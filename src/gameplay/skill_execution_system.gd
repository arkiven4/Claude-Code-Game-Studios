# skill_execution_system.gd
class_name SkillExecutionSystem
extends Node

## Executes the 5-phase skill activation sequence for a character.

signal skill_activated(slot_index: int, success: bool)
signal attack_activated(is_special: bool, success: bool)
signal skill_cast(skill: SkillData)
signal damage_dealt(amount: int, target: Node)

@export var state: Node # Will be PartyMemberState
@export var status_effects: StatusEffectsSystem
@export var projectile_scene: PackedScene

## Duration the hitbox stays active when executing a melee/hitbox skill.
const _HITBOX_ACTIVE_WINDOW: float = 0.15

func try_activate_skill(slot_index: int, active_tier: int) -> bool:
	# Phase 1: Validation
	if not state or not state.get("is_alive"):
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

## Tries to activate basic or special attack (Left/Right click).
## Cooldown only, no MP cost.
func try_activate_attack(is_special: bool, active_tier: int = 1) -> bool:
	if not state or not state.get("is_alive"):
		attack_activated.emit(is_special, false)
		return false
		
	if not state.has_method("can_attack") or not state.can_attack(is_special):
		attack_activated.emit(is_special, false)
		return false
		
	var character_data: CharacterData = state.get("character_data")
	var skill: SkillData = character_data.special_attack if is_special else character_data.basic_attack
	if not skill:
		attack_activated.emit(is_special, false)
		return false
		
	# Consume cooldown (No MP)
	state.call("consume_attack_cooldown", is_special)
	
	# Execute
	var tier_index := clampi(active_tier, 1, 3) - 1
	var tier_config: SkillTierConfig = skill.tiers[tier_index] if tier_index < skill.tiers.size() else null
	var effect_value: float = tier_config.effect_value if tier_config else 1.0
	var target_count: int = tier_config.target_count if tier_config and tier_config.target_count > 0 else skill.target_count
	
	if _is_enemy_targeting(skill.target_type):
		_execute_enemy_skill(skill, tier_config, effect_value, target_count, active_tier)
	else:
		_execute_friendly_skill(skill, tier_config, effect_value, target_count, active_tier)
		
	skill_cast.emit(skill)
	attack_activated.emit(is_special, true)
	return true

func _is_enemy_targeting(target_type: SkillData.TargetType) -> bool:
	return target_type in [
		SkillData.TargetType.SINGLE_ENEMY,
		SkillData.TargetType.MULTI_ENEMY_LINE,
		SkillData.TargetType.MULTI_ENEMY_CONE,
		SkillData.TargetType.ALL_ENEMIES
	]

func _execute_enemy_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if not caster_node: return

	# Determine effect parameters
	var max_range: float = skill.max_cast_range
	var area_radius: float = skill.area_radius
	if tier_config and tier_config.area_radius > 0.0:
		area_radius = tier_config.area_radius
	
	# Phase 1: Determine the Cast Center
	var cast_center: Vector3 = caster_node.global_position
	var primary_target: EnemyAIController = null
	
	if max_range > 0.0:
		# Search for nearest primary target within reach
		var potential_targets = caster_node.get_tree().get_nodes_in_group("Enemies")
		var best_dist := INF
		for e in potential_targets:
			if e is EnemyAIController and e.is_alive:
				var dist = caster_node.global_position.distance_to(e.global_position)
				if dist <= max_range and dist < best_dist:
					best_dist = dist
					primary_target = e
		
		if primary_target:
			cast_center = primary_target.global_position
			# Auto-target: rotate caster to face the target
			var to_target = (primary_target.global_position - caster_node.global_position)
			to_target.y = 0
			if to_target.length() > 0.1:
				var target_basis := Basis.looking_at(to_target.normalized(), Vector3.UP)
				caster_node.basis = target_basis
		else:
			# If no target found for a targeted skill, center it at max range in front of player
			var forward = -caster_node.global_transform.basis.z.normalized()
			cast_center = caster_node.global_position + (forward * max_range)

	_spawn_skill_vfx(cast_center + Vector3(0, 1.0, 0), Color(1.0, 0.3, 0.1))

	# Phase 2: Damage Calculation
	var caster_atk: int = int(state.call("get_effective_atk")) if state.has_method("get_effective_atk") else 10
	var crit_chance: float = float(state.call("get_effective_crit")) if state.has_method("get_effective_crit") else 0.05
	var damage_result := HealthDamageSystem.calculate_damage(caster_atk, skill.base_damage, effect_value, 0, 1.0, crit_chance)

	# Phase 3: Area Hit Detection
	var enemy_nodes := caster_node.get_tree().get_nodes_in_group("Enemies")
	var in_range: Array = []
	
	for e in enemy_nodes:
		if not (e is EnemyAIController and e.is_alive): continue
		
		var dist_to_center = cast_center.distance_to(e.global_position)
		
		# Basic Radius Check
		if dist_to_center > area_radius: continue
		
		# Cone Check (Special case for melee arcs)
		if skill.target_type == SkillData.TargetType.MULTI_ENEMY_CONE:
			var to_enemy = (e.global_position - caster_node.global_position)
			to_enemy.y = 0 # Ignore vertical difference
			to_enemy = to_enemy.normalized()
			
			var caster_forward = -caster_node.global_transform.basis.z
			caster_forward.y = 0 # Ignore vertical difference
			caster_forward = caster_forward.normalized()
			
			var angle = rad_to_deg(caster_forward.angle_to(to_enemy))
			if angle > skill.cone_angle * 0.5: continue
			
		in_range.append(e)

	if in_range.is_empty(): return

	# Sort by distance to the CENTER of the effect
	in_range.sort_custom(func(a: EnemyAIController, b: EnemyAIController) -> bool:
		return cast_center.distance_to(a.global_position) < cast_center.distance_to(b.global_position))

	var hits := mini(target_count, in_range.size())
	for i in range(hits):
		var target := in_range[i] as EnemyAIController
		target.take_damage(damage_result)
		_spawn_skill_vfx(target.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.1, 0.1))
		damage_dealt.emit(damage_result.get("damage", 0), target)

func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if caster_node:
		_spawn_skill_vfx(caster_node.global_position + Vector3(0, 1.0, 0), Color(0.2, 1.0, 0.4))

## Spawns a simple expanding flash sphere at [position] as a placeholder cast VFX.
## Scales from 0.2 → 1.5 and fades out over 0.4 s, then frees itself.
func _spawn_skill_vfx(position: Vector3, color: Color) -> void:
	var vfx := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	vfx.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	vfx.material_override = mat

	get_tree().root.add_child(vfx)
	vfx.global_position = position

	var tween := vfx.create_tween()
	tween.set_parallel(true)
	tween.tween_property(vfx, "scale", Vector3(1.5, 1.5, 1.5), 0.4)
	tween.tween_property(mat, "albedo_color", Color(color.r, color.g, color.b, 0.0), 0.4)
	get_tree().create_timer(0.45).timeout.connect(vfx.queue_free)

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
