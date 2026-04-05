# Sprint 2 — 2026-04-21 to 2026-05-02

## Sprint Goal

Implement all Core and Gameplay layer systems (Audio, Save/Load, Health & Damage, Hit Detection, Status Effects, Skill Execution, Scene Management, Character State Manager) so that Sprint 3 can wire them into the first playable build.

## Capacity

- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work and bug fixes
- Available: 8 days

## Agent Assignment

> Two agents work in parallel. Agent A owns programmer/gameplay systems. Agent B owns foundation infrastructure and game-systems logic.

### Agent A — Programmer
`S2-01` Health & Damage → `S2-02` Hit Detection → `S2-04` Skill Execution → `S2-03` Scene Management
Tests: `S2-10`, `S2-12`
*Estimated wall-clock: ~4.0 days*

### Agent B — Systems & Infrastructure
`S2-05` Save/Load → `S2-03` Scene Management (depends on S2-05)
`S2-06` Audio System (Mixer + Manager) → `S2-07` Audio Pool + MusicPlayer
`S2-01` → `S2-08` Status Effects → `S2-09` Character State Manager
Tests: `S2-11`, `S2-13`, `S2-14`
*Estimated wall-clock: ~4.0 days*

> Note: S2-03 (Scene Management) depends on both Agent A (Health & Damage done) and Agent B (Save/Load done). Assign to whichever agent finishes their preceding tasks first.

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S2-01 | **Health & Damage System** — `HealthComponent` MonoBehaviour: tracks CurrentHP, MaxHP, CurrentMP, MaxMP. `DamageData` struct: RawDamage (float), DamageType enum (Physical/Magical/True), SourceCharacter (CharacterDataSO ref). Methods: `TakeDamage(DamageData)` with formula `FinalDamage = (ATK × SkillScalar) - (DEF × 0.5)` min 1, `Heal(float)`, `RestoreMP(float)`, `Kill()`. Events: `OnDeath` (UnityEvent), `OnHealthChanged(float, float)`, `OnMPChanged(float, float)`. HP/MP clamped 0–Max. | Agent A | 1.0 | S1-01 (CharacterDataSO) | Compiles; ATK=100, Scalar=1.0, DEF=50 → FinalDamage=75; ATK=10, DEF=100 → FinalDamage=1 (min clamp); HP=0 fires `OnDeath`; `Heal(50)` clamps to MaxHP |
| S2-02 | **Hit Detection System** — Hitbox/Hurtbox pattern. `HitboxComponent` (attacker): shape enum (Sphere/Box/Capsule), active frame window, `DamageData` payload, `OnHit` event, layer mask. `HurtboxComponent` (defender): receives hits, filters own-team via layer, calls `HealthComponent.TakeDamage()`. Layer matrix: PlayerHitbox↔EnemyHurtbox, EnemyHitbox↔PlayerHurtbox, ProjectileHitbox↔both. Uses `Physics.OverlapSphere`/`OverlapBox` — no trigger polling. Prevents duplicate hits per activation (HashSet). | Agent A | 1.0 | S2-01 | Both components compile; hitbox only deals damage during active window; same target not hit twice per swing; layer filtering prevents friendly fire; `OnHit` fires on valid target; `HurtboxComponent` correctly calls `TakeDamage()` |
| S2-03 | **Scene Management System** — `SceneLoader` with async loading via `SceneManager.LoadSceneAsync()`. Provides `LoadScene(string, LoadSceneMode)`, `LoadSceneWithTransition(string, float fadeDuration)`. Loading screen with progress callback (`Action<float>`). Fires AudioManager crossfade event on scene change via SO event channel — no direct AudioManager reference. Triggers auto-save on scene transition if `SaveManager.HasSave()`. | Agent A/B | 0.5 | S2-05 (SaveManager), S2-06 (Audio event channel) | Compiles; `LoadScene()` loads asynchronously; progress callback fires 0.0–1.0; transition triggers fade-out/in; audio crossfade event fires on scene change; auto-save triggered on transition; no direct coupling to AudioManager |
| S2-04 | **Skill Execution System** — `SkillExecutor` MonoBehaviour. Per-skill cooldown tracking (Dictionary skill ID → float remaining). Validates MP cost before cast. On cast: deducts MP, triggers `Animator.SetTrigger(skill.AnimationTrigger)`, activates hitbox with skill's DamageData, applies status effects via `StatusEffectManager`. Cooldown formula: `RemainingCD = BaseCooldown × (1 - CDReduction)`. Events: `OnSkillCast(SkillSO)`, `OnSkillHit(SkillSO, target)`, `OnSkillCooldownComplete(SkillSO)`. Blocks re-cast while on cooldown. | Agent A | 1.0 | S1-05 (SkillSO), S2-01, S2-02, S2-08 | Compiles; insufficient MP fails cast silently; MP deducted and cooldown started on cast; re-cast blocked during cooldown; `Animator.SetTrigger` called with correct string; hitbox activated; status effects from skill applied to targets; `OnSkillCast` fires on successful cast |
| S2-05 | **Save/Load System** — `SaveManager` using JsonUtility. 1 save slot. `SaveData` struct: chapter progress flags (int), per-character HP/MP (float arrays), equipped item IDs (string arrays), inventory item IDs (string list), current scene name. Methods: `Save()`, `Load() → SaveData`, `DeleteSave()`, `HasSave() → bool`. Persists to `Application.persistentDataPath`. No singleton — SO channel or DI. | Agent B | 1.0 | None | Compiles; `Save()` writes JSON to persistent path; `Load()` returns populated SaveData; `HasSave()` correct after save and after `DeleteSave()`; no singleton; JSON is human-readable |
| S2-06 | **Audio System — Mixer + AudioManager** — Create Unity Audio Mixer (`GameAudioMixer`) with 4 groups: Music (default 0.8), SFX (1.0), UI (0.6), Ambience (0.5). Expose parameters: MasterVol, MusicVol, SFXVol, UIVol, AmbVol. `AudioManager` using SO channel or DI (no singleton). `SetVolume(group, float 0–1)` converting to dB via `20 × log10(value)`. SO event channel for crossfade trigger (used by SceneLoader). | Agent B | 0.5 | None | Mixer asset exists with 4 groups + 5 exposed parameters; `SetVolume("Music", 0.5f)` sets MusicVol ≈ −6 dB; event channel fires correctly; no singleton |
| S2-07 | **Audio Pool + MusicPlayer + SFXPlayer** — `AudioPoolManager`: 32 pooled AudioSources (4 Music, 20 SFX, 4 UI, 4 Ambience). `MusicPlayer`: crossfade (1.5s default, configurable), `Play(clip)`, `Stop()`. `SFXPlayer`: `PlayOneShot(clip, mixerGroup, priority)`, priority-based culling when pool exhausted (lowest-priority stopped). No runtime AudioSource instantiation. | Agent B | 1.0 | S2-06 | Pool creates 32 AudioSources on init; `MusicPlayer.Play(clip)` crossfades from current track over 1.5s; `SFXPlayer.PlayOneShot()` plays from pool; pool exhaustion drops lowest-priority sound; no `new AudioSource()` at runtime |
| S2-08 | **Status Effects System** — `StatusEffectSO`: EffectID, DisplayName, EffectType enum (Buff/Debuff/DoT/Control), stat modifier (StatType enum + flat + percent), duration, tick interval (0 = no tick), max stacks, stacking rule enum (Replace/Refresh/Stack), icon Sprite ref. `StatusEffectManager` component: `ApplyEffect(StatusEffectSO, caster)`, `RemoveEffect(string)`, `RemoveAllEffects()`, `HasEffect(string) → bool`, `TickEffects()` in Update. Events: `OnEffectApplied`, `OnEffectRemoved`, `OnEffectExpired`. | Agent B | 1.0 | S2-01 (DoT applies damage), S1-01 (stat modifiers) | Both SOs compile; 5s Buff applies stat increase then auto-removes at expiry; DoT ticks each `tick interval` seconds; Replace rule removes old instance; Stack rule increments stacks to max; `OnEffectExpired` fires on duration end; `RemoveEffect` clears immediately |
| S2-09 | **Character State Manager** — `CharacterStateSnapshot` struct: HP, MP, active effects (list of EffectID + remaining duration + stacks), per-skill cooldown remainders (Dictionary skill ID → float), is-alive (bool). `CharacterStateManager` component: `CaptureSnapshot()` reads from HealthComponent + StatusEffectManager + SkillExecutor; `RestoreFromSnapshot(snapshot)` reapplies all values with correct remaining durations and cooldown timers. Enables lossless character switching. | Agent B | 0.5 | S2-01, S2-08, S2-04 | Compiles; `CaptureSnapshot()` returns correct HP/MP; status effect restored with correct remaining duration; cooldown timers survive capture/restore cycle; is-alive flag reflects HP > 0 |

