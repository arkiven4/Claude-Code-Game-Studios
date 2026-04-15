# Chapter 5: "Bonds" — Narrative Design Document

> **Chapter Number**: 5
> **POV Characters**: Evelyn and Evan (alternating)
> **Duration**: 90-120 minutes
> **Emotional Arc**: Relief -> Joy -> Satisfaction
> **Status**: Authoritative — awaiting narrative director review
> **Last Updated**: 2026-04-14
> **Cross-Reference**: [level-design.md](../../../levels/chapter5-bonds/level-design.md)

---

## 1. Overview

Chapter 5 is the breathing room of the game — the happiest extended sequence in the entire narrative. After the shock, revelation, and alliance of Chapter 4, the party arrives at the village hub at its peak: bustling, festive, alive with people who owe their safety to Evelyn and her companions. The village is not just a base — it is a living community, and the player should never want to leave.

This chapter accomplishes three things: party assembly, village immersion, and the first major raid. The support members who joined briefly at the end of Chapter 4 are formally introduced through dedicated introduction sequences. Two new members join: Silas the healer and Kaelen the tank, each with their own narrative arc that makes the player fall in love with them. These are the companions who will be threatened in later chapters. The player must care about them deeply.

Evelyn's POV sections are warm, relaxed, and joyful. Her tail curls when she is happy — and she is happy often in this chapter. She builds bonds with every party member through dedicated sequences. Evan's POV sections show his formal demeanor softening. He smiles more. He is protective but understated, letting his actions speak louder than words.

The chapter culminates in the first major raid on a Church Tier 2 facility — the biggest combat encounter the player has faced. The raid is preceded by a village celebration, a campfire scene, and a morning assembly that makes the party feel like a family going to war together. The victory is sweet, warm, and earned.

The chapter ends with a faint undertone: things are almost too good. The player should feel warmth, but also the smallest seed of "this cannot last." It will not. Later chapters will test every bond forged here.

---

## 2. Player Fantasy

### As Evelyn — The Host
The player experiences Evelyn at her most relaxed and happy. She is surrounded by people who chose to be here — chose her. The village she protected is thriving, and she is the center of a community that celebrates her without knowing what she is. The player should feel the joy of belonging, the warmth of purpose, and the quiet satisfaction of a life built from nothing.

### As Evan — The Partner
The player experiences Evan's transition from Church hunter to trusted companion. He is learning what it means to be part of something chosen rather than assigned. His formal speech relaxes. He smiles. He watches Evelyn with growing affection and says very little about it. The player should feel the warmth of someone who is discovering that he is allowed to be happy.

### As the Party — The Family
Through introduction sequences, bond sequences, and the shared raid, the player builds emotional investment in every party member. Silas's gentle competence and quiet grief make him the person you want at your side. Kaelen's steadfast loyalty and dry humor make him the shield you trust. The support members round out the ensemble. The player must fall in love with these people — because later chapters will threaten them.

### As a Commander — The Raid Leader
The first major raid on a Church Tier 2 facility is the biggest combat encounter yet. The player controls Evelyn (with Evan switching POV during the raid) leading a full party through a fortified Church position. The preparation, the approach, the combat, and the victory all carry emotional weight because the player cares about the people fighting alongside them.

### The Undertone — The Shadow
Beneath the warmth, the faintest shadow: this is too good to last. Small moments — a pause that lasts a beat too long, a look exchanged between Evelyn and Evan that carries weight, Kaelen checking his shield with extra care — hint that something is coming. The player should feel it without being able to name it.

---

## 3. Narrative Arc

### 3.1 Arrival at the Village Peak (Minutes 0-12) — Evelyn POV

The party arrives at the village. It is transformed — not just surviving, but thriving. Banners hang from rooftops. Children run through the streets. The market is full. Evelyn is recognized not as a monster but as the person who saved them all.

The village hub is at its PEAK state. All vendors are active. Side quests are available. Festival atmosphere permeates everything. Evelyn walks through the village with the party, and each member reacts to the warmth of the community in character-appropriate ways.

**Trigger:** `ch5_village_hub_peak`

Evelyn's internal monologue reveals her joy and her slight disbelief that this is real. She has been alone so long that a bustling village full of people who smile at her feels almost unreal.

### 3.2 Silas Introduction (Minutes 12-22) — Evan POV

Evan finds Silas in a makeshift clinic, treating villagers with the same steady care he showed the party during the escape. This sequence formally introduces Silas as a party member with his own identity, backstory fragments, and bond potential.

Silas is treating a child's scraped knee with the same attention he would give a battlefield wound. Evan watches this and begins to understand who Silas is: not just a healer, but a man who treats every injury as if it matters.

Their conversation reveals Silas's guilt — he carries the weight of patients he could not save. He does not perform his grief. He metabolizes it through work. Evan, who carries his own institutional guilt, recognizes something familiar.

**Trigger:** `ch5_member1_intro` → `ch5_member1_joins`

### 3.3 Kaelen Introduction (Minutes 22-32) — Evelyn POV

Evelyn finds Kaelen on the village perimeter, walking a patrol route he established without being asked. His shield is on his back. He is scanning the treeline. He has been guarding the village since dawn and has not told anyone.

This sequence formally introduces Kaelen as a party member. He is uncomfortable with the festival — too many people, too much noise, too many variables. But he is here because the village needs protecting, and Evelyn asked him to rest.

Their conversation reveals Kaelen's regret — the twelve years he spent holding the line for the wrong side. He does not ask for forgiveness. He asks for a chance to do better. Evelyn gives him both without condition.

**Trigger:** `ch5_member2_intro` → `ch5_member2_joins`

### 3.4 Support Member Introductions (Minutes 32-42) — Alternating POV

The support members who joined at the end of Chapter 4 receive dedicated introduction sequences. Each reveals their personality, their reason for joining, and their bond with at least one main character.

**Trigger:** `ch5_member3_intro` → `ch5_member3_joins` → `ch5_member4_intro` → `ch5_member4_joins`

### 3.5 Village Immersion and Side Quests (Minutes 42-65) — Alternating POV

The player explores the village hub freely. Side quests are available that deepen bonds with party members. Each side quest has a narrative payoff — a conversation, a shared moment, a small revelation about a character's past.

**Trigger:** `ch5_side_quest_bond`

Evelyn helps a baker prepare festival bread. Evan assists the village guard with patrol routes. Silas treats an elderly villager's chronic pain. Kaelen helps children build a practice shield-wall with wooden boards.

These sequences are optional but strongly encouraged. They are the emotional investment phase — the player falls in love with the village and the people in it.

### 3.6 Evening Celebration (Minutes 65-78) — Evelyn POV

The village holds a celebration — music, food, warmth. The party sits together for the first time as a full group in a non-crisis context. This is the happiest scene in the game.

Evelyn's tail curls openly. Evan smiles — genuinely, not the tight acknowledgment he has used before. Silas tells a terrible medical pun that makes everyone groan. Kaelen makes a dry observation that makes Evelyn snort with laughter.

The camera lingers. The player should never want to leave.

### 3.7 Campfire Conversations (Minutes 78-88) — Alternating POV

After the celebration, smaller conversations happen around the campfire. One-on-one bond moments between party members. The player experiences these as Evelyn or Evan, moving between fires and listening.

These are quiet, tender moments. Not every conversation needs resolution. Some are just presence.

### 3.8 The Raid — Approach (Minutes 88-95) — Evan POV

Morning comes. The party assembles for the raid on a Church Tier 2 facility. The mood shifts — not to fear, but to purpose. They are not afraid. They are ready.

Evan briefs the party on the approach. Kaelen handles tactical planning. Silas checks everyone's supplies. The support members prepare their roles. Evelyn stands at the center, watching her team, and feels something she has not felt before: confidence.

**Trigger:** `ch5_raid_approach`

### 3.9 The Raid — Combat (Minutes 95-110) — Evelyn/Evan POV Switch

The raid is the biggest combat encounter yet. A fortified Church Tier 2 facility with multiple wings, elite guards, and a commander. The full party fights together.

Evelyn and Evan switch POV during the raid — Evelyn for the aggressive pushes, Evan for tactical moments. The switching emphasizes their growing synchronicity as partners.

**Trigger:** `ch5_raid_combat`

### 3.10 The Raid — Victory (Minutes 110-117) — Evelyn POV

The facility falls. The party stands victorious among the wreckage. They found evidence of the Church's expanding operations — the threat is growing, but so are they.

The victory is warm, not triumphant. They are not celebrating destruction. They are celebrating survival — together.

**Trigger:** `ch5_raid_victory`

### 3.11 Chapter Close (Minutes 117-120) — Evelyn POV

The party returns to the village. The celebration has wound down. The streets are quiet. Evelyn walks alone for a moment, looking at the sleeping village, and feels the weight of everything she has built.

Evan joins her. They stand together. The chapter ends with warmth — and the faintest shadow of "too good to last."

**Trigger:** `ch5_chapter_close`

---

## 4. Cutscene Scripts

### SCENE 1: ch5_village_hub_peak — Arrival at the Village

**TRIGGER**: `ch5_village_hub_peak`
**LOCATION**: Village entrance — morning, golden light, banners, children playing
**CAMERA**: Wide establishing shot. The party stands at the village entrance. Slow pan across the bustling scene. Push in on Evelyn's face as she takes it in.
**LIGHTING**: Warm golden morning light. Festival banners catch the breeze. Dust motes in the air.
**MUSIC**: Light strings and woodwinds. Joyful but not grand — intimate, warm, like coming home.
**DURATION**: ~60 seconds

**PreCutsceneAction**:
- Disable player input for all party members
- Position party at village entrance gate in formation
- Set village to PEAK state (all vendors active, NPCs spawning, festival decorations)
- Spawn children NPCs running between buildings
- Queue ambient crowd chatter

**[NODE: ch5_arrival_01]**
`EVELYN` — [Standing at the gate. Ears forward. Tail beginning to curl.]

> "Listen to that."

**Notes:** She is listening to the village life. The hum of people living safely.

**[NODE: ch5_arrival_02]**
`EVAN` — [Beside her. Looking around. Something softens in his face.]

> "It sounds like a real town."

**Notes:** Not "a town." "A real town." The word "real" carries weight.

**[NODE: ch5_arrival_03]**
`EVELYN` — [Steps forward. A child runs past and waves. She waves back.]

> "It is. It always was. They just needed space to breathe."

**Notes:** She takes credit for nothing. "Space to breathe" — she gave them that.

**[NODE: ch5_arrival_04]**
`SILAS` — [Behind them. Looking at the clinic building. Voice warm.]

> "There is a clinic. I can— I could help, if they need it."

**Notes:** Silas cannot not work. A clinic is a beacon to him. He catches himself.

**[NODE: ch5_arrival_05]**
`EVELYN` — [Turns to Silas. Smile.]

> "They need it. And so do you. But yes — help them."

**Notes:** She gives him permission and purpose in one sentence.

**[NODE: ch5_arrival_06]**
`KAELEN` — [Standing apart. Scanning rooftops, treeline, gate.]

> "Three sightlines from the east wall. I will walk the perimeter."

**Notes:** Kaelen cannot not protect. The festival means nothing if the perimeter is open.

**[NODE: ch5_arrival_07]**
`EVELYN` — [To Kaelen. Gentle but firm.]

> "Kaelen. The perimeter has been secure for months. Walk it later. Rest now."

**Notes:** She uses his name. Not his full name — warm, not formal. Permission to rest.

**[NODE: ch5_arrival_08]**
`KAELEN` — [Looks at her. Pauses. Slowly nods.]

> "After I check the east wall. Then I will rest. That is my offer."

**Notes:** Compromise. Kaelen does not fully relax yet. But he is trying.

**[NODE: ch5_arrival_09]**
`EVAN` — [Watching the village. Voice quiet, almost to himself.]

> "People are waving at us."

**Notes:** Evan is not used to being welcomed. Church knights are feared or obeyed.

**[NODE: ch5_arrival_10]**
`EVELYN` — [Looks at him. Tail curling more openly.]

> "They are waving at me. You are just here because you are with me."

**Notes:** Playful teasing. She is happy. Her tail betrays it.

**[NODE: ch5_arrival_11]**
`EVAN` — [Almost smiles. Almost.]

> "I can live with that."

**Notes:** He can. He is learning to.

**[NODE: ch5_arrival_12]**
`EVELYN` — [Steps fully into the village. The camera follows her.]

> "Come on. Let me show you where the bread is."

**Notes:** The most important thing in a village is the bread. She knows this.

**AnimationPlayer Tracks**:
- `Camera`: Wide gate (0s) → pan across village (8s) → push-in Evelyn face (18s) → medium group (30s) → individual close-ups (38s-50s) → follow Evelyn walking (55s-60s)
- `Evelyn_ears_forward`: Animation at 0s-3s, hold through scene
- `Evelyn_tail_curl_start`: Animation begins at 3s, gradual increase through scene
- `Evan_soften_face`: Subtle animation at 15s-20s, shoulders drop slightly
- `Child_run_wave`: Child NPC runs past at 12s, waves, continues
- `Banner_flap`: Loop animation on all banners, wind cycle 4s
- `Kaelen_scan`: Head turn animation at 25s, 27s, 30s (three sightline checks)
- `Music_fade`: Enter at 0s, swell at 18s, hold warm through end

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `village_hub_peak_active` → fire at 10s (enable full village state)
- `ch5_arrival_complete` → fire at 55s
- `player_input_released` → fire at 60s
- `gameplay_resume_village` → fire at 60s, position at village entrance

**VFX Triggers**:
- `golden_morning_light` → directional light, warm amber tone, entire scene
- `dust_motes` → particle system, sparse, floating in light shafts
- `festival_banners` → 12 banner props across village, wind animation
- `child_particles` → subtle sparkle trail on running child NPC at 12s

