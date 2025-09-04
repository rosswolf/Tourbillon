#!/usr/bin/env python3
"""
Fix remaining type safety issues that need more context
"""

import sys
import re
from pathlib import Path

def fix_static_data():
    """Fix static_data.gd dictionary typing issues."""
    filepath = Path('src/scenes/data/static_data.gd')
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    # Fix dictionaries that store JSON data - they should be Dictionary[String, Variant]
    replacements = [
        ('var __enum_mappings: Dictionary = {}', 'var __enum_mappings: Dictionary[String, Variant] = {}'),
        ('var __resolved_enum_cache: Dictionary = {}', 'var __resolved_enum_cache: Dictionary[String, Variant] = {}'),
        ('var __lookup_cache: Dictionary = {}', 'var __lookup_cache: Dictionary[String, Variant] = {}'),
        ('var card_data: Dictionary = {}', 'var card_data: Dictionary[String, Variant] = {}'),
        ('var card_data_indices: Dictionary = {}', 'var card_data_indices: Dictionary[String, int] = {}'),
        ('static var icon_data: Dictionary = {}', 'static var icon_data: Dictionary[String, Variant] = {}'),
        ('var icon_data_indices: Dictionary = {}', 'var icon_data_indices: Dictionary[String, int] = {}'),
        ('var mob_data: Dictionary = {}', 'var mob_data: Dictionary[String, Variant] = {}'),
        ('var mob_data_indices: Dictionary = {}', 'var mob_data_indices: Dictionary[String, int] = {}'),
        ('var goals_data: Dictionary = {}', 'var goals_data: Dictionary[String, Variant] = {}'),
        ('var goals_data_indices: Dictionary = {}', 'var goals_data_indices: Dictionary[String, int] = {}'),
        ('var relic_data: Dictionary = {}', 'var relic_data: Dictionary[String, Variant] = {}'),
        ('var relic_data_indices: Dictionary = {}', 'var relic_data_indices: Dictionary[String, int] = {}'),
        ('var hero_data: Dictionary = {}', 'var hero_data: Dictionary[String, Variant] = {}'),
        ('var hero_data_indices: Dictionary = {}', 'var hero_data_indices: Dictionary[String, int] = {}'),
        ('var wave_data: Dictionary = {}', 'var wave_data: Dictionary[String, Variant] = {}'),
        ('var wave_data_indices: Dictionary = {}', 'var wave_data_indices: Dictionary[String, int] = {}'),
        ('static var configuration_data: Dictionary = {}', 'static var configuration_data: Dictionary[String, Variant] = {}'),
    ]
    
    for old, new in replacements:
        for i, line in enumerate(lines):
            if old in line:
                lines[i] = line.replace(old, new)
                print(f"Fixed: {old} -> {new}")
    
    with open(filepath, 'w') as f:
        f.writelines(lines)
    
    print(f"✅ Fixed static_data.gd")

def fix_countdown():
    """Fix countdown.gd render_label function."""
    filepath = Path('src/scenes/countdown.gd')
    
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    for i, line in enumerate(lines):
        if 'func render_label():' in line:
            lines[i] = line.replace('func render_label():', 'func render_label() -> String:')
            print(f"Fixed render_label return type")
            break
    
    with open(filepath, 'w') as f:
        f.writelines(lines)
    
    print(f"✅ Fixed countdown.gd")

def fix_more_functions():
    """Fix remaining function return types and parameters."""
    files_to_fix = [
        ('src/scenes/data/static_data.gd', [
            ('func __build_enum_mappings():', 'func __build_enum_mappings() -> void:'),
            ('func __add_enum_mapping(enum_name: String, enum_dict: Dictionary):', 'func __add_enum_mapping(enum_name: String, enum_dict: Dictionary) -> void:'),
            ('func parse_enum(enum_name: String, value):', 'func parse_enum(enum_name: String, value: Variant) -> int:'),
            ('func load_json_file(path):', 'func load_json_file(path: String) -> Dictionary:'),
            ('func normalize_numeric_value(value):', 'func normalize_numeric_value(value: Variant) -> Variant:'),
            ('func clear_lookup_cache():', 'func clear_lookup_cache() -> void:'),
        ]),
        ('src/scenes/utilities/global_utilities.gd', [
            ('func get_enum_string(enum_dict, enum_value):', 'func get_enum_string(enum_dict: Dictionary, enum_value: int) -> String:'),
        ]),
        ('src/scenes/utilities/sprite_control.gd', [
            ('func set_sprite(sprite_key: String, target_node: TextureRect):', 'func set_sprite(sprite_key: String, target_node: TextureRect) -> void:'),
            ('func __update_min_size(target_node: TextureRect):', 'func __update_min_size(target_node: TextureRect) -> void:'),
        ]),
    ]
    
    for filepath_str, replacements in files_to_fix:
        filepath = Path(filepath_str)
        if not filepath.exists():
            continue
            
        with open(filepath, 'r') as f:
            lines = f.readlines()
        
        modified = False
        for old, new in replacements:
            for i, line in enumerate(lines):
                if old in line:
                    lines[i] = line.replace(old, new)
                    print(f"Fixed in {filepath}: {old[:30]}...")
                    modified = True
        
        if modified:
            with open(filepath, 'w') as f:
                f.writelines(lines)
            print(f"✅ Fixed {filepath}")

