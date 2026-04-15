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
@export var combat_end_overlay: CombatEndOverlay
@export var inventory_ui: InventoryUI

var party_members: Array[PartyMemberState] = []
var enemies: Array[EnemyAIController] = []
var _last_highlighted: Node3D = null
var _highlight_vfx: MeshInstance3D = null

## Stats tracking for combat end screen
var _combat_start_time: float = 0.0
var _total_damage_dealt: float = 0.0
var _total_damage_received: float = 0.0
var _total_kills: int = 0
var _total_switches: int = 0

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
		encounter_manager.combat_started.connect(_on_combat_started)
		encounter_manager.combat_ended.connect(_on_combat_ended)
		encounter_manager.game_over.connect(_on_game_over)

	# --- CombatEncounterManager → CombatEndOverlay ---
	if encounter_manager and combat_end_overlay:
		encounter_manager.combat_ended.connect(_on_victory_for_overlay)
		encounter_manager.game_over.connect(_on_defeat_for_overlay)
	if combat_end_overlay:
		combat_end_overlay.restart_requested.connect(_on_restart_requested)

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

	# --- InputManager → InventoryUI ---
	if input_manager and inventory_ui:
		input_manager.inventory_pressed.connect(_on_inventory_pressed)

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

	# --- PartyMemberState damage → Floating numbers ---
	for member in party_members:
		if member:
			# Seed initial HP so damage delta tracking works from first hit
			_last_enemy_hp_for_floating[member.get_instance_id()] = member.current_hp
			member.hp_changed.connect(_on_party_member_hp_changed.bind(member))

	# --- EnemyAIController damage → Floating numbers ---
	for enemy in enemies:
		if enemy:
			enemy.damage_taken.connect(_on_enemy_damage_taken.bind(enemy))
			enemy.died.connect(_on_enemy_died_for_stats.bind(enemy))

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

func _on_inventory_pressed() -> void:
	print("[ArenaWiring] Inventory key pressed. inventory_ui: %s, switch_controller: %s" % [str(inventory_ui != null), str(switch_controller != null)])
	if not inventory_ui or not switch_controller: return
	
	if inventory_ui.visible:
		print("[ArenaWiring] Closing inventory")
		inventory_ui.close()
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		if switch_controller.current_character:
			print("[ArenaWiring] Opening inventory for: ", switch_controller.current_character.name)
			inventory_ui.open_for_character(switch_controller.current_character)
			print("[ArenaWiring] inventory_ui.visible after open: ", inventory_ui.visible)
			get_tree().paused = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			print("[ArenaWiring] Cannot open inventory: No current_character")

func _on_character_switched(previous: PartyMemberState, current: PartyMemberState) -> void:
	_total_switches += 1
	if not combat_hud: return

	# 1. Handle the member that was active (previous) -> now inactive
	if previous:
		# Disconnect active-specific signals
		if previous.hp_changed.is_connected(combat_hud.update_active_health):
			previous.hp_changed.disconnect(combat_hud.update_active_health)
		if previous.mp_changed.is_connected(combat_hud.update_active_mp):
			previous.mp_changed.disconnect(combat_hud.update_active_mp)
		if previous.shield_changed.is_connected(_on_active_shield_changed):
			previous.shield_changed.disconnect(_on_active_shield_changed)
		
		var prev_skill_system: SkillExecutionSystem = previous.get_parent().get_node_or_null("SkillExecutionSystem")
		if prev_skill_system:
			if prev_skill_system.targeting_started.is_connected(_on_targeting_started):
				prev_skill_system.targeting_started.disconnect(_on_targeting_started)
			if prev_skill_system.targeting_ended.is_connected(_on_targeting_ended):
				prev_skill_system.targeting_ended.disconnect(_on_targeting_ended)
			if prev_skill_system.hover_target_changed.is_connected(_on_hover_target_changed):
				prev_skill_system.hover_target_changed.disconnect(_on_hover_target_changed)
			# Cancel any active targeting on switch
			prev_skill_system.call("_exit_targeting_mode")

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
	if not member.shield_changed.is_connected(_on_active_shield_changed):
		member.shield_changed.connect(_on_active_shield_changed.bind(member))

	var skill_system: SkillExecutionSystem = member.get_parent().get_node_or_null("SkillExecutionSystem")
	if skill_system:
		if not skill_system.targeting_started.is_connected(_on_targeting_started):
			skill_system.targeting_started.connect(_on_targeting_started)
		if not skill_system.targeting_ended.is_connected(_on_targeting_ended):
			skill_system.targeting_ended.connect(_on_targeting_ended)
		if not skill_system.hover_target_changed.is_connected(_on_hover_target_changed):
			skill_system.hover_target_changed.connect(_on_hover_target_changed)

	# Full refresh of HUD for the new active member
	combat_hud.update_active_health(member.current_hp, member.max_hp)
	combat_hud.update_active_mp(member.current_mp, member.max_mp)
	combat_hud.update_active_shield(member.shield_value)
	combat_hud.set_active_character(member)

func _on_active_shield_changed(value: int, _member: PartyMemberState) -> void:
	if combat_hud:
		combat_hud.update_active_shield(value)

func _connect_inactive_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_inactive_health):
		member.hp_changed.connect(combat_hud.update_inactive_health)
	
	# Full refresh of HUD for the new inactive member
	combat_hud.set_inactive_character(member)

func _on_targeting_started(mode: int) -> void:
	print("[ArenaWiring] Targeting started: mode=", mode)
	if combat_hud:
		var color := Color.GREEN if mode == 1 else Color.WHITE # FRIENDLY = 1
		combat_hud.show_crosshair(color)

