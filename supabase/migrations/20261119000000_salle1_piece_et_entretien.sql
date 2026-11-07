-- SALLE-1-TOUT-ICI (lot 4 du plan des trois salles, 07/11/2026,
-- docs/current/PLAN-TROIS-SALLES-2026-11-07.md §2.1 et §4), partie serveur.
-- Plan accepte par le directeur le 07/11 (« Ok », relaye par le pilote).
-- Numero reserve aupres du garde-cap au nom de l'agent E.
--
-- Ce fichier :
--   1. LA PIECE EN SALLE 1. Le candidat enseignant depose sa piece d'identite
--      des la Salle d'examen (« Votre candidature »), tant que sa candidature
--      est a completer (etape prequalification, etat a_completer, en cours) :
--      le directeur, le 07/11 : « accepter tous les contrats, telecharger les
--      photos [...] donc ils font tout ici ». La question CAND-S04, ouverte
--      depuis le 21/10, est close par le §2.1 du plan.
--      Nouvelle regle `private.candidature_accepte_depot_piece(uuid)` : la
--      regle CAND-L1B (salle 2 en cours, ou salle 3), OU une candidature
--      enseignant en salle 1 a completer. Elle remplace l'appel de l'ancienne
--      regle dans les deux seules portes du depot :
--        - le declencheur `kyc_documents_depot_etape` (toute voie), par
--          remplacement ancre dans `private.kyc_depot_etape_trg()` (message
--          DETAIL dit vrai : il nomme la salle 1) ;
--        - la porte R2 `public.peut_deposer_piece_identite(uuid)`, lue par la
--          fonction Edge piece-identite-confirme.
--      L'ancienne regle `private.candidature_permet_depot_piece(uuid)` NE
--      CHANGE PAS : elle borne encore la file d'ADM-02
--      (`dossiers_en_attente`) et le compteur d'ADM-01
--      (`indicateurs_admin`). Une piece deposee en salle 1 n'entre donc pas
--      dans la file de la direction avant l'admission en salle 2 ; elle y
--      est decidee par `valider_piece_candidat` (salle 2, transition 14),
--      comme aujourd'hui. Les autres sortes de candidatures (admissions des
--      familles) ne sont pas touchees : la nouvelle branche ne vaut que pour
--      le type `enseignant`.
--      Les accords n'avaient pas besoin de changement serveur : le cadre
--      (cadre_religieux_acceptable), le contrat (teacher_nda), l'avis
--      d'enregistrement et le code de conduite s'acceptent deja par un compte
--      pending_kyc, sans condition d'etape (relu le 07/11 : 0086, f70,
--      pe_code_conduite_avant_activation, cand_l2a1). La photo aussi
--      (cand_photo, 20261110330000).
--   2. LE COURRIEL « RETENU POUR UN ENTRETIEN ». `admettre_salle_verification`
--      (transition 10) laisse deja le marqueur aNotifier
--      'admis_salle_verification' ; rien ne le lisait. Le geste enfile
--      maintenant le modele `retenu_entretien` (categorie `recrutement`) dans
--      la file des courriels, dans la meme transaction, une fois par geste
--      (cle d'idempotence du geste). Sans adresse, rien ne part et le geste
--      n'est pas empeche. `private.courriel_hors_plafond` l'ajoute aux
--      messages individuels du recrutement que le plafond des envois non
--      essentiels ne retarde jamais.
--      La notification dans l'application (et sur l'appareil) suit dans un
--      fichier a part, apres PUSH-1 : elle demande d'elargir
--      notifications_evenement_check, que PUSH-1 remplace.
--
-- Preflight : empreintes md5(prosrc) des quatre fonctions remplacees, relues
-- sur une base rejouee depuis main 9b37f5f0 le 07/11 ; a verifier en
-- production par le pilote avant l'application (lecture seule) :
--   SELECT p.oid::regprocedure, pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
--    WHERE p.oid IN ('private.kyc_depot_etape_trg()'::regprocedure,
--                    'public.peut_deposer_piece_identite(uuid)'::regprocedure,
--                    'public.admettre_salle_verification(uuid,integer,text)'::regprocedure,
--                    'private.courriel_hors_plafond(boolean,text)'::regprocedure);
--   attendu : kyc_depot_etape_trg                0040be19572da0c7b2fea771d094b005
--             peut_deposer_piece_identite        8605caedfc97f72b3d2271838545a9fe
--             admettre_salle_verification        0d16ab51f0d743311d9421c719119234
--             courriel_hors_plafond              03a6a81a5f0694f71bcfb7bbc7a3163c
-- Rejouable : deja applique, le preflight le dit et rien n'est refait.
--
-- Sans BEGIN ni COMMIT de premier niveau. Aucun mot d'effacement : ni ligne
-- effacee, ni objet supprime, ni table videe. Applicable par apply_migration.

