-- COM-COMPTE-OFFICIEL (17/11/2026, PRAXIS-AFFICHAGE) : le client recoit enfin l'indicateur « compte officiel ».
-- SECRETAIRE-IA §9 : le « # » et l'italique des comptes officiels sont rendus par l'application a partir d'un
-- indicateur du compte, jamais ranges dans le nom. Cet indicateur n'existait pas dans ce que lit la messagerie.
--
-- CHANGEMENT UNIQUE : private.com_participant (seul constructeur d'un participant : fils, parties, auteurs de
-- messages, interlocuteurs de com_conversations_pour_objet) rend, pour la nature « profil », deux cles de plus :
-- « officiel » (booleen) = private.praxis_est_officiel(profil), et « compte_officiel » (texte) = le code du compte dans
-- private.comptes_officiels ('praxis' aujourd'hui ; NULL pour une personne ordinaire), pour que l'ecran sache QUEL compte
-- officiel (jamais un nom en dur). Les cles existantes ne changent pas, ni la cle
-- « nouveau » de com_fil_json (non touchee). Retouche par ancre, une fois ; proprietaire, droits, volatilite et
-- search_path gardes et verifies. Aucune table, aucune vue, aucune fonction creee ; aucune donnee ecrite ; aucun
-- droit accorde. Rejouable : rien a faire si la cle est deja la. Une personne ordinaire recoit `false` et NULL.
--
-- FICHIER SANS MOT D'EFFACEMENT (compte : 0) ; sans BEGIN ni COMMIT de premier niveau.
-- ORDRE : ce fichier (20261129520000) precede le socle Praxis (20261129600000) dans un rejeu complet ; la fonction
-- private.praxis_est_officiel n'existe donc pas encore a ce moment-la. com_participant etant en LANGUAGE sql, la
-- verification du corps est suspendue le temps de la retouche (check_function_bodies, local a la transaction) ; le
-- nom est resolu a l'appel. En production le socle est deja la ; apres un rejeu complet, la fonction existe aussi.
-- S'installe par apply_migration, APRES 20261129510000.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('private.com_participant(text,uuid,text,uuid)') IS NULL THEN
    RAISE EXCEPTION 'compte officiel : private.com_participant absente';
  END IF;
END
$preflight$;

DO $participant$
DECLARE
  v_f regprocedure := 'private.com_participant(text,uuid,text,uuid)'::regprocedure;
  v_def text := pg_catalog.pg_get_functiondef(v_f);
  v_ancre constant text := '''prenom'', p.first_name,';
  v_n integer;
  v_avant record;
BEGIN
  PERFORM pg_catalog.set_config('check_function_bodies', 'off', true);
  IF pg_catalog.strpos(v_def, '''compte_officiel'',') > 0 THEN
    RAISE NOTICE 'compte officiel : com_participant porte deja les cles officiel et compte_officiel';
    RETURN;
  END IF;
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, v_ancre, '')))
         / pg_catalog.length(v_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'compte officiel : ancre de com_participant trouvee % fois (attendu 1)', v_n;
  END IF;
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl, p.provolatile INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = v_f;
  EXECUTE pg_catalog.replace(v_def, v_ancre,
    '''officiel'', private.praxis_est_officiel(p.id),' || pg_catalog.chr(10)
    || '        ''compte_officiel'', (SELECT o.code FROM private.comptes_officiels o WHERE o.profile_id = p.id),' || pg_catalog.chr(10)
    || '        ' || v_ancre);
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = v_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl
                    AND p.provolatile = v_avant.provolatile) THEN
    RAISE EXCEPTION 'compte officiel : proprietaire, droits ou attributs de com_participant modifies';
  END IF;
END
$participant$;

DO $postflight$
DECLARE v_def text := pg_catalog.pg_get_functiondef('private.com_participant(text,uuid,text,uuid)'::regprocedure);
BEGIN
  IF pg_catalog.strpos(v_def, '''officiel'',') = 0 OR pg_catalog.strpos(v_def, '''compte_officiel'',') = 0 THEN
    RAISE EXCEPTION 'compte officiel : les cles officiel et compte_officiel sont absentes de com_participant';
  END IF;
  IF pg_catalog.strpos(v_def, '''prenom'', p.first_name,') = 0 OR pg_catalog.strpos(v_def, '''equipe'' THEN') = 0 THEN
    RAISE EXCEPTION 'compte officiel : une cle existante de com_participant a disparu';
  END IF;
END
$postflight$;
