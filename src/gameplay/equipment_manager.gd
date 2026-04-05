# equipment_manager.gd
class_name EquipmentManager
extends Node

## Manages the equipment slots for a single character.

signal equipment_changed

@export var state: PartyMemberState
@export var rarity_table: ItemRarityTable

var _equipped_items: Dictionary = {} # EquipSlot -> ItemEquipment

func _ready() -> void:
	if not state:
		state = get_parent() as PartyMemberState

func equip(item: ItemEquipment) -> bool:
	if not item: return false
	
	# Validate class
	if not item.allowed_classes.is_empty() and not state.character_data.character_class in item.allowed_classes:
		print("[EquipmentManager] Class mismatch for %s" % item.display_name)
		return false
		
	# Unequip current
	unequip(item.slot)
	
	# Equip new
	_equipped_items[item.slot] = item
	equipment_changed.emit()
	return true

func unequip(slot: int) -> void:
	if _equipped_items.erase(slot):
		equipment_changed.emit()

func get_equipped_item(slot: int) -> ItemEquipment:
	return _equipped_items.get(slot)

func get_equipped(slot: int) -> ItemEquipment:
	return get_equipped_item(slot)

func get_total_modifiers() -> Dictionary:
	var total := {
		"atk": 0.0,
		"def": 0.0,
		"spd": 0.0,
		"max_hp": 0.0,
		"max_mp": 0.0,
		"crit": 0.0
	}
	
	for item in _equipped_items.values():
		var item_stats: Dictionary = item.get_final_stats(rarity_table)
		for stat in total.keys():
			total[stat] += item_stats.get(stat, 0.0)
			
	return total
