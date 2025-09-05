#!/usr/bin/env python3
"""
Add new waves - Batch 2: Medium waves (difficulty 26-60)
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

def add_medium_waves():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Medium waves (difficulty 26-60)
    new_waves = [
        ['wave_6a', 'Oil Slick', 2, 28, 'Medium', 'Resource Drain', 'Heavy resource drain', 'oil_thief'],
        ['wave_6b', 'Chaos Begins', 2, 27, 'Medium', 'Chaos Threat', 'Unpredictable enemy', 'chaos_imp'],
        ['wave_6c', 'Spawner Alert', 2, 30, 'Medium', 'Spawner Threat', 'Enemy that creates more', 'gnat_spawner'],
        ['wave_6d', 'Momentum Steal', 2, 30, 'Medium', 'Momentum Drain', 'Drains momentum', 'momentum_thief'],
        ['wave_6e', 'Dual Ticks', 2, 29, 'Medium', 'Double Disruption', 'Multiple disruptors', 'gear_tick|siphon_tick'],
        ['wave_6f', 'Armored Squad', 2, 27, 'Medium', 'Armor Tutorial', 'Learn armor mechanics', 'rust_speck|rust_speck|rust_speck'],
        ['wave_7a', 'Spring Attack', 2, 36, 'Medium', 'Spring Threat', 'Bouncing damage', 'spring_snapper'],
        ['wave_7b', 'Phase One', 2, 40, 'Medium', 'Phase Threat', 'Phasing enemy', 'phase_shifter'],
        ['wave_7c', 'Oil Squad', 2, 44, 'Medium', 'Drain Squad', 'Multiple drainers', 'oil_thief|dust_mite|dust_mite'],
        ['wave_7d', 'Feedback Begin', 2, 36, 'Medium', 'Feedback Loop', 'Escalating threat', 'feedback_loop'],
        ['wave_7e', 'Dual Springs', 2, 37, 'Medium', 'Double Spring', 'Multiple bouncers', 'spring_snapper|basic_gnat'],
        ['wave_7f', 'Chaos Patrol', 2, 43, 'Medium', 'Chaos Squad', 'Unpredictable group', 'chaos_imp|dust_mite|dust_mite'],
        ['wave_8a', 'Mirror Match', 2, 60, 'Hard', 'Mirror Threat', 'Reflects your actions', 'mirror_warden'],
        ['wave_8b', 'Echo Test', 2, 55, 'Hard', 'Echo Threat', 'Repeating patterns', 'echo_chamber'],
        ['wave_8c', 'Double Trouble', 2, 56, 'Hard', 'Double Drain', 'Heavy resource pressure', 'oil_thief|oil_thief']
    ]
    
    body = {'values': new_waves}
    
    result = sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Added {len(new_waves)} medium waves")

if __name__ == "__main__":
    add_medium_waves()