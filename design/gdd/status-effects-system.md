# Status Effects System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (status effects create switching strategy depth)

## Overview

The Status Effects System manages all persistent, time-bound modifiers applied to characters and enemies during combat and exploration — buffs that enhance stats, debuffs that weaken targets, damage-over-time effects that tick each interval, crowd-control effects that restrict action, and shields that absorb damage. Each status effect is defined as a ScriptableObject (`StatusEffectSO`) specifying its type, magnitude, duration, stacking rules, and visual/audio feedback. The system is called by the Skill Execution System (when skills apply effects), queried by the Health & Damage System (when calculating effective stats), and serialized by the Save / Load System (so active effects persist across saves). Status effects are the primary lever for combat strategy beyond raw stats — knowing when to buff an ally, debuff a boss, or cleanse a party-wide poison is the core skill expression of the party management loop.

## Player Fantasy

Status Effects System serves the fantasy of **tactical depth through temporary advantage**. The player should feel smart for applying the right effect at the right time: a well-timed ATK buff before a big skill hit feels powerful; a debuff that reduces a boss's DEF by 30% right before the Archer's ultimate skill feels clutch; cleansing a party-wide stun before the boss's next attack feels like clutch play. Status effects create moments of strategic brilliance that basic attacks cannot. They also create tension — a 5-second buff window means the player must act quickly, switching to the buffed character and unleashing their best skill before the effect expires. The system rewards planning, timing, and party composition awareness.

**Reference model**: Final Fantasy X's buff/debuff system (clear icons, visible duration, meaningful stat changes), Path of Exile's buff stacking depth (complex interactions but readable at a glance), and Genshin Impact's elemental reaction buffs (temporary but impactful).

## Detailed Design

### Core Rules

1. **StatusEffectSO ScriptableObject**: Every status effect is defined as a `StatusEffectSO` asset with the following fields:

   | Field | Type | Description |
   |-------|------|-------------|
   | `EffectId` | string | Unique identifier (e.g., "buff_atk_up", "debuff_slow", "dot_poison") |
   | `DisplayName` | string | Shown in HUD tooltip (e.g., "ATK Up", "Slowed", "Poisoned") |
   | `Icon` | Sprite | Displayed in the character's status bar in the Combat HUD |
   | `EffectType` | enum | `Buff`, `Debuff`, `DoT`, `CrowdControl`, `Shield` — determines behavior category |
   | `EffectCategory` | enum | `StatModifier`, `DamageOverTime`, `MovementImpair`, `ActionDenial`, `DamageAbsorption` — determines how the effect interacts with other systems |
   | `StatToModify` | enum | `ATK`, `DEF`, `SPD`, `MaxHP`, `MaxMP`, `CRIT` — which stat is affected (None for DoT/CC/Shield) |
   | `ModifyType` | enum | `Percentage` (multiply stat by 1 + EffectValue) or `Flat` (add EffectValue to stat) |
   | `EffectValue` | float | Magnitude of the effect (e.g., 0.25 for +25% ATK, 15.0 for 15 DoT damage per tick) |
   | `Duration` | float (seconds) | How long the effect lasts; 0 = infinite (until manually removed) |
   | `TickInterval` | float (seconds) | For DoT effects only: time between damage ticks; 0 for non-DoT effects |
   | `DamageCategory` | enum | `Physical`, `Magical`, `Holy`, `Dark` — for DoT effects, determines resistance calculation |
   | `CanCrit` | bool | For DoT effects: whether ticks can critically hit (default: false) |
   | `StackingRule` | enum | `NoStack` (refreshes duration), `AdditiveStack` (multiple instances stack magnitudes), `DurationStack` (multiple instances extend duration, max 3 stacks) |
   | `MaxStacks` | int | Maximum number of simultaneous instances (1 for NoStack, 3–5 for stackable effects) |
   | `Dispellable` | bool | Whether the effect can be removed by cleanse skills (default: true for buffs/debuffs, false for some boss-applied CC) |
   | `IsHostile` | bool | True for effects applied by enemies to players; false for player-applied effects |
   | `Description` | string | One-line tooltip text explaining the effect |
   | `VFX` | GameObject | Visual effect prefab instantiated on the target when effect is applied |
   | `AudioCue` | AudioClip | Sound played when effect is applied |
   | `RemoveAudioCue` | AudioClip | Sound played when effect expires or is dispelled |

