// PHOTOS-2a (03/11/2026, PLAN-LOTS §11) : la meme photo partout, posee par le
// serveur, sur la pile LOCALE seulement (jamais un apercu, jamais la
// production).
//
// Ce que le robot montre, a 1440 x 900 puis 390 x 844 :
//   1. le tuteur (Samir) pose SA photo depuis son Compte (poser_ma_photo) ;
//   2. il pose celle de son enfant Hakim depuis sa fiche (poser_photo_eleve) ;
//      son ecriture directe de la cle, elle, est refusee (droit ferme,
//      migration 20261107400000) ;
//   3. l'enseignant voit les photos de Hakim et de Camil dans la fiche de la
//      Classe, et la sienne dans son Profil ;
//   4. la salle : l'enseignant et les deux enfants y sont ; Camil voit la
//      vignette de Hakim avec sa photo (K-44 : un camarade, dans sa propre
//      session) ;
//   5. l'appareil de Hakim : son Compte montre sa photo, sans « Changer ma
//      photo » (un mineur ne pose rien) ;
//   6. la direction pose la sienne depuis son Compte ;
//   7. une autre famille (Nadia) et le parent du camarade (Leila) ne lisent
//      ni la source ni le fichier de la photo de Hakim (appels du client,
//      sous leur propre jeton).
// Les envois se font a la premiere largeur ; la seconde relit les memes
// ecrans. Donnees fictives, matricules RA-26-xxxx. Rien n'est efface.
// Usage : node tool/e2e/photos_ecrans.mjs
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { parcours, connecter, cliquer, trouver, attendreTexte, activerSemantique,
  libelles, sql, nettoyerClassesE2E, API, COMPTES, MDP } from './commun.mjs';

const JOUR = new Date().toISOString().slice(0, 10);
const p = await parcours('PHOTOS-2a : la meme photo partout', 'photos-ecrans');
const contexteBrut = p.contexte;
p.contexte = async (...args) => {
  const a = await contexteBrut(...args);
  suivrePhotos(a.page);
  return a;
};
const n = Date.now() % 1000000;
const un = (requete) => sql(requete).split('\n')[0].trim();
const statut = Object.fromEntries(fs.readFileSync('/tmp/e2e-pile/statut.env', 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => {
    const i = l.indexOf('=');
    return [l.slice(0, i), l.slice(i + 1).replace(/^"|"$/g, '')];
  }));
const ANON = statut.ANON_KEY;
const SERVICE = statut.SERVICE_ROLE_KEY;
const ID = {};
const verdicts = {};

function verifier(condition, message) {
  verdicts[message] = !!condition;
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

function matricule() {
  for (;;) {
    const m = `RA-26-${String(1000 + Math.floor(Math.random() * 9000))}`;
    if (un(`select count(*) from public.profiles where immutable_id = '${m}'`) === '0') return m;
  }
}

function creerCompte(courriel) {
  return un(`with nouveau as (
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
  select id from nouveau`);
}

/// Un foyer : le tuteur et son enfant mineur, chacun avec son compte.
function foyer(cle, tuteur, genre, enfant) {
  const t = { courriel: `e2e-ph-${cle}-${n}@example.com` };
  const e = { courriel: `e2e-ph-${cle}-enf-${n}@example.com` };
  t.id = creerCompte(t.courriel);
  e.id = creerCompte(e.courriel);
  sql(`begin;
    insert into public.households (id, timezone) values ('${t.id}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
    values ('${t.id}', '${matricule()}', 'guardian', '${t.id}', '${tuteur}', 'E2E', 'active', '${genre}'),
           ('${e.id}', '${matricule()}', 'student', '${t.id}', '${enfant}', 'E2E', 'active', 'male');
    insert into public.student_profiles (profile_id, student_type, interface_mode)
    values ('${e.id}', 'minor', 'standard');
    update public.households set primary_guardian_id = '${t.id}' where id = '${t.id}';
    commit;`);
  return { tuteur: t, enfant: e };
}

/// Un portrait fictif (cercle de couleur et une lettre), rendu par Chromium.
async function portrait(lettre, couleur) {
  const f = path.join(os.tmpdir(), `e2e-photo-${lettre}-${n}.png`);
  const c = await p.navigateur.newContext({ viewport: { width: 400, height: 400 } });
  const pg = await c.newPage();
  await pg.setContent(`<body style="margin:0;background:${couleur};display:flex;
    align-items:center;justify-content:center;height:400px;font:bold 220px sans-serif;
    color:white">${lettre}</body>`);
  await pg.screenshot({ path: f });
  await c.close();
  return f;
}

/// Amorce : un fichier deja dans un seau (cle de service, pile locale).
async function deposer(seau, cle, fichier) {
  const r = await fetch(`${API}/storage/v1/object/${seau}/${cle}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${SERVICE}`, apikey: SERVICE, 'Content-Type': 'image/png' },
    body: fs.readFileSync(fichier),
  });
  if (!r.ok) throw new Error(`depot ${seau}/${cle} : ${r.status} ${await r.text()}`);
}

