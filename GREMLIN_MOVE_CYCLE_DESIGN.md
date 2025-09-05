# Gremlin Move Cycle System Design

## Overview
Gremlins execute moves in sequence, with each move having a tick countdown. The UI shows the current move and a progress bar indicating when it will trigger.

## Core Concepts

### Move Queue Structure
Each gremlin has up to 6 moves (`move_1` through `move_6`) with corresponding tick timings (`move_1_ticks` through `move_6_ticks`).

**Move Types by Duration:**
- **Always Active (0 ticks)**: No countdown, effect remains active until gremlin moves to next move or dies
- **Timed Effects (N ticks)**: Effect is active for N ticks, then advances to next move
  - Persistent effects (caps, penalties): Active during their tick duration
  - Triggered actions (attack, drain, summon): Fire when countdown reaches 0

**Examples:**
- `heat_soft_cap=4` at 0 ticks: Cap always active, never advances (single-move gremlin)
- `heat_soft_cap=4` at 5 ticks: Cap active for 5 ticks, then moves to next effect
- `attack=3` at 10 ticks: Countdown from 10, attacks when reaching 0, then advances
- `card_cost_penalty=1` at 8 ticks: Penalty active for 8 ticks, then next move

### Move Cycle Behavior

```
INITIALIZATION:
├── Load move_1 as current_move
├── Set ticks_until_action = move_1_ticks
├── Apply move_1's effect (caps, penalties start immediately)
├── If move_1_ticks == 0 → Effect stays active, no advancement
└── Display current move in UI

EACH TICK:
├── If ticks_until_action > 0:
│   ├── Decrement ticks_until_action
│   └── Update progress bar (current/max)
├── When ticks_until_action reaches 0:
│   ├── For triggered actions (attack/drain/summon): Execute action
│   ├── For persistent effects: Remove effect
│   ├── Advance to next move in sequence
│   ├── Load next move's tick count
│   ├── Apply next move's effect (if persistent)
│   └── Reset progress bar
└── Continue cycle

MOVE SEQUENCE:
move_1 → move_2 → move_3 → move_4 → move_5 → move_6 → move_1 (loops)
```

## Data Structure

### Gremlin Properties
```gdscript
class_name Gremlin

# Move cycle data
var move_queue: Array[MoveData] = []
var current_move_index: int = 0
var current_move: MoveData = null
var ticks_until_action: int = 0

class MoveData:
    var effect_type: String  # "attack", "drain_random", "heat_soft_cap", etc.
    var effect_value: int    # Damage amount, drain amount, cap value
    var tick_duration: int   # Ticks until this move triggers
    var is_passive: bool     # True if tick_duration == 0
```

## UI Display

### Current Move Display
```
┌─────────────────────────┐
│ Gear Tick               │
│ HP: 15/15               │
│                         │
│ Next: Attack (3 damage) │
│ [████████░░] 8/10 ticks │
└─────────────────────────┘
```

### Move Type Descriptions
- **Attack**: "Attack: X damage"
- **Drain**: "Drain: X [type]"
- **Cap**: "[Force] cap: X"
- **Penalty**: "Cards +X cost"
- **Summon**: "Summon: [type]"
- **Discard**: "Force discard X"

## Implementation Components

### 1. Move Parser (gremlin_spawn_controller.gd)
```gdscript
func _parse_moves_to_queue(gremlin_data: Dictionary) -> Array[MoveData]:
    var queue: Array[MoveData] = []
    
    for i in range(1, 7):
        var move_key = "move_" + str(i)
        var tick_key = "move_" + str(i) + "_ticks"
        
        if gremlin_data.has(move_key):
            var move = _parse_single_move(
                gremlin_data[move_key],
                gremlin_data.get(tick_key, 0)
            )
            if move:
                queue.append(move)
    
    return queue
```

### 2. Move Executor (gremlin.gd)
```gdscript
func process_beat(context: BeatContext) -> void:
    # Handle passive effects (always active)
    _apply_passive_effects()
    
    # Countdown current move
    if current_move and not current_move.is_passive:
        ticks_until_action -= 1
        
        if ticks_until_action <= 0:
            _execute_current_move()
            _advance_to_next_move()
```

