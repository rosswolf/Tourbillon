#!/usr/bin/env python3
"""Test to capture Godot errors"""
import asyncio
from playwright.async_api import async_playwright
import subprocess
import time
import json

async def test_errors():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Capture ALL console messages with full text
        all_logs = []
        page.on("console", lambda msg: all_logs.append({
            "type": msg.type,
            "text": msg.text
        }))
        
        print("Loading game...")
        await page.goto("http://localhost:8000/")
        await page.wait_for_timeout(3000)
        
        print("Before clicking Play - checking for errors...")
        errors_before = [log for log in all_logs if log['type'] == 'error']
        if errors_before:
            print(f"Found {len(errors_before)} errors before clicking Play:")
            for err in errors_before:
                print(f"  ERROR: {err['text']}")
        
        print("\nClicking Play...")
        await page.mouse.click(104, 333)
        await page.wait_for_timeout(5000)
        
        print("\nAfter clicking Play - checking for errors...")
        errors_after = [log for log in all_logs if log['type'] == 'error']
        new_errors = errors_after[len(errors_before):]
        
        if new_errors:
            print(f"Found {len(new_errors)} NEW errors after clicking Play:")
            for err in new_errors:
                print(f"  ERROR: {err['text']}")
        else:
            print("No new errors after clicking Play")
        
        # Check for Tourbillon messages
        tourbillon_msgs = [log for log in all_logs if 'tourbillon' in log['text'].lower()]
        if tourbillon_msgs:
            print(f"\nFound {len(tourbillon_msgs)} Tourbillon-related messages:")
            for msg in tourbillon_msgs:
                print(f"  {msg['type'].upper()}: {msg['text'][:200]}")
        
        # Save all logs
        with open("claude_test_screenshots/error_logs.json", "w") as f:
            json.dump(all_logs, f, indent=2)
        print("\nFull logs saved to error_logs.json")
        
        await page.screenshot(path="claude_test_screenshots/error_test.png")
        print("Screenshot saved")
        
        await browser.close()

if __name__ == "__main__":
    server = subprocess.Popen(["python3", "serve_web.py"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(2)
    
    try:
        asyncio.run(test_errors())
    finally:
        server.terminate()