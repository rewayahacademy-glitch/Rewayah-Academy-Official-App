// Outils communs des parcours de bout en bout (Flutter web + Playwright).
// Flutter dessine sur un canevas : on agit par l'arbre d'accessibilite
// (flt-semantics), active des l'ouverture de chaque page.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { createRequire } from 'node:module';

const require = createRequire('/opt/node-tools/node_modules/');
const { chromium } = require('playwright');

export const APP = process.env.E2E_APP ?? 'http://127.0.0.1:8090';
export const MDP = process.env.E2E_MOT_DE_PASSE ?? 'E2E-motdepasse-2026';
export const TRAVAIL = process.env.E2E_TRAVAIL ?? '/tmp/e2e-pile';
export const DEPOT = path.resolve(new URL('../..', import.meta.url).pathname);
const WEB = path.join(TRAVAIL, 'web');

export const COMPTES = {
  direction: 'e2e-direction@example.com',
  enseignant: 'e2e-enseignant@example.com',
};

const statut = Object.fromEntries(
  fs.readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8').split('\n')
    .filter((l) => l.includes('=')).map((l) => {
      const i = l.indexOf('=');
      return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
    }));
export const API = statut.API_URL;
export const DB = statut.DB_URL;
export const MAILPIT = statut.MAILPIT_URL ?? statut.INBUCKET_URL;
if (!/^http:\/\/127\.0\.0\.1:/.test(API) || !/@127\.0\.0\.1:/.test(DB)) {
  throw new Error(`refus : pile non locale (${API})`);
}

/// Requete SQL sur la base LOCALE (lecture ou amorce), resultat brut.
export function sql(requete) {
  return execFileSync('psql', [DB, '-Atc', requete], { encoding: 'utf8' }).trim();
}

const TYPES = { '.js': 'text/javascript', '.wasm': 'application/wasm', '.mjs': 'text/javascript' };

/// Un parcours : un navigateur, un contexte par role, des captures numerotees,
/// un journal d'etapes. `fin()` ecrit le verdict et rend le code de sortie.
export async function parcours(nom, dossierCaptures) {
  const sortie = path.join(DEPOT, 'docs/current/captures/E2E', dossierCaptures);
  // On ne retire que les captures et le journal du passage precedent : les
  // fichiers ecrits a la main (pieges.md) restent.
  fs.mkdirSync(sortie, { recursive: true });
  for (const f of fs.readdirSync(sortie)) {
    if (/\.png$|^journal\.txt$|^verdict\.json$/.test(f)) fs.rmSync(path.join(sortie, f));
  }
  const navigateur = await chromium.launch({
    args: ['--use-fake-ui-for-media-stream', '--use-fake-device-for-media-stream',
      '--autoplay-policy=no-user-gesture-required'],
  });
  let n = 0;
  const journal = [];
  const debut = new Date();
  const dire = (m) => { console.log(m); journal.push(m); };
  dire(`== ${nom} : ${debut.toISOString()} ; Chromium ${navigateur.version()} ; ${APP}`);

  // `vue` (L1 des listes, 01/11/2026) : une taille d'ecran precise (1440 x
  // 900) ; `sombre` : le theme sombre du systeme. Sans eux, comme avant.
  async function contexte(role, { telephone = false, vue = null, sombre = false } = {}) {
    const ctx = await navigateur.newContext({
      viewport: vue ?? (telephone ? { width: 390, height: 780 } : { width: 1200, height: 760 }),
      colorScheme: sombre ? 'dark' : 'light',
      deviceScaleFactor: 1,
      locale: 'fr-FR',
      timezoneId: 'Europe/Paris',
      permissions: ['camera', 'microphone'],
      ignoreHTTPSErrors: true, // relais https local auto-signe
    });
    await ctx.route('**/*', (route) => {
      const u = new URL(route.request().url());
      if (u.host === 'www.gstatic.com' && u.pathname.startsWith('/flutter-canvaskit/')) {
        const f = path.join(WEB, 'canvaskit', u.pathname.split('/').slice(3).join('/'));
        if (fs.existsSync(f)) return route.fulfill({ path: f, contentType: TYPES[path.extname(f)] });
        return route.abort();
      }
      // Les fonctions Edge locales signent des URL sur l'adresse interne de la
      // pile (http://kong:8000) ; en production c'est l'URL publique. On la
      // ramene sur l'API locale.
      if (u.hostname === 'kong') {
        return route.continue({ url: u.href.replace(`${u.protocol}//${u.host}`, API) });
      }
      if (u.hostname === '127.0.0.1' || u.hostname === 'localhost' || /^172\.\d+\.\d+\.\d+$/.test(u.hostname)) {
        return route.continue();
      }
      // Polices de repli de Flutter (fonts.gstatic.com) : lecture seule, sans donnees.
      if (u.host === 'fonts.gstatic.com' || u.host === 'fonts.googleapis.com') return route.continue();
      if (u.protocol === 'data:' || u.protocol === 'blob:') return route.continue();
      return route.abort();
    });
    const page = await ctx.newPage();
    page.on('requestfailed', (r) => { if (process.env.E2E_DEBUG) dire(`  [${role}] echec reseau : ${r.url().slice(0, 160)}`); });
    page.on('pageerror', (e) => dire(`  [${role}] erreur de page : ${String(e).slice(0, 300)}`));
    page.on('console', (m) => {
      if (m.type() === 'error' && !m.text().startsWith('Failed to load resource')) dire(`  [${role}] console : ${m.text().slice(0, 300)}`);
    });
    return { role, ctx, page };
  }

  async function capture(acteur, etiquette) {
    n += 1;
    const f = path.join(sortie, `${String(n).padStart(2, '0')}_${acteur.role}_${etiquette}.png`);
    await acteur.page.screenshot({ path: f });
    return f;
  }

  async function fin(verdict, cause = '') {
    const ligne = `${verdict}${cause ? ` : ${cause}` : ''}`;
    dire(`== ${nom} : ${ligne}`);
    fs.writeFileSync(path.join(sortie, 'journal.txt'), journal.join('\n') + '\n');
    fs.writeFileSync(path.join(sortie, 'verdict.json'), JSON.stringify({
      parcours: nom, verdict, cause, debut: debut.toISOString(), fin: new Date().toISOString(),
    }, null, 2));
    await navigateur.close();
    alleger(sortie);
    return verdict === 'vert' ? 0 : 1;
  }

  return { navigateur, contexte, capture, fin, dire, sortie };
}

