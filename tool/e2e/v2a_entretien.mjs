// V2-a (04/11/2026) : le bloc Entretien de la fiche candidature (ADM-21) et la
// regle des fondateurs dans Configuration > Regles, sur la pile LOCALE.
//
// Ce que le parcours montre, connecte comme la direction (une femme), a 1440 x
// 900 puis 390 x 844, chaque fois sur une candidate neuve en Salle de
// verification et d'entretien, etat « Entretien a planifier » :
//   1. la section dit « Aucun entretien planifie » et propose « Planifier
//      l'entretien » ; la feuille dit le minimum de fondateurs (2) ;
//   2. un seul fondateur choisi : le serveur refuse, la feuille le dit en mots,
//      la base n'a aucun entretien ;
//   3. deux fondateurs : l'entretien est planifie, la section le montre, la
//      base porte l'entretien, ses deux participants et sa seance ;
//   4. un compte rendu et une entree (ecrits en SQL local, comme le feraient
//      la salle et le webhook LiveKit) se lisent dans la section ;
//   5. retirer une fondatrice : le serveur refuse (regle active), la feuille le
//      dit ;
//   6. consigner « Entretien tenu » : la base porte l'issue, la section dit
//      le dernier entretien.
// Puis Configuration > Regles, section Entretiens, aux deux largeurs.
//
// Amorce (SQL local) : une comptable active (le personnel compte direction,
// enseignants, comptables et controleurs ; un enseignant actif exige ses
// signatures), fondatrice, du meme cote que
// la direction (CAND-Q07) ; la direction cochee fondatrice ; une candidate par
// largeur. Rien n'est efface.
// Usage : node tool/e2e/v2a_entretien.mjs
import { parcours, connecter, trouver, cliquer, attendreTexte, ouvrir,
  activerSemantique, amenerEnVue, sql, COMPTES, MDP } from './commun.mjs';

const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours('V2-a (bloc Entretien, regle des fondateurs)', 'v2a-entretien');
const n = Date.now() % 1000000;
let direction;
let hafsa;

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function creerCompte(courriel) {
  return sql(`with nouveau as (
    insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change)
    values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated',
      'authenticated', '${courriel}', extensions.crypt('${MDP}', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
    returning id),
  ident as (insert into auth.identities (id, user_id, provider_id, identity_data, provider,
      created_at, updated_at, last_sign_in_at)
    select gen_random_uuid(), id, id::text,
      jsonb_build_object('sub', id::text, 'email', '${courriel}', 'email_verified', true),
      'email', now(), now(), now() from nouveau returning user_id)
  select id from nouveau`).split('\n')[0];
}

function matricule() {
  return `RA-26-${String(1000 + Math.floor(Math.random() * 9000))}`;
}

function amorcer() {
  direction = sql(`select id from auth.users where email = '${COMPTES.direction}'`);
  hafsa = creerCompte(`e2e-v2a-hafsa-${n}@example.com`);
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${hafsa}', '${matricule()}', 'accountant', 'Hafsa', 'Fondatrice${n}', 'active', 'female')`);
  for (const id of [direction, hafsa]) {
    sql(`insert into public.personnel_fondateurs (profile_id, fondateur, modifie_par)
         values ('${id}', true, '${direction}')
         on conflict (profile_id) do update set fondateur = true`);
  }
  sql(`update public.app_config set value = 'true'::jsonb where key = 'entretiens.regle_fondateurs_active'`);
  sql(`update public.app_config set value = '2'::jsonb where key = 'entretiens.fondateurs_minimum'`);
  verifier(sql(`select count(*) from public.personnel_fondateurs
                where fondateur and profile_id in ('${direction}', '${hafsa}')`) === '2',
    'amorce : la direction et Hafsa sont fondatrices, regle active, minimum 2');
}

function candidate(largeur) {
  const id = creerCompte(`e2e-v2a-cand-${largeur}-${n}@example.com`);
  const nom = `Cand${largeur}x${n}`;
  sql(`insert into public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
       values ('${id}', '${matricule()}', 'teacher', 'Khadija', '${nom}', 'pending_kyc', 'female')`);
  const ref = sql(`insert into public.candidatures (type_code, profile_id, genre, nom_complet, etape, etat, source, pays_residence)
       values ('enseignant', '${id}', 'female', 'Khadija ${nom}', 'verifications', 'entretien_a_planifier',
               'lien_public', 'FR') returning reference`).split('\n')[0];
  const cid = sql(`select id from public.candidatures where reference = '${ref}'`);
  p.dire(`Amorce ${largeur} : Khadija ${nom}, ${ref}`);
  return { id, ref, cid };
}

