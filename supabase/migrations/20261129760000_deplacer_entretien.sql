-- BE-1j DEPLACER-ENTRETIEN (carte des gestes, lot 3, trou T8, arbitrage A2 du pilote : un seul geste pour la
-- direction ; la personne est prevenue). Numero 20261129760000 (le 720000 est a BE-SALLE).
--
-- Le geste `deplacer_entretien` (transition 48) : la direction change le creneau d'un entretien planifie
-- d'une candidature (Salle de verification, etat `entretien_planifie`, en cours, hors pause).
--   * un nouveau debut et une duree, un motif ecrit (interne) ;
--   * les memes controles que planifier_entretien : debut entre dans 5 minutes et 90 jours, duree de 15 a 120
--     minutes, participants encore actifs et du bon cote, regle des fondateurs, personne libre sur la periode
--     (l'ancienne seance n'est pas comptee) ; un entretien deja commence ne se deplace pas ;
--   * COMMENT : l'entretien ouvert est ANNULE (issue `annule`, seance `canceled`, rien n'est efface) et un NOUVEL
--     entretien est cree avec les memes participants, le nouveau creneau. Pourquoi pas une mise a jour sur place :
--     le journal des avis (private.entretien_avis_envoyes, une ligne par seance et par sorte) rendrait muets
--     « reserve », « veille » et « quinze » pour la nouvelle heure. Une nouvelle seance rearme tout, SANS nouvel
--     evenement de notification et SANS nouveau modele de courriel :
--       - le candidat et les participants recoivent l'avis EXISTANT « entretien_reserve » (« Votre entretien est
--         fixe au ... », notification + courriel par le circuit courriels-envoi), puis les rappels, pour la
--         nouvelle seance, avec la nouvelle heure ;
--       - l'ancienne seance est marquee « a_replanifier deja envoye » dans le journal : le candidat ne lit donc
--         JAMAIS « Votre entretien n'a pas eu lieu » pour un simple deplacement.
--     Limite dite : l'avis ne dit pas « deplace », il dit la nouvelle heure ; un texte « deplace » serait un
--     nouvel evenement (reecriture de la contrainte des evenements), non decide ici.
--   * le dossier reste `entretien_planifie` ; l'evenement du dossier (type entretien) garde l'ancienne et la
--     nouvelle seance, l'ancien et le nouveau debut.
--   * un creneau d'entretien reserve par le candidat (entretien_creneaux) : s'il est A VENIR, il est rouvert
--     (libre pour un autre) et l'evenement du dossier le dit ; s'il est deja passe, il reste lie a l'ancienne
--     seance (scenarios a7 et a8).
-- Aucun message n'est ecrit ici : tout part par le circuit existant des avis d'entretien.
--
-- FICHIER SANS EFFACEMENT DE DONNEES : aucun mot d'effacement. Additif : une regle du moteur, deux fonctions ;
-- une fonction retouchee par ancrage (capacites_candidatures). Sans BEGIN/COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.candidature_geste_ouvrir(uuid,text,text,uuid,integer,text,text,text)') IS NULL
     OR pg_catalog.to_regprocedure('private.entretien_personne_occupee(uuid[],timestamptz,timestamptz,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.entretien_fondateurs_verifier(integer)') IS NULL
     OR pg_catalog.to_regclass('private.entretien_avis_envoyes') IS NULL THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : dependances absentes (moteur des gestes, entretiens, chevauchement, avis)';
  END IF;
  IF pg_catalog.to_regprocedure('public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)') IS NOT NULL THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : deja installee';
  END IF;
  IF EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.transition = 48) THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : la transition 48 est deja prise';
  END IF;
END
$preflight$;

CREATE FUNCTION pg_temp.remplacer(p_def text, p_avant text, p_apres text, p_nom text)
RETURNS text
LANGUAGE plpgsql
AS $f$
DECLARE
  v_n integer;
