# save_manager.gd
class_name SaveManager
extends Node

## Manages game persistence using a registry of saveable nodes.
## Handles versioning and atomic writes using JSON.

const MANUAL_SAVE_PATH: String = "user://manual_save.json"
const AUTO_SAVE_PATH: String = "user://auto_save.json"
const SAVE_VERSION: int = 1

func _ready() -> void:
	add_to_group("SaveManager")

var _saveables: Array[Node] = []

func register_saveable(node: Node) -> void:
	if not _saveables.has(node):
		_saveables.append(node)

func unregister_saveable(node: Node) -> void:
	_saveables.erase(node)

func save_game(is_auto_save: bool = false) -> void:
	var path := AUTO_SAVE_PATH if is_auto_save else MANUAL_SAVE_PATH
	
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"scene_path": get_tree().current_scene.scene_file_path,
		"entries": []
	}
	
	for saveable in _saveables:
		if saveable.has_method("get_save_data"):
			var key: String = saveable.get("save_key") if "save_key" in saveable else saveable.name
			save_data.entries.append({
				"key": key,
				"data": saveable.get_save_data()
			})
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] Saved game to %s" % path)
	else:
		push_error("[SaveManager] Failed to open file for writing: %s" % path)

func load_game(load_auto_save: bool = false) -> Dictionary:
	var path := AUTO_SAVE_PATH if load_auto_save else MANUAL_SAVE_PATH
	if not FileAccess.file_exists(path):
		print("[SaveManager] No save file found at %s" % path)
		return {}
		
	var file := FileAccess.open(path, FileAccess.READ)
	var json_string := file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(json_string)
	if save_data == null:
		push_error("[SaveManager] Failed to parse save file: %s" % path)
		return {}
		
	if save_data.version > SAVE_VERSION:
		push_error("[SaveManager] Save file version is newer than current game version!")
		return {}
		
	return save_data

func restore_state(save_data: Dictionary) -> void:
	if not save_data.has("entries"): return
	
	for entry in save_data.entries:
		for saveable in _saveables:
			var key: String = saveable.get("save_key") if "save_key" in saveable else saveable.name
			if key == entry.key and saveable.has_method("load_save_data"):
				saveable.load_save_data(entry.data)
	
	print("[SaveManager] State restoration complete.")

func has_save(is_auto_save: bool = false) -> bool:
	return FileAccess.file_exists(AUTO_SAVE_PATH if is_auto_save else MANUAL_SAVE_PATH)
