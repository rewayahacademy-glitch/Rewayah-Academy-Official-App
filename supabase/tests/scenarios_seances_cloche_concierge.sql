-- B2.2 bis (24/10/2026, plan de nuit du pilote) : la cloche et le concierge.
-- Migrations 20261025000000_seances_cloche.sql et
-- 20261025010000_seances_concierge.sql.
--
-- A rejouer sur une base NEUVE (stub_auth puis toutes les migrations). Le
-- scenario pose ses fixtures (aucune donnee personnelle), appelle les vraies
-- fonctions et annule tout a la fin.
--   (A) la cloche : une Classe dont l'horizon s'est epuise retrouve ses quatre
--       semaines ; la rejouer ne cree aucun doublon ; une Classe close, en
--       attente d'enseignant ou une seance supprimee a venir ne changent rien
--       d'autre ; une Classe en erreur n'arrete pas les autres ; personne
--       d'autre que postgres ne l'execute ;
--   (B) le concierge : le cours du jour, manquant parce que la Classe est nee
--       pendant le cours, est cree une seule fois (deux appels, une seance),
--       avec ses eleves, sa duree et l'ouverture de la salle ; une seance
--       existante est rendue telle quelle ; une seance supprimee n'est jamais
--       recreee ; hors fenetre, rien ; seuls l'enseignant, un eleve inscrit et
--       la direction l'appellent ;
--   (C) ajouter un creneau : la direction ajoute un creneau, ses seances sont
--       materialisees aussitot ; deux fois, rien de plus ; le predicat
--       d'affectation refuse un creneau qui chevauche, rien d'ecrit ; seule la
--       direction l'appelle.
-- Chaque controle leve 'CLOCHE-CONCIERGE ROUGE : ...' s'il echoue.
\o /dev/null
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', 'aal2',
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('test.uid', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
  PERFORM pg_catalog.set_config('test.jwt', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CLOCHE-CONCIERGE ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Un appel du concierge sous le role connecte, en tant que p_qui.
CREATE FUNCTION pg_temp.rejoindre(p_qui uuid, p_role text, p_classe uuid) RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v uuid;
BEGIN
  PERFORM pg_temp.qui(p_qui, p_role);
  SET LOCAL ROLE authenticated;
  v := public.seance_a_rejoindre(p_classe);
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.refuse(p_qui uuid, p_role text, p_classe uuid) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.rejoindre(p_qui, p_role, p_classe);
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
    PERFORM pg_temp.qui(NULL, NULL);
    RETURN true;
  END;
  RETURN false;
END $$;

CREATE TEMP TABLE cc_t (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
CREATE TEMP TABLE cc_c (code text PRIMARY KEY, id uuid NOT NULL) ON COMMIT DROP;
GRANT SELECT ON cc_t, cc_c TO authenticated;
CREATE FUNCTION pg_temp.t(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM cc_t WHERE code = p_code; $$;
CREATE FUNCTION pg_temp.c(p_code text) RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT id FROM cc_c WHERE code = p_code; $$;

-- Le jour ISO et l'heure de maintenant, a Paris (les cours du jour).
CREATE FUNCTION pg_temp.jour(p_decalage_jours int DEFAULT 0) RETURNS int
LANGUAGE sql STABLE AS $$
  SELECT extract(isodow FROM (now() AT TIME ZONE 'Europe/Paris') + make_interval(days => p_decalage_jours))::int $$;
CREATE FUNCTION pg_temp.heure() RETURNS int
LANGUAGE sql STABLE AS $$ SELECT extract(hour FROM now() AT TIME ZONE 'Europe/Paris')::int $$;

CREATE FUNCTION pg_temp.classe(p_code text, p_teacher text, p_jour int, p_heure int,
                               p_etat text DEFAULT 'active') RETURNS uuid
LANGUAGE plpgsql AS $$
DECLARE v_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.groupes
    (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
  VALUES (v_id, pg_temp.t(p_teacher), p_etat, 'adulte', 6, 'Cloche ' || p_code, p_jour, p_heure,
          'Europe/Paris', 'indetermine');
  INSERT INTO cc_c VALUES (p_code, v_id);
  RETURN v_id;
END $$;

CREATE FUNCTION pg_temp.nb(p_code text) RETURNS integer
LANGUAGE sql STABLE AS $$
  SELECT count(*)::integer FROM public.sessions s
   WHERE s.groupe_id = pg_temp.c(p_code) AND s.deleted_at IS NULL $$;

CREATE FUNCTION pg_temp.cloche() RETURNS integer
LANGUAGE plpgsql AS $$ BEGIN RETURN private.materialiser_classes_actives(); END $$;

-- ------------------------------------------------------------------
-- Fixtures
-- ------------------------------------------------------------------
INSERT INTO cc_t (code, id)
SELECT x.code, ('cc0c0000-0000-4000-8000-' || lpad(to_hex(x.n), 12, '0'))::uuid
  FROM (VALUES ('admin', 1), ('tA', 10), ('tB', 11), ('tC', 12), ('tD', 13),
               ('xA', 50), ('xB', 51), ('xautre', 52), ('xC', 53)) x(code, n);
INSERT INTO auth.users (id, email)
SELECT id, 'cloche-' || lower(code) || '@example.test' FROM cc_t;
INSERT INTO public.households (id, timezone) VALUES ('cc0cb000-0000-4000-8000-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, household_id)
SELECT t.id, 'CLOCHE' || upper(right(t.id::text, 10)),
       (CASE WHEN t.code = 'admin' THEN 'admin' WHEN t.code LIKE 'x%' THEN 'student' ELSE 'teacher' END)::public.app_role,
       'Fixture', t.code,
       (CASE WHEN t.code LIKE 't%' THEN 'provisional_active' ELSE 'active' END)::public.account_status, 'female'::public.gender,
       CASE WHEN t.code LIKE 'x%' THEN 'cc0cb000-0000-4000-8000-000000000001'::uuid END
  FROM cc_t t;
INSERT INTO public.student_profiles (profile_id, student_type, interface_mode)
SELECT t.id, 'autonomous'::public.student_type, 'standard'::public.interface_mode
  FROM cc_t t WHERE t.code LIKE 'x%';
INSERT INTO public.teacher_profiles (profile_id, country, languages, weekly_hours_cap, kyc_status, timezone_iana)
SELECT t.id, 'FR', ARRAY['francais'], 40, 'approved', 'Europe/Paris'
  FROM cc_t t WHERE t.code LIKE 't%';
INSERT INTO public.weekly_availability (profile_id, weekday, hour_local, timezone_iana)
SELECT t.id, d, h, 'Europe/Paris'
  FROM cc_t t CROSS JOIN generate_series(1, 7) d CROSS JOIN generate_series(0, 23) h
 WHERE t.code LIKE 't%';

-- ==================================================================
-- (A) La cloche
-- ==================================================================
-- Une Classe le jour apres-demain : quatre seances materialisees a sa creation.
SELECT pg_temp.classe('EPUISEE', 'tA', pg_temp.jour(2), 10);
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('EPUISEE'), pg_temp.t('xA'));
SELECT pg_temp.vrai(pg_temp.nb('EPUISEE') = 4, '(A) fixture : quatre seances a la creation');

-- L'horizon s'epuise : les deux dernieres seances sont reculees dans le passe
-- (comme si deux semaines etaient passees sans que la Classe change).
UPDATE public.sessions SET started_at = started_at - interval '400 days',
                           ended_at = ended_at - interval '400 days',
                           join_opens_at = join_opens_at - interval '400 days'
 WHERE id IN (SELECT id FROM public.sessions WHERE groupe_id = pg_temp.c('EPUISEE')
               ORDER BY started_at DESC LIMIT 2);
SELECT pg_temp.vrai(pg_temp.nb('EPUISEE') = 4
  AND (SELECT count(*) FROM public.sessions WHERE groupe_id = pg_temp.c('EPUISEE') AND started_at > now()) = 2,
  '(A) fixture : deux seances a venir seulement');

-- Une Classe close et une Classe sans enseignant ne recoivent rien.
SELECT pg_temp.classe('CLOSE', 'tB', pg_temp.jour(2), 12);
UPDATE public.groupes SET ended_at = now(), ended_by = pg_temp.t('admin'), end_reason = 'fixture'
 WHERE id = pg_temp.c('CLOSE');
UPDATE public.sessions SET deleted_at = now() WHERE groupe_id = pg_temp.c('CLOSE');
INSERT INTO cc_c VALUES ('ATTENTE', gen_random_uuid());
INSERT INTO public.groupes
  (id, teacher_id, etat, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, genre_public)
VALUES (pg_temp.c('ATTENTE'), NULL, 'en_attente_enseignant', 'adulte', 6, 'Cloche attente', pg_temp.jour(2), 14,
        'Europe/Paris', 'indetermine');

SELECT pg_temp.vrai(pg_temp.cloche() = 2, '(A) la cloche cree exactement les deux seances manquantes');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions WHERE groupe_id = pg_temp.c('EPUISEE')
     AND started_at > now() AND deleted_at IS NULL) = 4,
  '(A) la Classe epuisee retrouve ses quatre semaines a venir');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.session_participants sp JOIN public.sessions s ON s.id = sp.session_id
    WHERE s.groupe_id = pg_temp.c('EPUISEE') AND s.started_at > now() AND sp.profile_id = pg_temp.t('xA')) = 4,
  '(A) l''eleve inscrit est participant des quatre seances a venir');
SELECT pg_temp.vrai(
  NOT EXISTS (SELECT 1 FROM public.sessions WHERE groupe_id = pg_temp.c('EPUISEE') AND started_at > now()
                AND (ended_at - started_at <> interval '90 minutes'
                     OR join_opens_at <> started_at - interval '20 minutes'
                     OR status <> 'planned')),
  '(A) les seances creees ont la duree de la Classe (90 min) et l''ouverture 20 minutes avant');
SELECT pg_temp.vrai(pg_temp.cloche() = 0, '(A) rejouee, la cloche ne cree rien (idempotente)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM (SELECT started_at FROM public.sessions WHERE groupe_id = pg_temp.c('EPUISEE')
     AND deleted_at IS NULL GROUP BY started_at HAVING count(*) > 1) d) = 0,
  '(A) aucun doublon a la meme heure');
