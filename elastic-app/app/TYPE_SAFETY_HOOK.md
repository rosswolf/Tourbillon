# Type Safety Presubmit Hook Documentation

## Overview
This repository includes a presubmit hook that enforces type safety requirements for all GDScript files as defined in CLAUDE.md. The hook prevents commits that contain untyped variables, functions, or collections.

## Installation
The hook is already installed in `.git/hooks/pre-commit` and will run automatically on every commit.

## What It Checks

### 1. Variable Type Declarations
All variables must have explicit type annotations:
```gdscript
# ❌ BAD - Untyped variables
var health = 100
var name = "Player"
var items = []

# ✅ GOOD - Typed variables
var health: int = 100
var name: String = "Player"
var items: Array[String] = []
```

### 2. Function Parameters and Return Types
All functions must specify parameter types and return types:
```gdscript
# ❌ BAD - Untyped function
func calculate_damage(base, multiplier):
    return base * multiplier

# ✅ GOOD - Fully typed function
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

# Special functions should specify void
func _ready() -> void:
    pass
```

### 3. Collections (Arrays and Dictionaries)
Arrays and dictionaries must use typed versions:
```gdscript
# ❌ BAD - Untyped collections
var items = []
var data = {}
var things: Array
var map: Dictionary

# ✅ GOOD - Typed collections
var items: Array[String] = []
var data: Dictionary[String, int] = {}
var things: Array[Node] = []
var map: Dictionary[Vector2i, Tile] = {}
```

### 4. @onready Variables
@onready variables should specify the node type:
```gdscript
# ❌ BAD - Untyped node reference
@onready var label = $Label

# ✅ GOOD - Typed node reference
@onready var label: Label = $Label
@onready var timer: Timer = $Timer
```

### 5. Godot Limitations
Godot 4 doesn't support nested typed dictionaries:
```gdscript
# ⚠️ WARNING - Not supported by Godot
var nested: Dictionary[String, Dictionary[String, int]] = {}

# Use a custom class or add override comment (see below)
```

## Using Style Overrides

Sometimes you may have legitimate reasons to bypass type checking. Use the `#STYLEOVERRIDE` comment with a reason:

```gdscript
# STYLEOVERRIDE (Complex dynamic data structure)
var dynamic_data = {}

# STYLEOVERRIDE (Legacy code to be refactored in issue #123)
func old_function(data):
    return process_legacy_data(data)

# STYLEOVERRIDE (Godot nested dictionary limitation)
var complex_map: Dictionary[String, Dictionary[String, Variant]] = {}
```

### Override Syntax
- Must be on the line immediately before the code to override
- Must include a reason in parentheses
- Format: `#STYLEOVERRIDE (reason here)`

## Running Manually

### Check Specific Files
```bash
python3 elastic-app/app/check_type_safety.py file1.gd file2.gd
```

### Check All Files in src/
```bash
cd elastic-app/app
python3 check_type_safety.py --all
```

### Verbose Mode
```bash
python3 check_type_safety.py --verbose file.gd
```

## Bypassing the Hook (Not Recommended)

If absolutely necessary, you can bypass the hook for a single commit:
```bash
git commit --no-verify -m "Emergency fix"
```

⚠️ **Warning**: This should only be used in emergencies. It's better to add proper type annotations or use `#STYLEOVERRIDE` comments.

## Common Fixes

### Untyped Integer
```gdscript
# Before
var count = 0
# After
var count: int = 0
```

### Untyped String
```gdscript
# Before
var player_name = "Hero"
# After
var player_name: String = "Hero"
```

### Untyped Array
```gdscript
# Before
var enemies = []
# After
var enemies: Array[Enemy] = []
```

### Untyped Dictionary
```gdscript
# Before
var stats = {"hp": 100, "mp": 50}
# After
var stats: Dictionary[String, int] = {"hp": 100, "mp": 50}
```

### Function Missing Return Type
```gdscript
# Before
func get_health():
    return current_health
# After
func get_health() -> int:
    return current_health
```

### Void Functions
```gdscript
# Before
func _ready():
    initialize()
# After
func _ready() -> void:
    initialize()
```

## Exceptions

The following don't require explicit type annotations:
- Constants (type is inferred from value)
- Signal definitions
- Enum definitions
- Variables assigned with `null` (will be typed when assigned later)
- Variables assigned from typed expressions (new(), preload(), load(), as cast)

## Troubleshooting

### Error: "Function should explicitly specify '-> void' return type"
Add `-> void` to functions that don't return a value, especially lifecycle functions like `_ready()`, `_process()`, etc.

### Warning: "Godot doesn't support nested typed dictionaries"
Either:
1. Create a custom class to wrap the inner dictionary
2. Use `Dictionary[String, Variant]` for the inner type
3. Add `#STYLEOVERRIDE (reason)` if the structure is necessary

### Error: "Function parameter missing type annotation"
Add type annotations to all function parameters, even if they have default values:
```gdscript
# Before
func move(speed = 10):
# After  
func move(speed: int = 10) -> void:
```

## Benefits

- **Catches bugs early**: Type errors are caught before runtime
- **Better autocomplete**: IDEs can provide better suggestions
- **Self-documenting code**: Types make code intentions clear
- **Performance**: Typed GDScript can be optimized better by the engine
- **Maintainability**: Easier to refactor and understand code

## Questions?

If you encounter issues or have questions about type safety requirements, consult:
1. CLAUDE.md for full coding standards
2. The Godot 4 documentation on typed GDScript
3. Add an issue to the repository for discussion