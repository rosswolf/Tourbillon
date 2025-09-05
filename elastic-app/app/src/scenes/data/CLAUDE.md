# Data Directory Context for Claude

## CRITICAL: Read These Documents First

Before making ANY changes to data files or working with game data, you MUST read:

1. **GOOGLE_SHEETS.md** - Contains:
   - Google Sheets spreadsheet ID and URL
   - Authentication details and service account info  
   - Sheet structure and column mappings
   - How to access the master card database

2. **PATTERNS.md** - Contains:
   - Complete data flow from Google Sheets → Game
   - Code examples for fetching and converting data
   - JSON format mappings and transformations
   - Sync process and automation scripts

## Master Data Source

**The Google Sheets spreadsheet is the SINGLE SOURCE OF TRUTH for card data.**

- **Spreadsheet URL**: https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit
- **Sheet Name**: `card_data`
- **Spreadsheet ID**: `1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk`

## Data Files in This Directory

### Source Files (from Google Sheets)
- **card_data.json** - Generated from Google Sheets, contains all card definitions
- **mob_data.json** - Gremlin/mob definitions  
- **wave_data.json** - Wave and encounter definitions
- **goals_data.json** - Goal/objective definitions
- **configuration_data.json** - Game configuration parameters

### Processing Scripts
- **json_exporter.py** - Converts between Google Sheets format and game JSON format
- **static_data.gd** - Godot script that loads and parses JSON at runtime
- **move_parser.gd** - Parses move strings for gremlins and effects

## Important Notes for ASCII Conversion

When working with the spreadsheet data:

1. **Check for Non-ASCII Characters** in:
   - Card names (display_name)
   - Rules text
   - Tags
   - Effect descriptions

2. **Common Non-ASCII Issues**:
   - Smart quotes: " " ' ' → Convert to: " " ' '
   - Em/en dashes: — – → Convert to: - or --
   - Ellipsis: … → Convert to: ...
   - Arrows: → ← ↑ ↓ → Convert to: ->, <-, ^, v
   - Special symbols: × ÷ ± → Convert to: x, /, +/-
   - Accented characters: é à ñ → Convert to plain ASCII equivalents

3. **Update Process**:
   - Always update the Google Sheets FIRST
   - Then re-export to JSON using the sync process
   - Never modify JSON files directly (they get overwritten)

## Authentication for Google Sheets

Service Account Details (from GOOGLE_SHEETS.md):
- **Account**: `claude-sheets-mcp@wnann-dev.iam.gserviceaccount.com`
- **Key File**: `~/Code/google-sheets-mcp/service-account-key.json`
- **Access**: Editor (read/write)

## Quick Reference Commands

```bash
# Fetch latest from Google Sheets
node fetch_sheets.cjs

# Convert to game format
python3 json_exporter.py --input sheets_data.json --output card_data.json

# Check for non-ASCII characters
grep -P '[^\x00-\x7F]' card_data.json
```

## Data Flow Summary

```
Google Sheets (Master) 
    ↓ (fetch via API)
Intermediate JSON
    ↓ (json_exporter.py)
card_data.json
    ↓ (static_data.gd)
Game Objects
```

## Before Making Changes

1. Check GOOGLE_SHEETS.md for spreadsheet location
2. Check PATTERNS.md for data conversion process
3. Make edits in Google Sheets, not JSON files
4. Use proper sync process to update game data
5. Test changes in game after sync

Remember: The spreadsheet is the source of truth. All JSON files are generated and will be overwritten on next sync.