# status_effect.gd
class_name StatusEffect
extends Resource

## Defines a status effect that can be applied to characters or enemies.
## All fields are read-only at runtime.

enum EffectType { BUFF, DEBUFF, DOT, CROWD_CONTROL, SHIELD }
enum EffectCategory { STAT_MODIFIER, DAMAGE_OVER_TIME, MOVEMENT_IMPAIR, ACTION_DENIAL, DAMAGE_ABSORPTION }
enum StatToModify { NONE, ATK, DEF, SPD, MAX_HP, MAX_MP, CRIT }
enum ModifyType { PERCENTAGE, FLAT }
enum StackingRule { NO_STACK, ADDITIVE_STACK, DURATION_STACK }
enum DamageCategory { PHYSICAL, MAGICAL, HOLY, DARK }

@export_group("Identity")
@export var effect_id: String = ""
@export var display_name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""

@export_group("Classification")
@export var effect_type: EffectType = EffectType.BUFF
@export var effect_category: EffectCategory = EffectCategory.STAT_MODIFIER

@export_group("Stat Modification")
@export var stat_to_modify: StatToModify = StatToModify.NONE
@export var modify_type: ModifyType = ModifyType.PERCENTAGE
@export var effect_value: float = 0.0

@export_group("Timing")
@export var duration: float = 5.0
@export var tick_interval: float = 0.0

@export_group("Damage Over Time")
@export var damage_category: DamageCategory = DamageCategory.PHYSICAL
@export var can_crit: bool = false

@export_group("Stacking")
@export var stacking_rule: StackingRule = StackingRule.NO_STACK
@export var max_stacks: int = 1

@export_group("Interaction Flags")
@export var dispellable: bool = true
@export var is_hostile: bool = false

@export_group("Audio / Visual")
@export var vfx_path: String = "" # Replaces Unity GameObject VFX
@export var apply_audio_cue: AudioStream
@export var remove_audio_cue: AudioStream
