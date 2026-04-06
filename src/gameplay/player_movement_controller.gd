# player_movement_controller.gd
class_name PlayerMovementController
extends Node

## Reads move input and translates the currently player-controlled character.

@export var input_manager: InputManager
@export var switch_controller: CharacterSwitchController
@export var move_speed: float = 5.0
@export var dodge_multiplier: float = 3.0
@export var dodge_duration: float = 0.35

var _move_input: Vector2 = Vector2.ZERO
var _is_dodging: bool = false
var _dodge_timer: float = 0.0
var _dodge_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	if input_manager:
		input_manager.move_direction.connect(_on_move_direction)

func _on_move_direction(dir: Vector2) -> void:
	_move_input = dir

func _physics_process(delta: float) -> void:
	if not switch_controller: return
	
	var current := switch_controller.current_character
	if not current or not current.is_alive: return
	
	var character_node := current.get_parent() as CharacterBody3D
	if not character_node: return
	
	if _is_dodging:
		_dodge_timer -= delta
		if _dodge_timer <= 0.0:
			_is_dodging = false
			current.set_invincible(false)
			## Clear invincibility from StatusEffectsSystem
			var effects_node: Node = current.get_parent().get_node_or_null("StatusEffectsSystem")
			if effects_node and effects_node.has_method("remove_effect"):
				effects_node.remove_effect("invincibility")
		else:
			var dodge_speed: float = move_speed
			## Check for movement impair during dodge (reduced dodge distance when slowed)
			var effects_node: Node = current.get_parent().get_node_or_null("StatusEffectsSystem")
			if effects_node:
				for active_effect in effects_node.active_effects:
					var def: StatusEffect = active_effect.definition
					if def and def.effect_category == StatusEffect.EffectCategory.MOVEMENT_IMPAIR:
						dodge_speed *= active_effect.effective_value
			character_node.velocity.x = _dodge_dir.x * dodge_speed * dodge_multiplier
			character_node.velocity.z = _dodge_dir.z * dodge_speed * dodge_multiplier
			character_node.move_and_slide()
			return

	# Calculate movement relative to camera (fallback to world axes if camera unavailable)
	var camera := get_viewport().get_camera_3d()
	var forward: Vector3
	var right: Vector3
	if camera:
		forward = -camera.global_transform.basis.z
		right = camera.global_transform.basis.x
	else:
		forward = Vector3(0, 0, 1)
		right = Vector3(1, 0, 0)
	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()
	
	var move_dir := (forward * -_move_input.y + right * _move_input.x).normalized()

	## Check for stun (ACTION_DENIAL) — freeze movement and input
	var effects_node: Node = current.get_parent().get_node_or_null("StatusEffectsSystem")
	var is_stunned: bool = false
	if effects_node:
		for active_effect in effects_node.active_effects:
			var def: StatusEffect = active_effect.definition
			if def and def.effect_category == StatusEffect.EffectCategory.ACTION_DENIAL:
				is_stunned = true
				break
	if is_stunned:
		character_node.velocity.x = move_toward(character_node.velocity.x, 0, move_speed * 10.0 * delta)
		character_node.velocity.z = move_toward(character_node.velocity.z, 0, move_speed * 10.0 * delta)
		character_node.move_and_slide()
		return

	## Block movement during cast — character must stand still while channeling
	if current.is_casting:
		character_node.velocity.x = move_toward(character_node.velocity.x, 0, move_speed * 10.0 * delta)
		character_node.velocity.z = move_toward(character_node.velocity.z, 0, move_speed * 10.0 * delta)
		character_node.move_and_slide()
		return

	## Apply movement slow from active MOVEMENT_IMPAIR effects.
	var effective_speed: float = move_speed
	if effects_node:
		for active_effect in effects_node.active_effects:
			var def: StatusEffect = active_effect.definition
			if def and def.effect_category == StatusEffect.EffectCategory.MOVEMENT_IMPAIR:
				effective_speed *= active_effect.effective_value  ## 0.5 = 50% speed

	# Apply movement velocity
	var target_velocity := move_dir * effective_speed
	character_node.velocity.x = target_velocity.x
	character_node.velocity.z = target_velocity.z

	# Apply gravity
	if not character_node.is_on_floor():
		character_node.velocity += character_node.get_gravity() * delta

	if move_dir.length() > 0.01:
		# Rotate toward movement
		var target_basis := Basis.looking_at(move_dir, Vector3.UP)
		character_node.basis = character_node.basis.slerp(target_basis, 10.0 * delta)
	else:
		character_node.velocity.x = move_toward(character_node.velocity.x, 0, effective_speed * 10.0 * delta)
		character_node.velocity.z = move_toward(character_node.velocity.z, 0, effective_speed * 10.0 * delta)
		
	character_node.move_and_slide()

## Triggers a dodge/dash for the current character.
func dodge() -> void:
	if _is_dodging: return
	if not switch_controller: return

	var current := switch_controller.current_character
	if not current or not current.is_alive: return
	if current.is_casting: return

	var character_node := current.get_parent() as CharacterBody3D
	if not character_node: return

	# Try consume MP
	if not current.try_consume_dodge_mp():
		return

	_is_dodging = true
	_dodge_timer = dodge_duration
	current.set_invincible(true)

	## Apply through StatusEffectsSystem so it shows in HUD/world indicator
	## Duration matches the dodge dash duration
	var sfx := current.get_parent().get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
	if sfx:
		var inv_def := preload("res://assets/data/status_effects/invincibility.tres")
		sfx.apply_effect(inv_def, "dodge", 1, dodge_duration)

	# Dodge in current move direction, or forward if standing still
	if character_node.velocity.length() > 0.1:
		_dodge_dir = character_node.velocity.normalized()
	else:
		_dodge_dir = -character_node.global_transform.basis.z
