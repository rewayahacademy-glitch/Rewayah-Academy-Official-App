-- DOSSIER-DIRECTION (vague 2 du parcours enseignant, 20/11/2026) : lots PE-C1 (partie serveur), PE-C2 et PE-C10.
-- Plan : docs/current/PARCOURS-ENSEIGNANT/PLAN.md §3.1, §3.2, A1, A2, A7, §12.1 ; check-liste SUIVI.md.
--
-- LE PROBLEME
--   PE-C1 : les Comptes, l'Espace de traitement et les notifications ouvrent encore « Fichiers a valider »
--           (/admin/personnes/dossiers), parce qu'aucune lecture ne donne la candidature depuis un profil.
--   PE-C2 : la synthese en tete du dossier n'a pas la derniere connexion de la personne ; aucune lecture ne la rend.
--   PE-C10 : « Demander un complement » ne sait pas ce qui manque au dossier : seule la piece (ou la photo) s'ouvre cochee.
--
-- LIVRE ICI
--   1. public.references_dossiers_admin(uuid[]) (NEUVE) : pour une liste de profils (500 au plus), la reference
--      `CAND-...` de leur candidature d'ENSEIGNANT, dans la portee de genre du lecteur (meme regle que lire_candidature :
--      meme genre, ou exception du super-admin journalisee par lire_candidature a l'ouverture). Direction active seulement.
--      Pourquoi une fonction a cote, et non une colonne de plus dans comptes_admin_par_role() ou dossiers_en_attente() :
--      leur type de retour (RETURNS TABLE) ne change pas par CREATE OR REPLACE ; l'elargir demande de retirer la fonction,
--      ce qui est exclu ici. read_kyc_documents() rend SETOF kyc_documents : meme limite.
--   2. public.lire_candidature(uuid) (REMPLACEE, signature identique) : deux cles de plus dans la reponse,
--        `derniereConnexion` : auth.users.last_sign_in_at du compte de la candidature (la seule source : aucune autre
--                              lecture n'existe dans le depot), null sans compte ou jamais connecte ;
--        `manquants`         : ce que LA PERSONNE doit encore fournir, en codes, lu par private.praxis_dossier_manques
--                              (PX-3, deja en production ; appelee, jamais modifiee ni recopiee). Codes possibles :
--                              compte, cadre_religieux, contrat, avis, code_conduite, piece_identite, questionnaire,
--                              pays_versement, photo, accord_publication, et les codes d'un complement en cours.
--   3. private.push1_depuis_candidature() et private.push1_depuis_piece() (REMPLACEES, signature identique) : la
--      notification d'une candidature d'enseignant a examiner, et celle d'une piece deposee par un candidat enseignant,
--      portent la reference dans params (`reference`). La DESTINATION ne change pas : la contrainte
--      notifications_destination_check n'admet que des chemins fixes, et la reecrire demande de retirer la contrainte,
--      ce qui est exclu ici. L'application compose le chemin du dossier a partir de `reference`.
--   Les notifications DEJA envoyees ne sont pas reecrites (aucun UPDATE de donnees de personnes sans decision du
--   directeur) : elles ouvrent toujours la liste ou « Fichiers a valider ».
--
-- CE QUI N'EST PAS FAIT ICI
--   * Le telephone (push) et le courriel ouvrent toujours la liste ou « Fichiers a valider » : ils lisent `destination`.
--   * « Admettre a l'entretien » sans piece verifiee reste permis (Q4 du plan, sans reponse du directeur). « Accueillir »
--     l'interdit deja cote serveur (ACCUEIL-SEPARE, 20261129410000, installee en production le 16/11/2026).
--
-- MOTS D'EFFACEMENT : ZERO. Additif. Sans BEGIN/COMMIT de premier niveau.
--
-- EMPREINTES ATTENDUES AVANT REMPLACEMENT (md5(prosrc), lues sur une base rejouee jusqu'a 20261130400000,
-- puis relues identiques le 20/11/2026 sur une base rejouee jusqu'a 20261130960000, etat de main : aucune migration
-- 20261130800000, 910000, 930000 ni 960000 ne remplace ces fonctions ; d'ou le nom 20261130965000, posterieur a
-- celles deja installees en production) :
--   public.lire_candidature(uuid)              a3e65e5dfcc469ef073986ab5940e94b
--   private.push1_depuis_candidature()         dd4437ebaa00ccb5d2d32508ce103cf7
--   private.push1_depuis_piece()               13c945780201c684443c8db0290e5c6f
--   private.praxis_dossier_manques(candidatures) 875b81416310cd9c0269d82ffab90a62 (lue seulement, jamais remplacee)

-- 0. Controle des empreintes -------------------------------------------------
DO $empreintes$
DECLARE
  v record;
BEGIN
  IF pg_catalog.to_regprocedure('private.praxis_dossier_manques(public.candidatures)') IS NULL THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION : private.praxis_dossier_manques absente (PX-3, 20261130100000, a installer d''abord)';
  END IF;
  FOR v IN SELECT * FROM (VALUES
      ('public.lire_candidature(uuid)', 'a3e65e5dfcc469ef073986ab5940e94b'),
      ('private.push1_depuis_candidature()', 'dd4437ebaa00ccb5d2d32508ce103cf7'),
      ('private.push1_depuis_piece()', '13c945780201c684443c8db0290e5c6f')) AS t(f, md5) LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL THEN
      RAISE EXCEPTION 'DOSSIER-DIRECTION : % absente', v.f;
    END IF;
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = v.f::pg_catalog.regprocedure)
       IS DISTINCT FROM v.md5 THEN
      -- Deja remplacee par cette migration : on la reconnait a son marqueur, on rejoue sans erreur.
      IF (SELECT pg_catalog.strpos(p.prosrc, 'DOSSIER-DIRECTION') FROM pg_catalog.pg_proc p
           WHERE p.oid = v.f::pg_catalog.regprocedure) = 0 THEN
        RAISE EXCEPTION 'DOSSIER-DIRECTION : empreinte inattendue pour % (une autre migration l''a changee : relire)', v.f;
      END IF;
    END IF;
  END LOOP;
