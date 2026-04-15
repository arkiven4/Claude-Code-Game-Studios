class_name ItemInventory
extends Resource

signal item_added(item: Resource)
signal item_removed(item: Resource)

var items: Array[ItemEquipment] = []
var consumables: Array[ItemConsumable] = []

func add_item(item: Resource) -> void:
	if item is ItemEquipment:
		items.append(item)
		item_added.emit(item)
	elif item is ItemConsumable:
		consumables.append(item)
		item_added.emit(item)

func remove_item(item: Resource) -> bool:
	if item is ItemEquipment:
		var idx := items.find(item)
		if idx != -1:
			items.remove_at(idx)
			item_removed.emit(item)
			return true
	elif item is ItemConsumable:
		var idx := consumables.find(item)
		if idx != -1:
			consumables.remove_at(idx)
			item_removed.emit(item)
			return true
	return false

func get_items() -> Array[ItemEquipment]:
	return items

func get_consumables() -> Array[ItemConsumable]:
	return consumables

func transfer_to(item: Resource, other_inventory: ItemInventory) -> bool:
	if not item or not other_inventory:
		return false
	
	if remove_item(item):
		other_inventory.add_item(item)
		return true
	return false

func count() -> int:
	return items.size()
