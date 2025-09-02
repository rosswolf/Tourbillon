#!/usr/bin/env python3
"""Test with console output capture"""
import asyncio
from playwright.async_api import async_playwright
import time
import subprocess
import json

async def test_with_console():
    """Test the local build with console output"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture ALL console messages
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text
        }))
        
        # Navigate to local server
        print("Loading local game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu
        print("Waiting for menu to load...")
        await page.wait_for_timeout(3000)
        
        # Click Play
        print("Clicking Play button...")
        await page.mouse.click(104, 333)
        
        # Wait for game to load
        print("Waiting for game to load...")
        await page.wait_for_timeout(3000)
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/console_test.png")
        
        # Print all console messages
        print("\n=== CONSOLE OUTPUT ===")
        for msg in console_messages:
            if msg['type'] == 'error':
                print(f"❌ ERROR: {msg['text']}")
            elif msg['type'] == 'warning':
                print(f"⚠️  WARN: {msg['text']}")
            else:
                print(f"   INFO: {msg['text'][:200]}")
        
        # Look for specific patterns
        print("\n=== ANALYSIS ===")
        errors = [m for m in console_messages if m['type'] == 'error']
        if errors:
            print(f"Found {len(errors)} errors")
            for err in errors[:5]:
                print(f"  - {err['text'][:100]}")
        
        tourbillon_msgs = [m for m in console_messages if 'tourbillon' in m['text'].lower()]
        if tourbillon_msgs:
            print(f"Found {len(tourbillon_msgs)} Tourbillon-related messages")
            for msg in tourbillon_msgs[:5]:
                print(f"  - {msg['text'][:100]}")
        
        await browser.close()

if __name__ == "__main__":
    # Start server
    print("Starting local server...")
    server = subprocess.Popen(["python3", "serve_web.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_with_console())
    finally:
        server.terminate()
        print("\nServer stopped")