SELECT pg_temp.vrai(pg_temp.nb('CLOSE') = 0 AND pg_temp.nb('ATTENTE') = 0,
  '(A) une Classe close ou sans enseignant ne recoit rien');

-- Une Classe en erreur n'arrete pas les autres : la seance a venir de tC
-- chevauche (meme enseignant) le creneau d'une Classe dont on force le
-- creneau en base, puis on epuise une autre Classe.
SELECT pg_temp.classe('ERREUR', 'tC', pg_temp.jour(3), 10);
SELECT pg_temp.classe('SAINE', 'tD', pg_temp.jour(3), 16);
UPDATE public.sessions SET deleted_at = now()
 WHERE groupe_id IN (pg_temp.c('ERREUR'), pg_temp.c('SAINE'));
-- Une seance hors Classe de tC occupe les quatre prochains creneaux de ERREUR.
INSERT INTO public.sessions (teacher_id, started_at, ended_at, session_type)
SELECT pg_temp.t('tC'), d, d + interval '90 minutes', 'standard'
  FROM generate_series(0, 3) i,
       LATERAL (SELECT public.instant_creneau(pg_temp.jour(3), 10, 'Europe/Paris', i) AS d) x;
-- (la cloche dans sa propre requete : un instantane ne voit pas ses ecritures)
CREATE TEMP TABLE cc_n ON COMMIT DROP AS SELECT pg_temp.cloche() AS n;
SELECT pg_temp.vrai((SELECT n FROM cc_n) = 4 AND pg_temp.nb('SAINE') = 4 AND pg_temp.nb('ERREUR') = 0,
  '(A) une Classe en erreur (chevauchement) est sautee, les autres sont materialisees');

