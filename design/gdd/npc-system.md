# NPC System

> **Status**: Designed
> **Author**: Design session 2026-04-11 (interactive redesign)
> **Last Updated**: 2026-04-11
> **Implements Pillar**: Story First, The Party Is the Game

## Overview

The NPC System defines all non-combat characters that populate hub areas and safe zones. Each NPC is a Resource-based definition with a dialogue graph, optional quest chain, position data, sprite reference, and ambient behavior profile. NPCs serve four roles: Quest Givers (optional objectives with chains), Merchants (shop access points), Lore Keepers (world-building and hints), and Service Providers (heal, repair, storage). NPCs are placed using a mixed approach — key characters are fixed at landmarks, ambient NPCs patrol routes for atmosphere, and story-gated characters appear only after narrative unlocks. Players interact by approaching an NPC and pressing a prompt button. NPCs track their quest state, relationship value (from the Narrative Choice System), one-time reaction triggers, and can permanently leave via story events or permadeath. Large hubs contain 5-10 NPCs with idle animations, bubble dialogue, proximity reactions, and ambient sound barks to create a living settlement feel.

## Player Fantasy

NPCs serve the fantasy of **a world that exists beyond you**. When you return to a village and the blacksmith asks how your last mission went, when the old scholar has a new piece of lore because you just completed the quest they gave you, when the ambient chatter of a bustling hub makes you feel like you've arrived somewhere real — that's the NPC system working. Each NPC should feel like a person with a schedule, not a vending machine. The ones that matter leave an impression; the ones that are ambient make the place breathe. The player should want to come back to hubs, not just use them as loading screens between chapters.

**Reference model**: Stardew Valley's villagers (each with a schedule, a personality, and something to offer), Dragon Age's camp companions (characters you revisit between missions), and Final Fantasy XIV's resident NPCs in housing areas (world presence that makes settlements feel alive).

## Detailed Design

### Core Rules

1. **NPC Definition**: Each NPC is defined by an `NPCData` Resource (`.tres` file) with the following structure:
   ```
   NPCData Resource fields:
   ┌─────────────────────────────────────────────────┐
   | NPCId: string (unique identifier)                |
   | DisplayName: string                              |
   | Sprite: Texture2D                                |
   | Role: enum (QuestGiver, Merchant, LoreKeeper,    |
   |         ServiceProvider, Ambient)                 |
   | DialogueGraph: DialogueResource reference        |
   | QuestChain: QuestChainData? (optional, ref)      |
   | Position: Vector2 (hub scene coordinates)        |
   | PatrolPath: PackedScene? (optional patrol route)  |
   | AmbientBehaviors: AmbientBehaviorProfile?        |
   | StoryGateFlag: string? (null = always available)  |
   | CanLeavePermanently: bool                        |
   └─────────────────────────────────────────────────┘
   ```

2. **NPC Placement**: NPCs are placed in hub scenes using a mixed strategy:
   - **Fixed NPCs**: Key characters (quest givers, merchants, service providers) are placed at specific coordinates in the hub scene (`.tscn`). They don't move unless a story event relocates them.
   - **Patrol NPCs**: Characters with a `PatrolPath` follow a defined `Path2D` route with idle animations at waypoints. Used for important NPCs that need to feel active (village guards, traveling merchants).
   - **Ambient NPCs**: Background characters with simple idle animations and optional bubble dialogue. These don't have dialogue graphs or quests — they exist purely for atmosphere.

3. **Interaction Initiation**: When the player (Evelyn) enters a trigger zone (radius ~48px) around an NPC:
   - A prompt appears: "[NPC DisplayName] — Press [Interact] to Talk"
   - The NPC turns to face the player (proximity reaction)
   - If the NPC has quest state changes or one-time reactions pending, the prompt may include a visual indicator (exclamation mark for new quest, question mark for quest turn-in, sparkle for special dialogue)
   - Pressing Interact opens the Dialogue UI with the NPC's dialogue graph

4. **Dialogue Resolution**: NPC dialogue follows the Dialogue System's graph-based flow. If the NPC has a quest chain:
   - The dialogue graph checks quest state via story flags
   - Quest-available NPCs show quest offer dialogue
   - Quest-in-progress NPCs show progress check dialogue
   - Quest-complete NPCs show completion dialogue and may offer the next quest in the chain
   - If no quests are available/active, the NPC shows ambient/greeting dialogue

