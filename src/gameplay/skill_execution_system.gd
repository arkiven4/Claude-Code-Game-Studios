# skill_execution_system.gd
class_name SkillExecutionSystem
extends Node

## Executes the 5-phase skill activation sequence for a character.

signal skill_activated(slot_index: int, success: bool)
signal attack_activated(is_special: bool, success: bool)
signal skill_cast(skill: SkillData)
signal damage_dealt(amount: int, target: Node)
signal projectile_spawned(projectile: Projectile)
signal targeting_started(mode: TargetingMode)
signal targeting_ended
signal hover_target_changed(target: Node)

@export var state: Node # Will be PartyMemberState
@export var status_effects: StatusEffectsSystem
@export var projectile_scene: PackedScene
@export var cast_indicator: SkillCastIndicator

## Double-tap tracking
const DOUBLE_TAP_THRESHOLD: float = 0.35
var _last_skill_press_times: Array[float] = [0.0, 0.0, 0.0, 0.0]
var _last_skill_slot: int = -1

enum TargetingMode { NONE, FRIENDLY }
var _current_targeting_mode: TargetingMode = TargetingMode.NONE
var _targeting_skill_index: int = -1
var _targeting_tier: int = 1
var _last_hover_target: Node = null

# Casting State
var _cast_timer: float = 0.0
var _current_cast_skill: SkillData = null
var _current_cast_slot: int = -1 # -1 for basic/special attack
var _current_cast_tier: int = 1
var _is_special_attack: bool = false
var _cast_force_self: bool = false

func _process(delta: float) -> void:
	if _current_targeting_mode == TargetingMode.FRIENDLY:
		var current_hover := _get_crosshair_friendly_target()
		if current_hover != _last_hover_target:
			_last_hover_target = current_hover
			hover_target_changed.emit(current_hover)
	
	if state and state.get("is_casting"):
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_complete_casting()

func get_cast_progress() -> float:
	if not state or not state.get("is_casting") or not _current_cast_skill:
		return 0.0
	var total := _current_cast_skill.cast_time
	if total <= 0.0: return 1.0
	return clampf(1.0 - (_cast_timer / total), 0.0, 1.0)

func try_activate_skill(slot_index: int, active_tier: int) -> bool:
	# Phase 1: Validation
	if not state or not state.get("is_alive") or state.get("is_casting"):
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

	# Handle Targeting Mode
	if _current_targeting_mode == TargetingMode.FRIENDLY and _targeting_skill_index == slot_index:
		# Pressed the same skill again -> Self Heal
		_exit_targeting_mode()
		return _start_casting(skill, slot_index, active_tier, true)
	
	var is_supportive := skill.skill_type in [SkillData.SkillType.SUPPORT, SkillData.SkillType.STATUS]
	
	if is_supportive and skill.target_type == SkillData.TargetType.SINGLE_ALLY:
		# Enter friendly targeting mode
		_enter_targeting_mode(TargetingMode.FRIENDLY, slot_index, active_tier)
		return true

	# Standard execution path (checks for cast time)
	return _start_casting(skill, slot_index, active_tier)

## Called by RL agents to bypass interactive targeting for SINGLE_ALLY skills.
## force_self=true → heal/buff self; force_self=false → lowest-HP ally fallback.
func execute_skill_rl(slot_index: int, active_tier: int, force_self: bool) -> bool:
	if not state or not state.get("is_alive") or state.get("is_casting"): return false
	if slot_index < 0 or slot_index >= 4: return false
	if not state.has_method("can_use_skill") or not state.can_use_skill(slot_index): return false
	var character_data: CharacterData = state.get("character_data")
	if not character_data or slot_index >= character_data.skill_slots.size(): return false
	var skill: SkillData = character_data.skill_slots[slot_index]
	if not skill: return false
	return _start_casting(skill, slot_index, active_tier, force_self)

func _enter_targeting_mode(mode: TargetingMode, index: int, tier: int) -> void:
	_current_targeting_mode = mode
	_targeting_skill_index = index
	_targeting_tier = tier
	targeting_started.emit(mode)

func _exit_targeting_mode() -> void:
	_current_targeting_mode = TargetingMode.NONE
	_targeting_skill_index = -1
	_last_hover_target = null
	targeting_ended.emit()

