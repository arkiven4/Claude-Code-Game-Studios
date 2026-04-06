# enemy_ai_controller.gd
class_name EnemyAIController
extends CharacterBody3D

## Controls one enemy. Manages HP, skill cooldowns, and decision cycles.
## Combat States:
##   IDLE - No target, no combat engagement
##   CHASING - Target detected but out of attack range, moving toward target
##   ATTACKING - Target in range, using skills or basic attacks
##   STRAFING - All attacks on cooldown, target in max skill range, dodging left/right
##   WAITING - Target out of max range but within aggro, waiting for target to return

enum CombatState { IDLE, CHASING, ATTACKING, STRAFING, WAITING }

signal died
signal damage_taken(amount: int)
signal damage_dealt(amount: int, target: Node)
signal shield_changed(new_value: int)
signal skill_fired(index: int, skill: SkillData)
signal projectile_spawned(projectile: Projectile)

@export var enemy_data: EnemyData
@export var projectile_scene: PackedScene
@export var move_speed: float = 3.5
@export var stop_distance: float = 1.5
@export var aggro_range: float = 1.0
@export var attack_range: float = 1.5
@export var use_attack_range_for_aggro: bool = false
@export var cast_indicator: SkillCastIndicator
## When true, disables the scripted AI brain so an RL agent can drive this enemy.
## Movement and skill execution are handled externally by RLEnemyHiveAgent + rl_arena_manager.
@export var rl_controlled: bool = false

var current_hp: int
var max_hp: int
var is_alive: bool = true
var is_enraged: bool = false

var _skill_cooldowns: Array[float] = []
var _decision_timer: float = 0.5
var _current_target: Node3D # CharacterBody3D of the target character
var _is_invincible: bool = false

# Casting State
var _is_casting: bool = false
var _cast_timer: float = 0.0
var _current_cast_skill_index: int = -1
var _current_cast_target: PartyMemberState = null

# Combat State Management
var _combat_state: CombatState = CombatState.IDLE
var _basic_attack_cooldown: float = 0.0
const BASIC_ATTACK_COOLDOWN: float = 1.5
var _strafe_direction: int = 1
var _strafe_timer: float = 0.0
const STRAFE_DURATION: float = 0.5
const STRAFE_SPEED_MULTIPLIER: float = 0.05  # 5% speed when strafing

# Chase Tracking
var _is_chasing: bool = false

# Cached Range Calculations
var _max_skill_range: float = 0.0
var _aggro_range_calculated: float = 0.0
var _ranges_initialized: bool = false

# Debug Visualization
@export_group("Debug Settings")
@export var show_debug_ranges: bool = false
@export var show_debug_ai_decisions: bool = false
@export var show_debug_combat_logs: bool = false
var _aggro_debug_mesh: MeshInstance3D = null
var _attack_range_debug: MeshInstance3D = null

## Logs AI decision-making only if show_debug_ai_decisions is enabled.
func _debug_ai(msg: String) -> void:
	if show_debug_ai_decisions:
		print(msg)

## Logs combat events only if show_debug_combat_logs is enabled.
func _debug_combat(msg: String) -> void:
	if show_debug_combat_logs:
		print(msg)

# TODO: Pathfinding integration for chase behavior
# When implementing pathfinding:
# 1. Add NavigationAgent3D: @onready var _nav_agent = $NavigationAgent3D
# 2. Replace direct movement in _chase_target() with navigation path
# 3. Use _nav_agent.set_target_position() and get_next_path_position()
# 4. Handle dynamic obstacles and path recalculation

@onready var _hitbox: HitboxComponent = get_node_or_null("HitboxComponent")

## Current shield value — exposed for WorldHPBar to read.
var shield_value: int = 0

func _ready() -> void:
	if not enemy_data:
		push_error("[EnemyAIController] No enemy_data assigned!")
		return

	max_hp = enemy_data.base_max_hp
	current_hp = max_hp
	is_alive = true
	is_enraged = false
	_decision_timer = _get_decision_interval()

	_skill_cooldowns.resize(enemy_data.skill_list.size())
	_skill_cooldowns.fill(0.0)

	_initialize_ranges()

	if _hitbox:
		_hitbox.hit_landed.connect(_on_hitbox_hit)

	# Initialize debug visualization
	_create_debug_range_indicators()

