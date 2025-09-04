# Godot Hooks

Reusable validation and checking hooks for Godot projects.

## godot_compile_check.gd

A comprehensive GDScript validation tool that enforces code quality standards at compile time.

### Features

#### 🔒 Private Variable Protection
- Prevents access to `__prefixed` variables from other classes
- Enforces proper encapsulation
- Detects both direct access and method calls on private variables

#### 📝 Type Safety Enforcement
- **Variables**: All variables must have type annotations
- **Functions**: Return types required (use `-> void` for no return)
- **Parameters**: All function parameters must be typed
- **Arrays**: Encourages `Array[Type]` over untyped `Array`
- **Dictionaries**: Supports `Dictionary[KeyType, ValueType]`

#### 🛠️ Method Validation
- Detects calls to non-existent methods
- Warns about deprecated method usage
- Validates autoload availability

#### 🎯 Flexible Exemptions
- **Line-level**: Exempt specific lines with comments
- **File-level**: Exempt entire files from specific checks
- **Pattern-based**: Auto-exempt test files, mocks, generated code

### Installation

1. Copy `godot_compile_check.gd` to your project root or scripts folder
2. Configure exemptions if needed (edit the `exemptions` dictionary in the script)
3. Run manually or integrate into CI/CD

### Usage

#### Manual Run
```bash
godot --headless --script godot_compile_check.gd
```

#### CI/CD Integration (GitHub Actions)
```yaml
- name: Godot Compile Check
  run: |
    godot --headless --script godot_compile_check.gd
  continue-on-error: false  # Fail the build on errors
```

### Configuration

Edit the `exemptions` dictionary in the script:

```gdscript
var exemptions = {
    # Complete exemption from all checks
    "fully_exempt_files": [
        "res://src/legacy/old_system.gd",
        "res://addons/third_party/plugin.gd"
    ],
    
    # Exempt from type checking only
    "type_check_exempt": [
        "res://src/migration/partial.gd"
    ],
    
    # Exempt from private variable checks only
    "private_var_exempt": [
        "res://src/special/reflection.gd"
    ],
    
    # Auto-exempt files matching these patterns
    "path_patterns_exempt": [
        "test_",      # Test files
        "mock_",      # Mock objects
        "_generated", # Generated code
        "res://addons/"  # Third-party addons
    ],
    
    # Line exemption markers
    "line_exemption_markers": [
        "# EXEMPT: TYPE_CHECK",
        "# EXEMPT: PRIVATE_ACCESS", 
        "# EXEMPT: ALL",
        "# @compile-check-ignore"
    ]
}
```

### Exemption Examples

#### Line-Level Exemptions
```gdscript
# EXEMPT: TYPE_CHECK
var untyped_variable = "legacy code"  # Won't error

# EXEMPT: PRIVATE_ACCESS
func access_private(obj: MyClass) -> void:
    var data = obj.__private_data  # Normally illegal, but exempted

# EXEMPT: ALL
func completely_exempt():  # No checks on this function
    var x = y.__z
```

#### Inline Exemptions
```gdscript
var legacy = "old"  # @compile-check-ignore
```

### Error Messages

The hook provides clear, actionable error messages:

```
[COMPILE CHECK] ❌ ERRORS FOUND:
  res://src/game.gd:42 - Variable 'count' is missing type annotation. Should be: var count: Type = value
  res://src/player.gd:15 - Function 'update' is missing return type annotation. Add '-> Type' or '-> void'
  res://src/enemy.gd:73 - Illegal access to private variable '__health' of object 'player'. Private variables (prefixed with __) cannot be accessed from other classes.
```

### Exit Codes

- **0**: All checks passed
- **1**: Errors found (build should fail)
- **0**: Only warnings found (build continues)

### Customization

To add new checks:

1. Add a new check function:
```gdscript
func _check_my_rule(line: String, line_num: int, script_path: String) -> void:
    if "bad_pattern" in line:
        errors_found.append(script_path + ":" + str(line_num) + " - My custom error")
```

2. Call it from `_check_source_for_errors()`:
```gdscript
# 5. My custom check
if not is_line_exempt:
    _check_my_rule(line, line_num, script_path)
```

### Performance

The script is optimized for CI/CD environments:
- Runs in headless mode (no GUI)
- Processes files in a single pass
- Minimal memory footprint
- Fast regex-based parsing

### Limitations

- Cannot detect runtime type errors
- Custom class detection requires `class_name` declaration
- Some Godot built-in types might need to be added to the valid types list

### Troubleshooting

**Script fails to load:**
- Ensure Godot 4.x is installed
- Check file path is correct
- Verify project has a valid project.godot

**Too many false positives:**
- Add legitimate exceptions to exemptions
- Check if third-party code needs exempting
- Consider using line-level exemptions for edge cases

**Not catching errors:**
- Verify the file is being scanned (not in exemptions)
- Check that regex patterns match your code style
- Ensure error patterns are up to date