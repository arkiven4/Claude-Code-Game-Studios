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

## Resolved at apply-time from skill override, falling back to StatusEffect definition.
## Use these instead of definition.effect_value / definition.tick_interval.
var effective_value: float = 0.0
var effective_tick_interval: float = 0.0

# Tracking
var applied_by_id: String
var applied_tier: int

## Stored so refresh_duration() can restore to the full amount.
var _full_duration: float = 0.0

## custom_duration/custom_value/custom_tick: pass -1.0 to fall back to definition values.
func _init(def: StatusEffect, by_id: String, tier: int,
		custom_duration: float = -1.0,
		custom_value: float = -1.0,
		custom_tick: float = -1.0) -> void:
	definition = def
	applied_by_id = by_id
	applied_tier = tier
	_full_duration = custom_duration if custom_duration >= 0.0 else def.duration
	remaining_duration = _full_duration
	effective_value = custom_value if custom_value >= 0.0 else def.effect_value
	effective_tick_interval = custom_tick if custom_tick >= 0.0 else def.tick_interval
	current_stacks = 1
	time_since_last_tick = 0.0

func tick(delta: float) -> void:
	if _full_duration > 0.0:
		remaining_duration -= delta
	time_since_last_tick += delta

func is_expired() -> bool:
	## _full_duration == 0 means permanent — never expires.
	return _full_duration > 0.0 and remaining_duration <= 0.0

func should_tick() -> bool:
	return definition.effect_type == StatusEffect.EffectType.DOT and \
		time_since_last_tick >= effective_tick_interval and \
		effective_tick_interval > 0.0

func reset_tick() -> void:
	time_since_last_tick = 0.0

func refresh_duration() -> void:
	remaining_duration = _full_duration

func add_stack() -> void:
	if current_stacks < definition.max_stacks:
		current_stacks += 1

func extend_duration() -> void:
	remaining_duration += _full_duration * 0.5