/// Le jeton d'un compte, comme le client l'obtient.
async function jeton(courriel) {
  const r = await fetch(`${API}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: ANON, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: courriel, password: MDP }),
  });
  const j = await r.json();
  if (!j.access_token) throw new Error(`jeton ${courriel} : ${JSON.stringify(j).slice(0, 200)}`);
  return j.access_token;
}

async function client(courriel, chemin, init = {}) {
  const t = await jeton(courriel);
  const r = await fetch(`${API}${chemin}`, {
    ...init,
    headers: { apikey: ANON, Authorization: `Bearer ${t}`, 'Content-Type': 'application/json',
      ...(init.headers ?? {}) },
  });
  return { statut: r.status, corps: await r.text() };
}

async function amorcer() {
  nettoyerClassesE2E();
  const samir = foyer('samir', 'Samir', 'male', 'Hakim');
  const leila = foyer('leila', 'Leila', 'female', 'Camil');
  const nadia = foyer('nadia', 'Nadia', 'female', 'Omar');
  Object.assign(ID, { samir: samir.tuteur, hakim: samir.enfant, leila: leila.tuteur,
    camil: leila.enfant, nadia: nadia.tuteur, omar: nadia.enfant });
  ID.prof = un(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  ID.direction = un(`select id from auth.users where email = '${COMPTES.direction}'`);
  ID.nom = `E2E Photos An-Nour ${n}`;
  ID.classe = un(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${ID.prof}', 'enfant', 5, '${ID.nom}',
            date_part('isodow', now() at time zone 'UTC' + interval '3 days')::smallint, 9, 'UTC')
    returning id`);
  sql(`insert into public.groupe_membres (groupe_id, student_id) values
       ('${ID.classe}', '${ID.hakim.id}'), ('${ID.classe}', '${ID.camil.id}')`);
  ID.seance = un(`insert into public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at, status)
    values ('${ID.prof}', now() - interval '5 minutes', now() + interval '55 minutes', 'child',
            '${ID.classe}', now() - interval '25 minutes', 'planned') returning id`);
  sql(`insert into public.session_participants (session_id, profile_id, role) values
       ('${ID.seance}', '${ID.hakim.id}', 'student'), ('${ID.seance}', '${ID.camil.id}', 'student')
       on conflict do nothing`);
  // Camil et l'enseignant ont deja une photo (amorce) ; celles de Samir, de
  // Hakim et de la direction sont posees par l'application, plus bas.
  ID.fichiers = {
    samir: await portrait('S', '#2f6f5e'),
    hakim: await portrait('H', '#8a3b2e'),
    direction: await portrait('D', '#3a4a8a'),
  };
  const camil = `${ID.camil.id}/amorce.png`;
  await deposer('avatars', camil, await portrait('C', '#7a5a1e'));
  sql(`update public.student_profiles set avatar_storage_key = '${camil}' where profile_id = '${ID.camil.id}'`);
  const prof = `${ID.prof}/amorce-${n}.png`;
  await deposer('photos_enseignants', prof, await portrait('E', '#4b2e6f'));
  sql(`update public.teacher_profiles set photo_storage_key = '${prof}' where profile_id = '${ID.prof}'`);
  p.dire(`Amorce : classe ${ID.nom} (${ID.classe}), seance ${ID.seance} ; Samir ${ID.samir.id}, `
    + `Hakim ${ID.hakim.id}, Leila ${ID.leila.id}, Camil ${ID.camil.id}, Nadia ${ID.nadia.id}, Omar ${ID.omar.id}`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(4000);
  await activerSemantique(page);
}

/// Les photos que la page a chargees (CanvasKit les dessine sur un canevas,
/// sans balise <img> : on les lit au reseau). Chaque GET d'une URL signee d'un
/// seau de photos, servi en 200, est retenu pour le contexte du role (neuf
/// pour chaque role) : Flutter garde une image deja chargee dans son cache, et
/// ne la redemande pas en changeant d'ecran.
const charges = new WeakMap();
function suivrePhotos(page) {
  const vues = new Set();
  charges.set(page, vues);
  page.on('response', (r) => {
    const u = r.url();
    if (r.request().method() === 'GET' && r.status() === 200
        && /\/storage\/v1\/object\/sign\/(avatars|photos_enseignants)\//.test(u)) {
      vues.add(u.replace(/^.*\/sign\//, '').replace(/\?.*$/, ''));
    }
  });
}
async function photosVues(page) {
  await page.waitForTimeout(1500);
  return [...(charges.get(page) ?? [])];
}

/// Choisir le fichier, l'envoyer, attendre la phrase de reussite.
async function envoyerPhoto(page, fichier, choisir = /^(Choisir une photo|Changer la photo)$/) {
  const [selecteur] = await Promise.all([
    page.waitForEvent('filechooser', { timeout: 20000 }),
    cliquer(page, choisir, { pause: 500 }),
  ]);
  await selecteur.setFiles(fichier);
  await page.waitForTimeout(2500);
  await activerSemantique(page);
  await cliquer(page, /^Envoyer cette photo$/, { pause: 4000 });
  return attendreTexte(page, 'La photo est enregistrée.', 20000);
}

async function passage(largeur, hauteur) {
  const vue = { width: largeur, height: hauteur };
  const tag = `${JOUR}_${largeur}`;
  const premiere = largeur === 1440;

  // 1 et 2. Le tuteur : sa photo, puis celle de Hakim.
  const s = await p.contexte('tuteur_samir', { vue });
  await connecter(s.page, ID.samir.courriel);
  await vers(s.page, '/tuteur/compte');
  if (premiere) {
    await cliquer(s.page, /^Changer ma photo$/, { pause: 2500 });
    verifier(await envoyerPhoto(s.page, ID.fichiers.samir), 'le tuteur pose sa photo (poser_ma_photo)');
    await s.page.keyboard.press('Escape');
    await s.page.waitForTimeout(2500);
    verifier(un(`select photo_storage_key from public.profiles where id = '${ID.samir.id}'`)
      .startsWith(`${ID.samir.id}/`), 'sa cle est dans son dossier (profiles.photo_storage_key)');
  }
  await p.capture(s, `${tag}_1_compte_tuteur`);
  await vers(s.page, `/tuteur/foyer/${ID.hakim.id}/informations`);
  if (premiere) {
    verifier(await envoyerPhoto(s.page, ID.fichiers.hakim), 'le tuteur pose la photo de Hakim (poser_photo_eleve)');
    verifier(un(`select avatar_storage_key from public.student_profiles where profile_id = '${ID.hakim.id}'`)
      .startsWith(`${ID.hakim.id}/`), 'la cle de Hakim est dans son dossier');
    const direct = await client(ID.samir.courriel,
      `/rest/v1/student_profiles?profile_id=eq.${ID.hakim.id}`,
      { method: 'PATCH', body: JSON.stringify({ avatar_storage_key: `${ID.hakim.id}/direct.png` }) });
    p.dire(`  ecriture directe du tuteur : HTTP ${direct.statut} ${direct.corps.slice(0, 160)}`);
    verifier(direct.statut >= 400 && /42501|permission denied/.test(direct.corps),
      'ecriture directe de la cle refusee (droit 0005 ferme)');
  }
  await p.capture(s, `${tag}_2_fiche_hakim`);
  verifier((await photosVues(s.page)).some((x) => x.includes(ID.hakim.id)), `${largeur} : la fiche montre la photo de Hakim`);
  await s.ctx.close();

  // 3. L'enseignant : la fiche de la Classe, puis son Profil.
  const e = await p.contexte('enseignant', { vue });
  await connecter(e.page, COMPTES.enseignant);
  await vers(e.page, `/enseignant/groupe/${ID.classe}`);
  await attendreTexte(e.page, 'Camil', 20000);
  await e.page.waitForTimeout(2500);
  const classe = await photosVues(e.page);
  p.dire(`  ${largeur} enseignant, fiche de la Classe : ${classe.join(' | ')}`);
  await p.capture(e, `${tag}_3_fiche_classe`);
  verifier(classe.some((x) => x.includes(ID.hakim.id)) && classe.some((x) => x.includes(ID.camil.id)),
    `${largeur} : l'enseignant voit les photos de Hakim et de Camil`);
  await vers(e.page, '/enseignant/profil');
  await e.page.waitForTimeout(2000);
  await p.capture(e, `${tag}_4_profil_enseignant`);
  verifier((await photosVues(e.page)).some((x) => x.startsWith(`photos_enseignants/${ID.prof}/`)),
    `${largeur} : le Profil de l'enseignant montre sa photo`);

  // 4. La salle (une fois, a la premiere largeur) : l'enseignant, puis Hakim
  // et Camil ; Camil voit la vignette de Hakim.
  if (premiere) {
    await vers(e.page, '/enseignant/journee');
    const rejoindre = await trouver(e.page, new RegExp(`^Rejoindre la salle.*${ID.nom}`), { delai: 20000 });
    if (rejoindre) {
      await rejoindre.click();
      await e.page.waitForTimeout(9000);
      await activerSemantique(e.page);
    }
    p.dire(`  enseignant, salle : ${rejoindre ? 'entre' : 'pas de « Rejoindre la salle »'}`);
    const enfants = [];
    for (const [nom, compte] of [['hakim', ID.hakim], ['camil', ID.camil]]) {
      const c = await p.contexte(`eleve_${nom}`, { vue });
      await connecter(c.page, compte.courriel);
      const r = await trouver(c.page, /^Rejoindre/, { delai: 20000 });
      p.dire(`  ${nom} : ${r ? await r.getAttribute('aria-label') : `pas de « Rejoindre » ; ${(await libelles(c.page)).slice(0, 15).join(' | ')}`}`);
      if (r) { await r.click(); await c.page.waitForTimeout(9000); await activerSemantique(c.page); }
      enfants.push(c);
    }
    await p.capture(e, `${tag}_5_salle_enseignant`);
    p.dire(`  enseignant, photos en salle : ${(await photosVues(e.page)).join(' | ') || 'aucune'}`);
    const vuesCamil = await photosVues(enfants[1].page);
    p.dire(`  Camil, photos en salle : ${vuesCamil.join(' | ') || 'aucune'}`);
    await p.capture(enfants[1], `${tag}_6_salle_camarade`);
    verdicts['salle : Camil voit la photo de Hakim'] = vuesCamil.some((x) => x.includes(ID.hakim.id));
    p.dire(`  ${verdicts['salle : Camil voit la photo de Hakim'] ? 'OK' : 'NON PROUVE'} salle : Camil voit la photo de Hakim`);
    for (const c of enfants) await c.ctx.close();
  }
  await e.ctx.close();

  // 5. L'appareil de Hakim : son Compte.
  const h = await p.contexte('eleve_hakim', { vue });
  await connecter(h.page, ID.hakim.courriel);
  await vers(h.page, '/compte');
  await h.page.waitForTimeout(2000);
  await p.capture(h, `${tag}_7_compte_hakim`);
  verifier((await photosVues(h.page)).some((x) => x.includes(ID.hakim.id)), `${largeur} : Hakim voit sa photo sur son appareil`);
  verifier(!(await trouver(h.page, /^Changer ma photo$/, { delai: 3000 })),
    `${largeur} : aucun « Changer ma photo » pour un mineur`);
  await h.ctx.close();

  // 6. La direction : sa photo depuis son Compte.
  const d = await p.contexte('direction', { vue });
  await connecter(d.page, COMPTES.direction);
  await vers(d.page, '/compte');
  if (premiere) {
    await cliquer(d.page, /^Changer ma photo$/, { pause: 2500 });
    verifier(await envoyerPhoto(d.page, ID.fichiers.direction), 'la direction pose sa photo');
    await d.page.keyboard.press('Escape');
    await d.page.waitForTimeout(2500);
  }
  await p.capture(d, `${tag}_8_compte_direction`);
  verifier((await photosVues(d.page)).some((x) => x.includes(ID.direction)), `${largeur} : le Compte de la direction montre sa photo`);
  await d.ctx.close();

  // 7. Ni une autre famille, ni le parent du camarade.
  if (premiere) {
    const cleHakim = un(`select avatar_storage_key from public.student_profiles where profile_id = '${ID.hakim.id}'`);
    for (const [qui, compte] of [['Nadia (autre famille)', ID.nadia], ['Leila (parent du camarade)', ID.leila]]) {
      const source = await client(compte.courriel, '/rest/v1/rpc/photos_personnes',
        { method: 'POST', body: JSON.stringify({ p_ids: [ID.hakim.id] }) });
      const fichier = await client(compte.courriel, `/storage/v1/object/sign/avatars/${cleHakim}`,
        { method: 'POST', body: JSON.stringify({ expiresIn: 60 }) });
      p.dire(`  ${qui} : photos_personnes HTTP ${source.statut} ${source.corps} ; URL signee HTTP ${fichier.statut} ${fichier.corps.slice(0, 120)}`);
      verifier(source.statut === 200 && source.corps.trim() === '[]', `${qui} ne lit pas la source de Hakim`);
      verifier(fichier.statut >= 400, `${qui} n'obtient pas le fichier de Hakim`);
    }
    const n2 = await p.contexte('tuteur_nadia', { vue });
    await connecter(n2.page, ID.nadia.courriel);
    await vers(n2.page, '/tuteur/compte');
    await p.capture(n2, `${tag}_9_compte_autre_famille`);
    verifier(!(await photosVues(n2.page)).some((x) => x.includes(ID.hakim.id)),
      'aucune photo de Hakim chez une autre famille');
    await n2.ctx.close();
  }
}

let code = 1;
try {
  await amorcer();
  await passage(1440, 900);
  await passage(390, 844);
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  code = await p.fin('vert');
} catch (err) {
  p.dire(String(err?.stack ?? err));
  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err?.message ?? err).slice(0, 300));
}
process.exit(code);
