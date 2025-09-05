#!/usr/bin/env python3
"""
Enhanced Property Checker using PROJECT_INDEX.json
Validates property accesses against actual class definitions in the index.
"""

import json
import re
import sys
import subprocess
from pathlib import Path
from typing import Dict, Set, List, Tuple, Optional

class IndexedPropertyChecker:
    def __init__(self):
        self.class_properties: Dict[str, Set[str]] = {}
        self.class_methods: Dict[str, Set[str]] = {}
        self.errors: List[str] = []
        self.warnings: List[str] = []
        
    def update_index(self) -> bool:
        """Update the PROJECT_INDEX.json by running the index command."""
        print("📝 Updating project index...")
        
        # Try to find and run the index command
        index_paths = [
            Path.home() / "bin" / "index",
            Path("/usr/local/bin/index"),
            Path("~/bin/index").expanduser()
        ]
        
        index_cmd = None
        for path in index_paths:
            if path.exists():
                index_cmd = str(path)
                break
        
        if not index_cmd:
            print("⚠️  Index command not found, skipping index update")
            return False
        
        try:
            # Run index from project root (parent of elastic-app)
            project_root = Path.cwd().parent.parent
            result = subprocess.run(
                [index_cmd, "elastic-app"],
                cwd=project_root,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0:
                print("✅ Index updated successfully")
                return True
            else:
                print(f"⚠️  Index update failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"⚠️  Could not update index: {e}")
            return False
    
    def load_index(self) -> bool:
        """Load the PROJECT_INDEX.json file."""
        # Look for index in project root
        index_paths = [
            Path.cwd().parent.parent / "PROJECT_INDEX.json",
            Path.cwd() / "PROJECT_INDEX.json",
            Path("PROJECT_INDEX.json")
        ]
        
        index_data = None
        for index_path in index_paths:
            if index_path.exists():
                with open(index_path, 'r') as f:
                    index_data = json.load(f)
                print(f"✅ Loaded index from {index_path}")
                break
        
        if not index_data:
            print("❌ PROJECT_INDEX.json not found")
            return False
        
        # Extract properties and methods for each class
        for class_name, class_info in index_data.get('classes', {}).items():
            if not class_name or class_name == 'unknown':
                continue
            
            # Extract properties
            properties = set()
            for prop in class_info.get('properties', []):
                # Clean up property names (remove type annotations)
                prop_name = prop.split(':')[0].strip()
                # Keep the full property name including __ prefix
                if prop_name:
                    properties.add(prop_name)
                    # Also add without prefix for cases where it's accessed internally
                    if prop_name.startswith('__'):
                        properties.add(prop_name[2:])  # Add version without __
            
            # Extract methods
            methods = set()
            for method in class_info.get('methods', []):
                # Extract method name from signature
                method_name = re.match(r'^(\w+)', method)
                if method_name:
                    methods.add(method_name.group(1))
            
            # Store in our dictionaries (use lowercase for case-insensitive lookup)
            self.class_properties[class_name.lower()] = properties
            self.class_methods[class_name.lower()] = methods
        
        print(f"📚 Loaded {len(self.class_properties)} classes from index")
        return True
    
    def get_variable_type(self, lines: List[str], var_name: str, current_line: int) -> Optional[str]:
        """Try to determine the type of a variable from context."""
        
        # Search backwards from current line for variable declaration
        for i in range(current_line - 1, max(0, current_line - 50), -1):
            line = lines[i]
            
            # Skip comments
            if line.strip().startswith('#'):
                continue
            
            # Pattern: var var_name: Type
            type_match = re.search(rf'\bvar\s+{re.escape(var_name)}\s*:\s*(\w+)', line)
            if type_match:
                return type_match.group(1)
            
            # Pattern: var var_name := Type.new()
            new_match = re.search(rf'\bvar\s+{re.escape(var_name)}\s*:?=\s*(\w+)\.new\(', line)
            if new_match:
                return new_match.group(1)
            
            # Pattern: var var_name = get_something() where func returns Type
            assign_match = re.search(rf'\bvar\s+{re.escape(var_name)}\s*:?=\s*get_(\w+)', line)
            if assign_match:
                # Try to infer type from getter name
                return assign_match.group(1).capitalize()
            
            # Pattern: function parameter (param: Type)
            param_match = re.search(rf'\({re.escape(var_name)}\s*:\s*(\w+)', line)
            if param_match:
                return param_match.group(1)
            
            # Pattern: for var in array where we might know the array type
            for_match = re.search(rf'\bfor\s+{re.escape(var_name)}\s+in\s+', line)
            if for_match:
                # This is harder to infer, skip for now
                return None
        
        # Special cases for common variable names - be more strict
        if var_name == 'resource':
            return 'CappedResource'
        # Don't assume 'card' variable is always Card class
        # Don't assume 'gremlin' variable is always Gremlin class
        
        return None
    
    def check_file(self, filepath: Path) -> None:
        """Check property accesses in a single file."""
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        for line_num, line in enumerate(lines, 1):
            # Skip comments
            if line.strip().startswith('#'):
                continue
            
            # Look for property access pattern: variable.property
            # Negative lookahead (?!\() ensures it's not a method call
            access_pattern = r'\b(\w+)\.(\w+)\b(?!\s*\()'
            
            for match in re.finditer(access_pattern, line):
                var_name = match.group(1)
                prop_name = match.group(2)
                
                # Skip enum access (e.g., Card.RarityType)
                if prop_name[0].isupper() and '_' not in prop_name:
                    continue
                
                # Don't skip private properties - we should check them too
                
                # Skip common singletons and built-ins
                if var_name in ['self', 'super', 'GlobalSignals', 'GlobalGameManager', 
                               'StaticData', 'PreloadScenes', 'OS', 'Input', 'Engine']:
                    continue
                
                # Skip if it's a numeric literal (like 1.0)
                if var_name.isdigit():
                    continue
                
                # Try to determine the variable's type
                var_type = self.get_variable_type(lines, var_name, line_num - 1)
                
                # Only check if we're confident about the type
                if var_type and var_type not in ['Variant', 'var', 'auto']:
                    var_type_lower = var_type.lower()
                    
                    # Check if we know about this class
                    if var_type_lower in self.class_properties:
                        valid_props = self.class_properties[var_type_lower]
                        valid_methods = self.class_methods[var_type_lower]
                        
                        # Check if property exists
                        if prop_name not in valid_props and prop_name not in valid_methods:
                            # Check for common built-in properties
                            builtin_props = {
                                'position', 'global_position', 'rotation', 'scale',
                                'visible', 'modulate', 'name', 'size', 'length',
                                'instance_id', 'template_id', 'display_name',
                                'x', 'y', 'z', 'width', 'height',
                                'text', 'mouse_filter', 'z_index', 'queue_free',
                                'mouse_entered', 'mouse_exited', 'pressed',
                                'tscn', 'card_data', 'gremlin_data',
                                # Signal names (these are accessed as properties but are signals)
                                'hp_changed', 'defeated', 'disruption_triggered',
                                'damage_received', 'shields_changed', 'barrier_broken',
                                # Common UI properties  
                                'custom_minimum_size', 'anchor_left', 'anchor_right',
                                # Control/Button properties that were missing
                                'flat', 'size_flags_horizontal', 'size_flags_vertical',
                                'size_flags_stretch_ratio', 'focus_mode', 'disabled',
                                # Card effect properties (dynamically loaded from JSON)
                                'on_ready_effect', 'on_replace_effect', 'on_destroy_effect',
                                'on_discard_effect', 'on_draw_effect', 'on_exhaust_effect',
                                'passive_effect', 'conditional_effect',
                                # Effect subclass properties
                                '__f', '__valid_source_types', '__valid_target_types'
                            }
                            
                            if prop_name not in builtin_props:
                                # Generate suggestion if possible
                                suggestion = self.find_similar_property(prop_name, valid_props)
                                
                                error_msg = f"{filepath}:{line_num}: Property '{prop_name}' not found on {var_type}"
                                if suggestion:
                                    error_msg += f" (did you mean '{suggestion}'?)"
                                
                                # Show available properties for context
                                if valid_props:
                                    props_list = sorted(list(valid_props))[:5]
                                    error_msg += f" | Available: {', '.join(props_list)}"
                                    if len(valid_props) > 5:
                                        error_msg += "..."
                                
                                self.errors.append(error_msg)
    
    def find_similar_property(self, prop_name: str, valid_props: Set[str]) -> Optional[str]:
        """Find a similar property name that might be the intended one."""
        prop_lower = prop_name.lower()
        
        # Direct replacements for known mistakes
        known_mistakes = {
            'current': 'amount',
            'health': 'current_hp',
            'max_health': 'max_hp',
            'armor': 'shields',
            'block': 'shields'
        }
        
        if prop_lower in known_mistakes:
            suggestion = known_mistakes[prop_lower]
            if suggestion in valid_props:
                return suggestion
        
        # Find properties that contain the attempted name
        for valid in valid_props:
            if prop_lower in valid.lower() or valid.lower() in prop_lower:
                return valid
        
        # Find properties with similar prefixes
        for valid in valid_props:
            if valid[:3].lower() == prop_lower[:3]:
                return valid
        
        return None
    
    def check_directory(self, directory: Path) -> None:
        """Check all GDScript files in a directory."""
        for gd_file in directory.rglob("*.gd"):
            self.check_file(gd_file)
    
    def print_results(self) -> bool:
        """Print check results and return success status."""
        if self.errors:
            print("\n❌ Property Access Errors Found:")
            print("=" * 60)
            
            # Group errors by file for better readability
            errors_by_file: Dict[str, List[str]] = {}
            for error in self.errors:
                if ':' in error:
                    file_part = error.split(':')[0]
                    if file_part not in errors_by_file:
                        errors_by_file[file_part] = []
                    errors_by_file[file_part].append(error)
            
            # Print up to 20 errors
            shown = 0
            for file_path, file_errors in errors_by_file.items():
                for error in file_errors:
                    print(f"  {error}")
                    shown += 1
                    if shown >= 20:
                        break
                if shown >= 20:
                    break
            
            if len(self.errors) > 20:
                print(f"\n  ... and {len(self.errors) - 20} more errors")
            
            print(f"\nTotal errors: {len(self.errors)}")
            return False
        else:
            print("\n✅ All property accesses are valid!")
            return True

def main():
    checker = IndexedPropertyChecker()
    
    print("🔍 Enhanced Property Checker (using PROJECT_INDEX.json)")
    print("=" * 60)
    
    # Update the index first
    checker.update_index()
    
    # Load the index
    if not checker.load_index():
        print("Failed to load index, exiting")
        sys.exit(1)
    
    # Check the source directory
    src_dir = Path("src/scenes")
    if not src_dir.exists():
        # Try from different locations
        possible_paths = [
            Path("elastic-app/app/src/scenes"),
            Path("app/src/scenes"),
            Path.cwd() / "src" / "scenes"
        ]
        
        for path in possible_paths:
            if path.exists():
                src_dir = path
                break
    
    if not src_dir.exists():
        print(f"❌ Source directory not found: {src_dir}")
        sys.exit(1)
    
    print(f"📁 Checking files in: {src_dir}")
    checker.check_directory(src_dir)
    
    # Print results
    success = checker.print_results()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()