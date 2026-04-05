# Character Switching System

> **Status**: Approved
> **Author**: Reverse-documented from ADR-0002 + CharacterSwitchController.cs, 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (switching is the core strategic expression)
> **Architecture Decision**: [ADR-0002](../../docs/architecture/adr-0002-character-switching-state-sync.md) — Distributed State model

## Overview

The Character Switching System enables the player to transfer input authority between
any alive party member in real-time during combat and exploration. Implemented as a
`CharacterSwitchController` MonoBehaviour located via `FindFirstObjectByType`, the
system manages a 0.3-second switch window during which the outgoing character transitions
to AI control and the incoming character is visually highlighted before accepting player
input. The system is built on the ADR-0002 Distributed State architecture: each party
member owns their HP, cooldowns, and effects permanently; switching transfers input
authority only, never state. No data is copied, serialized, or reconstructed on switch.
All four party members remain fully active and ticking whether or not the player controls
them. The switch is fast enough to feel instant but gated enough to prevent input bleed
and rapid-switch exploits.

## Player Fantasy

Character Switching serves the fantasy of **being everywhere at once**. The player
should feel that every companion is fighting alongside them — not waiting on the bench.
When Evelyn is overwhelmed by a magical enemy, switching to Evan feels like calling in
backup. When Evan needs a healer, switching to the Healer feels clutch. The player
reads the battlefield, picks the right character for the moment, and swaps in cleanly.
The switch feels snappy — a visual flash, a sound cue, and you're in control. No loading,
no menu, no delay. But it's not spammable — the 0.3s window prevents panic-switching
out of every bad situation. The player commits to their choice for a beat, reads the
consequences, and decides again.

**Reference model**: Final Fantasy VII Remake's real-time party switching (instant,
strategic, visual feedback) and Xenoblade Chronicles' driver swap (character stays
in the fight when you leave, cooldowns persist).

## Detailed Design

### Core Rules

1. **Single Active Controller**: Only one party member accepts player input at a time.
   The `CharacterSwitchController` tracks `_currentCharacter` and denies switch requests
   that target the current character.

2. **Distributed State (ADR-0002)**: Each party member has a `PartyMemberState` component
   that owns HP, MP, cooldowns, active effects, shield, invincibility, and control state.
   These values tick every frame for all party members regardless of who is player-controlled.
   The switch controller never reads or writes these values — it only changes `IsPlayerControlled`.

3. **Switch Guards**: A switch is rejected if any of the following are true:
   - Switch cooldown is active (`CanSwitch` is false)
   - Target is null
   - Target is already the current character
   - Target is dead (`!target.IsAlive`)

4. **Switch Sequence** (total: 0.3s):
   ```
   Frame 0:  SwitchTo(target) called
   Frame 0:  previous.SetPlayerControlled(false)     ← input revoked
   Frame 0:  previous.IPartyAgent.OnAIResumeControl() ← AI takes over
   Frame 0:  _switchCooldownRemaining = 0.3s
   Frame 0:  StartCoroutine(CompleteSwitch(previous, target))

   Frame N:  (0.3s later)
   Frame N:  target.SetPlayerControlled(true)         ← input granted
   Frame N:  target.IPartyAgent.OnPlayerTakeControl() ← AI yields
   Frame N:  _currentCharacter = target
   Frame N:  OnCharacterSwitched.Invoke(previous, target)
   ```

5. **Switch Window (0.3s)**: The 0.3-second window serves three purposes:
   - **Input bleed prevention**: The button press that triggered the switch is flushed,
     preventing it from also firing a skill on the new character
   - **Rapid-switch protection**: The cooldown prevents the player from spam-switching
     to avoid all incoming damage
   - **Visual feedback**: The incoming character plays a brief highlight effect so the
     player knows who they're now controlling

6. **IPartyAgent Callbacks**: Every party member has an `IPartyAgent` component. On switch:
   - **Outgoing character**: `OnAIResumeControl(PartyMemberContext)` — the AI agent receives
     a snapshot of current state and resumes autonomous behavior within 1 frame
   - **Incoming character**: `OnPlayerTakeControl()` — the AI agent yields control and stops
     making decisions until the player switches away again
   - The `PartyMemberContext` includes: self reference, all allies, all active enemies,
     and the current combat encounter reference

