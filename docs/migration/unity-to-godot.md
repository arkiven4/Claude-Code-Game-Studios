# Migration Guide: Unity (C#) → Godot 4.6 (GDScript)

**Project**: My Vampire
**Migration date**: 2026-04-05
**From**: Unity 6.3 LTS — C#
**To**: Godot 4.6 — GDScript (statically typed)
**Reference**: Original C# code preserved in `Assets/Scripts/` for reference only.
Do NOT copy C# code directly. Rewrite every system to Godot patterns.

---

## Directory Mapping

| Unity (`Assets/Scripts/`) | Godot (`src/`) |
|--------------------------|----------------|
| `Core/` | `src/core/` |
| `Core/Audio/` | `src/core/audio/` |
| `Gameplay/` | `src/gameplay/` |
| `Gameplay/Loot/` | `src/gameplay/loot/` |
| `AI/` | `src/ai/` |
| `Narrative/` | `src/narrative/` |
| `UI/` | `src/ui/` |
| `Tools/Editor/` | `src/tools/` (Godot editor plugins go in `addons/`) |
| `Assets/Data/` | `assets/data/` (`.tres` Resource files) |
| `Assets/Scenes/` | `assets/scenes/` (`.tscn` PackedScene files) |

---

## System-by-System Migration

### Foundation — Data Resources

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Core/CharacterDataSO.cs` | `src/core/character_data.gd` | `extends Resource`; fields become typed `@export` vars |
| `Core/ItemEquipmentSO.cs` | `src/core/item_equipment.gd` | `extends Resource`; EquipSlot → `enum EquipSlot` |
| `Core/ItemRaritySO.cs` | `src/core/item_rarity.gd` | `extends Resource`; multiplier float per rarity tier |
| `Core/SkillDataSO.cs` | `src/core/skill_data.gd` | `extends Resource`; base skill definition |
| `Core/SkillDamageSO.cs` | Merge into `skill_data.gd` | Subclass or inner data in SkillData |
| `Core/SkillStatusSO.cs` | Merge into `skill_data.gd` | Status-applying skill variant |
| `Core/SkillSupportSO.cs` | Merge into `skill_data.gd` | Support skill variant |
| `Core/SkillUtilitySO.cs` | Merge into `skill_data.gd` | Utility skill variant |
| `Core/StatusEffectSO.cs` | `src/core/status_effect.gd` | `extends Resource`; EffectType → enum |
| `Core/EnemyDataSO.cs` | `src/core/enemy_data.gd` | `extends Resource`; enemy stats + loot table ref |
| `Core/Enums.cs` | Inline enums per file | GDScript enums live inside the class that uses them |

**Pattern:**
```gdscript
# character_data.gd
class_name CharacterData
extends Resource

enum CharacterClass { MAGE, SWORDMAN, HUNTER, TANKER, HEALER, SUPPORT, WITCH }

@export var character_id: String = ""
@export var display_name: String = ""
@export var character_class: CharacterClass = CharacterClass.MAGE
@export var max_hp: float = 100.0
@export var atk: float = 10.0
@export var def: float = 5.0
@export var spd: float = 5.0
@export var max_mp: float = 50.0
@export var crit: float = 0.05
@export var skills: Array[SkillData] = []
```

---

### Foundation — Input & Audio

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Core/InputManager.cs` | `src/core/input_manager.gd` | `extends Node`; wraps Godot InputMap; use `Input.is_action_just_pressed()` |
| `Core/Audio/AudioManager.cs` | `src/core/audio/audio_manager.gd` | `extends Node`; manages bus volumes via `AudioServer` |
| `Core/Audio/MusicPlayer.cs` | `src/core/audio/music_player.gd` | `extends AudioStreamPlayer`; crossfade via tween |
| `Core/Audio/SFXPlayer.cs` | `src/core/audio/sfx_player.gd` | `extends Node`; pool of `AudioStreamPlayer3D` nodes |
| `Core/Audio/AudioPoolManager.cs` | Merge into `sfx_player.gd` | Pool logic lives inside SFXPlayer |
| `Core/Audio/AudioEventChannel.cs` | `src/core/audio/audio_event_channel.gd` | `extends Resource`; signals replace Unity SO events |

**Input pattern:**
```gdscript
# input_manager.gd
class_name InputManager
extends Node

signal skill_pressed(slot: int)
signal switch_next_pressed
signal switch_prev_pressed

func _input(event: InputEvent) -> void:
    if event.is_action_just_pressed("skill_1"):
        skill_pressed.emit(0)
```

---

