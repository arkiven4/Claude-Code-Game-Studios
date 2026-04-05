class_name SkillSlotUI
extends Control

## One skill slot in the bottom HUD bar.
## Shows: colored background (icon placeholder), dark cooldown overlay, key label, cooldown timer.

@export var slot_index: int = 0
@export var key_label_text: String = "J"

const SLOT_SIZE := Vector2(64.0, 64.0)
const SLOT_COLORS: Array[Color] = [
	Color(0.45, 0.20, 0.65),  # slot 0 – purple
	Color(0.20, 0.40, 0.65),  # slot 1 – blue
	Color(0.65, 0.40, 0.15),  # slot 2 – amber
	Color(0.20, 0.60, 0.30),  # slot 3 – green
]

var _bg: ColorRect
var _cooldown_overlay: ColorRect
var _cooldown_label: Label
var _key_label: Label

func _ready() -> void:
	custom_minimum_size = SLOT_SIZE

	# Colored background (skill icon placeholder)
	_bg = ColorRect.new()
	_bg.position = Vector2.ZERO
	_bg.size = SLOT_SIZE
	_bg.color = SLOT_COLORS[slot_index % SLOT_COLORS.size()]
	add_child(_bg)

	# Dark overlay that fills from top and shrinks down as cooldown expires
	_cooldown_overlay = ColorRect.new()
	_cooldown_overlay.position = Vector2.ZERO
	_cooldown_overlay.size = SLOT_SIZE
	_cooldown_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	_cooldown_overlay.visible = false
	add_child(_cooldown_overlay)

	# Remaining seconds, centered
	_cooldown_label = Label.new()
	_cooldown_label.position = Vector2.ZERO
	_cooldown_label.size = SLOT_SIZE
	_cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cooldown_label.visible = false
	add_child(_cooldown_label)

	# Key binding hint (bottom-right corner)
	_key_label = Label.new()
	_key_label.position = Vector2.ZERO
	_key_label.size = SLOT_SIZE
	_key_label.text = key_label_text
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_key_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	add_child(_key_label)

## Call when the active character changes to refresh the slot's appearance.
func set_skill(skill: SkillData) -> void:
	if not _bg: return
	if skill:
		_bg.color = SLOT_COLORS[slot_index % SLOT_COLORS.size()]
		# When icon textures exist, swap them in here via TextureRect
	else:
		_bg.color = Color(0.18, 0.18, 0.18)

## Call every frame (or on cooldown change) to update the overlay.
func update_cooldown(remaining: float, total: float) -> void:
	if not _cooldown_overlay: return
	if remaining <= 0.0 or total <= 0.0:
		_cooldown_overlay.visible = false
		_cooldown_label.visible = false
		return
	var ratio := clampf(remaining / total, 0.0, 1.0)
	_cooldown_overlay.visible = true
	_cooldown_overlay.size.y = SLOT_SIZE.y * ratio
	_cooldown_label.visible = true
	_cooldown_label.text = "%.1f" % remaining
