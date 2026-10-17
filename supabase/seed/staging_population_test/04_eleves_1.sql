-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 1 à 25.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

create temp table sim_lot (n int, sexe text, prenom text, nom text, famille int, cohorte text, niveau text, objectif text, langue text, paiement text);
insert into sim_lot values
  (1, 'F', 'Sarah', 'Fofana', 1, 'enfant_10_13', 'lecture_lente', 'memoriser', 'francais', 'ponctuel'),
  (2, 'M', 'Sami', 'Kouyaté', 2, 'enfant_10_13', 'lecture_courante', 'indecis', 'francais', 'avance'),
  (3, 'F', 'Yasmine', 'Kouyaté', 2, 'ado_14_17', 'memorisation_partielle', 'apprendre_a_lire', 'francais', 'avance'),
  (4, 'M', 'Adam', 'Kaba', 3, 'ado_14_17', 'lecture_courante', 'devenir_fluide', 'english', 'defaillant'),
  (5, 'M', 'Karim', 'Kaba', 3, 'ado_14_17', 'lecture_courante', 'apprendre_a_lire', 'english', 'defaillant'),
  (6, 'F', 'Salma', 'Kaba', 3, 'enfant_6_9', 'debut_lettres', 'memoriser', 'english', 'defaillant'),
  (7, 'M', 'Moctar', 'El Amrani', 4, 'enfant_10_13', 'lettres_avec_aide', 'devenir_fluide', 'francais', 'ponctuel'),
  (8, 'F', 'Sarah', 'El Amrani', 4, 'enfant_10_13', 'lettres_avec_aide', 'memoriser', 'francais', 'ponctuel'),
  (9, 'F', 'Yasmine', 'El Amrani', 4, 'ado_14_17', 'lettres_avec_aide', 'memoriser', 'francais', 'ponctuel'),
  (10, 'F', 'Salma', 'El Amrani', 4, 'enfant_6_9', 'lecture_lente', 'indecis', 'francais', 'ponctuel'),
  (11, 'M', 'Noah', 'El Amrani', 5, 'enfant_6_9', 'lettres_avec_aide', 'devenir_fluide', 'english', 'retardLourd'),
  (12, 'F', 'Hawa', 'Chraïbi', 6, 'enfant_10_13', 'lecture_courante', 'indecis', 'francais', 'avance'),
  (13, 'F', 'Hafsa', 'Chraïbi', 6, 'enfant_10_13', 'debut_lettres', 'devenir_fluide', 'francais', 'avance'),
  (14, 'F', 'Hanane', 'Cissé', 7, 'enfant_6_9', 'debut_lettres', 'indecis', 'english', 'ponctuel'),
  (15, 'M', 'Anas', 'Cissé', 7, 'enfant_6_9', 'debut_lettres', 'indecis', 'english', 'ponctuel'),
  (16, 'F', 'Samira', 'Barry', 8, 'enfant_6_9', 'lecture_courante', 'apprendre_a_lire', 'english', 'defaillant'),
  (17, 'M', 'Alpha', 'Kaba', 9, 'enfant_6_9', 'lecture_lente', 'devenir_fluide', 'francais', 'retardLourd'),
  (18, 'M', 'Seydou', 'Kaba', 9, 'ado_14_17', 'lecture_courante', 'indecis', 'francais', 'retardLourd'),
  (19, 'M', 'Abdoulaye', 'Kaba', 9, 'enfant_6_9', 'memorisation_partielle', 'indecis', 'francais', 'retardLourd'),
  (20, 'M', 'Amadou', 'Touré', 10, 'enfant_10_13', 'debut_lettres', 'memoriser', 'francais', 'retardLeger'),
  (21, 'M', 'Amadou', 'Diakité', 11, 'enfant_10_13', 'lecture_lente', 'devenir_fluide', 'english', 'avance'),
  (22, 'M', 'Idriss', 'Mansour', 12, 'enfant_6_9', 'lecture_lente', 'indecis', 'english', 'retardLeger'),
  (23, 'F', 'Oumou', 'Mansour', 12, 'enfant_10_13', 'lecture_lente', 'indecis', 'english', 'retardLeger'),
  (24, 'F', 'Sarah', 'Sangaré', 13, 'enfant_6_9', 'lettres_avec_aide', 'apprendre_a_lire', 'english', 'retardLourd'),
  (25, 'M', 'Mamadou', 'Diakité', 14, 'enfant_6_9', 'lettres_avec_aide', 'memoriser', 'english', 'ponctuel');

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
