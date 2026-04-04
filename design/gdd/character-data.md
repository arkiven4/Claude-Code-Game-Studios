# Character Data

> **Status**: Designed
> **Author**: Design session 2026-04-03
> **Last Updated**: 2026-04-03
> **Implements Pillar**: The Party Is the Game

## Overview

Character Data is the master definition for every character in the game — Evelyn, Evan,
the Witch, and all party members. Stored as Unity ScriptableObjects, each character's
data card defines their six base stats (MaxHP, ATK, DEF, SPD, MP, CRIT), their four
skill slots with three upgrade tiers each, their role in the party, and their per-level
growth rates. Players interact with Character Data indirectly: when they read a stat
screen, watch a skill upgrade unlock, or notice that their tanker is getting tougher
each level, they are seeing Character Data in action. Every other system in the game —
combat, loot, AI, skills, cosmetics — reads from these cards. Nothing in the game can
reference a character without going through their Character Data.

## Player Fantasy

Character Data serves the fantasy of **building a team you believe in**. When a player
levels up Evelyn and watches her MaxHP grow faster than Evan's, or unlocks a skill's
Tier 2 and sees it change from hitting one enemy to hitting three, they feel the
satisfaction of investment paying off. Each character should feel *distinct* — not
interchangeable numbers, but specific people with a shape. Evelyn hits hard and survives
longer than she should. Evan is precise and fast. The Tanker absorbs punishment that
would kill anyone else. This differentiation lives in Character Data's growth rates and
skill tiers. The player should feel, without reading a tooltip, that each companion has
a personality expressed through their numbers.

## Detailed Design

### Core Rules

1. Every character has exactly one `CharacterDataSO` ScriptableObject. It is read-only
   at runtime — only base/maximum values live here. Runtime state (current HP, cooldowns,
   buffs) lives in `PartyMemberState` (see ADR-0002).

2. Every character has a **CharacterClass** enum with the following values:
   `Swordman`, `Mage`, `Assassin`, `Healer`, `Tanker`, `Support`, `Archer`.
   Class determines stat growth weights, AI behavior profile, and loot drop filtering.
   Two characters can share a class but have entirely different skill sets
   (e.g., Evelyn and the Witch are both `Mage`).

3. Every character has **six base stats**:

   | Stat | Type | Min | Max | Description |
   |------|------|-----|-----|-------------|
   | MaxHP | int | 100 | 9999 | Maximum health points |
   | ATK | int | 10 | 999 | Base attack power applied to damage formulas |
   | DEF | int | 5 | 999 | Damage reduction applied before HP loss |
   | SPD | float | 0.5 | 3.0 | Multiplier on move and attack animation speed |
   | MaxMP | int | 50 | 999 | Energy pool consumed by skill usage |
   | CRIT | float | 0.0 | 1.0 | Probability of a critical hit (0% – 100%) |

4. The **active party** has 4 slots (index 0–3). Slots have no fixed class requirement —
   the player composes freely. Two Mages + Swordman + Tanker is as valid as any other
   combination.

5. Every character has exactly **4 skill slots** (`SkillSlot0`–`SkillSlot3`). Each slot
   references a `SkillDataSO` and stores the level thresholds at which Tier 2 and Tier 3
   unlock (see Skill Tier System).

6. Every character has a **growth profile** — a set of per-stat multipliers applied each
   level up (see Growth Rates section).

7. Every character has **narrative metadata**:
   - `DisplayName` (string) — shown in UI and dialogue
   - `PortraitSprite` (Sprite) — used in party HUD and dialogue UI
   - `RoleDescription` (string) — one-line description shown in party selection UI
   - `IsMainCharacter` (bool) — true for Evelyn, Evan, and the Witch only

8. No system may write to `CharacterDataSO` at runtime. It is a definition, not a
   state container. Any attempt to modify it is a bug.

### Skill Tier System

**Level Thresholds (global — same for every character):**

| Tier | Unlocks At | Notes |
|------|-----------|-------|
| Tier 1 | Level 1 (default) | Base skill — always available |
| Tier 2 | Level 8 | All 4 skill slots upgrade simultaneously |
| Tier 3 | Level 18 | All 4 skill slots upgrade simultaneously; arrives in Chapter 3 |
| Level Cap | Level 30 | No further tier unlocks after Tier 3 |

**Rules:**

1. When a character reaches Level 8 or Level 18, **all 4 of their skills upgrade at
   once**. There is no per-skill unlock order.
