-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves des classes 17 à 20.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.groupe_membres (groupe_id, student_id)
select ('e5500000-0000-4000-8000-' || lpad((m.classe)::text, 12, '0'))::uuid, ('e5100000-0000-4000-8000-' || lpad((m.eleve)::text, 12, '0'))::uuid from (values
  (17, 6),
  (17, 10),
  (17, 11),
  (17, 14),
  (17, 15),
  (18, 16),
  (18, 17),
  (18, 19),
  (18, 22),
  (18, 24),
  (19, 25),
  (19, 29),
  (19, 32),
  (19, 34),
  (20, 37),
  (20, 42),
  (20, 43),
  (20, 45)
) m(classe, eleve);
