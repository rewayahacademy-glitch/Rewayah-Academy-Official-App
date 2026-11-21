-- CHIFFRES-ACADEMIE (migration 20261130969500) : public.chiffres_academie().
-- Droits (direction active seulement), resultat memorise 10 minutes (ferme a tout client), forme de la reponse (des nombres, rien d'autre), et chaque chiffre egal a un comptage
-- direct independant : la fixture est construite pour que chaque chiffre soit connu d'avance (un nombre ecrit ici), et la
-- verification compare l'ecart avant / apres la fixture a ce nombre.
-- A l'echelle : 650 candidatures d'enseignants, plus de 700 profils. Donnees fictives seulement.
-- La fixture est montee declencheurs coupes (session_replication_role = replica, superutilisateur local) : la fonction ne
-- fait que lire, les declencheurs d'ecriture ne sont pas l'objet de ce scenario.
-- Chaque verification est isolee ; le fichier se termine par la liste ok / ROUGE puis echoue s'il reste un ROUGE.
-- Annule tout a la fin. Aucun mot d'effacement.
-- Ce scenario n'est PAS dans .github/workflows/ci.yml (zone interdite a ce lot) : il se rejoue a la main ou par tool/e2e/.
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
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.code_refus(p_id uuid, p_role text, p_sql text, p_db_role text DEFAULT 'authenticated') RETURNS text
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    EXECUTE 'RESET ROLE';
    RETURN 'aucun';
  EXCEPTION WHEN OTHERS THEN
    RETURN SQLSTATE;
  END;
END $$;

CREATE TEMP TABLE res (nom text PRIMARY KEY, ok boolean NOT NULL, detail text);
GRANT ALL ON res TO authenticated, anon;
CREATE FUNCTION pg_temp.note(p_nom text, p_ok boolean, p_detail text DEFAULT NULL) RETURNS void LANGUAGE sql AS $$
  INSERT INTO res VALUES (p_nom, coalesce(p_ok, false), p_detail) $$;
CREATE FUNCTION pg_temp.verif(p_nom text, p_sql text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v boolean;
BEGIN
  BEGIN
    EXECUTE p_sql INTO v;
    PERFORM pg_temp.note(p_nom, v);
  EXCEPTION WHEN OTHERS THEN
    PERFORM pg_temp.note(p_nom, false, SQLSTATE || ' ' || SQLERRM);
  END;
END $$;

CREATE FUNCTION pg_temp.u(p_n int) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('c41f0000-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.c(p_n int) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('c41fcccc-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
CREATE FUNCTION pg_temp.g(p_n int) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$
  SELECT ('c41f9999-0000-4000-8000-' || lpad(p_n::text, 12, '0'))::uuid $$;
GRANT EXECUTE ON FUNCTION pg_temp.u(int), pg_temp.c(int), pg_temp.g(int) TO authenticated, anon;

-- Les comptes qui appellent : la direction (9001), puis un compte de chaque autre role, et une direction desactivee (9008).
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n), 'chiffres-' || n || '@test.invalid' FROM generate_series(9001, 9008) n;
SET LOCAL session_replication_role = replica;
INSERT INTO public.households (id, timezone, status) VALUES (pg_temp.g(99), 'Europe/Paris', 'active');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender) VALUES
 (pg_temp.u(9001), 'CHIF-ADM-01', 'admin',      NULL,          'Direction', 'Fictive', 'active',   'female'),
 (pg_temp.u(9002), 'CHIF-CPT-01', 'accountant', NULL,          'Comptable', 'Fictif',  'active',   'male'),
 (pg_temp.u(9003), 'CHIF-CTL-01', 'controller', NULL,          'Controle',  'Fictif',  'active',   'male'),
 (pg_temp.u(9005), 'CHIF-TUT-01', 'guardian',   pg_temp.g(99), 'Tuteur',    'Fictif',  'active',   'male'),
 (pg_temp.u(9006), 'CHIF-ELV-01', 'student',    pg_temp.g(99), 'Eleve',     'Fictif',  'active',   'male'),
 (pg_temp.u(9007), 'CHIF-ASS-01', 'associe',    NULL,          'Associe',   'Fictif',  'active',   'male'),
 (pg_temp.u(9008), 'CHIF-ADM-02', 'admin',      NULL,          'Direction', 'Eteinte', 'disabled', 'male');
SET LOCAL session_replication_role = origin;

-- L'etat AVANT la fixture, lu par la fonction elle-meme (la direction). Ce premier appel calcule et memorise.
CREATE TEMP TABLE etat (quand text PRIMARY KEY, j jsonb);
GRANT ALL ON etat TO authenticated;
INSERT INTO etat VALUES ('avant', pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()'));

-- ---------------------------------------------------------------------------------------------------------------------
-- LA FIXTURE, declencheurs coupes.
-- ---------------------------------------------------------------------------------------------------------------------
SET LOCAL session_replication_role = replica;

-- 650 candidats enseignants (comptes en attente : ils ne sont PAS des enseignants actifs). Une femme sur cinq : 130 / 520.
INSERT INTO auth.users (id, email) SELECT pg_temp.u(n), 'chiffres-cand-' || n || '@test.invalid' FROM generate_series(1, 650) n;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.u(n), 'CHIF-CAND-' || n, 'teacher', 'Candidat', 'Fictif ' || n, 'pending_kyc',
       (CASE WHEN n % 5 = 0 THEN 'female' ELSE 'male' END)::public.gender
  FROM generate_series(1, 650) n;
-- Arrivees : 5 aujourd'hui (a La Mecque), 35 il y a trois jours, 60 il y a dix jours, le reste il y a trente jours.
-- 12 pays distincts ; un sur treize sans pays.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, pays_residence, recue_le,
                                 derniere_activite)
SELECT pg_temp.c(n), 'enseignant', pg_temp.u(n), (CASE WHEN n % 5 = 0 THEN 'female' ELSE 'male' END)::public.gender,
       'Candidat Fictif ' || n, 'prequalification', 'en_examen',
       CASE WHEN n % 50 = 0 THEN 'retiree' ELSE 'en_cours' END, 'lien_public',
       CASE WHEN n % 13 = 0 THEN NULL
            ELSE (ARRAY['SA','EG','MA','DZ','TN','SN','ML','MR','FR','BE','CA','ID'])[(n % 12) + 1] END,
       ((((now() AT TIME ZONE 'Asia/Riyadh')::date
          - CASE WHEN n <= 5 THEN 0 WHEN n <= 40 THEN 3 WHEN n <= 100 THEN 10 ELSE 30 END)::timestamp)
         AT TIME ZONE 'Asia/Riyadh') + (n || ' seconds')::interval,
       now()
  FROM generate_series(1, 650) n;
-- 20 demandes de familles : elles ne comptent dans aucun chiffre des candidats.
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, pays_residence, recue_le,
                                 derniere_activite)
