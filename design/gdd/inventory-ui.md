# Inventory UI

> **Status**: Approved
> **Author**: Design session 2026-04-12 (user-directed)
> **Last Updated**: 2026-04-12
> **Complements**: [Inventory & Equipment System](./inventory-equipment-system.md)

## Overview

The Inventory UI is the presentation layer for the Inventory & Equipment System. It provides
a tabbed, categorized list view of all party-owned items and a character equipment view for
managing the 5 equipment slots per party member. The UI operates in two modes: **Pause Menu**
(accessible anytime, including combat) and **Full Screen** (out-of-combat exploration / village
hubs). It reads inventory state from the Inventory System and dispatches equip/unequip/use/sell
commands back to it. The UI is built with UI Toolkit (runtime) and uses USS styling for
rarity coloring, slot highlighting, and state-dependent visual feedback.

## Player Fantasy

The Inventory UI serves the fantasy of **having a well-equipped, carefully curated party**.
The player should feel a sense of ownership over their party's loadout — every item in the
list was earned, every piece of equipment has a story. Opening the inventory mid-combat should
feel like a quick tactical decision ("switch this weapon, use that potion"), while opening
it out of combat is a moment to strategize and customize. The UI should never feel like
a chore — sorting, equipping, and reviewing the collection is rewarding because the items
are meaningful. A Legendary item with a glowing orange border should feel *special*. Swapping
gear on a character and watching the stats climb should feel *satisfying*.

**Reference model**: Final Fantasy VII Remake's clean equipment screens (fast, satisfying,
stat-comparison is instant), with Genshin Impact's rarity visual language (color and glow
communicate value at a glance).

## Screen Hierarchy

```
┌─────────────────────────────────────────────────┐
│              Inventory Root (Panel)              │
│                                                  │
│  ┌──────────────┐  ┌──────────────────────────┐ │
│  │  Tab Bar     │  │  Context Header          │ │
│  │ [Eq][Con]    │  │  Gold: 1,250 | Stacks: 47 │ │
│  │ [Mat][Key]   │  │  / 200                   │ │
│  └──────────────┘  └──────────────────────────┘ │
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │           Item List (Scrollable)             ││
│  │                                              ││
│  │  [Icon] Evelyn's Longsword +3    [Lv.12]    ││
│  │  [Icon] Health Potion            ×12         ││
│  │  [Icon] Iron Ore                 ×45         ││
│  │                                              ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │            Action Bar (Context)              ││
│  │  [Equip] [Use] [Sell] [Discard] [Sort]      ││
│  └──────────────────────────────────────────────┘│
└─────────────────────────────────────────────────┘

Popup overlays (rendered on top):
  - Equipment Detail Popup (click/tap item in Equipment tab)
  - Character Equipment Screen (after "Equip to..." → select character)
  - Target Selector (after "Use" on consumable)
  - Confirm Dialog (for sell/discard/drop unique items)
```

## Inventory Screen Layout

The main inventory screen is a single panel with four zones:

### A. Tab Bar (top-left)

Four tabs: **Equipment** | **Consumables** | **Materials** | **Key Items**

- Active tab is highlighted with a gold underline
- Tab shows a count badge: e.g., `Equipment (23)`, `Consumables (4)`
- Switching tabs instantly filters the list — no transition animation

### B. Context Header (top-right)

```
Gold: 1,250    |    Stacks: 47 / 200    |    [Sort ▼]
```

- **Gold**: Party gold total (always visible, updated on sell)
- **Stacks**: Current inventory fill level. Turns orange at 80% (160/200), red at 95% (190/200)
- **Sort button**: Dropdown with options:
  - `Rarity` (Common → Legendary)
  - `Name` (A→Z)
  - `Level` (highest first, for equipment)
  - `Quantity` (largest stack first, for consumables/materials)
  - `Recently Acquired` (newest first)
- Sort preference persists across sessions

### C. Item List (center, scrollable)