BEGIN v_n := (pg_catalog.length(p_def) - pg_catalog.length(pg_catalog.replace(p_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : ancre % trouvee % fois (une attendue)', p_nom, v_n;
  END IF;
  RETURN pg_catalog.replace(p_def, p_avant, p_apres);
END;
$f$;

-- ============================================================
-- 0 bis. Les controles de planification, UNE fois (planifier_entretien ET deplacer_entretien)
-- ============================================================
-- Rend {"erreur": ...} au premier refus, sinon {"participants": [...], "fondateurs": n}. Meme ordre que le corps
-- qu'elle remplace dans planifier_entretien : debut, duree, candidat avec compte, participants, regle des
-- fondateurs, entretien deja ouvert (sauf deplacement : p_sauf est la seance qu'on remplace), personne libre.
CREATE FUNCTION private.entretien_controles_planification(
  p_debut timestamptz, p_duree_minutes integer, p_candidat uuid, p_genre public.gender,
  p_participants uuid[], p_sauf uuid, p_candidature uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_participants uuid[];
  v_p uuid;
  v_fondateurs integer;
  v_refus jsonb;
BEGIN
  IF NOT pg_catalog.isfinite(p_debut)
     OR p_debut < pg_catalog.now() + interval '5 minutes'
     OR p_debut > pg_catalog.now() + interval '90 days' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debut_invalide');
  END IF;
  IF p_duree_minutes NOT BETWEEN 15 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'duree_invalide');
  END IF;
  IF p_candidat IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.profiles p WHERE p.id = p_candidat AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidat_sans_compte');
  END IF;
  SELECT pg_catalog.array_agg(DISTINCT x) INTO v_participants
    FROM pg_catalog.unnest(coalesce(p_participants, '{}'::uuid[])) x WHERE x IS NOT NULL;
  IF v_participants IS NULL OR pg_catalog.cardinality(v_participants) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participants_requis');
  END IF;
  IF pg_catalog.cardinality(v_participants) > 12 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'participants_trop_nombreux');
  END IF;
  FOREACH v_p IN ARRAY v_participants LOOP
    IF v_p = p_candidat OR NOT private.personnel_actif(v_p) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_non_autorise', 'profil', v_p);
    END IF;
    IF NOT private.entretien_cote_permis(v_p, p_genre) THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'participant_autre_cote', 'profil', v_p);
    END IF;
  END LOOP;
  SELECT pg_catalog.count(*)::integer INTO v_fondateurs
    FROM public.personnel_fondateurs f
   WHERE f.fondateur AND f.profile_id = ANY (v_participants);
  v_refus := private.entretien_fondateurs_verifier(v_fondateurs);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;
  IF p_sauf IS NULL AND EXISTS (SELECT 1 FROM public.entretiens e WHERE e.candidature_id = p_candidature AND e.issue IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_planifie');
  END IF;
  -- V1-c : chaque participant et le candidat sont libres sur la periode (la seance remplacee n'est pas comptee).
  v_refus := private.entretien_personne_occupee(
    v_participants || p_candidat, p_debut,
    p_debut + pg_catalog.make_interval(mins => p_duree_minutes), p_sauf);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;
  RETURN pg_catalog.jsonb_build_object('participants', pg_catalog.to_jsonb(v_participants),
                                       'fondateurs', v_fondateurs);
END;
$function$;
ALTER FUNCTION private.entretien_controles_planification(timestamptz, integer, uuid, public.gender, uuid[], uuid, uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.entretien_controles_planification(timestamptz, integer, uuid, public.gender, uuid[], uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 1. La regle du geste (moteur des gestes)
-- ============================================================
INSERT INTO private.candidature_gestes_regles
  (geste, variante, transition, auteurs, etapes, etats, issues, pause, condition, motif_requis,
   modele_vers, groupable, type_evenement, cible, admis, brouillon)
VALUES
  ('deplacer_entretien', 1, 48, '{direction}', '{verifications}',
   '{entretien_planifie}', '{en_cours}', 'interdite', NULL, '{direction}',
   NULL, false, 'entretien', '{"etat": "entretien_planifie"}', '{}', false)
ON CONFLICT (geste, variante) DO NOTHING;

-- ============================================================
-- 2. Le geste lui-meme (un coeur prive, une porte publique)
-- ============================================================
CREATE FUNCTION private.candidature_geste_deplacer_entretien(
  p_id uuid, p_debut timestamptz, p_duree_minutes integer, p_auteur uuid, p_version integer,
  p_cle text, p_motif text)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
  v_e public.entretiens;
  v_ancienne public.sessions;
  v_nouvelle uuid;
  v_participants uuid[];
  v_fondateurs integer;
  v_refus jsonb;
  v_creneau uuid;
  v_motif text := private.candidature_motif(p_motif);
BEGIN
  IF p_debut IS NULL OR p_duree_minutes IS NULL THEN
    RAISE EXCEPTION 'entretien : debut et duree attendus' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'deplacer_entretien', 'direction', p_auteur, p_version, p_cle,
                                          p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  IF v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'motif_requis', 'geste', 'deplacer_entretien');
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.type_code IS DISTINCT FROM 'enseignant' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'type_non_admis');
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e
   WHERE e.candidature_id = p_id AND e.issue IS NULL
   FOR UPDATE;
  IF v_e.session_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'aucun_entretien_ouvert');
  END IF;
  SELECT s.* INTO v_ancienne FROM public.sessions s WHERE s.id = v_e.session_id FOR UPDATE;
  IF v_ancienne.status IS DISTINCT FROM 'planned' OR v_ancienne.started_at <= pg_catalog.now() THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_commence');
  END IF;
  IF v_ancienne.started_at = p_debut
     AND v_ancienne.ended_at = p_debut + pg_catalog.make_interval(mins => p_duree_minutes) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'meme_creneau');
  END IF;
  -- Les memes participants : ceux qui sont encore actifs dans l'entretien.
  SELECT pg_catalog.array_agg(ep.profile_id ORDER BY ep.profile_id) INTO v_participants
    FROM public.entretien_participants ep
   WHERE ep.session_id = v_e.session_id AND ep.retire_le IS NULL;
  -- Les controles de planification, les memes que planifier_entretien (une seule fonction).
  v_refus := private.entretien_controles_planification(
    p_debut, p_duree_minutes, v_c.profile_id, v_c.genre, v_participants, v_ancienne.id, v_c.id);
  IF v_refus ? 'erreur' THEN
    RETURN v_refus;
  END IF;
  v_fondateurs := (v_refus ->> 'fondateurs')::integer;

  -- L'ancien entretien est annule sans rien effacer ; le candidat ne lira pas « n'a pas eu lieu ».
  UPDATE public.entretiens
     SET issue = 'annule', consigne_par = p_auteur, consigne_le = pg_catalog.clock_timestamp()
   WHERE session_id = v_ancienne.id;
  UPDATE public.sessions SET status = 'canceled' WHERE id = v_ancienne.id AND status = 'planned';
  INSERT INTO private.entretien_avis_envoyes (session_id, sorte)
  VALUES (v_ancienne.id, 'a_replanifier') ON CONFLICT DO NOTHING;
  -- Un creneau reserve par le candidat pour l'ancienne seance : s'il est a venir, il est rouvert (libre pour
  -- un autre) dans la meme transaction ; passe, il reste tel quel.
  UPDATE public.entretien_creneaux
     SET session_id = NULL, reserve_le = NULL
   WHERE session_id = v_ancienne.id AND annule_le IS NULL AND debut > pg_catalog.now()
  RETURNING id INTO v_creneau;

  -- Le nouvel entretien : meme candidat, memes participants, le nouveau creneau.
  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_ancienne.teacher_id, p_debut, p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
          'planned', 'entretien', p_debut - interval '10 minutes')
  RETURNING id INTO v_nouvelle;
  INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
  VALUES (v_nouvelle, v_c.id, v_c.profile_id, p_auteur);
  INSERT INTO public.entretien_participants (session_id, profile_id, fondateur, ajoute_par)
  SELECT v_nouvelle, x, coalesce(f.fondateur, false), p_auteur
    FROM pg_catalog.unnest(v_participants) x
    LEFT JOIN public.personnel_fondateurs f ON f.profile_id = x;
  INSERT INTO public.session_participants (session_id, profile_id, role)
  SELECT v_nouvelle, x, 'intervieweur'::public.participant_role FROM pg_catalog.unnest(v_participants) x
  UNION ALL
  SELECT v_nouvelle, v_c.profile_id, 'candidat'::public.participant_role;

  PERFORM private.candidature_geste_appliquer(p_id, 'deplacer_entretien', (v_o ->> 'variante')::smallint,
    'direction', p_auteur, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionAvant', v_ancienne.id, 'sessionApres', v_nouvelle,
      'debutAvant', v_ancienne.started_at, 'debutApres', p_debut, 'creneauRouvert', v_creneau,
      'dureeMinutes', p_duree_minutes, 'fondateurs', v_fondateurs));
  RETURN private.candidature_geste_conclure(p_cle, p_id, 'deplacer_entretien', p_auteur,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(p_id),
      'entretien', pg_catalog.jsonb_build_object(
        'sessionId', v_nouvelle, 'debut', p_debut,
        'fin', p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
        'participants', pg_catalog.to_jsonb(v_participants), 'fondateurs', v_fondateurs)));
