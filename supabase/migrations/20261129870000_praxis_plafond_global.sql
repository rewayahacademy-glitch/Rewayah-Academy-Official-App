-- PRAXIS-PLAFOND-GLOBAL : aucune borne ne limitait le NOMBRE DE LIGNES que `private.praxis_journal` recoit.
-- Les plafonds en vigueur bornent ce que Praxis envoie (messages, annonces, propositions, calendrier) ;
-- chaque appel d'une cle existante (meme revoquee ou expiree) ecrit encore une ligne, y compris le refus
-- d'un plafond. Voir docs/current/BUREAU-EQUIPE/PRAXIS/AUDIT-JOURNAL-PRAXIS.md (arbitrage du pilote, 17/11).
--
-- Decision : un plafond global PAR CLE, sur une heure glissante, pose AU GUICHET (`private.praxis_porte`, entree
-- unique de tous les outils) et non a l'ecriture : les plafonds d'`ecrire` et d'`annoncer` se lisent au journal,
-- sauter des lignes les fausserait.
--  * Valeur : 600 appels par cle et par heure, REGLABLE (`private.praxis_reglages.appels_par_heure`, 60 a 3600),
--    ecrite par une porte neuve `direction_praxis_regler_plafond` (admin, aal2, journalisee) ; la porte
--    `direction_praxis_regler` garde sa signature.
--  * Au-dela : la porte rend la cause `plafond_global` AVEC `cle_id` NUL : les outils, qui n'ecrivent au
--    journal que lorsque `cle_id` existe, n'ecrivent RIEN et repondent {"erreur": "plafond_global"}.
--  * UNE seule ligne temoin par cle et par heure (outil `porte`, issue `plafond_global`), ecrite par la porte.
--  * Les cles revoquees ou expirees sont sous le meme plafond (elles ecrivent deja une ligne par appel).
--  * `praxis_noter_refus` ne change pas : il refuse deja quand `cle_id` est nul.
--
-- Additif : une colonne (avec valeur par defaut), un index, une porte neuve ; deux fonctions remplacees par
-- CREATE OR REPLACE a signature identique, apres controle de leur empreinte (production et depot ont les
-- memes). Aucun mot d'effacement, aucun BEGIN ni COMMIT de premier niveau.

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('private.praxis_journal') IS NULL OR pg_catalog.to_regclass('private.praxis_reglages') IS NULL THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-GLOBAL : le socle de Praxis est absent ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'private.praxis_porte(text,boolean)'::pg_catalog.regprocedure)
     IS DISTINCT FROM '3002e09955b7684a49adb95e9850edbd' THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-GLOBAL : la definition de private.praxis_porte n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p WHERE p.oid = 'public.direction_praxis_etat()'::pg_catalog.regprocedure)
     IS DISTINCT FROM '438bf87eec34d90edf3a3e745ac35eef' THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-GLOBAL : la definition de public.direction_praxis_etat n''est pas celle attendue ; rien n''est modifie';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a WHERE a.attrelid = 'private.praxis_reglages'::pg_catalog.regclass
              AND a.attname = 'appels_par_heure' AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-GLOBAL : deja installe ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Le reglage : 600 par defaut, 60 a 3600.
ALTER TABLE private.praxis_reglages
  ADD COLUMN appels_par_heure integer NOT NULL DEFAULT 600 CHECK (appels_par_heure BETWEEN 60 AND 3600);

-- 2. Le compte par cle et par heure, tous outils et toutes issues confondus.
CREATE INDEX praxis_journal_cle_recent_idx ON private.praxis_journal (cle_id, cree_le DESC);

-- 3. Le guichet.
CREATE OR REPLACE FUNCTION private.praxis_porte(p_secret text, p_ecrit boolean DEFAULT false)
 RETURNS TABLE(cle_id uuid, emise_par uuid, usage text, cause text, cause_interne text, cotes gender[])
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_c private.praxis_cles%ROWTYPE;
  v_r private.praxis_reglages%ROWTYPE;
  v_cotes public.gender[];
