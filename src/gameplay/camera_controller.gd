# camera_controller.gd
class_name CameraController
extends Node3D

## Third-person Elden Ring-style orbit camera.
## Horizontal mouse/stick -> yaw (rotates this node on Y).
## Vertical mouse/stick -> pitch (rotates CameraPivot on X).
## Camera3D sits at (0, 3, 8) inside CameraPivot and always look_at the follow target.
## Reference: design/gdd/camera-system.md

enum CameraMode { EXPLORATION, COMBAT, CINEMATIC }

@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var encounter_manager: CombatEncounterManager
@export var follow_target: Node3D  ## Set to active character at runtime

@export var look_speed: float = 2.0           ## Keyboard/stick orbit speed (radians/s)
@export var mouse_sensitivity: float = 0.002  ## Mouse orbit speed (radians/pixel)
@export var follow_speed: float = 15.0        ## Position follow lerp factor

var _mode: CameraMode = CameraMode.EXPLORATION
var _orbit_input: Vector2 = Vector2.ZERO   ## From keyboard/stick (rate, per second)
var _mouse_delta: Vector2 = Vector2.ZERO   ## Accumulated mouse motion since last physics tick

func _ready() -> void:
	if encounter_manager:
		encounter_manager.combat_started.connect(_on_combat_started)
		encounter_manager.combat_ended.connect(_on_combat_ended)
	if follow_target:
		global_position = follow_target.global_position
	if camera:
		camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_delta += event.relative

func _physics_process(delta: float) -> void:
	# Smooth follow
	if follow_target:
		global_position = global_position.lerp(follow_target.global_position, follow_speed * delta)

	# Keyboard / stick orbit (rate-based — multiply by delta)
	if _orbit_input.length_squared() > 0.0:
		rotate_y(-_orbit_input.x * look_speed * delta)
		if camera_pivot:
			var new_pitch := camera_pivot.rotation.x - _orbit_input.y * look_speed * delta
			camera_pivot.rotation.x = clamp(new_pitch, deg_to_rad(-60), deg_to_rad(30))
		_orbit_input = Vector2.ZERO

	# Mouse orbit (event-based — already a delta, no extra delta multiplication)
	if _mouse_delta.length_squared() > 0.0:
		rotate_y(-_mouse_delta.x * mouse_sensitivity)
		if camera_pivot:
			var new_pitch := camera_pivot.rotation.x - _mouse_delta.y * mouse_sensitivity
			camera_pivot.rotation.x = clamp(new_pitch, deg_to_rad(-60), deg_to_rad(30))
		_mouse_delta = Vector2.ZERO

	# Always look at the player's head so the angle is correct regardless of orbit
	if camera and follow_target:
		camera.look_at(follow_target.global_position + Vector3(0, 1.0, 0))

## Called by InputManager signal (keyboard/stick look input)
func on_camera_orbit(dir: Vector2) -> void:
	_orbit_input = dir

func set_mode(mode: CameraMode) -> void:
	_mode = mode

func _on_combat_started() -> void:
	set_mode(CameraMode.COMBAT)

func _on_combat_ended() -> void:
	set_mode(CameraMode.EXPLORATION)
