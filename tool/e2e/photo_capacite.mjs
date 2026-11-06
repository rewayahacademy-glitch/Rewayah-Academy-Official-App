// Lot PHOTO-CAPACITE (04/11/2026) : « Choisir une photo » ne se propose qu'a
// qui peut poser sa photo, selon la regle du serveur (`photo_adulte_moi()`,
// celle de `poser_ma_photo`). Pile LOCALE seulement.
//
// Amorce (SQL local) : un tuteur (adulte) et deux enfants mineurs : Hakim
// **hors Interface guidee** (interface_mode = standard, le cas que la version
// precedente laissait faux) et Yasmine en Interface guidee (child).
// Puis :
//   1. base, sous le jeton de chacun : photo_adulte_moi() vaut vrai pour le
//      tuteur, faux pour les deux enfants ; poser_ma_photo leur est refusee ;
//   2. le tuteur (adulte) ouvre son Compte : « Choisir une photo » est la ;
//   3. Yasmine (Interface guidee) ouvre son Compte : le lien n'y est pas ;
//   4. Hakim (hors Interface guidee) ouvre son Compte : le lien n'y est pas.
// Captures : docs/current/captures/E2E/PHOTO-CAPACITE/<date>/<largeur>.
//
// Usage : E2E_VUE=1440x900 node tool/e2e/photo_capacite.mjs (puis 390x844)
import { parcours, connecter, libelles, activerSemantique, sql, MDP,
  nettoyerClassesE2E } from './commun.mjs';

const [largeur, hauteur] = (process.env.E2E_VUE ?? '1440x900').split('x').map(Number);
const vue = { width: largeur, height: hauteur };
const date = new Date().toISOString().slice(0, 10);
const p = await parcours(`PHOTO-CAPACITE : le lien selon le serveur (${largeur} x ${hauteur})`,
  `PHOTO-CAPACITE/${date}/${largeur}`);
const n = Date.now() % 1000000;
const ID = {};
const verdicts = {};
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

/// Une requete sous le jeton d'une personne (role authenticated).
function sousJeton(uid, role, foyer, requete) {
  const jwt = JSON.stringify({ sub: uid, role: 'authenticated',
    app_metadata: { role, ...(foyer ? { household_id: foyer } : {}) } });
  return sql(`begin;
    select set_config('request.jwt.claims', '${jwt}', true);
    select set_config('request.jwt.claim.sub', '${uid}', true);
    set local role authenticated;
    ${requete};
    commit;`).split('\n').filter((l) => l !== '' && l !== 'BEGIN' && l !== 'COMMIT' && l !== 'SET').pop();
}

async function vers(page, chemin, attente = 6000) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(attente);
  await activerSemantique(page);
}

