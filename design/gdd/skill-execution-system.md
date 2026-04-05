# Skill Execution System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (skill usage drives character switching strategy)

## Overview

The Skill Execution System is the runtime engine that takes skill definitions from the Skill Database, validates their usage conditions, resolves targets, applies their effects (damage, healing, buffs, debuffs, crowd control), and manages the resulting runtime state (cooldowns, charges, active effect instances). It is the bridge between static skill data and dynamic combat outcomes. When a player presses a skill button, this system validates MP and cooldown, plays the animation, acquires targets through Hit Detection, calculates outcomes through Health & Damage, applies status effects through the Status Effects System, and updates the skill's cooldown and charge state. Every skill activation in the game — from Evelyn's basic attack to the Witch's ultimate spell — flows through this system. It is called by player input (via the Input System), by the Party AI System (for non-active party members), and by the Enemy AI System (for enemy skills).

## Player Fantasy

Skill Execution System serves the fantasy of **abilities that feel powerful and reliable**. When the player uses a skill, it should work exactly as expected: the animation plays, the target is hit, the damage number flies, the buff appears. No mystery mechanics, no hidden failures. The system is invisible infrastructure — players interact with skills through the Combat HUD, not through this system directly. But the system's quality shows in the responsiveness: skill activation has no perceptible input lag, cooldowns tick accurately, and the player always knows when their next skill will be ready. The system enables the core loop of "use skill, evaluate result, decide next action" that makes combat engaging.

**Reference model**: Final Fantasy VII Remake's skill activation (clear animation → effect → cooldown flow), Tales of Berseria's Arte system (responsive, readable, no ambiguity), and Genshin Impact's skill feedback (instant visual confirmation of skill effect).

## Detailed Design

### Core Rules

1. **SkillRuntimeState** (per skill, per character): Each character has a `SkillRuntimeState` entry for each of their 4 skill slots. This is the mutable runtime data that tracks:

   | Property | Type | Default | Description |
   |----------|------|---------|-------------|
   | `CurrentCooldown` | float (seconds) | `0` | Remaining cooldown time; decremented each frame |
   | `ChargeCount` | int | `MaxCharges` (from skill data) | Available uses before cooldown; for skills with multiple charges |
   | `ActiveInstances[]` | list of `ActiveEffectRef` | empty | References to active buffs/debuffs/DoTs applied by this skill |
   | `TotalUsesThisEncounter` | int | `0` | Tracks how many times this skill has been used (for analytics and achievement tracking) |

2. **Skill Activation Sequence** (executed when a skill is triggered):

   **Phase 1: Validation** (instant, no animation)
   1. Check `CurrentCooldown > 0` → fail with "On Cooldown" tooltip
   2. Check `ChargeCount <= 0` → fail with "No Charges" tooltip
   3. Check `caster.CurrentMP < skill.MPCost` → fail with "Not Enough MP" tooltip
   4. Check `skill.UnlockCondition` is met → fail with "Skill Locked" tooltip
   5. Check caster is not under `ActionDenial` crowd control (Silence, Stun) → fail with "Cannot Act" tooltip
   6. If any validation fails: abort sequence, no MP consumed, no cooldown triggered

   **Phase 2: Pre-Execution** (instant)
   7. Deduct MP: `caster.CurrentMP -= skill.MPCost`
   8. If `ChargeCount > 0` and skill has charges: `ChargeCount -= 1`
   9. If `ChargeCount == 0` after decrement: set `CurrentCooldown = EffectiveCooldown`
   10. Play skill animation (`skill.Animation`) on caster
   11. Play audio cue (`skill.AudioCue`)

   **Phase 3: Target Acquisition** (instant)
   12. Resolve targets based on `skill.TargetType`:
       - `SingleEnemy`: nearest valid enemy to caster
       - `MultiEnemyLine`: N enemies in a frontal line (N = TargetCount)
       - `MultiEnemyCone`: N enemies in a frontal cone of `AreaRadius`
       - `AllEnemies`: all valid enemies
       - `SingleAlly`: nearest valid ally (or self if no target selected)
       - `AllAllies`: all valid allies
       - `Self`: the caster only
   13. If no valid targets found: abort, refund MP, refund charge, cancel animation (this is an auto-abort, not a player cancel — MP and charge are always refunded regardless of knob settings)

   **Phase 4: Effect Application** (instant)
   14. For each target, apply the skill's effect:
       - **Damage skills** (SkillDamageSO): Calculate damage via Health & Damage System, apply to target
       - **Heal skills** (SkillSupportSO): Calculate heal via Health & Damage System, apply to target
       - **Status skills** (SkillStatusSO): Apply status effect(s) via Status Effects System
       - **Utility skills** (SkillUtilitySO): Execute utility effect (shield, MP restore, movement, etc.)
   15. If the skill applies multiple effects (e.g., damage + DoT), apply them in order: damage first, then status effects

   **Phase 5: Post-Execution** (instant)
   16. Register each applied status effect in `ActiveInstances[]` for tracking
   17. Increment `TotalUsesThisEncounter`
   18. Notify Combat HUD to update skill bar (cooldown display, charge count)

