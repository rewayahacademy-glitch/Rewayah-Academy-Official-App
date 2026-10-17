-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 41 à 50.
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
  (41, 'F', 'Ramatoulaye', 'Keïta', 21, 'ponctuel'),
  (42, 'M', 'Moussa', 'Keïta', 21, 'ponctuel'),
  (43, 'M', 'Mamadou', 'Keïta', 21, 'ponctuel'),
  (44, 'M', 'Mamadou', 'Keïta', 21, 'ponctuel'),
  (45, 'M', 'Anas', 'Camara', 22, 'retardLeger'),
  (46, 'M', 'Zakaria', 'Fofana', 1, 'ponctuel'),
  (47, 'M', 'Noah', 'Kouyaté', 2, 'avance'),
  (48, 'F', 'Zaynab', 'Kaba', 3, 'defaillant'),
  (49, 'F', 'Imane', 'El Amrani', 4, 'ponctuel'),
  (50, 'F', 'Oumou', 'El Amrani', 5, 'retardLourd')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (41, 'ado_14_17', 'lettres_avec_aide', 'devenir_fluide', 'francais'),
  (42, 'enfant_6_9', 'lettres_avec_aide', 'memoriser', 'francais'),
  (43, 'enfant_6_9', 'debut_lettres', 'devenir_fluide', 'francais'),
  (44, 'ado_14_17', 'memorisation_partielle', 'indecis', 'francais'),
  (45, 'enfant_6_9', 'memorisation_partielle', 'memoriser', 'francais'),
  (46, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'francais'),
  (47, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'francais'),
  (48, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'english'),
  (49, 'adulte_18_plus', 'lecture_courante', 'memoriser', 'francais'),
  (50, 'adulte_18_plus', 'lecture_courante', 'indecis', 'english')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
