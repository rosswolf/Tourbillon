#!/usr/bin/env python3
"""
Add new waves - Batch 1: Easy waves (difficulty 1-25)
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

def add_easy_waves():
    service = get_sheets_service()
    sheet = service.spreadsheets()
    
    # Easy waves (difficulty 1-25)
    new_waves = [
        ['wave_4a', 'Single Scout', 1, 1, 'Trivial', 'Tutorial', 'Learn basic combat', 'basic_gnat'],
        ['wave_4b', 'Lone Mite', 1, 8, 'Trivial', 'Rush Threat', 'Introduction to rush enemies', 'dust_mite'],
        ['wave_4c', 'Barrier Test', 1, 2, 'Trivial', 'Defense Tutorial', 'Learn about barriers', 'barrier_gnat|barrier_gnat'],
        ['wave_4d', 'Sparks Fly', 1, 10, 'Easy', 'Damage Tutorial', 'Introduction to spark damage', 'spark_flea'],
        ['wave_4e', 'Precision Strike', 1, 14, 'Easy', 'Precision Tutorial', 'Learn precision mechanics', 'precision_mite'],
        ['wave_4f', 'Double Gnats', 1, 2, 'Trivial', 'Swarm Intro', 'Multiple weak enemies', 'basic_gnat|basic_gnat'],
        ['wave_5a', 'Tick Tock', 1, 13, 'Easy', 'Mixed Threat', 'Combination of enemy types', 'gear_tick|basic_gnat'],
        ['wave_5b', 'Double Dust', 1, 16, 'Easy', 'Rush Swarm', 'Multiple rush enemies', 'dust_mite|dust_mite'],
        ['wave_5c', 'Siphon Intro', 1, 17, 'Easy', 'Drain Threat', 'Introduction to resource drain', 'siphon_tick'],
        ['wave_5d', 'Mixed Pests', 1, 17, 'Easy', 'Varied Threat', 'Different enemy types', 'rust_speck|dust_mite'],
        ['wave_5e', 'Gnat Swarm', 1, 5, 'Trivial', 'Pure Swarm', 'Many weak enemies', 'basic_gnat|basic_gnat|basic_gnat|basic_gnat|basic_gnat'],
        ['wave_5f', 'Spark and Dust', 1, 18, 'Easy', 'Damage Rush', 'Fast damage dealing', 'spark_flea|dust_mite']
    ]
    
    # Append to spreadsheet
    body = {'values': new_waves}
    
    result = sheet.values().append(
        spreadsheetId=SPREADSHEET_ID,
        range='Sheet1!A:H',
        valueInputOption='RAW',
        body=body
    ).execute()
    
    print(f"Added {len(new_waves)} easy waves")

if __name__ == "__main__":
    add_easy_waves()