def fix_arrays_and_dicts():
    """Fix untyped arrays and dictionaries in various files."""
    
    files_with_issues = {
        'src/scenes/data/static_data.gd': [
            ('var resolved_data = []', 'var resolved_data: Array[Variant] = []'),
            ('var resolved_array = []', 'var resolved_array: Array[Variant] = []'),
            ('var resolved_dict = {}', 'var resolved_dict: Dictionary[String, Variant] = {}'),
            ('var result_dict = {}', 'var result_dict: Dictionary[String, Variant] = {}'),
            ('return []', 'return [] as Array[Variant]'),
        ],
        'src/scenes/ui/time/ui_beat_orchestrator.gd': [
            ('var active_tweens = []', 'var active_tweens: Array[Tween] = []'),
        ],
        'src/scenes/ui/hand/hand_container.gd': [
            ('var cards_in_hand: Dictionary = {}', 'var cards_in_hand: Dictionary[String, CardUI] = {}'),
        ],
        'src/scenes/ui/gremlins/ui_gremlin_panel.gd': [
            ('var _gremlin_containers: Dictionary = {}', 'var _gremlin_containers: Dictionary[String, Control] = {}'),
        ],
        'src/scenes/ui/mainplate/ui_mainplate.gd': [
            ('var neighbors = []', 'var neighbors: Array[Vector2i] = []'),
        ],
        'src/scenes/core/wave_manager.gd': [
            ('var wave_configs: Dictionary = {}', 'var wave_configs: Dictionary[String, Variant] = {}'),
            ('var current_wave_config: Dictionary = {}', 'var current_wave_config: Dictionary[String, Variant] = {}'),
        ],
        'src/scenes/core/entities/mainplate.gd': [
            ('var __slot_button_map: Dictionary = {}', 'var __slot_button_map: Dictionary[String, Button] = {}'),
            ('var __button_slot_map: Dictionary = {}', 'var __button_slot_map: Dictionary[String, String] = {}'),
            ('var __slot_type_map: Dictionary = {}', 'var __slot_type_map: Dictionary[String, String] = {}'),
            ('var new_slots = {}', 'var new_slots: Dictionary[String, Button] = {}'),
            ('var offsets = [', 'var offsets: Array[Vector2i] = ['),
        ],
        'src/scenes/core/entities/card.gd': [
            ('var text_parts = []', 'var text_parts: Array[String] = []'),
            ('[],', '[] as Array[Variant],'),
        ],
    }
    
    for filepath_str, replacements in files_with_issues.items():
        filepath = Path(filepath_str)
        if not filepath.exists():
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        modified = False
        for old, new in replacements:
            if old in content:
                content = content.replace(old, new)
                print(f"Fixed in {filepath}: {old[:30]}...")
                modified = True
        
        if modified:
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"✅ Fixed {filepath}")

def fix_more_missing_types():
    """Fix additional missing types in various files."""
    
    specific_fixes = [
        ('src/scenes/ui/entities/ui_entity.gd', 'var __is_hovered = false', 'var __is_hovered: bool = false'),
        ('src/scenes/ui/entities/engine/ui_texture_button.gd', 'var __is_hovered = false', 'var __is_hovered: bool = false'),
        ('src/scenes/ui/hand/hand_container.gd', 'var card_width = 0', 'var card_width: int = 0'),
        ('src/scenes/ui/hand/hand_container.gd', 'var angle_step = 0.0', 'var angle_step: float = 0.0'),
        ('src/scenes/ui/hand/hand_container.gd', 'var i = 0', 'var i: int = 0'),
        ('src/scenes/ui/hand/hand_container.gd', 'var card_index = -1', 'var card_index: int = -1'),
        ('src/scenes/ui/icons/game_icon.gd', 'var text = ""', 'var text: String = ""'),
        ('src/scenes/ui/gremlins/ui_gremlin_panel.gd', 'var test_types =', 'var test_types: Array[String] ='),
        ('src/scenes/ui/mainplate/ui_mainplate.gd', 'var is_bonus = false', 'var is_bonus: bool = false'),
        ('src/scenes/ui/mainplate/ui_mainplate.gd', 'var bonus_type = ""', 'var bonus_type: String = ""'),
        ('src/scenes/core/global_game_manager.gd', 'var gremlin_types =', 'var gremlin_types: Array[String] ='),
        ('src/scenes/core/entities/mainplate.gd', 'var count = 0', 'var count: int = 0'),
        ('src/scenes/core/effects/tourbillon_effect_processor.gd', 'var largest_amount = 0', 'var largest_amount: int = 0'),
        ('src/scenes/core/effects/tourbillon_effect_processor.gd', 'var smallest_amount = 999999', 'var smallest_amount: int = 999999'),
        ('src/scenes/core/effects/tourbillon_effect_processor.gd', 'var consumed = 0', 'var consumed: int = 0'),
        ('src/scenes/core/effects/tourbillon_effect_processor.gd', 'var force_types =', 'var force_types: Array[String] ='),
    ]
    
    for filepath_str, old, new in specific_fixes:
        filepath = Path(filepath_str)
        if not filepath.exists():
            continue
            
        with open(filepath, 'r') as f:
            content = f.read()
        
        if old in content:
            content = content.replace(old, new)
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"Fixed in {filepath}: {old[:30]}... -> {new[:30]}...")

def main():
    print("Fixing remaining type safety issues...")
    
    fix_static_data()
    fix_countdown()
    fix_more_functions()
    fix_arrays_and_dicts()
    fix_more_missing_types()
    
    print("\n✅ Finished fixing remaining type safety issues")

if __name__ == '__main__':
    main()