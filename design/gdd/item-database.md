# Item Database

> **Status**: In Design
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game

## Overview

The Item Database is the master definition for all items in the game — equipment,
consumables, key/quest items, and enhancement materials. Stored as multiple
ScriptableObject types (`ItemEquipmentSO`, `ItemConsumableSO`, `ItemKeySO`,
`ItemMaterialSO`), each item's data card defines its identity, stats, rarity tier,
character class restrictions, and usage rules. Players interact with the Item Database
indirectly: when they see a sword drop, read its stats, equip it to Evan, or notice
that a potion restores 40% HP, they are seeing Item Database entries in action. The
database also contains the **Item Rarity System** — a five-tier rarity scale (Common,
Uncommon, Rare, Epic, Legendary) that governs stat range multipliers, drop frequency,
and visual presentation. Every system that handles items — Inventory, Loot & Drop,
Shop, Equipment Enhancement — reads from these cards. Nothing in the game can
reference an item without going through its Item Database entry.

## Player Fantasy

Item Database serves the fantasy of **building a team you believe in, piece by piece**.
When a player sees a Rare sword drop and immediately thinks "Evan needs this," they
feel the satisfaction of curation — not random number generation, but meaningful gear
that makes specific companions stronger in specific ways. Each item should feel
*intentional*, not generic. A Mage staff shouldn't feel like "the staff any Mage uses"
— it should feel like "the staff that makes *this* Mage the right choice for this
encounter." Equipment is an extension of character identity. When a player equips
Evelyn with a weapon, they're not just boosting ATK — they're investing in her
survival, because she matters. The rarity system amplifies this: finding an Epic item
should feel like finding a piece of a puzzle that finally clicks, not winning a
lottery ticket.

**Reference model**: Final Fantasy and Tales series — equipment feels character-
specific and narratively meaningful, not stat-stick commodities. Players remember the
sword they found in Chapter 2 because it carried them through Chapter 3, not because
it had the highest DPS at level 8.

## Detailed Design

### Core Rules

1. **Four ScriptableObject types** exist, one per item category:
   - `ItemEquipmentSO` — equippable items (weapons, armor, accessories)
   - `ItemConsumableSO` — single-use items (potions, buffs, revives)
   - `ItemKeySO` — quest/story items that cannot be used, sold, or dropped
   - `ItemMaterialSO` — enhancement materials used to upgrade equipment

2. **Every `ItemEquipmentSO` has exactly 5 equipment slots**:

   | Slot | Purpose | Examples |
   |------|---------|----------|
   | `Weapon` | Primary damage output stat modifier | Sword, Staff, Bow, Dagger, Mace |
   | `Armor` | Damage mitigation stat modifier | Robe, Chain Mail, Leather Vest |
   | `Helmet` | Defensive stat modifier with special effects | Crown, Hood, Battle Helm |
   | `Accessory` | Utility and percentage bonuses | Ring, Necklace, Charm |
   | `Relic` | Unique character-specific item with narrative weight | Evelyn's Cursed Pendant, Evan's Hunter Badge |

3. **Equipment slot assignment is per-character, not global** — every character can equip one item per slot simultaneously (5 items total when fully equipped).

4. **Every equipment item has a `CharacterClass` restriction** — either a single class (e.g., `Mage`-only staff) or `Any` (equippable by all classes). The Loot & Drop system uses this to filter drops; the Inventory UI grey-outs items a character cannot equip.

5. **Every equipment item defines stat bonuses** using these types:

   | Bonus Type | Applies To | Example |
   |------------|-----------|---------|
   | Flat Stat | MaxHP, ATK, DEF, MaxMP, SPD, CRIT | +80 ATK, +200 MaxHP |
   | Percentage | MaxHP%, ATK%, DEF%, MaxMP%, CRIT% | +12% ATK, +5% CRIT |
   | Special Effect | Conditional triggers | "Lifesteal 5% on hit", "+10 MP on kill" |

6. **Item levels** — every equipment item has a `RequiredLevel` field. Characters below this level cannot equip the item. This gates item progression independently from rarity.

