#!/usr/bin/env python3
"""
Update wave_data spreadsheet - Batch 1: Fix existing difficulties
"""

import os
import sys
from pathlib import Path
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Google Sheets setup
SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = '/home/rosswolf/Code/google-sheets-mcp/service-account-key.json'
SPREADSHEET_ID = '1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw'

def get_sheets_service():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=creds)

def update_existing_difficulties():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Get current data
    result = sheet.values().get(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H'
    ).execute()
    
    values = result.get('values', [])
    headers = values[0]
    wave_id_col = headers.index('wave_id')
    difficulty_col = headers.index('difficulty')
    
    # Corrections based on total HP
    corrections = {
        'wave_1a': 8,   # dust_mite
        'wave_1b': 12,  # gear_tick
        'wave_1c': 9,   # rust_speck
        'wave_1d': 3,   # 3x basic_gnat
        'wave_1e': 1,   # constricting_barrier_gnat
        'wave_1f': 36,  # spring_snapper
        'wave_2a': 44,  # oil_thief + 2x dust_mite
        'wave_2b': 63,  # chaos_imp + spring_snapper
    }
    
    updates = []
    for i, row in enumerate(values[1:], start=2):
        if len(row) > wave_id_col:
            wave_id = row[wave_id_col]
            if wave_id in corrections:
                cell_range = f'Sheet1!{chr(65 + difficulty_col)}{i}'
                updates.append({
                    'range': cell_range,
                    'values': [[corrections[wave_id]]]
                })
                print(f"Will update {wave_id}: {corrections[wave_id]}")
    
    # Apply updates
    if updates:
        body = {'valueInputOption': 'RAW', 'data': updates}
        result = sheet.values().batchUpdate(
            spreadsheetId=SPREADSHEET_ID, body=body).execute()
        print(f"Updated {len(updates)} difficulties")

if __name__ == "__main__":
    update_existing_difficulties()