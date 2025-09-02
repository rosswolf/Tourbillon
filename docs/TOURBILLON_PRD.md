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
- The ultimate goal: build the "Eternal Complication" that breaks The Wheel permanently

**Visual Direction:**
- Brass, steel, and crystal aesthetics
- Visible gears, springs, and escapements
- Progress bars as tension gauges
- Satisfying mechanical clicks and whirs
- Complications appear as intricate watch mechanisms
- The Wheel looms in the background, slowly turning

## 2. Core Mechanics

### 2.0 Order of Operations

#### 2.0.1 Time System Definitions
- **Beat**: The smallest unit of time (0.1 of a Tick)
- **Tick**: The standard time unit = 10 Beats (what players count and cards cost)
- All time in the game advances in Beats, but players primarily think in Ticks
- Cards show costs in whole Ticks (1, 2, 3, etc.)
- Complications produce on Tick intervals (e.g., "Every 3 Ticks: Produce 2 Heat")

#### 2.0.2 Beat Resolution
When time advances, the game processes every Beat:
1. **Complication Phase**: All complications check/trigger (top-to-bottom, left-to-right)
2. **Poison Resolution**: Poison damage applies based on poison timer (default 10 Beats, modifiable)
3. **Gremlin Phase**: All gremlins check/trigger (top-to-bottom)
4. **End of Beat**: Check for victory/loss conditions (only after full card resolution)

Note: Checking every Beat allows for precise timing and off-Tick effects (e.g., complications that produce every 3.5 Ticks = 35 Beats)

#### 2.0.3 Complication Trigger Rules
- Each complication can only trigger once per Beat maximum (prevents infinite loops)
- Since there are 10 Beats per Tick, a complication can trigger at most 10 times per Tick
- Complications track their own timers independently in Beats
- Complications produce/consume in strict priority order (Escapement Order)
- If Complication A produces forces, Complication B (lower in priority) can consume them same Beat
- Tag counts are checked when each complication triggers (can change mid-Beat)
- Complications have no memory - destroyed/bounced complications lose all timer progress (unless Overbuild)

#### 2.0.4 Card Play Sequence
1. Replace complication on movement plate if necessary (triggers replacement effects)
2. Slot remembers state of old complication
3. Old complication's "when replaced" effects trigger
4. Old complication moved to discard
5. Old complication's "when destroyed" effects trigger
6. New complication played on movement plate
7. New complication's "when played" effects trigger
8. Slot "memory" of old complication is cleared
9. Time advances by card's cost (in Beats: 10 Beats per Tick shown on card)
10. All complications check for production in priority order
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
- Minimum complication trigger interval is 5 Beats (0.5 Ticks)
- When a card is played, global time advances by that amount
- All systems in the game react to this time advancement
- Fractional Ticks only occur through modification effects (e.g., "Micro complications cost -0.5 Ticks")
- Time cannot go backwards (no rewind effects)

#### 2.1.2 Production Intervals
- Each complication has a production interval in Ticks (whole numbers for base: 3, 4, 5 Ticks etc.)
- Time advances in Beats internally for precise tracking
- All fractional results are rounded to nearest Beat
- When time advances, all complications check if their interval threshold is reached
- Complications that hit their interval produce their forces
- Production happens AFTER the new complication is placed, allowing it to potentially produce immediately
- Fractional intervals only occur through modifications (tracked in Beats)

#### 2.1.3 No Turn Structure
- The game has no discrete turns or phases beyond card resolution
- Players can play cards as long as they have cards in hand
- All timing is based on the accumulated time from played cards

### 2.2 Card System

#### 2.2.1 Deck Composition
- Every card represents a complication that can be placed on the movement plate
- Starting deck contains approximately 7-8 cards
- No maximum deck size, but larger decks reduce consistency
- Maximum hand size: 10 cards (can be expanded by certain effects)

