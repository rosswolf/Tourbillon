#!/usr/bin/env python3
"""Test the live deployment to check background"""
import asyncio
from playwright.async_api import async_playwright

async def test_live_background():
    """Test the deployed version and capture what's actually showing"""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Navigate to deployed game
        print("Loading deployed game...")
        await page.goto("https://rosswolf.github.io/Tourbillon/")
        
        # Wait for game to load
        print("Waiting for game to load...")
        await page.wait_for_timeout(5000)
        
        # Click Play button
        print("Clicking Play button...")
        await page.mouse.click(104, 333)
        
        # Wait for game scene
        print("Waiting for game scene to load...")
        await page.wait_for_timeout(5000)
        
        # Take screenshot
        await page.screenshot(path="claude_test_screenshots/live_background_check.png")
        print("📸 Screenshot saved")
        
        # Check network requests for image loads
        print("\nChecking loaded images...")
        images = await page.evaluate("""() => {
            const imgs = Array.from(document.querySelectorAll('img'));
            const backgrounds = Array.from(document.querySelectorAll('*')).filter(el => {
                const style = window.getComputedStyle(el);
                return style.backgroundImage && style.backgroundImage !== 'none';
            });
            return {
                imgSrcs: imgs.map(img => img.src),
                backgroundImages: backgrounds.map(el => window.getComputedStyle(el).backgroundImage)
            };
        }""")
        
        if images['imgSrcs']:
            print("Image sources found:")
            for src in images['imgSrcs']:
                if 'background' in src or 'gears' in src or 'underwater' in src:
                    print(f"  - {src}")
        
        if images['backgroundImages']:
            print("Background images found:")
            for bg in images['backgroundImages']:
                if 'background' in bg or 'gears' in bg or 'underwater' in bg:
                    print(f"  - {bg}")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(test_live_background())