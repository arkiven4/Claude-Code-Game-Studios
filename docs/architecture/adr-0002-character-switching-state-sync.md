# ADR-0002: Character Switching — State Synchronization Architecture

## Status
Accepted

## Date
2026-04-03

---

## Context

### Problem Statement

The player can switch control between any active party member in real-time during
combat. At the moment of a switch, several questions must be answered by the
architecture:

- Where does each character's HP, cooldowns, and active buffs/debuffs live?
- What happens to those values during and after a switch?
- How does the game transfer "player authority" from one character to another without
  animation glitches, state corruption, or input bleed?
- How does the Party AI resume cleanly when the player leaves a character?

This decision must be made before implementing the Combat System, Character State
Manager, or Party AI System — all three depend on this architecture.

### Constraints

- **All party members fight simultaneously**: Non-active party members are controlled
  by AI and take damage, use skills, and accumulate buffs in real time. Their state
  is always live, not frozen.
- **Switch must feel instant and clean**: The player should never feel a stutter,
  ghost input, or state inconsistency after switching.
- **Unity 6.3 MonoBehaviour architecture**: The solution must work within Unity's
  component model without requiring DOTS/ECS (too complex for this scope).
- **IPartyAgent interface**: Any switching solution must be compatible with the
  `IPartyAgent` interface defined in ADR-0001 (RL or BT agents).
- **Timeline**: Month 1 MVP. This must be prototypable with 2 characters before
  the full party roster exists.

### Requirements

- Each character maintains independent HP, skill cooldowns, and status effects at all times
- Switching must transfer input authority in ≤ 1 frame (no perceptible delay)
- A brief "switch window" animation (≤ 0.3s) during which the new character is
  highlighted but not yet fully controllable is acceptable
- No state must be copied, serialized, or reconstructed on switch — only authority changes
- The leaving character must seamlessly hand off to AI control with no behavioral gap
- The arriving character must seamlessly resume from wherever it was (position, facing,
  mid-animation) with no teleport or reset
- Input buffering during the switch window must be discarded (no ghost attacks)

---

## Decision

**Use a Distributed State model: each party member owns and maintains their own
state at all times. The `CharacterSwitchController` only transfers input authority —
it never copies, moves, or reconstructs state.**

All party members are always-active GameObjects in the scene. HP drains, cooldowns
tick, and buffs expire for every character whether or not the player controls them.
A switch is nothing more than:
1. Remove `PlayerInputHandler` authority from the old character
2. Activate `PlayerInputHandler` authority on the new character
3. Notify the old character's `IPartyAgent` to resume AI control
4. Play a brief switch visual/audio cue

No state transfer. No snapshots. No serialization.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Active Scene (always live)                    │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │    Evelyn        │  │      Evan        │  │   Archer A   │  │
│  │                  │  │                  │  │              │  │
│  │  PartyMemberState│  │  PartyMemberState│  │PartyMemberState  │
│  │  HP: 85/100      │  │  HP: 100/100     │  │ HP: 72/100   │  │
│  │  Cooldowns: [..]  │  │  Cooldowns: [..] │  │ Cooldowns:[.]│  │
│  │  Buffs: [Regen]  │  │  Buffs: []       │  │ Buffs: []    │  │
│  │                  │  │                  │  │              │  │
│  │  PlayerInput:    │  │  PlayerInput:    │  │ PlayerInput: │  │
│  │  ★ ACTIVE        │  │  ○ disabled      │  │ ○ disabled   │  │
│  │                  │  │                  │  │              │  │
│  │  IPartyAgent:    │  │  IPartyAgent:    │  │ IPartyAgent: │  │
│  │  ○ yielded       │  │  ★ RUNNING       │  │ ★ RUNNING    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────┐                      │
│  │       CharacterSwitchController       │                      │
│  │  currentCharacter: Evelyn             │                      │
│  │  SwitchTo(target) → transfers authority                      │
│  │  switchCooldown: 0.3s                 │                      │
│  └───────────────────────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘

Switch sequence (SwitchTo(Evan)):
  Frame 0: SwitchController.SwitchTo(Evan)
  Frame 0: Evelyn.PlayerInputHandler.Disable()        ← no more input
  Frame 0: Evelyn.IPartyAgent.OnAIResumeControl()     ← AI takes over
  Frame 0: Evelyn.Animator → transition to AI-idle
  Frame 0: Evan.SwitchHighlight.Play()                ← visual cue (0.3s)
  Frame 0: SwitchController.switchCooldown = 0.3s     ← prevent rapid spam
  Frame N: (0.3s later) Evan.PlayerInputHandler.Enable() ← player now controls Evan
  Frame N: Evan.IPartyAgent.OnPlayerTakeControl()     ← AI yields
  Frame N: Input buffer flushed                       ← no ghost attacks
