# Chapter State System

> **Status**: Designed
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (narrative persistence), Earn the Ending

## Overview

The Chapter State System is the narrative spine of the game — it tracks which chapter the
player is in, which story beats have been completed, which narrative choices have been
made, and what the consequences are. It is the system that makes the story remember what
the player did. Each chapter has a unique identifier, a set of required story beats
(encounters, dialogues, cutscenes, choices), and a set of story flags that record
consequential decisions. The Chapter State System is read by the Dialogue System (to
determine what characters say), the Cutscene System (to determine which scenes play), the
Scene Management System (to determine which scenes load), and the Save / Load System (to
persist narrative progress). It is the bridge between gameplay and narrative.

## Player Fantasy

The Chapter State System serves the fantasy of **a story that remembers you**. Every
choice the player makes — who they saved, who they sacrificed, which path they took — is
recorded and reflected in the world. The player should feel that their decisions matter,
not because the game tells them "your choices matter," but because the story changes in
visible ways: characters remember what the player did, areas look different based on past
events, and the ending reflects the accumulation of every decision. The chapter system
gives structure to the narrative — the player always knows where they are in the story
and what's coming next.

**Reference model**: The Walking Dead's choice tracking (every decision is recorded and
referenced later), Life is Strange's chapter-based narrative structure, and Witcher 3's
consequential story flags (small decisions ripple through the entire game).

## Detailed Design

### Core Rules

1. **Chapter Structure**: The game is divided into numbered chapters. Each chapter has:
   - `ChapterId` (int, 0-based) — unique identifier
   - `ChapterName` (string) — display name (e.g., "Prologue: The Awakening")
   - `RequiredStoryBeats` (list of StoryBeat enum values) — must-complete events
   - `OptionalStoryBeats` (list of StoryBeat values) — side content, not required
   - `EntranceScene` (string) — scene name loaded when chapter begins
   - `ExitCondition` (enum) — what triggers the chapter to end

2. **Story Flags**: A bitmask of narrative decisions and their outcomes. Each flag is a
   named boolean:
   ```
   // Prologue flags
   SAVED_VILLAGERS = 0x01      // Did Evelyn save the villagers in the prologue?
   KILLED_WITCH_HUNTER = 0x02  // Did Evelyn kill or spare the witch hunter?
   MET_EVAN = 0x04             // Has Evelyn met Evan yet?
   
   // Chapter 1 flags
   ALLIED_WITH_WITCH = 0x10    // Did Evelyn ally with the witch?
   BETRAYED_EVAN = 0x20        // Did Evelyn betray Evan's trust?
   DISCOVERED_VAMPIRE_ORIGIN = 0x40  // Did Evelyn learn about her vampire origins?
   ```
   Flags are set by the Narrative Choice System, dialogue completions, and encounter
   outcomes. They are never unset once set (narrative decisions are permanent).

3. **Chapter Transitions**: A chapter ends when its `ExitCondition` is met:
   - `BossDefeated` — The chapter's boss encounter is completed
   - `StoryBeatCompleted` — The final required story beat is completed
   - `ChoiceMade` — A narrative choice triggers an immediate chapter transition
   - `TimedEvent` — A scripted event ends the chapter (rare, used for prologue)

   On chapter transition:
   1. The Chapter State System marks the chapter as `Completed`
   2. An auto-save is triggered (see Save / Load System)
   3. The Chapter End cutscene plays
   4. The next chapter's entrance scene is loaded by Scene Management
   5. The Chapter Begin cutscene plays

