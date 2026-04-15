# Level Generation System (Procedural)

> **Status**: Approved
> **Author**: Gemini CLI
> **Last Updated**: 2026-04-14
> **Implements Pillar**: Scale for Solo Dev (Automated content)

## Overview

The Level Generation System allows for the creation of 70+ unique maps for 12 chapters 
without requiring manual layout design for every stage. It uses a "Modular Stitching" 
algorithm that connects hand-crafted **Level Segments** based on **Biome Data**. 
By varying the `level_seed`, the system can produce different layouts for the same chapter theme.

## Player Fantasy

The player experiences a **vast and unpredictable world**. While the theme of a chapter 
(e.g., "The Whispering Woods") remains consistent, the specific path through the woods 
changes, rewarding exploration and preventing repetitive "memory-based" speedrunning.

## Detailed Rules

1. **Biome-Driven**: Each chapter is assigned a `BiomeData` resource containing:
   - A pool of modular segments (Room, Corridor, Arena).
   - Chapter-specific environment settings (Sky, Fog, Lighting).
   - Enemy and loot spawn tables.

2. **Stitching Algorithm**:
   - Start with a random `StartSegment`.
   - Pick an available `ExitPoint` marker on the current segment.
   - Pick a random segment from the pool and align its `EntryPoint` to the exit.
   - Continue for $N$ iterations.
   - Cap the path with an `EndSegment`.

3. **Spawn Automation**: 
   - Segments contain `SpawnMarkers`.
   - The generator automatically populates these markers using the Biome's `enemy_pool`.

## Dependencies

- **Depends on**: Chapter State System (for chapter_id), Scene Management (for loading).
- **Depended on by**: Combat Encounter Manager.

## Acceptance Criteria

- [x] Can generate a connected path of 8 segments without gaps.
- [x] Successfully aligns rotations of segments.
- [x] Spawns a start and end point for every level.
