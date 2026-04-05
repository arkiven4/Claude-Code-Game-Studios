class_name CombatHUD
extends CanvasLayer

@onready var active_portrait: ActivePortrait = %ActivePortrait
@onready var active_hp_bar: ProgressBar = %ActiveHPBar
@onready var active_mp_bar: ProgressBar = %ActiveMPBar
@onready var inactive_portrait: TextureRect = %InactivePortrait
@onready var inactive_hp_bar: ProgressBar = %InactiveHPBar
@onready var switch_cooldown_label: Label = %SwitchCooldownLabel

var _switch_cooldown: float = 0.0
var _active_member: PartyMemberState
var _skill_ui_slots: Array[Control] = []

func _ready() -> void:
	_skill_ui_slots = [
		$SkillBar/SkillSlot0,
		$SkillBar/SkillSlot1,
		$SkillBar/SkillSlot2,
		$SkillBar/SkillSlot3,
	]
	hide()

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

## Call whenever the active character changes to refresh icons and begin polling their cooldowns.
func set_active_character(member: PartyMemberState) -> void:
	_active_member = member
	if not member: return
	var char_data: CharacterData = member.character_data
	if not char_data: return
	
	if active_portrait:
		active_portrait.set_character(member)
		
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
