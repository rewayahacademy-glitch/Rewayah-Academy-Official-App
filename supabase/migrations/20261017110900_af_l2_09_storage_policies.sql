-- Audit final 16/10/2026, lot L2-09 (P2-3, P3-3, avatars de classe).
-- supports : lecture directe reservee a l'administration ; eleves et enseignants
--   passent par la porte (autoriser_lecture_version, fonction Edge bibliotheque-lecture).
-- avatars : l'enseignant lit les avatars des eleves actifs de ses groupes.
-- photos_enseignants : ecriture reservee aux enseignants sur leur propre dossier.
begin;

drop policy if exists supports_lecture on storage.objects;
create policy supports_lecture_admin on storage.objects
  for select to authenticated
  using (bucket_id = 'supports' and coalesce(public.app_role() = 'admin' and public.app_account_valid(), false));

drop policy if exists avatar_lecture_classe on storage.objects;
create policy avatar_lecture_classe on storage.objects
  for select to authenticated
  using (
    bucket_id = 'avatars'
    and coalesce(
      public.app_role() = 'admin'
      or (public.app_role() = 'teacher' and exists (
        select 1 from public.groupe_membres gm
        join public.groupes g on g.id = gm.groupe_id
        where gm.student_id::text = (storage.foldername(name))[1]
          and g.teacher_id = auth.uid()
          and gm.left_at is null
      )),
      false
    )
    and public.app_account_valid()
  );

drop policy if exists photos_enseignants_ecriture on storage.objects;
create policy photos_enseignants_ecriture on storage.objects
  for all to authenticated
  using (
    bucket_id = 'photos_enseignants'
    and coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false)
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'photos_enseignants'
    and coalesce(public.app_role() = 'teacher' and public.app_account_valid(), false)
    and (storage.foldername(name))[1] = auth.uid()::text
  );

do $postflight$
begin
  if exists (select 1 from pg_policies where schemaname = 'storage' and policyname = 'supports_lecture') then
    raise exception 'L2-09 postflight: supports_lecture encore presente';
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'storage' and policyname = 'avatar_lecture_classe') then
    raise exception 'L2-09 postflight: avatar_lecture_classe absente';
  end if;
end $postflight$;

commit;
