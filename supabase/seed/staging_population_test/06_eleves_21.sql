-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 21 à 30.
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
  (21, 'M', 'Amadou', 'Diakité', 11, 'avance'),
  (22, 'M', 'Idriss', 'Mansour', 12, 'retardLeger'),
  (23, 'F', 'Oumou', 'Mansour', 12, 'retardLeger'),
  (24, 'F', 'Sarah', 'Sangaré', 13, 'retardLourd'),
  (25, 'M', 'Mamadou', 'Diakité', 14, 'ponctuel'),
  (26, 'M', 'Sami', 'Diakité', 14, 'ponctuel'),
  (27, 'F', 'Sarah', 'Diakité', 14, 'ponctuel'),
  (28, 'M', 'Alpha', 'Sow', 15, 'retardLourd'),
  (29, 'F', 'Aminata', 'Sow', 15, 'retardLourd'),
  (30, 'M', 'Moussa', 'Traoré', 16, 'ponctuel')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (21, 'enfant_10_13', 'lecture_lente', 'devenir_fluide', 'english'),
  (22, 'enfant_6_9', 'lecture_lente', 'indecis', 'english'),
  (23, 'enfant_10_13', 'lecture_lente', 'indecis', 'english'),
  (24, 'enfant_6_9', 'lettres_avec_aide', 'apprendre_a_lire', 'english'),
  (25, 'enfant_6_9', 'lettres_avec_aide', 'memoriser', 'english'),
  (26, 'ado_14_17', 'lecture_lente', 'memoriser', 'english'),
  (27, 'ado_14_17', 'lecture_courante', 'apprendre_a_lire', 'english'),
  (28, 'ado_14_17', 'lecture_courante', 'memoriser', 'francais'),
  (29, 'enfant_6_9', 'memorisation_partielle', 'memoriser', 'francais'),
  (30, 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire', 'english')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
