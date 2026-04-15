# Narrative Choice System

> **Status**: Approved
> **Author**: Design session 2026-04-11 (interactive redesign)
> **Last Updated**: 2026-04-11
> **Implements Pillar**: Earn the Ending, Story First

## Overview

The Narrative Choice System captures player decisions during dialogue and exploration that branch the story, shift relationships, and alter consequences. Every choice is recorded as a story flag, relationship delta, or reputation shift — invisible to the player but felt through how characters respond, what rewards are available, and which paths remain open. Most choices appear as dialogue branches within the existing Dialogue UI; major decisions trigger a dramatic full-screen overlay with illustrated options. The system feeds into the Chapter State System (which reads choice flags for story progression), the Shop System (relationship-based pricing), and the Multiple Endings System (which aggregates reputation and relationship data). Choices have real stakes — including full permadeath — but the main narrative arc remains completable in one playthrough.

## Player Fantasy

Narrative Choice serves the fantasy of **this is your story, your burden**. When you spare an enemy instead of killing it, and later that enemy's sibling offers you information you wouldn't have gotten otherwise — that feels earned. When you lie to protect Evelyn and Evan's relationship with you shifts because they saw through it — that feels real. The player should never feel like choices are illusory (all roads lead to the same place) or paralyzing (every decision could doom someone). There's a sweet spot: 3-5 meaningful choices per chapter, each with visible immediate consequence and hidden long-term ripple. The dramatic full-screen overlay on big decisions tells the player: *this matters*. But the game doesn't punish — it responds. Even the worst choice opens a path, just a different one.

**Reference model**: The Witcher 3's choice-and-consequence web (small choices compound into unexpected outcomes), Mass Effect's relationship system (party loyalty shifts based on decisions, not just dialogue), and Undertale's hidden morality tracking (player doesn't see the meter but the world reacts).

## Detailed Rules

### Core Rules

1. **Choice Definition**: Every narrative choice is defined in the Dialogue Graph as a `ChoiceNode` with the following properties:
   ```
   ChoiceNode fields:
   ┌─────────────────────────────────────────────────┐
   | ChoiceId: string (unique identifier)             |
   | DisplayText: string (what player sees)           |
   | DisplayIcon: Texture2D? (optional, for big decisions) |
   | Condition: StoryFlag check? (null = always shown) |
   | Consequences: ChoiceConsequence[]                |
   | IsMajorDecision: bool (triggers dramatic overlay) |
   └─────────────────────────────────────────────────┘

   ChoiceConsequence fields:
   ┌─────────────────────────────────────────────────┐
   | Type: enum (StoryFlag, RelationshipDelta,        |
   |              ReputationShift, ItemReward,        |
   |              CharacterDeath, SceneBranch)         |
   | Target: string (flag key, character ID, etc.)    |
   | Value: int or string (delta amount, scene ref)   |
   └─────────────────────────────────────────────────┘
   ```

2. **Choice Presentation**: Most choices appear as 2-4 options within the standard Dialogue UI (see Dialogue System GDD). When `IsMajorDecision = true`, the Dialogue UI transitions to a **dramatic overlay**: the screen dims, the choice options appear as large illustrated cards with icons and extended descriptions, and the player has unlimited time to decide. There is no timer on narrative choices.

3. **Choice Types**:
   - **Dialogue Branch**: Different responses to the same question. Affects relationship values and minor story flags. Example: "I trust you" vs "Prove yourself first."
   - **Action Decision**: Player chooses between two actions that both happen, but only one. Example: "Save the wounded guard" vs "Leave them — the Witch is dying."
   - **Moral Decision**: Player chooses between ethically distinct options. Affects reputation and character permadeath. Example: "Execute the defeated enemy" vs "Show mercy."
   - **Priority Decision**: Player must choose one problem to solve; the other resolves without them (often negatively). Example: "Defend the village" vs "Chase the fleeing boss."

4. **Story Flags**: Simple boolean values stored in the Chapter State System. Set by choice consequences and read by dialogue nodes, scene branches, and the Multiple Endings System. Example: `spared_grunt_ch2`, `lied_to_elder`, `defended_village`.

