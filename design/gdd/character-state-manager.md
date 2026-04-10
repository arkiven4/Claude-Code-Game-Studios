# Character State Manager

> **Status**: Approved
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game

## Overview

The Character State Manager is the runtime state container for every party member in My Vampire. Implemented as a `PartyMemberState` Node that lives permanently on each character's GameObject, it owns and continuously ticks the four mutable values that define a character's combat state: current HP, current MP, skill cooldowns, and active status effects. It initializes from `CharacterData` on scene load, exposes read-only state to all other systems (Combat HUD, Party AI, Enemy AI), and accepts writes only from the systems authorized to change each value — Health & Damage writes HP/MP, Skill Execution writes cooldowns, Status Effects writes active effects, Character Switch Controller writes control authority. No state is ever frozen or copied on a character switch — the system ticks for all 4 party members simultaneously, whether player-controlled or AI-controlled.

## Player Fantasy

The Character State Manager serves the fantasy of **a party that keeps fighting for you**. When the player switches from Evelyn to Evan mid-combat, Evelyn doesn't freeze — her DoT ticks, her cooldowns count down, her AI keeps acting. When the player switches back, Evelyn is exactly as they left her: same HP, same buffs, same position. The system is invisible but its absence would be immediately felt. Players trust their party because the party's state is always honest, always current, and never surprising.

## Detailed Design

### Core Rules

1. **One `PartyMemberState` per character**: Every party member has exactly one `PartyMemberState` Node on their root GameObject. It is never duplicated, pooled, or shared.

2. **State fields** (all runtime-mutable; read-only to external systems except authorized writers):

   | Field | Type | Default | Authorized Writer | Description |
   |-------|------|---------|-------------------|-------------|
   | `CurrentHP` | int | `CharacterData.MaxHP` | Health & Damage System | Current health points, clamped 0–MaxHP |
   | `CurrentMP` | int | `CharacterData.MaxMP` | Skill Execution System | Current mana points, clamped 0–MaxMP |
   | `SkillCooldowns` | `float[4]` | `0f` each | Skill Execution System | Remaining cooldown in seconds per skill slot |
   | `SkillCharges` | `int[4]` | `MaxCharges` each | Skill Execution System | Remaining charges per skill slot |
   | `ActiveEffects` | `List<ActiveEffect>` | empty | Status Effects System | All active buffs, debuffs, DoTs, shields |
   | `ShieldValue` | int | `0` | Status Effects System | Current shield absorption remaining |
   | `IsPlayerControlled` | bool | false (true for Evelyn at start) | CharacterSwitchController only | Whether this character accepts player input |
   | `IsAlive` | bool | true | Health & Damage System | False when CurrentHP == 0 |
   | `RevivesUsedThisEncounter` | int | 0 | Health & Damage System | Tracks one-revive-per-encounter rule |
   | `IsInvincible` | bool | false | Skill Execution / Character Switching | No damage taken while true |
   | `ControlState` | enum | `AIControlled` | CharacterSwitchController | `PlayerControlled`, `AIControlled`, `SwitchingIn`, `SwitchingOut` |

3. **Initialization** (on `Awake()`, before any other system runs):
   1. Read assigned `CharacterData` reference (set in Inspector)
   2. `CurrentHP = CharacterData.MaxHP`
   3. `CurrentMP = CharacterData.MaxMP`
   4. `SkillCooldowns[0..3] = 0f`
   5. `SkillCharges[i] = SkillDataSO[i].MaxCharges` for each slot
   6. `ActiveEffects = new List<ActiveEffect>()`
   7. `ShieldValue = 0`
   8. `IsAlive = true`
   9. `RevivesUsedThisEncounter = 0`
   10. `ControlState = AIControlled` (CharacterSwitchController sets one character to `PlayerControlled` after all `Awake()` calls complete)
   11. Resolve active skill tier: level ≥ 18 → Tier 3; level ≥ 8 → Tier 2; else Tier 1

4. **Per-frame tick** (`Update()`, runs for ALL party members regardless of control state):
   - Decrement each `SkillCooldowns[i]` by `Time.deltaTime`, clamped to `≥ 0`
   - If `SkillCooldowns[i]` reaches 0 and `SkillCharges[i] < MaxCharges`: restore all charges
   - Decrement `RemainingDuration` on each `ActiveEffect`; remove expired effects
   - Tick DoT effects via Status Effects System at their interval
   - No HP or MP regeneration outside of skill/item effects