#### 2.2.2 Card Flow
- No automatic draw: Players do NOT draw back up to a maximum hand size
- Cards are only drawn through complication effects or other abilities
- When the deck is empty, the discard pile is shuffled to form a new deck
- Destroyed/replaced complications go to the discard pile
- Deck visibility: Can see cards remaining in deck (not order), can see discard pile (with order)
- Tutor effects: Search for specific card, then shuffle deck
- Card Draw Balance: Card draw should not be free but with minimal effort should be sustainable
- Must balance between drawing too many (hand clog) and too few (starvation)

#### 2.2.3 How You Lose
- **Loss Condition 1**: Zero cards in hand after full card resolution (end of turn)
- **Loss Condition 2**: Attempt to draw a card when deck and discard are both empty
- **Loss Condition 3**: Mill a card when deck is empty (from overdraw with full hand)
- When you need to draw and deck is empty, shuffle discard into deck first
- If both deck AND discard are empty when you need to draw, you lose immediately
- **Grace Period**: Loss from empty hand is checked only after current card fully resolves and all triggered effects complete
- If pending complication triggers would draw cards, you survive
- If you achieve victory and loss simultaneously, victory takes precedence
- This makes card draw a critical resource alongside force production
- Gremlin discard effects become extremely threatening

#### 2.2.4 Overdraw and Mill Mechanics
- **Hand Limit**: Maximum 10 cards in hand
- **Overdraw**: If you would draw a card with a full hand (10 cards), mill the top card of your deck instead
- **Mill**: Discarded directly from deck to discard pile without entering hand
- **Mill Loss**: If you must mill but your deck is empty, you lose immediately
- **Strategic Tension**: Mass card draw becomes risky with a full hand
- This prevents infinite draw strategies from dominating

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

### 3.1 Dual Resource System
The game features two types of resources: Basic Forces and Special Resources.

#### 3.1.1 Basic Forces
Five colored forces that gears produce and consume:

- **Red Force** - Raw energy from friction and combustion
- **Blue Force** - Controlled energy from precise mechanisms
- **Green Force** - Kinetic energy from moving parts
- **White Force** - Stable energy from balanced systems
- **Black Force** - Chaotic energy from entropy and decay

#### 3.1.2 Special Resources
Powerful resources created by combining specific Basic Forces. Each Special Resource has unique mechanical effects:

- **🔥 HEAT** - Created from Red and Blue forces
  - Powers pierce damage, momentary effects, and slowing enemies
  - Most efficient for direct combat
  
- **🎯 PRECISION** - Created from Blue and White forces
  - Enables targeted effects, bouncing, and card selection
  - Controls timing and positioning
  
- **🌀 MOMENTUM** - Created from Green and Red forces
  - Provides haste, chains, and cost reduction
  - Accelerates your engine
  
- **⚖️ BALANCE** - Created from White and Black forces
  - Enables execution, suppression, and renewal
  - Maintains stability and control
  
- **💀 ENTROPY** - Created from Black and Green forces
  - Powers poison, sacrifice, and copying effects
  - Breaks normal rules

#### 3.1.3 Resource Production Map
Each Basic Force contributes to exactly two Special Resources:
- **Red**: Creates HEAT and MOMENTUM
- **Blue**: Creates HEAT and PRECISION
- **Green**: Creates MOMENTUM and ENTROPY
- **White**: Creates PRECISION and BALANCE
- **Black**: Creates BALANCE and ENTROPY

This creates natural color pair synergies where pairs that share a Special Resource can produce it more efficiently.

### 3.2 Special Resource Keywords

Each Special Resource grants access to unique keywords and effects:

#### HEAT Keywords
- **PIERCE** - Damage ignores armor
- **MOMENTARY** - One-time burst effects
- **QUICKSTART** - Starts with timer progress
- **SLOW** - Delays enemy actions

#### PRECISION Keywords
- **TARGETED** - Choose specific targets
- **STEADY** - Can't be sped up or slowed
- **BOUNCE** - Return gears to hand
- **SCRY** - Look at and arrange cards

