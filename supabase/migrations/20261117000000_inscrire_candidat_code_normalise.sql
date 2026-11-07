-- inscrire_candidat : le code d'invitation se normalise comme a la verification
-- (07/11/2026, correctif demande par le pilote, defaut vu par le robot pieges_1).
--
-- FICHIER SANS EFFACEMENT (regle B5) : aucun des trois mots d'effacement ;
-- le pilote l'installe tel quel. Migration additive (B6) : meme signature,
-- memes reponses, meme proprietaire, memes droits.
--
-- Le defaut : la verification du code (verifier_invitation_enseignant) et la
-- consommation par inscrire_enseignant_invite normalisent le code tape
-- (I1, UX-016 : app_private.code_invitation_normalise, casse, espaces et tirets
-- oublies). inscrire_candidat, la creation du compte du candidat, comparait
-- `i.code = upper(v_code)` : « abcd - efgh - jkmn » etait declare valide a la
-- verification, puis refuse a « Envoyer ma candidature » (reponse « inconnue »).
--
-- Cette migration ne change QUE la comparaison du code, par ancre, une seule
-- fois : `i.code = pg_catalog.upper(v_code)` devient
-- `i.code = app_private.code_invitation_normalise(v_code)`. La signature, le
-- proprietaire, SECURITY DEFINER, le search_path et les droits restent ceux de
-- la fonction (CREATE OR REPLACE les garde) ; l'empreinte F86 de son
-- commentaire est recalculee. Le postflight verifie chacun de ces points, et
-- que le reste de la definition est identique a l'octet pres.
--
-- Preflight : la fonction est dans l'etat de production (md5 de son corps
-- 0ed9aafb7aa837eb0c3e160f12e61ea9) ou deja corrigee (rejeu : rien a faire).
-- Tout autre etat arrete la migration : la fonction a change depuis le depot.
-- Pas de BEGIN ni de COMMIT : un seul bloc, atomique par lui-meme.

DO $migration$
DECLARE
  f CONSTANT regprocedure :=
    'public.inscrire_candidat(text,text,text,public.gender,text,text,text)'::regprocedure;
  c_ancre CONSTANT text := 'i.code = pg_catalog.upper(v_code)';
  c_neuf CONSTANT text := 'i.code = app_private.code_invitation_normalise(v_code)';
  c_md5_prod CONSTANT text := '0ed9aafb7aa837eb0c3e160f12e61ea9';
  v_avant record;
  v_def text;
  v_apres text;
  v_n integer;
  v_com text;
  v_acl_apres aclitem[];
BEGIN
  -- Le code normalise doit exister (migration I1).
  IF pg_catalog.to_regprocedure('app_private.code_invitation_normalise(text)') IS NULL THEN
    RAISE EXCEPTION 'inscrire_candidat : app_private.code_invitation_normalise est absente (migration I1 non installee)';
  END IF;

  SELECT p.prosrc, p.prosecdef, p.proowner, p.proconfig, p.proacl,
         pg_catalog.md5(p.prosrc) AS empreinte
    INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = f;

  -- Rejeu : deja corrigee, rien a faire.
  IF pg_catalog.strpos(v_avant.prosrc, c_neuf) > 0
     AND pg_catalog.strpos(v_avant.prosrc, c_ancre) = 0 THEN
    RAISE NOTICE 'inscrire_candidat : deja normalisee, rien a faire';
    RETURN;
  END IF;

  -- Preflight : etat de production, ancre presente une seule fois.
  IF v_avant.empreinte <> c_md5_prod THEN
    RAISE EXCEPTION 'inscrire_candidat : corps inattendu (md5 %, attendu %) : la fonction a change depuis le depot',
      v_avant.empreinte, c_md5_prod;
  END IF;
  v_def := pg_catalog.pg_get_functiondef(f);
  v_n := (pg_catalog.length(v_def) - pg_catalog.length(pg_catalog.replace(v_def, c_ancre, '')))
         / pg_catalog.length(c_ancre);
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'inscrire_candidat : ancre trouvee % fois (attendu 1) : %', v_n, c_ancre;
  END IF;

  EXECUTE pg_catalog.replace(v_def, c_ancre, c_neuf);

  -- L'empreinte F86 du commentaire suit la definition.
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', f, v_com);
  END IF;

  -- Postflight.
  v_apres := pg_catalog.pg_get_functiondef(f);
  IF pg_catalog.strpos(v_apres, c_neuf) = 0 OR pg_catalog.strpos(v_apres, c_ancre) > 0 THEN
    RAISE EXCEPTION 'inscrire_candidat : la comparaison du code n''est pas celle attendue';
  END IF;
  -- Rien d'autre n'a change : en remettant l'ancienne ligne, on retrouve la definition d'avant.
  IF pg_catalog.replace(v_apres, c_neuf, c_ancre) <> v_def THEN
    RAISE EXCEPTION 'inscrire_candidat : la definition differe ailleurs que par la comparaison du code';
  END IF;
  SELECT p.proacl INTO v_acl_apres FROM pg_catalog.pg_proc p WHERE p.oid = f;
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_proc p
        WHERE p.oid = f
          AND p.prosecdef = v_avant.prosecdef
          AND p.proowner = v_avant.proowner
          AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
          AND p.proacl IS NOT DISTINCT FROM v_avant.proacl)
     OR NOT (SELECT p.prosecdef AND pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
                    AND coalesce(p.proconfig @> ARRAY['search_path=""'], false)
               FROM pg_catalog.pg_proc p WHERE p.oid = f) THEN
    RAISE EXCEPTION 'inscrire_candidat : proprietaire, SECURITY DEFINER, search_path ou droits modifies';
  END IF;
  IF pg_catalog.has_function_privilege('anon', f, 'EXECUTE')
     OR pg_catalog.has_function_privilege('public', f, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', f, 'EXECUTE') THEN
    RAISE EXCEPTION 'inscrire_candidat : les droits d''execution ne sont plus ceux attendus (authenticated seul)';
  END IF;
  v_com := pg_catalog.obj_description(f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%'
     AND v_com NOT LIKE '%md5_functiondef=' || pg_catalog.md5(v_apres) || '%' THEN
    RAISE EXCEPTION 'inscrire_candidat : l''empreinte F86 du commentaire n''a pas suivi la definition';
  END IF;
END
$migration$;
