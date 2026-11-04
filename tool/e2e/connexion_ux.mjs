// CONNEXION-UX (directeur, 03/11/2026) : la page de connexion simplifiee, sur
// la pile LOCALE, par l'interface (R3).
//
// A 390 et a 1440, en francais puis en arabe (droite a gauche) :
//   - seuls visibles en haut : le titre, les onglets, le champ, « Recevoir le
//     lien », « Continuer avec Google » et le bouton « Connecter l'appareil
//     d'un eleve » ; aucune phrase d'introduction ;
//   - le bouton de l'eleve est sur la ligne de Google, avant lui dans le sens
//     de lecture (a gauche en francais, a droite en arabe), sous « Recevoir
//     le lien » (sur ordinateur aussi : la rangee de trois ne tient pas) ;
//   - les petits liens du bas : lien expire, tuteur qui prepare l'appareil,
//     informations legales ;
//   - le bouton de l'eleve ouvre la feuille existante.
// Puis, a 390 et 1440 en francais, la case de Cloudflare forcee visible (cle
// de TEST publique « interaction exigee », reglage du BANC seulement) : elle
// se pose entre le champ et les boutons. Le reglage est remis a vide a la fin.
//
// L'application doit etre construite SANS le mode demonstration
// (AUTH_PAR_MOT_DE_PASSE absent) : la demonstration retire Google et le
// bouton de l'eleve. Servie par tool/e2e/serveur.mjs sur un autre port.
// Usage : E2E_APP=http://127.0.0.1:8092 E2E_PROXY=$HTTPS_PROXY node tool/e2e/connexion_ux.mjs
import { parcours, activerSemantique, trouver, attendreTexte, libelles, sql, APP } from './commun.mjs';

const CLE_VISIBLE = '3x00000000000000000000FF';
const p = await parcours('CONNEXION-UX : page de connexion simplifiee', 'CONNEXION-UX');
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 }, bureau: false },
  { nom: '1440', vue: { width: 1440, height: 900 }, bureau: true },
];
const LANGUES = [
  {
    code: 'fr', langue: 'fr-FR', rtl: false,
    titre: 'Se connecter', lien: /^Recevoir le lien$/, google: /^Continuer avec Google$/,
    eleve: /^Connecter l'appareil d'un élève$/, intro: 'Nous vous envoyons un lien par courriel',
    pied: [/Lien expiré ou jamais reçu/, /préparez l'appareil d'un élève/, /^Informations légales$/, /^Confidentialité$/],
    feuille: /Saisir le code/,
  },
  {
    code: 'ar', langue: 'ar-SA', rtl: true,
    titre: 'تسجيل الدخول', lien: /^استلام الرابط$/, google: /^المتابعة بحساب Google$/,
    eleve: /^ربط جهاز طالب$/, intro: null,
    pied: [/انتهت صلاحية الرابط أو لم يصل/, /وتجهّز جهاز طالب/, /^المعلومات القانونية$/, /^الخصوصية$/],
    feuille: /إدخال الرمز/,
  },
];

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function regler(cle) {
  sql(`update public.app_config set value = to_jsonb('${cle}'::text) where key = 'securite.turnstile_cle_site'`);
}

async function contexte(vue, langue) {
  const a = await p.contexte('visiteur', { vue: vue.vue, langue: langue.langue });
  await a.ctx.route('**/*', (route) => {
    const u = new URL(route.request().url());
    if (/(^|\.)challenges\.cloudflare\.com$/.test(u.hostname)) return route.continue();
    return route.fallback();
  });
  return a;
}

async function ouvrirConnexion(page) {
  await page.goto(`${APP}/#/connexion`);
  await page.waitForTimeout(6000);
  await activerSemantique(page);
}

async function boite(page, nom) {
  const e = await trouver(page, nom, { role: 'button' });
  verifier(e !== null, `bouton ${nom} present`);
  return e.boundingBox();
}

