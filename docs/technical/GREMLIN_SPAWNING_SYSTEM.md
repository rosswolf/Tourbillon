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

Tourbillon already has a Gremlin class that extends BeatListenerEntity (which extends Entity):

**Location**: `elastic-app/app/src/scenes/core/entities/gremlin.gd`

```gdscript
# Existing Gremlin class structure
extends BeatListenerEntity
class_name Gremlin

# Core properties (already implemented)
@export var gremlin_name: String = "Gremlin"
@export var max_hp: int = 10
@export var slot_index: int = 0  # Position in gremlin column (0-4)
@export var moves_string: String = ""  # Downsides/moves from data

# Defense properties (already implemented)
var current_hp: int
var shields: int = 0
var armor: int = 0
var barrier_count: int = 0
var burn_duration: int = 0
var damage_cap: int = 0
var damage_resistance: float = 0.0
var reflect_percent: float = 0.0
var execute_immunity_threshold: int = 0
var invulnerable: bool = false

# Uses composition pattern with Damageable for damage handling
var _damage_handler: Damageable

# Beat processing (already integrated with time system)
func process_beat(context: BeatContext) -> void
```

The existing implementation already:
- Extends BeatListenerEntity for time-based triggers
- Uses composition with Damageable for unified damage handling
- Has Builder pattern support via GremlinBuilder
- Processes moves/downsides via GremlinDownsideProcessor
- Integrates with the beat/tick time system

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

### 2. Spawning Integration with Existing Gremlin Class

Since Gremlin already exists with full damage handling and beat processing, spawning only needs to:

```gdscript
# In GremlinSpawnController
func spawn_from_template(template_id: String) -> Gremlin:
    var mob_data = StaticData.get_data_source("mob_data").get(template_id, {})
    
    # Use existing GremlinBuilder
    var builder = Gremlin.GremlinBuilder.new()
    builder.with_name(mob_data.get("display_name", "Unknown"))
    builder.with_hp(mob_data.get("max_health", 10))
    builder.with_armor(mob_data.get("max_armor", 0))
    builder.with_shields(mob_data.get("max_shields", 0))
    builder.with_barriers(mob_data.get("barrier_count", 0))
    builder.with_moves(mob_data.get("moves_string", ""))
    
    var gremlin = builder.build()
    
    # Register with beat system
    BeatManager.register_listener(gremlin)
    
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