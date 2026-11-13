-- SUIVI-ATTENTE (lot 1, 13/11/2026), suite de 20261123960000 et de
-- 20261123961000 : cinq choses, aucun mot d'effacement (applicable par
-- apply_migration).
--   1. « Tout est pret » previent la famille : notification et courriel, au tuteur
--      d'un mineur ou a l'eleve adulte, jamais a un enfant ;
--   2. les lignes de private.notification_courriel et de private.push_evenements
--      de ce nouvel evenement ;
--   3. public.demandes_formation_depassees() : le fait pour la direction (les
--      demandes envoyees depuis plus que le delai des reglages, sans classe), sans
--      relance automatique (lot FC-3, non construit) ;
--   4. l'export « mes donnees » porte les colonnes ajoutees a teacher_profiles par
--      20261123960000 (pays, mot, visibilite) ;
--   5. public.courriel_enfiler : garde serveur, AUCUN courriel n'est mis en file
--      pour un profil mineur, quel que soit le modele (arbitrage de
--      l'architecte, 13/11/2026) ; meme signature, memes droits, une seule
--      garde ajoutee ;
--   6. controles apres pose.
--
-- ORDRE : 20261123961000 d'abord. Ce fichier REFUSE de s'installer si la
-- contrainte des evenements ne contient pas encore `tout_est_pret` : installe
-- avant, il laisserait des seances, des eleves et des demandes se creer sans
-- que « Tout est pret » parte jamais pour elles (la notification est refusee par
-- la contrainte puis le fait est dedup par eleve et par classe). Gardee en
-- plus, la pose de la notification est faite dans un sous-bloc qui avertit et
-- n'echoue jamais (une seance, un eleve ou une demande ajoutes ne sont jamais
-- bloques par une notification).

DO $ordre$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_evenement_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''tout_est_pret''%') THEN
    RAISE EXCEPTION 'Installez d''abord 20261123961000_suivi_attente_evenement.sql : la contrainte des evenements de notification ne contient pas encore « tout_est_pret ». Sans elle, « Tout est pret » ne partirait jamais. Rien n''a ete change.';
  END IF;
END
$ordre$;

-- ---------------------------------------------------------------------------
-- 1. « Tout est pret » : une notification par eleve et par classe
-- ---------------------------------------------------------------------------
-- L'etape 5 du suivi : la classe est active et a son enseignant, la demande de
-- l'eleve est affectee (ou porte l'evenement), l'eleve est membre actif, et sa
-- premiere seance est a venir. La fonction est idempotente (une notification par
-- eleve et par classe, verrou par classe) : elle peut etre appelee depuis chaque
-- fait qui rapproche l'etape 5, dans n'importe quel ordre. Le destinataire d'un
-- mineur est son tuteur ; un enfant n'est jamais destinataire.
CREATE OR REPLACE FUNCTION private.suivi_attente_notifier_pret(p_groupe uuid)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_g public.groupes%ROWTYPE;
  v_n integer := 0;
