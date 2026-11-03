-- ANTI-ROBOT (03/11/2026), partie serveur. Fiche PLAN-LOTS §13
-- (docs/current/RELEVES-2026-11-02/PLAN-LOTS.md) ; decision du directeur du
-- 03/11 : « Oui pour la securite » (Cloudflare Turnstile et plafonds d'envoi).
--
-- Ce fichier :
--   1. reglage `securite.turnstile_cle_site` : la cle PUBLIQUE du widget
--      Turnstile, semee vide (vide = aucun controle cote client : le client se
--      livre avant l'activation), validee par un declencheur. La cle SECRETE ne
--      vient jamais ici : le directeur la pose dans Supabase (Authentication,
--      protection contre les attaques).
--   2. `public.turnstile_cle_site()` : lecture SANS compte de cette cle
--      publique (l'ecran de connexion la lit avant toute session).
--   3. un plafond horaire partage, `private.plafond_horaire`, compte dans la
--      table existante `public.rate_limits` (fenetre d'une heure, une ligne par
--      seau mise a jour, jamais effacee).
--   4. plafonds des portes qui ecrivent sans compte et n'en avaient pas de
--      cadence : `courriel_desinscrire` (par adresse et par heure) et
--      `avis_deposer` (par lien et par heure, en plus de `avis_max`). Deux
--      reglages de la console, valides par le meme declencheur.
--      Remplacements par ancres ; empreintes F86 mises a jour.
--
-- Preflight du 03/11/2026 (21:01 UTC, lecture seule) : les definitions de
-- production de courriel_desinscrire (md5 af0ee33b...) et avis_deposer (md5
-- ad34b1b0...) sont celles du depot (main fccd2f6b) ; `public.rate_limits`
-- (bucket PK, tokens, updated_at) est vide ; aucune cle `securite.%`.
-- Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : aucun.

-- ---------------------------------------------------------------------------
-- 1. Les reglages, et leur validation.
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value) VALUES
  ('securite.turnstile_cle_site', '""'::jsonb),
  ('securite.desinscription_par_heure', '10'::jsonb),
  ('securite.avis_par_heure_par_lien', '30'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.securite_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_texte text;
BEGIN
  IF NEW.key = 'securite.turnstile_cle_site' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'string' THEN
      RAISE EXCEPTION 'reglage de securite : un texte est attendu (la cle publique du site, ou vide)'
        USING ERRCODE = '22023';
    END IF;
    v_texte := pg_catalog.btrim(NEW.value #>> '{}');
    -- Une cle de site Cloudflare : un chiffre, « x », puis des lettres,
    -- chiffres, tirets ou soulignes ; ou vide (aucun controle).
    IF v_texte <> '' AND v_texte !~ '^[0-9]x[A-Za-z0-9_-]{16,96}$' THEN
      RAISE EXCEPTION 'reglage de securite : la cle publique du site n''a pas la forme attendue'
        USING ERRCODE = '22023';
    END IF;
    NEW.value := pg_catalog.to_jsonb(v_texte);
  ELSIF NEW.key IN ('securite.desinscription_par_heure', 'securite.avis_par_heure_par_lien') THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
       OR (NEW.value #>> '{}') !~ '^[1-9][0-9]{0,3}$'
       OR (NEW.value #>> '{}')::integer > 1000 THEN
      RAISE EXCEPTION 'reglage de securite : un entier de 1 a 1000 est attendu' USING ERRCODE = '22023';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
REVOKE ALL ON FUNCTION private.securite_reglages_valider() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER app_config_securite
  BEFORE INSERT OR UPDATE OF value ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.securite_reglages_valider();

-- ---------------------------------------------------------------------------
-- 2. La cle publique, lue sans compte.
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.turnstile_cle_site()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  -- Une cle publique : faite pour etre lue par le navigateur. Vide : null,
  -- l'ecran ne pose aucun controle.
  SELECT NULLIF(pg_catalog.btrim(c.value #>> '{}'), '')
    FROM public.app_config c
   WHERE c.key = 'securite.turnstile_cle_site';
$function$;
REVOKE ALL ON FUNCTION public.turnstile_cle_site() FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.turnstile_cle_site() FROM agent_ro';
  END IF;
END;
$agent_ro$;
GRANT EXECUTE ON FUNCTION public.turnstile_cle_site() TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Le plafond horaire partage.
-- ---------------------------------------------------------------------------
-- Une fenetre d'une heure par seau, dans `public.rate_limits` : la ligne du
-- seau est mise a jour (compte remis a 1 a l'heure suivante), jamais effacee.
-- Le seau ne porte aucune donnee en clair (l'appelant y met une empreinte).
-- Vrai tant que le compte de l'heure ne depasse pas p_max.
CREATE FUNCTION private.plafond_horaire(p_seau text, p_max integer)
RETURNS boolean
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $function$
DECLARE
  v_heure timestamptz := pg_catalog.date_trunc('hour', pg_catalog.now());
  v_compte real;
BEGIN
  IF p_seau IS NULL OR pg_catalog.length(p_seau) NOT BETWEEN 8 AND 200 OR p_max IS NULL OR p_max < 1 THEN
    RAISE EXCEPTION 'plafond horaire : seau et maximum attendus' USING ERRCODE = '22023';
  END IF;
  INSERT INTO public.rate_limits AS r (bucket, tokens, updated_at)
  VALUES ('plafond:' || p_seau, 1, v_heure)
  ON CONFLICT (bucket) DO UPDATE
    SET tokens = CASE WHEN r.updated_at < v_heure THEN 1 ELSE r.tokens + 1 END,
        updated_at = v_heure
  RETURNING r.tokens INTO v_compte;
  RETURN v_compte <= p_max;
END;
$function$;
REVOKE ALL ON FUNCTION private.plafond_horaire(text, integer) FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.plafond_horaire(text, integer) FROM agent_ro';
    EXECUTE 'REVOKE ALL ON FUNCTION private.securite_reglages_valider() FROM agent_ro';
  END IF;
END;
$agent_ro$;
COMMENT ON FUNCTION private.plafond_horaire(text, integer) IS
  'ANTI-ROBOT (03/11/2026) : plafond par seau et par heure, compte dans public.rate_limits (ligne mise a jour, jamais effacee). Vrai tant que le compte de l''heure ne depasse pas p_max.';

-- ---------------------------------------------------------------------------
-- 4. Les plafonds des deux portes sans compte (ancres).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- La desinscription : un plafond par adresse et par heure, compte une fois le
-- jeton reconnu (un jeton inconnu n'ecrit toujours rien). Au-dela, rien n'est
-- ecrit et la reponse le dit.
SELECT pg_temp.remplacer('public.courriel_desinscrire(text)',
  $a$  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  INSERT INTO public.courriel_desinscriptions (adresse, categorie)$a$,
  $b$  IF NOT FOUND THEN
    RETURN pg_catalog.jsonb_build_object('ok', false);
  END IF;
  -- ANTI-ROBOT (03/11/2026) : plafond par adresse et par heure (reglage
  -- securite.desinscription_par_heure).
  IF NOT private.plafond_horaire(
       'desinscription:' || pg_catalog.md5(pg_catalog.lower(v_j.adresse)),
       public.app_config_int('securite.desinscription_par_heure', 10)) THEN
    RETURN pg_catalog.jsonb_build_object('ok', false, 'plafond', true);
  END IF;
  INSERT INTO public.courriel_desinscriptions (adresse, categorie)$b$, 1);

-- L'avis : un plafond par lien et par heure, en plus du nombre d'avis du
-- lien ; meme erreur que tout autre echec du lien (aucun oracle).
SELECT pg_temp.remplacer('public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)',
  $a$    RAISE EXCEPTION 'lien indisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.avis $a$,
  $b$    RAISE EXCEPTION 'lien indisponible' USING ERRCODE = 'P0002';
  END IF;
  -- ANTI-ROBOT (03/11/2026) : plafond par lien et par heure (reglage
  -- securite.avis_par_heure_par_lien).
  IF NOT private.plafond_horaire('avis:' || v_lien.id::text,
       public.app_config_int('securite.avis_par_heure_par_lien', 30)) THEN
    RAISE EXCEPTION 'lien indisponible' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.avis $b$, 1);

-- ---------------------------------------------------------------------------
-- Empreintes F86.
-- ---------------------------------------------------------------------------
DO $empreintes$
DECLARE
  f regprocedure;
  v_com text;
BEGIN
  f := 'public.turnstile_cle_site()'::regprocedure;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f,
    'F86 candidate allowlist: signature=turnstile_cle_site(); md5_functiondef='
    || pg_catalog.md5(pg_catalog.pg_get_functiondef(f))
    || '; guard_type=PUBLIC_READ_WHITELIST; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-03. '
    || 'ANTI-ROBOT : la cle PUBLIQUE du widget Turnstile (securite.turnstile_cle_site), lue sans compte par l''ecran de connexion ; vide : null. Must-pass: supabase/tests/scenarios_anti_robot.sql.');
  FOREACH f IN ARRAY ARRAY['public.courriel_desinscrire(text)'::regprocedure,
                           'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure] LOOP
    v_com := pg_catalog.obj_description(f, 'pg_proc');
    IF v_com LIKE '%md5_functiondef=%' THEN
      v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
        'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
      IF pg_catalog.strpos(v_com, 'ANTI-ROBOT') = 0 THEN
        v_com := v_com || ' ANTI-ROBOT (03/11/2026) : plafond horaire (private.plafond_horaire). Must-pass: supabase/tests/scenarios_anti_robot.sql.';
      END IF;
      EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
    END IF;
  END LOOP;
END;
$empreintes$;

-- ---------------------------------------------------------------------------
-- Postflight.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF (SELECT pg_catalog.count(*) FROM public.app_config
       WHERE key IN ('securite.turnstile_cle_site', 'securite.desinscription_par_heure',
                     'securite.avis_par_heure_par_lien')) <> 3 THEN
    RAISE EXCEPTION 'anti-robot : les trois reglages manquent';
  END IF;
  IF NOT pg_catalog.has_function_privilege('anon', 'public.turnstile_cle_site()', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.plafond_horaire(text,integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', 'private.plafond_horaire(text,integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'anti-robot : droits d''execution inattendus';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.courriel_desinscrire(text)'::regprocedure),
                       'securite.desinscription_par_heure') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(
          'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure),
          'securite.avis_par_heure_par_lien') = 0 THEN
    RAISE EXCEPTION 'anti-robot : un plafond manque';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.oid IN ('public.turnstile_cle_site()'::regprocedure,
                              'public.courriel_desinscrire(text)'::regprocedure,
                              'public.avis_deposer(text,text,text,text,date,integer,text,text,boolean)'::regprocedure)
                AND coalesce(pg_catalog.obj_description(p.oid, 'pg_proc'), '')
                    NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid)) || '%') THEN
    RAISE EXCEPTION 'anti-robot : empreinte F86 perimee';
  END IF;
END;
$postflight$;
