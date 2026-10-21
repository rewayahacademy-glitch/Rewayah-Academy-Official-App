"""Serve generated public routes locally, including their clean URLs."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parent / 'tests' / '.qa-build'


class PreviewHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        if urlsplit(self.path).path == '/connexion':
            self.send_error(503, 'Application non servie dans cet apercu local', 'La connexion appartient au parcours existant de l’application.')
            return
        super().do_GET()

    def translate_path(self, path):
        resolved = Path(super().translate_path(path))
        if not resolved.suffix and resolved.with_suffix('.html').is_file():
            return str(resolved.with_suffix('.html'))
        return str(resolved)


if __name__ == '__main__':
    print('Aperçu Rewayah : http://127.0.0.1:8766/fr/', flush=True)
    ThreadingHTTPServer(('127.0.0.1', 8766), PreviewHandler).serve_forever()
