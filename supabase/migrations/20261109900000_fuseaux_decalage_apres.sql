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
-- FICHIER SANS EFFACEMENT (regle B5) : une fonction remplacee par sa copie
-- complete ; aucun objet retire.

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

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur hors des calculs connus : on relit la fonction
-- installee, ses droits, et trois fuseaux de reference.
DO $postflight$
DECLARE
  v_prive pg_catalog.regprocedure := 'private.fuseau_info(text,timestamptz)'::pg_catalog.regprocedure;
  v_public pg_catalog.regprocedure := 'public.horloge_interlocuteurs(uuid)'::pg_catalog.regprocedure;
  v_p record;
  v_paris jsonb := private.fuseau_info('Europe/Paris', '2026-10-01 12:00+00');
  v_abidjan jsonb := private.fuseau_info('Africa/Abidjan', '2026-10-01 12:00+00');
BEGIN
  SELECT p.prosecdef, p.proconfig, p.provolatile INTO v_p FROM pg_catalog.pg_proc p WHERE p.oid = v_prive;
  IF NOT v_p.prosecdef OR NOT ('search_path=""' = ANY (v_p.proconfig)) OR v_p.provolatile <> 's' THEN
    RAISE EXCEPTION 'FUSEAUX-bis : private.fuseau_info doit rester SECURITY DEFINER, STABLE, search_path vide';
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
