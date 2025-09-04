# Unified Damage System Design

## Overview

Currently, the damage system in Tourbillon is fragmented:
- `Gremlin` has its own `take_damage()` implementation
- `Hero` doesn't have a damage method at all
- `BattleEntity` has some damage modifier logic but it's unused
- No consistent interface for damage types, keywords, or resolution

This document specifies a unified damage system that handles all damage calculation, modifiers, and resolution in a consistent way across all entities.

## Core Architecture

### 1. Damage Packet Class

**New File: `src/scenes/core/combat/damage_packet.gd`**

```gdscript
extends Resource
class_name DamagePacket

## Encapsulates all information about a damage instance
## Immutable once created - modifications create new packets

# Core properties
@export var base_amount: float = 0.0
@export var damage_type: DamageType = DamageType.NORMAL
@export var source: Node = null  # Who/what caused this damage
@export var force_type: GameResource.Type = GameResource.Type.NONE

# Damage keywords (from PRD)
@export var pierce: bool = false  # Ignores armor
@export var pop: bool = false  # Double damage vs shields
@export var overkill: bool = false  # Excess carries to next target
@export var true_damage: bool = false  # Cannot be modified
@export var poison: bool = false  # Is this poison damage?

# Targeting
@export var target_type: String = "single"  # single, all, chain
@export var chain_count: int = 0  # For chain damage

# Metadata
@export var tags: Array[String] = []  # For conditional effects
@export var timestamp_beats: int = 0  # When this damage was created

enum DamageType {
    NORMAL,      # Standard damage
    FIRE,        # From Heat effects
    PRECISION,   # From Precision effects
    FORCE,       # From Momentum effects
    DECAY,       # From Entropy effects
    VOID,        # From Balance effects
    POISON,      # Damage over time
    REFLECT,     # Reflected damage
    EXECUTE      # Instant kill below threshold
}

## Calculate final damage with all modifiers
func calculate_final_amount() -> int:
    if true_damage:
        return int(base_amount)
    
    var multiplier = get_force_multiplier()
    var modified = base_amount * multiplier
    
    return int(modified)

## Get damage multiplier based on force type
func get_force_multiplier() -> float:
    match force_type:
        GameResource.Type.HEAT, GameResource.Type.RED:
            return 1.25
        GameResource.Type.PRECISION, GameResource.Type.WHITE:
            return 0.75
        GameResource.Type.MOMENTUM, GameResource.Type.GREEN:
            return 1.0
        GameResource.Type.BALANCE, GameResource.Type.BLUE:
            return 0.8
        GameResource.Type.ENTROPY, GameResource.Type.PURPLE:
            return 1.1
        # Combined forces
        GameResource.Type.HEAT_COMBINED:  # Red + Blue
            return 1.6
        GameResource.Type.PRECISION_COMBINED:  # Blue + White
            return 1.3
        GameResource.Type.MOMENTUM_COMBINED:  # Green + Red
            return 1.4
        GameResource.Type.BALANCE_COMBINED:  # White + Purple
            return 1.2
        GameResource.Type.ENTROPY_COMBINED:  # Purple + Green
            return 1.5
        _:
            return 1.0

## Create a modified copy of this packet
func with_modifier(property: String, value) -> DamagePacket:
    var new_packet = duplicate(true) as DamagePacket
    new_packet.set(property, value)
    return new_packet
```

### 2. Damageable Interface

**New File: `src/scenes/core/combat/damageable.gd`**

