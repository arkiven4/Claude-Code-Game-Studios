# player_movement_controller.gd
class_name PlayerMovementController
extends Node

## Reads move input and translates the currently player-controlled character.

@export var input_manager: InputManager
@export var switch_controller: CharacterSwitchController
@export var move_speed: float = 5.0
@export var dodge_multiplier: float = 3.0
@export var dodge_duration: float = 0.2

var _move_input: Vector2 = Vector2.ZERO
var _is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	if input_manager:
		input_manager.move_direction.connect(_on_move_direction)

func _on_move_direction(dir: Vector2) -> void:
	_move_input = dir

func _physics_process(delta: float) -> void:
	if not switch_controller: return
	
	var current := switch_controller.current_character
	if not current or not current.is_alive: return
	
	var character_node := current.get_parent() as CharacterBody3D
	if not character_node: return
	
	if _is_dodging:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			_is_dodging = false
			current.set_invincible(false)
		else:
			character_node.velocity.x = _dodge_dir.x * move_speed * dodge_multiplier
			character_node.velocity.z = _dodge_dir.z * move_speed * dodge_multiplier
			character_node.move_and_slide()
			return

	# Calculate movement relative to camera (fallback to world axes if camera unavailable)
	var camera := get_viewport().get_camera_3d()
	var forward: Vector3
	var right: Vector3
	if camera:
		forward = -camera.global_transform.basis.z
		right = camera.global_transform.basis.x
	else:
		forward = Vector3(0, 0, 1)
		right = Vector3(1, 0, 0)
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var move_dir := (forward * -_move_input.y + right * _move_input.x).normalized()
	
	# Apply movement velocity
	var target_velocity := move_dir * move_speed
	character_node.velocity.x = target_velocity.x
	character_node.velocity.z = target_velocity.z
	
	# Apply gravity
	if not character_node.is_on_floor():
		character_node.velocity += character_node.get_gravity() * delta
	
	if move_dir.length() > 0.01:
		# Rotate toward movement
		var target_basis := Basis.looking_at(move_dir, Vector3.UP)
		character_node.basis = character_node.basis.slerp(target_basis, 10.0 * delta)
	else:
		character_node.velocity.x = move_toward(character_node.velocity.x, 0, move_speed * 10.0 * delta)
		character_node.velocity.z = move_toward(character_node.velocity.z, 0, move_speed * 10.0 * delta)
		
	character_node.move_and_slide()

## Triggers a dodge/dash for the current character.
func dodge() -> void:
	if _is_dodging: return
	if not switch_controller: return
	
	var current := switch_controller.current_character
	if not current or not current.is_alive: return
	
	var character_node := current.get_parent() as CharacterBody3D
	if not character_node: return
	
	# Try consume MP
	if not current.try_consume_dodge_mp():
		return
		
	_is_dodging = true
	_dodge_timer = dodge_duration
	current.set_invincible(true)
	
	# Dodge in current move direction, or forward if standing still
	if character_node.velocity.length() > 0.1:
		_dodge_dir = character_node.velocity.normalized()
	else:
		_dodge_dir = -character_node.global_transform.basis.z
