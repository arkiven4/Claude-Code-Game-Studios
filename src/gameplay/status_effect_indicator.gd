# status_effect_indicator.gd
class_name StatusEffectIndicator
extends Node3D

## World-space billboarded status effect icons displayed above a character's head.
##
## Each active effect gets:
##   - A small colored quad (icon or placeholder)
##   - A duration bar at the bottom of the quad
##   - A numeric time label above the icon
##
## Icon colors by category:
##   - Red    = ACTION_DENIAL (stun)
##   - Blue   = MOVEMENT_IMPAIR (slow)
##   - Orange = DAMAGE_OVER_TIME
##   - Purple = STAT_MODIFIER (debuff)
##   - White  = SHIELD / DAMAGE_ABSORPTION
##   - Gold   = INVINCIBILITY

const ICON_SIZE: float = 0.25
const ICON_GAP: float = 0.04
const HEIGHT_ABOVE_HEAD: float = 0.2
const LABEL_HEIGHT: float = 0.15
const LABEL_FONT_SIZE: int = 8

## Colour mapping by effect category.
const CATEGORY_COLORS := {
	StatusEffect.EffectCategory.ACTION_DENIAL:      Color(1.0, 0.15, 0.15, 1.0),
	StatusEffect.EffectCategory.MOVEMENT_IMPAIR:    Color(0.25, 0.5, 1.0, 1.0),
	StatusEffect.EffectCategory.DAMAGE_OVER_TIME:   Color(1.0, 0.5, 0.0, 1.0),
	StatusEffect.EffectCategory.STAT_MODIFIER:      Color(0.7, 0.2, 1.0, 1.0),
	StatusEffect.EffectCategory.DAMAGE_ABSORPTION:  Color(1.0, 1.0, 1.0, 1.0),
	StatusEffect.EffectCategory.INVINCIBILITY:      Color(1.0, 0.8, 0.2, 1.0),
}

## Shader-based icon quad — renders icon with animated border wipe.
const EFFECT_ICON_SHADER = preload("res://assets/shaders/effect_icon.gdshader")

## Per-effect display: icon mesh only. Duration shown via shader border wipe outline.
class EffectDisplay:
	var icon_mesh: MeshInstance3D
	var effect: ActiveEffect

	func _init(i: MeshInstance3D, e: ActiveEffect) -> void:
		icon_mesh = i
		effect = e

var _sfx_system: StatusEffectsSystem
var _displays: Array[EffectDisplay] = []

func _ready() -> void:
	## Find the sibling StatusEffectsSystem
	_sfx_system = get_node_or_null("StatusEffectsSystem")
	if not _sfx_system:
		_sfx_system = get_parent().get_node_or_null("StatusEffectsSystem")

	if not _sfx_system:
		var parent := get_parent()
		if parent:
			for child in parent.get_children():
				if child is StatusEffectsSystem:
					_sfx_system = child
					break

	if _sfx_system:
		_sfx_system.effect_applied.connect(_on_effect_applied)
		_sfx_system.effect_removed.connect(_on_effect_removed)

	visible = false

func _process(_delta: float) -> void:
	## Update icon shader border-wipe outline each frame.
	for display in _displays:
		var ae := display.effect
		if not ae.definition or not display.icon_mesh: continue
		var mat := display.icon_mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("duration_ratio", _get_remaining_ratio(ae))

func _on_effect_applied(effect: ActiveEffect) -> void:
	_rebuild_all()

func _on_effect_removed(effect: ActiveEffect) -> void:
	_rebuild_all()

func _rebuild_all() -> void:
	## Clear old icons
	for display in _displays:
		if display.icon_mesh: display.icon_mesh.queue_free()
	_displays.clear()

	if not _sfx_system:
		visible = false
		return

	if _sfx_system.active_effects.is_empty():
		visible = false
		return

	visible = true

	## Build icon row
	var count := _sfx_system.active_effects.size()
	var total_width := count * (ICON_SIZE + ICON_GAP) - ICON_GAP
	var start_x := -total_width * 0.5

	for i in range(count):
		var effect: ActiveEffect = _sfx_system.active_effects[i]
		var def: StatusEffect = effect.definition
		if not def: continue

		var icon := _create_icon_quad(def)

		var x_offset := start_x + i * (ICON_SIZE + ICON_GAP) + ICON_SIZE * 0.5
		icon.position.x = x_offset
		icon.position.y = HEIGHT_ABOVE_HEAD

		add_child(icon)
		_displays.append(EffectDisplay.new(icon, effect))

func _create_icon_quad(def: StatusEffect) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(ICON_SIZE, ICON_SIZE)
	mesh_instance.mesh = mesh

	var mat := ShaderMaterial.new()
	mat.shader = EFFECT_ICON_SHADER

	var base_color: Color = CATEGORY_COLORS.get(def.effect_category, Color(0.6, 0.6, 0.6, 1.0))
	mat.set_shader_parameter("icon_color", base_color)

	if def.icon:
		mat.set_shader_parameter("use_texture", true)
		mat.set_shader_parameter("icon_texture", def.icon)
	else:
		mat.set_shader_parameter("use_texture", false)

	mat.set_shader_parameter("duration_ratio", 1.0)

	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

func _get_remaining_ratio(ae: ActiveEffect) -> float:
	## Uses _full_duration (resolved at apply-time) so stripped .tres values don't break the ratio.
	if ae._full_duration <= 0.0: return 1.0
	return clampf(ae.remaining_duration / ae._full_duration, 0.0, 1.0)