#### MOMENTUM Keywords
- **CHAIN** - Trigger other gears
- **HASTE** - Speed up timers
- **OVERBUILD** - Inherit timer from replaced gear
- **ACCUMULATING** - Build counters over time
- **ENABLING** - Reduce costs

#### BALANCE Keywords
- **EXECUTE** - Instantly kill below threshold
- **POP** - Double damage vs shields
- **SUPPRESS** - Disable disruptions
- **RENEW** - Recover cards from discard
- **IMMOVABLE** - Can't be destroyed

#### ENTROPY Keywords
- **POISON** - Stacking damage over time
- **SACRIFICE** - Destroy own gears for power
- **DOPPELGANGER** - Copy other effects
- **OVERKILL** - Excess damage carries over
- **DEBT** - Gain resources now, pay back later (or get away with it!)

### 3.3 Force Mechanics

#### 3.3.1 Production
- Complications produce Basic Forces when their time interval is reached
- Basic Forces combine to create Special Resources through converter gears
- Printed production amounts are whole numbers (1, 2, 3, etc.)
- Modified production amounts can be fractional (rounded to 0.1)
- Forces and Special Resources stored as fractional values (0.1 precision)
- Some complications may produce multiple force types
- Special Resources are consumed for powerful keyword effects

#### 3.3.2 Round Tracking
- Track statistics per combat: cards played, cards sacrificed, complications destroyed, etc.
- Enables complex scaling triggers and achievements
- Complications can trigger on events other than time (e.g., "When 3rd card played this turn")
- Adds strategic dimensionality beyond pure time management

#### 3.3.3 Consumption-Based Production
- Many gears only produce when they can consume required inputs
- If a gear would produce but cannot consume its requirements, it enters "ready" state
- Timer stops at maximum until forces are available
- Creates supply chain management puzzles
- Gear priority order (top-left to bottom-right) determines consumption order
- Consumption is mandatory unless explicitly stated as optional
- Optional consumption mainly for discard costs ("You may discard a card to...")

#### 3.3.4 Storage and Caps
- **Default: Unlimited storage** - Resources can accumulate infinitely
- **Caps come from Gremlins** - Only gremlin disruptions impose resource caps
- **No player-controlled caps** - Players cannot voluntarily limit their storage
- **Cap effects are disruptions** - Part of the challenge gremlins create
- Example: "Red Cap Gremlin: Your Red Force cannot exceed 5"

#### 3.3.5 Spoilage
- Forces may spoil based on gremlin effects or special rules
- Spoiled forces may disappear or convert to waste
- Waste/pollution mechanics may require management

#### 3.3.6 Payment Types
Cards can require different payment methods for flexibility:

**Specific Color**: "Consume 2 Red" - Takes exactly that Basic Force
**Named Resource**: "Consume 2 HEAT" - Takes exactly that Special Resource  
**Largest**: "Consume 3 Largest" - Automatically takes from your highest resource pool
**Smallest**: "Consume 2 Smallest" - Automatically takes from your lowest pool that can afford the cost

Payment resolution is automatic - no player decisions during payment:
- Largest: Takes from highest pool (ties broken by: Red → Blue → Green → White → Black → HEAT → PRECISION → MOMENTUM → BALANCE → ENTROPY)
- Smallest: Takes from lowest pool that has enough (same tiebreaker order)
- Mixed costs resolve in order listed on the card

#### 3.3.7 Card Power Tiers
Cards are balanced around their resource requirements:

**Basic Tier** - Powered by Basic Forces (colors)
- Simple effects, lower power level
- Accessible early game
- Example: "Consume 2 Red → Deal 2 damage"

**Advanced Tier** - Powered by Special Resources  
- Stronger effects with keywords
- Require conversion infrastructure
- Example: "Consume 2 HEAT → Deal 4 pierce damage"

**Flexible Tier** - Use Largest/Smallest costs
- Work with any resource type
- Less efficient than specific costs
- Example: "Consume 5 Largest → Deal 4 damage"

**Hybrid Tier** - Multiple payment options
- Can be paid different ways
- Efficient with right resources, flexible otherwise
- Example: "Consume 2 Red OR 4 Largest → Produce 1 HEAT"

