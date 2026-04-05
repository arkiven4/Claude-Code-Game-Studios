# Milestone 1: MVP — Core Loop Playable

> **Target Date**: 2026-05-16 (end of Sprint 3)
> **Stage**: Production
> **Status**: In Progress — First Playable complete; content sprint pending

---

## Success Criteria

The MVP is complete when a player can:

- [ ] Start a new game from the Main Menu and reach the Witch Prologue
- [ ] Play the Witch Prologue end-to-end (combat, dialogue, cutscene)
- [ ] Play Chapter 1 end-to-end with Evelyn and Evan as controllable characters
- [ ] Switch between Evelyn and Evan in real-time during combat
- [ ] Collect and assign loot drops after encounters
- [ ] Equip items to characters and see stats change
- [ ] Reach the Chapter 2 ending (the twist: Evelyn vanishes, Evan survives alone)
- [ ] Save and load game progress (1 save slot minimum)
- [ ] Use the Combat HUD to read HP, MP, cooldowns, and active character state

## Content Targets

| Content Piece | Status | Notes |
|---------------|--------|-------|
| Evelyn CharacterData | Done | `assets/data/characters/evelyn.tres` |
| Evan CharacterData | Done | `assets/data/characters/evan.tres` |
| Witch CharacterData | Done | `assets/data/characters/witch.tres` (CharacterClass.MAGE) |
| Evelyn skill set (4 skills × 3 tiers) | Done | Dark Bolt, Shadow Veil, Abyssal Chain, Eclipse Burst |
| Evan skill set (4 skills × 3 tiers) | Done | Crescent Slash, Shield Bash, Hunter's Mark, Rending Storm |
| Witch skill set (4 skills × 3 tiers) | Done | Hex Bolt, Spirit Ward, Moonfire, Coven's Wrath |
| Item set (10–15 equippable items) | Partial (5/10) | Starter weapons + armor + copper ring done; need 5–10 more |
| Enemy roster (5 types + 2 bosses) | Partial (2/7) | GruntMelee + ArcherRanged done; need 3 more types + 2 bosses |
| Witch Prologue scene (.tscn) | Not Started | ~20 min play |
| Chapter 1 scene (.tscn) | Not Started | ~30 min play |
| Chapter 2 scene + twist ending | Not Started | ~30 min play |
| Dialogue scripts (Prologue + Ch 1-2) | Not Started | |
| Prologue cutscene | Not Started | Witch's loss, her grief |
| Twist ending cutscene | Not Started | Evelyn vanishes |

## Explicitly NOT in MVP

- Multiple endings (main ending only — Evelyn's death)
- RL Party AI (BTPartyAgent fallback is acceptable)
- Shop / Village systems (placeholder hub acceptable)
- Full party roster (3 characters: Evelyn, Evan, Witch)
- Cosmetics system
- Chapter 3 and 4
- Character Progression System (characters are fixed level for MVP)
- Inventory UI screen (loot distribution screen is sufficient)

## Sprint Plan

| Sprint | Dates | Focus | Status |
|--------|-------|-------|--------|
| Sprint 1 | 2026-04-07 → 2026-04-18 | Core systems: Input, Camera, Item Database, Audio | Done (migrated) |
| Sprint 2 | 2026-04-21 → 2026-05-02 | Save/Load, Dialogue, HUD, Scene Management | Done (migrated) |
| Sprint 3 | 2026-05-05 → 2026-05-16 | First Playable: Enemy AI, Combat, Character Switching, Loot, HUD wiring | Done |
| Sprint 4 | TBD | Content: More items + enemies, Prologue scene, Chapter 1 scene, Dialogue | Not Started |
| Sprint 5 | TBD | Content: Chapter 2 + twist ending, Cutscenes, Save/Load integration | Not Started |

## Risks

| Risk | Mitigation |
|------|-----------|
| Dialogue/cutscene scope creep | Prologue only needs 1 cutscene + ~15 dialogue nodes for MVP |
| RL training not needed for MVP | BTPartyAgent is the working fallback — do not spend time on RL until MVP is shipped |
| Twist ending emotional impact unvalidated | Playtest after Chapter 1 is complete; adjust pacing if players aren't invested |
