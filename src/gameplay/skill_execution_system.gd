# skill_execution_system.gd
class_name SkillExecutionSystem
extends Node

## Executes the 5-phase skill activation sequence for a character.

signal skill_activated(slot_index: int, success: bool)
signal attack_activated(is_special: bool, success: bool)
signal skill_cast(skill: SkillData)
signal damage_dealt(amount: int, target: Node)
signal heal_applied(amount: int, target: Node)
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

# Combo State
var _combo_active_skill: SkillData = null
var _combo_active_slot: int = -2 # -2: None, -1: Basic/Special, 0-3: Skill Slot
var _combo_window_timer: float = 0.0

func _clear_combo() -> void:
	_combo_active_skill = null
	_combo_active_slot = -2
	_combo_window_timer = 0.0

func _ready() -> void:
	## Cancel any in-progress cast when the caster dies. Without this, the
	## _cast_timer in _process keeps ticking on a dead caster and eventually
	## fires _complete_casting() — damage/heal/VFX all come out of the corpse.
	## Also leaves is_casting stuck at true across revive, softlocking the
	## character on respawn.
	if state and state.has_signal("death"):
		state.death.connect(cancel_cast)

func _process(delta: float) -> void:
	if _current_targeting_mode == TargetingMode.FRIENDLY:
		var current_hover := _get_crosshair_friendly_target()
		if current_hover != _last_hover_target:
			_last_hover_target = current_hover
			hover_target_changed.emit(current_hover)

	## Guard: never tick the cast timer on a dead caster. The death signal
	## above handles cancellation, but this is defense-in-depth in case a
	## future code path leaves is_casting=true without firing death.
	if state and state.get("is_alive"):
		if state.get("is_casting"):
			_cast_timer -= delta
			if _cast_timer <= 0.0:
				_complete_casting()
		
		if _combo_window_timer > 0.0:
			_combo_window_timer -= delta
			if _combo_window_timer <= 0.0:
				_clear_combo()

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
		
	var character_data: CharacterData = state.get("character_data")
	if not character_data or slot_index >= character_data.skill_slots.size():
		skill_activated.emit(slot_index, false)
		return false
		
	var skill: SkillData = character_data.skill_slots[slot_index]
	
	# Check for Combo
	if _combo_active_slot == slot_index and _combo_active_skill:
		skill = _combo_active_skill
	elif not state.has_method("can_use_skill") or not state.can_use_skill(slot_index):
		skill_activated.emit(slot_index, false)
		return false
		
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
	if not skill:
		push_error("[SkillSystem] _start_casting called with null skill!")
		return false
	print("[SkillSystem] _start_casting skill=%s cast_time=%.2f" % [skill.display_name, skill.cast_time])
	if skill.cast_time > 0.0:
		_cast_timer = skill.cast_time
		_current_cast_skill = skill
		_current_cast_slot = slot_index
		_current_cast_tier = tier
		_is_special_attack = is_special
		_cast_force_self = force_self
		state.set("is_casting", true)
		return true
	else:
		if slot_index == -1:
			return _execute_attack_immediately(is_special, tier)
		else:
			return _execute_skill_immediately(slot_index, tier, force_self)

## Cancels an in-progress cast without firing the skill. Used on episode reset.
func cancel_cast() -> void:
	if state:
		state.set("is_casting", false)
	_cast_timer = 0.0
	_current_cast_skill = null
	_current_cast_slot = -1

