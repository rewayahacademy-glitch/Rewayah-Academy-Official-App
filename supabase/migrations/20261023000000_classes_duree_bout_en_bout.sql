-- CLASSES-DUREE, SUITE (23/10/2026) : la duree d'une Classe (90 minutes pour
-- les adultes, 60 pour les enfants) tient de bout en bout. Ferme les trois
-- defauts laisses ouverts par 20261022000400 (CANDIDATURES/
-- SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md, 2.1 bis, « Reste ouvert, hors de
-- ce lot »). Demande du directeur : « il faut en finir ».
--
-- Les choix ci-dessous sont des CHOIX PAR DEFAUT DU 23/10, A CONFIRMER PAR LE
-- DIRECTEUR ; chacun est reversible (une ligne), et ecrit dans la specification.
--
-- ==========================================================================
-- (A) La duree des seances materialisees
-- ==========================================================================
-- Defaut : materialiser_seances_groupe (0055:44, derniere definition ; les
-- autres lignes de 0033 sont anterieures) fixait la fin de chaque seance par le
-- reglage session_duration_minutes (60) pour TOUTES les Classes : le calendrier
-- reel d'une Classe d'adultes durait 60 minutes alors que l'affectation la
-- comparait deja a 90. Ce que cela cassait (lu dans les definitions de la base du
-- rejeu) :
--   * ses_cloturer_seances_echues fermait la seance a 60 minutes + marge, en
--     plein cours ;
--   * autoriser_jeton_video, entrer_observation et rejoindre_observation
--     refusaient « salle fermee » a partir de la 76e minute (fin + 15 minutes de
--     grace) d'un cours qui en dure 90 ;
--   * mes_rapports_en_attente reclamait le rapport 30 minutes trop tot ;
--   * private.pai_due_seance payait 60 minutes (voir plus bas : l'argent).
-- Correction :
--   1. materialiser_seances_groupe prend la duree de la Classe,
--      app_private.duree_seance_minutes(offre, public) : la meme fonction que le
--      predicat d'affectation. Le reste du corps est celui de 0055.
--   2. Les seances A VENIR NON COMMENCEES (statut planned, debut > maintenant,
--      non supprimees) d'une Classe non close prennent la duree de leur Classe,
--      une fois, par app_private.aligner_seances_a_venir_sur_la_classe().
--      Les seances passees, commencees (preflight, in_progress) ou closes ne
--      changent JAMAIS. Avant de rallonger, la fonction cherche les
--      chevauchements que le rallongement creerait : une autre seance du meme
--      enseignant (contrainte sessions_no_teacher_overlap), de l'enseignant
--      effectif (un remplacant designe), ou d'un meme participant
--      (guard_session_overlap), en comptant la NOUVELLE fin des seances qui
--      changent aussi. S'il y en a, la migration S'ARRETE (garde positive,
--      aucune omission silencieuse) avec le nombre et les identifiants.
--   3. Choix par defaut : materialiser_seances_groupe ne reecrit PAS les
--      seances deja materialisees d'une Classe quand elle tourne (elle tourne
--      a chaque adhesion : un rallongement qui chevauche y ferait echouer
--      l'adhesion). Un changement ulterieur du reglage seance.duree_minutes_*
--      touche donc les seances creees apres ; pour les autres, la direction
--      rejoue app_private.aligner_seances_a_venir_sur_la_classe().
--   Le calcul de la paie n'est PAS modifie (voir 2.1 bis : sa base est la
--   duree de la seance, qui change ici).
--
-- ==========================================================================
-- (B) Changer l'horaire d'une Classe qui a son enseignant
-- ==========================================================================
-- Defaut : modifier_groupe (7 arguments, SECURITY DEFINER, garde direction)
-- change weekday, hour_local, timezone_iana sans repasser par le predicat ; la
-- direction ecrit aussi groupe_creneaux directement (policy
-- groupe_creneaux_admin ; le client n'y ecrit jamais, il appelle la RPC :
-- lib/core/admin/service_groupes.dart). Seule la contrainte d'exclusion retenait
-- un deplacement, et pas celui d'une Classe de 90 minutes.
-- Correction, au niveau des TABLES (donc pour toute ecriture, pas seulement la
-- RPC ; aucune policy retiree, aucune signature changee) :
--   * groupes_horaire_verifie_enseignant : apres un changement de jour,
--     d'heure ou de fuseau d'une Classe active, non close, qui a son
--     enseignant, on repasse le predicat d'affectation avec le nouvel horaire ;
--   * groupe_creneaux_verifie_enseignant : meme controle quand un creneau est
--     insere ou modifie pour une telle Classe (ecriture directe de la
--     direction) ; quand le creneau est ecrit par un autre declencheur (le
--     creneau d'ancrage de groupes, deja couvert par le precedent), il n'est
--     pas rejoue.
--   Le predicat est app_private.verifier_affectation_enseignant_base (compte,
--   piece, acces, langue, genre, plafond horaire, couverture par les
--   disponibilites, collisions de classes, d'affectations et de seances
--   ponctuelles, verrou par enseignant). La Classe est ecartee de ses propres
--   collisions : il les compte deja (g.id <> p_groupe_id). Un refus arrete
--   l'ecriture avec les MEMES messages et le meme SQLSTATE (P0001) que
--   l'affectation : aucun code nouveau ; le client les met en mots.
--   Les declencheurs sont des AFTER (et non des BEFORE) : le predicat lit les
--   tables, la ligne doit y etre ; le refus annule l'ecriture de la meme
--   facon. Le declencheur de groupes porte un nom qui se range APRES
--   groupes_creneau_ancre (le creneau d'ancrage est deja deplace) et AVANT
--   tc_materialiser_apres_creation_groupe : un deplacement refuse ne
--   materialise aucune seance.
--   Choix par defaut :
--     - couverture par les disponibilites EXIGEE (comme affecter_enseignant_
--       classe_c11bis ; creer_groupe, lui, ne l'exige pas, D4) ;
--     - le maximum de Classes par enseignant (plafond_classes_atteint) n'est
--       PAS rejoue : un deplacement n'ajoute aucune Classe, et un enseignant
--       passe au-dessus du maximum par un abaissement du reglage ne doit pas
--       etre bloque pour en deplacer une qu'il tient deja. Pour l'ajouter :
--       appeler app_private.verifier_affectation_enseignant au lieu de _base ;
--     - une Classe SANS enseignant se deplace comme avant.
--   Ce que le deplacement fait aux seances a venir : RIEN de plus qu'avant. Le
--   declencheur de materialisation cree les seances du nouvel horaire ; celles
--   de l'ancien horaire restent planifiees. Non invente ici (voir 2.1 bis).
--
--   Relecture du 23/10 : le refus de chevauchement compte aussi les seances deja
--   materialisees de l'enseignant dans les AUTRES Classes (celles qu'un premier
--   deplacement laisse), un verrou BEFORE ordonne les verrous (40P01), un
--   declencheur de app_config refuse une duree hors de 15 a 240 minutes (sinon
--   chaque adhesion a une Classe echoue), l'alignement ne rejoue plus une
--   fonction chere sur chaque seance (quadratique), son message dit la Classe et
--   le debut et son indice distingue la migration de la fonction lancee a la main.
--   Laisse a decision du directeur (spec 2.1 bis, « Reste ouvert ») : annuler les
--   seances de l'ancien horaire au deplacement ; plafond d'heures rejoue (choix
--   par defaut : oui, comme a l'affectation).
--
-- ==========================================================================
-- (C) Les creneaux libres comptent la duree de la Classe
-- ==========================================================================
-- Defaut : enseignants_pour_classe et enseignants_pour_public comptaient
-- session_duration_minutes (60) pour la Classe et pour chaque creneau deja pris.
-- Correction : un creneau libre H d'un enseignant est une heure declaree telle
-- que [H, H + duree de la Classe) est COUVERT par ses heures declarees
-- consecutives (H et H + 1 pour 90 minutes ; passage minuit et dimanche
-- compris) ET ne chevauche ni ses Classes (chacune avec sa propre duree), ni
-- ses affectations individuelles, ni ses seances ponctuelles. La duree est celle
-- de la Classe (enseignants_pour_classe) ou celle du public demande
-- (enseignants_pour_public). Pour 60 minutes, rien ne change.
-- free_teacher_slots n'existe plus (aucune definition dans le depot depuis
-- 0083) : rien a faire.
--
-- ==========================================================================
-- Autres lecteurs de la duree d'une seance (inventaire, 2.1 bis)
-- ==========================================================================
-- Corrige ici, car local et sur : public.transferer_eleve lisait le REGLAGE du
-- public de la Classe cible pour comparer les seances de l'eleve ; il lit
-- maintenant la duree de la Classe cible (offre, sinon public). Rien d'autre :
-- tous les autres lecteurs lisent la fin de la seance (sessions.ended_at) et
-- deviennent justes avec les donnees corrigees.
--
-- Droits (F86) : les fonctions nouvelles sont de app_private, sans EXECUTE pour
-- aucun role ; les declencheurs sont SECURITY DEFINER (le predicat n'est
-- executable par aucun role connecte), search_path vide. Les quatre fonctions de
-- public touchees gardent signature et droits, restent DEFINER a search_path
-- vide, et portent une empreinte md5_functiondef verifiee au controle final.
BEGIN;

-- ------------------------------------------------------------------
-- 1. Aides : recouvrement de deux creneaux de durees differentes,
--    couverture par les heures declarees
-- ------------------------------------------------------------------
-- Comme app_private.creneaux_recurrents_se_chevauchent (0083), mais chaque
-- creneau a SA duree : une Classe d'adultes de 90 minutes peut toucher une
-- Classe d'enfants de 60 minutes sans que les deux durees soient egales.
CREATE FUNCTION app_private.creneaux_recurrents_se_chevauchent_durees(
  p_jour_a integer, p_heure_a integer, p_tz_a text, p_duree_a integer,
  p_jour_b integer, p_heure_b integer, p_tz_b text, p_duree_b integer
) RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.generate_series(0, 51) AS semaine_a(n)
    CROSS JOIN LATERAL pg_catalog.generate_series(
      greatest(0, semaine_a.n - 1), least(51, semaine_a.n + 1)
    ) AS semaine_b(n)
    WHERE public.instant_creneau(
            p_jour_a, p_heure_a, p_tz_a, semaine_a.n
          ) < public.instant_creneau(
            p_jour_b, p_heure_b, p_tz_b, semaine_b.n
          ) + pg_catalog.make_interval(mins => p_duree_b)
      AND public.instant_creneau(
            p_jour_b, p_heure_b, p_tz_b, semaine_b.n
          ) < public.instant_creneau(
            p_jour_a, p_heure_a, p_tz_a, semaine_a.n
          ) + pg_catalog.make_interval(mins => p_duree_a)
  );
$function$;

-- Le creneau (jour, heure, fuseau) de p_duree_minutes est-il couvert par les
-- heures DECLAREES de la personne ? Une ligne de weekly_availability est une
-- heure entiere ; un creneau de 90 minutes qui commence a H touche H et H + 1,
-- un creneau de 60 minutes la seule heure H. Les heures suivent le jour (passage
-- minuit : le jour d'apres, heure 0 ; dimanche soir : lundi) dans le MEME
-- fuseau que la ligne de depart : une personne n'a qu'un fuseau de grille
-- (2.1 bis). Garde positive : un argument absent ou hors plage ne couvre rien.
CREATE FUNCTION app_private.creneau_couvert_par_disponibilites(
  p_profile_id uuid, p_jour integer, p_heure integer, p_tz text, p_duree_minutes integer
) RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(
           p_profile_id IS NOT NULL
           AND p_jour BETWEEN 1 AND 7
           AND p_heure BETWEEN 0 AND 23
           AND p_tz IS NOT NULL
           AND p_duree_minutes BETWEEN 1 AND 1440
           AND NOT EXISTS (
             SELECT 1
             FROM pg_catalog.generate_series(0, ((p_duree_minutes + 59) / 60) - 1) AS k(n)
             WHERE NOT EXISTS (
               SELECT 1
               FROM public.weekly_availability w
               WHERE w.profile_id = p_profile_id
                 AND w.timezone_iana = p_tz
                 AND w.weekday = ((p_jour - 1 + (p_heure + k.n) / 24) % 7) + 1
                 AND w.hour_local = (p_heure + k.n) % 24
             )
           ),
           false);
$function$;

-- ------------------------------------------------------------------
-- 2. (A) Les seances a venir d'une Classe prennent la duree de la Classe
-- ------------------------------------------------------------------
-- Les seances A VENIR NON COMMENCEES dont la fin differe de debut + duree de la
-- Classe : planned, debut > maintenant, non supprimees, Classe non close.
CREATE FUNCTION app_private.seances_a_venir_a_realigner(p_groupe_id uuid DEFAULT NULL)
RETURNS TABLE(
  seance_id uuid, classe_id uuid, enseignant_id uuid,
  debut timestamptz, fin_actuelle timestamptz, fin_nouvelle timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT s.id, g.id, s.teacher_id, s.started_at, s.ended_at,
         s.started_at + pg_catalog.make_interval(mins => d.minutes)
  FROM public.sessions s
  JOIN public.groupes g ON g.id = s.groupe_id
  CROSS JOIN LATERAL (
    SELECT app_private.duree_seance_minutes(g.offre_id, g.type_public) AS minutes
  ) d
  WHERE s.deleted_at IS NULL
    AND s.status = 'planned'
    AND s.started_at > pg_catalog.now()
    AND g.ended_at IS NULL
    AND (p_groupe_id IS NULL OR g.id = p_groupe_id)
    AND s.ended_at <> s.started_at + pg_catalog.make_interval(mins => d.minutes);
$function$;

-- Aligne ces seances. S'ARRETE, sans rien ecrire, si un rallongement chevauche
-- une autre seance du meme enseignant, de l'enseignant effectif ou d'un meme
-- participant ; le message donne le nombre et les identifiants. Rend le nombre
-- de seances ecrites. Les raccourcissements passent d'abord (ils ne peuvent
-- rien chevaucher) ; les seances closes, commencees ou passees ne sont jamais
-- touchees.
CREATE FUNCTION app_private.aligner_seances_a_venir_sur_la_classe(p_groupe_id uuid DEFAULT NULL)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_conflits integer;
  v_liste text;
  v_raccourcies integer;
  v_rallongees integer;
BEGIN
  WITH r AS MATERIALIZED (
    SELECT * FROM app_private.seances_a_venir_a_realigner(p_groupe_id)
  ),
  paires AS (
    SELECT c.seance_id, c.classe_id, c.debut, o.id AS autre_id
    FROM r c
    JOIN public.sessions o
      ON o.id <> c.seance_id
     AND o.deleted_at IS NULL
     AND o.status IN ('planned', 'preflight', 'in_progress')
     AND o.started_at < c.fin_nouvelle
    LEFT JOIN r ro ON ro.seance_id = o.id
    WHERE c.fin_nouvelle > c.fin_actuelle
      -- Filtres bon marche, evalues AVANT l'appel de c29_enseignant_effectif_session
      -- (cher, quadratique sinon) : l'autre seance, avec sa nouvelle fin si elle
      -- change aussi, doit chevaucher celle-ci.
      AND coalesce(ro.fin_nouvelle, o.ended_at) > c.debut
      AND pg_catalog.tstzrange(o.started_at, coalesce(ro.fin_nouvelle, o.ended_at), '[)')
          && pg_catalog.tstzrange(c.debut, c.fin_nouvelle, '[)')
      AND (
        -- l'enseignant de la seance : la contrainte sessions_no_teacher_overlap
        o.teacher_id = c.enseignant_id
        -- l'enseignant effectif (un remplacant designe pour l'une ou l'autre)
        OR private.c29_enseignant_effectif_session(o.id)
           = private.c29_enseignant_effectif_session(c.seance_id)
        -- un meme participant : guard_session_overlap
        OR EXISTS (
          SELECT 1
          FROM public.session_participants a
          JOIN public.session_participants b ON b.profile_id = a.profile_id
          WHERE a.session_id = c.seance_id AND b.session_id = o.id
            AND a.deleted_at IS NULL AND b.deleted_at IS NULL
            AND a.role IN ('teacher', 'student') AND b.role IN ('teacher', 'student')
        )
      )
  )
  SELECT (SELECT pg_catalog.count(DISTINCT q.seance_id)::integer FROM paires q),
         (SELECT pg_catalog.string_agg(
                   p.seance_id::text || ' (Classe ' || p.classe_id::text || ', debut '
                   || pg_catalog.to_char(p.debut AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI') || ' UTC) chevauche '
                   || p.autre_id::text,
                   ', ' ORDER BY p.seance_id, p.autre_id)
            FROM (SELECT * FROM paires ORDER BY seance_id, autre_id LIMIT 20) p)
  INTO v_conflits, v_liste;

  -- Garde positive : aucune seance en conflit, sinon on s'arrete.
  IF NOT coalesce(v_conflits = 0, false) THEN
    RAISE EXCEPTION 'CLASSES-DUREE : % seance(s) a venir ne peuvent pas prendre la duree de leur Classe sans en chevaucher une autre (20 premieres paires) : %',
      v_conflits, v_liste
      USING HINT = 'Deplacer ou annuler l''une des deux seances, puis rejouer la migration (si c''est elle qui s''est arretee : elle a tout annule, ces fonctions n''existent pas encore) ou app_private.aligner_seances_a_venir_sur_la_classe() (si elle a ete lancee a la main).';
  END IF;

  UPDATE public.sessions s
     SET ended_at = r.fin_nouvelle, updated_at = pg_catalog.now()
    FROM app_private.seances_a_venir_a_realigner(p_groupe_id) r
   WHERE s.id = r.seance_id AND r.fin_nouvelle < r.fin_actuelle;
  GET DIAGNOSTICS v_raccourcies = ROW_COUNT;

  UPDATE public.sessions s
     SET ended_at = r.fin_nouvelle, updated_at = pg_catalog.now()
    FROM app_private.seances_a_venir_a_realigner(p_groupe_id) r
   WHERE s.id = r.seance_id AND r.fin_nouvelle > r.fin_actuelle;
  GET DIAGNOSTICS v_rallongees = ROW_COUNT;

  RETURN v_raccourcies + v_rallongees;
END;
$function$;

-- Les seances materialisees prennent la duree de la Classe. Corps de 0055:44,
-- a une ligne pres (v_duree).
CREATE OR REPLACE FUNCTION public.materialiser_seances_groupe(p_groupe_id uuid)
RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_creneau public.groupe_creneaux%ROWTYPE;
  v_semaines integer;
  v_duree integer;
  v_fenetre integer;
  v_debut timestamptz;
  v_session uuid;
  v_n integer := 0;
BEGIN
  SELECT * INTO v_g
  FROM public.groupes
  WHERE id = p_groupe_id AND ended_at IS NULL
  FOR UPDATE;
  IF NOT FOUND OR v_g.teacher_id IS NULL OR v_g.etat <> 'active' THEN
    RETURN 0;
  END IF;

  v_semaines := public.app_config_int('matching_horizon_weeks', 4);
  -- CLASSES-DUREE (23/10) : la duree de CETTE Classe (son offre, sinon le
  -- reglage de son public), la meme que celle du predicat d'affectation.
  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_fenetre := public.app_config_int('join_window_minutes', 20);

  FOR v_creneau IN
    SELECT gc.* FROM public.groupe_creneaux gc
    WHERE gc.groupe_id = p_groupe_id
    ORDER BY gc.weekday, gc.hour_local
  LOOP
    FOR i IN 0 .. v_semaines - 1 LOOP
      v_debut := public.instant_creneau(
        v_creneau.weekday, v_creneau.hour_local, v_g.timezone_iana, i
      );
      SELECT s.id INTO v_session
      FROM public.sessions s
      WHERE s.groupe_id = p_groupe_id
        AND s.started_at = v_debut
        AND s.deleted_at IS NULL;

      IF v_session IS NOT NULL THEN
        IF v_debut > now() THEN
          INSERT INTO public.session_participants (session_id, profile_id, role)
          SELECT v_session, m.student_id, 'student'
          FROM public.groupe_membres m
          WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL
          ON CONFLICT (session_id, profile_id) DO NOTHING;
        END IF;
        CONTINUE;
      END IF;

      INSERT INTO public.sessions
        (teacher_id, started_at, ended_at, session_type, groupe_id, join_opens_at)
      VALUES
        (v_g.teacher_id, v_debut,
         v_debut + make_interval(mins => v_duree),
         CASE v_g.type_public WHEN 'enfant' THEN 'child' ELSE 'standard' END,
         p_groupe_id, v_debut - make_interval(mins => v_fenetre))
      RETURNING id INTO v_session;

      INSERT INTO public.session_participants (session_id, profile_id, role)
      SELECT v_session, m.student_id, 'student'
      FROM public.groupe_membres m
      WHERE m.groupe_id = p_groupe_id AND m.left_at IS NULL;

      v_n := v_n + 1;
    END LOOP;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- ------------------------------------------------------------------
-- 3. (B) Le predicat d'affectation repasse quand l'horaire d'une Classe
--    qui a son enseignant change
-- ------------------------------------------------------------------
-- Ce que le predicat ne voit pas : il ne lit que les horaires RECURRENTS, et il
-- ecarte la Classe de ses propres collisions. Deux refus de plus, avec le message
-- existant « chevauchement avec une séance existante » (aucun code nouveau) :
--   1. deux creneaux de la Classe se chevauchent (mercredi 18 h et 19 h, pour un
--      cours de 90 minutes) : la materialisation heurterait la contrainte
--      sessions_no_teacher_overlap sur sa propre seance (SQLSTATE 23P01) ;
--   2. un creneau, au nouvel horaire, chevauche une seance A VENIR deja
--      materialisee de l'enseignant (titulaire ou remplacant designe), de cette
--      Classe a un autre instant OU D'UNE AUTRE CLASSE. C'est le cas d'un
--      deplacement : les seances de l'ancien horaire restent planifiees (le
--      deplacement ne les suit pas), et celles d'une Classe deplacee plus tot
--      occupent encore l'ancien creneau ; un adulte deplace de moins de 90
--      minutes se chevaucherait lui-meme. Le refus remplace une erreur technique
--      de la contrainte (23P01), qui se revelait a la materialisation ou, pour un
--      creneau ecrit directement, plus tard a l'inscription d'un eleve.
CREATE FUNCTION app_private.verifier_horaire_contre_seances_planifiees(p_groupe_id uuid)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_duree integer;
  v_propre boolean;
  v_semaines integer := public.app_config_int('matching_horizon_weeks', 4);
BEGIN
  SELECT g.* INTO v_g FROM public.groupes g WHERE g.id = p_groupe_id;
  IF NOT coalesce(FOUND, false) THEN
    RETURN;
  END IF;
  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);

  IF EXISTS (
    WITH c AS (
      SELECT v_g.weekday::integer AS jour, v_g.hour_local::integer AS heure
      UNION
      SELECT gc.weekday::integer, gc.hour_local::integer
        FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
    )
    SELECT 1
    FROM c a
    JOIN c b ON (a.jour, a.heure) < (b.jour, b.heure)
    WHERE app_private.creneaux_recurrents_se_chevauchent_durees(
            a.jour, a.heure, v_g.timezone_iana, v_duree,
            b.jour, b.heure, v_g.timezone_iana, v_duree)
  ) THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante'
      USING DETAIL = 'deux creneaux de cette Classe se chevauchent';
  END IF;

  -- Un creneau, au nouvel horaire, contre les seances DEJA MATERIALISEES de
  -- l'enseignant (titulaire ou remplacant designe), de cette Classe a un autre
  -- instant comme de n'importe quelle AUTRE Classe : un deplacement laisse les
  -- seances de l'ancien horaire planifiees (elles restent la, comme avant), et
  -- le predicat ne voit que les horaires recurrents. Sans ce controle, le
  -- chevauchement ne se revele qu'a la materialisation, en erreur technique de
  -- sessions_no_teacher_overlap (23P01), ou plus tard a l'inscription d'un eleve.
  -- Meme message, DETAIL different.
  WITH c AS (
    SELECT v_g.weekday::integer AS jour, v_g.hour_local::integer AS heure
    UNION
    SELECT gc.weekday::integer, gc.hour_local::integer
      FROM public.groupe_creneaux gc WHERE gc.groupe_id = p_groupe_id
  )
  SELECT s.groupe_id IS NOT DISTINCT FROM p_groupe_id INTO v_propre
  FROM c
  CROSS JOIN LATERAL pg_catalog.generate_series(0, v_semaines - 1) AS w(n)
  CROSS JOIN LATERAL (
    SELECT public.instant_creneau(c.jour, c.heure, v_g.timezone_iana, w.n) AS debut
  ) d
  JOIN public.sessions s
    ON s.deleted_at IS NULL
   AND s.status IN ('planned', 'preflight', 'in_progress')
   AND s.started_at < d.debut + pg_catalog.make_interval(mins => v_duree)
   AND s.ended_at > d.debut
   AND NOT (s.groupe_id IS NOT DISTINCT FROM p_groupe_id AND s.started_at = d.debut)
   AND (s.teacher_id = v_g.teacher_id
        OR private.c29_enseignant_effectif_session(s.id) = v_g.teacher_id)
  ORDER BY (s.groupe_id IS NOT DISTINCT FROM p_groupe_id) DESC
  LIMIT 1;
  IF FOUND THEN
    RAISE EXCEPTION 'chevauchement avec une séance existante'
      USING DETAIL = CASE WHEN v_propre
        THEN 'ce creneau chevauche une seance a venir de cette Classe a un autre horaire'
        ELSE 'ce creneau chevauche une seance a venir de cet enseignant dans une autre Classe ou hors Classe' END;
  END IF;
