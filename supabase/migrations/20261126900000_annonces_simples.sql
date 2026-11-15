-- ANNONCES-SIMPLES (directeur, 14/11/2026) : « perfectionner le systeme
-- d'annonce qui existe deja, qui permet d'envoyer un seul message a tout le
-- monde d'un coup, ou a travers des canaux specifiques […] Sinon on va devoir
-- continuer a envoyer des e-mails pour des petits trucs de rien du tout. »
--
-- Ce fichier FINIT le systeme existant (COM-BACK-1, 20261016090100 ; RACCORDEMENT
-- 20261016102300), il ne le recree pas : les annonces restent des lignes de
-- `public.com_annonces` (ajout seul), lues et marquees par les memes tables.
--
-- 1. Les publics, calcules ici et jamais dans l'application :
--      tous            tout le monde inscrit (comptes actifs adultes, et
--                      candidats en cours) ;
--      enseignants     enseignants actifs ;
--      candidats       candidatures enseignant en cours, avant la salle 3 ;
--      candidats_admis candidatures confirmees (salle 3), encore en cours ;
--      familles        parents et tuteurs actifs ;
--      eleves          eleves adultes, et le PARENT de chaque eleve mineur ;
--      eleves_adultes  eleves adultes seulement ;
--      hommes, femmes  filtres : ils restreignent les publics choisis (seuls,
--                      ils restreignent « tous »).
--    Les publics de groupe s'additionnent ; hommes et femmes les restreignent.
--    Separation CAND-Q07 : seul le super-admin (exception active) atteint les
--    deux cotes ; une direction d'un cote ne compte et n'atteint que le sien.
--    Une personne sans genre connu n'est atteinte que par le super-admin.
--
-- 2. Protection des mineurs (plus stricte qu'avant, jamais moins) : un mineur
--    n'est JAMAIS destinataire (ni annonce, ni notification, ni courriel, ni
--    push) ; un message « eleves » l'atteint par son parent ou tuteur
--    seulement. En plus, un compte mineur ne lit plus aucune annonce generale
--    (« toute l'academie », « familles ») : avant ce fichier il les lisait dans
--    sa Classe. Les annonces de SA Classe, publiees par son enseignant, ne
--    changent pas.
--
-- 3. Canaux : l'annonce dans l'application d'abord (fil `com_mes_annonces`,
--    ouvert aussi aux candidats, dont le compte est en attente), et une
--    notification pour les adultes au compte actif. Le courriel est une option :
--    categorie « nouvelles » (non essentielle, lien de desinscription), modele
--    « message_libre », donc sous le plafond non essentiel (reglages
--    courriels.non_essentiels_par_jour et _par_heure) ; l'audience dit combien
--    de jours prendra l'envoi, file d'attente comprise.
--    La notification utilise l'evenement « annonce_direction ». La contrainte
--    notifications_evenement_check ne le connait pas encore et ne s'elargit que
--    par un fichier a mot d'effacement, que ce lot n'ecrit pas (regle du pilote :
--    aucun DROP). Tant qu'elle ne l'accepte pas, la distribution le constate,
--    l'ecrit dans `com_annonce_envois.notifiees` (0) et continue : l'annonce
--    reste dans le fil, le courriel part s'il est demande.
--
-- 4. Une annonce programmee est distribuee (notifications, courriels) a son
--    heure par `private.com_annonce_distribuer`, appelee par la tache unique
--    `tache-minute` (R5 : aucune nouvelle tache par minute). Sans annonce en
--    attente, elle n'ecrit rien.
--
-- 5. Mesure : `com_annonces_direction()` rend, pour chaque annonce, le nombre
--    de destinataires et le nombre de personnes qui l'ont vue (lecture
--    enregistree par `com_annonce_vue`, ou par `com_annonce_marquer_lue`).
--
-- Retouches par ancres comptees (une fois et une seule, sinon arret) :
-- `com_annonces_academie`, `com_annonce_lire` (lecture des annonces generales)
-- et `private.tache_minute`. Leurs empreintes F86 sont recalculees.
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : 0.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.com_annonces') IS NULL
     OR pg_catalog.to_regprocedure('public.com_annonces_academie(uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.com_appelant_msg()') IS NULL
     OR pg_catalog.to_regprocedure('private.tache_minute()') IS NULL
     OR pg_catalog.to_regprocedure('public.courriel_enfiler(text,text,text,uuid,jsonb,text,text,uuid)') IS NULL
     OR pg_catalog.to_regprocedure('private.courriel_hors_plafond(boolean,text)') IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES : installer d''abord COM-BACK-1, RACCORDEMENT, MESSAGES-CANDIDAT, CANDIDATS-FLUX et IO-TACHE-MINUTE';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.com_annonce_envois (
  annonce_id uuid PRIMARY KEY REFERENCES public.com_annonces(id) ON DELETE RESTRICT,
  publics text[] NOT NULL CHECK (pg_catalog.cardinality(publics) BETWEEN 1 AND 9),
  cotes public.gender[] NOT NULL CHECK (pg_catalog.cardinality(cotes) BETWEEN 1 AND 2),
  destinataires integer NOT NULL CHECK (destinataires > 0),
  courriel boolean NOT NULL DEFAULT false,
  distribuee_le timestamptz,
  notifiees integer CHECK (notifiees >= 0),
  courriels integer CHECK (courriels >= 0)
);
CREATE INDEX IF NOT EXISTS com_annonce_envois_a_distribuer
  ON public.com_annonce_envois (annonce_id) WHERE distribuee_le IS NULL;

