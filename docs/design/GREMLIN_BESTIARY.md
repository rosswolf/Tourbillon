# Gremlin Bestiary - Design Reference

## Overview

This document provides concrete gremlin designs across all difficulty tiers, showcasing the encounter archetypes defined in ENCOUNTER_DESIGN_ARCHETYPES.md. Each gremlin demonstrates specific mechanical concepts while fitting into the broader strategic ecosystem.

## Design Principles

### Power Scaling by Tier
- **Small (5-15 HP)**: Single constraint, basic defenses, teaching mechanics
- **Medium (20-40 HP)**: Dual mechanics, moderate defenses, strategic choices  
- **Large (50-80 HP)**: Multi-system interactions, advanced defenses, deep decisions
- **Elite (60-120 HP)**: Complex move cycles, unique mechanics, skill gates
- **Boss (100-200 HP)**: Phase transitions, multiple simultaneous systems, mastery tests

### Summoning Rules
- **Summon Position**: Where new gremlins appear in the stack
- **Summon Timing**: How often and under what conditions
- **Summon Strength**: Power level of summoned creatures
- **Summon Cap**: Maximum number that can be summoned

---

## Gnats (Swarm Fodder)

### **Basic Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Archetype**: Pure fodder - Clogs targeting, minimal threat

**Single Move**:
- **Move 1**: No effect (pure blocker)

**Strategy**: Forces AOE damage to be efficient. Vulnerable to any damage source. Main purpose is protection and targeting interference.

---

### **Barrier Gnat**  
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Barrier**: Absorbs first hit completely
**Archetype**: Protected fodder - Tests multi-hit strategies

**Single Move**:
- **Move 1**: No effect (pure blocker)

**Strategy**: First hit destroys the barrier, second hit kills the 1 HP gnat. Requires exactly 2 hits regardless of damage amounts. Makes single big attacks inefficient, encourages multi-hit or chain effects.

---

### **Constricting Barrier Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0  
**Barrier**: Absorbs first hit completely
**Archetype**: Protected constraint - Super annoying disruption

**Single Move**:
- **Move 1**: Max any resource soft capped at 5

**Strategy**: Extremely annoying - protected by barrier AND limits your biggest resource. High priority for multi-hit removal.

---

### **Draining Barrier Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Barrier**: Absorbs first hit completely  
**Archetype**: Protected disruption - Persistent annoyance

**Single Move**:
- **Move 1**: Every 6 ticks, drain 2 random force

**Strategy**: Protected persistent drain. Much more threatening than regular Drain Gnat due to barrier protection.

---

### **Toxic Barrier Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Barrier**: Absorbs first hit completely
**Archetype**: Protected constraint - Special resource disruption  

**Single Move**:
- **Move 1**: All Special Resources soft capped at 2

**Strategy**: Devastates advanced strategies by limiting HEAT, PRECISION, etc. Protected by barrier makes it incredibly frustrating.

---

### **Breeding Barrier Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Barrier**: Absorbs first hit completely
**Archetype**: Protected multiplier - Nightmare swarm source

**Single Move**:
- **Move 1**: Every 10 ticks, summon Basic Gnat at bottom of stack

**Summon Cap**: 3 total gnats from this source
**Strategy**: Self-replacing AND barrier protected. Absolute priority target. Requires multi-hit to stop the breeding cycle.

---

### **Drain Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Archetype**: Annoying fodder - Small but persistent disruption

**Single Move**:
- **Move 1**: Every 8 ticks, drain 1 random force

**Strategy**: Minimal disruption that becomes annoying in groups. Low priority target unless swarming.

---

### **Breeding Gnat**
**HP**: 1 | **Armor**: 0 | **Shields**: 0
**Archetype**: Self-replacing fodder - Creates endless problems

**Single Move**:
- **Move 1**: Every 12 ticks, summon Basic Gnat at bottom of stack

**Summon Cap**: 2 total gnats from this source
**Strategy**: Self-sustaining annoyance. Priority target to stop reproduction.

---

## Small Gremlins (Tutorial & Fodder)

