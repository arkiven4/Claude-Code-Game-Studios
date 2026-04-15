## SurfaceZone
## A seamless outdoor zone chunk (forest clearing, beach, village district, etc.).
## Place terrain mesh, props, and enemy spawn nodes as children.
## Add a child Area3D named "BoundaryArea" with a BoxShape3D matching the zone size
## so ZoneTracker can detect which zone the player is in.
##
## Entrance markers (Node3D named "EntranceMarker_N") define where TransitionDoors
## deposit the player when entering from a door/dungeon exit inside this zone.
##
## Implements: design/gdd/procedural-level-system.md
class_name SurfaceZone
extends Node3D

## Display name used in UI and for music/ambience lookups.
@export var zone_name: String = ""
## Biome tag — matched against BiomeConfig resources (e.g. "forest", "beach", "desert").
@export var biome: String = "forest"
## Whether enemies in this zone respawn when the player re-enters.
@export var enemies_respawn: bool = true

## Emitted by ZoneTracker when the player enters this zone's boundary.
signal zone_entered(zone: SurfaceZone)
## Emitted by ZoneTracker when the player leaves this zone's boundary.
signal zone_exited(zone: SurfaceZone)

## Returns the BoundaryArea3D child, or null if not found.
func get_boundary_area() -> Area3D:
	return find_child("BoundaryArea", false, false) as Area3D

## Returns a named entrance marker by index (EntranceMarker_0, _1, etc.).
func get_entrance_marker(index: int = 0) -> Node3D:
	var marker_name: String = "EntranceMarker_%d" % index
	var found: Node = find_child(marker_name, false, false)
	if found == null:
		# Fallback: first marker with any EntranceMarker prefix
		found = find_child("EntranceMarker*", false, false)
	return found as Node3D
