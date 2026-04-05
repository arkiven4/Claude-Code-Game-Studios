# Task for Qwen — Create Status Effect .tres Resources

Your job: create the StatusEffect resource files for stun and slow,
then update the skill .tres files that should apply them.

**Do NOT modify** any `.gd` source files — data only.

---

## Context

This is a Godot 4.6 project. Status effects are defined as `.tres` resource files
using the `StatusEffect` class (`src/core/status_effect.gd`).

**StatusEffect enums (exact integer values)**:
```
EffectType:     0=BUFF, 1=DEBUFF, 2=DOT, 3=CROWD_CONTROL, 4=SHIELD
EffectCategory: 0=STAT_MODIFIER, 1=DAMAGE_OVER_TIME, 2=MOVEMENT_IMPAIR, 3=ACTION_DENIAL, 4=DAMAGE_ABSORPTION
StatToModify:   0=NONE, 1=ATK, 2=DEF, 3=SPD, 4=MAX_HP, 5=MAX_MP, 6=CRIT
ModifyType:     0=PERCENTAGE, 1=FLAT
StackingRule:   0=NO_STACK, 1=ADDITIVE_STACK, 2=DURATION_STACK
DamageCategory: 0=PHYSICAL, 1=MAGICAL, 2=HOLY, 3=DARK
```

**StatusEffect .tres template**:
```
[gd_resource type="Resource" script_class="StatusEffect" format=3]

[ext_resource type="Script" path="res://src/core/status_effect.gd" id="1_fx"]

[resource]
script = ExtResource("1_fx")
effect_id = "..."
display_name = "..."
description = "..."
effect_type = ...
effect_category = ...
stat_to_modify = ...
modify_type = ...
effect_value = ...
duration = ...
tick_interval = 0.0
stacking_rule = 0
max_stacks = 1
dispellable = true
is_hostile = true
```

---

## Task 1 — Create `assets/data/status_effects/stun.tres`

A stun that completely denies all actions for a brief duration.

```
effect_id = "stun"
display_name = "Stunned"
description = "Stunned — cannot act."
effect_type = 3          ## CROWD_CONTROL
effect_category = 3      ## ACTION_DENIAL
stat_to_modify = 0       ## NONE (no stat change, just action lock)
modify_type = 0          ## PERCENTAGE (unused, but required)
effect_value = 0.0
duration = 1.5
tick_interval = 0.0
stacking_rule = 0        ## NO_STACK
max_stacks = 1
dispellable = true
is_hostile = true
```

---

## Task 2 — Create `assets/data/status_effects/slow.tres`

A movement slow that reduces the target's move speed.
`effect_value = 0.5` means movement is multiplied by 0.5 (50% speed).
The code reads `effect_value` from this resource to scale velocity.

```
effect_id = "slow"
display_name = "Slowed"
description = "Movement speed reduced by 50%."
effect_type = 1          ## DEBUFF
effect_category = 2      ## MOVEMENT_IMPAIR
stat_to_modify = 3       ## SPD
modify_type = 0          ## PERCENTAGE
effect_value = 0.5       ## multiplier (0.5 = 50% of normal speed)
duration = 3.0
tick_interval = 0.0
stacking_rule = 0        ## NO_STACK
max_stacks = 1
dispellable = true
is_hostile = true
```

---

## Task 3 — Update `assets/data/skills/enemies/archer_super_shot.tres`

Add the stun status effect to `effects_to_apply`. The archer's power shot stuns
on hit. Keep all existing fields — only add the `effects_to_apply` line.

Find this block in the file:
```
[ext_resource type="Script" path="res://src/core/skill_data.gd" id="1_skill"]
[ext_resource type="Script" path="res://src/core/skill_tier_config.gd" id="2_tier"]
```

Add after those ext_resource lines:
```
[ext_resource type="Resource" path="res://assets/data/status_effects/stun.tres" id="3_stun"]
```

Then on the `[resource]` section, add:
```
effects_to_apply = Array[Resource]([ExtResource("3_stun")])
```

---

## Task 4 — Update `assets/data/skills/enemies/mage_slow.tres`

Add the slow status effect to `effects_to_apply`. Keep all existing fields.

Find the ext_resource section and add:
```
[ext_resource type="Resource" path="res://assets/data/status_effects/slow.tres" id="3_slow"]
```

Then on the `[resource]` section, add:
```
effects_to_apply = Array[Resource]([ExtResource("3_slow")])
```

---

## Output Checklist

- [ ] `assets/data/status_effects/stun.tres`
- [ ] `assets/data/status_effects/slow.tres`
- [ ] `assets/data/skills/enemies/archer_super_shot.tres` — `effects_to_apply` added
- [ ] `assets/data/skills/enemies/mage_slow.tres` — `effects_to_apply` added
