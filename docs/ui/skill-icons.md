# Skill Slot Icons — Implementation Note

## Current State

Skill slots (`src/ui/skill_slot_ui.gd`) use a solid colored `ColorRect` as a
placeholder background. The four slots are color-coded by index (purple, blue,
amber, green) so they are visually distinct during development.

## Adding Real Icons

When skill icon textures are ready:

1. **Assign the icon in each `.tres` skill file**  
   Each `SkillData` resource has an `icon: Texture2D` field. Set it in the
   Godot Inspector (or directly in the `.tres` file).

2. **Add a `TextureRect` inside `SkillSlotUI._ready()`**

   ```gdscript
   # In skill_slot_ui.gd — add after _bg is created
   _icon = TextureRect.new()
   _icon.position = Vector2(8, 8)          # small inset
   _icon.size = Vector2(48, 48)
   _icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   add_child(_icon)
   ```

3. **Set the texture in `set_skill()`**

   ```gdscript
   func set_skill(skill: SkillData) -> void:
       if skill and skill.icon:
           _icon.texture = skill.icon
           _icon.visible = true
       else:
           _icon.visible = false
   ```

   The cooldown overlay and key label are added after `_icon` in `_ready()`, so
   they already draw on top of it — no z-order changes needed.

## File Locations

| Asset | Suggested path |
|-------|----------------|
| Skill icons (PNG/SVG) | `assets/art/ui/skills/` |
| SkillData resources | `assets/data/skills/` |
| SkillSlotUI script | `src/ui/skill_slot_ui.gd` |
