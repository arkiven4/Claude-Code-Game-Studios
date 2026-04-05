# enemy_ai_controller.gd
class_name EnemyAIController
extends CharacterBody3D

## Controls one enemy. Manages HP, skill cooldowns, and decision cycles.

signal died
signal damage_taken(amount: int)

@export var enemy_data: EnemyData
@export var move_speed: float = 3.5
@export var stop_distance: float = 1.5
@export var aggro_range: float = 10.0

var current_hp: int
var max_hp: int
var is_alive: bool = true
var is_enraged: bool = false

var _skill_cooldowns: Array[float] = []
var _decision_timer: float = 0.5
var _current_target: Node3D # CharacterBody3D of the target character

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

func _physics_process(delta: float) -> void:
	if not is_alive or not enemy_data: return
	
	# Tick cooldowns
	for i in range(_skill_cooldowns.size()):
		if _skill_cooldowns[i] > 0.0:
			_skill_cooldowns[i] -= delta
			
	# Movement toward target
	var target_state := _get_target_state()
	if _current_target and target_state and target_state.is_alive:
		var dist := global_position.distance_to(_current_target.global_position)
		if dist > stop_distance:
			var dir: Vector3 = (_current_target.global_position - global_position).normalized()
			var target_vel := dir * move_speed
			velocity.x = target_vel.x
			velocity.z = target_vel.z
			look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)

	# Apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	
	# Decision cycle
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_make_decision()

## Accepts either a damage Dictionary (from HealthDamageSystem) or a plain int.
func take_damage(data) -> void:
	if not is_alive: return
	var amount: int = int(data.get("damage", 0)) if data is Dictionary else int(data)
	var final_amount: int = int(max(HealthDamageSystem.MINIMUM_DAMAGE, amount))
	
	current_hp = max(0, current_hp - final_amount)
	damage_taken.emit(final_amount)
	
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

## Returns the PartyMemberState child of _current_target, or null if not valid.
func _get_target_state() -> PartyMemberState:
	if not _current_target: return null
	return _current_target.get_node_or_null("PartyMemberState") as PartyMemberState

func _make_decision() -> void:
	_current_target = _select_target()

	var target_state := _get_target_state()
	if not target_state or not target_state.is_alive:
		_decision_timer = _get_decision_interval()
		return

	var best_skill_index := _select_best_skill()
	if best_skill_index >= 0:
		_execute_skill(best_skill_index, target_state)
	elif _current_target:
		# Fallback: plain melee punch when no skills are defined and enemy is in range
		var dist := global_position.distance_to(_current_target.global_position)
		if dist <= stop_distance + 0.5:
			var atk: int = enemy_data.base_atk if enemy_data else 10
			var result := HealthDamageSystem.calculate_damage(atk, atk, 1.0, target_state.get_effective_def(), 1.0, 0.05)
			target_state.take_damage(result)

	_decision_timer = _get_decision_interval()

## Returns the CharacterBody3D of the best party member to target (for movement/position).
func _select_target() -> Node3D:
	var party_members := get_tree().get_nodes_in_group("PartyMembers")
	if party_members.is_empty(): return null

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
	
	for i in range(enemy_data.skill_list.size()):
		var entry := enemy_data.skill_list[i]
		if not entry or not entry.skill_ref: continue
		
		# Condition check
		if not _is_condition_eligible(entry.condition): continue
		
		var condition_bonus := 2.0 if _evaluate_condition(entry.condition) else 1.0
		
		# Cooldown penalty
		var max_cooldown := entry.cooldown * 0.5 if is_enraged else entry.cooldown
		var cooldown_penalty := 1.0 - (_skill_cooldowns[i] / max_cooldown) if max_cooldown > 0.0 else 1.0
		
		# Range check
		if _current_target:
			var dist := global_position.distance_to(_current_target.global_position)
			if entry.max_range > 0.0 and dist > entry.max_range: continue
			if entry.min_range > 0.0 and dist < entry.min_range: continue
			
		var score := entry.weight * condition_bonus * cooldown_penalty
		if score > best_score:
			best_score = score
			best_index = i
			
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
	var entry := enemy_data.skill_list[index]
	var skill := entry.skill_ref

	var cooldown := entry.cooldown * 0.5 if is_enraged else entry.cooldown
	_skill_cooldowns[index] = cooldown

	# Apply effect based on skill type
	if skill.skill_type == SkillData.SkillType.DAMAGE:
		var effect_value: float = skill.tiers[0].effect_value if not skill.tiers.is_empty() else 1.0
		var atk: int = int(floor(enemy_data.base_atk * 1.5)) if is_enraged else enemy_data.base_atk
		var target_def: int = target.get_effective_def()
		var res: float = float(target.call("get_resistance", skill.damage_category)) if target.has_method("get_resistance") else 1.0

		var result: Dictionary = HealthDamageSystem.calculate_damage(atk, skill.base_damage, effect_value, target_def, res, 0.0)
		target.take_damage(result)

func _get_decision_interval() -> float:
	match enemy_data.enemy_class:
		EnemyData.EnemyClass.GRUNT: return 0.5
		EnemyData.EnemyClass.ELITE, EnemyData.EnemyClass.MINI_BOSS: return 0.3
		EnemyData.EnemyClass.BOSS: return 0.2
	return 0.5
