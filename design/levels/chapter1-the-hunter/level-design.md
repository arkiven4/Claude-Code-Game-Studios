# Chapter 1: "The Hunter"

**Chapter Number**: 1
**POV Characters**: Evan
**Duration**: 30-40 minutes
**Emotional Arc**: Trust (Evan is righteous, Church is good) -> Confidence (Evan is competent, world makes sense) -> Unease (cracks appear — monsters dying with strange energy)
**Prerequisites**: Prologue completion

---

## Overview

Chapter 1 introduces Evan — a Church knight sent to investigate a village where monsters have been dying mysteriously. The player controls Evan through a structured hunting experience: receiving his mission, tracking monsters through the wild, engaging in competent combat, and discovering evidence that does not fit the Church's narrative. By the end of the chapter, Evan has performed his duty faithfully, but small cracks have appeared in his certainty. Strange magical energy signatures on dead monsters. Church deflections when he asks questions. The seeds of doubt have been planted — though Evan does not yet recognize them as such.

This chapter establishes Evan as a capable, likable protagonist operating within a system the player (who saw the Prologue) already knows is corrupt. The dramatic irony is intentional and powerful.

---

## Level Flow

### Section 1: The Mission

- **Location**: Church outpost — warm, functional, lived-in. Knights preparing for the day. A chapel bell ringing.
- **Gameplay**: Dialogue sequences, brief exploration, equipment check
- **Enemies**: None
- **Loot**: Church-issued Essence Resonance Detector (key item), standard knight gear
- **Narrative Beats**:
  1. Evan reports for duty. He is competent, respected, and trusted.
  2. He receives his mission: investigate reports of monsters dying near a village on the Weald's edge. Something is killing them. The Church wants to know what.
  3. Evan is issued his equipment — most importantly, the Essence Resonance Detector.
  4. Brief interaction with a parish priest who blesses his journey. The priest is genuinely kind. Evan is genuinely grateful.
  5. Evan departs. The player sees the Church at its best — and knows (from the Prologue) what it hides.
- **Triggers**:
  - `ch1_evan_quarters` — Ambient: Evan's quarters. Sparse, functional. A worn hunting journal on the desk. Player can read entries showing Evan's dedication and competence.
  - `ch1_briefing` — Cutscene: Evan receives his mission from a senior knight. "Something is killing monsters near Oakhaven village. Find out what. Report back."
  - `ch1_equipment` — Interactive: Evan collects his gear. The Essence Resonance Detector is explained. "It reads magical signatures. Clean means natural. Anything else... investigate and report."
  - `ch1_priest_blessing` — Dialogue: Parish priest offers a blessing. Warm, genuine. "May the Light guide your hand, Sir Evan."
  - `ch1_departure` — Cutscene: Evan rides out. Camera follows. The outpost shrinks behind him.

### Section 2: The Trail

- **Location**: Forest and moorland between the Church outpost and Oakhaven village. Open hunting grounds.
- **Gameplay**: Tracking investigation, light combat with wild monsters, evidence discovery
- **Enemies**: Shadow wolves (2-3), forest wraiths (1-2), crystal-backed tortoise (1, optional)
- **Loot**: Monster materials (crafting), old Church vial (story item), abandoned campsite notes
- **Narrative Beats**:
  1. Evan tracks through the forest, using his detector and reading signs.
  2. He encounters and defeats wild monsters competently — this is his job, and he is good at it.
  3. He finds the first dead monster — dissolved, as magical creatures do. But his detector picks up something strange: a "dirty" magical signature. Residual energy that does not match natural dissolution patterns.
  4. He finds more dead monsters — all with the same anomalous signature. Something is killing them, and it is not natural.
  5. He discovers an old Church vial near one of the bodies. Empty. Discarded. This does not make sense — Church vials are carefully tracked.
  6. He finds an abandoned campsite with notes referencing "subject transport" and "essence yield." He does not yet understand what he is looking at.