END;
$function$;
ALTER FUNCTION private.candidature_geste_deplacer_entretien(uuid, timestamptz, integer, uuid, integer, text, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_geste_deplacer_entretien(uuid, timestamptz, integer, uuid, integer, text, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

CREATE FUNCTION public.deplacer_entretien(
  p_id uuid, p_debut timestamptz, p_duree_minutes integer, p_motif text, p_version_attendue integer,
  p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.candidature_geste_deplacer_entretien(p_id, p_debut, p_duree_minutes, auth.uid(),
                                                      p_version_attendue, p_cle_idempotence, p_motif);
END;
$function$;
ALTER FUNCTION public.deplacer_entretien(uuid, timestamptz, integer, text, integer, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.deplacer_entretien(uuid, timestamptz, integer, text, integer, text)
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.deplacer_entretien(uuid, timestamptz, integer, text, integer, text) TO authenticated;

-- ============================================================
-- 2 bis. planifier_entretien appelle les controles communs (retouche par ancrage, un bloc remplace)
-- ============================================================
-- Le bloc remplace va de « IF NOT pg_catalog.isfinite(p_debut) » (debut) jusqu'a la fin du controle de la
-- personne occupee ; chaque borne doit se trouver UNE fois, sinon la migration s'arrete. Rien d'autre ne change
-- (garde d'acces, mission, moteur, insertions, retour).
DO $planifier$
DECLARE
  v_def text;
  v_debut text := '  IF NOT pg_catalog.isfinite(p_debut)';
  v_fin text := E'    p_debut + pg_catalog.make_interval(mins => p_duree_minutes), NULL);\n  IF v_refus IS NOT NULL THEN\n    RETURN v_refus;\n  END IF;\n';
  v_a integer;
  v_b integer;
  v_com text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef('public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)'::regprocedure);
  IF pg_catalog.strpos(v_def, 'entretien_controles_planification') > 0 THEN
    RETURN;
  END IF;
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_debut, ''))) / pg_catalog.length(v_debut) <> 1
     OR (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_fin, ''))) / pg_catalog.length(v_fin) <> 1 THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : bornes du bloc de planifier_entretien introuvables ou multiples';
  END IF;
  v_a := pg_catalog.strpos(v_def, v_debut);
  v_b := pg_catalog.strpos(v_def, v_fin) + pg_catalog.length(v_fin);
  IF v_a >= v_b THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : bornes du bloc de planifier_entretien dans le mauvais ordre';
  END IF;
  v_def := pg_catalog.substr(v_def, 1, v_a - 1)
    || E'  -- BE-1j : les controles de planification sont ceux de private.entretien_controles_planification\n'
    || E'  -- (les memes pour deplacer_entretien).\n'
    || E'  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature;\n'
    || E'  v_refus := private.entretien_controles_planification(\n'
    || E'    p_debut, p_duree_minutes, v_c.profile_id, v_c.genre, p_participants, NULL, v_c.id);\n'
    || E'  IF v_refus ? ''erreur'' THEN\n    RETURN v_refus;\n  END IF;\n'
    || E'  v_participants := ARRAY(SELECT pg_catalog.jsonb_array_elements_text(v_refus -> ''participants'')::uuid);\n'
    || E'  v_fondateurs := (v_refus ->> ''fondateurs'')::integer;\n'
    || pg_catalog.substr(v_def, v_b);
  EXECUTE v_def;
  v_com := pg_catalog.obj_description('public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)'::regprocedure, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+', 'md5_functiondef='
      || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)'::regprocedure)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text) IS %L', v_com);
  END IF;
