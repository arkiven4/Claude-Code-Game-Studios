# party_member_state.gd
class_name PartyMemberState
extends Node

## Authoritative runtime state container for a party member.

signal health_state_changed(state: HealthState)
signal death
signal revived
signal hp_changed(current: int, max: int)
signal mp_changed(current: int, max: int)
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
@export var base_mp_regen: float = 2.0 # MP per second

# Status Effects
var active_effects: Array[ActiveEffect] = []

# Shield / Invincibility
var shield_value: int = 0
var is_invincible: bool = false

# Control State
var is_player_controlled: bool = false
var control_state: ControlState = ControlState.AI_CONTROLLED

# Life State
var is_alive: bool = true
var revives_used_this_encounter: int = 0

var _last_health_state: HealthState = HealthState.HEALTHY

func _ready() -> void:
	if not character_data:
		push_error("[PartyMemberState] No character_data assigned to %s" % name)
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
	if is_invincible: amount = 0
	if amount <= 0: return
	
	# Shield
	if shield_value > 0:
		var absorbed: int = int(min(shield_value, amount))
		shield_value -= absorbed
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
	is_player_controlled = false
	control_state = ControlState.AI_CONTROLLED
	death.emit()
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
	if slot < 0 or slot >= 4: return false
	
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
	if _has_action_denial_effect(): return false
	
	if is_special:
		return special_attack_cooldown <= 0.0 and character_data.special_attack != null
	else:
		return basic_attack_cooldown <= 0.0 and character_data.basic_attack != null

## Consumes the cooldown for a basic/special attack.
func consume_attack_cooldown(is_special: bool) -> void:
	var attack_skill := character_data.special_attack if is_special else character_data.basic_attack
	if not attack_skill: return
	
	if is_special:
		special_attack_cooldown = attack_skill.base_cooldown
	else:
		basic_attack_cooldown = attack_skill.base_cooldown

## Consumes MP for a dodge/dash. Returns true if successful.
func try_consume_dodge_mp() -> bool:
	if not is_alive: return false
	if current_mp < character_data.dodge_mp_cost: return false
	if is_invincible: return true # Maybe dodging while invincible is free? Or not.
	
	consume_mp(character_data.dodge_mp_cost)
	return true

func consume_charge(slot: int) -> void:
	if slot < 0 or slot >= 4: return
	if skill_charges[slot] > 0:
		skill_charges[slot] -= 1
		if skill_charges[slot] == 0:
			var skill: SkillData = character_data.skill_slots[slot] if slot < character_data.skill_slots.size() else null
			if skill:
				skill_cooldowns[slot] = skill.base_cooldown

# --- Stats ---

func get_effective_atk() -> int:
	var base_atk := character_data.get_atk_at_level(character_level)
	var equip_mod := 0
	var equip_manager := get_node_or_null("EquipmentManager")
	if equip_manager and equip_manager.has_method("get_total_modifiers"):
		equip_mod = int(equip_manager.get_total_modifiers().get("atk", 0.0))
	return _calculate_effective_stat(base_atk + equip_mod, StatusEffect.StatToModify.ATK)

func get_effective_def() -> int:
	var base_def := character_data.get_def_at_level(character_level)
	var equip_mod := 0
	var equip_manager := get_node_or_null("EquipmentManager")
	if equip_manager and equip_manager.has_method("get_total_modifiers"):
		equip_mod = int(equip_manager.get_total_modifiers().get("def", 0.0))
	return _calculate_effective_stat(base_def + equip_mod, StatusEffect.StatToModify.DEF)

func get_effective_crit() -> float:
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
	for effect in active_effects:
		if effect.definition.effect_category == StatusEffect.EffectCategory.ACTION_DENIAL:
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

func set_player_controlled(value: bool) -> void:
	is_player_controlled = value
	control_state = ControlState.PLAYER_CONTROLLED if value else ControlState.AI_CONTROLLED
	control_state_changed.emit(value)

func set_shield(value: int) -> void:
	shield_value = max(0, value)

func set_invincible(value: bool) -> void:
	is_invincible = value

func revive() -> void:
	if is_alive or revives_used_this_encounter >= 1: return
	is_alive = true
	current_hp = int(max_hp * HealthDamageSystem.REVIVE_HP_PERCENT)
	revives_used_this_encounter += 1
	active_effects.clear()
	hp_changed.emit(current_hp, max_hp)
	revived.emit()
	_notify_health_state_changed()

func reset_for_encounter(full_reset: bool) -> void:
	if full_reset:
		current_hp = max_hp
		current_mp = max_mp
		is_alive = true
		revives_used_this_encounter = 0
		active_effects.clear()
		
	# Always reset cooldowns
	for i in range(4):
		skill_cooldowns[i] = 0.0
		var skill: SkillData = character_data.skill_slots[i] if i < character_data.skill_slots.size() else null
		if skill:
			skill_charges[i] = skill.max_charges
			
	hp_changed.emit(current_hp, max_hp)
	_notify_health_state_changed()
