-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 76 à 100.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

create temp table sim_lot (n int, sexe text, prenom text, nom text, famille int, cohorte text, niveau text, objectif text, langue text, paiement text);
insert into sim_lot values
  (76, 'F', 'Djeneba', 'Diallo', 43, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'english', 'ponctuel'),
  (77, 'F', 'Imane', 'Kouyaté', 44, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'english', 'avance'),
  (78, 'M', 'Sami', 'Siddiqui', 45, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'english', 'avance'),
  (79, 'F', 'Maryam', 'Sow', 46, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (80, 'M', 'Seydou', 'Mansour', 47, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'retardLourd'),
  (81, 'F', 'Sofia', 'Bah', 48, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (82, 'F', 'Inès', 'Sangaré', 49, 'adulte_18_plus', 'debut_lettres', 'indecis', 'english', 'ponctuel'),
  (83, 'M', 'Youssef', 'Cissé', 50, 'adulte_18_plus', 'lecture_courante', 'indecis', 'francais', 'retardLeger'),
  (84, 'M', 'Mamadou', 'Traoré', 51, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais', 'retardLeger'),
  (85, 'M', 'Omar', 'Chraïbi', 52, 'adulte_18_plus', 'lecture_courante', 'devenir_fluide', 'english', 'ponctuel'),
  (86, 'M', 'Youssef', 'Ndiaye', 53, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'english', 'ponctuel'),
  (87, 'F', 'Sarah', 'Bah', 54, 'adulte_18_plus', 'debut_lettres', 'indecis', 'francais', 'defaillant'),
  (88, 'F', 'Aminata', 'Sangaré', 55, 'adulte_18_plus', 'lettres_avec_aide', 'indecis', 'francais', 'retardLourd'),
  (89, 'M', 'Bilal', 'Sangaré', 56, 'adulte_18_plus', 'lecture_lente', 'devenir_fluide', 'francais', 'retardLourd'),
  (90, 'F', 'Inès', 'Traoré', 57, 'adulte_18_plus', 'lecture_lente', 'indecis', 'english', 'ponctuel'),
  (91, 'F', 'Yasmine', 'Chraïbi', 58, 'adulte_18_plus', 'debut_lettres', 'indecis', 'english', 'retardLeger'),
  (92, 'F', 'Sarah', 'Camara', 59, 'adulte_18_plus', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (93, 'M', 'Alpha', 'Rahman', 60, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'francais', 'retardLourd'),
  (94, 'M', 'Thierno', 'Yilmaz', 61, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'english', 'retardLeger'),
  (95, 'F', 'Djeneba', 'Sow', 62, 'adulte_18_plus', 'memorisation_partielle', 'memoriser', 'english', 'ponctuel'),
  (96, 'M', 'Youssef', 'Diakité', 63, 'adulte_18_plus', 'debut_lettres', 'devenir_fluide', 'english', 'ponctuel'),
  (97, 'M', 'Karim', 'Camara', 64, 'adulte_18_plus', 'debut_lettres', 'memoriser', 'english', 'avance'),
  (98, 'F', 'Hind', 'Bah', 65, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'francais', 'retardLeger'),
  (99, 'F', 'Rokia', 'Bouzid', 66, 'adulte_18_plus', 'memorisation_partielle', 'devenir_fluide', 'english', 'avance'),
  (100, 'M', 'Alpha', 'Siddiqui', 67, 'adulte_18_plus', 'lecture_lente', 'memoriser', 'francais', 'ponctuel');

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
