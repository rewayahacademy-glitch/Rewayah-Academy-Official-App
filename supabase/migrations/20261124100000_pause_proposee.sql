-- PAUSE-SERVEUR (directeur, 12/11/2026) : la pause proposee.
--
-- « La pause de 10 est un reglage, il faut permettre a l'enseignant de la gerer
-- lui-meme ; par defaut, le systeme active automatiquement la pause juste apres
-- le milieu de la session ; pour une classe d'adultes, a 45 min, la barre du
-- chrono propose a l'enseignant de prendre une pause de 10 min ; il accepte par
-- un simple OUI ou refuse par NON ; s'il accepte, tous les participants recoivent
-- l'alerte et l'heure exacte de reprise ; s'il refuse, le systeme le lui rappelle
-- apres quelques minutes (reglable par l'admin, 5 min par defaut), car la pause
-- est un droit. »
--
-- Ce que fait ce fichier, en ajout seul (aucun effacement, aucune contrainte
-- retiree, signatures et types de retour inchanges) :
--
-- 1. app_config : seance.pause_minutes_adulte passe de 0 a 10 (decision du
--    18/10, DECISION-TARIFS-2026-10-18.md l. 106 et 139, jamais appliquee) ;
--    seulement si la valeur est encore l'ancien 0, pour qu'un rejeu n'ecrase pas
--    un choix ulterieur de la direction. Deux cles nouvelles :
--    seance.pause_rappel_minutes = 5 (delai avant de reproposer apres un Non) et
--    seance.pause_reste_minimum_minutes = 15 (on ne propose plus la pause si,
--    apres elle, il resterait moins que cela de cours).
-- 2. pause_seances : deux colonnes, refus_nombre et prochaine_proposition_utc.
-- 3. La pause par defaut : une classe SANS ligne dans pause_reglages recoit la
--    pause au milieu de la duree prevue de la seance, d'une duree lue selon le
--    public de la classe (groupes.type_public : seance.pause_minutes_adulte ou
--    seance.pause_minutes_enfant, la meme lecture que les offres de 0043). Une
--    classe AVEC une ligne garde le choix de son enseignant (actif faux : pas de
--    pause). Une duree reglee a 0 : pas de pause (non_prevue). Une duree hors du
--    pas de la table (5 a 30, par 5) est ramenee au multiple de 5 le plus proche
--    dans ces bornes, pour que le demarrage d'une seance ne soit jamais refuse
--    par la contrainte de pause_seances.
-- 4. Le moment prevu se compte depuis le debut PREVU de la seance
--    (sessions.started_at, borne prevue, jamais reecrite au demarrage ; meme
--    lecture que private.presence_temps_reel, 20261107500000_fn_serveur.sql) :
--    debut_prevu_utc = greatest(now(), started_at) + delai. Vaut aussi pour une
--    classe reglee par son enseignant.
-- 5. pause_seance_refuser (Non) : memes gardes que pause_seance_demarrer,
--    compteur de refus, prochaine proposition a now() + rappel ; idempotente.
-- 6. L'etat rendu (pause_etat_interne, donc pause_seance_etat, demarrer,
--    terminer et refuser) porte en plus proposer_a et refus_nombre ; proposer_a
--    est nul quand la pause ne tient plus avant la fin prevue ou quand le
--    statut n'est plus programmee. Le reste minimum ne compte que pour la
--    pause ordinaire (motif nul) ; une pause a motif doit seulement finir
--    avant la fin prevue. L'etat porte aussi rappel_minutes
--    (seance.pause_rappel_minutes, au moins 1, meme lecture que le Non) :
--    l'application reprend la proposition restee sans reponse apres ce delai
--    de la direction, et non plus apres une constante (SERVEUR-PETITS,
--    13/11/2026, D-042).
-- 7. pause_reglage_lire rend, pour une classe sans ligne, la verite : la pause
--    par defaut (actif, milieu de la duree de la classe, duree du public), avec
--    par_defaut = true. Type de retour inchange (jsonb).
-- 8. Compatibilite avec la pause prevue par le serveur (la priere, autre lot,
--    table public.seance_pause_prevue, qui peut exister ou non) : colonne
--    pause_seances.motif ; au demarrage, une ligne valide de cette table donne
--    l'heure, la duree et le motif de la pause ; l'etat rendu porte motif.
--    Les bornes de l'autre lot font foi : une pause a motif acceptee reste
--    proposable sans le reste minimum (convenu avec le lot priere).
--    Une erreur de lecture de cet objet, ou une ligne presente mais rejetee
--    (heure absente, duree hors pas, heure hors de la seance), garde le repli
--    sur la regle ordinaire et laisse un RAISE WARNING au journal du serveur
--    (identifiant de la seance et raison en clair, ou le SQLSTATE ; aucune
--    donnee personnelle, aucune ecriture). L'absence de l'objet reste
--    toleree en silence (SERVEUR-PETITS, 13/11/2026, remarque du lot priere).
--
-- Aucun droit nouveau a un eleve, un tuteur ou un controleur ; ni la presence
-- ni la paie ne lisent la pause.
BEGIN;