3. **Cooldown Management**:
   - Cooldown ticks down in real-time every frame: `CurrentCooldown -= deltaTime`
   - When `CurrentCooldown <= 0`: set `CurrentCooldown = 0`, restore `ChargeCount = MaxCharges` (if skill has charges)
   - Cooldown continues ticking during character switches — switching does not pause cooldowns
   - Cooldown reduction from equipment modifies `EffectiveCooldown` at activation time, not during ticking
   - Cooldown cannot be reduced below 0.5 seconds (minimum cooldown floor)

4. **Charge Management**:
   - Skills with `MaxCharges > 1` can be used multiple times before entering cooldown
   - Each use consumes one charge
   - When all charges are consumed, cooldown begins
   - When cooldown reaches 0, all charges are restored simultaneously
   - Partial charge regeneration is not supported — charges restore all at once when cooldown ends

5. **Target Validation**: A target is valid if:
   - For enemy-targeted skills: target is alive, not invincible, and within range
   - For ally-targeted skills: target is alive (dead allies are only valid for Revive-type skills)
   - For self-targeted skills: caster is alive and not under ActionDenial
   - Range is defined by `AreaRadius` on the skill's tier config (0 = unlimited range for single-target)

6. **Animation Cancellation**: A skill's animation can be cancelled by:
   - Character death: animation cancelled, effects already applied are NOT reverted, unapplied effects are skipped
   - Character switch: animation is NOT cancelled — it plays to completion on the previous character (the character continues the animation while not player-controlled)
   - Stun/Silence applied mid-animation: animation continues but additional effects from the skill still apply (the skill was already committed)
   - Player input cancellation (for cancelable skills only): animation stops, effects already applied are NOT reverted, remaining effects are skipped

7. **Skill Interruption Cost**: If a skill is interrupted (death, cancel), the MP cost is NOT refunded and the cooldown is NOT reset. The player loses the resource investment. This makes interruption meaningful and prevents animation-cancel exploits.

8. **Multi-Effect Skills**: Some skills apply multiple effects (e.g., damage + stun, heal + buff). Each effect is processed independently. If one effect fails (e.g., target is immune to stun), the other effects still apply (damage still lands).

9. **Chain Effects**: Some skills have secondary effects triggered by conditions (e.g., "if target is below 30% HP, deal +50% damage"). These are defined as `ConditionalEffect` entries in the skill data:

   | Field | Type | Description |
   |-------|------|-------------|
   | `Condition` | enum | `TargetBelowHP%`, `CasterBelowHP%`, `TargetHasDebuff`, `TargetHasBuff`, `IsCriticalHit` |
   | `Threshold` | float | HP% threshold for below-HP conditions (0.0–1.0) |
   | `BonusEffectValue` | float | Additional effect magnitude when condition is met |
   | `BonusType` | enum | `ExtraDamage`, `ExtraDuration`, `ExtraStack`, `ApplyAdditionalEffect` |

10. **Encounter Reset**: When an encounter ends (all enemies defeated or encounter scripted to end), all skill cooldowns and charges for all party members are reset to their default state (cooldown = 0, charges = MaxCharges). This ensures the next encounter starts with all skills available.

