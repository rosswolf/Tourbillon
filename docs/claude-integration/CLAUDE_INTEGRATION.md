# Claude GitHub Integration Documentation

## Overview

This repository uses an enhanced Claude integration system with session persistence for 10x faster responses after initial setup.

## Quick Start

### First Time Setup
```bash
# Create the repository parent session (one-time, 5-10 minutes)
./manage-parent-session.sh create
```

### Check Status
```bash
# See if parent session exists and get info
./manage-parent-session.sh info
```

### Manual Management
```bash
# Edit the context file that Claude reads
./manage-parent-session.sh context

# Recreate parent after major code changes
./manage-parent-session.sh recreate

# Test that it's working
./manage-parent-session.sh test
```

## Architecture

### Two-Tier Session System

```
Repository Parent Session (created once)
    ├── Reads PARENT_CONTEXT.md for repository knowledge
    ├── Loads CLAUDE.md for development guidelines
    ├── Runs indexer and loads PROJECT_INDEX.json
    ├── Has full repository access
    └── Shared by ALL GitHub interactions
           │
           ├── Issue #1 Child Agent (30s fork)
           ├── Issue #2 Child Agent (30s fork)
           ├── PR Review Agent (30s fork)
           └── Any future agents (30s fork)
```

### Performance Characteristics

| Operation | Old System | New System |
|-----------|------------|------------|
| First @claude mention | 5-7 minutes | 5-10 minutes (creates parent) |
| Subsequent mentions (same issue) | 5-7 minutes | 30 seconds |
| Different issue/PR | 5-7 minutes | 30 seconds |
| After repository restart | 5-7 minutes | 30 seconds |

## How It Works

### 1. Parent Session Creation (One-Time)

When the first @claude mention occurs (or when you manually create):

1. **Indexer runs** - Analyzes codebase structure
2. **Context loaded** - Reads PARENT_CONTEXT.md
3. **Guidelines loaded** - Reads CLAUDE.md
4. **Deep learning** - Claude reads entire codebase
5. **Session saved** - Stored as `parent-repo-castlebuilder`

### 2. Child Agent Forking (Every Request)

For each @claude mention:

1. **Check parent exists** - Creates if missing
2. **Fork child** - Inherits all parent knowledge (30s)
3. **Add issue context** - Includes conversation history
4. **Execute task** - With full understanding
5. **Respond** - Posts to GitHub

### 3. Session Persistence

- Parent session persists on the self-hosted runner
- Survives between GitHub Actions runs
- Shared across all issues and PRs
- Only recreated when manually requested

## Files and Components

### Core Files

| File | Purpose |
|------|---------|
| `.github/workflows/claude-enhanced.yml` | Enhanced workflow with sessions |
| `.github/workflows/claude-self-hosted.yml` | Original workflow (backup) |
| `.github/scripts/session_manager.sh` | Session orchestration logic |
| `manage-parent-session.sh` | Manual parent management |
| `PARENT_CONTEXT.md` | Repository knowledge for parent |
| `PARENT_SESSION_GUIDE.md` | User documentation |
| `GITHUB_CLAUDE_ARCHITECTURE.md` | Technical architecture details |

### Context Files Loaded

1. **PARENT_CONTEXT.md** - Custom repository knowledge
   - Project overview and current state
   - Known issues and decisions
   - Performance hotspots and fragile areas
   - Deep learning instructions

2. **CLAUDE.md** - Development guidelines
   - Coding standards
   - Patterns and conventions
   - Project-specific rules

3. **PROJECT_INDEX.json** - Codebase structure
   - All functions and methods
   - Call relationships
   - File organization

## Managing Parent Context

### Edit Context
```bash
# Opens PARENT_CONTEXT.md in your editor
./manage-parent-session.sh context
```

### What to Include in PARENT_CONTEXT.md

