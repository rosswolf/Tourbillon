# Product Requirements Document: Tourbillon - Engine Builder Roguelike Card Game

## Executive Summary

Tourbillon is a single-player roguelike card game that combines engine-building mechanics with time-based resource management. Players construct clockwork engines using gears and springs to generate five distinct forces, defend against gremlins, and ultimately build a perpetual motion machine to escape a collapsing timeline.

## Core Concept

### The Hook
"Build impossible clockwork engines that bend the laws of physics, where every tick of the clock could be your last."

### Unique Selling Points
- **Time as Currency**: Every action costs time from a depleting timeline
- **Polyomino Gear Placement**: Tetris-like spatial puzzle for engine construction
- **Five-Force System**: Unique resource types that interact and transform
- **Living Engine**: Your creation actively produces, consumes, and evolves
- **Temporal Stakes**: The world literally ends when time runs out

## Game Mechanics

### 1. Time System

#### The Timeline
- **Total Duration**: 100 beats per run (expandable through gameplay)
- **Beat Structure**: Each beat contains 10 ticks
- **Depletion**: Timeline constantly counts down during active play
- **Game Over**: When timeline reaches zero, reality collapses

#### Temporal Resources
- **Beats**: Major time units, used for significant actions
- **Ticks**: Minor time units, used for quick adjustments
- **Temporal Anomalies**: Events that can add/subtract from timeline

### 2. Forces System

The game features five fundamental forces that power all mechanics:

#### Heat (Red) 🔥
- **Generation**: Furnaces, friction gears, combustion chambers
- **Properties**: Volatile, high output, difficult to control
- **Uses**: Raw power, melting, explosive effects
- **Interactions**: Consumes Precision, generates Entropy

#### Precision (Blue) 💎
- **Generation**: Clockwork, alignment gears, tuning forks
- **Properties**: Stable, predictable, slow to generate
- **Uses**: Crafting, accuracy, complex operations
- **Interactions**: Reduces Entropy, enhances Balance

#### Momentum (Green) ⚡
- **Generation**: Flywheels, pendulums, springs
- **Properties**: Builds over time, hard to stop once started
- **Uses**: Sustained effects, chain reactions
- **Interactions**: Amplifies other forces, resists Balance

#### Balance (White) ☯️
- **Generation**: Gyroscopes, harmonic resonators
- **Properties**: Neutralizes extremes, stabilizing
- **Uses**: Defense, conversion, efficiency
- **Interactions**: Converts between forces, reduces all extremes

#### Entropy (Purple) 🌀
- **Generation**: Chaos gears, paradox engines, glitch zones
- **Properties**: Unpredictable, corrupting, powerful
- **Uses**: Random effects, reality manipulation
- **Interactions**: Corrupts all other forces, self-generating

### 3. Engine Building

#### The Grid
- **Size**: 7x7 expandable to 9x9
- **Placement Rules**: Gears must connect via teeth/springs
- **Power Flow**: Forces travel through connections
- **Efficiency**: Distance and connection quality affect transfer

#### Complications (Gears)
Complications are polyomino-shaped mechanical components:

**Tier 1 - Simple Gears**
- **Cogwheel** (2x2): +1 Heat per beat
- **Precision Pin** (1x3): +1 Precision per 2 beats
- **Spinner** (L-shape): +1 Momentum when Heat passes through

**Tier 2 - Complex Mechanisms**
- **Furnace** (3x3 with hole): +3 Heat, consumes 1 Balance
- **Clockwork Core** (T-shape): +2 Precision, +1 Balance
- **Flywheel** (Plus-shape): Stores up to 5 Momentum

**Tier 3 - Exotic Devices**
- **Paradox Engine** (5-square zigzag): Generates random force each beat
- **Harmony Matrix** (3x3): Converts any 3 forces to any 2 forces
- **Perpetual Prototype** (4x4): Win condition component

#### Springs and Connections
- **Basic Spring**: Transfers 1 force per tick
- **Resonant Spring**: Transfers 2 forces if matching type
- **Chaos Spring**: Randomly changes transferred force type
- **Quantum Spring**: Can transfer forces backward in time (costs beats)

### 4. Card System

#### Card Types

**Plans** (Blue cards)
- Blueprints for complications
- Must be "developed" using Precision
- Single-use, consumed on placement

**Calibrations** (Green cards)
- Instant effects and modifications
- Examples: "Rotate any gear 90°", "Add +2 output for 3 beats"
- Can be played during any tick

**Contingencies** (Red cards)
- Reactive cards triggered by conditions
- Examples: "When Entropy exceeds 5...", "If a gear breaks..."
- Set in advance, trigger automatically

**Theorems** (Purple cards)
- Permanent rule modifications
- Examples: "Heat generates +1 Momentum", "Gears can overlap"
- Limited to 3 active per run

#### Draw System
- **Hand Size**: 5 cards (expandable)
- **Draw Cost**: 1 tick per card OR 1 Precision for 3 cards
- **Mulligan**: Once per beat, costs 2 ticks
- **Deck Building**: Cards gained through events and shops

### 5. Gremlin System

#### Gremlin Behavior
Gremlins are temporal parasites that attack your engine:

**Types**
- **Rust Sprites**: Target high-Heat gears, reduce output
- **Precision Thieves**: Steal Precision, disable complex gears
- **Momentum Leeches**: Slow down flywheels and springs
- **Balance Breakers**: Create instability, cause misfires
- **Entropy Worms**: Spread corruption, randomize outputs

#### Combat Mechanics
- **Detection**: Gremlins appear on timeline 3 beats before arrival
- **Defense**: Spend forces to create barriers and traps
- **Damage**: Gremlins disable gears, corrupt connections
- **Elimination**: Specific force combinations destroy specific gremlins

### 6. Shop System

#### The Temporal Bazaar
Between each sector (every 20 beats), access the shop:

**Currencies**
- Residual Forces (carried over from engine)
- Temporal Fragments (earned from perfect beats)
- Paradox Tokens (from embracing Entropy)

**Shop Inventory**
- New complication blueprints
- Card packs (themed by force type)
- Spring upgrades
- Timeline extensions (+5 beats)
- Gremlin repellents
- Permanent upgrades (gear slots, hand size)

### 7. Progression System

#### Run Structure
1. **Sector 1 (Beats 1-20)**: Tutorial zone, basic gears only
2. **Sector 2 (Beats 21-40)**: Intermediate gears, first gremlins
3. **Sector 3 (Beats 41-60)**: Advanced gears, gremlin swarms
4. **Sector 4 (Beats 61-80)**: Exotic gears, reality distortions
5. **Sector 5 (Beats 81-100)**: Final push, perpetual motion assembly

#### Victory Conditions
- **Primary**: Build and power the Perpetual Motion Machine
- **Secondary**: Survive all 100 beats
- **Tertiary**: Achieve specific force generation milestones

#### Meta Progression
- **Knowledge Bank**: Unlock new starting cards/gears
- **Temporal Echoes**: Carry forward one upgrade between runs
- **Theorem Library**: Permanent access to discovered theorems
- **Gremlin Bestiary**: Reveals weaknesses after encounters

## User Interface

### Main Display
- **Center**: 7x7 (or 9x9) engine grid
- **Top**: Timeline with beat/tick counter
- **Right**: Force meters and storage
- **Bottom**: Card hand
- **Left**: Upcoming gremlins and events

### Visual Design
- **Art Style**: Steampunk meets cosmic horror
- **Animations**: Gears constantly spinning, forces flowing as particles
- **Effects**: Time distortion waves, reality tears, force explosions

## Technical Specifications

### Platform Requirements
- **Primary**: PC (Steam)
- **Secondary**: Mobile (iOS/Android) with adapted UI
- **Performance**: Must maintain 60 FPS with 50+ animated gears

### Development Stack
- **Engine**: Godot 4.4
- **Languages**: GDScript for logic, shaders for effects
- **Multiplayer**: None (purely single-player experience)

## Monetization

### Base Game
- **Price Point**: $19.99
- **Content**: Full 5-sector campaign, 20+ hours gameplay

### DLC Opportunities
- **Force Packs**: New gear types focused on specific forces
- **Infinite Mode**: Endless run with scaling difficulty
- **Challenge Scenarios**: Preset puzzles with specific solutions
- **Cosmetic Themes**: Visual overhauls (Steampunk, Cyber, Organic)

## Success Metrics

### Launch Targets
- 10,000 sales in first month
- 85% positive review score
- Average 8 hours playtime per player
- 30% completion rate for first run

### Long-term Goals
- 100,000 lifetime sales
- Active speedrun community
- Regular content updates for 1 year
- Mobile version within 6 months

## Risk Analysis

### Design Risks
- **Complexity**: May overwhelm casual players
- **Mitigation**: Robust tutorial, difficulty options

### Technical Risks
- **Performance**: Many animated elements could cause lag
- **Mitigation**: LOD system, particle limits, optimization passes

### Market Risks
- **Niche Appeal**: Engine builders are a specific audience
- **Mitigation**: Strong aesthetic hook, streamable moments

## Next Steps

### Pre-Production (Months 1-2)
- Prototype core force system
- Test polyomino placement mechanics
- Design 10 basic complications
- Create vertical slice of first sector

### Production Phase 1 (Months 3-6)
- Complete all gear types
- Implement full card system
- Design and balance 5 sectors
- Create gremlin AI

### Production Phase 2 (Months 7-9)
- Polish UI/UX
- Balance pass on all numbers
- Add particle effects and animations
- Implement meta progression

### Beta & Launch (Months 10-12)
- Closed beta with 100 players
- Balance based on feedback
- Marketing campaign
- Launch preparation

## Appendices

### A. Force Interaction Matrix
```
        Heat  Prec  Mom  Bal  Ent
Heat     0    -1    +1   -1   +2
Prec    -1     0    +1   +2   -2  
Mom     +1    +1     0   -2   +1
Bal     -1    +2    -2    0   -3
Ent     +2    -2    +1   -3    X
```

### B. Sample Complication Stats
[Detailed stats for all 50+ planned complications]

### C. Card List
[Complete list of 200+ cards organized by type and tier]

### D. Gremlin Behavioral Charts
[AI decision trees and spawn patterns]

## Conclusion

Tourbillon combines the satisfaction of engine building with the tension of roguelike progression, wrapped in a unique temporal crisis narrative. The five-force system provides deep mechanical complexity while remaining intuitive through color coding and clear visual feedback. With proper execution, this can become the definitive clockwork roguelike experience.