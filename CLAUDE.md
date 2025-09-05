# Claude Development Guide - Godot 4.4 Project

## 🔴 CRITICAL: Git Worktree Protocol for Multiple Claude Sessions

### Worktree Setup and Usage

**IMPORTANT:** When multiple Claude sessions are running simultaneously, each MUST use its own git worktree to avoid conflicts.

**Worktree Locations:**
- **Claude 1**: `/home/rosswolf/Code/Tourbillon-claude-1`
- **Claude 2**: `/home/rosswolf/Code/Tourbillon-claude-2`  
- **Claude 3**: `/home/rosswolf/Code/Tourbillon-claude-3`
- **Main** (reference only): `/home/rosswolf/Code/Tourbillon`

### Your Workflow (FOLLOW EXACTLY):

1. **Identify which Claude you are** (1, 2, or 3) at session start
2. **Navigate to your worktree**: `cd /home/rosswolf/Code/Tourbillon-claude-[N]`
3. **Sync with main before ANY work**:
   ```bash
   git fetch origin main
   git reset --hard origin/main
   ```
4. **After EVERY change**:
   ```bash
   # Commit locally
   git add -A && git commit -m "description"
   
   # Push to main (from your worktree)
   cd /home/rosswolf/Code/Tourbillon
   git pull origin main
   git cherry-pick [your-commit-hash]
   git push origin main
   
   # Return to your worktree and sync
   cd /home/rosswolf/Code/Tourbillon-claude-[N]
   git reset --hard origin/main
   
   # Show diff for review
   git diff HEAD~1
   ```
5. **NEVER accumulate uncommitted changes** - push after each logical change
6. **ALWAYS provide the diff** after pushing for code review

### Rules:
- Maximum 3 pending changes before syncing
- Never work directly in main worktree
- Always pull latest before starting new work
- If you get conflicts, sync with main first

---

## 🔴 CRITICAL: Check Project Index BEFORE ANY Code Work

## 🛑 STOP: Pre-Code Verification Checklist

**DO NOT WRITE ANY CODE until you've completed ALL these steps:**

□ 1. Navigate to correct project directory (has project.godot)
□ 2. Run `/index --quick` to ensure index is current
□ 3. For the specific class you're modifying:
   - Query: `@PROJECT_INDEX.json list all methods in [ClassName]`
   - Query: `@PROJECT_INDEX.json what calls [ClassName]`
□ 4. Verify the exact method signatures you'll call exist
□ 5. Check parameter types match what you'll pass

**If ANY step fails → STOP and run `/index --full`**

### Mandatory Index Usage - NEVER SKIP THIS STEP

**Before touching ANY code, you MUST:**
```bash
# FASTEST INDEX CHECKS (memorize these):
ls PROJECT_INDEX.json  # Check if exists
head -1 PROJECT_INDEX.json | grep "indexed_at"  # Check age
/index --quick  # Update if needed (takes <5 seconds)

# Step 1: Check if index exists and when it was last updated
cat PROJECT_INDEX.json | head -20

# Step 2: If no index or it's outdated (>1 day old):
/index --quick  # Uses cache for speed

# Step 3: For major work, use the index-analyzer:
# Task: "Analyze PROJECT_INDEX.json for [specific need]" with index-analyzer agent
```

### When You MUST Use the Index:

1. **Before calling any method** → Check it exists: `@PROJECT_INDEX.json does MapCore have set_map method?`
2. **Before creating new code** → See patterns: `@PROJECT_INDEX.json show similar implementations`
3. **Before modifying code** → Check dependencies: `@PROJECT_INDEX.json what calls this function?`
4. **When answering questions** → Get accurate info: `@PROJECT_INDEX.json what methods does Entity have?`

### Red Flags - If You're Doing This, You Forgot the Index:
- Using `grep` or `find` to search for methods
- Guessing if a method exists
- Assuming parameter types
- Not knowing where similar code lives
- Getting "method not found" errors

### Example Index Queries:
```bash
# Check available methods
@PROJECT_INDEX.json what public methods does GameManager have?

# Find implementations
@PROJECT_INDEX.json where is fog_of_war implemented?

# Check dependencies
@PROJECT_INDEX.json what calls signal_core_map_created?

# Understand architecture
Task: "Analyze the entity system architecture" with index-analyzer
```

### Consequences of Not Using Index:
- ❌ Calling non-existent methods (like `set_map()` on MapCore)
- ❌ Wrong parameter types and counts
- ❌ Creating duplicate functionality
- ❌ Missing existing utilities
- ❌ Breaking architectural patterns

