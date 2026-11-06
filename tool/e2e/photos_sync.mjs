// Train photos (garde-cap, 05/11/2026), exigence du directeur, mot pour mot :
// « il faut que ça soit synchronisé partout, un enfant avec une photo doit
// être vu avec sa photo par l'enseignant, l'admin, son foyer ».
// Pile LOCALE seulement (jamais un apercu Vercel, jamais la production).
//
// Amorce : un foyer, son enfant Hakim SANS photo, une Classe de l'enseignant
// de test avec Hakim, une seance commencee il y a deux minutes.
//   1. AVANT, a 390 puis 1440 (chaque session OUVERTE a sa largeur) :
//      enseignant (fiche de la Classe), direction (Comptes, vue Eleves),
//      foyer (Accueil, fiche de Hakim, Suivi) ; aucune URL signee de Hakim ;
//   2. le tuteur, session ouverte a 390, apres Accueil et Suivi, pose la
//      photo de Hakim (fiche, Informations) ; puis, SANS recharger, revient a
//      l'Accueil : l'URL signee de la nouvelle cle est servie dans ce
//      document (des la fiche), et l'Accueil la montre ;
//   3. APRES, memes ecrans, memes largeurs : l'URL signee est servie ;
//   4. salle, a 1440 : l'enseignant rejoint, le tuteur rejoint avec Hakim ;
//      la tuile de Hakim chez l'enseignant porte sa photo.
// Le capteur : les reponses 200 d'URL signees du seau avatars pour la cle de
// Hakim. Un ecran qui reste en initiales est nomme dans le journal.
// Captures : docs/current/captures/E2E/PHOTOS-SYNC/<date>/.
//
// Usage : node tool/e2e/photos_sync.mjs
import path from 'node:path';
import { parcours, connecter, trouver, libelles, activerSemantique, amenerEnVue,
  sql, COMPTES, MDP, DEPOT, nettoyerClassesE2E } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('Photos synchronisees : Hakim vu par l\'enseignant, la direction, son foyer',
  `PHOTOS-SYNC/${date}`);
const FICHIER = path.join(DEPOT, 'tool/e2e/portrait_factice.png');
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 } },
  { nom: '1440', vue: { width: 1440, height: 900 } },
];
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
const constats = {};
const lus = async (page, k = 60) => (await libelles(page)).slice(0, k).join(' | ');

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