Each row renders:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Icon 32×32]  Item Name                    Rarity-colored bar   │
│               Subtitle (class/level or ×N)                      │
│               [Equipped badge]  [Broken badge]  [New badge]     │
└─────────────────────────────────────────────────────────────────┘
```

- **Equipment rows**: Show item name, class restriction subtitle (e.g., `Lv.12 Mage`), rarity-colored right border
- **Consumable rows**: Show item name, quantity as `×N` subtitle
- **Material rows**: Show item name, quantity as `×N` subtitle
- **Key Item rows**: Show item name, description tooltip on hover
- **Badges**:
  - `Equipped` (green pill) — shown on equipment currently on a character
  - `Broken` (grey pill with crack icon) — durability = 0
  - `New` (yellow dot) — acquired since last inventory open, clears on view

### D. Action Bar (bottom, context-sensitive)

Actions change based on selected item type and tab:

| Tab | Selected | Actions |
|-----|----------|---------|
| Equipment | Unselected | *(none — select an item)* |
| Equipment | Not equipped | `[Equip to...]` `[Sell]` `[Discard]` |
| Equipment | Equipped | `[Unequip]` `[Enhance]` `[Sell]` |
| Equipment | Broken equipped | `[Repair]` `[Unequip]` |
| Consumables | Any | `[Use]` |
| Materials | Any | `[Use]` (for enhancement materials) |
| Key Items | Any | `[View]` (lore popup) |

- `[Sell]` only appears when in a shop or village hub with a merchant
- `[Discard]` requires confirmation dialog for any unique/rare item
- `[Enhance]` opens the Equipment Enhancement sub-screen (links to that system's UI)

### Navigation

- **Gamepad**: D-pad navigates tabs (left/right) and list (up/down). A selects, B closes
- **Mouse/Keyboard**: Click tabs, scroll list. ESC closes. Hover shows tooltip
- **Touch**: Tap tabs, swipe list. Tap-and-hold opens detail popup

## Equipment Detail Popup

Triggered by clicking/tapping an equipment item in the Equipment tab. Renders as a modal overlay:

```
┌──────────────────────────────────────────────────────┐
│  [Icon 64×64]   ✦ Evelyn's Longsword +3        ✕     │
│                 Rare • Weapon (Sword)                │
│  ─────────────────────────────────────────────────   │
│                                                      │
│  Required: Lv.12 Mage           Class: Mage ✓       │
│                                                      │
│  ┌─ Stats ──────────────────────────────────────┐   │
│  │  ATK      +45                                │   │
│  │  SPD      +8                                 │   │
│  │  CRIT%    +3.2%                              │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌─ Enhancement ────────────────────────────────┐   │
│  │  Level: +3/10     ████████░░  (30%)           │   │
│  │  Materials: 2× Iron Ore, 1× Magic Dust        │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌─ Durability ─────────────────────────────────┐   │
│  │  72 / 100   ████████████████░░░░░░░           │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌─ Special Effects ────────────────────────────┐   │
│  │  • On hit: 10% chance to apply Bleed (3s)    │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │         [Equip to...]       [Close]          │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### Visual Rules

- **Rarity border**: The entire popup has a colored border matching item rarity:
  - Common: `#B0B0B0` (grey)
  - Uncommon: `#4CAF50` (green)
  - Rare: `#2196F3` (blue)
  - Epic: `#9C27B0` (purple)
  - Legendary: `#FF9800` (orange)
- **Stat colors**: Positive bonuses in green `#4CAF50`, negative in red `#F44336`
- **Durability bar**: Green (>50%), orange (25–50%), red (<25%), grey (0 = broken)
- **Class match indicator**: Green check ✓ if current character can equip, red ✗ with reason if not

### Equip Restriction Failure Display

When the selected character cannot equip an item, the popup shows a warning banner:

```
⚠ Cannot equip: Requires Lv.15 Mage (Evan is Lv.10 Swordman)
```

## Character Equipment View

Triggered by `[Equip to...]` → selecting a character. Shows the character's current loadout:

```
┌──────────────────────────────────────────────────────────────┐
│  [Portrait]    Evelyn                    [Switch Character ▶]│
│   96×96      Lv.12 Mage                                      │
│              Class: Mage                                       │
│                                                              │
│  ┌──────────┐              ┌──────────┐                     │
│  │ Helmet   │              │ Weapon   │                     │
│  │[Icon 48] │              │[Icon 48] │                     │
│  │Crown +2  │              │Longsword │                     │
│  │  +12 DEF │              │   +3     │                     │
│  └──────────┘              └──────────┘                     │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  Armor   │  │Accessory │  │  Relic   │                  │
│  │[Icon 48] │  │[Icon 48] │  │[Icon 48] │                  │
│  │ Robe +1  │  │ Ring of  │  │ Cursed   │                  │
│  │  +18 DEF │  │  Wisdom  │  │ Pendant  │                  │
│  │          │  │  +5 INT  │  │  Unique  │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│                                                              │
│  ┌─ Stat Summary ────────────────────────────────────────┐ │
│  │  ATK: 127  DEF: 84  SPD: 34  CRIT: 12.4%  HP: 480    │ │
│  │  (Base → Bonus → Effective)                           │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │       [Change Equipment]    [Back]                   │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Layout Rules

- **Portrait**: Character's portrait with name, level, and class underneath
- **Slot arrangement**: Weapon and Helmet side-by-side at top. Armor, Accessory, Relic in a row below
- **Empty slot**: Shows a greyed-out slot icon with the slot type label (e.g., `— Weapon —`). Clicking opens the Equipment tab filtered to items compatible with that slot
- **Filled slot**: Shows the item's icon, name, enhancement level, and primary stat bonus
- **Broken item**: Slot icon has a crack overlay and is desaturated
- **[Switch Character]**: Cycles through party members (left arrow = previous, right arrow = next)
- **Stat Summary**: Shows effective stats (base + equipment bonuses). The `(Base → Bonus → Effective)` line expands on click to show the breakdown

## Interaction Flows

### Equip Flow

```
Player selects equipment item in list
  → Equipment Detail Popup opens
  → Player taps [Equip to...]
    → Character Equipment View opens (default: first party member)
      → If item is compatible: [Equip] button is active
      → If item is NOT compatible: [Equip] is greyed out with ⚠ reason
      → Player taps [Switch Character] to cycle party members
    → Player taps [Equip]
      → Confirmation if replacing an already-equipped item:
          "Replace [Old Item] with [New Item] on [Character]?"
          [Confirm] [Cancel]
      → On Confirm:
          - Old item returns to inventory (if replacing)
          - New item moves to character's slot
          - Stat bonuses update immediately
          - "Equip" sound plays
          - Character stat block animates upward (+X numbers)
          - Popup closes, returns to Inventory Screen
```

**Gamepad flow variant**:

```
[Equip to...] → Character portrait selector (A to confirm, D-pad to navigate)
  → Confirmation dialog (if replacing)
  → Equip animation → Return to Inventory
```

### Unequip Flow

```
Player selects equipped item in Equipment tab
  → Equipment Detail Popup opens
  → Player taps [Unequip]
    → If inventory is full (200 stacks):
        ⚠ "Inventory is full. Free up space before unequipping."
        [OK] → Returns to popup
    → If inventory has space:
        - Item returns to inventory as new stack entry
        - Stat bonuses removed immediately
        - "Unequip" sound plays
        - Slot shows empty state
        - Popup closes, returns to Inventory Screen
```

### Swap Flow (equip to occupied slot)

```
Player selects equipment item → [Equip to...] → Character with occupied slot
  → Player taps slot that has existing item
    → Confirmation dialog:
        "Replace [Old Item] with [New Item] on [Character]?"
        "  [Old Item] will return to inventory."
        [Confirm] [Cancel]
    → On Confirm:
        - Old item added to inventory
        - New item equipped to slot
        - Both stat changes applied atomically
        - Dual animation: old stat block animates down (-X), new animates up (+X)
```

### Consumable Use Flow

**In Combat**:

```
Player selects consumable → [Use]
  → Target Selector opens (shows valid targets only)
    → Player selects target character/enemy
      → Consumable activates (costs combat action)
      → Stack decrements by 1
      → Effect animation plays on target
      → If stack reaches 0: item removed from inventory
      → Combat HUD updates
