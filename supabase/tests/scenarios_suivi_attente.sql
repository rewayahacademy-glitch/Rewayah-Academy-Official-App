-- SUIVI-ATTENTE : droits, cinq etapes, delai honnete, cas hors du chemin droit,
-- carte de l'enseignant (S4), notification de l'enseignant, aucun message vers
-- un mineur. A rejouer apres stub_auth.sql et toutes les migrations.
BEGIN;

CREATE FUNCTION pg_temp.moi(p_uid uuid, p_role text, p_foyer uuid) RETURNS void
LANGUAGE sql AS $f$
  SELECT set_config('test.uid', p_uid::text, true),
         set_config('request.jwt.claim.sub', p_uid::text, true),
         set_config('test.jwt', pg_catalog.jsonb_build_object('sub', p_uid,
           'app_metadata', pg_catalog.jsonb_build_object('role', p_role, 'household_id', p_foyer))::text, true),
         set_config('request.jwt.claims', pg_catalog.jsonb_build_object('sub', p_uid,
           'app_metadata', pg_catalog.jsonb_build_object('role', p_role, 'household_id', p_foyer))::text, true)
$f$;

-- ---------------------------------------------------------------------------
-- Les personnes
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (id, email) VALUES
  ('5a000000-0000-0000-0000-000000000001', 'sa-tuteur@example.test'),
  ('5a000000-0000-0000-0000-000000000002', 'sa-enfant@example.test'),
  ('5a000000-0000-0000-0000-000000000003', 'sa-enseignant@example.test'),
  ('5a000000-0000-0000-0000-000000000004', 'sa-autre-tuteur@example.test'),
  ('5a000000-0000-0000-0000-000000000005', 'sa-autre-enfant@example.test'),
  ('5a000000-0000-0000-0000-000000000006', 'sa-adulte@example.test'),
  ('5a000000-0000-0000-0000-000000000007', 'sa-enseignante@example.test'),
  ('5a000000-0000-0000-0000-000000000008', 'sa-direction@example.test');
INSERT INTO public.households (id, timezone) VALUES
  ('5afffff0-0000-0000-0000-000000000001', 'Europe/Paris'),
  ('5afffff0-0000-0000-0000-000000000002', 'Europe/Paris'),
  ('5afffff0-0000-0000-0000-000000000003', 'Africa/Casablanca');
INSERT INTO public.profiles
  (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
  ('5a000000-0000-0000-0000-000000000001', 'SATUTEUR000001', 'guardian',
   '5afffff0-0000-0000-0000-000000000001', 'Tuteur', 'Un', 'active', 'male'),
  ('5a000000-0000-0000-0000-000000000002', 'SAENFANT000001', 'student',
   '5afffff0-0000-0000-0000-000000000001', 'Yusuf', 'Un', 'active', 'male'),
  ('5a000000-0000-0000-0000-000000000003', 'SAENSEIGN00001', 'teacher',
   NULL, 'Ibrahim', 'Camara', 'provisional_active', 'male'),
  ('5a000000-0000-0000-0000-000000000004', 'SATUTEUR000002', 'guardian',
   '5afffff0-0000-0000-0000-000000000002', 'Autre', 'Tuteur', 'active', 'female'),
  ('5a000000-0000-0000-0000-000000000005', 'SAENFANT000002', 'student',
   '5afffff0-0000-0000-0000-000000000002', 'Maryam', 'Deux', 'active', 'female'),
  ('5a000000-0000-0000-0000-000000000006', 'SAADULTE000001', 'student',
   '5afffff0-0000-0000-0000-000000000003', 'Leila', 'Adulte', 'active', 'female'),
  ('5a000000-0000-0000-0000-000000000007', 'SAENSEIGN00002', 'teacher',
   NULL, 'Khadija', 'Diallo', 'provisional_active', 'female'),
  ('5a000000-0000-0000-0000-000000000008', 'SADIRECTION001', 'admin',
   NULL, 'Direction', 'Test', 'active', 'female');
UPDATE public.households SET primary_guardian_id = '5a000000-0000-0000-0000-000000000001'
 WHERE id = '5afffff0-0000-0000-0000-000000000001';
UPDATE public.households SET primary_guardian_id = '5a000000-0000-0000-0000-000000000004'
 WHERE id = '5afffff0-0000-0000-0000-000000000002';
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode, cohorte) VALUES
  ('5a000000-0000-0000-0000-000000000002', 'minor', 'child', 'enfant_6_9'),
  ('5a000000-0000-0000-0000-000000000005', 'minor', 'standard', 'enfant_10_13'),
  ('5a000000-0000-0000-0000-000000000006', 'autonomous', 'standard', 'adulte_18_plus');
INSERT INTO public.teacher_profiles (profile_id, country, languages, kyc_status) VALUES
  ('5a000000-0000-0000-0000-000000000003', 'Guinée', ARRAY['fr']::text[], 'approved'),
  ('5a000000-0000-0000-0000-000000000007', 'Mali', ARRAY['fr']::text[], 'approved');

-- ---------------------------------------------------------------------------
-- 0. Les colonnes : vrai pour un nouvel enseignant, rien de confirme
-- ---------------------------------------------------------------------------
DO $defauts$
BEGIN
  IF NOT (SELECT montre_aux_familles FROM public.teacher_profiles
           WHERE profile_id = '5a000000-0000-0000-0000-000000000003') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un nouvel enseignant doit montrer par defaut';
  END IF;
  IF (SELECT montre_aux_familles_confirme_le FROM public.teacher_profiles
       WHERE profile_id = '5a000000-0000-0000-0000-000000000003') IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : rien ne doit etre confirme a la creation';
  END IF;
END
$defauts$;

-- ---------------------------------------------------------------------------
-- 1. Une demande envoyee il y a 3 jours : etape 1 faite, 2 en cours, delai honnete
-- ---------------------------------------------------------------------------
INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
   source, etat, created_at)
