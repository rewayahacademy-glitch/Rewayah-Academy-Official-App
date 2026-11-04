// CHARGEMENT-bis (directeur, 04/11/2026) : la phrase de l'ouverture
// (web/index.html) n'est jamais figee et suit l'etat reel du chargement.
// Serveur LOCAL qui imite les en-tetes de Vercel (comme tool/e2e/chargement.mjs :
// Cache-Control « public, max-age=0, must-revalidate », ETag, brotli sans
// taille annoncee) ; il ralentit main.dart.js, retarde son 304, retient le
// moteur de rendu, et peut changer l'ETag (une nouvelle version publiee).
//
// Etats, a 360 et a 1280 (francais), puis a 360 en arabe :
//   1. premiere visite : « Mise a jour de l'application… » puis
//      « Installation de la nouvelle version… » (la phrase tourne) ;
//   2. code recu pendant une mise a jour : « Vous y etes presque, la mise a
//      jour est presque terminee », puis « Preparation de l'affichage… » ;
//   3. meme version (meme navigateur, meme ETag) : « Ouverture de Rewayah… »,
//      puis « Preparation de votre espace… » ;
//   4. code recu, meme version : « Preparation de l'affichage… » ;
//   5. nouvelle version (ETag change) : de nouveau « Mise a jour… ».
//
// CHARGEMENT_PHASE=avant : memes etats, captures seules (l'ancienne
// ouverture, CHARGEMENT_INDEX vers son index.html), sans controle des phrases.
// Prerequis : l'application construite dans la pile locale (TRAVAIL/web).
// Usage : CHARGEMENT_INDEX=<index.html> CHARGEMENT_PHASE=apres node tool/e2e/chargement_bis.mjs
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
import { parcours, TRAVAIL } from './commun.mjs';

const WEB = path.join(TRAVAIL, 'web');
const PHASE = process.env.CHARGEMENT_PHASE === 'avant' ? 'avant' : 'apres';
const INDEX = process.env.CHARGEMENT_INDEX ?? path.join(WEB, 'index.html');
const PORT = 8092;
const BASE = `http://127.0.0.1:${PORT}`;
const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
};

const reglage = { debit: 0, retard304: 0, retenirMoteur: false, version: 'v1' };
const moteurRetenu = [];
const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

const compresses = new Map();
function corps(fichier) {
  if (!compresses.has(fichier)) {
    const brut = fichier === 'INDEX'
      ? fs.readFileSync(INDEX, 'utf8').replace('$FLUTTER_BASE_HREF', '/')
      : fs.readFileSync(fichier);
    compresses.set(fichier, {
      br: zlib.brotliCompressSync(brut, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 5 } }),
      empreinte: crypto.createHash('md5').update(brut).digest('hex'),
    });
  }
  return compresses.get(fichier);
}

async function envoyerLentement(res, donnees) {
  const morceau = 32 * 1024;
  for (let envoye = 0; envoye < donnees.length; envoye += morceau) {
    res.write(donnees.subarray(envoye, Math.min(donnees.length, envoye + morceau)));
    if (reglage.debit > 0) await attendre(Math.round((morceau / reglage.debit) * 1000));
  }
  res.end();
}

