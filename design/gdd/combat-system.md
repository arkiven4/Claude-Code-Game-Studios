# Combat System

> **Status**: Approved
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (combat is the expression of party composition and switching)

## Overview

The Combat System is the encounter orchestrator for My Vampire — it defines when combat begins, when it ends, what constitutes "in combat," and how all combat subsystems (Health & Damage, Hit Detection, Skill Execution, Enemy AI, Status Effects, Camera) bind together into a coherent, playable encounter. It manages the encounter lifecycle (start → active → wave transitions → complete), tracks combat state flags (`IsInCombat`, `CurrentWave`, `EnemiesRemaining`), and provides the authoritative source of truth for whether the player is in a fight. The system does not calculate damage, acquire targets, or control enemy behavior — those are delegated to specialized subsystems. Instead, the Combat System is the conductor: it signals when the music starts, when it changes tempo, and when it ends. For story encounters, combat can have scripted waves (adds arrive, bosses enter mid-fight). For optional fights, combat is a single arena with all enemies present. The combat feel is **tactical** — positioning, timing, and resource management matter more than execution speed or combo chains. The player wins by choosing the right character for the moment, not by pressing buttons faster.

## Player Fantasy

Combat System serves the fantasy of **winning through smart decisions, not fast fingers**. The player should feel that every encounter is a puzzle with a solution encoded in their party composition and their timing. A well-positioned Tanker absorbs a boss's big attack while the Archer picks off adds from behind. A timely switch to the Healer saves a party member from a DoT stack. The player reads the battlefield — enemy positions, their telegraphs, their party's HP and cooldowns — and makes the call. Combat feels like a chess match where every piece has skills, not a rhythm game where every miss punishes you. The tactical depth is accessible: no combo chains to memorize, no execution windows measured in frames. The challenge is "am I using the right character right now?" — and that question is always answerable, always fair, and always within the player's control.

**Reference model**: Final Fantasy XII's gambit system (positioning and automation matter), Fire Emblem's tactical positioning (where you stand matters), but played in real-time ARPG rather than turn-based grid combat.

## Detailed Rules

### Core Rules

1. **Encounter Lifecycle**: Every combat encounter goes through four phases:
   - **Pre-Combat**: Player is in the encounter area but combat has not started. Enemies may be visible (optional fights) or hidden (story encounters). Player can prepare (buff, position) before triggering.
   - **Active**: Combat has started. `IsInCombat = true`. Enemies are alive and acting. Player skills, enemy AI, and all combat subsystems are fully operational.
   - **Wave Transition** (optional): All enemies in the current wave are defeated, but more enemies are scripted to spawn. `IsInCombat` remains true. Party gets a brief recovery window (5s) — cooldowns reset, but no healing occurs. Next wave spawn.
   - **Complete**: All enemies in all waves are defeated. `IsInCombat = false`. Loot drops. Encounter rewards are distributed. Combat music fades out. Player regains full exploration control.

2. **Encounter Trigger**: How combat starts depends on encounter type:
   - **Story encounters**: Triggered by a narrative event (cutscene ends, player reaches a story beat, dialogue completes). The encounter area is defined by the scene designer — boundaries are marked with invisible walls. All enemies for wave 1 spawn immediately or on script.
   - **Optional encounters**: Triggered by player entering an aggro radius around an enemy or enemy group. The player can avoid the fight by not entering the radius. Once triggered, the encounter is a single arena (no waves).

3. **Encounter End Conditions**: Combat ends when:
   - **Victory**: All enemies in all waves are dead. Triggers loot drops, encounter complete event, and exploration resume.
   - **Party Wipe**: All 4 party members are dead. Triggers Game Over (handled by Health & Damage System).
   - **Story Override**: A narrative event forces combat to end (e.g., a boss retreats, a cutscene interrupts). This is rare and only used for story encounters.

4. **No Fleeing**: Once combat starts, the player cannot leave. Story encounters have locked boundaries (invisible walls or arena geometry). Optional fights, once triggered, must be completed. There is no "run past enemies" or "disengage" mechanic.

