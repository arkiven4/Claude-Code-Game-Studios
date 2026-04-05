# Save / Load System

> **Status**: In Design
> **Author**: Design session 2026-04-04
> **Last Updated**: 2026-04-04
> **Implements Pillar**: Story First (narrative persistence)

## Overview

The Save / Load System is the persistence backbone of the game — responsible for
serializing all game state to disk and restoring it on demand. Using binary
serialization, it captures the complete state of every active system: party composition
and character levels (Character Data), equipped items and their enhancement/durability
state (EquipmentInstance), skill cooldowns and active buffs (SkillRuntimeState), chapter
progression and story flags, inventory contents, current scene state, and player settings.
Players can only save **outside of combat** — at village hubs, between encounters, or at
designated save points during chapter transitions. This prevents save-scumming before
puzzles or difficult encounters. Auto-save triggers at chapter transitions and key story
beats. Load is available from the pause menu and returns the player to the exact moment
they saved. The system is designed to be invisible — saves happen automatically at
narrative beats, and loading is fast enough to feel instantaneous. No system in the game
can persist data without going through the Save / Load System's serialization interface.

## Player Fantasy

Save / Load System serves the fantasy of **a journey that never forgets**. The player
should never worry about losing progress — auto-save at chapter transitions, key story
beats, and between encounters creates a safety net that lets them focus on the narrative
and characters, not on managing save files. When they load a save, they return to the
exact moment they left off: same party state, same equipment, same story flags. No
discrepancies. No "I lost my progress." The system is invisible infrastructure — players
only notice it if it fails. But the *knowledge* that their journey is safe frees them to
invest emotionally in the story. They don't hold back from caring about Evelyn because
they're afraid of losing progress. The save system says: "Keep playing. I've got you."

**Reference model**: Modern RPGs like Final Fantasy VII Remake and Nier: Automata —
auto-save is so reliable that players rarely think about manual saves, and loading
returns them to the exact narrative moment with zero state corruption.

## Detailed Design

### Core Rules

1. **Two save files exist** on disk:
   - `manual_save.bin` — the player's single manual save slot (overwritten each time they save)
   - `auto_save.bin` — the auto-save file (overwritten automatically at designated triggers)

2. **Save is only permitted outside of combat**. The system checks `CombatSystem.IsInCombat` before allowing a save. If in combat, save is blocked and a tooltip appears: "Cannot save during combat."

3. **Auto-save triggers** (automatic, no player input required):
   - Chapter transition completion (after cutscene ends)
   - Key story beat completion (major cutscene or dialogue sequence ends)
   - Entering a village/hub area (safe zone entry)
   - After defeating a boss or mini-boss

4. **Manual save** is triggered from the pause menu. The player selects "Save Game" — the system immediately writes `manual_save.bin` without confirmation (no slot selection needed).

5. **Load** is triggered from the pause menu. The player selects "Load Game" — the system presents a choice between the manual save and auto-save. Selecting either immediately loads that file.

6. **Serialized state** — every save file contains a `SaveData` binary structure with these sections:

   | Section | Data Serialized | Source System |
   |---------|----------------|---------------|
   | `SaveMetadata` | Save timestamp, play time (seconds), chapter number, save type (manual/auto) | Save / Load System |
   | `PartyState` | Active party member IDs, character levels, XP values, IsMainCharacter flags | Character Data / Character Progression |
   | `PartyMemberState[]` | Per-member: CurrentHP, CurrentMP, SkillCooldowns[], ActiveBuffs[], CharacterClass | Character Data |
   | `EquipmentInstance[]` | Per-equipped item: ItemGUID, IsEquipped, EnhancementLevel, Durability, EquippedOnCharacterID | Item Database |
   | `InventoryState` | Inventory items list (ItemGUID + quantity per item), gold amount | Inventory & Equipment System |
   | `SkillRuntimeState[]` | Per-skill-per-character: CurrentCooldown, ChargeCount, ActiveInstances[] (type, duration, target, effect value) | Skill Database |
   | `ChapterState` | Current chapter number, completed chapter flags, story flags (bitmask), visited locations | Chapter State System |
   | `SceneState` | Current scene name, player position/rotation, enemy states (alive/dead, HP), opened chests/interactables | Scene Management System |
   | `PlayerSettings` | Volume levels (master, music, SFX), input sensitivity, display settings | Settings System |

7. **Save file versioning** — every save file includes a `SaveFileVersion` (int). If the save file version doesn't match the current game version, the load is rejected with a message: "This save file is incompatible with the current game version."

8. **Save file integrity** — every save file includes a CRC32 checksum appended to the binary data. On load, the checksum is verified. If it doesn't match, the save is rejected with: "Save file is corrupted and cannot be loaded."

9. **No system may serialize state independently**. All save/load operations must go through the Save / Load System's `ISaveable` interface:
   ```csharp
   public interface ISaveable {
       string SaveKey { get; } // Unique identifier for this system's data in the save file
       byte[] Serialize();     // Convert state to binary
       void Deserialize(byte[] data); // Restore state from binary
   }
   ```

10. **Save operations are synchronous writes** to disk. The game pauses during save (1-2 seconds max). A "Saving..." overlay is displayed.

