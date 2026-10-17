-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves des classes 13 à 16.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.groupe_membres (groupe_id, student_id)
select ('e5500000-0000-4000-8000-' || lpad((m.classe)::text, 12, '0'))::uuid, ('e5100000-0000-4000-8000-' || lpad((m.eleve)::text, 12, '0'))::uuid from (values
  (13, 31),
  (13, 38),
  (13, 39),
  (13, 40),
  (14, 3),
  (14, 4),
  (14, 5),
  (14, 9),
  (14, 18),
  (15, 26),
  (15, 27),
  (15, 28),
  (15, 33),
  (16, 35),
  (16, 36),
  (16, 41),
  (16, 44)
) m(classe, eleve);
