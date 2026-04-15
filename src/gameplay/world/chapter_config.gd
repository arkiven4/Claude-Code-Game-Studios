## ChapterConfig
## Per-chapter configuration resource for the procedural level generator.
## Create one .tres per chapter and assign room chunk scene pools.
class_name ChapterConfig
extends Resource

@export var chapter_id: int = 1
@export var chapter_name: String = ""
## Biome tag used for themeing (e.g. "forest", "crypt", "volcanic").
@export var biome_theme: String = "forest"

@export_group("Branch Layout")
## Number of parallel paths between START and JUNCTION.
@export_range(1, 4) var branch_count: int = 2
## Min rooms generated per branch (exclusive of start/junction/boss).
@export_range(1, 6) var rooms_per_branch_min: int = 2
## Max rooms generated per branch (exclusive of start/junction/boss).
@export_range(1, 6) var rooms_per_branch_max: int = 4

@export_group("Fixed Rooms")
## Always placed first. Must have one exit per branch_count.
@export var start_room: PackedScene
## Always placed after junction. Final challenge room.
@export var boss_room: PackedScene
## Where branches converge. Must have branch_count entrances and 1 exit.
@export var junction_room: PackedScene

@export_group("Room Pools")
## Heavy combat encounters — placed at even positions in a branch.
@export var combat_rooms: Array[PackedScene] = []
## Light traversal rooms — placed at odd positions in a branch.
@export var corridor_rooms: Array[PackedScene] = []
## Placed as the last room in each branch before the junction.
@export var rest_rooms: Array[PackedScene] = []
