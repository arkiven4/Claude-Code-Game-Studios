# test_health_damage.gd
# Tests: HealthDamageSystem formulas
# Covers sprint tasks S1-10, S1-11

extends GutTest

func before_all() -> void:
	HealthDamageSystem.use_variance = false

func after_all() -> void:
	HealthDamageSystem.use_variance = true

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
	var result := HealthDamageSystem.calculate_heal(100, 30, 1.0, 200, 0.0, 100)
	assert_eq(result["heal_amount"], 40, "Basic heal formula")

func test_calculate_heal_capped_by_missing_hp() -> void:
	# Only 10 HP missing — can't heal more than that
	var result := HealthDamageSystem.calculate_heal(100, 30, 1.0, 200, 0.0, 190)
	assert_eq(result["heal_amount"], 10, "Heal capped at missing HP")