## Creates visual ring indicators for aggro and attack ranges (debug only).
func _create_debug_range_indicators() -> void:
	if not show_debug_ranges:
		return

	# Aggro range ring (red)
	_aggro_debug_mesh = MeshInstance3D.new()
	var aggro_ring := CylinderMesh.new()
	aggro_ring.top_radius = aggro_range
	aggro_ring.bottom_radius = aggro_range
	aggro_ring.height = 0.05
	aggro_ring.radial_segments = 64
	_aggro_debug_mesh.mesh = aggro_ring
	var aggro_mat := StandardMaterial3D.new()
	aggro_mat.albedo_color = Color(1.0, 0.0, 0.0, 0.3)
	aggro_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aggro_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	aggro_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_aggro_debug_mesh.material_override = aggro_mat
	add_child(_aggro_debug_mesh)
	_aggro_debug_mesh.position.y = 0.05

	# Attack range ring (green)
	_attack_range_debug = MeshInstance3D.new()
	var attack_ring := CylinderMesh.new()
	attack_ring.top_radius = attack_range
	attack_ring.bottom_radius = attack_range
	attack_ring.height = 0.05
	attack_ring.radial_segments = 64
	_attack_range_debug.mesh = attack_ring
	var attack_mat := StandardMaterial3D.new()
	attack_mat.albedo_color = Color(0.0, 1.0, 0.0, 0.4)
	attack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	attack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	attack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_attack_range_debug.material_override = attack_mat
	add_child(_attack_range_debug)
	_attack_range_debug.position.y = 0.05

## Updates debug range indicators to match current ranges.
func _update_debug_ranges() -> void:
	if not show_debug_ranges:
		if _aggro_debug_mesh:
			_aggro_debug_mesh.visible = false
		if _attack_range_debug:
			_attack_range_debug.visible = false
		return

	if _aggro_debug_mesh:
		_aggro_debug_mesh.visible = true
		var aggro_ring := _aggro_debug_mesh.mesh as CylinderMesh
		if aggro_ring:
			aggro_ring.top_radius = aggro_range
			aggro_ring.bottom_radius = aggro_range

	if _attack_range_debug:
		_attack_range_debug.visible = true
		var attack_ring := _attack_range_debug.mesh as CylinderMesh
		if attack_ring:
			attack_ring.top_radius = attack_range
			attack_ring.bottom_radius = attack_range

## Initializes aggro range dynamically from skill_list[0].
## attack_range = skill_list[0].max_cast_range (basic attack skill range)
## aggro_range = 1.5 * attack_range
## Fallback to 10 if result is <= 0.5.
func _initialize_ranges() -> void:
	if _ranges_initialized:
		return

	# attack_range = how close the enemy must get before attacking.
	# For ranged skills: use max_cast_range (enemy fires from that distance).
	# For melee/caster-centered AoE (max_cast_range = 0): keep the exported default (1.5).
	#   area_radius describes the SWEEP size of the attack, not the engagement distance.
	#   A grunt with a 3-unit AoE slash still needs to walk into melee range to swing.
	if not enemy_data.skill_list.is_empty():
		var basic_entry := enemy_data.skill_list[0]
		if basic_entry and basic_entry.skill_ref:
			var skill := basic_entry.skill_ref
			if skill.max_cast_range > 0.5:
				attack_range = skill.max_cast_range
			# else: melee/AoE — keep @export default (attack_range stays at 1.5)

	# stop_distance: meaningfully inside attack_range so the hitbox reliably connects.
	# 0.5 unit buffer ensures floating-point jitter and capsule radius offsets don't cause misses.
	stop_distance = maxf(0.5, attack_range - 0.5)

	# Dynamic aggro: 1.5 * attack_range, with a minimum of 6.0 so melee enemies
	# auto-aggro at a reasonable distance (not just arm's reach).
	aggro_range = maxf(6.0, attack_range * 1.5)
	_aggro_range_calculated = aggro_range

	# Max skill range (longest among ALL skills, used for chase distance)
	_max_skill_range = _calculate_max_skill_range()

	_ranges_initialized = true

## Calculates the maximum cast range among all equipped skills.
## Uses skill.max_cast_range (actual skill range), NOT entry.max_range (selection filter).
func _calculate_max_skill_range() -> float:
	if enemy_data.skill_list.is_empty():
		return 0.0

	var max_range: float = 0.0
	for entry in enemy_data.skill_list:
		if entry and entry.skill_ref:
			var skill_range := entry.skill_ref.max_cast_range
			if skill_range > max_range:
				max_range = skill_range
	return max_range