async function voir(c, texte, nom) {
  const e = await trouver(c.page, texte, { delai: 15000 });
  if (e) await amenerEnVue(c.page, e);
  await c.page.waitForTimeout(700);
  await p.capture(c, nom);
}

// Un jour et une heure propres a chaque passage : la seance d'entretien est
// au nom de la direction, qui ne peut pas avoir deux seances au meme moment
// (un passage precedent garde les siennes, rien n'est efface).
async function choisirJourEtHeure(page, decalage) {
  const jour = await trouver(page, /^Jour\b/, { delai: 8000 });
  verifier(jour !== null, 'le champ « Jour »');
  await amenerEnVue(page, jour); await jour.click(); await page.waitForTimeout(1200);
  await activerSemantique(page);
  const dans = new Date(Date.now() + (3 + ((n + decalage) % 20)) * 86400000);
  if (dans.getMonth() !== new Date().getMonth()) {
    const suivant = await trouver(page, /mois suivant|Next month/i, { delai: 4000 });
    if (suivant) { await suivant.click(); await page.waitForTimeout(800); }
  }
  const jourNum = await trouver(page, new RegExp(`^${dans.getDate()}\\b`), { delai: 6000 });
  verifier(jourNum !== null, `calendrier : le jour ${dans.getDate()}`);
  await jourNum.click(); await page.waitForTimeout(600);
  const ok = await trouver(page, /^OK$/i, { delai: 4000 });
  if (ok) { await ok.click(); await page.waitForTimeout(1000); }
  await activerSemantique(page);
  const heure = await trouver(page, /^Heure\b/, { delai: 8000, role: 'button' });
  verifier(heure !== null, 'le menu « Heure »');
  await amenerEnVue(page, heure); await heure.click(); await page.waitForTimeout(900);
  const minutes = 6 * 60 + 30 * ((n + decalage) % 32);
  const libelle = `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
  const h = await trouver(page, new RegExp(`^${libelle}$`), { delai: 6000, role: 'menuitem' })
    ?? await trouver(page, new RegExp(`^${libelle}$`), { delai: 3000 });
  verifier(h !== null, `menu : ${libelle}`);
  await amenerEnVue(page, h); await h.click(); await page.waitForTimeout(900);
}

async function cocher(page, nom) {
  const o = await trouver(page, nom, { delai: 8000 });
  verifier(o !== null, `l'option ${nom}`);
  await amenerEnVue(page, o); await o.click(); await page.waitForTimeout(700);
}

