# RL Agent Observation Specification

## Overview

Each agent observes the game state from their perspective. Observations are **normalized float32 arrays** sent to neural networks at each game step.

---

## Party Agents (Evan & Evelyn) — 54 Dimensions

**Code**: `RLPartyAgent.get_obs()` in `src/ai/rl_party_agent.gd`

### Structure

| Section | Dims | Description |
|---------|------|-------------|
| **Self** | 10 | Character status |
| **Casting** | 2 | Spell execution state |
| **Allies** | 15 | Up to 3 party members |
| **Enemies** | 20 | Up to 4 enemies |
| **Directive** | 7 | Team coordinator commands |
| **TOTAL** | **54** | |

### Detailed Breakdown

#### Self (10 dims)
```
[0]     hp_ratio              [0.0-1.0]  Current HP / Max HP
[1]     mp_ratio              [0.0-1.0]  Current MP / Max MP
[2-5]   skill_cd[0-3]_ratio   [0.0-1.0]  Cooldown / max_cooldown for each skill slot
[6-9]   can_use[0-3]          [0.0, 1.0] Boolean: is skill ready now?
```

#### Casting (2 dims)
```
[10]    is_casting            [0.0, 1.0] Boolean: currently executing a spell?
[11]    cast_progress         [0.0-1.0]  Spell completion (0=start, 1=done)
```

#### Allies (15 dims) — Up to 3 allies, 5 dims each
```
For each of 3 allies (or zero-padded):
  [12+i*5]      hp_ratio           [0.0-1.0]  Ally HP / Max HP
  [13+i*5]      mp_ratio           [0.0-1.0]  Ally MP / Max MP
  [14+i*5]      alive              [0.0, 1.0] Boolean: alive?
  [15+i*5]      rel_x              [-1.0-1.0] Relative X / MAX_OBS_DIST (20m)
  [16+i*5]      rel_z              [-1.0-1.0] Relative Z / MAX_OBS_DIST

Dead allies are zero-padded (alive=0 signals network to ignore).
```

#### Enemies (20 dims) — Up to 4 enemies, 5 dims each
```
For each of 4 enemies (or zero-padded):
  [27+i*5]      hp_ratio           [0.0-1.0]  Enemy HP / Max HP
  [28+i*5]      distance            [0.0-1.0]  Distance / MAX_OBS_DIST
  [29+i*5]      alive              [0.0, 1.0] Boolean: alive?
  [30+i*5]      rel_x              [-1.0-1.0] Relative X / MAX_OBS_DIST
  [31+i*5]      rel_z              [-1.0-1.0] Relative Z / MAX_OBS_DIST

Dead enemies are zero-padded.
```

#### Directive (7 dims) — Commands from Team Coordinator
```
[47-50]   focus_target one-hot [0.0-1.0]  Which enemy to focus? (4 slots)
          - Index 0-2: enemy 0-2
          - Index 3: no focus
[51-53]   role_mode one-hot    [0.0-1.0]  What role? (3 slots)
          - Index 0: ATTACK
          - Index 1: DEFEND
          - Index 2: SUPPORT
```

**Example**: `[0,0,1,0, 1,0,0]` = focus enemy 2, ATTACK role

---

## Team Agent — 33 Dimensions

**Code**: `RLTeamAgent.get_obs()` in `src/ai/rl_team_agent.gd`

### Structure

| Section | Dims | Description |
|---------|------|-------------|
| **Evan State** | 3 | Evan's status |
| **Evelyn State** | 3 | Evelyn's status |
| **Enemies** | 20 | Up to 4 enemies |
| **Combat State** | 3 | Battle metrics |
| **Memory** | 4 | Last directives issued |
| **TOTAL** | **33** | |

### Detailed Breakdown

#### Evan State (3 dims)
```
[0]     hp_ratio              [0.0-1.0]  Evan's HP / Max HP
[1]     mp_ratio              [0.0-1.0]  Evan's MP / Max MP
[2]     alive                 [0.0, 1.0] Boolean: Evan alive?
```

#### Evelyn State (3 dims)
```
[3]     hp_ratio              [0.0-1.0]  Evelyn's HP / Max HP
[4]     mp_ratio              [0.0-1.0]  Evelyn's MP / Max MP
[5]     alive                 [0.0, 1.0] Boolean: Evelyn alive?
```

#### Enemies (20 dims) — Up to 4 enemies, 5 dims each
```
For each of 4 enemies (or zero-padded):
  [6+i*5]       hp_ratio           [0.0-1.0]  Enemy HP / Max HP
  [7+i*5]       distance           [0.0-1.0]  Distance / MAX_OBS_DIST
  [8+i*5]       alive              [0.0, 1.0] Boolean: alive?
  [9+i*5]       rel_x              [-1.0-1.0] Relative X from Evan's pos
  [10+i*5]      rel_z              [-1.0-1.0] Relative Z from Evan's pos

Dead enemies are zero-padded.
```

#### Combat State (3 dims)
```
[26]    step_normalized       [0.0-1.0]  Current step / max_episode_steps
[27]    alive_party_ratio     [0.0-1.0]  Alive party members / 2
[28]    alive_enemies_ratio   [0.0-1.0]  Alive enemies / 4
```

