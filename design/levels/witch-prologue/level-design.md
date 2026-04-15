# Witch Prologue: "Her Name Was..."

**Chapter Number**: Witch Prologue (playable, chronologically 10 years before main game)
**POV Characters**: The Witch
**Duration**: 35-45 minutes
**Emotional Arc**: Love and warmth -> Devastation and rage -> Hollow resolve
**Prerequisites**: None (this is the first playable experience if the game begins here; alternatively unlocked after Chapter 7)

---

## Overview

The Witch Prologue is the emotional pivot of the entire game. The player experiences the Witch's story firsthand — not as a villain, but as a woman who loved someone, lost everything, and made a vow in the ashes. This prologue reframes every encounter with the Witch that follows. When the party fights her in Chapter 11, the player will remember this.

The prologue is divided into two halves: **Before** — a brief but vivid domestic scene with the Mage, establishing their love, their debates, their life together — and **After** — the Church raid, the Witch's desperate pursuit, the outpost massacre, and the vow. The contrast between the two halves is the entire point. The player must feel what was lost.

The Witch is POWERFUL in this prologue. The player should feel overwhelming magical strength — reality bending to her will, enemies crumbling before her rage. But the gameplay deliberately undercuts this power: no amount of force can save the Mage. Her strength is hollow, and the prologue's design makes the player feel that hollowness.

---

## Level Flow

### Section 1: "The Cabin" — Before

- **Location**: The Witch and the Mage's cabin on the edge of the Deep Weald
- **Gameplay**: Light exploration, interaction with domestic objects, one short conversation with the Mage
- **Enemies**: None
- **Loot**: None — only environmental interaction
- **Narrative Beats**:
  1. The player opens on a morning in the cabin. Sunlight through windows. The Mage is at his desk, reading, surrounded by books and half-finished tea. The Witch is gathering herbs — she is about to leave for the Weald.
  2. The player can interact with objects around the cabin. Each triggers a short memory or observation: the Mage's staff leaning against the wall, a half-finished argument written on a chalkboard, herbs drying on a rack, two cups on the desk.
  3. A brief conversation with the Mage. He is warm, intellectual, slightly absent-minded. They debate something small — whether to screen magic students — and it is clear this is an argument they have had a hundred times. They love each other. This is not told. It is shown.
  4. The Witch leaves for the Weald to gather herbs. The Mage waves from the doorway. This is the last time she sees him alive.
- **Triggers**:
  - `witch_pro_cabin_open` — Cutscene: Morning light. The cabin. The Mage at his desk. "You think magic is a system. I think it is a language. We will argue about this forever." The Witch smiles. She picks up her herb basket. "I am going to the Weald. Do not forget to eat." "I never forget. I just... delay."
  - `witch_pro_cabin_explore` — Interactive: Player explores the cabin. Interacting with key objects triggers short ambient lines:
    - **Mage's Staff**: "Carved from a Weald oak. He says it channels his energy. I say it channels his habit of gesturing when he talks."
    - **Chalkboard**: Half-finished debate: "Screen students?" / "Gate knowledge? For what?" — their unresolved argument.
    - **Herbs on Rack**: Drying bundles. Practical healing supplies. The Witch's domain.
    - **Two Cups**: On the Mage's desk. One cold, one still warm. A small detail. A life.
  - `witch_pro_mage_dialogue` — Dialogue Sequence: The Mage looks up from his book. "You are going out again. The Weald is damp this time of year." "Someone has to keep you alive. You forget to eat." "I do not forget. I... prioritize differently." A pause. He smiles. "Come back safely." "I always do."
  - `witch_pro_departure` — Cutscene: The Witch walks out of the cabin into the Weald. The Mage stands in the doorway, staff in hand, watching her go. He waves. She waves back. She does not look back again. She cannot know this is the last time.

### Section 2: "The Weald" — Gathering

- **Location**: The edge of the Deep Weald — forest paths, herb patches, a quiet clearing
- **Gameplay**: Gentle gathering, ambient nature, the last peaceful moments
- **Enemies**: None
- **Loot**: Herb collection (narrative, not gameplay-functional)
- **Narrative Beats**:
  1. The Witch walks through the Weald, gathering herbs. The environment is beautiful, alive, peaceful. Birds, filtered sunlight, moss, the smell of earth and growing things.
  2. She gathers herbs mechanically — this is familiar, routine work. Her mind is elsewhere. She thinks about the Mage, about their argument, about the book he is reading.
  3. Something feels wrong. A distant sound — not natural. She pauses, listens, and dismisses it. She is wrong to dismiss it.
  4. The gathering is complete. She turns back toward the cabin.
