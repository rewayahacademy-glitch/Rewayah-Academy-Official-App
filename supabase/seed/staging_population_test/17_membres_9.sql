-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves des classes 9 à 12.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.groupe_membres (groupe_id, student_id)
select ('e5500000-0000-4000-8000-' || lpad((m.classe)::text, 12, '0'))::uuid, ('e5100000-0000-4000-8000-' || lpad((m.eleve)::text, 12, '0'))::uuid from (values
  (9, 78),
  (9, 80),
  (9, 83),
  (9, 84),
  (9, 85),
  (9, 86),
  (10, 89),
  (10, 93),
  (10, 94),
  (10, 96),
  (10, 97),
  (10, 100),
  (11, 1),
  (11, 2),
  (11, 7),
  (11, 8),
  (11, 12),
  (12, 13),
  (12, 20),
  (12, 21),
  (12, 23),
  (12, 30)
) m(classe, eleve);
