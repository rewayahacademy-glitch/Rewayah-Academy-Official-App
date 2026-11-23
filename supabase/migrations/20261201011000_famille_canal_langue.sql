-- AUDIT-FAMILLE-1 (directeur, 22/11/2026 : « l'infrastructure complete pour accueillir 100 familles »).
-- Source : docs/current/PARCOURS-FAMILLE/AUDIT-ANGLES-MORTS-2026-11-22.md, points 1 et 2.
--
--   1. CANAL D'AIDE. La ligne app_config `support_canal` manquait en production : l'aide du compte disait
--      « aucun canal ». Elle est posee au format que lit canal_support() : {"type": "courriel",
--      "adresse": "support@rewayahacademy.com"} (adresse publiee par le site public). Aucune ecrasement : une
--      valeur deja choisie par la direction reste. Une personne qui n'arrive pas a entrer n'a pas de compte
--      valide, donc canal_support() lui est ferme : canal_support_public() rend le meme canal, sans compte, et
--      rien d'autre (l'adresse est deja publique sur le site).
--   2. LANGUE. inscrire_titulaire recoit la langue de l'interface (p_langue) et l'ecrit au compte
--      (profiles.langue_communication) et a la demande (candidatures.langue : fr, ar, en). Un courriel part ainsi
--      dans la langue de la famille (R27). Une langue inconnue est ignoree, jamais refusee. La forme a huit
--      parametres est mise de cote dans private, comme au lot ONBOARDING-PRAXIS, sans droit client.
--      RATTRAPAGE des comptes DEJA acceptes sans langue (famille ou eleve adulte, demande confirmee) : la langue
--      de leur demande si elle existe (candidatures.langue, sinon la langue des explications choisie : francais,
--      english, ar, pt) ; sinon rien n'est touche.
--
-- MOTS D'EFFACEMENT : ZERO. Additif. Sans BEGIN ni COMMIT de premier niveau. Rejouable.
-- Ecritures de donnees A L'INSTALLATION : une ligne app_config (si absente) ; langue_communication des seuls
-- comptes acceptes dont la langue est vide et dont la demande en porte une.

DO $preflight$
BEGIN
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text)') IS NULL
     AND pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : inscrire_titulaire (ONBOARDING-PRAXIS) est absente';
  END IF;
  IF pg_catalog.to_regclass('public.langues_communication') IS NULL THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : langues_communication est absente';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Le canal d'aide
-- ---------------------------------------------------------------------------
INSERT INTO public.app_config (key, value)
VALUES ('support_canal', pg_catalog.jsonb_build_object(
  'type', 'courriel', 'adresse', 'support@rewayahacademy.com'))
ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION public.canal_support_public()
RETURNS TABLE (nature text, adresse text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_valeur jsonb;
BEGIN
  SELECT c.value INTO v_valeur
    FROM public.app_config c
   WHERE c.key = 'support_canal';
  IF pg_catalog.jsonb_typeof(v_valeur) = 'object'
     AND v_valeur ->> 'type' IN ('courriel', 'lien')
     AND pg_catalog.length(pg_catalog.btrim(v_valeur ->> 'adresse')) > 0 THEN
    RETURN QUERY
      SELECT v_valeur ->> 'type', pg_catalog.btrim(v_valeur ->> 'adresse');
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.canal_support_public() FROM PUBLIC, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.canal_support_public() TO anon, authenticated;
COMMENT ON FUNCTION public.canal_support_public() IS
  'AUDIT-FAMILLE-1 (22/11/2026) : le canal d''aide publie (courriel ou lien), sans compte : une personne qui n''arrive pas a entrer n''a pas de compte valide. Ne lit que la cle support_canal, deja publique sur le site.';

-- ---------------------------------------------------------------------------
-- 2. La langue de l'interface, ecrite avec la demande
-- ---------------------------------------------------------------------------
DO $de_cote$
BEGIN
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text)') IS NOT NULL THEN
    ALTER FUNCTION public.inscrire_titulaire(text, text, text, public.gender, text, boolean, jsonb, text)
      RENAME TO inscrire_titulaire_avant_langue;
    ALTER FUNCTION public.inscrire_titulaire_avant_langue(text, text, text, public.gender, text, boolean, jsonb, text)
      SET SCHEMA private;
    ALTER FUNCTION private.inscrire_titulaire_avant_langue(text, text, text, public.gender, text, boolean, jsonb, text)
      SECURITY INVOKER;
    REVOKE ALL ON FUNCTION private.inscrire_titulaire_avant_langue(text, text, text, public.gender, text, boolean, jsonb, text)
      FROM PUBLIC, anon, authenticated, service_role;
    COMMENT ON FUNCTION private.inscrire_titulaire_avant_langue(text, text, text, public.gender, text, boolean, jsonb, text) IS
      'AUDIT-FAMILLE-1 (22/11/2026) : ancienne forme a huit parametres, inerte, a supprimer lors d''un lot de nettoyage avec le directeur present.';
  END IF;
