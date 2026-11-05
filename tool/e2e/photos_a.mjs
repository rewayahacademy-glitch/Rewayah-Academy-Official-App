// Lot PHOTOS-A (garde-cap, 04/11/2026) : tout portrait de l'enseignant et de
// la salle lit `photoPersonneProvider(id)`. Pile LOCALE seulement (jamais un
// apercu Vercel, jamais la production).
//
// Amorce (SQL local et stockage local, cle de service de la pile) : la photo
// de l'enseignant de test est retiree (remise a la fin), un foyer et son
// enfant Hakim (photo dans le seau avatars), une Classe de l'enseignant et
// une seance qui a commence il y a deux minutes.
// Puis par l'interface :
//   1. AVANT, a 390 et 1440, en francais et en arabe : Accueil du tuteur
//      (carte de la Classe) et Classes de l'enseignant (sa carte) ; aucune
//      URL signee du seau photos_enseignants n'est servie (initiales) ;
//   2. l'enseignant pose sa photo (Profil, « Choisir une photo »,
//      « Utiliser cette photo ») ; la base porte la cle ;
//   3. SANS recharger, il revient a ses Classes : l'URL signee de la nouvelle
//      cle est servie (la source unique a ete relue) ;
//   4. APRES, les memes ecrans et langues : l'URL signee est servie ;
//   5. salle (francais, a 390 puis 1440) : l'enseignant rejoint, le tuteur
//      rejoint avec Hakim, cameras eteintes ; le tuteur recoit la photo de
//      l'enseignant, l'enseignant celle de Hakim.
// Le capteur : les reponses 200 d'URL signees (`/storage/v1/object/sign/`).
// Captures : docs/current/captures/E2E/PHOTOS-A/<date>/.
//
// Usage : node tool/e2e/photos_a.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { parcours, connecter, trouver, libelles, activerSemantique, amenerEnVue,
  attendreTexte, sql, COMPTES, MDP, DEPOT, API, TRAVAIL,
  nettoyerClassesE2E } from './commun.mjs';

const date = new Date().toISOString().slice(0, 10);
const p = await parcours('PHOTOS-A : la photo de l\'enseignant et de la salle, par l\'id',
  `PHOTOS-A/${date}`);
const FICHIER = path.join(DEPOT, 'tool/e2e/portrait_factice.png');
const PHOTO = readFileSync(FICHIER);
const statut = Object.fromEntries(readFileSync(path.join(TRAVAIL, 'statut.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => {
    const i = l.indexOf('=');
    return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
  }));
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 } },
  { nom: '1440', vue: { width: 1440, height: 900 } },
];
const LANGUES = [
  { code: 'fr', langue: 'fr-FR' },
  { code: 'ar', langue: 'ar-SA' },
];
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
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
  sql(`update public.teacher_profiles set photo_storage_key = null where profile_id = '${ID.prof}'`);
  ID.courrielTuteur = `e2e-pha-tuteur-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courrielTuteur);
  ID.hakim = creerCompte(`e2e-pha-hakim-${n}@example.com`);
  ID.classe = sql('select gen_random_uuid()');
  ID.nom = `E2E Photos A ${n}`;
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-PHA-T-${n}', 'guardian', '${ID.tuteur}', 'Samira', 'Photo${n}', 'active', 'female'),
      ('${ID.hakim}', 'E2E-PHA-E-${n}', 'student', '${ID.tuteur}', 'Hakim', 'Photo${n}', 'active', 'male');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${ID.hakim}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${ID.classe}', '${ID.prof}', 'enfant', 5, '${ID.nom}',
              extract(isodow from (now() at time zone 'Europe/Paris'))::int, 9, 'Europe/Paris', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${ID.classe}', '${ID.hakim}', now() - interval '10 days');
    commit;`);
  ID.cleHakim = `${ID.hakim}/e2e-pha-${n}.png`;
  await deposer('avatars', ID.cleHakim);
  sql(`update public.student_profiles set avatar_storage_key = '${ID.cleHakim}' where profile_id = '${ID.hakim}'`);
  ID.seance = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) values
      ('${ID.seance}', '${ID.prof}', now() - interval '2 minutes', now() + interval '43 minutes', 'planned', 'child', '${ID.classe}');
    insert into public.session_participants (session_id, profile_id, role) values ('${ID.seance}', '${ID.hakim}', 'student');
    commit;`);
  p.dire(`Amorce : tuteur ${ID.courrielTuteur}, Hakim ${ID.hakim}, classe ${ID.classe} (${ID.nom}), `
    + `seance ${ID.seance}, photo de l'enseignant retiree (avant : « ${ID.photoProfAvant} »)`);
}

