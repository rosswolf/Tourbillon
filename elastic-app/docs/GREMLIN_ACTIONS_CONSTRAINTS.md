# Gremlin Actions & Constraints Design

## Overview
Gremlins are the primary antagonists that players must defeat. They have actions they perform and constraints that limit/modify their behavior.

## Gremlin Action System

### Base Action Types

#### 1. **Attack Actions**
```gdscript
class AttackAction extends GremlinAction:
    var damage: int
    var target: TargetSelector = TargetSelector.PLAYER
    
    func execute(gremlin: Gremlin):
        var damage_packet = DamagePacket.new()
        damage_packet.base_amount = damage
        damage_packet.source = gremlin
        GlobalGameManager.deal_damage_to_player(damage_packet)
```

#### 2. **Buff Actions**
```gdscript
class BuffAction extends GremlinAction:
    var stat: String  # "attack", "health", "shields"
    var amount: int
    var target: TargetSelector = TargetSelector.SELF
    
    func execute(gremlin: Gremlin):
        var target = resolve_target(target, gremlin)
        target.modify_stat(stat, amount)
```

#### 3. **Summon Actions**
```gdscript
class SummonAction extends GremlinAction:
    var gremlin_type: String
    var count: int = 1
    
    func execute(gremlin: Gremlin):
        for i in count:
            GremlinManager.spawn_gremlin(gremlin_type)
```

#### 4. **Special Actions**
```gdscript
class SpecialAction extends GremlinAction:
    var effect_type: String
    
    func execute(gremlin: Gremlin):
        match effect_type:
            "steal_resources":
                GlobalGameManager.steal_player_resources(2)
            "disable_gear":
                GlobalGameManager.disable_random_gear()
            "corrupt_card":
                GlobalGameManager.corrupt_random_card_in_hand()
```

### Action Timing

```gdscript
enum ActionTiming {
    EVERY_N_BEATS,      # Every N beats
    EVERY_N_TICKS,      # Every N ticks  
    ON_DAMAGE_TAKEN,    # When damaged
    ON_ALLY_DEATH,      # When another gremlin dies
    ON_SPAWN,           # When first created
    ON_DEATH,           # When destroyed
    WHEN_BELOW_HALF,    # When health < 50%
    RANDOM_CHANCE       # X% chance each beat
}
```

### Action Patterns

```gdscript
class GremlinPattern:
    var actions: Array[GremlinAction] = []
    var current_index: int = 0
    var pattern_type: PatternType
    
    enum PatternType {
        SEQUENTIAL,    # Do actions in order
        RANDOM,        # Random action each time
        CONDITIONAL,   # Based on game state
        ESCALATING     # Stronger over time
    }
    
    func get_next_action() -> GremlinAction:
        match pattern_type:
            PatternType.SEQUENTIAL:
                var action = actions[current_index]
                current_index = (current_index + 1) % actions.size()
                return action
            PatternType.RANDOM:
                return actions[randi() % actions.size()]
            PatternType.ESCALATING:
                var power_level = GlobalGameManager.get_current_tick() / 10
                return get_action_for_power_level(power_level)
```

## Gremlin Constraints

### Movement Constraints

```gdscript
class MovementConstraint:
    enum Type {
        IMMOBILE,       # Cannot move
        SLOW,           # Moves every 2 actions
        NORMAL,         # Moves every action
        FAST,           # Moves twice per action
        TELEPORTING     # Can move anywhere
    }
    
    var movement_type: Type = Type.NORMAL
    var movement_range: int = 1
    
    func can_move_to(from: Vector2i, to: Vector2i) -> bool:
        if movement_type == Type.IMMOBILE:
            return false
        if movement_type == Type.TELEPORTING:
            return true
        var distance = abs(to.x - from.x) + abs(to.y - from.y)
        return distance <= movement_range
```

### Defensive Constraints

```gdscript
class DefensiveConstraint:
    var damage_cap: int = -1          # Max damage per hit (-1 = no cap)
    var immune_to: Array[DamageType] = []  # Damage immunities
    var resist_percent: float = 0.0   # General damage resistance
    var shield_regen: int = 0         # Shields regenerated per tick
    var armor_stacks: int = 0         # Permanent damage reduction
    
    func modify_incoming_damage(damage: int, type: DamageType) -> int:
        if type in immune_to:
            return 0
        
        damage = int(damage * (1.0 - resist_percent))
        damage = max(0, damage - armor_stacks)
        
        if damage_cap > 0:
            damage = min(damage, damage_cap)
            
        return damage
```

### Behavioral Constraints

```gdscript
class BehavioralConstraint:
    var aggression_level: float = 1.0  # Multiplier for attack frequency
    var cowardice_threshold: int = 0   # Flee when health below this
    var pack_mentality: bool = false   # Gets stronger with more gremlins
    var vengeful: bool = false         # Enrages when allies die
    var methodical: bool = false       # Always targets same enemy
    
    func modify_behavior(gremlin: Gremlin, action: GremlinAction) -> GremlinAction:
        if cowardice_threshold > 0 and gremlin.health < cowardice_threshold:
            return FleeAction.new()
        
        if pack_mentality:
            var ally_count = GremlinManager.get_alive_count()
            action.power *= (1.0 + ally_count * 0.1)
        
        if vengeful and GremlinManager.deaths_this_turn > 0:
            action.power *= 2.0
            
        return action
```