END
$de_cote$;

CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false,
  p_apprenants jsonb DEFAULT NULL,
  p_source text DEFAULT NULL,
  p_langue text DEFAULT NULL
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
  v_candidature uuid;
  v_apprenant jsonb;
  v_rang smallint := 0;
  v_titulaire boolean;
  v_moments text[];
  v_objectif text;
  v_langue text;
  v_juz smallint[];
  v_sourates text[];
  v_langue_interface text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_langue, ''))), '');
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF NOT coalesce(p_usage IN ('moi', 'famille'), false) THEN
    RAISE EXCEPTION 'usage inconnu : %', p_usage USING ERRCODE = '22023';
  END IF;
  IF p_apprenants IS NOT NULL AND (
       pg_catalog.jsonb_typeof(p_apprenants) <> 'array'
       OR pg_catalog.jsonb_array_length(p_apprenants) > 6) THEN
    RAISE EXCEPTION 'apprenants : une liste de 6 au plus' USING ERRCODE = '22023';
  END IF;
  IF p_source IS NOT NULL
     AND p_source NOT IN ('mosquee', 'proche', 'reseaux', 'recherche', 'autre') THEN
    RAISE EXCEPTION 'source inconnue : %', p_source USING ERRCODE = '22023';
  END IF;
  v_profile := private.creer_profil_inscription_interne(
    'guardian', p_first_name, p_last_name, p_gender, p_timezone,
    p_usage = 'moi' OR coalesce(p_suit_des_cours, false));
  UPDATE public.households h
     SET usage_inscription = p_usage
   WHERE h.id = v_profile.household_id;
  -- « Moi » : la demande est celle d'un eleve adulte (liste separee, lot C).
  IF p_usage = 'moi' THEN
    UPDATE public.candidatures c
       SET type_code = 'eleve_adulte'
     WHERE c.profile_id = v_profile.id AND c.type_code = 'famille';
  END IF;

  SELECT c.id INTO v_candidature
    FROM public.candidatures c
   WHERE c.profile_id = v_profile.id
     AND c.type_code IN ('famille', 'eleve_adulte');
  IF p_source IS NOT NULL THEN
    UPDATE public.candidatures c
       SET source_declaree = p_source
     WHERE c.id = v_candidature;
  END IF;
  -- AUDIT-FAMILLE (22/11/2026, R27) : la langue de l'interface au moment de la
  -- demande devient la langue du compte (courriels, lien de connexion) et celle
  -- de la demande. Une langue inconnue ou inactive est ignoree : jamais un refus.
  IF v_langue_interface IS NOT NULL AND EXISTS (
       SELECT 1 FROM public.langues_communication l
        WHERE l.code = v_langue_interface AND l.active) THEN
    UPDATE public.profiles p
       SET langue_communication = v_langue_interface
     WHERE p.id = v_profile.id;
    UPDATE public.candidatures c
       SET langue = v_langue_interface
     WHERE c.id = v_candidature AND v_langue_interface IN ('fr', 'ar', 'en');
  END IF;
  FOR v_apprenant IN
    SELECT e FROM pg_catalog.jsonb_array_elements(coalesce(p_apprenants, '[]'::jsonb)) AS e
  LOOP
    IF pg_catalog.jsonb_typeof(v_apprenant) <> 'object' THEN
      RAISE EXCEPTION 'apprenant illisible' USING ERRCODE = '22023';
    END IF;
    v_rang := v_rang + 1;
    v_titulaire := coalesce((v_apprenant ->> 'est_titulaire')::boolean, false);
    -- « Moi » n'a qu'un apprenant, lui-meme ; « famille » a au moins un
    -- enfant et au plus le parent en plus.
    IF p_usage = 'moi' AND NOT v_titulaire THEN
      RAISE EXCEPTION 'pour moi : un seul apprenant, le titulaire' USING ERRCODE = '22023';
    END IF;
    IF v_titulaire AND NOT (p_usage = 'moi' OR coalesce(p_suit_des_cours, false)) THEN
      RAISE EXCEPTION 'le titulaire ne suit pas de cours' USING ERRCODE = '22023';
    END IF;
    SELECT coalesce(pg_catalog.array_agg(m), '{}'::text[]) INTO v_moments
      FROM pg_catalog.jsonb_array_elements_text(
        coalesce(v_apprenant -> 'moments', '[]'::jsonb)) AS m;
    SELECT coalesce(pg_catalog.array_agg(j::smallint ORDER BY j::smallint), '{}'::smallint[]) INTO v_juz
      FROM pg_catalog.jsonb_array_elements_text(
        coalesce(v_apprenant -> 'juz', '[]'::jsonb)) AS j;
    SELECT coalesce(pg_catalog.array_agg(s), '{}'::text[]) INTO v_sourates
      FROM pg_catalog.jsonb_array_elements_text(
        coalesce(v_apprenant -> 'sourates', '[]'::jsonb)) AS s;
    v_objectif := v_apprenant ->> 'objectif';
    v_langue := nullif(v_apprenant ->> 'langue', '');
    INSERT INTO public.candidature_apprenants (
      candidature_id, rang, est_titulaire, prenom, age, genre,
      niveau_declare, objectif, moments, langue_code,
      riwaya, riwaya_autre, memorise_quantite, juz, sourates, objectif_priere,
      langue_demandee, langue_secours, langue_autre)
    VALUES (
      v_candidature, v_rang, v_titulaire,
      -- Le titulaire porte son prenom de compte, jamais un autre.
      CASE WHEN v_titulaire THEN pg_catalog.btrim(p_first_name)
           ELSE pg_catalog.btrim(v_apprenant ->> 'prenom') END,
      CASE WHEN v_titulaire THEN NULL ELSE (v_apprenant ->> 'age')::smallint END,
      CASE WHEN v_titulaire THEN p_gender
           ELSE (v_apprenant ->> 'genre')::public.gender END,
      v_apprenant ->> 'niveau',
      CASE WHEN v_objectif = 'priere_invocations' THEN NULL ELSE v_objectif END,
      v_moments,
      -- Le referentiel des classes ne connait que ses codes ; une langue des
      -- enseignants hors referentiel reste dans langue_demandee.
      (SELECT l.code FROM public.langues_cours l WHERE l.code = v_langue),
      nullif(v_apprenant ->> 'riwaya', ''),
      nullif(pg_catalog.btrim(coalesce(v_apprenant ->> 'riwaya_autre', '')), ''),
      nullif(v_apprenant ->> 'memorise', ''),
      v_juz,
      v_sourates,
      coalesce(v_objectif = 'priere_invocations', false),
      v_langue,
      nullif(v_apprenant ->> 'langue_secours', ''),
      nullif(pg_catalog.btrim(coalesce(v_apprenant ->> 'langue_autre', '')), ''));
  END LOOP;
  IF p_usage = 'famille' AND p_apprenants IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
        WHERE a.candidature_id = v_candidature AND NOT a.est_titulaire) THEN
    RAISE EXCEPTION 'famille : au moins un enfant' USING ERRCODE = '22023';
  END IF;
  RETURN v_profile;
