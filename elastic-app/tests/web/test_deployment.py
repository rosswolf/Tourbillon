#!/usr/bin/env python3
"""
Automated deployment testing for Tourbillon
Builds the project, serves it locally, and tests in a browser
"""

import subprocess
import time
import sys
import os
import signal
from pathlib import Path
import json
from datetime import datetime

# Check for playwright
try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("❌ Playwright not installed. Installing...")
    subprocess.run([sys.executable, "-m", "pip", "install", "playwright"])
    subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"])
    from playwright.sync_api import sync_playwright

class TourbillonTester:
    def __init__(self):
        self.server_process = None
        self.test_results = []
        self.screenshots_dir = Path("test_screenshots")
        self.screenshots_dir.mkdir(exist_ok=True)
        
    def build_project(self):
        """Build the Godot project for web"""
        print("🔨 Building project for web...")
        result = subprocess.run(
            ["./build_web.sh"],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"❌ Build failed:\n{result.stderr}")
            return False
            
        print("✅ Build successful!")
        return True
        
    def start_server(self):
        """Start the local web server"""
        print("🌐 Starting local server...")
        self.server_process = subprocess.Popen(
            [sys.executable, "serve_web.py"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Wait for server to start
        time.sleep(2)
        
        # Check if server is running
        if self.server_process.poll() is not None:
            print("❌ Server failed to start")
            return False
            
        print("✅ Server started on http://localhost:8000")
        return True
        
    def stop_server(self):
        """Stop the local web server"""
        if self.server_process:
            print("🛑 Stopping server...")
            self.server_process.terminate()
            try:
                self.server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_process.kill()
                
    def run_browser_tests(self):
        """Run automated browser tests"""
        print("🧪 Running browser tests...")
        
        with sync_playwright() as p:
            # Launch browser (visible by default for debugging)
            browser = p.chromium.launch(
                headless=False,  # Set to True for CI/CD
                args=['--start-maximized']
            )
            
            context = browser.new_context(
                viewport={'width': 1920, 'height': 1080},
                ignore_https_errors=True
            )
            
            page = context.new_page()
            
            # Enable console logging
            page.on("console", lambda msg: print(f"  [Browser Console] {msg.text}"))
            page.on("pageerror", lambda exc: print(f"  [Page Error] {exc}"))
            
            try:
                # Test 1: Load the game
                print("\n📍 Test 1: Loading game...")
                page.goto("http://localhost:8000", wait_until="networkidle")
                self.test_results.append({"test": "page_load", "status": "passed"})
                print("  ✅ Page loaded successfully")
                
                # Take initial screenshot
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                page.screenshot(path=self.screenshots_dir / f"initial_{timestamp}.png")
                print(f"  📸 Screenshot saved: initial_{timestamp}.png")
                
                # Test 2: Check if canvas is present
                print("\n📍 Test 2: Checking for game canvas...")
                canvas = page.query_selector("canvas")
                if canvas:
                    self.test_results.append({"test": "canvas_present", "status": "passed"})
                    print("  ✅ Game canvas found")
                else:
                    self.test_results.append({"test": "canvas_present", "status": "failed"})
                    print("  ❌ Game canvas not found")
                    
                # Test 3: Wait for game to fully load
                print("\n📍 Test 3: Waiting for game initialization...")
                page.wait_for_timeout(3000)  # Give game time to initialize
                
                # Check for Godot-specific elements or loading completion
                try:
                    # Try to detect if Godot has loaded by checking for specific elements
                    page.wait_for_function(
                        "() => document.querySelector('canvas') && document.querySelector('canvas').width > 0",
                        timeout=10000
                    )
                    self.test_results.append({"test": "game_initialized", "status": "passed"})
                    print("  ✅ Game initialized")
                except Exception as e:
                    self.test_results.append({"test": "game_initialized", "status": "failed", "error": str(e)})
                    print(f"  ⚠️  Game initialization timeout: {e}")
                
                # Test 4: Simulate user interactions
                print("\n📍 Test 4: Testing user interactions...")
                
                # Click on the canvas to focus it
                if canvas:
                    canvas.click()
                    print("  🖱️  Clicked on canvas")
                    
                # Simulate keyboard input
                page.keyboard.press("Space")
                print("  ⌨️  Pressed Space key")
                
                # Simulate mouse movement
                page.mouse.move(500, 500)
                page.mouse.click(500, 500)
                print("  🖱️  Moved and clicked mouse")
                
                # Take screenshot after interactions
                page.wait_for_timeout(1000)
                page.screenshot(path=self.screenshots_dir / f"after_interaction_{timestamp}.png")
                print(f"  📸 Screenshot saved: after_interaction_{timestamp}.png")
                
                self.test_results.append({"test": "user_interactions", "status": "passed"})
                print("  ✅ User interactions completed")
                
                # Test 5: Check for JavaScript errors
                print("\n📍 Test 5: Checking for JavaScript errors...")
                errors = page.evaluate("() => window.__errors || []")
                if not errors:
                    self.test_results.append({"test": "no_js_errors", "status": "passed"})
                    print("  ✅ No JavaScript errors detected")
                else:
                    self.test_results.append({"test": "no_js_errors", "status": "failed", "errors": errors})
                    print(f"  ❌ JavaScript errors found: {errors}")
                
                # Test 6: Performance check
                print("\n📍 Test 6: Checking performance metrics...")
                metrics = page.evaluate("""() => {
                    const perf = performance.getEntriesByType('navigation')[0];
                    return {
                        loadTime: perf.loadEventEnd - perf.fetchStart,
                        domReady: perf.domContentLoadedEventEnd - perf.fetchStart,
                        resources: performance.getEntriesByType('resource').length
                    };
                }""")
                
                print(f"  ⏱️  Load time: {metrics['loadTime']:.2f}ms")
                print(f"  ⏱️  DOM ready: {metrics['domReady']:.2f}ms")
                print(f"  📦 Resources loaded: {metrics['resources']}")
                
                if metrics['loadTime'] < 5000:  # Less than 5 seconds
                    self.test_results.append({"test": "performance", "status": "passed", "metrics": metrics})
                    print("  ✅ Performance acceptable")
                else:
                    self.test_results.append({"test": "performance", "status": "warning", "metrics": metrics})
                    print("  ⚠️  Load time exceeds 5 seconds")
                    
            except Exception as e:
                print(f"❌ Test failed with error: {e}")
                self.test_results.append({"test": "browser_tests", "status": "failed", "error": str(e)})
                page.screenshot(path=self.screenshots_dir / f"error_{timestamp}.png")
                
            finally:
                browser.close()
                
    def generate_report(self):
        """Generate a test report"""
        print("\n" + "="*50)
        print("📊 TEST REPORT")
        print("="*50)
        
        passed = sum(1 for r in self.test_results if r["status"] == "passed")
        failed = sum(1 for r in self.test_results if r["status"] == "failed")
        warnings = sum(1 for r in self.test_results if r["status"] == "warning")
        
        print(f"\n✅ Passed: {passed}")
        print(f"❌ Failed: {failed}")
        print(f"⚠️  Warnings: {warnings}")
        
        print("\nDetailed Results:")
        for result in self.test_results:
            status_icon = "✅" if result["status"] == "passed" else "❌" if result["status"] == "failed" else "⚠️"
            print(f"  {status_icon} {result['test']}: {result['status']}")
            if "error" in result:
                print(f"     Error: {result.get('error', 'N/A')}")
                
        # Save report to file
        report_path = Path("test_report.json")
        with open(report_path, "w") as f:
            json.dump({
                "timestamp": datetime.now().isoformat(),
                "summary": {
                    "passed": passed,
                    "failed": failed,
                    "warnings": warnings
                },
                "results": self.test_results
            }, f, indent=2)
            
        print(f"\n📄 Full report saved to: {report_path}")
        print(f"📸 Screenshots saved to: {self.screenshots_dir}/")
        
        return failed == 0
        
    def run(self):
        """Run the complete test suite"""
        print("🚀 Starting Tourbillon deployment test...")
        print("="*50)
        
        try:
            # Build project
            if not self.build_project():
                return False
                
            # Start server
            if not self.start_server():
                return False
                
            # Run browser tests
            self.run_browser_tests()
            
            # Generate report
            success = self.generate_report()
            
            return success
            
        finally:
            # Clean up
            self.stop_server()
            
def main():
    """Main entry point"""
    tester = TourbillonTester()
    
    # Handle Ctrl+C gracefully
    def signal_handler(sig, frame):
        print("\n\n⚠️  Test interrupted by user")
        tester.stop_server()
        sys.exit(1)
        
    signal.signal(signal.SIGINT, signal_handler)
    
    # Run tests
    success = tester.run()
    
    if success:
        print("\n✨ All tests passed! Deployment is ready.")
        sys.exit(0)
    else:
        print("\n❌ Some tests failed. Please review the report.")
        sys.exit(1)

if __name__ == "__main__":
    main()