END;
$function$;

CREATE FUNCTION app_private.verifier_horaire_classe_avec_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  -- Seule une Classe active, non close, qui a son enseignant est controlee : une
  -- Classe en attente se deplace comme avant (elle n'a personne a verifier).
  IF NOT coalesce(NEW.teacher_id IS NOT NULL AND NEW.etat = 'active' AND NEW.ended_at IS NULL, false) THEN
    RETURN NULL;
  END IF;
  -- Le predicat lit les tables : l'horaire nouveau y est deja. Il ecarte la
  -- Classe de ses propres collisions ; un refus (P0001, memes messages que
  -- l'affectation) annule l'ecriture, avant la materialisation des seances.
  PERFORM app_private.verifier_affectation_enseignant_base(NEW.id, NEW.teacher_id, true);
  PERFORM app_private.verifier_horaire_contre_seances_planifiees(NEW.id);
  RETURN NULL;
END;
$function$;

CREATE FUNCTION app_private.verifier_creneau_classe_avec_enseignant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
BEGIN
  SELECT g.* INTO v_g FROM public.groupes g WHERE g.id = NEW.groupe_id;
  IF NOT coalesce(FOUND AND v_g.teacher_id IS NOT NULL AND v_g.etat = 'active' AND v_g.ended_at IS NULL, false) THEN
    RETURN NULL;
  END IF;
  -- Le creneau d'ancrage (celui de groupes.weekday / hour_local, que
  -- groupes_creneau_ancre ecrit avec la Classe) est deja couvert par
  -- groupes_horaire_verifie_enseignant : on ne le rejoue pas. Le critere est la
  -- LIGNE (l'ancre de la Classe), et non la profondeur d'appel : un creneau
  -- ecrit depuis un autre declencheur, qui n'est pas l'ancre, est controle.
  IF NEW.weekday = v_g.weekday AND NEW.hour_local = v_g.hour_local THEN
    RETURN NULL;
  END IF;
  PERFORM app_private.verifier_affectation_enseignant_base(NEW.groupe_id, v_g.teacher_id, true);
  PERFORM app_private.verifier_horaire_contre_seances_planifiees(NEW.groupe_id);
  RETURN NULL;
END;
$function$;

-- Le nom se range apres groupes_creneau_ancre et avant
-- tc_materialiser_apres_creation_groupe (les declencheurs de meme evenement
-- tirent par ordre alphabetique) : verifie par le controle final.
CREATE TRIGGER groupes_horaire_verifie_enseignant
  AFTER UPDATE OF weekday, hour_local, timezone_iana ON public.groupes
  FOR EACH ROW
  WHEN (OLD.weekday IS DISTINCT FROM NEW.weekday
        OR OLD.hour_local IS DISTINCT FROM NEW.hour_local
        OR OLD.timezone_iana IS DISTINCT FROM NEW.timezone_iana)
  EXECUTE FUNCTION app_private.verifier_horaire_classe_avec_enseignant();

CREATE TRIGGER groupe_creneaux_verifie_enseignant
  AFTER INSERT OR UPDATE OF groupe_id, weekday, hour_local ON public.groupe_creneaux
  FOR EACH ROW
  EXECUTE FUNCTION app_private.verifier_creneau_classe_avec_enseignant();

-- Interblocage (40P01) : le controle de cle etrangere d'un creneau prend deja un
-- FOR KEY SHARE sur la ligne de la Classe ; le predicat y prend ensuite FOR UPDATE.
-- Deux ecritures concurrentes sur la meme Classe se tenaient alors chacune le
-- KEY SHARE et attendaient la montee en FOR UPDATE de l'autre. Ce declencheur BEFORE
-- prend FOR UPDATE sur la Classe AVANT le controle de cle etrangere (les controles
-- de cle etrangere sont des declencheurs AFTER) : l'ordre des verrous est toujours
-- la ligne de la Classe, puis le verrou de l'enseignant.
CREATE FUNCTION app_private.verrouiller_classe_du_creneau()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM 1 FROM public.groupes g WHERE g.id = NEW.groupe_id FOR UPDATE;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupe_creneaux_a_verrou_classe
  BEFORE INSERT OR UPDATE OF groupe_id, weekday, hour_local ON public.groupe_creneaux
  FOR EACH ROW
  EXECUTE FUNCTION app_private.verrouiller_classe_du_creneau();

-- Un reglage de duree hors de 15 a 240 minutes (une faute de frappe : 300, 9, 90.5)
-- faisait echouer app_private.duree_seance_minutes, donc CHAQUE adhesion a une
-- Classe (la materialisation s'y declenche). La valeur est refusee a l'ecriture.
-- Comme plafond_classes_valider (20261022000200) : nombre entier, normalise.
CREATE FUNCTION app_private.duree_seance_reglage_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_n numeric;
BEGIN
  IF NEW.key IS DISTINCT FROM 'seance.duree_minutes_adulte'
     AND NEW.key IS DISTINCT FROM 'seance.duree_minutes_enfant' THEN
    RETURN NEW;
  END IF;
  IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number' THEN
    RAISE EXCEPTION 'duree de seance : un nombre entier de minutes, de 15 a 240, est attendu'
      USING ERRCODE = '22023';
  END IF;
  v_n := (NEW.value #>> '{}')::numeric;
  IF NOT coalesce(v_n = pg_catalog.trunc(v_n) AND v_n BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'duree de seance : un nombre entier de minutes, de 15 a 240, est attendu'
      USING ERRCODE = '22023';
  END IF;
  NEW.value := pg_catalog.to_jsonb(v_n::integer);
  RETURN NEW;
END;
$function$;

CREATE TRIGGER app_config_duree_seance
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION app_private.duree_seance_reglage_valider();

-- ------------------------------------------------------------------
-- 4. (C) Les creneaux libres comptent la duree de la Classe
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enseignants_pour_classe(p_classe_id uuid)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, titre_public text, timezone_iana text, classes_actives integer, creneaux_pris jsonb, creneaux_libres jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_teacher record;
  v_pris jsonb;
  v_libres jsonb;
  v_duree integer;
  v_duree_individuelle integer;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(), false
  ) THEN
    RAISE EXCEPTION 'proposition d''enseignants réservée à la direction active';
  END IF;

  SELECT g.* INTO v_g
  FROM public.groupes AS g
  WHERE g.id = p_classe_id
    AND g.etat = 'en_attente_enseignant'
    AND g.teacher_id IS NULL
    AND g.ended_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'classe en attente absente ou indisponible';
  END IF;

  -- CLASSES-DUREE (23/10) : un creneau libre dure ce que dure CETTE Classe
  -- (son offre, sinon le reglage de son public) ; les affectations
  -- individuelles gardent la duree unique d'avant.
  v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_duree_individuelle := public.app_config_int('session_duration_minutes', 60);

  FOR v_teacher IN
    SELECT p.id, p.first_name, p.last_name, p.immutable_id, p.gender,
           tp.country, tp.timezone_iana, tp.weekly_hours_cap
    FROM public.profiles p
    JOIN public.teacher_profiles tp ON tp.profile_id = p.id
    WHERE p.role = 'teacher'
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
      AND p.gender IS NOT NULL
      AND tp.deleted_at IS NULL
      AND tp.kyc_status = 'approved'
      AND (v_g.langue_code IS NULL OR v_g.langue_code = ANY(tp.languages))
      AND (v_g.genre_public = 'indetermine'
           OR (v_g.genre_public = 'hommes' AND p.gender = 'male')
           OR (v_g.genre_public = 'femmes' AND p.gender = 'female'))
  LOOP
    BEGIN
      PERFORM public.tc_verifier_affectation_enseignant(v_g.id, v_teacher.id);
    EXCEPTION WHEN OTHERS THEN
      CONTINUE;
    END;

    SELECT count(*)::integer INTO classes_actives
    FROM public.groupes g
    WHERE g.teacher_id = v_teacher.id
      AND g.ended_at IS NULL AND g.etat = 'active';

    SELECT coalesce(jsonb_agg(jsonb_build_object(
             'weekday', busy.weekday,
             'hour_local', busy.hour_local,
             'timezone_iana', busy.timezone_iana
           ) ORDER BY busy.weekday, busy.hour_local), '[]'::jsonb)
      INTO v_pris
    FROM (
      SELECT DISTINCT slots.weekday, slots.hour_local, g.timezone_iana
      FROM public.groupes g
      CROSS JOIN LATERAL (
        SELECT g.weekday, g.hour_local
        UNION
        SELECT gc.weekday, gc.hour_local
        FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
      ) slots
      WHERE g.teacher_id = v_teacher.id
        AND g.ended_at IS NULL AND g.etat = 'active'
      UNION
      SELECT wa.weekday, wa.hour_local, wa.timezone_iana
      FROM public.teacher_student_assignments tsa
      JOIN public.weekly_availability wa ON wa.profile_id = tsa.student_id
      WHERE tsa.teacher_id = v_teacher.id AND tsa.ended_at IS NULL
    ) busy;

    -- Une heure declaree est libre pour CETTE Classe si [H, H + duree) est
    -- couvert par ses heures declarees consecutives et ne chevauche rien, chaque
    -- creneau deja pris comptant sa propre duree.
    SELECT coalesce(jsonb_agg(jsonb_build_object(
             'weekday', wa.weekday,
             'hour_local', wa.hour_local,
             'timezone_iana', wa.timezone_iana
           ) ORDER BY wa.weekday, wa.hour_local), '[]'::jsonb)
      INTO v_libres
    FROM public.weekly_availability wa
    WHERE wa.profile_id = v_teacher.id
      AND app_private.creneau_couvert_par_disponibilites(
            wa.profile_id, wa.weekday, wa.hour_local, wa.timezone_iana, v_duree)
      AND NOT EXISTS (
        SELECT 1
        FROM public.groupes g
        CROSS JOIN LATERAL (
          SELECT g.weekday, g.hour_local
          UNION
          SELECT gc.weekday, gc.hour_local
          FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
        ) slots
        WHERE g.teacher_id = v_teacher.id
          AND g.ended_at IS NULL AND g.etat = 'active'
          AND app_private.creneaux_recurrents_se_chevauchent_durees(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            slots.weekday, slots.hour_local, g.timezone_iana,
            app_private.duree_seance_minutes(g.offre_id, g.type_public)
          )
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.teacher_student_assignments tsa
        JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
        WHERE tsa.teacher_id = v_teacher.id AND tsa.ended_at IS NULL
          AND app_private.creneaux_recurrents_se_chevauchent_durees(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            busy.weekday, busy.hour_local, busy.timezone_iana, v_duree_individuelle
          )
      )
      AND NOT EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.teacher_id = v_teacher.id
          AND s.groupe_id IS NULL
          AND s.deleted_at IS NULL
          AND s.status NOT IN ('canceled')
          AND app_private.creneau_recurrent_chevauche_session(
            wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
            s.started_at, s.ended_at
          )
      );

    teacher_id := v_teacher.id;
    first_name := v_teacher.first_name;
    last_name := v_teacher.last_name;
    immutable_id := v_teacher.immutable_id;
    country := v_teacher.country;
    titre_public := CASE v_teacher.gender
      WHEN 'female' THEN 'sayyida'
      WHEN 'male' THEN 'sayid'
      ELSE NULL
    END;
    timezone_iana := v_teacher.timezone_iana;
    creneaux_pris := v_pris;
    creneaux_libres := v_libres;
    RETURN NEXT;
  END LOOP;
END;
$function$;

CREATE OR REPLACE FUNCTION public.enseignants_pour_public(p_type_public text)
 RETURNS TABLE(teacher_id uuid, first_name text, last_name text, immutable_id text, country text, titre_public text, timezone_iana text, classes_actives integer, creneaux_pris jsonb, creneaux_libres jsonb)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_duree integer;
  v_duree_individuelle integer;
  v_masque boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'proposition d''enseignants reservee a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type_public IS NULL OR p_type_public NOT IN ('enfant', 'adulte') THEN
    RAISE EXCEPTION 'public invalide' USING ERRCODE = '22023';
  END IF;
  -- CLASSES-DUREE (23/10) : la duree du public demande (aucune offre, aucune
  -- Classe encore) ; les affectations individuelles gardent la duree unique.
  v_duree := app_private.duree_seance_minutes(NULL, p_type_public);
  v_duree_individuelle := public.app_config_int('session_duration_minutes', 60);
  v_masque := coalesce(public.agent_identite_masquee(), false);

  RETURN QUERY
  SELECT p.id,
         CASE WHEN v_masque THEN NULL ELSE p.first_name END,
         CASE WHEN v_masque THEN NULL ELSE p.last_name END,
         p.immutable_id, tp.country,
         CASE p.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayyid' END,
         tp.timezone_iana,
         (SELECT count(*)::integer FROM public.groupes g
           WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', b.weekday, 'hour_local', b.hour_local, 'timezone_iana', b.timezone_iana)
                  ORDER BY b.weekday, b.hour_local, b.timezone_iana)
           FROM (
             SELECT DISTINCT s.weekday, s.hour_local, g.timezone_iana
             FROM public.groupes g
             CROSS JOIN LATERAL (
               SELECT g.weekday, g.hour_local
               UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
             ) s
             WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
           ) b), '[]'::jsonb),
         coalesce((
           SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                    'weekday', wa.weekday, 'hour_local', wa.hour_local, 'timezone_iana', wa.timezone_iana)
                  ORDER BY wa.weekday, wa.hour_local)
           FROM public.weekly_availability wa
           WHERE wa.profile_id = p.id
             AND app_private.creneau_couvert_par_disponibilites(
                   wa.profile_id, wa.weekday, wa.hour_local, wa.timezone_iana, v_duree)
             AND NOT EXISTS (
               SELECT 1 FROM public.groupes g
               CROSS JOIN LATERAL (
                 SELECT g.weekday, g.hour_local
                 UNION SELECT gc.weekday, gc.hour_local FROM public.groupe_creneaux gc WHERE gc.groupe_id = g.id
               ) s
               WHERE g.teacher_id = p.id AND g.ended_at IS NULL AND g.etat = 'active'
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       s.weekday, s.hour_local, g.timezone_iana,
                       app_private.duree_seance_minutes(g.offre_id, g.type_public)))
             AND NOT EXISTS (
               SELECT 1 FROM public.teacher_student_assignments tsa
               JOIN public.weekly_availability busy ON busy.profile_id = tsa.student_id
               WHERE tsa.teacher_id = p.id AND tsa.ended_at IS NULL
                 AND app_private.creneaux_recurrents_se_chevauchent_durees(
                       wa.weekday, wa.hour_local, wa.timezone_iana, v_duree,
                       busy.weekday, busy.hour_local, busy.timezone_iana, v_duree_individuelle))), '[]'::jsonb)
  FROM public.profiles p
  JOIN public.teacher_profiles tp ON tp.profile_id = p.id
  WHERE p.role = 'teacher' AND p.deleted_at IS NULL
    AND p.account_status IN ('active', 'provisional_active')
    AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())
    AND tp.deleted_at IS NULL AND tp.kyc_status = 'approved'
  ORDER BY p.last_name, p.first_name, p.id;