VALUES
  ('5afffff0-0000-0000-0000-0000000000d1', '5a000000-0000-0000-0000-000000000002',
   'enfant', 'francais', 'Europe/Paris', ARRAY[1, 3]::smallint[], ARRAY[18, 18]::smallint[],
   'personnalisee', 'envoyee', pg_catalog.now() - interval '3 days'),
  ('5afffff0-0000-0000-0000-0000000000d2', '5a000000-0000-0000-0000-000000000005',
   'enfant', 'francais', 'Europe/Paris', ARRAY[2]::smallint[], ARRAY[17]::smallint[],
   'personnalisee', 'envoyee', pg_catalog.now() - interval '20 days'),
  ('5afffff0-0000-0000-0000-0000000000d3', '5a000000-0000-0000-0000-000000000006',
   'adulte', 'francais', 'Africa/Casablanca', ARRAY[4]::smallint[], ARRAY[20]::smallint[],
   'personnalisee', 'envoyee', pg_catalog.now() - interval '1 day');

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $etape1$
DECLARE r record; n integer;
BEGIN
  SELECT count(*) INTO n FROM public.suivi_attente_foyer();
  IF n <> 1 THEN RAISE EXCEPTION 'SUIVI-ATTENTE : le tuteur doit voir 1 demande, vu %', n; END IF;
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.demande_id <> '5afffff0-0000-0000-0000-0000000000d1' OR r.prenom <> 'Yusuf'
     OR r.cas <> 'chemin' OR NOT r.version_simple THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : demande, cas ou version simple inattendus : %', r;
  END IF;
  IF (SELECT array_agg(e ->> 'statut' ORDER BY (e ->> 'numero')::int)
        FROM jsonb_array_elements(r.etapes) e)
     IS DISTINCT FROM ARRAY['fait', 'en_cours', 'a_venir', 'a_venir', 'a_venir'] THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : statuts etape 1 inattendus : %', r.etapes;
  END IF;
  IF (r.etapes -> 0 ->> 'le') IS NULL OR (r.etapes -> 1 ->> 'le') IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l etape 1 a une date, l etape 2 n en a pas : %', r.etapes;
  END IF;
  IF r.enseignant IS NOT NULL OR r.classe IS NOT NULL OR r.premier_cours IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : avant l etape 4, aucun enseignant ni classe ni cours';
  END IF;
  IF (r.delai ->> 'jours')::int <> 14 OR (r.delai ->> 'depasse')::boolean
     OR (r.delai ->> 'point_passe')::boolean OR (r.delai ->> 'limite') IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : delai honnete inattendu : %', r.delai;
  END IF;
  IF jsonb_array_length(r.occurrences) <> 2 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les deux jours choisis sont rappeles : %', r.occurrences;
  END IF;
END
$etape1$;
RESET ROLE;

-- Le delai depasse (20 jours) : le serveur le dit.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000004', 'guardian', '5afffff0-0000-0000-0000-000000000002');
SET LOCAL ROLE authenticated;
DO $depasse$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.demande_id <> '5afffff0-0000-0000-0000-0000000000d2' OR r.version_simple THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l autre foyer voit sa propre demande seulement : %', r;
  END IF;
  IF NOT (r.delai ->> 'depasse')::boolean OR NOT (r.delai ->> 'point_passe')::boolean THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : a 20 jours le delai est depasse : %', r.delai;
  END IF;
END
$depasse$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 2. Les refus : anonyme, autre role, autre foyer, autre eleve
-- ---------------------------------------------------------------------------
SET LOCAL ROLE anon;
DO $anon$
BEGIN
  PERFORM * FROM public.suivi_attente_foyer();
  RAISE EXCEPTION 'SUIVI-ATTENTE : anon ne doit pas lire le suivi';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END
$anon$;
RESET ROLE;

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
DO $enseignant_refuse$
BEGIN
  PERFORM * FROM public.suivi_attente_foyer();
  RAISE EXCEPTION 'SUIVI-ATTENTE : un enseignant ne lit pas le suivi des familles';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END
$enseignant_refuse$;
RESET ROLE;

-- Un eleve d'un autre foyer ne voit que sa propre demande ; l'adulte aussi.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000005', 'student', '5afffff0-0000-0000-0000-000000000002');
SET LOCAL ROLE authenticated;
DO $autre_eleve$
BEGIN
  IF (SELECT count(*) FROM public.suivi_attente_foyer()
       WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1') <> 0 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un eleve d un autre foyer ne lit pas la demande d autrui';
  END IF;
  IF (SELECT count(*) FROM public.suivi_attente_foyer()) <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un eleve ne voit que sa demande';
  END IF;
END
$autre_eleve$;
RESET ROLE;

-- Un tuteur dont le jeton porte un autre foyer ne lit rien d'un foyer etranger.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000002');
SET LOCAL ROLE authenticated;
DO $jeton_etranger$
BEGIN
  IF (SELECT count(*) FROM public.suivi_attente_foyer()
       WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1') <> 0 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le foyer vient du jeton, pas de la ligne';
  END IF;
END
$jeton_etranger$;
RESET ROLE;

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000006', 'student', '5afffff0-0000-0000-0000-000000000003');
SET LOCAL ROLE authenticated;
DO $adulte$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.demande_id <> '5afffff0-0000-0000-0000-0000000000d3' OR r.version_simple
     OR r.fuseau_iana <> 'Africa/Casablanca' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l adulte lit sa propre demande dans son fuseau : %', r;
  END IF;
END
$adulte$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 3. Classe confirmee, sans enseignant : etape 3 faite, 4 en cours, attente
-- ---------------------------------------------------------------------------
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code)
VALUES
  ('5afffff0-0000-0000-0000-0000000000a1', NULL, 'en_attente_enseignant',
   'enfant', 5, 'Classe Al-Fatiha', 1, 18, 'Europe/Paris', 'francais');
