# Main Menu & Pause Menu

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (first impression and ongoing accessibility)

## Overview

The Main Menu and Pause Menu are the player's entry point and hub for all game-level
controls. Built with Godot UI, the Main Menu presents the game title, Continue,
New Game, Settings, and Quit options on a stylized background (key art or animated
scene). The Pause Menu overlays the current game with Resume, Settings, Save Game,
Load Game, and Return to Main Menu options. Both menus use the same Settings sub-panel
(audio volumes, keybindings, display options). The menus are navigable via keyboard
(WASD + Enter/Escape) and gamepad (Left Stick + A/B). The Main Menu is the first thing
the player sees — it sets the game's tone. The Pause Menu is the player's control
panel during play — it must be fast, clear, and comprehensive.

## Player Fantasy

The Main Menu serves the fantasy of **stepping into a story you can't wait to begin**.
The title screen is atmospheric — maybe Evelyn standing in moonlight, or the Witch's
last words echoing over a dark background. Music plays the main menu theme. The player
clicks New Game and the story begins without a loading screen (or with a brief cinematic
fade). The Pause Menu is the opposite — it's utilitarian and clean. The player opens it
to save, check settings, or take a break. It doesn't try to be atmospheric; it tries to
be fast. Both menus share the same Settings panel so the player only learns the layout
once. The gothic styling (dark panels, gold accents, serif fonts) carries through both,
maintaining visual consistency.

**Reference model**: Dark Souls' minimalist, atmospheric main menu (title on black,
haunting music), Final Fantasy VII Remake's clean pause menu (fast access to save and
settings), and Persona 5's consistent menu styling (every menu feels like the game).

## Detailed Design

### Core Rules