END;
$function$;

-- ------------------------------------------------------------------
-- 5. transferer_eleve lit la duree de la Classe cible
-- ------------------------------------------------------------------
-- Une seule ligne change : le reglage du public (seance.duree_minutes_<public>)
-- devient la duree de la Classe cible (son offre, sinon son public), la meme que
-- celle des seances qu'elle materialise. Le reste du corps est repris tel quel
-- de la definition en base (aucune copie a la main), et la migration verifie que
-- la ligne attendue s'y trouve une seule fois.
DO $transferer$
DECLARE
  v_oid oid := 'public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure::oid;
  v_def text := pg_catalog.pg_get_functiondef(v_oid);
  v_ancien constant text := 'v_duree := public.app_config_int(''seance.duree_minutes_'' || v_cible.type_public, 60);';
  v_nouveau constant text := 'v_duree := app_private.duree_seance_minutes(v_cible.offre_id, v_cible.type_public);';
BEGIN
  IF (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancien, '')))
       / pg_catalog.length(v_ancien) <> 1 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la ligne de duree de transferer_eleve n''est pas celle attendue (ou n''y est pas une seule fois)';
  END IF;
  EXECUTE pg_catalog.replace(v_def, v_ancien, v_nouveau);
END;
$transferer$;

-- ------------------------------------------------------------------
-- 6. Droits, proprietaires, commentaires, empreintes F86
-- ------------------------------------------------------------------
ALTER FUNCTION app_private.creneaux_recurrents_se_chevauchent_durees(integer, integer, text, integer, integer, integer, text, integer) OWNER TO postgres;
ALTER FUNCTION app_private.creneau_couvert_par_disponibilites(uuid, integer, integer, text, integer) OWNER TO postgres;
ALTER FUNCTION app_private.seances_a_venir_a_realigner(uuid) OWNER TO postgres;
ALTER FUNCTION app_private.aligner_seances_a_venir_sur_la_classe(uuid) OWNER TO postgres;
ALTER FUNCTION app_private.verifier_horaire_contre_seances_planifiees(uuid) OWNER TO postgres;
ALTER FUNCTION app_private.verifier_horaire_classe_avec_enseignant() OWNER TO postgres;
ALTER FUNCTION app_private.verifier_creneau_classe_avec_enseignant() OWNER TO postgres;
ALTER FUNCTION app_private.verrouiller_classe_du_creneau() OWNER TO postgres;
ALTER FUNCTION app_private.duree_seance_reglage_valider() OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.creneaux_recurrents_se_chevauchent_durees(integer, integer, text, integer, integer, integer, text, integer),
  app_private.creneau_couvert_par_disponibilites(uuid, integer, integer, text, integer),
  app_private.seances_a_venir_a_realigner(uuid),
  app_private.aligner_seances_a_venir_sur_la_classe(uuid),
  app_private.verifier_horaire_contre_seances_planifiees(uuid),
  app_private.verifier_horaire_classe_avec_enseignant(),
  app_private.verifier_creneau_classe_avec_enseignant(),
  app_private.verrouiller_classe_du_creneau(),
  app_private.duree_seance_reglage_valider()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION app_private.creneaux_recurrents_se_chevauchent_durees(integer, integer, text, integer, integer, integer, text, integer) IS
  'CLASSES-DUREE (23/10) : deux creneaux hebdomadaires se chevauchent-ils, chacun avec SA duree, sur 52 semaines en instants (comme creneaux_recurrents_se_chevauchent, 0083, qui compte une duree unique). INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.creneau_couvert_par_disponibilites(uuid, integer, integer, text, integer) IS
  'CLASSES-DUREE (23/10) : le creneau (jour, heure, fuseau) de p_duree_minutes est-il couvert par les heures declarees consecutives de la personne (H et H + 1 pour 90 minutes, passage minuit et dimanche compris, meme fuseau) ? Garde positive : argument absent ou hors plage = faux. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.seances_a_venir_a_realigner(uuid) IS
  'CLASSES-DUREE (23/10) : les seances a venir non commencees (planned, debut > maintenant, non supprimees, Classe non close) dont la fin differe de debut + duree de leur Classe (app_private.duree_seance_minutes). Jamais une seance passee, commencee ou close. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.aligner_seances_a_venir_sur_la_classe(uuid) IS
  'CLASSES-DUREE (23/10) : aligne ces seances sur la duree de leur Classe (raccourcissements d''abord). S''ARRETE sans rien ecrire, avec le nombre et les identifiants, si un rallongement chevauche une autre seance du meme enseignant, de l''enseignant effectif ou d''un meme participant. Rend le nombre de seances ecrites. Rejouable apres un changement du reglage de duree. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_horaire_contre_seances_planifiees(uuid) IS
  'CLASSES-DUREE (23/10) : la Classe contre elle-meme et contre les seances deja materialisees de son enseignant. Refuse (« chevauchement avec une séance existante ») deux creneaux de la Classe qui se chevauchent, ou un creneau qui chevauche une seance a venir (planned, preflight, in_progress) de l''enseignant, titulaire ou remplacant, dans cette Classe a un autre instant ou dans une autre Classe (les seances de l''ancien horaire restent planifiees apres un deplacement). Remplace l''erreur technique de sessions_no_teacher_overlap (23P01) a la materialisation. INVOKER, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_horaire_classe_avec_enseignant() IS
  'CLASSES-DUREE (23/10) : declencheur de groupes_horaire_verifie_enseignant. Repasse app_private.verifier_affectation_enseignant_base (couverture exigee, la Classe ecartee de ses collisions) quand le jour, l''heure ou le fuseau d''une Classe active qui a son enseignant change. Refus = memes messages que l''affectation. DEFINER, search_path vide, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verifier_creneau_classe_avec_enseignant() IS
  'CLASSES-DUREE (23/10) : declencheur de groupe_creneaux_verifie_enseignant. Meme controle quand un creneau est insere ou modifie pour une Classe active qui a son enseignant (ecriture directe de la direction) ; ne rejoue pas le creneau d''ancrage (celui de groupes.weekday / hour_local), deja couvert par le declencheur de groupes. DEFINER, search_path vide, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.verrouiller_classe_du_creneau() IS
  'CLASSES-DUREE (23/10) : declencheur BEFORE de groupe_creneaux_a_verrou_classe. Prend FOR UPDATE sur la Classe avant le controle de cle etrangere, pour que deux ecritures concurrentes sur la meme Classe ne s''interbloquent pas (40P01) : ordre des verrous = ligne de la Classe, puis verrou de l''enseignant. DEFINER, search_path vide, aucun EXECUTE client.';
