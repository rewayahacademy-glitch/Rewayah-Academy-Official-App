// DEFIL-FEUILLE (03/11/2026, PLAN-LOTS §10) : une surface modale trop haute
// devient l'ecran, sur la pile LOCALE.
//
// Ce que le parcours montre, a 1440 x 900 puis 390 x 844 :
//   1. « Ajouter un eleve » (Operations, Classes, Actions de la classe) : la
//      surface en haut, puis apres avoir fait defiler sa seule barre ; on
//      releve la hauteur de la surface, la place du titre avant et apres le
//      defilement, et le nombre de cartes d'eleve vues ;
//   2. une boite courte (« Cloturer la classe », ouverte puis fermee par
//      Echap, rien n'est envoye) : inchangee.
// PHASE=avant joue le meme parcours sur la construction de main (captures
// dans defil-feuille/avant/), PHASE=apres sur cette branche. Les captures portent la
// date du passage.
//
// Donnees : une Classe neuve de l'enseignant amorce a chaque passage ; rien
// n'est efface ni envoye. Usage : PHASE=apres node tool/e2e/defil_feuille.mjs
import { parcours, trouver, activerSemantique, connecter, cliquer, attendreTexte,
  nettoyerClassesE2E, sql, COMPTES } from './commun.mjs';

const PHASE = process.env.PHASE === 'avant' ? 'avant' : 'apres';
const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours(`DEFIL-FEUILLE (${PHASE})`,
  PHASE === 'avant' ? 'defil-feuille/avant' : 'defil-feuille');
const n = Date.now() % 1000000;
const CLASSE = `E2E Defil An-Nour ${n}`;
const releves = {};

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function amorcer() {
  nettoyerClassesE2E();
  const prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
       values ('${prof}', 'enfant', 5, '${CLASSE}', 6, 21)`);
  const eleves = sql(`select count(*) from public.profiles where role = 'student'
    and deleted_at is null and account_status in ('active', 'provisional_active')`);
  p.dire(`  amorce : classe « ${CLASSE} » ; ${eleves} eleves proposables sur la pile`);
  verifier(Number(eleves) >= 6, 'au moins six eleves proposables (la liste en montre six)');
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

/// Les cartes d'eleve visibles dans la fenetre, par leur nom.
async function cartesVisibles(page) {
  const vue = page.viewportSize();
  const radios = page.getByRole('radio');
  const vus = [];
  for (let i = 0; i < await radios.count(); i++) {
    const b = await radios.nth(i).boundingBox().catch(() => null);
    if (b && b.y >= 0 && b.y + b.height / 2 <= vue.height) {
      vus.push(((await radios.nth(i).getAttribute('aria-label')) ?? '').slice(0, 40));
    }
  }
  return vus;
}

/// Le haut du titre de la surface, ou null s'il n'est plus a l'ecran.
async function hautDuTitre(page) {
  const t = await trouver(page, /^Ajouter un élève/, { role: 'heading', delai: 1500 });
  const b = t ? await t.boundingBox().catch(() => null) : null;
  return b && b.y + b.height > 0 ? Math.round(b.y) : null;
}

async function ouvrirActions(page) {
  const actives = await trouver(page, /^Actives, /, { delai: 2000 });
  if (actives) { await actives.click(); await page.waitForTimeout(1500); }
  await cliquer(page, new RegExp(`^Actions : ${CLASSE}`));
}

async function passage(largeur, hauteur) {
  const tag = `${JOUR}_${largeur}`;
  const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  await connecter(c.page, COMPTES.direction);
  await vers(c.page, '/admin/operations/groupes');
  verifier(await attendreTexte(c.page, CLASSE, 30000), `${largeur} : la classe est dans la liste`);

  // 1. « Ajouter un eleve ».
  await ouvrirActions(c.page);
  await cliquer(c.page, /^Ajouter un élève$/, { role: 'menuitem', pause: 2500 });
  verifier(await attendreTexte(c.page, /^Ajouter un élève/, 10000), `${largeur} : la surface « Ajouter un élève » est ouverte`);
  const titreAvant = await hautDuTitre(c.page);
  const vus = new Set(await cartesVisibles(c.page));
  await p.capture(c, `${tag}_1_ajouter_haut`);
  // Faire defiler la surface, a la molette, au milieu de l'ecran.
  await c.page.mouse.move(largeur / 2, hauteur / 2);
  for (let i = 0; i < 12; i++) {
    await c.page.mouse.wheel(0, 250);
    await c.page.waitForTimeout(250);
    for (const v of await cartesVisibles(c.page)) vus.add(v);
  }
  await c.page.waitForTimeout(600);
  const titreApres = await hautDuTitre(c.page);
  await p.capture(c, `${tag}_2_ajouter_bas`);
  releves[largeur] = { titreAvant, titreApres, cartesVues: vus.size };
  p.dire(`  ${largeur} : titre ${titreAvant} puis ${titreApres} ; ${vus.size} cartes vues : ${[...vus].join(' | ')}`);
  if (PHASE === 'apres') {
    verifier(vus.size >= 5, `${largeur} : cinq cartes ou plus vues en faisant defiler`);
    verifier(titreAvant !== null && (titreApres === null || titreApres < titreAvant),
      `${largeur} : le titre defile avec le contenu (une seule barre, celle de la surface)`);
  }
  await c.page.keyboard.press('Escape');
  await c.page.waitForTimeout(1500);

  // 2. Une boite courte, inchangee : ouverte, capturee, fermee sans rien envoyer.
  await activerSemantique(c.page);
  await ouvrirActions(c.page);
  await cliquer(c.page, /^Clôturer la classe$/, { role: 'menuitem', pause: 2500 });
  await p.capture(c, `${tag}_3_boite_courte`);
  await c.page.keyboard.press('Escape');
  await c.page.waitForTimeout(1000);
  verifier(sql(`select count(*) from public.groupes where libelle = '${CLASSE}' and ended_at is null`) === '1',
    `${largeur} : la boite courte fermee, rien n'est envoye (classe toujours active)`);
  await c.ctx.close();
}

let code = 1;
try {
  amorcer();
  await passage(1440, 900);
  await passage(390, 844);
  p.dire(`Releves : ${JSON.stringify(releves)}`);
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
}
process.exit(code);