### States and Transitions

**SkillRuntimeState Lifecycle**:

```
┌───────────────────┐
│    READY          │ ◄── Cooldown = 0, Charges > 0, MP sufficient
│  (Available)      │     Skill can be activated
└────────┬──────────┘
         │ Player/AI triggers activation
         ▼
┌───────────────────┐
│  ACTIVATING       │ ◄── Animation playing, MP consumed, targets acquired,
│  (Animation)      │     effects being applied
└────────┬──────────┘
         │ Effects applied, animation completes or is cancelled
         ▼
┌───────────────────┐
│   COOLDOWN        │ ◄── CurrentCooldown > 0, skill unavailable
│  (Unavailable)    │     Ticks down each frame
└────────┬──────────┘
         │ CurrentCooldown <= 0
         ▼
┌───────────────────┐
│    READY          │ ◄── Charges restored, skill available again
│  (Available)      │
└───────────────────┘
```

**For Charge-Based Skills**:

```
┌───────────────────┐
│  READY (N charges)│ ◄── ChargeCount = MaxCharges
└────────┬──────────┘
         │ Use skill (charge consumed)
         ▼
┌───────────────────┐
│  READY (N-1)      │ ◄── Can still use if ChargeCount > 0
└────────┬──────────┘
         │ Use skill (last charge consumed)
         ▼
┌───────────────────┐
│   COOLDOWN        │ ◄── No charges left, cooldown begins
└────────┬──────────┘
         │ Cooldown reaches 0
         ▼
┌───────────────────┐
│  READY (N charges)│ ◄── All charges restored
└───────────────────┘
```

**Per-Encounter Skill Usage Tracking**:

| State | Value | Reset Trigger |
|-------|-------|---------------|
| `TotalUsesThisEncounter` | int, starts at 0 | Encounter end (all enemies defeated) |

### Interactions with Other Systems

| System | Direction | Details |
|--------|-----------|---------|
| **Skill Database** | Reads | Reads SkillDamageSO, SkillSupportSO, SkillStatusSO, SkillUtilitySO for all skill definitions |
| **Character Data** | Reads | Reads character's 4 skill slot references, current level (for tier resolution), base stats |
| **Input System** | Called by | Player input triggers skill activation for active character |
| **Health & Damage System** | Calls | Delegates damage and heal calculations; receives final damage/heal amounts |
| **Status Effects System** | Calls | Applies buffs, debuffs, DoT, crowd control, and shield effects from skills |
| **Hit Detection System** | Calls | Resolves target acquisition for line, cone, and AoE target types |
| **Combat System** | Read by | Combat System queries skill state for encounter logic and encounter-end reset |
| **Character State Manager** | Read by | Provides skill state for character availability checks during switching |
| **Combat HUD** | Read by | Reads cooldown state, charge count, and active instances for skill bar display |
| **Party AI System** | Calls / Reads | AI triggers skill activation for non-active party members; reads skill state for decision-making |
| **Enemy AI System** | Calls | Enemy AI triggers enemy skill activation (uses same execution pipeline) |
| **Audio System** | Calls | Plays skill audio cues (activation, cooldown ready) |
| **Animation System** | Calls | Plays skill animation clips on character models |
| **Save / Load System** | Serialized | Serializes SkillRuntimeState (cooldown, charges, active instances) per skill per character |
| **Camera System** | Calls | Camera tracks skill impact point for AoE skills; cinematic mode for ultimate skills |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| **Effective Cooldown** | `BaseCooldown × (1 - CooldownReductionBonus)` | Capped at 40% reduction; minimum 0.5s |
| **Cooldown Tick** | `CurrentCooldown = max(0, CurrentCooldown - deltaTime)` | Each frame |
| **MP Validation** | `caster.CurrentMP >= skill.MPCost` | Must pass before activation |
| **Charge Validation** | `ChargeCount > 0` | Must pass before activation (for charge skills) |
| **Damage Application** | Delegated to Health & Damage System | See Health & Damage GDD for formula |
| **Heal Application** | Delegated to Health & Damage System | See Health & Damage GDD for formula |
| **DoT Application** | Delegated to Status Effects System | See Status Effects GDD for formula |
| **Conditional Bonus** | `if (ConditionMet) EffectValue += BonusEffectValue` | Evaluated during Phase 4 |
| **Target Count Resolution** | `min(TargetCount, AvailableTargets)` | Cannot target more than available |
| **Encounter Reset** | `CurrentCooldown = 0; ChargeCount = MaxCharges` | All party members, all skills |

