#!/bin/bash

# Session Manager for GitHub Claude Integration
# Handles parent/child session creation and management

set -e

CLAUDE_CMD="claude"
SESSION_DIR="$HOME/.claude/sessions"
REPO_PATH="/home/rosswolf/Code/castlebuilder"
INDEX_CMD="/index"

# Ensure session directory exists
mkdir -p "$SESSION_DIR"

# Function to check if a session exists
session_exists() {
    local session_id="$1"
    $CLAUDE_CMD --list-sessions 2>/dev/null | grep -q "$session_id" || return 1
}

# Function to get session info
get_session_info() {
    local session_id="$1"
    if [ -f "$SESSION_DIR/${session_id}.info" ]; then
        cat "$SESSION_DIR/${session_id}.info"
    else
        echo "{}"
    fi
}

# Function to save session info
save_session_info() {
    local session_id="$1"
    local info="$2"
    echo "$info" > "$SESSION_DIR/${session_id}.info"
}

# Function to create parent session
create_parent_session() {
    local repo_name="${1:-castlebuilder}"
    local parent_session="parent-repo-${repo_name}"
    
    echo "Creating parent session: $parent_session"
    
    # Check if parent already exists
    if session_exists "$parent_session"; then
        echo "Parent session already exists: $parent_session"
        echo "$parent_session"
        return 0
    fi
    
    # Run indexer first
    echo "Running code indexer..."
    cd "$REPO_PATH"
    if command -v "$INDEX_CMD" &> /dev/null; then
        $INDEX_CMD --quick || echo "Warning: Indexer failed or not available"
    fi
    
    # Build comprehensive parent context
    local context_file="/tmp/parent_context_${repo_name}.txt"
    cat > "$context_file" << 'EOF'
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

EOF
    
    # Add PARENT_CONTEXT.md - the main context document
    if [ -f "$REPO_PATH/PARENT_CONTEXT.md" ]; then
        echo "=== REPOSITORY CONTEXT (PARENT_CONTEXT.md) ===" >> "$context_file"
        cat "$REPO_PATH/PARENT_CONTEXT.md" >> "$context_file"
        echo -e "\n=== End of PARENT_CONTEXT.md ===\n" >> "$context_file"
    else
        echo "WARNING: PARENT_CONTEXT.md not found - parent session will have limited context" >&2
    fi
    
    # Add CLAUDE.md if it exists
    if [ -f "$REPO_PATH/CLAUDE.md" ]; then
        echo "=== PROJECT GUIDELINES (CLAUDE.md) ===" >> "$context_file"
        cat "$REPO_PATH/CLAUDE.md" >> "$context_file"
        echo -e "\n=== End of CLAUDE.md ===\n" >> "$context_file"
    fi
    
    # Add PROJECT_INDEX.json summary if it exists
    if [ -f "$REPO_PATH/PROJECT_INDEX.json" ]; then
        echo "=== CODEBASE INDEX SUMMARY ===" >> "$context_file"
        # Extract key information from index
        cat "$REPO_PATH/PROJECT_INDEX.json" | jq -r '
            {
                total_functions: .functions | length,
                total_files: .files | length,
                key_classes: [.functions[].class_name] | unique | sort,
                file_structure: .files | keys | sort
            }' >> "$context_file" 2>/dev/null || echo "Index present but couldn't parse"
        echo -e "\n=== End of Index Summary ===\n" >> "$context_file"
    fi
    
    # Note: No conversation history in parent - it's repo-wide, not issue-specific
    
    # Final instructions
    cat >> "$context_file" << 'EOF'

=== PARENT SESSION TASK ===
Analyze and understand:
1. The complete codebase structure and all key components
2. Project patterns, conventions, and architectural decisions
3. The problem domain (game development, card mechanics, etc.)
4. All configuration files, build processes, and dependencies

This is a ONE-TIME initialization that will serve ALL future GitHub interactions.
Child agents will fork from you to handle specific issues, PRs, and tasks.
Respond with a brief acknowledgment of the codebase structure you've understood.
EOF
    
    # Create the parent session
    echo "Initializing parent session with Claude..."
    $CLAUDE_CMD --model opus \
        --session-id "$parent_session" \
        --print "$(cat "$context_file")" \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions \
        > "/tmp/parent_init_${repo_name}.log" 2>&1
    
    local exit_code=$?
    
    # Save session metadata
    save_session_info "$parent_session" "{
        \"type\": \"parent\",
        \"repository\": \"$repo_name\",
        \"created_at\": \"$(date -Iseconds)\",
        \"repo_path\": \"$REPO_PATH\",
        \"indexed\": true,
        \"scope\": \"repository-wide\"
    }"
    
    # Clean up
    rm -f "$context_file"
    
    if [ $exit_code -eq 0 ]; then
        echo "Parent session created successfully: $parent_session"
        echo "$parent_session"
    else
        echo "Error: Failed to create parent session (exit code: $exit_code)"
        cat "/tmp/parent_init_${repo_name}.log"
        return 1
    fi
}

