# Party Management System

> **Status**: Approved
> **Author**: Design session 2026-04-11 (interactive redesign)
> **Last Updated**: 2026-04-11
> **Implements Pillar**: The Party Is the Game

## Overview

The Party Management System is the player's window into their party's state, growth, and readiness. Accessed from the pause menu, it presents all current party members as a row of character cards showing portrait, level, HP/MP, and XP progress. Selecting a character opens a split view with the character list on the left and a tabbed detail panel on the right — Stats (with bonus point allocation), Equipment (with side-by-side item picker), Skills (tier progress), and Passives (unlock tracking). The screen is read-only during combat and shows dead characters with a KO overlay. The party composition is story-driven — the chapter determines who is present — so this system focuses on management, not selection. **This system does not include formation or party selection — those are controlled by narrative events and chapter state.**

## Player Fantasy

Party Management serves the fantasy of **caring for your companions**. Between chapters, the player opens this screen to check on their team. They see Evelyn's ATK climbing from bonus points they invested. They notice Evan's weapon is still the starter gear and swap it for something better from the inventory. The Witch's passives are unlocking — she's becoming more than just a prologue NPC. Each character card is a window into a person, not a spreadsheet. The player feels the weight of preparation before a dangerous chapter: *is my team ready?* The split view — character list on the left, detail on the right — keeps everyone visible while letting the player focus on one person at a time.

**Reference model**: Final Fantasy X's Sphere Grid (clear progression path), Tales of Berseria's party status screen (portrait-forward, story-oriented), and Fire Emblem's support conversations (character identity matters as much as numbers).

## Detailed Rules

### Core Rules

1. **Access**: The Party Management screen is opened from the Pause Menu via a "Party" option. It is accessible at any time during gameplay except during cutscenes and dialogue (the pause menu is blocked in those states).

2. **Party Roster**: The screen shows all current party members (story-determined, 2–6 characters depending on chapter) as a horizontal row of character cards. Each card displays:
   - Character portrait (128×128)
   - Character name and class label (e.g., "Evelyn — Vampire Mage")
   - Level badge (prominent number) + XP progress bar (current XP / XP to next level)
   - HP bar (current/max) and MP bar (current/max)
   - KO overlay if dead (gray tint + "KO" badge)
   - Unspent bonus point indicator ("✦N" badge if > 0)

3. **Character Selection**: Clicking a character card opens a **split view**: the roster stays visible on the left (narrowed), and a tabbed detail panel opens on the right. Clicking another character card swaps the detail panel to that character without closing the split view.

4. **Detail Panel Tabs**:
   - **Stats**: Full stat block (MaxHP, ATK, DEF, SPD, CRIT, MaxMP) showing three columns: Base (from CharacterData), Equipment Bonus (green "+N"), and Effective Total. If the character has unspent bonus points, an allocator appears at the bottom of this tab: 3 buttons (ATK +1, DEF +1, MaxMP +1) with a "Remaining: ✦N" counter and a small "Reset" button that undoes all allocations made in the current session (does not reset bonus points spent in previous sessions or level-ups).
   - **Equipment**: 5 slots (Weapon, Armor, Helmet, Accessory, Relic) with currently equipped items. Each slot has a "Change" button (or "Equip" if empty). Equipment changes are delegated to the Inventory & Equipment System's `EquipmentManager.Equip()` — this system is the UI layer only.
   - **Skills**: 4 skill slots showing skill icon, name, current tier (Tier 1/2/3), and next tier unlock level (e.g., "Tier 2 at Level 8").
   - **Passives**: Vertical list of all passives for this character, each showing unlock level and locked/unlocked status (✓/✗).

5. **Equipment Change Flow**: Pressing "Change" on an equipment slot opens a **side-by-side picker**: the currently equipped item is shown on the left, and a scrollable list of compatible items from Party Inventory is shown on the right. Each candidate item shows a stat delta preview: "Current: ATK+12 → New: ATK+20 (**+8**)". The player confirms the swap, which applies immediately.

6. **Bonus Point Allocation**: If the character has unspent bonus points, the Stats tab shows an allocator at the bottom. The player clicks ATK+1, DEF+1, or MaxMP+1 to spend points. Each click immediately applies the stat and decrements the counter. Changes are instant — no confirmation dialog. A "Reset" button (small, at the bottom) lets the player undo all uncommitted allocations in this session.

7. **Read-Only During Combat**: If the pause menu is opened during combat, the Party Management screen can still be opened but all modification buttons (Change Equipment, Bonus Point allocator, Reset) are grayed out with a tooltip: "Cannot change during combat." View tabs and read data freely.

8. **Dead Characters**: KO'd characters display with a gray overlay on their portrait and a "KO" badge. Their HP bar shows "0 / [MaxHP]." Their detail panel is viewable but the Equipment and Bonus Points sections are locked with a tooltip: "Character is KO'd."

