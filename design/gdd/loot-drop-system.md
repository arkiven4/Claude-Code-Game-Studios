# Loot & Drop System

> **Status**: Approved
> **Author**: Design session 2026-04-04 (user-directed)
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (loot is how you invest in your companions)

## Overview

The Loot & Drop System determines what items enemies drop when defeated, how those items
enter the party's possession, and how the player distributes them. On enemy death, the
system rolls against the encounter's loot table to determine drops. Drops are split into
two pools: **50% class-weighted** (filtered to match the classes of currently alive
party members) and **50% wildcard** (any item from the full loot table, regardless of
class). Dropped items and gold go into a **shared party pool** — a temporary holding
area presented to the player after each encounter. The player manually distributes items
from the pool into the party inventory. Gold is automatically added to the party's total.
The system reads from the Item Database for item definitions, rarity, and class
restrictions, and writes to the Inventory & Equipment System when the player assigns
drops.

## Player Fantasy

Loot & Drop serves the fantasy of **the hunt that pays off**. Every encounter ends with
a moment of anticipation — what did we get? The class-weighted pool means most drops are
useful to someone in your party, so you rarely get junk. The wildcard pool adds surprise
— sometimes you'll find a Tanker sword when you have no Tanker, and that tells you
"maybe you should bring a Tanker next chapter." The shared pool + manual distribution
makes loot feel communal — the party found this together, and you decide who needs it
most. Gold drops feel like a bonus on top of the items — a small victory pile.

**Reference model**: Fire Emblem's post-battle item distribution (shared loot, manual
assign) and World of Warcraft's need/greed rolling spirit (everyone gets a say, but
someone decides).

## Detailed Rules

### Core Rules

1. **Loot Table Definition**: Each enemy and encounter has a loot table defined as a
   Resource (`LootTable`):
   ```
   LootTable fields:
   ┌─────────────────────────────────────────────────┐
   | LootTableId: string (unique identifier)          |
   | GuaranteedDrops: DropEntry[]                     |
   | ChanceDrops: DropEntry[]                         |
   | GoldMin: int                                     |
   | GoldMax: int                                     |
   | BossLootTable: bool (true for boss enemies)      |
   └─────────────────────────────────────────────────┘

   DropEntry:
   ┌─────────────────────────────────────────────────┐
   | ItemRef: Resource reference              |
   | DropChance: float (0.0–1.0)                      |
   | MinQuantity: int (default 1)                     |
   | MaxQuantity: int (default 1)                     |
   | RarityWeight: float (affects rarity roll)         |
   └─────────────────────────────────────────────────┘
   ```

2. **Drop Roll Process** (executed on each enemy death):
   - **Step 1**: Process all `GuaranteedDrops` — these items always drop
   - **Step 2**: For each `ChanceDrop`, roll `Random(0.0, 1.0) ≤ DropChance`. If the
     roll succeeds, the item is marked for dropping
   - **Step 3**: For each marked drop, determine the **specific item instance** by
     rolling rarity based on `RarityWeight` (see Rule 3)
   - **Step 4**: Determine the **quantity** via `Random(MinQuantity, MaxQuantity)`
   - **Step 5**: Roll gold via `Random(GoldMin, GoldMax)`
   - **Step 6**: Apply the **class-weighted / wildcard split** (see Rule 4)

3. **Rarity Roll**: When an item drops, its specific rarity variant is determined by
   rolling against the global rarity distribution, modified by the enemy's
   `RarityWeight`:
   | Rarity | Base Chance | Adjusted Chance |
   |--------|------------|-----------------|
   | Common | 50% | `50%` (unchanged) |
   | Uncommon | 30% | `30%` (unchanged) |
   | Rare | 15% | `15% × RarityWeight` |
   | Epic | 4% | `4% × RarityWeight` |
   | Legendary | 1% | `1% × RarityWeight` |

   `RarityWeight` multiplies only the Rare, Epic, and Legendary tiers. Common and Uncommon
   are left at their base values. All five values are then summed and each is divided by the
   total to normalize to 100%.

   **Example** with `RarityWeight = 2.0`: Rare → 30, Epic → 8, Legendary → 2, Common → 50,
   Uncommon → 30. Sum = 120. Normalized: Common ≈ 41.7%, Uncommon ≈ 25%, Rare ≈ 25%,
   Epic ≈ 6.7%, Legendary ≈ 1.7%.

   A weight of 1.0 = base distribution. A weight of 2.0 ≈ doubles Rare+ representation.
   A weight of 0.5 ≈ halves it (Common/Uncommon absorb the released probability).

