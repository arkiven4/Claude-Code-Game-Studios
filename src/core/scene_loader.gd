# scene_loader.gd
class_name SceneLoader
extends Node

## Manages async scene loading, portal transitions, and state restoration.

signal loading_started(scene_path: String)
signal loading_progress(scene_path: String, progress: float)
signal loading_complete(scene_path: String)

@export var save_manager: SaveManager
@export var default_fade_duration: float = 0.5

var _target_scene_path: String = ""
var _is_loading: bool = false
var _pending_save_data: Dictionary = {}
var _pending_portal_data: Dictionary = {}

func _process(_delta: float) -> void:
	if not _is_loading:
		return
		
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(_target_scene_path, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			loading_progress.emit(_target_scene_path, progress[0])
		ResourceLoader.THREAD_LOAD_LOADED:
			_complete_loading()
		ResourceLoader.THREAD_LOAD_FAILED:
			_is_loading = false
			push_error("[SceneLoader] Failed to load scene: %s" % _target_scene_path)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_is_loading = false
			push_error("[SceneLoader] Invalid resource: %s" % _target_scene_path)

func load_scene(scene_path: String) -> void:
	if _is_loading: return
	_target_scene_path = scene_path
	_start_loading()

func load_from_save(save_data: Dictionary) -> void:
	if _is_loading: return
	_target_scene_path = save_data.scene_path
	_pending_save_data = save_data
	_start_loading()

func transition_through_portal(scene_path: String, exit_pos: Vector3, exit_rot: Vector3) -> void:
	if _is_loading: return
	_target_scene_path = scene_path
	_pending_portal_data = {"pos": exit_pos, "rot": exit_rot}
	_start_loading()

func _start_loading() -> void:
	_is_loading = true
	loading_started.emit(_target_scene_path)
	ResourceLoader.load_threaded_request(_target_scene_path)

func _complete_loading() -> void:
	_is_loading = false
	var new_scene_resource: PackedScene = ResourceLoader.load_threaded_get(_target_scene_path)
	var new_scene := new_scene_resource.instantiate()
	
	# Replace current scene
	var root := get_tree().root
	var current_scene := get_tree().current_scene
	root.remove_child(current_scene)
	current_scene.queue_free()
	
	root.add_child(new_scene)
	get_tree().current_scene = new_scene
	
	# Wait one frame for initialization
	await get_tree().process_frame
	
	# Restore state if needed
	if not _pending_save_data.is_empty():
		var sm := save_manager
		if not sm:
			sm = get_tree().get_first_node_in_group("SaveManager") as SaveManager
		if sm:
			sm.restore_state(_pending_save_data)
		_pending_save_data = {}
	
	# Handle portal positioning
	if not _pending_portal_data.is_empty():
		var player := get_tree().get_first_node_in_group("Player")
		if player:
			player.global_position = _pending_portal_data.pos
			player.global_rotation = _pending_portal_data.rot
		_pending_portal_data = {}
	
	loading_complete.emit(_target_scene_path)
	print("[SceneLoader] Completed loading: %s" % _target_scene_path)
