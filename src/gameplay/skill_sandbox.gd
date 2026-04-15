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

func _process(delta: float) -> void:
		if not is_instance_valid(current_skill_execution_system):
				return
		if not current_skill_execution_system.state:
				return

		# The sandbox only needs to track if a cast is currently active for UI/blocking
		_is_currently_casting = current_skill_execution_system.state.get("is_casting")

func _ready() -> void:
		if not character_scene:
				character_scene = load("res://assets/scenes/characters/Evelyn.tscn")
		if characters.is_empty():
				_load_all_characters()
		_setup_ui()
		
		# Find Evelyn in the loaded characters and select her by default
		var default_index := 0
		for i in range(characters.size()):
				if characters[i].display_name.to_lower().contains("evelyn"):
						default_index = i
						break
						
		if not characters.is_empty():
				_spawn_character(default_index)
				character_selector.selected = default_index
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
								var full_path = path + file_name
								if FileAccess.file_exists(full_path):
										var char_data = load(full_path)
										if char_data == null:
												push_error("[SkillSandbox] FAILED to load: " + full_path)
										elif char_data is CharacterData:
												characters.append(char_data)
										else:
												push_warning("[SkillSandbox] File is not CharacterData: " + full_path)
								else:
										push_error("[SkillSandbox] File NOT FOUND (even though listed): " + full_path)
						file_name = dir.get_next()
				dir.list_dir_end()

func _setup_ui() -> void:
		character_selector.clear()
		for char in characters:
				character_selector.add_item(char.display_name)
		
		character_selector.item_selected.connect(_on_character_selected)
		%ExecuteButton.pressed.connect(_execute_selected_skill)
		%BuffButton.pressed.connect(_receive_test_buff)
		%StunButton.pressed.connect(_receive_test_stun)
		%DamageButton.pressed.connect(_receive_test_damage)
		%ResetButton.pressed.connect(_reset_sandbox)

func _receive_test_damage() -> void:
		if not is_instance_valid(current_character_node): return
		if current_character_node.has_method("take_damage"):
				current_character_node.take_damage({"damage": 100})
				print("[SkillSandbox] Applied 100 test damage to caster")

func _receive_test_buff() -> void:
		if not is_instance_valid(caster_status_effects): return
		
		# Apply a generic ATK+ buff for testing
		var effect := StatusEffect.new()
		effect.effect_id = "test_atk_buff"
		effect.display_name = "ATK Up (Test)"
		effect.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
		effect.stat_to_modify = StatusEffect.StatToModify.ATK
		effect.modify_type = StatusEffect.ModifyType.PERCENTAGE
		effect.effect_value = 0.5 # +50%
		effect.is_hostile = false
		effect.duration = 5.0
		
		# StatusEffectsSystem.apply_effect(definition, applied_by_id, tier)
		caster_status_effects.apply_effect(effect, "sandbox", 1)
		print("[SkillSandbox] Applied test ATK buff to caster")

func _receive_test_stun() -> void:
		if not is_instance_valid(caster_status_effects): return
		
		# Apply a generic stun for testing
		var effect := StatusEffect.new()
		effect.effect_id = "test_stun"
		effect.display_name = "Stunned (Test)"
		effect.effect_category = StatusEffect.EffectCategory.ACTION_DENIAL
		effect.is_hostile = true
		effect.duration = 2.0
		
		# StatusEffectsSystem.apply_effect(definition, applied_by_id, tier)
		caster_status_effects.apply_effect(effect, "sandbox", 1)
		print("[SkillSandbox] Applied test stun to caster")

func _on_character_selected(index: int) -> void:
		_spawn_character(index)

func _spawn_character(index: int) -> void:
		current_char_data = characters[index]

		# Use CasterDummy as the caster directly (with its Skeleton_Mage visual)
		current_character_node = spawn_point
		current_character_node.visible = true

		# Use pre-existing systems on CasterDummy instead of recreating them
		current_party_member_state = current_character_node.get_node_or_null("PartyMemberState")
		current_skill_execution_system = current_character_node.get_node_or_null("SkillExecutionSystem")
		caster_status_effects = current_character_node.get_node_or_null("StatusEffectsSystem")

		if current_party_member_state:
				current_party_member_state.character_data = current_char_data
				current_party_member_state.character_level = 30 # Max level for testing
				current_party_member_state.reinitialize_stats()

		# Link StatusEffectsSystem to PartyMemberState (bidirectional)
		if caster_status_effects and current_party_member_state:
				caster_status_effects.parent_node = current_party_member_state
				# Re-link signals in case they were disconnected
				if not caster_status_effects.effect_applied.is_connected(current_party_member_state._on_effect_applied):
						caster_status_effects.effect_applied.connect(current_party_member_state._on_effect_applied)
				if not caster_status_effects.effect_removed.is_connected(current_party_member_state._on_effect_removed):
						caster_status_effects.effect_removed.connect(current_party_member_state._on_effect_removed)

		# Explicitly link system to state if not already set
		if is_instance_valid(current_skill_execution_system):
				if not current_skill_execution_system.state:
						current_skill_execution_system.state = current_party_member_state
				if not current_skill_execution_system.status_effects:
						current_skill_execution_system.status_effects = caster_status_effects
				# Assign default projectile scene if missing
				if not current_skill_execution_system.projectile_scene:
						current_skill_execution_system.projectile_scene = default_projectile_scene
				
				# Unification: Link AnimationTree to the system so it handles visuals centrally
				var anim_tree: AnimationTree = _find_animation_tree(current_character_node)
				if anim_tree:
						current_skill_execution_system.animation_tree = anim_tree
						# Trigger re-ready to initialize _anim_state
						current_skill_execution_system._ready()

		_update_skill_list()

func _find_animation_tree(node: Node) -> AnimationTree:
		if node is AnimationTree: return node
		for child in node.get_children():
				var res := _find_animation_tree(child)
				if res: return res
		return null

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
