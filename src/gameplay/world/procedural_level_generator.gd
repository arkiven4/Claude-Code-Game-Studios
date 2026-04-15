## ProceduralLevelGenerator
## Assembles a branching level from a ChapterConfig.
## Usage: call generate(seed) → returns a Node3D containing all room instances.
##
## ROOM MODE (seamless_mode = false) — dungeons & labyrinths:
##   Rooms are hidden/shown on transition. Player teleports between rooms.
##   Default spacing: 30 m, branches spread 25 m apart.
##
## SEAMLESS MODE (seamless_mode = true) — surface zones:
##   All zones visible simultaneously, placed edge-to-edge.
##   Player walks freely. ZoneTracker handles zone detection.
##   Default zone_size: 120 m, branches spread zone_size apart.
##
## Layout (top-down XZ view):
##
##         START (x=0)
##        /       \
##     [B0]      [B1]      ← branch zones/rooms spread on X
##     [B0]      [B1]
##        \       /
##        JUNCTION (x=0)
##             |
##           BOSS (x=0)
##
## Implements: design/gdd/procedural-level-system.md
class_name ProceduralLevelGenerator
extends Node

@export var config: ChapterConfig

@export_group("Mode")
## When true, generates seamless surface zones (no hide/show, edge-to-edge placement).
## When false, generates dungeon/labyrinth rooms (hide/show + teleport on door).
@export var seamless_mode: bool = false

@export_group("Room Mode Settings")
## Distance (Z) between room centres in room mode.
@export var room_spacing_z: float = 30.0
## Horizontal (X) gap between branch lanes in room mode.
@export var branch_spread_x: float = 25.0

@export_group("Seamless Mode Settings")
## Side length of each square surface zone (metres).
@export var zone_size: float = 120.0
## Extra horizontal margin between adjacent branch lanes (metres).
@export var branch_lane_margin: float = 10.0

## Emitted after generate() completes.
signal generation_complete(world_root: Node3D)

var _graph: LevelGraph
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Generates a level and returns its Node3D root.
## Pass seed >= 0 for a reproducible layout; -1 = random.
func generate(seed: int = -1) -> Node3D:
	assert(config != null, "ProceduralLevelGenerator: config must be set.")

	if seed >= 0:
		_rng.seed = seed
	else:
		_rng.randomize()

	_graph = LevelGraph.new()
	_build_graph()
	_assign_positions()

	var world_root := Node3D.new()
	world_root.name = "GeneratedLevel_%s" % config.chapter_name
	_instantiate_rooms(world_root)

	generation_complete.emit(world_root)
	return world_root

## Returns the current graph (call after generate()).
func get_graph() -> LevelGraph:
	return _graph

# ---------------------------------------------------------------------------
# Graph construction
# ---------------------------------------------------------------------------

func _build_graph() -> void:
	# --- Start room ---
	var start: LevelGraph.RoomNode = _graph.add_node(
		RoomChunk.RoomType.START, config.start_room
	)
	_graph.start_node = start

	# --- Branch rooms ---
	var branch_tails: Array = []  # Array[LevelGraph.RoomNode]
	for b: int in config.branch_count:
		var depth: int = _rng.randi_range(
			config.rooms_per_branch_min, config.rooms_per_branch_max
		)
		var prev: LevelGraph.RoomNode = start
		for r: int in depth:
			var rtype: RoomChunk.RoomType = _pick_room_type(r, depth)
			var scene: PackedScene = _pick_scene_for_type(rtype)
			var room: LevelGraph.RoomNode = _graph.add_node(rtype, scene)
			room.branch_id = b
			room.branch_order = r
			_graph.connect_nodes(prev, room)
			prev = room
		branch_tails.append(prev)

	# --- Junction room ---
	var junction_scene: PackedScene = config.junction_room
	if junction_scene == null:
		junction_scene = _any_combat_scene()
	var junction: LevelGraph.RoomNode = _graph.add_node(
		RoomChunk.RoomType.JUNCTION, junction_scene
	)
	for tail: LevelGraph.RoomNode in branch_tails:
		_graph.connect_nodes(tail, junction)

	# --- Boss room ---
	var boss: LevelGraph.RoomNode = _graph.add_node(
		RoomChunk.RoomType.BOSS, config.boss_room
	)
	_graph.boss_node = boss
	_graph.connect_nodes(junction, boss)

# ---------------------------------------------------------------------------
# Room type / scene selection
# ---------------------------------------------------------------------------

func _pick_room_type(order: int, total: int) -> RoomChunk.RoomType:
	# Last slot → rest room (if pool exists)
	if order == total - 1 and not config.rest_rooms.is_empty():
		return RoomChunk.RoomType.REST
	# Alternate combat / corridor
	return RoomChunk.RoomType.COMBAT if order % 2 == 0 else RoomChunk.RoomType.CORRIDOR

func _pick_scene_for_type(rtype: RoomChunk.RoomType) -> PackedScene:
	match rtype:
		RoomChunk.RoomType.REST:
			return _pick_random(config.rest_rooms)
		RoomChunk.RoomType.CORRIDOR:
			if not config.corridor_rooms.is_empty():
				return _pick_random(config.corridor_rooms)
			return _any_combat_scene()
		_:
			return _any_combat_scene()