### Resource Constraints

```gdscript
class ResourceConstraint:
    var energy_cost: int = 0          # Energy needed to act
    var energy_per_tick: int = 1      # Energy gained per tick
    var current_energy: int = 0       # Current energy pool
    var shares_energy: bool = false   # Shares energy with allies
    
    func can_perform_action(action: GremlinAction) -> bool:
        if shares_energy:
            return GremlinManager.get_total_energy() >= action.energy_cost
        return current_energy >= action.energy_cost
    
    func consume_energy(amount: int):
        if shares_energy:
            GremlinManager.consume_shared_energy(amount)
        else:
            current_energy -= amount
```

## Gremlin Archetypes

### 1. **Grunt** (Basic Enemy)
```gdscript
{
    "name": "Grunt",
    "health": 5,
    "actions": [
        {"type": "attack", "damage": 2, "timing": "every_2_beats"}
    ],
    "constraints": {
        "movement": "normal",
        "defensive": {"resist_percent": 0}
    }
}
```

### 2. **Tank** (Defensive)
```gdscript
{
    "name": "Tank",
    "health": 15,
    "actions": [
        {"type": "attack", "damage": 3, "timing": "every_3_beats"},
        {"type": "buff", "stat": "shields", "amount": 2, "timing": "every_5_beats"}
    ],
    "constraints": {
        "movement": "slow",
        "defensive": {
            "armor_stacks": 2,
            "shield_regen": 1
        }
    }
}
```

### 3. **Assassin** (High Damage, Low Health)
```gdscript
{
    "name": "Assassin",
    "health": 3,
    "actions": [
        {"type": "attack", "damage": 6, "timing": "every_2_beats", "property": "piercing"}
    ],
    "constraints": {
        "movement": "fast",
        "behavioral": {
            "cowardice_threshold": 2,
            "methodical": true
        }
    }
}
```

### 4. **Summoner** (Spawns More Enemies)
```gdscript
{
    "name": "Summoner",
    "health": 8,
    "actions": [
        {"type": "summon", "gremlin_type": "grunt", "timing": "every_5_beats"},
        {"type": "buff", "stat": "attack", "target": "all_allies", "timing": "on_spawn"}
    ],
    "constraints": {
        "movement": "immobile",
        "defensive": {"damage_cap": 3}
    }
}
```

### 5. **Berserker** (Gets Stronger When Hurt)
```gdscript
{
    "name": "Berserker",
    "health": 10,
    "actions": [
        {"type": "attack", "damage": 3, "timing": "every_beat"}
    ],
    "constraints": {
        "behavioral": {
            "vengeful": true,
            "aggression_level": 1.5
        },
        "special": {
            "enrage_below_half": true,  # Double damage when < 50% health
            "fury_stacks": true          # +1 attack per damage taken
        }
    }
}
```

## Constraint Combinations

### Synergy Examples

1. **Shielded Swarm**
   - Multiple weak gremlins with shared shields
   - Killing one reduces defense of all

2. **Alpha Pack**
   - One strong leader buffing weaker members
   - Pack loses morale when alpha dies

3. **Regenerating Horde**
   - Gremlins heal each other
   - Must defeat all quickly or they recover

## State Machine Implementation

```gdscript
class GremlinStateMachine:
    enum State {
        IDLE,
        PREPARING,    # Charging up attack
        ATTACKING,    # Executing attack
        DEFENDING,    # Defensive stance
        FLEEING,      # Running away
        ENRAGED,      # Berserk mode
        STUNNED,      # Cannot act
        DYING         # Death animation
    }
    
    var current_state: State = State.IDLE
    var state_timer: float = 0.0
    
    func transition_to(new_state: State):
        exit_state(current_state)
        current_state = new_state
        enter_state(new_state)
        state_timer = 0.0
    
    func process_state(delta: float):
        state_timer += delta
        match current_state:
            State.PREPARING:
                if state_timer >= prepare_time:
                    transition_to(State.ATTACKING)
            State.ATTACKING:
                execute_attack()
                transition_to(State.IDLE)
```

## Difficulty Scaling

```gdscript
class DifficultyScaler:
    static func scale_gremlin(gremlin: Gremlin, wave: int):
        var scale = 1.0 + (wave * 0.2)
        
        gremlin.health *= scale
        gremlin.max_health *= scale
        
        for action in gremlin.actions:
            if action.has("damage"):
                action.damage *= scale
                
        # Add constraints at higher waves
        if wave > 5:
            gremlin.constraints.defensive.armor_stacks += 1
        if wave > 10:
            gremlin.constraints.behavioral.aggression_level *= 1.5
```

## Visual Communication

### Action Telegraphing
- Show charging animation before attacks
- Display target indicators
- Preview damage numbers
- Show action countdown timers

### Constraint Indicators
- Shield bubbles for defensive constraints
- Speed lines for movement constraints
- Rage effects for behavioral constraints
- Energy bars for resource constraints

## Balance Guidelines

### Action Power Budget
- Basic Attack: 2-3 damage
- Strong Attack: 5-6 damage
- Buff: +1-2 to stat
- Summon: 1 weak gremlin

### Constraint Impact
- Each constraint should meaningfully change how players approach the gremlin
- Constraints should create interesting decisions, not just make gremlins harder
- Synergies between constraints should be intentional and balanced