5. **State query API** (read-only, used by Party AI, Combat HUD, Enemy AI):

   | Query | Returns | Used By |
   |-------|---------|---------|
   | `GetHPRatio()` | `float` 0.0–1.0 | Party AI observations, HUD |
   | `GetMPRatio()` | `float` 0.0–1.0 | Party AI observations, HUD |
   | `GetCooldownRatio(int slot)` | `float` 0.0–1.0 | Party AI observations, HUD |
   | `GetHealthState()` | `HealthState` enum | Combat system, HUD |
   | `HasEffect(string effectId)` | `bool` | Party AI, Status Effects |
   | `GetEffectiveATK()` | `int` | Damage calculations |
   | `GetEffectiveDEF()` | `int` | Damage calculations |
   | `GetEffectiveSPD()` | `float` | Animation speed |
   | `GetEffectiveCRIT()` | `float` | Crit roll |
   | `CanUseSkill(int slot)` | `bool` | Skill Execution, Party AI |
   | `IsSkillAvailable(int slot)` | `bool` | HUD display |

6. **Write authority**: Only authorized systems may write state. Unauthorized writes are a bug — enforce with `private set` on all mutable properties. Authorized writes go through explicit public methods:

   | Method | Authorized Caller | What It Does |
   |--------|-------------------|--------------|
   | `ApplyDamage(int amount)` | Health & Damage | Reduces CurrentHP, updates IsAlive |
   | `ApplyHeal(int amount)` | Health & Damage | Increases CurrentHP, clamped to MaxHP |
   | `ConsumeMP(int amount)` | Skill Execution | Reduces CurrentMP |
   | `RestoreMP(int amount)` | Skill Execution | Increases CurrentMP, clamped to MaxMP |
   | `SetCooldown(int slot, float duration)` | Skill Execution | Sets SkillCooldowns[slot] |
   | `ConsumeCharge(int slot)` | Skill Execution | Decrements SkillCharges[slot] |
   | `AddEffect(ActiveEffect effect)` | Status Effects | Adds to ActiveEffects list |
   | `RemoveEffect(string effectId)` | Status Effects | Removes from ActiveEffects list |
   | `SetShield(int value)` | Status Effects | Sets ShieldValue |
   | `AbsorbShieldDamage(int damage)` | Health & Damage | Reduces ShieldValue, returns remainder |
   | `SetInvincible(bool value)` | Skill Execution, CharacterSwitch | Sets IsInvincible |
   | `SetPlayerControlled(bool value)` | CharacterSwitchController | Sets IsPlayerControlled + ControlState |
   | `ResetForEncounter()` | Combat System | Resets cooldowns, charges, RevivesUsed |
   | `OnRevived()` | Health & Damage | Sets IsAlive=true, CurrentHP=25% MaxHP, increments RevivesUsed |

7. **Effective stat calculation** (accounts for all active buffs/debuffs):
   ```
   EffectiveATK = (CharacterData.ATK × (1 + ΣPercentageBuffs_ATK - ΣPercentageDebuffs_ATK)) + ΣFlatBuffs_ATK - ΣFlatDebuffs_ATK
   ```
   Clamped to minimum `CharacterData.ATK × 0.1`. Same formula for DEF, SPD, CRIT, MaxHP, MaxMP. Recalculated on every buff/debuff application or removal — not cached (stats change too frequently to cache safely).

8. **HealthState enum** (derived, never stored — computed from HP ratio each query):

   | State | Condition |
   |-------|-----------|
   | `Healthy` | `CurrentHP > MaxHP × 0.5` |
   | `Injured` | `MaxHP × 0.1 < CurrentHP ≤ MaxHP × 0.5` |
   | `Critical` | `0 < CurrentHP ≤ MaxHP × 0.1` |
   | `Dead` | `CurrentHP == 0` |

9. **No state is ever reset on character switch.** All ticking continues. This is the core invariant of ADR-0002: the switch controller transfers input authority only, never state.

### States and Transitions

**ControlState enum** (managed by CharacterSwitchController):