### **Dust Mite** - Rush Threat
**HP**: 8 | **Armor**: 0 | **Shields**: 0
**Archetype**: Rush Threat - Forces immediate action

**Single Move**:
- **Move 1**: Heat soft capped at 4

**Strategy**: Teach players about soft caps and spending resources under pressure. Dies quickly to any focused damage.

---

### **Gear Tick** - Disruption Threat  
**HP**: 12 | **Armor**: 0 | **Shields**: 0
**Archetype**: Disruption Threat - Makes everything harder

**Single Move**:
- **Move 1**: All cards cost +1 tick

**Strategy**: Teaches timing pressure and efficiency. Forces players to consider card sequencing.

---

### **Rust Speck** - Turtle Threat
**HP**: 6 | **Armor**: 3 | **Shields**: 0  
**Archetype**: Turtle Threat - Tests sustained damage

**Single Move**:
- **Move 1**: Precision soft capped at 3

**Strategy**: High armor relative to HP teaches armor penetration and sustained pressure. Shows that small enemies can be tough.

---

## Medium Gremlins (Core Encounters)

### **Spring Snapper** - Scaling Threat
**HP**: 35 | **Armor**: 1 | **Shields**: 0
**Archetype**: Scaling Threat - Gets worse over time

**Move Cycle** (Each move lasts until it fires):
- **Move 1**: Every 8 ticks, drain 2 Momentum (switches to Move 2)
- **Move 2**: Every 6 ticks, drain 3 Momentum (switches to Move 3)  
- **Move 3**: Every 4 ticks, drain 4 Momentum (switches to Move 1)

**Strategy**: Demonstrates escalating pressure. Players must eliminate it before the drains become unsustainable.

---

### **Oil Thief** - Resource Vampire
**HP**: 28 | **Armor**: 0 | **Shields**: 5
**Shield Regen**: 1 per tick (max 8)
**Archetype**: Turtle + Rush combination

**Move Cycle**:
- **Move 1**: All forces hard capped at 6 (lasts 10 ticks, switches to Move 2)
- **Move 2**: Every 3 ticks, drain 3 largest force (switches to Move 1 after 3 activations)

**Strategy**: Dual threat - hard caps force immediate spending, then drains punish accumulation. Regenerating shields reward sustained damage.

---

### **Chaos Imp** - Multi-Target Synergy  
**HP**: 25 | **Armor**: 2 | **Shields**: 0
**Archetype**: Synergy Threat - Enhances other gremlins

**Move Cycle**:
- **Move 1**: Other gremlins drain +1 additional of each resource type (passive)
- **Move 2**: Every 5 ticks, all gremlins gain 3 shields (switches to Move 1)

**Strategy**: Force multiplier that makes other encounters significantly harder. High priority target in multi-gremlin fights.

---

### **Gnat Spawner** - Summoning Threat
**HP**: 30 | **Armor**: 0 | **Shields**: 0  
**Archetype**: Summoning Threat - Board control

**Move Cycle**:
- **Move 1**: Every 6 ticks, summon Dust Mite at bottom of stack
- **Move 2**: Every 8 ticks, summon 2 Dust Mites at bottom of stack  
- **Move 3**: Every 10 ticks, summon 3 Dust Mites at bottom of stack

**Summon Cap**: Maximum 4 summoned gremlins at once
**Strategy**: Tests Attack (Most HP) vs Attack (Basic) targeting. Green excels here, Red struggles with protected summoner.

---

## Large Gremlins (Advanced Encounters)

### **Gear Grinder** - Armored Berserker
**HP**: 75 | **Armor**: 6 | **Shields**: 0
**Archetype**: Turtle Threat with escalating offense

**Move Cycle**:
- **Move 1**: Balance soft capped at 2 (lasts 12 ticks)
- **Move 2**: Every 4 ticks, drain 5 largest force + gain 2 armor (max 12 total armor)
- **Move 3**: Every 3 ticks, drain 6 largest force + all cards cost +2 ticks

**Strategy**: Becomes more dangerous over time. Heavy armor encourages pierce damage or execution strategies.

---

