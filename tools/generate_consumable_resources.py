import os
import re
import json

# Template for generating new ItemConsumable resources
CONSUMABLE_TRES_TEMPLATE = """[gd_resource type="Resource" script_class="ItemConsumable" format=3 uid="uid://{uid}"]
[ext_resource type="Script" uid="uid://item_consumable_script" path="res://src/core/item_consumable.gd" id="1_consumable"]
[ext_resource type="Texture2D" uid="uid://icon_{icon_id}" path="res://assets/art/ui/item_icons/{icon_file}" id="2_icon"]

[resource]
script = ExtResource("1_consumable")
item_id = "{item_id}"
display_name = "{display_name}"
description = "{description}"
type = {type_enum}
is_stackable = true
max_stack = 999
effect_details = "{effect_details}"
duration = {duration}
level_requirement = 1
sell_price = 10
icon = ExtResource("2_icon")
"""

def generate_consumable_resources():
    data_file = "assets/data/items/lineage2m_consumables.json"
    icon_dir = "assets/art/ui/item_icons"
    item_dir = "assets/data/items/lineage2m"
    
    if not os.path.exists(data_file):
        print("Data file not found.")
        return
    os.makedirs(item_dir, exist_ok=True)

    with open(data_file, 'r') as f:
        all_item_data = json.load(f)

    print(f"Loaded {len(all_item_data)} consumables.")

    # enum ConsumableType { HEALING, BUFF, SCROLL, MATERIAL, BOX, OTHER }
    # 0: HEALING, 1: BUFF, 2: SCROLL, 3: MATERIAL, 4: BOX, 5: OTHER

    generated_count = 0
    for item in all_item_data:
        name = item["name"]
        raw_type = item["type"]
        details = item["details"].replace('"', '\\"')
        icon_file = item["filename"]
        
        # Determine type enum
        type_enum = 5 # OTHER
        duration = 0.0
        
        type_lower = raw_type.lower()
        name_lower = name.lower()
        
        if "potion" in type_lower or "health" in name_lower or "mana" in name_lower:
            if "acceleration" in name_lower or "growth" in name_lower:
                type_enum = 1 # BUFF
                duration = 600.0 # Default 10 min
            else:
                type_enum = 0 # HEALING
        elif "food" in type_lower:
            type_enum = 1 # BUFF
            duration = 1800.0 # Default 30 min
        elif "scroll" in type_lower:
            if "enchant" in name_lower:
                type_enum = 3 # MATERIAL
            else:
                type_enum = 2 # SCROLL
                if "combat" in name_lower or "defense" in name_lower:
                    duration = 1200.0 # 20 min
        elif "progression" in type_lower or "stone" in name_lower:
            type_enum = 3 # MATERIAL
        elif "box" in type_lower or "chest" in name_lower:
            type_enum = 4 # BOX

        def clean_id(s):
            return re.sub(r'[^a-zA-Z0-9]', '_', s.lower()).strip('_')
            
        clean_name = clean_id(name)
        item_id = f"l2m_consumable_{clean_name}"
        tres_filename = f"{item_id}.tres"
        tres_path = os.path.join(item_dir, tres_filename)
        
        content = CONSUMABLE_TRES_TEMPLATE.format(
            uid=item_id,
            icon_id=generated_count + 10000,
            icon_file=icon_file,
            type_enum=type_enum,
            display_name=name,
            item_id=item_id,
            description=f"{raw_type}: {name}",
            effect_details=details,
            duration=duration
        )
        
        with open(tres_path, 'w') as f:
            f.write(content)
        
        generated_count += 1

    print(f"\nSuccessfully generated {generated_count} consumable resources in {item_dir}.")

if __name__ == "__main__":
    generate_item_resources = generate_consumable_resources # fix name call
    generate_consumable_resources()
