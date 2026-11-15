-- PAYS-VERSEMENT (migration 20261127000300) : le candidat corrige son pays de
-- versement apres l'envoi ; la direction peut le lui redemander.
-- Prouve : code de complement present ; pays inconnu refuse ; changement =
-- nouveau document sans operateurs, coordonnees a revalider, candidature jamais
-- refusee ; meme pays = inchange ; autre profil sans candidature refuse ; anon ferme.
BEGIN;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN RAISE EXCEPTION 'PAYS-VERSEMENT ROUGE : %', p_label; END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;
CREATE FUNCTION pg_temp.id(p text) RETURNS uuid LANGUAGE sql IMMUTABLE AS $$ SELECT pg_catalog.md5('pays-versement-' || p)::uuid $$;
CREATE FUNCTION pg_temp.en(p_id uuid, p_role text, p_sql text) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'aal', 'aal1', 'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql INTO v;
  EXECUTE 'RESET ROLE';
  RETURN v;
END $$;

INSERT INTO auth.users (id, email)
SELECT pg_temp.id(x), 'pays-versement-' || x || '@test.invalid' FROM unnest(ARRAY['cand', 'autre']) AS x;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.id('cand'), 'PV-ENS-0001', 'teacher', 'Candidat', 'Essai', 'pending_kyc', 'male'),
       (pg_temp.id('autre'), 'PV-ENS-0002', 'teacher', 'Autre', 'Essai', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause, source)
VALUES (pg_temp.id('c1'), 'enseignant', pg_temp.id('cand'), 'male', 'Candidat Essai',
        'prequalification', 'en_examen', 'en_cours', false, 'lien_public');
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
VALUES (pg_temp.id('c1'), 'v-essai',
        '{"paysVersement":"FR","compteBancaire":true,"operateurs":["op_essai"],"publics":["adultes"]}', 'candidat', false, now());
INSERT INTO public.versement_coordonnees (profile_id, devise_cible, titulaire, iban, valide_le, valide_par)
VALUES (pg_temp.id('cand'), 'EUR', 'Candidat Essai', 'FR7630006000011234567890189', now(), pg_temp.id('cand'));

SELECT pg_temp.vrai('pays_versement' = ANY (private.candidature_complement_codes('prequalification', 'enseignant'))
  AND 'pays_versement' = ANY (private.candidature_complement_codes('verifications', 'enseignant')),
  'le complement « pays et compte de versement » existe en salle 1 et en salle 2');

SELECT pg_temp.vrai(pg_temp.en(pg_temp.id('cand'), 'teacher', $$SELECT public.modifier_mon_pays_versement('ZZ')$$) ->> 'erreur' = 'pays_invalide',
  'un pays hors de la liste ISO est refuse');

SELECT pg_temp.vrai(pg_temp.en(pg_temp.id('cand'), 'teacher', $$SELECT public.modifier_mon_pays_versement('fr')$$) ->> 'inchange' = 'true',
  'le meme pays ne change rien');

SELECT pg_temp.vrai(pg_temp.en(pg_temp.id('cand'), 'teacher', $$SELECT public.modifier_mon_pays_versement('QA')$$) ? 'candidature',
  'le candidat change son pays de versement apres l''envoi');

SELECT pg_temp.vrai((SELECT r.reponses ->> 'paysVersement' = 'QA' AND NOT (r.reponses ? 'operateurs') AND r.reponses ->> 'publics' IS NOT NULL
                       FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.id('c1') AND NOT r.brouillon
                      ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1)
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.id('c1')) = 2,
  'nouveau document : nouveau pays, operateurs vides, le reste garde, l''historique reste');

SELECT pg_temp.vrai((SELECT valide_le IS NULL AND valide_par IS NULL FROM public.versement_coordonnees WHERE profile_id = pg_temp.id('cand') AND active),
  'les coordonnees de versement redeviennent « a valider »');

SELECT pg_temp.vrai((SELECT issue = 'en_cours' FROM public.candidatures WHERE id = pg_temp.id('c1')),
  'la candidature n''est jamais refusee pour ce motif');

SELECT pg_temp.vrai((SELECT count(*) = 1 FROM public.candidature_evenements
                      WHERE candidature_id = pg_temp.id('c1') AND details ->> 'controle' = 'pays_versement_modifie'),
  'le changement est journalise');

DO $autre$
BEGIN
  BEGIN
    PERFORM pg_temp.en(pg_temp.id('autre'), 'teacher', $$SELECT public.modifier_mon_pays_versement('QA')$$);
    RAISE EXCEPTION 'PAYS-VERSEMENT ROUGE : un compte sans candidature a pu appeler';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'OK un compte sans candidature est refuse';
  END;
END $autre$;

SELECT pg_temp.vrai(NOT has_function_privilege('anon', 'public.modifier_mon_pays_versement(text)'::regprocedure, 'EXECUTE'),
  'anon n''a pas le droit d''appeler');

ROLLBACK;
