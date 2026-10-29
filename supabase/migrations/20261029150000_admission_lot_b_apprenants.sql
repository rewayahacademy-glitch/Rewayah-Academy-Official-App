-- ADMISSION lot B, onboarding (fiche docs/current/FICHE-ONBOARDING-2026-10-29.md,
-- validee le 29/10/2026 par le pilote sur delegation du directeur, Q2) : la
-- demande garde ses apprenants. Aucune donnee d'enfant dans un compte cree
-- avant la decision : les profils des enfants sont crees a l'acceptation
-- (lot C), a partir de ces lignes, sans rien ressaisir.
--
-- 1. public.candidature_apprenants : une ligne par apprenant de la demande
--    (le titulaire quand il suit des cours, et chaque enfant). RLS sans
--    politique ni droit client, comme les autres tables des candidatures :
--    on la lit par fonction.
-- 2. public.inscrire_titulaire recoit p_apprenants (JSON borne : 6 au plus,
--    champs valides) et les range dans la meme transaction que la demande.
--    Remplace la signature a six parametres (DROP puis CREATE : l'ancienne
--    forme rendrait l'appel nomme ambigu).
-- 3. public.mes_apprenants_demande() : le titulaire relit les prenoms et
--    les ages de sa demande, pour la page d'attente.

BEGIN;

CREATE TABLE public.candidature_apprenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id) ON DELETE CASCADE,
  rang smallint NOT NULL CHECK (rang BETWEEN 1 AND 6),
  -- Le titulaire lui-meme (« pour moi », ou le parent qui suit des cours).
  est_titulaire boolean NOT NULL DEFAULT false,
  prenom text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(prenom)) BETWEEN 1 AND 80),
  -- L'age d'un enfant, a la demande ; nul pour le titulaire (adulte).
  age smallint NULL CHECK (age BETWEEN 5 AND 17),
  genre public.gender NOT NULL,
  niveau_declare text NULL CHECK (niveau_declare IN (
    'debut_lettres', 'lettres_avec_aide', 'lecture_lente',
    'lecture_courante', 'memorisation_partielle')),
  objectif text NULL CHECK (objectif IN (
    'apprendre_a_lire', 'devenir_fluide', 'memoriser', 'indecis')),
  moments text[] NOT NULL DEFAULT '{}'::text[]
    CHECK (moments <@ ARRAY['matin', 'apres_midi', 'soir']::text[]),
  langue_code text NULL REFERENCES public.langues_cours(code),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.now(),
  CONSTRAINT candidature_apprenants_rang_unique UNIQUE (candidature_id, rang),
  CONSTRAINT candidature_apprenants_age_selon_titulaire
    CHECK ((est_titulaire AND age IS NULL) OR (NOT est_titulaire AND age IS NOT NULL))
);
CREATE UNIQUE INDEX candidature_apprenants_un_titulaire
  ON public.candidature_apprenants (candidature_id) WHERE est_titulaire;

ALTER TABLE public.candidature_apprenants ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.candidature_apprenants FROM PUBLIC, anon, authenticated;

DROP FUNCTION public.inscrire_titulaire(text, text, text, public.gender, text, boolean);

CREATE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false,
  p_apprenants jsonb DEFAULT NULL
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
    INSERT INTO public.candidature_apprenants (
      candidature_id, rang, est_titulaire, prenom, age, genre,
      niveau_declare, objectif, moments, langue_code)
    VALUES (
      v_candidature, v_rang, v_titulaire,
      -- Le titulaire porte son prenom de compte, jamais un autre.
      CASE WHEN v_titulaire THEN pg_catalog.btrim(p_first_name)
           ELSE pg_catalog.btrim(v_apprenant ->> 'prenom') END,
      CASE WHEN v_titulaire THEN NULL ELSE (v_apprenant ->> 'age')::smallint END,
      CASE WHEN v_titulaire THEN p_gender
           ELSE (v_apprenant ->> 'genre')::public.gender END,
      v_apprenant ->> 'niveau',
      v_apprenant ->> 'objectif',
      v_moments,
      nullif(v_apprenant ->> 'langue', ''));
  END LOOP;
  IF p_usage = 'famille' AND p_apprenants IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.candidature_apprenants a
        WHERE a.candidature_id = v_candidature AND NOT a.est_titulaire) THEN
    RAISE EXCEPTION 'famille : au moins un enfant' USING ERRCODE = '22023';
  END IF;
  RETURN v_profile;
END;
$function$;

-- Le titulaire relit les apprenants de sa propre demande d'admission :
-- prenom, age, titulaire ou non, dans l'ordre. Rien d'autre, aucune autre
-- demande.
CREATE FUNCTION public.mes_apprenants_demande()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'prenom', a.prenom,
           'age', a.age,
           'est_titulaire', a.est_titulaire) ORDER BY a.rang), '[]'::jsonb)
    FROM public.candidature_apprenants a
    JOIN public.candidatures c ON c.id = a.candidature_id
   WHERE c.profile_id = auth.uid()
     AND c.type_code IN ('famille', 'eleve_adulte');
$function$;

DO $droits$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb)'::pg_catalog.regprocedure,
    'public.mes_apprenants_demande()'::pg_catalog.regprocedure
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=PUBLIC_REGISTRATION; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-29. Admission lot B, apprenants de la demande.',
      v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  FOREACH v_oid IN ARRAY ARRAY[
    'public.inscrire_titulaire(text,text,text,public.gender,text,boolean,jsonb)'::pg_catalog.regprocedure,
    'public.mes_apprenants_demande()'::pg_catalog.regprocedure
  ] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                     AND p.proowner = 'postgres'::pg_catalog.regrole
                     AND p.proconfig @> ARRAY['search_path=""'])
       OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Admission lot B : DEFINER ou ACL invalide pour %', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_table_privilege('authenticated', 'public.candidature_apprenants', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.candidature_apprenants', 'SELECT') THEN
    RAISE EXCEPTION 'Admission lot B : candidature_apprenants lisible par un client';
  END IF;
END;
$postflight$;

COMMIT;