#### 3.3.8 Conversion Infrastructure
- Basic Forces convert to Special Resources through converter gears
- Conversion ratios vary by combination (typically 2:1 or 3:1)
- Building conversion infrastructure is key to accessing powerful cards
- Some converters are more efficient than others
- Forces can exist in fractional amounts (rounded to 0.1) for more granularity
- Forces can accumulate infinitely (no upper limit)

#### 3.3.9 Universal Effect Efficiency
All colors and resources can produce damage and card draw, but at different efficiencies:

**Damage Efficiency:**
- **Efficient (2:1)**: Red, Green, Black, HEAT, MOMENTUM, ENTROPY
  - 2 resources = 1 damage
  - Red may have rare 1:1 cards
  - HEAT may have rare 1:1 pierce cards
- **Inefficient (3:1)**: Blue, White, PRECISION, BALANCE
  - 3 resources = 1 damage

**Card Draw Efficiency:**
- **Efficient (2:1)**: White, Blue, PRECISION, BALANCE
  - 2 resources = 1 card
  - White may have rare 1:1 cards
- **Inefficient (3:1)**: Red, Green, Black, HEAT, MOMENTUM, ENTROPY
  - 3 resources = 1 card

This ensures every mono-color strategy is viable while maintaining distinct identities.

### 3.4 Inspiration (Per-Run Currency)
- **Inspiration**: Resource earned from defeating gremlins during a run
- Represents mechanical insights gained during this attempt
- Inspiration resets between runs (does not persist)
- Used at workshops within a run to acquire new cards or temporary upgrades
- Regular forces (Red, Blue, Green, White, Black) and Special Resources reset between combats
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

## 7. Complication Types

### 7.1 Core Categories

#### 7.1.1 Generators
- Produce Basic Forces without requiring input
- Example: "Red Generator - Produces 2 Red Force every 3 ticks"

#### 7.1.2 Converters
- Transform Basic Forces into Special Resources
- Require specific force combinations
- Example: "Heat Forge - Every 4 ticks, consume 1 Red + 1 Blue → 1 HEAT"

#### 7.1.3 Card Manipulators  
- Provide card draw or deck manipulation
- Often powered by PRECISION or BALANCE
- Example: "Precision Draw - Every 4 ticks, consume 1 PRECISION → Draw 2 cards"

#### 7.1.4 Damage Dealers
- Convert Special Resources into damage
- May use keywords from their resource type
- Example: "Heat Cannon - Every 3 ticks, consume 2 HEAT → 4 pierce damage"

#### 7.1.5 Synergy Complications
- Boost or trigger other complications
- Create combo potential
- Example: "Master Gear - Adjacent complications produce 50% more often"

### 7.2 Special Complication Mechanics

#### 7.2.1 Trigger Effects
- Complications can have various trigger conditions (see Section 6.3)

#### 7.2.2 Death/Destruction Triggers
- Complications can have "on destroyed" effects that trigger when destroyed
- Multiple destructions in same tick = multiple separate triggers
- Death triggers resolve in standard priority order
- "On destroyed" effects trigger regardless of ready state

#### 7.2.3 Simultaneous Placement
- Some effects may place multiple complications at once
- Card must specify placement rules
- Placement order: Main card placed → effect resolves → additional placements
- Forced placement replaces existing complications (top-to-bottom, left-to-right)
- ALWAYS resolve simultaneous ordering questions top to bottom, left to right

#### 7.2.4 Bounce/Return Effects
- Some complications can return to hand instead of discard when destroyed
- Bounced complications lose timer progress always
- Creates card advantage but costs tempo

#### 7.2.5 Copy Effects
- "Copy target complication" must specify what is copied
- Copy cards should have directional requirement
- Fails if no valid target in specified direction

#### 7.2.6 Overbuild Mechanics
- Some complications have "Overbuild" keyword
- When placed on top of another complication, inherit timer progress
- Creates burst potential by building up timer
- Strategic use of ready states and timer management

