# Gemini Phase 5+6 Prompt — Signal Wiring & GUT Tests

You are implementing Phase 5 (signal wiring) and Phase 6 (GUT tests) for a
Godot 4.6 / GDScript game project called **MyVampire**. Read this entire file
before writing anything.

---

## Context

Phase 3+4 are complete. The project now has:
- All `.tres` data assets (skills, characters, items, enemies)
- All `.tscn` scene files (Evelyn, Evan, Witch, GruntMelee, ArcherRanged, TestArena)
- All GDScript system files in `src/`

**Your role**: Write files exactly as specified. Do not invent new architecture.
Do not rename anything. Do not add extra features.

---

## Phase 5 — Signal Wiring

Phase 5 has four sub-tasks: 5A (CombatHUD UI nodes), 5B (LootDropper nodes),
5C (ArenaWiring script), 5D (update TestArena.tscn).

---

### Phase 5A — CombatHUD UI Nodes

`src/ui/combat_hud.gd` already exists. It references these unique-named nodes:
- `%ActivePortrait` (TextureRect)
- `%ActiveHPBar` (ProgressBar)
- `%ActiveMPBar` (ProgressBar)
- `%InactivePortrait` (TextureRect)
- `%InactiveHPBar` (ProgressBar)
- `%SwitchCooldownLabel` (Label)

Create the scene file **`assets/scenes/ui/CombatHUD.tscn`**:

```gdscript
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://src/ui/combat_hud.gd" id="1_hud"]

[node name="CombatHUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="MarginContainer" type="MarginContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 16
theme_override_constants/margin_top = 16
theme_override_constants/margin_right = 16
theme_override_constants/margin_bottom = 16

[node name="VBoxContainer" type="VBoxContainer" parent="MarginContainer"]
layout_mode = 2

[node name="ActiveSection" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="ActivePortrait" type="TextureRect" parent="MarginContainer/VBoxContainer/ActiveSection"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(64, 64)

[node name="ActiveStats" type="VBoxContainer" parent="MarginContainer/VBoxContainer/ActiveSection"]
layout_mode = 2

[node name="ActiveHPBar" type="ProgressBar" parent="MarginContainer/VBoxContainer/ActiveSection/ActiveStats"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(200, 20)
max_value = 100.0
value = 100.0

[node name="ActiveMPBar" type="ProgressBar" parent="MarginContainer/VBoxContainer/ActiveSection/ActiveStats"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(200, 20)
max_value = 100.0
value = 100.0

[node name="InactiveSection" type="HBoxContainer" parent="MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="InactivePortrait" type="TextureRect" parent="MarginContainer/VBoxContainer/InactiveSection"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(48, 48)

[node name="InactiveHPBar" type="ProgressBar" parent="MarginContainer/VBoxContainer/InactiveSection"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(160, 16)
max_value = 100.0
value = 100.0

[node name="SwitchCooldownLabel" type="Label" parent="MarginContainer/VBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
text = ""
```

---

### Phase 5B — LootDropper Nodes in Enemy Scenes

`LootDropper` (`src/gameplay/loot/loot_dropper.gd`) needs to be a child node
of each enemy. It calls `drop_loot(position)` when the enemy dies.

The `LootTable` resource (`src/gameplay/loot/loot_table.gd`) has exported fields:
- `entries: Array[Resource]` — array of `ItemEquipment` resources
- `entry_weights: Array[float]` — parallel array of weights

**Update `assets/scenes/enemies/GruntMelee.tscn`** — add after the WorldHPBar node:

```
[ext_resource type="Script" path="res://src/gameplay/loot/loot_dropper.gd" id="6_loot"]
[ext_resource type="Script" path="res://src/gameplay/loot/loot_table.gd" id="7_table"]
[ext_resource type="Resource" path="res://assets/data/items/generic_copper_ring.tres" id="8_ring"]
[ext_resource type="Resource" path="res://assets/data/items/swordman_chain_mail.tres" id="9_mail"]
```

