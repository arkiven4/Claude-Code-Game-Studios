## TestPlayer — temporary movement script for procedural level testing only.
## Attach to CharacterBody3D. Delete when replacing with real player controller.
extends CharacterBody3D

const SPEED: float = 8.0
const GRAVITY: float = 20.0

func _ready() -> void:
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# WASD / arrow key movement (top-down flat movement)
	var dir := Vector3.ZERO
	dir.x = Input.get_axis("ui_left", "ui_right")
	dir.z = Input.get_axis("ui_up", "ui_down")

	if dir.length() > 0.0:
		velocity.x = dir.normalized().x * SPEED
		velocity.z = dir.normalized().z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()
