# Force System Redesign - Adding Depth

## Current Problem

The 5 forces are functionally identical - just different colored resources that convert to damage. This lacks depth and makes force choice feel arbitrary.

## Proposed Solution: Tiered Resource System

### Tier 1: Basic Resources (Raw Materials)
These are what simple gears produce:

- **Steam** - Raw pressure/energy
- **Metal** - Physical materials  
- **Oil** - Lubrication/fuel

### Tier 2: Refined Forces (The 5 Colors)
Created by combining/refining basic resources:

- **Heat (Red)** = Steam + Steam
- **Precision (Blue)** = Metal + Oil  
- **Momentum (Green)** = Steam + Oil
- **Balance (White)** = Metal + Metal
- **Entropy (Black)** = Consumes any 3 basics

### Tier 3: Specialized Effects
Each force has unique mechanical effects when consumed:

## Force Mechanical Identities

### 🔥 Heat (Red) - "Direct Damage"
**Consumes for:**
- Direct damage (most efficient)
- Burn effects (damage over time)
- Area damage
- Pierce effects

**Special Rule:** Heat naturally decays (1 per 10 ticks) - use it or lose it

**Example Cards:**
```
Heat Blast: Consume 3 Heat → 5 damage
Flame Wave: Consume 5 Heat → 2 damage to all
Melting Point: Consume 10 Heat → Destroy a gear, deal 10 damage
```

### 🎯 Precision (Blue) - "Control & Cards"  
**Consumes for:**
- Card draw
- Card selection (tutor/search)
- Timer manipulation
- Target selection

**Special Rule:** Precision can "bank" card draws (store up to 3)

**Example Cards:**
```
Calculated Draw: Consume 2 Precision → Draw 2 cards
Perfect Timing: Consume 3 Precision → Set any gear to fire next tick
Surgical Strike: Consume 4 Precision → 3 damage to chosen enemy
```

### 🌀 Momentum (Green) - "Scaling & Speed"
**Consumes for:**
- Permanent stat boosts
- Haste effects  
- Chain reactions
- Ramping damage