func _complete_casting() -> void:
	print("[SkillSystem] _complete_casting skill=%s" % (_current_cast_skill.display_name if _current_cast_skill else "NULL"))
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
	print("[SkillSystem] _execute_skill_immediately skill=%s" % (skill.display_name if skill else "NULL"))
	
	# If we were executing a combo, use that skill instead
	if _combo_active_slot == slot_index and _combo_active_skill:
		skill = _combo_active_skill
		_clear_combo() # Clear it so we can set the next one in the chain

	# Phase 2: Pre-execution
	state.call("consume_mp", skill.mp_cost)
	# Only consume charge if it's the start of a chain or a non-combo skill
	if _combo_active_slot != slot_index:
		state.call("consume_charge", slot_index)
	
	# Phase 3 & 4: Acquisition + Application
	var tier_data: Dictionary = CombatSkillExecutor.resolve_tier(skill, active_tier)
	var effect_value: float = tier_data.effect_value
	var target_count: int = tier_data.target_count
	
	if _is_enemy_targeting(skill.target_type):
		_execute_enemy_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier)
	else:
		_execute_friendly_skill(skill, tier_data.tier_config, effect_value, target_count, active_tier, force_self)

	# Set up next combo if applicable
	if skill.combo_next_skill:
		_combo_active_skill = skill.combo_next_skill
		_combo_active_slot = slot_index
		_combo_window_timer = skill.combo_window

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
		
	# Check for Combo (only for basic attacks by convention, but we check _combo_active_slot)
	var skill: SkillData = null
	if _combo_active_slot == -1 and not is_special and _combo_active_skill:
		# Check if basic attack cooldown is clear before allowing the combo hit
		if state.has_method("can_use_basic_attack") and state.can_use_basic_attack():
			skill = _combo_active_skill
		else:
			# Cooldown not ready, fail but don't clear combo yet (user might just be spamming)
			attack_activated.emit(is_special, false)
			return false
	
	if not skill:
		if is_special:
			if not state.has_method("can_use_special_attack") or not state.can_use_special_attack():
				attack_activated.emit(is_special, false)
				return false
		else:
			if not state.has_method("can_use_basic_attack") or not state.can_use_basic_attack():
				attack_activated.emit(is_special, false)
				return false
				
		var character_data: CharacterData = state.get("character_data")
		skill = character_data.special_attack if is_special else character_data.basic_attack

	if not skill:
		attack_activated.emit(is_special, false)
		return false
			
	return _start_casting(skill, -1, active_tier, false, is_special)

func _execute_attack_immediately(is_special: bool, active_tier: int) -> bool:
	var character_data: CharacterData = state.get("character_data")
	var skill: SkillData = character_data.special_attack if is_special else character_data.basic_attack
	
	# If we were executing a combo, use that skill instead
	if _combo_active_slot == -1 and not is_special and _combo_active_skill:
		skill = _combo_active_skill
		_clear_combo()

	if not skill: return false
	
	# Apply cooldown of the current skill in the chain (basic or combo hit)
	if state.has_method("consume_attack_cooldown"):
		state.call("consume_attack_cooldown", is_special, skill.base_cooldown)
	
	var tier_data: Dictionary = CombatSkillExecutor.resolve_tier(skill, active_tier)
	_execute_enemy_skill(skill, tier_data.tier_config, tier_data.effect_value, tier_data.target_count, active_tier)
	
	# Set up next combo if applicable
	if skill.combo_next_skill:
		_combo_active_skill = skill.combo_next_skill
		_combo_active_slot = -1
		_combo_window_timer = skill.combo_window

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
	var primary_target: Node3D = null
	if max_range > 0.0:
		# Search for nearest primary target within reach
		var potential_targets = caster_node.get_tree().get_nodes_in_group("Enemies")
		var best_dist := INF
		for e in potential_targets:
				var is_alive = true
				if e.has_method("is_alive"):
						is_alive = e.is_alive()
				elif "is_alive" in e:
						is_alive = e.is_alive

				if is_alive:
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
	var in_range: Array[Node3D] = []
	
	for e: Node in enemy_nodes:
		var e_node := e as Node3D
		if not e_node: continue

		var is_alive = true
		if e_node.has_method("is_alive"):
			is_alive = e_node.is_alive()
		elif "is_alive" in e_node:
			is_alive = e_node.is_alive

		if not is_alive: continue
		var dist_to_center = cast_center.distance_to(e_node.global_position)
		
		# Basic Radius Check
		if dist_to_center > area_radius: continue
		
		# Cone Check (Special case for melee arcs)
		if skill.target_type == SkillData.TargetType.MULTI_ENEMY_CONE:
			var to_enemy = (e_node.global_position - caster_node.global_position)
			to_enemy.y = 0 # Ignore vertical difference
			to_enemy = to_enemy.normalized()
			
			var caster_forward = -caster_node.global_transform.basis.z
			caster_forward.y = 0 # Ignore vertical difference
			caster_forward = caster_forward.normalized()
			
			var angle = rad_to_deg(caster_forward.angle_to(to_enemy))
			if angle > skill.cone_angle * 0.5: continue
			
		in_range.append(e_node)

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
	in_range.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return cast_center.distance_to(a.global_position) < cast_center.distance_to(b.global_position))

	var hits := mini(target_count, in_range.size())

	if skill.is_projectile:
		# Projectile delivery: spawn one projectile per hit target aimed at that target.
		for i in range(hits):
			var target: Node3D = in_range[i]
			var actual_damage: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, target)
			actual_damage["caster_name"] = caster_node.name
			_spawn_projectile_vfx(skill, caster_node, target, actual_damage)
		# damage_dealt is emitted later by the Projectile node's hurtbox callback;
		# nothing more to do here for projectile skills.
		return

	for i in range(hits):
		var target: Node3D = in_range[i]
		var actual_damage: Dictionary = CombatSkillExecutor.calculate_skill_damage(state, skill, effect_value, target)
		actual_damage["caster_name"] = caster_node.name
		if target.has_method("take_damage"):
			target.take_damage(actual_damage)
		_spawn_skill_vfx(target.global_position + Vector3(0, 0.8, 0), Color(1.0, 0.1, 0.1), skill.vfx_effect)
		damage_dealt.emit(actual_damage.get("damage", 0), target)
		# Apply on-hit status effects (e.g. abyssal_chain stun)
		CombatSkillExecutor.apply_skill_effects(skill, state.get_parent().name if state and state.get_parent() else "", target)