- **Triggers**:
  - `witch_pro_weald_walk` — Ambient: The Weald is alive. Birds, wind, light through canopy. The Witch hums quietly — a tune the Mage likes.
  - `witch_pro_gathering` — Gameplay: Player collects 3-4 herb types from designated spots. Simple, meditative. The last peaceful gameplay in the prologue.
  - `witch_pro_ominous` — Internal Monologue: A distant sound. Like... voices? Metal? She pauses. "Probably hunters. Or the wind." She continues gathering. She is wrong.
  - `witch_pro_return` — Cutscene: Her basket is full. She turns back. The Weald seems... quieter. She walks faster.

### Section 3: "The Cabin, Ransacked"

- **Location**: The cabin — destroyed
- **Gameplay**: Discovery, investigation, tracking
- **Enemies**: None
- **Loot**: The Mage's broken staff (story-critical)
- **Narrative Beats**:
  1. The cabin is destroyed. Furniture overturned. Books scattered. The Mage's desk is smashed. His tea cup lies shattered. The herbs she left on the counter are scattered on the floor.
  2. The Witch searches frantically. Calling his name. No answer.
  3. She finds the staff. Broken on the floor. Deliberately placed — a message.
  4. She tracks them. Her magical intuition reads the residue — Church ritualists, knights, heading northeast toward the outpost. She runs.
- **Triggers**:
  - `witch_pro_discovery` — Cutscene: The cabin door is broken open. She drops her basket. Herbs scatter. "Hello?" Silence. The interior is destroyed. Her voice changes — not yet screaming, but the quiet of someone whose world is tilting. "No. No, no, no."
  - `witch_pro_search` — Gameplay: Player searches the cabin. Each interactable reveals a piece of the destruction:
    - **Desk**: Smashed. His books torn. "No—"
    - **Floor**: The broken staff. She picks it up. Her hands shake. "They left this. They left it as a message."
    - **Door**: Kicked in. Boot marks. Church insignia on the wood.
  - `witch_pro_tracking` — Internal Monologue: She follows the magical trail. "Church. Knights. Ritualists. Northeast. The outpost." Her voice is flat now. The kind of flat that comes after the first wave of panic and before the rage. "I am coming."

### Section 4: "The Outpost" — Arrival

- **Location**: Church outpost — a small fortified facility on the edge of Weald territory
- **Gameplay**: Infiltration, first combat encounters, escalating violence
- **Enemies**: Church outpost guards (6-8), automated ward systems (2)
- **Loot**: Church guard equipment, outpost map, prisoner transfer documents
- **Narrative Beats**:
  1. The Witch arrives at the outpost as the Knight Captain is preparing to move the Mage to a larger facility. She can hear orders being given through the walls.
  2. She enters. Not stealth — purpose. Guards challenge her. She does not stop.
  3. Her magical power awakens — not trained, not controlled, but born of pure grief and love and terror. It is overwhelming. She tears through the outer defenses like they are paper.
  4. The Knight Captain confronts her. He is a good man who believes he is protecting the world from a dangerous sorceress. He dies fighting her. She does not hesitate.
- **Triggers**:
  - `witch_pro_outpost_approach` — Cutscene: The outpost looms. Stone walls, Church banners, guards at the gate. She can hear voices inside. "—transfer at dawn. The prisoner is secured." Her eyes close. He is alive. She has time. "Let me in."
  - `witch_pro_combat_1` — Combat: Church guards attempt to stop her. She does not know how to fight — her magic acts on instinct. Energy blasts, reality warping, environmental destruction. It is raw and uncontrolled and devastating. The player should feel the power and the lack of control simultaneously.
  - `witch_pro_captain_confrontation` — Cutscene: The Knight Captain steps into the corridor. He is armored, armed, and resolute. "You are the one who destroyed the outer wall. Stand down. The prisoner is Church property." "He is not property. He is a person." "He is a threat to everything we have built." "Then what you have built deserves to burn." Combat begins.
  - `witch_pro_captain_combat` — Mini-Boss: Knight Captain. He fights with conviction — blessed weapons, defensive formations, Church knight techniques. He believes he is right. The Witch fights with grief-fueled power that is raw but overwhelming. She wins not because she is a better fighter — she wins because she has nothing left to lose.

### Section 5: "Too Late"

- **Location**: Outset prison cell -> Extraction chamber
- **Gameplay**: Narrative sequence, no gameplay — the extraction has already begun
- **Enemies**: None
- **Loot**: None
- **Narrative Beats**:
  1. The Witch fights through the last of the outpost's defenders and reaches the prison block. She is too late — the extraction ritual has already begun.
  2. She finds the Mage in the extraction chamber. He is broken, fading, the ritual having already damaged him beyond recovery. The ritualists fled when she breached the facility.
  3. Their last conversation. He apologizes. She cannot bear it. He dies.
  4. She watches from the outpost window as Church riders arrive to collect the extracted essence. She cannot stop them. They take everything that was him and leave nothing.
