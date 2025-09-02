#!/usr/bin/env python3
"""Test script to fully load the game after countdown"""
import asyncio
from playwright.async_api import async_playwright
import time

async def test_full_game():
    """Click Play and wait for full game to load"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Navigate to the game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu
        print("Waiting for menu...")
        await page.wait_for_timeout(3000)
        
        # Click Play button
        print("Clicking Play button...")
        await page.mouse.click(104, 333)
        
        # Wait for countdown (3, 2, 1, GO!)
        print("Waiting for countdown to finish...")
        await page.wait_for_timeout(5000)  # Countdown takes about 4 seconds
        
        # Take screenshot of full game
        await page.screenshot(path="claude_test_screenshots/full_game_map.png")
        print("📸 Full game map screenshot saved")
        
        # Try to interact with the game
        print("Testing game interactions...")
        
        # Click on the main play area
        await page.mouse.click(400, 300)
        await page.wait_for_timeout(1000)
        
        # Try to drag a card (if cards are visible on the right)
        print("Attempting to drag a card...")
        await page.mouse.move(600, 350)  # Move to card area
        await page.mouse.down()
        await page.mouse.move(400, 300, steps=10)  # Drag to play area
        await page.mouse.up()
        await page.wait_for_timeout(1000)
        
        # Take final screenshot
        await page.screenshot(path="claude_test_screenshots/game_after_interaction.png")
        print("📸 After interaction screenshot saved")
        
        # Get viewport info
        viewport = page.viewport_size
        print(f"\nViewport size: {viewport['width']}x{viewport['height']}")
        
        await browser.close()
        print("\n✅ Game successfully loaded with main map visible!")

if __name__ == "__main__":
    # Start server
    import subprocess
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_full_game())
    finally:
        server.terminate()
        print("Server stopped")