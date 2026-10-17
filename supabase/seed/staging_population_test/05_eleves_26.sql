-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves 26 à 50.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

create temp table sim_lot (n int, sexe text, prenom text, nom text, famille int, cohorte text, niveau text, objectif text, langue text, paiement text);
insert into sim_lot values
  (26, 'M', 'Sami', 'Diakité', 14, 'ado_14_17', 'lecture_lente', 'memoriser', 'english', 'ponctuel'),
  (27, 'F', 'Sarah', 'Diakité', 14, 'ado_14_17', 'lecture_courante', 'apprendre_a_lire', 'english', 'ponctuel'),
  (28, 'M', 'Alpha', 'Sow', 15, 'ado_14_17', 'lecture_courante', 'memoriser', 'francais', 'retardLourd'),
  (29, 'F', 'Aminata', 'Sow', 15, 'enfant_6_9', 'memorisation_partielle', 'memoriser', 'francais', 'retardLourd'),
  (30, 'M', 'Moussa', 'Traoré', 16, 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire', 'english', 'ponctuel'),
  (31, 'M', 'Karim', 'Keïta', 17, 'enfant_10_13', 'memorisation_partielle', 'devenir_fluide', 'english', 'avance'),
  (32, 'F', 'Samira', 'Keïta', 17, 'enfant_6_9', 'lecture_courante', 'apprendre_a_lire', 'english', 'avance'),
  (33, 'F', 'Inès', 'Mansour', 18, 'ado_14_17', 'lettres_avec_aide', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (34, 'M', 'Amadou', 'Mansour', 18, 'enfant_6_9', 'debut_lettres', 'indecis', 'francais', 'ponctuel'),
  (35, 'F', 'Amina', 'Mansour', 18, 'ado_14_17', 'memorisation_partielle', 'apprendre_a_lire', 'francais', 'ponctuel'),
  (36, 'M', 'Moctar', 'Mansour', 19, 'ado_14_17', 'memorisation_partielle', 'memoriser', 'english', 'avance'),
  (37, 'M', 'Anas', 'Mansour', 19, 'enfant_6_9', 'lecture_courante', 'apprendre_a_lire', 'english', 'avance'),
  (38, 'M', 'Ibrahim', 'Camara', 20, 'enfant_10_13', 'lettres_avec_aide', 'memoriser', 'english', 'retardLeger'),
  (39, 'M', 'Noah', 'Camara', 20, 'enfant_10_13', 'memorisation_partielle', 'memoriser', 'english', 'retardLeger'),
  (40, 'F', 'Zaynab', 'Camara', 20, 'enfant_10_13', 'lecture_lente', 'memoriser', 'english', 'retardLeger'),
  (41, 'F', 'Ramatoulaye', 'Keïta', 21, 'ado_14_17', 'lettres_avec_aide', 'devenir_fluide', 'francais', 'ponctuel'),
  (42, 'M', 'Moussa', 'Keïta', 21, 'enfant_6_9', 'lettres_avec_aide', 'memoriser', 'francais', 'ponctuel'),
  (43, 'M', 'Mamadou', 'Keïta', 21, 'enfant_6_9', 'debut_lettres', 'devenir_fluide', 'francais', 'ponctuel'),
  (44, 'M', 'Mamadou', 'Keïta', 21, 'ado_14_17', 'memorisation_partielle', 'indecis', 'francais', 'ponctuel'),
  (45, 'M', 'Anas', 'Camara', 22, 'enfant_6_9', 'memorisation_partielle', 'memoriser', 'francais', 'retardLeger'),
  (46, 'M', 'Zakaria', 'Fofana', 1, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'francais', 'ponctuel'),
  (47, 'M', 'Noah', 'Kouyaté', 2, 'adulte_18_plus', 'lecture_courante', 'apprendre_a_lire', 'francais', 'avance'),
  (48, 'F', 'Zaynab', 'Kaba', 3, 'adulte_18_plus', 'lettres_avec_aide', 'devenir_fluide', 'english', 'defaillant'),
  (49, 'F', 'Imane', 'El Amrani', 4, 'adulte_18_plus', 'lecture_courante', 'memoriser', 'francais', 'ponctuel'),
  (50, 'F', 'Oumou', 'El Amrani', 5, 'adulte_18_plus', 'lecture_courante', 'indecis', 'english', 'retardLourd');

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
