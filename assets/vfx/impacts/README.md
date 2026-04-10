# Impact VFX System

Layered hit/impact visual effects based on the tutorial:
**"GODOT VFX - Hits and Impacts Effect Tutorial"**

---

## Overview

This system creates dynamic impact effects by layering **4 particle systems**,
each contributing a different visual element:

| Layer | Purpose | Lifetime | Particles |
|-------|---------|----------|-----------|
| **Flash** | Quick bright burst | 0.1s | 1 |
| **Flare** | Cross-shaped glow | 0.2s | 1 |
| **Shockwave** | Expanding ring | 0.4s | 1 |
| **Sparks** | Velocity-aligned sparks | 0.5s | 20 |

---

## File Structure

```
assets/vfx/impacts/
├── materials/
│   ├── flash_flare_shader.gdshader      # Procedural soft circle/flare
│   ├── flash_flare_material.tres        # Material instance
│   ├── cross_flare_shader.gdshader      # Procedural cross/plus shape
│   ├── cross_flare_material.tres        # Material instance
│   ├── shockwave_ring_shader.gdshader   # Procedural ring/donut
│   └── shockwave_ring_material.tres     # Material instance
├── scenes/
│   ├── impact_flash.tscn                # Flash layer (single particle)
│   ├── impact_flare.tscn                # Flare layer (cross shape)
│   ├── impact_shockwave.tscn            # Shockwave layer (ring)
│   ├── impact_sparks.tscn               # Sparks layer (20 particles)
│   └── impact_vfx_master.tscn           # Combined 4-layer effect
├── scripts/
│   ├── impact_vfx_controller.gd         # Per-instance VFX controller
│   └── impact_vfx_manager.gd            # Global spawn manager (singleton)
└── README.md                            # This file
```

---

## Quick Start

### 1. Register the VFX Manager as Autoload

In Godot Editor:
1. Go to **Project → Project Settings → Autoload**
2. Add: `res://assets/vfx/impacts/scripts/impact_vfx_manager.gd`
3. Node name: `ImpactVFXManager`
4. Enable: ✓

### 2. Spawn an Impact Effect

```gdscript
# Basic usage
ImpactVFXManager.spawn_impact(hit_position)

# With color tint
ImpactVFXManager.spawn_impact(hit_position, Color.ORANGE)

# With preset
ImpactVFXManager.spawn_impact_preset(hit_position, "fire")
ImpactVFXManager.spawn_impact_preset(hit_position, "ice")
ImpactVFXManager.spawn_impact_preset(hit_position, "lightning")
```

### 3. Use in Combat/Hit Detection

```gdscript
func _on_enemy_hit(hit_position: Vector3, damage: float) -> void:
    # Spawn impact VFX at hit location
    ImpactVFXManager.spawn_impact(hit_position, Color(1.0, 0.5, 0.2))
    
    # Play sound, apply damage, etc.
    audio_player.play_hit_sound()
    enemy.take_damage(damage)
```

---

## Procedural Shaders

### Flash/Flare Shader (`flash_flare_shader.gdshader`)

Creates a soft circular glow with smooth falloff. Based on the tutorial's
Material Maker circle node with smoothness ~0.95.

**Key parameters:**
- `modulate`: Color tint (default: white)
- `smoothstep`: Controls edge softness
- `blend_add`: Additive blending for brightness

### Cross Flare Shader (`cross_flare_shader.gdshader`)

Creates two perpendicular lines intersecting with center glow. Replicates the
tutorial's Material Maker math node setup (horizontal + vertical lines).

**Key parameters:**
- `modulate`: Color tint (default: orange)
- `center_glow`: Exponential falloff from center
- Lines are 5% thickness of the texture

### Shockwave Ring Shader (`shockwave_ring_shader.gdshader`)

Creates a ring/donut shape by subtracting two circles. Replicates the tutorial's
"subtract A from B" math node technique.

