# party_agent.gd
class_name PartyAgent
extends Node

## Base class for party AI implementations (BT or RL).

var is_active: bool = false
var context: Dictionary = {}

func on_player_take_control() -> void:
	is_active = false
	print("[PartyAgent] %s: Player took control" % get_parent().name)

func on_ai_resume_control(new_context: Dictionary) -> void:
	is_active = true
	context = new_context
	print("[PartyAgent] %s: AI resumed control" % get_parent().name)

# To be overridden by subclasses
func _process(_delta: float) -> void:
	pass
