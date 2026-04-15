# Procedural Level System

## Overview
A semi-procedural level generator that assembles hand-crafted room chunks into branching chapter maps. Each chapter run produces a unique path layout while preserving authored story anchors (start, junction, boss). Designed to scale to 12 chapters × 6+ maps with minimal per-chapter manual work.

## Player Fantasy
Players feel like each run through a chapter takes a slightly different route — discovering a hidden rest spot on one path, facing harder rooms on another — while story beats (chapter climax, boss fight) always land at the right moment.

## Detailed Rules

### Room Types
| Type | Description | Placement |
|---|---|---|
| `START` | Entry room; has N exits (one per branch) | Always first |
| `COMBAT` | Enemy encounter (fixed spawns) | Even slots in branch |
| `CORRIDOR` | Light traversal, traps or loot | Odd slots in branch |
| `REST` | Heal/save point | Last slot of each branch |
| `JUNCTION` | Branches converge here | Always before BOSS |
| `BOSS` | Chapter climax fight | Always last |

### Graph Structure
```
START
├── Branch 0: [COMBAT, CORRIDOR, ..., REST]
├── Branch 1: [COMBAT, CORRIDOR, ..., REST]
└── Branch N-1: ...
JUNCTION
BOSS
```

### Room Selection
- Combat/Corridor rooms are drawn **randomly without replacement** from each pool per branch.
- If a pool runs out, rooms are re-drawn from the full pool (with wrap).
- Rest rooms are always the final slot before junction (if `rest_rooms` pool is non-empty).

### Replay Behavior
- Passing `seed >= 0` to `generate()` produces the same layout every time — use the chapter run index as seed for deterministic replays.
- Passing `seed = -1` generates a fresh random layout each run.

### Room Activation
- On generation, only the START room is visible and active.
- All other rooms are hidden (`visible = false`, `process_mode = DISABLED`).
- When the player enters an exit Area3D, the generator deactivates the current room and activates the target, teleporting the party to its `entrance_marker`.

## Formulas

**Branch X position:**
```
total_width = (branch_count - 1) × branch_spread_x
branch_x[b] = -total_width / 2 + b × branch_spread_x
```

**Room Z position:**
```
room_z[b][r] = room_spacing_z × (r + 1)      # r = 0-based order in branch
junction_z   = max(room_z) + room_spacing_z
boss_z       = junction_z  + room_spacing_z
```

## Edge Cases
- **Single branch** (`branch_count = 1`): valid — linear path. Junction still placed.
- **Empty pool**: If `combat_rooms` is empty, `push_warning` is emitted and the node is skipped. Generator continues.
- **No `junction_room` set**: Falls back to a random combat room.
- **Exit index out of range**: Clamped to the last valid target — player always proceeds.
- **No `entrance_marker` on room**: Teleport skipped; player stays in place.

## Dependencies
- `ChapterConfig` (.tres) — room pools and layout parameters
- `RoomChunk` — base script on every room .tscn
- `SceneLoader` — not required; generator self-manages room visibility
- `ChapterStateManager` — may hook into `generation_complete` to record visited rooms

## Tuning Knobs
| Parameter | Location | Default | Effect |
|---|---|---|---|
| `branch_count` | ChapterConfig | 2 | Number of parallel paths |
| `rooms_per_branch_min/max` | ChapterConfig | 2–4 | Branch length variance |
| `room_spacing_z` | ProceduralLevelGenerator | 30.0 | Depth between rooms |
| `branch_spread_x` | ProceduralLevelGenerator | 25.0 | Horizontal lane width |

## Acceptance Criteria
- [ ] `generate(-1)` produces a valid graph with START → branches → JUNCTION → BOSS ordering
- [ ] `generate(42)` called twice produces identical world positions
- [ ] Entering an exit Area3D deactivates current room and activates the correct next room
- [ ] Party teleports to `entrance_marker` on room transition
- [ ] No crash when a room pool is empty (warning emitted, generation continues)
- [ ] `branch_count = 1` produces a linear level without errors
- [ ] `branch_count = 3` produces 3 diverging paths that converge at junction
