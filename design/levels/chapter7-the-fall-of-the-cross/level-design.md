# Chapter 7: "The Fall of the Cross"

**Chapter Number**: 7
**POV Characters**: Evelyn & Evan (alternating)
**Duration**: 90-110 minutes
**Emotional Arc**: Determination (assault begins) -> Triumph (Church defeated) -> Dread (Witch records found -- bigger threat coming)
**Prerequisites**: Prologue, Chapters 1-6 completion

---

## Overview

Chapter 7 is the Church arc's climax. The party assaults the Church Stronghold -- "The Cross" -- in the biggest combat set piece the game has produced so far. This is not a raid. This is a full-scale assault: multiple entry points, layered defenses, escalating encounters, and a leadership boss fight that tests every skill the player has developed.

The chapter is structured as a dungeon crawl through the most fortified building in the region. The Stronghold is part cathedral, part fortress, part research facility -- a physical manifestation of the Church's dual nature. Its public face is the cathedral: beautiful, grand, inspiring. Its private face is the facility beneath: cold, clinical, monstrous. The player fights through both.

After the Church leadership is defeated and the Stronghold falls, the party discovers something unexpected: records about the Witch. Not Church propaganda -- real intelligence, gathered by the Church's most secretive division. The Witch is not just a shadow. She is an archmage with a decade of preparation, a movement of followers, and a plan that the Church has been desperately trying to understand and counter. The records reveal the scope of her campaign, the depth of her power, and a terrifying detail: the Church's intelligence suggests that the Witch's plan is not just to destroy the Church. It is to eliminate all magical creatures from the world.

Evelyn is a magical creature. The party realizes, with growing dread, that the Witch's victory would mean Evelyn's death. The Church was an enemy they chose to fight. The Witch may be a threat they cannot fight -- because defeating her might be the same thing as killing Evelyn.

The chapter ends with the party standing in the ruins of the Church Stronghold, victorious but terrified. They won. But they just learned that winning might not be enough.

---

## Level Flow

### Section 1: The Approach

- **Location**: World map -> The Cross approach road -> Outer perimeter
- **Gameplay**: Tactical approach, final preparations, party dialogue
- **Enemies**: Church outer patrols (minimal -- the party approaches through untracked terrain)
- **Loot**: None
- **Narrative Beats**:
  1. The party approaches the Stronghold from an unexpected direction -- not the main road, but through the surrounding forest and hills. Evan has studied the Stronghold's defenses and identified blind spots.
  2. Final preparations: gear checks, role confirmations, last-minute bond dialogue. The mood is focused and determined. No one jokes.
  3. Evelyn and Evan share a private moment. Not a farewell -- a grounding. "Whatever happens in there, we do it together." "Together."
  4. The party reaches the outer perimeter. The Stronghold looms -- massive, imposing, beautiful from the outside. The contrast between its public grandeur and private horror has never been sharper.
  5. The assault begins.
- **Triggers**:
  - `ch7_approach` -- Cutscene: The party approaches through the forest. The Stronghold becomes visible through the trees. It is enormous -- walls within walls, towers, a cathedral spire rising above everything. "That is the Cross. The center of everything."
  - `ch7_final_prep` -- Interactive: Gear check. Role confirmation. Player can speak with each party member for a final word. Each response is brief, focused, determined.
  - `ch7_evelyn_evan` -- Dialogue: Private moment. Evelyn: "Whatever happens in there, we do it together." Evan: "Together." No more needs to be said.
  - `ch7_assault_begin` -- Cutscene: The party takes position. Evan gives the signal. The assault begins.

### Section 2: Outer Defenses

