# Task for Gemini — Enemy Implementation

Qwen is creating the skill .tres files. Your job is everything else:
fix the Archer AI behavior, extend the enemy skill executor to handle new skill types,
create the Mage enemy, and wire everything into TestArena.tscn.

---

## Context

**Engine**: Godot 4.6 GDScript (statically typed)
**Do NOT modify**: `src/core/skill_data.gd`, `src/core/enemy_data.gd`, `src/core/enemy_skill_entry.gd`
**Qwen's output** (assume ready): `assets/data/skills/enemies/*.tres` (9 files)

---

## Existing File Reference

| File | Key details |
|------|-------------|
| `src/gameplay/enemy_ai_controller.gd` | Controls all enemies. Has `stop_distance`, `aggro_range`, `_execute_skill()` |
| `assets/data/enemies/grunt_melee.tres` | Grunt stats: HP=150, ATK=25, DEF=15 |
| `assets/data/enemies/archer_ranged.tres` | Archer stats: HP=120, ATK=35, DEF=10, `skill_list=[]` (currently empty) |
| `assets/scenes/enemies/GruntMelee.tscn` | Red capsule, uses `enemy_ai_controller.gd` + `grunt_melee.tres` |
| `assets/scenes/enemies/ArcherRanged.tscn` | Orange capsule, same structure |
| `assets/scenes/TestArena.tscn` | Has GruntMelee_1, GruntMelee_2, ArcherRanged_1 at preset positions |

**EnemySkillEntry fields** (`src/core/enemy_skill_entry.gd`):
```
skill_ref: SkillData
cooldown: float       ## seconds between uses
weight: float         ## selection probability weight
min_range: float
max_range: float
condition: int        ## 0=ALWAYS, 3=ENEMY_BELOW_HP_50, 4=ENEMY_BELOW_HP_25, 7=PHASE_2_ONLY
```

**SkillData relevant fields for enemies**:
```
skill_type: int       ## 0=DAMAGE, 1=STATUS, 2=SUPPORT, 3=UTILITY
target_type: int      ## 0=SINGLE_ENEMY, 2=CONE, 3=ALL_ENEMIES, 6=SELF
max_cast_range: float
area_radius: float
base_damage: int
effect_value: float   ## tier[0].effect_value — damage multiplier
damage_category: int  ## 0=PHYSICAL, 1=MAGICAL
shield_value: int     ## for shield block skills
grants_invincibility: bool
invincibility_duration: float
```

---

## Task 1 — Fix Archer Aggro/Attack Range Logic

**File**: `src/gameplay/enemy_ai_controller.gd`

**Problem**: Archer currently uses `stop_distance = 1.5` (melee range). It should stop
at its attack range and its aggro range should be 1.5× its attack range.

**Add a new export** to `EnemyAIController`:
```gdscript
@export var attack_range: float = 1.5       ## distance to stop moving and attack
@export var use_attack_range_for_aggro: bool = false  ## if true, aggro = attack_range * 1.5
```

**Update `_ready()`** — compute aggro from attack range when flag is set:
```gdscript
func _ready() -> void:
    ...existing code...
    if use_attack_range_for_aggro:
        aggro_range = attack_range * 1.5
    stop_distance = attack_range
```

**Update `ArcherRanged.tscn`** — set these on the root node Inspector:
- `attack_range = 8.0`
- `use_attack_range_for_aggro = true`
- Result: `stop_distance = 8.0`, `aggro_range = 12.0`

---

## Task 2 — Extend `_execute_skill()` to Handle All Skill Types

**File**: `src/gameplay/enemy_ai_controller.gd`

Currently `_execute_skill()` only handles `SkillType.DAMAGE`. Extend it to handle
STATUS, UTILITY (shield block, invincibility), and the basic attack fallback.

Replace the `_execute_skill()` method with:

```gdscript
func _execute_skill(index: int, target: PartyMemberState) -> void:
	var entry: EnemySkillEntry = enemy_data.skill_list[index]
	var skill: SkillData = entry.skill_ref

	var cooldown: float = entry.cooldown * 0.5 if is_enraged else entry.cooldown
	_skill_cooldowns[index] = cooldown

	match skill.skill_type:
		SkillData.SkillType.DAMAGE:
			_apply_damage_skill(skill, target)
		SkillData.SkillType.STATUS:
			_apply_status_skill(skill, target)
		SkillData.SkillType.UTILITY:
			_apply_utility_skill(skill)
		_:
			pass

func _apply_damage_skill(skill: SkillData, target: PartyMemberState) -> void:
	var tier: SkillTierConfig = skill.tiers[0] if not skill.tiers.is_empty() else null
	var effect_value: float = tier.effect_value if tier else 1.0
	var atk: int = int(enemy_data.base_atk * 1.5) if is_enraged else enemy_data.base_atk
	var target_def: int = target.get_effective_def()
	var res: float = float(target.call("get_resistance", skill.damage_category)) if target.has_method("get_resistance") else 1.0

	if skill.target_type == SkillData.TargetType.MULTI_ENEMY_CONE or skill.area_radius > 0.0:
		## Hit all party members in range/cone
		var party := get_tree().get_nodes_in_group("PartyMembers")
		for member in party:
			var state: PartyMemberState = member.get_node_or_null("PartyMemberState")
			if not state or not state.is_alive: continue
			if skill.area_radius > 0.0:
				var dist: float = global_position.distance_to(member.global_position)
				if dist > skill.area_radius: continue
			var result: Dictionary = HealthDamageSystem.calculate_damage(atk, skill.base_damage, effect_value, state.get_effective_def(), res, 0.0)
			state.take_damage(result)
			damage_dealt.emit(result.get("damage", 0), state)
	else:
		## Single target
		var result: Dictionary = HealthDamageSystem.calculate_damage(atk, skill.base_damage, effect_value, target_def, res, 0.0)
		target.take_damage(result)
		damage_dealt.emit(result.get("damage", 0), target)

	## Apply on-hit status effects (e.g. archer_super_shot stun) after damage
	_apply_on_hit_effects(skill, target)

func _apply_on_hit_effects(skill: SkillData, target: PartyMemberState) -> void:
	if skill.effects_to_apply.is_empty(): return
	var sfx_node: Node = target.get_parent().get_node_or_null("StatusEffectsSystem")
	if not sfx_node: return
	for effect_def in skill.effects_to_apply:
		if effect_def:
			sfx_node.apply_effect(effect_def, name, 1)

func _apply_status_skill(skill: SkillData, target: PartyMemberState) -> void:
	## Apply all status effects listed in skill.effects_to_apply via StatusEffectsSystem.
	## target is a PartyMemberState — its StatusEffectsSystem is a sibling node on the parent.
	var sfx_node: Node = target.get_parent().get_node_or_null("StatusEffectsSystem")
	if not sfx_node: return
	for effect_def in skill.effects_to_apply:
		if effect_def:
			sfx_node.apply_effect(effect_def, name, 1)

func _apply_utility_skill(skill: SkillData) -> void:
	## Self-targeted utility: shield block, invincibility (dash)
	if skill.shield_value > 0:
		_active_shield = skill.shield_value
	if skill.grants_invincibility:
		_is_invincible = true
		await get_tree().create_timer(skill.invincibility_duration).timeout
		_is_invincible = false
```

Also **add these variables** to the class:
```gdscript
var _active_shield: int = 0
var _is_invincible: bool = false
```

**Add a helper** to check status effects on self:
```gdscript
func _has_effect_category(category: StatusEffect.EffectCategory) -> bool:
	var sfx: Node = get_node_or_null("StatusEffectsSystem")
	if not sfx: return false
	for active in sfx.active_effects:
		if active.definition and active.definition.effect_category == category:
			return true
	return false

func _get_movement_multiplier() -> float:
	var sfx: Node = get_node_or_null("StatusEffectsSystem")
	if not sfx: return 1.0
	var multiplier: float = 1.0
	for active in sfx.active_effects:
		if active.definition and active.definition.effect_category == StatusEffect.EffectCategory.MOVEMENT_IMPAIR:
			multiplier *= active.definition.effect_value
	return multiplier
```