let code = 1;
try {
  nettoyerClassesE2E();
  ID.courrielTuteur = `e2e-pc-tuteur-${n}@example.com`;
  ID.courrielHakim = `e2e-pc-hakim-${n}@example.com`;
  ID.tuteur = creerCompte(ID.courrielTuteur);
  ID.hakim = creerCompte(ID.courrielHakim);
  ID.courrielYasmine = `e2e-pc-yasmine-${n}@example.com`;
  ID.yasmine = creerCompte(ID.courrielYasmine);
  sql(`begin;
    insert into public.households (id, timezone) values ('${ID.tuteur}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${ID.tuteur}', 'E2E-PC-T-${n}', 'guardian', '${ID.tuteur}', 'Samira', 'Capacite${n}', 'active', 'female'),
      ('${ID.hakim}', 'E2E-PC-E-${n}', 'student', '${ID.tuteur}', 'Hakim', 'Capacite${n}', 'active', 'male'),
      ('${ID.yasmine}', 'E2E-PC-Y-${n}', 'student', '${ID.tuteur}', 'Yasmine', 'Capacite${n}', 'active', 'female');
    update public.households set primary_guardian_id = '${ID.tuteur}' where id = '${ID.tuteur}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values
      ('${ID.hakim}', 'minor', 'standard'), ('${ID.yasmine}', 'minor', 'child');
    commit;`);
  p.dire(`Amorce : tuteur ${ID.courrielTuteur}, Hakim ${ID.hakim} (mineur, interface standard), Yasmine ${ID.yasmine} (mineure, Interface guidee)`);

  // 1. La regle du serveur, sous le jeton de chacun.
  const capTuteur = sousJeton(ID.tuteur, 'guardian', ID.tuteur, 'select public.photo_adulte_moi()');
  const capHakim = sousJeton(ID.hakim, 'student', ID.tuteur, 'select public.photo_adulte_moi()');
  const capYasmine = sousJeton(ID.yasmine, 'student', ID.tuteur, 'select public.photo_adulte_moi()');
  let refus = '';
  try {
    sousJeton(ID.hakim, 'student', ID.tuteur, `select * from public.poser_ma_photo('${ID.hakim}/x.png')`);
  } catch (e) { refus = String(e.message ?? e).match(/ERROR:[^\n]*/)?.[0] ?? String(e).slice(0, 160); }
  p.dire(`Base : photo_adulte_moi() tuteur=${capTuteur}, Hakim=${capHakim} ; poser_ma_photo (Hakim) : ${refus || 'acceptee'}`);
  verdicts.baseTuteurPeut = capTuteur === 't';
  verdicts.baseHakimNePeutPas = capHakim === 'f';
  verdicts.baseYasmineNePeutPas = capYasmine === 'f';
  p.dire(`Base : photo_adulte_moi() Yasmine=${capYasmine}`);
  verdicts.baseRefusePoserHakim = /mineur/.test(refus);
  ID.modeHakim = sql(`select interface_mode from public.student_profiles where profile_id = '${ID.hakim}'`);
  ID.modeYasmine = sql(`select interface_mode from public.student_profiles where profile_id = '${ID.yasmine}'`);
  p.dire(`Interface en base : Hakim ${ID.modeHakim}, Yasmine ${ID.modeYasmine}`);
  verdicts.hakimHorsInterfaceGuidee = ID.modeHakim === 'standard';
  verdicts.yasmineEnInterfaceGuidee = ID.modeYasmine === 'child';

  // 2. Le tuteur : le lien est la.
  const t = await p.contexte('tuteur', { vue });
  await connecter(t.page, ID.courrielTuteur);
  await vers(t.page, '/tuteur/compte');
  const compteTuteur = await lus(t.page);
  p.dire(`Compte du tuteur : ${compteTuteur.slice(0, 400)}`);
  verdicts.tuteurVoitChoisir = compteTuteur.includes('Choisir une photo');
  await p.capture(t, '01_tuteur_compte');

  // 3. Yasmine, en Interface guidee : le lien n'y est pas.
  const y = await p.contexte('enfant', { vue });
  await connecter(y.page, ID.courrielYasmine);
  await vers(y.page, '/compte');
  const compteYasmine = await lus(y.page);
  p.dire(`Compte de Yasmine : ${compteYasmine.slice(0, 400)}`);
  verdicts.yasmineCompteOuvert = compteYasmine.includes('Yasmine');
  verdicts.yasmineSansChoisir = !compteYasmine.includes('Choisir une photo');
  await p.capture(y, '02_enfant_compte_interface_guidee');
  await y.ctx.close();

  // 4. Hakim, hors Interface guidee : le lien n'y est pas.
  const h = await p.contexte('enfant', { vue });
  await connecter(h.page, ID.courrielHakim);
  await vers(h.page, '/compte');
  const compteHakim = await lus(h.page);
  p.dire(`Compte de Hakim : ${compteHakim.slice(0, 400)}`);
  verdicts.hakimCompteOuvert = compteHakim.includes('Hakim');
  verdicts.hakimSansChoisir = !compteHakim.includes('Choisir une photo');
  await p.capture(h, '03_enfant_compte_hors_interface_guidee');

  p.dire(`Verdicts : ${JSON.stringify(verdicts)}`);
  const ok = Object.values(verdicts).every((v) => v === true);
  code = await p.fin(ok ? 'vert' : 'rouge', ok ? '' : JSON.stringify(verdicts));
} catch (err) {
  p.dire(`Verdicts partiels : ${JSON.stringify(verdicts)}`);
  code = await p.fin('rouge', String(err).slice(0, 400));
}
process.exit(code);