const serveur = http.createServer(async (req, res) => {
  const u = new URL(req.url, BASE);
  let chemin = decodeURIComponent(u.pathname);
  if (chemin.endsWith('/')) chemin += 'index.html';
  let fichier = path.join(WEB, chemin);
  if (!fichier.startsWith(WEB) || !fs.existsSync(fichier) || fs.statSync(fichier).isDirectory()) {
    fichier = path.join(WEB, 'index.html');
  }
  const estIndex = fichier === path.join(WEB, 'index.html');
  const codeApp = /main\.dart\.js$/.test(fichier);
  const moteur = /canvaskit\.wasm$/.test(fichier);
  const { br, empreinte } = corps(estIndex ? 'INDEX' : fichier);
  // L'ETag de main.dart.js porte la version publiee : la changer imite un
  // nouveau deploiement.
  const etag = `"${empreinte}${codeApp ? `-${reglage.version}` : ''}"`;
  const entetes = {
    'content-type': TYPES[estIndex ? '.html' : path.extname(fichier)] ?? 'application/octet-stream',
    'cache-control': 'public, max-age=0, must-revalidate',
    etag,
  };
  const pasChange = req.headers['if-none-match'] === etag;
  const repondre = () => {
    if (pasChange) { res.writeHead(304, entetes); res.end(); return; }
    res.writeHead(200, { ...entetes, 'content-encoding': 'br' });
    res.end(br);
  };
  if (moteur && reglage.retenirMoteur) { moteurRetenu.push(repondre); return; }
  if (codeApp && pasChange) {
    await attendre(reglage.retard304);
    repondre();
    return;
  }
  if (codeApp) {
    res.writeHead(200, { ...entetes, 'content-encoding': 'br' });
    await envoyerLentement(res, br);
    return;
  }
  repondre();
});
await new Promise((r) => serveur.listen(PORT, '127.0.0.1', r));

const p = await parcours(`CHARGEMENT-bis : ouverture qui suit l'etat reel (${PHASE})`,
  `chargement-bis/2026-11-04/${PHASE}`);

function verifier(condition, message) {
  if (PHASE === 'avant') return;
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

async function lire(page) {
  return page.evaluate(() => {
    const o = document.getElementById('ouverture');
    if (!o || o.classList.contains('partie')) return { partie: true };
    return {
      partie: false,
      phrase: document.getElementById('ouverture-phrase')?.textContent ?? '',
      annonce: document.getElementById('ouverture-annonce')?.textContent ?? '',
      etat: o.getAttribute('data-etat') ?? '',
      codeFini: !!(window.__ouverture && window.__ouverture.codeFini),
      lent: o.classList.contains('lent'),
    };
  });
}

async function attendreQue(page, predicat, delai, quoi) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const e = await lire(page);
    if (predicat(e)) return e;
    await attendre(200);
  }
  throw new Error(`ROUGE : ${quoi} pas atteint en ${delai} ms`);
}

/// Releve les phrases distinctes pendant `duree` (la rotation).
async function phrasesVues(page, duree) {
  const vues = [];
  const fin = Date.now() + duree;
  while (Date.now() < fin) {
    const e = await lire(page);
    if (e.partie) break;
    if (!vues.includes(e.phrase)) vues.push(e.phrase);
    await attendre(200);
  }
  return vues;
}

async function liberer(page) {
  reglage.retenirMoteur = false;
  moteurRetenu.splice(0).forEach((f) => f());
  await attendreQue(page, (e) => e.partie, 90000, "l'application");
}

const FR = {
  miseAJour: "Mise à jour de l'application…",
  installation: 'Installation de la nouvelle version…',
  presque: 'Vous y êtes presque, la mise à jour est presque terminée',
  ouverture: 'Ouverture de Rewayah…',
  espace: 'Préparation de votre espace…',
  affichage: "Préparation de l'affichage…",
};
const AR = {
  miseAJour: 'جارٍ تحديث التطبيق…',
  installation: 'جارٍ تثبيت الإصدار الجديد…',
  presque: 'اقتربتم، التحديث على وشك الانتهاء',
  ouverture: 'جارٍ فتح Rewayah…',
  espace: 'جارٍ تجهيز مساحتكم…',
  affichage: 'جارٍ تجهيز العرض…',
};
const egal = (a, b) => a.length === b.length && a.every((x) => b.includes(x));

