## Controls a layered impact VFX effect with multiple particle systems.
##
## This script manages the playback of impact visual effects composed of
## multiple layered particle systems (flash, flare, shockwave, sparks).
## It provides methods to trigger, stop, and configure the VFX at runtime.
##
## @tutorial: Based on "GODOT VFX - Hits and Impacts Effect Tutorial"
##   The effect layers are:
##   - Flash: Quick bright burst (0.1s, single particle)
##   - Flare: Cross-shaped glow (0.2s, camera-facing)
##   - Shockwave: Expanding ring (0.4s, low alpha)
##   - Sparks: Velocity-aligned particles (20 particles, 0.5s)

extends Node3D
class_name ImpactVFXController

## Emitted when the VFX has finished playing all layers.
signal vfx_completed

# Layer references
@onready var flash: Node3D = $Flash
@onready var flare: Node3D = $Flare
@onready var shockwave: Node3D = $Shockwave
@onready var sparks: Node3D = $Sparks

# Layer configuration
@export_group("Layer Configuration")
## Enable/disable the flash layer
@export var enable_flash: bool = true
## Enable/disable the flare layer
@export var enable_flare: bool = true
## Enable/disable the shockwave layer
@export var enable_shockwave: bool = true
## Enable/disable the sparks layer
@export var enable_sparks: bool = true

# Color customization
@export_group("Color Settings")
## Tint color for all layers
@export var tint_color: Color = Color.WHITE
## Flash layer color
@export var flash_color: Color = Color(1.0, 0.6, 0.2)
## Flare layer color
@export var flare_color: Color = Color(1.0, 0.6, 0.1)
## Shockwave layer color
@export var shockwave_color: Color = Color(1.0, 0.8, 0.3)
## Sparks layer color
@export var sparks_color: Color = Color(1.0, 0.3, 0.2)

# Scale multipliers
@export_group("Scale Settings")
## Global scale multiplier for the entire VFX
@export var global_scale: float = 1.0
## Flash layer scale multiplier
@export var flash_scale: float = 1.0
## Flare layer scale multiplier
@export var flare_scale: float = 1.0
## Shockwave layer scale multiplier
@export var shockwave_scale: float = 1.0
## Sparks layer scale multiplier
@export var sparks_scale: float = 1.0

# Internal state
var _is_playing: bool = false
var _max_lifetime: float = 0.5  # Longest layer lifetime
var _elapsed_time: float = 0.0


## Plays the impact VFX.
## 
## @param position: World position to play the effect at (optional, uses current position if not provided)
## @param custom_color: Optional tint color override for all layers
func play(position: Vector3 = Vector3.ZERO, custom_color: Color = Color.WHITE) -> void:
	if position != Vector3.ZERO:
		global_position = position
	
	# Apply colors and visibility to layers
	_configure_layer(flash, enable_flash, flash_color if custom_color == Color.WHITE else custom_color, flash_scale)
	_configure_layer(flare, enable_flare, flare_color if custom_color == Color.WHITE else custom_color, flare_scale)
	_configure_layer(shockwave, enable_shockwave, shockwave_color if custom_color == Color.WHITE else custom_color, shockwave_scale)
	_configure_layer(sparks, enable_sparks, sparks_color if custom_color == Color.WHITE else custom_color, sparks_scale)
	
	# Reset state
	_is_playing = true
	_elapsed_time = 0.0
	
	# Trigger all particle systems
	_emit_particles(flash, enable_flash)
	_emit_particles(flare, enable_flare)
	_emit_particles(shockwave, enable_shockwave)
	_emit_particles(sparks, enable_sparks)


## Stops the VFX playback immediately.
func stop() -> void:
	_is_playing = false
	_stop_particles()


## Returns true if the VFX is currently playing.
func is_playing() -> bool:
	return _is_playing


func _configure_layer(layer: Node3D, enabled: bool, color: Color, scale_mult: float) -> void:
	layer.visible = enabled
	if enabled:
		layer.scale = Vector3.ONE * global_scale * scale_mult
		# Apply color to the material
		for child in layer.get_children():
			if child is GPUParticles3D:
				# Make material unique to avoid affecting other instances
				if child.material_override:
					child.material_override = child.material_override.duplicate()
					if child.material_override is ShaderMaterial:
						child.material_override.set_shader_parameter("modulate", color)

func _emit_particles(layer: Node3D, enabled: bool) -> void:
	if not enabled:
		return
	
	for child in layer.get_children():
		if child is GPUParticles3D:
			child.emitting = true
			child.restart()


func _stop_particles() -> void:
	for layer in [flash, flare, shockwave, sparks]:
		for child in layer.get_children():
			if child is GPUParticles3D:
				child.emitting = false


func _process(delta: float) -> void:
	if not _is_playing:
		return
	
	_elapsed_time += delta
	
	# Check if all layers have finished
	if _elapsed_time >= _max_lifetime:
		_is_playing = false
		vfx_completed.emit()
		queue_free()  # Auto-cleanup after completion
