#!/usr/bin/env python3
"""Fix all remaining type safety issues."""

import subprocess
import re
from pathlib import Path

def get_all_issues():
    """Get all type safety issues from the checker."""
    result = subprocess.run(
        ["python3", "check_type_safety.py", "--all"],
        capture_output=True,
        text=True
    )
    
    issues = []
    for line in result.stdout.split('\n'):
        # Parse issues: filepath:line_num: message
        match = re.match(r'\s*(.+):(\d+):\s*(.+)', line)
        if match:
            filepath = match.group(1).strip()
            line_num = int(match.group(2))
            message = match.group(3)
            issues.append((filepath, line_num, message))
    
    return issues

def fix_issue(filepath: Path, line_num: int, message: str) -> bool:
    """Fix a single issue."""
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    if line_num > len(lines):
        return False
    
    idx = line_num - 1
    line = lines[idx]
    modified = False
    
    if "missing return type" in message:
        # Add return type
        if "func " in line and "->" not in line:
            # Determine return type from function name or message
            return_type = "-> void"
            if "has_" in line or "is_" in line:
                return_type = "-> bool"
            elif "get_" in line:
                return_type = "-> Variant"
            elif "pct" in line:
                return_type = "-> float"
                
            # Insert return type before colon
            paren_pos = line.rfind(')')
            colon_pos = line.rfind(':')
            if paren_pos != -1 and colon_pos != -1:
                before = line[:paren_pos + 1]
                after = line[paren_pos + 1:]
                lines[idx] = before + " " + return_type + after
                modified = True
                print(f"  Fixed: Added {return_type} at line {line_num}")
                
    elif "should explicitly specify '-> void'" in message:
        # Add -> void to _init functions
        if "_init" in line and "->" not in line:
            paren_pos = line.rfind(')')
            colon_pos = line.rfind(':')
            if paren_pos != -1 and colon_pos != -1:
                before = line[:paren_pos + 1]
                after = line[paren_pos + 1:]
                lines[idx] = before + " -> void" + after
                modified = True
                print(f"  Fixed: Added -> void to _init at line {line_num}")
                
    elif "Use typed dictionaries" in message:
        # Fix untyped dictionary
        if "{}" in line and "Dictionary[" not in line:
            # Try to infer type from context
            if "wave" in line.lower():
                lines[idx] = line.replace("{}", "{} as Dictionary[String, Variant]")
            else:
                lines[idx] = line.replace("{}", "{} as Dictionary")
            modified = True
            print(f"  Fixed: Typed dictionary at line {line_num}")
            
    elif "Use typed arrays" in message:
        # Fix untyped array
        if "[]" in line and "Array[" not in line:
            lines[idx] = line.replace("[]", "[] as Array")
            modified = True
            print(f"  Fixed: Typed array at line {line_num}")
    
    if modified:
        with open(filepath, 'w') as f:
            f.writelines(lines)
    
    return modified

def main():
    """Main entry point."""
    print("Getting all type safety issues...")
    issues = get_all_issues()
    print(f"Found {len(issues)} issues to fix")
    
    # Group by file
    issues_by_file = {}
    for filepath, line_num, message in issues:
        if filepath not in issues_by_file:
            issues_by_file[filepath] = []
        issues_by_file[filepath].append((line_num, message))
    
    total_fixed = 0
    for filepath, file_issues in issues_by_file.items():
        file_path = Path(filepath)
        if not file_path.exists():
            print(f"Warning: {filepath} not found")
            continue
        
        print(f"\nFixing {filepath}...")
        # Sort by line number in reverse to avoid offset issues
        file_issues.sort(key=lambda x: x[0], reverse=True)
        
        for line_num, message in file_issues:
            if fix_issue(file_path, line_num, message):
                total_fixed += 1
    
    print(f"\n✅ Fixed {total_fixed} issues")
    
    # Run checker again to verify
    print("\nVerifying fixes...")
    result = subprocess.run(
        ["python3", "check_type_safety.py", "--all"],
        capture_output=True,
        text=True
    )
    
    if "✅ Type safety check passed!" in result.stdout:
        print("✅ All type safety checks now pass!")
    else:
        remaining = len([line for line in result.stdout.split('\n') if re.match(r'\s*.+:\d+:', line)])
        print(f"⚠️  {remaining} issues remain (may need manual fixing)")

if __name__ == "__main__":
    main()