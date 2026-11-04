-- FUSEAUX-bis (garde-cap, 04/11/2026). La migration 20261109500000 rend, pour
-- chaque fuseau, le decalage UTC actuel et l'instant du prochain changement
-- d'heure, mais pas le decalage d'APRES ce changement. Le client ne fait
-- aucune conversion IANA (`pubspec.yaml` gele) : sans cette valeur, l'heure
-- d'une seance placee apres le prochain changement (une seance du 30/03 vue
-- le 20/03 depuis Paris) ne peut pas etre rendue juste.
--
-- `private.fuseau_info` gagne deux cles, rien d'autre ne change (meme
-- signature, meme type de retour, memes droits, memes appelants) :
--   * `decalage_apres` : le decalage juste apres `prochain_changement`, nul
--     quand le fuseau n'a pas de changement dans l'annee ;
--   * `changement_suivant` : l'instant du changement d'apres (dans les 400
--     jours qui suivent le prochain), nul s'il n'y en a pas. Au-dela, le
--     client dit « heure a confirmer », jamais une heure calculee a un
--     decalage perime.
--
-- `public.mon_horloge()` (garde-cap, 04/11/2026) : l'instant serveur et le
-- fuseau de l'appelant seul, lu dans son profil (foyer, sinon profil
-- enseignant), avec son decalage et ses changements d'heure. Elle sert les
-- ecrans sans classe (notifications, Journee, accueil eleve, salle), qui
-- lisaient jusqu'ici l'heure de l'appareil. Aucun fuseau dans le profil, ou un
-- fuseau inconnu : `moi` nul, sans erreur, et le client dit « heure de cet
-- appareil ». Elle ne lit aucune donnee d'une autre personne.
--
-- FICHIER SANS EFFACEMENT (regle B5) : une fonction remplacee par sa copie
-- complete, une fonction creee ; aucun objet retire.

BEGIN;

-- Preflight : la fonction installee doit etre exactement celle de la
-- 20261109500000 (empreinte relevee en production par garde-cap le 04/11).
-- Une retouche faite depuis ne peut pas etre ecrasee en silence.
DO $preflight$
DECLARE
  v_empreinte text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_empreinte
    FROM pg_catalog.pg_proc p
   WHERE p.oid = 'private.fuseau_info(text,timestamptz)'::pg_catalog.regprocedure;
  IF v_empreinte IS DISTINCT FROM '87106c2bcf428f5fb2deaf92d993c935' THEN
    RAISE EXCEPTION 'FUSEAUX-bis : private.fuseau_info a change depuis 20261109500000 (empreinte %), migration refusee', v_empreinte;
  END IF;
END;
$preflight$;

-- Le prochain changement apres un instant donne se cherche jour par jour sur
-- 400 jours, puis heure par heure, puis par quart d'heure (tous les
-- changements d'heure reels tombent sur un quart d'heure). On le cherche deux
-- fois : le prochain, puis celui d'apres.
CREATE OR REPLACE FUNCTION private.fuseau_info(p_fuseau text, p_maintenant timestamptz DEFAULT pg_catalog.now())
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_decalage integer;
  v_depart timestamptz;
  v_reference integer;
  v_jour timestamptz;
  v_heure timestamptz;
  v_quart timestamptz;
  v_changements timestamptz[] := ARRAY[]::timestamptz[];
  v_decalage_apres integer;
  v_tour integer;
BEGIN
  IF p_fuseau IS NULL OR pg_catalog.btrim(p_fuseau) = '' THEN
    RETURN NULL;
  END IF;
  BEGIN
    v_decalage := EXTRACT(epoch FROM
      (p_maintenant AT TIME ZONE p_fuseau) - (p_maintenant AT TIME ZONE 'UTC'))::integer;
  EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
  END;

  v_depart := p_maintenant;
  v_reference := v_decalage;
  FOR v_tour IN 1..2 LOOP
    v_jour := NULL;
    SELECT j INTO v_jour
      FROM pg_catalog.generate_series(v_depart + interval '1 day',
                                      v_depart + interval '400 days', interval '1 day') AS j
     WHERE EXTRACT(epoch FROM (j AT TIME ZONE p_fuseau) - (j AT TIME ZONE 'UTC'))::integer
           <> v_reference
     ORDER BY j
     LIMIT 1;
    EXIT WHEN v_jour IS NULL;
    SELECT h INTO v_heure
      FROM pg_catalog.generate_series(
             pg_catalog.date_trunc('hour', v_jour - interval '1 day'), v_jour, interval '1 hour') AS h
     WHERE EXTRACT(epoch FROM (h AT TIME ZONE p_fuseau) - (h AT TIME ZONE 'UTC'))::integer
           <> v_reference
     ORDER BY h
     LIMIT 1;
    SELECT q INTO v_quart
      FROM pg_catalog.generate_series(v_heure - interval '1 hour', v_heure, interval '15 minutes') AS q
     WHERE EXTRACT(epoch FROM (q AT TIME ZONE p_fuseau) - (q AT TIME ZONE 'UTC'))::integer
           <> v_reference
     ORDER BY q
     LIMIT 1;
    v_changements := v_changements || v_quart;
    v_reference := EXTRACT(epoch FROM
      (v_quart AT TIME ZONE p_fuseau) - (v_quart AT TIME ZONE 'UTC'))::integer;
    IF v_tour = 1 THEN
      v_decalage_apres := v_reference;
    END IF;
    v_depart := v_quart;
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'fuseau', p_fuseau,
    'decalage_secondes', v_decalage,
    'prochain_changement', v_changements[1],
    'decalage_apres', v_decalage_apres,
    'changement_suivant', v_changements[2]);
