// CAMERA-JUMELAGE (12/11/2026) : le flux de la camera du lecteur de QR est-il
// ferme quand on quitte l'ecran du scanner ?
//
// Sans pile Supabase : l'ecran /connexion/eleve/scanner est public. On
// enveloppe getUserMedia AVANT le chargement pour garder chaque flux rendu,
// on attend que la camera tourne, on quitte l'ecran comme une personne
// (« Saisir le code »), puis on lit l'etat de chaque piste.
//
// Usage :
//   node tool/e2e/camera_jumelage_flux.mjs <dossier build/web> [port]
// Construction : une cle publiable plausible suffit, aucun serveur n'est joint
// sur cet ecran (une cle contenant « factice » ouvre l'ecran « Configuration
// absente ») :
//   flutter build web --release -O1 --no-wasm-dry-run \
//     --dart-define=SUPABASE_URL=https://127.0.0.1:9 \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_essaiLocalSansServeur000000
// Sortie : une ligne JSON par mesure ; code 0 si toutes les pistes du lecteur
// sont « ended » apres la sortie et le temoin encore « live », 1 si une piste
// du lecteur reste ouverte (defaut reproduit), 2 si aucun flux, 3 si le
// temoin a ete ferme.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
let playwright;
try {
  playwright = require('playwright');
} catch {
  playwright = createRequire('/opt/node-tools/node_modules/')('playwright');
}
const { chromium } = playwright;

const racine = path.resolve(process.argv[2] ?? 'build/web');
const port = Number(process.argv[3] ?? 8097);
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf',
  '.otf': 'font/otf', '.woff2': 'font/woff2', '.ico': 'image/x-icon',
};

// Serveur statique a page unique : toute route inconnue rend index.html.
const serveur = http.createServer((req, res) => {
  const url = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let fichier = path.join(racine, url);
  if (!fichier.startsWith(racine) || !fs.existsSync(fichier) ||
      fs.statSync(fichier).isDirectory()) {
    fichier = path.join(racine, 'index.html');
  }
  res.writeHead(200, {
    'Content-Type': types[path.extname(fichier)] ?? 'application/octet-stream',
  });
  fs.createReadStream(fichier).pipe(res);
});
await new Promise((ok) => serveur.listen(port, '127.0.0.1', ok));

const navigateur = await chromium.launch({
  args: ['--use-fake-device-for-media-stream', '--use-fake-ui-for-media-stream'],
});
let code = 0;
try {
  const contexte = await navigateur.newContext({
    viewport: { width: 390, height: 844 },
    permissions: ['camera'],
  });
  const page = await contexte.newPage();
  page.on('pageerror', (e) => console.error('pageerror', e.message));
  // Temoin : au premier appel du lecteur, un AUTRE flux (comme la visio de
  // la salle reduite) est attache a un <video> ordinaire pendant le
  // demarrage du lecteur. Il ne doit jamais etre ferme par la correction.
  await page.addInitScript(() => {
    window.__flux = [];
    window.__temoin = null;
    const md = navigator.mediaDevices;
    const origine = md.getUserMedia.bind(md);
    md.getUserMedia = async (c) => {
      if (!window.__temoin) {
        const t = await origine({ video: true });
        const v = document.createElement('video');
        v.muted = true;
        v.srcObject = t;
        window.__temoin = t;
      }
      const s = await origine(c);
      window.__flux.push(s);
      return s;
    };
  });
  const etats = () => page.evaluate(() =>
    window.__flux.map((s) => s.getTracks().map((t) => t.readyState)));
  const temoin = () => page.evaluate(() =>
    window.__temoin ? window.__temoin.getTracks().map((t) => t.readyState) : null);

  await page.goto(`http://127.0.0.1:${port}/connexion/eleve/scanner`);
  await page.waitForFunction(
    () => window.__flux?.some((s) => s.getTracks().some((t) => t.readyState === 'live')),
    null, { timeout: 90000 });
  await page.waitForTimeout(1500);
  console.log(JSON.stringify({ mesure: 'camera ouverte', url: page.url(), pistes: await etats(), temoin: await temoin() }));

  // Pause puis reprise (onglet cache puis revenu) : l'ecran arrete la camera
  // puis la redemarre ; un flux neuf doit s'ouvrir.
  const visibilite = (etat) => page.evaluate((e) => {
    Object.defineProperty(document, 'visibilityState', { configurable: true, get: () => e });
    Object.defineProperty(document, 'hidden', { configurable: true, get: () => e === 'hidden' });
    document.dispatchEvent(new Event('visibilitychange'));
  }, etat);
  await visibilite('hidden');
  await page.waitForTimeout(2000);
  console.log(JSON.stringify({ mesure: 'onglet cache', pistes: await etats() }));
  await visibilite('visible');
  await page.waitForFunction((n) => window.__flux.length > n &&
    window.__flux[window.__flux.length - 1].getTracks().every((t) => t.readyState === 'live'),
  (await etats()).length, { timeout: 30000 });
  await page.waitForTimeout(1500);
  const repris = await etats();
  console.log(JSON.stringify({ mesure: 'onglet revenu', pistes: repris }));

  // Quitter l'ecran comme une personne : le bouton « Saisir le code »
  // (l'arbre d'accessibilite de Flutter est active d'abord).
  await page.evaluate(() => {
    const b = document.querySelector('flt-semantics-placeholder');
    if (b) b.click();
  });
  await page.getByRole('button', { name: 'Saisir le code' }).click({ timeout: 30000 });
  await page.waitForURL(/\/connexion\/eleve\/code/, { timeout: 30000 });
  await page.waitForTimeout(2000);
  const apres = await etats();
  console.log(JSON.stringify({ mesure: 'apres sortie', url: page.url(), pistes: apres, temoin: await temoin() }));

  const toutes = apres.flat();
  if (toutes.length === 0) code = 2;
  else if (toutes.some((e) => e !== 'ended')) code = 1;
  if ((await temoin())?.some((e) => e !== 'live')) {
    console.log('ECHEC : le flux temoin (hors lecteur) a ete ferme');
    code = 3;
  }
} finally {
  await navigateur.close();
  serveur.close();
}
process.exit(code);