BEGIN
  IF p_groupe IS NULL THEN
    RETURN 0;
  END IF;
  SELECT * INTO v_g FROM public.groupes g WHERE g.id = p_groupe;
  IF NOT FOUND OR v_g.teacher_id IS NULL OR v_g.ended_at IS NOT NULL
     OR v_g.etat <> 'active' THEN
    RETURN 0;
  END IF;
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('suivi_attente_pret:' || p_groupe::text, 0));
  BEGIN
    WITH eleves AS (
      SELECT d.eleve_id, d.type_public, p.household_id, p.first_name,
             h.timezone AS tz, h.primary_guardian_id,
             (SELECT min(s.started_at)
                FROM public.sessions s
               WHERE s.groupe_id = p_groupe
                 AND s.deleted_at IS NULL
                 AND s.status NOT IN ('canceled', 'canceled_late')
                 AND s.started_at > (SELECT min(gm.joined_at)
                                       FROM public.groupe_membres gm
                                      WHERE gm.groupe_id = p_groupe
                                        AND gm.student_id = d.eleve_id
                                        AND gm.left_at IS NULL)) AS premier
        FROM public.demandes_horaires_famille d
        JOIN public.profiles p ON p.id = d.eleve_id AND p.deleted_at IS NULL
        JOIN public.households h ON h.id = p.household_id
                                AND h.deleted_at IS NULL AND h.status = 'active'
       WHERE d.groupe_id = p_groupe
         AND d.etat NOT IN ('refusee', 'retiree')
         AND (d.etat = 'enseignant_affecte'
              OR EXISTS (SELECT 1 FROM public.demande_evenements e
                          WHERE e.demande_id = d.id AND e.type = 'enseignant_affecte'))
         AND EXISTS (SELECT 1 FROM public.groupe_membres gm
                      WHERE gm.groupe_id = p_groupe AND gm.student_id = d.eleve_id
                        AND gm.left_at IS NULL)
         AND NOT EXISTS (SELECT 1 FROM public.notifications n
                          WHERE n.evenement = 'tout_est_pret'
                            AND n.params ->> 'groupe_id' = p_groupe::text
                            AND n.params ->> 'eleve_id' = d.eleve_id::text)
    ), dest AS (
      -- L'eleve adulte, lui-meme.
      SELECT e.eleve_id AS destinataire, e.household_id AS foyer, 'soi'::text AS portee,
             e.tz, e.eleve_id, NULL::text AS prenom, e.premier
        FROM eleves e
       WHERE e.type_public = 'adulte' AND e.premier > pg_catalog.now()
      UNION ALL
      -- Les tuteurs du foyer d'un mineur : jamais l'enfant.
      SELECT t.id, e.household_id, 'foyer', e.tz, e.eleve_id, e.first_name, e.premier
        FROM eleves e
        JOIN public.profiles t ON t.deleted_at IS NULL
                              AND t.role = 'guardian'
                              AND (t.id = e.primary_guardian_id OR t.household_id = e.household_id)
       WHERE e.type_public <> 'adulte' AND e.premier > pg_catalog.now()
    )
    INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
    SELECT x.destinataire, x.foyer, 'tout_est_pret',
           pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
             'groupe_id', p_groupe,
             'eleve_id', x.eleve_id,
             'portee', x.portee,
             'classe', nullif(pg_catalog.btrim(v_g.libelle), ''),
             'fuseau', x.tz,
             'prochaine_local', pg_catalog.to_char(x.premier AT TIME ZONE x.tz,
                                                   'YYYY-MM-DD"T"HH24:MI:SS'),
             'eleves', CASE WHEN x.prenom IS NULL THEN NULL
                            ELSE pg_catalog.jsonb_build_array(x.prenom) END,
             -- Le prenom de l'enfant, pour le tuteur seulement : un tuteur de deux
             -- enfants dans la meme classe recoit deux notifications, chacune
             -- nommant son enfant. Pas `prenom` : le courriel salue le
             -- destinataire par cette cle.
             'eleve_prenom', x.prenom)),
           CASE x.portee WHEN 'soi' THEN '/eleve' ELSE '/tuteur/demandes' END
      FROM dest x;
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN OTHERS THEN
    -- Jamais d'echec ici : un fait de la classe ne depend pas d'un avis.
    RAISE WARNING 'tout_est_pret : notification non posee (%)', SQLERRM;
    v_n := 0;
  END;
  RETURN v_n;
END;
$function$;

REVOKE ALL ON FUNCTION private.suivi_attente_notifier_pret(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Le declencheur : un seul corps, quatre faits qui rapprochent l'etape 5.
CREATE OR REPLACE FUNCTION private.suivi_attente_pret_declencheur()
RETURNS trigger
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_groupe uuid;
BEGIN
  IF TG_TABLE_NAME = 'groupes' THEN
    v_groupe := NEW.id;
  ELSE
    v_groupe := (pg_catalog.to_jsonb(NEW) ->> 'groupe_id')::uuid;
  END IF;
  PERFORM private.suivi_attente_notifier_pret(v_groupe);
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.suivi_attente_pret_declencheur()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- Differes : ils lisent l'etat final de la transaction (membres, seances et
-- affectation poses dans le meme geste), comme notifier_classe.
DO $declencheurs$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.groupes'::regclass
                    AND t.tgname = 'z_suivi_attente_pret_groupes' AND NOT t.tgisinternal) THEN
    CREATE CONSTRAINT TRIGGER z_suivi_attente_pret_groupes
      AFTER UPDATE OF teacher_id, etat ON public.groupes
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW EXECUTE FUNCTION private.suivi_attente_pret_declencheur();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.groupe_membres'::regclass
                    AND t.tgname = 'z_suivi_attente_pret_membres' AND NOT t.tgisinternal) THEN
    CREATE CONSTRAINT TRIGGER z_suivi_attente_pret_membres
      AFTER INSERT ON public.groupe_membres
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW EXECUTE FUNCTION private.suivi_attente_pret_declencheur();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.sessions'::regclass
                    AND t.tgname = 'z_suivi_attente_pret_seances' AND NOT t.tgisinternal) THEN
    CREATE CONSTRAINT TRIGGER z_suivi_attente_pret_seances
      AFTER INSERT ON public.sessions
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW WHEN (NEW.groupe_id IS NOT NULL)
      EXECUTE FUNCTION private.suivi_attente_pret_declencheur();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.demandes_horaires_famille'::regclass
                    AND t.tgname = 'z_suivi_attente_pret_demandes' AND NOT t.tgisinternal) THEN
    CREATE CONSTRAINT TRIGGER z_suivi_attente_pret_demandes
      AFTER UPDATE OF etat, groupe_id ON public.demandes_horaires_famille
      DEFERRABLE INITIALLY DEFERRED
      FOR EACH ROW WHEN (NEW.groupe_id IS NOT NULL)
      EXECUTE FUNCTION private.suivi_attente_pret_declencheur();
  END IF;
