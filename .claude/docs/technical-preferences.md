# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (statically typed)
- **Rendering**: Forward+ renderer (3D)
- **Physics**: Jolt Physics (default in Godot 4.6)

## Visual Style

- **Dimension**: 3D
- **Aesthetic**: Soft cartoon — rounded forms, toon shading, clean outlines
- **Shading**: Toon/cel-shaded via `StandardMaterial3D` + custom rim shader or Godot toon shader
- **Outlines**: Inverted hull method on character/enemy meshes
- **Color palette**: Warm shadows, desaturated midtones, vibrant per-character accents
  - Evelyn: deep purple / crimson
  - Evan: steel blue / gold
  - Witch: forest green / ivory
- **VFX**: Bold, readable skill effects — large impact flashes, no subtle particle-only effects
- **UI**: Flat design, soft rounded panels — matches cartoon aesthetic
- **Prototyping placeholders**: Solid flat-color capsules (blue = player, red = enemy)
- **References**: Tales of Arise, Guilty Gear Strive, Genshin Impact

## Naming Conventions

- **Classes** (`class_name`): PascalCase — e.g., `PlayerController`, `CharacterData`
- **Variables / properties**: snake_case — e.g., `move_speed`, `current_health`
- **Private variables**: _snake_case — e.g., `_move_speed`, `_is_alive`
- **Methods / functions**: snake_case — e.g., `take_damage()`, `switch_character()`
- **Signals**: snake_case — e.g., `character_switched`, `hp_changed`
- **Files**: snake_case matching the class — e.g., `player_controller.gd`, `character_data.gd`
- **Scenes**: PascalCase descriptive — e.g., `Evelyn.tscn`, `WitchPrologue.tscn`, `Chapter1Forest.tscn`
- **Resources (.tres)**: snake_case with `[character/system]_[name]` pattern — e.g., `evelyn_dark_bolt.tres`, `grunt_melee.tres`
- **Constants**: UPPER_SNAKE_CASE — e.g., `MAX_PARTY_SIZE`, `CRITICAL_MULTIPLIER`

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 200 per frame (Godot batching assists with this)
- **Memory Ceiling**: 2 GB RAM (PC target)
- **Texture Budget**: 512MB VRAM for active scene assets

## Testing

- **Framework**: GUT (Godot Unit Testing) v9.x — install from AssetLib
- **Test location**: `tests/unit/` (all test files prefixed `test_`)
- **Minimum Coverage**: Core gameplay systems (combat, switching, loot, equipment)
- **Required Tests**:
  - Balance formulas (damage, heal calculations in `HealthDamageSystem`)
  - Character switching state (no HP/cooldown leaks on swap)
  - Status effect apply/tick/expire/stack
  - Loot table distribution + drop count by enemy class
  - Equipment slot equip/unequip + stat modifiers
- **Run tests**: GUT panel in Godot Editor → Run All

## Forbidden Patterns

- **`get_node()` with hardcoded absolute paths**: Use `@export` NodePath or `get_node_or_null()` with null-check
- **`get_tree().get_nodes_in_group()` for gameplay logic**: Only use for broad queries; prefer direct references via `@export`
- **`autoload` singletons for gameplay state**: Use dependency injection (`@export` references) — autoloads only for truly global services (AudioManager, SaveManager)
- **Hardcoded gameplay values**: All tunable values (damage, speed, cooldowns) must be in `.tres` Resource files
- **`func _ready()` doing heavy work synchronously**: Use `call_deferred()` for cross-node wiring
- **Untyped GDScript variables**: All variables must have explicit type annotations — `var speed: float = 5.0`
- **Direct `set()`/`get()` on other nodes' internals**: Use signals or explicit public methods

## Allowed Libraries / Addons

- **GUT** — Godot Unit Testing framework (AssetLib: "Gut - Godot Unit Testing")
- **Godot Input Map** — built-in action-based input; define all actions in Project Settings → Input Map
- **Godot Resource system** — `.tres` / `.res` files for all data; no external JSON for gameplay data
- **Godot AudioStreamPlayer** — SFX and music via `AudioManager` autoload
- **Godot Control / CanvasLayer** — all runtime UI (HUD, menus, inventory)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [ADR-0001](../../docs/architecture/adr-0001-party-ai-rl-vs-behavior-tree.md) — Party AI: RL (ML-Agents) with BT fallback; IPartyAgent interface; expertise scalar (0.0–1.0); Month 1 prototype gate
- [ADR-0002](../../docs/architecture/adr-0002-character-switching-state-sync.md) — Character Switching: distributed state (each character owns their own HP/cooldowns/buffs); CharacterSwitchController transfers input authority only; 0.3s switch window; input buffer flush
