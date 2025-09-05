#!/usr/bin/env python3
"""
Build a function signature index for compile-time validation.
Separate from main index to avoid context pollution.
Creates SIGNATURES.json with function signatures for validation.
"""

import json
import re
import os
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class SignatureIndexBuilder:
    def __init__(self):
        self.signatures = {
            "classes": {},
            "godot_builtins": self._get_godot_builtins()
        }
        
    def _get_godot_builtins(self) -> Dict:
        """Pre-populate common Godot built-in class signatures"""
        return {
            # Core types
            "Node": {
                "methods": {
                    "_ready": {"params": []},
                    "_process": {"params": [{"name": "delta", "type": "float"}]},
                    "_physics_process": {"params": [{"name": "delta", "type": "float"}]},
                    "get_node": {"params": [{"name": "path", "type": "NodePath"}]},
                    "add_child": {"params": [{"name": "node", "type": "Node"}]},
                    "queue_free": {"params": []},
                    "set_meta": {"params": [{"name": "name", "type": "String"}, {"name": "value", "type": "Variant"}]},
                    "get_meta": {"params": [{"name": "name", "type": "String"}, {"name": "default", "type": "Variant", "optional": True}]}
                }
            },
            "RefCounted": {
                "methods": {
                    "_init": {"params": []},
                    "reference": {"params": []},
                    "unreference": {"params": []}
                }
            },
            "Resource": {
                "inherits": "RefCounted",
                "methods": {
                    "_init": {"params": []},
                    "duplicate": {"params": [{"name": "subresources", "type": "bool", "optional": True}]}
                }
            },
            "PackedScene": {
                "methods": {
                    "instantiate": {"params": [{"name": "edit_state", "type": "int", "optional": True}]}
                }
            },
            "Array": {
                "methods": {
                    "append": {"params": [{"name": "value", "type": "Variant"}]},
                    "size": {"params": []},
                    "is_empty": {"params": []},
                    "clear": {"params": []},
                    "erase": {"params": [{"name": "value", "type": "Variant"}]},
                    "pop_back": {"params": []},
                    "pop_front": {"params": []}
                }
            },
            "Dictionary": {
                "methods": {
                    "get": {"params": [{"name": "key", "type": "Variant"}, {"name": "default", "type": "Variant", "optional": True}]},
                    "has": {"params": [{"name": "key", "type": "Variant"}]},
                    "size": {"params": []},
                    "is_empty": {"params": []},
                    "clear": {"params": []},
                    "erase": {"params": [{"name": "key", "type": "Variant"}]}
                }
            },
            "String": {
                "methods": {
                    "length": {"params": []},
                    "is_empty": {"params": []},
                    "split": {"params": [{"name": "delimiter", "type": "String"}, {"name": "allow_empty", "type": "bool", "optional": True}]},
                    "strip_edges": {"params": []},
                    "begins_with": {"params": [{"name": "text", "type": "String"}]},
                    "ends_with": {"params": [{"name": "text", "type": "String"}]}
                }
            },
            "Vector2": {
                "constructor": {"params": [{"name": "x", "type": "float", "optional": True}, {"name": "y", "type": "float", "optional": True}]},
                "methods": {
                    "length": {"params": []},
                    "normalized": {"params": []},
                    "distance_to": {"params": [{"name": "to", "type": "Vector2"}]}
                }
            },
            "Color": {
                "constructor": {"params": [
                    {"name": "r", "type": "float", "optional": True},
                    {"name": "g", "type": "float", "optional": True},
                    {"name": "b", "type": "float", "optional": True},
                    {"name": "a", "type": "float", "optional": True}
                ]}
            },
            "Timer": {
                "methods": {
                    "start": {"params": [{"name": "time_sec", "type": "float", "optional": True}]},
                    "stop": {"params": []}
                }
            },
            "Tween": {
                "methods": {
                    "tween_property": {"params": [
                        {"name": "object", "type": "Object"},
                        {"name": "property", "type": "NodePath"},
                        {"name": "final_val", "type": "Variant"},
                        {"name": "duration", "type": "float"}
                    ]},
                    "set_parallel": {"params": [{"name": "parallel", "type": "bool"}]},
                    "chain": {"params": []},
                    "tween_callback": {"params": [{"name": "callback", "type": "Callable"}]}
                }
            }
        }
    
    def extract_function_signatures(self, filepath: Path) -> Dict:
        """Extract function signatures from a GDScript file"""
        class_data = {
            "path": str(filepath),
            "methods": {},
            "signals": {},
            "class_name": None,
            "extends": None,
            "constructors": {}
        }
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Extract class_name
            class_match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
            if class_match:
                class_data["class_name"] = class_match.group(1)
                
            # Extract extends
            extends_match = re.search(r'^extends\s+(\w+)', content, re.MULTILINE)
            if extends_match:
                class_data["extends"] = extends_match.group(1)
                
            # Extract function signatures with parameters
            func_pattern = r'^func\s+(\w+)\s*\(([^)]*)\)\s*(?:->[\s]*([^:]+))?:'
            for match in re.finditer(func_pattern, content, re.MULTILINE):
                func_name = match.group(1)
                params_str = match.group(2).strip()
                return_type = match.group(3).strip() if match.group(3) else None
                
                params = self._parse_parameters(params_str)
                class_data["methods"][func_name] = {
                    "params": params,
                    "return_type": return_type
                }
            
            # Extract signal definitions
            signal_pattern = r'^signal\s+(\w+)\s*(?:\(([^)]*)\))?'
            for match in re.finditer(signal_pattern, content, re.MULTILINE):
                signal_name = match.group(1)
                params_str = match.group(2).strip() if match.group(2) else ""
                params = self._parse_parameters(params_str)
                class_data["signals"][signal_name] = {"params": params}
                
            # Extract constructor patterns for inner classes
            constructor_pattern = r'class\s+(\w+)(?:\s+extends\s+\w+)?:.*?func\s+_init\s*\(([^)]*)\)'
            for match in re.finditer(constructor_pattern, content, re.DOTALL):
                inner_class = match.group(1)
                params_str = match.group(2).strip()
                params = self._parse_parameters(params_str)
                class_data["constructors"][inner_class] = {"params": params}
                
            # Special handling for classes that have new() patterns
            # Look for patterns like DamagePacket.new() 
            new_pattern = r'static\s+func\s+new\s*\(([^)]*)\)'
            for match in re.finditer(new_pattern, content):
                params_str = match.group(1).strip()
                params = self._parse_parameters(params_str)
                class_data["constructors"]["new"] = {"params": params}
            
            # If class extends Resource/RefCounted and no explicit new(), it has default 0-arg constructor
            if class_data["extends"] in ["Resource", "RefCounted", "Node", "Object"] and "new" not in class_data["constructors"]:
                class_data["constructors"]["new"] = {"params": []}
                
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
            
        return class_data
    
    def _parse_parameters(self, params_str: str) -> List[Dict]:
        """Parse function parameter string into structured format"""
        if not params_str:
            return []
            
        params = []
        # Split by comma, handling nested types
        param_parts = self._smart_split(params_str, ',')
        
        for param in param_parts:
            param = param.strip()
            if not param:
                continue
                
            param_info = {}
            
            # Check for default value
            if '=' in param:
                param, default = param.split('=', 1)
                param = param.strip()
                param_info["default"] = default.strip()
                param_info["optional"] = True
                
            # Check for type annotation
            if ':' in param:
                name, type_str = param.split(':', 1)
                param_info["name"] = name.strip()
                param_info["type"] = type_str.strip()
            else:
                param_info["name"] = param.strip()
                param_info["type"] = "Variant"
                
            params.append(param_info)
            
        return params
    
    def _smart_split(self, text: str, delimiter: str) -> List[str]:
        """Split text by delimiter, respecting brackets and parentheses"""
        parts = []
        current = ""
        depth = 0
        
        for char in text:
            if char in '([{':
                depth += 1
            elif char in ')]}':
                depth -= 1
            elif char == delimiter and depth == 0:
                parts.append(current)
                current = ""
                continue
            current += char
            
        if current:
            parts.append(current)
            
        return parts
    
    def build_index(self, src_path: Path) -> None:
        """Build the signature index for all GDScript files"""
        print("Building function signature index...")
        
        for gdscript_file in src_path.rglob("*.gd"):
            # Skip test files and addons
            if any(skip in str(gdscript_file) for skip in ["test_", "_test.gd", "addons/", ".godot/"]):
                continue
                
            class_data = self.extract_function_signatures(gdscript_file)
            
            # Store by class name if available, otherwise by file
            if class_data["class_name"]:
                self.signatures["classes"][class_data["class_name"]] = class_data
            else:
                # Store by file path for non-class scripts
                rel_path = str(gdscript_file.relative_to(src_path))
                self.signatures["classes"][rel_path] = class_data
                
        print(f"Indexed {len(self.signatures['classes'])} classes/scripts")
    
    def save_index(self, output_path: Path) -> None:
        """Save the signature index to JSON"""
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(self.signatures, f, indent=2)
        print(f"Signature index saved to {output_path}")

def main():
    # Build signature index for the project
    project_root = Path("/home/rosswolf/Code/Tourbillon-claude-2/elastic-app/app")
    src_path = project_root / "src"
    
    if not src_path.exists():
        print(f"Source directory not found: {src_path}")
        return
        
    builder = SignatureIndexBuilder()
    builder.build_index(src_path)
    builder.save_index(project_root / "SIGNATURES.json")

if __name__ == "__main__":
    main()