5. **Skill Combo Windows**: When a character uses Skill A, a combo window opens for 1.5 seconds. If the player (or Party AI) uses Skill B within that window, the combo triggers a bonus effect:
   - **Combo Definition**: Stored as pairs in a `CombatCombo` Resource:
     | Field | Type | Description |
     |-------|------|-------------|
     | `SkillA` | SkillData reference | First skill in the combo |
     | `SkillB` | SkillData reference | Second skill in the combo |
     | `BonusEffect` | enum | `ExtraDamage`, `ApplyStatus`, `ExtendDuration`, `HealBonus` |
     | `BonusValue` | float | Magnitude of the bonus (damage multiplier, status duration, heal amount) |
     | `ComboDescription` | string | Tooltip shown when combo is possible (e.g., "Fire → Dark: +50% burn damage") |
   - **Combo Execution**: The Combat System tracks the last skill used per character. If a matching combo pair is found within the window, the bonus effect is applied via the appropriate subsystem (Health & Damage for extra damage, Status Effects for status application, etc.).
   - **Combo Window Duration**: 1.5 seconds by default, tunable per combo. Not extendable — if the window expires, the combo is lost.
   - **Combo Feedback**: When a combo window opens, the Combat HUD shows a small indicator next to the skill bar ("→ [SkillB icon]"). When the combo executes, a "COMBO!" text flashes with the bonus effect shown.
   - **Combo Discovery**: Combos are not shown in a list — the player discovers them through experimentation or NPC hints. This encourages exploration of the skill space.

6. **Threat System** (configurable per enemy):
   - **ThreatMeter Mode** (default for normal/grunt enemies): Each character has a threat value. Threat is generated by:
     - Dealing damage: `threat += damageDealt × 1.0`
     - Taking damage: `threat += damageReceived × 0.5`
     - Taunt skill: `threat += 500` (instant spike, lasts 8s)
     - Threat decays over time: `threat *= 0.95` each second
     - Enemies target the character with the highest threat value.
   - **AITargeting Mode** (for smart enemies like assassins): Enemies ignore threat and use their behavior profile targeting (Enemy AI System decides — lowest HP, lowest DEF, healer priority, etc.).
   - **Boss Mode** (configured per boss in EnemyData): Each boss specifies which threat mode it uses. A boss can use ThreatMeter for phase 1 and switch to AITargeting in phase 2, or alternate based on phase conditions.
   - **Tanker Identity**: Tankers naturally generate more threat through their skills (taunt, damage absorption, high DEF). They don't need a separate "threat generation" stat — their toolkit creates threat through gameplay.

7. **Encounter Boundaries**: Each encounter has a defined arena:
   - **Story encounters**: Arena boundaries are invisible walls defined by the level designer. The player cannot leave the arena until combat ends.
   - **Optional encounters**: The encounter area is the aggro radius + 10 units. If the player somehow leaves this area (e.g., a knockback), they are pulled back to the nearest valid position.
   - **Knockback within bounds**: Skills that knock back characters or enemies cannot push them outside the arena bounds. Positions are clamped to the arena bounding box.

8. **Wave Spawning** (for story encounters):
   - Each wave has a `WaveConfig`: enemy list, spawn positions, spawn delay, and optional wave-start cutscene.
   - Between waves: 5-second recovery window. Party cooldowns reset. No HP/MP restoration. The camera may pan to show incoming enemies.
   - Wave transitions are announced: "Wave 2" text appears for 2s.
   - Maximum waves per encounter: 5 (designer-defined).

9. **Combat Pacing**: The system enforces a rhythm to prevent combat fatigue:
   - **Minimum encounter duration**: 30 seconds (even trivial fights take this long due to enemy HP pools and animations).
   - **Maximum encounter duration**: 5 minutes (if an encounter drags this long, the system logs a warning for designers — enemies may be undertuned or player overgeared).
   - **Encounter spacing**: Story encounters are spaced by at least 2 minutes of exploration/narrative content between them.

10. **Combat Music**: When `IsInCombat` becomes true, the Audio System crossfades to combat music. When combat ends, music crossfades back to exploration track. Wave transitions may play a sting. (Handled by Audio System, triggered by Combat System events.)

11. **Encounter Lock**: While `IsInCombat = true`:
    - Save/Load is blocked (cannot save during combat)
    - Party composition changes are blocked (cannot swap party members mid-fight)
    - Equipment changes are blocked
    - The pause menu is still accessible (for settings, but not for inventory or party management)

