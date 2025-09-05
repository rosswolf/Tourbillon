# Core - Game Logic and Systems

Contains the fundamental game systems, entities, and mechanics. This is where the actual game logic lives.

## What goes here:
- Game entities (heroes, enemies, items)
- Battle systems and mechanics  
- Action definitions and behaviors
- Resource and effect systems
- Map and dungeon generation
- Core game state management

## When to use:
- Implementing new game mechanics
- Adding character abilities or actions
- Creating new entity types
- Building battle systems
- Managing game resources

## Key principles:
- Pure logic, no UI dependencies
- Functional programming preferred
- Immutable data structures
- Clear separation of concerns
- Testable, isolated components

## Important Scene Tree Notes:
- Core entities are NOT part of the Godot scene tree
- They exist as pure data/logic objects (extend RefCounted or Resource)
- DO NOT use add_child() on core objects - it does nothing and is incorrect
- DO NOT rely on _ready() for initialization - use _init() or deferred calls
- Core objects communicate via signals and direct method calls
- UI layer is responsible for scene tree management and visual representation