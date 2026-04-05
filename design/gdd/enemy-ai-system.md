# Enemy AI System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (earned difficulty), The Party Is the Game (enemy pressure drives switching strategy)

## Overview

The Enemy AI System controls all non-player combatant behavior — from basic grunts that attack the nearest target to multi-phase bosses with scripted abilities, enrage timers, and adaptive targeting. Each enemy is defined by an `EnemyDataSO` ScriptableObject specifying its stats, abilities, behavior profile, and phase transitions. At runtime, a behavior tree selects actions each frame based on the combat state, cooldown availability, and target positions. The system calls Skill Execution to use enemy skills, Hit Detection to acquire targets, and Health & Damage to resolve outcomes. Enemy AI is designed to feel threatening but readable — telegraphs give the player time to react, and enemy behavior follows consistent patterns that reward observation and adaptation.

## Player Fantasy

Enemy AI System serves the fantasy of **smart opponents that you can outplay**. Enemies should not feel random or unfair — they follow patterns the player can learn, telegraph their big attacks, and create windows of opportunity. A basic enemy telegraphs its charge, giving the player time to switch to the Tanker and absorb it. A boss enters an enrage phase at 50% HP, changing its behavior and signaling to the player "this is the climax." The player should feel clever for predicting an enemy's next move and switching to the right character to counter it. Enemies that feel smart make the player feel smart for defeating them.

**Reference model**: Dark Souls' telegraphed boss attacks (clear wind-ups, punishable recoveries), Final Fantasy VII Remake's pressured/staggered system (enemies have exploitable weaknesses), and Hollow Knight's boss pattern memorization (repetition breeds mastery).

## Detailed Design

### Core Rules

1. **EnemyDataSO ScriptableObject**: Every enemy type has one `EnemyDataSO` asset:

   | Field | Type | Description |
   |-------|------|-------------|
   | `EnemyId` | string | Unique identifier (e.g., "church_guard", "witch_minion", "boss_inquisitor") |
   | `DisplayName` | string | Shown in Combat HUD and bestiary |
   | `EnemyClass` | enum | `Grunt`, `Elite`, `MiniBoss`, `Boss` — determines behavior complexity |
   | `BaseMaxHP` | int | HP at encounter start (scales with chapter) |
   | `BaseATK` | int | Attack power |
   | `BaseDEF` | int | Damage reduction |
   | `BaseSPD` | float | Movement and attack animation speed multiplier |
   | `CategoryResistances` | dict | Per-category resistance: `Physical`, `Magical`, `Holy`, `Dark` (default 1.0) |
   | `StatusImmunities` | list | Status effects this enemy is immune to (e.g., `Stun`, `Poison`) |
   | `BehaviorProfile` | EnemyBehaviorProfile | Defines decision-making priorities and skill selection logic |
   | `SkillList` | list of EnemySkillEntry | Skills this enemy can use, with cooldowns and usage conditions |
   | `Phases` | list of EnemyPhase | Multi-phase boss configurations (empty for non-boss enemies) |
   | `DeathThreshold` | float | HP% at which enemy dies (0.0 for standard, >0.0 for multi-phase bosses) |
   | `LootTable` | LootTableRef | What items this enemy drops on death |
   | `ModelPrefab` | GameObject | 3D model used to render this enemy |
   | `PortraitSprite` | Sprite | Used in combat target selection HUD |

2. **EnemyBehaviorProfile**: Defines how an enemy makes decisions:

   | Profile | Behavior | Used By |
   |---------|----------|---------|
   | `Aggressive` | Prioritizes damage-dealing skills; targets lowest-HP party member; low defensive behavior | Grunts, berserker elites |
   | `Tactical` | Balances offense and defense; targets character with lowest DEF; uses status effects strategically | Elites, mini-bosses |
   | `Defensive` | Prioritizes shields and self-buffs; attacks only when buffs are active; targets highest-threat party member | Guardian elites, support bosses |
   | `Boss` | Multi-phase scripted behavior; telegraphs big attacks; adapts to player strategy; enrage at low HP | All bosses |

3. **EnemySkillEntry**: Each skill an enemy can use:

   | Field | Type | Description |
   |-------|------|-------------|
   | `SkillRef` | SkillDataSO reference | The skill definition (reuses player skill types) |
   | `Cooldown` | float (seconds) | Time between uses |
   | `Weight` | float | Priority weight in skill selection (higher = more likely) |
   | `MinRange` | float | Minimum distance to target for this skill to be usable |
   | `MaxRange` | float | Maximum distance to target for this skill to be usable |
   | `Condition` | enum | `Always`, `TargetBelowHP50`, `TargetBelowHP25`, `EnemyBelowHP50`, `EnemyBelowHP25`, `TargetHasBuff`, `TargetIsStunned`, `Phase2Only`, `EnragePhase` |

