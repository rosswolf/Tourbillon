# Product Requirements Document: Castlebuilder (Early Prototype)

## Project Status: Early Prototype

**Current State:** This project is in early prototype stage with limited functional components. The PRD outlines both the implemented features and the planned vision for the complete game.

## 1. Product Overview

**Castlebuilder** (working title, formerly "Swish") is a turn-based tactical card game that combines strategic deck building with tower defense mechanics. Players control a hero who must survive waves of enemies using cards that deploy buildings, cast spells, and manage resources across multiple energy types.

### 1.1 Core Value Proposition (Planned)
- **Strategic Depth**: Multi-resource energy system with Purple, Green, Blue, Red, Orange, and None energy types
- **Building-Centric Gameplay**: Cards primarily deploy persistent buildings rather than one-shot effects
- **Dynamic Combat**: Real-time projectile combat within turn-based strategic framework
- **Goal-Driven Progression**: Timed objectives with rewards drive forward momentum

### 1.2 Target Platforms
- **Primary**: Mobile (Android/iOS) - configured for mobile rendering
- **Secondary**: Desktop (Windows/Mac/Linux) via Godot 4.4

## 2. Current Implementation Status

### 2.1 Functional Components

#### 2.1.1 Core Infrastructure
- ✅ **Godot 4.4 Project Structure**: Basic scene hierarchy and organization
- ✅ **Main Menu**: Basic navigation with Play, Settings, and Quit options
- ✅ **Scene Management**: Scene transition system with fade effects
- ✅ **Data Loading System**: JSON-based static data framework (StaticData)
- ✅ **Global Signal System**: Event-driven architecture foundation

#### 2.1.2 Avatar System
- ✅ **Mouse-Controlled Movement**: Avatar follows mouse position with smooth movement
- ✅ **Visual Effects**: Tail system with pulsating animation
- ✅ **Rotation Tracking**: Spin speed calculation for potential weapon integration

#### 2.1.3 Combat System (Partial)
- ✅ **Weapons Manager**: Framework for projectile firing patterns
- ✅ **Projectile System**: Basic projectile spawning and movement
- ✅ **Predictive Aiming**: Calculation for leading targets
- ⚠️ **Limited Testing**: Combat exists but lacks enemies to fight

#### 2.1.4 UI Components
- ✅ **Hand Container**: Card display system with fan layout
- ✅ **Card UI**: Basic card rendering framework
- ✅ **Selection Manager**: Click and drag system for interactions
- ✅ **HUD Elements**: Modal dialogs (pause, game over)
- ✅ **Icon System**: Framework for game icons

### 2.2 Prepared But Not Integrated

These systems have code scaffolding but are not functionally connected:

#### 2.2.1 Game Systems
- ⚠️ **Card Gameplay**: Card data structures exist but no actual gameplay
- ⚠️ **Resource Management**: Energy system defined but not implemented
- ⚠️ **Building Deployment**: Building definitions exist without spawn mechanics
- ⚠️ **Enemy AI**: Enemy data exists but no spawning or behavior
- ⚠️ **Goal System**: Goal structures defined but not active

#### 2.2.2 Data Files
- ⚠️ **Card Database**: 50+ card definitions in JSON
- ⚠️ **Enemy Database**: Enemy templates with stats
- ⚠️ **Building Database**: Building configurations
- ⚠️ **Hero Classes**: Knight and Berzerker templates

### 2.3 Known Issues

- **No Active Gameplay Loop**: Game loads but lacks playable mechanics
- **Disconnected Systems**: Components exist independently without integration
- **Missing Enemy Spawning**: Combat system has no targets
- **Card System Non-Functional**: Cards display but don't execute actions
- **Resource System Inactive**: Energy/gold defined but not tracked

## 3. Development Roadmap

### 3.1 Phase 0: Foundation Completion (Current Priority)

**Goal:** Connect existing components into minimal playable loop

- [ ] Spawn basic enemies with simple AI
- [ ] Connect card play to actual effects
- [ ] Implement basic resource tracking (energy/gold)
- [ ] Add win/lose conditions
- [ ] Create one complete gameplay round

**Estimated Completion:** 2-4 weeks

### 3.2 Phase 1: Core Mechanics

**Goal:** Establish fundamental game systems

- [ ] Implement full card effect system
- [ ] Create building spawn and management
- [ ] Add enemy wave spawning
- [ ] Implement resource generation
- [ ] Basic goal completion flow

**Estimated Completion:** 4-6 weeks

### 3.3 Phase 2: Content Expansion

**Goal:** Add variety and depth

- [ ] Additional hero classes with unique abilities
- [ ] Expanded card library (target: 100+ cards)
- [ ] New enemy types with varied behaviors
- [ ] Advanced building types
- [ ] Multiple map layouts

**Estimated Completion:** 6-8 weeks

### 3.4 Phase 3: Progression Systems

**Goal:** Add meta-progression and retention

- [ ] Persistent progression between runs
- [ ] Deck customization system
- [ ] Hero skill trees
- [ ] Achievement system
- [ ] Leaderboards

**Estimated Completion:** 4-6 weeks

