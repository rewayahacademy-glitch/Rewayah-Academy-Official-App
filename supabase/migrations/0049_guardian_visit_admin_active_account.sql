-- B-13 — une visite d'observation n'est lisible par l'administration
-- que si le compte connecté est actif. La policy 0032 vérifiait le rôle seul,
-- ce qui autorisait encore un profil admin suspendu.
begin;

drop policy if exists guardian_visit_admin
  on public.guardian_session_visit;

create policy guardian_visit_admin
  on public.guardian_session_visit
  for select
  to authenticated
  using (
    coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  );

comment on policy guardian_visit_admin on public.guardian_session_visit is
  'B-13: lecture admin reservee a un compte authentifie actif; un compte suspendu ne lit aucun historique.';

commit;
