-- CAND-L3, reprise apres relecture (23/10) : l'inscription publique tient quand deux
-- transactions se croisent. Migration
-- 20261022000600_cand_l3_inscription_import_rapprochement.sql.
--
-- (1) Le plafond d'inscriptions par heure. Sans verrou, deux inscriptions qui
-- arrivent ensemble lisent le meme compteur et passent toutes les deux : le
-- plafond se contournerait en parallele. Ici la premiere tient sa transaction
-- ouverte apres avoir ecrit ; la seconde doit ATTENDRE (dblink_is_busy), puis
-- recevoir la reponse neutre (acceptee) sans rien ecrire, car le plafond est atteint.
-- (2) La ligne « pour suivi » reprise par la personne qui s'inscrit. Sans verrou,
-- la direction retire la ligne pendant que l'inscription la lit : l'inscription
-- la reprendrait quand meme et la garderait retiree. Ici une transaction retire la
-- ligne (une ecriture simple : un geste du moteur, lui, serialise deja toute la
-- suite par le verrou du journal d'audit, ce qui cacherait le verrou de la ligne) et
-- reste ouverte ; l'inscription lit la ligne encore en cours, doit ATTENDRE sur son
-- verrou, puis la relire retiree, ne pas la reprendre, et creer une candidature neuve.
--
-- Ce scenario VALIDE ses donnees (deux sessions doivent les voir) : a rejouer sur
-- une base NEUVE et jetable (stub_auth puis toutes les migrations ;
-- tool/rejouer_scenarios.sh en donne une a chaque scenario). Il ne retire que ce
-- qui n'est pas une donnee (schema d'aide, extension dblink s'il l'a creee) : les
-- comptes, candidatures et accords qu'il pose sont en ajout seul ou lies entre eux.
-- (3) L'import et l'inscription. Chacun rapproche ce qu'il ecrit de ce que l'autre
-- a ecrit : si les deux se croisent, aucun ne voit l'autre (leurs ecritures ne sont
-- pas encore validees) et la personne n'est jamais reliee a sa reponse importee. Ici,
-- dans les deux ordres, la seconde session doit ATTENDRE la premiere (verrou de
-- l'import, pris en exclusif par l'import et en partage par l'inscription), puis la
-- ligne importee est reliee a la candidature par le courriel confirme.
-- Contre-epreuve : sans le verrou du plafond, sans le verrou de la ligne reprise ou
-- sans le verrou de l'import, la seconde session n'attend pas et passe ; le
-- scenario echoue.
-- Aucune donnee reelle : adresses en @test.invalid, numeros fictifs.

CREATE SCHEMA cand_l3_concurrence;
DO $dblink$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_extension WHERE extname = 'dblink') THEN
    CREATE EXTENSION dblink SCHEMA cand_l3_concurrence;
    PERFORM pg_catalog.set_config('test.dblink_cree', 'oui', false);
  END IF;
END $dblink$;
SELECT pg_catalog.set_config('search_path', 'public, ' || n.nspname, false)
FROM pg_catalog.pg_extension e JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
WHERE e.extname = 'dblink';
SELECT pg_catalog.set_config('test.conninfo', pg_catalog.format('dbname=%s user=%s port=%s host=%s',
  pg_catalog.current_database(), current_user, pg_catalog.current_setting('port'),
  pg_catalog.split_part(pg_catalog.current_setting('unix_socket_directories'), ',', 1)), false);

-- Un appel sous le role authenticated, au nom d'un compte : ce que fait la
-- passerelle. La transaction reste ouverte apres l'appel (BEGIN de l'appelant).
CREATE FUNCTION cand_l3_concurrence.appel(p_uid uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  -- p_role : le role de l'application, suivi de « :aal2 » pour une double verification.
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_uid::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_uid, 'role', 'authenticated',
    'aal', coalesce(nullif(pg_catalog.split_part(coalesce(p_role, ''), ':', 2), ''), 'aal1'),
    'app_metadata', CASE WHEN nullif(pg_catalog.split_part(coalesce(p_role, ''), ':', 1), '') IS NULL
                         THEN pg_catalog.json_build_object()
                         ELSE pg_catalog.json_build_object('role', pg_catalog.split_part(p_role, ':', 1)) END)::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

