#!/usr/bin/env python3
"""
Check for duplicate class_name declarations in GDScript files.
Duplicate class names will cause compilation errors in Godot.
"""

import os
import sys
import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Set, Tuple

def find_gd_files(directory: str = "src") -> List[Path]:
    """Find all .gd files in the directory."""
    gd_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.gd'):
                gd_files.append(Path(root) / file)
    return gd_files

def extract_class_names(file_path: Path) -> List[str]:
    """Extract all class_name declarations from a GDScript file."""
    class_names = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Find all class_name declarations
        # Pattern matches: class_name ClassName or class_name ClassName extends BaseClass
        pattern = r'^class_name\s+(\w+)'
        matches = re.finditer(pattern, content, re.MULTILINE)
        
        for match in matches:
            class_name = match.group(1)
            class_names.append(class_name)
            
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        
    return class_names

def check_duplicate_classes(directory: str = "src") -> Dict[str, List[Path]]:
    """Check for duplicate class_name declarations across all GDScript files."""
    class_to_files = defaultdict(list)
    
    gd_files = find_gd_files(directory)
    
    for file_path in gd_files:
        class_names = extract_class_names(file_path)
        for class_name in class_names:
            class_to_files[class_name].append(file_path)
    
    # Filter to only duplicates
    duplicates = {
        class_name: files 
        for class_name, files in class_to_files.items() 
        if len(files) > 1
    }
    
    return duplicates

def main():
    """Main function to check for duplicate classes."""
    print("🔍 Checking for duplicate class names...")
    print("=" * 60)
    
    # Check in src directory by default
    duplicates = check_duplicate_classes("src")
    
    if not duplicates:
        print("✅ No duplicate class names found!")
        return 0
    
    # Report duplicates
    print(f"\n❌ Found {len(duplicates)} duplicate class name(s):\n")
    
    for class_name, files in sorted(duplicates.items()):
        print(f"  Class '{class_name}' is defined in {len(files)} files:")
        for file_path in files:
            # Make path relative for cleaner output
            try:
                rel_path = file_path.relative_to(Path.cwd())
            except:
                rel_path = file_path
            print(f"    - {rel_path}")
        print()
    
    print("=" * 60)
    print("❌ Duplicate class names will cause Godot compilation errors!")
    print("Fix by renaming one of the duplicate classes or removing the duplicate file.")
    
    return 1

if __name__ == "__main__":
    sys.exit(main())