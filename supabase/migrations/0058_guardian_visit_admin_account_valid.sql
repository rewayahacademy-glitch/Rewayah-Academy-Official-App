-- 0058 — l'acces admin a l'historique d'observation exige un compte actif.
-- Le role seul n'est pas une preuve d'acces valide: une session admin suspendue
-- ne doit pas lire les visites des familles.
begin;

drop policy if exists guardian_visit_admin on public.guardian_session_visit;
create policy guardian_visit_admin
  on public.guardian_session_visit
  for select to authenticated
  using (
    coalesce(public.app_role() = 'admin' and public.app_account_valid(), false)
  );

comment on policy guardian_visit_admin on public.guardian_session_visit is
  'Lecture admin uniquement pour un compte authentifie actif ou provisoirement actif.';

commit;
