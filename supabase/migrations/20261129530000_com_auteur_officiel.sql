-- COM-AUTEUR-OFFICIEL (17/11/2026, PX-BULLE-2) : chaque message porte l'indicateur « compte officiel » de son
-- auteur REEL, meme quand l'auteur est rendu sous la nature « equipe ».
--
-- CONSTAT : private.com_fil_json rend l'auteur d'un message d'un fil d'equipe comme « equipe » (administration)
-- quand il n'est pas partie du fil (private.com_participant('equipe', ...)). Cette nature ne porte ni
-- « officiel » ni « compte_officiel » : la bulle de Praxis perdait son image et son nom « #Ra_Praxis » dans le
-- fil de l'administration.
--
-- CHANGEMENT UNIQUE : private.com_fil_json (plpgsql, 20261016090000) ajoute, a l'auteur de chaque message, la cle
-- « compte_officiel » (texte) = le code du compte dans private.comptes_officiels pour l'auteur REEL (m.auteur_id),
-- ou NULL pour une personne ordinaire. Les cles existantes ne changent pas (« est_soi », « nature », etc.).
-- Retouche par ancre, une fois ; proprietaire, droits, attributs, search_path gardes et verifies. Aucune table,
-- aucune vue, aucune fonction creee ; aucune donnee ecrite ; aucun droit accorde ; aucune suppression.
-- Rejouable : rien a faire si la cle est deja la.
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier niveau.
-- ORDRE : ce fichier (20261129530000) precede le socle Praxis (20261129600000) dans un rejeu complet, qui cree
-- private.comptes_officiels. com_fil_json est en plpgsql : le nom de table n'est resolu qu'a l'execution, donc la
-- retouche s'installe sans le socle, et la table existe a tout appel reel (rejeu complet puis scenarios).
-- Aucune verification de la table ici (un controle au moment de l'installation casserait le rejeu complet).

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_fil_json(uuid,uuid,text,uuid)') IS NULL THEN
    RAISE EXCEPTION 'auteur officiel : private.com_fil_json absente';
  END IF;
END
$preflight$;

DO $fil_json$
DECLARE
  v_f regprocedure := 'private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := 'END || pg_catalog.jsonb_build_object(''est_soi'', m.auteur_id = p_moi))';
  v_cle constant text := '''compte_officiel'', (SELECT o.code FROM private.comptes_officiels o WHERE o.profile_id = m.auteur_id)';
  v_n integer;
  v_avant record;
BEGIN
  PERFORM pg_catalog.set_config('check_function_bodies', 'off', true);
  IF pg_catalog.strpos(v_def, v_cle) > 0 THEN
    RAISE NOTICE 'auteur officiel : com_fil_json porte deja la cle compte_officiel de l''auteur';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'auteur officiel : ancre de com_fil_json trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    'END || pg_catalog.jsonb_build_object(''est_soi'', m.auteur_id = p_moi)' || pg_catalog.chr(10)
    || '          || pg_catalog.jsonb_build_object(' || v_cle || ')))');
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'auteur officiel : proprietaire, droits ou attributs de com_fil_json modifies';
  END IF;
END
$fil_json$;

DO $postflight$
DECLARE v_def text := pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''compte_officiel'', (SELECT o.code FROM private.comptes_officiels o WHERE o.profile_id = m.auteur_id)') = 0 THEN
    RAISE EXCEPTION 'auteur officiel : la cle compte_officiel de l''auteur est absente de com_fil_json';
  END IF;
  IF pg_catalog.strpos(v_def, '''nouveau'',') = 0 OR pg_catalog.strpos(v_def, '''est_soi'', m.auteur_id = p_moi') = 0 THEN
    RAISE EXCEPTION 'auteur officiel : une cle existante de com_fil_json a disparu';
  END IF;
END
$postflight$;
