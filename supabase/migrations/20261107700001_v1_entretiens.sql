-- V1, visio d'entretien, partie serveur (PLAN-LOTS §3 point 3, garde-cap et
-- pilote, 03/11/2026). Second fichier : tout ce qui emploie les types de
-- 20261107700000 (role `candidat`, session_type 'entretien' et 'reunion').
-- Installe par le pilote apres le collage de 20261107700000 par le directeur.
-- Intervieweur : role existant `admin_visible`, identite « Administration
-- Rewayah » (regle de 0040) ; reglage « propose » (garde-cap, 03/11).
--
-- Ce que ce fichier pose :
--   1. `public.entretiens` : le lien entre une seance d'entretien et une
--      candidature (intervieweur, candidat, issue, compte rendu). RLS, aucun
--      droit client : on n'y lit et n'y ecrit que par les fonctions.
--   2. `planifier_entretien`, `consigner_entretien`, `mes_entretiens` : la
--      direction seule (CAND-Q19), de son cote (cloisonnement femmes / hommes,
--      CAND-Q07 : la direction de genre connu, la candidature du meme genre,
--      l'intervieweur du meme genre). Les deux gestes passent par le moteur
--      des candidatures (regles 11, 12 et 13 de 20261022000000 : version
--      attendue, cle d'idempotence, journal, audit).
--   3. Exclusions (recensement B1 du 03/11, mesure sur la pile locale) :
--      seule la cloture de tresorerie prenait la seance (file
--      `tresorerie_a_reprendre`). Le reste est deja exclu sans changement :
--      remplacements (jointure groupes), vues des familles et des eleves
--      (participant `student`), vues de l'enseignant (teacher_id, ici
--      l'intervieweur seul), presence et paie (Classe ou eleve present),
--      cahier et avis de fin (Classe). Le scenario le prouve, famille par
--      famille.
--   4. `autoriser_jeton_video` : le candidat (compte `pending_kyc` admis) pour
--      SA seance seulement, entretien ouvert, candidature en cours ; un
--      entretien ou une reunion n'admet que ses inscrits. Le chemin « tuteur
--      pour un eleve » (`autoriser_jeton_video_eleve`) exige deja un
--      participant `student` : inchange, il refuse.
--   5. Capacites : `peutMenerEntretien`, `planifierEntretien` et
--      `consignerEntretien` suivent `peutDecider`.
--
-- Rien n'est enregistre (CAND-Q09) : aucune fonction d'enregistrement
-- n'existe ; un entretien n'a ni cahier, ni compte rendu de seance, ni avis
-- de fin. Le compte rendu d'entretien est un texte de la direction, lu par
-- elle seule.
--
-- `supabase/functions` : rien ne change. create-room-token appelle deja
-- autoriser_jeton_video avec l'identite du jeton Supabase verifie.
--
-- Mots de suppression de ce fichier : 0.

-- ---------------------------------------------------------------------------
-- 1. Le lien entretien - candidature
-- ---------------------------------------------------------------------------
CREATE TABLE public.entretiens (
  session_id uuid PRIMARY KEY REFERENCES public.sessions(id),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id),
  intervieweur_id uuid NOT NULL REFERENCES public.profiles(id),
  candidat_id uuid NOT NULL REFERENCES public.profiles(id),
  planifie_par uuid NOT NULL REFERENCES public.profiles(id),
  planifie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  issue text NULL CHECK (issue IN ('tenu', 'non_tenu')),
  compte_rendu text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(compte_rendu)) BETWEEN 1 AND 4000),
  consigne_par uuid NULL REFERENCES public.profiles(id),
  consigne_le timestamptz NULL,
  CONSTRAINT entretiens_consigne_coherent CHECK ((issue IS NULL) = (consigne_le IS NULL)
                                                 AND (issue IS NULL) = (consigne_par IS NULL)),
  CONSTRAINT entretiens_compte_rendu_si_tenu CHECK (issue IS DISTINCT FROM 'tenu' OR compte_rendu IS NOT NULL)
);
-- Un seul entretien ouvert par candidature.
CREATE UNIQUE INDEX entretiens_un_ouvert_par_candidature
  ON public.entretiens (candidature_id) WHERE issue IS NULL;
