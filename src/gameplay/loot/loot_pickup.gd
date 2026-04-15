class_name LootPickup
extends Area3D

signal collected(item: ItemEquipment)

@export var item: ItemEquipment

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
	if state and state.inventory:
		state.inventory.add_item(item)
		collected.emit(item)
		queue_free()
	elif body.is_in_group("Player") or body.is_in_group("PartyMembers"):
		# Fallback for simple bodies without state components
		collected.emit(item)
		queue_free()