4. **Class-Weighted / Wildcard Split**: After the drop roll determines WHAT items drop,
   the system splits the results:
   - **50% class-weighted pool**: For each dropped item, the system checks if it has a
     class restriction. If the item's class matches ANY alive party member's class, the
     item enters the class-weighted pool. If the item is `Any`-class, it also enters
     this pool. Items whose class does NOT match any alive party member are re-rolled
     from the class-weighted sub-table (items that match at least one party member's
     class).
   - **50% wildcard pool**: These drops are NOT filtered. Any item can drop, including
     items that no current party member can equip. This is intentional — it tells the
     player about future options.

   The split is applied per-item: each item independently has a 50% chance of being
   in the class-weighted pool vs. wildcard pool.

   **Example**: Party has Evelyn (Mage) and Evan (Swordman). Enemy drops 4 items:
   - Item A (Mage staff) → class-weighted pool (matches Evelyn)
   - Item B (Tanker shield) → re-rolled from class-weighted sub-table → new drop is
     Archer bow → class-weighted pool (matches Evan)
   - Item C (Healer staff) → wildcard pool (no filter, could be anything)
   - Item D (gold) → automatically added to party total

5. **Shared Party Pool (Post-Encounter Loot Screen)**:
   After an encounter completes, the Loot & Drop System presents a **Loot Distribution
   Screen** before the player returns to exploration:
   ```
   ┌──────────────────────────────────────────────────────────┐
   │              ENCOUNTER COMPLETE                          │
   │                                                          │
   │  ┌─────────────────────────┐    ┌────────────────────┐  │
   │  │  Drops:                  │    │  Assign to:        │  │
   │  │                          │    │                    │  │
   │  │  [Mage Staff] (Rare)     │───▶│  ▶ Evelyn (Mage)  │  │
   │  │  [Archer Bow] (Uncommon) │    │  ▶ Evan (Swordman)│  │
   │  │  [Healer Staff] (Common) │    │  ▶ Archer A       │  │
   │  │  [Health Potion ×3]      │    │  ▶ Tanker T       │  │
   │  │                          │    │  ▶ [Inventory]    │  │
   │  │                          │    │  (stash for later)│  │
   │  └─────────────────────────┘    └────────────────────┘  │
   │                                                          │
   │  Gold earned: 247                                        │
   │                                                          │
   │                    [Done]                                │
   └──────────────────────────────────────────────────────────┘
   ```
   - Each drop item is listed on the left with rarity-colored border
   - Player selects a drop, then selects a recipient on the right
   - **"Inventory"** option sends the item directly to the shared inventory without
     assigning to a specific character (useful for consumables and materials)
   - **"Done"** is only enabled when all drops have been assigned
   - Consumables and materials default to "Inventory" (no character needed)
   - Gold is automatically added — not assignable

6. **Gold Drops**:
   - Gold is dropped separately from items
   - Amount: `Random(GoldMin, GoldMax)` from the enemy's loot table
   - Gold is automatically added to the party's shared gold total
   - No player interaction required for gold
   - Gold is tracked by the Inventory & Equipment System as a party-level resource

7. **Boss Loot**:
   - Boss enemies have their own `LootTable` marked with `BossLootTable = true`
   - Boss drops are guaranteed (not chance-based)
   - Boss drops include at least one Rare-or-higher item
   - Boss drops are always class-weighted (no wildcard) — they're intended rewards
   - Boss encounters also trigger a cutscene (Cutscene System) that may narratively
     explain the drop ("You found the Witch's Amulet...")

8. **No Duplicate Equipment Instances**: When the same item drops twice (e.g., two
   enemies both drop a "Mage Sword"), each drop is a separate `EquipmentInstance` with
   its own enhancement level (0), durability (100), and equipped state. They are not
   stacked.

9. **Loot Table Inheritance**: Encounter-level loot tables can inherit from enemy-level
   loot tables. A story encounter defines its own loot table that includes the loot
   tables of all enemies in the encounter, plus encounter-specific guaranteed drops
   (e.g., a key item that advances the plot).

