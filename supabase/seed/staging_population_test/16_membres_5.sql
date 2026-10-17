-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves des classes 5 à 8.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.groupe_membres (groupe_id, student_id)
select ('e5500000-0000-4000-8000-' || lpad((m.classe)::text, 12, '0'))::uuid, ('e5100000-0000-4000-8000-' || lpad((m.eleve)::text, 12, '0'))::uuid from (values
  (5, 81),
  (5, 82),
  (5, 87),
  (5, 88),
  (5, 90),
  (6, 91),
  (6, 92),
  (6, 95),
  (6, 98),
  (6, 99),
  (7, 46),
  (7, 47),
  (7, 51),
  (7, 52),
  (7, 55),
  (7, 57),
  (8, 58),
  (8, 59),
  (8, 64),
  (8, 65),
  (8, 66),
  (8, 74)
) m(classe, eleve);
