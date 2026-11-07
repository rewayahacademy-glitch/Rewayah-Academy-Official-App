-- SUPPRIMER, partie serveur (03/11/2026 ; migration 20261108600000).
--
--   A. anon n'execute rien et ne lit pas le journal des retraits ;
--   B. un tuteur ne retire pas l'enfant d'un autre foyer, ni un eleve adulte,
--      ni lui-meme ; un enseignant n'appelle pas la porte du tuteur ;
--   C. le tuteur retire le profil de son enfant : l'eleve quitte la classe,
--      la classe reste intacte pour les autres ; l'anonymisation attend
--      l'echeance ;
--   D. la direction sans double verification est refusee ; en aal2, une
--      selection melangee rend un resultat par identifiant (seances a venir
--      nommees, soi-meme, compte de la direction, deja retire, introuvable) ;
--   E. l'anonymisation part a l'echeance, pas avant ;
--   F. aucune ecriture comptable ne disparait.
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
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5e9a0000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

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

-- Les ecritures comptables, table par table, avant le scenario.
CREATE TEMP TABLE compta_avant AS
SELECT t.table_name::text AS nom,
       (xpath('/row/c/text()', query_to_xml(pg_catalog.format('SELECT count(*) AS c FROM public.%I', t.table_name), false, true, '')))[1]::text::bigint AS n
  FROM information_schema.tables t
 WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
   AND (t.table_name ~ 'facture|paiement|tresorerie|remboursement|litige|recharge|commande|engagement'
        OR t.table_name IN ('contract_acceptances', 'audit_logs'));

GRANT EXECUTE ON FUNCTION pg_temp.vrai(boolean, text), pg_temp.refus(text, text, text, text),
  pg_temp.qui(uuid, text, text), pg_temp.u(text) TO authenticated, anon;

-- ------------------------------------------------------------------
-- Fixtures
--   H1 : tuteur P1, enfant E1 (mineur, dans la classe G), eleve adulte A1 ;
--   H2 : tuteur P2, enfant E2 (mineur, dans la classe G) ;
--   T enseignant de G, une seance a venir ; T2 enseignant sans seance, contrat signe ;
--   D direction, D2 autre compte de la direction.
-- ------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  (pg_temp.u('1'), 'sup-t@example.test'), (pg_temp.u('2'), 'sup-t2@example.test'),
  (pg_temp.u('11'), 'sup-p1@example.test'), (pg_temp.u('12'), 'sup-e1@example.test'),
  (pg_temp.u('13'), 'sup-a1@example.test'), (pg_temp.u('21'), 'sup-p2@example.test'),
  (pg_temp.u('22'), 'sup-e2@example.test'), (pg_temp.u('31'), 'sup-d@example.test'),
  (pg_temp.u('32'), 'sup-d2@example.test');