DO $preflight$
DECLARE
  v_attendu CONSTANT jsonb := pg_catalog.jsonb_build_object(
    'private.kyc_depot_etape_trg()', '0040be19572da0c7b2fea771d094b005',
    'peut_deposer_piece_identite(uuid)', '8605caedfc97f72b3d2271838545a9fe',
    'admettre_salle_verification(uuid,integer,text)', '0d16ab51f0d743311d9421c719119234',
    'private.courriel_hors_plafond(boolean,text)', '03a6a81a5f0694f71bcfb7bbc7a3163c');
  v_r record;
BEGIN
  IF pg_catalog.to_regprocedure('private.candidature_accepte_depot_piece(uuid)') IS NOT NULL THEN
    RAISE NOTICE 'SALLE-1 : deja applique, rien n''est refait';
    RETURN;
  END IF;
  FOR v_r IN
    SELECT p.oid::pg_catalog.regprocedure::text AS f, pg_catalog.md5(p.prosrc) AS m
      FROM pg_catalog.pg_proc p
     WHERE p.oid IN ('private.kyc_depot_etape_trg()'::pg_catalog.regprocedure,
                     'public.peut_deposer_piece_identite(uuid)'::pg_catalog.regprocedure,
                     'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure,
                     'private.courriel_hors_plafond(boolean,text)'::pg_catalog.regprocedure)
  LOOP
    IF v_r.m IS DISTINCT FROM v_attendu ->> v_r.f THEN
      RAISE EXCEPTION 'SALLE-1 : % a change (md5 %), migration a revoir', v_r.f, v_r.m;
    END IF;
  END LOOP;
END;
$preflight$;

CREATE OR REPLACE FUNCTION pg_temp.remplacer(p_f pg_catalog.regprocedure, p_avant text, p_apres text, p_n integer)
RETURNS void
LANGUAGE plpgsql
AS $function$
DECLARE
  v_def text := pg_catalog.pg_get_functiondef(p_f);
  v_n integer;
BEGIN
  IF pg_catalog.strpos(v_def, p_apres) > 0 THEN
    RETURN;  -- deja remplace (rejeu)
  END IF;
  v_n := (pg_catalog.length(v_def)
          - pg_catalog.length(pg_catalog.replace(v_def, p_avant, '')))
         / pg_catalog.length(p_avant);
  IF v_n <> p_n THEN
    RAISE EXCEPTION '% : passage trouve % fois au lieu de %, migration a revoir : %',
      p_f, v_n, p_n, pg_catalog.left(p_avant, 120);
  END IF;
  EXECUTE pg_catalog.replace(v_def, p_avant, p_apres);
END;
$function$;