- **Project Overview** - What is this repository?
- **Current State** - What works, what doesn't?
- **Key Decisions** - Why things are done certain ways
- **Known Issues** - Bugs, technical debt, gotchas
- **Performance Notes** - Hotspots, optimization areas
- **Future Direction** - Planned features, refactoring
- **Team Conventions** - Unwritten rules, preferences

### When to Recreate Parent

Recreate the parent session when:

1. **Major code changes** - New features, refactoring
2. **Architecture evolution** - New patterns, frameworks
3. **Context updates** - After editing PARENT_CONTEXT.md
4. **Monthly refresh** - Keep knowledge current
5. **Performance issues** - If responses seem confused

## Workflows

### Enhanced Workflow (`claude-enhanced.yml`)

Features:
- Repository-wide parent session
- Fast child agent forking
- Session persistence
- Automatic indexing
- Context file loading

Triggers:
- Issue comments with @claude
- Pull request comments with @claude
- New issues/PRs with @claude in body

### Original Workflow (`claude-self-hosted.yml`)

Features:
- Stateless operation
- Full context rebuild each time
- No session management
- Direct Claude CLI usage

Status: Kept as backup

## Troubleshooting

### Parent Session Missing
```bash
# Check status
./manage-parent-session.sh info

# Create if missing
./manage-parent-session.sh create
```

### Slow Responses
```bash
# Verify parent exists
./manage-parent-session.sh info

# If missing, create it
./manage-parent-session.sh create
```

### Confused/Wrong Responses
```bash
# Recreate with fresh knowledge
./manage-parent-session.sh recreate
```

### After Major Changes
```bash
# Update the index
/index --full

# Edit context if needed
./manage-parent-session.sh context

# Recreate parent
./manage-parent-session.sh recreate
```

## Best Practices

### 1. Pre-Create Parent Session
```bash
# At start of development day
./manage-parent-session.sh create
```
This ensures fast responses when the team needs them.

### 2. Keep Context Updated
- Edit PARENT_CONTEXT.md when project evolves
- Document new patterns and decisions
- Note performance issues and gotchas

### 3. Regular Maintenance
- Recreate parent monthly or after releases
- Update context with lessons learned
- Remove outdated information

### 4. Monitor Performance
- First response after parent creation: ~30 seconds
- If slower, check parent exists
- If confused, recreate parent

## Advanced Usage

### Direct Session Management
```bash
# List all Claude sessions
claude --list-sessions

# Check specific session
.github/scripts/session_manager.sh exists parent-repo-castlebuilder

# Get session metadata
.github/scripts/session_manager.sh info parent-repo-castlebuilder

# Clean old sessions
.github/scripts/session_manager.sh cleanup 7
```

### Manual Child Fork
```bash
# Fork a child for testing
.github/scripts/session_manager.sh fork-child \
  parent-repo-castlebuilder \
  general \
  "Test request" \
  "Issue context"
```

### Session Artifacts
GitHub Actions stores session artifacts for 7 days:
- conversation.txt
- response.md
- parent_session_repo.txt

## Migration from Old System

1. **Both workflows coexist** - No immediate changes needed
2. **Test enhanced workflow** - Mention @claude in test issue
3. **Monitor performance** - Should be 10x faster after parent
4. **Switch when ready** - Disable old workflow if desired

## Security Considerations

- Parent session has full repository knowledge
- Sessions stored locally on self-hosted runner
- No sensitive data in PARENT_CONTEXT.md
- Use `--dangerously-skip-permissions` flag carefully

## Future Enhancements

Potential improvements:
- Multiple specialized parents for different domains
- Parent session versioning
- Automatic parent refresh on schedule
- Session analytics and monitoring
- Cloud session storage for persistence

## Support

For issues or questions:
- Check PARENT_SESSION_GUIDE.md for user guide
- Review GITHUB_CLAUDE_ARCHITECTURE.md for technical details
- Create issue in repository for bugs
- Edit PARENT_CONTEXT.md to document solutions