2. Each tier **replaces** the previous — the player always uses the highest unlocked
   tier. There is no choosing between tiers.
3. Tier upgrades are **qualitative changes** to how a skill works, not just stat bumps.
   Each skill's specific tier changes are defined in its `SkillDataSO` (Skill Database).
   Character Data only stores the global thresholds (Level 8, Level 18).
4. Tier upgrade categories (what can change between tiers):

| Category | Tier 1 Example | Tier 2 Example | Tier 3 Example |
|----------|---------------|---------------|---------------|
| **Target Count** | Hit 1 enemy | Hit 2 enemies | Hit 3 enemies |
| **Area** | Single target | Small AoE | Large AoE |
| **Effect Intensity** | Slow (20%) | Slow (40%) | Slow (60%) or Stun |
| **Buff Power** | +10% ATK to ally | +18% ATK to ally | +28% ATK to ally |
| **Duration** | Short DoT (3s) | Medium DoT (5s) | Long DoT (8s) |
| **Hybrid** | Single slow | AoE slow | AoE slow + DoT |

5. Each skill uses exactly one upgrade category. The specific category and values per
   skill are defined in `SkillDataSO`, not here.

### Growth Rates

**Formula** (applies to MaxHP, ATK, DEF, MaxMP only):
```
Stat at Level N = Base + (GainPerLevel × (N - 1))
```

**SPD and CRIT are fixed** — they do not grow per level. They are class identity
stats. Changes to SPD and CRIT come from equipment and buffs only.

---

**Base Stats at Level 1:**

| Class | MaxHP | ATK | DEF | SPD | MaxMP | CRIT |
|-------|-------|-----|-----|-----|-------|------|
| Swordman | 320 | 45 | 35 | 1.1 | 80 | 8% |
| Mage | 220 | 65 | 18 | 1.2 | 120 | 6% |
| Assassin | 240 | 55 | 20 | 1.6 | 70 | 20% |
| Healer | 280 | 25 | 28 | 1.1 | 140 | 4% |
| Tanker | 480 | 35 | 55 | 0.9 | 60 | 3% |
| Support | 270 | 30 | 30 | 1.2 | 130 | 5% |
| Archer | 260 | 58 | 22 | 1.3 | 80 | 15% |
| Witch (prologue only) | 200 | 70 | 15 | 1.2 | 130 | 6% |

---

**Flat Gains Per Level (generic party members, applied each level L2–L30):**

| Class | MaxHP/lvl | ATK/lvl | DEF/lvl | MaxMP/lvl |
|-------|-----------|---------|---------|-----------|
| Swordman | +18 | +3 | +2 | +3 |
| Mage | +12 | +5 | +1 | +5 |
| Assassin | +14 | +4 | +1 | +3 |
| Healer | +16 | +1 | +2 | +6 |
| Tanker | +28 | +2 | +3 | +2 |
| Support | +15 | +2 | +2 | +5 |
| Archer | +15 | +4 | +1 | +3 |

---

**Main Character Bonus (flat addend per level, stacks on top of class gain):**

Applied only to characters where `IsMainCharacter = true`.

| Character | Class | MaxHP bonus/lvl | ATK bonus/lvl | DEF bonus/lvl | MaxMP bonus/lvl |
|-----------|-------|-----------------|---------------|---------------|-----------------|
| Evelyn | Mage | +3 | +1 | +0 | +2 |
| Evan | Swordman | +4 | +1 | +1 | +1 |

Effective per-level gains for main characters:
- **Evelyn**: MaxHP +15, ATK +6, DEF +1, MaxMP +7
- **Evan**: MaxHP +22, ATK +4, DEF +3, MaxMP +4

---

**Stat Ranges at Key Milestones:**

| Class | MaxHP L1 | MaxHP L8 | MaxHP L18 | MaxHP L30 |
|-------|----------|----------|-----------|-----------|
| Evelyn (main) | 220 | 325 | 490 | 655 |
| Mage (generic) | 220 | 304 | 436 | 568 |
| Evan (main) | 320 | 474 | 694 | 958 |
| Swordman (generic) | 320 | 446 | 626 | 842 |
| Tanker | 480 | 676 | 952 | 1292 |
| Assassin | 240 | 338 | 478 | 646 |