2. **Effect Types and Behaviors**:

   | Effect Type | Behavior | Examples |
   |-------------|----------|----------|
   | **Buff** | Enhances a target's stat temporarily. Applied to allies. Stacking rules apply. | +25% ATK, +15% DEF, +10% CRIT |
   | **Debuff** | Reduces a target's stat temporarily. Applied to enemies. Stacking rules apply. | -20% DEF, -15% SPD, -10% ATK |
   | **DoT** | Deals damage each tick interval. Damage is calculated through Health & Damage System (respects category resistance). Cannot crit by default. | Poison (Dark, 15 dmg/tick, 5s), Burn (Magical, 20 dmg/tick, 3s) |
   | **CrowdControl** | Restricts or denies target actions. Does not modify stats. | Stun (no actions for 2s), Slow (-30% SPD for 4s), Silence (no skills for 3s), Taunt (forces attack on taunter for 3s) |
   | **Shield** | Absorbs incoming damage up to a value. Tracked separately from HP. Disappears when depleted or expired. | Barrier (absorbs 100 damage, 8s), Magic Shield (absorbs 60 Magical damage, 10s) |

3. **Application Process** (when Skill Execution System applies a status effect):
   1. Validate target is alive and eligible (e.g., cannot buff dead allies)
   2. Check stacking rules — if effect already active on target, apply stacking rule
   3. Create `ActiveEffect` instance with remaining duration = Duration
   4. Apply immediate stat modification if StatModifier type
   5. Instantiate VFX on target, play AudioCue
   6. Register effect in target's `ActiveEffects` list

4. **Duration Tick Process** (each frame, managed by Status Effects System):
   1. For each `ActiveEffect` on each entity:
      - `RemainingDuration -= deltaTime`
      - If `EffectCategory == DamageOverTime` and `TimeSinceLastTick >= TickInterval`:
        - Calculate DoT damage via Health & Damage System
        - Apply damage to target (shield absorbs first if present)
        - `TimeSinceLastTick = 0`
   2. Remove effects where `RemainingDuration <= 0`
   3. On removal: reverse stat modifications, play RemoveAudioCue, destroy VFX

5. **Stacking Rules** (detailed):

   | Stacking Rule | Behavior on Re-application | Example |
   |---------------|--------------------------|---------|
   | `NoStack` | Refresh duration only. Magnitude unchanged. | ATK buff from two different skills both using NoStack — second application resets timer to full duration but doesn't increase the buff. |
   | `AdditiveStack` | New instance adds its EffectValue to existing total. Magnitude = sum of all instances. MaxStacks caps total instances. | Poison applied 3 times with AdditiveStack and MaxStacks=3 — total DoT = 3 × base damage per tick. |
   | `DurationStack` | Each new instance extends duration by `BaseDuration × 0.5` (flat, not diminishing). MaxStacks caps total extensions. Magnitude unchanged. | Burn applied 3 times — duration = base + 0.5×base + 0.5×base = 2.0× base duration. |

6. **Stat Recalculation**: When a buff or debuff is applied or removed, the target's effective stats are recalculated:
   ```
   EffectiveStat = BaseStat × (1 + SumOfPercentageBuffs) + SumOfFlatBuffs
   ```
   Buffs and debuffs of the same type (percentage or flat) are additive. Percentage and flat buffs are applied in sequence: percentage first, then flat.

7. **Dispel/Cleanse Rules**:
   - Skills can dispel effects from allies (remove all debuffs) or enemies (remove all buffs)
   - Only effects with `Dispelffable = true` can be removed
   - Dispelling is instant — no cooldown, no animation beyond the dispel skill's own animation
   - A "Cleanse" skill removes ALL dispellable debuffs from a single ally
   - A "Dispel" skill removes ALL dispellable buffs from a single enemy

