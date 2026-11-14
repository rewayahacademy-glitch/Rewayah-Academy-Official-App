-- PAIE-FENETRE (13/11/2026) : la fenetre payable d'une seance.
--
-- REGLE DU DIRECTEUR (13/11/2026, mot pour mot) : « Quand on dit qu'une classe
-- est adulte, ca veut dire que c'est 1h30. Les minutes qui viennent avant ne
-- sont pas comptees dans la paie, ni les minutes qui viennent apres. Et pour
-- une classe d'enfants, c'est 1 heure. La aussi, meme chose. » Et : « pour le
-- comptage, il faut faire attention, sinon l'academie va tomber dans des
-- litiges interminables avec les enseignants [...] un enseignant peut rentrer
-- et sortir plusieurs fois. »
--
-- AVANT (mesure en production, lecture seule, 13/11) :
--   * private.pai_due_seance payait la duree PLANIFIEE (ended_at - started_at),
--     quelle qu'elle soit : une classe d'enfants planifiee 90 minutes payait 90 ;
--   * private.pai_minutes_enseignant comptait les minutes de l'enseignant
--     jusqu'a la fin prevue plus 15 minutes de grace (74 minutes rendues pour
--     une seance de 60) ;
--   * private.presence_temps_reel, pour une seance sans fin financiere, prenait
--     pour borne la fin prevue plus la grace, donc du temps A VENIR
--     (least() ignore NULL : la seconde branche du coalesce ne servait jamais).
--
-- APRES :
--   1. FENETRE PAYABLE = [debut prevu, debut prevu + duree de la formule],
--      arretee a la fin planifiee si la seance est planifiee plus courte.
--      Duree de la formule : le reglage EXISTANT de la direction,
--      app_config seance.duree_minutes_adulte (90) pour une classe d'adultes
--      (groupes.type_public = 'adulte') et seance.duree_minutes_enfant (60)
--      sinon. Aucune colonne, aucun reglage nouveau : c'est deja la source de
--      la duree des seances (20261022000400, 20261023000000, garde par le
--      declencheur app_config_duree_seance). La duree d'une OFFRE
--      (offres_horaires.duree_minutes) ne sert PAS a la paie : la regle du
--      directeur ne connait que le public de la classe.
--   2. private.pai_minutes_enseignant ne compte que les secondes de connexion
--      de l'enseignant effectif DANS cette fenetre (et jamais apres la cloture
--      de la seance ni apres maintenant).
--   3. private.pai_due_seance paie au plus la fenetre : « duree prevue »
--      devient « duree de la fenetre ». Taux, seuils de duree due (45/70),
--      compte des eleves presents, decisions de la direction, files d'attente
--      et ecritures : a l'identique.
--   4. private.presence_temps_reel (presence des ELEVES et de tous) : seule la
--      borne de fin d'une seance SANS fin financiere change, least(maintenant,
--      fin prevue). Avec une fin financiere : least(fin financiere, fin prevue
--      + grace), comme avant. Statut, seuil, heure de sortie : a l'identique.
--   5. Un seul compteur : l'appariement des entrees et sorties et la fusion des
--      ilots (20261124800000) passent, sans changement, dans
--      private.presence_mesure(seance, profil, debut, fin) ; la presence et la
--      paie l'appellent avec leurs propres bornes. Il n'y a pas deux facons de
--      compter.
--
-- AUCUN RECALCUL : ce fichier ne modifie aucune ligne de donnees. Les montants
-- deja ecrits (tresorerie_mouvements et les autres tables d'argent) restent
-- tels quels ; seules les clotures et les lectures A VENIR utilisent la
-- fenetre. Consequence a connaitre : les MINUTES affichees d'une seance deja
-- payee sont relues par la nouvelle mesure, son MONTANT ne bouge pas.
--
-- FICHIER SANS EFFACEMENT (regle B5) : fonctions creees ou remplacees a
-- signature egale, rien n'est retire. Rejouable, collable en un bloc.
-- PREREQUIS : 20261124800000_paie_minutes_reconnexion.sql.
-- Scenario : supabase/tests/scenarios_paie_fenetre.sql.

BEGIN;

-- Preflight -------------------------------------------------------------------
-- Empreinte des trois fonctions remplacees : md5 du corps SANS commentaires ni
-- espaces (en production, pai_due_seance a le meme corps que le depot a quatre
-- lignes de commentaire pres ; releve du 13/11, lecture seule). Chaque
-- fonction doit etre soit celle d'avant ce fichier, soit celle de ce fichier
-- (rejeu). Tout autre corps : on s'arrete, rien n'est change.
DO $preflight$
DECLARE
  r record;
  v_md5 text;
BEGIN
  FOR r IN
    SELECT * FROM (VALUES
      ('private.presence_temps_reel(uuid,uuid)', 'f8ee8787569c765f1d5028ad9ccc778e', 'PAIE-FENETRE'),
      ('private.pai_minutes_enseignant(uuid)', 'a96a52c1dd6802c085ca0c305a3c4b6c', 'private.pai_fenetre'),
      ('private.pai_due_seance(uuid,public.politiques_commerciales)', '375048d6affff9c248fd6c5f42a9bfd0', 'private.pai_fenetre')
    ) AS x(fonction, empreinte, marque)
  LOOP
    IF pg_catalog.to_regprocedure(r.fonction) IS NULL THEN
      RAISE EXCEPTION 'PAIE-FENETRE : % absente', r.fonction;
    END IF;
    SELECT pg_catalog.md5(pg_catalog.regexp_replace(pg_catalog.regexp_replace(
             p.prosrc, '--[^\n]*', '', 'g'), '\s+', '', 'g'))
      INTO v_md5
      FROM pg_catalog.pg_proc p
     WHERE p.oid = pg_catalog.to_regprocedure(r.fonction);
    IF v_md5 IS DISTINCT FROM r.empreinte
       AND pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                               WHERE p.oid = pg_catalog.to_regprocedure(r.fonction)), r.marque) = 0 THEN
      RAISE EXCEPTION 'PAIE-FENETRE : % n''est pas la definition attendue (empreinte %). Si c''est presence_temps_reel : coller d''abord 20261124800000_paie_minutes_reconnexion.sql.',
        r.fonction, v_md5;
    END IF;
  END LOOP;
  IF pg_catalog.to_regprocedure('private.c29_enseignant_effectif_session(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('public.app_config_int(text,integer)') IS NULL THEN
    RAISE EXCEPTION 'PAIE-FENETRE : dependance absente';
  END IF;
END;
$preflight$;

-- 1. Le compteur unique ---------------------------------------------------------
-- Corps repris de private.presence_temps_reel (20261124800000) : appariement
-- des joined/left, branche entered_at/exited_at, fusion des ilots. Seules les
-- bornes deviennent des arguments.
CREATE OR REPLACE FUNCTION private.presence_mesure(
  p_seance uuid, p_profil uuid, p_debut timestamptz, p_fin timestamptz)
RETURNS TABLE (arrivee timestamptz, fin timestamptz, secondes numeric, ouvert boolean)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_secondes numeric := 0;
  v_ouvert_fin boolean := false;
  r record;
  v_ilot_debut timestamptz;
  v_ilot_fin timestamptz;
  -- Connexions ouvertes (pile) et intervalles tires des evenements joined/left.
  g record;
  v_pile timestamptz[] := ARRAY[]::timestamptz[];
  v_a timestamptz[] := ARRAY[]::timestamptz[];
  v_b timestamptz[] := ARRAY[]::timestamptz[];
  v_o boolean[] := ARRAY[]::boolean[];
  v_reste integer;
  v_n integer;
  v_j timestamptz;
  v_suivant timestamptz;
BEGIN
  secondes := 0;
  ouvert := false;
  -- Bornes inconnues ou fenetre vide : rien a compter.
  IF p_debut IS NULL OR p_fin IS NULL OR p_fin <= p_debut THEN
    RETURN NEXT;
    RETURN;
  END IF;

  -- PAIE-MINUTES-RECONNEXION (13/11/2026). Les evenements joined/left sont lus
  -- dans l'ordre de server_ts (jamais l'ordre d'insertion), un groupe par
  -- horodatage, comme des connexions ouvertes :
  --   * un left ferme d'abord une connexion ouverte AVANT cet horodatage ; il
  --     ne ferme donc plus la connexion qui s'ouvre a la meme seconde
  --     (reconnexion : left de l'ancienne et joined de la nouvelle arrivent
  --     avec le meme horodatage, tronque a la seconde par le webhook video) ;
  --   * s'il n'y a rien d'ouvert, un left et un joined du meme horodatage
  --     s'annulent (connexion de moins d'une seconde : zero) ;
  --   * un left sans connexion ouverte est ignore ;
  --   * deux appareils en meme temps : la presence dure jusqu'au left qui
  --     ferme la derniere connexion (union reelle) ;
  --   * un joined jamais ferme par un left qui lui revient : ferme au left
  --     suivant s'il y en a un, sinon ouvert jusqu'a la borne de fin (deux
  --     joined pour un seul left comptent une fois).
  -- session_events ne porte aucun identifiant de connexion : ni id (ordre
  -- d'arrivee des webhooks, non garanti) ni source (geste ou reseau) ne dit
  -- quelle connexion un left ferme ; aucun des deux ne sert donc a departager.
  FOR g IN
    SELECT e.server_ts AS ts,
           (pg_catalog.count(*) FILTER (WHERE e.event_type = 'joined'))::integer AS nj,
           (pg_catalog.count(*) FILTER (WHERE e.event_type = 'left'))::integer AS nl
      FROM public.session_events e
     WHERE e.session_id = p_seance AND e.profile_id = p_profil
       AND e.event_type IN ('joined', 'left')
     GROUP BY e.server_ts
     ORDER BY e.server_ts
  LOOP
    v_reste := g.nl;
    v_n := coalesce(pg_catalog.cardinality(v_pile), 0);
    WHILE v_reste > 0 AND v_n > 0 LOOP
      v_a := v_a || v_pile[v_n];
      v_b := v_b || g.ts;
      v_o := v_o || false;
      v_pile := v_pile[1:v_n - 1];
      v_n := v_n - 1;
      v_reste := v_reste - 1;
    END LOOP;
    FOR v_n IN 1 .. g.nj - v_reste LOOP
      v_pile := v_pile || g.ts;
    END LOOP;
  END LOOP;
  -- Connexions restees ouvertes : left suivant s'il existe, sinon borne de fin.
  FOREACH v_j IN ARRAY v_pile LOOP
    SELECT pg_catalog.min(e.server_ts) INTO v_suivant
      FROM public.session_events e
     WHERE e.session_id = p_seance AND e.profile_id = p_profil
       AND e.event_type = 'left' AND e.server_ts > v_j;
    v_a := v_a || v_j;
    v_b := v_b || coalesce(v_suivant, p_fin);
    v_o := v_o || (v_suivant IS NULL);
  END LOOP;

  -- Ilots : intervalles bornes, tries par debut, fusionnes a la volee.
  FOR r IN
    WITH intervalles AS (
      SELECT x.a, x.b, x.ouvert
        FROM ROWS FROM (pg_catalog.unnest(v_a), pg_catalog.unnest(v_b), pg_catalog.unnest(v_o))
             AS x(a, b, ouvert)
      UNION ALL
      SELECT sp.entered_at, coalesce(sp.exited_at, p_fin), sp.exited_at IS NULL
        FROM public.session_participants sp
       WHERE sp.session_id = p_seance AND sp.profile_id = p_profil
         AND sp.deleted_at IS NULL AND sp.entered_at IS NOT NULL
    )
    SELECT greatest(i.a, p_debut) AS a, least(i.b, p_fin) AS b, i.ouvert
      FROM intervalles i
     WHERE least(i.b, p_fin) > greatest(i.a, p_debut)
     ORDER BY 1, 2
  LOOP
    IF v_ilot_fin IS NULL OR r.a > v_ilot_fin THEN
      IF v_ilot_fin IS NOT NULL THEN
        v_secondes := v_secondes + extract(epoch FROM (v_ilot_fin - v_ilot_debut));
      END IF;
      v_ilot_debut := r.a;
      v_ilot_fin := r.b;
      v_ouvert_fin := r.ouvert;
      IF arrivee IS NULL THEN
        arrivee := r.a;
      END IF;
    ELSIF r.b >= v_ilot_fin THEN
      v_ouvert_fin := CASE WHEN r.b > v_ilot_fin THEN r.ouvert ELSE v_ouvert_fin OR r.ouvert END;
      v_ilot_fin := r.b;
    END IF;
  END LOOP;
  IF v_ilot_fin IS NOT NULL THEN
    v_secondes := v_secondes + extract(epoch FROM (v_ilot_fin - v_ilot_debut));
  END IF;

  fin := v_ilot_fin;
  secondes := v_secondes;
  ouvert := v_ouvert_fin;
  RETURN NEXT;
END;
$function$;

-- 2. La presence de tous : meme regle, borne de fin corrigee --------------------
CREATE OR REPLACE FUNCTION private.presence_temps_reel(p_seance uuid, p_profil uuid)
RETURNS TABLE (arrivee timestamptz, sortie timestamptz, minutes integer,
               minutes_prevues integer, statut text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions;
  v_debut timestamptz;
  v_fin timestamptz;
  v_seuil numeric;
  v_override public.presence_state;
  v_prevues numeric;
  m record;
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  v_debut := v_s.started_at;
  -- FN-003 : une fin financiere posee tard (cloture automatique, des heures
  -- apres) ne prolonge pas la presence au-dela de la fin prevue et de la grace
  -- (grace_after_end_minutes).
  -- PAIE-FENETRE : sans fin financiere, la borne est maintenant, au plus la fin
  -- prevue. L'ancienne ecriture coalesce(least(fin financiere, fin + grace),
  -- least(now(), fin)) ne prenait jamais sa seconde branche (least() ignore
  -- NULL) et comptait du temps a venir.
  v_fin := CASE
    WHEN v_s.finance_ended_at IS NULL THEN least(pg_catalog.now(), v_s.ended_at)
    ELSE least(v_s.finance_ended_at,
               v_s.ended_at + pg_catalog.make_interval(mins => public.app_config_int('grace_after_end_minutes', 15)))
  END;
  v_prevues := extract(epoch FROM (v_s.ended_at - v_s.started_at));
  v_seuil := public.app_config_int('presence.seuil_present_pourcentage', 50);

  -- PAIE-MINUTES-RECONNEXION, PAIE-FENETRE : le comptage (appariement des
  -- entrees et sorties, ilots) est celui de private.presence_mesure, le meme
  -- que celui de la paie.
  SELECT x.arrivee, x.fin, x.secondes, x.ouvert INTO m
    FROM private.presence_mesure(p_seance, p_profil, v_debut, v_fin) x;
  arrivee := m.arrivee;
  IF m.fin IS NOT NULL THEN
    -- Encore connecte pendant la seance : pas d'heure de sortie a montrer.
    sortie := CASE WHEN m.ouvert AND v_s.finance_ended_at IS NULL
                         AND v_s.status IN ('planned', 'preflight', 'in_progress')
                    THEN NULL ELSE m.fin END;
  END IF;

  minutes := pg_catalog.floor(m.secondes / 60)::integer;
  minutes_prevues := pg_catalog.ceil(v_prevues / 60)::integer;

  SELECT o.etat INTO v_override FROM public.session_presence_override o
   WHERE o.session_id = p_seance AND o.profile_id = p_profil;
  statut := CASE
    WHEN v_override = 'excusee' THEN 'excusee'
    WHEN v_override = 'corrigee_manuel' THEN 'presente'
    WHEN m.secondes <= 0 THEN 'absente'
    WHEN m.secondes * 100 >= v_prevues * v_seuil THEN 'presente'
    ELSE 'partielle'
  END;
  RETURN NEXT;
END;
$function$;

-- 3. La fenetre payable ---------------------------------------------------------
-- minutes et fin sont NULL si le reglage de la duree est absent ou hors de
-- 15 a 240 minutes : la paie part alors a la direction, elle ne retombe pas
-- en silence sur une valeur.
CREATE OR REPLACE FUNCTION private.pai_fenetre(p_seance uuid)
RETURNS TABLE (debut timestamptz, fin timestamptz, minutes numeric, formule_minutes integer)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions;
  v_public text;
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  SELECT g.type_public INTO v_public FROM public.groupes g WHERE g.id = v_s.groupe_id;
  -- Meme partage que le taux de private.pai_due_seance : adulte, sinon enfant.
  formule_minutes := CASE v_public
    WHEN 'adulte' THEN public.app_config_int('seance.duree_minutes_adulte', 90)
    ELSE public.app_config_int('seance.duree_minutes_enfant', 60) END;
  debut := v_s.started_at;
  IF coalesce(formule_minutes BETWEEN 15 AND 240, false)
     AND v_s.started_at IS NOT NULL AND v_s.ended_at IS NOT NULL THEN
    -- Seance planifiee plus courte que la formule : la fenetre s'arrete a la
    -- fin planifiee. Plus longue : elle s'arrete a la duree de la formule.
    fin := least(v_s.ended_at,
                 v_s.started_at + pg_catalog.make_interval(mins => formule_minutes));
    minutes := greatest(0, extract(epoch FROM (fin - debut)) / 60);
  END IF;
  RETURN NEXT;
END;
$function$;

-- 4. Les minutes de paie de l'enseignant effectif -------------------------------
-- Secondes de connexion dans la fenetre payable, jamais apres la cloture de la
-- seance (fin financiere) ni apres maintenant ; minutes entieres, arrondies
-- vers le bas, comme avant. NULL si la fenetre est inconnue.
CREATE OR REPLACE FUNCTION private.pai_minutes_enseignant(p_seance uuid)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT pg_catalog.floor(t.secondes / 60)::integer
    FROM public.sessions s
    CROSS JOIN LATERAL private.pai_fenetre(s.id) f
    CROSS JOIN LATERAL private.presence_mesure(
      s.id, coalesce(private.c29_enseignant_effectif_session(s.id), s.teacher_id),
      f.debut, least(f.fin, coalesce(s.finance_ended_at, pg_catalog.now()))) t
   WHERE s.id = p_seance AND f.fin IS NOT NULL;
$function$;

-- 5. La paie d'une seance : au plus la fenetre ----------------------------------
-- Corps de 20261102900000 ; changent : v_fenetre (lue une fois, garde positive)
-- et les deux lignes ou la duree prevue plafonnait la duree payee.
CREATE OR REPLACE FUNCTION private.pai_due_seance(p_seance uuid, p public.politiques_commerciales)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_s public.sessions;
  v_public text;
  v_taux bigint;
  v_duree_due integer;
  v_fenetre numeric;
  v_tenues numeric;
  v_payees numeric;
  v_presents integer;
  v_due bigint;
  v_ref bigint;
  v_debut timestamptz;
  v_fin timestamptz;
  v_montant bigint;
  v_devise text;
  v_decide boolean;
  v_transfert uuid := pg_catalog.gen_random_uuid();
  v_minutes_ens integer;
BEGIN
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id = p_seance FOR UPDATE;
  IF NOT FOUND OR v_s.status NOT IN ('ended', 'tech_failure') THEN
    RETURN NULL;
  END IF;
  SELECT q.decision_debut, q.decision_fin, q.decision_montant_minor, q.decision_devise
    INTO v_debut, v_fin, v_montant, v_devise
    FROM public.tresorerie_a_reprendre q
   WHERE q.source_type = 'prestation' AND q.source_id = p_seance::text
     AND q.raison = 'duree_indeterminee' AND q.traite_le IS NULL
     AND (q.decision_debut IS NOT NULL OR q.decision_montant_minor IS NOT NULL)
   ORDER BY q.id DESC LIMIT 1;
  v_decide := v_debut IS NOT NULL;
  IF NOT v_decide THEN
    v_debut := v_s.finance_started_at;
    v_fin := v_s.finance_ended_at;
  END IF;

  IF v_montant IS NOT NULL THEN
    IF v_devise IS DISTINCT FROM p.devise OR v_montant < 0 THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'montant_invalide');
      RETURN NULL;
    END IF;
    v_due := v_montant;
  ELSE
    -- PAIE-FENETRE : la fenetre payable (private.pai_fenetre). Reglage de la
    -- duree absent ou invalide : la seance part a la direction.
    SELECT f.minutes INTO v_fenetre FROM private.pai_fenetre(p_seance) f;
    IF NOT coalesce(v_fenetre > 0, false) THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'regle_remuneration_absente');
      RETURN NULL;
    END IF;
    -- PRESENCE-MINUTES : la duree tenue est celle ou l'enseignant effectif
    -- etait reellement connecte, jamais finance_started_at ; sans connexion
    -- mesuree (et sans decision de la direction), la seance part a la
    -- direction comme avant. PAIE-FENETRE : connexion DANS la fenetre payable.
    v_minutes_ens := CASE WHEN v_decide THEN NULL ELSE private.pai_minutes_enseignant(p_seance) END;
    IF (v_s.status = 'tech_failure' AND NOT v_decide)
       OR (v_decide AND (v_fin IS NULL OR v_fin <= v_debut))
       OR (NOT v_decide AND coalesce(v_minutes_ens, 0) <= 0) THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'duree_indeterminee');
      RETURN NULL;
    END IF;
    SELECT g.type_public INTO v_public FROM public.groupes g WHERE g.id = v_s.groupe_id;
    v_taux := CASE v_public WHEN 'adulte' THEN p.taux_eleve_heure_adulte_mineur
                            ELSE p.taux_eleve_heure_enfant_mineur END;
    v_duree_due := CASE v_public WHEN 'adulte' THEN p.duree_due_adulte_minutes
                                 ELSE p.duree_due_enfant_minutes END;
    IF v_taux IS NULL THEN
      PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'regle_remuneration_absente');
      RETURN NULL;
    END IF;
    v_tenues := CASE WHEN v_decide THEN extract(epoch FROM (v_fin - v_debut)) / 60
                     ELSE v_minutes_ens END;
    -- Duree due atteinte : toute la fenetre est payee. Sinon : les minutes
    -- tenues, jamais plus que la fenetre (une duree decidee par la direction
    -- est plafonnee de la meme facon).
    v_payees := CASE WHEN v_duree_due IS NULL OR v_tenues >= v_duree_due THEN v_fenetre
                     ELSE least(v_tenues, v_fenetre) END;
    v_presents := private.pai_eleves_presents(p_seance);
    v_due := pg_catalog.round(v_taux * v_presents * v_payees / 60)::bigint;
  END IF;

  IF v_due = 0 THEN
    RETURN 0;
  END IF;
  v_fin := coalesce(v_fin, v_s.finance_ended_at, v_s.ended_at);
  v_ref := public.x217_montant_ref(v_due, p.devise, v_fin);
  IF v_ref IS NULL OR v_ref <= 0 THEN
    PERFORM public.x217_mettre_en_file('prestation', p_seance::text, 'taux_change_absent');
    RETURN NULL;
  END IF;
  INSERT INTO public.tresorerie_mouvements (coffre, sens, montant_minor, devise, montant_ref_minor, devise_ref,
      survenu_le, transfert_id, source_type, regle, source_id)
  VALUES ('fonds_clients_engages', 'sortie', v_due, p.devise, v_ref, 'USD', v_fin,
          v_transfert, 'prestation', 'session_debit', p_seance::text),
         ('paie_a_decaisser', 'entree', v_due, p.devise, v_ref, 'USD', v_fin,
          v_transfert, 'prestation', 'remuneration_due', p_seance::text)
  ON CONFLICT (source_type, source_id, regle, coffre, sens) DO NOTHING;
  RETURN v_due;
