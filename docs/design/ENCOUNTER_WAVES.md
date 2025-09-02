# Encounter Waves - Gremlin Combinations

## Overview

This document defines specific encounter waves that combine gremlins from the bestiary into cohesive strategic challenges. Each wave represents a different encounter archetype with calculated difficulty ratings based on HP totals, defensive mechanics, and constraint complexity.

## Difficulty Rating System

### **Base Difficulty Calculation**
**Formula**: `Base Difficulty = Total HP + Armor Modifier + Shield Modifier + Constraint Modifier`

**Modifiers**:
- **Armor Modifier**: Armor × 2 (represents damage mitigation)  
- **Shield Modifier**: Max Shields × 1.5 + (Regen × 3) (accounts for regeneration)
- **Constraint Modifier**: Number of active constraints × 5
- **Synergy Modifier**: +10 per gremlin that enhances others
- **Barrier Modifier**: +8 per barrier (requires 2 hits regardless of damage)

### **Difficulty Tiers**
- **Trivial (1-15)**: Tutorial encounters, single weak enemy
- **Easy (16-35)**: Basic encounters, simple mechanics  
- **Medium (36-60)**: Standard encounters, dual mechanics
- **Hard (61-90)**: Advanced encounters, complex interactions
- **Extreme (91-120)**: Elite encounters, mastery tests
- **Nightmare (121+)**: Boss encounters, multiple complex systems

---

## Act 1 Waves (Tutorial & Learning)

### **Wave 1A: "First Contact"**
**Enemies**: 1× Dust Mite (8 HP)

**Difficulty Calculation**:
- Total HP: 8
- Constraints: 1 (Heat soft cap 4) = +5
- **Total Difficulty: 13 (Trivial)**

**Archetype**: Rush Threat - Single Constraint
**Strategy**: Teaches soft caps and resource spending pressure
**Counter**: Any basic damage, spend Heat before cap

---

### **Wave 1B: "Mechanical Disruption"**  
**Enemies**: 1× Gear Tick (12 HP)

**Difficulty Calculation**:
- Total HP: 12
- Constraints: 1 (Cards cost +1 tick) = +5  
- **Total Difficulty: 17 (Easy)**

**Archetype**: Disruption Threat - Timing Penalty
**Strategy**: Teaches timing efficiency and card sequencing
**Counter**: Efficient card plays, minimize waste

---

### **Wave 1C: "Armored Introduction"**
**Enemies**: 1× Rust Speck (6 HP, 3 Armor)

**Difficulty Calculation**:
- Total HP: 6
- Armor: 3 × 2 = +6
- Constraints: 1 (Precision soft cap 3) = +5
- **Total Difficulty: 17 (Easy)**

**Archetype**: Turtle Threat - Armor Tutorial  
**Strategy**: Teaches armor mechanics and sustained damage
**Counter**: Pierce damage or sustained attacks

---

### **Wave 1D: "Swarm Basics"**
**Enemies**: 3× Basic Gnat (1 HP each)

**Difficulty Calculation**:
- Total HP: 3
- Constraints: 0 = +0
- **Total Difficulty: 3 (Trivial)**

**Archetype**: Pure Swarm - AOE Tutorial
**Strategy**: Teaches AOE vs single-target efficiency  
**Counter**: Red (Attack All) or any AOE damage

---

## Act 1 Advanced Waves

### **Wave 1E: "Protected Pest"**
**Enemies**: 1× Constricting Barrier Gnat (1 HP, Barrier)

**Difficulty Calculation**:
- Total HP: 1
- Barrier: 1 × 8 = +8
- Constraints: 1 (Max resource soft cap 5) = +5
- **Total Difficulty: 14 (Trivial)**

**Archetype**: Protected Constraint - Multi-Hit Tutorial
**Strategy**: Teaches multi-hit strategies vs barriers
**Counter**: Chain effects, multi-hit attacks, or 2+ small attacks

---

### **Wave 1F: "Escalating Pressure"**
**Enemies**: 1× Spring Snapper (35 HP, 1 Armor)

**Difficulty Calculation**:
- Total HP: 35
- Armor: 1 × 2 = +2
- Constraints: 1 (escalating drains) = +5
- **Total Difficulty: 42 (Medium)**

**Archetype**: Scaling Threat - Time Pressure
**Strategy**: Teaches elimination priority and timing
**Counter**: Focused burst damage before escalation

