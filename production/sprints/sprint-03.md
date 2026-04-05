# Sprint 3 — 2026-05-05 to 2026-05-16

## Sprint Goal

Deliver the **First Playable Build**: a player can move a character, attack enemies in real-time, switch between Evelyn and Evan mid-combat, see an enemy fight back, collect a loot drop, and read HP/cooldowns on the Combat HUD — with audio feedback throughout.

## Capacity

- Total days: 10
- Buffer (20%): 2 days reserved for unplanned work and bug fixes
- Available: 8 days

## Agent Assignment

> Two agents work in parallel. Agent A owns gameplay programming (AI, combat, switching). Agent B owns systems, UI, and audio integration.

### Agent A — Gameplay Programmer
`S3-01` Enemy AI → `S3-02` Combat System → `S3-03` Character Switching → `S3-07` Test Scene (integration)
Tests: `S3-08`, `S3-10`
*Estimated wall-clock: ~5.5 days (critical path)*

### Agent B — Systems, UI & Audio
`S3-04` Loot & Drop (parallel with S3-02)
`S3-05` Inventory & Equipment data layer (independent, Day 1)
`S3-06` Combat HUD (after S3-02 + S3-03 done)
`S3-09` Audio SFX wiring (after S3-02 done)
`S3-10` Audio fade utilities (can start Day 1)
Tests: `S3-11`, `S3-12`
*Estimated wall-clock: ~5.0 days*

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S3-01 | **Enemy AI System** — `EnemyAIController` state machine: Idle, Patrol (random waypoints within radius), Alert (player enters aggro range), Attack (execute random skill when in range), Dead (disable AI, fire `OnEnemyDeath`). `EnemyDataSO`: EnemyID, DisplayName, EnemyClass enum (Grunt/Elite/Boss), stats mirroring CharacterDataSO structure, skill list, aggro range, patrol radius, loot table reference. Create 2 example assets: `GruntMelee` (short range, high ATK, low SPD) and `ArcherRanged` (long range, low ATK, high SPD). | Agent A | 1.5 | S2-01 (HealthComponent), S2-02 (Hit Detection), S1-05 (SkillSO) | Compiles; enemy transitions Idle→Alert on player entering aggro range; executes attack skill in range; `OnEnemyDeath` fires on HP=0; 2 EnemyDataSO assets in `Assets/Data/Enemies/` with all fields populated; Patrol moves within radius |
| S3-02 | **Combat System** — `CombatManager` orchestrates encounters: tracks all active combatants (player party + enemies), routes hit events, manages start/end conditions (all enemies dead = victory, all players dead = game over). `CombatSession` struct: enemy list, victory condition, loot pool ref. Player combat: real-time hack & slash, BasicAttack = Skill1 with 0.3s cooldown. Events: `OnCombatStart`, `OnCombatEnd(bool victory)`, `OnCombatantDeath`. Wires camera to Combat mode on `OnCombatStart`, Exploration on `OnCombatEnd`. | Agent A | 2.0 | S2-01 (Health), S2-02 (HitDetection), S2-04 (SkillExecution), S3-01 (EnemyAI), S1-07 (Camera) | Compiles; `OnCombatStart` fires when player enters aggro range; `OnCombatEnd(true)` fires when last enemy dies; `OnCombatEnd(false)` fires when all players at 0 HP; camera switches correctly; BasicAttack usable with 0.3s cooldown |
| S3-03 | **Character Switching System** — `CharacterSwitchController` per ADR-0002 (distributed state — switching transfers input authority only, each character owns their own state). Switch sequence: (1) disable current InputManager binding, (2) 0.3s switch animation window, (3) enable incoming InputManager binding, (4) camera follows new character. Cooldown: 1.0s between switches. `FlushBuffer()` on switch. Max 2 characters (Evelyn + Evan). Design rule: switching mid-skill cancels current skill cast (SkillExecutor listens to `OnCharacterSwitched`). Events: `OnCharacterSwitched(CharacterDataSO incoming, CharacterDataSO outgoing)`. | Agent A | 1.0 | S2-09 (CharacterStateManager), S3-02 (CombatSystem), S1-04 (InputManager) | Compiles; Tab switches active character; 0.3s window plays; 1.0s cooldown blocks rapid switching; input buffer flushed; camera follows new character; HP/cooldowns do NOT leak between characters; mid-skill switch cancels the skill; `OnCharacterSwitched` event fires with correct SOs |
| S3-04 | **Loot & Drop System** — `LootDropper` on enemies: on `OnEnemyDeath`, rolls loot table using rarity weights (Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1%). Drop count by EnemyClass (Grunt: 1, Elite: 2, Boss: 3). `LootTableSO`: list of `LootEntry` (ItemEquipmentSO ref + weight float). Dropped items spawn as world pickups with `LootPickupComponent` — player walks over to collect → adds to `PartyInventory`. `PartyInventory` class: flat list of collected ItemEquipmentSOs (data layer only, no UI). Create 1 example `LootTableSO` for GruntMelee. | Agent B | 1.0 | S1-08 (ItemDatabaseSO), S3-01 (EnemyAI), S1-08 (ItemRaritySO) | Compiles; enemy drops 1-3 items on death; items appear as world pickups; player collision adds to PartyInventory; LootTableSO asset exists; rarity distribution approximately correct over many rolls; PartyInventory stores flat list |
| S3-05 | **Inventory & Equipment System (Data Layer)** — `EquipmentManager` per character: 5 slots (Weapon, Armor, Helmet, Accessory, Relic). `Equip(ItemEquipmentSO)`: validates class restriction + slot type, applies stat modifiers, fires `OnEquipmentChanged`. `Unequip(EquipSlot)`: removes modifiers, reverts stats. `GetEffectiveStats()`: base CharacterDataSO stats + all equipment modifier sums. No UI this sprint. | Agent B | 0.5 | S1-08 (ItemDatabaseSO), S1-01 (CharacterDataSO) | Compiles; `Equip()` applies modifiers to correct slot; class restriction blocks wrong-class items; `Unequip()` reverts stats; `GetEffectiveStats()` returns correct sum; `OnEquipmentChanged` fires; 5 slots match EquipSlot enum |
| S3-06 | **Combat HUD** — UI Toolkit HUD visible during combat. Shows: active character portrait + name, HP bar (current/max + number), MP bar, 4 skill icons with cooldown radial overlay + MP cost label, inactive character portrait (grayed with mini HP bar), enemy HP bars positioned above enemy heads (world-to-screen, clamped to screen edges). Switch indicator: flashes on switch press, shows 1.0s cooldown timer. HUD appears on `OnCombatStart`, hides on `OnCombatEnd`. | Agent B | 1.0 | S3-02 (CombatManager), S2-01 (HealthComponent), S3-03 (CharacterSwitching), S2-04 (SkillExecution) | HUD appears/hides with combat; active character portrait, HP, MP, 4 skill slots with cooldown overlays all visible; inactive character portrait grayed; enemy HP bars track above heads; switch cooldown indicator visible; HP/MP/cooldowns update in real-time |
| S3-07 | **First Playable Test Scene** — Create `TestArena.unity`: flat ground, basic lighting, spawn point for Evelyn + Evan, 3 enemy spawn points (2 GruntMelee + 1 ArcherRanged). Wire up: `CombatManager`, `CharacterSwitchController`, `LootDropper` on all enemies, Combat HUD. Player can: WASD move, Skill1 (BasicAttack), Skill2-4, Tab to switch characters. Victory: all enemies dead → log "VICTORY". Defeat: all player HP = 0 → log "GAME OVER". Use placeholder capsule meshes (blue = player, red = enemy). | Agent A | 0.5 | S3-01 through S3-06 complete | Scene loads without errors; WASD moves player; BasicAttack damages enemies; enemies attack back; Tab switches Evelyn↔Evan; HUD correct at all times; ≥1 loot drops per enemy death; pickup adds to PartyInventory; VICTORY and GAME OVER logs fire correctly; no crashes during full play-through |
| S3-08 | **Audio SFX wiring** — Wire `SFXPlayer.PlayOneShot()` calls to combat events: hit sound on `HurtboxComponent.OnHit`, skill cast sound on `SkillExecutor.OnSkillCast`, death sound on `HealthComponent.OnDeath`, loot pickup sound on `LootPickupComponent` collected. Wire `MusicPlayer` to `CombatManager`: fade in combat music on `OnCombatStart`, crossfade back to exploration music on `OnCombatEnd`. Use placeholder AudioClip references (can be silent stub clips) — real audio assets deferred to content sprint. | Agent B | 0.5 | S2-07 (SFXPlayer + MusicPlayer), S3-02 (CombatManager), S2-04 (SkillExecution), S2-01 (HealthComponent) | SFX hooks compile and fire without errors using stub clips; combat music fades in on `OnCombatStart`; exploration music crossfades back on `OnCombatEnd`; no null-ref exceptions when AudioClip refs are empty stubs |
| S3-09 | **Audio fade utilities** — `FadeIn(group, duration)`, `FadeOut(group, duration)`, `CrossfadeMusic(newClip, duration)` coroutine helpers on `AudioManager`. Scene-change music transition: auto-crossfade when `SceneLoader` fires its audio event. | Agent B | 0.5 | S2-06 (AudioManager), S2-03 (SceneLoader) | `FadeOut("Music", 2f)` reduces Music volume to 0 over 2s; `CrossfadeMusic(clip, 1.5f)` transitions smoothly; scene-change hook fires crossfade automatically; `FadeIn` restores volume from 0 |

