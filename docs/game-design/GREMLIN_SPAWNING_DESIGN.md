# Gremlin Spawning System Design

## Overview

This design follows the existing entity-based pattern where we load mob definitions from JSON data files and spawn them as Entity instances using the Builder pattern. The system integrates with the existing StaticData loader and Entity hierarchy.

## Data Structure

### 1. Mob Data (mob_data.json)

```json
[
  {
    "mob_id": "gremlin_basic",
    "display_name": "Gremlin",
    "max_health": 12,
    "movement": 2,
    "attack_damage": 6,
    "attack_range": 1,
    "defense": 0,
    "spawn_weight": 10,
    "tier": 1,
    "abilities": ["scratch"],
    "loot_table": "gremlin_basic_loot",
    "sprite_path": "res://assets/sprites/mobs/gremlin_basic.png"
  },
  {
    "mob_id": "gremlin_warrior", 
    "display_name": "Gremlin Warrior",
    "max_health": 20,
    "movement": 2,
    "attack_damage": 10,
    "attack_range": 1,
    "defense": 2,
    "spawn_weight": 5,
    "tier": 2,
    "abilities": ["scratch", "guard"],
    "loot_table": "gremlin_warrior_loot",
    "sprite_path": "res://assets/sprites/mobs/gremlin_warrior.png"
  },
  {
    "mob_id": "gremlin_shaman",
    "display_name": "Gremlin Shaman",
    "max_health": 15,
    "movement": 1,
    "attack_damage": 8,
    "attack_range": 3,
    "defense": 0,
    "spawn_weight": 3,
    "tier": 2,
    "abilities": ["hex", "heal_ally"],
    "loot_table": "gremlin_shaman_loot",
    "sprite_path": "res://assets/sprites/mobs/gremlin_shaman.png"
  }
]
```

### 2. Wave Data (wave_data.json)

```json
[
  {
    "wave_id": "tutorial_1",
    "wave_number": 1,
    "display_name": "First Encounter",
    "spawn_budget": 10,
    "min_mobs": 1,
    "max_mobs": 2,
    "allowed_mob_tiers": [1],
    "specific_mobs": ["gremlin_basic"],
    "spawn_pattern": "random",
    "difficulty_modifier": 0.8
  },
  {
    "wave_id": "wave_1",
    "wave_number": 2,
    "display_name": "Gremlin Scouts",
    "spawn_budget": 20,
    "min_mobs": 2,
    "max_mobs": 3,
    "allowed_mob_tiers": [1],
    "specific_mobs": [],
    "spawn_pattern": "random",
    "difficulty_modifier": 1.0
  },
  {
    "wave_id": "wave_2",
    "wave_number": 3,
    "display_name": "Warriors Arrive",
    "spawn_budget": 35,
    "min_mobs": 2,
    "max_mobs": 4,
    "allowed_mob_tiers": [1, 2],
    "specific_mobs": [],
    "spawn_pattern": "mixed",
    "difficulty_modifier": 1.1
  },
  {
    "wave_id": "boss_1",
    "wave_number": 10,
    "display_name": "Gremlin Chief",
    "spawn_budget": 100,
    "min_mobs": 1,
    "max_mobs": 1,
    "allowed_mob_tiers": [3],
    "specific_mobs": ["gremlin_chief"],
    "spawn_pattern": "boss",
    "difficulty_modifier": 1.5
  }
]
```

## Architecture

### 1. Enable Data Sources

First, update `data_config.gd`:

```gdscript
"mob_data": {
    "path": "res://app/src/data/mob_data.json",
    "is_static": false,
    "enabled": true,  # Change to true
    "description": "Mob/enemy definitions"
},
"wave_data": {
    "path": "res://app/src/data/wave_data.json",
    "is_static": false,
    "enabled": true,  # Change to true
    "description": "Wave progression data"
}
```

### 2. WaveManager (Singleton)

Location: `app/src/managers/wave_manager.gd`