**Special Rule:** Momentum carries over between turns (doesn't reset)

**Example Cards:**
```
Building Speed: Consume 3 Momentum → All gears +20% speed permanently
Cascade: Consume 5 Momentum → Trigger all gears once
Runaway Train: Consume X Momentum → X damage, gain X/2 Momentum
```

### ⚖️ Balance (White) - "Defense & Stability"
**Consumes for:**
- Shields/armor
- Healing
- Negating disruptions
- Protecting gears

**Special Rule:** Balance can prevent one loss condition per combat

**Example Cards:**
```
Stabilize: Consume 2 Balance → Shield 3
Perfect Form: Consume 4 Balance → Gears are Immovable for 5 ticks
Emergency Reserve: Consume 5 Balance → Draw 3 cards if hand empty
```

### 💀 Entropy (Black) - "Sacrifice & Chaos"
**Consumes for:**
- Destroying your own gears for benefit
- Random powerful effects
- Poison/execute mechanics
- Resource conversion

**Special Rule:** Entropy can be used as wild (counts as any force)

**Example Cards:**
```
Controlled Demolition: Consume 2 Entropy → Destroy a gear, trigger its effect 3x
Chaos Theory: Consume 3 Entropy → Random effect (damage 2-10)
Void Conversion: Consume 5 Entropy → Convert all other forces to damage
```

## Resource Conversion Tree

```
TIER 1 (Basic)          TIER 2 (Forces)         TIER 3 (Effects)
                            
Steam ──┐                                       ┌─→ Direct Damage
Steam ──┴──→ 🔥 Heat ────────────────────────→ ├─→ Burn
                                                └─→ AoE

Metal ──┐                                       ┌─→ Card Draw
Oil ────┴──→ 🎯 Precision ──────────────────→ ├─→ Timing Control
                                                └─→ Targeting

Steam ──┐                                       ┌─→ Speed Boosts
Oil ────┴──→ 🌀 Momentum ───────────────────→ ├─→ Chains
                                                └─→ Scaling

Metal ──┐                                       ┌─→ Shields
Metal ──┴──→ ⚖️ Balance ────────────────────→ ├─→ Healing
                                                └─→ Protection

Any 3 ─────→ 💀 Entropy ────────────────────→ ┌─→ Sacrifice
                                                ├─→ Random
                                                └─→ Conversion
```

## New Gear Categories

### Basic Producers (Tier 1)
```
Steam Engine: Every 3 ticks → Produce 2 Steam
Ore Extractor: Every 4 ticks → Produce 2 Metal  
Oil Pump: Every 5 ticks → Produce 2 Oil
```

### Refineries (Tier 1 → Tier 2)
```
Heat Forge: Every 3 ticks → Consume 2 Steam → Produce 1 Heat
Precision Lathe: Every 4 ticks → Consume 1 Metal + 1 Oil → Produce 1 Precision
Momentum Turbine: Every 3 ticks → Consume 1 Steam + 1 Oil → Produce 1 Momentum
Balance Stabilizer: Every 4 ticks → Consume 2 Metal → Produce 1 Balance
Entropy Void: Every 5 ticks → Consume any 3 basic → Produce 1 Entropy
```

### Specialized Consumers (Tier 2 → Effects)
```
Flame Cannon: Consume 2 Heat → 4 damage (piercing)
Card Engine: Consume 2 Precision → Draw 2 cards
Speed Regulator: Consume 2 Momentum → All gears fire 1 tick faster
Shield Generator: Consume 2 Balance → Shield 3
Chaos Device: Consume 2 Entropy → Destroy gear for double its effect
```

## Conversion Recipes & Ratios

### Efficient Paths
- 2 Steam → 1 Heat → 2 damage (1:1 basic to damage)
- 1 Metal + 1 Oil → 1 Precision → 1 card (2:1 basic to card)
- 2 Metal → 1 Balance → 2 shield (1:1 basic to shield)

### Inefficient but Flexible
- 3 any basic → 1 Entropy → varies (3:? ratio)
- Cross-conversion between forces at 2:1 ratio

## Strategic Depth Added

### 1. Resource Planning
- Do I produce basics or skip to forces?
- Which basics support my strategy?
- When do I convert vs. stockpile?

### 2. Timing Decisions  
- Heat decays - use immediately
- Momentum accumulates - save for big turns
- Balance prevents losses - emergency reserve

### 3. Color Identity Matters
- Blue decks need Precision for cards
- Red decks rush with Heat damage
- Green decks scale with Momentum
- White decks survive with Balance
- Black decks use Entropy for flexibility

### 4. Conversion Efficiency
- Direct paths: Basic → Force → Effect
- Indirect paths: More flexible but less efficient
- Entropy as universal converter

## Example Upgraded Gameplay Loop

**Turn 1-3: Establish Basics**
- Play Steam Engine (producing Steam)
- Play Metal Extractor (producing Metal)

**Turn 4-6: Build Refineries**
- Play Heat Forge (Steam → Heat)
- Play Precision Lathe (Metal + Oil → Precision)

**Turn 7-9: Deploy Specialists**
- Play Flame Cannon (Heat → Damage)
- Play Card Engine (Precision → Cards)

**Turn 10+: Full Engine**
- Steam → Heat → Damage
- Metal + Oil → Precision → Cards
- Excess converts through Entropy

## Benefits of This System

1. **Meaningful Choices** - Which basic resources to prioritize?
2. **Build Identity** - Colors have mechanical differences
3. **Resource Puzzle** - Managing conversion chains
4. **Emergent Complexity** - Simple rules, deep gameplay
5. **Visual Clarity** - Can show resource flow visually

## Implementation Priority

### Phase 1: Core Identity
- Give each force unique consumption effects
- Heat = damage, Precision = cards, etc.

### Phase 2: Basic Resources
- Add Steam, Metal, Oil as Tier 1
- Add basic producers and refineries

### Phase 3: Special Rules
- Heat decay
- Momentum accumulation  
- Balance emergency saves
- Entropy wildcards

### Phase 4: Visual Polish
- Resource flow indicators
- Conversion preview
- Production chain visualization

## Comparison to Other Games

**Magic: The Gathering** - 5 colors with mechanical identity ✓
**Cultist Simulator** - Resource refinement chains ✓  
**Factorio** - Production optimization ✓
**Slay the Spire** - Simple to learn, hard to master ✓

This system adds the depth Tourbillon needs while maintaining the clockwork theme!