12. **Post-Combat Recovery**: When combat ends:
    - All party skill cooldowns reset (Skill Execution System encounter reset)
    - 3-second "victory pause" — music fades, camera pulls back, player can reorient
    - Loot drops are displayed
    - The player regains full exploration control

### States and Transitions

The Combat System tracks the state of the entire encounter through a `CombatEncounterState` enum and a per-encounter state machine:

```
┌──────────────┐  trigger: encounter event   ┌──────────────┐
│  INACTIVE    │ ──────────────────────────▶ │  PRE_COMBAT   │
│ (exploring)  │                              │ (preparing)   │
└──────────────┘                              └──────┬───────┘
                                                     │ trigger: combat starts
                                                     ▼
                                              ┌──────────────┐
                              wave cleared   │              │ all enemies dead
                   ┌─────────────────────────▶│    ACTIVE     │──────────────┐
                   │                          │  (fighting)   │              ▼
                   │                          └──────┬───────┘       ┌───────────┐
                   │       more waves                │                │ COMPLETE   │
                   │       remain           ┌────────┴────────┐      │ (victory)  │
                   │                        │ WAVE_TRANSITION  │      └───────────┘
                   │                        │  (5s recovery)   │
                   │                        └────────┬────────┘
                   │                                 │ wave spawns
                   └─────────────────────────────────┘
```

**State Definitions**:

| State | `IsInCombat` | Player Can... | Description |
|-------|-------------|---------------|-------------|
| `INACTIVE` | `false` | Explore, save, manage party | Normal exploration. No encounter active. |
| `PRE_COMBAT` | `false` | Explore, prepare, buff | Player is in the encounter area but hasn't triggered combat. Optional prep window. |
| `ACTIVE` | `true` | Fight, switch characters, use skills | Combat is ongoing. Enemies are alive and acting. Encounter lock applies. |
| `WAVE_TRANSITION` | `true` | View incoming wave, cannot move | Brief pause between waves. Cooldowns reset. Next wave about to spawn. |
| `COMPLETE` | `false` | View loot, reorient | Encounter ended in victory. 3-second recovery pause before exploration resumes. |

**Additional Encounter State** (tracked alongside the state machine):

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `CurrentWave` | int | `0` | Current wave index (0 = first wave, -1 = no waves) |
| `TotalWaves` | int | `1` | Total waves in this encounter (1 = single arena) |
| `EnemiesRemaining` | int | varies | Number of living enemies in current wave |
| `EncounterId` | string | — | Unique identifier for this encounter (for save/load and narrative tracking) |
| `EncounterType` | enum | — | `Story` or `Optional` — determines trigger behavior and wave support |
| `ArenaBounds` | Bounds | — | Bounding box defining the encounter area |
| `ComboWindow` | struct | null | Global combo window for the encounter: `{SkillA, SkillB, RemainingTime}`. One window at a time — transferable across character switches. Null when no window is open. |
| `ThreatValues[]` | dict | empty | Per-character threat value (CharacterId → threat float) |
| `EncounterTimer` | float | `0` | Time since combat started (Active state entry) |

**State Transition Triggers**:

| From State | Trigger | To State | Side Effects |
|------------|---------|----------|--------------|
| `INACTIVE` | Player enters aggro radius | `PRE_COMBAT` | Camera shifts to encounter preview, enemies become visible |
| `INACTIVE` | Story event (cutscene ends) | `PRE_COMBAT` | Cutscene System hands off to Combat System |
| `PRE_COMBAT` | Player attacks enemy or timer expires | `ACTIVE` | `IsInCombat = true`, combat music starts, all enemies activate |
| `PRE_COMBAT` | Player leaves aggro radius | `INACTIVE` | Encounter resets, enemies return to idle |
| `ACTIVE` | Last enemy in wave dies, more waves remain | `WAVE_TRANSITION` | Cooldowns reset, 5s timer starts, camera shows incoming wave |
| `WAVE_TRANSITION` | 5s timer expires | `ACTIVE` | Next wave spawns, `CurrentWave++`, EnemiesRemaining updated |
| `ACTIVE` | Last enemy in last wave dies | `COMPLETE` | Loot drops, music fades, 3s victory pause starts |
| `COMPLETE` | 3s timer expires | `INACTIVE` | Encounter fully ends, exploration resumes |
| `ACTIVE` | All party members dead | `GAME_OVER` (terminal) | Game Over overlay triggers (Health & Damage System handles the UI); distinct from INACTIVE — player is not in exploration |
| `ACTIVE` | Story override (boss retreats) | `COMPLETE` | Narrative event forces combat end; partial loot may be awarded |
| Any state | Player loads a save | Restored state | Encounter state is serialized; resumes from saved state |

