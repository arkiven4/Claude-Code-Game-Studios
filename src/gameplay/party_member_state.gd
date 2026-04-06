# party_member_state.gd
class_name PartyMemberState
extends Node

## Authoritative runtime state container for a party member.

signal health_state_changed(state: HealthState)
signal death
signal revived
signal hp_changed(current: int, max: int)
signal mp_changed(current: int, max: int)
signal shield_changed(current: int)
signal control_state_changed(is_player: bool)

enum HealthState { HEALTHY, INJURED, CRITICAL, DEAD }
enum ControlState { PLAYER_CONTROLLED, AI_CONTROLLED, SWITCHING_IN, SWITCHING_OUT }

@export var character_data: CharacterData
@export var character_level: int = 1

# Vital Stats
var current_hp: int
var current_mp: int
var max_hp: int
var max_mp: int

# Skill Runtime State
var skill_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var skill_charges: Array[int] = [0, 0, 0, 0]

# Dedicated Attack Cooldowns (Mouse)
var basic_attack_cooldown: float = 0.0
var special_attack_cooldown: float = 0.0

# Regeneration
var mp_regen_timer: float = 0.0
const MP_REGEN_INTERVAL: float = 1.0 # Regenerate MP every 1 second
@export var base_mp_regen: float = 17.0 # MP per second

# Status Effects
var active_effects: Array[ActiveEffect] = []
var _status_effects_system: StatusEffectsSystem

# Shield / Invincibility
var shield_value: int = 0
var is_invincible: bool = false
var is_casting: bool = false

# Control State
var is_player_controlled: bool = false
var control_state: ControlState = ControlState.AI_CONTROLLED

# Damage Tracking (for Death Summary)
var damage_history: Dictionary = {} # Map of "Caster:Skill" -> total_amount
var total_damage_received: int = 0

# Life State
var is_alive: bool = true
var revives_used_this_encounter: int = 0

var _last_health_state: HealthState = HealthState.HEALTHY

func _ready() -> void:
	if not character_data:
		push_warning("[PartyMemberState] No character_data assigned to %s — stats will not initialize." % name)
		return

	character_level = clampi(character_level, 1, CharacterData.LEVEL_CAP)

	max_hp = character_data.get_max_hp_at_level(character_level)
	max_mp = character_data.get_max_mp_at_level(character_level)

	current_hp = max_hp
	current_mp = max_mp

	for i in range(4):
		var skill: SkillData = character_data.skill_slots[i] if i < character_data.skill_slots.size() else null
		if skill:
			skill_charges[i] = skill.max_charges
		else:
			skill_charges[i] = 0

	is_alive = true
	_last_health_state = HealthState.HEALTHY

	## Find sibling StatusEffectsSystem and sync active_effects
	_status_effects_system = get_parent().get_node_or_null("StatusEffectsSystem")
	if _status_effects_system:
		_status_effects_system.effect_applied.connect(_on_effect_applied)
		_status_effects_system.effect_removed.connect(_on_effect_removed)

func _process(delta: float) -> void:
	if not is_alive: return
	
	# MP Regeneration
	if current_mp < max_mp:
		mp_regen_timer += delta
		if mp_regen_timer >= MP_REGEN_INTERVAL:
			restore_mp(int(base_mp_regen))
			mp_regen_timer = 0.0
	else:
		mp_regen_timer = 0.0

	# Tick skill cooldowns
	for i in range(4):
		if skill_cooldowns[i] > 0.0:
			skill_cooldowns[i] -= delta
			if skill_cooldowns[i] <= 0.0:
				skill_cooldowns[i] = 0.0
				# Restore charges
				var skill: SkillData = character_data.skill_slots[i] if i < character_data.skill_slots.size() else null
				if skill:
					skill_charges[i] = skill.max_charges
	
	# Tick attack cooldowns
	if basic_attack_cooldown > 0.0:
		basic_attack_cooldown = max(0.0, basic_attack_cooldown - delta)
	if special_attack_cooldown > 0.0:
		special_attack_cooldown = max(0.0, special_attack_cooldown - delta)

# --- Damage / Heal ---

