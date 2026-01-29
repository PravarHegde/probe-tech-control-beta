import http.server
import socketserver
import os
import sys
import mimetypes

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

# Ensure common MIME types are explicitly known
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('text/css', '.css')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('application/json', '.json')

class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # 1. Clean path
        path = self.path.split('?')[0]  # Remove query params
        
        # 2. Construct filesystem path
        # lstrip("/") ensures we append relative to DIRECTORY
        full_path = os.path.join(DIRECTORY, path.lstrip("/"))
        
        # 3. Check if file exists on disk
        if os.path.exists(full_path) and os.path.isfile(full_path):
             # It exists! Let the parent class serve it (handling Range, caching, etc.)
             super().do_GET()
             return
        
        # 4. If it doesn't exist...
        
        # 4a. Is it a "file-like" request? (has extension)
        _, ext = os.path.splitext(path)
        if ext and len(ext) < 6:
            # It looks like a file (e.g. .js, .css, .png) but wasn't found.
            # Serve a 404, DO NOT FALLBACK TO INDEX.HTML (this causes "MIME type text/html" error for missing JS)
            self.send_error(404, "File not found")
            return
            
        # 4b. If it looks like a route (no extension), rewrite to index.html
        self.path = '/index.html'
        super().do_GET()

if __name__ == "__main__":
    Handler = SPAHandler
    # Allow address reuse to prevent "Address already in use" on quick restarts
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print(f"Serving SPA at port {PORT} from {DIRECTORY}")
        httpd.serve_forever()