END;
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)'::pg_catalog.regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=PUBLIC_REGISTRATION; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. AUDIT-FAMILLE-1 : p_langue.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END
$droits$;

-- ---------------------------------------------------------------------------
-- Rattrapage : la langue des comptes deja acceptes, quand leur demande en porte une
-- ---------------------------------------------------------------------------
UPDATE public.profiles p
   SET langue_communication = d.langue
  FROM (
    SELECT c.profile_id,
           coalesce(
             c.langue,
             (SELECT CASE a.langue_demandee
                       WHEN 'francais' THEN 'fr' WHEN 'english' THEN 'en'
                       WHEN 'ar' THEN 'ar' WHEN 'pt' THEN 'pt' END
                FROM public.candidature_apprenants a
               WHERE a.candidature_id = c.id AND a.langue_demandee IS NOT NULL
               ORDER BY a.est_titulaire DESC, a.rang LIMIT 1)) AS langue
      FROM public.candidatures c
     WHERE c.type_code IN ('famille', 'eleve_adulte')
       AND c.etape = 'confirmee' AND c.issue = 'en_cours'
       AND c.profile_id IS NOT NULL
  ) d
 WHERE p.id = d.profile_id
   AND p.langue_communication IS NULL
   AND d.langue IS NOT NULL
   AND EXISTS (SELECT 1 FROM public.langues_communication l WHERE l.code = d.langue AND l.active);

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text,text)'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : DEFINER ou ACL invalide pour inscrire_titulaire';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname = 'inscrire_titulaire' AND p.pronargs <> 9) THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : une autre forme de inscrire_titulaire reste dans public';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.inscrire_titulaire_avant_langue(text,text,text,public.gender,text,boolean,jsonb,text)', 'EXECUTE') THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : l''ancienne forme reste executable';
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.canal_support_public()', 'EXECUTE') IS NOT TRUE THEN
    RAISE EXCEPTION 'AUDIT-FAMILLE-1 : canal_support_public n''est pas ouverte a anon';
  END IF;
END
$postflight$;