```gdscript
extends Node
class_name Damageable

## Interface for entities that can receive damage
## All damageable entities must extend this class

# Properties that affect damage calculation
@export var max_hp: int = 10
@export var current_hp: int = 10
@export var armor: int = 0  # Flat damage reduction
@export var shields: int = 0  # Absorbs damage before HP
@export var barrier_count: int = 0  # Absorbs complete hits

# Advanced defenses
@export var damage_cap: int = 0  # Max damage per hit (0 = no cap)
@export var damage_resistance: float = 0.0  # Percentage reduction (0.0-1.0)
@export var reflect_percent: float = 0.0  # Percentage reflected (0.0-1.0)
@export var execute_immunity_threshold: int = 0  # Can't be executed above this HP

# Status flags
@export var invulnerable: bool = false
@export var burn_duration: int = 0  # Prevents healing

# Signals
signal damage_received(packet: DamagePacket, actual_damage: int)
signal hp_changed(new_hp: int, max_hp: int)
signal shields_changed(new_shields: int)
signal barrier_broken()
signal defeated()

## Main damage interface - all damage goes through here
func receive_damage(packet: DamagePacket) -> int:
    if invulnerable:
        return 0
    
    # Pre-damage checks
    var modified_packet = _apply_pre_damage_modifiers(packet)
    
    # Calculate damage
    var damage_result = _calculate_damage(modified_packet)
    
    # Apply damage
    var actual_damage = _apply_damage(damage_result, modified_packet)
    
    # Post-damage effects
    _apply_post_damage_effects(modified_packet, actual_damage)
    
    # Emit signals
    damage_received.emit(modified_packet, actual_damage)
    
    return actual_damage

## Pre-damage modification hook (override in subclasses)
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
    return packet

## Calculate damage amount after defenses
func _calculate_damage(packet: DamagePacket) -> DamageResult:
    var result = DamageResult.new()
    result.packet = packet
    
    var damage = packet.calculate_final_amount()
    
    # Apply damage cap
    if damage_cap > 0:
        damage = min(damage, damage_cap)
    
    # Apply resistance (not for true damage or pierce)
    if not packet.true_damage and not packet.pierce:
        damage = int(damage * (1.0 - damage_resistance))
    
    # Check barriers first (complete absorption)
    if barrier_count > 0 and not packet.pierce:
        result.barriers_broken = 1
        result.total_prevented = damage
        return result
    
    # Apply armor (unless pierce)
    if not packet.pierce and not packet.poison:
        var armor_reduction = min(armor, damage)
        damage -= armor_reduction
        result.armor_absorbed = armor_reduction
    
    # Apply to shields first (unless pierce)
    if shields > 0 and not packet.pierce:
        var shield_damage = damage
        
        # Pop keyword doubles damage vs shields
        if packet.pop:
            shield_damage *= 2
        
        var shields_lost = min(shields, shield_damage)
        result.shields_lost = shields_lost
        damage -= shields_lost
        
        # Pop doubles remaining damage too
        if packet.pop and damage > 0:
            damage *= 2
    
    result.final_damage = max(0, damage)
    return result

## Apply calculated damage to the entity
func _apply_damage(result: DamageResult, packet: DamagePacket) -> int:
    # Remove barriers
    if result.barriers_broken > 0:
        barrier_count -= result.barriers_broken
        barrier_broken.emit()
        return 0  # Barrier absorbed everything
    
    # Remove shields
    if result.shields_lost > 0:
        shields -= result.shields_lost
        shields_changed.emit(shields)
    
    # Apply HP damage
    if result.final_damage > 0:
        current_hp -= result.final_damage
        hp_changed.emit(current_hp, max_hp)
        
        # Check defeat
        if current_hp <= 0:
            _on_defeated()
    
    return result.final_damage

## Post-damage effects (reflect, overkill, etc)
func _apply_post_damage_effects(packet: DamagePacket, actual_damage: int) -> void:
    # Handle damage reflection
    if reflect_percent > 0 and packet.source and not packet.poison:
        var reflected = int(actual_damage * reflect_percent)
        if reflected > 0:
            _reflect_damage(packet.source, reflected)
    
    # Handle overkill
    if packet.overkill and current_hp <= 0:
        var excess = abs(current_hp)
        if excess > 0:
            _apply_overkill(packet, excess)

## Heal the entity
func heal(amount: int) -> int:
    if burn_duration > 0:
        return 0  # Can't heal while burned
    
    var healed = min(amount, max_hp - current_hp)
    current_hp += healed
    hp_changed.emit(current_hp, max_hp)
    return healed

## Add shields
func add_shields(amount: int) -> void:
    shields += amount
    shields_changed.emit(shields)

## Add barriers
func add_barriers(count: int) -> void:
    barrier_count += count

## Check if can be executed
func can_be_executed(threshold: int) -> bool:
    if current_hp > execute_immunity_threshold:
        return false
    return current_hp <= threshold

## Execute (instant kill if eligible)
func execute() -> void:
    if not invulnerable:
        current_hp = 0
        _on_defeated()

## Called when HP reaches 0
func _on_defeated() -> void:
    defeated.emit()

## Helper: Reflect damage back to source
func _reflect_damage(source: Node, amount: int) -> void:
    if source.has_method("receive_damage"):
        var reflect_packet = DamagePacket.new()
        reflect_packet.base_amount = amount
        reflect_packet.damage_type = DamagePacket.DamageType.REFLECT
        reflect_packet.source = self
        reflect_packet.true_damage = true  # Reflected damage can't be reduced
        source.receive_damage(reflect_packet)

## Helper: Apply overkill to next target
func _apply_overkill(packet: DamagePacket, excess: int) -> void:
    # This needs to be handled by the combat manager
    if GlobalGameManager.has("gremlin_manager"):
        var manager = GlobalGameManager.get("gremlin_manager")
        if manager.has_method("apply_overkill_damage"):
            manager.apply_overkill_damage(packet, excess)

## Inner class for damage calculation results
class DamageResult extends RefCounted:
    var packet: DamagePacket
    var final_damage: int = 0
    var shields_lost: int = 0
    var armor_absorbed: int = 0
    var barriers_broken: int = 0
    var total_prevented: int = 0
```

