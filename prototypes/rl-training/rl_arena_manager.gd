# rl_arena_manager.gd
# Root script for TrainingArena.tscn.
# Handles: episode resets, movement execution, directive routing, reward wiring.
extends Node3D

@export var evan_body_path: NodePath
@export var evelyn_body_path: NodePath
@export var enemy_container_path: NodePath

@export var move_speed: float = 4.0
@export var arena_half_size: float = 30.0  ## Boundary penalty starts if |x| or |z| exceeds this (60x60 platform)

## Dash params — matches player_movement_controller.gd for consistent feel
@export var dash_multiplier: float = 3.0    ## velocity multiplier during dash
@export var dash_duration: float = 0.35     ## seconds of dash + invincibility

## Stagnation penalty: steps of no damage before penalty fires (90 = ~1.5s at 60 FPS)
## Raised from 60 to give the kite retreat window (60 steps) breathing room to
## complete a hit -> retreat -> hit cycle before stagnation fires.
@export var stagnation_threshold: int = 90
## Penalty applied to team reward and each party agent per step while stagnating
@export var w_stagnation: float = 0.002
## Penalty per step for being outside the arena platform
@export var w_boundary_penalty: float = 0.05

## Safety-net cap on episode length (physics steps). NOT a pacing knob —
## legitimate hit-and-run fights are expected to run 5–6 min (18k–21.6k steps).
## 28800 steps = 8 min @ 60 FPS, ~33% above the longest real fight, so only
## genuinely stuck episodes (corner camp, infinite kite, mutual disengage) hit
## it. Treated as a loss to discourage stalling. Prevents the RLlib sampler
## buffer from growing unbounded when a policy learns a non-terminating pattern.
@export var max_episode_steps: int = 28800

@export_group("Curriculum Scheduler")
## Enable automatic episode length scaling based on rolling win rate
@export var curriculum_enabled: bool = false
## Episodes required before the scheduler checks for the first stage advance
@export var curriculum_min_episodes: int = 20
## Fallback rolling window size — overridden per-stage by "eval_window" in _CURRICULUM_STAGES
@export var curriculum_eval_window: int = 100

var evan_body: CharacterBody3D
var evelyn_body: CharacterBody3D
var enemy_container: Node3D

@onready var _evan_agent: RLPartyAgent
@onready var _evelyn_agent: RLPartyAgent
@onready var _evan_state: PartyMemberState
@onready var _evelyn_state: PartyMemberState
@onready var _team_agent: RLTeamAgent = $TeamAI

var _initial_evan_pos: Vector3
var _initial_evelyn_pos: Vector3

var _enemies: Array[EnemyAIController] = []
var _hive_agents: Array[RLEnemyHiveAgent] = []
var _episode_step: int = 0
var _episode_active: bool = false
## Stagnation tracking — party (for stagnation penalty only)
var _steps_since_last_damage: int = 0
var _damage_dealt_this_step: bool = false

## Stagnation tracking — enemies (for stagnation penalty only)
var _enemy_steps_since_last_damage: int = 0
var _enemy_damage_dealt_this_step: bool = false

## Hit and Dodge tracking
var _evan_last_hit_step: int = -1000
var _evelyn_last_hit_step: int = -1000
var _evan_took_damage_since_hit: bool = false
var _evelyn_took_damage_since_hit: bool = false
var _episode_damage_dealt: float = 0.0
var _episode_damage_received: float = 0.0

## Kite ("hit-and-run") tracking — delta-based distance shaping + loop completion bonus
var _evan_prev_enemy_dist: float = 0.0
var _evelyn_prev_enemy_dist: float = 0.0
var _evan_kite_ready: bool = false
var _evelyn_kite_ready: bool = false

## Dash state — keyed by body instance id so movement routine can be generic.
## { body_id: float timer_seconds } / { body_id: Vector3 dir }
## Also tracks last non-dash move direction so a "dash with no input" defaults
## to the agent's previous intent (matches player dodge semantics).
var _dash_timers: Dictionary = {}
var _dash_dirs: Dictionary = {}
var _last_move_dirs: Dictionary = {}

## Long-term statistics
var _total_episodes: int = 0
var _party_wins: int = 0
var _enemy_wins: int = 0  ## party wiped (not timeout, not victory)

## Curriculum state
var _curriculum_stage: int = 0
var _recent_results: Array[float] = []  ## rolling window: damage_dealt/total_enemy_max_hp per episode
var _total_enemy_max_hp: float = 0.0    ## set at episode start; used to compute progress ratio

## Stage definitions:
const _CURRICULUM_STAGES: Array = [
	{"advance_at": 0.10, "eval_window": 20,  "label": "Stage 1  (Early)"},
	{"advance_at": 0.15, "eval_window": 20,  "label": "Stage 2"},
	{"advance_at": 0.20, "eval_window": 30,  "label": "Stage 3"},
	{"advance_at": 0.25, "eval_window": 30,  "label": "Stage 4"},
	{"advance_at": 0.30, "eval_window": 40,  "label": "Stage 5"},
	{"advance_at": 0.35, "eval_window": 40,  "label": "Stage 6"},
	{"advance_at": 0.40, "eval_window": 50,  "label": "Stage 7"},
	{"advance_at": 0.45, "eval_window": 50,  "label": "Stage 8"},
	{"advance_at": 0.50, "eval_window": 75,  "label": "Stage 9"},
	{"advance_at": 0.55, "eval_window": 75,  "label": "Stage 10"},
	{"advance_at": 0.62, "eval_window": 100, "label": "Stage 11"},
	{"advance_at": 0.68, "eval_window": 100, "label": "Stage 12"},
	{"advance_at":  1.1, "eval_window": 100, "label": "Stage 13 (Final)"},
]

