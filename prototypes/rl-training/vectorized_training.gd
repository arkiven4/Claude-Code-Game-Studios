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

## How often (in physics frames) to refresh the stats overlay.
@export var stats_refresh_interval: int = 30


var _arena_managers: Array = []
var _stats_frame: int = 0
var _stat_labels: Dictionary = {}
var _best_arena_idx: int = 0


func _ready() -> void:
	# Cap rendering so the GPU/compositor doesn't starve at high physics speedup.
	# Without this, the window goes blank after many episodes in non-headless mode.
	Engine.max_fps = 30
	_parse_user_args()
	print("[VectorizedTraining] Spawning %d arenas (spacing=%.0f u)..." % [n_arenas, grid_spacing])
	_spawn_arenas()

	# No awaits — add_child() during _ready() runs child _ready() synchronously,
	# so all AIController3D nodes register to "AGENT" group before we return.
	# Sync must be added HERE (before _ready() returns) so its internal
	# `await get_tree().root.ready` resolves when our _ready() returns.
	# Adding sync AFTER _ready() returns means root.ready has already fired → permanent hang.
	_add_sync_node()
	_build_stats_ui()


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

	# Cache arena manager references (each arena root has rl_arena_manager.gd).
	for i: int in range(n_arenas):
		var arena: Node = get_node_or_null("Arena_%d" % i)
		if arena:
			_arena_managers.append(arena)

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


# ---------------------------------------------------------------------------
#  Stats Overlay
# ---------------------------------------------------------------------------

func _build_stats_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "StatsOverlay"
	add_child(canvas)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10.0, 10.0)
	panel.custom_minimum_size = Vector2(300.0, 0.0)
	canvas.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	# Define rows: key → initial text, optional color override
	var rows: Array[Dictionary] = [
		{"key": "title",             "text": "BEST ARENA",        "size": 15, "color": Color(1.0, 0.85, 0.3)},
		{"key": "sep0",              "text": "─────────────────────────"},
		{"key": "curriculum",        "text": "Stage : —"},
		{"key": "episodes",          "text": "Eps   : 0  |  Wins: 0 (0%)"},
		{"key": "avg_damage",        "text": "Dmg   : [░░░░░░░░░░] 0.0%"},
		{"key": "step",              "text": "Step  : 0 / 0"},
		{"key": "sep1",              "text": "─────────────────────────"},
		{"key": "evan_hp",           "text": "Evan  : [░░░░░░░░░░] 0%"},
		{"key": "evelyn_hp",         "text": "Evelyn: [░░░░░░░░░░] 0%"},
		{"key": "enemies",           "text": "Enemies: 0 / 0 alive"},
		{"key": "sep2",              "text": "─────────────────────────"},
		{"key": "evan_r",            "text": "Evan R  :  0.000"},
		{"key": "evelyn_r",          "text": "Evelyn R:  0.000"},
		{"key": "team_r",            "text": "Team R  :  0.000"},
		{"key": "enemy_r",           "text": "Enemy R :  0.000"},
		{"key": "sep3",              "text": "─────────────────────────"},
		{"key": "arenas_header",     "text": "ALL ARENAS  (★ = best)",  "color": Color(0.7, 0.7, 0.7)},
		{"key": "arenas_list",       "text": ""},
	]

	for row: Dictionary in rows:
		var lbl := Label.new()
		lbl.text = row.get("text", "")
		lbl.add_theme_font_size_override("font_size", row.get("size", 13))
		if row.has("color"):
			lbl.add_theme_color_override("font_color", row["color"])
		elif row["key"].begins_with("sep"):
			lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		_stat_labels[row["key"]] = lbl
		vbox.add_child(lbl)


func _physics_process(_delta: float) -> void:
	_stats_frame += 1
	if _stats_frame % stats_refresh_interval == 0:
		_refresh_stats()