END
$declencheurs$;

-- ---------------------------------------------------------------------------
-- 2. Courriel (trace) et categorie de push
-- ---------------------------------------------------------------------------
INSERT INTO private.notification_courriel (evenement, portee, courriel) VALUES
  ('tout_est_pret', 'soi', true),
  ('tout_est_pret', 'foyer', true)
ON CONFLICT (evenement, portee) DO UPDATE SET courriel = EXCLUDED.courriel;

DO $push$
BEGIN
  IF pg_catalog.to_regclass('private.push_evenements') IS NOT NULL THEN
    INSERT INTO private.push_evenements (evenement, categorie, tag)
    VALUES ('tout_est_pret', 'classes', NULL)
    ON CONFLICT (evenement) DO NOTHING;
  END IF;
END
$push$;

-- ---------------------------------------------------------------------------
-- 3. Le fait pour la direction : les demandes envoyees depuis trop longtemps
-- ---------------------------------------------------------------------------
-- Une demande « envoyee » (aucune classe confirmee) depuis plus de
-- `formation_delai_jours` jours (reglages, 14 par defaut de ce lot). Lecture
-- seule : aucune relance automatique, aucun message a la famille (lot FC-3).
-- Une valeur de reglage absente ou non entiere : aucune ligne (la direction ne
-- voit pas un retard qu'aucune regle ne definit).
CREATE OR REPLACE FUNCTION public.demandes_formation_depassees()
RETURNS TABLE (
  demande_id uuid,
  eleve_id uuid,
  prenom text,
  nom text,
  matricule text,
  type_public text,
  envoyee_le timestamptz,
  jours_depuis integer,
  motif_attente text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_delai integer;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'lecture reservee a la direction' USING ERRCODE = '42501';
  END IF;
  SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'number'
               AND (c.value #>> '{}') ~ '^[0-9]{1,3}$'
              THEN (c.value #>> '{}')::integer END
    INTO v_delai FROM public.app_config c WHERE c.key = 'formation_delai_jours';
  IF v_delai IS NULL THEN
    RETURN;
  END IF;
  RETURN QUERY
  SELECT d.id, d.eleve_id, p.first_name, p.last_name, p.immutable_id, d.type_public,
         coalesce(
           (SELECT min(e.survenu_le) FROM public.demande_evenements e
             WHERE e.demande_id = d.id AND e.type = 'envoyee'),
           d.created_at),
         pg_catalog.floor(extract(epoch FROM (pg_catalog.now() - coalesce(
           (SELECT min(e.survenu_le) FROM public.demande_evenements e
             WHERE e.demande_id = d.id AND e.type = 'envoyee'),
           d.created_at))) / 86400)::integer,
         (SELECT e.motif_attente FROM public.demande_evenements e
           WHERE e.demande_id = d.id AND e.type = 'en_attente'
           ORDER BY e.survenu_le DESC LIMIT 1)
    FROM public.demandes_horaires_famille d
    JOIN public.profiles p ON p.id = d.eleve_id AND p.deleted_at IS NULL
   WHERE d.etat = 'envoyee'
     AND coalesce(
           (SELECT min(e.survenu_le) FROM public.demande_evenements e
             WHERE e.demande_id = d.id AND e.type = 'envoyee'),
           d.created_at) < pg_catalog.now() - pg_catalog.make_interval(days => v_delai)
   ORDER BY 7, d.id;
END;
$function$;

ALTER FUNCTION public.demandes_formation_depassees() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.demandes_formation_depassees()
  FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.demandes_formation_depassees() TO authenticated;
COMMENT ON FUNCTION public.demandes_formation_depassees() IS
  'SUIVI-ATTENTE : les demandes envoyees depuis plus de formation_delai_jours jours, sans classe confirmee (lecture seule, aucune relance). guard=direction (admin) et compte valide.';

-- ---------------------------------------------------------------------------
-- 4. L'export « mes donnees » porte les colonnes de l'enseignant ajoutees par
--    20261123960000 (une retouche ancree du corps en place, comme
--    20261104900000 ; l'empreinte F86 est recalculee).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : ancre trouvee % fois dans %', v_n, p_fonction;
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_ancre, p_neuf);
  v_com := pg_catalog.obj_description(p_fonction, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_fonction)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_fonction, v_com);
  END IF;
END;
$$;

DO $export$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.mes_donnees_export()'::regprocedure),
                       'montre_aux_familles') > 0 THEN
    RAISE NOTICE 'export : colonnes de SUIVI-ATTENTE deja presentes, rien a faire';
  ELSE
    PERFORM pg_temp.remplacer('public.mes_donnees_export()'::regprocedure,
      $a$'titre', tp.titre, 'cree_le', tp.created_at)$a$,
      $b$'titre', tp.titre, 'pays_origine', tp.pays_origine,
                 'pays_residence', tp.pays_residence, 'mot_presentation', tp.mot_presentation,
                 'montre_aux_familles', tp.montre_aux_familles,
                 'montre_aux_familles_confirme_le', tp.montre_aux_familles_confirme_le,
                 'cree_le', tp.created_at)$b$);
  END IF;
