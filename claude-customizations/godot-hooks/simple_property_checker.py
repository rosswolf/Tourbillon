#!/usr/bin/env python3
"""
Simple Property Checker for common GDScript mistakes
Catches common property name errors that the compiler won't detect.
"""

import re
import sys
from pathlib import Path

# Known property mappings for common classes
KNOWN_PROPERTIES = {
    'CappedResource': {'amount', 'max_amount', 'increment', 'decrement', 'have_enough', 'send_signal'},
    'Hero': {'red', 'blue', 'green', 'white', 'purple', 'heat', 'precision', 'momentum', 'balance', 'entropy'},
    'Gremlin': {'current_hp', 'max_hp', 'shields', 'armor', 'gremlin_name'},
    'Card': {'display_name', 'instance_id', 'template_id', 'time_cost', 'production_interval'},
}

# Common incorrect property names and their corrections
COMMON_MISTAKES = {
    'current': 'amount',  # Common mistake on CappedResource
    'health': 'current_hp',  # Common mistake on Gremlin
    'name': 'display_name',  # Common mistake on Entity subclasses
}

def check_file(filepath: Path) -> list:
    """Check a single file for property access issues."""
    errors = []
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    for line_num, line in enumerate(lines, 1):
        # Skip comments
        if line.strip().startswith('#'):
            continue
        
        # Look for .current on resources (most common mistake)
        if '.current' in line and 'resource' in line.lower():
            # Check if it's accessing .current on something that looks like a resource
            if re.search(r'\bresource\w*\.current\b', line, re.IGNORECASE):
                errors.append(f"{filepath}:{line_num}: Likely error: '.current' should be '.amount' on CappedResource")
        
        # Look for common property mistakes
        for wrong_prop, correct_prop in COMMON_MISTAKES.items():
            pattern = rf'\.\b{wrong_prop}\b'
            if re.search(pattern, line):
                # Try to determine context
                context = line.strip()[:80]  # First 80 chars for context
                if 'resource' in line.lower() and wrong_prop == 'current':
                    errors.append(f"{filepath}:{line_num}: '.{wrong_prop}' should likely be '.{correct_prop}' - {context}")
    
    return errors

def main():
    src_dir = Path("src/scenes")
    if not src_dir.exists():
        print("❌ src/scenes directory not found")
        sys.exit(1)
    
    print("🔍 Simple Property Checker")
    print("=" * 60)
    print("Checking for common property name mistakes...")
    
    all_errors = []
    files_checked = 0
    
    for gd_file in src_dir.rglob("*.gd"):
        errors = check_file(gd_file)
        all_errors.extend(errors)
        files_checked += 1
    
    print(f"✓ Checked {files_checked} files")
    
    if all_errors:
        print("\n❌ Potential Property Issues Found:")
        for error in all_errors:
            print(f"  {error}")
        print(f"\nTotal issues: {len(all_errors)}")
        sys.exit(1)
    else:
        print("\n✅ No common property mistakes found!")
        sys.exit(0)

if __name__ == "__main__":
    main()