```gdscript
extends Node
class_name WaveManager

var current_wave_number: int = 0
var current_wave_data: Dictionary = {}
var spawned_mobs: Array[String] = []  # Instance IDs

signal wave_started(wave_data: Dictionary)
signal wave_completed(wave_number: int)
signal all_waves_completed()

func start_wave(wave_number: int) -> void:
    # Load wave data from StaticData
    var wave_data = StaticData.get_data_source("wave_data")
    current_wave_data = _get_wave_by_number(wave_data, wave_number)
    
    if current_wave_data.is_empty():
        push_error("No wave data for wave number: " + str(wave_number))
        return
    
    current_wave_number = wave_number
    spawned_mobs.clear()
    
    # Determine mobs to spawn
    var mobs_to_spawn = _calculate_spawn_list(current_wave_data)
    
    # Spawn mobs via SpawnController
    for mob_template_id in mobs_to_spawn:
        var mob = SpawnController.spawn_mob(mob_template_id)
        if mob:
            spawned_mobs.append(mob.instance_id)
    
    wave_started.emit(current_wave_data)

func _calculate_spawn_list(wave_data: Dictionary) -> Array[String]:
    var spawn_list: Array[String] = []
    var budget = wave_data.get("spawn_budget", 10)
    var min_mobs = wave_data.get("min_mobs", 1)
    var max_mobs = wave_data.get("max_mobs", 3)
    
    # If specific mobs are defined, use those
    var specific_mobs = wave_data.get("specific_mobs", [])
    if not specific_mobs.is_empty():
        return specific_mobs
    
    # Otherwise, select from allowed tiers within budget
    var allowed_tiers = wave_data.get("allowed_mob_tiers", [1])
    var mob_data = StaticData.get_data_source("mob_data")
    
    # Get eligible mobs
    var eligible_mobs = _get_mobs_by_tiers(mob_data, allowed_tiers)
    
    # Spawn within budget constraints
    var current_budget = 0
    var mob_count = 0
    var max_attempts = 100
    
    while current_budget < budget and mob_count < max_mobs and max_attempts > 0:
        max_attempts -= 1
        
        # Weighted random selection
        var selected_mob = _weighted_mob_selection(eligible_mobs)
        var mob_cost = selected_mob.get("spawn_weight", 10)
        
        if current_budget + mob_cost <= budget:
            spawn_list.append(selected_mob.get("mob_id"))
            current_budget += mob_cost
            mob_count += 1
    
    # Ensure minimum mobs
    while spawn_list.size() < min_mobs and eligible_mobs.size() > 0:
        var cheapest = _get_cheapest_mob(eligible_mobs)
        spawn_list.append(cheapest.get("mob_id"))
    
    return spawn_list
```

### 3. SpawnController

Location: `app/src/core/spawn_controller.gd`

```gdscript
extends Node
class_name SpawnController

signal mob_spawned(mob: Mob)
signal mob_despawned(mob_id: String)

func spawn_mob(mob_template_id: String, spawn_position: Vector2i = Vector2i.ZERO) -> Mob:
    # Use existing Mob.build_new_mob_from_template
    var mob = Mob.build_new_mob_from_template(mob_template_id)
    
    if not mob:
        push_error("Failed to spawn mob: " + mob_template_id)
        return null
    
    # Set spawn position
    if spawn_position != Vector2i.ZERO:
        mob.position = spawn_position
    else:
        mob.position = _get_random_spawn_position()
    
    # Register with entity manager
    EntityManager.register_entity(mob)
    
    # Signal creation
    mob.signal_created()
    mob_spawned.emit(mob)
    
    return mob

func _get_random_spawn_position() -> Vector2i:
    # Get valid spawn positions from map
    var map = GlobalGameManager.get_current_map()
    if not map:
        return Vector2i.ZERO
    
    var spawn_tiles = map.get_spawn_tiles()
    if spawn_tiles.is_empty():
        # Fallback to random edge position
        return _get_random_edge_position()
    
    return spawn_tiles.pick_random()

func _get_random_edge_position() -> Vector2i:
    # Spawn on map edges
    var map_size = GlobalGameManager.get_map_size()
    var edge = randi() % 4
    
    match edge:
        0: # Top
            return Vector2i(randi() % map_size.x, 0)
        1: # Right
            return Vector2i(map_size.x - 1, randi() % map_size.y)
        2: # Bottom
            return Vector2i(randi() % map_size.x, map_size.y - 1)
        3: # Left
            return Vector2i(0, randi() % map_size.y)
    
    return Vector2i.ZERO

func despawn_mob(mob_id: String) -> void:
    EntityManager.unregister_entity(mob_id)
    mob_despawned.emit(mob_id)
```