CREATE TABLE IF NOT EXISTS public.com_annonce_destinataires (
  annonce_id uuid NOT NULL REFERENCES public.com_annonces(id) ON DELETE RESTRICT,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  PRIMARY KEY (annonce_id, profile_id)
);
CREATE INDEX IF NOT EXISTS com_annonce_destinataires_profil
  ON public.com_annonce_destinataires (profile_id, annonce_id);

ALTER TABLE public.com_annonce_envois ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.com_annonce_destinataires ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_annonce_envois, public.com_annonce_destinataires
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.com_annonce_envois, public.com_annonce_destinataires FROM agent_ro';
  END IF;
END
$agent_ro$;
COMMENT ON TABLE public.com_annonce_envois IS
  'ANNONCES-SIMPLES (14/11/2026) : les publics, les cotes, le nombre de destinataires et la distribution d''une annonce de la direction. RLS sans policy : lue et ecrite par les RPC com_annonce* seulement.';
COMMENT ON TABLE public.com_annonce_destinataires IS
  'ANNONCES-SIMPLES (14/11/2026) : les destinataires d''une annonce de la direction, figes a l''envoi. Jamais un mineur. RLS sans policy.';

-- La notification d'une annonce part dans l'application seulement : le
-- courriel est l'option de la direction, jamais un second envoi automatique.
INSERT INTO private.notification_courriel (evenement, portee, courriel)
VALUES ('annonce_direction', '*', false)
ON CONFLICT (evenement, portee) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Les publics
-- ---------------------------------------------------------------------------
-- Les codes connus, dans l'ordre de l'ecran.
CREATE OR REPLACE FUNCTION private.com_annonce_codes()
RETURNS text[] LANGUAGE sql IMMUTABLE SET search_path = '' AS $function$
  SELECT ARRAY['tous', 'enseignants', 'candidats', 'candidats_admis', 'familles',
               'eleves', 'eleves_adultes', 'femmes', 'hommes']::text[];
$function$;

-- Les cotes que l'appelant atteint (CAND-Q07) : les deux pour le super-admin,
-- le sien pour une autre direction, aucun si son genre n'est pas connu.
CREATE OR REPLACE FUNCTION private.com_annonce_cotes()
RETURNS public.gender[] LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT CASE
    WHEN coalesce(public.kyc_super_admin_exception_active(), false)
      THEN ARRAY['female', 'male']::public.gender[]
    ELSE coalesce((SELECT ARRAY[p.gender] FROM public.profiles p
                    WHERE p.id = auth.uid() AND p.gender IS NOT NULL),
                  ARRAY[]::public.gender[])
  END;
$function$;

