# hud_status_effect_indicator.gd
class_name HUDStatusEffectIndicator
extends HBoxContainer

## Displays status effect icons in the CombatHUD for the active party member.
##
## Each icon shows:
##   - Icon texture or colored placeholder
##   - Duration bar at bottom that fills left-to-right
##   - Numeric time label below the icon

const ICON_SIZE: Vector2 = Vector2(28, 28)
const ICON_GAP: float = 4.0
const BAR_HEIGHT: float = 3.0
const LABEL_FONT_SIZE: int = 8

## Colour mapping by effect category — same as world indicator.
const CATEGORY_COLORS := {
	StatusEffect.EffectCategory.ACTION_DENIAL:      Color(1.0, 0.15, 0.15, 1.0),
	StatusEffect.EffectCategory.MOVEMENT_IMPAIR:    Color(0.25, 0.5, 1.0, 1.0),
	StatusEffect.EffectCategory.DAMAGE_OVER_TIME:   Color(1.0, 0.5, 0.0, 1.0),
	StatusEffect.EffectCategory.STAT_MODIFIER:      Color(0.7, 0.2, 1.0, 1.0),
	StatusEffect.EffectCategory.DAMAGE_ABSORPTION:  Color(1.0, 1.0, 1.0, 1.0),
	StatusEffect.EffectCategory.INVINCIBILITY:      Color(1.0, 0.85, 0.0, 1.0),
}

## Container for one effect: icon + bar + time label
class EffectDisplay:
	var container: Control
	var bar: ColorRect
	var label: Label
	var effect: ActiveEffect

	func _init(c: Control, b: ColorRect, l: Label, e: ActiveEffect) -> void:
		container = c
		bar = b
		label = l
		effect = e

var _sfx_system: StatusEffectsSystem
var _displays: Array[EffectDisplay] = []

func _ready() -> void:
	add_theme_constant_override("separation", int(ICON_GAP))
	hide()

func _process(delta: float) -> void:
	## Update duration bars and time labels every frame
	for display in _displays:
		var ae := display.effect
		var def := ae.definition
		if not def or def.duration <= 0.0: continue

		var ratio := clampf(ae.remaining_duration / def.duration, 0.0, 1.0)

		## Update bar width
		if display.bar:
			display.bar.size.x = ratio * ICON_SIZE.x

		## Update time label
		if display.label:
			display.label.text = "%.1f" % ae.remaining_duration

func connect_to_party_member(member: PartyMemberState) -> void:
	if _sfx_system:
		if _sfx_system.effect_applied.is_connected(_on_effects_changed):
			_sfx_system.effect_applied.disconnect(_on_effects_changed)
		if _sfx_system.effect_removed.is_connected(_on_effects_changed):
			_sfx_system.effect_removed.disconnect(_on_effects_changed)

	if not member: return

	var parent_node := member.get_parent()
	if not parent_node: return

	_sfx_system = parent_node.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
	if _sfx_system:
		_sfx_system.effect_applied.connect(_on_effects_changed)
		_sfx_system.effect_removed.connect(_on_effects_changed)
	_rebuild_all()

func _on_effects_changed(_effect: ActiveEffect) -> void:
	_rebuild_all()

func _rebuild_all() -> void:
	## Clear old icons
	for display in _displays:
		if display.container: display.container.queue_free()
	_displays.clear()

	if not _sfx_system or _sfx_system.active_effects.is_empty():
		hide()
		return

	show()

	## Build icon row
	for effect in _sfx_system.active_effects:
		var def: StatusEffect = effect.definition
		if not def: continue

		var display := _create_display(def, effect)
		add_child(display.container)
		_displays.append(display)

func _create_display(def: StatusEffect, effect: ActiveEffect) -> EffectDisplay:
	var container := Control.new()
	container.custom_minimum_size = ICON_SIZE

	## Icon frame
	var frame := TextureRect.new()
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	if def.icon:
		frame.texture = def.icon
	else:
		var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		var base_color: Color = CATEGORY_COLORS.get(def.effect_category, Color(0.6, 0.6, 0.6, 1.0))
		img.set_pixel(0, 0, base_color)
		frame.texture = ImageTexture.create_from_image(img)

	frame.tooltip_text = def.display_name
	container.add_child(frame)

	## Duration bar at bottom
	var bar := ColorRect.new()
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.anchor_left = 0.0
	bar.anchor_right = 1.0
	bar.offset_top = -BAR_HEIGHT
	bar.offset_bottom = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if effect.definition.duration > 0.0:
		var ratio := clampf(effect.remaining_duration / effect.definition.duration, 0.0, 1.0)
		bar.size.x = ratio * ICON_SIZE.x
		var base_color: Color = CATEGORY_COLORS.get(def.effect_category, Color(0.6, 0.6, 0.6, 1.0))
		bar.color = base_color
	else:
		bar.size.x = ICON_SIZE.x
		bar.color = Color(0.6, 0.6, 0.6, 1.0)
	container.add_child(bar)

	## Time label centered inside the icon
	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	if def.duration > 0.0:
		label.text = "%.1f" % effect.remaining_duration
	else:
		label.text = "∞"
	container.add_child(label)

	return EffectDisplay.new(container, bar, label, effect)
