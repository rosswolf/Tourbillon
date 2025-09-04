# Gremlin System Implementation Design Document

## Overview

This document specifies the technical implementation required to fully support the gremlin attack patterns and constraint mechanics defined in the Tourbillon PRD. The implementation builds upon the existing foundation while adding sophisticated move cycles, advanced constraints, a unified damage system, and proper combat integration.

**Core Systems to Implement:**
1. Unified Damage System - Consistent damage resolution across all entities
2. Move Cycle System - Dynamic gremlin attack patterns
3. Enhanced Constraint System - Production taxes, placement restrictions, force decay
4. Advanced Defense Mechanics - Barriers, damage caps, reflection
5. Combat Effect Integration - Connect gremlins to the effect processor
6. Constraint UI System - Visual feedback for active disruptions

## 1. Unified Damage System

### 1.1 New File: `src/scenes/core/combat/damage_packet.gd`

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

## Get damage multiplier based on force type (from PRD)
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
```

**Responsibilities:**
- Encapsulate all damage information
- Apply force-based damage multipliers
- Track damage keywords and metadata
- Provide immutable damage data

### 1.2 New File: `src/scenes/core/combat/damageable.gd`

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
```

**Responsibilities:**
- Provide unified damage interface for all entities
- Handle damage calculation pipeline
- Manage HP, shields, armor, barriers
- Support damage reflection and overkill
- Emit consistent damage signals

### 1.3 New File: `src/scenes/core/combat/damage_factory.gd`

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
```

**Responsibilities:**
- Create damage packets from various sources
- Parse effect strings for damage data
- Apply appropriate force multipliers
- Set damage type based on force

## 2. Move Cycle System

### 1.1 New File: `src/scenes/core/battle/gremlin_move.gd`

```gdscript
extends Resource
class_name GremlinMove

## Represents a single move in a gremlin's attack pattern
## Moves can be passive (always active) or triggered (periodic effects)

@export var move_id: String = ""
@export var move_name: String = ""
@export var duration_ticks: int = 0  # 0 = until triggered/transitioned
@export var trigger_interval_beats: int = 0  # 0 = passive only
@export var max_triggers: int = 0  # 0 = unlimited

# Transition control
@export var next_move: String = ""  # Empty = cycle to first
@export var transition_condition: String = ""  # "trigger_count", "health_below", "time_elapsed"
@export var transition_value: float = 0.0

# Effects (stored as Dictionaries for data-driven design)
@export var passive_effects: Array[Dictionary] = []
@export var trigger_effects: Array[Dictionary] = []
@export var on_enter_effects: Array[Dictionary] = []
@export var on_exit_effects: Array[Dictionary] = []

var triggers_performed: int = 0
var beats_active: int = 0
```

**Responsibilities:**
- Store move configuration data
- Track move state (triggers, duration)
- Define transition conditions
- Hold effect definitions

### 1.2 New File: `src/scenes/core/battle/gremlin_move_controller.gd`

```gdscript
extends Node
class_name GremlinMoveController

## Controls the execution of a gremlin's move cycle
## Handles transitions, effect triggering, and state management

var current_move: GremlinMove
var move_cycle: Array[GremlinMove] = []
var move_index: int = 0
var owner_gremlin: Gremlin

signal move_changed(old_move: GremlinMove, new_move: GremlinMove)
signal move_triggered(move: GremlinMove)

func load_moves_from_data(moves_data: Array) -> void
func process_beat(context: BeatContext) -> void
func transition_to_move(move_id: String) -> void
func check_transition_conditions() -> bool
func execute_passive_effects() -> void
func execute_trigger_effects() -> void
```

**Responsibilities:**
- Manage move cycle progression
- Execute move effects at appropriate times
- Handle move transitions based on conditions
- Apply passive and triggered effects

## 2. Enhanced Constraint System

### 2.1 Modified File: `src/scenes/core/battle/gremlin_downside_processor.gd`

**New Static Variables:**
```gdscript
# Production modifiers
static var production_taxes: Dictionary[String, float] = {}  # tag -> multiplier
static var global_production_tax: float = 0.0

# Placement restrictions  
static var blocked_positions: Array[Vector2i] = []
static var position_penalties: Dictionary[Vector2i, float] = {}

# Gear modifiers
static var disabled_gears: Array[String] = []  # instance_ids
static var corrupted_gears: Dictionary[String, Dictionary] = {}  # id -> modifications

# Force decay
static var force_decay_rates: Dictionary[GameResource.Type, float] = {}
static var universal_decay_rate: float = 0.0

# Time modifiers
static var time_penalty_beats: int = 0  # Added to all card costs
static var tag_time_penalties: Dictionary[String, int] = {}  # tag -> extra beats
```

**New Functions to Add:**
```gdscript
# Production tax application
static func apply_production_tax(tag: String, percent: float) -> void
static func apply_global_production_tax(percent: float) -> void
static func get_production_multiplier_for_gear(gear: Card) -> float

# Placement restrictions
static func block_position(pos: Vector2i) -> void
static func unblock_position(pos: Vector2i) -> void
static func is_position_blocked(pos: Vector2i) -> bool
static func apply_position_penalty(pos: Vector2i, penalty: float) -> void

# Gear corruption
static func disable_gear(instance_id: String) -> void
static func enable_gear(instance_id: String) -> void
static func corrupt_gear(instance_id: String, modifications: Dictionary) -> void
static func is_gear_disabled(instance_id: String) -> bool
static func get_gear_corruption(instance_id: String) -> Dictionary

# Force decay
static func apply_force_decay(force_type: GameResource.Type, rate: float) -> void
static func process_force_decay() -> void  # Called each tick

# Time penalties
static func apply_time_penalty(beats: int) -> void
static func apply_tag_time_penalty(tag: String, beats: int) -> void
static func get_total_time_penalty_for_card(card: Card) -> int

# Hand constraints
static func set_hand_size_limit(limit: int) -> void
static func block_card_draw() -> void
static func unblock_card_draw() -> void
```

## 3. Advanced Defense Mechanics

### 3.1 Modified File: `src/scenes/core/entities/gremlin.gd`

**Change Parent Class to Damageable:**
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
# - barrier_count, damage_cap, reflect_percent (in Damageable)

# Keep gremlin-specific properties
var beat_consumers: Array[BeatConsumer] = []
var beats_until_disruption: int = 0
var move_controller: GremlinMoveController

# Targeting
@export var can_be_targeted: bool = true
@export var untargetable_condition: String = ""  # e.g., "while_other_gremlins_exist"

signal disruption_triggered(gremlin: Gremlin)

func _ready() -> void:
    # Initialize from Damageable
    current_hp = max_hp
    beats_until_disruption = disruption_interval_beats
    
    # Initialize move controller
    move_controller = GremlinMoveController.new()
    move_controller.owner_gremlin = self
    add_child(move_controller)
    
    # Process moves/downsides
    if not moves_string.is_empty():
        GremlinDownsideProcessor.process_gremlin_moves(moves_string, self)

# Remove old take_damage() - now uses receive_damage() from Damageable

## Override to handle gremlin-specific damage modifiers
func _apply_pre_damage_modifiers(packet: DamagePacket) -> DamagePacket:
    # Gremlin-specific damage modifications
    # e.g., resistance to certain damage types based on gremlin type
    return packet

## Override defeated handler
func _on_defeated() -> void:
    super._on_defeated()  # Call parent
    _remove_disruptions()
    # Signal manager about defeat
    if GlobalGameManager.has("gremlin_manager"):
        GlobalGameManager.gremlin_manager._on_gremlin_defeated(self)

func is_targetable() -> bool:
    if not can_be_targeted:
        return false
    
    match untargetable_condition:
        "while_other_gremlins_exist":
            var manager = GlobalGameManager.gremlin_manager
            return manager.active_gremlin_count <= 1
        _:
            return true
```

### 3.2 Modified File: `src/scenes/core/entities/hero.gd`

**Add Damageable Support:**
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
        var modified = packet.duplicate(true) as DamagePacket
        modified.damage_resistance = max(modified.damage_resistance, 0.2)
        return modified
    
    return packet

## Hero loses when out of cards (different from HP)
func check_card_defeat() -> bool:
    # This is separate from damage-based defeat
    return GlobalGameManager.library.get_cards_in_hand().is_empty()

## Override defeated to handle hero-specific defeat
func _on_defeated() -> void:
    super._on_defeated()
    GlobalSignals.signal_core_defeat()
```

## 4. Combat Effect Integration

### 4.1 Modified File: `src/scenes/core/effects/tourbillon_effect_processor.gd`

**Replace Placeholder Functions:**
```gdscript
static func _effect_damage(amount: int, target_type: String) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        push_warning("No gremlin_manager in GlobalGameManager")
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    
    # Create damage packet using the unified system
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

static func _effect_damage_all(amount: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    var packet = DamageFactory.from_force(_get_current_force_type(), amount, GlobalGameManager.active_gear)
    
    for gremlin in manager.get_gremlins_in_order():
        gremlin.receive_damage(packet)

static func _effect_apply_poison(stacks: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    var target = manager.get_topmost_gremlin()
    
    if target:
        # Poison is handled differently - it adds a beat consumer
        target.apply_poison(stacks)

static func _effect_apply_burn(duration: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    var target = manager.get_topmost_gremlin()
    if target:
        target.apply_burn(duration)

static func _effect_execute(threshold: int) -> void:
    if not GlobalGameManager.has("gremlin_manager"):
        return
    
    var manager = GlobalGameManager.get("gremlin_manager") as GremlinManager
    
    for gremlin in manager.get_gremlins_in_order():
        if gremlin.can_be_executed(threshold):
            gremlin.execute()

static func _get_current_force_type() -> GameResource.Type:
    # Get the active force type from context
    if GlobalGameManager.has_meta("active_force_type"):
        var type_str = GlobalGameManager.get_meta("active_force_type")
        return _parse_force_type(type_str)
    return GameResource.Type.NONE

static func _parse_force_type(type_str: String) -> GameResource.Type:
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

## 5. Constraint UI System

### 5.1 New File: `src/scenes/ui/constraints/ui_constraint_panel.gd`

```gdscript
extends PanelContainer
class_name UIConstraintPanel

## Displays active gremlin constraints and disruptions
## Updates in real-time as constraints change

@onready var constraint_list: VBoxContainer = %ConstraintList
@onready var disruption_timer: Label = %DisruptionTimer

var constraint_items: Dictionary = {}  # constraint_id -> UIConstraintItem

func add_constraint(id: String, description: String, severity: String) -> void
func remove_constraint(id: String) -> void
func update_constraint(id: String, new_value) -> void
func set_disruption_countdown(beats: int) -> void
```

**Responsibilities:**
- Show all active constraints in a list
- Update constraint values in real-time
- Display countdown to next disruption
- Color-code by severity (soft cap = yellow, hard cap = red, etc.)

### 5.2 New File: `src/scenes/ui/constraints/ui_constraint_item.gd`

```gdscript
extends HBoxContainer
class_name UIConstraintItem

## Individual constraint display item

@onready var icon: TextureRect = %Icon
@onready var description: Label = %Description
@onready var value: Label = %Value

func setup(constraint_type: String, desc: String, val) -> void
func update_value(new_val) -> void
func set_severity(level: String) -> void  # "warning", "danger", "critical"
```

## 6. Move Data Loading

### 6.1 Modified File: `src/scenes/core/entities/gremlin.gd`

**Add Move Loading:**
```gdscript
func _ready() -> void:
    # Initialize move controller
    move_controller = GremlinMoveController.new()
    move_controller.owner_gremlin = self
    add_child(move_controller)
    
    # Load moves from moves_string or template data
    if not moves_string.is_empty():
        _load_moves_from_string(moves_string)
    
    # Process downsides
    if not moves_string.is_empty():
        GremlinDownsideProcessor.process_gremlin_moves(moves_string, self)

func _load_moves_from_string(moves_data: String) -> void:
    # Parse move data and create GremlinMove resources
    # Format: "move_id:trigger_interval:effects|move_id2:..."
    # This is simplified - actual implementation would parse JSON
    pass

func load_moves_from_template(template_id: String) -> void:
    # Load move cycle from mob_data.json template
    var mob_data = load("res://mob_data.json")
    # ... parse and load moves ...
```

## 7. Production Modification System

### 7.1 Modified File: `src/scenes/core/entities/card.gd`

**Add Production Calculation:**
```gdscript
func calculate_production_amount() -> int:
    var base_amount = production_amount
    
    # Apply global production tax
    var global_tax = GremlinDownsideProcessor.global_production_tax
    base_amount = int(base_amount * (1.0 - global_tax))
    
    # Apply tag-specific taxes
    for tag in tags:
        if tag in GremlinDownsideProcessor.production_taxes:
            var tag_tax = GremlinDownsideProcessor.production_taxes[tag]
            base_amount = int(base_amount * (1.0 - tag_tax))
    
    # Apply position penalties
    var pos = get_mainplate_position()
    if pos in GremlinDownsideProcessor.position_penalties:
        var penalty = GremlinDownsideProcessor.position_penalties[pos]
        base_amount = int(base_amount * (1.0 - penalty))
    
    # Check if gear is disabled
    if GremlinDownsideProcessor.is_gear_disabled(instance_id):
        return 0
    
    # Apply corruption modifications
    var corruption = GremlinDownsideProcessor.get_gear_corruption(instance_id)
    if corruption.has("production_multiplier"):
        base_amount = int(base_amount * corruption["production_multiplier"])
    
    return max(0, base_amount)
```

## 8. Time Penalty System

### 8.1 Modified File: `src/scenes/core/library.gd`

**Add Time Penalty Calculation:**
```gdscript
func get_card_time_cost(card: Card) -> int:
    var base_cost = card.time_cost_beats
    
    # Apply global time penalty
    base_cost += GremlinDownsideProcessor.time_penalty_beats
    
    # Apply card cost penalty (legacy system)
    base_cost += GremlinDownsideProcessor.active_downsides.get("card_cost_penalty", 0) * 10
    
    # Apply tag-specific penalties
    for tag in card.tags:
        if tag in GremlinDownsideProcessor.tag_time_penalties:
            base_cost += GremlinDownsideProcessor.tag_time_penalties[tag]
    
    # Minimum cost is 1 beat
    return max(1, base_cost)
```

## 9. Force Decay System

### 9.1 Modified File: `src/scenes/core/time/beat_processor.gd`

**Add Decay Phase:**
```gdscript
func process_beat(context: BeatContext) -> void:
    # Phase 1: Process gears in Escapement Order
    __process_gears_phase(context)
    
    # Phase 1.5: Process force decay (NEW)
    __process_force_decay_phase(context)
    
    # Phase 2: Process gremlins
    __process_gremlins_phase(context)
    
    # ... rest of phases ...

func __process_force_decay_phase(context: BeatContext) -> void:
    # Only process on whole ticks (every 10 beats)
    if context.beat_number % 10 != 0:
        return
    
    phase_started.emit("force_decay")
    GremlinDownsideProcessor.process_force_decay()
    phase_completed.emit("force_decay")
```

## 10. Summon System Enhancement

### 10.1 Modified File: `src/scenes/core/battle/gremlin_manager.gd`

**Update to Use Unified Damage System:**
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

## Updated damage function signature for compatibility
func deal_damage_to_target_legacy(amount: int, target_type: String = "topmost", 
                           pierce: bool = false, pop: bool = false, 
                           overkill: bool = false) -> void:
    # Legacy support - convert to damage packet
    var packet = DamagePacket.new()
    packet.base_amount = amount
    packet.pierce = pierce
    packet.pop = pop
    packet.overkill = overkill
    
    deal_damage_to_target(packet, target_type)
```

**Add Summon Functions:**
```gdscript
func summon_gremlin(template_id: String, position: String = "bottom") -> bool:
    # Check summon cap
    if active_gremlin_count >= 5:
        push_warning("Cannot summon: gremlin slots full")
        return false
    
    # Load gremlin template
    var gremlin = _create_gremlin_from_template(template_id)
    if not gremlin:
        return false
    
    # Determine slot based on position
    var slot = -1
    match position:
        "top":
            slot = _find_first_empty_slot()
        "bottom":
            slot = _find_last_empty_slot()
        "random":
            slot = _find_random_empty_slot()
    
    # Add to combat
    return add_gremlin(gremlin, slot)

func _create_gremlin_from_template(template_id: String) -> Gremlin:
    # Load from mob_data.json
    var mob_data = ResourceLoader.load("res://mob_data.json")
    # ... create and configure gremlin ...
    return null  # Placeholder
```

## 11. Integration Points

### 11.1 Modified File: `src/scenes/core/global_game_manager.gd`

**Add References:**
```gdscript
var gremlin_manager: GremlinManager
var constraint_ui: UIConstraintPanel

func _ready() -> void:
    # ... existing setup ...
    
    # Create gremlin manager
    gremlin_manager = GremlinManager.new()
    add_child(gremlin_manager)
    
    # Connect to beat processor
    if beat_processor:
        beat_processor.set_gremlin_manager(gremlin_manager)
```

### 11.2 Modified File: `src/scenes/ui/main_ui.gd`

**Add Constraint Panel:**
```gdscript
@onready var constraint_panel: UIConstraintPanel = %ConstraintPanel

func _ready() -> void:
    # ... existing setup ...
    
    # Register constraint panel with game manager
    GlobalGameManager.constraint_ui = constraint_panel
    
    # Hide initially
    constraint_panel.visible = false

func on_combat_started() -> void:
    constraint_panel.visible = true
    constraint_panel.clear()

func on_combat_ended() -> void:
    constraint_panel.visible = false
```

## 12. Data Migration

### 12.1 New File: `tools/migrate_gremlin_data.gd`

```gdscript
extends Node

## Migrates mob_data.json to new gremlin schema
## Run as tool script to update data files

func migrate_mob_data() -> void:
    var old_data = load_json("res://mob_data.json")
    var new_data = []
    
    for mob in old_data:
        var gremlin = {
            "template_id": mob["template_id"],
            "display_name": mob["display_name"],
            "max_health": mob["max_health"],
            "move_cycle": convert_moves(mob),
            # ... map other fields ...
        }
        new_data.append(gremlin)
    
    save_json("res://gremlin_data.json", new_data)
```

## Implementation Priority

### Phase 1 - Core Systems (Week 1)
1. GremlinMove and GremlinMoveController classes
2. Enhanced GremlinDownsideProcessor with new constraint types
3. Combat effect integration in TourbillonEffectProcessor
4. Basic constraint UI panel

### Phase 2 - Advanced Mechanics (Week 2)
1. Advanced defense mechanics (barriers, damage cap, reflect)
2. Production modification system
3. Time penalty system
4. Force decay implementation

### Phase 3 - Polish & Data (Week 3)
1. Summon system enhancements
2. Move data loading from JSON
3. Data migration from old mob_data
4. Visual polish and animations
5. Testing and balance adjustments

## Testing Requirements

### Unit Tests Needed:
- Move cycle transitions
- Constraint stacking/removal
- Damage calculation with modifiers
- Production tax calculations
- Force decay rates
- Barrier/damage cap mechanics

### Integration Tests:
- Full combat with multiple gremlins
- Constraint UI updates
- Save/load with active constraints
- Move cycle persistence
- Summon chain reactions

## Performance Considerations

1. **Constraint Checking**: Cache constraint calculations per beat to avoid recalculating for every gear
2. **UI Updates**: Batch constraint UI updates to once per beat maximum
3. **Move Processing**: Use object pooling for move effects to avoid allocation
4. **Force Decay**: Only process on whole ticks, not every beat
5. **Production Modifiers**: Calculate once per gear fire, cache results

## Configuration Files

### New File: `res://data/gremlin_moves.json`
Contains all possible move definitions that gremlins can use.

### New File: `res://data/gremlin_constraints.json`
Defines all constraint types and their UI representations.

### Modified File: `res://mob_data.json`
Update to match new schema from GREMLIN_SCHEMA.md

## Success Criteria

The implementation is complete when:
1. All gremlins can execute move cycles with proper transitions
2. All constraint types from PRD are functional
3. Combat damage properly integrates with force multipliers
4. UI clearly shows all active constraints
5. Advanced defenses (barriers, reflect, caps) work correctly
6. Summon chains don't break the game
7. Performance remains smooth with 5 gremlins active
8. Save/load preserves all gremlin state

---

This design provides a complete roadmap for implementing the full gremlin system as specified in the PRD, with clear file responsibilities and integration points.