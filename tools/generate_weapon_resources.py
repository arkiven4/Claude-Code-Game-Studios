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
description = "Lineage 2M {display_name} - Imported weapon."
slot = 0
rarity = {rarity_enum}
base_atk = 10.0
base_def = 0.0
base_spd = 0.0
base_max_hp = 0.0
base_max_mp = 0.0
base_crit = 0.0
level_requirement = 1
sell_price = 100
icon = ExtResource("2_icon")
"""

def generate_weapon_resources():
    data_file = "assets/data/items/lineage2m_weapons.json"
    icon_dir = "assets/art/ui/item_icons"
    item_dir = "assets/data/items/lineage2m"
    
    if not os.path.exists(data_file):
        print("Data file not found.")
        return
    os.makedirs(item_dir, exist_ok=True)

    with open(data_file, 'r') as f:
        all_weapon_data = json.load(f)

    print(f"Loaded {len(all_weapon_data)} weapons.")

    # Rarity mapping
    rarity_map = {
        "Common": 0,
        "Rare": 2,
        "Unique": 3,
        "Epic": 3,
        "Legend": 4
    }

    generated_count = 0
    for weapon in all_weapon_data:
        name = weapon["name"]
        rank = weapon["rank"]
        icon_file = weapon["filename"]
        scroller_idx = weapon["scroller_index"]
        
        # Determine weapon type based on scroller index
        # 2: Sword, 3: DualBlades, 4: Dagger, 5: Bow, 6: Staff, 7: Orb
        weapon_type = "weapon"
        if scroller_idx == 2: weapon_type = "sword"
        elif scroller_idx == 3: weapon_type = "dualblades"
        elif scroller_idx == 4: weapon_type = "dagger"
        elif scroller_idx == 5: weapon_type = "bow"
        elif scroller_idx == 6: weapon_type = "staff"
        elif scroller_idx == 7: weapon_type = "orb"

        def clean_id(s):
            return re.sub(r'[^a-zA-Z0-9]', '_', s.lower()).strip('_')
            
        clean_name = clean_id(name)
        item_id = f"l2m_{weapon_type}_{clean_name}"
        tres_filename = f"{item_id}.tres"
        tres_path = os.path.join(item_dir, tres_filename)
        
        rarity_enum = rarity_map.get(rank, 0)
        
        content = ITEM_TRES_TEMPLATE.format(
            uid=item_id,
            icon_id=generated_count + 2000,
            icon_file=icon_file,
            rarity_enum=rarity_enum,
            display_name=name,
            item_id=item_id
        )
        
        with open(tres_path, 'w') as f:
            f.write(content)
        
        generated_count += 1
        if generated_count % 50 == 0:
            print(f"Generated {generated_count} resources...")

    print(f"\nSuccessfully generated {generated_count} weapon resources in {item_dir}.")

if __name__ == "__main__":
    generate_weapon_resources()
