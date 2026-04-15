# Dialogue Style Guide — My Vampire

> **Author**: Writer Team
> **Status**: Authoritative — all in-game dialogue must conform to this guide
> **Last Updated**: 2026-04-13
> **Version**: 1.0

---

## Purpose

This guide defines the standards for writing, formatting, and organizing all in-game dialogue for *My Vampire*. It covers character voice principles, dialogue rules, emotional beats, subtext, dialect and formality, and the standard template for adding new dialogue to chapter documents.

Every line of dialogue in this game must serve at least one of these purposes: reveal character, advance plot, build emotional investment, or deliver information the player needs. If a line does none of these, cut it.

---

## 1. Character Voice Principles

Each main character has a distinct vocal identity. A player should be able to identify who is speaking without a name tag. The differences are in rhythm, vocabulary, formality, and emotional expression.

### Evelyn

| Dimension | Profile |
|-----------|---------|
| **Rhythm** | Gentle, measured, with deliberate pauses. She considers before she speaks. |
| **Vocabulary** | Everyday words, warm and accessible. No academic or military jargon. |
| **Formality** | Informal but never sloppy. Respectful with strangers, warm with friends, tender with Evan. |
| **Emotional Expression** | Deflects pain with humor. Direct with warmth. Goes quiet when truly afraid. |
| **Verbal Tells** | Trailing off mid-sentence when vulnerable. Using humor to replace what she cannot say. |
| **Taboo** | Never cruel. Never sarcastic at someone's expense. Never uses profanity as emphasis. |
| **Signature Pattern** | Self-deprecating humor that invites the listener in rather than pushing them away. |

**Example contrast:**
> *"I do not need to eat, but have you tasted bread with butter? I refuse to give that up."*

### Evan

| Dimension | Profile |
|-----------|---------|
| **Rhythm** | Steady, direct, structured. Early chapters use fuller sentences; later chapters relax. |
| **Vocabulary** | Hunting and military terminology early (track, sign, spoor, trail, quarry). Plain language later. |
| **Formality** | Moderate to high early. Softens to moderate-low by Chapter 9. |
| **Emotional Expression** | Action-oriented. Expresses feeling through what he does, not what he says. Goes quiet when moved. |
| **Verbal Tells** | Direct questions when processing. Hunting jargon in non-combat contexts. Rare, significant profanity. |
| **Taboo** | Never theatrical in his anger. Never performs grief. His pain is quiet and real. |
| **Signature Pattern** | Statements of commitment and presence. *"I am here." "I will stay." "I remember."* |

**Example contrast:**
> Chapter 1: *"The creature's trail leads north. I will pursue."*
> Chapter 9: *"Your tail is doing that thing again. The happy thing. You can just say you are happy."*

### The Witch

| Dimension | Profile |
|-----------|---------|
| **Rhythm** | Precise, unhurried, economical. Every sentence is complete and purposeful. |
| **Vocabulary** | Healing metaphors, Weald imagery, the Mage's teachings. Never Church or military terminology. |
| **Formality** | High. Deliberate. Sparingly uses contractions. Not archaic — intentional. |
| **Emotional Expression** | Controlled, except when speaking of the Mage. Then precision softens into lyricism. |
| **Verbal Tells** | Pauses before continuing from emotional topics. Goes quieter when feeling more. |
| **Taboo** | Never raises her voice. Never pleads. Never begs. Her power speaks for her. |
| **Signature Pattern** | *"I will burn the parchment."* — the vow as refrain, delivered differently each time. |

**Example contrast:**
> *"I am not here to argue. I am here to end this."*
> *"He believed magic was a language the world spoke to itself. I believed it was a tool. He was right."*

### Cat Magical Beast

| Dimension | Profile |
|-----------|---------|
| **Rhythm** | Slow, deliberate, alien. Speaks in observations, not commands. |
| **Vocabulary** | Literal but riddling. Its statements are technically accurate but framed in ways mortals find cryptic. |
| **Formality** | Neither formal nor informal. It speaks as something that does not recognize the distinction. |
| **Emotional Expression** | Detached amusement. Indifference. It does not hate, love, or judge. It observes. |
| **Verbal Tells** | Layered, echoing voice (multiple versions of the same thought spoken simultaneously). |
| **Taboo** | Never explains itself fully. Never offers comfort. Never apologizes. |
| **Signature Pattern** | Statements that sound like riddles but are literal observations from a non-human perspective. |

