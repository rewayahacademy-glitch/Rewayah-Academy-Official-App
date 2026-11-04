// FUSEAUX (04/11/2026) : la meme seance vue par un tuteur a Paris et par un
// enseignant a Abidjan, sur la pile LOCALE, par l'interface (R3, fiche §12 et
// garde-cap).
//
// Ce que le parcours prouve, a 390 et a 1440, en francais puis en arabe :
//   1. base : horloge_interlocuteurs rend au tuteur l'enseignant a Abidjan, et
//      a l'enseignant le fuseau de la famille, sans nom ;
//   2. le tuteur : Accueil et fiche de la classe, « Chez Sayyid ... » a
//      l'heure d'Abidjan ;
//   3. l'enseignant : fiche de la classe, l'heure de la famille a Paris, sans
//      nom ; « En ce moment », l'heure courante des deux cotes ;
//   4. changement d'heure : une seance du 01/04/2027 (Paris passe a l'heure
//      d'ete le 28/03/2027) : 09:00 a Paris, 07:00 a Abidjan ;
//   5. un profil sans fuseau : la Journee dit « Heure de cet appareil ».
//
// Prerequis : pile LOCALE avec les migrations 20261109500000 et
// 20261109900000, comptes amorces (tool/e2e/amorcer.sh). L'enseignant du banc
// retrouve a la fin son fuseau, son titre et son pays d'avant.
// Usage : node tool/e2e/fuseaux.mjs
import { parcours, activerSemantique, connecter, attendreTexte, libelles,
  nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs';

const p = await parcours('FUSEAUX : la meme seance a Paris et a Abidjan', 'fuseaux/2026-11-04');
const n = Date.now() % 1000000;
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 } },
  { nom: '1440', vue: { width: 1440, height: 900 } },
];
const LANGUES = [
  { code: 'fr', langue: 'fr-FR' },
  { code: 'ar', langue: 'ar-SA' },
];
const ABIDJAN = /Abidjan|أبيدجان/;
const PARIS = /Paris|باريس/;
const CHEZ_SAYYID = /Chez Sayyid|عند ⁨?السيد|عند ⁨?Sayyid|سيد/;
const FAMILLE = /famille|عائلة/;
const EN_CE_MOMENT = /En ce moment|الآن/;
const APPAREIL = /Heure de cet appareil|هذا الجهاز/;

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(4500);
  await activerSemantique(page);
}