### Should Have

| ID | Task | Agent | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------|-----------|--------------|---------------------|
| S3-10 | **Unit tests — Character Switching** — Verify 1.0s cooldown blocks rapid switching; incoming character retains its own HP/cooldowns after switch (damage Evelyn, switch to Evan, verify Evan has full HP); `OnCharacterSwitched` fires with correct SO refs; mid-skill switch cancels the skill. | Agent A | 0.25 | S3-03 | All tests pass; ≥4 test methods; state isolation verified; event payload verified |
| S3-11 | **Unit tests — Loot Drop** — Verify rarity distribution (10,000 rolls, each rarity within 5% of expected weight); enemy tier determines drop count (Grunt=1, Elite=2, Boss=3); items are valid non-null refs; empty loot table drops nothing without error. | Agent B | 0.25 | S3-04 | All tests pass; ≥4 test methods; distribution within 5% tolerance |
| S3-12 | **Unit tests — Combat System + Equipment** — Combat: `OnCombatEnd(true)` fires on last enemy death; `OnCombatEnd(false)` fires when all players at 0 HP; `OnCombatStart` fires on first enemy engaged. Equipment: `Equip()` applies correct stat modifiers; class restriction blocks wrong-class; `Unequip()` reverts stats; occupied slot swap works. | Agent B | 0.25 | S3-02, S3-05 | All tests pass; ≥6 test methods total |

