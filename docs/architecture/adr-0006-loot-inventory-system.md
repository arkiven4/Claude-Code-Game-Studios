# ADR-0006: ScriptableObject-Based Shared Inventory and Weighted Loot Tables

## Status
Accepted

## Date
Sunday, 5 April 2026

## Context

### Problem Statement
The game requires a system to handle loot drops from defeated enemies and a way to store these items persistently across different game states (combat, menus, and exploration). We need a solution that is easy for designers to tune and simple for different systems (UI, save system, characters) to access.

### Constraints
- Must support weighted random drops (Loot Tables).
- Must scale drop quantity based on enemy difficulty (Grunt, Elite, Boss).
- Must provide a shared inventory state accessible by both the HUD and the equipment systems.

### Requirements
- Centralized data layer for collected items.
- Event-driven notifications for inventory changes.
- Physical in-world pickups that can be collected by the player.
- Decoupling of loot generation (Enemy) from loot storage (Party).

## Decision
We implement a shared inventory using a `PartyInventory` ScriptableObject and a data-driven loot generation system using `LootTableSO` and `LootDropper`.

### Architecture Diagram
```text
[EnemyAIController] (Death Event)
        |
[LootDropper] (MonoBehaviour) --Uses--> [LootTableSO] (Data)
        |                                     |
        v                                     v
[LootPickupComponent] (World Object)   [ItemEquipmentSO] (Definition)
        |
        +-- (Player Trigger) --+
                               |
                               v
                     [PartyInventory] (ScriptableObject State)
                               |
                               v (Events)
                    [Combat HUD / Equipment Menu]
```

### Key Interfaces
- `LootTableSO.GetRandomDrop()`: Pure logic to select an item based on weights.
- `PartyInventory.AddItem(item)`: Central method for state modification with event firing.
- `LootDropper.HandleDeath()`: Orchestrates the drop count based on enemy class and spawns pickups.

## Alternatives Considered

### Alternative 1: Singleton Inventory Manager
- **Description**: A single `MonoBehaviour` singleton (e.g., `InventoryManager.Instance`).
- **Pros**: Familiar pattern for many developers.
- **Cons**: Difficult to manage during scene transitions; requires persistent GameObjects (`DontDestroyOnLoad`).
- **Rejection Reason**: ScriptableObjects provide a cleaner "data-first" approach that doesn't rely on the existence of a scene object.

### Alternative 2: Direct Inventory Addition
- **Description**: Enemies add items directly to the inventory on death without spawning a pickup.
- **Pros**: Simpler implementation; no physics/interaction required.
- **Cons**: Lacks the visual feedback and player satisfaction of collecting loot.
- **Rejection Reason**: The physical pickup is a core part of the "Player Fantasy" of looting.

## Consequences

### Positive
- **Cross-Scene Persistence**: The `PartyInventory` asset exists independently of scenes, making it easier to maintain state during transitions.
- **Designer Friendly**: Weights and drop tables can be adjusted in the Unity Inspector without code changes.
- **Decoupled**: The `LootDropper` doesn't need to know *how* the inventory works, only that it can pass an item to it.

### Negative
- **ScriptableObject Lifetime**: Changes to ScriptableObjects persist in the Editor (which is great for tuning) but must be manually cleared or reset at the start of a real game session to avoid carrying over loot from previous playtests.
- **Reference Management**: All systems needing inventory access must have a reference to the specific `PartyInventory` asset.

### Risks
- **Inventory Reset**: Forgetting to clear the ScriptableObject inventory on "New Game" start.
- **Mitigation**: Implemented `PartyInventory.Clear()` and integrated it into the game's startup/reset flow.

## Performance Implications
- **CPU**: Negligible. Loot calculations and weight rolls are lightweight.
- **Memory**: Scales with the number of items in the inventory.
- **Load Time**: No impact.

## Validation Criteria
- Unit tests must confirm that `LootTableSO` correctly honors its weights over a large sample size.
- Integration tests must verify that picking up an item correctly fires the `OnInventoryChanged` event.
- Stress test: Verify that dropping 100+ items simultaneously (e.g., in a debug "loot fountain") doesn't cause frame spikes.

## Related Decisions
- ADR-0003: Health & Damage System (Enemies trigger drops via this system's death events).
- design/gdd/loot-drop-system.md (The source for drop rules).
