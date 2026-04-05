# hitbox_component.gd
class_name HitboxComponent
extends Area3D

## Performs overlap queries to find HurtboxComponents in range during its active window.

signal hit_landed(hurtbox: HurtboxComponent)

@export var target_layer: int = 1

var _is_active: bool = false
var _damage_data: Dictionary = {}
var _hit_targets: Array[HurtboxComponent] = []

func _ready() -> void:
	monitoring = false
	monitorable = false

func activate(damage_data: Dictionary) -> void:
	_is_active = true
	_damage_data = damage_data
	_hit_targets.clear()
	monitoring = true

func deactivate() -> void:
	_is_active = false
	monitoring = false

func _physics_process(_delta: float) -> void:
	if not _is_active:
		return
		
	var overlapping_areas := get_overlapping_areas()
	for area in overlapping_areas:
		if area is HurtboxComponent:
			var hurtbox := area as HurtboxComponent
			if hurtbox.is_alive() and not hurtbox in _hit_targets:
				hurtbox.take_hit(_damage_data)
				_hit_targets.append(hurtbox)
				hit_landed.emit(hurtbox)
				print("[HitboxComponent] Hit %s" % hurtbox.get_parent().name)
