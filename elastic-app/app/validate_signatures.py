#!/usr/bin/env python3
"""
Validate function calls against the signature index.
Used by compile checker to catch argument mismatches.
"""

import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

class SignatureValidator:
    def __init__(self, signatures_path: Path):
        self.signatures = {}
        self.godot_builtins = {}
        self.errors = []
        self.warnings = []
        
        # Load signature index
        if signatures_path.exists():
            with open(signatures_path, 'r') as f:
                data = json.load(f)
                self.signatures = data.get("classes", {})
                self.godot_builtins = data.get("godot_builtins", {})
        else:
            print(f"Warning: Signatures file not found: {signatures_path}")
    
    def validate_file(self, filepath: Path) -> Tuple[List[str], List[str]]:
        """Validate all function calls in a file"""
        self.errors = []
        self.warnings = []
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                
            # Extract the class context
            class_context = self._get_class_context(content)
            
            # Find all function calls
            self._validate_constructor_calls(content, filepath, class_context)
            self._validate_method_calls(content, filepath, class_context)
            
        except Exception as e:
            self.errors.append(f"Error processing {filepath}: {e}")
            
        return self.errors, self.warnings
    
    def _get_class_context(self, content: str) -> Dict:
        """Extract class context from file"""
        context = {
            "class_name": None,
            "extends": None,
            "local_methods": set(),
            "local_vars": set()
        }
        
        # Extract class_name
        class_match = re.search(r'^class_name\s+(\w+)', content, re.MULTILINE)
        if class_match:
            context["class_name"] = class_match.group(1)
            
        # Extract extends
        extends_match = re.search(r'^extends\s+(\w+)', content, re.MULTILINE)
        if extends_match:
            context["extends"] = extends_match.group(1)
            
        # Extract local method names
        for match in re.finditer(r'^func\s+(\w+)', content, re.MULTILINE):
            context["local_methods"].add(match.group(1))
            
        # Extract variable declarations for type inference
        for match in re.finditer(r'(?:var|const)\s+(\w+)\s*:\s*(\w+)', content):
            var_name = match.group(1)
            var_type = match.group(2)
            context["local_vars"].add((var_name, var_type))
            
        return context
    
    def _validate_constructor_calls(self, content: str, filepath: Path, context: Dict):
        """Validate ClassName.new() constructor calls"""
        # Pattern for ClassName.new(args)
        pattern = r'\b(\w+)\.new\s*\((.*?)\)'
        
        for match in re.finditer(pattern, content):
            class_name = match.group(1)
            args_str = match.group(2).strip()
            
            # Count arguments (simple count, doesn't handle nested calls perfectly)
            arg_count = self._count_arguments(args_str)
            
            # Check if this is a known class
            signature = self._get_constructor_signature(class_name)
            if signature:
                expected = self._get_expected_arg_count(signature)
                if not self._args_match(arg_count, expected):
                    line_num = content[:match.start()].count('\n') + 1
                    self.errors.append(
                        f"{filepath}:{line_num} - {class_name}.new() expects "
                        f"{self._format_arg_count(expected)} arguments, got {arg_count}"
                    )
            elif class_name in self.godot_builtins:
                # It's a Godot builtin, check if constructor is defined
                builtin = self.godot_builtins[class_name]
                if "constructor" in builtin:
                    expected = self._get_expected_arg_count(builtin["constructor"])
                    if not self._args_match(arg_count, expected):
                        line_num = content[:match.start()].count('\n') + 1
                        self.errors.append(
                            f"{filepath}:{line_num} - {class_name}.new() expects "
                            f"{self._format_arg_count(expected)} arguments, got {arg_count}"
                        )
    
    def _validate_method_calls(self, content: str, filepath: Path, context: Dict):
        """Validate object.method() calls"""
        # Pattern for object.method(args) - excluding .new()
        pattern = r'\b(\w+)\.(\w+)\s*\((.*?)\)'
        
        for match in re.finditer(pattern, content):
            if match.group(2) == "new":
                continue  # Skip constructors, handled separately
                
            object_name = match.group(1)
            method_name = match.group(2)
            args_str = match.group(3).strip()
            
            # Count arguments
            arg_count = self._count_arguments(args_str)
            
            # Try to determine object type
            object_type = self._infer_object_type(object_name, context)
            if not object_type:
                continue  # Can't determine type, skip validation
                
            # Check method signature
            signature = self._get_method_signature(object_type, method_name)
            if signature:
                expected = self._get_expected_arg_count(signature)
                if not self._args_match(arg_count, expected):
                    line_num = content[:match.start()].count('\n') + 1
                    
                    # Determine if it's a warning or error
                    if object_type in self.godot_builtins:
                        # Error for Godot builtins
                        self.errors.append(
                            f"{filepath}:{line_num} - {object_type}.{method_name}() expects "
                            f"{self._format_arg_count(expected)} arguments, got {arg_count}"
                        )
                    else:
                        # Warning for user classes (might be overridden)
                        self.warnings.append(
                            f"{filepath}:{line_num} - {object_type}.{method_name}() expects "
                            f"{self._format_arg_count(expected)} arguments, got {arg_count}"
                        )
    
    def _count_arguments(self, args_str: str) -> int:
        """Count the number of arguments in a call"""
        if not args_str:
            return 0
            
        # Simple counting - split by comma at depth 0
        depth = 0
        arg_count = 1
        
        for char in args_str:
            if char in '([{':
                depth += 1
            elif char in ')]}':
                depth -= 1
            elif char == ',' and depth == 0:
                arg_count += 1
                
        return arg_count
    
    def _get_expected_arg_count(self, signature: Dict) -> Tuple[int, int]:
        """Get min and max expected arguments from signature"""
        params = signature.get("params", [])
        min_args = sum(1 for p in params if not p.get("optional", False) and not p.get("default"))
        max_args = len(params)
        return (min_args, max_args)
    
    def _args_match(self, actual: int, expected: Tuple[int, int]) -> bool:
        """Check if actual arg count matches expected range"""
        min_args, max_args = expected
        return min_args <= actual <= max_args
    
    def _format_arg_count(self, expected: Tuple[int, int]) -> str:
        """Format expected arg count for error message"""
        min_args, max_args = expected
        if min_args == max_args:
            return str(min_args)
        elif min_args == 0:
            return f"at most {max_args}"
        else:
            return f"{min_args}-{max_args}"
    
    def _get_constructor_signature(self, class_name: str) -> Optional[Dict]:
        """Get constructor signature for a class"""
        # Check user classes
        if class_name in self.signatures:
            class_data = self.signatures[class_name]
            if "constructors" in class_data and "new" in class_data["constructors"]:
                return class_data["constructors"]["new"]
                
        # Check if it's an inner class constructor
        for cls in self.signatures.values():
            if "constructors" in cls and class_name in cls["constructors"]:
                return cls["constructors"][class_name]
                
        return None
    
    def _get_method_signature(self, class_name: str, method_name: str) -> Optional[Dict]:
        """Get method signature for a class"""
        # Check user classes
        if class_name in self.signatures:
            methods = self.signatures[class_name].get("methods", {})
            if method_name in methods:
                return methods[method_name]
                
        # Check Godot builtins
        if class_name in self.godot_builtins:
            methods = self.godot_builtins[class_name].get("methods", {})
            if method_name in methods:
                return methods[method_name]
                
        return None
    
    def _infer_object_type(self, object_name: str, context: Dict) -> Optional[str]:
        """Try to infer the type of an object from context"""
        # Check if it's a known singleton/autoload
        autoloads = {
            "GlobalSignals": "GlobalSignals",
            "GlobalGameManager": "GlobalGameManager",
            "StaticData": "StaticData",
            "TimerService": "TimerService",
            "DamageFactory": "DamageFactory"
        }
        if object_name in autoloads:
            return autoloads[object_name]
            
        # Check local variables
        for var_name, var_type in context["local_vars"]:
            if var_name == object_name:
                return var_type
                
        # Common patterns
        if object_name == "self":
            return context.get("class_name") or context.get("extends")
            
        return None

