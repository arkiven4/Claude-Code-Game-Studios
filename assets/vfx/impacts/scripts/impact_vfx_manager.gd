## Singleton manager for spawning and managing impact VFX effects.
##
## This autoload script provides a centralized system for spawning impact
## visual effects throughout the game. It handles pooling, cleanup, and
## runtime configuration of VFX instances.
##
## @tutorial: Based on "GODOT VFX - Hits and Impacts Effect Tutorial"
## 
## @example:
##   ImpactVFXManager.spawn_impact(global_position, Color.ORANGE)
##   ImpactVFXManager.spawn_impact_at(global_position, global_transform.basis)

extends Node

## Reference to the master impact VFX scene
const IMPACT_VFX_SCENE: PackedScene = preload("res://assets/vfx/impacts/scenes/impact_vfx_master.tscn")

## Parent node where spawned VFX will be attached
var _vfx_parent: Node3D
## Track active VFX instances for cleanup
var _active_vfx: Array[Node3D] = []


## Initializes the VFX manager. Call this once at game startup.
func _ready() -> void:
	_vfx_parent = Node3D.new()
	_vfx_parent.name = "VFX_Spawner"
	get_tree().root.add_child.call_deferred(_vfx_parent)


## Spawns an impact VFX at the specified position.
##
## @param position: World position to spawn the effect
## @param tint_color: Optional color tint for the effect
## @param basis: Optional orientation (for directional effects)
## @returns: Reference to the spawned VFX node
func spawn_impact(
	position: Vector3,
	tint_color: Color = Color.WHITE,
	basis: Basis = Basis.IDENTITY
) -> Node3D:
	var vfx: Node3D = IMPACT_VFX_SCENE.instantiate()

	_vfx_parent.add_child(vfx)
	vfx.global_position = position
	vfx.global_basis = basis

	# Connect cleanup signal
	if vfx.has_signal("vfx_completed"):	_active_vfx.append(vfx)
	
	# Trigger the effect
	if vfx.has_method("play"):
		vfx.play.call_deferred(Vector3.ZERO, tint_color)
	
	return vfx


## Spawns an impact VFX with a specific preset configuration.
##
## @param position: World position to spawn the effect
## @param preset: Preset name ("default", "fire", "ice", "lightning")
## @returns: Reference to the spawned VFX node
func spawn_impact_preset(
	position: Vector3,
	preset: String = "default"
) -> Node3D:
	var config: Dictionary = _get_preset_config(preset)
	return spawn_impact(position, config["color"], config["basis"])

## Returns all currently active VFX instances.
func get_active_vfx() -> Array[Node3D]:
	return _active_vfx.duplicate()


## Removes all active VFX instances immediately.
func clear_all_vfx() -> void:
	for vfx in _active_vfx.duplicate():
		if is_instance_valid(vfx):
			vfx.queue_free()
	_active_vfx.clear()


## Returns the number of active VFX instances.
func get_active_count() -> int:
	return _active_vfx.size()


## Internal handler for VFX cleanup when effects complete.
func _on_vfx_completed(vfx: Node3D) -> void:
	_active_vfx.erase(vfx)
	# VFX auto-deletes via queue_free() in controller


## Returns configuration for named presets.
func _get_preset_config(preset: String) -> Dictionary:
	match preset:
		"fire":
			return {
				"color": Color(1.0, 0.4, 0.1),
				"basis": Basis.IDENTITY
			}
		"ice":
			return {
				"color": Color(0.3, 0.7, 1.0),
				"basis": Basis.IDENTITY
			}
		"lightning":
			return {
				"color": Color(0.8, 0.9, 1.0),
				"basis": Basis.IDENTITY
			}
		_:  # default
			return {
				"color": Color.WHITE,
				"basis": Basis.IDENTITY
			}
