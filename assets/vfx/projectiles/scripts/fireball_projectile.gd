# fireball_projectile.gd
extends Projectile

func _on_area_entered(area: Area3D) -> void:
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		if hurtbox.get_parent().name == _caster_id:
			return

		var target := hurtbox.get_parent()
		var is_enemy := target is EnemyAIController or target.is_in_group("Enemies")
		
		var is_party := false
		var check_node: Node = target
		while check_node and check_node != get_tree().root:
			if check_node.is_in_group("PartyMembers"):
				is_party = true
				break
			check_node = check_node.get_parent()

		if (is_enemy and _hit_enemies) or (is_party and _hit_allies):
			var state_node: Node = hurtbox.parent_node if hurtbox.parent_node else target
			if state_node in _hit_targets: return

			if state_node.get("is_invincible") != true:
				hurtbox.take_hit({
					"damage": _damage, 
					"is_projectile": true,
					"caster_name": _caster_id,
					"skill_name": _skill_name
				})
				_apply_effects_on_hit(target)
				_hit_targets.append(state_node)
				hit.emit(state_node)
				_target = null

			# CUSTOM FIREBALL IMPACT
			if ImpactVFXManager:
				ImpactVFXManager.spawn_impact_preset(global_position, "fire")
			
			queue_free()

func _on_body_entered(body: Node) -> void:
	if _timer < 0.05: return
	if body.is_in_group("Environment") or body is StaticBody3D:
		if ImpactVFXManager:
			ImpactVFXManager.spawn_impact_preset(global_position, "fire")
		queue_free()
