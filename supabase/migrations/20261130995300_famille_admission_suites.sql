-- AUDIT-FAMILLE-7 (directeur, 22/11/2026) : ce que la famille voit et recoit autour de la decision de la direction.
--   a. ma_demande_admission() rend aussi `motif` : le modele du refus (refus_general, refus_niveau, refus_besoins,
--      refus_sans_reponse) quand la demande est refusee, pour que l'application dise la raison sans dependre du
--      courriel (perdu ou en spam). Le motif INTERNE n'est jamais rendu : seulement le modele deja envoye a la famille.
--   b. annuler_admission (acceptation annulee, 7 jours) et annuler_refus_admission (refus annule, 7 jours) envoient
--      un courriel `admission_reprise` : sans lui, la famille voyait « en cours » sans un mot (R26, R31).
-- Remplacement par ancres (une fois chacune, sinon la migration s'arrete). MOTS D'EFFACEMENT : ZERO. Sans BEGIN ni
-- COMMIT de premier niveau. Rejouable.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.ma_demande_admission()') IS NULL
     OR pg_catalog.to_regprocedure('public.annuler_admission(uuid,text,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('public.annuler_refus_admission(uuid,text,integer,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.admission_courriel(public.candidatures,text,jsonb,text)') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-7 : une fonction d''admission manque';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_f regprocedure, p_ancres text[], p_nouvelles text[])
RETURNS void LANGUAGE plpgsql AS $r$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_apres text;
  v_n integer;
  v_com text;
  v_avant record;
  i integer;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = p_f;
  v_apres := v_def;
  FOR i IN 1 .. pg_catalog.cardinality(p_ancres) LOOP
    v_n := (pg_catalog.length(v_apres) - pg_catalog.length(pg_catalog.replace(v_apres, p_ancres[i], '')))
           / pg_catalog.length(p_ancres[i]);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'AUDIT-FAMILLE-7 : ancre trouvee % fois (attendu 1) dans % : %', v_n, p_f, p_ancres[i];
    END IF;
    v_apres := pg_catalog.replace(v_apres, p_ancres[i], p_nouvelles[i]);
  END LOOP;
  EXECUTE v_apres;
  v_com := pg_catalog.obj_description(p_f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f, v_com);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = p_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-7 : proprietaire, SECURITY DEFINER, search_path ou droits modifies pour %', p_f;
  END IF;
END
$r$;

DO $migration$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.ma_demande_admission()'::regprocedure),
                       '''motif''') > 0 THEN
    RAISE NOTICE 'AUDIT-FAMILLE-7 : deja installee, rien a faire';
    RETURN;
  END IF;

  PERFORM pg_temp.remplacer('public.ma_demande_admission()'::regprocedure,
    ARRAY['''recue_le'', c.recue_le,'],
    ARRAY['''recue_le'', c.recue_le,
           ''motif'', CASE WHEN c.issue = ''refusee'' THEN c.issue_modele END,']);

  PERFORM pg_temp.remplacer('public.annuler_admission(uuid,text,integer,text)'::regprocedure,
    ARRAY['  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, ''annuler_admission'', auth.uid(),'],
    ARRAY['  PERFORM private.admission_courriel(v_c, ''admission_reprise'',
    pg_catalog.jsonb_build_object(''cas'', ''acceptation''),
    ''admission_reprise:'' || v_c.id::text || '':'' || p_cle_idempotence);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, ''annuler_admission'', auth.uid(),']);

  PERFORM pg_temp.remplacer('public.annuler_refus_admission(uuid,text,integer,text)'::regprocedure,
    ARRAY['  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, ''rouvrir_admission'', auth.uid(),'],
    ARRAY['  PERFORM private.admission_courriel(v_c, ''admission_reprise'',
    pg_catalog.jsonb_build_object(''cas'', ''refus''),
    ''admission_reprise:'' || v_c.id::text || '':'' || p_cle_idempotence);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, ''rouvrir_admission'', auth.uid(),']);

  RAISE NOTICE 'AUDIT-FAMILLE-7 : installee';
END
$migration$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.ma_demande_admission()'::regprocedure), '''motif''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.annuler_admission(uuid,text,integer,text)'::regprocedure), 'admission_reprise') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.annuler_refus_admission(uuid,text,integer,text)'::regprocedure), 'admission_reprise') = 0 THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-7 : une fonction n''a pas la forme attendue';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.ma_demande_admission()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.ma_demande_admission()', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-7 : droits inattendus sur ma_demande_admission';
  END IF;
END
$postflight$;
