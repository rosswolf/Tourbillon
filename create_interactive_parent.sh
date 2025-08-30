#!/bin/bash

# Script to create a parent session in interactive mode
# This session can then be resumed in GitHub Actions

set -e

REPO_PATH="/home/rosswolf/Code/castlebuilder"
CONTEXT_FILE="$REPO_PATH/PARENT_CONTEXT.md"

echo "=== Creating Parent Session in Interactive Mode ==="
echo ""
echo "This script will:"
echo "1. Start Claude in interactive mode"
echo "2. Load the parent context"
echo "3. Create a resumable session"
echo "4. Save the session ID for GitHub Actions"
echo ""
echo "IMPORTANT: After Claude starts, you need to:"
echo "1. Wait for it to process the context"
echo "2. Type: /session"
echo "3. Copy the session ID"
echo "4. Type: exit"
echo ""
read -p "Press Enter to continue..."

# Change to the repository directory
cd "$REPO_PATH"

# Create the initial prompt for the parent session
cat > /tmp/parent_prompt.txt << 'EOF'
You are Claude, an AI assistant with deep knowledge of the castlebuilder repository.

=== PARENT SESSION INITIALIZATION ===
This is a MASTER parent session that will be shared across ALL GitHub issues, PRs, and interactions.
You are establishing a comprehensive understanding of:
- The entire codebase architecture and structure
- Project conventions and patterns
- Key components and their relationships
- The problem domain and business logic

=== YOUR ROLE ===
1. Understand the entire codebase structure and architecture
2. Learn the project's patterns, conventions, and guidelines
3. Map out key components and their interactions
4. Build knowledge that ALL child agents can inherit for ANY task
5. This knowledge will be reused across different issues and PRs

=== REPOSITORY CONTEXT ===
EOF

# Add the parent context if it exists
if [ -f "$CONTEXT_FILE" ]; then
    cat "$CONTEXT_FILE" >> /tmp/parent_prompt.txt
fi

cat >> /tmp/parent_prompt.txt << 'EOF'

=== CODEBASE ACCESS ===
You have full access to the repository at: /home/rosswolf/Code/castlebuilder

Key locations:
- Main game project: castlebuilder-app/app/ (Godot 4.4)
- Documentation: docs/
- GitHub workflows: .github/workflows/
- Scripts: .github/scripts/

=== TASK ===
Analyze and understand the complete codebase. Acknowledge when you've processed this context.

After acknowledging, I will ask for the session ID using /session command.
EOF

echo ""
echo "=== Starting Claude Interactive Session ==="
echo "Remember to:"
echo "1. Let Claude process the context"
echo "2. Type: /session"
echo "3. Save the session ID"
echo "4. Type: exit"
echo ""
echo "Initial prompt saved to: /tmp/parent_prompt.txt"
echo ""
echo "You can paste this into Claude:"
echo "---"
cat /tmp/parent_prompt.txt
echo "---"
echo ""
echo "Starting Claude now..."
echo ""

# Start Claude in interactive mode
claude