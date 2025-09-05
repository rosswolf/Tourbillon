#!/usr/bin/env python3
"""
Add new waves - Batch 3: Hard waves (difficulty 61-160)
"""

from google.oauth2 import service_account
from googleapiclient.discovery import build

SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = '/home/rosswolf/Code/google-sheets-mcp/service-account-key.json'
SPREADSHEET_ID = '1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw'

def get_sheets_service():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=creds)

def add_hard_waves():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Hard waves (difficulty 61-160)
    new_waves = [
        ['wave_9a', 'Time Nibble', 2, 67, 'Hard', 'Time Threat', 'Manipulates time', 'time_nibbler'],
        ['wave_9b', 'Resource War', 2, 74, 'Hard', 'Resource Control', 'Controls resources', 'resource_tyrant'],
        ['wave_9c', 'Mirror Chaos', 2, 75, 'Hard', 'Reflect Chaos', 'Mirror with support', 'mirror_warden|dust_mite|dust_mite|dust_mite'],
        ['wave_9d', 'Triple Oil', 2, 64, 'Hard', 'Triple Drain', 'Heavy drain pressure', 'oil_thief|oil_thief|dust_mite'],
        ['wave_9e', 'Echo Swarm', 2, 79, 'Hard', 'Echo Multiple', 'Echoing swarm', 'echo_chamber|dust_mite|dust_mite|dust_mite'],
        ['wave_9f', 'Dual Phase', 2, 80, 'Hard', 'Double Phase', 'Multiple phase enemies', 'phase_shifter|phase_shifter'],
        ['wave_10a', 'Gear Grind', 3, 81, 'Hard', 'Grinder Threat', 'Heavy armored enemy', 'gear_grinder'],
        ['wave_10b', 'Entropy Rising', 3, 91, 'Hard', 'Entropy Threat', 'Chaos incarnate', 'entropic_mass'],
        ['wave_10c', 'Paradox Found', 3, 93, 'Hard', 'Paradox Threat', 'Balanced chaos', 'balanced_paradox'],
        ['wave_10d', 'Constraint Test', 3, 98, 'Hard', 'Constraint Engine', 'Limits your options', 'constraint_engine'],
        ['wave_10e', 'Grinder Pair', 3, 89, 'Hard', 'Grinder Support', 'Armored with support', 'gear_grinder|dust_mite'],
        ['wave_10f', 'Time Echo', 3, 95, 'Hard', 'Time Echo Combo', 'Time and echo combo', 'time_nibbler|oil_thief'],
        ['wave_11a', 'Temporal Feast', 3, 114, 'Nightmare', 'Temporal Glutton', 'Devours time', 'temporal_glutton'],
        ['wave_11b', 'Double Grind', 3, 117, 'Nightmare', 'Double Grinder', 'Two heavy enemies', 'gear_grinder|spring_snapper'],
        ['wave_11c', 'Resource Chaos', 3, 114, 'Nightmare', 'Resource Control', 'Resource manipulation', 'resource_tyrant|phase_shifter']
    ]
    
    body = {'values': new_waves}
    
    result = sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Added {len(new_waves)} hard waves")

if __name__ == "__main__":
    add_hard_waves()