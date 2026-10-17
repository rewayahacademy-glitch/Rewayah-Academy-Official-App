-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), classes actives et leurs trois créneaux par semaine.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

-- Enseignant du même sexe quand la classe est séparée.
insert into public.groupes (id, teacher_id, type_public, seuil_max, libelle, nom_cours, weekday, hour_local,
  timezone_iana, etat, genre_public, langue_code)
select ('e5500000-0000-4000-8000-' || lpad((n)::text, 12, '0'))::uuid, ('e5200000-0000-4000-8000-' || lpad((enseignant)::text, 12, '0'))::uuid, type, seuil, libelle, 'Lecture du Coran',
  jour, heure, 'Europe/Paris', 'active', genre, 'francais'
from (values
  (1, 1, 'adulte', 'femmes', 1, 19, 6, 'Adultes femmes · classe 1'),
  (2, 1, 'adulte', 'femmes', 1, 21, 6, 'Adultes femmes · classe 2'),
  (3, 2, 'adulte', 'femmes', 2, 19, 6, 'Adultes femmes · classe 3'),
  (4, 2, 'adulte', 'femmes', 2, 21, 6, 'Adultes femmes · classe 4'),
  (5, 3, 'adulte', 'femmes', 1, 19, 6, 'Adultes femmes · classe 5'),
  (6, 3, 'adulte', 'femmes', 1, 21, 6, 'Adultes femmes · classe 6'),
  (7, 4, 'adulte', 'hommes', 2, 19, 6, 'Adultes hommes · classe 7'),
  (8, 4, 'adulte', 'hommes', 2, 21, 6, 'Adultes hommes · classe 8'),
  (9, 5, 'adulte', 'hommes', 1, 19, 6, 'Adultes hommes · classe 9'),
  (10, 5, 'adulte', 'hommes', 1, 21, 6, 'Adultes hommes · classe 10'),
  (11, 6, 'enfant', 'indetermine', 2, 17, 5, 'Enfants 10-13 ans · classe 11'),
  (12, 6, 'enfant', 'indetermine', 2, 19, 5, 'Enfants 10-13 ans · classe 12'),
  (13, 7, 'enfant', 'indetermine', 1, 17, 5, 'Enfants 10-13 ans · classe 13'),
  (14, 7, 'enfant', 'indetermine', 1, 19, 5, 'Enfants 14-17 ans · classe 14'),
  (15, 8, 'enfant', 'indetermine', 2, 17, 5, 'Enfants 14-17 ans · classe 15'),
  (16, 8, 'enfant', 'indetermine', 2, 19, 5, 'Enfants 14-17 ans · classe 16'),
  (17, 9, 'enfant', 'indetermine', 1, 17, 5, 'Enfants 6-9 ans · classe 17'),
  (18, 9, 'enfant', 'indetermine', 1, 19, 5, 'Enfants 6-9 ans · classe 18'),
  (19, 10, 'enfant', 'indetermine', 2, 17, 5, 'Enfants 6-9 ans · classe 19'),
  (20, 10, 'enfant', 'indetermine', 2, 19, 5, 'Enfants 6-9 ans · classe 20')
) c(n, enseignant, type, genre, jour, heure, seuil, libelle);

insert into public.groupe_creneaux (groupe_id, weekday, hour_local)
select ('e5500000-0000-4000-8000-' || lpad((n)::text, 12, '0'))::uuid, jour, heure from (values
  (1, 3, 19),
  (1, 5, 19),
  (2, 3, 21),
  (2, 5, 21),
  (3, 4, 19),
  (3, 6, 19),
  (4, 4, 21),
  (4, 6, 21),
  (5, 3, 19),
  (5, 5, 19),
  (6, 3, 21),
  (6, 5, 21),
  (7, 4, 19),
  (7, 6, 19),
  (8, 4, 21),
  (8, 6, 21),
  (9, 3, 19),
  (9, 5, 19),
  (10, 3, 21),
  (10, 5, 21),
  (11, 4, 17),
  (11, 6, 17),
  (12, 4, 19),
  (12, 6, 19),
  (13, 3, 17),
  (13, 5, 17),
  (14, 3, 19),
  (14, 5, 19),
  (15, 4, 17),
  (15, 6, 17),
  (16, 4, 19),
  (16, 6, 19),
  (17, 3, 17),
  (17, 5, 17),
  (18, 3, 19),
  (18, 5, 19),
  (19, 4, 17),
  (19, 6, 17),
  (20, 4, 19),
  (20, 6, 19)
) c(n, jour, heure);
