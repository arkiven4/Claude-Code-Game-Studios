# Audio System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (cinematic presentation), Sensation (audio feedback)

## Overview

The Audio System manages all sound playback in My Vampire: background music, combat
sound effects, UI sounds, ambient environmental audio, and voice/narration. Built on
Godot's AudioBus system with AudioStreamPlayer3D pooling, it provides four bus groups
(Music, SFX, UI, Ambience) with independent volume controls, crossfade transitions,
and priority-based sound culling. Music tracks crossfade on scene changes and combat
state transitions. Combat SFX are pooled and recycled to avoid allocation. The Audio
System is called by nearly every other system — combat triggers hit sounds, the camera
triggers transition whooshes, the UI triggers click sounds — but it owns no gameplay
logic. It is purely a playback service.

## Player Fantasy

The Audio System serves the fantasy of **a living, breathing world**. The player should
hear the world around them: the hum of the forest, the crack of a spell connecting,
the low drums building as combat intensifies, the sudden silence when a boss dies.
Music is the emotional narrator — it swells during the twist ending, it mourns during
the Witch's death, it pulses during hack-and-slash combat. Sound effects are punchy
and satisfying — every hit connects with weight. The player never hears a sound that
doesn't belong, never experiences audio popping or clipping, and can always hear
what matters (combat cues > ambience > music). The mix is always clean, always
intentional.

**Reference model**: NieR:Automata's music-to-silence transitions (music drops out
for emotional impact), Final Fantasy VII Remake's layered combat music (combat adds
drums, exploration strips to strings), and Persona 5's crisp UI sounds (every menu
click is satisfying).

## Detailed Design

### Core Rules

1. **Four Audio Mixer Groups**: All audio routes through a master `GameAudioMixer` with
   four child groups:
   - **Music** (default volume: 0.8) — Background music, boss themes, chapter themes
   - **SFX** (default volume: 1.0) — Combat hits, skill activations, deaths, physics
   - **UI** (default volume: 0.6) — Menu clicks, button presses, dialogue advance
   - **Ambience** (default volume: 0.5) — Environmental sounds, wind, birds, crowd noise

   Each group has an `AudioMixerGroup` asset exposed to the Godot Audio Mixer window.
   Volume is controlled in dB via exposed parameters (`MusicVol`, `SFXVol`, `UIVol`,
   `AmbVol`).

2. **Master Volume**: A master `MasterVol` exposed parameter controls the overall output.
   All individual volumes are multipliers applied on top of master volume. If the player
   sets Music to 50%, the Music group's dB is set to `20 * log10(0.5) ≈ -6 dB`.

3. **AudioSource Pooling**: `AudioSource` objects are pooled, not created at runtime.
   The `AudioPoolManager` maintains a pool of 32 `AudioSource` components:
   - 4 for Music (one per concurrent music track; typically only 1 active)
   - 20 for SFX (combat is the heaviest user: 4 skills × 4 characters + enemy hits)
   - 4 for UI (UI sounds are short; 4 concurrent is ample)
   - 4 for Ambience (one per active area layer)

   When a sound plays, the pool returns an idle `AudioSource`. If none are idle, it
   steals the oldest playing sound (lowest priority first). Pool size is configurable.

4. **Music Playback Rules**:
   - Only ONE music track plays at a time (with crossfade exceptions)
   - Music tracks are `AudioClip` assets referenced by scene or encounter state
   - On scene change or combat state change, the current track crossfades to the new
     track over 2.0s (tunable)
   - Music tracks have a `MusicPriority` enum to resolve conflicts:
     | Priority | Use Case |
     |----------|----------|
     | `Silence` | Post-boss emotional silence |
     | `Exploration` | Default area music |
     | `Combat` | Standard combat music |
     | `BossCombat` | Boss-specific theme |
     | `Narrative` | Story-triggered music (cutscenes, deaths) |
   - Higher-priority music always overrides lower-priority music
   - When the higher-priority music stops, the previous track does NOT resume unless
     explicitly told to (music state is not remembered)

5. **SFX Playback Rules**:
   - SFX are one-shot: play once, release the `AudioSource` back to the pool
   - SFX can overlap: multiple SFX play simultaneously without interrupting each other
   - SFX have 3D spatial blend for positional sounds (hits, enemy vocalizations):
     - `SpatialBlend = 1.0` (fully 3D) for positional sounds (combat hits near the camera)
     - `SpatialBlend = 0.0` (fully 2D) for global sounds (UI clicks, menu sounds)
   - SFX pitch variation: ±5% random pitch on each playback to prevent machine-gun
     repetition on frequently played sounds (normal attacks, footsteps)

