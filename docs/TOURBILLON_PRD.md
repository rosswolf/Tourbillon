# Product Requirements Document: Tourbillon - Engine Builder Roguelike Card Game

Version: 0.5.0  
Working Title: Tourbillon  
Last Updated: [Current Session]

## 1. Executive Summary

### 1.1 Game Overview
Tourbillon is a roguelike deck-building game where players construct intricate clockwork engines to defeat gremlins through strategic card play. Players act as master horologists building increasingly complex mechanisms. The core innovation is that time only advances when cards are played, representing the manual winding of the grand mechanism.

### 1.2 Core Pillars
- **Time as Currency**: Every card played advances time, creating tension between action and efficiency
- **Dual Economy**: Players must balance both force production and card availability
- **Evolving Engines**: Gears placed on a limited mainplate produce forces on different intervals, creating polyrhythmic production patterns
- **Dynamic Constraints**: Gremlins impose disruptions that force strategic adaptation
- **Force-Based Resources**: Five distinct forces with thematic identities drive different strategies
- **Tag Synergies**: Gears have multiple tags that create emergent combinations and tribal strategies
- **Mainplate Expansion**: Players can expand their mainplate as part of progression

### 1.3 Target Experience
Players should feel the satisfaction of building a complex clockwork engine while under constant pressure from limited cards and gremlin disruptions. Success comes from understanding production rhythms, managing multiple force types, exploiting tag synergies, and adapting strategies to overcome diverse gremlin configurations. The game should evoke the precision and satisfaction of fine watchmaking.

### 1.4 Thematic Framework
**The Central Conflict - The Wheel**: The world is trapped in an endless cycle by The Wheel - a cosmic mechanism that forces time to repeat in increasingly degraded loops. Each rotation, gremlins emerge from the friction between cycles, growing stronger and more numerous. Master horologists attempt to build a perfect mechanism capable of jamming The Wheel and breaking the cycle forever.

**Why You Keep Fighting:**
- Each "run" is another loop of The Wheel
- Even when you "win," The Wheel continues turning (though perhaps slower)
- Your mechanical knowledge accumulates across loops
- Some loops are harder as The Wheel adapts to your previous attempts
- The ultimate goal: build the "Eternal Gear" that breaks The Wheel permanently

**Visual Direction:**
- Brass, steel, and crystal aesthetics
- Visible gears, springs, and escapements
- Progress bars as tension gauges
- Satisfying mechanical clicks and whirs
- Gears appear as intricate watch mechanisms
- The Wheel looms in the background, slowly turning

## 2. Core Mechanics

### 2.0 Order of Operations

#### 2.0.1 Time System Definitions
- **Beat**: The smallest unit of time (0.1 of a Tick)
- **Tick**: The standard time unit = 10 Beats (what players count and cards cost)
- All time in the game advances in Beats, but players primarily think in Ticks
- Cards show costs in whole Ticks (1, 2, 3, etc.)
- Gears produce on Tick intervals (e.g., "Every 3 Ticks: Produce 2 Heat")

#### 2.0.2 Beat Resolution
When time advances, the game processes every Beat:
1. **Gear Phase**: All gears check/trigger (top-to-bottom, left-to-right)
2. **Poison Resolution**: Poison damage applies based on poison timer (default 10 Beats, modifiable)
3. **Gremlin Phase**: All gremlins check/trigger (top-to-bottom)
4. **End of Beat**: Check for victory/loss conditions (only after full card resolution)

Note: Checking every Beat allows for precise timing and off-Tick effects (e.g., gears that produce every 3.5 Ticks = 35 Beats)

#### 2.0.3 Gear Trigger Rules
- Each gear can only trigger once per Beat maximum (prevents infinite loops)
- Since there are 10 Beats per Tick, a gear can trigger at most 10 times per Tick
- Gears track their own timers independently in Beats
- Gears produce/consume in strict priority order (Escapement Order)
- If Gear A produces forces, Gear B (lower in priority) can consume them same Beat
- Tag counts are checked when each gear triggers (can change mid-Beat)
- Gears have no memory - destroyed/bounced gears lose all timer progress (unless Overbuild)

#### 2.0.4 Card Play Sequence
1. Replace gear on movement plate if necessary (triggers replacement effects)
2. Slot remembers state of old gear
3. Old gear's "when replaced" effects trigger
4. Old gear moved to discard
5. Old gear's "when destroyed" effects trigger
6. New gear played on movement plate
7. New gear's "when played" effects trigger
8. Slot "memory" of old gear is cleared
9. Time advances by card's cost (in Beats: 10 Beats per Tick shown on card)
10. All gears check for production in priority order
11. All gremlins check for triggers in order
12. All effects must fully resolve before playing another card (turn ends)

#### 2.0.4 Turn Structure
- A "turn" consists of playing one card and resolving all effects
- Turn ends when all effects are resolved
- Players can then play another card (start new turn)
- Loss conditions checked at end of turn

