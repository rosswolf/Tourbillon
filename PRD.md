# Product Requirements Document
## Castlebuilder - AI-Enhanced Card Game Platform

### Executive Summary
Castlebuilder is a strategic card-based game built on the Godot engine, enhanced with Claude AI integration for automated development assistance through GitHub Actions. The project combines a tactical card game (originally from ross-jam/elastic-app) with cutting-edge AI workflow automation.

### Product Overview

#### Vision
Create an engaging card-based strategy game with AI-powered development workflows that enable rapid iteration and automated issue resolution.

#### Core Components
1. **Elastic Card Game** - The main gaming application
2. **Claude AI Integration** - Automated GitHub issue and PR management
3. **GitHub Actions Workflows** - CI/CD pipeline with AI assistance

### Active Components

#### 1. Elastic Game Application (`/elastic-app/`)
The primary product is a Godot 4.4-based card game featuring:

**Core Game Systems:**
- **Card Management System** - 54 GDScript files managing card mechanics, durability, and effects
- **Battle System** - Turn-based combat with position management and entity interactions
- **Resource System** - Multi-colored energy system (Purple, Blue, Green) with time-based mechanics
- **Goal System** - Dynamic objectives with rewards and punishments
- **Effect System** - Card slot effects, instinct effects, and one-time effects

**Game Features:**
- Hero selection system (currently Knight template)
- Card rarity system (Common, Uncommon, Rare)
- Status effects (Vulnerable, Weak multipliers)
- Relic collection and management
- Wave-based progression leading to boss encounters

**UI Components:**
- Main menu with settings
- Card hand visualization with drag-and-drop
- Real-time energy meters with hexadecimal time display
- Goal tracking interface
- Card selection modals
- Game over and pause screens

**Data Configuration:**
- JSON-based data system for cards, mobs, heroes, relics, and waves
- Configurable game parameters (hand size, card durability, etc.)
- Static data loading with caching and indexing

#### 2. Claude AI Integration (`/.github/workflows/`)

**Automated Workflows:**
- **Issue Response System** (`claude-session.yml`)
  - Monitors GitHub issues and comments for @claude mentions
  - Provides automated responses with <60 second latency
  - Full repository access for code analysis
  - Automatic PR creation capability

- **Session Management** (`claude-create-session.yml`)
  - Creates persistent Claude sessions for faster responses
  - Maintains context across multiple interactions
  - GitHub-native session storage

**Key Features:**
- Emoji reactions for user feedback
- Error handling with fallback mechanisms
- Session resumption for improved performance
- Automated git configuration for PR creation

### Unused/Legacy Components

The following components exist in the repository but are not actively utilized:
- Documentation files in `/docs/` related to previous Claude integration experiments
- Various `.md` files documenting past workflow iterations
- Test result documentation from earlier implementations

### Technical Architecture

#### Technology Stack
- **Game Engine**: Godot 4.4
- **Programming Language**: GDScript (primary), Python (data export tools)
- **CI/CD**: GitHub Actions with self-hosted runners
- **AI Assistant**: Claude API via CLI tool
- **Data Format**: JSON for game configuration

#### Game Architecture
- **Scene-based structure** with autoloaded singletons
- **Signal-driven communication** between components
- **Entity-Component pattern** for game objects
- **Builder pattern** for entity creation
- **Bimap data structure** for position management

### Current State & Roadmap

#### Current State (v1.0)
- ✅ Fully functional card game with basic gameplay loop
- ✅ Claude AI integration for development assistance
- ✅ Automated issue response system
- ✅ Data-driven configuration system

#### Future Enhancements
- [ ] Multiple hero classes beyond Knight
- [ ] Expanded card library
- [ ] Multiplayer support
- [ ] Save/load game state
- [ ] Achievement system
- [ ] Enhanced AI opponent behavior
- [ ] Mobile platform optimization

### User Personas

1. **Players**
   - Strategy game enthusiasts
   - Card game players
   - Casual gamers seeking tactical gameplay

2. **Developers**
   - Contributors who benefit from AI-assisted development
   - Maintainers using automated issue management

### Success Metrics
- Game session duration
- Card usage diversity
- GitHub issue resolution time (<60 seconds with Claude)
- PR creation success rate
- Player progression through waves

### Technical Requirements

#### Minimum System Requirements
- **OS**: Windows/Linux/macOS
- **Godot Version**: 4.4+
- **Display**: 1920x1080 resolution
- **Memory**: 2GB RAM

#### Development Requirements
- GitHub account with repository access
- Self-hosted runner with Claude CLI installed (for AI features)
- Godot 4.4 editor for game development

### Conclusion
Castlebuilder represents an innovative fusion of engaging card-based gameplay with AI-enhanced development workflows. The active components focus on delivering a polished gaming experience while leveraging Claude AI to streamline development and maintenance processes.