### Foundation — Save/Load

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Core/SaveManager.cs` | `src/core/save_manager.gd` | `extends Node`; use `FileAccess` + `JSON`; path = `OS.get_user_data_dir()` |
| `Core/ISaveable.cs` | Remove | Replace with duck-typed `save()` / `load()` methods or a `Saveable` base class |

```gdscript
# save_manager.gd
const SAVE_PATH: String = "user://save_data.json"

func save(data: Dictionary) -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data))

func load_save() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    return JSON.parse_string(file.get_as_text())
```

---

### Core — Scene & Chapter

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Core/SceneLoader.cs` | `src/core/scene_loader.gd` | Use `ResourceLoader.load_threaded_request()` + progress callback |
| `Core/SceneLoadingManager.cs` | Merge into `scene_loader.gd` | Single scene management node |
| `Gameplay/ChapterStateManager.cs` | `src/core/chapter_state_manager.gd` | `extends Node`; story flags as `Dictionary` |

---

### Gameplay — Combat Systems

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Gameplay/HealthDamageSystem.cs` | `src/gameplay/health_damage_system.gd` | `extends Node`; attach to character node; formula unchanged |
| `Gameplay/HitboxComponent.cs` | `src/gameplay/hitbox_component.gd` | `extends Area3D`; use `body_entered` signal |
| `Gameplay/HurtboxComponent.cs` | `src/gameplay/hurtbox_component.gd` | `extends Area3D`; receives hits from hitboxes |
| `Gameplay/HitDetectionSystem.cs` | Remove as separate file | Logic split into HitboxComponent + HurtboxComponent |
| `Gameplay/StatusEffectsSystem.cs` | `src/gameplay/status_effects_system.gd` | `extends Node`; apply/tick/expire effects |
| `Gameplay/ActiveEffect.cs` | `src/gameplay/active_effect.gd` | `extends RefCounted`; runtime effect instance |
| `Gameplay/SkillExecutionSystem.cs` | `src/gameplay/skill_execution_system.gd` | `extends Node`; cooldown dict + MP check + hitbox activation |
| `Gameplay/CombatEncounterManager.cs` | `src/gameplay/combat_encounter_manager.gd` | `extends Node`; tracks combatants, win/lose conditions |
| `Gameplay/EnemyAIController.cs` | `src/gameplay/enemy_ai_controller.gd` | `extends CharacterBody3D`; state machine: Idle/Patrol/Alert/Attack/Dead |
| `Gameplay/Projectile.cs` | `src/gameplay/projectile.gd` | `extends CharacterBody3D` or `Area3D` |

**Hitbox pattern:**
```gdscript
# hitbox_component.gd
class_name HitboxComponent
extends Area3D

signal hit_landed(target: Node, damage_data: Dictionary)

var damage_data: Dictionary = {}
var active: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if not active:
        return
    if body.has_node("HurtboxComponent"):
        hit_landed.emit(body, damage_data)
```

---

### Party — Switching & State

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Gameplay/CharacterStateManager.cs` | `src/gameplay/character_state_manager.gd` | `extends Node`; snapshot/restore HP, MP, effects, cooldowns |
| `Gameplay/PartyMemberState.cs` | `src/gameplay/party_member_state.gd` | `extends RefCounted`; plain data struct |
| `Gameplay/CharacterSwitchController.cs` | `src/gameplay/character_switch_controller.gd` | `extends Node`; per ADR-0002; 0.3s window, 1.0s cooldown |
| `Gameplay/EquipmentManager.cs` | `src/gameplay/equipment_manager.gd` | `extends Node`; 5 slots; apply/remove stat modifiers |
| `Gameplay/PlayerMovementController.cs` | `src/gameplay/player_movement_controller.gd` | `extends CharacterBody3D`; WASD + `move_and_slide()` |

---

### Party — AI

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `AI/IPartyAgent.cs` | `src/ai/party_agent.gd` | GDScript has no interfaces — use base class with `@warning_ignore("unused_signal")` virtual methods |
| `AI/BTPartyAgent.cs` | `src/ai/bt_party_agent.gd` | `extends PartyAgent`; BT fallback with noise+delay expertise model |
| `AI/RLPartyAgent.cs` | `src/ai/rl_party_agent.gd` | `extends PartyAgent`; wraps Godot RL Agents addon (replaces Unity ML-Agents) |
| `Tools/TrainingOrchestrator.cs` | `src/tools/training_orchestrator.gd` | Godot RL Agents has its own training loop — review addon docs |

**Interface → base class pattern:**
```gdscript
# party_agent.gd
class_name PartyAgent
extends Node

var expertise: float = 0.5

# Override in subclasses
func choose_action(state: Dictionary) -> String:
    return ""

func set_expertise(value: float) -> void:
    expertise = clamp(value, 0.0, 1.0)
```

---