END;
$function$;

-- 6. Droits et commentaires -----------------------------------------------------
ALTER FUNCTION private.presence_mesure(uuid, uuid, timestamptz, timestamptz) OWNER TO postgres;
ALTER FUNCTION private.pai_fenetre(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.presence_mesure(uuid, uuid, timestamptz, timestamptz)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON FUNCTION private.pai_fenetre(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON FUNCTION private.presence_mesure(uuid, uuid, timestamptz, timestamptz) IS
  'PAIE-FENETRE (13/11/2026) : le compteur unique. Secondes de connexion d''un profil a une seance entre deux bornes (joined/left de session_events lus comme des connexions ouvertes, un left ne ferme jamais la connexion ouverte a la meme seconde ; entered_at/exited_at ; reconnexions additionnees, chevauchements comptes une fois ; une connexion sans left est fermee a la borne de fin). Appele par la presence (private.presence_temps_reel) et par la paie (private.pai_minutes_enseignant). Privee.';
COMMENT ON FUNCTION private.presence_temps_reel(uuid, uuid) IS
  'PRESENCE-MINUTES (31/10/2026), PAIE-MINUTES-RECONNEXION et PAIE-FENETRE (13/11/2026) : arrivee, sortie, minutes connectees (private.presence_mesure, du debut prevu a la fin : least(fin financiere, fin prevue + grace), ou least(maintenant, fin prevue) sans fin financiere), minutes prevues et etat : presente (>= presence.seuil_present_pourcentage de la duree prevue), partielle (> 0), absente (0) ; excusee et corrigee_manuel de la direction l''emportent. Privee.';
COMMENT ON FUNCTION private.pai_fenetre(uuid) IS
  'PAIE-FENETRE (13/11/2026, regle du directeur) : fenetre payable d''une seance = du debut prevu au debut prevu + duree de la formule (app_config seance.duree_minutes_adulte, 90, pour une classe d''adultes ; seance.duree_minutes_enfant, 60, sinon), arretee a la fin planifiee si la seance est plus courte. minutes et fin NULL si le reglage est absent ou hors de 15 a 240. Privee.';
COMMENT ON FUNCTION private.pai_minutes_enseignant(uuid) IS
  'PRESENCE-MINUTES (31/10/2026), PAIE-FENETRE (13/11/2026) : minutes entieres de connexion de l''enseignant effectif (remplacant s''il y en a un) DANS la fenetre payable (private.pai_fenetre), jamais apres la cloture de la seance ni apres maintenant ; compteur private.presence_mesure. Lue par la paie, le releve de la direction et les revenus de l''enseignant. Privee.';
COMMENT ON FUNCTION private.pai_due_seance(uuid, public.politiques_commerciales) IS
  'FAC-E-02, PRESENCE-MINUTES, PAIE-FENETRE (13/11/2026) : paie d''une seance close = taux par eleve et par heure x eleves presents x duree payee / 60. Duree payee : toute la fenetre payable (private.pai_fenetre) si l''enseignant effectif y a tenu la duree due de la politique, sinon ses minutes dans la fenetre ; jamais plus que la fenetre. Une decision de la direction (montant ou duree) l''emporte, la duree decidee etant plafonnee a la fenetre. Privee.';

-- Postflight ------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_role text;
  v_def text;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'private.presence_mesure(uuid,uuid,timestamptz,timestamptz)'::pg_catalog.regprocedure,
    'private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure,
    'private.pai_fenetre(uuid)'::pg_catalog.regprocedure,
    'private.pai_minutes_enseignant(uuid)'::pg_catalog.regprocedure,
    'private.pai_due_seance(uuid,public.politiques_commerciales)'::pg_catalog.regprocedure]
  LOOP
    FOREACH v_role IN ARRAY ARRAY['public', 'anon', 'authenticated', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v_oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'PAIE-FENETRE : % exposee a %', v_oid, v_role;
      END IF;
    END LOOP;
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                    WHERE p.oid = v_oid AND p.prosecdef
                      AND 'search_path=""' = ANY (coalesce(p.proconfig, ARRAY[]::text[]))) THEN
      RAISE EXCEPTION 'PAIE-FENETRE : % mal durcie', v_oid;
    END IF;
  END LOOP;

  v_def := pg_catalog.pg_get_functiondef('private.presence_temps_reel(uuid,uuid)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_def, 'private.presence_mesure') = 0
     OR pg_catalog.strpos(v_def, 'grace_after_end_minutes') = 0
     OR pg_catalog.strpos(v_def, 'WHEN v_s.finance_ended_at IS NULL THEN least(pg_catalog.now(), v_s.ended_at)') = 0 THEN
    RAISE EXCEPTION 'PAIE-FENETRE : presence_temps_reel sans compteur unique, sans grace ou sans borne corrigee';
  END IF;
  v_def := pg_catalog.pg_get_functiondef('private.pai_minutes_enseignant(uuid)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_def, 'private.pai_fenetre') = 0
     OR pg_catalog.strpos(v_def, 'private.presence_mesure') = 0
     OR pg_catalog.strpos(v_def, 'presence_temps_reel') > 0 THEN
    RAISE EXCEPTION 'PAIE-FENETRE : pai_minutes_enseignant hors de la fenetre payable';
  END IF;
  v_def := pg_catalog.pg_get_functiondef('private.pai_due_seance(uuid,public.politiques_commerciales)'::pg_catalog.regprocedure);
  IF pg_catalog.strpos(v_def, 'private.pai_fenetre') = 0
     OR pg_catalog.strpos(v_def, 'v_s.ended_at - v_s.started_at') > 0 THEN
    RAISE EXCEPTION 'PAIE-FENETRE : pai_due_seance paie encore la duree planifiee';
  END IF;
  -- Le reglage de la direction existe et tient dans ses bornes.
  IF NOT coalesce(public.app_config_int('seance.duree_minutes_adulte', 0) BETWEEN 15 AND 240, false)
     OR NOT coalesce(public.app_config_int('seance.duree_minutes_enfant', 0) BETWEEN 15 AND 240, false) THEN
    RAISE EXCEPTION 'PAIE-FENETRE : reglage seance.duree_minutes_adulte ou seance.duree_minutes_enfant absent ou hors de 15 a 240';
  END IF;
END;
$postflight$;

COMMIT;
