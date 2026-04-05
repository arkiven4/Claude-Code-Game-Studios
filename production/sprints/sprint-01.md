# Sprint 1 — 2026-04-07 to 2026-04-18

## Sprint Goal

Stand up the four foundation systems (Character Data, Skill Database, Input, Camera) and the Item Database so that every downstream system in Milestone 1 has the data schemas and input/camera infrastructure it depends on.

## Capacity

- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work and bug fixes
- Available: 8 days

## Agent Assignment

> Two agents work in parallel. Agent A owns programmer systems (code-heavy). Agent B owns data and content (ScriptableObject schemas + assets). Both start Day 1.

### Agent A — Programmer
`S1-03` Input Actions Asset → `S1-04` InputManager wrapper → `S1-07` Camera System
Tests: `S1-12`
*Estimated wall-clock: ~3.25 days*

### Agent B — Data & Content
`S1-01` CharacterDataSO schema → `S1-02` 3 char assets → `S1-05` SkillDatabaseSO schema → `S1-06` 12 skill assets
`S1-01` → `S1-08` ItemEquipmentSO schema → `S1-09` 5 item assets
Tests: `S1-10`, `S1-11`
*Estimated wall-clock: ~3.75 days (longest track)*

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S1-01 | **CharacterDataSO schema** — Create `CharacterDataSO` ScriptableObject with 6 base stats (MaxHP, ATK, DEF, SPD, MaxMP, CRIT), CharacterClass enum (7 values), 4 skill slots with 3 upgrade tiers each, per-level growth rates, and role field. All fields validated with min/max ranges per design doc. | Agent B | 0.5 | None | SO compiles; Inspector shows all fields with correct types and ranges; CharacterClass enum has all 7 values; skill slots array length is exactly 4 |
| S1-02 | **Create 3 CharacterDataSO assets** — Evelyn (Mage, high ATK/low MaxHP), Evan (Swordman, balanced stats), Witch (Mage, prologue-only, higher ATK/lower MaxHP than Evelyn). Populate all fields per character-data.md stat tables. | Agent B | 0.5 | S1-01 | 3 SO assets exist in `Assets/Data/Characters/`; all 6 stats populated within valid ranges; class enums correct; no fields at default/zero |
| S1-03 | **Input Actions Asset** — Create Unity Input Action Asset with 3 action maps (Exploration, Combat, UI). Exploration: Move (Vector2), Interact (Button), CameraOrbit (Vector2), Pause (Button). Combat: Skill1-4 (Button), SwitchNext/Prev (Button), Dodge (Button), BasicAttack (Button), TargetLock (Button). UI: Navigate (Vector2), Confirm (Button), Cancel (Button), TabLeft/Right (Button). Bind keyboard + gamepad defaults per input-system.md. | Agent A | 0.5 | None | `.inputactions` asset exists; all 3 action maps present with all listed actions; keyboard and gamepad bindings assigned; asset compiles without errors |
| S1-04 | **InputManager wrapper** — Create `InputManager` class wrapping the Input Action Asset. `EnableActionMap(string)` switches maps (only one active at a time). Exposes C# events per action (`OnMove`, `OnSkill1`, etc.). Implements input buffer (0.15s window) and `FlushBuffer()`. DI or SO channel pattern — no singleton, no legacy `Input` class. | Agent A | 1.0 | S1-03 | `InputManager.cs` compiles; `EnableActionMap("Combat")` disables other maps; C# events fire correctly in Play Mode; `FlushBuffer()` clears pending inputs; no `UnityEngine.Input` references |
| S1-05 | **SkillDatabaseSO schema** — Create `SkillSO` ScriptableObject with fields: SkillID (string), DisplayName, Description, SkillType enum (Active/Passive/Ultimate), damage formula scalar (float), base cooldown (float), MP cost (float), status effects applied (list of StatusEffectSO refs — can be null for now), animation trigger string, tier upgrades array (×3 tiers with flat bonuses: +damage scalar, -cooldown, -MP cost), CharacterClass restriction. All tunable values exposed in Inspector. | Agent B | 0.5 | S1-01 (CharacterClass enum) | SO compiles; Inspector shows all fields; SkillType enum has 3 values; tier upgrade array length is exactly 3; CharacterClass restriction references S1-01 enum |
| S1-06 | **Create 12 Skill assets** — Evelyn ×4 (Dark Bolt, Shadow Veil, Abyssal Chain, Eclipse Burst), Evan ×4 (Crescent Slash, Shield Bash, Hunter's Mark, Rending Storm), Witch ×4 (Hex Bolt, Spirit Ward, Moonfire, Coven's Wrath). Populate all fields per `design/gdd/skill-database.md`. Tier upgrades use flat bonuses only. Class restrictions applied correctly. | Agent B | 1.0 | S1-05 | 12 SO assets in `Assets/Data/Skills/`; all fields populated; skills restricted to correct class; damage scalars and cooldowns match design doc values; no fields at default/zero |
| S1-07 | **Camera System — Cinemachine + CameraController** — Create 3 virtual cameras: Exploration (third-person, 8u behind, 4u above, 15° down), Combat (tracking, dynamic distance: 6/8/10u based on enemy count 1/3/5+), Cinematic (authored, no auto-behavior). `CameraController` switches modes via game state. Transitions: Exploration→Combat 0.5s, Combat→Exploration 0.3s, Any→Cinematic 0.2s fade, Cinematic→Previous 0.3s. Reads CameraOrbit input from `InputManager`. | Agent A | 1.5 | S1-04 (orbit input) | 3 virtual cams in scene; `CameraController.SetMode(CameraMode.Combat)` activates correct cam with correct blend time; combat cam distance correct at enemy counts 1, 3, 5; `SetCinematicPosition(Vector3, Quaternion)` positions cinematic cam |

