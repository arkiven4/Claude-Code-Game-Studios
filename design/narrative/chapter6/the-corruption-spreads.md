# Chapter 6: "The Corruption Spreads" — Narrative Design Document

> **Chapter Number**: 6
> **POV Characters**: Evelyn and Evan (alternating)
> **Duration**: 60-75 minutes
> **Emotional Arc**: Unease -> Tension -> Resolve
> **Status**: Authoritative — awaiting narrative director review
> **Last Updated**: 2026-04-14
> **Cross-Reference**: [level-design.md](../../../levels/chapter6-the-corruption-spreads/level-design.md)

---

## 1. Overview

Chapter 6 is the turning point of the game. The warmth of Chapter 5 is shattered by a dawn alarm. The party's victory over the Church Tier 2 facility has consequences — severe, immediate, and far-reaching. The Church retaliates with overwhelming force, deploying resources it had been holding in reserve. The village of Oakhaven, now the party's home, comes under direct attack.

This chapter introduces the Witch's shadow for the first time — not as a direct encounter, but as environmental storytelling, magical residue, and a distant figure watching from a hillside. Her presence is subtle, unsettling, and deeply mysterious. The party does not yet know who she is, but they know two things: someone else is fighting the Church, and that someone is terrifyingly powerful.

The chapter alternates between Evelyn and Evan POV. Evelyn's sections carry her warmth increasingly shadowed by concern — she is protective, storing moments, sensing things through her vampiric intuition. Evan's sections show him shifting from formal tactical command to something more personal — he defers to Evelyn on moral questions while taking charge of logistics and strategy.

By chapter's end, the full scope of the conflict is revealed: the Church is mobilizing region-wide, the Witch's campaign is beginning, and the party is caught between two overwhelming forces. They choose to fight anyway. The chapter closes with resolve — not triumph, not despair, but the quiet determination of people who know the cost and pay it anyway.

**Key Triggers**: `ch6_alarm_dawn`, `ch6_village_defense`, `ch6_enhanced_creature`, `ch6_aftermath`, `ch6_tactical_documents`, `ch6_investigation`, `ch6_ley_line_node`, `ch6_witch_shadow_first`, `ch6_regroup`, `ch6_chapter_close`

---

## 2. Player Fantasy

### As Evelyn — The Protector Under Pressure
The player experiences Evelyn's shift from the relaxed joy of Chapter 5 to a more guarded, protective stance. The dawn alarm breaks the warmth she worked so hard to build. Her tail stops curling. Her ears flatten at threats. She fights not just for the village but for the life she has built there. Her vampiric senses pick up something unfamiliar — the Witch's residual energy — and she cannot name what she feels. The player should feel her unease, her determination to hold what she has built, and the growing weight of responsibility she carries.

### As Evan — The Tactical Leader Learning to Trust
The player experiences Evan stepping into his role as the party's operational center. He reads tactical documents, assesses Church capabilities, and plans their response. But beneath the tactical competence, he is also learning to trust Evelyn's moral authority — her intuition, her empathy, her sense of the Witch's energy as "grief." The player should feel his competence, his growing comfort in the group, and the quiet respect he shows Evelyn's instincts.

### As the Party — The Family Tested
The bonds forged in Chapter 5 are now tested. Silas treats wounded villagers with the same steady care he showed in his introduction. Kaelen holds the wall because that is what he does. The support members fight alongside the main cast. The player should feel the weight of everything they built being threatened — and the resolve that makes them fight harder.

### As an Investigator — Discovering the Witch's Shadow
The discovery of the Witch's presence is the chapter's mystery arc. A destroyed Church outpost with precise, overwhelming destruction. A symbol burned into stone. A distant figure watching from a hillside, then gone. Magical energy readings that defy classification. Evelyn sensing "grief" in the residue. The player should feel awe, unease, and curiosity — a different kind of tension from the Church's brute-force retaliation.

### As a Commander — Facing the Full Scope
The revelation of the Church's full operational scale — 47 facilities, 312 active subjects, essence harvesting across the entire region — is devastating. The player should feel the weight of the task ahead, then the resolve that comes from knowing retreat is not an option. The chapter ends not with despair at the scope but with determination to meet it.

---

## 3. Narrative Arc

### 3.1 Dawn Alarm (Minutes 0-5) — Evelyn POV

