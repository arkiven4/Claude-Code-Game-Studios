# vectorized_training.gd
# Root script for VectorizedTraining.tscn.
# Spawns N isolated arena groups in a single Godot process, then adds one shared
# godot_rl Sync node so Python sees N * 6 agents (evan, evelyn, team, enemy × 3).
#
# Run:
#   python3.10 prototypes/rl-training/train_vectorized.py
#   godot --headless res://prototypes/rl-training/VectorizedTraining.tscn -- --n_arenas=8 --speedup=10
extends Node3D

## TrainingArena.tscn is reused as the per-arena template.
## The embedded Sync and CanvasLayer are stripped before each instance enters the tree.
@export var arena_scene: PackedScene = preload("res://prototypes/rl-training/TrainingArena.tscn")

## Default arena count — overridden by --n_arenas= user arg.
@export var n_arenas: int = 4

## Distance between arena centres. 100 u keeps physics/visuals fully separate.
@export var grid_spacing: float = 100.0

func _ready() -> void:
	_parse_user_args()
	print("[VectorizedTraining] Spawning %d arenas (spacing=%.0f u)..." % [n_arenas, grid_spacing])
	_spawn_arenas()

	# No awaits — add_child() during _ready() runs child _ready() synchronously,
	# so all AIController3D nodes register to "AGENT" group before we return.
	# Sync must be added HERE (before _ready() returns) so its internal
	# `await get_tree().root.ready` resolves when our _ready() returns.
	# Adding sync AFTER _ready() returns means root.ready has already fired → permanent hang.
	_add_sync_node()

func _parse_user_args() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--n_arenas="):
			n_arenas = arg.split("=")[1].to_int()

func _spawn_arenas() -> void:
	if not arena_scene:
		push_error("[VectorizedTraining] arena_scene is not set!")
		return

	var cols: int = int(ceil(sqrt(n_arenas)))
	for i: int in range(n_arenas):
		var arena: Node3D = arena_scene.instantiate() as Node3D
		arena.name = "Arena_%d" % i

		# Strip embedded Sync and CanvasLayer BEFORE add_child so they never
		# enter the scene tree.  Multiple Sync nodes break godot_rl; N HUDs waste CPU.
		for strip_name: String in ["Sync", "CanvasLayer"]:
			var node: Node = arena.get_node_or_null(strip_name)
			if node:
				node.get_parent().remove_child(node)
				node.free()

		# Grid layout — each arena is isolated at its own position.
		var col: int = i % cols
		var row: int = i / cols
		arena.position = Vector3(col * grid_spacing, 0.0, row * grid_spacing)

		add_child(arena)

	print("[VectorizedTraining] %d arenas ready." % n_arenas)

func _add_sync_node() -> void:
	# Read --speedup from user args (default 10)
	var speedup: float = 10.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--speedup="):
			speedup = arg.split("=")[1].to_float()

	var sync_script = load("res://addons/godot_rl_agents/sync.gd")
	if not sync_script:
		push_error("[VectorizedTraining] sync.gd not found — enable the godot_rl_agents addon.")
		return

	var sync_node := Node.new()
	sync_node.set_script(sync_script)
	sync_node.name = "Sync"
	sync_node.set("control_mode", 1)  ## 1 = TRAINING
	sync_node.set("speed_up", speedup)
	add_child(sync_node)
	# Godot is the CLIENT — it connects to Python's server socket.
	# Python must already be running and listening before this point.
	print("[VectorizedTraining] Sync active (speedup=%.1f). Connecting to Python server on port 11008..." % speedup)
