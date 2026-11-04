-- M1-A8 (04/11/2026, PLAN-LOTS §7 rang 17) : retrait du serveur du « support
-- actif » en double. FICHIER B5 : il contient des DROP, il est colle par le
-- directeur dans l'editeur SQL, par la page du pilote. Ni le pilote ni un
-- agent ne l'appliquent.
--
-- Decision du directeur (03/11/2026, registre 08, mot pour mot) : « le retirer
-- et supprimer son backend si cela ne cause pas problème ».
--
-- Ce qui est retire, et rien d'autre (cinq fonctions de 20261016100400,
-- `support_actif_json` completee par 20261104600000) :
--   public.support_actif_capacites(uuid)
--   public.presenter_support(uuid, uuid, integer, text, jsonb)
--   public.support_actif(uuid)
--   app_private.support_actif_json(uuid)
--   app_private.support_refus(uuid, uuid)
--
-- Ce qui reste, et que ce fichier verifie intact : `public.session_shared_content`
-- (l'etat partage de la seance, lu par etat_partage_supabase.dart), sa
-- politique `ssc_participant_read` et sa publication temps reel.
--
-- Preuve « aucun lecteur » (relevee le 04/11/2026, lecture seule) :
--   * lib/, test/, tool/ : zero mention apres le lot M1-A8-lib (retrait de
--     SupportActifSupabase, du port, de la demo et de la surcharge de
--     main.dart), a fusionner AVANT ce fichier ;
--   * supabase/functions : aucune mention ; aucun cron ;
--   * production : pg_depend sans aucune vue ni politique dependante ; les
--     cinq fonctions ne s'appellent qu'entre elles ; journaux de l'API sur
--     24 h : 2168 requetes, 986 RPC, 0 appel a presenter_support ni
--     support_actif* ; track_functions = none (pas de compteur d'appels).
--
-- Sauvegarde : aucune. Les lignes de `pedagogie_partage_idempotence` d'operation
-- 'presenter_support' sont au nombre de 0 en production, et elles ne sont de
-- toute facon pas touchees.
--
-- Mots d'effacement : 5 (cinq DROP FUNCTION). Ni DELETE, ni TRUNCATE, ni
-- cron.unschedule. Aucun CASCADE : une dependance inattendue fait echouer le
-- fichier au lieu de l'emporter.

-- ---------------------------------------------------------------------------
-- Preflight : les cinq objets sont ceux qu'on a releves, et rien n'en depend.
-- ---------------------------------------------------------------------------
DO $preflight$
DECLARE
  v_attendu CONSTANT jsonb := '{
    "public.support_actif_capacites(uuid)": "2a395b9788e10a966c7d2145efef957c",
    "public.presenter_support(uuid,uuid,integer,text,jsonb)": "cd2b95a389ae401bbc78d920a6e3340f",
    "public.support_actif(uuid)": "0764f157433de7c9dce7800ea62c12e0",
    "app_private.support_actif_json(uuid)": "3098e7344bbde3adcd4d59612e2c2d6a",
    "app_private.support_refus(uuid,uuid)": "6726064555ead6822c730498472f0b2c"
  }'::jsonb;
  v_sig text;
  v_oid regprocedure;
  v_dependants text;
BEGIN
  FOR v_sig IN SELECT jsonb_object_keys(v_attendu) LOOP
    v_oid := pg_catalog.to_regprocedure(v_sig);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'M1-A8 preflight : % absente, rien a retirer ou base inattendue', v_sig;
    END IF;
    IF pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)) <> v_attendu ->> v_sig THEN
      RAISE EXCEPTION 'M1-A8 preflight : % ne correspond plus au releve (md5)', v_sig;
    END IF;
  END LOOP;

  -- Aucune dependance enregistree vers ces fonctions (vue, politique,
  -- declencheur, valeur par defaut...), hors leurs propres entrees internes.
  SELECT pg_catalog.string_agg(d.classid::regclass::text || ':' || d.objid::text, ', ')
    INTO v_dependants
    FROM pg_catalog.pg_depend d
   WHERE d.refclassid = 'pg_catalog.pg_proc'::regclass
     AND d.refobjid IN (SELECT pg_catalog.to_regprocedure(k)::oid
                          FROM pg_catalog.jsonb_object_keys(v_attendu) k)
     AND d.deptype <> 'i';
  IF v_dependants IS NOT NULL THEN
    RAISE EXCEPTION 'M1-A8 preflight : des objets dependent encore du support actif : %', v_dependants;
  END IF;

  -- Aucune autre fonction ne les appelle (hors les cinq elles-memes).
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
     WHERE p.oid NOT IN (SELECT pg_catalog.to_regprocedure(k)::oid
                           FROM pg_catalog.jsonb_object_keys(v_attendu) k)
       AND (p.prosrc LIKE '%support_actif_capacites%'
            OR p.prosrc LIKE '%presenter_support%'
            OR p.prosrc LIKE '%support_actif_json%'
            OR p.prosrc LIKE '%support_refus%'
            OR p.prosrc ~ 'support_actif\s*\(')) THEN
    RAISE EXCEPTION 'M1-A8 preflight : une autre fonction appelle encore le support actif';
  END IF;

  IF pg_catalog.to_regclass('public.session_shared_content') IS NULL THEN
    RAISE EXCEPTION 'M1-A8 preflight : session_shared_content absente, base inattendue';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- Le retrait
-- ---------------------------------------------------------------------------
DROP FUNCTION public.presenter_support(uuid, uuid, integer, text, jsonb);
DROP FUNCTION public.support_actif(uuid);
DROP FUNCTION public.support_actif_capacites(uuid);
DROP FUNCTION app_private.support_actif_json(uuid);
DROP FUNCTION app_private.support_refus(uuid, uuid);

-- ---------------------------------------------------------------------------
-- Postflight : les cinq objets absents, l'etat partage de la seance intact.
-- ---------------------------------------------------------------------------
DO $postflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.support_actif_capacites(uuid)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.presenter_support(uuid,uuid,integer,text,jsonb)') IS NOT NULL
     OR pg_catalog.to_regprocedure('public.support_actif(uuid)') IS NOT NULL
     OR pg_catalog.to_regprocedure('app_private.support_actif_json(uuid)') IS NOT NULL
     OR pg_catalog.to_regprocedure('app_private.support_refus(uuid,uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'M1-A8 postflight : une fonction du support actif existe encore';
  END IF;
  IF pg_catalog.to_regclass('public.session_shared_content') IS NULL THEN
    RAISE EXCEPTION 'M1-A8 postflight : session_shared_content a disparu';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                  WHERE schemaname = 'public' AND tablename = 'session_shared_content'
                    AND policyname = 'ssc_participant_read') THEN
    RAISE EXCEPTION 'M1-A8 postflight : la politique ssc_participant_read a disparu';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_publication WHERE pubname = 'supabase_realtime')
     AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_publication_tables
                      WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
                        AND tablename = 'session_shared_content') THEN
    RAISE EXCEPTION 'M1-A8 postflight : session_shared_content a quitte la publication temps reel';
  END IF;
END
$postflight$;
