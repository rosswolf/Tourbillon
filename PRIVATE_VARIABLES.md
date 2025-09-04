# Private Variable Convention

## Overview
This codebase enforces strict encapsulation for private variables. Variables prefixed with double underscores (`__`) are considered private and cannot be accessed from outside their defining class.

## Convention Rules

### Private Variables
- **Naming**: Private variables must start with `__` (double underscore)
- **Access**: Can ONLY be accessed within the same class
- **Enforcement**: Compile-time checking via `godot_compile_check.gd`

### Examples

**Good - Proper Encapsulation:**
```gdscript
class_name Card

var __instinct_effect: MoveDescriptorEffect  # Private
var display_name: String  # Public

func has_instinct_effect() -> bool:
    # OK: Accessing own private variable
    return __instinct_effect != null

func get_effect() -> MoveDescriptorEffect:
    # OK: Exposing via public interface
    return __instinct_effect
```

**Bad - Violation:**
```gdscript
class_name GameManager

func process_card(card: Card) -> void:
    # ERROR: Cannot access private variable from another class!
    if card.__instinct_effect != null:  # ❌ VIOLATION
        card.__instinct_effect.activate()  # ❌ VIOLATION
    
    # CORRECT: Use public interface
    if card.has_instinct_effect():  # ✅ OK
        card.activate_instinct_effect()  # ✅ OK
```

## Compile Check Hook

The `godot_compile_check.gd` script automatically detects violations:

1. Direct access to private variables: `object.__private_var`
2. Method calls on private variables: `object.__private_var.method()`

**Error Output:**
```
[COMPILE CHECK] ❌ ERRORS FOUND:
  res://src/game.gd:42 - Illegal access to private variable '__instinct_effect' of object 'card'. Private variables (prefixed with __) cannot be accessed from other classes.
```

## Benefits

1. **Clear Interfaces**: Forces explicit public APIs
2. **Better Encapsulation**: Implementation details stay hidden
3. **Easier Refactoring**: Private implementation can change without breaking other code
4. **Compile-Time Safety**: Violations caught before runtime

## Migration Guide

If you have existing code accessing private variables:

1. Add a public getter method:
   ```gdscript
   func get_effect() -> MoveDescriptorEffect:
       return __instinct_effect
   ```

2. Add a public checker method:
   ```gdscript
   func has_effect() -> bool:
       return __instinct_effect != null
   ```

3. Add public action methods:
   ```gdscript
   func activate_effect() -> bool:
       if __instinct_effect:
           return __instinct_effect.activate()
       return false
   ```

## Exemptions

Sometimes you need to bypass these checks for legacy code or special cases. The compile check supports several exemption methods:

### Line-Level Exemptions
Add a comment on the line before to exempt the next line:

```gdscript
# EXEMPT: TYPE_CHECK
var untyped_var = "legacy code"

# EXEMPT: PRIVATE_ACCESS  
var private = obj.__private_field  # Normally illegal

# EXEMPT: ALL
func old_function():  # Exempts from all checks

# @compile-check-ignore
var another_way = "to exempt"
```

### File-Level Exemptions
In `godot_compile_check.gd`, add files to exemption lists:

```gdscript
var exemptions = {
    "fully_exempt_files": [
        "res://src/legacy/old_code.gd"  # Skip all checks
    ],
    "type_check_exempt": [
        "res://src/migration/partial.gd"  # Skip type checks only
    ],
    "private_var_exempt": [
        "res://src/special/accessor.gd"  # Allow private access
    ]
}
```

### Pattern-Based Exemptions
Files matching these patterns are automatically exempted:
- `test_*.gd` - Test files
- `mock_*.gd` - Mock objects
- `*_generated.gd` - Generated code

## Running the Check

The compile check runs automatically during CI/CD, but you can run it manually:

```bash
cd elastic-app/app
godot --headless --script godot_compile_check.gd
```