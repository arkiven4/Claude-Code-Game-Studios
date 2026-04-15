# Architecture Overview

This document provides a high-level map of the *My Vampire* game architecture, unifying the design decisions documented in the ADRs.

## Core Design Philosophy
- **Data-Driven**: Most gameplay logic is defined in `Resource` (ScriptableObject) files, allowing for rapid iteration without code changes.
- **Decoupled Systems**: Systems interact via established interfaces and signals rather than direct tight coupling.
- **Distributed State**: Each entity (player, companion, enemy) owns its own state (HP, cooldowns, effects), which is updated continuously regardless of control.

## System Map

### 1. Combat & Character Management
- **PartyMemberState**: The authoritative source of truth for a character's HP, MP, cooldowns, and active effects.
- **CharacterSwitchController**: Transfers player input authority between party members without desyncing state.
- **EnemyAIController**: Manages enemy behaviors using a state machine (IDLE, CHASING, ATTACKING) or RL policies.

### 2. Execution Pipeline
- **SkillExecutionSystem**: A 5-phase orchestrator (Validation -> Pre-exec -> Acquisition -> Application -> Post-exec) that handles all skill logic.
- **HealthDamageSystem**: A centralized static utility for consistent math (damage, healing, DoT) across all systems.
- **StatusEffectsSystem**: Manages the lifecycle, stacking rules, and periodic ticking of buffs and debuffs.

### 3. AI & Navigation
- **IPartyAgent Interface**: Abstracts party AI implementations, allowing seamless switching between **Reinforcement Learning** (primary) and **Behavior Trees** (fallback).
- **ExpertiseScalar**: A tunable parameter (0.0 to 1.0) that injects noise and delay into AI actions to simulate different skill levels.

### 4. Items & Loot
- **LootDropper**: Orchestrates item drops on enemy death based on weighted **LootTables**.
- **PartyInventory**: A shared resource-based state that tracks all collected equipment and consumables.
- **Item Classes**:
    - `ItemEquipment`: Weapons, Armor, and Accessories with rarity multipliers.
    - `ItemConsumable`: Potions, scrolls, and materials with usage logic.

## Data Flow Diagram

```text
[Input / AI] 
      │
      ▼
[SkillExecutionSystem] ───Uses───▶ [SkillData Resource]
      │
      ├─Calculate Math──▶ [HealthDamageSystem]
      │                         │
      ├─Acquire Targets─▶ [Physics Engine]
      │                         │
      └─Apply Effects───▶ [StatusEffectsSystem] ──▶ [PartyMemberState]
                                │                         │
                                └─────Modify State────────┘
```

## Relevant Documents
- [ADR-0001: Party AI](adr-0001-party-ai-rl-vs-behavior-tree.md)
- [ADR-0002: Character Switching](adr-0002-character-switching-state-sync.md)
- [ADR-0003: Health & Damage](adr-0003-health-damage-system.md)
- [ADR-0004: Skill Execution](adr-0004-skill-execution-system.md)
- [ADR-0005: Status Effects](adr-0005-status-effects-system.md)
- [ADR-0006: Loot & Inventory](adr-0006-loot-inventory-system.md)
