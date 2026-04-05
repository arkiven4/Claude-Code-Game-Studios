# projectile.gd
class_name Projectile
extends Area3D

## Moves in a straight line and hits targets via HurtboxComponent.

@export var speed: float = 20.0
@export var lifetime: float = 3.0

var _damage: int = 0
var _caster_id: String = ""
var _hit_enemies: bool = true
var _hit_allies: bool = false
var _effect_overrides: Array[SkillEffectOverride] = []
var _timer: float = 0.0

func initialize(damage: int, caster_id: String, hit_enemies: bool = true, hit_allies: bool = false, overrides: Array[SkillEffectOverride] = []) -> void:
	_damage = damage
	_caster_id = caster_id
	_hit_enemies = hit_enemies
	_hit_allies = hit_allies
	_effect_overrides = overrides
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
		queue_free()
		return
		
	var movement := -global_transform.basis.z * speed * delta
	global_position += movement

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		# Logic to filter enemies/allies
		var parent := hurtbox.get_parent()
		var is_enemy := parent is EnemyAIController
		var is_party := parent.is_in_group("PartyMembers")

		if (is_enemy and _hit_enemies) or (is_party and _hit_allies):
			hurtbox.take_hit({"damage": _damage, "is_projectile": true})
			_apply_effects_on_hit(parent)
			queue_free()

func _on_body_entered(body: Node) -> void:
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