| Class | ATK L1 | ATK L8 | ATK L18 | ATK L30 |
|-------|--------|--------|---------|---------|
| Evelyn (main) | 65 | 107 | 167 | 239 |
| Mage (generic) | 65 | 100 | 150 | 210 |
| Archer | 58 | 86 | 126 | 174 |
| Assassin | 55 | 83 | 123 | 171 |
| Evan (main) | 45 | 73 | 109 | 161 |
| Healer | 25 | 32 | 42 | 54 |

---

**Evelyn — Full Progression Example:**

| Level | MaxHP | ATK | DEF | SPD | MaxMP | CRIT |
|-------|-------|-----|-----|-----|-------|------|
| 1 | 220 | 65 | 18 | 1.2 | 120 | 6% |
| 8 (Tier 2 unlocks) | 325 | 107 | 25 | 1.2 | 169 | 6% |
| 18 (Tier 3 unlocks) | 490 | 167 | 35 | 1.2 | 239 | 6% |
| 30 (cap) | 655 | 239 | 47 | 1.2 | 323 | 6% |

At cap: highest ATK in the party, second-highest MaxMP. Glass cannon who can keep
skill cycling, with enough HP to feel like a protagonist.

### States and Transitions

`CharacterDataSO` is stateless — it has no runtime states or transitions. It is a
read-only data asset that never changes after the scene loads.

The character's runtime states (Alive, Dead, Controlled, AI-Controlled) are managed
by `PartyMemberState` (see ADR-0002), which reads base values from `CharacterDataSO`
on initialization.

**Initialization sequence (on scene load):**
1. `PartyMemberState.Awake()` reads its assigned `CharacterDataSO` reference
2. `CurrentHP` is set to `CharacterDataSO.MaxHP`
3. `CurrentMP` is set to `CharacterDataSO.MaxMP`
4. `SkillCooldowns[]` is initialized to `0f` for all 4 slots
5. Active skill tier is resolved:
   - Character level ≥ 18 → Tier 3 active on all 4 slots
   - Character level ≥ 8 → Tier 2 active on all 4 slots
   - Character level < 8 → Tier 1 active on all 4 slots

### Interactions with Other Systems

| System | Direction | What It Reads |
|--------|-----------|---------------|
| PartyMemberState | Reads CharacterDataSO | MaxHP, MaxMP on init; CharacterClass, IsMainCharacter |
| Health & Damage System | Reads CharacterDataSO | MaxHP (to clamp current HP); DEF (damage reduction) |
| Skill Execution System | Reads CharacterDataSO | SkillSlot0–3 references; active tier thresholds |
| Character Progression System | Reads CharacterDataSO | GainPerLevel values per stat; triggers tier unlock at L8 and L18 |
| Inventory & Equipment System | Reads CharacterDataSO | CharacterClass (to filter equippable items per character) |
| Loot & Drop System | Reads CharacterDataSO | CharacterClass (drop pool filter); selects 2 random party members per drop event |
| Party AI System | Reads CharacterDataSO | CharacterClass (selects correct AI behavior profile per role) |
| Party Management System | Reads CharacterDataSO | DisplayName, PortraitSprite, RoleDescription (party selection UI) |
| NPC System | Reads CharacterDataSO | DisplayName, PortraitSprite (dialogue portrait display) |
| Cosmetics System | Reads CharacterDataSO | IsMainCharacter (only main characters have cosmetic slots) |
| Combat HUD | Reads CharacterDataSO | DisplayName, PortraitSprite, MaxHP, MaxMP (HUD display) |

No system writes to CharacterDataSO at runtime. It is strictly a read source.

## Formulas

### Stat at Level N (generic)

```
Stat(N) = BaseStat + (GainPerLevel × (N - 1))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseStat | int or float | See base stats table | CharacterDataSO | Stat value at Level 1 |
| GainPerLevel | int or float | See gains table | CharacterDataSO | Fixed flat gain applied each level |
| N | int | 1–30 | Character Progression System | Current character level |

**Expected output ranges at level cap (L30):**

| Stat | Minimum | Maximum | Notes |
|------|---------|---------|-------|
| MaxHP | 568 (Mage generic) | 1292 (Tanker) | |
| ATK | 54 (Healer) | 239 (Evelyn) | |
| DEF | 47 (Mage) | 142 (Tanker) | |
| MaxMP | 118 (Tanker) | 323 (Evelyn) | |
| SPD | 0.9 (Tanker, fixed) | 1.6 (Assassin, fixed) | No growth — class identity stat |
| CRIT | 3% (Tanker, fixed) | 20% (Assassin, fixed) | No growth — class identity stat |

---

### Stat at Level N (main character)

```
Stat(N) = BaseStat + ((GainPerLevel + MainCharBonus) × (N - 1))
```

Only applied when `CharacterDataSO.IsMainCharacter = true`.
`MainCharBonus` defaults to `0` for any stat not listed in the main character bonus table.

| Variable | Type | Source | Description |
|----------|------|--------|-------------|
| MainCharBonus | int or float | CharacterDataSO | Per-stat flat bonus per level for main characters only |

---

### Active Skill Tier

```
if (characterLevel >= 18) activeTier = 3
else if (characterLevel >= 8) activeTier = 2
else activeTier = 1
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| characterLevel | int | 1–30 | Character Progression System |
| activeTier | int | 1–3 | Evaluated at scene load and on every level-up |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Two characters share the same `CharacterDataSO` | Not allowed — each character must have its own `.asset` file. Add a custom Editor validator to detect duplicate references. | Shared data would cause one character's stats to affect another |
| Character level saved as > 30 (data corruption) | Clamp to 30 on load. Log a warning. | Level cap is 30; no valid path exceeds it |
| Character level saved as < 1 (data corruption) | Clamp to 1 on load. Log a warning. | Level 1 is the minimum; negative levels are invalid |
| `GainPerLevel` is 0 for MaxHP, ATK, DEF, or MaxMP | Data authoring error — flag in a custom Unity Editor validator with a warning. SPD and CRIT intentionally have 0 gain and are exempt from this check. | 0-gain on growth stats is unintended; SPD/CRIT are fixed by design |
| `IsMainCharacter = true` on a generic party member | Bonus applies (technically valid), but designers must not set this flag outside Evelyn and Evan. Add an Editor warning if `IsMainCharacter = true` and `DisplayName` is not "Evelyn" or "Evan". | Prevents accidental protagonist bonuses on generic characters |
| Party has 0 characters (empty roster) | Not possible — Evelyn is always in the party and cannot be removed. Enforced by Party Management System. | Evelyn's presence is a narrative requirement tied to the ending |
| Skill slot references a null `SkillDataSO` | Log an error. Slot renders as greyed-out and unselectable in UI. Never crash. | Null skill slots are data authoring errors, not valid game states |
| Character level reaches 8 or 18 mid-combat | Tier upgrade is applied immediately. Active skill mid-cast completes at its old tier; next use applies the new tier. | Avoids mid-animation state corruption |

## Dependencies

