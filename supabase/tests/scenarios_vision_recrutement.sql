-- VISION-RECRUTEMENT (14/11/2026 ; migration 20261126500000) : le super-admin
-- agit aussi en lot, et la direction voit « qui attend quoi ».
--
-- Ce que le scenario prouve :
--   a. une direction homme, non super-admin, qui demande l'apercu d'un lot
--      (mise en pause, refus) sur une candidate femme : exclue, raison
--      hors_portee, la tentative tracee (candidature_hors_portee) ;
--   b. le super-admin homme (exception active) : la meme candidate est
--      eligible, le lot s'execute avec le jeton de l'apercu (pause, puis refus
--      d'une autre candidate), la candidature change, le journal sensible
--      porte super_admin_hors_cote, aucune trace hors portee a son nom ;
--   c. exception coupee (kyc_exception_super_admin = false) : le meme
--      super-admin est borne a son cote, comme toute direction ;
--   d. attentes_recrutement() : les nombres de chaque lecteur egalent les
--      fixtures (son cote seul pour une direction, les deux pour le
--      super-admin), la piece en attente comptee, la pause a part et hors des
--      etats ;
--   e. droits : aucun EXECUTE pour anon, un enseignant refuse (42501), une
--      direction au genre inconnu refusee (42501).
--
-- Base PostgreSQL jetable apres stub_auth.sql et toutes les migrations.
-- Donnees inventees. Tout est annule a la fin.
BEGIN;

CREATE FUNCTION pg_temp.ok(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('test.n',
    (coalesce(nullif(pg_catalog.current_setting('test.n', true), ''), '0')::int + 1)::text, true);
  RAISE NOTICE 'OK %', p_label;
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('vision-recrutement-p-' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('vision-recrutement-c-' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.s(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('vision-recrutement-s-' || p_n)::uuid $$;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', CASE WHEN p_id IS NULL THEN '{}' ELSE
    pg_catalog.json_build_object('sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
      'app_metadata', pg_catalog.json_build_object('role', p_role))::text END, true);
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb $$;

-- Un appel sous le role authenticated, au nom d'un compte ; le resultat jsonb
-- est rendu apres retour au proprietaire.
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

-- Un appel qui doit etre refuse avec ce code.
CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text,
                                 p_db_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE pg_catalog.format('SET LOCAL ROLE %I', p_db_role);
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Le nombre d'un etat dans une reponse de attentes_recrutement().
CREATE FUNCTION pg_temp.n(p_j jsonb, p_etat text) RETURNS integer
LANGUAGE sql IMMUTABLE AS $$ SELECT coalesce((p_j -> 'etats' -> p_etat ->> 'nombre')::int, 0) $$;
-- Les ecarts entre deux reponses (apres - avant), en nombres seulement.
CREATE FUNCTION pg_temp.ecart(p_apres jsonb, p_avant jsonb) RETURNS jsonb
LANGUAGE sql IMMUTABLE AS $$
  SELECT pg_catalog.jsonb_build_object(
    'a_completer', pg_temp.n(p_apres, 'a_completer') - pg_temp.n(p_avant, 'a_completer'),
    'en_examen', pg_temp.n(p_apres, 'en_examen') - pg_temp.n(p_avant, 'en_examen'),
    'entretien_planifie', pg_temp.n(p_apres, 'entretien_planifie') - pg_temp.n(p_avant, 'entretien_planifie'),
    'piece', coalesce((p_apres #>> '{pieceAValider,nombre}')::int, 0)
             - coalesce((p_avant #>> '{pieceAValider,nombre}')::int, 0),
    'pause', (p_apres ->> 'enPause')::int - (p_avant ->> 'enPause')::int,
    'creneaux', (p_apres ->> 'creneauxOuverts')::int - (p_avant ->> 'creneauxOuverts')::int,
    'entretiens', (p_apres ->> 'entretiensSansIssue')::int - (p_avant ->> 'entretiensSansIssue')::int,
    'deuxCotes', p_apres -> 'deuxCotes')
$$;

-- Les traces hors portee d'une candidature.
CREATE FUNCTION pg_temp.hp(p_id uuid) RETURNS integer
LANGUAGE sql AS $$
  SELECT pg_catalog.count(*)::int FROM public.audit_logs a
   WHERE a.row_id = p_id::text AND a.action = 'candidature_hors_portee'
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.c(text), pg_temp.s(text)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- dm direction homme (non super-admin), df direction femme, sa super-admin
-- homme (exception active), dx direction au genre inconnu, en enseignant (provisoire).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(x), 'vision-recrutement-' || x || '@test.invalid'
  FROM unnest(ARRAY['dm', 'df', 'sa', 'dx', 'en']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('dm'), 'VISREC-DM', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
       (pg_temp.p('df'), 'VISREC-DF', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
       (pg_temp.p('sa'), 'VISREC-SA', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
       (pg_temp.p('dx'), 'VISREC-DX', 'admin', NULL, 'Direction', 'Inconnue', 'active', NULL),
       (pg_temp.p('en'), 'VISREC-EN', 'teacher', NULL, 'Enseignant', 'Provisoire', 'provisional_active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('sa'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

-- Les reponses de reference avant les candidatures du scenario (la base peut
-- en porter d'autres : on compare des ecarts).
SELECT pg_temp.garde('av_dm', pg_temp.en(pg_temp.p('dm'), 'admin', 'SELECT public.attentes_recrutement()'));
SELECT pg_temp.garde('av_df', pg_temp.en(pg_temp.p('df'), 'admin', 'SELECT public.attentes_recrutement()'));
SELECT pg_temp.garde('av_sa', pg_temp.en(pg_temp.p('sa'), 'admin', 'SELECT public.attentes_recrutement()'));

-- Candidatures : m1 homme en examen ; m2 homme a completer avec piece en
-- attente ; m3 homme a completer en pause ; m4 homme refuse ; m5 homme en
-- entretien planifie (entretien sans issue) ; f1 femme en examen (cible du
-- lot de pause) ; f2 femme a completer avec piece en attente ; f3 femme a
-- completer (cible du lot de refus).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(x), 'vision-recrutement-' || x || '@test.invalid'
  FROM unnest(ARRAY['m1', 'm2', 'm3', 'm4', 'm5', 'f1', 'f2', 'f3']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
SELECT pg_temp.p(x), 'VISREC-' || pg_catalog.upper(x), 'teacher', NULL, 'Candidat', 'Fictif', 'pending_kyc',
       CASE WHEN x LIKE 'm%' THEN 'male' ELSE 'female' END::public.gender
  FROM unnest(ARRAY['m1', 'm2', 'm3', 'm4', 'm5', 'f1', 'f2', 'f3']) AS x;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause,
                                 pause_modele, issue_modele, source)
VALUES
 (pg_temp.c('m1'), 'enseignant', pg_temp.p('m1'), 'male', 'Fixture VISREC m1', 'prequalification', 'en_examen', 'en_cours', false, NULL, NULL, 'lien_public'),
 (pg_temp.c('m2'), 'enseignant', pg_temp.p('m2'), 'male', 'Fixture VISREC m2', 'prequalification', 'a_completer', 'en_cours', false, NULL, NULL, 'lien_public'),
 (pg_temp.c('m3'), 'enseignant', pg_temp.p('m3'), 'male', 'Fixture VISREC m3', 'prequalification', 'a_completer', 'en_cours', true, 'pause_general', NULL, 'lien_public'),
 (pg_temp.c('m4'), 'enseignant', pg_temp.p('m4'), 'male', 'Fixture VISREC m4', 'prequalification', 'en_examen', 'refusee', false, NULL, 'refus_general', 'lien_public'),
 (pg_temp.c('m5'), 'enseignant', pg_temp.p('m5'), 'male', 'Fixture VISREC m5', 'verifications', 'entretien_planifie', 'en_cours', false, NULL, NULL, 'lien_public'),
 (pg_temp.c('f1'), 'enseignant', pg_temp.p('f1'), 'female', 'Fixture VISREC f1', 'prequalification', 'en_examen', 'en_cours', false, NULL, NULL, 'lien_public'),
 (pg_temp.c('f2'), 'enseignant', pg_temp.p('f2'), 'female', 'Fixture VISREC f2', 'prequalification', 'a_completer', 'en_cours', false, NULL, NULL, 'lien_public'),
 (pg_temp.c('f3'), 'enseignant', pg_temp.p('f3'), 'female', 'Fixture VISREC f3', 'prequalification', 'a_completer', 'en_cours', false, NULL, NULL, 'lien_public');

-- Les pieces deposees (voie serveur), en attente.
INSERT INTO public.kyc_documents (profile_id, doc_type, object_key)
VALUES (pg_temp.p('m2'), 'passport', 'visrec/m2.jpg'),
       (pg_temp.p('f2'), 'passport', 'visrec/f2.jpg');

-- L'entretien de m5, a venir, sans issue.
INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type)
VALUES (pg_temp.s('m5'), pg_temp.p('dm'), now() + interval '2 days', now() + interval '2 days 45 minutes',
        'planned', 'entretien');
INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par)
VALUES (pg_temp.s('m5'), pg_temp.c('m5'), pg_temp.p('m5'), pg_temp.p('dm'));

-- Creneaux : un ouvert a venir de chaque cote ; cote homme, un passe et un
-- annule, jamais comptes.
INSERT INTO public.entretien_creneaux (cote, debut, duree_minutes, langues, ouvert_par, annule_par, annule_le)
VALUES ('male', now() + interval '3 days', 30, ARRAY['fr'], pg_temp.p('dm'), NULL, NULL),
       ('female', now() + interval '3 days', 30, ARRAY['fr'], pg_temp.p('df'), NULL, NULL),
       ('male', now() - interval '3 days', 30, ARRAY['fr'], pg_temp.p('dm'), NULL, NULL),
       ('male', now() + interval '4 days', 30, ARRAY['fr'], pg_temp.p('dm'), pg_temp.p('dm'), now());

-- ------------------------------------------------------------
-- d. Qui attend quoi
-- ------------------------------------------------------------
SELECT pg_temp.garde('at_dm', pg_temp.en(pg_temp.p('dm'), 'admin', 'SELECT public.attentes_recrutement()'));
SELECT pg_temp.garde('at_df', pg_temp.en(pg_temp.p('df'), 'admin', 'SELECT public.attentes_recrutement()'));
SELECT pg_temp.garde('at_sa', pg_temp.en(pg_temp.p('sa'), 'admin', 'SELECT public.attentes_recrutement()'));

SELECT pg_temp.vrai(pg_temp.ecart(pg_temp.lu('at_dm'), pg_temp.lu('av_dm'))
  = '{"a_completer": 1, "en_examen": 1, "entretien_planifie": 1, "piece": 1, "pause": 1, "creneaux": 1,
      "entretiens": 1, "deuxCotes": false}'::jsonb,
  'attentes, direction homme : son cote seul (examen 1, a completer 1 hors pause, entretien 1, piece 1, pause 1, creneau 1)');
SELECT pg_temp.vrai(pg_temp.ecart(pg_temp.lu('at_df'), pg_temp.lu('av_df'))
  = '{"a_completer": 2, "en_examen": 1, "entretien_planifie": 0, "piece": 1, "pause": 0, "creneaux": 1,
      "entretiens": 0, "deuxCotes": false}'::jsonb,
  'attentes, direction femme : son cote seul, rien du cote homme');
SELECT pg_temp.vrai(pg_temp.ecart(pg_temp.lu('at_sa'), pg_temp.lu('av_sa'))
  = '{"a_completer": 3, "en_examen": 2, "entretien_planifie": 1, "piece": 2, "pause": 1, "creneaux": 2,
      "entretiens": 1, "deuxCotes": true}'::jsonb,
  'attentes, super-admin : les deux cotes, deuxCotes vrai');
SELECT pg_temp.vrai(
  NOT (pg_temp.lu('at_dm') ->> 'deuxCotes')::boolean
  AND (pg_temp.lu('at_dm') #>> '{etats,en_examen,plusAncien}') IS NOT NULL
  AND (pg_temp.lu('at_dm') #>> '{pieceAValider,plusAncien}') IS NOT NULL
  AND pg_temp.lu('at_sa')::text NOT LIKE '%Fixture VISREC%'
  AND pg_temp.lu('at_sa')::text NOT LIKE '%' || pg_temp.c('m1')::text || '%',
  'attentes : des nombres et des dates seulement, aucun nom ni identifiant');
-- La pause : hors des etats, comptee a part (m3 est a completer, en pause).
UPDATE public.candidatures SET en_pause = false, pause_modele = NULL WHERE id = pg_temp.c('m3');
SELECT pg_temp.vrai(pg_temp.ecart(
    pg_temp.en(pg_temp.p('dm'), 'admin', 'SELECT public.attentes_recrutement()'), pg_temp.lu('at_dm'))
  = '{"a_completer": 1, "en_examen": 0, "entretien_planifie": 0, "piece": 0, "pause": -1, "creneaux": 0,
      "entretiens": 0, "deuxCotes": false}'::jsonb,
  'attentes : la pause levee, la candidature quitte enPause et revient dans son etat');
UPDATE public.candidatures SET en_pause = true, pause_modele = 'pause_general' WHERE id = pg_temp.c('m3');
-- La piece decidee ne compte plus.
UPDATE public.kyc_documents SET status = 'rejected', verified_by = pg_temp.p('dm'), verified_at = now(),
       rejection_reason = 'Essai du scenario'
 WHERE object_key = 'visrec/m2.jpg';
SELECT pg_temp.vrai(pg_temp.ecart(
    pg_temp.en(pg_temp.p('dm'), 'admin', 'SELECT public.attentes_recrutement()'), pg_temp.lu('at_dm'))
  = '{"a_completer": 0, "en_examen": 0, "entretien_planifie": 0, "piece": -1, "pause": 0, "creneaux": 0,
      "entretiens": 0, "deuxCotes": false}'::jsonb,
  'attentes : une piece decidee (refusee) ne compte plus dans pieceAValider');

-- ------------------------------------------------------------
-- e. Les droits
-- ------------------------------------------------------------
SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.attentes_recrutement()', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.attentes_recrutement()', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.attentes_recrutement()', 'EXECUTE'),
  'droits : aucun EXECUTE pour anon ni PUBLIC, authenticated seulement');
SELECT pg_temp.refus_en(NULL, NULL, 'SELECT public.attentes_recrutement()', '42501',
  'anon : refuse (42501)', 'anon');
SELECT pg_temp.refus_en(pg_temp.p('en'), 'teacher', 'SELECT public.attentes_recrutement()', '42501',
  'enseignant : refuse (42501)');
SELECT pg_temp.refus_en(pg_temp.p('dx'), 'admin', 'SELECT public.attentes_recrutement()', '42501',
  'direction au genre inconnu : refusee (42501)');

-- ------------------------------------------------------------
-- a. Direction homme non super-admin : la candidate femme est hors portee
-- ------------------------------------------------------------
SELECT pg_temp.garde('hp_f1', to_jsonb(pg_temp.hp(pg_temp.c('f1'))));
SELECT pg_temp.garde('ap_dm', pg_temp.en(pg_temp.p('dm'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('f1'), pg_temp.c('m1')])$$));
SELECT pg_temp.vrai((pg_temp.lu('ap_dm') ->> 'nombre')::int = 1
  AND pg_temp.lu('ap_dm') -> 'exclus' = jsonb_build_array(jsonb_build_object('id', pg_temp.c('f1'), 'raison', 'hors_portee'))
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('ap_dm') -> 'eligibles') e
        WHERE e ->> 'id' = pg_temp.c('m1')::text) = 1
  AND pg_temp.lu('ap_dm')::text NOT LIKE '%Fixture VISREC f1%'
  AND pg_temp.hp(pg_temp.c('f1')) = pg_temp.lu('hp_f1')::int + 1
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = pg_temp.c('f1')::text AND a.action = 'candidature_hors_portee'
          AND a.actor = pg_temp.p('dm') AND a.payload ->> 'lecture' = 'lot:mettre_en_pause') = 1,
  'a. direction homme, pause en lot : la candidate femme exclue (hors_portee), sans donnee, la tentative tracee');
SELECT pg_temp.garde('ap_dm_r', pg_temp.en(pg_temp.p('dm'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('f3')])$$));
SELECT pg_temp.vrai((pg_temp.lu('ap_dm_r') ->> 'nombre')::int = 0
  AND pg_temp.lu('ap_dm_r') -> 'exclus' = jsonb_build_array(jsonb_build_object('id', pg_temp.c('f3'), 'raison', 'hors_portee'))
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = pg_temp.c('f3')::text AND a.action = 'candidature_hors_portee'
          AND a.actor = pg_temp.p('dm') AND a.payload ->> 'lecture' = 'lot:refuser') = 1,
  'a. direction homme, refus en lot : la candidate femme exclue (hors_portee), la tentative tracee');
-- Son jeton n'ouvre rien sur la candidate femme : la ligne reste exclue.
SELECT pg_temp.garde('ex_dm', pg_temp.en(pg_temp.p('dm'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('f1'), pg_temp.c('m1')],
    pg_temp.lu('ap_dm') ->> 'jeton', 1, 'cle-visrec-dm-1', 'Motif interne VISREC', 'pause_attente_besoin')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex_dm') @> '{"reussies": 1, "exclues": 1, "refusees": 0}'::jsonb
  AND (SELECT NOT en_pause AND version = 1 FROM public.candidatures WHERE id = pg_temp.c('f1'))
  AND (SELECT en_pause FROM public.candidatures WHERE id = pg_temp.c('m1')),
  'a. direction homme, execution : son cote seul change, la candidate femme reste intacte');

-- ------------------------------------------------------------
-- b. Le super-admin agit en lot des deux cotes
-- ------------------------------------------------------------
SELECT pg_temp.garde('hp_sa', to_jsonb((SELECT count(*) FROM public.audit_logs
                                         WHERE action = 'candidature_hors_portee' AND actor = pg_temp.p('sa'))));
SELECT pg_temp.garde('ap_sa', pg_temp.en(pg_temp.p('sa'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('f1')])$$));
SELECT pg_temp.vrai((pg_temp.lu('ap_sa') ->> 'nombre')::int = 1
  AND pg_temp.lu('ap_sa') -> 'exclus' = '[]'::jsonb
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('ap_sa') -> 'eligibles') e
        WHERE e ->> 'id' = pg_temp.c('f1')::text AND e ->> 'nomComplet' = 'Fixture VISREC f1') = 1
  AND pg_temp.lu('ap_sa') ->> 'jeton' ~ '^[0-9a-f]{32}$',
  'b. super-admin, apercu de pause : la candidate femme eligible, jeton rendu');