-- Les personnes d'une combinaison de publics, dans les cotes donnes. Jamais un
-- mineur, jamais un compte d'enfant (adresse technique), jamais un compte
-- supprime.
CREATE OR REPLACE FUNCTION private.com_annonce_personnes(p_publics text[], p_cotes public.gender[])
RETURNS TABLE (profile_id uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  WITH choix AS (
    SELECT coalesce(p_publics, ARRAY[]::text[]) AS tous_codes,
           ARRAY(SELECT c FROM pg_catalog.unnest(coalesce(p_publics, ARRAY[]::text[])) c
                  WHERE c NOT IN ('femmes', 'hommes')) AS groupes,
           ARRAY(SELECT CASE c WHEN 'femmes' THEN 'female' ELSE 'male' END::public.gender
                   FROM pg_catalog.unnest(coalesce(p_publics, ARRAY[]::text[])) c
                  WHERE c IN ('femmes', 'hommes')) AS genres
  ),
  personnes AS (
    SELECT p.id, p.role::text AS role, p.gender, p.household_id,
           (p.account_status::text IN ('active', 'provisional_active')
            AND (p.access_until IS NULL OR p.access_until > pg_catalog.now())) AS actif,
           private.com_est_mineur(p.id) AS mineur
      FROM public.profiles p
     WHERE p.deleted_at IS NULL
       AND NOT EXISTS (SELECT 1 FROM auth.users u
                        WHERE u.id = p.id AND u.raw_app_meta_data ? 'child_of')
  ),
  candidats AS (
    SELECT c.profile_id AS id, pg_catalog.bool_or(c.etape = 'confirmee') AS admis
      FROM public.candidatures c
     WHERE c.type_code = 'enseignant' AND c.profile_id IS NOT NULL AND c.issue = 'en_cours'
     GROUP BY c.profile_id
  ),
  -- Les foyers ou vit un eleve mineur actif : son parent recoit pour lui.
  foyers_mineurs AS (
    SELECT DISTINCT p.household_id
      FROM personnes p
     WHERE p.role = 'student' AND p.mineur AND p.actif AND p.household_id IS NOT NULL
  ),
  retenus AS (
    SELECT p.id, p.gender
      FROM personnes p, choix ch
     WHERE NOT p.mineur
       AND (
         -- « tous », ou un filtre de genre choisi seul.
         ((('tous' = ANY (ch.groupes)) OR pg_catalog.cardinality(ch.groupes) = 0)
           AND (p.actif OR EXISTS (SELECT 1 FROM candidats c WHERE c.id = p.id)))
         OR ('enseignants' = ANY (ch.groupes) AND p.role = 'teacher' AND p.actif)
         OR ('candidats' = ANY (ch.groupes)
             AND EXISTS (SELECT 1 FROM candidats c WHERE c.id = p.id AND NOT c.admis))
         OR ('candidats_admis' = ANY (ch.groupes)
             AND EXISTS (SELECT 1 FROM candidats c WHERE c.id = p.id AND c.admis))
         OR ('familles' = ANY (ch.groupes) AND p.role = 'guardian' AND p.actif)
         OR (('eleves' = ANY (ch.groupes) OR 'eleves_adultes' = ANY (ch.groupes))
             AND p.role = 'student' AND p.actif)
         OR ('eleves' = ANY (ch.groupes) AND p.role = 'guardian' AND p.actif
             AND p.household_id IN (SELECT f.household_id FROM foyers_mineurs f))
       )
       AND pg_catalog.cardinality(ch.tous_codes) > 0
  )
  SELECT r.id
    FROM retenus r, choix ch
   WHERE r.gender IS NOT NULL
     AND r.gender = ANY (coalesce(p_cotes, ARRAY[]::public.gender[]))
     AND (pg_catalog.cardinality(ch.genres) = 0 OR r.gender = ANY (ch.genres));
$function$;

-- Les publics recus, valides : codes connus, sans doublon, au moins un.
CREATE OR REPLACE FUNCTION private.com_annonce_publics_valides(p_publics text[])
RETURNS text[] LANGUAGE plpgsql IMMUTABLE SET search_path = '' AS $function$
DECLARE
  v text[];
BEGIN
  SELECT ARRAY(SELECT DISTINCT c FROM pg_catalog.unnest(coalesce(p_publics, ARRAY[]::text[])) c
                ORDER BY c) INTO v;
  IF pg_catalog.cardinality(v) = 0
     OR EXISTS (SELECT 1 FROM pg_catalog.unnest(v) c WHERE NOT (c = ANY (private.com_annonce_codes()))) THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES public inconnu' USING ERRCODE = '22023';
  END IF;
  RETURN v;
END;
$function$;

-- Ce que coute le courriel : adresses joignables, place sous le plafond, jours.
CREATE OR REPLACE FUNCTION private.com_annonce_courriel_estimation(p_personnes uuid[])
RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  WITH adresses AS (
    SELECT pg_catalog.count(*)::integer AS n
      FROM pg_catalog.unnest(coalesce(p_personnes, ARRAY[]::uuid[])) x(id)
      JOIN auth.users u ON u.id = x.id
     WHERE u.email IS NOT NULL AND pg_catalog.btrim(u.email) <> ''
       AND NOT EXISTS (SELECT 1 FROM public.courriel_desinscriptions d
                        WHERE d.adresse = pg_catalog.lower(pg_catalog.btrim(u.email))
                          AND d.categorie = 'nouvelles')
  ),
  file AS (
    SELECT pg_catalog.count(*)::integer AS n
      FROM public.courriels_sortants s
      JOIN public.courriel_categories c ON c.code = s.categorie
     WHERE s.statut IN ('en_attente', 'envoi')
       AND NOT private.courriel_hors_plafond(c.essentielle, s.modele)
  ),
  plafond AS (
    SELECT GREATEST(coalesce(public.app_config_int('courriels.non_essentiels_par_jour', 300), 300), 1) AS par_jour
  )
  SELECT pg_catalog.jsonb_build_object(
    'adresses', a.n,
    'en_file', f.n,
    'par_jour', pl.par_jour,
    'jours', CASE WHEN a.n = 0 THEN 0
                  ELSE pg_catalog.ceil((f.n + a.n)::numeric / pl.par_jour)::integer END)
    FROM adresses a, file f, plafond pl;
$function$;

REVOKE ALL ON FUNCTION private.com_annonce_codes(), private.com_annonce_cotes(),
  private.com_annonce_personnes(text[], public.gender[]),
  private.com_annonce_publics_valides(text[]),
  private.com_annonce_courriel_estimation(uuid[])
  FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 3. Les RPC de la direction
-- ---------------------------------------------------------------------------
-- La direction appelante (compte actif, role du jeton), sinon refus.
CREATE OR REPLACE FUNCTION private.com_annonce_direction_appelante()
RETURNS uuid LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $function$
DECLARE
  v uuid;
BEGIN
  SELECT a.id INTO v FROM private.com_appelant() a WHERE a.role = 'admin';
  IF v IS NULL OR NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES reserve a la direction' USING ERRCODE = '42501';
  END IF;
  RETURN v;
END;
$function$;
REVOKE ALL ON FUNCTION private.com_annonce_direction_appelante() FROM PUBLIC, anon, authenticated, service_role;

-- Les publics ouverts a la direction, chacun avec son nombre reel de
-- destinataires dans ses cotes.
CREATE OR REPLACE FUNCTION public.com_annonce_publics()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_cotes public.gender[];
BEGIN
  PERFORM private.com_annonce_direction_appelante();
  v_cotes := private.com_annonce_cotes();
  RETURN pg_catalog.jsonb_build_object(
    'cotes', pg_catalog.to_jsonb(v_cotes),
    'publics', (
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'code', c.code,
               'destinataires', (SELECT pg_catalog.count(*)
                                   FROM private.com_annonce_personnes(ARRAY[c.code], v_cotes)))
               ORDER BY c.rang)
        FROM pg_catalog.unnest(private.com_annonce_codes()) WITH ORDINALITY AS c(code, rang)
       -- Une direction d'un seul cote ne choisit pas un genre : il est deja le sien.
       WHERE c.code NOT IN ('femmes', 'hommes') OR pg_catalog.cardinality(v_cotes) = 2));