### Party Members (General Guidelines)

Each party member (names and backstories TBD) must have:

- A **distinct rhythm** that differs from Evelyn (gentle), Evan (steady), and the Witch (precise).
- A **vocabulary domain** tied to their background (e.g., a defected Church guard uses tactical language, a village healer uses herbal and medical terms).
- A **formality level** that places them on the spectrum from casual to formal, not overlapping with any main character.
- At least **one verbal tic or habit** — a phrase they repeat, a way they start sentences, a verbal pause.
- An **emotional expression style** — how they show anger, fear, joy, and grief differently from the main cast.

---

## 2. Dialogue Rules

### 2.1 Maximum Line Length

**Every dialogue line must be under 120 characters.**

This includes all punctuation and spaces. This limit exists for:

- **Text box fitting:** Godot UI text boxes are sized for short lines. Long lines overflow or require scroll.
- **Readability:** Players read dialogue during gameplay. Short lines are scannable and digestible.
- **Voice acting:** If/when lines are voiced, 120 characters maps to approximately 3-5 seconds of speech — a natural conversational unit.

**Enforcement:** All dialogue submitted for implementation must pass a character count check. Lines over 120 characters will be rejected.

**Long thoughts:** If a character has more than 120 characters to say, split into multiple dialogue nodes. Use the dialogue system's sequencing to play them consecutively. A pause between nodes is more dramatic than a wall of text.

```
// WRONG (141 characters):
"I've been protecting this village for months now, and nobody even knows it's me, and honestly sometimes I wonder if that's how it should be."

// RIGHT (split into two nodes, both under 120):
Node 1: "I've been protecting this village for months. Nobody even knows it's me."
Node 2: "Sometimes I wonder if that's how it should be."
```

### 2.2 Named Placeholders for Variables

When dialogue references a variable value (character name, item name, location, number), use a named placeholder with the format `{placeholder_name}`.

**Supported placeholders:**

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{player_name}` | The player character's name (if customizable) | `"Well met, {player_name}."` |
| `{character_name}` | A specific character's name | `"Evan, wait—"` |
| `{item_name}` | An item's display name | `"Take this {item_name}. You will need it."` |
| `{location_name}` | A location's display name | `"We head for {location_name} at dawn."` |
| `{quest_target}` | Current quest objective | `"The {quest_target} is our priority."` |
| `{bond_level}` | Relationship bond level (numeric or label) | `"We have come far. ({bond_level})"` |

**Resolution:** Placeholder values are resolved at runtime by the DialogueSystem. Writers must coordinate with systems/programming on the exact placeholder taxonomy.

### 2.3 Localization-Ready Format

All dialogue must be written with localization in mind:

- **No idioms that do not translate.** Avoid culture-specific expressions like "break a leg" or "piece of cake." Use literal language: "good luck," "easy task."
- **Avoid puns and wordplay.** These rarely survive translation and create rework for every target language.
- **Sentence structure should be SVO-friendly.** Subject-Verb-Order is the most common cross-linguistic pattern. Complex nested clauses create translation ambiguity.
- **Context notes for translators.** Each dialogue line in the string table must include a context comment explaining who is speaking, the situation, and any emotional subtext. Example:
  ```
  # Context: Evelyn to Evan, Chapter 9, camp scene. Warm, playful, tail is curling.
  "Your tail is doing that thing again. The happy thing. You can just say you are happy."
  ```
- **Gender-neutral where possible.** Unless the speaker's gender is relevant to the line, avoid gendered address terms.
- **Preserve emotional tone across languages.** A line that is funny in English must be funny in Japanese, French, and Spanish. If the humor does not translate, the line should be rewritten, not translated literally.

### 2.4 Dialogue Node Structure

Every dialogue entry in a chapter document must include:

```markdown
**[Node ID]** `[CHARACTER]` — `[Context: where, when, to whom]`