The chapter opens in darkness. Dawn has not yet broken. The village is quiet — the kind of quiet that follows Chapter 5's celebration, winding down, content. Then the alarm bells ring.

Evelyn wakes instantly — vampire senses, always half-alert. She is at the village gate before most others. Church knights. A strike team. Not an investigation — an assault.

**Trigger:** `ch6_alarm_dawn`

Evelyn's first thought is not fear. It is protectiveness. The village she built, the people she saved, the life she constructed from nothing — all of it is threatened. Her tail is still. Her ears are forward. Her voice is calm but firm.

### 3.2 Village Defense (Minutes 5-15) — Alternating POV

The village defense is urgent, chaotic, and personal. This is not a planned encounter — it is an emergency. The party fights to protect everything they love.

Evelyn controls the aggressive pushes. Evan coordinates tactical positioning. Silas keeps everyone alive. Kaelen holds the wall. The support members fight at their stations.

**Trigger:** `ch6_village_defense`

The Church deploys an enhanced Church-made creature — more powerful than anything before, with partial seal stability. Kaelen recognizes it immediately: "They have been holding these back."

### 3.3 Enhanced Creature and Aftermath (Minutes 15-22) — Evan POV

The enhanced creature falls. The strike team is repelled. But the cost is visible: the gate is damaged, the perimeter wall has fresh scorch marks, the blacksmith's forge bears a scar.

Evan surveys the damage with a soldier's eye. This was not a probing attack. This was a response — the Church's answer to Chapter 5's raid. And it will not be the last.

**Trigger:** `ch6_enhanced_creature` -> `ch6_aftermath`

Evan's internal monologue reveals his tactical assessment: the Church is mobilizing. This was one strike team. There will be more.

### 3.4 Tactical Documents (Minutes 22-28) — Evelyn POV

The party recovers documents from defeated Church knights. Evelyn reads them with growing unease. Mobilization orders. Every Church facility going to full alert. The party's raid on the Tier 2 facility has woken the entire hive.

**Trigger:** `ch6_tactical_documents`

Evelyn processes the guilt: they won, but the village paid for it. The Elder reassures her — the village chose this. They chose to stand with her. She stores the moment, as she stores all the good ones.

### 3.5 Investigation Phase (Minutes 28-38) — Alternating POV

The party investigates the broader scope of the Church's corruption. They visit a destroyed village — wiped out by a Church-made creature with seal failure. No survivors. The healer's reaction is devastating.

**Trigger:** `ch6_investigation`

Evan reads supply manifests with a flat voice — the flatness of someone reading numbers that represent horrors. Forty-seven facilities. Three hundred twelve active subjects. Industrial-scale corruption.

Evelyn's internal monologue: "Three hundred twelve. I was Subject E-V-7. How many were before me? How many did not escape?"

### 3.6 Ley Line Node (Minutes 38-45) — Evelyn POV

The party discovers a corrupted ley line node — the Church's experimentation has destabilized the world's magical ecosystem. Creatures spontaneously generate and dissipate, confused, disoriented, lashing out.

**Trigger:** `ch6_ley_line_node`

Evelyn fights while managing the node. Her blood magic interacts with the corrupted energy. She senses the wrongness in it — not just damage, but a wound in the world itself. The Church is not just hurting people. They are hurting everything.

### 3.7 The Witch's Shadow — First Appearance (Minutes 45-55) — Alternating POV

The party discovers a Church outpost that has been destroyed — but not by them, and not by any creature they recognize. The destruction is precise, overwhelming, and accompanied by a magical signature that matches nothing in the Church's catalogue.

**Trigger:** `ch6_witch_shadow_first`

A symbol is burned into the central stone. A distant figure watches from a hillside — tall, still, forest green and ivory. By the time the party reaches the hillside, there is no trace.

Evan's detector reads "intensity off the scale, frequency unknown." Evelyn's vampiric senses read something else: "It feels like grief. I know that sounds mad. But it does."

### 3.8 Party Regroup (Minutes 55-62) — Alternating POV

The party discusses what they have found. The mood is heavy but not broken. The Church is mobilizing. The Witch's shadow is a wild card. They are caught between two overwhelming forces.

**Trigger:** `ch6_regroup`

Evan presents the strategic assessment: the Church is powerful but reactive. Strike the Stronghold, and the rest collapses. Evelyn shares her intuition about the Witch's grief. The party takes her seriously — they have learned to trust her instincts.

