-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 91 à 100.
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
  (91, 'F', 'Yasmine', 'Chraïbi', 58, 'retardLeger'),
  (92, 'F', 'Sarah', 'Camara', 59, 'ponctuel'),
  (93, 'M', 'Alpha', 'Rahman', 60, 'retardLourd'),
  (94, 'M', 'Thierno', 'Yilmaz', 61, 'retardLeger'),
  (95, 'F', 'Djeneba', 'Sow', 62, 'ponctuel'),
  (96, 'M', 'Youssef', 'Diakité', 63, 'ponctuel'),
  (97, 'M', 'Karim', 'Camara', 64, 'avance'),
  (98, 'F', 'Hind', 'Bah', 65, 'retardLeger'),
  (99, 'F', 'Rokia', 'Bouzid', 66, 'avance'),
  (100, 'M', 'Alpha', 'Siddiqui', 67, 'ponctuel')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (91, 'adulte_18_plus', 'debut_lettres', 'indecis', 'english'),
  (92, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais'),
  (93, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais'),
  (94, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'english'),
  (95, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'english'),
  (96, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'english'),
  (97, 'adulte_18_plus', 'debut_lettres', 'memoriser', 'english'),
  (98, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'francais'),
  (99, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english'),
  (100, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