INSERT INTO public.households (id, timezone) VALUES (pg_temp.u('101'), 'Europe/Paris'), (pg_temp.u('102'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  (pg_temp.u('1'), 'SUP-T', 'teacher', NULL, 'Omar', 'Enseignant', 'male', 'provisional_active'),
  (pg_temp.u('2'), 'SUP-T2', 'teacher', NULL, 'Ali', 'Second', 'male', 'pending_kyc'),
  (pg_temp.u('11'), 'SUP-P1', 'guardian', pg_temp.u('101'), 'Samira', 'Un', 'female', 'active'),
  (pg_temp.u('12'), 'SUP-E1', 'student', pg_temp.u('101'), 'Lina', 'Un', 'male', 'active'),
  (pg_temp.u('13'), 'SUP-A1', 'student', pg_temp.u('101'), 'Karim', 'Un', 'male', 'active'),
  (pg_temp.u('21'), 'SUP-P2', 'guardian', pg_temp.u('102'), 'Nadia', 'Deux', 'female', 'active'),
  (pg_temp.u('22'), 'SUP-E2', 'student', pg_temp.u('102'), 'Sami', 'Deux', 'male', 'active'),
  (pg_temp.u('31'), 'SUP-D', 'admin', NULL, 'Direction', 'Une', 'female', 'active'),
  (pg_temp.u('32'), 'SUP-D2', 'admin', NULL, 'Direction', 'Deux', 'female', 'active');
UPDATE public.households SET primary_guardian_id = pg_temp.u('11') WHERE id = pg_temp.u('101');
UPDATE public.households SET primary_guardian_id = pg_temp.u('21') WHERE id = pg_temp.u('102');
INSERT INTO public.teacher_profiles (profile_id, languages, weekly_hours_cap, kyc_status, timezone_iana)
VALUES (pg_temp.u('1'), ARRAY['francais'], 20, 'approved', 'Europe/Paris'),
       (pg_temp.u('2'), ARRAY['francais'], 20, 'approved', 'Europe/Paris');
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT pg_temp.u('1'), d, h, 'Europe/Paris'
  FROM pg_catalog.unnest(ARRAY[1, 2, 3, 4, 5, 6, 7]::smallint[]) d, pg_catalog.unnest(ARRAY[17, 18, 19, 20]::smallint[]) h;
INSERT INTO public.student_profiles
  (profile_id, student_type, interface_mode, camera_policy, langue_cours, cohorte, niveau_declare, objectif)
VALUES
  (pg_temp.u('12'), 'minor', 'child', 'forbidden', 'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'),
  (pg_temp.u('22'), 'minor', 'child', 'forbidden', 'francais', 'enfant_10_13', 'debut_lettres', 'apprendre_a_lire'),
  (pg_temp.u('13'), 'autonomous', 'standard', 'allowed', 'francais', NULL, 'debut_lettres', 'apprendre_a_lire');
INSERT INTO public.groupes
  (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code, genre_public, niveau, etat, created_at)
VALUES (pg_temp.u('201'), pg_temp.u('1'), 'enfant', 5, 'SUP Classe', 2, 18, 'Europe/Paris',
        'francais', 'hommes', 'debut_lettres', 'active', pg_catalog.now() - interval '1 day');
INSERT INTO public.groupe_membres (groupe_id, student_id, joined_at)
VALUES (pg_temp.u('201'), pg_temp.u('12'), pg_catalog.now() - interval '1 day'),
       (pg_temp.u('201'), pg_temp.u('22'), pg_catalog.now() - interval '1 day');
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES (pg_temp.u('401'), pg_temp.u('1'), pg_temp.u('201'),
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '5 days 3 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '5 days 4 hours', 'planned');
-- T2 signe son contrat : une ecriture qui ne doit jamais disparaitre.
SELECT pg_temp.qui(pg_temp.u('2'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.signer_contrat((SELECT t.version FROM public.contract_texts t
  WHERE t.contract_kind = 'teacher_nda' AND t.locale = 'fr' AND t.is_current), 'Ali Second');
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- ------------------------------------------------------------------
-- A. anon n'a rien.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.direction_supprimer_comptes(uuid[],text,boolean)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.tuteur_supprimer_profil_enfant(uuid)', 'EXECUTE')
  AND NOT pg_catalog.has_table_privilege('anon', 'private.retraits_comptes', 'SELECT')
  AND NOT pg_catalog.has_table_privilege('authenticated', 'private.retraits_comptes', 'SELECT')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.suppr_retirer(uuid,uuid,text,text)', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('authenticated', 'private.suppr_anonymiser_echus()', 'EXECUTE'),
  'A.1 anon n''execute aucune des deux portes ; personne ne lit le journal ni n''appelle le retrait prive');
SET LOCAL ROLE anon;
SELECT pg_temp.refus($q$SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('12'))$q$, '42501', NULL,
  'A.2 anon : appel de la porte du tuteur refuse');
RESET ROLE;

-- ------------------------------------------------------------------
-- B. Le tuteur, hors de son foyer.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('21'), 'guardian');
SELECT pg_temp.refus($q$SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('12'))$q$, '42501', 'profil_hors_foyer',
  'B.1 le tuteur de H2 ne retire pas l''enfant du foyer H1');
SELECT pg_temp.qui(pg_temp.u('11'), 'guardian');
SELECT pg_temp.refus($q$SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('13'))$q$, '42501', 'profil_hors_foyer',
  'B.2 le tuteur ne retire pas l''eleve adulte autonome de son foyer');
