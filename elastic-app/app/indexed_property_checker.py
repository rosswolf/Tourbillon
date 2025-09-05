#!/usr/bin/env python3
"""
Property Access Checker using PROJECT_INDEX.json
Validates property accesses against the indexed class definitions.
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, Set, List

def load_index() -> Dict:
    """Load the PROJECT_INDEX.json file."""
    index_path = Path("PROJECT_INDEX.json")
    if not index_path.exists():
        print("❌ PROJECT_INDEX.json not found. Run /index first!")
        sys.exit(1)
    
    with open(index_path, 'r') as f:
        return json.load(f)

def extract_class_properties(index_data: Dict) -> Dict[str, Set[str]]:
    """Extract properties for each class from the index."""
    class_props = {}
    
    for file_path, file_data in index_data.get('files', {}).items():
        # Look for class_name declarations
        for class_name, class_info in file_data.get('classes', {}).items():
            if class_name and class_name != 'unknown':
                properties = set()
                
                # Get properties from the class
                for prop in class_info.get('properties', []):
                    properties.add(prop['name'])
                
                # Get public methods (they can be accessed like properties in some contexts)
                for func in class_info.get('functions', []):
                    if not func['name'].startswith('_'):
                        properties.add(func['name'])
                
                class_props[class_name] = properties
    
    return class_props

def check_property_access_in_file(filepath: Path, class_props: Dict[str, Set[str]]) -> List[str]:
    """Check property accesses in a single file."""
    errors = []
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Track variable types in this file
    var_types = {}
    
    for line_num, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith('#'):
            continue
        
        # Track variable declarations with types
        # Pattern: var name: Type
        var_decl = re.search(r'\bvar\s+(\w+)\s*:\s*(\w+)', line)
        if var_decl:
            var_types[var_decl.group(1)] = var_decl.group(2)
        
        # Pattern: var name = Type.new()
        var_new = re.search(r'\bvar\s+(\w+)\s*=\s*(\w+)\.new\(', line)
        if var_new:
            var_types[var_new.group(1)] = var_new.group(2)
        
        # Pattern: func(param: Type)
        param_match = re.search(r'\((\w+)\s*:\s*(\w+)', line)
        if param_match:
            var_types[param_match.group(1)] = param_match.group(2)
        
        # Check property accesses
        # Pattern: variable.property (not followed by parentheses)
        access_pattern = r'\b(\w+)\.(\w+)\b(?!\s*\()'
        
        for match in re.finditer(access_pattern, line):
            var_name = match.group(1)
            prop_name = match.group(2)
            
            # Skip if the variable is 'self' or a common singleton
            if var_name in ['self', 'GlobalSignals', 'GlobalGameManager', 'StaticData', 'PreloadScenes']:
                continue
            
            # Check if we know the type of this variable
            if var_name in var_types:
                var_type = var_types[var_name]
                
                # Check if this type exists in our class properties
                if var_type in class_props:
                    valid_props = class_props[var_type]
                    
                    # Check if the property exists
                    if prop_name not in valid_props and not prop_name.startswith('_'):
                        # Skip common built-in properties
                        builtin_props = {'position', 'global_position', 'visible', 'modulate', 
                                       'size', 'length', 'name', 'instance_id'}
                        if prop_name not in builtin_props:
                            errors.append(
                                f"{filepath}:{line_num}: Unknown property '{prop_name}' on {var_type}. "
                                f"Available: {', '.join(sorted(list(valid_props)[:3]))}..."
                            )
    
    return errors

def main():
    print("🔍 Property Access Checker (using PROJECT_INDEX.json)")
    print("=" * 60)
    
    # Load the index
    index_data = load_index()
    print(f"✓ Loaded index from {index_data.get('indexed_at', 'unknown time')}")
    
    # Extract class properties
    class_props = extract_class_properties(index_data)
    print(f"✓ Found {len(class_props)} classes with properties")
    
    # Check all GDScript files
    src_dir = Path("src/scenes")
    if not src_dir.exists():
        print("❌ src/scenes directory not found")
        sys.exit(1)
    
    all_errors = []
    files_checked = 0
    
    for gd_file in src_dir.rglob("*.gd"):
        errors = check_property_access_in_file(gd_file, class_props)
        all_errors.extend(errors)
        files_checked += 1
    
    print(f"✓ Checked {files_checked} files")
    
    # Print results
    print("\n" + "=" * 60)
    if all_errors:
        print("❌ Property Access Issues Found:")
        for error in all_errors[:10]:  # Show first 10
            print(f"  {error}")
        if len(all_errors) > 10:
            print(f"  ... and {len(all_errors) - 10} more")
        print(f"\nTotal issues: {len(all_errors)}")
        sys.exit(1)
    else:
        print("✅ All property accesses look valid!")
        sys.exit(0)

if __name__ == "__main__":
    main()