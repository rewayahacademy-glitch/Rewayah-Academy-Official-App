-- VERSEMENT-QUESTIONS, PR 2 : les questions de versement du candidat (directeur, 16/11/2026).
-- Migration 20261128500100_versement_questions.sql. Source : DECISION-QUESTIONS-VERSEMENT-2026-11-16.md.
--
-- Cas couverts : (a) refus de public.modifier_mon_versement (sans session, sans candidature,
-- valeurs invalides, aucune reponse envoyee) ; (b) un candidat en attente de paiement (« non » au
-- compte, Arabie saoudite) passe a « oui » : nouvelle ligne de reponses, historique garde, paiement
-- compatible, dossier de retour a a_completer, evenement ; (c) sans compte, un service de mobile
-- money du pays, coordonnees remises a valider quand le pays change ; (d) les memes valeurs ne
-- changent rien ; (e) apres la validation du dossier (verifications) ou pour une candidature close,
-- modification_impossible, pour la nouvelle RPC comme pour l'ancienne ; (f) le geste « Debloquer le
-- versement » : refus (session, non-direction, motif absent, version perimee, etape), succes
-- (motif, trace, paiement compatible sans moyen declare, retour a a_completer), rejeu par la meme
-- cle sans effet, deblocage leve par une modification du candidat ; (g) capacites, droits, empreintes.
-- Chaque controle leve 'VERSEMENT-Q ROUGE : ...' s'il echoue. A rejouer sur une base NEUVE (stub_auth
-- puis toutes les migrations) ; le scenario annule tout a la fin.
BEGIN;

CREATE FUNCTION pg_temp.qui(p_id uuid, p_role text, p_aal text DEFAULT 'aal1') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_jwt text;
BEGIN
  v_jwt := CASE WHEN p_id IS NULL AND p_role IS NULL THEN '{}'
                ELSE pg_catalog.json_build_object(
                       'sub', p_id, 'role', 'authenticated', 'aal', p_aal,
                       'app_metadata', CASE WHEN p_role IS NULL THEN pg_catalog.json_build_object()
                                            ELSE pg_catalog.json_build_object('role', p_role) END)::text END;
  PERFORM pg_catalog.set_config('request.jwt.claim.sub', coalesce(p_id::text, ''), true);
  PERFORM pg_catalog.set_config('request.jwt.claims', v_jwt, true);
END $$;

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
    RAISE EXCEPTION 'VERSEMENT-Q ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
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

