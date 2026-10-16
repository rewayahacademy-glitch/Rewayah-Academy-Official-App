-- L1-02-reprise (P0-2, fratrie) : profils_du_foyer_v reservee au tuteur et a l'eleve lui-meme.
--
-- La vue appartient a postgres : la RLS de profiles et de student_profiles ne
-- s'y applique pas. Elle ne filtrait que par foyer et par role 'student' de la
-- ligne, sans role ni compte valide de l'appelant. Un enfant y lisait prenom,
-- matricule, interface, camera, avatar et fin d'acces de ses freres et soeurs
-- (verification croisee L1-V, defaut D-2, bloc C9). Un compte suspendu la lisait aussi.
--
-- Lecteurs cote Flutter (grep) : un seul appel, ServiceAppairageSupabase.eleves()
-- (lib/core/appairage/service_appairage.dart), derriere elevesDuFoyerProvider ;
-- ses ecrans sont ceux du tuteur ou de l'adulte autonome (Foyer, Fiche eleve,
-- Appareils, Disponibilites, Reglages enfant, Compte). L'adulte autonome, de role
-- 'student', garde sa propre ligne (p.id = auth.uid()). Aucun ecran d'enfant n'y lit
-- la ligne d'un autre.
--
-- Memes colonnes, meme ordre, security_barrier conserve, masquage d'agent de 0014
-- conserve. Seule la clause d'acces est ajoutee.

begin;

create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  case when public.agent_identite_masquee()
       then p.immutable_id else p.first_name end as first_name,
  p.immutable_id,
  sp.interface_mode,
  sp.camera_policy,
  sp.avatar_storage_key,
  p.access_until
from public.profiles p
join public.student_profiles sp on sp.profile_id = p.id
where p.household_id is not null
  and p.household_id = public.app_household_id()
  and p.role = 'student'
  and p.deleted_at is null
  and sp.deleted_at is null
  and public.app_account_valid()
  and (public.app_role() = 'guardian'
       or (public.app_role() = 'student' and p.id = auth.uid()));

do $$
declare
  def text := pg_get_viewdef('public.profils_du_foyer_v'::regclass, true);
begin
  if def not like '%guardian%' or def not like '%app_account_valid%' then
    raise exception 'L1-02-reprise : la clause d''acces manque dans profils_du_foyer_v';
  end if;
  if def not like '%agent_identite_masquee%' then
    raise exception 'L1-02-reprise : le masquage d''agent a ete perdu';
  end if;
  if not exists (
    select 1 from pg_class
     where oid = 'public.profils_du_foyer_v'::regclass
       and 'security_barrier=true' = any (reloptions)
  ) then
    raise exception 'L1-02-reprise : security_barrier perdu';
  end if;
end $$;

commit;
