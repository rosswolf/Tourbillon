# Tourbillon Card Schema Design

## Overview

In Tourbillon, **every card represents a gear** that can be placed on the mainplate (grid). Cards become gears when played, producing and consuming forces at regular intervals. This document defines the data schema for cards that works within the existing StaticData system constraints.

## Schema Constraints & Capabilities

The existing StaticData system provides:
- **JSON Structure**: Array of objects, first field becomes the key in nested dictionary
- **Enum Resolution**: Supports `"Class.Enum.VALUE"` format (auto-resolved)
- **Dictionary Fields**: Can use nested objects for complex data
- **Array Support**: Pipe-separated values (`|`) in spreadsheet cells become arrays
- **Params Field**: Special field that expands key:value pairs to top-level properties
- **Config References**: `__CONFIG_REF__key` pulls from configuration_data.json
- **Column Prefixes**: Headers can include enum prefixes with `:` syntax

## Core Schema Fields

### Identity Fields
```json
{
  "card_template_id": "string",        // Unique identifier (MUST be first field)
  "group_template_id": "string",       // Group/set identifier
  "display_name": "string",            // Card name shown to player
  "rules_text": "string",              // Human-readable card text
  "card_rarity": "enum",               // Card.RarityType.COMMON, etc.
  "card_count": "number"               // How many copies in starting pool
}
```

### Visual/UI Fields
```json
{
  "card_image_uid": "string",          // Card artwork resource ID
  "cursor_image_uid": "string",        // Cursor when dragging
  "vfx_on_play": "string",            // Visual effect ID when played (optional)
  "vfx_on_fire": "string"             // Visual effect ID when producing (optional)
}
```

### Time & Production Fields
```json
{
  "time_cost": "number",                // Cost in Ticks to play (1, 2, 3, etc.)
  "production_interval": "number",      // Fires every X Ticks
  "starting_progress": "number"         // Initial timer progress in Beats (0-interval*10)
}
```

### Force Fields
```json
{
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
  },
  "force_cost": {                       // Additional cost to play (beyond time)
    "GameResource.Type.HEAT": "number"
  }
}
```

### Tag & Keyword Fields
```json
{
  "tags": ["string"],                   // Tags for synergies
  "keywords": ["string"]                // Special mechanics
}
```

### Effect Trigger Fields
```json
{
  "on_play_effect": "string",           // When played from hand
  "on_place_effect": "string",          // When placed on mainplate
  "on_fire_effect": "string",           // When producing (besides force production)
  "on_ready_effect": "string",          // When entering ready state
  "on_replace_effect": "string",        // When another gear replaces this
  "on_destroy_effect": "string",        // When destroyed/removed
  "on_discard_effect": "string",        // When discarded from hand
  "on_draw_effect": "string",           // When drawn from deck
  "on_exhaust_effect": "string",        // When deck exhausted (reshuffle)
  "passive_effect": "string",           // Ongoing effect while on mainplate
  "conditional_effect": "string"        // Effect with conditions (e.g., "if 3+ MICRO")
}
```

### Legacy Compatibility Fields
```json
{
  "instinct_effect": "string",          // Keep for backward compatibility
  "slot_effect": "string",               // Keep for backward compatibility
  "durability_max": "number",           // Keep but unused in Tourbillon
  "card_cost": {}                       // Keep but replaced by force_cost
}
```

## Tag System Reference

### Mechanical Identity (Opposing Pairs)
- **ORDER** vs **CHAOS** - Pattern vs isolation
- **MICRO** vs **TITAN** - Fast/weak vs slow/powerful
- **FORGE** vs **VOID** - Creation vs destruction

### Thematic Flavor
- **CRYSTAL** - Pristine, geometric, focusing
- **SHADOW** - Dark, hidden, elusive
- **BEAST** - Wild, living, pack-minded
- **ARCANE** - Magical, mystical, complex
- **MECH** - Mechanical, futuristic, automated

### Common Tags
- **STONE** - Solid, permanent, foundational
- **SPARK** - Energy, activation, catalyst
- **TOOL** - Implements, equipment, utility
- **DUST** - Remnants, particles, ephemeral

## Keyword System

### Core Keywords
- **OVERBUILD** - Inherit timer progress from replaced gear
- **MOMENTARY** - Trigger effect then immediately destroy self
- **IMMOVABLE** - Cannot be destroyed by effects (can be replaced)
- **EPHEMERAL** - Exile instead of discard when leaving play
- **STEADY** - Production interval cannot be modified

### Combat Keywords
- **PIERCE** - Damage ignores armor
- **POP** - Double damage vs shields
- **POISON X** - Apply X poison stacks
- **BURN X** - Prevent healing for X Ticks
- **EXECUTE X** - Instantly kill gremlin below X HP
- **OVERKILL** - Excess damage carries to next gremlin

### Timing Keywords
- **HASTE X** - Timer advances X% faster
- **SLOW X** - Timer advances X% slower
- **QUICKSTART** - Start with 50% timer progress
- **PATIENT** - Double production when at max timer

## Effect String Format

Effects use a simple key=value syntax, with multiple effects separated by commas:

```
"effect_name=value, other_effect=value2, conditional:condition=value"
```

### Basic Effect Examples
- `draw_card=2` - Draw 2 cards
- `damage=5` - Deal 5 damage to topmost gremlin
- `damage_all=3` - Deal 3 damage to all gremlins
- `add_heat=2` - Add 2 Heat force
- `consume_max=3` - Consume 3 from the highest available forces
- `shield_self=2` - Add 2 shields to hero
- `poison=3` - Apply 3 poison stacks
- `heal=2` - Heal 2 HP

