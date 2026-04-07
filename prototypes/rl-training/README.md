# RL Training Prototype

**Hypothesis:** Can multi-agent adversarial PPO train Evan + Evelyn to fight as a coordinated party against 3 enemies (Grunt, Archer, Mage), while enemies simultaneously learn to counter the party?

**Status:** In progress — self-play adversarial training running.

---

## How to Run

> **Important:** The scene path must come **before** `--`. Everything after `--` is read by godot_rl as user args.

### 1. Standard Training (One Arena)
**Terminal 1:** `python3.10 prototypes/rl-training/train.py`
**Terminal 2:** `godot --headless res://prototypes/rl-training/TrainingArena.tscn -- --speedup=10`

### 2. Vectorized Training (Fastest — recommended)
Runs N arenas in one Godot process. 8× more experience per wall-clock second vs single arena.
**Terminal 1:** `python3.10 prototypes/rl-training/train_vectorized.py`
**Terminal 2:** `godot --headless res://prototypes/rl-training/VectorizedTraining.tscn -- --n_arenas=8 --speedup=10`

Start **Python first**. Launch Godot only after Python prints "Waiting for Godot to connect..."

### 3. Inference & Validation
To test your trained agents and see their performance:
1.  **Identify Checkpoint:** Find your model in `prototypes/rl-training/models/`.
2.  **Start Python:**
	```bash
	python3 prototypes/rl-training/inference.py --checkpoint prototypes/rl-training/models/checkpoint_000XXX
	```
3.  **Start Godot:**
	```bash
	godot -- res://prototypes/rl-training/InferenceArena.tscn --port=11009
	```

---

## Monitoring Win Rate
The HUD in both Training and Inference arenas now displays a **Win Rate** counter:
- **Calculation:** `(Party Victories / Total Episodes) * 100`
- **Inference Terminal:** The `inference.py` console will also print the result of every episode:
  `Episode 10 finished. Win: True. Win Rate: 80.0%`
- **Target:** A stable win rate above 80% indicates the party has learned effective coordination.

---

## File Map

| File | Purpose |
|------|---------|
| `train.py` | Python: RLlib PPO config for single-arena training |
| `train_vectorized.py` | Python: RLlib PPO config for N-arena vectorized training |
| `TrainingArena.tscn` | Godot: single arena with all 6 agents pre-placed as static nodes |
| `VectorizedTraining.tscn` | Godot: root scene that spawns N TrainingArena instances in a grid, shared Sync node |
| `vectorized_training.gd` | Spawns arenas, strips embedded Sync/HUD per arena, adds one shared Sync node |
| `rl_arena_manager.gd` | Episode logic: reset, rewards, curriculum, damage-progress tracking |
| `rl_party_agent.gd` | Per-character agent: obs, actions, reward for Evan/Evelyn |
| `rl_team_agent.gd` | High-level coordinator: outputs target/role directives to party agents |
| `rl_enemy_hive_agent.gd` | Enemy agent: obs, actions, reward (shared policy across all 3 enemies) |
| `rl_enemy_controller.gd` | Training-only subclass of EnemyAIController — forces `rl_controlled=true`, overrides `_die()` to skip `queue_free()` |
| `models/` | Saved RLlib checkpoints |

---

## Agent Architecture

6 agents train simultaneously across 4 policies:

| Agent ID | Policy | Obs | Action Space | Role |
|----------|--------|-----|--------------|------|
| `evan` | `evan_policy` | 54 floats | `action`(11) + `heal_target`(2) | Party tanker |
| `evelyn` | `evelyn_policy` | 54 floats | `action`(11) + `heal_target`(2) | Party mage |
| `team` | `team_policy` | 33 floats | `evan_target`(4) + `evan_role`(3) + `evelyn_target`(4) + `evelyn_role`(3) | High-level coordinator |
| `enemy_0` | `enemy_hive_policy` | 25 floats | `action`(6) | Grunt (melee) |
| `enemy_1` | `enemy_hive_policy` | 25 floats | `action`(6) | Archer (ranged) |
| `enemy_2` | `enemy_hive_policy` | 25 floats | `action`(6) | Mage |

**Enemies share one policy** (`enemy_hive_policy`) — one brain controls all 3 bodies.
**Self-play adversarial**: party and enemies train against each other simultaneously.

### Action Meanings

**Party `action`:**
- `0` = wait (idle penalty applied)
- `1–4` = skill slots 0–3
- `5–8` = movement (toward target, away from enemy, toward ally, hold)
- `9` = basic attack
- `10` = special

**Party `heal_target`** (used when skill is `SINGLE_ALLY` type):
- `0` = target self
- `1` = target lowest-HP ally

**Enemy `action`:**
- `0` = wait (idle penalty applied)
- `1` = skill slot 0
- `2` = skill slot 1
- `3` = move toward nearest party member
- `4` = reposition away from party
- `5` = move toward lowest-HP party member

---

## Observation Spaces

### Party agent (54 floats)
```
Self (10):     hp_ratio, mp_ratio, cooldown×4, can_use×4
Casting (2):   is_casting, cast_progress
Allies (15):   up to 3 × (hp, mp, alive, rel_x, rel_z)  — dead allies zero-padded
Enemies (20):  up to 4 × (hp, dist, alive, rel_x, rel_z) — dead enemies zero-padded
Directive (7): focus_target one-hot×4, role_mode one-hot×3
```

### Team agent (33 floats)
```
Evan (3):      hp, mp, alive
Evelyn (3):    hp, mp, alive
Enemies (20):  up to 4 × (hp, dist, alive, rel_x, rel_z)
Combat (3):    step_norm, alive_party_ratio, alive_enemy_ratio
Memory (4):    last evan_target, evan_role, evelyn_target, evelyn_role
```

