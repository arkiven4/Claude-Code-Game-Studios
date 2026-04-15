## WorldLayerManager
## Manages a stack of world layers: Surface → Interior or Dungeon on top.
## Add this node to your root scene. Inject it into TransitionDoor via @export.
##
## Stack behaviour:
##   push_layer()  — freeze surface, load new layer, move player to entrance
##   pop_layer()   — unload top layer, resume surface, return player to saved position
##
## Implements: design/gdd/procedural-level-system.md (Layer Stack section)
class_name WorldLayerManager
extends Node

## Emitted when a new layer is pushed onto the stack.
signal layer_pushed(layer: Node3D, layer_type: String)
## Emitted when the top layer is popped and surface resumes.
signal layer_popped(layer_type: String)
## Emitted when the active zone or layer changes (use for music/ambience).
signal active_context_changed(layer_type: String, zone_name: String)

## The surface root node (assign in the editor or call set_surface_root() on ready).
@export var surface_root: Node3D

var _layer_stack: Array[Node3D] = []
var _layer_type_stack: Array[String] = []
var _return_positions: Array[Vector3] = []

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Registers the persistent surface root (layer 0).
func set_surface_root(root: Node3D) -> void:
	surface_root = root

## Pushes a new layer (interior or dungeon root) on top of the surface.
## return_position: where the player will be teleported when popping back.
## entrance_marker_name: name of a Node3D child in the new layer to spawn at.
func push_layer(
	layer_root: Node3D,
	layer_type: String,
	return_position: Vector3,
	entrance_marker_name: String = "EntranceMarker"
) -> void:
	# Freeze surface (or current top layer)
	_freeze_top()

	# Register layer
	_layer_stack.push_back(layer_root)
	_layer_type_stack.push_back(layer_type)
	_return_positions.push_back(return_position)

	# Add to tree and activate
	add_child(layer_root)
	layer_root.process_mode = Node.PROCESS_MODE_INHERIT
	layer_root.visible = true

	# Teleport player to entrance
	var marker: Node3D = layer_root.find_child(entrance_marker_name, true, false) as Node3D
	_teleport_players_to(marker.global_position if marker else Vector3.ZERO)

	layer_pushed.emit(layer_root, layer_type)
	active_context_changed.emit(layer_type, layer_root.name)

## Pops the top layer and returns the player to the surface.
func pop_layer() -> void:
	if _layer_stack.is_empty():
		push_warning("WorldLayerManager: pop_layer() called with empty stack.")
		return

	var top: Node3D = _layer_stack.pop_back()
	var ltype: String = _layer_type_stack.pop_back()
	var return_pos: Vector3 = _return_positions.pop_back()

	top.queue_free()

	# Resume layer below (surface or previous interior)
	_resume_top()

	# Return player to saved position
	_teleport_players_to(return_pos)

	layer_popped.emit(ltype)
	var ctx_name: String = surface_root.name if _layer_stack.is_empty() else _layer_stack.back().name
	active_context_changed.emit("surface" if _layer_stack.is_empty() else ltype, ctx_name)

## True when only the surface layer is active.
func is_on_surface() -> bool:
	return _layer_stack.is_empty()

## Returns the currently active layer root (surface if stack is empty).
func current_layer() -> Node3D:
	if _layer_stack.is_empty():
		return surface_root
	return _layer_stack.back()

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _freeze_top() -> void:
	var top: Node3D = surface_root if _layer_stack.is_empty() else _layer_stack.back()
	if top:
		top.process_mode = Node.PROCESS_MODE_DISABLED
		top.visible = false

func _resume_top() -> void:
	var top: Node3D = surface_root if _layer_stack.is_empty() else _layer_stack.back()
	if top:
		top.process_mode = Node.PROCESS_MODE_INHERIT
		top.visible = true

func _teleport_players_to(pos: Vector3) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for p: Node in players:
		if p is Node3D:
			(p as Node3D).global_position = pos
