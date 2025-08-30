# Core - Coding Patterns

## Interface-First Development

### Core Principle
Objects are black boxes. They can only interact through explicitly defined public interfaces.

### Decision Tree for Any Change

1. **Does this change affect how other objects interact with this one?**
   - YES → Start with Define/Modify Interfaces
   - NO → Skip to Implementation only

2. **Am I creating new functionality that other objects will use?**
   - YES → Start with Define Interfaces
   - NO → Skip to Implementation only

### Define/Modify Interfaces (when needed)

Before writing ANY implementation code:
1. Check if the target class has the methods you want to call
2. Design the complete public interface in a clearly marked section
3. Document what each interface method/property does
4. Verify the interface is sufficient for all use cases
5. DO NOT write implementation until interfaces are complete

### Implementation Guidelines

1. Verify you're only using other objects through their public interfaces
2. Implement strictly within your defined interface contract
3. Keep all non-interface code private (use `__` prefix in Godot)
4. If you discover the interfaces are insufficient:
   - STOP immediately
   - Go back to define/modify interfaces
   - Update documentation before continuing

### Interface Requirements

**Needs Interface Definition First:**
- Adding a new method that other classes will call
- Changing parameters of an existing public method
- Creating a new class/module
- Adding signals that others can connect to
- Modifying return types of public methods

**Implementation Only (no interface changes):**
- Fixing a bug in existing method logic
- Optimizing performance of internal algorithms
- Refactoring private helper functions
- Updating internal data structures (if not exposed)

### Red Flags (Stop and Fix)

- Calling a method that doesn't exist (like `set_map()` on MapCore)
- Accessing private properties (`__` prefix) of another object
- Creating circular dependencies between classes
- Finding yourself needing to change multiple objects just to access data
- Using untyped variables to bypass interface contracts

## Core Architecture

- **Separation of Concerns:** Clear boundaries between Core Logic (game rules, data), UI Layer (visual representation), and Service Layer (utilities, cross-cutting concerns)
- **Communication Patterns:** Use GlobalSignals for cross-system events, direct calls for immediate operations
- **Instance Management:** All game objects use string-based instance_id for tracking and debugging
- **Composition over Inheritance:** Prefer component-based design over deep inheritance hierarchies

## Data structures:
- Use dictionaries for entity definitions
- Immutable state objects
- Simple data classes over complex inheritance
- Functional composition over OOP hierarchies

## System architecture:
- Systems operate on components
- No direct system-to-system communication
- Event-driven where necessary
- Stateless functions preferred

## Entity patterns:
- Composition over inheritance
- Component-based architecture
- Factory functions for creation
- Validation at creation time

## Function design:
- Single responsibility
- Pure functions when possible
- Return new state, don't mutate
- Early returns for error conditions

## Error handling:
- Fail fast and explicit
- Use return values over exceptions
- Validate inputs at boundaries
- Log errors with context