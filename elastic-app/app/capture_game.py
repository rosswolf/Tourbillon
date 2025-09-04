#!/usr/bin/env python3

from playwright.sync_api import sync_playwright
import time
import sys

def capture_game_screenshot():
    with sync_playwright() as p:
        # Launch browser
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 1280, 'height': 720})
        
        # Navigate to the game
        page.goto('http://localhost:8001')
        
        # Wait for game to load
        print("Waiting for game to load...")
        time.sleep(5)  # Give the game time to initialize
        
        # Take screenshot
        screenshot_path = '/tmp/tourbillon_game.png'
        page.screenshot(path=screenshot_path)
        print(f"Screenshot saved to {screenshot_path}")
        
        # Try to click "Start Game" if it exists
        try:
            page.click('text="Start Game"', timeout=2000)
            time.sleep(3)
            page.screenshot(path='/tmp/tourbillon_game_started.png')
            print("Game started screenshot saved")
        except:
            print("Could not find Start Game button")
        
        browser.close()

if __name__ == "__main__":
    capture_game_screenshot()