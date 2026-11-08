-- NOTIF-RETENU (08/11/2026, ordre du directeur relaye par le pilote le 07/11 vers
-- 23:59 UTC ; conditions du garde-cap, reservation 20261121000000-099999) :
-- « Vous etes retenu pour un entretien » dans l'application, POSEE AU MEME
-- ENDROIT que le courriel du meme nom : `admettre_salle_verification`
-- (transition 10), juste apres le courriel de SALLE-1 (20261119100000). UN SEUL
-- circuit : pas de declencheur sur candidatures (il partirait aussi par d'autres
-- chemins et doublerait au rejeu). Le rejeu du geste rend le resultat memorise
-- avant d'arriver ici (cle d'idempotence du geste) ; une admission refusee
-- (controles, conflit de version) sort avant : ni l'un ni l'autre ne pose de
-- notification.
--
-- Trois choses :
--   1. remplacement ANCRE dans public.admettre_salle_verification(uuid,integer,text) :
--      apres le courriel, une notification `retenu_entretien` pour la candidate
--      (destination /attente/entretien). Elle ne depend pas de l'adresse. Un echec de
--      la notification n'empeche JAMAIS l'admission : sous-bloc, avertissement,
--      journal de PUSH-1 s'il est installe ;
--   2. la fiche F86 de la fonction : empreinte md5_functiondef relue, ce qui change
--      ajoute a la fin ;
--   3. une ligne dans private.push_evenements : categorie `admissions` (« Demandes et
--      dossiers »), que la personne peut couper.
-- Aucune ligne dans private.notification_courriel : depuis FN-114a (20261103700000),
-- un evenement absent de cette table ne part PAS par courriel (application seulement) ;
-- cette notification n'enfile donc aucun second courriel (prouve par le scenario).
--
-- PREFLIGHT : md5(prosrc) de la fonction relue sur une base rejouee depuis main 225a957d
-- le 08/11 ; a verifier en production par le pilote avant l'application (lecture seule) :
--   SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
--    WHERE p.oid = 'public.admettre_salle_verification(uuid,integer,text)'::regprocedure;
--   attendu : e3c42f075a31014747a1a9fb2e5cd68d
-- Rejouable : deja applique, le preflight le dit et rien n'est refait.
--
-- PUSH : le push ne part que si le compte est autorise (private.push_compte_autorise :
-- `active` ou `provisional_active`). Un candidat est `pending_kyc` : il recoit la
-- notification dans l'application, PAS sur l'appareil, tant que cette regle ne change
-- pas (decision du directeur, hors de ce lot).
--
-- Preconditions : 20261121000000 (evenement dans la contrainte), 20261119100000
-- (courriel de SALLE-1), 20261119200000 (destination /attente/entretien), PUSH-1.
-- Sinon la migration s'arrete et le dit.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement : applicable par
-- apply_migration.

DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_evenement_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''retenu_entretien''%') THEN
    RAISE EXCEPTION 'retenu_entretien : installer d''abord 20261121000000_notif_retenu_evenement.sql';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.notifications'::regclass
          AND c.conname = 'notifications_destination_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''/attente/entretien''%') THEN
    RAISE EXCEPTION 'retenu_entretien : la destination /attente/entretien manque (installer 20261119200000)';
  END IF;
  IF pg_catalog.to_regclass('private.push_evenements') IS NULL THEN
    RAISE EXCEPTION 'retenu_entretien : PUSH-1 n''est pas installe';
  END IF;
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5 FROM pg_catalog.pg_proc p
   WHERE p.oid = 'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(
       'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure),
       'NOTIF-RETENU (08/11/2026)') > 0 THEN
    RAISE NOTICE 'retenu_entretien : deja applique, rien n''est refait';
  ELSIF v_md5 IS DISTINCT FROM 'e3c42f075a31014747a1a9fb2e5cd68d' THEN
    RAISE EXCEPTION 'retenu_entretien : admettre_salle_verification a change (md5 %), migration a revoir', v_md5;
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, p_apres) > 0 THEN
    RETURN;  -- deja remplace (rejeu)
  END IF;
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