11. **Load operations require a scene reload**. The system destroys the current scene, loads the target scene by name from the save data, then restores all serialized state in this order:
    1. PlayerSettings (so UI is correct before anything else displays)
    2. SceneState (loads the correct scene and positions)
    3. PartyState + PartyMemberState (creates party members)
    4. EquipmentInstance[] (equips items on party members)
    5. SkillRuntimeState[] (restores cooldowns and buffs)
    6. InventoryState (restores inventory contents and gold)
    7. ChapterState (restores story flags and chapter progress)

12. **New Game** bypasses save loading entirely — it initializes all systems to their default starting state (Evelyn at Level 1, prologue scene, empty inventory, Chapter 0).

### States and Transitions

The Save / Load System has four internal states:

```
┌─────────────┐
│   IDLE      │ ◄── Default state, no save/load in progress
└──────┬──────┘
       │ Player requests save
       ▼
┌─────────────┐
│   SAVING    │ ◄── Collecting ISaveable data, serializing, writing to disk
└──────┬──────┘
       │ Write complete + checksum verified
       ▼
┌─────────────┐
│   IDLE      │
└──────┬──────┘
       │ Player requests load
       ▼
┌─────────────┐
│  LOADING    │ ◄── Reading file, verifying checksum, deserializing,
│             │     destroying current scene, restoring state in order
└──────┬──────┘
       │ State restoration complete
       ▼
┌─────────────┐
│   IDLE      │
└─────────────┘
```

**Transitions**:
- `IDLE → SAVING`: Triggered by manual save (pause menu) or auto-save trigger event
- `SAVING → IDLE`: Save write completed successfully
- `SAVING → IDLE (error)`: Save write failed — rollback temporary file, display error
- `IDLE → LOADING`: Triggered by load selection from pause menu
- `LOADING → IDLE`: Scene loaded, all state restored successfully
- `LOADING → IDLE (error)`: Load failed (corrupt file, missing scene) — return to main
  menu with error message

**Save Blocking Conditions** (system returns `false` for `CanSave()`):
- `CombatSystem.IsInCombat == true`
- `CutsceneSystem.IsPlaying == true`
- `NarrativeChoiceSystem.IsPresentingIrreversibleChoice == true`
- `PuzzleSystem.IsPuzzleActive == true`  *(forward reference — add to systems index when Puzzle System is designed)*
- `SaveSystem.CurrentState != IDLE`

### Interactions with Other Systems

| System | Interaction Type | Details |
|--------|-----------------|---------|
| **Character Data** | Read on save, write on load | Save reads party member configs; load reconstructs `PartyMemberState` from CharacterDataSO references |
| **Item Database** | Read on save, write on load | Save reads item definitions; load reconstructs `EquipmentInstance` from ItemEquipmentSO references |
| **Skill Database** | Read on save, write on load | Save reads skill configs; load reconstructs `SkillRuntimeState` from SkillDataSO references |
| **Inventory & Equipment** | `ISaveable` provider | Implements `ISaveable` to serialize inventory contents, equipped items, and gold |
| **Character Progression** | `ISaveable` provider | Implements `ISaveable` to serialize character levels, XP, and stat growth state |
| **Health & Damage** | `ISaveable` provider | Implements `ISaveable` to serialize current HP/MP per character (not the formula, just the values) |
| **Status Effects** | `ISaveable` provider | Implements `ISaveable` to serialize active buffs/debuffs (type, duration, remaining turns) |
| **Chapter State** | `ISaveable` provider | Implements `ISaveable` to serialize current chapter, story flags, visited locations |
| **Scene Management** | Coordinate with load | Scene Management destroys current scene and loads the target scene before state restoration begins |
| **Combat System** | Blocking gate | Save System queries `IsInCombat` to block saves during encounters |
| **Cutscene System** | Blocking gate | Save System queries `IsPlaying` to block saves during cutscenes |
| **Narrative Choice** | Blocking gate | Save System queries `IsPresentingIrreversibleChoice` to block saves before critical choices |
| **Settings System** | `ISaveable` provider | Implements `ISaveable` to serialize player preferences (audio, display, input) |
| **Dialogue System** | Read on load | After load, Dialogue System checks ChapterState to determine which dialogue branches are unlocked |

## Formulas

Save / Load System is infrastructure — it has no gameplay formulas. Instead, it defines
sizing and performance constraints:

| Formula | Description | Value |
|---------|-------------|-------|
| `SaveFileSize` | Estimated save file size | `~8 KB` for a typical mid-game save (4 party members, 50 inventory items, 20 story flags, 10 active skills) |
| `SaveDuration` | Time to write save to disk | `< 200ms` (synchronous, must not block frame) |
| `LoadDuration` | Time from load trigger to gameplay resumption | `< 3 seconds` (scene load + state restoration) |
| `MaxSaveFiles` | Number of save files on disk | `2` (1 manual + 1 auto-save) |
| `SaveDirectory` | Platform-specific save path | `Application.persistentDataPath / "saves/"` |
| `CRC32Check` | Integrity verification | `CRC32.Compute(data) == storedChecksum` |
| `SaveVersionCheck` | Compatibility check | `readVersion == currentSaveVersion` |

