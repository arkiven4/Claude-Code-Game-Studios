# Cutscene System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (cinematic presentation)

## Overview

The Cutscene System sequences cinematic moments that bridge gameplay and narrative.
Built on Unity's Timeline package (`UnityEngine.Timeline`), each cutscene is a
`PlayableDirector`-driven Timeline asset that choreographs camera movements, character
animations, dialogue beats, audio cues, and visual effects into a single authored
sequence. The Cutscene System manages the lifecycle: it blocks all input, takes over
the camera, plays the Timeline, handles mid-cutscene dialogue transitions, and restores
game state when the cutscene ends. Cutscenes are triggered by chapter state changes,
encounter completion, or explicit DialogueEvent calls. The system supports player skip
(after a 2-second grace period) and auto-skips on subsequent playthroughs (for players
who have already seen the cutscene in a prior session).

## Player Fantasy

The Cutscene System serves the fantasy of **living inside a well-animated story**. The
player should feel that cutscenes are events, not interruptions. A cutscene begins
seamlessly — no loading screen, no jarring transition — and plays with the production
value of a good anime episode. Camera angles are intentional. Characters move and
speak with purpose. Music swells at the right moment. The player can skip if they've
seen it before, but the quality is high enough that they won't want to. The twist
ending — Evelyn's death, the vanishing of all magical creatures — is delivered through
a cutscene that earns its emotional weight. The system ensures that moment hits hard.

**Reference model**: Final Fantasy VII Remake's seamless gameplay-to-cutscene transitions
(no loading, camera takes over naturally), Persona 5's stylish cinematic framing (camera
angles tell the story), and NieR:Automata's willingness to use cutscenes for emotional
punch rather than exposition dumps.

## Detailed Design

### Core Rules

1. **Unity Timeline-Driven**: Each cutscene is a `.playable` Timeline asset authored
   in Unity's Timeline window. A `PlayableDirector` component on a scene-level
   `CutsceneController` GameObject plays the Timeline. The Cutscene System wraps the
   director with lifecycle management, input blocking, and state restoration.

2. **CutsceneDefinitionSO**: A ScriptableObject that defines a cutscene's metadata:
   ```
   CutsceneDefinitionSO fields:
   ┌─────────────────────────────────────────────────┐
   | CutsceneId: string (unique identifier)           |
   | TimelineAsset: Timeline reference                |
   | Duration: float (auto-detected from Timeline)    |
   | SkipAllowedAfter: float (seconds, default 2.0)   |
   | AutoSkipIfSeen: bool (default false)             |
   | ChapterFlag: string (set when cutscene completes) |
   | PreCutsceneAction: enum (none, fade-to-black,    |
   |                          freeze-gameplay)         |
   | PostCutsceneAction: enum (none, fade-from-black,  |
   |                           trigger-dialogue,      |
   |                           start-combat)           |
   | PostCutsceneRef: reference (dialogue graph,       |
   |                              encounter, etc.)     |
   └─────────────────────────────────────────────────┘
   ```

3. **Cutscene Lifecycle**:
   1. `CutsceneManager.Play(cutsceneDef)` is called by a trigger
   2. `PreCutsceneAction` executes (fade-to-black or freeze gameplay)
   3. Input System blocks all gameplay input (UI map active with Skip button)
   4. Camera System switches to Cinematic mode (camera control handed to Timeline)
   5. Audio System triggers narrative music, ducks other audio
   6. `PlayableDirector.Play()` starts the Timeline
   7. Timeline plays: camera tracks, characters animate, audio plays, signals fire
   8. Timeline signals (custom `SignalEmitter`s) can trigger mid-cutscene events:
      - Dialogue nodes (hands off to Dialogue System mid-cutscene)
      - VFX triggers (explosions, magical effects)
      - Camera shakes, time scale changes
   9. Timeline ends (or player skips)
   10. `PostCutsceneAction` executes (fade-from-black, trigger dialogue, start combat)
   11. Input System restores gameplay input
   12. Camera System returns to Exploration/Combat mode
   13. If `ChapterFlag` is set, the Chapter State System records it
   14. Cutscene is marked as "seen" for auto-skip on replay

4. **Player Skip**: After `SkipAllowedAfter` seconds (default 2.0s), the player can
   press the Submit button to skip the cutscene. Skipping:
   - Stops the `PlayableDirector` immediately
   - Executes the `PostCutsceneAction` (same as if the cutscene completed naturally)
   - Sets the `ChapterFlag` (skipped cutscenes still count as "seen")
   - Marks the cutscene as "seen" for auto-skip
   - No partial state — the cutscene is treated as fully completed when skipped

