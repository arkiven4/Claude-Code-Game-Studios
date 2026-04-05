# arena_wiring.gd
class_name ArenaWiring
extends Node

## Wires runtime signals between arena systems.
## Runs after all sibling nodes are ready via call_deferred.

@export var encounter_manager: CombatEncounterManager
@export var switch_controller: CharacterSwitchController
@export var camera_controller: CameraController
@export var input_manager: InputManager
@export var player_movement_controller: PlayerMovementController
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
		# Set initial camera target
		if switch_controller.current_character:
			_on_switch_update_camera(null, switch_controller.current_character)

	# --- InputManager → CameraController ---
	if input_manager and camera_controller:
		input_manager.camera_orbit.connect(camera_controller.on_camera_orbit)

	# --- InputManager → SkillExecutionSystem (active character) ---
	if input_manager:
		input_manager.skill_pressed.connect(_on_skill_pressed)
		input_manager.basic_attack_pressed.connect(_on_basic_attack_pressed)
		input_manager.special_attack_pressed.connect(_on_special_attack_pressed)
		input_manager.dodge_pressed.connect(_on_dodge_pressed)

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
				enemy.died.connect(_on_enemy_died.bind(enemy, dropper))

	# --- Start combat immediately (TestArena is a test scene) ---
	if encounter_manager:
		call_deferred("_start_combat_deferred")

func _start_combat_deferred() -> void:
	if encounter_manager:
		encounter_manager.start_combat()

func _on_enemy_died(enemy: EnemyAIController, dropper: LootDropper) -> void:
	dropper.drop_loot(enemy.global_position)

func _on_character_switched(previous: PartyMemberState, current: PartyMemberState) -> void:
	if not combat_hud: return

	# 1. Handle the member that was active (previous) -> now inactive
	if previous:
		# Disconnect active-specific signals
		if previous.hp_changed.is_connected(combat_hud.update_active_health):
			previous.hp_changed.disconnect(combat_hud.update_active_health)
		if previous.mp_changed.is_connected(combat_hud.update_active_mp):
			previous.mp_changed.disconnect(combat_hud.update_active_mp)
		# Wire as inactive
		_connect_inactive_member(previous)

	# 2. Handle the member that was inactive (current) -> now active
	if current:
		# Disconnect inactive-specific signals
		if current.hp_changed.is_connected(combat_hud.update_inactive_health):
			current.hp_changed.disconnect(combat_hud.update_inactive_health)
		# Wire as active
		_connect_active_member(current)

	# Show switch cooldown
	if switch_controller:
		combat_hud.show_switch_cooldown(switch_controller.switch_cooldown_duration)

func _on_skill_pressed(slot_index: int) -> void:
	if not switch_controller or not switch_controller.current_character: return
	var char_node := switch_controller.current_character.get_parent()
	var skill_system: SkillExecutionSystem = char_node.get_node_or_null("SkillExecutionSystem") as SkillExecutionSystem
	if skill_system:
		skill_system.try_activate_skill(slot_index, 1)

func _on_basic_attack_pressed() -> void:
	if not switch_controller or not switch_controller.current_character: return
	var char_node := switch_controller.current_character.get_parent()
	var skill_system: SkillExecutionSystem = char_node.get_node_or_null("SkillExecutionSystem") as SkillExecutionSystem
	if skill_system:
		skill_system.try_activate_attack(false, 1)

func _on_special_attack_pressed() -> void:
	if not switch_controller or not switch_controller.current_character: return
	var char_node := switch_controller.current_character.get_parent()
	var skill_system: SkillExecutionSystem = char_node.get_node_or_null("SkillExecutionSystem") as SkillExecutionSystem
	if skill_system:
		skill_system.try_activate_attack(true, 1)

func _on_dodge_pressed() -> void:
	if player_movement_controller:
		player_movement_controller.dodge()

func _on_switch_update_camera(_previous: PartyMemberState, current: PartyMemberState) -> void:
	if camera_controller and current:
		var char_node := current.get_parent() as Node3D
		if char_node:
			camera_controller.follow_target = char_node

func _connect_active_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_active_health):
		member.hp_changed.connect(combat_hud.update_active_health)
	if not member.mp_changed.is_connected(combat_hud.update_active_mp):
		member.mp_changed.connect(combat_hud.update_active_mp)
	
	# Full refresh of HUD for the new active member
	combat_hud.update_active_health(member.current_hp, member.max_hp)
	combat_hud.update_active_mp(member.current_mp, member.max_mp)
	combat_hud.set_active_character(member)

func _connect_inactive_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_inactive_health):
		member.hp_changed.connect(combat_hud.update_inactive_health)
	
	# Full refresh of HUD for the new inactive member
	combat_hud.set_inactive_character(member)