-- Fixtures (donnees inventees) : deux inscrites pour le plafond, une inscrite
-- pour la ligne de suivi, cette ligne, deux inscrites pour l'import, et le super-admin.
INSERT INTO auth.users (id, email, email_confirmed_at) VALUES
 ('cb3c0000-0000-4000-8000-0000000000c1', 'cand-l3c-1@test.invalid', now()),
 ('cb3c0000-0000-4000-8000-0000000000c2', 'cand-l3c-2@test.invalid', now()),
 ('cb3c0000-0000-4000-8000-0000000000c3', 'cand-l3c-3@test.invalid', now()),
 ('cb3c0000-0000-4000-8000-0000000000c4', 'cand-l3c-4@test.invalid', now()),
 ('cb3c0000-0000-4000-8000-0000000000c5', 'cand-l3c-5@test.invalid', now()),
 ('cb3c0000-0000-4000-8000-0000000000a1', 'cand-l3c-sa@test.invalid', now());
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES ('cb3c0000-0000-4000-8000-0000000000a1', 'CB3C-ADM-0001', 'admin', NULL, 'Super', 'Admin', 'active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES ('cb3c0000-0000-4000-8000-0000000000a1');
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'candidatures.inscription_publique_ouverte';
UPDATE public.app_config SET value = '1'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
-- La ligne gardee pour suivi (transition 2), au courriel de la troisieme inscrite.
INSERT INTO public.candidatures (id, type_code, genre, nom_complet, etape, issue, source, source_ref)
VALUES ('cb3c0000-0000-4000-8000-000000000f01', 'enseignant', 'female', 'Essai Ligne Suivie', 'recue', 'en_cours',
        'import', 'Classeur CC|A|2026-12-31 10:00:00');
INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
VALUES ('cb3c0000-0000-4000-8000-000000000f01', 'cand-l3c-3@test.invalid', '+966500000931');

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, false);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.rouge(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.rouges',
    coalesce(nullif(pg_catalog.current_setting('test.rouges', true), ''), '') || ' | ' || p_label, false);
  RAISE NOTICE 'ROUGE %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    PERFORM pg_temp.rouge(p_label);
  ELSE
    PERFORM pg_temp.ok(p_label);
  END IF;
END $$;

-- Un croisement : la session 1 appelle (ou, sans compte, ecrit en proprietaire) puis
-- garde sa transaction ouverte ; la session 2 appelle pendant ce temps. Vrai quand
-- la seconde a attendu la premiere ; garde le resultat de chacune. La seconde valide ensuite.
CREATE FUNCTION pg_temp.croisement(p_label text, p_uid1 uuid, p_role1 text, p_sql1 text,
                                   p_uid2 uuid, p_role2 text, p_sql2 text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_attend boolean;
  v_r1 jsonb;
  v_r2 jsonb;
BEGIN
  PERFORM dblink_connect('cand_l3_t1', pg_catalog.current_setting('test.conninfo'));
  PERFORM dblink_connect('cand_l3_t2', pg_catalog.current_setting('test.conninfo'));
  PERFORM dblink_exec('cand_l3_t1', 'BEGIN');
  IF p_uid1 IS NULL THEN
    PERFORM dblink_exec('cand_l3_t1', p_sql1);
  ELSE
    SELECT t.r INTO v_r1 FROM dblink('cand_l3_t1', pg_catalog.format('SELECT cand_l3_concurrence.appel(%L::uuid, %L, %L)',
      p_uid1, p_role1, p_sql1)) AS t(r jsonb);
  END IF;
  PERFORM dblink_exec('cand_l3_t2', 'BEGIN');
  PERFORM dblink_send_query('cand_l3_t2', pg_catalog.format('SELECT cand_l3_concurrence.appel(%L::uuid, %L, %L)',
    p_uid2, p_role2, p_sql2));
  PERFORM pg_catalog.pg_sleep(0.5);
  v_attend := dblink_is_busy('cand_l3_t2') = 1;
  PERFORM dblink_exec('cand_l3_t1', 'COMMIT');
  SELECT t.r INTO v_r2 FROM dblink_get_result('cand_l3_t2') AS t(r jsonb);
  PERFORM * FROM dblink_get_result('cand_l3_t2', false) AS t(r jsonb);
  PERFORM dblink_exec('cand_l3_t2', 'COMMIT');
  PERFORM dblink_disconnect('cand_l3_t1');
  PERFORM dblink_disconnect('cand_l3_t2');
  PERFORM pg_catalog.set_config('test.r1', coalesce(v_r1::text, 'null'), false);
  PERFORM pg_catalog.set_config('test.r2', coalesce(v_r2::text, 'null'), false);
  PERFORM pg_temp.vrai(v_attend, p_label || ' : la seconde session attend la premiere');
END $$;

-- (1) le plafond : une seule inscription par heure ; deux inscrites ensemble, la seconde attend.
SELECT pg_temp.croisement('plafond',
  'cb3c0000-0000-4000-8000-0000000000c1', NULL,
  $q$SELECT public.inscrire_candidat(NULL, 'Essai', 'Un', 'female', '+966500000921', 'fr', '2026-10-v1')$q$,
  'cb3c0000-0000-4000-8000-0000000000c2', NULL,
  $q$SELECT public.inscrire_candidat(NULL, 'Essai', 'Deux', 'female', '+966500000922', 'fr', '2026-10-v1')$q$);
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.r1')::jsonb = '{"resultat": "acceptee"}'::jsonb
  AND pg_catalog.current_setting('test.r2')::jsonb = '{"resultat": "acceptee"}'::jsonb,
  'plafond : les deux inscrites recoivent la meme reponse (acceptee)');
