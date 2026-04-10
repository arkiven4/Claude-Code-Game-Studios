# test_combat_to_loot.gd
# Integration Test: Combat Victory -> Loot Drop -> Pickup Spawning
# Covers the full core loop from Sprint 03.

extends GutTest

var _manager: CombatEncounterManager
var _dropper: LootDropper
var _enemy: EnemyAIController
var _loot_table: LootTable
var _item: ItemEquipment
var _pickup_scene: PackedScene 
var _mock_scene: Node3D

func before_each() -> void:
	# Mock current_scene for LootDropper correctly
	_mock_scene = Node3D.new()
	_mock_scene.name = "MockScene"
	get_tree().root.add_child(_mock_scene)
	get_tree().current_scene = _mock_scene
	print("[Test] current_scene set to: ", get_tree().current_scene.name)
		
	# Setup Manager
	_manager = CombatEncounterManager.new()
	add_child(_manager)
	
	# Setup Data
	var enemy_data = EnemyData.new()
	
	# Setup Enemy
	_enemy = EnemyAIController.new()
	_enemy.enemy_data = enemy_data
	_enemy.is_alive = true
	add_child(_enemy)
	_manager.enemies = [_enemy]
	
	# Setup Loot
	_item = ItemEquipment.new()
	_loot_table = LootTable.new()
	_loot_table.entries = [_item]
	_loot_table.entry_weights = [1.0]
	
	# Setup Dropper
	_dropper = LootDropper.new()
	add_child(_dropper)
	_dropper.loot_table = _loot_table
	_dropper.enemy_data = enemy_data
	
	# Mock Pickup Scene behavior
	_pickup_scene = load("res://tests/integration/mock_pickup.tscn")
	_dropper.pickup_scene = _pickup_scene

	# Connect Enemy Death to Loot Drop
	_enemy.died.connect(func(): 
		print("[Test] Enemy died, triggering drop_loot at ", _enemy.global_position)
		_dropper.drop_loot(_enemy.global_position)
	)

func after_each() -> void:
	if is_instance_valid(_manager): _manager.free()
	if is_instance_valid(_dropper): _dropper.free()
	if is_instance_valid(_enemy): _enemy.free()
	
	if is_instance_valid(_mock_scene):
		if get_tree().current_scene == _mock_scene:
			get_tree().current_scene = null
		_mock_scene.free()

func test_combat_victory_triggers_loot_drop() -> void:
	# 1. Start Combat
	_manager.start_combat()
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.ACTIVE, "Combat should be ACTIVE")
	
	# 2. Kill Enemy
	watch_signals(_manager)
	_enemy.is_alive = false
	_enemy.died.emit()
	
	# 3. Verify Combat Ended
	assert_eq(_manager.enemies_remaining, 0, "Enemies remaining should be 0")
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.COMPLETE, "Combat should be COMPLETE")
	assert_signal_emitted(_manager, "combat_ended", "combat_ended signal should be emitted")
	
	# 4. Verify Loot Spawned
	# Check the mock_scene's children for a LootPickup
	var pickup: LootPickup = null
	for child in _mock_scene.get_children():
		if child is LootPickup:
			pickup = child
			break
			
	assert_not_null(pickup, "A loot pickup should have spawned")
	
	if pickup:
		assert_eq(pickup.item, _item, "Pickup should contain the correct item")
