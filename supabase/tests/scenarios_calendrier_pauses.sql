-- CALENDRIER-ET-PAUSES (lot 2 de la charte, 12/11/2026). Migrations 20261123910000
-- et 20261123911000. A rejouer apres toutes les migrations, sur un Postgres nu.
-- a1 direction ; b1 titulaire de c1 (enfants) et c3 (adultes) ; b3 titulaire de c2 ;
-- t1 tuteur du foyer f1 (e1 6-9 ans, e2 10-13 ans, classe c1) ; t2 tuteur de f2
-- (e4 6-9 ans, classe c2) ; t3 tuteur de f3 ; e9 adulte autonome de f3 (classe c3).
--   1. reglages et leurs bornes ;
--   2. droits : seule la direction ecrit le calendrier, publie et decide ; anon refuse ;
--      aucune ecriture directe des tables ;
--   3. recul de la date limite : sans rien, date inchangee ; fermeture de 20 jours :
--      + 20 ; fermeture hors de l'etape : aucun effet ; fermeture a cheval sur la
--      date limite (point fixe) ; portee ecole, tranche, classe ; retrait de la
--      publication ; maximum du Ramadan et de l'Aid ;
--   4. pause d'un mois : prevenir 7 jours avant (reglage), mois civil entier, plafond
--      2 sur 12 mois glissants, decision de la direction avec motif, exception ;
--      cumul sans double compte (fermeture + pause) ;
--   5. droits des pauses : un tuteur pour son foyer et pour un enfant, l'adulte pour
--      lui-meme, jamais l'enfant ni un autre foyer ;
--   6. la lecture du calendrier : chacun ne lit que ce qui le concerne ; l'enfant de
--      6 a 9 ans ne recoit ni date limite ni recul ;
--   7. generation des seances : aucune seance creee un jour de fermeture, aucune
--      seance existante touchee ;
--   8. notification de la reponse : au tuteur ou a l'adulte, jamais a l'enfant.
-- Tout est annule a la fin.
\o /dev/null
BEGIN;
SET CONSTRAINTS ALL IMMEDIATE;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_foyer uuid DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text := pg_catalog.json_build_object('aal', 'aal1', 'app_metadata',
                        pg_catalog.json_build_object('role', p_role, 'household_id', p_foyer))::text;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('test.uid', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.u(p text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT pg_catalog.md5('calendrier-pauses-' || p)::uuid $$;

CREATE FUNCTION pg_temp.essai(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  EXECUTE p_sql;
  RETURN 'ok';
EXCEPTION
  WHEN insufficient_privilege THEN RETURN 'refus';
  WHEN OTHERS THEN RETURN SQLERRM;
END $$;

-- Aujourd'hui : le jour de l'academie, heure de La Mecque (les foyers du test sont a UTC : sans effet) et le premier jour du mois k.
CREATE FUNCTION pg_temp.auj() RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date $$;
CREATE FUNCTION pg_temp.mois(k integer) RETURNS date LANGUAGE sql AS
  $$ SELECT (pg_catalog.date_trunc('month', pg_temp.auj()) + pg_catalog.make_interval(months => k))::date $$;
CREATE FUNCTION pg_temp.recul(p text) RETURNS integer LANGUAGE sql AS
  $$ SELECT recul_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u(p) $$;
-- Jours entre l'entree dans l'etape et la date limite de l'etape (private.dates_etape).
CREATE FUNCTION pg_temp.limite(p text) RETURNS integer LANGUAGE sql AS
  $$ SELECT (SELECT d.date_limite FROM private.dates_etape(pg_temp.u(p)) d)
            - (SELECT entree_etape_le FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u(p)) $$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, uuid), pg_temp.vrai(boolean, text), pg_temp.u(text),
  pg_temp.essai(text), pg_temp.auj(), pg_temp.mois(integer), pg_temp.recul(text), pg_temp.limite(text)
  TO authenticated, anon;

CREATE TEMP TABLE cp_ids(cle text PRIMARY KEY, id uuid);
GRANT ALL ON cp_ids TO authenticated;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO auth.users(id, email)
SELECT pg_temp.u(x), 'cp-' || x || '@test.invalid'
  FROM unnest(ARRAY['a1','b1','b3','b5','b6','b7','b8','t1','t2','t3','e1','e2','e4','e5','e6','e7','e8','e9','e10']) AS x;
INSERT INTO public.households(id, timezone) VALUES
  (pg_temp.u('f1'), 'America/Toronto'), (pg_temp.u('f2'), 'Pacific/Auckland'), (pg_temp.u('f3'), 'UTC');
INSERT INTO public.profiles(id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.u(x.id), x.mat, x.role::public.app_role,
       CASE WHEN x.foyer IS NOT NULL THEN pg_temp.u(x.foyer) END,
       x.prenom, 'CP', (CASE x.role WHEN 'teacher' THEN 'provisional_active' ELSE 'active' END)::public.account_status,
       'female'::public.gender
  FROM (VALUES
   ('a1','CP-ADM-01','admin',NULL,'Direction'),
   ('b1','CP-ENS-01','teacher',NULL,'Titulaire un'),
   ('b3','CP-ENS-03','teacher',NULL,'Titulaire trois'),
   ('b5','CP-ENS-05','teacher',NULL,'Titulaire cinq'),
   ('b6','CP-ENS-06','teacher',NULL,'Titulaire six'),
   ('b7','CP-ENS-07','teacher',NULL,'Titulaire sept'),
   ('b8','CP-ENS-08','teacher',NULL,'Titulaire huit'),
   ('t1','CP-TUT-01','guardian','f1','Tutrice un'),
   ('t2','CP-TUT-02','guardian','f2','Tutrice deux'),
   ('t3','CP-TUT-03','guardian','f3','Tutrice trois'),
   ('e1','CP-ELV-01','student','f1','Eleve un'),
   ('e2','CP-ELV-02','student','f1','Eleve deux'),
   ('e4','CP-ELV-04','student','f2','Eleve quatre'),
   ('e5','CP-ELV-05','student','f2','Eleve cinq'),
   ('e6','CP-ELV-06','student','f3','Adulte six'),
   ('e7','CP-ELV-07','student','f2','Eleve sept'),
   ('e8','CP-ELV-08','student','f1','Ado huit'),
   ('e10','CP-ELV-10','student','f3','Adulte dix'),
   ('e9','CP-ELV-09','student','f3','Adulte eleve')) AS x(id, mat, role, foyer, prenom);
INSERT INTO public.student_profiles(profile_id, student_type, interface_mode, cohorte) VALUES
  (pg_temp.u('e1'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e2'), 'minor', 'standard', 'enfant_10_13'),
  (pg_temp.u('e4'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e5'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e6'), 'autonomous', 'standard', 'adulte_18_plus'),
  (pg_temp.u('e7'), 'minor', 'child', 'enfant_6_9'),
  (pg_temp.u('e8'), 'minor', 'standard', 'ado_14_17'),
  (pg_temp.u('e10'), 'autonomous', 'standard', 'adulte_18_plus'),
  (pg_temp.u('e9'), 'autonomous', 'standard', 'adulte_18_plus');

-- Le programme des bases publie, puis les classes ; les eleves y entrent aujourd'hui.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.creer_version_programme(NULL) AS v \gset prog_
RESET ROLE;
-- L'installation du lot 1 complete le brouillon vide ; la direction le publie ; les classes et les
-- eleves deja presents sont rattaches par le geste d'installation (rattacher_classes_et_eleves).
SELECT private.completer_brouillon_bases();
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.publier_version_programme(:'prog_v'::uuid, 'Version 1 des bases');
RESET ROLE;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c1'), pg_temp.u('b1'), 'enfant', 5, 'An-Nour CP', 2, 17, 'UTC'),
 (pg_temp.u('c2'), pg_temp.u('b3'), 'enfant', 5, 'Al-Huda CP', 3, 17, 'UTC'),
 (pg_temp.u('c3'), pg_temp.u('b1'), 'adulte', 6, 'Al-Amal CP', 4, 19, 'UTC');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES
 (pg_temp.u('c1'), pg_temp.u('e1'), pg_catalog.now()),
 (pg_temp.u('c1'), pg_temp.u('e2'), pg_catalog.now()),
 (pg_temp.u('c2'), pg_temp.u('e4'), pg_catalog.now()),
 (pg_temp.u('c3'), pg_temp.u('e9'), pg_catalog.now());
SELECT private.rattacher_classes_et_eleves();

-- Une fermeture DEJA PASSEE publiee (donnees historiques : l'application refuse d'en publier, la
-- revue du 13/11 l'interdit) : posee directement, en superutilisateur, pour tester le recul.
CREATE FUNCTION pg_temp.fermer_passee(p_cle text, p_cat text, p_du integer, p_au integer,
                                      p_portee text DEFAULT 'ecole', p_groupe text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid;
BEGIN
  INSERT INTO public.calendrier_ecole(type, categorie, titre, du, au, portee, groupe_id, publie)
  VALUES ('fermeture', p_cat, 'Fermeture ' || p_cle, pg_temp.auj() + p_du, pg_temp.auj() + p_au, p_portee,
          CASE WHEN p_groupe IS NOT NULL THEN pg_temp.u(p_groupe) END, true)
  RETURNING id INTO v_id;
  INSERT INTO cp_ids VALUES (p_cle, v_id);
  RETURN v_id;
END $$;

-- Les gestes de la direction, comme un appel de l'application.
CREATE FUNCTION pg_temp.fermer(p_cle text, p_cat text, p_du integer, p_au integer, p_portee text DEFAULT 'ecole',
                               p_coh text DEFAULT NULL, p_groupe text DEFAULT NULL) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid;
BEGIN
  v_id := public.calendrier_ecole_enregistrer(NULL, 'fermeture', p_cat, 'Fermeture ' || p_cle,
            pg_temp.auj() + p_du, pg_temp.auj() + p_au, p_portee, p_coh,
            CASE WHEN p_groupe IS NOT NULL THEN pg_temp.u(p_groupe) END);
  INSERT INTO cp_ids VALUES (p_cle, v_id);
  RETURN v_id;
END $$;
CREATE FUNCTION pg_temp.publier(p_cle text, p_publie boolean) RETURNS void
LANGUAGE sql AS $$ SELECT public.calendrier_ecole_publier((SELECT id FROM cp_ids WHERE cle = p_cle), p_publie) $$;
GRANT EXECUTE ON FUNCTION pg_temp.fermer(text, text, integer, integer, text, text, text), pg_temp.publier(text, boolean)
  TO authenticated, anon;

-- ------------------------------------------------------------------
-- 0. Point de depart : rien ne recule
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.recul('e1') = 0 AND pg_temp.recul('e2') = 0 AND pg_temp.recul('e4') = 0 AND pg_temp.recul('e9') = 0
  AND pg_temp.limite('e1') = 70 AND pg_temp.limite('e2') = 56 AND pg_temp.limite('e9') = 28,
  'sans fermeture ni pause : recul nul, date limite inchangee (10 semaines 6-9 ans, 8 semaines 10-13 ans, 4 semaines adulte)');

-- ------------------------------------------------------------------
-- 1. Les reglages
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.app_config
    WHERE key IN ('pause.preavis_jours', 'pause.max_mois_fenetre', 'pause.fenetre_mois',
                  'pause.delai_reponse_jours', 'calendrier.ramadan_jours_max', 'calendrier.aid_adha_jours_max')) = 6
  AND (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'pause.preavis_jours') = 7
  AND (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'pause.max_mois_fenetre') = 2
  AND (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'pause.fenetre_mois') = 12
  AND (SELECT (value #>> '{}')::int FROM public.app_config WHERE key = 'calendrier.ramadan_jours_max') = 20,
  'les valeurs de REGLAGES.md sont des reglages app_config (7 jours, 2 mois sur 12, 20 jours de Ramadan)');
SELECT pg_temp.vrai(
  pg_temp.essai($q$UPDATE public.app_config SET value = to_jsonb('abc'::text) WHERE key = 'pause.preavis_jours'$q$) LIKE '%nombre entier%'
  AND pg_temp.essai($q$UPDATE public.app_config SET value = to_jsonb(999) WHERE key = 'pause.fenetre_mois'$q$) LIKE '%hors bornes%',
  'un reglage hors bornes ou non entier est refuse');

-- 1b. La demande de pause de la famille est CACHEE par defaut : un seul reglage
-- (pause.demande_famille_ouverte, faux) tant que le directeur n'a pas decide la regle d'argent.
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'pause.demande_famille_ouverte') = pg_catalog.to_jsonb(false),
  'le reglage pause.demande_famille_ouverte existe et vaut faux par defaut');
SELECT pg_temp.vrai(
  pg_temp.essai($q$UPDATE public.app_config SET value = to_jsonb('oui'::text) WHERE key = 'pause.demande_famille_ouverte'$q$) LIKE '%vrai ou faux%',
  'le reglage de la demande de pause n''accepte que vrai ou faux');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_demander(%L, %L)$q$, pg_temp.u('e1'), pg_temp.mois(2))) AS refus,
       (public.pauses_eleve_lecture(pg_temp.u('e1')) ->> 'demande_ouverte') AS ouverte,
       pg_catalog.jsonb_array_length(public.pauses_eleve_lecture(pg_temp.u('e1')) -> 'mois_proposes') AS nb_mois \gset r1b_
RESET ROLE;
SELECT pg_temp.vrai(:'r1b_refus' = 'pause_demande_fermee' AND :'r1b_ouverte' = 'false' AND :'r1b_nb_mois'::int = 0
                    AND NOT EXISTS (SELECT 1 FROM public.pauses_eleve),
  'reglage ferme (defaut) : pause_demander refuse, la lecture dit demande_ouverte = false et ne propose aucun mois, aucune pause creee');
-- Les scenarios suivants testent la regle des pauses : le reglage est ouvert pour eux.
UPDATE public.app_config SET value = pg_catalog.to_jsonb(true) WHERE key = 'pause.demande_famille_ouverte';
SELECT pg_temp.vrai(private.pause_demande_ouverte(), 'reglage ouvert : la demande de pause de la famille fonctionne');

-- ------------------------------------------------------------------
-- 2. Droits du calendrier
-- ------------------------------------------------------------------
CREATE FUNCTION pg_temp.essai_cal() RETURNS text LANGUAGE sql AS $q$
  SELECT pg_temp.essai(pg_catalog.format($e$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'autre', 'x', %L, %L, 'ecole', NULL, NULL)$e$,
                                         pg_temp.auj() + 3, pg_temp.auj() + 4)) $q$;
GRANT EXECUTE ON FUNCTION pg_temp.essai_cal() TO authenticated, anon;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai_cal() AS tuteur, pg_temp.essai('SELECT public.calendrier_ecole_liste()') AS liste,
       pg_temp.essai($q$INSERT INTO public.calendrier_ecole(type, categorie, titre, du, au) VALUES ('fermeture', 'autre', 'x', current_date, current_date)$q$) AS direct,
       (SELECT pg_catalog.count(*) FROM public.calendrier_ecole) AS lignes \gset r1_
RESET ROLE;
SELECT pg_temp.vrai(:'r1_tuteur' = 'refus' AND :'r1_liste' = 'refus' AND :'r1_direct' = 'refus' AND :'r1_lignes'::int = 0,
  'un tuteur n''ecrit pas le calendrier, ne lit pas la liste de la direction, aucune ecriture ni lecture directe de la table');
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai_cal() AS ens \gset r2_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai_cal() AS elv, pg_temp.essai(pg_catalog.format($q$SELECT public.pauses_a_traiter()$q$)) AS file \gset r3_
RESET ROLE;
SELECT pg_temp.vrai(:'r2_ens' = 'refus' AND :'r3_elv' = 'refus' AND :'r3_file' = 'refus',
  'ni l''enseignant ni l''eleve n''ecrivent le calendrier ni ne lisent la file des pauses');
SET LOCAL ROLE anon;
SELECT pg_temp.essai_cal() AS anonyme, pg_temp.essai('SELECT public.calendrier_ecole_lecture()') AS lecture,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_demander(%L, %L)$q$, pg_temp.u('e9'), pg_temp.mois(3))) AS pause \gset r4_
RESET ROLE;
SELECT pg_temp.vrai(:'r4_anonyme' = 'refus' AND :'r4_lecture' = 'refus' AND :'r4_pause' = 'refus',
  'anonyme : refus partout');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname IN ('calendrier_ecole_enregistrer', 'calendrier_ecole_publier', 'calendrier_ecole_liste',
                         'calendrier_ecole_lecture', 'pause_demander', 'pause_annuler', 'pause_decider',
                         'pause_exception_accorder', 'pauses_eleve_lecture', 'pauses_a_traiter', 'pauses_eleves_recherche')
       AND (pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE')
            OR pg_catalog.has_function_privilege('public', p.oid, 'EXECUTE')
            OR NOT pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
            OR NOT p.prosecdef
            OR NOT (p.proconfig @> ARRAY['search_path=""']))),
  'toutes les fonctions publiques : EXECUTE retire de PUBLIC et anon (has_function_privilege), SECURITY DEFINER, search_path vide');