4. **Visited Locations**: A list of scene names the player has visited in the current
   chapter. Used by the Dialogue System to reference past events ("Remember when we were
   in the Haunted Forest?") and by the Narrative Choice System to gate choices
   ("You've been to the Crypt — you can now choose to reveal what you found").

5. **Completed Encounters**: A list of encounter IDs the player has completed in the
   current chapter. Used to prevent re-fighting optional encounters and to track
   completion percentage.

6. **Chapter Progression Tracking**: The system tracks completion percentage per chapter:
   ```
   Completion% = (CompletedStoryBeats / TotalRequiredStoryBeats) × 100
   ```
   Displayed in the pause menu as "Chapter Progress: 3/5 beats completed (60%)".

7. **No Backtracking Between Chapters**: Once a chapter is completed, the player cannot
   return to it. This is intentional — the narrative moves forward, and past areas are
   inaccessible. This reinforces the "Earn the Ending" pillar: every decision is
   irreversible, and the story always moves forward.

8. **Chapter Save Data**: Serialized by the Save / Load System:
   ```csharp
   public struct ChapterSaveData {
       public int CurrentChapterId;
       public long CompletedChapterFlags;  // 64-bit bitmask of all chapters ever completed
       public long CurrentChapterFlags;    // 64-bit bitmask of current chapter's story flags
       public string[] VisitedLocations;
       public int[] CompletedEncounters;
       public int CompletedStoryBeats;
       public int TotalRequiredStoryBeats;
   }
   ```

### States and Transitions

```
┌─────────────────────┐
│  CHAPTER_ACTIVE     │ ◄── Player is playing within a chapter
│  (accepting input)  │
└────────┬────────────┘
         │ ExitCondition met
         ▼
┌─────────────────────┐
│ CHAPTER_TRANSITION  │ ◄── Auto-save, end cutscene, scene change
│  (no player input)  │
└────────┬────────────┘
         │ Next chapter loaded, begin cutscene done
         ▼
┌─────────────────────┐
│  CHAPTER_ACTIVE     │ ◄── Next chapter begins
│  (new chapter)      │
└─────────────────────┘
```

**Chapter states per story beat**:
```
StoryBeat_Inactive → StoryBeat_Active → StoryBeat_Completed
```
- `Inactive`: The story beat has not been triggered yet
- `Active`: The story beat is currently happening (dialogue playing, encounter in progress)
- `Completed`: The story beat has been finished

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Save / Load** | Serialized by | Current chapter, story flags, visited locations, completed encounters |
| **Scene Management** | Called by | Chapter State tells Scene Management which scene to load on transition |
| **Dialogue System** | Read by | Dialogue branches check story flags to determine available options |
| **Cutscene System** | Called by | Chapter State triggers chapter begin/end cutscenes |
| **Narrative Choice** | Calls | Narrative Choice sets story flags and can trigger chapter transitions |
| **Combat System** | Read by | Combat System reads `IsBossEncounter` flag to enable boss music |
| **Audio System** | Calls | Audio System crossfades music on chapter transition |
| **Multiple Endings** | Read by | Endings system reads accumulated story flags to determine ending |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `ChapterCompletion%` | `(CompletedBeats / TotalRequiredBeats) × 100` | Displayed in pause menu |
| `StoryFlagBit` | `1L << flagIndex` | 64-bit bitmask for flag storage; `1L` required to avoid int overflow past bit 31 |
| `HasFlag(flag)` | `(currentFlags & flagBit) != 0` | Check if a story flag is set |
| `SetFlag(flag)` | `currentFlags \|= flagBit` | Permanently set a story flag |

## Edge Cases

1. **Player loads a save from a different chapter**: The Chapter State is restored from
   the save file. The system validates that the saved chapter ID exists in the current
   build. If not, it defaults to Chapter 0.

2. **Story flag set during a cutscene**: The flag is set immediately, but the visual
   consequence (dialogue change, area change) may not appear until the cutscene ends.
   This is acceptable — the flag is the truth, the display catches up.

3. **Chapter transition triggered during combat**: Combat is ended first (all enemies
   marked as defeated), then the chapter transition proceeds. This prevents combat state
   from leaking into the next chapter.

4. **Narrative choice triggers chapter transition and auto-save simultaneously**: The
   auto-save completes before the chapter transition cutscene begins. The save contains
   the pre-transition state. If the player reloads, they are at the choice point again.

5. **Story flag overflow (more than 32 flags)**: The system uses a 64-bit integer for
   flags (`long` in C#, 64 bits) — supporting up to 64 flags per chapter. If a chapter
   needs more than 64 flags, it is split into sub-chapters (e.g., "Chapter 2A" and
   "Chapter 2B").

6. **Player completes all story beats but exit condition is not met**: The chapter remains
   active. The exit condition is the authority — story beats alone do not end a chapter
   unless the exit condition is `StoryBeatCompleted`.

## Dependencies

- **Depends on**: Save / Load System (for persisting chapter state)
- **Depended on by**: Scene Management, Dialogue System, Cutscene System, Narrative
  Choice, Multiple Endings, Combat System, Audio System

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `MaxFlagsPerChapter` | int | `64` | Maximum story flags per chapter (64-bit integer) |
| `ChapterTransitionFadeTime` | float | `1.0s` | Duration of fade-to-black during transitions |
| `AutoSaveOnTransition` | bool | `true` | Can disable for debugging |
| `ShowChapterProgress` | bool | `true` | Can disable for minimal HUD mode |

## Visual/Audio Requirements

- **Chapter Title Card**: Full-screen overlay with chapter name and subtitle (e.g.,
  "Chapter 1: The Vampire's Bargain") — displayed for 2s with a fade-in/fade-out
- **Chapter Progress HUD**: Small indicator in the pause menu showing current chapter
  name and completion percentage
- **Transition Music Crossfade**: Current track fades out over 1s while next chapter's
  track fades in (handled by Audio System, triggered by Chapter State)
- **Story Flag Debug View**: In debug builds, a panel showing all currently set story
  flags (for QA testing)

## UI Requirements

- **Pause Menu**: Chapter name displayed at the top (e.g., "Chapter 1: The Vampire's
  Bargain")
- **Pause Menu**: Story progress displayed (e.g., "3/5 story beats completed")
- **Chapter Transition**: Full-screen title card with chapter name, subtitle, and brief
  fade animation
- **Map Screen** (future): Chapters displayed as nodes on a linear progression map

## Acceptance Criteria

- [ ] Chapter ID correctly increments on each chapter transition
- [ ] Story flags are set permanently and cannot be unset
- [ ] Chapter transition triggers auto-save, end cutscene, scene change, begin cutscene
  in correct order
- [ ] Dialogue System correctly reads story flags and branches dialogue
- [ ] Chapter completion percentage is accurate (completed beats / total required beats)
- [ ] Visited locations are correctly recorded and queryable
- [ ] Completed encounters are tracked and prevent re-fighting
- [ ] Loading a save restores chapter state identically
- [ ] Chapter transition fade-to-black plays smoothly (no frame drops or stutter)
- [ ] Story flags support up to 64 flags per chapter without overflow
- [ ] Completed chapters cannot be re-entered; attempting to load a save in a past chapter scene defaults to that chapter's entrance scene
- [ ] `1L << flagIndex` correctly handles flag indices 0–63 without integer overflow

## Open Questions

- Should the player be able to review past story choices in a "Choice Journal" UI
  (narrative review screen showing past decisions and their consequences)?
- Should chapter transitions always include a cutscene, or can some be instant (skip
  cutscene for minor chapter breaks)?
- Should the prologue be treated as Chapter 0 or as a separate entity (non-chapter
  narrative segment)?
