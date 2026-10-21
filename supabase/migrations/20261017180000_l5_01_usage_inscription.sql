-- L5-01 (audit d'entree du 17/10/2026, E6 ; passation du 17/10, point 4) :
-- l'inscription garde le choix « Moi uniquement » ou « Moi et ma famille », et
-- la reponse a « Suivez-vous aussi des cours ? ».
--
-- Constat : l'ecran demandait les deux, mais n'envoyait ni l'un ni l'autre
-- (`creer_profil_inscription` appele sans `p_parent_suit_des_cours`). L'eleve
-- adulte (« Moi ») n'avait donc pas sa fiche d'eleve, et `/attente` choisissait
-- la variante du contrat sur une memoire du navigateur, perdue au rechargement.
--
-- Correction :
-- * `households.usage_inscription` ('moi' ou 'famille'), ecrit une fois, a la
--   creation du foyer ;
-- * `public.inscrire_titulaire(p_usage, ...)` : cree le profil tuteur par le
--   meme corps interne que `creer_profil_inscription` (AF L1-11) et pose
--   l'usage dans la meme transaction. « Moi » ouvre toujours la fiche d'eleve
--   du titulaire ; « Famille » l'ouvre seulement si le parent suit des cours ;
-- * `public.etat_dossier()` rend en plus `usage` et `suit_des_cours`, que le
--   portail d'attente relit au lieu de la memoire du navigateur.
-- `creer_profil_inscription` reste en place (signature et droits inchanges).
BEGIN;

ALTER TABLE public.households
  ADD COLUMN usage_inscription text
  CHECK (usage_inscription IN ('moi', 'famille'));

COMMENT ON COLUMN public.households.usage_inscription IS
  'L5-01 : choix fait a l''inscription par le titulaire (moi : eleve adulte seul ; famille : tuteur de foyer). Choisit la variante du contrat. date=2026-10-17.';

CREATE FUNCTION public.inscrire_titulaire(
  p_usage text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender DEFAULT NULL,
  p_timezone text DEFAULT 'Europe/Paris',
  p_suit_des_cours boolean DEFAULT false
) RETURNS public.profiles
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_profile public.profiles;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'aucune session'; END IF;
  IF NOT coalesce(p_usage IN ('moi', 'famille'), false) THEN
    RAISE EXCEPTION 'usage inconnu : %', p_usage USING ERRCODE = '22023';
  END IF;
  v_profile := private.creer_profil_inscription_interne(
    'guardian', p_first_name, p_last_name, p_gender, p_timezone,
    p_usage = 'moi' OR coalesce(p_suit_des_cours, false));
  UPDATE public.households h
     SET usage_inscription = p_usage
   WHERE h.id = v_profile.household_id;
  RETURN v_profile;
END;
$function$;

CREATE OR REPLACE FUNCTION public.etat_dossier()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_profile public.profiles;
  v_doc public.kyc_documents;
  v_contrat boolean;
  v_accuse boolean;
  v_usage text;
  v_suit boolean;
begin
  if auth.uid() is null then
    raise exception 'aucune session';
  end if;

  select * into v_profile
  from public.profiles p where p.id = auth.uid() and p.deleted_at is null;

  -- Aucun profil : c'est une inscription a terminer, pas un dossier a attendre.
  if v_profile.id is null then
    return jsonb_build_object('profil', false);
  end if;

  select * into v_doc
  from public.kyc_documents k
  where k.profile_id = v_profile.id and k.deleted_at is null
  order by k.created_at desc
  limit 1;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = case when v_profile.role = 'teacher'
                                 then 'teacher_nda' else 'guardian_terms' end
  ) into v_contrat;

  select exists (
    select 1 from public.contract_acceptances c
    where c.profile_id = v_profile.id
      and c.contract_kind = 'recording_and_control_notice'
  ) into v_accuse;

  -- L5-01 : l'usage choisi a l'inscription, et la fiche d'eleve du titulaire.
  select h.usage_inscription into v_usage
  from public.households h
  where h.id = v_profile.household_id and h.primary_guardian_id = v_profile.id;

  select exists (
    select 1 from public.student_profiles s
    where s.profile_id = v_profile.id
  ) into v_suit;

  return jsonb_build_object(
    'profil', true,
    'role', v_profile.role::text,
    'statut', v_profile.account_status::text,
    'piece_deposee', v_doc.id is not null,
    'piece_statut', v_doc.status::text,
    'motif_refus', v_doc.rejection_reason,
    'depose_le', v_doc.created_at,
    'contrat_signe', v_contrat,
    'accuse_signe', v_accuse,
    'usage', v_usage,
    'suit_des_cours', v_suit
  );
end;
$function$;

DO $droits$
DECLARE
  v_oid regprocedure := 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)'::regprocedure;
BEGIN
  EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', v_oid);
  EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', v_oid);
  EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', v_oid);
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_oid, pg_catalog.format(
    'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=PUBLIC_REGISTRATION; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-17. L5-01.',
    v_oid::text, pg_catalog.md5(pg_catalog.pg_get_functiondef(v_oid))));
END;
$droits$;

DO $postflight$
DECLARE
  v_oid regprocedure := 'public.inscrire_titulaire(text,text,text,public.gender,text,boolean)'::regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.proowner = 'postgres'::regrole AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'L5-01 : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
  IF pg_catalog.has_function_privilege('anon', 'public.etat_dossier()'::regprocedure, 'EXECUTE') THEN
    RAISE EXCEPTION 'L5-01 : etat_dossier executable par anon';
  END IF;
END;
$postflight$;

COMMIT;
