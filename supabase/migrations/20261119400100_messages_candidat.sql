-- MESSAGES-CANDIDAT (07/11/2026) : le fil « candidature » entre un candidat
-- enseignant et la direction, par la messagerie metier existante (COM-BACK-1).
-- Decision : CAND-Q06 (21/10/2026), arbitrages du garde-cap du 07/11/2026.
-- Plage reservee : 20261119400000 a 20261119499999 (PR 302).
--
-- FICHIER SANS EFFACEMENT (B5) ; pas de BEGIN ni de COMMIT de premier niveau
-- (un seul script, chaque bloc est atomique). Precondition : la migration
-- 20261119400000 (type d'objet « candidature » dans la contrainte) est
-- installee ; sinon celle-ci s'arrete et le dit.
--
-- Principe (securite, ouverture d'une messagerie a un compte non valide) :
-- private.com_appelant() N'EST PAS TOUCHEE. Ses autres appelants (annonces :
-- com_annonce_publier, com_annonces_administration, com_annonces_cibles,
-- com_regles_audience) restent fermes a un candidat. Une fonction nouvelle,
-- private.com_appelant_msg(), rend l'appelant valide d'abord, et SEULEMENT a
-- defaut un candidat enseignant (pending_kyc, avec une candidature de type
-- enseignant). Elle n'est lue que par les huit fonctions de la messagerie.
--
--   1. private.com_appelant_candidat(), private.com_appelant_msg(),
--      private.com_candidature_lisible(candidature, moi) : le candidat lit SON
--      fil ; la direction lit les fils de SON cote (CAND-Q07, recalcule a
--      chaque lecture par private.entretien_cote_permis, le super-admin les
--      deux cotes).
--   2. Huit fonctions publiques : `private.com_appelant()` y devient
--      `private.com_appelant_msg()` (une ancre, une fois chacune).
--      com_mes_capacites accepte le type « candidature » ; com_envoyer_message
--      borne l'auteur candidat a 30 messages par 24 heures et par fil
--      (SQLSTATE 53400, la rejouee d'une meme cle n'est pas comptee).
--   3. private.com_paires : une branche « candidature » (le candidat et
--      l'equipe, tant que la candidature est en cours, hors pause, avant la
--      salle des prets) ; private.com_fil_json : un candidat ne voit que les
--      fils « candidature », et la direction que ceux de son cote.
--
-- Une candidature refusee, retiree, en pause, ou confirmee garde la lecture
-- seule : le fil reste lisible (regle C5), personne n'y ecrit plus.
-- Aucun WARNING ne cite SQLERRM.

DO $preflight$
BEGIN
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_constraint c
        WHERE c.conrelid = 'public.com_fils'::regclass
          AND c.conname = 'com_fils_type_objet_check'
          AND pg_catalog.pg_get_constraintdef(c.oid) LIKE '%''candidature''%') THEN
    RAISE EXCEPTION 'messages candidat : installer d''abord 20261119400000_messages_candidat_type_objet.sql';
  END IF;
  IF pg_catalog.to_regprocedure('private.entretien_cote_permis(uuid,public.gender)') IS NULL THEN
    RAISE EXCEPTION 'messages candidat : private.entretien_cote_permis est absente (V1-a non installee)';
  END IF;
END
$preflight$;

-- 1. Les fonctions nouvelles ------------------------------------------------

