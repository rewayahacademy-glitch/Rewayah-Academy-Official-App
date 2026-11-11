-- SEC-GARDE-4, partie a (11/11/2026, demande du pilote, acceptee par le
-- garde-cap ; plage 20261123300000-20261123399999). Regle du directeur du
-- 14/10 : une lecture SECURITY DEFINER exige un compte valide. Meme dessin que
-- GARDE-COMPTE-DESACTIVE (#365).
--
-- Le defaut : le jeton d'un compte desactive garde son role
-- (custom_access_token_hook ne lit pas account_status). Ces trois lectures
-- DEFINER ne verifiaient pas public.app_account_valid() :
--   - derniere_position_groupe(uuid) : ou la classe s'est arretee ;
--   - visites_observation(uuid) : les visites d'observation d'une seance ;
--   - peut_poser_disponibilite(uuid) : la porte des disponibilites (les
--     politiques de weekly_availability exigent deja le compte valide ; la
--     fonction est aussi appelable seule).
--
-- Ce que fait ce fichier, et rien d'autre : CREATE OR REPLACE de ces trois
-- fonctions, sur leur signature exacte (0033_tc_vues_rpc.sql et
-- 0005_dashboards_affectation_regles.sql, jamais redefinies depuis), corps
-- recopie a l'identique, plus la seule garde (exigence positive, coalesce :
-- une inconnue ferme). Langage, volatilite, SECURITY DEFINER, search_path
-- vide, proprietaire et droits (ACL) inchanges : CREATE OR REPLACE les garde.
--
-- ECARTEES, et pourquoi :
--   - public.etat_dossier() : ne lit que le dossier de l'appelant
--     (auth.uid()), et c'est ce que lit un compte en attente de verification
--     ou suspendu pour savoir ou il en est (portail d'attente). Une garde de
--     compte valide le fermerait sur lui-meme. #365 laisse de meme la lecture
--     de soi.
--   - private.candidature_geste_ouvrir(...) : lue en entier ; la branche
--     direction passe deja par private.cand_lecteur(), qui exige
--     app_role() = 'admin' AND app_account_valid() ; la branche candidat
--     agit sur sa propre candidature (compte pas encore actif) ; le systeme
--     n'a pas d'auteur. Rien a ajouter.
--
-- PREFLIGHT : md5(pg_get_functiondef) relus sur une base rejouee depuis le
-- depot (PostgreSQL 16, main 11/11) ; a recalibrer en production par le
-- pilote avant l'application (lecture seule) :
--   SELECT p.oid::regprocedure, pg_catalog.md5(pg_catalog.pg_get_functiondef(p.oid))
--     FROM pg_catalog.pg_proc p
--    WHERE p.oid IN ('public.derniere_position_groupe(uuid)'::regprocedure,
--                    'public.visites_observation(uuid)'::regprocedure,
--                    'public.peut_poser_disponibilite(uuid)'::regprocedure);
-- Une definition differente, sans le marqueur SEC-GARDE-4, arrete le fichier.
-- Rejouable : deja applique, rien n'est refait de travers.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement :
-- applicable par apply_migration.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT f.sig, f.attendu, pg_catalog.pg_get_functiondef(f.sig::regprocedure) AS def
      FROM (VALUES
        ('public.derniere_position_groupe(uuid)', '73ddd94f8f873fb5ebed000d501b8ed6'),
        ('public.visites_observation(uuid)', 'fac9c7bb4194a98c08c7455afc18cd6c'),
        ('public.peut_poser_disponibilite(uuid)', 'a561c4fcfcf640b35e9a4964a024cfae')
      ) AS f(sig, attendu)
  LOOP
    IF pg_catalog.md5(v.def) <> v.attendu AND pg_catalog.strpos(v.def, 'SEC-GARDE-4') = 0 THEN
      RAISE EXCEPTION 'SEC-GARDE-4 : % a change (md5 %), rien n''est change',
        v.sig, pg_catalog.md5(v.def);
    END IF;
  END LOOP;
  IF to_regprocedure('public.app_account_valid()') IS NULL THEN
    RAISE EXCEPTION 'SEC-GARDE-4 : public.app_account_valid() absente';
  END IF;
END
$preflight$;

-- 1. derniere_position_groupe : la garde entre dans v_autorise ; un compte
--    non valide recoit le meme refus qu'un tiers (42501).
create or replace function public.derniere_position_groupe(p_groupe_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_autorise boolean;
  v_position jsonb;
begin
  -- SEC-GARDE-4 (11/11/2026) : un compte desactive ne lit plus rien.
  select coalesce(public.app_account_valid(), false) and exists (
    select 1 from public.groupes g
    where g.id = p_groupe_id
      and (
        g.teacher_id = auth.uid()
        or public.app_role() = 'admin'
        or exists (
          select 1 from public.groupe_membres m
          where m.groupe_id = g.id and m.left_at is null
            and (m.student_id = auth.uid() or public.est_du_foyer(m.student_id))
        )
      )
  ) into v_autorise;

  if not v_autorise then
    raise exception 'groupe introuvable ou acces refuse' using errcode = 'insufficient_privilege';
  end if;

  select c.group_resume_position into v_position
    from public.session_shared_content c
    join public.sessions s on s.id = c.session_id
   where s.groupe_id = p_groupe_id
     and s.deleted_at is null
     and c.group_resume_position is not null
   order by s.started_at desc
   limit 1;

  return v_position;
end;
$$;

-- 2. visites_observation : un compte non valide recoit la liste vide, comme
--    un tiers.
create or replace function public.visites_observation(p_session_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  -- SEC-GARDE-4 (11/11/2026) : un compte desactive ne lit plus rien.
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', v.id,
    'role', v.role,
    'entered_at', v.entered_at,
    'left_at', v.left_at,
    'duration_seconds', v.duration_seconds,
    'visit_number', v.visit_number,
    'fin_de_visite', v.fin_de_visite
  ) order by v.entered_at), '[]'::jsonb)
  from public.guardian_session_visit v
  where v.session_id = p_session_id
    and coalesce(public.app_account_valid(), false)
    and (v.observateur_profile_id = auth.uid() or public.app_role() = 'admin');
