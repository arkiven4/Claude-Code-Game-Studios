# skill_sandbox.gd
extends Node3D

## A sandbox for testing character skills and VFX.

@export var characters: Array[CharacterData] = []
@export var character_scene: PackedScene # A scene with PartyMemberState and SkillExecutionSystem

@onready var enemy_dummy: Node3D = $TrainingDummy
@onready var ally_dummy: Node3D = $AlliesDummy
@onready var spawn_point: Node3D = $CasterDummy
@onready var caster_anim_tree: AnimationTree
@onready var caster_anim_state: AnimationNodeStateMachinePlayback
@onready var character_selector: OptionButton = %CharacterSelector
@onready var skill_selector: ItemList = %SkillSelector
@onready var tier_selector: SpinBox = %TierSelector
@onready var total_damage_label: Label = %TotalDamageLabel
@onready var last_damage_label: Label = %LastDamageLabel
@onready var dps_label: Label = %DPSLabel

var current_character_node: Node3D
var current_char_data: CharacterData
var current_skill_execution_system: SkillExecutionSystem
var current_party_member_state: PartyMemberState
var caster_status_effects: StatusEffectsSystem

var default_projectile_scene := preload("res://assets/scenes/Projectile.tscn")

# Casting animation state tracking
var _is_currently_casting: bool = false
var _cast_anim_phase_switched: bool = false
var _cast_anim_timer: float = 0.0
var _forced_cast_anim: bool = false # For instant-cast skills

func _process(delta: float) -> void:
		if not is_instance_valid(current_skill_execution_system):
				return
		if not current_skill_execution_system.state:
				return

		var is_casting: bool = current_skill_execution_system.state.get("is_casting")

		# Handle real cast (cast_time > 0)
		if is_casting and not _is_currently_casting:
				_is_currently_casting = true
				_cast_anim_phase_switched = false
				_forced_cast_anim = false
				print("[SkillSandbox] Casting started — playing general_Interact")
				if caster_anim_state:
						caster_anim_state.travel("general_Interact")

		if is_casting and not _cast_anim_phase_switched:
				var cast_timer: float = current_skill_execution_system._cast_timer
				if cast_timer <= 0.5:
						_cast_anim_phase_switched = true
						print("[SkillSandbox] Cast timer < 0.5s — switching to general_Throw")
						if caster_anim_state:
								caster_anim_state.travel("general_Throw")

		if not is_casting and _is_currently_casting and not _forced_cast_anim:
				_is_currently_casting = false
				_cast_anim_phase_switched = false
				print("[SkillSandbox] Casting finished — resetting to Idle_A")
				_reset_caster_animation()

		# Handle forced cast animation for instant-cast skills
		if _forced_cast_anim:
				_cast_anim_timer -= delta
				if _cast_anim_timer <= 0.5 and not _cast_anim_phase_switched:
						_cast_anim_phase_switched = true
						print("[SkillSandbox] Forced anim < 0.5s — switching to general_Throw")
						if caster_anim_state:
								caster_anim_state.travel("general_Throw")
				if _cast_anim_timer <= 0.0:
						_forced_cast_anim = false
						_is_currently_casting = false
						_cast_anim_phase_switched = false
						print("[SkillSandbox] Forced anim done — resetting to Idle_A")
						_reset_caster_animation()

func _ready() -> void:
		if not character_scene:
				character_scene = load("res://assets/scenes/characters/Witch.tscn")
		if characters.is_empty():
				_load_all_characters()
		_setup_ui()
		if not characters.is_empty():
				_spawn_character(0)
		enemy_dummy.stats_updated.connect(_on_dummy_stats_updated)
		if ally_dummy and ally_dummy.has_signal("stats_updated"):
				ally_dummy.stats_updated.connect(_on_dummy_stats_updated)
		
		# Get AnimationTree from CasterDummy's Skeleton_Mage child
		if spawn_point and spawn_point.has_node("Skeleton_Mage/AnimationTree"):
				caster_anim_tree = spawn_point.get_node("Skeleton_Mage/AnimationTree")
				if caster_anim_tree:
						# The state machine is inside a BlendTree, path is parameters/StateMachine/playback
						caster_anim_state = caster_anim_tree.get("parameters/StateMachine/playback")

