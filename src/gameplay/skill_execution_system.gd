# skill_execution_system.gd
class_name SkillExecutionSystem
extends Node

## Executes the 5-phase skill activation sequence for a character.

signal skill_activated(slot_index: int, success: bool)
signal skill_cast(skill: SkillData)
signal damage_dealt(amount: int, target: Node)

@export var state: Node # Will be PartyMemberState
@export var status_effects: StatusEffectsSystem
@export var projectile_scene: PackedScene

func try_activate_skill(slot_index: int, active_tier: int) -> bool:
	# Phase 1: Validation
	if not state or not state.has_method("is_alive") or not state.is_alive():
		skill_activated.emit(slot_index, false)
		return false
		
	if slot_index < 0 or slot_index >= 4:
		return false
		
	if not state.has_method("can_use_skill") or not state.can_use_skill(slot_index):
		skill_activated.emit(slot_index, false)
		return false
		
	var character_data: CharacterData = state.get("character_data")
	if not character_data or slot_index >= character_data.skill_slots.size():
		skill_activated.emit(slot_index, false)
		return false
		
	var skill: SkillData = character_data.skill_slots[slot_index]
	if not skill:
		skill_activated.emit(slot_index, false)
		return false
		
	# Phase 2: Pre-execution
	state.call("consume_mp", skill.mp_cost)
	state.call("consume_charge", slot_index)
	
	# Phase 3 & 4: Acquisition + Application
	var tier_index := clampi(active_tier, 1, 3) - 1
	var tier_config: SkillTierConfig = skill.tiers[tier_index] if tier_index < skill.tiers.size() else null
	
	var effect_value: float = tier_config.effect_value if tier_config else 1.0
	var target_count: int = tier_config.target_count if tier_config and tier_config.target_count > 0 else skill.target_count
	
	if _is_enemy_targeting(skill.target_type):
		_execute_enemy_skill(skill, tier_config, effect_value, target_count, active_tier)
	else:
		_execute_friendly_skill(skill, tier_config, effect_value, target_count, active_tier)
		
	skill_cast.emit(skill)
	skill_activated.emit(slot_index, true)
	return true

func _is_enemy_targeting(target_type: SkillData.TargetType) -> bool:
	return target_type in [
		SkillData.TargetType.SINGLE_ENEMY,
		SkillData.TargetType.MULTI_ENEMY_LINE,
		SkillData.TargetType.MULTI_ENEMY_CONE,
		SkillData.TargetType.ALL_ENEMIES
	]

func _execute_enemy_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	# Placeholder for target acquisition and application
	# In Godot, we'd use Area3D or ShapeCast3D for this
	pass

func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	# Placeholder for friendly target acquisition (party members)
	pass

func _apply_skill_to_target(skill: SkillData, target: Node, effect_value: float, tier: int) -> void:
	match skill.skill_type:
		SkillData.SkillType.DAMAGE:
			_apply_damage_skill(skill, target, effect_value)
		SkillData.SkillType.SUPPORT:
			_apply_support_skill(skill, target, effect_value)
		SkillData.SkillType.STATUS:
			_apply_status_skill(skill, target, tier)
		SkillData.SkillType.UTILITY:
			_apply_utility_skill(skill)

func _apply_damage_skill(skill: SkillData, target: Node, effect_value: float) -> void:
	var caster_atk: int = int(state.call("get_effective_atk")) if state.has_method("get_effective_atk") else 10
	var target_def: int = int(target.call("get_effective_def")) if target.has_method("get_effective_def") else 0
	var res: float = float(target.call("get_resistance", skill.damage_category)) if target.has_method("get_resistance") else 1.0
	var crit_chance: float = float(state.call("get_effective_crit")) if state.has_method("get_effective_crit") else 0.05
	
	var result: Dictionary = HealthDamageSystem.calculate_damage(caster_atk, skill.base_damage, effect_value, target_def, res, crit_chance)
	
	if target.has_method("take_damage"):
		target.call("take_damage", result)
		damage_dealt.emit(result.damage, target)

func _apply_support_skill(skill: SkillData, target: Node, effect_value: float) -> void:
	if skill.is_revive:
		if target.has_method("revive"):
			target.call("revive")
		return
		
	var caster_max_mp: int = state.get("max_mp") if "max_mp" in state else 50
	var target_max_hp: int = target.get("max_hp") if "max_hp" in target else 100
	var target_current_hp: int = target.get("current_hp") if "current_hp" in target else 100
	
	var heal := HealthDamageSystem.calculate_heal(caster_max_mp, skill.base_heal, effect_value, target_max_hp, skill.bonus_percent, target_current_hp)
	
	if target.has_method("apply_heal"):
		target.call("apply_heal", heal)

func _apply_status_skill(skill: SkillData, target: Node, tier: int) -> void:
	var target_effects: StatusEffectsSystem = target.get_node_or_null("StatusEffectsSystem")
	if not target_effects: return
	
	for effect_def in skill.effects_to_apply:
		target_effects.apply_effect(effect_def, state.name, tier)

func _apply_utility_skill(skill: SkillData) -> void:
	if skill.mp_restore_amount > 0:
		state.call("restore_mp", skill.mp_restore_amount)
	if skill.shield_value > 0:
		state.call("set_shield", skill.shield_value)
	if skill.grants_invincibility:
		state.call("set_invincible", true)
		get_tree().create_timer(skill.invincibility_duration).timeout.connect(
			func(): state.call("set_invincible", false)
		)