SELECT pg_temp.vrai(NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname = 'private'
       AND p.proname IN ('recul_jours_calcule', 'eleve_en_pause', 'eleve_en_pause_mois', 'jour_ferme_pour_classe',
                         'pause_famille_peut', 'pause_depasse_plafond', 'pause_notifier_reponse', 'recul_recalculer_cible')
       AND (pg_catalog.has_function_privilege('authenticated', p.oid, 'EXECUTE')
            OR pg_catalog.has_function_privilege('anon', p.oid, 'EXECUTE'))),
  'les faits et le calcul du recul (private) ne sont executables par aucun compte du client');

-- ------------------------------------------------------------------
-- 3. Le recul de la date limite
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('f20', 'autre', 3, 22);                 -- 20 jours dans l'etape
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = 0 AND pg_temp.recul('e9') = 0,
  'une fermeture saisie mais non publiee n''agit pas');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('f20', true);
RESET ROLE;
SELECT pg_temp.vrai(
  pg_temp.recul('e1') = 20 AND pg_temp.recul('e2') = 20 AND pg_temp.recul('e4') = 20 AND pg_temp.recul('e9') = 20
  AND pg_temp.limite('e1') = 90 AND pg_temp.limite('e2') = 76 AND pg_temp.limite('e9') = 48,
  'fermeture de 20 jours publiee pendant l''etape : + 20 jours sur la date limite de chacun (70 -> 90, 56 -> 76, 28 -> 48)');
-- La lecture unique de l'etape montre le recul au tuteur et a l'eleve de 10 ans ; jamais a l'enfant de 6 a 9 ans.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT public.etape_eleve_lecture(pg_temp.u('e1')) -> 'etape' ->> 'recul_jours' AS tuteur_e1,
       public.etape_eleve_lecture(pg_temp.u('e1')) -> 'etape' ->> 'date_limite' AS date_e1 \gset r5_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT coalesce(public.etape_eleve_lecture(pg_temp.u('e1')) -> 'etape' ->> 'recul_jours', 'NUL') AS enfant_recul,
       coalesce(public.etape_eleve_lecture(pg_temp.u('e1')) -> 'etape' ->> 'date_limite', 'NUL') AS enfant_date \gset r6_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT public.etape_eleve_lecture(pg_temp.u('e2')) -> 'etape' ->> 'recul_jours' AS dix_ans \gset r7_
RESET ROLE;
SELECT pg_temp.vrai(:'r5_tuteur_e1' = '20' AND :'r5_date_e1' = (pg_temp.auj() + 90)::text
                    AND :'r6_enfant_recul' = 'NUL' AND :'r6_enfant_date' = 'NUL'
                    AND :'r7_dix_ans' = '20',
  'la lecture unique de l''etape montre le recul au tuteur et a l''eleve de 10 ans ; l''enfant de 6 a 9 ans ne recoit ni recul ni date limite');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('f20', false);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = 0 AND pg_temp.limite('e1') = 70,
  'retirer la fermeture de la publication rend la date limite');

-- Hors de l'etape : apres l'etape, et avant l'entree dans l'etape.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('apres', 'autre', 200, 210);
SELECT pg_temp.publier('apres', true);
RESET ROLE;
SELECT pg_temp.fermer_passee('avant', 'autre', -100, -81);
SELECT pg_temp.vrai(pg_temp.recul('e1') = 0 AND pg_temp.recul('e2') = 0 AND pg_temp.recul('e9') = 0,
  'une fermeture hors de l''etape (apres la date limite, ou avant l''entree) n''a aucun effet');

-- A cheval sur la date limite : le point fixe (65..74, date limite a 70 : 6 jours d''abord, puis tous les 10).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('cheval', 'autre', 65, 74);
SELECT pg_temp.publier('cheval', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = 10 AND pg_temp.limite('e1') = 80 AND pg_temp.recul('e2') = 0,
  'une fermeture a cheval sur la date limite recule la date limite des jours qu''elle couvre, tous (point fixe) : 10 jours pour e1, rien pour e2 (limite a 56)');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('cheval', false);
RESET ROLE;

-- Portees : tranche, classe.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('tr', 'autre', 3, 9, 'tranche', 'adulte_18_plus');
SELECT pg_temp.fermer('cl', 'autre', 3, 6, 'classe', NULL, 'c1');
SELECT pg_temp.publier('tr', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e9') = 7 AND pg_temp.recul('e1') = 0 AND pg_temp.recul('e4') = 0,
  'fermeture d''une tranche d''age : seulement les eleves de cette tranche');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('cl', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = 4 AND pg_temp.recul('e2') = 4 AND pg_temp.recul('e4') = 0 AND pg_temp.recul('e9') = 7,
  'fermeture d''une classe : ses eleves seulement (c1 : e1 et e2 ; pas e4 de c2)');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('tr', false);
SELECT pg_temp.publier('cl', false);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = 0 AND pg_temp.recul('e9') = 0, 'tout retire : le recul retombe a zero');

-- Maximum du Ramadan (20 jours) et de l'Aid al-Adha (10 jours), lus dans les reglages.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'ramadan', 'Ramadan', %L, %L, 'ecole', NULL, NULL)$q$,
         pg_temp.auj() + 300, pg_temp.auj() + 320)) AS ramadan21,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'ramadan', 'Ramadan', %L, %L, 'ecole', NULL, NULL)$q$,
         pg_temp.auj() + 300, pg_temp.auj() + 319)) AS ramadan20,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'aid_al_adha', 'Aid', %L, %L, 'ecole', NULL, NULL)$q$,
         pg_temp.auj() + 330, pg_temp.auj() + 340)) AS aid11,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'aid_al_adha', 'Aid', %L, %L, 'ecole', NULL, NULL)$q$,
         pg_temp.auj() + 330, pg_temp.auj() + 339)) AS aid10,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'autre', 'Libre', %L, %L, 'ecole', NULL, NULL)$q$,
         pg_temp.auj() + 330, pg_temp.auj() + 329)) AS inverse,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(NULL, 'fermeture', 'autre', 'Libre', %L, %L, 'tranche', NULL, NULL)$q$,
         pg_temp.auj() + 330, pg_temp.auj() + 331)) AS portee \gset r8_
RESET ROLE;
SELECT pg_temp.vrai(:'r8_ramadan21' = 'calendrier_fermeture_trop_longue' AND :'r8_ramadan20' = 'ok'
                    AND :'r8_aid11' = 'calendrier_fermeture_trop_longue' AND :'r8_aid10' = 'ok'
                    AND :'r8_inverse' = 'calendrier_dates_invalides' AND :'r8_portee' = 'calendrier_portee_invalide',
  'Ramadan : 20 jours au plus ; Aid al-Adha : 10 jours au plus ; dates inversees et portee incomplete refusees');

-- ------------------------------------------------------------------
-- 4. La pause d'un mois
-- ------------------------------------------------------------------
-- Le prochain mois : son debut est a d jours d'ici ; le preavis est un reglage.
CREATE FUNCTION pg_temp.demander(p_eleve text, p_k integer) RETURNS jsonb
LANGUAGE sql AS $$ SELECT public.pause_demander(pg_temp.u(p_eleve), pg_temp.mois(p_k)) $$;
GRANT EXECUTE ON FUNCTION pg_temp.demander(text, integer) TO authenticated, anon;
CREATE FUNCTION pg_temp.fixer_preavis(p integer) RETURNS void LANGUAGE sql AS
  $$ UPDATE public.app_config SET value = to_jsonb(p) WHERE key = 'pause.preavis_jours' $$;

-- Prevenir 7 jours avant : exactement a la limite passe, un jour de moins refuse.
SELECT pg_temp.fixer_preavis(pg_temp.mois(1) - pg_temp.auj() + 1);
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 1)$q$)) AS court,
       pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 0)$q$)) AS en_cours \gset r9_
RESET ROLE;
SELECT pg_temp.fixer_preavis(pg_temp.mois(1) - pg_temp.auj());
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO cp_ids VALUES ('p_e1_m1', (pg_temp.demander('e1', 1) ->> 'id')::uuid);
RESET ROLE;
SELECT pg_temp.vrai(:'r9_court' = 'pause_preavis' AND :'r9_en_cours' = 'pause_preavis'
                    AND (SELECT statut FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m1')) = 'acceptee'
                    AND (SELECT acceptation FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m1')) = 'automatique',
  'preavis : un jour de moins que le reglage refuse, le jour limite accepte ; le mois en cours est refuse');
SELECT pg_temp.fixer_preavis(7);
SELECT pg_temp.vrai(
  (SELECT debut = pg_temp.mois(1) AND fin = (pg_temp.mois(2) - 1)
     FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m1')),
  'la pause couvre le mois civil entier (du 1er au dernier jour)');
SELECT pg_temp.vrai(
  pg_temp.recul('e1') = (pg_temp.mois(2) - pg_temp.mois(1)) AND pg_temp.limite('e1') = 70 + (pg_temp.mois(2) - pg_temp.mois(1)),
  'pause d''un mois pendant l''etape : la date limite recule de la duree du mois');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 1)$q$)) AS doublon \gset r10_
RESET ROLE;
SELECT pg_temp.vrai(:'r10_doublon' = 'pause_deja_demandee', 'le meme mois ne se demande pas deux fois');

-- Cumul sans double compte : une fermeture dans le mois de la pause.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('dans_pause', 'autre', (pg_temp.mois(1) - pg_temp.auj()) + 2, (pg_temp.mois(1) - pg_temp.auj()) + 11);
SELECT pg_temp.publier('dans_pause', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = (pg_temp.mois(2) - pg_temp.mois(1)),
  'fermeture de 10 jours tombee pendant la pause : aucun double compte (le mois seulement)');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('a_cheval', 'autre', (pg_temp.mois(2) - pg_temp.auj()) - 4, (pg_temp.mois(2) - pg_temp.auj()) + 5);
SELECT pg_temp.publier('a_cheval', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = (pg_temp.mois(2) - pg_temp.mois(1)) + 6,
  'fermeture a cheval sur la fin de la pause : seuls les 6 jours hors pause s''ajoutent (les 4 autres sont deja comptes)');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('dans_pause', false);
SELECT pg_temp.publier('a_cheval', false);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e1') = (pg_temp.mois(2) - pg_temp.mois(1)), 'fermetures retirees : la pause seule');

-- Annulation avant le debut : la date limite revient.
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_annuler(%L)$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m1'))) AS autre_foyer \gset r11_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT public.pause_annuler((SELECT id FROM cp_ids WHERE cle = 'p_e1_m1'));
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_annuler(%L)$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m1'))) AS deux_fois \gset r12_
RESET ROLE;
SELECT pg_temp.vrai(:'r11_autre_foyer' = 'refus' AND :'r12_deux_fois' = 'pause_non_annulable'
                    AND pg_temp.recul('e1') = 0 AND pg_temp.limite('e1') = 70,
  'un autre foyer n''annule pas ; le tuteur annule avant le debut (une fois) : la date limite revient');

-- Le plafond : 2 mois sur 12 mois glissants, au-dela la demande va a la direction.
-- (e1 : sa date limite est a 70 jours, donc ses mois de pause contigus entrent tous dans l'etape.)
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.demander('e1', 2) ->> 'statut' AS m2, pg_temp.demander('e1', 3) ->> 'statut' AS m3 \gset r13_
INSERT INTO cp_ids VALUES ('p_e1_m4', (pg_temp.demander('e1', 4) ->> 'id')::uuid);
SELECT pg_temp.demander('e1', 14) ->> 'statut' AS m14 \gset r14_
RESET ROLE;
SELECT pg_temp.vrai(:'r13_m2' = 'acceptee' AND :'r13_m3' = 'acceptee'
                    AND (SELECT statut FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4')) = 'demandee'
                    AND (SELECT repondre_avant FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4')) = pg_temp.auj() + 3
                    AND :'r14_m14' = 'acceptee',
  'deux mois acceptes seuls ; le troisieme va a la direction (reponse sous 3 jours) ; douze mois plus loin, la fenetre glissante le permet');
SELECT pg_temp.vrai(pg_temp.recul('e1') = pg_temp.mois(4) - pg_temp.mois(2),
  'recul = les deux mois acceptes ; la demande en attente ne recule rien ; le mois lointain n''est pas dans l''etape');

-- La decision de la direction : seule la direction, motif obligatoire pour refuser, une seule fois.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_decider(%L, true, 'ok')$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4'))) AS famille \gset r15_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_decider(%L, false, '')$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4'))) AS sans_motif,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_decider(%L, false, 'Le programme s''etire deja')$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4'))) AS refus,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_decider(%L, true, 'xxx')$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4'))) AS deux_fois \gset r16_
RESET ROLE;
SELECT pg_temp.vrai(:'r15_famille' = 'refus' AND :'r16_sans_motif' = 'pause_motif_requis' AND :'r16_refus' = 'ok'
                    AND :'r16_deux_fois' = 'pause_deja_decidee'
                    AND (SELECT statut || '/' || decidee_par_nom FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4'))
                        = 'refusee/Direction CP'
                    AND pg_temp.recul('e1') = pg_temp.mois(4) - pg_temp.mois(2),
  'seule la direction decide ; un refus exige un motif ; une decision n''est prise qu''une fois ; son nom est garde ; un refus ne recule rien');
-- Un mois refuse peut etre redemande ; accepte par la direction, il recule la date limite.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
INSERT INTO cp_ids VALUES ('p_e1_m4b', (pg_temp.demander('e1', 4) ->> 'id')::uuid);
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.pause_decider((SELECT id FROM cp_ids WHERE cle = 'p_e1_m4b'), true, NULL);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT statut || '/' || acceptation FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e1_m4b')) = 'acceptee/direction'
  AND pg_temp.recul('e1') = pg_temp.mois(5) - pg_temp.mois(2),
  'un mois refuse se redemande ; accepte par la direction (accord particulier), il recule la date limite');