SELECT pg_temp.vrai(
  NOT has_function_privilege('authenticated', 'private.materialiser_classes_actives()', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'private.materialiser_classes_actives()', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'private.materialiser_classes_actives()', 'EXECUTE'),
  '(A) la cloche ne s''execute que par le planificateur');
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
     FROM pg_proc p WHERE p.oid = 'private.materialiser_classes_actives()'::regprocedure),
  '(A) SECURITY DEFINER, search_path vide');

-- ==================================================================
-- (B) Le concierge
-- ==================================================================
-- La Classe nait pendant le cours du jour (debut a l'heure pile, il y a moins
-- de 60 minutes ; le cours dure 90) : la materialisation saute ce cours.
SELECT pg_temp.classe('JOUR', 'tB', pg_temp.jour(0), pg_temp.heure());
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('JOUR'), pg_temp.t('xB'));
CREATE TEMP TABLE cc_debut ON COMMIT DROP AS
SELECT (date_trunc('hour', now() AT TIME ZONE 'Europe/Paris') AT TIME ZONE 'Europe/Paris') AS d;
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.sessions s, cc_debut
                                 WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = cc_debut.d),
  '(B) fixture : le cours du jour manque (materialiser part de la prochaine occurrence)');

CREATE TEMP TABLE cc_r (n int, id uuid) ON COMMIT DROP;
GRANT ALL ON cc_r TO authenticated;
INSERT INTO cc_r SELECT 1, pg_temp.rejoindre(pg_temp.t('xB'), 'student', pg_temp.c('JOUR'));
INSERT INTO cc_r SELECT 2, pg_temp.rejoindre(pg_temp.t('tB'), 'teacher', pg_temp.c('JOUR'));
INSERT INTO cc_r SELECT 3, pg_temp.rejoindre(pg_temp.t('admin'), 'admin', pg_temp.c('JOUR'));
SELECT pg_temp.vrai((SELECT count(DISTINCT id) FROM cc_r WHERE id IS NOT NULL) = 1
  AND (SELECT count(*) FROM cc_r WHERE id IS NULL) = 0,
  '(B) eleve, enseignant et direction recoivent la meme seance');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions s, cc_debut
    WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = cc_debut.d) = 1,
  '(B) le cours du jour est cree une seule fois (trois appels, une seance)');