### Should Have

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S1-08 | **ItemEquipmentSO schema** — `ItemEquipmentSO` with: ItemID (string), DisplayName, Description, EquipSlot enum (Weapon/Armor/Helmet/Accessory/Relic), Rarity enum (Common/Uncommon/Rare/Epic/Legendary), base stat modifiers (ATK/DEF/SPD/MaxHP/MaxMP/CRIT bonuses), CharacterClass restriction (list), level requirement, sell price, icon (Sprite ref via Addressables). `ItemRaritySO` with multiplier per rarity tier. | Agent B | 0.5 | S1-01 (CharacterClass enum) | SO compiles; EquipSlot enum 5 values; Rarity enum 5 values; `ItemRaritySO` multipliers: Common=1.0, Uncommon=1.15, Rare=1.35, Epic=1.6, Legendary=2.0 |
| S1-09 | **Create 5 example Item assets** — 2 weapons (Evelyn staff + Evan sword), 2 armors (Mage robe + Swordman chain mail), 1 accessory (generic ring). Populate all fields per item-database.md. Class restrictions applied. Rarity multipliers applied to base stats. | Agent B | 0.5 | S1-08 | 5 SO assets in `Assets/Data/Items/`; all fields populated; class restrictions correct; rarity multipliers applied; no fields at default/zero |
| S1-10 | **Unit tests — CharacterDataSO** — Verify all 6 stats within min/max ranges; CharacterClass enum values correct; skill slot count is exactly 4; growth rates are positive. Test all 3 created SO assets. | Agent B | 0.25 | S1-02 | All tests pass in Unity Test Runner; ≥5 test methods; tests fail correctly on out-of-range data |
| S1-11 | **Unit tests — ItemSO rarity multiplier** — Verify multiplier values match design doc; verify stat modifier calculation with multiplier; verify Common=1.0 (identity); test edge cases (0 base stat, max base stat). | Agent B | 0.25 | S1-08 | All tests pass; ≥4 test methods; multiplier math verified for all 5 rarity tiers |
| S1-12 | **Unit tests — InputManager** — Verify only one action map active after `EnableActionMap()`; verify `FlushBuffer()` clears pending inputs; verify buffer holds input for 0.15s window. | Agent A | 0.25 | S1-04 | All tests pass; ≥3 test methods; action map exclusivity verified |

### Nice to Have

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S1-13 | **Camera shake + hit effects** — Cinemachine Impulse on heavy hits, zoom-in on critical hits (temporary FOV change over 0.3s). `CameraController.Shake(intensity)` public API for use by Combat system later. | Agent A | 0.5 | S1-07 | `Shake(intensity)` triggers Cinemachine Impulse; FOV zoom-in triggers and recovers smoothly; slow-mo does not affect UI |

## Carryover from Previous Sprint

N/A — Sprint 1

## Critical Path

```
Agent B track (longest — ~3.75d):
  S1-01 (CharacterDataSO, 0.5d)
    → S1-02 (3 char assets, 0.5d)
    → S1-05 (SkillDatabaseSO, 0.5d)
      → S1-06 (12 skill assets, 1.0d)
    → S1-08 (ItemEquipmentSO, 0.5d)  [parallel with S1-05]
      → S1-09 (5 item assets, 0.5d)
    → S1-10 + S1-11 (tests, 0.5d)

Agent A track (~3.25d):
  S1-03 (Input Actions, 0.5d)
    → S1-04 (InputManager, 1.0d)
      → S1-07 (Camera System, 1.5d)
      → S1-12 (Input tests, 0.25d)
```

Both agents start Day 1. Agent B's track is the sprint bottleneck at ~3.75 days wall-clock.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Unity 6.3 Cinemachine API changes (post-cutoff) | High | Medium — +0.5-1 day to Camera tasks | Verify Cinemachine API against `docs/engine-reference/` before writing camera code |
| CharacterDataSO schema wrong — ripples to 10+ downstream systems | Medium | High — rework across combat, loot, AI, skills | Review schema against all 21 design docs before creating assets; get explicit approval on field list first |
| SkillSO StatusEffectSO references are null until Sprint 2 | Low | Low — field is a list ref, can be empty | Mark field as optional in doc comments; Sprint 2 will populate when StatusEffectSO is created |
| Solo developer — no slack for unexpected blockers | High | Medium | 20% buffer reserved; Nice to Have cut first; 2-agent parallelism reduces wall-clock time |

## Dependencies on External Factors

- Unity 6.3 LTS installed, project opens without errors
- Cinemachine package installed via Package Manager (verify Unity 6.3 compatibility)
- Unity Input System package (`com.unity.inputsystem`) installed and active in Player Settings
- Unity Addressables package installed (Item icon references use Addressable sprites)
- No external art or audio assets needed — all Sprint 1 work uses placeholder/empty references

## Sprint Status

> **COMPLETED AHEAD OF SCHEDULE** — All implementation tasks finished before sprint start
> date (2026-04-07). Code and data assets verified present. Unit tests (S1-10, S1-11,
> S1-12) were not written — deferred as tech debt.

## Definition of Done for this Sprint

- [x] All Must Have tasks (S1-01 through S1-07) completed and verified
- [x] S1-08 ItemEquipmentSO + S1-09 5 item assets — completed
- [ ] Unit tests S1-10 (CharacterDataSO), S1-11 (ItemRarity), S1-12 (InputManager) — NOT WRITTEN (tech debt)
- [x] No forbidden patterns; all gameplay values in ScriptableObjects; public APIs have XML docs
- [x] Design documents in place for all implemented systems
- [x] Code committed to main
- [x] Sprint 2 dependencies unblocked: CharacterData, SkillDatabase, ItemDatabase, Input all available
