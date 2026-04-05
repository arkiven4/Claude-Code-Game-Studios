class_name CombatHUD
extends CanvasLayer

@onready var active_portrait: TextureRect = %ActivePortrait
@onready var active_hp_bar: ProgressBar = %ActiveHPBar
@onready var active_mp_bar: ProgressBar = %ActiveMPBar
@onready var inactive_portrait: TextureRect = %InactivePortrait
@onready var inactive_hp_bar: ProgressBar = %InactiveHPBar
@onready var switch_cooldown_label: Label = %SwitchCooldownLabel
@onready var skill_slots: Array = []  # populated in _ready via %SkillSlot1..4

var _switch_cooldown: float = 0.0

func _ready() -> void:
	hide()

func _process(delta: float) -> void:
	if _switch_cooldown > 0.0:
		_switch_cooldown -= delta
		if switch_cooldown_label:
			switch_cooldown_label.text = "%.1f" % max(0.0, _switch_cooldown)

func show_hud() -> void:
	show()

func hide_hud() -> void:
	hide()

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

func update_skill_cooldown(slot: int, remaining: float, total: float) -> void:
	pass  # TODO: update radial cooldown overlay on skill icon

func show_switch_cooldown(duration: float) -> void:
	_switch_cooldown = duration