```
┌──────────────┐  SwitchTo(this)  ┌──────────────────┐
│ AIControlled │ ───────────────▶ │   SwitchingIn     │
│              │                  │  (0.3s window)    │
└──────────────┘                  └────────┬─────────┘
       ▲                                   │ window complete
       │                                   ▼
       │ SwitchTo(other)           ┌──────────────────┐
       │ (immediate)               │  PlayerControlled │
       │                           └────────┬─────────┘
       │                                    │ SwitchTo(other)
       │                           ┌────────▼─────────┐
       └─────────────────────────── │  SwitchingOut    │
                                    │  (0.3s window)   │
                                    └──────────────────┘
```

**IsAlive transitions:**

```
Alive ──(CurrentHP reaches 0)──▶ Dead ──(OnRevived(), RevivesUsed < 1)──▶ Alive
                                        ──(RevivesUsed >= 1)──▶ stays Dead (encounter)
```

**HealthState** — derived each frame, drives visual feedback:

| From | To | Trigger |
|------|----|---------|
| `Healthy` | `Injured` | `CurrentHP ≤ MaxHP × 0.5` |
| `Injured` | `Critical` | `CurrentHP ≤ MaxHP × 0.1` |
| `Critical` | `Dead` | `CurrentHP == 0` |
| Any | `Healthy` | Heal brings HP above `MaxHP × 0.5` |
| `Dead` | `Critical` | Revive (HP restored to 25%) |

### Interactions with Other Systems

| System | Direction | What Flows |
|--------|-----------|-----------|
| **Character Data** | Reads on init | MaxHP, MaxMP, SkillSlot references, CharacterClass, IsMainCharacter |
| **Health & Damage** | Writes via methods | Calls `ApplyDamage()`, `ApplyHeal()`, `AbsorbShieldDamage()`, `OnRevived()`, sets `IsAlive` |
| **Skill Execution** | Writes via methods | Calls `ConsumeMP()`, `SetCooldown()`, `ConsumeCharge()`, `SetInvincible()` |
| **Status Effects** | Writes via methods | Calls `AddEffect()`, `RemoveEffect()`, `SetShield()` |
| **CharacterSwitchController** | Writes via methods | Calls `SetPlayerControlled()`, reads `ControlState` |
| **Combat System** | Reads + triggers reset | Reads `IsAlive` for wipe check; calls `ResetForEncounter()` on wave/encounter end |
| **Party AI System** | Reads (observations) | Calls `GetHPRatio()`, `GetMPRatio()`, `GetCooldownRatio()`, `CanUseSkill()`, `HasEffect()`, `GetEffectiveATK()` |
| **Enemy AI System** | Reads (targeting) | Reads `CurrentHP`, `GetEffectiveDEF()`, `IsPlayerControlled` for target selection |
| **Combat HUD** | Reads | Reads `CurrentHP`, `CurrentMP`, `SkillCooldowns[]`, `ActiveEffects`, `ControlState` for display |
| **Save / Load** | Serialized | Full `PartyMemberState` fields serialized per character on save; restored on load |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| **HP ratio** | `CurrentHP / MaxHP` | Range 0.0–1.0; used for HealthState and AI observations |
| **MP ratio** | `CurrentMP / MaxMP` | Range 0.0–1.0; used for AI observations |
| **Cooldown ratio** | `SkillCooldowns[i] / BaseCooldown[i]` | Range 0.0–1.0; 0 = ready, 1 = just used |
| **Effective stat** | `BaseStat × (1 + ΣPct_buffs - ΣPct_debuffs) + ΣFlat_buffs - ΣFlat_debuffs` | Clamped to ≥ BaseStat × 0.1 |
| **MaxHP change — gain** | `CurrentHP += delta` | HP scales up with MaxHP increase |
| **MaxHP change — loss** | `CurrentHP = min(CurrentHP, newMaxHP)` | HP clamped down with MaxHP decrease |
| **Revive HP** | `MaxHP × 0.25` | From Health & Damage GDD |
| **Cooldown tick** | `SkillCooldowns[i] = max(0, SkillCooldowns[i] - deltaTime)` | Each frame, all slots, all characters |
| **Skill available** | `SkillCooldowns[i] == 0 && SkillCharges[i] > 0 && CurrentMP >= MPCost[i]` | Full availability check |

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Character takes damage during `SwitchingIn` window (0.3s) | Damage applies normally — `IsInvincible` is only set if the skill/switch explicitly sets it | State always ticks; switch window is visual only unless invincibility is explicitly set |
| `ApplyDamage()` called on a Dead character | Ignored — `IsAlive == false` guards the method | Dead characters take no further damage |
| `ApplyHeal()` called on a Dead character | Ignored — only `OnRevived()` can restore a dead character | Heal and Revive are different methods |
| Two `AddEffect()` calls with same `EffectId` on same frame | Status Effects System handles stacking rules; `PartyMemberState` stores the result — no special handling needed here | Stacking logic lives in Status Effects, not here |
| `ResetForEncounter()` called mid-combat (wave transition) | Cooldowns → 0, Charges → MaxCharges, RevivesUsed unchanged | Wave reset restores skills but not revive count — the one-revive rule persists across waves |
| `ResetForEncounter()` called at encounter complete | Cooldowns → 0, Charges → MaxCharges, RevivesUsed → 0 | Full reset between encounters |
| Save/load restores `CurrentHP = 0` and `IsAlive = true` | On load, re-evaluate: if CurrentHP == 0, set `IsAlive = false` | Prevents a dead-but-flagged-alive inconsistency from corrupt save data |
| `GetEffectiveStat()` called while `ActiveEffects` is being modified | Effects list must not be modified during iteration — Status Effects System must use a deferred removal queue | Prevents concurrent modification exceptions |
| MaxHP decreases (equipment removed) and `CurrentHP > newMaxHP` | `CurrentHP = min(CurrentHP, newMaxHP)` — HP is clamped immediately | From Health & Damage GDD; enforced here |
| Character is at 0 MP and a skill costs 0 MP | 0-cost skills always pass MP validation — `CurrentMP >= 0` is always true | 0-cost skills (utility, passives) must never be blocked by MP |
| `CanUseSkill()` queried while character is Dead | Returns false for all slots | Dead characters cannot act |
| SkillCooldowns tick on dead characters | Cooldowns continue ticking even when dead | Prevents a revived character from having 0 cooldown on skills that were already cooling before death |