### Skill Activation Timing Example

Evelyn uses Tier 2 Fire skill (BaseCooldown 8s, MPCost 28, MaxCharges 1):

| Time (s) | Event | Cooldown | Charges | MP |
|----------|-------|----------|---------|-----|
| 0.0 | Skill activated | 8.0 → 8.0 | 1 → 0 | 200 → 172 |
| 0.5 | Animation plays, damage applied | 7.5 | 0 | 172 |
| 1.0 | Animation completes | 7.0 | 0 | 172 |
| ... | Cooldown ticks each frame | ... | 0 | 172 |
| 8.0 | Cooldown reaches 0 | 0 → 0 | 0 → 1 | 172 |
| 8.0+ | Skill ready again | 0 | 1 | 172 |

### Charge Skill Example

Evan uses a charge skill (BaseCooldown 6s, MPCost 15, MaxCharges 3):

| Time (s) | Event | Cooldown | Charges | MP |
|----------|-------|----------|---------|-----|
| 0.0 | Use 1st charge | 0 | 3 → 2 | 100 → 85 |
| 1.5 | Use 2nd charge | 0 | 2 → 1 | 85 → 70 |
| 3.0 | Use 3rd charge (last) | 0 → 6.0 | 1 → 0 | 70 → 55 |
| 3.0–9.0 | Cooldown ticks | 6.0 → 0 | 0 | 55 |
| 9.0 | Cooldown ends, charges restore | 0 → 0 | 0 → 3 | 55 |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player activates skill but animation is interrupted by enemy stun | Animation continues (committed), effects apply normally | Skill was already activated; stun affects next action, not current |
| Player switches character mid-skill-animation | Animation plays to completion on previous character; new character has input authority | Prevents animation-cancel exploits; character continues their action |
| Skill targets a position where no enemies are in range | Skill fizzles; MP refunded; charge refunded; animation cancelled | No valid targets = activation error, not a skill failure |
| Two skills with DoT applied to same enemy simultaneously | Both DoTs tick independently; damage numbers appear separately | Multiple DoTs from different skills stack (per Status Effects GDD) |
| Skill with ConditionalEffect triggers on the frame target dies | Condition not met (dead targets have 0% HP but are not valid); bonus not applied | Dead targets are excluded from effect resolution |
| Character dies while skill is on cooldown | Cooldown continues ticking; on revive, cooldown state is whatever remains | Death does not reset cooldowns |
| MP is exactly equal to skill cost | Skill activates; MP goes to 0 | Exact cost is valid |
| Cooldown reduction would reduce cooldown below 0.5s | Clamp to 0.5s minimum | Prevents near-instant skill spam |
| Skill animation references a null AnimationClip | Log error; skip animation; effects still apply | Data error must not break functionality |
| Enemy AI triggers a player skill that doesn't exist on that character | Log error; activation fails | Enemy AI must reference valid skill data |
| Player has a locked skill (UnlockCondition not met) | Skill slot greyed out; activation blocked with "Locked" tooltip | Clear feedback for unavailable skills |
| Charge-based skill used, then character switches out before cooldown ends | Cooldown continues on the original character; switched-in character has their own skills | Cooldown is entity-bound, not party-slot-bound |
| All enemies die mid-AoE skill cast | Effects apply to already-acquired targets before death; remaining targets (none) are skipped | Partial application is valid |
| Skill applies buff to dead ally (via AllAllies targeting with one dead) | Dead ally is skipped; living allies receive buff | Dead targets excluded from ally targeting |
| Revive skill used on a character who has already been revived this encounter | Revive fails; "Already Revived" tooltip; MP not consumed | One revive per character per encounter rule (Health & Damage GDD) |
| Skill with 0 duration (instant effect) applied | Effect applies immediately; no ActiveInstance created | Instant effects have no ongoing state |
| Cooldown is active, then encounter ends | Cooldown resets to 0; charges restored | Encounter reset rule |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Skill Database** | Reads | Hard | All skill definitions (damage, support, status, utility) |
| **Character Data** | Reads | Hard | Skill slot references, character level (tier resolution), base stats |
| **Input System** | Called by | Hard | Player input triggers skill activation for active character |
| **Health & Damage System** | Calls | Hard | Damage and heal calculations delegated to this system |
| **Status Effects System** | Calls | Hard | Buff, debuff, DoT, CC, and shield effects applied through this system |
| **Hit Detection System** | Calls | Hard | Target acquisition for line, cone, AoE, and multi-target skills |
| **Combat System** | Read by | Soft | Combat System reads skill state for encounter logic and reset |
| **Character State Manager** | Read by | Soft | Skill state contributes to character availability for switching |
| **Combat HUD** | Read by | Soft | Cooldown display, charge count, active instances shown to player |
| **Party AI System** | Calls / Reads | Soft | AI triggers skills for non-active party members; reads skill state |
| **Enemy AI System** | Calls | Soft | Enemy AI triggers enemy skill activation through same pipeline |
| **Audio System** | Calls | Soft | Plays skill activation and cooldown-ready audio cues |
| **Animation System** | Calls | Soft | Plays skill animation clips |
| **Save / Load System** | Serialized | Hard | SkillRuntimeState serialized per skill per character |
| **Camera System** | Calls | Soft | Camera tracks skill impact for AoE and cinematic skills |

