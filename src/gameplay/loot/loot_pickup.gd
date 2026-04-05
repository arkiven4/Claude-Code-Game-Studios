class_name LootPickup
extends Area3D

signal collected(item: ItemEquipment)

@export var item: ItemEquipment

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") or body.is_in_group("PartyMembers"):
		collected.emit(item)
		queue_free()
