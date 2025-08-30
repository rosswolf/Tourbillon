# Parent Session Management Guide

## Quick Start

The repository parent session is the foundation of the enhanced Claude integration. It's created **once** and shared by **all** GitHub interactions.

### Check Status
```bash
./manage-parent-session.sh info
```

### Create Parent Session (First Time)
```bash
./manage-parent-session.sh create
```
This takes 5-10 minutes and:
- Runs the code indexer
- Analyzes entire codebase
- Creates comprehensive knowledge base

### Test It's Working
```bash
./manage-parent-session.sh test
```

### Recreate When Needed
```bash
./manage-parent-session.sh recreate
```

## When to Recreate the Parent

Recreate the parent session when:

1. **Major Architecture Changes**
   - New frameworks or libraries added
   - Significant refactoring completed
   - Project structure reorganized

2. **Project Evolution**
   - After merging large feature branches
   - When switching development focus
   - After major dependency updates

3. **Performance Issues**
   - If child agents seem confused
   - After clearing Claude sessions
   - If responses become inconsistent

4. **Regular Maintenance**
   - Monthly refresh (optional)
   - After major releases
   - When onboarding new team members

## How It Works

```
Repository Parent Session (created once)
    ├── Complete codebase knowledge
    ├── All architectural patterns
    ├── Project guidelines (CLAUDE.md)
    ├── Indexed code structure
    └── Shared by ALL issues/PRs
           │
           ├── Issue #1 Child Agent (30s fork)
           ├── Issue #2 Child Agent (30s fork)
           ├── PR #10 Review Agent (30s fork)
           └── Issue #15 Child Agent (30s fork)
```

## Manual Commands

### Create Parent Now (Without Waiting for GitHub Trigger)
```bash
# Navigate to repository
cd /home/rosswolf/Code/castlebuilder

# Create the parent session manually
./manage-parent-session.sh create
```

### Delete and Start Fresh
```bash
# Remove existing parent
./manage-parent-session.sh delete

# Create new parent
./manage-parent-session.sh create
```

### Advanced: Direct Session Management
```bash
# List all Claude sessions
claude --list-sessions

# Check specific session
.github/scripts/session_manager.sh exists parent-repo-castlebuilder

# Get session info
.github/scripts/session_manager.sh info parent-repo-castlebuilder
```

## Troubleshooting

### Parent Session Not Found
```bash
# Check if it exists
./manage-parent-session.sh info

# Create if missing
./manage-parent-session.sh create
```

### Child Agents Slow or Confused
```bash
# Recreate parent with fresh knowledge
./manage-parent-session.sh recreate
```

### After Major Code Changes
```bash
# Update the index first
/index --full

# Then recreate parent
./manage-parent-session.sh recreate
```

## Session Lifecycle

1. **Creation**: One-time 5-10 minute process
2. **Usage**: Shared by all GitHub agents
3. **Persistence**: Survives across GitHub runs
4. **Updates**: Manual recreation when needed
5. **Deletion**: Only when explicitly deleted

## Best Practices

1. **Create parent session before active development**
   - Run `./manage-parent-session.sh create` at start of day
   - Ensures fast responses when team needs them

2. **Test after creation**
   - Run `./manage-parent-session.sh test`
   - Verify it understands the codebase

3. **Document recreation**
   - Note when and why parent was recreated
   - Helps track knowledge freshness

4. **Monitor performance**
   - If responses slow down, check parent exists
   - If responses are confused, recreate parent

## Integration with GitHub

The enhanced workflow (`claude-enhanced.yml`) automatically:
1. Checks for parent session on each @claude mention
2. Creates it if missing (first run only)
3. Forks child agents with issue context
4. Delivers fast, informed responses

You don't need to manually create the parent - it happens automatically. But having manual control lets you:
- Pre-create for faster first response
- Recreate when code changes significantly
- Test and verify functionality
- Troubleshoot any issues

## Summary

- **Automatic**: Parent created on first @claude mention
- **Manual Control**: Use `manage-parent-session.sh` anytime
- **Persistent**: Survives between GitHub runs
- **Shared**: All agents inherit its knowledge
- **Fast**: 30-second child agent creation after parent exists