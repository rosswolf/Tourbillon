# Product Requirements Document: Swish

## 1. Product Overview

**Swish** is a turn-based tactical card game that combines strategic deck building with tower defense mechanics. Players control a hero who must survive waves of enemies using cards that deploy buildings, cast spells, and manage resources across multiple energy types.

### 1.1 Core Value Proposition
- **Strategic Depth**: Multi-resource energy system with Purple, Green, Blue, Red, Orange, and None energy types
- **Building-Centric Gameplay**: Cards primarily deploy persistent buildings rather than one-shot effects
- **Dynamic Combat**: Real-time projectile combat within turn-based strategic framework
- **Goal-Driven Progression**: Timed objectives with rewards drive forward momentum

### 1.2 Target Platforms
- **Primary**: Mobile (Android/iOS) - configured for mobile rendering
- **Secondary**: Desktop (Windows/Mac/Linux) via Godot 4.4

## 2. Game Systems

### 2.1 Hero System
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

### 2.2 Card System

#### 2.2.1 Card Types
- **Building Cards**: Deploy persistent structures (turrets, banks, town halls)
- **Effect Cards**: Instant actions and resource generation
- **Shop Cards**: Enable purchasing new cards or slots

#### 2.2.2 Card Properties
- **Energy Cost**: Paid using specific energy types (Purple, Green, etc.)
- **Durability**: Cards can be used multiple times before breaking
- **Rarity Tiers**: Starting, Common, Uncommon, Rare
- **Rules Text**: Clear description of card effects
- **Cursor Integration**: Cards change mouse cursor when selected

#### 2.2.3 Example Cards
- **"Innovate"** (Purple Energy: 2): Buy a card, Durability: 5
- **"Curious"** (Green Energy: 2): Buy a tool, Durability: 2

### 2.3 Building System

#### 2.3.1 Building Types
- **Town Hall**: Critical structure - losing it ends the game (10,000 HP)
- **Basic Turret**: Defensive structure (1,000 HP)
- **Bank**: Generates 200 gold when built (1,000 HP)

#### 2.3.2 Building Mechanics
- **Color Coding**: Buildings have color affiliations (Red, Blue, etc.)
- **Health System**: Buildings can be damaged and destroyed
- **Effect Types**: None, One-Time, Persistent
- **Targeting Priority**: Buildings can auto-target enemies

### 2.4 Combat System

#### 2.4.1 Enemy AI
Enemies use sophisticated AI with range-based behavior patterns:

**Goblin Scout** (55 HP, 0 Armor, Movement: 1)
- Sweet Spot Range: 1
- In-Range Actions: Block, melee attacks
- Out-of-Range Actions: Move closer, ranged attacks

**Torch Goblin** (20 HP, 5 Armor, Movement: 2)
- Sweet Spot Range: 2  
- Special: Slime attacks, ally healing
- Support-focused enemy type

#### 2.4.2 Weapon Systems
- **Basic Auto Attack**: Single shot, 60° spread, 100 damage
- **Trio Attack**: Three-shot burst at different angles
- **Projectile Physics**: Real-time projectiles with speed, damage, lifetime

### 2.5 Resource Management

#### 2.5.1 Energy Types
- **Purple Energy**: Innovation and advanced actions
- **Green Energy**: Nature and growth effects
- **Blue Energy**: Control and utility
- **Red Energy**: Aggression and damage
- **Orange Energy**: Hybrid effects
- **None Energy**: Universal/free actions

#### 2.5.2 Secondary Resources
- **Gold**: Currency for purchases
- **Training Points**: Character improvement
- **Instinct**: Combat awareness and reactions
- **Endurance**: Sustained action capability

### 2.6 Goal System

#### 2.6.1 Timed Objectives
Goals provide direction and rewards within time limits (typically 31 ticks):

- **"Spend 7 energy"**: Reward - shop a card
- **"Play 7 cards"**: Reward - shop a card  
- **"Activate 3 buildings"**: Reward - shop a card
- **"Draw 5 cards"**: Reward - shop a card

#### 2.6.2 Statistics Tracking
System tracks comprehensive gameplay metrics:
- Cards drawn, played, slotted
- Energy spent by type
- Buildings activated
- Gold expenditure

## 3. User Experience

### 3.1 Core Gameplay Loop