END
$empreintes$;

-- 1. Aides privees -------------------------------------------------------------

-- La reference de la candidature d'ENSEIGNANT d'un profil, ou null. Une seule par profil
-- (contrainte candidatures_type_profil_unique).
CREATE OR REPLACE FUNCTION private.reference_candidature_enseignant(p_profil uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT c.reference
    FROM public.candidatures c
   WHERE c.profile_id = p_profil
     AND c.type_code = 'enseignant'
   LIMIT 1;
$function$;

-- La derniere connexion d'un compte (auth.users.last_sign_in_at), ou null.
CREATE OR REPLACE FUNCTION private.derniere_connexion_compte(p_profil uuid)
RETURNS timestamptz
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT u.last_sign_in_at FROM auth.users u WHERE u.id = p_profil;
$function$;

ALTER FUNCTION private.reference_candidature_enseignant(uuid) OWNER TO postgres;
ALTER FUNCTION private.derniere_connexion_compte(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.reference_candidature_enseignant(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION private.derniere_connexion_compte(uuid) FROM PUBLIC;
DO $droits_prives$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON FUNCTION private.reference_candidature_enseignant(uuid) FROM anon;
    REVOKE ALL ON FUNCTION private.derniere_connexion_compte(uuid) FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    REVOKE ALL ON FUNCTION private.reference_candidature_enseignant(uuid) FROM authenticated;
    REVOKE ALL ON FUNCTION private.derniere_connexion_compte(uuid) FROM authenticated;
  END IF;
END
$droits_prives$;

-- 2. La reference depuis un profil (PE-C1) ---------------------------------------
CREATE OR REPLACE FUNCTION public.references_dossiers_admin(p_profils uuid[])
RETURNS TABLE(profile_id uuid, reference text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
  v_super boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'references de candidature reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_profils IS NULL OR pg_catalog.cardinality(p_profils) = 0 THEN
    RETURN;
  END IF;
  IF pg_catalog.cardinality(p_profils) > 500 THEN
    RAISE EXCEPTION 'au plus 500 profils par lecture' USING ERRCODE = '22023';
  END IF;
  SELECT p.gender INTO v_genre FROM public.profiles p WHERE p.id = auth.uid() AND p.deleted_at IS NULL;
  v_super := public.kyc_super_admin_exception_active();
  IF v_genre IS NULL AND NOT v_super THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  -- La reference seule : ni nom, ni etat. Le dossier se lit ensuite par lire_candidature, qui garde
  -- toutes ses gardes (mission, portee, journal).
  RETURN QUERY
    SELECT c.profile_id, c.reference
      FROM public.candidatures c
     WHERE c.profile_id = ANY (p_profils)
       AND c.type_code = 'enseignant'
       AND (v_super OR c.genre = v_genre);
END;
$function$;

ALTER FUNCTION public.references_dossiers_admin(uuid[]) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.references_dossiers_admin(uuid[]) FROM PUBLIC;
DO $droits_public$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'anon') THEN
    REVOKE ALL ON FUNCTION public.references_dossiers_admin(uuid[]) FROM anon;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'authenticated') THEN
    GRANT EXECUTE ON FUNCTION public.references_dossiers_admin(uuid[]) TO authenticated;
  END IF;
END
$droits_public$;

-- 3. Le dossier : derniere connexion et elements manquants (PE-C2, PE-C10) ---------
-- Corps de 20261129710000 et suivantes, recopie par pg_get_functiondef ; seul ajout : les deux cles en fin de reponse.
CREATE OR REPLACE FUNCTION public.lire_candidature(p_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
BEGIN
  IF NOT coalesce((public.app_role() = 'admin' OR private.mission_porteuse()) AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.mission_acteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) OR NOT private.mission_permis(v_c.id, 'lire') THEN
    RETURN private.cand_hors_portee(p_id, v_lecteur, 'dossier');
  END IF;
  IF v_super AND v_c.genre IS DISTINCT FROM v_genre THEN
    PERFORM public.log_sensitive_access('candidature_exception_super_admin', 'candidatures',
      p_id::text, pg_catalog.jsonb_build_object('lecture', 'dossier',
                                                'motif', 'exception_super_admin_kyc'));
  END IF;

  -- NOUVEAU-LISTE : la premiere ouverture seulement ; les suivantes n'ecrivent rien.
  IF v_c.ouverte_par_equipe_le IS NULL THEN
    UPDATE public.candidatures
       SET ouverte_par_equipe_le = pg_catalog.clock_timestamp(), ouverte_par_equipe_par = v_lecteur
     WHERE id = p_id AND ouverte_par_equipe_le IS NULL;
    v_c.ouverte_par_equipe_le := pg_catalog.clock_timestamp();
    v_c.ouverte_par_equipe_par := v_lecteur;
  END IF;

  RETURN private.cand_ligne_json(v_c) || pg_catalog.jsonb_build_object(
    'version', v_c.version,
    'source', v_c.source,
    'pauseModele', v_c.pause_modele,
    'refusModele', v_c.issue_modele,
    'restrictionCause', v_c.restriction_cause,
    'responsableNom', private.be_nom_membre(v_c.responsable_id),
    'majorite', pg_catalog.jsonb_build_object(
      'declaree', v_c.majorite_declaree,
      'attesteeLe', private.cand_instant(v_c.majorite_attestee_le)),
    'autresCompetences', (SELECT private.competences_json(a)
                           FROM public.candidature_autres_competences a
                          WHERE a.candidature_id = v_c.id),
    'reponses', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'questionnaireVersion', r.questionnaire_version,
               'reponses', r.reponses,
               'source', r.source,
               'soumisLe', private.cand_instant(r.soumis_le))
             ORDER BY r.soumis_le DESC, r.id DESC)
      FROM public.candidature_reponses r
      WHERE r.candidature_id = v_c.id), '[]'::jsonb),
    'controles', private.candidature_controles_dossier(v_c), -- AUDIT-PORTAIL-CANDIDAT
    'piece', NULL::jsonb)
    -- DOSSIER-DIRECTION (PE-C2, PE-C10) : la derniere connexion du compte, et ce que la personne doit encore fournir.
    || pg_catalog.jsonb_build_object(
    'derniereConnexion', CASE WHEN v_c.profile_id IS NOT NULL
                              THEN private.cand_instant(private.derniere_connexion_compte(v_c.profile_id)) END,
    'manquants', CASE WHEN v_c.type_code = 'enseignant'
                      THEN coalesce(private.praxis_dossier_manques(v_c) -> 'manquants', '[]'::jsonb) END);
END;
$function$;

-- 4. Les notifications portent la reference (PE-C1) --------------------------------
CREATE OR REPLACE FUNCTION private.push1_depuis_candidature()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v public.candidatures;
  v_n integer;
BEGIN
  BEGIN
    SELECT * INTO v FROM public.candidatures c WHERE c.id = NEW.id;
    IF NOT FOUND THEN
      RETURN NULL;
    END IF;
    IF v.type_code IN ('famille', 'eleve_adulte') THEN
      IF v.issue = 'en_cours' AND v.etape = 'recue' AND v.source <> 'import' THEN
        SELECT pg_catalog.count(*)::integer INTO v_n
          FROM public.candidature_apprenants a WHERE a.candidature_id = v.id;
        PERFORM private.notifier_direction('admission_recue',
          pg_catalog.jsonb_build_object('candidature_id', v.id, 'type', v.type_code, 'apprenants', v_n),
          '/admin/personnes/demandes', NULL, v.id::text);
      ELSE
        PERFORM private.push1_clore(ARRAY['admission_recue'], v.id::text);
      END IF;
    ELSIF v.type_code = 'enseignant' THEN
      IF v.issue = 'en_cours' AND v.etape = 'prequalification' AND v.etat = 'en_examen' THEN
        -- DOSSIER-DIRECTION : la reference, pour que l'application ouvre le dossier lui-meme.
        PERFORM private.notifier_direction('candidature_enseignant_a_examiner',
          pg_catalog.jsonb_build_object('candidature_id', v.id, 'reference', v.reference),
          '/admin/personnes/candidatures', NULL, v.id::text);
      ELSE
        PERFORM private.push1_clore(ARRAY['candidature_enseignant_a_examiner'], v.id::text);
      END IF;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('candidature', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION private.push1_depuis_piece()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  BEGIN
    IF NEW.status = 'pending' AND NEW.deleted_at IS NULL THEN
      IF TG_OP = 'INSERT' THEN
        -- DOSSIER-DIRECTION : la reference de la candidature d'enseignant du deposant, quand il en a une ;
        -- une piece de famille garde sa seule piece_id (jsonb_strip_nulls).
        PERFORM private.notifier_direction('piece_identite_deposee',
          pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
            'piece_id', NEW.id,
            'reference', private.reference_candidature_enseignant(NEW.profile_id))),
          '/admin/personnes/dossiers', NULL, NEW.id::text);
      END IF;
    ELSE
      PERFORM private.push1_clore(ARRAY['piece_identite_deposee'], NEW.id::text);
    END IF;
  EXCEPTION WHEN OTHERS THEN
    PERFORM private.push1_journaliser('piece_identite_deposee', NEW.id::text, SQLSTATE);
  END;
  RETURN NULL;