COMMENT ON FUNCTION app_private.duree_seance_reglage_valider() IS
  'CLASSES-DUREE (23/10) : declencheur de app_config_duree_seance. Refuse (22023) une valeur de seance.duree_minutes_adulte ou seance.duree_minutes_enfant qui n''est pas un nombre entier de 15 a 240 minutes : au-dela, app_private.duree_seance_minutes leve et chaque adhesion a une Classe echoue. INVOKER (ne lit aucune table), search_path vide, aucun EXECUTE client.';

-- Les quatre fonctions de public touchees : droits restates, empreinte F86.
REVOKE ALL ON FUNCTION public.materialiser_seances_groupe(uuid) FROM PUBLIC, anon, authenticated, agent_ro;
GRANT EXECUTE ON FUNCTION public.materialiser_seances_groupe(uuid) TO service_role;
REVOKE ALL ON FUNCTION public.enseignants_pour_classe(uuid) FROM PUBLIC, anon, agent_ro;
GRANT EXECUTE ON FUNCTION public.enseignants_pour_classe(uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.enseignants_pour_public(text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.enseignants_pour_public(text) TO authenticated;
REVOKE ALL ON FUNCTION public.transferer_eleve(uuid, uuid, uuid, text) FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.transferer_eleve(uuid, uuid, uuid, text) TO authenticated;

DO $droits$
DECLARE
  v_oid regprocedure;
BEGIN
  v_oid := 'public.materialiser_seances_groupe(uuid)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=NO_GUARD_HELPER; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23; justification=Materialise les seances d''une Classe qui a son enseignant ; executable par service_role seulement, appelee par les declencheurs de groupes et de groupe_membres. CLASSES-DUREE : la seance dure ce que dure sa Classe (app_private.duree_seance_minutes).',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));

  v_oid := 'public.enseignants_pour_classe(uuid)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23. C-04: entree classe_id seule; genre/titre, langue, fuseau et toutes occurrences viennent du serveur. CLASSES-DUREE : les creneaux libres comptent la duree de la Classe (couverture par les heures declarees consecutives, collisions avec la duree propre a chaque Classe). Garde: direction active.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));

  v_oid := 'public.enseignants_pour_public(text)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-23. PortEnseignantsClasse.pourClasse. CLASSES-DUREE : les creneaux libres comptent la duree du public demande. Garde: direction active.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));

  v_oid := 'public.transferer_eleve(uuid,uuid,uuid,text)'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; date=2026-10-23. Garde: direction active (R5, R10). CLASSES-DUREE : la comparaison des seances de l''eleve (R5) compte la duree de la Classe cible.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- ------------------------------------------------------------------
