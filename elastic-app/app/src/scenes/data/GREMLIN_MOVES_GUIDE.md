# Gremlin Multi-Move System Guide

## Overview
As of September 2025, gremlins use a multi-move system where each gremlin can have up to 6 independent moves with different timings. This replaced the old single "moves" string system.

## Google Sheets Structure

### Spreadsheet Location
- **URL**: https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/edit
- **Sheet Name**: `mob_data`
- **Spreadsheet ID**: `1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM`

### Column Structure
The sheet has these move-related columns:
- `move_1` - First move effect string
- `move_1_ticks` - Timing for move 1 (in ticks)
- `move_2` - Second move effect string  
- `move_2_ticks` - Timing for move 2
- `move_3` - Third move effect string
- `move_3_ticks` - Timing for move 3
- `move_4` - Fourth move effect string
- `move_4_ticks` - Timing for move 4
- `move_5` - Fifth move effect string
- `move_5_ticks` - Timing for move 5
- `move_6` - Sixth move effect string
- `move_6_ticks` - Timing for move 6

## How to Edit Gremlin Moves

### Step 1: Open the Google Sheet
1. Go to the [mob_data spreadsheet](https://docs.google.com/spreadsheets/d/1TlOn39AXlw0y2tlkE4kvIpvoZ9SpNQTkDGgOptvqSgM/edit)
2. Find the gremlin you want to edit by its `template_id`

### Step 2: Define Moves
For each move slot (1-6), enter:
- **Move effect**: The effect string (e.g., `drain_random=1`)
- **Move ticks**: The timing interval (e.g., `8` for every 8 ticks)

### Step 3: Move Effect Format
Effects use the format: `effect_type=value`

Common effect types:
```
# Resource Caps (limits maximum resources)
heat_soft_cap=4         # Soft cap on Heat
max_resource_hard_cap=3 # Hard cap on all resources

# Resource Drains
drain_random=1          # Drain 1 from random resource
drain_all_types=2       # Drain 2 from all resources
drain_largest=3         # Drain 3 from largest resource
drain_momentum=2        # Drain 2 Momentum specifically

# Card Effects
card_cost_penalty=1     # Cards cost +1 tick to play
force_discard=2         # Force discard 2 cards

# Summons
summon=basic_gnat       # Summon a basic_gnat
summon=dust_mite        # Summon a dust_mite

# Self/Group Buffs
self_gain_armor=2       # Gremlin gains 2 armor
all_gremlins_gain_shields=3  # All gremlins gain 3 shields
```

### Step 4: Timing Rules
- Use `0` for passive effects (always active)
- Use positive numbers for periodic effects (e.g., `8` = every 8 ticks)
- 1 tick = 10 beats in the game engine
- Leave empty if gremlin has fewer than 6 moves

### Step 5: Generate JSON Files
**NEVER edit mob_data.json directly!** Instead:

```bash
# From the project root
cd src/scenes/data
python3 json_exporter.py

# This fetches from Google Sheets and generates all JSON files
```

## Examples

### Gear Tick (Disruption Specialist)
- move_1: `card_cost_penalty=1`, move_1_ticks: `5`
- move_2: `force_discard=1`, move_2_ticks: `10`
- Result: Makes cards cost more every 5 ticks, forces discards every 10 ticks

### Oil Thief (Passive + Active)
- move_1: `max_resource_hard_cap=3`, move_1_ticks: `0` (passive)
- move_2: `drain_largest=2`, move_2_ticks: `15`
- Result: Always caps resources at 3, drains largest resource every 15 ticks

### Spring Snapper (Multi-threat)
- move_1: `drain_momentum=2`, move_1_ticks: `8`
- move_2: `summon=basic_gnat`, move_2_ticks: `12`
- Result: Drains momentum every 8 ticks, spawns gnats every 12 ticks

## Testing Your Changes

1. Edit the Google Sheet
2. Run `python3 json_exporter.py` from `src/scenes/data`
3. Check mob_data.json was updated with your changes
4. Test in game - gremlins should use new move patterns

## Common Mistakes to Avoid

❌ **DON'T** edit mob_data.json directly - changes will be overwritten
❌ **DON'T** use JavaScript/Node.js scripts to modify JSON files
❌ **DON'T** forget to run json_exporter.py after sheet changes
❌ **DON'T** use negative tick values (use 0 for passive)

✅ **DO** always edit the Google Sheet first
✅ **DO** use json_exporter.py to generate JSON files
✅ **DO** test your changes in game
✅ **DO** leave moves empty if not needed (don't fill all 6)

## UI Integration

The gremlin UI (UiGremlinNew) shows:
- Progress bar that fills based on the **next move to trigger**
- Display text showing which move is coming
- Countdown in format "(in X.Y)" where X=ticks, Y=beats
- Different colors for different effect types

## Code Files

Key files for the multi-move system:
- `src/scenes/core/battle/gremlin_move.gd` - GremlinMove class
- `src/scenes/core/entities/gremlin.gd` - Gremlin entity (needs update to use moves array)
- `src/scenes/ui/entities/gremlins/ui_gremlin_new.gd` - UI display
- `src/scenes/data/json_exporter.py` - Generates JSON from sheets

## Future Enhancements

Planned improvements:
- Update Gremlin class to load and process move arrays
- Show multiple progress bars in UI (not just next move)
- Support for conditional moves (e.g., "when HP < 50%")
- Move combinations (multiple effects per move)