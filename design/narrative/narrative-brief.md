# Narrative Brief — My Vampire

> **Author**: Narrative Director  
> **Status**: Authoritative — this document governs all narrative documentation  
> **Last Updated**: 2026-04-13  
> **Version**: 1.0

---

## Purpose

This brief defines the complete narrative direction for *My Vampire*. It is the single source of truth for character rosters, lore dependencies, emotional pacing, mystery tracking, narrative triggers, and the documentation plan. All chapter-specific documents in `design/narrative/` must conform to this brief.

---

## 1. Character Roster

### 1.1 Principal Characters

| Name | Role | POV Chapters | Voice Tone | Emotional Arc | Key Relationships |
|------|------|--------------|------------|---------------|-------------------|
| **Evelyn** | Protagonist — Vampire Girl | Prologue (human→cat), Ch 2–11 | Warm, self-deprecating humor masking grief. Soft-spoken but firm when decisive. Never cruel. | Disoriented (cursed) → Hidden (secret guardian) → Confused (encounter with Evan) → Resolute (truth revealed) → Connected (bonds formed) → Determined (Church fall) → Radiant (peak with party) → Accepting (final confrontation) → Vanishing | Evan (partner/love), Cat Beast (curse-giver), Church (captor/tormentor), Witch (mirror of what she could become) |
| **Evan** | Deuteragonist — Church Hunter | Ch 1, Ch 3–11 | Earnest, disciplined, dry humor. Voice of someone who believed in something and had to rebuild. | Devoted (true believer) → Confused (Evelyn's mercy) → Shattered (Church truth) → Allied (joins Evelyn) → Devoted (party bonds) → Resolute (Church fall) → Weighted (Witch campaign) → Peak (full strength) → Bereft (Evelyn vanishes) → Hollow survivor (epilogue) | Evelyn (anchor/purpose), Church (former master/enemy), Witch (sympathetic antagonist), Party (found family) |
| **The Witch** | Antagonist — Grieving Archmage | Witch Prologue, Ch 6–11 (as threat) | Low, measured, carrying the weight of a decade of grief. Never raises her voice — her power speaks for her. | Whole (loves the Mage) → Shattered (Mage executed) → Resolute (vow of erasure) → Escalating (shadow over world) → Exhausted (final confrontation) → Released (mercy death) | The Mage (lost love/dead), Church (enemy who took him), Evelyn (what she became — a magical creature), Evan (reminds her of the Mage's ideals) |
| **The Mage** | The Witch's Lover (deceased) | Witch Prologue only | Gentle, intellectual, warm. Voice of someone who believed magic could help the world. | (Already dead when game begins) — his presence is felt through the Witch's memories and the Church's harvested essence. | The Witch (love/dead), Church (creator and executioner) |
| **Cat Magical Beast** | Curse-Bringer | Prologue (brief), lore mentions | Ancient, alien, amused. Not malicious — operates on a logic that mortals cannot parse. Speaks in riddles that are technically literal. | Indifferent (observed Evelyn's disrespect) → Acts (curse as natural consequence, not punishment) → Absent (does not reappear; the curse is self-sustaining) | Evelyn (cursed one), World (operates on rules beyond mortal morality) |

### 1.2 Party Members (TBD — Names Pending)

> **Note**: The exact names, backstories, and personalities of party members are not yet finalized. Each party member MUST have: a unique voice tone, a clear emotional arc across the chapters they appear in, at least one relationship with Evelyn or Evan, and a reason for joining that ties to the main narrative.

| Role | Placeholder | Voice Tone | Emotional Arc | Reason for Joining |
|------|-------------|------------|---------------|-------------------|
| **Support 1** | TBD | TBD | TBD | Connected to Church corruption arc |
| **Support 2** | TBD | TBD | TBD | Village tie; joins after side quest |
| **Healer 1** | TBD | TBD | TBD | Personal loss to magical creatures |
| **Tanker 1** | TBD | TBD | TBD | Former Church guard, defected |
| **Archer 1** | TBD | TBD | TBD | Hunter's guild; Evan's former colleague |
| **Archer 2** | TBD | TBD | TBD | Joins in Witch arc; personal stake |

**Each party member must also have:**
- At least 3 unique party-bond dialogue sequences with Evelyn
- At least 2 unique party-bond dialogue sequences with Evan
- At least 1 cross-party-member interaction with another companion
- A personal side quest in Chapters 5, 8, or 9 that deepens their arc
- A clear stance on the Witch's philosophy (agree, disagree, understand but reject, etc.)

### 1.3 Supporting Cast

| Name | Role | Chapters | Notes |
|------|------|----------|-------|
| **Village Elder** | Village hub NPC | Ch 2, Ch 5, Ch 8, Ch 10 | Knows Evelyn protects the village but not her identity. Grateful, worried, protective. |
| **Church Bishop** | Mid-game antagonist | Ch 1–7 | Represents the Church's public face. Genuinely believes in the Church's righteousness. Not a cartoon villain — a true believer. |
| **Church Inquisitor** | Mid-game antagonist | Ch 3–7 | The one who captured Evelyn. Cold, methodical, represents the Church's creation program. |
| **Village Blacksmith** | Shop NPC | Village hubs | Warm, practical. Treats Evelyn the same as anyone else — the first person who does. |
| **Church Knight Captain** | Witch Prologue boss | Witch Prologue | Died protecting the outpost. Believed he was doing the right thing. |

### 1.4 Voice Tone Summary

| Character | Vocal Quality | Speech Pattern | Emotional Range |
|-----------|--------------|----------------|-----------------|
| Evelyn | Light, warm, slightly breathy | Pauses when thinking, uses humor to deflect pain | Curiosity → Warmth → Resolve → Acceptance |
| Evan | Grounded, steady, measured | Direct, formal early, softens over time | Conviction → Doubt → Loyalty → Grief |
| The Witch | Low, resonant, controlled | Precise, poetic when emotional, never rushes | Love → Devastation → Resolve → Exhaustion → Release |
| Cat Beast | Layered, echoing, ancient | Speaks in observations, not commands. Indifferent tone. | Detached amusement → Indifference |
| Church Bishop | Rich, warm, persuasive | Oratorical. Sounds like a good man defending a terrible institution. | Sincere conviction → Desperation |
| Church Inquisitor | Cold, clipped, efficient | Clinical. Treats people as resources. | None — emotionally flat throughout |

---

## 2. Lore Dependencies

### 2.1 Lore Prerequisites by Chapter

Each chapter requires the following lore to exist BEFORE writing begins:

| Chapter | Required Lore | Lore Document Needed |
|---------|--------------|---------------------|
| **Prologue** | Cat Magical Beast taxonomy and curse mechanics | `design/narrative/lore/cat-beast-lore.md` |
| **Prologue** | The Mage's backstory and execution | `design/narrative/lore/mage-lore.md` |
| **Prologue** | The Witch's identity and magical abilities | `design/narrative/lore/witch-lore.md` |
| **Prologue** | Church hierarchy and execution practices | `design/narrative/lore/church-lore.md` |
| **Ch 1** | Church public doctrine and propaganda | `design/narrative/lore/church-lore.md` |
| **Ch 1** | Monster ecology (what Evan hunts) | `design/narrative/lore/creature-taxonomy.md` |
| **Ch 2** | Evelyn's escape route from Church | `design/narrative/lore/church-experiments.md` |
| **Ch 2** | Village culture and layout | `design/narrative/lore/village-lore.md` |
| **Ch 2** | How Evelyn's half-cat nature works | `design/narrative/lore/cat-beast-lore.md` |
| **Ch 3** | Church investigation protocols | `design/narrative/lore/church-lore.md` |
| **Ch 3** | Evan's personal history with the Church | `design/narrative/lore/evan-backstory.md` |
| **Ch 4** | Church creation program details | `design/narrative/lore/church-experiments.md` |
| **Ch 4** | Evelyn's transformation process | `design/narrative/lore/church-experiments.md` |
| **Ch 4** | Why half-cat nature blocks Church control | `design/narrative/lore/cat-beast-lore.md` |
| **Ch 5** | Village hub social dynamics | `design/narrative/lore/village-lore.md` |
| **Ch 5** | Party member backstories | `design/narrative/lore/[member]-lore.md` per member |
| **Ch 6** | Witch's campaign scope and methods | `design/narrative/lore/witch-lore.md` |
| **Ch 6** | Church corruption mechanics | `design/narrative/lore/church-experiments.md` |
| **Ch 6** | Witch's shadow presence in the world | `design/narrative/lore/witch-lore.md` |
| **Ch 7** | Church stronghold architecture and defenses | `design/levels/` (level design docs) |
| **Ch 7** | Witch records (what they reveal) | `design/narrative/lore/witch-lore.md` |
| **Ch 8** | Witch's stronghold and forces | `design/narrative/lore/witch-lore.md` |
| **Ch 8** | Post-Church world state | `design/narrative/lore/world-state-post-church.md` |
| **Ch 9** | Deeper party bonds | `design/narrative/lore/[member]-lore.md` per member |
| **Ch 10** | Witch stronghold layout | `design/levels/` (level design docs) |
| **Ch 10** | Final village hub state | `design/narrative/lore/village-lore.md` |
| **Ch 11** | Mechanics of magical creature vanishing | `design/narrative/lore/magic-system.md` |
| **Ch 11** | What "mercy killing" means for the Witch | `design/narrative/lore/witch-lore.md` |
| **Epilogue** | World without magic — what remains | `design/narrative/lore/world-state-post-ending.md` |

### 2.2 Core Lore Documents (Must Be Authored First)

These documents are foundational and must exist before ANY chapter writing:

1. **`lore/cat-beast-lore.md`** — Cat Magical Beast nature, curse mechanics, half-cat state, why it blocks Church control
2. **`lore/church-lore.md`** — Church hierarchy, public doctrine, internal corruption, creation program, key figures
3. **`lore/church-experiments.md`** — How magical creatures are created, Evelyn's transformation, essence harvesting, the Inquisitor's role
4. **`lore/witch-lore.md`** — The Witch's identity, her Mage, her powers, her campaign, her philosophy, her stronghold
5. **`lore/mage-lore.md`** — The Mage's identity, relationship with the Witch, execution, essence harvesting
6. **`lore/creature-taxonomy.md`** — Magical creature types, how they're perceived by humans, Church's role in their proliferation
7. **`lore/magic-system.md`** — How magic works, what magical creatures are, why they vanish, the mechanics of the ending
8. **`lore/village-lore.md`** — Village culture, layout, key NPCs, relationship with Evelyn (secret protector)
9. **`lore/evan-backstory.md`** — Evan's history, why he joined the Church, what he believed, what breaks his faith

### 2.3 Lore Dependency Graph

```
cat-beast-lore ──────────────┬── Prologue
                              ├── Ch 2 (half-cat mechanics)
                              └── Ch 4 (blocks Church control)

church-lore ─────────────────┬── Prologue (execution context)
                              ├── Ch 1 (public face)
                              ├── Ch 3 (investigation protocols)
                              └── Ch 4 (truth reveal)

church-experiments ──────────┬── Ch 2 (Evelyn's escape)
                              ├── Ch 4 (transformation, creation program)
                              └── Ch 6 (corruption scope)

witch-lore ──────────────────┬── Prologue (playable)
                              ├── Ch 6 (shadow appears)
                              ├── Ch 7 (Witch records found)
                              ├── Ch 8 (campaign begins)
                              └── Ch 11 (confrontation, mercy)

mage-lore ───────────────────┬── Prologue (execution, essence)
                              └── Ch 11 (Witch's motivation context)

creature-taxonomy ───────────┬── Ch 1 (Evan hunts these)
                              └── Ch 11 (all vanish)

magic-system ────────────────└── Ch 11 (vanishing mechanics)

village-lore ────────────────┬── Ch 2 (Evelyn protects)
                              ├── Ch 5 (hub)
                              └── Ch 10 (final hub)

evan-backstory ──────────────┴── Ch 1 (believer)
                               └── Ch 3 (doubt seeded)
```

---

## 3. Emotional Pacing Map

### 3.1 Per-Chapter Emotional Arc

| Chapter | Player Feels at START | Player Feels at PEAK | Player Feels at END |
|---------|----------------------|---------------------|---------------------|
| **Prologue** | Curiosity (who is this woman?) | Devastation (watching love destroyed) | Determination + Dread (understanding the Witch's vow) |
| **Ch 1: The Hunter** | Trust (Evan is righteous, Church is good) | Confidence (Evan is competent, world makes sense) | Unease (cracks appear — monsters dying with strange energy) |
| **Ch 2: The Secret Guardian** | Intrigue (who is this mysterious protector?) | Warmth (Evelyn helping villagers, hiding her nature) | Affection (player falls for Evelyn without knowing it) |
| **Ch 3: First Encounter** | Tension (Evan vs. Evelyn — who is right?) | Confusion (Evelyn shows mercy; Evan expected her to kill) | Doubt (Evan questions everything; player questions too) |
| **Ch 4: The Truth** | Anticipation (answers coming) | Shock (Church creates creatures; Evelyn was human) | Alliance (Evelyn saves Evan; they join forces) |
| **Ch 5: Bonds** | Relief (party forming, tone lightens) | Joy (side quests, memories, village life) | Satisfaction (first major raid — party works together) |
| **Ch 6: The Corruption Spreads** | Unease (Church retaliates, Witch shadow looms) | Tension (corruption scope revealed, stakes rise) | Resolve (party at full strength, ready for fight) |
| **Ch 7: The Fall of the Cross** | Determination (assault begins) | Triumph (Church defeated) | Dread (Witch records found — bigger threat coming) |
| **Witch Prologue** | *(Placed before Ch 1 in game order, but chronologically earlier)* | | |
| **Ch 8: The Witch's Shadow** | Heaviness (Witch campaign begins) | Bonding (party deepens, side quests, first encounter = retreat) | Weight (Witch is powerful, not evil, just broken) |
| **Ch 9: What We Fight For** | Connection (party at peak bonds) | Radiance (Evelyn shines, Evan's loyalty deepens) | Strength (ready for final confrontation) |
| **Ch 10: The Last Hunt** | Gravity (final prep, weight builds) | Resolve (track Witch, everything on the line) | Anticipation + Anxiety (final village hub, last moments together) |
| **Ch 11: Vanishing** | Heartbreak (player knows what's coming if they paid attention) | Catharsis (killing Witch = mercy + loss) | Devastation (Evelyn vanishes; Evan alone) |
| **Epilogue: The World After** | Quiet grief (world without magic) | Reflection (memories, what was lost, what remains) | Hollow peace (Evan survives — alone, but the world is safe) |

### 3.2 Emotional Waveform Visualization

```
Intensity
   ^
   |    PRO                    CH4          CH7
   |     *                     *            *
   |    / \                   / \          / \
   |   /   \       CH3       /   \        /   \              CH11
   |  /     \       *       /     \      /     \              *
   | /       \     / \     /       \    /       \            / \
   |/         \   /   \   /         \  /         \    CH9   /   \
   *          \ /     \ /           \/*           \    *    /     \
   |           *       *             *             \  / \  /       \
   |  Witch                              CH5        *   **         EP
   |  Prologue                            *        /   /  \         *
   |    *                                / \      /   /    \       / \
   |   / \                              /   \    /   /      \     /   \
   |  /   \    CH1    CH2              /     \  /   /        \   /     \
   | /     \    *       *             /       \/   /          \ /       \
   |/       \  / \     / \           /        *   /            *         \
   +--------*--*---*---*---*---------*--------*--*------------*----------*--> Time
            1   2   3   4    5       6        7  8            9          10   11

Legend: * = chapter peak
        Bonding chapters (5, 8, 9) create "valleys" of warmth before the next spike.
        CH11 peak = catharsis; CH11 end = devastation.
        EP = quiet, low-intensity reflection.
```

### 3.3 Key Emotional Design Rules

1. **Earn the twist**: Chapters 1–5 MUST make the player love Evelyn. If they don't, Chapter 11 fails. Every side quest, every village interaction, every party dialogue serves this goal.
2. **The Witch is not a villain**: The player must sympathize with her in the prologue, understand her in Chapter 8, and feel grief (not triumph) when she dies in Chapter 11.
3. **No false hope**: After Chapter 7, the player should sense the ending coming. The Witch records, the Witch's shadow, the weight building in Chapters 8–10 — these are all breadcrumbs toward the twist.
4. **The epilogue must hurt**: Quiet, alone, memories. No resurrection, no secret survival. Evan is the only one left. Let the player sit with that.

---

## 4. Narrative Triggers

### 4.1 Trigger Classification

| Type | Description | Implementation |
|------|-------------|----------------|
| **Cutscene** | Cinematic sequence with camera work, voice acting, scripted events | Godot CutscenePlayer node, triggered by area entry or story flag |
| **Dialogue Sequence** | Conversational exchange between characters, may branch | DialogueSystem with branch nodes, triggered by story flag or proximity |
| **Story Beat** | Environmental storytelling, text logs, discovered lore | Triggered by area entry, object interaction, or story progression |
| **Ambient Dialogue** | Party member comments while moving through areas | Triggered by area tags + character presence in party |
| **Internal Monologue** | POV character's thoughts during gameplay | Voice-over or on-screen text, triggered by story flag |

### 4.2 Narrative Trigger Map by Chapter

#### Prologue ("The Curse" — then "The Day the Sun Goes Cold")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `prologue_curse_intro` | Cutscene | Forest clearing | Game start (Evelyn POV) | Evelyn disrespects Cat Beast → curse triggered → cat ears/tail appear |
| `prologue_curse_aftermath` | Internal Monologue | Forest path | Post-curse | Evelyn processes what happened, discovers new cat abilities |
| `prologue_capture` | Cutscene | Church ambush site | Area entry | Church captures Evelyn (sets up vampire experiment) |
| `witch_prologue_start` | Cutscene | Witch's cabin | Game start (Witch POV, 10 years earlier) | Witch discovers Mage taken |
| `witch_prologue_combat_1` | Dialogue Sequence | Path to outpost | First combat encounter | Witch's internal monologue about the Mage |
| `witch_prologue_outpost` | Cutscene | Church outpost | Area entry | Finds Mage's broken staff |
| `witch_prologue_boss` | Cutscene + Combat | Outpost interior | Boss encounter start | Captain confronts Witch; reveals Church essence harvesting |
| `witch_prologue_vow` | Cutscene | Burning outpost | Boss defeated | "I will burn the parchment" — the vow |
| `witch_prologue_end` | Cutscene | Outpost ruins | Vow delivered | Transition to 10 years later — prologue ends |

#### Chapter 1 ("The Hunter")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch1_evan_intro` | Cutscene | Church outpost | Chapter start | Evan receives mission — hunt monsters |
| `ch1_church_doctrine` | Dialogue Sequence | Church hall | First NPC interaction | Establishes Church as righteous (player believes this) |
| `ch1_first_hunt` | Combat + Ambient Dialogue | Monster territory | First combat | Evan hunts monsters competently |
| `ch1_strange_energy` | Story Beat | Monster corpse | After first kill | "This magical energy... it's not natural" |
| `ch1_investigation` | Story Beat | Monster territory | Area exploration | Evidence of Church tampering (seeds of doubt) |
| `ch1_report_back` | Dialogue Sequence | Church | Return to hub | Evan reports; Church deflects questions |

#### Chapter 2 ("The Secret Guardian")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch2_evelyn_intro` | Cutscene | Village outskirts | Chapter start | Evelyn escaped, helping villagers |
| `ch2_day_help` | Ambient Dialogue | Village | Day cycle | Evelyn helps villagers — they don't know what she is |
| `ch2_night_patrol` | Combat + Internal Monologue | Village perimeter | Night cycle | Evelyn secretly fights off monsters |
| `ch2_villager_gratitude` | Dialogue Sequence | Village | After night patrol | Villagers thank "someone" who protected them |
| `ch2_blacksmith_intro` | Dialogue Sequence | Blacksmith shop | First visit | First person who treats Evelyn normally |
| `ch2_elder_knows` | Dialogue Sequence | Elder's house | Specific condition | Elder suspects but doesn't ask — trusts her |

#### Chapter 3 ("First Encounter")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch3_evan_arrives` | Cutscene | Village entrance | Chapter start | Evan arrives to investigate |
| `ch3_evelyn_sighted` | Story Beat | Village | Evan explores | Reports of "a creature" |
| `ch3_first_fight` | Cutscene + Combat | Forest clearing | Triggered encounter | Evan fights Evelyn |
| `ch3_evelyn_mercy` | Cutscene | Post-combat | Evelyn defeats Evan | She shows mercy — "I don't want to kill you" |
| `ch3_evan_confusion` | Internal Monologue | Forest path | Post-mercy | "She could have killed me. Why didn't she?" |
| `ch3_evelyn_reflection` | Internal Monologue | Village outskirts | Post-fight | Evelyn wonders who this hunter is |

#### Chapter 4 ("The Truth")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch4_reveal_start` | Cutscene | Church facility | Infiltration begins | Evelyn and Evan enter together |
| `ch4_evelyn_story` | Dialogue Sequence | Facility interior | Discovery trigger | Evelyn reveals she was human, cursed, captured |
| `ch4_church_truth` | Story Beat | Experiment records | Area exploration | Church CREATES magical creatures |
| `ch4_cat_beast_reveal` | Story Beat | Church records | Discovery trigger | Cat Beast curse → half-cat nature → blocks Church control |
| `ch4_church_hunts_evan` | Cutscene | Facility | Church forces arrive | Church marks Evan as traitor |
| `ch4_evelyn_saves_evan` | Cutscene + Combat | Facility exit | Ambushed | Evelyn saves Evan — alliance formed |
| `ch4_alliance` | Dialogue Sequence | Safe location | Post-combat | "We fight together" |

#### Chapter 5 ("Bonds")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch5_party_joins` | Dialogue Sequence | Village | Various conditions | Party members join one by one |
| `ch5_village_hub` | Ambient Dialogue | Village hub | General | Side quests, shop interactions, party banter |
| `ch5_bond_[member]` | Dialogue Sequence | Various | Per member | Individual bond scenes |
| `ch5_raid_prep` | Dialogue Sequence | Village | Before raid | Party prepares together |
| `ch5_raid_start` | Cutscene | Church facility | Raid begins | First major raid — party works together |
| `ch5_raid_victory` | Cutscene | Facility | Raid complete | Party celebrates — first real win |

#### Chapter 6 ("The Corruption Spreads")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch6_church_retaliation` | Cutscene | Village | Chapter start | Church strikes back — consequences |
| `ch6_corruption_scope` | Story Beat | Various areas | Exploration | Full scope of Church corruption revealed |
| `ch6_witch_shadow` | Cutscene | Distant vista | Mid-chapter | Witch's forces seen for first time |
| `ch6_party_full` | Dialogue Sequence | Village | Party at full strength | Full party assembled |

#### Chapter 7 ("The Fall of the Cross")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch7_assault_begin` | Cutscene | Church stronghold | Chapter start | Final assault on Church |
| `ch7_battles` | Combat + Ambient Dialogue | Stronghold interior | Combat encounters | Party fights through Church defenses |
| `ch7_church_defeated` | Cutscene | Stronghold throne room | Boss defeated | Church falls |
| `ch7_witch_records` | Story Beat + Cutscene | Church archives | Post-defeat | Discover Witch records — bigger threat |
| `ch7_realization` | Dialogue Sequence | Stronghold | Records reviewed | "The Church was just the beginning" |

#### Chapter 8 ("The Witch's Shadow")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch8_witch_campaign` | Cutscene | Village | Chapter start | Witch's campaign begins |
| `ch8_bond_scenes` | Dialogue Sequence | Various | Side quests | Party bonding deepens |
| `ch8_first_witch_encounter` | Cutscene + Combat | Witch territory | Triggered | First encounter with Witch — she retreats, player sees her pain |
| `ch8_witch_retreat` | Dialogue Sequence | Post-encounter | Witch leaves | "I don't want to fight you. But I must." |

#### Chapter 9 ("What We Fight For")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch9_evelyn_shines` | Cutscene | Various | Multiple | Evelyn's best moments — player falls harder |
| `ch9_evan_loyalty` | Dialogue Sequence | Camp/rest | Rest moments | Evan's devotion to Evelyn deepens |
| `ch9_what_we_fight_for` | Dialogue Sequence | Camp/rest | Party gathered | "What are we fighting for?" — each member answers |
| `ch9_peak_strength` | Cutscene | Village | Chapter end | Party at absolute peak — makes the ending hurt more |

#### Chapter 10 ("The Last Hunt")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch10_final_prep` | Dialogue Sequence | Village | Chapter start | Last shopping, last conversations |
| `ch10_farewells` | Ambient Dialogue | Village | Before departure | NPCs give final words — some feel like goodbyes |
| `ch10_track_witch` | Cutscene | Path to stronghold | Departure | Tracking Witch to her stronghold |
| `ch10_weight_builds` | Internal Monologue | Various | Throughout | Evelyn's thoughts — subtle hints about what's coming |
| `ch10_final_village` | Dialogue Sequence | Final hub | Return visit (if applicable) | Last moments of normalcy |

#### Chapter 11 ("Vanishing")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `ch11_confrontation` | Cutscene | Witch stronghold | Chapter start | Final confrontation with Witch |
| `ch11_witch_truth` | Dialogue Sequence | Confrontation | Pre-combat | Witch explains everything — player understands |
| `ch11_witch_fight` | Combat | Stronghold | Boss encounter | Final battle |
| `ch11_witch_death` | Cutscene + Dialogue | Post-combat | Witch defeated | Mercy killing — Witch thanks them, releases |
| `ch11_vanishing_begins` | Cutscene | Stronghold | Witch dies | Magical creatures begin to vanish |
| `ch11_evelyn_fades` | Cutscene | Stronghold | Vanishing accelerates | Evelyn begins to fade — she knows |
| `ch11_goodbye` | Dialogue Sequence | Stronghold | Final moments | Evelyn and Evan's last exchange |
| `ch11_evelyn_gone` | Cutscene | Stronghold | Vanishing complete | Evelyn vanishes. Silence. |

#### Epilogue ("The World After")

| Trigger | Type | Location | Condition | Content |
|---------|------|----------|-----------|---------|
| `epilogue_world` | Cutscene | Various | Chapter start | World without magic — quiet, empty |
| `epilogue_evan_alone` | Ambient Dialogue + Internal Monologue | Village | Exploration | Evan walks through a world that doesn't need him anymore |
| `epilogue_memories` | Story Beat | Various locations | Area entry | Evan remembers — flashbacks, echoes |
| `epilogue_final` | Cutscene | Evelyn's favorite place | Final area | Evan sits where they sat together. The end. |

### 4.3 Ambient Dialogue System

Party members should have ambient dialogue triggered by:
- **Area tags**: Entering a Church facility, a Witch-corrupted zone, the village
- **Character presence**: Only triggers if the specific party member is in the active party
- **Story progression**: Different lines before and after major reveals
- **Combat states**: Before battle, during battle, after victory, after defeat

Each party member should have:
- 5+ area-specific ambient lines
- 3+ story-progression ambient lines
- 4+ combat-state ambient lines

---

## 5. Mystery Tracking

### 5.1 Mystery Register

| ID | Mystery | Introduced In | First Clue | Resolution In | True Answer | Player Misdirection |
|----|---------|--------------|------------|---------------|-------------|---------------------|
| **M1** | Why does Evelyn have cat ears and a tail? | Prologue (visual) | Evelyn's cursed state | Ch 4 | Disrespected Cat Magical Beast, cursed with cat traits | Player assumes she was always a vampire cat-girl |
| **M2** | Who captured Evelyn? | Prologue (end) | Church ambush | Ch 4 | Church captured her for vampire experiments | Player assumes Church hunts all magical creatures |
| **M3** | Is the Church good? | Ch 1 | Church doctrine, Evan's belief | Ch 4 | Church creates magical creatures and experiments on humans | Player is meant to believe the Church early |
| **M4** | What is the strange magical energy in dead monsters? | Ch 1 | Evan notices | Ch 4 | Church tampered with them — creating creatures | Player assumes it's natural magical phenomenon |
| **M5** | Who protects the village at night? | Ch 2 | Monsters dying mysteriously | Ch 3 | Evelyn does, secretly | Player knows from Ch 2 start (Evelyn POV) |
| **M6** | Why did Evelyn show Evan mercy? | Ch 3 | Combat encounter | Ch 4 | She's not a monster — she was human once | Player and Evan both confused |
| **M7** | What is the Church's secret? | Ch 1 (seeded), Ch 3 (deepened) | Strange energy, deflections | Ch 4 | They create magical creatures to control the world | Player assumes it's general corruption |
| **M8** | Who is the Witch? | Prologue (playable), Ch 6 (mentioned) | Prologue | Ch 8 | Grieving woman who lost her Mage to the Church | Player knows her identity but not her full plan |
| **M9** | What does the Witch want? | Prologue (vow), Ch 6 (shadow) | "Burn the parchment" | Ch 11 | Eliminate all magical creatures so no one suffers | Player assumes she wants revenge on the Church |
| **M10** | Why can Evelyn control her vampire nature but the Church can't control her? | Ch 4 | Cat Beast lore | Ch 4 | Half-cat nature creates a hybrid state the Church's control magic can't latch onto | — |
| **M11** | What happens when all magical creatures vanish? | Witch Prologue (implied), Ch 11 (explicit) | Witch's vow | Ch 11 | All magical creatures cease to exist — including Evelyn | Player does NOT know this includes Evelyn until it happens |
| **M12** | What happened to the Mage? | Witch Prologue | Execution mentioned | Witch Prologue | Church executed him for being too powerful, harvested his essence | — |
| **M13** | Will Evelyn survive the game? | Hidden | Subtle hints in Ch 10 | Ch 11 | No — she vanishes with all magical creatures | Player must NOT know this is inevitable until Ch 11 |

### 5.2 Mystery Pacing

```
Mystery
  ^
  | M1 ────────────────────────────── Ch4 ✓
  | M2 ────────────────────────────── Ch4 ✓
  | M3 ── Ch1 ─────────────────────── Ch4 ✓
  | M4 ── Ch1 ─────────────────────── Ch4 ✓
  | M5 ───── Ch2 ───────── Ch3 ✓
  | M6 ──────── Ch3 ─────── Ch4 ✓
  | M7 ── Ch1 ─────────────────────── Ch4 ✓
  | M8 ── Prologue ────────────────── Ch8 ✓
  | M9 ── Prologue ────────────────── Ch11 ✓
  | M10────────────────── Ch4 ✓
  | M11─ Prologue ─────────────────── Ch11 ✓
  | M12─ Prologue ✓
  | M13────────────────────────────── Ch11 (HIDDEN — player doesn't know this is a mystery)
  +─────────────────────────────────────────────────────────────────> Time
     Pro   1   2   3   4   5   6   7   8   9   10  11  EP
```

### 5.3 Misdirection Strategy

The game uses three misdirection techniques:

1. **Church-as-good** (Ch 1): Present the Church as genuinely righteous. Evan believes it. The player should too.
2. **Witch-as-villain** (Ch 6–8): Frame the Witch as the "final boss" in the traditional sense. The player knows her backstory but assumes she's the antagonist to defeat.
3. **Hidden cost** (Ch 11): The player must NOT know that Evelyn's vanishing is the direct consequence of the Witch's plan. They should believe that defeating the Witch stops the vanishing. The tragedy is that it doesn't — defeating the Witch IS the vanishing trigger.

---

## 6. Documentation Plan

### 6.1 Directory Structure

```
design/narrative/
├── narrative-brief.md              # THIS DOCUMENT — master narrative brief
├── lore/                           # Core lore documents
│   ├── cat-beast-lore.md           # Cat Magical Beast, curse mechanics, half-cat state
│   ├── church-lore.md              # Church hierarchy, doctrine, public face, key figures
│   ├── church-experiments.md       # Creation program, Evelyn's transformation, essence harvesting
│   ├── witch-lore.md               # The Witch, the Mage, her powers, campaign, philosophy
│   ├── mage-lore.md                # The Mage's identity, relationship, execution
│   ├── creature-taxonomy.md        # Magical creature types, perception, Church role
│   ├── magic-system.md             # Magic mechanics, vanishing rules, ending mechanics
│   ├── village-lore.md             # Village culture, layout, NPCs, relationship with Evelyn
│   ├── evan-backstory.md           # Evan's history, beliefs, breaking point
│   ├── world-state-post-church.md  # World after Church falls (Ch 8+)
│   └── world-state-post-ending.md  # World without magic (Epilogue)
├── prologue/
│   ├── witch-prologue.md           # EXISTS — Witch prologue narrative design
│   └── evelyn-prologue.md          # Evelyn's curse and capture (Prologue — Evelyn POV)
├── chapter1/
│   └── chapter-design.md           # Ch 1: The Hunter — Evan's POV narrative
├── chapter2/
│   └── chapter-design.md           # Ch 2: The Secret Guardian — Evelyn's POV narrative
├── chapter3/
│   └── chapter-design.md           # Ch 3: First Encounter — dual POV
├── chapter4/
│   └── chapter-design.md           # Ch 4: The Truth — dual POV, major reveals
├── chapter5/
│   └── chapter-design.md           # Ch 5: Bonds — bonding chapter, party joins
├── chapter6/
│   └── chapter-design.md           # Ch 6: The Corruption Spreads
├── chapter7/
│   └── chapter-design.md           # Ch 7: The Fall of the Cross
├── chapter8/
│   └── chapter-design.md           # Ch 8: The Witch's Shadow
├── chapter9/
│   └── chapter-design.md           # Ch 9: What We Fight For
├── chapter10/
│   └── chapter-design.md           # Ch 10: The Last Hunt
├── chapter11/
│   └── chapter-design.md           # Ch 11: Vanishing
├── epilogue/
│   └── epilogue-design.md          # Epilogue: The World After
├── dialogue/
│   ├── evelyn-voice-lines.md       # Evelyn's key dialogue lines and variations
│   ├── evan-voice-lines.md         # Evan's key dialogue lines and variations
│   ├── witch-voice-lines.md        # The Witch's key dialogue lines
│   ├── party-ambient-dialogue.md   # Ambient dialogue for all party members
│   └── bond-sequences.md           # All party bond dialogue sequences
└── mysteries/
    └── mystery-tracker.md          # LIVE tracker for mystery reveals/resolutions
```

### 6.2 File Content Specifications

#### `design/narrative/lore/*.md` — Lore Documents

Each lore document MUST include:
1. **Overview** — One-paragraph summary of the lore topic
2. **Detailed Content** — Comprehensive description of the lore
3. **Key Figures** — Named individuals/entities with descriptions
4. **Timeline** — When did these events happen?
5. **Chapter Connections** — Which chapters reference this lore and how
6. **Open Questions** — What is deliberately left unknown for mystery purposes
7. **Design Notes** — How this lore affects gameplay, level design, or art

#### `design/narrative/prologue/*.md` — Prologue Documents

Each prologue document MUST include:
1. **Overview** — What this prologue section achieves
2. **POV Character** — Whose perspective, voice tone, emotional state
3. **Narrative Beats** — Sequential story beats with descriptions
4. **Gameplay Integration** — What the player does during each beat
5. **Key Dialogue** — Important lines of dialogue
6. **Emotional Target** — What the player should feel
7. **Acceptance Criteria** — Testable conditions for completion

#### `design/narrative/chapterN/chapter-design.md` — Chapter Documents

Each chapter document MUST include:
1. **Overview** — Chapter summary (one paragraph)
2. **POV** — Whose perspective, split points if dual POV
3. **Narrative Arc** — Beginning, middle, end with story beats
4. **Party State** — Who is in the party, who joins, who leaves
5. **Key Encounters** — Combat encounters with narrative context
6. **Dialogue Sequences** — All major conversations with branch points
7. **Cutscene List** — Every cutscene with trigger, duration, content summary
8. **Mystery Progress** — What mysteries are introduced, advanced, or resolved
9. **Emotional Pacing** — Start/peak/end emotions for this chapter
10. **Dependencies** — What lore, levels, or systems this chapter needs
11. **Acceptance Criteria** — Testable conditions for chapter completion

#### `design/narrative/dialogue/*.md` — Dialogue Documents

Each dialogue document MUST include:
1. **Character Voice Guide** — Tone, speech patterns, catchphrases, taboo words
2. **Key Lines** — Important dialogue with context and variations
3. **Branch Points** — Where dialogue can diverge based on player choices
4. **Relationship State** — How this character's dialogue changes based on bond level
5. **Cross-References** — Links to chapter documents where this dialogue appears

#### `design/narrative/mysteries/mystery-tracker.md` — Mystery Tracker

A live document tracking each mystery's status:
1. **Mystery ID** — M1 through M13 (expandable)
2. **Status** — `[INTRODUCED]`, `[CLUE_PLANTED]`, `[RESOLVED]`, `[HIDDEN]`
3. **Introduced In** — Chapter/file
4. **Resolved In** — Chapter/file
5. **True Answer** — The actual truth
6. **Current Clues** — What the player knows so far
7. **Implementation Status** — `[TODO]`, `[IN_PROGRESS]`, `[DONE]`

### 6.3 Authoring Priority Order

Lore documents MUST be authored in this order (dependencies flow downward):

| Priority | Document | Required Before |
|----------|----------|-----------------|
| **P0** | `lore/cat-beast-lore.md` | Prologue, Ch 2, Ch 4 |
| **P0** | `lore/church-lore.md` | Prologue, Ch 1, Ch 3, Ch 4 |
| **P0** | `lore/church-experiments.md` | Ch 2, Ch 4, Ch 6 |
| **P0** | `lore/witch-lore.md` | Prologue, Ch 6, Ch 7, Ch 8, Ch 11 |
| **P0** | `lore/mage-lore.md` | Prologue, Ch 11 |
| **P1** | `lore/creature-taxonomy.md` | Ch 1, Ch 11 |
| **P1** | `lore/magic-system.md` | Ch 11 |
| **P1** | `lore/village-lore.md` | Ch 2, Ch 5, Ch 10 |
| **P1** | `lore/evan-backstory.md` | Ch 1, Ch 3 |
| **P2** | `lore/world-state-post-church.md` | Ch 8+ |
| **P2** | `lore/world-state-post-ending.md` | Epilogue |

Chapter documents should be authored in narrative order after all P0 lore exists:
1. `prologue/evelyn-prologue.md`
2. `chapter1/chapter-design.md`
3. `chapter2/chapter-design.md`
4. `chapter3/chapter-design.md`
5. `chapter4/chapter-design.md`
6. `chapter5/chapter-design.md`
7. `chapter6/chapter-design.md`
8. `chapter7/chapter-design.md`
9. `chapter8/chapter-design.md`
10. `chapter9/chapter-design.md`
11. `chapter10/chapter-design.md`
12. `chapter11/chapter-design.md`
13. `epilogue/epilogue-design.md`

Dialogue and mystery documents can be authored in parallel with chapters.

---

## 7. Cross-Team Handoffs

### 7.1 To the Writer Team
- This brief defines the full character roster, emotional arcs, and mystery tracking
- All dialogue must conform to the voice tone specifications in Section 1
- All chapter documents must reference the mystery tracker (Section 5)
- Party member backstories are TBD — writers should propose names and arcs

### 7.2 To the World-Builder Team
- Lore dependencies in Section 2 define what must exist before each chapter
- The lore documents in `design/narrative/lore/` are the world-builder's primary deliverable
- Village culture, Church architecture, and Witch stronghold need physical world models

### 7.3 To the Level-Designer Team
- Narrative trigger map (Section 4.2) defines where cutscenes and dialogue fire
- Each trigger references a location — level designers must place these areas
- Chapter documents will specify encounter layouts that serve narrative beats
- Level design docs in `design/levels/` must cross-reference narrative triggers

### 7.4 To Systems/Programming
- Trigger IDs in Section 4.2 are the contract between narrative and code
- The DialogueSystem must support branch nodes, story flags, and character presence checks
- The CutscenePlayer must support area-entry and story-flag triggers
- Ambient dialogue system needs area tags, character presence, story progression, and combat state inputs
- Mystery tracker is a live document — implementation status must be updated as triggers are coded

---

## 8. Open Questions

| ID | Question | Owner | Resolution Needed By |
|----|----------|-------|---------------------|
| **OQ1** | What are the party members' names, backstories, and voices? | Writer | Before Ch 5 writing |
| **OQ2** | How do multiple endings branch? What choices create different outcomes? | Narrative Director + Systems | Before Ch 11 writing |
| **OQ3** | Does the player ever learn that Evelyn's vanishing was inevitable? (Post-credits reveal?) | Narrative Director | Before Epilogue writing |
| **OQ4** | How many side quests per chapter? What is the minimum for "earning" the ending? | Writer + Level Designer | Before Ch 5 writing |
| **OQ5** | What is the Witch's physical appearance and visual design? | Art Director + Writer | Before Witch Prologue finalization |
| **OQ6** | Does the Cat Magical Beast ever reappear, or is it a one-time lore entity? | World-Builder | Before Ch 6 writing |
| **OQ7** | What does Evan do in the epilogue world? Does he have purpose, or pure emptiness? | Narrative Director | Before Epilogue writing |
| **OQ8** | Are there any post-vanishing hints that Evelyn might exist somewhere? (Ambiguous hope, or absolute finality?) | Narrative Director | Before Epilogue writing |

---

## 9. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-13 | Narrative Director | Initial narrative brief — all sections authored |

---

## 10. Approval Status

| Role | Status | Notes |
|------|--------|-------|
| Narrative Director | **APPROVED** | — |
| Creative Director | Pending | — |
| Writer Lead | Pending | — |
| World-Builder Lead | Pending | — |
| Level-Designer Lead | Pending | — |
| Technical Director | Pending | — |
