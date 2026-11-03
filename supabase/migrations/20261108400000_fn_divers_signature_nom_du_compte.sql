-- FN-DIVERS, partie serveur (rang 21 de PLAN-LOTS, garde-cap, 03/11/2026) :
-- FN-102, « signature au nom d'un autre ».
--
-- Constat (UX-CONSTATS, FN-102, 31/10/2026) : la signature du contrat
-- enseignant (`teacher_nda`) accepte un nom sans rapport avec le compte
-- (« Quelqu'un d'autre » pour « E2E Candidate Pieges »), alors que l'ecran
-- demande le nom « comme sur votre piece d'identite ».
--
-- Ce qui etait deja vrai, et le reste : la signature est toujours celle du
-- compte connecte. `public.signer_contrat` ecrit `profile_id = auth.uid()`,
-- la politique `contract_acceptances_self_insert` exige la meme egalite, et le
-- declencheur `completer_contract_acceptance` refuse toute ligne `teacher_nda`
-- dont le profil n'est pas l'appelant (`acces_signature_refusee`). Le scenario
-- supabase/tests/scenarios_fn_divers_signature.sql le prouve, en
-- authenticated, avec le refus nomme.
--
-- Ce qui change (decision du garde-cap du 03/11, sans comparaison de noms,
-- fragile : alphabets, accents) : comme les grands services de signature, le
-- nom signe est lie a l'identite connectee. Le declencheur
-- `completer_contract_acceptance` ecrit lui-meme `signer_name` a partir du nom
-- du compte (`profiles.first_name` et `last_name`) et ignore le nom envoye,
-- par la RPC comme par une insertion directe. Un compte sans nom ne signe pas
-- (`nom_compte_vide`). `signer_contrat` garde sa signature (le client envoie
-- encore un nom, qui n'est plus lu) ; l'ecran qui montrera le nom en lecture
-- seule attend la file `lib/`.
--
-- Les signatures deja posees ne changent pas (la table est en ajout seul).
--
-- FICHIER SANS EFFACEMENT (regle B5) : deux fonctions remplacees a signature
-- et droits egaux ; aucune table, ligne, contrainte ni declencheur retire.

BEGIN;

CREATE OR REPLACE FUNCTION public.completer_contract_acceptance()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
DECLARE
  v_texte public.contract_texts%rowtype;
  v_nom text;
BEGIN
  IF NEW.signed_sha256 IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'empreinte_signature_fournie_par_client_interdite';
  END IF;

  IF NEW.contract_kind <> 'teacher_nda' THEN
    NEW.signer_name := NULL;
    NEW.signed_sha256 := NULL;
    RETURN NEW;
  END IF;

  IF NOT coalesce(
    auth.uid() IS NOT NULL
    AND NEW.profile_id = auth.uid()
    AND public.app_role() = 'teacher'::public.app_role
    AND EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.role = 'teacher'::public.app_role
        AND p.deleted_at IS NULL
        AND p.account_status IN (
          'pending_kyc'::public.account_status,
          'provisional_active'::public.account_status,
          'active'::public.account_status
        )
    ),
    false
  ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'acces_signature_refusee';
  END IF;

  -- FN-102 : le nom signe est celui du compte connecte, jamais celui envoye.
  SELECT pg_catalog.btrim(pg_catalog.concat_ws(' ',
           nullif(pg_catalog.btrim(p.first_name), ''),
           nullif(pg_catalog.btrim(p.last_name), '')))
    INTO v_nom
    FROM public.profiles p
   WHERE p.id = auth.uid();
  IF v_nom IS NULL OR pg_catalog.length(v_nom) = 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'nom_compte_vide';
  END IF;
  IF pg_catalog.char_length(v_nom) > 120 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'nom_trop_long';
  END IF;

  SELECT t.* INTO v_texte
  FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda'
    AND t.version = NEW.version
    AND t.locale = 'fr'
    AND t.is_current;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'contrat_version_non_courante';
  END IF;

  NEW.signer_name := v_nom;
  NEW.signed_sha256 := v_texte.sha256;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.signer_contrat(p_version text, p_nom_saisi text)
RETURNS public.contract_acceptances
LANGUAGE plpgsql
SET search_path = ''
AS $function$
declare
  v_courant public.contract_texts%rowtype;
  v_signature public.contract_acceptances%rowtype;
  v_uid uuid := auth.uid();
begin
  if not coalesce(
    v_uid is not null
    and public.app_role() = 'teacher'::public.app_role,
    false
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;
  if not exists (
    select 1 from public.profiles p
    where p.id = v_uid and p.role = 'teacher'::public.app_role
      and p.deleted_at is null
      and p.account_status in (
        'pending_kyc'::public.account_status,
        'provisional_active'::public.account_status,
        'active'::public.account_status
      )
  ) then
    raise exception using errcode = '42501', message = 'acces_signature_refusee';
  end if;

  -- FN-102 : `p_nom_saisi` n'est plus lu. Le declencheur
  -- completer_contract_acceptance ecrit le nom du compte connecte.

  select t.* into v_courant
  from public.contract_texts t
  where t.contract_kind = 'teacher_nda'
    and t.locale = 'fr'
    and t.is_current;

  if not found then
    raise exception using errcode = 'P0002', message = 'contrat_introuvable';
  end if;
  if p_version is distinct from v_courant.version then
    raise exception using
      errcode = 'P0001',
      message = 'version_perimee:' || v_courant.version;
  end if;

  insert into public.contract_acceptances (
    profile_id, contract_kind, version, signer_name
  ) values (
    v_uid, 'teacher_nda', v_courant.version, NULL
  )
  on conflict (profile_id, contract_kind, version) do nothing
  returning * into v_signature;

  if not found then
    select c.* into v_signature
    from public.contract_acceptances c
    where c.profile_id = v_uid
      and c.contract_kind = 'teacher_nda'
      and c.version = v_courant.version;
  end if;

  if v_signature.id is null or v_signature.signed_sha256 is null
     or v_signature.signer_name is null then
    raise exception 'signature enseignant incomplete';
  end if;
  return v_signature;
end;
$function$;

-- Postflight ----------------------------------------------------------------
-- Aucun nombre ecrit en dur : on lit les fonctions installees et leurs droits.
DO $postflight$
DECLARE
  v_declencheur pg_catalog.regprocedure := 'public.completer_contract_acceptance()'::pg_catalog.regprocedure;
  v_rpc pg_catalog.regprocedure := 'public.signer_contrat(text,text)'::pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = v_declencheur), 'nom_compte_vide') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p WHERE p.oid = v_rpc), 'p_nom_saisi)') > 0 THEN
    RAISE EXCEPTION 'FN-102 : le nom signe ne vient pas encore du compte';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_trigger t
                  WHERE t.tgrelid = 'public.contract_acceptances'::pg_catalog.regclass
                    AND t.tgfoid = v_declencheur AND t.tgenabled <> 'D') THEN
    RAISE EXCEPTION 'FN-102 : le declencheur de signature n''est plus pose';
  END IF;
  IF pg_catalog.has_function_privilege('anon', v_rpc, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('authenticated', v_rpc, 'EXECUTE')
     OR pg_catalog.has_function_privilege('authenticated', v_declencheur, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_declencheur, 'EXECUTE') THEN
    RAISE EXCEPTION 'FN-102 : droits d''execution modifies';
  END IF;
END;
$postflight$;

COMMIT;