**No dependency conflicts.** All interactions are unidirectional except Combat System (read by) and Party AI (calls/reads).

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `GlobalCooldownScale` | float | `1.0` | 0.5–2.0 | All skills on cooldown; combat feels slow | Skills always available; no timing decisions |
| `MinCooldown` | float (seconds) | `0.5` | 0.25–1.0 | Skills can be spammed rapidly; no rotation skill | Minimum cooldown too punishing; skills feel unresponsive |
| `CooldownReductionCap` | float | `0.40` (40%) | 0.25–0.60 | Cooldown reduction is irrelevant; equipment stat wasted | Cooldowns approach zero; skill spam dominates |
| `AnimationCancelWindow` | float (seconds) | `0.0` (not cancelable) | 0.0–0.3 | Cancelable animations enable animation-cancel exploits | No cancel window; skills feel commitment-heavy |
| `InputBufferWindow` | float (seconds) | `0.15` | 0.05–0.3 | Inputs queued too far ahead; player loses control | Inputs missed frequently; combat feels unresponsive |
| `MaxActiveSkillsInQueue` | int | `1` | 1–3 | Multiple skills queue up; player loses immediate control | No queueing; input timing must be perfect |
| `EncounterResetCooldowns` | bool | `true` | true/false | Cooldowns persist between encounters; player starts next fight disadvantaged | Cooldowns always reset; no persistent resource management across encounters |
| `ChargeRefundOnPlayerCancel` | bool | `false` | true/false | Player-cancelled skills cost no charge — forgiving | Cancelled skills consume a charge; commitment matters |
| `MPRefundOnPlayerCancel` | bool | `false` | true/false | Player-cancelled skills cost no MP — forgiving | Cancelled skills cost MP; commitment matters |

### Interacting Knobs