---

## Act 2 Waves (Core Mechanics)

### **Wave 2A: "Turtle and Rush"**
**Enemies**: 1× Oil Thief (28 HP, 5 Shields, 1 regen), 2× Dust Mite (8 HP each)

**Difficulty Calculation**:  
- Total HP: 44
- Shields: 8 × 1.5 + (1 × 3) = 15
- Constraints: 2 (hard cap + drains) × 5 = +10
- **Total Difficulty: 69 (Hard)**

**Archetype**: Turtle + Rush Combination
**Strategy**: Tests priority targeting - rush vs turtle elimination
**Counter**: Decide whether to kill rush threats first or focus turtle

---

### **Wave 2B: "Synergistic Chaos"**
**Enemies**: 1× Chaos Imp (25 HP, 2 Armor), 1× Spring Snapper (35 HP, 1 Armor)

**Difficulty Calculation**:
- Total HP: 60  
- Armor: 3 × 2 = +6
- Constraints: 2 (scaling + synergy) × 5 = +10
- Synergy: 1 × 10 = +10 (Imp enhances others)
- **Total Difficulty: 86 (Hard)**

**Archetype**: Synergy + Scaling Threat
**Strategy**: Tests understanding of force multiplication
**Counter**: Kill Chaos Imp first to remove damage boost

---

### **Wave 2C: "The Gnat Problem"** 
**Enemies**: 1× Gnat Spawner (30 HP), 3× Barrier Gnat (1 HP, Barrier each)

**Difficulty Calculation**:
- Total HP: 33
- Barriers: 3 × 8 = +24
- Constraints: 0 = +0  
- **Total Difficulty: 57 (Medium)**

**Archetype**: Summoning + Protection
**Strategy**: Tests Green (Attack Most HP) vs multi-hit strategies
**Counter**: Green targets spawner, or multi-hit to clear barriers first

---

### **Wave 2D: "Resource Stranglehold"**
**Enemies**: 1× Constricting Barrier Gnat (1 HP, Barrier), 1× Draining Barrier Gnat (1 HP, Barrier), 1× Toxic Barrier Gnat (1 HP, Barrier)

**Difficulty Calculation**:
- Total HP: 3
- Barriers: 3 × 8 = +24
- Constraints: 3 × 5 = +15
- **Total Difficulty: 42 (Medium)**

**Archetype**: Multi-Constraint Swarm
**Strategy**: Tests multi-hit efficiency vs protected constraints
**Counter**: Chain attacks or multi-hit abilities essential

---

## Act 2 Elite Waves

### **Wave 2E: "Armored Assault"**
**Enemies**: 1× Gear Grinder (75 HP, 6 Armor), 2× Rust Speck (6 HP, 3 Armor each)

**Difficulty Calculation**:
- Total HP: 87
- Armor: 12 × 2 = +24
- Constraints: 2 (Balance cap + escalating effects) × 5 = +10
- **Total Difficulty: 121 (Nightmare)**

**Archetype**: Heavy Turtle + Support
**Strategy**: Tests pierce strategies and sustained damage
**Counter**: Pierce damage essential, or very sustained pressure

---

### **Wave 2F: "The Spawning Nightmare"**  
**Enemies**: 1× Temporal Glutton (110 HP, 4 Armor, 15 Shields, 3 regen), 1× Breeding Barrier Gnat (1 HP, Barrier)

**Difficulty Calculation**:
- Total HP: 111
- Armor: 4 × 2 = +8  
- Shields: 20 × 1.5 + (3 × 3) = 39
- Constraints: 1 (escalating summons) × 5 = +5
- Barriers: 1 × 8 = +8
- **Total Difficulty: 171 (Nightmare)**

**Archetype**: Elite Summoner + Protected Support
**Strategy**: Ultimate summoning challenge with protection
**Counter**: Burst damage on Glutton or multi-hit to stop breeding

---

## Act 3 Waves (Mastery Tests)

### **Wave 3A: "The Constraint Engine"**
**Enemies**: 1× The Constraint Engine (95 HP, 3 Armor, 8 Shields, 1 regen), 2× Constricting Barrier Gnat (1 HP, Barrier each)

