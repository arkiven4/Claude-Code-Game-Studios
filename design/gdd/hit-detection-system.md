# Hit Detection System

> **Status**: Designed
> **Author**: Automated design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: The Party Is the Game (combat feedback)

## Overview

The Hit Detection System is the bridge between physical attacks landing and damage being
dealt. It uses Unity's Physics (PhysX for 3D) collision detection to determine which
attacks hit which targets, then delegates to the Health & Damage System to calculate the
result. It handles four attack shapes: point/single-target (melee swings), line/raycast
(projectiles and cleaves), cone/AoE (breath weapons and frontal area attacks), and
sphere/AoE (explosions and party-wide effects). It is called
by Skill Execution for player skills and by Enemy AI for enemy attacks. The system is
stateless — it receives an attack query, runs the appropriate physics check, and returns
a list of hit targets.

## Player Fantasy

The Hit Detection System serves the fantasy of **precision matters**. The player should
feel that their attacks land with weight and intentionality — a wide cleave hits
everything in front, a projectile travels through space and can miss, a melee swing hits
only what's in range. Misses are possible but rare (reserved for telegraphed enemy
attacks and dodge mechanics), so players trust their inputs. When an attack connects, the
feedback is immediate: hit sparks, damage numbers, and screen shake. The system is
forgiving on hitbox size (generous collision volumes) but strict on attack shape (a cone
really is a cone, not a sphere). This creates combat that feels fair and responsive.

**Reference model**: Devil May Cry's generous melee hitboxes (attacks feel reliable),
combined with Monster Hunter's directional attacks (positioning matters), and Genshin
Impact's elemental skill AoE shapes (cone, line, sphere all feel distinct).

## Detailed Design

### Core Rules

1. **Three Attack Shapes** supported, selected per skill:
   - **Point** — single-target melee or instant hit. Uses a sphere overlap at the
     attack origin point with configurable radius. Returns the single closest target.
   - **Line** — raycast from origin in direction with length and width. Returns all
     targets intersecting the line segment. Used for projectile sweeps, cleaves, and
     beam attacks.
   - **Cone** — frontal cone from origin, defined by angle and length. Returns all
     targets within the cone volume. Used for breath weapons, frontal AoE, and burst
     attacks.
   - **Sphere** — spherical AoE centered at a point. Returns all targets within radius.
     Used for explosions, ground slams, and party-wide heals.

2. **Collision Layers**: The system uses Unity's layer-based collision matrix:
   - `Player` — all playable characters
   - `Enemy` — all enemy entities
   - `Environment` — static obstacles (walls, terrain)
   - `PlayerHitbox` — invisible collision volumes around players (for enemy attacks)
   - `EnemyHitbox` — invisible collision volumes around enemies (for player attacks)

3. **Hit Detection Flow**:
   1. Attacker initiates skill → Skill Execution calls `HitDetection.DetectTargets()`
   2. System reads skill's `AttackShape` (Point/Line/Cone/Sphere) and parameters
   3. System performs the appropriate Unity Physics query:
      - Point: `Physics.OverlapSphere(origin, radius, targetLayer)`
      - Line: `Physics.RaycastAll()` with sphere cast for width
      - Cone: Custom cone overlap (multiple raycasts or mesh overlap)
      - Sphere: `Physics.OverlapSphere(origin, radius, targetLayer)`
   4. System filters results: removes dead targets, removes attackers hitting themselves
   5. System returns `HitResult[]` to Skill Execution
   6. Skill Execution calls `HealthAndDamage.ApplyDamage()` for each hit target

4. **HitResult Structure** returned per target:
   ```csharp
   public struct HitResult {
       public GameObject Target;
       public Vector3 HitPoint;
       public Vector3 HitNormal;    // for impact direction
       public float Distance;       // distance from attacker to target
   }
   ```
   Critical hit determination is NOT done here — it is the sole responsibility of the
   Health & Damage System, which rolls against the attacker's CRIT stat after receiving
   the `HitResult[]` list.

5. **Friendly Fire**: Player attacks cannot hit other players. Enemy attacks cannot hit
   other enemies. Player attacks can only hit enemies. Enemy attacks can only hit players.

