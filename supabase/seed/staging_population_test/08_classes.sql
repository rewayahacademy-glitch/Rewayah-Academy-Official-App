-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), classes actives et leurs trois créneaux par semaine.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

create temp table sim_classes (n int, enseignant int, type text, genre text, jours int[], heure int, seuil int, libelle text);
insert into sim_classes values
  (1, 1, 'adulte', 'femmes', '{1,3,5}', 19, 6, 'Adultes femmes · classe 1'),
  (2, 1, 'adulte', 'femmes', '{1,3,5}', 21, 6, 'Adultes femmes · classe 2'),
  (3, 2, 'adulte', 'femmes', '{2,4,6}', 19, 6, 'Adultes femmes · classe 3'),
  (4, 2, 'adulte', 'femmes', '{2,4,6}', 21, 6, 'Adultes femmes · classe 4'),
  (5, 3, 'adulte', 'femmes', '{1,3,5}', 19, 6, 'Adultes femmes · classe 5'),
  (6, 3, 'adulte', 'femmes', '{1,3,5}', 21, 6, 'Adultes femmes · classe 6'),
  (7, 4, 'adulte', 'hommes', '{2,4,6}', 19, 6, 'Adultes hommes · classe 7'),
  (8, 4, 'adulte', 'hommes', '{2,4,6}', 21, 6, 'Adultes hommes · classe 8'),
  (9, 5, 'adulte', 'hommes', '{1,3,5}', 19, 6, 'Adultes hommes · classe 9'),
  (10, 5, 'adulte', 'hommes', '{1,3,5}', 21, 6, 'Adultes hommes · classe 10'),
  (11, 6, 'enfant', 'indetermine', '{2,4,6}', 17, 5, 'Enfants 10-13 ans · classe 11'),
  (12, 6, 'enfant', 'indetermine', '{2,4,6}', 19, 5, 'Enfants 10-13 ans · classe 12'),
  (13, 7, 'enfant', 'indetermine', '{1,3,5}', 17, 5, 'Enfants 10-13 ans · classe 13'),
  (14, 7, 'enfant', 'indetermine', '{1,3,5}', 19, 5, 'Enfants 14-17 ans · classe 14'),
  (15, 8, 'enfant', 'indetermine', '{2,4,6}', 17, 5, 'Enfants 14-17 ans · classe 15'),
  (16, 8, 'enfant', 'indetermine', '{2,4,6}', 19, 5, 'Enfants 14-17 ans · classe 16'),
  (17, 9, 'enfant', 'indetermine', '{1,3,5}', 17, 5, 'Enfants 6-9 ans · classe 17'),
  (18, 9, 'enfant', 'indetermine', '{1,3,5}', 19, 5, 'Enfants 6-9 ans · classe 18'),
  (19, 10, 'enfant', 'indetermine', '{2,4,6}', 17, 5, 'Enfants 6-9 ans · classe 19'),
  (20, 10, 'enfant', 'indetermine', '{2,4,6}', 19, 5, 'Enfants 6-9 ans · classe 20');

-- Enseignant du même sexe quand la classe est séparée.
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, nom_cours, weekday, hour_local,
  timezone_iana, etat, genre_public, langue_code)
select ('e5500000-0000-4000-8000-' || lpad((n)::text, 12, '0'))::uuid, ('e5200000-0000-4000-8000-' || lpad((enseignant)::text, 12, '0'))::uuid, type, seuil, libelle, 'Lecture du Coran',
  jours[1], heure, 'Europe/Paris', 'active', genre, 'francais'
from sim_classes;

insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
select ('e5500000-0000-4000-8000-' || lpad((n)::text, 12, '0'))::uuid, j, heure from sim_classes, unnest(jours[2:3]) j;

drop table sim_classes;
