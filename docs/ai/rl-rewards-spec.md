# Reinforcement Learning Rewards & Penalties Specification

This document details the reward signals used to train the Party AI (Evan, Evelyn, Witch) and the Enemy Hive AI.

## 1. Individual Party Agent Rewards (Step-by-Step)
These rewards are applied immediately to individual agents based on their specific actions.

| Action / Event | Reward Value | Weight Constant | Notes |
| :--- | :--- | :--- | :--- |
| **Damage Dealt** | `+0.001` per HP | `w_damage_dealt` | Primary aggression signal. |
| **Damage Received** | `-0.0011` per HP | `w_damage_received` | **Updated April 2026**: Set to 1.1x Deal to discourage hit-trading. |
| **Skill Cast (Instant)** | `+0.0025` | `w_skill_hit * 0.5` | Immediate reward for starting a skill. |
| **Skill Cast (Finish)** | `+0.0075` - `+0.01` | `w_skill_hit * 1.5/2.0` | Reward for completing a cast (Projectile vs Area). |
| **Attack (Finish)** | `+0.01` | Mirror of Skill | Reward for completing basic/special attacks. |
| **Projectile Hit** | `+0.01` | `w_skill_hit * 2.0` | Reward when a launched projectile hits a target. |
| **Heal Applied** | `+0.002` per HP | `w_heal_given` | Primary signal for Support/Mage roles. |
| **Dodge/Miss** | `+0.0075` | `w_skill_hit * 1.5` | Reward when an enemy projectile misses this agent. |
| **Team Kill** | `+0.2` | `0.5 * w_team` | Individual share of a team kill reward. |
| **Tank Protection** | `+0.003` | Fixed | Reward for Evan blocking Evelyn from enemy LOS. |

## 2. Penalties & Negative Signals
These are used to discourage inefficient or dangerous behavior.

| Event | Penalty Value | Weight Constant | Notes |
| :--- | :--- | :--- | :--- |
| **Waiting/Idle** | `-0.001` | `w_idle` | Penalizes doing nothing when not casting. |
| **Casting & Moving** | `-0.001` | `w_idle` | Penalty for trying to move while a cast is in-flight. |
| **Projectile Miss** | `-0.005` | `w_skill_hit * 1.0` | Penalizes our own missed shots. |
| **Arena Boundary** | `-0.1` | `w_boundary_penalty` | Discourages staying near or outside arena walls. |

## 3. Positioning & Tactical Rewards (Periodic)
Evaluated every step based on spatial relationships.

| Metric | Reward / Penalty | Condition |
| :--- | :--- | :--- |
| **Mage Spacing** | `+0.001` / `-0.002` | Evelyn rewarded for distance (6-12m), penalized for closeness (<4.5m). |
| **Tank Spacing** | `+0.001` / `-0.003` | Evan rewarded for closeness (<3m) if HP > 50%, penalized if HP < 50%. |
| **Flawless Play** | `+0.05` | Reward for dealing damage and taking NONE for 120 steps after. |

## 4. Episode Statistics & Terminal Rewards
Calculated at the end of an episode (Victory or Defeat).

| Event | Value | Calculation |
| :--- | :--- | :--- |
| **Victory** | `+1.0` | Applied to TeamAgent and shared. |
| **Defeat** | `-1.0` | Applied to TeamAgent and shared. |
| **Efficiency Bonus** | `+0.5` to `-0.2` | `clamp(log2(DamageDealt / DamageReceived) * 0.1, -0.2, 0.5)` |

**Note on Efficiency Damage:** The "Efficiency" stat displayed in HUDs is the raw ratio (`Dealt / Received`). The reward bonus uses a logarithmic scale to ensure that increasing efficiency from 1.0 to 2.0 is rewarded as much as from 2.0 to 4.0.