**Audio Cues**:
- `crowd_ambient_peak` → layered crowd chatter, -16dB, continuous
- `children_laughing` → intermittent, -22dB, every 3-5s
- `village_bells` → distant bell, every 15s, -26dB
- `footstep_village_path` → soft dirt path, alternating characters, -12dB
- `strings_woodwinds_joy` → light, warm, enters at 0s, swells at 18s

**PostCutsceneAction**:
- Release player input for Evelyn
- Enable village hub interactions (all vendors, NPCs, side quests)
- Set party members to free roam with idle behaviors
- Silas pathfinds toward clinic building
- Kaelen pathfinds toward east wall
- Evan stays near Evelyn for 10s, then explores
- Start timer for Silas introduction trigger (available after 5 min exploration)

**Skip Rules**:
- Player can skip after node 4 (30s mark)
- Skipping jumps to `village_hub_peak_active` state
- All party member positions are set to default exploration states
- No narrative content is lost — arrival context is provided via ambient dialogue

---

### SCENE 2: ch5_member1_intro — Silas in the Clinic

**TRIGGER**: `ch5_member1_intro`
**LOCATION**: Village clinic — warm light, herb bundles drying, bandage supplies organized
**CAMERA**: Medium on Silas working. Push in as Evan enters. Two-shot develops.
**LIGHTING**: Warm amber light from windows. Herb bundles cast soft shadows.
**MUSIC**: Solo piano — gentle, steady, like a heartbeat.
**DURATION**: ~70 seconds

**PreCutsceneAction**:
- If player is controlling Evelyn, switch POV to Evan
- Position Evan at clinic doorway
- Position Silas at workbench, treating a bandage roll
- Spawn clinic props: herb bundles, bandages, vials, small cot
- Set clinic interior lighting to warm amber

**[NODE: ch5_silas_intro_01]**
`EVAN` — [Clinic doorway. Watching. Silas does not notice him yet.]

> "You set this up fast."

**Notes:** Silas has been here less than an hour and has already organized the clinic.

**[NODE: ch5_silas_intro_02]**
`SILAS` — [Still working. Voice warm, not looking up.]

> "It was mostly here. I just— tidied. Old habit."

**Notes:** "Tidied" means he reorganized everything by type, urgency, and expiry date.

**[NODE: ch5_silas_intro_03]**
`EVAN` — [Steps inside. Looks at the organization. Impressed.]

> "You sorted the herbs by potency and shelf life."

**Notes:** Evan notices details. It is what he does. He notices Silas's competence.

**[NODE: ch5_silas_intro_04]**
`SILAS` — [Finally looks up. Small smile.]

> "If you are going to use something, know what it does. And when it expires."

**Notes:** Silas's philosophy in one sentence. Knowledge, readiness, care.

**[NODE: ch5_silas_intro_05]**
`EVAN` — [Leans against the wall. More relaxed posture.]

> "The village is lucky to have you."

**Notes:** Evan means it. He is also saying: I am lucky to have you.

**[NODE: ch5_silas_intro_06]**
`SILAS` — [Sets down the bandage. Voice gets quieter.]

> "I could not save everyone back at the hospital. The ones I lost—"

**Notes:** He does not finish. He does not need to. The guilt is present.

**[NODE: ch5_silas_intro_07]**
`EVAN` — [Direct. Not platitudes.]

> "You saved us. In that forest. You kept all of us alive."

**Notes:** Facts. Evan gives Silas what he needs: evidence that his work matters.

**[NODE: ch5_silas_intro_08]**
`SILAS` — [Looks at his hands. Scarred. Steady.]

> "Yes. I did. And I will keep doing it. That is all I can do."

**Notes:** The discipline of hope. Silas accepts the limit and chooses to act anyway.

**[NODE: ch5_silas_intro_09]**
`EVAN` — [Nods. A beat of shared understanding.]

> "It is enough. It has to be."

**Notes:** Evan knows this truth. He carried his own version of it for years.

**[NODE: ch5_silas_intro_10]**
`SILAS` — [Picks up a vial. Checks the seal. Voice lighter.]

> "Tell the others to stay out of trouble. I know that is asking a lot."

**Notes:** Silas's humor. Dry, warm, deployed to ease the heaviness.

**[NODE: ch5_silas_intro_11]**
`EVAN` — [Almost smiles.]

> "I will tell them. They will not listen."

**Notes:** He is right. They will not. But he will tell them anyway.

**[NODE: ch5_silas_intro_12]**
`SILAS` — [Smiles properly now.]

> "Then I will be here when they need me. As always."

**Notes:** The promise. Not dramatic. Quiet. Absolute. Silas will always be here.

**AnimationPlayer Tracks**:
- `Camera`: Medium Silas working (0s) → push-in as Evan enters (8s) → two-shot (15s) → close Silas hands (30s) → close Evan face (42s) → two-shot warm (55s-70s)
- `Silas_work`: Bandage rolling animation, 0s-10s, sets down at 15s
- `Silas_hands_steady`: Subtle animation showing scarred but steady hands at 30s
- `Evan_lean_wall`: Animation at 18s, posture relaxes
- `Clinic_light`: Warm amber window light, continuous, slight flicker
- `Music_piano`: Enters at 0s, sparse, warm, resolves at 65s

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `silas_introduction_complete` → fire at 60s
- `player_input_released` → fire at 70s
- `gameplay_resume_clinic` → fire at 70s

**VFX Triggers**:
- `herb_bundle_shadows` → soft shadows from hanging herbs, continuous
- `vial_glow` → subtle refraction on glass vials, window-dependent
- `dust_in_light` → motes in window light shafts, sparse

**Audio Cues**:
- `clinic_quiet` → interior room tone, -24dB, warm
- `distant_festival` → muffled celebration sounds through walls, -30dB
- `piano_gentle` → solo piano, warm, enters at 0s, resolves at 65s
- `fabric_rustle` → bandage handling, -18dB, 0s-10s

**PostCutsceneAction**:
- Release player input
- Flag `silas_introduced = true`
- Enable `ch5_member1_joins` trigger (Silas formally joins party roster)
- Silas returns to clinic work; available for bond conversations
- Unlock Silas side quest chain

**Skip Rules**:
- Player can skip after node 5 (30s mark)
- Skipping jumps to `silas_introduction_complete` state
- All narrative flags are set as if the scene played fully
- Silas is available for bond conversations immediately

---

### SCENE 3: ch5_member2_intro — Kaelen on the Perimeter

**TRIGGER**: `ch5_member2_intro`
**LOCATION**: East wall perimeter — late morning, treeline visible, shield scuff marks on stone
**CAMERA**: Wide on Kaelen walking the wall. Cut to Evelyn approaching. Medium two-shot.
**LIGHTING**: Late morning sun, long shadows from the wall. Clear visibility.
**MUSIC**: Low strings — steady, grounded, like footsteps on stone.
**DURATION**: ~65 seconds

**PreCutsceneAction**:
- If player is controlling Evan, switch POV to Evelyn
- Position Kaelen on east wall, walking patrol route
- Position Evelyn at base of wall, looking up
- Kaelen has visible scuff marks on his shield from morning patrol
- Set perimeter lighting to late morning sun

**[NODE: ch5_kaelen_intro_01]**
`EVELYN` — [At the base of the wall. Looking up. Voice warm.]

> "Kaelen. You have walked this wall four times already."

**Notes:** She counted. She notices things about her people.

**[NODE: ch5_kaelen_intro_02]**
`KAELEN` — [Stops. Looks down. Not embarrassed.]

> "Five. You missed one. The south corner has a blind spot."

**Notes:** Kaelen does not argue. He provides data. The blind spot is real.

**[NODE: ch5_kaelen_intro_03]**
`EVELYN` — [Climbs the wall steps. Tail loose, not curled — she is serious.]

> "Show me."

**Notes:** She does not dismiss his concern. She investigates it with him.

**[NODE: ch5_kaelen_intro_04]**
`KAELEN` — [Points to a gap in the treeline coverage. Tactical.]

> "There. Someone could approach under the canopy. I will post a marker."

**Notes:** Kaelen speaks in tactical language. This is his comfort zone.

**[NODE: ch5_kaelen_intro_05]**
`EVELYN` — [Looks at the gap. Nods. Then looks at him.]

> "Good catch. Now— when was the last time you sat down?"

**Notes:** The pivot. She acknowledged his competence and is now addressing the real issue.

**[NODE: ch5_kaelen_intro_06]**
`KAELEN` — [Pauses. Truthful.]

> "I do not remember."

**Notes:** Kaelen does not lie. "I do not remember" means "I have not."

**[NODE: ch5_kaelen_intro_07]**
`EVELYN` — [Sits on the wall. Pats the stone beside her.]

> "Then this is a good time to start remembering."

**Notes:** Not a command. An invitation. She sits first — showing it is safe.

**[NODE: ch5_kaelen_intro_08]**
`KAELEN` — [Looks at the stone. At his shield. Slowly sits.]

> "The wall is secure. The blind spot is marked. I can— spare ten minutes."

**Notes:** He frames rest as a tactical decision. It is his way of accepting.

**[NODE: ch5_kaelen_intro_09]**
`EVELYN` — [Sitting beside him. Shoulders almost touching. Tail begins to curl.]

> "Ten minutes. Then you can walk it again. I will not stop you."

**Notes:** She does not try to change him. She offers a pause. That is enough.

**[NODE: ch5_kaelen_intro_10]**
`KAELEN` — [Looks at the village below. His shoulders drop. Just a little.]

> "It is loud down there. I am not used to— this many people being safe."

**Notes:** Kaelen's regret surfaces. He guarded people who were in danger. This is new.

**[NODE: ch5_kaelen_intro_11]**
`EVELYN` — [Soft. Understanding.]

> "Get used to it. This is what we are fighting for."

**Notes:** Not "what I am fighting for." "What we are." The party, together.

**[NODE: ch5_kaelen_intro_12]**
`KAELEN` — [Looks at her. The smallest smile. Not showing teeth.]

> "Yes. I suppose it is."

**Notes:** Kaelen smiles. The party will notice this later. It matters.

**AnimationPlayer Tracks**:
- `Camera`: Wide Kaelen on wall (0s) → cut Evelyn approaching (8s) → medium two-shot (15s) → close Kaelen pointing (25s) → sit animation (38s) → two-shot on wall (45s-65s)
- `Kaelen_walk_patrol`: Loop animation, 0s-12s, stops at 12s
- `Kaelen_points`: Animation at 22s-26s, arm extension toward treeline
- `Evelyn_climb_wall`: Animation at 18s-22s
- `Evelyn_sit`: Animation at 32s, pats stone at 30s
- `Kaelen_sit`: Animation at 38s-42s, slow, deliberate
- `Kaelen_shoulders_drop`: Subtle animation at 45s, posture releases tension
- `Evelyn_tail_cwall`: Tail begins to curl at 42s, gradual
- `Kaelen_smallest_smile`: Animation at 58s, subtle, brief
- `Music_strings`: Enters at 0s, steady, warms at 45s, holds

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `kaelen_introduction_complete` → fire at 55s
- `player_input_released` → fire at 65s
- `gameplay_resume_perimeter` → fire at 65s

**VFX Triggers**:
- `wall_shadow_long` → late morning shadows from wall, continuous
- `treeline_visibility` → clear view of forest edge, slight haze for depth
- `shield_scuff_marks` → visible wear on Kaelen's shield, close-up at 28s

**Audio Cues**:
- `wind_on_wall` → elevated position, wind slightly stronger, -18dB
- `distant_festival_clear` → celebration sounds more audible from wall, -24dB
- `footstep_stone_wall` → stone wall steps, heavier echo, -12dB
- `strings_steady` → low strings, grounded, enters at 0s, warms at 45s

**PostCutsceneAction**:
- Release player input
- Flag `kaelen_introduced = true`
- Enable `ch5_member2_joins` trigger (Kaelen formally joins party roster)
- Kaelen returns to light patrol; available for bond conversations
- Unlock Kaelen side quest chain
- Mark blind spot on village map (visible to player in future raids)

**Skip Rules**:
- Player can skip after node 5 (30s mark)
- Skipping jumps to `kaelen_introduction_complete` state
- All narrative flags are set as if the scene played fully
- Kaelen is available for bond conversations immediately
- Blind spot marker is still placed on the village map

---

### SCENE 4: ch5_member3_intro — Support Member Introduction

**TRIGGER**: `ch5_member3_intro`
**LOCATION**: Village square — midday, market stalls, festival preparations visible
**CAMERA**: Medium on support member interacting with villagers. Cut to POV character approaching.
**LIGHTING**: Bright midday sun, market stall shadows, colorful fabric banners
**MUSIC**: Light percussion and flute — bustling, warm, community energy
**DURATION**: ~50 seconds

**PreCutsceneAction**:
- Position support member at market stall, helping a vendor
- Position POV character approaching from village center
- Set market to active state (vendors trading, NPCs browsing)

**[NODE: ch5_support3_intro_01]**
`EVELYN` — [Approaching the market stall. Watching the support member work.]

> "You are good at that."

**Notes:** The support member is helping a vendor arrange goods. Natural, unhurried.

**[NODE: ch5_support3_intro_02]**
`SUPPORT_MEMBER_3` — [Looks up. Warm smile.]

> "Years of practice. Before all this, I ran a stall much like this one."

**Notes:** Fragment of backstory. They had a normal life before the Church disrupted it.

**[NODE: ch5_support3_intro_03]**
`EVELYN` — [Steps closer. Looks at the goods.]

> "You left that behind to join us."

**Notes:** Not a question. An acknowledgment of sacrifice.

**[NODE: ch5_support3_intro_04]**
`SUPPORT_MEMBER_3` — [Arranges a display. Voice steady.]

> "I did not leave it behind. I am carrying it with me."

**Notes:** Their past is not abandoned. It is the reason they fight.

