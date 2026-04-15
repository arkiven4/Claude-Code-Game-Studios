# character_visuals.gd
class_name CharacterVisuals
extends Node3D

## Manages placeholder capsule visuals with distinct colors for roles.

@export var role_color: Color = Color.WHITE

func _ready() -> void:
	_apply_visuals()

func _apply_visuals() -> void:
	# Find or create a MeshInstance3D capsule
	var mesh_instance := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		mesh_instance.mesh = capsule
		add_child(mesh_instance)
		mesh_instance.position.y = 0.9 # Offset to stand on floor
	
	# Create a simple toon material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = role_color
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
	mat.roughness = 0.5
	
	# Add an outline (Next Pass)
	mat.next_pass = _create_outline_material()
	
	mesh_instance.material_override = mat

func _create_outline_material() -> StandardMaterial3D:
	var outline_mat := StandardMaterial3D.new()
	outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_mat.albedo_color = Color.BLACK
	outline_mat.grow = true
	outline_mat.grow_amount = 0.03
	return outline_mat
