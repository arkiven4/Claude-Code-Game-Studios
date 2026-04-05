class_name PartyInventory
extends Resource

signal item_added(item: ItemEquipment)
signal item_removed(item: ItemEquipment)

var items: Array[ItemEquipment] = []

func add_item(item: ItemEquipment) -> void:
	if not item:
		return
	items.append(item)
	item_added.emit(item)

func remove_item(item: ItemEquipment) -> bool:
	var idx := items.find(item)
	if idx == -1:
		return false
	items.remove_at(idx)
	item_removed.emit(item)
	return true

func get_items() -> Array[ItemEquipment]:
	return items

func count() -> int:
	return items.size()
