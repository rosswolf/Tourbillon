# Exemption System Guide

## Overview

The compile check hook provides a flexible exemption system to handle legacy code, third-party libraries, and special cases while maintaining strict standards for new code.

## Exemption Levels

### 1. Line-Level Exemptions

Exempt individual lines by adding a comment on the previous line.

#### Syntax Options

```gdscript
# EXEMPT: TYPE_CHECK
var untyped = "This line won't require type annotation"

# EXEMPT: PRIVATE_ACCESS
var data = object.__private_field  # Access allowed for this line

# EXEMPT: ALL
func legacy_function():  # Completely exempt from all checks
    pass

# @compile-check-ignore
var alternative_syntax = "Also works"
```

#### Available Markers
- `# EXEMPT: TYPE_CHECK` - Skip type annotation checks
- `# EXEMPT: PRIVATE_ACCESS` - Allow private variable access
- `# EXEMPT: ALL` - Skip all checks for the line
- `# @compile-check-ignore` - Alternative syntax (skips all)

### 2. File-Level Exemptions

Configure in the `exemptions` dictionary within `godot_compile_check.gd`:

```gdscript
var exemptions = {
    "fully_exempt_files": [
        "res://src/legacy/old_system.gd",
        "res://addons/dialogic/plugin.gd"
    ],
    
    "type_check_exempt": [
        "res://src/migration/partial_update.gd"
    ],
    
    "private_var_exempt": [
        "res://src/debug/inspector.gd"
    ]
}
```

#### Exemption Categories
- `fully_exempt_files` - Skip ALL checks
- `type_check_exempt` - Skip only type-related checks
- `private_var_exempt` - Skip only private variable access checks

### 3. Pattern-Based Exemptions

Files matching certain patterns are automatically exempted:

```gdscript
"path_patterns_exempt": [
    "test_",        # Files starting with test_
    "mock_",        # Mock objects
    "_generated",   # Generated files
    "/addons/",     # Third-party addons
    "/tests/",      # Test directories
    ".test.gd"      # Files ending in .test.gd
]
```

## Use Cases

### Legacy Code Migration

```gdscript
# In exemptions config:
"type_check_exempt": [
    "res://src/legacy/player_old.gd",
    "res://src/legacy/inventory_old.gd"
]

# Gradually migrate and remove from exemptions
```

### Third-Party Code

```gdscript
"fully_exempt_files": [
    "res://addons/dialogic/core.gd",
    "res://addons/gut/gut.gd"
]
```

### Test Files

Test files are auto-exempted if they match patterns:
- `test_*.gd`
- `*_test.gd`
- Files in `/tests/` directory

```gdscript
# test_player.gd - automatically exempted
extends GutTest

func test_private_access():
    var player = Player.new()
    # Can access privates in tests
    assert_eq(player.__health, 100)
```

### Debug/Development Tools

```gdscript
"private_var_exempt": [
    "res://src/debug/inspector.gd",
    "res://src/tools/editor_plugin.gd"
]
```

## Best Practices

### 1. Document Exemptions

Always explain why something is exempted:

```gdscript
# EXEMPT: TYPE_CHECK - Legacy API, will be removed in v2.0
var old_data = get_legacy_data()

# EXEMPT: PRIVATE_ACCESS - Debug tool needs internals
var internal = obj.__internal_state
```

### 2. Temporary Exemptions

Mark temporary exemptions with TODOs:

```gdscript
# EXEMPT: TYPE_CHECK - TODO: Add types after DataStore refactor
var temp_storage = DataStore.get_raw()
```

### 3. Minimize Scope

Prefer line-level over file-level exemptions:

```gdscript
# Bad - Exempts entire file
"fully_exempt_files": ["res://src/player.gd"]

# Good - Exempt only what's needed
# EXEMPT: TYPE_CHECK
var legacy_field = old_api.get_data()
```

### 4. Regular Review

Periodically review exemptions:
1. Check if exempted code can be updated
2. Remove unnecessary exemptions
3. Document why remaining exemptions exist

## Migration Workflow

### Step 1: Baseline
Add all existing files to exemptions:
```gdscript
"type_check_exempt": [
    "res://src/old_module1.gd",
    "res://src/old_module2.gd",
    # ... all legacy files
]
```

### Step 2: Gradual Updates
Update files one at a time:
1. Remove file from exemptions
2. Run compile check
3. Fix issues or add line-level exemptions
4. Commit changes

### Step 3: Enforce Standards
New code must pass without exemptions:
- No exemptions in new files
- Code review ensures exemptions are justified
- CI/CD enforces checks

## Complex Exemption Example

```gdscript
extends Node

# Modern, fully typed code
var health: int = 100
var inventory: Array[Item] = []

func take_damage(amount: int) -> void:
    health -= amount

# EXEMPT: TYPE_CHECK - Interfacing with legacy system
func process_legacy_data(data) -> void:
    # Can't type 'data' until LegacySystem is refactored
    var processed = LegacySystem.transform(data)
    
    # Back to typed code
    var result: Dictionary[String, int] = {}
    for key in processed:
        result[key] = processed[key]

# Debug function with special access needs
func debug_inspect(entity: Entity) -> Dictionary:
    var info: Dictionary = {}
    
    # EXEMPT: PRIVATE_ACCESS - Debug inspection needs internals
    info["private_data"] = entity.__internal_state
    info["hidden_field"] = entity.__cached_value
    
    return info

# EXEMPT: ALL - Generated code, do not modify
func _generated_serialize():
    var d = {}
    d["health"] = health
    # ... generated serialization
    return d
```

## Exemption Priority

When multiple exemption rules could apply:
1. Line-level exemptions (highest priority)
2. File-level full exemption
3. File-level specific exemptions
4. Pattern-based exemptions (lowest priority)

## Monitoring Exemptions

Track exemption usage:
```bash
# Count exempted files
grep -r "EXEMPT:" src/ --include="*.gd" | wc -l

# Find all exempted lines
grep -r "EXEMPT:" src/ --include="*.gd"

# List files in exemption config
grep "exempt" godot_compile_check.gd
```

## Removing Exemptions

When removing exemptions:
1. Remove from config file
2. Run compile check
3. Fix all reported issues
4. Test thoroughly
5. Commit both fixes and config change

## Anti-Patterns to Avoid

### ❌ Blanket Exemptions
```gdscript
# Bad - Too broad
"fully_exempt_files": ["res://src/"]
```

### ❌ Permanent "Temporary" Exemptions
```gdscript
# Bad - No plan to fix
# EXEMPT: ALL - TODO: Fix someday
```

### ❌ Undocumented Exemptions
```gdscript
# Bad - No explanation
# EXEMPT: TYPE_CHECK
var mystery = unknown_function()
```

### ✅ Good Exemption
```gdscript
# EXEMPT: TYPE_CHECK - Legacy API returns untyped Array, 
# will be typed after API v2 migration (ticket #1234)
var legacy_items = OldInventory.get_all_items()
```