-- ------------------------------------------------------------------
-- 1. Les reglages de la direction
-- ------------------------------------------------------------------
INSERT INTO public.app_config AS c (key, value)
VALUES ('seance.pause_minutes_adulte', pg_catalog.to_jsonb(10))
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = pg_catalog.now()
  WHERE c.value = pg_catalog.to_jsonb(0);

INSERT INTO public.app_config (key, value) VALUES
  ('seance.pause_rappel_minutes',         pg_catalog.to_jsonb(5)),
  ('seance.pause_reste_minimum_minutes',  pg_catalog.to_jsonb(15))
ON CONFLICT (key) DO NOTHING;

-- ------------------------------------------------------------------
-- 2. Les colonnes du refus
-- ------------------------------------------------------------------
-- motif : nul = pause ordinaire ; sinon le motif d'une pause prevue par le
-- serveur (la priere, table public.seance_pause_prevue d'un autre lot).
ALTER TABLE public.pause_seances
  ADD COLUMN IF NOT EXISTS refus_nombre integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS prochaine_proposition_utc timestamptz,
  ADD COLUMN IF NOT EXISTS motif text;

DO $contrainte$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint
                  WHERE conrelid = 'public.pause_seances'::pg_catalog.regclass
                    AND conname = 'pause_seances_refus_nombre_positif') THEN
    ALTER TABLE public.pause_seances
      ADD CONSTRAINT pause_seances_refus_nombre_positif CHECK (refus_nombre >= 0);
  END IF;
END;
$contrainte$;

-- ------------------------------------------------------------------
-- 3. La duree de la pause par defaut d'un public
-- ------------------------------------------------------------------
-- Nul : pas de pause (reglage a 0 ou moins). Sinon un multiple de 5 entre 5 et
-- 30 (le pas de pause_seances.duree_prevue_minutes).
CREATE OR REPLACE FUNCTION app_private.pause_duree_par_defaut(p_type_public text)
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_minutes integer;
BEGIN
  v_minutes := CASE p_type_public
    WHEN 'adulte' THEN public.app_config_int('seance.pause_minutes_adulte', 10)
    ELSE public.app_config_int('seance.pause_minutes_enfant', 5)
  END;
  IF v_minutes IS NULL OR v_minutes <= 0 THEN
    RETURN NULL;
  END IF;
  RETURN LEAST(30, GREATEST(5, (pg_catalog.round(v_minutes / 5.0) * 5)::integer));
END;
$function$;

