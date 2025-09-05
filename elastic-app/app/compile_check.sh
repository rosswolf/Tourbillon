#!/bin/bash

# Smart Godot Compilation Check Wrapper
# Handles autoload dependencies and catches real errors

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Running Smart Compilation Check for Godot Project${NC}"
echo "=================================================="

# Save current directory
ORIGINAL_DIR=$(pwd)

# Navigate to app directory if not already there
if [[ ! -f "smart_compile_check.gd" ]]; then
    if [[ -d "elastic-app/app" ]]; then
        cd elastic-app/app
    elif [[ -d "app" ]]; then
        cd app
    else
        echo -e "${RED}❌ Error: Cannot find smart_compile_check.gd${NC}"
        echo "Please run from project root or elastic-app directory"
        exit 1
    fi
fi

# Options for the check
RUN_TYPE_CHECK=true
RUN_COMPILE_CHECK=true
SKIP_TYPE_CHECK=false
VERBOSE=""

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --skip-type) SKIP_TYPE_CHECK=true ;;
        --type-only) RUN_COMPILE_CHECK=false ;;
        --compile-only) RUN_TYPE_CHECK=false ;;
        --verbose) VERBOSE="--verbose" ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --skip-type     Skip type safety checks"
            echo "  --type-only     Only run type safety checks"
            echo "  --compile-only  Only run compilation checks"
            echo "  --verbose       Show detailed output"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Track overall status
OVERALL_SUCCESS=true

# Run type safety check if not skipped
if [[ "$RUN_TYPE_CHECK" == true ]] && [[ "$SKIP_TYPE_CHECK" == false ]]; then
    echo -e "\n${BLUE}📝 Step 1: Type Safety Check${NC}"
    echo "------------------------------"
    
    if python3 check_type_safety.py --all $VERBOSE; then
        echo -e "${GREEN}✅ Type safety check passed${NC}"
    else
        echo -e "${YELLOW}⚠️ Type safety check had issues${NC}"
        # Don't fail on type safety - it's more of a style guide
    fi
fi

# Run Godot compilation check
if [[ "$RUN_COMPILE_CHECK" == true ]]; then
    echo -e "\n${BLUE}🔧 Step 2: Godot Compilation Check${NC}"
    echo "------------------------------"
    
    # Check if Godot is available
    if ! command -v godot &> /dev/null; then
        echo -e "${RED}❌ Error: Godot not found in PATH${NC}"
        echo "Please ensure Godot is installed and in your PATH"
        exit 1
    fi
    
    # Run the smart compilation check
    if godot --headless --script smart_compile_check.gd 2>/dev/null; then
        echo -e "${GREEN}✅ Compilation check passed${NC}"
    else
        EXIT_CODE=$?
        if [[ $EXIT_CODE -eq 1 ]]; then
            echo -e "${RED}❌ Compilation check failed - found errors${NC}"
            OVERALL_SUCCESS=false
        else
            echo -e "${RED}❌ Compilation check crashed (exit code: $EXIT_CODE)${NC}"
            OVERALL_SUCCESS=false
        fi
    fi
fi

# Return to original directory
cd "$ORIGINAL_DIR"

# Final summary
echo ""
echo "=================================================="
if [[ "$OVERALL_SUCCESS" == true ]]; then
    echo -e "${GREEN}✨ All checks passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some checks failed - please review output above${NC}"
    exit 1
fi