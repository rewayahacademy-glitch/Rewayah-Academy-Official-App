-- WHATSAPP-FAMILLE (directeur, 23/11/2026 : « ajouter une demande de numero WhatsApp, car c'est difficile d'etre en
-- contact avec les familles juste apres leur inscription par e-mail »).
--
-- AUCUNE TABLE, AUCUNE COLONNE : le numero se range dans `public.candidature_contacts.telephone` (E.164, `+` puis
-- 7 a 15 chiffres, contrainte deja en place), la ligne de contact de la demande d'admission (famille ou eleve adulte).
--
--   1. `inscrire_titulaire` recoit `p_whatsapp` (10e parametre, facultatif, en fin de liste). La forme a neuf
--      parametres est mise de cote dans private (comme ONBOARDING-PRAXIS et AUDIT-FAMILLE-1) ; la nouvelle forme
--      l'appelle puis range le numero. Un client d'avant (neuf arguments) reste servi : p_whatsapp a une valeur par
--      defaut. Un numero mal forme est refuse (22023) avant toute ecriture ; absent, la demande part quand meme.
--   2. `mon_whatsapp()` : l'etat pour l'accueil de la famille {possible, numero}. `definir_mon_whatsapp(text)` :
--      la famille ajoute ou corrige son numero (comptes deja inscrits, rien n'est invente).
--   3. `whatsapp_famille_direction(candidature, profil)` : la direction lit le numero (feuille d'une demande, fiche
--      eleve), journalise, nul sous masquage d'identite. Lecture separee : ni lister_demandes_admission ni
--      fiche_eleve_direction ne sont redefinies.
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : 0. Aucune donnee ecrite a l'installation.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)') IS NULL
     AND pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text,text)') IS NULL THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : inscrire_titulaire (AUDIT-FAMILLE-1) est absente';
  END IF;
  IF pg_catalog.to_regclass('public.candidature_contacts') IS NULL THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : candidature_contacts est absente';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. La forme a neuf parametres, mise de cote
-- ---------------------------------------------------------------------------
DO $de_cote$
BEGIN
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)') IS NOT NULL THEN
    ALTER FUNCTION public.inscrire_titulaire(text, text, text, public.gender, text, boolean, jsonb, text, text)
      RENAME TO inscrire_titulaire_avant_whatsapp;
    ALTER FUNCTION public.inscrire_titulaire_avant_whatsapp(text, text, text, public.gender, text, boolean, jsonb, text, text)
      SET SCHEMA private;
    ALTER FUNCTION private.inscrire_titulaire_avant_whatsapp(text, text, text, public.gender, text, boolean, jsonb, text, text)
      SECURITY INVOKER;
    REVOKE ALL ON FUNCTION private.inscrire_titulaire_avant_whatsapp(text, text, text, public.gender, text, boolean, jsonb, text, text)
      FROM PUBLIC, anon, authenticated, service_role;
    COMMENT ON FUNCTION private.inscrire_titulaire_avant_whatsapp(text, text, text, public.gender, text, boolean, jsonb, text, text) IS
      'WHATSAPP-FAMILLE (23/11/2026) : ancienne forme a neuf parametres, appelee par la nouvelle forme ; a fusionner lors d''un lot de nettoyage avec le directeur present.';
  END IF;
END
$de_cote$;

-- Le numero WhatsApp tel que le serveur le garde : « + » puis 7 a 15 chiffres, rien d'autre. Les espaces, points,
-- tirets et parentheses sont retires ; le reste est refuse (22023). Vide : nul.
CREATE OR REPLACE FUNCTION private.whatsapp_normaliser(p_numero text)
RETURNS text
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_n text := pg_catalog.regexp_replace(coalesce(p_numero, ''), '[ ().\-]', '', 'g');
BEGIN
  IF v_n = '' THEN
    RETURN NULL;
  END IF;
  IF v_n !~ '^\+[1-9][0-9]{6,14}$' THEN
    RAISE EXCEPTION 'numero WhatsApp illisible : + puis l''indicatif et le numero' USING ERRCODE = '22023';
  END IF;
  RETURN v_n;