CREATE INDEX entretiens_candidat_idx ON public.entretiens (candidat_id);
ALTER TABLE public.entretiens ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.entretiens FROM PUBLIC, anon, authenticated;
COMMENT ON TABLE public.entretiens IS
  'V1 (03/11/2026) : une seance session_type = entretien et sa candidature. Lue et ecrite par '
  'planifier_entretien, consigner_entretien et mes_entretiens seulement (direction, de son cote).';

-- ---------------------------------------------------------------------------
-- 2. Les gestes de la direction
-- ---------------------------------------------------------------------------
-- planifierEntretien (contrat CONTRAT_PORTS_CANDIDATURES) : la candidature en
-- Salle de verification, entretien a planifier ; l'intervieweur est un membre
-- de la direction actif, du genre de la candidature (CAND-Q07, CAND-Q19) ;
-- l'appelant par defaut. Cree la seance (teacher_id = intervieweur, qui
-- garde la garde de chevauchement), ses deux inscrits, le lien, puis la
-- transition 11 (etat entretien_planifie).
CREATE FUNCTION public.planifier_entretien(
  p_candidature uuid,
  p_debut timestamptz,
  p_duree_minutes integer,
  p_intervieweur uuid,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_intervieweur uuid := coalesce(p_intervieweur, auth.uid());
  v_o jsonb;
  v_c public.candidatures;
  v_seance uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_debut IS NULL OR p_duree_minutes IS NULL THEN
    RAISE EXCEPTION 'entretien : debut et duree attendus' USING ERRCODE = '22023';
  END IF;

  v_o := private.candidature_geste_ouvrir(p_candidature, 'planifier_entretien', 'direction', v_moi,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;

  IF NOT pg_catalog.isfinite(p_debut)
     OR p_debut < pg_catalog.now() + interval '5 minutes'
     OR p_debut > pg_catalog.now() + interval '90 days' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'debut_invalide');
  END IF;
  IF p_duree_minutes NOT BETWEEN 15 AND 120 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'duree_invalide');
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature;
  IF v_c.profile_id IS NULL OR NOT EXISTS (
       SELECT 1 FROM public.profiles p WHERE p.id = v_c.profile_id AND p.deleted_at IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidat_sans_compte');
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.profiles p
        WHERE p.id = v_intervieweur
          AND p.role = 'admin'
          AND p.deleted_at IS NULL
          AND p.account_status = 'active'
          AND p.gender = v_c.genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'intervieweur_non_autorise');
  END IF;
  IF EXISTS (SELECT 1 FROM public.entretiens e WHERE e.candidature_id = v_c.id AND e.issue IS NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_planifie');
  END IF;
  IF EXISTS (
       SELECT 1 FROM public.sessions s
        WHERE s.teacher_id = v_intervieweur
          AND s.deleted_at IS NULL
          AND s.status IN ('planned', 'preflight', 'in_progress')
          AND s.started_at < p_debut + pg_catalog.make_interval(mins => p_duree_minutes)
          AND s.ended_at > p_debut) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'intervieweur_occupe');
  END IF;

  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_intervieweur, p_debut, p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
          'planned', 'entretien', p_debut - interval '10 minutes')
  RETURNING id INTO v_seance;
  INSERT INTO public.session_participants (session_id, profile_id, role)
  VALUES (v_seance, v_intervieweur, 'admin_visible'),
         (v_seance, v_c.profile_id, 'candidat');
  INSERT INTO public.entretiens (session_id, candidature_id, intervieweur_id, candidat_id, planifie_par)
  VALUES (v_seance, v_c.id, v_intervieweur, v_c.profile_id, v_moi);

  PERFORM private.candidature_geste_appliquer(p_candidature, 'planifier_entretien',
    (v_o ->> 'variante')::smallint, 'direction', v_moi, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionId', v_seance, 'debut', p_debut,
      'dureeMinutes', p_duree_minutes, 'intervieweurId', v_intervieweur,
      'aNotifier', 'entretien_planifie'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_candidature, 'planifier_entretien', v_moi,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(p_candidature),
      'entretien', pg_catalog.jsonb_build_object(
        'sessionId', v_seance, 'debut', p_debut,
        'fin', p_debut + pg_catalog.make_interval(mins => p_duree_minutes),
        'intervieweurId', v_intervieweur)));
END;
$function$;

