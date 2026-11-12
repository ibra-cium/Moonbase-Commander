import http.server
import os
import sys

web_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "build", "web")
web_dir = os.path.abspath(web_dir)

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=web_dir, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, format, *args):
        try:
            super().log_message(format, *args)
        except (OSError, ValueError):
            pass

Handler.extensions_map[".wasm"] = "application/wasm"

class MoonbaseHTTPServer(http.server.ThreadingHTTPServer):
    allow_reuse_address = (os.name != "nt")

port = 8060
server = MoonbaseHTTPServer(("0.0.0.0", port), Handler)
server.serve_forever()

