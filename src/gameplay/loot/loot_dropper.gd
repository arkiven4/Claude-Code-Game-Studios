# loot_dropper.gd
class_name LootDropper
extends Node

@export var enemy_data: EnemyData
@export var loot_table: LootTable
@export var pickup_scene: PackedScene

func drop_loot(pos: Vector3) -> void:
	if not loot_table or not pickup_scene:
		return
		
	var item := loot_table.roll()
	if not item:
		return
		
	var pickup := pickup_scene.instantiate() as LootPickup
	if pickup:
		pickup.item = item
		get_tree().current_scene.add_child(pickup)
		pickup.global_position = pos
