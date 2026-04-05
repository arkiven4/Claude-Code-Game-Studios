# audio_event_channel.gd
class_name AudioEventChannel
extends Resource

## SO Channel for audio events. Used to decouple systems from the AudioManager.

signal music_crossfade_requested(clip: AudioStream, duration: float)
signal sfx_requested(clip: AudioStream, bus_name: String, priority: int)

func request_music_crossfade(clip: AudioStream, duration: float = 1.5) -> void:
	music_crossfade_requested.emit(clip, duration)

func request_sfx(clip: AudioStream, bus_name: String = "SFX", priority: int = 1) -> void:
	sfx_requested.emit(clip, bus_name, priority)
