#!/usr/bin/env python3
"""Test the deployed GitHub Pages version"""
import asyncio
from playwright.async_api import async_playwright
import json

async def test_github_pages():
    """Test the live GitHub Pages deployment"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture ALL console messages and errors
        console_messages = []
        page.on("console", lambda msg: console_messages.append({
            "type": msg.type,
            "text": msg.text
        }))
        
        page.on("pageerror", lambda err: console_messages.append({
            "type": "pageerror",
            "text": str(err)
        }))
        
        # Navigate to GitHub Pages URL
        print("Loading GitHub Pages deployment...")
        print("URL: https://rosswolf.github.io/Tourbillon/")
        
        try:
            response = await page.goto("https://rosswolf.github.io/Tourbillon/", wait_until="networkidle", timeout=30000)
            print(f"Response status: {response.status}")
        except Exception as e:
            print(f"Failed to load page: {e}")
        
        # Wait for potential Godot initialization
        print("Waiting for Godot to initialize...")
        await page.wait_for_timeout(10000)
        
        # Check for canvas
        print("\nChecking for canvas element...")
        canvas = await page.query_selector("canvas")
        if canvas:
            print("✅ Canvas found")
            is_visible = await canvas.is_visible()
            print(f"Canvas visible: {is_visible}")
            
            # Get canvas properties
            props = await canvas.evaluate("""(el) => ({
                width: el.width,
                height: el.height,
                display: window.getComputedStyle(el).display,
                visibility: window.getComputedStyle(el).visibility
            })""")
            print(f"Canvas properties: {json.dumps(props, indent=2)}")
        else:
            print("❌ No canvas found - Godot may not have loaded")
        
        # Check page content
        print("\nChecking page content...")
        body_html = await page.content()
        if "Play" in body_html or "Settings" in body_html:
            print("✅ Menu text found in page")
        else:
            print("❌ No menu text found")
            
        # Print ALL console messages
        print(f"\n=== Console Messages ({len(console_messages)}) ===")
        errors_found = False
        for msg in console_messages:
            if msg['type'] in ['error', 'pageerror']:
                print(f"❌ ERROR: {msg['text']}")
                errors_found = True
            elif msg['type'] == 'warning':
                print(f"⚠️  WARNING: {msg['text'][:200]}")
            elif 'Godot Engine' in msg['text']:
                print(f"✅ {msg['text']}")
            elif 'ERROR' in msg['text'] or 'Error' in msg['text'] or 'Failed' in msg['text']:
                print(f"❌ {msg['type'].upper()}: {msg['text'][:200]}")
                errors_found = True
        
        if not errors_found and len(console_messages) < 5:
            print("⚠️  Very few console messages - Godot may not be running")
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/github_pages_test.png")
        print("\n📸 Screenshot saved to claude_test_screenshots/github_pages_test.png")
        
        # Check what's actually visible
        print("\nChecking visible text on page...")
        visible_text = await page.evaluate("() => document.body.innerText")
        if visible_text:
            print(f"Visible text (first 200 chars): {visible_text[:200]}")
        else:
            print("No visible text on page")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(test_github_pages())