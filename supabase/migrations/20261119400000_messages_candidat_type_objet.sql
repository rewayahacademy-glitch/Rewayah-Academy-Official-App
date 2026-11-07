-- MESSAGES-CANDIDAT (07/11/2026) : l'objet « candidature » entre dans la
-- contrainte des types d'objet des fils de la messagerie metier (COM-BACK-1).
-- Plage reservee par le garde-cap : 20261119400000 a 20261119499999 (PR 302).
-- Decision : CAND-Q06 (21/10/2026), « on y ajoute l'objet candidature ».
--
-- FICHIER A MOT D'EFFACEMENT (B5) : il remplace la contrainte
-- com_fils_type_objet_check (DROP CONSTRAINT IF EXISTS puis ADD). Le directeur
-- le colle dans l'editeur SQL, AVANT 20261119400100 (qui l'exige et s'arrete
-- s'il manque). Sans BEGIN ni COMMIT de premier niveau : un seul bloc,
-- atomique par lui-meme.
--
-- La liste est LUE dans la contrainte en place, sous ses deux formes
-- (ARRAY['x'::text, ...] ou '{x,y}'::text[]), et 'candidature' y est ajoute
-- s'il n'y est pas. Rien n'est retire. Un rejeu ne change rien. Postflight :
-- chaque ancienne valeur est encore dans la contrainte.

DO $migration$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.com_fils'::regclass
     AND c.conname = 'com_fils_type_objet_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'messages candidat : la contrainte com_fils_type_objet_check est absente';
  END IF;
  IF v_def LIKE '%''candidature''%' THEN
    RAISE NOTICE 'messages candidat : candidature deja dans la contrainte, rien a faire';
    RETURN;
  END IF;
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_liste
    FROM pg_catalog.regexp_matches(v_def, '''([A-Za-z_]+)''::text', 'g')
         WITH ORDINALITY AS r(m, ord);
  IF v_liste IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_liste
      FROM pg_catalog.regexp_matches(v_def, '''\{([A-Za-z_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_liste IS NULL OR pg_catalog.cardinality(v_liste) < 5
     OR NOT ('classe' = ANY (v_liste)) OR NOT ('profilPaiement' = ANY (v_liste)) THEN
    RAISE EXCEPTION 'messages candidat : liste des types illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['candidature'];

  ALTER TABLE public.com_fils DROP CONSTRAINT IF EXISTS com_fils_type_objet_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.com_fils ADD CONSTRAINT com_fils_type_objet_check CHECK (type_objet IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.com_fils'::regclass
     AND c.conname = 'com_fils_type_objet_check';
  IF v_def IS NULL OR v_def NOT LIKE '%''candidature''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'messages candidat : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$migration$;