func _ready() -> void:
	evan_body   = get_node_or_null(evan_body_path)   as CharacterBody3D
	evelyn_body = get_node_or_null(evelyn_body_path) as CharacterBody3D
	enemy_container = get_node_or_null(enemy_container_path) as Node3D

	if evan_body:
		_evan_agent = evan_body.get_node_or_null("RLPartyAgent")
		_evan_state = evan_body.get_node_or_null("PartyMemberState")
		_initial_evan_pos = evan_body.global_position
	if evelyn_body:
		_evelyn_agent = evelyn_body.get_node_or_null("RLPartyAgent")
		_evelyn_state = evelyn_body.get_node_or_null("PartyMemberState")
		_initial_evelyn_pos = evelyn_body.global_position

	if _evan_state:   _evan_state.death.connect(_on_party_member_died)
	if _evelyn_state: _evelyn_state.death.connect(_on_party_member_died)
	if _evan_agent and _evan_agent.skill_execution:
		_evan_agent.skill_execution.damage_dealt.connect(_on_party_agent_damage_dealt.bind(_evan_agent))
		_evan_agent.skill_execution.projectile_spawned.connect(_on_party_projectile_spawned)
	if _evelyn_agent and _evelyn_agent.skill_execution:
		_evelyn_agent.skill_execution.damage_dealt.connect(_on_party_agent_damage_dealt.bind(_evelyn_agent))
		_evelyn_agent.skill_execution.projectile_spawned.connect(_on_party_projectile_spawned)

	_find_enemies()
	_update_all_contexts()

func _physics_process(delta: float) -> void:
	if _evan_agent and _evan_agent.needs_reset:
		_reset_episode()
		return

	if not _episode_active:
		return

	_episode_step += 1

	if _episode_step >= max_episode_steps:
		_end_episode(false)
		return

	if _team_agent:
		if _evan_agent:   _evan_agent.set_directive(_team_agent.evan_target, _team_agent.evan_role)
		if _evelyn_agent: _evelyn_agent.set_directive(_team_agent.evelyn_target, _team_agent.evelyn_role)

	_execute_party_movement(delta)
	_execute_enemy_movement(delta)

	var alive_ratio: float = _get_alive_party_ratio()
	if _team_agent:
		_team_agent.add_survival_reward(alive_ratio)

	_check_stagnation_penalty()
	_check_enemy_stagnation_penalty()
	_check_protection_bonus()
	_check_tank_priority()
	_check_enemy_focus_fire()
	_check_enemy_positioning()
	_check_party_spacing()
	_check_flawless_hits()
	_check_arena_boundaries()
	_check_victory_or_defeat()
	_update_hud()

# --- Enemy Discovery ---

func _find_enemies() -> void:
	if not enemy_container:
		return
	for child in enemy_container.get_children():
		if not child is RLEnemyController:
			continue
		var enemy := child as RLEnemyController
		var hive: RLEnemyHiveAgent = enemy.get_node_or_null("RLEnemyHiveAgent") as RLEnemyHiveAgent
		if not hive:
			continue
		enemy.died.connect(_on_enemy_died.bind(enemy, hive))
		enemy.damage_dealt.connect(_on_enemy_damage_dealt)
		enemy.attack_missed.connect(_on_enemy_attack_missed)
		enemy.projectile_spawned.connect(_on_enemy_projectile_spawned)
		hive.enemy_controller = enemy
		_enemies.append(enemy)
		_hive_agents.append(hive)
		var candidates: Array[Node3D] = []
		if evan_body: candidates.append(evan_body)
		if evelyn_body: candidates.append(evelyn_body)
		enemy.set_rl_party_candidates(candidates)

# --- Movement Execution ---

func _execute_party_movement(delta: float) -> void:
	_execute_agent_movement(evan_body, _evan_agent, delta)
	_execute_agent_movement(evelyn_body, _evelyn_agent, delta)