### 3.5 Phase 4: Polish & Launch

**Goal:** Production-ready release

- [ ] Tutorial and onboarding
- [ ] Audio integration
- [ ] Visual effects polish
- [ ] Performance optimization
- [ ] Platform-specific builds

**Estimated Completion:** 8-12 weeks

## 4. Technical Architecture

### 4.1 Current Architecture

#### 4.1.1 Directory Structure
```
castlebuilder-app/
├── app/
│   ├── src/
│   │   ├── scenes/
│   │   │   ├── core/          # Game logic
│   │   │   ├── ui/            # UI components
│   │   │   ├── data/          # Data management
│   │   │   └── utilities/     # Helper systems
│   │   └── data/              # JSON databases
│   └── assets/                # Art and audio
└── docs/                      # Documentation
```

#### 4.1.2 Core Systems
- **Signal-Based Communication**: GlobalSignals for decoupled events
- **Instance Management**: UID-based entity tracking
- **Data Loading**: JSON parsing with StaticData class
- **Scene Management**: Transition system with fade effects

### 4.2 Technical Debt

- **Incomplete Entity System**: Entity base class exists but not fully utilized
- **Missing State Management**: No save/load functionality
- **Limited Testing**: No automated tests
- **Performance Unknown**: Not profiled or optimized

## 5. Game Design (Target Vision)

### 5.1 Hero System
Players choose from hero classes with distinct starting stats and playstyles:

**Knight**
- Health: 60/60, Armor: 10/10
- Starting Resources: 100 gold, 2 training, 3 instinct
- Starting Relic: Training Gloves
- Playstyle: Balanced offense/defense

**Berzerker** 
- Health: 40/55, Armor: 0/0
- Starting Resources: 90 gold, 2 training, 3 instinct
- Starting Relic: Training Gloves
- Playstyle: High-risk, high-reward aggression

### 5.2 Card System

#### 5.2.1 Card Types
- **Building Cards**: Deploy persistent structures
- **Effect Cards**: Instant actions and resource generation
- **Shop Cards**: Enable purchasing new cards or slots

#### 5.2.2 Energy System
- **Purple Energy**: Innovation and advanced actions
- **Green Energy**: Nature and growth effects
- **Blue Energy**: Control and utility
- **Red Energy**: Aggression and damage
- **Orange Energy**: Hybrid effects
- **None Energy**: Universal/free actions

### 5.3 Combat Vision

- **Town Hall Defense**: Core objective is protecting the town hall
- **Building Combat**: Turrets and defensive structures
- **Enemy Waves**: Progressive difficulty with varied enemy types
- **Real-Time Projectiles**: Physics-based projectile combat

## 6. Risk Assessment

### 6.1 Current Critical Risks

- **No Playable Loop**: Game doesn't function as a game yet
- **Scope Creep**: Extensive planned features vs. limited implementation
- **Integration Challenge**: Connecting disparate systems
- **Platform Uncertainty**: Mobile-first design not validated

### 6.2 Mitigation Strategy

1. **Focus on MVP**: Prioritize minimum playable experience
2. **Iterative Development**: Small, testable increments
3. **Regular Playtesting**: Validate each phase before proceeding
4. **Scope Flexibility**: Be prepared to cut features

## 7. Success Metrics (Future)

Once the game reaches playable state:

### 7.1 Player Engagement
- **Session Length**: Target 15-30 minutes
- **Retention**: Day 1 >60%, Day 7 >25%
- **Completion Rate**: >80% complete first battle

### 7.2 Technical Performance
- **Load Time**: <3 seconds to gameplay
- **Frame Rate**: Stable 60 FPS on target devices
- **Memory**: <512MB on mobile

## 8. Next Steps

### Immediate Actions (This Week)
1. Connect avatar combat to enemy targets
2. Implement basic enemy spawning
3. Make one card have a real effect
4. Add basic win/lose conditions

### Short Term (This Month)
1. Create minimal viable gameplay loop
2. Implement 5-10 functional cards
3. Add 2-3 enemy types
4. Basic resource tracking

### Documentation Needs
- [ ] Technical integration guide
- [ ] Card effect implementation guide
- [ ] Enemy AI behavior documentation
- [ ] Building system architecture

---

*This PRD reflects the actual current state of the Castlebuilder prototype as of August 2025. The document will be updated as development progresses from prototype to full game.*

## Appendix A: File Inventory

### Functional Files (Actually Used)
- `main_menu.gd` - Menu navigation
- `avatar.gd` - Player character movement
- `weapons_manager.gd` - Projectile system
- `projectile.gd` - Projectile behavior
- `global_signals.gd` - Event system
- `static_data.gd` - Data loading

### Scaffolding Files (Not Integrated)
- `global_game_manager.gd` - Game state (partial)
- `hand_container.gd` - Card display (visual only)
- `card_ui.gd` - Card rendering (no gameplay)
- Various entity classes (unused)

### Data Files (Prepared Content)
- `cards.json` - 50+ card definitions
- `enemies.json` - Enemy templates
- `buildings.json` - Building configurations
- `heroes.json` - Hero class definitions