### Interactions with Other Systems

| System | Direction | Nature | Details |
|--------|-----------|--------|---------|
| **Health & Damage System** | Read by | Hard | Reads `IsInCombat` for death/Game Over flow; Combat System is notified when party wipe occurs |
| **Hit Detection System** | Read by | Soft | Hit Detection triggers Combat System events on first hit of an encounter (for optional encounter auto-start) |
| **Skill Execution System** | Calls | Hard | Combat System triggers encounter-wide cooldown reset on encounter end; tracks last-skill-used per character for combo windows |
| **Enemy AI System** | Calls | Hard | Combat System signals encounter start (enemies activate) and encounter end (enemies reset); Enemy AI reports enemy deaths to update EnemiesRemaining |
| **Status Effects System** | Read by | Soft | Status Effects reads encounter state to determine if certain effects should expire on encounter end |
| **Camera System** | Calls | Hard | Combat System signals mode transitions (Exploration ↔ Combat ↔ Cinematic); Camera reads `IsInCombat` for mode selection |
| **Audio System** | Calls | Hard | Combat System triggers combat music start/end, wave transition stings, victory fanfare |
| **Loot & Drop System** | Calls | Hard | Combat System triggers loot drops on encounter complete (victory) |
| **Character Switching System** | Read by | Hard | Character Switching reads `IsInCombat` for encounter lock (party composition changes blocked during combat) |
| **Party AI System** | Read by | Soft | Party AI reads `IsInCombat`, CurrentWave, EnemiesRemaining, and ThreatValues to optimize decisions |
| **Combat HUD** | Read by | Hard | Combat HUD displays IsInCombat indicator, wave counter, enemies remaining, combo window indicators, threat indicators |
| **Chapter State System** | Calls | Soft | Combat System notifies Chapter State when story encounters complete (for story flag tracking) |
| **Save / Load System** | Serialized | Hard | Encounter state (CurrentWave, EncounterTimer, ThreatValues, ComboWindows) serialized per encounter |
| **Scene Management System** | Read by | Soft | Scene Manager uses encounter data to position enemies and set up encounter triggers on scene load |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| **Threat on Damage Dealt** | `threat += damageDealt × 1.0` | Applied to the character who dealt the damage |
| **Threat on Damage Taken** | `threat += damageReceived × 0.5` | Applied to the character who took the damage |
| **Threat Decay** | `threat *= 0.95` per second | Applied each second to all characters' threat values |
| **Taunt Threat Spike** | `threat += 500` | Instant addition lasting 8 seconds, then normal decay resumes |
| **Combo Window Timer** | `remainingTime -= deltaTime` | Starts at 1.5s, ticks each frame. At 0, combo is lost. |
| **Combo Bonus Damage** | `bonusDamage = baseDamage × BonusValue` | Where BonusValue is defined in CombatCombo (e.g., 0.5 = +50%) |
| **Encounter Duration** | `EncounterTimer = Σ deltaTime` (while in ACTIVE state) | Used for pacing warnings and analytics |
| **Wave Recovery Window** | `5.0s` fixed | Cooldowns reset, no HP/MP restored |
| **Victory Pause** | `3.0s` fixed | Music fades, camera pulls back, player reorients |
| **Threat Target Selection** | `target = argmax(threatValues)` | Enemy selects character with highest threat value |
| **Pacing Warning** | `if (EncounterTimer > 300s) log("Encounter exceeded 5 minute budget")` | Designer warning, not a gameplay mechanic |
| **Arena Boundary Clamp** | `position = clamp(position, ArenaBounds)` | Applied to characters and enemies on movement |

### Threat Calculation Example

After 10 seconds of combat:

| Character | Damage Dealt | Damage Taken | Taunts Used | Threat Calculation | Final Threat |
|-----------|-------------|--------------|-------------|-------------------|--------------|
| Evelyn (Mage) | 2000 | 300 | 0 | (2000 × 1.0) + (300 × 0.5) = 2150, decayed to ~1288 | **1288** |
| Evan (Swordman) | 1200 | 800 | 0 | (1200 × 1.0) + (800 × 0.5) = 1600, decayed to ~959 | **959** |
| Tanker | 400 | 1500 | 1 | (400 × 1.0) + (1500 × 0.5) + 500 = 1650, decayed to ~989 | **989** |
| Healer | 100 | 200 | 0 | (100 × 1.0) + (200 × 0.5) = 200, decayed to ~120 | **120** |

**Enemies using ThreatMeter mode target: Evelyn** (highest threat at 1288).
**Enemies using AITargeting mode**: Ignore threat, use behavior profile (e.g., target Healer if profile = Defensive).

### Combo Execution Example

Evelyn uses Fire (Skill A) → 1.2s later uses Dark Bolt (Skill B). Combo window is 1.5s.

- Fire deals 200 base damage to Enemy X.
- Combo check: `Fire → Dark Bolt` exists in CombatCombo with BonusEffect = ExtraDamage, BonusValue = 0.5.
- Bonus damage: `200 × 0.5 = 100` bonus damage applied to Enemy X.
- "COMBO! +100" text flashes on screen.
- Total damage: 300 (200 from Fire + 100 from combo bonus).

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player triggers optional encounter, then immediately dies to first hit | Combat proceeds with 3 remaining party members; no auto-revive | 3-member fights are harder but valid; no special protection |
| Combo window is active, then player switches characters | Combo window transfers to the new active character — they can complete the combo with the second skill | Switching should not punish combo opportunity |
| Wave transition starts, but a lingering DoT kills the last enemy of the next wave during the 5s recovery | That enemy stays dead; wave spawns with one fewer enemy; combat continues with remaining enemies | DoT is a valid kill; no enemy resurrection |
| Boss phase transition invincibility (2s) overlaps with a player combo window | Combo window continues ticking during invincibility; if window expires before invincibility ends, combo is lost | Invincibility is absolute; player must time combos around it |
| Two enemies die on the same frame (party-wide skill) | Both deaths are processed; EnemiesRemaining decrements by 2; if this was the last wave, combat transitions to COMPLETE | Simultaneous deaths are valid |
| Player enters aggro radius during a cutscene | Combat does NOT start until the cutscene ends; PRE_COMBAT state is queued but not activated | Cutscenes have priority; combat doesn't interrupt narrative |
| Optional encounter trigger overlaps with story encounter boundary | Story encounter takes priority; optional encounter is disabled in that area | Story encounters are authored and must not be disrupted |
| Threat values overflow (extremely long encounter with massive damage numbers) | Threat values use float (max ~3.4 × 10^38); decay prevents runaway growth; overflow is practically impossible | Edge case is theoretical, not practical |
| All enemies in a wave are immune to all player damage (data authoring error) | Combat timer reaches 5-minute maximum; system logs critical error; designer is notified in debug build | Unwinnable encounters must be caught in testing |
| Player has a 1.5s combo window, but the second skill is on cooldown | Combo window ticks down; if cooldown ends within the window, player can still complete the combo | Cooldown and combo window are independent timers |
| Wave transition: camera pans to show incoming enemies, but one spawns behind the player | Camera shows all spawn points, not just the player-facing direction; player can see threats from all directions | Awareness is fair; surprise spawns from behind feel cheap |
| Combat ends (victory), but a late-arriving enemy spawns after the 3s victory pause | Late spawns are clamped to the wave they belong to; if the wave is already cleared, the spawn is skipped | Combat end is authoritative; no post-combat ambushes |
| Save is loaded mid-combat (from a previous session) | Encounter state is restored: CurrentWave, EnemiesRemaining, ThreatValues, ComboWindows all resume exactly | Save/Load fidelity is critical |
| Player is knockbacked into an arena wall during combat | Position is clamped to arena bounds; knockback stops at the wall; no clipping | Arena bounds are hard limits |
| Story encounter triggers but the required enemies haven't been placed by the level designer | System logs error at scene load; encounter starts with 0 enemies; immediately transitions to COMPLETE with partial loot | Missing data must not crash or soft-lock |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Health & Damage System** | Read by | Hard | Reads `IsInCombat` for death/Game Over flow; reports party wipe events |
| **Hit Detection System** | Read by | Soft | Triggers encounter start on first hit for optional fights |
| **Skill Execution System** | Calls | Hard | Triggers encounter-wide cooldown reset; tracks last-skill-used for combos |
| **Enemy AI System** | Calls | Hard | Signals encounter start/end; receives enemy death reports |
| **Status Effects System** | Read by | Soft | Reads encounter state for effect expiration rules |
| **Camera System** | Calls | Hard | Signals mode transitions (Exploration ↔ Combat ↔ Cinematic) |
| **Audio System** | Calls | Hard | Triggers combat music, wave stings, victory fanfare |
| **Loot & Drop System** | Calls | Hard | Triggers loot drops on encounter complete |
| **Character Switching System** | Read by | Hard | Reads `IsInCombat` for encounter lock enforcement |
| **Party AI System** | Read by | Soft | Provides encounter context for AI decision-making |
| **Combat HUD** | Read by | Hard | Provides encounter state for display (wave, enemies, combos, threat) |
| **Chapter State System** | Calls | Soft | Reports story encounter completion for story flag tracking |
| **Save / Load System** | Serialized | Hard | Encounter state serialized (wave, timer, threat, combo windows) |
| **Scene Management System** | Read by | Soft | Provides encounter data for enemy placement and trigger setup |