func _execute_agent_movement(body: CharacterBody3D, agent: RLPartyAgent, delta: float) -> void:
	if not body or not agent or not agent.state or not agent.state.is_alive:
		if body:
			body.velocity.x = 0.0
			body.velocity.z = 0.0
			if not body.is_on_floor():
				body.velocity += body.get_gravity() * delta
			body.move_and_slide()
		return

	var body_id: int = body.get_instance_id()

	# --- Dash tick: if currently dashing, override movement with boosted velocity ---
	var dash_timer: float = _dash_timers.get(body_id, 0.0)
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			# Dash finished — clear invincibility and tracking.
			_dash_timers.erase(body_id)
			_dash_dirs.erase(body_id)
			agent.state.set_invincible(false)
			var sfx_end: Node = body.get_node_or_null("StatusEffectsSystem")
			if sfx_end and sfx_end.has_method("remove_effect"):
				sfx_end.remove_effect("invincibility")
		else:
			_dash_timers[body_id] = dash_timer
			var dash_dir: Vector3 = _dash_dirs.get(body_id, Vector3.ZERO)
			body.velocity.x = dash_dir.x * move_speed * dash_multiplier
			body.velocity.z = dash_dir.z * move_speed * dash_multiplier
			if not body.is_on_floor():
				body.velocity += body.get_gravity() * delta
			body.move_and_slide()
			return  ## Skip normal movement while dashing

	# --- Dash start: the agent requested a dash this step ---
	if agent.pending_dash_request:
		agent.pending_dash_request = false
		## Dash direction = last non-dash movement intent, or retreat-from-nearest
		## if the agent has been idle (avoids dashing into enemies by default).
		var start_dir: Vector3 = _last_move_dirs.get(body_id, Vector3.ZERO)
		if start_dir.length_squared() < 0.0001:
			var enemies_for_dash: Array = agent._context.get("enemies", [])
			var nearest: Vector3 = _nearest_enemy_pos(body.global_position, enemies_for_dash)
			if nearest != Vector3.ZERO:
				start_dir = (body.global_position - nearest)
				start_dir.y = 0.0
				if start_dir.length_squared() > 0.0001:
					start_dir = start_dir.normalized()
			else:
				start_dir = -body.global_transform.basis.z  ## forward fallback
				start_dir.y = 0.0
				start_dir = start_dir.normalized()
		_dash_timers[body_id] = dash_duration
		_dash_dirs[body_id] = start_dir
		agent.state.set_invincible(true)
		var sfx_start: Node = body.get_node_or_null("StatusEffectsSystem")
		if sfx_start and sfx_start.has_method("apply_effect"):
			var inv_def: StatusEffect = load("res://assets/data/status_effects/invincibility.tres") as StatusEffect
			if inv_def:
				sfx_start.apply_effect(inv_def, "dodge", 1, dash_duration)
		body.velocity.x = start_dir.x * move_speed * dash_multiplier
		body.velocity.z = start_dir.z * move_speed * dash_multiplier
		if not body.is_on_floor():
			body.velocity += body.get_gravity() * delta
		body.move_and_slide()
		return

	var move_dir: Vector3 = Vector3.ZERO
	var enemies: Array = agent._context.get("enemies", [])

	match agent.pending_move_action:
		5:
			var target_idx: int = agent.directive_target
			if target_idx < enemies.size() and is_instance_valid(enemies[target_idx]) and enemies[target_idx].is_alive:
				move_dir = (enemies[target_idx].global_position - body.global_position)
			else:
				move_dir = _toward_nearest_enemy(body.global_position, enemies)
		6:
			var nearest: Vector3 = _nearest_enemy_pos(body.global_position, enemies)
			if nearest != Vector3.ZERO:
				move_dir = (body.global_position - nearest)
		7:
			var ally_body: CharacterBody3D = _lowest_hp_ally_body(body)
			if ally_body:
				move_dir = (ally_body.global_position - body.global_position)
		8:
			move_dir = Vector3.ZERO
		# 8-way cardinal movement in world-space XZ plane.
		# 11=N (+Z), 13=E (+X), 15=S (-Z), 17=W (-X). Diagonals normalised
		# to unit length so cardinal and diagonal moves travel the same speed.
		11: move_dir = Vector3( 0.0, 0.0,  1.0)                   # N
		12: move_dir = Vector3( 1.0, 0.0,  1.0).normalized()      # NE
		13: move_dir = Vector3( 1.0, 0.0,  0.0)                   # E
		14: move_dir = Vector3( 1.0, 0.0, -1.0).normalized()      # SE
		15: move_dir = Vector3( 0.0, 0.0, -1.0)                   # S
		16: move_dir = Vector3(-1.0, 0.0, -1.0).normalized()      # SW
		17: move_dir = Vector3(-1.0, 0.0,  0.0)                   # W
		18: move_dir = Vector3(-1.0, 0.0,  1.0).normalized()      # NW

	move_dir.y = 0.0
	if move_dir.length_squared() > 0.0001:
		move_dir = move_dir.normalized()
		## Remember this as the last-known intent so a future dash action can
		## default to "dash in the direction I was just moving" (matches the
		## player controller's dodge semantics).
		_last_move_dirs[body_id] = move_dir

	body.velocity.x = move_dir.x * move_speed
	body.velocity.z = move_dir.z * move_speed
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta
	body.move_and_slide()

func _execute_enemy_movement(_delta: float) -> void:
	var party_bodies: Array[CharacterBody3D] = []
	if evan_body: party_bodies.append(evan_body)
	if evelyn_body: party_bodies.append(evelyn_body)

	for i in range(_enemies.size()):
		var enemy: EnemyAIController = _enemies[i]
		var hive: RLEnemyHiveAgent = _hive_agents[i] if i < _hive_agents.size() else null
		if not enemy or not is_instance_valid(enemy) or not enemy.is_alive or not hive:
			continue

		var move_dir: Vector3 = Vector3.ZERO
		match hive.pending_move_action:
			3:
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (nearest - enemy.global_position).normalized()
			4:
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (enemy.global_position - nearest).normalized()
			5:
				var target_body: CharacterBody3D = _lowest_hp_alive_party_body(party_bodies)
				if target_body:
					move_dir = (target_body.global_position - enemy.global_position).normalized()
			_:
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					var dist: float = enemy.global_position.distance_to(nearest)
					if dist > enemy.stop_distance:
						move_dir = (nearest - enemy.global_position).normalized()

		if enemy.is_casting():
			enemy.velocity.x = 0.0; enemy.velocity.z = 0.0
			continue

		enemy.velocity.x = move_dir.x * enemy.move_speed
		enemy.velocity.z = move_dir.z * enemy.move_speed

