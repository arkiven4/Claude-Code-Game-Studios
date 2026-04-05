# loot_table.gd
class_name LootTable
extends Resource

@export var entries: Array[Resource] = []
@export var entry_weights: Array[float] = []

func roll() -> ItemEquipment:
	if entries.is_empty() or entries.size() != entry_weights.size():
		return null
		
	var total_weight: float = 0.0
	for w in entry_weights:
		total_weight += w
		
	var roll_val := randf() * total_weight
	var current_weight: float = 0.0
	
	for i in range(entries.size()):
		current_weight += entry_weights[i]
		if roll_val <= current_weight:
			return entries[i] as ItemEquipment
			
	return null
