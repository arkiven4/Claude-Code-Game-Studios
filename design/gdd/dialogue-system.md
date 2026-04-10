# Dialogue System

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (narrative is the core product)

## Overview

The Dialogue System is the primary narrative delivery mechanism for My Vampire. It presents
text-based dialogue between characters using a data-driven Resource architecture
(`DialogueNodeSO`) connected into directed dialogue graphs. Each dialogue node contains
speaker identification, display text with TextMarkup formatting, optional voice clip
references, and branching conditions. The system supports linear conversations, branching
choices (where designed), character portraits with expression states, typewriter text
animation with player skip, and auto-advance timers. The Dialogue System is triggered
by NPCs, story events, chapter state changes, and cutscenes. It blocks all gameplay input
while active and ducks ambient audio per the Audio System's ducking rules.

## Player Fantasy

The Dialogue System serves the fantasy of **watching an anime with your friends**. The
player should feel like they're in a living story — characters speak with personality,
expressions shift with the mood, and the pacing never drags. Text appears at a readable
speed but can be skipped if the player has seen it before. Character portraits show the
speaker's emotional state (serious, smiling, angry, pained), making the text feel alive.
The player never feels trapped in dialogue — they can advance at their own pace and skip
entire conversations if they want. But the dialogue is written well enough that most
players won't want to skip. Every conversation reveals character, advances the plot,
or builds the world — ideally all three.

**Reference model**: Persona 5's stylized dialogue presentation (character portraits with
expressions, clean text layout), Fire Emblem's skip-to-end convenience (hold button to
advance quickly), and Visual Novel-style text pacing (typewriter effect with instant-skip).

## Detailed Design

### Core Rules

1. **DialogueNodeSO Resource**: Each node in a dialogue graph is a
   `DialogueNodeSO` asset:
   ```
   DialogueNodeSO fields:
   ┌─────────────────────────────────────────────────┐
   | Speaker: CharacterDataSO reference               |
   | Expression: string (matches portrait state)      |
   | Text: string (TextMarkup formatted)             |
   | VoiceClip: AudioClip reference (optional)        |
   | NextNode: DialogueNodeSO reference (linear)      |
   | Choices: Choice[] (optional branching)           |
   | AutoAdvanceSeconds: float (0 = no auto-advance)  |
   | Condition: DialogueCondition (optional gate)     |
   | Events: DialogueEvent[] (optional triggers)      |
   └─────────────────────────────────────────────────┘

   Choice sub-object:
   ┌─────────────────────────────────────────────────┐
   | DisplayText: string                              |
   | TargetNode: DialogueNodeSO reference             |
   | Condition: DialogueCondition (optional)          |
   └─────────────────────────────────────────────────┘
   ```

2. **DialogueGraphSO**: A `DialogueGraphSO` Resource contains an array of
   `DialogueNodeSO` references and identifies the `StartNode`. Each conversation
   (NPC interaction, story beat, chapter intro) has its own graph asset. Graphs are
   Graphs are created in the Godot editor by the narrative team and referenced by scene triggers.

3. **Dialogue Text Markup**: Dialogue text supports inline formatting via a simple
   markup syntax processed by `TextMeshPro`:
   - `[name]Text[/name]` — colored speaker name inline (e.g., "Evelyn said...")
   - `[item]Text[/item]` — highlighted item reference
   - `[emphasis]Text[/emphasis]` — italic emphasis
   - `[pause=0.5]` — typewriter pause for N seconds
   - `[shake]Text[/shake]` — text shake effect (for angry/emotional lines)
   - `[size=1.5]Text[/size]` — larger text (for dramatic lines)

4. **Dialogue Display Pipeline**:
   1. A trigger (NPC, scene event, chapter state) calls `DialogueManager.StartGraph(graph)`
   2. The system resolves the `StartNode`, evaluates its `Condition` (if any)
   3. If the condition fails, the node is skipped to `NextNode` recursively
   4. The current node's speaker portrait, expression, and text are sent to the Dialogue UI
   5. Text animates in via typewriter effect at 40 characters/second (tunable)
   6. Player can press Submit to advance to the next node
   7. Player can hold Submit to instant-complete the current node's typewriter
   8. If `AutoAdvanceSeconds > 0`, the node auto-advances after that duration
   9. When a node has no `NextNode` and no `Choices`, the dialogue ends
   10. On end, gameplay input is restored and audio ducking is released

5. **Branching Choices**: When a node has a non-empty `Choices` array:
   - The typewriter completes immediately (choices require full context)
   - The Dialogue UI displays all available choices
   - Choices with a failing `Condition` are grayed out but visible
   - Player selects a choice via Navigate + Submit (UI input map)
   - The selected choice's `TargetNode` becomes the current node
   - Unselected choices are discarded (no "go back and choose differently")