### 3. Update Gremlin to Use Damageable

**Modified File: `src/scenes/core/entities/gremlin.gd`**

```gdscript
extends Damageable  # Changed from BeatListenerEntity
class_name Gremlin

# Gremlin still implements BeatListenerEntity interface
@export var disruption_interval_beats: int = 50
@export var gremlin_name: String = "Gremlin"
@export var moves_string: String = ""
@export var slot_index: int = 0

# Remove duplicate properties that are now in Damageable:
# - current_hp, max_hp, shields, burn_duration (all in Damageable)

# Keep gremlin-specific properties
var beat_consumers: Array[BeatConsumer] = []
var beats_until_disruption: int = 0
var move_controller: GremlinMoveController

signal disruption_triggered(gremlin: Gremlin)

func _ready() -> void:
    # Initialize from Damageable
    current_hp = max_hp
    beats_until_disruption = disruption_interval_beats
    
    # Process moves/downsides
    if not moves_string.is_empty():
        GremlinDownsideProcessor.process_gremlin_moves(moves_string, self)

# Remove old take_damage() - now uses receive_damage() from Damageable

## Override to handle gremlin-specific damage modifiers
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
    # Gremlin-specific damage modifications
    # e.g., resistance to certain damage types
    return packet

## Process beat for gremlin behaviors
func process_beat(context: BeatContext) -> void:
    # ... existing beat processing ...
```

### 4. Add Damage Support to Hero

**Modified File: `src/scenes/core/entities/hero.gd`**

```gdscript
extends Damageable  # Add Damageable as parent
class_name Hero

# Hero extends both BattleEntity and Damageable
# Remove any duplicate HP/shield properties

@export var hero_name: String = "Hero"
@export var max_card_hp: int = 10  # "Card HP" - running out of cards

# Force resources remain the same
var red: CappedResource
var blue: CappedResource
# ... etc ...

## Override damage handling for hero-specific mechanics
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
    # Check for damage reduction from Balance force
    if balance and balance.current > 5:
        packet = packet.with_modifier("damage_resistance", 0.2)
    
    return packet

## Hero loses when out of cards (different from HP)
func check_card_defeat() -> bool:
    # This is separate from damage-based defeat
    return GlobalGameManager.library.get_cards_in_hand().is_empty()
```

### 5. Damage Factory

**New File: `src/scenes/core/combat/damage_factory.gd`**