SELECT pg_temp.garde('su_f1', to_jsonb((SELECT count(*) FROM public.audit_logs
                                         WHERE row_id = pg_temp.c('f1')::text AND action = 'super_admin_hors_cote')));
SELECT pg_temp.garde('ex_sa', pg_temp.en(pg_temp.p('sa'), 'admin',
  $$SELECT public.executer_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('f1')], pg_temp.lu('ap_sa') ->> 'jeton', 1,
    'cle-visrec-sa-1', 'Motif interne VISREC super-admin', 'pause_attente_besoin')$$));
SELECT pg_temp.vrai(pg_temp.lu('ex_sa') @> '{"rejoue": false, "geste": "mettre_en_pause", "nombre": 1, "reussies": 1,
      "exclues": 0, "refusees": 0}'::jsonb
  AND (SELECT en_pause AND pause_modele = 'pause_attente_besoin' AND version = 2
         FROM public.candidatures WHERE id = pg_temp.c('f1')),
  'b. super-admin, execution de la pause en lot : la candidate femme est en pause');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.audit_logs a
    WHERE a.row_id = pg_temp.c('f1')::text AND a.action = 'super_admin_hors_cote' AND a.actor = pg_temp.p('sa')
      AND a.payload ->> 'geste' = 'mettre_en_pause' AND a.payload ->> 'genreCandidature' = 'female')
    = pg_temp.lu('su_f1')::int + 1
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = pg_temp.c('f1')::text AND a.action = 'candidature_geste' AND a.actor = pg_temp.p('sa')
          AND a.payload ->> 'geste' = 'mettre_en_pause') = 1,
  'b. super-admin : le geste hors cote est au journal sensible (super_admin_hors_cote) et au journal des gestes');