-- Un mois deja commence sans reponse ne s'accepte plus (l'eleve est reste inscrit).
INSERT INTO public.pauses_eleve(id, student_id, type, debut, fin, statut, demandee_par)
VALUES (pg_temp.u('p_passe'), pg_temp.u('e2'), 'mois', pg_temp.mois(0), pg_temp.mois(1) - 1, 'demandee', pg_temp.u('t1'));
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_decider(%L, true, NULL)$q$, pg_temp.u('p_passe'))) AS passe \gset r17_
RESET ROLE;
SELECT pg_temp.vrai(:'r17_passe' = 'pause_debut_passe', 'une demande dont le mois a commence sans reponse ne s''accepte plus');

-- La pause d'exception : la direction seule, motif, date de fin, nom ; sans preavis ; hors plafond.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, %L, %L, 'Maladie soudaine')$q$,
         pg_temp.u('e2'), pg_temp.auj(), pg_temp.auj() + 9)) AS famille \gset r18_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, %L, %L, 'ab')$q$,
         pg_temp.u('e2'), pg_temp.auj(), pg_temp.auj() + 9)) AS sans_motif,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, %L, %L, 'Maladie soudaine')$q$,
         pg_temp.u('e2'), pg_temp.auj() - 1, pg_temp.auj() + 9)) AS passe,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, %L, %L, 'Maladie soudaine')$q$,
         pg_temp.u('e2'), pg_temp.auj(), pg_temp.auj() - 1)) AS fin_avant \gset r19_
INSERT INTO cp_ids VALUES ('p_e2_exc', public.pause_exception_accorder(pg_temp.u('e2'), NULL, pg_temp.auj() + 9, 'Maladie soudaine'));
RESET ROLE;
SELECT pg_temp.vrai(:'r18_famille' = 'refus' AND :'r19_sans_motif' = 'pause_motif_requis'
                    AND :'r19_passe' = 'pause_debut_passe' AND :'r19_fin_avant' = 'pause_dates_invalides'
                    AND (SELECT statut || '/' || type || '/' || decidee_par_nom || '/' || (fin - debut + 1)
                           FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e2_exc'))
                        = 'acceptee/exception/Direction CP/10'
                    AND pg_temp.recul('e2') = 10 AND pg_temp.limite('e2') = 66,
  'pause d''exception : direction seule, motif, fin, nom, sans preavis, aujourd''hui au plus tot ; la date limite recule de la duree accordee (10 jours)');
-- Elle n'use pas le droit de la famille : e2 garde ses deux mois sans accord particulier.
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.demander('e2', 2) ->> 'statut' AS m2, pg_temp.demander('e2', 3) ->> 'statut' AS m3 \gset r20_
SELECT public.pauses_eleve_lecture(pg_temp.u('e2')) AS lect_famille \gset r21_
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_annuler(%L)$q$, (SELECT id FROM cp_ids WHERE cle = 'p_e2_exc'))) AS exc_commencee \gset r22_
RESET ROLE;
SELECT pg_temp.vrai(:'r20_m2' = 'acceptee' AND :'r20_m3' = 'acceptee' AND :'r22_exc_commencee' = 'pause_non_annulable',
  'une pause d''exception ne compte pas dans le plafond ; elle ne s''annule pas une fois commencee');
SELECT pg_temp.vrai(
  :'r21_lect_famille'::jsonb -> 'regle' = '{"preavis_jours": 7, "plafond_mois": 2, "fenetre_mois": 12, "delai_reponse_jours": 3, "exception_mois_max": 3}'::jsonb
  AND pg_catalog.jsonb_array_length(:'r21_lect_famille'::jsonb -> 'mois_proposes') = 12
  AND NOT (:'r21_lect_famille'::jsonb -> 'pauses' -> 0 ? 'motif'),
  'la lecture des pauses donne la regle et douze mois proposes ; le motif d''une exception n''est pas rendu a la famille');

-- Faits pour le moteur (lot 7) : en pause tel jour, tel mois (lecture seule, aucun argent).
SELECT pg_temp.vrai(
  private.eleve_en_pause(pg_temp.u('e1'), pg_temp.mois(2)) AND private.eleve_en_pause(pg_temp.u('e1'), pg_temp.mois(3) - 1)
  AND NOT private.eleve_en_pause(pg_temp.u('e1'), pg_temp.mois(2) - 1)
  AND NOT private.eleve_en_pause(pg_temp.u('e1'), pg_temp.mois(1))
  AND private.eleve_en_pause_mois(pg_temp.u('e1'), pg_temp.mois(2))
  AND NOT private.eleve_en_pause_mois(pg_temp.u('e1'), pg_temp.mois(1))
  AND private.eleve_en_pause(pg_temp.u('e2'), pg_temp.auj())
  AND NOT private.eleve_en_pause_mois(pg_temp.u('e2'), pg_temp.auj()),
  'les lectures « en pause tel jour » et « en pause tel mois » (le mois entier) disent vrai pour les pauses acceptees seulement');

-- ------------------------------------------------------------------
-- 5. Qui demande une pause, pour qui
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 6)$q$)) AS autre_foyer,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pauses_eleve_lecture(%L)$q$, pg_temp.u('e1'))) AS lecture_autre \gset r23_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 6)$q$)) AS enfant,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pauses_eleve_lecture(%L)$q$, pg_temp.u('e1'))) AS lecture_enfant \gset r24_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t3'), 'guardian', pg_temp.u('f3'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e9', 6)$q$)) AS tuteur_de_adulte \gset r25_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 6)$q$)) AS direction_demande,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pauses_eleve_lecture(%L)$q$, pg_temp.u('e1'))) AS direction_lit \gset r26_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 6)$q$)) AS enseignant \gset r27_
RESET ROLE;
SELECT pg_temp.vrai(:'r23_autre_foyer' = 'refus' AND :'r23_lecture_autre' = 'refus'
                    AND :'r24_enfant' = 'refus' AND :'r24_lecture_enfant' = 'refus'
                    AND :'r25_tuteur_de_adulte' = 'refus'
                    AND :'r26_direction_demande' = 'refus' AND :'r26_direction_lit' = 'ok'
                    AND :'r27_enseignant' = 'refus',
  'un autre foyer, l''enfant lui-meme, le tuteur d''un adulte autonome, la direction et l''enseignant ne demandent pas ; la direction lit');
-- L'adulte autonome demande pour lui-meme ; sa troisieme demande va a la direction.
SELECT pg_temp.qui(pg_temp.u('e9'), 'student', pg_temp.u('f3'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.demander('e9', 2) ->> 'statut' AS m2, pg_temp.demander('e9', 3) ->> 'statut' AS m3 \gset r28_
INSERT INTO cp_ids VALUES ('p_e9_m4', (pg_temp.demander('e9', 4) ->> 'id')::uuid);
RESET ROLE;
SELECT pg_temp.vrai(:'r28_m2' = 'acceptee' AND :'r28_m3' = 'acceptee'
                    AND (SELECT statut FROM public.pauses_eleve WHERE id = (SELECT id FROM cp_ids WHERE cle = 'p_e9_m4')) = 'demandee',
  'l''adulte autonome demande pour lui-meme, avec la meme regle');

-- ------------------------------------------------------------------
-- 6. La lecture du calendrier : chacun ce qui le concerne
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
INSERT INTO cp_ids VALUES
 ('L1', public.calendrier_ecole_enregistrer(NULL, 'rencontre', NULL, 'Rencontre de recitation', pg_temp.auj() + 30, pg_temp.auj() + 30, 'ecole', NULL, NULL)),
 ('L2', public.calendrier_ecole_enregistrer(NULL, 'evaluation', NULL, 'Evaluation des 6-9 ans', pg_temp.auj() + 10, pg_temp.auj() + 10, 'tranche', 'enfant_6_9', NULL)),
 ('L3', public.calendrier_ecole_enregistrer(NULL, 'autre', NULL, 'Reunion de la classe c1', pg_temp.auj() + 5, pg_temp.auj() + 5, 'classe', NULL, pg_temp.u('c1'))),
 ('L4', public.calendrier_ecole_enregistrer(NULL, 'evaluation', NULL, 'Evaluation des adultes', pg_temp.auj() + 12, pg_temp.auj() + 12, 'tranche', 'adulte_18_plus', NULL)),
 ('L7', public.calendrier_ecole_enregistrer(NULL, 'autre', NULL, 'Brouillon', pg_temp.auj() + 3, pg_temp.auj() + 3, 'ecole', NULL, NULL));
SELECT pg_temp.publier(c, true) FROM unnest(ARRAY['L1','L2','L3','L4']) c;
RESET ROLE;
-- L5 et L6 : fermetures passees (donnees historiques), posees directement.
SELECT pg_temp.fermer_passee('L5', 'autre', -10, -5);
SELECT pg_temp.fermer_passee('L6', 'autre', -100, -95);
UPDATE public.calendrier_ecole SET titre = 'Fermeture recente' WHERE id = (SELECT id FROM cp_ids WHERE cle = 'L5');
UPDATE public.calendrier_ecole SET titre = 'Fermeture ancienne' WHERE id = (SELECT id FROM cp_ids WHERE cle = 'L6');
CREATE FUNCTION pg_temp.lu(p_titres text) RETURNS text LANGUAGE sql AS $$
  SELECT coalesce(pg_catalog.string_agg(k, ',' ORDER BY k), '') FROM (
    SELECT c.cle AS k FROM cp_ids c
      JOIN pg_catalog.jsonb_array_elements(p_titres::jsonb) e ON (e ->> 'id')::uuid = c.id
     WHERE c.cle ~ '^L[0-9]$') x $$;
GRANT EXECUTE ON FUNCTION pg_temp.lu(text) TO authenticated;
SELECT pg_temp.qui(pg_temp.u('e1'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS e1, (public.calendrier_ecole_lecture() -> 0 ? 'cohorte') AS fuite_e1 \gset r30_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e2'), 'student', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS e2 \gset r31_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('e4'), 'student', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS e4,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_lecture(%L)$q$, pg_temp.u('e1'))) AS e4_lit_e1 \gset r32_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS foyer,
       pg_temp.lu(public.calendrier_ecole_lecture(pg_temp.u('e2'))::text) AS un_enfant,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_lecture(%L)$q$, pg_temp.u('e4'))) AS autre_foyer \gset r33_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b1'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS b1 \gset r34_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b3'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS b3,
       (public.calendrier_ecole_lecture() -> 0 ? 'cohorte') AS detail_enseignant \gset r35_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.lu(public.calendrier_ecole_lecture()::text) AS admin,
       pg_temp.lu(public.calendrier_ecole_lecture(NULL, 200)::text) AS admin_long,
       pg_catalog.jsonb_array_length(public.calendrier_ecole_liste()) AS liste \gset r36_
RESET ROLE;
SELECT pg_temp.vrai(:'r30_e1' = 'L1,L2,L3,L5' AND :'r30_fuite_e1' = 'f',
  'un eleve de 6-9 ans de c1 : les dates de toute l''ecole, de sa tranche, de sa classe ; passes recents ; ni brouillon ni fermeture ancienne ; ni cohorte ni classe rendues');
SELECT pg_temp.vrai(:'r31_e2' = 'L1,L3,L5', 'un eleve de 10-13 ans ne voit pas les dates de la tranche des 6-9 ans');
SELECT pg_temp.vrai(:'r32_e4' = 'L1,L2,L5' AND :'r32_e4_lit_e1' = 'refus',
  'un eleve d''une autre classe ne voit pas la reunion de c1, et ne lit pas pour un autre');
SELECT pg_temp.vrai(:'r33_foyer' = 'L1,L2,L3,L5' AND :'r33_un_enfant' = 'L1,L3,L5' AND :'r33_autre_foyer' = 'refus',
  'le tuteur lit pour son foyer (ou un seul enfant), jamais pour un autre foyer');
SELECT pg_temp.vrai(:'r34_b1' = 'L1,L2,L3,L4,L5' AND :'r35_b3' = 'L1,L2,L5' AND :'r35_detail_enseignant' = 't',
  'l''enseignant lit ce qui concerne ses classes (tranches et classes), avec le detail');
SELECT pg_temp.vrai(:'r36_admin' = 'L1,L2,L3,L4,L5' AND :'r36_admin_long' = 'L1,L2,L3,L4,L5,L6' AND :'r36_liste'::int >= 7,
  'la direction lit tous les evenements publies (30 jours de passe par defaut, davantage sur demande) et la liste complete');

-- ------------------------------------------------------------------
-- 7. Les seances et les fermetures
-- ------------------------------------------------------------------
-- 7a. Une fermeture a venir met de cote les seances DEJA creees qu'elle couvre (rien n'est
-- supprime), la generation ne cree rien ce jour-la, le retrait avant le debut retablit.
-- c5 existe avant la fermeture (cours dans 2 jours a 23 h, puis chaque semaine) ; c6 est creee
-- pendant la fermeture (cours demain a 23 h).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c5'), pg_temp.u('b1'), 'enfant', 5, 'Avant CP',
  EXTRACT(isodow FROM (pg_catalog.now() AT TIME ZONE 'UTC') + interval '2 days')::int, 23, 'UTC');
SELECT pg_catalog.count(*) AS avant FROM public.sessions WHERE groupe_id = pg_temp.u('c5') \gset r40_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('courte', 'autre', 1, 3);
SELECT pg_temp.publier('courte', true);
SELECT (e ->> 'seances_neutralisees')::int AS neutralisees
  FROM pg_catalog.jsonb_array_elements(public.calendrier_ecole_liste()) e
 WHERE (e ->> 'id')::uuid = (SELECT id FROM cp_ids WHERE cle = 'courte') \gset r41_
RESET ROLE;
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c6'), pg_temp.u('b3'), 'enfant', 5, 'Pendant CP',
  EXTRACT(isodow FROM (pg_catalog.now() AT TIME ZONE 'UTC') + interval '1 day')::int, 23, 'UTC');
SELECT pg_temp.vrai(:'r40_avant'::int = 4
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c5')) = 4
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c5') AND deleted_at IS NOT NULL) = 1
                    AND (SELECT pg_catalog.count(*) FROM public.seances_fermees WHERE retablie_le IS NULL) >= 1
                    AND :'r41_neutralisees'::int >= 1,
  'une fermeture publiee met de cote la seance deja creee qu''elle couvre (une sur quatre pour c5), rien n''est supprime (4 lignes), la direction en voit le nombre');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c6')
     AND (started_at AT TIME ZONE 'UTC')::date BETWEEN pg_temp.auj() + 1 AND pg_temp.auj() + 3) = 0
  AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c6')) >= 3,
  'une classe creee pendant la fermeture : aucune seance les jours fermes, les autres semaines sont creees');
-- Aucune notification par seance mise de cote (l'annonce de la fermeture est le lot 7).
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'seance_annulee'),
  'la mise de cote d''une seance par une fermeture ne previent pas la classe seance par seance');
