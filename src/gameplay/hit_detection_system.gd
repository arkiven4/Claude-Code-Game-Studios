# hit_detection_system.gd
class_name HitDetectionSystem
extends Object

## Static utility for resolving combat targets.

static func find_hurtboxes_in_radius(origin: Vector3, radius: float, tree: SceneTree) -> Array[HurtboxComponent]:
	var results: Array[HurtboxComponent] = []
	# For simplicity in this migration, we use distance check on all hurtboxes.
	# For production, use PhysicsDirectSpaceState3D.intersect_shape().
	var all_hurtboxes = tree.get_nodes_in_group("Hurtboxes")
	for hb in all_hurtboxes:
		if hb is HurtboxComponent:
			if hb.global_position.distance_to(origin) <= radius and hb.is_alive():
				results.append(hb)
	return results

static func find_allies_for_skill(skill: SkillData, caster: PartyMemberState, party_members: Array[PartyMemberState]) -> Array[PartyMemberState]:
	var results: Array[PartyMemberState] = []
	var is_revive: bool = skill.skill_type == SkillData.SkillType.SUPPORT and skill.is_revive
	
	match skill.target_type:
		SkillData.TargetType.SELF:
			if caster and caster.is_alive:
				results.append(caster)
				
		SkillData.TargetType.SINGLE_ALLY:
			var best: PartyMemberState = null
			var best_score: float = INF
			
			for member in party_members:
				if not member: continue
				if is_revive:
					if not member.is_alive and member.call("can_revive") if member.has_method("can_revive") else false:
						best = member
						break
				else:
					if not member.is_alive: continue
					var hp_ratio := member.get_hp_ratio()
					if hp_ratio < best_score:
						best_score = hp_ratio
						best = member
			if best: results.append(best)
			
		SkillData.TargetType.ALL_ALLIES:
			for member in party_members:
				if not member: continue
				if is_revive:
					if not member.is_alive and member.call("can_revive") if member.has_method("can_revive") else false:
						results.append(member)
				else:
					if member.is_alive:
						results.append(member)
						
	return results
