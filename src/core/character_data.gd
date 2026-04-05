# character_data.gd
class_name CharacterData
extends Resource

## Master definition for a playable character. Contains base stats, per-level
## growth rates, skill slot references, and narrative metadata.
## This asset is strictly read-only at runtime.

enum CharacterClass { SWORDMAN, MAGE, ASSASSIN, HEALER, TANKER, SUPPORT, ARCHER }

# Tier Thresholds
const TIER_2_LEVEL: int = 8
const TIER_3_LEVEL: int = 18
const LEVEL_CAP: int = 30

# Identity / Narrative
@export_group("Identity")
@export var character_class: CharacterClass = CharacterClass.SWORDMAN
@export var display_name: String = ""
@export var portrait_sprite: Texture2D
@export_multiline var role_description: String = ""
@export var is_main_character: bool = false

# Base Stats at Level 1
@export_group("Base Stats (Level 1)")
@export var base_max_hp: int = 100
@export var base_atk: int = 10
@export var base_def: int = 5
@export var base_spd: float = 1.0
@export var base_max_mp: int = 50
@export_range(0.0, 1.0) var base_crit: float = 0.05

# Growth Rates (applied each level from L2 to L30)
@export_group("Growth Rates")
@export var hp_per_level: int = 12
@export var atk_per_level: int = 5
@export var def_per_level: int = 1
@export var mp_per_level: int = 5

# Main Character Per-Level Bonuses
@export_group("Main Character Bonuses")
@export var main_char_hp_bonus: int = 0
@export var main_char_atk_bonus: int = 0
@export var main_char_def_bonus: int = 0
@export var main_char_mp_bonus: int = 0

# Skill Slots
@export_group("Skills")
## The four skill slots for this character (index 0-3).
@export var skill_slots: Array[SkillData] = [null, null, null, null]

@export_group("Combat Actions")
## Dedicated basic attack (Left Click).
@export var basic_attack: SkillData
## Dedicated special attack (Right Click).
@export var special_attack: SkillData
## MP cost for dodging/dashing.
@export var dodge_mp_cost: int = 15

# Stat Computation

## Returns MaxHP at the given character level.
func get_max_hp_at_level(level: int) -> int:
	var gain := hp_per_level + (main_char_hp_bonus if is_main_character else 0)
	return base_max_hp + gain * (level - 1)

## Returns ATK at the given character level.
func get_atk_at_level(level: int) -> int:
	var gain := atk_per_level + (main_char_atk_bonus if is_main_character else 0)
	return base_atk + gain * (level - 1)

## Returns DEF at the given character level.
func get_def_at_level(level: int) -> int:
	var gain := def_per_level + (main_char_def_bonus if is_main_character else 0)
	return base_def + gain * (level - 1)

## Returns MaxMP at the given character level.
func get_max_mp_at_level(level: int) -> int:
	var gain := mp_per_level + (main_char_mp_bonus if is_main_character else 0)
	return base_max_mp + gain * (level - 1)

## Returns the active skill tier for the given character level.
func get_active_tier(level: int) -> int:
	if level >= TIER_3_LEVEL: return 3
	if level >= TIER_2_LEVEL: return 2
	return 1
