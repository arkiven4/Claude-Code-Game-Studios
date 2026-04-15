# Skill Database

> **Status**: Approved
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game

## Overview

The Skill Database is the master definition for all character skills in the game —
damage, support, status effect, and utility abilities. Stored as four Resource
types (`SkillDamage`, `SkillSupport`, `SkillStatus`, `SkillUtility`), each
skill's data card defines its MP cost, cooldown, targeting rules, effect parameters,
and three tier definitions (Tier 1 at Level 1, Tier 2 at Level 8, Tier 3 at Level 18).
Players interact with the Skill Database indirectly: when they use a skill in combat,
watch it upgrade at Level 8, or notice that their healer's Tier 3 now heals the whole
party instead of one target, they are seeing Skill Database entries in action. Each
skill's tier upgrades are qualitative changes — more targets, larger areas, stronger
effects — not mere stat bumps. Every system that handles skills — Skill Execution,
Character Progression, Combat, Combat HUD — reads from these cards. Nothing in the game
can reference a skill without going through its Skill Database entry.

## Player Fantasy

Skill Database serves the fantasy of **growing into your power, one upgrade at a time**.
When a player uses a Tier 1 skill at Level 1, it should feel functional but limited —
"this is my starting tool." When they hit Level 8 and every skill upgrades simultaneously,
the player should feel a rush of satisfaction: their tools are *better* now, not just
numerically stronger but qualitatively improved. A single-target heal becomes a party
heal. A narrow attack hits three enemies. The anticipation of Level 8 and Level 18 is
part of the progression loop — players look forward to their skills evolving. Each
character's skill set should feel like a unique toolkit: Evelyn's Mage skills are
bursty and area-focused, Evan's Swordman skills are precise and counter-oriented, the
Healer's skills are sustain-oriented. The player should never feel like two characters
play the same way, even if they share a class.

**Reference model**: Final Fantasy X's Sphere Grid and Tales series' skill trees —
players anticipate unlock moments because they know what's coming and it feels earned.

## Detailed Rules

### Core Rules

1. **Four Resource types** exist, one per skill category:
   - `SkillDamage` — skills that deal damage to enemies (direct, AoE, DoT)
   - `SkillSupport` — skills that heal, buff, or protect allies
   - `SkillStatus` — skills that apply status effects (slow, stun, poison, silence, taunt)
   - `SkillUtility` — skills that provide utility (movement, shields, MP generation, resource manipulation)

2. **Every skill Resource shares these common fields**:

   | Field | Type | Description |
   |-------|------|-------------|
   | `SkillName` | string | Display name shown in HUD and skill menu |
   | `Description` | string | One-line description shown in tooltip |
   | `Icon` | Sprite | Skill icon displayed in Combat HUD skill bar |
   | `Animation` | AnimationClip | Animation played when skill is executed |
   | `AudioCue` | AudioStream | Sound played on skill activation |
   | `Category` | enum | `Physical`, `Magical`, `Holy`, `Dark` — used for resistance calculations |
   | `MPCost` | int | MP consumed when skill is used (0 for skills that cost nothing) |
   | `Cooldown` | float (seconds) | Time before skill can be used again |
   | `UnlockCondition` | string (optional) | Narrative or progression gate (e.g., "Unlocked in Chapter 2"); empty = available from Level 1 |

3. **Every skill defines a `TargetType` enum** with the following values. `TargetType` is
   the base targeting behavior at Tier 1. When a tier upgrade increases `TargetCount`
   beyond 1 on a `SingleEnemy` skill, Hit Detection treats it as "N nearest enemies within
   `PointRadius`" — no geometry change, just more targets selected. For geometric types
   (Line, Cone, AllEnemies), `TargetCount` caps how many individual targets within that
   area receive the effect (99 = unlimited).

   | Target Type | Description | Examples |
   |-------------|-------------|----------|
   | `SingleEnemy` | One enemy target | Single-target attack, single-target debuff |
   | `MultiEnemyLine` | Enemies in a line (frontal) | Cleave, linear projectile |
   | `MultiEnemyCone` | Enemies in a cone (frontal AoE) | Cone attack, breath weapon |
   | `AllEnemies` | All enemies on screen | Party-wide AoE, global effect |
   | `SingleAlly` | One ally (can be self) | Single heal, single buff |
   | `AllAllies` | All party members | Party heal, party buff |
   | `Self` | The skill user only | Self-buff, stance change, MP regen |

