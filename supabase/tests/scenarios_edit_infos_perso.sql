-- EDIT-INFOS-PERSO (garde-cap, 12/11/2026) : la personne change son prenom
-- et son nom elle-meme, depuis la page Informations du Compte, SANS RPC ni
-- migration : par la politique `profiles_self_update` et la garde
-- `guard_profile_privileged_columns` (20261110000000_garde_profil). L'ecriture
-- jouee ici est exactement celle de l'application
-- (`IdentiteTitulaireSupabase.modifier`) : UPDATE de first_name et last_name
-- seuls, sur id = auth.uid(), avec RETURNING id (une ligne rendue = ecrite).
--
--   1. l'enseignant, le tuteur et l'eleve autonome : acceptes sur leur ligne ;
--   2. l'eleve mineur : refuse (42501) ;
--   3. la ligne d'autrui : aucune ligne ecrite, la ligne reste intacte ;
--   4. genre, role, foyer, statut et acces : refuses (42501), meme a un
--      adulte sur sa propre ligne ; created_at, deleted_at et le matricule
--      aussi.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_message text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'ROUGE : % (aucun refus)', p_label USING ERRCODE = 'XX999';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE = 'XX999' THEN RAISE; END IF;
    IF SQLSTATE <> p_code OR (p_message IS NOT NULL AND SQLERRM <> p_message) THEN
      RAISE EXCEPTION 'ROUGE : % (% « % » au lieu de % « % »)', p_label, SQLSTATE, SQLERRM, p_code, p_message;
    END IF;
  END;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('9e1f0000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', p_aal,
  'app_metadata', pg_catalog.json_build_object('role', p_role))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

-- Lecture sans RLS (fonction des tests, executee en postgres).
CREATE FUNCTION pg_temp.champ(p_id uuid, p_col text) RETURNS text
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v text;
BEGIN
  EXECUTE pg_catalog.format('SELECT %I::text FROM public.profiles WHERE id = $1', p_col) INTO v USING p_id;
  RETURN coalesce(v, '∅');
END $$;

GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text),
  pg_temp.qui(uuid, text, text), pg_temp.u(text), pg_temp.champ(uuid, text) TO authenticated, anon, service_role;

-- Ecriture de l'application, sous l'identite courante : le nombre de
-- lignes rendues par RETURNING (0 : rien n'est ecrit).
CREATE FUNCTION pg_temp.ecrire(p_cible uuid, p_prenom text, p_nom text) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  WITH ecrites AS (
    UPDATE public.profiles SET first_name = p_prenom, last_name = p_nom
     WHERE id = p_cible RETURNING id
  ) SELECT count(*) INTO v FROM ecrites;
  RETURN v;
END $$;
GRANT EXECUTE ON FUNCTION pg_temp.ecrire(uuid, text, text) TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures : un foyer H (tuteur P, enfant mineur E) ; un eleve autonome A
-- dans son foyer H2 ; un enseignant T (actif provisoire : sans contrat
-- signe, un enseignant ne passe pas en « actif »).
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  (pg_temp.u('1'), 'eip-tuteur@example.test'), (pg_temp.u('2'), 'eip-enfant@example.test'),
  (pg_temp.u('4'), 'eip-adulte@example.test'), (pg_temp.u('5'), 'eip-enseignant@example.test');
INSERT INTO public.households (id, timezone) VALUES
  (pg_temp.u('101'), 'Europe/Paris'), (pg_temp.u('102'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  (pg_temp.u('1'), 'EIP-P', 'guardian', pg_temp.u('101'), 'Samira', 'Essai', 'female', 'active'),
  (pg_temp.u('2'), 'EIP-E', 'student', pg_temp.u('101'), 'Hakim', 'Essai', 'male', 'active'),
  (pg_temp.u('4'), 'EIP-A', 'student', pg_temp.u('102'), 'Nadia', 'Adulte', 'female', 'active'),
  (pg_temp.u('5'), 'EIP-T', 'teacher', pg_temp.u('102'), 'Karim', 'Enseignant', 'male', 'provisional_active');
UPDATE public.households SET primary_guardian_id = pg_temp.u('1') WHERE id = pg_temp.u('101');
UPDATE public.households SET primary_guardian_id = pg_temp.u('4') WHERE id = pg_temp.u('102');
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode) VALUES
  (pg_temp.u('2'), 'minor', 'standard'),
  (pg_temp.u('4'), 'autonomous', 'standard');

SET LOCAL ROLE authenticated;

-- ------------------------------------------------------------------
-- 1. Acceptes sur leur propre ligne
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('5'), 'teacher');
SELECT pg_temp.vrai(public.photo_adulte_moi() IS TRUE, '1.0 : le serveur dit que l''enseignant peut changer ses noms');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('5'), 'Karima', 'Enseignante') = 1, '1.1 : l''enseignant ecrit sa ligne (une ligne rendue)');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('5'), 'first_name') = 'Karima'
  AND pg_temp.champ(pg_temp.u('5'), 'last_name') = 'Enseignante', '1.2 : prenom et nom de l''enseignant changes');

SELECT pg_temp.qui(pg_temp.u('1'), 'guardian');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('1'), 'Samia', 'Essaie') = 1, '1.3 : le tuteur ecrit sa ligne');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('1'), 'first_name') = 'Samia'
  AND pg_temp.champ(pg_temp.u('1'), 'last_name') = 'Essaie', '1.4 : prenom et nom du tuteur changes');

