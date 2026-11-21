-- ANNONCES-SERVEUR (directeur, 21/11/2026, DECISION-ANNONCES-NOTIFS-2026-11-21.md, section 2 : le contrat).
-- « annonce jamais masquable ? [...] c'est faux » ; « il faut traduire automatiquement les annonces » ;
-- « ça s'empile [...] imagine si on a 100 annonces ».
--
-- Ce fichier COMPLETE ANNONCES-SIMPLES (20261126900000) ; il ne recree rien :
--
-- 1. `public.com_annonce_fermetures` : une annonce fermee par un lecteur (une ligne par lecteur et annonce ;
--    « rouvrir » remet `fermee` a faux, rien n'est jamais efface). RLS sans politique, aucun droit client.
-- 2. `public.com_annonce_traductions` : le titre et le texte d'une annonce dans chaque langue de
--    l'application (fr, en, ar), avec leur etat (a_faire, faite, originale, echec), leurs essais et la langue
--    detectee de l'original. Remplie au serveur, a l'envoi : un declencheur met en file chaque annonce
--    generale (groupe_id NULL) des son insertion ; la fonction Edge `courriels-envoi`, deja appelee chaque
--    minute par la tache unique, traduit par Google (`GOOGLE_TRADUCTION_CLE`) et consigne par deux fonctions
--    reservees a service_role. Un echec se rejoue (1, 4, 9... minutes, puis toutes les 6 h, 20 essais).
--    RLS sans politique, aucun droit client.
-- 3. `public.com_mes_annonces(p_limite, p_avant, p_langue, p_fermees)` : le fil selon le contrat, 20 par
--    defaut, 50 au plus, curseur `suite` (date de diffusion de la derniere annonce rendue, NULL a la fin),
--    texte dans la langue demandee ou celle du compte (`profiles.langue_communication`), original a cote,
--    jamais vide : l'original quand la traduction manque. `p_fermees = false` : les annonces non fermees.
--    NOTE : `p_limite` n'a pas de valeur par defaut dans la base. La forme sans argument
--    (`com_mes_annonces()`) existe deja et ne peut pas etre retiree (aucun mot d'effacement) : deux formes appelables
--    sans argument seraient ambigues. Les ecrans passent toujours `p_limite` ; la forme sans argument rend
--    l'ancien comportement (50 annonces, fermees comprises), avec les nouveaux champs, pour les
--    applications deja installees.
-- 4. `public.com_annonce_fermer(uuid)` et `public.com_annonce_rouvrir(uuid)`, idempotentes, reservees au
--    lecteur de l'annonce (meme porte que `com_annonce_vue`). Jamais un mineur (regle existante).
-- 5. Les annonces generales des 90 derniers jours sont mises en file une fois, pour etre traduites aussi.
--    Ce sont des textes de la direction, pas des donnees de personnes.
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : 0.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.com_annonces') IS NULL
     OR pg_catalog.to_regclass('public.com_annonce_lectures') IS NULL
     OR pg_catalog.to_regprocedure('public.com_mes_annonces()') IS NULL
     OR pg_catalog.to_regprocedure('private.com_annonce_lecteur()') IS NULL
     OR pg_catalog.to_regprocedure('private.com_annonce_generale_lisible(uuid,text)') IS NULL
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                     WHERE a.attrelid = 'public.profiles'::pg_catalog.regclass
                       AND a.attname = 'langue_communication' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR : installer d''abord ANNONCES-SIMPLES (20261126900000) et COURRIELS-2';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les tables
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.com_annonce_fermetures (
  annonce_id uuid NOT NULL REFERENCES public.com_annonces(id),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  fermee boolean NOT NULL DEFAULT true,
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (profile_id, annonce_id)
);

CREATE TABLE IF NOT EXISTS public.com_annonce_traductions (
  annonce_id uuid NOT NULL REFERENCES public.com_annonces(id),
  langue text NOT NULL CHECK (langue IN ('fr', 'en', 'ar')),
  titre text CHECK (titre IS NULL OR pg_catalog.length(titre) <= 400),
  texte text CHECK (texte IS NULL OR pg_catalog.length(texte) <= 20000),
  etat text NOT NULL DEFAULT 'a_faire' CHECK (etat IN ('a_faire', 'faite', 'originale', 'echec')),
  langue_source text CHECK (langue_source IS NULL OR langue_source ~ '^[a-z]{2,3}(-[A-Za-z]{2,4})?$'),
  essais integer NOT NULL DEFAULT 0 CHECK (essais >= 0),
  prochain_essai timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  reserve_le timestamptz,
  derniere_erreur text CHECK (derniere_erreur IS NULL OR pg_catalog.length(derniere_erreur) <= 300),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (annonce_id, langue),
  CHECK (etat <> 'faite' OR (titre IS NOT NULL AND texte IS NOT NULL AND pg_catalog.btrim(texte) <> ''))
);
CREATE INDEX IF NOT EXISTS com_annonce_traductions_a_faire
  ON public.com_annonce_traductions (prochain_essai) WHERE etat = 'a_faire';

ALTER TABLE public.com_annonce_fermetures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.com_annonce_traductions ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.com_annonce_fermetures, public.com_annonce_traductions
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON public.com_annonce_fermetures, public.com_annonce_traductions FROM agent_ro';
  END IF;
END
$agent_ro$;
COMMENT ON TABLE public.com_annonce_fermetures IS
  'ANNONCES-SERVEUR (21/11/2026) : les annonces fermees par chaque lecteur (fermee = faux apres « rouvrir » ; rien n''est efface). RLS sans policy : lue et ecrite par com_mes_annonces, com_annonce_fermer, com_annonce_rouvrir seulement.';
COMMENT ON TABLE public.com_annonce_traductions IS
  'ANNONCES-SERVEUR (21/11/2026) : titre et texte d''une annonce generale en fr, en, ar, traduits au serveur a l''envoi (Google, fonction Edge courriels-envoi). etat originale = la langue d''ecriture. RLS sans policy : ecrite par les fonctions reservees a service_role, lue par com_mes_annonces.';

-- ---------------------------------------------------------------------------
-- 2. La file de traduction : chaque annonce generale, des son insertion
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.com_annonce_traduction_enfiler()
RETURNS trigger LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  IF NEW.groupe_id IS NULL THEN
    INSERT INTO public.com_annonce_traductions (annonce_id, langue)
    SELECT NEW.id, l.langue FROM pg_catalog.unnest(ARRAY['fr', 'en', 'ar']) AS l(langue)
    ON CONFLICT (annonce_id, langue) DO NOTHING;
  END IF;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION private.com_annonce_traduction_enfiler() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.com_annonce_traduction_enfiler() FROM PUBLIC, anon, authenticated, service_role;

DO $declencheur$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.com_annonces'::pg_catalog.regclass
                    AND t.tgname = 'com_annonces_traduction_a_l_envoi') THEN
    CREATE TRIGGER com_annonces_traduction_a_l_envoi
      AFTER INSERT ON public.com_annonces
      FOR EACH ROW WHEN (NEW.groupe_id IS NULL)
      EXECUTE FUNCTION private.com_annonce_traduction_enfiler();
  END IF;
END
$declencheur$;

-- Les annonces generales encore lisibles (90 jours) entrent en file une fois.
INSERT INTO public.com_annonce_traductions (annonce_id, langue)
SELECT a.id, l.langue
  FROM public.com_annonces a
  CROSS JOIN pg_catalog.unnest(ARRAY['fr', 'en', 'ar']) AS l(langue)
 WHERE a.groupe_id IS NULL
   AND a.diffusee_le > pg_catalog.now() - interval '90 days'
ON CONFLICT (annonce_id, langue) DO NOTHING;

-- La porte du travailleur : service_role seulement (cle de service de la fonction Edge).
CREATE OR REPLACE FUNCTION private.com_annonce_travailleur()
RETURNS void LANGUAGE plpgsql STABLE SECURITY INVOKER SET search_path = '' AS $function$
BEGIN
  IF NOT (coalesce(auth.jwt() ->> 'role', '') = 'service_role'
          OR coalesce(pg_catalog.current_setting('role', true), '') = 'service_role') THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR reserve au travailleur' USING ERRCODE = '42501';
  END IF;
END;
$function$;
REVOKE ALL ON FUNCTION private.com_annonce_travailleur() FROM PUBLIC, anon, authenticated, service_role;

-- Reserve jusqu'a p_lot annonces a traduire. Une reservation de plus de dix minutes (travailleur tombe)
-- redevient disponible. Rend [{annonce_id, titre, texte, langues: [...], langue_source}].
CREATE OR REPLACE FUNCTION public.com_annonce_traductions_reserver(p_lot integer DEFAULT 5)
RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_ids uuid[];
BEGIN
  PERFORM private.com_annonce_travailleur();
  SELECT pg_catalog.array_agg(c.annonce_id) INTO v_ids FROM (
    SELECT t.annonce_id
      FROM public.com_annonce_traductions t
     WHERE t.etat = 'a_faire'
       AND t.prochain_essai <= pg_catalog.clock_timestamp()
       AND (t.reserve_le IS NULL OR t.reserve_le < pg_catalog.clock_timestamp() - interval '10 minutes')
     GROUP BY t.annonce_id
     ORDER BY pg_catalog.min(t.prochain_essai), t.annonce_id
     LIMIT LEAST(GREATEST(coalesce(p_lot, 5), 1), 20)
  ) c;
  IF v_ids IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;
  UPDATE public.com_annonce_traductions t
     SET reserve_le = pg_catalog.clock_timestamp(), essais = t.essais + 1, maj_le = pg_catalog.clock_timestamp()
   WHERE t.annonce_id = ANY (v_ids) AND t.etat = 'a_faire';
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'annonce_id', a.id, 'titre', a.titre, 'texte', a.texte,
             'langues', (SELECT pg_catalog.jsonb_agg(t.langue ORDER BY t.langue)
                           FROM public.com_annonce_traductions t
                          WHERE t.annonce_id = a.id AND t.etat = 'a_faire'),
             'langue_source', (SELECT pg_catalog.max(t.langue_source)
                                 FROM public.com_annonce_traductions t WHERE t.annonce_id = a.id))
             ORDER BY a.diffusee_le DESC)
      FROM public.com_annonces a WHERE a.id = ANY (v_ids)), '[]'::jsonb);
