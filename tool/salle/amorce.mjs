// Banc de la salle : amorce, dans la base LOCALE seulement, une classe de N
// eleves et sa seance en cours. Donnees fictives (prefixe E2E, example.com).
// Meme forme que tool/e2e/o1_livekit.mjs (foyer, tuteur, enfant, classe,
// seance) : on ne prouve pas ici l'inscription, seulement la salle.
import { sql, nettoyerClassesE2E, COMPTES, MDP } from '../e2e/commun.mjs';

export const PRENOMS = ['Amina', 'Youssef', 'Khadija', 'Bilal', 'Maryam', 'Ibrahim', 'Safiya', 'Hamza',
  'Aicha', 'Idriss', 'Soumaya', 'Anas', 'Hafsa', 'Zayd', 'Ruqayya', 'Ismail'];

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

/// Une classe « E2E Banc <etiquette> » de `n` eleves, seance en cours.
/// `enseignant` : courriel d'un enseignant actif (defaut : celui de amorcer.sh).
/// Rend { classe, seance, nom, prof, eleves: [{ id, prenom, courriel, tuteur, courrielTuteur }] }.
export function amorcerClasse({ n = 12, etiquette = '', enseignant = COMPTES.enseignant, nettoyer = true } = {}) {
  if (nettoyer) nettoyerClassesE2E();
  const k = Date.now() % 1000000;
  const prof = sql(`select id from auth.users where email = '${enseignant}'`);
  if (!prof) throw new Error(`enseignant introuvable : ${enseignant} (lancer tool/e2e/amorcer.sh)`);
  const nom = `E2E Banc ${etiquette || k}`;
  const classe = sql(`insert into public.groupes (teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana)
    values ('${prof}', 'enfant', ${Math.max(n, 5)}, '${nom}',
            date_part('isodow', now() at time zone 'UTC' + interval '3 days')::smallint, 9, 'UTC')
    returning id`).split('\n')[0];
  const seance = sql(`insert into public.sessions (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at, status)
    values ('${prof}', now() - interval '2 minutes', now() + interval '58 minutes', 'child',
            '${classe}', now() - interval '22 minutes', 'planned')
    returning id`).split('\n')[0];
  const eleves = [];
  for (let i = 0; i < n; i++) {
    const prenom = PRENOMS[i % PRENOMS.length];
    const courrielTuteur = `e2e-banc-t${i}-${k}@example.com`;
    const courriel = `e2e-banc-e${i}-${k}@example.com`;
    const tuteur = creerCompte(courrielTuteur);
    const id = creerCompte(courriel);
    sql(`begin;
      insert into public.households (id, timezone) values ('${tuteur}', 'Europe/Paris');
      insert into public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
      values ('${tuteur}', 'E2E-BANC-T${i}-${k}', 'guardian', '${tuteur}', 'E2E Parent ${prenom}', 'Banc', 'active', 'male'),
             ('${id}', 'E2E-BANC-E${i}-${k}', 'student', '${tuteur}', '${prenom}', 'Banc', 'active', '${i % 2 ? 'male' : 'female'}');
      update public.households set primary_guardian_id = '${tuteur}' where id = '${tuteur}';
      insert into public.groupe_membres (groupe_id, student_id) values ('${classe}', '${id}');
      insert into public.session_participants (session_id, profile_id, role) values ('${seance}', '${id}', 'student') on conflict do nothing;
      commit;`);
    eleves.push({ id, prenom, courriel, tuteur, courrielTuteur });
  }
  return { classe, seance, nom, prof, eleves };
}
