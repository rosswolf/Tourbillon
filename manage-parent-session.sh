#!/bin/bash

# Manual Parent Session Management for Claude Integration
# This script allows manual creation, deletion, and recreation of the repository parent session

set -e

# Configuration
REPO_PATH="/home/rosswolf/Code/castlebuilder"
CLAUDE_CMD="claude"
SESSION_MANAGER=".github/scripts/session_manager.sh"
PARENT_SESSION="parent-repo-castlebuilder"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure we're in the right directory
cd "$REPO_PATH"

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if parent session exists
check_parent() {
    if $SESSION_MANAGER exists "$PARENT_SESSION" | grep -q "true"; then
        return 0
    else
        return 1
    fi
}

# Function to show parent session info
show_info() {
    print_color "$BLUE" "\n=== Parent Session Information ==="
    
    if check_parent; then
        print_color "$GREEN" "✓ Parent session exists: $PARENT_SESSION"
        
        # Show metadata if available
        local info=$($SESSION_MANAGER info "$PARENT_SESSION")
        if [ ! -z "$info" ] && [ "$info" != "{}" ]; then
            echo "Metadata:"
            echo "$info" | jq . 2>/dev/null || echo "$info"
        fi
        
        # Show session size if available
        local session_file="$HOME/.claude/sessions/${PARENT_SESSION}"
        if [ -f "$session_file" ]; then
            local size=$(du -sh "$session_file" 2>/dev/null | cut -f1)
            echo "Session size: $size"
        fi
    else
        print_color "$YELLOW" "⚠ No parent session exists"
    fi
    
    # Show all Claude sessions
    echo -e "\n=== All Claude Sessions ==="
    claude --list-sessions 2>/dev/null | head -20 || echo "No sessions found"
}

# Function to create parent session
create_parent() {
    print_color "$BLUE" "\n=== Creating Repository Parent Session ==="
    
    if check_parent; then
        print_color "$YELLOW" "⚠ Parent session already exists: $PARENT_SESSION"
        read -p "Do you want to recreate it? This will delete the existing session. (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_color "$YELLOW" "Aborted."
            return 1
        fi
        delete_parent
    fi
    
    print_color "$GREEN" "Creating new parent session..."
    print_color "$YELLOW" "This will:"
    echo "  1. Run the code indexer to analyze the codebase"
    echo "  2. Load all project guidelines and patterns"
    echo "  3. Create a comprehensive knowledge base"
    echo "  4. Take approximately 5-10 minutes"
    echo ""
    read -p "Continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Aborted."
        return 1
    fi
    
    # Run the indexer first
    print_color "$GREEN" "Step 1: Running code indexer..."
    if command -v /index &> /dev/null; then
        /index --quick || print_color "$YELLOW" "Warning: Indexer failed or not available"
    else
        print_color "$YELLOW" "Indexer not found, skipping..."
    fi
    
    # Create the parent session
    print_color "$GREEN" "Step 2: Creating parent session with Claude..."
    if $SESSION_MANAGER create-parent "castlebuilder"; then
        print_color "$GREEN" "✓ Parent session created successfully!"
        show_info
    else
        print_color "$RED" "✗ Failed to create parent session"
        return 1
    fi
}

# Function to delete parent session
delete_parent() {
    print_color "$BLUE" "\n=== Deleting Parent Session ==="
    
    if ! check_parent; then
        print_color "$YELLOW" "No parent session exists to delete"
        return 0
    fi
    
    print_color "$YELLOW" "⚠ Warning: This will delete the parent session: $PARENT_SESSION"
    print_color "$YELLOW" "  All child agents will need to recreate the parent on next run."
    read -p "Are you sure? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_color "$YELLOW" "Aborted."
        return 1
    fi
    
    # Delete session metadata
    rm -f "$HOME/.claude/sessions/${PARENT_SESSION}.info" 2>/dev/null || true
    
    # Note: Claude CLI doesn't have a delete-session command, so we can't fully remove it
    # The session will be orphaned but won't be used
    print_color "$GREEN" "✓ Parent session marked as deleted"
    print_color "$YELLOW" "Note: The actual Claude session file may still exist but won't be used"
}

# Function to test parent session
test_parent() {
    print_color "$BLUE" "\n=== Testing Parent Session ==="
    
    if ! check_parent; then
        print_color "$RED" "✗ No parent session exists to test"
        print_color "$YELLOW" "Run: $0 create"
        return 1
    fi
    
    print_color "$GREEN" "Testing parent session with a simple query..."
    
    # Create a test prompt
    local test_prompt="You are a child agent forked from the repository parent session.
Test your inherited knowledge by briefly describing:
1. The main purpose of this repository
2. Key architectural components you're aware of
3. Confirm you have access to the codebase at $REPO_PATH

Keep your response under 5 lines."
    
    print_color "$YELLOW" "Sending test query to Claude..."
    
    # Test the session
    local response=$(echo "$test_prompt" | \
        $CLAUDE_CMD --model opus \
        --resume "$PARENT_SESSION" \
        --print \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions 2>&1)
    
    if [ $? -eq 0 ]; then
        print_color "$GREEN" "✓ Parent session is working!"
        echo -e "\nResponse from Claude:"
        echo "$response" | head -20
    else
        print_color "$RED" "✗ Failed to test parent session"
        echo "Error: $response"
        return 1
    fi
}

# Function to recreate parent session
recreate_parent() {
    print_color "$BLUE" "\n=== Recreating Parent Session ==="
    print_color "$YELLOW" "This will delete the existing parent and create a new one."
    
    delete_parent
    create_parent
}

# Function to show usage
show_usage() {
    cat << EOF
Repository Parent Session Manager

This tool manages the repository-wide parent session that all GitHub Claude agents
inherit from. The parent session contains comprehensive knowledge of the entire
codebase and is shared across all issues and PRs.

Usage: $0 [command]

Commands:
    info      Show information about the current parent session
    create    Create a new parent session (will prompt before overwriting)
    delete    Delete the existing parent session
    recreate  Delete and recreate the parent session
    test      Test the parent session with a simple query
    help      Show this help message

Examples:
    $0 info       # Check if parent session exists
    $0 create     # Create the parent session for first time
    $0 test       # Verify parent session is working
    $0 recreate   # Refresh parent session with latest code

Parent Session Details:
    Session ID: $PARENT_SESSION
    Repository: $REPO_PATH
    
The parent session:
    - Analyzes the entire codebase structure
    - Runs the code indexer for dependency mapping
    - Loads all project guidelines and patterns
    - Takes 5-10 minutes to create
    - Is reused by all child agents (30 second fork time)
    - Should be recreated when major architectural changes occur

EOF
}

# Main command handler
case "${1:-help}" in
    info)
        show_info
        ;;
    create)
        create_parent
        ;;
    delete)
        delete_parent
        ;;
    recreate)
        recreate_parent
        ;;
    test)
        test_parent
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        print_color "$RED" "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac