# Character Progression System

> **Status**: Designed
> **Author**: Design session 2026-04-11 (user-directed)
> **Last Updated**: 2026-04-11
> **Implements Pillar**: Earn the Ending, The Party Is the Game

## Overview

The Character Progression System governs how characters grow in power throughout the game. Characters earn experience from two sources: **combat XP** (per-character, awarded for defeating individual enemies) and **encounter XP** (shared among the entire party, awarded upon clearing an encounter or dungeon segment). When a character's accumulated XP crosses a level threshold, they level up **at the end of the encounter** — stats, tier unlocks, and passive bonuses activate after combat concludes. Leveling is primarily **automatic**: each character's six stats grow according to their class-defined growth rates (flat linear progression up to Level 30). Additionally, at each level-up the player earns **2 bonus stat points** to allocate among a choice of three stats (ATK, DEF, or MaxMP), letting them slightly customize their companion's build. This hybrid model keeps progression accessible and story-paced while giving the player meaningful ownership of how their party grows. Level-ups also trigger the Tier 2 (L8) and Tier 3 (L18) skill upgrades defined in Character Data, and the passive unlocks defined in the Character Skill System.

## Player Fantasy

Character Progression serves the fantasy of **ownership and pride in your companions**. When Evelyn hits Level 12 and the player chose to put her bonus points into MaxMP instead of ATK, that Evelyn feels slightly *theirs* — not a preset stat block, but a character shaped by their decisions. The growth is mostly automatic (respecting the narrative pacing — the story decides when characters are strong enough), but those 2 bonus points per level are a quiet promise: *you get to shape this person*. Each character should feel like they're growing into their identity. Evelyn's ATK climbs because she's a vampire mage who hits hard. Evan's MaxHP grows because he's a hunter who survives. The bonus points let the player lean into or counter those identities. The player should feel, after 15 hours, that their party is *their* party — not the default party the game handed them.

**Reference model**: Tales of Berseria's warm party growth — characters feel stronger because you've been through things together, not because you crunched numbers. The bonus stat points add a whisper of Final Fantasy X's Sphere Grid ownership without the complexity.

## Detailed Design

### Core Rules

1. **Experience Sources**:
   - **Combat XP**: Awarded per-character for each enemy defeated. The character who lands the killing blow receives 100% of the enemy's Combat XP value. (Encourages active switching for last hits.)
   - **Encounter XP**: Awarded equally to all 4 party members upon clearing an encounter (all enemies in a combat area defeated). This ensures inactive party members still progress.
   - **Chapter Bonus XP**: Awarded equally to all party members upon chapter completion. Represents narrative-driven growth between chapters.

2. **XP Curve Formula**:
   ```
   XPRequired(L) = floor(80 × 1.2^(L-1))
   ```
   Where `L` is the target level. Total XP to reach Level 30 from Level 1: approximately **30,000 XP**.

3. **Level-Up Timing**: Level-ups are **deferred to the end of the encounter**. When a character's accumulated XP crosses a level threshold mid-combat, the level counter increments internally but stat changes, tier unlocks, and passive activations wait until the encounter ends. This avoids mid-combat state corruption.

4. **Automatic Stat Growth**: On level-up, each character's stats grow automatically according to their class-defined `GainPerLevel` values (see Character Data GDD). This is the primary source of stat growth — ~85-90% of a character's final stats come from auto-growth.

5. **Bonus Stat Points**: On level-up, the player receives **2 bonus stat points** to allocate among **ATK, DEF, or MaxMP**. Points can be split (1 ATK + 1 DEF) or concentrated (2 ATK). Bonus points add flat values to the character's stats:
   - +1 ATK = +1 to the character's ATK stat
   - +1 DEF = +1 to the character's DEF stat
   - +1 MaxMP = +1 to the character's MaxMP stat
   - Points **cannot** be allocated to SPD, CRIT, or MaxHP (these are class identity stats, fixed by design).

6. **Total Bonus Point Budget**: Over 29 level-ups (L1→L30), each character receives **58 bonus points**. Fully concentrated, this could add +58 ATK, +58 DEF, or +58 MaxMP, or any split. Compared to auto-growth totals (e.g., Evelyn L30 ATK = 239), +58 ATK represents a ~24% increase — meaningful but not game-breaking.

