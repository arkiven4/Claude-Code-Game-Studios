# Character Skill System

> **Status**: Approved
> **Author**: Design session 2026-04-04 (user-directed)
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (passive mastery makes each character feel unique)

## Overview

The Character Skill System grants characters **passive bonuses** at specific character
levels, layered on top of the active skill tier system defined in the Skill Database and
Character Data GDDs. These passive bonuses are not new active skills or skill variants —
they are permanent, always-active modifiers that enhance how a character interacts with
their existing skills. Examples: "Evelyn: Dark skills cost 10% less MP," "Evan: Counter-
attacks deal +20% damage," "Tanker: Taunt duration +2s." Each character has a progression
of passive unlocks at specific levels (independent of the global Tier 2/Tier 3 skill
upgrades at Level 8 and Level 18). These passives are displayed in the Character Detail
screen and the Combat HUD. They require no player activation — they are always on once
unlocked.

## Player Fantasy

Character Skill serves the fantasy of **mastering a specific character over time**. When
Evelyn hits Level 5 and unlocks "Dark Affinity: Dark skills cost 10% less MP," the player
feels like she's growing into her identity as a vampire mage. When Evan reaches Level 12
and gains "Hunter's Instinct: +15% damage against bosses," the player feels like he's
becoming the master hunter he was meant to be. These passives don't change what buttons
the player presses — they make the same buttons hit harder, cost less, or last longer.
Each character's passive progression is unique, reinforcing their individual identity.
The player should feel that leveling up a specific character is always a surprise worth
celebrating.

**Reference model**: Final Fantasy X's Sphere Grid nodes (passive bonuses along the path),
League of Legends champion mastery (passive bonuses that reinforce identity), and
Xenoblade's affinity chart system (always-on modifiers that change how you play).

## Detailed Rules

### Core Rules

1. **PassiveUnlocks Definition**: Each `CharacterData` includes a list of passive
   unlocks:
   ```
   PassiveUnlock:
   ┌─────────────────────────────────────────────────┐
   | UnlockLevel: int                                 |
   | PassiveType: enum                                |
   | PassiveValue: float                              |
   | Description: string                              |
   | Icon: Sprite (optional, for HUD display)         |
   └─────────────────────────────────────────────────┘

   PassiveType enum values:
   - MPReduction         (skills of a category cost less MP)
   - DamageBonus         (skills of a category deal more damage)
   - CooldownReduction   (skills of a category have shorter cooldown)
   - DurationExtension   (buffs/debuffs from skills last longer)
   - DefenseBonus        (character takes reduced damage)
   - HealingBonus         (healing skills restore more HP)
   - ThreatBonus         (character generates more threat)
   - CritDamageBonus     (critical hits deal extra multiplier)
   - ReviveBonus         (revived characters return with more HP)
   - Special             (unique character-specific effect)
   ```

