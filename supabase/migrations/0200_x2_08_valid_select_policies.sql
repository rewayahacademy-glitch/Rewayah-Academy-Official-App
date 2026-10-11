-- X2-08: every catalog and published-offer SELECT requires a valid account.
begin;

drop policy if exists langues_cours_lecture on public.langues_cours;
create policy langues_cours_lecture on public.langues_cours
  for select to authenticated
  using (coalesce(public.app_account_valid(), false));

drop policy if exists cohortes_age_lecture on public.cohortes_age;
create policy cohortes_age_lecture on public.cohortes_age
  for select to authenticated
  using (coalesce(public.app_account_valid(), false));

drop policy if exists offres_horaires_vitrine on public.offres_horaires;
create policy offres_horaires_vitrine on public.offres_horaires
  for select to authenticated
  using (
    coalesce(
      public.app_account_valid()
      and (
        etat = 'publiee'
        or public.app_role() in ('admin', 'controller')
      ),
      false
    )
  );

commit;
