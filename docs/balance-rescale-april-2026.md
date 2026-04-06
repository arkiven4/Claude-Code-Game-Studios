# Balance Rescale: Party MP, Skill Cooldowns & Enemy Scaling

**Date**: 2026-04-06
**Scope**: Party MP budget, basic attack cooldown normalization, enemy stat rebalance

---

## Design Goals

1. **Party burst capacity**: Each character can afford all 4 equipped skills + 5 dashes in one burst window
2. **Basic attack cooldown**: Both party and enemy basic attacks land in the 1-2 second range
3. **Party DPS dominance**: Combined party DPS is ~4x larger than combined enemy DPS
4. **Enemy survivability**: Enemy HP is 8x the party's average original HP (270 × 8 = 2160)

---

## Party MP Adjustments

### Problem
At level 1, neither character had enough MP to cast all 4 skills + 5 dashes in one burst.

| Character | Old Max MP | Skills Cost | 5 Dashes Cost | Total Needed | Shortfall |
|---|---|---|---|---|---|
| Evan | 80 | 70 (0+20+15+35) | 75 (5×15) | 145 | -65 |
| Evelyn | 120 | 95 (15+25+30+25) | 75 (5×15) | 170 | -50 |

### Solution

| Character | Old Max MP | New Max MP |
|---|---|---|
| Evan | 80 | **145** |
| Evelyn | 120 | **170** |

### MP Regen

| What | Old | New | Rationale |
|---|---|---|---|
| `base_mp_regen` (party_member_state.gd) | 2.0/sec | **17.0/sec** | Recovers Evelyn's full burst (170 MP) in ~10 seconds |

---

## Party Basic Attack Cooldowns

Normalized to 1-2 second range.

| File | Old CD | New CD |
|---|---|---|
| `basic_sword_swing.tres` (Evan) | 0.4s | **1.0s** |
| `basic_minibolt.tres` (Evelyn) | 0.5s | **1.2s** |

Damage values unchanged.

---

## Enemy HP (8x Party Original Average)

Party original average HP = (320 + 220) / 2 = **270**
Enemy HP = 270 × 8 = **2160**

| File | Old HP | New HP |
|---|---|---|
| `grunt_melee.tres` | 150 | **2160** |
| `archer_ranged.tres` | 120 | **2160** |
| `mage_enemy.tres` | *missing* | **2160** |

---

## Enemy Skill Rebalance

### Basic Attacks

| File | Old Dmg | New Dmg | Old CD | New CD |
|---|---|---|---|---|
| `grunt_basic_slash.tres` | 20 | **20** (kept) | 0.8s | **1.5s** |
| `archer_basic_shot.tres` | 25 | **20** | 3.0s | **1.8s** |
| `mage_basic_bolt.tres` | 22 | **20** | 1.5s | **1.6s** |

### Special Skills

| File | Old Value | New Value | Old CD | New CD |
|---|---|---|---|---|
| `grunt_super_slash.tres` | damage 50 | damage **30** | 8.0s | **4.0s** |
| `grunt_shield_block.tres` | shield 60 | shield **30** | 12.0s | **6.0s** |
| `archer_super_shot.tres` | damage 65 | damage **30** | 14.0s | **4.0s** |
| `archer_dash.tres` | invinc 0.3s | invinc 0.3s (kept) | 10.0s | **5.0s** |
| `mage_slow.tres` | slow (kept) | slow (kept) | 9.0s | **5.0s** |
| `mage_skillshot.tres` | damage 70 | damage **30** | 11.0s | **4.5s** |

---

## DPS Verification

### Party Total DPS (with new cooldowns)

| Skill | Damage/Hit | Cooldown | DPS |
|---|---|---|---|
| Evan: Sword Swing | 30.0 | 1.0s | 30.00 |
| Evan: Crescent Slash | 68.25 | 1.2s | 56.88 |
| Evan: Shield Bash | 42.5 | 3.0s | 14.17 |
| Evan: Rending Storm | 130.5 | 6.0s | 21.75 |
| Evelyn: Minibolt | 31.15 | 1.2s | 25.96 |
| Evelyn: Dark Bolt | 69.0 | 1.0s | 69.00 |
| Evelyn: Abyssal Chain | 108.75 | 4.0s | 27.19 |
| **Party Total DPS** | | | **244.95** |

### Enemy DPS (per enemy)

| Skill | Damage/Hit | Cooldown | DPS |
|---|---|---|---|
| Basic Attack | 20 | 1.6s avg | 12.50 |
| Special Skill | 30 | 4.5s avg | 6.67 |
| **Per Enemy** | | | **19.17** |
| **3 Enemies Combined** | | | **57.50** |

### Ratio

| Metric | Value |
|---|---|
| Party DPS | 244.95 |
| Enemy Combined DPS | 57.50 |
| **Ratio (Party / Enemy)** | **4.26x** |

Target: 4x ✓

---

## Files Modified (20 total)

| # | File | Change |
|---|---|---|
| 1 | `assets/data/characters/evan.tres` | base_max_mp 80→145 |
| 2 | `assets/data/characters/evelyn.tres` | base_max_mp 120→170 |
| 3 | `src/gameplay/party_member_state.gd` | base_mp_regen 2.0→17.0 |
| 4 | `assets/data/skills/basic_sword_swing.tres` | cooldown 0.4→1.0 |
| 5 | `assets/data/skills/basic_minibolt.tres` | cooldown 0.5→1.2 |
| 6 | `assets/data/skills/enemies/grunt_basic_slash.tres` | cooldown 0.8→1.5 |
| 7 | `assets/data/skills/enemies/archer_basic_shot.tres` | damage 25→20, cooldown 3.0→1.8 |
| 8 | `assets/data/skills/enemies/mage_basic_bolt.tres` | damage 22→20, cooldown 1.5→1.6 |
| 9 | `assets/data/skills/enemies/grunt_super_slash.tres` | damage 50→30, cooldown 8.0→4.0 |
| 10 | `assets/data/skills/enemies/grunt_shield_block.tres` | shield 60→30, cooldown 12.0→6.0, desc fix |
| 11 | `assets/data/skills/enemies/archer_super_shot.tres` | damage 65→30, cooldown 14.0→4.0 |
| 12 | `assets/data/skills/enemies/archer_dash.tres` | cooldown 10.0→5.0 |
| 13 | `assets/data/skills/enemies/mage_slow.tres` | cooldown 9.0→5.0 |
| 14 | `assets/data/skills/enemies/mage_skillshot.tres` | damage 70→30, cooldown 11.0→4.5 |
| 15 | `assets/data/enemies/grunt_melee.tres` | HP 150→2160, entry cooldowns 0.8/8.0/12.0 → 1.5/4.0/6.0 |
| 16 | `assets/data/enemies/archer_ranged.tres` | HP 120→2160, entry cooldowns 1.2/10.0/14.0 → 1.8/5.0/4.0 |
| 17 | `assets/data/enemies/mage_enemy.tres` | HP →2160 (added missing field), entry cooldowns 1.5/9.0/11.0 → 1.6/5.0/4.5 |
