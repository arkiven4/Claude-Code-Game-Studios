# combat_vfx.gd
class_name CombatVFX
extends Object

## Static VFX helpers shared by all combat systems (players and enemies).
## Mirrors the pattern of HealthDamageSystem — pure functions, no node state.

## Spawns a billboard impact/aura VFX at [position].
## If [texture] is null this is a no-op — callers don't need to guard.
static func spawn_effect(tree: SceneTree, position: Vector3, texture: Texture2D, color: Color = Color.WHITE) -> void:
	if not texture: return
	
	var vfx := MeshInstance3D.new()
	vfx.name = "VFX_Effect_" + str(Time.get_ticks_msec())
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.5, 1.5)
	vfx.mesh = mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.albedo_color = color # Apply tint
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vfx.material_override = mat
	
	# Fallback to root if current_scene is invalid
	var parent: Node = tree.current_scene
	if not is_instance_valid(parent):
		parent = tree.root
		
	parent.add_child(vfx)
	vfx.global_position = position
	
	print("[CombatVFX] Spawned billboard VFX at %s (parent: %s, texture: %s)" % [str(position), parent.name, texture.resource_path.get_file()])
	
	var tween := tree.create_tween()
	tween.set_parallel(true)
	tween.tween_property(vfx, "scale", Vector3(2.0, 2.0, 2.0), 0.4)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.4)
	tween.set_parallel(false)
	tween.tween_callback(vfx.queue_free)

## Instantiates a real Projectile node and adds it to the scene tree.
## Collision mask is set automatically: layer 8 for enemies, layer 2 for party members.
## Pass lifetime > 0 to override the default (used when firing with no target).
## Returns the spawned Projectile, or null if projectile_scene is unset.
static func spawn_projectile(
		tree: SceneTree,
		projectile_scene: PackedScene,
		skill: SkillData,
		damage_data, # Can be int or Dictionary
		caster_id: String,
		spawn_pos: Vector3,
		target_pos: Vector3,
		hit_enemies: bool,
		hit_allies: bool,
		lifetime: float = -1.0,
		target: Node = null) -> Node:
	if not projectile_scene: return null
	var projectile: Node = projectile_scene.instantiate()
	if not projectile: return null

	var dir := target_pos - spawn_pos
	if dir.length() > 0.01:
		projectile.global_transform = Transform3D(Basis.looking_at(dir.normalized(), Vector3.UP), spawn_pos)
	else:
		projectile.global_position = spawn_pos

	if projectile.has_method("set"):
		projectile.set("speed", skill.projectile_speed)
		if lifetime > 0.0:
			projectile.set("lifetime", lifetime)

	# Layer 1 = environment, layer 8 = enemy hurtbox, layer 2 = party hurtbox
	var mask: int = 1
	if hit_enemies: mask |= 8
	if hit_allies:  mask |= 2
	if projectile is Area3D:
		projectile.collision_mask = mask

	if projectile.has_method("initialize"):
		projectile.call("initialize", damage_data, caster_id, hit_enemies, hit_allies, skill.effect_overrides, skill.vfx_effect, skill.display_name, target)
	
	if skill.vfx_projectile and projectile.has_method("set_vfx"):
		projectile.call("set_vfx", skill.vfx_projectile)

	# Prefer current_scene over root to ensure same World3D/Environment
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	parent.add_child(projectile)
	return projectile

## Spawns a visual-only projectile quad that travels from [from] to [to].
## Damage is already resolved before this is called — purely cosmetic.
static func spawn_visual_projectile(tree: SceneTree, skill: SkillData, from: Vector3, to: Vector3) -> void:
	if not skill.vfx_projectile: return
	var vfx := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.8, 0.8)
	vfx.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = skill.vfx_projectile
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	vfx.material_override = mat
	
	# Prefer current_scene over root to ensure same World3D/Environment
	var parent: Node = tree.current_scene if tree.current_scene else tree.root
	parent.add_child(vfx)
	vfx.global_position = from
	var duration := maxf(from.distance_to(to) / maxf(skill.projectile_speed, 1.0), 0.05)
	var tween := tree.create_tween()
	tween.tween_property(vfx, "global_position", to, duration)
	tween.tween_callback(vfx.queue_free)