-- ------------------------------------------------------------------
-- 4. Le reglage lu : la pause par defaut quand la classe n'a pas de ligne
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pause_reglage_lire(p_groupe_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_role public.app_role;
  v_r public.pause_reglages%ROWTYPE;
  v_g public.groupes%ROWTYPE;
  v_duree_classe integer;
  v_pause integer;
BEGIN
  v_role := public.app_role();
  IF auth.uid() IS NULL OR NOT public.app_account_valid()
     OR NOT EXISTS (SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id)
     OR NOT (v_role = 'admin' OR (v_role = 'teacher' AND EXISTS (
       SELECT 1 FROM public.groupes g WHERE g.id = p_groupe_id AND g.teacher_id = auth.uid()
     ))) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'lecture du reglage refusee';
  END IF;
  SELECT r.* INTO v_r FROM public.pause_reglages r WHERE r.groupe_id = p_groupe_id;
  IF FOUND THEN
    RETURN jsonb_build_object('actif', v_r.actif,
      'apres_minutes', v_r.apres_minutes, 'duree_minutes', v_r.duree_minutes,
      'version', v_r.version::text,
      'peut_modifier', v_role = 'teacher',
      'par_defaut', false);
  END IF;
  -- Pas de ligne : la pause par defaut, au milieu de la duree de la classe
  -- (arrondi au pas de 5 du reglage), duree du public.
  SELECT g.* INTO v_g FROM public.groupes g WHERE g.id = p_groupe_id;
  v_duree_classe := app_private.duree_seance_minutes(v_g.offre_id, v_g.type_public);
  v_pause := app_private.pause_duree_par_defaut(v_g.type_public);
  RETURN jsonb_build_object('actif', v_pause IS NOT NULL,
    'apres_minutes', LEAST(120, GREATEST(5, (v_duree_classe / 2 / 5) * 5)),
    'duree_minutes', coalesce(v_pause, 5),
    'version', '0',
    'peut_modifier', v_role = 'teacher',
    'par_defaut', true);
END;
$function$;

-- ------------------------------------------------------------------
-- 5. L'etat de la pause, avec la prochaine proposition
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pause_etat_interne(p_seance_id uuid, p_uid uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_result jsonb;
  v_reste integer;
  v_rappel integer;
BEGIN
  v_reste := GREATEST(0, coalesce(public.app_config_int('seance.pause_reste_minimum_minutes', 15), 15));
  -- Meme lecture et meme borne que pause_seance_refuser : au moins 1 minute.
  v_rappel := GREATEST(1, coalesce(public.app_config_int('seance.pause_rappel_minutes', 5), 5));
  SELECT jsonb_build_object(
    'statut', coalesce(ps.statut,'non_prevue'),
    'duree_prevue_minutes', coalesce(ps.duree_prevue_minutes,5),
    'debut_prevu_utc',ps.debut_prevu_utc,'debut_utc',ps.debut_utc,'fin_utc',ps.fin_utc,
    'peut_piloter', coalesce(s.teacher_id = p_uid AND s.status = 'in_progress',false),
    'refus_nombre', coalesce(ps.refus_nombre, 0),
    'rappel_minutes', v_rappel,
    'motif', ps.motif,
    'proposer_a', CASE
      WHEN ps.statut = 'programmee'
       AND coalesce(ps.prochaine_proposition_utc, ps.debut_prevu_utc)
           + pg_catalog.make_interval(mins => ps.duree_prevue_minutes
               + CASE WHEN ps.motif IS NULL THEN v_reste ELSE 0 END) <= s.ended_at
      THEN coalesce(ps.prochaine_proposition_utc, ps.debut_prevu_utc)
    END)
    INTO v_result
    FROM public.sessions s LEFT JOIN public.pause_seances ps ON ps.seance_id=s.id
   WHERE s.id=p_seance_id AND s.deleted_at IS NULL;
  RETURN v_result;
END;
$function$;

-- ------------------------------------------------------------------
-- 6. Non : la pause est reproposee apres le delai de rappel
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pause_seance_refuser(p_seance_id uuid, p_cle_idempotence text)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_s public.sessions%ROWTYPE;
  v_pause public.pause_seances%ROWTYPE;
  v_i public.pause_idempotence%ROWTYPE;
  v_rappel integer;
BEGIN
  IF auth.uid() IS NULL OR coalesce(public.app_role()='teacher' AND public.app_account_valid(),false)=false
     OR coalesce(length(btrim(p_cle_idempotence)),0) NOT BETWEEN 1 AND 200 THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='pilotage de pause refuse';
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(auth.uid()::text||':'||p_cle_idempotence,0));
  SELECT i.* INTO v_i FROM public.pause_idempotence i WHERE i.acteur_id=auth.uid() AND i.cle_idempotence=p_cle_idempotence;
  IF FOUND THEN
    IF v_i.operation<>'refuser' OR v_i.cible_id<>p_seance_id THEN RAISE EXCEPTION USING ERRCODE='23505',MESSAGE='cle_idempotence_reutilisee'; END IF;
    RETURN public.pause_seance_etat(p_seance_id);
  END IF;
  SELECT s.* INTO v_s FROM public.sessions s WHERE s.id=p_seance_id AND s.teacher_id=auth.uid() AND s.deleted_at IS NULL FOR UPDATE;
  IF NOT FOUND OR v_s.status<>'in_progress' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pilotage de pause refuse'; END IF;
  SELECT ps.* INTO v_pause FROM public.pause_seances ps WHERE ps.seance_id=p_seance_id FOR UPDATE;
  IF NOT FOUND OR v_pause.statut<>'programmee' THEN RAISE EXCEPTION USING ERRCODE='42501',MESSAGE='pause non disponible'; END IF;
  v_rappel := GREATEST(1, coalesce(public.app_config_int('seance.pause_rappel_minutes', 5), 5));
  UPDATE public.pause_seances
     SET refus_nombre = refus_nombre + 1,
         prochaine_proposition_utc = pg_catalog.now() + pg_catalog.make_interval(mins => v_rappel),
         updated_at = pg_catalog.now()
   WHERE seance_id = p_seance_id;
  INSERT INTO public.pause_idempotence(acteur_id,cle_idempotence,operation,cible_id,requete)
    VALUES(auth.uid(),p_cle_idempotence,'refuser',p_seance_id,jsonb_build_object('seance_id',p_seance_id));
  RETURN public.pause_etat_interne(p_seance_id,auth.uid());
END;
$function$;

-- ------------------------------------------------------------------
-- 7. L'instantane au demarrage : pause par defaut, moment depuis le debut prevu
-- ------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.pause_seance_snapshot_trigger()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $function$
DECLARE
  v_reglage public.pause_reglages%ROWTYPE;
  v_type text;
  v_base timestamptz;
  v_pause integer;
  v_reste integer;
  v_debut_prevu timestamptz;
  v_prevue_debut timestamptz;
  v_prevue_duree integer;
  v_prevue_motif text;
  v_prevue_lignes integer := 0;
  v_prevue_raison text;
BEGIN
  IF TG_OP='UPDATE' AND OLD.status IS DISTINCT FROM NEW.status
     AND NEW.status='in_progress' AND NEW.groupe_id IS NOT NULL THEN
    -- Le moment se compte depuis le debut PREVU (started_at), pas depuis
    -- l'entree de l'enseignant, qui peut ouvrir la salle en avance.
    v_base := GREATEST(pg_catalog.now(), NEW.started_at);
    -- Une pause prevue par le serveur (la priere, lot 20261123930000, table
    -- public.seance_pause_prevue) prime sur le milieu et sur le moment choisi
    -- par l'enseignant. La table peut ne pas exister : to_regclass, puis une
    -- requete constante, la seance passee par USING. Une ligne invalide (duree
    -- hors de 5 a 30 ou hors du pas de 5, heure hors de la seance) est ignoree,
    -- comme une erreur de lecture : la regle ordinaire s'applique (une seance
    -- doit toujours pouvoir commencer), mais l'ecart se voit dans le journal du
    -- serveur (RAISE WARNING : identifiant de la seance et raison, aucune
    -- donnee personnelle ; un avertissement n'arrete rien).
    IF pg_catalog.to_regclass('public.seance_pause_prevue') IS NOT NULL THEN
      BEGIN
        -- Table ou vue (le lot priere la livre en vue) ; aucune cle etrangere
        -- supposee, la plus tot si plusieurs lignes.
        EXECUTE 'SELECT p.debut_prevu_utc, p.duree_minutes, p.motif
                   FROM public.seance_pause_prevue p WHERE p.session_id = $1
                  ORDER BY p.debut_prevu_utc LIMIT 1'
          INTO v_prevue_debut, v_prevue_duree, v_prevue_motif
          USING NEW.id;
        GET DIAGNOSTICS v_prevue_lignes = ROW_COUNT;
      EXCEPTION WHEN OTHERS THEN
        -- Une forme inattendue ou une erreur de cet objet externe ne doit
        -- jamais empecher une seance de commencer : regle ordinaire.
        RAISE WARNING 'pause prevue illisible pour la seance % : %', NEW.id, SQLSTATE;
        v_prevue_debut := NULL;
        v_prevue_lignes := 0;
      END;
      IF v_prevue_lignes > 0 THEN
        v_prevue_raison := CASE
          WHEN v_prevue_debut IS NULL THEN 'heure absente'
          WHEN v_prevue_duree IS NULL OR v_prevue_duree NOT BETWEEN 5 AND 30
               OR v_prevue_duree % 5 <> 0 THEN 'duree hors pas'
          WHEN v_prevue_debut < NEW.started_at
               OR v_prevue_debut + pg_catalog.make_interval(mins => v_prevue_duree) > NEW.ended_at
            THEN 'heure hors de la seance'
        END;
        IF v_prevue_raison IS NOT NULL THEN
          RAISE WARNING 'pause prevue ignoree pour la seance % : %', NEW.id, v_prevue_raison;
        END IF;
      END IF;
      IF v_prevue_lignes > 0 AND v_prevue_raison IS NULL THEN
        -- A confirmer par le directeur : elle est posee meme si l'enseignant a
        -- desactive la pause de sa classe (actif = faux).
        INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc,motif)
        VALUES(NEW.id,'programmee',v_prevue_duree,v_prevue_debut,v_prevue_motif)
        ON CONFLICT(seance_id) DO NOTHING;
        RETURN NEW;
      END IF;
    END IF;
    SELECT r.* INTO v_reglage FROM public.pause_reglages r WHERE r.groupe_id=NEW.groupe_id;
    IF FOUND THEN
      -- Le choix de l'enseignant, y compris « pas de pause ».
      IF v_reglage.actif THEN
        INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
        VALUES(NEW.id,'programmee',v_reglage.duree_minutes,v_base+pg_catalog.make_interval(mins=>v_reglage.apres_minutes))
        ON CONFLICT(seance_id) DO NOTHING;
      ELSE
        INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
        VALUES(NEW.id,'non_prevue',5,NULL) ON CONFLICT(seance_id) DO NOTHING;
      END IF;
    ELSE
      -- Pas de reglage : la pause par defaut, au milieu de la duree prevue.
      SELECT g.type_public INTO v_type FROM public.groupes g WHERE g.id=NEW.groupe_id;
      v_pause := app_private.pause_duree_par_defaut(v_type);
      v_reste := GREATEST(0, coalesce(public.app_config_int('seance.pause_reste_minimum_minutes', 15), 15));
      v_debut_prevu := v_base + (NEW.ended_at - NEW.started_at) / 2;
      IF v_pause IS NOT NULL
         AND v_debut_prevu + pg_catalog.make_interval(mins => v_pause + v_reste) <= NEW.ended_at THEN
        INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
        VALUES(NEW.id,'programmee',v_pause,v_debut_prevu)
        ON CONFLICT(seance_id) DO NOTHING;
      ELSE
        INSERT INTO public.pause_seances(seance_id,statut,duree_prevue_minutes,debut_prevu_utc)
        VALUES(NEW.id,'non_prevue',5,NULL) ON CONFLICT(seance_id) DO NOTHING;
      END IF;
    END IF;
  END IF;
  IF TG_OP='UPDATE' AND OLD.status IS DISTINCT FROM NEW.status AND NEW.status IN ('ended','tech_failure') THEN
    UPDATE public.pause_seances SET
      statut=CASE WHEN statut='en_cours' THEN 'prise' WHEN statut='programmee' THEN 'non_prise' ELSE statut END,
      fin_utc=CASE WHEN statut IN ('en_cours','programmee') THEN pg_catalog.now() ELSE fin_utc END,
      updated_at=pg_catalog.now()
    WHERE seance_id=NEW.id AND statut IN ('en_cours','programmee');
  END IF;
  RETURN NEW;
