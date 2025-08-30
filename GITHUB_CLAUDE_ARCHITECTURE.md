# GitHub Claude Integration Architecture

## Table of Contents
1. [Current Implementation](#current-implementation)
2. [Limitations](#limitations)
3. [Proposed Enhancement: Context Inheritance System](#proposed-enhancement-context-inheritance-system)
4. [Implementation Plan](#implementation-plan)
5. [Technical Considerations](#technical-considerations)

---

## Current Implementation

### Overview
The current GitHub Claude integration uses GitHub Actions to respond to issue comments and PR reviews when `@claude` is mentioned. It runs on a self-hosted runner with Claude Code CLI installed locally.

### Architecture Flow

```
User Comment (@claude)
    ↓
GitHub Webhook
    ↓
GitHub Actions Workflow (claude-self-hosted.yml)
    ↓
Self-Hosted Runner
    ├── 1. Checkout Repository
    ├── 2. Check if Claude Should Respond
    ├── 3. Build Conversation History
    ├── 4. Create context.txt with:
    │   ├── Project guidelines (CLAUDE.md)
    │   ├── Full issue/PR history
    │   └── Task instructions
    ├── 5. Execute Claude CLI:
    │   └── claude --model opus --print "$(cat context.txt)" \
    │       --add-dir /path/to/repo \
    │       --dangerously-skip-permissions
    └── 6. Post Response to GitHub
```

### Key Components

#### 1. **Trigger Mechanism**
- Triggered by `issue_comment` and `pull_request_review_comment` events
- Checks for `@claude` mentions or previous Claude engagement
- Runs on self-hosted runner with `claude-pro` label

#### 2. **Context Building**
- Fetches entire issue/PR conversation history
- Includes project-specific guidelines (CLAUDE.md)
- Adds instructions about GitHub capabilities (git, gh CLI)
- Creates monolithic context.txt file (~100-1000+ lines)

#### 3. **Claude Execution**
- Uses `--print` flag for non-interactive mode
- Includes `--add-dir` for repository access
- `--dangerously-skip-permissions` for automated operations
- 10-minute timeout for complex requests
- Typically takes 5-7 minutes for responses

#### 4. **Response Handling**
- Captures stdout to response.md
- Error handling for timeouts and failures
- Posts response as GitHub comment

### Current Capabilities
- Read and analyze entire codebase
- Respond to questions about code
- Suggest implementations
- Create branches and pull requests (with instructions)
- Review pull requests

---

## Limitations

### Performance Issues
1. **Long Response Times**: 5-7 minutes per interaction
2. **Context Rebuilding**: Full history processed from scratch each time
3. **No Learning**: Can't build on previous understanding
4. **Redundant Processing**: Re-analyzes codebase for each request

### Session Management
1. **Stateless**: Each request starts fresh
2. **No Context Inheritance**: Can't share knowledge between related tasks
3. **No Specialization**: Can't create task-specific agents
4. **Lost Work**: Previous analysis isn't preserved

### Code Understanding
1. **No Index Integration**: Doesn't use PROJECT_INDEX.json
2. **Brute Force Analysis**: Reads entire directories without targeting
3. **Stale Knowledge**: No automatic index updates
4. **Missing Dependencies**: Can't track what code calls what

---

## Proposed Enhancement: Context Inheritance System

### Conceptual Architecture

```
┌─────────────────────────────────────────┐
│           Parent Session                 │
│  - Project context (CLAUDE.md)          │
│  - Indexed codebase knowledge           │
│  - Issue/PR conversation history        │
│  - Established understanding            │
│  Session ID: parent-{issue-number}      │
└────────────┬───────────────────────────┘
             │ Fork
    ┌────────┴────────┬──────────────┐
    ↓                 ↓              ↓
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Agent 1  │  │ Agent 2  │  │ Agent 3  │
│ Bug Fix  │  │ PR Create│  │ Testing  │
│ Session: │  │ Session: │  │ Session: │
│ child-1  │  │ child-2  │  │ child-3  │
└──────────┘  └──────────┘  └──────────┘
```

### Core Concepts

#### 1. **Parent Session Creation**
- Initialize once per issue/PR when first @claude mention occurs
- Load comprehensive context:
  - Project guidelines (CLAUDE.md)
  - Run indexer and load PROJECT_INDEX.json
  - Full conversation history
  - Codebase structure understanding
- Save session with ID: `parent-issue-{number}`
- Store session ID in GitHub (artifact or comment metadata)

#### 2. **Context Forking**
- Child agents resume from parent session
- Inherit all parent knowledge without reprocessing
- Add task-specific instructions
- Each child gets unique session ID
- Children can be specialized (bug-fix agent, PR-creation agent, etc.)

#### 3. **Index Integration**
```bash
# Before creating parent session
cd /path/to/repo
/index --quick  # Update PROJECT_INDEX.json

# Include in parent context
echo "=== CODEBASE INDEX ===" >> context.txt
cat PROJECT_INDEX.json | jq '.summary' >> context.txt
```

#### 4. **Session Persistence**
- Store session IDs in GitHub Actions artifacts
- Or embed in special HTML comments in responses:
  ```html
  <!-- claude-session: parent-issue-123 -->
  ```

### Workflow Enhancement

```yaml
- name: Initialize or Resume Parent Session
  run: |
    ISSUE_NUMBER=${{ github.event.issue.number }}
    PARENT_SESSION="parent-issue-${ISSUE_NUMBER}"
    
    # Check if parent session exists
    if claude --list-sessions | grep -q "$PARENT_SESSION"; then
      echo "Resuming existing parent session"
      SESSION_FLAG="--resume $PARENT_SESSION"
    else
      echo "Creating new parent session"
      # Run indexer first
      cd /home/rosswolf/Code/castlebuilder
      /index --quick
      
      # Create comprehensive parent context
      cat > parent_context.txt << 'EOF'
      [Project guidelines, index data, conversation history]
      EOF
      
      # Create parent session
      claude --model opus --session-id "$PARENT_SESSION" \
        --print "Initialize context" < parent_context.txt
      SESSION_FLAG="--session-id $PARENT_SESSION"
    fi
    
    echo "SESSION_FLAG=$SESSION_FLAG" >> $GITHUB_ENV

- name: Fork Child Agent for Task
  run: |
    # Determine task type from comment
    TASK_TYPE=$(analyze_comment_for_task_type)
    CHILD_SESSION="child-${ISSUE_NUMBER}-${GITHUB_RUN_ID}"
    
    # Fork from parent with task-specific prompt
    case $TASK_TYPE in
      "pull-request")
        AGENT_PROMPT="You are a PR creation specialist. Create the pull request discussed."
        ;;
      "bug-fix")
        AGENT_PROMPT="You are a bug fix specialist. Fix the identified issue."
        ;;
      *)
        AGENT_PROMPT="Handle this request with your full capabilities."
        ;;
    esac
    
    # Resume parent and continue as child
    claude --model opus ${{ env.SESSION_FLAG }} \
      --continue \
      --session-id "$CHILD_SESSION" \
      --print "$AGENT_PROMPT\n\nUser request: $(cat latest_comment.txt)" \
      --add-dir /home/rosswolf/Code/castlebuilder \
      --dangerously-skip-permissions
```

---

## Implementation Plan

### Phase 1: Session Management Infrastructure
1. **Modify workflow to detect existing sessions**
   - Add session listing check
   - Store session IDs in artifacts
   - Implement session ID extraction from comments

2. **Create parent session initialization**
   - Run indexer before first interaction
   - Build comprehensive initial context
   - Save session with predictable ID

### Phase 2: Context Forking
1. **Implement child session creation**
   - Resume from parent session
   - Add task-specific instructions
   - Maintain session genealogy

2. **Task specialization**
   - Detect task type from comment
   - Apply appropriate agent personality
   - Use focused prompts

### Phase 3: Index Integration
1. **Automatic indexing**
   - Run `/index --quick` before parent creation
   - Include index summary in context
   - Update index when repository changes

2. **Smart context loading**
   - Use index to identify relevant files
   - Load only necessary context for child agents
   - Query index for method signatures and dependencies

### Phase 4: Performance Optimization
1. **Response time improvements**
   - Parent session: One-time 5-minute setup
   - Child agents: 30-second startup (resume existing context)
   - Parallel child agents for complex tasks

2. **Context pruning**
   - Remove redundant information for child agents
   - Focus on task-specific context
   - Use index for targeted file loading

---

## Technical Considerations

### Session Storage
- **Local Storage**: Sessions stored in `~/.claude/sessions/` on runner
- **Persistence Risk**: Runner restarts lose sessions
- **Mitigation**: Store session artifacts in GitHub Actions cache

### Session Size Limits
- Parent sessions may grow large (100MB+)
- Consider periodic parent session refresh
- Implement context window management

### Concurrency
- Multiple child agents could run simultaneously
- Need session locking mechanism
- Consider queue system for sequential tasks

### Index Freshness
- Index becomes stale as code changes
- Need triggers for re-indexing:
  - On PR merge
  - Before parent session creation
  - Periodic refresh (daily?)

### Security Considerations
- Sessions contain full codebase knowledge
- Ensure sessions aren't exposed in logs
- Clean up old sessions periodically

### Monitoring and Debugging
```yaml
- name: Session Diagnostics
  run: |
    echo "=== Active Sessions ==="
    claude --list-sessions
    
    echo "=== Session Sizes ==="
    du -sh ~/.claude/sessions/*
    
    echo "=== Index Freshness ==="
    stat PROJECT_INDEX.json
```

---

## Benefits of Enhancement

### Performance Gains
- **Initial Response**: Still 5-7 minutes (parent creation)
- **Subsequent Responses**: 30-60 seconds (child agents)
- **Parallel Processing**: Multiple agents working simultaneously
- **Cached Understanding**: No repeated analysis

### Improved Capabilities
- **Contextual Awareness**: Agents understand previous discussions
- **Task Specialization**: Purpose-built agents for specific tasks
- **Code Intelligence**: Index-powered code navigation
- **Incremental Learning**: Build on previous analysis

### User Experience
- **Faster Responses**: After initial setup
- **Smarter Agents**: Better understanding of context
- **Reliable Actions**: Specialized agents less error-prone
- **Progressive Conversations**: Natural follow-ups

---

## Example Interaction Flow

```
User: @claude analyze this codebase
  → Create parent session (5 min)
  → Run indexer
  → Load full context
  → Response: "I've analyzed the codebase..."
  → Save session: parent-issue-123

User: Fix the bug in auth.py
  → Fork child from parent-issue-123 (30 sec)
  → Child inherits codebase knowledge
  → Focused on bug fixing task
  → Response: "I'll fix the auth.py bug..."

User: Make a pull request
  → Fork another child from parent-issue-123 (30 sec)
  → Child inherits understanding + bug fix context
  → Specialized for PR creation
  → Response: "Creating PR with the fix..."
  → Returns: PR #456 created
```

---

## Migration Path

1. **Keep current workflow as fallback**
2. **Add session management as optional feature**
3. **Test with specific issues before full rollout**
4. **Monitor performance metrics**
5. **Gradually transition to session-based approach**

---

## Conclusion

The proposed Context Inheritance System would transform the GitHub Claude integration from a stateless, slow responder to an intelligent, context-aware system with near-instant responses after initial setup. By combining session management, context forking, and index integration, we can create specialized agents that understand the codebase deeply and respond quickly to user requests.

The key innovation is treating the parent session as a "trained" state that child agents can inherit, eliminating redundant processing while maintaining full context awareness.