**[NODE: ch5_support3_intro_05]**
`EVELYN` — [Nods. Tail curling slightly.]

> "Then let us make sure there is a world to come back to."

**Notes:** The shared purpose. Not grand — practical. A world with market stalls.

**[NODE: ch5_support3_intro_06]**
`SUPPORT_MEMBER_3` — [Smiles. Hands the POV character something.]

> "Here. Take this. You will need it out there."

**Notes:** A gift — not a weapon, something practical. Food, a charm, a small comfort.

**[NODE: ch5_support3_intro_07]**
`EVELYN` — [Takes it. Genuine warmth.]

> "Thank you. I will."

**Notes:** Evelyn accepts the gift without deflection. She lets people care for her.

**AnimationPlayer Tracks**:
- `Camera`: Medium support member (0s) → approach POV character (8s) → two-shot at stall (15s) → close gift exchange (35s) → two-shot warm (42s-50s)
- `SupportMember_arrange`: Animation 0s-12s, natural, unhurried
- `Gift_exchange`: Animation at 35s-40s, small object handoff
- `Evelyn_tail_market`: Tail curls slightly at 30s, holds
- `Music_flute_percussion`: Enters at 0s, bustling, warm

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `support3_introduction_complete` → fire at 42s
- `player_input_released` → fire at 50s
- `gameplay_resume_market` → fire at 50s

**PostCutsceneAction**:
- Release player input
- Flag `support3_introduced = true`
- Enable `ch5_member3_joins` trigger
- Support member returns to market area; available for bond conversations

**Skip Rules**:
- Player can skip after node 4 (25s mark)
- Skipping sets all narrative flags as if scene completed

---

### SCENE 5: ch5_member4_intro — Support Member Introduction

**TRIGGER**: `ch5_member4_intro`
**LOCATION**: Village forge area — afternoon, heat from the fire, hammer marks on anvils
**CAMERA**: Medium on support member near the forge. Cut to POV character approaching.
**LIGHTING**: Warm forge glow, orange firelight mixing with afternoon sun
**MUSIC**: Low percussion and warm brass — steady, grounded, working energy
**DURATION**: ~50 seconds

**PreCutsceneAction**:
- Position support member near the forge, examining weapon racks
- Position POV character approaching from path
- Set forge area to active state (ambient fire sounds, metalworking props)

**[NODE: ch5_support4_intro_01]**
`EVAN` — [Approaching the forge area. Support member is inspecting weapons.]

> "Finding what you need?"

**Notes:** Evan's practical check-in. He wants everyone equipped and ready.

**[NODE: ch5_support4_intro_02]**
`SUPPORT_MEMBER_4` — [Looks up from a blade. Appraising.]

> "Good steel. Someone here knows their craft."

**Notes:** Respect for competence. This character values quality and skill.

**[NODE: ch5_support4_intro_03]**
`EVAN` — [Nods. Looks at the forge.]

> "The village takes care of its own. That includes us now."

**Notes:** "That includes us now." Evan is internalizing belonging.