END
$planifier$;

-- ============================================================
-- 3. La capacite du geste (retouche par ancrage)
-- ============================================================
DO $retouche$
DECLARE
  v_def text;
BEGIN
  v_def := pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure);
  IF pg_catalog.strpos(v_def, 'deplacerEntretien') = 0 THEN
    v_def := pg_temp.remplacer(v_def, '''dispenserEntretien'', v_decider,',
      '''dispenserEntretien'', v_decider,
      ''deplacerEntretien'', v_decider,', 'capacites.geste');
    EXECUTE v_def;
  END IF;
END;
$retouche$;

-- ============================================================
-- 4. F86 et controle final
-- ============================================================
DO $f86$
DECLARE
  f regprocedure := 'public.capacites_candidatures()'::regprocedure;
  v_com text;
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text) IS %L',
    'F86 candidate allowlist: signature=public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)'::regprocedure))
    || '; guard_type=ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-17. '
    || 'BE-1j DEPLACER-ENTRETIEN. Direction active ; moteur (transition 48, motif ecrit) ; '
    || 'ancien entretien annule sans rien effacer, nouvel entretien aux memes participants ; avis par le circuit existant. '
    || 'Must-pass: supabase/tests/scenarios_deplacer_entretien.sql.');
  v_com := coalesce(pg_catalog.obj_description(f, 'pg_proc'), '');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    IF pg_catalog.strpos(v_com, 'BE-1j') = 0 THEN
      v_com := v_com || ' BE-1j (17/11/2026) : la capacite deplacerEntretien.';
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;
END;
$f86$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.deplacer_entretien(uuid,timestamptz,integer,text,integer,text)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_oid AND p.prosecdef AND p.proowner = 'postgres'::regrole
                    AND p.proconfig @> ARRAY['search_path=""'])
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.candidature_geste_deplacer_entretien(uuid,timestamptz,integer,uuid,integer,text,text)'::regprocedure,
          'EXECUTE') THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : DEFINER ou ACL invalide';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure),
                       'deplacerEntretien') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)'::regprocedure),
                          'entretien_controles_planification') = 0
     OR pg_catalog.has_function_privilege('authenticated',
          'private.entretien_controles_planification(timestamptz,integer,uuid,public.gender,uuid[],uuid,uuid)'::regprocedure,
          'EXECUTE') THEN
    RAISE EXCEPTION 'DEPLACER-ENTRETIEN : retouche absente';
  END IF;
END
$postflight$;