func _pick_random(pool: Array) -> PackedScene:
	if pool.is_empty():
		return null
	return pool[_rng.randi() % pool.size()] as PackedScene

func _any_combat_scene() -> PackedScene:
	return _pick_random(config.combat_rooms)

# ---------------------------------------------------------------------------
# World-space layout
# ---------------------------------------------------------------------------

func _assign_positions() -> void:
	_graph.start_node.world_position = Vector3.ZERO

	var spacing_z: float = zone_size if seamless_mode else room_spacing_z
	var spread_x: float = (zone_size + branch_lane_margin) if seamless_mode else branch_spread_x

	# Evenly space branches on X, centered around 0
	var total_width: float = (config.branch_count - 1) * spread_x
	var max_branch_z: float = 0.0

	for node: LevelGraph.RoomNode in _graph.nodes:
		if node.branch_id < 0:
			continue
		var x: float = -total_width * 0.5 + node.branch_id * spread_x
		var z: float = spacing_z * (node.branch_order + 1)
		node.world_position = Vector3(x, 0.0, z)
		max_branch_z = maxf(max_branch_z, z)

	var junction_z: float = max_branch_z + spacing_z
	var boss_z: float = junction_z + spacing_z

	for node: LevelGraph.RoomNode in _graph.nodes:
		match node.room_type:
			RoomChunk.RoomType.JUNCTION:
				node.world_position = Vector3(0.0, 0.0, junction_z)
			RoomChunk.RoomType.BOSS:
				node.world_position = Vector3(0.0, 0.0, boss_z)

# ---------------------------------------------------------------------------
# Instantiation & wiring
# ---------------------------------------------------------------------------

func _instantiate_rooms(world_root: Node3D) -> void:
	for node: LevelGraph.RoomNode in _graph.nodes:
		if node.scene == null:
			push_warning(
				"ProceduralLevelGenerator: node %d (%s) has no scene — skipped."
				% [node.id, RoomChunk.RoomType.keys()[node.room_type]]
			)
			continue

		var instance: Node3D = node.scene.instantiate()
		instance.position = node.world_position
		instance.name = "Room%d_%s" % [node.id, RoomChunk.RoomType.keys()[node.room_type]]
		# Hide visually only — keep process_mode normal so Area3D registers with physics
		instance.visible = false
		world_root.add_child(instance)

		# Use get_script() check — more reliable than `is` for custom class_name scripts
		var chunk: RoomChunk = instance as RoomChunk
		if chunk != null:
			node.instance = chunk
		else:
			push_warning("ProceduralLevelGenerator: node %d scene root is not a RoomChunk (got %s). Forcing show." % [node.id, instance.get_class()])
			# Not a RoomChunk — show it anyway so the room is still visible
			node.raw_instance = instance

	if seamless_mode:
		# Seamless: all zones visible, attach a ZoneTracker for boundary detection
		var tracker := ZoneTracker.new()
		tracker.name = "ZoneTracker"
		world_root.add_child(tracker)
	else:
		# Room mode: wire exit teleports and hide all but start
		for node: LevelGraph.RoomNode in _graph.nodes:
			if not node.next_nodes.is_empty():
				_wire_exits(node)
		_set_active_room(_graph.start_node)

func _get_node3d(node: LevelGraph.RoomNode) -> Node3D:
	if node.instance != null:
		return node.instance
	return node.raw_instance

func _wire_exits(node: LevelGraph.RoomNode) -> void:
	var source: Node3D = _get_node3d(node)
	if source == null:
		push_warning("[PLG] _wire_exits: no node3d for node %d" % node.id)
		return
	print("[PLG] wiring exits for: %s  has_signal=%s" % [source.name, source.has_signal("player_exited")])
	if not source.has_signal("player_exited"):
		push_warning("[PLG] room '%s' has no player_exited signal — exits won't fire." % source.name)
		return
	source.connect("player_exited", func(exit_index: int) -> void:
		print("[PLG] player_exited fired! room=%s exit=%d" % [source.name, exit_index])
		var target_index: int = clampi(exit_index, 0, node.next_nodes.size() - 1)
		var target: LevelGraph.RoomNode = node.next_nodes[target_index]
		_transition(node, target)
	)

func _transition(from: LevelGraph.RoomNode, to: LevelGraph.RoomNode) -> void:
	var from_node: Node3D = _get_node3d(from)
	if from_node:
		from_node.visible = false

	_set_active_room(to)

	# Teleport player to entrance marker (search by name if typed cast failed)
	var to_node: Node3D = _get_node3d(to)
	if to_node:
		var marker: Node3D
		if to.instance and to.instance.entrance_marker:
			marker = to.instance.entrance_marker
		else:
			marker = to_node.find_child("EntranceMarker", true, false) as Node3D
		if marker:
			var players: Array[Node] = get_tree().get_nodes_in_group("player")
			for player: Node in players:
				if player is Node3D:
					(player as Node3D).global_position = marker.global_position

func _set_active_room(node: LevelGraph.RoomNode) -> void:
	var target: Node3D = _get_node3d(node)
	if target == null:
		push_warning("ProceduralLevelGenerator: _set_active_room — no instance for node %d" % node.id)
		return
	print("[PLG] showing room: ", target.name, " at ", target.position)
	target.visible = true
