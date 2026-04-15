# training_dummy.gd
extends CharacterBody3D

## A dummy for testing skills, damage, and status effects.
## Has infinite health and tracks DPS.

@onready var status_effects_system: StatusEffectsSystem = $StatusEffectsSystem
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var anim_tree: AnimationTree = _find_animation_tree()

func _find_animation_tree() -> AnimationTree:
	var at = get_node_or_null("AnimationTree")
	if at is AnimationTree: return at
	
	# Deep search if not found directly
	for child in get_children():
		if child is AnimationTree: return child
		for subchild in child.get_children():
			if subchild is AnimationTree: return subchild
	return null

var total_damage_received: int = 0
var last_damage_received: int = 0
var damage_history: Array[Dictionary] = [] # { "time": float, "damage": int }
var dps: float = 0.0
var tracking_start_time: float = 0.0
var is_tracking: bool = false

signal stats_updated(total: int, last: int, dps: float)

@export var is_ally: bool = false
@export var max_hp: int = 1000
@export var current_hp: int = 500

func _ready() -> void:
	if is_ally:
		add_to_group("PartyMembers")
		# Layer 9 is Party Hurtbox
		hurtbox.collision_layer = 9
	else:
		add_to_group("Enemies")
		# Layer 8 is Enemy Hurtbox
		hurtbox.collision_layer = 8

func _process(delta: float) -> void:
	if is_tracking:
		_update_dps()

func take_damage(data: Dictionary) -> void:
	var amount: int = data.get("damage", 0)
	if amount <= 0: return

	if not is_tracking:
		is_tracking = true
		tracking_start_time = Time.get_ticks_msec() / 1000.0
		total_damage_received = 0
		damage_history.clear()

	total_damage_received += amount
	last_damage_received = amount
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	damage_history.append({"time": current_time, "damage": amount})
	
	_update_dps()
	stats_updated.emit(total_damage_received, last_damage_received, dps)
	
	# Play hit animation
	_play_hit_anim()

	# Show floating damage number if the system exists
	if has_node("FloatingDamageNumberSpawn"):
		# Implementation depends on how floating numbers are handled
		pass

func apply_heal(data: Dictionary) -> void:
	var amount: int = data.get("heal_amount", 0)
	print("[TrainingDummy] Received heal: %d" % amount)
	
	current_hp = min(max_hp, current_hp + amount)
	
	# Feedback flash (green-ish)
	CombatFeedbackManager.hit_flash(self, 0.2)
	
	# Emit update so UI can show it if needed (though UI usually shows damage)
	stats_updated.emit(total_damage_received, amount, dps)

func _play_hit_anim() -> void:
	if not anim_tree: return
	
	# Priority 1: StateMachine playback (Standard KayKit/L2M)
	var playback = anim_tree.get("parameters/playback")
	if not playback: playback = anim_tree.get("parameters/StateMachine/playback")
	if not playback: playback = anim_tree.get("parameters/MainStateMachine/playback")
	
	if playback and playback is AnimationNodeStateMachinePlayback:
		playback.travel("general_Hit_A")
		return

	# Priority 2: Direct Conditions
	if anim_tree.get("parameters/conditions/hit") != null:
		anim_tree.set("parameters/conditions/hit", true)
		get_tree().create_timer(0.1).timeout.connect(func(): anim_tree.set("parameters/conditions/hit", false))
		return
		
	# Priority 3: OneShot request
	if anim_tree.get("parameters/HitOneShot/request") != null:
		anim_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		return

	# Log parameters to help debug if all failed
	print("[TrainingDummy] Hit anim fail. Params: ", anim_tree.get_property_list().filter(func(p): return p.name.begins_with("parameters/")).map(func(p): return p.name))
	
	# Fallback: AnimationPlayer
	var anim_player: AnimationPlayer = anim_tree.get_node(anim_tree.anim_player)
	if anim_player and anim_player.has_animation("general_Hit_A"):
		anim_player.play("general_Hit_A")

func _update_dps() -> void:
	if damage_history.is_empty():
		dps = 0.0
		return
	
	var current_time: float = Time.get_ticks_msec() / 1000.0
	var window_start: float = current_time - 5.0 # 5 second sliding window
	
	var window_damage: int = 0
	var i: int = damage_history.size() - 1
	while i >= 0 and damage_history[i].time >= window_start:
		window_damage += damage_history[i].damage
		i -= 1
	
	# Remove old history
	if i > 0:
		damage_history = damage_history.slice(i + 1)
	
	var duration: float = min(5.0, current_time - tracking_start_time)
	if duration > 0.1:
		dps = window_damage / duration
	else:
		dps = float(window_damage)

func reset_stats() -> void:
	total_damage_received = 0
	last_damage_received = 0
	damage_history.clear()
	dps = 0.0
	is_tracking = false
	current_hp = max_hp / 2
	stats_updated.emit(0, 0, 0.0)
	if status_effects_system:
		status_effects_system.clear_all_effects()

func get_resistance(_category: int) -> float:
	return 1.0 # Neutral resistance

func get_hp_ratio() -> float:
	return 0.5 # Prioritize for heals in sandbox

func get_effective_def() -> int:
	var base: int = 10
	var mods: Dictionary = status_effects_system.get_stat_modifier(StatusEffect.StatToModify.DEF) if status_effects_system else {"multiplier": 1.0, "flat": 0.0}
	return int(base * mods.multiplier + mods.flat)

func is_alive() -> bool:
	return true

func is_immune_to_effect(_id: String) -> bool:
	return false