**[NODE: ch5_support4_intro_04]**
`SUPPORT_MEMBER_4` — [Tests the blade's balance. Satisfied.]

> "Good. Because I intend to earn my place here."

**Notes:** Not "given" a place — "earned." This character values merit.

**[NODE: ch5_support4_intro_05]**
`EVAN` — [Direct. Sincere.]

> "You already have. You just do not know it yet."

**Notes:** Evan offers belonging without condition. He is learning to give what he needed.

**[NODE: ch5_support4_intro_06]**
`SUPPORT_MEMBER_4` — [Pauses. Then a small nod.]

> "Then I will not waste it."

**Notes:** Acceptance. Quiet, determined. The kind of promise that matters.

**AnimationPlayer Tracks**:
- `Camera`: Medium support member at forge (0s) → Evan approaching (8s) → two-shot (15s) → close blade test (28s) → two-shot (38s-50s)
- `SupportMember_inspect`: Animation 0s-15s, examining weapons, testing balance
- `Blade_test`: Animation at 25s-30s, checking weight and edge
- `Music_brass_percussion`: Enters at 0s, steady, warm

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `support4_introduction_complete` → fire at 42s
- `player_input_released` → fire at 50s
- `gameplay_resume_forge` → fire at 50s

**PostCutsceneAction**:
- Release player input
- Flag `support4_introduced = true`
- Enable `ch5_member4_joins` trigger
- Support member returns to forge area; available for bond conversations

**Skip Rules**:
- Player can skip after node 4 (25s mark)
- Skipping sets all narrative flags as if scene completed

---

### SCENE 6: ch5_evening_celebration — The Happiest Scene

**TRIGGER**: `ch5_evening_celebration`
**LOCATION**: Village square — evening, bonfire center, lanterns strung between buildings, full party
**CAMERA**: Wide celebration establishing shot. Orbit around the bonfire. Individual close-ups as each character reacts. Final wide ensemble.
**LIGHTING**: Warm bonfire orange, lantern gold, twilight blue sky. Faces lit by fire.
**MUSIC**: Full ensemble — strings, woodwinds, light percussion. Warm, joyful, the happiest theme in the game.
**DURATION**: ~90 seconds

**PreCutsceneAction**:
- Position all party members around the bonfire in a loose circle
- Spawn festival NPCs: musicians playing, children running, vendors serving food
- Set village to EVENING_CELEBRATION state
- Bonfire particle system active
- Lantern lights positioned between buildings
- Queue festival music as ambient layer

**[NODE: ch5_celebration_01]**
`EVELYN` — [Sitting by the fire. Tail fully curled — the happy thing. Ears relaxed.]

> "I cannot remember the last time it was this loud."

**Notes:** Not complaining. Celebrating. The noise is life, and life is good.

**[NODE: ch5_celebration_02]**
`EVAN` — [Sitting near her. Relaxed posture. Shoulders down. Almost smiling.]

> "Loud is good. Loud means safe."

**Notes:** Evan has learned this. Silence meant danger. Noise means the village is alive.

**[NODE: ch5_celebration_03]**
`SILAS` — [Eating something. Makes a face. Terrible pun incoming.]

> "This bread is well-kneaded. I will see myself out."

**Notes:** Silas's humor. Terrible medical/culinary pun. Deployed deliberately.

**[NODE: ch5_celebration_04]**
`EVELYN` — [Groans. But she is laughing. Tail curls tighter.]

> "That was awful. Do another one."

**Notes:** She wants more. She is enjoying this. The groan is affectionate.

**[NODE: ch5_celebration_05]**
`SILAS` — [Grinning now. Committing to the bit.]

> "I would, but I do not want to fracture the mood."

**Notes:** Another pun. He is on a roll. The party groans in unison.

**[NODE: ch5_celebration_06]**
`KAELEN` — [Sitting. Actually sitting. Not scanning. Watching the fire.]

> "We are being chased by Church knights through a festival."

**Notes:** Kaelen's dry observation.

**[NODE: ch5_celebration_07]**
`KAELEN` — [Continues. Deadpan.]

> "I have had better Tuesdays. But this is close."

**Notes:** The party laughs. Kaelen does not smile bigger, but his eyes soften.

**[NODE: ch5_celebration_08]**
`EVELYN` — [Snorts with laughter. Covers her mouth. Tail betraying everything.]

> "Kaelen. That was— oh, that was good."

**Notes:** Evelyn does not snort. She just did. Kaelen got her. This is significant.

**[NODE: ch5_celebration_09]**
`EVAN` — [Watching Evelyn laugh. Something warm in his expression.]

> "Your tail is doing that thing again."

**Notes:** Evan notices. He notices everything about her. He says it quietly.

**[NODE: ch5_celebration_10]**
`EVELYN` — [Looks at her tail. Does not try to stop it.]

> "The happy thing. I know. I am not going to hide it."

**Notes:** Evelyn stops hiding her joy. This is growth. She lets herself be happy.

**[NODE: ch5_celebration_11]**
`EVAN` — [Voice barely above the fire crackle.]

> "Good. Do not."

**Notes:** Two words. They carry everything. "Do not hide. Do not stop. I like seeing this."

**[NODE: ch5_celebration_12]**
`SILAS` — [Looking around the circle. Voice soft, sincere.]

> "I have spent a long time in hospitals. This is— this is better."

**Notes:** Silas does not say more. He does not need to. The firelight on his scarred hands.

**[NODE: ch5_celebration_13]**
`KAELEN` — [Leaning back. Shield beside him, not on his back.]

> "The perimeter is secure. The village is safe. For tonight— this is enough."

**Notes:** Kaelen gives his highest praise: the perimeter is secure and he can relax.

**[NODE: ch5_celebration_14]**
`EVELYN` — [Looking at each of them. Firelight in her eyes. Voice warm.]

> "This is what we fight for. This. Right here."

**Notes:** Not an abstract ideal. A concrete moment. This fire, these people, this laughter.

**[NODE: ch5_celebration_15]**
`EVAN` — [Meets her gaze across the fire. Nods once.]

> "Right here."

**Notes:** Echo. Agreement. Commitment. Evan is all the way in.

**AnimationPlayer Tracks**:
- `Camera`: Wide celebration (0s) → orbit bonfire (10s-30s) → individual close-ups: Evelyn (30s), Evan (38s), Silas (45s), Kaelen (52s) → two-shot Evelyn+Evan (62s) → wide ensemble (75s-90s)
- `Evelyn_tail_fully_curled`: Animation state from 0s, full curl, holds through scene
- `Evelyn_ears_relaxed`: Animation state from 0s, ears loose and back slightly
- `Evan_relaxed_posture`: Animation at 8s, shoulders down, lean back
- `Evan_almost_smile`: Subtle animation at 15s, mouth corners up, not quite a smile
- `Silas_eat_face`: Animation at 22s, eating, then face for pun at 25s
- `Evelyn_groan_laugh`: Animation at 32s, head back, hand to mouth, laughing
- `Kaelen_sitting_relaxed`: Animation at 40s, actually sitting, not rigid
- `Kaelen_eyes_soften`: Subtle animation at 55s, not a smile but warmth
- `Evelyn_snort`: Animation at 60s, sudden laugh, covers mouth, tail tightens
- `Evan_watching_Evelyn`: Gaze direction at 65s, warm expression
- `Evelyn_looks_at_tail`: Animation at 70s, glances down, does not stop it
- `Silas_firelight_hands`: Camera focus at 78s, scarred hands in firelight
- `Kaelen_shield_beside`: Shield placed on ground at 42s, not held
- `Music_full_ensemble`: Enters at 0s, warmest theme in game, swells at 30s, holds

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `celebration_ensemble_complete` → fire at 80s
- `player_input_released` → fire at 90s
- `gameplay_resume_celebration` → fire at 90s

**VFX Triggers**:
- `bonfire_particles` → large fire, orange and yellow, continuous, center of square
- `lantern_lights` → 16 point lights strung between buildings, warm gold, flickering
- `firelight_on_faces` → dynamic light on each character's face from bonfire direction
- `twilight_sky` → deep blue sky gradient, stars beginning to appear
- `spark_trail` → occasional sparks rising from bonfire, sparse, upward drift

**Audio Cues**:
- `bonfire_crackle` → continuous, -14dB, warm
- `festival_music_live` → diegetic musicians playing, -16dB, blends with score
- `crowd_celebration` → happy crowd sounds, laughter, clapping, -18dB
- `children_running` → intermittent, -24dB, feet on dirt
- `full_ensemble_warm` → score layer, warmest theme, enters at 0s, swells at 30s

**PostCutsceneAction**:
- Release player input
- Enable free roam during celebration (player can talk to party members, villagers)
- Party members remain at bonfire area with idle celebration animations
- Unlock campfire conversation sequences (triggered by approaching individual members)
- Festival vendors remain active for 15 minutes of gameplay time

**Skip Rules**:
- Player can skip after node 6 (40s mark)
- Skipping jumps to `celebration_ensemble_complete` state
- Party members are positioned at bonfire with idle animations
- Campfire conversation sequences remain available

---

### SCENE 7: ch5_campfire_bonds — Campfire Conversations

**TRIGGER**: `ch5_campfire_bonds` (triggered after player explores celebration for 10+ minutes)
**LOCATION**: Smaller campfires around the village — multiple locations, intimate groupings
**CAMERA**: Intimate two-shots. Close framing. The camera stays tight on faces and hands.
**LIGHTING**: Small fire glow, dark surroundings, intimate warm light on faces only
**MUSIC**: Different instrument per conversation — piano for Silas, strings for Kaelen, woodwinds for support members
**DURATION**: ~40 seconds per conversation (player chooses which to experience)

**PreCutsceneAction**:
- Player approaches a party member at a smaller campfire
- Position camera for intimate two-shot
- Set localized fire lighting
- Queue appropriate instrumental track

#### Campfire A: Evelyn and Silas

**[NODE: ch5_campfire_silas_01]**
`SILAS` — [Small fire. Cleaning his tools. Habit.]

> "I always do this when I am content. It looks like worry."

**Notes:** Self-aware. He knows his coping mechanism looks like anxiety.

**[NODE: ch5_campfire_silas_02]**
`EVELYN` — [Sitting across from him. Tail loosely curled.]

> "It is not worry?"

**Notes:** She is asking, not assuming. She wants to understand him.

**[NODE: ch5_campfire_silas_03]**
`SILAS` — [Sets down a scalpel. Looks at the fire.]

> "No. It is— gratitude. My hands need to do something with it."

**Notes:** Beautiful. Silas metabolizes joy the same way he metabolizes grief: through work.

**[NODE: ch5_campfire_silas_04]**
`EVELYN` — [Quiet. Understanding.]

> "I understand that."

**Notes:** She does. She helps villagers for the same reason. Action as gratitude.

**[NODE: ch5_campfire_silas_05]**
`SILAS` — [Looks at her. Voice drops to barely above a whisper.]

> "Thank you. For letting me be part of this."

**Notes:** Silas rarely says thank you for belonging. It means everything.

**[NODE: ch5_campfire_silas_06]**
`EVELYN` — [Warm. Direct.]

> "Thank you for being here, Silas."

**Notes:** She uses his name. The same warmth she says everything important with.

#### Campfire B: Evan and Kaelen

**[NODE: ch5_campfire_kaelen_01]**
`KAELEN` — [Small fire. Shield beside him. Not cleaning it. Just sitting.]

> "I am not checking the perimeter. I want to be clear about that."

**Notes:** Kaelen volunteering that he is resting. This is growth.

**[NODE: ch5_campfire_kaelen_02]**
`EVAN` — [Sitting. Relaxed. Small fire between them.]

> "Noted. I am not checking my detector either."

**Notes:** Evan matching Kaelen's vulnerability with his own. Parallel growth.

**[NODE: ch5_campfire_kaelen_03]**
`KAELEN` — [Looks at the fire. Quiet.]

> "Twelve years I held a line. Tonight I chose where to stand."

**Notes:** The core of Kaelen's arc. Choice. Agency. The first time in twelve years.

**[NODE: ch5_campfire_kaelen_04]**
`EVAN` — [Nods. Voice quiet.]

> "I know what that feels like."

**Notes:** Evan does. He left his insignia on his desk. He chose too.

**[NODE: ch5_campfire_kaelen_05]**
`KAELEN` — [Looks at Evan. Respect.]

> "Then we understand each other. That is enough."

**Notes:** Two soldiers who chose a new side. No speeches needed.

#### Campfire C: Evelyn and Support Members

**[NODE: ch5_campfire_support_01]**
`SUPPORT_MEMBER_3` — [Small fire. Looking at the stars.]

> "I forgot what the sky looks like without smoke."

**Notes:** Fragment of loss. The Church disrupted their life. This is the first peace.

**[NODE: ch5_campfire_support_02]**
`EVELYN` — [Looking up too. Ears catching starlight.]

> "It is pretty. It looks like— like it did before."

**Notes:** Before everything changed. Before the curse. Before the Church.

**[NODE: ch5_campfire_support_03]**
`SUPPORT_MEMBER_4` — [Joining them. Voice warm.]

> "It looks like tomorrow. That is what I see."

**Notes:** Forward-looking. Hopeful. The future is worth fighting for.

**[NODE: ch5_campfire_support_04]**
`EVELYN` — [Smiles. Tail curling.]

> "Tomorrow. I like that."

**Notes:** Evelyn likes the future. She has not always been able to say that.

**AnimationPlayer Tracks** (per conversation):
- `Camera`: Intimate two-shot (0s) → close face A (12s) → close face B (22s) → two-shot (32s-40s)
- `Small_fire`: Particle system, orange, intimate scale, continuous
- `Character_idle`: Breathing, slight movement, natural
- `Music_per_conversation`: Solo instrument, warm, enters at 0s, resolves at 38s

**Signal Timings** (per conversation):
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `campfire_conversation_complete` → fire at 35s
- `player_input_released` → fire at 40s

**VFX Triggers** (per conversation):
- `small_fire_particles` → intimate scale, orange glow on faces only
- `surrounding_darkness` → vignette outside firelight, dark beyond faces
- `firelight_intimate` → point light at fire, warm, face-limited range

**Audio Cues** (per conversation):
- `small_fire_crackle` → quieter than bonfire, -18dB
- `distant_celebration` → muffled main festival, -28dB
- `solo_instrument` → piano/strings/woodwinds per conversation, warm, sparse

**PostCutsceneAction**:
- Release player input
- Set bond flag for the party member whose conversation was experienced
- Player can approach remaining campfires for additional conversations
- Each conversation can only be experienced once per chapter

**Skip Rules**:
- Each conversation can be skipped after node 3 (20s mark)
- Skipping sets the bond flag and releases input

---

### SCENE 8: ch5_raid_approach — Morning Assembly

**TRIGGER**: `ch5_raid_approach`
**LOCATION**: Village entrance — early morning, mist, the party assembled and ready
**CAMERA**: Wide assembly shot. Individual close-ups as each member confirms readiness. Push in on Evelyn.
**LIGHTING**: Early morning mist, pale gold light, cool shadows
**MUSIC**: Building strings — purpose, not fear. Determination without dread.
**DURATION**: ~70 seconds

**PreCutsceneAction**:
- Position all party members at village entrance in formation
- Set village to QUIET_MORNING state (festival decorations still up, no NPCs active)
- Equip party members with raid-ready gear (visual change)
- Mist particle system active across the approach path

**[NODE: ch5_raid_approach_01]**
`EVAN` — [Briefing the party. Detector holstered. Tactical posture.]

> "Church Tier 2 facility. Three kilometers north. Standard layout."

**Notes:** Evan the tactician. But his voice is warmer than it was in Chapter 1.

**[NODE: ch5_raid_approach_02]**
`EVAN` — [Continues. Looking at each person.]

> "They are expanding. We hit them before the expansion completes."

**Notes:** "We." Not "I." Evan leads as part of the team.

**[NODE: ch5_raid_approach_03]**
`KAELEN` — [Shield on his back. Posture ready but calm.]

> "I will hold the entry corridor. No one gets past me."

**Notes:** Kaelen's promise. Simple, absolute. He is the wall.

**[NODE: ch5_raid_approach_04]**
`SILAS` — [Satchel packed. Vials organized. Voice steady.]

> "I have extra bandages. Everyone check your kit before we move."

**Notes:** Silas the caretaker. He fusses because he cares.

**[NODE: ch5_raid_approach_05]**
`SUPPORT_MEMBER_3` — [Nods. Checking their gear.]

> "Ready. Let us finish this."

**Notes:** Determined. The support members are not bystanders — they are fighters.

**[NODE: ch5_raid_approach_06]**
`SUPPORT_MEMBER_4` — [Weapon ready. Voice calm.]

> "Ready. I trust this team."

**Notes:** Trust. The most important word in this chapter.

**[NODE: ch5_raid_approach_07]**
`EVELYN` — [Looking at each of them. Tail loosely curled — not fear, purpose.]

> "We go in together. We come out together. That is the plan."

**Notes:** Not a complex plan. A commitment. Together in, together out.

**[NODE: ch5_raid_approach_08]**
`EVAN` — [Meets her eyes. Nods.]

> "Together. Always."

**Notes:** "Always." The word carries weight. It is a promise.

**[NODE: ch5_raid_approach_09]**
`EVELYN` — [Steps forward. The mist parts around her.]

> "Then let us move."

**Notes:** Evelyn leads. Not because she commands — because the party follows willingly.

**[NODE: ch5_raid_approach_10]**
`KAELEN` — [Falls in behind her. Shield ready.]

> "I have point on defense. Evelyn, you have point on offense."

**Notes:** The division of labor. Natural, earned, mutually respected.

**[NODE: ch5_raid_approach_11]**
`SILAS` — [In the middle. Voice warm.]

> "I have the middle. Stay close to me if you get hurt."

**Notes:** Silas positions himself where he can reach everyone. Always the center.

**[NODE: ch5_raid_approach_12]**
`EVAN` — [At the rear. Scanner active. Voice calm.]

> "Rear is clear. I will track our six."

**Notes:** Evan at the back. The hunter became the protector. Full circle.

**AnimationPlayer Tracks**:
- `Camera`: Wide assembly (0s) → Evan briefing (8s) → individual close-ups: Kaelen (18s), Silas (26s), Support3 (34s), Support4 (40s), Evelyn (46s), Evan (54s) → formation movement (58s-70s)
- `Mist_particles`: Continuous, pale, across approach path
- `Evelyn_tail_purpose`: Tail loosely curled at 46s, holds — purpose not fear
- `Kaelen_shield_ready`: Shield on back, posture calm but ready at 18s
- `Silas_satchel_check`: Animation at 26s, checking vials and bandages
- `Party_formation_walk`: Walking animation from 58s, formation: Kaelen front, Evelyn center, Silas middle, Support3-4 flanks, Evan rear
- `Music_building_strings`: Enters at 0s, purpose, builds at 46s, holds determination

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `raid_approach_complete` → fire at 60s
- `raid_zone_entered` → fire at 65s (transition to raid area)
- `player_input_released` → fire at 70s (raid gameplay begins)

**VFX Triggers**:
- `morning_mist` → particle system, pale, low ground, entire approach path
- `pale_gold_light` → directional light, early morning tone, cool shadows
- `gear_equipped` → visual change on all party members (raid-ready gear)

**Audio Cues**:
- `mist_quiet` → muffled ambient, early morning stillness, -22dB
- `footstep_misty_path` → damp path, softer than normal, -14dB
- `gear_clink` → weapons and armor settling, intermittent, -20dB
- `strings_purpose` → building strings, determination, enters at 0s, builds at 46s

**PostCutsceneAction**:
- Transition player to raid zone
- Enable raid combat gameplay
- Party AI set to raid formation behavior
- First raid encounter triggers after 30 seconds of approach movement

**Skip Rules**:
- Player can skip after node 6 (35s mark)
- Skipping jumps to raid zone entry with party in formation

---

### SCENE 9: ch5_raid_victory — The Facility Falls

**TRIGGER**: `ch5_raid_victory`
**LOCATION**: Church Tier 2 facility interior — final room, commander defeated, evidence scattered
**CAMERA**: Wide room shot. Party spread out, catching breath. Push in on Evelyn finding the evidence. Final wide ensemble.
**LIGHTING**: Damaged facility lighting — sparks, emergency lights, dust in the air
**MUSIC**: Resolving strings — warm victory, not triumphant. Relief and togetherness.
**DURATION**: ~75 seconds

**PreCutsceneAction**:
- Spawn defeated commander (non-critical, unconscious or fled)
- Scatter evidence documents across the final room
- Set facility to DAMAGED state (sparks, emergency lighting, debris)
- Position party members in post-combat stances

**[NODE: ch5_raid_victory_01]**
`EVELYN` — [Standing among the wreckage. Breathing. Alive.]

> "Everyone still standing?"

**Notes:** First priority. Her people. Not the facility. Not the evidence. Her people.

**[NODE: ch5_raid_victory_02]**
`KAELEN` — [Shield raised but posture relaxed. Nods.]

> "All clear on my side. The entry held."

**Notes:** Kaelen held the line. As promised. The shield did not break.

**[NODE: ch5_raid_victory_03]**
`SILAS` — [Already moving among the party. Checking.]

> "Minor wounds. Nothing serious. Evelyn, your left arm— let me see."

**Notes:** Silas is already healing. He cannot stop. It is who he is.

**[NODE: ch5_raid_victory_04]**
`EVELYN` — [Extends her arm. Lets him work. Tail loose.]

> "It is fine, Silas. Really."

**Notes:** Evelyn trying to deflect. Silas will not let her.

**[NODE: ch5_raid_victory_05]**
`SILAS` — [Already bandaging. Not looking up.]

> "I know it is fine. I am bandaging it anyway. Humor me."

**Notes:** Silas's gentle insistence. He cares. He shows it through action.

**[NODE: ch5_raid_victory_06]**
`EVAN` — [Across the room. Looking at documents. Voice focused.]

> "Evelyn. You need to see this."

**Notes:** The evidence. The reason they came. Evan's tone shifts to discovery.

**[NODE: ch5_raid_victory_07]**
`EVELYN` — [Crosses to him. Silas finishes the bandage.]

> "What is it?"

**Notes:** Evelyn shifts from patient to leader. Seamless transition.

**[NODE: ch5_raid_victory_08]**
`EVAN` — [Holding a document. Reading. Voice grim but steady.]

> "They are expanding. More facilities. More experiments. But— we stopped this one."

**Notes:** The threat is growing. But they stopped this one. That matters.

**[NODE: ch5_raid_victory_09]**
`EVELYN` — [Looks at the document. Then at the party.]

> "We stopped this one. Together."

**Notes:** The emphasis. Not "I stopped it." "We stopped it." The party matters.

**[NODE: ch5_raid_victory_10]**
`KAELEN` — [Lowering his shield. Shoulders dropping.]

> "Together. That is the part they did not expect."

**Notes:** Kaelen's dry truth. The Church expects individuals. They face a team.

**[NODE: ch5_raid_victory_11]**
`SILAS` — [Packing his supplies. Voice warm.]

> "I told you to stay out of trouble. You all failed magnificently."

**Notes:** Silas's humor in victory. The tension breaks. The party groans-laugh.

**[NODE: ch5_raid_victory_12]**
`EVELYN` — [Smiling. Tail curling — the happy thing, even here.]

> "We make a good team."

**Notes:** Not a question. A statement. The warmest truth in the chapter.

**[NODE: ch5_raid_victory_13]**
`EVAN` — [Looking at her. At the party. Voice quiet, certain.]

> "The best."

**Notes:** Two words. Full conviction. Evan means it with everything he has.

**AnimationPlayer Tracks**:
- `Camera`: Wide room (0s) → individual checks: Kaelen (10s), Silas (18s), Evelyn (26s), Evan (38s) → evidence moment (45s) → ensemble (55s-75s)
- `Silas_bandage`: Animation at 22s-30s, gentle, efficient
- `Evelyn_arm_extend`: Animation at 24s, accepts Silas's care
- `Evan_document`: Animation at 38s, reading, grim but steady
- `Evelyn_cross_room`: Animation at 32s-38s, moving from Silas to Evan
- `Kaelen_lower_shield`: Animation at 52s, shield lowers, shoulders drop
- `Evelyn_tail_victory`: Tail curls at 60s, happy even in damaged facility
- `Evan_looking_at_party`: Gaze direction at 65s, warm, taking it in
- `Music_resolving_strings`: Enters at 0s, warm resolution, swells at 55s, holds

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `raid_victory_complete` → fire at 65s
- `evidence_collected_flag` → fire at 50s
- `player_input_released` → fire at 75s
- `return_to_village` → fire at 75s (transition back)

**VFX Triggers**:
- `facility_sparks` → intermittent sparks from damaged equipment, 2-3s intervals
- `emergency_lights` → red flickering lights, damaged state
- `dust_debris` → floating dust particles, disturbed by combat
- `document_glow` → subtle highlight on evidence document at 45s

**Audio Cues**:
- `facility_damage_ambient` → sparking, creaking, damaged building sounds, -20dB
- `heavy_breathing` → party catching breath, settling, -16dB
- `bandage_rustle` → Silas working, -18dB, 22s-30s
- `document_handling` → paper rustling, -18dB, 38s-50s
- `strings_warm_victory` → resolving strings, warm, enters at 0s, swells at 55s

**PostCutsceneAction**:
- Release player input
- Flag `raid_victory = true`
- Flag `evidence_collected = true`
- Transition party back to village
- Set village to POST_RAID state (quiet, evening approaching)
- Unlock chapter close sequence

**Skip Rules**:
- Player can skip after node 6 (35s mark)
- Skipping jumps to `raid_victory_complete` state with all flags set

---

### SCENE 10: ch5_chapter_close — Too Good to Last

**TRIGGER**: `ch5_chapter_close`
**LOCATION**: Village edge — night, quiet streets, moonlight, the festival decorations still up
**CAMERA**: Wide on Evelyn alone. Slow push in. Evan enters frame. Two-shot. Slow pull back to wide.
**LIGHTING**: Moonlight silver, faint festival lantern glow, long shadows
**MUSIC**: Solo piano — warm but with a minor undertone. The faintest shadow.
**DURATION**: ~60 seconds

**PreCutsceneAction**:
- Set village to QUIET_NIGHT state (NPCs sleeping, lanterns dimmed)
- Position Evelyn at village edge, looking out over the sleeping village
- Position Evan to enter from village center after 15 seconds
- Moonlight and dim lantern lighting active
- Festival decorations visible but inactive

**[NODE: ch5_close_01]**
`EVELYN` — [Alone at the village edge. Moonlight. Tail loosely curled.]

> "It is quiet now. The good kind of quiet."

**Notes:** Not the quiet of danger. The quiet of a village that is safe and sleeping.

**[NODE: ch5_close_02]**
`EVELYN` — [Continues. Voice barely above a whisper.]

> "I used to listen for monsters. Now I listen for— nothing."

**Notes:** The absence of threat is so new she is still learning to trust it.

**[NODE: ch5_close_03]**
`EVELYN` — [A small smile.]

> "Nothing is my favorite sound."

**Notes:** Humor. But tender. The kind of humor that is really gratitude.

**[NODE: ch5_close_04]**
`EVAN` — [Approaching. Footsteps quiet. Stops beside her.]

> "I could not sleep either."

**Notes:** He does not say why. He does not need to. She is why.

**[NODE: ch5_close_05]**
`EVELYN` — [Does not look at him. Tail curls a little more.]

> "Too much happiness. It takes getting used to."

**Notes:** She names it. Happiness. She does not deflect or minimize it.

**[NODE: ch5_close_06]**
`EVAN` — [Looking at the sleeping village. Voice warm.]

> "I have spent my life listening for danger. Silence feels— strange."

**Notes:** Parallel confession. Both are learning to trust peace.

**[NODE: ch5_close_07]**
`EVELYN` — [Finally looks at him. Moonlight on her face.]

> "We will learn. Together."

**Notes:** The chapter's thesis. Together. In everything.

**[NODE: ch5_close_08]**
`EVAN` — [Meets her gaze. Holds it.]

> "Together."

**Notes:** The echo. The promise. The word that defines this chapter.

**[NODE: ch5_close_09]**
`EVELYN` — [Looks back at the village. Voice very soft.]

> "This— all of this. I want to keep it."

**Notes:** Not "I will keep it." "I want to." The wanting is honest and vulnerable.

**[NODE: ch5_close_10]**
`EVAN` — [Quiet. Certain.]

> "We will. I will help you."

**Notes:** Not a promise he can guarantee. A commitment he will honor.

**[NODE: ch5_close_11]**
`EVELYN` — [A beat. The faintest shadow crosses her face.]

> "I hope it lasts."

**Notes:** The undertone. She does not know what is coming. The player should feel it.

**[NODE: ch5_close_12]**
`EVAN` — [Does not notice the shadow. Or pretends not to. Voice steady.]

> "It will. We will make it last."

**Notes:** Evan's certainty. Earned but fragile. The player knows it will be tested.

**[NODE: ch5_close_13]**
`EVELYN` — [Nods. Tail curling. The happy thing. But quieter now.]

> "Goodnight, Evan."

**Notes:** Warm. Tender. The kind of goodnight that carries weight.

**[NODE: ch5_close_14]**
`EVAN` — [Voice barely audible.]

> "Goodnight, Evelyn."

**Notes:** Two names. Warmth. The camera pulls back. Moonlight. Two people who chose each other.

**AnimationPlayer Tracks**:
- `Camera`: Wide Evelyn alone (0s) → slow push-in (10s) → Evan enters frame (15s) → two-shot (20s) → slow pull back to wide (45s-60s)
- `Evelyn_tail_loose_curled`: Animation state from 0s, loose curl, tightens slightly at nodes 5 and 13
- `Evan_approach`: Walking animation at 12s-18s, quiet footsteps
- `Evelyn_look_at_Evan`: Head turn at 32s, moonlight on face
- `Evelyn_shadow`: Subtle expression change at 52s, brief shadow, then returns to warm
- `Evan_notices_or_not`: No reaction to shadow at 53s — ambiguous whether he sees it
- `Moonlight`: Directional light, silver-blue, continuous
- `Music_solo_piano`: Enters at 0s, warm with minor undertone, resolves at 55s

**Signal Timings**:
- `cutscene_started` → fire at 0s
- `player_input_blocked` → fire at 0s
- `chapter_close_complete` → fire at 55s
- `chapter5_complete_flag` → fire at 55s
- `player_input_released` → fire at 60s
- `chapter_transition` → fire at 60s (fade to black, chapter end)

**VFX Triggers**:
- `moonlight_silver` → directional light, cool blue-silver, entire scene
- `dim_lantern_glow` → point lights, warm gold, dimmed, village perimeter
- `long_shadows` → moonlight creates long shadows from buildings and trees
- `festival_decorations` → visible but inactive, reminder of earlier warmth

**Audio Cues**:
- `village_night` → sleeping village, very quiet, -28dB
- `distant_owl` → single owl call, every 12s, -26dB
- `gentle_wind` → soft breeze through trees, -24dB
- `footstep_soft_grass` → quiet footsteps, -18dB, Evan's approach
- `piano_warm_minor` → solo piano, warm with minor undertone, enters at 0s

**PostCutsceneAction**:
- Fade to black
- Display "Chapter 5 Complete" screen
- Save game state
- Unlock Chapter 6

**Skip Rules**:
- Player can skip after node 6 (30s mark)
- Skipping jumps to `chapter_close_complete` state
- All chapter completion flags are set

---

## 5. Dialogue Sequences

### SEQUENCE: ch5_party_assembly — The First Full Party Gathering

This sequence happens after all four member introductions are complete. The full party gathers in the village square for the first time as a complete team. It is warm, slightly awkward, and deeply human.

**Setting:** Village square. Midday. The festival is ongoing in the background. The party stands in a loose circle.

**Emotional Arc:** Slight awkwardness → growing warmth → shared purpose.

---

**[ch5_assembly_01]** `EVELYN` — [Village square, looking at the full group. Tail curling.]

> "We are all here. All of us. Together."

**Notes:** Evelyn taking in the full party. This is new for her — having a team.

**[ch5_assembly_02]** `EVAN` — [Standing beside her. More relaxed than he has ever been.]

> "It is unusual, is it not? A group like this."

**Notes:** Evan processing the novelty. Church units are assigned. This is chosen.

**[ch5_assembly_03]** `EVELYN` — [Grins. Ears forward.]

> "Unusual is good. Unusual means we built it ourselves."

**Notes:** Evelyn reframing the unusual as positive. This is her gift.

**[ch5_assembly_04]** `SILAS` — [Looking at the group. Voice warm.]

> "I have worked in teams before. None of them felt like this."

**Notes:** Silas acknowledges the difference. Church hospital teams were functional. This is personal.

**[ch5_assembly_05]** `KAELEN` — [Shield on his back. Hands loose. Not scanning.]

> "I spent twelve years in units where no one asked my opinion."

**Notes:** Kaelen's vulnerability. He is sharing something real with the group.

**[ch5_assembly_06]** `KAELEN` — [Continues. Looking at each person.]

> "You ask. That is— that matters more than you know."

**Notes:** Kaelen does not say "thank you." He says what the thing is worth.

**[ch5_assembly_07]** `SUPPORT_MEMBER_3` — [Smiling. Relaxed posture.]

> "I ran a market stall. This is a change of pace."

**Notes:** Light humor. The support members add levity to the group dynamic.

**[ch5_assembly_08]** `SUPPORT_MEMBER_4` — [Nods. Weapon at rest.]

> "Good change. I prefer this to working alone."

**Notes:** Direct. Honest. The support members are choosing this too.

**[ch5_assembly_09]** `EVELYN` — [Looking at each of them. Tail fully curled.]

> "Then we keep doing this. Together. Whatever comes."

**Notes:** The commitment. Not to a mission — to each other.

**[ch5_assembly_10]** `EVAN` — [Quiet. Sincere.]

> "Whatever comes."

**Notes:** Echo. Agreement. Evan is fully committed.

**[ch5_assembly_11]** `SILAS` — [Dry. Warm.]

> "Just— try not to need me too much. I have limited bandages."

**Notes:** Silas humor. The tension breaks. The group laughs.

**[ch5_assembly_12]** `KAELEN` — [Deadpan.]

> "I make no promises."

**Notes:** Kaelen knows he will need Silas. He always does. The group laughs harder.

**[ch5_assembly_13]** `EVELYN` — [Laughing. Tail betraying everything.]

> "This is it. This is the team. I am keeping you all."

**Notes:** Evelyn at her most joyful. She has found her people. She is not letting go.

---

### SEQUENCE: ch5_silas_bond — The Healer's Hands

Evan finds Silas in the clinic after the introduction scene. This is a deeper bond sequence that reveals more of Silas's past and his relationship with healing.

**Setting:** Clinic interior. Afternoon light through windows. Silas is organizing supplies but clearly waiting.

**Emotional Arc:** Professional warmth → vulnerability → shared understanding.

---

**[ch5_silas_bond_01]** `EVAN` — [Clinic doorway. Afternoon light.]

> "You have been here since morning."

**Notes:** Observation. Evan notices patterns. Silas has not left the clinic.

**[ch5_silas_bond_02]** `SILAS` — [Not looking up. Sorting vials.]

> "People need treating. I am treating them."

**Notes:** Deflection through purpose. Silas's default mode.

**[ch5_silas_bond_03]** `EVAN` — [Steps inside. Leans on the doorframe.]

> "You treat everyone who walks through that door."

**Notes:** Not a question. Evan has been watching. He sees Silas's radical equality.

**[ch5_silas_bond_04]** `SILAS` — [Pauses. Sets down a vial.]

> "Everyone who walks through. Or is carried through."

**Notes:** Silas's dark humor. It is not really humor. It is memory.

**[ch5_silas_bond_05]** `EVAN` — [Quiet. Processing.]

> "At the Church hospital— you treated everyone. Even defectors."

**Notes:** Evan knows this from the escape. Silas treated him without question.

**[ch5_silas_bond_06]** `SILAS` — [Voice gets softer. Medical vocabulary.]

> "A wound is a wound. The person who has it— they just need help."

**Notes:** Silas's philosophy. No moral judgment. Just pulse and breath and need.

**[ch5_silas_bond_07]** `EVAN` — [Looking at Silas's scarred hands.]

> "Your hands have seen a lot of work."

**Notes:** Evan notices details. The scarred hands tell a story.

**[ch5_silas_bond_08]** `SILAS` — [Looks at his own hands. Quiet.]

> "Burns, blade slips, chemical stains. Thirty years of leaning over people."

**Notes:** The biography of his hands. Each scar is a patient.

**[ch5_silas_bond_09]** `EVAN` — [Voice barely above a whisper.]

> "How many did you lose?"

**Notes:** The question no one asks Silas. Everyone assumes he is used to it.

**[ch5_silas_bond_10]** `SILAS` — [Long pause. The longest pause in the chapter.]

> "Too many to count. But I remember their names."

**Notes:** Silas remembers. He carries the names. The weight is real.

**[ch5_silas_bond_11]** `EVAN` — [Nods. No platitudes. Just presence.]

> "That matters. Remembering them matters."

**Notes:** Evan gives Silas what he needs: acknowledgment that his grief is valid.

**[ch5_silas_bond_12]** `SILAS` — [Voice drops to barely a whisper.]

> "I had a daughter. Maren. She was twelve."

**Notes:** The first time Silas says her name in this chapter. It lands like stone on water.

**[ch5_silas_bond_13]** `EVAN` — [Does not move. Does not interrupt.]

> "I am listening."

**Notes:** Evan holds the space. He does not fill it. This is how you honor grief.

**[ch5_silas_bond_14]** `SILAS` — [Looks at the window. Afternoon light on his face.]

> "I will tell you about her. Not today. But soon."

**Notes:** Silas is not ready yet. But he will be. The promise is enough.

**[ch5_silas_bond_15]** `EVAN` — [Nods. Warm. Certain.]

> "I will be here when you are ready."

**Notes:** The signature Evan line, adapted. "I will be here." Presence as commitment.

**[ch5_silas_bond_16]** `SILAS` — [Small smile. Returns to sorting vials. Voice lighter.]

> "Good. Now— tell the others to stop tracking mud in my clinic."

**Notes:** Silas deflects with humor. The heaviness lifts. But the moment was real.

---

### SEQUENCE: ch5_kaelen_bond — The Shield's Weight

Evelyn finds Kaelen at the forge, inspecting the village's defensive preparations. This sequence reveals Kaelen's regret and his need for redemption.

**Setting:** Forge area. Late afternoon. Heat from the fire. Kaelen is examining a shield rack.

**Emotional Arc:** Tactical discussion → personal revelation → quiet resolve.

---

**[ch5_kaelen_bond_01]** `EVELYN` — [Forge area. Watching Kaelen inspect shields.]

> "You are critiquing the village's defenses."

**Notes:** Not a question. Statement. Kaelen cannot not assess defenses.

**[ch5_kaelen_bond_02]** `KAELEN` — [Without looking up. Tactical.]

> "Their wall line is strong. The gate reinforcement is amateur but functional."

**Notes:** Kaelen gives honest assessment. Not cruel, not flattering. Precise.

**[ch5_kaelen_bond_03]** `EVELYN` — [Steps closer. Tail loose.]

> "You would do it differently."

**Notes:** She knows he would. She is asking him to share his knowledge.

**[ch5_kaelen_bond_04]** `KAELEN` — [Finally looks at her. Direct.]

> "Yes. But I will not. These are their walls. They built them with their hands."

**Notes:** Kaelen respects what people build. He will not overwrite their effort.

**[ch5_kaelen_bond_05]** `EVELYN` — [Nods. Impressed.]

> "That is surprisingly gentle."

**Notes:** Evelyn is genuinely surprised. Kaelen's tactical mind has compassion.

**[ch5_kaelen_bond_06]** `KAELEN` — [Looks back at the shield rack. Quieter.]

> "I spent twelve years telling people how to stand. I want to listen now."

**Notes:** The core of Kaelen's growth. From commander to partner. From orders to choice.

**[ch5_kaelen_bond_07]** `EVELYN` — [Soft. Understanding.]

> "You are listening. That is why I asked."

**Notes:** Evelyn gives Kaelen what he needs: her trust, her willingness to learn.

**[ch5_kaelen_bond_08]** `KAELEN` — [Touches a shield on the rack. Not his. A village one.]

> "In the Church, I held the line for twelve years. I never chose where."

**Notes:** The regret. Not dramatic. Quiet. True.

**[ch5_kaelen_bond_09]** `EVELYN` — [Voice gentle but not pitying.]

> "You choose now. Every day you stand with us, you choose."

**Notes:** Evelyn reframes Kaelen's past. Not wasted — the foundation for his choice now.

**[ch5_kaelen_bond_10]** `KAELEN` — [Looks at her. The smallest smile.]

> "Yes. I do. And I will keep choosing. Until I get it right."

**Notes:** Kaelen's commitment. Not to perfection. To the effort. The choosing.

**[ch5_kaelen_bond_11]** `EVELYN` — [Tail curling. Warm.]

> "You already are getting it right."

**Notes:** Evelyn affirms him. Not his past — his present. The now.

**[ch5_kaelen_bond_12]** `KAELEN` — [Picks up the village shield. Tests its weight.]

> "This shield is too light. The bearer will tire before the fight ends."

**Notes:** Kaelen returns to tactics. But his voice is warmer. The bond deepened.

**[ch5_kaelen_bond_13]** `EVELYN` — [Grinning.]

> "So fix it. You know how."

**Notes:** Evelyn gives him agency. He can improve things. He is allowed to help.

**[ch5_kaelen_bond_14]** `KAELEN` — [Almost smiles.]

> "I suppose I can. Stand back. This will involve fire."

**Notes:** Kaelen at the forge. The shield-becomes-teacher moment. He is in his element.

---

### SEQUENCE: ch5_evelyn_evan — The Space Between

A quiet moment between Evelyn and Evan during the village celebration. They step away from the main fire and talk.

**Setting:** Village edge, away from the main celebration. Evening light, warm, lantern glow from a distance.

**Emotional Arc:** Playful → tender → unspoken understanding.

---

**[ch5_evelyn_evan_01]** `EVELYN` — [Walking away from the fire. Lantern glow behind them.]

> "Your face is doing that thing. The thinking thing."

**Notes:** Evelyn mirrors Evan's earlier observation about her tail. Playful reciprocity.

**[ch5_evelyn_evan_02]** `EVAN` — [Touching his face. Almost smiling.]

> "Is it? I was just— taking it in."

**Notes:** Evan processing happiness. It is unfamiliar and he is being honest about that.

**[ch5_evelyn_evan_03]** `EVELYN` — [Stops walking. Looks at him.]

> "The village? The party? Or—?"

**Notes:** She leaves the question open. She is giving him space to answer.

**[ch5_evelyn_evan_04]** `EVAN` — [Looks at her. Holds the gaze.]

> "This. All of it. You. I was not built for this."

**Notes:** Vulnerability. Evan admitting that happiness is foreign to him.

**[ch5_evelyn_evan_05]** `EVELYN` — [Soft. Tail curling.]

> "Neither was I. But here we are. Building it."

**Notes:** Shared experience. Both learning to be happy. Together.

**[ch5_evelyn_evan_06]** `EVAN` — [Voice quiet. Sincere.]

> "You make it easy. Being here. With them. With you."

**Notes:** Evan's most direct expression of feeling. "You make it easy." That is everything.

**[ch5_evelyn_evan_07]** `EVELYN` — [Does not deflect. Does not hide. Tail fully curled.]

> "You make it easier."

**Notes:** Evelyn receives his honesty and returns it. No deflection. No humor. Just truth.

**[ch5_evelyn_evan_08]** `EVAN` — [A beat. The lantern glow on his face.]

> "Evelyn— thank you. For not giving up on me."

**Notes:** Evan says thank you. He does not do this often. It matters.

**[ch5_evelyn_evan_09]** `EVELYN` — [Warm. Direct.]

> "I never would. Not after you chose to see me."

**Notes:** The pivotal moment. When Evan saw her as a person, not a monster. Everything started there.

**[ch5_evelyn_evan_10]** `EVAN` — [Nods. Voice barely audible.]

> "I see you. I always will."

**Notes:** The promise. Not "I see you now." "I always will." Future tense. Permanent.

**[ch5_evelyn_evan_11]** `EVELYN` — [Smiles. The happiest she has been in the game.]

> "Good. Then let us go back to the fire. They will wonder where we are."

**Notes:** Evelyn brings them back to the party. Not hiding, not deflecting — returning to the people they love.

**[ch5_evelyn_evan_12]** `EVAN` — [Nods. They turn back together.]

> "Let them wonder. For one more minute."

**Notes:** Evan asks for one more minute. Just the two of them. The lantern glow. The warmth.

---

### SEQUENCE: ch5_raid_debrief — After the Battle

Post-raid conversation as the party walks back to the village. The adrenaline is fading. Warmth replaces it.

**Setting:** Forest path back to village. Late afternoon. Golden light filtering through trees.

**Emotional Arc:** Adrenaline → relief → warm camaraderie.

---

**[ch5_raid_debrief_01]** `SILAS` — [Walking. Already fussing over a bandage on his own arm.]

> "I told all of you to stay close. Did anyone listen? No."

**Notes:** Silas's post-combat fussing. He scolds because he cares.

**[ch5_raid_debrief_02]** `EVELYN` — [Walking ahead. Glancing back. Tail loose.]

> "We won, Silas. That counts for something."

**Notes:** Evelyn deflects with results. Silas is not satisfied with results alone.

**[ch5_raid_debrief_03]** `SILAS` — [Not looking up from the bandage.]

> "Winning is not the same as not getting hurt. I prefer the second one."

**Notes:** Silas's priority: no injuries. Victory is secondary.

**[ch5_raid_debrief_04]** `KAELEN` — [Walking rear guard. Shield down but ready.]

> "The entry held. No one got past me. That was the agreement."

**Notes:** Kaelen reporting. He kept his promise. He expects acknowledgment.

**[ch5_raid_debrief_05]** `EVELYN` — [Looking back at Kaelen. Warm.]

> "You held the line. I saw. It was— it was good."

**Notes:** Evelyn gives Kaelen the acknowledgment he earned. "It was good" from her means everything.

**[ch5_raid_debrief_06]** `KAELEN` — [Smallest nod. Not quite a smile.]

> "Thank you. That means something coming from you."

**Notes:** Kaelen values Evelyn's judgment. Her opinion of his combat matters.

**[ch5_raid_debrief_07]** `EVAN` — [Walking point now. Scanner holstered. Relaxed posture.]

> "The facility is neutralized. But the documents show more exist."

**Notes:** Evan reporting the strategic picture. But his voice is calm, not urgent.

**[ch5_raid_debrief_08]** `SUPPORT_MEMBER_3` — [Walking beside Support 4. Voice steady.]

> "Then we hit them too. One at a time. Together."

**Notes:** The support members are committed. "Together" is the key word.

**[ch5_raid_debrief_09]** `EVELYN` — [Looking at the party. Golden light through trees.]

> "One at a time. Together. That is the plan."

**Notes:** The same plan as the approach. Simple, absolute. Together.

**[ch5_raid_debrief_10]** `SILAS` — [Finally finishes his bandage. Looks up.]

> "Fine. But next time— everyone duck more. I ran out of bandages."

**Notes:** Silas's post-combat humor. The tension dissolves. The party laughs.

**[ch5_raid_debrief_11]** `KAELEN` — [Dry.]

> "I will add 'duck more' to my tactical repertoire."

**Notes:** Kaelen deadpan. The party laughs harder. The walk back is warm.

**[ch5_raid_debrief_12]** `EVAN` — [Looking at the village through the trees.]

> "Home. I keep saying that word. It feels— right."

**Notes:** Evan calling the village "home." He has never said that before.

**[ch5_raid_debrief_13]** `EVELYN` — [Hearing him. Tail curling. Warm.]

> "It is. For all of us."

**Notes:** Evelyn confirms it. The village is home. The party is family. Both are true.

---

### SEQUENCE: ch5_side_quest_bond — Village Side Quest Conversations

These are optional dialogue sequences triggered by completing village side quests. Each deepens a bond with a specific party member.

#### Side Quest A: Helping the Baker — Silas Bond

**[ch5_sq_baker_01]** `EVELYN` — [Village bakery. Flour everywhere. Silas is somehow helping.]

> "Silas. You are a healer, not a baker."

**Notes:** Evelyn amused. Silas has inserted himself into the baking process.

**[ch5_sq_baker_02]** `SILAS` — [Hands in dough. Flour on his coat.]

> "Dough needs kneading. Kneading is not unlike setting a bone."

**Notes:** Silas's medical metaphor applied to baking. Terrible. Charming.

**[ch5_sq_baker_03]** `EVELYN` — [Laugh.]

> "That is the worst comparison you have ever made."

**Notes:** Evelyn genuinely laughing. Silas's terrible comparisons are endearing.

**[ch5_sq_baker_04]** `SILAS` — [Grinning. Flour on his nose.]

> "I have made worse. You should have heard my splint-to-spoon comparison."

**Notes:** Silas leaning into the bit. He is having fun. This is rare and precious.

**[ch5_sq_baker_05]** `EVELYN` — [Takes a handful of dough. Begins kneading.]

> "Show me. If bones and bread are the same, I should learn."

**Notes:** Evelyn joins in. She is letting herself play. This is growth.

**[ch5_sq_baker_06]** `SILAS` — [Guiding her hands. Medical precision applied to bread.]

> "Firm but gentle. Like everything worth doing."

**Notes:** The line works as baking advice and as life philosophy. Silas means both.

---

#### Side Quest B: Patrol Routes — Kaelen Bond

**[ch5_sq_patrol_01]** `EVAN` — [Village perimeter. Kaelen has drawn a map in the dirt.]

> "You drew a map. In the dirt."

**Notes:** Evan amused. Kaelen's tactical mind cannot be turned off.

**[ch5_sq_patrol_02]** `KAELEN` — [Pointing at the map. Serious.]

> "The village has three blind spots. I have marked them."

**Notes:** Kaelen is dead serious. The dirt map is real. The blind spots are real.

**[ch5_sq_patrol_03]** `EVAN` — [Crouches to look. Tactical interest.]

> "Two of them overlap with my detector range. We can cover both."

**Notes:** Evan joins the planning. Two tactical minds working together.

**[ch5_sq_patrol_04]** `KAELEN` — [Looks at Evan. Respect.]

> "Your detector covers magical signatures. My eyes cover physical approach."

**Notes:** Kaelen identifying their complementary skills. The partnership is natural.

**[ch5_sq_patrol_05]** `EVAN` — [Nods. Standing.]

> "We share the watch. You take east and south. I take west and north."

**Notes:** Evan proposing the division. Kaelen nods approval.

**[ch5_sq_patrol_06]** `KAELEN` — [Rolls up the dirt map with his foot.]

> "Agreed. We rotate at dusk. No arguments."

**Notes:** Kaelen's compromise: shared watch, rotating schedule. Fair and practical.

**[ch5_sq_patrol_07]** `EVAN` — [Almost smiles.]

> "No arguments. That is a first for you."

**Notes:** Evan teasing Kaelen. Their banter is developing. This is good.

**[ch5_sq_patrol_08]** `KAELEN` — [Almost smiles back.]

> "Do not push your luck, Evan."

**Notes:** Kaelen uses Evan's first name. Warm. Not formal. The bond is real.

---

#### Side Quest C: Festival Preparations — Support Member Bonds

**[ch5_sq_festival_01]** `EVELYN` — [Village square. Support members are hanging lanterns.]

> "You two are making it look easy."

**Notes:** Evelyn watching the support members work together. They have developed rhythm.

**[ch5_sq_festival_02]** `SUPPORT_MEMBER_3` — [On a ladder. Passing lanterns down.]

> "Practice. We used to set up the market festival every year."

**Notes:** Fragment of their past life. The festivals they lost. The ones they are rebuilding.

**[ch5_sq_festival_03]** `SUPPORT_MEMBER_4` — [Ground level. Catching and positioning.]

> "Three is too high. The wind will knock it loose. Move it left."

**Notes:** Support 4 is the practical one. Precise, detail-oriented.

**[ch5_sq_festival_04]** `EVELYN` — [Takes a lantern. Hangs it on a nearby post.]

> "Like this?"

**Notes:** Evelyn joining in. She wants to contribute. Not lead — contribute.

**[ch5_sq_festival_05]** `SUPPORT_MEMBER_3` — [Looking down. Smile.]

> "Perfect. You have good instincts for this."

**Notes:** Affirmation. Evelyn built a village's safety. Now she is building its warmth.

**[ch5_sq_festival_06]** `SUPPORT_MEMBER_4` — [Steps back. Looking at the lanterns.]

> "When it is dark, this will look— it will look like a real celebration."

**Notes:** Support 4 rarely shows emotion. This is as close as they get. It matters.

**[ch5_sq_festival_07]** `EVELYN` — [Looking at the lanterns. Tail curling.]

> "It already is. You made it that way."

**Notes:** Evelyn gives credit to the support members. They are essential. She knows it.

---

## 6. Internal Monologues

### Evelyn Internal Monologues

**[MON_EVELYN_5_01]** `EVELYN` — [Walking through the bustling village. Golden morning light.]

> "They are smiling at me. Really smiling. Not fear. Not pity. Joy."

**Delivery:** voice_over
**Notes:** Evelyn processing being welcomed. This is new and overwhelming in the best way.

**[MON_EVELYN_5_02]** `EVELYN` — [Watching the party interact. Silas in the clinic, Kaelen on the wall.]

> "They chose this. They chose me. I keep waiting for it to end."

**Delivery:** voice_over
**Notes:** The undertone of disbelief. Evelyn has been alone so long that belonging feels fragile.

**[MON_EVELYN_5_03]** `EVELYN` — [At the evening celebration. Looking at the bonfire.]

> "I built this. Not the fire. The safety. The laughter. The space for all of this."

**Delivery:** voice_over
**Notes:** Evelyn taking ownership of her impact. Not pride — quiet satisfaction.

**[MON_EVELYN_5_04]** `EVELYN` — [Watching Evan laugh. Really laugh. For the first time.]

> "He has a nice laugh. I want to hear it more often."

**Delivery:** voice_over
**Notes:** Evelyn's growing affection. Simple, honest, unguarded.

**[MON_EVELYN_5_05]** `EVELYN` — [After the raid victory. Looking at the party.]

> "We did that. Together. I could not have done it alone. I do not want to."

**Delivery:** voice_over
**Notes:** Evelyn accepting dependence on others. Growth from the isolated protector to team leader.

**[MON_EVELYN_5_06]** `EVELYN` — [Chapter close. Looking at the sleeping village.]

> "Keep it safe. Keep them safe. I want— I want this to last."

**Delivery:** voice_over
**Notes:** The faint shadow. Evelyn wants it to last but is not sure it will. The player should feel this.

### Evan Internal Monologues

**[MON_EVAN_5_01]** `EVAN` — [Walking through the village. People waving at him.]

> "They wave at me. I am not a knight here. I am just— Evan."

**Delivery:** voice_over
**Notes:** Evan processing identity without the Church. Just Evan. That is enough.

**[MON_EVAN_5_02]** `EVAN` — [Watching Silas treat a child's scraped knee.]

> "He treats a scraped knee like a battlefield wound. Because to him, it matters."

**Delivery:** voice_over
**Notes:** Evan understanding Silas's radical equality. Every injury matters.

**[MON_EVAN_5_03]** `EVAN` — [Watching Kaelen guard the perimeter. Fifth time around the wall.]

> "He cannot stop guarding. I understand that. I used to be the same."

**Delivery:** voice_over
**Notes:** Evan recognizing his own patterns in Kaelen. The soldier who cannot stop being a soldier.

**[MON_EVAN_5_04]** `EVAN` — [At the celebration. Watching Evelyn laugh.]

> "Her tail curls when she is happy. I have noticed this. I will not tell her."

**Delivery:** voice_over
**Notes:** Evan noticing Evelyn's tells. He observes everything about her. He keeps it to himself.

**[MON_EVAN_5_05]** `EVAN` — [During the raid. Looking at the party fighting together.]

> "This is what a team looks like. I was trained to follow orders. This is different."

**Delivery:** voice_over
**Notes:** Evan recognizing the difference between assigned units and chosen teams.

**[MON_EVAN_5_06]** `EVAN` — [Chapter close. Standing beside Evelyn at the village edge.]

> "She asked me to stay once. I said yes. Best choice I ever made."

**Delivery:** voice_over
**Notes:** Evan's reflection on his choice to join Evelyn. The foundational decision of his new life.

---

## 7. Ambient Dialogue

### Village Hub Ambient Dialogue

#### Evelyn Ambient Lines

**[AMB_EVELYN_5_01]** `EVELYN` — [Village market, browsing stalls, relaxed.]

> "The bread smells different here. Better. Like— like home should smell."

**Conditions:**
- Area: village_market
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_EVELYN_5_02]** `EVELYN` — [Near the children playing. Ears forward.]

> "I used to watch children from the trees. Now I can watch from here."

**Conditions:**
- Area: village_square
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_EVELYN_5_03]** `EVELYN` — [Near the clinic. Hearing Silas inside.]

> "He has been in there since dawn. Someone tell him to eat."

**Conditions:**
- Area: clinic_exterior
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: silas_present

**[AMB_EVELYN_5_04]** `EVELYN` — [Near the east wall. Seeing Kaelen patrol.]

> "That is the fifth time around. I am not counting. I am absolutely counting."

**Conditions:**
- Area: east_wall
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: kaelen_present

**[AMB_EVELYN_5_05]** `EVELYN` — [Festival area. Music playing.]

> "I do not know this song. But my tail knows the rhythm."

**Conditions:**
- Area: festival_square
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: none required

**[AMB_EVELYN_5_06]** `EVELYN` — [At the bonfire. Looking at the party.]

> "This is it. This is the thing I was fighting for. Right here."

**Conditions:**
- Area: bonfire
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: full_party

#### Evan Ambient Lines

**[AMB_EVAN_5_01]** `EVAN` — [Village market. Observing.]

> "The vendor layouts are efficient. Good sightlines. Someone planned this well."

**Conditions:**
- Area: village_market
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_EVAN_5_02]** `EVAN` — [Near the clinic. Watching Silas.]

