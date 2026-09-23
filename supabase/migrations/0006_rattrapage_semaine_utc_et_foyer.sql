-- 0006 : rattrapage des deux objets que le lot L8 a modifies dans 0005
--
-- Pourquoi une migration plutot qu'une correction de plus dans 0005 : le
-- 7 septembre 2026, les migrations 0001 a 0005 ont ete appliquees au projet
-- reel et inscrites dans supabase_migrations. La convention « 0005 se corrige
-- sur place » n'a plus cours a partir de la : une base qui a deja joue 0005 ne
-- la rejouera jamais, donc toute correction posee dedans resterait invisible en
-- production. Voir docs/archive/2026-09-pre-remise-a-plat/MISE-EN-SERVICE.md.
--
-- Les deux objets ci-dessous sont deja corriges dans 0005 pour une base neuve.
-- Ce fichier ne sert qu'aux bases qui ont joue 0005 avant le lot L8. Les rejouer
-- est sans effet de bord : ce sont des remplacements, et `create or replace`
-- conserve les droits.

begin;

-- 1. La semaine de reference s'ancre en UTC, jamais dans le fuseau de la ligne.
-- Premiere ecriture : `date_trunc('week', now() at time zone p_tz)`. Chaque
-- fuseau datait donc sa propre semaine, et entre lundi 00h00 a Paris et lundi
-- 00h00 a Conakry les deux instants d'un meme rendez-vous differaient
-- d'exactement sept jours. Deux heures par semaine, le feed de ENS-06 se vidait
-- de toute famille d'un autre fuseau, sans erreur et sans trace.
create or replace function public.instant_creneau(
  p_weekday int,
  p_hour int,
  p_tz text,
  p_semaine_offset int default 0
) returns timestamptz
language sql stable set search_path = ''
as $$
  select ((date_trunc('week', (now() at time zone 'UTC'))::date
           + (p_weekday - 1) + (p_semaine_offset * 7))::timestamp
          + make_interval(hours => p_hour)) at time zone p_tz;
$$;

-- 2. profils_du_foyer_v porte la date de fin d'acces, que TUT-01 affiche. Sans
-- elle, l'ecran lisait une seconde source pour une colonne de la meme ligne, et
-- les deux auraient fini par diverger.
create or replace view public.profils_du_foyer_v
with (security_barrier = true)
as
select
  p.id,
  p.first_name,
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
  and sp.deleted_at is null;

commit;