### Loot & Economy

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Gameplay/Loot/LootDropper.cs` | `src/gameplay/loot/loot_dropper.gd` | `extends Node`; rolls loot table on enemy death signal |
| `Gameplay/Loot/LootTableSO.cs` | `src/gameplay/loot/loot_table.gd` | `extends Resource`; array of LootEntry inner class |
| `Gameplay/Loot/LootPickupComponent.cs` | `src/gameplay/loot/loot_pickup.gd` | `extends Area3D`; `body_entered` → collect |
| `Gameplay/Loot/PartyInventory.cs` | `src/gameplay/loot/party_inventory.gd` | `extends Resource` (shared); flat array of ItemEquipment refs |

---

### Narrative

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `Narrative/DialogueNodeSO.cs` | `src/narrative/dialogue_node.gd` | `extends Resource`; speaker, text, choices, next node ref |
| `Narrative/DialogueGraphSO.cs` | `src/narrative/dialogue_graph.gd` | `extends Resource`; Dictionary of nodes by ID |
| `Narrative/DialogueManager.cs` | `src/narrative/dialogue_manager.gd` | `extends Node`; walks the graph, emits signals for UI |

---

### UI

| C# File | GDScript File | Notes |
|---------|---------------|-------|
| `UI/CombatHUD.cs` | `src/ui/combat_hud.gd` | `extends CanvasLayer`; Control nodes for HP/MP bars, skill icons |
| `UI/WorldSpaceHPBar.cs` | `src/ui/world_hp_bar.gd` | `extends Node3D` with `SubViewport` or `Billboard` Label3D |

---

### Camera

| Unity Pattern | Godot Pattern |
|--------------|---------------|
| Cinemachine Virtual Camera | `Camera3D` + `SpringArm3D` for third-person |
| Cinemachine blend | `Tween` on camera properties or **Phantom Camera** addon |
| Combat / Exploration mode switch | Signal-driven `CameraController` node swapping active camera |

---

## Audio Bus Mapping

| Unity Mixer Group | Godot Audio Bus |
|------------------|----------------|
| Master | Master |
| Music | Music |
| SFX | SFX |
| UI | UI |
| Ambience | Ambience |

Configure in `Project → Audio Buses`. Use `AudioServer.set_bus_volume_db()` for volume control.

---

## Input Action Mapping

Re-create all Unity Input Actions in `Project → Input Map`:

| Unity Action | Godot Action Name |
|-------------|-------------------|
| Move (Vector2) | `move_up`, `move_down`, `move_left`, `move_right` |
| Skill1–4 | `skill_1`, `skill_2`, `skill_3`, `skill_4` |
| SwitchNext / SwitchPrev | `switch_next`, `switch_prev` |
| Dodge | `dodge` |
| BasicAttack | `basic_attack` |
| TargetLock | `target_lock` |
| Pause | `pause` |
| Interact | `interact` |

---

## Migration Order (follow dependency layers)

1. **Data Resources** — CharacterData, ItemEquipment, SkillData, StatusEffect, EnemyData
2. **Foundation** — InputManager, AudioManager, SaveManager
3. **Core** — HealthDamageSystem, HitboxComponent, HurtboxComponent, ChapterStateManager, SceneLoader
4. **Gameplay** — StatusEffectsSystem, SkillExecutionSystem, EnemyAIController
5. **Combat** — CombatEncounterManager, CharacterStateManager, CharacterSwitchController, EquipmentManager, LootDropper
6. **Party AI** — PartyAgent, BTPartyAgent, RLPartyAgent
7. **Narrative** — DialogueNode, DialogueGraph, DialogueManager
8. **UI** — CombatHUD, WorldHPBar
9. **Camera** — CameraController with Phantom Camera
10. **Test Scene** — TestArena.tscn equivalent
11. **Tests** — GUT test suite

---

## Data Assets to Re-create as `.tres`

Recreate all `.asset` files from `Assets/Data/` as Godot Resources:

- `Characters/` → 3 `CharacterData.tres` (Evelyn, Evan, Witch)
- `Skills/` → 12 `SkillData.tres` (Evelyn ×4, Evan ×4, Witch ×4)
- `Items/` → 5 `ItemEquipment.tres`
- `Enemies/` → 2 `EnemyData.tres` (GruntMelee, ArcherRanged)

Original `.asset` files are in `Assets/Data/` — use them as field-value reference only.

---

## What NOT to Migrate

- `Assets/Scripts/Tools/Editor/` Unity Editor tools → replace with Godot editor plugins if needed
- `ProjectSettings/` → gone (set up fresh in Godot)
- `Packages/manifest.json` → gone (use Godot Asset Library / addons)
- ML-Agents package → replace with **Godot RL Agents** addon
- Cinemachine → replace with **Phantom Camera** addon
- Unity URP shaders → rewrite in Godot Shader Language
