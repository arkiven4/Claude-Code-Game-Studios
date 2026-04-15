# level_generator.gd
class_name LevelGenerator
extends Node3D

## Procedurally generates a level by stitching LevelSegments based on BiomeData.

signal generation_complete

@export var biome: BiomeData
@export var segment_count: int = 8
@export var level_seed: int = 0

var _placed_segments: Array[LevelSegment] = []

func generate() -> void:
	if not biome:
		push_error("[LevelGenerator] No biome data assigned!")
		return
		
	if level_seed == 0:
		seed(Time.get_ticks_msec())
	else:
		seed(level_seed)
		
	_clear_level()
	_generate_sequence()
	generation_complete.emit()

func _clear_level() -> void:
	for child in get_children():
		child.queue_free()
	_placed_segments.clear()

func _generate_sequence() -> void:
	# 1. Place Start Segment
	var start_scene = _pick_random(biome.start_segments)
	if not start_scene: return
	
	var current_segment = _place_segment(start_scene, Vector3.ZERO)
	
	# 2. Place Middle Segments
	for i in range(segment_count):
		var exit_marker = current_segment.get_random_exit()
		if not exit_marker: break
		
		var next_scene = _pick_random(biome.segment_pool)
		if not next_scene: break
		
		var next_segment = _place_segment(next_scene, Vector3.ZERO)
		next_segment.align_to(exit_marker)
		current_segment = next_segment
		
	# 3. Place End Segment
	var last_exit = current_segment.get_random_exit()
	if last_exit:
		var end_scene = _pick_random(biome.end_segments)
		if end_scene:
			var end_segment = _place_segment(end_scene, Vector3.ZERO)
			end_segment.align_to(last_exit)

func _place_segment(scene: PackedScene, pos: Vector3) -> LevelSegment:
	var segment = scene.instantiate() as LevelSegment
	add_child(segment)
	segment.global_position = pos
	_placed_segments.append(segment)
	return segment

func _pick_random(list: Array) -> Variant:
	if list.is_empty(): return null
	return list[randi() % list.size()]
