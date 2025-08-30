# Parent Session Context

This file is loaded into the repository-wide parent session to provide persistent context across all GitHub Claude interactions.

## Repository Overview

**Project:** Castlebuilder (formerly Swish)
**Type:** Godot 4.4 game prototype
**Architecture:** Card-based tower defense with physics simulation

## Current State

### Working Components
- Avatar system with mouse-controlled movement
- Projectile firing with predictive aiming
- Data loading and management systems
- Basic menu navigation
- Physics simulation for projectiles

### In Development
- Card gameplay system (data structures exist, no execution)
- Resource management (energy types defined)
- Building deployment mechanics
- Enemy AI and combat systems
- Goal/objective system

## Key Technical Decisions

### Architecture Patterns
- Entity-Component pattern for game objects
- Builder pattern for entity creation
- Interface-first development
- Signal-based communication between systems
- Instance tracking with unique IDs

### Code Organization
```
castlebuilder-app/app/
├── src/
│   ├── core/          # Core game systems
│   │   ├── entities/  # Entity base classes
│   │   └── map/       # Map and node systems
│   ├── managers/      # Game state management
│   ├── ui/            # UI components
│   └── scenes/        # Godot scenes
├── data/              # JSON game data
└── PROJECT_INDEX.json # Code structure index
```

## Important Context for Agents

### When Working on Issues
1. Always check PROJECT_INDEX.json for existing methods before creating new ones
2. Follow the Builder pattern for new entities
3. Register new entity types in Entity.EntityType enum
4. Use typed variables and arrays (Array[Type], Dictionary[K,V])
5. Fail fast with assertions, not defensive checks

### Common Tasks

**Bug Fixes:**
- Check if the method exists in PROJECT_INDEX.json
- Verify parameter types match
- Look for similar implementations before creating new code

**Pull Requests:**
- Create feature branches: `feature/description-TIMESTAMP`
- Use atomic commits with clear messages
- Include issue number in PR description
- Run any existing tests before pushing

**Documentation Updates:**
- PRD.md contains game design (currently out of sync with implementation)
- CLAUDE.md contains development guidelines
- This file (PARENT_CONTEXT.md) provides repository context

### Known Issues & Decisions

1. **PRD Mismatch:** The PRD describes features not yet implemented
2. **No Test Suite:** Currently prototyping without automated tests
3. **Menu Navigation:** Main menu tries to load non-existent scene paths
4. **Missing Methods:** GlobalGameManager.activate() not implemented

## Project-Specific Knowledge

### Game Concepts
- **Castles:** Player's base that must be defended
- **Cards:** Represent actions player can take (summon units, cast spells)
- **Energy:** Resource system for playing cards (multiple types planned)
- **Enemies:** Spawn and move toward castle (AI not implemented)
- **Buildings:** Defensive structures placed by cards (system incomplete)

### Technical Gotchas
- Scene files (.tscn) cannot have comments - they break parsing
- Resource paths are relative to project.godot location
- The `__` prefix denotes private methods/properties
- Entity types must include UNKNOWN as first enum value

## Communication Patterns

### With GitHub Issues
- Be concise and action-oriented
- Reference specific files with `path/to/file.gd:line_number` format
- Create PRs when code changes are requested
- Use gh CLI for GitHub operations

### With Development Team
- Acknowledge previous conversation context
- Provide specific implementation suggestions
- Flag architectural concerns early
- Document decisions in commit messages

## Development Workflow

1. **Index First:** Run `/index --quick` before major work
2. **Check Index:** Query PROJECT_INDEX.json for existing code
3. **Follow Patterns:** Use established patterns from similar code
4. **Fail Fast:** Use assertions for requirements
5. **Clean As You Go:** Remove unused code immediately

## External Resources

### Tools Available
- `gh` CLI for GitHub operations
- `git` for version control
- `/index` command for updating PROJECT_INDEX.json
- Claude Code CLI for testing

### File Paths
- Repository: `/home/rosswolf/Code/castlebuilder`
- Claude settings: `~/.claude/`
- GitHub workflows: `.github/workflows/`

## Agent Specializations

When forked as specialized agents, remember your role:

- **pull-request:** Focus on creating clean PRs with proper branching
- **bug-fix:** Identify root cause, fix issue, verify solution
- **code-review:** Check patterns, performance, and guidelines
- **documentation:** Update docs to match current implementation

## Session Management Notes

This parent session is:
- Created once for the entire repository
- Shared across all issues and PRs
- Persistent between GitHub runs
- Updated manually when needed via `manage-parent-session.sh`

Child agents inherit all this knowledge and add issue-specific context.

---

*Last Updated: [Will be updated when parent session is recreated]*
*Purpose: Provide comprehensive context for the repository-wide parent session*