### 3.9 Chapter Close — Resolve (Minutes 62-75) — Evelyn POV

The party commits to the Stronghold assault. No one hesitates. Each member has their reason, but the decision is unanimous. The chapter ends with resolve — the party caught between Church and Witch, choosing to fight.

**Trigger:** `ch6_chapter_close`

Evelyn's final internal monologue: she stores this moment too. Not because it is warm — it is not — but because it is true. They chose each other. They chose the fight. And she will not let them face it alone.

---

## 4. Cutscene Scripts

### SCENE 1: ch6_alarm_dawn — The Alarm Breaks the Warmth

**TRIGGER**: `ch6_alarm_dawn`
**LOCATION**: Oakhaven village — pre-dawn darkness, alarm bells, chaos
**CAMERA**: Black screen. Bell rings once. Bell rings again. Fade up on Evelyn's eyes opening. Slow push back as she rises, moves to the window. Village chaos visible outside. Follow her to the gate.
**LIGHTING**: Pre-dawn blue-black. Alarm torchlight (orange flicker) from village. Bell tower spotlight (warm amber) cutting through the dark.
**MUSIC**: None at first. Only bells. At 25s: low strings enter — urgent, not yet aggressive. At 40s: percussion joins, building tension.
**DURATION**: ~75 seconds

**PreCutsceneAction**:
- Disable player input for all party members
- Set time to pre-dawn (darkness with blue-black ambient)
- Spawn alarm bell audio on loop (every 2s)
- Spawn NPC villagers running in panic paths toward central square
- Spawn Church strike team at village perimeter (visible in distance, torches)
- Position Evelyn in her room at party camp, sleeping state
- Set village state from PEAK to EMERGENCY (festival lights off, damage flags queued)
- Queue pre-dawn fog VFX (low-lying, subtle)

**[NODE: ch6_alarm_01]**
`EVELYN` — [Eyes open. Instantly alert. Ears forward.]

> "Bells."

**Notes:** One word. Vampire senses — she knows before anyone what bells mean.

**[NODE: ch6_alarm_02]**
`EVELYN` — [Rises. No grogginess. Moves to window.]

> "Not practice. Not a drill. Those are real."

**Notes:** She distinguishes alarm types. These are the real ones.

**[NODE: ch6_alarm_03]**
`EVELYN` — [Looks out. Torchlight. Movement at the perimeter.]

> "Church knights. At the walls."

**Notes:** Not surprise. Recognition. The Church has come.

**[NODE: ch6_alarm_04]**
`EVELYN` — [Already moving. Door opens. Into the corridor.]

> "Everyone up. Now. Church at the gates."

**Notes:** Her voice is calm but carries. She does not panic. She mobilizes.

**[NODE: ch6_alarm_05]**
`EVAN` — [Appears from adjacent room. Armor half-on. Sword in hand.]

> "How many?"

**Notes:** Evan does not ask if. He asks how many. He is already in soldier mode.

**[NODE: ch6_alarm_06]**
`EVELYN` — [Already at the gate. Counting with enhanced senses.]

> "Eight. Maybe ten. Elite. They brought torches and siege tools."

**Notes:** She can count them in the dark. Vampire sight. Her voice is flat.

**[NODE: ch6_alarm_07]**
`EVAN` — [Reaches her side. Assesses.]

> "Strike team. Not a patrol. This is a response."

**Notes:** He identifies the nature instantly. This is retaliation for Ch5 raid.

**[NODE: ch6_alarm_08]**
`EVELYN` — [Tail still. Ears forward. Voice steady.]

> "They found us. Because of what we did."

**Notes:** She connects the dots. Their victory brought this. Guilt, not stated.

**[NODE: ch6_alarm_09]**
`EVAN` — [Draws sword. Stands beside her.]

> "Because of what they do. This is on them. Not us."

**Notes:** Evan redirects the guilt. Important moment. He protects her from self-blame.

**[NODE: ch6_alarm_10]**
`SILAS` — [Running up. Medical kit on his back.]

> "Where do you need me?"

**Notes:** Silas does not ask what is happening. He asks where he is needed.

**[NODE: ch6_alarm_11]**
`EVELYN` — [Points to the central square.]

> "Set up by the well. People will get hurt. Be ready."

