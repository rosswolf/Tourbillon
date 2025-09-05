#!/usr/bin/env python3
"""
Better indexer - includes class properties/variables
"""
import os
import json
import re
from pathlib import Path

def index_godot_files():
    """Create index of Godot classes with methods AND properties"""
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
                
                # Extract properties/variables (var, @export, @onready)
                # Match: var name: Type = value or var name = value
                vars_pattern = r'^(?:@export\s+)?(?:@onready\s+)?var\s+(\w+)(?:\s*:\s*([^=\n]+))?(?:\s*=\s*[^#\n]+)?'
                variables = re.findall(vars_pattern, content, re.MULTILINE)
                
                # Extract signals
                signals = re.findall(r'^signal\s+(\w+)(?:\(([^)]*)\))?', content, re.MULTILINE)
                
                # Extract enums
                enums = re.findall(r'^enum\s+(\w+)', content, re.MULTILINE)
                
                if methods or variables or signals:
                    class_data = {"file": filepath}
                    
                    if variables:
                        class_data["properties"] = [
                            f"{name}: {typ.strip()}" if typ else name 
                            for name, typ in variables
                        ]
                    
                    if methods:
                        class_data["methods"] = [
                            f"{name}({params})" for name, params in methods
                        ]
                    
                    if signals:
                        class_data["signals"] = [
                            f"{name}({params})" if params else name 
                            for name, params in signals
                        ]
                    
                    if enums:
                        class_data["enums"] = enums
                    
                    index["classes"][class_name] = class_data
    
    # Save as compact JSON
    with open("BETTER_INDEX.json", "w") as f:
        json.dump(index, f, indent=2)
    
    size = os.path.getsize("BETTER_INDEX.json")
    print(f"Created BETTER_INDEX.json ({size//1024}KB)")
    print(f"Indexed {len(index['classes'])} classes")
    
    # Count totals
    total_props = sum(len(c.get("properties", [])) for c in index["classes"].values())
    total_methods = sum(len(c.get("methods", [])) for c in index["classes"].values())
    print(f"  - {total_props} properties")
    print(f"  - {total_methods} methods")

if __name__ == "__main__":
    index_godot_files()