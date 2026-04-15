# floating_damage_number.gd
class_name FloatingDamageNumber
extends Node3D

## Spawns a floating damage/heal number at a world position.
## Numbers float upward, fade out, and self-destruct.

static func spawn(
	tree: SceneTree,
	position: Vector3,
	value: int,
	is_heal: bool = false,
	is_crit: bool = false,
	source_position: Vector3 = Vector3.ZERO
) -> void:
	var label := Label3D.new()

	# Text content
	var prefix: String = "+" if is_heal else ""
	var suffix: String = "!" if is_crit else ""
	label.text = "%s%d%s" % [prefix, value, suffix]

	# Appearance - 1.5x bigger (from 72/54 -> 108/81)
	label.font_size = 108 if is_crit else 81
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.outline_modulate = Color.BLACK
	label.outline_size = 18
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED

	if is_heal:
		label.modulate = Color(0.2, 1.0, 0.4, 1.0)
	elif is_crit:
		label.modulate = Color(1.0, 0.9, 0.0, 1.0)
	else:
		label.modulate = Color(1.0, 0.25, 0.15, 1.0)

	# Use VFX_Spawner if ImpactVFXManager is active, else root
	var parent: Node = tree.root
	if tree.root.has_node("VFX_Spawner"):
		parent = tree.root.get_node("VFX_Spawner")
	
	parent.add_child(label)
	
	# Initial position (head level)
	label.global_position = position

	# Billboard so it always faces the camera
	label.no_depth_test = false 

	# Animate: Bounce towards attacker and drop to ground
	var duration: float = 1.2
	var tween := tree.create_tween()
	tween.set_parallel(true)
	
	# Calculate direction towards attacker
	var bounce_dir: Vector3
	if source_position != Vector3.ZERO:
		# Direction from victim to attacker
		var to_attacker = (source_position - position).normalized()
		# Perpendicular vector (sideways) - cross product with UP
		var sideways = to_attacker.cross(Vector3.UP).normalized()
		
		# Randomly pick left or right side
		var side_mult = 1.0 if randf() > 0.5 else -1.0
		# 1.5x travel distance (approx 3.0 units total displacement)
		bounce_dir = (sideways * side_mult + to_attacker * 0.2).normalized() * 3.0
	else:
		# Fallback: random
		bounce_dir = Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	
	tween.tween_property(label, "global_position:x", position.x + bounce_dir.x, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "global_position:z", position.z + bounce_dir.z, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Vertical "Drop and Bounce"
	var ground_y = position.y - 1.6
	var peak_y = position.y + 0.8 # Slightly higher pop
	
	var y_tween := tree.create_tween()
	y_tween.tween_property(label, "global_position:y", peak_y, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	y_tween.tween_property(label, "global_position:y", ground_y, 0.75).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Fade out after a delay
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(duration - 0.3)

	# Cleanup
	tween.finished.connect(label.queue_free)
