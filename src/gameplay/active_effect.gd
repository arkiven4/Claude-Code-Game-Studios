# active_effect.gd
class_name ActiveEffect
extends RefCounted

## Runtime instance of a status effect currently active on a target.

# Definition
var definition: StatusEffect

# Runtime State
var remaining_duration: float
var current_stacks: int = 1
var time_since_last_tick: float = 0.0

# Tracking
var applied_by_id: String
var applied_tier: int

func _init(def: StatusEffect, by_id: String, tier: int, rem_duration: float = -1.0, stacks: int = 1) -> void:
	definition = def
	applied_by_id = by_id
	applied_tier = tier
	remaining_duration = rem_duration if rem_duration >= 0 else def.duration
	current_stacks = stacks
	time_since_last_tick = 0.0

func tick(delta: float) -> void:
	if definition.duration > 0.0:
		remaining_duration -= delta
	time_since_last_tick += delta

func is_expired() -> bool:
	return remaining_duration <= 0.0 and definition.duration > 0.0

func should_tick() -> bool:
	return definition.effect_type == StatusEffect.EffectType.DOT and \
		time_since_last_tick >= definition.tick_interval and \
		definition.tick_interval > 0.0

func reset_tick() -> void:
	time_since_last_tick = 0.0

func refresh_duration() -> void:
	remaining_duration = definition.duration

func add_stack() -> void:
	if current_stacks < definition.max_stacks:
		current_stacks += 1

func extend_duration() -> void:
	remaining_duration += definition.duration * 0.5
