#!/usr/bin/env python3
"""Test script to click Play button and check if game starts"""
import sys
import time
from claude_game_tester import ClaudeGameTester

def test_play_button():
    """Test clicking the Play button"""
    print("Starting Play button test...")
    tester = ClaudeGameTester(headless=True)
    
    try:
        # Start the tester
        if not tester.start():
            print("Failed to start tester")
            return False
            
        # Wait for menu to load
        print("Waiting for menu to load...")
        time.sleep(3)
        
        # Take initial screenshot
        tester.take_screenshot("menu_screen")
        
        # Click Play button (it's in the upper left area based on screenshot)
        print("Clicking Play button...")
        tester.click((118, 378))  # Approximate position of Play button
        
        # Wait for game to load
        print("Waiting for game to start...")
        time.sleep(5)
        
        # Take screenshot after clicking Play
        tester.take_screenshot("after_play_click")
        
        # Try clicking in the center to interact with game
        print("Clicking center of screen...")
        tester.click((960, 540))
        time.sleep(2)
        
        # Take final screenshot
        tester.take_screenshot("game_state")
        
        print("✅ Test complete - check screenshots")
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False
    finally:
        tester.stop()
        print("Test finished")

if __name__ == "__main__":
    success = test_play_button()
    sys.exit(0 if success else 1)