7. **Tier Unlocks**: When a character reaches Level 8 or Level 18, their skill tier upgrades activate at the end of that encounter (see Character Data GDD for tier rules).

8. **Passive Unlocks**: When a character reaches a passive unlock level (1, 5, 10, 15, 22, 28), the passive activates at the end of that encounter (see Character Skill System GDD for passive rules).

9. **Level-Up Notification Screen**: At the end of an encounter, for each character that leveled up:
   - Display new level
   - Show auto stat growth (green "+N" next to each stat that grew)
   - Present bonus point allocation UI (2 points to spend)
   - Show any tier unlocks ("All skills upgraded to Tier 2!")
   - Show any passive unlocks ("Evelyn learned: Dark skills cost 10% less MP")

10. **XP Overflow**: If combat + encounter XP pushes a character past multiple level thresholds (e.g., Level 7 with 270/275 XP defeats a boss worth 100 XP → jumps to Level 9), **all intermediate levels are processed**. The player gets bonus points for each level (2 per level × number of levels gained). All tier/passive unlocks for all crossed levels activate.

11. **Dead Characters Gain XP**: Dead party members still receive encounter XP and level up. Their bonus points are allocated by the player at the end of the encounter. Auto stat growth and passive unlocks still apply. (Prevents death from punishing progression.)

12. **Level Cap**: Level 30 is the hard cap. XP earned beyond Level 30 is discarded with a notification: "[Character] is at maximum level."

### States and Transitions

