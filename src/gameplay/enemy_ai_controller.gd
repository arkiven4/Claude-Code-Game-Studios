# enemy_ai_controller.gd
class_name EnemyAIController
extends CharacterBody3D

## Controls one enemy. Manages HP, skill cooldowns, and decision cycles.

signal died
signal damage_taken(amount: int)

@export var enemy_data: EnemyData
@export var move_speed: float = 3.5
@export var stop_distance: float = 1.5

var current_hp: int
var max_hp: int
var is_alive: bool = true
var is_enraged: bool = false

var _skill_cooldowns: Array[float] = []
var _decision_timer: float = 0.5
var _current_target: Node # Will be PartyMemberState

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
	if _current_target and _current_target.has_method("is_alive") and _current_target.is_alive():
		var dist := global_position.distance_to(_current_target.global_position)
		if dist > stop_distance:
			var dir: Vector3 = (_current_target.global_position - global_position).normalized()
			velocity = dir * move_speed
			look_at(global_position + Vector3(dir.x, 0, dir.z), Vector3.UP)
			move_and_slide()
		else:
			velocity = Vector3.ZERO
	
	# Decision cycle
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_make_decision()

func take_damage(amount: int) -> void:
	if not is_alive: return
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

func _make_decision() -> void:
	_current_target = _select_target()
	
	if not _current_target or not _current_target.has_method("is_alive") or not _current_target.is_alive():
		_decision_timer = _get_decision_interval()
		return
		
	var best_skill_index := _select_best_skill()
	if best_skill_index >= 0:
		_execute_skill(best_skill_index, _current_target)
		
	_decision_timer = _get_decision_interval()

func _select_target() -> Node:
	var party_members := get_tree().get_nodes_in_group("PartyMembers")
	if party_members.is_empty(): return null
	
	var best_target: Node = null
	var best_score: float = INF
	
	for member in party_members:
		if not member.has_method("is_alive") or not member.is_alive(): continue
		
		var score: float = 0.0
		var hp_ratio: float = member.get("current_hp") / float(member.get("max_hp")) if "max_hp" in member else 1.0
		
		match enemy_data.behavior_profile:
			EnemyData.EnemyBehaviorProfile.AGGRESSIVE, EnemyData.EnemyBehaviorProfile.BOSS:
				score = hp_ratio # Lowest HP
			EnemyData.EnemyBehaviorProfile.TACTICAL:
				score = member.call("get_effective_def") if member.has_method("get_effective_def") else 0.0
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
			return _current_target.get("current_hp") < _current_target.get("max_hp") * 0.5 if "max_hp" in _current_target else false
		# ... other conditions ...
		7, 8: # PHASE_2_ONLY, ENRAGE_PHASE
			return is_enraged
	return true

func _is_condition_eligible(condition: int) -> bool:
	if condition == 7 or condition == 8: # PHASE_2_ONLY, ENRAGE_PHASE
		return is_enraged
	return true

func _execute_skill(index: int, target: Node) -> void:
	var entry := enemy_data.skill_list[index]
	var skill := entry.skill_ref
	
	var cooldown := entry.cooldown * 0.5 if is_enraged else entry.cooldown
	_skill_cooldowns[index] = cooldown
	
	# Apply effect based on skill type
	if skill.skill_type == SkillData.SkillType.DAMAGE:
		var effect_value: float = skill.tiers[0].effect_value if not skill.tiers.is_empty() else 1.0
		var atk: int = int(floor(enemy_data.base_atk * 1.5)) if is_enraged else enemy_data.base_atk
		var target_def: int = int(target.call("get_effective_def")) if target.has_method("get_effective_def") else 0
		var res: float = float(target.call("get_resistance", skill.damage_category)) if target.has_method("get_resistance") else 1.0
		
		var result: Dictionary = HealthDamageSystem.calculate_damage(atk, skill.base_damage, effect_value, target_def, res, 0.0)
		
		if target.has_method("take_damage"):
			target.call("take_damage", result)

func _get_decision_interval() -> float:
	match enemy_data.enemy_class:
		EnemyData.EnemyClass.GRUNT: return 0.5
		EnemyData.EnemyClass.ELITE, EnemyData.EnemyClass.MINI_BOSS: return 0.3
		EnemyData.EnemyClass.BOSS: return 0.2
	return 0.5
