# Task for Qwen — Create Enemy Skill .tres Files

Your job: design and create all skill resource files for 3 enemy types.
Gemini will handle the code implementation separately — you only write .tres files.

---

## Context

This is a Godot 4.6 project. Skills are defined as `.tres` resource files using the
`SkillData` class. Enemies do NOT use MP — their skills are regulated by cooldown only
(always set `mp_cost = 0`). Each enemy skill only needs **1 tier** (not 3).

---

## SkillData Resource Format

Use this exact .tres template for every skill file:

```
[gd_resource type="Resource" script_class="SkillData" format=3]

[ext_resource type="Script" path="res://src/core/skill_data.gd" id="1_skill"]
[ext_resource type="Script" path="res://src/core/skill_tier_config.gd" id="2_tier"]

[sub_resource type="Resource" id="Tier1"]
script = ExtResource("2_tier")
effect_value = 1.0        ## damage multiplier (1.0 = 100% of base_damage)
area_radius = 0.0         ## 0 = point target, >0 = area of effect
tier_description = "..."  ## short description of this tier

[resource]
script = ExtResource("1_skill")
skill_type = 0            ## 0=DAMAGE, 1=STATUS, 2=SUPPORT, 3=UTILITY
display_name = "..."
skill_id = "..."          ## snake_case, must match filename
description = "..."       ## player-visible description
mp_cost = 0               ## ALWAYS 0 for enemies
base_cooldown = 5.0       ## seconds between uses
max_charges = 1
target_type = 0           ## see TargetType enum below
target_count = 1
max_cast_range = 0.0      ## 0 = melee range, >0 = ranged
area_radius = 0.0
tiers = Array[Resource]([SubResource("Tier1")])
base_damage = 0           ## base damage value (0 for non-damage skills)
damage_category = 0       ## 0=PHYSICAL, 1=MAGICAL
shield_value = 0          ## for UTILITY block skills only
grants_invincibility = false
invincibility_duration = 0.0
```

### TargetType enum values:
- `0` = SINGLE_ENEMY (target one party member)
- `2` = MULTI_ENEMY_CONE (cone in front of enemy — good for slash attacks)
- `3` = ALL_ENEMIES (hits entire party)
- `6` = SELF (targets the enemy itself — for shield/buff skills)

---

## Skills to Create

Save all files in: `assets/data/skills/enemies/`

### GRUNT (Melee fighter — red capsule, base_atk = 25)

**File 1: `grunt_basic_slash.tres`**
Basic melee attack. Fast, short range. This is the fallback attack used frequently.
- skill_type = 0 (DAMAGE)
- target_type = 2 (CONE — cleave in front)
- max_cast_range = 0.0 (melee)
- area_radius = 2.5
- base_cooldown: ~0.8s (fast, frequent)
- base_damage: ~20 (light but fast)
- damage_category = 0 (PHYSICAL)
- effect_value: 0.9
- You decide: display_name, description, tier_description

**File 2: `grunt_super_slash.tres`**
A powerful overhead slam. Wider arc, deals heavy damage, moderate cooldown.
- skill_type = 0 (DAMAGE)
- target_type = 2 (CONE)
- max_cast_range = 0.0 (melee)
- area_radius = 3.5 (wider than basic)
- base_cooldown: ~8.0s
- base_damage: ~50 (heavy hit)
- effect_value: 1.4
- You decide: display_name, description, flavor