7. **Consumable items** (`ItemConsumableSO`) define:
   - `EffectType` enum: `RestoreHP`, `RestoreMP`, `TemporaryBuff`, `Revive`, `CleanseStatus`
   - `EffectValue` (int or float) — the magnitude of the effect
   - `TargetScope` enum: `SingleCharacter`, `AllParty`, `ActiveCharacterOnly`

8. **Key items** (`ItemKeySO`) have no stats, no equip rules, and cannot be sold or dropped. They exist purely for narrative gating and quest tracking.

9. **Enhancement materials** (`ItemMaterialSO`) define:
   - `EnhancementTier` — which equipment rarity levels they apply to
   - `StatIncrease` — the flat or percentage boost applied to the target equipment
   - `BaseGoldCost` (int) — the gold value of this material; used when calculating the 30% refund on enhanced item sale

10. **No system may write to item ScriptableObjects at runtime**. Equipment state (current enhancement level, durability) lives in a separate runtime state container. Item ScriptableObjects are read-only definitions.

### States and Transitions

`ItemEquipmentSO`, `ItemConsumableSO`, `ItemKeySO`, and `ItemMaterialSO` are **stateless** ScriptableObjects — they define item templates and never change at runtime.

Runtime state for equipment instances is tracked in `EquipmentInstance`, a separate runtime container:

| State Property | Type | Default | Description |
|---------------|------|---------|-------------|
| `IsEquipped` | bool | false | True when this instance is equipped on a character |
| `EnhancementLevel` | int | 0 | Current enhancement level (0 = base; increases with enhancement materials) |
| `Durability` | int (0–100) | 100 | Current durability; at 0, item is broken and unequipped until repaired |

**State Transitions (EquipmentInstance):**

| From State | Trigger | To State | Notes |
|-----------|---------|----------|-------|
| Unequipped | Player equips item on character | Equipped | Validates RequiredLevel, CharacterClass restriction, and slot availability |
| Equipped | Player unequips or character dies | Unequipped | Death applies -10 durability to Armor and Helmet slots only |
| Durability > 0 | Item takes damage in combat | Durability -1 | Only Armor and Helmet slots lose durability |
| Durability = 0 | Equipment breaks | Unequipped (locked) | Item greyed-out in inventory; must be repaired (costs gold at village hub) |
| EnhancementLevel N | Player uses enhancement material | EnhancementLevel N+1 | Validates material EnhancementTier matches item rarity; stats recalculated |

**Consumable, Key, and Material items have no runtime state** — they are consumed (consumables), permanently owned (key items), or spent (materials) without intermediate states.

### Interactions with Other Systems

| System | Direction | What It Reads |
|--------|-----------|---------------|
| Inventory & Equipment System | Reads Item ScriptableObjects + EquipmentInstance | ItemDisplayName, Icon, StatBonuses, RequiredLevel, CharacterClass; tracks EquipmentInstance state |
| Loot & Drop System | Reads Item ScriptableObjects | Rarity, CharacterClass restriction, RequiredLevel (filters drops to appropriate characters) |
| Character Progression System | Reads ItemEquipmentSO.RequiredLevel | Gates equipment equipping behind character level |
| Shop System | Reads Item ScriptableObjects | BaseGoldValue (calculated from Rarity + StatBonuses) |
| Equipment Enhancement System | Reads ItemEquipmentSO + EquipmentInstance | EnhancementTier compatibility; applies stat recalculation on enhancement |
| Combat HUD | Reads EquipmentInstance (via Inventory System) | Active equipment bonuses applied to character stats |
| Health & Damage System | Reads EquipmentInstance bonuses | Effective DEF and MaxHP after equipment bonuses applied |
| Skill Execution System | Reads EquipmentInstance bonuses | Effective SPD and CRIT after equipment bonuses applied |
| Combat System | Reads EquipmentInstance bonuses | All stat bonuses applied during combat calculations |
| Save / Load System | Reads EquipmentInstance state | Serializes IsEquipped, EnhancementLevel, Durability per item |