- **Triggers**:
  - `ch1_tracking_start` — Gameplay: Evan begins tracking. Player uses detector to follow magical signatures. Tutorial prompt for detector usage.
  - `ch1_first_combat` — Combat: Shadow wolves. Evan fights with Church-trained efficiency. Player learns combat basics.
  - `ch1_first_anomaly` — Story Beat: Evan examines a dissolved monster corpse. Detector reads the dirty signature. "This magical energy... it is not natural."
  - `ch1_more_bodies` — Story Beat: Evan finds 2-3 more dead monsters, all with the same anomaly. "This is the third. Same signature. Something is hunting them."
  - `ch1_church_vial` — Story Beat: Evan finds the empty Church vial. He picks it up. "This is Church glass. Out here? That is not right."
  - `ch1_abandoned_camp` — Story Beat: Evan investigates the campsite. Reads the notes. "Subject transport... essence yield... these are not hunting notes. These are —" He stops. He does not have the framework to understand what he is reading. Yet.

### Section 3: Oakhaven Village

- **Location**: Oakhaven — a small farming village on the edge of the Weald. Warm, humble, grateful.
- **Gameplay**: Investigation through dialogue, village exploration, final combat encounter
- **Enemies**: Rogue magical creature (1, drawn to the village by disturbed ley lines)
- **Loot**: Village gratitude gift (consumables), elder's information (story), final evidence piece
- **Narrative Beats**:
  1. Evan arrives at Oakhaven. The villagers are wary but respectful of a Church knight.
  2. He interviews villagers about the monster deaths. They confirm: monsters have been dying, but they do not know why. Some are relieved — fewer monsters means safer roads. Others are uneasy — something is changing, and change is frightening.
  3. The village elder speaks with Evan privately. They have noticed something else: a "presence" that protects the village at night. They do not know what it is. They do not want to. "Some questions, Sir Knight, are better left unasked."
  4. A rogue magical creature attacks the village — drawn by the disturbed ley lines from all the deaths. Evan fights and defeats it.
  5. After the fight, Evan uses his detector one more time on the creature's remains. The dirty signature is strongest here — whatever is killing monsters is close. Very close.
  6. Evan prepares his report for the Church. He files it honestly, including the anomalies. He does not yet know what the anomalies mean, but his training demands accurate reporting.
- **Triggers**:
  - `ch1_village_arrival` — Cutscene: Evan arrives at Oakhaven. Village life unfolds around him. Warm, normal, safe.
  - `ch1_villager_interviews` — Dialogue Sequence: Evan speaks with 2-3 villagers. Each provides a piece of the puzzle but none understand the full picture.
  - `ch1_elder_conversation` — Dialogue Sequence: The elder speaks privately. "Something protects us at night. We do not ask what. We are grateful."
  - `ch1_village_attack` — Combat: Rogue creature attacks. Evan defends the village. Competent, efficient, heroic.
  - `ch1_final_detection` — Story Beat: Evan scans the creature's remains. The dirty signature is strongest yet. "Whatever is doing this... it is close. And it is powerful."
  - `ch1_report_filed` — Cutscene: Evan writes his report. He includes everything. The anomalies. The vial. The camp. He sends it to the Church. He does not know it yet, but this report will bring him back.

---

## Level Layout

### Church Outpost (Opening)
```
[Chapel] --- [Knight Quarters] --- [Evan's Room]
                     |
              [Briefing Hall]
                     |
              [Equipment Room]
                     |
              [Main Gate] --- [Road to Oakhaven]
```

Linear, warm, functional. The outpost is a place Evan knows well. Every NPC here is friendly and competent. The player should feel safe here — which makes the later betrayal harder.

### The Trail (Hunting Grounds)
```
[Outpost Road]
      |
[Forest Entry] --- [Wolf Territory] --- [Wraith Marsh]
      |                                       |
[First Anomaly Site]                   [Church Vial Site]
      |                                       |
      \------------[Abandoned Camp]----------/
                        |
                  [Path to Oakhaven]
```

Semi-open area. The player can explore in any order, but the narrative beats are sequenced: first anomaly -> more bodies -> vial -> camp. Each discovery builds on the last. The area is large enough to feel like a hunt but small enough to stay focused.

