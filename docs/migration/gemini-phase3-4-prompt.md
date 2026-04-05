# Gemini Prompt — Phase 3 & 4: Data Assets + Scenes

Copy everything below this line and paste it as your first message to Gemini CLI.

---

## Context

You are continuing the Godot 4.6 migration of **My Vampire**. All 43 GDScript source
files in `src/` are complete. Your job is to create the remaining data assets (`.tres`)
and scene files (`.tscn`).

---

## What Already Exists — Do NOT recreate

**Evelyn's 4 skills (already created):**
- `assets/data/skills/evelyn_dark_bolt.tres`
- `assets/data/skills/evelyn_shadow_veil.tres`
- `assets/data/skills/evelyn_abyssal_chain.tres`
- `assets/data/skills/evelyn_eclipse_burst.tres`

Read `assets/data/skills/evelyn_dark_bolt.tres` first to confirm the exact `.tres`
format you must follow for all remaining files.

---

## .tres Format Rules

Every `.tres` file follows this pattern:

```
[gd_resource type="Resource" script_class="ClassName" load_steps=N format=3]

[ext_resource type="Script" path="res://src/core/skill_data.gd" id="1_skill"]
[ext_resource type="Script" path="res://src/core/skill_tier_config.gd" id="2_tier"]

[sub_resource type="Resource" id="Tier1_SkillName"]
script = ExtResource("2_tier")
effect_value = 1.2
target_count = 1
area_radius = 0.0
duration = 0.0

[resource]
script = ExtResource("1_skill")
property = value
tiers = [SubResource("Tier1_SkillName"), SubResource("Tier2_SkillName"), SubResource("Tier3_SkillName")]
```

**Rules:**
- No UIDs required — Godot assigns them on first editor open
- Sub-resource `id` strings must be unique per file — use `"Tier1_DarkBolt"` style not just `"Tier1"`
- `load_steps` = count of ext_resources + count of sub_resources + 1
- Use `res://` paths for all resource references

**Enum integer values:**
- `CharacterData.CharacterClass`: SWORDMAN=0, MAGE=1, ASSASSIN=2, HEALER=3, TANKER=4, SUPPORT=5, ARCHER=6
- `SkillData.SkillType`: DAMAGE=0, STATUS=1, SUPPORT=2, UTILITY=3
- `SkillData.TargetType`: SINGLE_ENEMY=0, MULTI_ENEMY_LINE=1, MULTI_ENEMY_CONE=2, ALL_ENEMIES=3, SINGLE_ALLY=4, ALL_ALLIES=5, SELF=6
- `SkillData.DamageCategory`: PHYSICAL=0, MAGICAL=1, HOLY=2, DARK=3
- `EnemyData.EnemyClass`: GRUNT=0, ELITE=1, MINI_BOSS=2, BOSS=3
- `EnemyData.EnemyBehaviorProfile`: AGGRESSIVE=0, TACTICAL=1, DEFENSIVE=2, BOSS=3
- `ItemEquipment.EquipSlot`: WEAPON=0, ARMOR=1, HELMET=2, ACCESSORY=3, RELIC=4
- `ItemEquipment.ItemRarity`: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4

**Script paths for ext_resource:**
- `res://src/core/character_data.gd`
- `res://src/core/skill_data.gd`
- `res://src/core/skill_tier_config.gd`
- `res://src/core/item_equipment.gd`
- `res://src/core/enemy_data.gd`

---

## Phase 3A — Remaining Skill .tres Files (8 files)

Create in `assets/data/skills/`. Each skill embeds 3 `SkillTierConfig` sub-resources
(Tier1/Tier2/Tier3). Read `src/core/skill_data.gd` and `src/core/skill_tier_config.gd`
for all available fields before writing.

### Evan Skills (4 files)

**evan_crescent_slash.tres**
- `skill_type=0` (DAMAGE), `damage_category=0` (PHYSICAL)
- `target_type=0` (SINGLE_ENEMY), `mp_cost=10`, `base_cooldown=1.2`, `base_damage=30`
- Tier upgrade: Target Count — T1: effect=1.3, count=1 | T2: count=2 | T3: count=3

**evan_shield_bash.tres**
- `skill_type=0` (DAMAGE), `damage_category=0` (PHYSICAL)
- `target_type=0` (SINGLE_ENEMY), `mp_cost=20`, `base_cooldown=3.0`, `base_damage=20`
- Tier upgrade: Effect Intensity — T1: effect=1.0 | T2: effect=1.5 | T3: effect=2.0