> "He treats people like they matter. All of them. I am learning from that."

**Conditions:**
- Area: clinic_exterior
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: silas_present

**[AMB_EVAN_5_03]** `EVAN` — [On the perimeter. With or near Kaelen.]

> "He sees threats I would miss. I see signatures he cannot. Together— we see everything."

**Conditions:**
- Area: perimeter
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: kaelen_present

**[AMB_EVAN_5_04]** `EVAN` — [Festival area. Music.]

> "I do not know how to dance. Evelyn does. I will watch and learn."

**Conditions:**
- Area: festival_square
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: evelyn_present

**[AMB_EVAN_5_05]** `EVAN` — [At the bonfire. Watching the party.]

> "A team. Not a unit. Not an assignment. A team. There is a difference."

**Conditions:**
- Area: bonfire
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: full_party

**[AMB_EVAN_5_06]** `EVAN` — [Village edge. Night.]

> "Silence used to mean danger. Now it means the village is sleeping. I prefer this."

**Conditions:**
- Area: village_edge
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: none required

#### Silas Ambient Lines

**[AMB_SILAS_5_01]** `SILAS` — [Clinic. Working.]

> "Hold still. This will sting. Almost done. There— good as new."

**Conditions:**
- Area: clinic_interior
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_SILAS_5_02]** `SILAS` — [Village square. Observing the festival.]