$$;

-- 3. peut_poser_disponibilite : faux pour un compte non valide.
create or replace function public.peut_poser_disponibilite(p_profile_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  -- SEC-GARDE-4 (11/11/2026) : un compte desactive ne pose plus rien.
  select coalesce(public.app_account_valid(), false) and (
    (p_profile_id = auth.uid() and public.app_role() = 'teacher')
    or (
      public.app_role() = 'guardian'
      and exists (
        select 1 from public.profiles p
        where p.id = p_profile_id and p.role = 'student'
          and p.household_id is not null
          and p.household_id = public.app_household_id()
          and p.deleted_at is null
      )
    )
    or (
      p_profile_id = auth.uid()
      and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid()
          and sp.student_type = 'autonomous'
          and sp.deleted_at is null
      )
    )
  );
$$;

-- POSTFLIGHT : la garde est dans les trois corps ; DEFINER et search_path
-- vide tiennent ; aucun droit d'execution pour PUBLIC ni anon.
DO $postflight$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT p.oid::regprocedure AS sig, p.prosecdef, p.proconfig, pg_catalog.pg_get_functiondef(p.oid) AS def
      FROM pg_catalog.pg_proc p
     WHERE p.oid IN ('public.derniere_position_groupe(uuid)'::regprocedure,
                     'public.visites_observation(uuid)'::regprocedure,
                     'public.peut_poser_disponibilite(uuid)'::regprocedure)
  LOOP
    IF pg_catalog.strpos(v.def, 'public.app_account_valid()') = 0
       OR pg_catalog.strpos(v.def, 'SEC-GARDE-4') = 0 THEN
      RAISE EXCEPTION 'SEC-GARDE-4 : garde absente de %', v.sig;
    END IF;
    IF NOT v.prosecdef OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'SEC-GARDE-4 : % n''est plus DEFINER a search_path vide', v.sig;
    END IF;
    IF has_function_privilege('anon', v.sig, 'EXECUTE') THEN
      RAISE EXCEPTION 'SEC-GARDE-4 : anon peut executer %', v.sig;
    END IF;
  END LOOP;
END
$postflight$;
