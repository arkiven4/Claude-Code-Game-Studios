#!/bin/bash

# Configuration
SKILL_DATA_UID="uid://be6mqnv6bugg"
TIER_CONFIG_UID="uid://bfep1t8y7u5tq"
OUTPUT_DIR="assets/data/skills/lineage2m"
mkdir -p "$OUTPUT_DIR"

# Function to generate a basic skill .tres
generate_skill() {
    local category=$1
    local id=$2
    local name=$3
    local type=$4 # 0: Damage, 1: Status, 2: Support, 3: Utility
    local description=$5
    local mp=$6

    local file_path="$OUTPUT_DIR/${category}_${id}.tres"
    local uid="uid://${category}_${id}"

    cat <<EOF > "$file_path"
[gd_resource type="Resource" script_class="SkillData" format=3 uid="$uid"]
[ext_resource type="Script" uid="$SKILL_DATA_UID" path="res://src/core/skill_data.gd" id="1_skill"]
[ext_resource type="Script" uid="$TIER_CONFIG_UID" path="res://src/core/skill_tier_config.gd" id="2_tier"]
[sub_resource type="Resource" id="Tier1"]
script = ExtResource("2_tier")
effect_value = 1.0
tier_description = "Imported from Lineage 2M"
[resource]
script = ExtResource("1_skill")
skill_type = $type
display_name = "$name"
skill_id = "${category}_${id}"
description = "$description"
mp_cost = $mp
tiers = Array[ExtResource("2_tier")]([SubResource("Tier1")])
EOF
}

# Example Sword Skills
generate_skill "sword" "shield_stun" "Shield Stun" 1 "Strikes with a Shield to Stun the enemy." 10
generate_skill "sword" "vanguard" "Vanguard" 3 "Increases tension in battle for faster movement." 40
generate_skill "sword" "power_strike" "Power Strike" 0 "Deals a heavy blow for strong damage." 2
generate_skill "sword" "magic_resistance" "Magic Resistance" 3 "Temporarily raises power to resist enemy's skills." 40
generate_skill "sword" "war_cry" "War Cry" 3 "Roars out in battle to increase Melee Damage and Accuracy." 0
generate_skill "sword" "majesty" "Majesty" 3 "Gains an unyielding spirit to overcome any adversity." 0
generate_skill "sword" "holy_blade" "Holy Blade" 3 "Holy power is bestowed upon the sword." 0

# Staff Skills
generate_skill "staff" "flame_strike" "Flame Strike" 0 "Shoots an exploding fireball for Fire damage." 15
generate_skill "staff" "magicians_movement" "Magician's Movement" 3 "Increases All Speed." 20
generate_skill "staff" "wind_strike" "Wind Strike" 0 "Deals Wind Type Damage to the target." 2
generate_skill "staff" "body_to_mind" "Body to Mind" 3 "Converts HP to MP." 0

# Orb Skills
generate_skill "orb" "aura_bolt" "Aura Bolt" 0 "Projects energy to attack target." 2
generate_skill "orb" "heal" "Heal" 2 "Heals target by converting MP to HP." 10
generate_skill "orb" "group_heal" "Group Heal" 2 "Restores HP of allies." 30

# Dagger Skills
generate_skill "dagger" "mortal_blow" "Mortal Blow" 0 "Deals damage, chance to inflict Poison." 2
generate_skill "dagger" "hide" "Hide" 3 "Hides in the shadows." 30
generate_skill "dagger" "shadow_step" "Shadow Step" 3 "Moves behind target, chance to Stun." 50

# Common Skills
generate_skill "common" "teleport" "Teleport" 3 "Randomly teleports user." 10
generate_skill "common" "salvation" "Salvation" 3 "Resurrects with full HP upon death." 0

echo "Generated initial batch of Lineage 2M skills in $OUTPUT_DIR"