```

**Out of Combat**:

```
Player selects consumable → [Use]
  → Target Selector opens (all party members selectable)
    → Player selects target
      → Consumable activates (free, no cost)
      → Stack decrements by 1
      → Effect animation plays on target
      → Character portrait updates (HP/SP bars change)
      → If stack reaches 0: item removed
```

**Edge case — Revive consumable on alive target**:

```
Player selects Revive → [Use] → selects alive character
  → Warning dialog: "[Character] is already alive. Use anyway?"
  → [Confirm] → Consumable wasted (stack decrements, no effect)
  → [Cancel] → Returns to Target Selector
```

### Sell Flow

**Prerequisite**: Player must be in a Shop or Village Hub with a merchant.

```
Player selects item → [Sell]
  → Sell Confirmation:
      "Sell [Item Name] for [Gold Value] Gold?"
      [Confirm] [Cancel]
  → On Confirm (equipment):
      - If equipped: auto-unequips first (stat bonuses removed)
      - Stack entry removed from inventory
      - Gold added to party total
      - "Coin" sound plays
      - Gold counter animates upward
  → On Confirm (consumable/material):
      - Entire stack sold (cannot sell partial stacks)
      - Gold added, same feedback
```

**Restriction**: Key Items cannot be sold. The [Sell] button does not appear for Key Items.

### Discard Flow

```
Player selects item → [Discard]
  → For Common/Uncommon items:
      "Discard [Item Name]?" [Confirm] [Cancel]
  → For Rare/Epic/Legendary items:
      "⚠ Discard [Item Name]? This is a [Rarity] item."
      "  It will be permanently lost."
      [Confirm] [Cancel] (double-confirm)
  → For Key Items:
      [Discard] button does not appear
  → For Equipped items:
      "Unequip [Item Name] first before discarding."
      [OK] → Unequips item, then re-opens discard dialog
  → On Confirm:
      - Item removed from inventory
      - "Item drop" sound plays
      - No recovery possible
```

### Sort Flow

```
Player taps [Sort ▼] in Context Header
  → Dropdown appears with sort options
  → Player selects option
    → List re-sorts immediately (no animation)
    → Selection persists across sessions
    → Dropdown closes
```

## Combat vs Out-of-Combat Differences

The Inventory UI operates in two distinct modes with different access levels:

| Feature | In Combat (Pause Menu) | Out of Combat (Full Screen) |
|---------|----------------------|---------------------------|
| **Open inventory** | Yes (pauses combat) | Yes |
| **View all tabs** | Yes | Yes |
| **Equip/Unequip** | Yes | Yes |
| **Use consumable** | Yes (costs combat action) | Yes (free) |
| **Sell items** | No | Yes (at shop/hub only) |
| **Discard items** | No | Yes |
| **Sort inventory** | No | Yes |
| **Enhance equipment** | No | Yes (at hub forge only) |
| **Repair equipment** | No | Yes (at shop/hub only) |
| **UI scale** | Scaled down (70% screen) | Full screen |
| **Time state** | Combat timer pauses | No timer |
| **Party AI** | Continues running | Idle |

### Combat Pause Menu Specific Rules

- Opens as a smaller panel centered on screen (doesn't cover entire viewport)
- Background shows dimmed combat scene (not blacked out — maintains combat awareness)
- Closing the inventory resumes the combat timer immediately
- Consumable usage triggers the combat action cost: character's turn is consumed
- No sound effects that would mask combat audio (equip/unequip sounds are muted in combat mode, only combat-relevant sounds play)

### Out-of-Combat Full Screen Rules

- Opens as a full-screen panel
- Background is the game world (blurred)
- No time pressure — all actions are free and unrestricted
- Ambient world audio continues at reduced volume

## Visual Style & Feedback

### Color Palette

| Element | Color | Usage |
|---------|-------|-------|
| **Common rarity** | `#B0B0B0` | Grey border, grey text tint |
| **Uncommon rarity** | `#4CAF50` | Green border, green text tint |
| **Rare rarity** | `#2196F3` | Blue border, blue text tint |
| **Epic rarity** | `#9C27B0` | Purple border, purple text tint |
| **Legendary rarity** | `#FF9800` | Orange border, orange text tint, subtle glow |
| **Positive stat** | `#4CAF50` | Green number for +bonuses |
| **Negative stat** | `#F44336` | Red number for -penalties |
| **Durability OK** | `#4CAF50` | Bar > 50% |
| **Durability Warn** | `#FF9800` | Bar 25–50% |
| **Durability Low** | `#F44336` | Bar < 25% |
| **Broken** | `#606060` | Grey, desaturated |
| **Equipped badge** | `#4CAF50` | Green pill background |
| **New badge** | `#FFD700` | Yellow dot |
| **Inventory full** | `#F44336` | Red banner text |
| **Selected row** | `#FFFFFF15` | Semi-transparent white highlight |