**evan_hunters_mark.tres**
- `skill_type=1` (STATUS), `damage_category=0` (PHYSICAL)
- `target_type=0` (SINGLE_ENEMY), `mp_cost=15`, `base_cooldown=0.0`, `base_damage=0`
- Tier upgrade: Duration — T1: effect=1.0, dur=6.0 | T2: dur=10.0 | T3: dur=15.0

**evan_rending_storm.tres**
- `skill_type=0` (DAMAGE), `damage_category=0` (PHYSICAL)
- `target_type=2` (MULTI_ENEMY_CONE), `mp_cost=35`, `base_cooldown=6.0`, `base_damage=50`
- Tier upgrade: Area — T1: effect=1.8, radius=3.0 | T2: radius=5.0 | T3: radius=8.0

### Witch Skills (4 files)

**witch_hex_bolt.tres**
- `skill_type=0` (DAMAGE), `damage_category=1` (MAGICAL)
- `target_type=0` (SINGLE_ENEMY), `mp_cost=12`, `base_cooldown=0.8`, `base_damage=20`
- Tier upgrade: Target Count — T1: effect=1.1, count=1 | T2: count=2 | T3: count=3

**witch_spirit_ward.tres**
- `skill_type=2` (SUPPORT), `damage_category=1` (MAGICAL)
- `target_type=5` (ALL_ALLIES), `mp_cost=20`, `base_cooldown=0.0`, `base_damage=0`, `base_heal=0`
- Tier upgrade: Buff Power — T1: effect=0.10, dur=8.0 | T2: effect=0.18 | T3: effect=0.28
- Note: effect_value is the ATK buff percentage. Not a heal skill.

**witch_moonfire.tres**
- `skill_type=0` (DAMAGE), `damage_category=1` (MAGICAL)
- `target_type=2` (MULTI_ENEMY_CONE), `mp_cost=40`, `base_cooldown=5.0`, `base_damage=45`
- Tier upgrade: Area — T1: effect=1.6, radius=3.0 | T2: radius=5.0 | T3: radius=7.0

**witch_covens_wrath.tres**
- `skill_type=0` (DAMAGE), `damage_category=1` (MAGICAL)
- `target_type=3` (ALL_ENEMIES), `mp_cost=80`, `base_cooldown=15.0`, `base_damage=70`
- Tier upgrade: Effect Intensity — T1: effect=2.8, radius=8.0 | T2: effect=3.5, radius=8.0 | T3: effect=4.2, radius=10.0

---

## Phase 3B — Character .tres Files (3 files)

Create in `assets/data/characters/`. Read `src/core/character_data.gd` for all fields.

Each character .tres references its 4 skill .tres files as `ext_resource` entries,
then assigns them in `skill_slots`.

**evelyn.tres**
- `character_class=1` (MAGE), `display_name="Evelyn"`, `is_main_character=true`
- `role_description="The vampire girl. Glass cannon dark mage."`
- Base stats L1: `base_max_hp=220, base_atk=65, base_def=18, base_spd=1.2, base_max_mp=120, base_crit=0.06`
- Growth (Mage): `hp_per_level=12, atk_per_level=5, def_per_level=1, mp_per_level=5`
- Main char bonuses: `main_char_hp_bonus=3, main_char_atk_bonus=1, main_char_def_bonus=0, main_char_mp_bonus=2`
- `skill_slots` = [dark_bolt, shadow_veil, abyssal_chain, eclipse_burst]

**evan.tres**
- `character_class=0` (SWORDMAN), `display_name="Evan"`, `is_main_character=true`
- `role_description="The hunter. Precise, counter-oriented swordsman."`
- Base stats L1: `base_max_hp=320, base_atk=45, base_def=35, base_spd=1.1, base_max_mp=80, base_crit=0.08`
- Growth (Swordman): `hp_per_level=18, atk_per_level=3, def_per_level=2, mp_per_level=3`
- Main char bonuses: `main_char_hp_bonus=4, main_char_atk_bonus=1, main_char_def_bonus=1, main_char_mp_bonus=1`
- `skill_slots` = [crescent_slash, shield_bash, hunters_mark, rending_storm]

