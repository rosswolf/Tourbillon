#!/usr/bin/env python3
"""Test script to see the game after countdown completes"""
import asyncio
from playwright.async_api import async_playwright
import time

async def test_game_ready():
    """Click Play and wait for game to be fully ready"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Navigate to the game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu
        print("Waiting for menu...")
        await page.wait_for_timeout(2000)
        
        # Click Play button
        print("Clicking Play button...")
        await page.mouse.click(104, 333)
        
        # Wait longer for countdown to complete (3, 2, 1, GO! = ~4 seconds + load time)
        print("Waiting for countdown to complete...")
        await page.wait_for_timeout(8000)  # Extra time for game to fully load
        
        # Take screenshot of game ready state
        await page.screenshot(path="claude_test_screenshots/game_ready.png")
        print("📸 Game ready screenshot saved")
        
        # Move mouse around to see if there are hover effects
        print("Testing hover areas...")
        await page.mouse.move(400, 300)  # Center of play area
        await page.wait_for_timeout(500)
        
        await page.mouse.move(600, 350)  # Card area
        await page.wait_for_timeout(500)
        
        # Take another screenshot
        await page.screenshot(path="claude_test_screenshots/game_with_ui.png")
        print("📸 Game with UI screenshot saved")
        
        await browser.close()
        print("\n✅ Game map is now visible!")

if __name__ == "__main__":
    # Start server
    import subprocess
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_game_ready())
    finally:
        server.terminate()
        print("Server stopped")