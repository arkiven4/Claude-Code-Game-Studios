# vectorized_training.gd
extends Node3D

@export var arena_scene: PackedScene = preload("res://prototypes/rl-training/TrainingArenaIsolated.tscn")
@export var n_arenas: int = 4
@export var grid_spacing: float = 100.0

func _ready() -> void:
	# Parse command line args for N
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--n_arenas="):
			n_arenas = arg.split("=")[1].to_int()
	
	print("[VectorizedTraining] Spawning %d arenas..." % n_arenas)
	_spawn_arenas()
	
	# Small delay to ensure all agents have entered the tree
	await get_tree().process_frame
	_add_sync_node()

func _spawn_arenas() -> void:
	var side = ceil(sqrt(n_arenas))
	for i in range(n_arenas):
		var arena = arena_scene.instantiate()
		
		var x = (i % int(side)) * grid_spacing
		var z = (i / int(side)) * grid_spacing
		arena.transform.origin = Vector3(x, 0, z)
		
		add_child(arena)
		arena.name = "Arena_%d" % i
	print("[VectorizedTraining] Arenas spawned.")

func _add_sync_node() -> void:
	print("[VectorizedTraining] Adding Sync node...")
	var sync_script = load("res://addons/godot_rl_agents/sync.gd")
	var sync_node = Node.new()
	sync_node.set_script(sync_script)
	sync_node.name = "Sync"
	# Set properties directly on the object
	sync_node.set("control_mode", 1) # TRAINING
	sync_node.set("speed_up", 10.0)
	add_child(sync_node)
	print("[VectorizedTraining] Sync node active. Waiting for Python connection...")
