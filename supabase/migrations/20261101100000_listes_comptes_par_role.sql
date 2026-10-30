-- LISTES, Comptes séparé par rôle (directeur, 30/10/2026, capture de l'écran
-- Comptes au téléphone) : « les élèves doivent être à part, parce qu'on ne peut
-- pas ajouter les tuteurs directement dans une classe ».
--
-- `comptes_admin()` rend une ligne par profil (son `immutable_id` est le
-- matricule RA depuis IMM-BACK-1), sans tranche d'âge, sans classe et sans le
-- tuteur d'un élève : l'écran ne peut ni séparer
-- proprement les vues Élèves et Familles, ni dire de qui dépend un élève. On
-- n'en change pas le type de retour (il faudrait le supprimer d'abord) : une
-- lecture voisine, `comptes_admin_par_role()`, rend les mêmes lignes, avec la
-- même porte, le même masquage et la même portée des comptes candidats, plus :
--
--   * teacher_country  : le pays déclaré d'un enseignant (ENS-PAYS-1) ;
--   * tranche_age      : 'enfant' ou 'adulte' (student_profiles.student_type),
--                        nul hors élève ; jamais une date de naissance ;
--   * classe_id, classe_libelle, classe_numero, classes_actives : la classe
--                        active d'un élève (la plus ancienne s'il en a
--                        plusieurs) et le nombre de ses classes actives ;
--   * tuteur_id, tuteur_prenom, tuteur_nom : le tuteur du foyer d'un élève
--                        (le tuteur principal, sinon le plus ancien tuteur du
--                        foyer) ; nul hors élève et sous masquage d'identité
--                        pour le prénom et le nom ;
--   * admission_a_traiter : vrai quand le profil porte une demande d'admission
--                        (famille ou élève adulte) en cours et encore reçue,
--                        la même définition que le compteur « à traiter » de
--                        `lister_demandes_admission`.
--
-- Lecture seule. Rien n'est supprimé, vidé ni remplacé.

BEGIN;

CREATE FUNCTION public.comptes_admin_par_role()
RETURNS TABLE(profile_id uuid, immutable_id text, prenom text, nom text, role public.app_role,
              etat_compte public.account_status, inscrit_le timestamp with time zone,
              acces_jusqu_au timestamp with time zone, foyer_id uuid, etat_piece text,
              contrats integer, a_enseignant boolean, enfants_du_foyer integer,
              teacher_country text, tranche_age text,
              classe_id uuid, classe_libelle text, classe_numero integer,
              classes_actives integer, tuteur_id uuid, tuteur_prenom text,
              tuteur_nom text, admission_a_traiter boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  with numeros as materialized (
    select n.groupe_id, n.numero from app_private.classes_numerotees() n
  )
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role,
    p.account_status,
    p.created_at,
    p.access_until,
    p.household_id,
    case
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'pending' and k.deleted_at is null
      ) then 'a_verifier'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'approved' and k.deleted_at is null
      ) then 'validee'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'rejected' and k.deleted_at is null
      ) then 'refusee'
      else 'aucune'
    end::text,
    (select count(*)::int from public.contract_acceptances c where c.profile_id = p.id),
    exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p.id and a.ended_at is null
    ),
    (select count(*)::int from public.profiles e
      where e.household_id = p.household_id
        and e.role = 'student' and e.deleted_at is null),
    case when p.role = 'teacher' then tp.country end,
    case when p.role = 'student' then
      case sp.student_type when 'minor' then 'enfant' when 'autonomous' then 'adulte' end
    end,
    cl.groupe_id,
    cl.libelle,
    cl.numero,
    case when p.role = 'student' then
      (select count(*)::int from public.groupe_membres m
         join public.groupes g on g.id = m.groupe_id
        where m.student_id = p.id and m.left_at is null and g.ended_at is null)
    end,
    tu.id,
    case when public.agent_identite_masquee() then null else tu.first_name end,
    case when public.agent_identite_masquee() then null else tu.last_name end,
    exists (
      select 1 from public.candidatures ca
      where ca.profile_id = p.id
        and ca.type_code in ('famille', 'eleve_adulte')
        and ca.issue = 'en_cours'
        and ca.etape = 'recue'
    )
  from public.profiles p
  left join public.teacher_profiles tp on tp.profile_id = p.id and tp.deleted_at is null
  left join public.student_profiles sp on sp.profile_id = p.id and sp.deleted_at is null
  left join lateral (
    select g.id as groupe_id, g.libelle, n.numero
      from public.groupe_membres m
      join public.groupes g on g.id = m.groupe_id
      left join numeros n on n.groupe_id = g.id
     where p.role = 'student'
       and m.student_id = p.id and m.left_at is null and g.ended_at is null
     order by m.joined_at, g.id
     limit 1
  ) cl on true
  left join lateral (
    select t.id, t.first_name, t.last_name
      from public.profiles t
      left join public.households h on h.id = p.household_id
     where p.role = 'student'
       and t.household_id = p.household_id
       and t.role = 'guardian'
       and t.deleted_at is null
     order by (t.id = h.primary_guardian_id) desc, t.created_at, t.id
     limit 1
  ) tu on true
  where p.deleted_at is null
    and public.app_role() = 'admin'
    and public.app_account_valid()
    and not app_private.compte_candidat_hors_portee(p.id)
  order by
    case p.account_status
      when 'pending_kyc' then 0
      when 'provisional_active' then 1
      else 2
    end,
    p.created_at asc;
$function$;

ALTER FUNCTION public.comptes_admin_par_role() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.comptes_admin_par_role() FROM PUBLIC, anon, service_role, agent_ro;
GRANT EXECUTE ON FUNCTION public.comptes_admin_par_role() TO authenticated;
COMMENT ON FUNCTION public.comptes_admin_par_role() IS
  'F86 candidate allowlist: signature=public.comptes_admin_par_role(); guard_type=ADMIN_ONLY; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-11-01. LISTES : Comptes par role (eleves, familles, enseignants, direction), lecture seule.';

DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure := 'public.comptes_admin_par_role()'::pg_catalog.regprocedure;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p WHERE p.oid = v_oid AND p.prosecdef
                   AND p.provolatile = 's'
                   AND p.proowner = 'postgres'::pg_catalog.regrole
                   AND p.proconfig @> ARRAY['search_path=""'])
     OR NOT pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('agent_ro', v_oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'LISTES comptes par role : DEFINER ou ACL invalide pour %', v_oid;
  END IF;
END;
$postflight$;

COMMIT;
