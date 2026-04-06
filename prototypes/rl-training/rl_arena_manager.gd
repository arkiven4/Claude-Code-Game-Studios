# rl_arena_manager.gd
# Root script for TrainingArena.tscn.
# Handles: episode resets, movement execution, directive routing, reward wiring.
extends Node3D

@export var evan_body_path: NodePath
@export var evelyn_body_path: NodePath
@export var enemy_container_path: NodePath

@export var move_speed: float = 4.0
@export var max_episode_steps: int = 18000

## Stagnation penalty: steps of no damage before penalty fires (60 = ~1 second at 60 FPS)
@export var stagnation_threshold: int = 60
## Penalty applied to team reward and each party agent per step while stagnating
@export var w_stagnation: float = 0.002

@export_group("Curriculum Scheduler")
## Enable automatic episode length scaling based on rolling win rate
@export var curriculum_enabled: bool = true
## Episodes required before the scheduler checks for the first stage advance
@export var curriculum_min_episodes: int = 50
## Rolling window of recent episodes used to compute win rate for advancement
@export var curriculum_eval_window: int = 100

var evan_body: CharacterBody3D
var evelyn_body: CharacterBody3D
var enemy_container: Node3D

@onready var _evan_agent: RLPartyAgent
@onready var _evelyn_agent: RLPartyAgent
@onready var _evan_state: PartyMemberState
@onready var _evelyn_state: PartyMemberState
@onready var _team_agent: RLTeamAgent = $TeamAI

var _initial_evan_pos: Vector3
var _initial_evelyn_pos: Vector3

var _enemies: Array[EnemyAIController] = []
var _hive_agents: Array[RLEnemyHiveAgent] = []
var _episode_step: int = 0
var _episode_active: bool = false
var _party: Array[PartyMemberState] = []

## Stagnation tracking — party
var _steps_since_last_damage: int = 0
var _damage_dealt_this_step: bool = false

## Stagnation tracking — enemies
var _enemy_steps_since_last_damage: int = 0
var _enemy_damage_dealt_this_step: bool = false

## Long-term statistics
var _total_episodes: int = 0
var _party_wins: int = 0

## Curriculum state
var _curriculum_stage: int = 0
var _recent_results: Array[bool] = []  ## rolling window: true=party win, false=loss/timeout

## Stage definitions: [episode_timeout_steps, win_rate_to_advance, display_label]
## Steps = game-time minutes × 60s × 60 ticks (at 60 FPS physics)
## Steps at speed_up=10: real_seconds × 60 FPS × 10 speed_up = steps
## Stage 1:  1200 steps =  2 real-seconds/episode — ultra-fast cycling, pure exploration
## Stage 2:  3600 steps =  6 real-seconds/episode
## Stage 3:  7200 steps = 12 real-seconds/episode
## Stage 4: 14400 steps = 24 real-seconds/episode
## Stage 5: 28800 steps = 48 real-seconds/episode — full fights once AI is competent
const _CURRICULUM_STAGES: Array = [
	{"steps":  1200, "advance_at": 0.40, "label": "Stage 1 (~2s/ep)"},
	{"steps":  3600, "advance_at": 0.45, "label": "Stage 2 (~6s/ep)"},
	{"steps":  7200, "advance_at": 0.50, "label": "Stage 3 (~12s/ep)"},
	{"steps": 14400, "advance_at": 0.55, "label": "Stage 4 (~24s/ep)"},
	{"steps": 28800, "advance_at":  1.1, "label": "Stage 5 (~48s/ep)"},  ## final stage
]

