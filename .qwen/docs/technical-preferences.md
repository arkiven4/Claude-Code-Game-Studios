# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Unity 6.3 LTS (6000.3)
- **Language**: C#
- **Rendering**: Universal Render Pipeline (URP) with Render Graph API
- **Physics**: Unity Physics (PhysX for 3D, Box2D for 2D)

## Naming Conventions

- **Classes**: PascalCase — e.g., `PlayerController`, `EvelynsInventory`
- **Public fields / properties**: PascalCase — e.g., `MoveSpeed`, `CurrentHealth`
- **Private fields**: _camelCase — e.g., `_moveSpeed`, `_isAlive`
- **Methods**: PascalCase — e.g., `TakeDamage()`, `SwitchCharacter()`
- **Events / delegates**: PascalCase with `On` prefix — e.g., `OnCharacterSwitched`
- **Files**: PascalCase matching the class name — e.g., `PlayerController.cs`
- **Scenes**: PascalCase descriptive — e.g., `WitchPrologue.unity`, `Chapter1_Forest.unity`
- **Prefabs**: PascalCase matching root GameObject — e.g., `Evelyn.prefab`, `ArcherA.prefab`
- **Constants**: PascalCase or UPPER_SNAKE_CASE — e.g., `MaxPartySize` or `MAX_PARTY_SIZE`
- **ScriptableObjects**: PascalCase with SO suffix — e.g., `CharacterStatsSO`

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6ms
- **Draw Calls**: < 200 per frame (URP batching assists with this)
- **Memory Ceiling**: 2 GB RAM (PC target)
- **Texture Budget**: 512MB VRAM for active scene assets

## Testing

- **Framework**: Unity Test Framework (NUnit-based, built-in)
- **Minimum Coverage**: Core gameplay systems (combat, switching, loot, party AI)
- **Required Tests**:
  - Balance formulas (damage, expertise scalar calculations)
  - Character switching state (no buff/cooldown leaks on swap)
  - Party AI expertise scalar (verify behavior at 0.0, 0.5, 1.0)
  - Loot assignment (correct items go to correct characters)

## Forbidden Patterns

- **`Input` class (legacy)**: Use `UnityEngine.InputSystem` package instead
- **`Resources.Load()`**: Use Addressables for all runtime asset loading
- **`FindObjectsOfType()`**: Use `FindObjectsByType()` with sort mode parameter
- **`FindObjectOfType()`**: Use `FindFirstObjectByType()` or `FindAnyObjectByType()`
- **`[SerializeField]` on properties**: Use `[field: SerializeField]` on auto-properties
- **Hardcoded gameplay values**: All tunable values (damage, speed, expertise) must be in ScriptableObjects
- **Singletons for gameplay systems**: Use dependency injection or ScriptableObject channels

## Allowed Libraries / Addons

- **Unity ML-Agents** — RL training for party AI (verify version in Package Manager)
- **Unity Input System** — `com.unity.inputsystem`
- **Unity Addressables** — `com.unity.addressables`
- **TextMeshPro** — all in-game text rendering
- **UI Toolkit** — runtime UI (menus, HUD, inventory)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [ADR-0001](../../docs/architecture/adr-0001-party-ai-rl-vs-behavior-tree.md) — Party AI: RL (ML-Agents) with BT fallback; IPartyAgent interface; expertise scalar (0.0–1.0); Month 1 prototype gate
- [ADR-0002](../../docs/architecture/adr-0002-character-switching-state-sync.md) — Character Switching: distributed state (each character owns their own HP/cooldowns/buffs); CharacterSwitchController transfers input authority only; 0.3s switch window; input buffer flush
