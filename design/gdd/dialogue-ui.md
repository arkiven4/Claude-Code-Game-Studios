# Dialogue UI

> **Status**: Approved
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (narrative presentation quality)

## Overview

The Dialogue UI is the visual presentation layer for the Dialogue System. Built with
Godot UI, it renders the dialogue box (speaker name, character portrait with
expressions, dialogue text), typewriter text animation, continue indicator, and choice
panel (when branching is available). The UI is a pure view — it receives data from the
Dialogue System and renders it. It handles TextMarkup processing through RichTextLabel,
typewriter text reveal animation, portrait swapping on speaker changes, choice button
generation, and the hold-to-skip visual indicator. The dialogue box is anchored to the
bottom of the screen (~30% screen height) and styled to match the game's gothic aesthetic
with dark panels, gold accents, and elegant typography.

## Player Fantasy

The Dialogue UI serves the fantasy of **reading a beautifully illustrated light novel**.
The text is crisp and readable. Character portraits change expression with the mood.
The speaker's name is always visible. Choices feel weighty — each one is a distinct
button with a satisfying hover and click animation. The typewriter effect gives the
text a natural rhythm, but the player can always skip ahead. The UI never fights the
art — it frames it. The gothic styling (dark backgrounds, gold borders, serif fonts)
reinforces the game's tone. Every dialogue box feels like a page from a well-crafted
book.

**Reference model**: Persona 5's bold stylistic dialogue boxes (the UI itself has
personality), Final Fantasy XVI's clean portrait + text layout, and Visual Novel
conventions (bottom-anchored box, portrait left, text right, choices below).

## Detailed Design

### Core Rules

1. **Dialogue Box Layout** (anchored to screen bottom, ~30% screen height):
   ```
   ┌──────────────────────────────────────────────────────────┐
   │ [SPEAKER NAME — gold text, top-left]                    │
   │                                                          │
   │ ┌─────────┐                                              │
   │ │Portrait │  [Dialogue text — RichTextLabel, white text   │
   │ │(64x64)  │   with markup support)]                     │
   │ │         │                                              │
   │ └─────────┘                                              │
   │                                                          │
   │                                              [Continue ▼]│
   └──────────────────────────────────────────────────────────┘
   ```
   - Speaker name: Gold-colored RichTextLabel label, top-left, bold
   - Portrait: 64x64 image, left-aligned, expression swaps on speaker change
   - Text area: Fills remaining space, RichTextLabel with word wrap
   - Continue indicator: Pulsing "▼" or ">>" at bottom-right (shown when typewriter
     is complete or when text has no more to reveal)

2. **Typewriter Animation**:
   - Text is revealed character-by-character at 40 characters/second (tunable)
   - Punctuation pauses: period (0.15s), comma (0.08s), ellipsis (0.3s)
   - Markup tags (`[emphasis]`, `[shake]`, etc.) are processed inline and do not
     count toward the character count
   - `[pause=N]` tags insert an N-second pause in the typewriter
   - The animation runs via Godot Tween animations on the RichTextLabel's `visible_ratio`
     property, not `_process()`

3. **Hold-to-Skip**:
   - When the player holds the Submit button for 0.3s, the typewriter instantly
     completes the current node's full text
   - A ">>" indicator appears briefly during the hold
   - If the current node has choices, the typewriter completes but the choice panel
     appears (player must still select a choice)
   - If the current node is the last node, the dialogue closes

4. **Choice Panel** (overlays the dialogue text area):
   - When a dialogue node has `Choices[]`, the typewriter completes instantly
   - The dialogue text area is replaced by a vertical stack of choice buttons
   - Each choice button shows the choice's `DisplayText`
   - Available choices have a gold border and glow on hover
   - Unavailable choices (failed condition) are grayed out with a lock icon
   - Player navigates choices with Navigate input (Up/Down) and confirms with Submit
   - Maximum 4 choices per node (enforced by the Dialogue System at authoring time)

5. **Portrait Management**:
   - Each `CharacterDataSO` references a portrait atlas (a single texture containing
     all expression states for that character)
   - The `expression` string on a `DialogueNodeSO` maps to a sprite rect in the atlas
   - When the speaker changes, the portrait sprite is swapped with a 0.2s crossfade
   - If the expression string does not match any sprite in the atlas, the `neutral`
     expression is used as fallback
   - If the character has no portrait asset, a default silhouette placeholder is shown

