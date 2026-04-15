# level_segment.gd
class_name LevelSegment
extends Node3D

## A modular piece of a level.
## Contains entry/exit points for stitching and markers for spawns.

@export var entry_point: Marker3D # Where the player enters this segment from the previous one
@export var exit_points: Array[Marker3D] = [] # Where this segment can lead to next

@onready var spawners: Array[Node] = []

func _ready() -> void:
	# Collect all spawn markers in children
	for child in get_children():
		if child is Marker3D and child.name.begins_with("Spawn"):
			spawners.append(child)

## Returns a random exit point for the generator to connect to.
func get_random_exit() -> Marker3D:
	if exit_points.is_empty(): return null
	return exit_points[randi() % exit_points.size()]

## Aligns this segment's entry_point to another segment's exit_point.
func align_to(other_exit: Marker3D) -> void:
	if not entry_point or not other_exit: return
	
	# Rotate this segment to match the exit direction
	# Assuming exits and entries face 'forward' out of the segment
	var target_rotation = other_exit.global_rotation
	global_rotation = target_rotation
	
	# Position so entry_point matches other_exit exactly
	var offset = global_position - entry_point.global_position
	global_position = other_exit.global_position + offset
