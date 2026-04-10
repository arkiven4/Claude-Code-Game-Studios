# Camera System

> **Status**: Designed
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Action-First Combat, Cinematic Presentation

## 1. Overview

The Camera System defines how the player perceives the game world and targets enemies during combat. Heavily inspired by modern Action RPGs (Elden Ring, Genshin Impact), it is built on Phantom Camera and features three primary modes: **Free Orbit** (player-controlled third-person camera), **Hard Lock-On** (rigid framing of the player and a specific enemy), and **Cinematic Burst** (temporary authored angles for ultimate skills). The camera is designed to give the player maximum situational awareness and control during standard gameplay while delivering high-impact visual flair during major abilities.

## 2. Player Fantasy

The Camera System serves the fantasy of **fluid, responsive action with moments of cinematic flair**. The player should feel completely in control of their view, able to scan the battlefield freely or focus intensely on a single duel. When combat is chaotic, the camera is a reliable tool for situational awareness. When a character unleashes their ultimate power, the camera briefly transforms the game into a high-budget anime, delivering the dramatic payoff the player earned, before snapping seamlessly back to the action.

**Reference models**: 
- *Elden Ring*: Responsive free-look, hard lock-on that keeps both combatants in frame, right-stick flick to switch targets.
- *Genshin Impact*: Soft auto-aiming during free-look, dynamic zooming, and brief authored cinematic cuts for Elemental Bursts.

## 3. Detailed Rules

1. **Three Camera States**:
   - **Free Orbit (Default)**: A third-person over-the-shoulder camera controlled entirely by the player's right stick (or mouse). It softly interpolates to align behind the character only when the player is moving forward without actively providing camera input.
   - **Target Lock-On**: Triggered by the "Target Lock" input. The camera rigidly frames the active character and the locked-on enemy. Pitch and yaw are automatically calculated to keep both entities on screen. Flicking the right stick switches the lock to the next nearest enemy in that direction.
   - **Cinematic Burst**: Triggered when a character activates a Tier 3 (Ultimate) skill. The camera cuts instantly to an authored animation (a Phantom Camera sequence) for 1–2 seconds, ignoring player input, before cutting back to the previous state.

2. **Target Lock-On Mechanics**:
   - Pressing the Target Lock button casts a sphere overlap (radius: 20 units) to find the nearest enemy relative to the center of the screen.
   - If an enemy is found, the state transitions to Target Lock-On.
   - If no enemy is found, the camera quickly resets its yaw to align perfectly behind the active character's forward facing direction.
   - Lock-on is broken if the enemy dies, moves out of maximum range (30 units), or the player presses the button again.

3. **Character Switching Camera**: 
   - When the player switches active characters, the camera smoothly interpolates from the old character to the new one over 0.4s. 
   - If the camera is in Free Orbit, it maintains its current yaw and pitch relative to the world during the transition.
   - If the camera is in Target Lock-On, it maintains the lock on the enemy while smoothly reframing around the newly active character.

4. **Camera Collision & Occlusion**: 
   - The camera raycasts from the target position (character's upper chest) to the camera position each frame. 
   - If an Environment collider blocks the line of sight, the camera physically glides forward along the ray to the nearest unobstructed position. It does *not* make the environment transparent.

5. **Camera Shake**: 
   - Triggered by the Hit Detection System, proportional to the damage dealt or received.
   - Shake intensity: `0.01 × (damage / casterATK)`, normalized to a 0–1 scale. 
   - Maximum shake: 0.3 units. Duration: 0.15s.

6. **Dead Character Camera**: 
   - When the active character dies, the camera immediately breaks lock-on.
   - The camera pans over 0.5s to the nearest living party member, and control is transferred.
   - If all party members are dead, the camera holds its position, orbiting slowly around the defeated character while the Game Over sequence plays.

## 4. Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `ShakeIntensity` | `0.01 × min(damage / casterATK, 1.0)` | Normalized to damage ratio |
| `ShakeDuration` | `0.15s` | Fixed duration for hits |
| `SwitchBlendTime` | `0.4s` | Smooth pan to new character |
| `LockOnMaxRange` | `30.0 units` | Distance at which lock-on breaks |
| `FOVOffset` | `playerSetting - 55°` | Player's FOV preference applied as offset |

## 5. Edge Cases

1. **Enemy moves directly above/below the player during Lock-On**: To prevent camera flipping (gimbal lock), the camera pitch is clamped between -20° and +60°. If the enemy moves outside this view frustum, the lock-on automatically disengages.
2. **Switching to a character far away (e.g., stuck on geometry)**: If the new character is more than 15 units away, the camera skips the 0.4s smooth blend and instead executes a 0.2s fade-to-black cut to prevent clipping through entire buildings.
3. **Lock-On target dies while player is mid-attack**: The camera immediately drops lock-on, returning to Free Orbit. The current attack continues targeting the location where the enemy died (soft-targeting takes over if another enemy is very close).

## 6. Dependencies

- **Depends on**: Phantom Camera package, Godot Input Map (for right stick/mouse orbit), Godot Physics (for camera collision raycasts).
- **Depended on by**: Combat System, Skill Execution System (triggers Cinematic Bursts), Character Switching, Hit Detection.

## 7. Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `FreeOrbitDistance` | float | `5.0` | Default distance behind character |
| `FreeOrbitHeight` | float | `1.5` | Default height offset above character root |
| `OrbitSensitivityX` | float | `2.0` | Mouse/Stick X-axis rotation speed |
| `OrbitSensitivityY` | float | `1.5` | Mouse/Stick Y-axis rotation speed |
| `LockOnTargetRadius`| float | `20.0` | Range to acquire a lock-on target |
| `LockOnBreakRadius` | float | `30.0` | Range at which lock-on auto-disengages |
| `CollisionRadius` | float | `0.2` | Thickness of the camera collision sphere |
| `DefaultFOV` | float | `55°` | Vertical FOV for all gameplay modes |

## 8. Acceptance Criteria

- [ ] Free Orbit camera responds smoothly to right stick / mouse input without snapping.
- [ ] Camera auto-aligns behind the player when moving forward without right-stick input.
- [ ] Pressing "Target Lock" frames the active character and the nearest enemy correctly on screen.
- [ ] Flicking the right stick while locked on switches targets fluidly.
- [ ] Camera glides forward when obstructed by environmental geometry to prevent wall-clipping.
- [ ] Activating a Tier 3 skill cuts to a cinematic camera sequence, then returns to gameplay.
- [ ] Switching characters smoothly blends the camera position without dropping the lock-on target.
- [ ] Target Lock breaks automatically if the enemy dies or moves out of range.
