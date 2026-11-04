// Relais HTTPS local devant l'API Supabase locale (http://127.0.0.1:54321).
// L'application refuse une SUPABASE_URL qui n'est pas en https (Env.configuree) ;
// le navigateur de test accepte le certificat auto-signe (ignoreHTTPSErrors).
// Requetes ordinaires et WebSocket (Realtime) sont relayes tels quels.
// Usage : node relais_https.mjs <cert.pem> <cle.pem> <port https> [cible]
import https from 'node:https';
import http from 'node:http';
import net from 'node:net';
import fs from 'node:fs';

const [cert, cle, port, cible = 'http://127.0.0.1:54321'] = process.argv.slice(2);
const c = new URL(cible);
const serveur = https.createServer({ cert: fs.readFileSync(cert), key: fs.readFileSync(cle) },
  (req, res) => {
    const amont = http.request({ host: c.hostname, port: c.port, method: req.method,
      path: req.url, headers: { ...req.headers, host: c.host } }, (r) => {
      res.writeHead(r.statusCode, r.headers);
      r.pipe(res);
    });
    amont.on('error', () => { res.writeHead(502); res.end(); });
    req.pipe(amont);
  });
serveur.on('upgrade', (req, socket, tete) => {
  const amont = net.connect(Number(c.port), c.hostname, () => {
    const entetes = Object.entries({ ...req.headers, host: c.host })
      .map(([k, v]) => `${k}: ${v}`).join('\r\n');
    amont.write(`${req.method} ${req.url} HTTP/1.1\r\n${entetes}\r\n\r\n`);
    if (tete?.length) amont.write(tete);
    amont.pipe(socket); socket.pipe(amont);
  });
  amont.on('error', () => socket.destroy());
  socket.on('error', () => amont.destroy());
});
serveur.listen(Number(port), '127.0.0.1', () => console.log(`https://127.0.0.1:${port} -> ${cible}`));
