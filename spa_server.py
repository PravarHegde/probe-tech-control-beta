import http.server
import socketserver
import os
import sys

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'dist')

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def handle_spa_routing(self):
        # Allow requests to specific file extensions or root
        # If path doesn't likely point to a file (no extension), serve index.html
        path = self.path.split('?')[0]  # Remove query params
        
        # Check if the file exists in the directory (DIRECTORY is absolute)
        # We strip leading / to join correctly, but we must be careful not to use os.getcwd() if DIRECTORY is absolute
        full_path = os.path.join(DIRECTORY, path.lstrip("/"))
        
        if os.path.exists(full_path) and os.path.isfile(full_path):
             return # Let default handler serve the file
        
        # Check if it looks like an asset (has extension)
        _, ext = os.path.splitext(path)
        if ext and len(ext) < 5: # likely a file like .js, .css, .png
            return # Let default handler return 404 if missing
            
        # Rewrites
        self.path = '/index.html'

    def do_GET(self):
        self.handle_spa_routing()
        super().do_GET()

    def do_HEAD(self):
        self.handle_spa_routing()
        super().do_HEAD()

if __name__ == "__main__":
    # Ensure we are in the right directory or change permission
    # For now, assumes script runs from project root and dist exists
    
    Handler = SPAHandler
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving SPA at port {PORT}")
        httpd.serve_forever()