4. **Every skill defines three tier configurations** (Tier 1, Tier 2, Tier 3). Each tier
   specifies:

   | Tier Field | Type | Description |
   |------------|------|-------------|
   | `EffectValue` | float | Primary effect magnitude (damage multiplier, heal amount, buff percentage, etc.) |
   | `EffectValueSecondary` | float | Secondary effect magnitude (DoT damage, buff duration, etc.); 0 if not applicable |
   | `TargetCount` | int | Number of targets (1 = single, 2-3 = multi, 99 = all) |
   | `AreaRadius` | float (meters) | Radius of AoE effect; 0 for single-target skills |
   | `Duration` | float (seconds) | How long the effect persists (buff duration, DoT ticks); 0 for instant effects |
   | `TierDescription` | string | One-line text shown in tooltip explaining what changed from the previous tier |

5. **Tier upgrade categories** (from Character Data GDD — each skill uses exactly one):

   | Category | What Changes | Example |
   |----------|-------------|---------|
   | **Target Count** | TargetCount increases | Tier 1: 1 enemy → Tier 2: 2 enemies → Tier 3: 3 enemies |
   | **Area** | AreaRadius increases | Tier 1: 2m → Tier 2: 4m → Tier 3: 6m |
   | **Effect Intensity** | EffectValue increases | Tier 1: 100% ATK → Tier 2: 150% ATK → Tier 3: 200% ATK |
   | **Buff Power** | EffectValue increases | Tier 1: +10% ATK → Tier 2: +18% ATK → Tier 3: +28% ATK |
   | **Duration** | Duration increases | Tier 1: 3s → Tier 2: 5s → Tier 3: 8s |
   | **Hybrid** | Two categories change | Tier 1: single slow → Tier 2: AoE slow → Tier 3: AoE slow + DoT |

6. **No system may write to skill Resources at runtime**. Skills are read-only
   definitions. Runtime state (current cooldown, active buffs applied by the skill) is
   tracked in the Skill Execution System and Character State Manager.

7. **Skill assignment to characters** is defined in `CharacterData` — each character
   references exactly 4 `SkillData` assets (one per slot). The Skill Database does
   not own which characters have which skills.

8. **Skills cannot reference other skills**. Each skill is self-contained. Chain effects
   (e.g., "after using this skill, the next skill deals bonus damage") are handled by
   the Skill Execution System, not by skill-to-skill references.

### States and Transitions

`SkillDamage`, `SkillSupport`, `SkillStatus`, and `SkillUtility` are **stateless** Resources — they define skill templates and never change at runtime.

Runtime state for skill instances is tracked in `SkillRuntimeState`, a per-skill-per-character runtime container managed by the Skill Execution System:

| State Property | Type | Default | Description |
|---------------|------|---------|-------------|
| `CurrentCooldown` | float (seconds) | 0 | Remaining cooldown time; decremented each frame |
| `ActiveInstances[]` | list | empty | Active buffs/debuffs/DoTs applied by this skill (each with duration, target, effect value) |
| `ChargeCount` | int | 1 | Number of available charges (for skills that can be used multiple times before cooldown); defaults to 1 |
| `MaxCharges` | int | 1 | Maximum number of charges this skill can store. `0` means the skill uses cooldown instead of charges; `1` is default (standard cooldown skill). Only skills with `MaxCharges > 1` restore charges on cooldown completion. |

**State Transitions (SkillRuntimeState):**