END;
$function$;

-- 5. F86 : les empreintes ecrites en commentaire (lues par les scenarios CAND-L1, CAND-AUTRES, AUDIT-PORTAIL...) ---
DO $f86$
DECLARE
  f regprocedure := 'public.lire_candidature(uuid)'::regprocedure;
  v_com text;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.references_dossiers_admin(uuid[]) IS %L',
    'F86 candidate allowlist: signature=public.references_dossiers_admin(uuid[]); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.references_dossiers_admin(uuid[])'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-20. '
    || 'DOSSIER-DIRECTION (PE-C1). Direction active (garde positive) ; genre du lecteur ou exception super-admin ; '
    || 'ne rend que la reference CAND-... d''une candidature d''enseignant, jamais un nom ni un etat ; 500 profils au plus. '
    || 'Must-pass: supabase/tests/scenarios_dossier_direction.sql.');
  v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    IF pg_catalog.strpos(v_com, 'DOSSIER-DIRECTION') = 0 THEN
      v_com := v_com || ' DOSSIER-DIRECTION (20/11/2026) : derniereConnexion et manquants (private.praxis_dossier_manques). '
        || 'Must-pass: supabase/tests/scenarios_dossier_direction.sql.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;
END
$f86$;

-- 6. Controle final ------------------------------------------------------------------
DO $controle$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['public.lire_candidature(uuid)', 'private.push1_depuis_candidature()',
                             'private.push1_depuis_piece()'] LOOP
    IF (SELECT pg_catalog.strpos(p.prosrc, 'DOSSIER-DIRECTION') FROM pg_catalog.pg_proc p
         WHERE p.oid = v_f::pg_catalog.regprocedure) = 0 THEN
      RAISE EXCEPTION 'DOSSIER-DIRECTION : % n''a pas ete remplacee', v_f;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_f::pg_catalog.regprocedure AND p.prosecdef
                      AND 'search_path=""' = ANY (p.proconfig)) THEN
      RAISE EXCEPTION 'DOSSIER-DIRECTION : % doit rester SECURITY DEFINER avec search_path vide', v_f;
    END IF;
  END LOOP;
  IF has_function_privilege('anon', 'public.references_dossiers_admin(uuid[])', 'EXECUTE') THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION : anon ne doit pas executer references_dossiers_admin';
  END IF;
  IF has_function_privilege('authenticated', 'private.derniere_connexion_compte(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION : derniere_connexion_compte doit rester privee';
  END IF;
  IF coalesce(pg_catalog.obj_description('public.lire_candidature(uuid)'::regprocedure, 'pg_proc'), '')
     NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.lire_candidature(uuid)'::regprocedure)) || '%' THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION : empreinte F86 de lire_candidature pas a jour';
  END IF;
  IF NOT has_function_privilege('authenticated', 'public.lire_candidature(uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'DOSSIER-DIRECTION : lire_candidature a perdu son droit d''execution';
  END IF;
END
$controle$;
