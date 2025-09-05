#!/usr/bin/env python3
"""Enhanced converter for mob_data.json to use new multi-move format"""

import json
import re

# Define interesting multi-move patterns for specific gremlins
CUSTOM_PATTERNS = {
    "gear_tick": [
        ("card_cost_penalty=1", 5),  # Every 5 ticks
        ("force_discard=1", 10),      # Every 10 ticks
    ],
    "spring_snapper": [
        ("drain_momentum=2", 8),       # Every 8 ticks
        ("summon=basic_gnat", 12),     # Every 12 ticks
    ],
    "oil_thief": [
        ("max_resource_hard_cap=3", 0),  # Passive (always on)
        ("drain_largest=2", 15),         # Every 15 ticks
    ],
    "breeding_gnat": [
        ("summon=basic_gnat", 12),       # Keep original
    ],
    "gear_grinder": [
        ("card_cost_penalty=2", 6),      # Every 6 ticks
        ("force_discard=2", 12),         # Every 12 ticks
        ("drain_all_types=1", 18),       # Every 18 ticks
    ],
}

def parse_moves_string(moves_str):
    """Parse the old moves string format into individual moves"""
    if not moves_str:
        return {'moves': [], 'ticks': None}
    
    # Handle if it's accidentally a list already
    if isinstance(moves_str, list):
        return {'moves': [], 'ticks': None}
    
    moves = []
    ticks = None
    
    # Split by comma and process each part
    parts = moves_str.split(',')
    for part in parts:
        part = part.strip()
        if '=' in part:
            key, value = part.split('=', 1)
            key = key.strip()
            value = value.strip()
            
            if key == 'ticks':
                # This is the timing for the following moves
                ticks = int(value)
            else:
                # This is an actual move effect
                moves.append(f"{key}={value}")
    
    return {'moves': moves, 'ticks': ticks}

def convert_mob_entry(mob):
    """Convert a single mob entry to new format"""
    template_id = mob.get('template_id', '')
    
    # Check for custom pattern
    if template_id in CUSTOM_PATTERNS:
        # Use custom multi-move pattern
        for i, (move, ticks) in enumerate(CUSTOM_PATTERNS[template_id], 1):
            mob[f'move_{i}'] = move
            mob[f'move_{i}_ticks'] = ticks
        
        # Keep old moves for reference
        if 'moves' in mob:
            mob['__old_moves'] = mob['moves']
            del mob['moves']
    elif 'moves' in mob and mob['moves']:
        # Use automatic conversion
        old_moves = mob['moves']
        parsed = parse_moves_string(old_moves)
        
        # Keep the old moves field for reference
        mob['__old_moves'] = old_moves
        
        # Add new move fields
        if parsed['moves']:
            for i, move in enumerate(parsed['moves'], 1):
                mob[f'move_{i}'] = move
                mob[f'move_{i}_ticks'] = parsed['ticks'] if parsed['ticks'] is not None else 0
        
        # Remove the old moves field
        del mob['moves']
    
    return mob

def main():
    # Read the current mob_data.json
    with open('mob_data.json', 'r') as f:
        data = json.load(f)
    
    # Convert each mob entry
    converted_data = []
    for mob in data:
        converted_mob = convert_mob_entry(mob.copy())
        converted_data.append(converted_mob)
    
    # Write the converted data
    with open('mob_data_enhanced.json', 'w') as f:
        json.dump(converted_data, f, indent=2)
    
    print(f"Converted {len(data)} mob entries")
    print("Output written to mob_data_enhanced.json")
    
    # Show examples, especially custom patterns
    print("\n=== Custom Multi-Move Patterns ===")
    for mob in converted_data:
        if mob['template_id'] in CUSTOM_PATTERNS:
            print(f"\n{mob['template_id']} ({mob['display_name']}):")
            if '__old_moves' in mob:
                print(f"  Old: {mob['__old_moves']}")
            for i in range(1, 7):
                if f'move_{i}' in mob:
                    ticks = mob[f'move_{i}_ticks']
                    if ticks == 0:
                        print(f"  Move {i}: {mob[f'move_{i}']} (passive)")
                    else:
                        print(f"  Move {i}: {mob[f'move_{i}']} (every {ticks} ticks)")
    
    print("\n=== Regular Conversions ===")
    shown = 0
    for mob in converted_data:
        if mob['template_id'] not in CUSTOM_PATTERNS and '__old_moves' in mob and shown < 5:
            print(f"\n{mob['template_id']}:")
            print(f"  Old: {mob['__old_moves']}")
            for i in range(1, 7):
                if f'move_{i}' in mob:
                    ticks = mob[f'move_{i}_ticks']
                    if ticks == 0:
                        print(f"  Move {i}: {mob[f'move_{i}']} (passive)")
                    else:
                        print(f"  Move {i}: {mob[f'move_{i}']} (every {ticks} ticks)")
            shown += 1

if __name__ == '__main__':
    main()