# Game Concept: My Vampire

*Created: 2026-04-03*
*Status: Draft*

---

## Elevator Pitch

> A vampire girl cursed by the Church joins forces with the hunter sent to kill her,
> battling through a world of magic, grief, and betrayal toward a final confrontation
> that will cost more than either of them expected. A warm, narrative Action RPG where
> your party is your heart — and completing the journey means letting one of them go.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Action RPG / Hack & Slash |
| **Platform** | PC |
| **Target Audience** | Story-driven RPG fans, 18–35 |
| **Player Count** | Single-player |
| **Session Length** | 45–90 minutes |
| **Monetization** | Premium (no F2P) |
| **Estimated Scope** | Medium (3 months) |
| **Comparable Titles** | Final Fantasy VII Remake, Tales of Berseria, Nier: Automata |

---

## Core Fantasy

> You are a cursed vampire — feared by the world that made you — fighting alongside
> a team of companions who chose to stand with you anyway. You grow with them, equip
> them, switch into their bodies in combat, and slowly fall in love with the party you
> built. Then the ending arrives, and you realize: you worked toward this all along.
> Completing the quest was always going to cost Evelyn. The player never knew. Neither
> did she.

This game delivers the fantasy of **chosen family fighting a corrupt world** — and
then earns the cost of that fight emotionally, through the very investment the player
built over the entire game.

---

## Unique Hook

> "It's like Final Fantasy VII Remake's party combat AND ALSO your party AI is
> trained by reinforcement learning so companions genuinely improve with expertise —
> AND ALSO the protagonist's death is triggered by completing the game, a twist the
> player never sees coming until the credits roll."

The hook is the **structural tragedy**: the player's goal and Evelyn's doom are the
same event. Every item looted for her, every level gained, every bond formed makes
the ending hit harder.

---

## Character Overview

### Evelyn — The Vampire Protagonist
Once a human girl, cursed by God and subjected to Church experimentation that turned
her into a vampire. She carries her curse with grace, fighting not for revenge but
for a world where what happened to her doesn't happen again. **She will not survive
the ending.** When all magical creatures vanish, so does she.

### Evan — The Hunter
A magical hunter employed by the Church who learns the truth: the Church *creates*
magical creatures to control the world. He retaliates, joining Evelyn's cause. He
survives the ending — the only one who does.

### The Witch — The Final Boss (Playable in Prologue)
The Witch loved a Mage — a Church-produced magical being of singular power. Because
the Mage was too powerful, the Church executed them. The Witch barely survived,
broken. Now she wants to eliminate all magical creatures so no one suffers what she
suffered. Her method: raids villages, dark magic, accumulation of power by any means.
Her goal and the game's ending are the same event — she was right, she was just
destruction rather than grace.

*The player plays the Witch in the prologue. By the time Evelyn and Evan must kill
her, the player understands her completely. The killing feels like mercy and loss
simultaneously.*

### Party Members
Multiple characters per role, each with a unique skill set:

| Role | Purpose | Notes |
| ---- | ---- | ---- |
| **Support** | Buffs, crowd control | Each support character has a different buff philosophy |
| **Healer** | Sustain, revival | Skill variance determines heal style (burst vs. regen) |
| **Tanker** | Aggro, damage absorption | Different stances and counter mechanics |
| **Archer** | Ranged DPS, positioning | Example: Archer A (skills A, B, C) vs. Archer B (skills B, D, F) |

Characters within the same role are not interchangeable — skill set composition
makes party building genuinely strategic.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Narrative** (drama, story arc) | 1 | Chapter structure, Witch prologue, Evelyn's hidden arc |
| **Fantasy** (make-believe, role-playing) | 2 | Vampire identity, cursed world, party roleplay |
| **Expression** (self-expression, creativity) | 3 | Party builds, cosmetics, skill set variety |
| **Sensation** (sensory pleasure) | 4 | Smooth combat feel, character switch impact, audio feedback |
| **Discovery** (exploration, secrets) | 5 | World lore, Witch backstory reveals, hidden party interactions |
| **Challenge** (obstacle course, mastery) | 6 | Accessible — present but never the point |
| **Fellowship** | N/A | Single-player; party bonds are narrative, not social |
| **Submission** | N/A | Not a relaxation game |

### Key Dynamics (Emergent player behaviors)

- Players will experiment with party compositions to find skill synergies
- Players will equip party members they feel emotionally attached to first
- Players will re-read the prologue after finishing the game, seeing the Witch
  differently
- Players will feel reluctant to "finish" once they sense the end approaching

### Core Mechanics

