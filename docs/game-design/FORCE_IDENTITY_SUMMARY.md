# Force Identity Summary - Quick Reference

## Core Design Philosophy
Each force has EXCLUSIVE mechanical effects that only it can produce efficiently. This prevents "rainbow" builds and forces meaningful specialization.

## The 5 Forces at a Glance

### 🔥 Heat (Red) = DAMAGE
**What it does:** Kills things
- Direct damage (1 Heat = 1 damage)
- Burn (damage over time)
- Pierce (ignores shields)
- Overkill (excess carries over)

**You need Heat if:** You want to actually defeat gremlins

---

### 🎯 Precision (Blue) = CARDS & TEMPO
**What it does:** Controls cards and timing
- Draw cards (2 Precision = 1 card)
- Bounce gears back to hand
- Search for specific cards
- Reduce replay costs

**You need Precision if:** You want card advantage and tempo plays

---

### 🌀 Momentum (Green) = SPEED & EFFICIENCY
**What it does:** Makes things happen faster and cheaper
- Reduce card costs
- Speed up all gears
- Trigger gears extra times
- Chain reactions
- Free plays (0 tick cards)

**You need Momentum if:** You want a fast, efficient engine

---

### ⚖️ Balance (White) = DEFENSE
**What it does:** Keeps you alive
- Create shields (1 Balance = 1 shield)
- Make gears immovable
- Cleanse disruptions
- Prevent loss conditions

**You need Balance if:** You want to survive big hits

---

### 💜 Entropy (Purple) = CHAOS & FLEXIBILITY
**What it does:** Wild card effects
- Acts as any force (inefficient)
- Sacrifice your gears for power
- Apply poison
- Transform resources
- DEBT: Borrow resources now, pay later (or get away with it!)

**You need Entropy if:** You want flexibility, sacrifice synergies, or risky resource gambling

## Why This Creates Depth

### Can't Do Everything
- Heat decks need Precision for cards
- Precision decks need Heat to win
- Balance decks need damage somewhere
- You must choose 2-3 forces to focus on

### Build Identity Examples

**Red/Blue (Heat + Precision)**
- Burn through deck quickly
- Tempo plays with bounce
- Classic aggro-control

**Green/Red (Momentum + Heat)**
- Turbo damage
- Everything fires constantly
- Pure aggression

**White/Purple (Balance + Entropy)**
- Defensive grind
- Sacrifice for value
- Outlast and poison

**Blue/Green (Precision + Momentum)**
- Card engine supreme
- Infinite loops possible
- Combo-focused

## Hand Size Philosophy

**Base Hand Size: 10 cards**
- Rarely modified (maybe 1-2 cards in entire game can affect)
- Not a force effect - too powerful
- Creates tension with card draw

**Why Limited:**
- Forces hard decisions
- Prevents hoarding
- Makes overdraw meaningful
- Adds skill to hand management

## Bounce as Tempo Tool

Bounce creates interesting decisions:
- **Reset timer** - Bounced gear loses progress
- **Reuse effects** - "On play" triggers again
- **Save from destruction** - Defensive option
- **Hand space tension** - Bounce clogs hand

**Example Bounce Cards:**
```
"Precision Recall"
Consume 3 Precision → Bounce target gear, reduce its cost by 1

"Emergency Return"
Momentary: Consume 2 Precision → Bounce all your gears

"Tempo Shift"
Every 4 Ticks: Consume 1 Precision → Bounce lowest-cost gear
```

## Implementation Checklist

✅ **Step 1:** Make damage Heat-exclusive
✅ **Step 2:** Make card draw Precision-exclusive
✅ **Step 3:** Make shields Balance-exclusive
✅ **Step 4:** Make speed Momentum-exclusive
✅ **Step 5:** Add bounce to Precision
✅ **Step 6:** Remove hand size modifications
✅ **Step 7:** Make Entropy the "wild" force

## Force Conversion Rules

### Efficient (Intended Use)
- 1 Heat → 1 damage
- 2 Precision → 1 card
- 1 Balance → 1 shield
- 3 Momentum → 1 extra trigger
- 2 Entropy → 1 of any force

### Inefficient (Emergency Only)
- 3 Any Force → 1 damage (except Heat: always 1:1)
- 4 Any Force → 1 card (except Precision: always 2:1)
- 2 Any Force → 1 shield (except Balance: always 1:1)

This 3:1 or 4:1 penalty makes specialization crucial while allowing desperate plays.

## The Result

Forces now have strong mechanical identity:
- **Choices matter** - Can't just produce any force
- **Specialization rewarded** - Efficient ratios for intended use
- **Flexibility costly** - Can emergency convert but it hurts
- **Build diversity** - Different force pairs play differently
- **Counterplay exists** - Gremlins can target specific forces