class_name CharacterStateManager
extends Node

@export var health_system: NodePath
@export var status_effects: NodePath
@export var skill_executor: NodePath

var _health_system: PartyMemberState
var _status_effects: StatusEffectsSystem
var _skill_executor: SkillExecutionSystem

func _ready() -> void:
	if health_system: _health_system = get_node(health_system) as PartyMemberState
	if status_effects: _status_effects = get_node(status_effects)
	if skill_executor: _skill_executor = get_node(skill_executor)

func capture_snapshot() -> Dictionary:
	return {
		"hp": _health_system.current_hp if _health_system else 0.0,
		"mp": _health_system.current_mp if _health_system else 0.0,
		"is_alive": _health_system.is_alive if _health_system else false,
		"effects": _capture_effects(),
		"cooldowns": _skill_executor.get_all_cooldowns() if _skill_executor else {},
	}

func restore_from_snapshot(snapshot: Dictionary) -> void:
	if _health_system:
		_health_system.current_hp = snapshot.get("hp", 0.0)
		_health_system.current_mp = snapshot.get("mp", 0.0)
		_health_system.is_alive = snapshot.get("is_alive", false)
		_health_system.health_changed.emit(_health_system.current_hp, _health_system.character_data.max_hp)
	if _skill_executor:
		_skill_executor.restore_cooldowns(snapshot.get("cooldowns", {}))

func _capture_effects() -> Array:
	if not _status_effects:
		return []
	var result: Array = []
	for effect in _status_effects.get_active_effects():
		result.append({
			"effect_id": effect.effect_data.effect_id,
			"remaining": effect.remaining_duration,
			"stacks": effect.stacks,
		})
	return result