-- consignerEntretien : tenu (compte rendu obligatoire, transition 13, etat
-- decision_en_attente, seance terminee) ou non tenu (motif obligatoire,
-- transition 12, retour a « entretien a planifier », seance annulee).
CREATE FUNCTION public.consigner_entretien(
  p_session uuid,
  p_tenu boolean,
  p_compte_rendu text,
  p_motif text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_e public.entretiens;
  v_geste text;
  v_o jsonb;
  v_statut public.session_status;
  v_compte_rendu text := nullif(pg_catalog.btrim(coalesce(p_compte_rendu, '')), '');
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_tenu IS NULL THEN
    RAISE EXCEPTION 'entretien : tenu ou non tenu attendu' USING ERRCODE = '22023';
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e WHERE e.session_id = p_session;
  IF v_e.session_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  v_geste := CASE WHEN p_tenu THEN 'consigner_entretien_tenu' ELSE 'consigner_entretien_non_tenu' END;

  v_o := private.candidature_geste_ouvrir(v_e.candidature_id, v_geste, 'direction', v_moi,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT e.* INTO v_e FROM public.entretiens e WHERE e.session_id = p_session FOR UPDATE;
  IF v_e.issue IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entretien_deja_consigne');
  END IF;
  IF p_tenu AND v_compte_rendu IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'compte_rendu_requis');
  END IF;
  IF pg_catalog.length(v_compte_rendu) > 4000 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'compte_rendu_trop_long');
  END IF;

  UPDATE public.entretiens
     SET issue = CASE WHEN p_tenu THEN 'tenu' ELSE 'non_tenu' END,
         compte_rendu = v_compte_rendu,
         consigne_par = v_moi,
         consigne_le = pg_catalog.clock_timestamp()
   WHERE session_id = p_session;

  -- La seance suit, par les transitions permises (machine d'etat de 0001).
  SELECT s.status INTO v_statut FROM public.sessions s WHERE s.id = p_session FOR UPDATE;
  IF p_tenu THEN
    IF v_statut = 'planned' THEN
      UPDATE public.sessions SET status = 'preflight' WHERE id = p_session;
      v_statut := 'preflight';
    END IF;
    IF v_statut = 'preflight' THEN
      UPDATE public.sessions SET status = 'in_progress' WHERE id = p_session;
      v_statut := 'in_progress';
    END IF;
    IF v_statut = 'in_progress' THEN
      UPDATE public.sessions SET status = 'ended' WHERE id = p_session;
    END IF;
  ELSIF v_statut = 'planned' THEN
    UPDATE public.sessions SET status = 'canceled' WHERE id = p_session;
  END IF;

  PERFORM private.candidature_geste_appliquer(v_e.candidature_id, v_geste,
    (v_o ->> 'variante')::smallint, 'direction', v_moi, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('sessionId', p_session, 'tenu', p_tenu));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_e.candidature_id, v_geste, v_moi,
    pg_catalog.jsonb_build_object(
      'candidature', private.candidature_etat_direction(v_e.candidature_id),
      'entretien', pg_catalog.jsonb_build_object('sessionId', p_session,
        'issue', CASE WHEN p_tenu THEN 'tenu' ELSE 'non_tenu' END)));
END;
$function$;

