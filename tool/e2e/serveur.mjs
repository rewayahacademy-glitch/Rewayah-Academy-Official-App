// Sert la construction web de l'application (build/web) sur 127.0.0.1.
// Usage : node serveur.mjs <dossier web> <port>
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const racine = path.resolve(process.argv[2]);
const port = Number(process.argv[3] ?? 8090);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf', '.css': 'text/css',
  '.webp': 'image/webp', '.jpg': 'image/jpeg' };
http.createServer((req, res) => {
  const p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let f = path.join(racine, p === '/' ? 'index.html' : p);
  if (!f.startsWith(racine)) { res.writeHead(403); res.end(); return; }
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(racine, 'index.html');
  res.writeHead(200, { 'content-type': types[path.extname(f)] ?? 'application/octet-stream',
    'cache-control': 'no-store' });
  fs.createReadStream(f).pipe(res);
}).listen(port, '127.0.0.1', () => console.log(`http://127.0.0.1:${port}`));