**No dependency conflicts.** All interactions are unidirectional except Skill Execution (calls for reset, reads for combo tracking) and Enemy AI (calls for start/end, reads for death reports).

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `ComboWindowDuration` | float (seconds) | `1.5` | 0.8–3.0 | Combos are trivial; players chain everything | Combos feel impossible; player never discovers them |
| `ThreatDecayRate` | float | `0.95` | 0.85–0.99 | Threat drops too fast; enemies switch targets constantly | Threat is nearly permanent; Tanker locks aggro forever |
| `TauntThreatBonus` | float | `500` | 200–1000 | Taunt is overwhelming; enemies never look away | Taunt is negligible; enemies ignore the Tanker |
| `TauntDuration` | float (seconds) | `8.0` | 4.0–15.0 | Taunt lasts too long; Tanker trivializes boss mechanics | Taunt expires too fast; no time to capitalize |
| `WaveRecoveryTime` | float (seconds) | `5.0` | 3.0–10.0 | Recovery is too generous; player heals and resets | No time to process the next wave; feels rushed |
| `VictoryPauseDuration` | float (seconds) | `3.0` | 1.5–5.0 | Victory feels drawn out; player wants to move on | Victory feels abrupt; no satisfaction moment |
| `MaxWavesPerEncounter` | int | `5` | 2–8 | Encounters drag on; player fatigue sets in | Not enough pacing variety in story encounters |
| `MinEncounterDuration` | float (seconds) | `30` | 15–60 | Trivial fights drag; player feels padded | Fights can end instantly; no engagement |
| `MaxEncounterDuration` | float (seconds) | `300` | 180–600 | Warning never triggers; designer never knows about drag | Warning fires too often; false positives |
| `PreCombatAggroRadius` | float | `8.0` | 5.0–15.0 | Encounters trigger from too far; player can't avoid | Encounters trigger too close; player is surprised |
| `EncounterSpacingMin` | float (seconds) | `120` | 60–300 | Narrative pacing has no breathing room | Too much dead time between encounters |

### Interacting Knobs

