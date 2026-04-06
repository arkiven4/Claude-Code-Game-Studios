# static_camera.gd
extends Camera3D

## Forces the camera to stay at its initial global position.
## Useful for RL training/inference to prevent accidental following.

@onready var _initial_pos: Vector3 = global_position
@onready var _initial_rot: Vector3 = global_rotation

func _process(_delta: float) -> void:
	global_position = _initial_pos
	global_rotation = _initial_rot