4. **Decision Cycle** (each enemy, every 0.5 seconds):
   1. Evaluate current state: HP%, active buffs/debuffs, target positions, phase
   2. Filter available skills: check range and condition only — cooldown is handled as a scoring penalty (on-cooldown skills score low but are not excluded, allowing the AI to prefer nearly-ready skills)
   3. Score each available skill using behavior profile weights
   4. Select highest-scoring skill
   5. Acquire target using Hit Detection system
   6. Execute skill via Skill Execution System
   7. Update movement: move toward target position (or retreat if defensive)

5. **Telegraph System**: Before executing any skill with `TelegraphDuration > 0`, the enemy plays a telegraph animation/signal:
   - **Visual**: Red AoE indicator appears on the ground (for targeted attacks), enemy glows (for self-buffs), wind-up animation plays
   - **Audio**: Warning sound plays at telegraph start
   - **Duration**: Telegraph plays for `TelegraphDuration` seconds before the skill actually fires
   - The telegraph gives the player time to dodge, switch characters, or raise shields
   - Telegraphs are mandatory for all Elite+ enemy skills and all Boss skills

6. **Phases** (for bosses and some mini-bosses):
   - Each phase has its own `BehaviorProfile`, `SkillList`, and visual state
   - Phase transition triggers when boss HP crosses the phase threshold
   - On transition: boss becomes invincible for 2s, plays transition animation, new phase skills become available, old phase skills are disabled
   - Phase transitions always telegraph — the boss pulls back, changes form, or summons adds

7. **Enrage Mechanic**: Bosses enter enrage when their HP drops below a defined threshold (typically 25%):
   - All skill cooldowns are halved
   - Attack animations are 20% faster (SPD × 1.2)
   - New enrage-only skills become available
   - Visual change: boss glows red, music intensifies
   - Enrage is a signal to the player: "finish this now"

8. **Target Selection Priority** (per behavior profile):

   | Profile | Primary Target | Secondary Target | Tertiary |
   |---------|---------------|-----------------|----------|
   | `Aggressive` | Lowest current HP | Closest character | Highest DPS (by recent damage dealt) |
   | `Tactical` | Lowest DEF | Character with active buffs | Lowest current HP |
   | `Defensive` | Highest threat (most damage dealt) | Healer (if alive) | Lowest current HP |
   | `Boss` | Phase-dependent (defined per phase) | Adaptive (switches if primary is unavailable) | Random |

9. **Movement AI**: Enemies move during combat:
   - **Melee enemies**: Move toward their target until within melee range (2 units), then attack
   - **Ranged enemies**: Maintain optimal range (8–12 units); retreat if target gets too close
   - **Boss enemies**: Follow scripted movement patterns per phase (position A → position B → position C)
   - Movement does not block skill usage — enemies can move and cast simultaneously
   - Enemies do not collide with each other — they use simple separation steering to avoid stacking

10. **Add Summoning**: Some bosses can summon additional enemies (adds) during combat:
    - Summoned enemies have their own `EnemyDataSO` entries
    - Adds are limited per encounter (max 4 active adds at once)
    - Adds use `Aggressive` behavior profile by default
    - When the boss dies, all remaining adds die instantly

11. **Encounter Design**: Encounters are authored, not procedurally generated. The encounter designer places enemies in specific positions, assigns each enemy a specific level, and defines the encounter trigger conditions. The Enemy AI System controls what enemies do during the encounter, not which enemies appear.

### States and Transitions

**Enemy Runtime State**:

| Property | Type | Description |
|----------|------|-------------|
| `CurrentHP` | int | Current health (from Health & Damage System) |
| `CurrentPhase` | int | Active phase index (0 = first phase) |
| `SkillCooldowns[]` | dict | Per-skill remaining cooldown |
| `CurrentAction` | enum | `Idle`, `Moving`, `Telegraphing`, `Attacking`, `Stunned`, `Dead` |
| `TargetCharacter` | GameObject reference | Currently selected target |
| `TelegraphTimer` | float | Remaining telegraph duration |
| `DecisionTimer` | float | Time until next decision cycle |
| `IsEnraged` | bool | Whether the enemy is in enrage state |

**Enemy State Machine**:

```
┌─────────┐   decision: move    ┌─────────┐
│  Idle   │ ──────────────────▶ │ Moving  │
└────┬────┘                      └────┬────┘
     │ decision: attack               │ reached position
     ▼                                ▼
┌──────────────┐   telegraph     ┌────────────┐
│ Telegraphing │ ──────────────▶ │ Attacking  │
│  (warning)   │   timer ends    │  (skill)   │
└──────────────┘                 └──────┬─────┘
                                        │ skill complete
                                        ▼
                                       Idle

Stun applied (from any state) → Stunned → (stun expires) → Idle
HP reaches 0 (from any state) → Dead
Phase threshold crossed → Invincible (2s) → New phase → Idle
```

### Interactions with Other Systems

| System | Direction | Details |
|--------|-----------|---------|
| **Health & Damage System** | Calls / Called by | Calls ApplyDamage on successful hits; receives damage events to trigger enrage/phase transitions |
| **Hit Detection System** | Calls | Acquires targets for enemy attacks using physics queries |
| **Skill Execution System** | Calls | Triggers enemy skill activation through the same pipeline as player skills |
| **Combat System** | Called by | Combat System signals encounter start/end; Enemy AI resets state on encounter end |
| **Status Effects System** | Calls | Applies status effects to player characters (debuffs, DoT, CC) |
| **Camera System** | Read by | Camera tracks boss telegraphs and adjusts distance for multi-enemy encounters |
| **Audio System** | Calls | Plays enemy attack sounds, telegraph warnings, enrage music |
| **Loot & Drop System** | Triggered by | Enemy death triggers loot drop |
| **Animation System** | Calls | Plays enemy attack, telegraph, death, and phase transition animations |
| **Party AI System** | Read by | Party AI reads enemy behavior patterns to optimize counter-strategy |
| **Scene Management** | Read by | Scene Manager positions enemies at encounter start locations |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| **Skill Score** | `Weight × RangeMultiplier × ConditionBonus × CooldownPenalty` | Highest score selected each decision cycle |
| **RangeMultiplier** | `1.0` if target in range, `0.0` otherwise | Binary range check |
| **ConditionBonus** | `2.0` if skill's Condition is met (e.g., target below 50% HP), `1.0` otherwise | Encourages opportunistic skill usage |
| **CooldownPenalty** | `1.0 - (CurrentCooldown / MaxCooldown)` | Skills closer to being ready score higher |
| **Enrage Cooldown** | `BaseCooldown × 0.5` | All enemy skill cooldowns halved during enrage |
| **Enrage SPD** | `BaseSPD × 1.2` | 20% faster attack animations during enrage |
| **Decision Interval** | `0.5s` (Grunt), `0.3s` (Elite), `0.2s` (Boss) | More complex enemies decide more frequently |
| **Telegraph Duration** | `0.8s` (standard), `1.5s` (boss big attack) | Player reaction window |
| **Phase Transition Invincibility** | `2.0s` | Boss is immune during phase change |
| **Add Separation** | `Steer away if distance < 1.5 units` | Prevents enemy stacking |

### Skill Selection Example

Boss Inquisitor at 60% HP, player Tanker at 40% HP (below 50% threshold):

| Skill | Weight | Condition | ConditionBonus | Cooldown | CooldownPenalty | Score |
|-------|--------|-----------|----------------|----------|-----------------|-------|
| Heavy Strike | 8.0 | TargetBelowHP50 | 2.0 | 0s | 1.0 | 8.0 × 1.0 × 2.0 × 1.0 = **16.0** |
| Dark Bolt | 5.0 | Always | 1.0 | 2s / 6s | 0.67 | 5.0 × 1.0 × 1.0 × 0.67 = **3.35** |
| Shield Up | 3.0 | EnemyBelowHP50 | 1.0 (boss at 60%) | 0s | 1.0 | 3.0 × 1.0 × 1.0 × 1.0 = **3.0** |
| Enrage Slam | 10.0 | EnragePhase | 0.0 (not enraged) | 0s | 1.0 | 10.0 × 1.0 × 0.0 × 1.0 = **0.0** |