> "Dialogue line here."

**Branches:** (if applicable)
- Option A: "Player response A" → [Next node]
- Option B: "Player response B" → [Next node]

**Notes:** (emotional subtext, voice direction, localization notes)
```

---

## 3. Emotional Beats

Dialogue carries emotion. The way a character speaks in Chapter 1 should differ from how they speak in Chapter 11, reflecting their emotional journey.

### Emotional Progression by Character

#### Evelyn

| Chapter Range | Emotional State | Dialogue Characteristics |
|---------------|-----------------|-------------------------|
| Prologue | Fear, confusion | Short sentences. Questions. Disbelief. *"What is happening to me?"* |
| Ch 2-4 | Secrecy, discovery | Guarded warmth. Humor as deflection. *"Passing through. That is all."* |
| Ch 5-7 | Bonding, purpose | Relaxed humor. Direct warmth. Uses names. *"Evan, you worry too much."* |
| Ch 8-10 | Deepening, dread | Longer pauses. Moments of stillness. Lines that feel like they are being stored. *"Look at this sunset. Really look."* |
| Ch 11 | Acceptance, vanishing | Quiet, tender, unafraid for herself but afraid of leaving. *"Remember me, Evan."* |
| Epilogue | (Absent) | Her absence is expressed through other characters' memories and the empty spaces she left. |

#### Evan

| Chapter Range | Emotional State | Dialogue Characteristics |
|---------------|-----------------|-------------------------|
| Ch 1 | Certainty, loyalty | Formal, structured, hunting jargon. Reports and observations. *"The trail leads north."* |
| Ch 3-4 | Doubt, betrayal | Questions. Shorter sentences. Frustration. *"This does not make sense."* |
| Ch 5-7 | Purpose, bonding | Relaxed. Contractions increase. Direct affection. *"I am not going anywhere."* |
| Ch 8-10 | Determination, awareness | Focused, protective, holding on. *"Stay close. Both of you."* |
| Ch 11 | Loss, solitude | Quiet. Breaking control. *"Evelyn— no."* |
| Epilogue | Remembrance | Internal monologue. Sparse. Reflective. *"The village is quiet now."* |

#### The Witch

| Chapter Range | Emotional State | Dialogue Characteristics |
|---------------|-----------------|-------------------------|
| Witch Prologue | Love, then devastation | Warm with the Mage. Shattered after. The vow: precise, furious, absolute. |
| Ch 6-7 | Shadow presence | Indirect dialogue through records and environmental storytelling. |
| Ch 8-10 | Campaign, determination | Cold, precise, purposeful. Unwillingness to fight the party shows in restraint. |
| Ch 11 | Confrontation, release | Explains. Fights. Thanks them. *"I am so tired."* Voice breaks for the first time. |

### Cross-Chapter Dialogue Evolution

Track how specific recurring conversations change across chapters:

- **Evelyn and Evan's first meeting:** Ch 3 (hostile) → Ch 4 (allied) → Ch 7 (comfortable) → Ch 9 (intimate) → Ch 11 (final).
- **The Witch's vow:** Prologue (rage) → Ch 8 (resolve) → Ch 11 (release).
- **Party greetings:** Ch 5 (formal introductions) → Ch 7 (familiar warmth) → Ch 10 (weight of impending loss).

---

## 4. Subtext Guide

What characters do not say is as important as what they do. Subtext is the emotional truth beneath the spoken words.

### Evelyn's Subtext

| What She Says | What She Means |
|---------------|----------------|
| *"I am just passing through."* | I have nowhere else to go, and I am afraid to admit that. |
| *"The ears are useful, honestly. Great for hearing monsters coming."* | I hate them. I hate that everyone sees them before they see me. |
| *"Do not worry about me."* | Please worry about me. Please notice that I am not alright. |
| *"Look at that sunset. Really look at it."* | I want to remember this. I want you to remember this with me. |
| *"It is fine. Really."* | It is not fine. But I will carry it so you do not have to. |

### Evan's Subtext

| What He Says | What He Means |
|---------------|----------------|
| *"The trail is cold here. We should regroup."* | I am worried about you. I do not want to push too far. |
| *"I was following orders."* | I was wrong. I know it now. I am trying to tell you I am sorry. |
| *"Your tail is doing that thing again."* | I notice everything about you. I want you to know that. |
| *"I will handle the rear."* | I will protect you. Always. Even when you do not need it. |
| *"We will figure this out."* | I do not know how. But I will not let you face it alone. |

### The Witch's Subtext

| What She Says | What She Means |
|---------------|----------------|
| *"I am not here to argue."* | I cannot bear to be challenged on this. If I doubt, I will break. |
| *"The creatures suffer. I end their suffering."* | I could not end his suffering in time. I will not fail again. |
| *"I do not seek your understanding."* | I am desperate for someone to understand, but I cannot ask. |
| *"You remind me of someone."* | You remind me of him, and it is the most painful thing I have felt in ten years. |
| *"Thank you."* | You showed me that I was wrong, and it is a gift I do not deserve. |

### General Subtext Principles

1. **The player should feel the subtext before understanding it.** Evelyn's pauses, Evan's formality retreating under stress, the Witch's quiet intensity — these should register emotionally before the player articulates why.
2. **Subtext is chapter-dependent.** A line that carries subtext in Chapter 3 may be literal in Chapter 9 as relationships deepen. Track the evolution.
3. **Never explain the subtext in dialogue.** Characters do not say "I am using humor to hide my pain." They make the joke, and the player reads the pain underneath.
4. **Silence is subtext.** A character who does not respond is saying something. Evelyn trailing off, Evan going quiet, the Witch pausing — these are all dialogue.

---

## 5. Dialect and Vernacular

This world does not use heavy dialect or regional accents in dialogue. The setting is fantasy but the speech is accessible modern English with subtle texture. The differences between characters come from **formality level**, **vocabulary domain**, and **rhythm** rather than phonetic spelling or regional slang.

### Formality Spectrum

```
Most Formal                              Least Formal
The Witch → Evan (Ch 1) → Evan (Ch 9) → Evelyn → Party Members → Blacksmith
```

- **The Witch:** Most formal. Deliberate, precise, sparing with contractions. Never casual.
- **Evan (Chapter 1):** Structured, report-like, Church terminology. Formal but not stiff.
- **Evan (Chapter 9+):** Relaxed, natural contractions, direct. Formal in crisis, informal in comfort.
- **Evelyn:** Informal but never sloppy. Warm, accessible, uses contractions naturally. Respectful with strangers.
- **Party Members:** Varies by background. A defected Church guard speaks more formally; a village farmer speaks more casually.
- **The Blacksmith:** Most casual. Direct, warm, practical. Uses contractions, colloquialisms, and regional flavor without becoming inaccessible.

### Vocabulary Domains

| Character | Vocabulary Sources | Avoid |
|-----------|-------------------|-------|
| Evelyn | Village life, practical tasks, warmth, nature | Academic, military, Church, or technical jargon |
| Evan | Hunting, tracking, Church doctrine (early), plain language (late) | Flowery language, academic terms, excessive profanity |
| The Witch | Healing, the Weald, the Mage's teachings, metaphor | Church terminology, military jargon, casual slang |
| Cat Beast | Observation, literal description, alien perspective | Human idioms, emotional language, explanations |
| Blacksmith | Craft, tools, practical life, warmth | Abstract philosophy, Church doctrine, academic terms |

### Regional Variation

The game world has subtle regional speech patterns that add texture without creating localization barriers:

- **Village speech:** Slightly older phrasing ("I do not" instead of "I don't" in earnest moments), nature-adjacent metaphors, community-focused language.
- **Church speech:** Structured, doctrinal, authoritative. Uses words like "cleansing," "purification," "the sacred duty." After the truth is revealed, these terms are abandoned by characters who leave the Church.
- **Weald-adjacent speech:** People who live near the Deep Weald (Evelyn, the Witch, the blacksmith) use nature metaphors and practical language. They speak of roots, soil, weather, and growing things.

### Profanity

Profanity is used sparingly and meaningfully:

- **Mild:** "damn," "hell" — used by Evelyn and Evan in frustration. Rare for the Witch.
- **Moderate:** "god," "gods" — used by Evan only when emotionally shattered. Once or twice in the entire game.
- **Severe:** No extreme profanity exists in this world's vocabulary. The tone does not call for it.

The rule is: **if a character swears, it must matter.** Swearing is an emotional event, not verbal seasoning.

---

## 6. Dialogue Format Template

Use this template when adding new dialogue to any chapter document. Every dialogue sequence must follow this structure.

### 6.1 Single Node

```markdown
**[NODE_ID]** `[CHARACTER]` — `[Location, story moment, addressee]`