### Nice to Have

*No Nice to Have tasks this sprint — all capacity allocated to First Playable delivery.*

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| TBD — Sprint 2 not yet complete | Sprint 2 ends 2026-05-02; assess on 2026-05-02 and add any incomplete S2 tasks here | Updated at Sprint 3 kickoff |

## Critical Path

```
Agent A (critical path — 5.5d wall-clock):
  S3-01 (Enemy AI, 1.5d)
    → S3-02 (Combat System, 2.0d)
      → S3-03 (Character Switching, 1.0d)
        → S3-07 (Test Scene, 0.5d)

Agent B (parallel — ~5.0d wall-clock):
  S3-05 (Equipment data layer, 0.5d — starts Day 1, independent)
  S3-09 (Audio fade utilities, 0.5d — starts Day 1, independent)
  S3-04 (Loot & Drop, 1.0d — starts Day 1 after S3-01 prereqs met)
  S3-08 (Audio SFX wiring, 0.5d — starts after S3-02)
  S3-06 (Combat HUD, 1.0d — starts after S3-02 + S3-03)

Convergence → S3-07 (Test Scene) integrates everything.
```

**Parallel execution by day:**

| Day | Agent A | Agent B |
|-----|---------|---------|
| 1 | S3-01 Enemy AI (start) | S3-05 Equipment data + S3-09 Audio fades |
| 2 | S3-01 Enemy AI (finish) | S3-04 Loot & Drop (start) |
| 3 | S3-02 Combat System (start) | S3-04 Loot & Drop (finish) |
| 4 | S3-02 Combat System (cont.) | S3-08 Audio SFX wiring |
| 5 | S3-02 (finish) + S3-03 Character Switching (start) | S3-06 Combat HUD (start) |
| 6 | S3-03 (finish) | S3-06 Combat HUD (finish) |
| 7 | S3-07 Test Scene (integration) | S3-10 + S3-11 + S3-12 unit tests |
| 8 | Buffer — integration bug fixes | Buffer |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Sprint 2 tasks incomplete by 2026-05-02, blocking Sprint 3 | Medium | High — all S3 tasks depend on S2 systems | Sprint 2 status check on 2026-04-28; if S2 systems incomplete, use Sprint 3 buffer days to finish them; defer S3 unit tests if needed |
| Combat feel flat with capsule placeholders — risk of false-negative quality assessment | High | Medium | Focus on mechanical correctness first; color-code capsules (blue=player, red=enemy); feel tuning deferred to content sprint |
| S3-07 (Test Scene integration) surfaces unexpected cross-system interaction bugs | High | Medium — integration day could expand 0.5→1.5 days | Keep TestArena minimal; wire systems individually verified before integration; log liberally during wiring |
| Character switch mid-skill causes lingering hitbox or ghost hits | Medium | Medium — core to game identity | Design rule documented: switch cancels skill immediately; SkillExecutor listens to `OnCharacterSwitched` and calls `CancelCurrentSkill()`; tested in S3-10 |
| HUD enemy HP bars off-screen edge cases (camera rotation, far enemies) | Medium | Low — cosmetic | Clamp HP bar positions to screen edges; hide bars beyond 30u from camera |
| Agent A critical path (5.5d) leaves only 2.5d of slack in 8 available days | High | High | Unit tests (S3-10 through S3-12) are Should Have — first to defer; Equipment can be descoped to 3 slots if needed |