SELECT pg_temp.vrai(
  (SELECT s.ended_at - s.started_at = interval '90 minutes'
      AND s.join_opens_at = s.started_at - interval '20 minutes'
      AND s.teacher_id = pg_temp.t('tB') AND s.status = 'planned' AND s.session_type = 'standard'
     FROM public.sessions s WHERE s.id = (SELECT id FROM cc_r WHERE n = 1)),
  '(B) la seance creee a la duree, l''ouverture, l''enseignant et le type de la materialisation');
SELECT pg_temp.vrai(EXISTS (SELECT 1 FROM public.session_participants
                             WHERE session_id = (SELECT id FROM cc_r WHERE n = 1)
                               AND profile_id = pg_temp.t('xB') AND role = 'student'),
  '(B) l''eleve inscrit est participant');
SELECT pg_temp.cloche();
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.sessions s, cc_debut
    WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = cc_debut.d) = 1,
  '(B) la cloche apres le concierge ne double pas le cours du jour');

-- Supprimee par la direction : jamais recreee.
UPDATE public.sessions SET deleted_at = now() WHERE id = (SELECT id FROM cc_r WHERE n = 1);
SELECT pg_temp.vrai(pg_temp.rejoindre(pg_temp.t('xB'), 'student', pg_temp.c('JOUR')) IS NULL
  AND (SELECT count(*) FROM public.sessions s, cc_debut
        WHERE s.groupe_id = pg_temp.c('JOUR') AND s.started_at = cc_debut.d) = 1,
  '(B) une seance supprimee n''est jamais recreee');

-- Hors fenetre (cours demain) : rien, rien d'ecrit.
SELECT pg_temp.classe('DEMAIN', 'tD', pg_temp.jour(1), pg_temp.heure());
INSERT INTO public.groupe_membres (groupe_id, student_id) VALUES (pg_temp.c('DEMAIN'), pg_temp.t('xC'));
CREATE TEMP TABLE cc_avant ON COMMIT DROP AS SELECT count(*) AS n FROM public.sessions;
SELECT pg_temp.vrai(pg_temp.rejoindre(pg_temp.t('xC'), 'student', pg_temp.c('DEMAIN')) IS NULL
  AND (SELECT count(*) FROM public.sessions) = (SELECT n FROM cc_avant),
  '(B) avant l''ouverture de la salle : rien, rien d''ecrit');

-- Les refus.
SELECT pg_temp.vrai(pg_temp.refuse(pg_temp.t('xautre'), 'student', pg_temp.c('JOUR')),
  '(B) un eleve d''une autre Classe est refuse');
SELECT pg_temp.vrai(pg_temp.refuse(pg_temp.t('tA'), 'teacher', pg_temp.c('JOUR')),
  '(B) un autre enseignant est refuse');
SELECT pg_temp.vrai(pg_temp.refuse(NULL, NULL, pg_temp.c('JOUR')),
  '(B) un appel sans session est refuse');
UPDATE public.groupe_membres SET left_at = now(), left_by = pg_temp.t('admin'), left_reason = 'fixture'
 WHERE groupe_id = pg_temp.c('JOUR');