### Real Examples of Index Preventing Errors:

```gdscript
# WRONG - Method doesn't exist (would fail at runtime)
map_core.set_map(new_map)  # MapCore has no set_map method!

# RIGHT - Check index first, use correct method
# Query: @PROJECT_INDEX.json what methods does MapCore have?
# Result shows: signal_core_map_created(map: Map)
map_core.signal_core_map_created(new_map)
```

### What Happens When You Skip the Index:

1. **Runtime Errors:** Calling non-existent methods
2. **Wasted Time:** Implementing duplicate functionality  
3. **Architecture Violations:** Not following established patterns
4. **User Frustration:** Having to fix preventable mistakes

**Remember:** 5 seconds to check index saves 30 minutes of debugging

---

## Compilation Errors Are Non-Negotiable

**CRITICAL:** Never use `--no-verify` to bypass compilation errors without explicit user permission.
- Compilation errors indicate broken code that will fail at runtime
- Always fix compilation errors before committing
- If a pre-commit hook fails with compilation errors, investigate and fix them immediately
- Only use `--no-verify` after getting explicit permission: "The compilation error is a false positive, should I bypass it?"

## Project Context

This is a Godot 4.4 game development project focused on prototyping and building reusable library components. The codebase prioritizes clean, production-quality code even during rapid iteration phases.

## Git Repository Requirements

### Create All New Repositories as Private

**CRITICAL:** When creating new Git repositories, ALWAYS create them in a **private** state:

- **Default to private:** All new repositories must be created as private unless explicitly requested otherwise
- **GitHub:** Use `--private` flag with `gh repo create` or select "Private" in web UI
- **Security first:** Private by default prevents accidental exposure of proprietary code, credentials, or sensitive information
- **Ask before public:** Only make a repository public after explicit confirmation from the user

**Example:**
```bash
# CORRECT - Creates private repository by default
gh repo create my-project --private

# WRONG - Creates public repository without confirmation
gh repo create my-project --public
```

This applies to:
- New project repositories
- Fork operations (ensure private fork if possible)
- Repository migrations
- Any repository creation via API or CLI

### Gitignore Best Practices

**IMPORTANT:** When modifying .gitignore to exclude files from version control:

1. **Remove already-tracked files:** If files matching the new gitignore patterns are already in git, they must be removed from tracking:
   ```bash
   # After adding patterns to .gitignore, remove tracked files:
   git rm -r --cached path/to/files/
   git rm -r --cached directory/
   
   # Then commit the removal:
   git commit -m "Remove files that should be gitignored"
   ```

2. **Common patterns to always exclude:**
   - Build artifacts: `build/`, `/build/`, `dist/`
   - Test screenshots: `*_test_screenshots/`, `test_screenshots/`
   - Temporary files: `*.tmp`, `*.pyc`, `__pycache__/`
   - IDE/editor files: `.idea/`, `.vscode/`, `*.swp`

3. **Verification steps:**
   - Run `git status` to ensure ignored files don't appear
   - Check that `git ls-files` doesn't list files that should be ignored
   - Use `git check-ignore <path>` to verify a path is properly ignored

**Note:** Simply adding patterns to .gitignore does NOT remove already-tracked files. You must use `git rm --cached` to untrack them first.

## Communications Directory (comms/)

Project communications, task documentation, and work-in-progress notes are stored in the top-level `comms/` directory in your Code workspace. This directory is NOT checked into version control.

**Key Points:**
- Task-specific folders: `comms/[task-name]/` (e.g., `comms/map-ui-refactor/`)
- Deleted code goes here for reference: `comms/[task-name]/deleted/`
- Progress updates and decisions: `comms/[task-name]/notes.md`
- See `comms/COMMS.md` for full documentation

**Location:** Always use the top-level Code workspace `comms/` directory, not project-specific comms folders

**Never commit:** Files in `comms/` directory - it's for local documentation only

## Development Philosophy

- **Clean code is non-negotiable** - Write production-quality code from the start
- **Prototyping != sloppy code** - Rapid iteration with solid architecture
- **Skip tests, not quality** - During prototyping, we defer test writing but maintain high code standards
- **Iterate on stable foundations** - Build robust systems that can evolve
- **Interface-first development** - Define contracts before implementation
- **Fail fast, fail loud** - Use assertions instead of defensive checks (see below)

## Git Workflow and Task Completion

### Git Worktrees for Parallel Development

**USE WORKTREES** when working on multiple features or bugs simultaneously. Worktrees allow multiple Claude sessions to work in parallel without interference.

