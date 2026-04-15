# Shop System

> **Status**: Approved
> **Author**: Design session 2026-04-11
> **Last Updated**: 2026-04-11
> **Implements Pillar**: Earn the Ending (meaningful resource choices)

## Overview

The Shop System provides a controlled economy sink where players can spend gold (earned from combat and exploration) to purchase equipment, consumables, and enhancement materials. Shops are accessed through NPC merchants in Village/Hub areas. Each shop has an inventory defined by a `ShopInventory` Resource that lists available items, their prices, and any unlock conditions (e.g., "available after Chapter 2"). The shop UI presents a categorized grid of purchasable items with full stat previews, and the transaction flow ensures the player always understands what they're buying and how it compares to their current equipment. Gold is a shared party resource — loot drops deposit gold into the party wallet, not individual characters.

## Player Fantasy

The Shop System serves the fantasy of **strategic preparation**. Before heading into a dangerous chapter, the player visits the village merchant to buy a better weapon for Evan or stock up on healing items. The shopkeeper is a character, not a vending machine — they have a name, a personality, and dialogue that reflects the story state. Buying an item feels like an investment, not a transaction: the stat preview shows exactly how much better (or worse) the new item is compared to what's equipped. The player should feel the weight of spending their hard-earned gold — every purchase is a deliberate choice, not an impulse click.

**Reference model**: Final Fantasy IX's Treno weapon shops (merchants with personality, stock that changes with story progression), and Dragon Quest's clean buy/sell interfaces with clear stat comparisons.

## Detailed Rules

### Core Rules

1. **Gold Currency**: Gold is the sole currency for shop transactions. Gold is earned from:
   - **Enemy Drops**: Each enemy has a `GoldDrop` range (e.g., 15-25 gold). Awarded on death.
   - **Encounter Bonus**: Each cleared encounter awards a fixed bonus gold amount (e.g., 30 gold).
   - **Treasure Chests**: World exploration yields gold caches (e.g., 50-200 gold per chest).
   - **Chapter Rewards**: Chapter completion awards a lump sum (e.g., Ch1=500, Ch2=800, Ch3=1200, Ch4=2000).

2. **Gold Persistence**: Gold is a **party-wide shared resource**, tracked in the `InventoryManager` as `TotalGold`. Gold is NOT character-specific. The save file stores a single `partyGold` value.

3. **Shop Definition**: Each merchant is defined by a `ShopInventory` Resource:
   ```
   ShopInventory fields:
   ┌─────────────────────────────────────────────────┐
   | ShopId: string (unique identifier)               |
   | MerchantName: string (display name)              |
   | MerchantPortrait: Texture2D reference            |
   | Category: enum (General, Weapons, Armor, Special)|
   | Entries: ShopEntry[]                             |
   | DialogueGreeting: DialogueGraph reference        |
   └─────────────────────────────────────────────────┘

   ShopEntry fields:
   ┌─────────────────────────────────────────────────┐
   | ItemRef: ItemEquipment reference               |
   | Price: int (gold cost)                           |
   | UnlockCondition: enum (Always, AfterChapter N,   |
   |                        StoryFlag, Reputation)    |
   | UnlockRef: string (chapter ID or story flag key) |
   | StockLimit: int (0 = unlimited, >0 = finite)     |
   └─────────────────────────────────────────────────┘
   ```

4. **Shop Access**: Players interact with shops by talking to merchant NPCs in Village/Hub scenes. The NPC triggers a `DialogueGraph` that includes a `ShopOpen` action node. When the player selects "Browse items" in dialogue, the Shop UI opens. Closing the shop returns to the dialogue.

5. **Buy Flow**:
   1. Player selects an item from the shop grid
   2. Item detail panel opens showing: item name, icon, stats, price, and comparison to currently equipped item in that slot (for the active character)
   3. Player confirms purchase
   4. If `TotalGold >= Price`, gold is deducted, item is added to `InventoryManager`
   5. If `TotalGold < Price`, purchase is rejected with "Not enough gold" feedback
   6. If item has `StockLimit > 0`, the stock count decreases by 1

