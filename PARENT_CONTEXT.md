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

## Critical Information for All Agents

### Performance Hotspots
- Rendering loop in main game scene
- Projectile collision detection
- Entity spawning and pooling

### Fragile Areas (Handle with Care)
- Scene loading paths (hardcoded references)
- Signal connections (order-dependent)
- Physics body interactions

### Where to Look First
- **For game logic:** `core/entities/` and `managers/`
- **For UI issues:** `ui/` and scene files
- **For data problems:** `data/*.json` and loading in `managers/`
- **For physics issues:** Entity physics bodies and collision layers

### Common Pitfalls to Avoid
1. Don't add comments to .tscn files
2. Don't assume methods exist - check PROJECT_INDEX.json
3. Don't create circular dependencies between systems
4. Don't bypass the Builder pattern for entities
5. Don't use defensive programming where assertions should fail fast

## Session Management Notes

This parent session is:
- Created once for the entire repository
- Shared across all issues and PRs
- Persistent between GitHub runs
- Updated manually when needed via `manage-parent-session.sh`

Child agents inherit all this knowledge and add issue-specific context.

## Questions for Deep Understanding

As you read the codebase, consider:

1. **Architecture Questions**
   - Why is there both a MapCore and a MapManager?
   - How does the signal system prevent circular dependencies?
   - Why use instance IDs instead of direct references?

2. **Pattern Questions**
   - When is the Builder pattern NOT used for entities?
   - Where does type safety get relaxed and why?
   - Which systems break the established patterns?

3. **Evolution Questions**
   - What code looks newest vs oldest?
   - What patterns are being introduced?
   - What patterns are being phased out?

4. **Intent Questions**
   - What is the game trying to become?
   - What technical excellence is being pursued?
   - What pragmatic compromises have been made?

## Parent Session Initialization Instructions

When you are initialized as the parent session, your primary task is to:

**Read the entire codebase and prepare to have a discussion.**

### Deep Learning Objectives

1. **Familiarize yourself with the patterns used across the repository**
   - Study how the Builder pattern is consistently applied
   - Understand the signal-based communication flow
   - Learn the type safety conventions and when they're relaxed
   - Recognize the privacy patterns and their exceptions
   - See where assertions vs defensive checks are used and why

2. **Develop intuition about the code**
   - What feels polished vs what feels experimental?
   - Where is the code confident vs tentative?
   - What patterns are emerging vs being phased out?
   - Which systems are core vs peripheral?

3. **Understand the developer's mindset**
   - What problems are they trying to solve?
   - What constraints are they working under?
   - What are they optimizing for (speed, clarity, flexibility)?
   - What technical debt are they aware of?

4. **Build a mental model**
   - How would you navigate this codebase?
   - What would you check first when debugging?
   - Where would you add new features?
   - What would you refactor if you could?

### What to Pay Special Attention To

**Code Smells and Patterns:**
- Repeated code that could be abstracted
- Inconsistencies that might indicate evolution
- Comments that reveal intention or frustration
- TODOs that show future direction

**System Boundaries:**
- How core/ differs from managers/ differs from ui/
- Where coupling is tight vs loose
- Which systems know about which others
- How data flows between layers

**The Unwritten Rules:**
- Conventions that aren't documented but are followed
- Patterns that emerge from multiple examples
- The "feel" of the code style
- Preferences that show up repeatedly

### Expected Response

After thoroughly reading and understanding the codebase, provide:

1. **Pattern Recognition:** "I notice you consistently use X pattern for Y purpose..."
2. **Architectural Insights:** "The system is organized around these key principles..."
3. **Current State Assessment:** "The project appears to be in a phase where..."
4. **Readiness Confirmation:** "I'm familiar with [specific examples] and ready to discuss..."

Remember: You're not just loading data - you're developing understanding. Future child agents will rely on your deep comprehension to handle specific tasks effectively.

### Additional Context for Child Agents

When child agents fork from you, they should inherit not just facts but understanding:
- Why certain approaches were chosen
- What the unstated conventions are
- Where the tricky parts are
- What the developer cares about most

This deep, intuitive understanding is what makes the difference between a helpful assistant and a true collaborator.

---

*Last Updated: [Will be updated when parent session is recreated]*
*Purpose: Provide comprehensive context for the repository-wide parent session*
*Note: This file is loaded into the parent session during initialization*