-- ONBOARDING-PRAXIS (directeur, 22/11/2026 ; maquette validee
-- docs/current/maquettes/onboarding-praxis/prototype.html, decisions datees dans
-- docs/current/ONBOARDING-PRAXIS-2026-11-22.md). La demande d'admission garde
-- les nouvelles reponses du questionnaire pose avant le compte.
--
-- 1. public.candidature_apprenants recoit, par apprenant (colonnes ajoutees,
--    aucune retiree) :
--    - riwaya ('hafs', 'warsh', 'autre') et riwaya_autre (texte libre, 40 au
--      plus, seulement avec 'autre') : posees seulement pour « lit deja le
--      Coran » et « a deja memorise une partie » ;
--    - memorise_quantite ('quelques_sourates', '1_5_juz', 'plus_5_juz',
--      'coran_entier') : seulement pour « a deja memorise une partie » ;
--    - juz smallint[] (1 a 30) et sourates text[] (les 17 sourates des bases,
--      par un code stable) : le detail facultatif, jamais pour « tout le
--      Coran » ;
--    - objectif_priere : l'objectif « La priere et les invocations » (enfant
--      seulement). L'ancien CHECK de `objectif` n'est pas reecrit (aucun mot
--      d'effacement dans ce lot) : cet objectif se range ici, `objectif` reste
--      nul ;
--    - langue_demandee (le code de la langue choisie, l'une des langues des
--      enseignants, au referentiel ou non : `langue_code`, qui pointe le
--      referentiel des classes, n'est rempli que si elle y est),
--      langue_secours (la langue de repli, facultative, distincte) et
--      langue_autre (« une langue absente de la liste », texte libre, pour
--      mesurer la demande).
-- 2. public.candidatures recoit source_declaree ('mosquee', 'proche',
--    'reseaux', 'recherche', 'autre'), facultative.
-- 3. public.inscrire_titulaire recoit p_source (8e parametre) et range les
--    nouvelles cles de p_apprenants. La forme a sept parametres est mise de
--    cote comme au lot B (renommee, schema private, INVOKER, aucun droit) :
--    deux formes appelables avec sept arguments seraient ambigues.
-- 4. public.lister_demandes_admission rend les nouveaux champs (meme
--    signature, meme garde, meme pagination).
--
-- Rejouable. Sans BEGIN ni COMMIT de premier niveau. Mots d'effacement : 0.
-- Aucune ecriture sur des donnees de personnes : les lignes existantes gardent
-- des colonnes nulles ou vides.

-- ---------------------------------------------------------------------------
-- 0. Preflight
-- ---------------------------------------------------------------------------
DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.candidature_apprenants') IS NULL
     OR pg_catalog.to_regprocedure('public.lister_demandes_admission(text,text,integer)') IS NULL
     OR (pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb)') IS NULL
         AND pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text)') IS NULL) THEN
    RAISE EXCEPTION 'ONBOARDING-PRAXIS : installer d''abord les admissions (lots B et C)';
  END IF;
END
$preflight$;

-- ---------------------------------------------------------------------------
-- 1. Les colonnes
-- ---------------------------------------------------------------------------
ALTER TABLE public.candidature_apprenants
  ADD COLUMN IF NOT EXISTS riwaya text NULL,
  ADD COLUMN IF NOT EXISTS riwaya_autre text NULL,
  ADD COLUMN IF NOT EXISTS memorise_quantite text NULL,
  ADD COLUMN IF NOT EXISTS juz smallint[] NOT NULL DEFAULT '{}'::smallint[],
  ADD COLUMN IF NOT EXISTS sourates text[] NOT NULL DEFAULT '{}'::text[],
  ADD COLUMN IF NOT EXISTS objectif_priere boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS langue_demandee text NULL,
  ADD COLUMN IF NOT EXISTS langue_secours text NULL,
  ADD COLUMN IF NOT EXISTS langue_autre text NULL;

ALTER TABLE public.candidatures
  ADD COLUMN IF NOT EXISTS source_declaree text NULL;

DO $contraintes$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_riwaya',
       $c$CHECK (riwaya IS NULL OR riwaya IN ('hafs', 'warsh', 'autre'))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_riwaya_selon_niveau',
       $c$CHECK (riwaya IS NULL OR niveau_declare IN ('lecture_courante', 'memorisation_partielle'))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_riwaya_autre',
       $c$CHECK (riwaya_autre IS NULL OR (riwaya = 'autre'
                 AND pg_catalog.length(pg_catalog.btrim(riwaya_autre)) BETWEEN 1 AND 40))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_memorise_quantite',
       $c$CHECK (memorise_quantite IS NULL OR (niveau_declare = 'memorisation_partielle'
                 AND memorise_quantite IN ('quelques_sourates', '1_5_juz', 'plus_5_juz', 'coran_entier')))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_juz',
       $c$CHECK (pg_catalog.cardinality(juz) <= 30
                 AND juz <@ '{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30}'::smallint[])$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_sourates',
       $c$CHECK (pg_catalog.cardinality(sourates) <= 17
                 AND sourates <@ ARRAY['fatiha', 'nas', 'falaq', 'ikhlas', 'masad', 'nasr', 'kafirun',
                   'kawthar', 'maun', 'quraysh', 'fil', 'humaza', 'asr', 'takathur', 'qaria',
                   'adiyat', 'zalzala']::text[])$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_detail_memorise',
       $c$CHECK ((pg_catalog.cardinality(juz) = 0 AND pg_catalog.cardinality(sourates) = 0)
                 OR memorise_quantite IN ('quelques_sourates', '1_5_juz', 'plus_5_juz'))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_objectif_priere',
       $c$CHECK (NOT objectif_priere OR (NOT est_titulaire AND objectif IS NULL))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_langue_demandee',
       $c$CHECK (langue_demandee IS NULL OR langue_demandee ~ '^[a-z]{2,8}$')$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_langue_secours',
       $c$CHECK (langue_secours IS NULL OR (langue_secours ~ '^[a-z]{2,8}$'
                 AND langue_secours IS DISTINCT FROM langue_demandee))$c$),
      ('public.candidature_apprenants'::pg_catalog.regclass, 'candidature_apprenants_langue_autre',
       $c$CHECK (langue_autre IS NULL OR pg_catalog.length(pg_catalog.btrim(langue_autre)) BETWEEN 1 AND 40)$c$),
      ('public.candidatures'::pg_catalog.regclass, 'candidatures_source_declaree',
       $c$CHECK (source_declaree IS NULL
                 OR source_declaree IN ('mosquee', 'proche', 'reseaux', 'recherche', 'autre'))$c$)
    ) AS t(tbl, nom, def)
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_constraint c
                    WHERE c.conrelid = v.tbl AND c.conname = v.nom) THEN
      EXECUTE pg_catalog.format('ALTER TABLE %s ADD CONSTRAINT %I %s', v.tbl, v.nom, v.def);
    END IF;
  END LOOP;
