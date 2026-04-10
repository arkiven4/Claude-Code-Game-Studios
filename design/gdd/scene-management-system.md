# Scene Management System

> **Status**: Designed
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (seamless narrative flow)

## Overview

The Scene Management System controls which Godot scene is loaded, how scenes transition,
and what state is restored after a scene change. It handles four transition types:
standard scene load (with loading screen), chapter transition (with cutscene bookends),
area portal transitions (walking through a door triggers a seamless scene swap), and
load-from-save (destroys current scene and loads the saved scene). It coordinates with
the Chapter State System to know which scene to load, with the Save / Load System to
restore scene state, and with the Audio System to crossfade music during transitions.
The system ensures that scene changes feel intentional and smooth — no hard cuts, no
loading screen pop-in, no state loss.

## Player Fantasy

The Scene Management System serves the fantasy of **a world that flows without seams**.
The player should rarely see a loading screen — when they do, it's brief and contextual
(a fade-to-black with a narrative title like "Entering the Witch's Lair"). Walking through
a door or crossing a zone boundary feels like moving through a continuous world, not
loading a new file. Music crossfades during transitions maintain mood continuity. When
loading a save, the player appears in exactly the right spot, with everything in the right
state. The system is invisible — the player only notices it when it breaks.

**Reference model**: Hollow Knight's seamless area transitions (walking through doorways
feels natural), God of War's single-shot camera (no visible loading), and Final Fantasy's
contextual loading screens (narrative text during load).

## Detailed Design

### Core Rules

1. **Four Transition Types**:
   - **Standard Load**: Loads a scene by name with a loading screen. Used for chapter
     transitions and initial game start. Shows a black screen with loading text and a
     brief narrative tip (e.g., "Evelyn remembers the taste of blood...").
   - **Area Portal Load**: Triggered by walking through a portal object (doorway, cave
     entrance, teleporter). Plays a brief fade-to-black (0.3s), loads the new scene,
     positions the player at the portal's exit point, fades back in (0.3s). Total
     transition time: ~0.8s.
   - **Chapter Transition Load**: Triggered by Chapter State System. Plays the chapter
     end cutscene, loads the new scene (standard load), plays the chapter begin cutscene.
     Total transition time: 5–15s (cutscene-dependent).
   - **Load-from-Save**: Triggered by Save / Load System. Destroys all current scene
     objects, loads the target scene, restores all serialized state from the save file.
     Total transition time: 2–3s.

2. **Scene Loading Flow** (standard load):
   1. `SceneManager.LoadSceneAsync(sceneName, LoadSceneMode.Single)` is called with
      `allowSceneActivation = false` (holds on loading screen until state is ready)
   2. System displays loading screen overlay (black background, loading text, narrative tip)
   3. Async load runs in the background; `asyncOperation.progress` drives a loading bar
   4. When `asyncOperation.isDone` is true, the system waits one frame for all objects
      to initialize
   5. System calls `ISceneLoadable.OnSceneLoaded()` on all registered managers
   6. System hides the loading screen with a fade-out (0.3s)
   7. Scene is active and player-controlled

3. **Area Portal Flow**:
   1. Player enters a `PortalTrigger` collider
   2. System reads the portal's `TargetScene` and `ExitPoint` properties
   3. System fades camera to black (0.3s)
   4. System loads the target scene asynchronously
   5. System positions the player at the `ExitPoint`
   6. System fades camera back from black (0.3s)
   7. Audio System crossfades music (handled by Audio System on scene change event)

4. **Scene State Restoration** (after load-from-save):
   1. Scene loads normally (all objects at their default positions)
   2. Save / Load System calls `SceneStateRestorer.RestoreState(SceneStateData)`
   3. System iterates over serialized scene objects and restores:
      - Object positions (for moved/interacted objects)
      - Object active state (for destroyed/deactivated objects)
      - Chest open/closed state
      - Door open/closed state
      - Enemy alive/dead state
   4. System notifies all `ISaveable` systems that scene state is restored