## Edge Cases

1. **Save file deleted externally**: Player deletes `manual_save.bin` via file manager. On
   load attempt, the system detects the missing file and falls back to auto-save. If
   auto-save also doesn't exist, it behaves as a new game.

2. **Save during power loss**: If the game crashes mid-save, the atomic write pattern
   (write to temp file, then rename) ensures the original save file is never partially
   corrupted. The temp file may be orphaned but the save slot is intact.

3. **Game version update changes save schema**: When a code change adds a new field to
   `SaveData`, the save version number increments. On load, if the save version is older,
   a migration routine fills default values for missing fields. If the save version is
   newer (player downgraded game), the load is rejected with an incompatibility message.

4. **Missing scene on load**: Player saves in a scene that was removed from the build.
   On load, the system detects the missing scene and returns to the main menu with a
   message: "The saved location is no longer available. Starting from the beginning of
   the current chapter."

5. **Corrupted EquipmentInstance reference**: A saved item GUID no longer exists in the
   Item Database (item was removed in a patch). On load, the system skips the missing
   item and logs a warning. Equipped slots become empty.

6. **Corrupted skill cooldown reference**: A saved skill is no longer assigned to a
   character. On load, the system skips restoring that cooldown. The character's
   cooldown resets to default.

7. **Negative gold on load**: Due to a bug, a save file has negative gold. On load, the
   system clamps gold to 0 and logs a warning.

8. **Save file from a different playthrough**: Player copies a save file from another
   player's game. The save loads normally — there is no DRM or account binding. Save
   files are portable.

9. **Disk full during save**: Write fails partway through. The atomic write pattern
   leaves the original file intact and reports: "Not enough storage space to save your
   game."

10. **Loading into a combat that was just ending**: If the saved state shows the last
    enemy dead but combat state hasn't cleared, the system forces `IsInCombat = false`
    and allows the player to proceed normally.

## Dependencies

The Save / Load System is a **foundation root** — it has no upstream dependencies on
other gameplay systems. It defines the `ISaveable` interface that all other systems
implement.

**Depended on by** (directly or indirectly):
- **Chapter State System** — relies on Save/Load to persist story flags
- **Scene Management System** — relies on Save/Load to know which scene to load and
  what state to restore
- **Inventory UI** — reads save metadata to display "Continue" info (chapter, playtime)
  on the main menu
- **Main Menu** — reads save metadata to populate the "Continue" button

**No dependency direction conflicts.**

## Tuning Knobs

| Knob | Type | Default | Notes |
|------|------|---------|-------|
| `AutoSaveFrequency` | Enum | `Chapter + Boss + Hub` | Could be changed to `Chapter only` or `Chapter + Hub` if saves are too frequent |
| `SaveCompression` | bool | `false` | Can enable gzip compression if save files grow beyond 50 KB |
| `ShowSavingIndicator` | bool | `true` | Can disable for speedrunners who want instant save |

## Visual/Audio Requirements

- **Visual**: A brief "Saving..." overlay (translucent background, rotating icon, 0.5–1.5s
  duration)
- **Visual**: On load, a fade-to-black transition (0.3s) while the scene reloads
- **Audio**: A short, subtle save confirmation sound (soft chime, 200ms, low priority in
  mixer)
- **Audio**: On load failure, a distinct error sound (short, non-startling)

## UI Requirements

- **Pause Menu**: "Save Game" button (disabled during combat, puzzles, and irreversible
  choices with tooltip explanation)
- **Pause Menu**: "Load Game" button — opens a dialog showing manual save and auto-save
  with metadata (chapter name, playtime, timestamp)
- **Main Menu**: "Continue" button — appears when any save file exists, loads the most
  recent save directly
- **Save Overlay**: "Saving..." indicator with progress spinner (displays during write
  operation)
- **Load Error Dialog**: "Save file corrupted" or "Save file incompatible" with OK button
  and option to return to main menu

## Acceptance Criteria

- [ ] Manual save completes in < 200ms with "Saving..." overlay visible
- [ ] Auto-save triggers at chapter transitions, boss defeats, and hub entries
- [ ] Save is blocked during combat, cutscenes, puzzles, and irreversible narrative choices
- [ ] Load restores all state: party, HP/MP, cooldowns, buffs, inventory, gold, scene
  position, story flags
- [ ] Loading a save produces identical gameplay state to the moment of save (no stat
  drift, no missing items)
- [ ] Corrupted save file is detected via CRC32 and rejected with a clear error message
- [ ] Incompatible save version is rejected with a clear error message
- [ ] Auto-save and manual save coexist — system loads the more recent one
- [ ] Deleting both save files results in "New Game" behavior
- [ ] Save file size stays under 50 KB even with maximum party, inventory, and story flag
  counts

## Open Questions

- ~~Should we support save file migration when the save format version changes?~~ **Resolved** —
  Edge Case 3 documents the migration routine: newer game versions fill missing fields with
  defaults; older game versions reject newer save files with a clear error message.
- Should save files be encrypted to prevent players from editing them externally?