END;
$function$;

-- Le nombre exact de destinataires d'une combinaison, et ce que couterait le
-- courriel. Un public vide dit pourquoi (`raison`).
CREATE OR REPLACE FUNCTION public.com_annonce_audience(p_publics text[])
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_cotes public.gender[];
  v_publics text[];
  v_personnes uuid[];
BEGIN
  PERFORM private.com_annonce_direction_appelante();
  v_publics := private.com_annonce_publics_valides(p_publics);
  v_cotes := private.com_annonce_cotes();
  SELECT coalesce(pg_catalog.array_agg(x.profile_id), ARRAY[]::uuid[]) INTO v_personnes
    FROM private.com_annonce_personnes(v_publics, v_cotes) x;
  RETURN pg_catalog.jsonb_build_object(
    'publics', pg_catalog.to_jsonb(v_publics),
    'destinataires', pg_catalog.cardinality(v_personnes),
    'raison', CASE
      WHEN pg_catalog.cardinality(v_cotes) = 0 THEN 'cote_inconnu'
      WHEN pg_catalog.cardinality(v_personnes) = 0 THEN 'personne'
      ELSE NULL END,
    'courriel', private.com_annonce_courriel_estimation(v_personnes));
END;
$function$;

-- Distribue les annonces dont l'heure est venue : notification aux adultes au
-- compte actif, courriel si demande. Une fois par annonce (verrou, puis
-- `distribuee_le`). Appelee a l'envoi et par `tache-minute`.
CREATE OR REPLACE FUNCTION private.com_annonce_distribuer(p_annonce uuid DEFAULT NULL)
RETURNS integer LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_e record;
  v_notifiees integer;
  v_courriels integer;
  v_n integer := 0;
  v_role text;
  v_destination text;
  v_pose integer;
