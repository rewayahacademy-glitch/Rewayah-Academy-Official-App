-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 51 à 75.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

create temp table sim_lot (n int, sexe text, prenom text, nom text, famille int, cohorte text, niveau text, objectif text, langue text, paiement text);
insert into sim_lot values
  (51, 'M', 'Ayoub', 'Chraïbi', 6, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais', 'avance'),
  (52, 'M', 'Amadou', 'Cissé', 7, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english', 'ponctuel'),
  (53, 'F', 'Mariama', 'Barry', 8, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english', 'defaillant'),
  (54, 'F', 'Hanane', 'Benkirane', 23, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais', 'retardLeger'),
  (55, 'M', 'Ilyes', 'Benkirane', 23, 'adulte_18_plus', 'lecture_courante', 'indecis', 'francais', 'retardLeger'),
  (56, 'F', 'Safiya', 'Bah', 24, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'english', 'ponctuel'),
  (57, 'M', 'Ousmane', 'Bah', 24, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'english', 'ponctuel'),
  (58, 'M', 'Bilal', 'Sylla', 25, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english', 'retardLeger'),
  (59, 'M', 'Seydou', 'Haddad', 26, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais', 'retardLourd'),
  (60, 'F', 'Aïcha', 'Fofana', 27, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais', 'retardLourd'),
  (61, 'F', 'Hawa', 'Barry', 28, 'adulte_18_plus', 'lettres_avec_aide', 'memoriser', 'english', 'ponctuel'),
  (62, 'F', 'Djeneba', 'Ndiaye', 29, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'francais', 'avance'),
  (63, 'F', 'Salma', 'Diallo', 30, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais', 'retardLourd'),
  (64, 'M', 'Adam', 'Touré', 31, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais', 'retardLeger'),
  (65, 'M', 'Yacine', 'Touré', 32, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais', 'retardLeger'),
  (66, 'M', 'Elias', 'Sangaré', 33, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english', 'avance'),
  (67, 'F', 'Fatima', 'Kaba', 34, 'adulte_18_plus', 'lecture_lente', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (68, 'F', 'Sarah', 'Koné', 35, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'francais', 'defaillant'),
  (69, 'F', 'Leila', 'Fofana', 36, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'english', 'defaillant'),
  (70, 'F', 'Samira', 'Sangaré', 37, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais', 'retardLourd'),
  (71, 'F', 'Samira', 'Haddad', 38, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais', 'retardLeger'),
  (72, 'F', 'Malika', 'Bouzid', 39, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'retardLeger'),
  (73, 'F', 'Leila', 'Ali', 40, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais', 'retardLeger'),
  (74, 'M', 'Youssef', 'Traoré', 41, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais', 'ponctuel'),
  (75, 'F', 'Djeneba', 'Kaba', 42, 'adulte_18_plus', 'lecture_courante', 'devenir_fluide', 'english', 'retardLeger');

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
from sim_lot e;

insert into public.student_profiles (profile_id, student_type, interface_mode, riwaya, camera_policy, langue_cours,
  cohorte, niveau_declare, objectif, diagnostic_statut, onboarding_fait_le)
select ('e5100000-0000-4000-8000-' || lpad((e.n)::text, 12, '0'))::uuid, c.student_type, c.interface_mode, 'hafs',
  (case c.type_public when 'enfant' then 'forbidden' else 'allowed' end)::public.camera_policy,
  e.langue, c.code, e.niveau, e.objectif, 'fait', now()
from sim_lot e join public.cohortes_age c on c.code = e.cohorte;

drop table sim_lot;
