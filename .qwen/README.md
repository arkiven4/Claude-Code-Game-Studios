# Qwen Code Configuration

This directory contains configuration and agent definitions for Qwen Code, adapted from the Claude Code Game Studios architecture.

## Structure

```
.qwen/
├── settings.json              # Main Qwen Code configuration
├── statusline.sh              # Status line script
├── agents/                    # 48 specialized game development agents
├── hooks/                     # Automation scripts for session lifecycle
├── rules/                     # Domain-specific coding standards
├── skills/                    # Reusable workflows and procedures
└── docs/                      # Documentation and templates
```

## Quick Start

1. **Main Configuration**: `QWEN.md` in the project root is the entry point
2. **Local Settings**: Copy `.qwen/docs/settings-local-template.json` to `.qwen/settings.local.json` for personal overrides
3. **Local Preferences**: Copy `.qwen/docs/QWEN-local-template.md` to `QWEN.local.md` in the project root for personal preferences

## Agents

48 specialized agents covering all aspects of game development:
- **Core Team**: Lead Programmer, Technical Director, Creative Director, Producer
- **Programming**: AI, Gameplay, Engine, Network, Tools, UI, Security
- **Design**: Game Design, Systems, Level, Economy, UX
- **Art & Audio**: Art Director, Technical Artist, Sound Designer
- **Specialized**: Engine specialists for Unity, Unreal, Godot
- **Quality & Operations**: QA, DevOps, Release Manager, Analytics

## Hooks

Automated scripts that run during session lifecycle:
- **SessionStart**: Initialize session and detect gaps
- **PreToolUse**: Validate git operations before execution
- **PostToolUse**: Validate assets after writes/edits
- **PreCompact**: Prepare for context compaction
- **Stop**: Clean up session
- **SubagentStart**: Log agent usage

## Rules

Domain-specific coding standards applied automatically:
- AI Code, Data Files, Design Docs
- Engine Code, Gameplay Code, Narrative
- Network Code, Prototype Code, Shader Code
- Test Standards, UI Code

## Skills

37 reusable workflows including:
- Code Review, Bug Report, Prototype
- Sprint Planning, Retrospectives
- Balance Check, Perf Profile
- Localization, Accessibility checks

## Migration from Claude Code

This configuration mirrors the `.claude` setup with path references updated for Qwen Code. Both can coexist in the same project.

## Documentation

See `.qwen/docs/` for:
- Agent roster and coordination map
- Coding standards and technical preferences
- Rules and skills reference
- Quick start and setup guides
- Review workflow
