# Prologue: "The Curse"

**Chapter Number**: Prologue
**POV Characters**: Evelyn (human -> cat-cursed), The Witch (playable flashback)
**Duration**: 15-20 minutes
**Emotional Arc**: Curiosity (who is this woman?) -> Devastation (watching love destroyed) -> Determination + Dread (understanding the Witch's vow)
**Prerequisites**: None — this is the game's opening experience

---

## Overview

The Prologue is a two-part experience that establishes the entire emotional foundation of the game. First, the player controls Evelyn as a normal human woman who wanders into the Deep Weald, disrespects the Cat Magical Beast, and is cursed — gaining cat ears, a tail, and abilities she does not understand. Before she can process what has happened, the Church captures her.

The sequence then shifts to the Witch Prologue — "The Day the Sun Goes Cold" — played ten years earlier. The player experiences the Witch's love, her loss, and her vow firsthand. This is not a cutscene. The player IS the Witch's grief.

Together, these two sequences establish: Evelyn's origin and the source of her powers, the Church's cruelty, the Witch's tragedy, and the emotional stakes that make Chapter 11 devastating.

---

## Level Flow

### Section 1: The Deep Weald — Evelyn's Descent

- **Location**: The Deep Weald — ancient forest, spiraling trees, wrong shadows, thinning boundary between physical and magical
- **Gameplay**: Guided exploration -> environmental puzzle -> boss encounter (Cat Beast) -> transformation cutscene -> brief ability tutorial -> ambush and capture
- **Enemies**: None (the Weald itself is the threat), Cat Magical Beast (non-combat encounter)
- **Loot**: None
- **Narrative Beats**:
  1. Evelyn flees through the Weald (reason unspecified — bandits, storm, lost path)
  2. The Weald warps around her — paths loop, shadows point wrong
  3. She encounters the Cat Magical Beast
  4. She laughs at it — not from malice, from disbelief
  5. The Cat curses her — not punishment, consequence
  6. Cat ears and tail appear. She discovers new abilities.
  7. Church ambush captures her before she can escape
- **Triggers**:
  - `prologue_weald_entry` — Cutscene: Evelyn enters the Weald, camera shows reality warping
  - `prolude_weald_loop` — Environmental: player walks a path that loops back on itself (teaching the Weald's rules)
  - `prologue_cat_encounter` — Cutscene: the Cat appears, Evelyn speaks dismissively, the Cat responds
  - `prologue_curse_triggered` — Cutscene + VFX: transformation sequence — ears burst through hair, tail emerges, body shudders
  - `prologue_cat_beast_dialogue` — The Cat speaks its riddle. Evelyn processes what happened.
  - `prolude_ability_tutorial` — Gameplay: brief tutorial prompts for High Jump (clear a fallen log), Wall Crawl (scale a root wall), Enhanced Senses (hear distant Church knights approaching)
  - `prolude_church_ambush` — Cutscene: Church knights arrive. Evelyn tries to fight but is overwhelmed. Sedated. Captured.

### Section 2: The Small Lab — Evelyn's Imprisonment

- **Location**: Church Small Lab — cold stone, restraints, essence vials glowing on shelves, ritual circle on the floor
- **Gameplay**: Brief interactive sequence — player attempts to break free (fails), then cutscene to transformation
- **Enemies**: None (player is restrained)
- **Loot**: None
- **Narrative Beats**:
  1. Evelyn wakes in restraints. Inquisitor Veyss speaks clinically.
  2. The vampire transformation begins — essence infusion, archetype catalyst
  3. The Control Litany is chanted. The seal forms — and shatters.
  4. Veyss observes with clinical interest. Orders termination.
  5. Evelyn — newly transformed, enraged — breaks free
  6. Brief escape sequence: Evelyn fights through disoriented guards, flees into the night
- **Triggers**:
  - `prolude_lab_awakening` — Cutscene: Evelyn wakes. Veyss speaks. No emotion. Just data.
  - `prolude_transformation` — Cutscene + VFX: essence flows into Evelyn. Body transforms. Pale skin, red-tinged eyes, canines elongate. Player feels power surge.
  - `prolude_seal_failure` — Cutscene: Control Litany chanted. Seal forms visually — then cracks, shatters. Veyss: "Fascinating."
  - `prolude_escape_combat` — Gameplay: 30-second escape sequence. Player has full vampire abilities for the first time. Guards are weak. This is power fantasy mixed with terror — the player should feel both the thrill of new power and the horror of what was done.
  - `prolude_escape_complete` — Cutscene: Evelyn bursts through the lab door into the night. She runs. She does not stop. Transition to black.

### Section 3: Witch Prologue — "Her Name Was..."

- **Location**: Witch's cabin -> Deep Weald path -> Church outpost -> burning ruins
- **Gameplay**: Exploration and domestic moments -> investigation and pursuit -> boss combat -> vow cutscene
- **Enemies**: Church knights (3-4 encounters), Knight Captain (boss)
- **Loot**: None (prologue is narrative-only)
- **Narrative Beats**:
  1. **Domestic opening**: The player is the Witch. Morning in the cabin. The Mage is there. They debate magic over tea. This is the most peaceful 3 minutes in the entire game.
  2. The Mage leaves to teach in a nearby village. The Witch goes to the Weald to gather herbs.
  3. She returns to find the cabin ransacked. The Mage's broken staff on the floor.
  4. She tracks them. The path is a montage — running, sensing magical residue, growing desperation.
  5. She arrives at the Church outpost as the Knight Captain prepares to move the prisoner.
  6. Combat: the Witch tears through the outpost's defenses. Her power is overwhelming — the player should feel this. This is not a hard fight. It is catharsis.
  7. Boss: Knight Captain. He fights with conviction. He believes he is right. He dies believing it.
  8. She reaches the Mage's cell. Too late. The extraction has damaged him beyond recovery.
  9. His last words: "I'm sorry I couldn't show you everything."
  10. She watches from a distance as the Church completes the extraction. Essence harvested. Stored.
  11. Standing in the burning ruins, she makes her vow: "I will burn the parchment."
  12. Transition: 10 years forward. Prologue ends. Title screen.
- **Triggers**:
  - `witch_prologue_domestic` — Interactive: player walks through the cabin. Interacts with objects. The Mage speaks. This is the only time the player sees the Witch happy.
  - `witch_prologue_discovery` — Cutscene: cabin ransacked. Broken staff. The Witch's voice changes.
  - `witch_prologue_pursuit` — Gameplay: tracking sequence. Player follows magical trail. Increasing urgency.
  - `witch_prologue_outpost_combat` — Gameplay: the Witch fights through Church knights. Her abilities are shown — reality warping, energy projection. The player should feel unstoppable.
  - `witch_prologue_boss` — Cutscene + Combat: Knight Captain confronts the Witch. Short boss fight. The Knight Captain fights well but is outmatched.
  - `witch_prologue_mage_cell` — Cutscene: the Witch finds the Mage. His last words. The extraction.
  - `witch_prologue_vow` — Cutscene: the vow. Camera pulls back from the burning outpost. Silence. Then: 10 years forward. Title card: MY VAMPIRE.

---

## Level Layout

### The Deep Weald
```
                    [Entrance Path]
                          |
                    [Loop Section] <-- player walks this path twice, realizing it loops
                          |
                    [Cat Clearing]  <-- open area, ancient tree, Cat Beast appears
                          |
                    [Ability Gauntlet]
                    /        |        \
              [Jump]    [Crawl]    [Senses]
                    \        |        /
                    [Ambush Point] <-- Church knights arrive
```

The Weald is a linear path with environmental storytelling at every turn. The loop section is the first puzzle — the player walks forward and arrives back at the same clearing. On the second pass, the environment has changed subtly (a branch that was whole is now snapped, a shadow points a different direction) — rewarding observation.

### The Small Lab
```
[Restraint Chair] --- [Veyss Observation Desk]
        |
[Evelyn breaks free]
        |
[Guard Corridor] --- [Essence Storage] --- [Exit Door]
```

Small, claustrophobic, oppressive. Low ceiling. Cold stone. Glowing vials on shelves. The escape is linear — break free, fight through 2-3 guards, exit. No exploration — the player is desperate to escape.

### Witch's Cabin
```
              [Garden]
                |
[Cabin Interior] --- [Front Door] --- [Path to Weald]
    |
[Mage's Desk]    [Herbalist Shelf]    [Shared Bed]
```

Warm. Sunlit. Lived-in. Books everywhere. Tea cups. This is the only truly safe, peaceful space in the entire game. The player should feel the contrast when it is destroyed.

### Church Outpost (Witch Prologue)
```
                    [Outer Wall] --- [Guard Post]
                          |
                    [Courtyard]
                    /           \
            [Barracks]      [Mage's Cell]
                                  |
                            [Extraction Chamber]
                                  |
                            [Escape Route] --- [Burning Ruins]
```

The outpost is a small facility. The Witch's path is linear — wall, courtyard, cell. The Knight Captain boss fight occurs in the courtyard. The extraction chamber is visible but unreachable during combat — the player can see it through a window, building dread.

---

## Encounter Design

### Encounter 1: Witch vs. Church Patrol
- **Location**: Weald path, mid-pursuit
- **Enemies**: 3 Church knights (standard)
- **Difficulty**: Trivial — this is a power demonstration
- **Environmental Hazards**: None
- **Design Notes**: The Witch's abilities are shown, not taught. Player has access to energy blasts and a shield. Knights fall in 1-2 hits. This establishes the Witch's power level for later chapters.

### Encounter 2: Knight Captain (Boss)
- **Location**: Church outpost courtyard
- **Enemies**: Knight Captain (single boss)
- **Difficulty**: Medium — the Knight Captain fights with conviction and skill
- **Mechanics**:
  - Knight Captain uses blessed weapon strikes (holy energy — the Witch's one vulnerability preview)
  - Phases: 1 (standard combat) -> 2 (Knight Captain prays, gains temporary buff) -> 3 (desperation attacks)
  - The Witch's emotional resonance ability activates in Phase 3 — her power increases as she nears the Mage's cell
- **Environmental Hazards**: None
- **Design Notes**: The Knight Captain is not evil. He is a good man doing what he believes is right. His dialogue during the fight reflects this: "I will not let you pass." "He is dangerous." "You do not understand what you are doing." The player should feel conflict — this man does not deserve to die, but he is in the way.

### Encounter 3: Evelyn's Escape
- **Location**: Small Lab corridors
- **Enemies**: 2-3 disoriented guards
- **Difficulty**: Trivial — power fantasy
- **Design Notes**: This is the player's first taste of Evelyn's vampire abilities. Full strength, full speed, full blood magic. It should feel incredible and terrifying simultaneously.

---

## Environmental Storytelling

### Deep Weald
- Trees grow in spirals, not straight trunks
- Shadows point in directions that light sources cannot explain
- Flowers bloom in colors that do not have names (described through Evelyn's internal monologue)
- A snapped branch on the ground that Evelyn steps over — later, after the loop, the branch is whole again
- The Cat Beast's clearing: an ancient tree with a hollow at its base filled with bones — not prey bones, but the remains of things that came here and were changed
- After the curse: Evelyn's reflection in a pool of water shows her cat ears and tail for the first time. The player sees what she sees.

### Small Lab
- Essence vials on shelves, each labeled with a creature type and a number. Some labels are scratched out and replaced.
- A ledger on Veyss's desk: subject numbers, transformation dates, outcomes. Most entries end in "TERMINATED." Evelyn's entry is the first marked "ESCAPED."
- Restraint chair with scratch marks from previous subjects
- A faded prayer on the wall — someone in this lab once believed in what they were doing
- The ritual circle on the floor: geometric patterns, runes, the outline of a human body where Evelyn lay

### Witch's Cabin
- Two tea cups on the desk — one cold, one still warm
- Books stacked everywhere: magical theory, herbalism, ethics, philosophy
- The Mage's staff, broken, on the floor near the door
- A garden outside — half-tended, the Witch left in a hurry
- A sketch on the wall: the Mage's drawing of the two of them, laughing. The Witch does not take it. She cannot bring herself to.

### Church Outpost
- Wanted posters with the Mage's face: "Dangerous Sorcerer. Report to nearest Church authority."
- A small chapel in the corner of the outpost — the knights who guarded the Mage were devout. They believed they were doing the right thing.
- The extraction chamber: crystalline vessels, now full of glowing essence. A label reads: "SOURCE: MAGE. POTENCY: MAXIMUM. HANDLE WITH EXTREME CAUTION."
- The burning ruins at the end: everything is fire and smoke. The Witch walks through it unharmed. She does not look back.

---

## Pacing

```
Time (min)    Section                          Intensity
0-2           Evelyn enters the Weald           Low (curiosity)
2-5           The Weald loops                   Medium (confusion)
5-7           Cat Beast encounter               Medium-High (alien, unsettling)
7-8           The curse triggers                High (transformation, body horror)
8-10          Ability tutorial                  Medium (wonder + urgency)
10-11         Church ambush                     High (capture, helplessness)
11-13         Lab imprisonment                  Medium (Veyss, dread)
13-14         Transformation + escape           Very High (power fantasy)
14-15         Evelyn flees into night           Low (quiet, disoriented)
--- TRANSITION ---
15-18         Witch domestic scene              Very Low (peace, warmth)
18-19         Discovery of ransacked cabin      Medium (panic, pursuit)
19-20         Tracking through Weald            Medium-High (urgency)
20-22         Outpost combat                    High (catharsis, power)
22-23         Knight Captain boss               High (conflict, conviction)
23-24         Mage's last words                 Very High (devastation)
24-25         Essence harvesting observed       High (horror, helplessness)
25-26         The Vow                           Peak (resolve, dread)
26-27         10 years forward -> Title         Low (anticipation)
```

The Prologue is a rollercoaster with two distinct halves. Evelyn's half is about loss of control — cursed, captured, transformed. The Witch's half is about loss of meaning — love, destroyed, avowed. Both end with the character fundamentally changed. The player should feel exhausted and emotionally invested before Chapter 1 begins.

---

## Dependencies

- **Cutscene System**: Godot CutscenePlayer with camera control, dialogue integration, and VFX triggers
- **Character Models**: Evelyn (human form, cat-cursed form, vampire form), Witch (younger/older variants), Cat Beast, Mage, Church knights, Knight Captain, Veyss
- **Transformation VFX**: Curse transformation sequence (ears, tail, body changes), vampire transformation sequence
- **Environmental VFX**: Weald warping (spiraling trees, wrong shadows), dissolution effects, fire and smoke for outpost
- **Combat System**: Basic melee for Evelyn's escape, Witch's magic abilities (energy blasts, shields, reality warping)
- **Audio**: Cat Beast voice (layered, echoing), Witch voice (low, resonant), Mage voice (warm, gentle), Veyss voice (cold, clinical), ambient forest sounds, Church chanting, burning outpost
- **Input System**: Godot Input System for movement, ability activation, interaction prompts

---

## Acceptance Criteria

- [ ] Player controls Evelyn (human) entering the Deep Weald and experiences the looping path
- [ ] Cat Beast encounter plays with full dialogue and the Cat's alien voice design
- [ ] Curse transformation cutscene triggers with visible ear/tail appearance
- [ ] Player briefly tutorials High Jump, Wall Crawl, and Enhanced Senses abilities
- [ ] Church ambush cutscene plays and Evelyn is captured
- [ ] Lab imprisonment sequence includes Veyss dialogue and the Control Litany failing
- [ ] Evelyn's escape sequence is playable with vampire abilities
- [ ] Witch Prologue domestic scene establishes the Mage and their relationship
- [ ] Witch tracking sequence leads to Church outpost
- [ ] Knight Captain boss fight is playable with Witch abilities
- [ ] Mage's last words cutscene plays with full emotional weight
- [ ] Essence harvesting is shown from the Witch's perspective
- [ ] The Vow cutscene plays: "I will burn the parchment"
- [ ] Transition to title screen: 10 years forward, game title appears
- [ ] Total playtime is between 15-20 minutes
- [ ] All dialogue lines are under 120 characters
- [ ] Environmental storytelling details are present in each area (Weald warping, lab details, cabin warmth, outpost horror)
