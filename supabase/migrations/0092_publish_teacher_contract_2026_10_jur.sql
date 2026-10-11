BEGIN;

-- Publish the director-approved teacher contract already rendered by
-- `paragraphesE1()` and `clauseControle` in `signature_page.dart`.
-- Keep the existing French copy verbatim; hash the exact UTF-8 text served to
-- the client. This is the source previously selected as version 2026-10-jur.
UPDATE public.contract_texts
   SET is_current = false
 WHERE contract_kind = 'teacher_nda'
   AND locale = 'fr'
   AND is_current;

WITH texte AS (
  SELECT $teacher_contract$
Ce que nous faisons.
Chaque cours est enregistré en audio. L'image n'est pas enregistrée. Une personne de l'académie chargée du contrôle peut aussi suivre un cours en direct : elle voit et entend le cours, sans être vue ni entendue. Elle n'enregistre rien. Elle envoie ensuite un compte rendu à l'académie. La salle le rappelle en permanence.

Pourquoi.
Pour protéger les enfants et les enseignants. Si quelqu'un signale un problème, nous pouvons vérifier ce qui s'est passé. C'est aussi une preuve pour vous si une famille se plaint à tort.

Qui peut écouter l'enregistrement.
Seulement les personnes de l'académie chargées de la qualité et de la protection, et seulement pour une raison précise, par exemple un signalement. Chaque écoute est inscrite dans un journal. Vous pouvez demander si un enregistrement a été écouté, et pourquoi.

Combien de temps.
30 jours, puis effacé. S'il y a un signalement, l'enregistrement est gardé jusqu'à la fin de l'examen.

Si vous refusez.
Nous ne pouvons pas vous confier d'élèves, car cette mesure protège les enfants. Nous vous le disons avant votre signature.

Vous ne voyez jamais les coordonnées d'une famille : ni nom complet, ni courriel, ni téléphone.

Visites de contrôle.
Pour protéger les élèves et garantir la qualité des cours, une personne de l'académie peut observer vos cours en direct, sans vous prévenir du moment. Elle voit et entend le cours. Elle ne parle pas, n'enregistre rien et ne publie rien. Elle écrit un compte rendu pour l'administration. Vous recevez chaque mois une synthèse. Vous pouvez la contester. Les comptes rendus sont gardés 12 mois. La politique de contrôle, jointe à ce contrat et disponible dans votre espace, explique tout. En signant, vous confirmez l'avoir reçue.

J'accepte que l'académie traite le fait que j'enseigne le Coran, qui peut révéler ma religion, pour gérer mon contrat et mes cours.
$teacher_contract$::text AS body
)
INSERT INTO public.contract_texts (
  contract_kind, version, locale, body, sha256, is_current
)
SELECT
  'teacher_nda',
  '2026-10-jur',
  'fr',
  texte.body,
  pg_catalog.encode(extensions.digest(pg_catalog.convert_to(texte.body, 'UTF8'), 'sha256'), 'hex'),
  true
FROM texte
ON CONFLICT (contract_kind, version, locale)
DO UPDATE SET is_current = true
WHERE public.contract_texts.body = EXCLUDED.body
  AND public.contract_texts.sha256 = EXCLUDED.sha256;

DO $verification$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.contract_texts
    WHERE contract_kind = 'teacher_nda'
      AND version = '2026-10-jur'
      AND locale = 'fr'
      AND is_current
      AND sha256 = pg_catalog.encode(
        extensions.digest(pg_catalog.convert_to(body, 'UTF8'), 'sha256'),
        'hex'
      )
  ) OR (
    SELECT count(*)
    FROM public.contract_texts
    WHERE contract_kind = 'teacher_nda'
      AND locale = 'fr'
      AND is_current
  ) <> 1 THEN
    RAISE EXCEPTION 'F70: validated teacher contract was not published exactly once';
  END IF;
END;
$verification$;

COMMIT;
