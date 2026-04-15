# checkpoint.gd
class_name Checkpoint
extends Area3D

## Triggers an auto-save when the player enters the area.

signal activated

@export var once_only: bool = true
@export var vfx_on_activate: PackedScene

var _activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _activated and once_only: return
	
	if body.is_in_group("player"):
		_activate_checkpoint()

func _activate_checkpoint() -> void:
	_activated = true
	activated.emit()
	print("[Checkpoint] Activated! Triggering auto-save...")
	
	var save_manager := get_tree().get_first_node_in_group("SaveManager") as SaveManager
	if save_manager:
		save_manager.save_game(true)
	
	if vfx_on_activate:
		var vfx = vfx_on_activate.instantiate()
		add_child(vfx)
