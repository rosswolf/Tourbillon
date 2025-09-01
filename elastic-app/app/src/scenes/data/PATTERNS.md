# Data Patterns and Parsing Guide

## Google Sheets Integration

### Reading Card Data from Google Sheets

To fetch the latest card data from Google Sheets and convert it for use in the game:

```javascript
// Node.js script to fetch and convert card data
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');

async function fetchCardData() {
    // Setup authentication
    const auth = new google.auth.GoogleAuth({
        keyFile: path.join(process.env.HOME, 'Code/google-sheets-mcp/service-account-key.json'),
        scopes: ['https://www.googleapis.com/auth/spreadsheets'],
    });
    
    const sheets = google.sheets({ version: 'v4', auth: await auth.getClient() });
    
    // Fetch data
    const res = await sheets.spreadsheets.values.get({
        spreadsheetId: '1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk',
        range: 'card_data!A2:F1000', // Skip header row
    });
    
    const rows = res.data.values || [];
    const cards = rows.map(row => ({
        template_id: row[0],
        time_cost: parseInt(row[1]) || row[1], // Handle special costs like "???"
        display_name: row[2],
        tags: row[3] ? row[3].split(',').map(t => t.trim()) : [],
        rules_text: row[4],
        notes: row[5]
    }));
    
    return cards;
}
```

## Python JSON Exporter (`json_exporter.py`)

The `json_exporter.py` script converts between Google Sheets data and the game's JSON format.

### Key Functions

#### `export_cards(cards_data)`
Converts card data from sheets format to game JSON:
- Parses time costs (handles fractional and special values)
- Splits tags into arrays
- Generates unique IDs
- Creates force type mappings

#### `import_cards(json_file)`
Reads existing card_data.json and can merge with sheet data

### Usage with Google Sheets Data

```python
import json
from json_exporter import export_cards

# After fetching from Google Sheets (via Node.js script)
with open('sheets_data.json', 'r') as f:
    sheets_cards = json.load(f)

# Convert to game format
game_cards = export_cards(sheets_cards)

# Write to card_data.json
with open('card_data.json', 'w') as f:
    json.dump(game_cards, f, indent=2)
```

## Data Flow

1. **Google Sheets** (Master source)
   - Edit cards in spreadsheet
   - Maintain version control through sheet history

2. **Fetch Script** (Node.js)
   - Authenticate with service account
   - Pull latest data from sheets
   - Save as intermediate JSON

3. **Python Exporter** (`json_exporter.py`)
   - Parse intermediate JSON
   - Apply game-specific transformations
   - Generate card_data.json

4. **Godot Game** (`static_data.gd`)
   - Load card_data.json at runtime
   - Parse into game objects
   - Use in gameplay

## File Format Mappings

### Google Sheets → JSON
| Sheet Column | JSON Field | Transform |
|-------------|------------|-----------|
| card_template_id | id | Direct copy |
| time_cost | cost | Parse to int/float |
| display_name | name | Direct copy |
| tags | tags | Split by comma |
| rules_text | description | Direct copy |
| notes | category | Direct copy |

### JSON → Godot
The `static_data.gd` file loads JSON and creates card resources:
- Validates required fields
- Applies default values
- Creates Card objects
- Registers with game systems

## Syncing Process

To update game with latest Google Sheets data:

```bash
# 1. Fetch from sheets (run from data folder)
node fetch_sheets.cjs

# 2. Convert to game format
python3 json_exporter.py --input sheets_data.json --output card_data.json

# 3. Game automatically loads new data on next run
```

## Important Notes

- **Authentication**: Service account must have Editor access to sheet
- **Rate Limits**: Google Sheets API has quotas (500 requests per 100 seconds)
- **Validation**: Always validate data before importing to game
- **Backup**: Keep backups of card_data.json before overwriting
- **Testing**: Test with small batches before full import