- **GlobalCooldownScale + CooldownReductionCap**: These interact multiplicatively. A high cooldown scale with a high reduction cap means the player can still reach low cooldowns through equipment. Tune both together.
- **AnimationCancelWindow + InputBufferWindow**: These define the skill responsiveness envelope. A cancel window of 0.2s with a buffer window of 0.15s means the player can cancel and queue the next skill within 0.35s total.
- **ChargeRefundOnMiss + MPRefundOnCancel**: These define the punishment for skill misuse. Both false = punishing (commitment matters). Both true = forgiving (misuse is free). Asymmetric designs (one true, one false) create nuanced punishment.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Skill activated** | Skill icon flashes; target indicator appears; animation plays | Skill's AudioCue plays immediately | Critical |
| **Skill on cooldown** | Dark overlay on icon; countdown timer | No sound | High |
| **Cooldown ends** | Icon brightens; subtle pulse animation | Soft "ready" chime (active character only) | Medium |
| **Charge consumed** | Charge counter decrements on icon | "Charge consumed" click | Low |
| **Skill misses (no targets)** | Animation plays but no impact; "No valid targets" text | Error "buzz" | Medium |
| **Skill interrupted by death** | Animation stops abruptly; character falls | Death sound overrides skill audio | High |
| **Conditional bonus triggered** | Bonus effect has enhanced VFX (larger explosion, brighter buff) | Louder/layered version of the base effect sound | Medium |
| **Skill locked (UnlockCondition not met)** | Greyed-out icon with lock overlay | No sound on attempted activation | Low |
| **Not enough MP** | Icon shakes; red "Not enough MP" tooltip | Low "denied" buzz | High |
| **Skill tier upgrade active** | Icon border reflects current tier (white/gold/glowing) | No additional sound (tier unlock sound played at level-up) | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Skill icon | Combat HUD skill bar (active character only) | Static | Always visible during combat |
| Cooldown overlay | On top of skill icon | Every frame while on cooldown | Dark overlay with countdown timer |
| Charge count | Bottom-right corner of skill icon | On charge use/regen | "×N" badge; hidden when charges = MaxCharges |
| Tier indicator | Border color of skill icon | Static (changes only on level-up) | Tier 1: white, Tier 2: gold, Tier 3: glowing gold |
| MP cost | Tooltip on hover/focus | Static | Shows in skill detail tooltip |
| Active instances | Buff/debuff icons below character HP bar | On application/removal | Each ActiveInstance gets an icon with duration |
| Conditional bonus indicator | Small icon on skill when condition is met | Dynamic | e.g., skull icon when target is below 30% HP |
| Skill lock status | Lock icon overlay | Static | Shown when UnlockCondition is not met |
| Encounter use count | Debug overlay (debug builds only) | Per use | "Uses: N" for analytics |

## Acceptance Criteria

- [ ] Skill activation validates cooldown, charges, MP, unlock condition, and action denial in correct order
- [ ] Failed validation aborts the sequence with no MP cost, no cooldown, no charge consumed
- [ ] MP is deducted before animation plays; charge is consumed before cooldown begins
- [ ] Target acquisition correctly resolves SingleEnemy, MultiEnemyLine, MultiEnemyCone, AllEnemies, SingleAlly, AllAllies, and Self targeting
- [ ] Damage skills correctly delegate to Health & Damage System and display damage numbers
- [ ] Heal skills correctly delegate to Health & Damage System and display heal numbers
- [ ] Status skills correctly apply effects through Status Effects System
- [ ] Cooldown ticks down accurately in real-time, unaffected by character switches
- [ ] Charge-based skills consume charges correctly and restore all charges when cooldown ends
- [ ] Conditional effects trigger correctly when their conditions are met
- [ ] Animation cancellation by death stops the animation but does not revert already-applied effects
- [ ] Encounter end resets all skill cooldowns and charges for all party members
- [ ] Skill state (cooldown, charges, active instances) is correctly serialized and restored on save/load
- [ ] Combat HUD displays cooldown overlay, charge count, and tier indicator accurately
- [ ] Input buffer of 0.15s allows queuing the next skill during an active animation
- [ ] Minimum cooldown of 0.5s is enforced regardless of cooldown reduction
- [ ] Performance: processing 10 simultaneous skill activations in a single frame adds < 1.0ms frame time

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| Should ultimate skills (high-impact, long-cooldown skills) have a dedicated UI element separate from the standard 4 skill slots? | UX Designer | Resolve during Combat HUD design |
| Should the player be able to see the cooldown state of non-active party members' skills? | UX Designer | Resolve during Combat HUD design — showing all 4 characters' skill states may clutter the HUD |
| Should skills have a "smart targeting" mode (auto-select best target) vs. manual targeting (player aims)? | Game Designer | Resolve during Input System design — console controller support may require smart targeting |
| Should there be a "skill combo" system where using Skill A then Skill B within a window triggers a bonus effect? | Systems Designer | Resolve during Combat System design — adds depth but increases complexity |
