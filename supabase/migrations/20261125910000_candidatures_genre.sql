-- SALLE2-GENRE (directeur, 14/11/2026, relaye par le pilote) : la direction
-- voit le genre du candidat (Homme / Femme) dans la liste des candidatures et
-- en tete de la fiche, et filtre la liste par genre.
--
-- Change une regle d'avant, a la demande expresse et la plus recente du
-- directeur : depuis CAND-L1 (20261021200000), une ligne ne portait « ni
-- courriel, ni telephone, ni genre ». Le genre entre dans la ligne ; le
-- courriel et le telephone restent hors de la ligne (« Voir le contact »).
-- La portee ne change pas : la direction ne lit que les candidatures de son
-- cote (CAND-Q07), le super-admin les deux.
--
-- 1. private.cand_ligne_json : une cle de plus, 'genre' (male, female), par
--    ancre sur le corps de production (lue par lister_candidatures et
--    lire_candidature).
-- 2. public.lister_candidatures : le filtre 'genre' ('male' ou 'female'),
--    par ancre ; une autre valeur est refusee comme tout filtre mal forme.
--    L'empreinte F86 du commentaire suit le nouveau corps.
--
-- Preflight : md5 de production lus le 14/11/2026 (lecture seule) :
-- cand_ligne_json adebd6585fd904f90cafbbecf9d56003, lister_candidatures
-- 5e8276c73744877c65743a627f288877, egaux au depot.
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

DO $genre$
DECLARE
  f_ligne regprocedure := 'private.cand_ligne_json(public.candidatures)'::regprocedure;
  f_liste regprocedure := 'public.lister_candidatures(jsonb,text,integer)'::regprocedure;
  v_def text;
  v_com text;
  v_avant text;
  v_apres text;
BEGIN
  -- 1. La ligne.
  v_def := pg_catalog.pg_get_functiondef(f_ligne);
  IF pg_catalog.strpos(v_def, '''genre'', c.genre') > 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : deja installee';
  END IF;
  IF pg_catalog.md5(v_def) <> 'adebd6585fd904f90cafbbecf9d56003' THEN
    RAISE EXCEPTION 'SALLE2-GENRE : cand_ligne_json a change depuis le depot (md5 %)', pg_catalog.md5(v_def);
  END IF;
  v_avant := '''paysResidence'', c.pays_residence,';
  v_apres := '''paysResidence'', c.pays_residence,' || E'\n    ''genre'', c.genre,';
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : ancre de cand_ligne_json introuvable';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);

  -- 2. Le filtre de la liste.
  v_def := pg_catalog.pg_get_functiondef(f_liste);
  IF pg_catalog.md5(v_def) <> '5e8276c73744877c65743a627f288877' THEN
    RAISE EXCEPTION 'SALLE2-GENRE : lister_candidatures a change depuis le depot (md5 %)', pg_catalog.md5(v_def);
  END IF;
  v_avant := '''paysResidence'', ''recherche'', ''competenceDomaine'',';
  v_apres := '''paysResidence'', ''recherche'', ''competenceDomaine'', ''genre'',';
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : ancre des cles de filtre introuvable';
  END IF;
  v_def := pg_catalog.replace(v_def, v_avant, v_apres);
  v_avant := '  v_pays := v_filtre ->> ''paysResidence'';';
  v_apres := '  v_pays := v_filtre ->> ''paysResidence'';' || E'\n'
    || '  -- SALLE2-GENRE : male ou female seulement.' || E'\n'
    || '  IF v_filtre ->> ''genre'' IS NOT NULL AND v_filtre ->> ''genre'' NOT IN (''male'', ''female'') THEN' || E'\n'
    || '    RAISE EXCEPTION ''filtre de candidatures mal type : genre'' USING ERRCODE = ''22023'';' || E'\n'
    || '  END IF;';
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : ancre du filtre pays introuvable';
  END IF;
  v_def := pg_catalog.replace(v_def, v_avant, v_apres);
  v_avant := '      AND (v_pays IS NULL OR c.pays_residence = v_pays)';
  v_apres := '      AND (v_pays IS NULL OR c.pays_residence = v_pays)' || E'\n'
    || '      AND (v_filtre ->> ''genre'' IS NULL OR c.genre::text = v_filtre ->> ''genre'')';
  IF pg_catalog.strpos(v_def, v_avant) = 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : ancre du WHERE introuvable';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_avant, v_apres);

  v_com := pg_catalog.obj_description(f_liste, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f_liste)));
    IF pg_catalog.strpos(v_com, 'SALLE2-GENRE') = 0 THEN
      v_com := v_com || ' SALLE2-GENRE (14/11/2026) : filtre genre (male, female).';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f_liste, v_com);
  END IF;
END;
$genre$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.cand_ligne_json(public.candidatures)'::regprocedure),
                       '''genre'', c.genre') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'c.genre::text = v_filtre') = 0 THEN
    RAISE EXCEPTION 'SALLE2-GENRE : retouche absente';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.cand_ligne_json(public.candidatures)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SALLE2-GENRE : droits inattendus';
  END IF;
END;
$postflight$;
