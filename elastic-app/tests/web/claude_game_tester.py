#!/usr/bin/env python3
"""
Claude-friendly game testing interface for Tourbillon
Provides simple commands for interacting with the HTML5 build
"""

import subprocess
import time
import sys
import os
from pathlib import Path
from typing import Optional, Tuple, Dict, Any
import json

try:
    from playwright.sync_api import sync_playwright, Page
except ImportError:
    print("Installing Playwright...")
    subprocess.run([sys.executable, "-m", "pip", "install", "playwright"])
    subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"])
    from playwright.sync_api import sync_playwright, Page

class ClaudeGameTester:
    """
    Simple interface for Claude to test Tourbillon web builds
    
    Usage:
        tester = ClaudeGameTester()
        tester.start()
        tester.click_button("Start Game")
        tester.drag_card(from_pos=(100, 200), to_pos=(300, 400))
        tester.take_screenshot("after_move")
        tester.stop()
    """
    
    def __init__(self, headless: bool = False, verbose: bool = True):
        self.server_process = None
        self.playwright = None
        self.browser = None
        self.page = None
        self.headless = headless
        self.verbose = verbose
        self.screenshots_dir = Path("claude_test_screenshots")
        self.screenshots_dir.mkdir(exist_ok=True)
        self.test_log = []
        
    def log(self, message: str, level: str = "info"):
        """Log a message"""
        if self.verbose:
            icons = {"info": "ℹ️", "success": "✅", "error": "❌", "action": "🎮"}
            print(f"{icons.get(level, '•')} {message}")
        self.test_log.append({"time": time.time(), "level": level, "message": message})
        
    def build(self) -> bool:
        """Build the Godot project"""
        self.log("Building project...", "info")
        result = subprocess.run(["./build_web.sh"], capture_output=True, text=True)
        if result.returncode == 0:
            self.log("Build successful!", "success")
            return True
        else:
            self.log(f"Build failed: {result.stderr}", "error")
            return False
            
    def start(self, build_first: bool = True) -> bool:
        """Start the game server and browser"""
        try:
            # Optionally build first
            if build_first and not self.build():
                return False
                
            # Start server
            self.log("Starting server...", "info")
            self.server_process = subprocess.Popen(
                [sys.executable, "serve_web.py"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            time.sleep(2)
            
            # Start browser
            self.log("Starting browser...", "info")
            self.playwright = sync_playwright().start()
            self.browser = self.playwright.chromium.launch(
                headless=self.headless,
                args=['--start-maximized'] if not self.headless else []
            )
            
            context = self.browser.new_context(
                viewport={'width': 1920, 'height': 1080}
            )
            self.page = context.new_page()
            
            # Set up console logging
            self.page.on("console", lambda msg: self.log(f"[Console] {msg.text}", "info"))
            self.page.on("pageerror", lambda exc: self.log(f"[Error] {exc}", "error"))
            
            # Navigate to game
            self.log("Loading game...", "info")
            self.page.goto("http://localhost:8000", wait_until="networkidle")
            
            # Wait for canvas
            self.page.wait_for_selector("canvas", timeout=10000)
            self.log("Game loaded!", "success")
            
            # Focus the canvas
            self.click_canvas()
            
            return True
            
        except Exception as e:
            self.log(f"Failed to start: {e}", "error")
            return False
            
    def stop(self):
        """Stop the game server and browser"""
        self.log("Stopping tester...", "info")
        
        if self.browser:
            self.browser.close()
        if self.playwright:
            self.playwright.stop()
        if self.server_process:
            self.server_process.terminate()
            try:
                self.server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                
        # Save test log
        log_path = self.screenshots_dir / "test_log.json"
        with open(log_path, "w") as f:
            json.dump(self.test_log, f, indent=2)
        self.log(f"Test log saved to {log_path}", "success")
        
    # === BASIC INTERACTIONS ===
    
    def click(self, x: int, y: int):
        """Click at specific coordinates"""
        self.log(f"Clicking at ({x}, {y})", "action")
        self.page.mouse.click(x, y)
        
    def click_canvas(self):
        """Click on the game canvas to focus it"""
        canvas = self.page.query_selector("canvas")
        if canvas:
            canvas.click()
            self.log("Clicked canvas", "action")
        else:
            self.log("Canvas not found", "error")
            
    def click_button(self, text: str):
        """Click a button by its text"""
        self.log(f"Clicking button: {text}", "action")
        try:
            # Try different selectors for Godot buttons
            button = self.page.get_by_text(text).first
            if button:
                button.click()
            else:
                self.log(f"Button '{text}' not found", "error")
        except Exception as e:
            self.log(f"Failed to click button: {e}", "error")
            
    def hover(self, x: int, y: int):
        """Hover at specific coordinates"""
        self.log(f"Hovering at ({x}, {y})", "action")
        self.page.mouse.move(x, y)
        
    # === CARD GAME SPECIFIC ===
    
    def drag_card(self, from_pos: Tuple[int, int], to_pos: Tuple[int, int], duration: float = 0.5):
        """Drag a card from one position to another"""
        self.log(f"Dragging from {from_pos} to {to_pos}", "action")
        
        # Move to start position
        self.page.mouse.move(from_pos[0], from_pos[1])
        
        # Press down
        self.page.mouse.down()
        
        # Drag to end position (with steps for smooth animation)
        steps = int(duration * 60)  # 60fps
        for i in range(steps):
            progress = (i + 1) / steps
            x = from_pos[0] + (to_pos[0] - from_pos[0]) * progress
            y = from_pos[1] + (to_pos[1] - from_pos[1]) * progress
            self.page.mouse.move(x, y)
            time.sleep(duration / steps)
            
        # Release
        self.page.mouse.up()
        
    def drag_and_drop(self, selector_from: str, selector_to: str):
        """Drag from one element to another using selectors"""
        self.log(f"Dragging {selector_from} to {selector_to}", "action")
        try:
            source = self.page.query_selector(selector_from)
            target = self.page.query_selector(selector_to)
            if source and target:
                source.drag_to(target)
            else:
                self.log("Source or target element not found", "error")
        except Exception as e:
            self.log(f"Drag and drop failed: {e}", "error")
            
    # === KEYBOARD INPUTS ===
    
    def press_key(self, key: str):
        """Press a keyboard key"""
        self.log(f"Pressing key: {key}", "action")
        self.page.keyboard.press(key)
        
    def type_text(self, text: str):
        """Type text"""
        self.log(f"Typing: {text}", "action")
        self.page.keyboard.type(text)
        
    # === GAME STATE ===
    
    def wait(self, seconds: float):
        """Wait for a specified time"""
        self.log(f"Waiting {seconds} seconds...", "info")
        self.page.wait_for_timeout(int(seconds * 1000))
        
    def take_screenshot(self, name: str = "screenshot") -> Path:
        """Take a screenshot"""
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        filename = f"{name}_{timestamp}.png"
        path = self.screenshots_dir / filename
        self.page.screenshot(path=path)
        self.log(f"Screenshot saved: {filename}", "success")
        return path
        
    def get_canvas_info(self) -> Optional[Dict[str, Any]]:
        """Get information about the game canvas"""
        try:
            info = self.page.evaluate("""() => {
                const canvas = document.querySelector('canvas');
                if (!canvas) return null;
                const rect = canvas.getBoundingClientRect();
                return {
                    width: canvas.width,
                    height: canvas.height,
                    x: rect.x,
                    y: rect.y,
                    displayWidth: rect.width,
                    displayHeight: rect.height
                };
            }""")
            self.log(f"Canvas info: {info}", "info")
            return info
        except Exception as e:
            self.log(f"Failed to get canvas info: {e}", "error")
            return None
            
    def find_clickable_areas(self) -> list:
        """Find areas that might be clickable (experimental)"""
        # This would need to be customized based on how Tourbillon renders
        try:
            # Look for any div or button elements that might be overlaid
            elements = self.page.evaluate("""() => {
                const elements = [];
                document.querySelectorAll('button, div[onclick], [role="button"]').forEach(el => {
                    const rect = el.getBoundingClientRect();
                    elements.push({
                        text: el.innerText || el.value || '',
                        x: rect.x + rect.width/2,
                        y: rect.y + rect.height/2,
                        width: rect.width,
                        height: rect.height
                    });
                });
                return elements;
            }""")
            
            if elements:
                self.log(f"Found {len(elements)} clickable elements", "info")
                for el in elements:
                    self.log(f"  - '{el.get('text', 'unnamed')}' at ({el['x']}, {el['y']})", "info")
            return elements
        except Exception as e:
            self.log(f"Failed to find clickable areas: {e}", "error")
            return []
            
    # === VISUAL TESTING ===
    
    def compare_screenshots(self, name1: str, name2: str) -> float:
        """Compare two screenshots (requires additional libraries)"""
        # This would need PIL/Pillow for actual comparison
        self.log(f"Screenshot comparison not yet implemented", "info")
        return 0.0
        
    def wait_for_animation(self, timeout: float = 2.0):
        """Wait for animations to complete"""
        self.log("Waiting for animations...", "info")
        # Wait for any CSS animations
        self.page.wait_for_timeout(int(timeout * 1000))
        
    # === QUICK TEST SEQUENCES ===
    
    def test_basic_interaction(self):
        """Run a basic interaction test"""
        self.log("Running basic interaction test...", "info")
        
        # Take initial screenshot
        self.take_screenshot("initial")
        
        # Click around the canvas
        canvas_info = self.get_canvas_info()
        if canvas_info:
            center_x = canvas_info['x'] + canvas_info['displayWidth'] / 2
            center_y = canvas_info['y'] + canvas_info['displayHeight'] / 2
            
            # Click center
            self.click(center_x, center_y)
            self.wait(0.5)
            
            # Try some common game keys
            self.press_key("Space")
            self.wait(0.5)
            self.press_key("Enter")
            self.wait(0.5)
            
            # Take final screenshot
            self.take_screenshot("after_interaction")
            
        self.log("Basic interaction test complete", "success")
        
    def test_card_gameplay(self):
        """Test card game specific interactions"""
        self.log("Testing card gameplay...", "info")
        
        # This would need to be customized based on Tourbillon's actual UI
        # For now, it's a template
        
        self.take_screenshot("game_start")
        
        # Try to find and click start button
        self.click_button("Start")
        self.wait(1)
        
        # Simulate dragging a card (would need actual coordinates)
        # These are placeholder coordinates
        self.drag_card((500, 600), (700, 400))
        self.wait(0.5)
        
        self.take_screenshot("after_card_play")
        
        self.log("Card gameplay test complete", "success")


# === SIMPLE CLI FOR CLAUDE ===

def main():
    """Simple CLI for testing"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Test Tourbillon web build")
    parser.add_argument("--headless", action="store_true", help="Run in headless mode")
    parser.add_argument("--no-build", action="store_true", help="Skip building")
    parser.add_argument("--test", choices=["basic", "cards", "full"], default="basic",
                       help="Which test to run")
    
    args = parser.parse_args()
    
    # Create tester
    tester = ClaudeGameTester(headless=args.headless)
    
    try:
        # Start game
        if not tester.start(build_first=not args.no_build):
            print("Failed to start game")
            return 1
            
        # Run selected test
        if args.test == "basic":
            tester.test_basic_interaction()
        elif args.test == "cards":
            tester.test_card_gameplay()
        else:  # full
            tester.test_basic_interaction()
            tester.test_card_gameplay()
            
        # Keep browser open for a bit if not headless
        if not args.headless:
            print("\n📺 Browser will stay open for 10 seconds...")
            tester.wait(10)
            
    finally:
        tester.stop()
        
    print("\n✨ Testing complete! Check claude_test_screenshots/ for results.")
    return 0

if __name__ == "__main__":
    sys.exit(main())