END;
$function$;

-- L'horloge de l'appelant -------------------------------------------------------
CREATE FUNCTION public.mon_horloge()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_fuseau text;
BEGIN
  IF NOT coalesce(public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'horloge non autorisee' USING ERRCODE = '42501';
  END IF;
  -- Le meme ordre que public.mon_fuseau(), sans son repli sur Paris : un
  -- profil sans fuseau ne recoit pas une ville inventee.
  SELECT nullif(pg_catalog.btrim(h.timezone), '') INTO v_fuseau
    FROM public.households h
   WHERE h.id = public.app_household_id() AND h.deleted_at IS NULL;
  IF v_fuseau IS NULL THEN
    SELECT nullif(pg_catalog.btrim(tp.timezone_iana), '') INTO v_fuseau
      FROM public.teacher_profiles tp
     WHERE tp.profile_id = auth.uid() AND tp.deleted_at IS NULL;
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'maintenant', pg_catalog.now(),
    'moi', private.fuseau_info(v_fuseau));
END;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.mon_horloge()'::pg_catalog.regprocedure;
  v_role text;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC', v_oid);
  FOREACH v_role IN ARRAY ARRAY['anon', 'service_role', 'agent_ro'] LOOP
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
      EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM %I', v_oid, v_role);
    END IF;
  END LOOP;
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=ROLE_POSITIVE_TEMPLATE; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-04. FUSEAUX : l''instant serveur et le fuseau de l''appelant seul (decalage actuel, changements d''heure), lu dans son profil ; moi nul sans fuseau.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

-- Postflight ----------------------------------------------------------------
-- Les dates de Paris ci-dessous sont ecrites en dur, et c'est voulu : ce
-- sont des changements d'heure connus. On relit aussi les fonctions
-- installees et leurs droits.
DO $postflight$
DECLARE
  v_prive pg_catalog.regprocedure := 'private.fuseau_info(text,timestamptz)'::pg_catalog.regprocedure;
  v_public pg_catalog.regprocedure := 'public.horloge_interlocuteurs(uuid)'::pg_catalog.regprocedure;
  v_mien pg_catalog.regprocedure := 'public.mon_horloge()'::pg_catalog.regprocedure;
  v_p record;
  v_paris jsonb := private.fuseau_info('Europe/Paris', '2026-10-01 12:00+00');
  v_abidjan jsonb := private.fuseau_info('Africa/Abidjan', '2026-10-01 12:00+00');
BEGIN
  FOR v_p IN SELECT p.oid, p.prosecdef, p.proconfig, p.provolatile FROM pg_catalog.pg_proc p
              WHERE p.oid IN (v_prive, v_mien) LOOP
    IF NOT v_p.prosecdef OR NOT ('search_path=""' = ANY (v_p.proconfig)) OR v_p.provolatile <> 's' THEN
      RAISE EXCEPTION 'FUSEAUX-bis : % doit etre SECURITY DEFINER, STABLE, search_path vide', v_p.oid::pg_catalog.regprocedure;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', v_mien, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_mien, 'EXECUTE') THEN
    RAISE EXCEPTION 'FUSEAUX-bis : droits d''execution de public.mon_horloge incorrects';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', v_prive, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_prive, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_public, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_public, 'EXECUTE') THEN
    RAISE EXCEPTION 'FUSEAUX-bis : droits d''execution modifies';
  END IF;
  IF (v_paris ->> 'prochain_changement')::timestamptz IS DISTINCT FROM '2026-10-25 01:00+00'::timestamptz
     OR (v_paris ->> 'decalage_apres')::integer IS DISTINCT FROM 3600
     OR (v_paris ->> 'changement_suivant')::timestamptz IS DISTINCT FROM '2027-03-28 01:00+00'::timestamptz THEN
    RAISE EXCEPTION 'FUSEAUX-bis : Europe/Paris mal calcule (%)', v_paris;
  END IF;
  IF v_abidjan ->> 'prochain_changement' IS NOT NULL
     OR v_abidjan ->> 'decalage_apres' IS NOT NULL
     OR v_abidjan ->> 'changement_suivant' IS NOT NULL THEN
    RAISE EXCEPTION 'FUSEAUX-bis : Africa/Abidjan ne change jamais d''heure (%)', v_abidjan;
  END IF;
END;
$postflight$;

COMMIT;
