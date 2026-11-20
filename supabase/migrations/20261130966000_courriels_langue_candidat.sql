-- PE-A1 COURRIELS-CANDIDAT (parcours de l'enseignant, plan du 19/11/2026 §2.1 ; RETOURS-TERRAIN R10).
--
-- LE PROBLEME (courriels lus le 19/11/2026) : des candidats qui ecrivent en arabe ou en anglais recoivent
-- en francais « Votre candidature est retenue pour un entretien », l'invitation personnelle, et le corps du
-- lien de connexion. Causes lues dans le code :
--   a. la langue d'un courriel de la file vient de profiles.langue_communication, que l'application n'ecrit
--      QUE si la personne choisit une langue dans son compte (un candidat dont l'application suit la langue de
--      son appareil n'a rien) ; sinon de la donnee `langue` du courriel, que les appelants ne passent presque
--      jamais (retenu_entretien, invitation_candidat_importe) ; sinon le francais. Or la candidature porte
--      `candidatures.langue`, la langue de l'interface choisie a l'inscription (CAND-L3), jamais lue ici ;
--   b. les courriels de Supabase Auth (lien de connexion, confirmation) choisissent leur corps sur
--      `user_metadata.langue`, que personne n'ecrit (l'application appelle signInWithOtp sans donnee).
--
-- CE QUE FAIT CE FICHIER :
--   1. public.courriel_langue_a_l_entree() (CREATE OR REPLACE, signature identique, apres controle de
--      md5(prosrc)) : la langue d'un courriel suit, dans l'ordre, la langue choisie dans le compte ; la donnee
--      `langue` du courriel ; la langue de la candidature de ce compte ; celle d'une candidature dont le
--      contact est cette adresse ; la langue explicitement donnee au dernier courriel de cette adresse ;
--      l'arabe si la reponse importee de cette adresse (nom ou formulaire) est ecrite en arabe ; sinon le
--      francais. Un courriel sans profil retrouve le compte qui porte son adresse (sans tenir compte de la casse).
--      ATTENTION, PORTEE : la langue de la candidature vaut pour TOUS les courriels d'un compte sans langue
--      choisie, pas seulement ceux du recrutement : un enseignant admis dont la candidature est en arabe recevra
--      aussi ses courriels de classes, de remplacement et de paie en arabe, tant qu'il ne choisit pas une
--      langue dans son compte (le choix du compte passe toujours en premier).
--   2. private.auth_langue_synchroniser(uuid) : recopie dans auth.users.raw_user_meta_data.langue la langue
--      du compte (choisie, sinon celle de sa candidature), pour que Supabase Auth ecrive le lien de connexion
--      dans cette langue. Deux declencheurs la tiennent a jour (choix de langue du compte ; langue d'une
--      candidature) a partir de l'installation. Une ecriture qui echoue ne bloque jamais le choix de langue ni
--      la candidature (avertissement seulement). Seul un raw_user_meta_data absent (NULL SQL) ou objet JSON est
--      ecrit : un JSON null, un scalaire ou un tableau n'est jamais touche.
--   3. private.auth_langue_rattraper() : le rattrapage des comptes EXISTANTS, rendu comme une fonction privee
--      (aucun droit client) que ce fichier N'APPELLE PAS : il attend la decision du directeur (ecriture sur
--      des donnees de personnes). Elle rend le nombre de comptes changes. Le pilote l'appellera par une
--      migration d'une ligne (SELECT private.auth_langue_rattraper();) le jour ou le directeur le decide.
--   4. Un index sur courriels_sortants (destinataire_adresse, cree_le) pour la lecture 1.
--
-- CE QUE CE FICHIER NE FAIT PAS (hors du serveur) : le SUJET des courriels Auth se regle dans le tableau de
-- bord Supabase (texte a coller : docs/current/captures/E2E/pe-courriels-candidat/A-COLLER-SUPABASE-AUTH.md).
--
-- MOTS D'EFFACEMENT : ZERO. Additif : une fonction remplacee a l'identique de signature (droits et
-- proprietaire gardes par CREATE OR REPLACE), trois fonctions privees neuves, deux declencheurs neufs, un index.
-- Ecriture de donnees A L'INSTALLATION : AUCUNE (le rattrapage n'est pas appele). Ensuite, seuls les
-- declencheurs ecrivent raw_user_meta_data.langue, au moment ou une personne choisit sa langue ou depose une
-- candidature. Sans BEGIN ni COMMIT de premier niveau. Rejouable.

