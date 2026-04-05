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
var _timer: float = 0.0

func initialize(damage: int, caster_id: String, hit_enemies: bool = true, hit_allies: bool = false) -> void:
	_damage = damage
	_caster_id = caster_id
	_hit_enemies = hit_enemies
	_hit_allies = hit_allies
	_timer = 0.0

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
			queue_free()

func _on_body_entered(body: Node) -> void:
	# Hit environment
	if body.is_in_group("Environment") or body is StaticBody3D:
		queue_free()