func _ready() -> void:
	evan_body   = get_node_or_null(evan_body_path)   as CharacterBody3D
	evelyn_body = get_node_or_null(evelyn_body_path) as CharacterBody3D
	enemy_container = get_node_or_null(enemy_container_path) as Node3D

	if evan_body:
		_evan_agent = evan_body.get_node_or_null("RLPartyAgent")
		_evan_state = evan_body.get_node_or_null("PartyMemberState")
		_initial_evan_pos = evan_body.global_position
	if evelyn_body:
		_evelyn_agent = evelyn_body.get_node_or_null("RLPartyAgent")
		_evelyn_state = evelyn_body.get_node_or_null("PartyMemberState")
		_initial_evelyn_pos = evelyn_body.global_position

	_party = [_evan_state, _evelyn_state]
	if _evan_state:   _evan_state.death.connect(_on_party_member_died)
	if _evelyn_state: _evelyn_state.death.connect(_on_party_member_died)
	if _evan_agent and _evan_agent.skill_execution:
		_evan_agent.skill_execution.damage_dealt.connect(_on_party_damage_dealt)
		_evan_agent.skill_execution.projectile_spawned.connect(_on_party_projectile_spawned)
	if _evelyn_agent and _evelyn_agent.skill_execution:
		_evelyn_agent.skill_execution.damage_dealt.connect(_on_party_damage_dealt)
		_evelyn_agent.skill_execution.projectile_spawned.connect(_on_party_projectile_spawned)

	# Apply initial curriculum stage timeout
	if curriculum_enabled:
		max_episode_steps = _CURRICULUM_STAGES[0]["steps"]

	# Discover static enemies — already registered with godot_rl at scene load
	_find_enemies()
	_update_all_contexts()
	# Don't call _start_episode() here — Python sends "reset" after connecting,
	# which triggers needs_reset=true and calls _reset_episode() via _physics_process.

func _physics_process(delta: float) -> void:
	# godot_rl sets needs_reset=true when Python calls env.reset() after an episode ends.
	# Reset here — before sync.gd reads observations — so Python gets fresh state.
	if _evan_agent and _evan_agent.needs_reset:
		_reset_episode()
		return

	if not _episode_active:
		return

	_episode_step += 1

	# Push TeamPolicy directives to party agents
	if _team_agent:
		if _evan_agent:   _evan_agent.set_directive(_team_agent.evan_target, _team_agent.evan_role)
		if _evelyn_agent: _evelyn_agent.set_directive(_team_agent.evelyn_target, _team_agent.evelyn_role)

	_execute_party_movement(delta)
	_execute_enemy_movement(delta)

	# Survival reward per step
	var alive_ratio: float = _get_alive_party_ratio()
	if _team_agent:
		_team_agent.add_survival_reward(alive_ratio)

	_check_stagnation_penalty()
	_check_enemy_stagnation_penalty()
	_check_protection_bonus()
	_check_victory_or_defeat()
	_update_hud()

	if _episode_step >= max_episode_steps:
		_end_episode(false, true)  ## timeout — not a party wipe

# --- Enemy Discovery ---

func _find_enemies() -> void:
	## Read pre-placed RLEnemyController children from the Enemies container.
	## Called once in _ready() — enemies stay in scene tree for all episodes.
	if not enemy_container:
		return
	for child in enemy_container.get_children():
		if not child is RLEnemyController:
			continue
		var enemy := child as RLEnemyController
		var hive: RLEnemyHiveAgent = enemy.get_node_or_null("RLEnemyHiveAgent") as RLEnemyHiveAgent
		if not hive:
			push_warning("[ArenaManager] %s has no RLEnemyHiveAgent child — skipping." % enemy.name)
			continue
		enemy.died.connect(_on_enemy_died.bind(enemy, hive))
		enemy.damage_dealt.connect(_on_enemy_damage_dealt)
		enemy.projectile_spawned.connect(_on_enemy_projectile_spawned)
		hive.enemy_controller = enemy
		_enemies.append(enemy)
		_hive_agents.append(hive)

func _on_enemy_projectile_spawned(projectile: Projectile) -> void:
	# Connect party agents to this projectile so they can get dodge rewards
	if _evan_agent:
		projectile.missed.connect(_evan_agent._on_projectile_missed)
	if _evelyn_agent:
		projectile.missed.connect(_evelyn_agent._on_projectile_missed)

