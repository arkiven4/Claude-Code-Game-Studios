# Gemini Migration Prompt — My Vampire: Unity → Godot 4.6

Copy everything below this line and paste it as your first message to Gemini CLI.

---

## Context

You are taking over development of **My Vampire**, a narrative Action RPG being migrated
from Unity 6.3 LTS (C#) to **Godot 4.6 (GDScript)**. The project has been fully designed
but needs its Godot implementation completed.

**Game concept (one paragraph):**
A vampire girl cursed by the Church joins forces with the hunter sent to kill her,
battling through a world of magic, grief, and betrayal. Narrative Action RPG with
real-time hack & slash combat, real-time party switching between characters, and
RL-trained party AI. Comparable to Final Fantasy VII Remake and Tales of Berseria.

**Visual style**: 3D with a soft, cartoon aesthetic. Toon/cel-shaded characters,
clean outlines (inverted hull method), bold readable VFX, flat UI with rounded panels.
Color references per character: Evelyn = deep purple/crimson, Evan = steel blue/gold,
Witch = forest green/ivory. Art references: Tales of Arise (combat readability),
Guilty Gear Strive (cartoon outlines), Genshin Impact (soft toon shading).
During prototyping, use solid flat-color capsules (blue = player, red = enemy).

---

## What Already Exists

### Design (complete — do not change)
- `design/gdd/` — 27 Game Design Documents, all MVP systems fully approved
- `design/gdd/systems-index.md` — full list of 37 systems with dependencies
- `design/gdd/game-concept.md` — full game concept
- `docs/architecture/` — 6 Architecture Decision Records (ADR-0001 through ADR-0006)
- `docs/migration/unity-to-godot.md` — full system-by-system migration guide

### GDScript Skeletons (need full implementation)
All files in `src/` are skeletons — class names, signals, and property stubs only.
Most methods have placeholder `pass` or minimal logic. Your job is to complete them.

```
src/
  core/
    character_data.gd       ✓ complete (Resource)
    skill_data.gd           ✓ complete (Resource)
    item_equipment.gd       ✓ complete (Resource)
    item_rarity.gd          ✓ complete (Resource)
    status_effect.gd        ✓ complete (Resource)
    enemy_data.gd           ✓ complete (Resource)
    input_manager.gd        ✓ complete
    save_manager.gd         ✓ complete
    scene_loader.gd         ✓ complete
    chapter_state_manager.gd ✓ complete
    audio/
      audio_manager.gd      ✓ complete
      music_player.gd       ✓ complete
      sfx_player.gd         ✓ complete
      audio_event_channel.gd ✓ complete
  gameplay/
    health_damage_system.gd ✓ complete
    hitbox_component.gd     ✓ complete
    hurtbox_component.gd    ✓ complete
    active_effect.gd        ✓ complete
    status_effects_system.gd ✓ complete
    skill_execution_system.gd ⚠ stub — cooldown_complete emits null, needs SkillData ref
    combat_encounter_manager.gd ✓ complete
    enemy_ai_controller.gd  ⚠ stub — _perform_attack() is empty
    player_movement_controller.gd ✓ complete
    character_state_manager.gd ✓ complete
    character_switch_controller.gd ✓ complete
    equipment_manager.gd    ✓ complete
    loot/
      loot_table.gd         ✓ complete
      loot_dropper.gd       ✓ complete
      loot_pickup.gd        ✓ complete
      party_inventory.gd    ✓ complete
  ai/
    party_agent.gd          ✓ complete (base class)
    bt_party_agent.gd       ⚠ stub — _apply_action() is empty
    rl_party_agent.gd       ⚠ stub — needs Godot RL Agents addon
  narrative/
    dialogue_node.gd        ✓ complete (Resource)
    dialogue_graph.gd       ✓ complete (Resource)
    dialogue_manager.gd     ✓ complete
  ui/
    combat_hud.gd           ⚠ stub — skill cooldown overlays not wired
    world_hp_bar.gd         ⚠ stub — needs SubViewport tscn
```

### Not Yet Created (your primary task)
- `assets/scenes/` — all `.tscn` scene files (zero exist)
- `assets/data/` — all `.tres` Resource data files (zero exist)
- Camera system (`src/gameplay/camera_controller.gd`)
- `CombatAudioWiring` (connect audio to combat events)
- `VictoryGameOverLogger` equivalent
- GUT test suite (`tests/`)

---

## Your Task: Complete the Migration

Work through this **in dependency order** (foundation first):

### Phase 1 — Fix Stubs
1. `skill_execution_system.gd` — track SkillData by skill_id so `skill_cooldown_complete` emits the correct SkillData
2. `enemy_ai_controller.gd` — implement `_perform_attack()`: activate hitbox facing the target
3. `bt_party_agent.gd` — implement `_apply_action()`: call skill_executor or movement on the parent character node
4. `combat_hud.gd` — wire skill slot cooldown radial overlays

### Phase 2 — Camera System
Create `src/gameplay/camera_controller.gd`:
- 3 modes: Exploration (third-person, 8u behind, 4u above), Combat (dynamic 6/8/10u by enemy count), Cinematic
- Transitions: Exploration↔Combat 0.5s, Any→Cinematic 0.2s fade
- Use Godot `SpringArm3D` + `Camera3D` (no external addon required for basic setup)
- `set_mode(mode: CameraMode)` public API
- Reference: `design/gdd/camera-system.md`

### Phase 3 — Data Assets (.tres files)
Create all Resource data files in `assets/data/`:

**Characters** (`assets/data/characters/`):
- `evelyn.tres` — CharacterData: Mage class, MaxHP=180, ATK=85, DEF=40, SPD=60, MaxMP=120, CRIT=0.12
- `evan.tres` — CharacterData: Swordman class, MaxHP=250, ATK=70, DEF=65, SPD=55, MaxMP=60, CRIT=0.08
- `witch.tres` — CharacterData: Witch class, MaxHP=150, ATK=95, DEF=30, SPD=50, MaxMP=150, CRIT=0.15

**Skills** (`assets/data/skills/`) — 12 total:
- Evelyn ×4: DarkBolt (damage, 1.2 scalar, 1.0s CD, 15 MP), ShadowVeil (utility, 0s CD, 25 MP), AbyssalChain (damage+status, 1.5 scalar, 4.0s CD, 30 MP), EclipseBurst (ultimate, 2.5 scalar, 12.0s CD, 60 MP)
- Evan ×4: CrescentSlash (damage, 1.3 scalar, 1.2s CD, 10 MP), ShieldBash (damage+control, 1.0 scalar, 3.0s CD, 20 MP), HuntersMark (debuff, 0s CD, 15 MP), RendingStorm (damage, 1.8 scalar, 6.0s CD, 35 MP)
- Witch ×4: HexBolt (damage, 1.1 scalar, 0.8s CD, 12 MP), SpiritWard (buff, 0s CD, 20 MP), Moonfire (damage, 1.6 scalar, 5.0s CD, 40 MP), CovensWrath (ultimate, 2.8 scalar, 15.0s CD, 80 MP)
- Full values in: `design/gdd/skill-database.md`

**Items** (`assets/data/items/`) — 5 items:
- `evelyn_starter_staff.tres` — Weapon, Mage, UNCOMMON, ATK+15
- `evan_starter_sword.tres` — Weapon, Swordman, UNCOMMON, ATK+12, DEF+5
- `mage_apprentice_robe.tres` — Armor, Mage, COMMON, DEF+10, MaxMP+20
- `swordman_chain_mail.tres` — Armor, Swordman, COMMON, DEF+20, MaxHP+30
- `generic_copper_ring.tres` — Accessory, any class, COMMON, CRIT+0.02
- Full values in: `design/gdd/item-database.md`

**Enemies** (`assets/data/enemies/`) — 2 enemies:
- `grunt_melee.tres` — EnemyData: GRUNT, HP=150, ATK=25, DEF=15, SPD=40, aggro_range=6.0
- `archer_ranged.tres` — EnemyData: ELITE, HP=120, ATK=35, DEF=10, SPD=60, aggro_range=12.0
- Full values in: `design/gdd/enemy-ai-system.md`

### Phase 4 — Scenes (.tscn files)

#### Character scenes (`assets/scenes/characters/`)
Each character scene structure:
```
CharacterBody3D (PlayerMovementController.gd)
  ├── MeshInstance3D (placeholder capsule)
  ├── CollisionShape3D
  ├── HealthDamageSystem (Node)
  ├── StatusEffectsSystem (Node)
  ├── SkillExecutionSystem (Node)
  ├── CharacterStateManager (Node)
  ├── EquipmentManager (Node)
  ├── HitboxComponent (Area3D)
  │   └── CollisionShape3D
  └── HurtboxComponent (Area3D)
      └── CollisionShape3D
```
Create: `Evelyn.tscn`, `Evan.tscn`, `Witch.tscn`

#### Enemy scenes (`assets/scenes/enemies/`)
```
CharacterBody3D (EnemyAIController.gd)
  ├── MeshInstance3D (placeholder capsule, red color)
  ├── CollisionShape3D
  ├── HealthDamageSystem (Node)
  ├── HitboxComponent (Area3D)
  ├── HurtboxComponent (Area3D)
  ├── LootDropper (Node)
  └── WorldHPBar (Node3D)
```
Create: `GruntMelee.tscn`, `ArcherRanged.tscn`

#### TestArena scene (`assets/scenes/TestArena.tscn`)
```
Node3D (root)
  ├── WorldEnvironment
  ├── DirectionalLight3D
  ├── MeshInstance3D (ground plane, 20×20)
  ├── CombatEncounterManager (Node)
  ├── CharacterSwitchController (Node)
  ├── InputManager (Node)
  ├── SaveManager (Node)
  ├── AudioManager (Node)
  │   ├── MusicPlayer (AudioStreamPlayer)
  │   └── SFXPlayer (Node)
  ├── CameraController (Node3D)
  │   ├── SpringArm3D
  │   │   └── Camera3D
  ├── Party (Node3D)
  │   ├── Evelyn (instance of Evelyn.tscn)
  │   └── Evan (instance of Evan.tscn)
  ├── Enemies (Node3D)
  │   ├── GruntMelee_1 (instance of GruntMelee.tscn)
  │   ├── GruntMelee_2 (instance of GruntMelee.tscn)
  │   └── ArcherRanged_1 (instance of ArcherRanged.tscn)
  └── CombatHUD (CanvasLayer, instance of CombatHUD.tscn)
```

### Phase 5 — Wiring
After all scenes exist, wire up the cross-system connections:
- `CharacterSwitchController` → reference Evelyn and Evan NodePaths
- `CombatEncounterManager` → connect to enemy `enemy_died` signals
- `LootDropper` on each enemy → connect to `enemy_died` signal, set pickup_scene
- `CombatHUD` → connect to active character's `HealthDamageSystem` signals
- `CameraController` → connect to `CombatEncounterManager.combat_started/ended`
- `EnemyAIController` → set target to active player character

### Phase 6 — Tests (GUT)
Install GUT addon (`addons/gut/`) and create test files in `tests/`:
- `test_health_damage.gd` — damage formula, min clamp, death signal, heal clamp
- `test_status_effects.gd` — DoT tick, stack rules, expiry
- `test_character_switching.gd` — cooldown blocks rapid switch, no state leak between characters
- `test_loot_drop.gd` — rarity distribution (10k rolls, within 5% tolerance), drop count by enemy class
- `test_equipment.gd` — equip/unequip stat modifiers, class restriction

---

## Rules You Must Follow

1. **Statically typed GDScript only** — every variable, parameter, and return type must have a type hint
2. **No singletons (AutoLoad)** — pass dependencies via `@export` NodePath or Resource references
3. **No hardcoded gameplay values** — all numbers must be in `.tres` Resource files
4. **Signals over direct calls** for cross-system communication
5. **Ask before writing** any file — show what you plan to create first
6. **Follow the design docs** — `design/gdd/[system].md` is the source of truth for every mechanic
7. **Godot 4.6 API only** — check `docs/engine-reference/godot/VERSION.md` for post-cutoff changes

## Key Design Docs to Read First
- `design/gdd/systems-index.md` — dependency order
- `design/gdd/combat-system.md` — combat rules
- `design/gdd/character-switching-system.md` + `docs/architecture/adr-0002-character-switching-state-sync.md`
- `design/gdd/health-damage-system.md` — damage formula
- `design/gdd/enemy-ai-system.md` — AI state machine
- `.gemini/docs/technical-preferences.md` — naming conventions + forbidden patterns

## Start Here

Read `src/gameplay/skill_execution_system.gd` and fix the `skill_cooldown_complete` emission
so it passes the correct `SkillData` reference instead of `null`. Show me your fix before writing it.