-- 1. La notification, juste apres le courriel.
SELECT pg_temp.remplacer('public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure,
  $a$      '{}'::jsonb, 'retenu_entretien:' || p_id::text || ':' || p_cle_idempotence, 'auto', v_uid);
  END IF;$a$,
  $b$      '{}'::jsonb, 'retenu_entretien:' || p_id::text || ':' || p_cle_idempotence, 'auto', v_uid);
  END IF;
  -- NOTIF-RETENU (08/11/2026) : la meme nouvelle dans l'application, une fois par
  -- geste (le rejeu sort plus haut). Un echec ne bloque jamais l'admission.
  IF v_c.profile_id IS NOT NULL THEN
    BEGIN
      INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
      VALUES (v_c.profile_id, NULL, 'retenu_entretien', '{}'::jsonb, '/attente/entretien');
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'retenu_entretien : notification non posee (SQLSTATE %), admission poursuivie', SQLSTATE;
      IF pg_catalog.to_regprocedure('private.push1_journaliser(text,text,text)') IS NOT NULL THEN
        BEGIN
          EXECUTE 'SELECT private.push1_journaliser($1, $2, $3)'
            USING 'notification:retenu_entretien', p_id::text, SQLSTATE;
        EXCEPTION WHEN OTHERS THEN
          NULL;
        END;
      END IF;
    END;
  END IF;$b$, 1);

-- 2. La fiche F86 : empreinte reelle, et ce qui change ajoute a la fin.
DO $f86$
DECLARE
  v_f CONSTANT pg_catalog.regprocedure :=
    'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure;
  v_avant text;
  v_apres text;
BEGIN
  v_avant := pg_catalog.obj_description(v_f, 'pg_proc');
  IF v_avant IS NULL OR v_avant NOT LIKE 'F86 candidate allowlist:%md5_functiondef=%' THEN
    RAISE EXCEPTION 'retenu_entretien : fiche F86 de % introuvable', v_f;
  END IF;
  v_apres := pg_catalog.regexp_replace(v_avant, 'md5_functiondef=[0-9a-f]{32}',
                                       'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
  IF pg_catalog.strpos(v_apres, 'NOTIF-RETENU (08/11/2026)') = 0 THEN
    v_apres := v_apres
      || ' NOTIF-RETENU (08/11/2026) : pose aussi la notification retenu_entretien (application), une fois par geste, '
         'apres le courriel ; un echec ne bloque pas l admission. Must-pass aussi : supabase/tests/scenarios_notif_retenu.sql.';
  END IF;
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_apres);
END
$f86$;

-- 3. Categorie du push.
INSERT INTO private.push_evenements (evenement, categorie, tag)
VALUES ('retenu_entretien', 'admissions', NULL)
ON CONFLICT (evenement) DO UPDATE SET categorie = EXCLUDED.categorie, tag = EXCLUDED.tag;

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(
    'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, 'NOTIF-RETENU (08/11/2026)') = 0
     OR pg_catalog.strpos(v_def, '''retenu_entretien:'' || p_id::text') = 0 THEN
    RAISE EXCEPTION 'retenu_entretien : remplacement incomplet (la notification ou le courriel manque)';
  END IF;
  IF NOT (SELECT pg_catalog.obj_description(
            'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure, 'pg_proc')
          LIKE '%md5_functiondef=' || pg_catalog.md5(v_def) || '%') THEN
    RAISE EXCEPTION 'retenu_entretien : la fiche F86 n''est pas a l''empreinte reelle';
  END IF;
  IF pg_catalog.has_function_privilege('anon',
       'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'retenu_entretien : la fonction est ouverte a anon';
  END IF;
END
$postflight$;