BEGIN
  FOR v_e IN
    SELECT e.annonce_id, e.courriel, a.titre, a.texte, a.auteur_id
      FROM public.com_annonce_envois e
      JOIN public.com_annonces a ON a.id = e.annonce_id
     WHERE e.distribuee_le IS NULL
       AND a.diffusee_le <= pg_catalog.clock_timestamp()
       AND (p_annonce IS NULL OR e.annonce_id = p_annonce)
     ORDER BY a.diffusee_le
     FOR UPDATE OF e SKIP LOCKED
  LOOP
    v_notifiees := 0;
    -- Une notification par role adulte : une destination refusee par la
    -- contrainte n'emporte pas les autres roles.
    FOREACH v_role IN ARRAY ARRAY['guardian', 'student', 'teacher', 'admin', 'controller'] LOOP
      v_destination := CASE v_role
        WHEN 'guardian' THEN '/tuteur'
        WHEN 'student' THEN '/eleve'
        WHEN 'teacher' THEN '/enseignant/journee'
        WHEN 'admin' THEN '/admin/alertes'
        ELSE '/controleur' END;
      BEGIN
        INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
        SELECT p.id,
               CASE WHEN p.role::text IN ('guardian', 'student') THEN p.household_id END,
               'annonce_direction',
               pg_catalog.jsonb_build_object(
                 'titre', v_e.titre,
                 'extrait', pg_catalog.left(v_e.texte, 400)),
               v_destination
          FROM public.com_annonce_destinataires d
          JOIN public.profiles p ON p.id = d.profile_id
         WHERE d.annonce_id = v_e.annonce_id
           AND p.role::text = v_role
           AND p.deleted_at IS NULL
           AND p.account_status::text IN ('active', 'provisional_active')
           AND NOT private.com_est_mineur(p.id);
        GET DIAGNOSTICS v_pose = ROW_COUNT;
        v_notifiees := v_notifiees + v_pose;
      EXCEPTION WHEN check_violation THEN
        -- L'evenement « annonce_direction » attend son fichier de contrainte :
        -- l'annonce reste dans le fil, rien d'autre n'est bloque.
        NULL;
      END;
    END LOOP;

    v_courriels := 0;
    IF v_e.courriel THEN
      SELECT pg_catalog.count(public.courriel_enfiler(
               'nouvelles', 'message_libre', public.courriel_adresse_profil(d.profile_id),
               d.profile_id,
               pg_catalog.jsonb_build_object('sujet', v_e.titre, 'corps', v_e.texte),
               'annonce:' || v_e.annonce_id::text || ':' || d.profile_id::text,
               'manuel', v_e.auteur_id))::integer
        INTO v_courriels
        FROM public.com_annonce_destinataires d
        JOIN public.profiles p ON p.id = d.profile_id
       WHERE d.annonce_id = v_e.annonce_id
         AND p.deleted_at IS NULL
         AND NOT private.com_est_mineur(p.id)
         AND public.courriel_adresse_profil(d.profile_id) IS NOT NULL;
    END IF;

    UPDATE public.com_annonce_envois
       SET distribuee_le = pg_catalog.clock_timestamp(),
           notifiees = v_notifiees,
           courriels = v_courriels
     WHERE annonce_id = v_e.annonce_id;
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$function$;
ALTER FUNCTION private.com_annonce_distribuer(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.com_annonce_distribuer(uuid) FROM PUBLIC, anon, authenticated, service_role;

-- Envoie (ou programme) une annonce de la direction. Rend l'accuse ; une cle
-- rejouee rend le meme accuse, sans second envoi.
CREATE OR REPLACE FUNCTION public.com_annonce_envoyer(
  p_publics text[], p_titre text, p_texte text, p_programmee_le timestamptz,
  p_courriel boolean, p_cle_idempotence uuid)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
  v_publics text[];
  v_cotes public.gender[];
  v_texte text := pg_catalog.btrim(coalesce(p_texte, ''));
  v_titre text := pg_catalog.btrim(coalesce(p_titre, ''));
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_ligne public.com_annonces%ROWTYPE;
  v_nb integer;
BEGIN
  v_moi := private.com_annonce_direction_appelante();
  IF p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES cle absente' USING ERRCODE = '22023';
  END IF;
  SELECT * INTO v_ligne FROM public.com_annonces a
   WHERE a.auteur_id = v_moi AND a.cle_idempotence = p_cle_idempotence;
  IF FOUND THEN
    RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
      'etat', CASE WHEN v_ligne.diffusee_le > v_maintenant THEN 'planifiee' ELSE 'publiee' END,
      'le', v_ligne.diffusee_le,
      'destinataires', (SELECT e.destinataires FROM public.com_annonce_envois e
                         WHERE e.annonce_id = v_ligne.id));
  END IF;
  v_publics := private.com_annonce_publics_valides(p_publics);
  IF v_texte = '' OR pg_catalog.length(v_texte) > 5000 OR pg_catalog.length(v_titre) > 120 THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES annonce invalide' USING ERRCODE = '22023';
  END IF;
  -- Le titre est facultatif : sans titre, le debut de la premiere ligne.
  IF v_titre = '' THEN
    v_titre := pg_catalog.btrim(pg_catalog.left(pg_catalog.split_part(v_texte, pg_catalog.chr(10), 1), 80));
  END IF;
  IF p_programmee_le IS NOT NULL
     AND (p_programmee_le < v_maintenant + interval '5 minutes'
          OR p_programmee_le > v_maintenant + interval '14 days') THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES date de diffusion hors bornes' USING ERRCODE = '22023';
  END IF;
  v_cotes := private.com_annonce_cotes();
  IF pg_catalog.cardinality(v_cotes) = 0 THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES cote inconnu' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.com_annonces
    (auteur_id, audience, groupe_id, titre, texte, diffusee_le, programmee, cle_idempotence)
  VALUES (v_moi, 'toutes', NULL, v_titre, v_texte,
          coalesce(p_programmee_le, v_maintenant), p_programmee_le IS NOT NULL, p_cle_idempotence)
  RETURNING * INTO v_ligne;

  INSERT INTO public.com_annonce_destinataires (annonce_id, profile_id)
  SELECT v_ligne.id, x.profile_id FROM private.com_annonce_personnes(v_publics, v_cotes) x;
  GET DIAGNOSTICS v_nb = ROW_COUNT;
  IF v_nb = 0 THEN
    -- Un public vide ne s'envoie pas : tout est annule.
    RAISE EXCEPTION 'ANNONCES-SIMPLES aucun destinataire' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.com_annonce_envois (annonce_id, publics, cotes, destinataires, courriel)
  VALUES (v_ligne.id, v_publics, v_cotes, v_nb, coalesce(p_courriel, false));

  PERFORM public.log_sensitive_access('com_annonce_envoyer', 'com_annonces', v_ligne.id::text,
    pg_catalog.jsonb_build_object('publics', v_publics, 'destinataires', v_nb,
                                  'courriel', coalesce(p_courriel, false)));

  IF p_programmee_le IS NULL THEN
    PERFORM private.com_annonce_distribuer(v_ligne.id);
  END IF;

  RETURN pg_catalog.jsonb_build_object('id', v_ligne.id,
    'etat', CASE WHEN v_ligne.programmee THEN 'planifiee' ELSE 'publiee' END,
    'le', v_ligne.diffusee_le,
    'destinataires', v_nb);
