# skill_effect_override.gd
class_name SkillEffectOverride
extends Resource

## Pairs a StatusEffect with skill-specific runtime values.
## The StatusEffect .tres defines identity, type, and stacking rules only.
## All numeric values (how long, how strong, how fast) live here in the skill config.

@export var effect_ref: StatusEffect

@export_group("Override Values")
## Duration in seconds. 0 = resolved from tier_config.duration, then StatusEffect.duration fallback.
@export var duration: float = 0.0
## Effect magnitude: slow multiplier (0.5 = 50% speed), DoT damage, stat modifier amount.
## 0 = use StatusEffect.effect_value fallback.
@export var effect_value: float = 0.0
## DoT tick interval in seconds. 0 = use StatusEffect.tick_interval fallback.
@export var tick_interval: float = 0.0
