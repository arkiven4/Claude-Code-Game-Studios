# ADR-0003: Centralized Static Utility for Health and Damage Calculations

## Status
Accepted

## Date
Sunday, 5 April 2026

## Context

### Problem Statement
The game requires a robust, consistent, and highly testable way to calculate damage, healing, and status effect ticks across multiple systems, including the `SkillExecutionSystem`, `EnemyAIController`, and `StatusEffectsSystem`. Repeating these complex formulas in every script is error-prone and makes tuning difficult.

### Constraints
- Must match the exact mathematical formulas defined in the "Health & Damage System GDD".
- Must be callable from both MonoBehaviours and non-MonoBehaviour classes (like AI agents).
- Must minimize garbage collection (GC) allocations during high-frequency combat.

### Requirements
- Centralized "Tuning Knobs" for global constants (Crit Multiplier, Revive HP, etc.).
- Support for Critical Hit rolls and reporting.
- Support for Damage, Healing, and Damage-over-Time (DoT) calculations.
- Decoupling of "Math" (calculation) from "Application" (modifying state).

## Decision
We implement the `HealthDamageSystem` as a `public static class` within the `MyVampire.Gameplay` namespace.

### Architecture Diagram
```text
[SkillExecutionSystem] ----+
                           |
[EnemyAIController] -------+---> [HealthDamageSystem (Static)]
                           |           |
[StatusEffectsSystem] -----+           | (Calculates & Applies)
                                       v
                             [PartyMemberState (Component)]
```

### Key Interfaces
- `CalculateDamage(...)`: Pure function returning final damage and crit status.
- `CalculateHeal(...)`: Pure function returning clamped heal amount.
- `ApplyDamageToTarget(...)`: Helper that checks invincibility before calling state modification.
- `ApplyMaxHPChange(...)`: Specific logic for propagating MaxHP deltas to CurrentHP.

## Alternatives Considered

### Alternative 1: ScriptableObject-based Damage Calculator
- **Description**: Logic exists in a ScriptableObject asset that can be swapped or modified in the Inspector.
- **Pros**: Highly configurable without code changes.
- **Cons**: Adds overhead of asset referencing and is slightly harder to unit test in isolation.
- **Rejection Reason**: The formulas are stable and defined by the GDD; the static approach is faster and easier to test.

### Alternative 2: Logic inside PartyMemberState
- **Description**: Each character component calculates its own damage/healing received.
- **Pros**: Encapsulation of character logic.
- **Cons**: Makes it difficult to predict damage for AI (calculating damage *before* applying it) and leads to duplicate logic if different systems calculate damage differently.
- **Rejection Reason**: Centralizing the math allows AI to "simulation" hits without modifying state.

## Consequences

### Positive
- **High Testability**: Pure math functions can be unit-tested without a Unity Scene or GameObject.
- **Single Source of Truth**: Formula changes in the GDD only require one update in code.
- **Performance**: Zero allocations for standard calculations.

### Negative
- **Static Dependency**: Harder to mock in some testing frameworks (though the functions themselves are pure).
- **No Polymorphism**: Cannot easily swap calculation strategies at runtime (e.g., "Boss Math" vs "Player Math") without internal conditionals.

### Risks
- **Formula Drift**: If developers bypass the system and write their own math.
- **Mitigation**: Code reviews and project-wide standards enforced by CLI tools.

## Performance Implications
- **CPU**: Negligible. Static methods are highly efficient.
- **Memory**: Zero allocations.
- **Load Time**: No impact.

## Migration Plan
All existing damage/healing logic has been consolidated into this class. Future gameplay systems must use this static utility for any HP-related math.

## Validation Criteria
- Unit tests must confirm damage math matches GDD edge cases (e.g., Minimum 1 damage).
- Performance profiling during a 100-hit combat burst must show 0 bytes of GC allocation from this class.

## Related Decisions
- ADR-0002: Character Switching & State Sync (uses this system for HP sync).
- design/gdd/health-damage-system.md (The source for all formulas).
