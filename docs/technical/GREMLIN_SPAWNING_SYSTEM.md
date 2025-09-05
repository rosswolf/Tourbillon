# Gremlin Spawning System Design

## Overview

This document defines the entity-based spawning system for Gremlins in Tourbillon. Gremlins are clockwork parasites that disrupt the player's mechanism through constraints and disruptions. The system loads gremlin definitions from `mob_data.json` and spawns them as Entity instances following the existing architectural patterns.

## Core Context

In Tourbillon:
- Time only advances when cards are played (in Beats, 10 Beats = 1 Tick)
- Gremlins impose constraints (soft caps, hard caps, timing penalties)
- Gremlins have move cycles that trigger based on time advancement
- Combat is not turn-based but time-based (everything triggers on intervals)

## Data Architecture

### Google Sheets as Source of Truth

All game data originates from Google Sheets and is synced to local JSON files:

1. **Card Data Sheet**
   - **Spreadsheet ID**: `1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk`
   - **URL**: https://docs.google.com/spreadsheets/d/1zoNrBnX2od6nrTL3G4wS_QMYig69laRn0XYH-KOUqTk/edit
   - **Sheet**: `card_data`

2. **Wave Data Sheet** 
   - **Spreadsheet ID**: `1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw`
   - **URL**: https://docs.google.com/spreadsheets/d/1Bv6R-AZtzmG_ycwudZ5Om6dKrJgl6Ut9INw7GTJFUlw/edit
   - **Sheet**: Contains wave compositions and difficulty settings
   - **Sync Script**: `update_wave_sheet.js`
   - **Columns**: wave_id | display_name | act | difficulty | difficulty_tier | archetype | strategy_hint | gremlins | is_boss

3. **Authentication**
   - **Service Account**: `claude-sheets-mcp@wnann-dev.iam.gserviceaccount.com`
   - **Key File**: `~/Code/google-sheets-mcp/service-account-key.json`

### Local Data Files

After syncing from Google Sheets:

1. **mob_data.json** - Complete gremlin definitions including:
   - Basic properties (health, armor, shields, barriers)
   - Defense mechanisms (damage caps, reflect, execute immunity)
   - Move cycles and timing patterns
   - Archetype classifications (fodder, rush, turtle, disruption, etc.)

2. **Wave data** - Wave compositions including:
   - **wave_id**: Unique identifier (e.g., "wave_1a", "boss_1")
   - **display_name**: Human-readable name (e.g., "First Contact", "The Rust King's Domain")
   - **act**: Act number (1, 2, 3)
   - **difficulty**: Numeric difficulty value
   - **difficulty_tier**: Text tier (Trivial, Easy, Medium, Hard, Nightmare, Nightmare+)
   - **archetype**: Combat strategy type (e.g., "Rush Threat", "Turtle Threat", "Synergy")
   - **strategy_hint**: Player guidance text
   - **gremlins**: Pipe-separated list of gremlin template_ids (e.g., "dust_mite|oil_thief|dust_mite")
   - **is_boss**: Boolean flag for boss encounters

### Example Wave Data

From the wave sheet, here are some example wave configurations:

#### Tutorial Waves (Act 1)
- **wave_1a** - "First Contact": Single `dust_mite` (Trivial difficulty)
  - Teaches soft caps and resource spending pressure
- **wave_1d** - "Swarm Basics": `basic_gnat|basic_gnat|basic_gnat` 
  - Teaches AOE vs single-target efficiency

#### Mid-Game Waves (Act 2)  
- **wave_2a** - "Turtle and Rush": `oil_thief|dust_mite|dust_mite` (Hard)
  - Tests priority targeting between rush and turtle enemies
- **wave_2f** - "The Spawning Nightmare": `temporal_glutton|breeding_barrier_gnat` (Nightmare)
  - Ultimate summoning challenge with protection

#### Boss Encounters
- **boss_1** - "The Rust King's Domain": `rust_king_phase_1|spring_snapper|spring_snapper` (Nightmare+)
  - Phase transitions with scaling support
- **boss_2** - "Temporal Collapse": `chronophage|time_nibbler` (Nightmare+)
  - Tests all timing and constraint management skills

### Entity Integration

Following the existing pattern in `workjam3.5/app/libraries_submodules/common/core/entities/mob.gd`:

```gdscript
# Gremlins extend the Mob class which extends BattleEntity
extends Mob
class_name Gremlin

# Additional properties for Tourbillon gremlins
var move_cycle: Array[GremlinMove] = []
var current_move_index: int = 0
var current_move_timer: float = 0.0  # In Beats
var trigger_count: int = 0

# Constraint tracking
var active_constraints: Dictionary = {}  # constraint_type -> value
var passive_effects: Array[GremlinEffect] = []
```

## Spawning System Architecture

### 1. GremlinSpawnController (Singleton)

Location: `elastic-app/app/src/core/gremlin_spawn_controller.gd`

