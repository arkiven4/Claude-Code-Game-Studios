# test_status_effects.gd
# Tests: StatusEffectsSystem apply/tick/expire
# Covers sprint tasks S1-12, S2-11

extends GutTest

var _system: StatusEffectsSystem
var _mock_state: Node

func before_each() -> void:
	_system = StatusEffectsSystem.new()
	add_child(_system)

	# Minimal mock state (PartyMemberState is too heavy; just test system isolation)
	_mock_state = Node.new()
	add_child(_mock_state)

func after_each() -> void:
	_system.queue_free()
	_mock_state.queue_free()

func test_apply_effect_adds_to_active_list() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_id = "test_effect"
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 5.0
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "test_source", 1)
	assert_eq(_system.active_effects.size(), 1, "Effect added to active list")

func test_effect_expires_after_duration() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_id = "expiry_test"
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 0.1
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "test_source", 1)
	assert_eq(_system.active_effects.size(), 1, "Effect present before expiry")

	# Simulate enough time passing
	_system._process(0.2)
	assert_eq(_system.active_effects.size(), 0, "Effect expired after duration")

func test_effect_stacks_up_to_max() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_id = "stack_test"
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 10.0
	effect_def.max_stacks = 3
	effect_def.stacking_rule = StatusEffect.StackingRule.ADDITIVE_STACK

	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)  # 4th — should not exceed max

	assert_eq(_system.active_effects.size(), 1, "Same effect merges into one entry")
	assert_eq(_system.active_effects[0].current_stacks, 3, "Stacks capped at max_stacks=3")

func test_clear_removes_all() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_id = "clear_test"
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 10.0
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "s", 1)
	_system.clear_all_effects()
	assert_eq(_system.active_effects.size(), 0, "All effects cleared")