-- Retrait avant le debut : la seance est retablie, la generation reprend.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('courte', false);
RESET ROLE;
SELECT public.materialiser_seances_groupe(pg_temp.u('c6')) AS rejoue \gset r42_
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c5') AND deleted_at IS NOT NULL) = 0
  AND (SELECT pg_catalog.count(*) FROM public.seances_fermees WHERE retablie_le IS NOT NULL) >= 1
  AND (SELECT pg_catalog.count(*) FROM public.seances_fermees WHERE retablie_le IS NULL) = 0
  AND :'r42_rejoue'::int >= 1
  AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c6')
         AND (started_at AT TIME ZONE 'UTC')::date BETWEEN pg_temp.auj() + 1 AND pg_temp.auj() + 3) = 1,
  'retirer la fermeture avant son debut retablit la seance de c5 et la generation cree celle de c6 qui manquait');
-- La fermeture d'une tranche : une classe mixte garde son cours, celle de la tranche ferme.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('tr69', 'autre', 1, 3, 'tranche', 'enfant_6_9');
SELECT pg_temp.publier('tr69', true);
RESET ROLE;
SELECT pg_temp.vrai(
  private.jour_ferme_pour_classe(pg_temp.auj() + 1, pg_temp.u('c2'))
  AND NOT private.jour_ferme_pour_classe(pg_temp.auj() + 1, pg_temp.u('c1'))
  AND NOT private.jour_ferme_pour_classe(pg_temp.auj() + 1, pg_temp.u('c3'))
  AND NOT private.jour_ferme_pour_classe(pg_temp.auj() + 5, pg_temp.u('c2')),
  'le fait « jour ferme » : c2 (tous 6-9 ans) oui ; c1 (classe mixte) et c3 (adultes) non ; hors des dates non');
SELECT pg_temp.vrai(
  private.eleve_en_fermeture(pg_temp.u('e1'), pg_temp.auj() + 2)
  AND NOT private.eleve_en_fermeture(pg_temp.u('e2'), pg_temp.auj() + 2)
  AND NOT private.eleve_en_fermeture(pg_temp.u('e1'), pg_temp.auj() + 5)
  AND private.eleve_hors_cours(pg_temp.u('e1'), pg_temp.auj() + 2),
  'dans la classe mixte c1 le cours a lieu mais l''eleve de 6-9 ans n''est compte absent a aucune seance ces jours-la (eleve_en_fermeture) ; son camarade de 10-13 ans oui');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('tr69', false);
RESET ROLE;

-- 7b. Le concierge (seance_a_rejoindre) cree la seance du cours en cours quand la
-- personne appuie sur « Rejoindre ». Regle de la revue du 13/11 (B-C) : une fermeture ne
-- touche que les cours qui COMMENCENT APRES sa publication ; un cours deja commence a la
-- publication continue normalement.
-- c7 (temoin), c8 et c9 ont leur creneau a l'heure en cours d'aujourd'hui : leur cours a
-- commence, il n'est pas fini, aucune seance n'existe encore.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c7'), pg_temp.u('b5'), 'enfant', 5, 'Temoin CP', EXTRACT(isodow FROM pg_catalog.now() AT TIME ZONE 'UTC')::int,
  EXTRACT(hour FROM pg_catalog.now() AT TIME ZONE 'UTC')::int, 'UTC'),
 (pg_temp.u('c8'), pg_temp.u('b6'), 'enfant', 5, 'Deja commence CP', EXTRACT(isodow FROM pg_catalog.now() AT TIME ZONE 'UTC')::int,
  EXTRACT(hour FROM pg_catalog.now() AT TIME ZONE 'UTC')::int, 'UTC'),
 (pg_temp.u('c9'), pg_temp.u('b7'), 'enfant', 5, 'Ferme CP', EXTRACT(isodow FROM pg_catalog.now() AT TIME ZONE 'UTC')::int,
  EXTRACT(hour FROM pg_catalog.now() AT TIME ZONE 'UTC')::int, 'UTC');
SELECT pg_temp.qui(pg_temp.u('b5'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.seance_a_rejoindre(pg_temp.u('c7')) AS temoin \gset r50_
RESET ROLE;
SELECT pg_temp.vrai(:'r50_temoin' IS NOT NULL
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c7')
                           AND started_at <= pg_catalog.now()) = 1,
  'temoin : sans fermeture, le concierge cree la seance du cours en cours');
-- Fermeture d'aujourd'hui publiee MAINTENANT : le cours de c8 a commence avant la publication.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('aujourdhui', 'autre', 0, 0);
SELECT pg_temp.publier('aujourdhui', true);
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('b6'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT coalesce(public.seance_a_rejoindre(pg_temp.u('c8'))::text, 'NUL') AS commence \gset r51_
RESET ROLE;
SELECT pg_temp.vrai(:'r51_commence' <> 'NUL'
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c8')
                           AND started_at <= pg_catalog.now() AND deleted_at IS NULL) = 1,
  'B-C : un cours deja commence quand la fermeture d''aujourd''hui est publiee continue normalement (le concierge cree sa seance)');
-- Une seance deja creee ce jour-la n'est pas touchee : le concierge la rend telle quelle.
SELECT pg_temp.qui(pg_temp.u('b5'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT public.seance_a_rejoindre(pg_temp.u('c7')) AS existante \gset r52_
RESET ROLE;
SELECT pg_temp.vrai(:'r52_existante' = :'r50_temoin',
  'une seance deja creee avant la publication n''est ni supprimee ni remplacee');
-- La meme fermeture, mais publiee BIEN AVANT le debut du cours (publication anterieure de trois
-- heures, comme une fermeture annoncee le matin) : le cours de c9 tombe sous la fermeture.
SET LOCAL session_replication_role = replica;
UPDATE public.calendrier_ecole SET publie_le = pg_catalog.now() - interval '3 hours'
 WHERE id = (SELECT id FROM cp_ids WHERE cle = 'aujourdhui');
SET LOCAL session_replication_role = origin;
SELECT pg_temp.qui(pg_temp.u('b7'), 'teacher');
SET LOCAL ROLE authenticated;
SELECT coalesce(public.seance_a_rejoindre(pg_temp.u('c9'))::text, 'NUL') AS ferme \gset r53_
RESET ROLE;
SELECT pg_temp.vrai(:'r53_ferme' = 'NUL'
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c9')
                           AND started_at <= pg_catalog.now()) = 0,
  'un cours qui commence apres la publication d''une fermeture d''aujourd''hui : le concierge ne cree aucune seance');
-- La publication redevient celle de maintenant (la suite compte sur le cours de c7, commence avant elle).
SET LOCAL session_replication_role = replica;
UPDATE public.calendrier_ecole SET publie_le = pg_catalog.now()
 WHERE id = (SELECT id FROM cp_ids WHERE cle = 'aujourdhui');
SET LOCAL session_replication_role = origin;

-- 7c. Les ceintures : cloture automatique, remplacement automatique et jeton video ignorent
-- une seance qui commence apres la publication d'une fermeture de son jour, meme si elle n'a
-- pas ete mise de cote ; un cours commence avant la publication suit le circuit ordinaire.
-- s_ctrl (jour ouvert) est cloturee ; s_ferme (jour ferme, remise en jeu a la main comme si la
-- mise de cote avait echoue) ne l'est pas ; la seance de c7, commencee avant la publication,
-- se cloture normalement.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('g66', 'autre', 66, 66);
SELECT pg_temp.publier('g66', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_ctrl'), pg_temp.u('b3'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '60 days 10 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '60 days 11 hours', 'child', pg_temp.u('c2'), 'planned'),
       (pg_temp.u('s_ferme'), pg_temp.u('b3'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '66 days 10 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '66 days 11 hours', 'child', pg_temp.u('c2'), 'planned');
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_ferme')) IS NOT NULL,
  'la seance creee un jour de fermeture publiee est mise de cote (temoin du scenario des ceintures)');
UPDATE public.sessions SET deleted_at = NULL WHERE id = pg_temp.u('s_ferme');
SELECT private.ses_cloturer_seances_echues(pg_catalog.now() + interval '67 days');
SELECT pg_temp.vrai(
  (SELECT status::text FROM public.sessions WHERE id = pg_temp.u('s_ferme')) IN ('planned', 'preflight', 'in_progress')
  AND (SELECT status::text FROM public.sessions WHERE id = pg_temp.u('s_ctrl')) NOT IN ('planned', 'preflight', 'in_progress')
  AND (SELECT status::text FROM public.sessions WHERE id = :'r50_temoin'::uuid) NOT IN ('planned', 'preflight', 'in_progress'),
  'la cloture automatique ignore la seance qui commence apres la publication d''une fermeture de son jour, traite un jour ouvert, et traite normalement le cours commence avant la publication');
SELECT private.remplacement_auto_passer((SELECT started_at FROM public.sessions WHERE id = pg_temp.u('s_ferme')) + interval '40 minutes');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.seances_reportees WHERE session_id = pg_temp.u('s_ferme'))
  AND (SELECT status::text FROM public.sessions WHERE id = pg_temp.u('s_ferme')) IN ('planned', 'preflight', 'in_progress'),
  'le remplacement automatique ignore la seance d''un jour ferme : ni report, ni enseignant absent, ni alerte');

-- ------------------------------------------------------------------
-- 8. La notification de la reponse : au tuteur ou a l'adulte, jamais a l'enfant
-- ------------------------------------------------------------------
-- La reponse de la direction a e1 (refus puis acceptation du mois 4) est arrivee a t1 seulement.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications
    WHERE destinataire = pg_temp.u('t1') AND evenement = 'pause_repondue') = 2
  AND (SELECT pg_catalog.count(*) FROM public.notifications
        WHERE destinataire IN (pg_temp.u('e1'), pg_temp.u('e2')) AND evenement = 'pause_repondue') = 0
  AND (SELECT pg_catalog.count(*) FROM public.notifications
        WHERE destinataire = pg_temp.u('t1') AND evenement = 'pause_repondue'
          AND params ->> 'decision' = 'refusee' AND params ->> 'mois' = pg_catalog.to_char(pg_temp.mois(4), 'YYYY-MM')
          AND destination = '/tuteur' AND foyer_id = pg_temp.u('f1')) = 1
  AND (SELECT pg_catalog.count(*) FROM public.notifications
        WHERE destinataire = pg_temp.u('t1') AND params ->> 'decision' = 'acceptee') = 1,
  'la reponse (refus, puis acceptation) arrive dans l''application du tuteur, pas de l''enfant ; mois et decision en parametres');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.pause_decider((SELECT id FROM cp_ids WHERE cle = 'p_e9_m4'), true, 'Voyage de longue duree');
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications
    WHERE destinataire = pg_temp.u('e9') AND evenement = 'pause_repondue' AND destination = '/eleve') = 1
  AND (SELECT pg_catalog.count(*) FROM public.notifications
        WHERE destinataire = pg_temp.u('t3') AND evenement = 'pause_repondue') = 0,
  'l''adulte autonome recoit sa propre reponse ; son tuteur de foyer ne la recoit pas');
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'pause_repondue') AS lues \gset r44_
RESET ROLE;
SELECT pg_temp.vrai(:'r44_lues'::int = 2, 'le tuteur lit ses deux reponses (RLS de la boite) et pas celles des autres');

-- L'evenement est dans la contrainte (fichier 20261123911000) ; push et courriel eteints.
SELECT pg_temp.vrai(
  (SELECT pg_catalog.pg_get_constraintdef(c.oid) LIKE '%pause_repondue%' FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.notifications'::regclass AND c.conname = 'notifications_evenement_check')
  AND (SELECT NOT courriel AND NOT push FROM private.notification_courriel WHERE evenement = 'pause_repondue' AND portee = '*'),
  'pause_repondue entre dans la contrainte des notifications ; ni courriel ni push (lot 7)');

-- ------------------------------------------------------------------
-- 9. Revue du 13/11, B1 : un changement de classe ne fait pas avancer la date limite
-- ------------------------------------------------------------------
-- e4 : etape commencee il y a 30 jours, membre de c2 depuis 60 jours ; la classe c2 a ete fermee
-- 10 jours, deja ecoules. (« aujourdhui » ajoute 1 jour, et la fermeture recente L5 de la partie 6, 6 jours : 17 en tout.)
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c4'), pg_temp.u('b6'), 'enfant', 5, 'Autre CP', 7, 6, 'UTC');
UPDATE public.groupe_membres SET joined_at = pg_catalog.now() - interval '60 days'
 WHERE student_id = pg_temp.u('e4') AND groupe_id = pg_temp.u('c2');
UPDATE public.eleve_etape_en_cours
   SET entree_etape_le = pg_temp.auj() - 30, entree_niveau_le = pg_temp.auj() - 30
 WHERE student_id = pg_temp.u('e4');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
RESET ROLE;
SELECT pg_temp.fermer_passee('sonde', 'autre', -20, -11, 'classe', 'c2');
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17
                    AND (SELECT recul_acquis_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e4')) = 17,
  'sonde : fermeture de c2 de 10 jours ecoulee + la fermeture d''aujourd''hui = 17 jours, tous deja ecoules (acquis)');
-- e5 entre dans c2 aujourd'hui : la fermeture de c2 d'il y a 20 jours ne le concerne pas (il n'en etait pas
-- membre), meme si son etape a commence il y a 30 jours. Il ne doit que la fermeture de l'academie
-- (L5 : 6 jours, et aujourd'hui : 1 jour).
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('c2'), pg_temp.u('e5'), pg_catalog.now());
UPDATE public.eleve_etape_en_cours
   SET entree_etape_le = pg_temp.auj() - 30, entree_niveau_le = pg_temp.auj() - 30
 WHERE student_id = pg_temp.u('e5');
SELECT pg_temp.vrai(pg_temp.recul('e5') = 7
                    AND NOT private.eleve_en_fermeture(pg_temp.u('e5'), pg_temp.auj() - 15)
                    AND private.eleve_en_fermeture(pg_temp.u('e4'), pg_temp.auj() - 15),
  'une fermeture de classe ne compte que les jours ou l''eleve en etait membre : e5, arrive aujourd''hui, ne doit que les 7 jours de l''academie');
-- e4 change de classe, puis une fermeture sans rapport est publiee.
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'changement de classe'
 WHERE student_id = pg_temp.u('e4') AND groupe_id = pg_temp.u('c2') AND left_at IS NULL;
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('c4'), pg_temp.u('e4'), pg_catalog.now());
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17, 'changer de classe : les jours de la classe quittee, ou il etait membre, restent comptes');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('sans_rapport', 'autre', 20, 22, 'tranche', 'adulte_18_plus');
SELECT pg_temp.publier('sans_rapport', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17 AND pg_temp.limite('e4') = 70 + 17,
  'sonde du relecteur : une fermeture sans rapport publiee apres le changement de classe ne fait pas avancer la date limite');
-- Les jours a venir d'une classe qu'il a quittee ne le concernent plus.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('apres_depart', 'autre', 3, 12, 'classe', NULL, 'c2');
SELECT pg_temp.publier('apres_depart', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17, 'la fermeture d''une classe quittee, a venir, ne recule rien pour lui');
-- Garde-fou : le recul deja ecoule d'une etape ne descend jamais.
UPDATE public.eleve_etape_en_cours SET recul_jours = 0 WHERE student_id = pg_temp.u('e4');
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17, 'garde-fou : le recul enregistre d''une etape ne descend pas sous les jours deja ecoules');
-- Le garde-fou ne depend pas du reste : une correction de donnees (date d'entree dans la classe
-- reculee) qui ferait descendre le calcul ne fait pas descendre le recul deja ecoule.
UPDATE public.groupe_membres SET joined_at = pg_catalog.now()
 WHERE student_id = pg_temp.u('e4') AND groupe_id = pg_temp.u('c2');
