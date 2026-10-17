-- Population de test du STAGING (xldmmlrnxyabdtvxqbyy), enseignants (provisoirement actifs) et administration.
-- Ne jamais appliquer en production. Généré par tool/simulation/generer_population_staging.mjs.

insert into public.profiles (id, role, household_id, first_name, last_name, account_status, gender)
select (p.prefixe || '00000-0000-4000-8000-' || lpad(p.n::text, 12, '0'))::uuid, p.role::public.app_role, null, p.prenom, p.nom,
  (case when p.role = 'teacher' then 'provisional_active' else 'active' end)::public.account_status,
  (case p.sexe when 'F' then 'female' else 'male' end)::public.gender
from (values
  ('e52', 1, 'teacher', 'F', 'Aïcha', 'Keïta'),
  ('e52', 2, 'teacher', 'F', 'Safiya', 'Barry'),
  ('e52', 3, 'teacher', 'F', 'Hawa', 'Yilmaz'),
  ('e52', 4, 'teacher', 'M', 'Zakaria', 'Camara'),
  ('e52', 5, 'teacher', 'M', 'Ousmane', 'Hassan'),
  ('e52', 6, 'teacher', 'F', 'Ramatoulaye', 'Siddiqui'),
  ('e52', 7, 'teacher', 'F', 'Sarah', 'Diallo'),
  ('e52', 8, 'teacher', 'F', 'Imane', 'Siddiqui'),
  ('e52', 9, 'teacher', 'F', 'Ramatoulaye', 'Fofana'),
  ('e52', 10, 'teacher', 'F', 'Hanane', 'Kaba'),
  ('e53', 1, 'admin', 'M', 'Yacine', 'Chraïbi'),
  ('e53', 2, 'admin', 'F', 'Aminata', 'Hassan'),
  ('e53', 3, 'accountant', 'F', 'Yasmine', 'Mahmoud'),
  ('e53', 4, 'controller', 'M', 'Ilyes', 'El Amrani')
) p(prefixe, n, role, sexe, prenom, nom);

insert into public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana, titre)
select ('e5200000-0000-4000-8000-' || lpad((t.n)::text, 12, '0'))::uuid, t.pays, array['fr', 'ar'], 12, 'approved', 'Africa/Conakry', t.titre from (values
  (1, 'GN', 'sayyida'),
  (2, 'GN', 'sayyida'),
  (3, 'ML', 'sayyida'),
  (4, 'ML', 'sayyid'),
  (5, 'SN', 'sayyid'),
  (6, 'ML', 'sayyida'),
  (7, 'ML', 'sayyida'),
  (8, 'GN', 'sayyida'),
  (9, 'MA', 'sayyida'),
  (10, 'ML', 'sayyida')
) t(n, pays, titre);
