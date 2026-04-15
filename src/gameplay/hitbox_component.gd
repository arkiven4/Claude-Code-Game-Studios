# hitbox_component.gd
class_name HitboxComponent
extends Area3D

## Performs overlap queries to find HurtboxComponents in range during its active window.

signal hit_landed(hurtbox: HurtboxComponent)

@export var target_layer: int = 1

var _is_active: bool = false
var _damage_data: Dictionary = {}
var _hit_targets: Array[HurtboxComponent] = []
var _current_skill: SkillData = null

func _ready() -> void:
	monitoring = false
	monitorable = false
	
	# Set collision mask based on target layer
	# Layer 2 = Party Hurtboxes (enemies hitting players)
	# Layer 8 = Enemy Hurtboxes (players hitting enemies)
	if target_layer == 2:
		collision_mask = 2  # Hit party members
		#print("[HitboxComponent] %s: Set collision_mask to 2 (hit Party)" % name)
	elif target_layer == 8:
		collision_mask = 8  # Hit enemies
		#print("[HitboxComponent] %s: Set collision_mask to 8 (hit Enemy)" % name)

func activate(damage_data: Dictionary, skill: SkillData = null) -> void:
	_is_active = true
	_damage_data = damage_data
	_current_skill = skill
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
				
				# Hitstop / Impact Feel
				_apply_hitstop(0.05) # 50ms freeze
				#print("[HitboxComponent] Hit %s" % hurtbox.get_parent().name)

func _apply_hitstop(duration: float) -> void:
	Engine.time_scale = 0.05 # Near freeze
	await get_tree().create_timer(duration, true, false, true).timeout # process_always=true, process_in_physics=true
	Engine.time_scale = 1.0

