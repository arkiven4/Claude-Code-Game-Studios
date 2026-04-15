# Village / Hub System

> **Status**: Approved
> **Author**: Design session 2026-04-11 (interactive redesign)
> **Last Updated**: 2026-04-11
> **Implements Pillar**: Story First, Earn the Ending

## Overview

The Village/Hub System defines safe areas where the player rests, shops, interacts with NPCs, and enhances equipment between chapters. The main hub is a medium-sized, open village with natural boundaries (forest edge, cliff, river) that the player can freely explore. It's a seamless part of the world scene — no scene transitions to enter or leave. The hub evolves over time: new NPCs arrive, buildings change, atmosphere shifts, and shop inventories grow as the story progresses. Minor rest stops appear between chapters, offering HP/MP recovery and a traveling merchant. The hub is a safe zone — no combat can occur inside it. Players access services by approaching NPCs or interaction points and talking. Rest costs gold and fully restores party HP/MP. Once discovered, hubs can be fast-traveled between. Equipment enhancement is accessed through a blacksmith NPC in the hub. All hub services delegate to their respective systems (Shop, NPC, Equipment Enhancement) — the Hub System is the spatial container and access layer.

## Player Fantasy

Hubs serve the fantasy of **coming home**. After a dangerous chapter of combat and choices, the player walks back into the village and everything softens. The music changes. The blacksmith hammers the same rhythm as always. The innkeeper remembers you. You can rest here — literally, your party heals, but also metaphorically, the weight lifts. The hub is your anchor. It's the place between adventures where you prepare, reflect, and connect. And because it evolves — new faces appear, buildings change, the merchant stocks better gear because you've proven yourself — coming back feels earned. The village grows with you. It's not static wallpaper between chapters. It's the world's way of saying: *you matter here.*

**Reference model**: Fire Emblem's monastery (a home base that grows and changes with story progression), Hollow Knight's Dirtmouth (small, quiet, atmospheric hub that grounds the adventure), and Stardew Valley's town (a living community you return to, not just a menu screen).

## Detailed Rules

### Core Rules

1. **Hub Definition**: Each hub is defined as a Godot scene (`.tscn`) with the following metadata:
   ```
   HubData Resource fields:
   ┌─────────────────────────────────────────────────┐
   | HubId: string (unique identifier)                |
   | DisplayName: string                              |
   | IsMainHub: bool (true = primary evolving village)|
   | ScenePath: string (path to .tscn file)           |
   | EntryPosition: Vector2 (where player spawns)     |
   | NaturalBoundaries: Area2D[] (collision zones)    |
   | NPCs: NPCReference[] (NPCId + position)          |
   | Services: ServiceReference[] (type + position)   |
   | Evolutions: HubEvolution[] (per-chapter changes)  |
   | FastTravelUnlocked: bool                         |
   └─────────────────────────────────────────────────┘
   ```

2. **Main Hub vs Minor Stops**:
   - **Main Hub**: One primary village marked `IsMainHub = true`. It persists across chapters and evolves. Contains the full suite of services: multiple NPCs, shops, blacksmith, inn.
   - **Minor Stops**: Small rest areas between chapters. Contain a campfire (rest point) and optionally a traveling merchant. No permanent NPCs, no equipment enhancement. Minor stops do not evolve — they're static.