### Should Have

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S2-10 | **Unit tests — Health & Damage** — Verify damage formula (ATK=100, DEF=50, Scalar=1.0 → 75); min damage clamp to 1; `Kill()` fires `OnDeath`; `Heal()` clamps to MaxHP; `TakeDamage` on dead = no-op; True damage bypasses DEF. | Agent A | 0.25 | S2-01 | All tests pass; ≥6 test methods |
| S2-11 | **Unit tests — Status Effects** — Verify DoT ticks at correct interval; max stacks not exceeded; expiry removes effect and fires event; Replace rule replaces previous instance; Refresh rule resets duration. | Agent B | 0.25 | S2-08 | All tests pass; ≥5 test methods; all 3 stacking rules verified |
| S2-12 | **Unit tests — Skill Execution** — Verify cast blocked when MP < MPCost; cooldown decrements per frame; re-cast blocked during cooldown; `OnSkillCooldownComplete` fires at 0; CDReduction formula correct (20% reduction on 10s → 8s). | Agent A | 0.25 | S2-04 | All tests pass; ≥5 test methods; cooldown math verified with edge cases |

### Nice to Have

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S2-13 | **Unit tests — Save/Load roundtrip** — `Save()` → `Load()` preserves all SaveData fields; `HasSave()` correct; `DeleteSave()` removes file; Load with no file returns default gracefully. | Agent B | 0.25 | S2-05 | All tests pass; ≥4 test methods; no exceptions on missing file |
| S2-14 | **Character State Manager roundtrip test** — Apply damage + status effect + start cooldown, capture snapshot, clear all state, restore, verify all values match. | Agent B | 0.25 | S2-09 | Test passes; snapshot roundtrip is lossless for HP, MP, effects, cooldowns, alive flag |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| None expected | Sprint 1 scope fits within capacity | N/A |

