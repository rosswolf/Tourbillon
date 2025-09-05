# Smart Godot Compilation Check

## Overview
A robust compilation checking system that handles Godot-specific patterns like autoload dependencies and enum references while still catching real errors.

## Features
- **Smart Autoload Resolution**: Analyzes and resolves autoload dependencies to avoid false positives
- **Enum Registry**: Tracks all enums across the project for proper validation
- **Common Typo Detection**: Catches common mistakes like `slef` instead of `self`
- **Pattern-Based Exemptions**: Respects existing exemption patterns in your code
- **Two-Phase Checking**: Type safety + compilation validation

## Usage

### Quick Check
```bash
# From project root
./elastic-app/app/compile_check.sh
```

### Options
```bash
# Skip type safety checks (faster)
./elastic-app/app/compile_check.sh --skip-type

# Only run type safety
./elastic-app/app/compile_check.sh --type-only  

# Only run compilation checks
./elastic-app/app/compile_check.sh --compile-only

# Verbose output
./elastic-app/app/compile_check.sh --verbose
```

### Direct Godot Check
```bash
# Run the smart compilation check directly
godot --headless --script smart_compile_check.gd
```

## What It Checks

### Real Errors It Catches
- Typos in common keywords (`slef`, `pritn`, `fucn`, etc.)
- Calling non-existent methods (like `set_map()` on MapCore)
- Missing colons after function definitions
- Invalid function signatures
- Deprecated method calls

### What It Intelligently Handles
- Autoload enum dependencies (no more false positives!)
- Cross-file enum references
- Circular autoload dependencies (with warnings)
- Class_name declarations and their usage

## Architecture

### Three-Phase Process
1. **Type Registry Building**: Scans all files for enums and class_name declarations
2. **Autoload Verification**: Checks autoloads with dependency resolution
3. **Script Validation**: Validates all project scripts for common errors

### Smart Features
- **Topological sorting** of autoloads based on dependencies
- **Pattern matching** for common typos and mistakes
- **Exemption support** for legacy code or intentional violations
- **Regex-based** error detection with line number reporting

## Integration

### Pre-commit Hook
To re-enable in your pre-commit hook, change line 549 in `check_type_safety.py`:
```python
# From:
if False:  # Compilation check disabled

# To:
if not args.skip_compile:  # Compilation check enabled
```

### CI/CD
Add to `.github/workflows/deploy-web.yml`:
```yaml
- name: Run Compilation Check
  run: |
    cd elastic-app/app
    ./compile_check.sh
```

## Exemptions

### In-Code Exemptions
```gdscript
# EXEMPT: Intentional pattern
some_unusual_code()  # This line will be skipped

#STYLEOVERRIDE (reason)
untyped_variable = "value"
```

### File-Level Exemptions
Files matching these patterns are automatically skipped:
- `test_*`
- `*_test.gd`
- `mock_*`
- `*_mock.gd`
- Files in `addons/`
- Files in `.godot/`

## Troubleshooting

### "Circular dependency detected"
This warning indicates autoloads that depend on each other. While Godot can handle this at runtime, consider refactoring to reduce coupling.

### Many regex errors in output
These are from Godot trying to compile scripts in headless mode without full project context. The important results are shown before these errors. Focus on the summary section.

### Script won't run
Ensure Godot is in your PATH:
```bash
which godot  # Should show path to Godot executable
```

## Benefits Over Previous System

1. **Handles Autoload Enums**: No more disabling checks because of valid enum references
2. **Smarter Dependency Resolution**: Understands the relationships between files
3. **Better Error Messages**: Clear, actionable feedback with line numbers
4. **Faster Execution**: Efficient scanning and caching of type information
5. **No False Positives**: Intelligently distinguishes between real errors and valid Godot patterns

## Future Improvements
- Cache type registry between runs for faster checks
- Add more sophisticated undefined variable checking
- Integrate with Godot's LSP for even better validation
- Add custom rule configuration file support