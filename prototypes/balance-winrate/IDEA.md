# Idea: RL-Assisted Game Balance (Win Rate Targeting)

**Status**: Parked — not current priority. Revisit after combat AI is trained.

---

## Goal

Use automated optimization to tune skill and enemy parameters so that
when both party AI and enemy AI play optimally, the player win rate is **60–70%**.
Difficulty should come from smart enemy mechanics, NOT raw stat walls.

---

## The Two-System Architecture

```
System 1 — Combat AI (in progress: prototypes/rl-training/)
  Trains Evan + Evelyn + Enemy Hive to play optimally
  Output: evan.onnx, evelyn.onnx, enemy_hive.onnx

System 2 — Balance Optimizer (this idea)
  Adjusts numbers in .tres files so that
  optimal AI vs optimal AI → win rate = 60–70%
  Output: balanced .tres parameter values
```

---

## What Gets Tuned

**Skill .tres files** (`assets/data/skills/`):
- `effect_value` (damage/heal amount)
- `cooldown`
- `mp_cost`

**Enemy .tres files** (`assets/data/enemies/`):
- `base_max_hp`, `base_atk`, `base_def`
- per-skill damage and cooldown
- `aggro_range`, `move_speed`

---

## Balance Metrics (not just win rate)

| Metric | Target | Reason |
|--------|--------|--------|
| Win rate | 60–70% | Primary target |
| Battle duration | 30–90 sec | Prevent stomps and stat slogs |
| Party HP at win | 20–60% remaining | Party should feel threatened |
| Skill casts / battle | > 8 | Fight requires active play |
| MP efficiency | > 60% | Skills should matter |

---

## Recommended Approach: Bayesian Optimization (Optuna)

Not RL — Optuna is the right tool here.
Each "trial" runs ~200 headless battles and measures the metrics above.
Optuna learns which parameter adjustments move the score toward target.
Efficient: ~100–200 trials to find good parameters.

RL for the balancer (meta-RL) only pays off if balancing hundreds of
different encounters simultaneously — overkill for this project.

---

## Integration Flow

```
1. Train combat AI (prototypes/rl-training/) → get .onnx models
2. Run balance optimizer with those models + current .tres files
3. Optimizer suggests parameter values → runs headless battles → scores result
4. After convergence, output balanced parameter set
5. Human reviews diff → approves → .tres files updated
```

---

## Open Design Questions (answer before implementing)

- What is the ideal fight length for this game's pacing?
- Is it okay for Evelyn (Mage) to nearly die every fight?
- Should enemies have a minimum skill cast count to feel "active"?
- How many encounter types need balancing at launch? (1 vs many changes scope)