END;
$function$;

-- Consigne le resultat d'une annonce reservee. p_langue_source : la langue detectee de l'original ;
-- p_traductions : {"en": {"titre": "...", "texte": "..."}, ...} ; p_erreur : la cause d'un echec (les
-- langues non rendues sont rejouees plus tard). Rend le nombre de langues encore a faire.
CREATE OR REPLACE FUNCTION public.com_annonce_traduction_consigner(
  p_annonce_id uuid, p_langue_source text, p_traductions jsonb, p_erreur text)
RETURNS integer LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_source text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_langue_source, '')));
  v_tr jsonb := CASE WHEN pg_catalog.jsonb_typeof(p_traductions) = 'object' THEN p_traductions
                     ELSE '{}'::jsonb END;
  v_reste integer;
BEGIN
  PERFORM private.com_annonce_travailleur();
  IF p_annonce_id IS NULL THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR annonce absente' USING ERRCODE = '22023';
  END IF;
  IF v_source <> '' AND v_source !~ '^[a-z]{2,3}(-[a-z]{2,4})?$' THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR langue source invalide' USING ERRCODE = '22023';
  END IF;
  -- Le chinois et le portugais du Bresil arrivent avec une region : seule la langue compte ici.
  v_source := pg_catalog.split_part(v_source, '-', 1);

  IF v_source <> '' THEN
    UPDATE public.com_annonce_traductions t SET langue_source = v_source
     WHERE t.annonce_id = p_annonce_id;
    -- La langue d'ecriture n'est pas traduite : on sert l'original.
    UPDATE public.com_annonce_traductions t
       SET etat = 'originale', titre = NULL, texte = NULL, reserve_le = NULL,
           derniere_erreur = NULL, maj_le = pg_catalog.clock_timestamp()
     WHERE t.annonce_id = p_annonce_id AND t.langue = v_source AND t.etat = 'a_faire';
  END IF;

  UPDATE public.com_annonce_traductions t
     SET etat = 'faite',
         titre = pg_catalog.left(pg_catalog.btrim(v_tr -> t.langue ->> 'titre'), 400),
         texte = pg_catalog.left(pg_catalog.btrim(v_tr -> t.langue ->> 'texte'), 20000),
         reserve_le = NULL, derniere_erreur = NULL, maj_le = pg_catalog.clock_timestamp()
   WHERE t.annonce_id = p_annonce_id AND t.etat = 'a_faire'
     AND pg_catalog.btrim(coalesce(v_tr -> t.langue ->> 'texte', '')) <> ''
     AND (v_tr -> t.langue ->> 'titre') IS NOT NULL;

  -- Le reste est rejoue : 1, 4, 9... minutes, au plus toutes les 6 h ; au vingtieme essai, on arrete
  -- (l'original reste servi).
  UPDATE public.com_annonce_traductions t
     SET etat = CASE WHEN t.essais >= 20 THEN 'echec' ELSE 'a_faire' END,
         prochain_essai = pg_catalog.clock_timestamp() + pg_catalog.make_interval(mins => LEAST(t.essais * t.essais, 360)),
         reserve_le = NULL,
         derniere_erreur = pg_catalog.left(coalesce(nullif(pg_catalog.btrim(p_erreur), ''), 'traduction absente'), 300),
         maj_le = pg_catalog.clock_timestamp()
   WHERE t.annonce_id = p_annonce_id AND t.etat = 'a_faire';

  SELECT pg_catalog.count(*) INTO v_reste FROM public.com_annonce_traductions t
   WHERE t.annonce_id = p_annonce_id AND t.etat = 'a_faire';
  RETURN v_reste;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. Le fil de la personne, selon le contrat
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.com_mes_annonces(
  p_limite integer, p_avant timestamptz DEFAULT NULL, p_langue text DEFAULT NULL,
  p_fermees boolean DEFAULT false)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
  v_maintenant timestamptz := pg_catalog.clock_timestamp();
  v_limite integer := LEAST(GREATEST(coalesce(p_limite, 20), 1), 50);
  v_langue text := pg_catalog.lower(pg_catalog.btrim(coalesce(p_langue, '')));
  v_liste jsonb;
  v_nb integer;
  v_suite timestamptz;
BEGIN
  v_moi := private.com_annonce_lecteur();
  IF v_langue NOT IN ('fr', 'en', 'ar') THEN
    SELECT pg_catalog.lower(p.langue_communication) INTO v_langue
      FROM public.profiles p WHERE p.id = v_moi;
    IF v_langue IS NULL THEN
      v_langue := 'fr';
    ELSIF v_langue NOT IN ('fr', 'en', 'ar') THEN
      v_langue := NULL;   -- une langue que les annonces ne servent pas : l'original
    END IF;
  END IF;

  WITH page AS (
    SELECT x.id, x.titre, x.texte, x.diffusee_le,
           coalesce(f.fermee, false) AS fermee
      FROM public.com_annonces x
      LEFT JOIN public.com_annonce_fermetures f
        ON f.annonce_id = x.id AND f.profile_id = v_moi
     WHERE x.groupe_id IS NULL
       AND x.diffusee_le <= v_maintenant
       AND x.diffusee_le > v_maintenant - interval '90 days'
       AND (p_avant IS NULL OR x.diffusee_le < p_avant)
       AND (coalesce(p_fermees, false) OR NOT coalesce(f.fermee, false))
       AND private.com_annonce_generale_lisible(x.id, x.audience)
     ORDER BY x.diffusee_le DESC, x.id DESC
     LIMIT v_limite + 1
  ), rendue AS (
    SELECT p.*, pg_catalog.row_number() OVER (ORDER BY p.diffusee_le DESC, p.id DESC) AS rang
      FROM page p
  )
  SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', r.id,
           'titre', CASE WHEN tr.annonce_id IS NOT NULL THEN tr.titre ELSE r.titre END,
           'texte', CASE WHEN tr.annonce_id IS NOT NULL THEN tr.texte ELSE r.texte END,
           'titre_original', r.titre,
           'texte_original', r.texte,
           'langue_originale', (SELECT pg_catalog.max(s.langue_source)
                                  FROM public.com_annonce_traductions s WHERE s.annonce_id = r.id),
           'traduite', tr.annonce_id IS NOT NULL,
           'publiee_le', r.diffusee_le,
           'vue', EXISTS (SELECT 1 FROM public.com_annonce_lectures l
                           WHERE l.annonce_id = r.id AND l.profile_id = v_moi),
           'fermee', r.fermee)
           ORDER BY r.rang) FILTER (WHERE r.rang <= v_limite),
         pg_catalog.count(*),
         pg_catalog.max(r.diffusee_le) FILTER (WHERE r.rang = v_limite)
    INTO v_liste, v_nb, v_suite
    FROM rendue r
    LEFT JOIN public.com_annonce_traductions tr
      ON tr.annonce_id = r.id AND tr.langue = v_langue AND tr.etat = 'faite'
         AND pg_catalog.btrim(coalesce(tr.texte, '')) <> '';

  RETURN pg_catalog.jsonb_build_object(
    'annonces', coalesce(v_liste, '[]'::jsonb),
    'suite', CASE WHEN v_nb > v_limite THEN pg_catalog.to_jsonb(v_suite) ELSE 'null'::jsonb END);
