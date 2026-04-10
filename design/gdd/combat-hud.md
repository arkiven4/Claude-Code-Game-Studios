# Combat HUD

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (the HUD makes the party state readable at a glance)

## Overview

The Combat HUD is the player's real-time window into the combat state. Built with Unity
UI Toolkit, it displays party member HP/MP bars, active skill cooldowns, the currently
controlled character indicator, enemy HP bars (world-space), skill combo windows,
damage/heal numbers (world-space floating text), and contextual button prompts. The HUD
is screen-space for player information and world-space for enemy information. It reads
from the Character State Manager, Combat System, Health & Damage System, and Skill
Execution System but never writes to them. The HUD is a pure view — it observes state
and renders it. It hides during cutscenes and dialogue, appears during combat and
exploration (with reduced information outside combat), and updates every frame with no
visible lag between state change and display.

## Player Fantasy

The Combat HUD serves the fantasy of **always knowing what's going on**. The player
should be able to glance at the HUD and instantly know: who's healthy, who's in danger,
which skills are ready, who they're controlling, and what the enemies look like. No
menu-diving, no guesswork. The HUD is clean and minimal — it shows what matters and
stays out of the way. It doesn't obscure the action. Damage numbers fly off enemies
like a satisfying slot machine. Combo windows feel exciting. The active character
pops out visually. The HUD is the dashboard of a car you're driving at high speed —
everything you need, nothing you don't.

**Reference model**: Final Fantasy VII Remake's clean party status display (HP/MP bars
always visible, skill bar contextual), Devil May Cry's stylish combat feedback (combo
counter, rank display), and Hollow Knight's minimal HUD (information without clutter).

## Detailed Design

### Core Rules

1. **Screen-Space Party Panel** (top-left corner):
   - Displays all 4 party members as stacked horizontal cards
   - Each card shows:
     - Character portrait thumbnail (32x32)
     - Character name (TextMeshPro)
     - HP bar (green → yellow → red gradient based on HP%)
     - MP bar (blue gradient)
     - Status effect icons (buffs on top row, debuffs on bottom row)
   - The currently player-controlled character's card is highlighted:
     - Bright border (gold glow)
     - Slightly larger (110% scale)
     - Other characters' cards are dimmed (80% opacity)
   - Dead characters' cards are grayed out with a skull icon

2. **Skill Bar** (bottom-center of screen):
   - Displays 4 skill slots for the currently controlled character
   - Each skill button shows:
     - Skill icon (from `SkillDataSO`)
     - Cooldown overlay (radial fill from full to empty)
     - Skill name (small text below button)
     - Key binding label (1, 2, 3, 4 / Square, Triangle, Circle, X)
   - Skills on cooldown are grayed out with the remaining time displayed as text
   - Skills with insufficient MP show a red MP warning icon
   - Skills with charges show a charge counter badge (e.g., "×3")
   - Charge-based skills show a recharge progress bar below the button

3. **Combo Window Indicator** (above skill bar):
   - When a combo window is open (Combat System), a small horizontal bar appears showing:
     - The last skill used (icon on the left)
     - An arrow "→"
     - The required next skill (icon on the right)
     - A timer bar that shrinks as the 1.5s window expires
   - When the combo is completed, a "COMBO!" text flashes for 0.5s
   - If the window expires without completion, the indicator fades out

4. **World-Space Enemy HP Bars** (above enemy models):
   - Each active enemy has a world-space HP bar rendered above their model
   - The HP bar uses a Billboard component to always face the camera
   - HP bar color: green (>50%), yellow (10-50%), red (<10%)
   - Enemy name is displayed above the HP bar
   - Boss enemies have a larger, screen-space HP bar at the bottom-center of the screen
     (in addition to the world-space bar)
   - Dead enemies' HP bars fade out over 0.5s then disappear

5. **Floating Damage/Heal Numbers** (world-space, above targets):
   - Damage numbers fly upward from the target's position and fade out over 1.0s
   - Color-coded by damage type: Physical (white), Magical (blue), Holy (yellow),
     Dark (purple)
   - Critical hits are 2x font size with a brief flash effect
   - Heal numbers are green with a "+" prefix
   - Shield absorption numbers are gray with a shield icon prefix
   - "Miss" / "Immune" indicators are white with no upward motion (static text)
   - Maximum concurrent floating numbers: 20 (oldest are culled if exceeded)

6. **Input Method Indicator** (top-right corner):
   - Small icon showing the current input device: keyboard (WASD icon) or controller
     (gamepad icon)
   - Updates automatically when the last-used input device changes
   - Determines the button prompt labels on the skill bar

