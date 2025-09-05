# Known Issues

## ~~Property Checker False Positives~~ (FIXED)

**Issue**: ~~The pre-commit property checker shows errors for properties that actually exist in the code.~~

**Status**: ✅ FIXED - Root cause identified and resolved

**Root Cause**: 
The indexer (lean_index.py and project_index.py) was truncating properties at 20 per class with `[:20]` slice.

**Resolution**: 
1. **Indexer Fixed**: Removed the 20-property limit from both indexer scripts
2. **Property Checker Re-enabled**: PROPERTY_EXIT_CODE now included in pre-commit hook
3. **Index Size Impact**: Minimal - only increased by 2KB (3%) to include all 529 properties

The property checker now passes without false positives and validates all properties correctly.

## Temporary Solutions

To commit without the error:
```bash
git commit --no-verify -m "your message"
```

Or edit `.git/hooks/pre-commit` line 55 to exclude PROPERTY_EXIT_CODE from the check.