-- ---------------------------------------------------------------------------
-- 1. La piece en salle 1
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.candidature_accepte_depot_piece(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT private.candidature_permet_depot_piece(p_profile_id)
      OR coalesce(
           -- SALLE-1 (07/11/2026) : la candidature enseignant de ce compte
           -- est en salle 1, a completer, en cours ; et aucune autre
           -- candidature de ce compte n'est hors des etapes permises.
           EXISTS (SELECT 1 FROM public.candidatures c
                    WHERE c.profile_id = p_profile_id
                      AND c.type_code = 'enseignant'
                      AND c.etape = 'prequalification'
                      AND c.etat = 'a_completer'
                      AND c.issue = 'en_cours')
           AND NOT EXISTS (SELECT 1 FROM public.candidatures c
                            WHERE c.profile_id = p_profile_id
                              AND NOT (c.etape = 'confirmee'
                                       OR (c.etape = 'verifications' AND c.issue = 'en_cours')
                                       OR (c.type_code = 'enseignant'
                                           AND c.etape = 'prequalification'
                                           AND c.etat = 'a_completer'
                                           AND c.issue = 'en_cours'))),
           false);
$function$;

ALTER FUNCTION private.candidature_accepte_depot_piece(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION private.candidature_accepte_depot_piece(uuid)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
COMMENT ON FUNCTION private.candidature_accepte_depot_piece(uuid) IS
  'SALLE-1 (07/11/2026) : le depot de la piece est permis par la regle CAND-L1B (salle 2 en cours, salle 3), '
  'ou pour une candidature enseignant en salle 1 a completer. Lu par le declencheur du depot et par '
  'peut_deposer_piece_identite ; la file d ADM-02 garde candidature_permet_depot_piece. Aucun droit client.';

SELECT pg_temp.remplacer('private.kyc_depot_etape_trg()',
  $a$  IF NOT private.candidature_permet_depot_piece(NEW.profile_id) THEN$a$,
  $b$  IF NOT private.candidature_accepte_depot_piece(NEW.profile_id) THEN$b$, 1);
SELECT pg_temp.remplacer('private.kyc_depot_etape_trg()',
  $a$      DETAIL = 'CAND-L1B : la piece d''un compte candidat se depose en Salle de verification et d''entretien (candidature en cours) ou apres ; jamais en Salle d''examen, ni apres un refus ou un retrait.';$a$,
  $b$      DETAIL = 'CAND-L1B, SALLE-1 : la piece d''un compte candidat se depose en salle 1 tant que la candidature est a completer, en salle 2 en cours, ou en salle 3 ; jamais pendant l''examen de la candidature, ni apres un refus ou un retrait.';$b$, 1);

SELECT pg_temp.remplacer('public.peut_deposer_piece_identite(uuid)',
  $a$    AND private.candidature_permet_depot_piece(p_profile_id)$a$,
  $b$    AND private.candidature_accepte_depot_piece(p_profile_id)$b$, 1);

-- ---------------------------------------------------------------------------
-- 2. Le courriel « retenu pour un entretien »
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION private.courriel_hors_plafond(p_essentielle boolean, p_modele text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT coalesce(p_essentielle, false)
      OR p_modele IN ('compte_enseignant_valide', 'invitation_enseignant', 'retenu_entretien');
$function$;
COMMENT ON FUNCTION private.courriel_hors_plafond(boolean, text) IS
  'CANDIDATS-FLUX (06/11/2026), SALLE-1 (07/11/2026) : vrai pour un message que le plafond '
  'courriels.non_essentiels_par_jour ne retarde jamais (categorie essentielle, ou message individuel '
  'compte_enseignant_valide / invitation_enseignant / retenu_entretien).';

SELECT pg_temp.remplacer('public.admettre_salle_verification(uuid,integer,text)',
  $a$    pg_catalog.jsonb_build_object('controles', v_controles, 'aNotifier', 'admis_salle_verification'));$a$,
  $b$    pg_catalog.jsonb_build_object('controles', v_controles, 'aNotifier', 'admis_salle_verification'));
  -- SALLE-1 (07/11/2026) : « Vous etes retenu pour un entretien », par la
  -- file, une fois par geste ; une adresse absente n'empeche pas le geste.
  IF v_c.profile_id IS NOT NULL AND public.courriel_adresse_profil(v_c.profile_id) IS NOT NULL THEN
    PERFORM public.courriel_enfiler(
      'recrutement', 'retenu_entretien', public.courriel_adresse_profil(v_c.profile_id), v_c.profile_id,
      '{}'::jsonb, 'retenu_entretien:' || p_id::text || ':' || p_cle_idempotence, 'auto', v_uid);
  END IF;$b$, 1);

-- ---------------------------------------------------------------------------
-- 3. Les fiches F86 des deux RPC remplacees : empreinte reelle, et ce qui
--    change, ajoute a la fin (le reste du texte est garde mot pour mot).
-- ---------------------------------------------------------------------------
DO $f86$
DECLARE
  v_f pg_catalog.regprocedure;
  v_ajout text;
  v_avant text;
  v_apres text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['public.peut_deposer_piece_identite(uuid)'::pg_catalog.regprocedure,
                             'public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure] LOOP
    v_ajout := CASE v_f
      WHEN 'public.peut_deposer_piece_identite(uuid)'::pg_catalog.regprocedure THEN
        ' SALLE-1 (07/11/2026) : l etape lue est private.candidature_accepte_depot_piece (salle 1 a completer, '
        'en plus de la salle 2 en cours et de la salle 3). Must-pass aussi : supabase/tests/scenarios_salle1_tout_ici.sql.'
      ELSE
        ' SALLE-1 (07/11/2026) : enfile le courriel retenu_entretien (recrutement), une fois par geste. '
        'Must-pass aussi : supabase/tests/scenarios_salle1_tout_ici.sql.' END;
    v_avant := pg_catalog.obj_description(v_f, 'pg_proc');
    IF v_avant IS NULL OR v_avant NOT LIKE 'F86 candidate allowlist:%md5_functiondef=%' THEN
      RAISE EXCEPTION 'SALLE-1 : fiche F86 de % introuvable', v_f;
    END IF;
    v_apres := pg_catalog.regexp_replace(v_avant, 'md5_functiondef=[0-9a-f]{32}',
                                         'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v_f)));
    IF pg_catalog.strpos(v_apres, 'SALLE-1 (07/11/2026)') = 0 THEN
      v_apres := v_apres || v_ajout;
    END IF;
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v_f, v_apres);
  END LOOP;
END;
$f86$;

COMMENT ON FUNCTION private.kyc_depot_etape_trg() IS
  'CAND-L1B, SALLE-1 (07/11/2026) : refuse le depot d une piece hors etape (private.candidature_accepte_depot_piece), '
  'par toute voie. Aucun droit client.';

-- ---------------------------------------------------------------------------
-- Postflight
-- ---------------------------------------------------------------------------
DO $postflight$
DECLARE
  v_oid pg_catalog.regprocedure;
BEGIN
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('private.kyc_depot_etape_trg()'::pg_catalog.regprocedure),
                       'private.candidature_accepte_depot_piece(NEW.profile_id)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.peut_deposer_piece_identite(uuid)'::pg_catalog.regprocedure),
                          'private.candidature_accepte_depot_piece(p_profile_id)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.admettre_salle_verification(uuid,integer,text)'::pg_catalog.regprocedure),
                          '''retenu_entretien''') = 0
     OR NOT private.courriel_hors_plafond(false, 'retenu_entretien') THEN
    RAISE EXCEPTION 'SALLE-1 : remplacement incomplet';
  END IF;
  -- L'ancienne regle borne toujours la file d'ADM-02 et le compteur d'ADM-01.
  IF pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.dossiers_en_attente()'::pg_catalog.regprocedure),
                       'private.candidature_permet_depot_piece(p.id)') = 0
     OR pg_catalog.strpos(pg_catalog.pg_get_functiondef('public.indicateurs_admin()'::pg_catalog.regprocedure),
                          'private.candidature_permet_depot_piece(p.id)') = 0 THEN
    RAISE EXCEPTION 'SALLE-1 : la file d''ADM-02 ne lit plus l''ancienne regle';
  END IF;
  FOREACH v_oid IN ARRAY ARRAY['private.candidature_accepte_depot_piece(uuid)'::pg_catalog.regprocedure,
                               'private.kyc_depot_etape_trg()'::pg_catalog.regprocedure] LOOP
    IF pg_catalog.has_function_privilege('anon', v_oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'SALLE-1 : % appelable par un client', v_oid;
    END IF;
  END LOOP;
  IF pg_catalog.has_function_privilege('anon', 'public.peut_deposer_piece_identite(uuid)', 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', 'public.admettre_salle_verification(uuid,integer,text)', 'EXECUTE')
     OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                     WHERE p.oid = 'private.candidature_accepte_depot_piece(uuid)'::pg_catalog.regprocedure
                       AND p.prosecdef AND p.proconfig @> ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'SALLE-1 : droits ou search_path inattendus';
  END IF;
END;
$postflight$;