# --- Episode Management ---

func _start_episode() -> void:
	_episode_step = 0
	_update_all_contexts()
	_episode_active = true
	_total_enemy_max_hp = 0.0
	for enemy in _enemies:
		if is_instance_valid(enemy):
			_total_enemy_max_hp += enemy.max_hp

func _end_episode(victory: bool) -> void:
	if not _episode_active: return
	_episode_active = false
	_total_episodes += 1
	if victory:        _party_wins += 1
	else:              _enemy_wins += 1

	## Damage progress tracking runs unconditionally — the HUD reads from
	## _recent_results to display "Avg: X%". Previously gated behind
	## curriculum_enabled, which left the counter locked at 0% when the
	## curriculum was disabled in the Inspector.
	var progress: float = 0.0
	if _total_enemy_max_hp > 0.0:
		var damage_dealt: float = 0.0
		for enemy in _enemies:
			if is_instance_valid(enemy):
				damage_dealt += enemy.max_hp - (enemy.current_hp if enemy.is_alive else 0)
		progress = clampf(damage_dealt / _total_enemy_max_hp, 0.0, 1.0)
	_recent_results.append(progress)
	if _recent_results.size() > curriculum_eval_window: _recent_results.pop_front()
	if curriculum_enabled:
		_update_curriculum()

	if _evan_agent: _evan_agent.done = true
	if _evelyn_agent: _evelyn_agent.done = true
	for hive in _hive_agents:
		if is_instance_valid(hive): hive.done = true

	if _episode_damage_dealt > 0:
		var eff_bonus: float = clampf(log(_episode_damage_dealt / maxf(1.0, _episode_damage_received)) / log(2.0) * 0.1, -0.2, 0.5)
		if _evan_agent: _evan_agent.reward += eff_bonus
		if _evelyn_agent: _evelyn_agent.reward += eff_bonus

	if victory:
		if _team_agent: _team_agent.on_victory()
		for hive in _hive_agents: if is_instance_valid(hive): hive.on_all_enemies_killed()
	else:
		if _team_agent: _team_agent.on_defeat()
		for hive in _hive_agents: if is_instance_valid(hive): hive.on_party_wiped()

func _reset_episode() -> void:
	_steps_since_last_damage = 0; _damage_dealt_this_step = false
	_enemy_steps_since_last_damage = 0; _enemy_damage_dealt_this_step = false
	_evan_last_hit_step = -1000; _evelyn_last_hit_step = -1000
	_evan_took_damage_since_hit = false; _evelyn_took_damage_since_hit = false
	_evan_prev_enemy_dist = 0.0; _evelyn_prev_enemy_dist = 0.0
	_evan_kite_ready = false; _evelyn_kite_ready = false
	_episode_damage_dealt = 0.0; _episode_damage_received = 0.0
	_dash_timers.clear(); _dash_dirs.clear(); _last_move_dirs.clear()
	## Clear any lingering invincibility from a dash that didn't finish before
	## the episode ended.
	for state in [_evan_state, _evelyn_state]:
		if not state: continue
		state.set_invincible(false)
		var sfx: Node = state.get_parent().get_node_or_null("StatusEffectsSystem") if state.get_parent() else null
		if sfx and sfx.has_method("remove_effect"):
			sfx.remove_effect("invincibility")

	if _evan_agent and _evan_agent.skill_execution:   _evan_agent.skill_execution.cancel_cast()
	if _evelyn_agent and _evelyn_agent.skill_execution: _evelyn_agent.skill_execution.cancel_cast()
	if _evan_state:   _evan_state.reset_for_encounter(true)
	if _evelyn_state: _evelyn_state.reset_for_encounter(true)
	if evan_body:   evan_body.global_position   = _initial_evan_pos
	if evelyn_body: evelyn_body.global_position = _initial_evelyn_pos

	for enemy in _enemies:
		if is_instance_valid(enemy): (enemy as RLEnemyController).reset_to_start()

	if _evan_agent:   _evan_agent.reset();   _evan_agent.done = false
	if _evelyn_agent: _evelyn_agent.reset(); _evelyn_agent.done = false
	if _team_agent:   _team_agent.reset();   _team_agent.done = false
	for hive in _hive_agents:
		if is_instance_valid(hive): hive.reset(); hive.done = false

	_update_all_contexts()
	_start_episode()

func _update_curriculum() -> void:
	if not curriculum_enabled: return
	if _curriculum_stage >= _CURRICULUM_STAGES.size() - 1: return
	var stage_def: Dictionary = _CURRICULUM_STAGES[_curriculum_stage]
	var window: int = stage_def.get("eval_window", curriculum_eval_window)
	if _total_episodes < curriculum_min_episodes or _recent_results.size() < window: return
	
	var total: float = 0.0
	for r in _recent_results: total += r
	var avg_progress: float = total / float(_recent_results.size())

	if avg_progress >= stage_def["advance_at"]:
		if _curriculum_stage == 2: # Finished Stage 3 (index 2), jumping to end
			_curriculum_stage = _CURRICULUM_STAGES.size() - 1
		else:
			_curriculum_stage += 1
		
		var new_stage: Dictionary = _CURRICULUM_STAGES[_curriculum_stage]
		_recent_results.clear()
		print("[Curriculum] Advanced to %s" % new_stage["label"])