/// Ouvre l'application et allume l'arbre d'accessibilite.
export async function ouvrir(page, chemin = '/') {
  await page.goto(APP + chemin);
  await page.waitForSelector('flt-semantics-placeholder, flt-semantics', { state: 'attached', timeout: 60000 });
  await page.waitForTimeout(4000);
  await activerSemantique(page);
}

export async function activerSemantique(page) {
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(700);
}

/// Les libelles visibles dans l'arbre (diagnostic).
export async function libelles(page) {
  return page.evaluate(() => {
    const vus = [];
    for (const e of document.querySelectorAll('flt-semantics, [aria-label], a, h1, h2, h3, h4, h5, h6, input, textarea')) {
      if (e.tagName === 'FLT-SEMANTICS-PLACEHOLDER') continue;
      const r = e.getAttribute('role') ?? e.tagName.toLowerCase();
      let t = (e.getAttribute('aria-label') ?? '').trim();
      if (!t) {
        // Texte propre au noeud (y compris ses <span>), sans celui des noeuds enfants.
        t = [...e.childNodes].filter((c) => c.nodeType === 3 || (c.nodeType === 1 && c.tagName !== 'FLT-SEMANTICS' && c.tagName !== 'FLT-SEMANTICS-CONTAINER'))
          .map((c) => c.textContent).join(' ').trim();
      }
      if (t) vus.push(`${r}:${t.replace(/[\u2068\u2069]/g, '').replace(/\s+/g, ' ').slice(0, 160)}`);
    }
    return vus;
  });
}

function echapper(s) { return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }

/// Le premier element visible portant ce nom (bouton, lien, onglet, case...).
export async function trouver(page, nom, { delai = 20000, exact = false, role } = {}) {
  const motif = typeof nom === 'string'
    ? new RegExp(exact ? `^\\s*${echapper(nom)}\\s*$` : echapper(nom), 'i') : nom;
  const roles = role ? [role] : ['button', 'link', 'tab', 'menuitem', 'checkbox', 'radio', 'switch', 'option', 'textbox', 'combobox'];
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    for (const r of roles) {
      const l = page.getByRole(r, { name: motif });
      const k = await l.count();
      for (let i = 0; i < k; i++) {
        if (await l.nth(i).isVisible().catch(() => false)) return l.nth(i);
      }
    }
    // Les liens de Flutter sont des <a> sans href (aucun role « link » implicite).
    if (!role || role === 'link') {
      const ancres = page.locator('a[aria-label]');
      const k = await ancres.count();
      for (let i = 0; i < k; i++) {
        const nomA = ((await ancres.nth(i).getAttribute('aria-label')) ?? '').replace(/[\u2068\u2069]/g, '').replace(/\s+/g, ' ').trim();
        if (motif.test(nomA) && await ancres.nth(i).isVisible().catch(() => false)) return ancres.nth(i);
      }
    }
    if (!role) {
      // Repli : le noeud le plus profond qui porte le texte (jamais un conteneur).
      const l = page.locator('flt-semantics').filter({ hasText: motif })
        .filter({ hasNot: page.locator('flt-semantics').filter({ hasText: motif }) });
      const k = await l.count();
      for (let i = k - 1; i >= 0; i--) {
        if (await l.nth(i).isVisible().catch(() => false)) return l.nth(i);
      }
    }
    await page.waitForTimeout(400);
  }
  return null;
}

/// Fait defiler la page (molette, comme un utilisateur) jusqu'a ce que
/// l'element soit dans la fenetre : un noeud hors ecran recoit sinon le clic
/// a la place d'un autre.
export async function amenerEnVue(page, e) {
  const vue = page.viewportSize();
  for (let i = 0; i < 30; i++) {
    const b = await e.boundingBox();
    if (!b) return;
    const centre = b.y + Math.min(b.height, 48) / 2;
    if (centre > 8 && centre < vue.height - 8) return;
    await page.mouse.move(vue.width * 0.6, vue.height / 2);
    await page.mouse.wheel(0, centre < 0 ? -300 : 300);
    await page.waitForTimeout(350);
  }
}

export async function cliquer(page, nom, options = {}) {
  const e = await trouver(page, nom, options);
  if (!e) {
    const vus = await libelles(page);
    throw new Error(`introuvable : « ${nom} » ; visibles : ${vus.slice(0, 60).join(' | ')}`);
  }
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(options.pause ?? 900);
}

/// Saisit dans le champ dont le nom accessible contient `nom`.
export async function saisir(page, nom, valeur, { delai = 20000 } = {}) {
  const fin = Date.now() + delai;
  const motif = new RegExp(echapper(nom), 'i');
  while (Date.now() < fin) {
    const l = page.getByRole('textbox', { name: motif });
    if (await l.count()) {
      const e = l.first();
      await e.click();
      await page.waitForTimeout(250);
      await page.keyboard.press('Control+A');
      await page.keyboard.type(valeur, { delay: 15 });
      await page.waitForTimeout(300);
      return;
    }
    await page.waitForTimeout(400);
  }
  const vus = await libelles(page);
  throw new Error(`champ introuvable : « ${nom} » ; visibles : ${vus.slice(0, 60).join(' | ')}`);
}

export async function attendreTexte(page, texte, delai = 30000) {
  return (await trouverTexte(page, texte, delai)) !== null;
}

export async function trouverTexte(page, texte, delai = 30000) {
  const motif = typeof texte === 'string' ? new RegExp(echapper(texte), 'i') : texte;
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const t = (await libelles(page)).find((x) => motif.test(x));
    if (t) return t;
    // Repli : tout le texte du document (certains textes de Flutter ne sont
    // pas rattaches a un noeud d'accessibilite lisible).
    const brut = await page.evaluate(() => document.body.innerHTML
      .replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, '\n')
      .replace(/&nbsp;/g, ' ').replace(/[\u2068\u2069\u00a0]/g, ' '));
    const ligne = brut.split('\n').map((x) => x.trim()).find((x) => x && motif.test(x));
    if (ligne) return `texte:${ligne.slice(0, 140)}`;
    await page.waitForTimeout(500);
  }
  return null;
}

/// Tape dans un champ designe par un selecteur CSS (les champs de Flutter
/// n'ont pas toujours de nom accessible : on vise le type ou l'autocompletion).
export async function taper(page, selecteur, valeur, { delai = 20000 } = {}) {
  const e = page.locator(selecteur).first();
  await e.waitFor({ state: 'attached', timeout: delai });
  await e.click({ force: true });
  await page.waitForTimeout(250);
  await page.keyboard.press('Control+A');
  await page.keyboard.type(valeur, { delay: 15 });
  await page.waitForTimeout(300);
}

