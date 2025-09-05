# Attack Moves to Add to Gremlins

Based on the archetype analysis and existing moves, here are the attack moves to add:

## Gremlins That Need Attack Moves

### 1. Basic Gnat (fodder)
- Add move_2: "attack=1" at 3 ticks (weak attack)

### 2. Barrier Gnat (protected_fodder)  
- Add move_1: "attack=2" at 5 ticks (slightly stronger due to protection)

### 3. Dust Mite (rush_threat)
- Already has heat_soft_cap=4
- Add move_2: "attack=2" at 4 ticks (fast attack)

### 4. Drain Gnat (annoying_fodder)
- Already has drain_random=1 at 8 ticks
- Add move_2: "attack=1" at 5 ticks (weak attack between drains)

### 5. Constricting Barrier Gnat (protected_constraint)
- Already has max_resource_soft_cap=5
- Add move_2: "attack=3" at 8 ticks (slower but stronger)

### 6. Breeding Gnat (self_replacing_fodder)
- Already has summon=basic_gnat at 12 ticks
- No attack needed (summoner archetype)

### 7. Gear Tick (disruption_threat)
- Already has card_cost_penalty=1 and force_discard=1
- Add move_3: "attack=2" at 15 ticks (occasional attack)

### 8. Rust Speck (turtle_threat)
- Has passive ability
- Add move_2: "attack=3" at 6 ticks (steady damage)

### 9. Spring Snapper (scaling_threat)
- Has sequence moves
- Add as part of sequence: "attack=4" at appropriate tick

### 10. Oil Thief (turtle_rush_combo)
- Has sequence moves
- Add as part of sequence: "attack=3" early, "attack=5" late

### 11. Chaos Imp (synergy_threat)
- Has cycle move
- Add move_2: "attack=2" at 7 ticks

### 12. Gnat Spawner (summoning_threat)
- Has summon cycle
- No attack needed (pure summoner)

### 13. Gear Grinder (turtle_berserker)
- Has sequence moves
- Add strong attacks: "attack=4" early, "attack=6" late in sequence

### 14. Time Nibbler (disruption_turtle)
- Has sequence moves
- Add move: "attack=3" at moderate tick rate

### 15. Echo Chamber (protected_synergy)
- Has cycle move
- Add move_2: "attack=2" at 9 ticks (support with light damage)

### 16. Constraint Engine (boss_turtle_constraint)
- Add powerful attack: "attack=5" at 10 ticks

### 17. Temporal Glutton (escalating_summoner)
- No direct attacks (summoner boss)

### 18. Clog Beast (boss_turtle_disruption)
- Add heavy attack: "attack=7" at 12 ticks

### 19. Gear Knight (boss_scaling_threat)
- Add scaling attacks: "attack=4" at 5 ticks, "attack=6" at 10 ticks