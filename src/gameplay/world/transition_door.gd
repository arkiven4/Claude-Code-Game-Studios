## TransitionDoor
## Place on any door, dungeon entrance, or building entry.
## Requires a child Area3D with CollisionShape3D to detect the player.
##
## For INTERIOR: assign target_scene (the building interior PackedScene).
## For DUNGEON:  assign dungeon_config (ChapterConfig for the dungeon).
## For SURFACE_EXIT: no scene needed — pops back to surface.
##
## Implements: design/gdd/procedural-level-system.md (Layer Stack section)
class_name TransitionDoor
extends Node3D

enum TargetType {
	INTERIOR,      ## Push a hand-authored interior scene
	DUNGEON,       ## Push a procedurally generated dungeon
	SURFACE_EXIT,  ## Pop current layer, return to surface
}

@export var target_type: TargetType = TargetType.INTERIOR
## Interior .tscn to load (used when target_type = INTERIOR).
@export var target_scene: PackedScene
## ChapterConfig for dungeon generation (used when target_type = DUNGEON).
@export var dungeon_config: ChapterConfig
## Pass -1 for a random dungeon each visit; >= 0 for a fixed seed.
@export var dungeon_seed: int = -1
## Name of the Node3D inside the new layer where the player spawns.
@export var entrance_marker_name: String = "EntranceMarker"

## Inject the WorldLayerManager from the scene tree.
@export var layer_manager: WorldLayerManager

## Whether the door can currently be activated.
@export var is_active: bool = true

## Emitted just before the transition executes.
signal door_activated(door: TransitionDoor)

var _dungeon_generator: ProceduralLevelGenerator

func _ready() -> void:
	var area: Area3D = _find_trigger_area()
	if area == null:
		push_warning("TransitionDoor '%s': no child Area3D found." % name)
		return
	area.body_entered.connect(_on_body_entered)

# ---------------------------------------------------------------------------
# Trigger
# ---------------------------------------------------------------------------

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if not body.is_in_group("player"):
		return
	if layer_manager == null:
		push_warning("TransitionDoor '%s': layer_manager is not assigned." % name)
		return

	door_activated.emit(self)

	match target_type:
		TargetType.INTERIOR:
			_enter_interior(body)
		TargetType.DUNGEON:
			_enter_dungeon(body)
		TargetType.SURFACE_EXIT:
			layer_manager.pop_layer()

# ---------------------------------------------------------------------------
# Transitions
# ---------------------------------------------------------------------------

func _enter_interior(player: Node3D) -> void:
	if target_scene == null:
		push_warning("TransitionDoor '%s': target_scene is not set." % name)
		return
	var interior: Node3D = target_scene.instantiate() as Node3D
	layer_manager.push_layer(
		interior,
		"interior",
		player.global_position,
		entrance_marker_name
	)

func _enter_dungeon(player: Node3D) -> void:
	if dungeon_config == null:
		push_warning("TransitionDoor '%s': dungeon_config is not set." % name)
		return

	_dungeon_generator = ProceduralLevelGenerator.new()
	_dungeon_generator.config = dungeon_config
	add_child(_dungeon_generator)

	var dungeon_root: Node3D = _dungeon_generator.generate(dungeon_seed)

	layer_manager.push_layer(
		dungeon_root,
		"dungeon",
		player.global_position,
		entrance_marker_name
	)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _find_trigger_area() -> Area3D:
	for child: Node in get_children():
		if child is Area3D:
			return child as Area3D
	return null