func take_damage(data: Dictionary) -> void:
	if not is_alive: return
	var amount: int = int(data.get("damage", 0))
	
	if is_player_controlled and amount > 0:
		var c_name: String = data.get("caster_name", "Unknown")
		var s_name: String = data.get("skill_name", "Attack")
		print("[CombatLog] %s took %d damage from %s's %s" % [character_data.display_name if character_data else name, amount, c_name, s_name])
		
		# Update History
		var key := "%s:%s" % [c_name, s_name]
		damage_history[key] = damage_history.get(key, 0) + amount
		total_damage_received += amount

	if is_invincible or _has_effect_category(StatusEffect.EffectCategory.INVINCIBILITY):
		amount = 0
	if amount <= 0: return
	
	# Shield
	if shield_value > 0:
		var absorbed: int = int(min(shield_value, amount))
		shield_value -= absorbed
		shield_changed.emit(shield_value)
		amount -= absorbed
		
	if amount <= 0: return
	
	current_hp = max(0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		_die()
	else:
		_notify_health_state_changed()

func _die() -> void:
	is_alive = false
	active_effects.clear()
	if _status_effects_system:
		_status_effects_system.clear_all_effects()
	
	if is_player_controlled:
		_print_death_recap()
		
	is_player_controlled = false
	control_state = ControlState.AI_CONTROLLED
	death.emit()

func _print_death_recap() -> void:
	var char_name: String = character_data.display_name if character_data else name
	print("=== DEATH RECAP: %s ===" % char_name)
	print("Total Damage Received: %d" % total_damage_received)
	
	if total_damage_received <= 0:
		print("No damage recorded (instakill or unknown source).")
		return
		
	# Sort by damage amount descending
	var sorted_keys: Array[String] = []
	for k in damage_history.keys():
		sorted_keys.append(str(k))
		
	sorted_keys.sort_custom(func(a: String, b: String) -> bool: 
		var val_a: int = int(damage_history.get(a, 0))
		var val_b: int = int(damage_history.get(b, 0))
		return val_a > val_b
	)
	
	for key_raw in sorted_keys:
		var key: String = str(key_raw)
		var amount: int = int(damage_history.get(key, 0))
		var percent: float = (float(amount) / float(total_damage_received)) * 100.0
		var parts: PackedStringArray = key.split(":")
		var source: String = parts[0] if parts.size() > 0 else "Unknown"
		var skill: String = parts[1] if parts.size() > 1 else "Attack"
		print("- %s (%s): %d (%.1f%%)" % [skill, source, amount, percent])
	print("===============================")
	_notify_health_state_changed()

func apply_heal(amount: int) -> void:
	if not is_alive or amount <= 0: return
	current_hp = min(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)
	_notify_health_state_changed()

# --- MP ---

func consume_mp(amount: int) -> void:
	current_mp = max(0, current_mp - amount)
	mp_changed.emit(current_mp, max_mp)

func restore_mp(amount: int) -> void:
	current_mp = min(current_mp + amount, max_mp)
	mp_changed.emit(current_mp, max_mp)

# --- Skills ---

func can_use_skill(slot: int) -> bool:
	if not is_alive: return false
	if is_casting: return false
	if slot < 0 or slot >= 4: return false
	if not character_data: return false

	var skill: SkillData = character_data.skill_slots[slot] if slot < character_data.skill_slots.size() else null
	if not skill: return false
	
	if skill_cooldowns[slot] > 0.0: return false
	if skill_charges[slot] <= 0: return false
	if current_mp < skill.mp_cost: return false
	
	if _has_action_denial_effect(): return false
	
	return true

## Checks if the character can use their basic/special attack.
func can_attack(is_special: bool) -> bool:
	if not is_alive: return false
	if is_casting: return false
	if _has_action_denial_effect(): return false
	
	if not character_data: return false
	if is_special:
		return special_attack_cooldown <= 0.0 and character_data.special_attack != null
	else:
		return basic_attack_cooldown <= 0.0 and character_data.basic_attack != null

## Consumes the cooldown for a basic/special attack.
func consume_attack_cooldown(is_special: bool) -> void:
	if not character_data: return
	var attack_skill := character_data.special_attack if is_special else character_data.basic_attack
	if not attack_skill: return
	
	if is_special:
		special_attack_cooldown = attack_skill.base_cooldown
	else:
		basic_attack_cooldown = attack_skill.base_cooldown

## Consumes MP for a dodge/dash. Returns true if successful.
func try_consume_dodge_mp() -> bool:
	if not is_alive: return false
	if not character_data: return false
	if current_mp < character_data.dodge_mp_cost: return false
	
	consume_mp(character_data.dodge_mp_cost)
	return true

func consume_charge(slot: int) -> void:
	if slot < 0 or slot >= 4: return
	if not character_data: return
	if skill_charges[slot] > 0:
		skill_charges[slot] -= 1
		if skill_charges[slot] == 0:
			var skill: SkillData = character_data.skill_slots[slot] if slot < character_data.skill_slots.size() else null
			if skill:
				skill_cooldowns[slot] = skill.base_cooldown

# --- Stats ---

func get_effective_atk() -> int:
	if not character_data: return 0
	var base_atk := character_data.get_atk_at_level(character_level)
	var equip_mod := 0
	var equip_manager := get_node_or_null("EquipmentManager")
	if equip_manager and equip_manager.has_method("get_total_modifiers"):
		equip_mod = int(equip_manager.get_total_modifiers().get("atk", 0.0))
	return _calculate_effective_stat(base_atk + equip_mod, StatusEffect.StatToModify.ATK)

func get_effective_def() -> int:
	if not character_data: return 0
	var base_def := character_data.get_def_at_level(character_level)
	var equip_mod := 0
	var equip_manager := get_node_or_null("EquipmentManager")
	if equip_manager and equip_manager.has_method("get_total_modifiers"):
		equip_mod = int(equip_manager.get_total_modifiers().get("def", 0.0))
	return _calculate_effective_stat(base_def + equip_mod, StatusEffect.StatToModify.DEF)

func get_effective_crit() -> float:
	if not character_data: return 0.0
	var base_crit := character_data.base_crit
	return clampf(_calculate_effective_float_stat(base_crit, StatusEffect.StatToModify.CRIT), 0.0, 1.0)

func _calculate_effective_stat(base_val: int, stat_type: int) -> int:
	var pct_sum := 0.0
	var flat_sum := 0.0
	
	for effect in active_effects:
		if effect.definition.stat_to_modify == stat_type and effect.definition.effect_category == StatusEffect.EffectCategory.STAT_MODIFIER:
			var val := effect.definition.effect_value * effect.current_stacks
			if effect.definition.modify_type == StatusEffect.ModifyType.PERCENTAGE:
				pct_sum += (-val if effect.definition.is_hostile else val)
			else:
				flat_sum += (-val if effect.definition.is_hostile else val)
				
	var result := base_val * (1.0 + pct_sum) + flat_sum
	return int(max(base_val * 0.1, result))

func _calculate_effective_float_stat(base_val: float, stat_type: int) -> float:
	var pct_sum := 0.0
	var flat_sum := 0.0
	
	for effect in active_effects:
		if effect.definition.stat_to_modify == stat_type and effect.definition.effect_category == StatusEffect.EffectCategory.STAT_MODIFIER:
			var val := effect.definition.effect_value * effect.current_stacks
			if effect.definition.modify_type == StatusEffect.ModifyType.PERCENTAGE:
				pct_sum += (-val if effect.definition.is_hostile else val)
			else:
				flat_sum += (-val if effect.definition.is_hostile else val)
				
	var result := base_val * (1.0 + pct_sum) + flat_sum
	return max(base_val * 0.1, result)

# --- Helpers ---

func _has_action_denial_effect() -> bool:
	return _has_effect_category(StatusEffect.EffectCategory.ACTION_DENIAL)

func _has_effect_category(category: StatusEffect.EffectCategory) -> bool:
	for effect in active_effects:
		if effect.definition.effect_category == category:
			return true
	return false

func _notify_health_state_changed() -> void:
	var current := get_health_state()
	if current != _last_health_state:
		_last_health_state = current
		health_state_changed.emit(current)

func get_health_state() -> HealthState:
	if not is_alive or current_hp <= 0: return HealthState.DEAD
	var ratio := current_hp / float(max_hp)
	if ratio > 0.5: return HealthState.HEALTHY
	if ratio > 0.1: return HealthState.INJURED
	return HealthState.CRITICAL

func get_hp_ratio() -> float:
	return current_hp / float(max_hp) if max_hp > 0 else 0.0

func get_mp_ratio() -> float:
	return current_mp / float(max_mp) if max_mp > 0 else 0.0

func set_player_controlled(value: bool) -> void:
	is_player_controlled = value
	control_state = ControlState.PLAYER_CONTROLLED if value else ControlState.AI_CONTROLLED
	control_state_changed.emit(value)

func set_shield(value: int) -> void:
	shield_value = max(0, value)
	shield_changed.emit(shield_value)

func set_invincible(value: bool) -> void:
	is_invincible = value

func get_status_effects_system() -> StatusEffectsSystem:
	return _status_effects_system

func revive() -> void:
	if is_alive or revives_used_this_encounter >= 1: return
	is_alive = true
	current_hp = int(max_hp * HealthDamageSystem.REVIVE_HP_PERCENT)
	revives_used_this_encounter += 1
	active_effects.clear()
	if _status_effects_system:
		_status_effects_system.clear_all_effects()
	shield_value = 0
	shield_changed.emit(0)
	hp_changed.emit(current_hp, max_hp)
	revived.emit()
	_notify_health_state_changed()

func reset_for_encounter(full_reset: bool) -> void:
	if full_reset:
		current_hp = max_hp
		current_mp = max_mp
		is_alive = true
		revives_used_this_encounter = 0
		damage_history.clear()
		total_damage_received = 0
		active_effects.clear()
		if _status_effects_system:
			_status_effects_system.clear_all_effects()
		shield_value = 0
		shield_changed.emit(0)
		
	# Always reset cooldowns
	for i in range(4):
		skill_cooldowns[i] = 0.0
		if character_data:
			var skill: SkillData = character_data.skill_slots[i] if i < character_data.skill_slots.size() else null
			if skill:
				skill_charges[i] = skill.max_charges

	hp_changed.emit(current_hp, max_hp)
	_notify_health_state_changed()

## --- Status Effects Sync ---
## Sync active_effects from sibling StatusEffectsSystem so stat calculations
## and action-denial checks read the correct effect list.

func _on_effect_applied(effect: ActiveEffect) -> void:
	## Check if already tracked
	for existing in active_effects:
		if existing.definition.effect_id == effect.definition.effect_id:
			return  ## Already synced
	active_effects.append(effect)

func _on_effect_removed(effect: ActiveEffect) -> void:
	for i in range(active_effects.size()):
		if active_effects[i].definition.effect_id == effect.definition.effect_id:
			active_effects.remove_at(i)
			return
