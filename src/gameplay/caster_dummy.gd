# caster_dummy.gd
extends CharacterBody3D

## A dummy for the Skill Sandbox that mimics player behavior.
## Supports buffs, stuns, and basic player systems.

@onready var status_effects: StatusEffectsSystem = $StatusEffectsSystem
@onready var party_member_state: PartyMemberState = $PartyMemberState

func _ready() -> void:
	# Connect to status effects system for visual feedback on certain effects
	if status_effects:
		status_effects.effect_applied.connect(_on_effect_applied)
		status_effects.effect_removed.connect(_on_effect_removed)

func take_damage(data: Dictionary) -> void:
	if party_member_state:
		party_member_state.take_damage(data)

func _on_effect_applied(_effect: ActiveEffect) -> void:
	pass

func _on_effect_removed(_effect: ActiveEffect) -> void:
	pass

# --- Interface for SkillExecutionSystem and PartyMemberState ---

func is_alive() -> bool:
	return party_member_state.is_alive if party_member_state else true

func get_hp_ratio() -> float:
	return party_member_state.get_hp_ratio() if party_member_state else 1.0

func get_effective_def() -> int:
	return party_member_state.get_effective_def() if party_member_state else 10