| From State | Trigger | To State | Notes |
|-----------|---------|----------|-------|
| Cooldown = 0 | Player activates skill | Cooldown = Cooldown (from SkillData) | Validates MPCost and ChargeCount; consumes MP; plays Animation + AudioCue |
| Cooldown > 0 | Each frame update | Cooldown -= deltaTime | Cooldown ticks down in real-time; not paused during character switch |
| ChargeCount < MaxCharges | Cooldown reaches 0 | ChargeCount++ | Only for skills with MaxCharges > 1 |
| Skill applies buff/debuff | Skill execution | ActiveInstances.add(buff) | Buff has its own duration timer independent of skill cooldown |
| Buff/debuff duration expires | Timer reaches 0 | ActiveInstances.remove(buff) | Effect is removed; target's stats are recalculated |
| Character switches out | Input authority changes | No change to skill state | Cooldown and charges persist across switch; only input authority changes |

**Skills that do not create persistent effects** (instant damage, instant heal) have no ActiveInstances — they apply their effect immediately and have no ongoing state.

### Interactions with Other Systems

| System | Direction | What It Reads |
|--------|-----------|---------------|
| Character Data | Depends on Skill Database | Reads SkillSlot0–3 references; reads active tier thresholds (Level 8, Level 18) |
| Skill Execution System | Reads Skill Resources + SkillRuntimeState | All skill fields (MPCost, Cooldown, TargetType, tier data); tracks cooldown and active instances |
| Character Progression System | Reads SkillData | Tier unlock levels (8, 18) to trigger tier upgrades on level-up |
| Character Skill System | Reads Skill Resources | Skill definitions for character-specific skill unlocks and progression |
| Combat HUD | Reads SkillRuntimeState (via Skill Execution) | Current cooldown per skill; active skill tier icon; charge count |
| Health & Damage System | Reads SkillData | Category (Physical/Magical/Holy/Dark) for resistance calculation; EffectValue for damage computation |
| Status Effects System | Reads SkillData | Status effect type and magnitude from SkillStatus |
| Combat System | Reads SkillData + SkillRuntimeState | Skill effect execution; ActiveInstances for buff/debuff tracking during combat |
| Party AI System | Reads SkillData | MPCost, Cooldown, TargetType (to make optimal skill usage decisions) |
| Audio System | Reads SkillData.AudioCue | Plays the skill's activation sound |
| Animation System | Reads SkillData.Animation | Plays the skill's animation clip |
| Save / Load System | Reads SkillRuntimeState | Serializes CurrentCooldown, ChargeCount, ActiveInstances per skill per character |

**Interface ownership**: The Skill Database **owns** the skill definition schema. The Skill Execution System **owns** the runtime state (cooldowns, charges, active instances). No system writes to the base Resource.

## Formulas

### Skill Damage Calculation

```
SkillDamage = max(1, floor(((CasterATK × 0.5 + SkillBaseDamage) × EffectValue × CategoryResistance) - TargetDEF))
```

> **Formula order**: CategoryResistance is applied **before** DEF subtraction. This means resistances reduce the raw hit, then DEF absorbs from the result. This matches the canonical formula in health-damage-system.md.

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| CasterATK | int | 25–239 | CharacterData (with equipment bonuses) | Attacker's effective ATK |
| SkillBaseDamage | int | 20–80 | SkillDamage | Base damage of the skill (before multiplier) |
| EffectValue | float | 0.8–2.5 | SkillDamage tier config | Damage multiplier per tier |
| TargetDEF | int | 15–142 | CharacterData (with equipment bonuses) | Target's effective DEF |
| CategoryResistance | float | 0.5–1.5 | Enemy data (per-enemy resistance table) | Multiplier based on damage category (Physical/Magical/Holy/Dark) |

**Minimum damage**: SkillDamage cannot go below 1. If the formula produces ≤ 0, damage is clamped to 1.

**Example** — Evelyn (ATK 239) uses Tier 2 fire skill (BaseDamage 50, EffectValue 1.5) against an enemy with DEF 60 and Magical resistance 1.0:
- SkillDamage = max(1, floor(((239 × 0.5 + 50) × 1.5 × 1.0) - 60))
- = max(1, floor((119.5 + 50) × 1.5 - 60))
- = max(1, floor(169.5 × 1.5 - 60))
- = max(1, floor(254.25 - 60))
- = max(1, floor(194.25)) = max(1, 194) = **194 damage**