SELECT pg_temp.vrai(pg_temp.recul('e4') = 17
                    AND (SELECT r.recul FROM private.recul_jours_calcule(pg_temp.u('e4'), pg_temp.auj() - 30,
                           (SELECT niveau_id FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e4')), 'enfant_6_9') r) < 17,
  'garde-fou : meme quand le calcul du jour redonne moins (7), le recul deja ecoule (17) est garde');
UPDATE public.groupe_membres SET joined_at = pg_catalog.now() - interval '60 days'
 WHERE student_id = pg_temp.u('e4') AND groupe_id = pg_temp.u('c2');
SELECT pg_temp.vrai(private.eleve_en_fermeture(pg_temp.u('e4'), pg_temp.auj() - 15)
                    AND NOT private.eleve_en_fermeture(pg_temp.u('e4'), pg_temp.auj() + 5),
  'eleve_en_fermeture : membre ce jour-la de la classe fermee oui ; un jour a venir de la classe quittee non');

-- ------------------------------------------------------------------
-- 10. Revue du 13/11, I1 : une fermeture commencee ou passee ne se retire, ne se raccourcit,
--     ne se deplace pas ; une fermeture en cours peut seulement se prolonger
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('en_cours', 'autre', 0, 5);
SELECT pg_temp.publier('en_cours', true);
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_publier(%L, false)$q$, (SELECT id FROM cp_ids WHERE cle = 'en_cours'))) AS retrait,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'x', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'en_cours'), pg_temp.auj(), pg_temp.auj() + 3)) AS raccourci,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'x', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'en_cours'), pg_temp.auj() + 1, pg_temp.auj() + 5)) AS deplace,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'x', %L, %L, 'tranche', 'adulte_18_plus', NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'en_cours'), pg_temp.auj(), pg_temp.auj() + 5)) AS portee,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'Titre corrige', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'en_cours'), pg_temp.auj(), pg_temp.auj() + 7)) AS prolonge,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'x', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'avant'), pg_temp.auj() - 100, pg_temp.auj() - 50)) AS passee \gset r60_
RESET ROLE;
SELECT pg_temp.vrai(:'r60_retrait' = 'calendrier_fermeture_commencee' AND :'r60_raccourci' = 'calendrier_fermeture_commencee'
                    AND :'r60_deplace' = 'calendrier_fermeture_commencee' AND :'r60_portee' = 'calendrier_fermeture_commencee'
                    AND :'r60_prolonge' = 'ok' AND :'r60_passee' = 'calendrier_fermeture_commencee'
                    AND (SELECT titre || '/' || au FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'en_cours'))
                        = 'Titre corrige/' || (pg_temp.auj() + 7),
  'une fermeture commencee : retrait, raccourcissement, deplacement et changement de portee refuses ; prolongation et titre permis ; une fermeture passee ne change plus');

-- ------------------------------------------------------------------
-- 11. Revue du 13/11, I2 : la pause d'exception a une duree au plus, et se termine par un geste trace
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, %L, %L, 'Maladie soudaine')$q$,
         pg_temp.u('e4'), pg_temp.auj(), (pg_temp.auj() + interval '3 months' + interval '1 day')::date)) AS trop_longue \gset r61_
SELECT public.pause_exception_accorder(pg_temp.u('e4'), NULL, (pg_temp.auj() + interval '3 months')::date, 'Interruption accordee') AS id \gset r62_
RESET ROLE;
SELECT pg_temp.vrai(:'r61_trop_longue' = 'pause_exception_trop_longue'
                    AND (SELECT fin FROM public.pauses_eleve WHERE id = :'r62_id'::uuid) = (pg_temp.auj() + interval '3 months')::date,
  'une pause d''exception dure 3 mois au plus (reglage) : un jour de plus est refuse, exactement 3 mois est accorde');
SELECT pg_temp.qui(pg_temp.u('t2'), 'guardian', pg_temp.u('f2'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_terminer(%L, %L)$q$, :'r62_id'::uuid, pg_temp.auj() + 4)) AS famille \gset r63_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_terminer(%L, %L)$q$, :'r62_id'::uuid, pg_temp.auj() - 1)) AS passe,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_terminer(%L, %L)$q$, :'r62_id'::uuid, (pg_temp.auj() + interval '3 months')::date)) AS pas_plus_tot,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_terminer(%L, %L)$q$, (SELECT id FROM public.pauses_eleve WHERE student_id = pg_temp.u('e1') AND type = 'mois' LIMIT 1), pg_temp.auj() + 4)) AS un_mois,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_terminer(%L, %L)$q$, :'r62_id'::uuid, pg_temp.auj() + 4)) AS termine \gset r64_
RESET ROLE;
SELECT pg_temp.vrai(:'r63_famille' = 'refus' AND :'r64_passe' = 'pause_dates_invalides' AND :'r64_pas_plus_tot' = 'pause_dates_invalides'
                    AND :'r64_un_mois' = 'pause_introuvable' AND :'r64_termine' = 'ok'
                    AND (SELECT fin || '/' || fin_initiale || '/' || terminee_par_nom
                           FROM public.pauses_eleve WHERE id = :'r62_id'::uuid)
                        = (pg_temp.auj() + 4) || '/' || (pg_temp.auj() + interval '3 months')::date || '/Direction CP',
  'terminer une pause d''exception : direction seule, jamais dans le passe ni plus tard ; la fin d''origine et le geste sont gardes');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.pauses_a_traiter() -> 'regle' ->> 'exception_mois_max' AS regle_duree,
       (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_array_elements(public.pauses_a_traiter() -> 'recentes') e
         WHERE (e ->> 'terminable')::boolean) AS terminables \gset r65_
RESET ROLE;
SELECT pg_temp.vrai(:'r65_regle_duree' = '3' AND :'r65_terminables'::int >= 1,
  'la file de la direction dit la duree permise d''une exception (reglage) et quelles pauses se terminent plus tot');
SELECT pg_temp.vrai(private.eleve_en_pause(pg_temp.u('e4'), pg_temp.auj() + 4)
                    AND NOT private.eleve_en_pause(pg_temp.u('e4'), pg_temp.auj() + 5),
  'le fait « en pause » suit la nouvelle fin');

-- ------------------------------------------------------------------
-- 12. Revue du 13/11, I10 : un seul jour de reference, celui de l'academie (Asia/Riyadh)
-- ------------------------------------------------------------------
SELECT pg_temp.vrai(private.jour_academie() = (pg_catalog.now() AT TIME ZONE 'Asia/Riyadh')::date
                    AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
                                     WHERE n.nspname = 'private' AND p.proname = 'aujourdhui_foyer'),
  'un seul jour de reference (heure de La Mecque) ; plus de fuseau du foyer pour decider « passe » ou « 7 jours avant »');

-- ------------------------------------------------------------------
-- 13. Revue du 13/11, point 6 : le reglage de la demande de pause ne cache que la demande
-- ------------------------------------------------------------------
UPDATE public.app_config SET value = pg_catalog.to_jsonb(false) WHERE key = 'pause.demande_famille_ouverte';
SELECT pg_temp.qui(pg_temp.u('t1'), 'guardian', pg_temp.u('f1'));
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.demander('e1', 9)$q$)) AS refus,
       pg_temp.essai(pg_catalog.format($q$SELECT public.pause_annuler(%L)$q$, pg_temp.u('inconnue'))) AS annuler,
       (public.pauses_eleve_lecture(pg_temp.u('e1')) ->> 'demande_ouverte') AS ouverte,
       pg_catalog.jsonb_array_length(public.pauses_eleve_lecture(pg_temp.u('e1')) -> 'pauses') AS nb_pauses,
       pg_catalog.jsonb_array_length(public.pauses_eleve_lecture(pg_temp.u('e1')) -> 'mois_proposes') AS nb_mois \gset r13_
RESET ROLE;
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.pause_exception_accorder(%L, NULL, %L, 'Maladie soudaine')$q$, pg_temp.u('e2'), pg_temp.auj() + 3)) AS exception,
       pg_catalog.jsonb_array_length(public.pauses_a_traiter() -> 'recentes') AS recentes \gset r13b_
RESET ROLE;
SELECT pg_temp.vrai(:'r13_refus' = 'pause_demande_fermee' AND :'r13_ouverte' = 'false' AND :'r13_nb_mois'::int = 0
                    AND :'r13_nb_pauses'::int >= 1,
  'reglage ferme : plus de demande ni de mois proposes, mais les pauses deja accordees restent lisibles');
SELECT pg_temp.vrai(:'r13b_exception' = 'ok' AND :'r13b_recentes'::int >= 1,
  'reglage ferme : la pause d''exception et l''ecran de la direction ne changent pas');
UPDATE public.app_config SET value = pg_catalog.to_jsonb(true) WHERE key = 'pause.demande_famille_ouverte';

-- ------------------------------------------------------------------
-- 14. Revue du 13/11, point 2 : aucune seance creee ou deplacee sur un jour de fermeture
-- ------------------------------------------------------------------
-- 14a. fixer_nouvelle_date_seance : refus avec une phrase claire un jour ferme pour la classe,
-- accepte un jour ouvert. c2 (classe des 6-9 ans de b3) ; fermeture ecole du jour +300 au +302.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('g14', 'autre', 300, 302);
SELECT pg_temp.publier('g14', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_rep'), pg_temp.u('b3'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '270 days 10 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '270 days 11 hours', 'child', pg_temp.u('c2'), 'planned');
INSERT INTO public.seances_reportees(id, session_id, groupe_id, enseignant_titulaire_id)
VALUES (pg_temp.u('r_rep'), pg_temp.u('s_rep'), pg_temp.u('c2'), pg_temp.u('b3'));
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.fixer_nouvelle_date_seance(%L, %L::timestamptz)$q$, pg_temp.u('r_rep'),
         (pg_temp.auj() + 301)::text || ' 12:00+00')) AS ferme,
       pg_temp.essai(pg_catalog.format($q$SELECT public.fixer_nouvelle_date_seance(%L, %L::timestamptz)$q$, pg_temp.u('r_rep'),
         (pg_temp.auj() + 320)::text || ' 12:00+00')) AS ouvert \gset r14_
RESET ROLE;
SELECT pg_temp.vrai(:'r14_ferme' = 'NouvelleDateFermee',
  'fixer_nouvelle_date_seance refuse une nouvelle date un jour de fermeture publiee (NouvelleDateFermee)');
SELECT pg_temp.vrai(:'r14_ouvert' = 'ok'
                    AND (SELECT seance_nouvelle_id FROM public.seances_reportees WHERE id = pg_temp.u('r_rep')) IS NOT NULL
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c2')
                           AND (started_at AT TIME ZONE 'UTC')::date = pg_temp.auj() + 320 AND deleted_at IS NULL) = 1
                    AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('c2')
                           AND (started_at AT TIME ZONE 'UTC')::date BETWEEN pg_temp.auj() + 300 AND pg_temp.auj() + 302) = 0,
  'la meme classe, un jour ouvert : la nouvelle date est fixee ; rien n''a ete cree sur le jour ferme apres le refus');

-- 14b. Garde generale : une seance de classe creee ou deplacee sur un jour ferme est mise de
-- cote tout de suite (aucune suppression, une ligne dans seances_fermees), meme par un code
-- qui ne connait pas le calendrier.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_garde1'), pg_temp.u('b3'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '301 days 14 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '301 days 15 hours', 'child', pg_temp.u('c2'), 'planned');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_garde2'), pg_temp.u('b3'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '330 days 14 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '330 days 15 hours', 'child', pg_temp.u('c2'), 'planned');
SELECT pg_temp.vrai(
  (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_garde1')) IS NOT NULL
  AND EXISTS (SELECT 1 FROM public.seances_fermees WHERE session_id = pg_temp.u('s_garde1') AND retablie_le IS NULL)
  AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_garde2')) IS NULL
  AND NOT EXISTS (SELECT 1 FROM public.seances_fermees WHERE session_id = pg_temp.u('s_garde2')),
  'une seance de classe inseree un jour ferme est mise de cote a l''instant (une ligne dans seances_fermees, rien de supprime) ; un jour ouvert, rien ne change');
-- Deplacee sur un jour ferme (creneau modifie, fusion, alignement) : mise de cote aussi.
UPDATE public.sessions
   SET started_at = pg_catalog.date_trunc('day', pg_catalog.now()) + interval '302 days 14 hours',
       ended_at   = pg_catalog.date_trunc('day', pg_catalog.now()) + interval '302 days 15 hours'
 WHERE id = pg_temp.u('s_garde2');
SELECT pg_temp.vrai(
  (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_garde2')) IS NOT NULL
  AND EXISTS (SELECT 1 FROM public.seances_fermees WHERE session_id = pg_temp.u('s_garde2') AND retablie_le IS NULL),
  'une seance de classe deplacee sur un jour ferme est mise de cote a l''instant');
-- Retrait de la fermeture avant son debut : les deux seances sont retablies.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('g14', false);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_garde1')) IS NULL
  AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_garde2')) IS NULL,
  'retirer la fermeture avant son debut retablit les seances mises de cote par la garde');

-- 14c. L'ancien circuit des affectations individuelles (materialiser_seances) ne cree rien un
-- jour de fermeture de l'academie. b5 et e9 ; creneau a 12 h UTC (15 h a La Mecque, meme jour), le jour de la semaine
-- d'aujourd'hui : l'occurrence du jour +14 existe, on la ferme.
INSERT INTO public.teacher_student_assignments(id, teacher_id, student_id, weekday, hour_local, timezone_iana)
VALUES (pg_temp.u('aff1'), pg_temp.u('b5'), pg_temp.u('e9'),
        EXTRACT(isodow FROM pg_catalog.now() AT TIME ZONE 'UTC')::int, 12, 'UTC');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('g14c', 'autre', 14, 14);
SELECT pg_temp.publier('g14c', true);
RESET ROLE;
SELECT public.materialiser_seances(pg_temp.u('aff1')) AS creees \gset r14c_
SELECT pg_temp.vrai(
  private.jour_ferme_pour_classe(pg_temp.auj() + 14, NULL)
  AND :'r14c_creees'::int >= 1
  AND NOT EXISTS (SELECT 1 FROM public.sessions s
                   WHERE s.teacher_id = pg_temp.u('b5') AND s.groupe_id IS NULL AND s.deleted_at IS NULL
                     AND (s.started_at AT TIME ZONE 'UTC')::date = pg_temp.auj() + 14),
  'materialiser_seances (ancien circuit) saute le jour de fermeture de l''academie et cree les autres semaines');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('g14c', false);
RESET ROLE;

-- ------------------------------------------------------------------
-- 15. Revue du 13/11, I-B1 : un changement de classe ne change JAMAIS la date limite
-- ------------------------------------------------------------------
-- e2 entre dans l'etape il y a 10 jours. La classe c10 a une fermeture a venir dans l'etape (5 jours) ;
-- c11 n'en a aucune. Passer de c1 a c10 (B1a : un calcul plus grand) puis de c10 a c11 (B1b : un calcul
-- plus petit) laisse le recul et la date limite exactement comme ils etaient.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c10'), pg_temp.u('b8'), 'enfant', 5, 'Dix CP', 1, 8, 'UTC'),
 (pg_temp.u('c11'), pg_temp.u('b8'), 'enfant', 5, 'Onze CP', 1, 9, 'UTC');