### 2.1 Time System

#### 2.1.1 Time Advancement
- Time only advances when cards are played
- Each card has a "time cost" in Ticks (whole numbers: 1, 2, 3, 4, 5+ Ticks)
- Minimum time cost of a card play (after modifications) is 1 Beat (0.1 Ticks)
- Minimum gear trigger interval is 5 Beats (0.5 Ticks)
- When a card is played, global time advances by that amount
- All systems in the game react to this time advancement
- Fractional Ticks only occur through modification effects (e.g., "Micro gears cost -0.5 Ticks")
- Time cannot go backwards (no rewind effects)

#### 2.1.2 Production Intervals
- Each gear has a production interval in Ticks (whole numbers for base: 3, 4, 5 Ticks etc.)
- Time advances in Beats internally for precise tracking
- All fractional results are rounded to nearest Beat
- When time advances, all gears check if their interval threshold is reached
- Gears that hit their interval produce their forces
- Production happens AFTER the new gear is placed, allowing it to potentially produce immediately
- Fractional intervals only occur through modifications (tracked in Beats)

#### 2.1.3 No Turn Structure
- The game has no discrete turns or phases beyond card resolution
- Players can play cards as long as they have cards in hand
- All timing is based on the accumulated time from played cards

### 2.2 Card System

#### 2.2.1 Deck Composition
- Every card represents a gear that can be placed on the movement plate
- Starting deck contains approximately 7-8 cards
- No maximum deck size, but larger decks reduce consistency
- Maximum hand size: 10 cards (can be expanded by certain effects)

#### 2.2.2 Card Flow
- No automatic draw: Players do NOT draw back up to a maximum hand size
- Cards are only drawn through gear effects or other abilities
- When the deck is empty, the discard pile is shuffled to form a new deck
- Destroyed/replaced gears go to the discard pile
- Deck visibility: Can see cards remaining in deck (not order), can see discard pile (with order)
- Tutor effects: Search for specific card, then shuffle deck
- Card Draw Balance: Card draw should not be free but with minimal effort should be sustainable
- Must balance between drawing too many (hand clog) and too few (starvation)

#### 2.2.3 How You Lose
- **Loss Condition 1**: Zero cards in hand after full card resolution (end of turn)
- **Loss Condition 2**: Attempt to draw a card when deck and discard are both empty
- When you need to draw and deck is empty, shuffle discard into deck first
- If both deck AND discard are empty when you need to draw, you lose immediately
- **Grace Period**: Loss from empty hand is checked only after current card fully resolves and all triggered effects complete
- If pending gear triggers would draw cards, you survive
- If you achieve victory and loss simultaneously, victory takes precedence
- This makes card draw a critical resource alongside force production
- Gremlin discard effects become extremely threatening

### 2.3 Mainplate System (Grid)

#### 2.3.1 Mainplate Structure
- Starting mainplate size: 4x4
- Mainplate can be expanded through rewards/upgrades
- Maximum 4 expansions total (could become 8x4, 6x6, 5x7, etc.)
- Each position can contain one gear
- Some positions may have placement bonuses

#### 2.3.2 Mainplate Expansion
Expansion mechanics:
- Between combats: Permanent expansions via rewards or workshops
- During combat: Temporary expansions possible via card effects
- When mainplate expands, new row/column adds to edge of existing plate
- Existing gears do not shift positions
- Expansions add rows/columns to edges of current plate

#### 2.3.3 Placement Rules
- Gears can be placed on empty positions
- Replacement mechanic: Gears can be played on top of existing gears
- When mainplate is full, you MUST replace an existing gear
- When a gear is replaced, the old gear's card goes to the discard pile
- This allows for engine evolution and card recycling
- No voluntary discarding of cards (unless a card effect specifically allows it)

#### 2.3.4 Position Bonuses
- Certain plate positions provide bonuses
- Ongoing bonuses: Always affect any gear on that position
- Triggered bonuses: Activate once when first gear placed, then disappear
- Some gears can create position bonuses for adjacent spaces
- Position bonuses stack (e.g., two "+1 production" effects = +2 production)
- Examples: "+1 production in this position", "Gears here cost 1 less time", "Draw 1 card when placed"
- Starting plates should have multiple card draw bonuses to help early game sustainability

#### 2.3.5 The Escapement Order (Priority System)
- Fixed evaluation order: Top to Bottom, Left to Right
- When forces are consumed, gears are evaluated in this order
- Production and consumption happen in this exact sequence each tick
- This enables deliberate production chains if timed correctly
- Top-left gears get first access to forces
- Creates strategic depth in placement decisions
- Represents the mechanical cascade of a watch movement

## 3. Force System

### 3.1 Five Forces (Colors)
Forces represent different types of energy in your clockwork mechanism. Each force has both a mechanical name and a color association:

- **Heat (Red)** - Friction/Combustion
  - Attack Targeting: **Attack (All)** - Hits all gremlins
  - Direct damage focus, fast intervals, volatile explosive effects
  - Damage Multiplier: **1.25x**
  - Color: Red represents the heat and fire of friction

- **Precision (Blue)** - Control/Accuracy  
  - Attack Targeting: **Attack (Bottom)** - Targets last gremlin in stack
  - Card draw, time manipulation, control and optimization
  - Damage Multiplier: **0.75x**
  - Color: Blue represents cool calculation and precision

- **Momentum (Green)** - Perpetual Motion
  - Attack Targeting: **Attack (Most HP)** - Targets highest health gremlin
  - Force ramping, scaling effects, self-sustaining cycles
  - Damage Multiplier: **1.0x** (baseline)
  - Color: Green represents growth and acceleration

- **Balance (White)** - Regulation/Stability
  - Attack Targeting: **Attack (Oldest)** - Targets gremlin in combat longest
  - Shields/damage prevention, consistent production, stability focus
  - Damage Multiplier: **0.8x**
  - Color: White represents purity and equilibrium

- **Entropy (Purple/Black)** - Decay/Unwinding
  - Attack Targeting: **Attack (Lowest HP)** - Targets weakest gremlin
  - Destroy own gears for benefit, high risk/high reward
  - Damage Multiplier: **1.1x**
  - Color: Purple/Black represents decay and chaos

**Universal**: All forces can use **Attack (Basic)** - Targets top gremlin in stack

### 3.2 Force Mechanics

#### 3.2.1 Production
- Gears produce forces when their time interval is reached
- Printed production amounts are whole numbers (1, 2, 3, etc.)
- Modified production amounts can be fractional (rounded to 0.1)
- Forces stored as fractional values (0.1 precision)
- Some gears may produce multiple force types

#### 3.2.2 Round Tracking
- Track statistics per combat: cards played, cards sacrificed, gears destroyed, etc.
- Enables complex scaling triggers and achievements
- Gears can trigger on events other than time (e.g., "When 3rd card played this turn")
- Adds strategic dimensionality beyond pure time management

#### 3.2.3 Consumption-Based Production
- Many gears only produce when they can consume required inputs
- If a gear would produce but cannot consume its requirements, it enters "ready" state
- Timer stops at maximum until forces are available
- Creates supply chain management puzzles
- Gear priority order (top-left to bottom-right) determines consumption order
- Consumption is mandatory unless explicitly stated as optional
- Optional consumption mainly for discard costs ("You may discard a card to...")

#### 3.2.4 Storage and Caps
- No base force caps - unlimited storage by default
- Gremlin disruptions can impose force caps
- Gremlin effects can add decay triggers
- Some gears might increase or decrease effective caps

#### 3.2.5 Spoilage
- Forces may spoil based on gremlin effects or special rules
- Spoiled forces may disappear or convert to waste
- Waste/pollution mechanics may require management

#### 3.2.6 Conversion Chains
- Higher-tier effects require force conversion
- Conversions use whole number ratios (2:1, 3:1, etc.)
- Multi-input recipes for complex effects
- "Consume X max" effects:
  - Check if X total forces exist
  - If not, effect fails completely (no partial consumption)
  - If yes, consume from highest force pool first
  - If tied for highest, consume in order: Heat → Precision → Momentum → Balance → Entropy
- Some effects may specify "Consume X of one force" for focused consumption
- Forces can exist in fractional amounts (rounded to 0.1) for more granularity
- Forces can accumulate infinitely (no upper limit)

### 3.3 Special Resources (Future Consideration)
[NOTE: Special combined resources are planned for future expansion but not currently implemented]

Special Resources could be created by combining Basic Forces for powerful effects:

- **HEAT COMBINED** (Heat/Red + Precision/Blue combination)
  - Damage Multiplier: **1.6x**
  - Would power pierce damage, momentary effects, and combat specialization

- **PRECISION COMBINED** (Precision/Blue + Balance/White combination)  
  - Damage Multiplier: **1.3x**
  - Would enable targeted effects, card manipulation, and control

- **MOMENTUM COMBINED** (Momentum/Green + Heat/Red combination)
  - Damage Multiplier: **1.4x** (base, can scale with usage)
  - Would provide acceleration, chains, and scaling effects

- **BALANCE COMBINED** (Balance/White + Entropy/Purple combination)
  - Damage Multiplier: **1.2x** 
  - Would enable execution (<10 HP threshold), stability, and control

- **ENTROPY COMBINED** (Entropy/Purple + Momentum/Green combination)
  - Damage Multiplier: **1.5x**
  - Would power poison, sacrifice, copying, and rule-breaking effects

### 3.4 Damage Balance System

The game uses a systematic approach to balance damage output across all force types.