### 7.3 Example Gears

#### Basic Force Production (Common)
**"Red Generator"**
- Tags: [Stone]
- Cost: 3 Ticks
- "Fires every 3 Ticks: Produce 2 Red Force"

**"Blue Crystal"**
- Tags: [Crystal]
- Cost: 3 Ticks
- "Fires every 3 Ticks: Produce 2 Blue Force"

#### Basic Force Consumption (Common)
**"Simple Flame"**
- Tags: [Spark]
- Cost: 2 Ticks
- "Consume 2 Red → Deal 2 damage"

**"Emergency Valve"**
- Tags: [Tool]
- Cost: 2 Ticks
- "Consume 4 Largest → Draw 2 cards"

#### Converters (Common)
**"Heat Forge"**
- Tags: [Forge, Tool]
- Cost: 3 Ticks  
- "Fires every 4 Ticks: Consume 1 Red + 1 Blue → Gain 1 HEAT"

**"Precision Engine"**
- Tags: [Crystal, Tool]
- Cost: 3 Ticks
- "Fires every 4 Ticks: Consume 1 Blue + 1 White → Gain 1 PRECISION"

#### Special Resource Cards (Uncommon)
**"Heat Burst"**
- Tags: [Spark]
- Cost: 2 Ticks
- "MOMENTARY: Consume 2 HEAT → Deal 5 pierce damage"

**"Precision Bounce"**
- Tags: [Micro, Tool]
- Cost: 4 Ticks
- "Fires every 3 Ticks: Consume 1 PRECISION → TARGETED bounce, reduce its cost by 1"

#### Flexible Cost Cards (Uncommon)
**"Adaptive Furnace"**
- Tags: [Forge]
- Cost: 4 Ticks
- "Fires every 3 Ticks: Consume 2 Red OR 4 Largest → Produce 1 HEAT"

**"Balanced Strike"**
- Tags: [Weapon]
- Cost: 3 Ticks
- "Consume 3 Smallest → Deal 4 damage, gain 1 BALANCE"

**"Chaos Siphon"**
- Tags: [Void]
- Cost: 5 Ticks
- "Consume 2 Largest + 2 Smallest → Draw 3 cards, gain 2 ENTROPY"

#### Advanced Cards (Rare)
**"Entropy Debt"**
- Tags: [Void, Chaos]
- Cost: 1 Tick
- "DEBT: On Play: Gain 5 ENTROPY. Every 5 Ticks: Pay 3 ENTROPY or get away with it!"

**"Perfect Equilibrium"**
- Tags: [Balance]
- Cost: 6 Ticks
- "If all Basic Forces within 2 of each other: Consume 1 Smallest → Gain 3 BALANCE"

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

**Resource Caps (Primary Disruption):**
- **Gremlins are the ONLY source of resource caps**
- Default game state: unlimited resource storage
- Each gremlin may impose caps on specific resources
- Caps don't stack - take the lowest cap if multiple gremlins
- Example: "Red Cap Gremlin: Red Force cannot exceed 5"
- Example: "Heat Limiter: HEAT cannot exceed 3"
- Defeating the gremlin removes its cap

**Other Passive Disruptions:**
- Production taxes (reduce force generation)
- Placement restrictions (limit where gears can go)
- Time penalties - stack additively
- Hand restrictions
- Force-specific disruptions
- Production modifiers stack additively
- Decay triggers (forces spoil over time)

**Active Sabotage:**
- Drain forces periodically
- Corrupt complications
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

#### 9.3.1 Card Reward Selection
When offered card choices (typically choose 1 of 3):
- **Synergy Weighting**: ~1/3 of offered cards will share a Tag or Color with your existing deck
- **Random Pool**: The other ~2/3 are drawn from the general card pool
- **Smart Offering**: System tracks your most common tags and colors to determine synergies
- This ensures coherent deck building while maintaining variety