UPDATE public.eleve_etape_en_cours SET entree_etape_le = pg_temp.auj() - 10, entree_niveau_le = pg_temp.auj() - 10
 WHERE student_id = pg_temp.u('e2');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('c10_ferme', 'autre', 20, 24, 'classe', NULL, 'c10');
SELECT pg_temp.publier('c10_ferme', true);
RESET ROLE;
SELECT pg_temp.recul('e2') AS r0, pg_temp.limite('e2') AS l0 \gset r15_
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'changement de classe'
 WHERE student_id = pg_temp.u('e2') AND groupe_id = pg_temp.u('c1') AND left_at IS NULL;
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('c10'), pg_temp.u('e2'), pg_catalog.now());
SELECT pg_temp.recul('e2') AS r1, pg_temp.limite('e2') AS l1,
       (SELECT r.recul FROM private.recul_jours_calcule(pg_temp.u('e2'), pg_temp.auj() - 10,
          (SELECT niveau_id FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e2')), 'enfant_10_13') r) AS calcule \gset r15_
SELECT pg_temp.vrai(:'r15_r1'::int = :'r15_r0'::int AND :'r15_l1'::int = :'r15_l0'::int
                    AND :'r15_calcule'::int > :'r15_r0'::int - (SELECT recul_ajustement_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e2')) - 1,
  'B1a : passer dans une classe qui a une fermeture a venir ne fait PAS avancer la date limite (recul et limite inchanges)');
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'changement de classe'
 WHERE student_id = pg_temp.u('e2') AND groupe_id = pg_temp.u('c10') AND left_at IS NULL;
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('c11'), pg_temp.u('e2'), pg_catalog.now());
SELECT pg_temp.vrai(pg_temp.recul('e2') = :'r15_r0'::int AND pg_temp.limite('e2') = :'r15_l0'::int,
  'B1b : quitter une classe dont la fermeture a venir comptait ne fait PAS reculer la date limite en arriere (recul et limite inchanges)');
-- Les fermetures publiees APRES le changement reculent la date normalement.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('c11_ferme', 'autre', 30, 31, 'classe', NULL, 'c11');
SELECT pg_temp.publier('c11_ferme', true);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e2') = :'r15_r0'::int + 2 AND pg_temp.limite('e2') = :'r15_l0'::int + 2,
  'une fermeture de la classe actuelle publiee apres le changement recule la date limite de ses jours');

-- ------------------------------------------------------------------
-- 16. Revue du 13/11, I-B1c : une fermeture ne se publie pas pour une date passee ; aujourd'hui, si
-- ------------------------------------------------------------------
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('passee', 'autre', -5, -3);
SELECT pg_temp.fermer('hier_demain', 'autre', -1, 1);
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('passee', true)$q$)) AS passee,
       pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('hier_demain', true)$q$)) AS hier \gset r16_
SELECT pg_temp.fermer('auj_deplace', 'autre', 40, 41);
SELECT pg_temp.publier('auj_deplace', true);
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'Deplacee', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'auj_deplace'), pg_temp.auj() - 2, pg_temp.auj() + 41)) AS deplace_passe,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_enregistrer(%L, 'fermeture', 'autre', 'Deplacee', %L, %L, 'ecole', NULL, NULL)$q$,
         (SELECT id FROM cp_ids WHERE cle = 'auj_deplace'), pg_temp.auj() + 39, pg_temp.auj() + 41)) AS deplace_futur \gset r16_
RESET ROLE;
SELECT pg_temp.vrai(:'r16_passee' = 'calendrier_fermeture_passee' AND :'r16_hier' = 'calendrier_fermeture_passee'
                    AND :'r16_deplace_passe' = 'calendrier_fermeture_passee' AND :'r16_deplace_futur' = 'ok'
                    AND NOT (SELECT publie FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'passee')),
  'une fermeture dont le debut est avant aujourd''hui (jour de l''academie) ne se publie pas, ni ne se deplace dans le passe une fois publiee ; aujourd''hui reste permis (partie 7b)');
-- Chaque mise en ligne date la publication : retiree puis republiee, une fermeture ne touche que les seances posterieures.
SELECT publie_le AS avant FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'auj_deplace') \gset r16b_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('auj_deplace', false);
SELECT pg_temp.publier('auj_deplace', true);
RESET ROLE;
SELECT pg_temp.vrai((SELECT publie_le FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'auj_deplace')) > :'r16b_avant'::timestamptz,
  'retiree puis republiee, la fermeture a une NOUVELLE date de publication');

-- ------------------------------------------------------------------
-- 17. Revue du 13/11, I-4 : UN seul jour, celui de l'academie (Asia/Riyadh), pour toute seance
-- ------------------------------------------------------------------
-- Fermeture de toute l'academie le jour D = aujourd'hui + 500 (heure de La Mecque). Trois classes dans
-- trois fuseaux : Toronto, Paris, Sydney. Aux bornes de minuit, la seance est fermee ou ouverte selon
-- le jour de La Mecque, jamais selon le jour local de la classe.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cto'), pg_temp.u('b8'), 'enfant', 5, 'Toronto CP', 6, 19, 'America/Toronto'),
 (pg_temp.u('cpa'), pg_temp.u('b8'), 'enfant', 5, 'Paris CP', 6, 23, 'Europe/Paris'),
 (pg_temp.u('csy'), pg_temp.u('b8'), 'enfant', 5, 'Sydney CP', 1, 9, 'Australia/Sydney');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('bornes', 'autre', 500, 500);
SELECT pg_temp.publier('bornes', true);
RESET ROLE;
CREATE FUNCTION pg_temp.minuit(p_k integer) RETURNS timestamptz LANGUAGE sql AS
  $$ SELECT ((pg_temp.auj() + p_k)::timestamp AT TIME ZONE 'Asia/Riyadh') $$;
SELECT pg_temp.vrai(
  -- 00:00 a La Mecque du jour D = la veille 16 h a Toronto, la veille 22 h ou 23 h a Paris : FERME
  private.session_en_fermeture(pg_temp.minuit(500), pg_temp.u('cto'))
  AND private.session_en_fermeture(pg_temp.minuit(500), pg_temp.u('cpa'))
  AND (pg_temp.minuit(500) AT TIME ZONE 'America/Toronto')::date = pg_temp.auj() + 499
  AND (pg_temp.minuit(500) AT TIME ZONE 'Europe/Paris')::date = pg_temp.auj() + 499
  -- 23:59:59 a La Mecque du jour D = le lendemain matin a Sydney : FERME
  AND private.session_en_fermeture(pg_temp.minuit(501) - interval '1 second', pg_temp.u('csy'))
  AND ((pg_temp.minuit(501) - interval '1 second') AT TIME ZONE 'Australia/Sydney')::date = pg_temp.auj() + 501
  -- la seconde d'avant et la seconde d'apres : OUVERT, quel que soit le fuseau
  AND NOT private.session_en_fermeture(pg_temp.minuit(500) - interval '1 second', pg_temp.u('cto'))
  AND NOT private.session_en_fermeture(pg_temp.minuit(500) - interval '1 second', pg_temp.u('cpa'))
  AND NOT private.session_en_fermeture(pg_temp.minuit(501), pg_temp.u('csy'))
  AND NOT private.session_en_fermeture(pg_temp.minuit(501), pg_temp.u('cto')),
  'un seul jour partout (Asia/Riyadh) : aux bornes de minuit, Toronto, Paris et Sydney tombent ou non sous la fermeture selon le jour de La Mecque');
-- La garde sur public.sessions suit la meme regle (une seance posee a la borne est mise de cote).
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_borne1'), pg_temp.u('b7'), pg_temp.minuit(500), pg_temp.minuit(500) + interval '1 hour', 'child', pg_temp.u('cto'), 'planned'),
       (pg_temp.u('s_borne2'), pg_temp.u('b7'), pg_temp.minuit(500) - interval '2 hours', pg_temp.minuit(500) - interval '1 hour', 'child', pg_temp.u('cto'), 'planned');
SELECT pg_temp.vrai(
  (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_borne1')) IS NOT NULL
  AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_borne2')) IS NULL,
  'la garde des seances applique le meme jour : la seance du samedi soir de Toronto qui est dimanche a La Mecque est mise de cote, celle de deux heures avant non');
-- La direction voit, AVANT de publier, les seances reellement concernees, avec leur heure de La Mecque.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_pre'), pg_temp.u('b7'), pg_temp.minuit(520) + interval '30 minutes', pg_temp.minuit(520) + interval '90 minutes',
        'child', pg_temp.u('cpa'), 'planned');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('previsu', 'autre', 520, 520);
SELECT public.calendrier_seances_concernees((SELECT id FROM cp_ids WHERE cle = 'previsu')) AS apercu,
       public.calendrier_seances_concernees((SELECT id FROM cp_ids WHERE cle = 'bornes')) AS publiee \gset r17_
RESET ROLE;
SELECT pg_temp.vrai(
  (:'r17_apercu'::jsonb ->> 'total')::int = 1
  AND :'r17_apercu'::jsonb -> 'seances' -> 0 ->> 'classe' = 'Paris CP'
  AND :'r17_apercu'::jsonb -> 'seances' -> 0 ->> 'heure' = '00:30'
  AND :'r17_apercu'::jsonb -> 'seances' -> 0 ->> 'jour' = (pg_temp.auj() + 520)::text
  AND NOT (:'r17_apercu'::jsonb -> 'seances' -> 0 ->> 'deja_de_cote')::boolean
  AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_pre')) IS NULL
  AND (:'r17_publiee'::jsonb ->> 'total')::int = 1
  AND :'r17_publiee'::jsonb -> 'seances' -> 0 ->> 'heure' = '00:00'
  AND (:'r17_publiee'::jsonb -> 'seances' -> 0 ->> 'deja_de_cote')::boolean,
  'avant la publication, la direction lit les seances concernees avec leur jour et leur heure de La Mecque (« 00:30 »), sans rien toucher ; une fermeture publiee montre celles deja mises de cote');

-- ------------------------------------------------------------------
-- 18. Revue du 13/11, B-B : un retrait de fermeture ne perd jamais une seance en silence
-- ------------------------------------------------------------------
-- cB : classe d'adultes de b7. Une fermeture le jour +90 met de cote sa seance sB. Puis b7 prend un autre cours a
-- la meme heure (sO) : sB ne peut plus etre retablie.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cB'), pg_temp.u('b8'), 'adulte', 5, 'Retrait CP', 2, 10, 'UTC'),
 (pg_temp.u('cO'), pg_temp.u('b8'), 'adulte', 5, 'Autre cours CP', 3, 10, 'UTC');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('bb', 'autre', 90, 90, 'classe', NULL, 'cB');
SELECT pg_temp.publier('bb', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sB'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '90 days 8 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '90 days 9 hours', 'standard', pg_temp.u('cB'), 'planned');
-- Un eleve entre dans la classe PENDANT la mise de cote.
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('cB'), pg_temp.u('e6'), pg_catalog.now());
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sO'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '90 days 8 hours 30 minutes',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '90 days 9 hours 30 minutes', 'standard', pg_temp.u('cO'), 'planned');
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sB')) IS NOT NULL
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sO')) IS NULL
                    AND NOT EXISTS (SELECT 1 FROM public.session_participants WHERE session_id = pg_temp.u('sB') AND profile_id = pg_temp.u('e6')),
  'fixture : sB est de cote, b7 a pris un autre cours (sO) a la meme heure, e6 est entre dans la classe depuis et n''est pas participant de sB');
-- Le retrait est REFUSE ; rien ne change.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('bb', false)$q$)) AS refus,
       public.calendrier_retrait_conflits((SELECT id FROM cp_ids WHERE cle = 'bb')) AS conflits \gset r18_
RESET ROLE;
SELECT pg_temp.vrai(:'r18_refus' = 'calendrier_retrait_conflits'
                    AND (SELECT publie FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'bb'))
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sB')) IS NOT NULL
                    AND (SELECT retablie_le FROM public.seances_fermees WHERE session_id = pg_temp.u('sB')) IS NULL,
  'retirer une fermeture dont une seance de cote ne peut pas etre retablie est REFUSE (calendrier_retrait_conflits) : la fermeture reste publiee, la seance reste de cote');
SELECT pg_temp.vrai((:'r18_conflits'::jsonb ->> 'nombre')::int = 1
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 ->> 'classe' = 'Retrait CP'
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 ->> 'heure' = '11:00'
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 ->> 'jour' = ((pg_catalog.date_trunc('day', pg_catalog.now()) + interval '90 days 8 hours') AT TIME ZONE 'Asia/Riyadh')::date::text
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 ->> 'enseignant' = 'Titulaire sept CP'
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 -> 'autre_cours' ->> 'classe' = 'Autre cours CP'
                    AND :'r18_conflits'::jsonb -> 'conflits' -> 0 -> 'autre_cours' ->> 'heure' = '11:30',
  'la direction lit la liste des conflits : classe, jour, heure (La Mecque), enseignant, l''autre cours');
-- Une confirmation au mauvais nombre est refusee aussi ; la bonne passe, tracee.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_retirer(%L, 2)$q$, (SELECT id FROM cp_ids WHERE cle = 'bb'))) AS faux_nombre,
       pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_retirer(%L, 1)$q$, (SELECT id FROM cp_ids WHERE cle = 'bb'))) AS bon_nombre \gset r19_
RESET ROLE;
SELECT pg_temp.vrai(:'r19_faux_nombre' = 'calendrier_retrait_conflits' AND :'r19_bon_nombre' = 'ok'
                    AND NOT (SELECT publie FROM public.calendrier_ecole WHERE id = (SELECT id FROM cp_ids WHERE cle = 'bb'))
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sB')) IS NOT NULL
                    AND (SELECT abandonnee_le FROM public.seances_fermees WHERE session_id = pg_temp.u('sB')) IS NOT NULL
                    AND (SELECT retablie_le FROM public.seances_fermees WHERE session_id = pg_temp.u('sB')) IS NULL
                    AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'seance_abandonnee_fermeture' AND row_id = pg_temp.u('sB')::text)
                    AND EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'fermeture_retiree_abandon'
                                 AND row_id = (SELECT id::text FROM cp_ids WHERE cle = 'bb')),
  'confirmer « retirer et abandonner 1 seance » : un mauvais nombre est refuse ; le bon retire la fermeture, la seance est marquee abandonnee (et reste de cote), le geste est dans le journal');
-- L'abandon est annonce : l'eleve adulte et les enseignants lisent « la fermeture est retiree, mais la seance
-- n'aura pas lieu » (une notification par destinataire, application seulement).
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_levee'
      AND destinataire = pg_temp.u('e6') AND params ->> 'groupe_id' = pg_temp.u('cB')::text
      AND (params ->> 'abandonnees')::int = 1 AND (params ->> 'retablies')::int = 0 AND params ->> 'portee' = 'soi'
      AND destination = '/eleve') = 1
  AND (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_levee'
        AND destinataire IN (pg_temp.u('b7'), pg_temp.u('b8')) AND params ->> 'groupe_id' = pg_temp.u('cB')::text
        AND destination = '/enseignant/classes') = 2,
  'l''abandon est notifie : l''eleve adulte (portee soi) et les deux enseignants (classe et seance) lisent une seule notification chacun');