1. **Main Menu Screen Flow**:
   ```
   ┌───────────────────────────────────────────┐
   │              MAIN MENU                     │
   │                                            │
   │         [GAME TITLE — large, styled]       │
   │                                            │
   │         ┌─────────────────────┐            │
   │         │  ▶ Continue         │ (if saves  │
   │         │  ▶ New Game         │  exist)    │
   │         │  ▶ Settings         │            │
   │         │  ▶ Quit             │            │
   │         └─────────────────────┘            │
   │                                            │
   │         [Version number — bottom-right]    │
   └───────────────────────────────────────────┘
   ```
   - **Continue**: Loads the most recent save file. If no saves exist, this option is
     grayed out. A save file summary is shown on hover (chapter, playtime, last save
     time).
   - **New Game**: Starts a new game from the Witch prologue. A confirmation dialog
     appears: "Starting a new game will erase your current progress. Continue?" If the
     player has unsaved progress, a second warning appears.
   - **Settings**: Opens the shared Settings panel (see #4 below).
   - **Quit**: Exits the game. On PC, this closes the application. A confirmation
     dialog appears: "Are you sure you want to quit?"

2. **Pause Menu Screen Flow** (overlay, game is paused behind it):
   ```
   ┌───────────────────────────────────────────┐
   │              PAUSE MENU                    │
   │                                            │
   │         ┌─────────────────────┐            │
   │         │  ▶ Resume           │            │
   │         │  ▶ Save Game        │            │
   │         │  ▶ Load Game        │            │
   │         │  ▶ Settings         │            │
   │         │  ▶ Return to Title  │            │
   │         └─────────────────────┘            │
   │                                            │
   │         [Chapter name — bottom-left]       │
   │         [Playtime — bottom-right]          │
   └───────────────────────────────────────────┘
   ```
   - **Resume**: Closes the pause menu, unpauses the game. Same as pressing Cancel.
   - **Save Game**: Opens the Save sub-panel showing save slots (up to 3 slots). Each
     slot shows: chapter name, playtime, save date. Player selects a slot to overwrite
     or create a new save. Auto-save slot is read-only and labeled "Auto-Save."
   - **Load Game**: Opens the Load sub-panel showing save slots. Player selects a slot
     to load. A confirmation dialog appears: "Loading will discard unsaved progress."
   - **Settings**: Opens the shared Settings panel.
   - **Return to Title**: Returns to the Main Menu. A confirmation dialog appears:
     "Return to title? Unsaved progress will be lost."

3. **Game Paused State**: When the pause menu is open:
   - `Time.timeScale = 0` (game simulation is frozen)
   - Input System activates the UI action map
   - Audio System: Music ducks to -6 dB (less aggressive than dialogue ducking)
   - Camera System: Holds the current camera position (no movement)
   - Combat HUD: Frozen behind the menu (visible but not updating)
   - All gameplay systems stop processing (Update checks `Time.timeScale > 0`)

4. **Settings Panel** (shared between Main Menu and Pause Menu):

   > **Design Note**: This document fully owns the Settings System. The planned "Settings
   > System" entry (#37 in the systems index) should be removed — it is absorbed here.
   > The `GameSettings` Resource is the persistence container for all settings.
   >
   > **`GameSettings` schema** (persisted via Save / Load System):
   >
   > | Field | Type | Default | Effect |
   > |-------|------|---------|--------|
   > | `MasterVolume` | float | `0.8` | AudioMixer `MasterVol` |
   > | `MusicVolume` | float | `0.8` | AudioMixer `MusicVol` |
   > | `SFXVolume` | float | `1.0` | AudioMixer `SFXVol` |
   > | `UIVolume` | float | `0.6` | AudioMixer `UIVol` |
   > | `AmbienceVolume` | float | `0.5` | AudioMixer `AmbVol` |
   > | `MuteAll` | bool | `false` | Master mute toggle |
   > | `Fullscreen` | bool | `true` | `Screen.fullScreen` |
   > | `Resolution` | `Vector2Int` | `1920×1080` | `Screen.SetResolution` |
   > | `FOV` | float | `55` | Camera FOV (Camera System) |
   > | `DamageNumbersVisible` | bool | `true` | Combat HUD damage number toggle |
   > | `DamageNumberSize` | enum | `Normal` | Combat HUD damage number scale |
   > | `TypewriterSpeed` | float | `40` | Calls `DialogueManager.SetTypewriterSpeed(value)` in real-time when changed |
   > | `ColorblindMode` | enum | `Off` | Post-processing color filter (future system) |
   > | `KeyBindings` | `InputBindingOverride[]` | (defaults) | Input System action overrides |
   ```
   ┌───────────────────────────────────────────┐
   │              SETTINGS                      │
   │                                            │
   │  Audio          │                          │
   │  ─────────────  │  Master Volume  [████░]  │
   │  Display        │  Music Volume   [████░]  │
   │  Controls       │  SFX Volume     [█████]  │
   │  Accessibility  │  UI Volume      [███░░]  │
   │                 │  Ambience Vol   [██░░░]  │
   │                 │  [Mute All]              │
   │                 │                          │
   │                 │  Display                  │
   │                 │  ─────────────            │
   │                 │  Resolution     [1920x1080│
   │                 │  Fullscreen     [Yes]     │
   │                 │  FOV            [55°]     │
   │                 │  Damage Numbers [On]     │
   │                 │                          │
   │                 │  Controls                 │
   │                 │  ─────────────            │
   │                 │  [Key Bindings...]        │
   │                 │  Input Method   [Auto]    │
   │                 │                          │
   │                 │  Accessibility             │
   │                 │  ─────────────            │
   │                 │  Typewriter Speed [Normal]│
   │                 │  Damage # Size  [Normal]  │
   │                 │  Colorblind Mode  [Off]   │
   │                                            │
   │              [Apply]  [Cancel]              │
   └───────────────────────────────────────────┘
   ```
   - Settings are organized into tabs: Audio, Display, Controls, Accessibility
   - Changes are previewed immediately but not applied until "Apply" is pressed
   - "Cancel" reverts to the values when the panel was opened
   - Settings persist via the Save / Load System (stored in a `GameSettings` JSON file)

5. **Key Bindings Sub-Panel**:
   - Lists all remappable actions with their current bindings
   - Player selects an action and presses a new key/button to rebind
   - Conflicts are detected and highlighted (e.g., "This key is already bound to
     'Interact'. Replace?")
   - "Reset to Defaults" button restores all default bindings
   - Bindings are saved as part of the Settings data

6. **Navigation and Focus**:
   - First menu element is auto-focused when the menu opens
   - Navigate (WASD / Left Stick) moves focus between elements
   - Submit (Enter / A) activates the focused element
   - Cancel (Escape / B) goes back one level (Settings → Pause Menu → Game)
   - Focus is visually indicated with a gold border and slight scale-up (105%)

7. **Menu Open/Close Animation**:
   - Main Menu: Fade in from black over 1.0s (title screen entrance)
   - Pause Menu: Fade in from transparent over 0.2s, with a subtle scale-up
   - Both menus fade out over 0.2s when closing
   - Sub-panels (Settings, Save, Load) slide in from the right over 0.2s

### States and Transitions

```
                    ┌──────────────────┐
                    │   Application    │
                    │     Start        │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │   Main Menu      │
                    │   (title screen) │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │ New Game     │ Continue     │ Quit
              ▼              ▼              ▼
     ┌──────────────┐ ┌──────────────┐ ┌──────────┐
     │   In Game    │ │   In Game    │ │  Quit    │
     │              │ │  (loaded)    │ │  App     │
     └──────┬───────┘ └──────┬───────┘ └──────────┘
            │ Pause          │ Pause
            ▼                ▼
     ┌──────────────────────────────┐
     │       Pause Menu             │
     │  Resume → back to In Game    │
     │  Save/Load → sub-panels      │
     │  Settings → Settings panel   │
     │  Return to Title → Main Menu │
     └──────────────────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Save / Load** | Calls | Saves and loads game state via save/load slots |
| **Input System** | Reads | Reads Submit, Navigate, Cancel for menu navigation |
| **Audio System** | Calls | Plays menu music, UI sounds for button press/hover |
| **Scene Management** | Calls | New Game triggers scene load (Witch prologue) |
| **Chapter State** | Reads | Reads chapter name and playtime for pause menu display |
| **Combat HUD** | Calls | HUD is frozen behind pause menu |
| **Dialogue System** | Reads | Blocks pause menu from opening during dialogue |
| **Cutscene System** | Reads | Blocks pause menu from opening during cutscenes |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `MainMenuFadeIn` | `1.0s` | Title screen entrance fade |
| `MenuOpenFadeIn` | `0.2s` | Pause menu open animation |
| `MenuCloseFadeOut` | `0.2s` | Menu close animation |
| `SubPanelSlideIn` | `0.2s` | Settings/Save/Load slide from right |
| `MusicDuckPause` | `-6 dB` | Music volume while pause menu is open |
| `MaxSaveSlots` | `3` | Manual save slots (plus 1 auto-save) |
| `FocusScale` | `1.05x` | Focused menu element scale |

## Edge Cases

1. **Player pauses during a cutscene**: Pause menu is blocked. Cutscenes cannot be paused
   (the player must skip or wait). This is intentional — cutscenes are authored sequences.

2. **Player pauses during dialogue**: Pause menu is blocked. Dialogue is modal and cannot
   be interrupted. The player must complete or skip the dialogue first.

3. **All save slots are full**: Creating a new save requires overwriting an existing slot.
   The Save panel makes this clear: "All slots are full. Select a slot to overwrite."

4. **Save file is corrupted**: The save slot shows "Corrupted Save — Cannot Load." The
   player can overwrite it but not load it. A warning is logged with details for debugging.

5. **Settings applied, then player opens settings again and cancels**: The settings revert
   to the values when the panel was opened (the previously applied values). No double-
   revert or loss of applied settings.

6. **Key binding conflict detected**: The conflicting action is shown ("This key is bound
   to 'Interact'. Replace?"). If the player confirms, the old binding is removed and the
   new one is set. If they cancel, the binding is not changed.

7. **Player quits during combat**: Unsaved progress is lost. The next Continue load will
   be from the last manual or auto-save. Auto-save typically occurs at encounter
   boundaries, so the player loses at most one encounter's progress.

8. **Resolution set to unsupported value**: The resolution dropdown only lists supported
   resolutions (from `Screen.resolutions`). If the player's monitor is disconnected and
   the saved resolution is no longer available, the game falls back to the closest
   supported resolution.

## Dependencies

- **Depends on**: Save / Load System, Input System, Audio System, Scene Management,
  Chapter State, Godot UI
- **Depended on by**: Audio System (menu music), Input System (UI action map), Combat
  HUD (hidden behind pause menu)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `MaxSaveSlots` | int | `3` | Manual save slots |
| `AutoSaveSlotCount` | int | `1` | Auto-save slot (rotating) |
| `MainMenuMusicVolume` | float | `0.6` | Main menu music volume |
| `MusicDuckPause` | float | `-6 dB` | Music duck during pause |
| `FocusScale` | float | `1.05` | Focused element scale |

## Visual/Audio Requirements

- **Main Menu Background**: Key art image or animated scene featuring Evelyn (MVP: a
  single static key art image with subtle particle effects — floating embers or moonlight)
- **Game Title**: Stylized "My Vampire" text with custom font treatment (gothic serif,
  gold color, subtle glow)
- **Menu Music**: Main menu theme (somber, atmospheric, ~2 min loop). Fades out when
  New Game is selected.
- **UI Sounds**: Button hover (soft click), button press (confirming click), menu open
  (subtle whoosh), menu close (reverse whoosh).
- **Pause Menu Background**: Semi-transparent dark overlay (80% opacity black) with the
  game visible but dimmed behind it.

## UI Requirements

- **Godot UI Scenes**: Separate `.tscn` files for Main Menu, Pause Menu, Settings Panel,
  Save/Load Panel, and Key Bindings Panel.
- **Theme Resources**: Shared `.tres` theme file for menu styles (colors, borders, fonts, animations).
- **Responsive Layout**: Menus scale correctly at 720p, 1080p, 1440p, and 4K resolutions.
- **Controller Support**: All menu elements navigable with gamepad. Focus indicator is
  visible and unambiguous.

## Acceptance Criteria

- [ ] Main Menu displays with title, Continue, New Game, Settings, and Quit
- [ ] Continue is grayed out when no save files exist
- [ ] New Game starts the Witch prologue scene (loads the correct scene)
- [ ] New Game confirmation warns about progress loss
- [ ] Pause Menu opens with Escape/Start and freezes game simulation
- [ ] Pause Menu shows current chapter name and total playtime
- [ ] Resume closes the pause menu and unpauses the game
- [ ] Save Game opens the Save panel with 3 manual slots + 1 auto-save
- [ ] Load Game opens the Load panel and loads the selected save
- [ ] Load confirmation warns about unsaved progress
- [ ] Settings panel shows all four tabs (Audio, Display, Controls, Accessibility)
- [ ] Settings changes preview immediately but apply only on "Apply"
- [ ] Cancel reverts settings to values when panel was opened
- [ ] Key Bindings panel allows rebinding all actions with conflict detection
- [ ] Return to Title closes to Main Menu with confirmation dialog
- [ ] Pause menu is blocked during cutscenes and dialogue
- [ ] Menu navigation works with both keyboard and gamepad
- [ ] Menu elements auto-focus correctly and Navigate moves focus predictably
- [ ] Settings persist across game sessions (saved and loaded)
- [ ] Corrupted save files are detected and cannot be loaded
- [ ] Menus scale correctly at all supported resolutions

## Open Questions

- Should the Main Menu include a "Credits" option? For MVP, credits can be shown at the
  end of the game (post-credits scene). A separate credits option from the main menu is
  nice-to-have but not required.
- Should the auto-save be visible in the Load panel? It should be visible but labeled
  "Auto-Save (read-only)" and not overwritable by the player.
- Should we support a "Quick Save" (single button press saves to a dedicated slot) from
  the pause menu? This would speed up saving during exploration. Recommendation: yes,
  as a keyboard shortcut (F5) and controller shortcut (D-Pad Down) in addition to the
  Save panel.
