# arena_wiring.gd
class_name ArenaWiring
extends Node

## Wires runtime signals between arena systems.
## Runs after all sibling nodes are ready via call_deferred.

@export var encounter_manager: CombatEncounterManager
@export var switch_controller: CharacterSwitchController
@export var camera_controller: CameraController
@export var party_member_paths: Array[NodePath] = []
@export var enemy_paths: Array[NodePath] = []
@export var combat_hud: CombatHUD

var party_members: Array[PartyMemberState] = []
var enemies: Array[EnemyAIController] = []

func _ready() -> void:
	for path in party_member_paths:
		var node = get_node_or_null(path)
		if node is PartyMemberState:
			party_members.append(node)
	for path in enemy_paths:
		var node = get_node_or_null(path)
		if node is EnemyAIController:
			enemies.append(node)
			
	call_deferred("_wire_signals")

func _wire_signals() -> void:
	# --- CombatEncounterManager → CombatHUD ---
	if encounter_manager and combat_hud:
		encounter_manager.combat_started.connect(combat_hud.show_hud)
		encounter_manager.combat_ended.connect(combat_hud.hide_hud)
		encounter_manager.game_over.connect(combat_hud.hide_hud)

	# --- CharacterSwitchController → CombatHUD ---
	if switch_controller and combat_hud:
		switch_controller.character_switched.connect(_on_character_switched)

	# --- CharacterSwitchController → CameraController ---
	if switch_controller and camera_controller:
		switch_controller.character_switched.connect(_on_switch_update_camera)

	# --- PartyMemberState → CombatHUD (initial active = index 0) ---
	if not party_members.is_empty() and combat_hud:
		_connect_active_member(party_members[0])
		if party_members.size() > 1:
			_connect_inactive_member(party_members[1])

	# --- EnemyAIController.died → LootDropper ---
	for enemy in enemies:
		if enemy:
			var dropper: LootDropper = enemy.get_node_or_null("LootDropper")
			if dropper:
				enemy.died.connect(func(): dropper.drop_loot(enemy.global_position))

	# --- Start combat immediately (TestArena is a test scene) ---
	if encounter_manager:
		call_deferred("_start_combat_deferred")

func _start_combat_deferred() -> void:
	if encounter_manager:
		encounter_manager.start_combat()

func _on_character_switched(previous: PartyMemberState, current: PartyMemberState) -> void:
	# Disconnect previous character's signals from active HUD slots
	if previous and combat_hud:
		if previous.hp_changed.is_connected(combat_hud.update_active_health):
			previous.hp_changed.disconnect(combat_hud.update_active_health)

	# Connect new active character
	if current and combat_hud:
		_connect_active_member(current)

	# Show switch cooldown
	if combat_hud and switch_controller:
		combat_hud.show_switch_cooldown(switch_controller.switch_window_duration)

func _on_switch_update_camera(_previous: PartyMemberState, current: PartyMemberState) -> void:
	if camera_controller and current:
		var char_node := current.get_parent() as Node3D
		if char_node:
			camera_controller.follow_target = char_node

func _connect_active_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_active_health):
		member.hp_changed.connect(combat_hud.update_active_health)
	# Immediately refresh bars
	combat_hud.update_active_health(member.current_hp, member.max_hp)
	combat_hud.update_active_mp(member.current_mp, member.max_mp)

func _connect_inactive_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_inactive_health):
		member.hp_changed.connect(combat_hud.update_inactive_health)
	combat_hud.update_inactive_health(member.current_hp, member.max_hp)
