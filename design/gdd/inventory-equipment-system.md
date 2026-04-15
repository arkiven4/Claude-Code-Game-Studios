# Inventory & Equipment System

> **Status**: Approved
> **Author**: Design session 2026-04-04 (user-directed)
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (equipment is how you invest in each companion)

## Overview

The Inventory & Equipment System manages all items the party owns and equips. The
inventory is **stack-based**: consumables stack by type (99 potions = 1 stack), equipment
items each occupy one inventory entry, and key/material items stack by type. There is no
grid or spatial puzzle — the inventory is a categorized list the player scrolls through.
Each of the up to 4 party members has **5 equipment slots** (Weapon, Armor, Helmet,
Accessory, Relic) defined by the Item Database. Equipping validates both the character's
class and level against the item's restrictions. Consumable items can be used both in
combat and during exploration. The system exposes its state to the Combat HUD, Health &
Damage System (for equipment stat bonuses), and Save / Load System. All inventory data
is a runtime state container — it reads from Item Resources but never writes to
them.

## Player Fantasy

Inventory & Equipment serves the fantasy of **finding the perfect piece for the right
person**. When a Rare Mage staff drops and the player immediately thinks "Evelyn needs
this," the inventory lets them act on that instinct fast. No Tetris puzzle, no managing
encumbrance — just: open inventory, see what you have, equip what works, go. The stack-
based design keeps the inventory clean and readable. The player scrolls, sees "Health
Potion ×12" and "Evan's Longsword +3," and knows exactly where they stand. Equipment
feels permanent and meaningful — you don't swap gear every encounter, you find something
good and carry it for chapters.

**Reference model**: Final Fantasy X's Sphere Grid (equipment is a permanent investment,
not a disposable commodity) and Fire Emblem's clean inventory list (categorized, no
spatial management).

## Detailed Rules

### Core Rules

1. **Stack-Based Inventory**: The inventory is a list of `InventoryStack` entries:
   ```
   InventoryStack:
   ┌─────────────────────────────────────────────────┐
   | ItemRef: Resource reference              |
   | ItemType: enum (Equipment, Consumable, Key, Mat)|
   | Quantity: int                                    |
   | EquipmentData: EquipmentInstance? (if Equipment) |
   └─────────────────────────────────────────────────┘
   ```
   - **Equipment items**: Quantity is always 1. Each unique equipment piece is its own
     stack entry with an `EquipmentInstance` tracking its equipped state, enhancement
     level, and durability.
   - **Consumable items**: Stack up to 99. Identical consumables (same `ItemConsumable`)
     merge into one stack.
   - **Key items**: Quantity is always 1. Cannot be dropped, sold, or consumed.
   - **Material items**: Stack up to 99. Identical materials merge.

2. **Inventory Capacity**: The inventory holds up to **200 stack entries**. This is
   shared across the entire party (not per-character). When the inventory is full:
   - New loot cannot be collected until space is freed
   - A "Inventory Full" notification appears
   - The player must consume, sell, or discard items to make room

3. **Equipment Slots Per Character**: Each party member has exactly 5 slots:
   | Slot | Purpose | Example Restrictions |
   |------|---------|---------------------|
   | `Weapon` | Primary damage output | Mage-only staff, Swordman-only sword |
   | `Armor` | Damage mitigation | Any-class robe, Tanker-only plate |
   | `Helmet` | Defensive stat modifier | Any-class hood, Mage-only crown |
   | `Accessory` | Utility and percentage bonuses | Any-class ring, class-specific charm |
   | `Relic` | Unique character-specific item | Evelyn's Cursed Pendant, Evan's Hunter Badge |

   All 5 slots are available from the start. No slots are locked or need unlocking.

4. **Equip Restrictions**: An item can be equipped on a character only if:
   - **Class match**: The item's `CharacterClass` restriction matches the character's
     class, OR the item is marked as `Any` (equippable by all classes)
   - **Level match**: The character's current level is ≥ the item's `RequiredLevel`
   - **Slot availability**: The target slot is not already occupied (equipping replaces)

   If either restriction fails, the item cannot be equipped. The inventory UI greys
   it out with a tooltip explaining which restriction failed ("Requires Level 15 Mage"
   or "Requires Tanker class").

