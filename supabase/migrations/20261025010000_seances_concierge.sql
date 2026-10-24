-- B2.2 bis (b), « le concierge » (plan de nuit du pilote, 24/10/2026).
--
-- Constat : `materialiser_seances_groupe` cree les seances a partir de la
-- PROCHAINE occurrence de chaque creneau (`instant_creneau`, decalage 0, est
-- strictement apres maintenant). Une Classe creee, affectee ou deplacee
-- pendant la fenetre d'entree (20 minutes avant) ou pendant le cours n'a
-- donc aucune seance pour le cours du jour : « Rejoindre » ne trouve rien.
--
-- Le concierge : `seance_a_rejoindre(classe)` rend la seance de l'emploi du
-- temps qu'on peut rejoindre maintenant (fenetre d'entree ouverte, cours pas
-- fini) ; si elle manque, il la cree, avec ses participants, exactement comme
-- la materialisation (meme duree, meme type, meme ouverture de la salle).
--
-- Sans doublon : le verrou est la ligne de la Classe (`FOR UPDATE`), la meme
-- que prend `materialiser_seances_groupe` ; deux « Rejoindre » simultanes, ou
-- un « Rejoindre » pendant la cloche, passent l'un apres l'autre, et le
-- second trouve la seance du premier.
--
-- Il ne recree jamais une seance que la direction a supprimee ou annulee :
-- toute seance de la Classe a cette heure, quel que soit son etat, est
-- rendue telle quelle (ou `null` si elle est supprimee).
--
-- Qui l'appelle : l'enseignant de la Classe, un eleve inscrit (non parti), la
-- direction. Tout autre appel est refuse (42501).
--
-- Aucune suppression.

BEGIN;

CREATE OR REPLACE FUNCTION public.seance_a_rejoindre(p_groupe_id uuid)
RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_g public.groupes%ROWTYPE;
  v_creneau public.groupe_creneaux%ROWTYPE;
  v_duree integer;
  v_fenetre integer;
  v_debut timestamptz;
  v_existante public.sessions%ROWTYPE;
  v_session uuid;
BEGIN
  IF p_groupe_id IS NULL THEN
    RAISE EXCEPTION 'ClasseInconnue' USING ERRCODE = '22023';
  END IF;
  IF NOT coalesce(
       public.app_account_valid() AND v_uid IS NOT NULL AND (
         public.app_role() = 'admin'
         OR EXISTS (SELECT 1 FROM public.groupes g
                    WHERE g.id = p_groupe_id AND g.teacher_id = v_uid)
         OR EXISTS (SELECT 1 FROM public.groupe_membres m
                    WHERE m.groupe_id = p_groupe_id AND m.student_id = v_uid
                      AND m.left_at IS NULL)),
       false) THEN
    RAISE EXCEPTION 'SeanceNonAutorisee' USING ERRCODE = '42501';
  END IF;

  -- Le verrou de la Classe : celui de materialiser_seances_groupe.
  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND OR v_g.teacher_id IS NULL OR v_g.etat <> 'active' THEN
    RETURN NULL;
  END IF;

  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_fenetre := public.app_config_int('join_window_minutes', 20);

  FOR v_creneau IN
    SELECT gc.* FROM public.groupe_creneaux gc
    WHERE gc.groupe_id = p_groupe_id
    ORDER BY gc.weekday, gc.hour_local
  LOOP
    -- L'occurrence dont le cours n'est pas fini : la premiere qui commence
    -- apres (maintenant - duree).
    v_debut := public.instant_creneau_reference(
      v_creneau.weekday, v_creneau.hour_local, v_g.timezone_iana, 0,
      pg_catalog.now() - pg_catalog.make_interval(mins => v_duree));
    IF v_debut - pg_catalog.make_interval(mins => v_fenetre) > pg_catalog.now() THEN
      CONTINUE;  -- la salle n'ouvre pas encore
    END IF;

    SELECT s.* INTO v_existante
    FROM public.sessions s
    WHERE s.groupe_id = p_groupe_id AND s.started_at = v_debut
    ORDER BY (s.deleted_at IS NULL) DESC, s.created_at
    LIMIT 1;
    IF FOUND THEN
      IF v_existante.deleted_at IS NOT NULL THEN
        CONTINUE;
      END IF;
      RETURN v_existante.id;
    END IF;

    INSERT INTO public.sessions
      (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
    VALUES
      (v_g.teacher_id, v_debut,
       v_debut + pg_catalog.make_interval(mins => v_duree),
       CASE v_g.type_public WHEN 'enfant' THEN 'child' ELSE 'standard' END,
       p_groupe_id, v_debut - pg_catalog.make_interval(mins => v_fenetre))
    RETURNING id INTO v_session;

    INSERT INTO public.session_participants (session_id, profile_id, role)
    SELECT v_session, m.student_id, 'student'
    FROM public.groupe_membres m
    WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;

    RETURN v_session;
  END LOOP;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION public.seance_a_rejoindre(uuid) FROM PUBLIC;
DO $droits$
DECLARE v_role text;
BEGIN
  FOREACH v_role IN ARRAY ARRAY['anon', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format(
        'REVOKE ALL ON FUNCTION public.seance_a_rejoindre(uuid) FROM %I', v_role);
    END IF;
  END LOOP;
END;
$droits$;
GRANT EXECUTE ON FUNCTION public.seance_a_rejoindre(uuid) TO authenticated;

COMMENT ON FUNCTION public.seance_a_rejoindre(uuid) IS
  'B2.2 bis (b), le concierge : rend la seance de la Classe a rejoindre maintenant, la cree sans doublon si elle manque.';

COMMIT;
