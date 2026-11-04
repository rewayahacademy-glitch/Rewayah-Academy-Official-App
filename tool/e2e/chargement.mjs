// CHARGEMENT (directeur, 03/11/2026) : l'ouverture de l'application web
// (web/index.html), sur un serveur LOCAL qui imite les en-tetes de Vercel
// releves sur l'apercu du 03/11 (Cache-Control « public, max-age=0,
// must-revalidate », ETag, compression brotli sans taille annoncee). Le
// serveur ralentit main.dart.js et peut s'arreter de l'envoyer : on prouve
// ainsi ce que dit l'ecran, sans attendre un vrai reseau lent.
//
// Prouve, a 390 (francais puis arabe) :
//   1. les phrases suivent ce qui est recu (CHARGEMENT-bis, 04/11/2026 : la
//      phrase tourne dans la liste de l'etat ; le detail des etats est prouve
//      par tool/e2e/chargement_bis.mjs) : premiere visite, « Chargement de
//      l'application… » ou « Preparation de votre espace… », puis, code recu
//      et moteur retenu, « Preparation de l'affichage… » ou « Preparation de
//      votre espace… », puis l'application ;
//   2. la barre avance avec les octets recus ;
//   3. aucun « Recharger » tant que des octets arrivent (envoi lent de plus
//      de 30 s) ;
//   4. « Recharger » apres 30 s sans aucun octet, et il repart quand les
//      octets reviennent ;
//   5. main.dart.js n'est envoye qu'une fois : la seconde demande (celle de
//      Flutter) recoit un 304 ;
//   6. mouvement reduit : la barre ne s'anime pas.
//
// Prerequis : l'application construite dans la pile locale (TRAVAIL/web).
// Usage : node tool/e2e/chargement.mjs
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import zlib from 'node:zlib';
import crypto from 'node:crypto';
import { parcours, TRAVAIL } from './commun.mjs';

const WEB = path.join(TRAVAIL, 'web');
const PORT = 8091;
const BASE = `http://127.0.0.1:${PORT}`;
const TYPES = {
  '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.ttf': 'font/ttf', '.otf': 'font/otf',
};

// Le comportement du serveur, change par chaque passage.
const reglage = { debit: 0, pauseApres: -1, pauseDuree: 0, retenirMoteur: false };
const moteurRetenu = [];
const journalCode = [];

const compresses = new Map();
function corps(fichier) {
  if (!compresses.has(fichier)) {
    const brut = fs.readFileSync(fichier);
    compresses.set(fichier, {
      br: zlib.brotliCompressSync(brut, { params: { [zlib.constants.BROTLI_PARAM_QUALITY]: 5 } }),
      etag: `"${crypto.createHash('md5').update(brut).digest('hex')}"`,
    });
  }
  return compresses.get(fichier);
}

const attendre = (ms) => new Promise((r) => setTimeout(r, ms));

async function envoyerLentement(res, donnees) {
  const morceau = 32 * 1024;
  let envoye = 0;
  let pause = reglage.pauseApres;
  while (envoye < donnees.length) {
    if (pause >= 0 && envoye >= pause) {
      pause = -1;
      await attendre(reglage.pauseDuree);
    }
    const fin = Math.min(donnees.length, envoye + morceau);
    res.write(donnees.subarray(envoye, fin));
    envoye = fin;
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
  const { br, etag } = corps(fichier);
  const entetes = {
    'content-type': TYPES[path.extname(fichier)] ?? 'application/octet-stream',
    'cache-control': 'public, max-age=0, must-revalidate',
    etag,
  };
  const codeApp = /main\.dart\.js$/.test(fichier);
  if (req.headers['if-none-match'] === etag) {
    if (codeApp) journalCode.push(304);
    res.writeHead(304, entetes);
    res.end();
    return;
  }
  if (codeApp) journalCode.push(200);
  res.writeHead(200, { ...entetes, 'content-encoding': 'br' });
  if (/canvaskit\.wasm$/.test(fichier) && reglage.retenirMoteur) {
    moteurRetenu.push(() => res.end(br));
    return;
  }
  if (codeApp) {
    await envoyerLentement(res, br);
    return;
  }
  res.end(br);
});
await new Promise((r) => serveur.listen(PORT, '127.0.0.1', r));

const p = await parcours('CHARGEMENT : ouverture de l\'application web', 'CHARGEMENT');

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

async function lire(page) {
  return page.evaluate(() => {
    const o = document.getElementById('ouverture');
    if (!o) return { partie: true };
    const barre = o.querySelector('.ouverture-barre span');
    return {
      partie: o.classList.contains('partie'),
      phrase: document.getElementById('ouverture-phrase')?.textContent ?? '',
      lent: o.classList.contains('lent'),
      barre: parseFloat(barre?.style.width || '0'),
      dir: o.dir,
      transition: getComputedStyle(barre).transitionDuration,
    };
  });
}

/// Un contexte SANS interception de requetes : Playwright coupe le cache HTTP
/// du navigateur des qu'une route est posee, et c'est precisement ce cache
/// que la preuve 5 regarde. Rien ne sort de la machine : seule la page locale
/// est ouverte (l'API est aussi locale).
async function ouvrir(langue, { mouvementReduit = false } = {}) {
  const ctx = await p.navigateur.newContext({
    viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, locale: langue,
    ignoreHTTPSErrors: true,
  });
  const page = await ctx.newPage();
  const a = { role: 'visiteur', ctx, page };
  if (mouvementReduit) await a.page.emulateMedia({ reducedMotion: 'reduce' });
  // Le cache HTTP du navigateur est neuf : chaque passage est un premier
  // chargement.
  await a.page.goto(`${BASE}/`, { waitUntil: 'commit' });
  return a;
}