CREATE FUNCTION pg_temp.refus_en(p_id uuid, p_role text, p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_passe boolean := false;
  v_code text;
  v_msg text;
BEGIN
  PERFORM pg_temp.qui(p_id, p_role);
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
    EXECUTE p_sql;
    v_passe := true;
    EXECUTE 'RESET ROLE';
  EXCEPTION WHEN OTHERS THEN
    v_code := SQLSTATE;
    v_msg := SQLERRM;
    EXECUTE 'RESET ROLE';
  END;
  IF v_passe THEN
    RAISE EXCEPTION 'VERSEMENT-Q ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'VERSEMENT-Q ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be7a0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('be7acccc-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.vue(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT private.paiement_etat(c.id) || '/' || c.paiement || '/' || coalesce(c.etat, '-') || '/' || c.version
    FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.etat(p_n text) RETURNS text
LANGUAGE sql AS $$
  SELECT private.paiement_etat(c.id) || '/' || c.paiement || '/' || coalesce(c.etat, '-')
    FROM public.candidatures c WHERE c.id = pg_temp.c(p_n);
$$;
CREATE FUNCTION pg_temp.ver(p_n text) RETURNS integer
LANGUAGE sql AS $$ SELECT version FROM public.candidatures WHERE id = pg_temp.c(p_n); $$;
CREATE FUNCTION pg_temp.envoyees(p_n text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_reponses r
   WHERE r.candidature_id = pg_temp.c(p_n) AND r.source = 'candidat' AND NOT r.brouillon;
$$;
CREATE FUNCTION pg_temp.derniere(p_n text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT r.reponses FROM public.candidature_reponses r
   WHERE r.candidature_id = pg_temp.c(p_n) AND r.source = 'candidat' AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC LIMIT 1;
$$;
CREATE FUNCTION pg_temp.controles(p_n text, p_controle text) RETURNS integer
LANGUAGE sql AS $$
  SELECT count(*)::int FROM public.candidature_evenements e
   WHERE e.candidature_id = pg_temp.c(p_n) AND e.type = 'controle' AND e.details ->> 'controle' = p_controle;
$$;
GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.p(text), pg_temp.c(text) TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction (homme). Candidats (hommes) : 01 « non » au compte + Arabie saoudite, en attente de
-- paiement ; 02 en examen, Arabie saoudite avec compte, coordonnees validees ; 03 en salle 2
-- (verifications) ; 04 refusee ; 05 sans reponse envoyee ; 06 « non » + Algerie (ligne en verification),
-- en attente de paiement : le cas du deblocage ; 07 meme cas que 06, pour le geste refuse (etape).
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'versement-q-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', '01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('a1'), 'BE7A-ADM-0001', 'admin', 'Direction', 'Un', 'active', 'male');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
SELECT pg_temp.p(s), 'BE7A-ENS-00' || s, 'teacher', 'Essai' || s, 'Fictif', 'pending_kyc', 'male'
FROM unnest(ARRAY['01', '02', '03', '04', '05', '06', '07']) AS s;
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
SELECT pg_temp.c(v.s), 'enseignant', pg_temp.p(v.s), 'male', 'Fixture ' || v.s, v.etape, v.etat, v.issue, 'lien_public'
FROM (VALUES
  ('01', 'prequalification', 'paiement_non_disponible', 'en_cours'),
  ('02', 'prequalification', 'en_examen', 'en_cours'),
  ('03', 'verifications', 'en_examen', 'en_cours'),
  ('04', 'prequalification', 'en_examen', 'refusee'),
  ('05', 'prequalification', 'a_completer', 'en_cours'),
  ('06', 'prequalification', 'paiement_non_disponible', 'en_cours'),
  ('07', 'verifications', 'en_examen', 'en_cours')
) AS v(s, etape, etat, issue);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, soumis_le)
SELECT pg_temp.c(v.s), 'salle-examen-2', v.r::jsonb, 'candidat', false, now() - interval '1 day'
FROM (VALUES
  ('01', '{"paysVersement": "SA", "compteBancaire": false, "publics": ["adultes"]}'),
  ('02', '{"paysVersement": "SA", "compteBancaire": true, "publics": ["adultes"]}'),
  ('03', '{"paysVersement": "SA", "compteBancaire": true}'),
  ('04', '{"paysVersement": "SA", "compteBancaire": false}'),
  ('06', '{"paysVersement": "DZ", "compteBancaire": false}'),
  ('07', '{"paysVersement": "DZ", "compteBancaire": false}')
) AS v(s, r);
INSERT INTO public.versement_coordonnees (profile_id, devise_cible, titulaire, iban, valide_le, valide_par)
VALUES (pg_temp.p('02'), 'EUR', 'Candidat Deux', 'FR7630006000011234567890189', now(), pg_temp.p('02'));
-- Un service de mobile money confirme au Senegal (le referentiel de depart n'en porte aucun).
INSERT INTO public.referentiel_paiement (pays, methode, operateur, etat, source, source_ref, verifie_le)
VALUES ('SN', 'mobile_money', 'wave', 'confirme', 'decision_directeur', 'scenario VERSEMENT-Q', current_date);
SELECT private.paiement_recalculer(pg_temp.c(s), 'reponses') FROM unnest(ARRAY['01', '02', '06']) AS s;

SELECT pg_temp.vrai((SELECT etat FROM public.referentiel_paiement WHERE pays = 'SA' AND methode = 'virement_bancaire') = 'confirme'
  AND (SELECT etat FROM public.referentiel_paiement WHERE pays = 'DZ' AND methode = 'virement_bancaire') = 'en_verification',
  'a0 : le virement saoudien est confirme, l''algerien est en verification (points de depart)');
SELECT pg_temp.vrai(pg_temp.etat('01') = 'incompatible/incompatible/paiement_non_disponible'
  AND pg_temp.etat('02') = 'compatible/compatible/en_examen'
  AND pg_temp.etat('06') = 'incompatible/incompatible/paiement_non_disponible',
  'a1 : 01 sans compte en Arabie saoudite attend ; 02 avec compte est compatible ; 06 (Algerie) attend');

-- ------------------------------------------------------------
-- (a) Refus de modifier_mon_versement
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL, $q$SELECT public.modifier_mon_versement(true, 'SA')$q$, '42501',
  'b1 : sans session');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', $q$SELECT public.modifier_mon_versement(true, 'SA')$q$, '42501',
  'b2 : la direction n''est pas titulaire d''une candidature');
SELECT pg_temp.refus_en(pg_temp.p('01'), 'teacher', $q$SELECT public.modifier_mon_versement(NULL, 'SA')$q$, '22023',
  'b3 : compte bancaire attendu (vrai ou faux)');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.modifier_mon_versement(true, 'ZZ')$q$) ->> 'erreur' = 'pays_invalide'
  AND pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY['inconnu_xx'])$q$) ->> 'erreur' = 'operateur_invalide'
  AND pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY['wave'::text, 'Mauvais Code'])$q$) ->> 'erreur' = 'operateur_invalide'
  AND pg_temp.en(pg_temp.p('05'), 'teacher', $q$SELECT public.modifier_mon_versement(true, 'SA')$q$) ->> 'erreur' = 'aucune_reponse_envoyee',
  'b4 : pays inconnu, service inconnu ou mal ecrit, aucune reponse envoyee : refus par leur nom');