func _on_hitbox_hit(hurtbox: HurtboxComponent) -> void:
	if not _hitbox or not _hitbox._current_skill: return

	var target_state := hurtbox.parent_node as PartyMemberState
	if not target_state or not target_state.is_alive: return

	# Damage is already delivered by hurtbox.take_hit() in HitboxComponent._physics_process.
	damage_dealt.emit(_hitbox._damage_data.get("damage", 0), target_state)
	CombatSkillExecutor.apply_skill_effects(_hitbox._current_skill, name, target_state)

func _physics_process(delta: float) -> void:
	if not is_alive or not enemy_data: return

	# Tick cooldowns
	for i in range(_skill_cooldowns.size()):
		if _skill_cooldowns[i] > 0.0:
			_skill_cooldowns[i] -= delta

	# Tick basic attack cooldown
	if _basic_attack_cooldown > 0.0:
		_basic_attack_cooldown = maxf(0.0, _basic_attack_cooldown - delta)

	# Tick strafe timer
	if _strafe_timer > 0.0:
		_strafe_timer -= delta

	# Update debug visualization
	_update_debug_ranges()

	if _is_casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_complete_casting()

		# Freeze movement while casting
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		move_and_slide()
		return

	if rl_controlled:
		# RL mode: scripted AI brain is disabled. Movement and skills are driven by
		# RLEnemyHiveAgent + rl_arena_manager. Only refresh target so _execute_skill
		# and _get_target_state() remain functional when the RL agent fires a skill.
		var ts: PartyMemberState = _get_target_state()
		if not ts or not ts.is_alive:
			_current_target = null
			var best_dist: float = INF
			for member in get_tree().get_nodes_in_group("PartyMembers"):
				var member_state: PartyMemberState = member.get_node_or_null("PartyMemberState") as PartyMemberState
				if not member_state or not member_state.is_alive:
					continue
				var d: float = global_position.distance_to(member.global_position)
				if d < best_dist:
					best_dist = d
					_current_target = member as Node3D
	else:
		var is_stunned := _has_effect_category(StatusEffect.EffectCategory.ACTION_DENIAL)
		if is_stunned:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
		else:
			# Update combat state and execute behavior
			_update_combat_state()
			_execute_behavior(delta)

		# Apply gravity
		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()

		# Decision cycle for attack actions
		_decision_timer -= delta
		if _decision_timer <= 0.0 and _combat_state == CombatState.ATTACKING:
			_make_decision()
			_decision_timer = _get_decision_interval()
		return

	# RL mode: gravity + slide (movement velocity set by rl_arena_manager)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

## Updates the combat state based on current target distance and cooldowns.
## Priority 1: When aggroed, ALWAYS keep enemy inside attack range (chase to close distance)
## Priority 2: When in range, attack
## Stops chasing if 30m from spawn point.
func _update_combat_state() -> void:
	var target_state := _get_target_state()

	# If no current target, try to find one in aggro range
	if not target_state or not target_state.is_alive:
		_current_target = _select_target()
		target_state = _get_target_state()

		# Still no target - return to IDLE
		if not target_state or not target_state.is_alive:
			_combat_state = CombatState.IDLE
			_is_chasing = false
			_current_target = null
			return

	var dist := global_position.distance_to(_current_target.global_position)
	var can_basic_attack := dist <= attack_range and _basic_attack_cooldown <= 0.0
	var can_use_skill := _select_best_skill() >= 0

	var in_aggro_range := dist <= aggro_range

	# Check if target was marked (entered aggro at some point)
	if in_aggro_range and not _is_chasing:
		_is_chasing = true  # Mark the player as tracked

	# If already chasing, continue even outside aggro (persistent lock-on)
	var can_chase := _is_chasing

	# If moved too far from spawn or target cleared, return to IDLE
	if not in_aggro_range and not can_chase:
		_combat_state = CombatState.IDLE
		_is_chasing = false
		_current_target = null
		return

	# State transitions - Priority 1: Keep enemy inside attack range
	# Only enter ATTACKING once within attack_range. Long-range secondary skills
	# (e.g. Arcane Barrage range=11 while attack_range=9) must NOT trigger ATTACKING
	# early — that causes the enemy to stop mid-chase and cast, creating a jarring freeze.
	# Once inside attack_range, _make_decision() will still select long-range skills.
	var in_attack_range := dist <= attack_range
	var new_state := CombatState.IDLE
	if (can_basic_attack or can_use_skill) and in_attack_range:
		# In range and can attack
		new_state = CombatState.ATTACKING
	elif can_chase and dist > attack_range:
		# Priority: Keep enemy inside attack range - CHASE to close distance!
		# Lock onto current target - do NOT switch
		# This happens when _select_best_skill == -1 (skills on cooldown or unavailable)
		new_state = CombatState.CHASING
	else:
		# Target too far or outside chase limit
		new_state = CombatState.IDLE
		_is_chasing = false
		_current_target = null

	_combat_state = new_state