END;
$function$;

-- La forme sans argument (applications deja installees) : l'ancien fil, 50 annonces, fermees comprises.
CREATE OR REPLACE FUNCTION public.com_mes_annonces()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $function$
BEGIN
  RETURN public.com_mes_annonces(50, NULL::timestamptz, NULL::text, true);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 4. Fermer et rouvrir (« تراجع »), idempotentes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.com_annonce_lisible_par_lecteur(p_annonce_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT EXISTS (SELECT 1 FROM public.com_annonces x
                  WHERE x.id = p_annonce_id AND x.groupe_id IS NULL
                    AND x.diffusee_le <= pg_catalog.clock_timestamp()
                    AND private.com_annonce_generale_lisible(x.id, x.audience));
$function$;
REVOKE ALL ON FUNCTION private.com_annonce_lisible_par_lecteur(uuid) FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.com_annonce_fermer(p_annonce_id uuid)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
BEGIN
  v_moi := private.com_annonce_lecteur();
  IF p_annonce_id IS NULL OR NOT private.com_annonce_lisible_par_lecteur(p_annonce_id) THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR annonce indisponible' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.com_annonce_fermetures (annonce_id, profile_id, fermee)
  VALUES (p_annonce_id, v_moi, true)
  ON CONFLICT (profile_id, annonce_id) DO UPDATE
    SET fermee = true, maj_le = pg_catalog.clock_timestamp()
    WHERE public.com_annonce_fermetures.fermee IS DISTINCT FROM true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.com_annonce_rouvrir(p_annonce_id uuid)
RETURNS void LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_moi uuid;
BEGIN
  v_moi := private.com_annonce_lecteur();
  IF p_annonce_id IS NULL OR NOT private.com_annonce_lisible_par_lecteur(p_annonce_id) THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR annonce indisponible' USING ERRCODE = '42501';
  END IF;
  UPDATE public.com_annonce_fermetures f
     SET fermee = false, maj_le = pg_catalog.clock_timestamp()
   WHERE f.profile_id = v_moi AND f.annonce_id = p_annonce_id AND f.fermee;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Droits, empreintes F86, postflight
-- ---------------------------------------------------------------------------
DO $acl$
DECLARE
  f text;
  v_client text[] := ARRAY[
    'public.com_mes_annonces(integer,timestamptz,text,boolean)',
    'public.com_mes_annonces()',
    'public.com_annonce_fermer(uuid)',
    'public.com_annonce_rouvrir(uuid)'];
  v_travailleur text[] := ARRAY[
    'public.com_annonce_traductions_reserver(integer)',
    'public.com_annonce_traduction_consigner(uuid,text,jsonb,text)'];
BEGIN
  FOREACH f IN ARRAY v_client || v_travailleur LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, authenticated, service_role', f);
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM agent_ro', f);
    END IF;
    IF f = ANY (v_client) THEN
      EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
        'F86: signature=' || f || '; md5_functiondef='
        || pg_catalog.md5(pg_catalog.pg_get_functiondef(f::pg_catalog.regprocedure))
        || '; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-11-21. '
        || 'ANNONCES-SERVEUR : lecteur adulte au compte actif ou candidat (private.com_annonce_lecteur) ; jamais un mineur ; '
        || 'fermer et rouvrir n''ecrivent que la ligne du lecteur dans com_annonce_fermetures.');
    ELSE
      EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO service_role', f);
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
        'F86: signature=' || f || '; md5_functiondef='
        || pg_catalog.md5(pg_catalog.pg_get_functiondef(f::pg_catalog.regprocedure))
        || '; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=a relire; date=2026-11-21. '
        || 'ANNONCES-SERVEUR : service_role seulement (private.com_annonce_travailleur), fonction Edge courriels-envoi ; '
        || 'n''ecrit que com_annonce_traductions.');
    END IF;
  END LOOP;
