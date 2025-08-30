# Enhanced Claude GitHub Workflow - Detailed Status Report

## Executive Summary
We've been implementing an enhanced GitHub Actions workflow with a parent-child session architecture to achieve 10x faster Claude responses (from 5-7 minutes down to 30 seconds). The system is 90% working but has a critical issue: sessions created locally work perfectly, but aren't accessible from the GitHub Actions environment.

## What We're Building

### Architecture: Parent-Child Session System
```
Repository Parent Session (UUID-based, created once)
    ├── Contains full codebase knowledge
    ├── Loads PARENT_CONTEXT.md and CLAUDE.md
    ├── Persists across all GitHub interactions
    └── Child Agents Fork From Parent (30 second responses)
           ├── Issue Comments
           ├── Pull Request Reviews
           └── Any GitHub Event
```

## What's Been Done

### 1. **Fixed Workflow Syntax Issues** ✅
- Unclosed JavaScript script blocks in YAML
- Changed `|` to `>` for multi-line conditions
- Fixed `parseInt()` for issue numbers
- Properly closed all script blocks

### 2. **Implemented UUID-Based Sessions** ✅
- Claude CLI requires UUIDs, not plain strings
- Created mapping system: `~/.claude/sessions/uuid_map.txt`
- Maps human names to UUIDs: `parent-repo-castlebuilder:eb663f5f-6455-4161-bf88-a7b8bedc6994`

### 3. **Created Core Components** ✅

**Files Created/Modified:**
- `.github/workflows/claude-enhanced-v2.yml` - Main enhanced workflow
- `.github/scripts/session_manager.sh` - Handles parent/child session operations
- `manage-parent-session.sh` - Manual parent management tool
- `PARENT_CONTEXT.md` - Repository knowledge for parent
- `create_parent_now.sh` - Quick parent creation script

### 4. **Successfully Created Parent Session** ✅
- **UUID:** `eb663f5f-6455-4161-bf88-a7b8bedc6994`
- **Status:** Active and verified locally
- **Can resume:** Yes, tested successfully

## The Current Problem

### Issue: "No conversation found with session ID"

**What Works:**
```bash
# Manually from command line - WORKS
claude --resume eb663f5f-6455-4161-bf88-a7b8bedc6994 --print "test"
# Output: Success

# Manual fork - WORKS
.github/scripts/session_manager.sh fork-child "eb663f5f-6455-4161-bf88-a7b8bedc6994" "general" "Test" "Context"
# Output: Successfully creates PRs
```

**What Fails:**
```bash
# In GitHub Actions - FAILS
# Same commands return: "No conversation found with session ID: eb663f5f-6455-4161-bf88-a7b8bedc6994"
```

### Error Pattern from Actions Logs:
```
Fork exit code: 1
Output preview: Forking child agent: 402d08d6-4997-4732-8464-a802a7af12e9 (type: general)
Executing child agent with inherited context...
No conversation found with session ID: eb663f5f-6455-4161-bf88-a7b8bedc6994...
```

## Key Technical Details

### Session Storage Locations:
- **UUID Mapping:** `~/.claude/sessions/uuid_map.txt`
- **Session Files:** `~/.claude/todos/{uuid}*.json`
- **Session Metadata:** `~/.claude/sessions/{uuid}.info`

### Claude CLI Behavior:
- Requires valid UUIDs for `--session-id`
- Cannot use `--session-id` with `--resume` (they conflict)
- Sessions must be created with content to be resumable

### Workflow Execution Context:
- Runs on self-hosted runner with label `claude-pro`
- User: `rosswolf`
- Has Claude CLI installed at `/home/rosswolf/.npm-global/bin/claude`

## Hypothesis About Root Cause

The session files are stored in the user's home directory (`~/.claude/`), but GitHub Actions might be:

1. **Running with different HOME environment variable**
   - Actions might override HOME temporarily
   - Session files might be looked up in wrong location

2. **Permission/Isolation Issue**
   - Actions runner might isolate file access
   - Claude CLI might not have access to session files

3. **Session State Persistence**
   - Sessions might be in-memory and not persisted properly
   - File-based session storage might not be working as expected

## Next Debugging Steps

### 1. **Environment Investigation** (Added debug output)
```bash
echo "Current user: $(whoami)"
echo "Home directory: $HOME"
echo "Claude sessions directory: $(ls -la ~/.claude/sessions)"
echo "Session files: $(ls ~/.claude/todos/eb663f5f*)"
```

### 2. **Check Claude's Session Lookup**
- Verify where Claude is looking for sessions
- Check if it's using absolute vs relative paths
- Test with explicit paths instead of `~`

### 3. **Test Session Creation in Actions**
- Try creating a new session within the Actions workflow
- See if that session can be resumed in the same workflow run

### 4. **Alternative Approaches If Needed**
- Store session state in GitHub artifacts/cache
- Use a different session persistence mechanism
- Create parent inline for each workflow run (slower but works)

## Critical Files for Reference

### Session Manager Key Functions:
```bash
# Check if session exists (line 33-37)
session_exists() {
    local session_uuid="$1"
    ls ~/.claude/todos/${session_uuid}*.json >/dev/null 2>&1
}

# Fork child from parent (line 189-290)
fork_child_agent() {
    $CLAUDE_CMD --model opus \
        --resume "$parent_uuid" \
        --print "$child_prompt" \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions
}
```

### V2 Workflow Fork Logic (line 133-157):
```bash
if [ -n "$PARENT_UUID" ] && [[ "$PARENT_UUID" =~ ^[a-f0-9]{8}-... ]]; then
    OUTPUT=$(.github/scripts/session_manager.sh fork-child ...)
    if [ $FORK_EXIT -ne 0 ] || echo "$OUTPUT" | grep -q "No conversation found"; then
        echo "Fork had issues, using fallback..."
    fi
fi
```

## Success Metrics
- Parent session created once, persists forever ✅ (locally)
- Child agents fork in ~30 seconds ✅ (locally)
- Works in GitHub Actions environment ❌ (current issue)
- Provides Claude responses with full context ✅ (when working)

## Summary
The enhanced workflow architecture is solid and works perfectly in local testing. The single remaining issue is that Claude sessions created in the local environment aren't accessible from the GitHub Actions runtime, likely due to environment or path differences. Once we solve this session visibility issue, the system will be fully operational.