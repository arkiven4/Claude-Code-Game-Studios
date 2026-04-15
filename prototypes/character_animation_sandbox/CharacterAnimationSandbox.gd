extends Node3D

## Character and Animation Sandbox
## A tool to preview and test any GLB/GLTF character and animation library.

@onready var model_container: Node3D = %ModelContainer
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var camera_pivot: Node3D = %CameraPivot
@onready var camera: Camera3D = %Camera3D

@onready var model_selector: OptionButton = %ModelSelector
@onready var anim_selector: OptionButton = %AnimSelector
@onready var lib_selector: OptionButton = %LibSelector
@onready var status_label: Label = %StatusLabel

var _current_model: Node = null
var _models: Array[String] = []
var _libs: Array[String] = []

# Camera control variables
var _orbit_active: bool = false
var _pan_active: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _orbit_sensitivity: float = 0.005
var _pan_sensitivity: float = 0.01
var _zoom_speed: float = 1.0

func _ready() -> void:
	# Scan for models and libraries
	_scan_assets()
	
	# Connect UI signals
	model_selector.item_selected.connect(_on_model_selected)
	anim_selector.item_selected.connect(_on_anim_selected)
	lib_selector.item_selected.connect(_on_lib_selected)
	
	if _models.size() > 0:
		_load_model(0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_orbit_active = event.pressed
			if _orbit_active:
				_last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_pan_active = event.pressed
			if _pan_active:
				_last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-_zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(_zoom_speed)
			
	elif event is InputEventMouseMotion:
		if _orbit_active:
			var delta = event.position - _last_mouse_pos
			_orbit_camera(delta)
			_last_mouse_pos = event.position
		elif _pan_active:
			var delta = event.position - _last_mouse_pos
			_pan_camera(delta)
			_last_mouse_pos = event.position

func _scan_assets() -> void:
	_models.clear()
	_libs.clear()
	
	model_selector.clear()
	lib_selector.clear()
	
	# Recursively search for .glb and .gltf files in imported_assets/
	var dir = DirAccess.open("res://imported_assets/")
	if dir:
		_recursive_scan("res://imported_assets/", _models, _libs)
	
	for m in _models:
		model_selector.add_item(m.get_file())
	
	lib_selector.add_item("None")
	for l in _libs:
		lib_selector.add_item(l.get_file())

func _recursive_scan(path: String, models: Array[String], libs: Array[String]) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_recursive_scan(path + file_name + "/", models, libs)
		else:
			if file_name.ends_with(".glb") or file_name.ends_with(".gltf"):
				var full_path = path + file_name
				# Heuristic: If it has "Animation" or "Rig" in path, it's likely a library
				if "Animations" in path or "Rig" in file_name:
					libs.append(full_path)
				else:
					models.append(full_path)
		file_name = dir.get_next()

func _load_model(index: int) -> void:
	if index < 0 or index >= _models.size():
		return
		
	# Clear existing model
	if _current_model:
		_current_model.queue_free()
		_current_model = null
	
	var path = _models[index]
	status_label.text = "Loading: " + path
	
	var packed_scene = load(path) as PackedScene
	if packed_scene:
		_current_model = packed_scene.instantiate()
		model_container.add_child(_current_model)
		_setup_animation_player()
		status_label.text = "Model Loaded: " + path.get_file()
	else:
		status_label.text = "Failed to load model: " + path

func _setup_animation_player() -> void:
	# Find AnimationPlayer in the loaded model
	var model_anim_player = _current_model.find_child("AnimationPlayer", true, false)
	
	anim_selector.clear()
	
	if model_anim_player and model_anim_player is AnimationPlayer:
		# We want to use our OWN animation player or just use the model's
		# Let's just use the model's for now
		animation_player = model_anim_player
		_refresh_animations()
	else:
		status_label.text += " (No AnimationPlayer found)"

func _refresh_animations() -> void:
	anim_selector.clear()
	if not animation_player:
		return
		
	var anim_list = animation_player.get_animation_list()
	for anim_name in anim_list:
		anim_selector.add_item(anim_name)
	
	if anim_list.size() > 0:
		anim_selector.select(0)
		_on_anim_selected(0)

func _on_model_selected(index: int) -> void:
	_load_model(index)

func _on_anim_selected(index: int) -> void:
	var anim_name = anim_selector.get_item_text(index)
	if animation_player:
		animation_player.play(anim_name)

func _on_lib_selected(index: int) -> void:
	if index == 0: # "None"
		return
		
	if not animation_player:
		status_label.text = "Error: No AnimationPlayer found in current model."
		return
		
	var lib_path = _libs[index - 1]
	status_label.text = "Loading Lib: " + lib_path
	
	var lib_scene = load(lib_path) as PackedScene
	if lib_scene:
		var lib_instance = lib_scene.instantiate()
		var lib_anim_player = lib_instance.find_child("AnimationPlayer", true, false)
		if lib_anim_player and lib_anim_player is AnimationPlayer:
			# Import libraries into our current player
			for lib_name in lib_anim_player.get_animation_library_list():
				var library = lib_anim_player.get_animation_library(lib_name)
				var final_lib_name = String(lib_name)
				if final_lib_name == "":
					final_lib_name = lib_path.get_file().get_basename()
				
				if animation_player.has_animation_library(final_lib_name):
					animation_player.remove_animation_library(final_lib_name)
				animation_player.add_animation_library(final_lib_name, library)
				
			_refresh_animations()
			status_label.text = "Lib Loaded: " + lib_path.get_file()
		else:
			status_label.text = "No AnimationPlayer in Lib: " + lib_path.get_file()
		lib_instance.queue_free()
	else:
		status_label.text = "Failed to load lib scene: " + lib_path

func _orbit_camera(delta: Vector2) -> void:
	camera_pivot.rotate_y(-delta.x * _orbit_sensitivity)
	camera_pivot.rotate_object_local(Vector3.RIGHT, -delta.y * _orbit_sensitivity)
	
	# Clamp X rotation to avoid flipping
	var rot = camera_pivot.rotation
	rot.x = clamp(rot.x, deg_to_rad(-89), deg_to_rad(89))
	camera_pivot.rotation = rot

func _pan_camera(delta: Vector2) -> void:
	var forward = -camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	var up = camera.global_transform.basis.y
	
	camera_pivot.global_translate(right * -delta.x * _pan_sensitivity + up * delta.y * _pan_sensitivity)

func _zoom_camera(amount: float) -> void:
	camera.position.z = clamp(camera.position.z + amount, 1.0, 50.0)