func _on_targeting_ended() -> void:
	if combat_hud:
		combat_hud.hide_crosshair()
	_set_highlight(null)

func _on_hover_target_changed(target: Node) -> void:
	print("[ArenaWiring] Hover target changed: ", target.name if target else "null")
	var target_char: Node3D = null
	if target is PartyMemberState:
		target_char = target.get_parent() as Node3D
	_set_highlight(target_char)

func _set_highlight(node: Node3D) -> void:
	if _last_highlighted == node: return
	
	if _highlight_vfx:
		_highlight_vfx.queue_free()
		_highlight_vfx = null
			
	_last_highlighted = node
	
	if _last_highlighted:
		print("[ArenaWiring] Spawning highlight VFX on ", _last_highlighted.name)
		_highlight_vfx = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.8
		cylinder.bottom_radius = 0.8
		cylinder.height = 2.2
		_highlight_vfx.mesh = cylinder
		
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.0, 1.0, 0.0, 0.4) # Brighter green
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.no_depth_test = true # Always visible
		mat.emission_enabled = true
		mat.emission = Color(0.0, 1.0, 0.0)
		mat.emission_energy_multiplier = 1.5
		
		_highlight_vfx.material_override = mat
		_last_highlighted.add_child(_highlight_vfx)
		_highlight_vfx.position = Vector3(0, 0.8, 0) # Highlight centered on character chest

func _get_mesh(node: Node3D) -> MeshInstance3D:
	if not node: return null
	var mesh := node.get_node_or_null("Mesh") as MeshInstance3D
	if not mesh:
		# Fallback: search children
		for child in node.get_children():
			if child is MeshInstance3D:
				return child
	return mesh

# =============================================================================
# Combat End Overlay & Stats Tracking
# =============================================================================

func _on_combat_started() -> void:
	combat_hud.show_hud()
	_combat_start_time = Time.get_ticks_msec() / 1000.0
	_total_damage_dealt = 0.0
	_total_damage_received = 0.0
	_total_kills = 0
	_total_switches = 0

func _on_combat_ended() -> void:
	combat_hud.hide_hud()

func _on_game_over() -> void:
	combat_hud.hide_hud()

func _on_victory_for_overlay() -> void:
	if not combat_end_overlay: return
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _combat_start_time
	combat_end_overlay.show_victory({
		"time_seconds": elapsed,
		"damage_dealt": _total_damage_dealt,
		"damage_received": _total_damage_received,
		"kills": _total_kills,
		"switches": _total_switches,
	})

func _on_defeat_for_overlay() -> void:
	if not combat_end_overlay: return
	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _combat_start_time
	combat_end_overlay.show_defeat({
		"time_seconds": elapsed,
		"damage_dealt": _total_damage_dealt,
		"damage_received": _total_damage_received,
		"kills": _total_kills,
		"switches": _total_switches,
	})

func _on_restart_requested() -> void:
	_reload_current_scene()

func _reload_current_scene() -> void:
	var current_scene := get_tree().current_scene
	if current_scene:
		var scene_path := current_scene.scene_file_path
		if not scene_path.is_empty():
			get_tree().reload_current_scene()
		else:
			# Fallback: remove and re-add the root
			var root := get_tree().root
			root.remove_child(current_scene)
			current_scene.queue_free()
			var new_scene: Node = load("res://assets/scenes/TestArena.tscn").instantiate()
			root.add_child(new_scene)
			get_tree().current_scene = new_scene

# =============================================================================
# Floating Damage Numbers
# =============================================================================

var _last_enemy_hp_for_floating: Dictionary = {}

func _on_enemy_damage_taken(amount: int, enemy: EnemyAIController) -> void:
	if not enemy or not is_instance_valid(enemy): return
	_total_damage_dealt += amount
	var world_pos := enemy.global_position + Vector3(0, 1.8, 0)
	var is_crit: bool = randf() < 0.1  # ~10% chance for visual crit flair
	
	# Bounce towards active character
	var attacker_pos := Vector3.ZERO
	if switch_controller and is_instance_valid(switch_controller.current_character):
		var body = switch_controller.current_character.get_parent() as Node3D
		if body:
			attacker_pos = body.global_position

	FloatingDamageNumber.spawn(get_tree(), world_pos, amount, false, is_crit, attacker_pos)

func _on_party_member_hp_changed(current: int, max_hp: int, member: PartyMemberState) -> void:
	if not member or not is_instance_valid(member): return
	var body := member.get_parent() as Node3D
	if not body or not is_instance_valid(body): return
	# Only show floating number when HP decreased (damage taken)
	var prev_hp: int = _last_enemy_hp_for_floating.get(member.get_instance_id(), max_hp)
	if current < prev_hp:
		var dmg: int = prev_hp - current
		_total_damage_received += dmg
		var world_pos := body.global_position + Vector3(0, 1.8, 0)
		
		# Bounce "forward" from where the player is facing (generic attacker dir)
		var attacker_pos = body.global_position + body.global_transform.basis.z * 2.0
		FloatingDamageNumber.spawn(get_tree(), world_pos, dmg, false, false, attacker_pos)
	# Update tracked HP for next delta comparison
	_last_enemy_hp_for_floating[member.get_instance_id()] = current



func _on_enemy_died_for_stats(enemy: EnemyAIController) -> void:
	_total_kills += 1
	# Death thump number
	if enemy and is_instance_valid(enemy):
		var world_pos := enemy.global_position + Vector3(0, 2.0, 0)
		FloatingDamageNumber.spawn(get_tree(), world_pos, 0, false, true)  # "0!" as death marker
