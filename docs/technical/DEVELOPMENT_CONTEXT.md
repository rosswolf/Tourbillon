# Tourbillon Development Context

## Repository Overview

**Repository:** https://github.com/rosswolf/Tourbillon  
**Base Codebase:** Elastic-app (roguelike card game)  
**Reusability:** ~70% of elastic-app code can be adapted  

### Directory Structure
```
/home/rosswolf/Code/Tourbillon/
├── elastic-app/app/              # Base game codebase to adapt
│   ├── src/scenes/
│   │   ├── core/                # Game logic
│   │   │   ├── entities/        # Cards, heroes, etc.
│   │   │   ├── resources/       # Force system (modified)
│   │   │   └── effects/         # Card effects
│   │   ├── ui/                  # UI components
│   │   └── data/                # JSON data files
│   └── project.godot            # Godot project file
├── docs/
│   ├── TOURBILLON_PRD.md        # Complete game design (782 lines)
│   ├── CARD_SCHEMA_DESIGN.md    # Card JSON structure (311 lines)
│   ├── CODEBASE_REUSABILITY_ANALYSIS.md # What to reuse (241 lines)
│   └── DEVELOPMENT_CONTEXT.md    # This document
└── .github/workflows/            # Claude AI GitHub integration
```

## Current Implementation Status

### ✅ Completed
1. **Force System Resources**
   - Added 6 force types to replace 3-color system
   - Files modified:
     - `air.gd` - Added force colors and enums
     - `game_resource.gd` - Added force resource types
     - `hero.gd` - Added force properties as CappedResources
     - `cost.gd` - Updated cost checking for new forces

2. **Documentation**
   - Full PRD with game mechanics
   - Card schema design
   - Codebase reusability analysis

3. **GitHub Integration**
   - Claude AI responds to issues/comments
   - Session persistence for <60 second responses

### 🔄 In Progress
- Converting from turn-based to time-based system
- Adapting battleground to mainplate grid

### ❌ Not Started
- Gremlin enemy system
- Tag synergy implementation
- Beat/Tick time system
- Complication production intervals

## Core Game Concepts

### Time System
- **Beat:** 0.1 of a Tick (smallest unit)
- **Tick:** Standard time unit (what players see)
- **Key Rule:** Time ONLY advances when cards are played
- **Production:** Complications fire every X Ticks
- **Processing:** Game checks every Beat for precision

### Mainplate (Grid)
- **Starting Size:** 4x4 grid
- **Expandable:** Up to 4 expansions (max 8x4, 6x6, etc.)
- **Placement:** Each position holds ONE complication
- **Replacement:** Can play on top of existing gears
- **Escapement Order:** Top-to-bottom, left-to-right evaluation

### Cards = Complications
- **Single Type:** All cards are complications (no separate types)
- **Placement:** Cards become gears on the mainplate
- **Production:** Each has interval (e.g., "Every 3 Ticks: Produce 2 Heat")
- **Consumption:** Some require forces to produce
- **Ready State:** Complications wait when lacking required forces

### Force System
| Force | Color | Theme | Focus |
|-------|-------|-------|-------|
| **Heat** | Red | Friction/Combustion | Direct damage, fast intervals |
| **Precision** | Blue | Control/Accuracy | Card draw, time manipulation |
| **Momentum** | Green | Perpetual Motion | Scaling, ramping effects |
| **Balance** | White | Regulation/Stability | Shields, consistent production |
| **Entropy** | Purple | Decay/Unwinding | High risk/reward, destruction |
| **Inspiration** | Gold | Creative Energy | Per-run currency for upgrades |

### Tag System
**Mechanical Identity (Opposing Pairs):**
- ORDER vs CHAOS - Pattern vs isolation
- MICRO vs TITAN - Fast/weak vs slow/powerful
- FORGE vs VOID - Creation vs destruction

**Thematic Flavor:**
- CRYSTAL, SHADOW, BEAST, ARCANE, MECH

**Common Tags:**
- STONE, SPARK, TOOL, DUST

### Combat System
- **Gremlins:** 1-4 enemies per combat
- **Disruptions:** Force caps, taxes, restrictions
- **Victory:** Defeat all gremlins before running out of cards
- **Loss Conditions:** 
  - Empty hand after card resolution
  - Can't draw when required (deck + discard empty)

## Card Schema Structure