### Oakhaven Village
```
              [Village Gate]
                   |
           [Central Square]
           /      |       \
    [Store]  [Well]   [Blacksmith]
       |                  |
[Elder's House]    [Village Perimeter]
       |
[Chapel (small)]
```

Compact, warm, detailed. The village is designed to feel lived-in — NPCs have routines, children play, smoke rises from chimneys. The perimeter wall is visible but modest. This is the first version of the village hub system.

---

## Encounter Design

### Encounter 1: Shadow Wolves
- **Location**: Forest, early in the trail
- **Enemies**: 2-3 shadow wolves (beast-type, non-sentient)
- **Difficulty**: Easy — tutorial encounter
- **Mechanics**:
  - Wolves attack in packs, attempting to flank
  - Evan uses standard Church knight combat: sword strikes, defensive stances, anti-creature tactics
  - Player learns: basic attack, dodge, detector usage during combat
- **Environmental Hazards**: Dense forest limits visibility. Wolves can emerge from shadows.
- **Loot**: Wolf essence residue (crafting material)

### Encounter 2: Forest Wraiths
- **Location**: Marsh area, mid-trail
- **Enemies**: 1-2 forest wraiths (humanoid-type, minimally sentient)
- **Difficulty**: Medium — introduces tactical thinking
- **Mechanics**:
  - Wraiths phase in and out of visibility
  - Evan's detector tracks their signature even when invisible
  - Player must use detector to locate and engage wraiths
- **Environmental Hazards**: Marsh terrain slows movement. Patches of unstable ground.
- **Loot**: Wraith essence (crafting material), strange energy residue (story-relevant)

### Encounter 3: Crystal-Backed Tortoise (Optional)
- **Location**: Hidden cave off the main trail
- **Enemies**: 1 crystal-backed tortoise (beast-type, defensive)
- **Difficulty**: Medium-Hard — optional challenge
- **Mechanics**:
  - Tortoise has high defense, low offense
  - Player must find and attack weak points (joints, underbelly)
  - Rewards rare crafting materials
- **Environmental Hazards**: Narrow cave, limited maneuvering space
- **Loot**: Crystal shell fragment (rare crafting material)

### Encounter 4: Rogue Creature (Village Attack)
- **Location**: Oakhaven village, central square
- **Enemies**: 1 rogue magical creature (type varies — designed to feel unpredictable)
- **Difficulty**: Medium — showcase encounter
- **Mechanics**:
  - Creature is agitated, confused — its dirty signature is visible throughout
  - Evan fights to protect villagers (some flee, some watch from windows)
  - This is Evan's most heroic moment in the chapter
- **Environmental Hazards**: Village structures can be damaged. Evan must avoid hitting buildings.
- **Loot**: Creature essence (crafting), village gratitude gift (consumables)

---

## Environmental Storytelling

### Church Outpost
- Banners and religious iconography everywhere — the Church's public face is genuine here
- Knights train in the yard. They are disciplined, focused, and proud of their work
- A memorial wall lists knights who died fighting monsters. Evan pauses at one name — a mentor or friend
- The chapel is warm and well-kept. The priest inside is praying for the knights who ride out today
- Evan's quarters: a hunting journal with detailed entries. Each entry is accurate, thorough, and reveals his competence. The last entry reads: "Something is killing monsters near Oakhaven. I will find out what."

### The Trail — Anomaly Sites
- **First dead monster**: The dissolution is incomplete — residue remains on the ground. Evan's detector picks up the dirty signature. The area feels wrong, like the magical energy was ripped out rather than released naturally.
- **Church vial**: Lying in the dirt, half-buried. Standard Church-issue glass. The label has been scratched off but a number remains: "VII-". This is the seventh in a series.
- **Abandoned campsite**: Fire pit, bedrolls, a crude table with papers. The papers reference "subject transport," "essence yield," and "control seal integrity." Evan reads them but lacks the context to understand. He files them as evidence. The papers are written in clinical language — the same language Veyss uses.
- **General trail atmosphere**: The forest is unusually quiet. Fewer birds, fewer insects. The magical deaths have disturbed the local ecosystem. Evan notes this in his journal.

