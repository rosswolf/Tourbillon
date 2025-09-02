#!/usr/bin/env python3
"""
Ultra-simple game testing script for Claude
Just run: python test_game.py
"""

from claude_game_tester import ClaudeGameTester
import sys

def test_tourbillon():
    """Run a simple test of Tourbillon"""
    
    print("🎮 Tourbillon Game Tester")
    print("="*40)
    
    # Create tester (headless mode for CI/servers without display)
    tester = ClaudeGameTester(headless=True)
    
    try:
        # Start the game
        print("\n1️⃣  Starting game...")
        if not tester.start(build_first=True):
            print("❌ Failed to start game")
            return False
            
        # Let it load
        print("\n2️⃣  Waiting for game to fully load...")
        tester.wait(3)
        
        # Take initial screenshot
        print("\n3️⃣  Taking initial screenshot...")
        tester.take_screenshot("game_loaded")
        
        # Get canvas info
        print("\n4️⃣  Getting canvas information...")
        canvas = tester.get_canvas_info()
        if canvas:
            print(f"   Canvas size: {canvas['width']}x{canvas['height']}")
            print(f"   Display size: {canvas['displayWidth']}x{canvas['displayHeight']}")
            
        # Try basic interactions
        print("\n5️⃣  Testing basic interactions...")
        
        # Click in center of canvas
        if canvas:
            center_x = canvas['x'] + canvas['displayWidth'] / 2
            center_y = canvas['y'] + canvas['displayHeight'] / 2
            print(f"   Clicking center at ({center_x:.0f}, {center_y:.0f})")
            tester.click(center_x, center_y)
            tester.wait(1)
            
        # Try keyboard inputs
        print("   Pressing Space...")
        tester.press_key("Space")
        tester.wait(0.5)
        
        print("   Pressing Enter...")
        tester.press_key("Enter")
        tester.wait(0.5)
        
        # Try arrow keys
        print("   Testing arrow keys...")
        for key in ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"]:
            tester.press_key(key)
            tester.wait(0.2)
            
        # Simulate a card drag (using estimated positions)
        print("\n6️⃣  Testing drag interaction...")
        if canvas:
            # Drag from bottom of screen (hand area) to middle (play area)
            from_x = canvas['x'] + canvas['displayWidth'] * 0.3
            from_y = canvas['y'] + canvas['displayHeight'] * 0.8
            to_x = canvas['x'] + canvas['displayWidth'] * 0.5
            to_y = canvas['y'] + canvas['displayHeight'] * 0.5
            
            print(f"   Dragging from ({from_x:.0f}, {from_y:.0f}) to ({to_x:.0f}, {to_y:.0f})")
            tester.drag_card((from_x, from_y), (to_x, to_y))
            tester.wait(1)
            
        # Take final screenshot
        print("\n7️⃣  Taking final screenshot...")
        tester.take_screenshot("after_interactions")
        
        # Look for clickable elements
        print("\n8️⃣  Looking for clickable UI elements...")
        clickables = tester.find_clickable_areas()
        if clickables:
            print(f"   Found {len(clickables)} clickable elements")
        else:
            print("   No HTML buttons found (game likely uses canvas rendering)")
            
        # Keep browser open for manual inspection
        print("\n✅ Automated tests complete!")
        print("\n📺 Browser will stay open for 15 seconds for manual inspection...")
        print("   You can interact with the game manually now.")
        tester.wait(15)
        
        return True
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        tester.take_screenshot("error")
        return False
        
    finally:
        print("\n🛑 Shutting down...")
        tester.stop()
        print("\n📸 Screenshots saved to: claude_test_screenshots/")
        print("📄 Test log saved to: claude_test_screenshots/test_log.json")

if __name__ == "__main__":
    success = test_tourbillon()
    sys.exit(0 if success else 1)