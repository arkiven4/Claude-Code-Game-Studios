# test_combat_to_loot.gd
# Integration Test: Combat Victory -> Loot Drop -> Pickup Spawning
# Covers the full core loop from Sprint 03.

extends GutTest

var _manager: CombatEncounterManager
var _dropper: LootDropper
var _enemy: EnemyAIController
var _loot_table: LootTable
var _item: ItemEquipment
var _pickup_scene: Resource 
var _mock_scene: Node3D

func before_each() -> void:
	# Mock current_scene for LootDropper correctly
	# It must be a child of root to be set as current_scene
	_mock_scene = Node3D.new()
	get_tree().root.add_child(_mock_scene)
	get_tree().current_scene = _mock_scene
		
	# Setup Manager
	_manager = CombatEncounterManager.new()
	add_child(_manager)
	
	# Setup Enemy
	var enemy_data = EnemyData.new()
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
	
	# Mock Pickup Scene behavior
	_pickup_scene = load("res://tests/integration/mock_pickup_scene.gd").new()
	_dropper.pickup_scene = _pickup_scene as PackedScene 

	# Connect Enemy Death to Loot Drop
	_enemy.died.connect(func(): _dropper.drop_loot(_enemy.global_position))

func after_each() -> void:
	if is_instance_valid(_manager): _manager.free()
	if is_instance_valid(_dropper): _dropper.free()
	if is_instance_valid(_enemy): _enemy.free()
	
	# Clean up mock scene and its children (pickups)
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
	# We check the mock_scene's children
	var pickups = _mock_scene.get_children().filter(func(n): return n.is_in_group("mock_pickups"))
	assert_gt(pickups.size(), 0, "A loot pickup should have spawned")
	
	if pickups.size() > 0:
		var pickup = pickups[0]
		assert_eq(pickup.get("item"), _item, "Pickup should contain the correct item")
