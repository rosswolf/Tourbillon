#!/bin/bash

# Session Manager for GitHub Claude Integration
# Handles parent/child session creation and management with UUID support

set -e

CLAUDE_CMD="claude"
SESSION_DIR="$HOME/.claude/sessions"
REPO_PATH="/home/rosswolf/Code/castlebuilder"
INDEX_CMD="/index"
UUID_MAP_FILE="$SESSION_DIR/uuid_map.txt"

# Ensure session directory exists
mkdir -p "$SESSION_DIR"

# Function to save UUID mapping
save_uuid_mapping() {
    local name="$1"
    local uuid="$2"
    echo "$name:$uuid" >> "$UUID_MAP_FILE"
}

# Function to get UUID from name
get_uuid_from_name() {
    local name="$1"
    if [ -f "$UUID_MAP_FILE" ]; then
        grep "^$name:" "$UUID_MAP_FILE" 2>/dev/null | cut -d: -f2 | tail -1
    fi
}

# Function to check if a session exists (by UUID)
session_exists() {
    local session_uuid="$1"
    # Check if UUID file exists in todos
    ls ~/.claude/todos/${session_uuid}*.json >/dev/null 2>&1
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
    local parent_name="parent-repo-${repo_name}"
    
    # Check if we already have a UUID for this parent
    local existing_uuid=$(get_uuid_from_name "$parent_name")
    
    if [ -n "$existing_uuid" ] && session_exists "$existing_uuid"; then
        echo "Parent session already exists with UUID: $existing_uuid"
        echo "$existing_uuid"
        return 0
    fi
    
    # Generate a new UUID for the session
    local parent_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    echo "Creating parent session: $parent_name"
    echo "UUID: $parent_uuid"
    
    # Save the mapping
    save_uuid_mapping "$parent_name" "$parent_uuid"
    
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
    
    # Create the parent session with UUID
    echo "Initializing parent session with Claude..."
    
    # WORKAROUND: Claude CLI has issues with --session-id and initial content
    # Instead, we'll create a regular conversation and save its ID
    echo "Creating parent session (this takes 5-10 minutes)..."
    
    # Create session without --session-id, let Claude auto-generate one
    local response=$($CLAUDE_CMD --model opus \
        --print "$(cat "$context_file")" \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions 2>&1)
    
    # Extract the session ID from Claude's output or session files
    # Claude creates sessions automatically - find the most recent one
    local actual_session_id=$(ls -t ~/.claude/todos/*.json 2>/dev/null | head -1 | xargs basename | cut -d'-' -f1-5)
    
    if [ -z "$actual_session_id" ]; then
        echo "Error: Failed to create parent session"
        return 1
    fi
    
    # Update our UUID map with the actual session ID
    parent_uuid="$actual_session_id"
    echo "$parent_name:$parent_uuid" >> "$UUID_MAP_FILE"
    
    echo "$response" > "/tmp/parent_init_${repo_name}.log"
    
    local exit_code=$?
    
    # Save session metadata
    save_session_info "$parent_uuid" "{
        \"type\": \"parent\",
        \"name\": \"$parent_name\",
        \"repository\": \"$repo_name\",
        \"created_at\": \"$(date -Iseconds)\",
        \"repo_path\": \"$REPO_PATH\",
        \"indexed\": true,
        \"scope\": \"repository-wide\"
    }"
    
    # Clean up
    rm -f "$context_file"
    
    if [ $exit_code -eq 0 ]; then
        echo "Parent session created successfully"
        echo "$parent_uuid"
    else
        echo "Error: Failed to create parent session (exit code: $exit_code)"
        cat "/tmp/parent_init_${repo_name}.log"
        return 1
    fi
}

# Function to fork child agent from parent
fork_child_agent() {
    local parent_uuid="$1"
    local task_type="$2"
    local user_request="$3"
    local issue_context="$4"  # Optional: issue/PR specific context
    
    # Generate UUID for child
    local child_uuid=$(uuidgen | tr '[:upper:]' '[:lower:]')
    
    echo "Forking child agent: $child_uuid (type: $task_type)"
    
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

=== YOUR CAPABILITIES ===
You are running in a GitHub Actions workflow with these abilities:

1. **READ ACCESS**: You can read any file in the repository at $REPO_PATH
2. **WRITE ACCESS**: You can create and modify files in the repository
3. **GIT OPERATIONS**: You can create branches, commits, and pull requests using:
   - git commands for branching and committing
   - gh CLI for creating pull requests: gh pr create --title \"title\" --body \"description\"
4. **CURRENT CONTEXT**: You're in the checked-out repository on a self-hosted runner

=== HOW TO HANDLE REQUESTS ===

- **\"Update/Change/Modify files\"** (PRD, README, code, etc):
  1. Create a new branch: git checkout -b feature-name-\$(date +%s)
  2. Make the file changes using Edit or Write tools
  3. Commit: git add -A && git commit -m \"Clear commit message\"
  4. Push: git push origin HEAD
  5. Create PR: gh pr create --title \"Title\" --body \"Description with issue #X reference\"
  6. Provide the PR link in your response

- **\"Make a pull request\"** (after discussing changes):
  - If you've already described changes, implement them and create a PR
  - If unclear what changes to make, ask for clarification
  - Always create a feature branch, never commit directly to main/master

- **\"Fix a bug\"**:
  1. Identify the issue in the code
  2. Create a fix branch: git checkout -b fix-issue-description-\$(date +%s)
  3. Make the fix
  4. Test if possible
  5. Commit and create PR with clear explanation

=== IMPORTANT ===
- You inherit complete codebase knowledge from the repository-wide parent session
- You have full understanding of the project architecture, patterns, and conventions
- You have the dangerously-skip-permissions flag, so you can execute all operations
- Always provide clear feedback about what actions you're taking
- Include PR links in your response when you create them
- Focus on completing the specific task requested
- Be concise and action-oriented"
    
    # Fork from parent session using --resume (without --session-id since they conflict)
    echo "Executing child agent with inherited context..."
    $CLAUDE_CMD --model opus \
        --resume "$parent_uuid" \
        --print "$child_prompt" \
        --add-dir "$REPO_PATH" \
        --dangerously-skip-permissions
    
    local exit_code=$?
    
    # Save child session metadata
    save_session_info "$child_uuid" "{
        \"type\": \"child\",
        \"parent\": \"$parent_uuid\",
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

# Function to check if session exists by name
exists_by_name() {
    local session_name="$1"
    local uuid=$(get_uuid_from_name "$session_name")
    
    if [ -n "$uuid" ] && session_exists "$uuid"; then
        echo "true"
    else
        echo "false"
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
        fork_child_agent "$2" "$3" "$4" "$5"  # parent UUID, type, request, context
        ;;
    exists)
        # Check if it's a UUID or a name
        if [[ "$2" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; then
            session_exists "$2" && echo "true" || echo "false"
        else
            exists_by_name "$2"
        fi
        ;;
    get-uuid)
        get_uuid_from_name "$2"
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
        echo "=== UUID Mappings ==="
        if [ -f "$UUID_MAP_FILE" ]; then
            cat "$UUID_MAP_FILE"
        else
            echo "No mappings found"
        fi
        echo -e "\n=== Session Metadata ==="
        ls -la "$SESSION_DIR"/*.info 2>/dev/null || echo "No metadata found"
        ;;
    help|*)
        cat << 'HELP'
Session Manager for GitHub Claude Integration with UUID Support

Usage:
  session_manager.sh create-parent [repo_name]
    Create a repository-wide parent session (defaults to "castlebuilder")
    Returns the UUID of the created session
    
  session_manager.sh fork-child <parent_uuid> <task_type> <user_request> [issue_context]
    Fork a child agent from parent session with optional issue context
    
  session_manager.sh exists <session_id_or_name>
    Check if a session exists (by UUID or name)
    
  session_manager.sh get-uuid <session_name>
    Get UUID for a named session
    
  session_manager.sh info <session_id>
    Get session metadata
    
  session_manager.sh detect-type <comment_text>
    Detect task type from comment
    
  session_manager.sh cleanup [days_old]
    Clean up old sessions (default: 7 days)
    
  session_manager.sh list
    List all sessions and metadata

Examples:
  # Create parent
  UUID=$(./session_manager.sh create-parent castlebuilder)
  
  # Fork child for PR creation
  ./session_manager.sh fork-child $UUID pull-request "Create PR with the fixes"
  
  # Check if session exists by name
  ./session_manager.sh exists parent-repo-castlebuilder
  
  # Get UUID from name
  UUID=$(./session_manager.sh get-uuid parent-repo-castlebuilder)
HELP
        ;;
esac