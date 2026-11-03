// Lot N4 (03/11/2026) : la Bibliotheque lue au serveur hors direction, sur la
// pile LOCALE seulement (jamais un apercu Vercel, jamais la production).
//
// Amorce (SQL local, comme amorcer.sh : l'interface du lecteur ne cree pas de
// support) : trois supports publies (deux « inscrits », un « publique »), leurs
// droits revus par la direction de test, et une position de lecture de
// l'enseignant de test sur l'un d'eux. Les supports d'un passage precedent sont
// archives (jamais effaces).
// Puis par l'interface, connecte comme l'enseignant de test :
//   1. /#/tc/bibliotheque : les trois supports, lus par
//      `bibliotheque_catalogue_lecteur`, et la reprise ;
//   2. recherche « tajwid » : seul le support de cette categorie reste ;
//   3. recherche sans resultat : l'etat vide.
// Les captures vont dans docs/current/captures/E2E/N4/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/n4_bibliotheque.mjs (puis 390x844)
import { parcours, connecter, trouver, libelles, ouvrir, activerSemantique,
  sql, COMPTES } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`N4 : Bibliotheque du lecteur (${largeur} x ${hauteur})`,
  `N4/${date}/${largeur}`);
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
const lus = async (page, k = 80) => (await libelles(page)).slice(0, k).join(' | ');

const SUPPORTS = [
  { titre: `E2E N4 Règles du tajwid ${n}`, court: 'Tajwid', type: 'lesson', acces: 'inscrits', categorie: 'tajwid' },
  { titre: `E2E N4 Lecture guidée ${n}`, court: 'Lecture', type: 'pdf', acces: 'inscrits', categorie: 'lecture' },
  { titre: `E2E N4 Invocations du matin ${n}`, court: 'Invocations', type: 'pdf', acces: 'publique', categorie: 'invocations' },
];

function amorcer() {
  ID.admin = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  sql(`update public.library_resource set archived_at = now()
        where title like 'E2E N4 %' and archived_at is null`);
  ID.supports = SUPPORTS.map((s) => {
    const id = sql(`insert into public.library_resource
        (title, short_title, resource_type, access_policy, offline_policy, category, language)
      values ('${s.titre.replace(/'/g, "''")}', '${s.court}', '${s.type}', '${s.acces}', 'jamais', '${s.categorie}', 'fr')
      returning id`).split('\n')[0];
    const version = sql(`insert into public.resource_version (resource_id, numero_version, statut)
      values ('${id}', 1, 'brouillon') returning id`).split('\n')[0];
    sql(`insert into public.library_version_rights
        (resource_version_id, source_titre, titulaire, usages, attribution, approuve, revu_par, revu_le)
      values ('${version}', 'Support E2E N4', 'Rewayah', array['application'], 'Rewayah', true, '${ID.admin}', now())`);
    sql(`do $r$ begin
      perform set_config('request.jwt.claim.sub', '${ID.admin}', true);
      update public.resource_version set statut = 'publiee' where id = '${version}';
      update public.library_resource set current_version_id = '${version}' where id = '${id}';
    end $r$;`);
    return id;
  });
  sql(`insert into public.library_reading_position (profile_id, resource_id, type_ancrage, page, vue_le)
       values ('${ID.prof}', '${ID.supports[1]}', 'page', 4, now())
       on conflict (profile_id, resource_id) do update set page = 4, vue_le = now()`);
  p.dire(`Amorce : supports ${ID.supports.join(', ')} ; enseignant ${ID.prof} ; reprise sur le deuxieme`);
}

/// La zone de recherche de la Bibliotheque. Le champ actif porte l'aide
/// « Titre, niveau, sourate ou page » ; « Rechercher un support » est son
/// etiquette, rendue desactivee dans l'arbre d'accessibilite.
async function chercher(page, texte) {
  // Une fois du texte saisi, l'aide disparait : le champ garde alors le focus.
  const champ = page.getByRole('textbox', { name: /^Titre, niveau/ });
  if (await champ.count()) {
    await champ.first().click();
    await page.waitForTimeout(300);
  }
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Backspace');
  await page.keyboard.type(texte, { delay: 40 });
  await page.waitForTimeout(2500);
  await activerSemantique(page);
}

let code = 1;
try {
  amorcer();
  const e = await p.contexte('enseignant', { vue });
  await connecter(e.page, COMPTES.enseignant);
  await ouvrir(e.page, '/#/tc/bibliotheque');
  await e.page.waitForTimeout(4000);
  await activerSemantique(e.page);
  const ecran = await lus(e.page, 120);
  p.dire(`Bibliotheque : ${ecran}`);
  verdicts.troisSupports = /Tous les supports \| flt-semantics:3 \|/.test(ecran);
  verdicts.reprise = /Continuer \| button:E2E N4 Lecture guidée/.test(ecran);
  await p.capture(e, 'bibliotheque_catalogue');

  await chercher(e.page, 'tajwid');
  const filtre = await lus(e.page, 120);
  p.dire(`Recherche « tajwid » : ${filtre}`);
  verdicts.rechercheFiltre = filtre.includes('Règles du tajwid') && !filtre.includes('Invocations du matin');
  await p.capture(e, 'bibliotheque_recherche');

  await chercher(e.page, `introuvable${n}`);
  const vide = await lus(e.page, 80);
  p.dire(`Recherche sans resultat : ${vide}`);
  verdicts.rechercheVide = !SUPPORTS.some((s) => vide.includes(s.titre));
  await p.capture(e, 'bibliotheque_recherche_vide');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