2. **Passive Unlock Levels** (per-character progression):
   Each character has 5–6 passive unlocks spread across levels 1–30:

   | Unlock Level | Purpose |
   |--------------|---------|
   | Level 1 | Identity passive (defines the character's starting flavor) |
   | Level 5 | Early combat enhancement |
   | Level 10 | Mid-game power bump |
   | Level 15 | Pre-Tier 3 enhancement |
   | Level 22 | Late-game bonus |
   | Level 28 | Near-cap mastery (optional, for main characters) |

   Not all characters have all 6 unlocks. Generic party members have 3–4 passives.
   Main characters (Evelyn, Evan) have all 6.

3. **Passive Application**: Passives are **always active** once unlocked. They are
   evaluated at the point of use:
   - **MPReduction**: Applied when calculating skill MPCost. `EffectiveMPCost = BaseMPCost × (1 - PassiveValue)`
   - **DamageBonus**: Applied as a multiplier in the damage formula. `FinalDamage = BaseDamage × (1 + PassiveValue)`
   - **CooldownReduction**: Applied to skill cooldowns. `EffectiveCooldown = BaseCooldown × (1 - PassiveValue)`
   - **DurationExtension**: Applied to buff/debuff durations. `EffectiveDuration = BaseDuration × (1 + PassiveValue)`
   - **DefenseBonus**: Applied as damage reduction. `FinalDamage = IncomingDamage × (1 - PassiveValue)`
   - **HealingBonus**: Applied to heal amounts. `FinalHeal = BaseHeal × (1 + PassiveValue)`
   - **ThreatBonus**: Applied to threat generation. `Threat += damage × (1 + PassiveValue)`
   - **CritDamageBonus**: Applied to critical hit multiplier. `CritMultiplier = 1.5 + PassiveValue`
   - **ReviveBonus**: Applied to revive HP. `ReviveHP = MaxHP × (0.25 + PassiveValue)`
   - **Special**: Case-by-case effect, defined per character

4. **Category-Restricted Passives**: Some passives apply only to skills of a specific
   damage category:
   - "Dark skills cost 10% less MP" → applies only to skills with `Category = Dark`
   - "Physical skills deal +15% damage" → applies only to skills with `Category = Physical`
   - Passives without a category restriction apply to all skills

5. **No Active Skill Changes**: This system does NOT add new active skills, new skill
   variants, or new skill slots. Characters always have exactly 4 active skill slots
   with 3 tiers each. Passives are a separate, parallel progression system.

6. **Passive Display**:
   - **Combat HUD**: Unlocked passives are shown as small icons below the character's
     skill bar (active character only). Hovering shows the passive description.
   - **Character Detail Screen**: All passives (locked and unlocked) are listed with
     their unlock level. Locked passives show a lock icon and the required level.
   - **Unlock Notification**: When a passive unlocks (on level-up), a full-screen
     notification appears: "[CharacterName] learned [PassiveDescription]!" with the
     passive icon and a chime sound.

7. **Passive Stacking with Equipment**: Passive bonuses stack additively with equipment
   bonuses of the same type:
   - Evelyn's "Dark skills cost 10% less MP" + equipment "Dark skills cost 5% less MP"
     = 15% total MP reduction
   - Caps still apply (e.g., Cooldown Reduction Cap of 40% includes passive + equipment)

8. **Special Passives**: Main characters may have unique passives that don't fit the
   standard enum. These are defined as `Special` type with a character-specific effect:
   - **Evelyn — "Bloodline" (Level 28)**: "When Evelyn's HP drops below 25%, her next
     Dark skill costs no MP." (Once per encounter)
   - **Evan — "Mercy" (Level 28)**: "When Evan lands the killing blow on an enemy, all
     party members heal 5% of their MaxHP."

   **Implementation contract for `Special` passives**: Each character with a `Special`
   passive has a dedicated child `Node` on their root Node3D that implements the
   Special Passive Protocol:
   ```gdscript
   # Special Passive Protocol — implement these methods on the passive's Node:
   # func on_skill_activated(context: Dictionary) -> void
   # func on_damage_dealt(context: Dictionary) -> void
   # func on_hp_threshold_crossed(hp_percent: float) -> void
   # func on_killing_blow(context: Dictionary) -> void
   ```
   The Skill Execution System and Health & Damage System call the appropriate method
   at each trigger point. Characters without a `Special` passive have no node — callers
   check `if passive_node != null` before calling. Concrete scripts:
   `evelyn_bloodline_passive.gd`, `evan_mercy_passive.gd`.

### States and Transitions

```
┌──────────────────────────────────────────────────────────────────────┐
│               Character Passive Progression                           │
│                                                                       │
│  Evelyn:                                                               │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐              │
│  │ Lvl 1│  │ Lvl 5│  │Lvl 10│  │Lvl 15│  │Lvl 22│  │Lvl 28│         │
│  │Dark  │  │Dark  │  │ATK   │  │DoT   │  │CRIT  │  │Blood-│         │
│  │-10%  │  │+15%  │  │+8%   │  │Dur+3s│  │Dmg+10│  │line  │         │
│  │MP    │  │DMG   │  │      │  │      │  │%     │  │      │         │
│  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘  └─────┘              │
│     ✓         ✓         ✓         ✓         ✓         🔒             │
│   unlocked  unlocked  unlocked  unlocked  unlocked  (needs Lvl 28)   │
└──────────────────────────────────────────────────────────────────────┘

Transitions:
  Character levels up → Check if any passive unlock level is reached
  Passive unlocked  → Always-on effect activates; notification fires
  Passive cannot be "unlearned" or reset once unlocked
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Character Data** | Reads | Reads PassiveUnlock list from CharacterData |
| **Skill Execution** | Read by | Reads passives to modify MPCost, damage, cooldown, duration |
| **Health & Damage** | Read by | Reads DefenseBonus, CritDamageBonus, HealingBonus passives |
| **Combat System** | Read by | Reads ThreatBonus passives for threat calculation |
| **Character Progression** | Read by | Triggers passive unlock notifications on level-up |
| **Combat HUD** | Read by | Displays unlocked passive icons for active character |
| **Party AI** | Read by | AI agents factor passive bonuses into skill scoring |
| **Save / Load** | Serialized by | Tracks which passives are unlocked (derived from character level) |
| **Audio System** | Calls | Plays passive unlock chime sound |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `EffectiveMPCost` | `BaseMPCost × (1 - MPReduction)` | Capped at 0 (never negative MP cost) |
| `EffectiveDamage` | `BaseDamage × (1 + DamageBonus)` | Stacks with equipment damage bonus |
| `EffectiveCooldown` | `BaseCooldown × (1 - CooldownReduction)` | Subject to 40% cap (with equipment) |
| `EffectiveDuration` | `BaseDuration × (1 + DurationExtension)` | No cap |
| `EffectiveDefense` | `IncomingDamage × (1 - DefenseBonus)` | Stacks additively with equipment DEF% |
| `EffectiveHeal` | `BaseHeal × (1 + HealingBonus)` | Stacks with equipment healing bonus |
| `CritMultiplier` | `1.5 + CritDamageBonus` | Base 1.5x + passive bonus |
| `ReviveHP` | `MaxHP × (0.25 + ReviveBonus)` | Base 25% + passive bonus |
| `ThreatGenerated` | `damage × (1 + ThreatBonus)` | Passive multiplier on threat |
| `PassiveUnlockCheck` | `character.Level >= passive.UnlockLevel` | Evaluated on level-up |

## Edge Cases

1. **Multiple passives of the same type on one character**: All stack additively. If
   Evelyn has "Dark skills -10% MP" (Level 1) and "Dark skills -5% MP" (Level 15), the
   total is -15% MP cost. Caps still apply (e.g., MP cost cannot go below 0).

2. **Passive + equipment bonus exceeds the cap**: The Cooldown Reduction Cap (40%)
   includes ALL sources: passive + equipment. If a character has 15% passive cooldown
   reduction and 30% equipment cooldown reduction, the total is capped at 40%. The
   excess 5% is ignored. A tooltip explains: "Cooldown Reduction at maximum."

3. **Special passive triggers during a state transition**: Evelyn's "Bloodline" passive
   (free Dark skill at <25% HP) triggers when her HP crosses the 25% threshold. If she
   crosses it during a skill animation, the passive activates for the NEXT skill use,
   not the current one. The free skill must be a Dark-category skill.

4. **Passive unlock happens mid-combat (level-up during encounter)**: The passive
   activates immediately. If it's a damage bonus, the next skill use benefits from it.
   If it's a cooldown reduction, the current cooldown tick uses the new value. No
   mid-animation state corruption.

5. **Character dies and is revived after a passive was about to unlock**: The passive
   unlock is tied to level, not combat state. If the character levels up (via XP gain
   from the encounter that killed them), the passive unlocks regardless of alive/dead
   state.

6. **Passive references a category the character has no skills in**: The passive is
   still unlocked and displayed. It simply has no effect (e.g., "Holy skills cost less
   MP" on a character with no Holy skills). This is a content authoring oversight, not
   a system error.

7. **Save file loaded at a level where passives should already be unlocked**: The system
   evaluates all passives against the loaded character level. Any passives with
   `UnlockLevel <= character.Level` are marked as unlocked. No passives are missed.

## Dependencies

- **Depends on**: Character Data (passive definitions), Skill Execution (reads passives
  to modify skill parameters), Character Progression (level-up triggers) — **Note:
  Character Progression System is Not Started (#17). Passive unlocks will not fire in
  gameplay until it is implemented. For isolated testing, force-set character level on
  the `CharacterData` directly to verify passive unlock behavior.**
- **Depended on by**: Combat HUD (displays passive icons), Party AI (factors passives
  into skill scoring), Health & Damage (reads defense/crit/heal passives), Save / Load
  (passive state is derived from level)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `PassivesPerMainChar` | int | `6` | Main characters have 6 passive unlocks |
| `PassivesPerGenericChar` | int | `3–4` | Generic party members have fewer passives |
| `MPReductionRange` | float | `5–15%` | Typical MP reduction per passive |
| `DamageBonusRange` | float | `8–20%` | Typical damage bonus per passive |
| `CooldownReductionRange` | float | `5–10%` | Per passive; subject to 40% total cap |
| `CooldownReductionCap` | float | `0.40` | Max CDR from **all sources combined** (passive + equipment); enforced by Skill Execution System at calculation time |
| `CritDamageBonusRange` | float | `5–15%` | Added to base 1.5x crit multiplier |
| `SpecialPassiveLimit` | int | `1` | Max special passives per character (usually at Level 28) |

## Visual/Audio Requirements

- **Passive Unlock Notification**: Full-screen banner: "[CharacterName] learned
  [PassiveDescription]!" with the passive icon, a golden glow animation, and an
  ascending chime sound.
- **Passive Icons**: Small icons (24x24) displayed below the active character's skill
  bar in the Combat HUD. Locked passives show a lock icon.
- **Character Detail Screen**: Lists all passives with their unlock level, description,
  and unlock status (locked/unlocked).

## UI Requirements

- **Combat HUD Passive Row**: Below the skill bar, a horizontal row of passive icons
  for the active character. Unlocked passives are visible; locked passives show a lock.
  Hover tooltip shows the passive description.
- **Character Detail Screen — Passive Section**: A dedicated section showing the full
  passive progression for each character, similar to the skill tier display but for
  passives.
- **Passive Unlock Notification**: Modal overlay (non-blocking) that appears for 3
  seconds after a passive unlocks, then fades out.

## Acceptance Criteria

- [ ] Each character's PassiveUnlock list is loaded from CharacterData on scene load
- [ ] Passives activate automatically when character level reaches UnlockLevel
- [ ] MPReduction passives reduce skill MPCost correctly for the specified category
- [ ] DamageBonus passives increase skill damage correctly for the specified category
- [ ] CooldownReduction passives reduce skill cooldowns correctly (subject to 40% cap)
- [ ] DurationExtension passives increase buff/debuff durations correctly
- [ ] DefenseBonus passives reduce incoming damage correctly
- [ ] HealingBonus passives increase heal amounts correctly
- [ ] CritDamageBonus passives increase critical hit multiplier correctly
- [ ] Special passives execute their unique effect correctly
- [ ] Passive bonuses stack additively with equipment bonuses of the same type
- [ ] Passive + equipment bonuses respect the Cooldown Reduction Cap (40%)
- [ ] Passive unlock notification fires on level-up with correct character, description, and icon
- [ ] Passive icons display in Combat HUD for the active character
- [ ] Locked passives show lock icon with unlock level tooltip
- [ ] Passive state is correctly restored on save/load (derived from character level)
- [ ] Passives that reference categories the character has no skills in are harmless (no effect, no crash)

## Open Questions

- Should passives be visible to the player BEFORE they unlock (as a preview of what's
  coming)? Currently, locked passives show a lock icon with unlock level. Showing the
  full description would build anticipation but might spoil the surprise. Recommendation:
  show the description but greyed out, so the player knows what to work toward.
- Should the player be able to respec (reset and reassign) passives? Since passives
  are automatic unlocks (not choices), there's nothing to respec. If future passives
  become choice-based (player picks 1 of 2 at each level), then respec would be needed.
  Recommendation: no respec for MVP.
- Should party AI agents account for character passives when scoring skills? Yes — if
  Evelyn has "Dark skills cost 10% less MP," the AI should slightly prefer Dark skills.
  This is a tuning consideration for the Party AI System.
