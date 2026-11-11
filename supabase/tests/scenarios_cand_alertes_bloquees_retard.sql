-- CAND-ALERTES-2B : les compteurs « bloquees » et « entretiensEnRetard » de
-- public.lister_candidatures. Migration 20261122800000_cand_alertes_bloquees_retard.sql.
--
-- Cas couverts : (a) signature, droits, DEFINER, search_path vide, empreinte F86 et
-- reglage N pose ; (b) bloquees : restriction a toute etape, salle 2 avec controle de
-- paiement ou de profil faux ; hors compte : pause, issue close, controles faux hors de
-- la salle 2 ; (c) entretiensEnRetard : seance finie depuis plus de 24 h sans compte
-- rendu ; hors compte : moins de 24 h, compte rendu ecrit, entretien annule, pause ;
-- « a planifier » depuis plus de N jours (dernier evenement, a defaut derniere
-- activite) ; (d) N suit app_config, une valeur illisible ou negative ne compte rien ;
-- (e) la portee par genre ; (f) les autres cles de la reponse ne changent pas.
-- Chaque controle leve 'CAND-ALERTES-2B ROUGE : ...' s'il echoue. A rejouer sur une base
-- NEUVE (stub_auth puis toutes les migrations) ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', p_id::text, true);
  PERFORM pg_catalog.set_config('request.jwt.claims', pg_catalog.json_build_object(
    'sub', p_id, 'role', 'authenticated', 'aal', 'aal1',
    'app_metadata', pg_catalog.json_build_object('role', p_role))::text, true);
END $$;

CREATE FUNCTION pg_temp.vrai(p_condition boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_condition IS NOT TRUE THEN
    RAISE EXCEPTION 'CAND-ALERTES-2B ROUGE : %', p_label;
  END IF;
  RAISE NOTICE 'OK %', p_label;
END $$;

-- Les compteurs d'alerte lus par la direction p_id, comme le client les lit.
CREATE FUNCTION pg_temp.alertes(p_id uuid) RETURNS jsonb
LANGUAGE plpgsql AS $$
DECLARE v jsonb;
BEGIN
  PERFORM pg_temp.qui(p_id, 'admin');
  SET LOCAL ROLE authenticated;
  v := public.lister_candidatures('{}'::jsonb, 'activite', 1) -> 'compteursAlertes';
  RESET ROLE;
  RETURN v;
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a1e20000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a1e2cccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.s(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('a1e25555-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Une candidature enseignante, son compte en attente sans profil enseignant
-- (profil_unique faux par construction, cause profil_enseignant_absent).
CREATE FUNCTION pg_temp.cand(p_n text, p_genre public.gender, p_etape text, p_etat text,
                             p_issue text DEFAULT 'en_cours', p_pause boolean DEFAULT false,
                             p_restreinte boolean DEFAULT false,
                             p_activite timestamptz DEFAULT now()) RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email) VALUES (pg_temp.p(p_n), 'alertes-2b-' || p_n || '@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (pg_temp.p(p_n), 'A1E2-ENS-00' || p_n, 'teacher', 'Candidat' || p_n, 'Fictif', 'pending_kyc', p_genre);
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue,
                                   en_pause, reprise_le, restreinte, restriction_cause, source,
                                   recue_le, derniere_activite)
  VALUES (pg_temp.c(p_n), 'enseignant', pg_temp.p(p_n), p_genre, 'Essai ' || p_n, p_etape, p_etat, p_issue,
          p_pause, CASE WHEN p_pause THEN current_date + 30 END, p_restreinte,
          CASE WHEN p_restreinte THEN 'paiement' END, 'lien_public',
          now() - interval '60 days', p_activite);
  RETURN pg_temp.c(p_n);
END $$;

-- Un entretien de la candidature p_n, seance finie il y a p_fin, avec ou sans compte
-- rendu, consigne ou non.
CREATE FUNCTION pg_temp.entretien(p_n text, p_fin interval, p_compte_rendu boolean DEFAULT false,
                                  p_issue text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.sessions (id, teacher_id, started_at, ended_at, status, session_type)
  VALUES (pg_temp.s(p_n), pg_temp.p('a1'), now() - p_fin - interval '45 minutes', now() - p_fin,
          'planned', 'entretien');
  INSERT INTO public.entretiens (session_id, candidature_id, candidat_id, planifie_par, planifie_le,
                                 issue, consigne_par, consigne_le)
  VALUES (pg_temp.s(p_n), pg_temp.c(p_n), pg_temp.p(p_n), pg_temp.p('a1'), now() - p_fin - interval '3 days',
          p_issue, CASE WHEN p_issue IS NOT NULL THEN pg_temp.p('a1') END,
          CASE WHEN p_issue IS NOT NULL THEN now() - p_fin END);
  IF p_compte_rendu THEN
    INSERT INTO public.entretien_comptes_rendus (session_id, auteur_id, texte, avis)
    VALUES (pg_temp.s(p_n), pg_temp.p('a1'), 'Compte rendu fictif.', 'favorable');
  END IF;
END $$;

-- L'evenement qui fait entrer la candidature p_n en entretien_a_planifier, il y a p_il_y_a.
CREATE FUNCTION pg_temp.a_planifier_depuis(p_n text, p_il_y_a interval) RETURNS void
LANGUAGE sql AS $$
  INSERT INTO public.candidature_evenements (candidature_id, type, etape_avant, etape_apres,
                                             etat_avant, etat_apres, cree_le)
  VALUES (pg_temp.c(p_n), 'transition', 'prequalification', 'verifications', 'en_examen',
          'entretien_a_planifier', now() - p_il_y_a);
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text), pg_temp.vrai(boolean, text) TO authenticated;

-- ------------------------------------------------------------
-- (a) Contrat
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (SELECT p.prosecdef AND p.proconfig @> ARRAY['search_path=""']
          AND pg_catalog.pg_get_function_identity_arguments(p.oid) = 'p_filtre jsonb, p_tri text, p_page integer'
          AND p.prorettype = 'jsonb'::regtype
     FROM pg_proc p WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
  'a1 : signature (jsonb, text, integer) -> jsonb, DEFINER, search_path vide');
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.lister_candidatures(jsonb,text,integer)', 'EXECUTE'),
  'a2 : seul authenticated execute (anon, service_role, agent_ro, public : non)');
SELECT pg_temp.vrai(
  obj_description('public.lister_candidatures(jsonb,text,integer)'::regprocedure, 'pg_proc')
    LIKE '%md5_functiondef=' || md5(pg_get_functiondef('public.lister_candidatures(jsonb,text,integer)'::regprocedure)) || '%',
  'a3 : empreinte F86 a jour');
SELECT pg_temp.vrai(
  (SELECT value FROM public.app_config WHERE key = 'cand_entretien_a_planifier_jours') = '7'::jsonb,
  'a4 : N pose a 7 jours dans app_config');

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'alertes-2b-' || s || '@test.invalid' FROM unnest(ARRAY['a1', 'a2']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'A1E2-ADM-0001', 'admin', 'Direction', 'Homme', 'active', 'male'),
       (pg_temp.p('a2'), 'A1E2-ADM-0002', 'admin', 'Direction', 'Femme', 'active', 'female');

SELECT pg_temp.vrai(pg_temp.alertes(pg_temp.p('a1')) = '{"bloquees": 0, "entretiensEnRetard": 0,
  "informationsManquantes": 0, "confirmeesIndisponibles": 0}'::jsonb,
  'a5 : base vide, les quatre compteurs a 0, jamais null');