- **Triggers**:
  - `witch_pro_prison_block` — Cutscene: She kicks open the cell door. He is on the floor. The extraction apparatus is still running — magical energy being siphoned into vials. He is conscious but fading. "You came." "I am here. I am here. I will get you out." "It is too late for me. But not for you."
  - `witch_pro_last_words` — Dialogue Sequence: The Mage is dying. His voice is weak but clear. "I am sorry I could not show you everything." She is holding him. Her hands — the healer's hands that set bones and mixed remedies — cannot fix this. "Do not. Do not apologize. You showed me everything that matters." He smiles. His eyes close. The extraction apparatus continues running. The vials glow brighter.
  - `witch_pro_extraction_complete` — Cutscene: The apparatus finishes. The vials are full — the most concentrated magical essence the Church has ever harvested. Church riders arrive outside to collect them. She watches from the window. She could go out there. She could fight them. But he is gone, and the vials are not him. She lets them take the essence. This is the moment her power becomes meaningless.

### Section 6: "The Vow"

- **Location**: Burning outpost ruins
- **Gameplay**: Cutscene only
- **Enemies**: None
- **Loot**: None
- **Narrative Beats**:
  1. The Witch stands in the ruins of the outpost. The Knight Captain is dead. The Mage is dead. The Church has taken his essence. The building burns around her — she did not set the fire consciously, but her grief did.
  2. She holds the broken staff. She looks at the burning world.
  3. She makes her vow. Not shouted. Not whispered. Spoken with the precision of someone who has just decided the rest of her life.
  4. Transition to 10 years later — the main game begins.
- **Triggers**:
  - `witch_pro_vow` — Cutscene: She stands in the burning ruins. The broken staff in her hands. The outpost crumbles around her. She is very still. When she speaks, her voice is low, precise, and absolute: "They wrote his death on parchment. Treaties. Doctrines. Records. I will burn the parchment. Every treaty. Every doctrine. Every lie they wrote in magic's name." She looks at the burning sky. "No one will lose what I lost. Not ever again."
  - `witch_pro_transition` — Cutscene: The fire consumes the screen. When the light fades, 10 years have passed. The Witch's stronghold. The broken staff, preserved in suspended time. The Witch — older, harder, exhausted — standing over maps and ley line diagrams. "It is time." Transition to main game.

---

## Level Layout

```
[Cabin Interior]
    |
[Cabin Door] -> [Weald Path] -> [Herb Clearing] -> [Weald Path] -> [Cabin Door]
                                                          |
                                                  [Cabin - Ransacked]
                                                          |
                                                  [Forest Trail - Tracking]
                                                          |
                                                  [Outpost Outer Wall]
                                                    /           \
                                           [Outer Guards]   [Ward Systems]
                                                  \           /
                                                  [Outpost Interior]
                                                        |
                                               [Knight Captain Fight]
                                                        |
                                                [Prison Block]
                                                        |
                                               [Extraction Chamber]
                                                        |
                                              [Outpost Window - Watch]
                                                        |
                                               [Burning Ruins - Vow]
```

The prologue is a linear path with one loop (the Weald gathering area). The cabin is visited twice — once intact, once destroyed — and the emotional contrast between the two visits is the primary design tool.

---

## Encounter Design