END;
$function$;

-- Les annonces de la direction (30 derniers jours et a venir), avec leur
-- mesure : destinataires et personnes qui l'ont vue. Une direction d'un cote
-- ne voit que les annonces de son cote, et les annonces d'avant ce lot.
CREATE OR REPLACE FUNCTION public.com_annonces_direction()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_cotes public.gender[];
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  PERFORM private.com_annonce_direction_appelante();
  v_cotes := private.com_annonce_cotes();
  RETURN (
    WITH a AS (
      SELECT x.id, x.diffusee_le, pg_catalog.jsonb_build_object(
        'id', x.id, 'titre', x.titre, 'texte', x.texte, 'le', x.diffusee_le,
        'etat', CASE WHEN x.diffusee_le > v_maintenant THEN 'planifiee' ELSE 'publiee' END,
        'publics', CASE WHEN e.annonce_id IS NULL THEN NULL ELSE pg_catalog.to_jsonb(e.publics) END,
        'courriel', coalesce(e.courriel, false),
        'destinataires', e.destinataires,
        'vues', CASE WHEN e.annonce_id IS NULL
                  THEN (SELECT pg_catalog.count(*) FROM public.com_annonce_lectures l
                         WHERE l.annonce_id = x.id)
                  ELSE (SELECT pg_catalog.count(*) FROM public.com_annonce_lectures l
                          JOIN public.com_annonce_destinataires d
                            ON d.annonce_id = l.annonce_id AND d.profile_id = l.profile_id
                         WHERE l.annonce_id = x.id) END,
        'cible', CASE WHEN e.annonce_id IS NOT NULL THEN NULL
          WHEN x.audience = 'classe'
          THEN pg_catalog.jsonb_build_object('id', 'classe:' || g.id::text, 'nature', 'classe',
                 'classe_id', g.id, 'libelle', g.libelle)
          ELSE pg_catalog.jsonb_build_object('id', x.audience,
                 'nature', CASE x.audience WHEN 'toutes' THEN 'toutes' ELSE 'public' END,
                 'libelle', x.audience) END) AS j
      FROM public.com_annonces x
      LEFT JOIN public.groupes g ON g.id = x.groupe_id
      LEFT JOIN public.com_annonce_envois e ON e.annonce_id = x.id
      WHERE x.diffusee_le > v_maintenant - interval '30 days'
        AND (e.annonce_id IS NULL OR e.cotes <@ v_cotes)
    )
    SELECT pg_catalog.jsonb_build_object(
      'publiees', coalesce((SELECT pg_catalog.jsonb_agg(a.j ORDER BY a.diffusee_le DESC, a.id DESC)
                              FROM a WHERE a.diffusee_le <= v_maintenant), '[]'::jsonb),
      'planifiees', coalesce((SELECT pg_catalog.jsonb_agg(a.j ORDER BY a.diffusee_le, a.id)
                                FROM a WHERE a.diffusee_le > v_maintenant), '[]'::jsonb)));
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Le fil de la personne (adultes au compte actif, et candidats)
-- ---------------------------------------------------------------------------
-- L'appelant du fil : un compte actif adulte, ou un candidat en attente. Un
-- mineur n'a pas de fil d'annonces de la direction.
CREATE OR REPLACE FUNCTION private.com_annonce_lecteur()
RETURNS uuid LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $function$
DECLARE
  v uuid;