-- Le refus en lot, modele de refus.
SELECT pg_temp.garde('ap_sa_r', pg_temp.en(pg_temp.p('sa'), 'admin',
  $$SELECT public.apercu_lot_candidats('refuser', ARRAY[pg_temp.c('f3')])$$));
SELECT pg_temp.garde('ex_sa_r', pg_temp.en(pg_temp.p('sa'), 'admin',
  $$SELECT public.executer_lot_candidats('refuser', ARRAY[pg_temp.c('f3')], pg_temp.lu('ap_sa_r') ->> 'jeton', 1,
    'cle-visrec-sa-2', 'Motif interne VISREC refus', 'refus_general')$$));
SELECT pg_temp.vrai((pg_temp.lu('ap_sa_r') ->> 'nombre')::int = 1
  AND pg_temp.lu('ex_sa_r') @> '{"reussies": 1, "exclues": 0, "refusees": 0}'::jsonb
  AND (SELECT issue = 'refusee' AND issue_modele = 'refus_general' FROM public.candidatures WHERE id = pg_temp.c('f3'))
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = pg_temp.c('f3')::text AND a.action = 'super_admin_hors_cote' AND a.actor = pg_temp.p('sa')
          AND a.payload ->> 'geste' = 'refuser') = 1,
  'b. super-admin, refus en lot : la candidate femme est refusee, le geste hors cote au journal');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs
                      WHERE action = 'candidature_hors_portee' AND actor = pg_temp.p('sa')) = pg_temp.lu('hp_sa')::int,
  'b. super-admin : aucune trace hors portee a son nom (les deux cotes sont dans sa portee)');