-- Bloquees (hommes) : 01 confirmee restreinte ; 02 salle 2 (profil_unique et paiement
-- faux) ; 03 restreinte mais en pause ; 04 restreinte mais refusee ; 05 salle d'examen
-- (memes controles faux, hors salle 2) ; 06 restreinte, cote femmes.
SELECT pg_temp.cand('01', 'male', 'confirmee', NULL, p_restreinte => true);
SELECT pg_temp.cand('02', 'male', 'verifications', 'decision_en_attente');
SELECT pg_temp.cand('03', 'male', 'confirmee', NULL, p_pause => true, p_restreinte => true);
SELECT pg_temp.cand('04', 'male', 'confirmee', NULL, p_issue => 'refusee', p_restreinte => true);
SELECT pg_temp.cand('05', 'male', 'prequalification', 'en_examen');
SELECT pg_temp.cand('06', 'female', 'confirmee', NULL, p_restreinte => true);

-- ------------------------------------------------------------
-- (b) Bloquees et (e) portee par genre
-- ------------------------------------------------------------
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'bloquees')::int = 2,
  'b1 : hommes, 2 bloquees (restriction ; salle 2 avec profil faux), pause, refus et salle d''examen hors compte');
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a2')) ->> 'bloquees')::int = 1,
  'b2 : femmes, 1 bloquee : chaque direction ne compte que son cote');
UPDATE public.candidatures SET restreinte = false, restriction_cause = NULL WHERE id = pg_temp.c('01');
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'bloquees')::int = 1,
  'b3 : restriction levee, la candidature quitte le compte');