1. **Accessible hack & slash combat** — smooth, readable, satisfying hits. No punishing skill ceiling.
2. **Character switching** — player can control any party member in real-time; the strategic depth lives here, not in individual combo mastery.
3. **RL-trained party AI with expertise scalar** — non-active party members are governed by reinforcement-learning agents trained to optimal play, then tuned via an expertise parameter (0.0–1.0) that controls decision quality and timing accuracy.
4. **Loot & per-character skill builds** — items drop for specific characters; skill sets are character-unique, making every party member's equipment meaningful.
5. **Chapter-based narrative with village/shop hubs** — story advances in chapters with RPG hub areas (shops, cosmetics, NPC interactions) between encounters.

---

## Player Motivation Profile

### Primary Psychological Needs

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Party composition, which character to switch to, loot decisions | Supporting |
| **Competence** | Smart switching makes encounters feel won by skill; party AI grows with expertise | Supporting |
| **Relatedness** | Deep investment in Evelyn, Evan, and party members through story and combat | **Core** |

### Player Type Appeal

- [x] **Storytellers** — narrative-first players who want to feel something. This is their game.
- [x] **Achievers** — loot, progression, party builds give them goals across every session.
- [x] **Explorers** — world lore, Witch backstory, hidden party dialogue reward curiosity.
- [ ] **Competitors** — no PvP, no leaderboards. This is not their game.

### Flow State Design

- **Onboarding**: Witch prologue teaches tone and combat in a contained, emotionally gripping sequence before the main game begins.
- **Difficulty scaling**: Expertise scalar on party AI creates a natural ramp — early chapters feel like learning together, later chapters feel like a veteran team.
- **Feedback clarity**: Character swap animations, loot chimes, skill impact audio all telegraph player effectiveness.
- **Recovery from failure**: Fast respawn, no lengthy death penalties. Failure is educational, not punishing. Story always continues.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Attack enemies with the current character, use a skill when the moment is right,
evaluate whether to switch to a different party member based on the encounter.
Combat is smooth and readable — the interesting decision is always *who should I
be right now*, not *can I execute this combo correctly*.

### Short-Term (5–15 minutes)
Clear an encounter or dungeon segment. Loot drops. Evaluate items for party members —
equip the right gear to the right character, consider how it affects their skill
access. Move to the next area.

### Session-Level (30–90 minutes)
Progress through a chapter. Hit a major story beat or cutscene. Reach a village or
hub — shop, cosmetic changes, NPC dialogue, party interactions. Sessions end on a
narrative beat that answers one question and opens another.

### Long-Term Progression
- Chapter completion advances Evelyn and Evan's story
- Party members level and unlock deeper skill access
- Loot builds specialize each character's role
- Evelyn's arc slowly, invisibly counts down (player doesn't know)
- Multiple endings reflect how the player engaged with the world

### Retention Hooks

- **Curiosity**: "What happens to the Witch?" "Why did the Church create Evelyn?" "What does Evan do after?"
- **Investment**: Party equipment, bonds formed, progress made — all feel worth protecting
- **Mastery**: Refining party compositions and switch timing as chapters grow harder
- **Narrative pull**: The next story beat is always the reason to keep playing

---

## Story Structure

| Chapter | POV | Narrative Purpose |
| ---- | ---- | ---- |
| **Prologue** | The Witch | Player bonds with the Witch; witnesses her loss; understands her grief |
| **Chapter 1** | Evelyn & Evan | Establish the duo; first encounter with Church forces; party begins forming |
| **Chapter 2** | Evelyn & Evan | World expands; party grows; Church's true nature revealed |
| **Chapter 3** | Evelyn & Evan | Stakes escalate; Witch's shadow looms; bonds deepen |
| **Chapter 4 (Final)** | Evelyn & Evan | Confrontation with the Witch; Evelyn's fate sealed; Evan survives alone |

*The Witch's goal (remove all magical creatures) and the game's ending (all magical
creatures including Evelyn vanish) are the same event. The player kills the Witch to
stop her — and then it happens anyway.*

---

## Game Pillars

### Pillar 1: Story First
Every system exists to serve the narrative. If a mechanic doesn't deepen player
attachment to the characters or world, it doesn't ship.

*Design test*: "Should we add a survival hunger mechanic?" — Story First says no:
it adds friction without deepening character bonds or advancing the narrative.

### Pillar 2: The Party Is the Game
Switching characters, building unique skill sets, and equipping each party member
IS the core expression of player skill. Depth lives in party management, not
individual combat mastery.

*Design test*: "Should we add complex individual combo chains?" — The Party Is the
Game says no: depth goes into switching strategy and party composition, not solo
execution.

