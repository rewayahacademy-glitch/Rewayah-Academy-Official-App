// DRAPEAUX (04/11/2026) : le pays de l'enseignant, avec son drapeau, la ou
// une famille le voit, sur la pile LOCALE, par l'interface (R3).
//
// Ce que le parcours prouve :
//   1. base : sous le jeton du tuteur, mes_groupes_famille_v et mes_seances_v
//      rendent teacher_country (migration 20261109400000) ;
//   2. a 390 et a 1440, en francais puis en arabe (droite a gauche), le
//      tuteur lit « Côte d'Ivoire » et son drapeau sous le nom de
//      l'enseignant : Accueil (carte de la classe et de la seance), fiche de
//      la classe.
//
// Prerequis : pile LOCALE avec les migrations du depot, comptes amorces
// (tool/e2e/amorcer.sh). Donnees : un foyer, un enfant, une classe et une
// seance neufs a chaque passage. Le pays de l'enseignant du banc est remis a
// sa valeur d'avant a la fin (pays et titre). Usage : node tool/e2e/drapeaux.mjs
import { parcours, trouver, activerSemantique, connecter, attendreTexte,
  libelles, nettoyerClassesE2E, sql, COMPTES, MDP } from './commun.mjs';

const p = await parcours('DRAPEAUX : le pays de l\'enseignant vu par la famille', 'DRAPEAUX');
const n = Date.now() % 1000000;
const VUES = [
  { nom: '390', vue: { width: 390, height: 844 } },
  { nom: '1440', vue: { width: 1440, height: 900 } },
];
const LANGUES = [
  { code: 'fr', langue: 'fr-FR' },
  { code: 'ar', langue: 'ar-SA' },
];
// Le nom ecrit par PaysEnseignant : celui du profil, ou sa traduction.
const PAYS = /Côte d.Ivoire|ساحل العاج|كوت ديفوار/;

function verifier(condition, message) {
  if (!condition) throw new Error(`ROUGE : ${message}`);
  p.dire(`  OK ${message}`);
}

async function vers(page, chemin) {
  await page.evaluate((r) => { location.hash = `#${r}`; }, chemin);
  await page.waitForTimeout(4000);
  await activerSemantique(page);
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

/// Le pays est-il ecrit dans la page (arbre d'accessibilite ou texte) ?
async function paysVisible(page, delai = 20000) {
  return attendreTexte(page, PAYS, delai);
}

const TUTEUR = `e2e-drapeaux-tuteur-${n}@example.com`;
const CLASSE = `E2E Drapeaux ${n}`;
let paysAvant = null;
let titreAvant = null;
let prof = null;

let code = 1;
try {
  p.dire('-- 1. banc : un foyer, un enfant, une classe, une seance');
  nettoyerClassesE2E();
  prof = sql(`select id from auth.users where email = '${COMPTES.enseignant}'`);
  paysAvant = sql(`select coalesce(country, '') from public.teacher_profiles where profile_id = '${prof}'`);
  titreAvant = sql(`select coalesce(titre, '') from public.teacher_profiles where profile_id = '${prof}'`);
  sql(`update public.teacher_profiles set country = 'Côte d''Ivoire', titre = 'sayyid' where profile_id = '${prof}'`);
  const T = creerCompte(TUTEUR);
  const E = creerCompte(`e2e-drapeaux-enfant-${n}@example.com`);
  const G = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.households (id, timezone) values ('${T}', 'Europe/Paris');
    insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) values
      ('${T}', 'E2E-DRP-T-${n}', 'guardian', '${T}', 'Amina', 'FamilleDRP', 'active', 'female'),
      ('${E}', 'E2E-DRP-E-${n}', 'student', '${T}', 'Yasmine', 'FamilleDRP', 'active', 'female');
    update public.households set primary_guardian_id = '${T}' where id = '${T}';
    insert into public.student_profiles (profile_id, student_type, interface_mode) values ('${E}', 'minor', 'child');
    insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, created_at)
      values ('${G}', '${prof}', 'enfant', 5, '${CLASSE}',
              extract(isodow from (now() at time zone 'Europe/Paris') + interval '2 days')::int, 9, 'Africa/Abidjan', now() - interval '10 days');
    insert into public.groupe_membres (groupe_id, student_id, joined_at) values ('${G}', '${E}', now() - interval '10 days');
    commit;`);
  const seance = sql('select gen_random_uuid()');
  sql(`begin;
    insert into public.sessions (id, teacher_id, started_at, ended_at, status, session_type, groupe_id)
      values ('${seance}', '${prof}', now() + interval '2 days', now() + interval '2 days 45 minutes', 'planned', 'child', '${G}');
    insert into public.session_participants (session_id, profile_id, role) values ('${seance}', '${E}', 'student');
    commit;`);

  verifier(sousJeton(T, 'guardian', T, `select teacher_country from public.mes_groupes_famille_v where groupe_id = '${G}'`)
    === "Côte d'Ivoire", 'base : mes_groupes_famille_v rend le pays au tuteur');
  verifier(sousJeton(T, 'guardian', T, `select teacher_country from public.mes_seances_v where session_id = '${seance}'`)
    === "Côte d'Ivoire", 'base : mes_seances_v rend le pays au tuteur');

  p.dire('-- 2. le tuteur : Accueil, fiche de la classe');
  for (const v of VUES) {
    for (const l of LANGUES) {
      const c = await p.contexte('tuteur', { vue: v.vue, langue: l.langue });
      await connecter(c.page, TUTEUR);
      await vers(c.page, '/tuteur');
      verifier(await paysVisible(c.page, 30000), `${v.nom} ${l.code} : Accueil, le pays de l'enseignant`);
      await p.capture(c, `${v.nom}_${l.code}_1_accueil`);
      await vers(c.page, `/tuteur/classes/${G}?eleve=${E}`);
      const ok = await paysVisible(c.page);
      if (!ok) p.dire(`  visibles : ${(await libelles(c.page)).slice(0, 40).join(' | ')}`);
      verifier(ok, `${v.nom} ${l.code} : fiche de la classe, le pays de l'enseignant`);
      await p.capture(c, `${v.nom}_${l.code}_2_fiche_classe`);
      await c.ctx.close();
    }
  }
  code = await p.fin('vert');
} catch (e) {
  p.dire(String(e?.stack ?? e));
  code = await p.fin('rouge', String(e?.message ?? e).slice(0, 300));
} finally {
  try {
    if (prof && paysAvant !== null) {
      sql(`update public.teacher_profiles set country = nullif('${paysAvant.replace(/'/g, "''")}', ''),
             titre = nullif('${(titreAvant ?? '').replace(/'/g, "''")}', '') where profile_id = '${prof}'`);
    }
  } catch { /* pile arretee */ }
}
process.exit(code);