> "Dialogue line under 120 characters."

**Notes:** [Emotional subtext, voice direction, animation cues]
```

### 6.2 Branching Node

```markdown
**[NODE_ID]** `[CHARACTER]` — `[Location, story moment, addressee]`

> "Dialogue line under 120 characters."

**Branches:**
- `[OPTION_A]` "Player response A." → `[NEXT_NODE_A]`
- `[OPTION_B]` "Player response B." → `[NEXT_NODE_B]`
- `[OPTION_C]` "Player response C." → `[NEXT_NODE_C]`

**Notes:** [What each branch reveals about the player's relationship state]
```

### 6.3 Multi-Node Sequence

```markdown
#### [SEQUENCE_NAME] — [Brief description of the scene]

**[NODE_1]** `EVELYN` — [Context]

> "First line under 120 characters."

**[NODE_2]** `EVAN` — [Context]

> "Response under 120 characters."

**[NODE_3]** `EVELYN` — [Context]

> "Continuation under 120 characters."

**Notes:** [Full sequence emotional arc, how it connects to surrounding nodes]
```

### 6.4 Ambient Dialogue

```markdown
**[AMBIENT_ID]** `[CHARACTER]` — `[Area tag, story phase, combat state]`

> "Ambient line under 120 characters."

**Conditions:**
- Area: `[area_tag]`
- Story Phase: `[before_reveal | after_reveal | post_church | witch_campaign | final]`
- Combat State: `[exploration | pre_combat | in_combat | post_victory | post_defeat]`
- Party: `[required party member present]`
```

### 6.5 Internal Monologue

```markdown
**[MONOLOGUE_ID]** `[CHARACTER]` — `[Location, story moment]`

> "Internal thought under 120 characters."

**Delivery:** `[voice_over | on_screen_text | environmental_trigger]`
**Notes:** [What the player learns from this that dialogue cannot convey]
```

### 6.6 File Organization

Dialogue for each chapter should be organized in the chapter's design document under a dedicated **Dialogue Sequences** section, with nodes grouped by:

1. **Story-critical sequences** — Major plot dialogue that advances the narrative
2. **Bond sequences** — Character relationship dialogue that deepens emotional investment
3. **Ambient dialogue** — Area-triggered, story-phase-dependent, combat-state-dependent lines
4. **Internal monologue** — POV character's thoughts during gameplay

Each chapter document must cross-reference the character profile files in `design/narrative/characters/` for voice guidance.

---

## 7. Quality Checklist

Before any dialogue is committed to a chapter document, verify:

- [ ] Every line is under 120 characters
- [ ] Named placeholders are used for variable references
- [ ] Character voice matches their profile in `design/narrative/characters/[character].md`
- [ ] Subtext is present but not stated explicitly
- [ ] Emotional state matches the chapter's emotional pacing map
- [ ] No idioms or wordplay that would not survive translation
- [ ] Context notes are included for translator reference
- [ ] Profanity (if any) is meaningful and earned
- [ ] The line serves at least one purpose: reveal character, advance plot, build emotion, or deliver information
- [ ] The line would be identifiable as belonging to this character without a name tag

---

## 8. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-13 | Writer Team | Initial dialogue style guide — all sections authored |