/// Connexion par mot de passe (construction locale AUTH_PAR_MOT_DE_PASSE=true).
export async function connecter(page, courriel, motDePasse = MDP) {
  await ouvrir(page, '/');
  if (!(await page.locator('input[type=password]').count())) {
    const e = await trouver(page, "J'ai déjà un compte", { delai: 8000 });
    if (e) { await e.click(); await page.waitForTimeout(1200); }
  }
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await taper(page, 'input[type=password]', motDePasse);
  await page.keyboard.press('Enter');
  await page.waitForTimeout(5000);
  await activerSemantique(page);
}

/// Ferme, dans la base LOCALE, les classes E2E d'un passage precedent (et leurs
/// seances a venir), pour que l'enseignant de test soit libre au meme horaire.
export function nettoyerClassesE2E() {
  const admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  sql(`update public.sessions set deleted_at = now()
       where deleted_at is null and groupe_id in (select id from public.groupes where libelle like 'E2E %' and ended_at is null)`);
  sql(`update public.groupe_membres set left_at = now(), left_by = '${admin}', left_reason = 'E2E : nettoyage avant passage'
       where left_at is null and groupe_id in (select id from public.groupes where libelle like 'E2E %' and ended_at is null)`);
  sql(`update public.groupes set ended_at = now(), ended_by = '${admin}', end_reason = 'E2E : nettoyage avant passage'
       where libelle like 'E2E %' and ended_at is null`);
}

/// Va a un onglet de la barre de navigation par son nom ; si l'arbre
/// d'accessibilite ne l'expose pas, par l'adresse de la route (ecart note).
export async function allerOnglet(page, nom, route, dire = console.log) {
  const e = await trouver(page, new RegExp(`^${nom}( Onglet.*)?$`), { delai: 4000 });
  if (e) { await e.click(); await page.waitForTimeout(1500); return true; }
  dire(`  ECART : onglet « ${nom} » absent de l'arbre d'accessibilite ; ouvert par l'adresse ${route}`);
  await page.evaluate((r) => { location.hash = `#${r}`; }, route);
  await page.waitForTimeout(2500);
  await activerSemantique(page);
  return false;
}

/// Allege les captures PNG (palette de 96 couleurs) pour garder le depot leger.
export function alleger(dossier) {
  try {
    execFileSync('python3', ['-I', '-c', `
import pathlib, sys
from PIL import Image
for f in pathlib.Path(sys.argv[1]).glob('*.png'):
    Image.open(f).convert('RGB').quantize(96, method=Image.Quantize.MEDIANCUT).save(f, optimize=True)
`, dossier]);
  } catch (e) { console.log(`captures non allegees : ${e.message}`); }
}

/// Dernier message de Mailpit adresse a `courriel` arrive apres `depuis`.
export async function dernierLien(courriel, depuis = 0, delai = 60000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    const r = await (await fetch(`${MAILPIT}/api/v1/search?query=${encodeURIComponent(`to:${courriel}`)}`)).json();
    const m0 = (r.messages ?? []).find((m) => Date.parse(m.Created) >= depuis - 2000);
    if (m0) {
      const m = await (await fetch(`${MAILPIT}/api/v1/message/${m0.ID}`)).json();
      const corps = `${m.HTML ?? ''} ${m.Text ?? ''}`;
      const liens = [...corps.matchAll(/https?:\/\/[^\s"'<>]+/g)].map((x) => x[0].replace(/&amp;/g, '&'));
      return { sujet: m.Subject, lien: liens.find((u) => u.includes('/auth/v1/verify')), liens };
    }
    await new Promise((res) => setTimeout(res, 1500));
  }
  return null;
}

/// Connexion d'un compte cree par l'interface (sans mot de passe) : « Recevoir
/// le lien », puis le lien recu dans Mailpit, comme un vrai utilisateur.
export async function connecterParLien(page, courriel) {
  await ouvrir(page, '/');
  const deja = await trouver(page, "J'ai déjà un compte", { delai: 6000 });
  if (deja) { await deja.click(); await page.waitForTimeout(1000); }
  // Session encore ouverte dans ce navigateur : rien a faire.
  if (!(await page.locator('input[autocomplete=email], input[inputmode=email]').count())) return;
  const depuis = Date.now();
  await taper(page, 'input[autocomplete=email], input[inputmode=email]', courriel);
  await cliquer(page, /^Recevoir le lien/, { pause: 2000 });
  const recu = await dernierLien(courriel, depuis);
  if (!recu?.lien) throw new Error(`connexion par lien : aucun lien recu dans Mailpit pour ${courriel}`);
  await page.goto(recu.lien);
  await page.waitForTimeout(6000);
  await activerSemantique(page);
}
