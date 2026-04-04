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

[To be designed]

## Detailed Design

### Core Rules

[To be designed]

### States and Transitions

[To be designed]

### Interactions with Other Systems

[To be designed]

## Formulas

[To be designed]

## Edge Cases

[To be designed]

## Dependencies

[To be designed]

## Tuning Knobs

[To be designed]

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

[To be designed]

## Open Questions

[To be designed]