#### What are Worktrees?
- Worktrees create separate working directories for different branches
- Each worktree has its own files, build artifacts, and node_modules
- All worktrees share the same Git history and remote
- Perfect for running multiple Claude sessions on different tasks

#### Setting Up Worktrees

**Create a new worktree:**
```bash
# From main project directory
# Create worktree with new branch
git worktree add ../project-feature-x -b feature-x

# Or use existing branch
git worktree add ../project-bugfix-123 bugfix-123
```

**Naming convention:**
- Use descriptive names: `../project-feature-auth`, `../project-fix-login`
- Keep worktrees at same level as main project for easy navigation

#### Working with Worktrees

**Start Claude in each worktree:**
```bash
# Terminal 1
cd ../project-feature-auth
claude
> implement OAuth authentication

# Terminal 2 (simultaneously!)
cd ../project-fix-login  
claude
> fix the login timeout bug
```

**Benefits:**
- No context switching or stashing required
- Each Claude session maintains its own state
- Build artifacts and dependencies stay isolated
- Can compare implementations side-by-side

#### Managing Worktrees

```bash
# List all worktrees
git worktree list

# Remove completed worktree
git worktree remove ../project-feature-x

# Clean up stale worktree references
git worktree prune
```

#### Worktree Workflow

1. **Create worktree** for new task
2. **Run Claude** in the worktree directory
3. **Complete the task** with Claude
4. **Push changes** from the worktree
5. **Merge to main** (from any worktree)
6. **Remove worktree** when done

**Example complete workflow:**
```bash
# Create worktree for new feature
git worktree add ../project-add-caching -b feature/caching

# Work in worktree
cd ../project-add-caching
npm install  # Set up environment
claude       # Start development

# After completing work
git add .
git commit -m "feat: add caching system"
git push origin feature/caching

# Merge (from main worktree or current)
cd ../main-project
git pull origin main
git merge feature/caching
git push origin main

# Cleanup
git worktree remove ../project-add-caching
git branch -d feature/caching
```

#### When to Use Worktrees

**Use worktrees for:**
- Working on multiple features simultaneously
- Handling urgent bugs while preserving feature work
- Running long Claude tasks without blocking other work
- Comparing different implementation approaches
- Isolating experimental changes

**Don't need worktrees for:**
- Quick single-file fixes
- Sequential tasks on the same branch
- Read-only code reviews

### Push to Main After Each Task

**IMPORTANT:** After completing any significant task or feature:

1. **Ask for permission to push:** "I've completed [task]. Should I push these changes to main?"
2. **Wait for user confirmation** before pushing
3. **Push to main immediately** after getting approval
4. **Provide the GitHub compare link** after pushing: `https://github.com/[owner]/[repo]/compare/[old-commit]..[new-commit]`
   - Example: "CL: https://github.com/rosswolf/Tourbillon/compare/019a857..894e04e"
5. **Never accumulate multiple unrelated changes** without pushing

**Why this matters:**
- Prevents merge conflicts from accumulating
- Keeps the remote repository up-to-date
- Makes it easier to track what changes have been deployed
- Reduces risk of losing work
- Allows other team members to see progress

**Example workflow:**
```bash
# After completing a task
git add .
git commit -m "feat: Add resource management system"
# ASK USER: "Should I push these changes to main?"
# After approval:
git push origin main
```

**When to push:**
- After completing a feature
- After fixing a bug
- After refactoring code
- After updating documentation
- Before switching to a different task

**When NOT to push (without explicit permission):**
- Work in progress that breaks the build
- Incomplete features that would confuse other developers
- Experimental changes that haven't been discussed

## Interface-First Development

### Project Index Integration
This project uses automatic indexing to maintain architectural awareness. The PROJECT_INDEX.json file contains:
- All function and class signatures
- Call relationships between functions
- File organization and structure

**Index Commands:**
- `/index` - From Code directory: indexes ALL Godot projects. From project directory: indexes just that project
- `/index --full` - Force complete regeneration (ignores cache)
- `/index --quick` - Quick update using cache only
- `/index src` - Update just the src folder (when in a project)

**When to Reindex:**
- After creating new interfaces or public methods
- After major refactoring or moving code
- Before starting work (use `--quick` for fast cache check)
- After completing a feature to update the architectural map

### Index + TodoWrite Workflow

**MANDATORY for any code modification task:**

```gdscript
# Step 1: Create todo with index check
TodoWrite([
    "Check PROJECT_INDEX.json for target class methods",
    "Verify method signatures match intended usage",
    "Implement the change",
    "Update index if new public methods added"
])

# Step 2: Mark first todo in_progress and CHECK THE INDEX
@PROJECT_INDEX.json list all public methods in [TargetClass]
```