9. **Close Behavior**: Pressing Cancel/Escape closes the detail panel and returns to the full-width roster view. Pressing Cancel again closes Party Management and returns to the Pause Menu. All changes are applied immediately — there is no "confirm all" step.

10. **Save/Load**: Equipment assignments and bonus point allocations persist through save/load. The save file stores: `equipment` (slot→item mapping per character) and `bonusPointAllocations` (per-character allocation records).

### States and Transitions

```
┌──────────┐  Open from     ┌──────────────────┐
│  Pause   │  Pause Menu    │  Party Roster    │
│  Menu    │ ──────────────▶│  (card overview) │
└──────────┘                └────────┬─────────┘
                                     │ Select character
                                     ▼
                            ┌──────────────────┐
                            │  Split View      │
                            │  Roster | Detail │
                            └────────┬─────────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
          ▼                          ▼                          ▼
   ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
   │  Stats Tab   │        │ Equipment Tab│        │  Skills Tab  │
   │  + Bonus Pts │        │ + Side Picker│        │ (read-only)  │
   └──────────────┘        └──────┬───────┘        └──────────────┘
                                  │ Change button
                                  ▼
                         ┌──────────────────┐
                         │  Side-by-Side    │
                         │  Item Picker     │
                         │  + Stat Preview  │
                         └────────┬─────────┘
                                  │ Confirm swap
                                  ▼
                         ┌──────────────────┐
                         │  Equipment       │
                         │  Applied         │
                         └──────────────────┘
```

### Interactions with Other Systems

| System | Direction | What This System Does | What It Receives Back |
|--------|-----------|----------------------|----------------------|
| **Character Data** | Reads | Reads base stats, class, skill definitions, passive definitions | Character definitions |
| **Character Progression** | Reads | Reads level, XP, tier unlocks, unspent bonus points | Level/XP data, bonus point counts |
| **Inventory & Equipment** | Reads + Writes | Reads equipped items; writes equipment swaps; reads compatible items from inventory | Item references, equipment modification events |
| **Health & Damage** | Reads | Reads current HP, MaxHP, alive/dead state | HP values, death flags |
| **Status Effects** | Reads | Soft | Reads active buffs/debuffs for status summary (future use) | Active effect list |
| **Combat System** | Reads | Soft | Reads encounter state (disables modifications during combat) | `IsInCombat` flag |
| **Chapter State System** | Reads | Soft | Reads current chapter for context header | Chapter name, number |
| **Shop System** | Reads | Soft | Reads party inventory for item sell price when player sells from Equipment tab | Item sell price |
| **Save / Load** | Serialized | Hard | Equipment assignments and bonus point allocations are saved/loaded | — |
| **Combat HUD** | Writes | Sends equipment change events for HUD update | — |

## Formulas

| Formula | Expression | Variables | Notes |
|---------|-----------|-----------|-------|
| **Effective Stat** | `BaseStat + LevelGrowth + EquipmentBonus + BonusPoints` | All from respective systems | Displayed in Stats tab's "Total" column |
| **XP Progress %** | `currentXP / XPRequired(nextLevel) × 100` | From Character Progression | Shown on XP bar |

## Edge Cases

1. **Party has only 2 members**: Cards resize to fill available width. No empty placeholder slots.
2. **All characters at max level**: XP bars show "MAX" instead of progress. Bonus point allocator doesn't appear (no more points to earn).
3. **Player tries to unequip a character's only weapon (out of combat)**: Warning tooltip: "This character will have no weapon." Action is allowed but the equipment context is clear. This edge case applies only outside combat — equipment changes are locked during combat per Rule #7.
4. **Equipment swap leaves an orphan item no one can equip**: Item is still added to inventory with a label: "No character can equip this."
5. **Save/load during equipment swap animation**: Equipment change is applied instantly on load (no animation). Inventory state is consistent.
6. **Character leaves the party (story event)**: Their card is removed. Their equipped items are automatically moved to Party Inventory. Notification: "[Character] left the party. Equipment moved to inventory."
7. **New character joins mid-game**: Their card appears with a "Joined!" animation. All their data (level, XP, equipment, skills) is displayed from the start.
8. **Bonus points allocated mid-session vs. at level-up**: Both flows produce identical results. The Stats tab allocator is just an alternative path for unspent points.

## Dependencies

