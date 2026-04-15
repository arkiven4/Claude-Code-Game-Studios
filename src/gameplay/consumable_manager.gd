# consumable_manager.gd
class_name ConsumableManager
extends Node

## Static utility for using consumable items.

static func use_consumable(item: ItemConsumable, target: Node) -> bool:
	if not item or not target:
		return false
		
	var success = false
	
	# Handle multiple effects per item
	for effect in item.effects:
		if _apply_effect(effect, target):
			success = true
			
	return success

static func _apply_effect(effect: ItemEffect, target: Node) -> bool:
	var state = target.get_node_or_null("PartyMemberState") as PartyMemberState
	if not state:
		return false
		
	# Skip healing/buffing dead characters unless it's a revive effect (not yet in ItemEffect)
	if not state.is_alive:
		return false
		
	match effect.type:
		ItemEffect.EffectType.HEAL_HP_FLAT:
			state.apply_heal(int(effect.value))
			return true
			
		ItemEffect.EffectType.HEAL_HP_PERCENT:
			var heal_amount = int(state.max_hp * (effect.value / 100.0))
			state.apply_heal(heal_amount)
			return true
			
		ItemEffect.EffectType.RESTORE_MP_FLAT:
			state.restore_mp(int(effect.value))
			return true
			
		ItemEffect.EffectType.RESTORE_MP_PERCENT:
			var mp_amount = int(state.max_mp * (effect.value / 100.0))
			state.restore_mp(mp_amount)
			return true
			
		ItemEffect.EffectType.APPLY_STATUS_EFFECT:
			var sfx_system = target.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
			if sfx_system and effect.status_effect:
				sfx_system.apply_effect(effect.status_effect, "consumable", 1)
				return true
				
		ItemEffect.EffectType.REMOVE_STATUS_EFFECT:
			var sfx_system = target.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
			if sfx_system:
				# We might need a more granular removal, but for now we clear by category if matching
				_remove_effects_by_category(sfx_system, effect.effect_category)
				return true
				
		ItemEffect.EffectType.GRANT_EXP:
			# If we have a progression system, apply it here
			if state.has_method("add_exp"):
				state.call("add_exp", int(effect.value))
				return true
				
	return false

static func _remove_effects_by_category(sfx_system: StatusEffectsSystem, category: StatusEffect.EffectCategory) -> void:
	var to_remove: Array[String] = []
	for effect in sfx_system.active_effects:
		if effect.definition.effect_category == category:
			to_remove.append(effect.definition.effect_id)
			
	for id in to_remove:
		sfx_system.remove_effect(id)
