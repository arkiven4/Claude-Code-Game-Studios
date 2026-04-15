import os
import re
import json

# Template for EnemyData with optional loot table
ENEMY_TRES_TEMPLATE = """[gd_resource type="Resource" script_class="EnemyData" format=3 uid="uid://{uid}"]
[ext_resource type="Script" uid="uid://enemy_data_script" path="res://src/core/enemy_data.gd" id="1_enemy"]
{ext_loot}
[ext_resource type="Texture2D" uid="uid://icon_{icon_id}" path="res://assets/art/ui/monster_icons/{icon_file}" id="2_icon"]

[resource]
script = ExtResource("1_enemy")
enemy_id = "{enemy_id}"
display_name = "{display_name}"
enemy_class = {class_enum}
behavior_profile = 0
base_max_hp = {hp}
base_atk = {atk}
base_def = {def_val}
base_spd = 1.0
physical_resistance = 1.0
magical_resistance = 1.0
holy_resistance = 1.0
dark_resistance = 1.0
status_immunities = []
skill_list = []
{loot_prop}
death_threshold = 0.0
model_path = "res://assets/models/enemies/placeholder_capsule.tscn"
portrait_sprite = ExtResource("2_icon")
"""

def generate_monster_resources():
    data_file = "assets/data/monsters/lineage2m_monsters.json"
    icon_dir = "assets/art/ui/monster_icons"
    monster_dir = "assets/data/monsters/lineage2m"
    loot_dir = "assets/data/loot/lineage2m"
    
    if not os.path.exists(data_file):
        print("Data file not found.")
        return
    os.makedirs(monster_dir, exist_ok=True)

    with open(data_file, 'r') as f:
        all_monster_data = json.load(f)

    print(f"Loaded {len(all_monster_data)} monsters.")

    generated_count = 0
    for monster in all_monster_data:
        name = monster["name"]
        lv = monster["level"]
        raw_class = monster["class"]
        icon_file = monster["filename"]
        
        class_enum = 0
        if "Elite" in raw_class: class_enum = 1
        elif "Boss" in raw_class: class_enum = 3
        
        hp = 100 + (lv * 50)
        atk = 10 + (lv * 5)
        def_val = 5 + (lv * 2)

        def clean_id(s):
            return re.sub(r'[^a-zA-Z0-9]', '_', s.lower()).strip('_')
            
        clean_name = clean_id(name)
        enemy_id = f"l2m_monster_{clean_name}"
        tres_filename = f"{enemy_id}.tres"
        tres_path = os.path.join(monster_dir, tres_filename)
        
        # Check for loot table
        loot_id = f"loot_{clean_name}"
        loot_res_path = f"res://{loot_dir}/{loot_id}.tres"
        
        ext_loot = ""
        loot_prop = "loot_table = null"
        if os.path.exists(os.path.join(loot_dir, f"{loot_id}.tres")):
            ext_loot = f'[ext_resource type="Resource" path="{loot_res_path}" id="3_loot"]\n'
            loot_prop = "loot_table = ExtResource(\"3_loot\")"
        
        content = ENEMY_TRES_TEMPLATE.format(
            uid=enemy_id,
            icon_id=generated_count + 20000,
            icon_file=icon_file,
            class_enum=class_enum,
            display_name=name,
            enemy_id=enemy_id,
            hp=hp,
            atk=atk,
            def_val=def_val,
            ext_loot=ext_loot,
            loot_prop=loot_prop
        )
        
        with open(tres_path, 'w') as f:
            f.write(content)
        
        generated_count += 1
        if generated_count % 100 == 0:
            print(f"Generated {generated_count} resources...")

    print(f"\nSuccessfully updated {generated_count} monster resources with loot tables.")

if __name__ == "__main__":
    generate_monster_resources()