5. **Relationship Values**: Hidden integer values (-100 to +100) between the player (Evelyn) and specific characters (party members + key NPCs). Choices apply deltas to these values. The value is NOT displayed to the player but manifests through:
   - Dialogue variation (characters reference past choices)
   - Shop pricing (friendly merchants give discounts)
   - Combat assistance (loyal allies intervene in fights)
   - Loyalty outcomes (high-relationship party members may survive permadeath events)

6. **Reputation Meter**: A hidden integer (-100 to +100) tracking the player's moral alignment. Negative = "Dark" (selfish, cruel), Positive = "Light" (selfless, merciful). Every moral decision shifts reputation. The player never sees the number but experiences its effects:
   - NPC dialogue tone (fearful, respectful, warm)
   - World state (villages are safer or more dangerous)
   - Ending variation (Multiple Endings System reads final reputation)
   - Character permadeath likelihood (dark reputation = allies less likely to protect you)

7. **Consequence Resolution**: When a choice is made, consequences are resolved immediately:
   - Story flags are set in the Chapter State
   - Relationship deltas are applied to affected characters
   - Reputation shifts are recorded
   - Item rewards are granted or withheld
   - Character death events trigger (if applicable)
   - Scene branches are determined (which version of the next scene plays)

8. **Conditional Choices**: Some choices only appear if certain story flags are set or relationship thresholds are met. Example: A redemption option only appears if the player's relationship with a character is above +30. Unavailable choices are hidden entirely — the player never sees grayed-out options they "can't unlock."

9. **Permadeath Resolution**: When a choice triggers a character death:
   - The character is marked `IsPermaDead` in their CharacterData runtime wrapper
   - Their portrait is grayed out in the Party Management screen
   - They are removed from all future scenes and dialogue
   - Their equipment moves to Party Inventory
   - A narrative cutscene plays (brief, 5-10 seconds) confirming the death
   - If the character is a main party member (Evelyn, Evan), the death is **never forced by choice** — only secondary characters can die permanently from player decisions

10. **Save/Load**: All story flags, relationship values, and reputation are serialized in the save file. Loading restores the exact choice state. Choices already made cannot be undone through save scumming within the same save file (the game doesn't prevent it, but doesn't encourage it either).

### States and Transitions

