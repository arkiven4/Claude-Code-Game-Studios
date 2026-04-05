# rl_party_agent.gd
class_name RLPartyAgent
extends PartyAgent

## Reinforcement learning party agent. 
## Wraps Godot RL Agents addon (replaces Unity ML-Agents).

@export var state: PartyMemberState
@export var skill_execution: SkillExecutionSystem

# Reward Tuning
@export var reward_per_damage: float = 0.001
@export var reward_ally_death: float = -1.0
@export var reward_enemy_kill: float = 1.0
@export var reward_encounter_win: float = 2.0
@export var penalty_per_step: float = -0.001

const MAX_OBSERVATION_DISTANCE: float = 20.0

var _active_tier: int = 1
var _total_reward: float = 0.0

func _ready() -> void:
	if not state:
		state = get_parent().get_node_or_null("PartyMemberState")
	if not skill_execution:
		skill_execution = get_parent().get_node_or_null("SkillExecutionSystem")
		
	if skill_execution:
		skill_execution.damage_dealt.connect(_on_damage_dealt)

func on_ai_resume_control(new_context: Dictionary) -> void:
	super.on_ai_resume_control(new_context)
	if state:
		_active_tier = state.character_data.get_active_tier(state.character_level)

func collect_observations() -> Array[float]:
	var obs: Array[float] = []
	
	if not state:
		for i in range(39): obs.append(0.0)
		return obs
		
	# Self (10)
	obs.append(state.get_hp_ratio())
	obs.append(state.get_mp_ratio())
	for i in range(4):
		obs.append(state.call("get_cooldown_ratio", i) if state.has_method("get_cooldown_ratio") else 0.0)
	for i in range(4):
		obs.append(1.0 if state.can_use_skill(i) else 0.0)
		
	# Allies (9)
	var allies: Array = context.get("allies", [])
	var ally_count := 0
	for ally in allies:
		if ally_count >= 3: break
		if ally != state and ally:
			obs.append(ally.call("get_hp_ratio") if ally.has_method("get_hp_ratio") else 0.0)
			obs.append(ally.call("get_mp_ratio") if ally.has_method("get_mp_ratio") else 0.0)
			obs.append(1.0 if ally.is_alive else 0.0)
			ally_count += 1
	for i in range(ally_count, 3):
		for j in range(3): obs.append(0.0)
		
	# Enemies (20)
	var enemies: Array = context.get("enemies", [])
	var enemy_count := 0
	for enemy in enemies:
		if enemy_count >= 4: break
		if enemy:
			var rel_pos: Vector3 = enemy.global_position - state.get_parent().global_position
			var dist := state.get_parent().global_position.distance_to(enemy.global_position)
			obs.append(enemy.call("get_hp_ratio") if enemy.has_method("get_hp_ratio") else 0.0)
			obs.append(clampf(dist / MAX_OBSERVATION_DISTANCE, 0.0, 1.0))
			obs.append(1.0 if enemy.is_alive else 0.0)
			obs.append(clampf(rel_pos.x / MAX_OBSERVATION_DISTANCE, -1.0, 1.0))
			obs.append(clampf(rel_pos.z / MAX_OBSERVATION_DISTANCE, -1.0, 1.0))
			enemy_count += 1
	for i in range(enemy_count, 4):
		for j in range(5): obs.append(0.0)
		
	return obs

func on_action_received(action: int) -> void:
	if not is_active or not state or not state.is_alive: return
	
	if action >= 1 and action <= 4:
		var slot_index := action - 1
		if skill_execution:
			skill_execution.try_activate_skill(slot_index, _active_tier)
			
	add_reward(penalty_per_step)

func add_reward(amount: float) -> void:
	_total_reward += amount
	# In actual Godot RL Agents, we would call self.reward += amount

func _on_damage_dealt(amount: int, _target: Node) -> void:
	add_reward(amount * reward_per_damage)

func end_episode() -> void:
	# Signal to RL addon
	_total_reward = 0.0
