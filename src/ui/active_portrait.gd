# active_portrait.gd
class_name ActivePortrait
extends SubViewportContainer

## Displays a live "portal" to a Camera3D attached to the character in the game world.

@onready var viewport: SubViewport = $SubViewport
@onready var display_camera: Camera3D = %Camera3D

var _target_camera: Camera3D = null

func _ready() -> void:
	# Keep transparency and setup viewport properly
	viewport.transparent_bg = true

## Updates the portrait to sync with the given party member's internal camera.
func set_character(member: PartyMemberState) -> void:
	_target_camera = null
	
	if not member:
		return
		
	var character_root = member.get_parent()
	if not character_root is Node3D:
		return
		
	# Look for a Camera3D named "PortraitCamera" in the character scene
	var cam_node = character_root.find_child("PortraitCamera", true, false)
	
	if cam_node is Camera3D:
		_target_camera = cam_node
		
		# Robust world linking
		var world = _target_camera.get_viewport().find_world_3d()
		if world and (viewport.world_3d != world or viewport.own_world_3d):
			viewport.own_world_3d = false
			viewport.world_3d = world
		
		# MATCH LAYERS RUNTIME: Ensure character mesh is actually on Layer 2
		# We don't want to rely solely on manual editor settings
		_set_layer_recursive(character_root, 2, true)
		
		# Match camera settings
		display_camera.fov = _target_camera.fov
		display_camera.near = _target_camera.near
		display_camera.far = _target_camera.far
	else:
		push_warning("[ActivePortrait] No Camera3D 'PortraitCamera' found for %s" % member.name)

func _process(_delta: float) -> void:
	if _target_camera and is_instance_valid(_target_camera):
		# Sync the UI display camera to the world camera's global transform
		display_camera.global_transform = _target_camera.global_transform

func _set_layer_recursive(node: Node, layer: int, enable: bool) -> void:
	if node is VisualInstance3D:
		# Use set_layer_mask_value to add Layer 2 (while keeping Layer 1)
		node.set_layer_mask_value(layer, enable)
	
	for child in node.get_children():
		_set_layer_recursive(child, layer, enable)
