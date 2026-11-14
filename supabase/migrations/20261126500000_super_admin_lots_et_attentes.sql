-- VISION-RECRUTEMENT (14/11/2026) : le super-admin agit aussi en lot, et la
-- direction voit « qui attend quoi ».
--
-- Decision du directeur, 14/11/2026, mot pour mot : « je suis le seul super
-- admin… je dois tout voir… qu'est-ce qu'il te faut d'autre pour ne pas que tu
-- me bloques dans ma propre app ? ». Ecrite comme decision datee dans
-- docs/orchestration/CONSIGNES-DIRECTEUR-EN-VIGUEUR.md.
--
-- Releve en production avant ce fichier (lecture seule, 14/11) :
--   * les gestes un par un (`valider_piece_candidat`, decider, verifier, les
--     gestes d'entretien) acceptent DEJA le super-admin des deux cotes depuis
--     V1-a-bis (20261109100000) : le moteur `private.candidature_geste_ouvrir`
--     leve la borne de genre quand `kyc_super_admin_exception_active()` est
--     vrai, et ecrit `super_admin_hors_cote` au journal sensible. Aucun
--     evenement `lecture_hors_portee` du super-admin en production ;
--   * restaient bornes, faute d'une decision qui les nomme (V1-a-bis, en-tete) :
--     les gestes EN LOT. `private.candidature_lot_examiner` et
--     `private.candidature_lot_tracer` excluent toute candidature de l'autre
--     genre, meme pour le super-admin. Ce fichier leve cette borne pour lui
--     seul. Chaque ligne passe ensuite par `private.candidature_geste_groupe`,
--     donc par le moteur, qui ecrit deja `super_admin_hors_cote` au journal.
--     Une direction qui n'est pas super-admin reste bornee a son cote.
--
-- Nouveau : `public.attentes_recrutement()`, lecture seule, dans la portee du
-- lecteur (son genre, ou les deux pour le super-admin) : combien de personnes
-- attendent l'academie (examen, piece a valider, entretien a planifier,
-- decision), combien attendent la personne (dossier a completer), combien
-- attendent un moyen de versement, combien d'entretiens sont planifies, en
-- pause, et combien de creneaux d'entretien sont ouverts. Avec, pour chaque
-- attente, la date de la plus ancienne derniere activite. Le nom ne contient
-- pas « candidature » (gardes CAND-L1, L2A2, L3 : etat_dossier() reste la
-- seule lecture de l'etat du candidat).
--
-- Retouches par ancres comptees (chaque ancre une fois et une seule, sinon la
-- migration s'arrete), aucune recopie entiere. Mots de suppression : 0.

-- ---------------------------------------------------------------------------
-- 1. Les retouches par ancres
-- ---------------------------------------------------------------------------
CREATE FUNCTION pg_temp.retoucher(p_f pg_catalog.regprocedure, p_avant text, p_apres text)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1, migration a revoir : %',
      p_f, v_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- 1.1 L'apercu et l'execution d'un lot : une candidature de l'autre genre est
-- eligible pour le super-admin (exception active), exclue pour les autres.
SELECT pg_temp.retoucher('private.candidature_lot_examiner(text,uuid[],uuid,public.gender)',
  $a$    ELSIF v_c.genre IS DISTINCT FROM p_genre THEN$a$,
  $a$    ELSIF v_c.genre IS DISTINCT FROM p_genre
          -- VISION-RECRUTEMENT (directeur, 14/11/2026) : le super-admin agit
          -- aussi en lot ; le moteur ecrit chaque geste hors cote au journal.
          AND NOT coalesce(public.kyc_super_admin_exception_active(), false) THEN$a$);

-- 1.2 La trace « hors portee » d'un lot : rien a tracer pour le super-admin,
-- dont les lignes de l'autre genre sont dans sa portee.
SELECT pg_temp.retoucher('private.candidature_lot_tracer(uuid[],uuid,public.gender,text)',
  $a$    WHERE c.genre IS DISTINCT FROM p_genre$a$,
  $a$    WHERE c.genre IS DISTINCT FROM p_genre
      AND NOT coalesce(public.kyc_super_admin_exception_active(), false)$a$);

-- ---------------------------------------------------------------------------
-- 2. Qui attend quoi
-- ---------------------------------------------------------------------------
-- Une seule lecture, des nombres seulement, aucune donnee personnelle. Les
-- candidatures en cours (issue `en_cours`), hors pause, comptees par etat ;
-- la pause a part ; la piece a valider (piece deposee, en attente) a part, car
-- elle peut attendre a tout etat.
CREATE OR REPLACE FUNCTION public.attentes_recrutement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_etats jsonb;
  v_piece jsonb;
  v_pause integer;
  v_creneaux integer;
  v_planifies integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;

  -- Par etat : le nombre et la plus ancienne derniere activite.
  SELECT coalesce(pg_catalog.jsonb_object_agg(x.etat, pg_catalog.jsonb_build_object(
           'nombre', x.n, 'plusAncien', x.plus_ancien)), '{}'::jsonb)
    INTO v_etats
    FROM (SELECT c.etat::text AS etat, pg_catalog.count(*)::integer AS n,
                 pg_catalog.min(coalesce(c.derniere_activite, c.recue_le)) AS plus_ancien
            FROM public.candidatures c
           WHERE (v_super OR c.genre = v_genre)
             AND c.issue = 'en_cours' AND NOT c.en_pause AND c.etat IS NOT NULL
           GROUP BY c.etat) x;

  -- La piece d'identite deposee et en attente d'une decision.
  SELECT pg_catalog.jsonb_build_object('nombre', pg_catalog.count(*)::integer,
           'plusAncien', pg_catalog.min(k.created_at))
    INTO v_piece
    FROM public.candidatures c
    JOIN LATERAL (SELECT d.status, d.created_at FROM public.kyc_documents d
                   WHERE d.profile_id = c.profile_id AND d.deleted_at IS NULL
                   ORDER BY d.created_at DESC, d.id DESC LIMIT 1) k ON true
   WHERE (v_super OR c.genre = v_genre)
     AND c.issue = 'en_cours' AND NOT c.en_pause AND c.type_code = 'enseignant'
     AND k.status = 'pending'::public.kyc_doc_status;

  SELECT pg_catalog.count(*)::integer INTO v_pause
    FROM public.candidatures c
   WHERE (v_super OR c.genre = v_genre) AND c.issue = 'en_cours' AND c.en_pause;

  -- Les creneaux d'entretien ouverts a venir, non annules, non reserves.
  SELECT pg_catalog.count(*)::integer INTO v_creneaux
    FROM public.entretien_creneaux cr
   WHERE (v_super OR cr.cote = v_genre)
     AND cr.annule_le IS NULL AND cr.session_id IS NULL AND cr.debut > pg_catalog.now();

  -- Les entretiens a venir, sans issue consignee.
  SELECT pg_catalog.count(*)::integer INTO v_planifies
    FROM public.entretiens e
    JOIN public.candidatures c ON c.id = e.candidature_id
   WHERE (v_super OR c.genre = v_genre) AND e.issue IS NULL AND c.issue = 'en_cours';

  RETURN pg_catalog.jsonb_build_object(
    'etats', v_etats,
    'pieceAValider', v_piece,
    'enPause', v_pause,
    'creneauxOuverts', v_creneaux,
    'entretiensSansIssue', v_planifies,
    'deuxCotes', v_super);
END;
$function$;
ALTER FUNCTION public.attentes_recrutement() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.attentes_recrutement() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.attentes_recrutement() TO authenticated;

DO $fiche$
DECLARE
  f pg_catalog.regprocedure := 'public.attentes_recrutement()'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=public.attentes_recrutement(); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_READ; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-14. '
    || 'VISION-RECRUTEMENT : qui attend quoi, des nombres seulement, dans la portee du lecteur.');
END;
$fiche$;

-- ---------------------------------------------------------------------------
-- 3. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
      'private.candidature_lot_examiner(text,uuid[],uuid,public.gender)',
      'private.candidature_lot_tracer(uuid[],uuid,public.gender,text)'] LOOP
    IF pg_catalog.pg_get_functiondef(v_f::regprocedure) !~ 'kyc_super_admin_exception_active' THEN
      RAISE EXCEPTION 'VISION-RECRUTEMENT : % sans le super-admin', v_f;
    END IF;
  END LOOP;
  -- Le moteur garde sa borne et son journal (V1-a-bis jamais defait).
  IF pg_catalog.pg_get_functiondef(
       'private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)'::regprocedure)
     !~ 'super_admin_hors_cote' THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT : le moteur a perdu le journal hors cote';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.attentes_recrutement()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.attentes_recrutement()', 'EXECUTE') THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT : droits inattendus sur attentes_recrutement';
  END IF;
END;
$postflight$;
