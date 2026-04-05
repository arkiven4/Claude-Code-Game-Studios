# item_rarity.gd
class_name ItemRarityTable
extends Resource

## Defines the stat multipliers per rarity tier.

@export var common_multiplier: float = 1.0
@export var uncommon_multiplier: float = 1.15
@export var rare_multiplier: float = 1.35
@export var epic_multiplier: float = 1.6
@export var legendary_multiplier: float = 2.0

func get_multiplier(rarity: int) -> float:
	match rarity:
		0: return common_multiplier # Common
		1: return uncommon_multiplier # Uncommon
		2: return rare_multiplier # Rare
		3: return epic_multiplier # Epic
		4: return legendary_multiplier # Legendary
		_: return 1.0
