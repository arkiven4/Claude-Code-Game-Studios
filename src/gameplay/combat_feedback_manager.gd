# combat_feedback_manager.gd
class_name CombatFeedbackManager
extends Object

## Static utility for "Game Feel" (Juiciness) — Screen Shake, Hitstop, and Material Flashes.
## Coordinates between camera, time scale, and character materials.

## Triggers a screen shake on the active CameraController.
static func screen_shake(tree: SceneTree, intensity: float = 0.2, duration: float = 0.15) -> void:
	var camera: CameraController = tree.get_first_node_in_group("MainCamera") as CameraController
	if camera and camera.has_method("shake"):
		camera.shake(intensity, duration)

## Triggers hitstop (momentary time pause/slowdown) to add weight to impacts.
static func hitstop(tree: SceneTree, duration: float = 0.05, time_scale: float = 0.01) -> void:
	var original_scale: float = Engine.time_scale
	Engine.time_scale = time_scale
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void:
		Engine.time_scale = original_scale
	)

## Triggers a white flash on a character's mesh to indicate a hit.
## Expects the target node to have a "MeshInstance3D" or children with materials.
static func hit_flash(target: Node3D, duration: float = 0.1) -> void:
	if not target: return
	
	# Find all MeshInstance3D nodes in the hierarchy
	var meshes: Array[MeshInstance3D] = []
	if target is MeshInstance3D:
		meshes.append(target)
	
	for child in target.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
		# Deep search for modular characters
		for subchild in child.get_children():
			if subchild is MeshInstance3D:
				meshes.append(subchild)

	for mesh in meshes:
		# Use a tween to briefly set the emission to white
		var mat: Material = mesh.get_active_material(0)
		if mat is StandardMaterial3D:
			# Clone material if it's shared to avoid flashing everyone
			# But for performance we might just use emission_enabled = true
			var tween: Tween = target.create_tween()
			var smat: StandardMaterial3D = mat as StandardMaterial3D
			var original_color: Color = smat.emission
			var original_enabled: bool = smat.emission_enabled
			
			smat.emission_enabled = true
			smat.emission = Color.WHITE
			
			tween.tween_callback(func() -> void:
				smat.emission = original_color
				smat.emission_enabled = original_enabled
			).set_delay(duration)

## High-level Juiciness combo for a light hit.
static func apply_light_hit(tree: SceneTree, target: Node3D) -> void:
	hit_flash(target, 0.08)
	hitstop(tree, 0.03)
	screen_shake(tree, 0.1, 0.1)

## High-level Juiciness combo for a heavy/crit hit.
static func apply_heavy_hit(tree: SceneTree, target: Node3D) -> void:
	hit_flash(target, 0.15)
	hitstop(tree, 0.08)
	screen_shake(tree, 0.3, 0.25)