**File 3: `grunt_shield_block.tres`**
The Grunt raises its shield, briefly becoming invulnerable to the next hit.
Self-buff — targets itself.
- skill_type = 3 (UTILITY)
- target_type = 6 (SELF)
- max_cast_range = 0.0
- base_cooldown: ~12.0s
- base_damage = 0
- shield_value = 60 (absorbs this much damage)
- grants_invincibility = false (shield absorbs, doesn't make immune)
- effect_value = 1.0
- You decide: display_name, description

---

### ARCHER (Ranged fighter — orange capsule, base_atk = 35)

**File 4: `archer_basic_shot.tres`**
A quick arrow shot from range. Fired frequently at distance.
- skill_type = 0 (DAMAGE)
- target_type = 0 (SINGLE_ENEMY)
- max_cast_range = 10.0
- area_radius = 0.0 (precise shot)
- base_cooldown: ~1.2s
- base_damage: ~25
- damage_category = 0 (PHYSICAL)
- effect_value: 0.85
- You decide: display_name, description

**File 5: `archer_dash.tres`**
The Archer dashes forward, closing distance or repositioning.
Self-movement buff — treated as UTILITY.
- skill_type = 3 (UTILITY)
- target_type = 6 (SELF)
- max_cast_range = 0.0
- base_cooldown: ~10.0s
- base_damage = 0
- effect_value = 1.0
- shield_value = 0
- grants_invincibility = true (brief invincibility during dash)
- invincibility_duration = 0.3
- You decide: display_name, description

**File 6: `archer_super_shot.tres`**
A charged power shot that deals heavy damage and stuns the target briefly.
- skill_type = 0 (DAMAGE — stun implemented by Gemini via applied_status_effect)
- target_type = 0 (SINGLE_ENEMY)
- max_cast_range = 12.0
- area_radius = 0.0
- base_cooldown: ~14.0s
- base_damage: ~65 (big hit)
- damage_category = 0 (PHYSICAL)
- effect_value: 1.6
- You decide: display_name, description — mention the stun in the description

---

### MAGE (New enemy — purple capsule, base_atk = 28, magical attacker)

**File 7: `mage_basic_bolt.tres`**
A fast magic bolt fired at range. Bread-and-butter attack.
- skill_type = 0 (DAMAGE)
- target_type = 0 (SINGLE_ENEMY)
- max_cast_range = 9.0
- area_radius = 0.0
- base_cooldown: ~1.5s
- base_damage: ~22
- damage_category = 1 (MAGICAL)
- effect_value: 0.9
- You decide: display_name, description

**File 8: `mage_slow.tres`**
Fires a magic orb that slows the target's movement.
STATUS skill — Gemini will implement the slow effect.
- skill_type = 1 (STATUS)
- target_type = 0 (SINGLE_ENEMY)
- max_cast_range = 9.0
- area_radius = 0.0
- base_cooldown: ~9.0s
- base_damage = 0 (no direct damage — just the debuff)
- effect_value = 0.5 (represents 50% speed reduction — Gemini reads this)
- You decide: display_name, description — mention the slow

**File 9: `mage_skillshot.tres`**
A slow-moving but devastating magic projectile that tracks toward the target.
High damage, wide impact area.
- skill_type = 0 (DAMAGE)
- target_type = 0 (SINGLE_ENEMY)
- max_cast_range = 11.0
- area_radius = 1.5 (small splash on impact)
- base_cooldown: ~11.0s
- base_damage: ~70
- damage_category = 1 (MAGICAL)
- effect_value: 1.8
- You decide: display_name, description — make it feel threatening

---

## Power Level Guidelines

| Enemy | Basic attack dmg | Special 1 | Special 2 |
|-------|-----------------|-----------|-----------|
| Grunt | ~20 fast | ~50 heavy | 0 (shield) |
| Archer | ~25 fast | 0 (dash) | ~65 stun |
| Mage | ~22 medium | 0 (slow) | ~70 magic |

These values are relative to party HP (Evan ≈ 200 HP, Evelyn ≈ 160 HP).
A full super_slash should hurt but not one-shot. Adjust to feel right.

---

## Naming Rules

- `skill_id` must exactly match the filename without `.tres`
  - Example: file `grunt_super_slash.tres` → `skill_id = "grunt_super_slash"`
- `display_name` is what players see — make it punchy (1–3 words)
- `description` is the tooltip — 1 sentence, describe what it does mechanically

---

## Output Checklist

- [ ] `assets/data/skills/enemies/grunt_basic_slash.tres`
- [ ] `assets/data/skills/enemies/grunt_super_slash.tres`
- [ ] `assets/data/skills/enemies/grunt_shield_block.tres`
- [ ] `assets/data/skills/enemies/archer_basic_shot.tres`
- [ ] `assets/data/skills/enemies/archer_dash.tres`
- [ ] `assets/data/skills/enemies/archer_super_shot.tres`
- [ ] `assets/data/skills/enemies/mage_basic_bolt.tres`
- [ ] `assets/data/skills/enemies/mage_slow.tres`
- [ ] `assets/data/skills/enemies/mage_skillshot.tres`
