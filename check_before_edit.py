#!/usr/bin/env python3
"""
Pre-edit checker for Claude to prevent editing auto-generated files
Add this to your workflow BEFORE editing any JSON files
"""

import os
import sys
import json

# Auto-generated files that should not be edited
AUTO_GENERATED_FILES = {
    'mob_data.json': 'https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/',
    'card_data.json': 'https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/',
    'wave_data.json': 'Google Sheets (see CLAUDE.md)',
    'goals_data.json': 'Google Sheets (see CLAUDE.md)',
    'configuration_data.json': 'Google Sheets (see CLAUDE.md)'
}

def check_file(filepath):
    """Check if a file should be edited"""
    filename = os.path.basename(filepath)
    
    if filename in AUTO_GENERATED_FILES:
        print(f"""
╔══════════════════════════════════════════════════════════════╗
║  ⛔ STOP! DO NOT EDIT {filename:<40} ║
╠══════════════════════════════════════════════════════════════╣
║  This file is AUTO-GENERATED from Google Sheets!            ║
║  Any changes will be LOST on next sync!                     ║
╠══════════════════════════════════════════════════════════════╣
║  ✅ CORRECT WORKFLOW:                                       ║
║  1. Edit the Google Sheets spreadsheet:                     ║
║     {AUTO_GENERATED_FILES[filename]:<55} ║
║                                                              ║
║  2. Sync the changes:                                       ║
║     cd elastic-app/app/src/scenes/data                      ║
║     python3 json_exporter.py                                ║
║                                                              ║
║  📖 See: elastic-app/app/src/scenes/data/CLAUDE.md         ║
╚══════════════════════════════════════════════════════════════╝
""")
        return False
    
    # Check for CLAUDE.md in the same directory
    dir_path = os.path.dirname(filepath) if filepath else '.'
    claude_md = os.path.join(dir_path, 'CLAUDE.md')
    
    if os.path.exists(claude_md):
        print(f"""
📋 REMINDER: There is a CLAUDE.md file in this directory!
   {claude_md}
   
   Please read it BEFORE making changes to ensure you follow
   the correct workflow for this directory.
""")
    
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        filepath = sys.argv[1]
        if not check_file(filepath):
            sys.exit(1)
    else:
        print("Usage: python3 check_before_edit.py <filepath>")
        print("Returns 0 if safe to edit, 1 if not")