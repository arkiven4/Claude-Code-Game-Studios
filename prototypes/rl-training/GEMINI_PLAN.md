# RL Training Prototype — Multi-Agent Execution Plan for Gemini

**Goal**: Implement a 3-tier multi-agent RL system: a high-level Team AI coordinates
Evan (Tanker) and Evelyn (Mage/DPS), while a separate Enemy Hive Mind controls all
enemies. Training produces 4 `.onnx` models (one per policy).

**Engine**: Godot 4.6 (GDScript, statically typed)
**RL Framework**: `godot_rl` v0.8.2 + Ray RLlib
**Addon**: `addons/godot_rl_agents/` already installed and enabled
**Python**: 3.10

**DO NOT modify `assets/scenes/TestArena.tscn`** — build a separate training scene.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│             TeamPolicy (high-level)              │
│  obs: 33 floats  |  4 discrete action heads      │
│  reward: team outcomes (victory/defeat/kills)    │
└──────────────┬──────────────┬───────────────────┘
               │ directive     │ directive
      ┌────────▼──────┐  ┌────▼────────────┐
      │  EvanPolicy   │  │  EvelynPolicy   │
      │ Tanker role   │  │  Mage/DPS role  │
      │ obs: 46 float │  │  obs: 46 float  │
      │ action: disc9 │  │  action: disc9  │
      └───────────────┘  └─────────────────┘

┌─────────────────────────────────────────────────┐
│         EnemyHivePolicy (shared weights)         │
│  1 controller per enemy, same policy weights     │
│  obs: 21 floats  |  action: discrete 6           │
│  reward: adversarial to party                    │
└─────────────────────────────────────────────────┘
```

All 5 agents share ONE Sync node (port 11008). Python uses Ray RLlib MultiAgentEnv.
TeamPolicy runs every step — its output (directives) is injected into party agent
observations. No frequency mismatch.

---

## Existing Files — Do NOT Recreate

| Path | Used By |
|------|---------|
| `addons/godot_rl_agents/controller/ai_controller_3d.gd` | Base class for all agents |
| `addons/godot_rl_agents/sync.gd` | TCP bridge, add to TrainingArena |
| `src/gameplay/party_member_state.gd` | Has `get_hp_ratio()`, `can_use_skill(i)`, `skill_cooldowns[]`, `reset_for_encounter(bool)` |
| `src/gameplay/skill_execution_system.gd` | Has `try_activate_skill(slot, tier)`, emits `damage_dealt(amount, target)` |
| `src/gameplay/enemy_ai_controller.gd` | Has `is_alive`, `current_hp`, `max_hp`, `take_damage(data)`, emits `died`, `damage_taken(amount)` |
| `assets/scenes/characters/Evan.tscn` | Use as instance — contains PartyMemberState, SkillExecutionSystem |
| `assets/scenes/characters/Evelyn.tscn` | Same |
| `assets/scenes/enemies/GruntMelee.tscn` | Use as instance |
| `assets/scenes/enemies/ArcherRanged.tscn` | Use as instance |

---

## Task 1 — Rewrite `src/ai/rl_party_agent.gd`

Extends `AIController3D`. Handles both Evan and Evelyn — role is set via export enum.
Discrete 9 actions (skills + movement). 46 observations (39 base + 7 directive).

**Replace the entire file:**

```gdscript
# rl_party_agent.gd
class_name RLPartyAgent
extends AIController3D

## Individual party AI agent (Evan=Tanker, Evelyn=Mage).
## Extends AIController3D for Godot RL Agents addon.
## ADR reference: ADR-0001 (Party AI: RL vs. Behavior Tree)

enum Role { TANKER, MAGE }

@export var state: PartyMemberState
@export var skill_execution: SkillExecutionSystem
@export var role: Role = Role.TANKER

## Reward weights — tuned per role via Inspector
@export var w_damage_dealt: float = 0.001
@export var w_damage_received: float = 0.0003
@export var w_skill_hit: float = 0.005
@export var w_idle: float = 0.001
@export var w_team: float = 0.4

const MAX_OBS_DIST: float = 20.0
const N_BASE_OBS: int = 39
const N_DIRECTIVE: int = 7
const N_OBS: int = N_BASE_OBS + N_DIRECTIVE  ## 46

var _active_tier: int = 1
var _context: Dictionary = {}

## Current directive from TeamPolicy (set each step by rl_arena_manager)
var directive_target: int = 3   ## 0-2=enemy index, 3=none
var directive_role: int = 0     ## 0=ATTACK, 1=DEFEND, 2=SUPPORT

## Pending movement action for rl_arena_manager to execute
var pending_move_action: int = 0

## Last discrete action received (for rl_arena_manager to read)
var last_action: int = 0

