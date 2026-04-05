# world_hp_bar.gd
class_name WorldHPBar
extends Node3D

## World-space health bar with shield overlay rendered above an enemy.
##
## Layout (top to bottom):
##   [Shield Bar]     — blue bar, only visible when shield > 0
##   [HP Bar]         — green/yellow/red with white shield overlay

const BAR_SHADER = preload("res://assets/shaders/world_hp_bar.gdshader")

var _hp_mesh: MeshInstance3D
var _hp_material: ShaderMaterial
var _shield_mesh: MeshInstance3D
var _shield_material: ShaderMaterial
var _shield_overlay_mesh: MeshInstance3D
var _shield_overlay_material: ShaderMaterial

const BAR_WIDTH: float = 1.0
const BAR_HEIGHT: float = 0.12
const BAR_GAP: float = 0.03
const SHIELD_COLOR: Color = Color(0.3, 0.6, 1.0, 1.0)
const SHIELD_OVERLAY_ALPHA: float = 0.45

var _max_hp: int = 0
var _max_shield: int = 0

func _ready() -> void:
	_create_hp_bar()
	_create_shield_bar()
	_create_shield_overlay()
	call_deferred("_connect_to_parent")

func _create_hp_bar() -> void:
	_hp_mesh = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_hp_mesh.mesh = mesh

	_hp_material = ShaderMaterial.new()
	_hp_material.shader = BAR_SHADER
	_hp_mesh.material_override = _hp_material
	_hp_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_hp_mesh.position.y = -(BAR_HEIGHT * 0.5 + BAR_GAP)
	add_child(_hp_mesh)
	_hp_mesh.visible = false

func _create_shield_bar() -> void:
	_shield_mesh = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(BAR_WIDTH, BAR_HEIGHT * 0.7)
	_shield_mesh.mesh = mesh

	_shield_material = ShaderMaterial.new()
	_shield_material.shader = BAR_SHADER
	## Override to solid blue via a custom tint parameter
	_shield_mesh.material_override = _shield_material
	_shield_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	## Position above HP bar
	_shield_mesh.position.y = BAR_HEIGHT * 0.35 + BAR_GAP
	add_child(_shield_mesh)
	_shield_mesh.visible = false

func _create_shield_overlay() -> void:
	## A thin white overlay ON TOP of the HP bar showing shield as a fraction.
	_shield_overlay_mesh = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_shield_overlay_mesh.mesh = mesh

	_shield_overlay_material = ShaderMaterial.new()
	_shield_overlay_material.shader = preload("res://assets/shaders/world_hp_bar.gdshader")
	_shield_overlay_mesh.material_override = _shield_overlay_material
	_shield_overlay_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_shield_overlay_mesh.position.y = -(BAR_HEIGHT * 0.5 + BAR_GAP)
	## Slightly in front of the HP bar
	_shield_overlay_mesh.position.z = 0.005
	add_child(_shield_overlay_mesh)
	_shield_overlay_mesh.visible = false

func _connect_to_parent() -> void:
	var p := get_parent()
	if not p: return
	if "current_hp" in p and "max_hp" in p:
		_max_hp = int(p.max_hp)
		if p.has_signal("damage_taken"):
			p.damage_taken.connect(_on_damage_taken)
		if p.has_signal("shield_changed"):
			p.shield_changed.connect(_on_shield_changed)
		update_all()

func update_all() -> void:
	var p := get_parent()
	if not p: return
	var hp: int = p.get("current_hp") if "current_hp" in p else 0
	var max: int = p.get("max_hp") if "max_hp" in p else 1
	var shield: int = p.get("shield_value") if "shield_value" in p else 0
	_max_hp = max
	## Track peak shield value for bar scaling
	if shield > _max_shield:
		_max_shield = shield
	update_hp(hp, max)
	update_shield(shield)

func update_hp(current: float, maximum: float) -> void:
	if not _hp_material or maximum <= 0.0: return

	if current >= maximum or current <= 0:
		_hp_mesh.visible = false
		_shield_overlay_mesh.visible = false
		return

	_hp_mesh.visible = true
	var ratio := clampf(current / maximum, 0.0, 1.0)
	_hp_material.set_shader_parameter("health_ratio", ratio)

	## Re-evaluate shield overlay visibility
	var p := get_parent()
	if p:
		var shield: int = p.get("shield_value") if "shield_value" in p else 0
		update_shield(shield)

func update_shield(shield: int) -> void:
	## Track peak shield
	if shield > _max_shield:
		_max_shield = shield

	if shield <= 0 or _max_shield <= 0:
		_shield_mesh.visible = false
		_shield_overlay_mesh.visible = false
		return

	var shield_ratio := clampf(float(shield) / float(_max_shield), 0.0, 1.0)

	## Shield bar (above HP)
	_shield_mesh.visible = true
	_shield_material.set_shader_parameter("health_ratio", shield_ratio)
	_shield_material.set_shader_parameter("tint_color", SHIELD_COLOR)

	## Shield overlay (on HP bar)
	_shield_overlay_mesh.visible = true
	_shield_overlay_material.set_shader_parameter("health_ratio", shield_ratio)
	_shield_overlay_material.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, SHIELD_OVERLAY_ALPHA))

func _on_damage_taken(_amount: int) -> void:
	update_all()

func _on_shield_changed(_value: int) -> void:
	update_all()
