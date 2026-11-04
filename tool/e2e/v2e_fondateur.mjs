// V2-e (04/11/2026) : la coche « fondateur » dans le menu de ligne des
// Comptes (ADM-08), sur la pile LOCALE.
//
// Ce que le parcours montre, a 1440 x 900 puis 390 x 844, connecte comme la
// direction, vue Enseignants :
//   1. le menu de la ligne « E2E Enseignant » propose « Marquer comme
//      fondateur » (la coche est fausse au depart) ;
//   2. le geste coche, le retour local le dit, la base le confirme
//      (personnel_fondateurs) ;
//   3. le menu relu propose « Retirer des fondateurs » ; le geste decoche, la
//      base le confirme.
// Les captures portent la date du passage.
//
// Donnees : la coche de l'enseignant amorce est remise a faux au depart.
// Rien n'est efface.
// Usage : node tool/e2e/v2e_fondateur.mjs
import { parcours, trouver, activerSemantique, connecter, cliquer, attendreTexte,
  sql, COMPTES } from './commun.mjs';

const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours('V2-e (coche fondateur)', 'v2e-fondateur');
let prof;

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function coche() {
  return sql(`select coalesce((select fondateur::text from public.personnel_fondateurs
               where profile_id = '${prof}'), 'aucune')`);
}

function amorcer() {
  prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  const direction = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  sql(`insert into public.personnel_fondateurs (profile_id, fondateur, modifie_par)
       values ('${prof}', false, '${direction}')
       on conflict (profile_id) do update set fondateur = false`);
  verifier(coche() === 'false', 'amorce : la coche de l\'enseignant est fausse');
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

async function ouvrirMenu(page) {
  const menu = await trouver(page, /^Actions.*E2E Enseignant/, { delai: 20000 });
  verifier(menu !== null, 'le menu de la ligne de l\'enseignant est la');
  await menu.click();
  await page.waitForTimeout(1200);
  await activerSemantique(page);
}

async function passage(largeur, hauteur) {
  const tag = `${JOUR}_${largeur}`;
  const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  await connecter(c.page, COMPTES.direction);
  await vers(c.page, '/admin/personnes/comptes?vue=enseignants');
  verifier(await attendreTexte(c.page, /E2E Enseignant/, 30000), `${largeur} : l'enseignant est dans la vue Enseignants`);

  await ouvrirMenu(c.page);
  verifier(await attendreTexte(c.page, /^Marquer comme fondateur$/, 10000),
    `${largeur} : le menu propose « Marquer comme fondateur »`);
  await p.capture(c, `${tag}_1_menu_marquer`);
  await cliquer(c.page, /^Marquer comme fondateur$/, { pause: 2500 });
  verifier(await attendreTexte(c.page, /compte désormais parmi les fondateurs/, 10000),
    `${largeur} : le retour local dit la coche`);
  await p.capture(c, `${tag}_2_retour_marque`);
  verifier(coche() === 'true', `${largeur} : la base porte la coche`);

  await ouvrirMenu(c.page);
  verifier(await attendreTexte(c.page, /^Retirer des fondateurs$/, 10000),
    `${largeur} : le menu relu propose « Retirer des fondateurs »`);
  await p.capture(c, `${tag}_3_menu_retirer`);
  await cliquer(c.page, /^Retirer des fondateurs$/, { pause: 2500 });
  verifier(await attendreTexte(c.page, /ne compte plus parmi les fondateurs/, 10000),
    `${largeur} : le retour local dit le retrait`);
  verifier(coche() === 'false', `${largeur} : la base n'a plus la coche`);
  await c.ctx.close();
}

let code = 1;
try {
  amorcer();
  await passage(1440, 900);
  await passage(390, 844);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
