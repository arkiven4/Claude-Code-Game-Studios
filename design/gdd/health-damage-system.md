# Health & Damage System

> **Status**: In Design
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (earned difficulty), The Party Is the Game

## Overview

The Health & Damage System is the combat arithmetic core of My Vampire. It defines how
health pools work, how damage is calculated and applied, how healing functions, and when
characters and enemies die. It consumes the six base stats from Character Data (MaxHP,
ATK, DEF, SPD, CRIT) and the damage/heal formulas from the Skill Database, then adds
the missing pieces: damage type resistances, critical hit calculation, the "damage
number" feedback system, death and revive rules, and the relationship between MaxHP
modifiers (from equipment) and current HP tracking. This system is called by Skill
Execution, Enemy AI, Hit Detection, and Combat — making it the most referenced system in
the game. Every point of damage, every heal, every death flows through this system's
rules.

## Player Fantasy

The Health & Damage System serves the fantasy of **a dangerous but surmountable world**.
The player should feel that Evelyn and her companions are always at risk — every encounter
matters, every hit taken is visible in the HP bar dropping — but also that smart party
composition and skill usage can overcome any threat. The numbers are transparent: the
player can see ATK, DEF, HP, and understand *why* they deal more or less damage. There
are no hidden mechanics that punish the player without feedback. When a critical hit
lands, it *feels* great. When a heal saves a party member from death, it *feels* clutch.
Damage numbers flying off enemies create satisfying combat rhythm. The system is simple
enough that players can plan around it ("I need to switch to my Mage because this enemy
has high Physical resistance") but deep enough to reward optimization ("If I buff their
ATK first, then hit them with a Dark skill, I'll one-shot this boss").

**Reference model**: Final Fantasy X's transparent damage formula (players can see the
math), combined with Genshin Impact's damage number feedback (big numbers feel good),
and Dark Souls' death/restart clarity (you always know why you died).

## Detailed Design

### Core Rules

1. **Current HP Tracking**: Every character and enemy has `CurrentHP` (int, clamped 0 to
   MaxHP) and `CurrentMP` (int, clamped 0 to MaxMP). These are runtime state, not
   ScriptableObject fields. They are initialized to MaxHP/MaxMP on encounter start or
   scene load.

2. **Damage Formula** (from Skill Database, restated with full detail):
   ```
   RawDamage = (CasterATK × 0.5 + SkillBaseDamage) × EffectValue
   AfterDefense = RawDamage - TargetDEF
   AfterCategory = AfterDefense × CategoryResistance
   FinalDamage = max(1, floor(AfterCategory))   // minimum 1 damage always
   ```

3. **Critical Hit Calculation**: When a skill deals damage, the game rolls a random float
   0.0–1.0. If the result is ≤ the attacker's CRIT stat, the hit is critical. Critical
   hits multiply `EffectValue` by 1.5x before the damage formula is evaluated.

