# Godot Style Checker

A comprehensive style checker for GDScript that enforces coding standards and best practices.

## Features

### Style Rules Checked

#### 1. **Naming Conventions**
- **Classes**: PascalCase (e.g., `MyClass`)
- **Public functions**: snake_case (e.g., `my_function`)
- **Godot virtual methods**: Single underscore prefix - **VALIDATED** against known Godot methods
  - Lifecycle: `_ready`, `_process`, `_physics_process`, `_init`, `_enter_tree`, `_exit_tree`
  - Input: `_input`, `_unhandled_input`, `_gui_input`
  - Drawing: `_draw`, `_notification`
  - Signal handlers: `_on_*` patterns (e.g., `_on_Button_pressed`)
- **Private functions**: Double underscore prefix (e.g., `__private_func`)
- **Variables**: snake_case (e.g., `my_variable`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_HEALTH`)
- **Enum values**: UPPER_SNAKE_CASE (e.g., `ENTITY_TYPE`)

**Note:** Single underscore functions are validated against a comprehensive list of ~50+ known Godot virtual methods. Using `_` for custom private methods will trigger a warning - use `__` instead.

#### 2. **Code Quality**
- **Line length**: Maximum 120 characters
- **Function complexity**: Warns on functions > 50 lines
- **Nesting depth**: Warns on nesting > 4 levels
- **Magic numbers**: Suggests using named constants
- **Empty blocks**: Flags empty functions with only `pass`
- **Duplicate code**: Detects consecutive duplicate lines

#### 3. **Whitespace & Formatting**
- No trailing whitespace
- No mixed tabs/spaces indentation
- Space after comma
- No space before comma/semicolon

#### 4. **Comments & Documentation**
- Public functions should have `##` documentation
- Classes should have documentation at top of file
- Detects commented-out code
- Flags TODO/FIXME/HACK comments
- Requires space after `#` in comments

#### 5. **Godot-Specific Patterns**
- No `.new()` on autoloads
- Avoid `== true` (redundant)
- Use `not` instead of `== false`
- Print statements should have `[DEBUG]` tag
- Consider `$` shorthand over `get_node()`
- Consider `CONNECT_DEFERRED` for signals in `_ready`

#### 6. **Assertions & Error Handling**
- Use assertions for required dependencies
- Include error messages in assertions
- Avoid defensive null checks for required objects

## Usage

### Quick Start
```bash
# Check all files in src/ directory (default)
./style_check.sh

# Check all .gd files in entire project
./style_check.sh --all

# Check specific files
./style_check.sh src/player.gd src/enemy.gd

# Show only errors (ignore warnings)
./style_check.sh --errors-only

# Verbose mode with suggestions
./style_check.sh --verbose
```

### Command Line Options
- `--all` - Check all .gd files in project
- `--verbose` or `-v` - Show detailed suggestions
- `--errors-only` - Only show errors, not warnings
- `--max-violations N` - Limit output to N violations (default: 100)
- `--help` - Show help message

### Python Script Direct Usage
```bash
# Run directly with Python
python3 style_check.py --all --verbose

# Check specific directory
python3 style_check.py src/scenes/

# Pipe specific files
find . -name "*.gd" -mtime -1 | xargs python3 style_check.py
```

## Severity Levels

### ❌ **ERROR** - Must fix
- Mixed tabs/spaces
- Instantiating autoloads with `.new()`
- Critical anti-patterns

### ⚠️ **WARNING** - Should fix
- Naming convention violations
- Line too long
- Missing spaces in formatting
- Deep nesting
- Long functions

### ℹ️ **INFO** - Consider fixing
- Missing documentation
- TODO comments
- Magic numbers
- Print statements without DEBUG tag
- Could use Godot shortcuts

## Exemptions

Add exemption comments to ignore specific lines:

```gdscript
# STYLEOVERRIDE - Reason for override
var complexData = {}  # Won't trigger untyped warning

# STYLE_EXEMPTION - Legacy code
func oldFunction():  # Won't be checked

# noqa - Generic exemption
print("Debug")  # Ignored by style checker
```

## Examples

### Sample Output
```
🔍 Checking 45 files for style violations...

❌ ERRORS:
  src/player.gd:23 [godot-pattern] Don't instantiate autoloads with .new()
    → Access autoloads directly without .new()

⚠️ WARNINGS:
  src/enemy.gd:45 [naming] Variable 'enemyHealth' should be snake_case
    → Rename to 'enemy_health'
  src/utils.gd:78 [line-length] Line exceeds 120 characters (145)
    → Break line into multiple lines

ℹ️ INFO:
  src/game.gd:12 [documentation] Public function 'start_game' lacks documentation
    → Add ## doc comment above function

============================================================
Files checked: 45
Found 1 error, 2 warnings, 1 info
```

### Common Fixes

#### Naming Convention
```gdscript
# ❌ Bad
var playerHealth = 100
func GetDamage():
    pass

# ✅ Good
var player_health = 100
func get_damage():
    pass

# ✅ Also Good - Godot virtual methods
func _ready():
    pass
func _process(delta):
    pass
func _input(event):
    pass

# ✅ Private methods use double underscore
func __handle_internal_state():
    pass
```

#### Magic Numbers
```gdscript
# ❌ Bad
if position.x > 1920:
    position.x = 0

# ✅ Good
const SCREEN_WIDTH = 1920
if position.x > SCREEN_WIDTH:
    position.x = 0
```

#### Assertions
```gdscript
# ❌ Bad (defensive check)
func process_entity(entity):
    if not entity:
        return
    
# ✅ Good (assertion)
func process_entity(entity):
    assert(entity != null, "Entity is required")
```

#### Godot Patterns
```gdscript
# ❌ Bad
if is_ready == true:
    GlobalSignals.new()
    
# ✅ Good
if is_ready:
    GlobalSignals.signal_ready()
```

## Integration

### Pre-commit Hook
Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Run style check on staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.gd$')
if [ -n "$STAGED_FILES" ]; then
    python3 style_check.py $STAGED_FILES --errors-only
    if [ $? -ne 0 ]; then
        echo "Style check failed. Fix errors or use --no-verify to bypass"
        exit 1
    fi
fi
```

### CI/CD Pipeline
```yaml
- name: Run Style Check
  run: |
    python3 style_check.py --all --max-violations 50
    if [ $? -ne 0 ]; then
      echo "::error::Style check failed"
      exit 1
    fi
```

## Configuration

Future versions will support `.style_check.yml` for customizing:
- Maximum line length
- Function complexity thresholds
- Ignored patterns
- Custom rules

## Benefits

1. **Consistency** - Uniform code style across the project
2. **Readability** - Easier to read and understand code
3. **Maintainability** - Reduces technical debt
4. **Best Practices** - Encourages Godot-specific patterns
5. **Early Detection** - Catches issues before code review
6. **Documentation** - Ensures public APIs are documented

## Philosophy

The style checker follows the principle of **progressive enforcement**:
- **Errors** block commits (critical issues)
- **Warnings** should be fixed soon (style violations)
- **Info** are suggestions (nice to have)

This allows teams to adopt the checker gradually without blocking work.