---

### Skill Heal Calculation

```
SkillHeal = (CasterMaxMP × 0.1 + SkillBaseHeal) × EffectValue + (TargetMaxHP × TargetMaxHPBonus)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| CasterMaxMP | int | 60–323 | CharacterData (with equipment bonuses) | Healer's effective MaxMP |
| SkillBaseHeal | int | 30–100 | SkillSupport | Base heal amount of the skill |
| EffectValue | float | 0.8–2.0 | SkillSupport tier config | Heal multiplier per tier |
| TargetMaxHP | int | 220–1292 | CharacterData | Target's effective MaxHP |
| TargetMaxHPBonus | float | 0.0–0.3 | SkillSupport | Additional heal as % of target's MaxHP; 0 if not applicable |

**Maximum healing**: SkillHeal cannot exceed the target's MaxHP. Overheal is discarded.

> **Design note**: Heal skills scale on `CasterMaxMP` intentionally — equipping MP gear on healers increases heal output. Equipment designers should treat `MaxMP` as a healer's primary offensive stat. This is the intended interaction, not a bug.

**Example** — Healer (MaxMP 200) uses Tier 2 heal (BaseHeal 60, EffectValue 1.3, TargetMaxHPBonus 0.1) on a Tanker (MaxHP 952):
- SkillHeal = (200 × 0.1 + 60) × 1.3 + (952 × 0.1)
- SkillHeal = (20 + 60) × 1.3 + 95.2
- SkillHeal = 80 × 1.3 + 95.2 = 104 + 95.2 = **199.2 → 199 HP restored**

---

### MP Cost Per Tier

```
MPCost(Tier) = BaseMPCost + ((Tier - 1) × MPCostIncrement)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseMPCost | int | 10–50 | SkillData | MP cost at Tier 1 |
| Tier | int | 1–3 | Character Progression System | Current active tier |
| MPCostIncrement | int | 5–15 | SkillData | MP cost increase per tier level |

**Example** — Skill with BaseMPCost 20, MPCostIncrement 8:
- Tier 1: 20 MP
- Tier 2: 28 MP
- Tier 3: 36 MP

---

### Cooldown Calculation

```
EffectiveCooldown = BaseCooldown × (1 - CooldownReductionBonus)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseCooldown | float (seconds) | 2.0–15.0 | SkillData | Base cooldown of the skill |
| CooldownReductionBonus | float | 0.0–0.40 (0%–40%) | Equipment bonuses + buffs | Percentage cooldown reduction (capped at 40%) |

**Example** — Skill with 8s base cooldown, character has 25% cooldown reduction from equipment:
- EffectiveCooldown = 8.0 × (1 - 0.25) = 8.0 × 0.75 = **6.0 seconds**

---

### Buff/Debuff Effectiveness

```
BuffedStat = BaseStat × (1 + EffectValue)  (for percentage buffs)
BuffedStat = BaseStat + EffectValue        (for flat buffs)
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseStat | int or float | Varies | Character or enemy stat | Stat being modified |
| EffectValue | float | Varies | SkillSupport or SkillStatus tier config | Buff/debuff magnitude |
| Buff Type | enum | — | Skill data | Determines whether formula is percentage or flat |

