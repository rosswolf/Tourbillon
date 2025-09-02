#!/usr/bin/env python3
"""Test script to enter the game and check gameplay"""
import asyncio
from playwright.async_api import async_playwright
import time

async def test_gameplay():
    """Test entering the game and checking UI"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Navigate to the game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu to load
        print("Waiting for menu...")
        await page.wait_for_timeout(3000)
        
        # Take screenshot of menu
        await page.screenshot(path="claude_test_screenshots/menu.png")
        print("📸 Menu screenshot saved")
        
        # Click Play button (approximate position based on screenshot)
        print("Clicking Play button...")
        await page.click("canvas", position={"x": 118, "y": 358})
        
        # Wait for game to load
        print("Waiting for game to load...")
        await page.wait_for_timeout(5000)
        
        # Take screenshot of gameplay
        await page.screenshot(path="claude_test_screenshots/gameplay.png")
        print("📸 Gameplay screenshot saved")
        
        # Get canvas info
        canvas = await page.query_selector("canvas")
        if canvas:
            is_visible = await canvas.is_visible()
            print(f"✅ Canvas visible: {is_visible}")
            
            # Get canvas size
            size = await canvas.evaluate("""(el) => ({
                width: el.width,
                height: el.height
            })""")
            print(f"Canvas size: {size['width']}x{size['height']}")
        
        # Check console for any errors
        console_messages = []
        page.on("console", lambda msg: console_messages.append(msg))
        
        await browser.close()
        print("\n✅ Test complete!")

if __name__ == "__main__":
    # Start server
    import subprocess
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_gameplay())
    finally:
        server.terminate()
        print("Server stopped")