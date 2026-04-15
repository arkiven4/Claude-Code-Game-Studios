import os
import re
import json

# Template for generating new SkillData resources
SKILL_TRES_TEMPLATE = """[gd_resource type="Resource" script_class="SkillData" format=3 uid="uid://{uid}"]
[ext_resource type="Script" uid="uid://be6mqnv6bugg" path="res://src/core/skill_data.gd" id="1_skill"]
[ext_resource type="Script" uid="uid://bfep1t8y7u5tq" path="res://src/core/skill_tier_config.gd" id="2_tier"]
[ext_resource type="Texture2D" uid="uid://icon_{icon_id}" path="res://assets/art/ui/skill_icons/{icon_file}" id="3_icon"]

[sub_resource type="Resource" id="Tier1"]
script = ExtResource("2_tier")
effect_value = 1.0
tier_description = "Automatically generated from scraped Lineage 2M data"

[resource]
script = ExtResource("1_skill")
skill_type = {skill_type_enum}
display_name = "{display_name}"
skill_id = "{skill_id}"
description = "{description}"
icon = ExtResource("3_icon")
tiers = Array[ExtResource("2_tier")]([SubResource("Tier1")])
"""

def link_and_generate():
    data_file = "assets/data/skills/lineage2m_data.json"
    icon_dir = "assets/art/ui/skill_icons"
    skill_dir = "assets/data/skills/lineage2m"
    
    if not os.path.exists(data_file):
        print("Data file not found.")
        return
    if not os.path.exists(skill_dir):
        os.makedirs(skill_dir)

    with open(data_file, 'r') as f:
        all_skill_data = json.load(f)

    print(f"Loaded {len(all_skill_data)} skills from data file.")

    generated_count = 0
    updated_count = 0

    for skill in all_skill_data:
        page = skill["page"].lower()
        name = skill["name"]
        skill_type_str = skill["type"]
        description = skill["description"].replace('"', '\\"') # Escape quotes for .tres
        icon_file = skill["filename"]
        
        # Clean ID for the filename and uid
        def clean_id(s):
            return re.sub(r'[^a-zA-Z0-9]', '_', s.lower()).strip('_')
            
        clean_name = clean_id(name)
        skill_id = f"{page}_{clean_name}"
        tres_filename = f"{skill_id}.tres"
        tres_path = os.path.join(skill_dir, tres_filename)
        
        # Determine skill_type enum (0: Damage, 1: Status, 2: Support, 3: Utility)
        skill_type_enum = 0
        if "Heal" in name or "Cure" in name or "Bless" in name or "Restore" in name:
            skill_type_enum = 2
        elif any(kw in name for kw in ["Stun", "Silence", "Slow", "Root", "Darkness", "Cancellation"]):
            skill_type_enum = 1
        elif "Passive" in skill_type_str or any(kw in name for kw in ["Mastery", "Increase", "Boost", "Armor", "Control", "Improve", "Weight"]):
            skill_type_enum = 3 

        icon_full_path = os.path.join(icon_dir, icon_file)
        if not os.path.exists(icon_full_path):
            # Try to find a similar icon if filename changed
            found_icon = False
            for f in os.listdir(icon_dir):
                if clean_name in f.lower() and page in f.lower():
                    icon_file = f
                    found_icon = True
                    break
            if not found_icon:
                print(f"  Warning: Icon {icon_file} not found for {name}")
                # Continue anyway, Godot will show missing resource which is better than nothing
        
        if os.path.exists(tres_path):
            # Update existing file
            update_skill_resource(tres_path, name, description, icon_file, skill_type_enum)
            updated_count += 1
        else:
            # Generate new file
            content = SKILL_TRES_TEMPLATE.format(
                uid=skill_id,
                icon_id=generated_count + 1000,
                icon_file=icon_file,
                skill_type_enum=skill_type_enum,
                display_name=name,
                skill_id=skill_id,
                description=description
            )
            with open(tres_path, 'w') as f:
                f.write(content)
            generated_count += 1

    print(f"\nSuccessfully generated {generated_count} and updated {updated_count} skills.")

def update_skill_resource(filepath, name, description, icon_file, skill_type):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Update or add the icon ext_resource
    icon_path = f"res://assets/art/ui/skill_icons/{icon_file}"
    ext_id = "icon_res"
    
    has_icon_ext = False
    for i, line in enumerate(lines):
        if 'path="res://assets/art/ui/skill_icons/' in line:
            lines[i] = f'[ext_resource type="Texture2D" uid="uid://icon_upd" path="{icon_path}" id="{ext_id}"]\n'
            has_icon_ext = True
            break
            
    if not has_icon_ext:
        # Insert before [resource]
        for i, line in enumerate(lines):
            if line.startswith("[resource]"):
                lines.insert(i, f'[ext_resource type="Texture2D" uid="uid://icon_new" path="{icon_path}" id="{ext_id}"]\n')
                break

    # Update properties in [resource] section
    resource_idx = -1
    for i, line in enumerate(lines):
        if line.startswith("[resource]"):
            resource_idx = i
            break
            
    if resource_idx != -1:
        # Use a dict to track what we've updated
        updated = {"display_name": False, "description": False, "icon": False, "skill_type": False}
        
        for i in range(resource_idx + 1, len(lines)):
            if lines[i].startswith("display_name ="):
                lines[i] = f'display_name = "{name}"\n'
                updated["display_name"] = True
            elif lines[i].startswith("description ="):
                lines[i] = f'description = "{description}"\n'
                updated["description"] = True
            elif lines[i].startswith("icon ="):
                lines[i] = f'icon = ExtResource("{ext_id}")\n'
                updated["icon"] = True
            elif lines[i].startswith("skill_type ="):
                lines[i] = f'skill_type = {skill_type}\n'
                updated["skill_type"] = True
            elif lines[i].startswith("["): # End of resource
                break
        
        # Add missing properties
        if not updated["display_name"]: lines.insert(resource_idx + 1, f'display_name = "{name}"\n')
        if not updated["description"]: lines.insert(resource_idx + 1, f'description = "{description}"\n')
        if not updated["icon"]: lines.insert(resource_idx + 1, f'icon = ExtResource("{ext_id}")\n')

    with open(filepath, 'w') as f:
        f.writelines(lines)

if __name__ == "__main__":
    link_and_generate()