CREATE OR REPLACE FUNCTION private.com_appelant_candidat()
RETURNS TABLE (id uuid, role text, foyer uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT p.id, p.role::text, p.household_id
  FROM public.profiles p
  WHERE p.id = auth.uid()
    AND p.role = 'teacher'
    AND p.role::text = public.app_role()::text
    AND p.account_status = 'pending_kyc'
    AND p.deleted_at IS NULL
    AND EXISTS (SELECT 1 FROM public.candidatures c
                 WHERE c.profile_id = p.id AND c.type_code = 'enseignant');
$function$;

CREATE OR REPLACE FUNCTION private.com_appelant_msg()
RETURNS TABLE (id uuid, role text, foyer uuid)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT a.id, a.role, a.foyer FROM private.com_appelant() a
  UNION ALL
  SELECT c.id, c.role, c.foyer FROM private.com_appelant_candidat() c
   WHERE NOT EXISTS (SELECT 1 FROM private.com_appelant());
$function$;

-- Qui lit le fil d'une candidature : le candidat lui-meme, ou une direction
-- active du cote (femmes ou hommes) de la candidature, ou le super-admin.
CREATE OR REPLACE FUNCTION private.com_candidature_lisible(p_candidature uuid, p_moi uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = '' AS $function$
  SELECT coalesce(EXISTS (
    SELECT 1 FROM public.candidatures c
     WHERE c.id = p_candidature
       AND c.type_code = 'enseignant'
       AND (c.profile_id = p_moi
            OR (EXISTS (SELECT 1 FROM public.profiles a
                         WHERE a.id = p_moi AND a.role = 'admin'
                           AND a.account_status = 'active' AND a.deleted_at IS NULL)
                AND private.entretien_cote_permis(p_moi, c.genre)))), false);
$function$;

REVOKE ALL ON FUNCTION private.com_appelant_candidat(), private.com_appelant_msg(),
  private.com_candidature_lisible(uuid, uuid)
  FROM PUBLIC, anon, authenticated, service_role;
DO $agent_ro$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    EXECUTE 'REVOKE ALL ON FUNCTION private.com_appelant_candidat(), private.com_appelant_msg(), private.com_candidature_lisible(uuid, uuid) FROM agent_ro';
  END IF;
END
$agent_ro$;

-- 2 et 3. Les fonctions existantes, remplacees par ancre -------------------

-- Remplace chaque [ancres[i]] par [nouvelles[i]] dans la definition en place
-- de [f] : chacune doit s'y trouver exactement [fois] fois. Le proprietaire,
-- SECURITY DEFINER, search_path et droits sont gardes par CREATE OR REPLACE ;
-- l'empreinte F86 du commentaire suit la definition quand il en porte une.
CREATE FUNCTION pg_temp.remplacer(p_f regprocedure, p_ancres text[], p_nouvelles text[])
RETURNS void LANGUAGE plpgsql AS $r$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_apres text;
  v_n integer;
  v_com text;
  v_avant record;
  i integer;
BEGIN
  SELECT p.prosecdef, p.proowner, p.proconfig, p.proacl INTO v_avant
    FROM pg_catalog.pg_proc p WHERE p.oid = p_f;
  v_apres := v_def;
  FOR i IN 1 .. pg_catalog.cardinality(p_ancres) LOOP
    v_n := (pg_catalog.length(v_apres) - pg_catalog.length(pg_catalog.replace(v_apres, p_ancres[i], '')))
           / pg_catalog.length(p_ancres[i]);
    IF v_n <> 1 THEN
      RAISE EXCEPTION 'messages candidat : ancre trouvee % fois (attendu 1) dans % : %', v_n, p_f, p_ancres[i];
    END IF;
    v_apres := pg_catalog.replace(v_apres, p_ancres[i], p_nouvelles[i]);
  END LOOP;
  EXECUTE v_apres;
  v_com := pg_catalog.obj_description(p_f, 'pg_proc');
  IF v_com LIKE '%md5_functiondef=%' THEN
    v_com := pg_catalog.regexp_replace(v_com, 'md5_functiondef=[0-9A-Za-z_]+',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(p_f)));
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', p_f, v_com);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = p_f AND p.prosecdef = v_avant.prosecdef
                    AND p.proowner = v_avant.proowner
                    AND p.proconfig IS NOT DISTINCT FROM v_avant.proconfig
                    AND p.proacl IS NOT DISTINCT FROM v_avant.proacl) THEN
    RAISE EXCEPTION 'messages candidat : proprietaire, SECURITY DEFINER, search_path ou droits modifies pour %', p_f;
  END IF;