Multiple buffs of the same type on the same stat are **additive**, not multiplicative:
```
TotalBuff = 1 + (Buff1_EffectValue + Buff2_EffectValue + ...)
```

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player activates a skill but doesn't have enough MP | Skill fails to activate; a "Not enough MP" tooltip appears; no cooldown is triggered | MP cost must be validated before cooldown; penalizing cooldown for insufficient MP feels unfair |
| Skill targets an invalid target (dead ally, dead enemy) | Skill fizzles; MP is not consumed; cooldown is not triggered | Invalid targets are selection errors, not skill execution failures |
| Two buffs from the same skill are applied to the same target (skill used twice before first buff expires) | Buffs do NOT stack; the second application refreshes the duration but does not increase the magnitude | Prevents buff stacking exploits; refresh is still valuable |
| Character dies while a skill's animation is playing | Animation is cancelled; skill effect is NOT applied; MP is not consumed (if not already consumed at animation start) | Prevents wasted resources on death-transition edge cases |
| Skill cooldown is active when character switches out | Cooldown continues ticking down; skill is available again based on real time, not active character time | Prevents switch-abuse where players swap to avoid cooldowns |
| A skill's tier upgrade happens mid-combat (character levels to 8 or 18) | Current skill cast completes at old tier; next use applies new tier; cooldown and MP cost update to new tier values | Prevents mid-animation state corruption; consistent with Character Data GDD |
| Player has a skill with UnlockCondition = "Chapter 2" but is still in Chapter 1 | Skill slot is greyed-out in HUD with a lock icon; tooltip shows "Unlocks in Chapter 2" | Clear feedback; no confusion about why a skill is unavailable |
| Cooldown reduction from equipment exceeds 40% cap | Cap at 40%; excess reduction is ignored; HUD shows "Cooldown Reduction Cap Reached" | Prevents near-zero cooldown exploits; cap keeps skill rotation meaningful |
| Skill references a null Animation or AudioCue | Log a warning at scene load; use a default animation/sound fallback; skill still functions | Data authoring errors must never crash the game or break functionality |
| Buff/debuff persists after the skill-using character is removed from the party | Buff/debuff remains active for its full duration; it is independent of the caster's party status | Prevents buff flickering when party composition changes mid-encounter |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Character Data** | Depends on Skill Database | Hard | References 4 SkillData per character; reads tier unlock levels (8, 18) |
| **Skill Execution System** | Depends on Skill Database | Hard | Reads all skill fields; creates and manages SkillRuntimeState per skill per character |
| **Character Progression System** | Depends on Skill Database | Soft | Reads tier unlock levels to trigger skill upgrades on level-up |
| **Character Skill System** | Depends on Skill Database | Hard | Reads skill definitions for character-specific unlocks and progression tracking |
| **Combat HUD** | Reads Skill Database (via Skill Execution) | Soft | Reads skill icons, cooldown state, tier indicator, charge count for display |
| **Health & Damage System** | Reads Skill Database | Soft | Reads damage category (Physical/Magical/Holy/Dark) and EffectValue for resistance calculation |
| **Status Effects System** | Reads Skill Database | Soft | Reads status effect type and magnitude from SkillStatus |
| **Combat System** | Reads Skill Database | Soft | Reads skill effect parameters for execution during combat |
| **Party AI System** | Reads Skill Database | Soft | Reads MPCost, Cooldown, TargetType for optimal skill selection |
| **Audio System** | Reads Skill Database | Soft | Reads AudioCue for skill activation sound |
| **Animation System** | Reads Skill Database | Soft | Reads Animation clip for skill execution |
| **Save / Load System** | Depends on Skill Runtime State | Hard | Serializes SkillRuntimeState (cooldown, charges, active instances) per skill per character |

