# Task for Gemini — Fix Unimplemented Skill Effects

Two isolated code fixes. Both are in existing files — no new files needed.

**Engine**: Godot 4.6 GDScript (statically typed)
**Do NOT modify**: `src/core/skill_data.gd`, `src/core/status_effect.gd`

---

## Context

Qwen is creating `assets/data/status_effects/stun.tres` and `slow.tres`.
Your job is the two code fixes that make those resources actually work at runtime.

---

## Fix 1 — `_execute_friendly_skill` in `src/gameplay/skill_execution_system.gd`

### Problem

`_execute_friendly_skill` (line 190) only spawns a green VFX flash and returns.
It never applies heals, shields, invincibility, or status effects.
The method `_apply_skill_to_target` already exists at line 221 and is correct —
it's just never called from `_execute_friendly_skill`.

### Current broken code (lines 190–194):

```gdscript
func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if caster_node:
		_spawn_skill_vfx(caster_node.global_position + Vector3(0, 1.0, 0), Color(0.2, 1.0, 0.4))
```

### Replace with:

```gdscript
func _execute_friendly_skill(skill: SkillData, tier_config: SkillTierConfig, effect_value: float, target_count: int, tier: int) -> void:
	var caster_node: Node3D = state.get_parent() as Node3D
	if not caster_node: return

	_spawn_skill_vfx(caster_node.global_position + Vector3(0, 1.0, 0), Color(0.2, 1.0, 0.4))

	if skill.target_type == SkillData.TargetType.SELF:
		## Self-targeted: apply directly to caster's own state
		_apply_skill_to_target(skill, state, effect_value, tier)
		return

	## ALL_ALLIES: apply to every living party member
	if skill.target_type == SkillData.TargetType.ALL_ALLIES:
		var party := get_tree().get_nodes_in_group("PartyMembers")
		for member in party:
			var member_state: Node = member.get_node_or_null("PartyMemberState")
			if member_state and member_state.get("is_alive"):
				_apply_skill_to_target(skill, member_state, effect_value, tier)
		return

	## SINGLE_ALLY: apply to the lowest-HP living ally (or self if none found)
	var party := get_tree().get_nodes_in_group("PartyMembers")
	var best_target: Node = state
	var lowest_hp_ratio: float = 1.0
	for member in party:
		var member_state: Node = member.get_node_or_null("PartyMemberState")
		if not member_state or not member_state.get("is_alive"): continue
		var current_hp: int = member_state.get("current_hp") if "current_hp" in member_state else 1
		var max_hp: int = member_state.get("max_hp") if "max_hp" in member_state else 1
		var ratio: float = float(current_hp) / float(max_hp)
		if ratio < lowest_hp_ratio:
			lowest_hp_ratio = ratio
			best_target = member_state
	_apply_skill_to_target(skill, best_target, effect_value, tier)
```

---

## Fix 2 — Apply MOVEMENT_IMPAIR slow in `src/gameplay/player_movement_controller.gd`

### Problem

`PlayerMovementController` uses a hardcoded `move_speed` float and never checks
for active status effects. When a MOVEMENT_IMPAIR effect is applied (e.g., mage_slow),
the player's speed is not actually reduced.

`StatusEffectsSystem` is on each character node. It has a method `get_active_effects()`
that returns an `Array` of `ActiveEffect` objects, each having a `.effect_def`
field (a `StatusEffect` resource) with `.effect_category` and `.effect_value`.

### Change required

In `_physics_process`, before this line:
```gdscript
var target_velocity := move_dir * move_speed
```

First add a stun check — if stunned, zero out movement and return early:
```gdscript
## Freeze movement when stunned (ACTION_DENIAL)
var effects_node: Node = current.get_parent().get_node_or_null("StatusEffectsSystem")
var is_stunned: bool = false
if effects_node:
	for active_effect in effects_node.active_effects:
		var def: StatusEffect = active_effect.definition
		if def and def.effect_category == StatusEffect.EffectCategory.ACTION_DENIAL:
			is_stunned = true
			break
if is_stunned:
	character_node.velocity.x = move_toward(character_node.velocity.x, 0, move_speed * 10.0 * delta)
	character_node.velocity.z = move_toward(character_node.velocity.z, 0, move_speed * 10.0 * delta)
	character_node.move_and_slide()
	return
```

Then insert a speed multiplier calculation:
```gdscript
## Apply movement slow from active MOVEMENT_IMPAIR effects.
## StatusEffectsSystem is a sibling node on the character (same parent as PartyMemberState).
var effective_speed: float = move_speed
var effects_node: Node = current.get_parent().get_node_or_null("StatusEffectsSystem")
if effects_node:
	for active_effect in effects_node.active_effects:
		var def: StatusEffect = active_effect.definition
		if def and def.effect_category == StatusEffect.EffectCategory.MOVEMENT_IMPAIR:
			effective_speed *= def.effect_value  ## 0.5 = 50% speed

var target_velocity := move_dir * effective_speed
```

Also update the deceleration line below it. Find:
```gdscript
character_node.velocity.x = move_toward(character_node.velocity.x, 0, move_speed * 10.0 * delta)
character_node.velocity.z = move_toward(character_node.velocity.z, 0, move_speed * 10.0 * delta)
```

Change to use `effective_speed`:
```gdscript
character_node.velocity.x = move_toward(character_node.velocity.x, 0, effective_speed * 10.0 * delta)
character_node.velocity.z = move_toward(character_node.velocity.z, 0, effective_speed * 10.0 * delta)
```

**Note**: `effective_speed` is declared inside `_physics_process`. Calculate it once near
the top of `_physics_process` (after getting `current` and `character_node`), then use it
everywhere — including the dodge block — so it's always in scope.

**About `current`**: `switch_controller.current_character` returns a `PartyMemberState`.
`StatusEffectsSystem` is a sibling of `PartyMemberState` on the same character node, so
`current.get_parent().get_node_or_null("StatusEffectsSystem")` is the correct path.

---

## Note on Enemy-Side Slow/Stun

Enemy movement slow and stun checks are handled in `GEMINI_enemy_implementation.md`
(Task 2 and Task 3). This doc only covers the player/party side.

---

## Acceptance Criteria

- [ ] `_execute_friendly_skill` applies heals, shields, invincibility, and buffs correctly
  - `evelyn_shadow_mend` (SUPPORT/SINGLE_ALLY) — ally with lowest HP gets healed
  - `evan_parry_stance` (UTILITY/SELF) — Evan gets shield applied
  - `evelyn_shadow_veil` (UTILITY/SELF) — Evelyn becomes invincible
  - `witch_spirit_ward` (SUPPORT/ALL_ALLIES) — all party members get ATK buff
- [ ] When mage_slow hits the player, movement visibly slows to ~50% speed for 3 seconds
- [ ] When archer_super_shot hits the player, movement and input freeze for 1.5 seconds
- [ ] No null reference errors in either file
