class_name DialogueNode
extends Resource

@export var node_id: String = ""
@export var speaker_id: String = ""
@export var text: String = ""
@export var next_node_id: String = ""         # empty = end of dialogue
@export var choices: Array[Dictionary] = []  # [{text, next_node_id, flag_condition}]
@export var flags_to_set: Dictionary = {}    # {flag_id: bool} — set on reaching this node
@export var audio_clip: AudioStream = null
