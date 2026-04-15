import os
import re
import json

# Template for generating new ItemEquipment resources
ITEM_TRES_TEMPLATE = """[gd_resource type="Resource" script_class="ItemEquipment" format=3 uid="uid://{uid}"]
[ext_resource type="Script" uid="uid://item_script" path="res://src/core/item_equipment.gd" id="1_item"]
[ext_resource type="Texture2D" uid="uid://icon_{icon_id}" path="res://assets/art/ui/item_icons/{icon_file}" id="2_icon"]

[resource]
script = ExtResource("1_item")
item_id = "{item_id}"
display_name = "{display_name}"
description = "{description}"
slot = {slot_enum}
rarity = {rarity_enum}
base_atk = {base_atk}
base_def = {base_def}
base_spd = 0.0
base_max_hp = 0.0
base_max_mp = 0.0
base_crit = 0.0
level_requirement = 1
sell_price = 100
icon = ExtResource("2_icon")
"""

def generate_item_resources():
    data_file = "assets/data/items/lineage2m_items_full.json"
    icon_dir = "assets/art/ui/item_icons"
    item_dir = "assets/data/items/lineage2m"
    
    if not os.path.exists(data_file):
        print("Data file not found.")
        return
    os.makedirs(item_dir, exist_ok=True)

    with open(data_file, 'r') as f:
        all_item_data = json.load(f)

    print(f"Loaded {len(all_item_data)} items.")

    # Rarity mapping
    rarity_map = {
        "Common": 0,
        "Uncommon": 1,
        "Rare": 2,
        "Unique": 3,
        "Epic": 3,
        "Legend": 4
    }

    # Slot mapping (EquipSlot { WEAPON, ARMOR, HELMET, ACCESSORY, RELIC })
    slot_map = {
        "Weapon": 0,
        "Armor": 1,
        "Accessory": 3
    }

    generated_count = 0
    for item in all_item_data:
        main_type = item["main_type"]
        class_specific = item["class_specific"]
        name = item["name"]
        rank = item["rank"]
        stats = item["stats"]
        options = item["options"]
        material = item["material"]
        icon_file = item["filename"]
        
        # Determine slot override for Helm
        slot_enum = slot_map.get(main_type, 1)
        if "Helm" in class_specific: slot_enum = 2 # HELMET

        def clean_id(s):
            return re.sub(r'[^a-zA-Z0-9]', '_', s.lower()).strip('_')
            
        clean_name = clean_id(name)
        clean_class = clean_id(class_specific)
        item_id = f"l2m_{clean_class}_{clean_name}"
        tres_filename = f"{item_id}.tres"
        tres_path = os.path.join(item_dir, tres_filename)
        
        rarity_enum = rarity_map.get(rank, 0)
        
        # Parse basic stats
        base_atk = 0.0
        base_def = 0.0
        
        for k, v in stats.items():
            try:
                # Extract number from string like "10" or "5~10"
                num = float(re.findall(r'\d+', v)[0])
                if "damage" in k: base_atk = num
                elif "defense" in k: base_def = num
            except: pass

        desc_parts = []
        if options: desc_parts.append(f"Options: {options}")
        if material: desc_parts.append(f"Material: {material}")
        description = " | ".join(desc_parts).replace('"', '\\"')

        content = ITEM_TRES_TEMPLATE.format(
            uid=item_id,
            icon_id=generated_count + 5000,
            icon_file=icon_file,
            rarity_enum=rarity_enum,
            slot_enum=slot_enum,
            display_name=name,
            item_id=item_id,
            description=description,
            base_atk=base_atk,
            base_def=base_def
        )
        
        with open(tres_path, 'w') as f:
            f.write(content)
        
        generated_count += 1
        if generated_count % 100 == 0:
            print(f"Generated {generated_count} resources...")

    print(f"\nSuccessfully generated {generated_count} item resources in {item_dir}.")

if __name__ == "__main__":
    generate_item_resources()
