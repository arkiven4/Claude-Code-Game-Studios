# input_manager.gd
class_name InputManager
extends Node

## Wraps the Godot InputMap and exposes signals for game actions.
## Implements an input buffer for responsive combat.

# Exploration Signals
signal move_direction(dir: Vector2)
signal interact_pressed
signal camera_orbit(dir: Vector2)
signal pause_pressed
signal inventory_pressed

# Combat Signals
signal skill_pressed(index: int)
signal switch_next_pressed
signal switch_prev_pressed
signal dodge_pressed
signal basic_attack_pressed
signal special_attack_pressed
signal target_lock_pressed

# UI Signals
signal navigate_direction(dir: Vector2)
signal confirm_pressed
signal cancel_pressed

const BUFFER_WINDOW: float = 0.15
var _input_buffer: Array[Dictionary] = []

var is_exploration_enabled: bool = true
var is_combat_enabled: bool = true
var is_ui_enabled: bool = false

func _process(delta: float) -> void:
	_update_buffered_inputs(delta)
	
	if is_exploration_enabled or is_combat_enabled:
		var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		move_direction.emit(move_dir)
		
		var orbit_dir := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		camera_orbit.emit(orbit_dir)

func _input(event: InputEvent) -> void:
	if is_ui_enabled:
		_handle_ui_input(event)
		return
		
	if is_exploration_enabled:
		_handle_exploration_input(event)
		
	if is_combat_enabled:
		_handle_combat_input(event)

func _handle_exploration_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
	elif event.is_action_pressed("pause"):
		pause_pressed.emit()
	elif event.is_action_pressed("inventory"):
		inventory_pressed.emit()

func _handle_combat_input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_1"):
		_buffer_input(func(): skill_pressed.emit(0))
	elif event.is_action_pressed("skill_2"):
		_buffer_input(func(): skill_pressed.emit(1))
	elif event.is_action_pressed("skill_3"):
		_buffer_input(func(): skill_pressed.emit(2))
	elif event.is_action_pressed("skill_4"):
		_buffer_input(func(): skill_pressed.emit(3))
	elif event.is_action_pressed("dodge") or event.is_action_pressed("roll"):
		_buffer_input(func(): dodge_pressed.emit())
	elif event.is_action_pressed("basic_attack"):
		_buffer_input(func(): basic_attack_pressed.emit())
	elif event.is_action_pressed("special_attack"):
		_buffer_input(func(): special_attack_pressed.emit())
	elif event.is_action_pressed("switch_next"):
		switch_next_pressed.emit()
	elif event.is_action_pressed("switch_prev"):
		switch_prev_pressed.emit()
	elif event.is_action_pressed("target_lock"):
		target_lock_pressed.emit()
	elif event.is_action_pressed("inventory"):
		inventory_pressed.emit()

func _handle_ui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		confirm_pressed.emit()
	elif event.is_action_pressed("ui_cancel"):
		cancel_pressed.emit()
	
	var nav_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if nav_dir != Vector2.ZERO:
		navigate_direction.emit(nav_dir)

func _buffer_input(action: Callable) -> void:
	# Trigger immediately for high responsiveness
	action.call()
	
	_input_buffer.append({
		"action": action,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})

func _update_buffered_inputs(_delta: float) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var i := 0
	while i < _input_buffer.size():
		if current_time - _input_buffer[i].timestamp > BUFFER_WINDOW:
			_input_buffer.remove_at(i)
		else:
			i += 1

func flush_buffer() -> void:
	for input in _input_buffer:
		input.action.call()
	_input_buffer.clear()

func clear_buffer() -> void:
	_input_buffer.clear()

func set_input_mode(exploration: bool, combat: bool, ui: bool) -> void:
	is_exploration_enabled = exploration
	is_combat_enabled = combat
	is_ui_enabled = ui
	clear_buffer()