func _update_all_contexts() -> void:
	if _evan_agent:   _evan_agent.set_context({"enemies": _enemies, "allies": [_evelyn_state]})
	if _evelyn_agent: _evelyn_agent.set_context({"enemies": _enemies, "allies": [_evan_state]})
	if _team_agent:   _team_agent.set_context({"enemies": _enemies})
	for i in range(_hive_agents.size()):
		if is_instance_valid(_hive_agents[i]):
			_hive_agents[i].set_context({"party": [_evan_state, _evelyn_state], "enemy_allies": _enemies})

# --- Reward Logic ---

func _check_stagnation_penalty() -> void:
	if _damage_dealt_this_step:
		_steps_since_last_damage = 0; _damage_dealt_this_step = false
		return
	_steps_since_last_damage += 1
	var any_enemy_alive: bool = false
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive: any_enemy_alive = true; break
	if not any_enemy_alive or _steps_since_last_damage < stagnation_threshold: return
	if _team_agent:   _team_agent.reward -= w_stagnation
	if _evan_agent:   _evan_agent.reward -= w_stagnation
	if _evelyn_agent: _evelyn_agent.reward -= w_stagnation

func _check_enemy_stagnation_penalty() -> void:
	if _enemy_damage_dealt_this_step:
		_enemy_steps_since_last_damage = 0; _enemy_damage_dealt_this_step = false
		return
	_enemy_steps_since_last_damage += 1
	var party_alive: bool = (_evan_state and _evan_state.is_alive) or (_evelyn_state and _evelyn_state.is_alive)
	if not party_alive or _enemy_steps_since_last_damage < stagnation_threshold: return
	for i in range(_hive_agents.size()):
		var hive = _hive_agents[i]
		var enemy = _enemies[i] if i < _enemies.size() else null
		if is_instance_valid(hive) and is_instance_valid(enemy) and enemy.is_alive:
			if enemy.has_method("get_hp_ratio") and enemy.get_hp_ratio() > 0.2:
				hive.reward -= w_stagnation

func _check_protection_bonus() -> void:
	if not _evan_agent or not _evelyn_agent or not evan_body or not evelyn_body: return
	if not _evan_state or not _evan_state.is_alive: return
	for enemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive: continue
		var to_evelyn: Vector3 = (evelyn_body.global_position - enemy.global_position).normalized()
		var to_evan: Vector3 = (evan_body.global_position - enemy.global_position).normalized()
		if to_evan.dot(to_evelyn) > 0.5 and evan_body.global_position.distance_to(enemy.global_position) < evelyn_body.global_position.distance_to(enemy.global_position):
			_evan_agent.on_protection_bonus(); break

func _check_tank_priority() -> void:
	## Tank role: Evan should absorb damage so Evelyn stays ~25% healthier.
	## Per-step shaping reward encouraging the state: evelyn_hp - evan_hp >= 0.25.
	## Only runs when both are alive — a dead mage can't be "protected".
	const TARGET_GAP: float = 0.25   # Evelyn should be 25% healthier than Evan
	const W_TANK_GOOD: float = 0.002 # per-step bonus when gap is healthy
	const W_TANK_BAD: float = 0.002  # per-step penalty when Evelyn is the lower one
	if not _evan_agent or not _evelyn_agent: return
	if not _evan_state or not _evan_state.is_alive: return
	if not _evelyn_state or not _evelyn_state.is_alive: return
	var evan_hp: float = _evan_state.get_hp_ratio()
	var evelyn_hp: float = _evelyn_state.get_hp_ratio()
	var gap: float = evelyn_hp - evan_hp  # positive = Evelyn healthier (desired)
	if gap >= TARGET_GAP:
		# Tank is doing his job — Evelyn is safely ahead.
		_evan_agent.reward += W_TANK_GOOD
	elif gap < 0.0:
		# Evelyn is the one eating damage — tank failed.
		_evan_agent.reward -= W_TANK_BAD
	# Between 0.0 and 0.25: neutral, no shaping either way.

func _check_enemy_focus_fire() -> void:
	var party_bodies: Array[CharacterBody3D] = []
	if evan_body and _evan_state and _evan_state.is_alive: party_bodies.append(evan_body)
	if evelyn_body and _evelyn_state and _evelyn_state.is_alive: party_bodies.append(evelyn_body)
	if party_bodies.is_empty(): return
	const FOCUS_RANGE: float = 5.0
	for target_body in party_bodies:
		var count: int = 0
		for enemy in _enemies:
			if is_instance_valid(enemy) and enemy.is_alive and enemy.global_position.distance_to(target_body.global_position) <= FOCUS_RANGE: count += 1
		if count >= 2:
			for i in range(_hive_agents.size()):
				if is_instance_valid(_hive_agents[i]) and is_instance_valid(_enemies[i]) and _enemies[i].is_alive and _enemies[i].global_position.distance_to(target_body.global_position) <= FOCUS_RANGE:
					_hive_agents[i].on_focus_fire_bonus()
			break

