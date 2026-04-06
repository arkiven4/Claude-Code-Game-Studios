# test_combat_encounter.gd
# Tests: CombatEncounterManager orchestrator
# Covers sprint tasks S3-02, S3-03
#
# NOTE: EnemyAIController extends CharacterBody3D which cannot be reliably
# instantiated in headless unit tests. We test the manager's state machine
# using direct state manipulation where possible.

extends GutTest

var _manager: CombatEncounterManager
var _member: PartyMemberState
var _char_data: CharacterData

func before_each() -> void:
	_manager = CombatEncounterManager.new()
	add_child(_manager)

	_char_data = CharacterData.new()
	_char_data.base_max_hp = 100

	_member = PartyMemberState.new()
	_member.name = "TestMember"
	_member.character_data = _char_data
	add_child(_member)

	_manager.party_members = [_member]
	# Enemies array starts empty; we manipulate enemies_remaining directly
	_manager.enemies = []

func after_each() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()
	if is_instance_valid(_member):
		_member.queue_free()

func test_start_combat_initializes_state() -> void:
	# With no enemies, start_combat should still transition to ACTIVE
	watch_signals(_manager)
	_manager.enemies_remaining = 0  # No enemies in this test
	_manager.start_combat()

	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.ACTIVE, "Combat should be ACTIVE")
	assert_signal_emitted(_manager, "combat_started")

func test_victory_when_all_enemies_die() -> void:
	_manager.enemies_remaining = 1
	_manager.state = CombatEncounterManager.CombatEncounterState.ACTIVE
	watch_signals(_manager)

	# Simulate the last enemy dying
	_manager._on_enemy_died(null)

	assert_eq(_manager.enemies_remaining, 0, "No enemies left")
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.COMPLETE, "Should be COMPLETE")
	assert_signal_emitted(_manager, "combat_ended")

func test_game_over_when_party_wiped() -> void:
	_manager.start_combat()
	watch_signals(_manager)

	# Simulate party wipe
	_member.is_alive = false
	_manager._check_party_wipe()

	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.GAME_OVER, "Should be GAME_OVER")
	assert_signal_emitted(_manager, "game_over")

func test_reset_encounter() -> void:
	_manager.enemies_remaining = 1
	_manager.state = CombatEncounterManager.CombatEncounterState.ACTIVE
	_member.current_hp = 10

	watch_signals(_manager)
	_manager.start_training_episode()

	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.ACTIVE, "Re-activated")
	assert_signal_emitted(_manager, "encounter_reset")
