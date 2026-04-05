class_name DialogueManager
extends Node

signal dialogue_started(graph: DialogueGraph)
signal node_advanced(node: DialogueNode)
signal choice_presented(choices: Array)
signal dialogue_ended
signal flag_set(flag_id: String, value: bool)

@export var chapter_state: NodePath

var _current_graph: DialogueGraph = null
var _current_node: DialogueNode = null
var _chapter_state: ChapterStateManager

func _ready() -> void:
	if chapter_state:
		_chapter_state = get_node(chapter_state)

func start_dialogue(graph: DialogueGraph) -> void:
	_current_graph = graph
	_current_node = graph.get_node_by_id(graph.start_node_id)
	dialogue_started.emit(graph)
	_present_node(_current_node)

func advance() -> void:
	if not _current_node:
		return
	if not _current_node.choices.is_empty():
		return  # Wait for player to pick choice
	var next_id := _current_node.next_node_id
	if next_id == "":
		_end_dialogue()
		return
	_current_node = _current_graph.get_node_by_id(next_id)
	_present_node(_current_node)

func select_choice(choice_index: int) -> void:
	if not _current_node or choice_index >= _current_node.choices.size():
		return
	var choice: Dictionary = _current_node.choices[choice_index]
	var next_id: String = choice.get("next_node_id", "")
	if next_id == "":
		_end_dialogue()
		return
	_current_node = _current_graph.get_node_by_id(next_id)
	_present_node(_current_node)

func _present_node(node: DialogueNode) -> void:
	if not node:
		_end_dialogue()
		return
	for flag_id in node.flags_to_set:
		if _chapter_state:
			_chapter_state.set_flag(flag_id, node.flags_to_set[flag_id])
		flag_set.emit(flag_id, node.flags_to_set[flag_id])
	node_advanced.emit(node)
	if not node.choices.is_empty():
		choice_presented.emit(node.choices)

func _end_dialogue() -> void:
	_current_graph = null
	_current_node = null
	dialogue_ended.emit()
