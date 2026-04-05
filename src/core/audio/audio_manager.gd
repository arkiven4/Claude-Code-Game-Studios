# audio_manager.gd
class_name AudioManager
extends Node

## Manages volume settings and mixer bus parameters using AudioServer.

@export var event_channel: AudioEventChannel

## Sets the volume for a specific audio bus.
## Converts linear 0-1 value to decibels.
func set_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Audio bus not found: %s" % bus_name)
		return
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)

func get_volume(bus_name: String) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))

func mute(is_muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, is_muted)

## Fades a bus volume to -80dB over duration.
func fade_out(bus_name: String, duration: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	var start_db := AudioServer.get_bus_volume_db(bus_index)
	var tween := create_tween()
	tween.tween_method(
		func(db: float): AudioServer.set_bus_volume_db(bus_index, db),
		start_db,
		-80.0,
		duration
	)

## Fades a bus volume from -80dB to target_linear over duration.
func fade_in(bus_name: String, duration: float, target_linear: float = 1.0) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1: return
	var target_db := linear_to_db(target_linear)
	AudioServer.set_bus_volume_db(bus_index, -80.0)
	var tween := create_tween()
	tween.tween_method(
		func(db: float): AudioServer.set_bus_volume_db(bus_index, db),
		-80.0,
		target_db,
		duration
	)

func crossfade_music(new_clip: AudioStream, duration: float) -> void:
	if event_channel:
		event_channel.request_music_crossfade(new_clip, duration)
