## ZoneTracker
## Monitors which SurfaceZone the player is currently inside.
## Add as a child of the generated surface level root.
## Automatically connects to all SurfaceZone BoundaryArea nodes in its parent.
##
## Listen to zone_changed for music, ambience, enemy-pool, and minimap updates.
##
## Implements: design/gdd/procedural-level-system.md
class_name ZoneTracker
extends Node

## Currently active zone (null until player enters a zone).
var current_zone: SurfaceZone = null

## Emitted whenever the player crosses a zone boundary.
signal zone_changed(from_zone: SurfaceZone, to_zone: SurfaceZone)

func _ready() -> void:
	# Defer so parent's children are all ready before we scan.
	call_deferred("_connect_all_zones")

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Re-scans and connects to all SurfaceZone nodes under the parent.
## Call this after new zones are added at runtime.
func refresh() -> void:
	_connect_all_zones()

func _connect_all_zones() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	for child: Node in parent.get_children():
		if child is SurfaceZone:
			_connect_zone(child as SurfaceZone)

func _connect_zone(zone: SurfaceZone) -> void:
	var area: Area3D = zone.get_boundary_area()
	if area == null:
		push_warning(
			"ZoneTracker: SurfaceZone '%s' has no BoundaryArea child — skipped." % zone.name
		)
		return

	# Guard against double-connecting
	if area.body_entered.is_connected(_on_zone_body_entered.bind(zone)):
		return

	area.body_entered.connect(_on_zone_body_entered.bind(zone))
	area.body_exited.connect(_on_zone_body_exited.bind(zone))

# ---------------------------------------------------------------------------
# Zone events
# ---------------------------------------------------------------------------

func _on_zone_body_entered(body: Node3D, zone: SurfaceZone) -> void:
	if not body.is_in_group("player"):
		return
	if zone == current_zone:
		return

	var previous: SurfaceZone = current_zone
	current_zone = zone

	zone.zone_entered.emit(zone)
	zone_changed.emit(previous, zone)

func _on_zone_body_exited(body: Node3D, zone: SurfaceZone) -> void:
	if not body.is_in_group("player"):
		return
	if zone != current_zone:
		return

	zone.zone_exited.emit(zone)
	# current_zone cleared only when player enters a new zone (avoids null flicker)