5. **Auto-Skip on Replay**: If `AutoSkipIfSeen` is true and the player has already
   seen this cutscene in a prior session (tracked by `ChapterStateSystem`), the
   cutscene is skipped automatically:
   - A brief 0.5s fade-to-black plays (so the skip is visible)
   - `PostCutsceneAction` executes
   - The player doesn't see the cutscene again
   - This is opt-in per cutscene — important story moments should NOT auto-skip

6. **Timeline Signal Integration**: Timelines can include `SignalEmitter` tracks that
   fire `INotification` callbacks at specific timecodes. The `CutsceneController`
   subscribes to these and routes them:
   - `DialogueSignal` → pauses Timeline, starts Dialogue System, resumes Timeline when
     dialogue ends
   - `VFXSignal` → triggers a VFX at a specified position
   - `AudioSignal` → plays a one-shot sound at the specified mixer group
   - `TimeScaleSignal` → sets `Time.timeScale` (slow-mo, pause, etc.)
   - `CameraSignal` → switches to a specific Cinemachine virtual camera

7. **Mid-Cutscene Dialogue**: When a `DialogueSignal` fires:
   - The `PlayableDirector` is paused (not stopped)
   - The Dialogue System starts the specified `DialogueGraphSO`
   - When dialogue ends, the `PlayableDirector` resumes from the pause point
   - This allows cutscenes with embedded conversations (character exchanges during
     cinematic moments)

8. **Cutscene Triggers**: Cutscenes are started by:
   - **Chapter State**: `ChapterStateSystem` detects a flag and fires the cutscene
   - **Scene Load**: A scene's `CutsceneTrigger` fires on load (chapter opener)
   - **Dialogue Event**: A `DialogueEvent` of type `StartCutscene` transitions to
     a cutscene mid-conversation
   - **Encounter End**: A boss death triggers a post-fight cutscene
   - **Story Override**: Any script can call `CutsceneManager.Play()` directly

9. **No Gameplay During Cutscenes**: Cutscenes are fully authored — no player control
   of characters, camera, or actions (except skip). Characters do not respond to
   combat input, movement input, or any gameplay input. Combat subsystems are frozen.

10. **Cutscene Loading**: Cutscene Timeline assets are loaded via Addressables when
    needed. The first play of a cutscene may have a brief loading hitch (0.5-1.0s).
    A fade-to-black pre-cutscene action covers this. Subsequent plays are instant
    (Timeline is cached).

### States and Transitions

