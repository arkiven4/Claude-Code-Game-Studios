# inventory_ui.gd
class_name InventoryUI
extends CanvasLayer

## Manages the display and item transfer for character inventories.

@export var item_list: ItemList
@export var character_selector: OptionButton
@export var transfer_target_selector: OptionButton
@export var transfer_button: Button
@export var transfer_all_button: Button
@export var equip_button: Button
@export var unequip_button: Button
@export var use_button: Button

var current_character: PartyMemberState
var party_members: Array[PartyMemberState] = []

func _ready() -> void:
	if transfer_button:
		transfer_button.pressed.connect(_on_transfer_pressed)
	if transfer_all_button:
		transfer_all_button.pressed.connect(_on_transfer_all_pressed)
	if equip_button:
		equip_button.pressed.connect(_on_equip_pressed)
	if unequip_button:
		unequip_button.pressed.connect(_on_unequip_pressed)
	if use_button:
		use_button.pressed.connect(_on_use_pressed)
	if character_selector:
		character_selector.item_selected.connect(_on_character_selected)
	
	# Try to find CombatEncounterManager to get party members
	var manager = get_tree().get_first_node_in_group("CombatEncounterManager")
	if manager and "party_members" in manager:
		party_members = manager.party_members
		_update_selectors()

func _refresh_party_members() -> void:
	var manager = get_tree().get_first_node_in_group("CombatEncounterManager")
	if manager and "party_members" in manager:
		party_members = manager.party_members
		_update_selectors()

func open_for_character(character: PartyMemberState) -> void:
	_refresh_party_members()
	current_character = character
	visible = true
	$MainControl.visible = true
	_refresh_inventory()
	_refresh_transfer_targets()
	
	# Update selector to match
	if character_selector:
		for i in range(party_members.size()):
			if party_members[i] == character:
				character_selector.selected = i
				break

func close() -> void:
	visible = false

func _update_selectors() -> void:
	if character_selector:
		character_selector.clear()
		for member in party_members:
			character_selector.add_item(member.name)
	
	_refresh_transfer_targets()

func _on_character_selected(index: int) -> void:
	if index >= 0 and index < party_members.size():
		current_character = party_members[index]
		_refresh_inventory()
		_refresh_transfer_targets()

func _refresh_inventory() -> void:
	if not item_list or not current_character or not current_character.inventory:
		return
		
	item_list.clear()
	
	var equip_manager = current_character.get_node_or_null("EquipmentManager")
	
	# Add equipment
	for item in current_character.inventory.get_items():
		var display_text = item.display_name
		if equip_manager:
			var is_equipped = false
			for slot in range(5): # Assuming 5 slots: WEAPON, ARMOR, HELMET, ACCESSORY, RELIC
				if equip_manager.get_equipped(slot) == item:
					is_equipped = true
					break
			if is_equipped:
				display_text += " [E]"
				
		var idx = item_list.add_item(display_text, item.icon)
		item_list.set_item_metadata(idx, item)
		
	# Add consumables
	for item in current_character.inventory.get_consumables():
		var idx = item_list.add_item(item.display_name, item.icon)
		item_list.set_item_metadata(idx, item)

func _refresh_transfer_targets() -> void:
	if not transfer_target_selector:
		return
		
	transfer_target_selector.clear()
	for member in party_members:
		if member != current_character:
			var idx = transfer_target_selector.get_item_count()
			transfer_target_selector.add_item(member.name)
			transfer_target_selector.set_item_metadata(idx, member)

func _on_equip_pressed() -> void:
	var selected = item_list.get_selected_items()
	if selected.is_empty(): return
	
	var item = item_list.get_item_metadata(selected[0])
	if not item is ItemEquipment: return
	
	var equip_manager = current_character.get_node_or_null("EquipmentManager")
	if equip_manager and equip_manager.has_method("equip"):
		if equip_manager.equip(item):
			print("[Inventory] Equipped %s to %s" % [item.display_name, current_character.name])
			_refresh_inventory()

func _on_unequip_pressed() -> void:
	var selected = item_list.get_selected_items()
	if selected.is_empty(): return
	
	var item = item_list.get_item_metadata(selected[0])
	if not item is ItemEquipment: return
	
	var equip_manager = current_character.get_node_or_null("EquipmentManager")
	if equip_manager:
		for slot in range(5):
			if equip_manager.get_equipped(slot) == item:
				equip_manager.unequip(slot)
				print("[Inventory] Unequipped %s from %s" % [item.display_name, current_character.name])
				_refresh_inventory()
				break

func _on_use_pressed() -> void:
	var selected = item_list.get_selected_items()
	if selected.is_empty(): return
	
	var item = item_list.get_item_metadata(selected[0])
	if not item is ItemConsumable: return
	
	if ConsumableManager.use_consumable(item, current_character.get_parent()):
		print("[Inventory] Used %s on %s" % [item.display_name, current_character.name])
		current_character.inventory.remove_consumable(item)
		_refresh_inventory()

func _on_transfer_pressed() -> void:
	var selected_items = item_list.get_selected_items()
	if selected_items.is_empty():
		return
		
	var target_idx = transfer_target_selector.selected
	if target_idx == -1:
		return
		
	var target_member = transfer_target_selector.get_item_metadata(target_idx)
	if not target_member or not target_member.inventory:
		return
		
	for idx in selected_items:
		var item = item_list.get_item_metadata(idx)
		if current_character.inventory.transfer_to(item, target_member.inventory):
			print("[Inventory] Transferred %s from %s to %s" % [item.display_name, current_character.name, target_member.name])
			
	_refresh_inventory()

func _on_transfer_all_pressed() -> void:
	if not current_character or not current_character.inventory:
		return
		
	var target_idx = transfer_target_selector.selected
	if target_idx == -1:
		return
		
	var target_member = transfer_target_selector.get_item_metadata(target_idx)
	if not target_member or not target_member.inventory:
		return
		
	# Transfer all equipment
	var equipment = current_character.inventory.get_items().duplicate()
	for item in equipment:
		current_character.inventory.transfer_to(item, target_member.inventory)
		
	# Transfer all consumables
	var consumables = current_character.inventory.get_consumables().duplicate()
	for item in consumables:
		current_character.inventory.transfer_to(item, target_member.inventory)
			
	print("[Inventory] Transferred ALL items from %s to %s" % [current_character.name, target_member.name])
	_refresh_inventory()