-- Comme la creation d'une classe depuis un regroupement : l'eleve entre dans la
-- classe AVANT que sa demande porte le groupe. Aucun evenement `eleve_integre`
-- n'est alors ecrit ; l'etape 5 s'appuie sur l'adhesion, pas sur lui.
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('5afffff0-0000-0000-0000-0000000000a1', '5a000000-0000-0000-0000-000000000002');
UPDATE public.demandes_horaires_famille
   SET etat = 'classe_validee', groupe_id = '5afffff0-0000-0000-0000-0000000000a1'
 WHERE id = '5afffff0-0000-0000-0000-0000000000d1';

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $etape3$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.cas <> 'en_attente_enseignant' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : classe sans enseignant = en_attente_enseignant, vu %', r.cas;
  END IF;
  IF (SELECT array_agg(e ->> 'statut' ORDER BY (e ->> 'numero')::int)
        FROM jsonb_array_elements(r.etapes) e)
     IS DISTINCT FROM ARRAY['fait', 'fait', 'fait', 'en_cours', 'a_venir'] THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : statuts etape 3 inattendus : %', r.etapes;
  END IF;
  IF (r.etapes -> 2 ->> 'le') IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l etape 3 a une date';
  END IF;
  IF r.classe <> 'Classe Al-Fatiha' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la classe est nommee des l etape 3';
  END IF;
  IF r.enseignant IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : aucun enseignant avant l etape 4 (% )', r.enseignant;
  END IF;
  IF r.delai IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : plus de delai de formation une fois la classe confirmee : %', r.delai;
  END IF;
END
$etape3$;
RESET ROLE;

DO $sans_evenement$
BEGIN
  IF EXISTS (SELECT 1 FROM public.demande_evenements
              WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1'
                AND type = 'eleve_integre') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : ce scenario rejoue l ordre sans evenement eleve_integre';
  END IF;
END
$sans_evenement$;

-- ---------------------------------------------------------------------------
-- 4. Enseignant affecte, eleve integre, premier cours connu : etapes 4 et 5
-- ---------------------------------------------------------------------------
-- L'enseignant regle sa presentation.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT public.regler_presentation_aux_familles(true, 'GN', 'FR', 'Je suis heureux de vous retrouver.');
DO $reglage$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.ma_presentation_aux_familles();
  IF NOT r.montre_aux_familles OR NOT r.confirme OR r.pays_origine <> 'GN' OR r.pays_residence <> 'FR' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le reglage n a pas ete enregistre : %', r;
  END IF;
END
$reglage$;
RESET ROLE;

DO $avant_pret$
BEGIN
  IF EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'tout_est_pret') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : aucun « tout est pret » avant l enseignant et la premiere seance';
  END IF;
END
$avant_pret$;

UPDATE public.groupes
   SET teacher_id = '5a000000-0000-0000-0000-000000000003', etat = 'active'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
INSERT INTO public.sessions (id, teacher_id, groupe_id, started_at, ended_at, status)
VALUES ('5afffff0-0000-0000-0000-0000000000b1', '5a000000-0000-0000-0000-000000000003',
        '5afffff0-0000-0000-0000-0000000000a1',
        pg_catalog.now() + interval '3 days', pg_catalog.now() + interval '3 days 1 hour', 'planned');
-- Les declencheurs differes (notifier_classe) tournent maintenant.
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $etape45$
DECLARE r record; cles text[];
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.cas <> 'chemin' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : enseignant affecte = chemin droit, vu %', r.cas;
  END IF;
  IF (SELECT array_agg(e ->> 'statut' ORDER BY (e ->> 'numero')::int)
        FROM jsonb_array_elements(r.etapes) e)
     IS DISTINCT FROM ARRAY['fait', 'fait', 'fait', 'fait', 'fait'] THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les cinq etapes sont faites : %', r.etapes;
  END IF;
  IF r.premier_cours IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le premier cours est dit quand il est connu';
  END IF;
  IF r.enseignant ->> 'prenom' <> 'Ibrahim' OR r.enseignant ->> 'titre' <> 'sayyid'
     OR (r.enseignant ->> 'nom') IS NOT NULL
     OR r.enseignant ->> 'pays_origine' <> 'GN' OR r.enseignant ->> 'pays_residence' <> 'FR'
     OR r.enseignant ->> 'mot' <> 'Je suis heureux de vous retrouver.'
     OR r.enseignant ->> 'teacher_id' <> '5a000000-0000-0000-0000-000000000003' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : carte de l enseignant inattendue : %', r.enseignant;
  END IF;
  SELECT array_agg(k ORDER BY k) INTO cles FROM jsonb_object_keys(r.enseignant) k;
  IF NOT (cles @> ARRAY['langue_cours', 'mot', 'montre', 'pays_origine',
                        'pays_residence', 'prenom', 'teacher_id', 'titre']
          AND cles <@ ARRAY['langue_cours', 'mot', 'montre', 'pays_origine',
                            'pays_residence', 'prenom', 'teacher_id', 'titre']) THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la carte ne porte que ses champs (civilite et prenom, ni nom de famille, ville, telephone, courriel, naissance, piece) : %', cles;
  END IF;
END
$etape45$;
RESET ROLE;

-- La premiere seance reste la premiere : passee depuis 3 jours, le suivi est
-- encore en tete de l'accueil ; passee depuis 10 jours, il en disparait.
-- (Les faits du journal sont recules de 20 jours, sans declencheur : le test
-- rejoue une demande ancienne ; en production le journal est en ajout seul.)
SET LOCAL session_replication_role = replica;
UPDATE public.demande_evenements SET survenu_le = survenu_le - interval '20 days'
 WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1';
UPDATE public.groupe_membres SET joined_at = joined_at - interval '20 days'
 WHERE groupe_id = '5afffff0-0000-0000-0000-0000000000a1';
SET LOCAL session_replication_role = origin;
UPDATE public.sessions
   SET started_at = pg_catalog.now() - interval '3 days',
       ended_at = pg_catalog.now() - interval '3 days' + interval '1 hour'
 WHERE id = '5afffff0-0000-0000-0000-0000000000b1';
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $accueil_3j$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF NOT r.premier_cours_passe OR NOT r.visible_accueil OR r.premier_cours IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : 3 jours apres le premier cours, le suivi reste en tete : %', r;
  END IF;
END
$accueil_3j$;
RESET ROLE;
UPDATE public.sessions
   SET started_at = pg_catalog.now() - interval '10 days',
       ended_at = pg_catalog.now() - interval '10 days' + interval '1 hour'
 WHERE id = '5afffff0-0000-0000-0000-0000000000b1';
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $accueil_10j$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.visible_accueil OR NOT r.premier_cours_passe THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : 10 jours apres le premier cours, le suivi quitte l accueil : %', r;
  END IF;
END
$accueil_10j$;
RESET ROLE;
-- Retour au futur pour la suite.
UPDATE public.sessions
   SET started_at = pg_catalog.now() + interval '3 days',
       ended_at = pg_catalog.now() + interval '3 days' + interval '1 hour'
 WHERE id = '5afffff0-0000-0000-0000-0000000000b1';

-- L'enseignant qui refuse : nom et langue du cours seulement.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT public.regler_presentation_aux_familles(false, 'GN', 'FR', 'Je suis heureux de vous retrouver.');
RESET ROLE;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $refus_visibilite$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.enseignant ->> 'prenom' <> 'Ibrahim' OR (r.enseignant ->> 'nom') IS NOT NULL
     OR (r.enseignant ->> 'langue_cours') IS NULL
     OR (r.enseignant ->> 'teacher_id') IS NULL
     OR (r.enseignant ->> 'pays_origine') IS NOT NULL
     OR (r.enseignant ->> 'pays_residence') IS NOT NULL
     OR (r.enseignant ->> 'mot') IS NOT NULL
     OR (r.enseignant ->> 'montre')::boolean THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un enseignant qui refuse ne cache que ses pays et son mot (la photo n est pas masquee par ce reglage) : %', r.enseignant;
  END IF;
END
$refus_visibilite$;
RESET ROLE;

-- Le reglage lui-meme : reserve a l'enseignant, valeurs bornees.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $reglage_refus$
BEGIN
  PERFORM public.regler_presentation_aux_familles(true);
  RAISE EXCEPTION 'SUIVI-ATTENTE : un tuteur ne regle pas la presentation d un enseignant';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END
$reglage_refus$;
RESET ROLE;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
DO $reglage_borne$
BEGIN
  BEGIN
    PERFORM public.regler_presentation_aux_familles(true, 'fra', NULL, NULL);
    RAISE EXCEPTION 'SUIVI-ATTENTE : un pays doit etre un code a deux lettres';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
  BEGIN
    PERFORM public.regler_presentation_aux_familles(true, NULL, NULL, pg_catalog.repeat('a', 501));
    RAISE EXCEPTION 'SUIVI-ATTENTE : le mot est borne a 500 caracteres';
  EXCEPTION WHEN SQLSTATE '22023' THEN NULL;
  END;
END
$reglage_borne$;
RESET ROLE;

-- L'export « mes donnees » de l'enseignant porte ses colonnes.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
DO $export$
DECLARE x jsonb;
BEGIN
  x := public.mes_donnees_export() -> 'profil_enseignant';
  IF NOT (x ? 'pays_origine' AND x ? 'pays_residence' AND x ? 'mot_presentation'
          AND x ? 'montre_aux_familles' AND x ? 'montre_aux_familles_confirme_le') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l export de l enseignant porte pays, mot et visibilite : %', x;
  END IF;
  IF x ->> 'pays_origine' <> 'GN' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le pays d origine exporte est celui qu il a regle : %', x;
  END IF;
END
$export$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 5. La notification de l'enseignant : une seule, enrichie ; rien vers un mineur
-- ---------------------------------------------------------------------------
DO $notification$
DECLARE n integer; p jsonb;
BEGIN
  SELECT count(*) INTO n FROM public.notifications
   WHERE destinataire = '5a000000-0000-0000-0000-000000000003'
     AND evenement = 'enseignant_affecte'
     AND params ->> 'groupe_id' = '5afffff0-0000-0000-0000-0000000000a1';
  IF n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l enseignant recoit UNE notification d affectation, % trouvee(s)', n;
  END IF;
  SELECT params INTO p FROM public.notifications
   WHERE destinataire = '5a000000-0000-0000-0000-000000000003'
     AND evenement = 'enseignant_affecte';
  IF p ->> 'portee' <> 'classe' OR p ->> 'classe' <> 'Classe Al-Fatiha'
     OR (p ->> 'eleves_n')::int <> 1 OR p ->> 'public' <> 'enfant'
     OR (p ->> 'tranche') IS NULL
     OR (p ->> 'debut_local') IS NULL OR (p ->> 'fuseau') IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : notification de l enseignant incomplete : %', p;
  END IF;
  -- Jamais de notification de portee « classe » vers un eleve.
  IF EXISTS (SELECT 1 FROM public.notifications nn
               JOIN public.profiles pp ON pp.id = nn.destinataire
              WHERE nn.params ->> 'portee' = 'classe' AND pp.role = 'student') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : aucun message de classe vers un eleve';
  END IF;
  -- Le courriel part pour l'enseignant et pour la famille (trace).
  IF NOT private.notification_avec_courriel('enseignant_affecte', 'classe')
     OR NOT private.notification_avec_courriel('enseignant_affecte', 'foyer')
     OR NOT private.notification_avec_courriel('enseignant_affecte', 'soi') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le courriel d affectation doit partir (enseignant, foyer, adulte)';
  END IF;
END
$notification$;

-- ---------------------------------------------------------------------------
-- 5 bis. « Tout est pret » : une seule, au tuteur, jamais a l'enfant
-- ---------------------------------------------------------------------------
DO $pret$
DECLARE n integer; p jsonb; dest text;
BEGIN
  SELECT count(*) INTO n FROM public.notifications
   WHERE evenement = 'tout_est_pret'
     AND destinataire = '5a000000-0000-0000-0000-000000000001'
     AND params ->> 'groupe_id' = '5afffff0-0000-0000-0000-0000000000a1';
  IF n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le tuteur recoit UNE notification « tout est pret », % trouvee(s)', n;
  END IF;
  SELECT params, destination INTO p, dest FROM public.notifications
   WHERE evenement = 'tout_est_pret' AND destinataire = '5a000000-0000-0000-0000-000000000001';
  IF p ->> 'portee' <> 'foyer' OR p ->> 'eleve_id' <> '5a000000-0000-0000-0000-000000000002'
     OR (p ->> 'prochaine_local') IS NULL OR (p ->> 'fuseau') <> 'Europe/Paris'
     OR p -> 'eleves' <> '["Yusuf"]'::jsonb OR dest <> '/tuteur/demandes' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : notification « tout est pret » inattendue : % %', p, dest;
  END IF;
  -- L'enfant n'est jamais destinataire ; personne d'autre non plus.
  IF EXISTS (SELECT 1 FROM public.notifications
              WHERE evenement = 'tout_est_pret'
                AND destinataire <> '5a000000-0000-0000-0000-000000000001') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : « tout est pret » ne va qu au tuteur de ce foyer';
  END IF;
  -- Idempotente : rappelee, elle n'ajoute rien.
  IF private.suivi_attente_notifier_pret('5afffff0-0000-0000-0000-0000000000a1') <> 0
     OR (SELECT count(*) FROM public.notifications WHERE evenement = 'tout_est_pret') <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : « tout est pret » ne se repete pas';
  END IF;
  IF NOT private.notification_avec_courriel('tout_est_pret', 'soi')
     OR NOT private.notification_avec_courriel('tout_est_pret', 'foyer') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le courriel « tout est pret » doit partir';
  END IF;
END
$pret$;

-- ---------------------------------------------------------------------------
-- 6. Un changement de creneau recent est dit
-- ---------------------------------------------------------------------------
INSERT INTO public.notifications (destinataire, foyer_id, evenement, params, destination)
VALUES ('5a000000-0000-0000-0000-000000000001', '5afffff0-0000-0000-0000-000000000001',
        'creneau_change',
        '{"groupe_id":"5afffff0-0000-0000-0000-0000000000a1","portee":"foyer"}'::jsonb,
        '/tuteur');
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $changement$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.creneau_change_le IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le changement de creneau recent doit etre dit';
  END IF;
END
$changement$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 6 bis. Le fait pour la direction : les demandes envoyees depuis trop longtemps
-- ---------------------------------------------------------------------------
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000008', 'admin', NULL);
SET LOCAL ROLE authenticated;
DO $depassees$
DECLARE r record; n integer;
BEGIN
  SELECT count(*) INTO n FROM public.demandes_formation_depassees();
  IF n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la direction voit 1 demande depassee (d2, 20 jours), vu %', n;
  END IF;
  SELECT * INTO r FROM public.demandes_formation_depassees();
  IF r.demande_id <> '5afffff0-0000-0000-0000-0000000000d2' OR r.jours_depuis < 19
     OR r.matricule <> 'SAENFANT000002' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : demande depassee inattendue : %', r;
  END IF;
END
$depassees$;
RESET ROLE;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $depassees_refus$
BEGIN
  PERFORM * FROM public.demandes_formation_depassees();
  RAISE EXCEPTION 'SUIVI-ATTENTE : un tuteur ne lit pas les demandes depassees';
EXCEPTION WHEN insufficient_privilege THEN NULL;
END
$depassees_refus$;
RESET ROLE;
DO $depassees_anon$
BEGIN
  IF pg_catalog.has_function_privilege('anon', 'public.demandes_formation_depassees()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : demandes_formation_depassees ouverte a anon';
  END IF;
END
$depassees_anon$;

-- ---------------------------------------------------------------------------
-- 7. Les cas de cloture : refusee, retiree
-- ---------------------------------------------------------------------------
UPDATE public.demandes_horaires_famille
   SET etat = 'refusee', motif = 'refus_direction'
 WHERE id = '5afffff0-0000-0000-0000-0000000000d2';
UPDATE public.demandes_horaires_famille
   SET etat = 'retiree', motif = 'retrait_famille'
 WHERE id = '5afffff0-0000-0000-0000-0000000000d3';

SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000004', 'guardian', '5afffff0-0000-0000-0000-000000000002');
SET LOCAL ROLE authenticated;
DO $refusee$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.cas <> 'refusee' OR r.motif <> 'refus_direction' OR NOT r.peut_choisir_autre_creneau THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : demande refusee, motif et suite : %', r;
  END IF;
  IF (SELECT array_agg(e ->> 'statut' ORDER BY (e ->> 'numero')::int)
        FROM jsonb_array_elements(r.etapes) e)
     IS DISTINCT FROM ARRAY['fait', 'a_venir', 'a_venir', 'a_venir', 'a_venir'] THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : une demande close n a pas d etape en cours : %', r.etapes;
  END IF;
  IF r.delai IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : une demande close ne promet aucun delai';
  END IF;
END
$refusee$;
RESET ROLE;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000006', 'student', '5afffff0-0000-0000-0000-000000000003');
SET LOCAL ROLE authenticated;
DO $retiree$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer();
  IF r.cas <> 'retiree' OR r.motif <> 'retrait_famille' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : demande retiree : %', r;
  END IF;
END
$retiree$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 8. Le delai manquant : l'ecran ne promet rien
-- ---------------------------------------------------------------------------
INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
   source, etat, created_at)
VALUES
  ('5afffff0-0000-0000-0000-0000000000d4', '5a000000-0000-0000-0000-000000000005',
   'enfant', 'francais', 'Europe/Paris', ARRAY[5]::smallint[], ARRAY[16]::smallint[],
   'personnalisee', 'envoyee', pg_catalog.now());
UPDATE public.app_config SET value = '"absent"'::jsonb WHERE key = 'formation_delai_jours';
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000004', 'guardian', '5afffff0-0000-0000-0000-000000000002');
SET LOCAL ROLE authenticated;
DO $sans_delai$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer() WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d4';
  IF r.delai IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : sans valeur dans les reglages, aucun delai promis : %', r.delai;
  END IF;
END
$sans_delai$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 8 bis. L'effacement du compte efface aussi ce que l'enseignant montrait
-- ---------------------------------------------------------------------------
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000003', 'teacher', NULL);
SET LOCAL ROLE authenticated;
SELECT public.regler_presentation_aux_familles(true, 'GN', 'FR', 'Un mot a effacer.');
RESET ROLE;
UPDATE public.profiles
   SET first_name = 'Compte', last_name = 'supprimé', account_status = 'disabled'
 WHERE id = '5a000000-0000-0000-0000-000000000003';
DO $anonymisation$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.teacher_profiles
   WHERE profile_id = '5a000000-0000-0000-0000-000000000003';
  IF r.pays_origine IS NOT NULL OR r.pays_residence IS NOT NULL
     OR r.mot_presentation IS NOT NULL OR r.montre_aux_familles THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le compte efface ne montre plus rien aux familles : %', r;
  END IF;
END
$anonymisation$;

-- ---------------------------------------------------------------------------
-- 8 ter. L'eleve adulte est prevenu lui-meme ; l'ordre des faits ne change rien
-- ---------------------------------------------------------------------------
-- L'affectation de l'enseignant materialise les seances de la classe : le
-- fait qui rapproche l'etape 5 arrive de la classe elle-meme.
INSERT INTO public.demandes_horaires_famille
  (id, eleve_id, type_public, langue_code, fuseau_iana, jours, heures_locales,
   source, etat, created_at)
VALUES
  ('5afffff0-0000-0000-0000-0000000000d5', '5a000000-0000-0000-0000-000000000006',
   'adulte', 'francais', 'Africa/Casablanca', ARRAY[5]::smallint[], ARRAY[19]::smallint[],
   'personnalisee', 'envoyee', pg_catalog.now() - interval '2 days');
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local,
   timezone_iana, langue_code)
VALUES
  ('5afffff0-0000-0000-0000-0000000000a2', NULL, 'en_attente_enseignant',
   'adulte', 5, 'Classe Al-Baqara', 5, 19, 'Africa/Casablanca', 'francais');
INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('5afffff0-0000-0000-0000-0000000000a2', '5a000000-0000-0000-0000-000000000006');
UPDATE public.demandes_horaires_famille
   SET etat = 'classe_validee', groupe_id = '5afffff0-0000-0000-0000-0000000000a2'
 WHERE id = '5afffff0-0000-0000-0000-0000000000d5';
UPDATE public.groupes
   SET teacher_id = '5a000000-0000-0000-0000-000000000007', etat = 'active'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a2';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $adulte_pret$
DECLARE p jsonb; dest text;
BEGIN
  SELECT params, destination INTO p, dest FROM public.notifications
   WHERE evenement = 'tout_est_pret'
     AND destinataire = '5a000000-0000-0000-0000-000000000006';
  IF p IS NULL OR p ->> 'portee' <> 'soi' OR dest <> '/eleve'
     OR p ->> 'fuseau' <> 'Africa/Casablanca' OR (p -> 'eleves') IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : « tout est pret » de l eleve adulte inattendu : % %', p, dest;
  END IF;
  -- Jamais un enfant : aucun destinataire eleve hors de la tranche adulte.
  IF EXISTS (SELECT 1 FROM public.notifications n
               JOIN public.profiles pp ON pp.id = n.destinataire
               JOIN public.student_profiles sp ON sp.profile_id = pp.id
              WHERE n.evenement = 'tout_est_pret' AND sp.cohorte <> 'adulte_18_plus') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : « tout est pret » n est jamais ecrit a un enfant';
  END IF;
END
$adulte_pret$;

-- ---------------------------------------------------------------------------
-- 8 quater. Aucun courriel n'est mis en file pour un mineur, quel que soit le modele
-- ---------------------------------------------------------------------------
DO $courriel_mineur$
DECLARE m text;
BEGIN
  FOREACH m IN ARRAY ARRAY['enseignant_affecte', 'classe_creee', 'classe_validee',
                           'eleve_inscrit', 'tout_est_pret', 'demande_close',
                           'seance_annulee', 'classe_changee', 'creneau_change'] LOOP
    PERFORM public.courriel_enfiler('classes', m, 'sa-enfant@example.test',
      '5a000000-0000-0000-0000-000000000002', '{}'::jsonb, 'sa-mineur-' || m, 'auto');
    PERFORM public.courriel_enfiler('classes', m, 'sa-enfant-bis@example.test',
      '5a000000-0000-0000-0000-000000000005', '{}'::jsonb, 'sa-mineur-bis-' || m, 'auto');
  END LOOP;
  -- Aucune ligne, ni pour l'enfant de 6 a 9 ans ni pour celui de 10 a 13 ans.
  IF EXISTS (SELECT 1 FROM public.courriels_sortants cs
              JOIN public.student_profiles sp ON sp.profile_id = cs.destinataire_profil
             WHERE sp.student_type = 'minor') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : aucun courriel en file pour un mineur, quel que soit le modele';
  END IF;
  -- Le garde ne bloque pas l'adulte ni le tuteur.
  PERFORM public.courriel_enfiler('classes', 'tout_est_pret', 'sa-adulte@example.test',
    '5a000000-0000-0000-0000-000000000006', '{}'::jsonb, 'sa-adulte-ok', 'auto');
  PERFORM public.courriel_enfiler('classes', 'tout_est_pret', 'sa-tuteur@example.test',
    '5a000000-0000-0000-0000-000000000001', '{}'::jsonb, 'sa-tuteur-ok', 'auto');
  IF NOT EXISTS (SELECT 1 FROM public.courriels_sortants
                  WHERE destinataire_profil = '5a000000-0000-0000-0000-000000000006')
     OR NOT EXISTS (SELECT 1 FROM public.courriels_sortants
                     WHERE destinataire_profil = '5a000000-0000-0000-0000-000000000001'
                       AND cle_idempotence = 'sa-tuteur-ok') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l adulte et le tuteur recoivent leur courriel';
  END IF;
  -- Le tuteur recoit son propre courriel par la portee « foyer », pour chaque
  -- evenement ou l'eleve avait une portee « soi » et pour ceux de ce lot.
  IF NOT private.notification_avec_courriel('classe_creee', 'foyer')
     OR NOT private.notification_avec_courriel('classe_validee', 'foyer')
     OR NOT private.notification_avec_courriel('eleve_inscrit', 'foyer')
     OR NOT private.notification_avec_courriel('enseignant_affecte', 'foyer')
     OR NOT private.notification_avec_courriel('tout_est_pret', 'foyer') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le tuteur recoit son courriel par la portee foyer';
  END IF;
  -- Et le courriel du flux reel : le tuteur a recu celui de l'affectation et
  -- celui de « tout est pret ».
  IF NOT EXISTS (SELECT 1 FROM public.courriels_sortants
                  WHERE destinataire_profil = '5a000000-0000-0000-0000-000000000001'
                    AND modele = 'enseignant_affecte')
     OR NOT EXISTS (SELECT 1 FROM public.courriels_sortants
                     WHERE destinataire_profil = '5a000000-0000-0000-0000-000000000001'
                       AND modele = 'tout_est_pret'
                       AND cle_idempotence LIKE 'notification:%') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le tuteur doit recevoir les courriels du flux reel';
  END IF;
