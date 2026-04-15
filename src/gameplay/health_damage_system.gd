# health_damage_system.gd
class_name HealthDamageSystem
extends Object

## Static utility class for all damage and heal math.

# Tuning Knobs
const CRITICAL_MULTIPLIER: float = 1.5
const REVIVE_HP_PERCENT: float = 0.25
const HEALTHY_THRESHOLD: float = 0.5
const CRITICAL_THRESHOLD: float = 0.1
const MINIMUM_DAMAGE: int = 1

## If false, calculate_damage will skip the +/- 10% random variance (useful for unit tests).
static var use_variance: bool = true

## Calculates final damage for a skill hit.
## Formula:
##   RawDamage = (casterATK * 0.5 + skillBaseDamage) * effectValue * critMultiplier
##   AfterDef = RawDamage - targetDEF
##   FinalDamage = max(1, floor(AfterDef * categoryResistance))
static func calculate_damage(
	caster_atk: int,
	skill_base_damage: int,
	effect_value: float,
	target_def: int,
	category_resistance: float,
	crit_chance: float
) -> Dictionary:
	var was_crit := randf() <= crit_chance
	var crit_mult := CRITICAL_MULTIPLIER if was_crit else 1.0
	
	var raw_damage: float = (caster_atk * 0.5 + skill_base_damage) * effect_value * crit_mult
	
	# Add +/- 10% variance (skip if use_variance is false)
	if use_variance:
		var variance := randf_range(0.9, 1.1)
		raw_damage *= variance
	
	var after_def: float = raw_damage - target_def
	var after_category: float = after_def * category_resistance
	
	var final_damage: int = max(MINIMUM_DAMAGE, floor(after_category))
	
	return {
		"damage": final_damage,
		"was_crit": was_crit
	}

## Calculates the effective heal amount for a support skill.
## Formula:
##   HealAmount = (casterMaxMP * 0.1 + skillBaseHeal) * effectValue + (targetMaxHP * bonusPercent)
##   ActualHeal = min(HealAmount, targetMaxHP - targetCurrentHP)
static func calculate_heal(
	caster_max_mp: int,
	skill_base_heal: int,
	effect_value: float,
	target_max_hp: int,
	bonus_percent: float,
	target_current_hp: int
) -> Dictionary:
	var heal_amount: float = (caster_max_mp * 0.1 + skill_base_heal) * effect_value + (target_max_hp * bonus_percent)
	var max_healable: int = max(0, target_max_hp - target_current_hp)
	var final_heal: int = int(min(floor(heal_amount), max_healable))
	return {
		"heal_amount": final_heal
	}

## Calculates the damage dealt by a single DoT tick.
## Formula: floor(effect_value * category_resistance)
static func calculate_dot_damage(effect_value: float, category_resistance: float) -> int:
	return max(MINIMUM_DAMAGE, floor(effect_value * category_resistance))