### 4. Enhanced Mob Class

Update the existing `mob.gd` to support spawn data:

```gdscript
# Add to MobBuilder class:
class MobBuilder extends BattleEntity.BattleEntityBuilder:
    var __attack_damage: int = 5
    var __attack_range: int = 1
    var __defense: int = 0
    var __abilities: Array[String] = []
    var __loot_table: String = ""
    var __sprite_path: String = ""
    
    func with_attack_stats(damage: int, range: int) -> MobBuilder:
        __attack_damage = damage
        __attack_range = range
        return self
    
    func with_defense(defense: int) -> MobBuilder:
        __defense = defense
        return self
    
    func with_abilities(abilities: Array) -> MobBuilder:
        __abilities = abilities
        return self
    
    func with_loot_table(loot_table: String) -> MobBuilder:
        __loot_table = loot_table
        return self

# Update build_new_mob_from_template:
static func build_new_mob_from_template(mob_template_id: String) -> Mob:
    var mob_data_source = StaticData.get_data_source("mob_data")
    var mob_data = mob_data_source.get(mob_template_id, {})
    
    if mob_data.is_empty():
        push_error("Mob template not found: " + mob_template_id)
        return null
    
    # Create builder with all data
    var builder = Mob.MobBuilder.new() \
        .with_display_name(mob_data.get("display_name", "Unknown")) \
        .with_template_id(mob_template_id) \
        .with_movement_range(int(mob_data.get("movement", 1))) \
        .with_attack_stats(
            int(mob_data.get("attack_damage", 5)),
            int(mob_data.get("attack_range", 1))
        ) \
        .with_defense(int(mob_data.get("defense", 0))) \
        .with_abilities(mob_data.get("abilities", [])) \
        .with_loot_table(mob_data.get("loot_table", ""))
    
    var mob = builder.build()
    
    # Set up health
    var max_health: int = mob_data.get("max_health", 10)
    var on_health_change: Callable = func(value): 
        Signals.signal_core_mob_resource_changed(mob.instance_id, GameResource.Type.HEALTH, value)
        Signals.signal_core_mob_check_state(mob.instance_id, value)
    
    mob.health = GameResource.new(max_health, on_health_change, Callable(), max_health)
    
    return mob
```

## Usage Example

```gdscript
# In game scene or battle manager:

func _ready():
    # Connect to wave signals
    WaveManager.wave_completed.connect(_on_wave_completed)
    WaveManager.all_waves_completed.connect(_on_all_waves_completed)

func start_battle():
    # Start first wave
    WaveManager.start_wave(1)

func _on_wave_completed(wave_number: int):
    # Give rewards, show UI, etc.
    await get_tree().create_timer(2.0).timeout
    
    # Start next wave
    WaveManager.start_wave(wave_number + 1)

func _on_all_waves_completed():
    # Victory!
    show_victory_screen()
```

## Integration Points

1. **EntityManager** - All spawned mobs are registered as entities
2. **StaticData** - Mob and wave definitions loaded from JSON
3. **Signals** - Uses existing signal system for mob events
4. **GlobalGameManager** - Gets map information for spawn positions
5. **Battle System** - Mobs participate in turn-based combat

## Benefits of This Design

1. **Data-Driven**: All mob and wave configurations in JSON files
2. **Reuses Existing Patterns**: Builder pattern, Entity hierarchy, StaticData loader
3. **Flexible**: Easy to add new mob types and wave configurations
4. **Balanced**: Spawn budget system prevents overwhelming players
5. **Extensible**: Can add special spawn patterns, boss mechanics, etc.

## Next Steps

1. Create the JSON data files with initial mob and wave definitions
2. Enable the data sources in data_config.gd
3. Implement WaveManager singleton
4. Implement SpawnController
5. Enhance Mob class with new properties
6. Create spawn position markers in maps
7. Test with tutorial wave