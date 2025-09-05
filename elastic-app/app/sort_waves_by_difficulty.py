#!/usr/bin/env python3
"""
Sort waves in spreadsheet by difficulty value
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

def sort_waves_by_difficulty():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Get all data
    result = sheet.values().get(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H'
    ).execute()
    
    values = result.get('values', [])
    if not values:
        print("No data found")
        return
    
    headers = values[0]
    data_rows = values[1:]
    
    # Find difficulty column
    difficulty_col = headers.index('difficulty') if 'difficulty' in headers else 3
    
    # Sort data rows by difficulty (convert to int for proper sorting)
    sorted_rows = sorted(data_rows, key=lambda row: int(row[difficulty_col]) if len(row) > difficulty_col and row[difficulty_col].isdigit() else 0)
    
    # Rebuild the full data
    all_data = [headers] + sorted_rows
    
    # Clear and rewrite entire sheet
    # First clear
    sheet.values().clear(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H'
    ).execute()
    
    # Then write sorted data
    body = {'values': all_data}
    
    result = sheet.values().update(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Sorted {len(sorted_rows)} waves by difficulty")
    print("Difficulty range:", 
          int(sorted_rows[0][difficulty_col]) if sorted_rows and len(sorted_rows[0]) > difficulty_col else 0,
          "to",
          int(sorted_rows[-1][difficulty_col]) if sorted_rows and len(sorted_rows[-1]) > difficulty_col else 0)

if __name__ == "__main__":
    sort_waves_by_difficulty()