DO $preflight$
DECLARE
  v_md5 text;
BEGIN
  SELECT pg_catalog.md5(p.prosrc) INTO v_md5
    FROM pg_catalog.pg_proc p WHERE p.oid = 'public.courriel_langue_a_l_entree()'::pg_catalog.regprocedure;
  -- 8948fb01... : la definition de 20261023140000 (jamais retouchee depuis) ; b94cabac... : celle de ce fichier.
  IF v_md5 IS DISTINCT FROM '8948fb01f326c3ba42d827629b823fec'
     AND v_md5 IS DISTINCT FROM 'b94cabac83d7ee59ef30715777e0a923' THEN
    RAISE EXCEPTION 'PE-A1 : la definition de courriel_langue_a_l_entree n''est pas celle attendue (%) ; rien n''est modifie', v_md5;
  END IF;
  IF pg_catalog.to_regclass('public.candidatures') IS NULL
     OR pg_catalog.to_regclass('public.candidature_contacts') IS NULL
     OR pg_catalog.to_regclass('public.formulaires_reponses') IS NULL
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                     WHERE a.attrelid = 'public.candidatures'::pg_catalog.regclass AND a.attname = 'langue'
                       AND NOT a.attisdropped) THEN
    RAISE EXCEPTION 'PE-A1 : un objet attendu manque (candidatures.langue, candidature_contacts, formulaires_reponses)';
  END IF;
END
$preflight$;

-- ====================================================================================================================
-- 1. La langue d'un courriel, fixee a son entree dans la file
-- ====================================================================================================================
CREATE OR REPLACE FUNCTION public.courriel_langue_a_l_entree()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_langue text;
  v_profil uuid := NEW.destinataire_profil;
BEGIN
  -- PE-A1 : un courriel sans profil retrouve le compte qui porte son adresse.
  IF v_profil IS NULL THEN
    SELECT p.id INTO v_profil
      FROM auth.users u JOIN public.profiles p ON p.id = u.id
     WHERE pg_catalog.lower(u.email) = NEW.destinataire_adresse
     LIMIT 1;
  END IF;
  -- 1. La langue choisie dans le compte.
  IF v_profil IS NOT NULL THEN
    SELECT p.langue_communication INTO v_langue FROM public.profiles p WHERE p.id = v_profil;
  END IF;
  -- 2. La langue donnee par l'appelant.
  IF v_langue IS NULL AND NEW.donnees ? 'langue' THEN
    v_langue := pg_catalog.lower(NEW.donnees->>'langue');
  END IF;
  -- 3. PE-A1 : la langue de l'interface choisie a la candidature de ce compte (CAND-L3).
  IF v_langue IS NULL AND v_profil IS NOT NULL THEN
    SELECT c.langue INTO v_langue FROM public.candidatures c
     WHERE c.profile_id = v_profil AND c.langue IS NOT NULL
     ORDER BY c.recue_le DESC, c.id LIMIT 1;
  END IF;
  -- 4. PE-A1 : celle d'une candidature dont le contact est cette adresse.
  IF v_langue IS NULL THEN
    SELECT c.langue INTO v_langue
      FROM public.candidature_contacts k JOIN public.candidatures c ON c.id = k.candidature_id
     WHERE k.courriel = NEW.destinataire_adresse AND c.langue IS NOT NULL
     ORDER BY c.recue_le DESC, c.id LIMIT 1;
  END IF;
  -- 5. PE-A1 : la langue explicitement donnee au dernier courriel de cette adresse (ex. attente_candidat).
  IF v_langue IS NULL THEN
    SELECT s.langue INTO v_langue FROM public.courriels_sortants s
     WHERE s.destinataire_adresse = NEW.destinataire_adresse AND s.donnees ? 'langue'
     ORDER BY s.cree_le DESC LIMIT 1;
  END IF;
  -- 6. PE-A1 : la reponse importee de cette adresse, nom ou formulaire ecrit en arabe (regle de
  --    prevenir_par_courriel, CANDIDATS-FLUX 06/11/2026).
  IF v_langue IS NULL AND EXISTS (
       SELECT 1 FROM public.formulaires_reponses r JOIN public.formulaires_lots l ON l.id = r.lot_id
        WHERE r.courriel = NEW.destinataire_adresse AND r.etat = 'active'
          AND (r.nom_affiche || ' ' || l.classeur) ~ '[؀-ۿ]') THEN
    v_langue := 'ar';
  END IF;
  IF v_langue IS NULL OR NOT EXISTS (SELECT 1 FROM public.langues_communication l
                                      WHERE l.code = v_langue AND l.active) THEN
    v_langue := 'fr';
  END IF;
  NEW.langue := v_langue;
  RETURN NEW;
