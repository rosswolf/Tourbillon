# Tourbillon Card Schema Design

## Overview

In Tourbillon, **every card represents a complication** that can be placed on the mainplate (grid). There are no separate card types like "Plans", "Calibrations", etc. - all cards are complications with different effects.

## Core Schema Fields

### Identity Fields
```json
{
  "card_template_id": "string",        // Unique identifier
  "display_name": "string",             // Card name shown to player
  "rules_text": "string",               // Human-readable card text
  "rarity": "enum",                     // STARTING | COMMON | UNCOMMON | RARE
  "tags": ["string"],                   // Tags for synergies (see Tag System)
  "flavor_text": "string",              // Lore/flavor text (optional)
}
```

### Visual/UI Fields
```json
{
  "card_image_uid": "string",           // Card artwork resource ID
  "cursor_image_uid": "string",         // Cursor when dragging
  "vfx_on_play": "string"              // Visual effect when played (optional)
}
```

### Cost Fields
```json
{
  "time_cost": "number",                // Cost in Ticks to play (1, 2, 3, etc.)
  "force_cost": {                       // Optional additional costs
    "GameResource.Type.HEAT": "number",
    "GameResource.Type.PRECISION": "number",
    "GameResource.Type.MOMENTUM": "number",
    "GameResource.Type.BALANCE": "number",
    "GameResource.Type.ENTROPY": "number"
  }
}
```

### Production Fields
```json
{
  "production_interval": "number",      // Fires every X Ticks
  "force_production": {                  // What it produces when firing
    "GameResource.Type.HEAT": "number",
    "GameResource.Type.PRECISION": "number",
    "GameResource.Type.MOMENTUM": "number",
    "GameResource.Type.BALANCE": "number",
    "GameResource.Type.ENTROPY": "number"
  },
  "force_consumption": {                 // What it needs to consume to produce
    "GameResource.Type.HEAT": "number",
    "GameResource.Type.PRECISION": "number"
  }
}
```

### Effect Fields
```json
{
  "on_play_effect": "string",           // Trigger when played
  "on_fire_effect": "string",           // Trigger when producing (besides force production)
  "on_destroy_effect": "string",        // Trigger when destroyed/replaced
  "on_replaced_effect": "string",       // Trigger when another gear replaces this
  "passive_effect": "string",           // Ongoing effects while on mainplate
  "keywords": ["string"]                // OVERBUILD | MOMENTARY | IMMOVABLE | EPHEMERAL
}
```

### Tag System Fields
From the PRD, tags are critical for synergies:
```json
{
  "tags": ["string"]                    // Can include multiple tags from:
  // Mechanical Identity (opposing pairs):
  // - ORDER | CHAOS
  // - MICRO | TITAN  
  // - FORGE | VOID
  // Thematic Flavor:
  // - CRYSTAL | SHADOW | BEAST | ARCANE | MECH
  // Common:
  // - STONE | SPARK | TOOL | DUST
}
```

## Example Cards (Based on PRD)

### Basic Chronometer (Starter Card)
```json
{
  "card_template_id": "basic_chronometer",
  "display_name": "Basic Chronometer",
  "rules_text": "Fires every 6 Ticks: Draw 1 card",
  "time_cost": 2,
  "production_interval": 6,
  "on_fire_effect": "draw_card=1",
  "tags": ["TOOL", "SPARK"],
  "rarity": "STARTING"
}
```

### Simple Mainspring (Generator)
```json
{
  "card_template_id": "simple_mainspring_heat",
  "display_name": "Simple Mainspring",
  "rules_text": "Fires every 3 Ticks: Produce 2 Heat",
  "time_cost": 3,
  "production_interval": 3,
  "force_production": {
    "GameResource.Type.HEAT": 2
  },
  "tags": ["STONE"],
  "rarity": "STARTING"
}
```

### Force Converter (Converter)
```json
{
  "card_template_id": "force_converter",
  "display_name": "Force Converter",
  "rules_text": "Fires every 4 Ticks: Consume 2 any → 3 damage",
  "time_cost": 3,
  "production_interval": 4,
  "force_consumption": {
    "ANY": 2
  },
  "on_fire_effect": "damage=3",
  "tags": ["FORGE"],
  "rarity": "STARTING"
}
```

### Micro Forge (Example from PRD)
```json
{
  "card_template_id": "micro_forge",
  "display_name": "Micro Forge",
  "rules_text": "Fires every 2 Ticks: Produce 1 Heat. Tool gears cost -0.5 Ticks",
  "time_cost": 2,
  "production_interval": 2,
  "force_production": {
    "GameResource.Type.HEAT": 1
  },
  "passive_effect": "tool_cost_reduction=0.5",
  "tags": ["MICRO", "TOOL"],
  "rarity": "COMMON"
}
```

### Crystal Regulator (Example from PRD)
```json
{
  "card_template_id": "crystal_regulator",
  "display_name": "Crystal Regulator",
  "rules_text": "Fires every 12 Ticks: Produce 5 of any single force. Immovable",
  "time_cost": 8,
  "production_interval": 12,
  "on_fire_effect": "produce_any_single=5",
  "keywords": ["IMMOVABLE"],
  "tags": ["TITAN", "CRYSTAL"],
  "rarity": "RARE"
}
```

