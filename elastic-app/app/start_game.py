#!/usr/bin/env python3

from playwright.sync_api import sync_playwright
import time

def start_game():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 1280, 'height': 720})
        
        # Navigate to game
        page.goto('http://localhost:8001')
        print("Loading game...")
        time.sleep(5)
        
        # Get all clickable elements
        buttons = page.query_selector_all('button, [role="button"], .button')
        print(f"Found {len(buttons)} button elements")
        
        # Also check for any text elements
        all_text = page.inner_text('body')
        print("Page text content:")
        print(all_text[:500] if all_text else "No text found")
        
        # Try clicking on coordinates where Play button should be
        # Based on the menu screenshot, Play is in the middle
        try:
            page.mouse.click(640, 360)  # Center of screen
            print("Clicked center of screen")
            time.sleep(3)
            page.screenshot(path='/tmp/game_after_center_click.png')
            
            # Now try to start Tourbillon mode
            page.mouse.click(640, 400)  # A bit lower
            print("Clicked lower area")
            time.sleep(3)
            page.screenshot(path='/tmp/game_in_progress.png')
            
        except Exception as e:
            print(f"Error clicking: {e}")
        
        browser.close()

if __name__ == "__main__":
    start_game()