| System | Direction | Nature | Interface |
|--------|-----------|--------|-----------|
| Character Data | Reads | Hard | `CharacterData` Resources |
| Character Progression | Reads | Hard | `GetLevel()`, `GetXP()`, `GetUnspentBonusPoints()` |
| Inventory & Equipment | Reads + Writes | Hard | `Equip()`, `Unequip()`, `GetCompatibleItems(slot, class)` |
| Health & Damage | Reads | Hard | `CurrentHP`, `MaxHP`, `IsAlive` |
| Combat System | Reads | Soft | `IsInCombat` flag |
| Chapter State System | Reads | Soft | `CurrentChapter` |
| Save / Load | Serialized | Hard | JSON: `equipment`, `bonusPointAllocations` |
| Combat HUD | Writes | Soft | `OnEquipmentChanged(character, slot, newItem)` event |

## Tuning Knobs

| Knob | Type | Default | Safe Range | Effect if Too High | Effect if Too Low |
|------|------|---------|------------|-------------------|-------------------|
| `PortraitSize` | int | `128px` | 96–192 | Cards feel cluttered | Portraits too small; characters lose identity |
| `CardMinWidth` | int | `180px` | 140–240 | Cards feel cramped | Cards overflow screen with 6 characters |
| `BonusPointResetEnabled` | bool | `true` | true/false | Player can't undo mistakes | Player stuck with bad allocations |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Party screen opens | Roster cards slide in with staggered timing | Menu open whoosh | High |
| Character card selected | Split view slides in; selected card highlights | Soft click | High |
| Tab switch | Tab buttons highlight; content crossfades | Tab click sound | Medium |
| Equipment swap confirmed | Item icon flies to slot; stat numbers animate green "+N" | Equip chime — satisfying "click" | High |
| Bonus point allocated | Stat number increments with upward animation; counter decrements | Point allocation click | High |
| Dead character shown | Gray overlay on portrait; "KO" badge | No sound | High |
| New character joins | "Joined!" banner animates across card; card slides in | Warm chime | High |
| Combat lock active | Modification buttons grayed out with tooltip | No sound | Medium |

## UI Requirements

| Screen | Information | Condition |
|--------|-------------|-----------|
| **Party Roster** | Character cards (portrait, name, class, level badge, XP bar, HP/MP bars, KO overlay, bonus point badge) | Opened from Pause Menu > Party |
| **Split View Detail** | Current chapter name header (e.g., "Chapter 2: The Vanishing"), roster narrowed on left; tabbed detail panel on right (Stats, Equipment, Skills, Passives) | Opened when a character card is selected |
| **Equipment Picker** | Side-by-side: current item on left, scrollable compatible items on right with stat delta preview | Opened from Equipment tab > Change button |
| **Bonus Point Allocator** | 3 buttons (ATK +1, DEF +1, MaxMP +1) with "Remaining: ✦N" counter, Reset button | Shown in Stats tab when unspent points > 0 |

## Acceptance Criteria

- [ ] Party roster shows all active party members with correct portraits, names, classes, levels, HP/MP, and XP bars
- [ ] Selecting a character opens split view with roster on left and tabbed detail on right
- [ ] Switching between characters in split view updates detail panel without closing the view
- [ ] Stats tab shows Base, Equipment Bonus, and Effective Total columns for all 6 stats
- [ ] Equipment tab shows all 5 slots with equipped items; empty slots show "Equip" button
- [ ] Equipment picker filters items by slot type and character class — incompatible items are hidden
- [ ] Equipment picker shows correct stat delta preview for each candidate item ("Current: ATK+12 → New: ATK+20 (+8)")
- [ ] Equipment swap applies immediately and updates effective stats — verified by unit test
- [ ] Skills tab shows current tier for each skill and next tier unlock level
- [ ] Passives tab shows locked/unlocked status for each passive with correct unlock level
- [ ] Bonus point allocator appears in Stats tab only when unspent points > 0
- [ ] Bonus point allocation applies immediately and persists through save/load
- [ ] All modifications are disabled during combat (buttons grayed out with tooltip)
- [ ] Dead characters show gray overlay with KO badge; detail panel is view-only for dead characters
- [ ] Save/load preserves equipment assignments and bonus point allocations
- [ ] When a character leaves the party, their equipment moves to Party Inventory
- [ ] Cancel/Escape closes detail panel → returns to full roster → closes to Pause Menu

## Open Questions

| Question | Owner | Resolution Target |
|----------|-------|-------------------|
| Should the Party Management screen include a "Recommended Equipment" suggestion system (the game suggests better gear from inventory)? | UX Designer | Resolve during UI implementation — nice-to-have for Polish |
| Should the player be able to sell equipped items directly from the Equipment tab (shortcut to Shop sell flow)? | Game Designer | Resolve during Shop System implementation |
| Should dead characters' equipment be accessible for reassignment (unequip KO'd character to give gear to another)? | Game Designer | Recommendation: no for MVP — adds complexity; defer to Polish if needed |
| Should the screen show a combined party power score (sum of all effective stats) as a high-level readiness metric? | Systems Designer | Resolve after Alpha — nice-to-have for Polish phase |