func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int, force_self: bool = false) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if not caster_node: return

	print("[SkillSystem] _execute_friendly_skill skill=%s target_type=%d force_self=%s" % [skill.display_name, skill.target_type, str(force_self)])

	if skill.target_type == SkillData.TargetType.SELF or force_self:
		## Self-targeted: apply directly to caster's own state
		print("[SkillSystem] Targeting SELF")
		_apply_skill_to_target(skill, state, effect_value, tier)
		_spawn_skill_vfx(caster_node.global_position + Vector3(0, 0.8, 0), Color(0.2, 1.0, 0.4), skill.vfx_effect)
		return

	## ALL_ALLIES: apply to every living party member
	if skill.target_type == SkillData.TargetType.ALL_ALLIES:
		print("[SkillSystem] Targeting ALL_ALLIES")
		_spawn_skill_vfx(caster_node.global_position + Vector3(0, 0.8, 0), Color(0.2, 1.0, 0.4), skill.vfx_effect)
		var party := get_tree().get_nodes_in_group("PartyMembers")
		for member in party:
			var member_state: Node = member.get_node_or_null("PartyMemberState")
			if member_state and member_state.get("is_alive"):
				_apply_skill_to_target(skill, member_state, effect_value, tier)
				_spawn_skill_vfx(member.global_position + Vector3(0, 0.8, 0), Color(0.2, 1.0, 0.4), skill.vfx_effect)
		return

	## SINGLE_ALLY: Check if we have a confirmed target from targeting mode
	var final_target: Node = null

	# Priority 1: Use the confirmed hover target if in friendly targeting mode
	if _current_targeting_mode == TargetingMode.FRIENDLY and _last_hover_target:
		final_target = _last_hover_target
		print("[SkillSystem] Targeting HOVER: %s" % final_target.name)
	else:
		# Priority 2: Try crosshair targeting
		var crosshair_target := _get_crosshair_friendly_target()
		if crosshair_target:
			final_target = crosshair_target
			print("[SkillSystem] Targeting CROSSHAIR: %s" % final_target.name)
		else:
			## SINGLE_ALLY FALLBACK: apply to the lowest-HP living ally (or self if none found)
			var party := get_tree().get_nodes_in_group("PartyMembers")
			print("[SkillSystem] Targeting FALLBACK. Party size: %d" % party.size())
			var best_target: Node = state
			var lowest_hp_ratio: float = 1.0
			
			# Check self first
			if state.has_method("get_hp_ratio"):
				lowest_hp_ratio = state.get_hp_ratio()

			for member in party:
				var target_for_hp: Node = member
				var member_state: Node = member.get_node_or_null("PartyMemberState")
				if member_state:
					target_for_hp = member_state
				
				# Check if alive
				var target_alive: bool = false
				if target_for_hp.has_method("is_alive"):
					target_alive = target_for_hp.is_alive()
				elif "is_alive" in target_for_hp:
					target_alive = target_for_hp.is_alive
				
				if not target_alive: 
					print("[SkillSystem] Candidate %s is NOT alive" % member.name)
					continue
				
				var ratio: float = 1.0
				if target_for_hp.has_method("get_hp_ratio"):
					ratio = target_for_hp.get_hp_ratio()
				elif "current_hp" in target_for_hp and "max_hp" in target_for_hp:
					ratio = float(target_for_hp.current_hp) / float(target_for_hp.max_hp)
				
				print("[SkillSystem] Candidate %s HP ratio: %.2f" % [member.name, ratio])
				if ratio < lowest_hp_ratio:
					lowest_hp_ratio = ratio
					best_target = target_for_hp
			
			final_target = best_target
			print("[SkillSystem] Resolved fallback target: %s" % final_target.name)

	if final_target:
		_apply_skill_to_target(skill, final_target, effect_value, tier)
		var target_node: Node3D = null
		if final_target is Node3D:
			target_node = final_target
		elif final_target.get_parent() is Node3D:
			target_node = final_target.get_parent()
			
		if target_node:
			print("[SkillSystem] Spawning VFX on %s at %s" % [target_node.name, str(target_node.global_position)])
			_spawn_skill_vfx(target_node.global_position + Vector3(0, 0.8, 0), Color(0.2, 1.0, 0.4), skill.vfx_effect)

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
	var closest_to_center := INF

	for member in party_members:
		if member == state.get_parent(): continue
		
		# Project to screen
		var screen_pos = camera.unproject_position(member.global_position + Vector3(0, 1, 0))
		var diff = (screen_pos - screen_center).abs()
		
		if diff.x < snap_width and diff.y < snap_height:
			var dist = diff.length()
			if dist < closest_to_center:
				closest_to_center = dist
				best_snap_target = member.get_node_or_null("PartyMemberState")
	
	return best_snap_target

