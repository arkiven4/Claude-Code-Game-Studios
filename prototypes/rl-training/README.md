# RL Training Prototype

**Hypothesis:** Can a multi-agent PPO setup train Evan + Evelyn to fight as a coordinated party against 3 enemies (Grunt, Archer, Mage)?

**Status:** In progress

---

## Setup

Install Python dependencies (only once):

```bash
pip install ray[rllib] torch godot-rl
```

---

## How to Train

Training requires two terminals running at the same time.

**Terminal 1 — Start Python trainer first:**

```bash
cd /home/arkiven4/Documents/Project/Other/myvampire
python3.10 prototypes/rl-training/train.py
```

Wait until you see:
```
Waiting for Godot to connect on port 11008 ...
```

**Terminal 2 — Launch Godot headless:**

```bash
cd /home/arkiven4/Documents/Project/Other/myvampire
godot --headless -- res://prototypes/rl-training/TrainingArena.tscn --speedup=10 --fixed-fps=2000 --disable-render-loop
```

Training runs for 500 iterations. Progress prints every 10 iterations. Checkpoints save every 50 iterations to `prototypes/rl-training/models/`.

Stop training at any time with **Ctrl+C** in Terminal 1.

---

## Agents

| Agent | Policy | Obs Size | Action Space |
|-------|--------|----------|--------------|
| Evan | `evan_policy` | 46 | `action` (9) + `heal_target` (2) |
| Evelyn | `evelyn_policy` | 46 | `action` (9) + `heal_target` (2) |
| TeamAI | `team_policy` | 33 | `evan_target/role` + `evelyn_target/role` |

**Action meanings (`action`):**
- `0` = wait
- `1–4` = skill slots
- `5` = move toward target enemy
- `6` = move away from nearest enemy
- `7` = move toward lowest-HP ally
- `8` = hold position

**`heal_target`** (only used when action 1–4 triggers a `SINGLE_ALLY` skill):
- `0` = heal self
- `1` = heal lowest-HP ally

---

## Enemies

3 enemies spawn each episode:
- **Grunt** (front-left) — melee
- **Archer** (back-right) — ranged
- **Mage** (back-center) — slow debuff

---

## Findings

*(Update this when training concludes)*