### **Time Nibbler** - Complex Controller
**HP**: 65 | **Armor**: 2 | **Shields**: 10
**Shield Regen**: 2 per tick (max 15)
**Damage Cap**: 8 per hit
**Archetype**: Disruption + Turtle combination

**Move Cycle**:
- **Move 1**: All forces decay by 1 every 3 ticks (lasts 15 ticks)
- **Move 2**: Hand size reduced to 6, no card draw allowed (lasts 10 ticks)  
- **Move 3**: Every 2 ticks, force discard 1 card (lasts until 4 activations)

**Strategy**: Multi-layered disruption with strong defenses. Damage cap prevents burst strategies. Tests adaptation and resource management.

---

### **Echo Chamber** - Position Controller
**HP**: 55 | **Armor**: 0 | **Shields**: 0
**Special**: Cannot be targeted while other gremlins exist
**Archetype**: Protected Synergy Threat

**Single Move**:
- **Move 1**: Every 4 ticks, summon random medium gremlin at top of stack (max 3 total gremlins)

**Strategy**: Forces players to clear minions repeatedly while the real threat hides. Tests targeting variety and threat prioritization.

---

## Elite Gremlins (Skill Gates)

### **The Constraint Engine** - Multi-System Controller
**HP**: 95 | **Armor**: 3 | **Shields**: 8  
**Shield Regen**: 1 per tick (max 12)
**Reflect**: 25% damage reflected
**Archetype**: Master of multiple constraint types

**Complex Move Cycle**:
- **Move 1**: Total resources hard capped at 10 (lasts 8 ticks)
- **Move 2**: Max any resource hard capped at 4 (lasts 6 ticks)
- **Move 3**: Every 3 ticks, drain 2 of each force type (switches after 3 activations)
- **Move 4**: All previous constraints active simultaneously (lasts 5 ticks, then restart)

**Strategy**: Tests mastery of constraint management and resource efficiency. Each phase requires different tactical approaches.

---

### **Temporal Glutton** - Escalating Summoner
**HP**: 110 | **Armor**: 4 | **Shields**: 15
**Shield Regen**: 3 per tick (max 20)  
**Archetype**: Protected summoner with escalating threats

**Escalating Move Cycle**:
- **Move 1**: Every 8 ticks, summon 1 small gremlin at bottom
- **Move 2**: Every 6 ticks, summon 1 medium gremlin at bottom  
- **Move 3**: Every 8 ticks, summon 1 large gremlin at bottom
- **Move 4**: Every 6 ticks, summon 2 medium gremlins at bottom (then restart at Move 1)

**Summon Cap**: 5 total gremlins
**Strategy**: Ramp-up encounter that becomes overwhelming if not addressed quickly. Tests burst damage vs sustained elimination.

---

### **The Balanced Paradox** - Execution Counter
**HP**: 85 | **Armor**: 8 | **Shields**: 0
**Execute Immunity**: Cannot be executed while above 25 HP
**Archetype**: Anti-execution specialist

**Move Cycle**:
- **Move 1**: Entropy hard capped at 1, Balance hard capped at 1 (counters execution strategies)
- **Move 2**: Every 4 ticks, drain 4 Balance + 4 Entropy specifically  
- **Move 3**: Gains 3 armor, all forces soft capped at 8 (forces alternative strategies)

**Strategy**: Hard counter to Balance/Black execution strategies. Forces diverse damage approaches and resource management.

---

## Boss Gremlins (Mastery Tests)

### **The Rust King** - Phase Transition Boss
**Phase 1 HP**: 150 | **Phase 2 HP**: 100
**Phase 1**: **Armor**: 10 | **Shields**: 0
**Phase 2**: **Armor**: 5 | **Shields**: 20 (regen 4/tick, max 25)

**Phase 1 - "The Spreading Corruption"**:
- **Passive**: All forces decay by 2 every 5 ticks
- **Move 1**: Total resources hard capped at 15 (lasts 10 ticks)
- **Move 2**: Every 3 ticks, all gremlins gain 2 armor (switches after 4 activations)

**Phase Transition** (at 0 HP): 
- Armor reduced, gains massive shields and regeneration
- Summons 2 medium gremlins
- Changes move pattern entirely

