# player_movement_controller.gd
class_name PlayerMovementController
extends Node

## Reads move input and translates the currently player-controlled character.

@export var input_manager: InputManager
@export var switch_controller: CharacterSwitchController
@export var move_speed: float = 5.0

var _move_input: Vector2 = Vector2.ZERO

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
	
	# Calculate movement relative to camera
	var camera := get_viewport().get_camera_3d()
	if not camera: return
	
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var move_dir := (forward * -_move_input.y + right * _move_input.x).normalized()
	
	if move_dir.length() > 0.01:
		character_node.velocity = move_dir * move_speed
		
		# Rotate toward movement
		var target_basis := Basis.looking_at(move_dir, Vector3.UP)
		character_node.basis = character_node.basis.slerp(target_basis, 10.0 * delta)
	else:
		character_node.velocity = character_node.velocity.move_toward(Vector3.ZERO, move_speed * 10.0 * delta)
		
	character_node.move_and_slide()
