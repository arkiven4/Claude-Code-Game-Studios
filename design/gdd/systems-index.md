# Systems Index: My Vampire

> **Status**: Approved
> **Created**: 2026-04-03
> **Last Updated**: 2026-04-03
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

My Vampire is a narrative Action RPG built around three mechanical pillars: accessible
hack & slash combat, real-time party switching, and RL-trained party AI. The game
needs 37 systems spanning foundation data, combat, party management, narrative delivery,
world/hub infrastructure, and UI presentation. The mechanical core is compact — combat,
switching, and loot form a tight loop — but the narrative infrastructure (dialogue,
chapter state, cutscenes, choices, multiple endings) adds significant design scope.

The most critical architectural decision is the **Character Data** ScriptableObject
schema: it is a dependency root with 10+ systems depending on it. It must be designed
first and changed as little as possible afterward. The second-highest risk is the
**Party AI System** (RL training feasibility) — prototype this in Month 1 before
committing the Alpha schedule to it.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Character Data | Foundation | MVP | Designed | design/gdd/character-data.md | — |
| 2 | Item Database | Foundation | MVP | Not Started | — | — |
| 3 | Item Rarity System | Foundation | MVP | Not Started | — | Item Database |
| 4 | Skill Database | Foundation | MVP | Not Started | — | — |
| 5 | Input System | Foundation | MVP | Not Started | — | — |
| 6 | Audio System | Foundation | MVP | Not Started | — | — |
| 7 | Save / Load System | Foundation | MVP | Not Started | — | — |
| 8 | Health & Damage System | Core | MVP | Not Started | — | Character Data |
| 9 | Hit Detection System | Core | MVP | Not Started | — | Unity Physics |
| 10 | Camera System | Core | MVP | Not Started | — | Unity Cinemachine |
| 11 | Chapter State System | Core | MVP | Not Started | — | Save / Load |
| 12 | Scene Management System | Core | MVP | Not Started | — | Save / Load, Audio |
| 13 | Status Effects System | Gameplay | MVP | Not Started | — | Health & Damage, Character Data |
| 14 | Skill Execution System | Gameplay | MVP | Not Started | — | Skill Database, Health & Damage, Status Effects |
| 15 | Enemy AI System | Gameplay | MVP | Not Started | — | Health & Damage, Hit Detection |
| 16 | Inventory & Equipment System | Progression | MVP | Not Started | — | Item Database, Character Data |
| 17 | Character Progression System | Progression | Alpha | Not Started | — | Character Data, Health & Damage |
| 18 | Character Skill System | Progression | MVP | Not Started | — | Skill Database, Skill Execution, Character Progression |
| 19 | Loot & Drop System | Economy | MVP | Not Started | — | Item Database, Item Rarity, Enemy AI |
| 20 | Combat System | Gameplay | MVP | Not Started | — | Health & Damage, Hit Detection, Skill Execution, Enemy AI, Camera |
| 21 | Character State Manager | Party | MVP | Not Started | — | Health & Damage, Status Effects, Skill Execution |
| 22 | Character Switching System | Party | MVP | Not Started | — | Character State Manager, Combat |
| 23 | Party AI System | Party | Alpha | Not Started | — | Combat, Enemy AI, Character State Manager |
| 24 | Party Management System | Party | Alpha | Not Started | — | Character Data, Character Switching |
| 25 | Dialogue System | Narrative | MVP | Not Started | — | Audio, Chapter State |
| 26 | Narrative Choice System | Narrative | Alpha | Not Started | — | Dialogue, Chapter State |
| 27 | Cutscene System | Narrative | MVP | Not Started | — | Dialogue, Camera, Audio, Chapter State |
| 28 | Multiple Endings System | Narrative | Full Vision | Not Started | — | Narrative Choice, Chapter State |
| 29 | NPC System (inferred) | World | Alpha | Not Started | — | Character Data, Dialogue |
| 30 | Shop System | Economy | Alpha | Not Started | — | Inventory & Equipment, Item Database |
| 31 | Village / Hub System (inferred) | World | Alpha | Not Started | — | Scene Management, NPC, Shop, Equipment Enhancement |
| 32 | Equipment Enhancement System | Economy | Full Vision | Not Started | — | Inventory & Equipment, Item Database |
| 33 | Combat HUD (inferred) | UI | MVP | Not Started | — | Combat, Health & Damage, Character Switching, Skill Execution |
| 34 | Inventory UI (inferred) | UI | Alpha | Not Started | — | Inventory & Equipment, Equipment Enhancement |
| 35 | Dialogue UI (inferred) | UI | MVP | Not Started | — | Dialogue System |
| 36 | Main Menu & Pause Menu (inferred) | UI | MVP | Not Started | — | Save / Load, Settings |
| 37 | Settings System (inferred) | Meta | Alpha | Not Started | — | Audio, Input |
| 38 | Cosmetics System | Progression | Full Vision | Not Started | — | Character Data, Inventory & Equipment |

---

## Categories