BEGIN
  SELECT a.id INTO v FROM private.com_appelant_msg() a LIMIT 1;
  IF v IS NULL OR private.com_est_mineur(v) THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES non autorise' USING ERRCODE = '42501';
  END IF;
  RETURN v;
END;
$function$;
REVOKE ALL ON FUNCTION private.com_annonce_lecteur() FROM PUBLIC, anon, authenticated, service_role;

-- Une annonce generale lisible par l'appelant : jamais par un mineur ; une
-- annonce de la direction par ses destinataires (et la direction) ; une
-- annonce d'avant ce lot selon sa regle d'origine.
CREATE OR REPLACE FUNCTION private.com_annonce_generale_lisible(p_id uuid, p_audience text)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT CASE
    WHEN auth.uid() IS NULL OR private.com_est_mineur(auth.uid()) THEN false
    WHEN EXISTS (SELECT 1 FROM public.com_annonce_envois e WHERE e.annonce_id = p_id) THEN
      EXISTS (SELECT 1 FROM public.com_annonce_destinataires d
               WHERE d.annonce_id = p_id AND d.profile_id = auth.uid())
      OR coalesce(public.app_role()::text = 'admin' AND public.app_account_valid(), false)
    ELSE coalesce(private.com_lit_annonce_generale(p_audience), false)
  END;
$function$;
REVOKE ALL ON FUNCTION private.com_annonce_generale_lisible(uuid, text) FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.com_mes_annonces()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
BEGIN
  v_moi := private.com_annonce_lecteur();
  RETURN pg_catalog.jsonb_build_object('annonces', coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', a.id, 'titre', a.titre, 'texte', a.texte, 'publiee_le', a.diffusee_le,
             'vue', EXISTS (SELECT 1 FROM public.com_annonce_lectures l
                             WHERE l.annonce_id = a.id AND l.profile_id = v_moi))
             ORDER BY a.diffusee_le DESC, a.id DESC)
      FROM (
        SELECT x.* FROM public.com_annonces x
         WHERE x.groupe_id IS NULL
           AND x.diffusee_le <= v_maintenant
           AND x.diffusee_le > v_maintenant - interval '90 days'
           AND private.com_annonce_generale_lisible(x.id, x.audience)
         ORDER BY x.diffusee_le DESC, x.id DESC
         LIMIT 50
      ) a), '[]'::jsonb));
END;
$function$;

-- Enregistre que la personne a vu l'annonce (la mesure de la direction).
CREATE OR REPLACE FUNCTION public.com_annonce_vue(p_annonce_id uuid)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
BEGIN
  v_moi := private.com_annonce_lecteur();
  IF NOT EXISTS (SELECT 1 FROM public.com_annonces x
                  WHERE x.id = p_annonce_id AND x.groupe_id IS NULL
                    AND x.diffusee_le <= pg_catalog.clock_timestamp()
                    AND private.com_annonce_generale_lisible(x.id, x.audience)) THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES annonce indisponible' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.com_annonce_lectures (annonce_id, profile_id)
  VALUES (p_annonce_id, v_moi)
  ON CONFLICT (annonce_id, profile_id) DO NOTHING;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Retouches par ancres : la lecture des annonces generales, la tache unique
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.retoucher(p_f pg_catalog.regprocedure, p_marque text,
                                             p_avant text, p_apres text)
