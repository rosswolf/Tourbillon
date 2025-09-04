# Claude Customizations for Godot Projects

A collection of reusable hooks, checks, and tools for Godot projects with Claude AI integration.

## Features

### 🔍 Godot Compile Check Hook
A comprehensive GDScript validation tool that enforces:
- **Private variable encapsulation** - No accessing `__prefixed` variables from other classes
- **Type safety** - All variables, parameters, and return types must be typed
- **Method validation** - Detects calls to non-existent methods
- **Flexible exemptions** - Line-level, file-level, and pattern-based exemptions

## Quick Start

### 1. Copy the compile check to your project
```bash
cp godot-hooks/godot_compile_check.gd your-project/
```

### 2. Run the check
```bash
cd your-project
godot --headless --script godot_compile_check.gd
```

### 3. Integrate with CI/CD
Add to your GitHub Actions workflow:
```yaml
- name: Run Godot Compile Check
  run: |
    godot --headless --script godot_compile_check.gd
```

## Directory Structure

```
claude-customizations/
├── godot-hooks/           # Reusable Godot hooks and checks
│   ├── godot_compile_check.gd
│   └── README.md
├── docs/                  # Documentation
│   ├── PRIVATE_VARIABLES.md
│   ├── TYPE_SAFETY.md
│   └── EXEMPTIONS.md
└── examples/              # Example configurations
    ├── exemption_config.gd
    └── ci_workflow.yml
```

## Available Hooks

### godot_compile_check.gd
Full-featured compile-time validation for GDScript projects.

**Features:**
- Private variable access protection
- Type annotation enforcement  
- Custom type validation
- Deprecated method detection
- Flexible exemption system

**Usage:**
```gdscript
# Add exemptions in the script:
var exemptions = {
    "fully_exempt_files": ["res://legacy/old_code.gd"],
    "type_check_exempt": ["res://migration/partial.gd"],
    "private_var_exempt": ["res://special/accessor.gd"]
}
```

## Integration Guide

### For New Projects

1. Copy the desired hooks to your project
2. Configure exemptions as needed
3. Add to your CI/CD pipeline
4. Document any project-specific exemptions

### For Existing Projects  

1. Start with all legacy files in exemptions
2. Gradually remove files from exemptions as you update them
3. Use line-level exemptions for partial migrations
4. Track progress in your project documentation

## Exemption System

### Line-Level Exemptions
```gdscript
# EXEMPT: TYPE_CHECK
var untyped = "legacy code"

# EXEMPT: PRIVATE_ACCESS
var private = obj.__private_field

# EXEMPT: ALL
func old_function():
    pass
```

### File Patterns
Files matching these patterns are auto-exempted:
- `test_*.gd` - Test files
- `mock_*.gd` - Mock objects
- `*_generated.gd` - Generated code

## Contributing

To add new hooks or improve existing ones:
1. Create your hook in the appropriate directory
2. Add documentation
3. Include examples
4. Test with multiple Godot projects

## License

MIT - Feel free to use in any project

## Support

For questions or issues, please open an issue in the repository.