```json
{
  "card_template_id": "micro_forge",
  "display_name": "Micro Forge",
  "rules_text": "Fires every 2 Ticks: Produce 1 Heat. Tool gears cost -0.5 Ticks",
  "time_cost": 2,                    // Ticks to play this card
  "production_interval": 2,          // Fires every 2 Ticks
  "force_production": {
    "GameResource.Type.HEAT": 1      // Produces 1 Heat
  },
  "force_consumption": {},            // What it needs (empty = generator)
  "tags": ["MICRO", "TOOL"],        // For synergies
  "rarity": "COMMON",
  "on_fire_effect": "tool_cost_reduction=0.5",  // Additional effects
  "keywords": ["OVERBUILD"]          // Special mechanics
}
```

## Development Roadmap

### Phase 1: Time System Foundation
- [ ] Implement Beat/Tick time advancement
- [ ] Replace turn-based logic with time-based
- [ ] Add production intervals to complications
- [ ] Create ready state mechanics

### Phase 2: Mainplate Grid
- [ ] Adapt battleground to 4x4 mainplate
- [ ] Implement Escapement Order evaluation
- [ ] Add position bonuses
- [ ] Enable mainplate expansion

### Phase 3: Card → Complication Conversion
- [ ] Add `time_cost` to all cards
- [ ] Add `production_interval` fields
- [ ] Convert effects to time-based triggers
- [ ] Implement force production/consumption

### Phase 4: Tag Synergy System
- [ ] Implement tag counting
- [ ] Add conditional effects based on tags
- [ ] Create tag-based cost reductions
- [ ] Build synergy combinations

### Phase 5: Gremlin Combat
- [ ] Create Gremlin entity class
- [ ] Implement disruption mechanics
- [ ] Add HP and damage systems
- [ ] Build gremlin AI patterns

### Phase 6: Meta Systems
- [ ] Inspiration currency
- [ ] Workshop upgrades
- [ ] Run progression structure
- [ ] The Wheel narrative framework

## Technical Implementation Notes

### Reusable from Elastic
- **Entity System:** Builder pattern, instance tracking
- **Card Infrastructure:** Hand management, deck cycling
- **UI Components:** Card display, resource meters
- **Data System:** JSON loading, static data management
- **Signal System:** Event bus architecture

### Needs Modification
- **Turn System → Time System:** Major rewrite needed
- **Resources:** Extended from 3 to 6 forces (completed)
- **Card Effects:** Convert to time-based production
- **Grid:** Adapt battleground for complications

### New Development Required
- **Gremlin System:** Completely new
- **Tag Synergies:** New mechanic
- **Beat/Tick Processing:** New time resolution
- **Ready States:** New complication behavior
- **Escapement Order:** New evaluation system

## Key Files to Reference

### Documentation
- `/docs/TOURBILLON_PRD.md` - Complete game design specification
- `/docs/CARD_SCHEMA_DESIGN.md` - Card data structure and examples
- `/docs/CODEBASE_REUSABILITY_ANALYSIS.md` - Detailed code reuse plan

### Modified Code
- `/elastic-app/app/src/scenes/core/resources/air.gd` - Force colors
- `/elastic-app/app/src/scenes/core/resources/game_resource.gd` - Resource types
- `/elastic-app/app/src/scenes/core/entities/hero.gd` - Force properties
- `/elastic-app/app/src/scenes/core/resources/cost.gd` - Cost checking

### Key Existing Files to Adapt
- `/elastic-app/app/src/scenes/core/entities/card.gd` - Card base class
- `/elastic-app/app/src/scenes/ui/battleground/ui_battleground.gd` - Grid system
- `/elastic-app/app/src/scenes/core/global_game_manager.gd` - Game flow
- `/elastic-app/app/src/scenes/data/card_data.json` - Card definitions

## Critical Design Principles

1. **Time is Currency:** Every action costs time
2. **No Automatic Draw:** Card draw must be earned
3. **Single Grid Positions:** No complex shapes, all complications are 1x1
4. **Ready States:** Complications wait for resources
5. **Tag Synergies:** Core combo system
6. **Escapement Order:** Deterministic evaluation order
7. **Force Flow:** No explicit connections, just evaluation order
8. **Loss is Quick:** Empty hand = immediate loss

## Next Immediate Steps

1. **Create test scene** with basic mainplate grid
2. **Implement tick counter** that advances on card play
3. **Add production timer** to one test complication
4. **Test force production** on interval
5. **Verify ready state** behavior with consumption

## Notes and Clarifications

- **No Polyomino Shapes:** All complications are single-position (1x1)
- **No Spring/Teeth Connections:** Force flow follows Escapement Order only
- **No Card Types:** All cards are complications with different effects
- **No Turn Phases:** Only card resolution sequences
- **Forces Unlimited:** No caps unless gremlins impose them
- **Deadlocks Intentional:** Part of puzzle design

This document represents the complete development context as of the current session. All referenced files contain additional detail for their specific domains.