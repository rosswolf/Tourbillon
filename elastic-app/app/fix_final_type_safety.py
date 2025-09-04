#!/usr/bin/env python3
"""
Fix all remaining type safety issues in GDScript files.
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple

class FinalTypeSafetyFixer:
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.files_fixed = 0
        self.total_fixes = 0
        
    def fix_file(self, filepath: Path) -> bool:
        """Fix type safety issues in a single file."""
        if not filepath.exists():
            return False
            
        content = filepath.read_text()
        original_content = content
        lines = content.split('\n')
        modified = False
        
        for i, line in enumerate(lines):
            # Skip comments and empty lines
            stripped = line.strip()
            if stripped.startswith('#') or not stripped:
                continue
                
            # Fix missing return type annotations
            lines[i] = self._fix_return_types(lines[i], filepath.name, i+1)
            
            # Fix untyped arrays
            lines[i] = self._fix_untyped_arrays(lines[i], filepath.name, i+1)
            
            # Fix untyped dictionaries
            lines[i] = self._fix_untyped_dictionaries(lines[i], filepath.name, i+1)
            
            # Fix missing parameter types
            lines[i] = self._fix_parameter_types(lines[i], filepath.name, i+1)
            
        content = '\n'.join(lines)
        
        if content != original_content:
            filepath.write_text(content)
            self.files_fixed += 1
            if self.verbose:
                print(f"Fixed: {filepath}")
            return True
        return False
        
    def _fix_return_types(self, line: str, filename: str, line_num: int) -> str:
        """Fix missing return type annotations."""
        
        # Special handling for specific files and functions
        fixes = {
            # global_utilities.gd line 9
            ('global_utilities.gd', 9): {
                'pattern': r'static func get_enum_name\(enum_dict, enum_value\)',
                'replacement': 'static func get_enum_name(enum_dict: Dictionary, enum_value: int) -> String'
            },
            # sprite_control.gd line 4
            ('sprite_control.gd', 4): {
                'pattern': r'static func set_sprite\(',
                'replacement': 'static func set_sprite('
            },
            # Various _init functions
            ('*', '*'): {
                'pattern': r'func _init\(([^)]*)\)(?:\s*:)?$',
                'replacement': r'func _init(\1) -> void:'
            },
            # Functions missing return type
            ('*', '*'): {
                'pattern': r'func (\w+)\(([^)]*)\)(?:\s*:)?$',
                'check': lambda m: m.group(1) not in ['_init', '_ready', '_process', '_physics_process'] or '_init' in m.group(1),
                'replacement': r'func \1(\2) -> void:'
            }
        }
        
        # Check specific file/line fixes first
        key = (filename, line_num)
        if key in fixes:
            fix = fixes[key]
            if re.search(fix['pattern'], line):
                line = re.sub(fix['pattern'], fix['replacement'], line)
                self.total_fixes += 1
                
        # Apply general patterns
        # Fix functions declared without return type
        if 'func ' in line and ')' in line and '->' not in line and not line.strip().startswith('#'):
            # Skip if it already has a colon (means it's properly typed)
            if line.strip().endswith(':'):
                return line
                
            # Special cases for known functions
            if 'set_hovered' in line:
                line = re.sub(r'func set_hovered\((.*?)\)', r'func set_hovered(\1) -> void', line)
                self.total_fixes += 1
            elif 'set_selected_force' in line:
                line = re.sub(r'func set_selected_force\((.*?)\)', r'func set_selected_force(\1) -> void', line)
                self.total_fixes += 1
            elif 'is_valid_target' in line:
                line = re.sub(r'func is_valid_target\((.*?)\)', r'func is_valid_target(\1) -> bool', line)
                self.total_fixes += 1
            elif 'activate' in line and 'move_descriptor_effect' in filename:
                line = re.sub(r'func activate\((.*?)\)', r'func activate(\1) -> void', line)
                self.total_fixes += 1
            elif 'has_status_effect' in line:
                line = re.sub(r'func has_status_effect\((.*?)\)', r'func has_status_effect(\1) -> bool', line)
                self.total_fixes += 1
            elif 'decrement_status_effect' in line:
                line = re.sub(r'func decrement_status_effect\((.*?)\)', r'func decrement_status_effect(\1) -> void', line)
                self.total_fixes += 1
            elif 'activate_slot_effect' in line and 'button.gd' in filename:
                line = re.sub(r'func activate_slot_effect\((.*?)\)', r'func activate_slot_effect(\1) -> void', line)
                self.total_fixes += 1
            elif 'has_relic' in line:
                line = re.sub(r'func has_relic\((.*?)\)', r'func has_relic(\1) -> bool', line)
                self.total_fixes += 1
            elif 'end_game' in line:
                line = re.sub(r'func end_game\((.*?)\)', r'func end_game(\1) -> void', line)
                self.total_fixes += 1
            elif 'add_card_to_zone' in line and 'library.gd' in filename:
                line = re.sub(r'func add_card_to_zone\((.*?)\)', r'func add_card_to_zone(\1) -> void', line)
                self.total_fixes += 1
            elif 'draw_card' in line and 'library.gd' in filename:
                line = re.sub(r'func draw_card\((.*?)\)', r'func draw_card(\1) -> void', line)
                self.total_fixes += 1
            elif 'draw_new_hand' in line and 'library.gd' in filename:
                line = re.sub(r'func draw_new_hand\((.*?)\)', r'func draw_new_hand(\1) -> void', line)
                self.total_fixes += 1
            elif 'increment' in line and 'capped_resource' in filename:
                line = re.sub(r'func increment\((.*?)\)', r'func increment(\1) -> void', line)
                self.total_fixes += 1
            elif 'decrement' in line and 'capped_resource' in filename:
                line = re.sub(r'func decrement\((.*?)\)', r'func decrement(\1) -> void', line)
                self.total_fixes += 1
            elif 'set_cursor_position' in line:
                line = re.sub(r'func set_cursor_position\((.*?)\)', r'func set_cursor_position(\1) -> void', line)
                self.total_fixes += 1
            elif 'create_card_ui' in line:
                line = re.sub(r'func create_card_ui\((.*?)\)', r'func create_card_ui(\1) -> void', line)
                self.total_fixes += 1
            elif 'pct' in line and ('ui_goal' in filename or 'ui_engine_slot' in filename):
                line = re.sub(r'func pct\((.*?)\)', r'func pct(\1) -> void', line)
                self.total_fixes += 1
            elif 'create_button_entity' in line:
                line = re.sub(r'func create_button_entity\((.*?)\)', r'func create_button_entity(\1) -> void', line)
                self.total_fixes += 1
            elif 'set_entity_data' in line and 'ui_entity' in filename:
                line = re.sub(r'func set_entity_data\((.*?)\)', r'func set_entity_data(\1) -> void', line)
                self.total_fixes += 1
            elif 'go_to_scene' in line:
                line = re.sub(r'func go_to_scene\((.*?)\)', r'func go_to_scene(\1) -> void', line)
                self.total_fixes += 1
            elif 'clear_hovered_known' in line:
                line = re.sub(r'func clear_hovered_known\((.*?)\)', r'func clear_hovered_known(\1) -> void', line)
                self.total_fixes += 1
            elif 'set_selected_known' in line:
                line = re.sub(r'func set_selected_known\((.*?)\)', r'func set_selected_known(\1) -> void', line)
                self.total_fixes += 1
            elif 'add_dragging_visual' in line:
                line = re.sub(r'func add_dragging_visual\((.*?)\)', r'func add_dragging_visual(\1) -> void', line)
                self.total_fixes += 1
            elif '_init' in line:
                line = re.sub(r'func _init\((.*?)\)(?:\s*:)?', r'func _init(\1) -> void:', line)
                self.total_fixes += 1
                
        return line
        
    def _fix_untyped_arrays(self, line: str, filename: str, line_num: int) -> str:
        """Fix untyped arrays."""
        
        # Specific fixes based on context
        if 'ui_mainplate.gd' in filename and line_num == 268:
            # var tags: Array = card.get_meta("tags", []) as Array
            line = re.sub(r'var tags: Array = (.*?)\[\]', r'var tags: Array[String] = \1[]', line)
            self.total_fixes += 1
        elif 'card.gd' in filename and 'text_parts' in line:
            line = re.sub(r'var text_parts: Array = \[\]', 'var text_parts: Array[String] = []', line)
            self.total_fixes += 1
        elif 'ui_beat_orchestrator' in filename and 'var slots' in line:
            line = re.sub(r'var slots: Array = \[\]', 'var slots: Array[EngineSlot] = []', line)
            self.total_fixes += 1
            
        # Generic array fixes
        elif re.search(r':\s*Array\s*=\s*\[\]', line):
            # Try to infer type from context
            if 'String' in line or 'text' in line.lower() or 'name' in line.lower():
                line = re.sub(r':\s*Array\s*=\s*\[\]', ': Array[String] = []', line)
                self.total_fixes += 1
            elif 'int' in line.lower() or 'number' in line.lower():
                line = re.sub(r':\s*Array\s*=\s*\[\]', ': Array[int] = []', line)
                self.total_fixes += 1
                
        return line
        
    def _fix_untyped_dictionaries(self, line: str, filename: str, line_num: int) -> str:
        """Fix untyped dictionaries."""
        
        # Specific fixes based on file and context
        if 'hand_container.gd' in filename and 'cards:' in line:
            line = re.sub(r'var cards:\s*Dictionary\s*=\s*{}', 
                         'var cards: Dictionary[String, CardUI] = {}', line)
            self.total_fixes += 1
        elif 'ui_gremlin_panel.gd' in filename and 'test_gremlin_data' in line:
            line = re.sub(r'var test_gremlin_data:\s*Dictionary\s*=\s*{}',
                         'var test_gremlin_data: Dictionary[String, Variant] = {}', line)
            self.total_fixes += 1
        elif 'wave_manager.gd' in filename:
            if 'current_wave:' in line:
                line = re.sub(r'var current_wave:\s*Dictionary\s*=\s*{}',
                             'var current_wave: Dictionary[String, Variant] = {}', line)
                self.total_fixes += 1
            elif 'wave_history:' in line:
                line = re.sub(r'var wave_history:\s*Dictionary\s*=\s*{}',
                             'var wave_history: Dictionary[int, String] = {}', line)
                self.total_fixes += 1
        elif 'mainplate.gd' in filename:
            if 'slots:' in line:
                line = re.sub(r'var slots:\s*Dictionary\s*=\s*{}',
                             'var slots: Dictionary[Vector2i, Card] = {}', line)
                self.total_fixes += 1
            elif 'card_states:' in line:
                line = re.sub(r'var card_states:\s*Dictionary\s*=\s*{}',
                             'var card_states: Dictionary[String, Dictionary] = {}', line)
                self.total_fixes += 1
            elif 'bonus_squares:' in line:
                line = re.sub(r'var bonus_squares:\s*Dictionary\s*=\s*{}',
                             'var bonus_squares: Dictionary[Vector2i, String] = {}', line)
                self.total_fixes += 1
            elif 'CardState' in line and '{}' in line:
                line = re.sub(r':\s*Dictionary\s*=\s*{}',
                             ': Dictionary[String, Variant] = {}', line)
                self.total_fixes += 1
                
        # Generic dictionary fixes
        elif re.search(r':\s*Dictionary\s*=\s*{}', line):
            # Default to String, Variant for safety
            line = re.sub(r':\s*Dictionary\s*=\s*{}',
                         ': Dictionary[String, Variant] = {}', line)
            self.total_fixes += 1
            
        return line
        
    def _fix_parameter_types(self, line: str, filename: str, line_num: int) -> str:
        """Fix missing parameter type annotations."""
        
        # Specific parameter type fixes
        if 'global_utilities.gd' in filename and 'get_enum_name' in line:
            line = re.sub(r'func get_enum_name\(enum_dict, enum_value\)',
                         'func get_enum_name(enum_dict: Dictionary, enum_value: int)', line)
            self.total_fixes += 1
        elif 'cost.gd' in filename and '__can_satisfy_requirement' in line and 'amount)' in line:
            line = re.sub(r'amount\)', 'amount: int)', line)
            self.total_fixes += 1
            
        return line

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Fix remaining type safety issues')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose output')
    parser.add_argument('files', nargs='*', help='Files to fix (default: all problem files)')
    args = parser.parse_args()
    
    fixer = FinalTypeSafetyFixer(verbose=args.verbose)
    
    # List of files with remaining issues
    problem_files = [
        'src/scenes/utilities/global_utilities.gd',
        'src/scenes/utilities/sprite_control.gd', 
        'src/scenes/ui/time/ui_beat_orchestrator.gd',
        'src/scenes/ui/entities/ui_entity.gd',
        'src/scenes/ui/entities/goals/ui_goal.gd',
        'src/scenes/ui/entities/engine/ui_texture_button.gd',
        'src/scenes/ui/entities/engine/ui_engine_slot.gd',
        'src/scenes/ui/hand/hand_container.gd',
        'src/scenes/ui/click_and_drag/image_cursor.gd',
        'src/scenes/ui/click_and_drag/global_selection_manager.gd',
        'src/scenes/ui/click_and_drag/cursor.gd',
        'src/scenes/ui/click_and_drag/click_and_drag.gd',
        'src/scenes/ui/transitions/fade_to_black.gd',
        'src/scenes/ui/gremlins/ui_gremlin_panel.gd',
        'src/scenes/ui/mainplate/ui_mainplate.gd',
        'src/scenes/core/wave_manager.gd',
        'src/scenes/core/global_game_manager.gd',
        'src/scenes/core/library.gd',
        'src/scenes/core/entities/battle_entity.gd',
        'src/scenes/core/entities/mainplate.gd',
        'src/scenes/core/entities/card.gd',
        'src/scenes/core/entities/button.gd',
        'src/scenes/core/resources/capped_resource.gd',
        'src/scenes/core/resources/relic_manager.gd',
        'src/scenes/core/resources/cost.gd',
        'src/scenes/core/resources/game_resource.gd',
        'src/scenes/core/effects/move_descriptor_effect.gd',
        'src/scenes/core/effects/one_time_effect.gd',
    ]
    
    files_to_fix = args.files if args.files else problem_files
    
    for filepath_str in files_to_fix:
        filepath = Path(filepath_str)
        if filepath.exists():
            fixer.fix_file(filepath)
            
    print(f"\n✅ Fixed {fixer.files_fixed} files with {fixer.total_fixes} total fixes")
    
if __name__ == '__main__':
    main()