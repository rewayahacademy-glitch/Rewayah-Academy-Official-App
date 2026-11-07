-- CADRE-MIGRATIONS, fichier 1 sur 2 (schema), 07/11/2026. Lot valide par le
-- garde-cap (plan des trois salles, salle 1), numero reserve au nom de
-- l'agent E. Le texte a publier : docs/current/TEXTES-VALIDES/
-- CADRE-RELIGIEUX-ENSEIGNANT.md (valide par le directeur le 07/11/2026),
-- publie par le fichier 2, 20261118000100_cadre_publication.sql.
--
-- contract_texts (0086_signature_contrat_versionnee.sql) a trois limites,
-- constatees en production par A et le garde-cap :
--   (1) contract_texts_contract_kind_check n'accepte que 'teacher_nda' ;
--   (2) contract_texts_locale_check n'accepte que 'fr' ;
--   (3) la policy contract_texts_published_read lit
--       USING (is_current AND locale = 'fr').
-- Ce fichier :
--   (1) accepte aussi 'teacher_religious_framework' ;
--   (2) accepte 'fr' et 'ar' ;
--   (3) lit tout texte is_current, quelle que soit la locale (toujours pour
--       authenticated seulement ; anon n'a aucun droit sur la table).
-- Les noms sont ceux de 0086 (contraintes en ligne, noms par defaut de
-- PostgreSQL), relus sur une base rejouee depuis le depot le 07/11.
--
-- FICHIER A MOTS D'EFFACEMENT (deux DROP CONSTRAINT IF EXISTS et un
-- DROP POLICY IF EXISTS, rien d'autre) : PAGE COLLEE PAR LE DIRECTEUR. Aucune
-- ligne n'est effacee. Sans BEGIN ni COMMIT de premier niveau. Rejouable :
-- deja applique, il remet les memes definitions.
--
-- VERIFICATION PREALABLE, a lancer avant de coller (lecture seule) :
--   SELECT conname, pg_catalog.pg_get_constraintdef(oid)
--     FROM pg_catalog.pg_constraint
--    WHERE conrelid = 'public.contract_texts'::regclass
--      AND conname IN ('contract_texts_contract_kind_check', 'contract_texts_locale_check');
--   -- attendu : CHECK ((contract_kind = 'teacher_nda'::text))
--   --           CHECK ((locale = 'fr'::text))
--   SELECT polname, polcmd, polroles::regrole[],
--          pg_catalog.pg_get_expr(polqual, polrelid)
--     FROM pg_catalog.pg_policy
--    WHERE polrelid = 'public.contract_texts'::regclass;
--   -- attendu : contract_texts_published_read | r | {authenticated}
--   --           | (is_current AND (locale = 'fr'::text))
-- Le preflight ci-dessous refait ces lectures et s'arrete sur toute autre
-- valeur (sauf l'etat deja elargi par ce fichier).

DO $preflight$
DECLARE
  v_kind text;
  v_locale text;
  v_policy text;
  v_autres integer;
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_kind FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.contract_texts'::regclass AND c.conname = 'contract_texts_contract_kind_check';
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_locale FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.contract_texts'::regclass AND c.conname = 'contract_texts_locale_check';
  SELECT pg_catalog.pg_get_expr(p.polqual, p.polrelid) INTO v_policy FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.contract_texts'::regclass AND p.polname = 'contract_texts_published_read';
  SELECT pg_catalog.count(*)::integer INTO v_autres FROM pg_catalog.pg_policy p
   WHERE p.polrelid = 'public.contract_texts'::regclass AND p.polname <> 'contract_texts_published_read';

  IF v_kind IS NULL
     OR v_kind NOT IN ('CHECK ((contract_kind = ''teacher_nda''::text))',
                       'CHECK ((contract_kind = ANY (ARRAY[''teacher_nda''::text, ''teacher_religious_framework''::text])))') THEN
    RAISE EXCEPTION 'CADRE : contract_texts_contract_kind_check inattendu (%), arret', v_kind;
  END IF;
  IF v_locale IS NULL
     OR v_locale NOT IN ('CHECK ((locale = ''fr''::text))',
                         'CHECK ((locale = ANY (ARRAY[''fr''::text, ''ar''::text])))') THEN
    RAISE EXCEPTION 'CADRE : contract_texts_locale_check inattendu (%), arret', v_locale;
  END IF;
  IF v_policy IS NULL OR v_policy NOT IN ('(is_current AND (locale = ''fr''::text))', 'is_current') THEN
    RAISE EXCEPTION 'CADRE : policy contract_texts_published_read inattendue (%), arret', v_policy;
  END IF;
  IF v_autres <> 0 THEN
    RAISE EXCEPTION 'CADRE : % autre(s) policy sur contract_texts, a relire avant de continuer', v_autres;
  END IF;
END;
$preflight$;

-- (1) Le cadre religieux et pedagogique de l'enseignant.
ALTER TABLE public.contract_texts DROP CONSTRAINT IF EXISTS contract_texts_contract_kind_check;
ALTER TABLE public.contract_texts ADD CONSTRAINT contract_texts_contract_kind_check
  CHECK (contract_kind IN ('teacher_nda', 'teacher_religious_framework'));

-- (2) Le francais et l'arabe.
ALTER TABLE public.contract_texts DROP CONSTRAINT IF EXISTS contract_texts_locale_check;
ALTER TABLE public.contract_texts ADD CONSTRAINT contract_texts_locale_check
  CHECK (locale IN ('fr', 'ar'));

-- (3) Tout texte en vigueur, quelle que soit sa langue. L'acceptation du
-- contrat teacher_nda reste bornee au francais par sa propre policy
-- (contract_acceptances_self_insert), qui n'est pas touchee.
DROP POLICY IF EXISTS contract_texts_published_read ON public.contract_texts;
CREATE POLICY contract_texts_published_read ON public.contract_texts
  FOR SELECT TO authenticated USING (is_current);

DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                  WHERE c.conrelid = 'public.contract_texts'::regclass
                    AND c.conname = 'contract_texts_contract_kind_check'
                    AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%teacher_religious_framework%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                     WHERE c.conrelid = 'public.contract_texts'::regclass
                       AND c.conname = 'contract_texts_locale_check'
                       AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''ar''%')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p
                     WHERE p.polrelid = 'public.contract_texts'::regclass
                       AND p.polname = 'contract_texts_published_read'
                       AND p.polcmd = 'r'
                       AND pg_catalog.pg_get_expr(p.polqual, p.polrelid) = 'is_current'
                       AND p.polroles = ARRAY['authenticated'::regrole]::oid[]) THEN
    RAISE EXCEPTION 'CADRE : schema incomplet apres le fichier 1';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.contract_texts'::regclass AND c.relrowsecurity)
     OR pg_catalog.has_table_privilege('anon', 'public.contract_texts', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.contract_texts', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.contract_texts', 'UPDATE') THEN
    RAISE EXCEPTION 'CADRE : RLS ou droits inattendus sur contract_texts';
  END IF;
END;
$postflight$;
