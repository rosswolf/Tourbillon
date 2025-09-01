# Tourbillon

A clockwork engine builder roguelike card game with GitHub Claude AI integration.

## Project Contents

- **elastic-app/** - Original card game application (from ross-jam)
- **docs/** - Documentation including PRD and Claude integration guides
- **.github/** - GitHub Actions workflows for Claude AI

## Game Design

Tourbillon is a single-player roguelike card game that combines engine-building mechanics with time-based resource management. Players construct clockwork engines using gears and springs to generate five distinct forces, defend against gremlins, and ultimately build a perpetual motion machine to escape a collapsing timeline.

See `docs/TOURBILLON_PRD.md` for the complete Product Requirements Document.

## Claude AI Integration

This repository has full Claude AI integration for automated issue responses and code assistance.

To interact with Claude, mention `@claude` in any issue or comment. Once mentioned, Claude will monitor the entire thread and respond to all subsequent comments automatically.

### Features
- **Continuous thread monitoring** - Mention once, Claude stays engaged
- Session persistence with <60 second responses  
- Automated issue and comment responses
- Pull request creation capability
- Full repository access for code assistance
- PR review comment support

### Setup
See `docs/GITHUB_CLAUDE_INTEGRATION_SETUP.md` for detailed setup instructions.

## Project Origin

This repository is a fork of the ross-jam elastic-app project, enhanced with Claude AI capabilities for development assistance.

## Development

The elastic-app is a Godot-based card game. Navigate to `elastic-app/app/` to find the main project files.