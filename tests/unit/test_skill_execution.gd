# test_skill_execution.gd
# Tests: SkillExecutionSystem logic
# Covers sprint tasks S3-04, S3-05

extends GutTest

var _skill_system: SkillExecutionSystem
var _state: PartyMemberState
var _char_data: CharacterData
var _skill: SkillData
var _tier_1: SkillTierConfig

func before_each() -> void:
	_skill_system = SkillExecutionSystem.new()
	add_child(_skill_system)

	_tier_1 = SkillTierConfig.new()
	_tier_1.effect_value = 1.5
	_tier_1.target_count = 1

	_skill = SkillData.new()
	_skill.skill_id = "test_skill"
	_skill.mp_cost = 20
	_skill.base_cooldown = 10.0
	_skill.max_charges = 1
	_skill.tiers = [_tier_1]
	_skill.skill_type = SkillData.SkillType.DAMAGE
	_skill.target_type = SkillData.TargetType.SINGLE_ENEMY

	_char_data = CharacterData.new()
	_char_data.skill_slots = [_skill, null, null, null]

	_state = PartyMemberState.new()
	_state.name = "TestState"
	_state.character_data = _char_data
	add_child(_state)

	# Ensure _state is properly initialized with defaults
	_state.is_alive = true
	_state.max_hp = 100
	_state.current_hp = 100
	_state.max_mp = 100
	_state.current_mp = 100

	_skill_system.state = _state

func after_each() -> void:
	if is_instance_valid(_skill_system):
		_skill_system.queue_free()
	if is_instance_valid(_state):
		_state.queue_free()

func test_try_activate_skill_validation_dead() -> void:
	_state.is_alive = false
	watch_signals(_skill_system)
	var success := _skill_system.try_activate_skill(0, 1)
	assert_false(success, "Cannot use skill while dead")
	assert_signal_emitted_with_parameters(_skill_system, "skill_activated", [0, false])

func test_try_activate_skill_invalid_slot() -> void:
	var success := _skill_system.try_activate_skill(5, 1)
	assert_false(success, "Invalid slot index")

func test_try_activate_skill_insufficient_mp() -> void:
	_state.current_mp = 5
	watch_signals(_skill_system)
	var success := _skill_system.try_activate_skill(0, 1)
	assert_false(success, "Insufficient MP")
	assert_signal_emitted_with_parameters(_skill_system, "skill_activated", [0, false])

func test_try_activate_skill_on_cooldown() -> void:
	_state.skill_cooldowns[0] = 5.0
	var success := _skill_system.try_activate_skill(0, 1)
	assert_false(success, "Skill is on cooldown")

func test_try_activate_skill_success_consumes_resources() -> void:
	var initial_mp := _state.current_mp
	watch_signals(_skill_system)
	
	# Note: _execute_enemy_skill will try to access get_tree() if not careful.
	# But we can test the pre-execution phase (Phase 2).
	
	var success := _skill_system.try_activate_skill(0, 1)
	assert_true(success, "Skill should activate")
	assert_eq(_state.current_mp, initial_mp - _skill.mp_cost, "MP consumed")
	assert_eq(_state.skill_charges[0], 0, "Charge consumed")
	assert_eq(_state.skill_cooldowns[0], _skill.base_cooldown, "Cooldown started")
	assert_signal_emitted_with_parameters(_skill_system, "skill_activated", [0, true])
	assert_signal_emitted(_skill_system, "skill_cast")

func test_tier_selection() -> void:
	var tier_2 := SkillTierConfig.new()
	tier_2.effect_value = 2.5
	_skill.tiers.append(tier_2)
	
	# We can't easily verify the internal effect_value without deeper mocking 
	# of _execute_enemy_skill, but we can verify it doesn't crash and returns true.
	var success := _skill_system.try_activate_skill(0, 2)
	assert_true(success, "Activates with tier 2")

func test_cast_time_logic() -> void:
	_skill.cast_time = 1.0
	_state.current_mp = 100
	
	watch_signals(_skill_system)
	var success := _skill_system.try_activate_skill(0, 1)
	
	assert_true(success, "Skill activation should start (casting)")
	assert_true(_state.is_casting, "State should be 'is_casting'")
	assert_false(_state.can_use_skill(0), "Cannot use another skill while casting")
	
	# MP and charges should NOT be consumed yet (consumed in Phase 2: _execute_skill_immediately)
	assert_eq(_state.current_mp, 100, "MP not yet consumed")
	assert_eq(_state.skill_charges[0], 1, "Charge not yet consumed")
	
	# Progress should be 0 at start
	assert_eq(_skill_system.get_cast_progress(), 0.0, "Progress should be 0.0")
	
	# Advance time
	_skill_system._process(0.5)
	assert_true(_state.is_casting, "Should still be casting after 0.5s")
	assert_almost_eq(_skill_system.get_cast_progress(), 0.5, 0.01, "Progress should be ~0.5")
	
	# Complete casting
	_skill_system._process(0.6)
	assert_false(_state.is_casting, "Should have finished casting")
	assert_eq(_state.current_mp, 100 - _skill.mp_cost, "MP should be consumed after cast")
	assert_eq(_state.skill_charges[0], 0, "Charge should be consumed after cast")
	assert_signal_emitted(_skill_system, "skill_cast")
