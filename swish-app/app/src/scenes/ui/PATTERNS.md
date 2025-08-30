# UI - Coding Patterns

## Creating UI Components

### Core Principles
- Separate visual representation from game logic
- Connect to GlobalSignals for state updates
- Use `__on` prefix for signal handlers  
- Clean up tweens and connections on removal

### Privacy Conventions for UI
- **Public interface (no underscore):** Methods other UI components can call
- **Godot built-ins (single underscore):** `func _ready():` and `func _gui_input(event):`
- **Private handlers (double underscore):** `func __on_button_pressed():` and `func __on_custom_signal():`

## Component structure:
- Separate data from presentation
- Event handlers as pure functions
- Props-driven component behavior
- Minimal internal state
- Visual representation separate from game logic

## State management:
- UI state separate from game state
- One-way data flow
- Event bubbling for interactions
- Clear state ownership
- Connect to GlobalSignals for state updates

## Styling patterns:
- Theme-based styling
- Consistent component APIs
- Responsive design principles
- Reusable style components

## Event handling:
```python
def on_button_click(event_data):
    # Validate input
    # Process action
    # Emit result event
    return action_result
```

### Signal Handler Naming
- Always use `__on` prefix for signal handlers
- Format: `func __on_<source>_<signal>():`
- Examples:
  - `func __on_button_pressed():`
  - `func __on_animation_finished():`
  - `func __on_global_state_changed():`

## Component reuse:
- Generic components with props
- Composition over inheritance
- Slot/template patterns
- Configurable behaviors

## Performance:
- Lazy loading for heavy components
- Efficient update patterns
- Minimal re-renders
- Resource cleanup
- Clean up tweens and connections on removal