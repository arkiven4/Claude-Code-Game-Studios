# character_switch_controller.gd
class_name CharacterSwitchController
extends Node

## Manages input authority transfer between party members.

signal character_switched(previous: PartyMemberState, current: PartyMemberState)

@export var input_manager: InputManager
@export var party_member_paths: Array[NodePath] = []
@export var switch_window_duration: float = 0.3   # Animation delay before switch completes
@export var switch_cooldown_duration: float = 1.0 # Total cooldown between switches (per design)

var party_members: Array[PartyMemberState] = []
var current_member_index: int = 0
var current_character: PartyMemberState
var _switch_cooldown_remaining: float = 0.0

func _ready() -> void:
	for path in party_member_paths:
		var node = get_node_or_null(path)
		if node is PartyMemberState:
			party_members.append(node)
			
	if input_manager:
		input_manager.switch_next_pressed.connect(switch_to_next)
		input_manager.switch_prev_pressed.connect(switch_to_prev)
		
	_initialize_starting_character()

func _initialize_starting_character() -> void:
	if party_members.is_empty(): return
	
	current_character = null
	for i in range(party_members.size()):
		if party_members[i] and party_members[i].is_alive:
			current_character = party_members[i]
			current_member_index = i
			break
			
	if not current_character:
		push_error("[CharacterSwitchController] No alive party members found!")
		return
		
	# Set starting character
	current_character.set_player_controlled(true)
	
	for i in range(party_members.size()):
		if party_members[i] and party_members[i] != current_character:
			party_members[i].set_player_controlled(false)
			# Agent logic will be added here later

func _process(delta: float) -> void:
	if _switch_cooldown_remaining > 0.0:
		_switch_cooldown_remaining -= delta

func switch_to_next() -> void:
	if party_members.is_empty(): return
	var next := (current_member_index + 1) % party_members.size()
	switch_to_index(next)

func switch_to_prev() -> void:
	if party_members.is_empty(): return
	var prev := (current_member_index - 1 + party_members.size()) % party_members.size()
	switch_to_index(prev)

func switch_to_index(index: int) -> void:
	if index < 0 or index >= party_members.size(): return
	var target := party_members[index]
	if target and target != current_character and target.is_alive:
		current_member_index = index
		switch_to(target)

func switch_to(target: PartyMemberState) -> void:
	if _switch_cooldown_remaining > 0.0: return
	if not target or target == current_character or not target.is_alive: return
	if current_character and current_character.is_casting: return
	
	var previous := current_character
	previous.set_player_controlled(false)

	_switch_cooldown_remaining = switch_cooldown_duration

	_complete_switch(previous, target)

func _complete_switch(previous: PartyMemberState, target: PartyMemberState) -> void:
	await get_tree().create_timer(switch_window_duration).timeout
	
	if not target or not target.is_alive:
		# Target died during switch window
		return
		
	target.set_player_controlled(true)
	current_character = target
	character_switched.emit(previous, current_character)
	print("[CharacterSwitch] Switched to %s" % current_character.name)