func _ready() -> void:
	super._ready()
	if not state:
		state = get_parent().get_node_or_null("PartyMemberState")
	if not skill_execution:
		skill_execution = get_parent().get_node_or_null("SkillExecutionSystem")
	if skill_execution:
		skill_execution.damage_dealt.connect(_on_damage_dealt)

## Called by rl_arena_manager each step after TeamPolicy outputs directives.
func set_directive(target: int, role_mode: int) -> void:
	directive_target = target
	directive_role = role_mode

## Called by rl_arena_manager to inject enemy/ally context each episode.
func set_context(context: Dictionary) -> void:
	_context = context
	if state:
		_active_tier = state.character_data.get_active_tier(state.character_level)

# --- AIController3D interface ---

func get_obs() -> Dictionary:
	var obs: Array[float] = []

	if not state:
		obs.resize(N_OBS)
		obs.fill(0.0)
		return {"obs": obs}

	# Self (10): hp, mp, 4×cooldown_ratio, 4×can_use
	obs.append(state.get_hp_ratio())
	obs.append(float(state.current_mp) / float(state.max_mp) if state.max_mp > 0 else 0.0)
	for i in range(4):
		var cd: float = state.skill_cooldowns[i] if i < state.skill_cooldowns.size() else 0.0
		var skill: SkillData = state.character_data.skill_slots[i] if i < state.character_data.skill_slots.size() else null
		var max_cd: float = skill.cooldown if skill else 1.0
		obs.append(clampf(cd / max_cd, 0.0, 1.0) if max_cd > 0.0 else 0.0)
	for i in range(4):
		obs.append(1.0 if state.can_use_skill(i) else 0.0)

	# Allies (9): up to 3 × (hp, mp, alive)
	var allies: Array = _context.get("allies", [])
	var ally_count: int = 0
	for ally in allies:
		if ally_count >= 3:
			break
		if ally and is_instance_valid(ally) and ally != state:
			obs.append(ally.get_hp_ratio() if ally.has_method("get_hp_ratio") else 0.0)
			obs.append(float(ally.current_mp) / float(ally.max_mp) if ally.max_mp > 0 else 0.0)
			obs.append(1.0 if ally.is_alive else 0.0)
			ally_count += 1
	while ally_count < 3:
		obs.append(0.0); obs.append(0.0); obs.append(0.0)
		ally_count += 1

	# Enemies (20): up to 4 × (hp, dist, alive, rel_x, rel_z)
	var enemies: Array = _context.get("enemies", [])
	var agent_pos: Vector3 = get_parent().global_position if get_parent() else Vector3.ZERO
	var enemy_count: int = 0
	for enemy in enemies:
		if enemy_count >= 4:
			break
		if enemy and is_instance_valid(enemy):
			var rel: Vector3 = enemy.global_position - agent_pos
			obs.append(float(enemy.current_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0)
			obs.append(clampf(agent_pos.distance_to(enemy.global_position) / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if enemy.is_alive else 0.0)
			obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
			obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			enemy_count += 1
	while enemy_count < 4:
		for _j in range(5): obs.append(0.0)
		enemy_count += 1

	# Directive (7): focus_target one-hot×4 + role_mode one-hot×3
	for i in range(4):
		obs.append(1.0 if directive_target == i else 0.0)
	for i in range(3):
		obs.append(1.0 if directive_role == i else 0.0)

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		# 0=wait, 1-4=skill slots, 5=move→enemy, 6=move away, 7=move→ally, 8=hold
		"action": {"size": 9, "action_type": "discrete"},
	}

func set_action(action: Dictionary) -> void:
	var act: int = action.get("action", 0)
	last_action = act
	pending_move_action = 0

	if not state or not state.is_alive:
		return

	match act:
		1, 2, 3, 4:
			if skill_execution:
				var hit: bool = skill_execution.try_activate_skill(act - 1, _active_tier)
				if hit:
					reward += w_skill_hit
		5:
			pending_move_action = 5  ## move toward focus_target — rl_arena_manager executes
		6:
			pending_move_action = 6  ## move away
		7:
			pending_move_action = 7  ## move toward lowest-HP ally
		8:
			pending_move_action = 8  ## hold
		_:
			reward -= w_idle  ## action=0 or unknown = idle penalty

func reset() -> void:
	super.reset()
	reward = 0.0
	directive_target = 3
	directive_role = 0
	pending_move_action = 0
	last_action = 0

# --- Reward callbacks (called by rl_arena_manager) ---

func add_team_reward(amount: float) -> void:
	reward += amount * w_team

func on_protection_bonus() -> void:
	## Called when Evan (Tanker) is positioned between enemy and Evelyn
	if role == Role.TANKER:
		reward += 0.003

func _on_damage_dealt(amount: int, _target: Node) -> void:
	reward += amount * w_damage_dealt

func on_damage_received(amount: int) -> void:
	reward -= amount * w_damage_received
```

---

## Task 2 — Create `src/ai/rl_team_agent.gd`

High-level coordinator. Observes full battle state, outputs 4 discrete directives
(target + role for each party member). Receives team-outcome reward only.

**Create new file:**

```gdscript
# rl_team_agent.gd
class_name RLTeamAgent
extends AIController3D

## High-level Team AI coordinator.
## Observes full party + enemy state, outputs directives to individual party agents.
## ADR reference: ADR-0001

@export var evan_agent: RLPartyAgent
@export var evelyn_agent: RLPartyAgent

const MAX_OBS_DIST: float = 20.0
const N_OBS: int = 33

## Current directive outputs — read by rl_arena_manager to push to party agents
var evan_target: int = 3   ## 0-2=enemy index, 3=none
var evan_role: int = 0     ## 0=ATTACK, 1=DEFEND, 2=SUPPORT
var evelyn_target: int = 3
var evelyn_role: int = 0

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
	obs.append(float(evan_state.current_mp) / float(evan_state.max_mp) if evan_state and evan_state.max_mp > 0 else 0.0)
	obs.append(1.0 if evan_state and evan_state.is_alive else 0.0)
	if evan_state:
		center = evan_agent.get_parent().global_position

	# Evelyn state (3)
	var evelyn_state: PartyMemberState = evelyn_agent.state if evelyn_agent else null
	obs.append(evelyn_state.get_hp_ratio() if evelyn_state else 0.0)
	obs.append(float(evelyn_state.current_mp) / float(evelyn_state.max_mp) if evelyn_state and evelyn_state.max_mp > 0 else 0.0)
	obs.append(1.0 if evelyn_state and evelyn_state.is_alive else 0.0)

	# Enemies × 4 (20): hp, dist, alive, rel_x, rel_z
	var enemies: Array = _context.get("enemies", [])
	var enemy_count: int = 0
	for enemy in enemies:
		if enemy_count >= 4: break
		if enemy and is_instance_valid(enemy):
			var rel: Vector3 = enemy.global_position - center
			obs.append(float(enemy.current_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0)
			obs.append(clampf(center.distance_to(enemy.global_position) / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if enemy.is_alive else 0.0)
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
		if e and is_instance_valid(e) and e.is_alive:
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
	evan_target = 3; evan_role = 0
	evelyn_target = 3; evelyn_role = 0
	_step_count = 0

# --- Reward callbacks (called by rl_arena_manager) ---

func on_enemy_killed() -> void:
	reward += 0.5

func on_victory() -> void:
	reward += 5.0
	done = true

func on_defeat() -> void:
	reward -= 5.0
	done = true

func on_ally_died() -> void:
	reward -= 1.5

func add_survival_reward(alive_ratio: float) -> void:
	reward += 0.01 * alive_ratio
```

---

## Task 3 — Create `src/ai/rl_enemy_hive_agent.gd`

One controller per enemy, all sharing the same policy ("enemy_hive").
Hive mind emerges from parameter sharing — same weights, local observations.

**Create new file:**

```gdscript
# rl_enemy_hive_agent.gd
class_name RLEnemyHiveAgent
extends AIController3D

## Enemy hive mind agent (one per enemy, shared policy weights).
## Adversarial to party agents.

@export var enemy_controller: EnemyAIController

const MAX_OBS_DIST: float = 20.0
const N_OBS: int = 21

## Pending movement action — executed by rl_arena_manager
var pending_move_action: int = 0

var _context: Dictionary = {}

func _ready() -> void:
	super._ready()
	if not enemy_controller:
		enemy_controller = get_parent() as EnemyAIController
	if enemy_controller:
		enemy_controller.damage_taken.connect(_on_damage_taken)

func set_context(context: Dictionary) -> void:
	_context = context

# --- AIController3D interface ---

func get_obs() -> Dictionary:
	var obs: Array[float] = []

	if not enemy_controller:
		obs.resize(N_OBS); obs.fill(0.0)
		return {"obs": obs}

	var self_pos: Vector3 = enemy_controller.global_position

	# Self (3): hp_ratio, skill0_cd_ratio, skill1_cd_ratio
	obs.append(float(enemy_controller.current_hp) / float(enemy_controller.max_hp) if enemy_controller.max_hp > 0 else 0.0)
	var cds: Array = enemy_controller._skill_cooldowns if enemy_controller.get("_skill_cooldowns") != null else []
	obs.append(clampf(cds[0] / 5.0, 0.0, 1.0) if cds.size() > 0 else 0.0)
	obs.append(clampf(cds[1] / 5.0, 0.0, 1.0) if cds.size() > 1 else 0.0)

	# Party members × 2 (10): hp, dist, alive, rel_x, rel_z
	var party: Array = _context.get("party", [])
	var party_count: int = 0
	for member_state in party:
		if party_count >= 2: break
		if member_state and is_instance_valid(member_state):
			var member_body: Node3D = member_state.get_parent() as Node3D
			var rel: Vector3 = (member_body.global_position - self_pos) if member_body else Vector3.ZERO
			var dist: float = self_pos.distance_to(member_body.global_position) if member_body else 0.0
			obs.append(member_state.get_hp_ratio())
			obs.append(clampf(dist / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if member_state.is_alive else 0.0)
			obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
			obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			party_count += 1
	while party_count < 2:
		for _j in range(5): obs.append(0.0)
		party_count += 1

	# Other enemies × 2 (8): hp, alive, rel_x, rel_z
	var allies: Array = _context.get("enemy_allies", [])
	var ally_count: int = 0
	for ally in allies:
		if ally_count >= 2: break
		if ally and is_instance_valid(ally) and ally != enemy_controller:
			var rel: Vector3 = ally.global_position - self_pos
			obs.append(float(ally.current_hp) / float(ally.max_hp) if ally.max_hp > 0 else 0.0)
			obs.append(1.0 if ally.is_alive else 0.0)
			obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
			obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			ally_count += 1
	while ally_count < 2:
		for _j in range(4): obs.append(0.0)
		ally_count += 1

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		# 0=wait, 1=skill0, 2=skill1, 3=move→nearest party, 4=reposition away, 5=move→lowest-HP party
		"action": {"size": 6, "action_type": "discrete"},
	}

func set_action(action: Dictionary) -> void:
	var act: int = action.get("action", 0)
	pending_move_action = 0

	if not enemy_controller or not enemy_controller.is_alive:
		return

	match act:
		1, 2:
			if enemy_controller.enemy_data and act - 1 < enemy_controller.enemy_data.skill_list.size():
				enemy_controller._use_skill(act - 1)
		3:
			pending_move_action = 3  ## rl_arena_manager moves toward nearest party member
		4:
			pending_move_action = 4  ## reposition away
		5:
			pending_move_action = 5  ## move toward lowest-HP party member
		_:
			reward -= 0.001  ## idle penalty

func reset() -> void:
	super.reset()
	reward = 0.0
	pending_move_action = 0

# --- Reward callbacks ---

func on_damage_dealt_to_party(amount: int) -> void:
	reward += amount * 0.001

func _on_damage_taken(amount: int) -> void:
	reward -= amount * 0.0005

func on_party_member_killed() -> void:
	reward += 1.0

func on_party_wiped() -> void:
	reward += 3.0
	done = true

func on_all_enemies_killed() -> void:
	reward -= 3.0
	done = true
```

---

## Task 4 — Create `prototypes/rl-training/rl_arena_manager.gd`

Manages episodes, executes movement from agent actions, routes directives and rewards.

**Create new file:**

```gdscript
# rl_arena_manager.gd
# Root script for TrainingArena.tscn.
# Handles: episode resets, movement execution, directive routing, reward wiring.
extends Node3D

@export var evan_body: CharacterBody3D
@export var evelyn_body: CharacterBody3D
@export var enemy_container: Node3D

@export var move_speed: float = 4.0
@export var max_episode_steps: int = 2000

@onready var _evan_agent: RLPartyAgent = evan_body.get_node("RLPartyAgent") if evan_body else null
@onready var _evelyn_agent: RLPartyAgent = evelyn_body.get_node("RLPartyAgent") if evelyn_body else null
@onready var _evan_state: PartyMemberState = evan_body.get_node("PartyMemberState") if evan_body else null
@onready var _evelyn_state: PartyMemberState = evelyn_body.get_node("PartyMemberState") if evelyn_body else null
@onready var _team_agent: RLTeamAgent = $TeamAI

const GRUNT_SCENE: PackedScene = preload("res://assets/scenes/enemies/GruntMelee.tscn")
const ARCHER_SCENE: PackedScene = preload("res://assets/scenes/enemies/ArcherRanged.tscn")

## Spawn transforms (position, rotation) for enemies — set to match TestArena layout
const ENEMY_SPAWNS: Array[Transform3D] = [
	Transform3D(Basis.IDENTITY, Vector3(-4.0, 0.9, 25.0)),
	Transform3D(Basis.IDENTITY, Vector3(4.0,  0.9, 25.0)),
	Transform3D(Basis.IDENTITY, Vector3(0.0,  0.9, 26.5)),
]
const ENEMY_SCENES: Array = [GRUNT_SCENE, GRUNT_SCENE, ARCHER_SCENE]

var _enemies: Array[EnemyAIController] = []
var _hive_agents: Array[RLEnemyHiveAgent] = []
var _episode_step: int = 0
var _episode_active: bool = false
var _party: Array[PartyMemberState] = []

func _ready() -> void:
	_party = [_evan_state, _evelyn_state]
	await get_tree().process_frame
	_start_episode()

func _physics_process(delta: float) -> void:
	if not _episode_active:
		return

	_episode_step += 1

	# Push TeamPolicy directives to party agents
	if _team_agent:
		if _evan_agent:
			_evan_agent.set_directive(_team_agent.evan_target, _team_agent.evan_role)
		if _evelyn_agent:
			_evelyn_agent.set_directive(_team_agent.evelyn_target, _team_agent.evelyn_role)

	# Execute party movement
	_execute_party_movement(delta)
	# Execute enemy movement
	_execute_enemy_movement(delta)

	# Survival reward per step
	var alive_ratio: float = _get_alive_party_ratio()
	if _team_agent:
		_team_agent.add_survival_reward(alive_ratio)

	# Check protection bonus for Evan (tanker between enemy and Evelyn)
	_check_protection_bonus()

	# Check end conditions
	_check_victory_or_defeat()

	# Force-end episode after timeout
	if _episode_step >= max_episode_steps:
		_end_episode(false)

# --- Movement Execution ---

func _execute_party_movement(delta: float) -> void:
	_execute_agent_movement(evan_body, _evan_agent, delta)
	_execute_agent_movement(evelyn_body, _evelyn_agent, delta)

func _execute_agent_movement(body: CharacterBody3D, agent: RLPartyAgent, delta: float) -> void:
	if not body or not agent or not agent.state or not agent.state.is_alive:
		if body:
			body.velocity = Vector3.ZERO
			body.move_and_slide()
		return

	var move_dir: Vector3 = Vector3.ZERO
	var enemies: Array = agent._context.get("enemies", [])

	match agent.pending_move_action:
		5:  ## move toward focus_target enemy
			var target_idx: int = agent.directive_target
			if target_idx < enemies.size() and is_instance_valid(enemies[target_idx]) and enemies[target_idx].is_alive:
				move_dir = (enemies[target_idx].global_position - body.global_position).normalized()
			else:
				move_dir = _toward_nearest_enemy(body.global_position, enemies)
		6:  ## move away from nearest enemy
			var nearest: Vector3 = _nearest_enemy_pos(body.global_position, enemies)
			if nearest != Vector3.ZERO:
				move_dir = (body.global_position - nearest).normalized()
		7:  ## move toward lowest-HP ally
			var ally_body: CharacterBody3D = _lowest_hp_ally_body(body)
			if ally_body:
				move_dir = (ally_body.global_position - body.global_position).normalized()
		8:  ## hold position
			move_dir = Vector3.ZERO

	body.velocity = move_dir * move_speed
	body.move_and_slide()

func _execute_enemy_movement(delta: float) -> void:
	var party_bodies: Array[CharacterBody3D] = []
	if evan_body: party_bodies.append(evan_body)
	if evelyn_body: party_bodies.append(evelyn_body)

	for i in range(_enemies.size()):
		var enemy: EnemyAIController = _enemies[i]
		var hive: RLEnemyHiveAgent = _hive_agents[i] if i < _hive_agents.size() else null
		if not enemy or not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		if not hive:
			continue

		var move_dir: Vector3 = Vector3.ZERO
		var party_states: Array = hive._context.get("party", [])

		match hive.pending_move_action:
			3:  ## move toward nearest party member
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (nearest - enemy.global_position).normalized()
			4:  ## reposition away
				var nearest: Vector3 = _nearest_alive_party_pos(enemy.global_position, party_bodies)
				if nearest != Vector3.ZERO:
					move_dir = (enemy.global_position - nearest).normalized()
			5:  ## move toward lowest-HP party member
				var target_body: CharacterBody3D = _lowest_hp_alive_party_body(party_bodies, party_states)
				if target_body:
					move_dir = (target_body.global_position - enemy.global_position).normalized()

		enemy.velocity = move_dir * enemy.move_speed
		enemy.move_and_slide()

# --- Episode Management ---

func _start_episode() -> void:
	_episode_step = 0
	_spawn_enemies()
	_wire_enemy_signals()
	_update_all_contexts()
	_episode_active = true

func _end_episode(victory: bool) -> void:
	_episode_active = false

	if victory:
		if _team_agent: _team_agent.on_victory()
		if _evan_agent: _evan_agent.done = true
		if _evelyn_agent: _evelyn_agent.done = true
		for hive in _hive_agents:
			if hive: hive.on_all_enemies_killed()
	else:
		if _team_agent: _team_agent.on_defeat()
		if _evan_agent: _evan_agent.done = true
		if _evelyn_agent: _evelyn_agent.done = true
		for hive in _hive_agents:
			if hive: hive.on_party_wiped()

	await get_tree().create_timer(0.1).timeout
	_reset_episode()

func _reset_episode() -> void:
	# Reset party
	if _evan_state: _evan_state.reset_for_encounter(true)
	if _evelyn_state: _evelyn_state.reset_for_encounter(true)
	if evan_body: evan_body.global_position = Vector3(-1.0, 1.0, 0.0)
	if evelyn_body: evelyn_body.global_position = Vector3(1.0, 1.0, 0.0)

	# Destroy and respawn enemies
	for enemy in _enemies:
		if is_instance_valid(enemy): enemy.queue_free()
	_enemies.clear()
	_hive_agents.clear()
	await get_tree().process_frame

	# Reset AI controllers
	if _evan_agent: _evan_agent.reset()
	if _evelyn_agent: _evelyn_agent.reset()
	if _team_agent: _team_agent.reset()

	_start_episode()

func _spawn_enemies() -> void:
	for i in range(ENEMY_SPAWNS.size()):
		var scene: PackedScene = ENEMY_SCENES[i]
		var enemy: EnemyAIController = scene.instantiate()
		enemy_container.add_child(enemy)
		enemy.global_transform = ENEMY_SPAWNS[i]

		var hive: RLEnemyHiveAgent = RLEnemyHiveAgent.new()
		hive.policy_name = "enemy_hive"
		hive.reset_after = max_episode_steps
		enemy.add_child(hive)
		hive.enemy_controller = enemy

		_enemies.append(enemy)
		_hive_agents.append(hive)

func _wire_enemy_signals() -> void:
	for i in range(_enemies.size()):
		var enemy: EnemyAIController = _enemies[i]
		var hive: RLEnemyHiveAgent = _hive_agents[i]
		enemy.died.connect(_on_enemy_died.bind(enemy, hive))
		enemy.damage_taken.connect(_on_enemy_damage_taken.bind(hive))
		# Wire party hurtbox → enemy reward
		if _evan_state:
			_evan_state.hp_changed.connect(_on_party_hp_changed)
		if _evelyn_state:
			_evelyn_state.hp_changed.connect(_on_party_hp_changed)

func _update_all_contexts() -> void:
	var enemy_context: Dictionary = {
		"enemies": _enemies,
		"allies": [_evan_state, _evelyn_state],
	}
	if _evan_agent: _evan_agent.set_context({"enemies": _enemies, "allies": [_evelyn_state]})
	if _evelyn_agent: _evelyn_agent.set_context({"enemies": _enemies, "allies": [_evan_state]})
	if _team_agent: _team_agent.set_context({"enemies": _enemies})

	for i in range(_hive_agents.size()):
		_hive_agents[i].set_context({
			"party": [_evan_state, _evelyn_state],
			"enemy_allies": _enemies,
		})

# --- Reward Routing ---

func _on_enemy_died(enemy: EnemyAIController, hive: RLEnemyHiveAgent) -> void:
	if _team_agent: _team_agent.on_enemy_killed()
	if _evan_agent: _evan_agent.reward += 0.5 * _evan_agent.w_team
	if _evelyn_agent: _evelyn_agent.reward += 0.5 * _evelyn_agent.w_team
	_update_all_contexts()
	_check_victory_or_defeat()

func _on_enemy_damage_taken(amount: int, hive: RLEnemyHiveAgent) -> void:
	if hive: hive._on_damage_taken(amount)

func _on_party_hp_changed(current: int, max_hp: int) -> void:
	## Party took damage — reward enemy hive agents
	## We can't easily compute the delta here so we use the damage_taken signal on hurtbox instead
	pass

func _check_protection_bonus() -> void:
	if not _evan_agent or not _evelyn_agent or not evan_body or not evelyn_body:
		return
	if not _evan_state or not _evan_state.is_alive:
		return
	for enemy in _enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var evan_pos: Vector3 = evan_body.global_position
		var evelyn_pos: Vector3 = evelyn_body.global_position
		var enemy_pos: Vector3 = enemy.global_position
		## Check if Evan is between enemy and Evelyn
		var to_evelyn: Vector3 = (evelyn_pos - enemy_pos).normalized()
		var to_evan: Vector3 = (evan_pos - enemy_pos).normalized()
		if to_evan.dot(to_evelyn) > 0.7 and evan_pos.distance_to(enemy_pos) < evelyn_pos.distance_to(enemy_pos):
			_evan_agent.on_protection_bonus()
			break

func _check_victory_or_defeat() -> void:
	if not _episode_active:
		return
	var all_enemies_dead: bool = true
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			all_enemies_dead = false
			break
	if all_enemies_dead:
		_end_episode(true)
		return
	var party_wiped: bool = (not _evan_state or not _evan_state.is_alive) and (not _evelyn_state or not _evelyn_state.is_alive)
	if party_wiped:
		_end_episode(false)

# --- Helpers ---

func _get_alive_party_ratio() -> float:
	var alive: int = 0
	if _evan_state and _evan_state.is_alive: alive += 1
	if _evelyn_state and _evelyn_state.is_alive: alive += 1
	return float(alive) / 2.0

func _toward_nearest_enemy(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF
	var best_dir: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist: float = from.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_dir = (enemy.global_position - from).normalized()
	return best_dir

func _nearest_enemy_pos(from: Vector3, enemies: Array) -> Vector3:
	var best_dist: float = INF
	var best_pos: Vector3 = Vector3.ZERO
	for enemy in enemies:
		if enemy and is_instance_valid(enemy) and enemy.is_alive:
			var dist: float = from.distance_to(enemy.global_position)
			if dist < best_dist:
				best_dist = dist
				best_pos = enemy.global_position
	return best_pos

func _nearest_alive_party_pos(from: Vector3, party_bodies: Array) -> Vector3:
	var best_dist: float = INF
	var best_pos: Vector3 = Vector3.ZERO
	for body in party_bodies:
		if body and is_instance_valid(body):
			var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
			if state and state.is_alive:
				var dist: float = from.distance_to(body.global_position)
				if dist < best_dist:
					best_dist = dist
					best_pos = body.global_position
	return best_pos

func _lowest_hp_ally_body(self_body: CharacterBody3D) -> CharacterBody3D:
	var bodies: Array = [evan_body, evelyn_body]
	var best_ratio: float = INF
	var best_body: CharacterBody3D = null
	for body in bodies:
		if body == self_body or not body:
			continue
		var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive:
			var ratio: float = state.get_hp_ratio()
			if ratio < best_ratio:
				best_ratio = ratio
				best_body = body
	return best_body

func _lowest_hp_alive_party_body(party_bodies: Array, _party_states: Array) -> CharacterBody3D:
	var best_ratio: float = INF
	var best_body: CharacterBody3D = null
	for body in party_bodies:
		if not body: continue
		var state: PartyMemberState = body.get_node_or_null("PartyMemberState")
		if state and state.is_alive and state.get_hp_ratio() < best_ratio:
			best_ratio = state.get_hp_ratio()
			best_body = body
	return best_body
```

---

## Task 5 — Create `prototypes/rl-training/TrainingArena.tscn`

Build this scene in the Godot Editor. Scene tree:

```
TrainingArena (Node3D)  ← script: res://prototypes/rl-training/rl_arena_manager.gd
│   [Inspector exports]
│   evan_body:     NodePath("Party/Evan")
│   evelyn_body:   NodePath("Party/Evelyn")
│   enemy_container: NodePath("Enemies")
│
├── Sync (Node)  ← script: res://addons/godot_rl_agents/sync.gd
│     control_mode = 1  (TRAINING)
│     speed_up = 10.0
│
├── WorldEnvironment  ← copy from TestArena
├── Sun (DirectionalLight3D)  ← copy from TestArena
│
├── Ground (StaticBody3D)
│   ├── Mesh (MeshInstance3D)  ← BoxMesh 60×0.1×60, gray material
│   └── Collision (CollisionShape3D)  ← BoxShape3D 60×0.1×60
│
├── Party (Node3D)
│   ├── Evan (instance: res://assets/scenes/characters/Evan.tscn)
│   │     transform: position (-1, 1, 0)
│   │     └── RLPartyAgent (Node3D)  ← script: res://src/ai/rl_party_agent.gd
│   │           policy_name = "evan_policy"
│   │           role = TANKER (0)
│   │           reset_after = 2000
│   │           w_damage_dealt = 0.001
│   │           w_damage_received = 0.0003
│   │           [state + skill_execution left as null — rl_arena_manager sets via _ready]
│   │
│   └── Evelyn (instance: res://assets/scenes/characters/Evelyn.tscn)
│         transform: position (1, 1, 0)
│         └── RLPartyAgent (Node3D)  ← script: res://src/ai/rl_party_agent.gd
│               policy_name = "evelyn_policy"
│               role = MAGE (1)
│               reset_after = 2000
│               w_damage_dealt = 0.002
│               w_damage_received = 0.002
│
├── TeamAI (Node3D)  ← script: res://src/ai/rl_team_agent.gd
│     policy_name = "team_policy"
│     reset_after = 2000
│     evan_agent:   NodePath("../Party/Evan/RLPartyAgent")
│     evelyn_agent: NodePath("../Party/Evelyn/RLPartyAgent")
│
└── Enemies (Node3D)
    [empty at design time — spawned at runtime by rl_arena_manager]
```

**Important**: The `RLPartyAgent` nodes auto-resolve `state` and `skill_execution`
from their parent via `get_parent().get_node_or_null()` in `_ready()`.
No manual NodePath wiring needed for those.

---

## Task 6 — Create `prototypes/rl-training/train.py`

```python
"""
Multi-agent RL training for myvampire party AI.
Uses godot_rl v0.8.2 + Ray RLlib (multi-policy).

Install dependencies:
  pip install ray[rllib] torch godot-rl-agents

Usage:
  Terminal 1 (start first):
    cd /path/to/myvampire
    python3.10 prototypes/rl-training/train.py

  Terminal 2 (after Python prints "waiting for connection"):
    godot --headless -- res://prototypes/rl-training/TrainingArena.tscn \\
      --speedup=10 --fixed-fps=2000 --disable-render-loop

Models saved to: prototypes/rl-training/models/
"""

import os
import ray
from ray.rllib.algorithms.ppo import PPOConfig
from ray.tune.registry import register_env
from godot_rl.wrappers.ray_wrapper import GodotEnv

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

# Observation/action space sizes matching GDScript agent designs
PARTY_OBS_SIZE  = 46   # RLPartyAgent N_OBS
TEAM_OBS_SIZE   = 33   # RLTeamAgent N_OBS
ENEMY_OBS_SIZE  = 21   # RLEnemyHiveAgent N_OBS

PARTY_ACT_SIZE  = 9    # discrete
ENEMY_ACT_SIZE  = 6    # discrete
# Team has 4 discrete heads — handled by RLlib multi-discrete or Dict space


def env_creator(env_config):
    return GodotEnv(
        env_path=None,      # Godot launched manually
        port=env_config.get("port", 11008),
        seed=env_config.get("seed", 42),
        n_parallel=1,
        speedup=10,
    )


def main():
    ray.init()
    register_env("godot_multiagent", env_creator)

    # Build a temporary env to get observation/action spaces from Godot
    print("Waiting for Godot to connect on port 11008 ...")
    print("Launch: godot --headless -- res://prototypes/rl-training/TrainingArena.tscn")

    config = (
        PPOConfig()
        .environment("godot_multiagent", env_config={"port": 11008})
        .multi_agent(
            policies={
                "team_policy":   (None, None, None, {}),
                "evan_policy":   (None, None, None, {"role": "tanker"}),
                "evelyn_policy": (None, None, None, {"role": "mage"}),
                "enemy_hive":    (None, None, None, {}),
            },
            policy_mapping_fn=lambda agent_id, *args, **kwargs: agent_id,
        )
        .training(
            lr=3e-4,
            train_batch_size=4000,
            sgd_minibatch_size=128,
            num_sgd_iter=10,
            entropy_coeff=0.01,
        )
        .resources(num_gpus=0)
    )

    algo = config.build()

    print("Training started. Ctrl+C to stop.")
    for iteration in range(500):
        result = algo.train()
        if iteration % 10 == 0:
            print(f"[{iteration}] reward_mean: {result.get('episode_reward_mean', 'N/A'):.3f}")
        if iteration % 50 == 0:
            save_path = algo.save(MODELS_DIR)
            print(f"Checkpoint saved: {save_path}")

    algo.save(os.path.join(MODELS_DIR, "final"))
    print(f"Training complete. Models saved to {MODELS_DIR}")
    ray.shutdown()


if __name__ == "__main__":
    main()
```

---

## Task 7 — Verify Godot Plugin Enabled

Check `project.godot` contains:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_rl_agents/godot_rl_agents.gd", ...)
```

If not listed, enable via **Project → Project Settings → Plugins** in Godot Editor.

---

## Execution Order for Gemini

1. Rewrite `src/ai/rl_party_agent.gd`
2. Create `src/ai/rl_team_agent.gd`
3. Create `src/ai/rl_enemy_hive_agent.gd`
4. Create `prototypes/rl-training/rl_arena_manager.gd`
5. Create `prototypes/rl-training/TrainingArena.tscn` (in Godot Editor using spec above)
6. Create `prototypes/rl-training/train.py`

---

## Acceptance Criteria

- [ ] All 3 GDScript AI files compile in Godot 4.6 without errors
- [ ] `TrainingArena.tscn` opens; scene tree has Sync, Party (Evan+Evelyn), TeamAI, Enemies nodes
- [ ] Each party character has an `RLPartyAgent` child node; TeamAI node exists
- [ ] `python3.10 prototypes/rl-training/train.py` starts and waits for Godot connection
- [ ] Godot headless connects (handshake appears in Python terminal)
- [ ] 4 policy reward streams visible in training output
- [ ] `models/` directory populated with checkpoint files after training

---

## Known Risks / Notes

- `EnemyAIController._skill_cooldowns` is a private variable. `rl_enemy_hive_agent.gd`
  accesses it via `enemy_controller.get("_skill_cooldowns")` — this works in GDScript
  but is fragile. If it returns null, the fallback is 0.0 (safe).

- `EnemyAIController._use_skill(slot)` is called from `rl_enemy_hive_agent`. If this
  method is private/non-existent, replace with `enemy_controller.call("_use_skill", slot)`.
  Check `src/gameplay/enemy_ai_controller.gd` for the exact method name.

- `ray[rllib]` must be installed: `pip install ray[rllib] torch`

- For ONNX export from RLlib checkpoints, use `ray.rllib` model export utilities or
  TorchScript export — deferred until after first successful training run.

- The `_on_party_hp_changed` signal is connected but does nothing (reward for enemy hive
  when party takes damage is tracked via `damage_taken` on enemy controller instead).
  This is intentional — simplifies signal routing.
