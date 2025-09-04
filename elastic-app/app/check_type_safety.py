#!/usr/bin/env python3
"""
Type Safety Presubmit Hook for Godot 4.4 Projects
Enforces type safety requirements as defined in CLAUDE.md
"""

import sys
import re
import os
from pathlib import Path
from typing import List, Tuple, Optional

class TypeSafetyChecker:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.errors: List[Tuple[str, int, str]] = []
        self.warnings: List[Tuple[str, int, str]] = []
        self.all_errors: List[Tuple[str, int, str]] = []
        self.all_warnings: List[Tuple[str, int, str]] = []
        
        # Patterns for various type safety violations
        self.patterns = {
            # Untyped variable declarations
            'untyped_var': re.compile(r'^\s*var\s+(\w+)\s*=\s*(?!null)'),
            
            # Typed variable declarations (to exclude from untyped check)
            'typed_var': re.compile(r'^\s*var\s+\w+\s*:\s*\w+'),
            
            # Function definitions without return type - match func declarations
            'func_def': re.compile(r'^\s*func\s+(\w+)\s*\(([^)]*)\)(.*)'),
            
            # Function parameters without types
            'func_param': re.compile(r'func\s+\w+\s*\(([^)]*)\)'),
            
            # Untyped arrays
            'untyped_array': re.compile(r'(?:var\s+\w+\s*=\s*\[\]|:\s*Array(?!\[))'),
            
            # Untyped dictionaries
            'untyped_dict': re.compile(r'(?:var\s+\w+\s*=\s*\{\}|:\s*Dictionary(?!\[))'),
            
            # Nested dictionary detection (Godot limitation)
            'nested_dict': re.compile(r'Dictionary\[.*Dictionary\['),
            
            # Style override comment
            'style_override': re.compile(r'#\s*STYLEOVERRIDE\s*(?:\(([^)]+)\))?'),
            
            # @onready declarations
            'onready_untyped': re.compile(r'@onready\s+var\s+(\w+)\s*='),
            'onready_typed': re.compile(r'@onready\s+var\s+\w+\s*:\s*\w+'),
            
            # Enum detection
            'enum_def': re.compile(r'^\s*enum\s+\w+'),
            
            # Signal detection
            'signal_def': re.compile(r'^\s*signal\s+'),
            
            # Const detection (constants don't require explicit typing)
            'const_def': re.compile(r'^\s*const\s+'),
        }
    
    def check_file(self, filepath: Path) -> bool:
        """Check a single GDScript file for type safety violations."""
        if not filepath.suffix == '.gd':
            return True
            
        # Reset per-file error lists
        self.errors = []
        self.warnings = []
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Error reading {filepath}: {e}")
            return False
        
        override_active = False
        override_reason = ""
        in_multiline_string = False
        
        for line_num, line in enumerate(lines, 1):
            # Check for multiline strings
            if '"""' in line:
                in_multiline_string = not in_multiline_string
                continue
            if in_multiline_string:
                continue
                
            # Skip comments (except style override)
            if line.strip().startswith('#'):
                override_match = self.patterns['style_override'].search(line)
                if override_match:
                    override_active = True
                    override_reason = override_match.group(1) or "No reason provided"
                    if self.verbose:
                        print(f"  Style override active at line {line_num}: {override_reason}")
                continue
            
            # Skip empty lines
            if not line.strip():
                continue
            
            # Skip signal and enum definitions
            if self.patterns['signal_def'].match(line) or self.patterns['enum_def'].match(line):
                continue
                
            # Skip const definitions (they infer type from value)
            if self.patterns['const_def'].match(line):
                continue
            
            # If override is active, skip this line but reset override
            if override_active:
                override_active = False
                if self.verbose:
                    print(f"  Skipping line {line_num} due to style override")
                continue
            
            # Check for various violations
            self._check_variable_typing(line, line_num, filepath)
            self._check_function_typing(line, line_num, filepath)
            self._check_collection_typing(line, line_num, filepath)
            self._check_nested_dictionary(line, line_num, filepath)
            self._check_onready_typing(line, line_num, filepath)
        
        # Add this file's errors to the cumulative lists
        self.all_errors.extend(self.errors)
        self.all_warnings.extend(self.warnings)
        
        return len(self.errors) == 0
    
    def _check_variable_typing(self, line: str, line_num: int, filepath: Path) -> None:
        """Check for untyped variable declarations."""
        # Skip if it's a typed variable
        if self.patterns['typed_var'].search(line):
            return
            
        # Check for untyped variables
        match = self.patterns['untyped_var'].search(line)
        if match:
            # Special cases where typing might be inferred or not needed
            if '=' in line:
                # Check right side of assignment
                right_side = line.split('=', 1)[1].strip()
                
                # Allow null assignments (will be typed when assigned later)
                if right_side == 'null':
                    return
                    
                # Allow assignments from typed expressions
                if any(keyword in right_side for keyword in ['new()', 'preload(', 'load(', 'as ']):
                    return
                    
                # Check for obvious literals that should still be typed
                # Remove inline comments for checking
                right_side_clean = right_side.split('#')[0].strip() if '#' in right_side else right_side
                
                if re.match(r'^-?[\d.]+$', right_side_clean):  # number literal
                    if '.' in right_side_clean:
                        type_hint = "float"
                    else:
                        type_hint = "int"
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Untyped variable '{match.group(1)}'. Use: var {match.group(1)}: {type_hint} = {right_side_clean}"
                    ))
                elif right_side_clean in ['true', 'false']:  # boolean literal
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Untyped variable '{match.group(1)}'. Use: var {match.group(1)}: bool = {right_side_clean}"
                    ))
                elif right_side_clean.startswith('"') or right_side_clean.startswith("'"):  # string literal
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Untyped variable '{match.group(1)}'. Use: var {match.group(1)}: String = {right_side_clean}"
                    ))
                elif right_side.startswith('['):  # array literal
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Untyped variable '{match.group(1)}'. Use typed array: var {match.group(1)}: Array[Type] = ..."
                    ))
                elif right_side.startswith('{'):  # dictionary literal
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Untyped variable '{match.group(1)}'. Use typed dictionary: var {match.group(1)}: Dictionary[KeyType, ValueType] = ..."
                    ))
    
    def _check_function_typing(self, line: str, line_num: int, filepath: Path) -> None:
        """Check for untyped function parameters and return types."""
        # Check for function definitions
        func_match = self.patterns['func_def'].search(line)
        if func_match:
            func_name = func_match.group(1)
            params = func_match.group(2)
            after_params = func_match.group(3)
            
            # Check for missing return type (should have -> after params)
            if '->' not in after_params:
                # Check if it's _ready, _init, or other special functions that return void
                if any(special in func_name for special in ['_ready', '_init', '_enter_tree', '_exit_tree', '_process', '_physics_process', '_input', '_unhandled_input']):
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Function {func_name} should explicitly specify '-> void' return type"
                    ))
                else:
                    self.errors.append((
                        str(filepath), 
                        line_num, 
                        f"Function {func_name} missing return type annotation. Add -> ReturnType or -> void"
                    ))
        
        # Check function parameters
        param_match = self.patterns['func_param'].search(line)
        if param_match:
            params = param_match.group(1)
            if params.strip():  # Has parameters
                # Split by comma, handle nested parentheses
                param_list = self._split_params(params)
                for param in param_list:
                    param = param.strip()
                    if not param:
                        continue
                    
                    # Check if parameter has type annotation
                    if ':' not in param and '=' not in param:
                        # No type annotation and no default value
                        param_name = param.split()[0] if param else ""
                        self.errors.append((
                            str(filepath),
                            line_num,
                            f"Function parameter '{param_name}' missing type annotation"
                        ))
                    elif '=' in param and ':' not in param.split('=')[0]:
                        # Has default value but no type
                        param_name = param.split('=')[0].strip()
                        self.errors.append((
                            str(filepath),
                            line_num,
                            f"Function parameter '{param_name}' with default value should still have explicit type"
                        ))
    
    def _check_collection_typing(self, line: str, line_num: int, filepath: Path) -> None:
        """Check for untyped arrays and dictionaries."""
        # Check for untyped arrays
        if '[]' in line and 'Array[' not in line:
            if 'var ' in line or ': Array' in line:
                self.errors.append((
                    str(filepath),
                    line_num,
                    "Use typed arrays: Array[Type] instead of [] or untyped Array"
                ))
        
        # Check for untyped dictionaries  
        if '{}' in line and 'Dictionary[' not in line:
            if 'var ' in line or ': Dictionary' in line:
                self.errors.append((
                    str(filepath),
                    line_num,
                    "Use typed dictionaries: Dictionary[KeyType, ValueType] instead of {} or untyped Dictionary"
                ))
    
    def _check_nested_dictionary(self, line: str, line_num: int, filepath: Path) -> None:
        """Check for nested typed dictionaries (Godot limitation)."""
        if self.patterns['nested_dict'].search(line):
            self.warnings.append((
                str(filepath),
                line_num,
                "Godot doesn't support nested typed dictionaries. Consider using a custom class or add #STYLEOVERRIDE comment"
            ))
    
    def _check_onready_typing(self, line: str, line_num: int, filepath: Path) -> None:
        """Check for untyped @onready variables."""
        if self.patterns['onready_untyped'].search(line) and not self.patterns['onready_typed'].search(line):
            match = self.patterns['onready_untyped'].search(line)
            if match:
                var_name = match.group(1)
                # Check if it's getting a node
                if '$' in line or 'get_node' in line:
                    self.errors.append((
                        str(filepath),
                        line_num,
                        f"@onready var {var_name} should specify node type: @onready var {var_name}: NodeType = $..."
                    ))
    
    def _split_params(self, params: str) -> List[str]:
        """Split function parameters, handling nested parentheses."""
        result = []
        current = []
        depth = 0
        
        for char in params:
            if char == '(' or char == '[':
                depth += 1
                current.append(char)
            elif char == ')' or char == ']':
                depth -= 1
                current.append(char)
            elif char == ',' and depth == 0:
                result.append(''.join(current))
                current = []
            else:
                current.append(char)
        
        if current:
            result.append(''.join(current))
        
        return result
    
    def print_report(self) -> None:
        """Print the errors and warnings found."""
        if self.all_errors:
            print("\n❌ Type Safety Violations Found:")
            for filepath, line_num, message in self.all_errors:
                print(f"  {filepath}:{line_num}: {message}")
        
        if self.all_warnings:
            print("\n⚠️  Warnings:")
            for filepath, line_num, message in self.all_warnings:
                print(f"  {filepath}:{line_num}: {message}")
        
        if not self.all_errors and not self.all_warnings:
            print("✅ All files pass type safety checks!")


