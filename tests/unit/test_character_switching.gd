# test_character_switching.gd
# Tests: CharacterSwitchController — no buff/cooldown leaks on swap
# Covers sprint tasks S2-12, S2-13 (ADR-0002)

extends GutTest

var _controller: CharacterSwitchController
var _member_a: PartyMemberState
var _member_b: PartyMemberState

func before_each() -> void:
	_controller = CharacterSwitchController.new()
	add_child(_controller)

	# Create minimal PartyMemberState nodes (no character_data — just test control state)
	_member_a = _make_member("Evelyn")
	_member_b = _make_member("Evan")

	_controller.party_members = [_member_a, _member_b]

func _make_member(member_name: String) -> PartyMemberState:
	var m := PartyMemberState.new()
	m.name = member_name
	m.is_alive = true
	m.current_hp = 100
	m.max_hp = 100
	add_child(m)
	return m

func after_each() -> void:
	_controller.queue_free()
	_member_a.queue_free()
	_member_b.queue_free()

func test_first_member_is_player_controlled_after_init() -> void:
	_controller._initialize_starting_character()
	assert_true(_member_a.is_player_controlled, "First member starts player-controlled")
	assert_false(_member_b.is_player_controlled, "Second member starts AI-controlled")

func test_switch_transfers_control() -> void:
	_controller.switch_window_duration = 0.05
	_controller._initialize_starting_character()
	
	_controller.switch_to(_member_b)

	assert_false(_member_a.is_player_controlled, "Previous member loses control immediately")
	
	await wait_for_signal(_controller.character_switched, 1.0)

	assert_true(_member_b.is_player_controlled, "Target member gains control after switch window")
	assert_eq(_controller.current_character, _member_b, "Current character updated")

func test_dead_member_cannot_be_switched_to() -> void:
	_controller._initialize_starting_character()
	_member_b.is_alive = false
	_controller.current_character = _member_a
	_controller.current_member_index = 0

	_controller.switch_to(_member_b)

	# Should remain on member_a
	assert_eq(_controller.current_character, _member_a, "Cannot switch to dead member")

func test_switch_cooldown_blocks_rapid_switch() -> void:
	_controller._initialize_starting_character()
	_controller.current_character = _member_a
	_controller._switch_cooldown_remaining = 5.0  # Simulate active cooldown

	_controller.switch_to(_member_b)

	# Should remain on member_a — cooldown blocked it
	assert_eq(_controller.current_character, _member_a, "Switch blocked by cooldown")