```

### Key Interfaces

```csharp
// Lives on every party member GameObject.
// Owns ALL state for that character — never copied elsewhere.
public class PartyMemberState : MonoBehaviour
{
    [field: SerializeField] public float MaxHP { get; private set; }
    public float CurrentHP { get; private set; }

    // Cooldowns keyed by skill index — tick every Update() regardless of control state
    public float[] SkillCooldowns { get; private set; }

    // Active buffs/debuffs — tick every Update() regardless of control state
    public List<StatusEffect> ActiveEffects { get; private set; }

    public CharacterRole Role { get; private set; }
    public bool IsPlayerControlled { get; private set; }

    // Called by CharacterSwitchController only — never set directly
    public void SetPlayerControlled(bool value) => IsPlayerControlled = value;
}

// Lives on every party member GameObject.
// Enabled/disabled by CharacterSwitchController to transfer input authority.
public class PlayerInputHandler : MonoBehaviour
{
    // Reads from Unity Input System actions
    // When disabled: all input ignored, buffer flushed on re-enable
    private void OnEnable() => FlushInputBuffer();
    private void OnDisable() => FlushInputBuffer();
}

// Singleton — one per scene. Manages which character the player controls.
public class CharacterSwitchController : MonoBehaviour
{
    public PartyMemberState CurrentCharacter { get; private set; }

    [SerializeField] private float _switchWindowDuration = 0.3f;
    private float _switchCooldownRemaining;

    public bool CanSwitch => _switchCooldownRemaining <= 0f;

    public void SwitchTo(PartyMemberState target)
    {
        if (!CanSwitch || target == CurrentCharacter) return;

        // Step 1: Disable input on current character
        CurrentCharacter.GetComponent<PlayerInputHandler>().enabled = false;
        CurrentCharacter.SetPlayerControlled(false);

        // Step 2: Resume AI on current character
        CurrentCharacter.GetComponent<IPartyAgent>()
            .OnAIResumeControl(BuildContext(CurrentCharacter));

        // Step 3: Start switch window on target (visual only, no input yet)
        target.GetComponent<SwitchHighlightFX>().Play(_switchWindowDuration);
        _switchCooldownRemaining = _switchWindowDuration;

        // Step 4: After switch window, transfer authority to target
        StartCoroutine(CompleteSwitch(target));
    }