## Critical Path

```
Agent A track (~4.0d):
  S2-01 (Health & Damage, 1.0d — start Day 1)
    → S2-02 (Hit Detection, 1.0d)
      → S2-04 (Skill Execution, 1.0d — needs S2-01, S2-02, S2-08)
  S2-03 (Scene Management, 0.5d — after S2-05 and S2-06 done)

Agent B track (~4.0d):
  S2-05 (Save/Load, 1.0d — start Day 1)
  S2-06 (Audio Mixer + Manager, 0.5d — start Day 1, parallel with S2-05)
    → S2-07 (Audio Pool + MusicPlayer, 1.0d)
  S2-01 delivered by Agent A
    → S2-08 (Status Effects, 1.0d — can start after S2-01)
      → S2-09 (Character State Manager, 0.5d — needs S2-01, S2-08, S2-04)

Convergence point: S2-04 (Skill Execution) needs S2-08 — Agent B's
Status Effects must be done before Agent A can complete Skill Execution.
Coordinate: Agent A finishes S2-02 by ~Day 3, then waits for S2-08.
```

**Recommended execution by day:**

| Day | Agent A | Agent B |
|-----|---------|---------|
| 1 | S2-01 Health & Damage | S2-05 Save/Load + S2-06 Audio Mixer |
| 2 | S2-01 (finish) + S2-02 Hit Detection | S2-05 (finish) + S2-07 Audio Pool |
| 3 | S2-02 (finish) | S2-07 (finish) + S2-08 Status Effects |
| 4 | S2-03 Scene Management | S2-08 (finish) |
| 5 | S2-04 Skill Execution | S2-09 Character State Manager |
| 6 | S2-04 (finish) + S2-10 tests | S2-09 (finish) + S2-11 tests |
| 7 | S2-12 tests | S2-13 + S2-14 tests |
| 8 | Buffer | Buffer |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| S2-04 (Skill Execution) blocked until both S2-02 and S2-08 are done — cross-agent dependency | High | Medium — Agent A idles if Agent B's Status Effects is late | Agent A starts S2-03 Scene Management while waiting; both tracks must finish by Day 4 |
| Unity Physics layer matrix is manual in Editor — hit detection silently fails if misconfigured | High | Medium | Document required layer setup in a checklist before writing Hit Detection code |
| Status effect stacking edge cases cause stat corruption | Medium | High | Test all 3 stacking rules explicitly in S2-11; keep stacking logic simple for now |
| Damage formula feel (too spongey or lethal) unknown until Sprint 3 playtesting | Medium | Low | All values in ScriptableObjects; formula documented — easy to retune in Sprint 3 |
| Character State Manager misses mid-tick status effects on capture | Medium | Medium | S2-14 roundtrip test covers this; test with active DoTs and partial cooldowns |

## Dependencies on External Factors

- Sprint 1 complete: CharacterDataSO (S1-01), SkillDatabaseSO (S1-05), Input System (S1-03/04) are dependencies
- Unity Physics layer configuration must be set manually in Project Settings before S2-02
- Animator controllers with trigger parameters must exist (placeholder/empty) for S2-04 animation triggers
- No external art or audio clip assets needed — SFX integration deferred to Sprint 3

## Sprint Status

> **COMPLETED AHEAD OF SCHEDULE** — All Must Have implementation tasks finished before
> sprint start date (2026-04-21). S2-10 (HealthDamage tests) written; S2-11 through S2-14
> (Status Effects, Skill Execution, Save/Load, CharStateManager tests) not written — deferred
> as tech debt.

## Definition of Done for this Sprint

- [x] All Must Have tasks (S2-01 through S2-09) completed and verified
- [x] S2-10 Health & Damage tests — PASS (`Assets/Tests/Editor/HealthDamageSystemTests.cs`)
- [ ] S2-11 Status Effects tests — NOT WRITTEN (tech debt)
- [ ] S2-12 Skill Execution tests — NOT WRITTEN (tech debt)
- [ ] S2-13 Save/Load roundtrip tests — NOT WRITTEN (tech debt)
- [ ] S2-14 Character State Manager roundtrip test — NOT WRITTEN (tech debt)
- [x] Audio Mixer exists with 4 groups; MusicPlayer, SFXPlayer, AudioPool implemented
- [x] No forbidden patterns; all gameplay values in ScriptableObjects; public APIs have XML docs
- [x] Code committed to main with references to design docs
- [x] Sprint 3 dependencies unblocked: all Core + Gameplay + Audio systems ready for first playable