7. **HUD Visibility Rules**:
   | Game State | HUD Visibility |
   |------------|---------------|
   | Exploration | Party panel (HP/MP only, no cooldowns), no skill bar, no combo |
   | Combat | Full HUD (all elements active) |
   | Dialogue | HUD hidden |
   | Cutscene | HUD hidden |
   | Pause Menu | HUD frozen behind menu |
   | Game Over | HUD hidden, Game Over overlay shown |

8. **Damage Number Pooling**: Floating text objects are pooled (max 20). When the pool
   is exhausted, the oldest floating text is recycled. This prevents GC allocation
   during heavy combat.

9. **Passive Icon Row** (below skill bar):
   - Displays unlocked passive icons for the currently active character in a horizontal row
   - Icons sourced from `PassiveUnlock.Icon` on the character's `CharacterDataSO`
   - Only **unlocked** passives are shown (locked passives are hidden, not grayed out)
   - Hovering over a passive icon shows a tooltip with the passive description
   - When a passive unlocks mid-combat, the new icon appears with a 0.5s glow-in animation
   - Maximum 6 icons (matching the max passives per main character); generic party members
     show 3–4 icons
   - This row is sourced from the Character Skill System and is read-only (no click action)

10. **No HUD Writes to Game State**: The Combat HUD is read-only. It subscribes to
   events from gameplay systems and updates its display. Clicking a skill button on
   the HUD does NOT directly activate the skill — the Input System routes the button
   press, and the Skill Execution System handles activation. The HUD is visual only.

### States and Transitions