**Synergy Detection Algorithm:**
1. Count all tags in current deck (weight by frequency)
2. Count all colors in current deck (weight by frequency)  
3. Track Special Resource usage (converters you have vs consumers)
4. For synergy slots, prioritize cards that:
   - Share the most common tag(s) in deck
   - Match the dominant color(s) in deck
   - Complete converter chains (if you have Red→HEAT converters, offer HEAT consumers)
   - Support existing payment types (if using Largest costs, offer more flexible payments)
5. Avoid offering duplicate cards unless specifically a duplication reward

**Example Card Offering:**
- If your deck has many [Spark] and Red cards:
  - Card 1: Random from any pool
  - Card 2: Guaranteed to have [Spark] tag OR use Red Force
  - Card 3: Random from any pool

**Special Reward Types:**
- **Color-Focused**: All 3 cards from a single color (rare elite rewards)
- **Tag-Themed**: All 3 cards share a specific tag (uncommon events)
- **Converter Package**: Matched converter + consumer pair (workshop specials)
- **Flexible Payment**: At least 1 card uses Largest/Smallest costs (common)

#### 9.3.2 Other Rewards
- Movement plate expansions
- Temporary upgrades
- Deck manipulation options (remove cards, duplicate cards, transform cards)

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
- Starting Movement Plate: Empty except for starting complication
- Starting Forces: 0 of each force
- Starting Complication: One "Basic Chronometer" automatically in play or guaranteed in starting hand

### 10.2 Starter Deck Composition (7-8 cards)
- 2-3 Basic Generators
- 1-2 Card Draw Complications
- 1 Converter
- 1-2 Utility complications

### 10.3 Starter Gear Examples

**"Basic Chronometer" (1 copy - starts in play)**
- Tags: [Tool, Spark]
- Cost: 2 Ticks
- "Fires every 6 Ticks: Draw 1 card"

**"Simple Mainspring" (2-3 copies)**
- Tags: [Stone]
- Cost: 3 Ticks
- "Fires every 3 Ticks: Produce 2 [Force]"

**"Force Converter" (1 copy)**
- Tags: [Forge]
- Cost: 3 Ticks
- "Fires every 4 Ticks: Consume 2 any → 3 damage"

## 11. Rules Clarifications

### 11.1 Consumption Timer Behavior

**Ready State Mechanics:**
- When a complication that requires consumption reaches its interval, it enters "ready" state
- Timer stops at maximum (e.g., stays at 3.0/3.0 seconds)
- Complication waits until forces are available
- Checks every 0.1 second tick for required forces
- Once forces available, consumes and produces immediately
- Timer then resets to 0 and begins counting again

**Ready State Interactions:**
- Ready state is purely time-based (not a trigger condition)
- Chain/trigger effects activate the complication's effect regardless of timer state
- If triggered while ready with forces available, produces immediately
- Explicit "all complications produce" effects trigger production (requires forces if needed)

**Overbuild Strategy:**
- Complications with "Overbuild" keyword inherit timer from replaced complication
- Can strategically build up timer on weak complication, then overbuild with strong effect
- Creates burst potential and makes deadlocked complications useful

**Strategic Considerations:**
- Deadlocks can occur (e.g., A needs B's output, B needs A's output)
- Deadlocks are intentional puzzle elements - break with other cards
- Movement plate can become fully "ready" - must overbuild to escape
- Players must balance pure generators vs converters to avoid lockup

### 11.2 Effect Resolution
- Partial effects: Resolve as much as possible
- Exception: "Draw X" effects cause loss if you can't draw; "Reveal X" effects don't
- Multi-part effects must complete all parts if possible
- Consumption failure: If a complication can't consume required forces, effect fails completely
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
- Tag changes mid-tick: Complications check tags when they trigger
- Destruction timing: Replacement effects → Death triggers → Placement effects
- Simultaneous triggers: Complications at same interval trigger in placement priority order

## 12. Tutorial Concepts - Essential Rules for Players

