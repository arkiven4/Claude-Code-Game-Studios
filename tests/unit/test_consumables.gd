# test_consumables.gd
extends GutTest

var character_data: CharacterData
var party_member: Node
var state: PartyMemberState
var sfx_system: StatusEffectsSystem

func before_each() -> void:
	character_data = CharacterData.new()
	character_data.base_hp = 100
	character_data.base_mp = 100
	character_data.hp_growth = 10
	character_data.mp_growth = 5
	
	party_member = Node.new()
	state = PartyMemberState.new()
	state.character_data = character_data
	party_member.add_child(state)
	
	sfx_system = StatusEffectsSystem.new()
	party_member.add_child(sfx_system)
	
	add_child(party_member)
	state._ready() # Initialize stats

func after_each() -> void:
	party_member.free()

func test_use_healing_potion_flat() -> void:
	state.current_hp = 50
	
	var effect = ItemEffect.new()
	effect.type = ItemEffect.EffectType.HEAL_HP_FLAT
	effect.value = 30
	
	var potion = ItemConsumable.new()
	potion.type = ItemConsumable.ConsumableType.HEALING
	potion.effects.append(effect)
	
	var success = ConsumableManager.use_consumable(potion, party_member)
	
	assert_true(success, "Consumable use should be successful")
	assert_eq(state.current_hp, 80, "HP should be restored by flat amount")

func test_use_healing_potion_percent() -> void:
	state.current_hp = 20
	# max_hp is 110 at level 1 (base 100 + growth 10)
	
	var effect = ItemEffect.new()
	effect.type = ItemEffect.EffectType.HEAL_HP_PERCENT
	effect.value = 50 # 50% of 110 = 55
	
	var potion = ItemConsumable.new()
	potion.type = ItemConsumable.ConsumableType.HEALING
	potion.effects.append(effect)
	
	var success = ConsumableManager.use_consumable(potion, party_member)
	
	assert_true(success, "Consumable use should be successful")
	assert_eq(state.current_hp, 75, "HP should be restored by percentage of max")

func test_use_mana_potion_flat() -> void:
	state.current_mp = 10
	
	var effect = ItemEffect.new()
	effect.type = ItemEffect.EffectType.RESTORE_MP_FLAT
	effect.value = 40
	
	var potion = ItemConsumable.new()
	potion.type = ItemConsumable.ConsumableType.HEALING # Still categorizing as healing/restoration
	potion.effects.append(effect)
	
	var success = ConsumableManager.use_consumable(potion, party_member)
	
	assert_true(success, "Consumable use should be successful")
	assert_eq(state.current_mp, 50, "MP should be restored by flat amount")

func test_use_buff_potion() -> void:
	var mock_effect_def = StatusEffect.new()
	mock_effect_def.effect_id = "test_buff"
	mock_effect_def.display_name = "Test Buff"
	
	var effect = ItemEffect.new()
	effect.type = ItemEffect.EffectType.APPLY_STATUS_EFFECT
	effect.status_effect = mock_effect_def
	
	var potion = ItemConsumable.new()
	potion.type = ItemConsumable.ConsumableType.BUFF
	potion.effects.append(effect)
	
	var success = ConsumableManager.use_consumable(potion, party_member)
	
	assert_true(success, "Consumable use should be successful")
	assert_eq(sfx_system.active_effects.size(), 1, "One status effect should be applied")
	assert_eq(sfx_system.active_effects[0].definition.effect_id, "test_buff", "Correct effect applied")

func test_use_complex_potion() -> void:
	state.current_hp = 10
	state.current_mp = 10
	
	var hp_effect = ItemEffect.new()
	hp_effect.type = ItemEffect.EffectType.HEAL_HP_FLAT
	hp_effect.value = 20
	
	var mp_effect = ItemEffect.new()
	mp_effect.type = ItemEffect.EffectType.RESTORE_MP_FLAT
	mp_effect.value = 20
	
	var potion = ItemConsumable.new()
	potion.effects.append(hp_effect)
	potion.effects.append(mp_effect)
	
	var success = ConsumableManager.use_consumable(potion, party_member)
	
	assert_true(success, "Complex potion use should be successful")
	assert_eq(state.current_hp, 30, "Both HP and MP should be restored")
	assert_eq(state.current_mp, 30, "Both HP and MP should be restored")