```
┌──────────┐  Play()     ┌──────────────────┐
│  Idle    │ ──────────▶ │  Pre-Cutscene    │
│          │             │  (fade/freeze)   │
└──────────┘             └────────┬─────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │  Timeline        │◄───────────────────┐
                        │  Playing         │                    │
                        └────────┬─────────┘                    │
                                 │                              │
                    ┌────────────┼────────────┐                 │
                    │            │            │                 │
                    ▼            ▼            ▼                 │
             Timeline End   Player Skip   Dialogue Signal       │
                    │            │            │                 │
                    │            │     Timeline Paused          │
                    │            │     Dialogue Plays           │
                    │            │     Dialogue Ends            │
                    │            │            │                 │
                    │            │            └─────────────────┘
                    │            │
                    ▼            ▼
                        ┌──────────────────┐
                        │  Post-Cutscene   │
                        │  (fade/trigger)  │
                        └────────┬─────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │     Idle         │
                        │  (restore input) │
                        └──────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Chapter State** | Reads/Writes | Reads auto-skip flag, writes completion flag |
| **Camera System** | Calls | Switches to Cinematic mode, returns to previous mode after |
| **Audio System** | Calls | Triggers narrative music, ducks other audio, plays signal sounds |
| **Input System** | Calls | Blocks gameplay input, enables UI skip button |
| **Dialogue System** | Calls/Resumed by | Pauses/resumes Timeline for mid-cutscene dialogue |
| **Scene Management** | Called by | Scene load triggers fire opening cutscenes |
| **Combat System** | Called by | Boss death triggers post-fight cutscene |
| **Save / Load** | Serialized by | Seen cutscene IDs, chapter flags |
| **Combat HUD** | Calls | Hides HUD during cutscenes |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `SkipGracePeriod` | `2.0s` | Minimum time before skip is allowed |
| `FadeToBlackDuration` | `0.5s` | Pre-cutscene fade duration |
| `FadeFromBlackDuration` | `0.5s` | Post-cutscene fade duration |
| `AutoSkipFadeDuration` | `0.5s` | Brief fade for auto-skipped cutscenes |
| `TimelineResumeAfterDialogue` | `instant` | Timeline resumes immediately when dialogue ends |

## Edge Cases

1. **Player tries to skip during the 2s grace period**: Skip input is ignored. A subtle
   "hold to skip" indicator does not appear until the grace period passes.

2. **Cutscene triggered while another cutscene is playing**: The new cutscene is queued.
   When the current cutscene ends (or is skipped), the queued cutscene plays immediately.
   Queue depth: 1 (only one cutscene can be queued; additional triggers are dropped with
   a warning).

3. **Cutscene Timeline references a character not in the current scene**: The Timeline
   plays but the missing character's track is silent. The cutscene continues — no crash.
   A prominent error is logged. This is a content authoring error, not a runtime bug.

4. **Save file loaded during a cutscene**: Cutscenes are never saved mid-play. If a save
   occurs while a cutscene is playing, the save records the cutscene ID as "in progress."
   On load, the cutscene replays from the beginning.

5. **Dialogue System ends while Timeline is paused**: The Timeline resumes immediately.
   If the Timeline was waiting for the dialogue to set up the next beat, the cutscene
   continues from the resume point.

6. **Player opens pause menu during cutscene**: The pause menu is blocked during
   cutscenes. The player must skip or wait for the cutscene to end.

7. **Cutscene signal references an invalid VFX or audio clip**: The signal is silently
   skipped. The cutscene continues. A warning is logged for the content team.

8. **Timeline duration exceeds 5 minutes**: Long cutscenes are allowed but a warning is
   logged. The recommendation is to split long cutscenes into multiple shorter ones with
   dialogue breaks between them.

## Dependencies

- **Depends on**: Unity Timeline package, Unity Cinemachine, Dialogue System, Camera
  System, Audio System, Input System, Chapter State System, Addressables (cutscene loading)
- **Depended on by**: Chapter State System, Combat System (boss death cutscenes),
  Dialogue System (mid-cutscene transitions), Scene Management System, Save / Load

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `SkipGracePeriod` | float | `2.0s` | Reduce for impatient players, increase to ensure story beats land |
| `FadeToBlackDuration` | float | `0.5s` | Faster for pace, slower for drama |
| `MaxCutsceneQueue` | int | `1` | Max queued cutscenes |
| `LongCutsceneWarning` | float | `300s` | Warning threshold (5 minutes) |

## Visual/Audio Requirements

- **Timeline Assets**: One per cutscene in the game. MVP needs: Witch prologue intro,
  Witch prologue ending (Witch's death), Chapter 1 intro, Chapter 1 ending, Chapter 2
  intro, Chapter 2 ending (the twist), and boss death cutscenes for each boss.
- **Fade-to-Black**: Full-screen black overlay with alpha animation. Used for transitions
  into and out of cutscenes.
- **Cinematic Cameras**: Each cutscene Timeline includes authored Cinemachine virtual
  cameras with custom framing, FOV, and post-processing (vignette, color grading).
- **Narrative Music**: Dedicated music tracks for cutscenes, separate from exploration
  and combat music.

## UI Requirements

- **Skip Indicator**: Small text at the bottom-right of the screen: "Press [Submit] to
  skip" — appears after the 2s grace period. Button label matches current input device.
- **HUD Hidden**: The Combat HUD, Dialogue UI, and all gameplay UI are hidden during
  cutscenes.
- **Post-Cutscene Transition**: If the post-cutscene action is fade-from-black, a full-
  screen black overlay fades out over 0.5s.

## Acceptance Criteria

- [ ] Cutscene Timeline plays from start to end with correct camera, animation, and audio
- [ ] Player can skip after 2s grace period; skip executes post-cutscene action correctly
- [ ] Auto-skip works for cutscenes marked as seen (0.5s fade, post-action executes)
- [ ] Mid-cutscene dialogue pauses Timeline and resumes it when complete
- [ ] Cutscene signals (Dialogue, VFX, Audio, TimeScale, Camera) fire at correct timecodes
- [ ] Gameplay input is fully blocked during cutscene playback
- [ ] Camera System returns to the correct mode after cutscene ends
- [ ] Audio System restores audio levels after cutscene ends
- [ ] Chapter flag is set when cutscene completes (or is skipped)
- [ ] Cutscene "seen" state persists through save/load
- [ ] Queued cutscenes play in order after the current one ends
- [ ] Invalid Timeline references do not crash the game (warn and continue)
- [ ] HUD is hidden during cutscene playback

## Open Questions

- Should cutscenes support quick-time events (QTEs) during playback for player agency?
  This would add interactivity but complicate the authored sequence. Recommendation:
  no QTEs for MVP; the game's interactivity is in combat, not cutscenes.
- Should we support cutscene chaptering (a long cutscene split into parts with the
  player able to pause between parts)? This would help with the 5-minute+ cutscene
  problem. Recommendation: split into separate cutscene assets instead.
- Should the twist ending cutscene be unskippable on first playthrough? Recommendation:
  yes — the 2s grace period applies, but after that the player CAN skip. The first
  playthrough should encourage watching, not force it.