**Selected**: Heavy Strike (score 16.0) — the boss exploits the weakened Tanker.

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| All party members are dead | Enemy stops attacking, returns to Idle state | No valid targets; prevents wasted animations |
| Enemy is stunned mid-telegraph | Telegraph cancels; skill does not fire; cooldown is NOT consumed | Stun interrupts; player gets value from the stun |
| Target switches characters during enemy telegraph | Enemy continues telegraphing toward the original target position; if target moves out of AoE, the attack misses | Telegraphs are position-based, not target-tracking |
| Enemy's only available skill is on cooldown | Enemy moves toward target (closing distance) or uses basic attack if available | Enemies always do something, never stand idle |
| Boss phase transition triggered while player skill is mid-air | Boss becomes invincible; player skill hits but deals 0 damage; cooldown is consumed | Invincibility is absolute; player must time around phase transitions |
| Summoned add spawns outside the combat arena | Clamp spawn position to arena bounds; if impossible, spawn at boss position | Prevents adds from spawning in unreachable locations |
| Enemy tries to use a skill but the referenced SkillDataSO is null | Log error; skip this skill; select next highest-scoring skill | Data error must not crash or freeze |
| Two enemies target the same party member simultaneously | Both attacks resolve independently; party member takes damage from both | No artificial coordination limit between enemies |
| Boss enrage triggers during a party-wide player skill | Enrage transition plays; boss becomes invincible for 2s; player skill hits remaining enemies normally | Enrage is a state change, not an interrupt |
| Enemy movement blocked by environment obstacle | Enemy pathfinds around obstacle using simple steering; if truly blocked, enemy attacks from current position | Enemies should not get stuck |
| Player character is invincible during enemy attack | Attack connects (hit detection fires) but deals 0 damage; cooldown is consumed | Invincibility is resolved in Health & Damage, not here |
| Decision cycle runs but no skills are available (all on cooldown) | Enemy moves toward target or uses basic attack | Decision cycle always produces an action |
| Boss killed during phase transition invincibility | Boss dies immediately; invincibility is overridden by death; death animation plays | Death is the highest-priority state |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Health & Damage System** | Calls / Called by | Hard | Deals damage through this system; receives damage events for enrage/phase triggers |
| **Hit Detection System** | Calls | Hard | Acquires targets for enemy attacks |
| **Skill Execution System** | Calls | Hard | Triggers enemy skills through the same execution pipeline |
| **Status Effects System** | Calls | Hard | Applies debuffs, DoT, and CC to player characters |
| **Combat System** | Called by | Soft | Receives encounter start/end signals; resets state on encounter end |
| **Camera System** | Read by | Soft | Camera tracks telegraphs and adjusts for multi-enemy encounters |
| **Audio System** | Calls | Soft | Plays enemy attack sounds and telegraph warnings |
| **Loot & Drop System** | Triggered by | Soft | Enemy death triggers loot drop |
| **Animation System** | Calls | Soft | Plays enemy animations (attack, telegraph, death, phase transition) |
| **Party AI System** | Read by | Soft | Party AI reads enemy behavior to optimize counter-strategy |
| **Scene Management** | Read by | Soft | Scene Manager positions enemies at encounter start |

**No dependency conflicts.** All interactions are unidirectional except Health & Damage (mutual for damage dealing and damage event reception).

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `DecisionInterval` | float (seconds) | `0.5` | 0.2–1.0 | Enemies react too fast; feels unfair | Enemies are sluggish; combat feels easy |
| `TelegraphDuration` | float (seconds) | `0.8` | 0.5–2.0 | Telegraphs are too fast to react | Telegraphs are so slow combat drags |
| `EnrageHPThreshold` | float | `0.25` (25%) | 0.15–0.40 | Enrage happens too early; fights feel punishing | Enrage barely matters; boss dies before enraging |
| `EnrageCooldownMultiplier` | float | `0.5` | 0.3–0.7 | Enrage makes boss too aggressive | Enrage feels like a minor annoyance |
| `EnrageSPDMultiplier` | float | `1.2` | 1.1–1.4 | Enrage animations become unreadable | Enrage feels visually identical to normal |
| `AddSummonLimit` | int | `4` | 2–8 | Too many adds overwhelm the player | Adds feel like a minor distraction |
| `PhaseTransitionInvincibility` | float (seconds) | `2.0` | 1.0–3.0 | Invincibility feels like a free safe window | Transition is too fast to react to |
| `AggroSwitchThreshold` | float | `0.3` | 0.2–0.5 | Enemies switch targets too frequently | Enemies never adapt their targeting |
| `SeparationDistance` | float | `1.5` | 1.0–2.5 | Enemies spread out too much; melee enemies can't reach target | Enemies stack on top of each other; visual mess |
| `BasicAttackWeight` | float | `3.0` | 1.0–5.0 | Enemies only use basic attacks; no variety | Enemies never use basic attacks; always on cooldown |

### Interacting Knobs