### Typography

| Element | Font | Size | Weight |
|---------|------|------|--------|
| Item name | Project body font | 16px | Semibold (600) |
| Subtitle (class/level/qty) | Project body font | 12px | Regular (400) |
| Stat values | Monospace (for alignment) | 14px | Medium (500) |
| Section headers | Project body font | 13px | Bold (700), uppercase |
| Tooltip text | Project body font | 11px | Regular (400) |
| Badge text | Project body font | 10px | Bold (700) |

### Animations

| Event | Animation | Duration | Easing |
|-------|-----------|----------|--------|
| **Item equipped** | Stat numbers count upward from base to effective | 0.4s | `ease-out` |
| **Item unequipped** | Stat numbers count downward | 0.3s | `ease-in` |
| **Equip swap** | Old stat drops (-X, red), new stat rises (+X, green) | 0.5s | `ease-out` |
| **Tab switch** | Instant filter (no animation) | 0s | — |
| **Popup open** | Scale from 0.9→1.0, fade in | 0.15s | `ease-out` |
| **Popup close** | Scale from 1.0→0.95, fade out | 0.1s | `ease-in` |
| **Consumable use** | Target flashes with effect color (heal=green, damage=red) | 0.3s | `ease-out` |
| **Gold change** | Gold counter animates digit-by-digit | 0.5s | `ease-out` |
| **Inventory full warning** | Banner slides down from top | 0.2s | `ease-out` |
| **New badge clear** | Dot fades out | 0.2s | `ease-in` |
| **List scroll** | Smooth scroll | — | `ease-out` (momentum) |
| **Broken item unequip** | Slot icon cracks (VFX), desaturates, drops down | 0.4s | `ease-in` |

### Audio Feedback

| Event | Sound | Volume | Notes |
|-------|-------|--------|-------|
| **Equip item** | "Lock-in" metallic click | Medium | Satisfying, confirms action |
| **Unequip item** | Soft "release" click | Low | Less impactful than equip |
| **Equip swap** | Two-tone: old drops (low thud), new rises (chime) | Medium | Dual feedback |
| **Consumable use** | Type-specific (potion = glug, bomb = whoosh, revive = bell) | Medium | Varies by consumable type |
| **Sell item** | Coin clink | Medium | Same as shop system |
| **Discard item** | Item drop thud | Low | Dull, discouraging |
| **Inventory full** | Warning buzzer | High | Urgent, stops action |
| **Broken equipment** | Crack sound + dull thud | High | Tension-inducing |
| **Popup open** | Soft UI "pop" | Low | Subtle |
| **Popup close** | Soft UI "dismiss" | Low | Subtle |

**Combat mode audio overrides**: Equip/unequip sounds are **muted** during combat. Only consumable-use sounds play (they are combat-relevant feedback).

### Tooltip System

Hovering (mouse) or holding (gamepad: Y button / touch: long-press) on any item row shows a tooltip:

```
┌──────────────────────────────────────┐
│ ✦ Evelyn's Longsword +3              │
│ Rare • Weapon (Sword)                │
│ ─────────────────────────────────── │
│ Required: Lv.12 Mage                 │
│ ATK +45 | SPD +8 | CRIT +3.2%       │
│ Durability: 72/100                   │
│ Enhancement: +3/10                   │
│ ─────────────────────────────────── │
│ "A blade forged from Evelyn's own     │
│  cursed blood. It hungers."          │
└──────────────────────────────────────┘
```