| Category | Description | Systems in This Game |
|----------|-------------|----------------------|
| **Foundation** | Data definitions and infrastructure everything else depends on | Character Data, Item DB, Item Rarity, Skill DB, Input, Audio, Save/Load |
| **Core** | Engine-level systems required before gameplay can function | Health & Damage, Hit Detection, Camera, Chapter State, Scene Management |
| **Gameplay** | The systems that make combat and encounters work | Status Effects, Skill Execution, Enemy AI, Combat |
| **Party** | Party-specific management, switching, and AI | Character State Manager, Character Switching, Party AI, Party Management |
| **Progression** | How characters and gear grow over time | Inventory & Equipment, Character Progression, Character Skill, Cosmetics |
| **Economy** | Items entering, leaving, and upgrading in the world | Loot & Drop, Shop, Equipment Enhancement |
| **Narrative** | Story delivery and choice tracking | Dialogue, Narrative Choice, Cutscene, Multiple Endings |
| **World** | Hub areas, NPCs, and area transitions | NPC, Shop, Village/Hub |
| **UI** | All player-facing information screens | Combat HUD, Inventory UI, Dialogue UI, Main Menu |
| **Meta** | Settings, accessibility, and project-level systems | Settings System |

---

## Priority Tiers

| Tier | Definition | Target | Systems |
|------|------------|--------|---------|
| **MVP** | Required for core loop to function. Witch prologue + Ch 1–2 playable. | Month 1 | 21 systems |
| **Alpha** | All major features present in rough form. Full party, shops, choices. | Month 2 | 10 systems |
| **Full Vision** | Polish, enhancement, cosmetics, multiple endings complete. | Month 3 | 4 systems |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Character Data** — Root data definition for every playable and party character; schema changes ripple through 10+ systems
2. **Item Database** — All equippable items defined as ScriptableObjects; Item Rarity lives here
3. **Item Rarity System** — Rarity tier enum and stat range multipliers; property of Item Database
4. **Skill Database** — All skills defined as ScriptableObjects; skill effects, cooldowns, character assignments
5. **Input System** — Unity Input System action maps; no player action exists without this
6. **Audio System** — Music playback, SFX triggering, mixer management; referenced by almost every system
7. **Save / Load System** — JSON or binary serialization of all game state; required before any persistent data is designed

### Core Layer (depends on foundation only)

1. **Health & Damage System** — depends on: Character Data (stats define max HP, defense)
2. **Hit Detection System** — depends on: Unity Physics (hitboxes, collision layers)
3. **Camera System** — depends on: Unity Cinemachine (combat tracking, cinematic mode)
4. **Chapter State System** — depends on: Save / Load (story flags must persist)
5. **Scene Management System** — depends on: Save / Load, Audio (music crossfade on scene change)

### Gameplay Layer (depends on Foundation + Core)

1. **Status Effects System** — depends on: Health & Damage, Character Data
2. **Skill Execution System** — depends on: Skill Database, Health & Damage, Status Effects
3. **Enemy AI System** — depends on: Health & Damage, Hit Detection
4. **Inventory & Equipment System** — depends on: Item Database, Character Data
5. **Dialogue System** — depends on: Audio System, Chapter State System
6. **Character Progression System** — depends on: Character Data, Health & Damage

### Combat & Narrative Layer (depends on Gameplay)

1. **Combat System** — depends on: Health & Damage, Hit Detection, Skill Execution, Enemy AI, Camera
2. **Character State Manager** — depends on: Health & Damage, Status Effects, Skill Execution
3. **Loot & Drop System** — depends on: Item Database, Item Rarity, Enemy AI (drops on death)
4. **Character Skill System** — depends on: Skill Database, Skill Execution, Character Progression
5. **NPC System** — depends on: Character Data, Dialogue System
6. **Cutscene System** — depends on: Dialogue, Camera, Audio, Chapter State

### Party Layer (depends on Combat)

1. **Character Switching System** — depends on: Character State Manager, Combat System
2. **Party AI System** — depends on: Combat System, Enemy AI, Character State Manager
3. **Party Management System** — depends on: Character Data, Character Switching
4. **Narrative Choice System** — depends on: Dialogue System, Chapter State System

### World & Advanced Layer (depends on Party)

1. **Shop System** — depends on: Inventory & Equipment, Item Database
2. **Equipment Enhancement System** — depends on: Inventory & Equipment, Item Database
3. **Village / Hub System** — depends on: Scene Management, NPC, Shop, Enhancement
4. **Multiple Endings System** — depends on: Narrative Choice, Chapter State

### Presentation Layer (UI)

1. **Combat HUD** — depends on: Combat, Health & Damage, Character Switching, Skill Execution
2. **Inventory UI** — depends on: Inventory & Equipment, Equipment Enhancement
3. **Dialogue UI** — depends on: Dialogue System
4. **Main Menu & Pause Menu** — depends on: Save / Load, Settings System
5. **Settings System** — depends on: Audio System, Input System

### Polish Layer