```
┌────────────┐  combat starts   ┌─────────────┐
│ Exploration│ ────────────────▶│   Combat    │
│   HUD      │                  │     HUD     │
│ (minimal)  │                  │   (full)    │
└─────┬──────┘                  └──────┬──────┘
      │               dialogue/cutscene │
      │◄───────────────────────────────┤
      │         HUD hidden             │
      └────────────────────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Character State Manager** | Reads | Party member HP, MP, control state, alive/dead, status effects |
| **Combat System** | Reads | IsInCombat, combo window state, encounter state |
| **Skill Execution** | Reads | Skill cooldowns, charge counts, MP costs, skill icons |
| **Health & Damage** | Reads | Damage amounts, heal amounts, critical flags (for floating text) |
| **Hit Detection** | Reads | Hit positions (for floating text spawn point) |
| **Character Switching** | Reads | Current character, switch events (for highlight update) |
| **Input System** | Reads | Current input device (for button prompt labels) |
| **Enemy AI** | Reads | Enemy HP, enemy names, boss flags (for enemy HP bars) |
| **Combat HUD** | Calls Audio System | Optional sound on combo completion |
| **Camera System** | Read by | Camera mode affects HUD visibility (hidden during cutscenes) |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `HPBarColor` | `HP% > 0.5 → lerp(yellow, green, (HP% − 0.5) / 0.5)`; `HP% ≤ 0.5 → lerp(red, yellow, HP% / 0.5)` | Three-step gradient: green above 50%, yellow at 50%, red below 50% |
| `MPBarColor` | `blue` with alpha = `currentMP / maxMP` | Blue fill |
| `CooldownFill` | `remainingCooldown / totalCooldown` | Radial fill, full→empty |
| `FloatingTextLifetime` | `1.0s` | Time before floating text fades |
| `FloatingTextMaxConcurrent` | `20` | Pool size for floating text |
| `BossHPBarThreshold` | `isBoss == true` | Bosses get screen-space HP bar |
| `DeadCardOpacity` | `0.5` | Grayed-out dead character card |
| `ActiveCardScale` | `1.1x` | Active character card is 10% larger |
| `ComboWindowTimer` | `1.5s default` | Shrinks to show remaining time |

## Edge Cases

1. **Party has fewer than 4 members**: Only active members are displayed. The party
   panel shrinks to fit the number of members (1-4 cards). No empty slots shown.

2. **Floating text exceeds 20 concurrent**: Oldest floating texts are immediately
   recycled to make room for new ones. The player may not see old damage numbers, but
   the current combat state is always visible.

3. **Character switches during heavy combat**: The HUD updates the active character
   highlight within 1 frame. The skill bar swaps to the new character's skills
   immediately. No lag between switch and display update.

4. **Enemy dies and spawns loot simultaneously**: The enemy HP bar fades out over 0.5s.
   The floating death damage number plays and fades normally. Loot drops are handled
   by the Loot System (separate from HUD).

5. **Boss HP bar overlaps with Combat HUD skill bar**: The boss HP bar is positioned
   above the skill bar (bottom-center, but higher). Both are visible. If the boss bar
   and skill bar conflict, the skill bar shifts up by 40px to avoid overlap.

6. **Status effect icons overflow the card**: Maximum 4 buff icons and 4 debuff icons
   per character card. If more effects are active, only the first 4 of each type are
   shown. A "..." indicator appears if effects are hidden.

7. **Player has FOV set to extreme value**: The world-space enemy HP bars may appear
   very large (low FOV) or very small (high FOV). The billboard scale is adjusted
   based on camera distance to maintain readability.

8. **Resolution changes at runtime**: The HUD resizes to the new resolution. Screen-
   space elements re-anchor. World-space elements are unaffected. No UI elements are
   clipped or overflow.

## Dependencies

- **Depends on**: Character State Manager, Combat System, Skill Execution, Health &
  Damage, Hit Detection, Character Switching, Input System, Enemy AI, Audio System
  (combo completion sound), Character Skill System (passive icons), Godot UI,
  TextMeshPro
- **Depended on by**: Save / Load (HUD settings like damage number visibility)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `FloatingTextLifetime` | float | `1.0s` | How long damage numbers stay visible |
| `FloatingTextMaxConcurrent` | int | `20` | Pool size for floating text |
| `PartyPanelWidth` | float | `280px` | Width of each character card |
| `SkillButtonSize` | float | `64px` | Size of each skill button |
| `BossHPBarHeight` | float | `40px` | Height of the boss screen-space HP bar |
| `StatusEffectIconMax` | int | `4+4` | Max buff + debuff icons shown |
| `ComboIndicatorYOffset` | float | `40px` | How far above skill bar the combo indicator appears |

## Visual/Audio Requirements

- **Party Cards**: Rounded rectangle panels with portrait, name, HP bar, MP bar, and
  status effect icons. Gold glow border for active character. Gray overlay for dead.
- **Skill Buttons**: Square buttons with icon, cooldown radial overlay, and key label.
- **Floating Text**: World-space TextMeshPro text with color per damage type, upward
  animation, and fade-out.
- **Boss HP Bar**: Screen-space bar at bottom-center, styled distinctively (ornate
  border, boss name centered above).
- **Combo Sound**: Subtle "chime" sound when a combo is completed (mixed under SFX).

## UI Requirements

- **UI Toolkit UXML Layout**: The Combat HUD is defined in a `.uxml` file with
  responsive anchors. Party panel anchors top-left. Skill bar anchors bottom-center.
  Input method indicator anchors top-right.
- **Damage Number USS Styles**: USS file defines font size, colors per damage type,
  animation curves for floating text.
- **HUD Settings**: Pause menu includes toggle for damage numbers visibility
  (show/hide) and damage number size (small/normal/large).

## Acceptance Criteria

- [ ] Party panel shows correct HP, MP, status effects for all 4 party members
- [ ] Active character card is visually highlighted (gold glow, 110% scale)
- [ ] Dead characters' cards are grayed out with skull icon
- [ ] Skill bar shows correct skills for the active character with accurate cooldowns
- [ ] Skills on cooldown show remaining time and are grayed out
- [ ] Skills with insufficient MP show red warning
- [ ] Combo window indicator appears, shrinks with timer, and shows "COMBO!" on success
- [ ] Enemy HP bars follow enemies in world-space and face the camera
- [ ] Boss enemies have a screen-space HP bar at bottom-center
- [ ] Damage numbers display in correct color per damage type, float upward, and fade in 1.0s
- [ ] Critical hit numbers are 2x size with flash effect
- [ ] Heal numbers are green with "+" prefix
- [ ] Floating text pool recycles at 20 concurrent (no allocation)
- [ ] HUD hides during dialogue and cutscenes
- [ ] HUD updates within 1 frame of state change (no visible lag)
- [ ] Input method indicator shows correct device (keyboard/controller)
- [ ] Passive icon row displays below skill bar with correct unlocked icons for the active character
- [ ] Passive icon tooltip shows correct description on hover
- [ ] Passive unlock glow-in animation plays when a passive unlocks mid-combat
- [ ] HUD does not write to game state (read-only view)

## Open Questions

- Should the HUD support a minimalist mode for experienced players (hide damage numbers,
  simplify party cards)? This would be a settings toggle.
- Should we add a threat meter display for Tanker characters (shows which party member
  each enemy is targeting)? Useful for tank gameplay but adds HUD clutter.
- Should floating damage numbers stack vertically when multiple hits land simultaneously,
  or fan out horizontally? Vertical stacking is cleaner; horizontal fanning is more
  readable for multi-hits.