**witch.tres**
- `character_class=1` (MAGE — the Witch's CharacterClass is Mage per the GDD)
- `display_name="The Witch"`, `is_main_character=false`
- `role_description="Prologue-only ally. High ATK, fragile glass cannon."`
- Base stats L1: `base_max_hp=200, base_atk=70, base_def=15, base_spd=1.2, base_max_mp=130, base_crit=0.06`
- Growth (Mage): `hp_per_level=12, atk_per_level=5, def_per_level=1, mp_per_level=5`
- No main char bonuses (all 0)
- `skill_slots` = [hex_bolt, spirit_ward, moonfire, covens_wrath]

---

## Phase 3C — Item .tres Files (5 files)

Create in `assets/data/items/`. Read `src/core/item_equipment.gd` for all fields.

| File | display_name | slot | rarity | allowed_classes | base stats | sell_price |
|------|-------------|------|--------|-----------------|------------|------------|
| `evelyn_starter_staff.tres` | Evelyn's Starter Staff | WEAPON(0) | UNCOMMON(1) | [1] (Mage) | base_atk=15.0 | 80 |
| `evan_starter_sword.tres` | Evan's Starter Sword | WEAPON(0) | UNCOMMON(1) | [0] (Swordman) | base_atk=12.0, base_def=5.0 | 70 |
| `mage_apprentice_robe.tres` | Mage Apprentice Robe | ARMOR(1) | COMMON(0) | [1] (Mage) | base_def=10.0, base_max_mp=20.0 | 40 |
| `swordman_chain_mail.tres` | Swordman Chain Mail | ARMOR(1) | COMMON(0) | [0] (Swordman) | base_def=20.0, base_max_hp=30.0 | 40 |
| `generic_copper_ring.tres` | Copper Ring | ACCESSORY(3) | COMMON(0) | [] (any class) | base_crit=0.02 | 30 |

Each item also needs:
- `item_id` = filename without .tres extension (e.g., `"evelyn_starter_staff"`)
- `description` = short one-liner
- `level_requirement = 1`

For `allowed_classes` typed array in .tres format, use: `Array[int]([1])` for single
class, `Array[int]([0, 1])` for multiple, `Array[int]([])` for any class.

---

## Phase 3D — Enemy .tres Files (2 files)

Create in `assets/data/enemies/`. Read `src/core/enemy_data.gd` for all fields.

**grunt_melee.tres**
- `enemy_id="grunt_melee"`, `display_name="Grunt"`
- `enemy_class=0` (GRUNT), `behavior_profile=0` (AGGRESSIVE)
- `base_max_hp=150, base_atk=25, base_def=15, base_spd=1.0`
- All resistances = 1.0 (neutral)
- `skill_list=[]`, `death_threshold=0.0`

**archer_ranged.tres**
- `enemy_id="archer_ranged"`, `display_name="Archer"`
- `enemy_class=1` (ELITE), `behavior_profile=1` (TACTICAL)
- `base_max_hp=120, base_atk=35, base_def=10, base_spd=1.3`
- `physical_resistance=1.0, magical_resistance=0.8, holy_resistance=1.0, dark_resistance=1.2`
- `skill_list=[]`, `death_threshold=0.0`

---

## Phase 4A — Camera Controller Script

Create `src/gameplay/camera_controller.gd`:

```gdscript
# camera_controller.gd
class_name CameraController
extends Node3D

## Third-person camera with Exploration, Combat, and Cinematic modes.
## Uses SpringArm3D + Camera3D — no external addons required.
## Reference: design/gdd/camera-system.md

enum CameraMode { EXPLORATION, COMBAT, CINEMATIC }

@export var spring_arm: SpringArm3D
@export var camera: Camera3D
@export var encounter_manager: CombatEncounterManager
@export var follow_target: Node3D  # Set to active character at runtime

@export var exploration_length: float = 8.0
@export var exploration_height: float = 4.0
@export var combat_length_small: float = 6.0   # 1-2 enemies
@export var combat_length_medium: float = 8.0  # 3-4 enemies
@export var combat_length_large: float = 10.0  # 5+ enemies
@export var transition_duration: float = 0.5

var _mode: CameraMode = CameraMode.EXPLORATION

func _ready() -> void:
    if encounter_manager:
        encounter_manager.combat_started.connect(_on_combat_started)
        encounter_manager.combat_ended.connect(_on_combat_ended)
    set_mode(CameraMode.EXPLORATION)

func _physics_process(delta: float) -> void:
    if follow_target:
        global_position = global_position.lerp(follow_target.global_position, 10.0 * delta)

func set_mode(mode: CameraMode) -> void:
    _mode = mode
    match mode:
        CameraMode.EXPLORATION:
            _tween_spring_arm(exploration_length)
        CameraMode.CINEMATIC:
            pass  # handled externally via animation

func set_combat_length(enemy_count: int) -> void:
    var length: float
    if enemy_count <= 2:
        length = combat_length_small
    elif enemy_count <= 4:
        length = combat_length_medium
    else:
        length = combat_length_large
    _tween_spring_arm(length)

func _tween_spring_arm(target_length: float) -> void:
    if not spring_arm: return
    var tween := create_tween()
    tween.tween_property(spring_arm, "spring_length", target_length, transition_duration)

func _on_combat_started() -> void:
    set_mode(CameraMode.COMBAT)
    if encounter_manager:
        set_combat_length(encounter_manager.enemies_remaining)

func _on_combat_ended() -> void:
    set_mode(CameraMode.EXPLORATION)
```

Write this file exactly as shown.

---

## Phase 4B — .tscn Scene Files

**Before creating any scene**, read the script that will be attached to the root node
to confirm what `@export` NodePath fields exist — then wire them correctly.

Create in `assets/scenes/`:

### `characters/Evelyn.tscn`

Root: `CharacterBody3D` (no script on root — it's a plain CharacterBody3D)

```
[CharacterBody3D]  name="Evelyn"
  [MeshInstance3D]  name="Mesh"
    mesh = CapsuleMesh (radius=0.4, height=1.8)
    surface_material_override/0 = StandardMaterial3D (albedo_color=#6B2D8B)
  [CollisionShape3D]  name="Collision"
    shape = CapsuleShape3D (radius=0.4, height=1.8)
  [Node]  name="PartyMemberState"  script=res://src/gameplay/party_member_state.gd
    character_data = res://assets/data/characters/evelyn.tres
  [Node]  name="StatusEffectsSystem"  script=res://src/gameplay/status_effects_system.gd
  [Node]  name="SkillExecutionSystem"  script=res://src/gameplay/skill_execution_system.gd
    state = NodePath("../PartyMemberState")
    status_effects = NodePath("../StatusEffectsSystem")
  [Node]  name="CharacterStateManager"  script=res://src/gameplay/character_state_manager.gd
  [Node]  name="EquipmentManager"  script=res://src/gameplay/equipment_manager.gd
    state = NodePath("../PartyMemberState")
  [Area3D]  name="HitboxComponent"  script=res://src/gameplay/hitbox_component.gd
    collision_layer = 4
    collision_mask = 8
    [CollisionShape3D]  shape=SphereShape3D(radius=0.6)
  [Area3D]  name="HurtboxComponent"  script=res://src/gameplay/hurtbox_component.gd
    collision_layer = 8
    collision_mask = 4
    [CollisionShape3D]  shape=CapsuleShape3D(radius=0.5, height=1.8)
```

### `characters/Evan.tscn`

Same structure as Evelyn.tscn with:
- `Mesh` albedo_color = `#2E5D8E` (steel blue)
- `PartyMemberState.character_data` = `res://assets/data/characters/evan.tres`

### `characters/Witch.tscn`

Same structure with:
- `Mesh` albedo_color = `#2D6B3A` (forest green)
- `PartyMemberState.character_data` = `res://assets/data/characters/witch.tres`

### `enemies/GruntMelee.tscn`

Root: `CharacterBody3D` script=`res://src/gameplay/enemy_ai_controller.gd`

```
[CharacterBody3D]  name="GruntMelee"  script=res://src/gameplay/enemy_ai_controller.gd
  enemy_data = res://assets/data/enemies/grunt_melee.tres
  [MeshInstance3D]  name="Mesh"
    mesh = CapsuleMesh (radius=0.4, height=1.8)
    surface_material_override/0 = StandardMaterial3D (albedo_color=#CC2222)
  [CollisionShape3D]  name="Collision"
    shape = CapsuleShape3D (radius=0.4, height=1.8)
  [Area3D]  name="HitboxComponent"  script=res://src/gameplay/hitbox_component.gd
    collision_layer = 4
    collision_mask = 8
    [CollisionShape3D]  shape=SphereShape3D(radius=0.7)
  [Area3D]  name="HurtboxComponent"  script=res://src/gameplay/hurtbox_component.gd
    collision_layer = 8
    collision_mask = 4
    [CollisionShape3D]  shape=CapsuleShape3D(radius=0.5, height=1.8)
  [Node]  name="LootDropper"  script=res://src/gameplay/loot/loot_dropper.gd
  [Node3D]  name="WorldHPBar"  script=res://src/ui/world_hp_bar.gd
    position = Vector3(0, 2.2, 0)
```

### `enemies/ArcherRanged.tscn`

Same as GruntMelee with:
- `enemy_data` = `res://assets/data/enemies/archer_ranged.tres`
- `Mesh` albedo_color = `#CC5522` (orange-red)

### `TestArena.tscn`

Root: `Node3D` (no script)

```
[Node3D]  name="TestArena"
  [WorldEnvironment]  name="WorldEnvironment"
    environment = new Environment (ambient_light_color=#334455, sky enabled)
  [DirectionalLight3D]  name="Sun"
    rotation_degrees = Vector3(-45, -30, 0)
    light_energy = 1.0
    shadow_enabled = true
  [MeshInstance3D]  name="Ground"
    mesh = PlaneMesh (size=Vector2(20,20))
    surface_material_override/0 = StandardMaterial3D (albedo_color=#555555)
  [Node]  name="CombatEncounterManager"  script=res://src/gameplay/combat_encounter_manager.gd
  [Node]  name="CharacterSwitchController"  script=res://src/gameplay/character_switch_controller.gd
  [Node]  name="PlayerMovementController"  script=res://src/gameplay/player_movement_controller.gd
    input_manager = NodePath("../InputManager")
    switch_controller = NodePath("../CharacterSwitchController")
  [Node]  name="InputManager"  script=res://src/core/input_manager.gd
  [Node]  name="SaveManager"  script=res://src/core/save_manager.gd
  [Node]  name="AudioManager"  script=res://src/core/audio/audio_manager.gd
    [AudioStreamPlayer]  name="MusicPlayer"
    [Node]  name="SFXPlayer"  script=res://src/core/audio/sfx_player.gd
  [Node3D]  name="CameraController"  script=res://src/gameplay/camera_controller.gd
    encounter_manager = NodePath("../CombatEncounterManager")
    [SpringArm3D]  name="SpringArm"
      spring_length = 8.0
      rotation_degrees = Vector3(-20, 0, 0)
      [Camera3D]  name="Camera"
  [Node3D]  name="Party"
    [— instance Evelyn.tscn —]  name="Evelyn"  position=Vector3(-1, 0, 0)
    [— instance Evan.tscn —]    name="Evan"    position=Vector3( 1, 0, 0)
  [Node3D]  name="Enemies"
    [— instance GruntMelee.tscn —]    name="GruntMelee_1"    position=Vector3(-3, 0, 8)
    [— instance GruntMelee.tscn —]    name="GruntMelee_2"    position=Vector3( 3, 0, 8)
    [— instance ArcherRanged.tscn —]  name="ArcherRanged_1"  position=Vector3( 0, 0, 12)
  [CanvasLayer]  name="CombatHUD"  script=res://src/ui/combat_hud.gd
```

**Wire these NodePaths in TestArena.tscn:**
- `CharacterSwitchController.party_members` = [NodePath("Party/Evelyn/PartyMemberState"), NodePath("Party/Evan/PartyMemberState")]
- `CombatEncounterManager.party_members` = same as above
- `CombatEncounterManager.enemies` = [NodePath("Enemies/GruntMelee_1"), NodePath("Enemies/GruntMelee_2"), NodePath("Enemies/ArcherRanged_1")]
- `CameraController.follow_target` = NodePath("Party/Evelyn")

---

## Completion Checklist

When done, confirm:
- [ ] 8 skill .tres files created (evan ×4, witch ×4)
- [ ] 3 character .tres files created (evelyn, evan, witch)
- [ ] 5 item .tres files created
- [ ] 2 enemy .tres files created
- [ ] `src/gameplay/camera_controller.gd` created
- [ ] `assets/scenes/characters/Evelyn.tscn` created
- [ ] `assets/scenes/characters/Evan.tscn` created
- [ ] `assets/scenes/characters/Witch.tscn` created
- [ ] `assets/scenes/enemies/GruntMelee.tscn` created
- [ ] `assets/scenes/enemies/ArcherRanged.tscn` created
- [ ] `assets/scenes/TestArena.tscn` created

---

## Start Here

1. Read `assets/data/skills/evelyn_dark_bolt.tres` — confirm format
2. Read `src/core/skill_data.gd` and `src/core/skill_tier_config.gd` — confirm field names
3. Create the 8 remaining skill .tres files
4. Read `src/core/character_data.gd` — confirm field names
5. Create the 3 character .tres files
6. Create the 5 item .tres files and 2 enemy .tres files
7. Create `camera_controller.gd`
8. Read each scene's root script before creating its .tscn
9. Create all 6 .tscn files