END
$acl$;

DO $postflight$
DECLARE
  f pg_catalog.regprocedure;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.com_mes_annonces(integer,timestamptz,text,boolean)'::pg_catalog.regprocedure,
    'public.com_mes_annonces()'::pg_catalog.regprocedure,
    'public.com_annonce_fermer(uuid)'::pg_catalog.regprocedure,
    'public.com_annonce_rouvrir(uuid)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'])
       OR coalesce(pg_catalog.obj_description(f, 'pg_proc'), '') NOT LIKE
            '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)) || '%' THEN
      RAISE EXCEPTION 'ANNONCES-SERVEUR : droits, DEFINER ou empreinte F86 invalides pour %', f;
    END IF;
  END LOOP;
  FOREACH f IN ARRAY ARRAY[
    'public.com_annonce_traductions_reserver(integer)'::pg_catalog.regprocedure,
    'public.com_annonce_traduction_consigner(uuid,text,jsonb,text)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT pg_catalog.has_function_privilege('service_role', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = f AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""']) THEN
      RAISE EXCEPTION 'ANNONCES-SERVEUR : la fonction du travailleur % est ouverte au client', f;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.com_annonce_fermetures', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.com_annonce_traductions', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.com_annonce_traductions', 'SELECT')
     OR pg_catalog.has_function_privilege('authenticated',
          'private.com_annonce_traduction_enfiler()'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR : une table ou la file est ouverte au client';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.com_annonces'::pg_catalog.regclass
                    AND t.tgname = 'com_annonces_traduction_a_l_envoi' AND t.tgenabled <> 'D') THEN
    RAISE EXCEPTION 'ANNONCES-SERVEUR : la mise en file a l''envoi est absente';
  END IF;
END
$postflight$;
