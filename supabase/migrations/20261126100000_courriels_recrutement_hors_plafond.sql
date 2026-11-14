-- COURRIELS-RECRUTEMENT-HORS-PLAFOND (14/11/2026, constat d'audit du pilote en
-- production) : le plafond des courriels non essentiels
-- (app_config courriels.non_essentiels_par_jour = 300, 24 heures glissantes)
-- retenait aussi les messages individuels du recrutement : entretien_reserve,
-- entretien_rappel, entretien_rappel_direction, entretien_tenu (SALLE-2) et
-- message_candidat_recu (MESSAGERIE-PUSH), tous en categorie « recrutement »
-- (non essentielle). Derriere 1306 lien_inscription en attente, un rappel
-- « 15 minutes avant » serait parti des jours plus tard ; 5
-- message_candidat_recu etaient deja retenus.
--
-- Ce que fait ce fichier, et rien d'autre : ces cinq modeles entrent dans
-- private.courriel_hors_plafond. Ils passent alors par la premiere passe de
-- public.courriels_reserver, celle des envois hors plafond, qui est servie
-- AVANT les non essentiels et sans plafond : ils partent donc aussi avant
-- les lien_inscription en attente. courriels_reserver n'est pas touchee.
-- Les lignes deja en file en profitent a la prochaine reservation.
--
-- Retouche par ancre (une fois) : la liste en place est gardee, les cinq
-- modeles s'y ajoutent ; volatilite, search_path et droits gardes.
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier
-- niveau. S'installe par apply_migration. Rejouable : deja fait, rien ne change.

DO $hors_plafond$
DECLARE
  v_f regprocedure := 'private.courriel_hors_plafond(boolean,text)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''retenu_entretien'')';
  v_n integer;
  v_avant record;
BEGIN
  IF pg_catalog.strpos(v_def, '''message_candidat_recu''') > 0 THEN
    RAISE NOTICE 'courriels hors plafond : deja fait, rien ne change';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'courriels hors plafond : ancre trouvee % fois (attendu 1), a revoir', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''retenu_entretien'',' || pg_catalog.chr(10)
    || '                       -- 14/11/2026 : les messages individuels du recrutement.' || pg_catalog.chr(10)
    || '                       ''entretien_reserve'', ''entretien_rappel'', ''entretien_rappel_direction'',' || pg_catalog.chr(10)
    || '                       ''entretien_tenu'', ''message_candidat_recu'')');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'courriels hors plafond : proprietaire, droits ou attributs modifies';
  END IF;
END
$hors_plafond$;

DO $postflight$
DECLARE
  v_m text;
BEGIN
  FOREACH v_m IN ARRAY ARRAY['entretien_reserve', 'entretien_rappel', 'entretien_rappel_direction',
                             'entretien_tenu', 'message_candidat_recu',
                             'compte_enseignant_valide', 'invitation_enseignant', 'retenu_entretien'] LOOP
    IF NOT private.courriel_hors_plafond(false, v_m) THEN
      RAISE EXCEPTION 'courriels hors plafond : % reste sous plafond', v_m;
    END IF;
  END LOOP;
  IF private.courriel_hors_plafond(false, 'lien_inscription')
     OR private.courriel_hors_plafond(false, 'nouvelles') THEN
    RAISE EXCEPTION 'courriels hors plafond : un envoi en nombre est sorti du plafond';
  END IF;
END
$postflight$;