SELECT pg_temp.c(5000 + n), 'famille', NULL, 'female', 'Famille Fictive ' || n, 'recue', NULL, 'en_cours', 'lien_public', 'BR', now(), now()
  FROM generate_series(1, 20) n;

-- Reponses. Les candidats 1 a 600 ont une reponse ENVOYEE ; celle qui compte est la derniere envoyee.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le, soumis_le)
SELECT pg_temp.c(n), 'salle-examen-2',
       jsonb_build_object(
         'niveauMemorisationDeclare',
           CASE WHEN n % 4 = 0 THEN 'coran_entier' WHEN n % 4 = 1 THEN 'juz_7' WHEN n % 4 = 2 THEN 'de_10_a_29_juz'
                WHEN n % 8 = 3 THEN 'moins_10_juz' ELSE 'aucune' END,
         'ijazaPresentable', CASE WHEN n % 3 = 0 THEN 'oui' ELSE 'pret_test' END,
         'riwayat', to_jsonb(ARRAY['hafs'] || CASE WHEN n % 2 = 0 THEN ARRAY['warsh'] ELSE ARRAY[]::text[] END
                                           || CASE WHEN n % 7 = 0 THEN ARRAY['qalun'] ELSE ARRAY[]::text[] END),
         'languesExplication', to_jsonb(ARRAY['ar', 'autre'] || CASE WHEN n % 2 = 1 THEN ARRAY['francais'] ELSE ARRAY[]::text[] END)),
       'candidat', false, now() - interval '2 hours', now() - interval '2 hours'
  FROM generate_series(1, 600) n;