**Notes:** Direct, clear orders. She is in protector mode.

**[NODE: ch6_alarm_12]**
`KAELEN` — [Already at the wall. Shield on his back. Scanning.]

> "East wall is weak. I am holding it. Send backup."

**Notes:** Kaelen has already identified the vulnerability and claimed it.

**[NODE: ch6_alarm_13]**
`EVELYN` — [Nods. Turns to the gate. Takes position.]

> "Then we hold. All of us. Together."

**Notes:** Not a speech. A statement of fact. This is what they will do.

**[NODE: ch6_alarm_14]**
`EVAN` — [Beside her. Sword ready. Voice quiet.]

> "Together."

**Notes:** He echoes her word. It matters. It is a promise.

**AnimationPlayer Tracks**:
- `Camera`: Black screen (0s) → bell sound (2s) → close-up Evelyn eyes open (4s) → pull back to room (8s) → over-shoulder window (14s) → POV outside torches (18s) → follow Evelyn corridor (24s) → medium Evelyn calling out (28s) → two-shot Evelyn+Evan (34s) → perimeter wide shot (42s) → individual close-ups Silas/Kaelen (50s-60s) → gate position two-shot (66s-75s)
- `Bell_tower`: Bell swing animation, 2s cycle, throughout
- `Evelyn_eyes_open`: Animation at 4s, instant alertness
- `Evelyn_ears_forward`: Animation at 4s, holds through scene
- `Evelyn_tail_still`: Animation at 38s — tail is still, not curled, tension
- `Evan_half_armor`: Prop state at 34s — armor partially equipped
- `Silas_run`: Running animation with medical kit, 50s-54s
- `Kaelen_wall`: Already positioned at wall, scanning animation, 58s-62s
- `Torch_flicker`: Perimeter torches, orange flicker, continuous from 18s
- `Fog_low`: Pre-dawn fog VFX, subtle, ground-level, continuous from 10s
- `Music_none_to_strings`: Enter low strings at 25s, percussion at 40s, build through end
- `Villager_panic`: NPC villagers running to central square, paths 15s-75s

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `village_emergency_state` → fire at 18s (switch from PEAK to EMERGENCY)
- `party_mobilized` → fire at 60s (all members in position)
- `ch6_alarm_complete` → fire at 70s
- `player_input_released` → fire at 75s
- `combat_village_defense_start` → fire at 75s, position Evelyn at gate

**VFX Triggers**:
- `predawn_darkness` → ambient lighting, blue-black, entire scene
- `alarm_torchlight` → 20+ torch props around perimeter, orange flicker, 2s cycle
- `bell_tower_spotlight` → warm amber cone from bell tower, continuous
- `predawn_fog` → low-lying fog particle system, ground-level, subtle, continuous
- `vampire_eye_glow` → subtle red tint on Evelyn's eyes at 4s-8s, very subtle

**Audio Cues**:
- `alarm_bell_loop` → bell every 2s, -14dB, dominant, continuous
- `villager_panic_chatter` → distant shouting, running footsteps, -20dB, from 15s
- `church_torches_approach` → distant torch crackle, marching feet, -22dB, from 18s
- `footstep_urgent` → Evelyn and party running, hard-soled, -12dB, 24s-60s
- `sword_draw` → Evan's sword, sharp metallic, -10dB, at 36s
- `low_strings_urgent` → enters at 25s, building tension, no melody yet
- `percussion_tension` → enters at 40s, steady pulse, increasing tempo

**PostCutsceneAction**:
- Release player input for Evelyn
- Enable combat state: Village Defense encounter
- Set all party members to combat-ready AI behavior
- Church strike team begins assault on multiple perimeter points
- Enable multi-point defense mechanics (north wall, east gate, south perimeter)
- Set enhanced creature as reserve deployment (spawns at 60s into combat)
- Flag `ch6_alarm_seen = true`

**Skip Rules**:
- Player can skip after node 6 (34s mark)
- Skipping jumps to `party_mobilized` state
- All party members are positioned at their defense stations
- Village is in EMERGENCY state
- Combat encounter begins immediately after skip

---

### SCENE 2: ch6_aftermath — The Cost of Victory

