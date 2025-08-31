# Claude Session Persistence Solutions

## Research Summary
Date: August 31, 2025

Based on extensive research into Claude CLI, SDK, and API documentation, I've identified multiple approaches to solve the session persistence issue that's causing 90-120 second response times in GitHub Actions.

## Core Problem Recap

**Current Issue**: Claude CLI sessions created locally cannot be accessed in GitHub Actions environment, even though session files exist in `~/.claude/todos/`

**Impact**: 
- 3-4x slower responses (90-120s vs target <30s)
- Higher API costs
- No conversation continuity
- Full context reload each time

## Solution Options

### Option 1: Claude Code SDK Implementation (Recommended)
**Replace CLI with Claude Code SDK for full session management**

**Advantages:**
- Native session persistence support via `ClaudeSDKClient`
- Built-in `continue_conversation` and `resume` parameters
- Designed for production automation
- Automatic prompt caching
- Full GitHub Actions compatibility

**Implementation:**
```python
from claude_code import ClaudeSDKClient, ClaudeCodeOptions

# Create persistent client
client = ClaudeSDKClient()

# Resume specific session
options = ClaudeCodeOptions(
    resume="session-uuid",  # Load existing session
    session_dir="/shared/claude-sessions"  # Custom location
)

# Or continue most recent
options = ClaudeCodeOptions(
    continue_conversation=True
)
```

**Steps:**
1. Install Claude Code SDK in GitHub Actions runner
2. Store session UUIDs in GitHub repository (encrypted secrets or files)
3. Load session on each workflow run
4. Save session UUID after each interaction

**Estimated Performance:** <30 seconds response time

### Option 2: Anthropic API with Custom Session Management
**Build lightweight session manager using standard API**

**Advantages:**
- Full control over session storage
- Can use GitHub Actions artifacts/cache
- More portable across environments
- Lower overhead than full SDK

**Implementation:**
```python
import anthropic
import json
from pathlib import Path

class SessionManager:
    def __init__(self, session_path="/tmp/claude-sessions"):
        self.session_path = Path(session_path)
        self.client = anthropic.Anthropic()
    
    def load_session(self, session_id):
        session_file = self.session_path / f"{session_id}.json"
        if session_file.exists():
            return json.loads(session_file.read_text())
        return {"messages": []}
    
    def save_session(self, session_id, messages):
        session_file = self.session_path / f"{session_id}.json"
        session_file.write_text(json.dumps({"messages": messages}))
    
    def continue_conversation(self, session_id, new_message):
        session = self.load_session(session_id)
        session["messages"].append({"role": "user", "content": new_message})
        
        response = self.client.messages.create(
            model="claude-3-opus-20240229",
            messages=session["messages"],
            max_tokens=4096
        )
        
        session["messages"].append({
            "role": "assistant", 
            "content": response.content[0].text
        })
        
        self.save_session(session_id, session["messages"])
        return response
```

**Storage Options:**
- GitHub Actions cache
- Repository files (encrypted)
- GitHub Artifacts
- External storage (S3, etc.)

**Estimated Performance:** <20 seconds response time

### Option 3: GitHub Issues as Context Storage
**Use GitHub issues themselves as persistent context**

**Advantages:**
- Zero external dependencies
- Context visible to developers
- Natural conversation threading
- Built-in versioning

**Implementation:**
```yaml
- name: Load Context from Issue
  run: |
    # Fetch issue history
    gh issue view ${{ github.event.issue.number }} --json comments > context.json
    
    # Extract previous Claude responses
    jq '.comments[] | select(.author.login == "github-actions[bot]")' context.json > claude_history.json

- name: Call Claude with Context
  run: |
    # Include history in prompt
    CONTEXT=$(cat claude_history.json)
    echo "Previous context: $CONTEXT" | claude --headless
```

**Estimated Performance:** 60-90 seconds (better than current)

### Option 4: Hybrid Markdown Context Files
**Maintain context in repository markdown files**

**Advantages:**
- Simple implementation
- Version controlled
- Human-readable context
- Can be edited manually

**Implementation:**
```bash
# Load context from markdown
CONTEXT_FILE=".claude/sessions/${ISSUE_NUMBER}.md"

if [ -f "$CONTEXT_FILE" ]; then
  CONTEXT=$(cat "$CONTEXT_FILE")
fi

# Append new context
echo "## Session $(date)" >> "$CONTEXT_FILE"
echo "$USER_MESSAGE" >> "$CONTEXT_FILE"

# Call Claude with full context
claude --headless --context-file "$CONTEXT_FILE" "$USER_MESSAGE"

# Save response
echo "$CLAUDE_RESPONSE" >> "$CONTEXT_FILE"
```