5. **Equip/Unequip Flow**:
   - **Equip**: Player selects an equipment item → selects a party member → validates
     restrictions → if valid, the item moves from the inventory stack to the character's
     slot. If the slot was already occupied, the previous item returns to the inventory.
   - **Unequip**: Player selects an equipped item → unequips → the item returns to the
     inventory as a new stack entry.
   - **Swap**: Player selects a new item for an occupied slot → the old item returns
     to inventory, the new item takes the slot. One atomic operation.

6. **Consumable Usage**:
   - **In combat**: Consumables are activated via a skill-equivalent action. The player
     selects a consumable from their inventory (or a dedicated consumable slot in the
     Combat HUD) and applies it to a valid target. Consumable use consumes a combat
     action (uses the character's turn / occupies the skill input during the combat
     action window).
   - **Out of combat**: Consumables can be used freely from the inventory menu at any
     time during exploration. No combat action cost.
   - **Stack decrement**: Each use reduces the stack quantity by 1. When quantity reaches
     0, the stack is removed from the inventory.

7. **Effective Stat Aggregation** (equipment bonuses applied to characters):
   ```
   EffectiveStat = (BaseStat + EquipmentFlatBonus) × (1 + min(EquipmentPercentageBonus, 0.50))
   ```
   This formula is defined in the Item Database GDD. The Inventory & Equipment System
   is responsible for providing the `EquipmentFlatBonus` and `EquipmentPercentageBonus`
   values by summing all 5 equipped items' bonuses. The Health & Damage System and
   Skill Execution System read these effective stats during combat.

8. **Equipment State Persistence**: Each `EquipmentInstance` tracks:
   | Field | Type | Default | Description |
   |-------|------|---------|-------------|
   | `IsEquipped` | bool | false | True when equipped on a character |
   | `EquippedOn` | CharacterData ref | null | Which character this is equipped on |
   | `EnhancementLevel` | int | 0 | Current enhancement level (0–10) |
   | `Durability` | int | 100 | Current durability (0 = broken) |

   This state is saved and loaded by the Save / Load System.

9. **Inventory Operations** (no combat state dependency):
   | Operation | In Combat | Out of Combat |
   |-----------|-----------|---------------|
   | View inventory | Yes (via pause menu) | Yes |
   | Equip/unequip | Yes (via pause menu) | Yes |
   | Use consumable | Yes (costs combat action) | Yes (free) |
   | Sell items | No | Yes (at shop / village) |
   | Discard items | No | Yes |
   | Sort inventory | No | Yes |

10. **Durability in Combat**: When Armor or Helmet equipment durability reaches 0
    mid-combat:
    - The item is auto-unequipped
    - All stat bonuses from that item are immediately removed
    - The Combat HUD updates within 1 frame
    - The item is marked "Broken" in the inventory
    - The player cannot re-equip it until repaired (at a shop/village)

### States and Transitions

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Inventory (Runtime State)                      │
│                                                                       │
│  ┌─────────────────┐    ┌──────────────────────────────────────────┐ │
│  │  InventoryStacks│    │         Equipment Slots (per character)  │ │
│  │  (list of ≤200) │    │                                          │ │
│  │                 │    │  ┌────────┐ ┌──────┐ ┌────────┐        │ │
│  │  Equipment ×N   │    │  │ Weapon │ │Armor │ │Helmet  │        │ │
│  │  Consumable ×M  │    │  │  (item)│ │(item)│ │ (item) │        │ │
│  │  Key ×K         │    │  └────────┘ └──────┘ └────────┘        │ │
│  │  Material ×L    │    │  ┌────────┐ ┌──────┐                    │ │
│  │                 │    │  │Accessory│ │Relic │                    │ │
│  │  Each stack:    │    │  │ (item)  │ │(item)│                    │ │
│  │  ItemRef, Qty,  │    │  └────────┘ └──────┘                    │ │
│  │  InstanceData?  │    │                                          │ │
│  └─────────────────┘    └──────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘

Transitions:
  Loot acquired     → New stack added (or quantity increased if stack exists)
  Item equipped     → Stack removed/moved to character slot; stat bonuses applied
  Item unequipped   → Character slot freed; stack added to inventory
  Consumable used   → Stack quantity decremented; removed at 0
  Item sold         → Stack removed; gold added to party total
  Item discarded    → Stack removed; no recovery
  Inventory full    → New loot rejected until space freed
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Item Database** | Reads | Reads item definitions (stats, icons, names, restrictions, rarity) |
| **Character Data** | Reads | Reads CharacterClass for equip restriction validation |
| **Loot & Drop** | Written by | Loot System adds new stacks to the inventory pool |
| **Health & Damage** | Read by | Reads effective DEF and MaxHP after equipment bonuses |
| **Skill Execution** | Read by | Reads effective SPD and CRIT after equipment bonuses |
| **Combat System** | Read by | Reads all equipment stat bonuses during combat calculations |
| **Combat HUD** | Read by | Reads equipped items for display (item icons, durability warnings) |
| **Character Progression** | Read by | Reads character level for equip restriction checks |
| **Shop System** | Read/Written by | Shop reads item gold value for sell price; selling removes stacks |
| **Equipment Enhancement** | Written by | Enhancement System modifies EquipmentInstance.EnhancementLevel |
| **Save / Load** | Serialized by | All InventoryStacks and EquipmentInstances are saved/loaded |
| **Inventory UI** | Driven by | All inventory state is displayed through the Inventory UI |

## Formulas

| Formula | Expression | Notes |
|---------|-----------|-------|
| `EffectiveStat` | `(BaseStat + EqFlat) × (1 + min(EqPct, 0.50))` | From Item Database GDD |
| `EquipClassCheck` | `item.Class == character.Class OR item.Class == Any` | Must pass |
| `EquipLevelCheck` | `character.Level >= item.RequiredLevel` | Must pass |
| `MaxStackConsumable` | `99` | Consumables stack to 99 |
| `MaxStackMaterial` | `99` | Materials stack to 99 |
| `MaxInventoryStacks` | `200` | Total unique stack entries |
| `DurabilityOnDeath` | `Durability -= 10` (Armor + Helmet only) | Flat penalty |
| `DurabilityPerHit` | `Durability -= 1` (Armor + Helmet only) | Per combat hit |

## Edge Cases

1. **Inventory is full (200 stacks) and loot drops**: The Loot & Drop System cannot add
   the item to the inventory. A "Inventory Full" notification appears. The dropped item
   is held in a temporary "pending loot" queue. The player must free space (consume,
   sell, or discard) to claim it. Pending loot expires after 3 encounters (dropped items
   are lost if not claimed).

2. **Character level drops below an equipped item's RequiredLevel**: The item stays
   equipped but all stat bonuses from it are disabled (greyed-out in HUD). Stats re-
   activate when the character re-meets the level requirement. This can happen via
   curses or death penalties that temporarily reduce level.

3. **Equipment breaks mid-combat (durability = 0)**: The item is auto-unequipped
   immediately. All stat bonuses are removed. The Combat HUD updates within 1 frame.
   The player sees a "Broken" notification. Combat continues — this is intended tension.

4. **Two characters try to equip the same unique item**: Impossible — each equipment
   instance is a unique runtime object. Once equipped on one character, it is no longer
   in the inventory and cannot be selected for another character.

5. **Consumable used on dead character (Revive type)**: The consumable is consumed,
   the character is revived at `EffectValue%` of MaxHP. If the character was already
   alive, the consumable is wasted (used but has no effect). A warning appears:
   "Target is already alive."