SELECT pg_temp.qui(pg_temp.u('4'), 'student');
SELECT pg_temp.vrai(public.photo_adulte_moi() IS TRUE, '1.5 : le serveur dit que l''eleve autonome peut changer ses noms');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('4'), 'Nadira', 'Adultee') = 1, '1.6 : l''eleve autonome ecrit sa ligne');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('4'), 'first_name') = 'Nadira'
  AND pg_temp.champ(pg_temp.u('4'), 'last_name') = 'Adultee', '1.7 : prenom et nom de l''eleve autonome changes');

-- ------------------------------------------------------------------
-- 2. L'eleve mineur est refuse
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('2'), 'student');
SELECT pg_temp.vrai(public.photo_adulte_moi() IS FALSE, '2.0 : le serveur dit que l''enfant ne change pas ses noms');
SELECT pg_temp.refus($q$SELECT pg_temp.ecrire(pg_temp.u('2'), 'Pirate', 'Pirate')$q$,
  '42501', 'le nom d''un eleve mineur se change par l''academie', '2.1 : l''enfant ne change ni son prenom ni son nom');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Hakim'
  AND pg_temp.champ(pg_temp.u('2'), 'last_name') = 'Essai', '2.2 : la ligne de l''enfant est intacte');

-- ------------------------------------------------------------------
-- 3. La ligne d'autrui : rien n'est ecrit
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('5'), 'teacher');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('1'), 'Pirate', 'Pirate') = 0, '3.1 : l''enseignant n''ecrit pas la ligne du tuteur');
SELECT pg_temp.qui(pg_temp.u('1'), 'guardian');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('2'), 'Pirate', 'Pirate') = 0, '3.2 : le tuteur ne renomme pas son enfant par cette porte');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('4'), 'Pirate', 'Pirate') = 0, '3.3 : le tuteur n''ecrit pas la ligne d''un autre foyer');
SELECT pg_temp.qui(pg_temp.u('4'), 'student');
SELECT pg_temp.vrai(pg_temp.ecrire(pg_temp.u('5'), 'Pirate', 'Pirate') = 0, '3.4 : l''eleve autonome n''ecrit pas la ligne de l''enseignant');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('1'), 'first_name') = 'Samia'
  AND pg_temp.champ(pg_temp.u('2'), 'first_name') = 'Hakim'
  AND pg_temp.champ(pg_temp.u('4'), 'first_name') = 'Nadira'
  AND pg_temp.champ(pg_temp.u('5'), 'first_name') = 'Karima', '3.5 : aucune ligne d''autrui n''a change');

-- ------------------------------------------------------------------
-- 4. Les colonnes protegees restent refusees, meme a un adulte
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('5'), 'teacher');
SELECT pg_temp.refus($q$UPDATE public.profiles SET gender = 'female' WHERE id = pg_temp.u('5')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.1 : l''enseignant ne change pas son genre');
SELECT pg_temp.refus($q$UPDATE public.profiles SET role = 'admin' WHERE id = pg_temp.u('5')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.2 : l''enseignant ne change pas son role');
SELECT pg_temp.refus($q$UPDATE public.profiles SET access_until = now() WHERE id = pg_temp.u('5')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.3 : l''enseignant ne change pas son acces');
SELECT pg_temp.qui(pg_temp.u('1'), 'guardian');
SELECT pg_temp.refus($q$UPDATE public.profiles SET household_id = pg_temp.u('102') WHERE id = pg_temp.u('1')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.4 : le tuteur ne change pas de foyer');
SELECT pg_temp.refus($q$UPDATE public.profiles SET account_status = 'disabled' WHERE id = pg_temp.u('1')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.5 : le tuteur ne change pas son statut');
SELECT pg_temp.qui(pg_temp.u('4'), 'student');
SELECT pg_temp.refus($q$UPDATE public.profiles SET first_name = 'Nadia', gender = 'male' WHERE id = pg_temp.u('4')$q$,
  '42501', 'seul un admin modifie rôle, foyer, statut, accès ou genre', '4.6 : le genre glisse avec le prenom est refuse en entier');
SELECT pg_temp.refus($q$UPDATE public.profiles SET created_at = '2020-01-01' WHERE id = pg_temp.u('4')$q$,
  '42501', 'seule la direction retire un compte, ou change sa date de creation ou son matricule',
  '4.7 : l''eleve autonome ne change pas sa date de creation');
SELECT pg_temp.refus($q$UPDATE public.profiles SET deleted_at = now() WHERE id = pg_temp.u('4')$q$,
  '42501', NULL, '4.8 : l''eleve autonome ne se retire pas lui-meme');
SELECT pg_temp.refus($q$UPDATE public.profiles SET immutable_id = 'EIP-X' WHERE id = pg_temp.u('4')$q$,
  'P0001', 'immutable_id ne peut pas être modifié', '4.9 : l''eleve autonome ne change pas son matricule');
SELECT pg_temp.vrai(pg_temp.champ(pg_temp.u('4'), 'first_name') = 'Nadira'
  AND pg_temp.champ(pg_temp.u('4'), 'gender') = 'female'
  AND pg_temp.champ(pg_temp.u('5'), 'role') = 'teacher'
  AND pg_temp.champ(pg_temp.u('1'), 'household_id') = pg_temp.u('101')::text, '4.10 : rien de protege n''a change');

RESET ROLE;
ROLLBACK;