func _start_casting(skill: SkillData, slot_index: int, tier: int, force_self: bool = false, is_special: bool = false) -> bool:
	if skill.cast_time > 0.0:
		_cast_timer = skill.cast_time
		_current_cast_skill = skill
		_current_cast_slot = slot_index
		_current_cast_tier = tier
		_is_special_attack = (slot_index == -1)
		_cast_force_self = force_self
		state.set("is_casting", true)
		return true
	else:
		if slot_index == -1:
			return _execute_attack_immediately(is_special, tier)
		else:
			return _execute_skill_immediately(slot_index, tier, force_self)

func _complete_casting() -> void:
	state.set("is_casting", false)
	var skill := _current_cast_skill
	var slot := _current_cast_slot
	var tier := _current_cast_tier
	var force_self := _cast_force_self
	var is_special := _is_special_attack
	
	_current_cast_skill = null
	
	if slot == -1:
		_execute_attack_immediately(is_special, tier)
	else:
		_execute_skill_immediately(slot, tier, force_self)

func _execute_skill_immediately(slot_index: int, active_tier: int, force_self: bool = false) -> bool:
	var character_data: CharacterData = state.get("character_data")
	var skill: SkillData = character_data.skill_slots[slot_index]
	
	# Phase 2: Pre-execution
	state.call("consume_mp", skill.mp_cost)
	state.call("consume_charge", slot_index)
	
	# Phase 3 & 4: Acquisition + Application
	var tier_data: Dictionary = CombatSkillExecutor.resolve_tier(skill, active_tier)
	var effect_value: float = tier_data.effect_value
	var target_count: int = tier_data.target_count
	
	if _is_enemy_targeting(skill.target_type):
		_execute_enemy_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier)
	else:
		_execute_friendly_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier, force_self)

	skill_cast.emit(skill)
	if cast_indicator:
		cast_indicator.show_skill_icon(skill)
	skill_activated.emit(slot_index, true)
	return true

## Tries to activate basic or special attack (Left/Right click).
## Cooldown only, no MP cost.
func try_activate_attack(is_special: bool, active_tier: int = 1) -> bool:
	if _current_targeting_mode == TargetingMode.FRIENDLY:
		if not is_special:
			# Left click confirms friendly targeting
			var skill: SkillData = state.get("character_data").skill_slots[_targeting_skill_index]
			# If we have a hover target, use it; otherwise self-heal
			var use_hover := _last_hover_target != null and _last_hover_target != state
			_start_casting(skill, _targeting_skill_index, _targeting_tier, !use_hover)
			_exit_targeting_mode()
			return true
		else:
			# Right click cancels targeting
			_exit_targeting_mode()
			return false

	if not state or not state.get("is_alive") or state.get("is_casting"):
		attack_activated.emit(is_special, false)
		return false
		
	if not state.has_method("can_attack") or not state.can_attack(is_special):
		attack_activated.emit(is_special, false)
		return false
		
	var character_data: CharacterData = state.get("character_data")
	if not character_data:
		attack_activated.emit(is_special, false)
		return false

	var skill: SkillData = character_data.special_attack if is_special else character_data.basic_attack
	if not skill:
		attack_activated.emit(is_special, false)
		return false
		
	return _start_casting(skill, -1, active_tier, false, is_special)

