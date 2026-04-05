# hurtbox_component.gd
class_name HurtboxComponent
extends Area3D

## Receives hits from hitboxes and notifies the health system.

signal took_hit(damage_data: Dictionary)

@export var parent_node: Node

func _ready() -> void:
	if not parent_node:
		parent_node = get_parent()
	monitorable = true
	monitoring = false

func take_hit(damage_data: Dictionary) -> void:
	# For now, just emit the signal. 
	# Later, this will call HealthDamageSystem.apply_damage_to_target()
	took_hit.emit(damage_data)
	if parent_node and parent_node.has_method("take_damage"):
		parent_node.take_damage(damage_data)

func is_alive() -> bool:
	if parent_node and parent_node.has_method("is_alive"):
		return parent_node.is_alive()
	return true
