# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: Godot Export Pipeline
- **Asset Pipeline**: Godot Import Pipeline (native .import files)

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.
Use jcodemunch-mcp for code lookup whenever available.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md



## jcodemunch-mcp (v1.23.3)

Use jcodemunch-mcp tools instead of Grep/Read/Glob for any indexed repository.

### Quick start
1. `list_repos` — check if the project is indexed.
   If not: `index_folder` (local) or `index_repo` (GitHub URL).
2. `search_symbols` — find functions/classes by name or description.
3. `get_context_bundle` — symbol source + imports in one call.
4. `search_text` — full-text/regex search for literals and comments.

### All tools
**Indexing:** `index_repo`, `index_folder`, `summarize_repo`, `index_file`
**Discovery:** `list_repos`, `resolve_repo`, `suggest_queries`, `get_repo_outline`, `get_file_tree`, `get_file_outline`
**Search & Retrieval:** `search_symbols`, `get_symbol_source`, `get_context_bundle`, `get_file_content`, `search_text`, `search_columns`, `get_ranked_context`
**Relationships:** `find_importers`, `find_references`, `check_references`, `get_dependency_graph`, `get_class_hierarchy`, `get_related_symbols`, `get_call_hierarchy`
**Impact & Safety:** `get_blast_radius`, `check_rename_safe`, `get_impact_preview`, `get_changed_symbols`
**Architecture:** `get_dependency_cycles`, `get_coupling_metrics`, `get_layer_violations`, `get_extraction_candidates`, `get_cross_repo_map`
**Quality & Metrics:** `get_symbol_complexity`, `get_churn_rate`, `get_hotspots`, `get_repo_health`, `get_symbol_importance`, `find_dead_code`, `get_dead_code_v2`
**Diffs & Embeddings:** `get_symbol_diff`, `embed_repo`
**Session-Aware Routing:** `plan_turn`, `get_session_context`, `get_session_snapshot`, `register_edit`
**Utilities:** `get_session_stats`, `invalidate_cache`, `test_summarizer`, `audit_agent_config`

Never fall back to Grep, Read, or Glob for indexed repos.
