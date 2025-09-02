# Tourbillon Starter Deck Design

## Overview

The starter deck contains 12 cards designed to teach core mechanics while providing a balanced, playable experience. Every card serves a specific purpose in demonstrating Tourbillon's fundamental systems.

## Design Principles

1. **Card Draw is Critical** - Multiple redundant draw sources prevent loss from empty hand
2. **Force Diversity** - All 5 force types represented to show variety
3. **Simple Mechanics** - Clear, straightforward effects for new players
4. **Teaching Moments** - Each card demonstrates a key concept
5. **Viable Strategy** - The deck can actually win early encounters

## Deck Composition (12 cards)

### Card Draw Engine (4 cards - 33%)
- **2x Basic Chronometer** - Reliable, consistent draw every 6 ticks
- **1x Quick Calibration** - Momentary burst draw for emergencies
- **1x Steady Draw** - Slower but more efficient draw (2 cards/8 ticks)

**Purpose:** Multiple draw sources ensure sustainable play and teach the importance of card economy.

### Force Generators (5 cards - 42%)
- **1x Heat Spring** - Basic Heat production (aggressive)
- **1x Precision Spring** - Basic Precision production (control)
- **1x Momentum Spring** - Basic Momentum production (scaling)
- **1x Balance Core** - Basic Balance production (defensive)
- **1x Entropy Leak** - Basic Entropy production (sacrifice)

**Purpose:** One of each force type shows variety without overwhelming. All have similar rates (2 forces/3-5 ticks) for easy comparison.

### Damage Dealers (3 cards - 25%)
- **1x Force Converter** - Flexible damage using any force type
- **1x Heat Blast** - Momentary burst damage requiring specific force
- **1x Quick Strike** - Low-cost damage with card draw bonus

**Purpose:** Different damage patterns teach resource conversion and burst vs. sustained damage.

## Key Mechanics Demonstrated

1. **Persistent vs. Momentary** - Gears that stay on board vs. one-time effects
2. **Production vs. Consumption** - Generating resources vs. spending them
3. **Time Management** - Every card costs time, creating strategic decisions
4. **Force Economy** - Balancing generation with consumption
5. **Card Economy** - Drawing cards is not automatic, must be managed

## Features Field

The new `features` field helps categorize cards beyond their gameplay tags:

### Feature Categories
- **starter** - Part of starter deck
- **draw** - Provides card draw
- **generator** - Produces forces without consumption
- **damage** - Deals damage to gremlins
- **converter** - Transforms one resource to another
- **momentary** - One-time effect
- **burst** - High immediate impact
- **consistent** - Reliable, steady effect
- **essential** - Core to deck function
- **flexible** - Multiple uses/options
- **heat/precision/momentum/balance/entropy** - Force type specialization

## Opening Hand Strategy

With 5 cards drawn initially:

**Ideal Opening:**
1. Basic Chronometer (for sustained draw)
2. 1-2 Force generators 
3. Force Converter or damage dealer
4. Flex slot (Quick Calibration or generator)

**Turn 1-3 Priorities:**
1. Play Basic Chronometer first (sustain draw)
2. Establish 1-2 generators
3. Use Momentary cards for immediate needs

## Upgrade Path

After the first few encounters, players should look to:
1. Add more efficient card draw
2. Specialize in 2-3 force types
3. Add synergy cards (tag-based bonuses)
4. Replace basic generators with converters
5. Add keywords (OVERBUILD, IMMOVABLE, etc.)

## Balance Notes

- **Draw Ratio:** 4/12 cards (33%) provide draw - prevents stalling
- **Time Costs:** Range from 1-3 ticks - teaches time management
- **Production Rates:** Standardized at 2 forces per 3-5 ticks - easy to understand
- **Momentary Cards:** 3/12 (25%) - provides flexibility without complexity

## Google Sheets Integration

The starter deck can be managed via Google Sheets with these columns:
- `card_template_id` - Unique identifier
- `features` - Pipe-separated feature tags (starter|draw|essential)
- `starter_copies` - Number of copies in starter deck
- All standard card fields (production, consumption, effects, etc.)

**Sheet ID for Tourbillon Cards:** [To be added to json_exporter.py]

## Testing Considerations

The starter deck should be tested against:
1. **Tutorial Gremlin** (5 HP, no disruptions)
2. **Basic Gremlins** (8-10 HP, minor disruptions)
3. **Card starvation scenarios** (can the deck recover?)
4. **Force variety usage** (are all types useful?)
5. **New player comprehension** (is it learnable?)