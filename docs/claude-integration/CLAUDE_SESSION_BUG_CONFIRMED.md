# Claude Session Persistence Bug - CONFIRMED

## Date: August 31, 2025

## Executive Summary

After extensive testing, we've **confirmed the Claude CLI session persistence bug**. The exact error is:

```
No conversation found with session ID: 25fd8500-045a-4a40-bb74-f1f9e60e46ce
```

This occurs even though:
- The session file exists (314KB, 101 lines)
- The file is readable and in the correct location
- The same command works perfectly locally

## The Bug

**What we thought would work:**
```bash
echo "message" | claude --print --resume SESSION_ID
```

**What actually happens:**
- Works perfectly in local/interactive environment ✅
- Fails in GitHub Actions with "No conversation found" ❌
- Same user, same files, different result

## Root Cause Analysis

The Claude CLI session mechanism appears to use more than just the JSONL files. Possible causes:

1. **Environment-specific validation** - Sessions may be tied to specific environment variables or system identifiers
2. **User context binding** - Sessions might be cryptographically tied to the creating user's context
3. **Hidden state files** - There may be additional state files we haven't discovered
4. **In-memory components** - Some session data might not be persisted to disk

## Testing Results

### Test 1-7: Various Approaches
All attempts to resume the session in GitHub Actions failed with the same error:
- ❌ With `--print --resume`
- ❌ Without `--model opus`
- ❌ Without `--add-dir`
- ❌ With proper session file in place
- ❌ With all permissions correct

### Error Messages Captured
```
Error log: No conversation found with session ID: 25fd8500-045a-4a40-bb74-f1f9e60e46ce
Exit code: 1
```

## Confirmed Workaround

Use direct Claude calls without session resumption:

```yaml
# Instead of this (doesn't work):
echo "$REQUEST" | claude --print --resume "$SESSION_ID"

# Use this (works but slower):
echo "$REQUEST" | claude --add-dir "$WORKSPACE"
```

**Performance Impact:**
- With session: Would be <30 seconds
- Without session: 90-120 seconds
- 3-4x slower, but functional

## What We Learned

1. **The `--print` flag is required** for non-interactive mode
2. **Session files alone are insufficient** - Claude needs additional context
3. **The bug is consistent** - Not a intermittent issue
4. **Fallback is necessary** - Must have non-session alternative

## Recommendations

### Immediate Action
Continue using direct Claude calls without session resumption. The system works, just slower.

### Long-term Solutions

1. **File bug report with Anthropic** including:
   - Exact error message
   - Reproduction steps
   - Session file analysis

2. **Alternative approaches to explore:**
   - Claude Code SDK (may have better session handling)
   - API with custom session management
   - GitHub-hosted runner (different environment)

3. **Potential workarounds:**
   - Create sessions within GitHub Actions (not just resume)
   - Use GitHub artifacts to store conversation context
   - Implement custom context management

## Files Updated

- `.github/workflows/claude-session.yml` - Reverted to direct calls with documentation
- `docs/CLAUDE_SESSION_BUG_CONFIRMED.md` - This report
- Previous investigation files remain for reference

## Conclusion

The session persistence bug is **real and reproducible**. The feature works locally but fails in CI/CD environments with "No conversation found" error, even with identical session files.

**Current Status:** Working with degraded performance (90-120s vs target <30s)
**Root Cause:** Claude CLI session validation fails across environments
**Workaround:** Direct Claude calls without session resumption
**Impact:** 3-4x slower but fully functional