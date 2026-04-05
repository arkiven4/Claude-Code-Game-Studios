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
	for path in enemy_paths:
		var node = get_node_or_null(path)
		if node is EnemyAIController:
			enemies.append(node)
	for path in party_member_paths:
		var node = get_node_or_null(path)
		if node is PartyMemberState:
			party_members.append(node)
@export var encounter_type: EncounterType = EncounterType.OPTIONAL
@export var victory_pause_duration: float = 3.0

var state: CombatEncounterState = CombatEncounterState.INACTIVE
var encounter_timer: float = 0.0
var enemies_remaining: int = 0

func _process(delta: float) -> void:
	if state == CombatEncounterState.ACTIVE or state == CombatEncounterState.WAVE_TRANSITION:
		encounter_timer += delta
		_check_party_wipe()

func start_combat() -> void:
	if state == CombatEncounterState.ACTIVE: return
	
	enemies_remaining = 0
	for enemy in enemies:
		if enemy:
			if not enemy.died.is_connected(_on_enemy_died.bind(enemy)):
				enemy.died.connect(_on_enemy_died.bind(enemy))
			if enemy.is_alive:
				enemies_remaining += 1
				
	encounter_timer = 0.0
	state = CombatEncounterState.ACTIVE
	combat_started.emit()
	print("[CombatEncounter] Started")

func _on_enemy_died(enemy: EnemyAIController) -> void:
	enemies_remaining = max(0, enemies_remaining - 1)
	if enemies_remaining <= 0:
		_victory_sequence()

func _victory_sequence() -> void:
	state = CombatEncounterState.COMPLETE
	
	# Reset skill cooldowns for party (wave reset)
	for member in party_members:
		if member:
			member.call("reset_for_encounter", false)
			
	combat_ended.emit()
	print("[CombatEncounter] Victory!")
	
	await get_tree().create_timer(victory_pause_duration).timeout
	state = CombatEncounterState.INACTIVE

func _check_party_wipe() -> void:
	if state != CombatEncounterState.ACTIVE: return
	
	var all_dead := true
	for member in party_members:
		if member and member.is_alive:
			all_dead = false
			break
			
	if all_dead:
		_handle_game_over()

func _handle_game_over() -> void:
	state = CombatEncounterState.GAME_OVER
	game_over.emit()
	print("[CombatEncounter] Game Over - Party Wiped")

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
