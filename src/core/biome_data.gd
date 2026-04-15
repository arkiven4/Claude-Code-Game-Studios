# biome_data.gd
class_name BiomeData
extends Resource

## Data container for a chapter's visual and mechanical theme.
## Used by LevelGenerator to produce procedural maps.

@export_group("Identity")
@export var chapter_id: int = 1
@export var biome_name: String = "Forest"

@export_group("Assets")
@export var segment_pool: Array[PackedScene] = []
@export var start_segments: Array[PackedScene] = []
@export var end_segments: Array[PackedScene] = []

@export_group("Spawns")
@export var enemy_pool: Array[EnemyData] = []
@export var loot_tables: Array[LootTable] = []

@export_group("Environment")
@export var world_environment: WorldEnvironment
@export var music_track: AudioStream
@export var ambient_sound: AudioStream