6. **Combat Music Layering**: During combat, the music track can have additional layers
   added dynamically:
   - **Base Layer**: Always present — the core combat track
   - **Intensity Layer**: Added when 3+ enemies are alive — adds percussion
   - **Crisis Layer**: Added when any party member enters Critical state (<10% HP) — adds
     strings and urgency
   - Layers are mixed in real-time by adjusting the volume of additional `AudioSource`s
     playing the layer stems. All layers are part of the same music asset (stems are
     separate clips synced to the same tempo).

7. **Audio Ducking**: When critical game events occur, lower-priority audio is ducked
   (temporarily reduced in volume):
   - **Dialogue starts**: Music ducks to -12 dB, Ambience ducks to -6 dB. SFX unchanged.
     Duck lasts for the duration of the dialogue.
   - **Boss enters**: Ambience ducks to -18 dB for 3s (boss entrance is the focus).
   - **Party member dies**: All audio ducks to -6 dB for 1s (death moment is emphasized).
   - Ducking is implemented via `AudioMixer` snapshots with smooth transitions (0.3s in,
     0.5s out).

8. **Scene Transition Crossfade**: When the Scene Management System changes scenes:
   - Current scene's music fades out over 1.0s
   - New scene's music fades in over 2.0s (0.5s overlap with the fade-out)
   - SFX are hard-cut on scene change (no carry-over)
   - Ambience transitions with the scene (old stops, new starts)

9. **Save/Load of Audio State**: The following audio state is saved:
   - Master volume, Music volume, SFX volume, UI volume, Ambience volume (player settings)
   - Currently playing music track and playback position (for save/resume)
   - Mute state of each group

### States and Transitions

