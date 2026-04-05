# Input System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (every party member responds to the same input)

## Overview

The Input System is the bridge between player actions and game responses. Built on Unity's
new Input System package (`com.unity.inputsystem`), it defines a single Input Action Asset
with three action maps: **Exploration** (movement, interaction, camera orbit), **Combat**
(skills, character switching, targeting), and **UI** (menus, navigation, confirmation).
The player never configures keybinds for individual characters — one set of inputs
controls whoever is currently the active party member. The Input System reads raw input,
applies contextual awareness (is the player in combat? is a dialogue box open?), and
dispatches normalized action events that the Gameplay systems consume. Dead zones, input
buffering, and input flushing during character switches are all handled here.

## Player Fantasy

The Input System serves the fantasy of **effortless control**. The player should never
think "which button does what" — every button does the obvious thing. The same four
buttons always cast skills, the same switch button swaps party members, the same interact
button talks to NPCs. The player doesn't rebind keys per character or relearn controls
between exploration and combat. The input feels responsive: pressing a button registers
within one frame, and if you press slightly early, the system buffers it for 0.15s so
it doesn't feel lost. When you switch characters, your button mash doesn't accidentally
fire the new character's skill — the system flushes the buffer cleanly. Input is
invisible when it works and frustrating when it doesn't. This system makes sure it works.

**Reference model**: Final Fantasy VII Remake's context-sensitive single button (Interact
= talk / pick up / open door), Dark Souls' consistent face-button layout (light / heavy /
dodge / interact), and Hades' tight input buffering (feels responsive without being twitch).

## Detailed Design

### Core Rules

1. **Unity Input System Package**: This system uses `UnityEngine.InputSystem` exclusively.
   The legacy `UnityEngine.Input` class is forbidden per technical-preferences.md.
   An `InputActionAsset` defines all game actions.

2. **Three Action Maps**:
   - **Exploration** — active when the player is not in combat and no UI modal is open.
   - **Combat** — active when `CombatEncounterManager.IsInCombat` is true.
   - **UI** — active when any menu, dialogue box, or pause screen has focus.

   Only one action map is enabled at a time. Transitions between maps are automatic and
   context-driven (see State Transitions below).

3. **Exploration Action Map**:
   | Action | Input (Default) | Type | Description |
   |--------|----------------|------|-------------|
   | `Move` | WASD / Left Stick | Value (Vector2) | Movement direction and magnitude |
   | `Interact` | E / D-Pad Up | Button | Talk to NPCs, pick up items, open doors |
   | `CameraOrbit` | Mouse drag / Right Stick | Value (Vector2) | Rotate exploration camera |
   | `Pause` | Escape / Start | Button | Open pause menu |

4. **Combat Action Map**:
   | Action | Input (Default) | Type | Description |
   |--------|----------------|------|-------------|
   | `Move` | WASD / Left Stick | Value (Vector2) | Movement direction (character-relative) |
   | `Skill1` | 1 / Square | Button | Activate skill slot 1 |
   | `Skill2` | 2 / Triangle | Button | Activate skill slot 2 |
   | `Skill3` | 3 / Circle | Button | Activate skill slot 3 |
   | `Skill4` | 4 / X | Button | Activate skill slot 4 |
   | `Switch1` | F1 / D-Pad Left | Button | Switch to party slot 1 |
   | `Switch2` | F2 / D-Pad Right | Button | Switch to party slot 2 |
   | `Switch3` | F3 / D-Pad Up | Button | Switch to party slot 3 |
   | `Switch4` | F4 / D-Pad Down | Button | Switch to party slot 4 |
   | `TargetLock` | Mouse right / LT | Button (hold) | Lock onto nearest enemy |
   | `CameraOrbit` | Mouse drag / Right Stick | Value (Vector2) | Rotate combat camera |
   | `Pause` | Escape / Start | Button | Open pause menu |

5. **UI Action Map**:
   | Action | Input (Default) | Type | Description |
   |--------|----------------|------|-------------|
   | `Navigate` | WASD / Left Stick | Value (Vector2) | Navigate UI elements |
   | `Submit` | Enter / A | Button | Confirm selection |
   | `Cancel` | Escape / B | Button | Close menu / go back |
   | `TabLeft` | Q / L1 | Button | Move to previous tab |
   | `TabRight` | E / R1 | Button | Move to next tab |

