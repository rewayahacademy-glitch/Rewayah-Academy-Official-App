-- AUDIT-FAMILLE-3 (directeur, 22/11/2026) : « Ecrire a la direction » pour une famille ou un eleve adulte dont la
-- demande attend, est « a completer » ou refusee (R1, R30, L3). AUCUN nouveau circuit : la messagerie metier
-- existante (MESSAGES-CANDIDAT, fil de type « candidature ») s'ouvre au titulaire d'une demande de famille ou
-- d'eleve adulte, comme elle l'etait au candidat enseignant.
--
--   * private.com_appelant_candidat() : le titulaire en attente (role guardian, compte pending_kyc, avec une demande
--     famille ou eleve_adulte) est un appelant de la messagerie, comme le candidat enseignant. Il ne voit que son fil
--     « candidature » (com_fil_json) ; private.com_appelant() n'est PAS touchee.
--   * private.com_candidature_lisible() : une demande de famille est lue par son titulaire et par toute direction
--     active (le cloisonnement par cote ne vaut que pour les candidatures d'enseignants : les gestes d'admission des
--     familles sont deja ouverts a toute direction active).
--   * private.com_paires() : le titulaire d'une demande de famille ecrit tant qu'elle est en cours ou refusee (un
--     refus se rouvre pendant 7 jours et la famille doit pouvoir demander pourquoi) ; plus apres l'acceptation, ou
--     elle a la messagerie ordinaire. Pour l'enseignant rien ne change.
--   * public.com_ma_candidature() : rend aussi l'identifiant de la demande du titulaire.
--
-- Remplacement par ancres (chacune trouvee une fois, sinon la migration s'arrete et le dit). MOTS D'EFFACEMENT :
-- ZERO. Sans BEGIN ni COMMIT de premier niveau. Rejouable (deuxieme passage : rien a faire).

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_appelant_candidat()') IS NULL
     OR pg_catalog.to_regprocedure('private.com_candidature_lisible(uuid,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.com_paires(text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.com_ma_candidature()') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-3 : la messagerie du candidat (MESSAGES-CANDIDAT) n''est pas installee';
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
      RAISE EXCEPTION 'AUDIT-FAMILLE-3 : ancre trouvee % fois (attendu 1) dans % : %', v_n, p_f, p_ancres[i];
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
    RAISE EXCEPTION 'AUDIT-FAMILLE-3 : proprietaire, SECURITY DEFINER, search_path ou droits modifies pour %', p_f;
  END IF;
END
$r$;

DO $migration$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_appelant_candidat()'::regprocedure),
                       '''famille''') > 0 THEN
    RAISE NOTICE 'AUDIT-FAMILLE-3 : deja installee, rien a faire';
    RETURN;
  END IF;

  PERFORM pg_temp.remplacer('private.com_appelant_candidat()'::regprocedure,
    ARRAY['AND p.role = ''teacher''
    AND p.role::text',
          'WHERE c.profile_id = p.id AND c.type_code = ''enseignant'''],
    ARRAY['AND p.role IN (''teacher'', ''guardian'')
    AND p.role::text',
          'WHERE c.profile_id = p.id
                   AND ((p.role = ''teacher'' AND c.type_code = ''enseignant'')
                        OR (p.role = ''guardian'' AND c.type_code IN (''famille'', ''eleve_adulte'')))']);

  PERFORM pg_temp.remplacer('private.com_candidature_lisible(uuid,uuid)'::regprocedure,
    ARRAY['AND c.type_code = ''enseignant''',
          'AND private.entretien_cote_permis(p_moi, c.genre)'],
    ARRAY['AND c.type_code IN (''enseignant'', ''famille'', ''eleve_adulte'')',
          'AND (c.type_code <> ''enseignant'' OR private.entretien_cote_permis(p_moi, c.genre))']);

  PERFORM pg_temp.remplacer('private.com_paires(text,uuid)'::regprocedure,
    ARRAY['cd.type_code = ''enseignant'' AND cd.profile_id IS NOT NULL',
          'AND cd.issue = ''en_cours'' AND NOT cd.en_pause AND cd.etape <> ''confirmee'''],
    ARRAY['cd.type_code IN (''enseignant'', ''famille'', ''eleve_adulte'') AND cd.profile_id IS NOT NULL',
          'AND cd.etape <> ''confirmee''
        AND ((cd.type_code = ''enseignant'' AND cd.issue = ''en_cours'' AND NOT cd.en_pause)
             OR (cd.type_code <> ''enseignant'' AND cd.issue IN (''en_cours'', ''refusee'')))']);

  PERFORM pg_temp.remplacer('public.com_ma_candidature()'::regprocedure,
    ARRAY['AND c.type_code = ''enseignant'''],
    ARRAY['AND c.type_code IN (''enseignant'', ''famille'', ''eleve_adulte'')']);

  RAISE NOTICE 'AUDIT-FAMILLE-3 : installee';
END
$migration$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_appelant_candidat()'::regprocedure), '''famille''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_candidature_lisible(uuid,uuid)'::regprocedure), '''famille''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_paires(text,uuid)'::regprocedure), '''famille''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.com_ma_candidature()'::regprocedure), '''famille''') = 0 THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-3 : une des quatre fonctions n''a pas la forme attendue';
  END IF;
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.com_ma_candidature()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.com_ma_candidature()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.com_appelant_candidat()', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-3 : droits inattendus';
  END IF;
END
$postflight$;