## Executes behavior based on current combat state.
func _execute_behavior(delta: float) -> void:
	match _combat_state:
		CombatState.IDLE:
			_behavior_idle()
		CombatState.CHASING:
			_behavior_chase_target(delta)
		CombatState.ATTACKING:
			_behavior_attack_target()
		CombatState.STRAFING:
			_behavior_strafe(delta)

func _behavior_idle() -> void:
	# No target, no movement
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)

func _behavior_chase_target(_delta: float) -> void:
	if not _current_target:
		# No target - stop moving
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		return

	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist <= stop_distance:
		# Already inside stop_distance — halt and face target so hitbox reliably connects
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		var dir_face: Vector3 = (_current_target.global_position - global_position).normalized()
		look_at(global_position + Vector3(dir_face.x, 0, dir_face.z), Vector3.UP)
		return

	var dir: Vector3 = (_current_target.global_position - global_position).normalized()
	var effective_speed: float = move_speed * _get_movement_multiplier()
	var target_vel := dir * effective_speed
	velocity.x = target_vel.x
	velocity.z = target_vel.z
	look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)

func _behavior_attack_target() -> void:
	# Stop movement when within stop_distance (0.5 buffer inside attack_range ensures hitbox connects)
	var dist := global_position.distance_to(_current_target.global_position) if _current_target else 999.0
	if dist <= stop_distance:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		# Move closer if still too far
		_behavior_chase_target(0.0)

func _behavior_strafe(delta: float) -> void:
	# Strafe left/right randomly to avoid projectiles
	_strafe_timer -= delta

	if _strafe_timer <= 0.0:
		# Pick new strafe direction
		_strafe_direction = 1 if randf() > 0.5 else -1
		_strafe_timer = STRAFE_DURATION

	var right := global_transform.basis.x.normalized()
	var strafe_vel := right * _strafe_direction * move_speed * STRAFE_SPEED_MULTIPLIER * _get_movement_multiplier()
	velocity.x = strafe_vel.x
	velocity.z = strafe_vel.z

## Accepts either a damage Dictionary (from HealthDamageSystem) or a plain int.
func take_damage(data) -> void:
	if not is_alive: return
	if _is_invincible or _has_effect_category(StatusEffect.EffectCategory.INVINCIBILITY): return

	var amount: int = int(data.get("damage", 0)) if data is Dictionary else int(data)
	var final_amount: int = int(max(HealthDamageSystem.MINIMUM_DAMAGE, amount))

	## Shield absorbs damage first
	if shield_value > 0:
		var absorbed: int = min(shield_value, final_amount)
		shield_value -= absorbed
		shield_changed.emit(shield_value)
		final_amount -= absorbed
		if final_amount <= 0:
			return

	current_hp = max(0, current_hp - final_amount)
	damage_taken.emit(final_amount)

	# When damaged by player, automatically mark attacker as target (taunt on hit).
	# Equivalent to entering aggro range — enemy will chase and attack regardless of distance.
	if data is Dictionary:
		var caster_name: String = data.get("caster_name", "")
		if not caster_name.is_empty():
			_acquire_target_by_name(caster_name)
			if _current_target:
				_is_chasing = true  # Persistent lock-on, won't drop target
				if _combat_state == CombatState.IDLE:
					_combat_state = CombatState.CHASING
					_debug_ai("[AI Decision] %s: Hit by '%s' — marking as target, entering CHASING" % [name, caster_name])

	# Check enrage (25%)
	if not is_enraged and current_hp <= max_hp * 0.25:
		is_enraged = true

	# Check death
	if current_hp <= enemy_data.death_threshold:
		_die()

func _die() -> void:
	is_alive = false
	died.emit()
	queue_free()

func get_resistance(category: int) -> float:
	return enemy_data.get_category_resistance(category) if enemy_data else 1.0

func get_hp_ratio() -> float:
	return float(current_hp) / float(max_hp) if max_hp > 0 else 0.0

func is_casting() -> bool:
	return _is_casting

func get_cast_progress() -> float:
	if not _is_casting or _current_cast_skill_index < 0:
		return 0.0
	var skill := enemy_data.skill_list[_current_cast_skill_index].skill_ref
	var total := skill.cast_time if skill else 1.0
	if total <= 0.0: return 1.0
	return clampf(1.0 - (_cast_timer / total), 0.0, 1.0)

