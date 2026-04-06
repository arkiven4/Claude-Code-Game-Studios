# hurtbox_component.gd
class_name HurtboxComponent
extends Area3D

## Receives hits from hitboxes and notifies the health system.

signal took_hit(damage_data: Dictionary)

@export var parent_node: Node

func _ready() -> void:
	if not parent_node:
		var p := get_parent()
		if p and not p.has_method("take_damage"):
			var state := p.get_node_or_null("PartyMemberState")
			parent_node = state if state else p
		else:
			parent_node = p
	monitorable = true
	monitoring = false
	
	# Set collision layer based on parent type
	# Layer 2 = Party Hurtboxes, Layer 8 = Enemy Hurtboxes
	if parent_node is EnemyAIController or (parent_node and parent_node.is_in_group("Enemies")):
		collision_layer = 8  # Enemy hurtbox layer
	else:
		collision_layer = 2  # Party hurtbox layer

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