```
┌──────────────────────────────────────────────────────────────────────┐
│               Character Progression State (per character)             │
│                                                                       │
│  ┌─────────────┐    gains XP     ┌─────────────────┐                 │
│  │  At Rest    │ ──────────────▶ │  XP Accumulating │                 │
│  │ (no combat) │                 │  (in encounter)  │                 │
│  └──────┬──────┘                 └────────┬────────┘                 │
│         │                                  │ encounter ends          │
│         │ encounter ends                   ▼                         │
│         │ ◀───────────────── ┌─────────────────┐                     │
│         │                    │  Level-Up Queue  │                     │
│         │                    │  (deferred)      │                     │
│         │                    └────────┬────────┘                     │
│         │                             │ player allocates bonus pts   │
│         │                             ▼                              │
│         │                    ┌─────────────────┐                     │
│         │◀──────────────────│  Stats Applied  │                     │
│         │                    │  (tier/passive) │                     │
│         │                    └─────────────────┘                     │
└──────────────────────────────────────────────────────────────────────┘

State Definitions:
- **At Rest**: Character is outside combat. XP, level, and stats are stable.
- **XP Accumulating**: Character is in combat. Combat XP and encounter XP are
  added to a running total. Level thresholds may be crossed internally but
  no state changes occur until encounter end.
- **Level-Up Queue**: At encounter end, characters who crossed level thresholds
  enter this state. Auto stat growth is calculated. Player allocates bonus
  points. Tier and passive unlocks are identified.
- **Stats Applied**: All level-up effects are committed. Character returns to
  At Rest state with updated stats.
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Character Data** | Reads | Reads `GainPerLevel`, `BaseStat`, `IsMainCharacter`, tier thresholds (L8, L18) | — |
| **Character Skill System** | Reads + Triggers | Reads passive unlock levels; triggers passive activation on level-up | Passive definitions |
| **Health & Damage** | Notifies | Notifies when MaxHP changes (from equipment or level-up) so CurrentHP adjusts | Reads MaxHP for XP curve scaling (if any) |
| **Combat System** | Reads | Reads encounter end signal to trigger level-up resolution | Provides encounter completion event |
| **Enemy AI** | Reads | Reads enemy death to award Combat XP to killing character | — |
| **Loot & Drop** | Writes | Provides character levels to Loot System for drop-level filtering | — |
| **Inventory & Equipment** | Reads | Reads character level for equip restriction validation | — |
| **Party AI System** | Reads | Reads character level for expertise scalar tuning | — |
| **Combat HUD** | Writes | Sends level/XP updates for display; triggers level-up notification UI | — |
| **Save / Load** | Serialized | Level, XP, allocated bonus points per character are saved/loaded | — |
| **Chapter State System** | Reads | Reads chapter completion to award Chapter Bonus XP | — |

## Formulas

### XP Curve

```
XPRequired(L) = floor(80 × 1.2^(L-1))
```

| Level | XP Required | Cumulative XP | Est. Encounters |
|---|---|---|---|
| 1 | — | 0 | — |
| 2 | 80 | 80 | 3-4 |
| 3 | 96 | 176 | 4 |
| 4 | 115 | 291 | 4-5 |
| 5 | 138 | 429 | 5 |
| 6 | 166 | 595 | 5-6 |
| 7 | 199 | 794 | 6 |
| 8 | 239 | 1,033 | 6-7 |
| 9 | 287 | 1,320 | 7 |
| 10 | 344 | 1,664 | 8 |
| 11 | 413 | 2,077 | 8-9 |
| 12 | 496 | 2,573 | 9-10 |
| 13 | 595 | 3,168 | 10 |
| 14 | 714 | 3,882 | 11 |
| 15 | 857 | 4,739 | 12 |
| 16 | 1,028 | 5,767 | 13 |
| 17 | 1,234 | 7,001 | 14 |
| 18 | 1,481 | 8,482 | 15 |
| 19 | 1,777 | 10,259 | 16 |
| 20 | 2,132 | 12,391 | 17-18 |
| 21 | 2,559 | 14,950 | 18-19 |
| 22 | 3,071 | 18,021 | 20 |
| 23 | 3,685 | 21,706 | 21-22 |
| 24 | 4,422 | 26,128 | 23-24 |
| 25 | 5,306 | 31,434 | 25+ |
| 26 | 6,367 | 37,801 | 27+ |
| 27 | 7,641 | 45,442 | 29+ |
| 28 | 9,169 | 54,611 | 32+ |
| 29 | 11,003 | 65,614 | 35+ |
| 30 | 13,204 | 78,818 | 40+ |

### Formula Reference Table

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **XP Required** | `floor(80 × 1.2^(L-1))` | L = target level | Each level costs 20% more than previous |
| **Total XP to Level N** | `Σ XPRequired(L) for L in 1..N` | N = target level | Cumulative sum |
| **Final Stat** | `BaseStat + (GainPerLevel × (Level - 1)) + BonusPoints` | See below | Combines auto-growth + player choice |
| **Combat XP (per enemy)** | `EnemyBaseXP × TierMultiplier` | TierMultiplier: Normal=1.0, Elite=2.5, Boss=6.0 | Awarded to character who lands killing blow |
| **Encounter XP (shared)** | `floor(Sum(CombatXP of all enemies) × 0.5) ÷ 4` | Divided equally among 4 party members | Ensures inactive members still progress |
| **Chapter Bonus XP** | `chapterNumber × 200` | Ch1=200, Ch2=400, Ch3=600, Ch4=800 | Awarded equally to all party members |
| **Bonus Points per Level** | `2` | Fixed | Allocated among ATK, DEF, MaxMP |
| **Total Bonus Points (L30)** | `2 × 29 = 58` | — | Maximum customization budget |

### Variable Definitions

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseStat | int | See Character Data | CharacterData | Stat value at Level 1 |
| GainPerLevel | int | See Character Data | CharacterData | Flat stat increase per level |
| Level | int | 1-30 | This system | Current character level |
| BonusPoints | int | 0-58 | Player allocation | Points spent on ATK/DEF/MaxMP |
| EnemyBaseXP | int | 10-50 | Enemy data (Loot & Drop) | Base XP value of enemy type |
| TierMultiplier | float | 1.0/2.5/6.0 | This system | Scales XP by enemy difficulty |

## Edge Cases

1. **Dead characters gain full XP**: Dead party members receive the same encounter XP as living members. They can level up while dead. Bonus points are allocated by the player at encounter end. Auto stat growth and passive unlocks still apply. (Death should not punish narrative pacing.)

2. **Unspent bonus points**: If the player closes the level-up screen without spending all bonus points, the remaining points are **saved** and can be allocated at any time from the Character Detail menu. Points persist across saves. A HUD indicator shows "X unspent bonus points" on characters with pending points.

3. **Multi-level jump**: A boss fight can push a character up 3-4 levels at once. All intermediate levels are processed sequentially. The player gets 2 bonus points per level (e.g., +6 points for a 3-level jump). All tier/passive unlocks for crossed levels activate simultaneously.

4. **XP overflow past level cap**: If a character at Level 29 with near-cap XP defeats a boss that would push them past Level 30, they level to 30 and the remaining XP is discarded. Bonus points for the L29→L30 level-up are still awarded.

5. **Party member joins mid-game at higher level**: If a new party member joins in Chapter 3 and the party is already at Level 15, the new member starts at **the average level of the current party, minus 2** (e.g., avg 15 → new member joins at Level 13). They receive XP to reach that level instantly but do not get bonus points for levels they "skipped" — they start with their base auto-growth stats only. This prevents new members from being over-customized.

6. **Party member leaves permanently**: If a party member leaves (story event), their accumulated XP, level, and allocated bonus points are preserved in the save file. If they rejoin later, they return at their previous level.

7. **Save/load mid-encounter**: If the game is saved during combat and loaded, the XP accumulated during that encounter is preserved. The level-up queue fires when the encounter ends normally.

8. **Simultaneous level-ups for multiple characters**: If 3 characters level up at the same encounter end, the level-up screen shows all 3 characters sequentially (player chooses order). Each character's bonus points are allocated independently.

9. **Encounter XP with fleeing enemies**: If the player flees from an encounter (not all enemies defeated), **no encounter XP is awarded**. Combat XP from already-defeated enemies still counts. (Prevents XP farming by partial encounters + retreat.)

10. **Chapter bonus XP on incomplete chapter**: If the player saves mid-chapter and resumes, the chapter bonus XP is only awarded when the chapter completion flag is set by the Chapter State System.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Character Data | Reads | Hard — cannot function without stat definitions | Reads `GainPerLevel`, `BaseStat`, tier thresholds |
| Character Skill System | Reads + Triggers | Hard — passive unlocks depend on level events | Reads `PassiveUnlock` list; fires level-up events |
| Combat System | Reads | Hard — needs encounter end signal | Receives `OnEncounterEnded` event |
| Enemy AI / Loot & Drop | Reads | Hard — needs enemy death events for Combat XP | Receives `OnEnemyKilled(killerCharacter)` event |
| Chapter State System | Reads | Hard — needs chapter completion for bonus XP | Reads `OnChapterCompleted` event |
| Health & Damage | Notifies | Soft — notifies MaxHP changes | Calls `OnMaxHPChanged(character, delta)` |
| Combat HUD | Writes | Soft — provides level/XP data for display | Exposes `GetCharacterLevel()`, `GetCharacterXP()` |
| Save / Load | Serialized | Hard — persists level, XP, bonus points | JSON fields: `level`, `currentXP`, `bonusPointsRemaining`, `bonusPointAllocations` |
| Party AI System | Reads | Soft — reads character level for expertise | Exposes `GetCharacterLevel(characterId)` |
| Inventory & Equipment | Reads | Soft — reads level for equip checks | Exposes `GetCharacterLevel(characterId)` |
| Loot & Drop | Writes | Soft — provides levels for drop filtering | Exposes `GetAllPartyLevels()` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `XPBaseCost` | int | `80` | 50-120 | Early levels feel like a grind | Levels come too fast; no sense of growth |
| `XPGrowthRate` | float | `1.2` | 1.1-1.3 | Late levels feel impossible | Late game levels trivialized |
| `CombatXPMultiplier` | float | `1.0` | 0.5-2.0 | Combat XP dominates; encounter XP irrelevant | Combat feels unrewarding |
| `EncounterXPRatio` | float | `0.5` | 0.3-0.7 | Shared XP too generous; no incentive to kill | Inactive members fall behind |
| `BonusPointsPerLevel` | int | `2` | 1-5 | Player over-customizes; balance breaks | No sense of player agency |
| `ChapterBonusXPBase` | int | `200` | 100-400 | Chapter completion feels unrewarding | Chapters feel like XP padding |
| `NewMemberLevelOffset` | int | `-2` | -4 to 0 | New members join too strong | New members feel useless |
| `LevelCap` | int | `30` | 20-40 | Too much filler content needed | Skill tiers arrive too close together |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Encounter end — level up | Character portrait glows; level number increments with upward animation | Warm chime — ascending tone | High |
| Stat growth display | Green "+N" floats next to each stat that increased | Soft "tick" per stat | High |
| Bonus point allocation screen | Modal overlay with 3 stat options (ATK, DEF, MaxMP); point counter animates as spent | Click sound per point allocation | High |
| Tier unlock notification | "TIER 2" / "TIER 3" banner across screen; all 4 skill icons pulse | Ascending chord — more impactful than regular level-up | High |
| Passive unlock notification | "[Character] learned: [Passive]!" banner with passive icon | Distinct chime — unique from tier unlock | High |
| Level cap reached | "[Character] is at maximum level" — grey text, no animation | Soft "thud" — neutral feedback | Medium |
| Unspent bonus point indicator | Small "✦2" icon next to character portrait in HUD | No sound | Medium |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **Level-Up Notification** (post-encounter modal) | Character name, new level, stat growth (+N per stat), bonus point allocation UI (2 points to spend), tier unlock alerts, passive unlock alerts | Shown after any encounter where ≥1 character leveled up |
| **Combat HUD — XP Bar** | Small XP progress bar beneath each character's HP bar; shows current XP / XP to next level | Always visible during combat (active character only) |
| **Combat HUD — Unspent Points** | "✦N" indicator next to character portrait when bonus points are unspent | Only when unspent points > 0 |
| **Character Detail Screen** | Full stat block, level, XP progress bar, tier unlock progress ("Level 8 for Tier 2"), passive progression list (locked/unlocked), bonus point allocation history | Opened from party menu |
| **Bonus Point Allocation Menu** | 3 options (ATK +1, DEF +1, MaxMP +1) with current stat values; remaining points counter; "Confirm" and "Save for Later" buttons | Opened from level-up screen or Character Detail menu |

## Acceptance Criteria

- [ ] `XPRequired(L) = floor(80 × 1.2^(L-1))` produces correct values for all levels 2-30 — verified by unit test
- [ ] Total XP to reach Level 30 equals ~78,818 — matches the XP curve table
- [ ] Combat XP is awarded only to the character who lands the killing blow
- [ ] Encounter XP is divided equally among all 4 party members (including dead ones)
- [ ] Level-ups are deferred to encounter end — stats don't change mid-combat
- [ ] Bonus points (2 per level) can be allocated among ATK, DEF, MaxMP only — not SPD, CRIT, or MaxHP
- [ ] Unspent bonus points persist across saves and can be allocated from Character Detail menu
- [ ] Multi-level jumps process all intermediate levels with full bonus points and unlocks
- [ ] Tier 2 activates at Level 8, Tier 3 at Level 18 — verified against Character Data thresholds
- [ ] Passive unlocks fire at correct levels (1, 5, 10, 15, 22, 28) — verified against Character Skill System
- [ ] Chapter bonus XP awarded correctly (Ch1=200, Ch2=400, Ch3=600, Ch4=800)
- [ ] New party members join at average party level minus 2, without bonus points for skipped levels
- [ ] Fleeing from encounter awards Combat XP from defeated enemies but no Encounter XP
- [ ] Level 30 is a hard cap — XP beyond it is discarded with notification
- [ ] Evelyn at Level 30 with 0 bonus points: MaxHP 655, ATK 239, DEF 47, MaxMP 323 (matches Character Data example)
- [ ] Evelyn at Level 30 with all 58 bonus points in ATK: ATK = 297 — verified by unit test
- [ ] Save/load preserves character level, current XP, unspent bonus points, and bonus point allocations

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| What are the exact EnemyBaseXP values for Normal, Elite, and Boss enemy types? | Systems Designer | Resolve during Enemy AI System implementation — affects XP pacing |
| Should the bonus point allocation UI allow undoing previous allocations (respec)? | Game Designer | Resolve before Chapter 2 — recommendation: no respec for MVP |
| How does the Chapter Bonus XP scale if chapters have vastly different encounter counts? | Game Designer | Resolve during chapter authoring — may need per-chapter override |
| If a new party member joins at Level 13 (avg -2), what XP value do they start with? At the Level 13 threshold, or 0? | Systems Designer | Resolve before character recruitment design — recommendation: start at 0 XP within their level |
| Should the XP curve be flattened for the Witch (prologue-only character) since she doesn't progress beyond the prologue? | Narrative Director + Systems Designer | Resolve during Witch prologue design — recommendation: fixed Level 1, no progression in prologue |
