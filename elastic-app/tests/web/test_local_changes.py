#!/usr/bin/env python3
"""Test local changes - no air meters, ticks display, new cards"""
import asyncio
from playwright.async_api import async_playwright
import time
import subprocess

async def test_local_changes():
    """Test the local build with our changes"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture console messages
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text[:200] if len(msg.text) > 200 else msg.text
        }))
        
        # Navigate to local server
        print("Loading local game...")
        await page.goto("http://localhost:8000/")
        
        # Wait for menu
        print("Waiting for menu to load...")
        await page.wait_for_timeout(3000)
        
        # Click Play (should go directly to game, no countdown)
        print("Clicking Play button (should skip countdown)...")
        await page.mouse.click(104, 333)
        
        # Wait for game to load
        print("Waiting for game to load...")
        await page.wait_for_timeout(3000)
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/local_test_ui.png")
        print("📸 Screenshot saved")
        
        # Check for UI elements
        print("\nChecking UI elements...")
        
        # Look for tick display
        timer_text = await page.evaluate("""() => {
            const elements = Array.from(document.querySelectorAll('*'));
            const tickElements = elements.filter(el => 
                el.textContent && el.textContent.includes('Tick:')
            );
            return tickElements.length > 0 ? tickElements[0].textContent : null;
        }""")
        
        if timer_text:
            print(f"✅ Tick display found: {timer_text}")
        else:
            print("❌ No tick display found")
        
        # Check for Tourbillon cards mentioned in console
        tourbillon_cards = [msg for msg in console_messages if 'chronometer' in msg['text'].lower() or 'mainspring' in msg['text'].lower()]
        if tourbillon_cards:
            print("✅ Tourbillon cards detected in console")
            for msg in tourbillon_cards[:3]:
                print(f"  - {msg['text']}")
        
        # Check for air meter errors (should not exist)
        meter_errors = [msg for msg in console_messages if 'meter' in msg['text'].lower() and msg['type'] == 'error']
        if meter_errors:
            print("⚠️ Meter-related errors found (these should be removed):")
            for msg in meter_errors[:3]:
                print(f"  - {msg['text']}")
        else:
            print("✅ No air meter errors")
        
        await browser.close()

if __name__ == "__main__":
    # Start server
    print("Starting local server...")
    server = subprocess.Popen(["python3", "serve_web.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_local_changes())
    finally:
        server.terminate()
        print("\nServer stopped")