**Key parameters:**
- `modulate`: Color tint (default: warm yellow, low alpha)
- `outer_radius`: 0.9
- `inner_radius`: 0.6
- `edge_glow`: Additional brightness on ring edges

### Spark Shader (`spark_shader.gdshader`)

Creates a small bright dot with soft outer glow. Used for individual spark
particles that are velocity-aligned and stretched.

**Key parameters:**
- `modulate`: Color tint (default: orange-red)
- `core`: Bright center (exp(-dist * 10))
- `glow`: Soft outer falloff (exp(-dist * 4) * 0.5)

---

## Layer Configuration

Each layer can be individually enabled/disabled and configured via the
`ImpactVFXController` exports:

```gdscript
# In Godot Editor inspector (when impact_vfx_master.tscn is selected):
Layer Configuration:
  ├─ Enable Flash: true/false
  ├─ Enable Flare: true/false
  ├─ Enable Shockwave: true/false
  └─ Enable Sparks: true/false

Color Settings:
  ├─ Tint Color: WHITE (global tint)
  ├─ Flash Color: RGB(1.0, 0.6, 0.2)
  ├─ Flare Color: RGB(1.0, 0.6, 0.1)
  ├─ Shockwave Color: RGB(1.0, 0.8, 0.3)
  └─ Sparks Color: RGB(1.0, 0.3, 0.2)

Scale Settings:
  ├─ Global Scale: 1.0
  ├─ Flash Scale: 1.0
  ├─ Flare Scale: 1.0
  ├─ Shockwave Scale: 1.0
  └─ Sparks Scale: 1.0
```

---

## Customization Guide

### Change Effect Colors

**Option 1: Via Inspector**
1. Open `impact_vfx_master.tscn`
2. Select root node `ImpactVFX`
3. Modify colors in the inspector under "Color Settings"

**Option 2: Via Code**
```gdscript
var vfx = ImpactVFXManager.spawn_impact(position, Color.CYAN)
```

**Option 3: Modify Shader Defaults**
Edit the shader files directly:
```glsl
uniform vec4 modulate : hint_color = vec4(0.2, 0.8, 1.0, 1.0);  // Blue
```

### Adjust Effect Scale

**Global scale:**
```gdscript
vfx.global_scale = 2.0  # 2x larger
```

**Per-layer scale:**
```gdscript
vfx.flash_scale = 1.5   # Flash only
vfx.sparks_scale = 0.5  # Smaller sparks
```

### Change Particle Lifetime

Edit the `.tscn` files:
```
# In impact_flash.tscn
lifetime = 0.1  # Change to 0.2 for longer flash

# In impact_sparks.tscn
lifetime = 0.5  # Change to 1.0 for longer-lasting sparks
```

### Add New Layers

1. Create a new particle scene in `scenes/`
2. Add it to `impact_vfx_master.tscn` as a child node
3. Update `impact_vfx_controller.gd`:
   - Add `@onready var new_layer: Node3D = $NewLayer`
   - Update `_configure_layer()` and `_emit_particles()`

---

## Tutorial Reference

This implementation is based on the YouTube tutorial:
**"GODOT VFX - Hits and Impacts Effect Tutorial"**

### Tutorial Techniques Implemented

| Technique | Implementation |
|-----------|----------------|
| **One Shot mode** | All layers use `one_shot = true` for burst effects |
| **Billboard particles** | Flash/flare use `Particle Billboard` for camera-facing |
| **Velocity alignment** | Sparks use `flags_align_y = true` to align with velocity |
| **Scale/Alpha curves** | Each layer has custom curves for fade-out behavior |
| **Procedural textures** | All textures are shader-based (no external images) |
| **Layered composition** | 4 independent layers combined into single effect |

### Tutorial Workflow Summary

1. Create `Node3D` as VFX container
2. Add `GPUParticles3D` for each layer
3. Create `ParticleProcessMaterial` with:
   - Amount (particle count)
   - Lifetime
   - Scale curve
   - Color ramp