SELECT pg_temp.refus($q$SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('11'))$q$, '42501', 'profil_hors_foyer',
  'B.3 le tuteur ne se retire pas lui-meme par cette porte');
SELECT pg_temp.qui(pg_temp.u('1'), 'teacher');
SELECT pg_temp.refus($q$SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('12'))$q$, '42501', NULL,
  'B.4 un enseignant n''appelle pas la porte du tuteur');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT p.deleted_at FROM public.profiles p WHERE p.id = pg_temp.u('12')) IS NULL
  AND NOT EXISTS (SELECT 1 FROM private.retraits_comptes),
  'B.5 apres les refus : aucun profil retire, aucun retrait journalise');

-- ------------------------------------------------------------------
-- C. Le tuteur retire le profil de son enfant.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('11'), 'guardian');
SELECT pg_catalog.set_config('test.r', public.tuteur_supprimer_profil_enfant(pg_temp.u('12'))::text, true);
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.r')::jsonb ->> 'statut' = 'retire'
  AND (pg_catalog.current_setting('test.r')::jsonb ->> 'anonymiser_le')::timestamptz > pg_catalog.now() + interval '29 days'
  AND NOT (pg_catalog.current_setting('test.r')::jsonb ? 'retrait_id'),
  'C.1 retrait par le tuteur : retire, anonymisation dans 30 jours (delai propose)');
SELECT pg_temp.vrai(
  (SELECT p.deleted_at IS NOT NULL AND p.account_status = 'disabled' AND p.first_name = 'Lina'
     FROM public.profiles p WHERE p.id = pg_temp.u('12'))
  AND (SELECT r.source = 'tuteur' AND r.acteur = pg_temp.u('11') AND r.anonymise_le IS NULL
         FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('12')),
  'C.2 le profil sort des listes et ne se connecte plus ; journalise ; pas encore anonymise');
SELECT pg_temp.vrai(
  (SELECT gm.left_at IS NOT NULL AND gm.left_by = pg_temp.u('11') FROM public.groupe_membres gm
    WHERE gm.groupe_id = pg_temp.u('201') AND gm.student_id = pg_temp.u('12'))
  AND (SELECT gm.left_at IS NULL FROM public.groupe_membres gm
        WHERE gm.groupe_id = pg_temp.u('201') AND gm.student_id = pg_temp.u('22'))
  AND (SELECT g.ended_at IS NULL AND g.teacher_id = pg_temp.u('1') FROM public.groupes g WHERE g.id = pg_temp.u('201'))
  AND (SELECT s.status = 'planned' FROM public.sessions s WHERE s.id = pg_temp.u('401')),
  'C.3 Lina quitte la classe ; Sami y reste, la classe, son enseignant et sa seance sont intacts');

-- ------------------------------------------------------------------
-- D. La direction.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal1');
SELECT pg_temp.refus($q$SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('2')])$q$, '42501', NULL,
  'D.1 la direction sans double verification est refusee');
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT pg_temp.refus($q$SELECT public.direction_supprimer_comptes(ARRAY[]::uuid[])$q$, '22023', 'selection_vide',
  'D.2 une selection vide est refusee');
SELECT pg_catalog.set_config('test.d', public.direction_supprimer_comptes(
  ARRAY[pg_temp.u('1'), pg_temp.u('2'), pg_temp.u('13'), pg_temp.u('31'), pg_temp.u('32'),
        pg_temp.u('12'), pg_temp.u('999')], 'profils de test', true)::text, true);
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
CREATE TEMP TABLE resultat_d AS
SELECT (x ->> 'id')::uuid AS id, x ->> 'statut' AS statut, x ->> 'raison' AS raison, x
  FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.d')::jsonb) x;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM resultat_d) = 7
  AND (SELECT statut || '/' || coalesce(raison, '') FROM resultat_d WHERE id = pg_temp.u('1')) = 'refuse/seances_a_venir'
  -- La fixture 401 parmi les seances a venir, quelle que soit sa place : le
  -- creneau hebdomadaire de la classe engendre aussi ses seances, dont l'ordre
  -- depend de la date du jour (SCENARIOS-ISOLES, 07/11/2026).
  AND EXISTS (SELECT 1 FROM resultat_d r,
                     pg_catalog.jsonb_array_elements(r.x -> 'seances') s
               WHERE r.id = pg_temp.u('1') AND s ->> 'session_id' = pg_temp.u('401')::text)
  AND (SELECT statut FROM resultat_d WHERE id = pg_temp.u('2')) = 'retire'
  AND (SELECT statut FROM resultat_d WHERE id = pg_temp.u('13')) = 'retire'
  AND (SELECT raison FROM resultat_d WHERE id = pg_temp.u('31')) = 'soi_meme'
  AND (SELECT raison FROM resultat_d WHERE id = pg_temp.u('32')) = 'compte_direction'
  AND (SELECT raison FROM resultat_d WHERE id = pg_temp.u('12')) = 'deja_retire'
  AND (SELECT raison FROM resultat_d WHERE id = pg_temp.u('999')) = 'introuvable',
  'D.3 selection melangee : un resultat par identifiant ; la seance a venir de T est nommee');