1. **Cosmetics System** — depends on: Character Data, Inventory & Equipment

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Character Data | MVP | Foundation | game-designer, systems-designer | L |
| 2 | Item Database + Item Rarity | MVP | Foundation | game-designer, economy-designer | M |
| 3 | Skill Database | MVP | Foundation | game-designer, systems-designer | M |
| 4 | Save / Load System | MVP | Foundation | game-designer | S |
| 5 | Health & Damage System | MVP | Core | systems-designer | M |
| 6 | Hit Detection System | MVP | Core | gameplay-programmer | S |
| 7 | Status Effects System | MVP | Gameplay | systems-designer | M |
| 8 | Skill Execution System | MVP | Gameplay | systems-designer, gameplay-programmer | M |
| 9 | Enemy AI System | MVP | Gameplay | ai-programmer, game-designer | M |
| 10 | Combat System | MVP | Combat | game-designer, systems-designer | L |
| 11 | Character State Manager | MVP | Combat | systems-designer, gameplay-programmer | M |
| 12 | Character Switching System | MVP | Party | game-designer, systems-designer | M |
| 13 | Inventory & Equipment System | MVP | Gameplay | game-designer, economy-designer | M |
| 14 | Loot & Drop System | MVP | Economy | economy-designer | M |
| 15 | Character Skill System | MVP | Progression | game-designer, systems-designer | L |
| 16 | Dialogue System | MVP | Narrative | narrative-director, game-designer | M |
| 17 | Chapter State System | MVP | Core | game-designer | S |
| 18 | Cutscene System | MVP | Narrative | narrative-director | M |
| 19 | Combat HUD | MVP | UI | ux-designer, ui-programmer | M |
| 20 | Dialogue UI | MVP | UI | ux-designer, ui-programmer | S |
| 21 | Main Menu & Pause Menu | MVP | UI | ux-designer, ui-programmer | S |
| 22 | Character Progression System | Alpha | Progression | systems-designer, economy-designer | M |
| 23 | Party AI System | Alpha | Party | ai-programmer, systems-designer | L |
| 24 | Party Management System | Alpha | Party | game-designer | S |
| 25 | Narrative Choice System | Alpha | Narrative | narrative-director, game-designer | M |
| 26 | NPC System | Alpha | World | game-designer, narrative-director | S |
| 27 | Shop System | Alpha | Economy | economy-designer | M |
| 28 | Village / Hub System | Alpha | World | game-designer, level-designer | M |
| 29 | Inventory UI | Alpha | UI | ux-designer | M |
| 30 | Settings System | Alpha | Meta | game-designer | S |
| 31 | Multiple Endings System | Full Vision | Narrative | narrative-director, game-designer | L |
| 32 | Equipment Enhancement System | Full Vision | Economy | economy-designer, systems-designer | M |
| 33 | Cosmetics System | Full Vision | Progression | game-designer, art-director | M |
| 34 | Scene Management System | MVP | Core | gameplay-programmer | S |
| 35 | Input System | MVP | Foundation | gameplay-programmer | S |
| 36 | Audio System | MVP | Foundation | audio-director | S |
| 37 | Camera System | MVP | Core | gameplay-programmer | S |
| 38 | Cosmetics System | Full Vision | Polish | art-director | M |

---

## Circular Dependencies

None found. The dependency graph is acyclic — all systems can be designed and
built in strict layer order.

**Note**: NPC System and Dialogue System might appear circular (NPCs trigger dialogue;
dialogue references NPCs) but they are not: the Dialogue System is data-driven and
doesn't depend on NPC System. NPCs call into the Dialogue System, not the reverse.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **Character Data** | Design | Schema is a dependency root — wrong design cascades to 10+ systems | Design this first, thoroughly; use `/design-system character-data` with extra review |
| **Party AI System** | Technical | RL training for real-time ARPG combat is unproven; training loop time is hard to estimate | Prototype Month 1 with `/prototype party-ai`; fallback: behavior trees with noise simulation |
| **Character State Manager** | Technical | Mid-combat state sync (HP, buffs, cooldowns on character swap) is error-prone | Prototype switching with 2 characters before designing the full system |
| **Character Skill System** | Scope | Multiple characters per role × unique skill sets = large balance surface | Design the data schema carefully; use ScriptableObjects to keep skills data-driven |
| **Multiple Endings System** | Design | Choice tracking across 4 chapters must feel earned, not arbitrary | Design Narrative Choice System first; endings are derived, not parallel branches |
| **Equipment Enhancement System** | Design | Enhancement levels could make base loot feel irrelevant if balance is wrong | Design after Loot & Drop; tuning knobs must be explicit |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 38 |
| Design docs started | 0 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 1 / 21 |
| Alpha systems designed | 0 / 10 |
| Full Vision systems designed | 0 / 4 |

---

## Next Steps

- [ ] Design system #1: **Character Data** — use `/design-system character-data`
- [ ] Run `/design-review` on each completed GDD
- [ ] Prototype Party AI in Month 1 — use `/prototype party-ai`
- [ ] Create ADR for RL vs. behavior tree — use `/architecture-decision`
- [ ] Run `/gate-check pre-production` when all MVP systems are designed
- [ ] Plan first sprint with `/sprint-plan new`