#### 3.4.1 Damage Calculation Formula
**Card Damage = Base Damage × Resource Multiplier × Resource Count**
- Result rounded to 0.1 precision
- Final damage value burned into card text
- No dynamic calculation during gameplay

#### 3.4.2 Balance Framework
**Two-Level Balance Control:**

**Individual Card Level:**
- Adjust Base Damage for specific cards that are over/underpowered
- Example: "Heat Cannon" base damage 3 → 2.5 affects only that card

**Color-Wide Level:**  
- Adjust Resource Multipliers to affect all cards of that type proportionally
- Example: Red multiplier 1.25x → 1.1x affects all Red damage cards

#### 3.4.3 Design Process
1. **Design Intent**: Define card concept and resource cost
2. **Calculate Damage**: Apply formula using current multipliers  
3. **Burn In**: Write final damage value into card text
4. **Balance**: Adjust base damage (individual) or multiplier (color-wide) as needed

#### 3.4.4 Multiplier Rationale
- **Basic Forces**: Range from 0.75x to 1.25x based on strategic role
- **Special Resources**: All above 1.2x to reward conversion investment
- **Red Highest**: Front-loaded aggression, peak early power
- **Blue/White Lowest**: Utility focus, sacrifice damage for other benefits

### 3.5 Card Draw Balance System

The game uses a parallel system to balance card draw across all force types, ensuring every color has sustainable access to cards.

#### 3.5.1 Card Draw Calculation Formula
**Card Draw Amount = Base Draw × Resource Multiplier × Resource Count**
- Result rounded to nearest 0.5 (0.5 rounds up to 1 card)
- Final draw value burned into card text
- Fractional draws can be designed as "Draw 1, 50% chance to draw 2"

#### 3.5.2 Card Draw Multipliers

**Basic Forces:**
- **Heat**: 0.9x draw multiplier (trades draw efficiency for damage power)
- **Precision**: 1.25x draw multiplier (card draw specialist, inverse of damage)
- **Momentum**: 1.0x draw multiplier (baseline balanced)
- **Balance**: 1.1x draw multiplier (reliable and consistent)
- **Entropy**: 0.8x draw multiplier (sacrifices draw for destruction effects)

**Special Resources (Combinations):**
- **HEAT** (Red + Blue): 1.15x draw multiplier
- **PRECISION** (Blue + White): 1.35x draw multiplier (best draw engine)
- **MOMENTUM** (Green + Red): 0.95x draw multiplier  
- **BALANCE** (White + Purple): 1.0x draw multiplier
- **ENTROPY** (Purple + Green): 0.9x draw multiplier

#### 3.5.3 Implementation Strategy
All forces draw the same amount (1 card) but vary in cost and speed:
- **Heat**: Every 4 Ticks, Consume 3 Heat → Draw 1 card (expensive, moderate speed)
- **Precision**: Every 3 Ticks, Consume 2 Precision → Draw 1 card (cheap, fast)
- **Momentum**: Every 4 Ticks, Consume 2.5 Momentum → Draw 1 card (baseline balanced)
- **Balance**: Every 5 Ticks, Consume 2 Balance → Draw 1 card (cheap, slow, reliable)
- **Entropy**: Every 3 Ticks, Consume 4 Entropy → Draw 1 card (expensive, fast)

#### 3.5.4 Design Rationale
- **Every color is self-sufficient**: No mandatory splashing for card draw
- **Preserves color identity**: Precision remains the draw specialist
- **Strategic tradeoffs**: High damage colors sacrifice draw efficiency
- **Consistent with damage system**: Players understand the parallel structure
- **Tunable balance**: Single multiplier table controls all draw effects

### 3.5 Inspiration (Per-Run Currency)
- **Inspiration**: Resource earned from defeating gremlins during a run
- Represents mechanical insights gained during this attempt
- Inspiration resets between runs (does not persist)
- Used at workshops within a run to acquire new cards or temporary upgrades
- Regular forces (Heat, Precision, Momentum, Balance, Entropy) also reset between combats
- Inspiration farming prevention: Non-summoned gremlins give fixed Inspiration amounts
- Some gears may provide bonus Inspiration on kills (still capped per encounter)

## 4. Tag System

### 4.1 Tag Categories
Tags create synergies and define gear identities. Gears typically have 1-4 tags.

#### 4.1.1 Mechanical Identity Tags (6 - Opposing Pairs)

**Order vs Chaos**
- **Order**: Wants patterns, similarity, alignment
  - "Order gears produce +1 for each matching force in same row"
  - "When 3 Order gears form a line, draw a card"
- **Chaos**: Wants isolation, diversity, uniqueness
  - "Chaos gears produce +1 for each different force in same row"
  - "Chaos gears deal 3 damage if no adjacent gears"

