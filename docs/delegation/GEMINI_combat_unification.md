# Combat System Unification — Delegation Task for Gemini

## Context

This is a Godot 4.6 GDScript project. The combat system currently has duplicated logic split
between two files:
- `src/gameplay/skill_execution_system.gd` — player side skill execution
- `src/gameplay/enemy_ai_controller.gd` — enemy AI + skill execution

Two utility classes are already shared correctly:
- `src/gameplay/health_damage_system.gd` — static damage/heal math
- `src/gameplay/combat_vfx.gd` — static VFX spawning

The goal is to unify duplicated logic into a new shared static class `CombatSkillExecutor`,
following the same pattern as `HealthDamageSystem` (pure static functions, no node state).

---

## Duplications Found (Code Review Output)

### Duplication 1 — Status Effect Apply Loop (4 COPIES — fix this first)

Same "find StatusEffectsSystem, iterate effects_to_apply, call apply_effect" block appears in:

| File | Function | Lines |
|------|----------|-------|
| `skill_execution_system.gd` | `_apply_effects_to_enemy()` | ~214–220 |
| `skill_execution_system.gd` | `_apply_status_skill()` | ~339–344 |
| `enemy_ai_controller.gd` | `_apply_on_hit_effects()` | ~304–310 |
| `enemy_ai_controller.gd` | `_apply_status_skill()` | ~312–318 |

**Bug note:** Player side looks up `target.get_node_or_null("StatusEffectsSystem")`,
enemy side uses `target.get_parent().get_node_or_null("StatusEffectsSystem")` — divergent paths.

### Duplication 2 — Tier Config Resolution (3 COPIES)

Same pattern (clamp tier_index, resolve tier_config, extract effect_value + target_count) in:
- `skill_execution_system.gd` lines ~47–51
- `skill_execution_system.gd` lines ~87–90 (repeated in `try_activate_attack`)
- `enemy_ai_controller.gd` lines ~265–266 (always uses tier 0, slightly different)

### Duplication 3 — Damage Calculation + Application (2 COPIES)

`HealthDamageSystem.calculate_damage()` → `take_damage()` → emit `damage_dealt` in:
- `skill_execution_system.gd` `_apply_damage_skill()` ~312–322
- `enemy_ai_controller.gd` `_apply_damage_skill()` ~264–302 (also has inline AoE loop)

**Note:** Enemy version applies `base_atk * 1.5` when enraged — this must be preserved.

### Duplication 4 — Utility Skill (shield + invincibility) (2 COPIES)

- `skill_execution_system.gd` `_apply_utility_skill()` ~346–355
- `enemy_ai_controller.gd` `_apply_utility_skill()` ~323–336

Enemy version uses a child `Timer` node (correct — freed with parent on death).
Player version uses `get_tree().create_timer()` (unsafe if node freed before timeout).

### Duplication 5 — VFX Fallback Sphere (1 COPY MISSING)

- `skill_execution_system.gd` `_spawn_skill_vfx()` ~258–282 has a fallback sphere when texture is null
- `enemy_ai_controller.gd` `_spawn_vfx()` calls `CombatVFX.spawn_effect` directly — no fallback (bug: enemy skills with no texture show nothing)

---

## Task: Implement the Unification

### Step 1 — Create `src/gameplay/combat_skill_executor.gd`

New static utility class. Pattern matches `HealthDamageSystem` exactly.

