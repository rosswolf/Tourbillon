#!/bin/bash

# Build script for Godot HTML5 export
# Usage: ./build_web.sh

echo "Building Tourbillon for Web..."

# Check if Godot is installed
if ! command -v godot &> /dev/null; then
    echo "Error: Godot is not installed or not in PATH"
    echo "Please install Godot 4.3+ and ensure it's in your PATH"
    exit 1
fi

# Check Godot version
GODOT_VERSION=$(godot --version 2>&1 | head -n 1)
echo "Using Godot version: $GODOT_VERSION"

# Create build directory
echo "Creating build directory..."
mkdir -p build/web

# Import project resources (in case they're not imported)
echo "Importing project resources..."
godot --headless --import || true

# Export to HTML5
echo "Exporting to HTML5..."
godot --headless --export-release "HTML5" build/web/index.html

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Output files are in: build/web/"
    echo ""
    echo "To test locally, you can:"
    echo "1. Use Python: python3 -m http.server 8000 --directory build/web"
    echo "2. Use Node.js: npx serve build/web"
    echo "3. Use any other local web server"
    echo ""
    echo "Then open: http://localhost:8000"
else
    echo "Build failed!"
    echo "Make sure you have HTML5 export templates installed"
    echo "You can install them from: Editor -> Manage Export Templates"
    exit 1
fi