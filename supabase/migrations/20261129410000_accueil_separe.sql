-- ACCUEIL-SEPARE (pilote, 16/11/2026, carte des gestes de la direction, trous T1 et T4, arbitrage A1) :
-- « Accueillir dans l'equipe » (public.valider_piece_candidat) ne decide plus de la piece et ne passe plus sur un
-- complement en attente.
--
--   T1 : valider_piece_candidat approuvait elle-meme une piece `pending` ; la piece se decide maintenant a part, par
--        public.decider_dossier (« Fichiers a valider » ou la fiche), puis l'accueil exige une piece `approved`.
--        Verifie sur la fonction en vigueur : decider_dossier ne change JAMAIS l'etape de la candidature ; pour une
--        candidature en cours avant `confirmee` il n'active pas le compte (v_candidat_avant_salle3), il pose la piece et
--        teacher_profiles.kyc_status. Aucune etape ne bouge avant l'accueil.
--   T4 : private.candidature_controles_salle3 ne lisait pas le complement en cours : la fonction
--        private.candidature_complement_en_cours existe (COMPLEMENT-EN-COURS) ; un complement ouvert refuse l'accueil.
--
-- Deux controles de plus, nommes, dans private.candidature_controles_salle3 (donc dans la reponse `controles` du refus,
-- pour que l'ecran dise la phrase) :
--   piece_validee : vrai quand la piece non effacee la plus recente est `approved` ; causes piece_absente,
--                   piece_a_verifier (en attente), piece_a_redeposer (refusee), compte_absent : le vocabulaire de
--                   private.candidature_controles_dossier, que l'ecran dit deja en mots.
--   complement_clos : vrai quand aucun complement n'est ouvert ; cause complement_en_cours. L'ecran n'a pas encore de
--                   phrase pour cette cause (repli « inconnue ») : a ajouter cote ecran.
--
-- Effets de bord a connaitre : private.candidature_controles_salle3 est lue par valider_piece_candidat,
-- private.candidature_controles_dossier (commentaire seulement) et lister_candidatures (seulement
-- paiement_compatible et profil_unique, par nom) : aucune autre lecture ne change. Le cas « aucune piece deposee » rend
-- desormais la cause `piece_absente` (et non plus `absente`) : meme nom de controle, meme refus, meme vocabulaire que le
-- dossier.
--
-- FICHIER SANS EFFACEMENT : aucun des trois mots d'effacement. Additif : deux fonctions retouchees par ancrage (jamais
-- une copie entiere). Sans BEGIN/COMMIT de premier niveau.

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'ACCUEIL-SEPARE : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- 1. Les deux controles, en fin de la liste de la salle 3.
DO $retouche$
DECLARE
  v_f regprocedure := 'private.candidature_controles_salle3(public.candidatures)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, '''complement_clos''') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      '
  RETURN v_resultat;
END;',
      '

  -- ACCUEIL-SEPARE : la piece la plus recente est approuvee (decidee a part), et aucun complement n''attend.
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    ''nom'', ''piece_validee'',
    ''valeur'', coalesce((SELECT k.status = ''approved''::public.kyc_doc_status
                          FROM public.kyc_documents k
                         WHERE k.profile_id = c.profile_id AND k.deleted_at IS NULL
                         ORDER BY k.created_at DESC, k.id DESC LIMIT 1), false),
    ''cause'', CASE
      WHEN c.profile_id IS NULL THEN ''compte_absent''
      WHEN NOT EXISTS (SELECT 1 FROM public.kyc_documents k
                        WHERE k.profile_id = c.profile_id AND k.deleted_at IS NULL) THEN ''piece_absente''
      ELSE (SELECT CASE k.status::text WHEN ''approved'' THEN NULL
                                       WHEN ''rejected'' THEN ''piece_a_redeposer''
                                       ELSE ''piece_a_verifier'' END
              FROM public.kyc_documents k
             WHERE k.profile_id = c.profile_id AND k.deleted_at IS NULL
             ORDER BY k.created_at DESC, k.id DESC LIMIT 1)
      END));
  v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
    ''nom'', ''complement_clos'',
    ''valeur'', pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) = 0,
    ''cause'', CASE WHEN pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
                    THEN ''complement_en_cours'' END));
  RETURN v_resultat;
END;',
      'controles.fin');
    EXECUTE v_def;
  END IF;
  v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
    IF pg_catalog.strpos(v_com, 'ACCUEIL-SEPARE') = 0 THEN
      v_com := v_com || ' ACCUEIL-SEPARE (16/11/2026) : controles piece_validee (piece la plus recente approuvee) et complement_clos (aucun complement ouvert). Must-pass aussi : supabase/tests/scenarios_accueil_separe.sql.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
  END IF;
END;
$retouche$;

-- 2. L'accueil n'approuve plus la piece : elle doit l'etre deja.
DO $retouche$
DECLARE
  v_f regprocedure := 'public.valider_piece_candidat(uuid,integer,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_com text;
BEGIN
  IF pg_catalog.strpos(v_def, 'ACCUEIL-SEPARE') = 0 THEN
    v_def := pg_temp.remplacer(v_def,
      'IF v_doc.id IS NULL OR v_doc.status NOT IN (''pending''::public.kyc_doc_status,
                                              ''approved''::public.kyc_doc_status) THEN',
      '-- ACCUEIL-SEPARE : la piece se decide a part (decider_dossier) ; ici elle doit etre approuvee.
  IF v_doc.id IS NULL OR v_doc.status IS DISTINCT FROM ''approved''::public.kyc_doc_status THEN',
      'piece.garde');
    v_def := pg_temp.remplacer(v_def,
      '  IF v_doc.status = ''pending''::public.kyc_doc_status THEN
    UPDATE public.kyc_documents
       SET status = ''approved''::public.kyc_doc_status, rejection_reason = NULL,
           verified_by = v_uid, verified_at = pg_catalog.now()
     WHERE id = v_doc.id;
    PERFORM public.log_sensitive_access(''kyc_decision'', ''kyc_documents'', v_doc.id::text,
      pg_catalog.jsonb_build_object(''approuve'', true, ''motif'', '''', ''acces_retire'', false,
                                    ''geste'', ''valider_piece'', ''candidature'', v_c.id));
  END IF;

',
      '',
      'piece.approbation');
    EXECUTE v_def;
  END IF;
  v_com := coalesce(pg_catalog.obj_description(v_f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
    IF pg_catalog.strpos(v_com, 'ACCUEIL-SEPARE') = 0 THEN
      v_com := v_com || ' ACCUEIL-SEPARE (16/11/2026) : n''approuve plus la piece (elle doit l''etre, decidee par decider_dossier) et refuse un complement en cours, par les controles piece_validee et complement_clos.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_com);
  END IF;
END;
$retouche$;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'private.candidature_controles_salle3(public.candidatures)'::regprocedure), '''complement_clos''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.valider_piece_candidat(uuid,integer,text)'::regprocedure), 'ACCUEIL-SEPARE') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.valider_piece_candidat(uuid,integer,text)'::regprocedure), 'SET status = ''approved''') > 0 THEN
    RAISE EXCEPTION 'ACCUEIL-SEPARE : retouche absente ou approbation encore presente';
  END IF;
END
$postflight$;