SELECT pg_temp.vrai(pg_temp.refuse(pg_temp.t('xB'), 'student', pg_temp.c('JOUR')),
  '(B) un eleve parti de la Classe est refuse');
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.seance_a_rejoindre(uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.seance_a_rejoindre(uuid)', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
         FROM pg_proc p WHERE p.oid = 'public.seance_a_rejoindre(uuid)'::regprocedure),
  '(B) droits : connecte oui, anonyme non ; SECURITY DEFINER, search_path vide');

-- ==================================================================
-- (C) Ajouter un creneau
-- ==================================================================
CREATE FUNCTION pg_temp.creneau(p_qui uuid, p_role text, p_classe uuid, p_jour int, p_heure int) RETURNS integer
LANGUAGE plpgsql AS $$
DECLARE v integer;
BEGIN
  PERFORM pg_temp.qui(p_qui, p_role);
  SET LOCAL ROLE authenticated;
  v := public.ajouter_creneau_classe_admin(p_classe, p_jour, p_heure);
  RESET ROLE;
  PERFORM pg_temp.qui(NULL, NULL);
  RETURN v;
END $$;
CREATE FUNCTION pg_temp.creneau_refuse(p_qui uuid, p_role text, p_classe uuid, p_jour int, p_heure int,
                                       p_code text) RETURNS boolean
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    PERFORM pg_temp.creneau(p_qui, p_role, p_classe, p_jour, p_heure);
  EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    PERFORM pg_temp.qui(NULL, NULL);
    RAISE NOTICE 'refus % %', SQLSTATE, SQLERRM;
    IF p_code IS NOT NULL AND SQLSTATE <> p_code THEN
      RAISE NOTICE 'refus inattendu % %', SQLSTATE, SQLERRM;
      RETURN false;
    END IF;
    RETURN true;
  END;
  RETURN false;
END $$;

CREATE TEMP TABLE cc_cr ON COMMIT DROP AS
SELECT pg_temp.creneau(pg_temp.t('admin'), 'admin', pg_temp.c('SAINE'), pg_temp.jour(4), 9) AS n;
SELECT pg_temp.vrai((SELECT n FROM cc_cr) = 4 AND pg_temp.nb('SAINE') = 8
  AND EXISTS (SELECT 1 FROM public.groupe_creneaux WHERE groupe_id = pg_temp.c('SAINE')
                AND weekday = pg_temp.jour(4) AND hour_local = 9),
  '(C) la direction ajoute un creneau : quatre seances de plus, aussitot');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'classe_creneau_ajoute'
            AND row_id = pg_temp.c('SAINE')::text),
  '(C) l''ajout est journalise');
SELECT pg_temp.vrai(pg_temp.creneau(pg_temp.t('admin'), 'admin', pg_temp.c('SAINE'), pg_temp.jour(4), 9) = 0
  AND pg_temp.nb('SAINE') = 8,
  '(C) le meme creneau deux fois : rien de plus');
-- 17 h chevauche le cours de 16 h (90 minutes) du meme enseignant.
SELECT pg_temp.vrai(
  pg_temp.creneau_refuse(pg_temp.t('admin'), 'admin', pg_temp.c('SAINE'), pg_temp.jour(3), 17, NULL)
  AND NOT EXISTS (SELECT 1 FROM public.groupe_creneaux WHERE groupe_id = pg_temp.c('SAINE')
                    AND weekday = pg_temp.jour(3) AND hour_local = 17)
  AND pg_temp.nb('SAINE') = 8,
  '(C) un creneau qui chevauche un cours de l''enseignant est refuse, rien d''ecrit');
SELECT pg_temp.vrai(
  pg_temp.creneau_refuse(pg_temp.t('tD'), 'teacher', pg_temp.c('SAINE'), pg_temp.jour(5), 9, '42501'),
  '(C) l''enseignant ne peut pas ajouter de creneau');
SELECT pg_temp.vrai(
  pg_temp.creneau_refuse(pg_temp.t('admin'), 'admin', pg_temp.c('SAINE'), 8, 9, '22023'),
  '(C) un jour hors de 1 a 7 est refuse');
SELECT pg_temp.vrai(
  NOT has_function_privilege('anon', 'public.ajouter_creneau_classe_admin(uuid,integer,integer)', 'EXECUTE')
  AND (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""'] FROM pg_proc p
        WHERE p.oid = 'public.ajouter_creneau_classe_admin(uuid,integer,integer)'::regprocedure),
  '(C) anonyme non ; SECURITY DEFINER, search_path vide');

\o
SELECT 'CLOCHE-CONCIERGE VERT';
ROLLBACK;