8. **Immunity**: Some enemies and characters may be immune to certain effect categories. Immunity is defined in the target's data (enemy data or CharacterDataSO). Immune targets do not receive the effect — the skill applies but the status effect is immediately rejected with a "Immune" indicator.

9. **Priority System**: When multiple effects conflict (e.g., a buff increasing ATK and a debuff reducing ATK on the same target), they are all applied independently. The effective stat is the net result of all active effects. There is no priority — all effects contribute to the final calculation.

10. **Death and Status Effects**: When a character or enemy dies, all active status effects are removed immediately. No effects persist through death or revive. Revived characters start with no active effects.

### States and Transitions

**ActiveEffect Runtime State** (per effect instance on a target):

| Property | Type | Description |
|----------|------|-------------|
| `EffectId` | string | Reference to the StatusEffectSO definition |
| `RemainingDuration` | float (seconds) | Time until effect expires |
| `CurrentStacks` | int | Number of stacked instances (1 for NoStack) |
| `TimeSinceLastTick` | float (seconds) | Time since last DoT tick (0 for non-DoT) |
| `AppliedByCharacterId` | string | ID of the character/enemy that applied this effect (for tracking) |
| `Tier` | int | Tier level of the skill that applied this effect (affects magnitude) |

**Status Effect Instance Lifecycle**:

```
┌──────────────┐
│   INACTIVE   │ ◄── Effect not present on target
└──────┬───────┘
       │ Skill applies effect
       ▼
┌──────────────┐
│   ACTIVE     │ ◄── Duration ticking; DoT dealing damage; stat modified
│  (Ticking)   │
└──────┬───────┘
       │ RemainingDuration <= 0 OR dispelled OR target dies
       ▼
┌──────────────┐
│   REMOVED    │ ◄── Stats recalculated, VFX destroyed, audio played
└──────────────┘
```

**For Stacking Effects** (`AdditiveStack` or `DurationStack`):

| Event | Behavior |
|-------|----------|
| Effect applied, none active | Create new instance, duration = Duration |
| Effect applied, instance active, stacks < MaxStacks | Increment stacks, apply stacking rule |
| Effect applied, instance active, stacks >= MaxStacks | For AdditiveStack: ignore. For DurationStack: ignore. For NoStack: refresh duration only. |
| Effect expires or dispelled | Remove all stacks, recalculate stats |

### Interactions with Other Systems

