# enemy_data.gd
class_name EnemyData
extends Resource

## Master definition for an enemy type. Contains base stats, resistances,
## immunities, skill list, behavior profile, and visual references.

enum EnemyClass { GRUNT, ELITE, MINI_BOSS, BOSS }
enum EnemyBehaviorProfile { AGGRESSIVE, TACTICAL, DEFENSIVE, BOSS }
enum DamageCategory { PHYSICAL, MAGICAL, HOLY, DARK }

@export_group("Identity")
@export var enemy_id: String = ""
@export var display_name: String = ""
@export var enemy_class: EnemyClass = EnemyClass.GRUNT
@export var behavior_profile: EnemyBehaviorProfile = EnemyBehaviorProfile.AGGRESSIVE

@export_group("Base Stats")
@export var base_max_hp: int = 100
@export var base_atk: int = 10
@export var base_def: int = 5
@export var base_spd: float = 1.0

@export_group("Damage Resistances")
# 1.0 = neutral, 0.5 = resisted, 1.5 = weak, 2.0 = critical weakness
@export var physical_resistance: float = 1.0
@export var magical_resistance: float = 1.0
@export var holy_resistance: float = 1.0
@export var dark_resistance: float = 1.0

@export_group("Immunities")
## Status effect IDs this enemy is immune to.
@export var status_immunities: Array[String] = []

@export_group("Skill List")
## All skills this enemy can select from during the decision cycle.
@export var skill_list: Array[EnemySkillEntry] = []

@export_group("Loot")
@export var loot_table: LootTable

@export_group("Death / Phase")
## HP threshold to trigger phase change or death. 0 for standard enemies.
@export var death_threshold: float = 0.0

@export_group("Visual")
@export var model_path: String = "" # Replaces Unity ModelPrefab
@export var portrait_sprite: Texture2D

## Returns the resistance multiplier for the given damage category.
func get_category_resistance(category: DamageCategory) -> float:
	match category:
		DamageCategory.PHYSICAL: return physical_resistance
		DamageCategory.MAGICAL: return magical_resistance
		DamageCategory.HOLY: return holy_resistance
		DamageCategory.DARK: return dark_resistance
		_: return 1.0
