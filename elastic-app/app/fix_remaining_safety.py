#!/usr/bin/env python3
"""Fix remaining type safety issues in GDScript files."""

import re
from pathlib import Path
from typing import List, Tuple

# Specific files and fixes needed based on the checker output
FIXES = [
    ("src/scenes/core/entities/battle_entity.gd", 25, "decrement_status_effect", "-> void"),
    ("src/scenes/core/entities/mainplate.gd", 13, "_init", "-> void"),
    ("src/scenes/core/entities/card.gd", 275, "array_init", None),
    ("src/scenes/core/entities/card.gd", 287, "array_init", None),
    ("src/scenes/core/entities/button.gd", 37, "activate_slot_effect", "-> void"),
    ("src/scenes/core/resources/capped_resource.gd", 31, "_init", "-> void"),
    ("src/scenes/core/resources/capped_resource.gd", 38, "increment", "-> void"),
    ("src/scenes/core/resources/capped_resource.gd", 41, "decrement", "-> void"),
    ("src/scenes/core/resources/relic_manager.gd", 12, "has_relic", "-> bool"),
    ("src/scenes/core/resources/cost.gd", 9, "_init", "-> void"),
    ("src/scenes/core/resources/cost.gd", 32, "_init", "-> void"),
    ("src/scenes/core/resources/game_resource.gd", 38, "_init", "-> void"),
    ("src/scenes/core/effects/move_descriptor_effect.gd", 7, "_init", "-> void"),
    ("src/scenes/core/effects/move_descriptor_effect.gd", 47, "activate", "-> bool"),
    ("src/scenes/core/effects/one_time_effect.gd", 22, "_init", "-> void"),
    ("src/scenes/core/effects/one_time_effect.gd", 35, "activate", "-> bool"),
]

def fix_file(filepath: Path, fixes: List[Tuple[int, str, str]]) -> bool:
    """Fix type safety issues in a single file."""
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    modified = False
    
    for line_num, fix_type, return_type in fixes:
        # Adjust for 0-based indexing
        idx = line_num - 1
        if idx >= len(lines):
            continue
            
        line = lines[idx]
        
        if fix_type == "array_init":
            # Fix untyped array initialization
            if "[]" in line and "Array[" not in line:
                # Extract the variable name and try to infer type from context
                if "card.tags" in line:
                    lines[idx] = line.replace("[]", "[] as Array[String]")
                elif "card.keywords" in line:
                    lines[idx] = line.replace("[]", "[] as Array[String]")
                else:
                    # Default to Array[String] if we can't infer
                    lines[idx] = line.replace("[]", "[] as Array[String]")
                modified = True
                print(f"  Fixed array at line {line_num}")
        elif fix_type == "dict_init":
            # Fix untyped dictionary initialization
            if "{}" in line and "Dictionary[" not in line:
                lines[idx] = line.replace("{}", "{} as Dictionary")
                modified = True
                print(f"  Fixed dictionary at line {line_num}")
        else:
            # Fix missing return type
            # Check if it already has a return type
            if "->" in line:
                continue
                
            # Find where to insert the return type
            if "func " in line:
                # Look for the closing parenthesis
                paren_pos = line.rfind(')')
                colon_pos = line.rfind(':')
                
                if paren_pos != -1 and colon_pos != -1:
                    # Insert return type between ) and :
                    before = line[:paren_pos + 1]
                    after = line[paren_pos + 1:]
                    lines[idx] = before + " " + return_type + after
                    modified = True
                    print(f"  Added {return_type} to {fix_type} at line {line_num}")
    
    if modified:
        with open(filepath, 'w') as f:
            f.writelines(lines)
    
    return modified

def main():
    """Main entry point."""
    print("Fixing remaining type safety issues...")
    
    # Group fixes by file
    fixes_by_file = {}
    for filepath, line_num, fix_type, return_type in FIXES:
        if filepath not in fixes_by_file:
            fixes_by_file[filepath] = []
        fixes_by_file[filepath].append((line_num, fix_type, return_type))
    
    total_fixed = 0
    for filepath, fixes in fixes_by_file.items():
        file_path = Path(filepath)
        if not file_path.exists():
            print(f"Warning: {filepath} not found")
            continue
            
        print(f"\nFixing {filepath}...")
        if fix_file(file_path, fixes):
            total_fixed += 1
    
    print(f"\n✅ Fixed {total_fixed} files")

if __name__ == "__main__":
    main()