END
$courriel_mineur$;

-- ---------------------------------------------------------------------------
-- 8 sexies. Un remplacement direct (A vers B) previent B une seule fois
-- ---------------------------------------------------------------------------
UPDATE public.groupes SET teacher_id = '5a000000-0000-0000-0000-000000000007'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
-- Deux ecritures dans la meme transaction : une seule ligne.
UPDATE public.groupes SET teacher_id = '5a000000-0000-0000-0000-000000000003'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
UPDATE public.groupes SET teacher_id = '5a000000-0000-0000-0000-000000000007'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
DO $remplacement$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM public.notifications
   WHERE destinataire = '5a000000-0000-0000-0000-000000000007'
     AND evenement = 'enseignant_affecte' AND params ->> 'groupe_id' = '5afffff0-0000-0000-0000-0000000000a1';
  IF n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : B est prevenu UNE fois par enseignant_affecte, % trouvee(s)', n;
  END IF;
  IF EXISTS (SELECT 1 FROM public.notifications
              WHERE destinataire = '5a000000-0000-0000-0000-000000000007'
                AND evenement = 'enseignant_change' AND params ->> 'groupe_id' = '5afffff0-0000-0000-0000-0000000000a1') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : B n est pas prevenu en plus par enseignant_change';
  END IF;
  -- (L'ancien enseignant et la famille gardent `enseignant_change` : ce que
  -- notifier_classe fait deja, non rejoue ici. Le scenario tient dans UNE
  -- transaction, ou la deduplication par instant masque la famille, deja
  -- prevenue de l'affectation, et ou le compte de l'ancien enseignant est
  -- efface plus haut.)
  SELECT count(*) INTO n FROM public.courriels_sortants
   WHERE destinataire_profil = '5a000000-0000-0000-0000-000000000007'
     AND modele = 'enseignant_affecte' AND donnees ->> 'groupe_id' = '5afffff0-0000-0000-0000-0000000000a1';
  IF n <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un seul courriel pour B sur cette classe, % trouve(s)', n;
  END IF;
END
$remplacement$;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $carte_b$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer() WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1';
  IF r.enseignant ->> 'prenom' <> 'Khadija' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la carte montre l enseignant en place : %', r.enseignant;
  END IF;
END
$carte_b$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 8 quater bis. « Enseignant affecte » : trois destinataires, trois cas
-- ---------------------------------------------------------------------------
-- Le courriel part pour l'eleve ADULTE (portee « soi »), il est arrete par la
-- garde serveur pour un MINEUR (meme portee « soi », meme evenement), et le
-- TUTEUR du mineur le recoit par la portee « foyer ».
DO $trois_cas$
BEGIN
  -- Les notifications reelles de l'affectation : l'adulte (classe Al-Baqara,
  -- 8 ter), le mineur et son tuteur (classe Al-Fatiha, section 4).
  IF NOT EXISTS (SELECT 1 FROM public.notifications
                  WHERE evenement = 'enseignant_affecte'
                    AND destinataire = '5a000000-0000-0000-0000-000000000006'
                    AND params ->> 'portee' = 'soi')
     OR NOT EXISTS (SELECT 1 FROM public.notifications
                     WHERE evenement = 'enseignant_affecte'
                       AND destinataire = '5a000000-0000-0000-0000-000000000002'
                       AND params ->> 'portee' = 'soi')
     OR NOT EXISTS (SELECT 1 FROM public.notifications
                     WHERE evenement = 'enseignant_affecte'
                       AND destinataire = '5a000000-0000-0000-0000-000000000001'
                       AND params ->> 'portee' = 'foyer') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les notifications d affectation de l adulte, du mineur et du tuteur existent';
  END IF;
  -- Adulte : un courriel, du flux reel.
  IF (SELECT count(*) FROM public.courriels_sortants cs
       WHERE cs.destinataire_profil = '5a000000-0000-0000-0000-000000000006'
         AND cs.modele = 'enseignant_affecte'
         AND cs.cle_idempotence LIKE 'notification:%') <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l eleve adulte recoit UN courriel « enseignant affecte »';
  END IF;
  -- Mineur : aucun, malgre la meme ligne de portee « soi ».
  IF EXISTS (SELECT 1 FROM public.courriels_sortants cs
              WHERE cs.destinataire_profil = '5a000000-0000-0000-0000-000000000002') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le mineur ne recoit aucun courriel';
  END IF;
  -- Tuteur : un courriel par la portee « foyer ».
  IF (SELECT count(*) FROM public.courriels_sortants cs
       WHERE cs.destinataire_profil = '5a000000-0000-0000-0000-000000000001'
         AND cs.modele = 'enseignant_affecte'
         AND cs.donnees ->> 'portee' = 'foyer') <> 1 THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le tuteur du mineur recoit UN courriel « enseignant affecte » par le foyer';
  END IF;
