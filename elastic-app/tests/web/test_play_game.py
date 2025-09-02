#!/usr/bin/env python3
"""Test script to click Play and see the game map"""
import asyncio
from playwright.async_api import async_playwright
import time

async def test_play_game():
    """Click Play and capture the game state"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture console messages
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text[:200] if len(msg.text) > 200 else msg.text
        }))
        
        # Navigate to the game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu to load
        print("Waiting for menu to load...")
        await page.wait_for_timeout(3000)
        
        # Take screenshot of menu
        await page.screenshot(path="claude_test_screenshots/1_menu.png")
        print("📸 Menu screenshot saved")
        
        # Click Play button - adjusted position based on button location
        print("Clicking Play button at (104, 333)...")
        await page.mouse.click(104, 333)
        
        # Wait for transition
        print("Waiting for game to transition...")
        await page.wait_for_timeout(3000)
        
        # Take screenshot after first click
        await page.screenshot(path="claude_test_screenshots/2_after_play.png")
        print("📸 After Play click screenshot saved")
        
        # Try clicking in different areas if needed
        print("Trying center click at (640, 360)...")
        await page.mouse.click(640, 360)
        await page.wait_for_timeout(2000)
        
        await page.screenshot(path="claude_test_screenshots/3_center_click.png")
        print("📸 After center click screenshot saved")
        
        # Try keyboard input (Space or Enter often starts games)
        print("Pressing Space key...")
        await page.keyboard.press("Space")
        await page.wait_for_timeout(2000)
        
        await page.screenshot(path="claude_test_screenshots/4_after_space.png")
        print("📸 After Space key screenshot saved")
        
        # Print recent console messages
        if console_messages:
            print("\n=== Recent Console Messages ===")
            for msg in console_messages[-10:]:
                if msg['type'] == 'error':
                    print(f"❌ ERROR: {msg['text']}")
                elif msg['type'] == 'warning':
                    print(f"⚠️  WARN: {msg['text']}")
        
        await browser.close()
        print("\n✅ Test complete! Check screenshots in claude_test_screenshots/")

if __name__ == "__main__":
    # Start server
    import subprocess
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_play_game())
    finally:
        server.terminate()
        print("Server stopped")