-- mesEntretiens : les entretiens de son cote (genre de la direction), a
-- venir et des [p_jours] derniers jours ; jamais le contact du candidat.
CREATE FUNCTION public.mes_entretiens(p_jours integer DEFAULT 14)
RETURNS TABLE (
  session_id uuid,
  candidature_id uuid,
  reference text,
  nom_complet text,
  debut timestamptz,
  fin timestamptz,
  intervieweur_id uuid,
  par_moi boolean,
  statut_seance text,
  issue text,
  version_candidature integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
  v_lecteur uuid;
BEGIN
  SELECT l.profile_id, l.genre INTO v_lecteur, v_genre FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'entretiens reserves a la direction active de genre connu' USING ERRCODE = '42501';
  END IF;
  RETURN QUERY
    SELECT e.session_id, c.id, c.reference, c.nom_complet, s.started_at, s.ended_at,
           e.intervieweur_id, e.intervieweur_id = v_lecteur, s.status::text, e.issue, c.version
      FROM public.entretiens e
      JOIN public.candidatures c ON c.id = e.candidature_id
      JOIN public.sessions s ON s.id = e.session_id
     WHERE c.genre = v_genre
       AND s.deleted_at IS NULL
       AND s.ended_at >= pg_catalog.now()
             - pg_catalog.make_interval(days => least(greatest(coalesce(p_jours, 14), 0), 90))
     ORDER BY s.started_at;
END;
$function$;

REVOKE ALL ON FUNCTION public.planifier_entretien(uuid, timestamptz, integer, uuid, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.consigner_entretien(uuid, boolean, text, text, integer, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.mes_entretiens(integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.planifier_entretien(uuid, timestamptz, integer, uuid, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.consigner_entretien(uuid, boolean, text, text, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mes_entretiens(integer) TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Exclusion : la tresorerie ne prend que les seances de cours
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.x217_sessions_cloture_tresorerie()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
BEGIN
  -- V1 : un entretien ou une reunion n'est ni une prestation ni une paie.
  IF OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure')
     AND NEW.session_type IN ('standard', 'child') THEN
    PERFORM public.remuneration_due_seance(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Le jeton video (corps en vigueur, retouche par ancrage)
-- ---------------------------------------------------------------------------
-- Le corps en vigueur (derniere definition : SNT, 20261106500000) est
-- retouche par ancrage, comme 20261102800000, 20261104600000 et SNT l'ont
-- fait (une copie du texte de 20261102500000 effacerait l'ouverture par le
-- jeton, A3-bis, SNT et l'acces paye). Chaque ancre doit
-- se trouver une fois et une seule, sinon la migration s'arrete.
DO $jeton$
DECLARE
  v_f pg_catalog.regprocedure :=
    'public.autoriser_jeton_video(uuid,uuid,text,text)'::pg_catalog.regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_retouches text[][] := ARRAY[
    -- 1. Le compte : le candidat `pending_kyc` admis pour SA seance d'entretien
    --    seulement (inscrit `candidat`, entretien ouvert, candidature en cours).
    ARRAY[$a$       and p.account_status in ('active', 'provisional_active')
       and (p.access_until is null or p.access_until > now())
  ) then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';$a$,
          $a$       and (p.access_until is null or p.access_until > now())
       and (p.account_status in ('active', 'provisional_active')
            -- V1 (03/11/2026) : le candidat convoque entre avec un compte
            -- `pending_kyc`, dans SA seance d'entretien seulement.
            or (p.account_status = 'pending_kyc' and exists (
                  select 1
                    from public.sessions s
                    join public.session_participants sp on sp.session_id = s.id
                    join public.entretiens en on en.session_id = s.id
                    join public.candidatures c on c.id = en.candidature_id
                   where s.id = p_session_id
                     and s.session_type = 'entretien'
                     and sp.profile_id = p_profile_id
                     and sp.role = 'candidat'
                     and sp.deleted_at is null
                     and en.candidat_id = p_profile_id
                     and en.issue is null
                     and c.issue = 'en_cours')))
  ) then
    raise exception 'compte non valide' using errcode = 'insufficient_privilege';$a$],
    -- 2. Le role : un entretien ou une reunion n'admet que ses inscrits (ni
    --    l'enseignant deduit de teacher_id, ni un remplacant) ; `candidat` ne
    --    vaut que dans un entretien ouvert, sur sa propre candidature.
    ARRAY[$a$  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;$a$,
          $a$  select sp.role into v_role from public.session_participants sp
   where sp.session_id = p_session_id
     and sp.profile_id = p_profile_id
     and sp.deleted_at is null;
  -- V1 (03/11/2026) : entretien et reunion, inscrits seulement ; le role
  -- `candidat` hors d'un entretien ouvert ne vaut rien. (Ces tests ne
  -- changent pas FOUND, lu plus bas.)
  if v_seance.session_type in ('entretien', 'reunion') then
    if v_role is null or v_role in ('teacher', 'student', 'guardian_observer') then
      raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
    end if;
  elsif v_role = 'candidat' then
    raise exception 'non inscrit a cette seance' using errcode = 'insufficient_privilege';
  end if;
  if v_role = 'candidat' and not exists (
    select 1 from public.entretiens en
      join public.candidatures c on c.id = en.candidature_id
     where en.session_id = p_session_id
       and en.candidat_id = p_profile_id
       and en.issue is null
       and c.issue = 'en_cours'
  ) then
    raise exception 'entretien clos ou candidature close' using errcode = 'insufficient_privilege';
  end if;$a$],
    -- 3. Le candidat parle (aucun canal de donnees, jamais masque).
    ARRAY[$a$  v_publier       := v_role in ('teacher', 'student', 'admin_visible');$a$,
          $a$  v_publier       := v_role in ('teacher', 'student', 'admin_visible', 'candidat');$a$],
    -- 4. ... et se montre (visio d'entretien).
    ARRAY[$a$  if v_role = 'teacher' then
    v_publier_video := true;$a$,
          $a$  if v_role in ('teacher', 'candidat') then
    v_publier_video := true;$a$]
  ];
  i integer;
  v_ancre text;
BEGIN
  FOR i IN 1 .. pg_catalog.array_length(v_retouches, 1) LOOP
    v_ancre := v_retouches[i][1];
    IF pg_catalog.strpos(v_def, v_ancre) = 0 THEN
      RAISE EXCEPTION 'autoriser_jeton_video : ancre % absente, le corps a change, migration a revoir', i;
    END IF;
    IF pg_catalog.strpos(pg_catalog.substr(v_def, pg_catalog.strpos(v_def, v_ancre) + 1), v_ancre) <> 0 THEN
      RAISE EXCEPTION 'autoriser_jeton_video : ancre % ambigue, migration a revoir', i;
    END IF;
    v_def := pg_catalog.replace(v_def, v_ancre, v_retouches[i][2]);
  END LOOP;
  EXECUTE v_def;
END;
$jeton$;

-- ---------------------------------------------------------------------------
-- 5. Les capacites (corps de 20261022000600, trois capacites vraies)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.capacites_candidatures()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin boolean;
  v_genre public.gender;
  v_super boolean;
  v_contact boolean;
  v_lire boolean;
  v_decider boolean;
  v_aal2 boolean;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL, false) THEN
    RAISE EXCEPTION 'Acces refuse' USING ERRCODE = '42501';
  END IF;
  v_admin := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  IF v_admin THEN
    SELECT l.genre, l.super_admin, l.contact INTO v_genre, v_super, v_contact
    FROM private.cand_lecteur() l;
  END IF;
  v_super := v_admin AND coalesce(v_super, false);
  v_lire := v_admin AND (v_genre IS NOT NULL OR v_super);
  -- CAND-L2A2 (D13) : un geste ne vaut que de son cote ; l'exception
  -- super-admin reste une exception de lecture.
  v_decider := v_admin AND v_genre IS NOT NULL;
  -- CAND-L3 : l'import des formulaires est celui du super-admin en double verification (aal2, exigee en base).
  v_aal2 := coalesce(public.app_aal() = 'aal2', false);
  RETURN pg_catalog.jsonb_build_object(
    'peutLire', v_lire,
    'peutVoirContact', v_lire AND coalesce(v_contact, false),
    'peutLireHorsGenre', v_super,
    'genreLecteurConnu', v_admin AND v_genre IS NOT NULL,
    'peutDecider', v_decider,
    'peutImporter', v_super AND v_aal2,
    'doubleVerificationRequise', v_super AND NOT v_aal2,
    'peutMenerEntretien', v_decider,
    'peutEcrireReferentiel', coalesce(private.paiement_gestionnaire(), false),
    'gestes', pg_catalog.jsonb_build_object(
      'demanderComplement', v_decider,
      'cloreComplement', v_decider,
      'admettreVerifications', v_decider,
      'confirmerMoyenPaiement', v_decider,
      'infirmerMoyenPaiement', v_decider,
      'mettreEnPause', v_decider,
      'leverPause', v_decider,
      'refuser', v_decider,
      'consignerRetrait', v_decider,
      'rouvrir', v_decider,
      'definirResponsable', v_decider,
      'agirEnLot', v_decider,
      'inviter', false,
      'consignerPrevenu', v_decider,
      'garderPourSuivi', v_decider,
      'rattacher', v_decider,
      'planifierEntretien', v_decider,
      'consignerEntretien', v_decider,
      'pieceACorriger', false,
      'validerPiece', false,
      'restreindre', false,
      'leverRestriction', false,
      'noterIndisponibilite', false,
      'leverIndisponibilite', false),
    'gestesGroupables', CASE WHEN v_decider THEN '["mettreEnPause", "leverPause", "refuser"]'::jsonb
                             ELSE '[]'::jsonb END,
    'listes', pg_catalog.jsonb_build_object(
      'modelesRefus', CASE WHEN v_decider THEN coalesce((
        SELECT pg_catalog.jsonb_agg(m.code ORDER BY m.rang) FROM private.candidature_modeles_message m
         WHERE m.usage = 'refus' AND m.actif), '[]'::jsonb) ELSE '[]'::jsonb END,
      'modelesPause', CASE WHEN v_decider THEN coalesce((
        SELECT pg_catalog.jsonb_agg(m.code ORDER BY m.rang) FROM private.candidature_modeles_message m
         WHERE m.usage = 'pause' AND m.actif), '[]'::jsonb) ELSE '[]'::jsonb END,
      'complementSalleExamen', CASE WHEN v_decider
        THEN pg_catalog.to_jsonb(private.candidature_complement_codes('prequalification', 'enseignant'))
        ELSE '[]'::jsonb END,
      'complementSalleVerification', CASE WHEN v_decider
        THEN pg_catalog.to_jsonb(private.candidature_complement_codes('verifications', 'enseignant'))
        ELSE '[]'::jsonb END,
      'canauxRetrait', CASE WHEN v_decider THEN '["conversation", "courriel"]'::jsonb ELSE '[]'::jsonb END,
      'codesClotureComplement', CASE WHEN v_decider THEN '["complement_clos"]'::jsonb ELSE '[]'::jsonb END,
      'canauxPrevenu', CASE WHEN v_decider THEN '["whatsapp"]'::jsonb ELSE '[]'::jsonb END,
      'modelesPrevenu', CASE WHEN v_decider THEN '["lien_inscription"]'::jsonb ELSE '[]'::jsonb END));
END;
$function$;

DO $empreinte$
DECLARE
  v_ancien text := pg_catalog.obj_description('public.capacites_candidatures()'::regprocedure, 'pg_proc');
BEGIN
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.capacites_candidatures() IS %L',
    pg_catalog.regexp_replace(v_ancien, 'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)))
    || ' V1 (03/11/2026) : peutMenerEntretien, planifierEntretien et consignerEntretien suivent peutDecider. Must-pass: supabase/tests/scenarios_v1_entretiens.sql.');
END;
$empreinte$;

-- ---------------------------------------------------------------------------
-- 6. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_enum en
                   JOIN pg_catalog.pg_type t ON t.oid = en.enumtypid
                  WHERE t.typname = 'participant_role' AND en.enumlabel = 'candidat') THEN
    RAISE EXCEPTION 'V1 : participant_role sans candidat (20261107700000 manquante)';
  END IF;
  IF pg_catalog.pg_get_constraintdef((SELECT c.oid FROM pg_catalog.pg_constraint c
        WHERE c.conname = 'sessions_session_type_check'
          AND c.conrelid = 'public.sessions'::regclass)) !~ 'entretien.*reunion' THEN
    RAISE EXCEPTION 'V1 : session_type n''admet pas entretien et reunion';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.entretiens'::regclass)
     OR pg_catalog.has_table_privilege('authenticated', 'public.entretiens', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.entretiens', 'INSERT') THEN
    RAISE EXCEPTION 'V1 : public.entretiens ouverte au client';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.planifier_entretien(uuid,timestamptz,integer,uuid,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.consigner_entretien(uuid,boolean,text,text,integer,text)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.mes_entretiens(integer)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.planifier_entretien(uuid,timestamptz,integer,uuid,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.consigner_entretien(uuid,boolean,text,text,integer,text)', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.mes_entretiens(integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'V1 : droits d''execution inattendus sur les fonctions d''entretien';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.autoriser_jeton_video(uuid,uuid,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'V1 : autoriser_jeton_video executable par un client';
  END IF;
  IF pg_catalog.pg_get_functiondef('public.x217_sessions_cloture_tresorerie()'::regprocedure) !~ 'session_type'
     OR pg_catalog.pg_get_functiondef('public.autoriser_jeton_video(uuid,uuid,text,text)'::regprocedure) !~ 'candidat'
     OR pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)
          !~ 'planifierEntretien.{1,3}v_decider' THEN
    RAISE EXCEPTION 'V1 : une des trois fonctions recopiees n''a pas son ajout';
  END IF;
END;
$postflight$;