6. **Contextual Input Resolution**: The Input System does not dispatch raw key events.
   Instead, a thin `InputRouter` MonoBehaviour reads the active action map and dispatches
   semantic events:
   ```csharp
   public class InputRouter : MonoBehaviour
   {
       public event Action<Vector2> OnMove;
       public event Action OnInteract;
       public event Action<int> OnSkillPressed;    // skill slot 1-4
       public event Action<int> OnSwitchToIndex;   // slot 0–3
       public event Action OnPause;
   }
   ```
   Consumers subscribe to semantic events, not raw keys. This allows input remapping at
   the action level without changing any gameplay code.

7. **Input Buffering**: When the player presses a skill button during a skill animation,
   the input is buffered for 0.15s. If the character becomes available (animation ends,
   cooldown is ready) within the buffer window, the skill fires. This prevents the
   "I pressed it but nothing happened" feel from sub-100ms timing misses.
   - Buffer window: 0.15s (tunable)
   - Only ONE input buffered at a time (latest input overwrites earlier)
   - Buffer is flushed on character switch, pause, or death

8. **Input Flushing on Character Switch**: When `CharacterSwitchController` initiates a
   switch, the `InputRouter` flushes its input buffer immediately (per ADR-0002). This
   prevents the button press that triggered the switch from also firing a skill on the
   newly controlled character. The flush is a hard reset — all buffered inputs are
   discarded.

9. **Dead Zone Handling**: Analog stick inputs (movement, camera orbit) apply a radial
   dead zone of 0.2 (20% of full range). Values below 0.2 are treated as zero. This
   prevents stick drift from causing unintended movement or camera rotation.

10. **Movement Smoothing**: Analog stick movement input is smoothed over `MoveSpeedSmoothing`
    seconds (default 0.1s) via linear interpolation. This eliminates micro-jitter from
    low-quality analog sticks and prevents stutter during slow directional inputs.
    Keyboard and D-Pad movement is **not** smoothed — digital input is already binary and
    instant-response is preferable. Smoothing is applied in the `InputRouter` before
    dispatching `OnMove`.

11. **Input Blocking**: Certain game states block all gameplay input:
    - Cutscene playing (Cutscene System blocks Exploration and Combat maps)
    - Dialogue box open (UI map is active; Exploration/Combat inputs ignored)
    - Pause menu open (UI map is active)
    - Character is dead (Combat inputs ignored; switch to alive character still works)
    - Game Over screen (all inputs blocked except UI Submit/Cancel)

11. **Controller Support**: All actions have both keyboard and gamepad bindings. The
    system auto-detects the last-used input device and displays the correct button
    prompts in the HUD (keyboard keys vs. controller face buttons).

### States and Transitions