**Interface ownership**: The Item Database **owns** the item definition schema. Other systems **read** from it. Only the Inventory & Equipment System and Equipment Enhancement System **write** to EquipmentInstance state at runtime. No system writes to the base ScriptableObject.

## Formulas

### Effective Stat Calculation

```
EffectiveStat = (BaseStat + EquipmentFlatBonus) × (1 + min(EquipmentPercentageBonus, 0.50))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| BaseStat | int or float | See Character Data GDD | CharacterDataSO | Character's base stat from their data card (includes level growth) |
| EquipmentFlatBonus | int | 0–200 | Sum of all 5 equipped items' flat bonuses | Total flat stat bonus from all equipped equipment |
| EquipmentPercentageBonus | float | 0.0–0.50 (0%–50%) | Sum of all 5 equipped items' percentage bonuses | Total percentage bonus from all equipped equipment (capped at 50%) |

**Example** — Evelyn at L30 with full Rare equipment:
- Base ATK: 239 (from CharacterDataSO)
- Equipment Flat Bonus: +80 ATK (Weapon) + +40 ATK (Accessory) = +120 ATK
- Equipment Percentage Bonus: 12% ATK (Weapon) + 8% ATK (Relic) = 20% ATK
- **Effective ATK** = (239 + 120) × (1 + 0.20) = 359 × 1.20 = **430.8**

**Expected bonus impact**: Equipment should contribute 15–35% of a character's total effective stats at endgame. This keeps character identity (base stats from CharacterDataSO) meaningful while making equipment feel impactful.

**Note on derived stat bonuses**: Some equipment grants bonuses to derived stats like "Final ATK%" (percentage of total ATK after all modifiers) or "Physical DEF%" (percentage of DEF against physical damage only). These are implemented as **Special Effects** and are applied during combat calculation, not during stat aggregation. The EffectiveStat formula above only covers base stat aggregation; derived stat modifiers are applied multiplicatively during damage calculation by the Combat System.

---

### Rarity Stat Multiplier

```
ItemStatRange = BaseStatRange × RarityMultiplier
```

| Rarity | Multiplier | Stat Range vs. Base | Drop Frequency |
|--------|-----------|---------------------|----------------|
| Common | 1.00x | 100% (baseline) | 50% of drops |
| Uncommon | 1.25x | +25% stat range | 30% of drops |
| Rare | 1.50x | +50% stat range | 15% of drops |
| Epic | 2.00x | +100% stat range | 4% of drops |
| Legendary | 2.50x | +150% stat range | 1% of drops |

**Baseline stat ranges per equipment piece** (before rarity multiplier):

| Equipment Slot | Stat Type | Common Range | Rare Range | Legendary Range |
|---------------|-----------|--------------|------------|-----------------|
| Weapon | ATK | 30–60 | 45–90 | 75–150 |
| Armor | DEF | 20–40 | 30–60 | 50–100 |
| Helmet | DEF + MaxHP | 15–30 DEF, 50–100 HP | 22–45 DEF, 75–150 HP | 37–75 DEF, 125–250 HP |
| Accessory | Any stat (percentage) | 3%–8% | 4–12% | 7–20% |
| Relic | Any stat (flat + special) | 40–80 flat + 1 effect | 60–120 flat + 1–2 effects | 100–200 flat + 2–3 effects |

---

### Item Gold Value

```
BaseGoldValue = (RequiredLevel × 10) × RarityMultiplier × (1 + StatBonusTotal / 100)
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| RequiredLevel | int | 1–30 | ItemEquipmentSO |
| RarityMultiplier | float | 1.0–2.5 | From rarity table above |
| StatBonusTotal | float | 0–50 | Sum of all percentage stat bonuses on the item |

**Example**: Rare (1.5x) sword, RequiredLevel 15, with +12% ATK and +8% CRIT (20% total):
- BaseGoldValue = (15 × 10) × 1.5 × (1 + 20/100) = 150 × 1.5 × 1.20 = **270 gold**

**Shop prices**: Shop System sells at 100% BaseGoldValue, buys from player at 40% BaseGoldValue.

---

### Durability Loss

