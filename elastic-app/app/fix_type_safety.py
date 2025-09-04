#!/usr/bin/env python3
"""
Automated Type Safety Fixer for Godot 4.4 Projects
Automatically fixes common type safety violations
"""

import sys
import re
import os
from pathlib import Path
from typing import List, Tuple, Optional

class TypeSafetyFixer:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.fixes_applied = 0
        
    def fix_file(self, filepath: Path) -> bool:
        """Fix type safety violations in a single GDScript file."""
        if not filepath.suffix == '.gd':
            return True
            
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Error reading {filepath}: {e}")
            return False
        
        original_lines = lines.copy()
        modified = False
        
        for i, line in enumerate(lines):
            # Skip comments and empty lines
            if line.strip().startswith('#') or not line.strip():
                continue
                
            # Fix _ready, _init, _enter_tree, _exit_tree, _process, _physics_process functions
            if re.match(r'^\s*func (_ready|_init|_enter_tree|_exit_tree)\s*\(\s*\)\s*:', line):
                if ' -> void:' not in line:
                    lines[i] = line.rstrip(':\n') + ' -> void:\n'
                    modified = True
                    if self.verbose:
                        print(f"  Fixed {filepath}:{i+1}: Added -> void to system function")
                        
            # Fix _process and _physics_process with delta parameter
            match = re.match(r'^(\s*)func (_process|_physics_process)\s*\((delta)\)\s*:', line)
            if match:
                indent = match.group(1)
                func_name = match.group(2)
                lines[i] = f"{indent}func {func_name}(delta: float) -> void:\n"
                modified = True
                if self.verbose:
                    print(f"  Fixed {filepath}:{i+1}: Added types to {func_name}")
                    
            # Fix _input and _unhandled_input with event parameter
            match = re.match(r'^(\s*)func (_input|_unhandled_input)\s*\((event)\)\s*:', line)
            if match:
                indent = match.group(1)
                func_name = match.group(2)
                lines[i] = f"{indent}func {func_name}(event: InputEvent) -> void:\n"
                modified = True
                if self.verbose:
                    print(f"  Fixed {filepath}:{i+1}: Added types to {func_name}")
                    
            # Fix functions starting with double underscore (private functions) - assume void if no return
            match = re.match(r'^(\s*)func (__\w+)\s*\(([^)]*)\)\s*:', line)
            if match and ' -> ' not in line:
                indent = match.group(1)
                func_name = match.group(2)
                params = match.group(3)
                
                # Try to infer parameter types for common patterns
                typed_params = self.type_parameters(params, filepath, i+1)
                
                lines[i] = f"{indent}func {func_name}({typed_params}) -> void:\n"
                modified = True
                if self.verbose:
                    print(f"  Fixed {filepath}:{i+1}: Added -> void to private function {func_name}")
                    
            # Fix signal_ functions (typically void)
            match = re.match(r'^(\s*)func (signal_\w+)\s*\(([^)]*)\)\s*:', line)
            if match and ' -> ' not in line:
                indent = match.group(1)
                func_name = match.group(2)
                params = match.group(3)
                
                # Type parameters
                typed_params = self.type_parameters(params, filepath, i+1)
                
                lines[i] = f"{indent}func {func_name}({typed_params}) -> void:\n"
                modified = True
                if self.verbose:
                    print(f"  Fixed {filepath}:{i+1}: Added -> void to signal function {func_name}")
                    
            # Fix _on_ callback functions (typically void)
            match = re.match(r'^(\s*)func (_on_\w+)\s*\(([^)]*)\)\s*:', line)
            if match and ' -> ' not in line:
                indent = match.group(1)
                func_name = match.group(2)
                params = match.group(3)
                
                typed_params = self.type_parameters(params, filepath, i+1)
                
                lines[i] = f"{indent}func {func_name}({typed_params}) -> void:\n"
                modified = True
                if self.verbose:
                    print(f"  Fixed {filepath}:{i+1}: Added -> void to callback function {func_name}")
                    
            # Fix untyped variables with literal values
            match = re.match(r'^(\s*)var\s+(\w+)\s*=\s*([^#\n]+)', line)
            if match and ': ' not in line.split('=')[0]:
                indent = match.group(1)
                var_name = match.group(2)
                value = match.group(3).strip()
                
                # Infer type from literal
                type_hint = self.infer_type_from_literal(value)
                if type_hint:
                    lines[i] = f"{indent}var {var_name}: {type_hint} = {value}\n"
                    modified = True
                    if self.verbose:
                        print(f"  Fixed {filepath}:{i+1}: Added type {type_hint} to variable {var_name}")
                        
            # Fix @onready variables
            match = re.match(r'^(\s*)@onready\s+var\s+(\w+)\s*=\s*(.+)', line)
            if match and ': ' not in line.split('=')[0]:
                indent = match.group(1)
                var_name = match.group(2)
                value = match.group(3).strip()
                
                # Try to infer node type
                node_type = self.infer_node_type(value, var_name)
                if node_type:
                    lines[i] = f"{indent}@onready var {var_name}: {node_type} = {value}\n"
                    modified = True
                    if self.verbose:
                        print(f"  Fixed {filepath}:{i+1}: Added type {node_type} to @onready variable {var_name}")
        
        if modified:
            try:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                self.fixes_applied += 1
                return True
            except Exception as e:
                print(f"Error writing {filepath}: {e}")
                return False
        
        return True
    
    def type_parameters(self, params: str, filepath: Path, line_num: int) -> str:
        """Add types to function parameters."""
        if not params.strip():
            return params
            
        param_list = []
        for param in params.split(','):
            param = param.strip()
            if not param:
                continue
                
            # Skip if already typed
            if ':' in param and '=' not in param.split(':')[0]:
                param_list.append(param)
                continue
                
            # Handle default values
            if '=' in param:
                param_name = param.split('=')[0].strip()
                default = param.split('=')[1].strip()
                param_type = self.infer_type_from_literal(default)
                if param_type:
                    param_list.append(f"{param_name}: {param_type} = {default}")
                else:
                    # Common parameter patterns
                    if 'id' in param_name.lower():
                        param_list.append(f"{param_name}: String = {default}")
                    else:
                        param_list.append(f"{param_name}: Variant = {default}")
            else:
                # Common parameter patterns
                if param in ['delta', 'dt']:
                    param_list.append(f"{param}: float")
                elif param == 'event':
                    param_list.append(f"{param}: InputEvent")
                elif 'pos' in param or 'position' in param:
                    param_list.append(f"{param}: Vector2")
                elif 'id' in param.lower() or 'name' in param:
                    param_list.append(f"{param}: String")
                elif 'count' in param or 'index' in param or 'num' in param:
                    param_list.append(f"{param}: int")
                elif 'entity' in param:
                    param_list.append(f"{param}: Entity")
                elif 'card' in param:
                    param_list.append(f"{param}: Card")
                elif 'node' in param:
                    param_list.append(f"{param}: Node")
                elif 'amount' in param or 'value' in param:
                    param_list.append(f"{param}: int")
                elif 'enabled' in param or 'visible' in param or 'active' in param:
                    param_list.append(f"{param}: bool")
                elif 'color' in param:
                    param_list.append(f"{param}: Color")
                elif 'path' in param:
                    param_list.append(f"{param}: String")
                elif 'filter_value' in param:
                    param_list.append(f"{param}: Variant")
                else:
                    # Default to Variant for unknown types
                    param_list.append(f"{param}: Variant")
                    if self.verbose:
                        print(f"    Warning: Could not infer type for parameter '{param}' at {filepath}:{line_num}")
        
        return ', '.join(param_list)
    
    def infer_type_from_literal(self, value: str) -> Optional[str]:
        """Infer type from a literal value."""
        value = value.strip()
        
        # Remove inline comments
        if '#' in value:
            value = value.split('#')[0].strip()
        
        if value == 'null':
            return None
        elif value in ['true', 'false']:
            return 'bool'
        elif value.startswith('"') or value.startswith("'"):
            return 'String'
        elif value.startswith('[]'):
            return 'Array'  # Should be typed array, but need more context
        elif value.startswith('{}'):
            return 'Dictionary'  # Should be typed dictionary, but need more context
        elif value.startswith('Vector2(') or value.startswith('Vector2i('):
            return 'Vector2' if 'Vector2i' not in value else 'Vector2i'
        elif value.startswith('Vector3('):
            return 'Vector3'
        elif value.startswith('Color('):
            return 'Color'
        elif re.match(r'^-?\d+$', value):
            return 'int'
        elif re.match(r'^-?[\d.]+$', value):
            return 'float'
        elif value.startswith('preload('):
            # Try to infer from preload path
            if 'Scene' in value or '.tscn' in value:
                return 'PackedScene'
            elif 'Texture' in value or '.png' in value or '.jpg' in value:
                return 'Texture2D'
            else:
                return 'Resource'
        elif value.startswith('load('):
            return 'Resource'
        elif '.new()' in value:
            # Extract class name
            class_match = re.match(r'(\w+)\.new\(\)', value)
            if class_match:
                return class_match.group(1)
        
        return None
    
    def infer_node_type(self, value: str, var_name: str) -> Optional[str]:
        """Infer node type from @onready assignment."""
        # Common UI node patterns based on variable name
        var_lower = var_name.lower()
        
        if 'label' in var_lower:
            return 'Label'
        elif 'button' in var_lower:
            if 'texture' in var_lower:
                return 'TextureButton'
            else:
                return 'Button'
        elif 'timer' in var_lower:
            return 'Timer'
        elif 'container' in var_lower:
            if 'hbox' in var_lower:
                return 'HBoxContainer'
            elif 'vbox' in var_lower:
                return 'VBoxContainer'
            elif 'grid' in var_lower:
                return 'GridContainer'
            else:
                return 'Container'
        elif 'panel' in var_lower:
            return 'Panel'
        elif 'sprite' in var_lower:
            return 'Sprite2D'
        elif 'audio' in var_lower:
            return 'AudioStreamPlayer'
        elif 'camera' in var_lower:
            return 'Camera2D'
        elif 'animation' in var_lower:
            return 'AnimationPlayer'
        elif 'line_edit' in var_lower or 'text_edit' in var_lower:
            return 'LineEdit' if 'line' in var_lower else 'TextEdit'
        elif 'progress' in var_lower:
            return 'ProgressBar'
        elif 'scroll' in var_lower:
            return 'ScrollContainer'
        elif 'icon' in var_lower or 'texture' in var_lower:
            return 'TextureRect'
        elif 'rich' in var_lower and 'label' in var_lower:
            return 'RichTextLabel'
        else:
            # Default to Control for UI elements
            if '%' in value or '$' in value:
                return 'Control'
            else:
                return 'Node'