async function passage(vue, langue) {
  p.dire(`-- ${vue.nom}, ${langue.code}`);
  const a = await contexte(vue, langue);
  await ouvrirConnexion(a.page);
  verifier(await attendreTexte(a.page, langue.titre, 20000), `titre « ${langue.titre} »`);
  if (langue.intro) {
    verifier(!(await attendreTexte(a.page, langue.intro, 1500)), 'aucune phrase d\'introduction');
  }
  const lien = await boite(a.page, langue.lien);
  const google = await boite(a.page, langue.google);
  const eleve = await boite(a.page, langue.eleve);
  const memeLigne = (x, y) => Math.abs((x.y + x.height / 2) - (y.y + y.height / 2)) < 4;
  verifier(memeLigne(eleve, google), "l'eleve et Google sur la meme ligne");
  verifier(langue.rtl ? eleve.x > google.x : eleve.x < google.x,
    `l'eleve avant Google dans le sens de lecture (${langue.rtl ? 'a droite' : 'a gauche'})`);
  // Sur ordinateur aussi, « Recevoir le lien » au-dessus : les trois boutons
  // ne tiennent pas sur une rangee de 560 (mesure du 03/11/2026, environ 723).
  verifier(lien.y + lien.height <= google.y, '« Recevoir le lien » au-dessus');
  if (vue.bureau) {
    verifier(eleve.width < 500 && google.width < 500, 'sur ordinateur, a la largeur de leur contenu');
  }
  await p.capture(a, `${vue.nom}_${langue.code}_1_connexion`);
  // Le bas de page, quand il ne tient pas a l'ecran (Flutter ne pose les
  // noeuds d'accessibilite que de ce qui est a l'ecran).
  await a.page.mouse.move(vue.vue.width * 0.75, vue.vue.height / 2);
  await a.page.mouse.wheel(0, 2000);
  await a.page.waitForTimeout(800);
  // Les petits liens sont des <a> : on les lit dans les libelles de la page.
  const vus = await libelles(a.page);
  for (const motif of langue.pied) {
    verifier(vus.some((x) => x.startsWith('a:') && motif.test(x.slice(2))), `lien du bas ${motif}`);
  }
  await p.capture(a, `${vue.nom}_${langue.code}_2_bas`);
  await a.page.mouse.wheel(0, -2000);
  await a.page.waitForTimeout(800);
  (await trouver(a.page, langue.eleve, { role: 'button' })).click();
  await a.page.waitForTimeout(1500);
  verifier(await attendreTexte(a.page, langue.feuille, 10000), "le bouton de l'eleve ouvre la feuille");
  await p.capture(a, `${vue.nom}_${langue.code}_3_feuille_eleve`);
  await a.ctx.close();
}

async function caseVisible(vue) {
  regler(CLE_VISIBLE);
  p.dire(`-- ${vue.nom}, fr, case de Cloudflare forcee visible`);
  const a = await contexte(vue, LANGUES[0]);
  await ouvrirConnexion(a.page);
  let cadre = false;
  for (let i = 0; i < 30 && !cadre; i++) {
    cadre = a.page.frames().some((f) => /challenges\.cloudflare\.com/.test(f.url()));
    if (!cadre) await a.page.waitForTimeout(500);
  }
  verifier(cadre, 'le cadre de Cloudflare est dans la page');
  await a.page.waitForTimeout(5000);
  await p.capture(a, `${vue.nom}_fr_4_case_visible`);
  await a.ctx.close();
}

let code = 1;
try {
  if (!process.env.E2E_PROXY) throw new Error('E2E_PROXY attendu : Cloudflare est joint par le proxy');
  regler('');
  for (const vue of VUES) {
    for (const langue of LANGUES) await passage(vue, langue);
  }
  for (const vue of VUES) await caseVisible(vue);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
} finally {
  try { regler(''); } catch { /* pile arretee */ }
}
process.exit(code);
