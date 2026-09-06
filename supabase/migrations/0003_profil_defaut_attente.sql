-- 0003 : une nouvelle inscription part en portail d'attente
--
-- Suite de 0002. Conformement a l'ADR-014 :
--
--   | Statut               | Qui l'obtient                          | Acces  |
--   | pending_kyc          | toute nouvelle inscription             | aucun  |
--   | provisional_active   | uniquement un import declenche par un admin | complet |
--   | active               | un profil valide                       | complet |
--   | disabled             | decision d'administration              | aucun  |
--
-- Deux garanties tenues par ce qui existe deja, et qu'il ne faut pas defaire :
--
-- 1. `public.app_account_valid()` n'accepte que `active` et
--    `provisional_active`. Un compte `pending_kyc` ne lit donc RIEN, dans
--    aucune table, quel que soit son role. La redirection du routeur Flutter
--    n'est qu'une commodite d'experience par-dessus cette regle.
-- 2. `provisional_active` reste inatteignable par le parcours d'inscription
--    publique : le declencheur `guard_profile_privileged_columns` reserve
--    l'ecriture de `account_status` a l'administration.

begin;

alter table public.profiles
  alter column account_status set default 'pending_kyc';

comment on column public.profiles.account_status is
  'ADR-014. pending_kyc a l''inscription, aucun acces. provisional_active '
  'uniquement par import admin. active apres validation. disabled sur '
  'decision d''administration.';

commit;