| System | Direction | Details |
|--------|-----------|---------|
| **Health & Damage System** | Called by / Calls | DoT ticks call `ApplyDamage()` on the Health & Damage System; shields are queried before HP damage is applied |
| **Skill Database** | Reads | SkillStatusSO and SkillSupportSO reference StatusEffectSO entries for effects they apply |
| **Skill Execution System** | Calls this | Creates ActiveEffect instances when skills with status effects are cast |
| **Character Data** | Reads | Reads target immunity flags and base stats for effective stat recalculation |
| **Character State Manager** | Read by | Provides active effect list per character for HUD display and AI decision-making |
| **Combat System** | Read by | Combat System queries active effects to determine encounter conditions (e.g., boss enrages when buffed) |
| **Party AI System** | Reads | AI reads active buffs/debuffs to adjust skill selection (e.g., don't use a debuff skill if target is already debuffed) |
| **Combat HUD** | Reads | Displays effect icons with duration timers on character bars |
| **Save / Load System** | Serialized | ActiveEffects[] per character are saved and loaded (EffectId, RemainingDuration, CurrentStacks) |
| **Enemy AI System** | Calls this | Enemy skills apply status effects to player characters |
| **Audio System** | Reads | Plays AudioCue and RemoveAudioCue from StatusEffectSO |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| **Effective Stat** | `BaseStat × (1 + ΣPercentageBuffs - ΣPercentageDebuffs) + ΣFlatBuffs - ΣFlatDebuffs` | Buffs are positive, debuffs are negative; all summed together; result clamped to ≥ BaseStat × 0.1 |
| **DoT Tick Damage** | `EffectValue × CategoryResistance` | No DEF subtraction, no crit (unless CanCrit = true) |
| **DoT Crit Tick** | `EffectValue × CategoryResistance × CritMult` | Only if CanCrit = true and crit roll succeeds |
| **DurationStack Extension** | `NewDuration = CurrentDuration + (BaseDuration × 0.5)` | Each stack adds a flat half of the base duration (not diminishing); 3 stacks = 2.0× base |
| **AdditiveStack Magnitude** | `TotalEffectValue = BaseEffectValue × CurrentStacks` | Each stack adds its full value |
| **Shield Absorption** | `DamageToHP = max(0, IncomingDamage - ShieldValue)` | Shield absorbs first, HP takes remainder |
| **Minimum Stat Floor** | `EffectiveStat >= BaseStat × 0.1` | Debuffs cannot reduce a stat below 10% of base |
| **Buff/Debuff Priority** | All effects applied simultaneously; no priority ordering | Net result = sum of all contributions |

### Effective Stat Calculation Example

Evelyn has Base ATK = 150. She receives:
- Buff A: +25% ATK (percentage, 8s duration)
- Buff B: +30 ATK (flat, 6s duration)
- Enemy debuff: -15% ATK (percentage, 5s duration)

While all three are active:
```
EffectiveATK = 150 × (1 + 0.25 - 0.15) + 30
EffectiveATK = 150 × 1.10 + 30
EffectiveATK = 165 + 30 = 195
```

When Buff A expires:
```
EffectiveATK = 150 × (1 - 0.15) + 30
EffectiveATK = 150 × 0.85 + 30
EffectiveATK = 127.5 + 30 = 157 (rounded to 157)
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Effect applied to already-dead target | Effect is rejected silently; no VFX, no audio | Dead targets have no active effects; prevents memory leaks |
| Two buffs of same type from same skill on same target | NoStack rule: second application refreshes duration, does not stack | Prevents buff stacking exploits from skill reuse |
| Two buffs of same type from different skills on same target | Both apply independently; additive combination | Different skills should synergize, not conflict |
| Debuff reduces stat below 10% of base | Clamp to 10% of base stat | Prevents stats from becoming meaningless |
| DoT tick while shield is active | Shield absorbs tick damage first; shield value decremented | Consistent with shield rule: absorbs all damage first |
| Effect expires during character switch | Effect continues ticking on the character regardless of who is active | Effects are entity-bound, not input-authority-bound |
| Target becomes immune mid-effect (equipment change, chapter event) | Immunity does not remove existing effects; prevents new applications | Existing effects run their course; immunity is forward-looking |
| Save/load mid-effect | RemainingDuration and CurrentStacks are serialized; effect resumes on load with correct remaining time | No effect time is lost due to saving |
| Effect applied but VFX fails to load (missing prefab) | Log warning; effect still applies mechanically; no VFX or fallback VFX plays | Data errors must not break gameplay |
| MaxStacks reached and new instance applied | Per stacking rule: NoStack = refresh, AdditiveStack = ignore, DurationStack = ignore | Prevents infinite stacking |
| All buffs removed by cleanse, then immediately reapplied by same skill | Reapplication follows normal stacking rules — if NoStack, full duration applied | Cleanse removes; reapplication is a new event |
| Enemy dies with DoT still ticking | DoT stops immediately; no post-death damage | Death removes all effects |
| Shield expires with 0 value remaining | Shield is removed; no negative HP or debt | Shield depletion is clean |
| Percentage buff applied to stat that is 0 | Buff has no effect (0 × multiplier = 0); log warning | Edge case for data authoring errors |
| Effect duration is 0 (infinite effect) | Effect persists until manually removed (by skill, chapter transition, or death) | Used for permanent buffs from story events or equipment |
| Two DoTs from same skill but different casters | Treated as same effect ID — NoStack rule applies (refreshes duration) | Prevents DoT stacking from same skill used by multiple characters |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Health & Damage System** | Mutual | Hard | DoT ticks call ApplyDamage(); Health & Damage queries shield values before HP damage |
| **Skill Database** | Reads | Hard | StatusEffectSO entries referenced by SkillStatusSO and SkillSupportSO |
| **Skill Execution System** | Calls this | Hard | Creates and manages ActiveEffect instances on skill cast |
| **Character Data** | Reads | Hard | Reads base stats and immunity flags for effective stat calculation |
| **Character State Manager** | Read by | Hard | Provides active effect list per character for state tracking |
| **Combat System** | Read by | Soft | Queries active effects for encounter conditions and boss behavior |
| **Party AI System** | Reads | Soft | Reads active effects to optimize skill selection |
| **Combat HUD** | Reads | Soft | Displays effect icons, durations, and stack counts |
| **Save / Load System** | Serialized | Hard | ActiveEffects[] per character serialized with remaining duration and stacks |
| **Enemy AI System** | Calls this | Soft | Enemy skills apply status effects to player characters |
| **Audio System** | Reads | Soft | Plays application and removal audio cues from StatusEffectSO |

**No upstream dependency conflicts.** The Status Effects System reads from Skill Database and Character Data, and is called by Skill Execution. All interactions are unidirectional except Health & Damage (mutual for DoT/shield calculation).

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `BuffDuration` | float (seconds) | `6.0` | 3.0–12.0 | Buffs last entire encounters; no reapplication skill | Buffs expire before player can act on them |
| `DebuffDuration` | float (seconds) | `5.0` | 3.0–10.0 | Debuffs trivialize encounters; enemies permanently weakened | Debuffs expire before second skill use; feel pointless |
| `DoTTickInterval` | float (seconds) | `1.0` | 0.5–2.0 | DoT damage is slow; player doesn't feel the effect | DoT ticks are too fast; feels like direct damage |
| `DoTBaseDamage` | float | `15.0` | 5.0–40.0 | DoT overshadows direct damage; players just apply DoT and wait | DoT is imperceptible; no reason to use DoT skills |
| `MaxBuffStacks` | int | `3` | 1–5 | Buff stacking becomes the dominant strategy | No stacking depth; single-application buffs only |
| `MaxDebuffStacks` | int | `3` | 1–5 | Debuff stacking makes enemies trivial | Debuffs feel one-dimensional |
| `ShieldBaseValue` | int | `80` | 30–200 | Shields absorb all damage; defensive skills dominate | Shields break instantly; feel pointless |
| `StatFloorPercent` | float | `0.1` (10%) | 0.05–0.25 | Debuffs barely matter; stats stay high | Debuffs reduce stats to near-zero; target is helpless |
| `CleanseCooldown` | float (seconds) | `15.0` | 8.0–30.0 | Cleanse is always available; debuffs are irrelevant | Cleanse is too rare; debuffs feel oppressive |
| `ImmunityPrevalence` | float | `0.15` (15% of enemies immune to 1 effect type) | 0.05–0.30 | Too many immunities make status skills unreliable | No immunities make status effects universally applicable; no counterplay |

### Interacting Knobs

- **BuffDuration + DebuffDuration**: These should be tuned together — if buffs last 12s and debuffs last 3s, the player has a massive advantage window. If both are short, combat becomes a buff/debuff reapplication treadmill.
- **DoTBaseDamage + DoTTickInterval**: Total DoT damage over full duration = BaseDamage × (Duration / TickInterval). This product should be comparable to a single direct-damage skill of the same tier.
- **MaxBuffStacks + SkillEffectValue**: If a skill applies 3 stacks of +25% ATK, that's +75% total — ensure this is balanced against direct damage skills at the same tier.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Buff applied to ally** | Green/blue particle effect swirls around target; buff icon appears in status bar with duration timer | Soft "empower" ascending tone | High |
| **Debuff applied to enemy** | Red/purple particle effect on enemy; debuff icon appears near HP bar with duration timer | Harsh "affliction" descending tone | High |
| **DoT applied** | Effect-specific VFX (green bubbles for poison, orange flames for burn); DoT icon with tick indicator | Status-specific application sound | Medium |
| **DoT tick damage** | Small damage number in DoT category color (purple for Dark, blue for Magical, etc.) | Subtle tick sound (per tick, quiet) | Low |
| **Effect expires** | Icon fades out; particle effect dissipates | Soft "expiration" sound (different for buff vs. debuff) | Medium |
| **Effect dispelled** | Icon shatters/bursts away with a flash; all stacks removed simultaneously | Bright "cleanse" chime — satisfying, clear | High |
| **Immunity triggered** | "Immune" text appears; VFX bounces off target with a shield-like visual | Shield "ping" or "bounce" sound | Medium |
| **Stack applied** | Stack counter increments on icon (×2, ×3); icon pulses brighter | Subtle "stack" click sound | Low |
| **Shield applied** | Translucent barrier appears around target; shield value displayed | Barrier "hum" sound that fades | Medium |
| **Shield breaks** | Barrier shatters visually; remaining damage number appears | Glass-breaking sound | High |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Buff/debuff icons | Character status bar (below HP/MP bar in Combat HUD) | On application/removal | Always visible during combat for all party members |
| Effect duration timer | Overlay on effect icon (countdown ring or number) | Every frame while effect is active | Shown for effects with Duration > 0 |
| Stack count badge | Bottom-right corner of effect icon (×N) | On stack application/removal | Only for stackable effects (CurrentStacks > 1) |
| DoT tick damage numbers | World space above target, category color-coded | On each tick | Only for DoT effects |
| Shield value indicator | Separate bar above HP bar (blue/white) | Every frame while shield is active | Disappears when shield depletes or expires |
| Effect tooltip | On hover/selection of effect icon | Static | Shows DisplayName, Description, RemainingDuration, CurrentStacks |
| Immunity indicator | "Immune" text float on failed application | On immunity trigger | Brief (1s display, then fades) |
| Cleanse/Dispel availability | Skill tooltip indicates which effects will be removed | Static | When Cleanse/Dispel skill is selected |

## Acceptance Criteria

- [ ] Buffs correctly modify target's effective stats using the formula: `BaseStat × (1 + ΣPercentageBuffs) + ΣFlatBuffs`
- [ ] Debuffs correctly reduce target's effective stats, clamped to minimum 10% of base stat
- [ ] DoT ticks deal damage each tick interval through the Health & Damage System (respects category resistance, cannot crit by default)
- [ ] Shields absorb incoming damage before HP is reduced; shield value decrements accordingly
- [ ] Stacking rules (NoStack, AdditiveStack, DurationStack) behave correctly per specification
- [ ] Effects expire after their duration; stats are recalculated on expiration
- [ ] Dispel/Cleanse skills remove all dispellable effects from a target
- [ ] Immune targets reject status effects with a clear "Immune" indicator
- [ ] Active effects are correctly serialized and restored on save/load
- [ ] Effect icons with duration timers and stack counts display correctly in the Combat HUD
- [ ] All VFX and audio cues play on effect application, expiration, and dispel
- [ ] Performance: managing 20+ simultaneous effects on 8 targets adds < 0.5ms frame time
- [ ] Effects persist correctly across character switches (entity-bound, not input-bound)
- [ ] Revived characters start with no active effects
- [ ] Dead targets have all effects removed immediately

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| Should boss enemies have "Enrage" effects (self-applied buffs at low HP that increase all stats by 50%)? | Game Designer | Resolve during Enemy AI and boss encounter design |
| Should there be a "Purge" skill that removes ALL effects (including non-dispellable) from a target? | Systems Designer | Resolve during skill roster design for Chapter 3+ |
| Should equipment provide status effect resistance (e.g., "+20% Poison Resistance")? | Economy Designer | Resolve during Equipment Enhancement System design |
| Should the player be able to see enemy buffs/debuffs in the HUD (not just party member effects)? | UX Designer | Resolve during Combat HUD design — enemy effect display may clutter the screen |
