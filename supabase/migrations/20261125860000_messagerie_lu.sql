-- MESSAGERIE-LU (14/11/2026, demande du directeur : les signes d'envoi et de
-- lecture « comme WhatsApp ») : le fil dit a quelle heure l'AUTRE partie l'a
-- lu pour la derniere fois ; l'application en tire, sous chaque message de
-- soi, « Envoye » (une coche, pale) ou « Lu » (deux coches, foncees).
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier
-- niveau. S'installe par apply_migration, APRES 20261125800000.
--
--   1. private.com_fil_json : une cle de plus, « lu_par_autres_le » = la plus
--      recente lecture (com_lectures) d'une personne de l'AUTRE partie du fil
--      (jamais la sienne, jamais un collegue de son cote). Retouche par ancre,
--      une fois ; proprietaire, droits, volatilite et search_path gardes.
--      Aucun nom : seulement une heure, que l'autre partie a produite en lisant.
--   2. private.com_signaler_lecture : une lecture signale aussi les autres
--      parties du fil (com_signaux, sans texte), pour que leurs coches passent
--      a « Lu » en direct.
--      Pour les autres parties, un signal « message » du meme fil pose dans
--      la meme transaction n'est jamais rabaisse en « lecture » : l'envoi
--      ecrit aussi la lecture de l'auteur, et sans cette regle l'avis
--      « Nouveau message » ne partirait plus. La propre lecture de la
--      personne, elle, reste posee comme avant (private.com_signal_poser).

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_destinataires_signal(uuid,uuid)') IS NULL THEN
    RAISE EXCEPTION 'messagerie lu : installer d''abord 20261125800000_messagerie_temps_reel.sql';
  END IF;
END
$preflight$;

-- 1. « lu_par_autres_le » ------------------------------------------------------
DO $fil$
DECLARE
  v_f regprocedure := 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''messages'', coalesce((';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, 'lu_par_autres_le') > 0 THEN
    RAISE NOTICE 'messagerie lu : com_fil_json porte deja lu_par_autres_le';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'messagerie lu : ancre de com_fil_json trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''lu_par_autres_le'', (' || pg_catalog.chr(10)
    || '      SELECT pg_catalog.max(l.lu_jusqu_au)' || pg_catalog.chr(10)
    || '        FROM public.com_lectures l' || pg_catalog.chr(10)
    || '        JOIN public.profiles r ON r.id = l.profile_id' || pg_catalog.chr(10)
    || '       WHERE l.fil_id = f.id AND l.profile_id <> p_moi' || pg_catalog.chr(10)
    || '         AND CASE WHEN v_soi_a' || pg_catalog.chr(10)
    || '               THEN private.com_est_partie(r.id, r.role::text, r.household_id, f.type_objet, f.partie_b_nature, f.partie_b_id)' || pg_catalog.chr(10)
    || '               ELSE private.com_est_partie(r.id, r.role::text, r.household_id, f.type_objet, f.partie_a_nature, f.partie_a_id)' || pg_catalog.chr(10)
    || '             END),' || pg_catalog.chr(10)
    || '    ' || v_ancre);
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'messagerie lu : proprietaire, droits ou attributs de com_fil_json modifies';
  END IF;
END
$fil$;

-- 2. La lecture signale aussi les autres parties -------------------------------
CREATE OR REPLACE FUNCTION private.com_signaler_lecture()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $function$
DECLARE
  v_qui uuid;
BEGIN
  BEGIN
    PERFORM private.com_signal_poser(NEW.profile_id, NEW.fil_id, 'lecture');
    FOR v_qui IN SELECT d FROM private.com_destinataires_signal(NEW.fil_id, NEW.profile_id) AS d LOOP
      INSERT INTO public.com_signaux AS s (destinataire, fil_id, nature, rang, change_le)
      VALUES (v_qui, NEW.fil_id, 'lecture', 1, pg_catalog.clock_timestamp())
      ON CONFLICT (destinataire) DO UPDATE
        SET fil_id = EXCLUDED.fil_id,
            nature = CASE
              WHEN s.nature = 'message' AND s.fil_id = EXCLUDED.fil_id
                   AND s.change_le >= pg_catalog.now()
                THEN 'message'
              ELSE 'lecture' END,
            rang = s.rang + 1,
            change_le = EXCLUDED.change_le;
    END LOOP;
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'messagerie lu : signal de lecture non pose (%)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION private.com_signaler_lecture() FROM PUBLIC, anon, authenticated, service_role;

DO $postflight$
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                       'lu_par_autres_le') = 0 THEN
    RAISE EXCEPTION 'messagerie lu : lu_par_autres_le absente de com_fil_json';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated', 'private.com_signaler_lecture()', 'execute') THEN
    RAISE EXCEPTION 'messagerie lu : com_signaler_lecture executable par un client';
  END IF;
END
$postflight$;