4. Create `StandardMaterial3D` with:
   - Billboard enabled (for camera-facing)
   - Additive blending
   - Unshaded rendering
5. Assign procedural texture (shader material)
6. Configure **One Shot** mode for burst effects
7. Test with **Emitting** toggle

---

## Performance Notes

| Metric | Value |
|--------|-------|
| **Total particles per impact** | 23 |
| **Max lifetime** | 0.5s (sparks layer) |
| **Draw calls per impact** | 4 (one per layer) |
| **Memory per instance** | ~50KB |
| **Auto-cleanup** | ✓ (queue_free on completion) |

### Optimization Tips

- **Pool instances** if spawning frequently (>10/sec)
- **Reduce particle count** for mobile: sparks from 20 → 10
- **Disable layers** you don't need (e.g., turn off shockwave for small hits)
- **Use LOD** for distant impacts (smaller scale, fewer particles)

---

## Presets

The VFX manager includes built-in presets for quick theming:

| Preset | Color | Use Case |
|--------|-------|----------|
| `default` | White | Generic impacts, neutral |
| `fire` | Orange-red (1.0, 0.4, 0.1) | Fire attacks, explosions |
| `ice` | Cyan-blue (0.3, 0.7, 1.0) | Ice attacks, frost |
| `lightning` | Pale blue (0.8, 0.9, 1.0) | Electric attacks, lightning |

### Adding Custom Presets

Edit `_get_preset_config()` in `impact_vfx_manager.gd`:

```gdscript
"shadow":
    return {
        "color": Color(0.3, 0.2, 0.4),
        "basis": Basis.IDENTITY
    }
```

---

## API Reference

### ImpactVFXManager (Singleton)

| Method | Description |
|--------|-------------|
| `spawn_impact(position, color, basis)` | Spawn impact at position with optional tint |
| `spawn_impact_preset(position, preset)` | Spawn with named preset configuration |
| `get_active_vfx() -> Array[Node3D]` | Get all currently active VFX instances |
| `clear_all_vfx()` | Remove all active VFX immediately |
| `get_active_count() -> int` | Get number of active VFX instances |

### ImpactVFXController (Per-instance)

| Method | Description |
|--------|-------------|
| `play(position, color)` | Play the VFX at position with color |
| `stop()` | Stop VFX playback immediately |
| `is_playing() -> bool` | Check if VFX is currently playing |

| Signal | Description |
|--------|-------------|
| `vfx_completed` | Emitted when all layers have finished playing |

---

## Troubleshooting

### Particles not showing?
- Check that the VFX manager is registered as an autoload
- Verify particle `emitting` property is true
- Check layer visibility (enable_* flags)
- Ensure camera is in range of the spawn position

### Particles not facing camera?
- Verify `params_billboard_flag = true` in material
- Check that shader has `cull_disabled` render mode

### Colors look wrong?
- Check `modulate` color in shader uniforms
- Verify `blend_add` is enabled for additive blending
- Test with white color to isolate tinting issues

### Performance issues?
- Reduce particle count in spark layer
- Disable unnecessary layers
- Check active VFX count with `get_active_count()`

---

## Future Enhancements

- [ ] Object pooling for high-frequency spawning
- [ ] Sound effect integration (sync with particle playback)
- [ ] Directional sparks (align with attack direction)
- [ ] Screen shake integration
- [ ] Hitstop/time freeze hook
- [ ] Decal spawning at impact point
- [ ] Elemental variant shaders (fire, ice, lightning)
- [ ] LOD system for distance-based quality

---

## Credits

- **Tutorial**: "GODOT VFX - Hits and Impacts Effect Tutorial" (YouTube)
- **Implementation**: Qwen Code VFX Agent
- **Date**: April 11, 2026
- **Engine**: Godot 4.x

---

## License

Same as project license. See `LICENSE` in project root.