#### Memory (4 dims) — Last Directives Issued
```
[29]    evan_target_norm      [0.0-1.0]  target / 3 (0-2=enemy, 3=none)
[30]    evan_role_norm        [0.0-1.0]  role / 2 (0=ATTACK, 1=DEFEND, 2=SUPPORT)
[31]    evelyn_target_norm    [0.0-1.0]  target / 3
[32]    evelyn_role_norm      [0.0-1.0]  role / 2
```

**Purpose**: Helps team agent track its own prior decisions, enabling short-term memory strategies.

---

## Enemy Agents (Hive Mind) — 29 Dimensions

**Code**: `RLEnemyHiveAgent.get_obs()` in `src/ai/rl_enemy_hive_agent.gd`

### Structure

| Section | Dims | Description |
|---------|------|-------------|
| **Self** | 5 | Enemy status |
| **Party** | 14 | Up to 2 party members |
| **Enemy Allies** | 10 | Up to 2 other enemies |
| **TOTAL** | **29** | |

### Detailed Breakdown

#### Self (5 dims)
```
[0]     hp_ratio              [0.0-1.0]  Enemy HP / Max HP
[1]     skill_cd[0]_ratio     [0.0-1.0]  Skill 0 cooldown / max_cooldown
[2]     skill_cd[1]_ratio     [0.0-1.0]  Skill 1 cooldown / max_cooldown
[3]     is_casting            [0.0, 1.0] Boolean: executing a spell?
[4]     cast_progress         [0.0-1.0]  Spell completion (0=start, 1=done)
```

#### Party Members (14 dims) — Up to 2 party members, 7 dims each
```
For each of 2 party members (or zero-padded):
  [5+i*7]       hp_ratio           [0.0-1.0]  Party member HP / Max HP
  [6+i*7]       distance           [0.0-1.0]  Distance / MAX_OBS_DIST
  [7+i*7]       alive              [0.0, 1.0] Boolean: alive?
  [8+i*7]       rel_x              [-1.0-1.0] Relative X / MAX_OBS_DIST
  [9+i*7]       rel_z              [-1.0-1.0] Relative Z / MAX_OBS_DIST
  [10+i*7]      is_casting         [0.0, 1.0] Boolean: party member casting?
  [11+i*7]      mp_ratio           [0.0-1.0]  Party member MP / Max MP

Dead members are zero-padded.
is_casting tells enemy when party is stationary (vulnerable to attack).
mp_ratio tells enemy if Evelyn is low on mana (can't heal — exploit this).
```

#### Enemy Allies (10 dims) — Up to 2 other enemies, 5 dims each
```
For each of 2 enemy allies (or zero-padded):
  [19+i*5]      hp_ratio           [0.0-1.0]  Ally HP / Max HP
  [20+i*5]      distance           [0.0-1.0]  Distance / MAX_OBS_DIST
  [21+i*5]      alive              [0.0, 1.0] Boolean: alive?
  [22+i*5]      rel_x              [-1.0-1.0] Relative X / MAX_OBS_DIST
  [23+i*5]      rel_z              [-1.0-1.0] Relative Z / MAX_OBS_DIST

Dead allies are zero-padded.
```

---

## Constants

```python
MAX_OBS_DIST = 20.0  # World distance beyond which obs is clamped to ±1.0
```

All relative position components are **clamped**:
```
clamp(rel_coord / 20.0, -1.0, 1.0)
```

This ensures agents can see ~20m away but values saturate at sight range.

---

## Normalization

| Type | Range | Meaning |
|------|-------|---------|
| Ratios | [0.0, 1.0] | Health, mana, cooldown percentages |
| Booleans | {0.0, 1.0} | Alive, casting, can_use |
| Distance | [0.0, 1.0] | Normalized by 20m sight range |
| Position | [-1.0, 1.0] | Relative to agent, clamped |

---

## Design Notes

- **Dead unit padding**: Dead allies/enemies are explicitly zero-padded so the network learns to ignore them (alive=0.0 is the signal).
- **Casting state visibility**: Party agents see when enemies are casting (vulnerable). Enemies see when party members are casting and their MP ratio.
- **Relative positions only**: No absolute world positions—only relative vectors. This makes observations translation-invariant.
- **Distance observation**: Party agents observe distance to enemies. Enemy agents observe distance to party (helps with threat assessment).
- **Directive as observation**: Party agents receive directives from the team coordinator as part of their observation, completing the feedback loop.

---

## Example: Party Agent Observing Battle

```
Battle state:
  - Evan: 75% HP, 50% MP, alive, not casting
  - Evelyn: 100% HP, 20% MP, alive, casting
  - Enemy 0: 50% HP, 5m away, alive
  - Enemy 1: 30% HP, 8m away, alive
  - Enemy 2: dead
  - Enemy 3: dead
  - Directive: Focus enemy 0, ATTACK role

Observation (example):
  Self:        [0.75, 0.50, 0.40, 0.80, 1.00, 1.00,  1, 1, 0, 1,  0.0, 0.0]          (10)
  Casting:     [0.0, 0.0]                                                            (2)
  Allies:      [1.0, 0.20, 1.0, -0.2, 0.3,  0, 0, 0, 0, 0,  0, 0, 0, 0, 0]         (15)
  Enemies:     [0.50, 0.25, 1.0, 0.1, -0.2,  0.30, 0.40, 1.0, -0.3, 0.4,
                0.0, 0.0, 0.0, 0.0, 0.0,  0.0, 0.0, 0.0, 0.0, 0.0]                 (20)
  Directive:   [1, 0, 0, 0,  1, 0, 0]                                                (7)

Total: 54 dims
```