func _on_party_projectile_spawned(projectile: Projectile) -> void:
	# Connect all active hive agents to this projectile so they can get dodge rewards
	for hive in _hive_agents:
		if is_instance_valid(hive):
			projectile.missed.connect(hive._on_projectile_missed)

# --- Movement Execution ---

func _execute_party_movement(delta: float) -> void:
	_execute_agent_movement(evan_body, _evan_agent, delta)
	_execute_agent_movement(evelyn_body, _evelyn_agent, delta)

func _execute_agent_movement(body: CharacterBody3D, agent: RLPartyAgent, _delta: float) -> void:
	if not body or not agent or not agent.state or not agent.state.is_alive:
		if body:
			body.velocity = Vector3.ZERO
			body.move_and_slide()
		return

	var move_dir: Vector3 = Vector3.ZERO
	var enemies: Array = agent._context.get("enemies", [])

	match agent.pending_move_action:
		5:
			var target_idx: int = agent.directive_target
			if target_idx < enemies.size() and is_instance_valid(enemies[target_idx]) and enemies[target_idx].is_alive:
				move_dir = (enemies[target_idx].global_position - body.global_position).normalized()
			else:
				move_dir = _toward_nearest_enemy(body.global_position, enemies)
		6:
			var nearest: Vector3 = _nearest_enemy_pos(body.global_position, enemies)
			if nearest != Vector3.ZERO:
				move_dir = (body.global_position - nearest).normalized()
		7:
			var ally_body: CharacterBody3D = _lowest_hp_ally_body(body)
			if ally_body:
				move_dir = (ally_body.global_position - body.global_position).normalized()
		8:
			move_dir = Vector3.ZERO

	body.velocity = move_dir * move_speed
	body.move_and_slide()

func _execute_enemy_movement(_delta: float) -> void:
	var party_bodies: Array[CharacterBody3D] = []
	if evan_body: party_bodies.append(evan_body)
	if evelyn_body: party_bodies.append(evelyn_body)

	for i in range(_enemies.size()):
		var enemy: EnemyAIController = _enemies[i]
		var hive: RLEnemyHiveAgent = _hive_agents[i] if i < _hive_agents.size() else null
		if not enemy or not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		if not hive:
			continue

		var move_dir: Vector3 = Vector3.ZERO
		var party_states: Array = hive._context.get("party", [])

		match hive.pending_move_action:
			3:
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (nearest - enemy.global_position).normalized()
			4:
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (enemy.global_position - nearest).normalized()
			5:
				var target_body: CharacterBody3D = _lowest_hp_alive_party_body(party_bodies, party_states)
				if target_body:
					move_dir = (target_body.global_position - enemy.global_position).normalized()
			_:
				# Action 0 (idle/wait): scripted fallback — chase nearest party member so enemies
				# always close distance. RL learns when to retreat or reposition (actions 4/5).
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					var dist: float = enemy.global_position.distance_to(nearest)
					if dist > enemy.stop_distance:
						move_dir = (nearest - enemy.global_position).normalized()

		# Freeze movement during cast — enemy stands still while winding up the attack
		if enemy.is_casting():
			enemy.velocity.x = 0.0
			enemy.velocity.z = 0.0
			continue

		# Only override horizontal velocity — preserve y so gravity accumulates in enemy's _physics_process
		enemy.velocity.x = move_dir.x * enemy.move_speed
		enemy.velocity.z = move_dir.z * enemy.move_speed

# --- Episode Management ---

func _start_episode() -> void:
	_episode_step = 0
	_update_all_contexts()
	_episode_active = true