## Dependencies

| System | Direction | Nature | What Flows |
|--------|-----------|--------|-----------|
| **Character Data** | Reads | Hard | MaxHP, MaxMP, SkillSlot references — cannot initialize without it |
| **Health & Damage** | Written by | Hard | HP/MP mutations; IsAlive transitions; revive |
| **Skill Execution** | Written by | Hard | Cooldown, charge, MP mutations; invincibility flag |
| **Status Effects** | Written by | Hard | ActiveEffects list; ShieldValue; effective stat modifiers |
| **CharacterSwitchController** | Written by | Hard | ControlState and IsPlayerControlled — exclusive authority |
| **Combat System** | Reads / triggers | Hard | Reads IsAlive for wipe check; sends ResetForEncounter() signal |
| **Party AI System** | Reads | Hard | Observation queries (HP ratio, MP ratio, cooldown ratio, skill availability) |
| **Enemy AI System** | Reads | Soft | Target selection queries (HP, DEF, IsPlayerControlled) |
| **Combat HUD** | Reads | Hard | All display fields |
| **Save / Load** | Serializes | Hard | All mutable fields serialized per character |

**Bidirectional notes:**
- Health & Damage GDD lists Character State Manager as "depended on by" — consistent ✓
- Status Effects GDD lists Character State Manager as "read by" — consistent ✓
- Skill Execution GDD lists Character State Manager as "read by" — consistent ✓
- Party AI (ADR-0001) defines `IPartyAgent` reads from `PartyMemberState` — consistent ✓

## Tuning Knobs

This system is primarily infrastructure — most tuning lives in the systems that write to it. However, three knobs are owned here:

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `SwitchWindowDuration` | float (seconds) | `0.3` | 0.1–0.5 | Switch feels sluggish; defensive switching is too slow | Input bleed occurs; no visual feedback on switch |
| `MaxRevivesPerEncounter` | int | `1` | 0–2 | Characters can be revived freely; death has no consequence | No revives possible; single death = permanent loss for the encounter |
| `EffectiveStatMinFloor` | float | `0.1` (10%) | 0.05–0.25 | Debuffs barely reduce stats | Stats can be reduced to near-zero; combat feels unfair |