**Update `_physics_process`** — apply slow to movement velocity. Find the movement block:
```gdscript
	if dist > stop_distance:
		var dir: Vector3 = (_current_target.global_position - global_position).normalized()
		var target_vel := dir * move_speed
```

Replace with:
```gdscript
	if dist > stop_distance:
		var dir: Vector3 = (_current_target.global_position - global_position).normalized()
		var effective_speed: float = move_speed * _get_movement_multiplier()
		var target_vel := dir * effective_speed
```

**Update `_make_decision`** — skip skill execution when stunned. Add at the top of `_make_decision()`:
```gdscript
	## Do nothing if action-denied (stunned)
	if _has_effect_category(StatusEffect.EffectCategory.ACTION_DENIAL):
		_decision_timer = _get_decision_interval()
		return
```

And **update `take_damage()`** to respect shield and invincibility:
```gdscript
func take_damage(data) -> void:
	if not is_alive: return
	if _is_invincible: return   ## add this line
	
	var amount: int = int(data.get("damage", 0)) if data is Dictionary else int(data)
	var final_amount: int = int(max(HealthDamageSystem.MINIMUM_DAMAGE, amount))
	
	## Shield absorbs damage first
	if _active_shield > 0:            ## add this block
		var absorbed: int = min(_active_shield, final_amount)
		_active_shield -= absorbed
		final_amount -= absorbed
		if final_amount <= 0:
			return
	
	...rest of existing take_damage code unchanged...
```

---

## Task 3 — Add `StatusEffectsSystem` Node to All Enemy Scenes

Status effects (stun, slow, debuffs) must work symmetrically — both party members
and enemies can receive them. Add a `StatusEffectsSystem` child node to all 3 scenes.

**File**: `assets/scenes/enemies/GruntMelee.tscn`

In the `[ext_resource]` section, add (use next available id number):
```
[ext_resource type="Script" path="res://src/gameplay/status_effects_system.gd" id="10_sfx"]
```

After the `LootDropper` node block, append:
```
[node name="StatusEffectsSystem" type="Node" parent="."]
script = ExtResource("10_sfx")
```

Update the header: `load_steps=14` → `load_steps=15`

**File**: `assets/scenes/enemies/ArcherRanged.tscn`

Same change — add `id="10_sfx"` ext_resource and `StatusEffectsSystem` node after `LootDropper`.
Update `load_steps=14` → `load_steps=15`.

**File**: `assets/scenes/enemies/MageEnemy.tscn` (Task 7)

Add the same ext_resource and node to the MageEnemy scene content in Task 7.
Update its `load_steps` header accordingly.

---

## Task 4 — Update `grunt_melee.tres` with Skill List

**File**: `assets/data/enemies/grunt_melee.tres`