BEGIN
  IF p_secret IS NULL OR p_secret !~ '^prx_[0-9a-f]{64}$' THEN
    RETURN QUERY SELECT NULL::uuid, NULL::uuid, NULL::text, 'cle_refusee'::text, 'cle_invalide'::text, NULL::public.gender[];
    RETURN;
  END IF;
  SELECT c.* INTO v_c FROM private.praxis_cles c WHERE c.empreinte = private.praxis_empreinte(p_secret);
  IF NOT FOUND THEN
    RETURN QUERY SELECT NULL::uuid, NULL::uuid, NULL::text, 'cle_refusee'::text, 'cle_inconnue'::text, NULL::public.gender[];
    RETURN;
  END IF;
  -- PRAXIS-PLAFOND-GLOBAL : le plafond d'appels par cle et par heure glissante, avant toute autre cause (une cle
  -- revoquee ou expiree y est soumise comme les autres). Au-dela : cle_id NUL (les outils n'ecrivent rien) et une
  -- seule ligne temoin par cle et par heure.
  IF (SELECT pg_catalog.count(*) FROM private.praxis_journal j
       WHERE j.cle_id = v_c.id AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour')
     >= (SELECT r.appels_par_heure FROM private.praxis_reglages r) THEN
    PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_c.id::text, 1));
    IF NOT EXISTS (SELECT 1 FROM private.praxis_journal j
                    WHERE j.cle_id = v_c.id AND j.issue = 'plafond_global'
                      AND j.cree_le > pg_catalog.clock_timestamp() - interval '1 hour') THEN
      PERFORM private.praxis_noter(v_c.id, v_c.emise_par, 'porte', 'plafond_global', NULL, NULL, NULL, pg_catalog.clock_timestamp());
    END IF;
    RETURN QUERY SELECT NULL::uuid, NULL::uuid, NULL::text, 'plafond_global'::text, 'plafond_global'::text, NULL::public.gender[];
    RETURN;
  END IF;
  IF v_c.revoquee_le IS NOT NULL THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'cle_revoquee'::text, NULL::public.gender[];
    RETURN;
  END IF;
  IF v_c.expire_le <= pg_catalog.clock_timestamp() THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'cle_expiree'::text, NULL::public.gender[];
    RETURN;
  END IF;
  -- AR-7 I5 : la personne qui a emis la cle est toujours une direction active, de compte valide (non supprime, actif, acces non expire).
  IF NOT private.com_profil_valide(v_c.emise_par, 'admin') THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'emetteur_invalide'::text, NULL::public.gender[];
    RETURN;
  END IF;
  v_cotes := private.praxis_cotes(v_c.emise_par);
  IF pg_catalog.cardinality(v_cotes) = 0 THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'cle_refusee'::text, 'emetteur_sans_cote'::text, NULL::public.gender[];
    RETURN;
  END IF;
  SELECT r.* INTO v_r FROM private.praxis_reglages r;
  IF NOT coalesce(v_r.actif, false) THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'eteint'::text, 'eteint'::text, v_cotes;
    RETURN;
  END IF;
  IF v_c.usage = 'routine' AND NOT coalesce(v_r.autonome, false) THEN
    RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, 'autonome_requis'::text, 'autonome_requis'::text, v_cotes;
    RETURN;
  END IF;
  UPDATE private.praxis_cles SET derniere_utilisation_le = pg_catalog.clock_timestamp() WHERE id = v_c.id;
  RETURN QUERY SELECT v_c.id, v_c.emise_par, v_c.usage, NULL::text, NULL::text, v_cotes;
END;
$function$;

-- 4. La porte du reglage (admin, aal2, journalisee) ; `direction_praxis_regler` garde sa signature.
CREATE FUNCTION public.direction_praxis_regler_plafond(p_appels_par_heure integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $f$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin'
                  AND auth.jwt() ->> 'aal' = 'aal2', false) THEN
    RAISE EXCEPTION 'autorisation direction avec MFA requise' USING ERRCODE = '42501';
  END IF;
  IF p_appels_par_heure IS NULL OR p_appels_par_heure NOT BETWEEN 60 AND 3600 THEN
    RAISE EXCEPTION 'plafond d''appels par heure invalide : 60 a 3600' USING ERRCODE = '22023';
  END IF;
  UPDATE private.praxis_reglages
     SET appels_par_heure = p_appels_par_heure, modifie_par = auth.uid(), modifie_le = pg_catalog.clock_timestamp()
   WHERE id;
  PERFORM public.log_sensitive_access('praxis_regle_plafond', 'private.praxis_reglages', 'praxis',
    pg_catalog.jsonb_build_object('appelsParHeure', p_appels_par_heure));
  RETURN pg_catalog.jsonb_build_object('appelsParHeure', p_appels_par_heure);
END;
$f$;

REVOKE ALL ON FUNCTION public.direction_praxis_regler_plafond(integer) FROM PUBLIC, anon, authenticated, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.direction_praxis_regler_plafond(integer) TO authenticated;
ALTER FUNCTION public.direction_praxis_regler_plafond(integer) OWNER TO postgres;

-- 5. L'etat de la direction rend le plafond.
CREATE OR REPLACE FUNCTION public.direction_praxis_etat()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_account_valid() AND public.app_role() = 'admin', false) THEN
    RAISE EXCEPTION 'autorisation direction requise' USING ERRCODE = '42501';
  END IF;
  RETURN (SELECT pg_catalog.jsonb_build_object(
    'actif', r.actif,
    'autonome', r.autonome,
    'envoisParHeure', r.envois_par_heure,
    'appelsParHeure', r.appels_par_heure,
    'modifieLe', r.modifie_le,
    'essaiFils', pg_catalog.to_jsonb(r.essai_fils),
    'donneesReelles', r.donnees_reelles,
    'cles', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'id', c.id, 'libelle', c.libelle, 'prefixe', c.prefixe, 'usage', c.usage,
               'emiseLe', c.emise_le, 'expireLe', c.expire_le, 'derniereUtilisationLe', c.derniere_utilisation_le,
               'revoqueeLe', c.revoquee_le, 'motifRevocation', c.motif_revocation,
               -- L'etat vient de la base (son horloge), jamais d'une comparaison faite sur le poste (meme regle que jetons_agent_actifs).
               'etat', CASE WHEN c.revoquee_le IS NOT NULL THEN 'revoquee'
                            WHEN c.expire_le <= pg_catalog.clock_timestamp() THEN 'expiree' ELSE 'active' END)
             ORDER BY c.emise_le DESC, c.id)
        FROM (SELECT * FROM private.praxis_cles x ORDER BY x.emise_le DESC, x.id LIMIT 100) c), '[]'::jsonb))
    FROM private.praxis_reglages r);
END;
$function$;

DO $postflight$
BEGIN
  IF NOT pg_catalog.has_function_privilege('authenticated', 'public.direction_praxis_regler_plafond(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.direction_praxis_regler_plafond(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', 'public.direction_praxis_regler_plafond(integer)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', 'public.direction_praxis_regler_plafond(integer)', 'EXECUTE') THEN
    RAISE EXCEPTION 'PRAXIS-PLAFOND-GLOBAL : droits de direction_praxis_regler_plafond inattendus';
  END IF;
END
$postflight$;
