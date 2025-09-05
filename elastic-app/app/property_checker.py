#!/usr/bin/env python3
"""
Property Access Checker for GDScript
Validates that property accesses match the actual properties defined in classes.
"""

import re
import os
import sys
from pathlib import Path
from typing import Dict, Set, List, Tuple

class PropertyChecker:
    def __init__(self):
        self.class_properties: Dict[str, Set[str]] = {}
        self.class_methods: Dict[str, Set[str]] = {}
        self.class_inheritance: Dict[str, str] = {}
        self.errors: List[str] = []
        
    def parse_class_file(self, filepath: Path) -> None:
        """Parse a GDScript file to extract class name, properties, and methods."""
        with open(filepath, 'r') as f:
            content = f.read()
            
        # Extract class name
        class_match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
        if not class_match:
            return  # Not a named class
            
        class_name = class_match.group(1)
        
        # Extract parent class
        extends_match = re.search(r'^extends\s+(\w+)', content, re.MULTILINE)
        if extends_match:
            self.class_inheritance[class_name] = extends_match.group(1)
        
        # Extract properties (var declarations)
        properties = set()
        
        # Standard variables
        var_pattern = r'^var\s+(\w+)\s*[:\s=]'
        for match in re.finditer(var_pattern, content, re.MULTILINE):
            prop_name = match.group(1)
            if not prop_name.startswith('_'):  # Only public properties
                properties.add(prop_name)
        
        # @export variables
        export_pattern = r'^@export\s+var\s+(\w+)'
        for match in re.finditer(export_pattern, content, re.MULTILINE):
            properties.add(match.group(1))
        
        # @onready variables
        onready_pattern = r'^@onready\s+var\s+(\w+)'
        for match in re.finditer(onready_pattern, content, re.MULTILINE):
            properties.add(match.group(1))
        
        # Extract methods
        methods = set()
        func_pattern = r'^(?:static\s+)?func\s+(\w+)\s*\('
        for match in re.finditer(func_pattern, content, re.MULTILINE):
            method_name = match.group(1)
            if not method_name.startswith('_'):  # Only public methods
                methods.add(method_name)
        
        self.class_properties[class_name] = properties
        self.class_methods[class_name] = methods
        
    def get_all_properties(self, class_name: str) -> Set[str]:
        """Get all properties including inherited ones."""
        all_props = set()
        
        # Get properties from this class
        if class_name in self.class_properties:
            all_props.update(self.class_properties[class_name])
        
        # Get inherited properties
        if class_name in self.class_inheritance:
            parent = self.class_inheritance[class_name]
            if parent in self.class_properties:
                all_props.update(self.get_all_properties(parent))
        
        return all_props
    
    def get_all_methods(self, class_name: str) -> Set[str]:
        """Get all methods including inherited ones."""
        all_methods = set()
        
        # Get methods from this class
        if class_name in self.class_methods:
            all_methods.update(self.class_methods[class_name])
        
        # Get inherited methods
        if class_name in self.class_inheritance:
            parent = self.class_inheritance[class_name]
            if parent in self.class_methods:
                all_methods.update(self.get_all_methods(parent))
        
        return all_methods
    
    def check_property_access(self, filepath: Path) -> None:
        """Check property accesses in a file."""
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        for line_num, line in enumerate(lines, 1):
            # Skip comments
            if line.strip().startswith('#'):
                continue
            
            # Look for property access patterns
            # Pattern 1: variable.property
            access_pattern = r'\b(\w+)\.(\w+)\b(?!\s*\()'  # Not followed by ( to exclude method calls
            
            for match in re.finditer(access_pattern, line):
                var_name = match.group(1)
                prop_name = match.group(2)
                
                # Try to determine the type of the variable
                # This is simplified - a full implementation would need type inference
                
                # Check for typed variable declarations in the file
                type_hint = self.find_variable_type(lines, var_name)
                
                if type_hint and type_hint in self.class_properties:
                    all_props = self.get_all_properties(type_hint)
                    if prop_name not in all_props and not prop_name.startswith('_'):
                        # Check if it's a method call without parentheses (which is invalid)
                        all_methods = self.get_all_methods(type_hint)
                        if prop_name in all_methods:
                            self.errors.append(
                                f"{filepath}:{line_num}: Method '{prop_name}' called without parentheses on {type_hint}"
                            )
                        else:
                            # Check common Godot built-in properties we might not have parsed
                            if not self.is_builtin_property(prop_name):
                                self.errors.append(
                                    f"{filepath}:{line_num}: Unknown property '{prop_name}' on {type_hint} (available: {', '.join(sorted(all_props)[:5])}{'...' if len(all_props) > 5 else ''})"
                                )
    
    def find_variable_type(self, lines: List[str], var_name: str) -> str:
        """Try to find the type of a variable from its declaration."""
        # Look for typed declarations
        for line in lines:
            # Pattern: var var_name: Type
            type_pattern = rf'\bvar\s+{var_name}\s*:\s*(\w+)'
            match = re.search(type_pattern, line)
            if match:
                return match.group(1)
            
            # Pattern: var var_name := value (inferred type)
            # Pattern: var var_name = ClassName.new()
            new_pattern = rf'\bvar\s+{var_name}\s*=\s*(\w+)\.new\('
            match = re.search(new_pattern, line)
            if match:
                return match.group(1)
            
            # Pattern: function parameter with type
            param_pattern = rf'\({var_name}\s*:\s*(\w+)[,\)]'
            match = re.search(param_pattern, line)
            if match:
                return match.group(1)
                
            # Pattern: function that returns this variable with known type
            # e.g., func get_resource() -> CappedResource:
            #       return resource
            if f'return {var_name}' in line:
                # Look backwards for the function signature
                for i, prev_line in enumerate(reversed(lines[:lines.index(line)])):
                    if 'func ' in prev_line:
                        return_type_match = re.search(r'->\s*(\w+):', prev_line)
                        if return_type_match:
                            return return_type_match.group(1)
                        break
        
        return ""
    
    def is_builtin_property(self, prop_name: str) -> bool:
        """Check if this is a known Godot built-in property."""
        builtin_props = {
            # Common Node properties
            'name', 'position', 'global_position', 'rotation', 'scale', 
            'visible', 'modulate', 'z_index', 'process_mode',
            # Resource properties  
            'resource_path', 'resource_name',
            # Array/Dictionary properties
            'size', 'length', 'empty',
            # String properties
            'length', 'to_lower', 'to_upper',
        }
        return prop_name in builtin_props
    
    def scan_directory(self, directory: Path) -> None:
        """Scan all GDScript files in a directory."""
        # First pass: Build class definitions
        print("🔍 Building class property database...")
        for gd_file in directory.rglob("*.gd"):
            self.parse_class_file(gd_file)
        
        print(f"  Found {len(self.class_properties)} classes with properties")
        
        # Second pass: Check property accesses
        print("🔍 Checking property accesses...")
        for gd_file in directory.rglob("*.gd"):
            self.check_property_access(gd_file)
    
    def print_results(self) -> None:
        """Print the results of the check."""
        if self.errors:
            print("\n❌ Property Access Errors Found:")
            print("=" * 60)
            for error in self.errors[:20]:  # Limit output
                print(f"  {error}")
            if len(self.errors) > 20:
                print(f"  ... and {len(self.errors) - 20} more")
            print("\n❌ Property check failed")
            return False
        else:
            print("\n✅ All property accesses are valid!")
            return True

def main():
    if len(sys.argv) > 1:
        directory = Path(sys.argv[1])
    else:
        directory = Path("src/scenes")
    
    if not directory.exists():
        print(f"Error: Directory {directory} not found")
        sys.exit(1)
    
    checker = PropertyChecker()
    checker.scan_directory(directory)
    success = checker.print_results()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()