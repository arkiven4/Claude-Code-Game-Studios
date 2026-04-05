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
	item.slot = ItemEquipment.EquipSlot.WEAPON
	item.base_atk = atk_bonus
	return item

func _make_armor(def_bonus: float) -> ItemEquipment:
	var item := ItemEquipment.new()
	item.slot = ItemEquipment.EquipSlot.ARMOR
	item.base_def = def_bonus
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