### 3. Progress Tracker (gremlin_display.gd)
```gdscript
func update_move_display():
    if gremlin.current_move:
        move_label.text = _format_move_description(gremlin.current_move)
        
        if not gremlin.current_move.is_passive:
            progress_bar.max_value = gremlin.current_move.tick_duration
            progress_bar.value = gremlin.current_move.tick_duration - gremlin.ticks_until_action
            tick_label.text = str(gremlin.ticks_until_action) + "/" + str(gremlin.current_move.tick_duration)
        else:
            progress_bar.visible = false
            tick_label.text = "Passive"
```

## Example Move Cycles

### Basic Gnat
```
move_1: attack=1 @ 3 ticks
move_2: attack=1 @ 3 ticks

Cycle:
Tick 0: Load "Attack: 1 damage", countdown from 3
Tick 3: Attack hero for 1, load second attack
Tick 6: Attack hero for 1, loop back to first attack
```

### Gear Tick (Complex)
```
move_1: card_cost_penalty=1 @ 5 ticks
move_2: force_discard=1 @ 10 ticks  
move_3: attack=2 @ 15 ticks

Cycle:
Tick 0: Load "Cards +1 cost", countdown from 5
Tick 5: Apply penalty (persistent), load "Force discard 1"
Tick 15: Force discard, load "Attack: 2 damage"
Tick 30: Attack for 2, loop back to penalty
```

### Rust Speck (Always Active + Triggered)
```
move_1: precision_soft_cap=3 @ 0 ticks (always active)
move_2: attack=3 @ 6 ticks

Cycle:
Tick 0: Apply cap (stays active forever since 0 ticks)
Never advances from move_1 since it has 0 ticks
Attack never happens because we're stuck on move_1

ISSUE: This doesn't work! Need to reconsider 0-tick moves in cycles.
```

### Rust Speck (Fixed Design)
```
move_1: precision_soft_cap=3 @ 10 ticks
move_2: attack=3 @ 6 ticks

Cycle:
Tick 0: Apply precision cap, countdown from 10
Tick 10: Remove cap, load attack, countdown from 6
Tick 16: Attack for 3, loop back to cap
Tick 26: Apply cap again...
```

## Special Cases

### Handling 0-Tick Moves
**Problem:** A move with 0 ticks would never advance, blocking the cycle.

**Solution Options:**
1. **Treat 0 ticks as "always on" background effect** - Not part of the cycle, always active
2. **Minimum 1 tick for cycle moves** - Force all cycle moves to have at least 1 tick
3. **Special "passive" slot** - Separate from the move cycle

**Recommended:** Option 1 - Moves with 0 ticks are extracted as background effects that are always active while the gremlin lives. The actual cycle only includes moves with tick counts > 0.

### Multiple Passives
If a gremlin has multiple passive effects (0 ticks), they all apply immediately as background effects. The move cycle only contains moves with tick counts > 0.

### Empty Slots
If a gremlin has gaps (e.g., move_1, move_3, no move_2), only defined moves are added to the queue.

### Single Move
If only one move exists, it repeats continuously with its tick timing.

### No Moves
Gremlin does nothing special, shows "No special effects".

## State Persistence

### On Gremlin Death
- Clear all persistent effects (caps, penalties)
- Stop move cycle
- Remove from UI

### On Player Turn
- Move cycles continue during player planning
- Ticks advance when cards are played

### Save/Load
- Store current_move_index
- Store ticks_until_action
- Restore exact position in cycle

## Benefits

1. **Clear Communication**: Players see exactly what's coming and when
2. **Strategic Depth**: Players can time their actions around gremlin moves  
3. **Visual Feedback**: Progress bars make timing tangible
4. **Flexible System**: Supports any combination of moves and timings
5. **Consistent Behavior**: Predictable cycles aid player planning

## Next Steps

1. Refactor `Gremlin` class to use move queue structure
2. Update `GremlinDownsideProcessor` to handle individual moves
3. Modify `gremlin_display.gd` to show current move and progress
4. Add tick countdown logic to `process_beat`
5. Test with various move combinations