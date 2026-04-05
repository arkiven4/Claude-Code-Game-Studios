# skill_data.gd
class_name SkillData
extends Resource

## Base skill definition. All fields are read-only at runtime.

enum SkillType { DAMAGE, STATUS, SUPPORT, UTILITY }
enum TargetType { SINGLE_ENEMY, MULTI_ENEMY_LINE, MULTI_ENEMY_CONE, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF }
enum DamageCategory { PHYSICAL, MAGICAL, HOLY, DARK }

@export_group("Common Fields")
@export var skill_type: SkillType = SkillType.DAMAGE
@export var display_name: String = ""
@export var skill_id: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var animation_name: String = "" # Replaces Unity AnimationClip
@export var audio_cue: AudioStream # Replaces Unity AudioClip

@export_group("Common Stats")
@export var mp_cost: int = 10
@export var base_cooldown: float = 5.0
@export var max_charges: int = 1

@export_group("Targeting")
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var target_count: int = 1
@export var area_radius: float = 0.0

@export_group("Tiers")
## Configuration for each of the 3 tiers.
@export var tiers: Array[SkillTierConfig] = []

# --- Specific Variant Fields ---

@export_group("Damage Fields")
@export var base_damage: int = 0
@export var damage_category: DamageCategory = DamageCategory.PHYSICAL
@export var applied_status_effect: StatusEffect # Needs status_effect.gd

@export_group("Status Fields")
@export var effects_to_apply: Array[StatusEffect] = []

@export_group("Support Fields")
@export var base_heal: int = 0
@export var bonus_percent: float = 0.0
@export var is_revive: bool = false
@export var target_max_hp_bonus: float = 0.0

@export_group("Utility Fields")
@export var mp_restore_amount: int = 0
@export var shield_value: int = 0
@export var grants_invincibility: bool = false
@export var invincibility_duration: float = 0.0
