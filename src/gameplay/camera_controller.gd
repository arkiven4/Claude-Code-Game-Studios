# camera_controller.gd
class_name CameraController
extends Node3D

## Third-person camera with Exploration, Combat, and Cinematic modes.
## Uses SpringArm3D + Camera3D — no external addons required.
## Reference: design/gdd/camera-system.md

enum CameraMode { EXPLORATION, COMBAT, CINEMATIC }

@export var spring_arm: SpringArm3D
@export var camera: Camera3D
@export var encounter_manager: CombatEncounterManager
@export var follow_target: Node3D  # Set to active character at runtime

@export var exploration_length: float = 8.0
@export var exploration_height: float = 4.0
@export var combat_length_small: float = 6.0   # 1-2 enemies
@export var combat_length_medium: float = 8.0  # 3-4 enemies
@export var combat_length_large: float = 10.0  # 5+ enemies
@export var transition_duration: float = 0.5

var _mode: CameraMode = CameraMode.EXPLORATION

func _ready() -> void:
	if encounter_manager:
		encounter_manager.combat_started.connect(_on_combat_started)
		encounter_manager.combat_ended.connect(_on_combat_ended)
	set_mode(CameraMode.EXPLORATION)

func _physics_process(delta: float) -> void:
	if follow_target:
		global_position = global_position.lerp(follow_target.global_position, 10.0 * delta)

func set_mode(mode: CameraMode) -> void:
	_mode = mode
	match mode:
		CameraMode.EXPLORATION:
			_tween_spring_arm(exploration_length)
		CameraMode.CINEMATIC:
			pass  # handled externally via animation

func set_combat_length(enemy_count: int) -> void:
	var length: float
	if enemy_count <= 2:
		length = combat_length_small
	elif enemy_count <= 4:
		length = combat_length_medium
	else:
		length = combat_length_large
	_tween_spring_arm(length)

func _tween_spring_arm(target_length: float) -> void:
	if not spring_arm: return
	var tween := create_tween()
	tween.tween_property(spring_arm, "spring_length", target_length, transition_duration)

func _on_combat_started() -> void:
	set_mode(CameraMode.COMBAT)
	if encounter_manager:
		set_combat_length(encounter_manager.enemies_remaining)

func _on_combat_ended() -> void:
	set_mode(CameraMode.EXPLORATION)
