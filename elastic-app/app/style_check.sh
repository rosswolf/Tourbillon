#!/bin/bash

# Godot Style Checker Wrapper
# Enforces coding standards and best practices

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎨 Running Godot Style Checker${NC}"
echo "=================================="

# Default options
CHECK_ALL=false
VERBOSE=""
ERRORS_ONLY=""
MAX_VIOLATIONS=100

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --all) CHECK_ALL=true ;;
        --verbose|-v) VERBOSE="--verbose" ;;
        --errors-only) ERRORS_ONLY="--errors-only" ;;
        --max-violations) MAX_VIOLATIONS="$2"; shift ;;
        --help)
            echo "Usage: $0 [options] [files...]"
            echo "Options:"
            echo "  --all              Check all .gd files in project"
            echo "  --verbose, -v      Show detailed output with suggestions"
            echo "  --errors-only      Only show errors, not warnings"
            echo "  --max-violations N Maximum violations to show (default: 100)"
            echo "  --help             Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                     # Check all files in src/"
            echo "  $0 --all               # Check all .gd files in project"
            echo "  $0 src/player.gd       # Check specific file"
            echo "  $0 --errors-only       # Only show errors"
            exit 0
            ;;
        *) FILES="$FILES $1" ;;
    esac
    shift
done

# Build command
CMD="python3 style_check.py"

if [[ "$CHECK_ALL" == true ]]; then
    CMD="$CMD --all"
elif [[ -n "$FILES" ]]; then
    CMD="$CMD $FILES"
fi

if [[ -n "$VERBOSE" ]]; then
    CMD="$CMD --verbose"
fi

if [[ -n "$ERRORS_ONLY" ]]; then
    CMD="$CMD --errors-only"
fi

CMD="$CMD --max-violations $MAX_VIOLATIONS"

# Run the style checker
if $CMD; then
    echo -e "\n${GREEN}✨ Style check passed!${NC}"
    exit 0
else
    EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 1 ]]; then
        echo -e "\n${RED}❌ Style check failed - please fix errors${NC}"
    else
        echo -e "\n${RED}❌ Style checker crashed (exit code: $EXIT_CODE)${NC}"
    fi
    exit $EXIT_CODE
fi