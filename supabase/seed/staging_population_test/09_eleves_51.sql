-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 51 à 60.
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
  (51, 'M', 'Ayoub', 'Chraïbi', 6, 'avance'),
  (52, 'M', 'Amadou', 'Cissé', 7, 'ponctuel'),
  (53, 'F', 'Mariama', 'Barry', 8, 'defaillant'),
  (54, 'F', 'Hanane', 'Benkirane', 23, 'retardLeger'),
  (55, 'M', 'Ilyes', 'Benkirane', 23, 'retardLeger'),
  (56, 'F', 'Safiya', 'Bah', 24, 'ponctuel'),
  (57, 'M', 'Ousmane', 'Bah', 24, 'ponctuel'),
  (58, 'M', 'Bilal', 'Sylla', 25, 'retardLeger'),
  (59, 'M', 'Seydou', 'Haddad', 26, 'retardLourd'),
  (60, 'F', 'Aïcha', 'Fofana', 27, 'retardLourd')
) e(n, sexe, prenom, nom, famille, paiement);

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from (values
  (51, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais'),
  (52, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english'),
  (53, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english'),
  (54, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais'),
  (55, 'adulte_18_plus', 'lecture_courante', 'indecis', 'francais'),
  (56, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'english'),
  (57, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'english'),
  (58, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english'),
  (59, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais'),
  (60, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais')
) e(n, cohorte, niveau, objectif, langue)
join public.cohortes_age c on c.code = e.cohorte;