func _load_all_characters() -> void:
		var path := "res://assets/data/characters/"
		var dir := DirAccess.open(path)
		if dir:
				dir.list_dir_begin()
				var file_name = dir.get_next()
				while file_name != "":
						if not dir.current_is_dir() and file_name.ends_with(".tres"):
								var char_data = load(path + file_name)
								if char_data is CharacterData:
										characters.append(char_data)
						file_name = dir.get_next()
				dir.list_dir_end()

func _setup_ui() -> void:
		character_selector.clear()
		for char in characters:
				character_selector.add_item(char.display_name)
		
		character_selector.item_selected.connect(_on_character_selected)
		%ExecuteButton.pressed.connect(_execute_selected_skill)
		%ResetButton.pressed.connect(_reset_sandbox)

func _on_character_selected(index: int) -> void:
		_spawn_character(index)

func _spawn_character(index: int) -> void:
		current_char_data = characters[index]

		# Use CasterDummy as the caster directly (with its Skeleton_Mage visual)
		current_character_node = spawn_point
		current_character_node.visible = true

		# Clear old references BEFORE freeing to avoid dangling references
		current_party_member_state = null
		current_skill_execution_system = null
		caster_status_effects = null

		# Remove old systems if they exist
		if current_character_node.has_node("PartyMemberState"):
				current_character_node.get_node("PartyMemberState").queue_free()
		if current_character_node.has_node("SkillExecutionSystem"):
				current_skill_execution_system = null # redundant but safe
				current_character_node.get_node("SkillExecutionSystem").queue_free()
		if current_character_node.has_node("StatusEffectsSystem"):
				current_character_node.get_node("StatusEffectsSystem").queue_free()

		# Call_deferred to ensure the freed nodes are fully gone before we create new ones
		await get_tree().process_frame

		# 1. Setup StatusEffectsSystem FIRST (PartyMemberState depends on it in _ready)
		var sfx_node := Node.new()
		sfx_node.name = "StatusEffectsSystem"
		sfx_node.set_script(load("res://src/gameplay/status_effects_system.gd"))
		current_character_node.add_child(sfx_node)
		caster_status_effects = current_character_node.get_node("StatusEffectsSystem")

		# 2. Setup PartyMemberState
		var state_node := Node.new()
		state_node.name = "PartyMemberState"
		state_node.set_script(load("res://src/gameplay/party_member_state.gd"))
		current_character_node.add_child(state_node)

		current_party_member_state = current_character_node.get_node("PartyMemberState")
		current_party_member_state.character_data = current_char_data
		current_party_member_state.character_level = 30 # Max level for testing
		current_party_member_state.reinitialize_stats()

		# Link StatusEffectsSystem to PartyMemberState (bidirectional)
		if caster_status_effects:
				caster_status_effects.parent_node = current_party_member_state

		# 3. Setup SkillExecutionSystem
		var system_node := Node.new()
		system_node.name = "SkillExecutionSystem"
		system_node.set_script(load("res://src/gameplay/skill_execution_system.gd"))
		current_character_node.add_child(system_node)

		current_skill_execution_system = current_character_node.get_node("SkillExecutionSystem")

		# Explicitly link system to state if not already set
		if is_instance_valid(current_skill_execution_system):
				if not current_skill_execution_system.state:
						current_skill_execution_system.state = current_party_member_state
				# Assign default projectile scene if missing
				if not current_skill_execution_system.projectile_scene:
						current_skill_execution_system.projectile_scene = default_projectile_scene

		_update_skill_list()

func _update_skill_list() -> void:
		skill_selector.clear()
		if not current_char_data: return
		
		for i in range(current_char_data.skill_slots.size()):
				var skill := current_char_data.skill_slots[i]
				if skill:
						skill_selector.add_item(skill.display_name)
				else:
						skill_selector.add_item("Empty Slot %d" % i)

