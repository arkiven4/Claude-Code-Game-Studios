# rl_enemy_hive_agent.gd
class_name RLEnemyHiveAgent
extends AIController3D

## Enemy hive mind agent (one per enemy, shared policy weights).
## Adversarial to party agents.

@export var enemy_controller: EnemyAIController

const MAX_OBS_DIST: float = 20.0
## self(5) + party×2(10) + enemy_allies×2(10: hp,dist,alive,rel_x,rel_z) = 25
const N_OBS: int = 25

## Pending movement action — executed by rl_arena_manager
var pending_move_action: int = 0

var _context: Dictionary = {}

func _ready() -> void:
	super._ready()
	if not enemy_controller:
		enemy_controller = get_parent() as EnemyAIController
	if enemy_controller:
		enemy_controller.damage_taken.connect(_on_damage_taken)
		enemy_controller.damage_dealt.connect(_on_damage_dealt)
		enemy_controller.skill_fired.connect(_on_skill_fired)
		enemy_controller.projectile_spawned.connect(_on_projectile_spawned)

func _on_projectile_spawned(projectile: Projectile) -> void:
	projectile.hit.connect(_on_projectile_hit)
	projectile.missed.connect(_on_projectile_missed)

func _on_projectile_hit(_target: Node) -> void:
	reward += 0.02

func _on_projectile_missed(target: Node) -> void:
	# Called only for our OWN projectiles (connected in _on_projectile_spawned).
	# target is the intended party member — we missed, apply miss penalty.
	reward -= 0.01

## Called for PARTY projectiles only (connected by rl_arena_manager).
## Only gives a dodge reward when this enemy was the intended target.
## Does NOT penalise — all hive agents are connected and the non-targeted
## ones would receive a false miss penalty if the generic handler were used.
func _on_party_projectile_missed(target: Node) -> void:
	if target == enemy_controller:
		reward += 0.05  # Dodge reward

func _on_skill_fired(_index: int, skill: SkillData) -> void:
	if skill.is_projectile:
		reward += 0.005 # Small intent reward, bulk comes from hit
	else:
		reward += 0.01  ## Reward for finishing a cast

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
	obs.append(enemy_controller.get_hp_ratio() if enemy_controller.has_method("get_hp_ratio") else 0.0)
	var cds: Array = enemy_controller.get("_skill_cooldowns") if enemy_controller.get("_skill_cooldowns") != null else []
	obs.append(clampf(cds[0] / 5.0, 0.0, 1.0) if cds.size() > 0 else 0.0)
	obs.append(clampf(cds[1] / 5.0, 0.0, 1.0) if cds.size() > 1 else 0.0)

	# Casting (2): is_casting, progress
	obs.append(1.0 if enemy_controller.is_casting() else 0.0)
	obs.append(enemy_controller.get_cast_progress())

	# Party members × 2 (10): hp, dist, alive, rel_x, rel_z
	# Dead members are zero-padded — alive=0.0 tells the network to ignore the entry.
	var party: Array = _context.get("party", [])
	var party_count: int = 0
	for member_state in party:
		if party_count >= 2: break
		if is_instance_valid(member_state):
			if member_state.get("is_alive"):
				var member_body: Node3D = member_state.get_parent() as Node3D
				var rel: Vector3 = (member_body.global_position - self_pos) if member_body else Vector3.ZERO
				var dist: float = self_pos.distance_to(member_body.global_position) if member_body else 0.0
				obs.append(member_state.get_hp_ratio())
				obs.append(clampf(dist / MAX_OBS_DIST, 0.0, 1.0))
				obs.append(1.0)
				obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
				obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			else:
				for _j in range(5): obs.append(0.0)
			party_count += 1
	while party_count < 2:
		for _j in range(5): obs.append(0.0)
		party_count += 1

	# Other enemies × 2 (10): hp, dist, alive, rel_x, rel_z
	# Dead allies zero-padded. Added dist (was missing vs party obs — now consistent).
	var allies: Array = _context.get("enemy_allies", [])
	var ally_count: int = 0
	for ally in allies:
		if ally_count >= 2: break
		if is_instance_valid(ally) and ally != enemy_controller:
			if ally.get("is_alive"):
				var rel: Vector3 = ally.global_position - self_pos
				obs.append(ally.get_hp_ratio() if ally.has_method("get_hp_ratio") else 0.0)
				obs.append(clampf(self_pos.distance_to(ally.global_position) / MAX_OBS_DIST, 0.0, 1.0))
				obs.append(1.0)
				obs.append(clampf(rel.x / MAX_OBS_DIST, -1.0, 1.0))
				obs.append(clampf(rel.z / MAX_OBS_DIST, -1.0, 1.0))
			else:
				for _j in range(5): obs.append(0.0)
			ally_count += 1
	while ally_count < 2:
		for _j in range(5): obs.append(0.0)
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
			if enemy_controller.is_casting():
				reward -= 0.001
				return
			var skill_idx: int = act - 1
			var cds: Array = enemy_controller.get("_skill_cooldowns")
			if cds and skill_idx < cds.size() and cds[skill_idx] > 0.0:
				reward -= 0.001  ## Penalty for trying to use a skill still on cooldown
				return
			if enemy_controller.enemy_data and skill_idx < enemy_controller.enemy_data.skill_list.size():
				var target = enemy_controller.call("_get_target_state")
				if target:
					enemy_controller.call("_execute_skill", skill_idx, target)
		3, 4, 5:
			if enemy_controller.is_casting():
				reward -= 0.001
				return
			pending_move_action = act
		_:
			reward -= 0.001  ## idle penalty

func reset() -> void:
	super.reset()
	reward = 0.0
	pending_move_action = 0

# --- Reward callbacks ---

func _on_damage_dealt(amount: int, _target: Node) -> void:
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