-- Une reponse envoyee PLUS ANCIENNE pour un candidat sur deux : elle ne compte pas (autres valeurs : shuba, tr, tout le Coran, ijaza).
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le, soumis_le)
SELECT pg_temp.c(n), 'salle-examen-2',
       '{"niveauMemorisationDeclare": "coran_entier", "ijazaPresentable": "oui", "riwayat": ["shuba"], "languesExplication": ["tr"]}'::jsonb,
       'candidat', false, now() - interval '3 days', now() - interval '3 days'
  FROM generate_series(2, 600, 2) n;
-- Un brouillon PLUS RECENT pour un candidat sur trois, et pour les candidats 601 a 650 (qui n'ont rien envoye) : il ne compte pas.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le, soumis_le)
SELECT pg_temp.c(n), 'salle-examen-2',
       '{"niveauMemorisationDeclare": "coran_entier", "ijazaPresentable": "oui", "riwayat": ["rawh"], "languesExplication": ["ur"]}'::jsonb,
       'candidat', true, NULL, now() - interval '1 minute'
  FROM generate_series(1, 650) n WHERE n % 3 = 0 OR n > 600;
-- Une reponse mal formee (riwayat et langues ne sont pas des tableaux) : elle ne fait pas tomber la lecture. Candidat 599 (n % 4 = 3,
-- n % 8 = 7 : aucune ; n % 3 <> 0), reponse plus recente que la sienne, memes valeurs comptees.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le, soumis_le)
VALUES (pg_temp.c(599), 'salle-examen-2',
        '{"niveauMemorisationDeclare": "aucune", "ijazaPresentable": "non", "riwayat": "hafs", "languesExplication": null}'::jsonb,
        'candidat', false, now() - interval '1 hour', now() - interval '1 hour');
-- La reponse d'une famille : hors des chiffres.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le, soumis_le)
VALUES (pg_temp.c(5001), 'famille-1',
        '{"niveauMemorisationDeclare": "coran_entier", "ijazaPresentable": "oui", "riwayat": ["idris"], "languesExplication": ["de"]}'::jsonb,
        'candidat', false, now(), now());

-- Enseignants : 7 actifs + 2 provisoires = 9 ; un desactive et un supprime ne comptent pas.
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender, deleted_at)
SELECT pg_temp.u(1000 + n), 'CHIF-ENS-' || n, 'teacher', 'Enseignant', 'Fictif ' || n,
       (CASE WHEN n <= 7 THEN 'active' WHEN n <= 9 THEN 'provisional_active' WHEN n = 10 THEN 'disabled' ELSE 'active' END)::public.account_status,
       'male', CASE WHEN n = 11 THEN now() END
  FROM generate_series(1, 11) n;

-- Familles : 11 foyers, plus un supprime.
INSERT INTO public.households (id, timezone, status, deleted_at)
SELECT pg_temp.g(100 + n), 'Europe/Paris', 'active', CASE WHEN n = 12 THEN now() END FROM generate_series(1, 12) n;

-- Eleves : 30 comptent ; 2 profils eleves supprimes, 1 compte desactive, 1 compte supprime ne comptent pas.
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender, deleted_at)
SELECT pg_temp.u(2000 + n), 'CHIF-ELV-' || n, 'student', pg_temp.g(101), 'Eleve', 'Fictif ' || n,
       (CASE WHEN n = 33 THEN 'disabled' ELSE 'active' END)::public.account_status, 'male', CASE WHEN n = 34 THEN now() END
  FROM generate_series(1, 34) n;
INSERT INTO public.student_profiles (profile_id, deleted_at)
SELECT pg_temp.u(2000 + n), CASE WHEN n IN (31, 32) THEN now() END FROM generate_series(1, 34) n;

-- Classes : 5 ouvertes, 2 terminees.
INSERT INTO public.groupes (id, teacher_id, type_public, seuil_max, libelle, weekday, hour_local, timezone_iana, etat, ended_at, ended_by, end_reason)
SELECT pg_temp.g(n), pg_temp.u(1001), 'adulte', 6, 'Classe fictive ' || n, 1, 18, 'Asia/Riyadh', 'active',
       CASE WHEN n > 5 THEN now() END, CASE WHEN n > 5 THEN pg_temp.u(9001) END, CASE WHEN n > 5 THEN 'fin de la fixture' END
  FROM generate_series(1, 7) n;
