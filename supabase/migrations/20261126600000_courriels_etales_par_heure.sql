-- COURRIELS-ETALES (directeur, 14/11/2026) : « si on dispatchait dans la
-- journee, disons 300 au matin, puis 300 dans l'apres-midi, et 300 le soir ».
-- 1 301 invitations (lien_inscription) attendent sous le plafond de 300 par
-- 24 heures glissantes. Le plafond passe a 900 par jour, mais sans rafale :
-- un nouveau reglage `courriels.non_essentiels_par_heure` borne aussi les
-- envois non essentiels sur l'heure glissante (40 : 900 / 24, arrondi), pour
-- que les messageries des destinataires ne voient pas un pic soudain.
-- Sans ce reglage (ou a 0), rien ne change : seul le plafond du jour compte.
-- Les valeurs de production (900 par jour, 40 par heure) ne sont pas ici :
-- le directeur les colle a part (reglages, pas schema).
-- Les messages essentiels et hors plafond ne sont jamais retenus.
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement.

DO $etales$
DECLARE
  v_f regprocedure := 'public.courriels_reserver(integer)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := 'v_place := LEAST(v_lot - coalesce(pg_catalog.cardinality(v_ids), 0), v_par_jour - v_partis);';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, 'courriels.non_essentiels_par_heure') > 0 THEN
    RAISE NOTICE 'courriels etales : deja fait, rien ne change';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'courriels etales : ancre trouvee % fois (attendu 1), a revoir', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    v_ancre || pg_catalog.chr(10)
    || '  -- COURRIELS-ETALES (14/11/2026) : au plus courriels.non_essentiels_par_heure' || pg_catalog.chr(10)
    || '  -- sur l''heure glissante, quand ce reglage est au-dessus de 0.' || pg_catalog.chr(10)
    || '  IF coalesce(public.app_config_int(''courriels.non_essentiels_par_heure'', 0), 0) > 0 THEN' || pg_catalog.chr(10)
    || '    v_place := LEAST(v_place, public.app_config_int(''courriels.non_essentiels_par_heure'', 0) - (' || pg_catalog.chr(10)
    || '      SELECT pg_catalog.count(*)::integer FROM public.courriels_sortants s' || pg_catalog.chr(10)
    || '        JOIN public.courriel_categories c ON c.code = s.categorie' || pg_catalog.chr(10)
    || '       WHERE NOT private.courriel_hors_plafond(c.essentielle, s.modele)' || pg_catalog.chr(10)
    || '         AND s.reserve_le > pg_catalog.now() - interval ''1 hour''));' || pg_catalog.chr(10)
    || '  END IF;');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'courriels etales : proprietaire, droits ou attributs modifies';
  END IF;
END
$etales$;
