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
  ('5a000000-0000-0000-0000-000000000007', 'sa-enseignante@example.test');
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
   NULL, 'Khadija', 'Diallo', 'provisional_active', 'female');
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

INSERT INTO public.groupe_membres (groupe_id, student_id)
VALUES ('5afffff0-0000-0000-0000-0000000000a1', '5a000000-0000-0000-0000-000000000002');
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
     OR r.enseignant ->> 'pays_origine' <> 'GN' OR r.enseignant ->> 'pays_residence' <> 'FR'
     OR r.enseignant ->> 'mot' <> 'Je suis heureux de vous retrouver.'
     OR r.enseignant ->> 'teacher_id' <> '5a000000-0000-0000-0000-000000000003' THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : carte de l enseignant inattendue : %', r.enseignant;
  END IF;
  SELECT array_agg(k ORDER BY k) INTO cles FROM jsonb_object_keys(r.enseignant) k;
  IF NOT (cles @> ARRAY['langue_cours', 'mot', 'montre', 'nom', 'pays_origine',
                        'pays_residence', 'prenom', 'teacher_id', 'titre']
          AND cles <@ ARRAY['langue_cours', 'mot', 'montre', 'nom', 'pays_origine',
                            'pays_residence', 'prenom', 'teacher_id', 'titre']) THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : la carte ne porte que ses champs (ni ville, telephone, courriel, naissance, piece) : %', cles;
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
  IF r.enseignant ->> 'prenom' <> 'Ibrahim' OR r.enseignant ->> 'nom' <> 'Camara'
     OR (r.enseignant ->> 'langue_cours') IS NULL
     OR (r.enseignant ->> 'teacher_id') IS NOT NULL
     OR (r.enseignant ->> 'pays_origine') IS NOT NULL
     OR (r.enseignant ->> 'pays_residence') IS NOT NULL
     OR (r.enseignant ->> 'mot') IS NOT NULL
     OR (r.enseignant ->> 'montre')::boolean THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : un enseignant qui refuse ne montre que son nom et la langue : %', r.enseignant;
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
    RAISE EXCEPTION 'SUIVI-ATTENTE : le courriel d affectation doit partir';
  END IF;
END
$notification$;

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
-- 9. Droits : fonctions et declencheur
-- ---------------------------------------------------------------------------
DO $droits$
DECLARE s text;
BEGIN
  FOREACH s IN ARRAY ARRAY[
    'public.suivi_attente_foyer()',
    'public.ma_presentation_aux_familles()',
    'public.regler_presentation_aux_familles(boolean,text,text,text)'
  ] LOOP
    IF has_function_privilege('anon', s, 'EXECUTE') OR has_function_privilege('public', s, 'EXECUTE')
       OR NOT has_function_privilege('authenticated', s, 'EXECUTE') THEN
      RAISE EXCEPTION 'SUIVI-ATTENTE : droits d execution invalides sur %', s;
    END IF;
  END LOOP;
  IF has_function_privilege('authenticated', 'private.suivi_attente_notifier_enseignant()', 'EXECUTE') THEN
    RAISE EXCEPTION 'SUIVI-ATTENTE : le declencheur ne s appelle pas';
  END IF;
END
$droits$;

ROLLBACK;