```
DurabilityLossPerHit = 1 (for Armor and Helmet slots only)
DurabilityLossOnDeath = 10 (flat penalty to Armor and Helmet slots only)
```

Only Armor and Helmet slots have durability. Weapon, Accessory, and Relic slots do not
lose durability and are never Broken.

---

### Enhancement Stat Increase

```
EnhancedStat = BaseItemStat × (1 + (EnhancementLevel × EnhancementBonusPerLevel))
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| BaseItemStat | int or float | From ItemEquipmentSO | Base stat of the item (after rarity multiplier) |
| EnhancementLevel | int | 0–10 | EquipmentInstance | Current enhancement level (0 = unenhanced) |
| EnhancementBonusPerLevel | float | 0.03–0.08 (3%–8%) | ItemEquipmentSO.EnhancementGrowth | Per-level stat increase (tuned per item) |

**Example**: Epic sword (base ATK 150), EnhancementLevel 5, EnhancementGrowth 5%:
- Enhanced ATK = 150 × (1 + (5 × 0.05)) = 150 × 1.25 = **187.5 ATK**

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Equipment percentage bonuses exceed 50% cap | Cap at 50%; log a warning in the console; excess bonus is ignored. The Inventory UI displays a "Stat Cap Reached" indicator on the offending item. | Prevents stat inflation from breaking combat balance; warning helps data authors debug |
| Character level drops below item's RequiredLevel (curse, death penalty) | Item stays equipped but all stat bonuses from it are disabled (greyed-out in HUD). Stats re-activate when character re-meets the level requirement. | Prevents exploit of equipping high-level gear then dropping level to bypass restrictions |
| Equipment item has a null or invalid field (data authoring error) | Log an error at scene load; use a zero-value fallback stat block (all bonuses = 0); item is still equippable but provides no stats. Flag the item in a data validation report for the team. | Null items must never crash the game; zero fallback is safe and debuggable |
| Enhanced equipment item is sold to a shop | Enhancement level is reset to 0; sell value = BaseGoldValue + (EnhancementLevel × `ItemMaterialSO.BaseGoldCost` × 0.30). Player recovers 30% of the gold spent on materials. | Prevents enhancement from being a total loss; 30% refund feels fair without making sell-and-repurchase profitable |
| Equipment durability reaches 0 mid-combat | Item is unequipped automatically; all stat bonuses are removed immediately; item is greyed-out in inventory with a "Broken" tag. Combat continues without pause. | Broken equipment mid-fight creates tension; auto-unequip prevents stat confusion |
| Player attempts to equip two items in the same slot | Second item replaces the first; first item returns to inventory. No equip animation plays for the swap. | Simple, unambiguous behavior; player always knows what's active |
| Two special effects trigger simultaneously (e.g., "Lifesteal on hit" and "+10 MP on kill" on same hit that kills an enemy) | Both effects fire in slot order: Weapon → Armor → Helmet → Accessory → Relic. Effects are resolved sequentially, not in parallel. | Deterministic ordering prevents race conditions and makes debugging reproducible |
| Consumable used on a dead character with Revive effect | Character is revived with HP = EffectValue% of MaxHP (not a flat amount). If EffectValue is > 100%, cap at 100%. | Revive must restore to a meaningful state; over-healing on revive is wasteful but not harmful |
| Enhancement material used on an item of mismatched tier | Operation fails; material is not consumed; a tooltip explains the tier mismatch. | Prevents accidental material waste; clear feedback to player |
| Item database file is missing or corrupted at scene load | Log a critical error; fall back to a minimal hardcoded item set (1 Common weapon, 1 Common armor per character class); display a "Data Load Error" banner in the HUD. | Game must remain playable even with data corruption; fallback is minimal but functional |
| Key item added to inventory that already contains it | Duplicate is silently discarded. Key items are unique-per-character. | Prevents inventory clutter from duplicate quest items |
| Character dies while an equipment enhancement is in-progress (UI animation) | Enhancement completes instantly at the moment of death; stats are applied before the death state is processed. | Prevents enhancement state corruption during death transition |

## Dependencies

| System | Direction | Nature | What Flows Between Them |
|--------|-----------|--------|------------------------|
| **Character Data** | Depended on by Item Database | Soft | Item Database reads CharacterClass enum to define class restrictions; Item Database does not modify Character Data |
| **Inventory & Equipment System** | Depends on Item Database | Hard | Reads item definitions (stats, icons, names); writes EquipmentInstance state (equipped flag, enhancement level, durability) |
| **Loot & Drop System** | Depends on Item Database | Hard | Reads item rarity, class restrictions, required level, and drop pool membership to filter valid drops per encounter |
| **Shop System** | Depends on Item Database | Hard | Reads BaseGoldValue formula inputs (rarity, required level, stat bonuses) to calculate buy/sell prices |
| **Equipment Enhancement System** | Depends on Item Database | Hard | Reads EnhancementTier compatibility and EnhancementGrowth per item; writes EquipmentInstance.EnhancementLevel |
| **Item Rarity System** | Embedded in Item Database | N/A | Rarity is a property of every item ScriptableObject; not a separate system at runtime |
| **Combat System** | Reads Item Database (via Inventory) | Soft | Reads effective stat bonuses from equipped items; does not modify item state |
| **Health & Damage System** | Reads Item Database (via Inventory) | Soft | Reads DEF and MaxHP bonuses from equipped items for damage calculation |
| **Skill Execution System** | Reads Item Database (via Inventory) | Soft | Reads SPD and CRIT bonuses from equipped items for skill timing and crit calculation |
| **Save / Load System** | Depends on Item Database | Hard | Serializes EquipmentInstance state (IsEquipped, EnhancementLevel, Durability) per item instance; reads item GUIDs from ScriptableObjects |

**No upstream dependencies**: Item Database is a foundation root — it depends on no other system for its definition. The only soft dependency is reading the CharacterClass enum from Character Data, which is a shared data type, not a system dependency.

## Tuning Knobs

| Parameter | Current Value | Safe Range | Effect if Too High | Effect if Too Low |
|-----------|--------------|------------|-------------------|-------------------|
| **Rarity Stat Multipliers** | Common 1.0x, Uncommon 1.25x, Rare 1.50x, Epic 2.0x, Legendary 2.5x | ±0.25x per tier | Epic/Legendary items trivialize content; Common items feel worthless | Rarity differences become imperceptible; loot feels unrewarding |
| **Equipment Percentage Bonus Cap** | 50% total | 30%–80% | Stats balloon; combat math breaks; damage formulas overflow | Equipment feels irrelevant; players ignore stat optimization |
| **Durability Loss Per Hit** | 1 (Armor/Helmet only) | 0–2 | Items break constantly; repair costs drain player gold; frustration | Items never break; durability system is ignored; no tension |
| **Durability Loss On Death** | 10 (flat) | 5–20 | Death penalty feels punishing; players avoid challenging content | Death has no consequence; players don't fear failure |
| **Enhancement Bonus Per Level** | 3%–8% per level (per item) | 2%–12% per level | Enhanced items outclass base items; enhancement feels mandatory | Enhancement not worth the material cost; players ignore the system |
| **Enhancement Level Cap** | 10 | 5–15 | Enhancement becomes a grind; material sink frustrates players | Enhancement feels trivial; no long-term investment goal |
| **Base Stat Ranges Per Equipment** | See Formulas section | ±20% of current values | Items overshadow character growth; character identity lost | Items feel like filler; no excitement from loot drops |
| **Item Gold Value Formula** | (ReqLevel × 10) × RarityMult × (1 + StatBonus%/100) | Coefficients adjustable | Shop economy inflates; gold becomes meaningless or overwhelming | Shop prices feel arbitrary; players can't afford upgrades |
| **Shop Buy/Sell Ratio** | Sell 100%, Buy 40% | Buy 25%–60% | Players exploit shop for gold farming or can't afford anything | Economy breaks; players hoard or dump items without thought |
| **RequiredLevel gating** | 1–30 (matches level cap) | Must not exceed level cap | Items permanently unusable; player frustration | All items available early; progression gating fails |
| **Special Effect Trigger Rate** | Per-item authored (typically 5%–20% on hit/kill) | 3%–30% | Effects proc constantly; combat becomes random and unpredictable | Effects never proc; special effects feel like a lie |
| **Drop Frequency By Rarity** | Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1% | ±10% per tier | Players drown in Legendaries (no excitement) or never see one (no hope) | Loot distribution feels rigged or meaningless |

**Interacting Knobs**:
- **Rarity Multiplier + Base Stat Ranges**: Increasing rarity multipliers without adjusting base stat ranges causes late-game item power creep
- **Enhancement Bonus + Enhancement Cap**: Higher per-level bonuses make the cap arrive faster; these must be tuned together
- **Durability Loss + Repair Cost**: Repair cost (defined in Village/Hub System) must scale with durability loss rate; otherwise repair is either too cheap or too expensive

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| **Item drop (Common)** | White glow beam from defeated enemy; small floating item icon | Soft metallic "clink" pickup sound | High |
| **Item drop (Uncommon)** | Green glow beam; slightly larger item icon | Brighter "clink" with ascending tone | High |
| **Item drop (Rare)** | Blue glow beam; item icon pulses twice | Distinctive "whoosh + chime" — recognizable as "good drop" | High |
| **Item drop (Epic)** | Purple glow beam; item icon orbits with sparkles | Dramatic ascending chord — players turn to look | High |
| **Item drop (Legendary)** | Gold glow beam; item icon erupts with particles; screen shake (subtle) | Full orchestral hit + choir — the most memorable drop sound in the game | Critical |
| **Equipment equipped** | Stat numbers animate upward on character sheet; slot icon highlights | Soft "lock-in" sound (like a click satisfying) | Medium |
| **Equipment unequipped** | Stat numbers animate downward; slot icon dims | Soft "release" sound | Low |
| **Enhancement success (levels 1–5)** | Item icon glows; "+1" text appears; small particle burst | Pleasant ascending chime | Medium |
| **Enhancement success (levels 6–10)** | Item icon ignites; larger particle burst; "+1" text is gold | Powerful ascending chord — feels like a milestone | High |
| **Enhancement failure (tier mismatch)** | Red X over item; tooltip slides in | Error "buzz" — clear failure feedback | Medium |
| **Equipment breaks (durability = 0)** | Icon cracks with a fissure effect; greyed-out overlay; "Broken" tag appears | Sharp "crack" sound followed by a dull thud | High |
| **Equipment repaired** | Crack effect reverses; icon returns to full color | Satisfying "repair" sound (like metal reforming) | Medium |

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Item name + icon | Inventory grid, loot drop popup, equipment slot HUD | Static (never changes) | Always visible when inventory/equipment screen is open |
| Item rarity (color-coded border) | Inventory grid, loot drop popup, equipment slot HUD | Static | Always visible; color matches rarity tier (white/green/blue/purple/gold) |
| Stat bonuses (flat + percentage) | Item detail tooltip (hover/click in inventory) | Static | Always visible when item detail is open |
| RequiredLevel + CharacterClass restriction | Item detail tooltip | Static | Greyed-out text if character doesn't meet requirements |
| Equipped status (which character, which slot) | Item detail tooltip; equipment slot HUD | On equip/unequip | Shows "Equipped by [Character] — [Slot]" or "Not Equipped" |
| Enhancement level (+0 to +10) | Item icon overlay (bottom-right corner); item detail tooltip | On enhancement | Displays as "+N" badge on icon |
| Durability bar (0–100) | Item detail tooltip; low durability warning (<20) on icon | Every durability change | Bar color: green (>50), yellow (20–50), red (<20) |
| "Broken" tag | Inventory icon overlay | When durability = 0 | Greyed-out icon with crack effect |
| Special effects list | Item detail tooltip (expandable section) | Static | Shows trigger condition and effect (e.g., "On Hit: Lifesteal 5%") |
| Stat Cap Reached indicator | Item detail tooltip | When total percentage bonuses ≥ 50% | Red warning icon with tooltip text |
| Item comparison (equipped vs. hovered) | Side-by-side stat diff in tooltip when hovering item in inventory | On hover | Shows "+X ATK" in green or "-Y DEF" in red vs. currently equipped item |
| Enhancement material compatibility | Green check or red X on material when used on incompatible item | On enhancement attempt | Tooltip explains tier mismatch |

## Acceptance Criteria

- [ ] All four ScriptableObject types (`ItemEquipmentSO`, `ItemConsumableSO`, `ItemKeySO`, `ItemMaterialSO`) can be created in the Unity Editor and saved as `.asset` files
- [ ] Equipment items correctly enforce CharacterClass restrictions — a Mage-only staff cannot be equipped by an Archer character (verified by unit test)
- [ ] RequiredLevel gating works — a Level 5 character cannot equip a Level 15 sword (verified by unit test)
- [ ] Effective stat calculation formula produces correct results: `(BaseStat + FlatBonus) × (1 + PercentageBonus)` — verified by unit test with known inputs
- [ ] Equipment percentage bonus cap at 50% is enforced — equipping items that would exceed 50% logs a warning and caps the bonus (verified by unit test)
- [ ] Rarity multipliers produce correct stat ranges: Common 1.0x, Uncommon 1.25x, Rare 1.5x, Epic 2.0x, Legendary 2.5x — verified by unit test
- [ ] Item gold value formula produces correct results: `(ReqLevel × 10) × RarityMult × (1 + StatBonus%/100)` — verified by unit test
- [ ] Equipment durability decreases on hit (Armor/Helmet only) and on death; items unequip automatically at durability = 0 (verified by integration test)
- [ ] Enhancement system correctly increases stats: `EnhancedStat = BaseItemStat × (1 + (EnhancementLevel × EnhancementBonusPerLevel))` — verified by unit test
- [ ] Enhancement material tier mismatch fails gracefully — material is not consumed, tooltip is shown (verified by integration test)
- [ ] Selling an enhanced item to shop resets enhancement level and refunds 30% of material cost (verified by integration test)
- [ ] Null or invalid item fields log errors at scene load and use zero-value fallback stats without crashing (verified by unit test)
- [ ] Key items cannot be sold, dropped, or consumed — they are permanently owned once acquired (verified by unit test)
- [ ] Consumable items correctly apply their effect type (RestoreHP, RestoreMP, Buff, Revive, Cleanse) to the correct target scope (verified by integration test)
- [ ] Performance: reading item ScriptableObject fields adds no measurable frame time (< 0.01ms per item lookup); loading 100 items at scene load takes < 50ms
- [ ] Save/Load correctly serializes and deserializes EquipmentInstance state (IsEquipped, EnhancementLevel, Durability) — verified by round-trip test

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| How many unique equipment items will exist per character class? (e.g., 10 Mage staffs, 8 Archer bows?) | Game Designer / Economy Designer | Resolve before loot table authoring begins — affects total number of ItemEquipmentSO assets to author |
| Should Relic items be truly unique (one per character, narrative-specific) or can multiple characters share a Relic pool? | Game Designer / Narrative Director | Resolve before Relic items are authored — affects narrative weight and loot distribution |
| Does durability loss feel punishing or engaging to players? Should the rate be tuned based on playtest feedback? | QA Lead / Game Designer | Resolve after first playtest of MVP combat — may require adjustment |
| What is the gold income rate per encounter? (Needed to validate shop prices and enhancement material costs) | Economy Designer | Resolve in Economy/Loot & Drop GDD — depends on encounter design |
| Should enhancement materials be purchasable in shops, or only found as loot? | Economy Designer | Resolve before Shop System GDD is authored — affects shop inventory design |
| Are there equipment set bonuses? (e.g., "Equip 3 pieces of the Fire Set: +20% ATK") | Game Designer | Resolve after core equipment system is implemented — set bonuses are a Full Vision enhancement |
| How many consumable item types are needed for MVP? (Potions, revives, buffs — which are essential for Witch prologue + Ch 1–2?) | Game Designer | Resolve before consumable data authoring — affects ItemConsumableSO asset count |