1. **Planning Phase**: Review goals, available cards, and energy
2. **Card Play**: Deploy buildings and activate effects using energy
3. **Combat Resolution**: Buildings auto-attack enemies with real-time projectiles
4. **Resource Management**: Collect energy, gold, and other resources
5. **Goal Completion**: Achieve timed objectives for rewards
6. **Progression**: Purchase new cards/upgrades, advance to next wave

### 3.2 User Interface

#### 3.2.1 Hand Management
- **Card Arrangement**: Visual hand with hover effects and selection
- **Drag & Drop**: Intuitive card targeting system
- **Visual Feedback**: Clear selection states and valid targets

#### 3.2.2 HUD Elements
- **Resource Displays**: Energy types, gold, health/armor
- **Goal Panel**: Current objectives with progress tracking
- **Menu System**: Pause, settings, and game over modals

#### 3.2.3 Visual Design
- **Theme System**: Consistent styling with custom fonts (BlackFlag.ttf)
- **Icon System**: Reusable components for energy types and effects
- **Color Coding**: Red, green, blue building affiliations
- **Shader Effects**: Water, blur, and highlight shaders for polish

### 3.3 Accessibility Features
- **Mobile Optimization**: Touch-friendly interface design
- **Clear Typography**: High-contrast text with custom fonts
- **Icon-Based Communication**: Visual symbols reduce text dependency
- **Consistent Interaction Patterns**: Unified selection/targeting system

## 4. Technical Architecture

### 4.1 Core Systems
- **Signal-Driven Architecture**: Clean separation between UI and game logic
- **Entity Component System**: Modular entity design with instance tracking
- **Data-Driven Design**: JSON-based configuration for easy content updates

### 4.2 Performance Optimization
- **Indexed Data Lookups**: O(1) performance for data queries
- **Mobile Rendering**: Optimized for mobile GPU capabilities
- **Resource Loading**: Efficient asset management with UID system

### 4.3 Content Pipeline
- **JSON Data Export**: Python tools for data management
- **Asset Organization**: Structured asset directories (owned_assets, cc0_assets)
- **Modular Architecture**: Clean directory structure with purpose documentation

## 5. Success Metrics

### 5.1 Player Engagement
- **Session Length**: Target 15-30 minutes per gameplay session
- **Goal Completion Rate**: >80% of players complete first-round goals
- **Retention**: Day 1 retention >60%, Day 7 retention >25%

### 5.2 Gameplay Balance
- **Energy Economy**: Players use all energy types meaningfully
- **Building Diversity**: No single building dominates optimal play
- **Difficulty Curve**: Progressive challenge increase across waves

### 5.3 Technical Performance
- **Load Times**: <3 seconds from launch to gameplay
- **Frame Rate**: Consistent 60 FPS on target mobile devices
- **Memory Usage**: <512MB on mid-range mobile devices

## 6. Development Roadmap

### 6.1 Phase 1: Core Mechanics (Current)
- ✅ Basic card system with energy costs
- ✅ Building deployment and management
- ✅ Enemy AI with range-based behavior
- ✅ Resource and goal systems

### 6.2 Phase 2: Content Expansion
- Additional hero classes and starting configurations
- Expanded card library with unique mechanics
- New enemy types and behavioral patterns
- Advanced building types with special abilities

### 6.3 Phase 3: Progression Systems
- Persistent progression between runs
- Deck customization and card unlocks
- Hero skill trees and specialization
- Achievement system integration

### 6.4 Phase 4: Polish & Launch
- Tutorial and onboarding flow
- Audio integration and sound effects
- Visual effects and animation polish
- Performance optimization and bug fixes

## 7. Risk Assessment

### 7.1 Design Risks
- **Complexity Management**: Multiple energy types may overwhelm new players
- **Balance Challenges**: Building-centric gameplay requires careful tuning
- **Pacing Issues**: Turn-based strategy may feel slow on mobile

### 7.2 Technical Risks  
- **Mobile Performance**: Real-time projectiles on lower-end devices
- **Data Management**: JSON-driven content pipeline complexity
- **Platform Differences**: Ensuring consistent experience across platforms

### 7.3 Mitigation Strategies
- **Gradual Introduction**: Tutorial introduces mechanics progressively
- **Automated Testing**: Data-driven balance testing tools
- **Performance Profiling**: Regular testing on target mobile devices
- **Modular Architecture**: Clean separation allows rapid iteration

---

*This PRD represents the current state of Swish based on implemented systems and serves as a foundation for continued development and iteration.*