SELECT pg_temp.vrai(
  (SELECT p.first_name = 'Compte' AND p.deleted_at IS NOT NULL FROM public.profiles p WHERE p.id = pg_temp.u('2'))
  AND (SELECT p.first_name = 'Compte' FROM public.profiles p WHERE p.id = pg_temp.u('13'))
  AND (SELECT r.anonymise_le IS NOT NULL FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('2'))
  AND (SELECT p.deleted_at IS NULL AND p.first_name = 'Omar' FROM public.profiles p WHERE p.id = pg_temp.u('1'))
  AND (SELECT p.deleted_at IS NULL FROM public.profiles p WHERE p.id = pg_temp.u('32')),
  'D.4 anonymisation immediate demandee : T2 et A1 anonymises ; T et D2 intacts');

-- ------------------------------------------------------------------
-- E. L'anonymisation a l'echeance, pas avant.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.suppr_anonymiser_echus() = 0
  AND (SELECT p.first_name FROM public.profiles p WHERE p.id = pg_temp.u('12')) = 'Lina',
  'E.1 avant l''echeance, rien n''est anonymise');
UPDATE private.retraits_comptes
   SET retire_le = pg_catalog.clock_timestamp() - interval '31 days',
       anonymiser_le = pg_catalog.clock_timestamp() - interval '1 day'
 WHERE profile_id = pg_temp.u('12');
-- Un appel par instruction : l'ordre d'evaluation dans un AND n'est pas garanti.
SELECT pg_temp.vrai(private.suppr_anonymiser_echus() = 1, 'E.2 a l''echeance : un retrait anonymise');
SELECT pg_temp.vrai(
  (SELECT p.first_name || ' ' || p.last_name FROM public.profiles p WHERE p.id = pg_temp.u('12')) = 'Compte supprimé'
  AND (SELECT p.immutable_id FROM public.profiles p WHERE p.id = pg_temp.u('12')) = 'SUP-E1',
  'E.3 Lina est anonymisee, son matricule est garde');
SELECT pg_temp.vrai(private.suppr_anonymiser_echus() = 0, 'E.4 un second passage ne refait rien');

-- ------------------------------------------------------------------
-- F. Aucune ecriture comptable ne disparait.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT EXISTS (
    SELECT 1 FROM compta_avant a
     WHERE (xpath('/row/c/text()', query_to_xml(pg_catalog.format('SELECT count(*) AS c FROM public.%I', a.nom), false, true, '')))[1]::text::bigint < a.n)
  AND EXISTS (SELECT 1 FROM public.contract_acceptances c
               WHERE c.profile_id = pg_temp.u('2') AND c.contract_kind = 'teacher_nda' AND c.signer_name = 'Ali Second')
  AND (SELECT pg_catalog.count(*) FROM public.audit_logs l WHERE l.action = 'compte_retire') >= 3
  AND (SELECT pg_catalog.count(*) FROM public.audit_logs l WHERE l.action = 'compte_anonymise') >= 3,
  'F.1 aucune table comptable ne perd une ligne ; le contrat signe de T2 reste ; retraits et anonymisations au journal d''audit');

DO $fin$ BEGIN RAISE NOTICE 'SUPPRIMER : scenario vert'; END $fin$;
ROLLBACK;