And update `load_steps` from 10 to 14. Then add these nodes at the end of the scene:

```
[sub_resource type="Resource" id="LootTable_Grunt"]
script = ExtResource("7_table")
entries = [ExtResource("8_ring"), ExtResource("9_mail")]
entry_weights = [0.7, 0.3]

[node name="LootDropper" type="Node" parent="."]
script = ExtResource("6_loot")
enemy_data = ExtResource("2_data")
loot_table = SubResource("LootTable_Grunt")
```

**Update `assets/scenes/enemies/ArcherRanged.tscn`** — same pattern, add:

```
[ext_resource type="Script" path="res://src/gameplay/loot/loot_dropper.gd" id="6_loot"]
[ext_resource type="Script" path="res://src/gameplay/loot/loot_table.gd" id="7_table"]
[ext_resource type="Resource" path="res://assets/data/items/generic_copper_ring.tres" id="8_ring"]
[ext_resource type="Resource" path="res://assets/data/items/mage_apprentice_robe.tres" id="9_robe"]
```

Update `load_steps` appropriately. Then add:

```
[sub_resource type="Resource" id="LootTable_Archer"]
script = ExtResource("7_table")
entries = [ExtResource("8_ring"), ExtResource("9_robe")]
entry_weights = [0.6, 0.4]

[node name="LootDropper" type="Node" parent="."]
script = ExtResource("6_loot")
enemy_data = ExtResource("2_data")
loot_table = SubResource("LootTable_Archer")
```

**Note on `pickup_scene`**: Leave `pickup_scene` unset for now — `LootDropper.drop_loot`
already null-checks `pickup_scene` and returns early if missing. This is intentional
prototype behaviour.

---

### Phase 5C — ArenaWiring Script

Create **`src/gameplay/arena_wiring.gd`**. This node connects all runtime signals
between the systems in TestArena. It runs `_ready()` after all children are ready.

```gdscript
# arena_wiring.gd
class_name ArenaWiring
extends Node

## Wires runtime signals between arena systems.
## Runs after all sibling nodes are ready via call_deferred.

@export var encounter_manager: CombatEncounterManager
@export var switch_controller: CharacterSwitchController
@export var camera_controller: CameraController
@export var party_members: Array[PartyMemberState] = []
@export var enemies: Array[EnemyAIController] = []
@export var combat_hud: CombatHUD

func _ready() -> void:
	call_deferred("_wire_signals")

func _wire_signals() -> void:
	# --- CombatEncounterManager → CombatHUD ---
	if encounter_manager and combat_hud:
		encounter_manager.combat_started.connect(combat_hud.show_hud)
		encounter_manager.combat_ended.connect(combat_hud.hide_hud)
		encounter_manager.game_over.connect(combat_hud.hide_hud)

	# --- CharacterSwitchController → CombatHUD ---
	if switch_controller and combat_hud:
		switch_controller.character_switched.connect(_on_character_switched)

	# --- CharacterSwitchController → CameraController ---
	if switch_controller and camera_controller:
		switch_controller.character_switched.connect(_on_switch_update_camera)

	# --- PartyMemberState → CombatHUD (initial active = index 0) ---
	if not party_members.is_empty() and combat_hud:
		_connect_active_member(party_members[0])
		if party_members.size() > 1:
			_connect_inactive_member(party_members[1])

	# --- EnemyAIController.died → LootDropper ---
	for enemy in enemies:
		if enemy:
			var dropper: LootDropper = enemy.get_node_or_null("LootDropper")
			if dropper:
				enemy.died.connect(func(): dropper.drop_loot(enemy.global_position))

	# --- Start combat immediately (TestArena is a test scene) ---
	if encounter_manager:
		call_deferred("_start_combat_deferred")

func _start_combat_deferred() -> void:
	if encounter_manager:
		encounter_manager.start_combat()

func _on_character_switched(previous: PartyMemberState, current: PartyMemberState) -> void:
	# Disconnect previous character's signals from active HUD slots
	if previous and combat_hud:
		if previous.hp_changed.is_connected(combat_hud.update_active_health):
			previous.hp_changed.disconnect(combat_hud.update_active_health)

	# Connect new active character
	if current and combat_hud:
		_connect_active_member(current)

	# Show switch cooldown
	if combat_hud and switch_controller:
		combat_hud.show_switch_cooldown(switch_controller.switch_window_duration)

func _on_switch_update_camera(_previous: PartyMemberState, current: PartyMemberState) -> void:
	if camera_controller and current:
		var char_node := current.get_parent() as Node3D
		if char_node:
			camera_controller.follow_target = char_node

func _connect_active_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_active_health):
		member.hp_changed.connect(combat_hud.update_active_health)
	# Immediately refresh bars
	combat_hud.update_active_health(member.current_hp, member.max_hp)
	combat_hud.update_active_mp(member.current_mp, member.max_mp)

func _connect_inactive_member(member: PartyMemberState) -> void:
	if not member or not combat_hud: return
	if not member.hp_changed.is_connected(combat_hud.update_inactive_health):
		member.hp_changed.connect(combat_hud.update_inactive_health)
	combat_hud.update_inactive_health(member.current_hp, member.max_hp)
```