## ICombatant interface — required by CombatSkillExecutor

func get_effective_atk() -> int:
	## Enrage multiplier baked in here so CombatSkillExecutor.calculate_skill_damage() gets correct value.
	return int(enemy_data.base_atk * 1.5) if is_enraged else enemy_data.base_atk

func get_effective_def() -> int:
	return 0  # Enemies currently have no DEF stat

func get_effective_crit() -> float:
	return 0.0  # Enemies currently do not crit

func get_status_effects_system() -> StatusEffectsSystem:
	return get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem

func get_combat_node() -> Node3D:
	return self  # EnemyAIController IS the CharacterBody3D

func get_caster_id() -> String:
	return name

func set_shield(value: int) -> void:
	shield_value = max(0, value)
	shield_changed.emit(shield_value)

func set_invincible(value: bool) -> void:
	_is_invincible = value

## Returns the PartyMemberState child of _current_target, or null if not valid.
func _get_target_state() -> PartyMemberState:
	if not _current_target: return null
	return _current_target.get_node_or_null("PartyMemberState") as PartyMemberState

## Acquires a target by their node name (used when damaged by a party member).
func _acquire_target_by_name(caster_name: String) -> void:
	var party_members := get_tree().get_nodes_in_group("PartyMembers")
	for member in party_members:
		if member.name == caster_name:
			var state: PartyMemberState = member.get_node_or_null("PartyMemberState")
			if state and state.is_alive:
				_current_target = member
				return

## Makes attack decisions based on current combat state.
## Decision flow: Try skills -> Try basic attack -> Wait for cooldowns
func _make_decision() -> void:
	## Do nothing if action-denied (stunned)
	if _has_effect_category(StatusEffect.EffectCategory.ACTION_DENIAL):
		_debug_ai("[AI Decision] %s: SKIPPED — stunned/action denied" % name)
		return

	var target_state := _get_target_state()
	if not target_state or not target_state.is_alive:
		return

	var dist := global_position.distance_to(_current_target.global_position)

	# Priority 1: Use best available skill
	var best_skill_index := _select_best_skill()
	if best_skill_index >= 0:
		var entry: EnemySkillEntry = enemy_data.skill_list[best_skill_index]
		_debug_ai("[AI Decision] %s: USING '%s' (slot %d, dist=%.1f, weight=%.1f) → %s" % [
			name, entry.skill_ref.display_name, best_skill_index, dist, entry.weight, target_state.name])
		_execute_skill(best_skill_index, target_state)
		return

	# Priority 2: Use basic attack if in range and not on cooldown.
	# Also check _skill_cooldowns[0] — basic attack uses slot 0, which may have been
	# put on cooldown by the skill path above. Both trackers must be clear.
	var slot0_ready := _skill_cooldowns.is_empty() or _skill_cooldowns[0] <= 0.0
	if dist <= attack_range and _basic_attack_cooldown <= 0.0 and slot0_ready:
		_debug_ai("[AI Decision] %s: USING Basic Attack (dist=%.1f <= range=%.1f, no cd) → %s" % [
			name, dist, attack_range, target_state.name])
		_execute_basic_attack(target_state)
		return

	# Priority 3: All attacks on cooldown - state machine will handle strafe/chase
	_debug_ai("[AI Decision] %s: WAITING — all skills on cooldown (dist=%.1f, basic_cd=%.1f)" % [
		name, dist, _basic_attack_cooldown])

## Returns the CharacterBody3D of the best party member to target (for movement/position).
func _select_target() -> Node3D:
	var party_members := get_tree().get_nodes_in_group("PartyMembers")
	if party_members.is_empty():
		return null

	var best_target: Node3D = null
	var best_score: float = INF

	for member in party_members:
		var state: PartyMemberState = member.get_node_or_null("PartyMemberState")
		if not state or not state.is_alive: continue
		if global_position.distance_to(member.global_position) > aggro_range: continue

		var score: float = 0.0
		var hp_ratio: float = state.current_hp / float(state.max_hp) if state.max_hp > 0 else 1.0

		match enemy_data.behavior_profile:
			EnemyData.EnemyBehaviorProfile.AGGRESSIVE, EnemyData.EnemyBehaviorProfile.BOSS:
				score = hp_ratio # Lowest HP
			EnemyData.EnemyBehaviorProfile.TACTICAL:
				score = state.get_effective_def()
			EnemyData.EnemyBehaviorProfile.DEFENSIVE:
				score = 1.0 - hp_ratio # Targets highest threat (approx by low HP)
				best_score = -INF # Invert for max

		if enemy_data.behavior_profile == EnemyData.EnemyBehaviorProfile.DEFENSIVE:
			if score > best_score:
				best_score = score
				best_target = member
		else:
			if score < best_score:
				best_score = score
				best_target = member

	return best_target