### Pillar 3: Earn the Ending
The player must feel genuinely invested in Evelyn before the twist lands. Every
design decision about pacing, party bonding, and narrative beat serves this goal.
A player who doesn't love Evelyn won't feel the ending. We must earn that love.

*Design test*: "Should we add optional side dungeons?" — Earn the Ending says only
if they deepen party bonds or reveal character backstory. Pure combat padding is cut.

### Anti-Pillars

- **NOT a skill-ceiling game**: No punishing difficulty that walls players away from the story. Accessibility over challenge. A player who struggles at combat still deserves the ending.
- **NOT a content treadmill**: No grinding for its own sake. Every loot drop and encounter serves party investment or narrative momentum, not padding.
- **NOT a spectacle-first game**: We are not competing with AAA production value. Warmth and narrative coherence matter more than visual bombast. One great cutscene beats ten mediocre ones.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **Final Fantasy VII Remake** | Party combat feel, emotional character investment | RL-trained AI instead of scripted; structural twist ending | Proves the market for narrative ARPG with deep party bonds |
| **Nier: Automata** | Multi-POV structure, villain with tragic backstory, twist ending | Witch POV is prologue not a full route; single-playthrough reveal | Shows structural tragedy can be a commercial and critical hit |
| **Harvest Moon / Story of Seasons** | Endless investment loop, multiple endings, relationship depth | Combat-forward, not life-sim; finite chapters not endless seasons | Confirms the "earn your ending" emotional payoff model works |
| **Tales of Berseria** | Warm party dynamics, villain-sympathetic narrative | Twist is earned structurally, not through dialogue reveals alone | Party banter and bond development as gameplay reward |

**Non-game inspirations**: Tragic romance anime (Clannad, Angel Beats) — the model
of "fall in love with a character the story was always going to take from you."
Church-as-institution horror (Bloodborne) — corruption hiding behind sanctity.

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18–35 |
| **Gaming experience** | Mid-core — familiar with RPGs, not necessarily hardcore action players |
| **Time availability** | 45–90 minute sessions, 3–5 times per week |
| **Platform preference** | PC |
| **Current games they play** | Final Fantasy, Tales of series, Nier, Genshin Impact |
| **What they're looking for** | An RPG that makes them feel something; a story they'll think about after finishing |
| **What would turn them away** | Punishing difficulty, excessive grinding, poor storytelling, janky AI companions |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Engine** | Unity — chosen for ML-Agents RL framework, strong asset store, team familiarity |
| **Key Technical Challenges** | RL training environment for party AI; character switching state management; per-chapter narrative branching |
| **Art Style** | 3D stylized — warm palette, readable character silhouettes |
| **Art Pipeline Complexity** | Medium — multiple playable characters with cosmetic variants |
| **Audio Needs** | Music-heavy — narrative moments require scored audio; combat needs satisfying hit feedback |
| **Networking** | None — single-player only |
| **Content Volume** | Prologue + 4 chapters; 10–15 party-equippable characters; 20–30 hours full playthrough |
| **Procedural Systems** | None — all content hand-authored to serve narrative pacing |

### Party AI — Reinforcement Learning Architecture

Party AI uses Unity ML-Agents. Each encounter type has a trained RL agent that
learns to defeat the encounter optimally. An **expertise scalar (0.0–1.0)** controls
how much noise and delay is applied to the agent's decisions:

- `0.0–0.3`: Poor — mistimed skills, suboptimal targeting, occasional idle gaps
- `0.4–0.6`: Competent — reliable but not optimal; readable as "still learning"
- `0.7–0.9`: Veteran — near-optimal play; player can trust this companion
- `1.0`: Expert — fully optimal; reserved for story-moment showcases

This allows NPC "experience" to be a tunable design value rather than a binary state.
**Prototype target: Month 1.** If the training environment proves too complex,
fall back to behavior trees with animated expertise simulation.

---

## Risks and Open Questions

### Design Risks
- **Player bonding speed**: If the player doesn't love Evelyn before the ending,
  the twist lands flat. Pacing and party interaction density are critical.
- **Witch empathy calibration**: The prologue must make the Witch sympathetic
  without making Evelyn's party feel like villains for fighting her.
- **Multiple endings coherence**: Endings must feel earned by player choices, not
  arbitrary. Requires clear design of what choices matter and how.

### Technical Risks
- **RL training complexity**: Training agents for dynamic real-time ARPG combat is
  non-trivial. Requires early prototyping (Month 1). Fallback: behavior trees.
- **Character switching state management**: Switching mid-combat requires careful
  state synchronization (cooldowns, buffs, AI handoff). Underestimated scope risk.
- **Per-character skill set balance**: Multiple characters per role with unique
  skill sets require extensive balancing. Risk of some characters becoming obsolete.