**Micro vs Titan**
- **Micro**: Fast, weak, numerous
  - "Every 1 second: produce 1"
  - "Micro gears cost -0.5 seconds per other Micro"
- **Titan**: Slow, powerful, immovable
  - "Every 10+ seconds: massive effect"
  - "Titan gears cannot be destroyed"

**Forge vs Void**
- **Forge**: Enhancement, support, creation
  - "Other gears in same row produce +1"
  - "When placed: permanently upgrade an adjacent gear"
- **Void**: Consumption, destruction, hunger
  - "Consume 5 any forces → 7 damage"
  - "When a gear is destroyed, Void gears produce"

#### 4.1.2 Thematic Flavor Tags (5 - Non-Opposing)
- **Crystal** - Pristine, geometric, focusing
- **Shadow** - Dark, hidden, elusive
- **Beast** - Wild, living, pack-minded
- **Arcane** - Magical, mystical, complex
- **Mech** - Mechanical, futuristic, automated

#### 4.1.3 Common Tags (4 - Widely Applicable)
- **Stone** - Solid, permanent, foundational
- **Spark** - Energy, activation, catalyst
- **Tool** - Implements, equipment, utility
- **Dust** - Remnants, particles, ephemeral

### 4.2 Tag Clarifications

#### 4.2.1 Colorless Cards
- Colorless cards have no force identity
- Can produce or consume forces normally
- Don't count for "different forces" bonuses
- Not affected by force-specific disruptions
- Otherwise function identically to force-aligned cards

#### 4.2.2 Tag Counting
- Tags are counted when each gear checks for production
- If tags change mid-tick (gear destroyed), downstream gears are affected
- Example: If 3rd Micro gear is destroyed, remaining Micro gears lose "3+ Micro" bonuses immediately

## 5. Keywords

