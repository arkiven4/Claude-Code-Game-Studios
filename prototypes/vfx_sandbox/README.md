# VFX Sandbox

A dedicated testing framework for trying out visual effects for Projectiles, Slashes, and Hit Impacts.

## How to Use

1.  Open `prototypes/vfx_sandbox/VFXSandbox.tscn` in the Godot Editor.
2.  Select the **VFXSandbox** root node in the Scene tree.
3.  In the **Inspector**, you will see three texture slots:
    -   **VFX Projectile Tex**: The texture for the flying projectile.
    -   **VFX Impact Tex**: The texture for the hit explosion/spark.
    -   **VFX Slash Tex**: The texture for the slash/sweep effect.
4.  Assign your `.png` or `.tres` textures to these slots.
5.  Run the scene (F6).
6.  Use the on-screen buttons to spawn effects:
    -   **Spawn Projectile**: Fires a projectile from the left marker to the target dummy.
    -   **Spawn Slash**: Shows the slash effect at the target dummy's position.
    -   **Spawn Hit Impact**: Shows the impact effect at the target dummy's position.

## Technical Details

- **Projectiles**: Uses `CombatVFX.spawn_projectile` and `assets/scenes/Projectile.tscn`. It simulates a `SkillData` resource to pass parameters.
- **Slashes/Impacts**: Uses `CombatSkillExecutor.spawn_hit_vfx` which creates a billboarded `MeshInstance3D` quad that expands and fades out via Tween.
- **Collision**: The Target Dummy has a `HurtboxComponent` on Layer 8 (Enemy). The projectile is configured to hit Layer 8.

## Customization

You can modify `VFXSandbox.gd` to change:
- `projectile_speed`
- `cast_center` and `spawn_pos`
- Spawn delays or multiple simultaneous spawns.