6. **Dialogue Conditions**: A `DialogueCondition` is a simple rule that gates node
   accessibility:
   ```
   DialogueCondition fields (MVP):
   ┌─────────────────────────────────────────────────┐
   | ChapterStateKey: string                          |
   | RequiredValue: enum (Seen, NotSeen, True, False) |
   └─────────────────────────────────────────────────┘
   ```
   Conditions are evaluated by the `DialogueManager` against the `ChapterStateSystem`.
   Failed conditions cause the node to be skipped (or the choice to be grayed out).

   **Deferred (Alpha scope)**: `CharacterAffinity` and `AffinityThreshold` condition
   fields require an Affinity System that is not yet in the systems index. They are
   excluded from the MVP `DialogueCondition` schema.

7. **Dialogue Events**: A `DialogueEvent` is a side effect triggered when a node is
   displayed or completed:
   | Event Type | Parameters | Use Case |
   |------------|-----------|----------|
   | `SetChapterFlag` | `flagKey: string, value: bool` | Mark a story beat as seen |
   | `SpawnNPC` | `npcPrefab, position` | NPC appears after dialogue |
   | `StartCutscene` | `cutsceneRef` | Transition to cutscene mid-dialogue |
   | `ChangeExpression` | `characterRef, expression` | Override portrait expression |
   | `PlaySound` | `audioClip` | Custom sound during dialogue |
   | `GrantItem` | `itemRef, count` | Player receives item from conversation |

8. **Dialogue Triggering**: Dialogue can be started by:
   - **NPC Interaction**: Player presses Interact near an NPC with a `DialogueTrigger`
     component referencing a `DialogueGraphSO`
   - **Scene Event**: A scene's `DialogueTrigger` fires on scene load (chapter intro dialogue)
   - **Chapter State**: The `ChapterStateSystem` detects a flag change and fires dialogue
   - **Combat End**: An encounter completion triggers post-combat banter (optional)
   - **Cutscene System**: A cutscene transitions to dialogue mid-sequence

