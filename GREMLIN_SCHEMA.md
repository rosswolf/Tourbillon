# Tourbillon Gremlin Data Schema

## Overview

This document defines the complete data schema for Gremlins in Tourbillon, based on the design specifications in the PRD and Gremlin Bestiary. Gremlins are clockwork parasites that disrupt the player's mechanism through various constraint and disruption effects.

## Core Schema Structure

### Basic Properties

```json
{
  "template_id": "string",           // Unique identifier (e.g., "dust_mite", "spring_snapper")
  "display_name": "string",          // Human-readable name
  "description": "string",           // Flavor text describing the gremlin
  "archetype": "string",             // Combat archetype classification
  "size_category": "string",         // Size tier for balancing
  
  // Core Stats
  "max_health": number,              // HP when gremlin enters combat
  "max_armor": number,               // Damage reduction amount
  "max_shields": number,             // Absorbs damage before HP
  "shield_regen": number,            // Shields restored per tick (if any)
  "shield_regen_max": number,        // Maximum shields from regeneration
  
  // Special Defenses
  "has_barrier": boolean,            // Absorbs one complete hit
  "barrier_count": number,           // Number of barriers (default 1)
  "damage_cap": number,              // Maximum damage per hit (0 = no cap)
  "reflect_percent": number,         // Percentage of damage reflected (0-100)
  "execute_immunity_threshold": number, // Cannot be executed above this HP
  
  // Targeting and Positioning
  "can_be_targeted": boolean,        // Whether direct attacks can target this gremlin
  "target_protection_condition": "string", // Condition for untargetable (e.g., "while_other_gremlins_exist")
  "summon_position": "string",       // Where summoned gremlins appear ("top", "bottom", "random")
  "summon_cap": number,              // Maximum gremlins this can summon (0 = no limit)
  
  // Move System
  "move_cycle": [],                  // Array of move definitions
  "move_timing_type": "string",      // "single", "cycle", "escalating", "conditional"
  "move_starting_index": number      // Which move to start with (default 0)
}
```

### Move Definition Structure

```json
{
  "move_id": "string",               // Unique identifier for this move
  "move_name": "string",             // Display name
  "duration_ticks": number,          // How long this move lasts (0 = until triggered)
  "trigger_interval": number,        // Ticks between triggers (0 = passive)
  "max_triggers": number,            // Maximum times this move can trigger (0 = unlimited)
  
  // Transition Conditions
  "next_move": "string",             // ID of next move (empty = cycle or end)
  "transition_condition": "string",   // When to switch moves
  "transition_value": number,         // Threshold for condition
  
  // Effects
  "passive_effects": [],             // Always active while this move is active
  "trigger_effects": [],             // Effects that happen on trigger_interval
  "on_enter_effects": [],            // Effects when move starts
  "on_exit_effects": []              // Effects when move ends
}
```

### Effect Structure

```json
{
  "effect_type": "string",           // Type of effect (see Effect Types below)
  "targets": "string",               // Who/what this affects
  "value": number,                   // Numeric value (if applicable)
  "force_types": [],                 // Array of force types affected
  "condition": "string",             // Optional condition for effect
  "description": "string"            // Human-readable description
}
```

## Effect Types

### Constraint Effects
- `"force_soft_cap"`: Limits force accumulation with overflow loss
- `"force_hard_cap"`: Absolute limit on force accumulation  
- `"total_forces_cap"`: Caps sum of all forces
- `"card_cost_penalty"`: Increases card time costs
- `"hand_size_limit"`: Reduces maximum hand size
- `"no_card_draw"`: Prevents card drawing

### Disruption Effects
- `"force_drain"`: Removes forces periodically
- `"force_decay"`: Forces lose value over time
- `"force_discard"`: Forces player to discard cards
- `"hand_shuffle"`: Randomizes hand order
- `"complication_destroy"`: Destroys player complications

### Combat Effects
- `"summon_gremlin"`: Creates new gremlin
- `"gain_armor"`: Increases gremlin armor
- `"gain_shields"`: Adds shield points
- `"heal_self"`: Restores HP
- `"enhance_other_gremlins"`: Boosts other gremlin effects

### Meta Effects
- `"phase_transition"`: Changes to different move set
- `"adaptive_counter"`: Responds to player strategy
- `"copy_player_effect"`: Mimics player abilities

## Archetype Classifications

### Primary Archetypes
- `"rush_threat"`: Forces immediate action
- `"turtle_threat"`: High defenses, sustained fight
- `"scaling_threat"`: Gets worse over time  
- `"summoning_threat"`: Creates additional enemies
- `"disruption_threat"`: Makes everything harder
- `"synergy_threat"`: Enhances other gremlins

### Size Categories
- `"gnat"`: 1 HP, swarm units
- `"small"`: 5-15 HP, tutorial enemies
- `"medium"`: 20-40 HP, standard encounters
- `"large"`: 50-80 HP, advanced encounters  
- `"elite"`: 60-120 HP, skill gates
- `"boss"`: 100-200 HP, mastery tests

