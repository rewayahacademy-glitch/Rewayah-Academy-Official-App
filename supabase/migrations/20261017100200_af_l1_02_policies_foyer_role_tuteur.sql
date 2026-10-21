-- Audit final 16/10/2026, lot L1-02 (P0-2). Le foyer n'est pas un role : seul le
-- tuteur (guardian) lit les finances et regle le profil d'un eleve. L'eleve
-- adulte autonome (student_profiles.student_type = 'autonomous', foyer d'une
-- personne, ADR-009) garde la main sur lui-meme. Un enfant porte pourtant
-- household_id dans son jeton : sans ce role dans la policy, il lisait les
-- finances de son foyer et s'accordait la camera.
--
-- Lecture a l'echelle : au plus une sous-requete indexee par ligne de plus
-- qu'avant (student_profiles par sa cle primaire, evaluee une fois par requete
-- car elle ne depend pas de la ligne lue).
begin;

alter policy wallets_family_read on public.wallets
  using (
    public.app_account_valid()
    and household_id = public.app_household_id()
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student' and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid() and sp.student_type = 'autonomous'
          and sp.deleted_at is null))
    )
  );

alter policy wallet_entries_family_read on public.wallet_entries
  using (
    public.app_account_valid()
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student' and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid() and sp.student_type = 'autonomous'
          and sp.deleted_at is null))
    )
    and exists (
      select 1 from public.wallets w
      where w.id = wallet_entries.wallet_id
        and w.household_id = public.app_household_id()
    )
  );

alter policy payout_methods_family_read on public.payout_methods
  using (
    public.app_account_valid()
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student' and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid() and sp.student_type = 'autonomous'
          and sp.deleted_at is null))
    )
    and exists (
      select 1 from public.profiles p
      where p.id = payout_methods.profile_id
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
  );

alter policy payouts_family_read on public.payouts
  using (
    public.app_account_valid()
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student' and exists (
        select 1 from public.student_profiles sp
        where sp.profile_id = auth.uid() and sp.student_type = 'autonomous'
          and sp.deleted_at is null))
    )
    and exists (
      select 1 from public.wallets w
      where w.id = payouts.wallet_id
        and w.household_id = public.app_household_id()
    )
  );

-- Ici la ligne porte deja student_type : pas de sous-requete sur la table de la
-- policy (qui bouclerait sur elle-meme).
alter policy student_profiles_family_update on public.student_profiles
  using (
    public.app_account_valid()
    and deleted_at is null
    and exists (
      select 1 from public.profiles p
      where p.id = student_profiles.profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student'
          and student_profiles.profile_id = auth.uid()
          and student_profiles.student_type = 'autonomous')
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = student_profiles.profile_id
        and p.household_id is not null
        and p.household_id = public.app_household_id()
        and p.deleted_at is null
    )
    and (
      public.app_role() = 'guardian'
      or (public.app_role() = 'student'
          and student_profiles.profile_id = auth.uid()
          and student_profiles.student_type = 'autonomous')
    )
  );

do $postflight$
declare v_n int;
begin
  select count(*) into v_n from pg_policies
   where schemaname = 'public'
     and policyname in ('wallets_family_read','wallet_entries_family_read',
                        'payout_methods_family_read','payouts_family_read',
                        'student_profiles_family_update')
     and coalesce(qual, '') || coalesce(with_check, '') like '%guardian%';
  if v_n <> 5 then
    raise exception 'L1-02 postflight: % policies sur 5 portent le role', v_n;
  end if;
end $postflight$;

commit;
