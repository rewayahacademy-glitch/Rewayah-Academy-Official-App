-- CLASSES-DUREE (22/10/2026) : l'affectation d'un enseignant couvre TOUTE la
-- duree de la seance de la Classe (90 minutes pour les adultes).
--
-- Defaut constate (CANDIDATURES/SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- section 2.1 bis, « Ce qui manque pour qu'un cours adulte de 90 minutes soit
-- compare correctement », points 1 a 3) sur le predicat
-- app_private.verifier_affectation_enseignant_base (corps de
-- 20261021210200_creer_groupe_predicat_affectation.sql, renomme par
-- 20261022000200_classes_plafond_par_enseignant.sql) :
--   1. une SEULE duree pour toutes les Classes : le reglage
--      session_duration_minutes (60 par defaut), alors qu'une Classe d'adultes
--      dure 90 minutes (offres_horaires.duree_minutes ; reglages
--      seance.duree_minutes_adulte 90 et seance.duree_minutes_enfant 60,
--      0043:536-537) ;
--   2. la couverture par les disponibilites exige qu'UNE SEULE ligne de
--      weekly_availability (une heure entiere) contienne toute la seance :
--      un enseignant disponible de 18 h a 20 h (lignes 18 et 19) etait refuse
--      pour un cours de 18 h a 19 h 30, et, avec la duree unique de 60
--      minutes, un cours d'adultes etait accepte sur la seule heure 18 dont il
--      depasse la fin de 30 minutes ;
--   3. le plafond horaire et les collisions comptaient la meme duree pour les
--      deux Classes en presence.
--
-- 1. D'ou se lit la duree de la Classe, et pourquoi.
--    app_private.duree_seance_minutes(offre_id, type_public), nouvelle, lit :
--    a) la duree de l'OFFRE dont la Classe est nee (groupes.offre_id,
--       offres_horaires.duree_minutes) quand il y en a une : c'est ce que
--       l'academie a publie aux familles, et ce que la Classe tient jusqu'a sa
--       cloture, meme si le reglage du public change ensuite ;
--    b) sinon le reglage du PUBLIC de la Classe (groupes.type_public, jamais
--       nul) : seance.duree_minutes_adulte (90) ou seance.duree_minutes_enfant
--       (60), que la direction regle (app_config) et que creer_offre_horaire
--       copie deja sur une offre neuve (0043:1090-1091). C'est le cas d'une
--       Classe creee par creer_groupe (« Creer la classe », c11bis), qui n'a pas
--       d'offre. Le reglage session_duration_minutes ne sert plus aux Classes ;
--       il reste la duree des affectations individuelles recurrentes
--       (teacher_student_assignments), qui n'ont ni offre ni public.
--    Une duree hors de 15 a 240 minutes (la borne de offres_horaires) ou un
--    public inconnu REFUSE (garde positive) : jamais de repli silencieux sur 60.
--
-- 2. Ce que « couvrir » veut dire. Une seance qui commence a l'instant D et
--    dure d minutes occupe [D, D + d). Elle est couverte quand l'UNION des
--    heures declarees de l'enseignant (une ligne de weekly_availability =
--    [instant de la ligne, + 1 h)) contient tout cet intervalle, sans trou :
--    chaque heure entiere touchee par la seance a sa ligne. Pour 90 minutes a
--    18 h, les lignes 18 et 19 ; a 18 h pour 60 minutes, la ligne 18 ; a 23 h
--    pour 90 minutes, les lignes 23 et, le jour suivant, 0 (le dimanche 23 h
--    passe au lundi 0 h : la semaine suivante, les lignes etant
--    examinees avec toutes les semaines). Le compte se fait en instants, comme
--    avant : la conversion de fuseau (instant_creneau, avec le fuseau de chaque
--    ligne et celui de la Classe) et les 52 semaines de l'annee (les deux
--    saisons, avant et apres les changements d'heure) sont ceux de la
--    definition precedente. Un enseignant
--    qui declare dans un autre fuseau que celui de la Classe est donc compare
--    en instants, y compris quand les deux grilles ne tombent pas sur les
--    memes heures (une ligne de 23 h a Calcutta couvre de 17 h 30 a 18 h 30
--    UTC : deux lignes couvrent alors une seance d'une heure a 18 h UTC).
--    Les lignes sont prises de la semaine -1 (la derniere occurrence deja
--    commencee) a la semaine 52 : instant_creneau rend la PROCHAINE occurrence
--    apres maintenant, et la ligne qui couvre le debut de la prochaine seance
--    d'une grille decalee a pu commencer il y a moins d'une heure ; sans la
--    semaine -1, un enseignant couvert etait refuse pendant cette demi-heure de
--    la semaine (relecture du 22/10).
--    Realisation : les heures declarees sont fusionnees une fois en plages
--    continues (deux heures qui se touchent font une plage), puis chaque
--    occurrence de la Classe doit tenir dans une plage. L'ancienne boucle
--    recalculait les instants de chaque ligne pour chaque occurrence ; celle-ci
--    les calcule une fois par ligne et par semaine (instant_creneau, fonction
--    SQL non inlinee, environ 0,1 ms l'appel). Mesure locale du 22/10 sur
--    l'appel du predicat de base, une Classe de trois seances : 30 heures
--    declarees, 0,2 s au lieu de 0,7 s avant ce lot ; 168 heures declarees (le
--    maximum d'une semaine), 1,0 s au lieu de 2,8 s.
--    Le refus garde son message (enseignant non disponible: jour, heure,
--    fuseau, semaine, instant) ; un DETAIL ajoute la duree et le premier
--    instant non couvert.
--
-- 3. Plafond horaire et collisions, avec la duree propre a chaque Classe :
--    * le plafond horaire additionne, pour chaque creneau, la duree de sa
--      Classe (la Classe visee, les Classes actives de l'enseignant) ; les
--      affectations individuelles gardent session_duration_minutes ;
--    * une collision compare l'intervalle de la Classe visee (sa duree) a celui
--      de chaque Classe deja tenue (la sienne) : une Classe d'adultes de 18 h a
--      19 h 30 touche une Classe d'enfants de 19 h, mais pas celle de 19 h 30.
--      Les seances ponctuelles (sessions) comptent leur propre fin.
--    Pour des Classes de 60 minutes, rien ne change.
--
-- Ce qui ne bouge pas : la signature, les attributs (INVOKER, search_path
-- vide), les droits (aucun EXECUTE client), le verrou par enseignant
-- (pg_advisory_xact_lock « teacher-schedule »), tous les autres refus (compte,
-- piece, acces, langue, genre) dans le meme ordre, le drapeau
-- p_exiger_disponibilites (false pour creer_groupe) ; l'enveloppe
-- app_private.verifier_affectation_enseignant (20261022000200) et le plafond
-- de Classes plafond_classes_atteint, qui ne sont pas touches. Le corps est une
-- copie integrale de la definition precedente, aux endroits ci-dessus pres.
--
-- Ce qui n'est pas dans ce lot : le cote eleve et les creneaux libres
-- (enseignants_pour_public, free_teacher_slots) comptent encore une duree
-- unique ; enseignants_pour_classe passe, lui, par le predicat. La duree des
-- seances MATERIALISEES (materialiser_seances_groupe lit encore
-- session_duration_minutes) : voir le document de specification, 2.1 bis.
--
-- Droits (F86) : la fonction nouvelle est de app_private, INVOKER, sans
-- EXECUTE pour aucun role ; le predicat redefini garde les siens.
BEGIN;

-- ------------------------------------------------------------------
-- 1. La duree de la seance d'une Classe
-- ------------------------------------------------------------------
CREATE FUNCTION app_private.duree_seance_minutes(p_offre_id uuid, p_type_public text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_duree integer;
BEGIN
  -- Garde positive : un public inconnu (ou nul) refuse, il ne retombe pas sur 60.
  IF NOT coalesce(p_type_public IN ('enfant', 'adulte'), false) THEN
    RAISE EXCEPTION 'public de classe inconnu';
  END IF;
  -- a) La duree de l'offre dont la Classe est nee.
  IF p_offre_id IS NOT NULL THEN
    SELECT o.duree_minutes INTO v_duree
    FROM public.offres_horaires o
    WHERE o.id = p_offre_id;
  END IF;
  -- b) Sinon le reglage du public.
  IF v_duree IS NULL THEN
    v_duree := CASE p_type_public
      WHEN 'adulte' THEN public.app_config_int('seance.duree_minutes_adulte', 90)
      ELSE public.app_config_int('seance.duree_minutes_enfant', 60)
    END;
  END IF;
  IF NOT coalesce(v_duree BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'duree de seance inconnue ou hors de 15 a 240 minutes';
  END IF;
  RETURN v_duree;
END;
$function$;

ALTER FUNCTION app_private.duree_seance_minutes(uuid, text) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.duree_seance_minutes(uuid, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION app_private.duree_seance_minutes(uuid, text) IS
  'CLASSES-DUREE : duree de la seance d''une Classe, en minutes : celle de son offre (groupes.offre_id, offres_horaires.duree_minutes) sinon le reglage de son public (seance.duree_minutes_adulte 90, seance.duree_minutes_enfant 60). Refuse (garde positive) un public inconnu ou une duree hors de 15 a 240. INVOKER, aucun EXECUTE client.';

-- ------------------------------------------------------------------
-- 2. Le predicat de base : meme signature, meme verrou, memes refus
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION app_private.verifier_affectation_enseignant_base(
  p_groupe_id uuid,
  p_teacher_id uuid,
  p_exiger_disponibilites boolean
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_gender public.gender;
  v_cap int;
  v_duree int;
  v_duree_individuelle int;
  v_charge numeric;
  v_c record;
  v_busy record;
  v_w int;
  v_debut timestamptz;
  v_fin timestamptz;
  v_busy_debut timestamptz;
  v_aw int;
  v_plages_debut timestamptz[];
  v_plages_fin timestamptz[];
BEGIN
  IF p_groupe_id IS NULL OR p_teacher_id IS NULL THEN
    RAISE EXCEPTION 'classe ou enseignant absent';
  END IF;

  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe indisponible';
  END IF;

  -- Serialise deux tentatives concurrentes d'affecter le meme enseignant.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('teacher-schedule:' || p_teacher_id::text, 0)
  );

  SELECT p.gender INTO v_gender
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.id = p_teacher_id
    AND p.role = 'teacher'
    AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL
    AND tp.kyc_status = 'approved'
    AND (v_g.langue_code IS NULL OR v_g.langue_code = ANY(tp.languages));
  IF NOT FOUND OR v_gender IS NULL THEN
    RAISE EXCEPTION 'enseignant indisponible ou genre inconnu';
  END IF;

  IF v_g.genre_public IS NULL
     OR v_g.genre_public NOT IN ('hommes', 'femmes', 'indetermine')
     OR (v_g.genre_public = 'hommes' AND v_gender <> 'male')
     OR (v_g.genre_public = 'femmes' AND v_gender <> 'female') THEN
    RAISE EXCEPTION 'enseignant incompatible avec le public de la classe';
  END IF;

  -- CLASSES-DUREE : la duree de la seance de CETTE Classe (son offre, sinon le
  -- reglage de son public) ; les affectations individuelles gardent la duree
  -- unique d'avant, qu'elles n'ont ni offre ni public.
  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_duree_individuelle := public.app_config_int('session_duration_minutes', 60);
  SELECT tp.weekly_hours_cap INTO v_cap
  FROM public.teacher_profiles tp
  WHERE tp.profile_id = p_teacher_id;

  -- La charge hebdomadaire, en minutes : chaque creneau compte la duree de sa
  -- Classe.
  SELECT
    (
      SELECT coalesce(pg_catalog.sum(active_groups.duree), 0) FROM (
        SELECT DISTINCT g.id, gs.weekday, gs.hour_local,
               app_private.duree_seance_minutes(g.offre_id, g.type_public) AS duree
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) gs
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
      ) active_groups
    )
    +
    (
      SELECT pg_catalog.count(*) * v_duree_individuelle
      FROM public.teacher_student_assignments tsa
      JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
      WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
    )
    +
    (
      SELECT pg_catalog.count(*) * v_duree FROM (
        SELECT DISTINCT gs.weekday, gs.hour_local
        FROM public.groupes target
        CROSS JOIN LATERAL (
          SELECT target.weekday, target.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = target.id
        ) gs
        WHERE target.id = p_groupe_id
      ) target_slots
    )
  INTO v_charge;

  IF v_cap IS NULL OR v_charge / 60.0 > v_cap THEN
    RAISE EXCEPTION 'plafond horaire enseignant dépassé';
  END IF;

  -- Couverture par les disponibilites declarees : chaque occurrence de la
  -- classe, y compris avant et apres les changements saisonniers. Exigee
  -- sauf quand l'appelant passe false (creer_groupe : D4 et CAND-Q15, la
  -- couverture n'est qu'un avertissement a l'ecran). NULL vaut true.
  --
  -- CLASSES-DUREE : la seance [debut, debut + duree) doit tenir dans l'UNION
  -- des heures declarees (chacune [instant de la ligne, + 1 h)), sans trou.
  -- Les heures declarees sont d'abord fusionnees UNE FOIS en plages continues
  -- (deux heures qui se touchent font une plage), en instants, sur les semaines
  -- -1 a 52 ; chaque occurrence doit ensuite tenir dans UNE plage. Les lignes
  -- d'une autre semaine que celle de l'occurrence ne changent rien : elles sont
  -- a sept jours. La semaine -1 est la derniere occurrence de la ligne qui a
  -- deja commence : instant_creneau rend la PROCHAINE occurrence apres
  -- maintenant, donc, quand la grille d'un enseignant tombe a la demi-heure de
  -- celle de la Classe (Calcutta), la ligne qui couvre le debut de la prochaine
  -- seance a pu commencer il y a moins d'une heure ; sans elle, ce cours etait
  -- refuse pendant cette demi-heure de la semaine.
  IF coalesce(p_exiger_disponibilites, true) THEN
    SELECT coalesce(pg_catalog.array_agg(m.debut ORDER BY m.debut), ARRAY[]::timestamptz[]),
           coalesce(pg_catalog.array_agg(m.fin ORDER BY m.debut), ARRAY[]::timestamptz[])
      INTO v_plages_debut, v_plages_fin
    FROM (
      SELECT pg_catalog.min(o.debut) AS debut, pg_catalog.max(o.fin) AS fin
      FROM (
        SELECT h.debut, h.fin,
               pg_catalog.sum(CASE WHEN h.fin_avant IS NULL OR h.debut > h.fin_avant THEN 1 ELSE 0 END)
                 OVER (ORDER BY h.debut, h.fin) AS plage
        FROM (
          SELECT x.debut, x.fin,
                 pg_catalog.max(x.fin) OVER (ORDER BY x.debut, x.fin
                                             ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS fin_avant
          FROM (
            SELECT d.debut, d.debut + interval '1 hour' AS fin
            FROM public.weekly_availability wa
            CROSS JOIN LATERAL pg_catalog.generate_series(-1, 52) AS w(n)
            CROSS JOIN LATERAL (
              -- OFFSET 0 : l'instant est calcule une fois par ligne et par semaine,
              -- non recopie dans chacune de ses utilisations.
              SELECT public.instant_creneau(wa.weekday, wa.hour_local, wa.timezone_iana, w.n) AS debut
              OFFSET 0
            ) d
            WHERE wa.profile_id = p_teacher_id
              AND d.debut IS NOT NULL
          ) x
        ) h
      ) o
      GROUP BY o.plage
    ) m;

    FOR v_c IN
      SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
      FROM (
        SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
        UNION
        SELECT gc.weekday, gc.hour_local
        FROM public.groupe_creneaux gc
        WHERE gc.groupe_id = p_groupe_id
      ) slots
    LOOP
      FOR v_w IN 0..51 LOOP
        v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
        v_fin := v_debut + pg_catalog.make_interval(mins => v_duree);
        IF NOT EXISTS (
          SELECT 1
          FROM ROWS FROM (pg_catalog.unnest(v_plages_debut), pg_catalog.unnest(v_plages_fin)) AS p(debut, fin)
          WHERE p.debut <= v_debut AND p.fin >= v_fin
        ) THEN
          -- Le premier instant non couvert : le debut de la seance, ou la fin
          -- de la plage qui le contient.
          RAISE EXCEPTION 'enseignant non disponible: jour %, heure %, fuseau %, semaine %, instant %',
            v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w, v_debut
            USING DETAIL = pg_catalog.format(
              'duree de la seance : %s minutes ; premier instant non couvert : %s',
              v_duree,
              coalesce((SELECT pg_catalog.max(p.fin)
                          FROM ROWS FROM (pg_catalog.unnest(v_plages_debut), pg_catalog.unnest(v_plages_fin)) AS p(debut, fin)
                         WHERE p.debut <= v_debut AND p.fin > v_debut), v_debut));
        END IF;
      END LOOP;
    END LOOP;
  END IF;

  -- C-07 : les creneaux principaux et secondaires des classes actives,
  -- les affectations individuelles recurrentes et les seances ponctuelles
  -- sont comparees comme des instants, pas comme des heures locales.
  -- CLASSES-DUREE : chaque creneau occupe la duree de SA Classe (celle de la
  -- Classe visee pour v_debut).
  FOR v_c IN
    SELECT DISTINCT slots.weekday, slots.hour_local, v_g.timezone_iana
    FROM (
      SELECT v_g.weekday AS weekday, v_g.hour_local AS hour_local
      UNION
      SELECT gc.weekday, gc.hour_local
      FROM public.groupe_creneaux gc
      WHERE gc.groupe_id = p_groupe_id
    ) slots
  LOOP
    FOR v_busy IN
      SELECT DISTINCT busy.weekday, busy.hour_local, busy.timezone_iana, busy.duree
      FROM (
        SELECT slots.weekday, slots.hour_local, g.timezone_iana,
               app_private.duree_seance_minutes(g.offre_id, g.type_public) AS duree
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc
          WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = p_teacher_id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND g.id <> p_groupe_id
        UNION
        SELECT wa.weekday, wa.hour_local, wa.timezone_iana, v_duree_individuelle AS duree
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
        WHERE tsa.teacher_id = p_teacher_id AND tsa.ended_at IS NULL
      ) busy
    LOOP
      FOR v_w IN 0..51 LOOP
        v_debut := public.instant_creneau(v_c.weekday, v_c.hour_local, v_c.timezone_iana, v_w);
        FOR v_aw IN greatest(0, v_w - 1)..least(52, v_w + 1) LOOP
          v_busy_debut := public.instant_creneau(
            v_busy.weekday, v_busy.hour_local, v_busy.timezone_iana, v_aw
          );
          IF v_debut < v_busy_debut + pg_catalog.make_interval(mins => v_busy.duree)
             AND v_busy_debut < v_debut + pg_catalog.make_interval(mins => v_duree) THEN
            RAISE EXCEPTION 'chevauchement avec une classe ou affectation active';
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;

  IF EXISTS (
    SELECT 1
    FROM public.sessions s
    CROSS JOIN LATERAL pg_catalog.generate_series(0, 51) AS w(n)
    CROSS JOIN LATERAL (
      SELECT public.instant_creneau(v_g.weekday, v_g.hour_local, v_g.timezone_iana, w.n) AS starts_at
      UNION
      SELECT public.instant_creneau(gc.weekday, gc.hour_local, v_g.timezone_iana, w.n)
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    ) target
    WHERE s.teacher_id = p_teacher_id
      AND s.groupe_id IS NULL
      AND s.deleted_at IS NULL
      AND s.status NOT IN ('canceled')
      AND target.starts_at < s.ended_at
      AND s.started_at < target.starts_at + pg_catalog.make_interval(mins => v_duree)
  ) THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante';
  END IF;
END;
$function$;

ALTER FUNCTION app_private.verifier_affectation_enseignant_base(uuid, uuid, boolean)
  OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.verifier_affectation_enseignant_base(uuid, uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION app_private.verifier_affectation_enseignant_base(uuid, uuid, boolean) IS
  'CAND-Q15 : predicat C-04/C-07 de 0082 (compte, piece validee, acces, langue, genre, plafond horaire, disponibilites si exigees, collisions, verrou par enseignant). p_exiger_disponibilites : couverture par weekly_availability exigee si true ou NULL ; false pour creer_groupe (D4). CLASSES-DUREE : la seance dure ce que dure SA Classe (app_private.duree_seance_minutes : son offre, sinon le reglage de son public, 90 minutes pour les adultes) ; la couverture exige chaque heure entiere touchee (union des lignes de weekly_availability, en instants) ; plafond horaire et collisions comptent la duree propre a chaque Classe. INVOKER, aucun EXECUTE client.';

-- ------------------------------------------------------------------
-- 3. Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_base regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)');
  v_envel regprocedure := pg_catalog.to_regprocedure(
    'app_private.verifier_affectation_enseignant(uuid,uuid,boolean)');
  v_fonctions regprocedure[] := ARRAY[
    pg_catalog.to_regprocedure('app_private.duree_seance_minutes(uuid,text)'),
    pg_catalog.to_regprocedure('app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'),
    pg_catalog.to_regprocedure('app_private.verifier_affectation_enseignant(uuid,uuid,boolean)')];
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
BEGIN
  -- Les trois fonctions existent, appartiennent a postgres, fixent un
  -- search_path vide, sont INVOKER et ne sont executables par personne.
  FOREACH v_f IN ARRAY v_fonctions LOOP
    IF v_f IS NULL THEN
      RAISE EXCEPTION 'CLASSES-DUREE : fonction absente';
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF v_p.prosecdef
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'CLASSES-DUREE : % doit etre INVOKER, a postgres, search_path vide', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-DUREE : % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;

  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_base::oid;
  -- Ce que CAND-Q15 et CLASSES-PLAFOND exigent encore de la base : les refus
  -- nommes, le verrou par enseignant, et pas de plafond de Classes dedans.
  IF pg_catalog.strpos(v_p.prosrc, 'plafond_classes') <> 0
     OR pg_catalog.strpos(v_p.prosrc, 'enseignant non disponible: jour') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'plafond horaire enseignant dépassé') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'chevauchement avec une classe ou affectation active') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'chevauchement avec une séance existante') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'enseignant indisponible ou genre inconnu') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'enseignant incompatible avec le public de la classe') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'pg_advisory_xact_lock') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'teacher-schedule:') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la base du predicat a perdu un refus nomme ou le verrou par enseignant';
  END IF;
  -- Le verrou est pris avant tout compte et toute duree.
  IF pg_catalog.strpos(v_p.prosrc, 'pg_advisory_xact_lock')
       > pg_catalog.strpos(v_p.prosrc, 'duree_seance_minutes(v_g.offre_id, v_g.type_public)') THEN
    RAISE EXCEPTION 'CLASSES-DUREE : le verrou par enseignant doit etre pris avant la duree et la charge';
  END IF;
  -- La duree est celle de la Classe, plus le reglage unique ; chaque Classe
  -- occupe sa propre duree dans la charge et les collisions.
  IF pg_catalog.strpos(v_p.prosrc, 'v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public)') = 0
     OR (pg_catalog.length(v_p.prosrc)
         - pg_catalog.length(pg_catalog.replace(v_p.prosrc, 'app_private.duree_seance_minutes(g.offre_id, g.type_public)', ''))
        ) / pg_catalog.length('app_private.duree_seance_minutes(g.offre_id, g.type_public)') <> 2
     OR pg_catalog.strpos(v_p.prosrc, 'make_interval(mins => v_busy.duree)') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'v_duree_individuelle') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la duree de la Classe n''est plus lue a la Classe (ou plus par creneau)';
  END IF;
  -- L'ancien test de couverture (une seule ligne d'une heure contient toute la
  -- seance) ne revient pas : la couverture est une union.
  IF pg_catalog.strpos(v_p.prosrc, 'v_busy_debut + interval ''1 hour'' >= v_debut') <> 0
     OR pg_catalog.strpos(v_p.prosrc, 'v_trouve') <> 0
     OR pg_catalog.strpos(v_p.prosrc, 'unnest(v_plages_debut), pg_catalog.unnest(v_plages_fin)') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'p.debut <= v_debut AND p.fin >= v_fin') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la couverture par disponibilites n''est plus une union de lignes';
  END IF;
  -- Les lignes declarees sont prises de la semaine -1 a la semaine 52 : la
  -- derniere occurrence deja commencee d'une ligne peut couvrir le debut de la
  -- prochaine seance (grille decalee d'une demi-heure).
  IF pg_catalog.strpos(v_p.prosrc, 'pg_catalog.generate_series(-1, 52) AS w(n)') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : les lignes declarees doivent couvrir les semaines -1 a 52';
  END IF;

  -- L'enveloppe n'a pas bouge : la base d'abord, le plafond de Classes ensuite.
  SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_envel::oid;
  IF pg_catalog.strpos(v_p.prosrc, 'app_private.verifier_affectation_enseignant_base(') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'app_private.verifier_plafond_classes_enseignant(p_teacher_id, p_groupe_id)') = 0
     OR pg_catalog.strpos(v_p.prosrc, 'verifier_plafond_classes_enseignant')
        < pg_catalog.strpos(v_p.prosrc, 'verifier_affectation_enseignant_base') THEN
    RAISE EXCEPTION 'CLASSES-DUREE : l''enveloppe du predicat doit appeler la base puis le plafond de Classes';
  END IF;
END;
$postflight$;

COMMIT;
