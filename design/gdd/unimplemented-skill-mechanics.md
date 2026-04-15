# Unimplemented Skill Mechanics: Lineage 2M Import

This document tracks mechanics found in the Lineage 2M skill import that are not yet supported by the core engine. These must be implemented to fully support the imported skill set.

## High Priority Mechanics

| Mechanic | Description | Example Skills |
| :--- | :--- | :--- |
| **Blood Force (Stacks)** | A character-specific secondary resource that generates on certain hits and is consumed by others. | Blade Whip, Unleash, Bloodlust |
| **Shadow Clones** | Spawning a temporary NPC/Entity that mimics the player's attacks or deals independent damage. | Shadow Blade, Phantom Blade |
| **Stealth / Hide** | Removing the character from enemy AI targeting and providing a "break-stealth" damage bonus. | Hide, Reinforced: Hide |
| **Teleportation** | Instant movement to a random location, behind a target, or a fixed distance forward. | Teleport, Shadow Step, Whip Dash |
| **Cooldown Manipulation** | Skills that fully reset or significantly reduce the cooldown of other skills. | Reset Movement, Restore Casting |
| **Catalyst Costs** | Requiring a specific item (e.g., "Ore") in inventory to activate the skill. | Ultimate Defense, Authority, Pray |
| **Buff Dispel/Steal** | Logic to identify and remove active `StatusEffect` instances from a target. | Cancellation, Whip Steal, Scourge |
| **Auto-Resurrection** | A passive check that prevents death and restores HP to full (one-time or on cooldown). | Salvation |

## Medium Priority Mechanics

| Mechanic | Description | Example Skills |
| :--- | :--- | :--- |
| **Scaling (HP %)** | Damage or healing formulas that reference `Target.CurrentHP` or `Caster.MaxHP`. | Vengeance, Cruel Slasher, Pain of Karma |
| **Complex CC (Fear/Bind)** | Fear: Forced movement away from caster. Bind: Combined Stun + Teleport Block + DoT. | Sonic Blaster, Blood Shackle |
| **Zone Effects** | Persistent area-of-effect nodes that apply buffs/debuffs to anyone inside (e.g., Invincibility zone). | Vampiric Zone, Blessed Sanctuary |
| **Vision/Marking** | Highlighting a specific target to grant the party bonus damage or defense against them. | Vision of Assassin, Death Mark |

## Low Priority Mechanics

| Mechanic | Description | Example Skills |
| :--- | :--- | :--- |
| **Proc-on-Proc** | Skills that have a chance to trigger another higher-tier skill automatically on hit. | Double Slash -> Triple Slash |
| **Absolute Accuracy** | A stat that ignores a percentage of the target's Evasion/Block rate. | Absolute Accuracy I-IV |
| **Weight Penalties** | Mechanics that allow resource recovery to ignore inventory weight thresholds. | Concentration |
| **Evil Reputation Scaling** | Bonus damage based on a "Karma" or "Reputation" variable on the target. | Chaos Hunter, Holy Focus |