async function passage(largeur, hauteur) {
  const tag = `${JOUR}_${largeur}`;
  const cand = candidate(largeur);
  const c = await p.contexte('direction', { vue: { width: largeur, height: hauteur } });
  // Les appels au serveur des gestes d'entretien, au journal.
  c.page.on('response', async (r) => {
    if (/rpc\/(planifier|ajouter|retirer|consigner|lire)_/.test(r.url())) {
      p.dire(`  rpc ${r.status()} ${r.url().replace(/^.*rpc\//, '')} ${(await r.text().catch(() => '')).slice(0, 300)}`);
    }
  });
  c.page.on('console', (m) => { if (m.type() === 'error') p.dire(`  console ${m.text().slice(0, 300)}`); });
  await connecter(c.page, COMPTES.direction);
  await ouvrir(c.page, `/#/admin/personnes/candidatures/${encodeURIComponent(cand.ref)}`);
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Aucun entretien planifié/, 30000),
    `${largeur} : « Aucun entretien planifié »`);
  await voir(c, /^Planifier l'entretien$/, `${tag}_1_aucun_entretien`);

  // 2. Un seul fondateur : refuse par le serveur, dit dans la feuille.
  await cliquer(c.page, /^Planifier l'entretien$/, { pause: 1500 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Minimum exigé\s*:\s*2/, 10000),
    `${largeur} : la feuille dit le minimum (2)`);
  await p.capture(c, `${tag}_2_feuille`);
  await choisirJourEtHeure(c.page, largeur);
  await cocher(c.page, /E2E Direction Locale/);
  await cliquer(c.page, /^Planifier$/, { pause: 2500 });
  verifier(await attendreTexte(c.page, /Il faut au moins 2 fondateurs/, 10000),
    `${largeur} : le refus des fondateurs est dit en mots`);
  await voir(c, /Il faut au moins 2 fondateurs/, `${tag}_3_refus_fondateurs`);
  verifier(sql(`select count(*) from public.entretiens where candidature_id = '${cand.cid}'`) === '0',
    `${largeur} : la base n'a aucun entretien`);

  // 3. Deux fondateurs : planifie.
  await cocher(c.page, new RegExp(`Hafsa Fondatrice${n}`));
  await cliquer(c.page, /^Planifier$/, { pause: 3500 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Entretien planifié\./, 15000),
    `${largeur} : le retour local dit « Entretien planifié »`);
  const session = sql(`select session_id from public.entretiens where candidature_id = '${cand.cid}' and issue is null`);
  verifier(session !== '', `${largeur} : la base porte l'entretien`);
  verifier(sql(`select count(*) from public.entretien_participants
                where session_id = '${session}' and retire_le is null and fondateur`) === '2',
    `${largeur} : deux participantes fondatrices`);
  verifier(sql(`select (session_type = 'entretien' and status = 'planned'
                        and ended_at - started_at = interval '45 minutes')::text
                  from public.sessions where id = '${session}'`) === 'true',
    `${largeur} : la seance d'entretien, 45 min, planifiee`);
  await voir(c, /Fondateurs parmi les participants/, `${tag}_4_entretien_planifie`);

  // 4. Un compte rendu et une entree, comme la salle et le webhook.
  sql(`insert into public.entretien_comptes_rendus (session_id, auteur_id, texte, avis)
       values ('${session}', '${hafsa}', 'Lecture soignée, tajwid appliqué.', 'favorable')`);
  sql(`insert into public.session_events (session_id, profile_id, event_type, source)
       values ('${session}', '${hafsa}', 'joined', 'livekit_webhook')`);
  await c.page.reload(); await c.page.waitForTimeout(5000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Lecture soignée, tajwid appliqué\./, 30000),
    `${largeur} : le compte rendu se lit`);
  verifier(await attendreTexte(c.page, /Entrée de .*Hafsa/, 10000),
    `${largeur} : l'entree dans la salle se lit`);
  await voir(c, /Lecture soignée/, `${tag}_5_compte_rendu_entree`);

  // 5. Retirer une fondatrice : refuse (regle active).
  const retirer = await trouver(c.page, new RegExp(`^Retirer .*Hafsa Fondatrice${n}`), { delai: 10000 });
  verifier(retirer !== null, `${largeur} : « Retirer » sur la ligne de Hafsa`);
  await amenerEnVue(c.page, retirer); await retirer.click(); await c.page.waitForTimeout(1500);
  await activerSemantique(c.page);
  await cliquer(c.page, /^Retirer$/, { pause: 2500 });
  verifier(await attendreTexte(c.page, /Il faut au moins 2 fondateurs/, 10000),
    `${largeur} : retirer sous le minimum est refuse, en mots`);
  await voir(c, /Il faut au moins 2 fondateurs/, `${tag}_6_retrait_refuse`);
  verifier(sql(`select count(*) from public.entretien_participants
                where session_id = '${session}' and retire_le is null`) === '2',
    `${largeur} : la base garde les deux participantes`);
  await cliquer(c.page, /^Annuler$/, { pause: 1200 });

  // 6. Consigner « Entretien tenu ».
  await activerSemantique(c.page);
  await cliquer(c.page, /^Consigner l'issue$/, { pause: 1500 });
  await activerSemantique(c.page);
  await cocher(c.page, /^Entretien tenu$/);
  await cliquer(c.page, /^Consigner$/, { pause: 3500 });
  await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Issue consignée\./, 15000),
    `${largeur} : le retour local dit « Issue consignée »`);
  verifier(sql(`select issue from public.entretiens where session_id = '${session}'`) === 'tenu',
    `${largeur} : la base porte l'issue « tenu »`);
  verifier(await attendreTexte(c.page, /Dernier entretien.*Entretien tenu/, 15000),
    `${largeur} : la section dit le dernier entretien`);
  await voir(c, /Dernier entretien/, `${tag}_7_issue_consignee`);

  // Configuration > Regles : la section Entretiens.
  await ouvrir(c.page, '/#/admin/configuration/regles');
  await c.page.waitForTimeout(4000); await activerSemantique(c.page);
  verifier(await attendreTexte(c.page, /Exiger des fondateurs/, 30000),
    `${largeur} : Regles, « Exiger des fondateurs »`);
  await voir(c, /Fondateurs au minimum/, `${tag}_8_regles_entretiens`);
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