SELECT pg_temp.vrai(pg_temp.envoyees('01') = 1 AND pg_temp.etat('01') = 'incompatible/incompatible/paiement_non_disponible',
  'b5 : les refus n''ont rien ecrit');

-- ------------------------------------------------------------
-- (b) Le « non » devient « oui » : le dossier en attente repart
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('01'), 'teacher', $q$SELECT public.modifier_mon_versement(true, 'SA')$q$)) ? 'candidature',
  'c1 : « oui » au compte bancaire, meme pays : accepte');
SELECT pg_temp.vrai(pg_temp.envoyees('01') = 2
  AND pg_temp.derniere('01') = '{"paysVersement": "SA", "compteBancaire": true, "publics": ["adultes"]}'::jsonb,
  'c2 : une reponse de plus, le reste des reponses garde, pas de services avec un compte');
SELECT pg_temp.vrai(pg_temp.etat('01') = 'compatible/compatible/a_completer',
  'c3 : paiement compatible, dossier de retour a a_completer (transition 9)');
SELECT pg_temp.vrai(pg_temp.controles('01', 'versement_modifie') = 1
  AND (SELECT e.details #>> '{avant,compteBancaire}' = 'false' AND e.details #>> '{apres,compteBancaire}' = 'true'
              AND (e.details ->> 'deblocageLeve')::boolean = false AND e.auteur_id = pg_temp.p('01')
         FROM public.candidature_evenements e WHERE e.candidature_id = pg_temp.c('01') AND e.details ->> 'controle' = 'versement_modifie'),
  'c4 : l''evenement porte l''avant, l''apres et l''auteur');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.c('01')
     AND r.reponses ->> 'compteBancaire' = 'false') = 1,
  'c5 : l''ancienne reponse « non » est gardee');

-- ------------------------------------------------------------
-- (c) Sans compte : le pays du mobile money, puis ses services
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('02'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY['wave'])$q$)) ? 'candidature'
  AND pg_temp.derniere('02') = '{"paysVersement": "SN", "compteBancaire": false, "operateurs": ["wave"], "publics": ["adultes"]}'::jsonb
  AND pg_temp.etat('02') = 'compatible/compatible/en_examen',
  'd1 : sans compte, Senegal et Wave (confirme) : compatible, services gardes');
SELECT pg_temp.vrai(
  (SELECT valide_le IS NULL AND valide_par IS NULL FROM public.versement_coordonnees WHERE profile_id = pg_temp.p('02') AND active),
  'd2 : le pays change, les coordonnees redeviennent « a valider »');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('02'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY['wave'])$q$)) ->> 'inchange' = 'true'
  AND pg_temp.envoyees('02') = 3 - 1,
  'd3 : les memes valeurs ne changent rien (aucune reponse de plus)');
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('02'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY[]::text[])$q$)) ? 'candidature'
  AND pg_temp.derniere('02') = '{"paysVersement": "SN", "compteBancaire": false, "publics": ["adultes"]}'::jsonb
  AND pg_temp.etat('02') LIKE 'incompatible/%',
  'd4 : sans service retenu, aucun moyen : incompatible (le dossier attend, il n''est jamais refuse)');
