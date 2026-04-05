# rl_arena_manager.gd
# Root script for TrainingArena.tscn.
# Handles: episode resets, movement execution, directive routing, reward wiring.
extends Node3D

@export var evan_body_path: NodePath
@export var evelyn_body_path: NodePath
@export var enemy_container_path: NodePath

@export var move_speed: float = 4.0
@export var max_episode_steps: int = 2000

var evan_body: CharacterBody3D
var evelyn_body: CharacterBody3D
var enemy_container: Node3D

@onready var _evan_agent: RLPartyAgent
@onready var _evelyn_agent: RLPartyAgent
@onready var _evan_state: PartyMemberState
@onready var _evelyn_state: PartyMemberState
@onready var _team_agent: RLTeamAgent = $TeamAI

const GRUNT_SCENE: PackedScene = preload("res://assets/scenes/enemies/GruntMelee.tscn")
const ARCHER_SCENE: PackedScene = preload("res://assets/scenes/enemies/ArcherRanged.tscn")

## Spawn transforms (position, rotation) for enemies — set to match TestArena layout
var ENEMY_SPAWNS: Array[Transform3D] = [
	Transform3D(Basis.IDENTITY, Vector3(-4.0, 0.9, 8.0)),
	Transform3D(Basis.IDENTITY, Vector3(4.0,  0.9, 8.0)),
	Transform3D(Basis.IDENTITY, Vector3(0.0,  0.9, 10.0)),
]
const ENEMY_SCENES: Array = [GRUNT_SCENE, GRUNT_SCENE, ARCHER_SCENE]

var _enemies: Array[EnemyAIController] = []
var _hive_agents: Array[RLEnemyHiveAgent] = []
var _episode_step: int = 0
var _episode_active: bool = false
var _party: Array[PartyMemberState] = []

func _ready() -> void:
	# Resolve node references from paths
	evan_body = get_node_or_null(evan_body_path) as CharacterBody3D
	evelyn_body = get_node_or_null(evelyn_body_path) as CharacterBody3D
	enemy_container = get_node_or_null(enemy_container_path) as Node3D
	
	if evan_body:
		_evan_agent = evan_body.get_node_or_null("RLPartyAgent")
		_evan_state = evan_body.get_node_or_null("PartyMemberState")
	if evelyn_body:
		_evelyn_agent = evelyn_body.get_node_or_null("RLPartyAgent")
		_evelyn_state = evelyn_body.get_node_or_null("PartyMemberState")

	_party = [_evan_state, _evelyn_state]
	# Wire party death to hive rewards
	if _evan_state: _evan_state.death.connect(_on_party_member_died)
	if _evelyn_state: _evelyn_state.death.connect(_on_party_member_died)
	
	await get_tree().process_frame
	_start_episode()

func _physics_process(delta: float) -> void:
	if not _episode_active:
		return

	_episode_step += 1

	# Push TeamPolicy directives to party agents
	if _team_agent:
		if _evan_agent:
			_evan_agent.set_directive(_team_agent.evan_target, _team_agent.evan_role)
		if _evelyn_agent:
			_evelyn_agent.set_directive(_team_agent.evelyn_target, _team_agent.evelyn_role)

	# Execute party movement
	_execute_party_movement(delta)
	# Execute enemy movement
	_execute_enemy_movement(delta)

	# Survival reward per step
	var alive_ratio: float = _get_alive_party_ratio()
	if _team_agent:
		_team_agent.add_survival_reward(alive_ratio)

	# Check protection bonus for Evan (tanker between enemy and Evelyn)
	_check_protection_bonus()

	# Check end conditions
	_check_victory_or_defeat()

	# Force-end episode after timeout
	if _episode_step >= max_episode_steps:
		_end_episode(false)

# --- Movement Execution ---

func _execute_party_movement(delta: float) -> void:
	_execute_agent_movement(evan_body, _evan_agent, delta)
	_execute_agent_movement(evelyn_body, _evelyn_agent, delta)