6. **Player tries to equip a Relic on the wrong character**: Relics are character-
   specific (e.g., Evelyn's Cursed Pendant can only be equipped on Evelyn). The
   equip restriction enforces this. Attempting to equip on the wrong character shows:
   "This Relic can only be equipped by [CharacterName]."

7. **Equipment enhancement level is at cap (+10) and player tries to enhance again**:
   Operation fails. Material is not consumed. Tooltip: "Enhancement level is at maximum."

8. **Save file loaded with an equipment item that no longer exists (deleted Resource)**:
   The EquipmentInstance references a null ItemRef. The item is removed from inventory.
   A critical error is logged. The character's slot is freed.

## Dependencies

- **Depends on**: Item Database (item definitions), Character Data (class restrictions),
  Character Progression (level checks)
- **Depended on by**: Loot & Drop (adds items), Health & Damage (reads stat bonuses),
  Skill Execution (reads stat bonuses), Combat HUD (displays equipment), Shop System
  (sells items), Equipment Enhancement (modifies enhancement level), Save / Load
  (persists state), Inventory UI (displays inventory)

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `MaxInventoryStacks` | int | `200` | Increase if players report running out of space |
| `MaxConsumableStack` | int | `99` | Standard cap for consumable items |
| `MaxMaterialStack` | int | `99` | Standard cap for enhancement materials |
| `EquipmentPctBonusCap` | float | `0.50` | Max percentage bonus from all equipment combined |
| `PendingLootExpiry` | int | `3` | Encounters before unclaimed loot is lost |
| `DurabilityPerHit` | int | `1` | Per-hit durability loss for Armor/Helmet |
| `DurabilityOnDeath` | int | `10` | Flat durability penalty on character death |

## Visual/Audio Requirements

- **Inventory UI**: Categorized list (Equipment, Consumables, Materials, Key Items) with
  stack quantities. Equipment items show icon, name, rarity-colored border, and equipped
  status. Consumables show icon, name, and quantity (×N).
- **Equip Action**: When an item is equipped, a "lock-in" sound plays and the character's
  stat block animates upward. The item's slot icon highlights.
- **Unequip Action**: Soft "release" sound. Stat block animates downward.
- **Broken Equipment**: Icon cracks with a fissure effect, greyed-out overlay, sharp
  "crack" sound followed by dull thud.
- **Inventory Full**: Red notification banner with a warning sound.

## UI Requirements

- **Inventory Screen**: Tabbed interface with Equipment, Consumables, Materials, and
  Key Items tabs. Each tab shows a scrollable list of stacks.
- **Equipment Detail Popup**: Clicking an equipment item shows: name, icon, rarity border,
  stat bonuses, required level/class, enhancement level (+N), durability bar, and special
  effects list.
- **Character Equipment Screen**: Shows a character portrait with 5 equipment slots
  arranged around it. Each slot shows the equipped item's icon. Empty slots show the
  slot type label.
- **Equip/Unequip Buttons**: "Equip to..." button on inventory items opens a character
  selector. "Unequip" button on equipped items returns the item to inventory.
- **Consumable Usage Button**: "Use" button on consumable stacks opens a target selector
  (in combat: choose character; out of combat: choose character freely).

## Acceptance Criteria

- [ ] Inventory correctly stacks identical consumables and materials (up to 99 per stack)
- [ ] Each equipment item occupies exactly one stack entry with unique EquipmentInstance
- [ ] Inventory capacity is capped at 200 stack entries; overflow is rejected with notification
- [ ] Each character has exactly 5 equipment slots (Weapon, Armor, Helmet, Accessory, Relic)
- [ ] Equip validation checks both CharacterClass and RequiredLevel
- [ ] Items that fail equip validation are greyed-out with correct error tooltip
- [ ] Equipping an item to an occupied slot returns the previous item to inventory
- [ ] Consumables can be used both in combat (costs action) and out of combat (free)
- [ ] Consumable stack decrements by 1 per use and is removed at 0
- [ ] Equipment stat bonuses aggregate correctly via the EffectiveStat formula
- [ ] Equipment percentage bonuses are capped at 50% total
- [ ] Broken equipment (durability = 0) is auto-unequipped with stat bonus removal
- [ ] Equipment state (equipped flag, enhancement level, durability) saves and loads correctly
- [ ] Pending loot queue holds items when inventory is full; expires after 3 encounters
- [ ] Character level drop below RequiredLevel disables equipment bonuses without unequipping

## Open Questions

- Should the inventory support a "favorite" or "lock" feature to prevent accidental
  selling/discarding of important items? Recommendation: yes, especially for Relics and
  high-enhancement equipment.
- Should consumable usage in combat have its own dedicated input button (5th skill slot),
  or should it be accessed via the pause menu during combat? A dedicated button is faster
  but adds HUD complexity.
- Should the inventory support auto-sort (by rarity, by type, by level)? This would help
  players manage large inventories but is a nice-to-have for MVP.