func _execute_selected_skill() -> void:
		var selected_items := skill_selector.get_selected_items()
		if selected_items.is_empty(): return
		
		var slot_index := selected_items[0]
		var tier := int(tier_selector.value)
		var skill := current_char_data.skill_slots[slot_index]
		if not skill: return

		# Target selection: Damage -> Enemy, Buff/Heal (Support/Status) -> Allies
		var target_pos: Vector3 = enemy_dummy.global_position
		
		var is_healing_buffing: bool = skill.skill_type == SkillData.SkillType.SUPPORT or \
									  skill.skill_type == SkillData.SkillType.STATUS
									  
		var targets_ally: bool = skill.target_type == SkillData.TargetType.SINGLE_ALLY or \
								 skill.target_type == SkillData.TargetType.ALL_ALLIES
								 
		if is_healing_buffing or targets_ally:
				if ally_dummy:
						target_pos = ally_dummy.global_position
		
		# Point character at target
		print("[SkillSandbox] Targeting position: %s" % str(target_pos))
		current_character_node.look_at(target_pos, Vector3.UP)
		current_character_node.rotation.x = 0
		
		# Execute skill via system
		if is_instance_valid(current_skill_execution_system) and current_skill_execution_system.has_method("execute_skill_rl"):
				# Reset cooldowns/MP to ensure successful execution in sandbox
				if is_instance_valid(current_party_member_state) and current_party_member_state.has_method("reset_for_encounter"):
						current_party_member_state.reset_for_encounter(false)
				elif is_instance_valid(current_party_member_state):
						current_party_member_state.current_mp = current_party_member_state.max_mp
						for i in range(4):
								current_party_member_state.skill_cooldowns[i] = 0.0

				# Use execute_skill_rl to bypass targeting modes
				# force_self=false will fallback to lowest-HP ally (our dummy)
				var success: bool = current_skill_execution_system.execute_skill_rl(slot_index, tier, false)
				print("[SkillSandbox] execute_skill_rl(slot=%d, tier=%d) success: %s" % [slot_index, tier, success])

				# If instant-cast (cast_time=0), play forced animation
				if success and skill.cast_time <= 0.0 and not _is_currently_casting:
						_forced_cast_anim = true
						_cast_anim_timer = 1.0 # 1s animation lock
						_cast_anim_phase_switched = false
						print("[SkillSandbox] Instant skill — forcing 1s cast animation (Interact -> Throw at 0.5s)")
						if caster_anim_state:
								caster_anim_state.travel("general_Interact")
		elif is_instance_valid(current_skill_execution_system) and current_skill_execution_system.has_method("try_activate_skill"):
				var success: bool = current_skill_execution_system.try_activate_skill(slot_index, tier)
				print("[SkillSandbox] try_activate_skill(slot=%d, tier=%d) success: %s" % [slot_index, tier, success])
		else:
				_direct_execute_test(skill, tier)

func _direct_execute_test(skill: SkillData, tier: int) -> void:
		print("Directly executing %s at tier %d" % [skill.display_name, tier])
		# This is a fallback if the full system isn't ready for manual triggering
		# In a real sandbox, we want the full animation/VFX flow.

func _reset_caster_animation() -> void:
		if caster_anim_state:
				caster_anim_state.travel("Idle_A")

func _on_dummy_stats_updated(total: int, last: int, dps: float) -> void:
		total_damage_label.text = "Total Damage: %d" % total
		last_damage_label.text = "Last Hit: %d" % last
		dps_label.text = "DPS (5s): %.1f" % dps

func _reset_sandbox() -> void:
		enemy_dummy.reset_stats()
		if ally_dummy and ally_dummy.has_method("reset_stats"):
				ally_dummy.reset_stats()
		if is_instance_valid(current_party_member_state):
				current_party_member_state.current_hp = current_party_member_state.max_hp
				current_party_member_state.current_mp = current_party_member_state.max_mp
		_reset_caster_animation()
