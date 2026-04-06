# rl_enemy_hive_agent.gd
class_name RLEnemyHiveAgent
extends AIController3D

## Enemy hive mind agent (one per enemy, shared policy weights).
## Adversarial to party agents.

@export var enemy_controller: EnemyAIController

const MAX_OBS_DIST: float = 20.0
## self(3) + party×2(10) + enemy_allies×2(8) = 21
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
		enemy_controller.damage_dealt.connect(_on_damage_dealt)

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

	# Party members × 2 (10): hp, dist, alive, rel_x, rel_z
	var party: Array = _context.get("party", [])
	var party_count: int = 0
	for member_state in party:
		if party_count >= 2: break
		if is_instance_valid(member_state):
			var member_body: Node3D = member_state.get_parent() as Node3D
			var rel: Vector3 = (member_body.global_position - self_pos) if member_body else Vector3.ZERO
			var dist: float = self_pos.distance_to(member_body.global_position) if member_body else 0.0
			obs.append(member_state.get_hp_ratio())
			obs.append(clampf(dist / MAX_OBS_DIST, 0.0, 1.0))
			obs.append(1.0 if member_state.get("is_alive") else 0.0)
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
		if is_instance_valid(ally) and ally != enemy_controller:
			var rel: Vector3 = ally.global_position - self_pos
			obs.append(ally.get_hp_ratio() if ally.has_method("get_hp_ratio") else 0.0)
			obs.append(1.0 if ally.get("is_alive") else 0.0)
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
				var target = enemy_controller.call("_get_target_state")
				if target:
					enemy_controller.call("_execute_skill", act - 1, target)
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