func _select_best_skill() -> int:
	if enemy_data.skill_list.is_empty(): return -1

	var best_index: int = -1
	var best_score: float = -INF
	var dist := global_position.distance_to(_current_target.global_position) if _current_target else 999.0

	if show_debug_ai_decisions:
		_debug_ai("[Skill Select] %s: Evaluating skills (target dist=%.1f, attack_range=%.1f)" % [name, dist, attack_range])

	for i in range(enemy_data.skill_list.size()):
		var entry := enemy_data.skill_list[i]
		if not entry or not entry.skill_ref:
			_debug_ai("[Skill Select] %s:   slot %d: SKIP (null skill_ref)" % [name, i])
			continue

		var skill := entry.skill_ref

		## Hard block: skip skills that are still on cooldown
		if _skill_cooldowns[i] > 0.0:
			_debug_ai("[Skill Select] %s:   slot %d '%s': SKIP (cooldown %.1fs remaining)" % [name, i, skill.display_name, _skill_cooldowns[i]])
			continue

		# Condition check
		if not _is_condition_eligible(entry.condition):
			_debug_ai("[Skill Select] %s:   slot %d '%s': SKIP (condition not eligible: %d)" % [name, i, skill.display_name, entry.condition])
			continue
		if not _evaluate_condition(entry.condition):
			_debug_ai("[Skill Select] %s:   slot %d '%s': SKIP (condition failed: %d)" % [name, i, skill.display_name, entry.condition])
			continue

		# Range check: how close must the enemy be to fire this skill?
		# - Ranged skill (max_cast_range > 0): fire from up to max_cast_range away.
		# - Melee/caster-AoE (max_cast_range = 0): enemy must be within attack_range (melee distance).
		#   area_radius is the sweep size after firing, not the engagement distance.
		var skill_range := skill.max_cast_range if skill.max_cast_range > 0.0 else attack_range
		if dist > skill_range:
			_debug_ai("[Skill Select] %s:   slot %d '%s': SKIP (out of range, dist=%.1f > range=%.1f)" % [name, i, skill.display_name, dist, skill_range])
			continue
		if entry.min_range > 0.0 and dist < entry.min_range:
			_debug_ai("[Skill Select] %s:   slot %d '%s': SKIP (too close, dist=%.1f < min=%.1f)" % [name, i, skill.display_name, dist, entry.min_range])
			continue

		# Skill is valid
		var score := entry.weight
		_debug_ai("[Skill Select] %s:   slot %d '%s': VALID (score=%.1f, range=%.1f, cd=%.1fs)" % [name, i, skill.display_name, score, skill_range, entry.cooldown])
		if score > best_score:
			best_score = score
			best_index = i

	if show_debug_ai_decisions:
		if best_index >= 0:
			var winner := enemy_data.skill_list[best_index].skill_ref
			_debug_ai("[Skill Select] %s: → SELECTED '%s' (slot %d, score=%.1f)" % [name, winner.display_name, best_index, best_score])
		else:
			_debug_ai("[Skill Select] %s: → NO VALID SKILL (all on cd, out of range, or conditions unmet)" % name)

	return best_index

func _evaluate_condition(condition: int) -> bool:
	match condition:
		0: # ALWAYS
			return true
		1: # TARGET_BELOW_HP_50
			var state := _get_target_state()
			if not state: return false
			return state.current_hp < state.max_hp * 0.5
		# ... other conditions ...
		7, 8: # PHASE_2_ONLY, ENRAGE_PHASE
			return is_enraged
	return true

func _is_condition_eligible(condition: int) -> bool:
	if condition == 7 or condition == 8: # PHASE_2_ONLY, ENRAGE_PHASE
		return is_enraged
	return true

func _execute_skill(index: int, target: PartyMemberState) -> void:
	var entry: EnemySkillEntry = enemy_data.skill_list[index]
	var skill: SkillData = entry.skill_ref

	if skill.cast_time > 0.0:
		_debug_ai("[Execute] %s: STARTING cast of '%s' for %.1fs → %s" % [name, skill.display_name, skill.cast_time, target.name])
		_is_casting = true
		_cast_timer = skill.cast_time
		_current_cast_skill_index = index
		_current_cast_target = target
		return

	_debug_ai("[Execute] %s: Firing '%s' immediately → %s" % [name, skill.display_name, target.name])
	_apply_skill_logic(index, target)

