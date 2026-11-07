-- SALLE-3-ACCUEIL (07/11/2026) : l'evenement « bienvenue_equipe » entre dans la
-- contrainte des evenements de notifications. Plage reservee par le garde-cap :
-- 20261119000000 a 20261119099999.
--
-- FICHIER A MOT D'EFFACEMENT (B5) : il remplace la contrainte
-- notifications_evenement_check (DROP CONSTRAINT IF EXISTS puis ADD). Le
-- directeur le colle dans l'editeur SQL, AVANT 20261119000100 (qui le verifie
-- et s'arrete s'il manque). Sans BEGIN ni COMMIT de premier niveau : un seul
-- bloc, atomique par lui-meme.
--
-- L'ordre d'installation avec les autres lots qui elargissent la meme
-- contrainte n'a pas d'importance : la liste est LUE dans la contrainte en
-- place, 'bienvenue_equipe' y est ajoute s'il n'y est pas, et rien d'autre
-- n'est retire ni ajoute. Un rejeu ne change rien.

DO $migration$
DECLARE
  v_def text;
  v_liste text[];
  v_nouvelle text[];
BEGIN
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL THEN
    RAISE EXCEPTION 'bienvenue_equipe : la contrainte notifications_evenement_check est absente';
  END IF;
  IF v_def LIKE '%''bienvenue_equipe''%' THEN
    RAISE NOTICE 'bienvenue_equipe : deja dans la contrainte, rien a faire';
    RETURN;
  END IF;
  -- Les evenements de la contrainte en place, dans leur ordre. Selon le fichier
  -- qui l'a posee, pg_get_constraintdef rend la liste sous deux formes :
  -- ARRAY['x'::text, 'y'::text] ou '{x,y}'::text[]. Les deux sont lues.
  SELECT pg_catalog.array_agg(m[1] ORDER BY ord) INTO v_liste
    FROM pg_catalog.regexp_matches(v_def, '''([a-z_]+)''::text', 'g')
         WITH ORDINALITY AS r(m, ord);
  IF v_liste IS NULL THEN
    SELECT pg_catalog.string_to_array(m[1], ',') INTO v_liste
      FROM pg_catalog.regexp_matches(v_def, '''\{([a-z_,]+)\}''::text\[\]') AS r(m);
  END IF;
  IF v_liste IS NULL OR pg_catalog.cardinality(v_liste) < 10
     OR NOT ('demande_recue' = ANY (v_liste)) THEN
    RAISE EXCEPTION 'bienvenue_equipe : liste des evenements illisible dans %', v_def;
  END IF;
  v_nouvelle := v_liste || ARRAY['bienvenue_equipe'];

  ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_evenement_check;
  EXECUTE pg_catalog.format(
    'ALTER TABLE public.notifications ADD CONSTRAINT notifications_evenement_check CHECK (evenement IN (%s))',
    (SELECT pg_catalog.string_agg(pg_catalog.quote_literal(e), ', ' ORDER BY ord)
       FROM pg_catalog.unnest(v_nouvelle) WITH ORDINALITY AS u(e, ord)));

  -- Postflight : tout ce qui y etait y est encore, plus le nouvel evenement.
  SELECT pg_catalog.pg_get_constraintdef(c.oid) INTO v_def
    FROM pg_catalog.pg_constraint c
   WHERE c.conrelid = 'public.notifications'::regclass
     AND c.conname = 'notifications_evenement_check';
  IF v_def IS NULL OR v_def NOT LIKE '%''bienvenue_equipe''%'
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v_liste) AS e WHERE v_def NOT LIKE '%''' || e || '''%') THEN
    RAISE EXCEPTION 'bienvenue_equipe : la contrainte n''est pas celle attendue : %', v_def;
  END IF;
END
$migration$;
