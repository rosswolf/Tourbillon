#!/usr/bin/env python3
"""
Update wave_data spreadsheet with corrected difficulties and new waves
"""

import os
import sys
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build
import json

# Add parent directory to path for imports
sys.path.insert(0, '/home/rosswolf/Code/Tourbillon-claude-2/elastic-app/app/src/scenes/data')

# Google Sheets setup
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = '/home/rosswolf/Code/google-sheets-mcp/service-account-key.json'
SPREADSHEET_ID = '1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw'

def get_sheets_service():
    """Create Google Sheets API service"""
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=creds)

def update_existing_difficulties():
    """Update existing wave difficulties to match total HP"""
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Corrections for existing waves
    corrections = {
        'wave_1a': 8,
        'wave_1b': 12,
        'wave_1c': 9,
        'wave_1d': 3,
        'wave_1e': 1,
        'wave_1f': 36,
        'wave_2a': 44,
        'wave_2b': 63,
        'wave_2c': 33,
        'wave_2d': 3,
        'wave_2e': 99,
        'wave_2f': 114,
        'wave_3a': 3,
        'wave_3b': 110,
        'boss_1': 232,
        'boss_2': 259
    }
    
    # Get current data
    result = sheet.values().get(
        spreadsheetId=SPREADSHEET_ID,
        range='wave_data!A:H'
    ).execute()
    
    values = result.get('values', [])
    if not values:
        print("No data found in spreadsheet")
        return
    
    headers = values[0]
    wave_id_col = headers.index('wave_id') if 'wave_id' in headers else 0
    difficulty_col = headers.index('difficulty') if 'difficulty' in headers else 3
    
    # Prepare batch updates
    updates = []
    
    for i, row in enumerate(values[1:], start=2):  # Start at row 2
        if len(row) > wave_id_col:
            wave_id = row[wave_id_col]
            if wave_id in corrections:
                # Update difficulty column
                cell_range = f'wave_data!{chr(65 + difficulty_col)}{i}'
                updates.append({
                    'range': cell_range,
                    'values': [[corrections[wave_id]]]
                })
                print(f"Updating {wave_id} difficulty to {corrections[wave_id]}")
    
    # Apply updates
    if updates:
        body = {
            'valueInputOption': 'RAW',
            'data': updates
        }
        
        result = sheet.values().batchUpdate(
            spreadsheetId=SPREADSHEET_ID,
            body=body
        ).execute()
        
        print(f"Updated {len(updates)} existing wave difficulties")