5. **Quest Chain State**: Each NPC with a quest chain tracks:
   ```
   QuestChainState:
   ┌─────────────────────────────────────────────────┐
   | NPCId: string                                    |
   | CurrentQuestIndex: int (which quest in chain)    |
   | QuestState: enum (NotStarted, Offered,           |
   |                   InProgress, Complete, Failed)  |
   | CompletionCount: int (for tracking repeats)      |
   └─────────────────────────────────────────────────┘
   ```
   Quest state is stored in the Chapter State System and persists through save/load.

6. **Relationship Integration**: NPCs with a `CharacterData` entry (named NPCs that appear in the relationship system) read their relationship value from the Narrative Choice System. This affects:
   - Greeting dialogue variant (cold/neutral/warm)
   - Shop prices (for merchant NPCs — see Shop System formula)
   - Quest availability (some quests only unlock at relationship thresholds)
   - Farewell dialogue (characters with high relationship may warn you of danger)

7. **One-Time Reactions**: After specific story events (tracked via story flags), NPCs can have a unique one-time dialogue that plays the next time the player interacts with them. After playing once, the dialogue flag is set and the NPC returns to normal dialogue. Example: After defending the village, the village elder says "Thank you. We owe you our lives." — but only the first time you visit after the event.

8. **Permanent Departure**: An NPC can leave permanently via:
   - **Story event**: A story flag marks `NPC_{id}_Left = true`. The NPC is removed from the hub scene. Their dialogue trigger is disabled.
   - **Permadeath**: If the NPC is a character with a `CharacterData` entry and dies (from Narrative Choice permadeath or combat), they are removed. Their sprite remains as a gray memorial sprite if configured.
   - When an NPC leaves, their quest chain is abandoned (incomplete quests are marked `Failed`). The player is notified: "[NPC] is gone. Their quest is no longer available."

9. **Ambient Behavior Profile**: NPCs with `AmbientBehaviors` configured exhibit:
   - **Idle animation**: Looping animation (breathing, working, shifting weight)
   - **Bubble dialogue**: Random flavor text appearing above the NPC every 15-30 seconds (randomized from a pool of 5-10 lines per NPC)
   - **Proximity reaction**: NPC sprite rotates to face the player when within trigger zone
   - **Sound barks**: Random audio clips (muttering, humming, sighing) played at 20-40 second intervals

10. **Hub Scene Loading**: When a hub scene loads, the NPC manager:
    - Reads all NPC definitions for the current hub
    - Filters out NPCs whose `StoryGateFlag` is not yet set
    - Filters out NPCs marked as permanently left
    - Instantiates remaining NPCs at their defined positions
    - Starts patrol routes and ambient behaviors for NPCs that have them
    - Updates quest state indicators on NPCs (exclamation/question marks)

### States and Transitions