**No upstream dependencies**: Skill Database is a foundation root — it defines skill templates independently. It depends only on the shared data types (enums, structs) defined in the project's core namespace.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect if Too High | Effect if Too Low |
|-----------|--------------|------------|-------------------|-------------------|
| **SkillBaseDamage** | 20–80 per skill | ±15 | Skills overshadow basic attacks; players only use skills | Skills feel like wasted MP; players stick to basic attacks |
| **SkillBaseHeal** | 30–100 per skill | ±20 | Heals trivialize encounters; no tension | Heals are imperceptible; healer role feels pointless |
| **EffectValue (damage)** | 0.8–2.5 per tier | 0.5–3.0 | Tier 3 one-shots enemies; no strategic depth | Tier upgrades feel unrewarding; no power progression |
| **EffectValue (heal)** | 0.8–2.0 per tier | 0.5–2.5 | Heals overheal constantly; MP wasted | Tier upgrades don't feel impactful |
| **BaseMPCost** | 10–50 per skill | 5–70 | Skills are too expensive; players hoard MP | Skills are spam; MP pool is meaningless |
| **MPCostIncrement** | 5–15 per tier | 3–20 | Higher tiers feel too costly; players avoid them | Tier upgrades feel free; no resource tension |
| **BaseCooldown** | 2.0–15.0s per skill | 1.0–20.0s | Skills are always on cooldown; frustrating rotation | Skills are always available; no timing decisions |
| **Cooldown Reduction Cap** | 40% | 25%–60% | Cooldowns are near-zero; skill spam | Cooldown reduction is pointless; equipment stat feels wasted |
| **CategoryResistance** | 0.5–1.5 per enemy | 0.3–2.0 | Some damage types are completely useless against certain enemies | Resistances don't matter; category choice is irrelevant |
| **Buff/Debuff Duration** | 3–8s per tier | 2–15s | Buffs last entire encounters; no reapplication skill | Buffs expire before they can be useful; frustrating |
| **ChargeCount (for charge skills)** | 1–3 per skill | 1–5 | Charge skills dominate; always available | Charge system is unused; single-charge skills feel restrictive |

**Interacting Knobs**:
- **BaseMPCost + MPCostIncrement**: These must be tuned together — high base cost with high increment makes Tier 3 unusable
- **SkillBaseDamage + Character ATK growth**: If skill damage scales too heavily on ATK, equipment ATK bonuses become overpowered
- **BaseCooldown + Cooldown Reduction Cap**: Lower base cooldowns make the cap less impactful; these need balanced tuning

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Skill activated** | Skill icon flashes; target indicator appears (line/cone/AoE) | Skill's AudioCue plays; target acquisition sound | Critical |
| **Skill on cooldown** | Skill icon darkens; cooldown timer overlay counts down | No sound (visual-only feedback) | High |
| **Skill ready (cooldown ends)** | Skill icon brightens; subtle pulse animation | Soft "ready" chime (only for active character) | Medium |
| **Tier 2 unlock (Level 8)** | All 4 skill icons get a golden border glow; "TIER 2" text flashes | Ascending chime — same as Character Data spec | High |
| **Tier 3 unlock (Level 18)** | All 4 skill icons ignite with a stronger golden fire; "TIER 3" text | Powerful ascending chord — most memorable unlock | High |
| **Skill misses (no valid targets)** | Skill animation plays but no impact effect; "No valid targets" text | Error "buzz" — clear failure feedback | Medium |
| **Buff applied to ally** | Green/blue particle effect on target; buff icon appears in their HUD bar | Soft "empower" sound | Medium |
| **Debuff applied to enemy** | Red/purple particle effect on enemy; debuff icon appears near their HP bar | Harsh "affliction" sound | Medium |
| **Buff/debuff expires** | Icon fades out; particle effect dissipates | Soft "expiration" sound (subtle) | Low |
| **Not enough MP** | Skill icon shakes briefly; red "Not enough MP" tooltip | Low "denied" buzz | High |
| **Charge used (multi-charge skill)** | Charge counter decrements on icon; small flash | "Charge consumed" click sound | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Skill icon | Combat HUD skill bar (active character only) | Static | Always visible during combat for active character |
| Skill cooldown overlay | On top of skill icon | Every frame while on cooldown | Dark overlay with countdown timer; disappears when ready |
| Charge count | Bottom-right corner of skill icon | On charge use/regen | Displays as "×N" badge |
| Skill tier indicator | Border color of skill icon | On tier unlock (Level 8, 18) | Tier 1: white border, Tier 2: golden border, Tier 3: golden glow |
| MP cost | Tooltip on hover | Static | Shows in skill detail tooltip |
| Skill description + tier details | Skill detail tooltip (expanded view) | On tier unlock | Shows TierDescription text for current active tier |
| Buff/debuff icons (from active skill instances) | Character HUD bar (below HP/MP) | On application/removal | Each active instance gets its own icon with duration timer |
| Cooldown Reduction Cap indicator | Skill tooltip | When equipment bonuses reach 40% cap | Warning text: "Cooldown Reduction at maximum" |
| Skill unlock condition (if locked) | Greyed-out skill icon with lock overlay | Static | Tooltip shows "Unlocks in [Chapter/Condition]" |
| Target type indicator | Skill tooltip | Static | Shows icon + text (e.g., "Cone AoE", "Single Ally") |
| Damage/Heal category | Skill tooltip | Static | Shows category (Physical/Magical/Holy/Dark) with resistance hint |