def add_new_waves():
    """Add new waves to the spreadsheet"""
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Define new waves
    new_waves = [
        # Difficulty 1-15 (Very Easy)
        ['wave_4a', 'Single Scout', 1, 1, 'Trivial', 'Tutorial', 'Learn basic combat', 'basic_gnat'],
        ['wave_4b', 'Lone Mite', 1, 8, 'Trivial', 'Rush Threat', 'Introduction to rush enemies', 'dust_mite'],
        ['wave_4c', 'Barrier Test', 1, 2, 'Trivial', 'Defense Tutorial', 'Learn about barriers', 'barrier_gnat|barrier_gnat'],
        ['wave_4d', 'Sparks Fly', 1, 10, 'Easy', 'Damage Tutorial', 'Introduction to spark damage', 'spark_flea'],
        ['wave_4e', 'Precision Strike', 1, 14, 'Easy', 'Precision Tutorial', 'Learn precision mechanics', 'precision_mite'],
        ['wave_4f', 'Double Gnats', 1, 2, 'Trivial', 'Swarm Intro', 'Multiple weak enemies', 'basic_gnat|basic_gnat'],
        
        # Difficulty 16-25 (Easy)
        ['wave_5a', 'Tick Tock', 1, 13, 'Easy', 'Mixed Threat', 'Combination of enemy types', 'gear_tick|basic_gnat'],
        ['wave_5b', 'Double Dust', 1, 16, 'Easy', 'Rush Swarm', 'Multiple rush enemies', 'dust_mite|dust_mite'],
        ['wave_5c', 'Siphon Intro', 1, 17, 'Easy', 'Drain Threat', 'Introduction to resource drain', 'siphon_tick'],
        ['wave_5d', 'Mixed Pests', 1, 17, 'Easy', 'Varied Threat', 'Different enemy types', 'rust_speck|dust_mite'],
        ['wave_5e', 'Gnat Swarm', 1, 5, 'Trivial', 'Pure Swarm', 'Many weak enemies', 'basic_gnat|basic_gnat|basic_gnat|basic_gnat|basic_gnat'],
        ['wave_5f', 'Spark and Dust', 1, 18, 'Easy', 'Damage Rush', 'Fast damage dealing', 'spark_flea|dust_mite'],
        
        # Difficulty 26-35 (Easy-Medium)
        ['wave_6a', 'Oil Slick', 1, 28, 'Medium', 'Resource Drain', 'Heavy resource drain', 'oil_thief'],
        ['wave_6b', 'Chaos Begins', 1, 27, 'Medium', 'Chaos Threat', 'Unpredictable enemy', 'chaos_imp'],
        ['wave_6c', 'Spawner Alert', 2, 30, 'Medium', 'Spawner Threat', 'Enemy that creates more enemies', 'gnat_spawner'],
        ['wave_6d', 'Momentum Steal', 2, 30, 'Medium', 'Momentum Drain', 'Drains momentum resource', 'momentum_thief'],
        ['wave_6e', 'Dual Ticks', 2, 29, 'Medium', 'Double Disruption', 'Multiple disruptors', 'gear_tick|siphon_tick'],
        ['wave_6f', 'Armored Squad', 2, 27, 'Medium', 'Armor Tutorial', 'Learn armor mechanics', 'rust_speck|rust_speck|rust_speck'],
        
        # Difficulty 36-45 (Medium)
        ['wave_7a', 'Spring Attack', 2, 36, 'Medium', 'Spring Threat', 'Bouncing damage', 'spring_snapper'],
        ['wave_7b', 'Phase One', 2, 40, 'Medium', 'Phase Threat', 'Phasing enemy', 'phase_shifter'],
        ['wave_7c', 'Oil Squad', 2, 44, 'Medium', 'Drain Squad', 'Multiple drainers', 'oil_thief|dust_mite|dust_mite'],
        ['wave_7d', 'Feedback Begin', 2, 36, 'Medium', 'Feedback Loop', 'Escalating threat', 'feedback_loop'],
        ['wave_7e', 'Dual Springs', 2, 37, 'Medium', 'Double Spring', 'Multiple bouncers', 'spring_snapper|basic_gnat'],
        ['wave_7f', 'Chaos Patrol', 2, 43, 'Medium', 'Chaos Squad', 'Unpredictable group', 'chaos_imp|dust_mite|dust_mite'],
        
        # Difficulty 46-60 (Medium-Hard)
        ['wave_8a', 'Mirror Match', 2, 60, 'Hard', 'Mirror Threat', 'Reflects your actions', 'mirror_warden'],
        ['wave_8b', 'Echo Test', 2, 55, 'Hard', 'Echo Threat', 'Repeating patterns', 'echo_chamber'],
        ['wave_8c', 'Double Trouble', 2, 56, 'Hard', 'Double Drain', 'Heavy resource pressure', 'oil_thief|oil_thief'],
        ['wave_8d', 'Phase Squad', 2, 56, 'Hard', 'Phase Group', 'Multiple phasers', 'phase_shifter|dust_mite|dust_mite'],
        ['wave_8e', 'Spawn Factory', 2, 60, 'Hard', 'Mass Spawning', 'Creates many enemies', 'gnat_spawner|gnat_spawner'],
        
        # Difficulty 61-80 (Hard)
        ['wave_9a', 'Time Nibble', 2, 67, 'Hard', 'Time Threat', 'Manipulates time', 'time_nibbler'],
        ['wave_9b', 'Resource War', 2, 74, 'Hard', 'Resource Control', 'Controls resources', 'resource_tyrant'],
        ['wave_9c', 'Mirror Chaos', 2, 75, 'Hard', 'Reflect Chaos', 'Chaotic reflection', 'mirror_warden|dust_mite|dust_mite|dust_mite'],
        ['wave_9d', 'Triple Oil', 2, 64, 'Hard', 'Triple Drain', 'Heavy drain pressure', 'oil_thief|oil_thief|dust_mite'],
        ['wave_9e', 'Echo Swarm', 2, 79, 'Hard', 'Echo Multiple', 'Echoing swarm', 'echo_chamber|dust_mite|dust_mite|dust_mite'],
        ['wave_9f', 'Dual Phase', 2, 80, 'Hard', 'Double Phase', 'Multiple phase enemies', 'phase_shifter|phase_shifter'],
        
        # Difficulty 81-100 (Hard)
        ['wave_10a', 'Gear Grind', 3, 81, 'Hard', 'Grinder Threat', 'Heavy armored enemy', 'gear_grinder'],
        ['wave_10b', 'Entropy Rising', 3, 91, 'Hard', 'Entropy Threat', 'Chaos incarnate', 'entropic_mass'],
        ['wave_10c', 'Paradox Found', 3, 93, 'Hard', 'Paradox Threat', 'Balanced chaos', 'balanced_paradox'],
        ['wave_10d', 'Constraint Test', 3, 98, 'Hard', 'Constraint Engine', 'Limits your options', 'constraint_engine'],
        ['wave_10e', 'Grinder Pair', 3, 89, 'Hard', 'Grinder Support', 'Armored with support', 'gear_grinder|dust_mite'],
        ['wave_10f', 'Time Echo', 3, 95, 'Hard', 'Time Echo', 'Time and echo combo', 'time_nibbler|oil_thief'],
        
        # Difficulty 101-130 (Very Hard)
        ['wave_11a', 'Temporal Feast', 3, 114, 'Nightmare', 'Temporal Glutton', 'Devours time', 'temporal_glutton'],
        ['wave_11b', 'Double Grind', 3, 117, 'Nightmare', 'Double Grinder', 'Two heavy enemies', 'gear_grinder|spring_snapper'],
        ['wave_11c', 'Resource Chaos', 3, 114, 'Nightmare', 'Resource Control', 'Resource manipulation', 'resource_tyrant|phase_shifter'],
        ['wave_11d', 'Mirror Grind', 3, 120, 'Nightmare', 'Reflect Grind', 'Reflection and armor', 'mirror_warden|mirror_warden'],
        ['wave_11e', 'Triple Springs', 3, 108, 'Nightmare', 'Triple Bounce', 'Many bouncers', 'spring_snapper|spring_snapper|spring_snapper'],
        ['wave_11f', 'Paradox Chaos', 3, 120, 'Nightmare', 'Paradox Mix', 'Balanced chaos combo', 'balanced_paradox|chaos_imp'],
        
        # Difficulty 131-160 (Nightmare)
        ['wave_12a', 'Rust Awakening', 3, 160, 'Nightmare', 'Boss Preview', 'Rust King appears', 'rust_king_phase_1'],
        ['wave_12b', 'Double Entropy', 3, 150, 'Nightmare', 'Double Chaos', 'Maximum entropy', 'entropic_mass|echo_chamber'],
        ['wave_12c', 'Constraint Chaos', 3, 153, 'Nightmare', 'Limited Chaos', 'Constraints and chaos', 'constraint_engine|echo_chamber'],
        ['wave_12d', 'Glutton Squad', 3, 154, 'Nightmare', 'Temporal Squad', 'Time devourers', 'temporal_glutton|phase_shifter'],
        ['wave_12e', 'Double Grind', 3, 155, 'Nightmare', 'Double Armor', 'Heavy armor', 'gear_grinder|resource_tyrant'],
        ['wave_12f', 'Time War', 3, 134, 'Nightmare', 'Time Battle', 'Time manipulation', 'time_nibbler|time_nibbler'],
        
        # Difficulty 161-200 (Nightmare)
        ['wave_13a', 'Chrono Attack', 3, 192, 'Nightmare', 'Chronophage', 'Time eater', 'chronophage'],
        ['wave_13b', 'Double Paradox', 3, 186, 'Nightmare', 'Double Paradox', 'Dual paradox', 'balanced_paradox|balanced_paradox'],
        ['wave_13c', 'Rust Squad', 3, 196, 'Nightmare', 'Rust Army', 'Rust King with support', 'rust_king_phase_1|spring_snapper'],
        ['wave_13d', 'Entropy War', 3, 190, 'Nightmare', 'Entropy Battle', 'Maximum chaos', 'entropic_mass|entropic_mass|dust_mite'],
        ['wave_13e', 'Constraint Army', 3, 196, 'Nightmare', 'Double Constraint', 'Heavy limitations', 'constraint_engine|constraint_engine'],
        ['wave_13f', 'Temporal Army', 3, 195, 'Nightmare', 'Time Army', 'Time manipulation squad', 'temporal_glutton|gear_grinder'],
        
        # Difficulty 200+ (Nightmare+)
        ['wave_14a', 'Sabotage', 3, 208, 'Nightmare+', 'Grand Saboteur', 'Ultimate sabotage', 'grand_saboteur'],
        ['wave_14b', 'Double Chrono', 3, 232, 'Nightmare+', 'Chrono Squad', 'Time eater squad', 'chronophage|phase_shifter'],
        ['wave_14c', 'Rust Empire', 3, 241, 'Nightmare+', 'Rust Empire', 'Rust King empire', 'rust_king_phase_1|gear_grinder'],
        ['wave_14d', 'Grand Chaos', 3, 235, 'Nightmare+', 'Ultimate Chaos', 'Maximum entropy', 'grand_saboteur|chaos_imp'],
        ['wave_14e', 'Final Stand', 3, 259, 'Nightmare+', 'Final Battle', 'Ultimate challenge', 'chronophage|time_nibbler'],
        ['wave_14f', 'Ultimate Test', 3, 280, 'Nightmare+', 'Ultimate Test', 'The final test', 'grand_saboteur|resource_tyrant']
    ]
    
    # Append to spreadsheet
    body = {
        'values': new_waves
    }
    
    result = sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range='wave_data!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Added {len(new_waves)} new waves to spreadsheet")

def main():
    print("Updating wave_data spreadsheet...")
    
    # First update existing difficulties
    print("\nStep 1: Updating existing wave difficulties...")
    update_existing_difficulties()
    
    # Then add new waves
    print("\nStep 2: Adding new waves...")
    add_new_waves()
    
    print("\nDone! Now sync the spreadsheet to JSON:")
    print("cd /home/rosswolf/Code/Tourbillon-claude-2/elastic-app/app/src/scenes/data")
    print("python3 json_exporter.py wave")

if __name__ == "__main__":
    main()