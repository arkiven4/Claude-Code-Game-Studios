# item_effect.gd
class_name ItemEffect
extends Resource

## Defines a specific effect applied by a consumable or item.

enum EffectType { 
	HEAL_HP_FLAT, 
	HEAL_HP_PERCENT, 
	RESTORE_MP_FLAT, 
	RESTORE_MP_PERCENT, 
	APPLY_STATUS_EFFECT,
	REMOVE_STATUS_EFFECT,
	TELEPORT_HOME,
	GRANT_EXP
}

@export var type: EffectType = EffectType.HEAL_HP_FLAT
@export var value: float = 0.0
## If type is APPLY_STATUS_EFFECT, this must be assigned.
@export var status_effect: StatusEffect
## If type is REMOVE_STATUS_EFFECT, this category is cleared.
@export var effect_category: StatusEffect.EffectCategory = StatusEffect.EffectCategory.ACTION_DENIAL