func _check_enemy_positioning() -> void:
	var party_bodies: Array[CharacterBody3D] = []
	if evan_body and _evan_state and _evan_state.is_alive: party_bodies.append(evan_body)
	if evelyn_body and _evelyn_state and _evelyn_state.is_alive: party_bodies.append(evelyn_body)
	if party_bodies.is_empty(): return
	for i in range(_enemies.size()):
		var enemy = _enemies[i]; var hive = _hive_agents[i]
		if not is_instance_valid(enemy) or not enemy.is_alive or not is_instance_valid(hive) or enemy.stop_distance <= 2.5: continue
		var nearest_dist: float = INF
		for pb in party_bodies:
			var d = enemy.global_position.distance_to(pb.global_position)
			if d < nearest_dist: nearest_dist = d
		if nearest_dist < 3.5: hive.reward -= 0.002
		elif nearest_dist >= (enemy.stop_distance - 2.0) and nearest_dist <= (enemy.stop_distance + 4.0): hive.reward += 0.001

func _check_party_spacing() -> void:
	if _evelyn_agent and _evelyn_state and _evelyn_state.is_alive and evelyn_body:
		var nearest = _nearest_enemy_pos(evelyn_body.global_position, _enemies)
		if nearest != Vector3.ZERO:
			var dist = evelyn_body.global_position.distance_to(nearest)
			if dist < 4.5: _evelyn_agent.reward -= 0.002
			elif dist >= 6.0 and dist <= 12.0: _evelyn_agent.reward += 0.001
	if _evan_agent and _evan_state and _evan_state.is_alive and evan_body:
		var nearest = _nearest_enemy_pos(evan_body.global_position, _enemies)
		if nearest != Vector3.ZERO:
			var dist = evan_body.global_position.distance_to(nearest); var hp_ratio = _evan_state.get_hp_ratio()
			## Removed the old high-HP melee-camp reward (+0.001 at dist < 3.0) —
			## it was a steady-state trap that beat the kite delta reward per step
			## and taught Evan to stand in melee instead of hit-and-run.
			## Low-HP logic retained so Evan retreats when hurt.
			if hp_ratio <= 0.5:
				if dist < 4.5: _evan_agent.reward -= 0.003
				elif dist > 7.0: _evan_agent.reward += 0.001

func _check_flawless_hits() -> void:
	## "Hit and run" kite shaping: reward opening distance AFTER landing a hit,
	## then pay a large bonus when the agent lands the NEXT hit from safe range.
	## Teaches: strike → back off → strike again, rather than face-tanking.
	const FLAWLESS_WINDOW: int = 120         # full-avoidance bonus window (preserved)
	const RETREAT_WINDOW: int = 60           # 1s window to open distance after a hit
	## Scaled up from 0.008 → 0.020 / 0.012 so per-step reward at walk speed
	## (~0.067 m/step) exceeds competing per-step shaping rewards (~0.001/step)
	## from party spacing checks. Previous values were being drowned out.
	const DIST_DELTA_REWARD: float = 0.020   # per meter opened
	const DIST_DELTA_PENALTY: float = 0.012  # per meter closed during retreat window
	const SAFE_DIST_EVAN: float = 5.0        # tank can fight closer
	const SAFE_DIST_EVELYN: float = 7.0      # mage needs more room

	# --- Evan ---
	if _evan_agent and _evan_last_hit_step > 0 and evan_body and _evan_state and _evan_state.is_alive:
		var nearest_pos: Vector3 = _nearest_enemy_pos(evan_body.global_position, _enemies)
		if nearest_pos != Vector3.ZERO:
			var dist: float = evan_body.global_position.distance_to(nearest_pos)
			if _episode_step == _evan_last_hit_step + FLAWLESS_WINDOW and not _evan_took_damage_since_hit:
				_evan_agent.reward += 0.2
			if _episode_step <= _evan_last_hit_step + RETREAT_WINDOW and not _evan_took_damage_since_hit:
				if _evan_prev_enemy_dist > 0.0:
					var delta: float = dist - _evan_prev_enemy_dist
					if delta > 0.0:
						_evan_agent.reward += delta * DIST_DELTA_REWARD
					else:
						_evan_agent.reward += delta * DIST_DELTA_PENALTY  # delta negative -> penalty
				if dist >= SAFE_DIST_EVAN:
					_evan_kite_ready = true
			_evan_prev_enemy_dist = dist

	# --- Evelyn ---
	if _evelyn_agent and _evelyn_last_hit_step > 0 and evelyn_body and _evelyn_state and _evelyn_state.is_alive:
		var nearest_pos: Vector3 = _nearest_enemy_pos(evelyn_body.global_position, _enemies)
		if nearest_pos != Vector3.ZERO:
			var dist: float = evelyn_body.global_position.distance_to(nearest_pos)
			if _episode_step == _evelyn_last_hit_step + FLAWLESS_WINDOW and not _evelyn_took_damage_since_hit:
				_evelyn_agent.reward += 0.2
			if _episode_step <= _evelyn_last_hit_step + RETREAT_WINDOW and not _evelyn_took_damage_since_hit:
				if _evelyn_prev_enemy_dist > 0.0:
					var delta: float = dist - _evelyn_prev_enemy_dist
					if delta > 0.0:
						_evelyn_agent.reward += delta * DIST_DELTA_REWARD
					else:
						_evelyn_agent.reward += delta * DIST_DELTA_PENALTY
				if dist >= SAFE_DIST_EVELYN:
					_evelyn_kite_ready = true
			_evelyn_prev_enemy_dist = dist

