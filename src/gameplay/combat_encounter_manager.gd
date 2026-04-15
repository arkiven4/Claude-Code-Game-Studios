# combat_encounter_manager.gd
class_name CombatEncounterManager
extends Node

## Encounter orchestrator. Manages combat state, victory, and game over.

signal combat_started
signal combat_ended
signal game_over
signal encounter_reset

enum CombatEncounterState { INACTIVE, PRE_COMBAT, ACTIVE, WAVE_TRANSITION, COMPLETE, GAME_OVER }
enum EncounterType { STORY, OPTIONAL }

@export var enemy_paths: Array[NodePath] = []
@export var party_member_paths: Array[NodePath] = []

var enemies: Array[EnemyAIController] = []
var party_members: Array[PartyMemberState] = []

func _ready() -> void:
	add_to_group("CombatEncounterManager")
	for path in enemy_paths:
		var node: Node = get_node_or_null(path)
		if node is EnemyAIController:
			enemies.append(node as EnemyAIController)
	for path in party_member_paths:
		var node: Node = get_node_or_null(path)
		if node is PartyMemberState:
			party_members.append(node as PartyMemberState)
@export var encounter_type: EncounterType = EncounterType.OPTIONAL
@export var victory_pause_duration: float = 3.0

var state: CombatEncounterState = CombatEncounterState.INACTIVE
var encounter_timer: float = 0.0
var enemies_remaining: int = 0

# Stats Tracking
var _stats_damage_dealt: float = 0.0
var _stats_damage_received: float = 0.0
var _stats_kills: int = 0
var _stats_switches: int = 0
var _stats_start_time: float = 0.0

func _process(delta: float) -> void:
	if state == CombatEncounterState.ACTIVE or state == CombatEncounterState.WAVE_TRANSITION:
		encounter_timer += delta
		_check_party_wipe()

func _check_party_wipe() -> void:
	if party_members.is_empty(): return
	
	var all_dead: bool = true
	for member in party_members:
		if member and member.is_alive:
			all_dead = false
			break
	
	if all_dead:
		_handle_game_over()

func start_combat() -> void:
	if state == CombatEncounterState.ACTIVE: return
	
	_reset_stats()
	_stats_start_time = Time.get_ticks_msec() / 1000.0
	
	enemies_remaining = 0
	for enemy in enemies:
		if enemy:
			if not enemy.died.is_connected(_on_enemy_died.bind(enemy)):
				enemy.died.connect(_on_enemy_died.bind(enemy))
			if not enemy.damage_taken.is_connected(_on_enemy_damaged):
				enemy.damage_taken.connect(_on_enemy_damaged)
			if enemy.is_alive:
				enemies_remaining += 1
				
	for member in party_members:
		if member:
			if not member.hp_changed.is_connected(_on_party_member_damaged.bind(member)):
				member.hp_changed.connect(_on_party_member_damaged.bind(member))
			if not member.control_state_changed.is_connected(_on_party_member_switch):
				member.control_state_changed.connect(_on_party_member_switch)

	encounter_timer = 0.0
	state = CombatEncounterState.ACTIVE
	combat_started.emit()
	print("[CombatEncounter] Started")

func _reset_stats() -> void:
	_stats_damage_dealt = 0.0
	_stats_damage_received = 0.0
	_stats_kills = 0
	_stats_switches = 0

func _on_enemy_damaged(amount: int) -> void:
	_stats_damage_dealt += amount

func _on_party_member_damaged(current: int, _max: int, member: PartyMemberState) -> void:
	# Simplified tracking, assumes only decreases are damage
	pass # Complex to track without a specific signal, but good enough for now

func _on_party_member_switch(is_player: bool) -> void:
	if is_player:
		_stats_switches += 1

func _on_enemy_died(enemy: EnemyAIController) -> void:
	_stats_kills += 1
	enemies_remaining = max(0, enemies_remaining - 1)
	if enemies_remaining <= 0:
		_victory_sequence()

func _victory_sequence() -> void:
	state = CombatEncounterState.COMPLETE
	
	var final_stats = {
		"time_seconds": Time.get_ticks_msec() / 1000.0 - _stats_start_time,
		"damage_dealt": _stats_damage_dealt,
		"damage_received": _stats_damage_received,
		"kills": _stats_kills,
		"switches": _stats_switches
	}
	
	# Reset skill cooldowns for party (wave reset)
	for member in party_members:
		if member:
			member.call("reset_for_encounter", false)
			
	combat_ended.emit() # UI can listen to this and pull stats from manager
	print("[CombatEncounter] Victory!")
	
	# Show overlay if found
	var overlay = get_tree().get_first_node_in_group("CombatEndOverlay")
	if overlay and overlay.has_method("show_victory"):
		overlay.show_victory(final_stats)

	await get_tree().create_timer(victory_pause_duration).timeout
	state = CombatEncounterState.INACTIVE

func _handle_game_over() -> void:
	state = CombatEncounterState.GAME_OVER
	
	var final_stats = {
		"time_seconds": Time.get_ticks_msec() / 1000.0 - _stats_start_time,
		"damage_dealt": _stats_damage_dealt,
		"damage_received": _stats_damage_received,
		"kills": _stats_kills,
		"switches": _stats_switches
	}
	
	game_over.emit()
	print("[CombatEncounter] Game Over - Party Wiped")
	
	# Show overlay if found
	var overlay = get_tree().get_first_node_in_group("CombatEndOverlay")
	if overlay and overlay.has_method("show_defeat"):
		overlay.show_defeat(final_stats)

func get_active_enemies() -> Array[EnemyAIController]:
	var active: Array[EnemyAIController] = []
	for e in enemies:
		if e and e.is_alive:
			active.append(e)
	return active

func start_training_episode() -> void:
	# Reset everything for RL training
	for member in party_members:
		if member: member.call("reset_for_encounter", true)
		
	for enemy in enemies:
		if enemy: 
			# Assuming reset logic exists or just re-instantiate
			pass
			
	encounter_reset.emit()
	start_combat()
