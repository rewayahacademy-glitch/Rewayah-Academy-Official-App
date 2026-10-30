-- Le cours du moment de chaque Classe, meme sans seance (defaut constate en
-- production par le directeur le vendredi 30/10/2026).
--
-- Constat : la Classe « Garcons, vendredi 19 h », creee a 18:15 UTC pour un
-- creneau de 19:00 (Europe/Paris, 90 min), n'apparaissait ni sur « Aujourd'hui »
-- ni sur « Classes » de l'enseignant pendant son cours. Cause (pilote) : la
-- seance du jour n'existe en base qu'une fois le concierge appele
-- (`seance_a_rejoindre`, bouton « Rejoindre » de la fiche de Classe) ; ces deux
-- ecrans ne lisent que les seances deja creees (`mes_seances_enseignant_v`).
-- La materialisation saute le cours deja commence d'une Classe nee pendant son
-- creneau.
--
-- `horloge_classe(classe)` sait deja rendre ce cours (session_id nul tant que
-- la seance n'existe pas), Classe par Classe. Cette lecture la rend pour
-- toutes les Classes de l'appelant, en un appel :
--   - direction : les Classes actives ;
--   - enseignant : ses Classes ;
--   - eleve : ses Classes (membre actif) ;
--   - tuteur : les Classes des eleves de son foyer.
-- Une ligne par Classe : la prochaine seance vivante ou la prochaine
-- occurrence d'un creneau dont le cours n'est pas fini, la plus proche des
-- deux, exactement ce que rend `horloge_classe` (memes fenetre, grace et
-- duree, lues sur le serveur). Une Classe sans cours a venir ne rend rien.
--
-- STABLE, aucune ecriture : la lecture ne cree jamais de seance ; le concierge
-- reste seul a la creer, a l'appui sur « Rejoindre ».
--
-- Aucune suppression.

BEGIN;

CREATE FUNCTION public.cours_du_moment_mes_classes()
RETURNS TABLE (
  groupe_id            uuid,
  groupe_libelle       text,
  type_public          text,
  seuil_max            int,
  nb_membres           int,
  session_id           uuid,
  debut_utc            timestamptz,
  fin_prevue_utc       timestamptz,
  join_opens_at_utc    timestamptz,
  fenetre_minutes      int,
  grace_minutes        int,
  maintenant_utc       timestamptz
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g record;
BEGIN
  IF NOT coalesce(public.app_account_valid()
                  AND public.app_role() IN ('admin', 'teacher', 'student', 'guardian'), false) THEN
    RAISE EXCEPTION 'cours du moment non autorise' USING ERRCODE = '42501';
  END IF;

  -- Les Classes de l'appelant, avec le predicat de `horloge_classe` : chaque
  -- appel ci-dessous est donc autorise (aucun refus en cours de boucle).
  FOR v_g IN
    SELECT g.id, g.libelle, g.type_public::text AS type_public, g.seuil_max::int AS seuil_max,
           (SELECT pg_catalog.count(*) FROM public.groupe_membres m
             WHERE m.groupe_id = g.id AND m.left_at IS NULL)::int AS nb_membres
      FROM public.groupes g
     WHERE g.ended_at IS NULL
       AND g.etat = 'active'
       AND (
         public.app_role() = 'admin'
         OR (public.app_role() = 'teacher' AND g.teacher_id = auth.uid())
         OR EXISTS (
              SELECT 1 FROM public.groupe_membres m
               WHERE m.groupe_id = g.id AND m.left_at IS NULL
                 AND (m.student_id = auth.uid()
                      OR (public.app_role() = 'guardian' AND public.est_du_foyer(m.student_id))))
       )
  LOOP
    RETURN QUERY
      SELECT v_g.id, v_g.libelle, v_g.type_public, v_g.seuil_max, v_g.nb_membres,
             h.session_id, h.debut_utc, h.fin_prevue_utc, h.join_opens_at_utc,
             h.fenetre_minutes, h.grace_minutes, h.maintenant_utc
        FROM public.horloge_classe(v_g.id) h;
  END LOOP;
END;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.cours_du_moment_mes_classes()'::pg_catalog.regprocedure;
  v_role text;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-01. Cours du moment de chaque Classe, par horloge_classe, sans creer de seance (defaut du 30/10/2026).',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
BEGIN
  IF (SELECT p.provolatile FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.cours_du_moment_mes_classes()'::pg_catalog.regprocedure) <> 's' THEN
    RAISE EXCEPTION 'cours_du_moment_mes_classes doit etre STABLE (aucune ecriture)';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.cours_du_moment_mes_classes()', 'EXECUTE') THEN
    RAISE EXCEPTION 'cours_du_moment_mes_classes ouverte a anon';
  END IF;
END;
$postflight$;

COMMIT;