**Difficulty Calculation**:
- Total HP: 97
- Armor: 3 × 2 = +6
- Shields: 12 × 1.5 + (1 × 3) = 21  
- Barriers: 2 × 8 = +16
- Constraints: 6 (multiple complex caps) × 5 = +30
- **Total Difficulty: 170 (Nightmare)**

**Archetype**: Multi-System Controller + Protection
**Strategy**: Tests mastery of all constraint types
**Counter**: Multi-hit for gnats, then sustained efficient damage

---

### **Wave 3B: "Echoing Madness"**
**Enemies**: 1× Echo Chamber (55 HP, Protected), 1× Chaos Imp (25 HP, 2 Armor), 1× Oil Thief (28 HP, 5 Shields, 1 regen)

**Difficulty Calculation**:
- Total HP: 108  
- Armor: 2 × 2 = +4
- Shields: 8 × 1.5 + (1 × 3) = 15
- Constraints: 4 (caps + drains + synergy) × 5 = +20
- Synergy: 1 × 10 = +10 (Imp boosts all)
- Protection: +15 (cannot target Chamber)
- **Total Difficulty: 172 (Nightmare)**

**Archetype**: Protected Summoner + Synergy + Turtle
**Strategy**: Complex priority puzzle with protection mechanics
**Counter**: Clear minions to expose Chamber, manage Imp synergy

---

## Boss Waves

### **Wave BOSS-1: "The Rust King's Domain"**
**Enemies**: The Rust King (150/100 HP, Phase Transition), 2× Spring Snapper (35 HP, 1 Armor each)

**Difficulty Calculation**:
- Total HP: 270 (both phases)
- Armor: 12 × 2 = +24 (average across phases)  
- Shields: 25 × 1.5 + (4 × 3) = 50 (Phase 2)
- Constraints: 6 (multiple complex systems) × 5 = +30
- Phase Mechanics: +25
- **Total Difficulty: 399 (Nightmare+)**

**Archetype**: Phase Transition + Scaling Support
**Strategy**: Ultimate resource management + adaptation test
**Counter**: Manage Phase 1 constraints, burst Phase 2 shields

---

### **Wave BOSS-2: "Temporal Collapse"**
**Enemies**: Chronophage (180 HP, 12 Armor, 30 Shields, 5 regen), 1× Time Nibbler (65 HP, 2 Armor, 10 Shields, 2 regen)

**Difficulty Calculation**:
- Total HP: 245
- Armor: 14 × 2 = +28
- Shields: 40 × 1.5 + (7 × 3) = 81
- Constraints: 8 (escalating time effects) × 5 = +40
- Damage Caps: +20
- **Total Difficulty: 414 (Nightmare+)**

**Archetype**: Ultimate Time Control + Support
**Strategy**: Tests all timing and constraint management skills
**Counter**: Survive escalation phases, burst final phase

---

## Wave Analysis Summary

### **Difficulty Distribution**
- **Trivial (1-15)**: 3 waves - Pure tutorial
- **Easy (16-35)**: 2 waves - Basic mechanics  
- **Medium (36-60)**: 4 waves - Standard encounters
- **Hard (61-90)**: 2 waves - Advanced challenges
- **Nightmare (121+)**: 6 waves - Elite/Boss encounters

### **Archetype Coverage**
- **Rush Threats**: 4 waves feature immediate pressure
- **Turtle Threats**: 6 waves test sustained damage  
- **Scaling Threats**: 5 waves create time pressure
- **Summoning Threats**: 4 waves test board control
- **Synergy Threats**: 3 waves require priority understanding
- **Multi-System**: 4 waves combine multiple archetypes

### **Strategic Skills Tested**
- **Priority Targeting**: 8 waves require threat assessment
- **Multi-Hit Strategy**: 6 waves need barrier/swarm solutions  
- **Resource Management**: 9 waves impose constraints
- **Timing Mastery**: 5 waves create time pressure
- **Adaptation**: 4 waves change during encounter

### **Color Favorability**
- **Red Favored**: 4 waves (swarm encounters)
- **Green Favored**: 3 waves (summoner encounters)  
- **Blue Favored**: 2 waves (precise targeting needed)
- **White Favored**: 3 waves (methodical elimination)
- **Black Favored**: 5 waves (opportunistic finishing)

This wave design ensures players encounter all strategic challenges in a progressive difficulty curve while testing mastery of different color strategies and mechanical systems.