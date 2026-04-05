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
	var enemy_data_res := EnemyData.new()
	var item := ItemEquipment.new()
	var table := LootTable.new()
	table.entries = [item]
	table.entry_weights = [1.0]

	var dropper := LootDropper.new()
	add_child(dropper)
	dropper.loot_table = table
	dropper.enemy_data = enemy_data_res
	# pickup_scene intentionally null

	# Should not crash
	dropper.drop_loot(Vector3.ZERO)
	assert_true(true, "drop_loot() without pickup_scene does not crash")
	dropper.queue_free()