-- Membres : 12 eleves dans des classes ouvertes ; 3 dans une classe terminee, 2 sortis : ils ne comptent pas.
INSERT INTO public.groupe_membres (groupe_id, student_id, left_at, left_by, left_reason)
SELECT pg_temp.g(CASE WHEN n <= 12 THEN (n % 5) + 1 WHEN n <= 15 THEN 6 ELSE 1 END), pg_temp.u(2000 + n),
       CASE WHEN n > 15 THEN now() END, CASE WHEN n > 15 THEN pg_temp.u(9001) END, CASE WHEN n > 15 THEN 'sortie de la fixture' END
  FROM generate_series(1, 17) n;

-- Seances de classe terminees : 9 (4 sur les 7 derniers jours, 3 sur les 7 d'avant, 2 plus anciennes) ; 8 d'une heure et une de
-- 45 minutes et 30 secondes (comptee 45) : 525 minutes. Ne comptent pas : 3 annulees, 1 entretien termine (sans classe), 1 supprimee.
INSERT INTO public.sessions (id, teacher_id, groupe_id, session_type, status, started_at, ended_at, deleted_at)
SELECT pg_temp.g(1000 + n), pg_temp.u(1001), CASE WHEN n = 13 THEN NULL ELSE pg_temp.g(1) END,
       CASE WHEN n = 13 THEN 'entretien' ELSE 'standard' END,
       (CASE WHEN n BETWEEN 10 AND 12 THEN 'canceled' ELSE 'ended' END)::public.session_status,
       f.fin - CASE WHEN n = 9 THEN interval '45 minutes 30 seconds' ELSE interval '1 hour' END, f.fin,
       CASE WHEN n = 14 THEN now() END
  FROM generate_series(1, 14) n
 CROSS JOIN LATERAL (SELECT now() - CASE WHEN n <= 4 THEN interval '2 days' WHEN n <= 7 THEN interval '9 days'
                                         WHEN n <= 9 THEN interval '40 days' ELSE interval '1 day' END AS fin) f;

SET LOCAL session_replication_role = origin;
ANALYZE public.candidatures;
ANALYZE public.candidature_reponses;
ANALYZE public.profiles;

-- Le resultat memorise a moins de 10 minutes : un appel le rend TEL QUEL, sans voir la fixture (sauf l'etage direct).
INSERT INTO etat VALUES ('servi', pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()'));
-- On le vieillit de 11 minutes : l'appel suivant recalcule.
UPDATE app_private.chiffres_cache SET calcule_le = now() - interval '11 minutes';
INSERT INTO etat VALUES ('apres', pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()'));

-- L'ecart entre apres et avant, pour un chemin de la reponse.
CREATE FUNCTION pg_temp.ecart(VARIADIC p_chemin text[]) RETURNS bigint LANGUAGE sql AS $$
  SELECT ((SELECT j #>> p_chemin FROM etat WHERE quand = 'apres')::bigint
        - (SELECT j #>> p_chemin FROM etat WHERE quand = 'avant')::bigint) $$;
CREATE FUNCTION pg_temp.apres(VARIADIC p_chemin text[]) RETURNS bigint LANGUAGE sql AS $$
  SELECT (SELECT j #>> p_chemin FROM etat WHERE quand = 'apres')::bigint $$;

-- ---------------------------------------------------------------------------------------------------------------------
-- 1. DROITS
-- ---------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.verif('1a direction active : lit', $$ SELECT pg_catalog.jsonb_typeof(pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()')) = 'object' $$);
SELECT pg_temp.verif('1b comptable : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9002), 'accountant', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1c controle : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9003), 'controller', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1d enseignant actif : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(1001), 'teacher', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1e tuteur : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9005), 'guardian', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1f eleve : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9006), 'student', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1g associe : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9007), 'associe', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1h direction desactivee : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(9008), 'admin', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1i candidat (compte en attente) : refus 42501', $$ SELECT pg_temp.code_refus(pg_temp.u(1), 'teacher', 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1j sans jeton : refus 42501', $$ SELECT pg_temp.code_refus(NULL, NULL, 'SELECT public.chiffres_academie()') = '42501' $$);
SELECT pg_temp.verif('1k anon : refus 42501 (pas le droit d''executer)', $$ SELECT pg_temp.code_refus(NULL, NULL, 'SELECT public.chiffres_academie()', 'anon') = '42501' $$);
SELECT pg_temp.verif('1l droits : authenticated seul', $$
  SELECT pg_catalog.has_function_privilege('authenticated', 'public.chiffres_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('anon', 'public.chiffres_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('public', 'public.chiffres_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('agent_ro', 'public.chiffres_academie()', 'EXECUTE')
     AND NOT pg_catalog.has_function_privilege('service_role', 'public.chiffres_academie()', 'EXECUTE') $$);
SELECT pg_temp.verif('1m definer, search_path vide', $$
  SELECT p.prosecdef AND p.proconfig = ARRAY['search_path=""']
    FROM pg_catalog.pg_proc p WHERE p.oid = 'public.chiffres_academie()'::regprocedure $$);

-- ---------------------------------------------------------------------------------------------------------------------
-- 2. FORME : des nombres seulement (plus une date), rien qui designe une personne ; legere.
-- ---------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.verif('2a cles de tete', $$
  SELECT (SELECT pg_catalog.array_agg(k ORDER BY k) FROM pg_catalog.jsonb_object_keys((SELECT j FROM etat WHERE quand = 'apres')) k)
         = ARRAY['academie', 'candidats', 'declarations', 'genere_le', 'memorise_le', 'seances'] $$);
SELECT pg_temp.verif('2b toute valeur est un nombre (ou les 7 nombres de par_jour)', $$
  SELECT pg_catalog.bool_and(pg_catalog.jsonb_typeof(v.value) = 'number'
                             OR (s.key = 'candidats' AND v.key = 'par_jour' AND pg_catalog.jsonb_typeof(v.value) = 'array'))
         AND pg_catalog.count(*) = 26
    FROM pg_catalog.jsonb_each((SELECT j FROM etat WHERE quand = 'apres') - 'genere_le' - 'memorise_le') s
   CROSS JOIN LATERAL pg_catalog.jsonb_each(s.value) v $$);
SELECT pg_temp.verif('2c par_jour : 7 nombres', $$
  SELECT pg_catalog.count(*) = 7 AND pg_catalog.bool_and(pg_catalog.jsonb_typeof(x) = 'number')
    FROM pg_catalog.jsonb_array_elements((SELECT j #> '{candidats,par_jour}' FROM etat WHERE quand = 'apres')) x $$);
SELECT pg_temp.verif('2d aucun nom, aucune adresse, aucun identifiant dans la reponse', $$
  SELECT (SELECT j::text FROM etat WHERE quand = 'apres') !~* '(fictif|@|c41f|CHIF-|CAND-)' $$);
SELECT pg_temp.verif('2e reponse de moins de 700 octets', $$ SELECT pg_catalog.length((SELECT j::text FROM etat WHERE quand = 'apres')) < 700 $$);

-- ---------------------------------------------------------------------------------------------------------------------
-- 3. CHAQUE CHIFFRE = le nombre construit par la fixture (ecart apres - avant).
-- ---------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.verif('3a candidats recus : 650 (les familles ne comptent pas)', $$ SELECT pg_temp.ecart('candidats', 'recus') = 650 $$);
SELECT pg_temp.verif('3b arrives aujourd''hui : 5', $$ SELECT pg_temp.ecart('candidats', 'aujourd_hui') = 5 $$);
SELECT pg_temp.verif('3c sept derniers jours : 40', $$ SELECT pg_temp.ecart('candidats', 'sept_jours') = 40 $$);
SELECT pg_temp.verif('3d sept jours pleins (aujourd''hui exclu) : 35 ; les sept d''avant : 60', $$
  SELECT pg_temp.ecart('candidats', 'sept_pleins') = 35 AND pg_temp.ecart('candidats', 'sept_pleins_avant') = 60 $$);
SELECT pg_temp.verif('3d bis hommes + femmes = recus (meme passage, en direct)', $$
  SELECT pg_temp.ecart('candidats', 'hommes') + pg_temp.ecart('candidats', 'femmes') = pg_temp.ecart('candidats', 'recus') $$);
SELECT pg_temp.verif('3e hommes 520, femmes 130', $$ SELECT pg_temp.ecart('candidats', 'hommes') = 520 AND pg_temp.ecart('candidats', 'femmes') = 130 $$);
-- Les pays : comptage direct independant (la base peut deja en contenir).
SELECT pg_temp.verif('3f pays = comptage direct, au moins 12, BR (famille) hors compte', $$
  SELECT pg_temp.apres('candidats', 'pays') = (SELECT pg_catalog.count(*) FROM (SELECT pays_residence FROM public.candidatures
                                                 WHERE type_code = 'enseignant' AND pays_residence IS NOT NULL GROUP BY 1) x)
     AND pg_temp.apres('candidats', 'pays') >= 12
     AND (pg_temp.ecart('candidats', 'pays') = 12 OR (SELECT (j #>> '{candidats,pays}')::int FROM etat WHERE quand = 'avant') > 0) $$);
SELECT pg_temp.verif('3g par jour : 35 il y a trois jours, 5 aujourd''hui, rien d''autre', $$
  SELECT (SELECT pg_catalog.array_agg(a.x::int - b.x::int ORDER BY a.i)
            FROM pg_catalog.jsonb_array_elements_text((SELECT j #> '{candidats,par_jour}' FROM etat WHERE quand = 'apres')) WITH ORDINALITY a(x, i)
            JOIN pg_catalog.jsonb_array_elements_text((SELECT j #> '{candidats,par_jour}' FROM etat WHERE quand = 'avant')) WITH ORDINALITY b(x, i) USING (i))
         = ARRAY[0, 0, 0, 35, 0, 0, 5] $$);
SELECT pg_temp.verif('3h par jour : la somme = les sept derniers jours', $$
  SELECT (SELECT pg_catalog.sum(x::int) FROM pg_catalog.jsonb_array_elements_text((SELECT j #> '{candidats,par_jour}' FROM etat WHERE quand = 'apres')) x)
         = pg_temp.apres('candidats', 'sept_jours') $$);

SELECT pg_temp.verif('3i repondants : 600 (brouillons seuls et familles hors compte)', $$ SELECT pg_temp.ecart('declarations', 'repondants') = 600 $$);
SELECT pg_temp.verif('3j tout le Coran : 150 (la derniere reponse envoyee seule)', $$ SELECT pg_temp.ecart('declarations', 'coran_entier') = 150 $$);
SELECT pg_temp.verif('3k juz, minimum certain : 7125', $$ SELECT pg_temp.ecart('declarations', 'juz_min') = 7125 $$);
SELECT pg_temp.verif('3l ijaza : 200', $$ SELECT pg_temp.ecart('declarations', 'ijaza') = 200 $$);
SELECT pg_temp.verif('3m riwayat : hafs, warsh, qalun (ni shuba ancienne, ni rawh en brouillon, ni idris de famille)', $$
  SELECT pg_temp.apres('declarations', 'riwayat') >= 3
     AND (pg_temp.ecart('declarations', 'riwayat') = 3 OR (SELECT (j #>> '{declarations,riwayat}')::int FROM etat WHERE quand = 'avant') > 0) $$);
SELECT pg_temp.verif('3n langues : ar, francais (« autre » hors compte)', $$
  SELECT pg_temp.apres('declarations', 'langues') >= 2
     AND (pg_temp.ecart('declarations', 'langues') = 2 OR (SELECT (j #>> '{declarations,langues}')::int FROM etat WHERE quand = 'avant') > 0) $$);

SELECT pg_temp.verif('3o enseignants actifs : 9 (candidats, desactive, supprime hors compte)', $$ SELECT pg_temp.ecart('academie', 'enseignants') = 9 $$);
SELECT pg_temp.verif('3p eleves : 30', $$ SELECT pg_temp.ecart('academie', 'eleves') = 30 $$);
SELECT pg_temp.verif('3q eleves en classe : 12', $$ SELECT pg_temp.ecart('academie', 'eleves_en_classe') = 12 $$);
SELECT pg_temp.verif('3r familles : 11', $$ SELECT pg_temp.ecart('academie', 'familles') = 11 $$);
SELECT pg_temp.verif('3s classes ouvertes : 5', $$ SELECT pg_temp.ecart('academie', 'classes') = 5 $$);
SELECT pg_temp.verif('3t langues de cours = comptage direct', $$
  SELECT pg_temp.apres('academie', 'langues_cours') = (SELECT pg_catalog.count(*) FILTER (WHERE actif) FROM public.langues_cours) $$);

SELECT pg_temp.verif('3u seances tenues : 9', $$ SELECT pg_temp.ecart('seances', 'tenues') = 9 $$);
SELECT pg_temp.verif('3v minutes : 525', $$ SELECT pg_temp.ecart('seances', 'minutes') = 525 $$);
SELECT pg_temp.verif('3w seances sur sept jours : 4 ; sept jours pleins : 4 ; les sept d''avant : 3', $$
  SELECT pg_temp.ecart('seances', 'sept_jours') = 4 AND pg_temp.ecart('seances', 'sept_pleins') = 4
     AND pg_temp.ecart('seances', 'sept_pleins_avant') = 3 $$);

-- ---------------------------------------------------------------------------------------------------------------------
-- 4. LE RESULTAT MEMORISE : servi tel quel pendant 10 minutes, recalcule ensuite, ferme a tout client.
-- ---------------------------------------------------------------------------------------------------------------------
SELECT pg_temp.verif('4a servi par la memoire : les chiffres memorises ne voient pas la fixture', $$
  SELECT (SELECT j -> 'declarations' FROM etat WHERE quand = 'servi') = (SELECT j -> 'declarations' FROM etat WHERE quand = 'avant')
     AND (SELECT j -> 'academie' FROM etat WHERE quand = 'servi') = (SELECT j -> 'academie' FROM etat WHERE quand = 'avant')
     AND (SELECT j -> 'seances' FROM etat WHERE quand = 'servi') = (SELECT j -> 'seances' FROM etat WHERE quand = 'avant')
     AND (SELECT j ->> 'memorise_le' FROM etat WHERE quand = 'servi') = (SELECT j ->> 'memorise_le' FROM etat WHERE quand = 'avant') $$);
SELECT pg_temp.verif('4b servi par la memoire : l''etage direct voit tout de suite les 650 candidats', $$
  SELECT ((SELECT j #>> '{candidats,recus}' FROM etat WHERE quand = 'servi')::int
        - (SELECT j #>> '{candidats,recus}' FROM etat WHERE quand = 'avant')::int) = 650 $$);
SELECT pg_temp.verif('4c une seule ligne memorisee, des nombres seulement', $$
  SELECT pg_catalog.count(*) = 1 AND pg_catalog.bool_and(valeurs::text !~* '(fictif|@|c41f|CHIF-|CAND-)') FROM app_private.chiffres_cache $$);
SELECT pg_temp.verif('4d un appel servi par la memoire n''ecrit rien (la ligne ne change pas)', $$
  WITH a AS (SELECT xmin::text AS x, calcule_le FROM app_private.chiffres_cache),
       appel AS (SELECT pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()') AS j)
  SELECT (SELECT j IS NOT NULL FROM appel)
     AND (SELECT x FROM a) = (SELECT xmin::text FROM app_private.chiffres_cache) $$);
SELECT pg_temp.verif('4e RLS active, aucune politique', $$
  SELECT c.relrowsecurity AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_policy p WHERE p.polrelid = c.oid)
    FROM pg_catalog.pg_class c WHERE c.oid = 'app_private.chiffres_cache'::regclass $$);
SELECT pg_temp.verif('4f la direction ne lit pas la table : 42501', $$
  SELECT pg_temp.code_refus(pg_temp.u(9001), 'admin', 'SELECT 1 FROM app_private.chiffres_cache') = '42501' $$);
SELECT pg_temp.verif('4g la direction n''ecrit pas la table : 42501', $$
  SELECT pg_temp.code_refus(pg_temp.u(9001), 'admin', 'UPDATE app_private.chiffres_cache SET calcule_le = now()') = '42501' $$);
SELECT pg_temp.verif('4h anon ne lit pas la table : 42501', $$
  SELECT pg_temp.code_refus(NULL, NULL, 'SELECT 1 FROM app_private.chiffres_cache', 'anon') = '42501' $$);
SELECT pg_temp.verif('4i aucun droit de table pour anon, authenticated, agent_ro, service_role', $$
  SELECT NOT pg_catalog.bool_or(pg_catalog.has_table_privilege(r, 'app_private.chiffres_cache', d))
    FROM unnest(ARRAY['anon', 'authenticated', 'agent_ro', 'service_role']) r
   CROSS JOIN unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'REFERENCES', 'TRIGGER']) d $$);
-- Un candidat de plus, d'un pays neuf : le total en direct monte tout de suite ; le pays n'apparait qu'apres 10 minutes.
SET LOCAL session_replication_role = replica;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source, pays_residence, recue_le,
                                 derniere_activite)
VALUES (pg_temp.c(7001), 'enseignant', NULL, 'male', 'Candidat Fictif tardif', 'recue', NULL, 'en_cours', 'lien_public', 'JP', now(), now());
SET LOCAL session_replication_role = origin;
INSERT INTO etat VALUES ('plus_un', pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()'));
UPDATE app_private.chiffres_cache SET calcule_le = now() - interval '10 minutes 1 second';
INSERT INTO etat VALUES ('plus_un_recalcule', pg_temp.en(pg_temp.u(9001), 'admin', 'SELECT public.chiffres_academie()'));
SELECT pg_temp.verif('4j en direct : recus + 1 et hommes + 1 tout de suite ; pays inchange tant que la memoire est fraiche', $$
  SELECT (SELECT (j #>> '{candidats,recus}')::int FROM etat WHERE quand = 'plus_un') = pg_temp.apres('candidats', 'recus') + 1
     AND (SELECT (j #>> '{candidats,hommes}')::int FROM etat WHERE quand = 'plus_un') = pg_temp.apres('candidats', 'hommes') + 1
     AND (SELECT (j #>> '{candidats,pays}')::int FROM etat WHERE quand = 'plus_un') = pg_temp.apres('candidats', 'pays') $$);
SELECT pg_temp.verif('4k apres 10 minutes : le pays neuf est compte', $$
  SELECT (SELECT (j #>> '{candidats,pays}')::int FROM etat WHERE quand = 'plus_un_recalcule') = pg_temp.apres('candidats', 'pays') + 1 $$);

-- ---------------------------------------------------------------------------------------------------------------------
-- 5. LEGERETE, a cette echelle : duree et blocs lus d'un appel servi par la memoire, puis d'un recalcul.
-- ---------------------------------------------------------------------------------------------------------------------
CREATE TEMP TABLE mesure (quoi text, ms numeric, blocs bigint);
GRANT ALL ON mesure TO authenticated;
CREATE FUNCTION pg_temp.mesurer(p_quoi text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE v json;
BEGIN
  PERFORM pg_temp.qui(pg_temp.u(9001), 'admin');
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT public.chiffres_academie()' INTO v;
  EXECUTE 'RESET ROLE';
  INSERT INTO mesure VALUES (p_quoi, (v -> 0 ->> 'Execution Time')::numeric,
                             coalesce((v -> 0 -> 'Plan' ->> 'Shared Hit Blocks')::bigint, 0)
                             + coalesce((v -> 0 -> 'Plan' ->> 'Shared Read Blocks')::bigint, 0));
END $$;
DO $$
BEGIN
  FOR i IN 1..5 LOOP
    PERFORM pg_temp.mesurer('servi');
  END LOOP;
  FOR i IN 1..5 LOOP
    UPDATE app_private.chiffres_cache SET calcule_le = now() - interval '11 minutes';
    PERFORM pg_temp.mesurer('recalcul');
  END LOOP;
END $$;
SELECT pg_temp.note('5a appel servi par la memoire : mediane sous 5 ms',
                    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY ms) FROM mesure WHERE quoi = 'servi') < 5,
                    (SELECT 'mediane ' || round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ms)::numeric, 2) || ' ms, max '
                            || round(max(ms), 2) || ' ms, blocs lus ' || max(blocs) FROM mesure WHERE quoi = 'servi'));
SELECT pg_temp.note('5b recalcul (au plus toutes les 10 minutes) : mediane sous 50 ms',
                    (SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY ms) FROM mesure WHERE quoi = 'recalcul') < 50,
                    (SELECT 'mediane ' || round(percentile_cont(0.5) WITHIN GROUP (ORDER BY ms)::numeric, 2) || ' ms, max '
                            || round(max(ms), 2) || ' ms, blocs lus ' || max(blocs) FROM mesure WHERE quoi = 'recalcul'));

\o
SELECT nom, CASE WHEN ok THEN 'ok' ELSE 'ROUGE' END AS etat, left(detail, 110) AS detail FROM res ORDER BY nom;
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM res WHERE NOT ok) THEN
    RAISE EXCEPTION 'CHIFFRES-ACADEMIE : % verification(s) en ROUGE', (SELECT count(*) FROM res WHERE NOT ok);
  END IF;
END $$;
ROLLBACK;
