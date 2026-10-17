-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 1 à 10.
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
  (1, 'F', 'Sarah', 'Fofana', 1, 'ponctuel'),
  (2, 'M', 'Sami', 'Kouyaté', 2, 'avance'),
  (3, 'F', 'Yasmine', 'Kouyaté', 2, 'avance'),
  (4, 'M', 'Adam', 'Kaba', 3, 'defaillant'),
  (5, 'M', 'Karim', 'Kaba', 3, 'defaillant'),
  (6, 'F', 'Salma', 'Kaba', 3, 'defaillant'),
  (7, 'M', 'Moctar', 'El Amrani', 4, 'ponctuel'),
  (8, 'F', 'Sarah', 'El Amrani', 4, 'ponctuel'),
  (9, 'F', 'Yasmine', 'El Amrani', 4, 'ponctuel'),
  (10, 'F', 'Salma', 'El Amrani', 4, 'ponctuel')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (1, 'enfant_10_13', 'lecture_lente', 'memoriser', 'francais'),
  (2, 'enfant_10_13', 'lecture_courante', 'indecis', 'francais'),
  (3, 'ado_14_17', 'memorisation_partielle', 'apprendre_a_lire', 'francais'),
  (4, 'ado_14_17', 'lecture_courante', 'devenir_fluide', 'english'),
  (5, 'ado_14_17', 'lecture_courante', 'apprendre_a_lire', 'english'),
  (6, 'enfant_6_9', 'debut_lettres', 'memoriser', 'english'),
  (7, 'enfant_10_13', 'lettres_avec_aide', 'devenir_fluide', 'francais'),
  (8, 'enfant_10_13', 'lettres_avec_aide', 'memoriser', 'francais'),
  (9, 'ado_14_17', 'lettres_avec_aide', 'memoriser', 'francais'),
  (10, 'enfant_6_9', 'lecture_lente', 'indecis', 'francais')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