4. **Damage Type Categories**: Four damage types exist, each with a resistance value per
   target:
   - **Physical** — standard weapon attacks, melee skills
   - **Magical** — mage skills, elemental attacks
   - **Holy** — healer skills, light-based attacks
   - **Dark** — vampire skills, shadow attacks (Evelyn's specialty)

   Category resistance is a multiplier: `1.0` (neutral), `0.5` (resisted), `1.5` (weak),
   or `2.0` (critical weakness). Enemies have per-type resistance defined in their enemy
   data. Player characters default to `1.0` for all types unless modified by a
   buff/debuff.

5. **Heal Formula** (from Skill Database, restated with full detail):
   ```
   HealAmount = (CasterMaxMP × 0.1 + SkillBaseHeal) × EffectValue + (TargetMaxHP × BonusPercent)
   ActualHeal = min(HealAmount, TargetMaxHP - TargetCurrentHP)  // cannot overheal
   ```

6. **Death Rule**: When `CurrentHP` reaches 0, the target is marked as `Dead`. Dead
   characters cannot act, take skill turns, or receive heals. Dead enemies are removed
   from the encounter and drop loot.

7. **Revive Rule**: Characters can be revived by skills (e.g., a Healer's revive skill)
   or by story events. Revived characters return with `CurrentHP = MaxHP × 0.25` (25% HP).
   Revive is a **single-target** effect with a cooldown (defined per skill). Only one
   revive is permitted per character per encounter (after the second death, they stay
   dead for that encounter).

8. **Party Wipe Rule**: If all 4 party members are dead, the game triggers a "Game Over"
   state. The player is offered:
   - **Retry from last auto-save** (returns to the most recent auto-save point)
   - **Return to main menu** (loses progress since last manual save)

9. **Enemy Death Threshold**: Enemies have a `DeathThreshold` HP value. When `CurrentHP
   ≤ DeathThreshold`, the enemy plays its death animation and is marked for removal. This
   threshold is always 0 for standard enemies but can be higher for multi-phase bosses
   (e.g., a boss with 2 phases has `DeathThreshold = 50% MaxHP` for phase 1 transition
   and `DeathThreshold = 0` for final death).

10. **MaxHP Modifiers**: Equipment and buffs can modify MaxHP. When MaxHP changes:
    - If MaxHP increases: `CurrentHP` increases by the same amount (new HP added)
    - If MaxHP decreases: `CurrentHP` is reduced by the same amount, clamped to new MaxHP
    - Example: Character has 500/500 HP. Equipment adds +50 MaxHP. Now 550/550 HP.
      Equipment is removed. Now 500/500 HP.

11. **Damage Over Time (DoT)**: Skills can apply DoT effects. At the start of each tick
    interval (defined per skill), the target takes `DoTDamage = BaseDoT × EffectValue`
    damage of the skill's damage category. DoT ticks cannot critically hit. Multiple DoTs
    from the same skill don't stack — they refresh duration. DoTs from different skills
    stack additively.

12. **Shield / Barrier**: Skills can apply shields that absorb damage before HP is
    reduced. Shield value is tracked separately from HP. When a shield exists, damage is
    applied to the shield first. Shields do not regenerate — they are consumed and
    disappear when depleted or when the buff expires.

13. **Invincibility Frames**: Brief periods where a character or enemy cannot take damage
    (e.g., during dodge animation, character switching, or resurrection). During
    invincibility, all incoming damage is set to 0.

### States and Transitions

The Health & Damage System tracks the vital state of each entity (character or enemy)
through a simple enum:

```
┌──────────┐     takes damage      ┌──────────┐
│  Healthy │ ──────────────────────▶│ Injured  │
│ (>50% HP)│                        │(1-50% HP)│
└──────────┘                        └────┬─────┘
     │                                   │ takes more damage
     │ heals to >50%                     ▼
     └───────────────────────────── ┌──────────┐
                                    │ Critical  │
                                    │ (<10% HP) │
                                    └─────┬─────┘
                                          │ reaches 0 HP
                                          ▼
                                    ┌──────────┐
                                    │   Dead    │
                                    └──────────┘
```

**State definitions**:
- `Healthy` — `CurrentHP > MaxHP × 0.5`. No visual indicator needed.
- `Injured` — `MaxHP × 0.1 < CurrentHP ≤ MaxHP × 0.5`. Character shows minor damage
  visual (scuffed clothing, slight limp animation).
- `Critical` — `0 < CurrentHP ≤ MaxHP × 0.1`. Character shows urgent damage visual
  (kneeling, heavy breathing), screen vignette pulses red for the active character.
- `Dead` — `CurrentHP == 0`. Character is removed from active combat.

**State transitions are passive** — no player action changes state directly. States are
derived from the ratio `CurrentHP / MaxHP`.

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Character Data** | Read | Reads MaxHP, ATK, DEF, CRIT stats for damage/heal calculations |
| **Skill Database** | Read | Reads SkillBaseDamage, EffectValue, MPCost, Category, TargetType for each skill |
| **Skill Execution** | Called by | Skill Execution calls `ApplyDamage()` and `ApplyHeal()` on targets |
| **Enemy AI** | Called by | Enemy AI calls `ApplyDamage()` when enemy attacks land |
| **Hit Detection** | Calls this | Hit Detection determines *who* was hit; Health & Damage determines *how much* |
| **Status Effects** | Mutual | DoT, shields, and HP-modifying buffs are managed by Status Effects but calculated here |
| **Combat System** | Read by | Combat System reads entity states to determine encounter end conditions |
| **Character State Manager** | Read by | Reads HP/MP/death state to update character availability for switching |
| **Equipment Enhancement** | Read by | Enhanced equipment modifies MaxHP, which triggers HP recalculation here |
| **Loot & Drop** | Triggered by | Enemy death (detected here) triggers loot drop in Loot & Drop System |
| **Save / Load System** | Serialized by | CurrentHP, CurrentMP, shields, DoTs, and death state are saved/loaded |

## Formulas

This system *is* the formula system. All formulas are consolidated here:

| Formula | Expression | Notes |
|---------|-----------|-------|
| **Damage** | `max(1, floor(((ATK × 0.5 + BaseDmg) × EffectVal × CritMult - DEF) × CatResist))` | CritMult = 1.5 on crit, 1.0 otherwise |
| **Heal** | `min((MaxMP × 0.1 + BaseHeal) × EffectVal + TargetMaxHP × Bonus%, TargetMaxHP - CurrentHP)` | Cannot overheal |
| **DoT Tick** | `BaseDoT × EffectValue` | No crit, no DEF subtraction |
| **Crit Roll** | `Random(0.0, 1.0) ≤ CRIT` | CRIT is 0.0–1.0 probability |
| **Injured Threshold** | `CurrentHP ≤ MaxHP × 0.5` | State boundary |
| **Critical Threshold** | `CurrentHP ≤ MaxHP × 0.1` | State boundary |
| **Revive HP** | `MaxHP × 0.25` | Revived characters start at 25% HP |
| **HP on MaxHP Gain** | `CurrentHP += delta` | New HP from equipment/buffs |
| **HP on MaxHP Loss** | `CurrentHP = min(CurrentHP - delta, newMaxHP)` | Clamp prevents exceeding new max |
| **Shield Absorption** | `damageToHP = max(0, incomingDamage - shieldValue)` | Shield absorbs first |
| **Minimum Damage** | `max(1, computedDamage)` | Always at least 1 damage |

## Edge Cases

1. **Zero defense enemy**: If target DEF > RawDamage, AfterDefense goes negative. The
   `max(1, ...)` floor ensures at least 1 damage always lands.

2. **Heal on full HP character**: `ActualHeal = min(calculated, MaxHP - CurrentHP)`. If
   CurrentHP == MaxHP, heal amount is 0. No overflow, no waste warning needed.

3. **Shield + DoT interaction**: DoT ticks apply to shield first. If shield absorbs the
   full DoT tick, no HP is lost. If shield is depleted mid-tick, the remaining damage
   goes to HP.

4. **MaxHP reduction while Injured/Critical**: If a buff expires and reduces MaxHP, the
   character may instantly drop from Healthy to Injured or Injured to Critical. The state
   visual updates immediately.

5. **Simultaneous death**: If a party-wide attack kills multiple characters simultaneously,
   all are marked Dead. The Party Wipe check runs after all deaths are processed.

6. **Heal on dead character**: Heal spells cannot target dead characters (they're excluded
   from `SingleAlly` and `AllAllies` targeting). Only Revive skills can affect dead
   characters.

7. **Damage during invincibility**: If a character is in an invincibility frame window and
   takes damage, the damage is recorded as 0 but the hit still plays (no damage number, a
   "Miss" or "Immune" indicator).

8. **Enemy with 2.0x resistance to all damage types**: This enemy would take
   `floor(RawDamage × 2.0 - DEF)`. If ATK and BaseDamage are low enough, this could result
   in the 1-damage floor. The player must increase ATK (buffs, equipment) or find a way
   to reduce the enemy's resistance (debuff skill).

9. **Negative damage from absurd DEF**: If TargetDEF > RawDamage, the result is clamped to
   1 by the minimum damage rule. DEF can never reduce damage below 1.

10. **Heal from enemy skills**: Some enemies may have healing skills (e.g., a boss that
    heals minions). The heal formula is identical — only the caster and target differ.

## Dependencies

- **Depends on**: Character Data (MaxHP, ATK, DEF, CRIT stats), Skill Database
  (damage/heal formulas, categories)
- **Depended on by**: Status Effects, Skill Execution, Enemy AI, Hit Detection, Combat
  System, Character State Manager, Loot & Drop, Save / Load System

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `CriticalMultiplier` | float | `1.5` | Could be reduced to 1.3x for easier difficulty |
| `ReviveHPPercent` | float | `0.25` | Revived characters return at 25% HP |
| `HealthyThreshold` | float | `0.5` | HP% boundary between Healthy and Injured |
| `CriticalThreshold` | float | `0.1` | HP% boundary between Injured and Critical |
| `MinimumDamage` | int | `1` | Always at least 1 damage lands |
| `DoTCritEligible` | bool | `false` | DoT ticks cannot critically hit |

## Visual/Audio Requirements

- **Damage Numbers**: Floating text above target showing damage amount. Color-coded by
  damage type (Physical=white, Magical=blue, Holy=yellow, Dark=purple). Critical hits
  show 2x font size with a flash effect.
- **Heal Numbers**: Green floating text above healed target, showing heal amount.
- **HP Bar**: Each character and enemy has a visible HP bar. Color shifts green → yellow
  → red as HP drops.
- **Critical State Vignette**: When the active character enters Critical state (<10% HP),
  a red vignette pulses on screen edges.
- **Death Animation**: Each character has a unique death animation. Enemies have a
  dissolve/fall-apart animation.
- **Hit Sound**: Each damage category has a distinct hit sound (physical thud, magical
  crackle, holy chime, dark whoosh).
- **Critical Hit Sound**: Louder, more impactful version of the category hit sound.
- **Heal Sound**: Soft ascending tone, distinct from damage sounds.
- **Death Sound**: Unique per boss, generic thud for standard enemies.

## UI Requirements

- **Combat HUD**: HP bars for all 4 party members (top-left), active character
  highlighted. Enemy HP bars above enemy models.
- **Damage Numbers**: Rendered in world space above targets, converted to screen space.
- **Death Overlay**: Full-screen fade to red when all party members are dead, with "Game
  Over" text and retry/main menu buttons.
- **Revive Indicator**: Shows which characters have been revived this encounter (to track
  the "one revive per encounter" rule).

## Acceptance Criteria

- [ ] Damage formula produces correct results for all combinations of ATK, DEF,
  EffectValue, and CategoryResistance
- [ ] Critical hits deal 1.5x EffectValue and show distinct visual/audio feedback
- [ ] Minimum damage of 1 is enforced regardless of DEF
- [ ] Healing cannot exceed MaxHP (no overheal)
- [ ] DoT ticks apply damage each interval, cannot crit, stack additively from different
  skills
- [ ] Shields absorb damage before HP is reduced
- [ ] Invincibility frames reduce all incoming damage to 0
- [ ] Dead characters cannot act, be healed, or be targeted by non-Revive skills
- [ ] Party wipe triggers Game Over with retry/return-to-menu options
- [ ] MaxHP changes propagate correctly to CurrentHP (increase adds, decrease clamps)
- [ ] HP state transitions (Healthy → Injured → Critical → Dead) trigger correct visual
  indicators
- [ ] HP bars update in real-time with no visible lag between state change and display

## Open Questions

- Should the revive limit be configurable per character (e.g., Evelyn as the vampire
  protagonist can self-revive once per encounter without using the team's revive)?
- Should we add a "downed" state between Critical and Dead where a character has 10
  seconds to be revived before permanent death?