END
$export$;

-- ---------------------------------------------------------------------------
-- 5. Aucun courriel n'est mis en file pour un mineur
-- ---------------------------------------------------------------------------
-- Un compte enfant est deja ecarte quand son compte d'authentification porte
-- `child_of` (adresse technique). Ce n'est pas une garantie suffisante : un profil
-- eleve mineur sans cette marque recevrait le courriel de n'importe quel modele
-- (prouve par la revue du 13/11 : `enseignant_affecte` en portee « soi »).
-- La garde est `private.com_est_mineur(p_profil)` : mineur si son profil eleve le
-- dit, et, **pour un profil eleve sans ligne `student_profiles`, mineur par
-- defaut** (refus quand on ne sait pas). Un tuteur, un enseignant, la direction
-- et un eleve adulte ne sont pas mineurs (scenario). LIMITE CONNUE : quand
-- `p_profil` est NULL (adresse tapee par la direction, invitations), aucun profil
-- n'est lu et la garde ne s'applique pas : laisse tel quel. Elle couvre aussi
-- les portees « soi » deja ecrites pour des eleves (classe_creee, classe_validee,
-- eleve_inscrit) : leur tuteur recoit son propre courriel par la portee « foyer ».
DO $courriel_mineur$
BEGIN
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef(
         'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure),
       'private.com_est_mineur(p_profil)') > 0 THEN
    RAISE NOTICE 'courriel_enfiler : garde des mineurs deja posee, rien a faire';
  ELSE
    PERFORM pg_temp.remplacer(
      'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure,
      $a$    -- Un compte enfant a une adresse technique : on ne lui ecrit jamais.$a$,
      $b$    -- Un mineur n'est jamais destinataire d'un courriel, quel que soit le modele
    -- (SUIVI-ATTENTE, 13/11/2026) : son tuteur est prevenu par la portee « foyer ».
    IF private.com_est_mineur(p_profil) THEN
      RETURN NULL;
    END IF;
    -- Un compte enfant a une adresse technique : on ne lui ecrit jamais.$b$);
  END IF;
END
$courriel_mineur$;

-- ---------------------------------------------------------------------------
-- 6. Controles apres pose
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_com text;
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.demandes_formation_depassees()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('public', 'public.demandes_formation_depassees()', 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', 'public.demandes_formation_depassees()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : droits invalides sur demandes_formation_depassees';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.suivi_attente_notifier_pret(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.suivi_attente_pret_declencheur()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les fonctions de notification ne s''appellent pas';
  END IF;
  IF (SELECT count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgname LIKE 'z_suivi_attente_pret_%' AND NOT t.tgisinternal) <> 4 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les quatre declencheurs de « tout est pret » ne sont pas poses';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.mes_donnees_export()'::regprocedure),
                       'montre_aux_familles') = 0 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l''export ne porte pas les colonnes de l''enseignant';
  END IF;
  v_com := pg_catalog.obj_description('public.mes_donnees_export()'::regprocedure, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(
           'public.mes_donnees_export()'::regprocedure))) = 0 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : empreinte F86 perimee pour mes_donnees_export';
  END IF;
  v_com := pg_catalog.obj_description(
    'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND pg_catalog.strpos(v_com, pg_catalog.md5(pg_catalog.pg_get_functiondef(
           'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)'::regprocedure))) = 0 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : empreinte F86 perimee pour courriel_enfiler';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon',
       'public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : courriel_enfiler doit rester interne';
  END IF;
END
$postflight$;