- Tooltip appears after 0.5s hover delay (prevents flicker during fast scrolling)
- Tooltip follows cursor position (mouse) or anchors to row center (gamepad)
- Tooltip shows: name, rarity, type, requirements, stats, durability, enhancement, flavor text
- Does **not** show: gold value, enhancement material costs (those are in the Detail Popup)

## Formulas

The Inventory UI is a presentation layer — it contains no gameplay math. All formulas
are owned by the systems it reads from. Key display calculations:

| Display | Formula | Source System |
|---------|---------|---------------|
| **Effective stat** | `BaseStat × (1 + ΣPct_buffs) + ΣFlat_buffs` | Character State Manager |
| **Stack fill %** | `CurrentStacks / 200` | Inventory & Equipment System |
| **Durability color threshold** | `>50% = green, 25–50% = orange, <25% = red, 0 = grey` | Inventory & Equipment System |
| **Stack warning color** | `>80% (160/200) = orange, >95% (190/200) = red` | This system |
| **Sell price** | Defined on each `ItemEquipment` asset | Item Database |

## Edge Cases

1. **Inventory opens during a cutscene**: Inventory input is blocked during cutscenes (Input
   System blocks all non-UI input). The inventory cannot be opened; if it was already open,
   it force-closes when the cutscene begins.

2. **Item equipped on character not in the active party slot**: The Equipment View still
   shows the item correctly on that character; the character is still visible via [Switch
   Character] cycling even if they are not the current active player character.

3. **Item quantity reaches 0 mid-view**: If a consumable is used and the stack hits 0, the
   row is removed from the list with a brief fade-out. If it was selected, selection moves
   to the adjacent row.

4. **Inventory full while trying to unequip**: Unequip is blocked with an error message
   ("Inventory is full. Free up space before unequipping."). The item remains equipped.

5. **Equipping an item whose requirements the character no longer meets** (e.g., level was
   reduced by a save migration bug): The equip action is blocked at the Inventory & Equipment
   System level. The UI shows the same ⚠ restriction message as any failed equip.

6. **Two players open inventory simultaneously on the same save (shared save, impossible
   scenario)**: Single-player game — not applicable. Save files are single-session.

7. **Sort order changes while detail popup is open**: The popup remains open for the current
   item. When the popup closes, the list reflects the new sort order.

8. **Item GUID in save file no longer exists in Item Database (patch removed the item)**:
   The Inventory & Equipment System handles this gracefully (see Save/Load edge cases). The
   UI simply does not render a row for missing items.

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `MaxInventoryStacks` | int | `200` | Total inventory capacity before the player must discard |
| `InventoryWarnOrange` | float | `0.80` | Stack fill % that triggers orange warning |
| `InventoryWarnRed` | float | `0.95` | Stack fill % that triggers red warning |
| `TooltipHoverDelay` | float | `0.5s` | Delay before tooltip appears on hover |
| `PopupOpenDuration` | float | `0.15s` | Equipment Detail Popup open animation |
| `StatAnimDuration` | float | `0.4s` | Stat count-up animation duration on equip |
| `CombatInventoryScale` | float | `0.70` | Panel scale in combat pause mode (70% screen) |

## Dependencies

| System | Relationship | Details |
|--------|-------------|---------|
| **Inventory & Equipment System** | Reads state, dispatches actions | Primary data source. All inventory state comes from here. Actions (equip, use, sell) are dispatched as events |
| **Item Database** | Reads item definitions | Icons, names, rarity, stat bonuses, flavor text, requirements |
| **Character Data** | Reads character info | Portraits, names, classes, levels, current stats |
| **Shop System** | Contextual sell availability | Determines if [Sell] button is visible (player must be near a merchant) |
| **Equipment Enhancement System** | Links to enhance UI | [Enhance] button opens enhancement sub-screen |
| **Combat HUD** | Shares item display assets | Combat HUD reads same item icons/names for consumable buttons |
| **Health & Damage System** | Reads effective stats | Stat summary in Character Equipment View uses effective stat calculations |
| **Save / Load System** | No direct dependency | Save/Load operates on data, not UI. UI reflects loaded state |
| **Audio System** | Dispatches sound events | UI triggers audio events by name; Audio System plays them |
| **UI Toolkit Runtime** | Framework | All screens built as UI Toolkit `VisualElement` trees with USS styling |