```
┌──────────────────────────────────────────────────────┐
│                   AudioMixer (Master)                 │
│                                                       │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐  │
│  │  Music   │ │   SFX    │ │   UI   │ │ Ambience │  │
│  │  0.8     │ │  1.0     │ │  0.6   │ │   0.5    │  │
│  │          │ │          │ │        │ │          │  │
│  │ Crossfade│ │ Pool: 20 │ │Pool: 4 │ │Pool: 4   │  │
│  │ Layers: 3│ │ 3D blend │ │2D only │ │Per scene │  │
│  └──────────┘ └──────────┘ └────────┘ └──────────┘  │
│                                                       │
│  Ducking Events:                                      │
│    Dialogue start → Music -12dB, Ambience -6dB       │
│    Boss enter → Ambience -18dB for 3s                │
│    Party death → All -6dB for 1s                     │
└──────────────────────────────────────────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Combat System** | Called by | Triggers combat music on encounter start, intensity layers on wave changes |
| **Health & Damage** | Called by | Triggers hit sounds, death sounds, critical hit sounds |
| **Skill Execution** | Called by | Triggers skill activation SFX per skill definition |
| **Enemy AI** | Called by | Triggers enemy attack SFX, enemy death SFX |
| **Camera System** | Called by | Triggers camera transition whoosh sounds |
| **Cutscene System** | Called by | Triggers narrative music, ducks other audio during cutscenes |
| **Dialogue System** | Called by | Triggers dialogue advance SFX, ducks music/ambience during dialogue |
| **Input System** | Called by | Triggers UI click sounds on button press |
| **Scene Management** | Called by | Crossfades music on scene change, stops scene-specific ambience |
| **Main Menu** | Called by | Plays main menu music, UI sounds for menu navigation |
| **Save / Load** | Serialized by | Volume settings, current music track, playback position |
| **Combat HUD** | Read by | Reads volume settings for mute button display |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `VolumeToDB` | `20 × log10(volumeLinear)` | Conversion for AudioMixer exposed parameters |
| `CrossfadeDuration` | `2.0s` | Default music crossfade time |
| `CrossfadeOverlap` | `0.5s` | Old track fades out while new track fades in |
| `DialogueDuckMusic` | `-12 dB` | Music volume during dialogue |
| `DialogueDuckAmbience` | `-6 dB` | Ambience volume during dialogue |
| `BossDuckAmbience` | `-18 dB for 3s` | Ambience ducking during boss entrance |
| `DeathDuckAll` | `-6 dB for 1s` | All audio ducks during party member death |
| `SFXPitchVariation` | `Random(0.95, 1.05)` | Random pitch per SFX playback |
| `DuckInTime` | `0.3s` | Smooth transition into ducked state |
| `DuckOutTime` | `0.5s` | Smooth transition out of ducked state |

## Edge Cases

1. **Two combat SFX request the same pooled AudioSource**: The newer sound steals from
   the oldest playing sound with the lowest priority. The player may miss a hit sound
   in very heavy combat, but this is preferable to audio clipping or allocation.

2. **Music crossfade interrupted by another music change**: The in-progress crossfade
   is canceled. The currently fading-in track becomes the "old" track and crossfades
   to the new track. No audio pops — the transition is smooth.

3. **Player mutes all audio during a cutscene**: The cutscene continues normally. Music
   and SFX are silenced, but the narrative plays. No warnings or blocks.

4. **Save file loaded with different volume settings than current**: The loaded settings
   override the current settings. Audio crossfades from the old volumes to the new ones
   over 0.5s (no sudden volume jump).

5. **Scene change while dialogue is active**: Dialogue is force-closed on scene change.
   Audio ducking is released. Music crossfades to the new scene's track.

6. **Boss combat music layer plays on a non-boss encounter**: The layer system only
   activates for bosses (explicit flag on the encounter). Standard combat encounters
   only get the base layer.

7. **SFX plays for a dead enemy**: The death event triggers the death SFX once. Subsequent
   SFX requests for that enemy (e.g., hit sounds) are ignored because the enemy's
   `AudioSource` reference is nulled on death.

## Dependencies

- **Depends on**: Godot AudioBus system (built-in), AudioStreamPlayer3D pooling
- **Depended on by**: Combat System, Health & Damage, Skill Execution, Enemy AI, Camera,
  Cutscene System, Dialogue System, Input System, Scene Management, Main Menu, Save / Load,
  Combat HUD

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `MusicVolumeDefault` | float | `0.8` | Default music volume (linear scale) |
| `SFXVolumeDefault` | float | `1.0` | Default SFX volume |
| `UIVolumeDefault` | float | `0.6` | Default UI volume |
| `AmbienceVolumeDefault` | float | `0.5` | Default ambience volume |
| `CrossfadeDuration` | float | `2.0s` | Music crossfade time |
| `SFXPoolSize` | int | `20` | Concurrent SFX capacity |
| `SFXPitchVariance` | float | `0.05` | ±5% random pitch |
| `DialogueDuckDB` | float | `-12` | Music duck amount during dialogue |
| `DuckInTime` | float | `0.3s` | Ducking ramp-in time |
| `DuckOutTime` | float | `0.5s` | Ducking ramp-out time |

## Visual/Audio Requirements

- **Audio Mixer Asset**: A `GameAudioMixer` asset in `Assets/Audio/Mixers/` with all
  four groups, exposed parameters, and snapshots for ducking states
- **Music Tracks**: One per chapter/area + one combat track + one boss track (MVP:
  Witch prologue music, Chapter 1 music, Chapter 2 music, Combat music, Boss music,
  Main menu music, Ending music)
- **SFX Library**: Hit sounds per damage type (Physical, Magical, Holy, Dark), skill
  activation sounds per skill, death sounds, character switch sound, dialogue advance
  sound, UI click sound, camera whoosh, combat start/end sounds
- **Ambience Tracks**: One per area (forest, village, dungeon, cave)

## UI Requirements

- **Settings Panel**: Pause menu includes volume sliders for Master, Music, SFX, UI,
  and Ambience. Each slider shows a dB readout alongside the linear percentage.
- **Mute Toggle**: A master mute button in the settings panel that silences all audio.
- **Combat HUD**: Small mute icon in the corner of the HUD that toggles master mute.

## Acceptance Criteria

- [ ] Music crossfades smoothly on scene change (no pops, no gaps, 2s crossfade)
- [ ] Combat music layers activate correctly (base always, intensity at 3+ enemies,
  crisis at Critical HP)
- [ ] SFX play from the pool without allocation during combat (zero GC alloc per SFX)
- [ ] Dialogue ducks music and ambience to specified dB levels
- [ ] Party member death ducks all audio for 1s
- [ ] Volume sliders in settings adjust AudioMixer exposed parameters in real-time
- [ ] Audio state (volumes, music position) saves and loads correctly
- [ ] SFX pitch variation is audible on repeated plays (not robotic)
- [ ] 3D spatial sounds position correctly (closer = louder, pans with camera)
- [ ] Audio pool does not overflow in 4-character combat with all skills firing
- [ ] No audio clipping, popping, or distortion at any volume level

## Open Questions

- Should dialogue have per-line voice clips (voice acting) or just text with ambient
  sounds? MVP scope suggests text-only, but the system should support voice clips if
  added later.
- Should the music layering system use stem mixing (separate clips for drums, strings,
  etc.) or a single compressed track with Godot's built-in layering? Stem mixing gives
  more control but requires more asset management.
- Should we support a "Now Playing" display in the settings so the player knows what
  track is currently playing?
