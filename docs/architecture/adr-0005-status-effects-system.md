# ADR-0005: Decentralized Status Effect Lifecycle Management

## Status
Accepted

## Date
Sunday, 5 April 2026

## Context

### Problem Statement
Combat in *My Vampire* relies heavily on status effects (buffs, debuffs, DoTs). These effects have complex lifecycles: they must tick at specific intervals, stack according to different rules, and interact with character stats. We need a system that handles these lifecycles efficiently and consistently across all combatants.

### Constraints
- Must support 3 stacking rules: `NoStack`, `AdditiveStack`, and `DurationStack`.
- Must handle DoT (Damage over Time) ticking without duplicating damage math.
- Must be performant enough to run on 4+ party members and multiple enemies simultaneously.

### Requirements
- Snapshot-safe ticking (allowing an effect to remove itself while the list is being iterated).
- Integration with `HealthDamageSystem` for DoT calculations.
- Support for "Cleanse" (remove debuffs) and "Dispel" (remove buffs) mechanics.
- Persistence support for active effects (Save/Load or Scene transitions).

## Decision
We implement the `StatusEffectsSystem` as a MonoBehaviour attached to each combatant. It acts as the "manager" that modifies the `ActiveEffects` list stored in the `PartyMemberState`.

### Lifecycle Management
1.  **Tick (Update)**: Every frame, the system iterates through a snapshot of the `ActiveEffects` list.
2.  **DoT Trigger**: If an effect's internal timer reaches its interval, `HealthDamageSystem.CalculateDoTDamage` is called.
3.  **Application**: New effects are processed through `ApplyEffect`, which checks for existing instances of the same ID and applies the appropriate `StackingRule`.
4.  **Removal**: Effects are removed from the `PartyMemberState` list once their duration reaches zero or they are explicitly dispelled.

### Architecture Diagram
```text
[SkillExecutionSystem] -> ApplyEffect(definition)
                                |
                      [StatusEffectsSystem]
                      /         |          \
           [ActiveEffect] [PartyMemberState] [HealthDamageSystem]
            (State/Timer)  (Effect List)      (DoT Math)
```

## Alternatives Considered

### Alternative 1: Global Status Manager
- **Description**: A single singleton that ticks every active effect in the game.
- **Pros**: Potentially more efficient for bulk processing.
- **Cons**: Difficult to manage local character state and harder to debug which effect belongs to which character.
- **Rejection Reason**: Per-character systems are more idiomatic in Unity and simplify the logic for local immunities and dispels.

### Alternative 2: ScriptableObject "Effect" Logic
- **Description**: The `StatusEffectSO` itself contains the logic for ticking and applying damage.
- **Pros**: High flexibility; new effect types can be created without changing code.
- **Cons**: Logic in ScriptableObjects can be tricky to debug and often leads to messy state management (as SOs are shared assets).
- **Rejection Reason**: Using a dedicated manager (`StatusEffectsSystem`) with a simple state container (`ActiveEffect`) provides better separation of concerns.

## Consequences

### Positive
- **Safe Iteration**: Using snapshots prevents "Collection Modified" exceptions during effect removal.
- **Consistent Stacking**: Centralized logic ensures that `Poison` stacks the same way across all characters.
- **Math Decoupling**: Reuses `HealthDamageSystem`, ensuring that DoT damage follows the same global resistance rules as direct hits.

### Negative
- **Update Overhead**: Every combatant has an `Update()` loop ticking its effects, which could impact performance if there are hundreds of entities.
- **Snapshot Allocation**: Creating a new list snapshot every frame per character adds minor GC pressure.

### Risks
- **Cumulative Stat Bloat**: If an effect applies a stat buff (e.g., +10 ATK) and fails to remove it properly on expiration.
- **Mitigation**: Stat modifications should be calculated dynamically based on active effects rather than permanently modified (see ADR-0002 for state sync).

## Performance Implications
- **CPU**: Low for typical encounter sizes (4-10 combatants).
- **Memory**: Minor GC allocation per frame due to list snapshotting (`new List<ActiveEffect>(_state.ActiveEffects)`).
- **Load Time**: No impact.

## Validation Criteria
- Unit tests must confirm that `AdditiveStack` correctly increases damage and `DurationStack` correctly extends the timer.
- Integration tests must verify that `DispelAll(true)` removes only hostile effects.
- Long-running tests must confirm that expired effects are always cleared from memory.

## Related Decisions
- ADR-0003: Health & Damage System (Used for DoT math).
- ADR-0004: Skill Execution System (Main caller of `ApplyEffect`).