```
┌──────────┐  Dialogue reaches  ┌──────────────────┐
│  Normal  │  ChoiceNode        │  Choice          │
│  Dialogue│ ──────────────────▶│  Presentation    │
└──────────┘                    └────────┬─────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │ IsMajorDecision?   │                    │
                    ▼                    ▼                    ▼
             ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
             │  Inline      │    │  Dramatic    │    │  Conditional │
             │  (2-4 buttons│    │  Overlay     │    │  (only shown │
             │   in dialogue│    │  (illustrated│    │   if flags/  │
             │   box)       │    │   cards)     │    │   relationships│
             └──────┬───────┘    └──────┬───────┘    │   met)       │
                    │                   │             └──────┬───────┘
                    │  Player selects   │                    │
                    └────────┬──────────┘                    │
                             ▼                               │
                    ┌──────────────────┐                     │
                    │  Consequence     │◄────────────────────┘
                    │  Resolution      │
                    └────────┬─────────┘
                             │ flags set, relationships shifted,
                             │ reputation updated, deaths triggered
                             ▼
                    ┌──────────────────┐
                    │  Resume Dialogue │
                    │  (branch based   │
                    │   on choice)     │
                    └──────────────────┘
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Dialogue System** | Reads + Driven by | Choices are nodes in the dialogue graph; dialogue resumes after choice | Choice presentation via Dialogue UI |
| **Chapter State System** | Writes | Sets story flags that persist across scenes and chapters | Chapter context for conditional choices |
| **Character Data** | Reads | Reads character IDs for relationship targets; reads IsMainCharacter for permadeath protection | Character definitions, main character flags |
| **Multiple Endings** | Writes | Provides final reputation and relationship state for ending calculation | — |
| **Shop System** | Reads | Shop reads relationship values for pricing adjustments | Relationship-based discounts |
| **Party Management** | Reads | Reads permadeath flags to gray out dead characters | — |
| **Cutscene System** | Calls | Triggers permadeath confirmation cutscenes | Cutscene playback |
| **Save / Load** | Serialized | All flags, relationships, and reputation are saved/loaded | — |
| **Combat System** | Reads | Reads relationship values for ally intervention events | — |

## Formulas

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **Relationship Delta** | `Relationship[characterId] += delta` | delta: -20 to +20 per choice | Clamped to -100..+100 |
| **Reputation Shift** | `Reputation += shift` | shift: -15 to +15 per moral choice | Clamped to -100..+100 |
| **Shop Price Modifier** | `finalPrice = floor(basePrice × (1 - relationship × 0.003))` | relationship: -100 to +100 | At +100: 30% discount; at -100: 30% markup |
| **Ally Intervention Chance** | `max(0, relationship × 0.01)` | relationship: -100 to +100 | At +50: 50% chance ally intervenes; at -50: 0% |
| **Permadeath Survival Roll** | `random(0, 100) < (relationship + 50)` | relationship with dying character | High relationship = chance to survive fatal event |

## Edge Cases

1. **Player tries to reload a save to undo a choice**: The game allows this (save files are player-owned), but the game does not prevent or discourage it. Each save file is its own timeline — loading an earlier save restores the pre-choice state for that file only.

2. **Choice references a character who is already dead (permadeath)**: The choice is automatically hidden. The dialogue graph skips over any ChoiceNode that requires a dead character as a target. This prevents broken dialogue branches.

3. **All choices in a node have conditions the player doesn't meet**: The dialogue falls back to a default "no choice" branch defined by the narrative designer. This should never happen in shipped content — it's a content authoring safety net.

4. **Major decision overlay triggered during combat dialogue**: Combat pauses (pause menu state) while the dramatic overlay plays. The player has unlimited time to decide. Combat resumes when the choice is made.

5. **Reputation reaches extreme values (-100 or +100)**: Further shifts in the same direction are clamped (no overflow). A notification appears at the extremes: "Your actions have defined you." — this is the only time the player is told their reputation matters.

6. **Multiple relationship targets affected by one choice**: All deltas are applied simultaneously. Example: sparing an enemy might increase Evelyn's trust (+10) while decreasing Evan's respect (-5) if Evan wanted the enemy dead.

7. **Chapter ends with unresolved choice consequences**: All pending consequences are resolved at chapter end. If a choice's consequence is "the village is safe/dangerous in the next chapter," that flag is set before the next chapter loads.

8. **New Game+ carries over choice knowledge but not choice state**: In New Game+, the player starts with a "memory" flag that unlocks bonus dialogue (characters reference the previous playthrough), but story flags, relationships, and reputation all reset to zero.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Dialogue System | Reads + Driven by | Hard — choices are dialogue graph nodes | `ChoiceNode` definitions in dialogue graphs |
| Chapter State System | Writes | Hard — stores story flags | `SetFlag(key, value)`, `GetFlag(key)` |
| Character Data | Reads | Hard — reads character IDs, main character flags | `CharacterData.IsMainCharacter`, `CharacterData.Id` |
| Multiple Endings | Writes | Hard — provides ending calculation data | `GetReputation()`, `GetAllRelationships()` |
| Save / Load | Serialized | Hard — persists all choice state | JSON: `storyFlags`, `relationships`, `reputation` |
| Shop System | Reads | Soft — reads relationships for pricing | `GetRelationship(characterId)` |
| Party Management | Reads | Soft — reads permadeath flags | `IsPermaDead(characterId)` |
| Cutscene System | Calls | Soft — triggers permadeath cutscenes | `PlayCutscene("permadeath_" + characterId)` |
| Combat System | Reads | Soft — reads relationships for ally events | `GetRelationship(characterId)` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `ChoicesPerChapter` | int | `4` | 2-8 | Players feel overwhelmed; decision fatigue | Choices feel inconsequential |
| `MaxRelationshipDelta` | int | `20` | 10-40 | Single choice swings relationships too far | Choices don't feel impactful |
| `MaxReputationShift` | int | `15` | 5-25 | Reputation swings feel jarring and arbitrary | Moral choices feel meaningless |
| `ShopPriceInfluence` | float | `0.003` (0.3% per point) | 0.001-0.005 | Relationships dominate shop prices | Relationships don't affect shops |
| `AllyInterventionBase` | float | `0.01` (1% per relationship point) | 0.005-0.02 | Allies save player too often | Allies never help |
| `MajorDecisionThreshold` | int | `10` | 5-20 | Too many dramatic moments; player numbed to them | No dramatic moments; choices feel flat |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Choice appears in dialogue | Choice buttons slide up from bottom of dialogue box | Soft "decision" chime | High |
| Major decision overlay | Screen dims, 2-4 illustrated cards fan out with character portraits | Deep bass note — gravity shifts | High |
| Choice confirmed | Selected option highlights, others fade out | Confirming click — decisive sound | High |
| Relationship shift (hidden) | No direct visual — manifests through character expression change in portrait | Subtle tone shift in character's voice line (if voiced) | Medium |
| Reputation extreme reached | Brief full-screen vignette: "Your actions have defined you." | Ominous or warm chord depending on direction | High |
| Permadeath triggered | Brief cutscene (5-10s) — character's final moment, portrait fades to gray | Somber music sting, then silence | High |
| Conditional choice revealed | "New option available" indicator glows on the choice button | Sparkle sound — unlocking feel | Medium |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **Dialogue Choice Buttons** | 2-4 choice options as buttons within the dialogue box | Shown when a DialogueNode has Choices[] |
| **Major Decision Overlay** | Full-screen dramatic overlay with 2-4 illustrated cards (icon, display text, extended description) | Shown when ChoiceNode.IsMajorDecision = true |
| **Relationship Summary** (New Game+ only) | "In your previous life, [Character] trusted you deeply" — summary of key relationships from prior playthrough | Shown during New Game+ intro |

## Acceptance Criteria

- [ ] Choices appear correctly within dialogue UI for standard ChoiceNodes
- [ ] Major decision overlay triggers for ChoiceNodes with IsMajorDecision = true
- [ ] Story flags are set correctly in Chapter State when choices are made — verified by unit test
- [ ] Relationship values are modified correctly (clamped to -100..+100) — verified by unit test
- [ ] Reputation shifts are applied correctly (clamped to -100..+100) — verified by unit test
- [ ] Conditional choices only appear when their conditions are met
- [ ] Unavailable choices are hidden entirely (not grayed out)
- [ ] Permadeath triggers correctly: character grayed in Party Management, equipment moved to inventory, cutscene plays
- [ ] Main characters (Evelyn, Evan) cannot be permadead by player choice
- [ ] Shop prices reflect relationship values correctly (30% discount at +100, 30% markup at -100)
- [ ] All choice state (flags, relationships, reputation) persists through save/load
- [ ] New Game+ resets choice state but grants bonus dialogue via memory flags
- [ ] Choices referencing dead characters are automatically hidden from dialogue graphs
- [ ] Reputation extreme values (-100 or +100) trigger a one-time notification

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| Should the player ever be told their reputation number directly, or should it always be implicit? | Narrative Director | Resolve during first chapter authoring — recommendation: always implicit, except at extremes |
| Can the player reverse a permadeath through a later choice (e.g., a resurrection quest)? | Game Designer + Narrative Director | Resolve during Chapter 3+ design — recommendation: no for MVP, maybe for Full Vision |
| Should relationship values affect combat AI behavior (loyal allies protect more aggressively)? | AI Programmer | Resolve during Party AI System refinement — adds mechanical depth to relationships |
| How many permadeath-vulnerable characters exist in the base game? | Narrative Director | Resolve during character roster finalization — recommendation: 2-3 secondary characters |