-- ------------------------------------------------------------
-- c. Exception coupee : le super-admin est borne comme toute direction
-- ------------------------------------------------------------
-- L'interrupteur ne bouge que sous postgres sans identite (SEC-GARDE-5) :
-- l'identite de session posee par pg_temp.en est effacee d'abord.
SELECT pg_temp.qui(NULL, NULL);
UPDATE public.app_config SET value = 'false'::jsonb WHERE key = 'kyc_exception_super_admin';
SELECT pg_temp.garde('hp_f2', to_jsonb(pg_temp.hp(pg_temp.c('f2'))));
SELECT pg_temp.garde('ap_sa_off', pg_temp.en(pg_temp.p('sa'), 'admin',
  $$SELECT public.apercu_lot_candidats('mettre_en_pause', ARRAY[pg_temp.c('f2')])$$));
SELECT pg_temp.vrai((SELECT value FROM public.app_config WHERE key = 'kyc_exception_super_admin') = 'false'::jsonb
  AND (pg_temp.lu('ap_sa_off') ->> 'nombre')::int = 0
  AND pg_temp.lu('ap_sa_off') -> 'exclus' = jsonb_build_array(jsonb_build_object('id', pg_temp.c('f2'), 'raison', 'hors_portee'))
  AND pg_temp.hp(pg_temp.c('f2')) = pg_temp.lu('hp_f2')::int + 1
  AND (SELECT count(*) FROM public.audit_logs a
        WHERE a.row_id = pg_temp.c('f2')::text AND a.action = 'candidature_hors_portee'
          AND a.actor = pg_temp.p('sa')) = 1,
  'c. exception coupee : le super-admin voit la candidate femme exclue (hors_portee), la tentative tracee');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('sa'), 'admin', 'SELECT public.attentes_recrutement()')
    = pg_temp.en(pg_temp.p('dm'), 'admin', 'SELECT public.attentes_recrutement()')
  AND pg_temp.en(pg_temp.p('sa'), 'admin', 'SELECT public.attentes_recrutement()') ->> 'deuxCotes' = 'false',
  'c. exception coupee : attentes du super-admin identiques a celles de la direction homme (deuxCotes faux)');
SELECT pg_temp.qui(NULL, NULL);
UPDATE public.app_config SET value = 'true'::jsonb WHERE key = 'kyc_exception_super_admin';

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 20 THEN
    RAISE EXCEPTION 'VISION-RECRUTEMENT ROUGE : % controles executes, 20 attendus', current_setting('test.n');
  END IF;
  RAISE NOTICE 'VISION-RECRUTEMENT : % controles verts', current_setting('test.n');
END $fin$;

ROLLBACK;