### Conditional Effects
- `if_tag:MICRO=3,damage=7` - If 3+ MICRO gears, deal 7 damage
- `per_tag:BEAST,damage=2` - Deal 2 damage per BEAST gear
- `if_force:HEAT>5,draw_card=1` - If Heat > 5, draw 1 card

### Target Modifiers
- `damage_weakest=5` - Target weakest gremlin
- `damage_strongest=5` - Target strongest gremlin
- `damage_random=5` - Target random gremlin
- `damage_bottom=5` - Target bottommost gremlin

### Cost Modifiers
- `tool_cost_reduction=0.5` - TOOL gears cost 0.5 less Ticks
- `micro_interval_reduction=1` - MICRO gears fire 1 Tick faster
- `next_card_cost=0` - Next card costs 0 Ticks

## Example Cards

### Basic Generator
```json
{
  "card_template_id": "simple_mainspring",
  "group_template_id": "starter",
  "display_name": "Simple Mainspring",
  "rules_text": "Every 3 Ticks: Produce 2 Heat",
  "time_cost": 3,
  "production_interval": 3,
  "force_production": {
    "GameResource.Type.HEAT": 2
  },
  "force_consumption": {},
  "tags": ["STONE"],
  "keywords": [],
  "card_rarity": "Card.RarityType.STARTING"
}
```

### Converter Gear
```json
{
  "card_template_id": "precision_converter",
  "group_template_id": "common",
  "display_name": "Precision Converter",
  "rules_text": "Every 4 Ticks: Consume 3 Heat → Produce 2 Precision",
  "time_cost": 3,
  "production_interval": 4,
  "force_production": {
    "GameResource.Type.PRECISION": 2
  },
  "force_consumption": {
    "GameResource.Type.HEAT": 3
  },
  "tags": ["FORGE", "TOOL"],
  "keywords": [],
  "card_rarity": "Card.RarityType.COMMON"
}
```

### Synergy Gear
```json
{
  "card_template_id": "micro_forge",
  "group_template_id": "uncommon",
  "display_name": "Micro Forge",
  "rules_text": "Every 2 Ticks: Produce 1 Heat. Tool gears cost -0.5 Ticks",
  "time_cost": 2,
  "production_interval": 2,
  "force_production": {
    "GameResource.Type.HEAT": 1
  },
  "tags": ["MICRO", "TOOL", "FORGE"],
  "keywords": ["OVERBUILD"],
  "on_fire_effect": "tool_cost_reduction=0.5",
  "passive_effect": "tool_cost_reduction=0.5",
  "card_rarity": "Card.RarityType.UNCOMMON"
}
```

### Combat Gear
```json
{
  "card_template_id": "shadow_striker",
  "group_template_id": "rare",
  "display_name": "Shadow Striker",
  "rules_text": "Every 3 Ticks: Consume 2 Entropy → 5 damage, apply 2 poison",
  "time_cost": 4,
  "production_interval": 3,
  "force_consumption": {
    "GameResource.Type.ENTROPY": 2
  },
  "tags": ["SHADOW", "VOID"],
  "keywords": ["PIERCE"],
  "on_fire_effect": "damage=5, poison=2",
  "card_rarity": "Card.RarityType.RARE"
}
```

## Spreadsheet Format

For Google Sheets data entry, the columns would be:

| card_template_id | display_name | rules_text | time_cost | production_interval | tags | keywords | force_production | force_consumption | on_fire_effect | card_rarity:Card.RarityType |
|-----------------|--------------|------------|-----------|-------------------|------|----------|-----------------|------------------|----------------|----------------------------|
| micro_forge | Micro Forge | Every 2 Ticks: Produce 1 Heat | 2 | 2 | MICRO\|TOOL\|FORGE | OVERBUILD | {"GameResource.Type.HEAT": 1} | {} | tool_cost_reduction=0.5 | UNCOMMON |

## Integration with Code

### Loading Cards
```gdscript
static func load_card_from_template(template_id: String) -> Card:
    var data = StaticData.card_data.get(template_id, {})
    if data.is_empty():
        return null
    
    var card = Card.new()
    card.template_id = template_id
    card.display_name = data.get("display_name", "")
    card.rules_text = data.get("rules_text", "")
    card.time_cost = data.get("time_cost", 2)
    card.production_interval = data.get("production_interval", 3)
    card.force_production = data.get("force_production", {})
    card.force_consumption = data.get("force_consumption", {})
    card.tags = data.get("tags", [])
    card.keywords = data.get("keywords", [])
    
    # Load effect strings
    card.on_play_effect = data.get("on_play_effect", "")
    card.on_fire_effect = data.get("on_fire_effect", "")
    card.on_destroy_effect = data.get("on_destroy_effect", "")
    # ... etc
    
    return card
```

## Notes

- **Force Types**: All force references use the enum format (e.g., `GameResource.Type.HEAT`)
- **Time Values**: All time values are in Ticks (whole numbers for base cards)
- **Effect Strings**: Use simple key=value syntax for effects
- **Arrays in Sheets**: Use pipe separator (`|`) for multiple values in spreadsheet cells
- **Empty Objects**: Use `{}` for empty force_consumption/production in JSON
- **Enum Prefixes**: Column headers can specify enum prefix with `:` (e.g., `card_rarity:Card.RarityType`)

This schema is designed to work seamlessly with the existing StaticData system while providing all the flexibility needed for Tourbillon's gameplay mechanics.