9. **Dialogue State Tracking**: The system tracks which dialogue graphs and nodes have
   been seen. This data is serialized by the Save / Load System. On load, the system
   knows which conversations are complete and which are new. Per-node tracking enables
   NPCs to have different dialogue on repeat interactions (e.g., "You've already heard
   this — want to hear it again?").

10. **Simultaneous Dialogue Blocking**: While dialogue is active:
    - Input System activates the UI action map, blocking Exploration/Combat inputs
    - Audio System ducks Music and Ambience per ducking rules
    - Camera System switches to Cinematic mode (or holds current camera)
    - All combat subsystems are frozen (if combat was active — rare but possible)
    - Time scale is NOT modified (dialogue runs in real-time)

### States and Transitions

```
┌────────────┐  StartGraph()  ┌─────────────────┐
│   Idle     │ ──────────────▶│ Typewriter Play │
│            │                │(text animating)  │
└────────────┘                └────────┬────────┘
                                       │
                  ┌────────────────────┼────────────────────┐
                  │ text complete      │ player advances    │ auto-advance
                  ▼                    ▼                    ▼
           ┌────────────┐      ┌──────────────┐     ┌──────────────┐
           │  Waiting   │      │  Next Node   │     │  Next Node   │
           │ (choices/  │      │  or End      │     │  or End      │
           │  complete) │      │              │     │              │
           └─────┬──────┘      └──────┬───────┘     └──────┬───────┘
                 │ player selects     │ has NextNode       │ no NextNode
                 ▼                    ▼                    ▼
           ┌────────────┐      ┌──────────────┐     ┌──────────────┐
           │  Branch    │      │ Typewriter   │     │    End       │
           │  selected  │      │ Play (next)  │     │  (restore)   │
           └─────┬──────┘      └──────────────┘     └──────────────┘
                 │
                 ▼
           ┌────────────┐
           │ Typewriter │
           │ Play       │
           └────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Chapter State** | Reads/Writes | Reads flags for conditions, writes flags via events |
| **Input System** | Calls | Activates UI action map, blocks gameplay input |
| **Audio System** | Calls | Ducks Music/Ambience, triggers voice clip playback |
| **Camera System** | Calls | Requests Cinematic camera mode during dialogue |
| **Cutscene System** | Calls/Triggered by | Can start cutscene mid-dialogue via DialogueEvent |
| **Save / Load** | Serialized by | Seen nodes, current graph position, chapter flags |
| **Dialogue UI** | Driven by | All visual display is delegated to Dialogue UI |
| **Combat System** | Read by | If dialogue starts during combat, combat is paused |
| **Scene Management** | Called by | Scene triggers fire dialogue on load |
| **NPC System** | Called by | NPCs reference DialogueGraphSO for their conversations |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `TypewriterSpeed` | `40 chars/sec` | Default text reveal speed |
| `TypewriterSkip` | `instant` | Hold Submit completes current node |
| `AutoAdvanceTimer` | `node.AutoAdvanceSeconds` | 0 = no auto-advance (player must press) |
| `ConditionEval` | `chapterState[flagKey] == requiredValue` | Boolean gate per node/choice |

## Edge Cases

1. **Dialogue triggered during combat**: Combat subsystems are frozen. Enemies continue
   their current actions but no new AI decisions are made. Combat resumes when dialogue
   ends. This should be rare — story encounters typically separate combat and dialogue
   with clear boundaries.

2. **Dialogue graph has a cycle (A → B → A)**: The system detects infinite loops by
   tracking the node visit count in the current conversation. If a node is visited
   3+ times in one conversation, the cycle is broken and the dialogue ends. A warning
   is logged for the narrative team to fix the graph.

3. **Player holds Submit during a choice node**: The hold-to-skip completes the
   typewriter instantly but does NOT auto-select a choice. The player must explicitly
   select a choice. No default choice is auto-picked.

4. **Voice clip longer than typewriter text**: The voice clip plays to completion
   regardless of text timing. If the text finishes before the audio, the node waits
   for the audio to end before accepting player advance.

5. **Dialogue graph references a deleted node**: The `NextNode` reference becomes null.
   The system treats null `NextNode` as end-of-dialogue and closes gracefully. A
   warning is logged.

6. **Save file loaded mid-dialogue**: The dialogue system restores the current graph,
   current node index, and typewriter progress. The typewriter completes instantly on
   load (no mid-animation text) and waits for player input on the restored node.

7. **Multiple dialogue triggers fire simultaneously**: Only the first trigger is
   processed. Subsequent triggers are queued and fire after the current dialogue ends.
   Queue depth: unlimited (but realistically 2-3 max).

8. **Character referenced as speaker has no portrait asset**: The dialogue displays
   without a portrait. A placeholder silhouette is shown. A warning is logged.

## Dependencies

- **Depends on**: Audio System (ducking, voice clips), Chapter State System (conditions),
  TextMeshPro (text rendering), Dialogue UI (all visual display delegated here — maintains
  system boundary), Input System (UI map)
- **Depended on by**: Cutscene System, Dialogue UI, NPC System, Narrative Choice System,
  Scene Management System, Combat System (post-encounter banter)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `TypewriterSpeed` | float | `40 chars/sec` | Reduce for readability, increase for pace |
| `HoldSkipDelay` | float | `0.3s` | How long to hold Submit before typewriter skips |
| `CycleDetectThreshold` | int | `3` | Max times a node can be visited before cycle break |
| `AutoAdvanceDefault` | float | `0s` | Default auto-advance (0 = player must press) |
| `DialogueQueueDepth` | int | `10` | Max queued dialogue triggers; additional triggers beyond the cap are dropped with a warning logged for the narrative team |

## Visual/Audio Requirements

- **Character Portraits**: Each `CharacterDataSO` has portrait sprites for at least these
  expressions: `neutral`, `happy`, `serious`, `angry`, `sad`, `pained`. MVP needs Evelyn,
  Evan, and Witch portraits at minimum.
- **Dialogue Box**: Semi-transparent panel at the bottom of the screen with speaker name,
  expression portrait, and text area. Styled to match the game's gothic aesthetic.
- **Choice Display**: Choice buttons appear stacked vertically below the dialogue text.
  Available choices are highlighted; unavailable choices are grayed out with a lock icon.
- **Voice Clips**: Optional `AudioClip` per node. If present, plays when the node displays.
  MVP may not have voice acting — the system supports it for future content.

## UI Requirements

- **Dialogue Box**: Fixed position at screen bottom, ~30% screen height, anchored to
  bottom edge. Speaker name at top-left, portrait at left, text fills remaining space.
- **Continue Indicator**: A small animated arrow or "▼" pulses at the bottom-right of
  the dialogue box when the typewriter is complete and the player can advance.
- **Choice Panel**: Overlays the dialogue text when choices are available. 2-4 choices max
  per node. Each choice is a button with hover highlight.
- **Skip Indicator**: When the player holds Submit to skip, a small ">>" icon appears
  briefly indicating the skip is active.

## Acceptance Criteria

- [ ] Dialogue graph starts from the designated StartNode and follows NextNode links
- [ ] Typewriter text animates at 40 chars/sec and can be instantly-completed with Submit
- [ ] Hold-to-skip completes the current node's typewriter instantly
- [ ] Branching choices display correctly; player selection determines the next node
- [ ] Dialogue conditions gate node access correctly (failed conditions skip or gray out)
- [ ] Dialogue events fire at the correct time (on display or on completion)
- [ ] Gameplay input is blocked while dialogue is active
- [ ] Audio ducks Music and Ambience during dialogue
- [ ] Dialogue state (seen nodes, chapter flags) saves and loads correctly
- [ ] Cycle detection prevents infinite loops in malformed graphs
- [ ] Null NextNode or missing nodes are handled gracefully (end dialogue, log warning)
- [ ] Character portraits display with correct expression and speaker name
- [ ] Auto-advance timer progresses dialogue without player input when set
- [ ] Voice clips (if present) play when the node displays and block advance until complete

## Open Questions

- Should dialogue support a "review" feature (player can re-read previous lines)? This
  would require a scroll-back buffer (last 5 lines). Nice-to-have, not MVP.
- Should we support dialogue interruption (player walks away from NPC mid-conversation)?
  Currently dialogue is modal and blocking. Allowing walk-away would require save-point
  tracking within the graph (resume from this node next time).
- Should the typewriter speed be adjustable in settings for accessibility? Some players
  read much faster or slower than 40 chars/sec.
