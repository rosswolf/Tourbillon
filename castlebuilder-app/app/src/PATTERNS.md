# Src - Source Code Patterns

## Type Safety

- Always use strong typing with specific class names: `var player: DungeonPlayer` not `var player: Node2D`
- Use abstract types only when polymorphism is needed: `var provider: MapProvider` when accepting different map types
- All variables must have explicit types: `var count: int = 0` not `var count = 0`
- All function parameters and returns must be typed: `func calculate(value: float) -> int:` not `func calculate(value):`
- Prefer specific class_name types over generic Node types: `var map_core: MapCore` not `var map_core: RefCounted`
- NEVER use untyped arrays: Always use `Array[Type]` not `Array`
- NEVER return untyped empty arrays: Use `var empty: Array[Type] = []` then `return empty`
- NEVER use untyped dictionaries when types are known: Specify types where possible
- NEVER use variants or untyped classes unless there is a compelling exception that MUST be documented

### Example of correct typing:
```gdscript
# CORRECT:
func get_nodes() -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    return result

func process_data(items: Array[String]) -> Dictionary:
    var output: Dictionary = {}  # OK when values are mixed types
    return output

# WRONG:
func get_nodes() -> Array:  # Missing type specification
    return []  # Returning untyped array

func process_data(items):  # Missing parameter type
    var output = {}  # Missing type annotation
    return output
```

## Resource and Script Loading

- **ALWAYS use class_name.new():** Every script must have a class_name and be instantiated via `MyClass.new()` - never use `load("res://path/to/script.gd").new()`
- **NEVER preload scripts with class_name:** If a script has class_name MyClass, use `MyClass.new()` directly, NOT `preload("uid://...")`
- **ALWAYS use preload for scenes/resources:** Use `const MyScene = preload("res://path/to/scene.tscn")` for scenes, shaders, and other resources
- **PREFER UID references over paths:** When resources have UIDs, use `preload("uid://abc123")` instead of path-based loading to avoid breakage when files move
- **ALWAYS add comments for UID references:** Include a comment with the filename when using UIDs: `preload("uid://abc123") # fog_shader.gdshader`
- **NEVER use load() without human approval:** The load() function should only be used for dynamic runtime paths after explicit verification with the human
- **Every script MUST have class_name:** No exceptions - every .gd file needs a class_name declaration at the top
- **Preload only non-script resources:** Use `const MY_SHADER = preload("res://path/to/shader.gdshader")` for shaders, scenes, textures, etc.

### Example:
```gdscript
# CORRECT:
class_name MySystem
extends Node

# Preload scenes and resources only (NOT scripts with class_name)
const PREFAB_SCENE = preload("uid://b8apg4aqwojm7") # prefab.tscn
const FOG_SHADER = preload("uid://c2emej86gntl7") # fog.gdshader

func create_component() -> void:
    # Use class_name directly for scripts
    var map_gen = MapGenerator.new()  # Direct class instantiation
    var fog_system = FogOfWarSystem.new()  # Direct class instantiation
    
    # Use preloaded constants for scenes
    var instance = PREFAB_SCENE.instantiate()

# WRONG:
const MapGen = preload("uid://abc123") # map_generator.gd - DON'T preload scripts!
var script = load("res://scripts/component.gd")
var component = script.new()  # Should use class_name instead
```

## Privacy Conventions

- **Public interface (no underscore):** `func add_card(card_data: CardData):`
- **Godot built-ins (single underscore):** `func _ready():` and `func _process(delta):`
- **Private implementation (double underscore):** `var __internal_state: Dictionary` and `func __handle_internal_logic():` and `func __on_custom_signal():`

## Naming Conventions

- **Variables/functions:** snake_case
- **Classes:** PascalCase
- **Private members:** __double_underscore
- **Godot native calls ONLY:** _single_underscore
- **Constants:** SCREAMING_SNAKE_CASE

## Project structure:
```
src/
├── main.gd              # Entry point
├── autoload/            # Singleton scripts
├── managers/            # System managers
├── scenes/              # Game scenes
├── components/          # Reusable components
└── utilities/           # Helper functions
```

## File naming:
- snake_case for all files
- Descriptive names that clearly indicate purpose
- Consistent prefixes for related files
- Clear file purposes
- Match class_name to filename (minus .gd extension)

## Code organization:
- Single responsibility per file
- Clear imports and exports
- Minimal dependencies
- Functional composition

## Manager patterns:
- Singleton autoload managers
- Event-based communication
- State management separation
- Clear service boundaries

## Scene structure:
- Scene files with logic scripts
- Component-based architecture
- Clear scene responsibilities
- Minimal scene coupling