## RoomChunk
## Base script for every hand-crafted room .tscn.
## Name exit nodes "Exit_0", "Exit_1", etc. — each needs one Area3D child.
## Name the entrance node "EntranceMarker".
## Enemy spawn points are plain Node3D children — no script needed.
##
## Auto-detection: if exit_markers / entrance_marker are left unassigned in the
## Inspector, _ready() scans children by name automatically. This means greybox
## templates work without any manual Inspector assignment.
class_name RoomChunk
extends Node3D

enum RoomType { START, COMBAT, CORRIDOR, REST, JUNCTION, BOSS }

## Semantic type used by the generator for pool selection.
@export var room_type: RoomType = RoomType.COMBAT
## Exit anchor nodes. Leave empty to auto-detect children named "Exit_*".
@export var exit_markers: Array[Node3D] = []
## Player teleports here when entering this room.
## Leave unassigned to auto-detect child named "EntranceMarker".
@export var entrance_marker: Node3D

## Emitted when the player body enters an exit Area3D.
signal player_exited(exit_index: int)

func _ready() -> void:
	_auto_detect_markers()
	_wire_exits()
	_add_exit_visuals()

# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _auto_detect_markers() -> void:
	if entrance_marker == null:
		entrance_marker = find_child("EntranceMarker", false, false) as Node3D

	if exit_markers.is_empty():
		for child: Node in get_children():
			if child.name.begins_with("Exit_") and child is Node3D:
				exit_markers.append(child as Node3D)
		# Sort by suffix number so Exit_0 < Exit_1 < Exit_2
		exit_markers.sort_custom(func(a: Node3D, b: Node3D) -> bool:
			return a.name < b.name
		)

func _wire_exits() -> void:
	for i: int in exit_markers.size():
		var area: Area3D = _find_exit_area(exit_markers[i])
		if area == null:
			push_warning("RoomChunk: exit_markers[%d] ('%s') has no Area3D child." % [i, exit_markers[i].name])
			continue
		print("[RoomChunk] wiring exit %d on %s — area: %s" % [i, name, area.name])
		var idx: int = i
		area.body_entered.connect(func(body: Node3D) -> void:
			print("[RoomChunk] body_entered exit %d: %s  is_player=%s" % [idx, body.name, body.is_in_group("player")])
			if body.is_in_group("player"):
				player_exited.emit(idx)
		)

## Returns the first Area3D child of a marker node, or null.
func _find_exit_area(marker: Node3D) -> Area3D:
	for child: Node in marker.get_children():
		if child is Area3D:
			return child as Area3D
	return null

## Adds a glowing yellow panel at every exit so you can see them during testing.
## Remove this call from _ready() when you have real door art.
func _add_exit_visuals() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.0, 1.0)
	mat.emission_energy_multiplier = 2.0

	for marker: Node3D in exit_markers:
		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 2.0, 0.1)
		box.material = mat
		mesh_instance.mesh = box
		mesh_instance.name = "ExitVisual"
		marker.add_child(mesh_instance)