RETURNS void LANGUAGE plpgsql AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
  v_avant record;
  v_note text;
BEGIN
  IF pg_catalog.strpos(v_def, p_marque) > 0 THEN
    RAISE NOTICE '% : deja retouchee', p_f;
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> 1 THEN
    RAISE EXCEPTION '% : ancre trouvee % fois au lieu de 1 : %', p_f, v_n, pg_catalog.left(p_avant, 120);
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = p_f;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = p_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION '% : proprietaire, droits ou attributs modifies', p_f;
  END IF;
  -- L'empreinte F86 suit le nouveau corps.
  v_note := pg_catalog.obj_description(p_f, 'pg_proc');
  IF v_note LIKE '%md5_functiondef=%' THEN
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f,
      pg_catalog.regexp_replace(v_note, 'md5_functiondef=[0-9a-f]{32}',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f))));
  END IF;
END;
$function$;

SELECT pg_temp.retoucher('public.com_annonces_academie(uuid)'::regprocedure,
  'com_annonce_generale_lisible',
  $a$AND private.com_lit_annonce_generale(a.audience)$a$,
  $a$AND private.com_annonce_generale_lisible(a.id, a.audience)$a$);

SELECT pg_temp.retoucher('public.com_annonce_lire(uuid)'::regprocedure,
  'com_annonce_generale_lisible',
  $a$IF NOT private.com_lit_annonce_generale(v_audience) THEN RETURN NULL; END IF;$a$,
  $a$IF NOT private.com_annonce_generale_lisible(p_annonce_id, v_audience) THEN RETURN NULL; END IF;$a$);

SELECT pg_temp.retoucher('private.tache_minute()'::regprocedure,
  'com_annonce_distribuer',
  $a$  IF v_echecs <> '' THEN$a$,
  $a$  -- ANNONCES-SIMPLES (14/11/2026) : les annonces dont l'heure est venue.
  -- Rien a ecrire tant qu'aucune n'attend.
  BEGIN
    PERFORM private.com_annonce_distribuer(NULL);
  EXCEPTION WHEN OTHERS THEN
    v_echecs := v_echecs || 'annonces : ' || SQLERRM || E'\n';
  END;
  IF v_echecs <> '' THEN$a$);

-- ---------------------------------------------------------------------------
-- 6. Droits, empreintes F86, postflight
-- ---------------------------------------------------------------------------
DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_annonce_publics()',
    'public.com_annonce_audience(text[])',
    'public.com_annonce_envoyer(text[],text,text,timestamptz,boolean,uuid)',
    'public.com_annonces_direction()',
    'public.com_mes_annonces()',
    'public.com_annonce_vue(uuid)'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role', f);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', f);
    END IF;
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
      'F86: signature=' || f || '; md5_functiondef='
      || pg_catalog.md5(pg_catalog.pg_get_functiondef(f::pg_catalog.regprocedure))
      || '; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-11-14. '
      || 'ANNONCES-SIMPLES : direction active (publics, audience, envoi, liste), ou lecteur adulte et candidat (fil, vue) ; jamais un mineur.');
  END LOOP;
END
$acl$;

DO $postflight$
DECLARE
  f pg_catalog.regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_annonce_publics()'::pg_catalog.regprocedure,
    'public.com_annonce_audience(text[])'::pg_catalog.regprocedure,
    'public.com_annonce_envoyer(text[],text,text,timestamptz,boolean,uuid)'::pg_catalog.regprocedure,
    'public.com_annonces_direction()'::pg_catalog.regprocedure,
    'public.com_mes_annonces()'::pg_catalog.regprocedure,
    'public.com_annonce_vue(uuid)'::pg_catalog.regprocedure,
    'public.com_annonces_academie(uuid)'::pg_catalog.regprocedure,
    'public.com_annonce_lire(uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(f, 'pg_proc'), '') NOT LIKE
            '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ANNONCES-SIMPLES : droits, DEFINER ou empreinte F86 invalides pour %', f;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.com_annonce_distribuer(uuid)'::pg_catalog.regprocedure, 'EXECUTE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_annonce_destinataires', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_annonce_envois', 'SELECT') THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES : une table ou la distribution est ouverte au client';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.tache_minute()'::pg_catalog.regprocedure),
                       'com_annonce_distribuer') = 0 THEN
    RAISE EXCEPTION 'ANNONCES-SIMPLES : la tache unique ne distribue pas les annonces';
  END IF;
END
$postflight$;
