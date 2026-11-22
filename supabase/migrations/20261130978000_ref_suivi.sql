-- REF-SUIVI (directeur, 22/11/2026) : savoir quelle organisation a envoye chaque famille (lien d'un courriel de
-- mosquee : https://rewayahacademy.com/en/familles?ref=chingford-londres).
--
-- LIVRE ICI : `private.sources_inscription` (une ligne par compte : `source_ref`, `source_ref_le`) et la porte
-- `public.noter_source_inscription(p_ref)`, qui pose la source du compte connecte UNE SEULE FOIS (la premiere gagne).
--
-- POURQUOI UNE TABLE A PART et non deux colonnes de `public.profiles` : la RLS borne les lignes, pas les colonnes ;
-- `profiles` est lue par la famille et par l'agent, et la politique `profiles_self_update` laisserait chacun
-- reecrire sa propre source. Dans `private`, sans aucun droit aux roles de l'API, seule la porte ecrit, et elle
-- ne retouche jamais une source deja posee. Le compte peut etre un candidat, une famille ou un eleve adulte : pas
-- de cle etrangere (comme `private.person_registrations`), la porte n'exige pas que le profil existe deja.
-- La lecture par la direction n'est pas livree ici (aucun ecran demande) : a ajouter quand l'ecran le demande.
--
-- MOTS D'EFFACEMENT : ZERO. Sans BEGIN ni COMMIT de premier niveau. Aucune donnee de personne existante touchee.

create schema if not exists private;

create table if not exists private.sources_inscription (
  profile_id uuid primary key,
  source_ref text not null
    constraint sources_inscription_source_ref_format check (source_ref ~ '^[a-z0-9-]{1,48}$'),
  source_ref_le timestamptz not null default pg_catalog.now()
);
alter table private.sources_inscription enable row level security;
revoke all on private.sources_inscription from public, anon, authenticated, service_role;

comment on table private.sources_inscription is
  'REF-SUIVI : l''organisation (ref du lien) qui a envoye le compte, posee une fois par noter_source_inscription.';

create or replace function public.noter_source_inscription(p_ref text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_moi uuid := auth.uid();
  v_posee integer;
begin
  if not (v_moi is not null) then
    raise exception 'SessionRequise' using errcode = '28000';
  end if;
  if not (p_ref is not null and p_ref ~ '^[a-z0-9-]{1,48}$') then
    raise exception 'RefInvalide' using errcode = '22023';
  end if;
  insert into private.sources_inscription (profile_id, source_ref)
  values (v_moi, p_ref)
  on conflict (profile_id) do nothing;
  get diagnostics v_posee = row_count;
  return v_posee = 1;
end;
$function$;

revoke all on function public.noter_source_inscription(text) from public;
revoke all on function public.noter_source_inscription(text) from anon;
grant execute on function public.noter_source_inscription(text) to authenticated;

comment on function public.noter_source_inscription(text) is
  'REF-SUIVI : note la source (ref) du compte connecte, une seule fois ; vrai si posee, faux si une source existait deja.';