- **ComboWindowDuration + Skill Cooldowns**: If a skill's cooldown is longer than the combo window, the combo is impossible unless the first skill is used while the second is already off cooldown. Designers must ensure combo pairs have compatible cooldowns.
- **ThreatDecayRate + TauntDuration + TauntThreatBonus**: These three define the Tanker's aggro control envelope. A high threat bonus with fast decay means the Tanker spikes hard but loses aggro quickly. A moderate bonus with slow decay means sustained aggro control. Tune as a system.
- **WaveRecoveryTime + VictoryPauseDuration**: These define the rhythm of multi-wave encounters. 5s recovery + 3s victory = 8s total pause time. If this is too long, encounters feel stop-start. If too short, the player never processes what happened.

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Combat starts** | Screen border briefly flashes red; "Combat" text appears | Combat music crossfades in (1s blend); tension sting | Critical |
| **Wave transition** | "Wave 2" text appears for 2s; camera pans to show incoming wave | Wave sting sound; enemies spawn sound | High |
| **Combo window opens** | Small "→ [SkillB icon]" appears next to skill bar | Subtle "ready" click (only for active character) | Medium |
| **Combo executes** | "COMBO!" text flashes; bonus effect VFX plays | Layered impact sound (base hit + combo chime) | High |
| **Victory** | Camera pulls back; "Victory" text appears; loot drops visible | Combat music fades out; victory fanfare (2s) | Critical |
| **Party wipe** | Screen fades to red; "Game Over" text | Combat music cuts; somber tone | Critical |
| **Threat target switch** | Brief indicator on the character who gained aggro | No sound (visual-only) | Low |
| **Arena boundary hit** | Subtle ripple effect on invisible wall | No sound | Low |
| **Story encounter start** | Cutscene transitions directly into combat | Music transitions from narrative to combat track | Critical |
| **5-minute pacing warning** | Debug overlay shows encounter timer in red | No sound (debug only) | Low |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Combat indicator | Combat HUD (top-center) | Static | "In Combat" icon visible while `IsInCombat = true` |
| Wave counter | Combat HUD (below combat indicator) | On wave transition | "Wave 2/3" shown during multi-wave encounters |
| Enemies remaining | Combat HUD (below wave counter) | Every frame | "3 enemies remaining" counter |
| Combo window indicator | Next to skill bar (active character) | Every frame while window is active | "→ [SkillB icon]" with fading timer ring |
| Combo execution flash | Center screen | On combo trigger | "COMBO! +[bonus]" text, 1s display |
| Threat indicator (debug) | Per-character in debug HUD | Every frame | Shows raw threat value per character |
| Encounter timer (debug) | Debug overlay | Every frame | Shows elapsed combat time |
| Arena boundary (debug) | Wireframe outline in world | Static | Shows encounter area bounds |

## Acceptance Criteria

- [ ] Encounter transitions correctly through all 5 states (INACTIVE → PRE_COMBAT → ACTIVE → WAVE_TRANSITION → COMPLETE)
- [ ] `IsInCombat` flag is `true` only during ACTIVE and WAVE_TRANSITION states
- [ ] Story encounters trigger via narrative events; optional encounters trigger via aggro radius
- [ ] No fleeing: once combat starts, player cannot leave until victory or party wipe
- [ ] Skill combo windows open for 1.5s after each skill use; matching combo within window triggers bonus effect
- [ ] Combo window persists across character switches (new active character can complete the combo)
- [ ] Threat system works in ThreatMeter, AITargeting, and Boss modes per enemy configuration
- [ ] Threat decay of 0.95 per second prevents permanent aggro lock
- [ ] Wave transitions provide 5s recovery (cooldowns reset, no HP/MP restored)
- [ ] Victory pause of 3s plays after last enemy dies before exploration resumes
- [ ] Encounter lock blocks save, party composition changes, and equipment changes during combat
- [ ] Knockback positions are clamped to arena bounds
- [ ] Loading a save mid-combat restores exact encounter state (wave, timer, threat, combos)
- [ ] Audio: combat music crossfades on start/end; wave stings play on transitions
- [ ] Performance: managing 20 simultaneous enemies across 5 waves adds < 2.0ms frame time
- [ ] Pacing warning fires when encounter exceeds 5 minutes

## Open Questions

| Question | Owner | Resolution |
|----------|-------|------------|
| Should combo discovery be aided by an in-game hint system (NPCs reveal combo pairs, or a tutorial prompt)? | Game Designer | Resolve during Chapter 1 encounter design — MVP can have combos without hints |
| Should the threat system have a visual indicator in the HUD for players who want to optimize Tanker play? | UX Designer | Resolve during Combat HUD design — MVP can work without visible threat values |
| Should wave transitions include a narrative beat (dialogue, cutscene) or just a camera pan and spawn? | Narrative Director | Resolve during story encounter authoring per chapter |
| Should there be a "combat tutorial" encounter in the prologue that teaches combos, threat, and switching? | Game Designer | Resolve during Witch prologue design — prologue is MVP |
| Should bosses have unique arena mechanics (moving platforms, environmental hazards, destructible cover)? | Level Designer | Resolve during boss encounter design per chapter |
