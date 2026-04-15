# TestArena.tscn Playable Showcase - TODO List

This document tracks the tasks required to make `TestArena.tscn` a fully playable showcase of the *My Vampire* gameplay loop.

## 1. Core Combat & Systems [DONE]
- [x] Static math utility (`HealthDamageSystem`)
- [x] Runtime state container (`PartyMemberState`)
- [x] Status effect lifecycle manager (`StatusEffectsSystem`)
- [x] 5-phase skill execution orchestrator (`SkillExecutionSystem`)
- [x] Mass import of Lineage 2M data (Skills, Items, Monsters)
- [x] Level-scaled stats for 579 monsters
- [x] LootTable generation and monster-to-item linking

## 2. Inventory & Equipment [DONE]
- [x] Per-character `ItemInventory` logic
- [x] Character-specific item collection (`LootPickup` update)
- [x] Item transfer logic between character inventories
- [x] "Transfer All" logic
- [x] Equip/Unequip logic in `InventoryUI`
- [x] Create `InventoryUI.tscn` (Visual scene with ItemList, Buttons, and Selectors)
- [x] Implement USS styling for rarity colors and "Equipped" highlights (Using ItemList display text logic)

## 3. UI & HUD [DONE]
- [x] `CombatHUD` logic (Active/Inactive portraits, HP/MP/Shield bars)
- [x] Create `CombatHUD.tscn` (Visual overlay for the arena)
- [x] Skill Bar with cooldown indicators (Logic exists in `SkillSlotUI`)
- [x] Floating `WorldHPBar` for enemies (Logic exists in `WorldHPBar.gd`)
- [x] Damage numbers / popups (Combat feedback manager implemented)

## 4. AI & Navigation [DONE]
- [x] Add `NavigationRegion3D` support for pathfinding
- [x] Integrate `NavigationAgent3D` into `EnemyAIController` for smart chasing
- [x] Implement `BTPartyAgent` (Behavior Tree) for competent companion AI
- [x] Implement `RLEnemyHiveAgent` for reinforcement learning training support

## 5. Playable Flow [DONE]
- [x] Character Switching: Integrate `CharacterSwitchController` with Camera follow
- [x] Character Switching: Integrate with CombatHUD portraits
- [x] Inventory Access: Toggle with 'inventory' key (pauses game)
- [x] Encounter Trigger: Spawn monsters and track stats
- [x] Victory/Defeat Overlay: Show results when all enemies are dead or party is wiped
- [x] Consumable Hotbar: Support for using items directly from the HUD

## 6. Visual Polish [DONE]
- [x] Skill VFX: Unified impact effects and hit flashes
- [x] Character Models: Placeholder capsules with toon-shading and outlines
- [x] Arena Environment: Basic geometry with toon-shaded materials