END
$contraintes$;

COMMENT ON COLUMN public.candidature_apprenants.objectif_priere IS
  'ONBOARDING-PRAXIS (22/11/2026) : objectif « La priere et les invocations » (enfant seulement) ; objectif reste nul.';
COMMENT ON COLUMN public.candidature_apprenants.langue_demandee IS
  'ONBOARDING-PRAXIS (22/11/2026) : code de la langue des explications choisie (langues des enseignants) ; langue_code n''est rempli que si ce code est au referentiel langues_cours.';
COMMENT ON COLUMN public.candidatures.source_declaree IS
  'ONBOARDING-PRAXIS (22/11/2026) : « Comment avez-vous connu Rewayah ? », facultatif (familles et eleves adultes).';

-- ---------------------------------------------------------------------------
-- 2. La forme a sept parametres, mise de cote (comme au lot B)
-- ---------------------------------------------------------------------------
DO $de_cote$
BEGIN
  IF pg_catalog.to_regprocedure('public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb)') IS NOT NULL THEN
    ALTER FUNCTION public.inscrire_titulaire(text, text, text, public.gender, text, boolean, jsonb)
      RENAME TO inscrire_titulaire_avant_onboarding;
    ALTER FUNCTION public.inscrire_titulaire_avant_onboarding(text, text, text, public.gender, text, boolean, jsonb)
      SET SCHEMA private;
    ALTER FUNCTION private.inscrire_titulaire_avant_onboarding(text, text, text, public.gender, text, boolean, jsonb)
      SECURITY INVOKER;
    REVOKE ALL ON FUNCTION private.inscrire_titulaire_avant_onboarding(text, text, text, public.gender, text, boolean, jsonb)
      FROM PUBLIC, anon, authenticated, service_role;
    COMMENT ON FUNCTION private.inscrire_titulaire_avant_onboarding(text, text, text, public.gender, text, boolean, jsonb) IS
      'ONBOARDING-PRAXIS (22/11/2026) : ancienne forme a sept parametres, inerte, a supprimer lors d''un lot de nettoyage avec le directeur present.';
  END IF;
END
$de_cote$;

-- ---------------------------------------------------------------------------
-- 3. inscrire_titulaire, avec p_source et les nouvelles reponses
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false,
  p_apprenants jsonb DEFAULT NULL,
  p_source text DEFAULT NULL
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