### 5.1 Core Keywords
- **Fire**: When a gear produces its effect and resets its timer to 0
- **Overbuild**: When played on another gear, inherit that gear's timer progress
- **Momentary**: Trigger effect when played, then immediately destroy self (doesn't stay on mainplate)
- **Immovable**: Cannot be destroyed by effects (can still be replaced)
- **Ephemeral**: When this card would go to the discard pile, exile it instead

### 5.2 Combat Keywords
- **Pierce**: This damage ignores armor
- **Pop**: Double damage vs shields (excess still doubled applies to HP)
- **Poison X**: Deal X damage based on poison timer (default: every 10 Beats, but modifiable)
- **Burn X**: Gremlin can't heal for X Ticks
- **Execute X**: Instantly kill gremlin below X HP (ignores shields)
- **Overkill**: Excess damage carries to next gremlin
- **Barrier**: Absorbs one entire hit completely (any amount of damage), then the barrier is destroyed. The unit remains alive and can be damaged normally by subsequent hits.

### 5.3 Timing Keywords
- **Haste X**: Gear's timer advances X% faster
- **Delay X**: Add X Ticks to target's timer
- **Disable X**: Disable gremlin effects for X Ticks
- **Starting X**: Begin with X Beats of production already complete

### 5.4 Resource Keywords
- **Efficient**: Enhanced force conversion ratios
- **Consume X**: Requires X forces to function
- **Produce X**: Generate X forces without input

## 6. Mechanics System

### 6.1 Core Production Mechanics
- **Produce**: Generate forces at intervals
- **Consume**: Require forces to function (Convert is a subtype)
- **Generate**: Create forces without input (basic production)

### 6.2 Gear Manipulation Mechanics
- **Overbuild**: Inherit timer from replaced gear when played on top
- **Copy**: Duplicate another gear's text/effects (must specify what is copied)
- **Bounce**: Return to hand instead of discard when destroyed

### 6.3 Trigger Mechanics
- **On play**: When the gear is played from hand
- **On pickup**: When the card enters hand (from draw OR bounce)
- **On draw**: When specifically drawn from deck
- **On bounce**: When specifically returned from play to hand
- **On destroy**: When the gear is destroyed
- **On replaced**: When another gear is played on top of this
- **On discard**: When discarded from hand
- **On fire**: When the gear successfully fires (produces and resets)

### 6.4 Timing Mechanics
- **Haste**: Speed up tick rate for duration
- **Slow**: Slow down tick rate for duration
- **Delay**: Add ticks to timer
- **Skip**: Remove ticks from timer
- **Trigger**: Force immediate production regardless of timer
- **Chain**: When this produces, trigger adjacent/specific gears

### 6.5 Combat Mechanics
- **Damage**: Direct HP reduction to gremlins (can target topmost, bottommost, weakest, AOE)
- **Poison**: Damage over time (ticks on whole seconds), ignores shields
- **Pierce**: Ignore armor
- **Pop**: Double damage vs shields
- **Delay**: Delay a gremlin from activating disruptions
- **Disable**: Disable a gremlin's disruptions for X seconds
- **Execute**: Instantly kill gremlins below HP threshold
- **Overkill**: Excess damage carries to next gremlin
- **Burn**: Gremlins can't heal while burned

### 6.6 Force Manipulation Mechanics
- **Efficient**: Increase production amounts
- **Multiply**: Forces become a multiple of current forces
- **Produce**: Generate forces from nothing
- **Spend/Consume**: Forces spent for an effect
- **Spoiling**: Forces decay over time
- **Cap**: Set maximum force amounts
- **Burn**: Destroy forces (may be used for negative forces)
- **Starting**: Start with X ticks of production

### 6.7 Mainplate Mechanics
- **Expand**: Add row/column to plate (usually between stages)
- **Create Position Bonus**: Add permanent or temporary bonus to plate position
- **Adjacent**: Affect gears next to this one
- **Row/Column**: Affect all gears in same row or column
- **On Plate**: Count the number of gears on the plate with criteria
- **Destroy Position**: Remove gear(s) at specific location

### 6.8 Card Mechanics
- **Draw**: Add cards from deck to hand
- **Discard**: Remove cards from hand (chosen by player)
- **Tutor**: Search deck for specific card or type
- **Create**: Generate new cards (tokens) during combat
- **Exile**: Remove cards from game (not to discard)
- **Ephemeral**: When this card would go to discard, exile it
- **Mill**: Move cards from deck directly to discard

## 7. Gear Types

### 7.1 Core Categories

#### 7.1.1 Generators
- Produce forces without requiring input
- Example: "Mainspring - Produces 2 Heat every 3 seconds"

#### 7.1.2 Converters
- Transform one force into another
- Require input to function
- Example: "Precision Gear - Every 5 seconds, consume 3 Heat → 2 Precision"

#### 7.1.3 Card Manipulators
- Provide card draw or deck manipulation
- Critical for sustaining gameplay
- Example: "Chronometer - Every 8 seconds, consume 2 Precision → Draw 1 card"

#### 7.1.4 Damage Dealers
- Convert forces into damage
- May have different targeting patterns
- Example: "Steam Cannon - Every 6 seconds, consume 5 Momentum → 3 damage"

#### 7.1.5 Synergy Gears
- Boost or trigger other gears
- Create combo potential
- Example: "Master Gear - Adjacent gears produce 50% more often"

### 7.2 Special Gear Mechanics

#### 7.2.1 Trigger Effects
- Gears can have various trigger conditions (see Section 6.3)

#### 7.2.2 Death/Destruction Triggers
- Gears can have "on destroyed" effects that trigger when destroyed
- Multiple destructions in same tick = multiple separate triggers
- Death triggers resolve in standard priority order
- "On destroyed" effects trigger regardless of ready state

#### 7.2.3 Simultaneous Placement
- Some effects may place multiple gears at once
- Card must specify placement rules
- Placement order: Main card placed → effect resolves → additional placements
- Forced placement replaces existing gears (top-to-bottom, left-to-right)
- ALWAYS resolve simultaneous ordering questions top to bottom, left to right

#### 7.2.4 Bounce/Return Effects
- Some gears can return to hand instead of discard when destroyed
- Bounced gears lose timer progress always
- Creates card advantage but costs tempo

#### 7.2.5 Copy Effects
- "Copy target gear" must specify what is copied
- Copy cards should have directional requirement
- Fails if no valid target in specified direction

#### 7.2.6 Overbuild Mechanics
- Some gears have "Overbuild" keyword
- When placed on top of another gear, inherit timer progress
- Creates burst potential by building up timer
- Strategic use of ready states and timer management

### 7.3 Example Gears

**"Micro Forge" (Heat/Red Common)**
- Tags: [Micro, Tool]
- Cost: 2 Ticks
- "Fires every 2 Ticks: Produce 1 Heat/Red. Tool gears cost -0.5 Ticks"

**"Crystal Regulator" (Precision/Blue Rare)**
- Tags: [Titan, Crystal]
- Cost: 8 Ticks
- "Fires every 12 Ticks: Produce 5 of any single force. Immovable"

**"Shadow Mechanism" (Entropy/Purple Uncommon)**
- Tags: [Beast, Shadow, Chaos]
- Cost: 4 Ticks
- "Fires every 3 Ticks: Consume 2 Entropy/Purple → 2 damage. +1 damage per Beast, +2 if no adjacent gears"

## 8. Gremlin System (Combat)

### 8.1 Gremlin Structure

#### 8.1.1 Gremlin Composition
- Each combat consists of 1-4 gremlins causing havoc in your mechanism
- Gremlins appear in a column on the right side
- Maximum 5 gremlins at once
- Gremlins have HP values (representing their grip on your mechanism)
- Gremlins are defeated when HP reaches 0 (expelled from the clockwork)
- Victory condition: Expel all gremlins before running out of playable cards
- Destroy effects can target gremlins
- Gremlins do not have force pools

#### 8.1.2 Gremlin Disruptions
Gremlins impose disruptions while infesting your mechanism:

**Passive Disruptions:**
- Force caps - caps don't stack, take lowest
- Production taxes
- Placement restrictions
- Time penalties - stack additively
- Hand restrictions
- Force-specific disruptions
- Production modifiers stack additively
- Decay triggers

**Active Sabotage:**
- Drain forces periodically
- Corrupt gears
- Scramble hand
- Force discards
- Jam mechanisms

### 8.2 Gremlin Types

#### 8.2.1 Common Gremlins
- Dust Mite: Causes minor friction
- Spring Snapper: Breaks tension
- Oil Thief: Steals lubrication

#### 8.2.2 Elite Gremlins
- Gear Grinder: Damages mechanisms
- Time Nibbler: Eats seconds
- Chaos Imp: Randomizes production

#### 8.2.3 Boss Gremlins
- The Rust King: Spreads corrosion
- Chronophage: Devours time itself
- The Grand Saboteur: Master of disruption

## 9. Progression Structure

### 9.1 Run Structure
- 3 acts with increasing difficulty
- Branching path structure
- Each act ends with a boss fight

### 9.2 Node Types
- **Combat**: Standard gremlin encounters
- **Elite Combat**: Harder fights with better rewards
- **Rest Sites**: Opportunities to modify deck or expand movement plate
- **Events**: Text-based choices with various outcomes
- **Workshops**: Spend Inspiration to acquire new cards or upgrades

### 9.3 Rewards
- Card rewards (choose 1 of 3)
- Movement plate expansions
- Temporary upgrades
- Deck manipulation options

### 9.4 Meta Progression (Roguelike with Unlocks)

#### 9.4.1 Horizontal Progression Only
- No power creep - unlocks never make the game easier
- New cards are different, not better
- All unlocks are sidegrades
- Starting deck power level remains constant
- The Wheel's difficulty is immutable

#### 9.4.2 Types of Unlocks
- Alternative cards that can appear in workshops/rewards
- Different starter configurations of equal power
- Cosmetic variations
- Statistics tracking
- Lore entries about The Wheel

#### 9.4.3 Design Philosophy
- True roguelike: Every run starts from the same power level
- Pure skill progression: Players get better, not their tools
- Discovery through play: Unlocks reveal new ways to play, not better ways
- The Wheel is constant: Difficulty never decreases
- A skilled player with zero unlocks has the same win rate as one with all unlocks

## 10. Starting Setup

### 10.1 Initial Combat Setup
- Starting Hand: Draw 5 cards
- Starting Movement Plate: Empty except for starting gear
- Starting Forces: 0 of each force
- Starting Gear: One "Basic Chronometer" automatically in play or guaranteed in starting hand

### 10.2 Starter Deck Composition (7-8 cards)
- 2-3 Basic Generators
- 1-2 Card Draw Gears
- 1 Converter
- 1-2 Utility gears

### 10.3 Starter Gear Examples

**"Basic Chronometer" (Colorless, 1 copy - starts in play)**
- Tags: [Tool, Spark]
- Cost: 2 Ticks
- "Fires every 6 Ticks: Draw 1 card"

**"Simple Mainspring" (Various colors, 2-3 copies)**
- Tags: [Stone]
- Cost: 3 Ticks
- "Fires every 3 Ticks: Produce 2 [Force/Color]" (Each copy produces a specific force)

**"Force Converter" (Colorless, 1 copy)**
- Tags: [Forge]
- Cost: 3 Ticks
- "Fires every 4 Ticks: Consume 2 any force → 3 damage"

## 11. Rules Clarifications

### 11.1 Consumption Timer Behavior

**Ready State Mechanics:**
- When a gear that requires consumption reaches its interval, it enters "ready" state
- Timer stops at maximum (e.g., stays at 3.0/3.0 seconds)
- Gear waits until forces are available
- Checks every 0.1 second tick for required forces
- Once forces available, consumes and produces immediately
- Timer then resets to 0 and begins counting again

**Ready State Interactions:**
- Ready state is purely time-based (not a trigger condition)
- Chain/trigger effects activate the gear's effect regardless of timer state
- If triggered while ready with forces available, produces immediately
- Explicit "all gears produce" effects trigger production (requires forces if needed)

**Overbuild Strategy:**
- Gears with "Overbuild" keyword inherit timer from replaced gear
- Can strategically build up timer on weak gear, then overbuild with strong effect
- Creates burst potential and makes deadlocked gears useful

**Strategic Considerations:**
- Deadlocks can occur (e.g., A needs B's output, B needs A's output)
- Deadlocks are intentional puzzle elements - break with other cards
- Movement plate can become fully "ready" - must overbuild to escape
- Players must balance pure generators vs converters to avoid lockup

### 11.2 Effect Resolution
- Partial effects: Resolve as much as possible
- Exception: "Draw X" effects cause loss if you can't draw; "Reveal X" effects don't
- Multi-part effects must complete all parts if possible
- Consumption failure: If a gear can't consume required forces, effect fails completely
- Destroy vs Sacrifice: Both trigger on-death effects; Sacrifice requires you control the target

### 11.3 Edge Case Rulings
- Simultaneous death: All death triggers happen after all damage dealt
- Victory/Loss timing: Victory checked before loss
- Fractional forces: Tracked to 0.1 precision; consumption requires exact amounts
- Timer inheritance: Only Overbuild or specific mechanics keep timers
- Permanent effects: Persist across combats and zone changes
- Constraint stacking: Caps take lowest value, modifiers stack additively
- Production minimums: Production cannot go below 0
- Deadlock resolution: Circular dependencies are valid puzzles

### 11.4 Priority Conflicts
- Force competition: Resolve top-to-bottom, left-to-right
- Tag changes mid-tick: Gears check tags when they trigger
- Destruction timing: Replacement effects → Death triggers → Placement effects
- Simultaneous triggers: Gears at same interval trigger in placement priority order

## 12. Tutorial Concepts - Essential Rules for Players

### 12.1 Core Concepts (The Basics)
- Gears are your clockwork mechanisms - Cards become gears when placed on the movement plate
- Time only moves when you play cards - Nothing happens between card plays
- Playing cards costs time - Each card shows its time cost in Ticks
- You can replace gears - Play on top of existing ones; old card goes to discard
- Losing conditions - You lose if you can't play a card (empty hand) OR can't draw when required

### 12.2 Production Mechanics (How Things Work)
- Gears produce on intervals - Example: "Every 3 Ticks: Produce 2 Heat"
- The Escapement Order - Top-left gears act first, then left-to-right, top-to-bottom
- Some gears need fuel - Example: "Consume 3 Heat → Produce 2 Precision"
- Hungry gears wait - They reach "ready" state and pause until resources available
- Time advances in Beats - 10 Beats = 1 Tick; all gears check their timers every Beat

### 12.3 Combat Basics (Fighting Gremlins)
- Gremlins disrupt your mechanism - Each adds constraints while alive
- Convert forces to damage - Some gears turn resources into attacks
- Victory condition - Defeat all gremlins before running out of cards
- Gremlin timers - Gremlins activate disruptions every X Ticks

### 12.4 Advanced Concepts (Strategy Layer)
- Tags create synergies - Gears with matching tags boost each other
- Position bonuses - Some movement plate positions grant special effects
- Overbuild inherits timers - Ready gears pass their wound-up timer when replaced
- Inspiration currency - Earn from defeating gremlins, spend at workshops for new cards
- The Wheel - Each run is an attempt to break the cosmic cycle

### 12.5 Critical Warnings (Must Understand)
- Card draw is not automatic - You need gears that specifically draw cards
- Deadlocks are possible - If A needs B's output and B needs A's output, both stuck
- Deck cycling - When deck empties, shuffle discard pile to form new deck
- Simultaneous win/loss - If victory and loss trigger together, victory takes precedence
- Forces are not capped - Unless gremlins add caps, forces can accumulate infinitely
- Time units - Remember: 10 Beats = 1 Tick. Cards cost Ticks, but the game processes every Beat

## 13. Ideas for Future Consideration

### 13.1 Movement Mechanics
- Gears that can move around the movement plate
- "On moved" trigger effects
- Swap positions between gears
- Note: Start without movement mechanics, add if needed for depth

### 13.2 Combat Goals
- Optional objectives during combat for bonus rewards
- Note: Consider adding after core combat is proven fun

### 13.3 Negative Forces
- Forces generated as unwanted byproducts
- Gremlin triggers that activate based on negative force accumulation
- Burn mechanics to dispose of negative forces

## 14. Archived Ideas (Not Currently in Scope)

### 14.1 Mechanics
- Transform gears (deemed unnecessary)
- Replace as keyword (all gears can replace by default)
- Probability-based production (explicitly rejected)
- Building health degradation
- Energy cost beyond time
- Card aging mechanics

### 14.2 Combat Features
- Mana Shield Gremlins
- Oracle Gremlin
- Thief Gremlin (steals cards)
- Lockdown effects (breaks time mechanic)

### 14.3 Force Mechanics
- Complex spoilage stages
- Force quality grades
- Seasonal forces
- Base force caps (rejected for unlimited with gremlin-imposed caps)

### 14.4 Movement Plate Mechanics
- Rotating plate
- Multi-level placement
- Fixed plate size (rejected for expandable)

### 14.5 Alternative Victory Conditions
- Survival mode
- Score attack
- Puzzle mode

These ideas are preserved for potential future development but are not part of the core game design.