6. **Multi-Speaker Nodes**: A single dialogue node has one speaker. When the conversation
   switches speakers, the next node has a different `Speaker` reference. The Dialogue UI
   handles the transition:
   - Speaker name updates
   - Portrait crossfades (0.2s)
   - Text area clears and typewriter starts the new node's text
   - If the same character speaks in consecutive nodes, the portrait stays (no crossfade)

7. **Dialogue Box Auto-Resize**: The text area dynamically resizes based on text length.
   Short lines use minimal height. Long paragraphs expand the box up to the maximum
   30% screen height. If the text exceeds the maximum height, a scroll indicator appears
   and the player can advance line-by-line (each Submit shows the next "page" of text).

8. **Hide/Show Animation**:
   - Dialogue box appears with a 0.2s slide-up from the bottom of the screen
   - Dialogue box disappears with a 0.2s slide-down
   - During the show animation, no typewriter text is revealed (text starts after
     the animation completes)

### States and Transitions

```
┌──────────┐  StartGraph()  ┌───────────────────┐
│  Hidden  │ ──────────────▶│  Showing (slide-up│
│          │                │   0.2s animation) │
└──────────┘                └─────────┬─────────┘
                                      │ animation complete
                                      ▼
                              ┌───────────────────┐
                              │  Typewriter       │
                              │  (text revealing) │
                              └─────────┬─────────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
             Text Complete       Hold-Skip Triggered   Auto-Advance
                    │                   │                   │
                    ▼                   ▼                   ▼
             ┌────────────┐      ┌────────────┐     ┌────────────┐
             │  Waiting   │      │ Text Full  │     │ Text Full  │
             │ (continue) │      │ + choices  │     │ (no choices)│
             │  or choices│      │  or next   │     │ → next     │
             └─────┬──────┘      └─────┬──────┘     └─────┬──────┘
                   │                   │                   │
                   ▼                   ▼                   ▼
             ┌────────────┐      ┌────────────┐     ┌────────────┐
             │  Next Node │      │  Next Node │     │  Next Node │
             │  or End    │      │  or End    │     │  or End    │
             └────────────┘      └────────────┘     └────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Dialogue System** | Driven by | Receives node data (speaker, expression, text, choices) |
| **Input System** | Reads | Reads Submit and Navigate inputs for typewriter skip and choice selection |
| **Audio System** | Calls | Triggers typewriter tick sound (barely audible), dialogue advance sound |
| **Camera System** | Read by | Camera System knows dialogue is active for Cinematic mode switch |
| **Cutscene System** | Called by | Cutscenes can hide/show the dialogue box mid-sequence |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `TypewriterSpeed` | `40 chars/sec` | Base reveal rate |
| `PunctuationPausePeriod` | `0.15s` | Pause on period/full stop |
| `PunctuationPauseComma` | `0.08s` | Pause on comma |
| `PunctuationPauseEllipsis` | `0.3s` | Pause on "..." |
| `PortraitCrossfadeDuration` | `0.2s` | Speaker change animation |
| `BoxShowDuration` | `0.2s` | Slide-up animation |
| `BoxHideDuration` | `0.2s` | Slide-down animation |
| `HoldSkipThreshold` | `0.3s` | Hold duration before typewriter skips |
| `MaxBoxHeight` | `30% screen height` | Maximum dialogue box size |

## Edge Cases

1. **Text contains no markup but is very long (single 500-character line)**: The text
   area word-wraps. If the wrapped text exceeds the max box height, the player advances
   page-by-page with Submit. Each page shows as much text as fits.

2. **Choice text is longer than the button width**: Choice buttons wrap text to multiple
   lines. Button height adjusts to fit. If a choice is so long that it exceeds the
   available space, the text is truncated with "..." and the player can hover to see
   the full text in a tooltip.

3. **Speaker has no portrait for the requested expression**: Falls back to the `neutral`
   expression. If no portrait asset exists at all, shows a default gray silhouette.
   A warning is logged.

4. **Dialogue UI is shown while the game window is resized**: The dialogue box re-anchors
   to the new bottom edge. The text re-flows. Portrait size scales proportionally. No
   UI elements overflow.

5. **Player mashes Submit during typewriter with auto-advance set**: The first Submit
   completes the typewriter. Subsequent Submits during the auto-advance timer are
   ignored (the timer is not reset).

6. **Multiple dialogue graphs queue up**: The UI shows the first dialogue. When it ends,
   if another dialogue is queued, the box slides down (0.2s) and then slides back up
   (0.2s) for the next dialogue. There is a 0.3s gap between dialogues so the player
   can breathe.

## Dependencies

- **Depends on**: Dialogue System (data source), Input System (Submit/Navigate), Audio
  System (typewriter/advance sounds), RichTextLabel (text rendering), Godot UI
  (layout and animation)
- **Depended on by**: Dialogue System (the UI is its display layer), Cutscene System
  (hides/shows dialogue box mid-cutscene)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `TypewriterSpeed` | float | `40 chars/sec` | Main readability control |
| `MaxBoxHeightPercent` | float | `30%` | Maximum dialogue box screen coverage |
| `PortraitSize` | float | `64px` | Portrait sprite display size |
| `ChoiceButtonPadding` | float | `8px` | Vertical space between choice buttons |
| `PageScrollPadding` | float | `20px` | Minimum text margin before page break |

## Visual/Audio Requirements

- **Dialogue Box Style**: Dark panel (#1a1a2e background, #c9a84c gold border, 2px
  border width). Rounded corners (8px radius). Subtle drop shadow.
- **Typography**: RichTextLabel with a serif font (matching the game's gothic tone).
  Body text at 18px, speaker name at 16px bold gold.
- **Portrait Atlas**: One texture per character containing all expression sprites
  (neutral, happy, serious, angry, sad, pained). Each sprite is 64x64.
- **Choice Buttons**: Dark rectangular buttons with gold border, hover glow, click
  animation (brief scale-down to 95%).
- **Typewriter Sound**: Very subtle click per character reveal (barely audible, mixed
  at UI volume). Dialogue advance sound: soft click.

## UI Requirements

- **Godot UI Scene**: `.tscn` file defining the dialogue box layout with proper
  anchors, VBoxContainer, and responsive sizing.
- **Theme Resources**: `.tres` theme file for all visual styles (colors, borders, fonts, animations).
- **Portrait Atlas Textures**: `.png` files per character, imported as Sprite sheets
  with named slices matching expression strings.
- **Choice Button Scene**: Reusable `.tscn` template for choice buttons (instantiated per choice).

## Acceptance Criteria

- [ ] Dialogue box slides up from bottom over 0.2s when dialogue starts
- [ ] Speaker name displays in gold bold text at top-left
- [ ] Portrait displays correct expression and crossfades (0.2s) on speaker change
- [ ] Typewriter reveals text at 40 chars/sec with correct punctuation pauses
- [ ] Markup tags (`[emphasis]`, `[shake]`, etc.) are processed correctly inline
- [ ] Hold Submit for 0.3s instantly completes the typewriter
- [ ] Continue indicator pulses when typewriter is complete
- [ ] Choice panel replaces text area when choices are available
- [ ] Choices navigate with Up/Down and confirm with Submit
- [ ] Unavailable choices are grayed out with lock icon
- [ ] Dialogue box slides down over 0.2s when dialogue ends
- [ ] Long text pages correctly with page-by-page advance on Submit
- [ ] Dialogue box hides during cutscenes
- [ ] UI resizes correctly on window resolution change
- [ ] Fallback portrait shows when expression or portrait asset is missing

## Open Questions

- Should the dialogue UI support a "text history" feature (scroll back to re-read
  previous lines)? This would require a buffer of the last N lines and a scroll
  mechanism. Useful for story-heavy games but adds complexity.
- Should portrait sprites animate (subtle idle breathing, expression changes with
  a transition effect beyond crossfade)? This would increase the art budget but
  significantly improve presentation quality.
- Should the dialogue box be repositionable by the player (drag to move)? Some players
  prefer it on the side rather than the bottom. Recommendation: not for MVP.