async function passage(largeur, langue, T) {
  const nom = `${largeur}_${langue.slice(0, 2)}`;
  p.dire(`-- ${nom}`);
  const ctx = await p.navigateur.newContext({
    viewport: { width: largeur, height: 800 }, deviceScaleFactor: 1, locale: langue,
  });
  const a = { role: nom, ctx, page: await ctx.newPage() };
  const tailleCode = corps(path.join(WEB, 'main.dart.js')).br.length;

  // 1. Premiere visite : rien de garde, code lent (environ 10 s).
  Object.assign(reglage, { debit: Math.ceil(tailleCode / 10), retard304: 0, retenirMoteur: true, version: `v1-${nom}` });
  await a.page.goto(`${BASE}/`, { waitUntil: 'commit' });
  await attendre(1200);
  let e = await lire(a.page);
  await p.capture(a, '1_premiere_visite');
  verifier(e.etat === 'nouvelle' && e.phrase === T.miseAJour, `premiere visite : « ${T.miseAJour} » (${e.phrase})`);
  let vues = await phrasesVues(a.page, 5500);
  verifier(egal(vues, [T.miseAJour, T.installation]), `premiere visite : la phrase tourne (${vues.join(' / ')})`);
  verifier((await lire(a.page)).annonce === T.miseAJour, "le lecteur d'ecran n'entend pas chaque tour");

  // 2. Code recu pendant la mise a jour (moteur retenu).
  e = await attendreQue(a.page, (x) => x.codeFini, 30000, 'code recu (premiere visite)');
  await attendre(300);
  e = await lire(a.page);
  await p.capture(a, '2_code_recu_mise_a_jour');
  verifier(e.etat === 'nouvelle-recue' && e.phrase === T.presque, `code recu, mise a jour : « ${T.presque} » (${e.phrase})`);
  vues = await phrasesVues(a.page, 5500);
  verifier(egal(vues, [T.presque, T.affichage]), `code recu, mise a jour : la phrase tourne (${vues.join(' / ')})`);
  await liberer(a.page);

  // 3. Meme version : meme navigateur, meme ETag ; le 304 tarde 8 s.
  Object.assign(reglage, { retard304: 8000, retenirMoteur: true });
  await a.page.goto(`${BASE}/`, { waitUntil: 'commit' });
  await attendre(1200);
  e = await lire(a.page);
  await p.capture(a, '3_meme_version');
  verifier(e.etat === 'meme' && e.phrase === T.ouverture, `meme version : « ${T.ouverture} » (${e.phrase})`);
  vues = await phrasesVues(a.page, 5500);
  verifier(egal(vues, [T.ouverture, T.espace]), `meme version : la phrase tourne (${vues.join(' / ')})`);

  // 4. Code recu, meme version.
  e = await attendreQue(a.page, (x) => x.codeFini, 30000, 'code recu (meme version)');
  await attendre(300);
  e = await lire(a.page);
  await p.capture(a, '4_code_recu_meme_version');
  verifier(e.etat === 'meme-recue' && e.phrase === T.affichage, `code recu, meme version : « ${T.affichage} » (${e.phrase})`);
  await liberer(a.page);

  // 5. Nouvelle version publiee : l'ETag change.
  Object.assign(reglage, { retard304: 0, retenirMoteur: true, version: `v2-${nom}` });
  await a.page.goto(`${BASE}/`, { waitUntil: 'commit' });
  await attendre(1200);
  e = await lire(a.page);
  await p.capture(a, '5_nouvelle_version');
  verifier(e.etat === 'nouvelle' && [T.miseAJour, T.installation].includes(e.phrase),
    `nouvelle version : « ${T.miseAJour} » (${e.phrase})`);
  await liberer(a.page);
  verifier(!e.lent, 'aucun « Recharger » pendant ces passages');
  await ctx.close();
}

let code = 1;
try {
  if (!fs.existsSync(path.join(WEB, 'main.dart.js'))) throw new Error(`application absente de ${WEB}`);
  p.dire(`  index servi : ${INDEX}`);
  await passage(360, 'fr-FR', FR);
  await passage(1280, 'fr-FR', FR);
  await passage(360, 'ar-SA', AR);
  code = await p.fin('vert');
} catch (err) {
  p.dire(String(err?.stack ?? err));
  code = await p.fin('rouge', String(err?.message ?? err).slice(0, 300));
} finally {
  serveur.close();
}
process.exit(code);