6. **Sell Flow**:
   1. Player switches to "Sell" tab in the shop UI
   2. Shows all items in `InventoryManager` (excluding key items and equipped items)
   3. Sell price is always `floor(BuyPrice × 0.5)` — items sell for half their purchase price
   4. Player selects items to sell, confirms
   5. Gold is added to `TotalGold`, items are removed from `InventoryManager`
   6. **Equipped items cannot be sold** — the player must unequip them first

7. **Item Comparison on Purchase**: When the player hovers/selects a purchasable item, the shop UI shows:
   - The item's full stat block (ATK, DEF, MaxHP bonus, etc.)
   - A "vs Current" comparison: if the active character has an item in the same slot, show the stat delta (green "+N" for improvements, red "-N" for downgrades)
   - If the active character has no item in that slot, show "No [slot] equipped"

8. **Stock Management**: Items with `StockLimit > 0` have a finite supply per shop visit. Purchased stock is **persisted per save file** — if the player buys the last "Silver Sword" from a shop, it's gone forever for that save. A counter shows "×N remaining" on limited-stock items.

9. **Shop Categories**: The shop UI organizes items into tabs:
   - **Weapons**: Swords, Staffs, Bows (filtered by what the shop stocks)
   - **Armor**: Body, Head, Accessories
   - **Materials**: Enhancement stones, upgrade components (if the Equipment Enhancement system is active)
   - **Consumables**: Healing items, MP restoration items (if consumables exist in the game)

10. **Shop Closing**: When the player exits the shop:
    - The dialogue resumes (if the shop was opened from an NPC conversation)
    - The player can continue talking or end the conversation
    - Gold and inventory changes are saved immediately

### States and Transitions