### Shadow Mechanism (Example from PRD)
```json
{
  "card_template_id": "shadow_mechanism",
  "display_name": "Shadow Mechanism",
  "rules_text": "Fires every 3 Ticks: Consume 2 Entropy → 2 damage. +1 damage per Beast, +2 if no adjacent gears",
  "time_cost": 4,
  "production_interval": 3,
  "force_consumption": {
    "GameResource.Type.ENTROPY": 2
  },
  "on_fire_effect": "damage=2,damage_per_beast=1,damage_if_isolated=2",
  "tags": ["BEAST", "SHADOW", "CHAOS"],
  "rarity": "UNCOMMON"
}
```

## Effect String Format

Based on existing elastic-app patterns and PRD mechanics:

### Card/Deck Effects
- `draw_card=N` - Draw N cards
- `discard=N` - Discard N cards from hand
- `tutor=TAG` - Search deck for card with TAG
- `mill=N` - Move N cards from deck to discard
- `bounce` - Return to hand instead of discard

### Force Effects
- `produce_[FORCE]=N` - Produce N of specific force
- `consume_[FORCE]=N` - Consume N of specific force
- `produce_any=N` - Produce N of any force
- `produce_any_single=N` - Produce N of one force type
- `convert=[FROM]>[TO]>N` - Convert N forces

### Combat Effects
- `damage=N` - Deal N damage to gremlin
- `damage_all=N` - Deal N damage to all gremlins
- `poison=N` - Apply N poison
- `pierce_damage=N` - Piercing damage
- `execute=N` - Kill gremlin below N HP

### Timing Effects
- `haste=N` - Speed up by N%
- `delay=N` - Add N ticks to timer
- `trigger_adjacent` - Trigger adjacent gears
- `skip_ticks=N` - Remove N ticks from timer

### Conditional Effects
- `damage_per_[TAG]=N` - +N damage per TAG on mainplate
- `damage_if_isolated=N` - +N damage if no adjacent gears
- `produce_per_[TAG]=N` - +N production per TAG

### Cost Modifications
- `[TAG]_cost_reduction=N` - Reduce cost of TAG cards by N

## Keywords (from PRD Section 5)

### Core Keywords
- **OVERBUILD** - When played on another gear, inherit that gear's timer progress
- **MOMENTARY** - Trigger effect when played, then immediately destroy self
- **IMMOVABLE** - Cannot be destroyed by effects (can still be replaced)
- **EPHEMERAL** - When this card would go to discard, exile it instead

### Combat Keywords  
- **PIERCE** - Damage ignores armor
- **POP** - Double damage vs shields
- **BURN** - Gremlin can't heal
- **OVERKILL** - Excess damage carries to next gremlin

### Timing Keywords
- **HASTE** - Gear's timer advances faster
- **STARTING** - Begin with some production already complete

## Migration from Existing Schema

The existing elastic-app schema maps well:

### Keep These Fields
- `card_template_id` → Keep as unique ID
- `display_name` → Keep for card name
- `rules_text` → Keep for card description
- `cursor_image_uid` → Keep for UI
- `card_cost` → Rename to `force_cost` and update types
- `durability_max` → Remove (not in PRD)
- `card_rarity` → Rename to `rarity`

### Transform These
- `instinct_effect` → Split into appropriate trigger effects (on_play, on_fire, etc.)
- `slot_effect` → Transform to production fields + on_fire_effect

### Add These
- `time_cost` - Critical for time system
- `production_interval` - How often gear fires
- `force_production/consumption` - What it produces/needs
- `tags` - Critical for synergies
- `keywords` - For special mechanics

## Validation Rules

1. **Every card must have:**
   - `card_template_id` (unique)
   - `display_name`
   - `time_cost` (1 or greater)
   - `rules_text`

2. **Production cards must have:**
   - `production_interval`
   - Either `force_production` OR `on_fire_effect` (or both)

3. **Converter cards must have:**
   - `force_consumption`
   - Corresponding production or effect

4. **Tag requirements:**
   - Use tags from the defined tag system
   - Typically 1-4 tags per card
   - Tags should match card identity

## Database Considerations

### Primary Structure
- Cards are loaded from JSON (like existing card_data.json)
- Single card type - all are complications
- Effects parsed at runtime

### Indexing
- By `card_template_id` for lookup
- By `tags` for synergy calculations
- By `rarity` for reward generation

## Summary

The card schema for Tourbillon is actually simpler than initially designed because:
1. All cards are complications - no separate types
2. Cards represent single-position gears on the mainplate
3. No complex shapes or connection mechanics
4. Focus is on timing, production, and tag synergies
5. Effects are time-based (every X ticks) not turn-based

This schema maintains compatibility with the existing elastic-app system while adding the time-based mechanics and force system from the Tourbillon PRD.