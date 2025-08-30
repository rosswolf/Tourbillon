# Core Entities - Coding Patterns

## Instance IDs

Every meaningful game object MUST have:
- `var __instance_id: String` (private storage)
- `var instance_id: String:` with getter that returns `__instance_id`
- `func generate_instance_id() -> String:` that returns `"type" + str(Time.get_unix_time_from_system()) + "_" + str(randi())`

### Instance Management Patterns
- **Instance Catalog:** Central registry for all game objects via instance_id
- **Instance tracking:** All game objects use string-based instance_id for tracking and debugging
- **Composition over Inheritance:** Prefer component-based design over deep inheritance hierarchies
- **Reference by ID:** Always reference entities by their instance_id, not direct object references

## Entity structure:
```python
entity = {
    'id': 'fire_elemental',
    'type': 'enemy',
    'components': {
        'health': {'max': 45, 'current': 45},
        'stats': {'attack': 12, 'defense': 8},
        'position': {'x': 5, 'y': 3}
    }
}
```

## Component patterns:
- Components as dictionaries
- No component inheritance
- Components are pure data
- Systems operate on components

## Entity creation:
- Factory functions over constructors
- Template-based generation
- Validation at creation
- Immutable after creation

## Entity operations:
- Pure functions for updates
- Return new entity state
- Component-specific update functions
- No direct entity mutation

## ID management:
- Unique IDs for all entities
- Consistent ID format
- ID generation utilities
- Reference by ID, not object
- Use instance_id dictionaries for O(1) lookups