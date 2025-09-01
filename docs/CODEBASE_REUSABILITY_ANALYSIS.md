# Codebase Reusability Analysis: Elastic → Tourbillon

## Executive Summary

The existing Elastic codebase provides an **excellent foundation** for Tourbillon development, with approximately **60-70% of the core systems being directly reusable or easily adaptable**. The architecture is well-suited for our needs, requiring primarily content changes and mechanical additions rather than fundamental rewrites.

## High-Level Comparison

| System | Elastic Has | Tourbillon Needs | Reusability |
|--------|------------|------------------|-------------|
| **Card System** | Hand management, effects, costs | Same + polyomino placement | **85%** - Extend for placement |
| **Resource System** | 3 colors (Purple/Blue/Green) + time | 5 forces + time system | **70%** - Add 2 forces, modify mechanics |
| **Turn-Based Flow** | Turn structure, phases | Beat/tick time system | **60%** - Adapt to continuous time |
| **Entity Architecture** | Cards, Heroes, Goals | Gears, Springs, Gremlins | **90%** - Use same patterns |
| **UI Framework** | Card hand, resource meters | Grid placement, force meters | **75%** - Extend with grid |
| **Data System** | JSON-driven, Google Sheets | Same needs | **100%** - Perfect match |
| **Effects Engine** | Move descriptors, modular | Force interactions needed | **80%** - Add new effect types |

## Detailed Reusability Plan

### 1. 🟢 **DIRECTLY REUSABLE** (Use As-Is)

#### Core Architecture
- **Entity System** (`/core/entities/`)
  - Builder pattern for object construction
  - Instance catalog for global lookup
  - Signal-based communication
  - **Action:** Keep entire entity framework, add new entity types

#### Data Management
- **Static Data System** (`/data/static_data.gd`)
  - JSON loading and parsing
  - Enum handling
  - Configuration references
  - **Action:** Use unchanged for Tourbillon data

#### Global Systems
- **Signal System** (`global_signals.gd`)
  - Event bus architecture
  - **Action:** Extend with new signals for grid events

- **Selection Manager** (`global_selection_manager.gd`)
  - Mouse interaction handling
  - **Action:** Extend for grid cell selection

#### Utilities
- **UID Manager** (`/utilities/uid_manager.gd`)
  - Unique ID generation
  - **Action:** Use for gear/spring IDs

### 2. 🟡 **EASILY ADAPTABLE** (Minor Modifications)

#### Resource System → Force System
**Current:** 3 colors (Purple/Blue/Green) with time/energy duality
**Needed:** 5 forces (Heat/Precision/Momentum/Balance/Entropy)

**Adaptation Plan:**
```gdscript
# Extend air.gd to forces.gd
enum ForceType {
    HEAT,      # Red (was PURPLE)
    PRECISION, # Blue (keep BLUE)
    MOMENTUM,  # Green (keep GREEN)
    BALANCE,   # White (NEW)
    ENTROPY    # Purple (NEW)
}

# Modify game_resource.gd
# Keep the time/energy duality concept
# Add force interaction matrix
```

**Reusability:** 70% - Core meter logic stays, add 2 new colors and interaction rules

#### Card System → Plans/Calibrations/Contingencies
**Current:** Cards with instinct_effect and slot_effect
**Needed:** Three card types with different behaviors

**Adaptation Plan:**
- Keep `card.gd` base class
- Add `card_type` enum (PLAN, CALIBRATION, CONTINGENCY, THEOREM)
- Plans → Use slot_effect for gear placement
- Calibrations → Use instinct_effect for instant effects
- Contingencies → Add trigger_condition field
- Theorems → Add permanent_rule field

**Reusability:** 85% - Card infrastructure perfect, just categorize differently

#### Hand Management → Card Hand + Grid Selection
**Current:** Fan-out card display with selection
**Needed:** Same + grid placement interface

**Adaptation Plan:**
- Keep `hand_container.gd` unchanged for card display
- Add new `grid_container.gd` for engine grid
- Link selection from hand to grid placement
- Use existing hover/selection logic

**Reusability:** 100% for hand, 0% for grid (new component)

### 3. 🔵 **SIGNIFICANT ADAPTATION** (Major Changes)

#### Turn System → Beat/Tick Timeline
**Current:** Discrete turns with phases
**Needed:** Continuous timeline with beats/ticks

**Adaptation Plan:**
```gdscript
# Transform global_game_manager.gd
class Timeline:
    var total_beats: int = 100
    var current_beat: int = 0
    var current_tick: float = 0.0
    var tick_duration: float = 0.1  # seconds
    
    func _process(delta):
        current_tick += delta / tick_duration
        if current_tick >= 10:
            advance_beat()
```

**Reusability:** 40% - Keep phase management, rewrite timing

#### Hero System → Engine Core
**Current:** Hero with resources
**Needed:** Engine that produces/consumes forces

**Adaptation Plan:**
- Rename Hero to EngineCore
- Replace health with structural_integrity
- Add force production arrays
- Add gear slot management

**Reusability:** 60% - Resource management transfers, mechanics change

### 4. 🔴 **NEW DEVELOPMENT** (Build from Scratch)

#### Grid System (0% exists)
**Needed:** 7x7 expandable grid for polyomino placement