10. **Loot Visibility**: The player sees what dropped during combat as floating loot
    icons above defeated enemies. After the encounter, the Loot Distribution Screen
    presents the full list. No loot is hidden or secret.

### States and Transitions

```
┌─────────────┐  enemy dies   ┌──────────────────┐
│  Combat     │ ────────────▶ │  Loot Roll       │
│  Active     │               │  (per enemy)     │
└─────────────┘               └────────┬─────────┘
                                       │
                                       ▼
                              ┌──────────────────┐
                              │  Class/Wildcard  │
                              │  Split           │
                              └────────┬─────────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
             Class-Weighted      Wildcard Pool      Gold (auto)
             Pool (filtered)     (any item)
                    │                  │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Shared Party    │
                    │  Pool            │
                    │  (pending assign)│
                    └────────┬─────────┘
                             │ player distributes
                             ▼
                    ┌──────────────────┐
                    │  Inventory &     │
                    │  Equipment       │
                    │  (items stored)  │
                    └──────────────────┘
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Item Database** | Reads | Reads item definitions, rarity, class restrictions, gold value |
| **Character Data** | Reads | Reads party member classes for class-weighted filtering |
| **Enemy AI** | Reads | Reads enemy loot table reference on death |
| **Inventory & Equipment** | Writes to | Adds distributed items to inventory stacks |
| **Combat System** | Read by | Combat complete triggers loot roll and distribution screen |
| **Audio System** | Calls | Triggers rarity-appropriate drop sounds per item |
| **Combat HUD** | Calls | Shows floating loot icons above defeated enemies |
| **Cutscene System** | Called by | Boss death cutscenes may narratively reference the drop |
| **Save / Load** | Serialized by | Party gold total and inventory state persist |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `DropCount` | `BaseDrops + floor(rand_float() * BonusDropRange)` | `BaseDrops` = min guaranteed drops; `BonusDropRange` = extra possible drops (default 2); e.g., BaseDrops=1, Range=2 → 1–2 drops |
| `DropRoll` | `Random(0.0, 1.0) ≤ DropChance` | Per chance-based drop entry |
| `RarityChance(R)` | Rare/Epic/Legendary: `BaseChance(R) × RarityWeight`; Common/Uncommon: `BaseChance(R)`; all normalized to 100% | Rarity determination |
| `GoldAmount` | `Random(GoldMin, GoldMax)` | Per enemy |
| `ClassWeightedCheck` | `item.Class IN {alive party member classes} OR item.Class == Any` | Class-weighted pool filter |
| `SplitPool` | `50% class-weighted, 50% wildcard per item` | Independent per drop |
| `BossDropGuaranteed` | `always drops, Rare+ minimum` | Boss-specific rule |

## Edge Cases

1. **All party members share the same class**: The class-weighted pool only contains
   items for that class. The wildcard pool still provides variety. The player may see
   many similar drops — this is a consequence of a homogeneous party composition.

2. **Only one party member is alive**: The class-weighted pool only filters for that
   one member's class. Drops may be very narrow. The wildcard pool compensates by
   providing any item.

3. **Loot Distribution Screen closed without assigning all items**: The "Done" button
   is disabled until all items are assigned. The player cannot skip this screen. Items
   remain in the shared pool. This is intentional — loot distribution is mandatory.

4. **Inventory is full during loot distribution**: The player can still assign items
   to character equipment slots (which doesn't consume inventory space). Items assigned
   to "Inventory" when the inventory is full are rejected with a warning. The player
   must assign those items to characters instead.

5. **Two identical equipment items drop**: Each is a separate EquipmentInstance. They
   appear as two separate entries in the loot distribution screen. The player can assign
   them to different characters (if class allows) or the same character (if the character
   has multiple of the same slot — but they can only equip one per slot).

6. **Enemy dies but loot table is null**: No items drop. Gold is still rolled if GoldMin
   or GoldMax is set. A warning is logged for the content team.

7. **Boss drop references an item that doesn't exist**: The boss drop is skipped. A
   critical error is logged. The boss death cutscene still plays. The player misses
   the reward — this is a content authoring error.

8. **Player disconnects or crashes during loot distribution**: The shared pool state
   is NOT saved mid-distribution. On reload, the encounter is replayed and loot is
   re-rolled. This is acceptable — loot distribution is a brief screen and crashes
   are rare.

9. **Consumables or materials remain unassigned when inventory is full**: Equipment items
   can always be assigned to a character's equipment slot (bypassing inventory space), but
   consumables and materials can only go to the shared inventory. If all remaining unassigned
   items are consumables/materials and the inventory is full, the "Done" button remains
   blocked. In this state, a **Discard** button appears next to each stuck item, allowing
   the player to remove it from the pool. The player must either discard the item or open
   the Pause Menu to free inventory space before they can complete distribution. Items
   pending discard show a confirmation tooltip: "Discard [item name]? This cannot be undone."

## Dependencies

- **Depends on**: Item Database (item definitions, rarity, gold value), Character Data
  (party classes), Enemy AI (enemy loot tables on death)
- **Depended on by**: Inventory & Equipment (receives distributed items), Audio System
  (drop sounds), Combat HUD (floating loot display), Cutscene System (boss drop narration),
  Save / Load (gold total persistence)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `ClassWeightedPercent` | float | `0.50` | 50% of drops are class-filtered |
| `RarityDistribution` | table | Common 50%, Uncommon 30%, Rare 15%, Epic 4%, Legendary 1% | Base rarity chances |
| `BossMinRarity` | enum | `Rare` | Boss drops are at least Rare |
| `BossDropGuaranteed` | bool | `true` | Boss drops are never chance-based |

## Visual/Audio Requirements

- **Floating Loot Icons**: During combat, defeated enemies show floating item icons
  above their body with a glow beam matching the item's rarity (white/green/blue/purple/gold).
- **Loot Distribution Screen**: Full-screen overlay post-encounter with item list on
  left and character selector on the right.
- **Drop Sounds**: Per-rarity drop sounds as defined in the Item Database GDD (Common =
  soft clink, Legendary = orchestral hit + choir).
- **Gold Notification**: "Gold +247" text floats upward at encounter end.

## UI Requirements

- **Loot Distribution Screen**: See layout in Rule 5. Item list with rarity borders,
  character selector, inventory option, gold total, and Done button.
- **Floating Loot Icons**: World-space icons above dead enemies during combat. Visible
  for 3s after enemy death, then fade out (the Loot Distribution Screen takes over).
- **Gold Display**: Party gold total shown in the Inventory UI and Pause Menu. Format:
  "Gold: 1,247" with comma separation for readability.

## Acceptance Criteria

- [ ] Loot roll processes guaranteed drops and chance drops correctly per enemy death
- [ ] Rarity roll applies RarityWeight modifier and normalizes correctly
- [ ] Class-weighted pool only contains items matching alive party member classes (or Any-class)
- [ ] Wildcard pool contains any item from the full loot table without filtering
- [ ] Each dropped item has a 50/50 chance of being in class-weighted vs wildcard pool
- [ ] Items that fail class-weighted filter are re-rolled from the class-weighted sub-table
- [ ] Gold drops are calculated per enemy and added to party total automatically
- [ ] Boss drops are guaranteed, class-weighted only, and at least Rare rarity
- [ ] Loot Distribution Screen presents all drops for manual assignment
- [ ] "Done" button is disabled until all drops are assigned
- [ ] Consumables and materials default to "Inventory" in the distribution screen
- [ ] Identical equipment drops are separate EquipmentInstances (not stacked)
- [ ] Inventory-full during loot distribution allows character equip but rejects inventory stash
- [ ] Null enemy loot tables do not crash the game (warn and skip)
- [ ] Floating loot icons display during combat with correct rarity colors

## Open Questions

- Should the player be able to "auto-distribute" loot (assign items to matching-class
  characters automatically) for convenience? This would be a button on the Loot
  Distribution Screen. Recommendation: yes, as an optional shortcut — the player can
  still manually override.
- Should loot drops scale with the party's average level? Higher-level parties facing
  the same encounter would get better drops. This rewards progression but complicates
  the loot table. Recommendation: no for MVP — loot tables are fixed per enemy.
- Should there be a "first encounter bonus" (extra loot the first time you defeat a
  specific enemy type)? This would reward exploration and prevent farming. Recommendation:
  yes, as a tuning knob — 10% extra drop chance on first kill.