func _execute_attack_immediately(is_special: bool, active_tier: int) -> bool:
	var character_data: CharacterData = state.get("character_data")
	var skill: SkillData = character_data.special_attack if is_special else character_data.basic_attack
	
	# Consume cooldown (No MP)
	state.call("consume_attack_cooldown", is_special)
	
	# Execute
	var tier_data: Dictionary = CombatSkillExecutor.resolve_tier(skill, active_tier)
	var effect_value: float = tier_data.effect_value
	var target_count: int = tier_data.target_count
	
	if _is_enemy_targeting(skill.target_type):
		_execute_enemy_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier)
	else:
		_execute_friendly_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier)

	skill_cast.emit(skill)
	if cast_indicator:
		cast_indicator.show_skill_icon(skill)
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


	# Phase 2: Damage Calculation (Baseline for projectiles/logic)
	var baseline_damage: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, caster_node)

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

	if in_range.is_empty():
		if skill.is_projectile:
			# Projectile: fire forward, expire at max range.
			_spawn_projectile_vfx(skill, caster_node, null, baseline_damage)
		else:
			# Melee/instant: show the VFX in front of the caster (air swing).
			var forward := -caster_node.global_transform.basis.z.normalized()
			var swing_pos := caster_node.global_position + forward * 1.0 + Vector3(0, 0.8, 0)
			_spawn_skill_vfx(swing_pos, Color(1.0, 0.3, 0.1), skill.vfx_effect)
		return

	# Sort by distance to the CENTER of the effect
	in_range.sort_custom(func(a: EnemyAIController, b: EnemyAIController) -> bool:
		return cast_center.distance_to(a.global_position) < cast_center.distance_to(b.global_position))

	var hits := mini(target_count, in_range.size())

	if skill.is_projectile:
		# Projectile delivery: spawn one projectile per hit target aimed at that target.
		for i in range(hits):
			var target := in_range[i] as EnemyAIController
			var actual_damage: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, target)
			actual_damage["caster_name"] = caster_node.name
			_spawn_projectile_vfx(skill, caster_node, target, actual_damage)
		# damage_dealt is emitted later by the Projectile node's hurtbox callback;
		# nothing more to do here for projectile skills.
		return

	for i in range(hits):
		var target := in_range[i] as EnemyAIController
		var actual_damage: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, target)
		actual_damage["caster_name"] = caster_node.name
		target.take_damage(actual_damage)
		_spawn_skill_vfx(target.global_position, Color(1.0, 0.1, 0.1), skill.vfx_effect)
		damage_dealt.emit(actual_damage.get("damage", 0), target)
		# Apply on-hit status effects (e.g. abyssal_chain stun)
		CombatSkillExecutor.apply_skill_effects(skill, state.get_parent().name if state and state.get_parent() else "", target)

func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int, force_self: bool = false) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if not caster_node: return

	if skill.target_type == SkillData.TargetType.SELF or force_self:
		## Self-targeted: apply directly to caster's own state
		_apply_skill_to_target(skill, state, effect_value, tier)
		_spawn_skill_vfx(caster_node.global_position, Color(0.2, 1.0, 0.4), skill.vfx_effect)
		return

	## ALL_ALLIES: apply to every living party member
	if skill.target_type == SkillData.TargetType.ALL_ALLIES:
		_spawn_skill_vfx(caster_node.global_position, Color(0.2, 1.0, 0.4), skill.vfx_effect)
		var party := get_tree().get_nodes_in_group("PartyMembers")
		for member in party:
			var member_state: Node = member.get_node_or_null("PartyMemberState")
			if member_state and member_state.get("is_alive"):
				_apply_skill_to_target(skill, member_state, effect_value, tier)
				_spawn_skill_vfx(member.global_position, Color(0.2, 1.0, 0.4), skill.vfx_effect)
		return

	## SINGLE_ALLY: Check if we have a confirmed target from targeting mode
	var final_target: Node = null

	# Priority 1: Use the confirmed hover target if in friendly targeting mode
	if _current_targeting_mode == TargetingMode.FRIENDLY and _last_hover_target:
		final_target = _last_hover_target
	else:
		# Priority 2: Try crosshair targeting
		var crosshair_target := _get_crosshair_friendly_target()
		if crosshair_target:
			final_target = crosshair_target
		else:
			## SINGLE_ALLY FALLBACK: apply to the lowest-HP living ally (or self if none found)
			var party := get_tree().get_nodes_in_group("PartyMembers")
			var best_target: Node = state
			var lowest_hp_ratio: float = 1.0
			for member in party:
				var member_state: Node = member.get_node_or_null("PartyMemberState")
				if not member_state or not member_state.get("is_alive"): continue
				var ratio: float = member_state.get_hp_ratio() if member_state.has_method("get_hp_ratio") else 1.0
				if ratio < lowest_hp_ratio:
					lowest_hp_ratio = ratio
					best_target = member_state
			final_target = best_target

	if final_target:
		_apply_skill_to_target(skill, final_target, effect_value, tier)
		var target_node: Node3D = final_target.get_parent() as Node3D
		if target_node:
			_spawn_skill_vfx(target_node.global_position, Color(0.2, 1.0, 0.4), skill.vfx_effect)