func _refresh_stats() -> void:
	if _arena_managers.is_empty() or _stat_labels.is_empty():
		return

	# --- Find best arena: highest curriculum stage, tie-break by avg damage progress ---
	var best_mgr = null
	var best_stage: int = -1
	var best_progress: float = -1.0

	for i: int in range(_arena_managers.size()):
		var mgr = _arena_managers[i]
		if not is_instance_valid(mgr) or not mgr.has_method("get_stats"):
			continue
		var s: Dictionary = mgr.get_stats()
		var stage: int    = s.get("curriculum_stage", 0)
		var prog: float   = s.get("avg_damage_progress", 0.0)
		if stage > best_stage or (stage == best_stage and prog > best_progress):
			best_stage    = stage
			best_progress = prog
			best_mgr      = mgr
			_best_arena_idx = i

	if not best_mgr:
		return

	var d: Dictionary = best_mgr.get_stats()

	# --- Aggregate wins across ALL arenas ---
	var total_party_wins: int = 0
	var total_enemy_wins: int = 0
	var total_eps: int = 0
	for mgr in _arena_managers:
		if is_instance_valid(mgr) and mgr.has_method("get_stats"):
			var s: Dictionary = mgr.get_stats()
			total_party_wins += s.get("party_wins", 0)
			total_enemy_wins += s.get("enemy_wins", 0)
			total_eps        += s.get("total_episodes", 0)

	var party_pct: float = float(total_party_wins) / float(maxi(total_eps, 1)) * 100.0
	var enemy_pct: float = float(total_enemy_wins) / float(maxi(total_eps, 1)) * 100.0

	var evan_pct:   float = float(d["evan_hp"])   / float(maxi(d["evan_max_hp"],   1)) * 100.0
	var evelyn_pct: float = float(d["evelyn_hp"]) / float(maxi(d["evelyn_max_hp"], 1)) * 100.0

	# --- Update best-arena labels ---
	_stat_labels["title"].text      = "BEST ARENA: Arena_%d" % _best_arena_idx
	_stat_labels["curriculum"].text = "Stage : %s" % d["curriculum_label"]
	_stat_labels["episodes"].text   = "Eps   : %d  |  Party: %d (%.0f%%)  Enemy: %d (%.0f%%)" \
									  % [total_eps, total_party_wins, party_pct, total_enemy_wins, enemy_pct]
	_stat_labels["avg_damage"].text = "Dmg   : %s %.1f%%" \
									  % [_bar(d["avg_damage_progress"], 10), d["avg_damage_progress"] * 100.0]
	_stat_labels["step"].text       = "Step  : %d / %d" % [d["episode_step"], d["max_episode_steps"]]
	_stat_labels["evan_hp"].text    = "Evan  : %s %.0f%%" % [_bar(evan_pct   / 100.0, 10), evan_pct]
	_stat_labels["evelyn_hp"].text  = "Evelyn: %s %.0f%%" % [_bar(evelyn_pct / 100.0, 10), evelyn_pct]
	_stat_labels["enemies"].text    = "Enemies: %d / %d alive" % [d["enemies_alive"], d["enemies_total"]]
	_stat_labels["evan_r"].text     = "Evan R  : %+.3f" % d["evan_reward"]
	_stat_labels["evelyn_r"].text   = "Evelyn R: %+.3f" % d["evelyn_reward"]
	_stat_labels["team_r"].text     = "Team R  : %+.3f" % d["team_reward"]
	_stat_labels["enemy_r"].text    = "Enemy R : %+.3f" % d["enemy_avg_reward"]

	# --- Compact all-arenas summary ---
	var lines: PackedStringArray = PackedStringArray()
	for i: int in range(_arena_managers.size()):
		var mgr = _arena_managers[i]
		if not is_instance_valid(mgr) or not mgr.has_method("get_stats"):
			continue
		var s: Dictionary = mgr.get_stats()
		var marker: String = "★" if i == _best_arena_idx else " "
		var ep_prog: float  = float(s["episode_step"]) / float(maxi(s["max_episode_steps"], 1)) * 100.0
		lines.append("%s A%-2d  S%-2d  dmg:%.0f%%  ep:%d%%" \
					 % [marker, i, s["curriculum_stage"] + 1,
						s["avg_damage_progress"] * 100.0, ep_prog])
	_stat_labels["arenas_list"].text = "\n".join(lines)


## ASCII progress bar.  ratio is clamped 0–1.  width is number of characters.
func _bar(ratio: float, width: int) -> String:
	var filled: int = int(clampf(ratio, 0.0, 1.0) * float(width))
	var s: String = "["
	for i: int in range(width):
		s += "█" if i < filled else "░"
	return s + "]"
