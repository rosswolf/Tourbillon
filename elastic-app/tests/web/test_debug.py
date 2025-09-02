#!/usr/bin/env python3
"""Debug test to capture all errors when transitioning to game"""
import asyncio
from playwright.async_api import async_playwright
import time

async def test_debug():
    """Debug game transition issues"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture ALL console messages
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text,
            "time": time.time()
        }))
        
        page.on("pageerror", lambda err: console_messages.append({
            "type": "pageerror",
            "text": str(err),
            "time": time.time()
        }))
        
        # Navigate to game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        await page.wait_for_timeout(2000)
        
        # Clear console messages from initial load
        console_messages.clear()
        
        # Click Play
        print("Clicking Play...")
        await page.mouse.click(104, 333)
        
        # Wait for countdown and transition
        print("Waiting for countdown and transition...")
        await page.wait_for_timeout(8000)
        
        # Print all messages during transition
        print("\n=== Console Messages During Transition ===")
        for msg in console_messages:
            if msg['type'] in ['error', 'pageerror']:
                print(f"❌ {msg['type'].upper()}: {msg['text']}")
            elif msg['type'] == 'warning':
                print(f"⚠️  WARNING: {msg['text'][:200]}")
            elif 'ERROR' in msg['text'] or 'Error' in msg['text']:
                print(f"❌ {msg['type'].upper()}: {msg['text'][:200]}")
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/debug_final.png")
        
        await browser.close()

if __name__ == "__main__":
    import subprocess
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_debug())
    finally:
        server.terminate()
        print("\nServer stopped")