### Market Risks
- **Genre competition**: Genshin Impact, FF7 Remake, and Tales of dominate the
  narrative ARPG space with AAA budgets. Differentiation through story structure
  (the twist) and RL AI must be clearly communicated.
- **Story quality dependency**: The game lives and dies on whether players feel the
  ending. Writing quality is a commercial risk, not just a creative one.

### Scope Risks
- **Content volume for 3 months**: Prologue + 4 chapters with full party, loot,
  cosmetics, and multiple endings is aggressive. Month 1 prototype will determine
  actual velocity.
- **RL training iteration time**: Training loops add non-code work time that is
  easy to underestimate in planning.

### Open Questions
- **How do multiple endings branch?** What choices create different outcomes? Needs
  design pass before Chapter 1 writing begins. → Resolve with `/design-system` for
  the Narrative system.
- **Is the RL approach feasible in Unity ML-Agents within 3 months?** → Resolve
  with `/prototype party-ai` in Month 1.
- **What is Evelyn's cosmetic scope?** How many outfits, and do they carry emotional
  weight (e.g., an outfit you can't bring yourself to remove after the ending)? →
  Resolve with `/design-system` for the Cosmetics system.

---

## MVP Definition

**Core hypothesis**: Players feel emotionally invested in Evelyn and the party after
2 chapters of play, making the twist ending hit as intended.

**Required for MVP**:
1. Witch prologue (teaches tone, establishes tragedy model)
2. Chapters 1–2 with Evelyn, Evan, and 1 additional party member
3. Character switching in combat (the core mechanical expression)
4. Basic loot system with per-character equipment
5. The twist ending (all magical creatures vanish, Evelyn dies, Evan survives)

**Explicitly NOT in MVP**:
- Multiple endings (main ending only)
- Full party roster (3 characters sufficient to test)
- Shop / village systems (hub placeholder acceptable)
- Cosmetics (default visuals only)
- RL party AI (behavior tree fallback acceptable for MVP validation)

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | Witch prologue + Ch 1–2, 3 characters | Combat, switching, basic loot, twist ending | Month 1 |
| **Alpha** | + Ch 3, 4–5 characters, basic shop | + RL party AI prototype, cosmetics v1 | Month 2 |
| **Full Vision** | Prologue + Ch 1–4, full party, villages | + Multiple endings, skill variants, full cosmetics | Month 3 |

---

## Visual Style

**Direction**: 3D with a soft, cartoon aesthetic.

| Aspect | Description |
|--------|-------------|
| **Rendering** | 3D — Godot Forward+ renderer |
| **Art style** | Soft cartoon — rounded forms, cel-shaded or toon-shaded lighting, clean outlines |
| **Color palette** | Warm shadows, desaturated midtones, vibrant accent colors per character (Evelyn = deep purple/crimson, Evan = steel blue/gold, Witch = forest green/ivory) |
| **Character proportions** | Slightly stylized (large expressive eyes, clean silhouettes) — readable at gameplay distance |
| **Environment** | Hand-painted texture feel, soft ambient occlusion, no photorealistic PBR |
| **VFX** | Bold, readable skill effects — large impact flashes, clear hitboxes implied by visual arcs |
| **UI** | Flat design with soft rounded panels; matches cartoon aesthetic; no hyper-realistic elements |
| **References** | Tales of Arise (stylized 3D combat readability), Guilty Gear Strive (crisp cartoon outlines), Genshin Impact (soft toon shading on 3D characters) |

### Godot Implementation Notes
- Use **toon shading** via a custom `StandardMaterial3D` with `Shading Mode: Unshaded` + rim lighting, or a simple Godot shader
- **Outlines**: Inverted hull method or Godot's built-in outline on `MeshInstance3D`
- **Post-processing**: Subtle bloom on skill VFX; no heavy film grain or chromatic aberration
- Placeholder geometry (capsules) should use **solid flat colors** — blue for players, red for enemies — to keep readability during prototyping

---

## Next Steps

- [ ] Run `/setup-engine unity` to configure Unity and populate version-aware reference docs
- [ ] Run `/design-review design/gdd/game-concept.md` to validate completeness
- [ ] Run `/map-systems` to decompose concept into individual systems with dependencies and priorities
- [ ] Create Architecture Decision Record for RL vs. behavior tree party AI (`/architecture-decision`)
- [ ] Run `/prototype party-ai` in Month 1 to validate RL feasibility
- [ ] Author per-system GDDs with `/design-system` (Combat, Party AI, Loot, Narrative, Cosmetics)
- [ ] Validate core loop with `/playtest-report` after MVP build
- [ ] Plan first sprint with `/sprint-plan new`