```
┌──────────┐  Talk to NPC   ┌──────────────────┐
│  Idle    │ ──────────────▶│  Dialogue with   │
│          │                │  Merchant        │
└──────────┘                └────────┬─────────┘
                                     │ Player selects "Browse"
                                     ▼
                            ┌──────────────────┐
                            │  Shop Open        │
                            │  (Buy/Sell tabs)  │
                            └────────┬─────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
              ▼                      ▼                      ▼
     ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
     │  Buy Mode    │      │  Sell Mode   │      │  Item Detail │
     │  (grid view) │      │  (inventory) │      │  (preview)   │
     └──────┬───────┘      └──────┬───────┘      └──────┬───────┘
            │ Confirm Purchase    │ Confirm Sell        │ Close
            ▼                      ▼                      ▼
     ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
     │  Gold -Price │      │  Gold +Sell  │      │  Return to   │
     │  Item +Inv   │      │  Item -Inv   │      │  Shop Grid   │
     └──────┬───────┘      └──────┬───────┘      └──────────────┘
            │                      │
            └──────────┬───────────┘
                       ▼
              ┌──────────────────┐
              │  Shop Close      │
              │  (return to      │
              │   dialogue)      │
              └──────────────────┘
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Inventory & Equipment** | Reads + Writes | Reads party inventory for sell mode; writes purchased items to inventory | Item definitions, equipped item references for comparison |
| **Item Database** | Reads | Reads item stats, rarity, slot type for display and filtering | Item definitions |
| **Character Data** | Reads | Reads active character's equipped items for "vs Current" comparison | Equipped item references |
| **Loot & Drop** | Reads + Writes | Reads gold drops from enemy deaths; writes gold to party inventory | Gold balance updates |
| **Combat HUD** | Writes | Sends gold balance updates for display | — |
| **Dialogue System** | Reads + Called by | Shop opens from dialogue `ShopOpen` action; closes back to dialogue | Dialogue graph execution |
| **Chapter State System** | Reads | Reads chapter progression for shop inventory unlocks | Chapter completion flags |
| **Save / Load** | Serialized | Gold balance, shop stock levels, and purchase history are saved/loaded | — |
| **Equipment Enhancement** | Reads (Alpha+) | Reads enhancement materials for the Materials tab | Enhancement item definitions |

## Formulas

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **Sell Price** | `floor(BuyPrice × 0.5)` | BuyPrice = item's shop price | Items always sell for half buy price |
| **Purchase Validation** | `TotalGold >= Price` | TotalGold = party gold, Price = item price | Reject if insufficient funds |
| **Item Price (base)** | `floor(ItemPower × PricePerPower × RarityMultiplier)` | ItemPower = sum of stat bonuses, PricePerPower = 5, RarityMultiplier: Common=1.0, Uncommon=1.3, Rare=1.6, Epic=2.0, Legendary=3.0 | Used when auto-pricing items without manual price |
| **Stock Remaining** | `StockLimit - PurchasedCount` | PurchasedCount = times bought this save | Shows "×N remaining" on limited items |

### Price Examples

| Item | ItemPower | Rarity | RarityMult | Calculated Price | Rounded |
|------|-----------|--------|------------|-----------------|---------|
| Iron Sword | 12 | Common | 1.0 | 12 × 5 × 1.0 = 60 | 60 |
| Silver Sword | 24 | Uncommon | 1.3 | 24 × 5 × 1.3 = 156 | 155 |
| Shadow Blade (Evelyn) | 40 | Rare | 1.6 | 40 × 5 × 1.6 = 320 | 320 |
| Hunter's Bow (Evan) | 28 | Uncommon | 1.3 | 28 × 5 × 1.3 = 182 | 180 |
| Copper Ring | 5 | Common | 1.0 | 5 × 5 × 1.0 = 25 | 25 |

## Edge Cases

1. **Player tries to buy an item they can't equip**: If the active character's class can't equip the item (e.g., a Mage buying a Bow), the item is still purchasable — it goes to the party inventory. The "Buy" button shows a warning icon: "No character can equip this." The player can still buy it for another character later.

2. **Shop opened with zero gold**: The shop still opens normally. All items are visible but grayed out with "Not enough gold" labels. The player can still sell items.

3. **Player sells their last of an item type**: The sell confirmation shows "You will lose this item permanently." for the last unit. This is a soft warning, not a block.

4. **Shop inventory unlocks mid-conversation**: If the player's chapter progression unlocks new shop stock while talking to a merchant (e.g., they just completed Chapter 2), the shop UI refreshes to show the new items with a "New Stock!" badge.

5. **Multiple shops in the same village**: Each merchant has their own `ShopInventory` Resource. The player can visit multiple shops in one hub area. Gold balance is shared across all shops.

6. **Shop NPC is part of a quest**: The merchant's dialogue may change based on story flags. If the merchant leaves the village (story event), their shop becomes inaccessible. The `ShopInventory` includes a `MerchantActive` flag that the Village/Hub System checks.

7. **Player buys and immediately sells the same item**: The player loses 50% of the gold (buy at full price, sell at half price). This is intentional — it prevents gold exploitation and the warning is clear.

8. **Save/load during shop open**: If the game is saved while the shop UI is open and loaded, the shop closes on load (player returns to the NPC conversation state). Gold and inventory changes made during the shop session are preserved.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Inventory & Equipment | Reads + Writes | Hard — reads inventory for sell mode, writes purchased items | `InventoryManager.GetItems()`, `InventoryManager.AddItem()`, `InventoryManager.RemoveItem()` |
| Item Database | Reads | Hard — cannot price or display items without definitions | `ItemEquipment` references |
| Character Data | Reads | Hard — reads equipped items for comparison | `CharacterData.GetEquippedItem(slot)` |
| Loot & Drop / Party Inventory | Reads + Writes | Hard — reads/writes party gold balance | `InventoryManager.TotalGold` property |
| Dialogue System | Called by | Hard — shop opens from dialogue action node | `ShopOpen` dialogue action |
| Chapter State System | Reads | Soft — reads chapter flags for inventory unlocks | `ChapterStateSystem.GetFlag()` |
| Save / Load | Serialized | Hard — persists gold, stock levels, purchase counts | JSON fields: `partyGold`, `shopStockLevels`, `purchaseCounts` |
| Combat HUD | Writes | Soft — provides gold updates for HUD display | `OnGoldChanged(amount)` event |
| Equipment Enhancement | Reads | Soft (Alpha+) | Enhancement item definitions for Materials tab |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `SellPriceRatio` | float | `0.5` | 0.3-0.7 | Selling feels too rewarding; players hoard less | Selling feels pointless; players never sell |
| `PricePerPower` | int | `5` | 3-8 | Items feel overpriced; gold is useless | Items feel cheap; gold demand is too high |
| `StartingGold` | int | `200` | 100-500 | Early game feels too easy | Early game is frustratingly poor |
| `GoldDropFrequency` | float | `1.0` | 0.5-2.0 | Gold feels abundant; shops lose tension | Gold feels scarce; players can't buy anything |
| `ShopCountPerHub` | int | `2` | 1-4 | Too many shops overwhelm the player | Only one shop limits variety |
| `LimitedStockPrevalence` | float | `0.3` (30% of items) | 0.1-0.5 | Shops feel too restrictive | No sense of scarcity or urgency |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Shop opens | Dialogue box transitions to shop panel with slide-up animation | Shop bell chime | High |
| Item hover in shop | Item detail panel fades in with stat preview and "vs Current" comparison | Soft hover click | High |
| Purchase confirmed | Gold counter animates down; item flies to inventory icon | Coin clink + positive chime | High |
| Insufficient gold | "Not enough gold" text flashes in red on the price label | Low "buzzer" sound | High |
| Limited stock purchased | "×N remaining" counter decrements with animation | Soft "tick" | Medium |
| New stock unlocked | "New Stock!" badge appears on newly available items | Sparkle sound | Medium |
| Sell confirmed | Gold counter animates up; item icon fades out from inventory | Coin clink | High |
| Shop closes | Shop panel slides down; dialogue box returns | Shop bell reverse chime | Medium |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **Shop Main Panel** | Category tabs (Weapons, Armor, Materials), item grid (3×4), gold balance display (top-right), Buy/Sell toggle | Opened from merchant dialogue |
| **Item Detail Panel** | Item icon, name, rarity border, stat block, "vs Current" comparison, price, stock remaining | Shown on item hover/selection |
| **Sell Panel** | Scrollable list of party inventory items (non-equipped, non-key), sell prices, total sell value | Shown when Sell tab is active |
| **Purchase Confirmation** | Modal dialog: "Buy [Item] for [Price] gold?" with Yes/No | Shown on purchase click |
| **Sell Confirmation** | Modal dialog: "Sell [Item] for [Price] gold?" with Yes/No | Shown on sell click |

## Acceptance Criteria

- [ ] Shop opens from merchant dialogue and closes back to dialogue correctly
- [ ] Buy flow deducts gold and adds item to party inventory — verified by unit test
- [ ] Sell flow adds gold and removes item from party inventory — verified by unit test
- [ ] Sell price equals floor(BuyPrice × 0.5) for all items — verified by unit test
- [ ] Item comparison shows correct stat delta vs currently equipped item for active character
- [ ] Limited stock items decrement correctly and persist across save/load
- [ ] Items with class restrictions are purchasable even if no character can equip them (with warning)
- [ ] Equipped items cannot be sold — sell button is disabled for equipped items
- [ ] Shop inventory unlocks correctly based on chapter progression
- [ ] Gold balance displays correctly in shop UI and Combat HUD
- [ ] "Not enough gold" feedback shows when purchase is rejected
- [ ] Save/load preserves gold balance, stock levels, and purchase counts
- [ ] Multiple shops in the same hub area share the same gold balance

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| Should shops offer consumable items (healing potions, MP restore items) or are those exclusively loot drops? | Game Designer | Resolve during consumable design — recommendation: shops sell 1-2 basic consumables |
| Should the player be able to "steal" from shops as a gameplay mechanic (Evelyn's vampire ability)? | Game Designer + Narrative Director | Resolve during Chapter 2 design — adds narrative flavor but economy balance risk |
| Should shop prices scale with player level (dynamic pricing) or remain fixed per shop? | Systems Designer | Resolve before shop implementation — recommendation: fixed prices for MVP |
| Should reputation with a merchant affect prices (buying more = discount)? | Economy Designer | Full Vision feature — defer beyond Alpha |
| Can the player open the shop menu outside of NPC dialogue (e.g., from the pause menu)? | UX Designer | Recommendation: no — shops are diegetic (NPC-anchored) for MVP |
