# ADR-0004: Phase-Based Skill Execution Pipeline

## Status
Accepted

## Date
Sunday, 5 April 2026

## Context

### Problem Statement
Combat in *My Vampire* involves complex skills with varying costs, target types, tier-based power scaling, and multi-phase execution (e.g., animations before damage). We need a unified system that handles the lifecycle of a skill activation consistently across all party members and AI agents.

### Constraints
- Must handle 5 distinct phases defined in the GDD: Validation, Pre-execution, Acquisition, Application, and Post-execution.
- Must support both melee (instant) and ranged (projectile-based) skill delivery.
- Must integrate with `HealthDamageSystem` for math and `PartyMemberState` for resource tracking.

### Requirements
- Centralized validation for MP, Cooldowns, and Charges.
- Dynamic tier scaling (Tiers 1, 2, 3) affecting damage and AoE radius.
- Support for multiple target types: Single Enemy, Multi Enemy, Self, All Allies.
- Cinematic event triggers for high-tier skills.

## Decision
We implement the `SkillExecutionSystem` as a MonoBehaviour attached to each combatant. It acts as an orchestrator that coordinates between `SkillDataSO` (data), `HealthDamageSystem` (math), and the physics engine (targeting).

### 5-Phase Lifecycle Implementation
1.  **Phase 1: Validation**: Checks `IsAlive`, `CanUseSkill` (CD/MP), and valid slot index.
2.  **Phase 2: Pre-execution**: Consumes MP/Charges and triggers visual/cinematic feedback (e.g., `CameraController.PlayCinematicBurst`).
3.  **Phase 3: Acquisition**: Performs spatial queries (`Physics.OverlapSphere`) or filtered searches (`FindAlliesForSkill`) to identify valid targets.
4.  **Phase 4: Application**: Loops through targets and applies effects (Damage, Support, Status, or Utility) based on the skill's specific type.
5.  **Phase 5: Post-execution**: Fires events (`OnSkillCast`) and updates UI/State.

### Architecture Diagram
```text
[Input/AI] -> TryActivateSkill(slot, tier)
                    |
          [SkillExecutionSystem]
          /         |          \
 [SkillDataSO] [HealthDamageSystem] [Physics Engine]
      (Data)      (Pure Math)       (Targeting)
                    |
          [PartyMemberState / Hurtbox]
              (Modify State)
```

## Alternatives Considered

### Alternative 1: Command Pattern for Skills
- **Description**: Each skill is a class instance that "executes" itself.
- **Pros**: Cleaner separation of individual skill logic.
- **Cons**: High memory overhead if spawning many instances; harder to coordinate shared dependencies like `CameraController` or `ProjectilePool`.
- **Rejection Reason**: The `SkillExecutionSystem` approach is more data-driven (using `SkillDataSO`) and performant for Unity's component model.

### Alternative 2: Centralized Skill Manager
- **Description**: A single global manager that executes skills for all characters.
- **Pros**: Easier to synchronize multi-character skills.
- **Cons**: Becomes a massive "God Class" and makes local character state tracking (like active invincibility coroutines) more complex.
- **Rejection Reason**: Per-character systems allow for easier local event handling and cleaner state isolation.

## Consequences

### Positive
- **Predictable Flow**: Every skill follows the same execution pipeline, making debugging easier.
- **Data-Driven Scaling**: Tiers and effects are pulled from `SkillDataSO`, allowing designers to tune skills without touching code.
- **Projectiles Integration**: Seamless transition between melee hits and projectile instantiation.

### Negative
- **Complexity**: The `TryActivateSkill` method is large (orchestrator pattern) and handles many branches for different skill types.
- **Physics Dependency**: Acquisition phase relies on Unity's physics layers being correctly configured.

### Risks
- **Target Acquisition Misses**: Melee skills might fail if the radius is too small or collision layers are misaligned.
- **Mitigation**: Implemented "Melee Reliability" guards (minimum 2.5m radius) and detailed debug logging.

## Performance Implications
- **CPU**: Minimal. `OverlapSphere` is called only once per skill activation.
- **Memory**: Low. Uses events and static math to avoid object allocations.
- **Load Time**: No impact.

## Validation Criteria
- Unit tests must verify that MP is NOT consumed if validation fails.
- Integration tests must confirm that high-tier skills trigger the `CameraController` effect.
- Combat logs must show the correct sequence of phases for both Melee and Ranged skills.

## Related Decisions
- ADR-0003: Health & Damage System (Used for all application math).
- design/gdd/skill-execution-system.md (The source for the 5-phase rule).
