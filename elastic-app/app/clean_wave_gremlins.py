#!/usr/bin/env python3
"""
Clean up wave data spreadsheet by moving actual mob IDs from is_boss to gremlins column
when gremlins column contains descriptive text instead of actual mob IDs.
"""

from google.oauth2 import service_account
from googleapiclient.discovery import build
import json

SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = '/home/rosswolf/Code/google-sheets-mcp/service-account-key.json'
SPREADSHEET_ID = '1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw'

def get_sheets_service():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    return build('sheets', 'v4', credentials=creds)

def clean_wave_gremlins():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Get all data
    result = sheet.values().get(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:Z'  # Get all columns
    ).execute()
    
    values = result.get('values', [])
    if not values:
        print("No data found")
        return
    
    headers = values[0]
    print(f"Headers: {headers}")
    
    # Find column indices
    gremlins_col = None
    is_boss_col = None
    
    for i, header in enumerate(headers):
        if header == 'gremlins':
            gremlins_col = i
        elif header == 'is_boss':
            is_boss_col = i
    
    if gremlins_col is None or is_boss_col is None:
        print(f"Required columns not found. gremlins_col: {gremlins_col}, is_boss_col: {is_boss_col}")
        return
    
    print(f"gremlins column: {gremlins_col}, is_boss column: {is_boss_col}")
    
    # Process each row
    updates = []
    cleaned_count = 0
    
    for row_num, row in enumerate(values[1:], start=2):  # Start at row 2 (skip headers)
        if len(row) <= max(gremlins_col, is_boss_col):
            continue  # Skip incomplete rows
            
        gremlins_value = row[gremlins_col] if gremlins_col < len(row) else ""
        is_boss_value = row[is_boss_col] if is_boss_col < len(row) else ""
        
        # Check if gremlins column contains descriptive text (has spaces) and is_boss has data
        if (isinstance(gremlins_value, str) and 
            ' ' in gremlins_value and 
            is_boss_value and 
            is_boss_value != gremlins_value):
            
            print(f"Row {row_num}: '{gremlins_value}' -> '{is_boss_value}'")
            
            # Prepare update to move is_boss value to gremlins column
            gremlins_cell = f"{chr(65 + gremlins_col)}{row_num}"
            updates.append({
                'range': gremlins_cell,
                'values': [[is_boss_value]]
            })
            cleaned_count += 1
    
    print(f"\nFound {cleaned_count} rows to clean")
    
    if updates and cleaned_count > 0:
        # Auto-apply changes (no confirmation needed in automated environment)
        # Batch update all changes
        body = {
            'valueInputOption': 'RAW',
            'data': updates
        }
        
        result = sheet.values().batchUpdate(
            spreadsheetId=SPREADSHEET_ID,
            body=body
        ).execute()
        
        print(f"✅ Updated {result.get('totalUpdatedCells', 0)} cells in {len(updates)} rows")
    else:
        print("✅ No updates needed - all gremlins columns already have proper mob IDs")

if __name__ == "__main__":
    clean_wave_gremlins()