## Design Rules Established This Sprint

- **Switching cancels current skill**: Switching mid-cast cancels the skill immediately. The skill goes on full cooldown (prevents switch-cancel exploit to reset cooldowns).
- **Distributed state on switch (ADR-0002)**: No HP, cooldown, or buff data is copied on switch. Each character owns their state permanently. Switching transfers input authority and camera focus only.
- **Loot drops are world pickups**: Items spawn in the world — player walks over to collect. This creates a "loot moment" without requiring inventory UI.

## Dependencies on External Factors

- All Sprint 2 Must Have tasks complete and merged before Sprint 3 starts
- Unity 6.3 LTS project stable — no editor crashes from Sprint 1/2
- UI Toolkit confirmed for runtime HUD (production-ready in Unity 6.3 per VERSION.md)
- No external art, animation, or real audio clip assets required — placeholder capsules, solid color materials, stub AudioClips
- Animator controllers with trigger parameters must exist (placeholder) for SkillExecutor animation triggers (from Sprint 2)

## Sprint Status

> **COMPLETED** — All Must Have implementation tasks (S3-01 through S3-09) finished
> ahead of schedule via Godot 4.6 migration (Gemini Phase 1–5). Should Have unit tests
> (S3-10, S3-11, S3-12) written in Phase 6 using GUT framework.
> **First Playable build is ready for manual playtesting in Godot 4.6.**
> Note: References to `.unity`/`.cs` above reflect original Unity design — all systems
> have been migrated to GDScript + `.tscn` / `.tres`.

## Definition of Done for Sprint 3 / First Playable Milestone

- [x] All Must Have tasks (S3-01 through S3-09) completed and verified
- [x] S3-10 Character Switching unit tests — written (`tests/unit/test_character_switching.gd`)
- [x] S3-11 Loot Drop unit tests — written (`tests/unit/test_loot_drop.gd`)
- [x] S3-12 Combat System + Equipment unit tests — written (`tests/unit/test_equipment.gd`)
- [x] `TestArena.tscn` exists and is wired with CombatEncounterManager, CharacterSwitchController, LootDroppers, Combat HUD (via ArenaWiring)
- [x] Character switching implemented per ADR-0002 (distributed state, input-authority transfer only)
- [x] Loot drop system implemented with rarity weights and world pickups
- [x] HUD implemented (`combat_hud.gd` + `CombatHUD.tscn`, `world_hp_bar.gd`)
- [x] Audio SFX wiring implemented (`audio_manager.gd`, `sfx_player.gd`)
- [x] No forbidden patterns; all gameplay values in `.tres` Resources; public APIs have doc comments
- [x] Code committed to main with references to design docs or task IDs
