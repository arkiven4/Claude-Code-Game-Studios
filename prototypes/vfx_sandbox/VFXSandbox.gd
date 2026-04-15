extends Node3D

## VFX Sandbox for testing Projectiles, Slashes, and Hit Impacts.

@onready var caster_pos: Marker3D = $CasterPos
@onready var target_pos: Marker3D = $TargetPos
@onready var target_dummy: Node3D = $TargetPos/TargetDummy
@onready var anim_player: AnimationPlayer = $TargetPos/TargetDummy/Skeleton_Mage/AnimationPlayer
@onready var caster_anim_player: AnimationPlayer = $CasterPos/Node3D/Skeleton_Mage/AnimationPlayer

@export var projectile_scene: PackedScene = preload("res://assets/scenes/Projectile.tscn")

## Texture used for the projectile itself.
@export var vfx_projectile_tex: Texture2D
## Texture used for the hit impact (explosion/spark).
@export var vfx_impact_tex: Texture2D
## Texture used for the slash/sweep effect.
@export var vfx_slash_tex: Texture2D
## Texture used for the casting/charging effect.
@export var vfx_cast_tex: Texture2D

func _ready() -> void:
	print("[VFXSandbox] Ready. Use the UI to trigger effects.")
	
	# Start idle animations
	if anim_player:
		anim_player.play("GeneralMage/Idle_A")
	if caster_anim_player:
		caster_anim_player.play("GeneralMage/Idle_A")
		
	# Ensure target dummy has a hurtbox
	var hurtbox = target_dummy.get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.took_hit.connect(_on_hurtbox_hit)

func spawn_projectile() -> void:
	if not projectile_scene:
		print("[VFXSandbox] Projectile scene not assigned!")
		return
	
	# Play caster animation
	if caster_anim_player:
		caster_anim_player.play("GeneralMage/Throw")
		# Return to idle after attack
		if not caster_anim_player.animation_finished.is_connected(_on_caster_anim_finished):
			caster_anim_player.animation_finished.connect(_on_caster_anim_finished)
	
	# Create a dummy SkillData for testing
	var skill = SkillData.new()
	skill.display_name = "Sandbox Projectile"
	skill.projectile_speed = 12.0
	skill.vfx_projectile = vfx_projectile_tex
	skill.vfx_effect = vfx_impact_tex # This is used as the impact texture in Projectile.gd
	
	print("[VFXSandbox] Spawning projectile...")
	CombatVFX.spawn_projectile(
		get_tree(),
		projectile_scene,
		skill,
		{ "damage": 10, "caster_name": "SandboxCaster", "skill_name": "Sandbox Projectile" },
		"SandboxCaster",
		caster_pos.global_position,
		target_pos.global_position,
		true, # hit_enemies
		false, # hit_allies
		5.0, # lifetime
		target_dummy
	)

func spawn_slash() -> void:
	# Play caster animation
	if caster_anim_player:
		caster_anim_player.play("GeneralMage/Use_Item")
		if not caster_anim_player.animation_finished.is_connected(_on_caster_anim_finished):
			caster_anim_player.animation_finished.connect(_on_caster_anim_finished)
			
	# Slashes are often instant hits with a specific visual.
	# We simulate the visual part here.
	print("[VFXSandbox] Spawning slash effect at target.")
	var pos = target_pos.global_position + Vector3(0, 0.5, 0)
	
	# If we have a slash texture, spawn it. 
	# We use spawn_effect which handles billboard quads.
	if vfx_slash_tex:
		CombatVFX.spawn_effect(get_tree(), pos, vfx_slash_tex)
	else:
		# Fallback to a colored hit vfx
		CombatSkillExecutor.spawn_hit_vfx(get_tree(), pos, null, Color.ORANGE)
	
	# Manually trigger the hurtbox for the sandbox
	var hurtbox = target_dummy.get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.take_hit({ "damage": 15, "skill_name": "Sandbox Slash" })

func spawn_hit_impact() -> void:
	print("[VFXSandbox] Spawning hit impact at target.")
	CombatSkillExecutor.spawn_hit_vfx(get_tree(), target_pos.global_position + Vector3(0, 0.5, 0), vfx_impact_tex, Color.YELLOW)
	
	# Manually trigger the hurtbox for the sandbox
	var hurtbox = target_dummy.get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.take_hit({ "damage": 5, "skill_name": "Sandbox Impact" })

func spawn_cast_vfx() -> void:
	# Play caster animation
	if caster_anim_player:
		caster_anim_player.play("GeneralMage/Use_Item")
		if not caster_anim_player.animation_finished.is_connected(_on_caster_anim_finished):
			caster_anim_player.animation_finished.connect(_on_caster_anim_finished)
			
	print("[VFXSandbox] Spawning cast/charging effect at caster.")
	var pos = caster_pos.global_position + Vector3(0, 0.5, 0)
	
	if vfx_cast_tex:
		# Use CombatVFX.spawn_effect for the cast visual at the caster's feet/chest
		CombatVFX.spawn_effect(get_tree(), pos, vfx_cast_tex)
	else:
		# Fallback to a cyan charging glow
		CombatSkillExecutor.spawn_hit_vfx(get_tree(), pos, null, Color.CYAN)

func _on_hurtbox_hit(damage_data: Dictionary) -> void:
	print("[VFXSandbox] Target dummy took hit! Damage: ", damage_data.get("damage", 0), " from ", damage_data.get("skill_name", "Unknown"))
	
	if anim_player:
		# Randomly play Hit_A or Hit_B
		var anim_name = "GeneralMage/Hit_A" if randf() > 0.5 else "GeneralMage/Hit_B"
		anim_player.stop() # Reset if already playing
		anim_player.play(anim_name)
		print("[VFXSandbox] Playing animation: ", anim_name)

func _on_caster_anim_finished(_anim_name: StringName) -> void:
	if caster_anim_player:
		caster_anim_player.play("GeneralMage/Idle_A")
