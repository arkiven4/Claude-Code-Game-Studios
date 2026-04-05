class_name CombatHUD
extends CanvasLayer

@onready var active_portrait: ActivePortrait = %ActivePortrait
@onready var active_hp_bar: ProgressBar = %ActiveHPBar
@onready var active_shield_bar: ProgressBar = %ActiveShieldBar
@onready var active_mp_bar: ProgressBar = %ActiveMPBar
@onready var status_effects_row: HUDStatusEffectIndicator = %StatusEffectsRow
@onready var inactive_portrait: TextureRect = %InactivePortrait
@onready var inactive_hp_bar: ProgressBar = %InactiveHPBar
@onready var switch_cooldown_label: Label = %SwitchCooldownLabel

var _switch_cooldown: float = 0.0
var _active_member: PartyMemberState
var _skill_ui_slots: Array[Control] = []
var _max_shield_encountered: int = 0
var _crosshair: Control

func _ready() -> void:
	_skill_ui_slots = [
		$SkillBar/SkillSlot0,
		$SkillBar/SkillSlot1,
		$SkillBar/SkillSlot2,
		$SkillBar/SkillSlot3,
	]
	_create_crosshair()
	hide()

func _create_crosshair() -> void:
	# Use a Control node as a container centered on screen
	_crosshair = Control.new()
	_crosshair.name = "CrosshairContainer"
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	
	# Center the container
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	
	# Add a vertical and horizontal line for the crosshair
	var h_line := ColorRect.new()
	h_line.size = Vector2(16, 2)
	h_line.position = -h_line.size / 2.0
	h_line.color = Color.WHITE
	h_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.add_child(h_line)
	
	var v_line := ColorRect.new()
	v_line.size = Vector2(2, 16)
	v_line.position = -v_line.size / 2.0
	v_line.color = Color.WHITE
	v_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.add_child(v_line)
	
	_crosshair.visible = false

func _process(delta: float) -> void:
	# Switch cooldown countdown
	if _switch_cooldown > 0.0:
		_switch_cooldown -= delta
		if switch_cooldown_label:
			switch_cooldown_label.text = "%.1f" % max(0.0, _switch_cooldown)

	# Poll skill cooldowns every frame
	if _active_member:
		var char_data: CharacterData = _active_member.character_data
		for i in range(_skill_ui_slots.size()):
			var remaining := _active_member.skill_cooldowns[i]
			var total := 0.0
			if char_data and i < char_data.skill_slots.size() and char_data.skill_slots[i]:
				total = char_data.skill_slots[i].base_cooldown
			var slot = _skill_ui_slots[i]
			if slot and slot.has_method("update_cooldown"):
				slot.update_cooldown(remaining, total)

func show_hud() -> void:
	show()

func hide_hud() -> void:
	hide()
	if _crosshair:
		_crosshair.visible = false

func show_crosshair(color: Color = Color.WHITE) -> void:
	if _crosshair:
		_crosshair.visible = true
		for child in _crosshair.get_children():
			if child is ColorRect:
				child.color = color

func hide_crosshair() -> void:
	if _crosshair:
		_crosshair.visible = false

## Call whenever the active character changes to refresh icons and begin polling their cooldowns.
func set_active_character(member: PartyMemberState) -> void:
	_active_member = member
	if not member: return
	var char_data: CharacterData = member.character_data
	if not char_data: return

	if active_portrait:
		active_portrait.set_character(member)

	if status_effects_row:
		status_effects_row.connect_to_party_member(member)

	for i in range(_skill_ui_slots.size()):
		var skill: SkillData = char_data.skill_slots[i] if i < char_data.skill_slots.size() else null
		var slot = _skill_ui_slots[i]
		if slot and slot.has_method("set_skill"):
			slot.set_skill(skill)

## Call to update the inactive member display (portrait and initial health).
func set_inactive_character(member: PartyMemberState) -> void:
	if not member: return
	var char_data: CharacterData = member.character_data
	if not char_data: return
	
	if inactive_portrait:
		inactive_portrait.texture = char_data.portrait_sprite
	
	update_inactive_health(member.current_hp, member.max_hp)

func update_active_health(current: float, maximum: float) -> void:
	if active_hp_bar:
		active_hp_bar.max_value = maximum
		active_hp_bar.value = current

func update_active_shield(current: int) -> void:
	if not active_shield_bar: return
	if current > _max_shield_encountered:
		_max_shield_encountered = current
	if current <= 0:
		_max_shield_encountered = 0
		active_shield_bar.visible = false
		return
	active_shield_bar.visible = true
	active_shield_bar.max_value = _max_shield_encountered
	active_shield_bar.value = current

func update_active_mp(current: float, maximum: float) -> void:
	if active_mp_bar:
		active_mp_bar.max_value = maximum
		active_mp_bar.value = current

func update_inactive_health(current: float, maximum: float) -> void:
	if inactive_hp_bar:
		inactive_hp_bar.max_value = maximum
		inactive_hp_bar.value = current

func show_switch_cooldown(duration: float) -> void:
	_switch_cooldown = duration