func _check_arena_boundaries() -> void:
	for body in [evan_body, evelyn_body]:
		if body:
			var rel = body.global_position - global_position
			if abs(rel.x) > arena_half_size or abs(rel.z) > arena_half_size or rel.y < 0.5:
				var agent = body.get_node_or_null("RLPartyAgent")
				if agent: agent.reward -= w_boundary_penalty
	for i in range(_enemies.size()):
		var enemy = _enemies[i]; var hive = _hive_agents[i]
		if is_instance_valid(enemy) and enemy.is_alive and hive:
			var rel = enemy.global_position - global_position
			if abs(rel.x) > arena_half_size or abs(rel.z) > arena_half_size or rel.y < 0.5:
				hive.reward -= w_boundary_penalty

func _check_victory_or_defeat() -> void:
	if not _episode_active: return
	var enemies_dead: bool = true
	for enemy in _enemies: if is_instance_valid(enemy) and enemy.is_alive: enemies_dead = false; break
	if enemies_dead: _end_episode(true); return
	if (not _evan_state or not _evan_state.is_alive) and (not _evelyn_state or not _evelyn_state.is_alive):
		_end_episode(false)

# --- Handlers ---

func _on_party_agent_damage_dealt(amount: int, _target: Node, agent: RLPartyAgent) -> void:
	## Kite loop bonus: if the agent successfully retreated to safe range after their
	## last hit, landing THIS hit completes the hit->run->hit cycle. Pay a large bonus
	## so the policy learns the full sequence, not just the retreat.
	const KITE_LOOP_BONUS: float = 0.1
	_damage_dealt_this_step = true; _episode_damage_dealt += amount
	if agent == _evan_agent:
		if _evan_kite_ready:
			_evan_agent.reward += KITE_LOOP_BONUS
			_evan_kite_ready = false
		_evan_last_hit_step = _episode_step
		_evan_took_damage_since_hit = false
		_evan_prev_enemy_dist = 0.0  # reset baseline for the new retreat window
	elif agent == _evelyn_agent:
		if _evelyn_kite_ready:
			_evelyn_agent.reward += KITE_LOOP_BONUS
			_evelyn_kite_ready = false
		_evelyn_last_hit_step = _episode_step
		_evelyn_took_damage_since_hit = false
		_evelyn_prev_enemy_dist = 0.0

func _on_enemy_damage_dealt(amount: int, target: Node) -> void:
	_enemy_damage_dealt_this_step = true; _episode_damage_received += amount
	if target == _evan_state: _evan_took_damage_since_hit = true
	elif target == _evelyn_state: _evelyn_took_damage_since_hit = true
	if target == _evan_state and _evan_agent: _evan_agent.on_damage_received(amount)
	elif target == _evelyn_state and _evelyn_agent: _evelyn_agent.on_damage_received(amount)

func _on_enemy_attack_missed(target: Node) -> void:
	if target == _evan_state and _evan_agent: _evan_agent.reward += 0.01
	elif target == _evelyn_state and _evelyn_agent: _evelyn_agent.reward += 0.01

func _on_enemy_projectile_spawned(projectile: Projectile) -> void:
	if _evan_agent: projectile.missed.connect(_evan_agent._on_enemy_projectile_missed)
	if _evelyn_agent: projectile.missed.connect(_evelyn_agent._on_enemy_projectile_missed)

func _on_party_projectile_spawned(projectile: Projectile) -> void:
	for hive in _hive_agents: if is_instance_valid(hive): projectile.missed.connect(hive._on_party_projectile_missed)

func _on_enemy_died(enemy: EnemyAIController, hive: RLEnemyHiveAgent) -> void:
	if _team_agent: _team_agent.on_enemy_killed()
	if _evan_agent: _evan_agent.add_team_reward(0.5)
	if _evelyn_agent: _evelyn_agent.add_team_reward(0.5)
	_update_all_contexts()
	_check_victory_or_defeat()

func _on_party_member_died() -> void:
	if _team_agent: _team_agent.on_ally_died()
	for hive in _hive_agents: if is_instance_valid(hive): hive.on_party_member_killed()
	_check_victory_or_defeat()

# --- Stats & HUD ---

