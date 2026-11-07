-- PROFIL-TITULAIRE (pilote, 07/11/2026)
--
-- Constat en production : le profil eleve du titulaire (cree par
-- creer_profil_eleve_titulaire, migration 0052) n'apparait dans aucune liste
-- du foyer. Cause : public.profils_du_foyer_v ne garde que p.role = 'student',
-- alors que le profil eleve du titulaire est SA propre ligne de profiles, de
-- role 'guardian', avec une fiche student_profiles dont titulaire_profile_id
-- vaut son propre identifiant (0052:118-121, student_type 'autonomous',
-- cohorte 'adulte_18_plus').
--
-- Correction a la source : la vue garde les eleves ET le profil eleve du
-- titulaire, et rien d'autre. Un tuteur sans fiche d'apprentissage n'a pas de
-- ligne (la jointure student_profiles l'exclut deja) ; un tuteur dont la fiche
-- ne porte pas titulaire_profile_id = son id non plus.
--
-- AUCUNE AUTRE GARDE NE CHANGE : foyer de l'appelant (app_household_id),
-- compte valide (app_account_valid), tuteur du foyer ou l'apprenant lui-meme
-- (app_role / auth.uid()), lignes non supprimees, masquage d'agent
-- (agent_identite_masquee), security_barrier. Memes colonnes, meme ordre.
--
-- RECOPIE DECLAREE : la definition est celle de
-- 20261017120200_af_l1_02_reprise_vue_foyer.sql, derniere du depot, dont
-- md5(pg_get_viewdef('public.profils_du_foyer_v'::regclass)) vaut en
-- PRODUCTION 118e78973e56ddefe80303a18118d2d9 (releve du pilote, 07/11/2026,
-- lecture seule) et la meme valeur sur une base nue rejouant le depot. Le
-- preflight l'exige, ou la forme d'apres (migration rejouee).
--
-- Rien d'autre a changer cote serveur pour la recharge : recharge_beneficiaires
-- n'a pas de filtre de role, et private.fac_tarif_profil rend le tarif adulte
-- pour une fiche 'autonomous' (scenario scenarios_profil_titulaire_foyer.sql).
--
-- Aucun effacement de ligne ni d'objet. Aucune fonction creee ni remplacee.
-- Pas de BEGIN/COMMIT de premier niveau.

-- Preflight : la definition de production, ou deja celle-ci. ----------------

DO $preflight$
DECLARE
  v_md5 text := pg_catalog.md5(pg_catalog.pg_get_viewdef('public.profils_du_foyer_v'::pg_catalog.regclass));
  v_colonnes text;
BEGIN
  SELECT pg_catalog.string_agg(a.attname, ',' ORDER BY a.attnum) INTO v_colonnes
    FROM pg_catalog.pg_attribute a
   WHERE a.attrelid = 'public.profils_du_foyer_v'::pg_catalog.regclass
     AND a.attnum > 0 AND NOT a.attisdropped;
  IF v_colonnes IS DISTINCT FROM
     'id,first_name,immutable_id,interface_mode,camera_policy,avatar_storage_key,access_until' THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : profils_du_foyer_v n''a pas la forme attendue (%)', v_colonnes;
  END IF;
  IF v_md5 <> '118e78973e56ddefe80303a18118d2d9'
     AND pg_catalog.pg_get_viewdef('public.profils_du_foyer_v'::pg_catalog.regclass)
         NOT LIKE '%titulaire_profile_id%' THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : profils_du_foyer_v n''est pas la definition de production (md5 %)', v_md5;
  END IF;
END;
$preflight$;

-- La vue -----------------------------------------------------------------------

CREATE OR REPLACE VIEW public.profils_du_foyer_v
WITH (security_barrier = true)
AS
SELECT
  p.id,
  CASE WHEN public.agent_identite_masquee()
       THEN p.immutable_id ELSE p.first_name END AS first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key,
  p.access_until
FROM public.profiles p
JOIN public.student_profiles sp ON sp.profile_id = p.id
WHERE p.household_id IS NOT NULL
  AND p.household_id = public.app_household_id()
  -- PROFIL-TITULAIRE : les eleves, et le profil eleve du titulaire.
  AND (p.role = 'student'
       OR (p.role = 'guardian' AND sp.titulaire_profile_id = p.id))
  AND p.deleted_at IS NULL
  AND sp.deleted_at IS NULL
  AND public.app_account_valid()
  AND (public.app_role() = 'guardian'
       OR (public.app_role() = 'student' AND p.id = auth.uid()));

-- Postflight --------------------------------------------------------------------

DO $postflight$
DECLARE
  v_def text := pg_catalog.pg_get_viewdef('public.profils_du_foyer_v'::pg_catalog.regclass, true);
BEGIN
  IF v_def NOT LIKE '%guardian%' OR v_def NOT LIKE '%app_account_valid%'
     OR v_def NOT LIKE '%app_household_id%' OR v_def NOT LIKE '%auth.uid()%' THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : la clause d''acces manque dans profils_du_foyer_v';
  END IF;
  IF v_def NOT LIKE '%agent_identite_masquee%' THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : le masquage d''agent a ete perdu';
  END IF;
  IF v_def NOT LIKE '%titulaire_profile_id%' THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : le profil eleve du titulaire manque';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c
                  WHERE c.oid = 'public.profils_du_foyer_v'::pg_catalog.regclass
                    AND coalesce(c.reloptions, '{}') @> ARRAY['security_barrier=true']) THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : security_barrier perdu';
  END IF;
  -- Droits inchanges : CREATE OR REPLACE VIEW garde ceux d'avant. anon a
  -- SELECT sur cette vue depuis l'origine (privileges par defaut) ; il n'y lit
  -- aucune ligne (app_account_valid, app_role). Ce lot ne touche pas aux
  -- droits (« ne change aucune autre garde »).
  IF NOT pg_catalog.has_table_privilege('authenticated', 'public.profils_du_foyer_v', 'SELECT') THEN
    RAISE EXCEPTION 'PROFIL-TITULAIRE : profils_du_foyer_v n''est plus lisible par authenticated';
  END IF;
END;
$postflight$;