### 12.1 Core Concepts (The Basics)
- Complications are your clockwork mechanisms - Cards become complications when placed on the movement plate
- Time only moves when you play cards - Nothing happens between card plays
- Playing cards costs time - Each card shows its time cost in Ticks
- You can replace complications - Play on top of existing ones; old card goes to discard
- Losing conditions - You lose if you can't play a card (empty hand) OR can't draw when required

### 12.2 Production Mechanics (How Things Work)
- Complications produce on intervals - Example: "Every 3 Ticks: Produce 2 Heat"
- The Escapement Order - Top-left complications act first, then left-to-right, top-to-bottom
- Some complications need fuel - Example: "Consume 3 Heat → Produce 2 Precision"
- Hungry complications wait - They reach "ready" state and pause until resources available
- Time advances in Beats - 10 Beats = 1 Tick; all complications check their timers every Beat

### 12.3 Combat Basics (Fighting Gremlins)
- Gremlins disrupt your mechanism - Each adds constraints while alive
- Convert forces to damage - Some complications turn resources into attacks
- Victory condition - Defeat all gremlins before running out of cards
- Gremlin timers - Gremlins activate disruptions every X Ticks

### 12.4 Advanced Concepts (Strategy Layer)
- Tags create synergies - Complications with matching tags boost each other
- Position bonuses - Some movement plate positions grant special effects
- Overbuild inherits timers - Ready complications pass their wound-up timer when replaced
- Inspiration currency - Earn from defeating gremlins, spend at workshops for new cards
- The Wheel - Each run is an attempt to break the cosmic cycle

### 12.5 Critical Warnings (Must Understand)
- Card draw is not automatic - You need complications that specifically draw cards
- Deadlocks are possible - If A needs B's output and B needs A's output, both stuck
- Deck cycling - When deck empties, shuffle discard pile to form new deck
- Simultaneous win/loss - If victory and loss trigger together, victory takes precedence
- Forces are not capped - Unless gremlins add caps, forces can accumulate infinitely
- Time units - Remember: 10 Beats = 1 Tick. Cards cost Ticks, but the game processes every Beat

## 13. User Interface Requirements

### 13.1 Card Efficiency Display
To help players understand resource economics, cards should display efficiency metrics at the bottom:

#### For Gear Cards (Repeating Effects):
- **Production Rate**: "Efficiency: X resources/tick" (e.g., "Efficiency: 0.83 Red/tick")
- **Consumption Rate**: "Consumption: Y resources/tick" (e.g., "Consumption: 0.5 Blue/tick")
- **Net Rate**: For converters, show both (e.g., "Consumes: 0.5 Red/tick → Produces: 0.25 HEAT/tick")

#### For Instant Effects:
- **Cost Efficiency**: "Cost: X per effect" (e.g., "2 Red per damage")
- **Flexible Costs**: Show all options (e.g., "2 Red OR 4 Largest per damage")

#### Display Format:
- Small text at bottom of card
- Use fractional display when appropriate (0.5, 0.83, etc.)
- Color-code by resource type
- Update dynamically with modifiers

### 13.2 Resource Display
- Show current resources with decimal precision (e.g., "Red: 3.5")
- Group Basic Forces and Special Resources separately
- Highlight which resource is "Largest" and "Smallest" with icons

## 14. Ideas for Future Consideration

### 14.1 Movement Mechanics
- Complications that can move around the movement plate
- "On moved" trigger effects
- Swap positions between complications
- Note: Start without movement mechanics, add if needed for depth

### 14.2 Combat Goals
- Optional objectives during combat for bonus rewards
- Note: Consider adding after core combat is proven fun

### 14.3 Negative Forces
- Forces generated as unwanted byproducts
- Gremlin triggers that activate based on negative force accumulation
- Burn mechanics to dispose of negative forces

## 15. Archived Ideas (Not Currently in Scope)

### 15.1 Mechanics
- Transform complications (deemed unnecessary)
- Replace as keyword (all complications can replace by default)
- Probability-based production (explicitly rejected)
- Building health degradation
- Energy cost beyond time
- Card aging mechanics

### 15.2 Combat Features
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