**Estimated Performance:** 45-60 seconds

### Option 5: Depot Claude Integration
**Use third-party Depot service for managed sessions**

**Advantages:**
- Pre-built solution
- Team collaboration features
- Cross-environment persistence
- Professional support

**Implementation:**
```bash
# Install Depot CLI
curl -L https://depot.dev/install-cli.sh | sh

# Create/resume session
depot claude --session-id "$SESSION_ID" --resume

# Share sessions across team
depot claude share "$SESSION_ID"
```

**Cost:** Requires Depot subscription
**Estimated Performance:** <30 seconds

### Option 6: Fix CLI Session Bug (Long-term)
**Work with Anthropic to fix the underlying CLI issue**

**Actions:**
1. File detailed bug report with reproduction steps
2. Contribute PR if open source
3. Work with Anthropic support team
4. Document workaround for others

**Timeline:** Unknown, depends on Anthropic

## Recommendation Priority

### Immediate (This Week)
**Implement Option 2: API with Custom Session Management**
- Fastest to implement
- Most control
- Good performance improvement
- No external dependencies

### Short-term (Next Sprint)
**Migrate to Option 1: Claude Code SDK**
- Best long-term solution
- Native session support
- Production-ready features
- Official support

### Backup Plan
**Option 4: Markdown Context Files**
- Simple fallback
- Can implement in hours
- Better than current state
- Easy to debug

## Implementation Checklist

### For API Solution (Option 2):
- [ ] Create Python session manager class
- [ ] Set up GitHub Actions cache for sessions
- [ ] Implement session ID tracking
- [ ] Add error handling and retries
- [ ] Test with multiple concurrent issues
- [ ] Document session lifecycle
- [ ] Create cleanup job for old sessions

### For SDK Solution (Option 1):
- [ ] Install Claude Code SDK on runner
- [ ] Configure SDK authentication
- [ ] Implement session storage strategy
- [ ] Create session management wrapper
- [ ] Test session persistence
- [ ] Migrate existing workflows
- [ ] Monitor performance metrics

## Performance Comparison

| Solution | Response Time | Implementation Effort | Maintenance | Cost |
|----------|--------------|----------------------|-------------|------|
| Current (No Sessions) | 90-120s | Already done | Low | High (tokens) |
| API + Custom Sessions | 15-20s | Medium (2-3 days) | Medium | Low |
| Claude Code SDK | 20-30s | Medium (3-4 days) | Low | Low |
| GitHub Issues Context | 60-90s | Low (1 day) | Low | Medium |
| Markdown Files | 45-60s | Low (1 day) | Medium | Medium |
| Depot Claude | 25-30s | Low (1 day) | Low | Subscription |

## Risk Mitigation

### Session Corruption
- Implement session validation
- Keep backup of last known good state
- Auto-recovery from corrupted sessions

### Concurrent Access
- Use file locking mechanisms
- Implement session queuing
- Handle race conditions gracefully

### Storage Limits
- Rotate old sessions
- Compress session data
- Implement cleanup policies

## Monitoring & Success Metrics

### Key Metrics to Track:
- Response time percentiles (p50, p95, p99)
- Session hit rate (reuse vs new)
- Token usage reduction
- Error rates
- Session storage size

### Success Criteria:
- [ ] Response time <30 seconds for 95% of requests
- [ ] 80%+ session reuse rate
- [ ] 50%+ reduction in token usage
- [ ] Zero session corruption incidents
- [ ] <1% error rate

## Next Steps

1. **Prototype Option 2** (API Solution) in test environment
2. **Measure baseline** performance metrics
3. **Run A/B test** against current implementation
4. **Document results** and learnings
5. **Plan SDK migration** if API solution proves successful

## Conclusion

The session persistence issue is solvable through multiple approaches. The API-based custom session management (Option 2) offers the best balance of performance improvement and implementation effort for immediate relief, while the Claude Code SDK (Option 1) represents the best long-term solution.

Moving from 90-120 second response times to sub-30 seconds is achievable with proper session management, which will also significantly reduce API costs and improve user experience.