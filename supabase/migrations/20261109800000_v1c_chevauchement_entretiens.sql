-- V1-c (04/11/2026, numero reserve par garde-cap) : le chevauchement des
-- entretiens. FICHIER B5 : il porte UN mot d'effacement (la contrainte
-- retiree puis reposee, section 3), le directeur le colle lui-meme dans l'editeur SQL
-- (CLAUDE.md, migrations sur staging) ; tout le fichier est une transaction.
--
-- Defaut trouve par le robot de V2-a (PR 221) : la seance d'entretien porte
-- teacher_id = la direction qui planifie (V1-a) ou qui a ouvert le creneau
-- (V1-b). La contrainte sessions_no_teacher_overlap refusait donc (23P01) a
-- une meme direction deux entretiens qui se chevauchent, meme pour deux
-- candidatures differentes et meme si elle n'y participe pas. A l'inverse,
-- rien n'empechait un meme intervieweur d'etre dans deux entretiens au meme
-- moment : guard_session_overlap ne compare que les roles teacher et student.
--
-- Consigne du pilote (04/11/2026, apres garde-cap) :
--   * l'EXCLUDE sessions_no_teacher_overlap ne vaut plus que pour les cours
--     (session_type IN ('standard', 'child')) : retiree puis reposee ;
--   * un garde-fou PAR PERSONNE (intervieweur ou candidat), par ancres, dans
--     planifier_entretien, ajouter_participant_entretien et
--     reserver_creneau_entretien, avec une erreur claire qui donne le nom et
--     l'heure ;
--   * des scenarios : deux entretiens en meme temps avec des intervieweurs
--     differents (acceptes), le meme intervieweur dans les deux (refuse), un
--     cours d'enseignant toujours protege.
--
-- Ce que « occupee » veut dire (private.entretien_personne_occupee) : la
-- personne a, sur une partie de la periode, une seance a venir ou en cours
-- (planned, preflight, in_progress ; non effacee ; bornes [) comme la
-- contrainte), soit comme enseignant d'un cours (titulaire ou enseignant
-- effectif, remplacant compris), soit comme participant inscrit d'une seance
-- de tout type (role autre qu'observateur, comme guard_session_overlap). La
-- direction qui a planifie un entretien sans y participer n'y est pas
-- occupee.
--
-- Concurrence : deux gestes simultanes sur la meme personne sont
-- serialises par un verrou consultatif de transaction par personne, pris dans
-- l'ordre des identifiants (aucun interblocage entre deux gestes).
--
-- Le candidat qui reserve un creneau ne lit jamais le nom d'un membre du
-- personnel : si l'un d'eux est occupe, le creneau est « indisponible »
-- (refus existant de V1-b) ; seul son propre conflit lui est dit.
--
-- Fonctions existantes retouchees, toutes par ancres comptees sur le corps
-- en vigueur (chaque ancre une fois et une seule, sinon la migration
-- s'arrete), aucune recopie entiere : public.planifier_entretien,
-- public.ajouter_participant_entretien (deja retouchee par V1-a-bis),
-- public.reserver_creneau_entretien. Aucune instruction de remplacement ecrite ici
-- (la retouche re-execute la definition rendue par pg_get_functiondef).
-- Fonction nouvelle : private.entretien_personne_occupee (aucun droit client).
--
-- Mots d'effacement de ce fichier : 1 (section 3, la contrainte retiree).

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Garde : la contrainte en vigueur est bien celle de 0005
-- ---------------------------------------------------------------------------
DO $avant$
BEGIN
  IF (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
       WHERE c.conrelid = 'public.sessions'::pg_catalog.regclass
         AND c.conname = 'sessions_no_teacher_overlap')
     IS DISTINCT FROM
     'EXCLUDE USING gist (teacher_id WITH =, tstzrange(started_at, ended_at, ''[)''::text) WITH &&) '
     || 'WHERE (((deleted_at IS NULL) AND (status = ANY (ARRAY[''planned''::session_status, '
     || '''preflight''::session_status, ''in_progress''::session_status]))))' THEN
    RAISE EXCEPTION 'V1-c : sessions_no_teacher_overlap n''est pas celle de 0005, migration a revoir : %',
      (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.sessions'::pg_catalog.regclass
          AND c.conname = 'sessions_no_teacher_overlap');
  END IF;
END;
$avant$;

-- ---------------------------------------------------------------------------
-- 1. La personne occupee
-- ---------------------------------------------------------------------------
-- Rend NULL si aucune des personnes n'est occupee sur [p_debut, p_fin), sinon
-- le premier conflit (par debut, puis par personne) :
--   {erreur: 'personne_occupee', profil, nom, debut, fin, message}
-- Le message dit le nom et l'heure (UTC, l'ecran la remet dans le fuseau de
-- l'appareil). p_sauf : la seance a ne pas compter (celle de l'entretien
-- auquel on ajoute quelqu'un). Verrouille chaque personne pour la transaction.
CREATE FUNCTION private.entretien_personne_occupee(
  p_profils uuid[],
  p_debut timestamptz,
  p_fin timestamptz,
  p_sauf uuid
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_p uuid;
  v_r record;
BEGIN
  FOR v_p IN SELECT DISTINCT x FROM pg_catalog.unnest(coalesce(p_profils, '{}'::uuid[])) x
              WHERE x IS NOT NULL ORDER BY x LOOP
    PERFORM pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended('v1c_entretien_personne:' || v_p::text, 0));
  END LOOP;

  SELECT x.profil, s.started_at, s.ended_at,
         pg_catalog.btrim(coalesce(pr.first_name, '') || ' ' || coalesce(pr.last_name, '')) AS nom
    INTO v_r
    FROM pg_catalog.unnest(coalesce(p_profils, '{}'::uuid[])) AS x(profil)
    JOIN public.sessions s
      ON s.deleted_at IS NULL
     AND s.status IN ('planned', 'preflight', 'in_progress')
     AND s.id IS DISTINCT FROM p_sauf
     AND pg_catalog.tstzrange(s.started_at, s.ended_at, '[)')
         OPERATOR(pg_catalog.&&) pg_catalog.tstzrange(p_debut, p_fin, '[)')
    LEFT JOIN public.profiles pr ON pr.id = x.profil
   WHERE x.profil IS NOT NULL
     AND (
       -- Enseignant d'un cours, titulaire ou effectif.
       (s.session_type IN ('standard', 'child')
        AND (s.teacher_id = x.profil OR private.c29_enseignant_effectif_session(s.id) = x.profil))
       -- Participant inscrit d'une seance de tout type (pas un observateur).
       OR EXISTS (
         SELECT 1 FROM public.session_participants sp
          WHERE sp.session_id = s.id AND sp.profile_id = x.profil AND sp.deleted_at IS NULL
            AND sp.role NOT IN ('masked_controller', 'guardian_observer', 'admin_masked', 'admin_visible'))
     )
   ORDER BY s.started_at, x.profil
   LIMIT 1;

  IF v_r.profil IS NULL THEN
    RETURN NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'erreur', 'personne_occupee',
    'profil', v_r.profil,
    'nom', v_r.nom,
    'debut', v_r.started_at,
    'fin', v_r.ended_at,
    'message', pg_catalog.format(
      '%s a déjà une séance ou un entretien le %s de %s à %s (UTC).',
      CASE WHEN v_r.nom = '' THEN 'Une personne choisie' ELSE v_r.nom END,
      pg_catalog.to_char(v_r.started_at AT TIME ZONE 'UTC', 'DD/MM/YYYY'),
      pg_catalog.to_char(v_r.started_at AT TIME ZONE 'UTC', 'HH24:MI'),
      pg_catalog.to_char(v_r.ended_at AT TIME ZONE 'UTC', 'HH24:MI')));
END;
$function$;
REVOKE ALL ON FUNCTION private.entretien_personne_occupee(uuid[], timestamptz, timestamptz, uuid)
  FROM PUBLIC, anon, authenticated;
COMMENT ON FUNCTION private.entretien_personne_occupee(uuid[], timestamptz, timestamptz, uuid) IS
  'V1-c (04/11/2026) : NULL, ou le premier conflit {erreur personne_occupee, profil, nom, debut, fin, '
  'message} d''une des personnes sur [debut, fin) : enseignant d''un cours (titulaire ou effectif) ou '
  'participant inscrit (hors observateurs) d''une seance a venir ou en cours. Verrou consultatif par '
  'personne. Aucun droit client.';

-- ---------------------------------------------------------------------------
-- 2. Les gestes, retouches par ancres
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

-- 2.1 Planifier (direction) : les participants et le candidat.
SELECT pg_temp.retoucher(
  'public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)',
  $a$  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_moi, p_debut,$a$,
  $a$  -- V1-c : chaque participant et le candidat sont libres sur la periode.
  v_refus := private.entretien_personne_occupee(
    v_participants || v_c.profile_id, p_debut,
    p_debut + pg_catalog.make_interval(mins => p_duree_minutes), NULL);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;

  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_moi, p_debut,$a$);

-- 2.2 Ajouter un participant (direction) : la personne ajoutee est libre.
SELECT pg_temp.retoucher(
  'public.ajouter_participant_entretien(uuid,uuid)',
  $a$  v_genre public.gender;
BEGIN$a$,
  $a$  v_genre public.gender;
  v_occupee jsonb;
BEGIN$a$);
SELECT pg_temp.retoucher(
  'public.ajouter_participant_entretien(uuid,uuid)',
  $a$  INSERT INTO public.entretien_participants AS ep (session_id, profile_id, fondateur, ajoute_par)$a$,
  $a$  -- V1-c : la personne ajoutee est libre sur la periode de l'entretien.
  v_occupee := (SELECT private.entretien_personne_occupee(ARRAY[p_profil], s.started_at, s.ended_at, p_session)
                  FROM public.sessions s WHERE s.id = p_session);
  IF v_occupee IS NOT NULL THEN
    RETURN v_occupee;
  END IF;
  INSERT INTO public.entretien_participants AS ep (session_id, profile_id, fondateur, ajoute_par)$a$);

-- 2.3 Reserver un creneau (candidat) : le candidat, et le personnel du
-- creneau. Le nom d'un membre du personnel n'est jamais dit au candidat.
SELECT pg_temp.retoucher(
  'public.reserver_creneau_entretien(uuid,integer,text)',
  $a$  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_cr.ouvert_par, v_cr.debut,$a$,
  $a$  -- V1-c : le candidat est libre ; le personnel du creneau aussi, sinon le
  -- creneau est indisponible (le candidat ne lit pas le nom du personnel).
  v_refus := private.entretien_personne_occupee(
    ARRAY[v_moi], v_cr.debut, v_cr.debut + pg_catalog.make_interval(mins => v_cr.duree_minutes), NULL);
  IF v_refus IS NOT NULL THEN
    RETURN v_refus;
  END IF;
  IF private.entretien_personne_occupee(
       ARRAY(SELECT p.profile_id FROM public.entretien_creneau_participants p WHERE p.creneau_id = p_creneau),
       v_cr.debut, v_cr.debut + pg_catalog.make_interval(mins => v_cr.duree_minutes), NULL) IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'creneau_indisponible');
  END IF;

  INSERT INTO public.sessions (teacher_id, started_at, ended_at, status, session_type, join_opens_at)
  VALUES (v_cr.ouvert_par, v_cr.debut,$a$);

-- ---------------------------------------------------------------------------
-- 3. La contrainte : les cours seulement (B5, le seul mot d'effacement)
-- ---------------------------------------------------------------------------
ALTER TABLE public.sessions DROP CONSTRAINT sessions_no_teacher_overlap;
ALTER TABLE public.sessions
  ADD CONSTRAINT sessions_no_teacher_overlap
  EXCLUDE USING gist (
    teacher_id WITH =,
    tstzrange(started_at, ended_at, '[)') WITH &&
  ) WHERE (deleted_at IS NULL AND status IN ('planned', 'preflight', 'in_progress')
           AND session_type IN ('standard', 'child'));
COMMENT ON CONSTRAINT sessions_no_teacher_overlap ON public.sessions IS
  'Un enseignant n''a jamais deux cours (standard, child) qui se chevauchent (0005). V1-c (04/11/2026) : '
  'un entretien ou une reunion n''y entre plus, chaque personne y est gardee par '
  'private.entretien_personne_occupee.';

-- ---------------------------------------------------------------------------
-- 4. Verification finale
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
  v_def text;
BEGIN
  v_def := (SELECT pg_catalog.pg_get_constraintdef(c.oid) FROM pg_catalog.pg_constraint c
             WHERE c.conrelid = 'public.sessions'::pg_catalog.regclass
               AND c.conname = 'sessions_no_teacher_overlap');
  IF v_def IS NULL OR v_def !~ 'EXCLUDE USING gist' OR v_def !~ 'session_type'
     OR v_def !~ '''standard''' OR v_def !~ '''child''' OR v_def ~ 'entretien' THEN
    RAISE EXCEPTION 'V1-c : sessions_no_teacher_overlap absente ou mal posee : %', v_def;
  END IF;
  FOREACH v_f IN ARRAY ARRAY[
      'public.planifier_entretien(uuid,timestamptz,integer,uuid[],integer,text)',
      'public.ajouter_participant_entretien(uuid,uuid)',
      'public.reserver_creneau_entretien(uuid,integer,text)'] LOOP
    v_def := pg_catalog.pg_get_functiondef(v_f::pg_catalog.regprocedure);
    IF v_def !~ 'entretien_personne_occupee' THEN
      RAISE EXCEPTION 'V1-c : % sans le garde par personne', v_f;
    END IF;
  END LOOP;
  -- V1-a-bis n'est pas defaite (le journal hors cote reste).
  IF pg_catalog.pg_get_functiondef('public.ajouter_participant_entretien(uuid,uuid)'::pg_catalog.regprocedure)
       !~ 'entretien_journal_hors_cote' THEN
    RAISE EXCEPTION 'V1-c : ajouter_participant_entretien a perdu le journal hors cote de V1-a-bis';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.entretien_personne_occupee(uuid[],timestamptz,timestamptz,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'private.entretien_personne_occupee(uuid[],timestamptz,timestamptz,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'V1-c : entretien_personne_occupee executable par un client';
  END IF;
END;
$postflight$;

COMMIT;