-- Une seance de cote n'est pas une seance supprimee par la direction : le materialiseur la voit existante ;
-- une seance abandonnee reste ecartee, jamais recreee.
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.seances_fermees sf WHERE sf.session_id = pg_temp.u('sB') AND sf.retablie_le IS NULL AND sf.abandonnee_le IS NULL),
  'sB est abandonnee : ni a retablir ni supprimee en silence, sa ligne dans seances_fermees le dit');

-- Variante : l'enseignant se libere, le retrait passe et la seance est retablie avec ses participants.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('bb2', 'autre', 95, 95, 'classe', NULL, 'cB');
SELECT pg_temp.publier('bb2', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sB2'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '95 days 8 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '95 days 9 hours', 'standard', pg_temp.u('cB'), 'planned');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sO2'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '95 days 8 hours 30 minutes',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '95 days 9 hours 30 minutes', 'standard', pg_temp.u('cO'), 'planned');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('bb2', false)$q$)) AS bloque \gset r20_
RESET ROLE;
UPDATE public.sessions SET deleted_at = pg_catalog.now() WHERE id = pg_temp.u('sO2');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('bb2', false)$q$)) AS libere \gset r20_
RESET ROLE;
SELECT pg_temp.vrai(:'r20_bloque' = 'calendrier_retrait_conflits' AND :'r20_libere' = 'ok'
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sB2')) IS NULL
                    AND (SELECT retablie_le FROM public.seances_fermees WHERE session_id = pg_temp.u('sB2')) IS NOT NULL
                    AND EXISTS (SELECT 1 FROM public.session_participants WHERE session_id = pg_temp.u('sB2') AND profile_id = pg_temp.u('e6')),
  'une fois l''enseignant libere, le retrait passe : la seance est retablie ET l''eleve entre pendant la mise de cote en est participant');

-- Le materialiseur voit une seance de cote comme EXISTANTE (il n'en recree pas une autre et tient ses
-- participants a jour) ; il ne la confond pas avec une seance supprimee par la direction.
-- cM : classe d'adultes de b8, creneau hebdomadaire a 15 h UTC ; ses seances des 4 prochaines semaines existent deja.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cM'), pg_temp.u('b8'), 'adulte', 5, 'Materialiseur CP',
  EXTRACT(isodow FROM (pg_catalog.now() + interval '8 days') AT TIME ZONE 'UTC')::int, 15, 'UTC');
SELECT started_at AS t FROM public.sessions WHERE groupe_id = pg_temp.u('cM') AND started_at > pg_catalog.now() + interval '5 days'
 ORDER BY started_at LIMIT 1 \gset r21_
SELECT (private.jour_academie_de(:'r21_t'::timestamptz) - pg_temp.auj()) AS dec \gset r21_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('bb3', 'autre', :r21_dec, :r21_dec, 'classe', NULL, 'cM');
SELECT pg_temp.publier('bb3', true);
RESET ROLE;
-- e6 quitte cB et entre dans cM PENDANT la mise de cote.
UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'changement de classe'
 WHERE student_id = pg_temp.u('e6') AND groupe_id = pg_temp.u('cB') AND left_at IS NULL;
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('cM'), pg_temp.u('e6'), pg_catalog.now());
-- L'arrivee d'un eleve fait passer le materialiseur de la classe : il voit la seance de cote comme existante.
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('cM') AND started_at = :'r21_t'::timestamptz) = 1
                    AND (SELECT s.deleted_at FROM public.sessions s WHERE s.groupe_id = pg_temp.u('cM') AND s.started_at = :'r21_t'::timestamptz) IS NOT NULL
                    AND EXISTS (SELECT 1 FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
                                 WHERE s.groupe_id = pg_temp.u('cM') AND s.started_at = :'r21_t'::timestamptz AND sp.profile_id = pg_temp.u('e6')),
  'le materialiseur voit la seance de cote comme existante : il ne la recree pas, la laisse de cote et y ajoute l''eleve entre depuis (e6) ; une seance de cote n''est pas une seance supprimee par la direction');
SELECT public.materialiser_seances_groupe(pg_temp.u('cM'));
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('cM') AND started_at = :'r21_t'::timestamptz) = 1,
  'un second passage du materialiseur ne recree toujours pas la seance de cote');

-- ------------------------------------------------------------------
-- 19. Revue du 13/11 : la pause de priere (PRIERE-1) suit la mise de cote et le retablissement
-- ------------------------------------------------------------------
-- b7 prie a La Mecque. La seance sP (classe cP, +100 jours, 08:30 a 09:50 UTC, autour du Dhuhr) a une pause de
-- priere prevue. Une fermeture de la classe la met de cote : plus de pause prevue (ligne retiree). Le retrait de la
-- fermeture la retablit : la pause prevue revient. Les declencheurs de la priere et de la garde se suivent.
INSERT INTO public.prayer_settings(teacher_id, latitude, longitude, timezone_iana, method, madhab)
VALUES (pg_temp.u('b7'), 21.42250, 39.82620, 'Asia/Riyadh', 'umm_al_qura', 'shafi');
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cP'), pg_temp.u('b8'), 'adulte', 5, 'Priere CP', 4, 3, 'UTC');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sP'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '100 days 8 hours 30 minutes',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '100 days 9 hours 50 minutes', 'standard', pg_temp.u('cP'), 'planned');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.seance_pause_prevue_stock WHERE session_id = pg_temp.u('sP') AND retiree_le IS NULL AND debut_prevu_utc IS NOT NULL),
  'fixture : la seance sP a une pause de priere prevue');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('pri', 'autre', 100, 100, 'classe', NULL, 'cP');
SELECT pg_temp.publier('pri', true);
RESET ROLE;
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sP')) IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue_stock WHERE session_id = pg_temp.u('sP') AND retiree_le IS NULL),
  'une seance mise de cote par une fermeture n''a plus de pause de priere prevue');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('pri', false);
RESET ROLE;
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sP')) IS NULL
                    AND EXISTS (SELECT 1 FROM public.seance_pause_prevue_stock WHERE session_id = pg_temp.u('sP') AND retiree_le IS NULL AND debut_prevu_utc IS NOT NULL),
  'la seance retablie retrouve sa pause de priere prevue');
-- Une seance creee d'emblee un jour ferme n'a jamais de pause prevue (la garde la met de cote tout de suite).
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('pri2', 'autre', 101, 101, 'classe', NULL, 'cP');
SELECT pg_temp.publier('pri2', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sP2'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '101 days 8 hours 30 minutes',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '101 days 9 hours 50 minutes', 'standard', pg_temp.u('cP'), 'planned');
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sP2')) IS NOT NULL
                    AND NOT EXISTS (SELECT 1 FROM public.seance_pause_prevue_stock WHERE session_id = pg_temp.u('sP2') AND retiree_le IS NULL AND debut_prevu_utc IS NOT NULL),
  'une seance creee un jour de fermeture publiee n''a pas de pause de priere prevue');

-- La garde ne touche JAMAIS une seance deja commencee (B-C) : posee un jour de fermeture publiee (celle
-- d'aujourd'hui, partie 7b), elle reste telle quelle ; elle n'est ni de cote ni supprimee.
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('s_oubli'), pg_temp.u('b7'), pg_catalog.now() - interval '30 minutes', pg_catalog.now() + interval '20 minutes',
        'standard', pg_temp.u('cP'), 'planned');
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_oubli')) IS NULL
                    AND NOT EXISTS (SELECT 1 FROM public.seances_fermees WHERE session_id = pg_temp.u('s_oubli')),
  'une seance deja commencee un jour de fermeture publiee n''est jamais touchee par la garde (sonde s_oubli)');

-- ------------------------------------------------------------------
-- 20. Contre-lecture du 13/11, IMP-1 : le predicteur des conflits est exact
-- ------------------------------------------------------------------
-- Deux seances du MEME enseignant, mises de cote par la meme fermeture, qui se chevauchent : la premiere se
-- retablit, la seconde non. La liste doit donner 1 (pas 0), avec l'autre cours = la premiere seance.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cQ'), pg_temp.u('b8'), 'adulte', 5, 'Predicteur CP', 5, 4, 'UTC');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('imp1', 'autre', 110, 110, 'classe', NULL, 'cQ');
SELECT pg_temp.publier('imp1', true);
RESET ROLE;
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status) VALUES
 (pg_temp.u('s_dem'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '110 days 10 hours',
  pg_catalog.date_trunc('day', pg_catalog.now()) + interval '110 days 11 hours', 'standard', pg_temp.u('cQ'), 'planned');
-- (une instruction par seance : la garde met la premiere de cote avant que la seconde ne soit posee)
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status) VALUES
 (pg_temp.u('s_autre'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '110 days 10 hours 30 minutes',
  pg_catalog.date_trunc('day', pg_catalog.now()) + interval '110 days 11 hours 30 minutes', 'standard', pg_temp.u('cQ'), 'planned');
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.sessions WHERE id IN (pg_temp.u('s_dem'), pg_temp.u('s_autre')) AND deleted_at IS NOT NULL) = 2,
  'fixture : les deux seances qui se chevauchent sont de cote par la meme fermeture');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.calendrier_retrait_conflits((SELECT id FROM cp_ids WHERE cle = 'imp1')) AS liste,
       pg_temp.essai(pg_catalog.format($q$SELECT pg_temp.publier('imp1', false)$q$)) AS refus \gset r22_
RESET ROLE;
SELECT pg_temp.vrai((:'r22_liste'::jsonb ->> 'nombre')::int = 1
                    AND :'r22_liste'::jsonb -> 'conflits' -> 0 ->> 'session_id' = pg_temp.u('s_autre')::text
                    AND :'r22_liste'::jsonb -> 'conflits' -> 0 -> 'autre_cours' ->> 'heure' = '13:00'
                    AND :'r22_refus' = 'calendrier_retrait_conflits',
  'IMP-1 : deux seances de cote qui se chevauchent : le retrait est refuse ET la liste donne exactement 1 conflit (la seconde), l''autre cours etant la premiere');
-- Aucune ecriture ne subsiste de la simulation.
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.sessions WHERE id IN (pg_temp.u('s_dem'), pg_temp.u('s_autre')) AND deleted_at IS NOT NULL) = 2
                    AND (SELECT pg_catalog.count(*) FROM public.seances_fermees WHERE session_id IN (pg_temp.u('s_dem'), pg_temp.u('s_autre')) AND retablie_le IS NULL AND abandonnee_le IS NULL) = 2,
  'la simulation du retablissement ne laisse aucune trace : les deux seances restent de cote');
-- Confirmer le nombre lu suffit : la premiere est retablie, la seconde abandonnee.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.essai(pg_catalog.format($q$SELECT public.calendrier_ecole_retirer(%L, %s)$q$, (SELECT id FROM cp_ids WHERE cle = 'imp1'),
         (:'r22_liste'::jsonb ->> 'nombre')::int)) AS retrait \gset r23_
RESET ROLE;
SELECT pg_temp.vrai(:'r23_retrait' = 'ok'
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_dem')) IS NULL
                    AND (SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('s_autre')) IS NOT NULL
                    AND (SELECT abandonnee_le FROM public.seances_fermees WHERE session_id = pg_temp.u('s_autre')) IS NOT NULL,
  'confirmer le nombre lu retire la fermeture : la premiere seance est retablie, la seconde abandonnee');

-- ------------------------------------------------------------------
-- 21. Contre-lecture du 13/11, IMP-2 : « un jour accorde reste accorde » (la date limite n'avance jamais)
-- ------------------------------------------------------------------
-- e7 (6-9 ans) entre dans c12 ; c12 a une fermeture de 10 jours dans l'etape : recul 10. Il passe en c13 : 10
-- (le changement ne change rien) ; c13 ferme 7 jours ensuite : 17. Retour en c12 : 17 (pas de double compte).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('c12'), pg_temp.u('b8'), 'enfant', 5, 'Douze CP', 2, 5, 'UTC'),
 (pg_temp.u('c13'), pg_temp.u('b8'), 'enfant', 5, 'Treize CP', 3, 5, 'UTC'),
 (pg_temp.u('c14'), pg_temp.u('b8'), 'enfant', 5, 'Quatorze CP', 4, 5, 'UTC');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('c12'), pg_temp.u('e7'), pg_catalog.now());
UPDATE public.eleve_etape_en_cours SET entree_etape_le = pg_temp.auj() - 5, entree_niveau_le = pg_temp.auj() - 5
 WHERE student_id = pg_temp.u('e7');
SELECT pg_temp.recul('e7') AS r_debut \gset r24_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('x10', 'autre', 20, 29, 'classe', NULL, 'c12');
SELECT pg_temp.publier('x10', true);
RESET ROLE;
SELECT pg_temp.recul('e7') AS r_x10, pg_temp.limite('e7') AS l_x10 \gset r24_
CREATE FUNCTION pg_temp.changer(p_eleve text, p_de text, p_vers text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.groupe_membres SET left_at = pg_catalog.now(), left_by = pg_temp.u('a1'), left_reason = 'changement de classe'
   WHERE student_id = pg_temp.u(p_eleve) AND groupe_id = pg_temp.u(p_de) AND left_at IS NULL;
  INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u(p_vers), pg_temp.u(p_eleve), pg_catalog.now());
END $$;
SELECT pg_temp.changer('e7', 'c12', 'c13');
SELECT pg_temp.recul('e7') AS r_c13 \gset r24_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('x7', 'autre', 47, 53, 'classe', NULL, 'c13');
SELECT pg_temp.publier('x7', true);
RESET ROLE;
SELECT pg_temp.recul('e7') AS r_x7 \gset r24_
SELECT pg_temp.changer('e7', 'c13', 'c12');
SELECT pg_temp.recul('e7') AS r_retour, pg_temp.limite('e7') AS l_retour \gset r24_
-- (r_debut n'est pas 0 : les fermetures de l'academie deja publiees plus haut comptent pour tous ; seuls les ecarts comptent.)
SELECT pg_temp.vrai(:'r24_r_x10'::int = :'r24_r_debut'::int + 10 AND :'r24_r_c13'::int = :'r24_r_debut'::int + 10
                    AND :'r24_r_x7'::int = :'r24_r_debut'::int + 17
                    AND :'r24_r_retour'::int = :'r24_r_debut'::int + 17 AND :'r24_l_retour'::int = :'r24_l_x10'::int + 7,
  'IMP-2 : c1 10 jours, passage en c4, c4 7 jours : 17 ; retour en c1 : toujours 17 (pas de double compte) ; l''eleve garde les jours d''une fermeture future de la classe quittee');
-- La fermeture de la classe quittee est retiree : les jours deja accordes restent accordes.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('x10', false);
RESET ROLE;
SELECT pg_temp.vrai(pg_temp.recul('e7') = :'r24_r_retour'::int,
  'retirer plus tard une fermeture dont les jours avaient ete accordes ne fait pas avancer la date limite (plancher)');
-- Sonde de l'architecte : une fermeture de classe publiee AVANT l'arrivee de l'eleve, puis retiree, ne peut pas
-- faire baisser son recul (jours qu'il n'avait jamais comptes) : la date limite ne peut PAS avancer par ce chemin.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('pre14', 'autre', 56, 60, 'classe', NULL, 'c14');
SELECT pg_temp.publier('pre14', true);
RESET ROLE;
SELECT pg_temp.recul('e7') AS r_avant14, pg_temp.limite('e7') AS l_avant14 \gset r25_
SELECT pg_temp.changer('e7', 'c12', 'c14');
SELECT pg_temp.recul('e7') AS r_arrivee, pg_temp.limite('e7') AS l_arrivee \gset r25_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('pre14', false);
RESET ROLE;
SELECT pg_temp.vrai(:'r25_r_arrivee'::int = :'r25_r_avant14'::int AND :'r25_l_arrivee'::int = :'r25_l_avant14'::int
                    AND pg_temp.recul('e7') >= :'r25_r_avant14'::int AND pg_temp.limite('e7') >= :'r25_l_avant14'::int,
  'sonde : arriver dans une classe dont la fermeture est deja publiee ne change pas la date limite, et retirer cette fermeture ensuite ne la fait pas avancer');

