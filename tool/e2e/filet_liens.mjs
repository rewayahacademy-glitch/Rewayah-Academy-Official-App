// FILET DES LIENS (06/11/2026) : un lien sans fragment arrive sur la bonne page.
//
// Sert un build web (par defaut `build/web`) comme Vercel : tout chemin sans
// fichier renvoie `index.html` (vercel.json, rewrites). Ouvre
// `/connexion?mode=creer&invitation=1` et verifie que l'adresse devient
// `/?mode=creer&invitation=1#/connexion?mode=creer&invitation=1` et que
// l'ecran de creation de compte s'affiche ; verifie aussi que la racine et un
// fichier statique ne sont pas reecrits.
//
//   flutter build web ... && node tool/e2e/filet_liens.mjs [build/web] [dossier-captures]
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');

const WEB = path.resolve(process.argv[2] ?? 'build/web');
const CAPTURES = process.argv[3];
const TYPES = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.ttf': 'font/ttf',
  '.otf': 'font/otf', '.png': 'image/png', '.svg': 'image/svg+xml',
};

const serveur = http.createServer((req, res) => {
  const chemin = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let fichier = path.join(WEB, chemin);
  if (!fichier.startsWith(WEB) || !fs.existsSync(fichier) || fs.statSync(fichier).isDirectory()) {
    fichier = path.join(WEB, 'index.html');
  }
  res.writeHead(200, { 'Content-Type': TYPES[path.extname(fichier)] ?? 'application/octet-stream' });
  fs.createReadStream(fichier).pipe(res);
});
await new Promise((r) => serveur.listen(0, '127.0.0.1', r));
const APP = `http://127.0.0.1:${serveur.address().port}`;

const echecs = [];
const verifier = (vrai, message) => { console.log(`${vrai ? 'OK  ' : 'FAUX'} ${message}`); if (!vrai) echecs.push(message); };

const navigateur = await chromium.launch();
try {
  for (const [w, h] of [[390, 844], [1440, 900]]) {
    const page = await navigateur.newPage({ viewport: { width: w, height: h }, locale: 'fr-FR' });
    await page.goto(`${APP}/connexion?mode=creer&invitation=1`);
    await page.waitForTimeout(6000);
    const adresse = new URL(page.url());
    verifier(adresse.pathname === '/', `${w} : chemin ramene a la racine (${adresse.pathname})`);
    verifier(adresse.search === '?mode=creer&invitation=1', `${w} : requete gardee a sa place (${adresse.search})`);
    verifier(adresse.hash === '#/connexion?mode=creer&invitation=1', `${w} : fragment du routeur (${adresse.hash})`);
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    await page.waitForTimeout(800);
    const creer = await page.getByText('Créer votre compte').count();
    const introuvable = await page.getByText('Cette page est introuvable').count();
    verifier(creer > 0 && introuvable === 0, `${w} : l'ecran « Créer votre compte » s'affiche`);
    if (CAPTURES) await page.screenshot({ path: path.join(CAPTURES, `06-filet-liens-connexion-${w}.png`) });
    await page.close();
  }

  const racine = await navigateur.newPage();
  // Lue avant le demarrage de Flutter (qui pose ensuite son propre fragment).
  await racine.goto(`${APP}/?demo=adulte`, { waitUntil: 'domcontentloaded' });
  const avantFlutter = await racine.evaluate(() => window.location.href);
  verifier(avantFlutter === `${APP}/?demo=adulte`, `la racine n'est pas reecrite (${avantFlutter})`);
  await racine.close();

  const fichier = await navigateur.newPage();
  const reponse = await fichier.goto(`${APP}/flutter.js`);
  verifier(reponse.ok() && fichier.url() === `${APP}/flutter.js`, 'un fichier statique n\'est pas reecrit');
  await fichier.close();
} finally {
  await navigateur.close();
  serveur.close();
}
if (echecs.length) {
  console.log(`${echecs.length} echec(s)`);
  process.exit(1);
}
console.log('Filet des liens : tout est vrai.');
