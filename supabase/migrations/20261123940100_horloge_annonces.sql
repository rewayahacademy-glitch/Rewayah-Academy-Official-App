-- HORLOGE-ET-LIEU, partie A, suite (architecte pedagogique, 12/11/2026 ; decision
-- H3, docs/current/pedagogie/HORLOGE-ET-LIEU.md).
--
-- Tous les cours sont a l'heure de La Mecque, qui ne change jamais. Dans un
-- pays qui change d'heure, l'heure LOCALE d'un cours bouge d'une heure deux
-- fois par an : chaque personne est prevenue 14 jours avant et la veille, avec
-- l'heure exacte avant et apres (« A partir du dimanche 28 mars, votre cours
-- passe de 19 h a 20 h »). Pour un mineur, le tuteur est prevenu, jamais
-- l'enfant. Les annonces se calculent PAR PERSONNE d'apres son fuseau : la
-- classe, elle, n'a plus de changement d'heure.
--
-- 1. private.changement_heure_cours : pour UN creneau et UN fuseau de
--    personne, l'heure locale avant et apres le prochain changement d'heure.
-- 2. public.apercu_creneau_academie : le meme calcul, pour l'ecran
--    (« 19 h, puis 20 h a partir du 28 mars chez vous »), a la creation d'un
--    creneau et a l'inscription dans une classe. Aucune donnee personnelle.
-- 3. private.annonces_changement_heure : une ligne par annonce envoyee
--    (personne, classe, changement, palier), pour ne jamais annoncer deux fois.
-- 4. private.annoncer_changements_heure : la tache quotidienne. Elle pose une
--    notification `creneau_change` (evenement deja admis : meme circuit que
--    les autres changements de creneau, courriel compris ; le texte de
--    l'application, du courriel et du push suit les parametres) avec l'heure
--    avant et apres.
-- 5. Planification quotidienne (pg_cron absente : rien, comme les autres).
--
-- FICHIER SANS EFFACEMENT : des objets crees, aucun retire, aucune ligne
-- effacee.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. L'heure locale d'un creneau avant et apres le prochain changement d'heure
-- ---------------------------------------------------------------------------
-- p_fuseau_creneau : le fuseau dans lequel le creneau est defini (celui de
-- l'academie ; celui de la classe tant qu'elle n'est pas convertie).
-- Rend une ligne quand l'heure OU le jour local du cours change au prochain
-- changement d'heure du fuseau de la personne, sinon rien.
CREATE FUNCTION private.changement_heure_cours(
  p_fuseau_personne text,
  p_fuseau_creneau text,
  p_weekday integer,
  p_hour integer,
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS TABLE (
  transition timestamptz,
  date_changement text,
  jour_avant integer,
  heure_avant text,
  jour_apres integer,
  heure_apres text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_transition timestamptz;
  v_avant timestamptz;
  v_apres timestamptz;
BEGIN
  IF p_fuseau_personne IS NULL OR p_fuseau_creneau IS NULL
     OR NOT app_private.fuseau_connu(p_fuseau_personne)
     OR NOT app_private.fuseau_connu(p_fuseau_creneau) THEN
    RETURN;
  END IF;
  v_transition := (private.fuseau_info(p_fuseau_personne, p_maintenant) ->> 'prochain_changement')::timestamptz;
  IF v_transition IS NULL THEN
    RETURN;
  END IF;
  -- La derniere occurrence avant le changement, la premiere apres (la semaine
  -- d'avant la prochaine occurrence compte : un changement d'heure imminent
  -- n'a plus d'occurrence avant lui dans l'avenir).
  SELECT pg_catalog.max(o.debut) FILTER (WHERE o.debut < v_transition),
         pg_catalog.min(o.debut) FILTER (WHERE o.debut >= v_transition)
    INTO v_avant, v_apres
    FROM (SELECT public.instant_creneau_reference(p_weekday, p_hour, p_fuseau_creneau, k, p_maintenant) AS debut
            FROM pg_catalog.generate_series(-1, 60) AS k) o;
  IF v_avant IS NULL OR v_apres IS NULL THEN
    RETURN;
  END IF;
  jour_avant := pg_catalog.date_part('isodow', v_avant AT TIME ZONE p_fuseau_personne)::integer;
  heure_avant := pg_catalog.to_char(v_avant AT TIME ZONE p_fuseau_personne, 'HH24:MI');
  jour_apres := pg_catalog.date_part('isodow', v_apres AT TIME ZONE p_fuseau_personne)::integer;
  heure_apres := pg_catalog.to_char(v_apres AT TIME ZONE p_fuseau_personne, 'HH24:MI');
  IF jour_avant = jour_apres AND heure_avant = heure_apres THEN
    RETURN;
  END IF;
  transition := v_transition;
  date_changement := pg_catalog.to_char(v_transition AT TIME ZONE p_fuseau_personne, 'YYYY-MM-DD');
  RETURN NEXT;
END;
$function$;

REVOKE ALL ON FUNCTION private.changement_heure_cours(text, text, integer, integer, timestamptz)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.changement_heure_cours(text, text, integer, integer, timestamptz) IS
  'HORLOGE-ET-LIEU (12/11/2026) : l''heure locale d''un creneau avant et apres le prochain changement d''heure du fuseau d''une personne ; aucune ligne quand rien ne change. DEFINER, search_path vide, aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 2. L'apercu pour l'ecran : « 19 h, puis 20 h a partir du 28 mars chez vous »
-- ---------------------------------------------------------------------------
-- p_heure : l'heure du creneau au fuseau de l'academie, ou a celui de
-- p_fuseau_creneau quand il est donne (une offre pas encore convertie). Rend
-- `meme` vrai quand l'heure locale ne change jamais dans l'annee.
CREATE FUNCTION public.apercu_creneau_academie(
  p_fuseau text,
  p_weekday integer,
  p_heure integer,
  p_fuseau_creneau text DEFAULT NULL)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_academie text := coalesce(p_fuseau_creneau, private.fuseau_academie());
  v_maintenant timestamptz := pg_catalog.now();
  v_actuel timestamptz;
  v_c record;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'apercu non autorise' USING ERRCODE = '42501';
  END IF;
  IF p_fuseau IS NULL OR NOT app_private.fuseau_connu(p_fuseau)
     OR NOT app_private.fuseau_connu(v_academie)
     OR p_weekday IS NULL OR p_weekday NOT BETWEEN 1 AND 7
     OR p_heure IS NULL OR p_heure NOT BETWEEN 0 AND 23 THEN
    RAISE EXCEPTION 'apercu : parametres invalides' USING ERRCODE = '22023';
  END IF;
  v_actuel := public.instant_creneau_reference(p_weekday, p_heure, v_academie, 0, v_maintenant);
  SELECT * INTO v_c FROM private.changement_heure_cours(p_fuseau, v_academie, p_weekday, p_heure, v_maintenant);
  RETURN pg_catalog.jsonb_build_object(
    'fuseau', p_fuseau,
    'academie', v_academie,
    'maintenant', pg_catalog.to_char(v_actuel AT TIME ZONE p_fuseau, 'HH24:MI'),
    'jour_maintenant', pg_catalog.date_part('isodow', v_actuel AT TIME ZONE p_fuseau)::integer,
    'meme', v_c.transition IS NULL,
    'date_changement', v_c.date_changement,
    'jour_apres', v_c.jour_apres,
    'heure_apres', v_c.heure_apres);
END;
$function$;

REVOKE ALL ON FUNCTION public.apercu_creneau_academie(text, integer, integer, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.apercu_creneau_academie(text, integer, integer, text) TO authenticated;
COMMENT ON FUNCTION public.apercu_creneau_academie(text, integer, integer, text) IS
  'HORLOGE-ET-LIEU (12/11/2026) : pour un creneau a l''heure de l''academie, l''heure locale chez soi aujourd''hui et apres le prochain changement d''heure de son fuseau. Aucune donnee personnelle. Compte valide exige. DEFINER, search_path vide.';

-- ---------------------------------------------------------------------------
-- 3. Les annonces deja envoyees
-- ---------------------------------------------------------------------------
CREATE TABLE private.annonces_changement_heure (
  destinataire uuid        NOT NULL,
  groupe_id    uuid        NOT NULL,
  transition   timestamptz NOT NULL,
  palier       text        NOT NULL CHECK (palier IN ('j14', 'j1')),
  annoncee_le  timestamptz NOT NULL DEFAULT pg_catalog.now(),
  PRIMARY KEY (destinataire, groupe_id, transition, palier)
);
ALTER TABLE private.annonces_changement_heure ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.annonces_changement_heure FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON TABLE private.annonces_changement_heure IS
  'HORLOGE-ET-LIEU (12/11/2026) : une ligne par annonce de changement d''heure envoyee (personne, classe, changement, palier), pour ne jamais annoncer deux fois. RLS sans politique.';

-- ---------------------------------------------------------------------------
-- 4. La tache quotidienne
-- ---------------------------------------------------------------------------
-- Rend le nombre de notifications posees. p_maintenant : l'instant de
-- reference (le test le fixe).
CREATE FUNCTION private.annoncer_changements_heure(
  p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_r record;
  v_palier text;
  v_n integer := 0;
  v_pose integer;
BEGIN
  FOR v_r IN
    WITH classes AS (
      SELECT g.id, g.timezone_iana AS fuseau_classe, g.type_public, g.teacher_id, g.libelle
        FROM public.groupes g
       WHERE g.ended_at IS NULL AND g.etat = 'active' AND g.teacher_id IS NOT NULL
    ),
    personnes AS (
      -- L'enseignant de la classe, a son fuseau.
      SELECT c.id AS groupe_id, c.teacher_id AS destinataire, NULL::uuid AS foyer,
             'classe'::text AS portee, coalesce(tp.timezone_iana, c.fuseau_classe) AS fuseau
        FROM classes c
        LEFT JOIN public.teacher_profiles tp ON tp.profile_id = c.teacher_id
      UNION
      -- Les tuteurs du foyer de chaque eleve inscrit : toujours, jamais l'enfant.
      SELECT c.id, t.id, h.id, 'foyer', coalesce(h.timezone, c.fuseau_classe)
        FROM classes c
        JOIN public.groupe_membres gm ON gm.groupe_id = c.id AND gm.left_at IS NULL
        JOIN public.profiles s ON s.id = gm.student_id AND s.deleted_at IS NULL
        JOIN public.households h ON h.id = s.household_id AND h.deleted_at IS NULL
        JOIN public.profiles t ON t.deleted_at IS NULL AND t.role = 'guardian'
                              AND (t.id = h.primary_guardian_id OR t.household_id = h.id)
      UNION
      -- Un eleve d'une classe d'adultes : lui-meme.
      SELECT c.id, s.id, s.household_id, 'soi', coalesce(h.timezone, c.fuseau_classe)
        FROM classes c
        JOIN public.groupe_membres gm ON gm.groupe_id = c.id AND gm.left_at IS NULL
        JOIN public.profiles s ON s.id = gm.student_id AND s.deleted_at IS NULL
        LEFT JOIN public.households h ON h.id = s.household_id AND h.deleted_at IS NULL
       WHERE c.type_public = 'adulte'
    ),
    -- Une personne, une ligne par classe (l'eleve adulte avant le tuteur).
    destinataires AS (
      SELECT DISTINCT ON (p.groupe_id, p.destinataire)
             p.groupe_id, p.destinataire, p.foyer, p.portee, p.fuseau
        FROM personnes p
       ORDER BY p.groupe_id, p.destinataire,
                CASE p.portee WHEN 'soi' THEN 1 WHEN 'foyer' THEN 2 ELSE 3 END
    ),
    creneaux AS (
      SELECT c.id AS groupe_id, c.fuseau_classe, c.libelle,
             s.jour, s.heure
        FROM classes c
        CROSS JOIN LATERAL (
          SELECT gc.weekday::integer AS jour, gc.hour_local::integer AS heure
            FROM public.groupe_creneaux gc WHERE gc.groupe_id = c.id
          UNION
          SELECT g.weekday::integer, g.hour_local::integer FROM public.groupes g WHERE g.id = c.id
        ) s
    )
    SELECT d.groupe_id, d.destinataire, d.foyer, d.portee, d.fuseau,
           pg_catalog.min(ch.transition) AS transition,
           pg_catalog.min(ch.date_changement) AS date_changement,
           cr.libelle,
           pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'jour_avant', ch.jour_avant, 'avant', ch.heure_avant,
             'jour_apres', ch.jour_apres, 'apres', ch.heure_apres)
             ORDER BY ch.jour_avant, ch.heure_avant) AS changements
      FROM destinataires d
      JOIN creneaux cr ON cr.groupe_id = d.groupe_id
      CROSS JOIN LATERAL private.changement_heure_cours(
        d.fuseau, cr.fuseau_classe, cr.jour, cr.heure, p_maintenant) ch
     GROUP BY d.groupe_id, d.destinataire, d.foyer, d.portee, d.fuseau, cr.libelle
  LOOP
    -- Le palier : 14 jours avant (des qu'on entre dans la fenetre), puis la
    -- veille (les dernieres 24 heures).
    v_palier := CASE
      WHEN p_maintenant >= v_r.transition - interval '1 day' AND p_maintenant < v_r.transition THEN 'j1'
      WHEN p_maintenant >= v_r.transition - interval '14 days' AND p_maintenant < v_r.transition THEN 'j14'
      ELSE NULL END;
    CONTINUE WHEN v_palier IS NULL;

    INSERT INTO private.annonces_changement_heure (destinataire, groupe_id, transition, palier)
    VALUES (v_r.destinataire, v_r.groupe_id, v_r.transition, v_palier)
    ON CONFLICT DO NOTHING;
    GET DIAGNOSTICS v_pose = ROW_COUNT;
    CONTINUE WHEN v_pose = 0;

    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    VALUES (
      v_r.destinataire, v_r.foyer, 'creneau_change',
      pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'groupe_id', v_r.groupe_id,
        'portee', v_r.portee,
        'fuseau', v_r.fuseau,
        'classe', nullif(pg_catalog.btrim(v_r.libelle), ''),
        'motif', 'changement_heure',
        'palier', v_palier,
        'date_changement', v_r.date_changement,
        'changements', v_r.changements)),
      CASE v_r.portee
        WHEN 'soi' THEN '/eleve'
        WHEN 'foyer' THEN '/tuteur/classes/' || v_r.groupe_id::text
        ELSE '/enseignant/classes' END);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$function$;

REVOKE ALL ON FUNCTION private.annoncer_changements_heure(timestamptz)
  FROM PUBLIC, anon, authenticated, service_role;
COMMENT ON FUNCTION private.annoncer_changements_heure(timestamptz) IS
  'HORLOGE-ET-LIEU (12/11/2026) : tache quotidienne, annonce a chaque personne concernee, 14 jours avant et la veille, l''heure locale de son cours avant et apres le changement d''heure de son pays (tuteur pour un mineur). Idempotente. DEFINER, search_path vide, aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 5. Planification quotidienne
-- ---------------------------------------------------------------------------
DO $planification$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $c$SELECT cron.schedule('horloge_annonces', '7 7 * * *',
      'SELECT private.annoncer_changements_heure()')$c$;
  ELSE
    RAISE NOTICE 'HORLOGE-ET-LIEU : pg_cron absente, rien n''est planifie';
  END IF;
END
$planification$;

-- ---------------------------------------------------------------------------
-- 6. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_f text;
  v_r text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'private.changement_heure_cours(text,text,integer,integer,timestamp with time zone)',
    'private.annoncer_changements_heure(timestamp with time zone)']
  LOOP
    FOREACH v_r IN ARRAY ARRAY['anon', 'authenticated', 'service_role'] LOOP
      IF pg_catalog.has_function_privilege(v_r, v_f::pg_catalog.regprocedure, 'EXECUTE') THEN
        RAISE EXCEPTION 'HORLOGE-ET-LIEU : % peut executer %', v_r, v_f;
      END IF;
    END LOOP;
  END LOOP;
  IF NOT pg_catalog.has_function_privilege('authenticated',
       'public.apercu_creneau_academie(text,integer,integer,text)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.apercu_creneau_academie(text,integer,integer,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : droits de apercu_creneau_academie';
  END IF;
  IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c
           WHERE c.oid = 'private.annonces_changement_heure'::pg_catalog.regclass) THEN
    RAISE EXCEPTION 'HORLOGE-ET-LIEU : RLS absente sur private.annonces_changement_heure';
  END IF;
END
$postflight$;

COMMIT;