---

### Phase 5D — Update TestArena.tscn

The existing `assets/scenes/TestArena.tscn` needs these changes:

1. **Add CombatHUD as a PackedScene** (replace the inline script reference).
   Replace the `[ext_resource type="Script" ... id="13_hud"]` line with:
   ```
   [ext_resource type="PackedScene" path="res://assets/scenes/ui/CombatHUD.tscn" id="13_hud"]
   ```

2. **Add ArenaWiring script** as a new ext_resource:
   ```
   [ext_resource type="Script" path="res://src/gameplay/arena_wiring.gd" id="14_wiring"]
   ```

3. **Update `load_steps`** from 18 to 19.

4. **Replace the CombatHUD node** at the bottom of the scene:
   Change:
   ```
   [node name="CombatHUD" type="CanvasLayer" parent="."]
   script = ExtResource("13_hud")
   ```
   To:
   ```
   [node name="CombatHUD" parent="." instance=ExtResource("13_hud")]
   ```

5. **Add ArenaWiring node** at the very end of the scene (after CombatHUD):
   ```
   [node name="ArenaWiring" type="Node" parent="."]
   script = ExtResource("14_wiring")
   encounter_manager = NodePath("../CombatEncounterManager")
   switch_controller = NodePath("../CharacterSwitchController")
   camera_controller = NodePath("../CameraController")
   party_members = [NodePath("../Party/Evelyn/PartyMemberState"), NodePath("../Party/Evan/PartyMemberState")]
   enemies = [NodePath("../Enemies/GruntMelee_1"), NodePath("../Enemies/GruntMelee_2"), NodePath("../Enemies/ArcherRanged_1")]
   combat_hud = NodePath("../CombatHUD")
   ```

**Important**: Godot NodePaths in exported arrays use this syntax:
```
party_members = [NodePath("../Party/Evelyn/PartyMemberState"), NodePath("../Party/Evan/PartyMemberState")]
```

---

## Phase 6 — GUT Tests

GUT (Godot Unit Testing) is the test framework. Install it first, then write 5 test files.

### Phase 6A — GUT Addon Installation

Create the directory `addons/gut/` and the minimal GUT config file.

Create **`addons/gut/plugin.cfg`**:
```ini
[plugin]
name="Gut"
description="Godot Unit Testing"
author="bitwes"
version="9.3.0"
script="gut_plugin.gd"
```

