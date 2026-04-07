# rl_enemy_controller.gd
class_name RLEnemyController
extends EnemyAIController

## Training-only subclass of EnemyAIController.
## Prevents queue_free() on death so godot_rl keeps the agent reference alive.
## Arena manager calls reset_to_start() between episodes instead of destroy/respawn.

var _initial_transform: Transform3D

func _ready() -> void:
	super._ready()
	_initial_transform = global_transform
	# Force rl_controlled regardless of Inspector value — this subclass exists only for RL
	# training. Without this, the scripted AI brain runs and overwrites RL movement commands.
	rl_controlled = true

func _die() -> void:
	## Override: suppress queue_free() — hive agent child must stay in scene tree
	is_alive = false
	died.emit()
	## queue_free() intentionally omitted for RL training

func reset_to_start() -> void:
	global_transform = _initial_transform
	current_hp = max_hp
	is_alive = true
	is_enraged = false
	velocity = Vector3.ZERO
	shield_value = 0
	shield_changed.emit(0)
	_skill_cooldowns.fill(0.0)
	_basic_attack_cooldown = 0.0
	_decision_timer = _get_decision_interval()
	_current_target = null
	## Clear cast state so the next episode doesn't start mid-cast
	_is_casting = false
	_cast_timer = 0.0
	_current_cast_skill_index = -1
	_current_cast_target = null