5. **Music Crossfade on Scene Change**:
   1. Before scene unload, Audio System begins fading out current music track (0.5s)
   2. New scene loads
   3. After scene load, Audio System begins fading in new music track (0.5s)
   4. If crossfading between related scenes (same chapter, adjacent areas), the
      crossfade uses a harmonic transition (same key, different arrangement)
   5. If crossfading between unrelated scenes (different chapters), the crossfade is
      a full stop → new track (no harmonic relationship)

6. **Scene Registry**: The system maintains a registry of all scenes in the game:
   ```csharp
   public struct SceneDefinition {
       public string SceneName;       // Godot scene file name (without .tscn)
       public int ChapterId;          // Which chapter this scene belongs to
       public SceneType Type;         // enum: Combat, Hub, Cutscene, Menu, Transition
       public bool IsStreaming;       // true for area portal scenes (can preload)
       public Vector3 DefaultSpawnPoint; // Where the player spawns in this scene
   }
   ```

7. **Preloading**: For Area Portal transitions, the system can preload the target scene
   in the background while the player is still in the current scene. If `IsStreaming` is
   true for the target scene, the system begins async loading when the player is within
   10 units of a portal. The scene is cached and the transition is instant (no loading
   screen, just the 0.6s fade).

8. **Loading Screen Tips**: The loading screen displays a narrative tip — a short quote
   or story fragment relevant to the scene being loaded. Tips are defined per scene:
   ```
   "WitchPrologue.tscn" → "The forest remembers what the village forgot."
   "HauntedCrypt.tscn" → "Not all tombs are meant to stay closed."
   ```

9. **Scene Unloading**: Before a scene is unloaded, the system:
   1. Calls `ISaveable.Serialize()` on all registered systems (if a save is in progress)
   2. Calls `ISceneUnloadable.OnSceneUnloading()` on registered managers
   3. Destroys all scene objects that are not marked `DontDestroyOnLoad`
   4. Notifies the Audio System to stop scene-specific audio sources

10. **Error Handling**:
    - If a scene fails to load (missing file, corrupt scene), the system displays an
      error screen: "Failed to load area. Returning to previous location."
    - The system falls back to the previous scene (if available) or the main menu
    - The error is logged with the scene name and error details for debugging

### States and Transitions

```
┌──────────────┐
│    IDLE      │ ◄── No scene change in progress
└──────┬───────┘
       │ LoadScene(sceneName) called
       ▼
┌──────────────┐
│  LOADING     │ ◄── Loading screen displayed, async load running
│  (standard)  │
└──────┬───────┘
       │ asyncOperation.isDone == true
       ▼
┌──────────────┐
│  RESTORING   │ ◄── State restoration, OnSceneLoaded callbacks
│  (brief)     │
└──────┬───────┘
       │ restoration complete
       ▼
┌──────────────┐
│    IDLE      │
└──────────────┘
```

