#!/usr/bin/env python3
"""
Simple HTTP server for testing Godot HTML5 exports
Handles CORS and SharedArrayBuffer requirements
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

PORT = 8000
DIRECTORY = "build/web"

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS and SharedArrayBuffer headers"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add headers required for SharedArrayBuffer (needed for Godot 4.x)
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests for CORS preflight"""
        self.send_response(200)
        self.end_headers()

def main():
    # Check if build directory exists
    if not os.path.exists(DIRECTORY):
        print(f"Error: Build directory '{DIRECTORY}' not found!")
        print("Please run ./build_web.sh first to build the project")
        sys.exit(1)
    
    # Check if index.html exists
    index_path = Path(DIRECTORY) / "index.html"
    if not index_path.exists():
        print(f"Error: index.html not found in '{DIRECTORY}'!")
        print("Please run ./build_web.sh first to build the project")
        sys.exit(1)
    
    # Start server
    with socketserver.TCPServer(("", PORT), CORSHTTPRequestHandler) as httpd:
        print(f"🚀 Serving Tourbillon at: http://localhost:{PORT}")
        print(f"📁 Serving from: {os.path.abspath(DIRECTORY)}")
        print("Press Ctrl+C to stop the server")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n👋 Server stopped")
            sys.exit(0)

if __name__ == "__main__":
    main()