## victory=true: party killed all enemies.
## victory=false + timeout=true: step limit reached, no winner.
## victory=false + timeout=false: party was wiped.
func _end_episode(victory: bool, timeout: bool = false) -> void:
	if not _episode_active: return
	_episode_active = false
	_total_episodes += 1
	if victory: _party_wins += 1

	# Curriculum tracking — always record, independent of outcome signals
	if curriculum_enabled:
		_recent_results.append(victory)
		if _recent_results.size() > curriculum_eval_window:
			_recent_results.pop_front()
		_update_curriculum()

	# Signal outcome — must set done=true on all agents so Python triggers env.reset()
	if _evan_agent: _evan_agent.done = true
	if _evelyn_agent: _evelyn_agent.done = true
	for hive in _hive_agents:
		if is_instance_valid(hive): hive.done = true

	if victory:
		if _team_agent: _team_agent.on_victory()
		for hive in _hive_agents:
			if is_instance_valid(hive): hive.on_all_enemies_killed()
	elif timeout:
		# Neither side won — small defeat signal for party, no bonus for enemies
		if _team_agent: _team_agent.on_defeat()
		# Enemies get no bonus reward for a timeout draw
	else:
		# Actual party wipe
		if _team_agent: _team_agent.on_defeat()
		for hive in _hive_agents:
			if is_instance_valid(hive): hive.on_party_wiped()
	## Do NOT reset here. godot_rl sends done=true to Python, Python calls reset(),
	## godot_rl sends "reset" message back to Godot, sync.gd sets needs_reset=true,
	## and we detect that at the top of _physics_process to reset cleanly.

func _reset_episode() -> void:
	## Synchronous — no awaits. Called from _physics_process when needs_reset is true,
	## which runs before sync.gd reads obs for the reset response to Python.
	_steps_since_last_damage = 0
	_damage_dealt_this_step = false
	_enemy_steps_since_last_damage = 0
	_enemy_damage_dealt_this_step = false

	# Reset party — cancel any in-flight casts before resetting state
	if _evan_agent and _evan_agent.skill_execution:   _evan_agent.skill_execution.cancel_cast()
	if _evelyn_agent and _evelyn_agent.skill_execution: _evelyn_agent.skill_execution.cancel_cast()
	if _evan_state:   _evan_state.reset_for_encounter(true)
	if _evelyn_state: _evelyn_state.reset_for_encounter(true)
	if evan_body:   evan_body.global_position   = _initial_evan_pos
	if evelyn_body: evelyn_body.global_position = _initial_evelyn_pos

	# Reset enemies in-place
	for enemy in _enemies:
		if is_instance_valid(enemy):
			(enemy as RLEnemyController).reset_to_start()

	# Reset all AI controllers (agent.reset() clears needs_reset and n_steps)
	if _evan_agent:   _evan_agent.reset()
	if _evelyn_agent: _evelyn_agent.reset()
	if _team_agent:   _team_agent.reset()
	for hive in _hive_agents:
		if is_instance_valid(hive):
			hive.reset()
			hive.done = false  ## base reset() does not clear done

	_update_all_contexts()
	_start_episode()

func _update_curriculum() -> void:
	if _total_episodes < curriculum_min_episodes:
		return
	if _recent_results.size() < curriculum_eval_window:
		return
	if _curriculum_stage >= _CURRICULUM_STAGES.size() - 1:
		return  ## Already at final stage

	var wins: int = 0
	for r: bool in _recent_results:
		if r: wins += 1
	var win_rate: float = float(wins) / float(_recent_results.size())

	var threshold: float = _CURRICULUM_STAGES[_curriculum_stage]["advance_at"]
	if win_rate >= threshold:
		_curriculum_stage += 1
		max_episode_steps = _CURRICULUM_STAGES[_curriculum_stage]["steps"]
		_recent_results.clear()  ## Reset window so next stage is judged fresh
		print("[Curriculum] Advanced to %s — win rate was %.1f%% over last %d episodes. Timeout: %d steps." % [
			_CURRICULUM_STAGES[_curriculum_stage]["label"],
			win_rate * 100.0,
			curriculum_eval_window,
			max_episode_steps,
		])

func _update_all_contexts() -> void:
	if _evan_agent: _evan_agent.set_context({"enemies": _enemies, "allies": [_evelyn_state]})
	if _evelyn_agent: _evelyn_agent.set_context({"enemies": _enemies, "allies": [_evan_state]})
	if _team_agent: _team_agent.set_context({"enemies": _enemies})

	for i in range(_hive_agents.size()):
		if is_instance_valid(_hive_agents[i]):
			_hive_agents[i].set_context({
				"party": [_evan_state, _evelyn_state],
				"enemy_allies": _enemies,
			})