```gdscript
extends Node
class_name DamageFactory

## Factory for creating properly configured damage packets

## Create damage packet from effect string
static func from_effect(effect_string: String, source: Node = null) -> DamagePacket:
    var packet = DamagePacket.new()
    packet.source = source
    
    # Parse effect string for damage amount and keywords
    # e.g., "damage=5,pierce,pop"
    var parts = effect_string.split(",")
    for part in parts:
        var trimmed = part.strip_edges()
        
        if trimmed.contains("="):
            var kv = trimmed.split("=")
            var key = kv[0]
            var value = kv[1]
            
            match key:
                "damage":
                    packet.base_amount = float(value)
                "type":
                    packet.damage_type = _parse_damage_type(value)
        else:
            # Keywords without values
            match trimmed:
                "pierce":
                    packet.pierce = true
                "pop":
                    packet.pop = true
                "overkill":
                    packet.overkill = true
                "poison":
                    packet.poison = true
                    packet.damage_type = DamagePacket.DamageType.POISON
    
    # Set force type from current context
    if GlobalGameManager.has_meta("active_force_type"):
        packet.force_type = _parse_force_type(GlobalGameManager.get_meta("active_force_type"))
    
    packet.timestamp_beats = GlobalGameManager.current_beat
    
    return packet

## Create damage packet for a specific force type
static func from_force(force_type: GameResource.Type, amount: float, source: Node = null) -> DamagePacket:
    var packet = DamagePacket.new()
    packet.base_amount = amount
    packet.force_type = force_type
    packet.source = source
    packet.timestamp_beats = GlobalGameManager.current_beat
    
    # Set damage type based on force
    match force_type:
        GameResource.Type.HEAT, GameResource.Type.RED:
            packet.damage_type = DamagePacket.DamageType.FIRE
        GameResource.Type.PRECISION, GameResource.Type.WHITE:
            packet.damage_type = DamagePacket.DamageType.PRECISION
        GameResource.Type.ENTROPY, GameResource.Type.PURPLE:
            packet.damage_type = DamagePacket.DamageType.DECAY
        _:
            packet.damage_type = DamagePacket.DamageType.NORMAL
    
    return packet

## Create an execute packet
static func create_execute(threshold: int, source: Node = null) -> DamagePacket:
    var packet = DamagePacket.new()
    packet.damage_type = DamagePacket.DamageType.EXECUTE
    packet.base_amount = threshold  # Store threshold in amount
    packet.source = source
    packet.true_damage = true
    return packet

static func _parse_damage_type(type_str: String) -> DamagePacket.DamageType:
    match type_str.to_lower():
        "fire", "heat":
            return DamagePacket.DamageType.FIRE
        "precision":
            return DamagePacket.DamageType.PRECISION
        "force", "momentum":
            return DamagePacket.DamageType.FORCE
        "decay", "entropy":
            return DamagePacket.DamageType.DECAY
        "void", "balance":
            return DamagePacket.DamageType.VOID
        "poison":
            return DamagePacket.DamageType.POISON
        "reflect":
            return DamagePacket.DamageType.REFLECT
        "execute":
            return DamagePacket.DamageType.EXECUTE
        _:
            return DamagePacket.DamageType.NORMAL

static func _parse_force_type(type_str: String) -> GameResource.Type:
    # Parse string to GameResource.Type
    match type_str.to_lower():
        "red", "heat":
            return GameResource.Type.RED
        "blue", "balance":
            return GameResource.Type.BLUE
        "green", "momentum":
            return GameResource.Type.GREEN
        "white", "precision":
            return GameResource.Type.WHITE
        "purple", "black", "entropy":
            return GameResource.Type.PURPLE
        _:
            return GameResource.Type.NONE
```

### 6. Update Effect Processor

**Modified File: `src/scenes/core/effects/tourbillon_effect_processor.gd`**

```gdscript
# Replace all damage effect functions with unified system

static func _effect_damage(amount: int, target_type: String) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        push_warning("No gremlin_manager in GlobalGameManager")
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    
    # Create damage packet
    var packet = DamageFactory.from_force(
        _get_current_force_type(),
        amount,
        GlobalGameManager.active_gear  # Track source gear
    )
    
    # Apply keywords from context
    if GlobalGameManager.has_meta("next_damage_pierce"):
        packet.pierce = true
        GlobalGameManager.remove_meta("next_damage_pierce")
    
    if GlobalGameManager.has_meta("next_damage_pop"):
        packet.pop = true
        GlobalGameManager.remove_meta("next_damage_pop")
    
    if GlobalGameManager.has_meta("next_damage_overkill"):
        packet.overkill = true
        GlobalGameManager.remove_meta("next_damage_overkill")
    
    # Deal damage using unified system
    match target_type:
        "all":
            for gremlin in manager.get_gremlins_in_order():
                gremlin.receive_damage(packet)
        _:
            var target = manager.get_target_by_type(target_type)
            if target:
                target.receive_damage(packet)

static func _effect_apply_poison(stacks: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    var target = manager.get_topmost_gremlin()
    
    if target:
        # Poison is handled differently - it adds a beat consumer
        target.apply_poison(stacks)

static func _effect_execute(threshold: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    
    for gremlin in manager.get_gremlins_in_order():
        if gremlin.can_be_executed(threshold):
            gremlin.execute()
```

### 7. Update Gremlin Manager

**Modified File: `src/scenes/core/battle/gremlin_manager.gd`**

```gdscript
# Replace deal_damage_to_target with unified system

func deal_damage_to_target(packet: DamagePacket, target_type: String = "topmost") -> void:
    match target_type:
        "all":
            for gremlin in get_gremlins_in_order():
                gremlin.receive_damage(packet)
        _:
            var target = _get_target_by_type(target_type)
            if target:
                target.receive_damage(packet)

## Handle overkill damage carrying to next target
func apply_overkill_damage(original_packet: DamagePacket, excess_damage: int) -> void:
    var next_target = get_topmost_gremlin()
    if next_target:
        # Create new packet for overkill damage
        var overkill_packet = original_packet.duplicate(true) as DamagePacket
        overkill_packet.base_amount = excess_damage
        overkill_packet.overkill = false  # Prevent infinite chain
        
        next_target.receive_damage(overkill_packet)
```

## Integration Benefits

### 1. Consistent Damage Resolution
- All entities use the same damage pipeline
- Keywords work identically everywhere
- Damage modifiers stack predictably

### 2. Extensibility
- Easy to add new damage types
- New keywords just need packet properties
- Damage sources are tracked

### 3. Debugging
- Single place to log all damage
- Damage packets can be inspected
- Clear damage flow

### 4. Balance
- Force multipliers in one place
- Easy to adjust damage formulas
- A/B testing different multipliers

### 5. Effects
- Damage reflection works automatically
- Overkill chains properly
- Barriers consistent across entities

## Usage Examples

### Basic Damage
```gdscript
# Deal 5 Heat damage to topmost gremlin
var packet = DamageFactory.from_force(GameResource.Type.HEAT, 5, self)
gremlin_manager.get_topmost_gremlin().receive_damage(packet)
```

### Pierce + Pop Damage
```gdscript
# Deal 10 piercing, shield-popping damage
var packet = DamageFactory.from_force(GameResource.Type.PRECISION, 10, self)
packet.pierce = true
packet.pop = true
target.receive_damage(packet)
```

### Execute Below Threshold
```gdscript
# Execute all gremlins below 10 HP
var threshold = 10
for gremlin in gremlin_manager.get_gremlins_in_order():
    if gremlin.can_be_executed(threshold):
        gremlin.execute()
```

### AOE with Overkill
```gdscript
# Deal 20 damage to all, excess carries
var packet = DamageFactory.from_force(GameResource.Type.ENTROPY, 20, self)
packet.overkill = true

for gremlin in gremlins:
    var actual = gremlin.receive_damage(packet)
    if gremlin.current_hp <= 0 and packet.overkill:
        # Manager handles overkill distribution
        break
```

## Migration Path

### Phase 1: Core Implementation
1. Implement DamagePacket class
2. Implement Damageable base class
3. Implement DamageFactory

### Phase 2: Entity Migration
1. Update Gremlin to extend Damageable
2. Add Damageable to Hero
3. Update existing damage calls

### Phase 3: Effect Integration
1. Update TourbillonEffectProcessor
2. Update GremlinManager
3. Add damage UI feedback

### Phase 4: Testing
1. Unit test damage calculations
2. Test all keywords
3. Verify multipliers
4. Test edge cases (barriers, reflection, etc.)

## Testing Considerations

### Unit Tests Required
- Damage calculation with all multipliers
- Barrier absorption
- Shield + pop interaction
- Armor reduction
- Damage cap enforcement
- Reflection calculations
- Overkill distribution
- Execute immunity

### Integration Tests
- Full combat with multiple damage sources
- Poison + burn interaction
- Chain damage through gremlins
- Hero taking reflected damage
- Save/load with damage state

This unified system provides a single, consistent way to handle all damage in the game, making it easier to implement complex mechanics like those described in the PRD while maintaining clean, testable code.