## Acceptance Criteria

### Screen Layout

- [ ] Four tabs (Equipment, Consumables, Materials, Key Items) render correctly and filter the list on switch
- [ ] Tab badges show correct item counts that update in real-time
- [ ] Context header displays gold, stack count (current/200), and sort button
- [ ] Stack count indicator turns orange at 160/200 and red at 190/200
- [ ] Sort dropdown has 5 options (Rarity, Name, Level, Quantity, Recently Acquired) and persists selection

### Item List

- [ ] Equipment rows show icon, name, class/level subtitle, and rarity-colored border
- [ ] Consumable and Material rows show icon, name, and `×N` quantity
- [ ] Key Item rows show icon, name, and display lore on hover/click
- [ ] Equipped items display a green "Equipped" badge
- [ ] Broken items display a grey "Broken" badge with crack icon
- [ ] Newly acquired items display a yellow "New" badge that clears on first view
- [ ] List scrolls smoothly with momentum scrolling on touch input

### Equipment Detail Popup

- [ ] Popup renders with correct rarity-colored border
- [ ] All stat bonuses display with correct color (green for +, red for -)
- [ ] Enhancement level shows progress bar with level/N format
- [ ] Durability bar shows correct color based on threshold (green/orange/red/grey)
- [ ] Special effects list renders with bullet points
- [ ] Equip restriction failure shows clear reason (e.g., "Requires Lv.15 Mage")

### Character Equipment View

- [ ] Character portrait, name, level, and class display correctly
- [ ] All 5 equipment slots render in correct layout (Weapon+Helmet top, Armor+Accessory+Relic bottom)
- [ ] Equipped items show icon, name, enhancement level, and primary stat
- [ ] Empty slots show greyed-out icon with slot type label
- [ ] Broken items show crack overlay and desaturation
- [ ] [Switch Character] cycles through party members correctly
- [ ] Stat Summary shows effective stats (base + bonuses combined)
- [ ] Stat breakdown expands on click to show Base → Bonus → Effective

### Interaction Flows

- [ ] Equipping an item to an occupied slot triggers replacement confirmation
- [ ] Unequipping when inventory is full shows error and prevents action
- [ ] Consumable use in combat costs a combat action; out of combat is free
- [ ] Revive consumable on alive target shows warning before use
- [ ] Sell button only appears when near a merchant (shop/village hub)
- [ ] Discarding Rare/Epic/Legendary items requires double-confirm dialog
- [ ] Key Items cannot be sold or discarded (buttons do not appear)
- [ ] Sort re-orders list immediately and persists across sessions

### Combat vs Out-of-Combat

- [ ] In combat, inventory opens as 70% scale centered panel with dimmed (not blacked out) background
- [ ] In combat, Sell/Discard/Sort/Enhance/Repair buttons are hidden
- [ ] Closing inventory in combat resumes combat timer immediately
- [ ] Equip/unequip sounds are muted during combat
- [ ] Out-of-combat inventory opens as full-screen panel with blurred world background

### Animations & Audio

- [ ] Equip animation plays stat count-up over 0.4s with ease-out
- [ ] Unequip animation plays stat count-down over 0.3s with ease-in
- [ ] Equip swap plays dual animation (old drops in red, new rises in green)
- [ ] Popup open/close animations play at correct durations
- [ ] All audio events trigger correct sounds at correct volumes
- [ ] Combat mode correctly mutes non-essential UI sounds

### Input Support

- [ ] Full gamepad navigation (D-pad tabs/list, A select, B close, Y tooltip)
- [ ] Mouse interaction (click tabs, scroll list, hover tooltips)
- [ ] Keyboard support (ESC closes, Tab switches tabs, arrow keys navigate list)
- [ ] Touch interaction (tap tabs, swipe list, tap-and-hold for detail popup)