## Executes a basic attack using skill_list index 0.
## Routes through _execute_skill so cast_time is respected (e.g. 0.4s wind-up).
## Cooldown is applied in _apply_skill_logic after the cast completes.
## If index 0 is missing or invalid, falls back to direct damage.
func _execute_basic_attack(target: PartyMemberState) -> void:
	if enemy_data.skill_list.is_empty():
		push_error("[EnemyAIController] %s: skill_list[0] missing! Cannot execute basic attack." % name)
		_basic_attack_cooldown = BASIC_ATTACK_COOLDOWN
		_fallback_direct_damage(target, "Basic Attack")
		return

	var entry: EnemySkillEntry = enemy_data.skill_list[0]
	if not entry or not entry.skill_ref:
		push_error("[EnemyAIController] %s: skill_list[0] is null! Cannot execute basic attack." % name)
		_basic_attack_cooldown = BASIC_ATTACK_COOLDOWN
		_fallback_direct_damage(target, "Basic Attack")
		return

	_debug_ai("[Execute] %s: Basic Attack '%s' → %s" % [name, entry.skill_ref.display_name, target.name])
	# Route through _execute_skill: respects cast_time, _apply_skill_logic handles cooldown
	_execute_skill(0, target)

## Executes a skill against a target using unified damage flow (projectile, hitbox, or direct).
## Mirrors SkillExecutionSystem._execute_enemy_skill pattern.
func _execute_skill_with_target(skill: SkillData, entry: EnemySkillEntry, target: PartyMemberState) -> void:
	var tier_data: Dictionary = CombatSkillExecutor.resolve_tier(skill, 1)
	var effect_value: float = tier_data.effect_value

	# Apply cooldown to the skill entry
	if entry:
		var skill_index := -1
		for i in range(enemy_data.skill_list.size()):
			if enemy_data.skill_list[i] == entry:
				skill_index = i
				break
		if skill_index >= 0:
			var cooldown: float = entry.cooldown * 0.5 if is_enraged else entry.cooldown
			_skill_cooldowns[skill_index] = cooldown

	if skill.is_projectile:
		# Projectile damage delivery
		if not projectile_scene:
			push_error("[EnemyAIController] %s: projectile_scene not assigned! Cannot fire '%s'" % [name, skill.display_name])
			_fallback_direct_damage(target, skill.display_name)
			return

		var target_node := target.get_parent() as Node3D
		if target_node:
			var result: Dictionary = CombatSkillExecutor.calculate_skill_damage(self, skill, effect_value, target)
			
			# Calculate lifetime based on range. Buffer of 0.1s.
			var p_speed := maxf(skill.projectile_speed, 1.0)
			var lifetime := (skill.max_cast_range / p_speed) + 0.1
			
			var spawned := CombatVFX.spawn_projectile(get_tree(), projectile_scene, skill,
					result, name,
					global_position + Vector3(0, 0.8, 0),
					target_node.global_position + Vector3(0, 0.8, 0),
					false, true, lifetime, target_node)
			if spawned:
				projectile_spawned.emit(spawned)
			else:
				push_error("[EnemyAIController] %s: Failed to spawn projectile for '%s' (projectile_scene=%s)" % [name, skill.display_name, str(projectile_scene)])
		else:
			push_error("[EnemyAIController] %s: Target node is null, cannot fire '%s'" % [name, skill.display_name])
	elif _hitbox and not skill.is_projectile:
		# Hitbox delivery for melee skills (single-target AND multi-target)
		var result: Dictionary = CombatSkillExecutor.calculate_skill_damage(self, skill, effect_value, target)
		result["caster_name"] = name
		result["skill_name"] = skill.display_name
		_hitbox.activate(result, skill)
		get_tree().create_timer(0.2).timeout.connect(func() -> void:
			if is_instance_valid(_hitbox):
				_hitbox.deactivate())
	else:
		# Direct delivery (ranged instant hit without projectile)
		var result: Dictionary = CombatSkillExecutor.calculate_skill_damage(self, skill, effect_value, target)
		result["caster_name"] = name
		result["skill_name"] = skill.display_name
		target.take_damage(result)
		damage_dealt.emit(result.get("damage", 0), target)
		CombatSkillExecutor.apply_skill_effects(skill, name, target)
		var target_node := target.get_parent() as Node3D
		if target_node:
			CombatSkillExecutor.spawn_hit_vfx(get_tree(), target_node.global_position,
					skill.vfx_effect)