**Area Portal sub-flow** (branched from IDLE):
```
IDLE → PORTAL_FADE_OUT (0.3s) → LOADING (async) → RESTORING → PORTAL_FADE_IN (0.3s) → IDLE
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Save / Load** | Called by | Save / Load requests scene load by name from save data |
| **Chapter State** | Called by | Chapter State requests scene load for chapter transitions |
| **Audio System** | Calls | Audio System crossfades music on scene change |
| **Camera System** | Called by | Camera System resets to default position on scene load |
| **Combat System** | Notified | Combat System clears combat state when scene changes |
| **Input System** | Notified | Input System is briefly disabled during transitions (0.3s) |
| **Health & Damage** | Notified | Health & Damage restores HP/MP if scene load is from save |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `LoadTime` | Unity async load time | Typically 0.5–2.0s depending on scene complexity |
| `PortalTransitionTime` | `fadeOut + loadTime + fadeIn` | Typically 0.3 + 0.5 + 0.3 = 1.1s |
| `MusicFadeOutDuration` | `0.5s` | Crossfade out duration |
| `MusicFadeInDuration` | `0.5s` | Crossfade in duration |
| `PreloadDistance` | `10 units` | Distance from portal to begin preloading |
| `LoadingTipDuration` | `3.0s` | Minimum time to read the narrative tip |

## Edge Cases

1. **Player spams portal trigger while loading**: The system ignores additional portal
   triggers while a scene load is already in progress. The player cannot queue multiple
   scene transitions.

2. **Scene load fails during chapter transition**: The system displays the chapter end
   cutscene again (from cached data) and retries the load. If it fails twice, it returns
   to the main menu with an error.

3. **Player dies during a portal transition**: Death is not possible during a transition
   — the player is in a loading state with input disabled. If death was triggered just
   before the portal, the death sequence completes before the transition begins.

4. **Save file references a deleted scene**: The Save / Load System detects this and
   defaults to the chapter's entrance scene. The player appears at the start of the
   chapter with a message: "The saved area is no longer available."

5. **Two portals in the same location**: The player can only trigger one portal at a time.
   If two portal colliders overlap, the system uses the portal with the highest priority
   (defined by the level designer).

6. **Loading screen stuck**: If the async load takes longer than 30 seconds (timeout),
   the system displays a fallback screen: "Still loading... this shouldn't take long."
   If it takes 60 seconds, the system returns to the main menu and logs the error.

## Dependencies

- **Depends on**: Save / Load System (for restore state), Audio System (for music
  crossfade on scene change)
- **Depended on by**: Chapter State, Camera System, Combat System, Cutscene System

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `FadeOutDuration` | float | `0.3s` | Camera fade-out for portal transitions |
| `FadeInDuration` | float | `0.3s` | Camera fade-in for portal transitions |
| `MusicCrossfadeDuration` | float | `0.5s` | Audio crossfade duration |
| `PreloadDistance` | float | `10.0` | Units from portal to begin preloading |
| `LoadTimeout` | float | `30.0s` | Maximum time before warning displayed |
| `LoadCriticalTimeout` | float | `60.0s` | Maximum time before abort and return to menu |

## Visual/Audio Requirements

- **Loading Screen**: Black background, centered loading text, scene name, narrative tip
  (italic text below), subtle animated background (particle drift, faint smoke)
- **Portal Transition**: Fade-to-black (0.3s), brief pause (0.2s), fade-in (0.3s)
- **Music Crossfade**: Current track fades out while new track fades in — no audio gap
- **Error Screen**: Red-tinted loading screen with error message and "Return to Menu"
  button

## UI Requirements

- **Loading Screen**: Scene name, loading indicator (spinner), narrative tip, estimated
  time (hidden if unknown)
- **Error Screen**: Error message, "Return to Menu" button, "Retry" button
- **Debug Overlay** (debug builds only): Current scene name, load time, memory usage,
  scene object count

## Acceptance Criteria

- [ ] Standard scene load displays loading screen and completes without errors
- [ ] Area portal transition is seamless (fade-out, load, fade-in in under 2s)
- [ ] Music crossfades smoothly on scene change (no audio gap, no clipping)
- [ ] Loading-from-save restores scene state identically (positions, states, enemies)
- [ ] Chapter transition plays end cutscene, loads scene, plays begin cutscene in order
- [ ] Failed scene load displays error and falls back gracefully
- [ ] Preloading reduces portal transition time to under 1s when target scene is cached
- [ ] Loading screen displays narrative tip relevant to the scene being loaded
- [ ] Input is disabled during all scene transitions (no input leakage)
- [ ] Scene unload properly cleans up objects and notifies registered systems

## Open Questions

- Should we support additive scene loading (loading multiple scenes simultaneously for
  open areas), or keep it strictly one scene at a time?
- Should portal transitions have a directional component (camera faces the exit direction
  when the new scene fades in)?
- Should the loading screen include a "skip tip" button for players who want to speed
  through repeated loads?
