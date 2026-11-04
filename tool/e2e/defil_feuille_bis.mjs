// DEFIL-FEUILLE-bis (03/11/2026, garde-cap) : « Signaler un besoin », une
// surface modale trop haute, sur la pile LOCALE.
//
// Ce que le parcours montre, a 1440 x 900 puis 390 x 844 :
//   1. l'enseignant ouvre la fiche d'un eleve de sa Classe, puis « Signaler un
//      besoin » : la surface en haut, puis apres avoir fait defiler sa seule
//      barre jusqu'au bas ; on releve la hauteur de la fenetre, le haut et le
//      bas de la surface (par son titre et son bouton d'envoi), la place du
//      titre avant et apres le defilement ;
//   2. rien n'est envoye : la surface est fermee par Echap.
// PHASE=avant joue le meme parcours sur la construction de main (captures
// dans defil-feuille-bis/avant/), PHASE=apres sur cette branche. Les captures
// portent la date du passage.
//
// Donnees : un foyer, un eleve et une Classe neuve de l'enseignant amorce a
// chaque passage ; rien n'est efface ni envoye.
// Usage : PHASE=apres node tool/e2e/defil_feuille_bis.mjs
import { parcours, trouver, activerSemantique, connecter, cliquer, attendreTexte,
  nettoyerClassesE2E, sql, COMPTES } from './commun.mjs';

const PHASE = process.env.PHASE === 'avant' ? 'avant' : 'apres';
const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours(`DEFIL-FEUILLE-bis (${PHASE})`,
  PHASE === 'avant' ? 'defil-feuille-bis/avant' : 'defil-feuille-bis');
const n = Date.now() % 1000000;
const ID = {};
const releves = {};

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function matricule() {
  for (;;) {
    const m = `RA-26-${String(1000 + Math.floor(Math.random() * 9000))}`;
    if (sql(`select count(*) from public.profiles where immutable_id = '${m}'`) === '0') return m;
  }
}

function amorcer() {
  nettoyerClassesE2E();
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.eleve = sql('select gen_random_uuid()');
  ID.foyer = sql('select gen_random_uuid()');
  ID.classe = sql('select gen_random_uuid()');
  ID.nom = `E2E Defil-bis Al-Huda ${n}`;
  sql(`begin;
    insert into auth.users (id, email) values ('${ID.eleve}', 'e2e-defil-bis-${n}@example.com');
    insert into public.households (id, timezone) values ('${ID.foyer}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
      values ('${ID.eleve}', '${matricule()}', 'student', '${ID.foyer}', 'Yasmine', 'Eleve', 'active', 'female');
    insert into public.student_profiles (profile_id, student_type, interface_mode)
      values ('${ID.eleve}', 'minor', 'standard');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, '${ID.nom}', 6, 21);
    insert into public.groupe_membres (groupe_id, student_id) values ('${ID.classe}', '${ID.eleve}');
    commit;`);
  p.dire(`  amorce : classe « ${ID.nom} » (${ID.classe}), eleve Yasmine`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(3500);
  await activerSemantique(page);
}

/// Le haut et le bas d'un element, ou null s'il n'est pas a l'ecran.
async function bornes(page, nom, options) {
  const e = await trouver(page, nom, { delai: 1500, ...options });
  const b = e ? await e.boundingBox().catch(() => null) : null;
  return b ? { haut: Math.round(b.y), bas: Math.round(b.y + b.height) } : null;
}

async function passage(largeur, hauteur) {
  const tag = `${JOUR}_${largeur}`;
  const c = await p.contexte('enseignant', { vue: { width: largeur, height: hauteur } });
  await connecter(c.page, COMPTES.enseignant);
  await vers(c.page, `/enseignant/groupe/${ID.classe}`);
  verifier(await attendreTexte(c.page, 'Yasmine', 30000), `${largeur} : l'eleve est dans la fiche de la Classe`);
  await cliquer(c.page, /Yasmine/, { pause: 2500 });
  await cliquer(c.page, /^Signaler un besoin$/, { pause: 2500 });
  verifier(await attendreTexte(c.page, /^Signaler un besoin$/, 10000), `${largeur} : « Signaler un besoin » est ouvert`);
  // Une categorie, pour que tout le formulaire soit la (resume et notice).
  await cliquer(c.page, /^Problème pédagogique/, { pause: 1000 });

  const titreAvant = await bornes(c.page, /^Signaler un besoin$/, { role: 'heading' });
  const envoiAvant = await bornes(c.page, /^Envoyer le signalement$/, { role: 'button' });
  await p.capture(c, `${tag}_1_signaler_haut`);
  await c.page.mouse.move(largeur / 2, hauteur / 2);
  for (let i = 0; i < 14; i++) {
    await c.page.mouse.wheel(0, 250);
    await c.page.waitForTimeout(200);
  }
  await c.page.waitForTimeout(600);
  await activerSemantique(c.page);
  const titreApres = await bornes(c.page, /^Signaler un besoin$/, { role: 'heading' });
  const envoiApres = await bornes(c.page, /^Envoyer le signalement$/, { role: 'button' });
  await p.capture(c, `${tag}_2_signaler_bas`);
  releves[largeur] = { hauteur, titreAvant, envoiAvant, titreApres, envoiApres };
  p.dire(`  ${largeur} : ${JSON.stringify(releves[largeur])}`);
  if (PHASE === 'apres') {
    verifier(envoiApres && envoiApres.bas <= hauteur,
      `${largeur} : en faisant defiler la seule barre, le bouton d'envoi est atteint`);
    verifier(titreAvant !== null && (titreApres === null || titreApres.haut < titreAvant.haut),
      `${largeur} : le titre defile avec le contenu`);
  }
  await c.page.keyboard.press('Escape');
  await c.page.waitForTimeout(1200);
  verifier(sql(`select count(*) from public.student_concern where student_id = '${ID.eleve}'`) === '0',
    `${largeur} : rien n'est envoye`);
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