### Core Principle
Objects are black boxes. They can only interact through explicitly defined public interfaces.

### Index-First Decision Tree

**Before ANY code change, ask:**

1. Am I calling a method on another class?
   → YES: `@PROJECT_INDEX.json does [Class] have [method]?`
   
2. Am I adding a new public method?
   → YES: Plan to run `/index` after implementation
   
3. Am I unsure what methods are available?
   → YES: `@PROJECT_INDEX.json list methods in [Class]`

**If you skip these → You WILL create bugs**

### Decision Tree for Any Change

1. **Does this change affect how other objects interact with this one?**
   - YES → Start with Define/Modify Interfaces
   - NO → Skip to Implementation only

2. **Am I creating new functionality that other objects will use?**
   - YES → Start with Define Interfaces
   - NO → Skip to Implementation only

### Define/Modify Interfaces (when needed)

Before writing ANY implementation code:
1. **CHECK THE INDEX FIRST** - Run: `/index --quick` if PROJECT_INDEX.json is >1 hour old
2. **READ THE TARGET FILE** - Use Read tool
3. **QUERY THE INDEX** - `@PROJECT_INDEX.json methods in [ClassName]`
4. Check if the target class has the methods you want to call
2. Design the complete public interface in a clearly marked section
3. Document what each interface method/property does
4. Verify the interface is sufficient for all use cases
5. DO NOT write implementation until interfaces are complete

### Implementation Guidelines

1. Verify you're only using other objects through their public interfaces
2. Implement strictly within your defined interface contract
3. Keep all non-interface code private (use `__` prefix in Godot)
4. If you discover the interfaces are insufficient:
   - STOP immediately
   - Go back to define/modify interfaces
   - Update documentation before continuing

### Interface Requirements