async function voir(c, motif, quoi, delai = 25000) {
  const ok = await attendreTexte(c.page, motif, delai);
  if (!ok) p.dire(`  visibles : ${(await libelles(c.page)).slice(0, 50).join(' | ')}`);
  verifier(ok, quoi);
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

const TUTEUR = `e2e-fuseaux-tuteur-${n}@example.com`;
let avant = null;
let prof = null;

let code = 1;
try {
  p.dire('-- 1. banc : un foyer a Paris, deux enfants, deux classes, l\'enseignant a Abidjan');
  nettoyerClassesE2E();
  prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  avant = sql(`select coalesce(timezone_iana, '') || '|' || coalesce(titre, '') || '|' || coalesce(country, '')
                 from public.teacher_profiles where profile_id = '${prof}'`);
  sql(`update public.teacher_profiles set timezone_iana = 'Africa/Abidjan', titre = 'sayyid',
         country = 'Côte d''Ivoire' where profile_id = '${prof}'`);
  const T = creerCompte(TUTEUR);
  const E = creerCompte(`e2e-fuseaux-enfant-${n}@example.com`);
  const E2 = creerCompte(`e2e-fuseaux-enfant2-${n}@example.com`);
  const G = sql('select gen_random_uuid()');
  const G2 = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.households (id, timezone) values ('${T}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${T}', 'E2E-FUS-T-${n}', 'guardian', '${T}', 'Amina', 'FamilleFUS', 'active', 'female'),
      ('${E}', 'E2E-FUS-E-${n}', 'student', '${T}', 'Yasmine', 'FamilleFUS', 'active', 'female'),
      ('${E2}', 'E2E-FUS-F-${n}', 'student', '${T}', 'Ilyes', 'FamilleFUS', 'active', 'male');
    update public.households set primary_guardian_id = '${T}' where id = '${T}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values
      ('${E}', 'minor', 'standard'), ('${E2}', 'minor', 'standard');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at) values
      ('${G}', '${prof}', 'enfant', 5, 'E2E Fuseaux ${n}',
       extract(isodow from (now() at time zone 'Europe/Paris') + interval '2 days')::int, 9, 'Europe/Paris', now() - interval '10 days'),
      ('${G2}', '${prof}', 'enfant', 5, 'E2E Fuseaux ete ${n}', 4, 9, 'Europe/Paris', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values
      ('${G}', '${E}', now() - interval '10 days'), ('${G2}', '${E2}', now() - interval '10 days');
    commit;`);
  const S = sql('select gen_random_uuid()');
  const S2 = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id) values
      ('${S}', '${prof}', date_trunc('hour', now() + interval '2 days'), date_trunc('hour', now() + interval '2 days') + interval '45 minutes', 'planned', 'child', '${G}'),
      ('${S2}', '${prof}', '2027-04-01 07:00+00', '2027-04-01 07:45+00', 'planned', 'child', '${G2}');
    insert into public.session_participants (session_id, profile_id, role) values
      ('${S}', '${E}', 'student'), ('${S2}', '${E2}', 'student');
    commit;`);

  const lu = JSON.parse(sousJeton(T, 'guardian', T, `select public.horloge_interlocuteurs('${G}')::text`));
  verifier(lu.enseignant?.fuseau === 'Africa/Abidjan' && lu.enseignant?.titre === 'sayyid'
    && lu.moi?.fuseau === 'Europe/Paris' && !lu.familles,
  'base : le tuteur lit l\'enseignant a Abidjan, titre enregistre, aucun fuseau de famille');
  const luProf = JSON.parse(sousJeton(prof, 'teacher', null, `select public.horloge_interlocuteurs('${G}')::text`));
  verifier(luProf.familles?.[0]?.fuseau === 'Europe/Paris' && luProf.familles?.[0]?.familles === 1
    && !luProf.enseignant && !JSON.stringify(luProf).includes('Amina'),
  'base : l\'enseignant lit 1 famille a Paris, sans nom');
  const ete = JSON.parse(sousJeton(T, 'guardian', T, `select public.mon_horloge()::text`));
  verifier(ete.moi?.prochain_changement?.startsWith('2027-03-28') && ete.moi?.decalage_apres === 7200,
    'base : mon_horloge rend Paris, passage a l\'heure d\'ete le 28/03/2027 (+2 h apres)');

  for (const v of VUES) {
    for (const l of LANGUES) {
      const nom = `${v.nom}_${l.code}`;
      p.dire(`-- 2. ${nom} : le tuteur a Paris`);
      const c = await p.contexte('tuteur', { vue: v.vue, langue: l.langue });
      await connecter(c.page, TUTEUR);
      await vers(c.page, `/tuteur/classes/${G}?eleve=${E}`);
      await voir(c, ABIDJAN, `${nom} : fiche de la classe, l'heure de l'enseignant a Abidjan`);
      await voir(c, CHEZ_SAYYID, `${nom} : fiche de la classe, « Chez Sayyid »`, 5000);
      await p.capture(c, `${nom}_1_tuteur_classe`);
      await vers(c.page, `/tuteur/classes/${G2}/planning?eleve=${E2}`);
      await voir(c, /07:00/, `${nom} : seance du 01/04/2027, 07:00 a Abidjan (heure d'ete a Paris)`);
      await p.capture(c, `${nom}_2_tuteur_heure_ete`);
      await c.ctx.close();

      p.dire(`-- 3. ${nom} : l'enseignant a Abidjan`);
      const e = await p.contexte('enseignant', { vue: v.vue, langue: l.langue });
      await connecter(e.page, COMPTES.enseignant);
      await vers(e.page, `/enseignant/groupe/${G}`);
      await voir(e, PARIS, `${nom} : fiche de la classe, l'heure de la famille a Paris`);
      await voir(e, FAMILLE, `${nom} : « 1 famille », jamais un nom`, 5000);
      await voir(e, EN_CE_MOMENT, `${nom} : « En ce moment », l'heure qui avance`, 5000);
      verifier(!(await attendreTexte(e.page, /Amina|FamilleFUS/, 1500)), `${nom} : aucun nom de famille chez l'enseignant`);
      await p.capture(e, `${nom}_3_enseignant_classe`);
      await e.ctx.close();
    }
  }

  p.dire('-- 5. un profil sans fuseau : la Journee le dit');
  sql(`update public.teacher_profiles set timezone_iana = '' where profile_id = '${prof}'`);
  const s = await p.contexte('enseignant', { vue: VUES[0].vue });
  await connecter(s.page, COMPTES.enseignant);
  await vers(s.page, '/enseignant/journee');
  await voir(s, APPAREIL, 'profil sans fuseau : « Heure de cet appareil »');
  await p.capture(s, '390_fr_4_sans_fuseau_journee');
  await s.ctx.close();

  code = await p.fin('vert');
} catch (err) {
  p.dire(String(err?.stack ?? err));
  code = await p.fin('rouge', String(err?.message ?? err).slice(0, 300));
} finally {
  try {
    if (prof && avant !== null) {
      const [tz, titre, pays] = avant.split('|');
      const q = (x) => `nullif('${(x ?? '').replace(/'/g, "''")}', '')`;
      sql(`update public.teacher_profiles set timezone_iana = coalesce(${q(tz)}, 'Europe/Paris'),
             titre = ${q(titre)}, country = ${q(pays)} where profile_id = '${prof}'`);
    }
  } catch { /* pile arretee */ }
}
process.exit(code);