SELECT pg_temp.vrai(
  EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb3c0000-0000-4000-8000-0000000000c1')
  AND NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = 'cb3c0000-0000-4000-8000-0000000000c2')
  AND NOT EXISTS (SELECT 1 FROM public.candidatures WHERE profile_id = 'cb3c0000-0000-4000-8000-0000000000c2')
  AND NOT EXISTS (SELECT 1 FROM public.candidat_accords_confidentialite WHERE profile_id = 'cb3c0000-0000-4000-8000-0000000000c2')
  AND (SELECT count(*) FROM private.inscriptions_publiques) = 1,
  'plafond : la premiere est inscrite, la seconde n''a laisse ni compte, ni candidature, ni accord ; un seul passage compte');

-- (2) la ligne gardee pour suivi : retiree pendant que sa personne s'inscrit.
UPDATE public.app_config SET value = '60'::jsonb WHERE key = 'candidatures.inscriptions_par_heure';
SELECT pg_temp.croisement('retrait puis inscription',
  NULL, NULL,
  $q$UPDATE public.candidatures SET issue = 'retiree', version = version + 1
      WHERE id = 'cb3c0000-0000-4000-8000-000000000f01'$q$,
  'cb3c0000-0000-4000-8000-0000000000c3', NULL,
  $q$SELECT public.inscrire_candidat(NULL, 'Essai', 'Trois', 'female', '+966500000931', 'fr', '2026-10-v1')$q$);
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.r2')::jsonb = '{"resultat": "acceptee"}'::jsonb,
  'retrait puis inscription : l''inscription est acceptee');
SELECT pg_temp.vrai(
  (SELECT issue = 'retiree' AND profile_id IS NULL AND etape = 'recue'
     FROM public.candidatures WHERE id = 'cb3c0000-0000-4000-8000-000000000f01')
  AND (SELECT count(*) FROM public.candidatures WHERE profile_id = 'cb3c0000-0000-4000-8000-0000000000c3') = 1
  AND (SELECT id <> 'cb3c0000-0000-4000-8000-000000000f01' AND etape = 'prequalification' AND issue = 'en_cours'
         FROM public.candidatures WHERE profile_id = 'cb3c0000-0000-4000-8000-0000000000c3'),
  'retrait puis inscription : la ligne retiree reste retiree et sans compte, la personne a une candidature neuve en cours');

-- (3) L'import et l'inscription. Un fichier d'une ligne (en-tetes reconnus par leur
-- texte, comme tout export), au courriel de la personne qui s'inscrit.
CREATE FUNCTION cand_l3_concurrence.csv(p_h text, p_nom text, p_courriel text) RETURNS text
LANGUAGE sql IMMUTABLE AS $$
  SELECT 'Horodateur,هل أنت,الاسم الكامل,البريد الألكتروني' || E'\n'
      || p_h || ',أنثى,' || p_nom || ',' || p_courriel || E'\n'
$$;
-- La confirmation d'un import, avec le jeton d'un essai a blanc fait AVANT, dans sa
-- propre transaction (comme l'ecran : l'essai a blanc et la confirmation sont deux
-- appels). Un essai a blanc dans la meme transaction ecrirait une ligne d'audit
-- d'entree, et le journal d'audit (qui serialise ses ecritures) ferait attendre la
-- seconde session pour une autre raison que le verrou de l'import. Le jeton est donc
-- pris par une requete a part, qui valide, et gardee dans un reglage de la session.
CREATE FUNCTION cand_l3_concurrence.apercu(p_cle text, p_csv text, p_onglet text) RETURNS void
LANGUAGE sql VOLATILE AS $$
  SELECT pg_catalog.set_config('test.jeton_' || p_cle, cand_l3_concurrence.appel(
    'cb3c0000-0000-4000-8000-0000000000a1'::uuid, 'admin:aal2',
    pg_catalog.format('SELECT public.apercu_import_formulaires(%L, %L, %L)', p_csv, 'Classeur CC', p_onglet)) ->> 'jeton', false)
$$;
CREATE FUNCTION cand_l3_concurrence.import_sql(p_cle text, p_csv text, p_onglet text) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT pg_catalog.format($q$SELECT public.confirmer_import_formulaires(%1$L, 'Classeur CC', %2$L, %3$L, '[]', %4$L)$q$,
    p_csv, p_onglet, pg_catalog.current_setting('test.jeton_' || p_cle), 'cle-conc-' || p_cle)
$$;