func _get_crosshair_friendly_target() -> Node:
	var camera := get_viewport().get_camera_3d()
	if not camera: return null

	var screen_center := get_viewport().get_visible_rect().size / 2.0

	# Phase 1: Direct Raycast (Center of screen)
	var from := camera.project_ray_origin(screen_center)
	var to := from + camera.project_ray_normal(screen_center) * 200.0

	var space_state := get_tree().root.world_3d.direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2 # Layer 2: Party Hurtboxes
	query.collide_with_areas = true
	query.collide_with_bodies = false # Don't hit bodies, only areas

	var result := space_state.intersect_ray(query)
	if not result.is_empty() and result.collider:
		var direct_target = _extract_party_member_state(result.collider)
		if direct_target and direct_target != state:
			return direct_target

	# Phase 2: Auto-snapping (Target allies within 30% of screen center)
	var viewport_size := get_viewport().get_visible_rect().size
	var snap_width := viewport_size.x * 0.3
	var snap_height := viewport_size.y * 0.3

	var party_members := get_tree().get_nodes_in_group("PartyMembers")
	var best_snap_target: Node = null
	var closest_dist_sq := INF

	for member in party_members:
		if not member is Node3D: continue
		var state_node: PartyMemberState = member.get_node_or_null("PartyMemberState")
		if not state_node or not state_node.is_alive: continue

		# Skip self (already handled by double-tap self-heal)
		if state_node == state: continue

		var chest_pos: Vector3 = member.global_position + Vector3(0, 0.9, 0)
		var screen_pos: Vector2 = camera.unproject_position(chest_pos)

		# Check if visible (not behind camera)
		if camera.is_position_behind(chest_pos):
			continue

		# Check if within snapping bounds
		var dx := absf(screen_pos.x - screen_center.x)
		var dy := absf(screen_pos.y - screen_center.y)
		if dx < snap_width * 0.5 and dy < snap_height * 0.5:
			var dist_sq = screen_pos.distance_squared_to(screen_center)
			if dist_sq < closest_dist_sq:
				closest_dist_sq = dist_sq
				best_snap_target = state_node

	return best_snap_target

func _extract_party_member_state(node: Node) -> PartyMemberState:
	if not node: return null
	var target_state: PartyMemberState = node.get_node_or_null("PartyMemberState") as PartyMemberState
	if not target_state and node.get_parent():
		target_state = node.get_parent().get_node_or_null("PartyMemberState") as PartyMemberState
	if not target_state:
		for child in node.get_children():
			if child is PartyMemberState:
				target_state = child
				break
	return target_state

## Delegates to CombatVFX. Keeps a [color] fallback sphere when no texture is set.
func _spawn_skill_vfx(position: Vector3, color: Color, texture: Texture2D = null) -> void:
	CombatSkillExecutor.spawn_hit_vfx(get_tree(), position, texture, color)

## Spawns a Projectile via CombatVFX.spawn_projectile aimed at [target] (or forward if null).
## Design doc: skills with is_projectile = true use this delivery path instead of instant hit.
func _spawn_projectile_vfx(skill: SkillData, caster_node: Node3D, target: EnemyAIController, damage_result: Dictionary) -> void:
	var spawn_pos := caster_node.global_position + Vector3(0, 0.8, 0)
	var caster_id: String = str(state.get_parent().name) if state and state.get_parent() else ""

	var projectile: Projectile = null
	if target:
		projectile = CombatVFX.spawn_projectile(get_tree(), projectile_scene, skill, damage_result, caster_id,
				spawn_pos, target.global_position + Vector3(0, 0.8, 0), true, false, -1.0, target)
	else:
		# No target: fire forward, expire when it reaches max range.
		var forward := -caster_node.global_transform.basis.z.normalized()
		var lifetime := skill.max_cast_range / maxf(skill.projectile_speed, 1.0)
		projectile = CombatVFX.spawn_projectile(get_tree(), projectile_scene, skill, damage_result, caster_id,
				spawn_pos, spawn_pos + forward * skill.max_cast_range, true, false, lifetime)
	
	if projectile:
		projectile_spawned.emit(projectile)

func _apply_skill_to_target(skill: SkillData, target: Node, effect_value: float, tier: int) -> void:
	match skill.skill_type:
		SkillData.SkillType.DAMAGE:
			var result: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, target)
			if target.has_method("take_damage"):
				target.call("take_damage", result)
				damage_dealt.emit(result.get("damage", 0), target)
		SkillData.SkillType.SUPPORT:
			_apply_support_skill(skill, target, effect_value)
		SkillData.SkillType.STATUS:
			CombatSkillExecutor.apply_skill_effects(skill, state.get_parent().name if state and state.get_parent() else "", target, tier)
		SkillData.SkillType.UTILITY:
			CombatSkillExecutor.apply_utility(skill, state, state.get_parent().name if state and state.get_parent() else "")

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
