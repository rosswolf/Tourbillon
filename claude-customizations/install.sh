#!/bin/bash

# Installation script for Godot compile check hook
# Usage: ./install.sh [project-directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get target directory from argument or current directory
TARGET_DIR="${1:-.}"

echo -e "${GREEN}Godot Compile Check Hook Installer${NC}"
echo "======================================"
echo ""

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${RED}Error: Directory $TARGET_DIR does not exist${NC}"
    exit 1
fi

# Check if it's a Godot project
if [ ! -f "$TARGET_DIR/project.godot" ]; then
    echo -e "${YELLOW}Warning: No project.godot found in $TARGET_DIR${NC}"
    echo "This may not be a Godot project directory."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Create backup directory
BACKUP_DIR="$TARGET_DIR/.compile-check-backup"
mkdir -p "$BACKUP_DIR"

# Function to install a file
install_file() {
    local source="$1"
    local dest="$2"
    local filename=$(basename "$source")
    
    # Check if file already exists
    if [ -f "$dest" ]; then
        echo -e "${YELLOW}File $filename already exists${NC}"
        read -p "Backup and replace? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp "$dest" "$BACKUP_DIR/$filename.$(date +%Y%m%d_%H%M%S).backup"
            echo "  Backed up to $BACKUP_DIR/"
        else
            echo "  Skipping $filename"
            return
        fi
    fi
    
    cp "$source" "$dest"
    echo -e "${GREEN}✓${NC} Installed $filename"
}

# Install compile check hook
echo ""
echo "Installing compile check hook..."
install_file "$SCRIPT_DIR/godot-hooks/godot_compile_check.gd" "$TARGET_DIR/godot_compile_check.gd"

# Ask about documentation
echo ""
read -p "Install documentation files? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$TARGET_DIR/docs/compile-check"
    for doc in "$SCRIPT_DIR/docs"/*.md; do
        if [ -f "$doc" ]; then
            install_file "$doc" "$TARGET_DIR/docs/compile-check/$(basename "$doc")"
        fi
    done
fi

# Ask about CI/CD setup
echo ""
read -p "Add GitHub Actions workflow? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$TARGET_DIR/.github/workflows"
    install_file "$SCRIPT_DIR/examples/ci_workflow.yml" "$TARGET_DIR/.github/workflows/godot-compile-check.yml"
fi

# Create a basic run script
echo ""
read -p "Create run script? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > "$TARGET_DIR/run-compile-check.sh" << 'EOF'
#!/bin/bash
# Run Godot compile check
echo "Running Godot compile check..."
godot --headless --script godot_compile_check.gd
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "✅ All checks passed!"
else
    echo "❌ Checks failed. Please fix the issues above."
fi
exit $exit_code
EOF
    chmod +x "$TARGET_DIR/run-compile-check.sh"
    echo -e "${GREEN}✓${NC} Created run-compile-check.sh"
fi

# Show summary
echo ""
echo -e "${GREEN}Installation Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Review exemption configuration in godot_compile_check.gd"
echo "2. Run the check: godot --headless --script godot_compile_check.gd"
echo "   Or use: ./run-compile-check.sh"
echo "3. Add exemptions as needed for legacy code"
echo "4. Commit the changes to your repository"
echo ""
echo "For more information, see:"
echo "  - docs/compile-check/PRIVATE_VARIABLES.md"
echo "  - docs/compile-check/TYPE_SAFETY.md"
echo "  - docs/compile-check/EXEMPTIONS.md"

# Offer to run the check now
echo ""
read -p "Run compile check now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$TARGET_DIR"
    echo ""
    echo "Running compile check..."
    echo "========================"
    godot --headless --script godot_compile_check.gd || true
fi