# Type Safety in Godot Projects

## Overview

Type safety is enforced through compile-time checks to catch errors early and improve code quality.

## Why Type Safety Matters

1. **Early Error Detection**: Catch type mismatches at compile time, not runtime
2. **Better IDE Support**: Autocomplete and IntelliSense work properly
3. **Self-Documenting Code**: Types serve as inline documentation
4. **Performance**: Godot can optimize typed code better
5. **Refactoring Safety**: Changes to types are caught immediately

## Required Type Annotations

### Variables

**❌ Bad - Untyped:**
```gdscript
var health = 100
var player_name = "Hero"
var enemies = []
var positions = {}
```

**✅ Good - Typed:**
```gdscript
var health: int = 100
var player_name: String = "Hero"
var enemies: Array[Enemy] = []
var positions: Dictionary[String, Vector2] = {}
```

### Functions

**❌ Bad - Missing return type:**
```gdscript
func calculate_damage(base, multiplier):
    return base * multiplier

func process_turn():
    # process logic
```

**✅ Good - Fully typed:**
```gdscript
func calculate_damage(base: float, multiplier: float) -> float:
    return base * multiplier

func process_turn() -> void:
    # process logic
```

### Parameters

**❌ Bad - Untyped parameters:**
```gdscript
func apply_effect(target, effect, duration):
    # apply effect
```

**✅ Good - Typed parameters:**
```gdscript
func apply_effect(target: Entity, effect: StatusEffect, duration: float) -> void:
    # apply effect
```

## Advanced Type Patterns

### Typed Arrays
```gdscript
var items: Array[Item] = []
var numbers: Array[int] = [1, 2, 3]
var positions: Array[Vector2] = []
```

### Typed Dictionaries
```gdscript
var inventory: Dictionary[String, Item] = {}
var scores: Dictionary[int, float] = {}
var entity_map: Dictionary[Vector2i, Entity] = {}
```

### Nullable Types
```gdscript
func find_enemy(id: int) -> Enemy:
    # Returns Enemy or null
    return enemies.get(id, null) as Enemy

func get_optional_config() -> Variant:
    # Can return any type or null
    return config.get("optional_setting")
```

### Type Casting
```gdscript
var node: Node = get_node("Player")
var player: Player = node as Player
if player:
    player.take_damage(10)
```

## Common Godot Types

### Built-in Value Types
- `int`, `float`, `bool`
- `String`, `StringName`
- `Vector2`, `Vector3`, `Vector2i`, `Vector3i`
- `Color`, `Rect2`, `Transform2D`, `Transform3D`

### Node Types
- `Node`, `Node2D`, `Node3D`
- `Control`, `Container`, `Panel`
- `Sprite2D`, `AnimatedSprite2D`
- `CharacterBody2D`, `RigidBody2D`, `Area2D`

### Resource Types
- `Resource`, `Texture2D`, `PackedScene`
- `AudioStream`, `Font`, `Theme`
- `Animation`, `AnimationLibrary`

### Collections
- `Array[Type]` - Typed arrays
- `Dictionary[KeyType, ValueType]` - Typed dictionaries
- `PackedByteArray`, `PackedInt32Array`, `PackedFloat32Array`
- `PackedStringArray`, `PackedVector2Array`

## Enum Types

```gdscript
enum State {
    IDLE,
    WALKING,
    RUNNING,
    JUMPING
}

var current_state: State = State.IDLE

func change_state(new_state: State) -> void:
    current_state = new_state
```

## Custom Class Types

```gdscript
class_name Player
extends CharacterBody2D

var inventory: Inventory
var stats: PlayerStats

func equip_item(item: Item) -> bool:
    return inventory.add_item(item)
```

## Signal Types

```gdscript
signal health_changed(new_health: int, max_health: int)
signal item_collected(item: Item)
signal enemy_defeated(enemy: Enemy, experience: int)
```

## Migration Strategy

### Phase 1: Add to New Code
- All new functions must have typed parameters and return types
- All new variables must have type annotations

### Phase 2: Update High-Traffic Code
- Core gameplay loops
- Frequently called functions
- Public APIs

### Phase 3: Gradual Migration
- Use exemptions for legacy code
- Update one file at a time
- Remove from exemptions when complete

## Exemptions

When you can't add types immediately:

```gdscript
# EXEMPT: TYPE_CHECK
var legacy_variable = get_legacy_data()

# For entire files, add to exemptions in compile check:
"type_check_exempt": ["res://src/legacy/old_system.gd"]
```

## Benefits in Practice

### Before Type Safety
```gdscript
func process_damage(attacker, target, weapon):
    # What types are these? What properties do they have?
    var damage = weapon.damage * attacker.strength
    target.health -= damage  # Will this work?
```

### After Type Safety
```gdscript
func process_damage(attacker: Unit, target: Unit, weapon: Weapon) -> int:
    # Clear types, IDE knows all properties
    var damage: int = weapon.damage * attacker.strength
    target.health -= damage  # IDE validates this
    return damage
```

## Common Pitfalls

### Variant Type
Avoid using `Variant` unless truly needed:
```gdscript
# Bad - loses type safety
var data: Variant = get_data()

# Good - preserve type information
var data: Dictionary[String, int] = get_data()
```

### Type Inference
Let Godot infer types when obvious:
```gdscript
# Redundant
var node: Node = Node.new()

# Clean - type is obvious
var node := Node.new()
```

### Const vs Var
Use `const` for immutable values:
```gdscript
const MAX_HEALTH: int = 100
const GRAVITY: float = 980.0
const PLAYER_NAME: String = "Hero"
```