END
$trois_cas$;

-- ---------------------------------------------------------------------------
-- 8 quinquies. « Me presenter » : jamais un mineur pour destinataire (serveur)
-- ---------------------------------------------------------------------------
-- L'enseignant n'ouvre une conversation que sur une paire que le serveur
-- autorise : jamais avec un eleve mineur.
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000007', 'teacher', NULL);
SET LOCAL ROLE authenticated;
DO $me_presenter$
DECLARE r jsonb;
BEGIN
  -- Controle positif : la paire autorisee est celle du FOYER (le tuteur),
  -- jamais celle de l'enfant.
  r := public.com_ouvrir_conversation('classe', '5afffff0-0000-0000-0000-0000000000a1'::uuid,
         '5afffff0-0000-0000-0000-000000000001');
  IF r IS NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l enseignant joint le foyer par la paire du serveur';
  END IF;
  r := public.com_ouvrir_conversation('classe', '5afffff0-0000-0000-0000-0000000000a1'::uuid,
         '5a000000-0000-0000-0000-000000000002');
  IF r IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un enseignant n ouvre aucune conversation avec un eleve mineur : %', r;
  END IF;
  r := public.com_ouvrir_conversation('classe', '5afffff0-0000-0000-0000-0000000000a1'::uuid,
         '5a000000-0000-0000-0000-000000000005');
  IF r IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : ni avec un autre eleve mineur : %', r;
  END IF;
END
$me_presenter$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 8 septies. Enseignant retire apres l'affectation : l'etape 4 n'est plus faite
-- ---------------------------------------------------------------------------
UPDATE public.groupes SET teacher_id = NULL, etat = 'en_attente_enseignant'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $enseignant_retire$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer() WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1';
  IF (SELECT array_agg(e ->> 'statut' ORDER BY (e ->> 'numero')::int)
        FROM jsonb_array_elements(r.etapes) e)
     IS DISTINCT FROM ARRAY['fait', 'fait', 'fait', 'en_cours', 'a_venir'] THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : enseignant retire, l etape 4 n est plus faite : %', r.etapes;
  END IF;
  IF r.cas <> 'en_attente_enseignant' OR r.enseignant IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la classe attend son enseignant, sans carte : % %', r.cas, r.enseignant;
  END IF;
END
$enseignant_retire$;
RESET ROLE;
-- La classe retrouve un enseignant : la suite se rejoue.
UPDATE public.groupes SET teacher_id = '5a000000-0000-0000-0000-000000000007', etat = 'active'
 WHERE id = '5afffff0-0000-0000-0000-0000000000a1';
SET CONSTRAINTS ALL IMMEDIATE;
SET CONSTRAINTS ALL DEFERRED;

-- ---------------------------------------------------------------------------
-- 8 octies. La carte de l'enseignant n'est rendue qu'a un foyer dont la demande
-- vit et dont l'enfant est membre actif de la classe
-- ---------------------------------------------------------------------------
-- Sonde 1 : la demande est retiree, l'enfant est encore membre.
UPDATE public.demandes_horaires_famille
   SET etat = 'retiree', motif = 'retrait_famille'
 WHERE id = '5afffff0-0000-0000-0000-0000000000d1';
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $sonde_retiree$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer() WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1';
  IF r.cas <> 'retiree' OR r.enseignant IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : une demande retiree ne montre aucun enseignant : % %', r.cas, r.enseignant;
  END IF;
END
$sonde_retiree$;
RESET ROLE;
-- Sonde 2 : l'enfant quitte la classe ; la demande retiree, et le remplacant,
-- ne sont plus rendus.
UPDATE public.groupe_membres
   SET left_at = pg_catalog.now(), left_by = '5a000000-0000-0000-0000-000000000001',
       left_reason = 'sortie de test'
 WHERE groupe_id = '5afffff0-0000-0000-0000-0000000000a1' AND student_id = '5a000000-0000-0000-0000-000000000002';
SELECT pg_temp.moi('5a000000-0000-0000-0000-000000000001', 'guardian', '5afffff0-0000-0000-0000-000000000001');
SET LOCAL ROLE authenticated;
DO $sonde_quitte$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM public.suivi_attente_foyer() WHERE demande_id = '5afffff0-0000-0000-0000-0000000000d1';
  IF r.enseignant IS NOT NULL THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un enfant sorti de la classe ne voit pas son enseignant : %', r.enseignant;
  END IF;
  IF (r.etapes -> 4 ->> 'statut') = 'fait' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : l etape 5 n est pas faite pour un enfant sorti de la classe';
  END IF;
END
$sonde_quitte$;
RESET ROLE;

-- ---------------------------------------------------------------------------
-- 9. Droits : fonctions et declencheur
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE s text;
BEGIN
  FOREACH s IN ARRAY ARRAY[
    'public.suivi_attente_foyer()',
    'public.ma_presentation_aux_familles()',
    'public.regler_presentation_aux_familles(boolean,text,text,text)',
    'public.demandes_formation_depassees()'
  ] LOOP
    IF has_function_privilege('anon', s, 'EXECUTE') OR has_function_privilege('public', s, 'EXECUTE')
       OR NOT has_function_privilege('authenticated', s, 'EXECUTE') THEN
      RAISE EXCEPTION 'SUIVI-ATTENTE : droits d execution invalides sur %', s;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'private.suivi_attente_notifier_pret(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'private.suivi_attente_pret_declencheur()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : les fonctions de « tout est pret » ne s appellent pas';
  END IF;
  IF has_function_privilege('authenticated', 'private.suivi_attente_notifier_enseignant()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le declencheur ne s appelle pas';
  END IF;
END
$droits$;

ROLLBACK;
