# chapter_state_manager.gd
class_name ChapterStateManager
extends Node

## Tracks narrative progress, story flags, and visited locations.

signal chapter_changed(chapter_id: int)
signal flag_changed(flag: String, value: bool)
signal beat_completed(beat: int)

enum StoryBeat { NONE, PROLOGUE_AWAKENING, PROLOGUE_SAVED_VILLAGERS, PROLOGUE_MET_EVAN, CHAPTER_1_REACHED_HUB, CHAPTER_1_ALLIED_WITH_WITCH, CHAPTER_1_BETRAYED_EVAN }

@export var save_key: String = "ChapterState"

var current_chapter_id: int = 0
var chapter_flags: Dictionary = {}
var visited_locations: Array[String] = []
var completed_encounters: Array[int] = []
var completed_story_beats: Array[int] = []

func _ready() -> void:
	# Register with SaveManager if it exists in the scene tree
	var save_manager := get_tree().get_first_node_in_group("SaveManager") as SaveManager
	if save_manager:
		save_manager.register_saveable(self)

func set_chapter(chapter_id: int) -> void:
	if current_chapter_id == chapter_id: return
	current_chapter_id = chapter_id
	chapter_changed.emit(current_chapter_id)
	print("[ChapterState] Chapter changed to: %d" % current_chapter_id)

func set_flag(flag: String, value: bool = true) -> void:
	var old_value = chapter_flags.get(flag, false)
	chapter_flags[flag] = value
	if old_value != value:
		flag_changed.emit(flag, value)
		print("[ChapterState] Flag %s set to %s" % [flag, value])

func has_flag(flag: String) -> bool:
	return chapter_flags.get(flag, false)

func complete_beat(beat: StoryBeat) -> void:
	if beat == StoryBeat.NONE: return
	if beat in completed_story_beats: return
	completed_story_beats.append(beat)
	beat_completed.emit(beat)
	print("[ChapterState] Story Beat Completed: %d" % beat)

func is_beat_completed(beat: StoryBeat) -> bool:
	return beat in completed_story_beats

func record_visit(scene_path: String) -> void:
	if not scene_path in visited_locations:
		visited_locations.append(scene_path)
		print("[ChapterState] Visited location recorded: %s" % scene_path)

func has_visited(scene_path: String) -> bool:
	return scene_path in visited_locations

func record_encounter_completion(encounter_id: int) -> void:
	if not encounter_id in completed_encounters:
		completed_encounters.append(encounter_id)
		print("[ChapterState] Encounter %d completed." % encounter_id)

# --- Save/Load ---

func get_save_data() -> Dictionary:
	return {
		"current_chapter_id": current_chapter_id,
		"chapter_flags": chapter_flags,
		"visited_locations": visited_locations,
		"completed_encounters": completed_encounters,
		"completed_story_beats": completed_story_beats
	}

func load_save_data(data: Dictionary) -> void:
	current_chapter_id = data.get("current_chapter_id", 0)
	chapter_flags = data.get("chapter_flags", {})
	visited_locations = Array(data.get("visited_locations", []), TYPE_STRING, &"", null)
	completed_encounters = Array(data.get("completed_encounters", []), TYPE_INT, &"", null)
	completed_story_beats = Array(data.get("completed_story_beats", []), TYPE_INT, &"", null)