- **DecisionInterval + TelegraphDuration**: A short decision interval with a long telegraph means enemies decide quickly but give the player time to react. A long decision interval with a short telegraph is the opposite — enemies pause longer but strike faster. The product of these two determines the rhythm of enemy attacks.
- **EnrageCooldownMultiplier + EnrageSPDMultiplier**: These stack multiplicatively. A boss with 0.5 cooldown multiplier and 1.2 SPD multiplier during enrage attacks 2× as often and 20% faster — a significant difficulty spike. Tune carefully.
- **AddSummonLimit + AddHP**: The total HP of all possible adds should not exceed the boss's HP — otherwise the adds become the primary threat and the boss is a summoning machine.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Enemy telegraphs attack** | Red AoE indicator on ground; enemy glows with warning color | Warning tone (ascending, urgent) | Critical |
| **Boss enters enrage** | Boss turns red/dark; aura particles intensify; screen tints slightly | Music intensifies; boss roar/growl | Critical |
| **Boss phase transition** | Boss pulls back; invincibility shield visual; form change animation | Dramatic music sting; transformation sound | Critical |
| **Enemy stunned** | Stunned icon above enemy; enemy animation shows dazed state | Stun impact sound | Medium |
| **Enemy summoned** | Spawn VFX (portal, explosion, or materialization) | Summon sound (magical or physical) | High |
| **Enemy dies** | Death animation per enemy type; loot drops visibly | Death sound per enemy type | High |
| **Basic attack** | Attack animation with weapon swing; hit spark on impact | Weapon swing + hit sound | Medium |
| **Skill attack** | Skill-specific VFX (fireball, dark bolt, etc.) | Skill-specific audio cue | High |
| **Enemy movement** | Walk/run animation; footstep particles for large enemies | Footsteps appropriate to surface | Low |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Enemy HP bar | World-space above enemy model | Every frame | Always visible during combat |
| Enemy name | Above HP bar | Static | Displayed when enemy is targeted or hovered |
| Boss phase indicator | Combat HUD (top-center) | On phase transition | "Phase 1", "Phase 2", "ENRAGE" |
| Boss HP bar | Combat HUD (top-center, large) | Every frame | Only for Boss-class enemies |
| Enemy status effect icons | Below enemy HP bar | On application/removal | Shows active debuffs on enemy |
| Telegraph warning | Red AoE on ground + HUD icon | During telegraph duration | For all telegraphed attacks |
| Enrage indicator | Red border around boss HP bar | While enraged | Visual urgency signal |
| Enemy target highlight | Outline on selected enemy | On player target selection | Helps player identify current target |

## Acceptance Criteria

- [ ] Enemy behavior profile correctly selects skills based on weight, range, condition, and cooldown
- [ ] Telegraphed attacks show clear visual/audio warning before the skill fires
- [ ] Bosses transition between phases correctly at HP thresholds, with 2s invincibility
- [ ] Enrage triggers at defined HP threshold; cooldowns halved, SPD increased, new skills available
- [ ] Enemies move toward targets using separation steering; no enemy stacking
- [ ] Target selection follows behavior profile priorities (Aggressive = lowest HP, Tactical = lowest DEF, etc.)
- [ ] Summoned adds spawn within arena bounds and use Aggressive behavior profile
- [ ] Adds die instantly when the summoning boss dies
- [ ] Enemy state machine transitions correctly (Idle → Moving → Telegraphing → Attacking → Idle)
- [ ] Stunned enemies cancel telegraphs and skip skill execution without consuming cooldown
- [ ] Decision cycle runs at the defined interval per enemy class (Grunt 0.5s, Elite 0.3s, Boss 0.2s)
- [ ] Enemy skills execute through the Skill Execution System pipeline (same as player skills)
- [ ] Performance: 20 enemies running decision cycles simultaneously adds < 2.0ms frame time
- [ ] Enemy death triggers loot drop through the Loot & Drop System

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| Should some enemies have elemental weaknesses that double damage from a specific category? | Game Designer | Resolve during encounter design per chapter — this affects CategoryResistance tuning |
| Should bosses have a "stagger" mechanic (taking enough damage of one type breaks their guard)? | Systems Designer | Resolve during Combat System design — stagger adds depth but increases complexity |
| Should enemy AI difficulty scale with the Party AI expertise scalar (harder player AI = harder enemies)? | Systems Designer | Resolve during Party AI implementation — this creates dynamic difficulty but may feel unfair |
| Should there be a bestiary UI that records encountered enemy behaviors, weaknesses, and loot tables? | UX Designer | Resolve during post-MVP — not needed for MVP but valuable for player discovery |
