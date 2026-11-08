-- HARMONISATION-B (08/11/2026), dette 3 du garde-cap (JOURNAL-GARDE-CAP 07/11
-- 22:25) : le plafond de 300 invitations de candidats importes par 24 heures
-- glissantes (lot 7, 20261120000000) devient un reglage de la direction.
--
-- 1. Le reglage. Une cle de la table des reglages (app_config, lecture et
--    ecriture par la seule direction active, journal app_config_history par
--    guard_app_config_history, comme les autres reglages) :
--      recrutement.invitations_candidats_jour   entier de 1 a 2000, 300 par defaut.
--    Pas de nouvelle table, pas de nouvelle RPC, pas de nouveau droit. Le semis
--    ne remplace jamais une valeur deja posee (ON CONFLICT DO NOTHING).
--
-- 2. La lecture. private.inv_cand_plafond_jour() rend la valeur si c'est un
--    entier de 1 a 2000 (nombre JSON entier, ou texte de chiffres) ; une cle
--    absente rend 300 sans bruit ; une valeur invalide rend 300 et leve un
--    WARNING qui nomme la cle et la plage, JAMAIS la valeur lue (garde-cap). Un
--    reglage mal ecrit ne bloque donc jamais l'envoi et ne l'ouvre jamais au-dela
--    de 2000. public.app_config_int n'est pas reutilisee : son ::int leve une
--    erreur sur une valeur non entiere au lieu de se replier.
--
-- 3. Les deux fonctions du lot 7 qui portaient la constante 300 la lisent :
--    apercu_invitations_candidats_importes (plafondJour, resteAujourdhui) et
--    envoyer_invitations_candidats_importes (refus plafond_atteint). Retouche par
--    ancre, une seule occurrence par fonction ; empreinte F86 rafraichie.
--
-- Preflight : les corps des deux fonctions sont ceux de 20261120000000 (md5 lus
-- sur une base neuve qui l'a rejouee, le 08/11) ; le pilote installe
-- 20261120000000 avant celle-ci. Aucun BEGIN/COMMIT au premier niveau, aucun
-- mot d'effacement, aucun texte d'erreur SQL recopie dans un WARNING. Aucun
-- envoi de courriel.

DO $preflight$
DECLARE
  v_apercu text := pg_catalog.md5(pg_catalog.pg_get_functiondef(
    'public.apercu_invitations_candidats_importes()'::regprocedure));
  v_envoyer text := pg_catalog.md5(pg_catalog.pg_get_functiondef(
    'public.envoyer_invitations_candidats_importes(integer,integer)'::regprocedure));
BEGIN
  IF v_apercu <> '1b0780c7b155fef6b149c82a690c0e05' THEN
    RAISE EXCEPTION 'HARMONISATION-B : apercu_invitations_candidats_importes a change depuis 20261120000000 (md5 %)', v_apercu;
  END IF;
  IF v_envoyer <> 'bd2fcf558006f717d7b88be389908209' THEN
    RAISE EXCEPTION 'HARMONISATION-B : envoyer_invitations_candidats_importes a change depuis 20261120000000 (md5 %)', v_envoyer;
  END IF;
  IF to_regclass('public.app_config') IS NULL THEN
    RAISE EXCEPTION 'HARMONISATION-B : la table des reglages manque';
  END IF;
END;
$preflight$;

-- Outil de la migration (detruit avec la session) : remplace une ancre, une
-- seule fois, puis rafraichit l'empreinte F86 du commentaire.
CREATE FUNCTION pg_temp.remplacer(p_fonction regprocedure, p_ancre text, p_neuf text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_fonction);
  v_n integer;
  v_com text;
BEGIN
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, p_ancre, '')))
         / pg_catalog.length(p_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'HARMONISATION-B : ancre trouvee % fois dans %', v_n, p_fonction;
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

-- ---------------------------------------------------------------------------
-- 1. Le reglage, semé a sa valeur par defaut.
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
VALUES ('recrutement.invitations_candidats_jour', pg_catalog.to_jsonb(300))
ON CONFLICT (key) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. La lecture, avec repli.
-- ---------------------------------------------------------------------------
CREATE FUNCTION private.inv_cand_plafond_jour()
RETURNS integer
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_valeur jsonb;
  v_texte text;
BEGIN
  SELECT c.value INTO v_valeur
    FROM public.app_config c
   WHERE c.key = 'recrutement.invitations_candidats_jour';
  IF NOT FOUND THEN
    RETURN 300;
  END IF;
  v_texte := v_valeur #>> '{}';
  -- Un entier ecrit en chiffres seuls (nombre JSON ou texte), de 1 a 2000.
  IF pg_catalog.jsonb_typeof(v_valeur) IN ('number', 'string')
     AND v_texte ~ '^[0-9]{1,4}$'
     AND v_texte::integer BETWEEN 1 AND 2000 THEN
    RETURN v_texte::integer;
  END IF;
  RAISE WARNING 'HARMONISATION-B : reglage recrutement.invitations_candidats_jour invalide (entier de 1 a 2000 attendu), repli a 300';
  RETURN 300;
END;
$function$;

ALTER FUNCTION private.inv_cand_plafond_jour() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.inv_cand_plafond_jour()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.inv_cand_plafond_jour() IS
  'HARMONISATION-B : le plafond du jour des invitations de candidats importes, lu dans '
  'app_config (recrutement.invitations_candidats_jour, entier de 1 a 2000) ; cle absente : 300 ; '
  'valeur invalide : 300 et WARNING sans la valeur. Aucun EXECUTE client.';

-- ---------------------------------------------------------------------------
-- 3. Les deux fonctions du lot 7 lisent le reglage.
-- ---------------------------------------------------------------------------
SELECT pg_temp.remplacer('public.apercu_invitations_candidats_importes()'::regprocedure,
  'v_plafond constant integer := 300;',
  'v_plafond constant integer := private.inv_cand_plafond_jour();');

SELECT pg_temp.remplacer('public.envoyer_invitations_candidats_importes(integer,integer)'::regprocedure,
  'v_plafond constant integer := 300;',
  'v_plafond constant integer := private.inv_cand_plafond_jour();');

-- La note F86 dit d'ou vient le plafond (l'empreinte vient d'etre rafraichie).
DO $note$
DECLARE
  v_sig regprocedure := 'public.envoyer_invitations_candidats_importes(integer,integer)'::regprocedure;
  v_com text := pg_catalog.obj_description(v_sig, 'pg_proc');
BEGIN
  IF pg_catalog.strpos(v_com, 'plafond propre de 300 par 24 h glissantes') = 0 THEN
    RAISE EXCEPTION 'HARMONISATION-B : note F86 de envoyer_invitations_candidats_importes inattendue';
  END IF;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_sig,
    pg_catalog.replace(v_com, 'plafond propre de 300 par 24 h glissantes',
      'plafond propre par 24 h glissantes (app_config recrutement.invitations_candidats_jour, 300 par defaut, 1 a 2000)'));
END;
$note$;

-- ---------------------------------------------------------------------------
-- 4. Controle final.
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT e.signature, p.*
    FROM (VALUES
      ('public.apercu_invitations_candidats_importes()'),
      ('public.envoyer_invitations_candidats_importes(integer,integer)')
    ) AS e(signature)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR pg_catalog.strpos(v.prosrc, 'private.inv_cand_plafond_jour()') = 0
       OR pg_catalog.strpos(v.prosrc, ':= 300;') > 0
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'HARMONISATION-B : fonction retouchee invalide : %', v.signature;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('authenticated', 'private.inv_cand_plafond_jour()'::regprocedure, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'private.inv_cand_plafond_jour()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'HARMONISATION-B : la lecture du plafond est ouverte aux comptes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_config c WHERE c.key = 'recrutement.invitations_candidats_jour') THEN
    RAISE EXCEPTION 'HARMONISATION-B : le reglage n est pas seme';
  END IF;
END;
$postflight$;
