# slash_vfx.gd
extends Node3D

## Automatically triggers all child GPUParticles3D and frees itself when done.

@export var max_lifetime: float = 1.0

func _ready() -> void:
    for child in get_children():
        if child is GPUParticles3D:
            child.emitting = true
            child.restart()
    
    get_tree().create_timer(max_lifetime).timeout.connect(queue_free)
