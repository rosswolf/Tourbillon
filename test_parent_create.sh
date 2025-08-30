#!/bin/bash

# Quick test to create a parent session

PARENT_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
PARENT_NAME="parent-repo-castlebuilder"

echo "Creating test parent session..."
echo "UUID: $PARENT_UUID"

# Save mapping
mkdir -p ~/.claude/sessions
echo "$PARENT_NAME:$PARENT_UUID" > ~/.claude/sessions/uuid_map.txt

# Create simple parent session
claude --session-id "$PARENT_UUID" --print "You are a parent session for the castlebuilder repository. You help child agents with GitHub tasks. Acknowledge this role." 2>&1

if [ $? -eq 0 ]; then
    echo "Parent session created: $PARENT_UUID"
    
    # Test resume
    echo "Testing resume..."
    claude --resume "$PARENT_UUID" --print "Say 'parent ready'" 2>&1 | grep -q "parent ready"
    
    if [ $? -eq 0 ]; then
        echo "✓ Parent session verified and ready!"
        echo "UUID: $PARENT_UUID"
    else
        echo "✗ Failed to resume from parent"
    fi
else
    echo "✗ Failed to create parent session"
fi