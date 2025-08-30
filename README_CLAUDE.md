# Claude Integration - Quick Reference

This repository has enhanced Claude GitHub integration with 10x faster responses.

## For Users

### Mention @claude in Any Issue/PR
```
@claude help me fix this bug
@claude create a pull request for the changes we discussed
@claude review this code
```

**First response:** 5-10 minutes (creates parent session)  
**All subsequent responses:** 30 seconds (uses cached knowledge)

## For Developers

### Setup (One-Time)
```bash
# Create the repository parent session
./manage-parent-session.sh create
```

### Manage Context
```bash
# Edit what Claude knows about the repository
./manage-parent-session.sh context

# Recreate after major changes
./manage-parent-session.sh recreate
```

### Check Status
```bash
./manage-parent-session.sh info
```

## How It Works

1. **Parent Session** (created once) - Understands entire codebase
2. **Child Agents** (per request) - Fork from parent with issue context
3. **Fast Responses** - 30 seconds instead of 5-7 minutes

## Documentation

- **Quick Start:** This file
- **User Guide:** [PARENT_SESSION_GUIDE.md](PARENT_SESSION_GUIDE.md)
- **Full Documentation:** [docs/CLAUDE_INTEGRATION.md](docs/CLAUDE_INTEGRATION.md)
- **Architecture:** [GITHUB_CLAUDE_ARCHITECTURE.md](GITHUB_CLAUDE_ARCHITECTURE.md)
- **Repository Context:** [PARENT_CONTEXT.md](PARENT_CONTEXT.md)

## Key Commands

```bash
# Manual parent management
./manage-parent-session.sh [info|create|recreate|test|context]

# Check integration status
./manage-parent-session.sh info

# Test it's working
./manage-parent-session.sh test
```

## Files

- `.github/workflows/claude-enhanced.yml` - Enhanced workflow
- `.github/scripts/session_manager.sh` - Session logic
- `PARENT_CONTEXT.md` - Knowledge Claude inherits
- `manage-parent-session.sh` - Management tool