    private IEnumerator CompleteSwitch(PartyMemberState target)
    {
        yield return new WaitForSeconds(_switchWindowDuration);

        target.SetPlayerControlled(true);
        target.GetComponent<IPartyAgent>().OnPlayerTakeControl();
        target.GetComponent<PlayerInputHandler>().enabled = true;

        CurrentCharacter = target;
    }
}
```

### State Ownership Summary

| State | Lives On | Ticks When | Never Copied |
|-------|----------|-----------|--------------|
| HP | `PartyMemberState` | Always | ✓ |
| Skill cooldowns | `PartyMemberState` | Always | ✓ |
| Status effects | `PartyMemberState` | Always | ✓ |
| Position | `Transform` | Always (physics) | ✓ |
| Animation state | `Animator` | Always | ✓ |
| Input authority | `PlayerInputHandler.enabled` | Only when player-controlled | ✓ |
| AI authority | `IPartyAgent` active | Only when AI-controlled | ✓ |

---

## Alternatives Considered

### Alternative 1: Centralized State Manager (singleton holds all state)

- **Description**: A `PartyStateManager` MonoBehaviour holds HP, cooldowns, and
  buffs for all characters in arrays. Characters read/write from it via character index.
- **Pros**: All state in one place, easier to inspect in editor; simpler serialization
  for save/load
- **Cons**:
  - Single point of failure — a bug in the manager corrupts all characters
  - Characters are data containers with no ownership; harder to reason about
  - Requires index-based access (fragile if party order changes)
  - Serialization requires one large object graph instead of per-character components
- **Rejection Reason**: Distributed ownership is more Unity-idiomatic, more debuggable
  (select the character in the hierarchy, see their state), and safer. Save/load can
  serialize each `PartyMemberState` independently.

### Alternative 2: Snapshot on Switch (freeze/restore state)

- **Description**: When switching away from a character, snapshot their state to a
  struct. Disable the GameObject. When switching back, restore the snapshot and
  re-enable.
- **Pros**: Lighter at runtime — only one character is active
- **Cons**:
  - Party AI cannot run on disabled GameObjects — breaks the core design requirement
    that non-active party members fight autonomously
  - State can desync if snapshot is stale (e.g., a DOT ticked after snapshot was taken)
  - Re-enabling a complex character with animation state causes hitches
- **Rejection Reason**: Incompatible with "all party members fight simultaneously."
  Dismissed immediately.

### Alternative 3: Immediate switch (no switch window)

- **Description**: Switch is instant — one frame, full input authority transferred,
  no animation window.
- **Pros**: Simplest implementation; no coroutine needed
- **Cons**:
  - Input bleed: button press that triggered the switch also fires as an attack on
    the new character
  - No visual feedback — player may not know who they're now controlling
  - Rapid-switching exploits (spam-switching to avoid all damage)
- **Rejection Reason**: The 0.3s switch window is a safety mechanism, not a restriction.
  It prevents input bleed and rapid-switch exploits while providing readable feedback.

---

## Consequences

### Positive

- State is always authoritative and current — no desync possible between "real" and
  "stored" state
- All party members fight autonomously while player controls one — supports the core
  gameplay loop
- Debugging is intuitive: select any character in the Unity hierarchy, see their
  full state in the Inspector
- Save/Load only needs to serialize `PartyMemberState` per character — no central
  manager to serialize
- Switch cooldown (0.3s) prevents rapid-switch exploits and input bleed

### Negative

- All character GameObjects are always active — slightly higher constant CPU/memory
  cost than disabling non-active characters
- Coroutine-based switch window adds slight complexity vs. immediate switch
- `PlayerInputHandler` enable/disable must flush input buffer correctly or ghost
  inputs will occur — requires careful implementation

### Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Input bleed on switch (attack fires on new character) | Medium | Medium | Flush input buffer in `PlayerInputHandler.OnEnable()` |
| AI resumes in wrong state after player leaves | Medium | High | `OnAIResumeControl()` passes current `PartyMemberContext` — AI rebuilds its intent from live state |
| Switch cooldown prevents defensive switching | Low | Low | 0.3s is short; tune down to 0.15s if playtesting shows frustration |
| Status effect ticking on all characters causes performance issues (large party) | Low | Low | Party is capped at 4 active members; effect count per character is small |
| Animator state on non-controlled character gets stuck | Medium | Medium | AI animator transitions always lead to recoverable states (idle, attack loop) — no dead-end states |

---

## Performance Implications

- **CPU**: 4 always-active characters × (HP update + cooldown tick + effect tick) per
  frame ≈ negligible. All operations are simple float arithmetic.
- **Memory**: 4 `PartyMemberState` components in memory at all times — tiny.
- **Rendering**: All 4 character meshes rendered regardless of control state.
  Use LOD if performance budget requires it (unlikely for stylized 3D).
- **Load Time**: No additional load time — all party members loaded with the scene.

---

## Migration Plan

New system — no existing code to migrate.

**Implementation order:**
1. Create `PartyMemberState` component with HP, cooldowns, effects
2. Create `PlayerInputHandler` with flush-on-toggle
3. Create `CharacterSwitchController` with `SwitchTo()` and coroutine window
4. Prototype with Evelyn + Evan only (2 characters sufficient to validate)
5. Verify: switch mid-attack, switch while Evelyn is under a DOT, switch rapidly
6. Integrate `IPartyAgent` callbacks (`OnPlayerTakeControl`, `OnAIResumeControl`)
7. Expand to full party once 2-character prototype is clean

---

## Validation Criteria

- [ ] Switching from Evelyn to Evan while Evelyn has a DOT: DOT continues ticking on
  Evelyn after switch — her HP updates correctly while player controls Evan
- [ ] Switching during a skill animation: old character completes or cancels the
  animation gracefully; new character starts from idle or current AI pose
- [ ] Input buffer flush: pressing the switch button does NOT fire an attack on the
  newly controlled character
- [ ] Rapid switching (switch every 0.1s): switch cooldown prevents it; no state
  corruption after repeated switch attempts
- [ ] AI resume: after player leaves a character, AI begins acting within 1 frame —
  no idle gap
- [ ] 4-character party: all 4 characters' HP, cooldowns, and effects update correctly
  simultaneously during a 60-second combat encounter

---

## Related Decisions

- **ADR-0001**: `docs/architecture/adr-0001-party-ai-rl-vs-behavior-tree.md` —
  defines `IPartyAgent` interface used by `CharacterSwitchController`
- **Systems Index**: `design/gdd/systems-index.md` — Character Switching System (#22),
  Character State Manager (#21), Party AI System (#23)
- **Next ADR candidate**: ADR-0003 — Save/Load architecture (what gets serialized,
  when, and in what format — affects Character State, Chapter State, and Inventory)
