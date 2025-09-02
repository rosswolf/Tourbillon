#!/usr/bin/env python3
"""Quick test to check if game loads"""
import asyncio
from playwright.async_api import async_playwright
import subprocess
import time

async def quick_test():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture console
        console_logs = []
        page.on("console", lambda msg: console_logs.append(f"{msg.type}: {msg.text[:100]}"))
        
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        await page.wait_for_timeout(2000)
        
        print("Clicking Play...")
        await page.mouse.click(104, 333)  # Coordinates for Play button
        await page.wait_for_timeout(3000)
        
        print("\nConsole output:")
        for log in console_logs[-10:]:
            print(log)
        
        await page.screenshot(path="claude_test_screenshots/quick_test.png")
        print("\nScreenshot saved")
        
        await browser.close()

if __name__ == "__main__":
    server = subprocess.Popen(["python3", "serve_web.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(quick_test())
    finally:
        server.terminate()