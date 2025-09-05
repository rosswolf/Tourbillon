# Manual Spreadsheet Update Instructions

## Google Sheets URL
https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/edit

## Updates to Add

### Row 2: Basic Gnat
- **Move 2**: `attack=1`
- **Move 2 Ticks**: `3`

### Row 3: Barrier Gnat  
- **Move 1**: `attack=2`
- **Move 1 Ticks**: `5`

### Row 4: Dust Mite
- **Move 2**: `attack=2`
- **Move 2 Ticks**: `4`

### Row 5: Drain Gnat
- **Move 2**: `attack=1`
- **Move 2 Ticks**: `5`

### Row 6: Constricting Barrier Gnat
- **Move 2**: `attack=3`
- **Move 2 Ticks**: `8`

### Row 7: Breeding Gnat
- No attack (pure summoner)

### Row 8: Gear Tick
- **Move 3**: `attack=2`
- **Move 3 Ticks**: `15`

### Row 9: Rust Speck
- **Move 2**: `attack=3`
- **Move 2 Ticks**: `6`

### Row 10: Spring Snapper
- **Move 3**: `attack=4`
- **Move 3 Ticks**: `10`

### Row 11: Oil Thief
- **Move 3**: `attack=3`
- **Move 3 Ticks**: `5`
- **Move 4**: `attack=5`
- **Move 4 Ticks**: `20`

### Row 12: Chaos Imp
- **Move 2**: `attack=2`
- **Move 2 Ticks**: `7`

### Row 13: Gnat Spawner
- No attack (pure summoner)

### Row 14: Gear Grinder
- **Move 3**: `attack=4`
- **Move 3 Ticks**: `6`
- **Move 4**: `attack=6`
- **Move 4 Ticks**: `18`

### Row 15: Time Nibbler
- **Move 3**: `attack=3`
- **Move 3 Ticks**: `10`

### Row 16: Echo Chamber
- **Move 2**: `attack=2`
- **Move 2 Ticks**: `9`

### Row 17: Constraint Engine
- **Move 2**: `attack=5`
- **Move 2 Ticks**: `10`

### Row 18: Temporal Glutton
- No attack (summoner boss)

### Row 19: Clog Beast
- **Move 2**: `attack=7`
- **Move 2 Ticks**: `12`

### Row 20: Gear Knight
- **Move 2**: `attack=4`
- **Move 2 Ticks**: `5`
- **Move 3**: `attack=6`
- **Move 3 Ticks**: `10`

## After Updating Spreadsheet

Run the sync command from the data directory:
```bash
cd elastic-app/app/src/scenes/data
python3 json_exporter.py
```