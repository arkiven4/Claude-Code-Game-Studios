## TestLevel
## Attach this to a Node3D in a new scene to test the procedural generator.
## See docs/how-to/procedural-level-setup.md for full setup guide.
extends Node3D

@export var chapter_config: ChapterConfig
@export var use_seed: int = -1

func _ready() -> void:
	print("[TestLevel] _ready called")
	print("[TestLevel] chapter_config = ", chapter_config)

	if chapter_config == null:
		push_error("[TestLevel] chapter_config is null — drag chapter_01_config.tres onto the Inspector field")
		return

	var gen := ProceduralLevelGenerator.new()
	gen.config = chapter_config
	gen.seamless_mode = false
	add_child(gen)

	var level: Node3D = gen.generate(use_seed)
	if level == null:
		push_error("[TestLevel] generate() returned null")
		return

	add_child(level)
	print("[TestLevel] done — %d rooms generated" % level.get_child_count())
