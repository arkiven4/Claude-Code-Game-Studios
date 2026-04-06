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
static func calculate_skill_damage(caster: Node, skill: SkillData, effect_value: float, target: Node) -> Dictionary:
	var caster_atk: int = caster.get_effective_atk() if caster.has_method("get_effective_atk") else 10
	var target_def: int = target.get_effective_def() if target.has_method("get_effective_def") else 0
	var res: float = target.get_resistance(skill.damage_category) if target.has_method("get_resistance") else 1.0
	var crit_chance: float = caster.get_effective_crit() if caster.has_method("get_effective_crit") else 0.0
	
	var result := HealthDamageSystem.calculate_damage(caster_atk, skill.base_damage, effect_value, target_def, res, crit_chance)
	
	# Add metadata for logging
	result["caster_name"] = caster.name
	result["skill_name"] = skill.display_name
	
	return result

## Applies all on-hit/on-cast status effects from a skill to a target.
## Values (duration, magnitude, tick rate) come from SkillEffectOverride in skill.effect_overrides.
## tier_config.duration takes highest precedence for duration (enables tier-scaling effects).
## Finds StatusEffectsSystem via get_status_effects_system() or node/parent fallback.
static func apply_skill_effects(skill: SkillData, caster_id: String, target: Node, tier: int = 1) -> void:
	if skill.effect_overrides.is_empty(): return
	var sfx: StatusEffectsSystem = null
	if target.has_method("get_status_effects_system"):
		sfx = target.get_status_effects_system()
	if not sfx:
		sfx = target.get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
	if not sfx and target.get_parent():
		sfx = target.get_parent().get_node_or_null("StatusEffectsSystem") as StatusEffectsSystem
	if not sfx: return
	## Resolve tier duration (e.g. shadow_veil scales duration per tier).
	var tier_data := resolve_tier(skill, tier)
	var tier_config: SkillTierConfig = tier_data.get("tier_config") as SkillTierConfig
	var tier_dur: float = tier_config.duration if tier_config and tier_config.duration > 0.0 else 0.0
	for override in skill.effect_overrides:
		if not override or not override.effect_ref: continue
		## Duration precedence: tier_config.duration > override.duration > definition fallback (-1)
		var dur: float
		if tier_dur > 0.0:
			dur = tier_dur
		elif override.duration > 0.0:
			dur = override.duration
		else:
			dur = -1.0
		var val: float = override.effect_value if override.effect_value > 0.0 else -1.0
		var tick: float = override.tick_interval if override.tick_interval > 0.0 else -1.0
		sfx.apply_effect(override.effect_ref, caster_id, tier, dur, val, tick)

## Applies a utility skill (shield, invincibility, MP restore) to a combatant.
## Uses a child Timer node for invincibility so it is freed safely if the node dies.
static func apply_utility(skill: SkillData, target: Node, caster_id: String = "") -> void:
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
	
	apply_skill_effects(skill, caster_id, target)

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
