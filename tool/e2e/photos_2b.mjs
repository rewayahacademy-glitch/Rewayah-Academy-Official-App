// Lot PHOTOS-2b (04/11/2026, PLAN-LOTS §11) : la meme photo dans les ecrans
// qui restaient, et le Compte de l'enfant qui dit son prenom. Pile LOCALE
// seulement (jamais un apercu Vercel, jamais la production).
//
// Amorce (SQL local et stockage local, cle de service de la pile) : la photo
// de l'enseignant de test (seau photos_enseignants), un foyer, son enfant
// Hakim (avec un compte pour son appareil) et sa photo (seau avatars), une
// Classe de l'enseignant, une seance a venir et une seance passee.
// Puis par l'interface, chaque ecran demandant la photo signee au serveur
// (`photos_personnes`, puis une URL signee du bon seau) :
//   1. tuteur, Accueil : la carte de la Classe et de la seance, photo de
//      l'enseignant ;
//   2. tuteur, espace de la Classe : photo de l'enseignant ;
//   3. tuteur, Messages : il ecrit a l'enseignant ; la liste et le fil
//      montrent la photo de l'enseignant ;
//   4. enseignant, cahier de la seance passee : photo de Hakim (constat,
//      non bloquant : le cahier peut refuser une seance amorcee a la main) ;
//   5. appareil de Hakim, Compte : son prenom en tete, pas « Élève ».
// Le capteur : les reponses 200 d'URL signees (`/storage/v1/object/sign/`)
// par seau, relevees ecran par ecran.
// Les captures vont dans docs/current/captures/E2E/PHOTOS-2b/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/photos_2b.mjs (puis 390x844)
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, libelles, activerSemantique, amenerEnVue,
  attendreTexte, cliquer, taper, sql, COMPTES, MDP, DEPOT, API, TRAVAIL,
  nettoyerClassesE2E } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`PHOTOS-2b : la meme photo partout (${largeur} x ${hauteur})`,
  `PHOTOS-2b/${date}/${largeur}`);
const PHOTO = readFileSync(path.join(DEPOT, 'tool/e2e/piece_factice.png'));
const statut = Object.fromEntries(readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => {
    const i = l.indexOf('=');
    return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
  }));
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
const constats = {};
const lus = async (page, k = 80) => (await libelles(page)).slice(0, k).join(' | ');

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

/// Depose la photo factice dans le stockage LOCAL (cle de service de la pile).
async function deposer(seau, cle) {
  const r = await fetch(`${API}/storage/v1/object/${seau}/${cle}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${statut.SERVICE_ROLE_KEY}`, 'Content-Type': 'image/png',
      'x-upsert': 'true' },
    body: PHOTO,
  });
  if (!r.ok) throw new Error(`depot ${seau}/${cle} : ${r.status} ${await r.text()}`);
}

