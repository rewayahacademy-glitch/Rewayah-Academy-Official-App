-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 81 à 90.
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
  (81, 'F', 'Sofia', 'Bah', 48, 'ponctuel'),
  (82, 'F', 'Inès', 'Sangaré', 49, 'ponctuel'),
  (83, 'M', 'Youssef', 'Cissé', 50, 'retardLeger'),
  (84, 'M', 'Mamadou', 'Traoré', 51, 'retardLeger'),
  (85, 'M', 'Omar', 'Chraïbi', 52, 'ponctuel'),
  (86, 'M', 'Youssef', 'Ndiaye', 53, 'ponctuel'),
  (87, 'F', 'Sarah', 'Bah', 54, 'defaillant'),
  (88, 'F', 'Aminata', 'Sangaré', 55, 'retardLourd'),
  (89, 'M', 'Bilal', 'Sangaré', 56, 'retardLourd'),
  (90, 'F', 'Inès', 'Traoré', 57, 'ponctuel')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (81, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais'),
  (82, 'adulte_18_plus', 'debut_lettres', 'indecis', 'english'),
  (83, 'adulte_18_plus', 'lecture_courante', 'indecis', 'francais'),
  (84, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais'),
  (85, 'adulte_18_plus', 'lecture_courante', 'devenir_fluide', 'english'),
  (86, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'english'),
  (87, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais'),
  (88, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais'),
  (89, 'adulte_18_plus', 'lecture_lente', 'devenir_fluide', 'francais'),
  (90, 'adulte_18_plus', 'lecture_lente', 'indecis', 'english')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