**Critical Rule: No Speculative Code (YAGNI)**
- Only add properties, methods, and interfaces that are actively used
- Future needs should be comments, not unused code
- Serialization methods (to_dict/from_dict) only when actually saving/loading
- Remove unused methods during refactoring
- "You Aren't Gonna Need It" (YAGNI) principle applies
- No placeholder properties (e.g., room_type when rooms aren't implemented)
- Use comments for future considerations:
```gdscript
# GOOD - Document future needs
# Future: Add room_type when room variety is implemented

# BAD - Unused property
var room_type: String = "normal"  # Not used anywhere
```

**Property Removal Checklist:**
- Is this property being read anywhere? If no, remove it
- Is this only being set but never used? Remove it
- Could this be derived from other data? Don't store it

**Needs Interface Definition First:**
- Adding a new method that other classes will call
- Changing parameters of an existing public method
- Creating a new class/module
- Adding signals that others can connect to
- Modifying return types of public methods

**Implementation Only (no interface changes):**
- Fixing a bug in existing method logic
- Optimizing performance of internal algorithms
- Refactoring private helper functions
- Updating internal data structures (if not exposed)

### Red Flags (Stop and Fix)

- **Not checking the index before calling methods**
- Calling a method that doesn't exist (like `set_map()` on MapCore)
- Accessing private properties (`__` prefix) of another object
- Creating circular dependencies between classes
- Finding yourself needing to change multiple objects just to access data
- Using untyped variables to bypass interface contracts
- **Returning EntityType.UNKNOWN from _get_type() when type is known**
- **Having both getter and setter for data that's never read**
- **Storing redundant position data in multiple formats**
- **Missing UNKNOWN as first enum value**
- **Having initialize() method when using Builder pattern**

### Using the Index for Interface Verification

**Before calling any method:**
1. Check PROJECT_INDEX.json or use `-i` flag to see available interfaces
2. Verify the method exists in the target class
3. Confirm parameter types match your usage
4. Check the call graph to understand dependencies

**The index prevents common mistakes:**
- Shows all public methods of a class instantly
- Reveals what functions call what (dependency tracking)
- Identifies unused interfaces (dead code)
- Helps place new code in the correct location

## Coding Standards

### Check Directory Documentation

**IMPORTANT:** Before working in any directory, check for:
- `PATTERNS.md` - Technical patterns and conventions for that directory
- `PURPOSE.md` - Architectural purpose and responsibilities
- `CLAUDE.md` - Directory-specific Claude instructions

These files contain critical context for the code you're about to modify.

### Type Safety Requirements

**Use the most specific type possible in all declarations:**
- Always use typed variables: `var health: int = 100` not `var health = 100`
- Use typed arrays: `Array[String]`, `Array[MapNode]`, `Array[Vector2i]`
- Use typed dictionaries in Godot 4: `Dictionary[String, Vector2i]`, `Dictionary[Vector2i, MapNode]`
- Use typed function parameters and return types
- Use enum types instead of int constants where applicable
- Prefer specific node types over generic Node: `@onready var label: Label` not `@onready var label: Node`

**Examples:**
```gdscript
# GOOD - Fully typed
var entity_positions: Dictionary[String, Vector2i] = {}
var nodes: Array[MapNode] = []
func get_entity_at(pos: Vector2i) -> Entity:
    return entities.get(pos, null) as Entity

# BAD - Untyped or weakly typed
var entity_positions = {}
var nodes = []
func get_entity_at(pos):
    return entities.get(pos)
```

**Benefits of full typing:**
- Compile-time error detection
- Better autocomplete and IntelliSense
- Self-documenting code
- Performance optimizations
- Prevents type-related bugs

## Specialized Documentation

**For detailed standards and patterns, see:**
- **Godot Development:** `godot/GODOT_STANDARDS.md`
- **External Integrations:** `tools/INTEGRATIONS.md`
- **Configuration:** `setup/CONFIGURATION.md`
- **Project-specific patterns:** Check `PATTERNS.md` in relevant project directories

## Fail-Fast Principle

### Use Assertions, Not Defensive Checks

**CRITICAL:** Unless we explicitly want to work without something, we should fail immediately to expose errors.

**BAD - Silent failure with defensive checks:**
```gdscript
func update_fog() -> void:
    if not camera:  # Silently does nothing if camera missing
        return
    if not map_entity:  # Hard to debug when it doesn't work
        return
    # actual work...
```

**GOOD - Fail fast with assertions:**
```gdscript
func update_fog() -> void:
    assert(camera != null, "Camera must exist for fog updates")
    assert(map_entity != null, "Map entity required for fog")
    # actual work...
```

### When to Use Assertions
- **Required dependencies:** Objects that MUST exist for the function to work
- **Invalid states:** Conditions that should never happen in correct code
- **Contract violations:** When callers provide invalid data
- **Initialization requirements:** Things that must be set up before use

### When to Use Defensive Checks
- **Optional features:** When something is genuinely optional
- **User input:** Data from external sources that could be invalid
- **Graceful degradation:** When you want to continue with reduced functionality
- **Explicitly documented as optional:** When the API says it's okay to be null

### Benefits of Fail-Fast
- **Easier debugging:** Errors appear exactly where they occur
- **Clear requirements:** Makes dependencies explicit
- **Prevents cascading failures:** Stops bad state from propagating
- **Better error messages:** Assertions provide context about what went wrong
- **Forces proper initialization:** Can't ignore setup requirements

## Clean Code Practices

### Progressive Refinement
- Start with working code, then refactor
- Remove unused elements immediately when identified
- Don't wait for "cleanup phase" - clean as you go

### Code Review Checklist
- Are all properties actively used?
- Can any data be derived instead of stored?
- Are enums properly defined with UNKNOWN first?
- Is the Builder pattern properly implemented?
- Are Entity types properly registered in the enum?

## Architectural Principles

**Note:** Detailed architectural patterns have been distributed to appropriate directories:
- **Core Architecture:** See `core/PATTERNS.md`
- **Entity Patterns:** See `core/entities/PATTERNS.md`
- **State Management:** See `managers/PATTERNS.md`
- **UI Architecture:** See `ui/PATTERNS.md`

### Quality Gates (Even in Prototypes)

- Code compiles without errors
- No memory leaks or resource issues
- Clear separation of concerns maintained
- Instance tracking consistent
- Manual functionality validation passes

## Remember

- Check interfaces exist before calling them - The #1 rule (use PROJECT_INDEX.json!)
- Clean code is faster to iterate on than messy code
- Architecture decisions compound - make them thoughtfully
- Prototype quality code, defer test writing
- Document what needs testing for later
- When asking for plan approval, bring an easily legible plan to the console

## Quick Index Reference

```bash
# From Code workspace root - indexes ALL Godot projects:
/index           # Smart mode (uses cache)
/index --full    # Complete regeneration
/index --quick   # Cache only

# From project directory - indexes just that project:
/index           # Update whole project
/index src       # Update just src folder
/index --full    # Force full regeneration

# Using the index in prompts:
"Check the index for MapCore methods -i"
"@PROJECT_INDEX.json what calls render_fog?"
```

