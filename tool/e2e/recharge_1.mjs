// Lot RECHARGE-1 (03/11/2026) : un ecran charge a la demande (morceau
// `main.dart.js_N.part.js`) qui ne s'ouvre pas, sur la pile LOCALE seulement
// (jamais un apercu Vercel, jamais la production : G5).
//
// Trois scenarios, chacun dans un navigateur neuf, sur l'ecran « Planning » de
// la direction (morceau `d_planning_page`) :
//   deploiement : la page tourne sur la build A ; le serveur passe a la build B
//                 (un deploiement) ; la direction ouvre le planning : les
//                 morceaux servis sont ceux de B ;
//   morceau     : le morceau est bloque (page.route), puis debloque ;
//   reseau      : le reseau est coupe (navigateur hors ligne), puis retabli.
//
// Le serveur est celui de ce robot (il bascule de A a B), sur le port 8092 ;
// il renvoie index.html pour un fichier absent, comme la reecriture de Vercel
// (vercel.json : « /(.*) » vers « /index.html »).
//
// Usage : E2E_APP=http://127.0.0.1:8092 BUILD_A=<dossier> BUILD_B=<dossier>
//         PHASE=avant|apres VUE=1440x900 node tool/e2e/recharge_1.mjs
import crypto from 'node:crypto';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, trouverTexte, libelles, activerSemantique, amenerEnVue,
  COMPTES } from './commun.mjs';

const [largeur, hauteur] = (process.env.VUE ?? '1440x900').split('x').map(Number);
const phase = process.env.PHASE ?? 'apres';
const A = path.resolve(process.env.BUILD_A);
const B = path.resolve(process.env.BUILD_B);
const port = Number(new URL(process.env.E2E_APP ?? 'http://127.0.0.1:8092').port);
const p = await parcours(`RECHARGE-1 (${phase}) : ecran charge a la demande (${largeur} x ${hauteur})`,
  `recharge-1/${phase}/${largeur}`);
const verdicts = {};
const lus = async (page, k = 40) => (await libelles(page)).slice(0, k).join(' | ');

// Le serveur, qui peut changer de build en cours de route.
let racine = A;
const servis = [];
const lectures = [];
const types = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.wasm': 'application/wasm', '.json': 'application/json', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf', '.css': 'text/css',
  '.webp': 'image/webp', '.jpg': 'image/jpeg' };
const serveur = http.createServer((req, res) => {
  const chemin = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  let f = path.join(racine, chemin === '/' ? 'index.html' : chemin);
  if (!f.startsWith(racine)) { res.writeHead(403); res.end(); return; }
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(racine, 'index.html');
  if (/version\.json$|main\.dart\.js$/.test(chemin)) lectures.push(`${req.method} ${path.basename(racine)}:${chemin}`);
  if (/part\.js$/.test(chemin)) servis.push(`${path.basename(racine)}:${path.basename(chemin)}->${path.basename(f)}`);
  // Un ETag par contenu, comme Vercel : le bandeau « nouvelle version »
  // compare celui de main.dart.js.
  const etag = `"${crypto.createHash('md5').update(fs.readFileSync(f)).digest('hex')}"`;
  res.writeHead(200, { 'content-type': types[path.extname(f)] ?? 'application/octet-stream',
    'cache-control': 'no-store', etag });
  fs.createReadStream(f).pipe(res);
});
await new Promise((ok) => serveur.listen(port, '127.0.0.1', ok));

const PLANNING = '/admin/operations/planning';
const ECHEC = /hors ligne|nouvelle version|n'a pas pu s'ouvrir|Rechargez|Impossible de charger/i;
const PLANNING_OUVERT = /Cette semaine|Semaine du|Aucune séance|semaine/i;

async function aller(page, route) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, route);
  await page.waitForTimeout(6000);
  await activerSemantique(page);
}

async function entrer(nom) {
  const c = await p.contexte(nom, { vue: { width: largeur, height: hauteur } });
  await connecter(c.page, COMPTES.direction);
  await c.page.waitForTimeout(4000);
  await activerSemantique(c.page);
  return c;
}

/// Touche le bouton d'action de l'etat d'echec, quel qu'il soit, et dit ce
/// qui suit.
async function toucherAction(c, etiquette) {
  const b = await trouver(c.page, /^(Réessayer|Recharger)$/, { delai: 5000 });
  const libelle = b ? ((await b.getAttribute('aria-label')) ?? (await b.textContent())) : null;
  p.dire(`${etiquette} : bouton ${libelle ?? 'absent'}`);
  if (!b) return null;
  await amenerEnVue(c.page, b);
  await b.click();
  await c.page.waitForTimeout(8000);
  await activerSemantique(c.page);
  return libelle;
}