7. **Party Member Array**: The controller holds a serialized `_partyMembers` array of up to
   4 `PartyMemberState` references. This array is set in the scene/inspector and does not
   change at runtime. Party composition changes (characters joining/leaving the party
   permanently) are handled by the Chapter State System loading new scenes with different
   party members.

8. **SwitchToIndex Convenience**: `SwitchToIndex(int index)` is a convenience wrapper that
   looks up the party member at the given array index and calls `SwitchTo()`. This is the
   primary API for keybind input (press "1" for party slot 0, "2" for slot 1, etc.).

9. **OnCharacterSwitched Event**: After the switch window completes, the `OnCharacterSwitched`
   event fires with `(previousCharacter, newCharacter)`. Subscribers include:
   - **Camera System**: Pans the camera to the new character
   - **Combat HUD**: Updates the active character indicator
   - **Combat System**: Updates combo window tracking (combos persist across switches)
   - **Audio System**: Plays the character switch sound cue

10. **No State Transfer**: This is the cardinal rule. HP, cooldowns, buffs, position,
    animation state — all remain on the original character's GameObject. The switch
    controller is a traffic cop, not a state manager.

### States and Transitions

```
              ┌─────────────────────────┐
              │   Player Controlled     │  ← IsPlayerControlled = true
              │   (accepts input)       │  ← IPartyAgent yielded
              └──────────┬──────────────┘
                         │ SwitchTo(other)
                         ▼
              ┌─────────────────────────┐
              │   AI Controlled         │  ← IsPlayerControlled = false
              │   (IPartyAgent active)  │  ← Full state ticking
              └──────────┬──────────────┘
                         │ SwitchTo(this)
                         ▼
              ┌─────────────────────────┐
              │   Switch Window (0.3s)  │  ← Highlight FX playing
              │   (not yet controllable)│  ← AI still active until complete
              └──────────┬──────────────┘
                         │ window expires
                         ▼
              ┌─────────────────────────┐
              │   Player Controlled     │  ← Full input authority
              └─────────────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Character State Manager** | Reads/Writes | Calls `SetPlayerControlled()`, reads `IsAlive` for guard |
| **Input System** | Calls | Calls `InputRouter.FlushBuffer()` on switch (prevents ghost input) |
| **Combat System** | Read by | Reads `CurrentCharacter` and `IsInCombat` (switching may be blocked in certain encounters) |
| **Camera System** | Read by | Camera pans to new character on `OnCharacterSwitched` |
| **Party AI System** | Calls | `OnAIResumeControl()` and `OnPlayerTakeControl()` on `IPartyAgent` |
| **Combat HUD** | Read by | Updates active character highlight, button prompts |
| **Audio System** | Calls | Triggers switch sound cue on `OnCharacterSwitched` |
| **Save / Load** | Read by | Saves/restores which character was player-controlled |
| **Health & Damage** | Read by | Reads `IsPlayerControlled` for input-specific effects |
| **Skill Execution** | Read by | Reads `IsPlayerControlled` to determine if skill was player or AI initiated |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `SwitchWindowDuration` | `0.3s` | Fixed duration from ADR-0002 |
| `SwitchCooldown` | `= SwitchWindowDuration` | Cooldown matches the window |
| `CanSwitch` | `_switchCooldownRemaining <= 0` | Guard check |
| `IsAlive` | `CurrentHP > 0` | Cannot switch to dead characters |

## Edge Cases

1. **Target dies during switch window**: If the target character is killed during the
   0.3s window, the `CompleteSwitch` coroutine checks `target.IsAlive` after the wait
   and aborts if the target is dead. The previous character remains without player
   control — the player must select a new target. `_switchCooldownRemaining` is not
   refunded (the attempt still costs the cooldown).

2. **Rapid switch attempts (every 0.1s)**: The 0.3s cooldown prevents this. Each
   attempt during cooldown is silently ignored. No state corruption.

3. **Switch during skill animation on the outgoing character**: The outgoing character's
   skill animation continues playing (it's not canceled). The AI resumes control and
   the animation completes or transitions to the AI's next action. The incoming character
   starts from idle or their current AI pose.

4. **All party members except one are dead**: The player can only switch to the one alive
   member. If that member is already active, switch is a no-op (guarded by "target is
   already current" check).

5. **Party wipe (all dead)**: The `Start()` method fails to find an alive member and
   logs an error. The Game Over state is handled by the Health & Damage System, which
   triggers before switching becomes relevant.

6. **Switch during a party-wide enemy attack**: The switch goes through normally. The
   incoming character takes the hit (they're at their current position with their current
   HP). No invincibility granted during the switch window — the 0.3s is a visual cue,
   not a dodge.

7. **Party member joins/leaves mid-chapter**: The `_partyMembers` array is set at scene
   load and doesn't change dynamically. If the party composition changes, the Chapter
   State System loads a new scene with a new array. No runtime array modifications.

8. **IPartyAgent component missing on a party member**: The switch still works — the
   `?.` null-conditional operator on the `GetComponent<IPartyAgent>()` call means the
   callback is simply skipped. A warning is logged. The character switches but has no
   AI behavior when not player-controlled.

## Dependencies

- **Depends on**: Character State Manager (`PartyMemberState`), Input System
  (input buffer flushing), Party AI System (`IPartyAgent`, `PartyMemberContext`),
  Combat System (encounter state), ADR-0002
- **Depended on by**: Camera System, Combat HUD, Combat System, Audio System,
  Save / Load System, Skill Execution System

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `SwitchWindowDuration` | float | `0.3s` | Reduce to 0.15s for faster feel; increase to 0.5s for clarity |
| `PartySizeMax` | int | `4` | Max party members in the array |

## Visual/Audio Requirements

- **Switch Highlight FX**: The incoming character plays a brief (0.3s) highlight effect —
  a white flash ring around the character, like FFXVII Remake's switch indicator
- **Switch Sound**: A short whoosh/click sound (0.2s) on switch completion, mixed under
  combat SFX
- **Switch Cooldown Indicator**: If the player attempts to switch during cooldown, the
  Combat HUD shows a brief "wait" flash (optional — visual feedback for rejected input)

## UI Requirements

- **Combat HUD Active Indicator**: The currently controlled character's portrait is
  highlighted (bright border, others are dimmed)
- **Switch Prompt**: HUD shows F1–F4 (keyboard) or D-Pad directions (gamepad) mapped to each party slot
- **Party Member Status**: HUD shows alive/dead status for each party member (dead
  members cannot be switched to)

## Acceptance Criteria

- [ ] Switching transfers input authority in exactly one frame after the 0.3s window
- [ ] Outgoing character's AI resumes within 1 frame (no idle gap)
- [ ] Incoming character's AI yields within 1 frame (no conflicting input)
- [ ] Switch is rejected when target is dead, null, already active, or on cooldown
- [ ] Input buffer is flushed on switch (no ghost skill fires on new character)
- [ ] Rapid switching (every 0.1s) is prevented by cooldown — no state corruption
- [ ] Switch during skill animation: old character's animation completes or transitions
  cleanly; new character starts from idle or current AI pose
- [ ] `OnCharacterSwitched` event fires with correct previous and new character
- [ ] All four party members' state continues ticking during and after switch
- [ ] No HP, cooldown, or effect data is copied or moved during switch
- [ ] Switch highlight FX plays for 0.3s and completes before input is accepted
- [ ] Target death during switch window aborts the switch cleanly (no null references,
  player must re-select)

## Open Questions

- Should the switch window grant brief invincibility (0.1s) to the incoming character
  to prevent punishing switches during enemy wind-ups? This would make switching feel
  safer but reduce the strategic risk of mistimed switches.
- Should we support switching to a specific character by name/role rather than by array
  index? This would require a party roster UI (tap to switch to Evan specifically) rather
  than cyclic next/prev.