> "The noise level is excellent. Noise means people are alive and happy."

**Conditions:**
- Area: village_square
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: none required

**[AMB_SILAS_5_03]** `SILAS` — [Near the bonfire. Watching the party.]

> "My hands are covered in flour and bandages. I have never been more content."

**Conditions:**
- Area: bonfire
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: full_party

**[AMB_SILAS_5_04]** `SILAS` — [Forge area. Watching Kaelen work.]

> "He treats that shield like it is alive. Perhaps it is. It has saved enough lives."

**Conditions:**
- Area: forge_area
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: kaelen_present

**[AMB_SILAS_5_05]** `SILAS` — [Near Evelyn. Quiet moment.]

> "She carries so much and still makes room for others. I recognize that. It is rare."

**Conditions:**
- Area: village_edge
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: evelyn_present

#### Kaelen Ambient Lines

**[AMB_KAELEN_5_01]** `KAELEN` — [East wall. Scanning.]

> "East wall secure. South corner marked. Gate reinforcement adequate."

**Conditions:**
- Area: east_wall
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_KAELEN_5_02]** `KAELEN` — [Village square. Uncomfortable but trying.]

> "Too many variables in a crowd. But the variables are smiling. I can manage that."

**Conditions:**
- Area: village_square
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: none required

**[AMB_KAELEN_5_03]** `KAELEN` — [Near the bonfire. Sitting.]