# Function to fork child agent from parent
fork_child_agent() {
    local parent_session="$1"
    local task_type="$2"
    local user_request="$3"
    local issue_context="$4"  # Optional: issue/PR specific context
    local child_session="child-$(date +%s)-$$"
    
    echo "Forking child agent: $child_session (type: $task_type)"
    
    # Prepare task-specific prompt based on type
    local agent_prompt=""
    case "$task_type" in
        "pull-request")
            agent_prompt="You are a Pull Request specialist. Your task is to create branches, make commits, and create pull requests as requested. You have access to git and gh CLI commands."
            ;;
        "bug-fix")
            agent_prompt="You are a Bug Fix specialist. Your task is to identify and fix bugs in the code. Focus on the specific issue mentioned."
            ;;
        "code-review")
            agent_prompt="You are a Code Review specialist. Analyze the code changes and provide constructive feedback."
            ;;
        "documentation")
            agent_prompt="You are a Documentation specialist. Update or create documentation as requested."
            ;;
        *)
            agent_prompt="You are a specialized agent. Handle the user's request with your full capabilities."
            ;;
    esac
    
    # Build child context
    local child_prompt="$agent_prompt

=== ISSUE/PR CONTEXT ===
$issue_context

=== CURRENT TASK ===
$user_request

=== IMPORTANT ===
- You inherit complete codebase knowledge from the repository-wide parent session
- You have full understanding of the project architecture, patterns, and conventions
- You can create branches, commits, and pull requests using git and gh CLI
- Focus on completing the specific task requested
- Be concise and action-oriented"
    
    # Fork from parent session
    echo "Executing child agent with inherited context..."
    $CLAUDE_CMD --model opus \
        --resume "$parent_session" \
        --session-id "$child_session" \
        --print "$child_prompt" \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions
    
    local exit_code=$?
    
    # Save child session metadata
    save_session_info "$child_session" "{
        \"type\": \"child\",
        \"parent\": \"$parent_session\",
        \"task_type\": \"$task_type\",
        \"created_at\": \"$(date -Iseconds)\"
    }"
    
    return $exit_code
}

# Function to detect task type from comment
detect_task_type() {
    local comment="$1"
    local comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')
    
    if echo "$comment_lower" | grep -qE "pull request|pr|merge"; then
        echo "pull-request"
    elif echo "$comment_lower" | grep -qE "bug|fix|error|issue"; then
        echo "bug-fix"
    elif echo "$comment_lower" | grep -qE "review|feedback|check"; then
        echo "code-review"
    elif echo "$comment_lower" | grep -qE "document|docs|readme|prd"; then
        echo "documentation"
    else
        echo "general"
    fi
}

# Function to clean old sessions
cleanup_old_sessions() {
    local days_old="${1:-7}"
    echo "Cleaning sessions older than $days_old days..."
    
    # Find and remove old session info files
    find "$SESSION_DIR" -name "*.info" -mtime +$days_old -delete 2>/dev/null || true
    
    # Note: Actual Claude sessions need to be cleaned separately
    # This just cleans our metadata
}

# Main command handler
case "${1:-help}" in
    create-parent)
        create_parent_session "$2"  # Just repo name, or defaults to "castlebuilder"
        ;;
    fork-child)
        fork_child_agent "$2" "$3" "$4" "$5"  # parent, type, request, context
        ;;
    exists)
        session_exists "$2" && echo "true" || echo "false"
        ;;
    info)
        get_session_info "$2"
        ;;
    detect-type)
        detect_task_type "$2"
        ;;
    cleanup)
        cleanup_old_sessions "$2"
        ;;
    list)
        echo "=== Claude Sessions ==="
        $CLAUDE_CMD --list-sessions 2>/dev/null || echo "No sessions found"
        echo -e "\n=== Session Metadata ==="
        ls -la "$SESSION_DIR"/*.info 2>/dev/null || echo "No metadata found"
        ;;
    help|*)
        cat << 'HELP'
Session Manager for GitHub Claude Integration

Usage:
  session_manager.sh create-parent [repo_name]
    Create a repository-wide parent session (defaults to "castlebuilder")
    
  session_manager.sh fork-child <parent_session> <task_type> <user_request> [issue_context]
    Fork a child agent from parent session with optional issue context
    
  session_manager.sh exists <session_id>
    Check if a session exists
    
  session_manager.sh info <session_id>
    Get session metadata
    
  session_manager.sh detect-type <comment_text>
    Detect task type from comment
    
  session_manager.sh cleanup [days_old]
    Clean up old sessions (default: 7 days)
    
  session_manager.sh list
    List all sessions and metadata

Examples:
  # Create parent for issue #123
  ./session_manager.sh create-parent 123 conversation.txt
  
  # Fork child for PR creation
  ./session_manager.sh fork-child parent-issue-123 pull-request "Create PR with the fixes"
  
  # Check if session exists
  ./session_manager.sh exists parent-issue-123
HELP
        ;;
esac