| System | Direction | Nature |
|--------|-----------|--------|
| CharacterDataSO | Depends on nothing | Foundation — zero upstream dependencies |
| PartyMemberState | Depends on CharacterDataSO | Hard — cannot initialize without it |
| Health & Damage System | Depends on CharacterDataSO | Hard — needs MaxHP and DEF |
| Skill Execution System | Depends on CharacterDataSO | Hard — needs skill slot references and tier thresholds |
| Character Progression System | Depends on CharacterDataSO | Hard — reads GainPerLevel to apply on level-up |
| Inventory & Equipment System | Depends on CharacterDataSO | Hard — needs CharacterClass to filter equippable items |
| Loot & Drop System | Depends on CharacterDataSO | Hard — needs CharacterClass for drop pool filtering |
| Party AI System | Depends on CharacterDataSO | Hard — needs CharacterClass to select AI behavior profile |
| Party Management System | Depends on CharacterDataSO | Hard — needs DisplayName, PortraitSprite, RoleDescription for party UI |
| NPC System | Depends on CharacterDataSO | Soft — uses portrait/name; can fall back to defaults |
| Cosmetics System | Depends on CharacterDataSO | Soft — reads IsMainCharacter flag; cosmetics are an optional feature |
| Combat HUD | Depends on CharacterDataSO | Hard — needs MaxHP, MaxMP, and PortraitSprite for display |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect if Too High | Effect if Too Low |
|-----------|--------------|------------|-------------------|-------------------|
| Base MaxHP per class | See base stats table | ±30% of current values | Characters feel unkillable; combat tension drops | Characters die too fast; frustrating for casual players |
| Base ATK per class | See base stats table | ±25% of current values | Encounters end too quickly; no time for switching | Encounters drag; players feel ineffective |
| GainPerLevel (MaxHP) | See gains table | ±5 per class per level | Late-game characters overpower enemies | Characters feel fragile at high levels |
| GainPerLevel (ATK) | See gains table | ±2 per class per level | Damage outscales enemy DEF; trivializes late content | Skills feel weak at max level |
| MainCharBonus per stat | See bonus table | 0–+5 per stat per level | Main characters overpower generics; party feels irrelevant | No meaningful protagonist identity in numbers |
| Tier 2 unlock level | 8 | 5–12 | First upgrade feels delayed; early game monotonous | Tier 2 arrives before players understand Tier 1 |
| Tier 3 unlock level | 18 | 14–24 | Tier 3 only usable in final chapter | Tier 3 arrives too early; end-game feels expected |
| Level cap | 30 | 20–40 | Too much filler content needed between levels | Skill tiers arrive too close together |
| Fixed SPD per class | See base stats table | Tanker ≥ 0.7, Assassin ≤ 2.0 | Assassin animations become unreadable | Tanker feels stuck; frustrating to control |
| Fixed CRIT per class | See base stats table | 0%–35% | Assassin/Archer feel random and inconsistent | CRIT class identity disappears |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Level up | Full-screen warm glow on character portrait; stat numbers animate upward | Chime — warm, triumphant, brief | High |
| Tier 2 unlock (Level 8) | All 4 skill icons pulse with a golden outline; "TIER 2" text appears | Distinct ascending sound — more impactful than regular level-up | High |
| Tier 3 unlock (Level 18) | All 4 skill icons ignite with a stronger glow; "TIER 3" text appears | Powerful ascending sound — the most memorable unlock in the game | High |
| Character selected in party UI | Portrait highlights; stat block slides in | Soft selection sound | Medium |
| Skill slot null / unavailable | Slot icon greyed out with a lock icon | No sound | Low |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Character name + portrait | Combat HUD (party strip) | Static (never changes) | Always visible during combat |
| Current HP / MaxHP | Combat HUD (per character bar) | Every frame | Always visible during combat |
| Current MP / MaxMP | Combat HUD (per character bar) | Every frame | Always visible during combat |
| Skill icons (×4) with tier indicator | Combat HUD (active character only) | On tier unlock, on cooldown change | Always visible during combat |
| Full stat block (all 6 stats) | Character detail screen (menu) | On level-up | Opened from party menu |
| Level + XP progress | Character detail screen | On XP gain | Opened from party menu |
| Tier unlock progress ("Level 8 for Tier 2") | Character detail screen | On level-up | Shown until Tier 3 is unlocked |
| CharacterClass label | Party selection UI | Static | When composing party |

## Acceptance Criteria

- [ ] Every playable character (Evelyn, Evan, Witch, all party members) has a unique `CharacterDataSO` asset file
- [ ] `Stat(N) = BaseStat + (GainPerLevel × (N-1))` produces correct values for all classes at L1, L8, L18, L30 — verified by unit test
- [ ] Evelyn at L30 has MaxHP 655, ATK 239, DEF 47, MaxMP 323 — matches the example table exactly
- [ ] Tier 2 activates on all 4 skill slots at exactly Level 8; Tier 3 activates at exactly Level 18 — verified by unit test
- [ ] No system writes to `CharacterDataSO` at runtime — verified by code review
- [ ] Null `SkillDataSO` reference in a skill slot logs an error and renders the slot as greyed-out without crashing
- [ ] Level values outside 1–30 are clamped on save/load with a logged warning
- [ ] Two characters sharing the same `CharacterDataSO` triggers an Editor validator warning
- [ ] A character reaching Tier 2 or Tier 3 mid-combat completes the current skill cast at the old tier before upgrading
- [ ] `PartyMemberState` initializes `CurrentHP = MaxHP` and `CurrentMP = MaxMP` on scene load for all party members
- [ ] Performance: reading `CharacterDataSO` fields adds no measurable frame time (ScriptableObject field access is O(1))

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| How many generic party members will there be per class? (e.g., 2 Archers, 1 Tanker?) | Game Designer | Resolve during party roster design — affects total number of CharacterDataSO assets to author |
| Does the Witch need a full CharacterDataSO (growth rates, 4 skills) or a simplified prologue-only version? | Narrative Director | Resolve before Witch prologue chapter is authored — prologue is Month 1 MVP |
| Should CharacterClass be extensible (new classes added post-launch) or fixed? | Technical Director | Resolve before CharacterClass enum is coded — adding enum values later is a recompile |
| What XP amount is required per level? (Curve design — fast early, slower late?) | Systems Designer | Resolve in Character Progression System GDD |