SELECT pg_temp.vrai((SELECT issue FROM public.candidatures WHERE id = pg_temp.c('02')) = 'en_cours',
  'd5 : jamais refuse pour ce motif');

-- ------------------------------------------------------------
-- (d) Apres la validation du dossier : plus de modification
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('03'), 'teacher', $q$SELECT public.modifier_mon_versement(false, 'SN', ARRAY['wave'])$q$) ->> 'erreur' = 'modification_impossible'
  AND pg_temp.en(pg_temp.p('03'), 'teacher', $q$SELECT public.modifier_mon_pays_versement('SN')$q$) ->> 'erreur' = 'modification_impossible'
  AND pg_temp.envoyees('03') = 1,
  'e1 : en salle 2 (dossier valide) : la nouvelle RPC et l''ancienne refusent, rien n''est ecrit');
SELECT pg_temp.refus_en(pg_temp.p('04'), 'teacher', $q$SELECT public.modifier_mon_versement(true, 'SN')$q$, '42501',
  'e2 : une candidature refusee n''a plus de titulaire en cours : refus, rien n''est ecrit');
SELECT pg_temp.vrai(pg_temp.envoyees('04') = 1, 'e3 : la candidature refusee n''a pas bouge');

-- ------------------------------------------------------------
-- (e) Le geste « Debloquer le versement »
-- ------------------------------------------------------------
SELECT pg_temp.refus_en(NULL, NULL,
  pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, 1, 'cle-deblocage-00', 'cas particulier')$q$, pg_temp.c('06')),
  '42501', 'f1 : sans session');
SELECT pg_temp.refus_en(pg_temp.p('06'), 'teacher',
  pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, 1, 'cle-deblocage-00', 'cas particulier')$q$, pg_temp.c('06')),
  '42501', 'f2 : le candidat ne se debloque pas lui-meme');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, %s, 'cle-deblocage-01', '   ')$q$, pg_temp.c('06'), pg_temp.ver('06')))
    ->> 'erreur' = 'motif_requis'
  AND pg_temp.etat('06') LIKE 'incompatible/%',
  'f3 : le motif ecrit est obligatoire (blanc refuse), rien n''est ecrit');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, %s, 'cle-deblocage-02', 'cas particulier')$q$, pg_temp.c('06'), pg_temp.ver('06') + 5))
    ->> 'erreur' = 'conflit_candidature',
  'f4 : une version perimee est refusee');
SELECT pg_temp.vrai(
  pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, %s, 'cle-deblocage-03', 'cas particulier')$q$, pg_temp.c('07'), pg_temp.ver('07')))
    ->> 'erreur' = 'transition_interdite',
  'f5 : en salle 2 (dossier valide), le geste n''existe plus');
SELECT set_config('test.cle', 'cle-deblocage-04', true);
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, %s, 'cle-deblocage-04', 'Cas particulier : paiement par un proche, confirme par message')$q$,
                      pg_temp.c('06'), pg_temp.ver('06')))) ->> 'paiement' = 'compatible'
  AND pg_temp.etat('06') = 'compatible/compatible/a_completer',
  'f6 : debloque : paiement compatible sans moyen declare, dossier de retour a a_completer');
SELECT pg_temp.vrai(
  (SELECT versement_debloque_le IS NOT NULL AND versement_debloque_par = pg_temp.p('a1')
     FROM public.candidatures WHERE id = pg_temp.c('06'))
  AND (SELECT count(*) FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.c('06') AND e.type = 'controle' AND e.details ->> 'controle' = 'versement_debloque'
          AND e.auteur_id = pg_temp.p('a1') AND e.motif_interne LIKE 'Cas particulier%') = 1
  AND (SELECT count(*) FROM public.audit_logs l WHERE l.row_id = pg_temp.c('06')::text
         AND l.action = 'candidature_geste') >= 1,
  'f7 : tracee (colonnes, evenement avec motif et auteur, audit)');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM public.candidature_evenements e
    WHERE e.candidature_id = pg_temp.c('06') AND e.type = 'transition' AND e.etat_apres = 'a_completer'
      AND e.details ->> 'aNotifier' = 'paiement_possible') = 1,
  'f8 : le retour a a_completer porte l''avis « paiement possible » (transition 9)');
