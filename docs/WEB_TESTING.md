# Tourbillon Web Testing Guide

**PRE-PR TESTING:** Claude can test Tourbillon's web deployment locally before creating PRs using automated browser testing.

## Testing Infrastructure

Three test scripts are available in the Tourbillon project (`elastic-app/app/`):

1. **`test_game.py`** - Quick validation test
   - Builds and launches the game
   - Tests basic interactions
   - Takes screenshots
   - Runs in headless mode by default

2. **`claude_game_tester.py`** - Full testing interface
   - Card game specific interactions (drag & drop)
   - Detailed logging and screenshots
   - Visual verification capabilities
   - Can run specific test suites

3. **`test_deployment.py`** - Complete deployment validation
   - Full build and serve pipeline
   - Performance metrics
   - Comprehensive browser tests
   - Generates detailed test reports

## Quick Test Commands

```bash
# From elastic-app/app directory:

# Quick test (headless - works without display):
python3 test_game.py

# Test with visible browser (requires display/XServer):
python3 test_game.py --no-headless

# Full deployment test with metrics:
python3 test_deployment.py

# Test card gameplay specifically:
python3 claude_game_tester.py --test cards
```

## What Claude Can Test

- **Build Process**: Verify the web export builds successfully
- **Game Loading**: Ensure the game loads without errors
- **Canvas Rendering**: Verify the game canvas is created and sized correctly
- **Card Game Interactions**: 
  - Click at specific coordinates
  - Drag cards from hand to play area
  - Press keyboard keys (Space, Enter, arrows)
  - Hover over card elements
- **Performance**: Load times, resource counts, DOM ready times
- **Visual Validation**: Screenshots at key points for comparison
- **Error Detection**: Console errors, missing resources, script failures

## Test Workflow for PRs

1. **Make code changes**
2. **Run local test**: `python3 test_game.py`
3. **Review screenshots**: Check `claude_test_screenshots/` folder
4. **Fix any issues found**
5. **Run full test**: `python3 test_deployment.py`
6. **Create PR when all tests pass**

## Testing Scripts Details

### test_game.py
- **Purpose**: Quick smoke test for basic functionality
- **Runtime**: ~30 seconds
- **Headless**: Yes (default)
- **Screenshots**: Basic game state captures
- **Use case**: Pre-commit validation

### claude_game_tester.py  
- **Purpose**: Comprehensive card game testing
- **Runtime**: 2-5 minutes
- **Headless**: Configurable
- **Screenshots**: Detailed card interactions
- **Use case**: Feature testing, debugging visual issues

### test_deployment.py
- **Purpose**: Full deployment pipeline validation
- **Runtime**: 3-8 minutes
- **Headless**: Yes
- **Screenshots**: Complete game flow
- **Use case**: Pre-PR testing, production readiness

## Test Output

Tests generate:
- **Screenshots**: `claude_test_screenshots/` directory
- **Test logs**: JSON format with timestamps and results
- **Console output**: Real-time feedback during testing
- **Performance metrics**: Load times, resource counts
- **Error reports**: Any JavaScript or loading errors

## Prerequisites

```bash
# Install dependencies (one-time setup):
pip install playwright
playwright install chromium

# For systems without display (servers, CI):
# Tests will run in headless mode automatically

# For local development with display:
# Tests can run with visible browser for debugging
```

## Browser Automation Details

The testing uses Playwright for browser automation:
- Runs in headless Chromium by default (no display needed)
- Can simulate real user interactions
- Captures console output and errors
- Takes screenshots for visual verification
- Measures performance metrics

## Troubleshooting

### Export Templates Missing
If you get an error about missing export templates:
```bash
# In Godot Editor: Editor → Manage Export Templates → Download
# Or install via command line (see WEB_DEPLOYMENT.md)
```

### Tests Timeout
If tests timeout during loading:
- Check console output for JavaScript errors
- Verify game builds properly with `./build_web.sh`
- Test manually by running `python3 serve_web.py` and visiting localhost:8000

### Screenshots Not Generated
- Ensure `claude_test_screenshots/` directory exists
- Check file permissions
- Run with `--no-headless` to see what's happening visually

### Card Drag & Drop Issues
If card interactions fail:
- Verify card elements have proper IDs/classes
- Check that cards are actually clickable (not covered by UI)
- Test card positioning logic manually

## Integration with CI/CD

Tests can be integrated into GitHub Actions for automated PR validation:

```yaml
# Example: .github/workflows/test-web.yml
- name: Test Web Build
  run: |
    cd elastic-app/app
    python3 test_game.py
    python3 test_deployment.py
```

## Related Documentation

- [WEB_DEPLOYMENT.md](./WEB_DEPLOYMENT.md) - Full deployment guide
- [WEB_BUILD_STATUS.md](./WEB_BUILD_STATUS.md) - Current build status
- Generic web testing capabilities in `/home/rosswolf/Code/CLAUDE.md`