**Development Plan:**
```gdscript
class EngineGrid:
    var grid_size: Vector2i = Vector2i(7, 7)
    var cells: Dictionary[Vector2i, GridCell] = {}
    var gears: Dictionary[String, Gear] = {}
    
    func can_place_gear(gear: Gear, position: Vector2i) -> bool
    func place_gear(gear: Gear, position: Vector2i) -> void
    func get_connections(gear: Gear) -> Array[Spring]
```

#### Polyomino Gears (0% exists)
**Needed:** Tetris-like pieces with rotation

**Development Plan:**
- Create Gear entity extending Entity
- Add shape definition system
- Implement rotation matrices
- Add collision detection

#### Spring Connections (0% exists)
**Needed:** Force transfer between gears

**Development Plan:**
- Create Spring entity
- Add pathfinding for force flow
- Implement transfer rates and types

#### Gremlin System (0% exists)
**Needed:** Enemies that attack the engine

**Development Plan:**
- Create Gremlin entity
- Add AI behavior system
- Implement damage/defense mechanics

### 5. 🟣 **REFACTOR OPPORTUNITIES**

#### Rename for Clarity
- `air.gd` → `forces.gd`
- `air_meter_2.gd` → `force_meter.gd`
- `hero.gd` → `engine_core.gd`
- `battleground` → `engine_grid`
- `library.gd` → `card_deck.gd`

#### Remove Unused Systems
- Mob system (not needed for Tourbillon)
- Relic system (unless adapted for permanent upgrades)
- Goal system (replace with perpetual motion victory)

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
1. ✅ Keep all core architecture
2. 🔄 Adapt resource system to 5 forces
3. 🔄 Modify card types for Plans/Calibrations/Contingencies
4. ✅ Keep data management system

### Phase 2: Grid System (Week 3-4)
1. 🆕 Build 7x7 grid UI component
2. 🆕 Implement polyomino gear shapes
3. 🔄 Adapt selection manager for grid
4. 🆕 Create placement validation

### Phase 3: Force Mechanics (Week 5-6)
1. 🆕 Implement force interaction matrix
2. 🆕 Build spring connection system
3. 🔄 Adapt effects engine for force transformations
4. 🆕 Create force flow visualization

### Phase 4: Timeline System (Week 7-8)
1. 🔄 Replace turn system with beat/tick timeline
2. 🔄 Adapt UI for continuous time display
3. 🆕 Add temporal effects and anomalies
4. 🔄 Modify game flow for real-time

### Phase 5: Enemies & Polish (Week 9-10)
1. 🆕 Implement Gremlin system
2. 🆕 Add damage and defense mechanics
3. 🔄 Polish UI for Tourbillon theme
4. 🆕 Add particle effects for forces

## Code Metrics

### Reusability Statistics
- **Lines of Code to Keep:** ~3,500 (70%)
- **Lines to Modify:** ~1,000 (20%)
- **Lines to Write New:** ~500 (10%)
- **Total Estimated:** ~5,000 lines

### File-Level Breakdown
| Directory | Keep | Modify | New | Notes |
|-----------|------|--------|-----|-------|
| `/core/entities/` | 90% | 10% | +3 files | Add Gear, Spring, Gremlin |
| `/core/resources/` | 60% | 40% | - | Adapt to forces |
| `/core/effects/` | 80% | 20% | +2 files | Add force effects |
| `/ui/hand/` | 100% | 0% | - | Perfect as-is |
| `/ui/grid/` | 0% | 0% | 100% | New system |
| `/data/` | 100% | 0% | - | Just change content |
| `/utilities/` | 100% | 0% | - | All reusable |

## Risk Assessment

### Low Risk (High Confidence)
- Entity architecture adaptation
- Data system usage
- Card hand UI
- Signal system extension

### Medium Risk (Some Uncertainty)
- Timeline system conversion
- Force interaction complexity
- Grid/polyomino implementation

### High Risk (Needs Prototyping)
- Performance with many animated gears
- Force flow pathfinding
- Real-time gameplay feel

## Recommendations

### Do Immediately
1. **Set up project structure** keeping Elastic's architecture
2. **Prototype the grid system** as the biggest unknown
3. **Test force interaction matrix** with simple gears
4. **Validate timeline system** feels good in real-time

### Preserve at All Costs
1. **Entity/Builder pattern** - It's perfect for our needs
2. **JSON data system** - Enables rapid iteration
3. **Signal architecture** - Keeps code decoupled
4. **UI animation system** - Already polished

### Consider Alternatives For
1. **Turn system** - May need complete rewrite for real-time
2. **Resource meters** - May need custom visualization for 5 forces
3. **Selection system** - Grid selection very different from cards

## Conclusion

The Elastic codebase provides an **exceptional foundation** for Tourbillon. The core architecture is so well-designed that we can focus primarily on implementing new game mechanics rather than building infrastructure. The biggest development effort will be the grid system and polyomino placement, which are entirely new. However, even these can leverage the existing entity patterns and UI framework.

**Estimated Development Time Saved: 4-6 weeks** compared to starting from scratch.

**Recommended Approach:** Keep Elastic's architecture intact, extend it with Tourbillon-specific features, and only replace systems where the gameplay fundamentally differs (turns → timeline).