SELECT set_config('test.ev06', (SELECT count(*)::text FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('06')), true);
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin',
    pg_catalog.format($q$SELECT public.debloquer_versement_candidat(%L, %s, 'cle-deblocage-04', 'Cas particulier : paiement par un proche, confirme par message')$q$,
                      pg_temp.c('06'), 1))) ->> 'paiement' = 'compatible'
  AND (SELECT count(*) FROM public.candidature_evenements WHERE candidature_id = pg_temp.c('06'))::text = current_setting('test.ev06'),
  'f9 : rejoue avec la meme cle, il rend le meme resultat sans rien ecrire de plus');
-- Le candidat modifie sa declaration : le deblocage valait pour la precedente.
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('06'), 'teacher', $q$SELECT public.modifier_mon_versement(true, 'DZ')$q$)) ? 'candidature',
  'f10 : le candidat modifie sa declaration (« oui » au compte, meme pays) : accepte');
SELECT pg_temp.vrai(
  (SELECT versement_debloque_le IS NULL AND versement_debloque_par IS NULL FROM public.candidatures WHERE id = pg_temp.c('06'))
  AND pg_temp.etat('06') LIKE 'incompatible/%'
  AND pg_temp.controles('06', 'versement_modifie') = 1
  AND (SELECT (e.details ->> 'deblocageLeve')::boolean FROM public.candidature_evenements e
        WHERE e.candidature_id = pg_temp.c('06') AND e.details ->> 'controle' = 'versement_modifie'),
  'f11 : une modification du candidat leve le deblocage (la direction decide sur une declaration precise)');

-- ------------------------------------------------------------
-- (f) Capacites, droits, empreintes
-- ------------------------------------------------------------
SELECT pg_temp.vrai(
  (pg_temp.en(pg_temp.p('a1'), 'admin', $q$SELECT public.capacites_candidatures()$q$)) #>> '{gestes,debloquerVersement}' = 'true',
  'g1 : la direction voit le geste dans ses capacites');
SELECT pg_temp.vrai(
  has_function_privilege('authenticated', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
  AND has_function_privilege('authenticated', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
  AND NOT has_function_privilege('service_role', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
  AND NOT has_function_privilege('agent_ro', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.modifier_mon_versement(boolean,text,text[])', 'EXECUTE')
  AND NOT has_function_privilege('public', 'public.debloquer_versement_candidat(uuid,integer,text,text)', 'EXECUTE'),
  'g2 : seul authenticated execute les deux fonctions');
SELECT pg_temp.vrai(
  (SELECT bool_and(obj_description(f, 'pg_proc') LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
                   AND prosecdef AND proconfig @> ARRAY['search_path=""'])
     FROM unnest(ARRAY['public.modifier_mon_versement(boolean,text,text[])',
                       'public.debloquer_versement_candidat(uuid,integer,text,text)',
                       'public.capacites_candidatures()']::regprocedure[]) AS f
     JOIN pg_proc p ON p.oid = f),
  'g3 : empreintes F86 a jour, DEFINER, search_path vide');
SELECT pg_temp.vrai(
  (SELECT count(*) FROM private.candidature_gestes_regles WHERE geste = 'debloquer_versement' AND transition = 44
     AND auteurs = '{direction}' AND etapes = '{prequalification}' AND motif_requis = '{direction}') = 1,
  'g4 : la regle du geste est dans le moteur (transition 44, direction, prequalification, motif exige)');

SELECT pg_temp.vrai(coalesce(nullif(current_setting('test.n', true), ''), '0')::int >= 30,
  'z : au moins 30 controles passes');
DO $$ BEGIN RAISE NOTICE 'VERSEMENT-Q : % controles OK', current_setting('test.n'); END $$;
ROLLBACK;