-- ---------------------------------------------------------------------------
-- 4. lister_demandes_admission, avec les nouveaux champs
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lister_demandes_admission(
  p_type text, p_recherche text DEFAULT NULL, p_page integer DEFAULT 1)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_recherche text := nullif(pg_catalog.lower(pg_catalog.btrim(coalesce(p_recherche, ''))), '');
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_lignes jsonb;
  v_total integer;
  v_a_traiter integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'listes des admissions reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_type IS NULL OR p_type NOT IN ('famille', 'eleve_adulte') THEN
    RAISE EXCEPTION 'population inconnue : famille ou eleve_adulte' USING ERRCODE = '22023';
  END IF;
  WITH filtrees AS (
    SELECT c.*, public.courriel_adresse_profil(c.profile_id) AS courriel
      FROM public.candidatures c
     WHERE c.type_code = p_type
       AND (v_recherche IS NULL
            OR pg_catalog.strpos(pg_catalog.lower(c.nom_complet), v_recherche) > 0
            OR pg_catalog.strpos(pg_catalog.lower(c.reference), v_recherche) > 0
            OR pg_catalog.strpos(coalesce(pg_catalog.lower(public.courriel_adresse_profil(c.profile_id)), ''),
                                 v_recherche) > 0)
  )
  SELECT
    coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
      'id', f.id,
      'reference', f.reference,
      'nom', f.nom_complet,
      'courriel', f.courriel,
      'recueLe', f.recue_le,
      'etape', f.etape,
      'etat', f.etat,
      'issue', f.issue,
      'version', f.version,
      'derniereActivite', f.derniere_activite,
      'source', f.source_declaree,
      'apprenants', (
        SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                 'prenom', a.prenom, 'age', a.age, 'genre', a.genre,
                 'estTitulaire', a.est_titulaire, 'niveau', a.niveau_declare,
                 'objectif', CASE WHEN a.objectif_priere THEN 'priere_invocations' ELSE a.objectif END,
                 'moments', a.moments, 'langue', coalesce(a.langue_demandee, a.langue_code),
                 'riwaya', a.riwaya, 'riwayaAutre', a.riwaya_autre,
                 'memorise', a.memorise_quantite, 'juz', pg_catalog.to_jsonb(a.juz),
                 'sourates', pg_catalog.to_jsonb(a.sourates),
                 'langueSecours', a.langue_secours, 'langueAutre', a.langue_autre)
                 ORDER BY a.rang), '[]'::jsonb)
          FROM public.candidature_apprenants a WHERE a.candidature_id = f.id)
    ) ORDER BY (f.issue = 'en_cours') DESC, f.recue_le, f.id)
    FILTER (WHERE f.rang_page = v_page), '[]'::jsonb),
    pg_catalog.count(*)::integer
    INTO v_lignes, v_total
    FROM (SELECT x.*, ((pg_catalog.row_number() OVER (
                   ORDER BY (x.issue = 'en_cours') DESC, x.recue_le, x.id) - 1) / 50 + 1)
                   AS rang_page
            FROM filtrees x) f;
  SELECT pg_catalog.count(*)::integer INTO v_a_traiter
    FROM public.candidatures c
   WHERE c.type_code = p_type AND c.issue = 'en_cours' AND c.etape = 'recue';
  RETURN pg_catalog.jsonb_build_object('lignes', v_lignes, 'total', v_total,
    'aTraiter', v_a_traiter, 'page', v_page, 'parPage', 50);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 5. Droits et empreintes
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text)'::pg_catalog.regprocedure,
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-22. ONBOARDING-PRAXIS.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid)),
      CASE WHEN v_oid::text LIKE 'inscrire_titulaire%' THEN 'PUBLIC_REGISTRATION' ELSE 'ADMIN_ONLY' END));
  END LOOP;
END
$droits$;

-- ---------------------------------------------------------------------------
-- 6. Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb,text)'::pg_catalog.regprocedure,
    'public.lister_demandes_admission(text,text,integer)'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'ONBOARDING-PRAXIS : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
              WHERE n.nspname = 'public' AND p.proname = 'inscrire_titulaire' AND p.pronargs <> 8) THEN
    RAISE EXCEPTION 'ONBOARDING-PRAXIS : une autre forme de inscrire_titulaire reste dans public';
  END IF;
  IF pg_catalog.has_function_privilege('authenticated',
       'private.inscrire_titulaire_avant_onboarding(text,text,text,public.gender,text,boolean,jsonb)', 'EXECUTE') THEN
    RAISE EXCEPTION 'ONBOARDING-PRAXIS : l''ancienne forme reste executable';
  END IF;
  IF pg_catalog.has_table_privilege('authenticated', 'public.candidature_apprenants', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.candidature_apprenants', 'SELECT') THEN
    RAISE EXCEPTION 'ONBOARDING-PRAXIS : candidature_apprenants lisible par un client';
  END IF;
END
$postflight$;
