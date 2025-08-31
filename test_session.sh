#!/bin/bash

# Test the interactive session in production-like environment

SESSION_ID="25fd8500-045a-4a40-bb74-f1f9e60e46ce"
REPO_PATH="/home/rosswolf/Code/castlebuilder"

echo "=== Testing Interactive Session ==="
echo "Session ID: $SESSION_ID"
echo ""

# Test 1: Basic resume
echo "Test 1: Can we resume the session?"
echo "What repository are you working with?" | \
  claude --resume "$SESSION_ID" --print 2>&1 | head -5

echo ""
echo "Test 2: Does it have repository context?"
echo "What is the main game project location in castlebuilder?" | \
  claude --resume "$SESSION_ID" --print \
  --add-dir "$REPO_PATH" \
  --dangerously-skip-permissions 2>&1 | head -10

echo ""
echo "Test 3: Can it see current files?"
echo "List the workflow files in .github/workflows/" | \
  claude --resume "$SESSION_ID" --print \
  --add-dir "$REPO_PATH" \
  --dangerously-skip-permissions 2>&1 | head -15

echo ""
echo "=== Tests Complete ==="