def validate_project(src_path: Path, signatures_path: Path) -> Tuple[int, int]:
    """Validate all GDScript files in the project"""
    validator = SignatureValidator(signatures_path)
    total_errors = 0
    total_warnings = 0
    
    for gdscript_file in src_path.rglob("*.gd"):
        # Skip test files and addons
        if any(skip in str(gdscript_file) for skip in ["test_", "_test.gd", "addons/", ".godot/"]):
            continue
            
        errors, warnings = validator.validate_file(gdscript_file)
        
        for error in errors:
            print(f"ERROR: {error}")
            total_errors += 1
            
        for warning in warnings:
            print(f"WARNING: {warning}")
            total_warnings += 1
            
    return total_errors, total_warnings

def main():
    project_root = Path("/home/rosswolf/Code/Tourbillon-claude-2/elastic-app/app")
    src_path = project_root / "src"
    signatures_path = project_root / "SIGNATURES.json"
    
    # Build signature index if it doesn't exist or is outdated
    if not signatures_path.exists():
        print("Signature index not found. Building...")
        import subprocess
        subprocess.run([sys.executable, "build_signature_index.py"], cwd=project_root)
    
    print("\nValidating function signatures...")
    errors, warnings = validate_project(src_path, signatures_path)
    
    print(f"\nValidation complete: {errors} errors, {warnings} warnings")
    
    return 1 if errors > 0 else 0

if __name__ == "__main__":
    sys.exit(main())