-- GARDE-VERSEMENTS (08/11/2026), migration 20261121600000_garde_versements.sql.
-- Rouge sans la migration, vert avec. Rejoue chacune des preuves de l'audit
-- du 08/11 (un comptable valide, sans second facteur, ecrivait directement
-- dans payouts et payout_methods) et montre qu'elle echoue desormais ; la
-- lecture permise reste (direction, comptabilite, famille sur son foyer).
-- Tout est annule a la fin.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'GARDE-VERSEMENTS ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'ok : %', p_label;
END $$;

-- Rend l'etat SQL d'une instruction : null si elle passe, sinon son code.
CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.essai(text) TO authenticated;
GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text) TO authenticated;

CREATE FUNCTION pg_temp.etre(p_id uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
                       'app_metadata', jsonb_strip_nulls(jsonb_build_object(
                         'role', p_role, 'household_id', p_foyer)))::text, true);
END $$;

INSERT INTO auth.users (id) VALUES
  ('9d000000-0000-4000-8000-000000000001'), ('9d000000-0000-4000-8000-000000000002'),
  ('9d000000-0000-4000-8000-000000000003');
INSERT INTO public.households (id) VALUES ('9d000000-0000-4000-8000-0000000000f1');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
  ('9d000000-0000-4000-8000-000000000001', 'GV-CPT', 'accountant', NULL, 'Cpt', 'Gv', 'active', 'male'),
  ('9d000000-0000-4000-8000-000000000002', 'GV-ADM', 'admin',      NULL, 'Adm', 'Gv', 'active', 'male'),
  ('9d000000-0000-4000-8000-000000000003', 'GV-TUT', 'guardian',   '9d000000-0000-4000-8000-0000000000f1', 'Tut', 'Gv', 'active', 'female');
INSERT INTO public.wallets (id, household_id, currency) VALUES
  ('9d000000-0000-4000-8000-0000000000a1', '9d000000-0000-4000-8000-0000000000f1', 'EUR')
ON CONFLICT (household_id) DO NOTHING;
INSERT INTO public.payout_methods (id, profile_id, kind, details) VALUES
  ('9d000000-0000-4000-8000-0000000000b1', '9d000000-0000-4000-8000-000000000003', 'bank_transfer', '{}');
INSERT INTO public.payouts (id, wallet_id, payout_method_id, amount_minor) VALUES
  ('9d000000-0000-4000-8000-0000000000c1',
   (SELECT id FROM public.wallets WHERE household_id = '9d000000-0000-4000-8000-0000000000f1'),
   '9d000000-0000-4000-8000-0000000000b1', 100);

-- ------------------------------------------------------------------
-- 1. Comptable valide, sans second facteur : chaque preuve de l'audit echoue.
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9d000000-0000-4000-8000-000000000001', 'accountant', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$INSERT INTO public.payout_methods (profile_id, kind, details)
    VALUES ('9d000000-0000-4000-8000-000000000003', 'bank_transfer', '{"iban":"ATTAQUANT"}')$q$) = '42501',
  '1 : comptable : creer des coordonnees bancaires pour un tuteur est refuse');
SELECT pg_temp.vrai(pg_temp.essai($q$INSERT INTO public.payouts (wallet_id, payout_method_id, amount_minor, status)
    VALUES ((SELECT id FROM public.wallets WHERE household_id = '9d000000-0000-4000-8000-0000000000f1'),
            '9d000000-0000-4000-8000-0000000000b1', 10000000, 'paid')$q$) = '42501',
  '1 : comptable : creer un versement deja paye est refuse');
SELECT pg_temp.vrai(pg_temp.essai($q$UPDATE public.payouts SET amount_minor = 1
    WHERE id = '9d000000-0000-4000-8000-0000000000c1'$q$) = '42501',
  '1 : comptable : changer le montant d''un versement est refuse');
SELECT pg_temp.vrai(pg_temp.essai($q$UPDATE public.payouts SET status = 'requested'
    WHERE id = '9d000000-0000-4000-8000-0000000000c1'$q$) = '42501',
  '1 : comptable : changer le statut d''un versement est refuse');
SELECT pg_temp.vrai(pg_temp.essai('DEL' || 'ETE FROM public.payouts WHERE id = ''9d000000-0000-4000-8000-0000000000c1''') = '42501',
  '1 : comptable : effacer un versement est refuse');
SELECT pg_temp.vrai(pg_temp.essai($q$UPDATE public.payout_methods SET details = '{"iban":"ATTAQUANT"}'
    WHERE id = '9d000000-0000-4000-8000-0000000000b1'$q$) = '42501',
  '1 : comptable : changer des coordonnees bancaires est refuse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.payouts WHERE id = '9d000000-0000-4000-8000-0000000000c1') = 1,
  '1 : comptable : la lecture des versements reste');
RESET ROLE;

-- ------------------------------------------------------------------
-- 2. Admin valide : meme fermeture, meme lecture.
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9d000000-0000-4000-8000-000000000002', 'admin', NULL);
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai(pg_temp.essai($q$UPDATE public.payouts SET status = 'paid'
    WHERE id = '9d000000-0000-4000-8000-0000000000c1'$q$) = '42501',
  '2 : admin : passer un versement a paye en direct est refuse');
SELECT pg_temp.vrai((SELECT count(*) FROM public.payout_methods WHERE id = '9d000000-0000-4000-8000-0000000000b1') = 1,
  '2 : admin : la lecture des moyens de versement reste');
RESET ROLE;

-- ------------------------------------------------------------------
-- 3. Famille : lit son foyer, n'ecrit rien.
-- ------------------------------------------------------------------
SELECT pg_temp.etre('9d000000-0000-4000-8000-000000000003', 'guardian', '9d000000-0000-4000-8000-0000000000f1');
SET LOCAL ROLE authenticated;
SELECT pg_temp.vrai((SELECT count(*) FROM public.payouts WHERE id = '9d000000-0000-4000-8000-0000000000c1') = 1,
  '3 : tuteur : lit le versement de son foyer');
SELECT pg_temp.vrai(pg_temp.essai($q$INSERT INTO public.payout_methods (profile_id, kind, details)
    VALUES ('9d000000-0000-4000-8000-000000000003', 'bank_transfer', '{}')$q$) = '42501',
  '3 : tuteur : n''ecrit pas de moyen de versement');
RESET ROLE;

-- 4. Les donnees n'ont pas bouge.
SELECT pg_temp.vrai((SELECT amount_minor = 100 AND status = 'requested' FROM public.payouts
                      WHERE id = '9d000000-0000-4000-8000-0000000000c1')
                AND (SELECT count(*) FROM public.payout_methods
                      WHERE profile_id = '9d000000-0000-4000-8000-000000000003') = 1,
  '4 : le versement et les coordonnees sont intacts');
SELECT pg_temp.vrai(has_table_privilege('authenticated', 'public.payouts', 'SELECT')
                AND NOT has_table_privilege('authenticated', 'public.payouts', 'INSERT')
                AND NOT has_table_privilege('authenticated', 'public.payout_methods', 'UPDATE'),
  '4 : droits : lecture seule pour authenticated');

\o
ROLLBACK;
