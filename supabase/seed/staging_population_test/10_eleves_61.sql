-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 61 à 70.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.profiles (id, role, household_id, first_name, last_name, account_status, access_until, gender)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, 'student', ('e5400000-0000-4000-8000-' || lpad((e.famille)::text, 12, '0'))::uuid, e.prenom, e.nom, 'active',
  case e.paiement
    when 'avance' then date_trunc('month', now()) + interval '3 months' - interval '1 second'
    when 'ponctuel' then date_trunc('month', now()) + interval '2 months' - interval '1 second'
    when 'retardLeger' then date_trunc('month', now()) + interval '1 month' - interval '1 second'
    when 'retardLourd' then date_trunc('month', now()) + interval '9 days'
    when 'defaillant' then date_trunc('month', now()) - interval '20 days'
  end,
  (case e.sexe when 'F' then 'female' else 'male' end)::public.gender
from (values
  (61, 'F', 'Hawa', 'Barry', 28, 'ponctuel'),
  (62, 'F', 'Djeneba', 'Ndiaye', 29, 'avance'),
  (63, 'F', 'Salma', 'Diallo', 30, 'retardLourd'),
  (64, 'M', 'Adam', 'Touré', 31, 'retardLeger'),
  (65, 'M', 'Yacine', 'Touré', 32, 'retardLeger'),
  (66, 'M', 'Elias', 'Sangaré', 33, 'avance'),
  (67, 'F', 'Fatima', 'Kaba', 34, 'ponctuel'),
  (68, 'F', 'Sarah', 'Koné', 35, 'defaillant'),
  (69, 'F', 'Leila', 'Fofana', 36, 'defaillant'),
  (70, 'F', 'Samira', 'Sangaré', 37, 'retardLourd')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (61, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english'),
  (62, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'francais'),
  (63, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais'),
  (64, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais'),
  (65, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais'),
  (66, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english'),
  (67, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais'),
  (68, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'francais'),
  (69, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'english'),
  (70, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