**Important**: GUT must be downloaded from the Asset Library or GitHub
(https://github.com/bitwes/Gut). The `plugin.cfg` alone is not sufficient —
the user must install GUT manually via the Godot Editor's AssetLib tab
(search "GUT") or by copying the full addon folder.

For now, create the test files using GUT's API. The test runner will work
once the addon is installed.

Create **`.gutconfig`** in the project root:
```json
{
  "dirs": ["res://tests/"],
  "double_strategy": "include_native",
  "ignore_pause": false,
  "include_subdirs": true,
  "log_level": 1,
  "prefix": "test_",
  "selected": "",
  "should_exit": false,
  "should_exit_on_success": false,
  "suffix": ".gd",
  "treat_error_as_failure": true
}
```

---

### Phase 6B — Test Files

Create these 5 files in `tests/unit/`.

---

#### File 1: `tests/unit/test_health_damage.gd`

```gdscript
# test_health_damage.gd
# Tests: HealthDamageSystem formulas
# Covers sprint tasks S1-10, S1-11

extends GutTest

func test_calculate_damage_no_crit() -> void:
	# Formula: raw = (atk * 0.5 + base_dmg) * effect * crit_mult
	# raw = (100 * 0.5 + 50) * 1.0 * 1.0 = 100
	# after_def = 100 - 20 = 80
	# final = floor(80 * 1.0) = 80
	var result := HealthDamageSystem.calculate_damage(100, 50, 1.0, 20, 1.0, 0.0)
	assert_eq(result["damage"], 80, "Basic damage formula")
	assert_false(result["was_crit"], "No crit at 0.0 chance")

func test_calculate_damage_effect_value_multiplier() -> void:
	# raw = (60 * 0.5 + 40) * 2.5 = (30 + 40) * 2.5 = 175
	# after_def = 175 - 10 = 165, final = 165
	var result := HealthDamageSystem.calculate_damage(60, 40, 2.5, 10, 1.0, 0.0)
	assert_eq(result["damage"], 165, "Effect value multiplier (eclipse burst tier 1)")

func test_calculate_damage_category_resistance() -> void:
	# raw = (50 * 0.5 + 25) = 50, after_def = 50 - 0 = 50
	# after_category = floor(50 * 0.5) = 25
	var result := HealthDamageSystem.calculate_damage(50, 25, 1.0, 0, 0.5, 0.0)
	assert_eq(result["damage"], 25, "Category resistance halves damage")

func test_calculate_damage_minimum_one() -> void:
	# High DEF should still produce at least 1 damage
	var result := HealthDamageSystem.calculate_damage(1, 1, 1.0, 9999, 1.0, 0.0)
	assert_eq(result["damage"], HealthDamageSystem.MINIMUM_DAMAGE, "Always at least 1 damage")

func test_crit_multiplier() -> void:
	# Crit = 1.5x. With 100% crit chance, result must be > non-crit result.
	var no_crit := HealthDamageSystem.calculate_damage(100, 50, 1.0, 0, 1.0, 0.0)
	var crit := HealthDamageSystem.calculate_damage(100, 50, 1.0, 0, 1.0, 1.0)
	assert_true(crit["was_crit"], "100% crit chance always crits")
	assert_true(crit["damage"] > no_crit["damage"], "Crit deals more damage")
	assert_almost_eq(float(crit["damage"]), float(no_crit["damage"]) * 1.5, 1.0, "Crit is 1.5x")

func test_calculate_heal_basic() -> void:
	# heal = (max_mp * 0.1 + base_heal) * effect_val + (max_hp * bonus_pct)
	# = (100 * 0.1 + 30) * 1.0 + (200 * 0.0) = 40
	var heal := HealthDamageSystem.calculate_heal(100, 30, 1.0, 200, 0.0, 100)
	assert_eq(heal, 40, "Basic heal formula")

func test_calculate_heal_capped_by_missing_hp() -> void:
	# Only 10 HP missing — can't heal more than that
	var heal := HealthDamageSystem.calculate_heal(100, 30, 1.0, 200, 0.0, 190)
	assert_eq(heal, 10, "Heal capped at missing HP")
```

---

#### File 2: `tests/unit/test_status_effects.gd`

```gdscript
# test_status_effects.gd
# Tests: StatusEffectsSystem apply/tick/expire
# Covers sprint tasks S1-12, S2-11

extends GutTest

var _system: StatusEffectsSystem
var _mock_state: Node

func before_each() -> void:
	_system = StatusEffectsSystem.new()
	add_child(_system)

	# Minimal mock state (PartyMemberState is too heavy; just test system isolation)
	_mock_state = Node.new()
	add_child(_mock_state)

func after_each() -> void:
	_system.queue_free()
	_mock_state.queue_free()

func test_apply_effect_adds_to_active_list() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 5.0
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "test_source", 1)
	assert_eq(_system.active_effects.size(), 1, "Effect added to active list")

func test_effect_expires_after_duration() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 0.1
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "test_source", 1)
	assert_eq(_system.active_effects.size(), 1, "Effect present before expiry")

	# Simulate enough time passing
	_system._process(0.2)
	assert_eq(_system.active_effects.size(), 0, "Effect expired after duration")

func test_effect_stacks_up_to_max() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 10.0
	effect_def.max_stacks = 3

	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)
	_system.apply_effect(effect_def, "source", 1)  # 4th — should not exceed max

	assert_eq(_system.active_effects.size(), 1, "Same effect merges into one entry")
	assert_eq(_system.active_effects[0].current_stacks, 3, "Stacks capped at max_stacks=3")

func test_clear_removes_all() -> void:
	var effect_def := StatusEffect.new()
	effect_def.effect_category = StatusEffect.EffectCategory.STAT_MODIFIER
	effect_def.duration = 10.0
	effect_def.max_stacks = 1

	_system.apply_effect(effect_def, "s", 1)
	_system.apply_effect(effect_def, "s", 1)
	_system.clear_all_effects()
	assert_eq(_system.active_effects.size(), 0, "All effects cleared")
```

---

#### File 3: `tests/unit/test_character_switching.gd`

```gdscript
# test_character_switching.gd
# Tests: CharacterSwitchController — no buff/cooldown leaks on swap
# Covers sprint tasks S2-12, S2-13 (ADR-0002)

extends GutTest

var _controller: CharacterSwitchController
var _member_a: PartyMemberState
var _member_b: PartyMemberState

func before_each() -> void:
	_controller = CharacterSwitchController.new()
	add_child(_controller)

	# Create minimal PartyMemberState nodes (no character_data — just test control state)
	_member_a = _make_member("Evelyn")
	_member_b = _make_member("Evan")

	_controller.party_members = [_member_a, _member_b]

func _make_member(member_name: String) -> PartyMemberState:
	var m := PartyMemberState.new()
	m.name = member_name
	m.is_alive = true
	m.current_hp = 100
	m.max_hp = 100
	add_child(m)
	return m

func after_each() -> void:
	_controller.queue_free()
	_member_a.queue_free()
	_member_b.queue_free()

func test_first_member_is_player_controlled_after_init() -> void:
	_controller._initialize_starting_character()
	assert_true(_member_a.is_player_controlled, "First member starts player-controlled")
	assert_false(_member_b.is_player_controlled, "Second member starts AI-controlled")

func test_switch_transfers_control() -> void:
	_controller._initialize_starting_character()
	# Directly call switch_to (bypasses cooldown for unit test)
	_controller.current_character = _member_a
	_controller.current_member_index = 0
	_member_a.is_player_controlled = true

	_controller._complete_switch(_member_a, _member_b)

	assert_false(_member_a.is_player_controlled, "Previous member loses control after switch")

func test_dead_member_cannot_be_switched_to() -> void:
	_controller._initialize_starting_character()
	_member_b.is_alive = false
	_controller.current_character = _member_a
	_controller.current_member_index = 0

	_controller.switch_to(_member_b)

	# Should remain on member_a
	assert_eq(_controller.current_character, _member_a, "Cannot switch to dead member")

func test_switch_cooldown_blocks_rapid_switch() -> void:
	_controller._initialize_starting_character()
	_controller.current_character = _member_a
	_controller._switch_cooldown_remaining = 5.0  # Simulate active cooldown

	_controller.switch_to(_member_b)

	# Should remain on member_a — cooldown blocked it
	assert_eq(_controller.current_character, _member_a, "Switch blocked by cooldown")
```

---

#### File 4: `tests/unit/test_loot_drop.gd`

```gdscript
# test_loot_drop.gd
# Tests: LootTable.roll() distribution + LootDropper.drop_loot()
# Covers sprint tasks S2-14, S3-10

extends GutTest

func test_loot_table_returns_item() -> void:
	var item_a := ItemEquipment.new()
	var item_b := ItemEquipment.new()

	var table := LootTable.new()
	table.entries = [item_a, item_b]
	table.entry_weights = [1.0, 1.0]

	var rolled := table.roll()
	assert_not_null(rolled, "LootTable.roll() returns an item")
	assert_true(rolled == item_a or rolled == item_b, "Rolled item is from table")

func test_loot_table_empty_returns_null() -> void:
	var table := LootTable.new()
	var rolled := table.roll()
	assert_null(rolled, "Empty LootTable returns null")

func test_loot_table_single_item_always_returns_it() -> void:
	var item := ItemEquipment.new()
	var table := LootTable.new()
	table.entries = [item]
	table.entry_weights = [1.0]

	for i in 10:
		assert_eq(table.roll(), item, "Single-item table always rolls that item")

func test_loot_table_weight_zero_item_never_drops() -> void:
	var item_never := ItemEquipment.new()
	var item_always := ItemEquipment.new()
	var table := LootTable.new()
	table.entries = [item_never, item_always]
	table.entry_weights = [0.0, 1.0]

	# Run many times — item_never should never appear
	for i in 50:
		var rolled := table.roll()
		assert_ne(rolled, item_never, "Zero-weight item never drops")

func test_dropper_skips_without_pickup_scene() -> void:
	# LootDropper returns early if pickup_scene is null — no crash
	var enemy_data := EnemyData.new()
	var item := ItemEquipment.new()
	var table := LootTable.new()
	table.entries = [item]
	table.entry_weights = [1.0]

	var dropper := LootDropper.new()
	add_child(dropper)
	dropper.loot_table = table
	dropper.enemy_data = enemy_data
	# pickup_scene intentionally null

	# Should not crash
	dropper.drop_loot(Vector3.ZERO)
	assert_true(true, "drop_loot() without pickup_scene does not crash")
	dropper.queue_free()
```

---

#### File 5: `tests/unit/test_equipment.gd`

```gdscript
# test_equipment.gd
# Tests: EquipmentManager slot assignments + stat modifiers
# Covers sprint tasks S3-11, S3-12

extends GutTest

var _manager: EquipmentManager
var _state: PartyMemberState

func before_each() -> void:
	# Minimal PartyMemberState — we only need it for the stat call passthrough
	_state = PartyMemberState.new()
	_state.name = "TestMember"
	_state.is_alive = true
	_state.current_hp = 100
	_state.max_hp = 100
	_state.current_mp = 50
	_state.max_mp = 50
	add_child(_state)

	_manager = EquipmentManager.new()
	_manager.name = "EquipmentManager"
	add_child(_manager)
	_manager.state = _state

func after_each() -> void:
	_manager.queue_free()
	_state.queue_free()

func _make_weapon(atk_bonus: float) -> ItemEquipment:
	var item := ItemEquipment.new()
	item.equip_slot = ItemEquipment.EquipSlot.WEAPON
	item.atk_bonus = atk_bonus
	return item

func _make_armor(def_bonus: float) -> ItemEquipment:
	var item := ItemEquipment.new()
	item.equip_slot = ItemEquipment.EquipSlot.ARMOR
	item.def_bonus = def_bonus
	return item

func test_equip_weapon_fills_slot() -> void:
	var weapon := _make_weapon(15.0)
	var success := _manager.equip(weapon)
	assert_true(success, "Equipping weapon returns true")
	assert_eq(_manager.get_equipped(ItemEquipment.EquipSlot.WEAPON), weapon, "Weapon in slot")

func test_equip_replaces_existing_slot() -> void:
	var sword := _make_weapon(10.0)
	var axe := _make_weapon(20.0)
	_manager.equip(sword)
	_manager.equip(axe)
	assert_eq(_manager.get_equipped(ItemEquipment.EquipSlot.WEAPON), axe, "New weapon replaces old")

func test_get_total_modifiers_includes_all_equipped() -> void:
	var weapon := _make_weapon(10.0)
	var armor := _make_armor(5.0)
	_manager.equip(weapon)
	_manager.equip(armor)

	var mods := _manager.get_total_modifiers()
	assert_almost_eq(mods.get("atk", 0.0), 10.0, 0.01, "ATK modifier from weapon")
	assert_almost_eq(mods.get("def", 0.0), 5.0, 0.01, "DEF modifier from armor")

func test_unequip_clears_slot() -> void:
	var weapon := _make_weapon(10.0)
	_manager.equip(weapon)
	_manager.unequip(ItemEquipment.EquipSlot.WEAPON)
	assert_null(_manager.get_equipped(ItemEquipment.EquipSlot.WEAPON), "Slot empty after unequip")

func test_modifiers_zero_after_unequip() -> void:
	var weapon := _make_weapon(10.0)
	_manager.equip(weapon)
	_manager.unequip(ItemEquipment.EquipSlot.WEAPON)
	var mods := _manager.get_total_modifiers()
	assert_almost_eq(mods.get("atk", 0.0), 0.0, 0.01, "No ATK modifier after unequip")
```

---

## Completion Checklist

After completing all phases, verify these files exist:

### Phase 5
- [ ] `assets/scenes/ui/CombatHUD.tscn` — CanvasLayer with UI children
- [ ] `assets/scenes/enemies/GruntMelee.tscn` — has LootDropper node
- [ ] `assets/scenes/enemies/ArcherRanged.tscn` — has LootDropper node
- [ ] `src/gameplay/arena_wiring.gd` — wires all signals in `_ready()`
- [ ] `assets/scenes/TestArena.tscn` — updated with ArenaWiring node + CombatHUD instance

### Phase 6
- [ ] `.gutconfig` — GUT config in project root
- [ ] `addons/gut/plugin.cfg` — GUT plugin stub (remind user to install full GUT)
- [ ] `tests/unit/test_health_damage.gd`
- [ ] `tests/unit/test_status_effects.gd`
- [ ] `tests/unit/test_character_switching.gd`
- [ ] `tests/unit/test_loot_drop.gd`
- [ ] `tests/unit/test_equipment.gd`

---

## Notes for Gemini

1. **Do not modify** `src/ui/combat_hud.gd` — the script already exists and is correct.
2. **Do not modify** `src/gameplay/enemy_ai_controller.gd` — `died` signal already exists (line 8).
3. **Do not create** a new `LootPickup.tscn` — `pickup_scene` is intentionally left null for now.
4. **`_complete_switch` is async** in `character_switch_controller.gd` (uses `await`). The `_on_character_switched` signal fires after the await, which is correct — connect to the signal, not the function directly.
5. **GUT version**: Write tests using `extends GutTest` (GUT 9.x API). Methods: `assert_eq`, `assert_true`, `assert_false`, `assert_null`, `assert_not_null`, `assert_almost_eq`, `assert_ne`, `before_each`, `after_each`.
6. **`EquipmentManager`** must have `equip(item)`, `unequip(slot)`, `get_equipped(slot)`, and `get_total_modifiers() -> Dictionary` methods. If these don't exist, add them — read `src/gameplay/equipment_manager.gd` first and add only what's missing.