let code = 1;
try {
  // 1. Deploiement : A a l'ouverture, B quand le planning s'ouvre.
  {
    racine = A;
    const c = await entrer('deploiement');
    racine = B;
    servis.length = 0;
    // Le bandeau FN-013 relit la version au retour au premier plan : un
    // autre onglet, puis celui-ci.
    // Le navigateur sans ecran ne masque jamais l'onglet : on le dit au
    // document (visibilitychange et focus), comme un navigateur le ferait.
    for (const etat of ['hidden', 'visible']) {
      await c.page.evaluate((e) => {
        Object.defineProperty(document, 'visibilityState', { value: e, configurable: true });
        Object.defineProperty(document, 'hidden', { value: e === 'hidden', configurable: true });
        document.dispatchEvent(new Event('visibilitychange'));
        window.dispatchEvent(new Event(e === 'hidden' ? 'blur' : 'focus'));
      }, etat);
      await c.page.waitForTimeout(1500);
    }
    await c.page.waitForTimeout(3000);
    await aller(c.page, PLANNING);
    const tous = (await libelles(c.page)).join(' | ');
    // Le bandeau (en tete) et l'ecran disent la meme phrase : deux fois.
    verdicts.bandeauNouvelleVersion = (tous.match(/Une nouvelle version de l'application est prête/g) ?? []).length >= 2;
    p.dire(`Deploiement, bandeau FN-013 : ${verdicts.bandeauNouvelleVersion ? 'present' : 'absent'} ; lectures de version : ${lectures.join(', ')}`);
    const ecran = await lus(c.page);
    p.dire(`Deploiement, planning ouvert sur la build B : ${ecran}`);
    p.dire(`Morceaux servis : ${servis.join(', ') || 'aucun'}`);
    await p.capture(c, 'deploiement_echec');
    verdicts.deploiementEchoue = ECHEC.test(ecran);
    verdicts.deploiementDitHorsLigne = /hors ligne/i.test(ecran);
    const action = await toucherAction(c, 'Deploiement');
    const apres = await lus(c.page);
    p.dire(`Deploiement, apres ${action ?? 'aucune action'} : ${apres}`);
    await p.capture(c, 'deploiement_apres_action');
    verdicts.deploiementRevient = !ECHEC.test(apres) && PLANNING_OUVERT.test(apres);
    verdicts.deploiementAction = action;
    await c.ctx.close();
  }

  // 2. Morceau bloque puis debloque.
  {
    racine = A;
    const c = await entrer('morceau');
    const bloquer = (r) => r.abort();
    await c.page.route('**/*.part.js*', bloquer);
    await aller(c.page, PLANNING);
    const ecran = await lus(c.page);
    p.dire(`Morceau bloque : ${ecran}`);
    await p.capture(c, 'morceau_bloque');
    verdicts.morceauEchoue = ECHEC.test(ecran);
    verdicts.morceauDitHorsLigne = /hors ligne/i.test(ecran);
    await c.page.unroute('**/*.part.js*', bloquer);
    const action = await toucherAction(c, 'Morceau debloque');
    const apres = await lus(c.page);
    p.dire(`Morceau debloque, apres ${action ?? 'aucune action'} : ${apres}`);
    await p.capture(c, 'morceau_debloque');
    verdicts.morceauRevient = !ECHEC.test(apres) && PLANNING_OUVERT.test(apres);
    await c.ctx.close();
  }

  // 3. Reseau coupe puis retabli : l'ecran doit revenir sans geste.
  {
    racine = A;
    const c = await entrer('reseau');
    await c.ctx.setOffline(true);
    await aller(c.page, PLANNING);
    const ecran = await lus(c.page);
    p.dire(`Reseau coupe : ${ecran}`);
    await p.capture(c, 'reseau_coupe');
    verdicts.reseauEchoue = ECHEC.test(ecran);
    await c.ctx.setOffline(false);
    const revenu = await trouverTexte(c.page, PLANNING_OUVERT, 20000);
    await activerSemantique(c.page);
    const apres = await lus(c.page);
    p.dire(`Reseau retabli, sans geste : ${apres}`);
    await p.capture(c, 'reseau_retabli');
    verdicts.reseauRevientSeul = !!revenu && !ECHEC.test(apres);
    await c.ctx.close();
  }

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  // Avant le correctif, le robot CONSTATE (verdict « joue ») ; apres, il exige.
  const ok = verdicts.deploiementRevient && !verdicts.deploiementDitHorsLigne
    && verdicts.bandeauNouvelleVersion
    && verdicts.morceauRevient && !verdicts.morceauDitHorsLigne && verdicts.reseauRevientSeul;
  code = await p.fin(phase === 'avant' ? 'joué' : (ok ? 'vert' : 'rouge'),
    ok ? '' : JSON.stringify(verdicts));
} catch (e) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(e).slice(0, 400));
}
serveur.close();
process.exit(phase === 'avant' ? 0 : code);
