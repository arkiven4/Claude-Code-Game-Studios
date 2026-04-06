# rl_party_agent.gd
class_name RLPartyAgent
extends AIController3D

## Individual party AI agent (Evan=Tanker, Evelyn=Mage, Witch=Support).
## Extends AIController3D for Godot RL Agents addon.
## ADR reference: ADR-0001 (Party AI: RL vs. Behavior Tree)

enum Role { TANKER, MAGE, SUPPORT }

@export var state: PartyMemberState
@export var skill_execution: SkillExecutionSystem
@export var role: Role = Role.TANKER

## Reward weights — tuned per role via Inspector
@export var w_damage_dealt: float = 0.001
@export var w_damage_received: float = 0.0003
@export var w_skill_hit: float = 0.005
@export var w_heal_given: float = 0.002
@export var w_idle: float = 0.001
@export var w_team: float = 0.4

const MAX_OBS_DIST: float = 20.0
const N_BASE_OBS: int = 41
const N_DIRECTIVE: int = 7
const N_OBS: int = N_BASE_OBS + N_DIRECTIVE  ## 48

var _active_tier: int = 1
var _context: Dictionary = {}

## Current directive from TeamPolicy (set each step by rl_arena_manager)
var directive_target: int = 3   ## 0-2=enemy index, 3=none
var directive_role: int = 0     ## 0=ATTACK, 1=DEFEND, 2=SUPPORT

## Pending movement action for rl_arena_manager to execute
var pending_move_action: int = 0

## Last discrete action received (for rl_arena_manager to read)
var last_action: int = 0

## Heal target for SINGLE_ALLY skills: 0=self, 1=ally (lowest-HP)
var pending_heal_target: int = 1

func _ready() -> void:
	super._ready()
	if not state:
		state = get_parent().get_node_or_null("PartyMemberState")
	if not skill_execution:
		skill_execution = get_parent().get_node_or_null("SkillExecutionSystem")
	if skill_execution:
		skill_execution.damage_dealt.connect(_on_damage_dealt)
		skill_execution.heal_applied.connect(_on_heal_applied)
		skill_execution.skill_cast.connect(_on_skill_cast_complete)
		skill_execution.projectile_spawned.connect(_on_projectile_spawned)

func _on_projectile_spawned(projectile: Projectile) -> void:
	projectile.hit.connect(_on_projectile_hit)
	projectile.missed.connect(_on_projectile_missed)

func _on_projectile_hit(_target: Node) -> void:
	reward += w_skill_hit * 2.0

func _on_projectile_missed(target: Node) -> void:
	# If WE were the target and it missed, we dodged it!
	if target == state:
		reward += w_skill_hit * 1.5 # Dodge reward
	else:
		# We were the caster and we missed
		reward -= w_skill_hit * 1.0

func _on_skill_cast_complete(skill: SkillData) -> void:
	## Reward for completing the cast/skill execution
	# If it's a projectile, we wait for hit/miss signal for the bulk of the reward
	if skill.is_projectile:
		reward += w_skill_hit * 0.5
	else:
		reward += w_skill_hit * 2.0

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
	obs.append(state.get_mp_ratio())
	for i in range(4):
		var cd: float = state.skill_cooldowns[i] if i < state.skill_cooldowns.size() else 0.0
		var skill: SkillData = state.character_data.skill_slots[i] if i < state.character_data.skill_slots.size() else null
		var max_cd: float = skill.base_cooldown if skill else 1.0
		obs.append(clampf(cd / max_cd, 0.0, 1.0) if max_cd > 0.0 else 0.0)
	for i in range(4):
		obs.append(1.0 if state.can_use_skill(i) else 0.0)

	# Casting (2): is_casting, progress
	obs.append(1.0 if state.get("is_casting") else 0.0)
	obs.append(skill_execution.get_cast_progress() if skill_execution else 0.0)

	# Allies (9): up to 3 × (hp, mp, alive)
	var allies: Array = _context.get("allies", [])
	var ally_count: int = 0
	for ally in allies:
		if ally_count >= 3:
			break
		if is_instance_valid(ally) and ally != state:
			obs.append(ally.get_hp_ratio() if ally.has_method("get_hp_ratio") else 0.0)
			obs.append(ally.get_mp_ratio() if ally.has_method("get_mp_ratio") else 0.0)
			obs.append(1.0 if ally.get("is_alive") else 0.0)
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
		if is_instance_valid(enemy):
			var rel: Vector3 = enemy.global_position - agent_pos
			obs.append(enemy.get_hp_ratio() if enemy.has_method("get_hp_ratio") else 0.0)
			obs.append(clampf(agent_pos.distance_to(enemy.global_position) / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if enemy.get("is_alive") else 0.0)
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
		# 0=wait, 1-4=skill slots, 5=move→enemy, 6=move away, 7=move→ally, 8=hold, 9=basic, 10=special
		"action": {"size": 11, "action_type": "discrete"},
		# For SINGLE_ALLY skills: 0=heal self, 1=heal lowest-HP ally
		"heal_target": {"size": 2, "action_type": "discrete"},
	}

func set_action(action: Dictionary) -> void:
	var act: int = action.get("action", 0)
	pending_heal_target = action.get("heal_target", 1)
	last_action = act
	pending_move_action = 0

	if not state or not state.is_alive:
		return

	match act:
		1, 2, 3, 4:
			if state.is_casting:
				reward -= w_idle  ## Penalty for trying to cast while already casting
				return

			if skill_execution:
				var slot: int = act - 1
				var char_data: CharacterData = state.character_data if state else null
				var skill: SkillData = char_data.skill_slots[slot] if char_data and slot < char_data.skill_slots.size() else null
				var hit: bool
				if skill and skill.target_type == SkillData.TargetType.SINGLE_ALLY:
					# Bypass interactive targeting — agent chose self (0) or ally (1)
					hit = skill_execution.execute_skill_rl(slot, _active_tier, pending_heal_target == 0)
				else:
					hit = skill_execution.try_activate_skill(slot, _active_tier)
				if hit:
					reward += w_skill_hit * 0.5  ## Reduced intent reward
		5, 6, 7, 8:
			if state.is_casting:
				reward -= w_idle  ## Penalty for trying to move while casting
				return
			pending_move_action = act
		9, 10:
			if state.is_casting:
				reward -= w_idle
				return
			if skill_execution:
				var hit := skill_execution.try_activate_attack(act == 10, _active_tier)
				if hit:
					reward += w_skill_hit * 0.5
		_:
			reward -= w_idle  ## action=0 or unknown = idle penalty

func reset() -> void:
	super.reset()
	reward = 0.0
	directive_target = 3
	directive_role = 0
	pending_move_action = 0
	last_action = 0
	pending_heal_target = 1

# --- Reward callbacks (called by rl_arena_manager) ---

func add_team_reward(amount: float) -> void:
	reward += amount * w_team

func on_protection_bonus() -> void:
	## Called when Evan (Tanker) is positioned between enemy and Evelyn
	if role == Role.TANKER:
		reward += 0.003

func _on_damage_dealt(amount: int, _target: Node) -> void:
	reward += amount * w_damage_dealt

func _on_heal_applied(amount: int, _target: Node) -> void:
	reward += amount * w_heal_given

func on_damage_received(amount: int) -> void:
	reward -= amount * w_damage_received