func _execute_agent_movement(body: CharacterBody3D, agent: RLPartyAgent, delta: float) -> void:
	if not body or not agent or not agent.state or not agent.state.is_alive:
		if body:
			body.velocity = Vector3.ZERO
			body.move_and_slide()
		return

	var move_dir: Vector3 = Vector3.ZERO
	var enemies: Array = agent._context.get("enemies", [])

	match agent.pending_move_action:
		5:  ## move toward focus_target enemy
			var target_idx: int = agent.directive_target
			if target_idx < enemies.size() and is_instance_valid(enemies[target_idx]) and enemies[target_idx].is_alive:
				move_dir = (enemies[target_idx].global_position - body.global_position).normalized()
			else:
				move_dir = _toward_nearest_enemy(body.global_position, enemies)
		6:  ## move away from nearest enemy
			var nearest: Vector3 = _nearest_enemy_pos(body.global_position, enemies)
			if nearest != Vector3.ZERO:
				move_dir = (body.global_position - nearest).normalized()
		7:  ## move toward lowest-HP ally
			var ally_body: CharacterBody3D = _lowest_hp_ally_body(body)
			if ally_body:
				move_dir = (ally_body.global_position - body.global_position).normalized()
		8:  ## hold position
			move_dir = Vector3.ZERO

	body.velocity = move_dir * move_speed
	body.move_and_slide()

func _execute_enemy_movement(delta: float) -> void:
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
			3:  ## move toward nearest party member
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (nearest - enemy.global_position).normalized()
			4:  ## reposition away
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (enemy.global_position - nearest).normalized()
			5:  ## move toward lowest-HP party member
				var target_body: CharacterBody3D = _lowest_hp_alive_party_body(party_bodies, party_states)
				if target_body:
					move_dir = (target_body.global_position - enemy.global_position).normalized()

		enemy.velocity = move_dir * enemy.move_speed
		enemy.move_and_slide()

# --- Episode Management ---

func _start_episode() -> void:
	_episode_step = 0
	_spawn_enemies()
	_update_all_contexts()
	_episode_active = true

func _end_episode(victory: bool) -> void:
	if not _episode_active: return
	_episode_active = false

	if victory:
		if _team_agent: _team_agent.on_victory()
		if _evan_agent: _evan_agent.done = true
		if _evelyn_agent: _evelyn_agent.done = true
		for hive in _hive_agents:
			if is_instance_valid(hive): hive.on_all_enemies_killed()
	else:
		if _team_agent: _team_agent.on_defeat()
		if _evan_agent: _evan_agent.done = true
		if _evelyn_agent: _evelyn_agent.done = true
		for hive in _hive_agents:
			if is_instance_valid(hive): hive.on_party_wiped()

	await get_tree().create_timer(0.1).timeout
	_reset_episode()

func _reset_episode() -> void:
	# Reset party
	if _evan_state: _evan_state.reset_for_encounter(true)
	if _evelyn_state: _evelyn_state.reset_for_encounter(true)
	if evan_body: evan_body.global_position = Vector3(-1.0, 1.0, 0.0)
	if evelyn_body: evelyn_body.global_position = Vector3(1.0, 1.0, 0.0)

	# Destroy and respawn enemies
	for enemy in _enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	_enemies.clear()
	_hive_agents.clear()
	await get_tree().process_frame

	# Reset AI controllers
	if _evan_agent: _evan_agent.reset()
	if _evelyn_agent: _evelyn_agent.reset()
	if _team_agent: _team_agent.reset()

	_start_episode()

func _spawn_enemies() -> void:
	for i in range(ENEMY_SPAWNS.size()):
		var scene: PackedScene = ENEMY_SCENES[i]
		var enemy: EnemyAIController = scene.instantiate()
		enemy_container.add_child(enemy)
		enemy.global_transform = ENEMY_SPAWNS[i]

		var hive: RLEnemyHiveAgent = RLEnemyHiveAgent.new()
		hive.policy_name = "enemy_hive"
		hive.reset_after = max_episode_steps
		enemy.add_child(hive)
		hive.enemy_controller = enemy

		enemy.died.connect(_on_enemy_died.bind(enemy, hive))
		_enemies.append(enemy)
		_hive_agents.append(hive)

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
		## Check if Evan is between enemy and Evelyn
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
	var party_wiped: bool = (not _evan_state or not _evan_state.is_alive) and (not _evelyn_state or not _evelyn_state.is_alive)
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