async function amorcer() {
  nettoyerClassesE2E();
  ID.prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.photoProfAvant = sql(`select coalesce(photo_storage_key, '') from public.teacher_profiles where profile_id = '${ID.prof}'`);
  ID.cleProf = `${ID.prof}/e2e-ph2b-${n}.png`;
  await deposer('photos_enseignants', ID.cleProf);
  sql(`update public.teacher_profiles set photo_storage_key = '${ID.cleProf}' where profile_id = '${ID.prof}'`);

  ID.courrielTuteur = `e2e-ph2b-tuteur-${n}@example.com`;
  ID.courrielHakim = `e2e-ph2b-hakim-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courrielTuteur);
  ID.hakim = creerCompte(ID.courrielHakim);
  ID.classe = sql('select gen_random_uuid()');
  ID.nom = `E2E Photos 2b ${n}`;
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-PH2B-T-${n}', 'guardian', '${ID.tuteur}', 'Samira', 'Photo${n}', 'active', 'female'),
      ('${ID.hakim}', 'E2E-PH2B-E-${n}', 'student', '${ID.tuteur}', 'Hakim', 'Photo${n}', 'active', 'male');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${ID.hakim}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, '${ID.nom}',
              extract(isodow from (now() at time zone 'Europe/Paris') + interval '2 days')::int, 9, 'Europe/Paris', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${ID.classe}', '${ID.hakim}', now() - interval '10 days');
    commit;`);
  ID.cleHakim = `${ID.hakim}/e2e-ph2b-${n}.png`;
  await deposer('avatars', ID.cleHakim);
  sql(`update public.student_profiles set avatar_storage_key = '${ID.cleHakim}' where profile_id = '${ID.hakim}'`);
  ID.seance = sql('select gen_random_uuid()');
  ID.passee = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) values
      ('${ID.seance}', '${ID.prof}', now() + interval '2 days', now() + interval '2 days 45 minutes', 'planned', 'child', '${ID.classe}'),
      ('${ID.passee}', '${ID.prof}', now() - interval '2 hours', now() - interval '75 minutes', 'ended', 'child', '${ID.classe}');
    insert into public.session_participants (session_id, profile_id, role) values
      ('${ID.seance}', '${ID.hakim}', 'student'), ('${ID.passee}', '${ID.hakim}', 'student');
    commit;`);
  p.dire(`Amorce : tuteur ${ID.courrielTuteur}, Hakim ${ID.hakim}, classe ${ID.classe} (${ID.nom}), `
    + `seances ${ID.seance} (a venir) et ${ID.passee} (passee), photo enseignant ${ID.cleProf}`);
}

/// Releve les URL signees servies (200) par seau, pour une page.
function capteur(page) {
  const vus = [];
  const tout = [];
  page.on('response', (r) => {
    const u = r.url();
    if (r.status() === 200 && u.includes('/storage/v1/object/sign/')) vus.push(u);
    if (u.includes('/storage/v1/') || u.includes('photos_personnes')) {
      tout.push(`${r.request().method()} ${r.status()} ${u.replace(/\?.*$/, '').split('/v1/')[1]}`);
    }
  });
  return {
    vider: () => { vus.length = 0; tout.length = 0; },
    journal: () => tout.slice(0, 30),
    servie: (seau, cle) => vus.some((u) => u.includes(`/sign/${seau}/`) && (!cle || u.includes(cle.split('/').pop()))),
    lire: () => vus.map((u) => u.replace(/\?.*$/, '').split('/sign/')[1]),
  };
}

async function vers(page, chemin, attente = 4500) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

async function recharger(page, chemin, attente = 6000) {
  // Un goto qui ne change que l'ancre ne recharge pas le document.
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.reload();
  await page.waitForSelector('flt-semantics-placeholder, flt-semantics', { state: 'attached', timeout: 60000 });
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

/// Attend qu'une URL signee du seau ait ete servie (le fournisseur lit,
/// puis signe ; l'image arrive apres).
async function attendrePhoto(c, seau, cle, delai = 20000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    if (c.servie(seau, cle)) return true;
    await new Promise((r) => setTimeout(r, 500));
  }
  return false;
}

let code = 1;
try {
  await amorcer();

  // 1-3. Le tuteur.
  const t = await p.contexte('tuteur', { vue });
  const ct = capteur(t.page);
  // Le tuteur arrive sur l'Accueil en se connectant : le capteur releve
  // depuis la connexion.
  await connecter(t.page, ID.courrielTuteur);
  await vers(t.page, '/tuteur');
  verdicts.accueilPhotoEnseignant = await attendrePhoto(ct, 'photos_enseignants', ID.cleProf);
  p.dire(`Accueil : URL signees ${JSON.stringify(ct.lire())} ; stockage ${JSON.stringify(ct.journal())}`);
  const carte = await trouver(t.page, new RegExp(ID.nom), { delai: 8000 });
  if (carte) await amenerEnVue(t.page, carte);
  await t.page.waitForTimeout(1500);
  await p.capture(t, '01_tuteur_accueil');

  // Chaque ecran est charge a neuf (rechargement) : le fournisseur relit la
  // photo, et le capteur la voit ; sinon l'URL deja signee sur l'Accueil
  // (branche gardee en vie par la coquille) serait reutilisee sans appel.
  ct.vider();
  await recharger(t.page, `/tuteur/classes/${ID.classe}?eleve=${ID.hakim}`);
  verdicts.espaceClassePhotoEnseignant = await attendrePhoto(ct, 'photos_enseignants', ID.cleProf);
  p.dire(`Espace de classe : URL signees ${JSON.stringify(ct.lire())} ; stockage ${JSON.stringify(ct.journal())}`);
  await p.capture(t, '02_tuteur_espace_classe');

  const MSG = `Bonjour, une question sur la sourate ${n}.`;
  await cliquer(t.page, /^Écrire à (Sayyid|Sayyida|E2E)/, { pause: 3000 });
  await taper(t.page, 'textarea', MSG);
  await cliquer(t.page, /^Envoyer$/, { pause: 2500 });
  verdicts.messageEnvoye = await attendreTexte(t.page, MSG, 15000);
  ct.vider();
  await recharger(t.page, '/tuteur/messages');
  verdicts.messagesPhotoEnseignant = await attendrePhoto(ct, 'photos_enseignants', ID.cleProf);
  p.dire(`Messages : URL signees ${JSON.stringify(ct.lire())} ; stockage ${JSON.stringify(ct.journal())} ; ecran : ${await lus(t.page, 30)}`);
  await p.capture(t, '03_tuteur_messages');

  // 4. L'enseignant, cahier de la seance passee (constat).
  const e = await p.contexte('enseignant', { vue });
  const ce = capteur(e.page);
  await connecter(e.page, COMPTES.enseignant);
  ce.vider();
  await vers(e.page, `/enseignant/seance/${ID.passee}/cahier`, 6000);
  const cahier = await lus(e.page, 60);
  constats.cahierPhotoHakim = await attendrePhoto(ce, 'avatars', ID.cleHakim, 15000);
  constats.cahierNommeHakim = cahier.includes('Hakim');
  p.dire(`Cahier : URL signees ${JSON.stringify(ce.lire())} ; ecran : ${cahier.slice(0, 500)}`);
  await p.capture(e, '04_enseignant_cahier');

  // 5. L'appareil de Hakim : son Compte.
  const h = await p.contexte('enfant', { vue });
  const ch = capteur(h.page);
  await connecter(h.page, ID.courrielHakim);
  ch.vider();
  await vers(h.page, '/compte', 6000);
  const compte = await lus(h.page, 40);
  p.dire(`Compte de Hakim : ${compte.slice(0, 400)} ; URL signees ${JSON.stringify(ch.lire())}`);
  // Chaque libelle est « role:texte » ; l'en-tete suit « Mon compte » et sa
  // phrase : le nom, puis le statut.
  const textes = compte.split(' | ').map((l) => l.slice(l.indexOf(':') + 1));
  const iTitre = textes.indexOf('Mon compte');
  verdicts.compteDitLePrenom = iTitre >= 0 && textes.slice(iTitre, iTitre + 4).includes('Hakim');
  verdicts.compteSansEleveEnTete = iTitre >= 0 && !textes.slice(iTitre, iTitre + 4).includes('Élève');
  constats.comptePhotoHakim = await attendrePhoto(ch, 'avatars', ID.cleHakim, 10000);
  await p.capture(h, '05_enfant_compte');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  p.dire(`Constats (non bloquants) : ${JSON.stringify(constats)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)} ; constats : ${JSON.stringify(constats)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
} finally {
  try {
    if (ID.prof && ID.photoProfAvant !== undefined) {
      sql(`update public.teacher_profiles set photo_storage_key = nullif('${ID.photoProfAvant}', '') where profile_id = '${ID.prof}'`);
    }
  } catch { /* pile arretee */ }
}
process.exit(code);
