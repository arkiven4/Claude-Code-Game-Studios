# skill_cast_indicator.gd
class_name SkillCastIndicator
extends Node3D

## Displays a skill icon above a caster's head when they cast a spell.
##
## When a skill is cast, this shows the skill's icon texture in a billboarded quad
## positioned above the entity's head. The indicator fades out after a configurable duration.

const ICON_SIZE: float = 0.3
const HEIGHT_ABOVE_HEAD: float = 0.35
const DISPLAY_DURATION: float = 1.2
const FADE_DURATION: float = 0.3

## Shader-based icon quad for skill display.
const EFFECT_ICON_SHADER = preload("res://assets/shaders/effect_icon.gdshader")

var _icon_mesh: MeshInstance3D
var _display_timer: float = 0.0
var _is_fading: bool = false
var _fade_timer: float = 0.0

func _ready() -> void:
	_icon_mesh = _create_icon_quad()
	_icon_mesh.visible = false
	add_child(_icon_mesh)

func _process(delta: float) -> void:
	if _icon_mesh.visible:
		if _is_fading:
			_fade_timer -= delta
			var alpha := clampf(_fade_timer / FADE_DURATION, 0.0, 1.0)
			var mat := _icon_mesh.material_override as ShaderMaterial
			if mat:
				mat.set_shader_parameter("duration_ratio", alpha)
			
			if _fade_timer <= 0.0:
				_icon_mesh.visible = false
		else:
			_display_timer -= delta
			if _display_timer <= 0.0:
				_start_fade()

## Shows the skill icon above the caster's head.
func show_skill_icon(skill: SkillData) -> void:
	if not skill:
		return
	
	_icon_mesh.visible = true
	_display_timer = DISPLAY_DURATION
	_is_fading = false
	
	var mat := _icon_mesh.material_override as ShaderMaterial
	if mat:
		if skill.icon:
			mat.set_shader_parameter("use_texture", true)
			mat.set_shader_parameter("icon_texture", skill.icon)
		else:
			mat.set_shader_parameter("use_texture", false)
			# Set a color based on skill type as fallback
			var type_color := _get_skill_type_color(skill.skill_type)
			mat.set_shader_parameter("icon_color", type_color)
		
		mat.set_shader_parameter("duration_ratio", 1.0)

func _start_fade() -> void:
	_is_fading = true
	_fade_timer = FADE_DURATION

func _create_icon_quad() -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(ICON_SIZE, ICON_SIZE)
	mesh_instance.mesh = mesh
	
	var mat := ShaderMaterial.new()
	mat.shader = EFFECT_ICON_SHADER
	mat.set_shader_parameter("icon_color", Color(1.0, 1.0, 1.0, 1.0))
	mat.set_shader_parameter("use_texture", false)
	mat.set_shader_parameter("duration_ratio", 1.0)
	
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh_instance

func _get_skill_type_color(skill_type: SkillData.SkillType) -> Color:
	match skill_type:
		SkillData.SkillType.DAMAGE:
			return Color(1.0, 0.2, 0.2, 1.0)  # Red
		SkillData.SkillType.STATUS:
			return Color(0.6, 0.2, 1.0, 1.0)  # Purple
		SkillData.SkillType.SUPPORT:
			return Color(0.2, 1.0, 0.4, 1.0)  # Green
		SkillData.SkillType.UTILITY:
			return Color(1.0, 0.8, 0.2, 1.0)  # Gold
		_:
			return Color(1.0, 1.0, 1.0, 1.0)  # White
