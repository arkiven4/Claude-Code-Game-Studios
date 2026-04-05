# item_equipment.gd
class_name ItemEquipment
extends Resource

## ScriptableObject for equipment items with stats, rarity, and class restrictions.

enum EquipSlot { WEAPON, ARMOR, HELMET, ACCESSORY, RELIC }
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

@export_group("Identity")
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Classification")
@export var slot: EquipSlot = EquipSlot.WEAPON
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var allowed_classes: Array[CharacterData.CharacterClass] = []

@export_group("Stats")
@export var base_atk: float = 0.0
@export var base_def: float = 0.0
@export var base_spd: float = 0.0
@export var base_max_hp: float = 0.0
@export var base_max_mp: float = 0.0
@export var base_crit: float = 0.0

@export_group("Requirements & Value")
@export var level_requirement: int = 1
@export var sell_price: int = 100

@export_group("Assets")
@export var icon: Texture2D

## Calculates the final stats of the item after applying the rarity multiplier.
func get_final_stats(rarity_table: ItemRarityTable) -> Dictionary:
	var multiplier := rarity_table.get_multiplier(rarity) if rarity_table else 1.0
	
	return {
		"atk": base_atk * multiplier,
		"def": base_def * multiplier,
		"spd": base_spd * multiplier,
		"max_hp": base_max_hp * multiplier,
		"max_mp": base_max_mp * multiplier,
		"crit": base_crit * multiplier
	}