function amorcer() {
  nettoyerClassesE2E();
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.courriel = `e2e-phs-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courriel);
  ID.hakim = creerCompte(`e2e-phs-e-${n}@example.com`);
  ID.nomFamille = `Sync${n}`;
  ID.classe = sql('select gen_random_uuid()');
  ID.nom = `E2E Photos Sync ${n}`;
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-PHS-T-${n}', 'guardian', '${ID.tuteur}', 'Samira', '${ID.nomFamille}', 'active', 'female'),
      ('${ID.hakim}', 'E2E-PHS-E-${n}', 'student', '${ID.tuteur}', 'Hakim', '${ID.nomFamille}', 'active', 'male');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${ID.hakim}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, '${ID.nom}',
              extract(isodow from (now() at time zone 'Europe/Paris'))::int, 9, 'Europe/Paris', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${ID.classe}', '${ID.hakim}', now() - interval '10 days');
    commit;`);
  ID.seance = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) values
      ('${ID.seance}', '${ID.prof}', now() - interval '2 minutes', now() + interval '43 minutes', 'planned', 'child', '${ID.classe}');
    insert into public.session_participants (session_id, profile_id, role) values ('${ID.seance}', '${ID.hakim}', 'student');
    commit;`);
  p.dire(`Amorce : tuteur ${ID.courriel}, Hakim ${ID.hakim} (${ID.nomFamille}), classe ${ID.classe} (${ID.nom}), seance ${ID.seance}`);
}

function capteur(page) {
  const vus = [];
  page.on('response', (r) => {
    if (r.status() === 200 && r.url().includes('/storage/v1/object/sign/avatars/')) vus.push(r.url());
  });
  return {
    vider: () => { vus.length = 0; },
    servie: () => vus.some((u) => u.includes(`/avatars/${ID.hakim}/`)
      && (!ID.cle || u.includes(ID.cle.split('/').pop()))),
    lire: () => vus.map((u) => u.replace(/\?.*$/, '').split('/sign/')[1]),
  };
}

async function attendre(c, delai = 20000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    if (c.servie()) return true;
    await new Promise((r) => setTimeout(r, 500));
  }
  return false;
}

async function vers(page, chemin, attente = 5000) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

async function toucher(page, motif, quoi, { delai = 10000, role } = {}) {
  const e = await trouver(page, motif, { delai, role });
  if (!e) throw new Error(`${quoi} absent ; ${await lus(page)}`);
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(2500);
  await activerSemantique(page);
}

/// Un ecran, lu a neuf dans sa propre session ouverte a la largeur voulue.
/// `attendue` : la photo de Hakim doit-elle etre servie ?
async function ecran(moment, nomVue, vue, qui, courriel, chemin, etiquette, attendue, cible) {
  const a = await p.contexte(`${qui}_${moment}_${nomVue}`, { vue });
  const c = capteur(a.page);
  await connecter(a.page, courriel);
  await vers(a.page, chemin, 6000);
  if (cible) {
    const e = await trouver(a.page, cible, { delai: 8000 });
    if (e) await amenerEnVue(a.page, e);
  }
  const vu = attendue ? await attendre(c) : (await a.page.waitForTimeout(4000), c.servie());
  const cle = `${moment}_${nomVue}_${etiquette}`;
  verdicts[cle] = vu === attendue;
  p.dire(`${cle} : URL signees ${JSON.stringify(c.lire())}${vu === attendue ? '' : ` ; ECART, ecran : ${await lus(a.page, 40)}`}`);
  await p.capture(a, `${moment}_${nomVue}_${etiquette}`);
  await a.ctx.close();
}

async function tour(moment, attendue) {
  for (const { nom, vue } of VUES) {
    await ecran(moment, nom, vue, 'enseignant', COMPTES.enseignant,
      `/enseignant/groupe/${ID.classe}`, 'enseignant_classe', attendue, /Hakim/);
    await ecran(moment, nom, vue, 'direction', COMPTES.direction,
      `/admin/personnes/comptes?vue=eleves&q=${ID.nomFamille}`, 'direction_comptes', attendue,
      new RegExp(`Hakim ${ID.nomFamille}`));
    await ecran(moment, nom, vue, 'tuteur', ID.courriel, '/tuteur', 'foyer_accueil', attendue, /Hakim/);
    await ecran(moment, nom, vue, 'tuteur', ID.courriel, `/tuteur/foyer/${ID.hakim}/informations`,
      'foyer_fiche', attendue);
    await ecran(moment, nom, vue, 'tuteur', ID.courriel, '/tuteur/suivi', 'foyer_suivi', attendue, /Hakim/);
  }
}

let code = 1;
try {
  amorcer();

  // 1. AVANT.
  await tour('avant', false);

  // 2. Le tuteur pose la photo, session ouverte a 390, apres Accueil et Suivi.
  const t = await p.contexte('tuteur_pose', { vue: VUES[0].vue });
  const ct = capteur(t.page);
  await connecter(t.page, ID.courriel);
  await vers(t.page, '/tuteur', 6000);
  await vers(t.page, '/tuteur/suivi', 5000);
  await vers(t.page, `/tuteur/foyer/${ID.hakim}/informations`, 5000);
  t.page.once('filechooser', (fc) => fc.setFiles(FICHIER));
  await toucher(t.page, /^Choisir une photo/, '« Choisir une photo » (Hakim)');
  await p.capture(t, 'pose_1_apercu');
  await toucher(t.page, /^Envoyer cette photo/, '« Envoyer cette photo »', { role: 'button' });
  await t.page.waitForTimeout(4000); await activerSemantique(t.page);
  ID.cle = sql(`select coalesce(avatar_storage_key, '') from public.student_profiles where profile_id = '${ID.hakim}'`);
  verdicts.poseEnBase = ID.cle.startsWith(`${ID.hakim}/`);
  verdicts.poseSansEchec = !/pas pu être envoyée/.test(await lus(t.page, 80));
  p.dire(`Photo de Hakim en base : « ${ID.cle} »`);
  await p.capture(t, 'pose_2_envoyee');
  // Sans vider le capteur : la fiche relit la source des l'envoi, et
  // l'Accueil (garde en vie par la coquille) reprend la meme URL, sans
  // nouvelle requete. La nouvelle cle servie dans CE document, puis l'Accueil
  // capture, sont la preuve.
  await vers(t.page, '/tuteur', 6000);
  verdicts.sansRecharger = await attendre(ct);
  p.dire(`Sans recharger, Accueil : URL signees ${JSON.stringify(ct.lire())}`);
  await p.capture(t, 'pose_3_accueil_sans_recharger');
  await t.ctx.close();

  // 3. APRES.
  await tour('apres', true);

  // 4. Salle, a 1440 : la tuile de Hakim chez l'enseignant.
  const se = await p.contexte('salle_enseignant', { vue: VUES[1].vue });
  const cse = capteur(se.page);
  await connecter(se.page, COMPTES.enseignant);
  await se.page.waitForTimeout(4000); await activerSemantique(se.page);
  await toucher(se.page, /^Rejoindre la salle/, '« Rejoindre la salle » (enseignant)', { role: 'button', delai: 15000 });
  await se.page.waitForTimeout(6000); await activerSemantique(se.page);
  const st = await p.contexte('salle_tuteur', { vue: VUES[1].vue });
  await connecter(st.page, ID.courriel);
  await st.page.waitForTimeout(4000); await activerSemantique(st.page);
  await toucher(st.page, /^Rejoindre la salle avec Hakim/, '« Rejoindre la salle avec Hakim »', { role: 'button', delai: 15000 });
  await st.page.waitForTimeout(8000);
  verdicts.salleEnseignantVoitHakim = await attendre(cse, 40000);
  p.dire(`Salle : enseignant URL ${JSON.stringify(cse.lire())}`);
  await p.capture(se, 'salle_1440_enseignant_voit_hakim');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  p.dire(`Constats : ${JSON.stringify(constats)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