### Encounter 1: Outpost Outer Guards
- **Location**: Outset perimeter
- **Enemies**: 4-6 Church outpost guards
- **Difficulty**: Medium (but the Witch's power makes it feel easy — this is intentional)
- **Mechanics:** The Witch's magic is raw and instinctive. Energy blasts, environmental warping, shield generation. The player should feel overwhelmingly powerful but emotionally hollow. Controls are simple — the power does the work.

### Encounter 2: Outpost Ward Systems
- **Location**: Outpost interior corridors
- **Enemies**: 2 automated ward systems
- **Difficulty**: Low-Medium
- **Mechanics:** Wards create magical barriers. The Witch's intuition-based magic can sense their frequency and disrupt them. A brief puzzle-combat hybrid.

### Encounter 3: Knight Captain (Mini-Boss)
- **Location**: Outpost main corridor
- **Enemies:** Knight Captain (boss)
- **Difficulty**: Medium-High (but manageable — the Witch's grief-fueled power tips the scales)
- **Mechanics:**
  - Knight Captain uses blessed weapons, defensive stances, and Church knight techniques. He fights with conviction.
  - The Witch has no formal combat training — her magic is pure instinct and emotion. She overwhelms through raw power, not technique.
  - The fight should feel tragic, not triumphant. The Knight Captain believes he is right. The Witch knows she is past caring.
- **Boss Dialogue:**
  - Captain: "Stand down. You do not know what you are doing."
  - Witch: "I know exactly what I am doing."
  - Captain: "He is a threat to everything."
  - Witch: "He was everything. And you took him."

---

## Environmental Storytelling

### The Cabin (Before)
- **Lighting**: Warm morning sunlight through windows. Golden hour feel.
- **Details**: Two cups on the desk. A half-finished argument on a chalkboard. Herbs drying on a rack. Books stacked everywhere. The Mage's staff leaning against the wall. A garden visible through the window. This is a lived-in, loved space.
- **Sound**: Birds, wind, the scratch of the Mage's pen, the Witch humming.

### The Cabin (After)
- **Lighting**: Harsh, grey. The warm light is gone.
- **Details**: Everything from the "Before" visit is destroyed but recognizable. The cups are shattered. The chalkboard is cracked — but the argument is still visible. The herbs are scattered. The desk is smashed. The staff is broken and deliberately placed on the floor.
- **Sound**: Silence. Wind through broken windows. The Witch's breathing.

### The Outpost
- **Lighting**: Cold, clinical. Church-issued lanterns. Stone walls.
- **Details**: The Knight Captain's quarters — a prayer book, a letter to his family, a medal. He is a person. The extraction chamber — cold metal, glowing vials, the apparatus still running. The prison cell — scratched walls, a blanket on the floor.
- **Sound**: Alarms, boots on stone, the hum of the extraction apparatus.

### The Burning Ruins
- **Lighting**: Fire. Orange and red and smoke. The Witch is silhouetted against the flames.
- **Details**: Everything burning. The broken staff in her hands. The Church banners melting. The outpost that held him — gone.
- **Sound**: Fire crackling. Distant shouting. The Witch's voice — calm, precise, absolute.

---

## Pacing

```
Cabin (Before)     -> Weald Gathering  -> Cabin (After)     -> Outpost Infiltration -> Vow
Warm, quiet        -> Gentle, meditative -> Shock, searching -> Escalating violence -> Hollow resolve
5-7 min            -> 5-8 min            -> 5-7 min          -> 12-15 min            -> 3-5 min

Combat intensity:   Low                  None                 None                  Medium-High            None
Emotional intensity: High (warmth)       Medium (unease)      Very High (loss)      Very High (rage)       Peak (vow)
```

The prologue is designed so that the player experiences the full arc — love, normalcy, loss, rage, and resolve — in under 45 minutes. The gameplay shifts from gentle domestic interaction to devastating violence, with the emotional intensity driving the experience rather than mechanical complexity.

---

## Dependencies

- **Playable Witch Character**: The Witch as a playable character with her full power set (reality warping, energy projection, intuition-based magic)
- **Cabin Environment Asset**: Detailed interior with two states (intact and destroyed)
- **Weald Environment Asset**: Forest environment with herb gathering points
- **Outpost Environment Asset**: Church outpost with guards, wards, prison block, extraction chamber
- **Mage Character Model**: For the brief domestic scene and death scene
- **Knight Captain Character Model**: Mini-boss encounter
- **Cutscene System**: For the opening, departure, discovery, last words, and vow sequences
- **Environmental State System**: Cabin must exist in two states and be transitionable
- **Audio**: Warm cabin ambience, Weald nature sounds, Church outpost alarms and boots, fire crackling, emotional music swells
- **VFX**: Witch's raw magic (uncontrolled, devastating), extraction apparatus glow, fire VFX

---

## Acceptance Criteria

- [ ] Player experiences the Witch's domestic life with the Mage through exploration and one conversation
- [ ] Cabin has two distinct states (intact and destroyed) with recognizable environmental contrast
- [ ] Weald gathering section is gentle, meditative, and establishes the Witch's practical nature
- [ ] Cabin discovery scene triggers appropriate emotional response — searching, finding the broken staff, tracking
- [ ] Outpost combat demonstrates the Witch's raw, overwhelming power but emotional hollowness
- [ ] Knight Captain mini-boss fight is tragic, not triumphant — he believes he is right
- [ ] Last conversation with the Mage is devastating and under 120 characters per line
- [ ] The vow scene is delivered with precision, not shouting — "I will burn the parchment"
- [ ] Transition to 10 years later is clean and sets up the main game
- [ ] All dialogue lines are under 120 characters
- [ ] The Witch's power feels overwhelming but the outcome feels inevitable — no amount of force saves the Mage
- [ ] Player who completes this prologue understands the Witch is not a villain but a broken person