func _extract_party_member_state(node: Node) -> Node:
	if not node: return null
	if "PartyMemberState" in node.name: return node
	return node.get_node_or_null("PartyMemberState")

func _spawn_skill_vfx(position: Vector3, color: Color, texture: Texture2D = null) -> void:
	CombatSkillExecutor.spawn_hit_vfx(get_tree(), position, texture, color)

## Spawns a Projectile via CombatVFX.spawn_projectile aimed at [target] (or forward if null).
## Design doc: skills with is_projectile = true use this delivery path instead of instant hit.
func _spawn_projectile_vfx(skill: SkillData, caster_node: Node3D, target: Node3D, damage_result: Dictionary) -> void:
	var spawn_pos := caster_node.global_position + Vector3(0, 0.8, 0)
	var caster_id: String = str(state.get_parent().name) if state and state.get_parent() else ""

	# Calculate lifetime based on range. Buffer of 0.1s to ensure it reaches the edge.
	var speed := maxf(skill.projectile_speed, 1.0)
	var lifetime := (skill.max_cast_range / speed) + 0.1

	var final_scene: PackedScene = skill.custom_projectile_scene if skill.custom_projectile_scene else projectile_scene
	var projectile: Projectile = null
	if target:
		projectile = CombatVFX.spawn_projectile(get_tree(), final_scene, skill, damage_result, caster_id,
				spawn_pos, target.global_position + Vector3(0, 0.8, 0), true, false, lifetime, target)
	else:
		# No target: fire forward
		var forward := -caster_node.global_transform.basis.z.normalized()
		projectile = CombatVFX.spawn_projectile(get_tree(), final_scene, skill, damage_result, caster_id,
				spawn_pos, spawn_pos + forward * skill.max_cast_range, true, false, lifetime)
	
	if projectile:
		projectile_spawned.emit(projectile)

func _apply_skill_to_target(skill: SkillData, target: Node, effect_value: float, tier: int) -> void:
	if not is_instance_valid(target) or not is_instance_valid(state): return
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
			CombatSkillExecutor.apply_utility(skill, target, state.get_parent().name if state and state.get_parent() else "")

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
		heal_applied.emit(heal.get("heal_amount", 0), target)