```
┌──────────┐  Load hub scene    ┌──────────────────┐
│  Hub     │  Manager filters   │  NPCs placed     │
│  Scene   │  by story flags    │  + patrols start │
└──────────┘                    └────────┬─────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
             ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
             │  Fixed NPC   │    │  Patrol NPC  │    │  Ambient NPC │
             │  (idle at    │    │  (follows    │    │  (idle +     │
             │  position)   │    │  Path2D)     │    │  bubble text)│
             └──────┬───────┘    └──────┬───────┘    └──────────────┘
                    │                   │
                    │  Player enters    │
                    │  trigger zone     │
                    ▼                   │
             ┌──────────────┐           │
             │  Prompt      │◄──────────┘
             │  appears     │
             └──────┬───────┘
                    │  Player presses Interact
                    ▼
             ┌──────────────┐
             │  Dialogue UI │──▶ Quest check ──▶ Quest offer/turn-in
             │  opens       │──▶ Story flag check ──▶ One-time reaction
             │              │──▶ Relationship check ──▶ Greeting variant
             └──────┬───────┘
                    │  Dialogue ends
                    ▼
             ┌──────────────┐
             │  Resume hub  │
             │  exploration │
             └──────────────┘
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Dialogue System** | Calls | NPCs use dialogue graphs for all conversation | Dialogue presentation via Dialogue UI |
| **Narrative Choice** | Reads | Reads relationship values and story flags for conditional dialogue | Relationship values, story flags |
| **Chapter State System** | Reads + Writes | Reads story flags for gating; writes quest chain state | Chapter context, quest persistence |
| **Quest System** | Reads + Writes | Manages quest chain state per NPC; offers/completes/fails quests | Quest definitions, rewards |
| **Shop System** | Calls | Merchant NPCs open shop UI when player chooses "Browse Shop" | Shop transaction flow |
| **Character Data** | Reads | Reads character definitions for named NPCs with relationships | Character definitions |
| **Save / Load** | Serialized | Quest chain state, NPC departure flags are saved/loaded | — |
| **Hub Scene System** | Driven by | Hub manager places NPCs when scenes load | Scene context, NPC positions |
| **Combat System** | Reads | Combat blocks NPC interaction (can't talk during combat) | `IsInCombat` flag |

## Formulas

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **Bubble Dialogue Interval** | `random(15, 30)` seconds | — | Randomized per NPC from their bubble pool |
| **Sound Bark Interval** | `random(20, 40)` seconds | — | Randomized per NPC from their audio pool |
| **Proximity Trigger Radius** | `48px` from NPC center | — | Distance at which prompt appears |
| **Quest Chain Progression** | `nextQuestIndex = currentQuestIndex + 1` | — | Linear chain; no branching quest chains |
| **Quest Failure on Departure** | `All active quests from NPC → State = Failed` | — | When NPC leaves permanently |

## Edge Cases

1. **Player interacts with an NPC who just left (race condition)**: The NPC removal is processed before the hub scene unloads. If the player was mid-conversation when a story event triggers NPC departure, the dialogue completes normally, but the NPC is gone when the player returns to the hub.

2. **Quest chain references an item that no longer exists (deleted Resource)**: The quest is marked as `Broken` and a warning is logged. The NPC's dialogue falls back to a generic "I can't help you with that anymore" branch. This is a content authoring error, not a runtime failure.

3. **Player enters a hub before the NPC's story gate is set**: The NPC simply isn't instantiated. No placeholder, no "coming soon" indicator. The player won't know the NPC exists until the story unlocks them.

4. **NPC with a patrol route has their path blocked by another NPC or obstacle**: The patrol path is defined by the level designer to avoid collisions. If a collision occurs (e.g., two NPCs on intersecting paths), the NPC pauses for 2 seconds then retries the current waypoint. If still blocked after 3 retries, the NPC teleports to the next waypoint.

5. **Ambient NPC bubble dialogue plays a line that contradicts current story state**: Bubble dialogue pools should be authored with context awareness. If not possible, the system falls back to a generic "safe" pool. The dialogue pool for each NPC should be reviewed after each chapter to remove invalidated lines.

6. **Player has multiple NPCs offering quests simultaneously**: All quest chains are independent. The player can accept quests from multiple NPCs and complete them in any order. Quest indicators (exclamation/question marks) appear on all eligible NPCs simultaneously.

7. **Merchant NPC leaves permanently while player has items they wanted to sell**: The shop system is tied to the merchant NPC — if the merchant leaves, their shop is unavailable. The player receives a notification: "[Merchant] is no longer trading." Alternative merchants may exist elsewhere.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Dialogue System | Calls | Hard — NPCs use dialogue graphs | `DialogueResource` references per NPC |
| Narrative Choice | Reads | Hard — reads relationships and story flags | `GetRelationship(characterId)`, `GetFlag(key)` |
| Chapter State System | Reads + Writes | Hard — quest state, NPC departure flags | `SetQuestState(npcId, index, state)`, `GetQuestState(npcId, index)` |
| Quest System | Reads + Writes | Hard — manages quest chains per NPC | `QuestChainData`, `OfferQuest()`, `CompleteQuest()`, `FailQuest()` |
| Shop System | Calls | Soft — merchant NPCs open shop UI | `OpenShop(merchantId)` |
| Character Data | Reads | Soft — reads definitions for named NPCs | `CharacterData` Resource references |
| Save / Load | Serialized | Hard — persists quest state, departure flags | JSON: `npcQuestChains`, `departedNPCs` |
| Hub Scene System | Driven by | Hard — NPC placement and instantiation | Hub scene `.tscn` files with NPC manager |
| Combat System | Reads | Soft — blocks interaction during combat | `IsInCombat` flag |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `ProximityTriggerRadius` | int | `48px` | 32-64 | Prompt appears too far; player accidentally triggers | Prompt appears too close; player overshoots NPC |
| `BubbleDialogueIntervalMin` | int | `15s` | 10-20 | NPCs chatter constantly; distracting | NPCs feel dead; no atmosphere |
| `BubbleDialogueIntervalMax` | int | `30s` | 20-45 | Same as min too low | Long gaps; NPCs feel forgotten |
| `SoundBarkIntervalMin` | int | `20s` | 15-30 | Audio clutter; overlapping sounds | No ambient audio presence |
| `SoundBarkIntervalMax` | int | `40s` | 30-60 | Same as min too low | Dead silence in hubs |
| `NPCsPerHub` | int | `7` | 5-10 | Hubs feel overcrowded; performance impact | Hubs feel empty and artificial |
| `PatrolSpeed` | float | `60px/s` | 40-100 | NPCs zip around unnaturally | Patrol feels frozen; no movement |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| NPC enters player proximity | Prompt appears above NPC with name and interact button | Soft prompt chime | High |
| NPC has new quest available | Exclamation mark icon ("!") bounces above NPC | Quest available jingle | High |
| NPC has quest turn-in ready | Question mark icon ("?") bounces above NPC | Quest complete jingle | High |
| NPC has one-time reaction | Sparkle icon ("✦") glows above NPC | Special dialogue trigger sound | Medium |
| Bubble dialogue appears | Speech bubble fades in above NPC with text | Soft pop sound | Low |
| NPC turns to face player | Sprite rotates smoothly (0.3s tween) | None | Medium |
| NPC leaves permanently | NPC fades out with particle dissolve (if witnessed by player) | Somber tone or ambient silence | High |
| Hub scene loads with NPCs | NPCs fade in with staggered timing (0.1s apart) | Ambient hub music starts | High |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **NPC Prompt** | NPC name + "Press [Key] to Talk" floating above NPC | Player within 48px trigger radius |
| **Quest Indicators** | "!" (new), "?" (turn-in), "✦" (special) above NPC | Quest state matches indicator |
| **Dialogue UI** | NPC portrait on left, dialogue text on right, choice buttons at bottom | Standard dialogue interaction (see Dialogue System GDD) |
| **Shop UI** (merchant NPCs) | Shop interface with buy/sell tabs | Player selects "Browse Shop" from merchant dialogue |

## Acceptance Criteria

- [ ] NPCs instantiate correctly in hub scenes based on story flag filtering
- [ ] Proximity prompt appears when player enters 48px trigger radius
- [ ] NPC turns to face player on proximity (0.3s rotation tween)
- [ ] Dialogue UI opens when player presses Interact on NPC prompt
- [ ] Quest indicators ("!", "?", "✦") appear correctly based on quest chain state
- [ ] Quest chains progress linearly (quest N+1 unlocks after quest N completes)
- [ ] Relationship values from Narrative Choice affect NPC greeting dialogue
- [ ] One-time reaction dialogue plays exactly once per story event
- [ ] Permanently departed NPCs are removed from hub scene; quest chains marked Failed
- [ ] Ambient NPCs exhibit idle animations, bubble dialogue, and sound barks at tuned intervals
- [ ] Patrol NPCs follow defined Path2D routes with waypoint idle pauses
- [ ] All quest chain state persists through save/load
- [ ] NPCs cannot be interacted with during combat
- [ ] Story-gated NPCs are invisible/absent until their gate flag is set

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| Should NPCs have a "last seen" timestamp so the player knows how long it's been since they last visited? | UX Designer | Resolve during first hub implementation — nice-to-have for Polish |
| Can the player gift items to NPCs to increase relationship faster? | Game Designer | Resolve during Quest System design — adds resource sink to relationship building |
| Should ambient NPCs have a minimal interaction (wave, nod) to acknowledge player presence without opening full dialogue? | Narrative Director | Resolve during hub atmospheric design — recommendation: yes, adds warmth |
| Should NPC quest rewards scale with player level or be fixed? | Systems Designer | Resolve during balance phase — recommendation: fixed rewards for predictability |
