# test_combat_encounter.gd
# Tests: CombatEncounterManager orchestrator
# Covers sprint tasks S3-02, S3-03

extends GutTest

var _manager: CombatEncounterManager
var _member: PartyMemberState
var _enemy: EnemyAIController
var _char_data: CharacterData
var _enemy_data: EnemyData

func before_each() -> void:
	_manager = CombatEncounterManager.new()
	add_child(_manager)
	
	_char_data = CharacterData.new()
	_char_data.base_max_hp = 100
	
	_member = PartyMemberState.new()
	_member.character_data = _char_data
	add_child(_member)
	
	_enemy_data = EnemyData.new()
	_enemy_data.base_max_hp = 50
	
	_enemy = EnemyAIController.new()
	_enemy.enemy_data = _enemy_data
	add_child(_enemy)
	
	_manager.party_members = [_member]
	_manager.enemies = [_enemy]

func test_start_combat_initializes_state() -> void:
	watch_signals(_manager)
	_manager.start_combat()
	
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.ACTIVE, "Combat should be ACTIVE")
	assert_eq(_manager.enemies_remaining, 1, "Should track 1 enemy")
	assert_signal_emitted(_manager, "combat_started")

func test_victory_when_all_enemies_die() -> void:
	_manager.start_combat()
	watch_signals(_manager)
	
	_enemy._die()
	
	assert_eq(_manager.enemies_remaining, 0, "No enemies left")
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.COMPLETE, "Should be COMPLETE")
	assert_signal_emitted(_manager, "combat_ended")

func test_game_over_when_party_wiped() -> void:
	_manager.start_combat()
	watch_signals(_manager)
	
	# Simulate party wipe
	_member.is_alive = false
	# We need to call _check_party_wipe manually or via _process
	_manager._check_party_wipe()
	
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.GAME_OVER, "Should be GAME_OVER")
	assert_signal_emitted(_manager, "game_over")

func test_reset_encounter() -> void:
	_manager.start_combat()
	_enemy._die()
	_member.current_hp = 10
	
	watch_signals(_manager)
	_manager.start_training_episode()
	
	assert_eq(_manager.state, CombatEncounterManager.CombatEncounterState.ACTIVE, "Re-activated")
	assert_eq(_member.current_hp, _member.max_hp, "HP fully reset for training")
	assert_signal_emitted(_manager, "encounter_reset")
