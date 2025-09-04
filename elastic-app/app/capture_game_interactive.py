#!/usr/bin/env python3

from playwright.sync_api import sync_playwright
import time
import sys

def capture_game_interactive():
    with sync_playwright() as p:
        # Launch browser
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 1280, 'height': 720})
        
        # Navigate to the game
        page.goto('http://localhost:8001')
        
        # Wait for game to load
        print("Waiting for game to load...")
        time.sleep(5)  # Give the game time to initialize
        
        # Take initial screenshot
        page.screenshot(path='/tmp/game_menu.png')
        print("Menu screenshot saved")
        
        # Click Play button
        try:
            page.click('button:has-text("Play")', timeout=3000)
            print("Clicked Play")
            time.sleep(2)
            page.screenshot(path='/tmp/game_after_play.png')
        except:
            print("Could not find Play button")
            
        # Try to click Tourbillon or start the game mode
        try:
            # Look for any button that might start the game
            page.click('button:has-text("Tourbillon")', timeout=3000)
            print("Clicked Tourbillon")
            time.sleep(3)
            page.screenshot(path='/tmp/game_tourbillon.png')
        except:
            try:
                # Alternative: click on any visible button
                page.click('button >> nth=0', timeout=2000)
                time.sleep(3)
                page.screenshot(path='/tmp/game_first_button.png')
            except:
                print("No buttons found to click")
        
        # Final screenshot after any interactions
        time.sleep(2)
        page.screenshot(path='/tmp/game_final.png')
        print("Final screenshot saved")
        
        browser.close()

if __name__ == "__main__":
    capture_game_interactive()