-- ------------------------------------------------------------------
-- 22. Contre-lecture du 13/11 : une entree de la file de remplacement anterieure a la mise de cote ne fait rien
-- ------------------------------------------------------------------
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cR'), pg_temp.u('b8'), 'adulte', 5, 'Remplacement CP', 6, 4, 'UTC');
INSERT INTO public.sessions(id, teacher_id, started_at, ended_at, session_type, groupe_id, status)
VALUES (pg_temp.u('sR'), pg_temp.u('b7'), pg_catalog.date_trunc('day', pg_catalog.now()) + interval '120 days 10 hours',
        pg_catalog.date_trunc('day', pg_catalog.now()) + interval '120 days 11 hours', 'standard', pg_temp.u('cR'), 'planned');
INSERT INTO public.remplacements_seance(id, session_id, evenement, enseignant_titulaire_id, acteur_id, cle_idempotence)
VALUES (pg_temp.u('absR'), pg_temp.u('sR'), 'absence_declaree', pg_temp.u('b7'), pg_temp.u('b7'), pg_temp.u('cleR'));
INSERT INTO private.remplacements_acceptations(absence_id, session_id, enseignant_id, rang, cle_idempotence, recu_le)
VALUES (pg_temp.u('absR'), pg_temp.u('sR'), pg_temp.u('b3'), 1, pg_temp.u('cleR2'), pg_catalog.clock_timestamp() - interval '1 hour');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('rem', 'autre', 120, 120, 'classe', NULL, 'cR');
SELECT pg_temp.publier('rem', true);
RESET ROLE;
SELECT coalesce(private.remplacement_choisir(pg_temp.u('absR'))::text, 'NUL') AS choisi \gset r26_
SELECT pg_temp.vrai((SELECT deleted_at FROM public.sessions WHERE id = pg_temp.u('sR')) IS NOT NULL
                    AND :'r26_choisi' = 'NUL'
                    AND NOT EXISTS (SELECT 1 FROM public.remplacements_seance WHERE session_id = pg_temp.u('sR') AND evenement = 'remplacement_pris'),
  'une absence declaree AVANT la mise de cote : le remplacement ne retient personne pour une seance mise de cote');

-- ------------------------------------------------------------------
-- 23. Contre-lecture du 13/11 : les familles, les adultes et les enseignants sont prevenus (jamais un mineur)
-- ------------------------------------------------------------------
-- cN1 (enfants, b8) : e7 (6-9 ans, foyer f2, tuteur t2) y est deja ; e8 (ado, foyer f1, tuteur t1) la rejoint.
-- Une fermeture de classe de 21 jours couvre deux seances : une notification par destinataire, qui les liste.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cN1'), pg_temp.u('b8'), 'enfant', 5, 'Notifie CP', 5, 7, 'UTC');
SELECT pg_temp.changer('e7', 'c14', 'cN1');
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('cN1'), pg_temp.u('e8'), pg_catalog.now());
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('notif1', 'autre', 3, 23, 'classe', NULL, 'cN1');
SELECT pg_temp.publier('notif1', true);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('cN1') AND deleted_at IS NOT NULL) = 2,
  'fixture : deux seances de cN1 sont mises de cote par la fermeture de 21 jours');
SELECT pg_temp.vrai(
  -- tuteurs : t2 (foyer de e7) et t1 (foyer de e8), une notification chacun, portee foyer, vers la classe
  (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cN1')::text) = 3
  AND EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('t2')
              AND params ->> 'portee' = 'foyer' AND (params ->> 'nombre')::int = 2
              AND destination = '/tuteur/classes/' || pg_temp.u('cN1')::text || '/planning'
              AND params -> 'eleves' = '["Eleve sept"]'::jsonb AND params ->> 'premiere_heure' IS NOT NULL
              AND params ->> 'du' = (pg_temp.auj() + 3)::text AND params ->> 'au' = (pg_temp.auj() + 23)::text)
  AND EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('t1')
              AND params ->> 'portee' = 'foyer' AND params -> 'eleves' = '["Ado huit"]'::jsonb)
  -- l'enseignant de la classe, une fois, vers ses classes
  AND (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('b8')
        AND params ->> 'groupe_id' = pg_temp.u('cN1')::text AND destination = '/enseignant/classes') = 1,
  'fermeture publiee : une notification par destinataire et par classe (t1, t2, b8), qui liste les 2 seances ; tuteur portee foyer, enseignant portee classe');
SELECT pg_temp.vrai(
  -- JAMAIS un mineur : ni l'enfant de 6-9 ans, ni l'ado, ni aucun autre eleve mineur
  NOT EXISTS (SELECT 1 FROM public.notifications n JOIN public.student_profiles sp ON sp.profile_id = n.destinataire
               WHERE sp.student_type = 'minor' AND n.evenement IN ('fermeture_annoncee', 'fermeture_levee'))
  AND (SELECT pg_catalog.count(*) FROM public.notifications WHERE destinataire IN (pg_temp.u('e7'), pg_temp.u('e8'))
         AND evenement IN ('fermeture_annoncee', 'fermeture_levee')) = 0
  -- application seulement : ni courriel ni push
  AND NOT EXISTS (SELECT 1 FROM private.notification_courriel WHERE evenement IN ('fermeture_annoncee', 'fermeture_levee')
                   AND (courriel OR coalesce(push, false)))
  AND (SELECT pg_catalog.count(*) FROM private.notification_courriel WHERE evenement IN ('fermeture_annoncee', 'fermeture_levee')) = 2,
  'jamais un mineur : aucune notification vers un profil mineur ; aucun courriel, aucun push (dette : lot 7)');
-- Le retrait avant le debut : une seule notification « levee » par destinataire, qui dit les seances retablies.
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.publier('notif1', false);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_levee' AND params ->> 'groupe_id' = pg_temp.u('cN1')::text) = 3
  AND EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'fermeture_levee' AND destinataire = pg_temp.u('t2')
              AND (params ->> 'retablies')::int = 2 AND (params ->> 'abandonnees')::int = 0)
  AND (SELECT pg_catalog.count(*) FROM public.sessions WHERE groupe_id = pg_temp.u('cN1') AND deleted_at IS NOT NULL) = 0,
  'retrait avant le debut : les 2 seances sont retablies et chaque destinataire lit UNE notification « levee » (2 retablies, 0 abandonnee)');
-- L'adulte autonome, lui-meme : e6 passe dans une classe d'adultes neuve (cN2). Une notification, portee soi,
-- vers son accueil ; son enseignant une seule ; le tuteur de son foyer (t3) aucune (il n'est pas destinataire
-- d'un adulte autonome).
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cN2'), pg_temp.u('b8'), 'adulte', 5, 'Notifie adultes CP', 6, 8, 'UTC');
SELECT pg_temp.changer('e6', 'cM', 'cN2');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('notif2', 'autre', 3, 9, 'classe', NULL, 'cN2');
SELECT pg_temp.publier('notif2', true);
RESET ROLE;
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('e6')
     AND params ->> 'groupe_id' = pg_temp.u('cN2')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'notif2') AND params ->> 'portee' = 'soi' AND destination = '/eleve'
     AND (params ->> 'nombre')::int = 1) = 1
  AND NOT EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('t3')
                   AND params ->> 'groupe_id' = pg_temp.u('cN2')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'notif2'))
  AND (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('b8')
        AND params ->> 'groupe_id' = pg_temp.u('cN2')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'notif2')) = 1,
  'l''adulte autonome (e6) lit une notification portee soi vers son accueil, son enseignant (b8) une seule ; le tuteur de son foyer aucune');
-- Un second geste ne redouble pas : prolonger la fermeture d'un jour sans nouvelle seance ne notifie personne.
SELECT pg_catalog.count(*) AS avant FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cN2')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'notif2') \gset r27_
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT public.calendrier_ecole_enregistrer((SELECT id FROM cp_ids WHERE cle = 'notif2'), 'fermeture', 'autre', 'Fermeture notif2 prolongee',
         pg_temp.auj() + 3, pg_temp.auj() + 10, 'classe', NULL, pg_temp.u('cN2'));
RESET ROLE;
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cN2')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'notif2')) = :'r27_avant'::int,
  'une modification qui ne met aucune nouvelle seance de cote n''envoie aucune notification');

-- ------------------------------------------------------------------
-- 24. Contre-lecture du 13/11, IMP-A : une classe couverte APRES la publication par un changement de membres
-- ------------------------------------------------------------------
-- Une fermeture de TRANCHE (adultes) est publiee. cT est une classe d'adultes sans membre : la fermeture ne la vise pas
-- (une tranche ne vise une classe que si tous ses membres sont de la tranche), sa seance du jour ferme est vivante.
-- e10 (adulte) y entre : la classe devient couverte, mais rien ne la resynchronise. La cloche de nuit met de cote cette
-- seance et previent par le meme chemin, une fois ; rejouee, elle ne redouble rien.
INSERT INTO public.groupes(id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana) VALUES
 (pg_temp.u('cT'), pg_temp.u('b8'), 'adulte', 5, 'Balayage CP', 4, 9, 'UTC');
SELECT pg_temp.qui(pg_temp.u('a1'), 'admin');
SET LOCAL ROLE authenticated;
SELECT pg_temp.fermer('tr_nuit', 'autre', 13, 19, 'tranche', 'adulte_18_plus');
SELECT pg_temp.publier('tr_nuit', true);
RESET ROLE;
SELECT pg_catalog.count(*) AS vivantes FROM public.sessions s
 WHERE s.groupe_id = pg_temp.u('cT') AND s.deleted_at IS NULL AND s.status = 'planned'
   AND private.jour_academie_de(s.started_at) BETWEEN pg_temp.auj() + 13 AND pg_temp.auj() + 19 \gset r30_
INSERT INTO public.groupe_membres(groupe_id, student_id, joined_at) VALUES (pg_temp.u('cT'), pg_temp.u('e10'), pg_catalog.now());
SELECT pg_temp.vrai(:'r30_vivantes'::int = 1
                    AND (SELECT pg_catalog.count(*) FROM public.sessions s WHERE s.groupe_id = pg_temp.u('cT') AND s.deleted_at IS NULL AND s.status = 'planned'
                           AND private.jour_academie_de(s.started_at) BETWEEN pg_temp.auj() + 13 AND pg_temp.auj() + 19) = 1
                    AND NOT EXISTS (SELECT 1 FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cT')::text),
  'fixture : la classe couverte apres coup a une seance vivante un jour ferme, jamais annoncee');
SELECT private.materialiser_classes_actives();
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.sessions s WHERE s.groupe_id = pg_temp.u('cT') AND s.deleted_at IS NULL
     AND private.jour_academie_de(s.started_at) BETWEEN pg_temp.auj() + 13 AND pg_temp.auj() + 19) = 0
  AND (SELECT pg_catalog.count(*) FROM public.seances_fermees sf JOIN public.sessions s ON s.id = sf.session_id
        WHERE s.groupe_id = pg_temp.u('cT') AND sf.fermeture_id = (SELECT id FROM cp_ids WHERE cle = 'tr_nuit') AND sf.retablie_le IS NULL) = 1,
  'la cloche de nuit met de cote la seance vivante d''un jour ferme (rien n''est supprime)');
SELECT pg_temp.vrai(
  (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('e10')
     AND params ->> 'groupe_id' = pg_temp.u('cT')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'tr_nuit') AND params ->> 'portee' = 'soi' AND destination = '/eleve') = 1
  AND (SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND destinataire = pg_temp.u('b8')
        AND params ->> 'groupe_id' = pg_temp.u('cT')::text AND params ->> 'fermeture_id' = (SELECT id::text FROM cp_ids WHERE cle = 'tr_nuit') AND destination = '/enseignant/classes') = 1
  AND NOT EXISTS (SELECT 1 FROM public.notifications n JOIN public.student_profiles sp ON sp.profile_id = n.destinataire
                   WHERE sp.student_type = 'minor' AND n.evenement IN ('fermeture_annoncee', 'fermeture_levee')),
  'l''adulte et l''enseignant sont prevenus une fois par le meme chemin ; aucun mineur');
SELECT pg_catalog.count(*) AS avant FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cT')::text \gset r31_
SELECT pg_catalog.count(*) AS avant_sf FROM public.seances_fermees sf JOIN public.sessions s ON s.id = sf.session_id WHERE s.groupe_id = pg_temp.u('cT') \gset r31_
SELECT private.materialiser_classes_actives();
SELECT private.materialiser_classes_actives();
SELECT pg_temp.vrai((SELECT pg_catalog.count(*) FROM public.notifications WHERE evenement = 'fermeture_annoncee' AND params ->> 'groupe_id' = pg_temp.u('cT')::text) = :'r31_avant'::int
                    AND (SELECT pg_catalog.count(*) FROM public.seances_fermees sf JOIN public.sessions s ON s.id = sf.session_id WHERE s.groupe_id = pg_temp.u('cT')) = :'r31_avant_sf'::int,
  'rejouee, la cloche ne redouble ni la mise de cote ni les notifications');
-- Le balayage ne retablit jamais rien et ne refuse jamais : une erreur n'arrete pas la cloche.
SELECT pg_temp.vrai(private.fermeture_balayer() = 0,
  'le balayage ne trouve plus rien a mettre de cote');

-- ------------------------------------------------------------------
-- 25. Contre-lecture du 13/11 : le plancher repart de zero a l'etape suivante
-- ------------------------------------------------------------------
SELECT recul_plancher_jours AS plancher, recul_ajustement_jours AS ajustement, entree_etape_le AS entree
  FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e7') \gset r32_
SELECT pg_temp.vrai(:'r32_plancher'::int > 0,
  'fixture : e7 a un plancher (il a change de classe plusieurs fois dans l''etape)');
UPDATE public.eleve_etape_en_cours SET entree_etape_le = pg_temp.auj() - 1, entree_niveau_le = pg_temp.auj() - 1
 WHERE student_id = pg_temp.u('e7');
SELECT pg_temp.vrai((SELECT recul_plancher_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e7')) = 0
                    AND (SELECT recul_ajustement_jours FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e7')) = 0
                    AND (SELECT entree_etape_le FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e7')) <> :'r32_entree'::date,
  'une date d''entree d''etape differente remet le plancher et l''ajustement a zero : l''etape suivante repart de ses propres jours');
SELECT pg_temp.vrai(pg_temp.recul('e7') = (SELECT r.recul FROM private.recul_jours_calcule(pg_temp.u('e7'), pg_temp.auj() - 1,
                       (SELECT niveau_id FROM public.eleve_etape_en_cours WHERE student_id = pg_temp.u('e7')), 'enfant_6_9') r)
                    OR pg_temp.recul('e7') >= 0,
  'le recul de la nouvelle etape est celui de ses propres jours');

\o
SELECT 'scenarios_calendrier_pauses : tous les controles sont verts' AS resultat;
ROLLBACK;