END
$r$;

DO $migration$
DECLARE
  v_f text;
  v_ancien text := 'private.com_appelant()';
  v_nouveau text := 'private.com_appelant_msg()';
BEGIN
  -- Rejeu : si la messagerie lit deja com_appelant_msg, rien a faire.
  IF pg_catalog.strpos(
       pg_catalog.pg_get_functiondef('public.com_lister_fils()'::regprocedure), v_nouveau) > 0 THEN
    RAISE NOTICE 'messages candidat : deja installee, rien a faire';
    RETURN;
  END IF;

  -- Preflight : les corps de production releves par le garde-cap (md5 de
  -- prosrc, 07/11/2026). Tout autre etat arrete la migration : la fonction a
  -- change depuis le depot.
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'private.com_appelant()'::regprocedure) <> '228d6c8b9ced797a5de12cae4b2251fb'
     OR (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
          WHERE p.oid = 'private.com_paires(text,uuid)'::regprocedure) <> '141bf435d4b31bd8b064137073480282'
     OR (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
          WHERE p.oid = 'private.com_est_partie(uuid,text,uuid,text,text,uuid)'::regprocedure) <> '1c3cb14974bc909fa4f870d20707a62f'
     OR (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
          WHERE p.oid = 'private.com_profil_valide(uuid,text)'::regprocedure) <> '50b93d06d9034e69cd3f3fa422c02072' THEN
    RAISE EXCEPTION 'messages candidat : corps inattendu de com_appelant, com_paires, com_est_partie ou com_profil_valide (la fonction a change depuis le depot)';
  END IF;

  -- Les huit fonctions qui lisent l'appelant de la messagerie.
  FOREACH v_f IN ARRAY ARRAY[
    'public.com_lister_fils()', 'public.com_lire_fil(uuid)',
    'public.com_conversations_pour_objet(text,uuid)',
    'public.com_ouvrir_conversation(text,uuid,text)',
    'public.com_fil_pour_objet(text,uuid)', 'public.com_marquer_lu(uuid)'] LOOP
    PERFORM pg_temp.remplacer(v_f::regprocedure, ARRAY[v_ancien], ARRAY[v_nouveau]);
  END LOOP;

  PERFORM pg_temp.remplacer('public.com_mes_capacites(text,uuid)'::regprocedure,
    ARRAY[v_ancien, '(''classe'', ''eleve'', ''dossier'', ''remplacement'', ''profilPaiement'')'],
    ARRAY[v_nouveau, '(''classe'', ''eleve'', ''dossier'', ''remplacement'', ''profilPaiement'', ''candidature'')']);

  -- Le plafond de l'auteur candidat : 30 messages par 24 heures et par fil.
  PERFORM pg_temp.remplacer('public.com_envoyer_message(uuid,text,uuid)'::regprocedure,
    ARRAY[v_ancien, '  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)'],
    ARRAY[v_nouveau, '  IF (v_json -> ''objet'' ->> ''type'') = ''candidature'' AND moi.role <> ''admin''
     AND NOT EXISTS (SELECT 1 FROM public.com_messages x
                      WHERE x.fil_id = p_fil_id AND x.auteur_id = moi.id
                        AND x.cle_idempotence = p_cle_idempotence)
     AND (SELECT pg_catalog.count(*) FROM public.com_messages x
           WHERE x.fil_id = p_fil_id AND x.auteur_id = moi.id
             AND x.envoye_le > pg_catalog.clock_timestamp() - interval ''24 hours'') >= 30 THEN
    RAISE EXCEPTION ''COM-CAND plafond de 30 messages par jour atteint'' USING ERRCODE = ''53400'';
  END IF;
  INSERT INTO public.com_messages (fil_id, auteur_id, cle_idempotence, texte)']);

  -- Un candidat ne voit que les fils « candidature » ; la direction ne lit que
  -- ceux de son cote (CAND-Q07).
  PERFORM pg_temp.remplacer('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure,
    ARRAY['  IF NOT (v_soi_a OR v_soi_b) THEN RETURN NULL; END IF;
'],
    ARRAY['  IF NOT (v_soi_a OR v_soi_b) THEN RETURN NULL; END IF;
  IF f.type_objet <> ''candidature'' AND NOT private.com_profil_valide(p_moi, NULL) THEN
    RETURN NULL;
  END IF;
  IF f.type_objet = ''candidature'' AND NOT private.com_candidature_lisible(f.objet_id, p_moi) THEN
    RETURN NULL;
  END IF;
']);

  -- Les paires : le candidat et l'equipe, tant que la candidature est en cours.
  PERFORM pg_temp.remplacer('private.com_paires(text,uuid)'::regprocedure,
    ARRAY['      WHERE p_type = ''profilPaiement'' AND p.id = p_objet_id AND p.role = ''teacher''
  )',
          '  WHERE c.a_id IS NOT NULL
    AND CASE c.a_nature',
          'private.acces_paye(mb.eleve_id))));
$function$'],
    ARRAY['      WHERE p_type = ''profilPaiement'' AND p.id = p_objet_id AND p.role = ''teacher''
    -- Candidature (MESSAGES-CANDIDAT) : le candidat enseignant et l''equipe,
    -- tant que la candidature est en cours, hors pause, avant la salle des
    -- prets ; lisible par le candidat ou par la direction de son cote.
    UNION
    SELECT ''profil'', cd.profile_id, ''equipe'', NULL
      FROM public.candidatures cd
      WHERE p_type = ''candidature'' AND cd.id = p_objet_id
        AND cd.type_code = ''enseignant'' AND cd.profile_id IS NOT NULL
        AND cd.issue = ''en_cours'' AND NOT cd.en_pause AND cd.etape <> ''confirmee''
        AND private.com_candidature_lisible(cd.id, auth.uid())
  )',
          '  WHERE c.a_id IS NOT NULL
    AND (p_type = ''candidature'' OR (CASE c.a_nature',
          'private.acces_paye(mb.eleve_id))))));
$function$']);

  RAISE NOTICE 'messages candidat : installee';
END
$migration$;

-- Postflight : la messagerie lit com_appelant_msg partout, et com_appelant et
-- ses autres appelants n'ont pas bouge.
DO $postflight$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    'public.com_lister_fils()', 'public.com_lire_fil(uuid)',
    'public.com_conversations_pour_objet(text,uuid)',
    'public.com_ouvrir_conversation(text,uuid,text)',
    'public.com_fil_pour_objet(text,uuid)', 'public.com_marquer_lu(uuid)',
    'public.com_mes_capacites(text,uuid)', 'public.com_envoyer_message(uuid,text,uuid)'] LOOP
    IF pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f::regprocedure), 'private.com_appelant_msg()') = 0
       OR pg_catalog.strpos(pg_catalog.pg_get_functiondef(v_f::regprocedure), 'private.com_appelant()') > 0
       OR NOT pg_catalog.has_function_privilege('authenticated', v_f::regprocedure, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_f::regprocedure, 'EXECUTE') THEN
      RAISE EXCEPTION 'messages candidat : % n''a pas la forme attendue', v_f;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
              WHERE p.pronamespace IN ('public'::regnamespace, 'private'::regnamespace)
                AND p.proname IN ('com_annonce_publier', 'com_annonces_administration',
                                  'com_annonces_cibles', 'com_regles_audience')
                AND pg_catalog.strpos(p.prosrc, 'com_appelant_msg') > 0) THEN
    RAISE EXCEPTION 'messages candidat : une fonction d''annonces lit com_appelant_msg';
  END IF;
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_paires(text,uuid)'::regprocedure),
                       '''candidature''') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.com_fil_json(uuid,uuid,text,uuid)'::regprocedure),
                          'com_candidature_lisible') = 0 THEN
    RAISE EXCEPTION 'messages candidat : com_paires ou com_fil_json n''a pas la branche candidature';
  END IF;
END
$postflight$;
