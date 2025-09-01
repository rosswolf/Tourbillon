# Google Sheets Data Sources

## Tourbillon Card Data Sheet

**Spreadsheet ID**: `1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk`
**Sheet Name**: `card_data`
**URL**: https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit

### Authentication
- **Service Account**: `claude-sheets-mcp@wnann-dev.iam.gserviceaccount.com`
- **Key File Location**: `~/Code/google-sheets-mcp/service-account-key.json`
- **Access Level**: Editor (can read and write)

### Sheet Structure
| Column | Field | Description |
|--------|-------|-------------|
| A | card_template_id | Unique identifier for the card |
| B | time_cost | Cost in Ticks to play the card |
| C | display_name | Card name shown to players |
| D | tags | Comma-separated tags for synergies |
| E | rules_text | Full mechanical description |
| F | notes | One-word archetype/category |

### Current Contents
- **Total Cards**: ~584
- **Categories**: Force generators, converters, damage dealers, synergy cards, wild mechanics
- **Last Updated**: September 1, 2025

### Usage
This sheet contains the master card database for Tourbillon. Cards are designed following the PRD mechanics where:
- Time only advances when cards are played
- Cards become "complications" (gears) on the mainplate
- Complications produce forces on timed intervals
- Players fight gremlins while building their clockwork engine