# --- Reward Routing ---

func _on_enemy_died(_enemy: EnemyAIController, _hive: RLEnemyHiveAgent) -> void:
	if _team_agent: _team_agent.on_enemy_killed()
	if _evan_agent: _evan_agent.reward += 0.5 * _evan_agent.w_team
	if _evelyn_agent: _evelyn_agent.reward += 0.5 * _evelyn_agent.w_team
	## Note: do NOT set hive.done = true here.
	## Mid-episode individual termination causes RLlib/godot_rl sync mismatches.
	## All agents terminate together at episode end.
	_update_all_contexts()
	_check_victory_or_defeat()

func _on_party_member_died() -> void:
	if _team_agent: _team_agent.on_ally_died()
	for hive in _hive_agents:
		if is_instance_valid(hive): hive.on_party_member_killed()
	_check_victory_or_defeat()

func _check_protection_bonus() -> void:
	if not _evan_agent or not _evelyn_agent or not evan_body or not evelyn_body:
		return
	if not _evan_state or not _evan_state.is_alive:
		return
	for enemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var evan_pos: Vector3 = evan_body.global_position
		var evelyn_pos: Vector3 = evelyn_body.global_position
		var enemy_pos: Vector3 = enemy.global_position
		var to_evelyn: Vector3 = (evelyn_pos - enemy_pos).normalized()
		var to_evan: Vector3 = (evan_pos - enemy_pos).normalized()
		if to_evan.dot(to_evelyn) > 0.7 and evan_pos.distance_to(enemy_pos) < evelyn_pos.distance_to(enemy_pos):
			_evan_agent.on_protection_bonus()
			break

func _check_victory_or_defeat() -> void:
	if not _episode_active:
		return
	var all_enemies_dead: bool = true
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			all_enemies_dead = false
			break
	if all_enemies_dead:
		_end_episode(true)
		return
	var party_wiped: bool = (not _evan_state or not _evan_state.is_alive) and \
							(not _evelyn_state or not _evelyn_state.is_alive)
	if party_wiped:
		_end_episode(false)

# --- Helpers ---

func _get_alive_party_ratio() -> float:
	var alive: int = 0
	if _evan_state and _evan_state.is_alive: alive += 1
	if _evelyn_state and _evelyn_state.is_alive: alive += 1
	return float(alive) / 2.0