/// Releve l'etat toutes les 250 ms pendant `duree`, et garde les phrases vues
/// dans l'ordre.
async function suivre(page, duree, { surChaque } = {}) {
  const vues = [];
  const fin = Date.now() + duree;
  while (Date.now() < fin) {
    const e = await lire(page);
    if (e.partie) { vues.push('(application)'); break; }
    if (vues.at(-1) !== e.phrase) vues.push(e.phrase);
    if (surChaque) await surChaque(e);
    await attendre(250);
  }
  return vues;
}

const MISE_A_JOUR = ["Chargement de l'application…", 'Préparation de votre espace…'];
const CODE_RECU = ["Préparation de l'affichage…", 'Préparation de votre espace…'];

let code = 1;
try {
  if (!fs.existsSync(path.join(WEB, 'main.dart.js'))) throw new Error(`application absente de ${WEB}`);

  // 1, 2, 5 : un envoi lent (environ 12 s pour le code), le moteur retenu.
  p.dire('-- francais, envoi lent, moteur retenu');
  journalCode.length = 0;
  Object.assign(reglage, { debit: Math.ceil(corps(path.join(WEB, 'main.dart.js')).br.length / 12), pauseApres: -1, retenirMoteur: true });
  let a = await ouvrir('fr-FR');
  await attendre(3000);
  let e = await lire(a.page);
  verifier(MISE_A_JOUR.includes(e.phrase), `phrase de depart (${e.phrase})`);
  verifier(e.barre > 0 && e.barre < 100, `la barre a avance avec les octets (${e.barre} %)`);
  await p.capture(a, '390_fr_1_chargement');
  const avant = e.barre;
  await attendre(3000);
  e = await lire(a.page);
  verifier(e.barre > avant, `la barre avance encore (${avant} % puis ${e.barre} %)`);
  let lentVu = false;
  const vues = await suivre(a.page, 25000, {
    surChaque: async (x) => { if (x.lent) lentVu = true; },
  });
  e = await lire(a.page);
  verifier(CODE_RECU.includes(e.phrase), `code recu, moteur retenu : « Preparation de l'affichage… » (${e.phrase})`);
  await p.capture(a, '390_fr_2_code_recu');
  moteurRetenu.splice(0).forEach((f) => f());
  reglage.retenirMoteur = false;
  const suite = await suivre(a.page, 60000);
  const toutes = [...vues, ...suite].filter((x, i, l) => l.indexOf(x) === i);
  p.dire(`  phrases vues : ${toutes.join(' > ')}`);
  verifier(!lentVu, 'aucun « Recharger » tant que les octets arrivent');
  const permises = [...MISE_A_JOUR, ...CODE_RECU, '(application)'];
  verifier(toutes.every((x) => permises.includes(x)), 'aucune autre phrase');
  verifier(toutes.at(-1) === '(application)', "l'application s'ouvre");
  verifier(journalCode.join(',') === '200,304', `main.dart.js envoye une fois, puis 304 (${journalCode.join(',')})`);
  await p.capture(a, '390_fr_3_application');
  await a.ctx.close();

  // 3, 4 : une pause de 40 s au milieu du code.
  p.dire('-- francais, plus aucun octet pendant 40 s');
  Object.assign(reglage, { debit: 400 * 1024, pauseApres: 256 * 1024, pauseDuree: 40000, retenirMoteur: false });
  a = await ouvrir('fr-FR');
  await attendre(20000);
  e = await lire(a.page);
  verifier(!e.lent, 'a 20 s sans octet : pas encore de « Recharger »');
  await attendre(13000);
  e = await lire(a.page);
  verifier(e.lent, 'apres 30 s sans octet : « Recharger » et sa phrase');
  await p.capture(a, '390_fr_4_plus_rien_recharger');
  await attendre(9000);
  e = await lire(a.page);
  verifier(e.partie || !e.lent, 'les octets reviennent : « Recharger » repart');
  await a.ctx.close();

  // L'arabe, et le mouvement reduit.
  p.dire('-- arabe, envoi lent, mouvement reduit');
  Object.assign(reglage, { debit: Math.ceil(corps(path.join(WEB, 'main.dart.js')).br.length / 8), pauseApres: -1, retenirMoteur: false });
  a = await ouvrir('ar-SA', { mouvementReduit: true });
  await attendre(2500);
  e = await lire(a.page);
  verifier(e.dir === 'rtl' && ['جارٍ تحميل التطبيق…', 'جارٍ تجهيز مساحتكم…'].includes(e.phrase),
    `arabe, de droite a gauche (${e.phrase})`);
  verifier(e.transition === '0s', `mouvement reduit : la barre ne s'anime pas (${e.transition})`);
  await p.capture(a, '390_ar_5_chargement');
  await a.ctx.close();

  code = await p.fin('vert');
} catch (err) {
  p.dire(String(err?.stack ?? err));
  code = await p.fin('rouge', String(err?.message ?? err).slice(0, 300));
} finally {
  serveur.close();
}
process.exit(code);
