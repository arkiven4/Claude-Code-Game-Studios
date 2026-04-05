# music_player.gd
class_name MusicPlayer
extends Node

## Handles music playback with crossfading between two AudioStreamPlayer nodes.

@export var event_channel: AudioEventChannel

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _current_player: AudioStreamPlayer
var _tween: Tween

func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = "Music"
	add_child(_player_a)
	
	_player_b = AudioStreamPlayer.new()
	_player_b.bus = "Music"
	add_child(_player_b)
	
	_current_player = _player_a
	
	if event_channel:
		event_channel.music_crossfade_requested.connect(play)

func play(clip: AudioStream, duration: float = 1.5) -> void:
	if _tween:
		_tween.kill()
	
	var incoming_player := _player_b if _current_player == _player_a else _player_a
	
	if clip == null:
		# Stop case
		_fade_out_current(duration)
		return
		
	if incoming_player.stream == clip and incoming_player.playing:
		return # Already playing
		
	incoming_player.stream = clip
	incoming_player.volume_db = -80.0
	incoming_player.play()
	
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_current_player, "volume_db", -80.0, duration)
	_tween.tween_property(incoming_player, "volume_db", 0.0, duration)
	
	_tween.chain().step_finished.connect(func(_idx): _on_crossfade_complete(incoming_player))

func _fade_out_current(duration: float) -> void:
	_tween = create_tween()
	_tween.tween_property(_current_player, "volume_db", -80.0, duration)
	_tween.finished.connect(_current_player.stop)

func _on_crossfade_complete(new_player: AudioStreamPlayer) -> void:
	_current_player.stop()
	_current_player = new_player

func stop(duration: float = 1.5) -> void:
	play(null, duration)
