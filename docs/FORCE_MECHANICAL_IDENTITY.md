# Force Mechanical Identity - Simplified

## Core Principle: Each Force Has Exclusive Effects

Instead of all forces converting to generic damage, each force has unique mechanical effects that ONLY it can produce.

## The 5 Force Identities

### 🔥 Heat (Red) - "Raw Damage"
**Exclusive Effects:**
- **Damage** - ONLY Heat converts to damage efficiently
- **Burn** - Damage over time
- **Pierce** - Ignores shields
- **Overkill** - Excess damage carries over

**Conversion Rate:** 1 Heat = 1 damage (most efficient)

**Example Effects:**
```
"consume_heat=3,damage=3"         // Direct damage
"consume_heat=5,damage_all=2"     // AoE damage
"consume_heat=2,burn=2"           // Apply burn stacks
"consume_heat=4,pierce_damage=4"  // Piercing damage
```

### 🎯 Precision (Blue) - "Card Control & Tempo"
**Exclusive Effects:**
- **Draw** - ONLY Precision draws cards efficiently
- **Bounce** - Return gears to hand (tempo play)
- **Search/Tutor** - Find specific cards
- **Cycle** - Draw X, discard Y
- **Replay** - Play cards for reduced cost

**Conversion Rate:** 2 Precision = 1 card draw

**Example Effects:**
```
"consume_precision=2,draw_card=1"        // Draw cards
"consume_precision=3,bounce_target"      // Return gear to hand
"consume_precision=4,tutor_tag=MICRO"    // Search for MICRO card
"consume_precision=3,cycle=2"            // Draw 2, discard 1
"consume_precision=2,bounce_self"        // Return this gear to hand
"consume_precision=5,replay_discount=2"  // Next card costs -2 ticks
```

### 🌀 Momentum (Green) - "Acceleration & Efficiency"
**Exclusive Effects:**
- **Cost Reduction** - Make cards cheaper to play
- **Haste** - Speed up gear timers
- **Extra Triggers** - Fire gears additional times
- **Chain Reactions** - One gear triggers another
- **Free Plays** - Play cards for 0 ticks

**Conversion Rate:** 3 Momentum = 1 cost reduction OR 1 extra trigger

**Example Effects:**
```
"consume_momentum=3,next_cost_minus=2"   // Next card costs -2 ticks
"consume_momentum=2,haste_all=20"        // All gears 20% faster
"consume_momentum=3,trigger_adjacent"    // Trigger adjacent gears
"consume_momentum=4,double_next_fire"    // Next gear fires twice
"consume_momentum=5,free_play"           // Next card costs 0 ticks
"consume_momentum=1,reduce_tag_cost=MICRO,1" // MICRO cards cost -1
```

### ⚖️ Balance (White) - "Protection"
**Exclusive Effects:**
- **Shields** - ONLY Balance creates shields
- **Immovable** - Protect gears from destruction
- **Cleanse** - Remove debuffs/disruptions
- **Prevent Loss** - Stop loss conditions

**Conversion Rate:** 1 Balance = 1 shield

**Example Effects:**
```
"consume_balance=2,shield_self=2"        // Add shields
"consume_balance=3,immovable_target"     // Make gear immovable
"consume_balance=4,cleanse_all"          // Remove all debuffs
"consume_balance=5,prevent_next_loss"    // Ignore next loss condition
```

### 💀 Entropy (Black) - "Destruction & Chaos"
**Exclusive Effects:**
- **Sacrifice** - Destroy your own gears for benefit
- **Poison** - Stacking poison damage
- **Execute** - Instant kills below threshold
- **Transform** - Change one thing into another

**Conversion Rate:** Variable/Chaotic

**Example Effects:**
```
"consume_entropy=2,sacrifice_gear,damage=5"   // Destroy gear for damage
"consume_entropy=1,poison=2"                  // Apply poison stacks
"consume_entropy=4,execute_below=5"           // Kill enemies under 5 HP
"consume_entropy=3,transform_force"           // Change any force to any other
```

## Why This Works

### 1. Clear Strategic Identity
- Want damage? You NEED Heat
- Want cards? You NEED Precision
- Want speed? You NEED Momentum
- Want defense? You NEED Balance
- Want flexibility? You NEED Entropy

### 2. Forces Meaningful Choices
- Can't just produce any force and convert to damage
- Must plan your force production around your needs
- Creates distinct build paths

### 3. Prevents "Rainbow" Builds
- You can't efficiently do everything
- Specialization is rewarded
- 2-3 force focus becomes optimal

## Cross-Force Interactions

### Inefficient Conversions (2:1 ratio)
While each force has exclusive effects, you can inefficiently convert:

```
2 Precision → 1 weak damage (1 damage)
2 Balance → 1 slow draw (costs 4 ticks)
2 Heat → 1 weak shield (1 shield)
```

This allows flexibility but encourages specialization.

## Starter Deck Implications

The starter deck should demonstrate all 5 forces but encourage focusing:

### Starter Force Distribution
- **2 Heat cards** - Show damage is red's thing
- **2 Precision cards** - Show card draw is blue's thing
- **1 Momentum card** - Taste of speed
- **1 Balance card** - Taste of defense
- **1 Entropy card** - Taste of chaos
- **3 Neutral cards** - Work with any forces

## Gremlin Interactions

Gremlins can now target specific force strategies:

### Force-Specific Disruptions
- **Heat Dampener** - "Heat production -50%"
- **Precision Scrambler** - "Card draws give random cards"
- **Momentum Friction** - "Gears can't be sped up"
- **Balance Breaker** - "Shields decay each tick"
- **Entropy Stabilizer** - "Sacrifice effects disabled"

This creates rock-paper-scissors dynamics where different builds handle different gremlins better.

## Visual Language

Each force should have distinct visual effects:

- **Heat** - Fire particles, red glow, burning edges
- **Precision** - Blue geometric patterns, targeting reticles
- **Momentum** - Green speed lines, acceleration trails
- **Balance** - White shields, stabilizing auras
- **Entropy** - Black void effects, decay particles

## Implementation Priority

### Step 1: Exclusive Effects (Minimum Viable Change)
Just make each force do ONE thing only:
- Heat → Damage
- Precision → Cards
- Momentum → Speed
- Balance → Shields
- Entropy → Wild/Anything (but inefficient)

### Step 2: Secondary Effects
Add the secondary exclusive effects for variety

### Step 3: Visual Feedback
Make it CLEAR what each force does through visuals

## Example Card Redesigns

### Before (Boring)
```
"Force Converter"
Consume 2 any force → 3 damage
```

### After (Interesting)
```
"Heat Cannon"
Consume 2 Heat → 3 damage (piercing)

"Precision Engine"  
Consume 2 Precision → Draw 2 cards

"Momentum Accelerator"
Consume 2 Momentum → All gears fire immediately

"Balance Shield"
Consume 2 Balance → Shield 3

"Entropy Rift"
Consume 2 Entropy → Destroy a gear, deal damage equal to its tick cost
```

## This Solves The Shallow Problem

Now forces aren't just "different colored mana" - they have mechanical identity that affects:
- What cards you draft
- What gears you play
- How you handle gremlins
- Your win condition
- Your counter-strategies

The game becomes about managing the RIGHT forces, not just ANY forces.