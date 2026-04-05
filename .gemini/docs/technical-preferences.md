# Technical Preferences

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript (statically typed — use type hints everywhere)
- **Rendering**: Forward+ renderer (3D default in Godot 4.6)
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
- **References**: Tales of Arise (combat readability), Guilty Gear Strive (cartoon outlines), Genshin Impact (soft toon shading)

## Naming Conventions

- **Classes**: PascalCase — e.g., `PlayerController`, `HealthDamageSystem`
- **Variables / properties**: snake_case — e.g., `move_speed`, `current_health`
- **Constants**: UPPER_SNAKE_CASE — e.g., `MAX_PARTY_SIZE`, `BASE_DAMAGE`
- **Signals**: snake_case, past-tense verb — e.g., `health_depleted`, `character_switched`
- **Functions / methods**: snake_case — e.g., `take_damage()`, `switch_character()`
- **Files**: snake_case matching the class — e.g., `player_controller.gd`
- **Scenes**: PascalCase — e.g., `WitchPrologue.tscn`, `Chapter1Forest.tscn`
- **Resources**: PascalCase with type suffix — e.g., `CharacterData`, `SkillData`, `ItemEquipment`
- **Enums**: PascalCase enum name, UPPER_SNAKE_CASE values — e.g., `enum CharacterClass { MAGE, SWORDMAN }`

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 200 per frame
- **Memory Ceiling**: 2 GB RAM (PC target)
- **Texture Budget**: 512 MB VRAM for active scene assets

## Testing

- **Framework**: GUT (Godot Unit Testing) addon
- **Minimum Coverage**: Core gameplay systems (combat, switching, loot, party AI)
- **Required Tests**:
  - Balance formulas (damage, expertise scalar calculations)
  - Character switching state (no buff/cooldown leaks on swap)
  - Party AI expertise scalar (verify behavior at 0.0, 0.5, 1.0)
  - Loot assignment (correct items go to correct characters)

## Forbidden Patterns

- **Untyped GDScript**: All variables, parameters, and return types must have type hints
- **`get_node()` with long paths**: Use `@onready var` or `%UniqueNodeName` syntax
- **AutoLoad singletons for gameplay systems**: Use dependency injection or Resource-based channels
- **Hardcoded gameplay values**: All tunable values (damage, speed, expertise) must be in Resources
- **`load()` at runtime for frequently-used assets**: Use `preload()` for assets known at compile time
- **String-based signal connections**: Use typed `signal_name.connect(callable)` syntax

## Godot-Specific Patterns (Unity Equivalents)

| Unity | Godot |
|-------|-------|
| `MonoBehaviour` | `extends Node3D` / `extends Node` |
| `ScriptableObject` | `extends Resource` (saved as `.tres`) |
| `UnityEvent` | `signal` + `.connect()` |
| `Prefab` | `PackedScene` (`.tscn`) |
| `Coroutine` | `await` / `await get_tree().create_timer(t).timeout` |
| `Update()` | `_process(delta)` |
| `FixedUpdate()` | `_physics_process(delta)` |
| `Start()` | `_ready()` |
| `GetComponent<T>()` | `$NodeName` or `%UniqueNode` via `@onready` |
| `Physics.OverlapSphere` | `PhysicsDirectSpaceState3D.intersect_sphere()` |
| `CharacterController` | `CharacterBody3D` |
| `Rigidbody` | `RigidBody3D` |
| `Animator` | `AnimationPlayer` / `AnimationTree` |
| `AudioSource` | `AudioStreamPlayer3D` |
| `Debug.Log` | `print()` |
| `Application.persistentDataPath` | `OS.get_user_data_dir()` |
| `JsonUtility` | `JSON.stringify()` / `JSON.parse_string()` |
| `SceneManager.LoadSceneAsync` | `ResourceLoader.load_threaded_request()` |

## Allowed Libraries / Addons

- **GUT** — Godot Unit Testing framework (`addons/gut/`)
- **Godot RL Agents** — RL training for party AI (replaces Unity ML-Agents)
- **Phantom Camera** — Camera management (replaces Cinemachine)

## Architecture Decisions Log

- [ADR-0001](../../docs/architecture/adr-0001-party-ai-rl-vs-behavior-tree.md) — Party AI: RL with BT fallback; IPartyAgent interface; expertise scalar (0.0–1.0)
- [ADR-0002](../../docs/architecture/adr-0002-character-switching-state-sync.md) — Character Switching: distributed state; switch transfers input authority only; 0.3s window
- [ADR-0003](../../docs/architecture/adr-0003-health-damage-system.md) — Health & Damage system
- [ADR-0004](../../docs/architecture/adr-0004-skill-execution-system.md) — Skill Execution system
- [ADR-0005](../../docs/architecture/adr-0005-status-effects-system.md) — Status Effects system
- [ADR-0006](../../docs/architecture/adr-0006-loot-inventory-system.md) — Loot & Inventory system