## Fallback direct damage when projectile or skill execution fails.
func _fallback_direct_damage(target: PartyMemberState, skill_name: String) -> void:
	var atk: int = enemy_data.base_atk if enemy_data else 10
	var result := HealthDamageSystem.calculate_damage(atk, atk, 1.0, target.get_effective_def(), 1.0, 0.05)
	result["caster_name"] = name
	result["skill_name"] = skill_name
	target.take_damage(result)
	damage_dealt.emit(result.get("damage", 0), target)

func _complete_casting() -> void:
	_is_casting = false
	if _current_cast_skill_index >= 0 and _current_cast_target and _current_cast_target.is_alive:
		var entry: EnemySkillEntry = enemy_data.skill_list[_current_cast_skill_index]
		if entry and entry.skill_ref:
			if cast_indicator:
				cast_indicator.show_skill_icon(entry.skill_ref)
		_apply_skill_logic(_current_cast_skill_index, _current_cast_target)

	_current_cast_skill_index = -1
	_current_cast_target = null

func _apply_skill_logic(index: int, target: PartyMemberState) -> void:
	var entry: EnemySkillEntry = enemy_data.skill_list[index]
	var skill: SkillData = entry.skill_ref

	# Apply cooldown after cast completes (this is the single source of truth for all skills)
	var cooldown: float = entry.cooldown * 0.5 if is_enraged else entry.cooldown
	_skill_cooldowns[index] = cooldown
	# Slot 0 is the basic attack — keep _basic_attack_cooldown in sync so the
	# basic attack guard in _make_decision always sees the correct value.
	if index == 0:
		_basic_attack_cooldown = cooldown

	# Show cast indicator
	if cast_indicator:
		cast_indicator.show_skill_icon(skill)

	skill_fired.emit(index, skill)

	# Handle skill type-specific logic
	match skill.skill_type:
		SkillData.SkillType.DAMAGE:
			# Unified damage flow (projectile, hitbox, or direct)
			_execute_skill_with_target(skill, entry, target)
		SkillData.SkillType.STATUS:
			CombatSkillExecutor.apply_skill_effects(skill, name, target)
			var target_node := target.get_parent() as Node3D
			if target_node:
				CombatSkillExecutor.spawn_hit_vfx(get_tree(), target_node.global_position, skill.vfx_effect, Color(0.6, 0.2, 1.0, 1.0))
		SkillData.SkillType.UTILITY:
			CombatSkillExecutor.apply_utility(skill, self, name)
			CombatSkillExecutor.spawn_hit_vfx(get_tree(), global_position, skill.vfx_effect, Color(1.0, 1.0, 1.0, 1.0))
		_:
			pass

func _apply_damage_skill(skill: SkillData, target: PartyMemberState) -> void:
	# Find the skill entry index for cooldown tracking
	var skill_index := -1
	var skill_entry: EnemySkillEntry = null
	for i in range(enemy_data.skill_list.size()):
		var entry := enemy_data.skill_list[i]
		if entry and entry.skill_ref == skill:
			skill_index = i
			skill_entry = entry
			break

	# Apply cooldown
	if skill_index >= 0 and skill_entry:
		var cooldown: float = skill_entry.cooldown * 0.5 if is_enraged else skill_entry.cooldown
		_skill_cooldowns[skill_index] = cooldown

	# Execute using unified damage flow
	_execute_skill_with_target(skill, skill_entry, target)

func _has_effect_category(category: StatusEffect.EffectCategory) -> bool:
	var sfx: Node = get_node_or_null("StatusEffectsSystem")
	if not sfx: return false
	for active in sfx.active_effects:
		if active.definition and active.definition.effect_category == category:
			return true
	return false

func _get_movement_multiplier() -> float:
	var sfx: Node = get_node_or_null("StatusEffectsSystem")
	if not sfx: return 1.0
	var multiplier: float = 1.0
	for active in sfx.active_effects:
		if active.definition and active.definition.effect_category == StatusEffect.EffectCategory.MOVEMENT_IMPAIR:
			multiplier *= active.effective_value
	return multiplier

func _get_decision_interval() -> float:
	match enemy_data.enemy_class:
		EnemyData.EnemyClass.GRUNT: return 0.5
		EnemyData.EnemyClass.ELITE, EnemyData.EnemyClass.MINI_BOSS: return 0.3
		EnemyData.EnemyClass.BOSS: return 0.2
	return 0.5
