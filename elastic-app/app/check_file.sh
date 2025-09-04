#!/bin/bash

# Script to check specific Godot files for type safety issues
# Usage: ./check_file.sh path/to/file.gd

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file.gd> [file2.gd ...]"
    echo "Example: $0 src/scenes/core/effects/simple_effect_processor.gd"
    exit 1
fi

echo "Checking files for type safety issues..."
echo "========================================"

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        continue
    fi
    
    echo ""
    echo "Checking: $file"
    echo "-------------------"
    
    # Check for untyped local variables (var name = value without : Type)
    echo "🔍 Untyped variables:"
    grep -n "^\s*var [a-zA-Z_][a-zA-Z0-9_]* = " "$file" | grep -v ":" | head -20 || echo "  ✅ None found"
    
    # Check for functions without return types
    echo ""
    echo "🔍 Functions without return types:"
    grep -n "^\s*func [a-zA-Z_][a-zA-Z0-9_]*([^)]*)\s*:" "$file" | grep -v "\->" | head -10 || echo "  ✅ None found"
    
    # Check for untyped parameters
    echo ""
    echo "🔍 Parameters without types (approximate):"
    grep -n "func.*([^:)]*[a-zA-Z_][a-zA-Z0-9_]*\s*[,)]" "$file" | head -10 || echo "  ✅ None found"
    
    # Check for untyped arrays
    echo ""
    echo "🔍 Untyped Arrays (should use Array[Type]):"
    grep -n ":\s*Array\s*=" "$file" | head -10 || echo "  ✅ None found"
    
    # Check for private variable access from other objects
    echo ""
    echo "🔍 Private variable access violations:"
    grep -n "\b[a-zA-Z_][a-zA-Z0-9_]*\.__[a-zA-Z_]" "$file" | grep -v "self\.__" | grep -v "super\.__" | head -10 || echo "  ✅ None found"
done

echo ""
echo "========================================"
echo "Check complete!"