**Note**: `SwitchWindowDuration` is defined in ADR-0002 as the `_switchWindowDuration` field on `CharacterSwitchController`, pinned to 0.3s. It is listed here as the canonical design reference. The ADR value takes implementation precedence.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **HealthState → Injured** | Minor damage visual on character model (scuffed clothing, slight limp) | No audio | Medium |
| **HealthState → Critical** | Urgent damage visual (kneeling pose, heavy breathing); red vignette pulses on screen edges (active character only) | Heartbeat-like pulse sound (active character only) | High |
| **HealthState → Dead** | Death animation plays; character removed from active party visually | Death sound per character | Critical |
| **Revived** | Revive VFX from Healer skill; character returns with glowing outline briefly | Resurrection chime | High |
| **Character switches in (SwitchingIn)** | Switch highlight FX on arriving character (0.3s) | Switch activation sound | High |
| **IsInvincible = true** | Brief flashing outline or glow on character | No dedicated sound | Low |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| `CurrentHP / MaxHP` | Combat HUD party strip (HP bar per character) | Every frame | Always during combat |
| `CurrentMP / MaxMP` | Combat HUD party strip (MP bar per character) | Every frame | Always during combat |
| `SkillCooldowns[]` | Skill bar (active character only) | Every frame | Cooldown overlay on skill icons |
| `SkillCharges[]` | Skill bar charge badge | On change | "×N" on skill icons when MaxCharges > 1 |
| `ActiveEffects` | Status icon row below HP/MP bar | On apply/remove | Shows effect icons with duration timers |
| `ShieldValue` | Shield bar above HP bar | Every frame | Visible only when ShieldValue > 0 |
| `ControlState` | Player marker on active character portrait | On switch | Highlight on active character's HUD slot |
| `RevivesUsedThisEncounter` | Revive indicator per character | On revive | Shows when a character has been revived (prevents player trying to revive twice) |

## Acceptance Criteria

- [ ] Every party member has exactly one `PartyMemberState` component; no two characters share an instance — verified by Editor validator
- [ ] `CurrentHP` initializes to `CharacterData.MaxHP` and `CurrentMP` to `CharacterData.MaxMP` on scene load — verified by unit test
- [ ] `SkillCooldowns[i]` ticks down each frame for all 4 party members simultaneously, regardless of which character the player controls — verified by unit test
- [ ] `SkillCooldowns[i]` continues ticking on a dead character — verified by unit test
- [ ] `ApplyDamage()` on a dead character is a no-op — verified by unit test
- [ ] `ApplyHeal()` on a dead character is a no-op — verified by unit test
- [ ] `OnRevived()` sets `CurrentHP = MaxHP × 0.25`, `IsAlive = true`, increments `RevivesUsedThisEncounter` — verified by unit test
- [ ] Second call to `OnRevived()` on a character with `RevivesUsedThisEncounter >= MaxRevivesPerEncounter` is rejected — verified by unit test
- [ ] `GetEffectiveStat()` correctly applies percentage buffs, percentage debuffs, and flat modifiers, clamped to 10% floor — verified by unit test for ATK, DEF, SPD, CRIT
- [ ] `ControlState` transitions correctly through all states on switch: `AIControlled → SwitchingIn → PlayerControlled → SwitchingOut → AIControlled` — verified by integration test
- [ ] `ResetForEncounter()` sets all cooldowns to 0, charges to MaxCharges, preserves `RevivesUsedThisEncounter` (wave reset) OR resets it to 0 (encounter complete reset) — verified by unit test
- [ ] Save/Load: serialized `PartyMemberState` restores exact HP, MP, cooldowns, charges, active effects, and RevivesUsed on reload — verified by integration test
- [ ] Performance: 4 characters ticking simultaneously (cooldowns + effects) costs < 0.2ms per frame — verified by profiler
- [ ] No unauthorized writes to any state field (private setters enforced, public only via defined methods) — verified by code review

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| Should `ResetForEncounter()` have two variants (wave reset vs. full reset), or use a parameter flag? | Lead Programmer | Resolve during implementation — both behaviors needed, method signature TBD |
| Should `PartyMemberState` expose an event/delegate (`OnHealthStateChanged`, `OnDeath`) for HUD and Audio to subscribe to, rather than polling each frame? | Lead Programmer | Resolve during HUD implementation — event-driven is cleaner but adds coupling; polling is simpler |
| Should MP regenerate passively over time (e.g., +2 MP/sec), or only from skills? | Game Designer | Resolve during Skill Database review — passive regen changes how MP-intensive builds feel |
| Should `SkillCharges` be restored on wave transition (same as cooldowns), or only on full encounter reset? | Systems Designer | Resolve during Combat System playtesting — charges on wave reset may make multi-wave encounters too easy |