## Acceptance Criteria

- [ ] All four Resource types (`SkillDamage`, `SkillSupport`, `SkillStatus`, `SkillUtility`) can be created in the Godot Editor and saved as `.tres` files
- [ ] Skill damage formula produces correct results: `max(1, floor(((CasterATK × 0.5 + SkillBaseDamage) × EffectValue × CategoryResistance) - TargetDEF))` — verified by unit test with known inputs
- [ ] Skill heal formula produces correct results: `(CasterMaxMP × 0.1 + SkillBaseHeal) × EffectValue + (TargetMaxHP × TargetMaxHPBonus)` — verified by unit test
- [ ] MP cost per tier formula produces correct results: `BaseMPCost + ((Tier - 1) × MPCostIncrement)` — verified by unit test
- [ ] Cooldown reduction is capped at 40% — equipping items that would exceed 40% logs a warning and caps the bonus (verified by unit test)
- [ ] Skills cannot be activated with insufficient MP — MP is not consumed, cooldown is not triggered (verified by integration test)
- [ ] Buffs from the same skill do not stack — second application refreshes duration only (verified by integration test)
- [ ] Skill cooldowns continue ticking down when the character is switched out (verified by integration test)
- [ ] Tier upgrade mid-combat completes current cast at old tier before applying new tier values (verified by integration test)
- [ ] Skills with UnlockCondition gates are greyed-out with lock icon and tooltip until condition is met (verified by unit test)
- [ ] Null Animation or AudioCue references log a warning and use default fallbacks without crashing (verified by unit test)
- [ ] Multiple buffs of the same type on the same stat are additive, not multiplicative (verified by unit test)
- [ ] Minimum skill damage is clamped to 1 — damage cannot be 0 or negative (verified by unit test)
- [ ] SkillRuntimeState is correctly serialized and deserialized by Save/Load — cooldown, charges, and active instances persist across save/load cycles (verified by round-trip test)
- [ ] Performance: reading skill Resource fields adds no measurable frame time (< 0.01ms per skill lookup); 4 skills × 4 party members = 16 lookups per frame at maximum

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| How many unique skills will each character have? (4 per character is fixed — but how many total across the roster?) | Game Designer | Resolve before skill data authoring begins — affects total SkillData asset count |
| Should skills have elemental sub-types (Fire, Ice, Lightning, Wind) beyond the 4 damage categories? | Game Designer / Narrative Director | Resolve before Enemy AI resistance table is authored — affects CategoryResistance complexity |
| What is the expected skill rotation length? (How many skills should a player use per encounter?) | Game Designer | Resolve during combat encounter design — validates cooldown and MP cost tuning |
| Should the Witch (prologue-only) have a simplified skill set (2 skills) or the full 4? | Narrative Director / Game Designer | Resolve before Witch prologue is authored — affects MVP scope |
| Are there "ultimate" skills with very long cooldowns (30s+) that are encounter-defining moments? | Game Designer | Resolve during skill authoring — affects cooldown range validation |
| Should skill animations be interruptible (character switched out mid-animation) or must they complete? | Technical Director / Gameplay Programmer | Resolve during Character Switching System GDD — affects state machine complexity |
| Do status effect skills (stun, silence) have diminishing returns on repeated application to the same enemy? | Game Designer | Resolve before Enemy AI and Status Effects GDDs are authored — prevents stun-lock exploits |