func _toward_nearest_enemy(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF
	var best_dir: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist: float = from.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_dir = (enemy.global_position - from).normalized()
	return best_dir

func _nearest_enemy_pos(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF
	var best_pos: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist: float = from.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_pos = enemy.global_position
	return best_pos

func _nearest_alive_party_pos(from: Vector3, party_bodies: Array) -> Vector3:
	var best_dist: float = INF
	var best_pos: Vector3 = Vector3.ZERO
	for body in party_bodies:
		if body and is_instance_valid(body):
			var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
			if state and state.is_alive:
				var dist: float = from.distance_to(body.global_position)
				if dist < best_dist:
					best_dist = dist
					best_pos = body.global_position
	return best_pos

func _lowest_hp_ally_body(self_body: CharacterBody3D) -> CharacterBody3D:
	var bodies: Array = [evan_body, evelyn_body]
	var best_ratio: float = INF
	var best_body: CharacterBody3D = null
	for body in bodies:
		if body == self_body or not body:
			continue
		var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive:
			var ratio: float = state.get_hp_ratio()
			if ratio < best_ratio:
				best_ratio = ratio
				best_body = body
	return best_body

func _lowest_hp_alive_party_body(party_bodies: Array, _party_states: Array) -> CharacterBody3D:
	var best_ratio: float = INF
	var best_body: CharacterBody3D = null
	for body in party_bodies:
		if not body: continue
		var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive and state.get_hp_ratio() < best_ratio:
			best_ratio = state.get_hp_ratio()
			best_body = body
	return best_body

func _on_party_damage_dealt(_amount: int, _target: Node) -> void:
	_damage_dealt_this_step = true

func _on_enemy_damage_dealt(_amount: int, _target: Node) -> void:
	_enemy_damage_dealt_this_step = true

func _check_stagnation_penalty() -> void:
	if _damage_dealt_this_step:
		_steps_since_last_damage = 0
		_damage_dealt_this_step = false
		return

	_steps_since_last_damage += 1

	var any_enemy_alive: bool = false
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			any_enemy_alive = true
			break

	if not any_enemy_alive or _steps_since_last_damage < stagnation_threshold:
		return

	if _team_agent:   _team_agent.reward -= w_stagnation
	if _evan_agent:   _evan_agent.reward -= w_stagnation
	if _evelyn_agent: _evelyn_agent.reward -= w_stagnation

func _check_enemy_stagnation_penalty() -> void:
	if _enemy_damage_dealt_this_step:
		_enemy_steps_since_last_damage = 0
		_enemy_damage_dealt_this_step = false
		return

	_enemy_steps_since_last_damage += 1

	var party_alive: bool = (_evan_state and _evan_state.is_alive) or \
							(_evelyn_state and _evelyn_state.is_alive)
	if not party_alive or _enemy_steps_since_last_damage < stagnation_threshold:
		return

	for i in range(_hive_agents.size()):
		var hive: RLEnemyHiveAgent = _hive_agents[i]
		var enemy: EnemyAIController = _enemies[i] if i < _enemies.size() else null
		if not is_instance_valid(hive) or not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var hp_ratio: float = enemy.get_hp_ratio() if enemy.has_method("get_hp_ratio") else 1.0
		if hp_ratio < 0.2:
			continue  ## Near-death enemy may be repositioning — exempt
		hive.reward -= w_stagnation


func _update_hud() -> void:
	if _evan_state:
		var label = get_node_or_null("%EvanHP")
		if label: label.text = "Evan: %d/%d" % [_evan_state.current_hp, _evan_state.max_hp]
	if _evelyn_state:
		var label = get_node_or_null("%EvelynHP")
		if label: label.text = "Evelyn: %d/%d" % [_evelyn_state.current_hp, _evelyn_state.max_hp]

	var step_label = get_node_or_null("%StepLabel")
	if step_label: step_label.text = "Step: %d" % _episode_step

	var wr_label = get_node_or_null("%WinRate")
	if wr_label:
		var wr: float = (float(_party_wins) / float(_total_episodes)) * 100.0 if _total_episodes > 0 else 0.0
		wr_label.text = "Win Rate: %.1f%% (%d/%d)" % [wr, _party_wins, _total_episodes]

	var stage_label = get_node_or_null("%CurriculumStage")
	if stage_label:
		var stage_name: String = _CURRICULUM_STAGES[_curriculum_stage]["label"]
		stage_label.text = "Curriculum: %s" % stage_name

	var evan_r = get_node_or_null("%EvanReward")
	if evan_r and _evan_agent: evan_r.text = "Evan R: %.3f" % _evan_agent.reward

	var evelyn_r = get_node_or_null("%EvelynReward")
	if evelyn_r and _evelyn_agent: evelyn_r.text = "Evelyn R: %.3f" % _evelyn_agent.reward

	var team_r = get_node_or_null("%TeamReward")
	if team_r and _team_agent: team_r.text = "Team R: %.3f" % _team_agent.reward

	var enemy_r = get_node_or_null("%EnemyReward")
	if enemy_r:
		var total: float = 0.0
		var count: int = 0
		for i in range(_hive_agents.size()):
			if is_instance_valid(_hive_agents[i]) and is_instance_valid(_enemies[i]) and _enemies[i].is_alive:
				total += _hive_agents[i].reward
				count += 1
		enemy_r.text = "Enemy R: %.3f" % (total / count if count > 0 else 0.0)
