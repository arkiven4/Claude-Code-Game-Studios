# status_effects_system.gd
class_name StatusEffectsSystem
extends Node

## Manages the full lifecycle of status effects on a single character or enemy.

signal effect_applied(effect: ActiveEffect)
signal effect_removed(effect: ActiveEffect)
signal dot_tick_fired(effect: ActiveEffect, damage: int)

var active_effects: Array[ActiveEffect] = []

func _process(delta: float) -> void:
	_tick_effects(delta)

func _tick_effects(delta: float) -> void:
	var to_remove: Array[ActiveEffect] = []
	
	for effect in active_effects:
		effect.tick(delta)
		
		if effect.should_tick():
			_apply_dot_tick(effect)
			effect.reset_tick()
			
		if effect.is_expired():
			to_remove.append(effect)
	
	for effect in to_remove:
		remove_effect(effect.definition.effect_id)

func _apply_dot_tick(effect: ActiveEffect) -> void:
	var category_resistance: float = 1.0
	if get_parent().has_method("get_resistance"):
		category_resistance = get_parent().get_resistance(effect.definition.damage_category)

	## Use effective_value (resolved from skill override) instead of definition.effect_value.
	var base_val := effect.effective_value
	if effect.definition.stacking_rule == StatusEffect.StackingRule.ADDITIVE_STACK:
		base_val *= effect.current_stacks

	var damage := HealthDamageSystem.calculate_dot_damage(base_val, category_resistance)
	dot_tick_fired.emit(effect, damage)

	if get_parent().has_method("take_damage"):
		get_parent().take_damage({"damage": damage, "is_dot": true})

## custom_duration/custom_value/custom_tick: pass -1.0 to use the StatusEffect .tres fallback.
func apply_effect(definition: StatusEffect, applied_by_id: String, tier: int,
		custom_duration: float = -1.0,
		custom_value: float = -1.0,
		custom_tick: float = -1.0) -> void:
	if not definition: return

	# Immunity check
	if get_parent().has_method("is_immune_to_effect"):
		if get_parent().is_immune_to_effect(definition.effect_id):
			return

	var existing: ActiveEffect = null
	for active in active_effects:
		if active.definition.effect_id == definition.effect_id:
			existing = active
			break

	if not existing:
		var new_effect := ActiveEffect.new(definition, applied_by_id, tier, custom_duration, custom_value, custom_tick)
		active_effects.append(new_effect)
		print("[StatusEffectsSystem] Applied effect: ", definition.display_name, " to ", get_parent().name)
		effect_applied.emit(new_effect)
	else:
		match definition.stacking_rule:
			StatusEffect.StackingRule.NO_STACK:
				existing.refresh_duration()
			StatusEffect.StackingRule.ADDITIVE_STACK:
				existing.add_stack()
			StatusEffect.StackingRule.DURATION_STACK:
				existing.add_stack()
				existing.extend_duration()

func remove_effect(effect_id: String) -> void:
	for i in range(active_effects.size()):
		if active_effects[i].definition.effect_id == effect_id:
			var removed := active_effects[i]
			active_effects.remove_at(i)
			effect_removed.emit(removed)
			return

func dispel_all(hostile_only: bool) -> void:
	var to_remove: Array[ActiveEffect] = []
	for effect in active_effects:
		if effect.definition.dispellable and effect.definition.is_hostile == hostile_only:
			to_remove.append(effect)
			
	for effect in to_remove:
		remove_effect(effect.definition.effect_id)

func clear_all_effects() -> void:
	var ids: Array[String] = []
	for effect in active_effects:
		ids.append(effect.definition.effect_id)
	for effect_id in ids:
		remove_effect(effect_id)