> "I am sitting. This is notable. Do not make a scene."

**Conditions:**
- Area: bonfire
- Story Phase: chapter5_celebration
- Combat State: exploration
- Party: full_party

**[AMB_KAELEN_5_04]** `KAELEN` — [Forge area. Working on shield improvement.]

> "The angle is wrong. Needs three degrees more tilt. There. Better."

**Conditions:**
- Area: forge_area
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: none required

**[AMB_KAELEN_5_05]** `KAELEN` — [Near Evelyn. Quiet moment.]

> "She trusts me with her perimeter. That is the highest trust anyone can give."

**Conditions:**
- Area: perimeter
- Story Phase: chapter5_village_peak
- Combat State: exploration
- Party: evelyn_present

#### Pre-Raid Ambient Dialogue

**[AMB_PRERAID_01]** `EVELYN` — [Village entrance. Morning mist. Party assembling.]

> "Everyone ready? No one forgot anything? Silas, do we have enough bandages?"

**Conditions:**
- Area: village_entrance
- Story Phase: chapter5_raid_approach
- Combat State: pre_combat
- Party: full_party

**[AMB_PRERAID_02]** `SILAS` — [Checking satchel. Organized.]

> "I have enough bandages. You do not have enough caution. But we will manage."

**Conditions:**
- Area: village_entrance
- Story Phase: chapter5_raid_approach
- Combat State: pre_combat
- Party: full_party

**[AMB_PRERAID_03]** `KAELEN` — [Shield on back. Ready.]

> "Formation is set. I take point on defense. Evelyn takes point on offense."

**Conditions:**
- Area: village_entrance
- Story Phase: chapter5_raid_approach
- Combat State: pre_combat
- Party: full_party

**[AMB_PRERAID_04]** `EVAN` — [Scanner holstered. Calm.]

> "Rear guard is mine. I will track our six. Move when ready."

**Conditions:**
- Area: village_entrance
- Story Phase: chapter5_raid_approach
- Combat State: pre_combat
- Party: full_party

**[AMB_PRERAID_05]** `SUPPORT_MEMBER_3` — [Gear checked. Ready.]

> "Let us finish this. I want to be back for the evening meal."

**Conditions:**
- Area: village_entrance
- Story Phase: chapter5_raid_approach
- Combat State: pre_combat
- Party: full_party

#### Post-Raid Ambient Dialogue

**[AMB_POSTRAID_01]** `EVELYN` — [Walking back to village. Golden light.]

> "Everyone accounted for? Sound off. I want to hear every voice."

**Conditions:**
- Area: forest_path
- Story Phase: chapter5_post_raid
- Combat State: post_victory
- Party: full_party

**[AMB_POSTRAID_02]** `KAELEN` — [Walking rear. Shield down.]

> "All accounted for. No one fell behind. The formation held."

**Conditions:**
- Area: forest_path
- Story Phase: chapter5_post_raid
- Combat State: post_victory
- Party: full_party

**[AMB_POSTRAID_03]** `SILAS` — [Already treating minor wounds.]

> "I said duck more. Nobody ducked. But you are all alive, so I will let it pass."

**Conditions:**
- Area: forest_path
- Story Phase: chapter5_post_raid
- Combat State: post_victory
- Party: full_party

**[AMB_POSTRAID_04]** `EVAN` — [Walking point. Looking at the village ahead.]

> "There it is. Home. I keep saying that word. It keeps feeling right."

**Conditions:**
- Area: forest_path
- Story Phase: chapter5_post_raid
- Combat State: post_victory
- Party: full_party

---

## 8. Cutscene Implementation Specs

### Global Cutscene Settings

| Parameter | Value |
|-----------|-------|
| **Text Box Style** | Semi-transparent dark background, white text, character name in accent color |
| **Text Speed** | 40ms per character, 200ms per punctuation pause |
| **Skip Input** | Confirm button hold for 1.5s (prevents accidental skips) |
| **Skip Threshold** | Per-scene (varies by scene, defined in PostCutsceneAction) |
| **Auto-Advance** | Disabled — player advances dialogue manually |
| **Letterbox** | Active during all cutscenes — 2.39:1 aspect ratio bars |

### AnimationPlayer Conventions

All cutscene AnimationPlayers follow these naming conventions:

- **Camera tracks**: Always named `Camera` — controls position, target, and FOV
- **Character animations**: Named `{CharacterName}_{Action}` — e.g., `Evelyn_tail_curl`, `Kaelen_scan`
- **Lighting tracks**: Named `Lights_{descriptor}` — e.g., `Lights_emergency`, `Lights_alert`
- **VFX tracks**: Named by effect — e.g., `alarm_strobe`, `detector_glow`
- **Music tracks**: Named by instrument — e.g., `Music_piano`, `Music_strings`

### Signal System

All cutscenes fire these standard signals:

| Signal | Timing | Purpose |
|--------|--------|---------|
| `cutscene_started` | 0s | Block input, disable gameplay systems |
| `player_input_blocked` | 0s | Prevent player actions during cutscene |
| `cutscene_ended` | duration | Release input, restore gameplay systems |
| `gameplay_resume` | duration | Resume gameplay at specified position |

Scene-specific signals are documented in each cutscene's Signal Timings section.

### Camera Direction Standards

- **Establishing shots**: Wide, 3-5 seconds, context-setting
- **Two-shots**: Medium framing, both characters visible, 5-8 seconds
- **Close-ups**: Face-only, emotional moments, 3-5 seconds
- **Orbit shots**: Slow circular movement around subject, 8-15 seconds
- **Push-ins**: Slow zoom toward subject, emphasis, 5-10 seconds
- **Pull-backs**: Slow zoom away, resolution, 5-10 seconds

Camera movements should be smooth and deliberate. No whip-pans or handheld shake except during combat sequences (not applicable in Chapter 5).

### VFX Trigger Standards

- **Lighting VFX**: Area lights, point lights, directional lights with color and intensity parameters
- **Particle VFX**: Named particle systems with spawn rate, lifetime, and color parameters
- **Screen VFX**: Vignettes, color grading shifts, letterbox bars
- **Prop VFX**: Animated props (banners, fire, detector glow) with animation states

### Audio Cue Standards

- **Ambient layers**: Continuous background sounds at -20dB to -30dB
- **Dialogue-adjacent sounds**: Foley and proximity sounds at -12dB to -18dB
- **Music layers**: Score enters at scene start, swells at emotional beats, resolves at scene end
- **Transition sounds**: Brief audio cues for scene changes (0.5s, -16dB)

### PreCutsceneAction Pattern

Every cutscene must define a PreCutsceneAction that:
1. Blocks player input
2. Positions characters at their starting locations
3. Sets up the environment (lighting, props, VFX state)
4. Queues audio and music

### PostCutsceneAction Pattern

Every cutscene must define a PostCutsceneAction that:
1. Releases player input
2. Sets narrative flags
3. Positions characters at their post-cutscene locations
4. Enables follow-up triggers or gameplay systems
5. Transitions to the appropriate game state

### Skip Rules

- **Minimum play-through time**: 30-50% of each cutscene must be viewable before skip is available
- **Skip behavior**: All narrative flags are set as if the cutscene played fully
- **Skip transition**: Quick fade (0.5s) to post-cutscene state
- **Critical scenes**: The evening celebration and chapter close cannot be skipped before their emotional apex (nodes 8-10 minimum)

---

## 9. Emotional Progression Notes

### Chapter 5 Emotional Map

This chapter is structured as an emotional ascent. Every scene builds warmth, connection, and joy. The player should experience the following emotional progression:

| Time | Scene | Emotion | Intensity | POV |
|------|-------|---------|-----------|-----|
| 0-12 min | Village Arrival | Relief, Wonder | High | Evelyn |
| 12-22 min | Silas Introduction | Warmth, Respect | Medium-High | Evan |
| 22-32 min | Kaelen Introduction | Trust, Gentleness | Medium-High | Evelyn |
| 32-42 min | Support Introductions | Curiosity, Connection | Medium | Alternating |
| 42-65 min | Village Immersion | Joy, Belonging | Very High | Alternating |
| 65-78 min | Evening Celebration | Euphoria, Warmth | Peak | Evelyn |
| 78-88 min | Campfire Conversations | Intimacy, Tenderness | High | Alternating |
| 88-95 min | Raid Approach | Purpose, Confidence | Medium-High | Evan |
| 95-110 min | Raid Combat | Tension, Teamwork | High | Alternating |
| 110-117 min | Raid Victory | Satisfaction, Relief | High | Evelyn |
| 117-120 min | Chapter Close | Warmth + Shadow | Medium-High | Evelyn |

### Key Emotional Beats

**Peak Joy:** The evening celebration (Scene 6) is the emotional peak. Every character is present, happy, and interacting warmly. Evelyn's tail is fully curled. Evan is almost smiling. Silas is making terrible puns. Kaelen makes a dry observation that makes Evelyn snort. The player should feel that this is the best moment in the game so far.

**Peak Intimacy:** The campfire conversations (Scene 7) are the most intimate moments. One-on-one conversations in small firelight. Each reveals something personal about the character. The player chooses which to experience, making each playthrough slightly different but equally warm.

**Peak Purpose:** The raid approach (Scene 8) shifts the emotion from joy to purpose. The party is not afraid — they are confident. They have bonded, they trust each other, and they are ready. The player should feel excitement, not dread.

**Peak Satisfaction:** The raid victory (Scene 9) delivers on the preparation. The party fought together, won together, and came back together. The satisfaction comes from the emotional investment — the player cares about these people, and they succeeded together.

**The Shadow:** The chapter close (Scene 10) introduces the faintest undertone. Evelyn's "I hope it lasts" and the shadow on her face are the first hints that this warmth will be tested. The player should feel warmth with a subtle undercurrent of "this is too good." This sets up the emotional devastation of later chapters.

### Character Emotional States by End of Chapter 5

| Character | Starting State | Ending State | Change |
|-----------|---------------|--------------|--------|
| Evelyn | Guarded joy | Open happiness | Fully relaxed, tail curling openly |
| Evan | Cautious belonging | Committed warmth | Smiling, calling the village "home" |
| Silas | Quiet guilt | Purpose renewed | Sharing fragments of Maren's story |
| Kaelen | Perpetual vigilance | Choosing to rest | Smiling (smallest smile), sitting by choice |
| Support 3 | Displaced | Rooted | Rebuilding festival traditions |
| Support 4 | Solo operator | Team believer | Trusting the party, saying "we" |

### What the Player Should Feel

By the end of Chapter 5, the player should:

1. **Love the party members.** Each introduction and bond sequence is designed to make the player care about these people as individuals, not just combat units.
2. **Love the village.** The village hub at PEAK is a place the player never wants to leave. It is warm, alive, and full of people who smile at the party.
3. **Feel the warmth of the celebration.** The evening celebration should be the happiest extended moment in the game. Music, food, laughter, terrible puns.
4. **Feel proud of the raid victory.** The raid is the biggest combat yet, and the party succeeds together. The satisfaction comes from the bonds forged earlier.
5. **Feel the faint shadow.** The chapter close introduces the smallest seed of dread. The player should feel warmth but also sense that this cannot last forever.

### Setup for Later Chapters

Chapter 5's warmth is the foundation for later emotional devastation. Every bond forged here will be tested:

- **Silas's guilt** will resurface when he cannot save someone in Chapter 7-8.
- **Kaelen's shield** will be cracked (literally and metaphorically) when his past catches up to him.
- **The village** will be threatened in Chapter 8-9, and the player will fight to protect what they built here.
- **Evelyn and Evan's warmth** will be the emotional anchor through the darkness of later chapters.
- **The support members** will prove their worth in ways that make their potential loss devastating.

The player must fall in love in Chapter 5 so that later chapters can hurt. This is intentional. This is the design.

---

## 10. Cross-References

### Character Profiles

- [Evelyn](../characters/evelyn.md) — POV character, voice and emotional arc guidance
- [Evan](../characters/evan.md) — POV character, voice and emotional arc guidance
- [Silas (Healer)](../characters/healer-char.md) — Party member introduction and bond sequences
- [Kaelen (Tanker)](../characters/tanker-char.md) — Party member introduction and bond sequences
- [Support Member 3](../characters/support3-char.md) — Support member introduction (TBD: finalize character file)
- [Support Member 4](../characters/support4-char.md) — Support member introduction (TBD: finalize character file)

### Dialogue Style Guide

- [Dialogue Style Guide](../dialogue-style-guide.md) — All dialogue in this document conforms to the 120-character limit, node format, and voice principles defined in the style guide.

### Level Design

- [Chapter 5 Level Design](../../../levels/chapter5-bonds/level-design.md) — Full level layout, encounter design, pacing map, and environmental storytelling. All trigger IDs referenced in this document must exist in the level design.

### Trigger ID Index

| Trigger ID | Scene | Timing |
|------------|-------|--------|
| `ch5_village_hub_peak` | Village Arrival | Minutes 0-12 |
| `ch5_member1_intro` | Silas Introduction | Minutes 12-22 |
| `ch5_member1_joins` | Silas Joins Roster | After intro |
| `ch5_member2_intro` | Kaelen Introduction | Minutes 22-32 |
| `ch5_member2_joins` | Kaelen Joins Roster | After intro |
| `ch5_member3_intro` | Support 3 Introduction | Minutes 32-42 |
| `ch5_member3_joins` | Support 3 Joins Roster | After intro |
| `ch5_member4_intro` | Support 4 Introduction | Minutes 32-42 |
| `ch5_member4_joins` | Support 4 Joins Roster | After intro |
| `ch5_side_quest_bond` | Village Side Quests | Minutes 42-65 |
| `ch5_evening_celebration` | Evening Celebration | Minutes 65-78 |
| `ch5_campfire_bonds` | Campfire Conversations | Minutes 78-88 |
| `ch5_raid_approach` | Raid Assembly | Minutes 88-95 |
| `ch5_raid_combat` | Raid Combat | Minutes 95-110 |
| `ch5_raid_victory` | Raid Victory | Minutes 110-117 |
| `ch5_chapter_close` | Chapter Close | Minutes 117-120 |

### Dialogue Node Index

| Node ID | Scene | Character | Character Count |
|---------|-------|-----------|-----------------|
| ch5_arrival_01 through ch5_arrival_12 | Village Arrival | Evelyn, Evan, Silas, Kaelen | All < 120 |
| ch5_silas_intro_01 through ch5_silas_intro_12 | Silas Introduction | Evan, Silas | All < 120 |
| ch5_kaelen_intro_01 through ch5_kaelen_intro_12 | Kaelen Introduction | Evelyn, Kaelen | All < 120 |
| ch5_support3_intro_01 through ch5_support3_intro_07 | Support 3 Introduction | Evelyn, Support 3 | All < 120 |
| ch5_support4_intro_01 through ch5_support4_intro_06 | Support 4 Introduction | Evan, Support 4 | All < 120 |
| ch5_celebration_01 through ch5_celebration_15 | Evening Celebration | Full Party | All < 120 |
| ch5_campfire_silas_01 through ch5_campfire_silas_06 | Campfire: Silas | Evelyn, Silas | All < 120 |
| ch5_campfire_kaelen_01 through ch5_campfire_kaelen_05 | Campfire: Kaelen | Evan, Kaelen | All < 120 |
| ch5_campfire_support_01 through ch5_campfire_support_04 | Campfire: Support | Evelyn, Support 3, Support 4 | All < 120 |
| ch5_raid_approach_01 through ch5_raid_approach_12 | Raid Approach | Full Party | All < 120 |
| ch5_raid_victory_01 through ch5_raid_victory_13 | Raid Victory | Full Party | All < 120 |
| ch5_close_01 through ch5_close_14 | Chapter Close | Evelyn, Evan | All < 120 |
| ch5_assembly_01 through ch5_assembly_13 | Party Assembly | Full Party | All < 120 |
| ch5_silas_bond_01 through ch5_silas_bond_16 | Silas Bond | Evan, Silas | All < 120 |
| ch5_kaelen_bond_01 through ch5_kaelen_bond_14 | Kaelen Bond | Evelyn, Kaelen | All < 120 |
| ch5_evelyn_evan_01 through ch5_evelyn_evan_12 | Evelyn + Evan | Evelyn, Evan | All < 120 |
| ch5_raid_debrief_01 through ch5_raid_debrief_13 | Raid Debrief | Full Party | All < 120 |
| ch5_sq_baker_01 through ch5_sq_baker_06 | Side Quest: Baker | Evelyn, Silas | All < 120 |
| ch5_sq_patrol_01 through ch5_sq_patrol_08 | Side Quest: Patrol | Evan, Kaelen | All < 120 |
| ch5_sq_festival_01 through ch5_sq_festival_07 | Side Quest: Festival | Evelyn, Support 3, Support 4 | All < 120 |

### Architecture Decision Records

- [ADR-0003](../../architecture/adr-0003-party-dialogue-node-system.md) — Dialogue node system design, signal timing, and AnimationPlayer integration patterns
- [ADR-0004](../../architecture/adr-0004-cutscene-skip-behavior.md) — Cutscene skip behavior, flag management, and narrative continuity guarantees

### Related Chapters

- [Chapter 4: "The Truth"](../chapter4/the-truth.md) — Preceding chapter. Alliance formed, party assembled. Ch5 builds on this foundation.
- [Chapter 6: "The Witch's Shadow"](../chapter6/the-witchs-shadow.md) — Following chapter. The warmth of Ch5 is contrasted with the Witch's indirect presence.
- [Chapter 7: "The Fall of the Cross"](../chapter7/the-fall-of-the-cross.md) — The bonds forged in Ch5 are tested in the first major Church confrontation as a full party.

### Lore References

- [Church Lore](../lore/church-lore.md) — Church Tier 2 facility design, organizational structure, and expansion plans referenced in raid sequences
- [Village Culture Lore](../lore/village-culture-lore.md) — Village festival traditions, market culture, and community dynamics referenced in village immersion sequences
- [Vampire Transformation Lore](../lore/vampire-transformation-lore.md) — Evelyn's vampire nature referenced in her internal monologues and ambient dialogue