-- L'import d'abord (session 1, ligne ecrite et non validee), l'inscription ensuite
-- (session 2, courriel confirme du meme cote) : elle attend, puis relie.
SELECT cand_l3_concurrence.apercu('x1',
  cand_l3_concurrence.csv('2027-06-01 10:00:00', 'Essai Femme Croisee Un', 'cand-l3c-4@test.invalid'), 'X1');
SELECT pg_temp.croisement('import puis inscription',
  'cb3c0000-0000-4000-8000-0000000000a1', 'admin:aal2',
  cand_l3_concurrence.import_sql('x1',
    cand_l3_concurrence.csv('2027-06-01 10:00:00', 'Essai Femme Croisee Un', 'cand-l3c-4@test.invalid'), 'X1'),
  'cb3c0000-0000-4000-8000-0000000000c4', NULL,
  $q$SELECT public.inscrire_candidat(NULL, 'Essai', 'Quatre', 'female', '+966500000941', 'fr', '2026-10-v1')$q$);
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.r1')::jsonb @> '{"ecritureEffectuee": true}'::jsonb
  AND pg_catalog.current_setting('test.r2')::jsonb = '{"resultat": "acceptee"}'::jsonb
  AND (SELECT r.candidature_id = c.id AND r.rattachement = 'courriel' AND r.etat = 'active'
         FROM public.formulaires_reponses r, public.candidatures c
        WHERE r.reference_source = 'Classeur CC|X1|2027-06-01 10:00:00'
          AND c.profile_id = 'cb3c0000-0000-4000-8000-0000000000c4'),
  'import puis inscription : la reponse importee est reliee a la candidature par le courriel confirme');

-- L'inscription d'abord (session 1, candidature ecrite et non validee), l'import ensuite
-- (session 2) : il attend, puis relie la ligne qu'il ecrit a la personne deja inscrite.
SELECT cand_l3_concurrence.apercu('x2',
  cand_l3_concurrence.csv('2027-06-02 10:00:00', 'Essai Femme Croisee Deux', 'cand-l3c-5@test.invalid'), 'X2');
SELECT pg_temp.croisement('inscription puis import',
  'cb3c0000-0000-4000-8000-0000000000c5', NULL,
  $q$SELECT public.inscrire_candidat(NULL, 'Essai', 'Cinq', 'female', '+966500000942', 'fr', '2026-10-v1')$q$,
  'cb3c0000-0000-4000-8000-0000000000a1', 'admin:aal2',
  cand_l3_concurrence.import_sql('x2',
    cand_l3_concurrence.csv('2027-06-02 10:00:00', 'Essai Femme Croisee Deux', 'cand-l3c-5@test.invalid'), 'X2'));
SELECT pg_temp.vrai(
  pg_catalog.current_setting('test.r1')::jsonb = '{"resultat": "acceptee"}'::jsonb
  AND pg_catalog.current_setting('test.r2')::jsonb @> '{"ecritureEffectuee": true}'::jsonb
  AND (SELECT r.candidature_id = c.id AND r.rattachement = 'courriel' AND r.etat = 'active'
         FROM public.formulaires_reponses r, public.candidatures c
        WHERE r.reference_source = 'Classeur CC|X2|2027-06-02 10:00:00'
          AND c.profile_id = 'cb3c0000-0000-4000-8000-0000000000c5'),
  'inscription puis import : la reponse que l''import ecrit est reliee a la personne deja inscrite');

-- L'aide d'appel et l'extension : ce que le scenario a pose hors donnees.
RESET search_path;
DROP FUNCTION cand_l3_concurrence.import_sql(text, text, text);
DROP FUNCTION cand_l3_concurrence.apercu(text, text, text);
DROP FUNCTION cand_l3_concurrence.appel(uuid, text, text);
DROP FUNCTION cand_l3_concurrence.csv(text, text, text);
DO $retrait$
BEGIN
  IF pg_catalog.current_setting('test.dblink_cree', true) = 'oui' THEN
    DROP EXTENSION dblink;
  END IF;
END $retrait$;
DROP SCHEMA cand_l3_concurrence;

DO $fin$
BEGIN
  IF coalesce(nullif(pg_catalog.current_setting('test.rouges', true), ''), '') <> '' THEN
    RAISE EXCEPTION 'CAND-L3 CONCURRENCE ROUGE : % controles verts ; rouges :%',
      coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0'),
      pg_catalog.current_setting('test.rouges');
  END IF;
  IF pg_catalog.current_setting('test.n')::int <> 10 THEN
    RAISE EXCEPTION 'CAND-L3 CONCURRENCE ROUGE : % controles executes, 10 attendus',
      pg_catalog.current_setting('test.n');
  END IF;
  RAISE NOTICE 'CAND-L3 concurrence : % controles verts', pg_catalog.current_setting('test.n');
END $fin$;