```gdscript
extends Node
class_name GremlinSpawnController

signal gremlin_spawned(gremlin: Gremlin)
signal wave_spawned(gremlins: Array[Gremlin])
signal all_gremlins_defeated()

var active_gremlins: Array[String] = []  # Instance IDs
var spawn_queue: Array[String] = []  # Template IDs to spawn

func spawn_gremlin(template_id: String, position: int = -1) -> Gremlin:
    var gremlin_data = StaticData.get_data_source("mob_data").get(template_id, {})
    
    if gremlin_data.is_empty():
        push_error("Gremlin template not found: " + template_id)
        return null
    
    # Use Builder pattern
    var gremlin = Gremlin.build_from_template(gremlin_data)
    
    # Set position (top to bottom ordering matters)
    if position >= 0:
        gremlin.combat_position = position
    else:
        gremlin.combat_position = active_gremlins.size()
    
    # Register with entity system
    EntityManager.register_entity(gremlin)
    active_gremlins.append(gremlin.instance_id)
    
    # Initialize move cycle
    gremlin.initialize_move_cycle()
    
    # Signal spawn
    gremlin.signal_created()
    gremlin_spawned.emit(gremlin)
    
    return gremlin

func spawn_wave(wave_composition: String) -> Array[Gremlin]:
    # Parse pipe-separated gremlin list
    var gremlin_ids = wave_composition.split("|")
    var spawned: Array[Gremlin] = []
    
    for template_id in gremlin_ids:
        var gremlin = spawn_gremlin(template_id.strip_edges())
        if gremlin:
            spawned.append(gremlin)
    
    wave_spawned.emit(spawned)
    return spawned
```

### 2. Gremlin Entity Class

Location: `elastic-app/app/src/core/entities/gremlin.gd`

```gdscript
extends Mob
class_name Gremlin

# Move cycle management
var move_cycle: Array[GremlinMove] = []
var current_move: GremlinMove = null
var move_timer_beats: float = 0.0
var triggers_this_move: int = 0

# Gremlin-specific properties from schema
var archetype: String = ""
var size_category: String = ""
var has_barrier: bool = false
var barrier_count: int = 0
var damage_cap: int = 0
var reflect_percent: float = 0.0
var execute_immunity_threshold: int = 0

func _init():
    Signals.time_advanced.connect(_on_time_advanced)

func _on_time_advanced(beats: float):
    if not current_move:
        return
    
    move_timer_beats += beats
    
    # Check for move triggers
    if current_move.trigger_interval > 0:
        var trigger_threshold = current_move.trigger_interval * 10  # Convert ticks to beats
        while move_timer_beats >= trigger_threshold:
            _trigger_current_move()
            move_timer_beats -= trigger_threshold
            triggers_this_move += 1
            
            # Check max triggers
            if current_move.max_triggers > 0 and triggers_this_move >= current_move.max_triggers:
                _advance_to_next_move()
                break
    
    # Check for move duration
    if current_move.duration_ticks > 0:
        var duration_beats = current_move.duration_ticks * 10
        if move_timer_beats >= duration_beats:
            _advance_to_next_move()

func _trigger_current_move():
    # Apply trigger effects
    for effect in current_move.trigger_effects:
        _apply_effect(effect)
    
    # Signal for UI updates
    Signals.signal_gremlin_triggered(instance_id, current_move.move_name)

func _apply_effect(effect: GremlinEffect):
    match effect.effect_type:
        "force_soft_cap":
            GlobalGameManager.apply_soft_cap(effect.force_types, effect.value)
        "force_drain":
            GlobalGameManager.drain_forces(effect.force_types, effect.value)
        "card_cost_penalty":
            GlobalGameManager.add_time_penalty(effect.value)
        "summon_gremlin":
            GremlinSpawnController.spawn_gremlin(effect.summon_template_id)
        _:
            push_warning("Unknown effect type: " + effect.effect_type)

# Builder pattern
static func build_from_template(gremlin_data: Dictionary) -> Gremlin:
    var builder = GremlinBuilder.new()
    
    builder.with_display_name(gremlin_data.get("display_name", "Unknown")) \
        .with_archetype(gremlin_data.get("archetype", "basic")) \
        .with_max_health(gremlin_data.get("max_health", 1)) \
        .with_armor(gremlin_data.get("max_armor", 0)) \
        .with_shields(gremlin_data.get("max_shields", 0)) \
        .with_barrier(
            gremlin_data.get("has_barrier", false),
            gremlin_data.get("barrier_count", 0)
        ) \
        .with_damage_cap(gremlin_data.get("damage_cap", 0)) \
        .with_move_cycle(gremlin_data.get("move_cycle", []))
    
    return builder.build()

class GremlinBuilder extends Mob.MobBuilder:
    var _archetype: String = ""
    var _armor: int = 0
    var _shields: int = 0
    var _has_barrier: bool = false
    var _barrier_count: int = 0
    var _damage_cap: int = 0
    var _move_cycle: Array = []
    
    func with_archetype(archetype: String) -> GremlinBuilder:
        _archetype = archetype
        return self
    
    func with_armor(armor: int) -> GremlinBuilder:
        _armor = armor
        return self
    
    func with_barrier(has_barrier: bool, count: int) -> GremlinBuilder:
        _has_barrier = has_barrier
        _barrier_count = count
        return self
    
    func with_move_cycle(moves: Array) -> GremlinBuilder:
        _move_cycle = moves
        return self
    
    func build() -> Gremlin:
        var gremlin = Gremlin.new()
        
        # Apply base entity properties
        super.build_entity(gremlin)
        
        # Apply gremlin-specific properties
        gremlin.archetype = _archetype
        gremlin.armor = _armor
        gremlin.shields = _shields
        gremlin.has_barrier = _has_barrier
        gremlin.barrier_count = _barrier_count
        gremlin.damage_cap = _damage_cap
        
        # Parse and set move cycle
        for move_data in _move_cycle:
            var move = GremlinMove.from_dict(move_data)
            gremlin.move_cycle.append(move)
        
        # Initialize first move
        if gremlin.move_cycle.size() > 0:
            gremlin.current_move = gremlin.move_cycle[0]
            gremlin._apply_passive_effects()
        
        return gremlin
```