function capteur(page) {
  const vus = [];
  page.on('response', (r) => {
    const u = r.url();
    if (r.status() === 200 && u.includes('/storage/v1/object/sign/')) vus.push(u);
  });
  return {
    vider: () => { vus.length = 0; },
    servie: (seau, cle) => vus.some((u) => u.includes(`/sign/${seau}/`)
      && (!cle || u.includes(cle.split('/').pop()))),
    lire: () => vus.map((u) => u.replace(/\?.*$/, '').split('/sign/')[1]),
  };
}

async function attendrePhoto(c, seau, cle, delai = 20000) {
  const fin = Date.now() + delai;
  while (Date.now() < fin) {
    if (c.servie(seau, cle)) return true;
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
  if (!e) throw new Error(`${quoi} absent ; ${await lus(page, 60)}`);
  await amenerEnVue(page, e);
  await e.click();
  await page.waitForTimeout(2000);
  await activerSemantique(page);
}

/// Les ecrans d'une famille et de l'enseignant, pour une vue et une langue.
/// `attendue` : la photo de l'enseignant doit-elle etre servie ?
async function ecrans(moment, attendue) {
  for (const { nom, vue } of VUES) {
    for (const { code, langue } of LANGUES) {
      const etiquette = `${moment}_${nom}_${code}`;
      const t = await p.contexte(`tuteur_${etiquette}`, { vue, langue });
      const ct = capteur(t.page);
      await connecter(t.page, ID.courrielTuteur);
      await vers(t.page, '/tuteur', 6000);
      const carte = await trouver(t.page, new RegExp(ID.nom), { delai: 8000 });
      if (carte) await amenerEnVue(t.page, carte);
      const vuT = attendue ? await attendrePhoto(ct, 'photos_enseignants', ID.cleProf)
        : (await t.page.waitForTimeout(4000), ct.servie('photos_enseignants'));
      verdicts[`${etiquette}_tuteur`] = vuT === attendue;
      p.dire(`${etiquette}, tuteur Accueil : URL signees ${JSON.stringify(ct.lire())}`);
      await p.capture(t, `${etiquette}_tuteur_accueil`);
      await t.ctx.close();

      const e = await p.contexte(`enseignant_${etiquette}`, { vue, langue });
      const ce = capteur(e.page);
      await connecter(e.page, COMPTES.enseignant);
      await vers(e.page, '/enseignant/classes', 6000);
      const carteE = await trouver(e.page, new RegExp(ID.nom), { delai: 8000 });
      if (carteE) await amenerEnVue(e.page, carteE);
      const vuE = attendue ? await attendrePhoto(ce, 'photos_enseignants', ID.cleProf)
        : (await e.page.waitForTimeout(4000), ce.servie('photos_enseignants'));
      verdicts[`${etiquette}_enseignant`] = vuE === attendue;
      p.dire(`${etiquette}, enseignant Classes : URL signees ${JSON.stringify(ce.lire())}`);
      await p.capture(e, `${etiquette}_enseignant_classes`);
      await e.ctx.close();
    }
  }
}

let code = 1;
try {
  await amorcer();

  // 1. AVANT.
  await ecrans('avant', false);

  // 2-3. L'enseignant pose sa photo, puis revient a ses Classes sans recharger.
  const e = await p.contexte('enseignant_pose', { vue: VUES[1].vue });
  const ce = capteur(e.page);
  await connecter(e.page, COMPTES.enseignant);
  await vers(e.page, '/enseignant/classes', 6000);
  await vers(e.page, '/enseignant/profil', 5000);
  await toucher(e.page, /^Choisir une photo/, '« Choisir une photo » (Profil)');
  e.page.once('filechooser', (fc) => fc.setFiles(FICHIER));
  await toucher(e.page, /^Choisir une photo/, '« Choisir une photo » (feuille)', { role: 'button' });
  await e.page.waitForTimeout(2500); await activerSemantique(e.page);
  await p.capture(e, 'pose_1_apercu');
  await toucher(e.page, /^Utiliser cette photo/, '« Utiliser cette photo »', { role: 'button' });
  verdicts.poseConfirmee = await attendreTexte(e.page, 'La photo est enregistrée.', 20000);
  ID.cleProf = sql(`select coalesce(photo_storage_key, '') from public.teacher_profiles where profile_id = '${ID.prof}'`);
  verdicts.cleEnBase = ID.cleProf.length > 0;
  p.dire(`Photo de l'enseignant en base : « ${ID.cleProf} »`);
  await p.capture(e, 'pose_2_enregistree');
  await e.page.keyboard.press('Escape');
  ce.vider();
  const urlAvant = e.page.url();
  await vers(e.page, '/enseignant/classes', 6000);
  const carteE = await trouver(e.page, new RegExp(ID.nom), { delai: 8000 });
  if (carteE) await amenerEnVue(e.page, carteE);
  verdicts.sansRecharger = await attendrePhoto(ce, 'photos_enseignants', ID.cleProf);
  p.dire(`Sans recharger (${urlAvant} -> ${e.page.url()}) : URL signees ${JSON.stringify(ce.lire())}`);
  await p.capture(e, 'pose_3_classes_sans_recharger');

  // 4. APRES.
  await ecrans('apres', true);

  // 5. Salle.
  for (const { nom, vue } of VUES) {
    const se = await p.contexte(`salle_enseignant_${nom}`, { vue });
    const cse = capteur(se.page);
    await connecter(se.page, COMPTES.enseignant);
    await se.page.waitForTimeout(4000); await activerSemantique(se.page);
    await toucher(se.page, new RegExp(`^Rejoindre la salle de la Classe ${ID.nom}|^Rejoindre la salle`),
      '« Rejoindre la salle » (enseignant)', { role: 'button', delai: 15000 });
    await se.page.waitForTimeout(6000); await activerSemantique(se.page);
    const st = await p.contexte(`salle_tuteur_${nom}`, { vue });
    const cst = capteur(st.page);
    await connecter(st.page, ID.courrielTuteur);
    await st.page.waitForTimeout(4000); await activerSemantique(st.page);
    await toucher(st.page, /^Rejoindre la salle avec Hakim/, '« Rejoindre la salle avec Hakim »',
      { role: 'button', delai: 15000 });
    await st.page.waitForTimeout(8000); await activerSemantique(st.page);
    verdicts[`salle_${nom}_tuteurVoitEnseignant`] = await attendrePhoto(cst, 'photos_enseignants', ID.cleProf, 30000);
    // La liste des presents de l'enseignant est relue toutes les 20 s.
    verdicts[`salle_${nom}_enseignantVoitHakim`] = await attendrePhoto(cse, 'avatars', ID.cleHakim, 40000);
    await se.page.waitForTimeout(2000);
    p.dire(`Salle ${nom} : enseignant URL ${JSON.stringify(cse.lire())} ; ecran ${await lus(se.page, 30)}`);
    p.dire(`Salle ${nom} : tuteur URL ${JSON.stringify(cst.lire())} ; ecran ${await lus(st.page, 30)}`);
    await p.capture(se, `salle_${nom}_enseignant_voit_hakim`);
    await p.capture(st, `salle_${nom}_tuteur_voit_enseignant`);
    await st.ctx.close();
    await se.ctx.close();
  }

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
} finally {
  try {
    if (ID.prof && ID.photoProfAvant !== undefined) {
      sql(`update public.teacher_profiles set photo_storage_key = nullif('${ID.photoProfAvant}', '') where profile_id = '${ID.prof}'`);
    }
  } catch { /* pile arretee */ }
}
process.exit(code);