-- 7. (A) Aligner les seances a venir existantes, une fois
-- ------------------------------------------------------------------
-- S'arrete (et annule toute la migration) s'il y a un chevauchement.
DO $aligner$
BEGIN
  PERFORM app_private.aligner_seances_a_venir_sur_la_classe();
END;
$aligner$;

-- ------------------------------------------------------------------
-- 8. Controle final
-- ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_interne regprocedure[] := ARRAY[
    pg_catalog.to_regprocedure('app_private.creneaux_recurrents_se_chevauchent_durees(integer,integer,text,integer,integer,integer,text,integer)'),
    pg_catalog.to_regprocedure('app_private.creneau_couvert_par_disponibilites(uuid,integer,integer,text,integer)'),
    pg_catalog.to_regprocedure('app_private.seances_a_venir_a_realigner(uuid)'),
    pg_catalog.to_regprocedure('app_private.aligner_seances_a_venir_sur_la_classe(uuid)'),
    pg_catalog.to_regprocedure('app_private.verifier_horaire_contre_seances_planifiees(uuid)'),
    pg_catalog.to_regprocedure('app_private.verifier_horaire_classe_avec_enseignant()'),
    pg_catalog.to_regprocedure('app_private.verifier_creneau_classe_avec_enseignant()'),
    pg_catalog.to_regprocedure('app_private.verrouiller_classe_du_creneau()'),
    pg_catalog.to_regprocedure('app_private.duree_seance_reglage_valider()')];
  v_publiques regprocedure[] := ARRAY[
    pg_catalog.to_regprocedure('public.materialiser_seances_groupe(uuid)'),
    pg_catalog.to_regprocedure('public.enseignants_pour_classe(uuid)'),
    pg_catalog.to_regprocedure('public.enseignants_pour_public(text)'),
    pg_catalog.to_regprocedure('public.transferer_eleve(uuid,uuid,uuid,text)')];
  v_f regprocedure;
  v_role text;
  v_p pg_catalog.pg_proc%ROWTYPE;
  v_def text;
