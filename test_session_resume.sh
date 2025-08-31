#!/bin/bash

# Test Claude session resumption in non-interactive mode
# This simulates GitHub Actions environment

SESSION_ID="25fd8500-045a-4a40-bb74-f1f9e60e46ce"
PROJECT_DIR="/home/rosswolf/Code/castlebuilder"

echo "Testing Claude session resumption..."
echo "Session ID: $SESSION_ID"
echo "Project Dir: $PROJECT_DIR"
echo "---"

# Test 1: Simple resume with print
echo "Test 1: Simple resume with --print"
cd "$PROJECT_DIR"
echo "What directory are we in?" | claude --print --resume "$SESSION_ID" 2>&1 | head -20
echo "---"

# Test 2: Resume with continue flag
echo "Test 2: Resume with --continue"
cd "$PROJECT_DIR"
echo "List three things from our previous discussion" | claude --print --continue 2>&1 | head -30
echo "---"

# Test 3: Check session file exists
echo "Test 3: Verify session file"
SESSION_FILE="$HOME/.claude/projects/-home-rosswolf-Code-castlebuilder/${SESSION_ID}.jsonl"
if [ -f "$SESSION_FILE" ]; then
    echo "✓ Session file exists: $SESSION_FILE"
    echo "  File size: $(stat -c%s "$SESSION_FILE") bytes"
    echo "  Lines: $(wc -l < "$SESSION_FILE")"
else
    echo "✗ Session file not found!"
fi
echo "---"

# Test 4: Create new message in session
echo "Test 4: Add new message to session"
cd "$PROJECT_DIR"
echo "This is a test message at $(date). Acknowledge receipt." | claude --print --resume "$SESSION_ID" 2>&1 | head -10

echo "---"
echo "All tests complete!"