# rl_team_agent.gd
class_name RLTeamAgent
extends AIController3D

## High-level Team AI coordinator.
## Observes full party + enemy state, outputs directives to individual party agents.
## ADR reference: ADR-0001

@export var evan_agent: RLPartyAgent
@export var evelyn_agent: RLPartyAgent

const MAX_OBS_DIST: float = 20.0
## evan(3) + evelyn(3) + enemies×4(20) + combat(3) + memory(4) = 33
const N_OBS: int = 33

## Current directive outputs — read by rl_arena_manager to push to party agents
var evan_target: int = 3   ## 0-2=enemy index, 3=none
var evan_role: int = 0     ## 0=ATTACK, 1=DEFEND, 2=SUPPORT
var evelyn_target: int = 3
var evelyn_role: int = 0

var victory: bool = false
var _context: Dictionary = {}
var _step_count: int = 0

func _ready() -> void:
	super._ready()

func set_context(context: Dictionary) -> void:
	_context = context

# --- AIController3D interface ---

func get_obs() -> Dictionary:
	var obs: Array[float] = []
	var center: Vector3 = Vector3.ZERO

	# Evan state (3)
	var evan_state: PartyMemberState = evan_agent.state if evan_agent else null
	obs.append(evan_state.get_hp_ratio() if evan_state else 0.0)
	obs.append(evan_state.get_mp_ratio() if evan_state else 0.0)
	obs.append(1.0 if evan_state and evan_state.is_alive else 0.0)
	if evan_state:
		center = evan_agent.get_parent().global_position

	# Evelyn state (3)
	var evelyn_state: PartyMemberState = evelyn_agent.state if evelyn_agent else null
	obs.append(evelyn_state.get_hp_ratio() if evelyn_state else 0.0)
	obs.append(evelyn_state.get_mp_ratio() if evelyn_state else 0.0)
	obs.append(1.0 if evelyn_state and evelyn_state.is_alive else 0.0)

	# Enemies × 4 (20): hp, dist, alive, rel_x, rel_z
	var enemies: Array = _context.get("enemies", [])
	var enemy_count: int = 0
	for enemy in enemies:
		if enemy_count >= 4: break
		if enemy and is_instance_valid(enemy):
			var rel: Vector3 = enemy.global_position - center
			obs.append(enemy.get_hp_ratio() if enemy.has_method("get_hp_ratio") else 0.0)
			obs.append(clampf(center.distance_to(enemy.global_position) / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if enemy.get("is_alive") else 0.0)
			obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
			obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			enemy_count += 1
	while enemy_count < 4:
		for _j in range(5): obs.append(0.0)
		enemy_count += 1

	# Combat state (3): step_norm, alive_ratio, alive_enemies_ratio
	_step_count += 1
	obs.append(clampf(float(_step_count) / 2000.0, 0.0, 1.0))
	var alive_party: int = (1 if evan_state and evan_state.is_alive else 0) + (1 if evelyn_state and evelyn_state.is_alive else 0)
	obs.append(float(alive_party) / 2.0)
	var alive_enemies: int = 0
	for e in enemies:
		if e and is_instance_valid(e) and e.get("is_alive"):
			alive_enemies += 1
	obs.append(float(alive_enemies) / float(max(enemies.size(), 1)))

	# Memory: last directives (4)
	obs.append(float(evan_target) / 3.0)
	obs.append(float(evan_role) / 2.0)
	obs.append(float(evelyn_target) / 3.0)
	obs.append(float(evelyn_role) / 2.0)

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_statistics() -> Dictionary:
	return {
		"reward": reward,
		"victory": 1.0 if victory else 0.0,
		"steps": float(_step_count)
	}

func get_action_space() -> Dictionary:
	return {
		"evan_target":   {"size": 4, "action_type": "discrete"},
		"evan_role":     {"size": 3, "action_type": "discrete"},
		"evelyn_target": {"size": 4, "action_type": "discrete"},
		"evelyn_role":   {"size": 3, "action_type": "discrete"},
	}

func set_action(action: Dictionary) -> void:
	evan_target   = action.get("evan_target", 3)
	evan_role     = action.get("evan_role", 0)
	evelyn_target = action.get("evelyn_target", 3)
	evelyn_role   = action.get("evelyn_role", 0)
	## rl_arena_manager reads these and pushes to party agents via set_directive()

func reset() -> void:
	super.reset()
	reward = 0.0
	victory = false
	evan_target = 3; evan_role = 0
	evelyn_target = 3; evelyn_role = 0
	_step_count = 0

# --- Reward callbacks (called by rl_arena_manager) ---

func on_enemy_killed() -> void:
	reward += 0.5

func on_victory() -> void:
	reward += 5.0
	victory = true
	done = true

func on_defeat() -> void:
	reward -= 5.0
	done = true

func on_ally_died() -> void:
	reward -= 1.5

func add_survival_reward(alive_ratio: float) -> void:
	reward += 0.01 * alive_ratio