3. **Hub Layout**: The main hub is an open village layout — the player walks freely between buildings, NPCs, and service points. Natural boundaries (forest edges, cliffs, rivers) define the walkable area. No invisible walls within the hub — the space is fully explorable. Buildings are decorative facades with interaction points at their entrances (the player doesn't enter buildings — services are accessed from outside).

4. **Service Access**: All hub services are accessed by approaching the relevant NPC or interaction point and pressing the Interact button:
   - **Inn**: Approach the inn building's door → prompt: "Rest (costs N gold)" → confirms → full party HP/MP restore
   - **Shop**: Approach merchant NPC → prompt: "Browse Shop" → opens Shop UI
   - **Blacksmith**: Approach forge anvil/blacksmith NPC → prompt: "Enhance Equipment" → opens Equipment Enhancement UI
   - **NPCs**: Approach any NPC → prompt: "Talk to [Name]" → opens Dialogue UI (see NPC System)

5. **Rest Mechanic**: Resting at an inn or campfire fully restores all party members' HP and MP. The rest costs gold (amount scales with chapter). Rest is optional — the player can choose not to rest and save gold, but enters the next chapter at whatever HP/MP they currently have. Rest does NOT reset cooldowns, remove buffs, or clear deferred level-ups — those are combat-state mechanics. Rest does NOT auto-save the game.

6. **Hub Evolution**: The main hub evolves based on chapter progression. Each `HubEvolution` entry specifies:
   ```
   HubEvolution fields:
   ┌─────────────────────────────────────────────────┐
   | TriggerChapter: int (chapter number to activate)  |
   | NewNPCs: NPCReference[] (NPCs that appear)        |
   | RemovedNPCs: string[] (NPCs that leave)           |
   | BuildingChanges: BuildingChange[] (add/modify)    |
   | AtmosphereChange: AtmosphereSettings? (music,     |
   |                      lighting overrides)           |
   | ShopInventoryUpgrade: InventoryTier? (better items)|
   └─────────────────────────────────────────────────┘
   ```
   Evolutions trigger when the player enters the hub after completing the trigger chapter. A brief cutscene plays (5-10 seconds) showing the changes: "The village has grown. New faces have arrived."

7. **Seamless World**: The hub is part of the same Godot scene as the surrounding world. There is no scene transition when entering or leaving the hub. The hub boundary is defined by natural features (trees, cliffs, water) and a `SafeZone` Area2D that:
   - Disables enemy spawning within the zone
   - Despawns any enemies that enter the zone (they turn around and leave)
   - Displays a subtle screen border effect that fades when the player is inside (warm tone)
   - Triggers hub music crossfade when the player enters

8. **Safe Zone Rule**: No combat can initiate within the hub's safe zone. If the player is pursued by enemies and enters the hub, enemies stop at the boundary and retreat. This is absolute — no story exceptions. The hub is the one place where the player can lower their guard.

9. **Fast Travel**: Once a hub has been discovered (player has entered it at least once), it becomes available for fast travel from the world map or pause menu. Fast travel:
   - Is instant (no loading screen if same scene; brief fade if different scene)
   - Can be used at any time except during combat or cutscenes
   - Costs no resources
   - Returns the player to the hub's defined `EntryPosition`

10. **Chapter Transition Behavior**: When a chapter ends and the player returns to the hub:
    - Party HP/MP are NOT auto-restored (player must rest at inn)
    - Any hub evolutions for the completed chapter are applied
    - The player spawns at the hub's `EntryPosition`
    - A brief narrative beat may play (2-3 lines of dialogue or narration summarizing the return)
    - The player is free to explore the hub and prepare for the next chapter

### States and Transitions

```
┌──────────┐  Player walks into  ┌──────────────────┐
│  World   │  hub boundary        │  Hub (Safe Zone) │
│  Map     │ ────────────────────▶│                  │
└──────────┘  (seamless, same     │  • Music crossfade
              scene)              │  • Screen border warms
                                  │  • Enemies despawn
                                  │  • Evolution check (if chapter just ended)
                                  └────────┬─────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
             ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
             │  Approach    │    │  Approach    │    │  Approach    │
             │  Inn Door    │    │  Merchant    │    │  NPC         │
             │  "Rest?"     │    │  "Shop?"     │    │  "Talk?"     │
             └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
                    │                   │                   │
                    ▼                   ▼                   ▼
             ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
             │  Full HP/MP  │    │  Shop UI     │    │  Dialogue UI │
             │  -Gold cost  │    │  (Shop Sys)  │    │  (NPC Sys)   │
             └──────┬───────┘    └──────────────┘    └──────────────┘
                    │
                    │  Player leaves hub
                    ▼
             ┌──────────┐
             │  World   │
             │  Map     │──▶ Enemies can spawn again
             └──────────┘
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Health & Damage** | Writes | Rest restores all party HP/MP | Current party HP/MP state |
| **Shop System** | Calls | Merchant NPCs open shop UI | Shop transaction results |
| **NPC System** | Calls | NPCs are placed in the hub; dialogue accessed from hub | NPC definitions, positions |
| **Equipment Enhancement** | Calls | Blacksmith opens enhancement UI | Enhancement results |
| **Chapter State System** | Reads | Reads current chapter for hub evolution triggers | Chapter number, completed flags |
| **Cutscene System** | Calls | Triggers evolution cutscenes and return narrative beats | Cutscene playback |
| **Save / Load** | Reads | Hub evolution state is loaded from save | Hub evolution progress |
| **Combat System** | Reads | Blocks fast travel during combat; enforces safe zone rule | `IsInCombat` flag |
| **Scene Management** | Driven by | Hub is loaded as part of world scene or as separate scene | Scene loading/unloading |
| **Narrative Choice** | Reads | Reads story flags for hub evolution conditions | Story flag values |

## Formulas

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **Rest Cost** | `BaseRestCost + (ChapterNumber × RestCostScaling)` | BaseRestCost: 20 gold, Scaling: 10 gold/chapter | Chapter 1: 30g, Chapter 2: 40g, etc. |
| **Fast Travel Unlock** | `HasEnteredHubAtLeastOnce[hubId] == true` | — | Boolean flag per hub |
| **Safe Zone Radius** | `Area2D boundary` defined per hub | — | Defined in HubData Resource |
| **Evolution Trigger** | `CurrentChapter >= HubEvolution.TriggerChapter` | — | Checked on hub entry |

## Edge Cases

1. **Player tries to rest but doesn't have enough gold**: The rest prompt shows the cost. If the player can't afford it, the action is blocked with a tooltip: "Not enough gold. Rest costs [N] gold." No partial rest is available.

2. **Player fast travels during combat**: Fast travel is blocked during combat. The button is grayed out with tooltip: "Cannot fast travel during combat." The player must exit combat first.

3. **Hub evolution triggers but the player hasn't visited the hub yet**: The evolution is queued and will apply the next time the player enters the hub. No notification is shown until the player arrives — the surprise is part of the experience.

4. **Player leaves the hub mid-conversation with an NPC**: The dialogue closes cleanly. The NPC returns to their default state. No conversation progress is lost — dialogue state is persisted in the Chapter State System.

5. **Safe zone despawns an enemy that was mid-combat**: If an enemy pursues the player into the hub boundary, the enemy stops, turns around, and walks away. The combat encounter is aborted — the enemy is removed from the encounter. The player does not gain XP or loot from an aborted encounter.

6. **Multiple hub evolutions trigger at once (player skipped chapters)**: All evolutions for completed chapters are applied in order. Each evolution's cutscene plays sequentially (5-10 seconds each). The player sees a montage of changes: "Chapter 3 complete — new buildings appear. Chapter 4 complete — the inn expands."

7. **Player rests at a minor stop's campfire while an NPC is mid-quest dialogue**: Rest is independent of NPC state. The player can rest at any time. Resting does not advance or complete quests.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Health & Damage | Writes | Hard — rest restores HP/MP | `RestorePartyHP()`, `RestorePartyMP()` |
| Shop System | Calls | Soft — merchant NPCs trigger shop UI | `OpenShop(merchantId)` |
| NPC System | Calls | Hard — NPCs are placed and managed in hubs | `NPCData` Resources, NPC Manager |
| Equipment Enhancement | Calls | Soft — blacksmith triggers enhancement UI | `OpenEquipmentEnhancement()` |
| Chapter State System | Reads | Hard — reads chapter for evolution triggers | `GetCurrentChapter()`, `IsChapterComplete(chapter)` |
| Cutscene System | Calls | Soft — plays evolution and return cutscenes | `PlayCutscene(cutsceneId)` |
| Save / Load | Reads | Soft — loads hub evolution state | Save file: `hubEvolutions`, `discoveredHubs` |
| Combat System | Reads | Hard — enforces safe zone and blocks fast travel | `IsInCombat` flag |
| Scene Management | Driven by | Hard — hub scene loading | Hub `.tscn` file paths |
| Narrative Choice | Reads | Soft — reads story flags for evolution conditions | `GetFlag(key)` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `BaseRestCost` | int | `20` gold | 10-50 | Rest becomes a significant gold sink | Rest feels trivial; no resource tension |
| `RestCostScaling` | int | `10` gold/chapter | 5-20 | Late-game rest becomes too expensive | No scaling impact on economy |
| `SafeZoneBoundary` | Area2D | `per-hub defined` | — | Too small: hub feels cramped; too large: enemies can get close |
| `EvolutionCutsceneDuration` | float | `7s` | 5-15 | Evolution feels slow and disruptive | Player misses the changes |
| `HubMusicCrossfadeTime` | float | `2s` | 1-4 | Music transition is jarring if too fast; sluggish if too slow |
| `FastTravelCooldown` | float | `0s` (instant) | 0-5 | Unnecessary delay between fast travels | Fast travel spam with no friction |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Player enters hub | Screen border warms (subtle golden vignette), music crossfades to hub theme | Hub music fades in with crossfade (2s) | High |
| Hub evolution triggers | Brief cutscene showing new buildings/NPCs appearing | Narrative narration + building construction sounds | High |
| Rest at inn | Party HP/MP bars animate upward to full; gold counter decreases | Rest chime — peaceful, resolving sound | High |
| Fast travel initiated | Brief fade to white (or instant if same scene), player appears at entry position | Teleport whoosh or simple step sound | Medium |
| Enemy approaches safe zone | Enemy stops at boundary, turns, walks away | Enemy retreat sound (footsteps fading) | Medium |
| Hub discovered for first time | "New location discovered: [Hub Name]" banner appears | Discovery chime — warm, welcoming | High |
| Minor stop campfire rest | Fire crackles, HP/MP bars animate to full | Fire ambience + rest chime | Medium |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **Rest Prompt** | "Rest at the inn? Costs [N] gold. Restores all party HP and MP." | Player interacts with inn door |
| **Fast Travel Menu** | List of discovered hubs with names and optional descriptions | Player opens fast travel from world map or pause menu |
| **Hub Discovery Banner** | "New location: [Hub Name]" with brief description | First time entering a hub |
| **Evolution Summary** | Brief cutscene or text: "The village has changed. New faces have arrived." | After chapter completion triggers evolution |

## Acceptance Criteria

- [ ] Main hub loads as part of the world scene with no scene transition
- [ ] Natural boundaries (forest, cliff, river) define walkable hub area
- [ ] Safe zone prevents enemy spawning and despawns pursuing enemies
- [ ] Screen border warms when player enters hub; music crossfades to hub theme
- [ ] Rest at inn fully restores party HP/MP and deducts correct gold cost
- [ ] Rest is blocked if player doesn't have enough gold (with tooltip)
- [ ] Hub evolution triggers after completing trigger chapter, applies all changes
- [ ] Multiple queued evolutions apply in order when player visits hub
- [ ] Fast travel is available for all discovered hubs; blocked during combat
- [ ] Minor stops provide rest + optional merchant; no enhancement or permanent NPCs
- [ ] Hub discovery banner shows first time entering a new hub
- [ ] Chapter transition returns player to hub entry position with optional narrative beat
- [ ] All hub services (shop, NPC talk, enhancement) are accessed via approach + interact

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| Should the main hub have a name that the player learns organically through story (not told upfront)? | Narrative Director | Resolve during first chapter writing — recommendation: yes, discovered through NPC dialogue |
| Can the player donate gold to the hub to accelerate its evolution (separate from story-driven evolution)? | Game Designer | Resolve during economy balance — recommendation: no for MVP; nice-to-have for Full Vision |
| Should the hub have a day/night cycle that affects which NPCs are available at what time? | Systems Designer | Resolve during hub atmospheric design — adds realism but significant content complexity |
| Should minor rest stops have unique visual identity per location (campfire in forest, shrine in mountains) or shared template? | Art Director | Resolve during art pipeline planning — recommendation: unique visuals for at least 3-4 stops |
