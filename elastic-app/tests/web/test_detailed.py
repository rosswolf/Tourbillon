#!/usr/bin/env python3
"""Detailed test to capture all console output and errors"""
import asyncio
from playwright.async_api import async_playwright
import json
import os

async def test_with_details():
    """Test with detailed console capture"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture all console messages
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text,
            "location": f"{msg.location.get('url', '')}:{msg.location.get('lineNumber', '')}:{msg.location.get('columnNumber', '')}" if msg.location else ""
        }))
        
        # Capture page errors
        page_errors = []
        page.on("pageerror", lambda err: page_errors.append(str(err)))
        
        # Navigate to the game
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for Godot to initialize
        print("Waiting for Godot initialization...")
        await page.wait_for_timeout(5000)
        
        # Check for canvas
        print("Checking for canvas element...")
        canvas = await page.query_selector("canvas")
        if canvas:
            print("✅ Canvas found")
            is_visible = await canvas.is_visible()
            print(f"Canvas visible: {is_visible}")
            
            # Get canvas properties
            props = await canvas.evaluate("""(el) => {
                const rect = el.getBoundingClientRect();
                return {
                    width: el.width,
                    height: el.height,
                    display: window.getComputedStyle(el).display,
                    visibility: window.getComputedStyle(el).visibility,
                    rect: {
                        top: rect.top,
                        left: rect.left,
                        width: rect.width,
                        height: rect.height
                    }
                };
            }""")
            print(f"Canvas properties: {json.dumps(props, indent=2)}")
        else:
            print("❌ No canvas found")
        
        # Check for any Godot-specific elements
        print("\nChecking page content...")
        body_text = await page.evaluate("() => document.body.innerText")
        if body_text:
            print(f"Page text (first 200 chars): {body_text[:200]}")
        
        # Print console messages
        print(f"\n=== Console Messages ({len(console_messages)}) ===")
        for msg in console_messages[-20:]:  # Last 20 messages
            if msg['type'] == 'error':
                print(f"❌ ERROR: {msg['text']}")
            elif msg['type'] == 'warning':
                print(f"⚠️  WARN: {msg['text']}")
            else:
                print(f"ℹ️  {msg['type'].upper()}: {msg['text'][:100]}")
        
        # Print page errors
        if page_errors:
            print(f"\n=== Page Errors ({len(page_errors)}) ===")
            for err in page_errors:
                print(f"❌ {err}")
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/detailed_test.png")
        print("\n📸 Screenshot saved to claude_test_screenshots/detailed_test.png")
        
        await browser.close()

if __name__ == "__main__":
    # Ensure the server is running
    import subprocess
    import time
    
    # Start server if not running
    print("Starting server...")
    server = subprocess.Popen(["python3", "server.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_with_details())
    finally:
        server.terminate()
        print("\nServer stopped")