```
┌─────────────┐   combat starts    ┌─────────────┐
│ Exploration │ ──────────────────▶│   Combat    │
│   Map       │                    │     Map     │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       │       UI map active              │
       │◄──── (any modal open) ──────────►│
       │                                  │
       └──────────────────────────────────┘
                    UI map blocks both

State transitions:
  Exploration → Combat    : When CombatEncounterManager.IsInCombat becomes true
  Combat → Exploration    : When CombatEncounterManager.IsInCombat becomes false
  Any → UI                : When any menu/dialogue/cutscene opens
  UI → Previous           : When all modals close
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Combat System** | Read by | Reads `OnSkillPressed`, `OnSwitchToIndex` during combat encounters |
| **Character State Manager** | Read by | Reads `OnMove` for character movement input |
| **Character Switching** | Calls | Calls `InputRouter.FlushBuffer()` on switch initiation |
| **Cutscene System** | Called by | Cutscene System enables/disables input maps as needed |
| **Dialogue System** | Called by | Dialogue System activates UI map when dialogue starts |
| **Camera System** | Read by | Reads `OnCameraOrbit` for camera rotation input |
| **Audio System** | Calls | Triggers input confirmation sound (UI click) and menu whoosh |
| **Save / Load** | Read by | Reads player's custom keybindings (if remapped) on load |
| **Main Menu** | Read by | Reads `OnSubmit`, `OnNavigate` for menu navigation |
| **Combat HUD** | Read by | Reads input state to show button prompts (keyboard vs. controller) |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `InputBufferWindow` | `0.15s` | Maximum time a buffered input waits |
| `DeadZoneRadius` | `0.2` | Radial dead zone for analog sticks |
| `BufferOverwrite` | `latest input replaces previous` | Only one input buffered |
| `FlushOnSwitch` | `buffer = empty` | Hard reset, no exceptions |
| `InputLatency` | `< 1 frame` | Input → action must be same frame |

## Edge Cases

1. **Player mashes skills during long animation**: Each new press overwrites the buffer.
   Only the last press fires when the character is available. No queue, no multi-fire.

2. **Player presses switch + skill simultaneously**: The switch input is processed first
   (it flushes the buffer). The skill input is discarded. The player must press the skill
   again after the switch completes.

3. **Player holds movement while opening pause menu**: Movement input is ignored while the
   UI map is active. When the menu closes, any held movement input does NOT carry over
   (inputs are re-sampled on map re-enable).

4. **Controller disconnected mid-game**: The system falls back to keyboard/mouse defaults.
   No gameplay interruption — the player can continue with keyboard.

5. **Skill button pressed during invincibility frames**: Input is buffered. If the
   invincibility ends within 0.15s, the skill fires. Otherwise, the buffer expires
   harmlessly.

6. **Two players press buttons on the same keyboard**: Only Player 1's Input Actions are
   bound. This is a single-player game — second keyboard input is ignored by default.

7. **Input pressed during fade-to-black**: Inputs are buffered during the fade but flushed
   when the new scene loads (scene transition always flushes).

8. **Player remaps a key to Escape**: The Pause action still triggers. If the player is in
   a menu, Escape/Cancel closes the menu. If no menu is open, Pause opens. No conflict.

## Dependencies

- **Depends on**: Unity Input System package (`com.unity.inputsystem`)
- **Depended on by**: Character State Manager, Combat System, Character Switching, Camera
  System, Cutscene System, Dialogue System, Main Menu, Save / Load (keybindings),
  Audio System (input sounds), Combat HUD (button prompts)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `InputBufferWindow` | float | `0.15s` | Reduce to 0.1s for tighter feel, increase to 0.2s for accessibility |
| `DeadZoneRadius` | float | `0.2` | Increase if players report stick drift |
| `SwitchFlushWindow` | float | `0.3s` | Matches switch cooldown duration |
| `MoveSpeedSmoothing` | float | `0.1s` | Movement input smoothing to prevent jittery analog input |

## Visual/Audio Requirements

- **Input Sounds**: Subtle UI click sound when a skill button is pressed (barely audible,
  mixed under combat SFX)
- **Button Prompts**: HUD displays current input method's button labels (E vs. D-Pad Up,
  Tab vs. RB). Switches automatically when last-used device changes.
- **Input Feedback**: When a skill is buffered, the skill icon shows a subtle glow (0.15s
  max). This tells the player "your press was registered, waiting for cooldown."

## UI Requirements

- **Button Prompt Display**: Combat HUD shows the four skill buttons with the correct
  labels (keyboard: 1, 2, 3, 4 / gamepad: Square, Triangle, Circle, X)
- **Input Method Indicator**: Small icon in HUD corner showing current input device
  (keyboard or controller)
- **Settings Keybinding Screen**: Pause menu includes a keybinding configuration panel
  allowing remap of all Exploration and Combat actions

## Acceptance Criteria

- [ ] Exploration movement responds within 1 frame of input (no visible lag)
- [ ] Combat skill activation fires within 1 frame when character is available
- [ ] Input buffer holds input for 0.15s and fires when cooldown ends
- [ ] Switch1–4 inputs switch to the correct party member by slot index (0–3)
- [ ] Input buffer is flushed completely on character switch (no ghost skill fires)
- [ ] Dead zone prevents stick drift movement at rest
- [ ] Pause menu blocks all gameplay inputs while open
- [ ] Dialogue blocks all gameplay inputs while active
- [ ] Controller disconnect falls back to keyboard without gameplay interruption
- [ ] Button prompts in HUD match the last-used input device
- [ ] Cutscene playing blocks all input until complete
- [ ] Custom keybindings persist across game sessions (saved and loaded)

## Open Questions

- Should the movement input use acceleration ramp-up (starts at 50% speed, reaches 100%
  over 0.1s) for smoother feel, or instant response for snappy feel?
- Should we support input combo detection (press two skills in sequence) as an explicit
  mechanic, or keep combos as a Combat System concern that fires on any skill sequence?
