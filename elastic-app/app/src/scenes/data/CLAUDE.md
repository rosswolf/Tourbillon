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

**The Google Sheets spreadsheets are the SINGLE SOURCE OF TRUTH for all game data.**

**CRITICAL: NEVER manually edit JSON files - they are auto-generated!**

### Card Data
- **Spreadsheet URL**: https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit
- **Sheet Name**: `card_data`
- **Spreadsheet ID**: `1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk`

### Mob/Gremlin Data
- **Spreadsheet URL**: https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/edit
- **Sheet Name**: `mob_data`
- **Spreadsheet ID**: `1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM`
- **Multi-Move System**: Uses `move_1` through `move_6` columns with corresponding `move_X_ticks` for timing

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

## How to Update Game Data

### IMPORTANT: Manual Spreadsheet Editing Required

**Claude cannot directly update Google Sheets via API.** You must:

1. **Open the Google Sheets URL directly in your browser**
2. **Manually edit the spreadsheet cells**
3. **Then sync changes back to JSON**

### Spreadsheet URLs for Manual Editing:
- **Mob Data**: https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/edit
- **Card Data**: https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit

### Quick Reference Commands

```bash
# STEP 1: MANUALLY EDIT THE GOOGLE SHEETS (Claude cannot do this)
# Open the URLs above and make your changes

# STEP 2: After manual edits, sync from sheets to JSON:
cd src/scenes/data
python3 json_exporter.py

# This will:
# 1. Fetch latest from all Google Sheets
# 2. Generate all JSON files (card_data.json, mob_data.json, etc.)
# 3. Apply proper formatting and conversions

# DO NOT:
# - Edit JSON files manually
# - Use JavaScript to update JSON files
# - Modify mob_data.json directly
# - Attempt to update Google Sheets via API (not supported)

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

## Gremlin Multi-Move System

As of September 2025, gremlins use a multi-move system:
- Each gremlin can have up to 6 independent moves
- Each move has its own timing (in ticks)
- Moves are defined in columns `move_1` through `move_6`
- Timing is in columns `move_1_ticks` through `move_6_ticks`
- Use `0` ticks for passive/always-on effects
- Effects use format: `effect_type=value` (e.g., `drain_random=1`)

Example:
- move_1: `card_cost_penalty=1`, move_1_ticks: `5`
- move_2: `force_discard=1`, move_2_ticks: `10`

This allows gremlins to have multiple independent abilities with different timings.