END;
$function$;

CREATE INDEX IF NOT EXISTS courriels_sortants_adresse
  ON public.courriels_sortants (destinataire_adresse, cree_le DESC);

-- ====================================================================================================================
-- 2. La langue du compte, recopiee pour Supabase Auth (user_metadata.langue)
-- ====================================================================================================================
CREATE OR REPLACE FUNCTION private.auth_langue_synchroniser(p_profil uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_langue text;
  v_n integer;
BEGIN
  IF p_profil IS NULL THEN
    RETURN false;
  END IF;
  SELECT coalesce(p.langue_communication,
                  (SELECT c.langue FROM public.candidatures c
                    WHERE c.profile_id = p.id AND c.langue IS NOT NULL
                    ORDER BY c.recue_le DESC, c.id LIMIT 1))
    INTO v_langue
    FROM public.profiles p WHERE p.id = p_profil;
  IF v_langue IS NULL OR v_langue !~ '^[a-z]{2,3}$' THEN
    RETURN false;
  END IF;
  -- La base de test (stub d'auth) n'a pas cette colonne : rien a faire.
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                  WHERE a.attrelid = 'auth.users'::pg_catalog.regclass AND a.attname = 'raw_user_meta_data'
                    AND NOT a.attisdropped) THEN
    RETURN false;
  END IF;
  EXECUTE 'UPDATE auth.users SET raw_user_meta_data = coalesce(raw_user_meta_data, ''{}''::jsonb)'
       || ' || pg_catalog.jsonb_build_object(''langue'', $2::text)'
       || ' WHERE id = $1 AND (raw_user_meta_data ->> ''langue'') IS DISTINCT FROM $2::text'
       -- Un JSON null, un scalaire ou un tableau n'est jamais touche.
       || ' AND (raw_user_meta_data IS NULL OR pg_catalog.jsonb_typeof(raw_user_meta_data) = ''object'')'
    USING p_profil, v_langue;
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n > 0;
END;
$function$;
ALTER FUNCTION private.auth_langue_synchroniser(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.auth_langue_synchroniser(uuid) FROM PUBLIC, anon, authenticated, service_role;
DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON FUNCTION private.auth_langue_synchroniser(uuid) FROM agent_ro;
  END IF;
END
$droits$;

-- Les declencheurs : un echec n'empeche jamais le choix de langue ni la candidature.
CREATE OR REPLACE FUNCTION private.auth_langue_suivre()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  -- profiles : la ligne est le compte ; candidatures : son profile_id.
  v_profil uuid := (pg_catalog.to_jsonb(NEW)
                    ->> CASE TG_TABLE_NAME WHEN 'profiles' THEN 'id' ELSE 'profile_id' END)::uuid;
BEGIN
  BEGIN
    PERFORM private.auth_langue_synchroniser(v_profil);
  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'PE-A1 : langue du compte non recopiee pour l''authentification (SQLSTATE %)', SQLSTATE;
  END;
  RETURN NULL;
END;
$function$;
ALTER FUNCTION private.auth_langue_suivre() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.auth_langue_suivre() FROM PUBLIC, anon, authenticated, service_role;
DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON FUNCTION private.auth_langue_suivre() FROM agent_ro;
  END IF;
END
$droits$;

DO $declencheurs$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.profiles'::pg_catalog.regclass AND t.tgname = 'profiles_langue_auth') THEN
    CREATE TRIGGER profiles_langue_auth
      AFTER INSERT OR UPDATE OF langue_communication ON public.profiles
      FOR EACH ROW WHEN (NEW.langue_communication IS NOT NULL)
      EXECUTE FUNCTION private.auth_langue_suivre();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.candidatures'::pg_catalog.regclass AND t.tgname = 'candidatures_langue_auth') THEN
    CREATE TRIGGER candidatures_langue_auth
      AFTER INSERT OR UPDATE OF langue, profile_id ON public.candidatures
      FOR EACH ROW WHEN (NEW.langue IS NOT NULL AND NEW.profile_id IS NOT NULL)
      EXECUTE FUNCTION private.auth_langue_suivre();
  END IF;
END
$declencheurs$;

-- Le rattrapage des comptes existants : une fonction privee, JAMAIS appelee par ce fichier (decision du
-- directeur attendue). Elle rend le nombre de comptes dont la langue a ete recopiee ; un second appel rend 0.
CREATE OR REPLACE FUNCTION private.auth_langue_rattraper()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_id uuid;
  v_n integer := 0;
BEGIN
  FOR v_id IN
    SELECT p.id FROM public.profiles p
     WHERE p.langue_communication IS NOT NULL
        OR EXISTS (SELECT 1 FROM public.candidatures c WHERE c.profile_id = p.id AND c.langue IS NOT NULL)
  LOOP
    IF private.auth_langue_synchroniser(v_id) THEN
      v_n := v_n + 1;
    END IF;
  END LOOP;
  RETURN v_n;
END;
$function$;
ALTER FUNCTION private.auth_langue_rattraper() OWNER TO postgres;
REVOKE ALL ON FUNCTION private.auth_langue_rattraper() FROM PUBLIC, anon, authenticated, service_role;
DO $droits$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'agent_ro') THEN
    REVOKE ALL ON FUNCTION private.auth_langue_rattraper() FROM agent_ro;
  END IF;
END
$droits$;

-- ====================================================================================================================
-- Controle final
-- ====================================================================================================================
DO $postflight$
DECLARE
  v text;
BEGIN
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = 'public.courriel_langue_a_l_entree()'::pg_catalog.regprocedure) IS DISTINCT FROM 'b94cabac83d7ee59ef30715777e0a923'
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'public.courriel_langue_a_l_entree()'::pg_catalog.regprocedure
                       AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'PE-A1 : courriel_langue_a_l_entree n''a pas la forme attendue';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.courriels_sortants'::pg_catalog.regclass AND t.tgname = 'courriel_langue'
                    AND t.tgfoid = 'public.courriel_langue_a_l_entree()'::pg_catalog.regprocedure) THEN
    RAISE EXCEPTION 'PE-A1 : le declencheur courriel_langue ne lit plus la fonction attendue';
  END IF;
  FOREACH v IN ARRAY ARRAY['private.auth_langue_synchroniser(uuid)', 'private.auth_langue_suivre()',
                           'private.auth_langue_rattraper()'] LOOP
    IF pg_catalog.has_function_privilege('anon', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v, 'EXECUTE')
       OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v::pg_catalog.regprocedure AND p.prosecdef
                        AND p.proconfig @> ARRAY['search_path=""'] AND p.proowner = 'postgres'::pg_catalog.regrole) THEN
      RAISE EXCEPTION 'PE-A1 : droits ou definition inattendus pour %', v;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgname IN ('profiles_langue_auth', 'candidatures_langue_auth')
         AND t.tgfoid = 'private.auth_langue_suivre()'::pg_catalog.regprocedure) <> 2 THEN
    RAISE EXCEPTION 'PE-A1 : les deux declencheurs de la langue du compte manquent';
  END IF;
END
$postflight$;