-- Entretiens (hommes) : 11 fini depuis 25 h sans compte rendu ; 12 fini depuis 23 h ;
-- 13 fini depuis 48 h avec compte rendu ; 14 fini depuis 48 h, annule ; 15 fini depuis
-- 48 h sans compte rendu mais en pause ; 16 tenu et consigne depuis 48 h sans compte
-- rendu.
SELECT pg_temp.cand('11', 'male', 'verifications', 'entretien_planifie');
SELECT pg_temp.cand('12', 'male', 'verifications', 'entretien_planifie');
SELECT pg_temp.cand('13', 'male', 'verifications', 'entretien_planifie');
SELECT pg_temp.cand('14', 'male', 'verifications', 'entretien_planifie');
SELECT pg_temp.cand('15', 'male', 'verifications', 'entretien_planifie', p_pause => true);
SELECT pg_temp.cand('16', 'male', 'verifications', 'entretien_planifie');
SELECT pg_temp.entretien('11', interval '25 hours');
SELECT pg_temp.entretien('12', interval '23 hours');
SELECT pg_temp.entretien('13', interval '48 hours', p_compte_rendu => true);
SELECT pg_temp.entretien('14', interval '48 hours', p_issue => 'annule');
SELECT pg_temp.entretien('15', interval '48 hours');
SELECT pg_temp.entretien('16', interval '48 hours', p_issue => 'tenu');

-- A planifier (hommes) : 21 entre dans l'etat il y a 10 jours ; 22 il y a 3 jours ;
-- 23 sans evenement, derniere activite il y a 10 jours ; 24 entre il y a 20 jours puis
-- de nouveau il y a 2 jours (le dernier passage compte).
SELECT pg_temp.cand('21', 'male', 'verifications', 'entretien_a_planifier');
SELECT pg_temp.cand('22', 'male', 'verifications', 'entretien_a_planifier');
SELECT pg_temp.cand('23', 'male', 'verifications', 'entretien_a_planifier',
                    p_activite => now() - interval '10 days');
SELECT pg_temp.cand('24', 'male', 'verifications', 'entretien_a_planifier');
SELECT pg_temp.a_planifier_depuis('21', interval '10 days');
SELECT pg_temp.a_planifier_depuis('22', interval '3 days');
SELECT pg_temp.a_planifier_depuis('24', interval '20 days');
SELECT pg_temp.a_planifier_depuis('24', interval '2 days');

-- ------------------------------------------------------------
-- (c) Entretiens en retard
-- ------------------------------------------------------------
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'entretiensEnRetard')::int = 4,
  'c1 : 4 en retard (11 et 16 sans compte rendu apres 24 h, 21 et 23 a planifier depuis plus de 7 jours)');
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a2')) ->> 'entretiensEnRetard')::int = 0,
  'c2 : cote femmes, aucun : la portee par genre vaut aussi pour ce compteur');
INSERT INTO public.entretien_comptes_rendus (session_id, auteur_id, texte, avis)
VALUES (pg_temp.s('11'), pg_temp.p('a1'), 'Compte rendu fictif.', 'reserve');
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'entretiensEnRetard')::int = 3,
  'c3 : le compte rendu ecrit retire la candidature du compte');
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'bloquees')::int
                    = 10,
  'c4 : bloquees compte aussi les salles 2 des entretiens, aux controles faux par construction : 02, 11 a 14, 16, 21 a 24 ; 15 en pause, 01 levee');

-- ------------------------------------------------------------
-- (d) N suit app_config
-- ------------------------------------------------------------
UPDATE public.app_config SET value = '2'::jsonb WHERE key = 'cand_entretien_a_planifier_jours';
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'entretiensEnRetard')::int = 4,
  'd1 : N a 2 jours, 22 entre dans le compte (24, entre il y a 2 jours tout juste, n''y est pas encore)');
UPDATE public.app_config SET value = '"sept"'::jsonb WHERE key = 'cand_entretien_a_planifier_jours';
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'entretiensEnRetard')::int = 1,
  'd2 : N illisible, le second cas ne compte rien ; le premier reste (16)');
UPDATE public.app_config SET value = '-1'::jsonb WHERE key = 'cand_entretien_a_planifier_jours';
SELECT pg_temp.vrai((pg_temp.alertes(pg_temp.p('a1')) ->> 'entretiensEnRetard')::int = 1,
  'd3 : N negatif vaut illisible');

-- ------------------------------------------------------------
-- (f) Le reste de la reponse
-- ------------------------------------------------------------
DO $f$
DECLARE r jsonb;
BEGIN
  PERFORM pg_temp.qui(pg_temp.p('a1'), 'admin');
  SET LOCAL ROLE authenticated;
  r := public.lister_candidatures('{}'::jsonb, 'activite', 1);
  RESET ROLE;
  PERFORM pg_temp.vrai(
    (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(r) k)
      = ARRAY['compteursAlertes', 'compteursEtapes', 'lignes', 'page', 'taillePage', 'total']
    AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(r -> 'compteursAlertes') k)
      = ARRAY['bloquees', 'confirmeesIndisponibles', 'entretiensEnRetard', 'informationsManquantes']
    AND jsonb_typeof(r -> 'compteursAlertes' -> 'bloquees') = 'number'
    AND jsonb_typeof(r -> 'compteursAlertes' -> 'entretiensEnRetard') = 'number',
    'f1 : memes cles, les deux compteurs sont des nombres');
END $f$;

ROLLBACK;