6. **Obstacle Blocking**: Line and Cone attacks are blocked by solid Environment colliders.
   If a wall stands between the attacker and the target, the attack does not connect.
   Point attacks (melee) ignore obstacle blocking (melee weapons clip through thin walls).

7. **Hit Cooldown**: The same target cannot be hit by the same attack instance more than
   once. Each attack creates a unique `AttackInstanceId` — if the attack animation has
   multiple hit frames, each frame can register independently.

8. **Projectile Travel Time**: Skills with `ProjectileSpeed > 0` use a moving hitbox that
   travels from origin to target over time. The projectile is destroyed on hitting an
   Environment collider (wall) or the first target in its path. Instant-hit skills
   (`ProjectileSpeed = 0`) register immediately.

9. **Evasion vs Hit Detection**: Evasion is **not** handled here. Evasion (dodge rolls,
   invincibility frames) is handled by the Health & Damage System's invincibility check.
   If a target is hit but is invincible, the hit is recorded as 0 damage.

10. **TargetType → AttackShape Mapping**: Skill Execution passes a `TargetType` from the
    Skill Database to this system. The mapping to an `AttackShape` physics query is:

    | TargetType | AttackShape Used | Notes |
    |------------|-----------------|-------|
    | `SingleEnemy` | Point | Returns the single closest enemy within `PointRadius` |
    | `MultiEnemyLine` | Line | Returns all enemies in a line; `LineLength` is skill-defined |
    | `MultiEnemyCone` | Cone | Returns all enemies within cone; `ConeLength` and `ConeAngle` are skill-defined |
    | `AllEnemies` | Sphere | Returns all enemies within `SphereRadius`; radius set large enough to cover the screen area |
    | `SingleAlly` | Point (ally layer) | Same as Point but queries `PlayerHitbox` layer only; returns nearest ally |
    | `AllAllies` | Sphere (ally layer) | Queries `PlayerHitbox` layer; returns all party members in radius |
    | `Self` | No query | Hit Detection is bypassed entirely; Skill Execution applies the effect directly to the caster |

    When `TargetCount > 1` on a `SingleEnemy` skill (via tier upgrade), Point detection
    returns the N closest enemies rather than just 1.

11. **Hit Confirmation Visuals**: On successful hit, the system triggers:
    - A hit spark VFX at `HitPoint` (pooled, not instantiated per hit)
    - A hit SFX (category-dependent: physical thud, magical crackle, etc.)
    - The damage number spawn (handled by Health & Damage System)
    - A brief hit-stop (0.05s time scale reduction) for impact feel

### States and Transitions

The Hit Detection System is **stateless** — it has no internal states. It is a pure
query system: receive attack parameters, perform physics check, return results.

The only state it tracks is an internal hit registry for the current attack instance
(preventing double-hits from the same attack frame):

```
Attack Start → Register AttackInstanceId
  → Frame 1 Hit → Add target to hit set
  → Frame 2 Hit → Skip if target in hit set
  → ...
Attack End → Unregister AttackInstanceId
```

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Skill Execution** | Called by | Skill Execution calls `DetectTargets()` with skill parameters |
| **Enemy AI** | Called by | Enemy AI calls `DetectTargets()` when enemy attacks |
| **Health & Damage** | Calls this | Health & Damage receives `HitResult[]` and calculates damage |
| **Camera System** | Read by | Camera System reads hit points for camera shake direction |
| **Audio System** | Calls | Triggers hit SFX and impact sounds |
| **VFX System** | Calls | Triggers hit spark VFX at impact point |
| **Combat System** | Read by | Combat System uses hit count for combo tracking |

## Formulas

Hit Detection is physics-based, not formula-driven. Key parameters:

| Parameter | Type | Default | Notes |
|-----------|------|---------|-------|
| `PointRadius` | float | `1.0` | Sphere overlap radius for point attacks |
| `LineLength` | float | Skill-dependent | Distance of line/raycast attacks |
| `LineWidth` | float | `0.5` | Width of line attack (sphere cast radius) |
| `ConeAngle` | float | `60°` | Half-angle of cone attacks |
| `ConeLength` | float | Skill-dependent | Maximum distance of cone |
| `SphereRadius` | float | Skill-dependent | AoE explosion radius |
| `ProjectileSpeed` | float | `0` (instant) | Units per second; 0 = instant hit |
| `HitStopDuration` | float | `0.05s` | Brief time scale reduction on hit |
| `MaxHitsPerAttack` | int | `20` | Safety cap to prevent infinite loops |

## Edge Cases

1. **Target moves out of attack area mid-animation**: The hit is registered at the moment
   the physics query runs. If the target dodges between query frames, the hit misses.
   This is intentional — dodge mechanics work by moving out of the hit volume.

2. **Multiple targets in same position**: All targets are detected and returned. Each
   receives independent damage calculation.

3. **Attacker dies mid-attack**: The attack completes its hit detection, but Skill
   Execution cancels damage application if the attacker is dead before results return.

4. **Projectile hits Environment collider**: The projectile is destroyed, and no target
   is hit. The Environment collider absorbs the attack (wall blocks the shot).

5. **Zero-radius sphere attack**: If SphereRadius is 0, the query returns nothing. This
   is treated as a developer error and logs a warning.

6. **Target destroyed between hit detection and damage application**: Health & Damage
   System handles this gracefully — if the target no longer exists, the damage is silently
   discarded.

7. **Attack origin point inside target collider**: The physics query still returns the
   target (overlap includes the origin point). This can happen in close-quarters melee
   combat and should still register.

8. **Line attack passing through multiple enemies in a row**: All enemies in the line path
   are returned. The attack hits all of them simultaneously.

## Dependencies

- **Depends on**: Unity Physics (PhysX), Unity Physics Layers configuration
- **Depended on by**: Skill Execution, Enemy AI, Health & Damage, Combat System

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `PointRadius` | float | `1.0` | Increase for more forgiving melee hitboxes |
| `ConeAngle` | float | `60°` | Wider = easier to hit groups, harder to dodge |
| `HitStopDuration` | float | `0.05s` | Increase for more impact feel, decrease for faster feel |
| `HitSparkPoolSize` | int | `20` | Number of pooled hit VFX objects |
| `PhysicsLayerMask` | LayerMask | `PlayerHitbox \| EnemyHitbox` | Which layers are checked |

## Visual/Audio Requirements

- **Hit Sparks**: Particle burst at impact point — color varies by damage category
  (Physical=white/orange, Magical=blue, Holy=yellow/white, Dark=purple/black)
- **Impact Decals**: Brief scorch mark at hit point on environment surfaces (fades after 2s)
- **Hit Sound**: Per damage category (see Health & Damage System), volume scaled with
  damage amount
- **Screen Shake**: Brief camera shake proportional to damage amount, direction from hit
  source
- **Projectile Trail**: Visible trail for non-instant attacks (glowing line following
  projectile path)
- **Miss Indicator**: "Miss" text (small, grey) when attack hits but target is invincible

## UI Requirements

- No direct UI components — this system is purely world-space and VFX-driven
- Indirectly supports damage numbers (Health & Damage System UI) and combo counter
  (Combat System UI)

## Acceptance Criteria

- [ ] Point attacks correctly detect single closest target within radius
- [ ] Line attacks detect all targets in a line segment, blocked by Environment colliders
- [ ] Cone attacks detect all targets within cone volume, blocked by Environment colliders
- [ ] Sphere attacks detect all targets within radius
- [ ] Friendly fire is prevented (players can't hit players, enemies can't hit enemies)
- [ ] Projectile attacks travel over time and are blocked by walls
- [ ] Same attack instance cannot hit the same target twice
- [ ] Hit sparks and SFX trigger on every successful hit
- [ ] System returns empty result when no targets are in attack area
- [ ] Performance: 100+ hit detection queries per frame without dropping below 60 FPS

## Open Questions

- Should cone and line attacks have a minimum range (can't hit targets too close to
  the attacker)?
- Should we support homing projectiles that track targets after launch?
- Should environmental hazards (lava, poison pools) use the hit detection system or a
  separate zone trigger?