END;
$function$;
REVOKE ALL ON FUNCTION private.whatsapp_normaliser(text) FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false,
  p_apprenants jsonb DEFAULT NULL,
  p_source text DEFAULT NULL,
  p_langue text DEFAULT NULL,
  p_whatsapp text DEFAULT NULL
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
  v_numero text;
  v_candidature uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  -- Refuse avant toute ecriture : un numero mal forme ne cree rien.
  v_numero := private.whatsapp_normaliser(p_whatsapp);
  v_profile := private.inscrire_titulaire_avant_whatsapp(
    p_usage, p_first_name, p_last_name, p_gender, p_timezone, p_suit_des_cours,
    p_apprenants, p_source, p_langue);
  IF v_numero IS NOT NULL THEN
    SELECT c.id INTO v_candidature
      FROM public.candidatures c
     WHERE c.profile_id = v_profile.id AND c.type_code IN ('famille', 'eleve_adulte');
    IF v_candidature IS NOT NULL THEN
      INSERT INTO public.candidature_contacts (candidature_id, telephone)
      VALUES (v_candidature, v_numero)
      ON CONFLICT (candidature_id) DO UPDATE
        SET telephone = EXCLUDED.telephone, telephone_brut = NULL;
    END IF;
  END IF;
  RETURN v_profile;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 2. La famille : lire et corriger son numero
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.mon_whatsapp()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_candidature uuid;
  v_numero text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501'; END IF;
  SELECT c.id INTO v_candidature
    FROM public.candidatures c
   WHERE c.profile_id = auth.uid() AND c.type_code IN ('famille', 'eleve_adulte')
   ORDER BY c.recue_le DESC, c.id
   LIMIT 1;
  IF v_candidature IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('possible', false, 'numero', NULL);
  END IF;
  SELECT k.telephone INTO v_numero
    FROM public.candidature_contacts k WHERE k.candidature_id = v_candidature;
  RETURN pg_catalog.jsonb_build_object('possible', true, 'numero', v_numero);
END;
$function$;

CREATE OR REPLACE FUNCTION public.definir_mon_whatsapp(p_numero text)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_numero text := private.whatsapp_normaliser(p_numero);
  v_candidature uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session' USING ERRCODE = '42501'; END IF;
  IF v_numero IS NULL THEN
    RAISE EXCEPTION 'numero WhatsApp requis' USING ERRCODE = '22023';
  END IF;
  SELECT c.id INTO v_candidature
    FROM public.candidatures c
   WHERE c.profile_id = auth.uid() AND c.type_code IN ('famille', 'eleve_adulte')
   ORDER BY c.recue_le DESC, c.id
   LIMIT 1;
  IF v_candidature IS NULL THEN
    RAISE EXCEPTION 'aucune demande d''admission pour ce compte' USING ERRCODE = '42501';
  END IF;
  INSERT INTO public.candidature_contacts (candidature_id, telephone)
  VALUES (v_candidature, v_numero)
  ON CONFLICT (candidature_id) DO UPDATE
    SET telephone = EXCLUDED.telephone, telephone_brut = NULL;
END;
$function$;

-- ---------------------------------------------------------------------------
-- 3. La direction : lire le numero (demande, ou eleve par son titulaire)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.whatsapp_famille_direction(
  p_candidature uuid DEFAULT NULL, p_profil uuid DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_candidature uuid := p_candidature;
  v_numero text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'numero WhatsApp reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF public.agent_identite_masquee() THEN
    RETURN NULL;
  END IF;
  IF v_candidature IS NULL AND p_profil IS NOT NULL THEN
    -- Le profil lui-meme (adulte), sinon le titulaire de son foyer.
    SELECT c.id INTO v_candidature
      FROM public.candidatures c
     WHERE c.type_code IN ('famille', 'eleve_adulte')
       AND (c.profile_id = p_profil
            OR c.profile_id IN (
              SELECT t.id FROM public.profiles t
               WHERE t.role = 'guardian' AND t.deleted_at IS NULL
                 AND t.household_id = (SELECT p.household_id FROM public.profiles p WHERE p.id = p_profil)))
     ORDER BY (c.profile_id = p_profil) DESC, c.recue_le DESC, c.id
     LIMIT 1;
  END IF;
  IF v_candidature IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT k.telephone INTO v_numero
    FROM public.candidature_contacts k WHERE k.candidature_id = v_candidature;
  IF v_numero IS NOT NULL THEN
    PERFORM public.log_sensitive_access('whatsapp_famille_lu', 'candidature_contacts', v_candidature::text,
      pg_catalog.jsonb_build_object('champ', 'telephone'));
  END IF;
  RETURN v_numero;
END;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
  v_sig text;
BEGIN
  FOREACH v_sig IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text,text)',
    'public.mon_whatsapp()',
    'public.definir_mon_whatsapp(text)',
    'public.whatsapp_famille_direction(uuid,uuid)']
  LOOP
    v_oid := v_sig::pg_catalog.regprocedure;
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-23. WHATSAPP-FAMILLE.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_sig LIKE '%whatsapp_famille_direction%' THEN 'ADMIN_ONLY'
           WHEN v_sig LIKE '%inscrire_titulaire%' THEN 'PUBLIC_REGISTRATION'
           ELSE 'SELF_ONLY' END));
  END LOOP;
END
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure :=
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text,text)'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : DEFINER ou ACL invalide pour inscrire_titulaire';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname = 'inscrire_titulaire' AND p.pronargs <> 10) THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : une autre forme de inscrire_titulaire reste dans public';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.inscrire_titulaire_avant_whatsapp(text,text,text,public.gender,text,boolean,jsonb,text,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : l''ancienne forme reste executable';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.whatsapp_famille_direction(uuid,uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.mon_whatsapp()', 'EXECUTE') THEN
    RAISE EXCEPTION 'WHATSAPP-FAMILLE : une lecture est ouverte a anon';
  END IF;
END
$postflight$;
