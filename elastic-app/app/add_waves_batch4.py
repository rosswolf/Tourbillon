#!/usr/bin/env python3
"""
Add new waves - Batch 4: Nightmare waves (difficulty 161-300)
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

def add_nightmare_waves():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Nightmare waves (difficulty 161-300)
    new_waves = [
        ['wave_12a', 'Rust Awakening', 3, 160, 'Nightmare', 'Boss Preview', 'Rust King appears', 'rust_king_phase_1'],
        ['wave_12b', 'Double Entropy', 3, 150, 'Nightmare', 'Double Chaos', 'Maximum entropy', 'entropic_mass|echo_chamber'],
        ['wave_12c', 'Constraint Chaos', 3, 153, 'Nightmare', 'Limited Chaos', 'Constraints and chaos', 'constraint_engine|echo_chamber'],
        ['wave_12d', 'Glutton Squad', 3, 154, 'Nightmare', 'Temporal Squad', 'Time devourers', 'temporal_glutton|phase_shifter'],
        ['wave_12e', 'Armor War', 3, 155, 'Nightmare', 'Heavy Armor', 'Maximum armor', 'gear_grinder|resource_tyrant'],
        ['wave_12f', 'Time War', 3, 134, 'Nightmare', 'Time Battle', 'Time manipulation', 'time_nibbler|time_nibbler'],
        ['wave_13a', 'Chrono Attack', 3, 192, 'Nightmare', 'Chronophage', 'Time eater', 'chronophage'],
        ['wave_13b', 'Double Paradox', 3, 186, 'Nightmare', 'Double Paradox', 'Dual paradox', 'balanced_paradox|balanced_paradox'],
        ['wave_13c', 'Rust Squad', 3, 196, 'Nightmare', 'Rust Army', 'King with support', 'rust_king_phase_1|spring_snapper'],
        ['wave_13d', 'Entropy Army', 3, 190, 'Nightmare', 'Entropy Battle', 'Maximum chaos army', 'entropic_mass|entropic_mass|dust_mite'],
        ['wave_13e', 'Constraint Army', 3, 196, 'Nightmare', 'Double Constraint', 'Heavy limitations', 'constraint_engine|constraint_engine'],
        ['wave_13f', 'Temporal Army', 3, 195, 'Nightmare', 'Time Army', 'Time manipulation squad', 'temporal_glutton|gear_grinder'],
        ['wave_14a', 'Sabotage', 3, 208, 'Nightmare+', 'Grand Saboteur', 'Ultimate sabotage', 'grand_saboteur'],
        ['wave_14b', 'Double Chrono', 3, 232, 'Nightmare+', 'Chrono Squad', 'Time eater squad', 'chronophage|phase_shifter'],
        ['wave_14c', 'Rust Empire', 3, 241, 'Nightmare+', 'Rust Empire', 'Rust King empire', 'rust_king_phase_1|gear_grinder']
    ]
    
    body = {'values': new_waves}
    
    result = sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Added {len(new_waves)} nightmare waves")

if __name__ == "__main__":
    add_nightmare_waves()