### Enemy hive agent (25 floats)
```
Self (5):            hp_ratio, skill0_cd_ratio, skill1_cd_ratio, rel_x, rel_z
Party ×2 (10):       hp, dist, alive, rel_x, rel_z  (per member — dead zero-padded)
Enemy allies ×2 (10): hp, dist, alive, rel_x, rel_z (other enemies — dead zero-padded)
```

---

## Reward Structure

### Party rewards
| Event | Reward |
|-------|--------|
| Damage dealt to enemy | `+amount × 0.001` (per agent) |
| Damage received | `-amount × 0.0003` |
| Skill hit landed | `+0.005` |
| Enemy killed | `+0.5 × w_team (0.4)` |
| All enemies dead (victory) | `+5.0` (team), `+done` |
| Party wiped (defeat) | `-5.0` (team), `+done` |
| Ally died | `-1.5` (team) |
| Survival per step | `+0.01 × alive_ratio` |
| Evan protection bonus | `+0.003` (Evan between enemy and Evelyn) |
| Stagnation (no damage for 60 steps, not recovering) | `-0.002` per step |

### Enemy rewards
| Event | Reward |
|-------|--------|
| Damage dealt | `+amount × 0.001` |
| Damage received | `-amount × 0.0005` |
| Party member killed | `+1.0` |
| Party wiped (win) | `+3.0` + done |
| All enemies dead (loss) | `-3.0` + done |
| Idle (action=0) | `-0.001` |
| Stagnation (no damage for 60 steps, not injured) | `-0.002` per step |

---

## Scene Layout

```
z = -5   [Evan]      [Evelyn]     ← party spawn (~13 units from nearest enemy)
z =  0   (arena center)
z =  8   [Grunt]     [Archer]     ← enemy spawn
z = 11          [Mage]
```

Party starts outside enemy aggro range (default 10 units) so agents must learn to approach before combat begins.

---

## Critical Architecture Decisions

### 1. Static enemies (not dynamically spawned)
Enemies are **pre-placed in TrainingArena.tscn** as static nodes. Do NOT move them back to dynamic spawning.

**Why:** godot_rl's `sync.gd` collects all agents once at startup via `get_tree().get_nodes_in_group("AGENT")`, which fires after `root.ready`. Dynamically spawned enemies (added via `await get_tree().process_frame`) register with the AGENT group *after* this collection — they become invisible to godot_rl and never get trained.

### 2. RLEnemyController — no `queue_free()` on death
`rl_enemy_controller.gd` overrides `EnemyAIController._die()` to suppress `queue_free()`. The enemy just sets `is_alive = false`.

**Why:** godot_rl holds live references to hive agent nodes in `agents_training`. If the enemy node is freed, its hive agent child is freed too, leaving dangling null references that crash godot_rl mid-episode. `reset_to_start()` restores the enemy state between episodes instead.

### 3. Episode reset triggered by Python, not by timer
`_end_episode()` only sets `done=true` on all agents. It does NOT call `_reset_episode()`. The reset is triggered by `_evan_agent.needs_reset` in `_physics_process()`.

**Why:** The old pattern used `await create_timer(0.1)` then auto-reset. This caused Godot to start a new episode while Python/RLlib still thought it was in the old one — RLlib would catch steps from two episodes in the same trajectory batch and crash with `"Batches sent to postprocessing must only contain steps from a single trajectory"`.

**Correct flow:**
```
Godot: episode ends → all agents done=true
Python (RLlib): receives done → calls env.reset()
Python (godot_rl): sends "reset" message to Godot
Godot (sync.gd): sets agent.needs_reset = true on all agents
Godot (arena_manager): sees needs_reset in _physics_process → _reset_episode()
Godot (sync.gd): reads fresh obs on same frame → sends reset obs to Python
```

### 4. No mid-episode individual agent termination
When a single enemy dies, we do NOT set `hive.done = true` on its individual agent. All agents terminate together at episode end.

**Why:** If one enemy's agent sends `terminated=True` mid-episode, RLlib removes it from active agents. But godot_rl keeps sending obs for it. This mismatch between Python and Godot's view of active agents causes various sync errors.

### 5. Vectorized sync node must be added before `_ready()` returns

In `VectorizedTraining.tscn`, the shared Sync node must be added at the **end of `_ready()`**, not after `await get_tree().process_frame`.

**Why:** `sync.gd._ready()` does `await get_tree().root.ready` before connecting to Python. `root.ready` fires the moment the top-level scene node's `_ready()` returns. If `vectorized_training.gd._ready()` suspends on any `await` before adding the Sync node, `root.ready` fires without Sync being in the tree. Sync is then added *after* `root.ready` has already fired — its internal await waits for a signal that never comes again → permanent hang, never connects to Python.

`add_child(arena)` during `_ready()` is **synchronous** — all child `_ready()` calls (AIController3D agent registration) complete immediately, so no frame waits are needed.

### 6. `_agent_ids` must be a set, not a list
```python
self._agent_ids = {"evan", "evelyn", "team", "enemy_0", "enemy_1", "enemy_2"}
self.possible_agents = self._agent_ids
```

**Why:** RLlib's `MultiAgentEnv` internally expects `_agent_ids` to be a `set`. Using a `list` triggers the deprecated `get_agent_ids` code path, which causes `KeyError` when RLlib omits some agents from `action_dict` on certain steps.

### 6. `_reset_episode()` is fully synchronous
No `await` calls inside `_reset_episode()`. It must complete in a single frame.

**Why:** It runs inside `_physics_process()` which must return synchronously. The removal of `queue_free()` (replaced by `reset_to_start()`) made this possible — there's nothing to wait for.

---

## Findings

*(Update this when training concludes)*