### 3. Integration with Time System

Since Tourbillon's time advances in Beats when cards are played:

```gdscript
# In GlobalGameManager or TimeManager
signal time_advanced(beats: float)

func advance_time(ticks: float):
    var beats = ticks * 10  # Convert ticks to beats
    
    # Process each beat
    for i in range(int(beats)):
        _process_single_beat()
    
    # Handle fractional beats if any
    var fractional = beats - int(beats)
    if fractional > 0:
        _process_fractional_beat(fractional)
    
    time_advanced.emit(beats)

func _process_single_beat():
    # Order matters - follows PRD specification
    # 1. Gear Phase
    _process_gears()
    
    # 2. Poison Resolution
    _process_poison()
    
    # 3. Gremlin Phase
    _process_gremlins()
    
    # 4. End of beat checks
    _check_victory_conditions()
```

## Wave Management

### WaveManager

Location: `elastic-app/app/src/managers/wave_manager.gd`

```gdscript
extends Node
class_name WaveManager

var current_wave_id: String = ""
var waves_data: Dictionary = {}  # Loaded from sheets or JSON

signal wave_started(wave_id: String, gremlins: Array)
signal wave_completed(wave_id: String)

func load_wave_data():
    # Could load from Google Sheets or local JSON
    # For now, use the hardcoded data from update_wave_sheet.js
    pass

func start_wave(wave_id: String):
    var wave = waves_data.get(wave_id, {})
    if wave.is_empty():
        push_error("Wave not found: " + wave_id)
        return
    
    current_wave_id = wave_id
    
    # Parse gremlin composition
    var gremlin_list = wave.get("gremlins", "")
    var spawned = GremlinSpawnController.spawn_wave(gremlin_list)
    
    wave_started.emit(wave_id, spawned)
    
    # Show strategy hint to player
    if wave.has("strategy_hint"):
        UI.show_strategy_hint(wave["strategy_hint"])
```

## Usage Example

```gdscript
# In main game scene
func start_combat():
    # Load first wave
    WaveManager.start_wave("wave_1a")
    
    # Gremlins are now active and will respond to time advancement

func _on_card_played(card: Card):
    # Playing a card advances time
    var time_cost = card.get_time_cost()  # In ticks
    GlobalGameManager.advance_time(time_cost)
    
    # This triggers all gremlin move cycles automatically

func _on_all_gremlins_defeated():
    # Wave complete
    WaveManager.wave_completed.emit(WaveManager.current_wave_id)
    
    # Load next wave or show rewards
    show_wave_complete_screen()
```

## Key Design Decisions

1. **Time-Based, Not Turn-Based**: Gremlins react to time advancement from card plays, not discrete turns
2. **Entity Pattern**: Gremlins are Entities registered with EntityManager for consistent tracking
3. **Builder Pattern**: Complex gremlin initialization uses Builder for clean construction
4. **Data-Driven**: All gremlin properties and moves defined in JSON for easy balancing
5. **Signal-Based**: Uses Godot signals for loose coupling between systems
6. **Beat Resolution**: Internal time tracking in Beats (0.1 Tick) for precise timing

## Benefits

- **Consistent with Tourbillon mechanics**: Time-based triggers match the game's core loop
- **Reuses existing patterns**: Extends Mob/Entity classes from workjam3.5
- **Data-driven balancing**: JSON files can be edited without code changes
- **Modular**: Each system (spawn, time, combat) is independent but connected via signals
- **Scalable**: Easy to add new gremlin types, effects, and move patterns