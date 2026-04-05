# enemy_skill_entry.gd
class_name EnemySkillEntry
extends Resource

## Defines which skill the enemy can use and its selection parameters.

enum SkillCondition { ALWAYS, TARGET_BELOW_HP_50, TARGET_BELOW_HP_25, ENEMY_BELOW_HP_50, ENEMY_BELOW_HP_25, TARGET_HAS_BUFF, TARGET_IS_STUNNED, PHASE_2_ONLY, ENRAGE_PHASE }

@export var skill_ref: SkillData
@export var cooldown: float = 5.0
@export var weight: float = 1.0
@export var min_range: float = 0.0
@export var max_range: float = 10.0
@export var condition: SkillCondition = SkillCondition.ALWAYS
