#!/usr/bin/env python3
"""
Godot Style Checker
Enforces coding standards and best practices for GDScript files.
"""

import re
import sys
import argparse
from pathlib import Path
from typing import List, Dict, Tuple, Set
from dataclasses import dataclass
from enum import Enum

class Severity(Enum):
    ERROR = "ERROR"
    WARNING = "WARNING"
    INFO = "INFO"

@dataclass
class StyleViolation:
    file: str
    line: int
    severity: Severity
    rule: str
    message: str
    suggestion: str = ""

class StyleChecker:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.violations: List[StyleViolation] = []
        self.files_checked = 0
        self.exemption_patterns = [
            r'#\s*STYLEOVERRIDE',
            r'#\s*STYLE_EXEMPTION',
            r'#\s*noqa',
            r'#\s*pylint:\s*disable'
        ]
        
        # Comprehensive list of Godot virtual methods that should use single underscore
        self.godot_virtual_methods = {
            # Node lifecycle
            '_init', '_ready', '_enter_tree', '_exit_tree',
            '_process', '_physics_process',
            
            # Input handling
            '_input', '_unhandled_input', '_unhandled_key_input',
            '_shortcut_input', '_gui_input',
            
            # Drawing and GUI
            '_draw', '_gui_draw',
            
            # Notifications
            '_notification',
            
            # Get methods
            '_get', '_set', '_get_property_list',
            '_property_can_revert', '_property_get_revert',
            
            # Validation
            '_validate_property',
            
            # Physics
            '_integrate_forces',
            
            # Animation
            '_animation_started', '_animation_finished', '_animation_changed',
            
            # Tree
            '_get_configuration_warnings',
            
            # Resources
            '_setup_local_to_scene',
            
            # Editor specific (tool scripts)
            '_get_editor_name', '_get_editor_description',
            '_has_editor_variant', '_make_custom_tooltip',
            
            # Control nodes
            '_make_custom_tooltip', '_structured_text_parser',
            '_can_drop_data', '_drop_data', '_get_drag_data',
            
            # HTTPRequest
            '_request_completed',
            
            # Area2D/3D
            '_area_entered', '_area_exited',
            '_body_entered', '_body_exited',
            
            # RigidBody
            '_integrate_forces',
            
            # Tween
            '_tween_started', '_tween_completed',
            
            # Timer
            '_timeout',
            
            # AnimationPlayer
            '_animation_finished', '_animation_changed',
            
            # Custom methods commonly used with signals (convention)
            '_on_', '_pressed', '_toggled', '_text_changed', '_item_selected',
            '_value_changed', '_timeout', '_tween_completed', '_finished'
        }
        
    def check_file(self, file_path: Path) -> List[StyleViolation]:
        """Check a single GDScript file for style violations."""
        violations = []
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return violations
        
        self.files_checked += 1
        file_str = str(file_path)
        
        # Check each rule
        violations.extend(self.check_naming_conventions(file_str, lines))
        violations.extend(self.check_line_length(file_str, lines))
        violations.extend(self.check_whitespace(file_str, lines))
        violations.extend(self.check_comments(file_str, lines))
        violations.extend(self.check_function_complexity(file_str, lines))
        violations.extend(self.check_magic_numbers(file_str, lines))
        violations.extend(self.check_todos(file_str, lines))
        violations.extend(self.check_empty_blocks(file_str, lines))
        violations.extend(self.check_duplicate_code(file_str, lines))
        violations.extend(self.check_godot_patterns(file_str, lines))
        violations.extend(self.check_documentation(file_str, lines))
        violations.extend(self.check_assertions(file_str, lines))
        
        # Filter out exempted violations
        filtered_violations = []
        for violation in violations:
            if not self.is_line_exempted(lines, violation.line - 1):
                filtered_violations.append(violation)
                
        return filtered_violations
    
    def is_line_exempted(self, lines: List[str], line_idx: int) -> bool:
        """Check if a line has a style exemption comment."""
        if line_idx < 0 or line_idx >= len(lines):
            return False
            
        line = lines[line_idx]
        for pattern in self.exemption_patterns:
            if re.search(pattern, line, re.IGNORECASE):
                return True
        return False
    
    def check_naming_conventions(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check naming conventions for variables, functions, and classes."""
        violations = []
        
        # Class names should be PascalCase
        class_pattern = re.compile(r'^class_name\s+(\w+)')
        # Function names should be snake_case (with __ prefix for private)
        func_pattern = re.compile(r'^func\s+(\w+)\s*\(')
        # Constants should be UPPER_SNAKE_CASE
        const_pattern = re.compile(r'^const\s+(\w+)\s*=')
        # Variables should be snake_case
        var_pattern = re.compile(r'^(?:var|@onready\s+var)\s+(\w+)')
        # Enum values should be UPPER_SNAKE_CASE
        enum_value_pattern = re.compile(r'^\s+(\w+)\s*=?\s*\d*,?$')
        
        in_enum = False
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Track enum blocks
            if 'enum' in stripped and '{' in stripped:
                in_enum = True
            elif in_enum and '}' in stripped:
                in_enum = False
                continue
            
            # Check class names
            match = class_pattern.search(stripped)
            if match:
                class_name = match.group(1)
                if not self.is_pascal_case(class_name):
                    violations.append(StyleViolation(
                        file, i, Severity.WARNING, "naming",
                        f"Class name '{class_name}' should be PascalCase",
                        f"Rename to '{self.to_pascal_case(class_name)}'"
                    ))
            
            # Check function names
            match = func_pattern.search(stripped)
            if match:
                func_name = match.group(1)
                
                # Check different function naming patterns
                if func_name.startswith('__'):
                    # Double underscore = private method (OK)
                    pass
                elif func_name.startswith('_'):
                    # Single underscore - check if it's a valid Godot method or signal handler
                    if not self.is_valid_godot_method(func_name):
                        violations.append(StyleViolation(
                            file, i, Severity.WARNING, "naming",
                            f"Function '{func_name}' uses single underscore but is not a recognized Godot virtual method",
                            f"Use double underscore for private methods or remove underscore for public methods"
                        ))
                else:
                    # Public method - should be snake_case
                    if not self.is_snake_case(func_name):
                        violations.append(StyleViolation(
                            file, i, Severity.WARNING, "naming",
                            f"Function '{func_name}' should be snake_case",
                            f"Rename to '{self.to_snake_case(func_name)}'"
                        ))
            
            # Check constants
            match = const_pattern.search(stripped)
            if match:
                const_name = match.group(1)
                if not self.is_upper_snake_case(const_name):
                    violations.append(StyleViolation(
                        file, i, Severity.WARNING, "naming",
                        f"Constant '{const_name}' should be UPPER_SNAKE_CASE",
                        f"Rename to '{const_name.upper()}'"
                    ))
            
            # Check variables (but not in function parameters)
            if not '(' in stripped:  # Crude check to avoid function params
                match = var_pattern.search(stripped)
                if match:
                    var_name = match.group(1)
                    if not var_name.startswith('__') and not self.is_snake_case(var_name):
                        violations.append(StyleViolation(
                            file, i, Severity.WARNING, "naming",
                            f"Variable '{var_name}' should be snake_case",
                            f"Rename to '{self.to_snake_case(var_name)}'"
                        ))
            
            # Check enum values
            if in_enum:
                match = enum_value_pattern.search(stripped)
                if match:
                    enum_val = match.group(1)
                    if not self.is_upper_snake_case(enum_val):
                        violations.append(StyleViolation(
                            file, i, Severity.WARNING, "naming",
                            f"Enum value '{enum_val}' should be UPPER_SNAKE_CASE",
                            f"Rename to '{enum_val.upper()}'"
                        ))
        
        return violations
    
    def check_line_length(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for lines that exceed maximum length."""
        violations = []
        max_length = 120  # Configurable
        
        for i, line in enumerate(lines, 1):
            # Don't count trailing newline
            line_len = len(line.rstrip('\n'))
            if line_len > max_length:
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "line-length",
                    f"Line exceeds {max_length} characters ({line_len})",
                    "Break line into multiple lines"
                ))
        
        return violations
    
    def check_whitespace(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check whitespace issues: trailing spaces, tabs vs spaces, etc."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            # Check for trailing whitespace
            if line.rstrip() != line.rstrip('\n').rstrip('\r'):
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "whitespace",
                    "Trailing whitespace detected",
                    "Remove trailing spaces"
                ))
            
            # Check for mixed indentation (tabs and spaces)
            if '\t' in line and '    ' in line[:line.find(line.lstrip())]:
                violations.append(StyleViolation(
                    file, i, Severity.ERROR, "whitespace",
                    "Mixed tabs and spaces in indentation",
                    "Use tabs consistently for indentation"
                ))
            
            # Check for space before comma/semicolon
            if re.search(r'\s[,;]', line):
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "whitespace",
                    "Space before comma or semicolon",
                    "Remove space before punctuation"
                ))
            
            # Check for missing space after comma (except in strings)
            # Simple check - may have false positives in strings
            if re.search(r',[^\s\)]', line) and not re.search(r'["\'].*,.*["\']', line):
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "whitespace",
                    "Missing space after comma",
                    "Add space after comma"
                ))
        
        return violations
    
    def check_comments(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check comment style and quality."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Check for commented-out code (heuristic)
            if stripped.startswith('#') and not stripped.startswith('##'):
                comment_content = stripped[1:].strip()
                # Look for code-like patterns
                if any(pattern in comment_content for pattern in ['var ', 'func ', 'if ', 'for ', 'return', '=', '()']):
                    violations.append(StyleViolation(
                        file, i, Severity.INFO, "comments",
                        "Possible commented-out code detected",
                        "Remove commented code or explain why it's kept"
                    ))
            
            # Check for missing space after # in comments
            if stripped.startswith('#') and len(stripped) > 1 and stripped[1] not in ['#', ' ', '\t']:
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "comments",
                    "Missing space after # in comment",
                    "Add space after #"
                ))
        
        return violations
    
    def check_function_complexity(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for overly complex functions."""
        violations = []
        
        current_func = None
        func_start_line = 0
        func_lines = 0
        nesting_level = 0
        max_nesting = 0
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Track function boundaries
            if stripped.startswith('func '):
                # Check previous function if any
                if current_func and func_lines > 50:  # Configurable threshold
                    violations.append(StyleViolation(
                        file, func_start_line, Severity.WARNING, "complexity",
                        f"Function '{current_func}' is too long ({func_lines} lines)",
                        "Consider breaking into smaller functions"
                    ))
                if current_func and max_nesting > 4:  # Configurable threshold
                    violations.append(StyleViolation(
                        file, func_start_line, Severity.WARNING, "complexity",
                        f"Function '{current_func}' has deep nesting (level {max_nesting})",
                        "Reduce nesting by extracting logic or using early returns"
                    ))
                
                # Start tracking new function
                match = re.search(r'func\s+(\w+)', stripped)
                current_func = match.group(1) if match else "unknown"
                func_start_line = i
                func_lines = 0
                max_nesting = 0
                nesting_level = 0
            
            elif current_func:
                func_lines += 1
                
                # Track nesting level
                if any(keyword in stripped for keyword in ['if ', 'elif ', 'for ', 'while ', 'match ']):
                    if ':' in stripped:
                        nesting_level += 1
                        max_nesting = max(max_nesting, nesting_level)
                
                # Decrease nesting on dedent (simple heuristic)
                if stripped and not line[0].isspace() and current_func:
                    nesting_level = 0
        
        return violations
    
    def check_magic_numbers(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for magic numbers that should be constants."""
        violations = []
        
        # Numbers that are typically OK as literals
        allowed_numbers = {0, 1, -1, 2, 10, 100, 0.0, 1.0, 0.5}
        
        for i, line in enumerate(lines, 1):
            # Skip comments and strings
            if '#' in line:
                line = line[:line.index('#')]
            
            # Find numeric literals (simple regex, may need refinement)
            numbers = re.findall(r'\b\d+\.?\d*\b', line)
            
            for num_str in numbers:
                try:
                    num = float(num_str) if '.' in num_str else int(num_str)
                    if num not in allowed_numbers:
                        # Check if it's in a const declaration (OK)
                        if not line.strip().startswith('const'):
                            violations.append(StyleViolation(
                                file, i, Severity.INFO, "magic-number",
                                f"Magic number {num} should be a named constant",
                                f"Define as const at top of file"
                            ))
                except ValueError:
                    pass
        
        return violations
    
    def check_todos(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for TODO/FIXME/HACK comments."""
        violations = []
        
        todo_patterns = [
            (r'\bTODO\b', "TODO"),
            (r'\bFIXME\b', "FIXME"),
            (r'\bHACK\b', "HACK"),
            (r'\bXXX\b', "XXX"),
            (r'\bBUG\b', "BUG")
        ]
        
        for i, line in enumerate(lines, 1):
            for pattern, keyword in todo_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    violations.append(StyleViolation(
                        file, i, Severity.INFO, "todo",
                        f"{keyword} comment found",
                        "Address the issue or create a tracking ticket"
                    ))
        
        return violations
    
    def check_empty_blocks(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for empty code blocks."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Check for empty functions (just pass)
            if stripped == 'pass':
                # Look at previous lines to see if this is in a function
                if i > 1:
                    prev_line = lines[i-2].strip()
                    if prev_line.endswith(':'):
                        violations.append(StyleViolation(
                            file, i, Severity.INFO, "empty-block",
                            "Empty code block with only 'pass'",
                            "Implement the function or add a comment explaining why it's empty"
                        ))
        
        return violations
    
    def check_duplicate_code(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for obvious duplicate code patterns."""
        violations = []
        
        # Simple duplicate line detection (consecutive identical lines)
        for i in range(1, len(lines)):
            if lines[i].strip() and lines[i] == lines[i-1] and not lines[i].strip().startswith('#'):
                violations.append(StyleViolation(
                    file, i+1, Severity.WARNING, "duplicate",
                    "Duplicate line detected",
                    "Remove duplicate or extract to variable/function"
                ))
        
        return violations
    
    def check_godot_patterns(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for Godot-specific patterns and anti-patterns."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Check for .new() on autoloads (anti-pattern)
            if re.search(r'(GlobalSignals|GlobalGameManager|StaticData|UidManager|GlobalUtilities)\.new\(\)', line):
                violations.append(StyleViolation(
                    file, i, Severity.ERROR, "godot-pattern",
                    "Don't instantiate autoloads with .new()",
                    "Access autoloads directly without .new()"
                ))
            
            # Check for == true or == false (redundant)
            if re.search(r'==\s*true\b', line):
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "godot-pattern",
                    "Redundant '== true' comparison",
                    "Remove '== true'"
                ))
            if re.search(r'==\s*false\b', line):
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "godot-pattern",
                    "Use 'not' instead of '== false'",
                    "Replace with 'not variable'"
                ))
            
            # Check for print statements in production code
            if 'print(' in line and not '[DEBUG]' in line:
                violations.append(StyleViolation(
                    file, i, Severity.INFO, "godot-pattern",
                    "Print statement without [DEBUG] tag",
                    "Add [DEBUG] tag or use push_warning/push_error"
                ))
            
            # Check for get_node instead of $ shorthand
            if 'get_node(' in line and not 'get_node_or_null' in line:
                violations.append(StyleViolation(
                    file, i, Severity.INFO, "godot-pattern",
                    "Consider using $ shorthand instead of get_node()",
                    "Replace get_node('Path') with $Path"
                ))
            
            # Check for connecting signals in _ready without CONNECT_DEFERRED
            if '.connect(' in line and i > 0:
                # Check if we're in _ready function
                for j in range(max(0, i-10), i):
                    if 'func _ready' in lines[j]:
                        if 'CONNECT_DEFERRED' not in line:
                            violations.append(StyleViolation(
                                file, i, Severity.INFO, "godot-pattern",
                                "Consider CONNECT_DEFERRED for signals in _ready",
                                "Add CONNECT_DEFERRED flag if needed"
                            ))
                        break
        
        return violations
    
    def check_documentation(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for missing documentation on public functions and classes."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Check for public functions without doc comments
            # Skip Godot virtual methods (_*) and private methods (__*)
            if stripped.startswith('func ') and not stripped.startswith('func _'):
                # Check if previous line has a doc comment
                if i > 1 and not lines[i-2].strip().startswith('##'):
                    func_name = re.search(r'func\s+(\w+)', stripped)
                    if func_name:
                        violations.append(StyleViolation(
                            file, i, Severity.INFO, "documentation",
                            f"Public function '{func_name.group(1)}' lacks documentation",
                            "Add ## doc comment above function"
                        ))
            
            # Check for class_name without description
            if stripped.startswith('class_name '):
                if i == 1 or not lines[0].strip().startswith('##'):
                    violations.append(StyleViolation(
                        file, i, Severity.INFO, "documentation",
                        "Class lacks documentation comment",
                        "Add ## comment at top of file describing the class"
                    ))
        
        return violations
    
    def check_assertions(self, file: str, lines: List[str]) -> List[StyleViolation]:
        """Check for proper use of assertions vs defensive checks."""
        violations = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            
            # Check for defensive null checks that should be assertions
            if re.search(r'if\s+not\s+\w+:.*return', line):
                if 'optional' not in line.lower() and 'or_null' not in line:
                    violations.append(StyleViolation(
                        file, i, Severity.INFO, "assertion",
                        "Defensive null check might be better as assertion",
                        "Use assert() for required dependencies"
                    ))
            
            # Check for assertions without messages
            if 'assert(' in line and ',' not in line:
                violations.append(StyleViolation(
                    file, i, Severity.WARNING, "assertion",
                    "Assertion without error message",
                    "Add descriptive message: assert(condition, 'Error message')"
                ))
        
        return violations
    
    def is_valid_godot_method(self, func_name: str) -> bool:
        """Check if a function with single underscore is a valid Godot virtual method or signal handler."""
        # Check if it's an exact match for a known Godot virtual method
        if func_name in self.godot_virtual_methods:
            return True
        
        # Check if it's a signal handler pattern (_on_NodeName_signal_name)
        if func_name.startswith('_on_'):
            return True
        
        # Check common signal handler suffixes
        for suffix in ['_pressed', '_toggled', '_text_changed', '_item_selected',
                       '_value_changed', '_timeout', '_tween_completed', '_finished']:
            if func_name.endswith(suffix):
                return True
        
        return False
    
    # Utility functions
    def is_pascal_case(self, name: str) -> bool:
        """Check if name is in PascalCase."""
        return bool(re.match(r'^[A-Z][a-zA-Z0-9]*$', name))
    
    def is_snake_case(self, name: str) -> bool:
        """Check if name is in snake_case."""
        return bool(re.match(r'^[a-z_][a-z0-9_]*$', name))
    
    def is_upper_snake_case(self, name: str) -> bool:
        """Check if name is in UPPER_SNAKE_CASE."""
        return bool(re.match(r'^[A-Z][A-Z0-9_]*$', name))
    
    def to_pascal_case(self, name: str) -> str:
        """Convert name to PascalCase."""
        parts = name.split('_')
        return ''.join(word.capitalize() for word in parts)
    
    def to_snake_case(self, name: str) -> str:
        """Convert name to snake_case."""
        # Insert underscore before capitals and lowercase everything
        result = re.sub(r'([A-Z])', r'_\1', name).lower()
        # Remove leading underscore if any
        return result.lstrip('_')
    
    def print_violations(self, violations: List[StyleViolation]):
        """Print violations in a formatted way."""
        if not violations:
            return
        
        # Group by severity
        errors = [v for v in violations if v.severity == Severity.ERROR]
        warnings = [v for v in violations if v.severity == Severity.WARNING]
        infos = [v for v in violations if v.severity == Severity.INFO]
        
        # Print by severity
        if errors:
            print("\n❌ ERRORS:")
            for v in errors:
                print(f"  {v.file}:{v.line} [{v.rule}] {v.message}")
                if v.suggestion and self.verbose:
                    print(f"    → {v.suggestion}")
        
        if warnings:
            print("\n⚠️  WARNINGS:")
            for v in warnings:
                print(f"  {v.file}:{v.line} [{v.rule}] {v.message}")
                if v.suggestion and self.verbose:
                    print(f"    → {v.suggestion}")
        
        if infos and self.verbose:
            print("\nℹ️  INFO:")
            for v in infos:
                print(f"  {v.file}:{v.line} [{v.rule}] {v.message}")
                if v.suggestion:
                    print(f"    → {v.suggestion}")
    
    def get_summary(self, violations: List[StyleViolation]) -> str:
        """Get summary statistics."""
        errors = len([v for v in violations if v.severity == Severity.ERROR])
        warnings = len([v for v in violations if v.severity == Severity.WARNING])
        infos = len([v for v in violations if v.severity == Severity.INFO])
        
        parts = []
        if errors:
            parts.append(f"{errors} errors")
        if warnings:
            parts.append(f"{warnings} warnings")
        if infos:
            parts.append(f"{infos} info")
        
        return f"Found {', '.join(parts)}" if parts else "No issues found"


def find_gd_files(path: Path, recursive: bool = True) -> List[Path]:
    """Find all .gd files in the given path."""
    if path.is_file():
        return [path] if path.suffix == '.gd' else []
    
    if recursive:
        return list(path.rglob('*.gd'))
    else:
        return list(path.glob('*.gd'))


def main():
    parser = argparse.ArgumentParser(description="Godot Style Checker")
    parser.add_argument('files', nargs='*', help='Files to check (default: all .gd files in src/)')
    parser.add_argument('--all', action='store_true', help='Check all .gd files in project')
    parser.add_argument('--verbose', '-v', action='store_true', help='Show detailed output')
    parser.add_argument('--errors-only', action='store_true', help='Only show errors, not warnings')
    parser.add_argument('--max-violations', type=int, default=100, help='Maximum violations to show')
    
    args = parser.parse_args()
    
    # Determine which files to check
    files_to_check = []
    
    if args.files:
        for file_path in args.files:
            path = Path(file_path)
            if path.exists():
                files_to_check.extend(find_gd_files(path))
    elif args.all:
        files_to_check = find_gd_files(Path.cwd(), recursive=True)
    else:
        # Default: check src/ directory
        src_path = Path('src')
        if src_path.exists():
            files_to_check = find_gd_files(src_path, recursive=True)
        else:
            files_to_check = find_gd_files(Path.cwd(), recursive=True)
    
    if not files_to_check:
        print("No .gd files found to check")
        return 0
    
    print(f"🔍 Checking {len(files_to_check)} files for style violations...\n")
    
    # Run the checker
    checker = StyleChecker(verbose=args.verbose)
    all_violations = []
    
    for file_path in files_to_check:
        violations = checker.check_file(file_path)
        all_violations.extend(violations)
    
    # Filter if requested
    if args.errors_only:
        all_violations = [v for v in all_violations if v.severity == Severity.ERROR]
    
    # Limit violations shown
    if len(all_violations) > args.max_violations:
        all_violations = all_violations[:args.max_violations]
        print(f"\n(Showing first {args.max_violations} violations)\n")
    
    # Print results
    checker.print_violations(all_violations)
    
    # Print summary
    print("\n" + "="*60)
    print(f"Files checked: {checker.files_checked}")
    print(checker.get_summary(all_violations))
    
    # Return exit code based on errors
    error_count = len([v for v in all_violations if v.severity == Severity.ERROR])
    if error_count > 0:
        print(f"\n❌ Style check failed with {error_count} errors")
        return 1
    elif len(all_violations) > 0:
        print("\n⚠️  Style check passed with warnings")
        return 0
    else:
        print("\n✅ Style check passed!")
        return 0


if __name__ == '__main__':
    sys.exit(main())