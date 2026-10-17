-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 71 à 80.
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
  (71, 'F', 'Samira', 'Haddad', 38, 'retardLeger'),
  (72, 'F', 'Malika', 'Bouzid', 39, 'retardLeger'),
  (73, 'F', 'Leila', 'Ali', 40, 'retardLeger'),
  (74, 'M', 'Youssef', 'Traoré', 41, 'ponctuel'),
  (75, 'F', 'Djeneba', 'Kaba', 42, 'retardLeger'),
  (76, 'F', 'Djeneba', 'Diallo', 43, 'ponctuel'),
  (77, 'F', 'Imane', 'Kouyaté', 44, 'avance'),
  (78, 'M', 'Sami', 'Siddiqui', 45, 'avance'),
  (79, 'F', 'Maryam', 'Sow', 46, 'ponctuel'),
  (80, 'M', 'Seydou', 'Mansour', 47, 'retardLourd')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (71, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais'),
  (72, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais'),
  (73, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais'),
  (74, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais'),
  (75, 'adulte_18_plus', 'lecture_courante', 'devenir_fluide', 'english'),
  (76, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'english'),
  (77, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'english'),
  (78, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'english'),
  (79, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais'),
  (80, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