Replace entire file with (Qwen's skill files referenced inline):

```
[gd_resource type="Resource" script_class="EnemyData" format=3 uid="uid://ckhsrldb8uyei"]

[ext_resource type="Script" uid="uid://pjoxxkra8hlc" path="res://src/core/enemy_data.gd" id="1_enemy"]
[ext_resource type="Script" uid="uid://cebmr5g6qwykx" path="res://src/core/enemy_skill_entry.gd" id="2_entry"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/grunt_basic_slash.tres" id="3_basic"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/grunt_super_slash.tres" id="4_super"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/grunt_shield_block.tres" id="5_shield"]

[sub_resource type="Resource" id="Entry_Basic"]
script = ExtResource("2_entry")
skill_ref = ExtResource("3_basic")
cooldown = 0.8
weight = 3.0
min_range = 0.0
max_range = 3.0
condition = 0

[sub_resource type="Resource" id="Entry_Super"]
script = ExtResource("2_entry")
skill_ref = ExtResource("4_super")
cooldown = 8.0
weight = 2.0
min_range = 0.0
max_range = 3.5
condition = 0

[sub_resource type="Resource" id="Entry_Shield"]
script = ExtResource("2_entry")
skill_ref = ExtResource("5_shield")
cooldown = 12.0
weight = 1.0
min_range = 0.0
max_range = 999.0
condition = 3

[resource]
script = ExtResource("1_enemy")
enemy_id = "grunt_melee"
display_name = "Grunt"
enemy_class = 0
behavior_profile = 0
base_max_hp = 150
base_atk = 25
base_def = 15
base_spd = 1.0
physical_resistance = 1.0
magical_resistance = 1.2
holy_resistance = 1.0
dark_resistance = 1.0
skill_list = Array[Resource]([SubResource("Entry_Basic"), SubResource("Entry_Super"), SubResource("Entry_Shield")])
death_threshold = 0.0
```

---

## Task 5 — Update `archer_ranged.tres` with Skill List

**File**: `assets/data/enemies/archer_ranged.tres`

Replace entire file:

```
[gd_resource type="Resource" script_class="EnemyData" format=3]

[ext_resource type="Script" path="res://src/core/enemy_data.gd" id="1_enemy"]
[ext_resource type="Script" path="res://src/core/enemy_skill_entry.gd" id="2_entry"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/archer_basic_shot.tres" id="3_basic"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/archer_dash.tres" id="4_dash"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/archer_super_shot.tres" id="5_super"]

[sub_resource type="Resource" id="Entry_Basic"]
script = ExtResource("2_entry")
skill_ref = ExtResource("3_basic")
cooldown = 1.2
weight = 3.0
min_range = 3.0
max_range = 10.0
condition = 0

[sub_resource type="Resource" id="Entry_Dash"]
script = ExtResource("2_entry")
skill_ref = ExtResource("4_dash")
cooldown = 10.0
weight = 1.5
min_range = 0.0
max_range = 999.0
condition = 4

[sub_resource type="Resource" id="Entry_Super"]
script = ExtResource("2_entry")
skill_ref = ExtResource("5_super")
cooldown = 14.0
weight = 2.0
min_range = 4.0
max_range = 12.0
condition = 0

[resource]
script = ExtResource("1_enemy")
enemy_id = "archer_ranged"
display_name = "Archer"
enemy_class = 1
behavior_profile = 1
base_max_hp = 120
base_atk = 35
base_def = 10
base_spd = 1.3
physical_resistance = 1.0
magical_resistance = 0.8
holy_resistance = 1.0
dark_resistance = 1.2
skill_list = Array[Resource]([SubResource("Entry_Basic"), SubResource("Entry_Dash"), SubResource("Entry_Super")])
death_threshold = 0.0
```

---

## Task 6 — Create `assets/data/enemies/mage_enemy.tres`

**Create new file:**

```
[gd_resource type="Resource" script_class="EnemyData" format=3]

[ext_resource type="Script" path="res://src/core/enemy_data.gd" id="1_enemy"]
[ext_resource type="Script" path="res://src/core/enemy_skill_entry.gd" id="2_entry"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/mage_basic_bolt.tres" id="3_basic"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/mage_slow.tres" id="4_slow"]
[ext_resource type="Resource" path="res://assets/data/skills/enemies/mage_skillshot.tres" id="5_skillshot"]

[sub_resource type="Resource" id="Entry_Basic"]
script = ExtResource("2_entry")
skill_ref = ExtResource("3_basic")
cooldown = 1.5
weight = 3.0
min_range = 2.0
max_range = 9.0
condition = 0

[sub_resource type="Resource" id="Entry_Slow"]
script = ExtResource("2_entry")
skill_ref = ExtResource("4_slow")
cooldown = 9.0
weight = 2.0
min_range = 0.0
max_range = 9.0
condition = 0

[sub_resource type="Resource" id="Entry_Skillshot"]
script = ExtResource("2_entry")
skill_ref = ExtResource("5_skillshot")
cooldown = 11.0
weight = 2.5
min_range = 3.0
max_range = 11.0
condition = 0

[resource]
script = ExtResource("1_enemy")
enemy_id = "mage_enemy"
display_name = "Mage"
enemy_class = 1
behavior_profile = 1
base_max_hp = 100
base_atk = 28
base_def = 8
base_spd = 1.1
physical_resistance = 1.0
magical_resistance = 0.7
holy_resistance = 0.9
dark_resistance = 1.3
skill_list = Array[Resource]([SubResource("Entry_Basic"), SubResource("Entry_Slow"), SubResource("Entry_Skillshot")])
death_threshold = 0.0
```

---

## Task 7 — Create `assets/scenes/enemies/MageEnemy.tscn`

Copy the structure from `ArcherRanged.tscn` exactly, with these changes:

- Root node name: `MageEnemy`
- `enemy_data` → `res://assets/data/enemies/mage_enemy.tres`
- Mesh color: `Color(0.4, 0.1, 0.6, 1)` (purple)
- Inspector on root node:
  - `attack_range = 7.0`
  - `use_attack_range_for_aggro = true`
  - Result: `stop_distance = 7.0`, `aggro_range = 10.5`
- LootTable: reuse the same items as Archer (copper ring + mage_apprentice_robe)

Full scene content to create:

```
[gd_scene load_steps=14 format=3]

[ext_resource type="Script" path="res://src/gameplay/enemy_ai_controller.gd" id="1_ai"]
[ext_resource type="Resource" path="res://assets/data/enemies/mage_enemy.tres" id="2_data"]
[ext_resource type="Script" path="res://src/gameplay/hitbox_component.gd" id="3_hitbox"]
[ext_resource type="Script" path="res://src/gameplay/hurtbox_component.gd" id="4_hurtbox"]
[ext_resource type="Script" path="res://src/ui/world_hp_bar.gd" id="5_hp"]
[ext_resource type="Script" path="res://src/gameplay/loot/loot_dropper.gd" id="6_loot"]
[ext_resource type="Script" path="res://src/gameplay/loot/loot_table.gd" id="7_table"]
[ext_resource type="Resource" path="res://assets/data/items/generic_copper_ring.tres" id="8_ring"]
[ext_resource type="Resource" path="res://assets/data/items/mage_apprentice_robe.tres" id="9_robe"]

[sub_resource type="CapsuleMesh" id="CapsuleMesh_1"]
radius = 0.4
height = 1.8

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_1"]
albedo_color = Color(0.4, 0.1, 0.6, 1)

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_1"]
radius = 0.4
height = 1.8

[sub_resource type="SphereShape3D" id="SphereShape3D_1"]
radius = 0.7

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_2"]
radius = 0.5
height = 1.8

[sub_resource type="Resource" id="LootTable_Mage"]
script = ExtResource("7_table")
entries = [ExtResource("8_ring"), ExtResource("9_robe")]
entry_weights = [0.5, 0.5]

[node name="MageEnemy" type="CharacterBody3D" groups=["Enemies"]]
script = ExtResource("1_ai")
enemy_data = ExtResource("2_data")
attack_range = 7.0
use_attack_range_for_aggro = true

[node name="Mesh" type="MeshInstance3D" parent="."]
mesh = SubResource("CapsuleMesh_1")
surface_material_override/0 = SubResource("StandardMaterial3D_1")

[node name="Collision" type="CollisionShape3D" parent="."]
shape = SubResource("CapsuleShape3D_1")

[node name="HitboxComponent" type="Area3D" parent="."]
collision_layer = 4
collision_mask = 2
script = ExtResource("3_hitbox")

[node name="CollisionShape3D" type="CollisionShape3D" parent="HitboxComponent"]
shape = SubResource("SphereShape3D_1")

[node name="HurtboxComponent" type="Area3D" parent="." groups=["Hurtboxes"]]
collision_layer = 8
collision_mask = 1
script = ExtResource("4_hurtbox")

[node name="CollisionShape3D" type="CollisionShape3D" parent="HurtboxComponent"]
shape = SubResource("CapsuleShape3D_2")

[node name="WorldHPBar" type="Node3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.2, 0)
script = ExtResource("5_hp")

[node name="LootDropper" type="Node" parent="."]
script = ExtResource("6_loot")
enemy_data = ExtResource("2_data")
loot_table = SubResource("LootTable_Mage")
```

---

## Task 8 — Update `assets/scenes/TestArena.tscn`

Add MageEnemy_1 to the Enemies node and wire it into the CombatEncounterManager and ArenaWiring.

**In the `[ext_resource]` section**, add:
```
[ext_resource type="PackedScene" path="res://assets/scenes/enemies/MageEnemy.tscn" id="15_mage"]
```

**After `ArcherRanged_1` node**, add:
```
[node name="MageEnemy_1" parent="Enemies" instance=ExtResource("15_mage")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0.9, 23)
```

**Update `CombatEncounterManager` node** — add MageEnemy_1 to enemy_paths:
```
enemy_paths = Array[NodePath]([NodePath("../Enemies/GruntMelee_1"), NodePath("../Enemies/GruntMelee_2"), NodePath("../Enemies/ArcherRanged_1"), NodePath("../Enemies/MageEnemy_1")])
```

**Update `ArenaWiring` node** — add MageEnemy_1 to enemy_paths:
```
enemy_paths = Array[NodePath]([NodePath("../Enemies/GruntMelee_1"), NodePath("../Enemies/GruntMelee_2"), NodePath("../Enemies/ArcherRanged_1"), NodePath("../Enemies/MageEnemy_1")])
```

---

## Also Update `ArcherRanged.tscn` Root Node Inspector Values

In `assets/scenes/enemies/ArcherRanged.tscn`, add to the root `[node]`:
```
attack_range = 8.0
use_attack_range_for_aggro = true
```

---

## Acceptance Criteria

- [ ] `EnemyAIController` compiles without errors in Godot 4.6
- [ ] Archer stops at ~8 units from player and fires from there (not at melee range)
- [ ] Grunt executes shield block when HP drops below 50% (`condition = 3`)
- [ ] Mage stays at ~7 units and fires magic bolts + slow + skillshot
- [ ] `TestArena.tscn` has 4 enemies: 2 Grunts, 1 Archer, 1 Mage (purple capsule)
- [ ] All enemies use skills regulated by cooldown (no MP consumed)
- [ ] Player movement slows visibly when hit by `mage_slow` skill
- [ ] No null reference errors when scene runs

---

## Notes / Risks

- `apply_movement_slow()` on `PartyMemberState` needs to connect to `PlayerMovementController`.
  Check `src/gameplay/player_movement_controller.gd` for where velocity is computed and
  multiply by `active_state.movement_speed_multiplier`.

- The `_apply_utility_skill` uses `await` inside a non-async function. In GDScript 4,
  this requires the function to be callable as a coroutine OR use a Timer node instead
  of `await get_tree().create_timer()`. Use a Timer node for the invincibility duration
  to avoid coroutine issues in `_execute_skill`.

- `grunt_shield_block` has `condition = 3` (ENEMY_BELOW_HP_50) — Grunt shields itself
  when its own HP drops below 50%. This is the correct use of that condition.

- The `archer_dash` UTILITY skill has `invincibility_duration = 0.3` — brief iframe
  during dash. The actual movement of the dash can be simplified: when dash skill fires,
  apply an impulse velocity toward the target (e.g., `velocity = direction * 15.0`)
  for 1 physics frame. Add this to `_apply_utility_skill` by checking `"dash" in skill.skill_id`.