```gdscript
# combat_skill_executor.gd
class_name CombatSkillExecutor
extends Object

## Shared skill execution logic for both player and enemy combatants.
## Pure static functions, no node state — mirrors HealthDamageSystem pattern.

## Resolves tier config from a skill and tier index.
static func resolve_tier(skill: SkillData, active_tier: int) -> Dictionary:
    var tier_index: int = clampi(active_tier, 1, 3) - 1
    var tier_config: SkillTierConfig = skill.tiers[tier_index] if tier_index < skill.tiers.size() else null
    var effect_value: float = tier_config.effect_value if tier_config else 1.0
    var target_count: int = tier_config.target_count if tier_config and tier_config.target_count > 0 else skill.target_count
    var area_radius: float = tier_config.area_radius if tier_config and tier_config.area_radius > 0.0 else skill.area_radius
    return {
        "tier_config": tier_config,
        "effect_value": effect_value,
        "target_count": target_count,
        "area_radius": area_radius,
    }

## Calculates damage from a caster using a skill against a target.
## Both caster and target must implement ICombatant interface (see below).
static func calculate_skill_damage(caster: Node, skill: SkillData, effect_value: float, target: Node) -> Dictionary:
    var caster_atk: int = caster.get_effective_atk() if caster.has_method("get_effective_atk") else 10
    var target_def: int = target.get_effective_def() if target.has_method("get_effective_def") else 0
    var res: float = target.get_resistance(skill.damage_category) if target.has_method("get_resistance") else 1.0
    var crit_chance: float = caster.get_effective_crit() if caster.has_method("get_effective_crit") else 0.0
    return HealthDamageSystem.calculate_damage(caster_atk, skill.base_damage, effect_value, target_def, res, crit_chance)

## Applies all on-hit/on-cast status effects from a skill to a target.
## Finds StatusEffectsSystem via get_status_effects_system() or node/parent fallback.
static func apply_skill_effects(skill: SkillData, caster_id: String, target: Node, tier: int = 1) -> void:
    if skill.effects_to_apply.is_empty(): return
    var sfx: StatusEffectsSystem = null
    if target.has_method("get_status_effects_system"):
        sfx = target.get_status_effects_system()
    if not sfx:
        sfx = target.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
    if not sfx and target.get_parent():
        sfx = target.get_parent().get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
    if not sfx: return
    for effect_def in skill.effects_to_apply:
        if effect_def:
            sfx.apply_effect(effect_def, caster_id, tier)

## Applies a utility skill (shield, invincibility, MP restore) to a combatant.
## Uses a child Timer node for invincibility so it is freed safely if the node dies.
static func apply_utility(skill: SkillData, target: Node) -> void:
    if skill.mp_restore_amount > 0 and target.has_method("restore_mp"):
        target.restore_mp(skill.mp_restore_amount)
    if skill.shield_value > 0 and target.has_method("set_shield"):
        target.set_shield(skill.shield_value)
    if skill.grants_invincibility and target.has_method("set_invincible"):
        target.set_invincible(true)
        var timer := Timer.new()
        timer.wait_time = skill.invincibility_duration
        timer.one_shot = true
        target.add_child(timer)
        timer.timeout.connect(func() -> void:
            if is_instance_valid(target):
                target.set_invincible(false)
            timer.queue_free()
        )
        timer.start()

## Spawns hit VFX at position. Falls back to a colored emissive sphere if texture is null
## and fallback_color.a > 0.
static func spawn_hit_vfx(tree: SceneTree, position: Vector3, texture: Texture2D, fallback_color: Color = Color.TRANSPARENT) -> void:
    if texture:
        CombatVFX.spawn_effect(tree, position, texture)
        return
    if fallback_color.a <= 0.0: return
    var vfx := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.2
    mesh.height = 0.4
    vfx.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = fallback_color
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_enabled = true
    mat.emission = fallback_color
    mat.emission_energy_multiplier = 3.0
    vfx.material_override = mat
    tree.root.add_child(vfx)
    vfx.global_position = position
    var tween := tree.create_tween()
    tween.set_parallel(true)
    tween.tween_property(vfx, "scale", Vector3(1.5, 1.5, 1.5), 0.4)
    tween.tween_property(mat, "albedo_color", Color(fallback_color.r, fallback_color.g, fallback_color.b, 0.0), 0.4)
    tree.create_timer(0.45).timeout.connect(vfx.queue_free)
```

---

### Step 2 — Add ICombatant Methods to `EnemyAIController`

Add these public methods to `src/gameplay/enemy_ai_controller.gd`.
These make `EnemyAIController` compatible with `CombatSkillExecutor` as both caster and target.

```gdscript
## ICombatant interface — required by CombatSkillExecutor

func get_effective_atk() -> int:
    ## Enrage multiplier baked in here so CombatSkillExecutor.calculate_skill_damage() gets correct value.
    return int(enemy_data.base_atk * 1.5) if is_enraged else enemy_data.base_atk

func get_effective_def() -> int:
    return 0  # Enemies currently have no DEF stat

func get_effective_crit() -> float:
    return 0.0  # Enemies currently do not crit

func get_status_effects_system() -> StatusEffectsSystem:
    return get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem

func get_combat_node() -> Node3D:
    return self  # EnemyAIController IS the CharacterBody3D

func get_caster_id() -> String:
    return name

func set_shield(value: int) -> void:
    shield_value = max(0, value)
    shield_changed.emit(shield_value)

func set_invincible(value: bool) -> void:
    _is_invincible = value
```