def main():
    """Main entry point for the type safety fixer."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Automatically fix GDScript type safety violations")
    parser.add_argument('files', nargs='*', help='Files to fix (default: all .gd files)')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('--all', '-a', action='store_true', help='Fix all .gd files in src/')
    parser.add_argument('--dry-run', '-n', action='store_true', help='Show what would be fixed without making changes')
    
    args = parser.parse_args()
    
    fixer = TypeSafetyFixer(verbose=args.verbose)
    
    # Determine which files to fix
    files_to_fix = []
    
    if args.all:
        # Fix all .gd files in src/
        src_path = Path('src')
        if src_path.exists():
            files_to_fix = list(src_path.rglob('*.gd'))
        else:
            print("Error: src/ directory not found")
            sys.exit(1)
    elif args.files:
        # Fix specified files
        files_to_fix = [Path(f) for f in args.files if f.endswith('.gd')]
    else:
        print("Usage: fix_type_safety.py [files...] or --all")
        sys.exit(1)
    
    if not files_to_fix:
        print("No GDScript files to fix")
        sys.exit(0)
    
    print(f"Fixing type safety in {len(files_to_fix)} files...")
    
    for filepath in files_to_fix:
        if filepath.exists():
            if args.verbose:
                print(f"Processing {filepath}...")
            if not args.dry_run:
                fixer.fix_file(filepath)
    
    if not args.dry_run:
        print(f"\n✅ Fixed type safety violations in {fixer.fixes_applied} files")
    else:
        print("\n(Dry run - no changes made)")


if __name__ == '__main__':
    main()