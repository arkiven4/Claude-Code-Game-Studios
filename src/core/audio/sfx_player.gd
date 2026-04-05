# sfx_player.gd
class_name SFXPlayer
extends Node

## Manages pooled AudioStreamPlayer3D nodes and handles SFX prioritization.

@export var event_channel: AudioEventChannel
@export var pool_size: int = 20

var _pool: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	for i in range(pool_size):
		var player := AudioStreamPlayer3D.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	
	if event_channel:
		event_channel.sfx_requested.connect(play_sfx)

func play_sfx(clip: AudioStream, bus_name: String = "SFX", priority: int = 1) -> void:
	var available_player := _get_available_player()
	
	if available_player == null:
		# Pool exhausted - in Unity higher numerical value was lower priority.
		# Here we'll just take the one that's been playing longest if we had timestamps,
		# but for now let's just find one and replace if priority is higher (lower value).
		# Simplified: just find any player and restart it if pool is full.
		available_player = _pool[0] # Very simple fallback
	
	available_player.stream = clip
	available_player.bus = bus_name
	# Godot AudioStreamPlayer3D doesn't have a built-in 'priority' property like Unity,
	# but we can store it in metadata if we want to implement advanced culling.
	available_player.set_meta("priority", priority)
	available_player.play()

func _get_available_player() -> AudioStreamPlayer3D:
	for player in _pool:
		if not player.playing:
			return player
	return null

func play_one_shot(clip: AudioStream, bus_name: String = "SFX", priority: int = 1) -> void:
	play_sfx(clip, bus_name, priority)
