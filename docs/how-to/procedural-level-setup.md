# How To: Set Up Procedural Levels

## Overview

The procedural level system has three layers:

| Layer | How it works | Use for |
|---|---|---|
| **Surface** | Seamless, all zones loaded | Forest, village, beach, desert |
| **Interior** | Door push → scene swap | Buildings, houses |
| **Dungeon** | Door push → procedural rooms | Labyrinths, caves, castles |

---

## Step 1 — Create room/zone templates (.tscn)

Templates are hand-crafted Godot scenes. The generator picks from pools of them.
Greybox starters are in `assets/scenes/templates/` — duplicate and reskin them.

### Dungeon room node structure

```
RoomCombat_Forest_A.tscn
└── Node3D              ← attach room_chunk.gd, set room_type
    ├── Floor           ← StaticBody3D + MeshInstance3D + CollisionShape3D
    ├── EntranceMarker  ← Node3D (named exactly "EntranceMarker")
    ├── Exit_0          ← Node3D (name must start with "Exit_")
    │   └── Area3D
    │       └── CollisionShape3D  ← trigger shape (≈1.5 × 2 × 0.5 m)
    ├── Exit_1          ← (optional second exit, for START / JUNCTION rooms)
    │   └── Area3D
    │       └── CollisionShape3D
    ├── EnemySpawn_0    ← Node3D (your spawner reads these by group or name)
    └── EnemySpawn_1
```

> **Auto-detection:** if you leave `exit_markers` and `entrance_marker` unassigned
> in the Inspector, `room_chunk.gd` will automatically find children named
> `EntranceMarker` and `Exit_*` at runtime.

### Surface zone node structure

```
Zone_Forest_A.tscn
└── Node3D              ← attach surface_zone.gd, set zone_name + biome
    ├── Terrain         ← MeshInstance3D (120 × 120 m flat or sculpted mesh)
    ├── TerrainBody     ← StaticBody3D + CollisionShape3D (floor collision)
    ├── BoundaryArea    ← Area3D + BoxShape3D (120 × 4 × 120 m)  ← REQUIRED name
    ├── EntranceMarker_0 ← Node3D (player spawns here when entering via door)
    ├── Trees           ← Node3D grouping props
    └── EnemySpawn_0
```

### Room type reference

| room_type | Int | Use |
|---|---|---|
| START | 0 | First room; needs Exit_0 and Exit_1 (one per branch) |
| COMBAT | 1 | Enemy encounter |
| CORRIDOR | 2 | Traversal / traps |
| REST | 3 | Heal / save — last in branch |
| JUNCTION | 4 | Branches merge; needs one entrance per branch |
| BOSS | 5 | Final fight |

---

## Step 2 — Create a ChapterConfig (.tres)

1. In Godot Editor FileSystem panel: **Right-click → New Resource → ChapterConfig**
2. Save as `assets/data/chapters/chapter_01_config.tres`
3. Assign `.tscn` files to each pool in the Inspector:

| Field | Assign |
|---|---|
| `start_room` | RoomStart_Greybox.tscn (or your custom one) |
| `boss_room` | RoomBoss_Greybox.tscn |
| `junction_room` | RoomJunction_Greybox.tscn |
| `combat_rooms` | [RoomCombat_A.tscn, RoomCombat_B.tscn, …] |
| `corridor_rooms` | [RoomCorridor_A.tscn, …] |
| `rest_rooms` | [RoomRest_A.tscn] |
| `branch_count` | 2 |
| `rooms_per_branch_min` | 2 |
| `rooms_per_branch_max` | 4 |

A ready-to-use greybox config is at `assets/data/chapters/chapter_01_config.tres`.

---

## Step 3 — Wire the generator in your scene

### Dungeon (door-transition mode)

Place a `TransitionDoor` node on your dungeon entrance in the surface zone:

```
DungeonEntrance (Node3D)
├── TransitionDoor.gd attached
│   target_type = DUNGEON
│   dungeon_config = chapter_01_config.tres
│   dungeon_seed = -1          ← random each visit; set >= 0 to fix layout
│   entrance_marker_name = "EntranceMarker"
│   layer_manager = <WorldLayerManager node>
└── Area3D + CollisionShape3D  ← trigger zone in front of door
```

Inside every dungeon, add one exit door:

```
ExitDoor (Node3D)
├── TransitionDoor.gd attached
│   target_type = SURFACE_EXIT
│   layer_manager = <WorldLayerManager node>
└── Area3D + CollisionShape3D
```

### Surface map (seamless mode)

```gdscript
var gen := ProceduralLevelGenerator.new()
gen.config = preload("res://assets/data/chapters/chapter_01_config.tres")
gen.seamless_mode = true
gen.zone_size = 120.0
add_child(gen)

var surface := gen.generate()   # -1 = random seed
get_tree().current_scene.add_child(surface)

# Register with WorldLayerManager
layer_manager.set_surface_root(surface)
```

### Interior building

Place a `TransitionDoor` on any door mesh:

```
HouseDoor (Node3D)
├── TransitionDoor.gd attached
│   target_type = INTERIOR
│   target_scene = HouseInterior.tscn
│   entrance_marker_name = "EntranceMarker"
│   layer_manager = <WorldLayerManager node>
└── Area3D + CollisionShape3D
```

Inside `HouseInterior.tscn`, add one exit door with `target_type = SURFACE_EXIT`.

---

## Step 4 — Minimum viable test (grey-box)

The fastest way to see it running:

1. Open `assets/scenes/templates/RoomCombat_Greybox_A.tscn` — verify it looks right
2. Create `chapter_01_config.tres`, assign the greybox templates
3. Create a test scene, add `ProceduralLevelGenerator`, set config, call `generate()`
4. Add a CharacterBody3D in group `"player"` and walk through

Expected result: player starts in START room, walks to Exit_0, teleports to next room,
eventually reaches BOSS room.

---

## Adding a new chapter

1. Duplicate an existing `chapter_XX_config.tres`
2. Change `chapter_id`, `chapter_name`, `biome_theme`
3. Swap room pools to new biome-themed `.tscn` files
4. Done — same generator, different rooms

## Scaling guide (12 chapters)

| Asset | Minimum per chapter | Recommended |
|---|---|---|
| combat_rooms | 2 | 4–6 |
| corridor_rooms | 1 | 2–3 |
| rest_rooms | 1 | 1–2 |
| start_room | 1 | 1 |
| boss_room | 1 | 1 |
| surface zones | 3–4 | 6–8 |

With 4 combat + 2 corridor per chapter, players rarely see the same combo twice
across a 3-room branch run.
