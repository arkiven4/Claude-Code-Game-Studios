# projectile.gd
class_name Projectile
extends Area3D

## Moves in a straight line and hits targets via HurtboxComponent.

signal hit(target: Node)
signal missed(target: Node)

@export var speed: float = 20.0
@export var lifetime: float = 3.0

var _damage: int = 0
var _caster_id: String = ""
var _skill_name: String = ""
var _hit_enemies: bool = true
var _hit_allies: bool = false
var _effect_overrides: Array[SkillEffectOverride] = []
var _timer: float = 0.0
var _vfx_impact: Texture2D = null
var _hit_targets: Array[Node] = []
var _target: Node = null # The intended target (if any) to track for misses/dodges

func initialize(damage_data, caster_id: String, hit_enemies: bool = true, hit_allies: bool = false, overrides: Array[SkillEffectOverride] = [], impact_texture: Texture2D = null, skill_name: String = "Projectile", target: Node = null) -> void:
	if damage_data is Dictionary:
		_damage = int(damage_data.get("damage", 0))
		# If dict contains names, use them, otherwise use defaults
		_caster_id = damage_data.get("caster_name", caster_id)
		_skill_name = damage_data.get("skill_name", skill_name)
	else:
		_damage = int(damage_data)
		_caster_id = caster_id
		_skill_name = skill_name
		
	_hit_enemies = hit_enemies
	_hit_allies = hit_allies
	_effect_overrides = overrides
	_vfx_impact = impact_texture
	_target = target
	_timer = 0.0

## Sets a skill-specific VFX texture on the Sprite3D billboard.
## Uses additive blending so the black background becomes transparent.
## Hides the generic fallback mesh when a texture is provided.
func set_vfx(texture: Texture2D) -> void:
	if not texture:
		return
	var sprite := get_node_or_null("VFXSprite") as Sprite3D
	var fallback := get_node_or_null("FallbackMesh") as MeshInstance3D
	if sprite:
		# Set texture on the node so Sprite3D knows the quad dimensions.
		# pixel_size: 0.002 px/unit → 512px texture ≈ 1 world unit wide
		sprite.texture = texture
		sprite.pixel_size = 0.002
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = texture
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sprite.material_override = mat
		sprite.visible = true
	if fallback:
		fallback.visible = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		if _target and is_instance_valid(_target):
			# If the target is still alive and we haven't hit anything, it's a miss/dodge
			missed.emit(_target)
		queue_free()
		return
		
	var movement := -global_transform.basis.z * speed * delta
	global_position += movement

	# Look at movement direction if speed is not zero.
	# Flatten to the XZ plane first — projectiles travel horizontally in this
	# game, and a (near-)vertical forward vector would be colinear with UP and
	# trigger a Basis.looking_at warning.
	if speed > 0 and movement.length() > 0.001:
		var flat_dir := Vector3(movement.x, 0.0, movement.z)
		if flat_dir.length_squared() > 0.0001:
			look_at(global_position + flat_dir, Vector3.UP)
func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent

		# Prevent hitting self
		if hurtbox.get_parent().name == _caster_id:
			return

		# Logic to filter enemies/allies
		var target := hurtbox.get_parent()
		var is_enemy := target is EnemyAIController or target.is_in_group("Enemies")

		# Check if target or any parent is in PartyMembers group
		var is_party := false
		var check_node: Node = target
		while check_node and check_node != get_tree().root:
			if check_node.is_in_group("PartyMembers"):
				is_party = true
				break
			check_node = check_node.get_parent()

		if (is_enemy and _hit_enemies) or (is_party and _hit_allies):
			# Access the authoritative state node (PartyMemberState or EnemyAIController)
			var state_node: Node = hurtbox.parent_node if hurtbox.parent_node else target

			# Prevent hitting the same target twice
			if state_node in _hit_targets:
				return

			# CRITICAL FIX: Check if target is invincible BEFORE applying damage
			var can_damage: bool = true
			if state_node.get("is_invincible") == true:
				can_damage = false

			if can_damage:
				hurtbox.take_hit({
					"damage": _damage, 
					"is_projectile": true,
					"caster_name": _caster_id,
					"skill_name": _skill_name
				})
				_apply_effects_on_hit(target)
				_hit_targets.append(state_node)
				hit.emit(state_node)
				_target = null # Clear target so we don't emit missed signal
			else:
				pass
				#print("[Projectile] Hit blocked by invincibility/dodge on: ", state_node.name)

			# Always spawn impact VFX and destroy projectile on hit, even if dodged
			if _vfx_impact:
				CombatSkillExecutor.spawn_hit_vfx(get_tree(), global_position, _vfx_impact)

			queue_free()
func _on_body_entered(body: Node) -> void:
	# Grace period to prevent hitting floor at spawn
	if _timer < 0.05:
		return
		
	# Hit environment
	if body.is_in_group("Environment") or body is StaticBody3D:
		queue_free()

func _apply_effects_on_hit(target: Node) -> void:
	if _effect_overrides.is_empty(): return
	var sfx: StatusEffectsSystem = target.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
	if not sfx: return
	for override in _effect_overrides:
		if not override or not override.effect_ref: continue
		var dur: float = override.duration if override.duration > 0.0 else -1.0
		var val: float = override.effect_value if override.effect_value > 0.0 else -1.0
		var tick: float = override.tick_interval if override.tick_interval > 0.0 else -1.0
		sfx.apply_effect(override.effect_ref, _caster_id, 1, dur, val, tick)
