class_name DialogueGraph
extends Resource

@export var graph_id: String = ""
@export var start_node_id: String = ""
@export var nodes: Array[DialogueNode] = []

var _node_map: Dictionary = {}

func _init() -> void:
	_build_map()

func get_node_by_id(id: String) -> DialogueNode:
	if _node_map.is_empty():
		_build_map()
	return _node_map.get(id, null)

func _build_map() -> void:
	_node_map.clear()
	for node in nodes:
		_node_map[node.node_id] = node