- **Location**: The Cross outer walls -> Courtyard -> Cathedral entrance
- **Gameplay**: Breach and clear, multi-path assault
- **Enemies**: Church elite guards (12-15), automated defenses (essence-dampening fields, locked gates), Church-made creature guards (2-3)
- **Loot**: Church guard equipment, outer defense schematics
- **Narrative Beats**:
  1. The outer walls are the first layer of defense. The party must breach through one of three entry points: the main gate (direct assault), a sewer entrance (stealth, cramped), or a wall breach point (cat abilities, vertical).
  2. Each entry point leads to the same courtyard but offers different challenges and rewards. The party splits to maximize efficiency, then regroups in the courtyard.
  3. The courtyard is the first open combat area -- multiple waves of guards, defensive positions, and Church-made creature guards. The party fights together to clear it.
  4. The cathedral doors are locked from the inside. The party must breach them -- a moment of symbolic weight: they are breaking into the Church's holiest space to expose its darkest secret.
- **Triggers**:
  - `ch7_entry_choice` -- Gameplay: Three entry options. Main gate (combat-heavy, straightforward), sewer (stealth, environmental hazards, flanking advantage), wall breach (Evelyn's Wall Crawl required, isolated, leads to guard barracks first).
  - `ch7_courtyard_combat` -- Combat: Multi-wave defense of the courtyard. Guards from multiple directions. Church-made creatures deployed as weapons.
  - `ch7_cathedral_breach` -- Cutscene: The party stands before the cathedral doors. Massive, ornate, inscribed with religious text. Evan: "Behind these doors is everything they showed the world. And everything they hid from it." Evelyn: "Then let us show them what is behind the doors." They breach.

### Section 3: The Cathedral

- **Location**: Cathedral interior -> Hidden passage -> Sub-levels
- **Gameplay**: Exploration, narrative discovery, transition to the facility beneath
- **Enemies**: Church knights (interior guards), Conclave defenders (elite)
- **Loot**: Conclave communications, Cathedral hidden passage access
- **Narrative Beats**:
  1. The cathedral interior is stunning -- stained glass, vaulted ceilings, an altar that seats hundreds. It is genuinely beautiful. The party is struck by the contrast: this space was built for worship, and beneath it lies a facility built for horror.
  2. Interior guards fight with religious conviction -- they genuinely believe they are defending a holy place. They do not know what is beneath their feet.
  3. The party discovers a hidden passage behind the altar -- the Conclave's private route to the facility below. The passage is elegant, well-maintained, and clearly used regularly.
  4. Descending into the passage, the atmosphere shifts: from warm candlelight to cold magical illumination, from stone and wood to metal and glass, from a place of worship to a place of control.
- **Triggers**:
  - `ch7_cathedral_entry` -- Cutscene: The party enters the cathedral. It is magnificent. Sunlight through stained glass. Rows of pews. A grand altar. "It is beautiful." "It is. That is what makes what is beneath it so much worse."
  - `ch7_cathedral_combat` -- Combat: Church knights defend the cathedral. They fight with conviction, using blessed weapon techniques. The environment is fragile -- the party must avoid destroying the stained glass and altar.
  - `ch7_hidden_passage` -- Story Beat: Behind the altar, a hidden mechanism reveals a passage. Stone stairs descending into darkness. "This is how they get from the cathedral to the facility. They walk through holiness to reach horror."
  - `ch7_descent` -- Cutscene: The party descends. The stairs are long. The atmosphere changes with each flight. Warmth fades. Light shifts from candle-orange to magical-blue. The walls change from stone to metal. By the bottom, they are no longer in the cathedral. They are in the machine.

### Section 4: The Facility Beneath

- **Location**: Sub-level facility -- reception, experimentation block, essence vault, Conclave chamber
- **Gameplay**: Multi-area dungeon, escalating encounters, evidence gathering
- **Enemies**: Conclave defenders, elite Church-made creatures, facility automated systems, Inquisitor Veyss (mini-boss)
- **Loot**: Full Conclave records, essence vault access, Inquisitor Veyss's research, Witch intelligence files
- **Narrative Beats**:
  1. The sub-level facility is the Church's true face -- vast, cold, and industrial. It is everything the Small Lab and the Tier 2 facility were, but scaled up to an institutional level.
  2. The party fights through multiple areas: the reception block (administrative), the experimentation block (active, with subjects to free), the essence vault (the largest collection of harvested essence in the game), and the Conclave chamber (where the Church's leadership makes its decisions).
  3. Inquisitor Veyss appears as a mini-boss. Cold, clinical, unbothered by the party's presence. Veyss treats the assault as a "containment event" and attempts to neutralize the party using facility systems. The fight is tactical and personal -- Veyss recognizes Evelyn and comments on her "anomalous status" with the same interest as a scientist observing a specimen.
  4. After Veyss is defeated (they retreat rather than die -- Veyss is too valuable to the Church to risk in a straight fight), the party gains access to the Conclave's private records.
- **Triggers**:
  - `ch7_facility_entry` -- Cutscene: The party emerges from the passage into the facility. "This is it. The real Church. Not the one on the surface. This one."
  - `ch7_experimentation_block` -- Combat + Story: Active experimentation chambers. Party frees subjects. Some are too far gone to save. The Healer member does what they can. "I am sorry. I am so sorry."
  - `ch7_essence_vault` -- Story: The largest essence vault in the game. Thousands of vials. "Every one of these is a life. Taken, bottled, and stored." Evelyn stares at the shelves. "This is what they made me from."
  - `ch7_veyss_encounter` -- Mini-Boss: Inquisitor Veyss. Tactical, using facility systems against the party. Cold commentary throughout: "Subject E-V-7. Your persistence is noted and irrelevant." "The hunter who thinks he is righteous. How predictable."
  - `ch7_veyss_retreat` -- Cutscene: Veyss retreats through an emergency passage. "This facility is lost. The Conclave will relocate. You have won nothing." Evan: "We won this. That is enough."
  - `ch7_conclave_chamber` -- Story + Gameplay: The Conclave's private chamber. Maps, communications, decision records. Party gathers evidence.

### Section 5: The Church Leadership Boss

- **Location**: Conclave chamber -> Stronghold command center
- **Gameplay**: Boss fight -- the Church's leadership
- **Enemies**: Bishop Aldric (boss), Conclave guards (2-3 elite)
- **Loot**: Bishop's confession (story-critical), Conclave surrender documents
- **Narrative Beats**:
  1. The party confronts Bishop Aldric in the command center. Aldric is the Church's public face -- genuinely good, genuinely righteous, and genuinely ignorant of the experiments beneath his feet.
  2. The boss fight is not just combat -- it is a confrontation. Aldric fights with conviction, believing the party are heretics attacking the Church. The party must defeat him while trying to make him understand the truth.
  3. Mid-fight, Evan presents the evidence: the records, the files, the subject lists. Aldric reads them. His face goes through the same stages Evan went through in Chapter 4: disbelief, denial, devastation.
  4. Aldric stops fighting. Not surrender -- collapse. The man who built his life on the Church's righteousness has just learned that the Church is built on lies. He does not rage. He does not argue. He sits down. "All these years. All the villages I blessed. All the knights I sent. What have I --" He cannot finish.
  5. Aldric surrenders. Not to the party -- to the truth. "You are right. I see it now. I -- I do not know how to carry this." The Church leadership is defeated not by force alone but by evidence.
- **Triggers**:
  - `ch7_aldric_confrontation` -- Cutscene: Aldric stands in the command center. He is not armored. He wears his bishop's robes. "You have come a long way to destroy my life's work." Evan: "We did not come to destroy it, Bishop. We came to show you what it is built on."
  - `ch7_aldric_boss` -- Boss Combat: Bishop Aldric + Conclave guards. Aldric fights with conviction -- not with weapons, but with blessed energy and defensive barriers. He is not a warrior -- he is a true believer, and his faith makes him dangerous.
  - `ch7_evidence_presented` -- Cutscene: Mid-fight, Evan presents the evidence. Aldric reads. Stops fighting. Reads more. His hands shake. "This is -- these are -- who authorized --" "The Conclave. Beneath your feet."
  - `ch7_aldric_collapse` -- Dialogue: Aldric processes. The man who was the Church's best face breaks. "I preached compassion. I blessed the knights who -- I -- God forgive me." Evelyn: "God did not do this. People did. And people can stop it."
  - `ch7_aldric_surrender` -- Cutscene: Aldric surrenders. He signs the Conclave's surrender documents. "The Church is over. I will make sure the world knows what it was." The Church is defeated.

### Section 6: The Witch Records

- **Location**: Conclave chamber -> Hidden intelligence vault
- **Gameplay**: Document reading, narrative revelation, party reaction
- **Enemies**: None
- **Loot**: Witch intelligence files (story-critical), Church counter-Witch plans
- **Narrative Beats**:
  1. After Aldric's surrender, the party explores a hidden intelligence vault within the Conclave chamber. This is the Church's most secret archive -- intelligence gathered about the Witch over the past decade.
  2. What they find recontextualizes everything:
     - The Witch is an archmage of unprecedented power, surpassing even Primal Beasts in raw output.
     - She has been systematically destroying Church facilities for months, not weeks. The party's raid was one of many.
     - The Witch's plan is not to defeat the Church. It is to eliminate all magical creatures from the world -- a ritual called the Vanishing.
     - The Vanishing would dissolve all magical energy from the world. Every magical creature -- natural, Church-made, and cursed humans -- would cease to exist.
     - Evelyn is a cursed human. She is a magical creature. The Vanishing would kill her.
  3. The party processes this revelation in real time. The mood shifts from triumph to dread. They just defeated the Church -- but in doing so, they may have cleared the path for something far worse.
  4. Evelyn is quiet. She reads the files. She understands what they mean. She does not share her fear with the party. She will not take this moment from them.
  5. The chapter ends with the party standing in the ruins of the Church Stronghold. The Church has fallen. But the Witch is coming.
- **Triggers**:
  - `ch7_intelligence_vault` -- Story Beat: Hidden vault opens behind the Conclave chamber. "There is more. Something they were keeping from everyone -- even the Bishop."
  - `ch7_witch_files` -- Gameplay: Player reads the Witch intelligence files. Each file reveals a piece of the truth. The Witch's identity. Her power level. Her campaign. The Vanishing. The implication for Evelyn.
  - `ch7_party_reaction` -- Dialogue Sequence: The party processes the revelation. "She is not just fighting the Church. She is -- all of them? Every magical creature?" "If the Vanishing happens --" "Evelyn."
  - `ch7_evelyn_silence` -- Internal Monologue (Evelyn): She reads the files. She understands. The Vanishing would end her. She looks at the party -- at Evan, at the blacksmith's scarf on her shoulders, at the people who gave her a life. She says nothing. She will not say it. Not yet. "Look at that sunset. Really look." (She stores this moment. She stores all of them.)
  - `ch7_chapter_close` -- Cutscene: The party stands on the Stronghold's highest tower, looking out over the region. The Church has fallen. The Witch's shadow is visible on the horizon -- not literally, but the party feels it. "We won." "Did we?" The camera pulls back. The Stronghold is in ruins. The village is safe. But something is coming.

---

## Level Layout

### The Cross -- Overview
```
                    [Cathedral Spire]
                         |
              [Cathedral Interior]
                    /         \
        [Main Nave]        [Side Chapels]
              |
        [Hidden Passage]
              |
    ============================= (Surface / Sub-level boundary)
              |
      [Sub-Level Reception]
         /        |        \
[Experimentation]  [Essence Vault]  [Conclave Chamber]
         \        |        /
      [Command Center (Boss)]
              |
      [Intelligence Vault (Hidden)]
```

The Stronghold is the largest single structure in the game. It has two distinct halves:

**Surface (Cathedral):** Beautiful, grand, warm. Stained glass, vaulted ceilings, religious iconography. This is the Church's public face -- and it is genuine. The cathedral is a real place of worship, maintained by genuine believers.

**Sub-Level (Facility):** Cold, industrial, oppressive. Metal, glass, magical energy. The Church's private face -- where the experiments happen, the essence is stored, and the Conclave makes its decisions.

The transition between the two is the hidden passage behind the altar -- a physical and metaphorical descent from worship to control.

### Entry Points
```
Entry A: Main Gate                  Entry B: Sewer                   Entry C: Wall Breach
[Front Assault]                     [Stealth Infiltration]           [Vertical Approach]
      |                                    |                                |
[Heavy Combat]                     [Environmental Hazards]          [Wall Crawl Required]
      |                                    |                                |
[Courtyard (North)]               [Courtyard (East)]               [Courtyard (South)]
```

All three entry points converge on the courtyard. The choice affects the difficulty and flavor of the outer defense phase but not the overall progression.

### Cathedral Interior
```
              [Main Doors]
                   |
           [Main Nave]
           /          \
    [Side Aisle]  [Side Aisle]
           \          /
            [Altar]
              |
      [Hidden Passage]
```

The cathedral is long and narrow, with the altar at the far end. Combat here must avoid damaging the stained glass windows (environmental constraint). The hidden passage is behind the altar, accessible only after clearing the cathedral's guards.

### Sub-Level Facility
```
[Hidden Passage Exit]
        |
[Reception Block] --- [Administrative Offices]
        |
[Experimentation Block] --- [Chambers 1-4] --- [Restraint Wing]
        |
[Essence Vault] --- [Storage Sectors A-D]
        |
[Conclave Chamber] --- [Command Center]
        |
[Hidden Intelligence Vault]
```

The sub-level is a linear progression with branching optional areas. The experimentation block and essence vault can be explored in any order, but both must be cleared before the Conclave Chamber becomes accessible. The intelligence vault is only accessible after the boss fight.

---

## Encounter Design

### Encounter 1: Outer Defense -- Entry Point
- **Location**: One of three entry points (player choice)
- **Enemies**: Entry-specific guards (4-6 elite)
- **Difficulty**: Medium-High (varies by entry)
- **Mechanics:**
  - Main Gate: Direct combat, heavy guards, straightforward
  - Sewer: Stealth, environmental hazards (toxic runoff, narrow passages), flanking advantage in courtyard
  - Wall Breach: Evelyn's Wall Crawl required, isolated encounter, access to guard barracks (bonus loot)
- **Environmental Hazards:** Depends on entry point

### Encounter 2: Courtyard Multi-Wave Defense
- **Location**: Stronghold courtyard
- **Enemies**: 3 waves of guards (4-5 per wave) + 2 Church-made creature guards
- **Difficulty**: High
- **Mechanics:**
  - Waves arrive from multiple directions
  - Church-made creatures are powerful but predictable
  - Party coordination is essential
  - Courtyard has defensive positions (pillars, walls) that both sides use
- **Environmental Hazards:** Courtyard structures (cover for both sides)

### Encounter 3: Cathedral Interior Guards
- **Location**: Cathedral main nave and side aisles
- **Enemies**: Church knights (6-8)
- **Difficulty**: Medium-High
- **Mechanics:**
  - Fragile environment -- stained glass windows and altar can be damaged
  - Damaging the environment has narrative consequences (Evelyn comments on the destruction of beautiful things)
  - Guards fight with conviction, using the cathedral's layout defensively
- **Environmental Hazards:** Fragile stained glass (damage reduces chapter-end aesthetic score, affects dialogue)

### Encounter 4: Experimentation Block
- **Location**: Sub-level experimentation chambers
- **Enemies**: Conclave defenders (4), Church-made creatures in containment (2-3)
- **Difficulty**: High
- **Mechanics:**
  - Combat mixed with subject freeing
  - Some creatures are hostile, some are frightened
  - Conclave defenders use tactical positioning
- **Environmental Hazards:** Active experiment apparatus, essence spills

### Encounter 5: Inquisitor Veyss (Mini-Boss)
- **Location**: Sub-level command corridor
- **Enemies**: Inquisitor Veyss (mini-boss) + 2 automated defense systems
- **Difficulty**: High -- tactical, personal
- **Mechanics:**
  - Veyss uses facility systems: locking doors, activating essence barriers, deploying automated turrets
  - Veyss does not engage in direct combat -- they control the battlefield from a protected position
  - Player must disable the facility systems while dealing with automated defenses
  - Veyss retreats when systems are sufficiently degraded
- **Boss Dialogue:** Cold, clinical throughout. "Subject E-V-7. Your anomalous status makes you interesting. Not survivable." "Hunter. You were one of the better ones. A waste."
- **Design Notes:** Veyss is not defeated by force -- they are defeated by the party's ability to adapt and overcome their control of the environment. This reflects Veyss's nature: they are dangerous because of the systems they control, not their personal power.

### Encounter 6: Bishop Aldric (Boss)
- **Location**: Conclave chamber / Command center
- **Enemies:** Bishop Aldric (boss) + 2-3 Conclave elite guards
- **Difficulty:** Very High -- chapter climax
- **Mechanics:**
  - **Phase 1:** Aldric defends with blessed barriers, calls on Conclave guards. He fights with conviction but not malice. "You are lost. I will not let you destroy what is good."
  - **Phase 2:** Evidence is presented. Aldric's barriers falter. He stops calling for reinforcements. He is reading the documents. His combat effectiveness drops, but his emotional intensity rises. "This cannot be -- these are -- who --"
  - **Phase 3:** Aldric stops fighting entirely. The encounter transitions from combat to dialogue. Aldric processes the truth and surrenders.
- **Environmental Hazards:** Command center consoles, Conclave chamber architecture
- **Design Notes:** This is a boss fight with a narrative resolution. The player does not kill Aldric -- they break his faith in the Church. This is thematically consistent with the game's approach to the Church: it is defeated by truth, not just by force.

---

## Environmental Storytelling

### The Cross -- Cathedral
- **Stained Glass Windows:** Depict the Church's founding myth -- knights protecting villages from monsters. Beautiful, sincere, and partially true. The Church did protect villages. It also created the monsters.
- **The Altar:** Large, ornate, clearly well-used. Fresh flowers, burning candles, an open prayer book. This altar served real worshippers. The fact that it sits above a facility of horrors does not make the worship beneath it fake -- it makes the deception more complete.
- **Side Chapels:** Smaller prayer spaces, each dedicated to a different aspect of the Church's mission. "Chapel of the Shield" (protection), "Chapel of the Sword" (purification), "Chapel of the Light" (guidance). Each chapel is genuine -- the people who prayed here believed in what they were doing.

### The Cross -- Sub-Level Facility
- **Reception Block:** Deceptively normal. A desk, a sign-in log, a waiting area. The banality of evil -- people walked through here every day to go to work, and their work was torture.
- **Experimentation Block:** The worst room in the game. Restraint tables, essence apparatus, Control Litany circles. Active subjects in some chambers -- people who are conscious, terrified, and aware of what is being done to them. The party can hear them.
- **Essence Vault:** Beautiful in the way a graveyard is beautiful. Thousands of vials, each glowing, each labeled, each representing a dead magical creature. The scale is the horror -- not one death, but thousands, catalogued and organized.
- **Conclave Chamber:** Rich, comfortable, powerful. Leather chairs, mahogany table, maps on the walls. The Conclave did not see themselves as villains. They saw themselves as leaders making hard decisions. The room reflects that self-image.
- **Intelligence Vault:** Hidden behind the Conclave chamber. Cold, secure, meticulously organized. The Church's intelligence on the Witch is extensive -- they feared her, and their fear produced thorough research. The files are the most valuable thing the party finds in the Stronghold.

---

## Pacing

```
Time (min)    Section                          Intensity
0-5           Approach, final preparations      Medium (focus, determination)
5-8           Evelyn and Evan moment            Low-Medium (grounding, connection)
8-10          Assault begins                    Medium-High (launch)
--- OUTER DEFENSES ---
10-15          Entry point breach                High (combat, entry choice)
15-22          Courtyard multi-wave              Very High (action, coordination)
22-25          Cathedral breach                  High (symbolic weight)
--- CATHEDRAL ---
25-30          Cathedral combat                  High (action, fragile environment)
30-33          Hidden passage discovery          Medium (transition, anticipation)
33-36          Descent to sub-levels             Low-Medium (atmosphere shift)
--- FACILITY ---
36-42          Experimentation block             High (combat, subject freeing)
42-47          Essence vault                     Medium-High (horror, scale)
47-53          Veyss mini-boss                   Very High (tactical, personal)
53-56          Veyss retreat, Conclave access    Medium (progress, tension)
--- BOSS ---
56-62          Aldric confrontation              High (confrontation, conviction)
62-68          Aldric boss fight                 Peak (combat, then evidence)
68-72          Aldric collapse, surrender        Medium-High (devastation, truth)
--- WITCH RECORDS ---
72-77          Intelligence vault discovery      Medium (curiosity -> dread)
77-83          Witch files reading               Peak (revelation, implications)
83-88          Party reaction                    Very High (processing, fear)
88-92          Evelyn's silence                  Low (internal, devastating)
92-96          Chapter close -- tower view       Low-Medium (victory shadowed)
96-100         Final beat: Witch's shadow        Medium (dread, anticipation)
```

Chapter 7 is the longest chapter in the Church arc and the most structurally complex. It moves through multiple phases: approach, outer defense, cathedral, facility, boss, revelation. Each phase has its own tone and pacing. The boss fight transitions from combat to narrative. The Witch records section is pure revelation -- no combat, just the growing realization that the victory is overshadowed. The chapter ends with triumph and dread in equal measure.

---

## Dependencies

- **Party System**: Full party at maximum strength
- **Character Switching**: Full switching between all party members
- **Ally AI System**: Full party AI coordination in all combat encounters
- **Combat System**: All party abilities, multi-wave encounters, boss mechanics
- **Stealth System**: Sewer entry option
- **Environmental Constraints:** Fragile cathedral environment
- **Document Reading System**: Witch intelligence files with narrative delivery
- **Character Models**: Evelyn, Evan, full party roster, Church elite guards, Church-made creatures, Inquisitor Veyss, Bishop Aldric, Conclave guards
- **Environmental Assets**: The Cross (cathedral + sub-level facility), all interior areas
- **Audio**: Party battle dialogue, cathedral combat acoustics, facility ambient sounds, Veyss cold voice, Aldric conviction -> devastation, Witch file reading tension, chapter-end orchestral shift from triumph to dread
- **Witch's Symbol**: Referenced in intelligence files
- **The Vanishing**: Described in Witch intelligence files

---

## Acceptance Criteria

- [ ] Party approaches the Stronghold through untracked terrain
- [ ] Final preparation sequence with party member dialogue
- [ ] Evelyn and Evan share a private grounding moment before the assault
- [ ] Three entry points for outer defense: main gate, sewer, wall breach
- [ ] Entry point choice affects difficulty and rewards but not progression
- [ ] Courtyard multi-wave defense is playable with full party coordination
- [ ] Cathedral breach has symbolic weight (breaking into holy space)
- [ ] Cathedral combat has fragile environment constraints (stained glass)
- [ ] Hidden passage behind altar leads to sub-levels
- [ ] Descent sequence shows atmospheric transition from cathedral to facility
- [ ] Sub-level facility has multiple explorable areas
- [ ] Experimentation block includes subject freeing
- [ ] Essence vault conveys the scale of the Church's harvesting operation
- [ ] Inquisitor Veyss appears as mini-boss using facility systems
- [ ] Veyss retreats rather than dies
- [ ] Bishop Aldric boss fight has 3 phases: combat, evidence, surrender
- [ ] Aldric reads the evidence and processes the truth on-screen
- [ ] Aldric surrenders -- the Church leadership is defeated
- [ ] Hidden intelligence vault is discovered after the boss
- [ ] Witch intelligence files reveal: her identity, power, campaign, the Vanishing
- [ ] The Vanishing's implications for Evelyn are clear (she would die)
- [ ] Party processes the revelation with dialogue and reaction
- [ ] Evelyn is silent about her own fear -- she will not burden the party
- [ ] Chapter ends with the party on the Stronghold tower, victorious but overshadowed
- [ ] The Witch's shadow is felt on the horizon
- [ ] All dialogue lines are under 120 characters
- [ ] Total playtime is between 90-110 minutes
- [ ] The emotional arc completes: determination -> triumph -> dread
- [ ] The Church arc concludes with the Church defeated
- [ ] The Witch is established as the next major threat
- [ ] The player understands that defeating the Witch may mean losing Evelyn