**TRIGGER**: `ch6_aftermath`
**LOCATION**: Oakhaven village post-battle — dawn light, damage visible, exhausted party
**CAMERA**: Wide on damaged village. Slow pan across destruction: gate, wall, forge. Push in on party standing among the damage. Individual close-ups as they react.
**LIGHTING**: Early dawn light — pale gold, cold. Damage visible in stark clarity. Smoke from small fires.
**MUSIC**: Solo cello — low, mournful but not defeated. Resolves to something steadier by the end.
**DURATION**: ~80 seconds

**PreCutsceneAction**:
- Disable player input
- Set combat end state: Church strike team defeated, enhanced creature defeated
- Enable damage props: damaged gate, scorched wall, scorch mark on forge
- Position party members at various points around the village
- Spawn repair NPCs (villagers assessing damage)
- Set ambient lighting to early dawn (pale gold, cold)
- Queue smoke VFX from small fires

**[NODE: ch6_aftermath_01]**
`EVELYN` — [Standing at the damaged gate. Tail low. Ears back slightly.]

> "The gate held. Barely."

**Notes:** She assesses before she feels. The protector first, the person second.

**[NODE: ch6_aftermath_02]**
`EVAN` — [Walking the perimeter. Inspecting scorch marks.]

> "They were testing us. Seeing what we could do."

**Notes:** Tactical assessment. He is already thinking about the next attack.

**[NODE: ch6_aftermath_03]**
`EVELYN` — [Turns to him. Voice quieter.]

> "And what can we do?"

**Notes:** Not rhetorical. She genuinely wants to know. She trusts his assessment.

**[NODE: ch6_aftermath_04]**
`EVAN` — [Looks at the damage. Honest.]

> "Enough to make them send more. That is the problem."

**Notes:** The truth, delivered plainly. Their competence provoked escalation.

**[NODE: ch6_aftermath_05]**
`BLACKSMITH` — [At the forge. Running a hand over the scorch mark.]

> "My forge still stands. That is what matters."

**Notes:** The blacksmith does not dramatize. Practical resilience. Evelyn's friend.

**[NODE: ch6_aftermath_06]**
`EVELYN` — [To the blacksmith. Guilt, barely contained.]

> "I am sorry. I brought this here."

**Notes:** She takes responsibility. This is her wound, not theirs.

**[NODE: ch6_aftermath_07]**
`BLACKSMITH` — [Looks at her. Firm. Not unkind.]

> "You brought us safety. They brought this. Do not confuse them."

**Notes:** The blacksmith redirects the guilt. The village chose to stand with her.

