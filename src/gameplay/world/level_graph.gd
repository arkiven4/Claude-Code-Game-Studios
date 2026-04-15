## LevelGraph
## Runtime directed graph produced by ProceduralLevelGenerator.
## Nodes = rooms. Edges = directional connections (from → to).
class_name LevelGraph
extends RefCounted

## A single room node in the graph.
class RoomNode:
	var id: int
	var room_type: RoomChunk.RoomType
	var scene: PackedScene
	## -1 = shared room (start / junction / boss). >= 0 = branch index.
	var branch_id: int = -1
	## Position within its branch (0-based).
	var branch_order: int = 0
	## World-space position assigned during layout.
	var world_position: Vector3 = Vector3.ZERO
	## Outgoing edges. Type: Array[RoomNode]
	var next_nodes: Array = []
	## Set after instantiation if the scene root is a RoomChunk.
	var instance: RoomChunk = null
	## Fallback: set when the scene root is NOT a RoomChunk (plain Node3D).
	var raw_instance: Node3D = null

	func _init(p_id: int, p_type: RoomChunk.RoomType, p_scene: PackedScene) -> void:
		id = p_id
		room_type = p_type
		scene = p_scene

## All nodes in generation order.
var nodes: Array = []  # Array[RoomNode]
var start_node: RoomNode = null
var boss_node: RoomNode = null

var _next_id: int = 0

## Creates and registers a new RoomNode.
func add_node(room_type: RoomChunk.RoomType, scene: PackedScene) -> RoomNode:
	var node := RoomNode.new(_next_id, room_type, scene)
	_next_id += 1
	nodes.append(node)
	return node

## Adds a directed edge from → to (no duplicates).
func connect_nodes(from: RoomNode, to: RoomNode) -> void:
	if not from.next_nodes.has(to):
		from.next_nodes.append(to)
