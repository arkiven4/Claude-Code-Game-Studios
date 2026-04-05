# training_arena_manager.gd
# Manages RL training episodes: spawns agents/enemies, resets on episode end.
# Attached to the root node of TrainingArena.tscn.
extends Node3D

@export var agent_character_data: CharacterData
@export var enemy_data: EnemyData
@export var enemy_spawn_count: int = 1

@onready var _rl_agent: RLPartyAgent = $AgentBody/RLPartyAgent
@onready var _agent_state: PartyMemberState = $AgentBody/PartyMemberState
@onready var _enemy_container: Node3D = $EnemyContainer

var _enemies: Array[EnemyAIController] = []
var _episode_active: bool = false

func _ready() -> void:
	_start_episode()

func _process(_delta: float) -> void:
	if not _episode_active:
		return

	# Check win condition: all enemies dead
	var all_dead := true
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			all_dead = false
			break

	if all_dead:
		_rl_agent.on_encounter_won()
		_episode_active = false
		await get_tree().create_timer(0.2).timeout
		_reset_episode()

	# Check lose condition: agent dead
	if _agent_state and not _agent_state.is_alive:
		_rl_agent.on_ally_died()
		_episode_active = false
		await get_tree().create_timer(0.2).timeout
		_reset_episode()

	# Force episode end after timeout (safety net)
	if _rl_agent.needs_reset:
		_reset_episode()

func _start_episode() -> void:
	_spawn_enemies()
	_setup_context()
	_episode_active = true

func _reset_episode() -> void:
	# Reset agent state
	if _agent_state:
		_agent_state.reset_for_encounter(true)

	# Clear and re-spawn enemies
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	await get_tree().process_frame

	_rl_agent.reset()
	_start_episode()

func _spawn_enemies() -> void:
	var enemy_scene := preload("res://assets/scenes/enemies/GruntMelee.tscn")
	for i in range(enemy_spawn_count):
		var enemy: EnemyAIController = enemy_scene.instantiate()
		_enemy_container.add_child(enemy)
		# Spread enemies slightly
		enemy.global_position = Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(4.0, 8.0))
		enemy.died.connect(_on_enemy_died.bind(enemy))
		_enemies.append(enemy)

func _setup_context() -> void:
	_rl_agent.set_context({
		"allies": [],         # Solo agent — no allies in this training scene
		"enemies": _enemies,
	})
	# Point enemy AI at the agent body
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy._current_target = $AgentBody

func _on_enemy_died(_enemy: EnemyAIController) -> void:
	_rl_agent.on_enemy_killed()