## Example Gremlin Definitions

### Simple Gremlin (Dust Mite)
```json
{
  "template_id": "dust_mite",
  "display_name": "Dust Mite",
  "description": "A tiny gremlin that causes friction in Heat mechanisms",
  "archetype": "rush_threat",
  "size_category": "small",
  
  "max_health": 8,
  "max_armor": 0,
  "max_shields": 0,
  
  "move_cycle": [{
    "move_id": "heat_disruption", 
    "move_name": "Heat Disruption",
    "duration_ticks": 0,
    "trigger_interval": 0,
    "passive_effects": [{
      "effect_type": "force_soft_cap",
      "targets": "player",
      "value": 4,
      "force_types": ["heat"],
      "description": "Heat soft capped at 4"
    }]
  }]
}
```

### Complex Gremlin (Spring Snapper)
```json
{
  "template_id": "spring_snapper",
  "display_name": "Spring Snapper", 
  "description": "A gremlin that increasingly disrupts Momentum generation",
  "archetype": "scaling_threat",
  "size_category": "medium",
  
  "max_health": 35,
  "max_armor": 1,
  "max_shields": 0,
  
  "move_timing_type": "cycle",
  "move_cycle": [
    {
      "move_id": "drain_phase_1",
      "move_name": "Initial Drain",
      "trigger_interval": 8,
      "max_triggers": 1,
      "trigger_effects": [{
        "effect_type": "force_drain",
        "targets": "player", 
        "value": 2,
        "force_types": ["momentum"],
        "description": "Drain 2 Momentum"
      }],
      "next_move": "drain_phase_2"
    },
    {
      "move_id": "drain_phase_2", 
      "move_name": "Moderate Drain",
      "trigger_interval": 6,
      "max_triggers": 1,
      "trigger_effects": [{
        "effect_type": "force_drain",
        "targets": "player",
        "value": 3, 
        "force_types": ["momentum"],
        "description": "Drain 3 Momentum"
      }],
      "next_move": "drain_phase_3"
    },
    {
      "move_id": "drain_phase_3",
      "move_name": "Heavy Drain", 
      "trigger_interval": 4,
      "max_triggers": 1,
      "trigger_effects": [{
        "effect_type": "force_drain",
        "targets": "player",
        "value": 4,
        "force_types": ["momentum"], 
        "description": "Drain 4 Momentum"
      }],
      "next_move": "drain_phase_1"
    }
  ]
}
```

### Boss Gremlin (The Rust King - Phase 1)
```json
{
  "template_id": "rust_king_phase_1",
  "display_name": "The Rust King",
  "description": "Phase 1: The Spreading Corruption", 
  "archetype": "boss",
  "size_category": "boss",
  
  "max_health": 150,
  "max_armor": 10,
  "max_shields": 0,
  
  "move_timing_type": "cycle",
  "move_cycle": [
    {
      "move_id": "corruption_spread",
      "move_name": "Spreading Corruption",
      "duration_ticks": 10,
      "passive_effects": [{
        "effect_type": "total_forces_cap",
        "targets": "player",
        "value": 15,
        "description": "Total resources hard capped at 15"
      }],
      "next_move": "armor_buildup"
    },
    {
      "move_id": "armor_buildup",
      "move_name": "Armor Buildup", 
      "trigger_interval": 3,
      "max_triggers": 4,
      "trigger_effects": [{
        "effect_type": "enhance_other_gremlins",
        "targets": "all_gremlins",
        "value": 2,
        "description": "All gremlins gain 2 armor"
      }],
      "next_move": "corruption_spread"
    }
  ],
  
  // Phase transition at 0 HP
  "phase_transitions": [{
    "trigger_condition": "health_below",
    "trigger_value": 1,
    "transition_to": "rust_king_phase_2"
  }],
  
  "on_phase_transition": [{
    "effect_type": "summon_gremlin",
    "value": 2,
    "summon_template": "medium_random",
    "description": "Summons 2 medium gremlins"
  }]
}
```

## Schema Validation Rules

1. **Required Fields**: template_id, display_name, max_health, move_cycle
2. **Health Values**: max_health > 0, armor/shields >= 0
3. **Move Cycles**: Must have at least one move
4. **Effect Types**: Must be from approved effect types list
5. **Archetype**: Must match approved archetype classifications
6. **Targeting**: targets field must specify valid target scope

## Migration Notes

The current mob_data.json uses a tower defense schema with range-based behaviors. This new schema focuses on:

1. **Constraint-based disruptions** instead of position-based attacks
2. **Timing-based triggers** instead of range conditions  
3. **Force manipulation** instead of direct damage patterns
4. **Move cycles** instead of static behavior sets
5. **Clockwork theming** instead of fantasy creatures

This schema supports all gremlin types defined in the Gremlin Bestiary and enables the complex encounter waves described in the design documents.