BEGIN
  -- Les neuf fonctions internes : a postgres, search_path vide, aucun EXECUTE.
  -- Les trois declencheurs de groupes et groupe_creneaux sont DEFINER (le
  -- predicat n'est executable par aucun role connecte, et le verrou doit
  -- passer la RLS) ; les six autres sont INVOKER.
  FOREACH v_f IN ARRAY v_interne LOOP
    IF v_f IS NULL THEN
      RAISE EXCEPTION 'CLASSES-DUREE : fonction interne absente';
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false)
       OR v_p.prosecdef IS DISTINCT FROM (v_p.proname IN (
            'verifier_horaire_classe_avec_enseignant', 'verifier_creneau_classe_avec_enseignant',
            'verrouiller_classe_du_creneau')) THEN
      RAISE EXCEPTION 'CLASSES-DUREE : % : proprietaire, search_path ou DEFINER invalides', v_f;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CLASSES-DUREE : % peut executer %', v_role, v_f;
      END IF;
    END LOOP;
  END LOOP;

  -- Les quatre fonctions de public : DEFINER, a postgres, search_path vide, droits
  -- inchanges, empreinte F86 a jour.
  FOREACH v_f IN ARRAY v_publiques LOOP
    IF v_f IS NULL THEN
      RAISE EXCEPTION 'CLASSES-DUREE : fonction publique absente';
    END IF;
    SELECT * INTO v_p FROM pg_catalog.pg_proc WHERE oid = v_f::oid;
    IF NOT v_p.prosecdef
       OR pg_catalog.pg_get_userbyid(v_p.proowner) <> 'postgres'
       OR NOT coalesce(v_p.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'CLASSES-DUREE : % doit etre DEFINER, a postgres, search_path vide', v_f;
    END IF;
    IF coalesce(pg_catalog.obj_description(v_f::oid, 'pg_proc'), '') NOT LIKE
         '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)) || '%' THEN
      RAISE EXCEPTION 'CLASSES-DUREE : empreinte F86 de % absente ou perimee', v_f;
    END IF;
    IF pg_catalog.has_function_privilege('anon', v_f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CLASSES-DUREE : anon ou agent_ro peut executer %', v_f;
    END IF;
  END LOOP;
  -- materialiser : service_role seulement ; les trois autres : authenticated.
  IF pg_catalog.has_function_privilege('authenticated', v_publiques[1], 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('service_role', v_publiques[1], 'EXECUTE') THEN
    RAISE EXCEPTION 'CLASSES-DUREE : materialiser_seances_groupe doit rester a service_role seul';
  END IF;
  FOR i IN 2..4 LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', v_publiques[i], 'EXECUTE') THEN
      RAISE EXCEPTION 'CLASSES-DUREE : authenticated doit pouvoir executer %', v_publiques[i];
    END IF;
  END LOOP;

  -- (A) La duree vient de la Classe, plus du reglage unique.
  v_def := (SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_publiques[1]::oid);
  IF pg_catalog.strpos(v_def, 'v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);') = 0
     OR pg_catalog.strpos(v_def, 'session_duration_minutes') <> 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : materialiser_seances_groupe ne lit plus la duree de la Classe';
  END IF;
  -- (C) Les creneaux libres : duree de la Classe ou du public, couverture, durees propres.
  v_def := (SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_publiques[2]::oid);
  IF pg_catalog.strpos(v_def, 'v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneau_couvert_par_disponibilites(') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneaux_recurrents_se_chevauchent_durees(') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneaux_recurrents_se_chevauchent(') <> 0
     OR pg_catalog.strpos(v_def, 'v_duree_individuelle') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : enseignants_pour_classe ne compte plus la duree de la Classe';
  END IF;
  v_def := (SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_publiques[3]::oid);
  IF pg_catalog.strpos(v_def, 'v_duree := app_private.duree_seance_minutes(NULL, p_type_public);') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneau_couvert_par_disponibilites(') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneaux_recurrents_se_chevauchent_durees(') = 0
     OR pg_catalog.strpos(v_def, 'app_private.creneaux_recurrents_se_chevauchent(') <> 0
     OR pg_catalog.strpos(v_def, 'v_duree_individuelle') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : enseignants_pour_public ne compte plus la duree du public';
  END IF;
  v_def := (SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_publiques[4]::oid);
  IF pg_catalog.strpos(v_def, 'v_duree := app_private.duree_seance_minutes(v_cible.offre_id, v_cible.type_public);') = 0
     OR pg_catalog.strpos(v_def, 'seance.duree_minutes_') <> 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : transferer_eleve ne lit plus la duree de la Classe cible';
  END IF;

  -- (B) Les declencheurs : presents, actifs, apres l'ancrage et avant la
  -- materialisation, appelant le predicat de base avec la couverture exigee.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid = 'public.groupes'::regclass AND NOT t.tgisinternal AND t.tgenabled = 'O'
         AND t.tgname IN ('groupes_horaire_verifie_enseignant')) <> 1
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
          WHERE t.tgrelid = 'public.groupe_creneaux'::regclass AND NOT t.tgisinternal AND t.tgenabled = 'O'
            AND t.tgname = 'groupe_creneaux_verifie_enseignant') <> 1 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : declencheur de verification de l''horaire absent ou desactive';
  END IF;
  IF NOT ('groupes_creneau_ancre' COLLATE "C" < 'groupes_horaire_verifie_enseignant' COLLATE "C"
          AND 'groupes_horaire_verifie_enseignant' COLLATE "C" < 'tc_materialiser_apres_creation_groupe' COLLATE "C")
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
          WHERE t.tgrelid = 'public.groupes'::regclass AND NOT t.tgisinternal
            AND t.tgname IN ('groupes_creneau_ancre', 'tc_materialiser_apres_creation_groupe')
            AND t.tgenabled = 'O') <> 2 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : l''ordre des declencheurs de groupes n''est plus ancrage, verification, materialisation';
  END IF;
  v_def := pg_catalog.pg_get_triggerdef((SELECT t.oid FROM pg_catalog.pg_trigger t
            WHERE t.tgrelid = 'public.groupes'::regclass AND t.tgname = 'groupes_horaire_verifie_enseignant'));
  IF v_def NOT LIKE 'CREATE TRIGGER groupes_horaire_verifie_enseignant AFTER UPDATE OF weekday, hour_local, timezone_iana ON public.groupes FOR EACH ROW WHEN%' THEN
    RAISE EXCEPTION 'CLASSES-DUREE : declencheur de groupes mal pose : %', v_def;
  END IF;
  v_def := pg_catalog.pg_get_triggerdef((SELECT t.oid FROM pg_catalog.pg_trigger t
            WHERE t.tgrelid = 'public.groupe_creneaux'::regclass AND t.tgname = 'groupe_creneaux_verifie_enseignant'));
  IF v_def NOT LIKE 'CREATE TRIGGER groupe_creneaux_verifie_enseignant AFTER INSERT OR UPDATE OF groupe_id, weekday, hour_local ON public.groupe_creneaux FOR EACH ROW%' THEN
    RAISE EXCEPTION 'CLASSES-DUREE : declencheur de groupe_creneaux mal pose : %', v_def;
  END IF;
  FOREACH v_f IN ARRAY ARRAY[v_interne[6], v_interne[7]] LOOP
    v_def := (SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_f::oid);
    IF pg_catalog.strpos(v_def, 'app_private.verifier_affectation_enseignant_base(') = 0
       OR pg_catalog.strpos(v_def, ', true);') = 0
       OR pg_catalog.strpos(v_def, 'plafond_classes') <> 0
       OR pg_catalog.strpos(v_def, 'app_private.verifier_horaire_contre_seances_planifiees(') = 0
       OR pg_catalog.strpos(v_def, 'verifier_affectation_enseignant_base')
          > pg_catalog.strpos(v_def, 'verifier_horaire_contre_seances_planifiees') THEN
      RAISE EXCEPTION 'CLASSES-DUREE : % doit appeler le predicat de base (couverture exigee) puis le controle de la Classe contre elle-meme', v_f;
    END IF;
  END LOOP;
  IF pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[5]::oid),
                       'private.c29_enseignant_effectif_session(s.id)') = 0
     OR pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[5]::oid),
                          'NOT (s.groupe_id IS NOT DISTINCT FROM p_groupe_id AND s.started_at = d.debut)') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : le controle des seances deja materialisees doit couvrir l''enseignant effectif de toutes les Classes';
  END IF;
  IF pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[7]::oid),
                       'NEW.weekday = v_g.weekday AND NEW.hour_local = v_g.hour_local') = 0
     OR pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[7]::oid),
                          'pg_trigger_depth') <> 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : le declencheur de groupe_creneaux doit ignorer le seul creneau d''ancrage de la Classe';
  END IF;
  -- Interblocage : le verrou de la Classe se prend AVANT le controle de cle
  -- etrangere (BEFORE, FOR UPDATE). Duree de seance : reglage valide a l'ecriture.
  v_def := pg_catalog.pg_get_triggerdef((SELECT t.oid FROM pg_catalog.pg_trigger t
            WHERE t.tgrelid = 'public.groupe_creneaux'::regclass AND t.tgname = 'groupe_creneaux_a_verrou_classe'
              AND t.tgenabled = 'O'));
  IF v_def IS NULL
     OR v_def NOT LIKE 'CREATE TRIGGER groupe_creneaux_a_verrou_classe BEFORE INSERT OR UPDATE OF groupe_id, weekday, hour_local ON public.groupe_creneaux FOR EACH ROW%'
     OR pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[8]::oid),
                          'FOR UPDATE') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : le verrou de la Classe avant le controle de cle etrangere est absent ou mal pose';
  END IF;
  v_def := pg_catalog.pg_get_triggerdef((SELECT t.oid FROM pg_catalog.pg_trigger t
            WHERE t.tgrelid = 'public.app_config'::regclass AND t.tgname = 'app_config_duree_seance'
              AND t.tgenabled = 'O'));
  IF v_def IS NULL
     OR v_def NOT LIKE 'CREATE TRIGGER app_config_duree_seance BEFORE INSERT OR UPDATE ON public.app_config FOR EACH ROW%'
     OR pg_catalog.strpos((SELECT prosrc FROM pg_catalog.pg_proc WHERE oid = v_interne[9]::oid),
                          'BETWEEN 15 AND 240') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la validation du reglage de duree est absente ou mal posee';
  END IF;
  -- La policy d'ecriture de la direction sur groupe_creneaux reste en place (le
  -- controle passe par le declencheur, pas par son retrait).
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies p
                  WHERE p.schemaname = 'public' AND p.tablename = 'groupe_creneaux'
                    AND p.policyname = 'groupe_creneaux_admin') THEN
    RAISE EXCEPTION 'CLASSES-DUREE : la policy groupe_creneaux_admin ne devait pas etre retiree';
  END IF;

  -- (A) Le predicat d'affectation est inchange : base puis plafond de Classes.
  SELECT * INTO v_p FROM pg_catalog.pg_proc
   WHERE oid = 'app_private.verifier_affectation_enseignant_base(uuid,uuid,boolean)'::regprocedure::oid;
  IF pg_catalog.strpos(v_p.prosrc, 'v_duree := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public)') = 0 THEN
    RAISE EXCEPTION 'CLASSES-DUREE : le predicat d''affectation ne lit plus la duree de la Classe';
  END IF;

  -- Plus aucune seance a venir ne differe de la duree de sa Classe.
  IF EXISTS (SELECT 1 FROM app_private.seances_a_venir_a_realigner()) THEN
    RAISE EXCEPTION 'CLASSES-DUREE : des seances a venir ne suivent pas la duree de leur Classe';
  END IF;
END;
$postflight$;

COMMIT;
