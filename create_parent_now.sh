#!/bin/bash

echo "Creating parent session for castlebuilder repository..."

# Generate UUID
PARENT_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
PARENT_NAME="parent-repo-castlebuilder"

echo "Generated UUID: $PARENT_UUID"

# Save mapping
mkdir -p ~/.claude/sessions
echo "$PARENT_NAME:$PARENT_UUID" > ~/.claude/sessions/uuid_map.txt

# Create parent session with repository context
claude --session-id "$PARENT_UUID" --print "You are the parent session for the castlebuilder GitHub repository.

REPOSITORY CONTEXT:
- This is a Godot 4.4 game development project
- It's a card-based battle system with heroes, mobs, and relics
- The codebase uses clean architecture principles
- Located at: /home/rosswolf/Code/castlebuilder

YOUR ROLE:
You are a persistent knowledge base that child agents will inherit from. Child agents will handle specific GitHub issues and pull requests. You provide them with:
1. Understanding of the codebase structure
2. Knowledge of project patterns and conventions  
3. Ability to make code changes and create PRs
4. Context about the repository's purpose and architecture

KEY CAPABILITIES FOR CHILD AGENTS:
- Create branches with: git checkout -b branch-name
- Make commits with: git add -A && git commit -m 'message'
- Push changes with: git push origin HEAD
- Create PRs with: gh pr create --title 'title' --body 'description'
- Full read/write access to the repository

Acknowledge that you are ready to serve as the parent session." --add-dir /home/rosswolf/Code/castlebuilder --dangerously-skip-permissions

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Parent session created successfully!"
    echo "UUID: $PARENT_UUID"
    echo "Name: $PARENT_NAME"
    echo ""
    echo "Testing resume capability..."
    
    claude --resume "$PARENT_UUID" --print "Confirm: say 'Parent session active and ready'" 2>&1 | grep -q "Parent session active and ready"
    
    if [ $? -eq 0 ]; then
        echo "✅ Parent session verified - can resume successfully"
        echo ""
        echo "The enhanced workflow is now ready to use!"
    else
        echo "⚠️  Warning: Parent created but resume test failed"
    fi
else
    echo "❌ Failed to create parent session"
    exit 1
fi