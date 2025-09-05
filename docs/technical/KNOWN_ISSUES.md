# Known Issues

## ~~Property Checker False Positives~~ (FIXED)

**Issue**: ~~The pre-commit property checker shows errors for properties that actually exist in the code.~~

**Status**: ✅ FIXED - Property checker updated to recognize all property types

**Resolution**: 
The property_check.py has been updated to include:
- Godot built-in Control/Button properties (flat, size_flags_horizontal, etc.)
- Card effect properties loaded dynamically from JSON
- Effect subclass private properties

The property checker now passes without false positives.

## Temporary Solutions

To commit without the error:
```bash
git commit --no-verify -m "your message"
```

Or edit `.git/hooks/pre-commit` line 55 to exclude PROPERTY_EXIT_CODE from the check.