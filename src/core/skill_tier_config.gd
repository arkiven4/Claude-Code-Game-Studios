# skill_tier_config.gd
class_name SkillTierConfig
extends Resource

## Configuration for a specific skill tier (Tier 1, 2, or 3).

@export var effect_value: float = 0.0
@export var effect_value_secondary: float = 0.0
@export var target_count: int = 1
@export var area_radius: float = 0.0
@export var duration: float = 0.0
@export_multiline var tier_description: String = ""
