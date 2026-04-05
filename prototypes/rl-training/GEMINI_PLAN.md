# RL Training Prototype — Execution Plan for Gemini

**Goal**: Wire the existing `RLPartyAgent` skeleton to the Godot RL Agents addon, create a
minimal training scene, and write a Python training script. The result should be a working
RL training loop: run Godot headless + Python SB3 → train → export `.onnx`.

**Engine**: Godot 4.6 (GDScript, statically typed)
**RL Framework**: `godot_rl` v0.8.2 + `stable-baselines3` v2.8.0
**Addon already installed**: `addons/godot_rl_agents/` (plugin enabled in project.godot)
**Python**: 3.10, packages installed system-wide via pip

---

## What Already Exists (do NOT recreate)

| Path | Status |
|------|--------|
| `addons/godot_rl_agents/controller/ai_controller_3d.gd` | Ready — base class |
| `addons/godot_rl_agents/sync.gd` | Ready — TCP bridge |
| `src/ai/rl_party_agent.gd` | EXISTS but wrong interface — needs full rewrite |
| `src/ai/party_agent.gd` | Keep as-is — base class for BT path only |
| `src/gameplay/party_member_state.gd` | Ready — has `get_hp_ratio()`, `can_use_skill(i)`, `reset_for_encounter(bool)` |
| `src/gameplay/skill_execution_system.gd` | Ready — has `try_activate_skill(slot, tier)`, emits `damage_dealt(amount, target)` |
| `src/gameplay/enemy_ai_controller.gd` | Ready — has `take_damage(data)`, `is_alive`, `died` signal, uses `queue_free()` on death |
| `assets/data/enemies/grunt_melee.tres` | Ready — `EnemyData` resource for a melee grunt |

---

## Task 1 — Rewrite `src/ai/rl_party_agent.gd`

**Why**: The current file extends `PartyAgent` and uses stub methods (`add_reward`,
`end_episode`). It needs to extend `AIController3D` from the addon, which requires
implementing `get_obs()`, `get_reward()`, `get_action_space()`, and `set_action()`.

**Replace the entire file** with the following content:

```gdscript
# rl_party_agent.gd
class_name RLPartyAgent
extends AIController3D

## RL party agent bridging Godot RL Agents addon to the game's skill/state systems.
## Implements AIController3D interface for training with Stable Baselines 3.
## ADR reference: ADR-0001 (Party AI: RL vs. Behavior Tree)

@export var state: PartyMemberState
@export var skill_execution: SkillExecutionSystem

## Reward shaping — all tunable from Inspector
@export var reward_per_damage: float = 0.001
@export var reward_enemy_kill: float = 1.0
@export var reward_encounter_win: float = 2.0
@export var reward_ally_death: float = -1.0
@export var penalty_per_step: float = -0.001

const MAX_OBS_DISTANCE: float = 20.0
const N_OBS: int = 39  ## self(10) + allies(9) + enemies(20)

var _active_tier: int = 1
var _context: Dictionary = {}

func _ready() -> void:
	super._ready()
	if not state:
		state = get_parent().get_node_or_null("PartyMemberState")
	if not skill_execution:
		skill_execution = get_parent().get_node_or_null("SkillExecutionSystem")
	if skill_execution:
		skill_execution.damage_dealt.connect(_on_damage_dealt)

## Called by TrainingArenaManager each episode reset to inject enemy/ally references.
func set_context(context: Dictionary) -> void:
	_context = context
	if state:
		_active_tier = state.character_data.get_active_tier(state.character_level)

# --- AIController3D required overrides ---

func get_obs() -> Dictionary:
	var obs: Array[float] = []

	if not state:
		obs.resize(N_OBS)
		obs.fill(0.0)
		return {"obs": obs}

	# Self (10): hp_ratio, mp_ratio, 4x cooldown_ratio, 4x can_use_skill
	obs.append(state.get_hp_ratio())
	obs.append(float(state.current_mp) / float(state.max_mp) if state.max_mp > 0 else 0.0)
	for i in range(4):
		var cd: float = state.skill_cooldowns[i] if i < state.skill_cooldowns.size() else 0.0
		var skill: SkillData = state.character_data.skill_slots[i] if i < state.character_data.skill_slots.size() else null
		var max_cd: float = skill.cooldown if skill else 1.0
		obs.append(clampf(cd / max_cd, 0.0, 1.0) if max_cd > 0.0 else 0.0)
	for i in range(4):
		obs.append(1.0 if state.can_use_skill(i) else 0.0)

	# Allies (9): up to 3 x (hp_ratio, mp_ratio, is_alive)
	var allies: Array = _context.get("allies", [])
	var ally_count: int = 0
	for ally in allies:
		if ally_count >= 3:
			break
		if ally and ally != state:
			obs.append(ally.get_hp_ratio() if ally.has_method("get_hp_ratio") else 0.0)
			obs.append(float(ally.current_mp) / float(ally.max_mp) if ally.has_method("get_mp_ratio") else 0.0)
			obs.append(1.0 if ally.is_alive else 0.0)
			ally_count += 1
	while ally_count < 3:
		obs.append(0.0)
		obs.append(0.0)
		obs.append(0.0)
		ally_count += 1

	# Enemies (20): up to 4 x (hp_ratio, dist_norm, is_alive, rel_x_norm, rel_z_norm)
	var enemies: Array = _context.get("enemies", [])
	var enemy_count: int = 0
	var agent_pos: Vector3 = get_parent().global_position if get_parent() else Vector3.ZERO
	for enemy in enemies:
		if enemy_count >= 4:
			break
		if enemy:
			var rel_pos: Vector3 = enemy.global_position - agent_pos
			var dist: float = agent_pos.distance_to(enemy.global_position)
			obs.append(enemy.get_hp_ratio() if enemy.has_method("get_hp_ratio") else 0.0)
			obs.append(clampf(dist / MAX_OBS_DISTANCE, 0.0, 1.0))
			obs.append(1.0 if enemy.is_alive else 0.0)
			obs.append(clampf(rel_pos.x / MAX_OBS_DISTANCE, -1.0, 1.0))
			obs.append(clampf(rel_pos.z / MAX_OBS_DISTANCE, -1.0, 1.0))
			enemy_count += 1
	while enemy_count < 4:
		for _j in range(5):
			obs.append(0.0)
		enemy_count += 1

	return {"obs": obs}

func get_reward() -> float:
	return reward

func get_action_space() -> Dictionary:
	return {
		# 0 = wait, 1 = skill slot 0, 2 = skill slot 1, 3 = skill slot 2, 4 = skill slot 3
		"action": {"size": 5, "action_type": "discrete"},
	}

func set_action(action: Dictionary) -> void:
	if not state or not state.is_alive:
		return
	var act: int = action.get("action", 0)
	if act >= 1 and act <= 4:
		if skill_execution:
			skill_execution.try_activate_skill(act - 1, _active_tier)
	reward += penalty_per_step

func reset() -> void:
	super.reset()
	reward = 0.0

# --- Reward signal handlers (called by TrainingArenaManager) ---

func on_enemy_killed() -> void:
	reward += reward_enemy_kill

func on_encounter_won() -> void:
	reward += reward_encounter_win
	done = true

func on_ally_died() -> void:
	reward += reward_ally_death
	done = true

# --- Internal ---

func _on_damage_dealt(amount: int, _target: Node) -> void:
	reward += amount * reward_per_damage
```

---

## Task 2 — Create `prototypes/rl-training/training_arena_manager.gd`

This script manages episode resets and wires reward signals. It runs as the root node
script of `TrainingArena.tscn`.

**Create new file** `prototypes/rl-training/training_arena_manager.gd`:

```gdscript
# training_arena_manager.gd
# Manages RL training episodes: spawns agents/enemies, resets on episode end.
# Attached to the root node of TrainingArena.tscn.
extends Node3D

@export var agent_character_data: CharacterData
@export var enemy_data: EnemyData
@export var enemy_spawn_count: int = 1

@onready var _rl_agent: RLPartyAgent = $AgentBody/RLPartyAgent
@onready var _agent_state: PartyMemberState = $AgentBody/PartyMemberState
@onready var _enemy_container: Node3D = $EnemyContainer

var _enemies: Array[EnemyAIController] = []
var _episode_active: bool = false

func _ready() -> void:
	_start_episode()

func _process(_delta: float) -> void:
	if not _episode_active:
		return

	# Check win condition: all enemies dead
	var all_dead := true
	for enemy in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive:
			all_dead = false
			break

	if all_dead:
		_rl_agent.on_encounter_won()
		_episode_active = false
		await get_tree().create_timer(0.2).timeout
		_reset_episode()

	# Check lose condition: agent dead
	if _agent_state and not _agent_state.is_alive:
		_rl_agent.on_ally_died()
		_episode_active = false
		await get_tree().create_timer(0.2).timeout
		_reset_episode()

	# Force episode end after timeout (safety net)
	if _rl_agent.needs_reset:
		_reset_episode()

func _start_episode() -> void:
	_spawn_enemies()
	_setup_context()
	_episode_active = true

func _reset_episode() -> void:
	# Reset agent state
	if _agent_state:
		_agent_state.reset_for_encounter(true)

	# Clear and re-spawn enemies
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	await get_tree().process_frame

	_rl_agent.reset()
	_start_episode()

func _spawn_enemies() -> void:
	var enemy_scene := preload("res://assets/scenes/enemies/GruntMelee.tscn")
	for i in range(enemy_spawn_count):
		var enemy: EnemyAIController = enemy_scene.instantiate()
		_enemy_container.add_child(enemy)
		# Spread enemies slightly
		enemy.global_position = Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(4.0, 8.0))
		enemy.died.connect(_on_enemy_died.bind(enemy))
		_enemies.append(enemy)

func _setup_context() -> void:
	_rl_agent.set_context({
		"allies": [],         # Solo agent — no allies in this training scene
		"enemies": _enemies,
	})
	# Point enemy AI at the agent body
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy._current_target = $AgentBody

func _on_enemy_died(_enemy: EnemyAIController) -> void:
	_rl_agent.on_enemy_killed()
```

---

## Task 3 — Create `prototypes/rl-training/TrainingArena.tscn`

Build the scene in Godot Editor (or write the .tscn text). The scene tree must be:

```
TrainingArena (Node3D) ← script: training_arena_manager.gd
├── Sync (Node) ← script: res://addons/godot_rl_agents/sync.gd
│     control_mode = 1  (TRAINING)
│     speed_up = 10.0
├── WorldEnvironment
├── DirectionalLight3D
│     rotation_degrees = Vector3(-45, 45, 0)
├── Floor (StaticBody3D)
│     └── CollisionShape3D (BoxShape3D, size 30x0.2x30)
│     └── MeshInstance3D (BoxMesh, size 30x0.2x30, flat gray material)
├── AgentBody (CharacterBody3D)  ← position (0, 0.5, 0)
│     └── CollisionShape3D (CapsuleShape3D radius=0.4, height=1.8)
│     └── MeshInstance3D (CapsuleMesh — blue flat color material)
│     └── PartyMemberState (Node) ← script: party_member_state.gd
│           character_data: [assign Evan's CharacterData .tres]
│           character_level: 1
│     └── SkillExecutionSystem (Node) ← script: skill_execution_system.gd
│           state: (NodePath to PartyMemberState sibling)
│     └── RLPartyAgent (Node3D) ← script: rl_party_agent.gd
│           control_mode = INHERIT_FROM_SYNC (0)
│           reset_after = 2000
│           state: (NodePath to PartyMemberState sibling)
│           skill_execution: (NodePath to SkillExecutionSystem sibling)
└── EnemyContainer (Node3D)  ← enemies spawned here at runtime
```

**TrainingArenaManager @export wiring** (set in Inspector on root node):
- `enemy_data`: `res://assets/data/enemies/grunt_melee.tres`
- `enemy_spawn_count`: `1`

**Sync node settings** (set in Inspector):
- `control_mode`: `TRAINING` (value 1)
- `speed_up`: `10.0` (10× faster than real-time during training)

---

## Task 4 — Create `prototypes/rl-training/train.py`

**Create new file** `prototypes/rl-training/train.py`:

```python
"""
RL training script for myvampire party AI.
Uses godot_rl v0.8.2 + stable-baselines3 v2.8.0.

Prerequisites:
  pip install godot-rl-agents stable-baselines3 torch

Usage (two terminals):
  Terminal 1 (Python — start first):
    cd prototypes/rl-training
    python train.py

  Terminal 2 (Godot — start after Python prints "waiting for env"):
    godot --headless -- res://prototypes/rl-training/TrainingArena.tscn \
      --speedup=10 --fixed-fps=2000 --disable-render-loop

After training, the model is saved to:
  prototypes/rl-training/models/party_agent.zip
  prototypes/rl-training/models/party_agent.onnx
"""

import os
import sys
from godot_rl.core.godot_env import GodotEnv
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CheckpointCallback

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

MODEL_PATH = os.path.join(MODELS_DIR, "party_agent")
ONNX_PATH  = os.path.join(MODELS_DIR, "party_agent.onnx")
LOG_DIR    = os.path.join(os.path.dirname(__file__), "logs")
TOTAL_STEPS = 500_000


def train():
    print("Starting training server — waiting for Godot to connect on port 11008...")
    print("Launch Godot now with TrainingArena.tscn in headless mode.")

    env = StableBaselinesGodotEnv(
        env_path=None,   # We launch Godot manually
        port=11008,
        n_parallel=1,
        seed=42,
    )

    checkpoint_cb = CheckpointCallback(
        save_freq=50_000,
        save_path=MODELS_DIR,
        name_prefix="party_agent_ckpt",
    )

    model = PPO(
        "MlpPolicy",
        env,
        verbose=1,
        tensorboard_log=LOG_DIR,
        n_steps=2048,
        batch_size=64,
        learning_rate=3e-4,
        ent_coef=0.01,
    )

    model.learn(
        total_timesteps=TOTAL_STEPS,
        callback=checkpoint_cb,
    )

    model.save(MODEL_PATH)
    print(f"Model saved to {MODEL_PATH}.zip")

    # Export to ONNX for Godot inference
    try:
        from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx
        export_model_as_onnx(model, ONNX_PATH)
        print(f"ONNX model exported to {ONNX_PATH}")
    except Exception as e:
        print(f"ONNX export failed: {e}")
        print("Training complete. Export ONNX manually if needed.")

    env.close()


if __name__ == "__main__":
    train()
```

---

## Task 5 — Verify the Godot plugin is enabled

Open `project.godot` and confirm this entry exists under `[editor_plugins]`:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_rl_agents/godot_rl_agents.gd", ...)
```

If `godot_rl_agents` is not listed, enable it via **Project → Project Settings → Plugins**
in the Godot Editor.

---

## How to Run Training

### Step 1 — Start Python server
```bash
cd /home/arkiven4/Documents/Project/Other/myvampire
python3.10 prototypes/rl-training/train.py
```
Wait until it prints: `waiting for Godot to connect on port 11008`

### Step 2 — Launch Godot in headless training mode
```bash
godot --headless -- res://prototypes/rl-training/TrainingArena.tscn \
  --speedup=10 --fixed-fps=2000 --disable-render-loop
```

Training will run for 500,000 steps. With `speed_up=10` this takes roughly
10–20 minutes depending on CPU.

### Step 3 — Monitor
```bash
# In a third terminal (optional tensorboard):
tensorboard --logdir prototypes/rl-training/logs
```

### Step 4 — After training
The ONNX model will be at `prototypes/rl-training/models/party_agent.onnx`.
Copy it to `assets/data/ai/` for use in the production scene.
To use it in Godot, set the `Sync` node's `control_mode` to `ONNX_INFERENCE` and
set `onnx_model_path` to the `.onnx` file path on the `RLPartyAgent` node.

---

## Acceptance Criteria

- [ ] `src/ai/rl_party_agent.gd` compiles with no errors in Godot 4.6
- [ ] `TrainingArena.tscn` opens without errors; scene tree matches spec above
- [ ] Running `python3.10 train.py` prints the waiting message and holds open
- [ ] Launching Godot with `TrainingArena.tscn` in headless mode connects to Python (handshake log appears)
- [ ] Training steps increment in Python terminal output
- [ ] `models/party_agent.zip` and `models/party_agent.onnx` exist after training completes

---

## Known Risks / Notes

- `EnemyAIController._die()` calls `queue_free()` — `TrainingArenaManager` must check
  `is_instance_valid(enemy)` before accessing a dead enemy node (already done in the script above).
- `GruntMelee.tscn` is expected at `res://assets/scenes/enemies/GruntMelee.tscn`. If the
  path differs, update `_spawn_enemies()` in `training_arena_manager.gd`.
- Evan's `CharacterData` resource must be assigned manually in the Inspector on the
  `PartyMemberState` node inside `AgentBody`. Use `res://assets/data/characters/evan.tres`
  (or whatever the correct path is — check `assets/data/`).
- The `SkillExecutionSystem` needs its `state` NodePath set to the `PartyMemberState` sibling.
  Wire this in the Inspector on `AgentBody/SkillExecutionSystem`.
- If Godot can't find `ONNXModel` during export, the GDNative ONNX wrapper may need the
  `.gdextension` binary for your platform. Check `addons/godot_rl_agents/onnx/` for platform
  binaries — if missing, the ONNX inference step can be skipped for now (training still works).