func get_stats() -> Dictionary:
	var avg_progress: float = 0.0
	if _recent_results.size() > 0:
		var s: float = 0.0
		for r in _recent_results: s += r
		avg_progress = s / float(_recent_results.size())
	var enemy_reward_sum: float = 0.0; var enemy_reward_count: int = 0
	for i in range(_hive_agents.size()):
		if is_instance_valid(_hive_agents[i]) and is_instance_valid(_enemies[i]) and _enemies[i].is_alive:
			enemy_reward_sum += _hive_agents[i].reward; enemy_reward_count += 1
	var enemies_alive: int = 0
	for enemy in _enemies: if is_instance_valid(enemy) and enemy.is_alive: enemies_alive += 1
	var efficiency: float = _episode_damage_dealt / maxf(1.0, _episode_damage_received)
	return {
		"total_episodes": _total_episodes, "party_wins": _party_wins, "enemy_wins": _enemy_wins,
		"efficiency": efficiency, "curriculum_stage": _curriculum_stage,
		"curriculum_label": _CURRICULUM_STAGES[_curriculum_stage]["label"],
		"avg_damage_progress": avg_progress, "episode_step": _episode_step,
		"evan_reward": _evan_agent.reward if _evan_agent else 0.0,
		"evelyn_reward": _evelyn_agent.reward if _evelyn_agent else 0.0,
		"team_reward": _team_agent.reward if _team_agent else 0.0,
		"enemy_avg_reward": enemy_reward_sum / float(enemy_reward_count) if enemy_reward_count > 0 else 0.0,
		"evan_hp": _evan_state.current_hp if _evan_state else 0,
		"evan_max_hp": _evan_state.max_hp if _evan_state else 1,
		"evelyn_hp": _evelyn_state.current_hp if _evelyn_state else 0,
		"evelyn_max_hp": _evelyn_state.max_hp if _evelyn_state else 1,
		"enemies_alive": enemies_alive, "enemies_total": _enemies.size(),
	}

func _update_hud() -> void:
	if _evan_state:
		var label = get_node_or_null("%EvanHP")
		if label: label.text = "Evan: %d/%d" % [_evan_state.current_hp, _evan_state.max_hp]
	if _evelyn_state:
		var label = get_node_or_null("%EvelynHP")
		if label: label.text = "Evelyn: %d/%d" % [_evelyn_state.current_hp, _evelyn_state.max_hp]
	var step_label = get_node_or_null("%StepLabel")
	if step_label: step_label.text = "Step: %d" % _episode_step
	var wr_label = get_node_or_null("%WinRate")
	if wr_label:
		var wr: float = (float(_party_wins) / float(_total_episodes)) * 100.0 if _total_episodes > 0 else 0.0
		var avg_prog: float = 0.0
		if _recent_results.size() > 0:
			var s: float = 0.0; for r in _recent_results: s += r
			avg_prog = s / float(_recent_results.size())
		var eff: float = _episode_damage_dealt / maxf(1.0, _episode_damage_received)
		wr_label.text = "Wins: %d/%d | Eff: %.2f | Avg: %.1f%%" % [_party_wins, _total_episodes, eff, avg_prog * 100.0]
	var stage_label = get_node_or_null("%CurriculumStage")
	if stage_label: stage_label.text = "Curriculum: %s" % _CURRICULUM_STAGES[_curriculum_stage]["label"]
	var evan_r = get_node_or_null("%EvanReward")
	if evan_r and _evan_agent: evan_r.text = "Evan R: %.3f" % _evan_agent.reward
	var evelyn_r = get_node_or_null("%EvelynReward")
	if evelyn_r and _evelyn_agent: evelyn_r.text = "Evelyn R: %.3f" % _evelyn_agent.reward
	var team_r = get_node_or_null("%TeamReward")
	if team_r and _team_agent: team_r.text = "Team R: %.3f" % _team_agent.reward
	var enemy_r = get_node_or_null("%EnemyReward")
	if enemy_r:
		var total: float = 0.0; var count: int = 0
		for i in range(_hive_agents.size()):
			if is_instance_valid(_hive_agents[i]) and is_instance_valid(_enemies[i]) and _enemies[i].is_alive:
				total += _hive_agents[i].reward; count += 1
		enemy_r.text = "Enemy R: %.3f" % (total / count if count > 0 else 0.0)

# --- Helpers ---

func _get_alive_party_ratio() -> float:
	var alive: int = 0
	if _evan_state and _evan_state.is_alive: alive += 1
	if _evelyn_state and _evelyn_state.is_alive: alive += 1
	return float(alive) / 2.0

func _toward_nearest_enemy(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF; var best_dir: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist = from.distance_to(enemy.global_position)
			if dist < best_dist: best_dist = dist; best_dir = (enemy.global_position - from).normalized()
	return best_dir

func _nearest_enemy_pos(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF; var best_pos: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist = from.distance_to(enemy.global_position)
			if dist < best_dist: best_dist = dist; best_pos = enemy.global_position
	return best_pos

func _nearest_alive_party_pos(from: Vector3, party_bodies: Array) -> Vector3:
	var best_dist: float = INF; var best_pos: Vector3 = Vector3.ZERO
	for body in party_bodies:
		if body and is_instance_valid(body):
			var state = body.get_node_or_null("PartyMemberState")
			if state and state.is_alive:
				var dist = from.distance_to(body.global_position)
				if dist < best_dist: best_dist = dist; best_pos = body.global_position
	return best_pos

func _lowest_hp_ally_body(self_body: CharacterBody3D) -> CharacterBody3D:
	var bodies: Array = [evan_body, evelyn_body]; var best_ratio: float = INF; var best_body: CharacterBody3D = null
	for body in bodies:
		if body == self_body or not body: continue
		var state = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive:
			var ratio = state.get_hp_ratio()
			if ratio < best_ratio: best_ratio = ratio; best_body = body
	return best_body

func _lowest_hp_alive_party_body(party_bodies: Array) -> CharacterBody3D:
	var best_ratio: float = INF; var best_body: CharacterBody3D = null
	for body in party_bodies:
		if not body: continue
		var state = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive and state.get_hp_ratio() < best_ratio:
			best_ratio = state.get_hp_ratio(); best_body = body
	return best_body
