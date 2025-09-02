#!/usr/bin/env python3
"""Final test for all changes"""
import asyncio
from playwright.async_api import async_playwright
import subprocess
import time

async def final_test():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture console for debugging
        console_logs = []
        page.on("console", lambda msg: console_logs.append(f"{msg.type}: {msg.text[:100]}"))
        
        print("1. Loading game...")
        await page.goto("http://localhost:8000/")
        await page.wait_for_timeout(3000)
        
        # Take menu screenshot
        await page.screenshot(path="claude_test_screenshots/final_1_menu.png")
        print("   Menu screenshot taken")
        
        print("2. Clicking Play button...")
        # Try clicking the actual button element
        try:
            await page.click("text=Play", timeout=2000)
        except:
            # Fallback to coordinates
            await page.mouse.click(104, 333)
        
        print("3. Waiting for game to load...")
        await page.wait_for_timeout(8000)  # Longer wait
        
        # Take game screenshot
        await page.screenshot(path="claude_test_screenshots/final_2_game.png")
        print("   Game screenshot taken")
        
        # Check for important messages
        print("\n4. Checking console output...")
        tourbillon_msgs = [log for log in console_logs if 'tourbillon' in log.lower() or 'initializ' in log.lower()]
        if tourbillon_msgs:
            print("   Found Tourbillon/initialization messages:")
            for msg in tourbillon_msgs:
                print(f"     {msg}")
        
        error_msgs = [log for log in console_logs if log.startswith('error:')]
        if error_msgs:
            print("   Found errors:")
            for msg in error_msgs[:5]:
                print(f"     {msg}")
        else:
            print("   No errors found")
        
        # Check page content
        content = await page.content()
        if "gears_background" in content.lower():
            print("   ✅ Gears background reference found")
        
        print("\n5. Test complete!")
        
        await browser.close()

if __name__ == "__main__":
    server = subprocess.Popen(["python3", "serve_web.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(final_test())
    finally:
        server.terminate()
        print("\nServer stopped")