-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), élèves des classes 1 à 4.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.groupe_membres (groupe_id, student_id)
select ('e5500000-0000-4000-8000-' || lpad((m.classe)::text, 12, '0'))::uuid, ('e5100000-0000-4000-8000-' || lpad((m.eleve)::text, 12, '0'))::uuid from (values
  (1, 48),
  (1, 49),
  (1, 50),
  (1, 53),
  (1, 54),
  (1, 56),
  (2, 60),
  (2, 61),
  (2, 62),
  (2, 63),
  (2, 67),
  (3, 68),
  (3, 69),
  (3, 70),
  (3, 71),
  (3, 72),
  (4, 73),
  (4, 75),
  (4, 76),
  (4, 77),
  (4, 79)
) m(classe, eleve);