**Phase 2 - "The Desperate Stand"**:
- **Passive**: Hand size reduced to 7
- **Move 1**: Every 2 ticks, drain 3 largest + 3 smallest forces
- **Move 2**: Every 4 ticks, force discard 2 cards (switches after 3 activations)

**Strategy**: Two completely different encounters in sequence. Phase 1 tests resource management under pressure. Phase 2 tests burst damage and hand management.

---

### **Chronophage** - Ultimate Time Controller  
**HP**: 180 | **Armor**: 12 | **Shields**: 30
**Shield Regen**: 5 per tick (max 40)
**Damage Cap**: 12 per hit
**Archetype**: Master of time manipulation

**Dynamic Move System** (moves change based on current HP):
- **100%+ HP**: All cards cost +3 ticks, forces decay by 3 every 2 ticks
- **75%+ HP**: Every 2 ticks, drain 4 of each force type
- **50%+ HP**: Cannot draw cards, hand shuffled every 6 ticks
- **25%+ HP**: All previous effects active + every tick, force discard 1 card
- **<25% HP**: "Temporal Collapse" - all constraints removed, but gains 5 armor

**Strategy**: Escalating constraint puzzle that tests every aspect of player mastery. Final phase rewards survival with constraint removal but increased defense.

---

### **The Grand Saboteur** - Adaptive Counter-Boss
**HP**: 200 | **Armor**: 8 | **Shields**: 0
**Special**: Adapts moves based on player strategy
**Archetype**: AI that learns and counters player patterns

**Adaptive Move System**:
- **Anti-Red**: If player uses mostly Red damage → gains damage reflection + AOE immunity
- **Anti-Execution**: If player attempts execution → becomes immune to execution, drains Balance/Entropy
- **Anti-Summoner**: If encounter has other gremlins → kills 1 random other gremlin, gains their HP
- **Anti-Engine**: If player has 8+ complications → every 2 ticks, destroy 1 random complication

**Base Moves** (when no pattern detected):
- **Move 1**: Random force hard capped at 3 (changes which force every 6 ticks)  
- **Move 2**: Every 4 ticks, copy the effect of player's most recently played card

**Strategy**: Ultimate skill test that punishes over-reliance on single strategies. Requires diverse tactical approaches and adaptation.

---

## Summoned Creatures Reference

### **Summoned by Gnat Spawner**:
**Dust Mite**: 8 HP, Heat soft cap 4 (as above)

### **Summoned by Temporal Glutton**:
- **Small**: Choose from Dust Mite, Gear Tick, Rust Speck
- **Medium**: Choose from Spring Snapper, Oil Thief (reduced stats)
- **Large**: Scaled-down versions of large gremlins (60% stats)

### **Summoned by Echo Chamber**:
- **Random Medium**: Full-power medium gremlins from available pool

---

## Design Notes

### **Encounter Combinations**
- **Rush + Turtle**: Oil Thief demonstrates dual pressure types
- **Scaling + Summoning**: Temporal Glutton shows escalating board states
- **Synergy + Protection**: Echo Chamber creates priority puzzles
- **Multi-Constraint**: Constraint Engine tests resource mastery

### **Counter-Play Examples**
- **vs Summoners**: Green (Attack Most HP) cuts to source
- **vs Swarms**: Red (Attack All) clears efficiently  
- **vs Tanks**: Execution strategies or sustained pierce damage
- **vs Controllers**: Burst damage before constraints activate

### **Difficulty Progression**
- **Act 1**: Small + Medium gremlins, single mechanics
- **Act 2**: Large + combinations, dual mechanics  
- **Act 3**: Elite + Boss encounters, complex interactions

### **Balance Guidelines**
- **Small**: 1-2 turns to kill with basic strategies
- **Medium**: 3-5 turns, require some optimization
- **Large**: 5-8 turns, demand strategic adaptation
- **Elite**: 6-10 turns, test specific skills
- **Boss**: 10-15 turns, comprehensive mastery tests

---

This bestiary provides a complete reference for gremlin encounters across all difficulty levels, demonstrating how the encounter archetype system creates diverse, engaging combat scenarios that scale appropriately with player progression.