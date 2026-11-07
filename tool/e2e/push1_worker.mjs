// PUSH-1 (07/11/2026) : robot du worker push (web/push_worker.js) dans un vrai
// Chromium (Playwright, channel « chromium », notifications accordees).
//
// Ce qu'il prouve : le worker s'enregistre ; un push livre par le protocole
// DevTools (ServiceWorker.deliverPushMessage, la charge en clair que le
// navigateur remet apres dechiffrement) s'affiche avec son titre et son texte ;
// deux push de meme etiquette donnent UNE alerte ; la destination est gardee
// pour le toucher ; une adresse hors application est ramenee a « / ».
//
// Ce qu'il NE prouve PAS : l'abonnement a un vrai service de push (le Chromium
// libre de ce banc n'a pas d'acces au service de Google : `subscribe` echoue),
// ni le chiffrement de bout en bout (prouve a part par les tests Deno, vecteur
// RFC 8291), ni l'ouverture de la page au toucher.
//
// Usage (depuis /opt/node-tools, ou Playwright est installe) :
//   mkdir -p /tmp/p/icons && cp web/push_worker.js web/push_client.js /tmp/p/ \
//     && cp web/icons/Icon-192.png web/icons/Icon-maskable-192.png /tmp/p/icons/ \
//     && printf '<!doctype html><script src="push_client.js"></script>' > /tmp/p/index.html
//   node <depot>/tool/e2e/push1_worker.mjs /tmp/p
import { chromium } from 'playwright';
import http from 'node:http'; import fs from 'node:fs'; import path from 'node:path';
const dir = process.argv[2];
const srv = http.createServer((q,r)=>{const u=q.url.split('?')[0];const f=path.join(dir,u==='/'?'/index.html':u); if(!fs.existsSync(f)){r.writeHead(404);return r.end();} r.writeHead(200,{'content-type':f.endsWith('.js')?'text/javascript':f.endsWith('.png')?'image/png':'text/html'}); r.end(fs.readFileSync(f));}).listen(8768);
const ok = (c, l) => { console.log((c ? 'OK ' : 'ROUGE ') + l); if (!c) process.exitCode = 1; };
const b = await chromium.launch({ channel: 'chromium' }); const ctx = await b.newContext(); await ctx.grantPermissions(['notifications'], { origin: 'http://localhost:8768' });
const p = await ctx.newPage(); await p.goto('http://localhost:8768/');
console.log('permission page :', await p.evaluate(() => Notification.permission));
await p.evaluate(async () => { await navigator.serviceWorker.register('push_worker.js', { scope: './' }); await navigator.serviceWorker.ready; });
const cdp = await ctx.newCDPSession(p);
let reg = null; cdp.on('ServiceWorker.workerRegistrationUpdated', (e) => { for (const r of e.registrations) if (!r.isDeleted) reg = r; });
await cdp.send('ServiceWorker.enable'); for (let i = 0; i < 20 && !reg; i++) await new Promise(r => setTimeout(r, 200));
ok(!!reg, 'worker enregistre');
const lire = () => p.evaluate(async () => (await (await navigator.serviceWorker.ready).getNotifications()).map(n => ({ t: n.title, b: n.body, tag: n.tag, d: n.data && n.data.destination })));
const charge = JSON.stringify({ titre: 'Rewayah Academy', texte: '3 nouvelles candidatures à examiner.', destination: '/admin/personnes/candidatures', tag: 'candidatures' });
for (let i = 0; i < 2; i++) await cdp.send('ServiceWorker.deliverPushMessage', { origin: 'http://localhost:8768', registrationId: reg.registrationId, data: charge });
await new Promise(r => setTimeout(r, 1200));
const n1 = await lire(); console.log(JSON.stringify(n1));
ok(n1.length === 1, 'deux push de meme etiquette : une seule alerte');
ok(n1[0] && n1[0].t === 'Rewayah Academy' && n1[0].b.startsWith('3 nouvelles') && n1[0].tag === 'candidatures', 'titre, texte et etiquette de la charge');
ok(n1[0] && n1[0].d === '/admin/personnes/candidatures', 'destination gardee pour le toucher');
await cdp.send('ServiceWorker.deliverPushMessage', { origin: 'http://localhost:8768', registrationId: reg.registrationId, data: JSON.stringify({ texte: 'x', destination: 'https://ailleurs.example/piege' }) });
await new Promise(r => setTimeout(r, 1000));
const n2 = await lire(); console.log(JSON.stringify(n2));
ok(n2.some(n => n.d === '/') && !n2.some(n => (n.d || '').startsWith('http')), 'destination hors application ramenee a « / », titre par defaut ' + JSON.stringify(n2.find(n=>n.d==='/')?.t));
await b.close(); srv.close();