END;
$function$;

-- ------------------------------------------------------------------
-- 8. Proprietaires et droits
-- ------------------------------------------------------------------
ALTER FUNCTION app_private.pause_duree_par_defaut(text) OWNER TO postgres;
ALTER FUNCTION public.pause_reglage_lire(uuid) OWNER TO postgres;
ALTER FUNCTION public.pause_etat_interne(uuid,uuid) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_refuser(uuid,text) OWNER TO postgres;
ALTER FUNCTION public.pause_seance_snapshot_trigger() OWNER TO postgres;

REVOKE ALL ON FUNCTION app_private.pause_duree_par_defaut(text) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_reglage_lire(uuid) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_etat_interne(uuid,uuid) FROM PUBLIC,anon,authenticated,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_refuser(uuid,text) FROM PUBLIC,anon,agent_ro,service_role;
REVOKE ALL ON FUNCTION public.pause_seance_snapshot_trigger() FROM PUBLIC,anon,authenticated,agent_ro,service_role;
GRANT EXECUTE ON FUNCTION public.pause_reglage_lire(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.pause_seance_refuser(uuid,text) TO authenticated;

COMMENT ON FUNCTION public.pause_seance_refuser(uuid,text) IS
  'PAUSE-SERVEUR (12/11/2026) : Non a la pause proposee. Enseignant titulaire de la seance en cours, compte valide, pause programmee ; refus_nombre + 1, prochaine proposition a now() + seance.pause_rappel_minutes ; idempotente (pause_idempotence, operation refuser).';

-- ------------------------------------------------------------------
-- 9. Verification
-- ------------------------------------------------------------------
DO $acl$
DECLARE
  v_role text;
BEGIN
  IF NOT has_function_privilege('authenticated','public.pause_seance_refuser(uuid,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_reglage_lire(uuid)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_etat(uuid)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_demarrer(uuid,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.pause_seance_terminer(uuid,text)','EXECUTE')
     OR has_function_privilege('authenticated','public.pause_etat_interne(uuid,uuid)','EXECUTE')
     OR has_function_privilege('authenticated','app_private.pause_duree_par_defaut(text)','EXECUTE') THEN
    RAISE EXCEPTION 'PAUSE-SERVEUR : ACL inattendue (authenticated)';
  END IF;
  FOREACH v_role IN ARRAY ARRAY['anon','public','agent_ro','service_role'] LOOP
    IF has_function_privilege(v_role,'public.pause_seance_refuser(uuid,text)','EXECUTE')
       OR has_function_privilege(v_role,'public.pause_reglage_lire(uuid)','EXECUTE')
       OR has_function_privilege(v_role,'public.pause_etat_interne(uuid,uuid)','EXECUTE')
       OR has_function_privilege(v_role,'app_private.pause_duree_par_defaut(text)','EXECUTE') THEN
      RAISE EXCEPTION 'PAUSE-SERVEUR : ACL inattendue (%)', v_role;
    END IF;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='pause_seances' AND column_name='refus_nombre')
     OR NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='pause_seances' AND column_name='prochaine_proposition_utc')
     OR NOT EXISTS (SELECT 1 FROM information_schema.columns
                  WHERE table_schema='public' AND table_name='pause_seances' AND column_name='motif')
     OR public.app_config_int('seance.pause_rappel_minutes', -1) < 0
     OR public.app_config_int('seance.pause_reste_minimum_minutes', -1) < 0 THEN
    RAISE EXCEPTION 'PAUSE-SERVEUR : colonnes ou reglages absents';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.pause_etat_interne(uuid,uuid)'::pg_catalog.regprocedure),
                       '''rappel_minutes''') = 0 THEN
    RAISE EXCEPTION 'PAUSE-SERVEUR : pause_etat_interne ne rend pas rappel_minutes';
  END IF;
END;
$acl$;

COMMIT;
