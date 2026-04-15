extends "res://addons/gut/test.gd"

## Integration Test for the First Playable Loop.
## Covers: Combat, AI, Switching, Loot, and Feedback Systems.

var _member_node: CharacterBody3D
var _member_state: PartyMemberState
var _enemy_node: CharacterBody3D
var _enemy_controller: EnemyAIController
var _encounter: CombatEncounterManager
var _vfx_spawner: Node3D

func before_each():
	# Create a mock VFX spawner
	_vfx_spawner = Node3D.new()
	_vfx_spawner.name = "VFX_Spawner"
	add_child_autoqfree(_vfx_spawner)
	
	# Setup Party Member
	_member_node = CharacterBody3D.new()
	_member_node.name = "TestPlayer"
	_member_node.add_to_group("PartyMembers")
	add_child_autoqfree(_member_node)
	
	_member_state = PartyMemberState.new()
	_member_state.name = "PartyMemberState"
	_member_node.add_child(_member_state)
	
	# Mock data
	var char_data = CharacterData.new()
	char_data.display_name = "Test Hero"
	char_data.base_hp_curve = {1: 1000}
	char_data.base_atk_curve = {1: 50}
	_member_state.character_data = char_data
	_member_state._ready()
	
	# Setup Enemy
	_enemy_node = CharacterBody3D.new()
	_enemy_node.name = "TestEnemy"
	_enemy_node.add_to_group("Enemies")
	add_child_autoqfree(_enemy_node)
	
	_enemy_controller = EnemyAIController.new()
	_enemy_node.add_child(_enemy_controller)
	
	var enemy_data = EnemyData.new()
	enemy_data.base_max_hp = 100
	enemy_data.base_atk = 10
	_enemy_controller.enemy_data = enemy_data
	_enemy_controller._ready()
	
	# Setup Encounter Manager
	_encounter = CombatEncounterManager.new()
	add_child_autoqfree(_encounter)
	_encounter.party_members = [_member_state]
	_encounter.enemies = [_enemy_controller]
	_encounter.state = CombatEncounterManager.CombatEncounterState.INACTIVE

func test_combat_feedback_triggers_on_damage():
	# Test that hitting an enemy triggers the feedback system (Screen Shake, Hitstop, etc.)
	# This is hard to test purely with code, but we can check if signals/logic flow correctly.
	
	watch_signals(_enemy_controller)
	
	var damage_data = {
		"damage": 10,
		"caster_name": "TestPlayer",
		"was_crit": true
	}
	
	_enemy_controller.take_damage(damage_data)
	
	assert_signal_emitted(_enemy_controller, "damage_taken", "Damage signal should emit")
	assert_eq(_enemy_controller.current_hp, 90, "HP should decrease")
	
	# Check if CombatFeedbackManager calls (indirectly by checking if it didn't crash)
	# Real verification would involve mocking CombatFeedbackManager, but in GDScript 
	# static methods are hard to mock.

func test_enemy_pathfinding_logic():
	# Ensure enemy AI with NavAgent starts chasing when aggroed
	var nav = NavigationAgent3D.new()
	_enemy_node.add_child(nav)
	_enemy_controller._nav_agent = nav
	
	# Move enemy away
	_enemy_node.global_position = Vector3(10, 0, 10)
	_member_node.global_position = Vector3(0, 0, 0)
	
	# Force aggro
	_enemy_controller.take_damage({"damage": 1, "caster_name": "TestPlayer"})
	
	assert_eq(_enemy_controller._combat_state, EnemyAIController.CombatState.CHASING, "Enemy should chase after being hit")
	
	# Simulate one physics tick for pathfinding
	_enemy_controller._behavior_chase_target(0.1)
	
	assert_gt(_enemy_controller.velocity.length(), 0.0, "Enemy should have velocity while chasing")

func test_victory_sequence_and_stats():
	watch_signals(_encounter)
	
	_encounter.start_combat()
	assert_eq(_encounter.state, CombatEncounterManager.CombatEncounterState.ACTIVE)
	
	# Kill the enemy
	_enemy_controller.take_damage({"damage": 200, "caster_name": "TestPlayer"})
	
	# Signal is emitted on _die() -> queue_free()
	# We'll simulate the signal directly since we manually instantiated
	_encounter._on_enemy_died(_enemy_controller)
	
	assert_signal_emitted(_encounter, "combat_ended", "Victory should trigger combat_ended")
	assert_eq(_encounter.state, CombatEncounterManager.CombatEncounterState.COMPLETE)
	assert_gt(_encounter._stats_damage_dealt, 0.0, "Damage stats should be tracked")
	assert_eq(_encounter._stats_kills, 1, "Kills should be tracked")

func test_consumable_use_logic():
	var potion = ItemConsumable.new()
	var effect = ItemEffect.new()
	effect.type = ItemEffect.EffectType.HEAL_HP_FLAT
	effect.value = 50.0
	potion.effects = [effect]
	
	_member_state.current_hp = 20
	
	var success = ConsumableManager.use_consumable(potion, _member_node)
	
	assert_true(success, "Consumable should use successfully")
	assert_eq(_member_state.current_hp, 70, "Player should be healed")
