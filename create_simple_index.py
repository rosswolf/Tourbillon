#!/usr/bin/env python3
"""
Lightweight indexer - just what you actually need
"""
import os
import json
import re
from pathlib import Path

def index_godot_files():
    """Create a simple index of Godot classes and methods"""
    index = {"classes": {}}
    
    # Find all .gd files
    for root, dirs, files in os.walk("elastic-app"):
        # Skip asset directories
        if any(skip in root for skip in ["cc0_assets", "ai_assets", ".godot"]):
            continue
            
        for file in files:
            if file.endswith(".gd"):
                filepath = os.path.join(root, file)
                class_name = Path(filepath).stem
                
                with open(filepath, 'r') as f:
                    content = f.read()
                    
                # Extract public methods (not starting with _)
                methods = re.findall(r'^func\s+([a-z]\w*)\s*\(([^)]*)\)', content, re.MULTILINE)
                
                if methods:
                    index["classes"][class_name] = {
                        "file": filepath,
                        "methods": [f"{name}({params})" for name, params in methods]
                    }
    
    # Save as compact JSON
    with open("SIMPLE_INDEX.json", "w") as f:
        json.dump(index, f, indent=2)
    
    size = os.path.getsize("SIMPLE_INDEX.json")
    print(f"Created SIMPLE_INDEX.json ({size//1024}KB)")
    print(f"Indexed {len(index['classes'])} classes")

if __name__ == "__main__":
    index_godot_files()