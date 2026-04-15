# item_consumable.gd
class_name ItemConsumable
extends Resource

## ScriptableObject for consumable items like potions, scrolls, and food.

enum ConsumableType { HEALING, BUFF, SCROLL, MATERIAL, BOX, OTHER }

@export_group("Identity")
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Classification")
@export var type: ConsumableType = ConsumableType.OTHER
@export var is_stackable: bool = true
@export var max_stack: int = 999

@export_group("Effect")
## List of effects applied when consumed.
@export var effects: Array[ItemEffect] = []
@export var target_type: TargetType = TargetType.SINGLE_ALLY

enum TargetType { SINGLE_ALLY, ALL_ALLIES, ACTIVE_ONLY }

@export_group("Requirements & Value")
@export var level_requirement: int = 1
@export var sell_price: int = 10

@export_group("Assets")
@export var icon: Texture2D
