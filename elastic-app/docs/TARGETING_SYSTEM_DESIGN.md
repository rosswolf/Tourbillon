# Targeting System Design

## Overview
The targeting system determines which gremlin(s) receive effects from cards and gears. This system needs to be flexible, predictable, and clearly communicated to players.

## Target Types

### Single Target Selectors

#### 1. **Highest** (Most Health)
```gdscript
func get_highest_health_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.health > b.health else b)
```

#### 2. **Lowest** (Least Health)
```gdscript
func get_lowest_health_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.health < b.health else b)
```

#### 3. **Newest** (Most Recently Spawned)
```gdscript
func get_newest_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.spawn_time > b.spawn_time else b)
```

#### 4. **Oldest** (Earliest Spawned)
```gdscript
func get_oldest_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.spawn_time < b.spawn_time else b)
```

#### 5. **Targeted** (Player Selected)
```gdscript
func get_targeted_gremlin() -> Gremlin:
    return GlobalGameManager.targeted_gremlin
```

#### 6. **Random**
```gdscript
func get_random_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins[randi() % gremlins.size()]
```

#### 7. **Strongest** (Highest Attack)
```gdscript
func get_strongest_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.attack > b.attack else b)
```

#### 8. **Weakest** (Lowest Attack)
```gdscript
func get_weakest_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): return a if a.attack < b.attack else b)
```

### Multi-Target Selectors

#### 1. **All**
- Targets every alive gremlin
- Damage may be split or full to each

#### 2. **Adjacent** 
- Targets gremlins next to the primary target
- Useful for splash damage effects

#### 3. **Row**
- All gremlins in the same row as target
- For horizontal line attacks

#### 4. **Column**
- All gremlins in the same column
- For vertical line attacks

#### 5. **First N**
- First N gremlins by position/spawn order
- Example: "Deal damage to the first 3 gremlins"

## Conditional Targeting

### State-Based Conditions
```gdscript
enum TargetCondition {
    ANY,           # No condition
    SHIELDED,      # Has shields > 0
    UNSHIELDED,    # Has shields == 0
    DAMAGED,       # Health < max_health
    FULL_HEALTH,   # Health == max_health
    POISONED,      # Has poison stacks
    MARKED,        # Has mark debuff
    ABOVE_THRESHOLD, # Health > X
    BELOW_THRESHOLD  # Health < X
}

func get_conditional_target(selector: TargetSelector, condition: TargetCondition) -> Gremlin:
    var candidates = get_all_alive_gremlins().filter(
        func(g): return meets_condition(g, condition)
    )
    if candidates.is_empty():
        return null
    return apply_selector(candidates, selector)
```

## Target Priority System

When multiple valid targets exist:

```gdscript
class TargetPriority:
    var primary: TargetSelector
    var tiebreaker: TargetSelector
    
    func select_target(gremlins: Array[Gremlin]) -> Gremlin:
        var candidates = apply_primary_selector(gremlins, primary)
        if candidates.size() > 1:
            return apply_selector(candidates, tiebreaker)
        return candidates[0]
```

### Example Priority Chains
- **Lowest health → Newest**: Among all with lowest health, pick newest
- **Shielded → Highest health**: Among shielded gremlins, pick highest health
- **Marked → Random**: Among marked gremlins, pick randomly

## Smart Targeting

### Threat Assessment
```gdscript
func get_highest_threat_gremlin() -> Gremlin:
    var gremlins = get_all_alive_gremlins()
    return gremlins.reduce(func(a, b): 
        var threat_a = calculate_threat(a)
        var threat_b = calculate_threat(b)
        return a if threat_a > threat_b else b
    )

func calculate_threat(gremlin: Gremlin) -> float:
    var threat = 0.0
    threat += gremlin.attack * 2.0  # Weight attack heavily
    threat += gremlin.health * 0.5  # Consider survivability
    threat += gremlin.shields * 0.3  # Shields make it harder to kill
    if gremlin.will_attack_next_turn():
        threat *= 1.5  # Immediate threats
    return threat
```

## Targeting UI/UX

### Visual Indicators
```gdscript
class TargetingVisual:
    func show_valid_targets(selector: TargetSelector):
        var valid = get_valid_targets(selector)
        for gremlin in valid:
            gremlin.highlight(Color.YELLOW)
    
    func show_selected_target(gremlin: Gremlin):
        gremlin.highlight(Color.RED)
        show_targeting_line(get_card_position(), gremlin.position)
```

### Targeting Preview
- Show damage numbers before confirming
- Indicate if target will be defeated
- Show chain/splash targets

## Retargeting System

When a target becomes invalid:

```gdscript
enum RetargetBehavior {
    FIZZLE,         # Effect fails
    NEXT_VALID,     # Pick next valid by same criteria
    RANDOM_VALID,   # Pick random valid target
    OVERKILL        # Excess damage/effect transfers
}

func handle_invalid_target(original: Gremlin, behavior: RetargetBehavior) -> Gremlin:
    match behavior:
        RetargetBehavior.FIZZLE:
            return null
        RetargetBehavior.NEXT_VALID:
            return get_next_valid_target(original)
        RetargetBehavior.RANDOM_VALID:
            return get_random_gremlin()
        RetargetBehavior.OVERKILL:
            return get_adjacent_gremlin(original)
```

## Implementation Structure

```gdscript
class TargetingSystem:
    static func resolve_targets(effect: Effect) -> Array[Gremlin]:
        var selector = effect.target_selector
        var count = effect.target_count
        var condition = effect.target_condition
        
        var candidates = get_valid_candidates(condition)
        var targets = []
        
        match selector.type:
            TargetType.SINGLE:
                targets.append(select_single(candidates, selector))
            TargetType.MULTI:
                targets = select_multiple(candidates, selector, count)
            TargetType.ALL:
                targets = candidates
                
        return targets
```

## Card Examples

```json
{
  "cards": {
    "lightning_strike": {
      "name": "Lightning Strike",
      "targeting": {
        "selector": "highest",
        "count": 1,
        "condition": "any"
      },
      "effect": "Deal 5 damage to the highest health gremlin"
    },
    "chain_lightning": {
      "name": "Chain Lightning", 
      "targeting": {
        "selector": "random",
        "count": 1,
        "chain_count": 2,
        "chain_selector": "adjacent"
      },
      "effect": "Deal 4 damage to a random gremlin, then 2 to adjacent"
    },
    "execute_weak": {
      "name": "Execute the Weak",
      "targeting": {
        "selector": "lowest",
        "count": 1,
        "condition": "below_threshold",
        "threshold": 3
      },
      "effect": "Destroy the lowest health gremlin if below 3 health"
    }
  }
}
```