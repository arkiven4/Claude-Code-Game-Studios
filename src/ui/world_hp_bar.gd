# world_hp_bar.gd
class_name WorldHPBar
extends Node3D

## World-space health bar rendered above an enemy.
## Uses a shader for 100% stable, left-anchored scaling.

const BAR_SHADER = preload("res://assets/shaders/world_hp_bar.gdshader")

var _mesh_instance: MeshInstance3D
var _material: ShaderMaterial

func _ready() -> void:
	_create_bar()
	call_deferred("_connect_to_parent")

func _create_bar() -> void:
	_mesh_instance = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 0.12)
	_mesh_instance.mesh = mesh
	
	_material = ShaderMaterial.new()
	_material.shader = BAR_SHADER
	_mesh_instance.material_override = _material
	
	# Ensure it's always on top of other translucent things if needed
	_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	add_child(_mesh_instance)
	
	# Start hidden
	visible = false

func _connect_to_parent() -> void:
	var p := get_parent()
	if not p: return
	if p.has_signal("damage_taken"):
		p.damage_taken.connect(_on_damage_taken)
	if "current_hp" in p and "max_hp" in p:
		update_hp(p.current_hp, p.max_hp)

func update_hp(current: float, maximum: float) -> void:
	if not _material or maximum <= 0.0: return
	
	# Logic: Hide if full health or dead
	if current >= maximum or current <= 0:
		visible = false
		return
	
	visible = true
	var ratio := clampf(current / maximum, 0.0, 1.0)
	
	# Update the shader parameter - this is mathematically perfect
	_material.set_shader_parameter("health_ratio", ratio)

func _on_damage_taken(_amount: int) -> void:
	var p := get_parent()
	if p and "current_hp" in p:
		update_hp(p.current_hp, p.max_hp)