**[NODE: ch6_aftermath_08]**
`EVELYN` — [Looks away. Stores the blacksmith's words. Tail still.]

> "Thank you."

**Notes:** She stores it. The moment, the loyalty, the choice the village made.

**[NODE: ch6_aftermath_09]**
`SILAS` — [Hands stained. Voice tired but steady.]

> "Three serious injuries. No fatalities. That is— that is good."

**Notes:** Silas counts the living, not the dead. That is his discipline.

**[NODE: ch6_aftermath_10]**
`EVELYN` — [To Silas. Genuine gratitude.]

> "Because of you. You kept them alive."

**Notes:** She gives credit. She does not hoost it. Silas matters.

**[NODE: ch6_aftermath_11]**
`SILAS` — [Shakes his head. Small smile.]

> "Because we all held the line. I just patched the gaps."

**Notes:** Silas deflects credit back to the group. That is his nature.

**[NODE: ch6_aftermath_12]**
`KAELEN` — [At the east wall. Shield scarred. Voice flat.]

> "The creature they sent. Enhanced. Partial seal stability."

**Notes:** Kaelen reports the tactical finding. He is still processing it.

**[NODE: ch6_aftermath_13]**
`EVAN` — [Turns to Kaelen. Sharp attention.]

> "You are sure?"

**Notes:** Evan recognizes the significance. Partial seal means directed deployment.

**[NODE: ch6_aftermath_14]**
`KAELEN` — [Nods. Looks at his scarred shield.]

> "I have seen them before. They were holding it back. Until now."

**Notes:** The Church was saving these assets. The raid forced their hand.

**[NODE: ch6_aftermath_15]**
`EVELYN` — [Quiet. Processing. Tail begins to curl — not happiness, tension.]

> "They were saving them. For special operations. We made them use one."

**Notes:** She connects the dots. Their victory cost the Church a reserve asset.

**[NODE: ch6_aftermath_16]**
`EVAN` — [Meets her eyes. Voice steady, warm.]

> "And we defeated it. That is the part that matters."

**Notes:** Evan redirects from guilt to victory. He protects her from spiraling.

**[NODE: ch6_aftermath_17]**
`EVELYN` — [Looks at the village. At the people. At her party.]

> "They will come back. With more."

**Notes:** Not fear. Fact. She is preparing, not panicking.

**[NODE: ch6_aftermath_18]**
`EVAN` — [Stands beside her. Shoulder almost touching.]

> "Then we will be ready. We are getting stronger too."

**Notes:** He does not promise safety. He promises growth. That is honest.

**[NODE: ch6_aftermath_19]**
`EVELYN` — [Looks at him. Something softens. Just for a moment.]

> "Yes. We are."

**Notes:** She believes him. Because it is true. And because she needs to.

**[NODE: ch6_aftermath_20]**
`EVELYN` — [Turns back to the village. Voice firmer now.]

> "Repair what we can. Rest what we must. They will not catch us sleeping."

**Notes:** The leader speaks. Not commanding — organizing. She is in her element.

**AnimationPlayer Tracks**:
- `Camera`: Wide damaged village (0s) → pan gate/wall/forge (10s-20s) → push-in party group (25s) → individual close-ups (30s-65s) → two-shot Evelyn+Evan (65s-75s) → Evelyn addressing village (75s-80s)
- `Damage_gate`: Damaged gate prop, visible from 0s, hinge broken, wood splintered
- `Damage_wall`: Scorched perimeter wall, visible from 8s, fresh burn marks
- `Damage_forge`: Scorch mark on forge wall, visible from 16s, black streak on stone
- `Smoke_small_fires`: Particle systems at 3 fire points, continuous, dissipating
- `Evelyn_tail_low`: Animation at 0s-25s, tail low, tension
- `Evelyn_tail_tension`: Animation at 52s-60s, tail begins to curl — tension, not joy
- `Evelyn_soften`: Subtle animation at 70s — something softens in her face, brief
- `Silas_stained_hands`: Prop state at 38s — hands show blood/herb stains
- `Kaelen_scarred_shield`: Prop state at 50s — shield shows fresh damage
- `Blacksmith_hand_scorch`: Animation at 24s — hand touching scorch mark
- `Music_cello`: Enters at 0s, low mournful, resolves to steadier at 55s, warm at 70s
- `Villager_repair`: NPCs assessing damage, carrying materials, paths throughout

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `village_damage_visible` → fire at 8s (enable all damage props fully)
- `ch6_aftermath_complete` → fire at 72s
- `player_input_released` → fire at 80s
- `gameplay_resume_aftermath` → fire at 80s, position at central square

**VFX Triggers**:
- `dawn_pale_gold` → directional light, cold gold tone, entire scene
- `smoke_fires` → 3 smoke particle systems, dissipating, continuous
- `dust_settling` → dust motes in dawn light, sparse, post-battle atmosphere
- `scorch_mark_glow` → faint residual heat shimmer on forge scorch, very subtle

**Audio Cues**:
- `dawn_quiet` → morning ambience, birds returning, -24dB, from 0s
- `villager_repair_chatter` → assessing damage, carrying materials, -22dB
- `cello_mournful` → solo cello, low, enters at 0s, resolves at 55s
- `footstep_slow` → party walking among damage, heavy, -14dB
- `blacksmith_forge_cold` → forge no longer burning, just cooling metal ticks, -26dB
- `repair_hammer` → distant repair sounds starting at 50s, -28dB

**PostCutsceneAction**:
- Release player input
- Flag `ch6_aftermath_seen = true`
- Enable `ch6_tactical_documents` trigger (documents available for pickup)
- Set village state to DAMAGED (repair NPCs active, vendors limited)
- Party members return to idle behaviors near their combat positions
- Evelyn available for bond conversation about guilt/responsibility

**Skip Rules**:
- Player can skip after node 8 (30s mark)
- Skipping jumps to `ch6_aftermath_complete` state
- All damage props are enabled, village is in DAMAGED state
- Tactical documents are available for pickup
- No narrative content is lost — context provided via follow-up dialogue

---

### SCENE 3: ch6_witch_shadow_first — The Distant Figure

**TRIGGER**: `ch6_witch_shadow_first`
**LOCATION**: Destroyed Church outpost — precise collapse, symbol in stone, distant hillside
**CAMERA**: Wide on destroyed outpost. Slow push into the ruins. Cut to symbol in stone. Cut to hillside — figure visible, watching. Hold on figure. Figure turns, walks away. Camera returns to party reacting.
**LIGHTING**: Overcast afternoon. Cold, flat light. The ruins cast sharp shadows. The symbol on the stone has a faint magical glow (green-white, cold).
**MUSIC**: None at first. Ambient wind and silence. At 30s: a single high string note, sustained, unresolved. At 45s: a second note joins — dissonance, mystery.
**DURATION**: ~85 seconds

**PreCutsceneAction**:
- Disable player input
- Position party at approach path to destroyed outpost
- Set outpost to destroyed state (collapsed buildings, neutralized guards)
- Enable Witch's symbol prop on central stone (faint green-white glow)
- Position Witch figure on hillside (full body, back to camera, still)
- Set ambient lighting to overcast (cold, flat, no direct sun)
- Spawn residual energy VFX around symbol (cold, green-white, subtle)
- Queue Evan's detector prop (reading high, unknown frequency)

**[NODE: ch6_witch_01]**
`EVELYN` — [Approaching the ruins. Ears forward, tense. Tail still.]

> "This was not us."

**Notes:** Obvious, but she says it anyway. She needs the group to know she did not do this.

**[NODE: ch6_witch_02]**
`EVAN` — [Scanning the destruction. Detector in hand, reading high.]

> "No. This is not any creature I have records for either."

**Notes:** Evan's detector is his authority. It does not recognize this signature.

**[NODE: ch6_witch_03]**
`EVELYN` — [Walking through the ruins. Precise destruction.]

> "Look at this. Buildings collapsed inward. Not burned. Not smashed."

**Notes:** She observes the precision. This was controlled, not chaotic.

**[NODE: ch6_witch_04]**
`KAELEN` — [Examining a collapsed wall. Tactical eye.]

> "Targeted. Each building folded in. Whoever did this knew what they wanted."

**Notes:** Kaelen reads the destruction tactically. It was deliberate.

**[NODE: ch6_witch_05]**
`EVAN` — [Looking at unconscious guards.]

> "Guards alive. Neutralized, not killed. This was not a massacre."

**Notes:** The distinction matters. This was not rage. It was purpose.

**[NODE: ch6_witch_06]**
`SILAS` — [Checking a guard's pulse. Voice quiet.]

> "They are breathing. Whatever did this— chose not to kill."

**Notes:** Silas confirms medically. The restraint is intentional.

**[NODE: ch6_witch_07]**
`EVELYN` — [Moving toward the central stone. Sensing something.]

> "There is— something here. In the stone. At the center."

**Notes:** Her vampiric senses pick up the residual energy before anyone sees it.

**[NODE: ch6_witch_08]**
`EVELYN` — [At the central stone. Looking at the symbol. Still.]

> "That mark. I have never seen anything like it."

**Notes:** The symbol is burned into the stone. Magical energy. Not Church. Not natural.

**[NODE: ch6_witch_09]**
`EVAN` — [Detector at maximum. Voice flat.]

> "Intensity off the scale. Frequency unknown. This is— this is not Church."

**Notes:** The detector cannot classify it. This is a new category of power.

**[NODE: ch6_witch_10]**
`EVELYN` — [Reaching toward the symbol. Not touching. Sensing.]

> "It feels like— like grief. That sounds mad. But it does."

**Notes:** The key line. Evelyn's vampiric intuition reads emotional content in magical energy.

**[NODE: ch6_witch_11]**
`EVAN` — [Looks at her. Does not dismiss it.]

> "Grief?"

**Notes:** He takes her seriously. He has learned to trust her instincts.

**[NODE: ch6_witch_12]**
`EVELYN` — [Nods. Hand still near the symbol. Eyes distant.]

> "Cold grief. Old grief. The kind that does not heal. It just— hardens."

**Notes:** She reads the emotional quality of the energy. It tells her everything.

**[NODE: ch6_witch_13]**
`EVELYN` — [Suddenly. Head snaps up. Ears lock on something.]

> "Wait. Someone is— up there."

**Notes:** Her enhanced senses detect the figure before anyone else.

**[NODE: ch6_witch_14]**
`CAMERA