def main():
    """Main entry point for the presubmit hook."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Check GDScript files for type safety")
    parser.add_argument('files', nargs='*', help='Files to check (default: all .gd files)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--all', '-a', action='store_true', help='Check all .gd files in src/')
    
    args = parser.parse_args()
    
    checker = TypeSafetyChecker(verbose=args.verbose)
    
    # Determine which files to check
    files_to_check = []
    
    if args.all:
        # Check all .gd files in src/
        src_path = Path('src')
        if src_path.exists():
            files_to_check = list(src_path.rglob('*.gd'))
        else:
            print("Error: src/ directory not found")
            sys.exit(1)
    elif args.files:
        # Check specified files
        files_to_check = [Path(f) for f in args.files if f.endswith('.gd')]
    elif not sys.stdin.isatty():
        # Read from stdin (for git hooks)
        for line in sys.stdin:
            filepath = line.strip()
            if filepath.endswith('.gd'):
                files_to_check.append(Path(filepath))
    else:
        # No input provided
        print("Usage: check_type_safety.py [files...] or --all")
        print("       Or pipe filenames to stdin")
        sys.exit(1)
    
    if not files_to_check:
        print("No GDScript files to check")
        sys.exit(0)
    
    # DEBUG
    if args.verbose:
        print(f"Checking {len(files_to_check)} files...")
    
    all_pass = True
    for filepath in files_to_check:
        if filepath.exists():
            if args.verbose:
                print(f"Checking {filepath}...")
            if not checker.check_file(filepath):
                all_pass = False
    
    checker.print_report()
    
    if not all_pass:
        print("\n❌ Type safety check failed. Fix violations or add #STYLEOVERRIDE (reason) comments.")
        sys.exit(1)
    else:
        print("\n✅ Type safety check passed!")
        sys.exit(0)


if __name__ == '__main__':
    main()