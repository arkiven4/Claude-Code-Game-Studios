import os
import re
import json

# Template for LootTable
LOOT_TRES_TEMPLATE = """[gd_resource type="Resource" script_class="LootTable" format=3 uid="uid://{uid}"]
[ext_resource type="Script" path="res://src/gameplay/loot/loot_table.gd" id="1_loot"]
{ext_resources}

[resource]
script = ExtResource("1_loot")
entries = Array[Resource]([{entry_list}])
entry_weights = Array[float]([{weight_list}])
"""

def clean_id(s):
    # Remove everything that's not alphanumeric or space, then replace spaces with underscore
    s = re.sub(r'[^a-zA-Z0-9\s]', '', s.lower())
    return re.sub(r'\s+', '_', s.strip())

def generate_loot_tables():
    monster_data_file = "assets/data/monsters/lineage2m_monsters.json"
    item_dir = "assets/data/items/lineage2m"
    loot_dir = "assets/data/loot/lineage2m"
    
    if not os.path.exists(monster_data_file):
        print(f"Monster data not found at {monster_data_file}")
        return
    os.makedirs(loot_dir, exist_ok=True)

    with open(monster_data_file, 'r', encoding='utf-8') as f:
        monsters = json.load(f)

    # Map item names to their resource paths
    # We'll use multiple keys for better matching
    item_map = {}
    if os.path.exists(item_dir):
        for f in os.listdir(item_dir):
            if f.endswith(".tres"):
                full_path = f"res://{item_dir}/{f}"
                
                # key 1: full filename without extension
                fname = f.replace(".tres", "")
                item_map[fname] = full_path
                
                # key 2: cleaned version of the filename
                clean_fname = clean_id(fname)
                item_map[clean_fname] = full_path
                
                # key 3: if it has l2m_prefix_name, try just name
                parts = fname.split("_")
                if len(parts) >= 3 and parts[0] == "l2m":
                    # parts[1] is usually the category (sword, armor, etc)
                    short_name = "_".join(parts[2:])
                    item_map[short_name] = full_path
                    item_map[clean_id(short_name)] = full_path

    print(f"Mapped {len(item_map)} potential item keys.")

    generated_count = 0
    for monster in monsters:
        name = monster.get("name", "unknown")
        drops = monster.get("drops", [])
        if not drops: continue

        monster_id = clean_id(name)
        loot_id = f"loot_{monster_id}"
        tres_path = os.path.join(loot_dir, f"{loot_id}.tres")

        # Find matching items
        found_items = []
        for drop_name in drops:
            # Try to match the drop name against our map
            c_drop = clean_id(drop_name)
            
            # Direct match
            if c_drop in item_map:
                found_items.append(item_map[c_drop])
                continue
            
            # Fuzzy match: is the drop name inside any of our item keys?
            # or is any item key inside our drop name?
            match_found = False
            for key in item_map:
                if len(key) > 3: # Avoid trivial matches
                    if key in c_drop or c_drop in key:
                        found_items.append(item_map[key])
                        match_found = True
                        break
        
        if not found_items: continue

        # Deduplicate items while preserving order
        unique_items = []
        for item in found_items:
            if item not in unique_items:
                unique_items.append(item)
        
        # Build Resource parts
        ext_resources = ""
        entry_list = ""
        weight_list = ""
        
        for idx, item_path in enumerate(unique_items):
            res_id = idx + 2
            ext_resources += f'[ext_resource type="Resource" path="{item_path}" id="{res_id}_item"]\n'
            entry_list += f'ExtResource("{res_id}_item"), '
            # Assign weights based on some heuristic? For now, equal weights.
            # But maybe rare items should have lower weights?
            # Drop list from scraper doesn't have weights, so we'll stay with 1.0.
            weight_list += "1.0, "

        entry_list = entry_list.strip(", ")
        weight_list = weight_list.strip(", ")

        content = LOOT_TRES_TEMPLATE.format(
            uid=monster_id, # Using monster_id as UID for simplicity
            ext_resources=ext_resources,
            entry_list=entry_list,
            weight_list=weight_list
        )
        
        with open(tres_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        generated_count += 1

    print(f"Successfully generated {generated_count} loot tables in {loot_dir}.")

if __name__ == "__main__":
    generate_loot_tables()