### Oakhaven Village
- The village is warm and lived-in. NPCs go about their daily routines
- Children play a game of "knight and monster" — reflecting the Church's cultural influence
- A notice board lists monster sightings (some real, some exaggerated), Church tithes due, and a request for help with fence repair
- The elder's house is the largest building, with books and maps. The elder is educated and perceptive
- The blacksmith's forge is active. The blacksmith is working on a plow, not a sword — this is a peaceful place
- The small chapel has a traveling priest's schedule posted. The priest visits monthly. The villagers are faithful but not fanatic

---

## Pacing

```
Time (min)    Section                          Intensity
0-5           Church outpost, mission briefing  Low (routine, warmth)
5-10          Ride out, forest entry            Low-Medium (anticipation)
10-15         Shadow wolf combat                Medium (competence, confidence)
15-18         First anomaly discovery           Medium (curiosity, wrongness)
18-22         Wraith encounter + detection      Medium-High (tactical, engaging)
22-25         Church vial + campsite discovery  Medium (confusion, unease)
25-30         Oakhaven arrival, interviews      Low (warmth, community)
30-33         Elder conversation                Low-Medium (intrigue, mystery)
33-36         Village attack combat             High (heroic, competent)
36-38         Final detection                   Medium (unease building)
38-40         Report filed, chapter close       Low (satisfaction with undertow)
```

Chapter 1 is designed to feel like a competent professional doing their job well. The combat is satisfying, the investigation is engaging, and the world feels good. But beneath the surface, anomalies accumulate. The player who paid attention to the Prologue will recognize the dirty signatures as evidence of Church-made creatures. Evan does not yet know this. The gap between what the player knows and what Evan knows is the chapter's primary source of tension.

---

## Dependencies

- **Combat System**: Church knight combat — sword attacks, dodge, defensive stances, detector-based targeting
- **Detection System**: Essence Resonance Detector — reads magical signatures, distinguishes clean vs. dirty, guides player to objectives
- **Dialogue System**: NPC interactions, branching conversations, ambient village dialogue
- **Character Models**: Evan (Church knight armor), Church knights, parish priest, villagers (elder, blacksmith, store owner, children), shadow wolves, forest wraiths, rogue creature
- **Environmental Assets**: Church outpost (interior + exterior), forest trail, marsh, abandoned campsite, Oakhaven village
- **Audio**: Evan's internal monologue (grounded, measured), hunting jargon, Church bells, village ambient sounds, combat audio, detector sound effects (clean vs. dirty signatures sound different)
- **Journal System**: Evan's hunting journal — auto-updates with discoveries, serves as quest log

---

## Acceptance Criteria

- [ ] Player controls Evan from mission briefing through investigation to report filing
- [ ] Church outpost opening establishes Evan as competent, respected, and faithful
- [ ] Essence Resonance Detector is introduced and used throughout the chapter
- [ ] At least 3 combat encounters: shadow wolves, forest wraiths, village attack
- [ ] Detection-based gameplay: player uses detector to find wraiths and track anomalies
- [ ] Anomaly discovery sequence: first body -> more bodies -> Church vial -> abandoned camp
- [ ] Evan's internal monologue reflects growing unease without conscious doubt
- [ ] Oakhaven village feels warm, lived-in, and culturally distinct from the Church outpost
- [ ] Elder conversation hints at the "secret guardian" (Evelyn) without revealing her
- [ ] Evan files an honest report including all anomalies — setting up his return in Chapter 3
- [ ] All dialogue lines are under 120 characters
- [ ] Evan's speech is formal and structured (Chapter 1 voice)
- [ ] Total playtime is between 30-40 minutes
- [ ] Environmental storytelling communicates the Church's public goodness and hidden corruption simultaneously
- [ ] The chapter ends with a sense of completion (mission done) but an undertow of unease (anomalies unexplained)
