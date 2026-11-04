-- SUPPRIMER-bis (03/11/2026 ; migration 20261108900000) : la restauration
-- pendant le delai de conservation, et la liste des retraits.
--
--   A. seule la direction en aal2 restaure et lit la liste (le tuteur ne
--      restaure pas : reglage propose) ;
--   B. le journal garde l'etat d'avant de chaque compte retire ;
--   C. la liste, par curseur, sans doublon, par etat ;
--   D. restaurer : le profil revient avec son statut et son acces d'avant,
--      l'eleve n'est pas remis dans sa classe ; refus apres anonymisation et
--      pour un profil jamais retire ;
--   E. un retrait restaure ne s'anonymise jamais ; un retrait sans etat
--      d'avant ne se restaure pas ; un profil restaure se retire de nouveau ;
--   F. aucune ecriture comptable ne disparait.
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations. Tout
-- est annule a la fin. Fixtures reprises de scenarios_supprimer_comptes.sql.
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
LANGUAGE sql IMMUTABLE AS $$ SELECT ('5e9b0000-0000-4000-8000-' || pg_catalog.lpad(p, 12, '0'))::uuid $$;

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
  (pg_temp.u('1'), 'supbis-t@example.test'), (pg_temp.u('2'), 'supbis-t2@example.test'),
  (pg_temp.u('11'), 'supbis-p1@example.test'), (pg_temp.u('12'), 'supbis-e1@example.test'),
  (pg_temp.u('13'), 'supbis-a1@example.test'), (pg_temp.u('21'), 'supbis-p2@example.test'),
  (pg_temp.u('22'), 'supbis-e2@example.test'), (pg_temp.u('31'), 'supbis-d@example.test'),
  (pg_temp.u('32'), 'supbis-d2@example.test');
INSERT INTO public.households (id, timezone) VALUES (pg_temp.u('101'), 'Europe/Paris'), (pg_temp.u('102'), 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, gender, account_status) VALUES
  (pg_temp.u('1'), 'SUPB-T', 'teacher', NULL, 'Omar', 'Enseignant', 'male', 'provisional_active'),
  (pg_temp.u('2'), 'SUPB-T2', 'teacher', NULL, 'Ali', 'Second', 'male', 'pending_kyc'),
  (pg_temp.u('11'), 'SUPB-P1', 'guardian', pg_temp.u('101'), 'Samira', 'Un', 'female', 'active'),
  (pg_temp.u('12'), 'SUPB-E1', 'student', pg_temp.u('101'), 'Lina', 'Un', 'male', 'active'),
  (pg_temp.u('13'), 'SUPB-A1', 'student', pg_temp.u('101'), 'Karim', 'Un', 'male', 'active'),
  (pg_temp.u('21'), 'SUPB-P2', 'guardian', pg_temp.u('102'), 'Nadia', 'Deux', 'female', 'active'),
  (pg_temp.u('22'), 'SUPB-E2', 'student', pg_temp.u('102'), 'Sami', 'Deux', 'male', 'active'),
  (pg_temp.u('31'), 'SUPB-D', 'admin', NULL, 'Direction', 'Une', 'female', 'active'),
  (pg_temp.u('32'), 'SUPB-D2', 'admin', NULL, 'Direction', 'Deux', 'female', 'active');
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
VALUES (pg_temp.u('201'), pg_temp.u('1'), 'enfant', 5, 'SUPB Classe', 2, 18, 'Europe/Paris',
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
-- A. Personne d'autre que la direction en aal2.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT pg_catalog.has_function_privilege('anon', 'public.direction_restaurer_comptes(uuid[])', 'EXECUTE')
  AND NOT pg_catalog.has_function_privilege('anon', 'public.retraits_comptes_lister(text,timestamptz,uuid,integer)', 'EXECUTE'),
  'A.1 anon n''execute ni la restauration ni la liste');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('11'), 'guardian');
SELECT pg_temp.refus($q$SELECT public.direction_restaurer_comptes(ARRAY[pg_temp.u('12')])$q$, '42501', NULL,
  'A.2 un tuteur ne restaure pas (reglage propose : seule la direction restaure)');
SELECT pg_temp.refus($q$SELECT public.retraits_comptes_lister()$q$, '42501', NULL,
  'A.3 un tuteur ne lit pas la liste des retraits');
SELECT pg_temp.qui(pg_temp.u('1'), 'teacher');
SELECT pg_temp.refus($q$SELECT public.direction_restaurer_comptes(ARRAY[pg_temp.u('12')])$q$, '42501', NULL,
  'A.4 un enseignant ne restaure pas');
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal1');
SELECT pg_temp.refus($q$SELECT public.direction_restaurer_comptes(ARRAY[pg_temp.u('12')])$q$, '42501', NULL,
  'A.5 la direction sans double verification ne restaure pas');
SELECT pg_temp.refus($q$SELECT public.retraits_comptes_lister()$q$, '42501', NULL,
  'A.6 la direction sans double verification ne lit pas la liste');
RESET ROLE;

-- ------------------------------------------------------------------
-- B. Retraits : Lina par son tuteur ; T2 et Karim par la direction, T2
--    anonymise tout de suite.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('11'), 'guardian');
SELECT public.tuteur_supprimer_profil_enfant(pg_temp.u('12'));
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('2')], 'profil de test', true);
SELECT public.direction_supprimer_comptes(ARRAY[pg_temp.u('13')], 'profil de test', false);
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.vrai(
  (SELECT r.statut_avant::text FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('12')) = 'active'
  AND (SELECT r.statut_avant::text FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('2')) = 'pending_kyc',
  'B.1 le journal garde le statut d''avant de chaque compte retire');

-- ------------------------------------------------------------------
-- C. La liste, par curseur.
-- ------------------------------------------------------------------
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT pg_catalog.set_config('test.l', public.retraits_comptes_lister('tous', NULL, NULL, 2)::text, true);
SELECT pg_catalog.set_config('test.l2', public.retraits_comptes_lister('tous',
  (pg_catalog.current_setting('test.l')::jsonb #>> '{suivant,apres_le}')::timestamptz,
  (pg_catalog.current_setting('test.l')::jsonb #>> '{suivant,apres_id}')::uuid, 2)::text, true);
SELECT pg_temp.vrai(
  pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.l')::jsonb -> 'lignes') = 2
  AND pg_catalog.current_setting('test.l')::jsonb -> 'suivant' <> 'null'::jsonb
  AND pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.l2')::jsonb -> 'lignes') = 1
  AND pg_catalog.current_setting('test.l2')::jsonb -> 'suivant' = 'null'::jsonb
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.l')::jsonb -> 'lignes') a
                   JOIN pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.l2')::jsonb -> 'lignes') b
                     ON a ->> 'retrait_id' = b ->> 'retrait_id'),
  'C.1 trois retraits, deux par page : un curseur, une seconde page d''une ligne, aucun doublon');
SELECT pg_catalog.set_config('test.e', public.retraits_comptes_lister()::text, true);
SELECT pg_catalog.set_config('test.a', public.retraits_comptes_lister('anonymises')::text, true);
SELECT pg_temp.vrai(
  pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.e')::jsonb -> 'lignes') = 2
  AND pg_catalog.jsonb_array_length(pg_catalog.current_setting('test.a')::jsonb -> 'lignes') = 1
  AND (SELECT x ->> 'nom' || '|' || (x ->> 'matricule') || '|' || (x ->> 'source') || '|' || (x ->> 'restaurable')
         FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.e')::jsonb -> 'lignes') x
        WHERE x ->> 'profile_id' = pg_temp.u('12')::text) = 'Lina Un|SUPB-E1|tuteur|true'
  AND (SELECT x ->> 'motif' FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.e')::jsonb -> 'lignes') x
        WHERE x ->> 'profile_id' = pg_temp.u('13')::text) = 'profil de test'
  AND (SELECT x ->> 'nom' FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.a')::jsonb -> 'lignes') x) = 'Compte supprimé',
  'C.2 en cours : Lina (par son tuteur, restaurable) et Karim (avec son motif) ; anonymises : T2, sous « Compte supprime »');
SELECT pg_temp.refus($q$SELECT public.retraits_comptes_lister('n_importe')$q$, '22023', 'etat_inconnu',
  'C.3 un etat inconnu est refuse');

-- ------------------------------------------------------------------
-- D. La restauration.
-- ------------------------------------------------------------------
SELECT pg_catalog.set_config('test.r', public.direction_restaurer_comptes(
  ARRAY[pg_temp.u('12'), pg_temp.u('2'), pg_temp.u('22')])::text, true);
RESET ROLE;
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
CREATE TEMP TABLE resultat_r AS
SELECT (x ->> 'id')::uuid AS id, x ->> 'statut' AS statut, x ->> 'raison' AS raison, x
  FROM pg_catalog.jsonb_array_elements(pg_catalog.current_setting('test.r')::jsonb) x;
SELECT pg_temp.vrai(
  (SELECT statut FROM resultat_r WHERE id = pg_temp.u('12')) = 'restaure'
  AND (SELECT (x ->> 'classes_quittees')::integer FROM resultat_r WHERE id = pg_temp.u('12')) = 1
  AND (SELECT (x ->> 'classes_a_reaffecter')::boolean FROM resultat_r WHERE id = pg_temp.u('12'))
  AND (SELECT raison FROM resultat_r WHERE id = pg_temp.u('2')) = 'deja_anonymise'
  AND (SELECT raison FROM resultat_r WHERE id = pg_temp.u('22')) = 'aucun_retrait',
  'D.1 Lina restauree (une classe a reaffecter) ; T2 deja anonymise, refuse ; Sami jamais retire, refuse');
SELECT pg_temp.vrai(
  (SELECT p.deleted_at IS NULL AND p.account_status = 'active' AND p.access_until IS NULL AND p.first_name = 'Lina'
     FROM public.profiles p WHERE p.id = pg_temp.u('12'))
  AND (SELECT gm.left_at IS NOT NULL FROM public.groupe_membres gm
        WHERE gm.groupe_id = pg_temp.u('201') AND gm.student_id = pg_temp.u('12'))
  AND (SELECT r.restaure_par = pg_temp.u('31') FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('12'))
  AND EXISTS (SELECT 1 FROM public.audit_logs l WHERE l.action = 'compte_restaure'),
  'D.2 Lina revient dans les listes, avec son statut et son acces d''avant ; elle n''est PAS remise dans sa classe ; journalise');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT pg_temp.vrai(
  (public.direction_restaurer_comptes(ARRAY[pg_temp.u('12')]) -> 0 ->> 'raison') = 'aucun_retrait',
  'D.3 une seconde restauration ne refait rien');
RESET ROLE;

-- ------------------------------------------------------------------
-- E. Un retrait restaure ne s'anonymise jamais ; un retrait ancien sans
--    etat d'avant ne se restaure pas ; un profil restaure se retire de nouveau.
-- ------------------------------------------------------------------
UPDATE private.retraits_comptes
   SET retire_le = pg_catalog.clock_timestamp() - interval '31 days',
       anonymiser_le = pg_catalog.clock_timestamp() - interval '1 day'
 WHERE profile_id = pg_temp.u('12');
SELECT pg_temp.vrai(private.suppr_anonymiser_echus() = 0, 'E.1 l''echeance passee d''un retrait restaure n''anonymise rien');
SELECT pg_temp.vrai(
  (SELECT p.first_name FROM public.profiles p WHERE p.id = pg_temp.u('12')) = 'Lina',
  'E.2 Lina garde son nom');
UPDATE private.retraits_comptes SET statut_avant = NULL WHERE profile_id = pg_temp.u('13');
SET LOCAL ROLE authenticated;
SELECT pg_temp.qui(pg_temp.u('31'), 'admin', 'aal2');
SELECT pg_temp.vrai(
  (public.direction_restaurer_comptes(ARRAY[pg_temp.u('13')]) -> 0 ->> 'raison') = 'etat_avant_inconnu',
  'E.3 un retrait sans etat d''avant (pose avant cette migration) ne se restaure pas, rien n''est devine');
SELECT pg_temp.vrai(
  (public.direction_supprimer_comptes(ARRAY[pg_temp.u('12')], 'second retrait') -> 0 ->> 'statut') = 'retire',
  'E.4 un profil restaure se retire de nouveau');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT r.restaure_le IS NULL AND r.anonymise_le IS NULL AND r.motif = 'second retrait'
          AND r.anonymiser_le > pg_catalog.now() + interval '29 days'
     FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('12'))
  AND (SELECT pg_catalog.count(*) FROM private.retraits_comptes r WHERE r.profile_id = pg_temp.u('12')) = 1,
  'E.5 sa ligne du journal repart, avec une echeance neuve ; une ligne par profil');

-- ------------------------------------------------------------------
-- F. Aucune ecriture comptable ne disparait.
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  NOT EXISTS (
    SELECT 1 FROM compta_avant a
     WHERE (xpath('/row/c/text()', query_to_xml(pg_catalog.format('SELECT count(*) AS c FROM public.%I', a.nom), false, true, '')))[1]::text::bigint < a.n),
  'F.1 aucune table comptable ne perd une ligne');

DO $fin$ BEGIN RAISE NOTICE 'SUPPRIMER-bis : scenario vert'; END $fin$;
ROLLBACK;