---

### Step 3 — Refactor `EnemyAIController` to Use Shared Functions

Replace the four private methods listed below with calls to `CombatSkillExecutor`.

**Delete `_apply_on_hit_effects()`** (~lines 304–310) and replace its call site in `_apply_damage_skill` with:
```gdscript
CombatSkillExecutor.apply_skill_effects(skill, name, target)
```

**Delete `_apply_status_skill()`** (~lines 312–321) and replace its call site in `_execute_skill` with:
```gdscript
CombatSkillExecutor.apply_skill_effects(skill, name, target)
var target_node := target.get_parent() as Node3D
if target_node:
    CombatSkillExecutor.spawn_hit_vfx(get_tree(), target_node.global_position + Vector3(0, 1.0, 0), skill.vfx_effect, Color(0.6, 0.2, 1.0, 1.0))
```

**Delete `_apply_utility_skill()`** (~lines 323–336) and replace its call site in `_execute_skill` with:
```gdscript
CombatSkillExecutor.apply_utility(skill, self)
CombatSkillExecutor.spawn_hit_vfx(get_tree(), global_position + Vector3(0, 1.0, 0), skill.vfx_effect)
```

**Delete `_spawn_vfx()`** (~lines 338–339) — all call sites replaced by `CombatSkillExecutor.spawn_hit_vfx()`.

**In `_apply_damage_skill()`** — remove the inline `get_effective_atk` calculation and replace with:
```gdscript
var result: Dictionary = CombatSkillExecutor.calculate_skill_damage(self, skill, effect_value, target)
```

---

### Step 4 — Refactor `SkillExecutionSystem` to Use Shared Functions

**Replace tier resolution blocks** in `try_activate_skill` (~lines 47–51) and `try_activate_attack` (~lines 87–90):
```gdscript
var tier_data := CombatSkillExecutor.resolve_tier(skill, active_tier)
var effect_value: float = tier_data.effect_value
var target_count: int = tier_data.target_count
```

**Delete `_apply_effects_to_enemy()`** (~lines 214–220) and replace its call site:
```gdscript
CombatSkillExecutor.apply_skill_effects(skill, state.name if state else "", target)
```

**Delete `_apply_status_skill()`** (~lines 339–344) and replace its call site in `_apply_skill_to_target`:
```gdscript
CombatSkillExecutor.apply_skill_effects(skill, state.name, target, tier)
```

**Delete `_apply_utility_skill()`** (~lines 346–355) and replace its call site:
```gdscript
CombatSkillExecutor.apply_utility(skill, state)
```

**Replace `_spawn_skill_vfx()`** (~lines 258–282) body with a delegation:
```gdscript
func _spawn_skill_vfx(position: Vector3, color: Color, texture: Texture2D = null) -> void:
    CombatSkillExecutor.spawn_hit_vfx(get_tree(), position, texture, color)
```
(Can delete the function entirely if all call sites are updated to call `CombatSkillExecutor.spawn_hit_vfx` directly.)

---

## Priority Order

1. **Step 1** — Create `combat_skill_executor.gd` (no breakage, purely additive)
2. **Step 2** — Add ICombatant methods to `EnemyAIController` (additive only)
3. **Step 3** — Refactor `EnemyAIController` (delete 4 functions, replace with shared calls)
4. **Step 4** — Refactor `SkillExecutionSystem` (delete 4 functions, replace with shared calls)

Do NOT unify AoE target acquisition — player and enemy loops are architecturally different.

---

## Architecture Rules to Follow

- All new code must be statically typed GDScript (Godot 4.6)
- No new autoloads — `CombatSkillExecutor` is a static class like `HealthDamageSystem`
- Do not modify `combat_vfx.gd` or `health_damage_system.gd`
- `damage_dealt` signal must still be emitted by the caller (not by the static utility)
- Use `is_instance_valid()` guard in any timer callback that references a node

---

## Files to Read Before Starting

- `src/gameplay/skill_execution_system.gd`
- `src/gameplay/enemy_ai_controller.gd`
- `src/gameplay/combat_vfx.gd`
- `src/gameplay/health_damage_system.gd`
