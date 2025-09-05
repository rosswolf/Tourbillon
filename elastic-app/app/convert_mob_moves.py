#!/usr/bin/env python3
"""Convert mob_data.json to use new multi-move format"""

import json
import re

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
    if 'moves' not in mob or not mob['moves']:
        return mob
    
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
    with open('mob_data_converted.json', 'w') as f:
        json.dump(converted_data, f, indent=2)
    
    print(f"Converted {len(data)} mob entries")
    print("Output written to mob_data_converted.json")
    
    # Show a few examples
    print("\nExample conversions:")
    for mob in converted_data[:5]:
        if '__old_moves' in mob:
            print(f"\n{mob['template_id']}:")
            print(f"  Old: {mob['__old_moves']}")
            for i in range(1, 7):
                if f'move_{i}' in mob:
                    print(f"  Move {i}: {mob[f'move_{i}']} (every {mob[f'move_{i}_ticks']} ticks)")

if __name__ == '__main__':
    main()