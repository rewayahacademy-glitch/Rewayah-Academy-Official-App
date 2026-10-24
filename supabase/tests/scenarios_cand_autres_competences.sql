-- CAND-AUTRES : les autres competences des candidats (« Vos autres talents »).
-- Migration 20261022000500_cand_autres_competences.sql.
-- Conception : docs/current/CANDIDATURES/PROPOSITION_AUTRES_COMPETENCES.md ;
-- decision du directeur du 22/10 : DECISION-CANDIDATURES-2026-10-21.md, section
-- 1 quater. Contrat : CONTRAT_PORTS_CANDIDATURES.md, section 3 bis.
--
-- Cas couverts : (a) droits et empreintes F86 (sept RPC, quatorze aides internes,
-- trois tables fermees, aucune fonction hors lot ne lit la table des reponses ni
-- le catalogue, aucun nom en « candidature ») ; (b) refus par appelant (sans session, tuteur,
-- direction, comptabilite, enseignant sans candidature, compte desactive ;
-- le titulaire d'abord (42501), les arguments ensuite (22023)) ;
-- (c) avant l'envoi de la Salle d'examen : refus rendus sans ecriture, un
-- brouillon n'ouvre pas, un refus avant l'envoi dit « candidature close »,
-- puis l'envoi REEL par envoyer_reponses_salle_examen ouvre ; (d) enregistrer :
-- creation, idempotence (rejeu, cle reutilisee, cle d'un brouillon, ecriture
-- identique sans effet), rien d'autre que la ligne du titulaire ne bouge,
-- version attendue, forme des reponses (huit motifs), accord et sa date,
-- aucune reponse sous la cle, aucun effet sur la candidature (version,
-- activite, evenements) ; (e) a toute etape en cours : pause, Salle de
-- verification, Salle des prets a enseigner ; refusee ou retiree : enregistrer
-- refuse, lire et retirer permis, le rejeu d'une cle reussie passe avant la
-- cloture ; compte desactive : 42501 ; (f) retirer
-- (version, rejeu, rien a retirer, recreation) ; (g) lecture par la
-- direction : autresCompetences dans lire_candidature, portee par genre
-- (hors portee rendu et trace, super-admin journalise, genre inconnu refuse ;
-- chaque candidature lue par chaque direction ; le journal d'audit et ses
-- totaux bornes au cote de la candidature), liste a dix-neuf cles inchangee ;
-- (h) le filtre de lister_candidatures (domaine, niveau minimum, disponibilite,
-- accord, combinaisons, portee, total et lignes de l'autre cote, valeurs
-- invalides, audit) ; (i) jamais lues par un controle, le paiement ni
-- etat_dossier() (texte des fonctions avec sa contre-epreuve, et resultats
-- identiques avec et sans reponses) ; (j) contraintes de la table (defense en
-- profondeur : domaine hors du catalogue refuse par le declencheur) ;
-- (k) conservation : la ligne suit la candidature, ECART CONNU epingle
-- (anonymisation et export, CAND-Q21) ; (l) le catalogue des competences
-- (decision du directeur du 22/10 : des competences precises, regroupees par
-- famille, que la direction complete) : etat initial de 25 competences en six
-- familles, lecture (direction : tout ; candidat : l'actif et sa propre reponse),
-- ecriture reservee a la direction (refus par appelant, arguments, ajout, ordre,
-- rejeu et cle reutilisee, version attendue, modification identique, desactiver
-- et reactiver), journal et audit sans libelle, ni suppression ni vidage ni
-- changement de code ou de famille par aucune voie, contraintes de la table,
-- un code desactive (lisible dans une reponse ancienne, plus choisissable sauf
-- par qui l'a deja, retirable, cherchable), un code neuf offert aussitot, le
-- filtre de la liste de la direction par code OU par famille dans la portee par
-- genre, l'audit du catalogue, le plafond de 100 codes.
-- Chaque controle leve 'CAND-AUTRES ROUGE : ...' s'il echoue. A rejouer sur une
-- base NEUVE (stub_auth puis toutes les migrations) ; le scenario pose ses
-- propres fixtures, publie une version de TEST du cadre religieux dans sa
-- transaction, et annule tout a la fin.
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
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : %', p_label;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

CREATE FUNCTION pg_temp.garde(p_nom text, p_valeur jsonb) RETURNS void
LANGUAGE sql AS $$
  SELECT pg_catalog.set_config('test.' || p_nom, coalesce(p_valeur::text, 'null'), true);
$$;
CREATE FUNCTION pg_temp.lu(p_nom text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.current_setting('test.' || p_nom)::jsonb;
$$;

-- Un appel sous le role authenticated (la RLS et les ACL jouent), au nom d'un
-- compte ; le resultat jsonb est rendu apres retour au proprietaire.
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

-- Un appel qui doit etre refuse avec ce code, sous authenticated (ou anon).
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
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : % (aucun refus)', p_label;
  END IF;
  IF v_code <> p_code THEN
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : % (code % au lieu de % : %)', p_label, v_code, p_code, v_msg;
  END IF;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Un ordre du proprietaire qui doit etre refuse avec ce code (contraintes).
CREATE FUNCTION pg_temp.refus(p_sql text, p_code text, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : % (aucun refus)', p_label USING ERRCODE = 'P0001';
  EXCEPTION WHEN OTHERS THEN
    IF SQLSTATE <> p_code THEN
      RAISE EXCEPTION 'CAND-AUTRES ROUGE : % (code % au lieu de % : %)', p_label, SQLSTATE, p_code, SQLERRM;
    END IF;
  END;
  PERFORM pg_temp.ok(p_label);
END $$;

-- Tout ce qu'une ecriture peut toucher pour une candidature : sa ligne (version
-- et derniere activite comprises), les reponses du questionnaire, le journal des
-- evenements, les cles d'idempotence, l'audit des autres competences, et la
-- ligne des autres competences elle-meme.
CREATE FUNCTION pg_temp.trace(p_id uuid) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'ligne', (SELECT md5(to_jsonb(c)::text) FROM public.candidatures c WHERE c.id = p_id),
    'reponses', (SELECT md5(coalesce(string_agg(r.reponses::text || r.soumis_le::text, '|' ORDER BY r.id), ''))
                   FROM public.candidature_reponses r WHERE r.candidature_id = p_id),
    'evenements', (SELECT count(*) FROM public.candidature_evenements e WHERE e.candidature_id = p_id),
    'gestes', (SELECT count(*) FROM public.candidature_gestes g WHERE g.candidature_id = p_id),
    'audit', (SELECT count(*) FROM public.audit_logs a
               WHERE a.row_id = p_id::text AND a.action LIKE 'candidature\_autres\_competences%'),
    'talents', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, '|'), ''))
                  FROM public.candidature_autres_competences t WHERE t.candidature_id = p_id));
$$;

-- Tout ce qui n'est PAS la candidature p_id : les autres lignes d'autres
-- competences, les autres candidatures et les cles d'idempotence des autres.
-- Une ecriture du titulaire de p_id ne doit rien y changer.
CREATE FUNCTION pg_temp.hors(p_id uuid) RETURNS text
LANGUAGE sql AS $$
  SELECT md5(coalesce((SELECT string_agg(to_jsonb(t)::text, '|' ORDER BY t.candidature_id)
                         FROM public.candidature_autres_competences t WHERE t.candidature_id <> p_id), '')
          || '#' || coalesce((SELECT string_agg(to_jsonb(c)::text, '|' ORDER BY c.id)
                                FROM public.candidatures c WHERE c.id <> p_id), '')
          || '#' || coalesce((SELECT string_agg(g.cle, '|' ORDER BY g.cle)
                                FROM public.candidature_gestes g WHERE g.candidature_id <> p_id), ''));
$$;

CREATE FUNCTION pg_temp.p(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca7a0000-0000-4000-8000-0000000000' || p_n)::uuid $$;
CREATE FUNCTION pg_temp.c(p_n text) RETURNS uuid
LANGUAGE sql IMMUTABLE AS $$ SELECT ('ca7acccc-0000-4000-8000-0000000000' || p_n)::uuid $$;

-- Les identifiants d'une page de liste, dans l'ordre rendu, en numeros de
-- fixture (les deux derniers caracteres).
CREATE FUNCTION pg_temp.nos(p_page jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(right(t.l ->> 'id', 2) ORDER BY t.n), ARRAY[]::text[])
    FROM jsonb_array_elements(p_page -> 'lignes') WITH ORDINALITY AS t(l, n);
$$;

-- Les 25 codes du catalogue seme par la migration, dans l'ordre d'affichage
-- (famille, ordre) : la liste precise du directeur du 22/10.
CREATE FUNCTION pg_temp.catalogue_initial() RETURNS text[]
LANGUAGE sql IMMUTABLE AS $$
  SELECT ARRAY['reseaux_sociaux', 'relations_publiques', 'design_graphique', 'montage_video', 'photographie',
               'redaction_contenus', 'publicite_en_ligne', 'traduction',
               'assistanat', 'coordination_groupe', 'accueil_familles', 'gestion_projet', 'ressources_humaines',
               'comptabilite', 'gestion_financiere', 'juridique_donnees',
               'conception_programmes', 'formation_enseignants', 'qualite_cours', 'tests_niveau', 'accompagnement_enfants',
               'developpement', 'assistance_technique', 'donnees_tableurs',
               'autre']::text[]
$$;

-- Une fixture : compte enseignant, candidature, au besoin un document de
-- reponses ENVOYE (jamais un brouillon).
CREATE FUNCTION pg_temp.cand(p_n text, p_genre public.gender, p_etape text, p_etat text, p_issue text,
                             p_pause boolean, p_doc jsonb, p_statut text DEFAULT 'pending_kyc') RETURNS uuid
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO auth.users (id, email) VALUES (pg_temp.p(p_n), 'cand-autres-' || p_n || '@test.invalid');
  INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
  VALUES (pg_temp.p(p_n), 'CA7A-ENS-00' || p_n, 'teacher', 'Essai' || p_n, 'Fictif', p_statut::public.account_status,
          p_genre);
  INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, en_pause,
                                   pause_modele, issue_modele, source)
  VALUES (pg_temp.c(p_n), 'enseignant', pg_temp.p(p_n), p_genre, 'Fixture CA7 ' || p_n, p_etape, p_etat, p_issue,
          p_pause, CASE WHEN p_pause THEN 'pause_general' END,
          CASE WHEN p_issue = 'refusee' THEN 'refus_general' END, 'lien_public');
  IF p_doc IS NOT NULL THEN
    INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon,
                                             envoye_le)
    VALUES (pg_temp.c(p_n), 'salle-examen-1', p_doc || '{"accordRemuneration": true}'::jsonb, 'candidat', false,
            pg_catalog.clock_timestamp());
    UPDATE public.candidatures SET paiement = private.paiement_etat(id) WHERE id = pg_temp.c(p_n);
  END IF;
  RETURN pg_temp.c(p_n);
END $$;

-- Une ligne d'autres competences posee par le proprietaire (la voie des RPC
-- est testee a part) : pour les filtres.
CREATE FUNCTION pg_temp.talents(p_n text, p_domaines jsonb, p_texte text, p_dispo text, p_accord boolean) RETURNS void
LANGUAGE sql AS $$
  INSERT INTO public.candidature_autres_competences
    (candidature_id, domaines, autre_texte, disponibilite, accord_contact, accord_le)
  VALUES (pg_temp.c(p_n), p_domaines, p_texte, p_dispo, p_accord,
          CASE WHEN p_accord THEN pg_catalog.clock_timestamp() END);
$$;

GRANT EXECUTE ON FUNCTION pg_temp.qui(uuid, text, text), pg_temp.ok(text), pg_temp.vrai(boolean, text),
  pg_temp.garde(text, jsonb), pg_temp.lu(text), pg_temp.p(text), pg_temp.c(text), pg_temp.trace(uuid)
  TO authenticated, anon;

-- ------------------------------------------------------------
-- Fixtures (donnees inventees)
-- ------------------------------------------------------------
-- a1 direction homme, a2 direction femme, a3 direction au genre inconnu, a4
-- super-admin homme (exception de 0088), c1 comptable, e1 tuteur, b1
-- enseignant (provisoire) sans candidature.
INSERT INTO auth.users (id, email)
SELECT pg_temp.p(s), 'cand-autres-' || s || '@test.invalid'
FROM unnest(ARRAY['a1', 'a2', 'a3', 'a4', 'c1', 'e1', 'b1']) AS s;
INSERT INTO public.households (id, timezone) VALUES ('ca7affff-ffff-4fff-8fff-000000000001', 'Europe/Paris');
INSERT INTO public.profiles (id, immutable_id, role, household_id, first_name, last_name, account_status, gender)
VALUES
 (pg_temp.p('a1'), 'CA7A-ADM-0001', 'admin', NULL, 'Direction', 'Homme', 'active', 'male'),
 (pg_temp.p('a2'), 'CA7A-ADM-0002', 'admin', NULL, 'Direction', 'Femme', 'active', 'female'),
 (pg_temp.p('a3'), 'CA7A-ADM-0003', 'admin', NULL, 'Direction', 'Inconnu', 'active', NULL),
 (pg_temp.p('a4'), 'CA7A-ADM-0004', 'admin', NULL, 'Super', 'Admin', 'active', 'male'),
 (pg_temp.p('c1'), 'CA7A-CPT-0001', 'accountant', NULL, 'Compta', 'Essai', 'active', 'male'),
 (pg_temp.p('e1'), 'CA7A-TUT-0001', 'guardian', 'ca7affff-ffff-4fff-8fff-000000000001', 'Tuteur', 'Essai',
  'active', 'female'),
 (pg_temp.p('b1'), 'CA7A-ENS-00B1', 'teacher', NULL, 'Ancien', 'Enseignant', 'provisional_active', 'male');
INSERT INTO private.super_admin_kyc (profile_id) VALUES (pg_temp.p('a4'));
INSERT INTO public.app_config (key, value) VALUES ('kyc_exception_super_admin', 'true'::jsonb)
ON CONFLICT (key) DO UPDATE SET value = excluded.value;

SELECT pg_temp.garde('complet_sa', $j$
{"langueMaternelle": "ar", "languesExplication": ["francais", "poular"],
 "niveauMemorisationDeclare": "coran_entier", "niveauLectureTajwid": "tajwid_enseigne",
 "riwayat": ["hafs", "warsh"], "ijazaPresentable": "oui", "experienceDebutants": "oui",
 "disponibilitesDeclarees": [{"jour": 1, "debut": "20:00", "fin": "22:00"},
                              {"jour": 3, "debut": "22:00", "fin": "24:00"}],
 "fuseauIana": "Asia/Riyadh", "classesSouhaitees": "2", "debutPossible": "immediat",
 "publics": ["6_9", "adultes"], "paysResidence": "SA", "paysVersement": "SA", "compteBancaire": true,
 "operateurs": []}
$j$::jsonb);

-- Candidatures (hommes sauf 03, 13 et 14).
-- 01 salle d'examen, rien d'envoye ; 02 en examen, envoye (le sujet des
-- ecritures) ; 03 une femme, envoye ; 04 refusee, envoye, avec des reponses ;
-- 05 retiree, envoye ; 06 en pause en salle de verification ; 07 confirmee
-- (salle des prets a enseigner) ; 08 compte desactive ; 09 refusee sans jamais
-- avoir envoye ; 10 a 16 les donnees des filtres ; 17 un document de reponses sans
-- date d'envoi ; 19 le rejeu d'une cle reussie apres un refus ; 20 une confirmee qui
-- ecrit puis retire ; 18 de quoi epingler l'ecart de
-- conservation ; 21 une candidature d'un autre type que enseignant.
SELECT pg_temp.cand('01', 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL);
SELECT pg_temp.cand('02', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('03', 'female', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('04', 'male', 'prequalification', 'en_examen', 'refusee', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('05', 'male', 'prequalification', 'en_examen', 'retiree', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('06', 'male', 'verifications', 'entretien_planifie', 'en_cours', true, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('07', 'male', 'confirmee', NULL, 'en_cours', false, pg_temp.lu('complet_sa'), 'provisional_active');
SELECT pg_temp.cand('08', 'male', 'prequalification', 'en_examen', 'refusee', false, pg_temp.lu('complet_sa'),
                    'disabled');
SELECT pg_temp.cand('09', 'male', 'prequalification', 'a_completer', 'refusee', false, NULL);
SELECT pg_temp.cand('10', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('11', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('12', 'male', 'verifications', 'entretien_a_planifier', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('13', 'female', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('14', 'female', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('15', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('16', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('17', 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL);
SELECT pg_temp.cand('18', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('19', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('20', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));

-- 21 : une candidature d'un AUTRE type que enseignant (un type neuf), envoyee.
INSERT INTO public.candidature_types (code, role_compte) VALUES ('formateur', 'teacher');
SELECT pg_temp.cand('21', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
UPDATE public.candidatures SET type_code = 'formateur' WHERE id = pg_temp.c('21');

-- Les reponses des filtres, posees par le proprietaire.
-- 10 comptabilite metier, mi-temps, accord ; 11 comptabilite experience, plus,
-- accord ; 12 reseaux_sociaux debutant et developpement metier, quelques heures,
-- sans accord ; 13 (une femme) assistanat metier et accompagnement experience,
-- mi-temps, accord ; 14 (une femme) comptabilite metier, plus, accord ; 15 autre
-- experience avec un texte, pas maintenant, sans accord ; 16 aucune reponse.
SELECT pg_temp.talents('10', '{"comptabilite": "metier"}', NULL, 'mi_temps', true);
SELECT pg_temp.talents('11', '{"comptabilite": "experience"}', NULL, 'plus', true);
SELECT pg_temp.talents('12', '{"reseaux_sociaux": "debutant", "developpement": "metier"}', NULL, 'quelques_heures', false);
SELECT pg_temp.talents('13', '{"assistanat": "metier", "coordination_groupe": "experience"}', NULL, 'mi_temps', true);
SELECT pg_temp.talents('14', '{"comptabilite": "metier"}', NULL, 'plus', true);
SELECT pg_temp.talents('15', '{"autre": "experience"}', 'Calligraphie arabe', 'pas_maintenant', false);
-- 04, refusee, a deja donne ses reponses avant son refus.
SELECT pg_temp.talents('04', '{"traduction": "debutant"}', NULL, 'quelques_heures', true);

SELECT pg_temp.vrai((SELECT count(*) FROM public.candidatures WHERE id::text LIKE 'ca7acccc%') = 21
  AND (SELECT count(*) FROM public.candidature_autres_competences) = 7
  AND (SELECT genre FROM public.candidatures WHERE id = pg_temp.c('13')) = 'female'
  AND (SELECT count(*) FROM public.candidature_reponses r WHERE r.candidature_id = pg_temp.c('02')
        AND r.envoye_le IS NOT NULL AND NOT r.brouillon) = 1
  AND public.cadre_religieux_version_requise() IS NULL,
  'fixtures : 21 candidatures, 7 lignes d''autres competences, 13 et 14 du cote des femmes, aucun cadre publie');

-- ------------------------------------------------------------
-- (a) Droits, empreintes F86, aides internes, table
-- ------------------------------------------------------------
DO $f86$
DECLARE
  f regprocedure;
  r text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
      'public.lire_autres_competences()'::regprocedure,
      'public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)'::regprocedure,
      'public.retirer_autres_competences(integer,text)'::regprocedure,
      'public.lire_catalogue_competences()'::regprocedure,
      'public.enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)'::regprocedure,
      'public.lire_candidature(uuid)'::regprocedure,
      'public.lister_candidatures(jsonb,text,integer)'::regprocedure] LOOP
    IF NOT (SELECT prosecdef AND pg_get_userbyid(proowner) = 'postgres'
                   AND coalesce(proconfig @> ARRAY['search_path=""'], false)
            FROM pg_proc WHERE oid = f)
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%md5_functiondef=' || md5(pg_get_functiondef(f)) || '%'
       OR coalesce(obj_description(f, 'pg_proc'), '') NOT LIKE '%CAND-AUTRES%'
       OR NOT has_function_privilege('authenticated', f, 'EXECUTE')
       OR has_function_privilege('anon', f, 'EXECUTE')
       OR has_function_privilege('service_role', f, 'EXECUTE')
       OR has_function_privilege('agent_ro', f, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-AUTRES ROUGE : DEFINER, proprietaire, search_path, empreinte ou ACL de %', f;
    END IF;
    IF app_private.has_unsafe_role_guard((SELECT prosrc FROM pg_proc WHERE oid = f))
       OR (SELECT prosrc LIKE '%app_role()%' AND prosrc NOT LIKE '%app_account_valid%' FROM pg_proc WHERE oid = f) THEN
      RAISE EXCEPTION 'CAND-AUTRES ROUGE : garde negative ou sans app_account_valid dans %', f;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('sept RPC (trois du candidat, deux du catalogue, deux lectures redefinies) : DEFINER postgres, search_path vide, empreinte reelle, authenticated seul, garde positive');
  IF (SELECT array_agg(provolatile::text ORDER BY proname) FROM pg_proc
      WHERE pronamespace = 'public'::regnamespace
        AND proname IN ('lire_autres_competences', 'enregistrer_autres_competences', 'retirer_autres_competences',
                        'lire_catalogue_competences', 'enregistrer_competence_catalogue'))
     IS DISTINCT FROM ARRAY['v', 'v', 's', 's', 'v'] THEN
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : volatilite inattendue';
  END IF;
  PERFORM pg_temp.ok('les lectures sont STABLE, les enregistrements et le retrait VOLATILE');
  -- La garde du catalogue : la direction active (role ET compte valide) ; la lecture
  -- ouvre aussi au titulaire ; l'ecriture n'ouvre jamais au candidat.
  IF EXISTS (SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
              AND proname IN ('lire_catalogue_competences', 'enregistrer_competence_catalogue')
              AND (prosrc NOT LIKE '%app_role() = ''admin''%' OR prosrc NOT LIKE '%app_account_valid()%'))
     OR (SELECT prosrc LIKE '%competences_titulaire%' FROM pg_proc
          WHERE pronamespace = 'public'::regnamespace AND proname = 'enregistrer_competence_catalogue') THEN
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : la garde du catalogue doit etre la direction active (la lecture, aussi le titulaire), jamais le candidat pour ecrire';
  END IF;
  PERFORM pg_temp.ok('la garde du catalogue est positive : direction active (role et compte valide) ; la lecture ouvre aussi au titulaire, l''ecriture jamais');
  -- La garde des trois RPC du candidat n'est pas une comparaison de role.
  IF EXISTS (SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
              AND proname IN ('lire_autres_competences', 'enregistrer_autres_competences', 'retirer_autres_competences')
              AND (prosrc LIKE '%app_role()%' OR prosrc NOT LIKE '%private.competences_titulaire()%')) THEN
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : la garde du candidat doit etre la candidature du titulaire, jamais un role';
  END IF;
  PERFORM pg_temp.ok('la garde du candidat est la candidature du titulaire (compte valide, type enseignant), jamais un role');
  FOR f IN SELECT p.oid::regprocedure FROM pg_proc p
           WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'competences\_%' LOOP
    FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF has_function_privilege(r, f, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-AUTRES ROUGE : aide interne % executable par %', f, r;
      END IF;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname LIKE 'competences\_%') = 14,
    'quatorze aides competences_ (dont les declencheurs), executables par aucun compte');
  PERFORM pg_temp.vrai((SELECT count(*) FROM pg_proc WHERE pronamespace = 'private'::regnamespace
                         AND proname LIKE 'cand\_%') = 9,
    'aucune aide cand_ de plus : les neuf de CAND-L1');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
         AND proname LIKE '%candidature%' AND has_function_privilege('authenticated', oid, 'EXECUTE')
         AND proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature',
                             'lire_contact_candidature', 'historique_candidature')),
    'aucune RPC du lot ne contient « candidature » : etat_dossier() reste la seule lecture de l''etat du candidat');
  PERFORM pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM pg_proc WHERE pronamespace = 'public'::regnamespace
         AND proname LIKE '%autres\_competences' AND provolatile = 'v' AND has_function_privilege('anon', oid, 'EXECUTE')),
    'aucune RPC du lot n''est ouverte a anon');
END $f86$;

DO $tables$
DECLARE
  r text;
BEGIN
  PERFORM pg_temp.vrai((SELECT relrowsecurity FROM pg_class WHERE oid = 'public.candidature_autres_competences'::regclass)
    AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'candidature_autres_competences'),
    'la table des autres competences : RLS active, aucune policy');
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF has_table_privilege(r, 'public.candidature_autres_competences',
         'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
      RAISE EXCEPTION 'CAND-AUTRES ROUGE : % a un privilege sur la table', r;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('la table est fermee a anon, authenticated, service_role et agent_ro');
  -- Le catalogue et son journal : fermes de la meme maniere, sans policy ni sequence ouverte.
  PERFORM pg_temp.vrai((SELECT bool_and(relrowsecurity) FROM pg_class
                         WHERE oid IN ('public.competences_catalogue'::regclass, 'public.competences_catalogue_journal'::regclass))
    AND NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename IN ('competences_catalogue', 'competences_catalogue_journal')),
    'le catalogue et son journal : RLS active, aucune policy');
  FOREACH r IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF has_table_privilege(r, 'public.competences_catalogue', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_table_privilege(r, 'public.competences_catalogue_journal', 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
       OR has_sequence_privilege(r, 'public.competences_catalogue_journal_id_seq', 'USAGE,SELECT,UPDATE') THEN
      RAISE EXCEPTION 'CAND-AUTRES ROUGE : % a un privilege sur le catalogue, son journal ou sa sequence', r;
    END IF;
  END LOOP;
  PERFORM pg_temp.ok('le catalogue, son journal et sa sequence sont fermes a anon, authenticated, service_role et agent_ro');
  -- Les cles d'idempotence ne passent pas par la table des regles du moteur :
  -- ses lignes ne changent pas (aucun geste « enregistrer_autres_competences »).
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles
                                    WHERE geste LIKE '%autres%competences%'),
    'le moteur de transitions n''a aucune regle pour ces ecritures : ce ne sont pas des transitions');
END $tables$;

-- Aucune fonction hors lot ne cite la table (C8). Le balayage a sa contre-epreuve :
-- une fonction d'essai qui la cite est vue, puis retiree.
CREATE FUNCTION pg_temp.citeurs() RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(n.nspname || '.' || p.proname ORDER BY n.nspname || '.' || p.proname), ARRAY[]::text[])
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname IN ('public', 'private', 'app_private')
     AND p.prosrc LIKE '%candidature_autres_competences%';
$$;
SELECT pg_temp.vrai(pg_temp.citeurs() = ARRAY[
    'public.enregistrer_autres_competences',
    'public.lire_autres_competences',
    'public.lire_candidature',
    'public.lire_catalogue_competences',
    'public.lister_candidatures',
    'public.retirer_autres_competences'],
  'seules les trois RPC du candidat, la lecture du catalogue (sa propre reponse) et les deux lectures de la direction citent la table des reponses : ni controle, ni paiement, ni transition, ni etat_dossier()');
-- Le catalogue : cite par le lot seulement (aides competences_, quatre RPC), jamais par un controle,
-- le paiement, une transition ni etat_dossier(). Meme balayage, meme contre-epreuve.
CREATE FUNCTION pg_temp.citeurs_catalogue() RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(n.nspname || '.' || p.proname ORDER BY n.nspname || '.' || p.proname), ARRAY[]::text[])
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname IN ('public', 'private', 'app_private')
     AND p.prosrc LIKE '%competences_catalogue%'
     AND NOT (n.nspname = 'private' AND p.proname LIKE 'competences\_%');
$$;
SELECT pg_temp.vrai(pg_temp.citeurs_catalogue() = ARRAY[
    'public.enregistrer_competence_catalogue',
    'public.lire_catalogue_competences',
    'public.lister_candidatures'],
  'seuls la lecture et l''ecriture du catalogue, et le filtre de la liste de la direction, citent le catalogue (les aides competences_ mises a part) : ni controle, ni paiement, ni transition, ni etat_dossier(), ni les RPC du candidat directement');
CREATE FUNCTION private.zz_essai_citeur_catalogue() RETURNS integer LANGUAGE sql AS
  $$ SELECT count(*)::integer FROM public.competences_catalogue $$;
SELECT pg_temp.vrai(pg_temp.citeurs_catalogue() @> ARRAY['private.zz_essai_citeur_catalogue'],
  'contre-epreuve du balayage du catalogue : une fonction d''essai qui le cite est vue');
DROP FUNCTION private.zz_essai_citeur_catalogue();
CREATE FUNCTION private.zz_essai_citeur() RETURNS integer LANGUAGE sql AS
  $$ SELECT count(*)::integer FROM public.candidature_autres_competences $$;
SELECT pg_temp.vrai(pg_temp.citeurs() @> ARRAY['private.zz_essai_citeur'],
  'contre-epreuve du balayage : une fonction d''essai qui cite la table est vue');
DROP FUNCTION private.zz_essai_citeur();
SELECT pg_temp.vrai(NOT (pg_temp.citeurs() @> ARRAY['private.zz_essai_citeur']),
  'contre-epreuve du balayage : la fonction d''essai retiree n''est plus vue');

-- ------------------------------------------------------------
-- (b) Refus par appelant : les trois RPC du candidat
-- ------------------------------------------------------------
DO $appelants$
DECLARE
  v_appel text;
  v_label text;
  v_qui record;
BEGIN
  FOR v_appel, v_label IN SELECT * FROM (VALUES
      ('SELECT public.lire_autres_competences()', 'lire'),
      ('SELECT public.enregistrer_autres_competences(''{"comptabilite": "metier"}'', NULL, ''mi_temps'', true, 0, ''cle-appelant-1'')', 'enregistrer'),
      ('SELECT public.retirer_autres_competences(0, ''cle-appelant-2'')', 'retirer')) AS t(a, l) LOOP
    FOR v_qui IN SELECT * FROM (VALUES
        (pg_temp.p('e1'), 'guardian', 'tuteur'),
        (pg_temp.p('a1'), 'admin', 'direction'),
        (pg_temp.p('c1'), 'accountant', 'comptabilite'),
        (pg_temp.p('b1'), 'teacher', 'enseignant sans candidature'),
        (pg_temp.p('08'), 'teacher', 'candidat au compte desactive'),
        (NULL::uuid, NULL::text, 'session sans compte')) AS q(id, role, nom) LOOP
      PERFORM pg_temp.refus_en(v_qui.id, v_qui.role, v_appel, '42501', v_label || ' : ' || v_qui.nom || ' refuse (42501)');
    END LOOP;
    PERFORM pg_temp.refus_en(NULL, NULL, v_appel, '42501', v_label || ' : anon refuse (42501)', 'anon');
  END LOOP;
END $appelants$;

-- Une candidature d'un autre type que enseignant n'ouvre rien (21).
DO $type$
DECLARE
  v_appel text;
BEGIN
  FOREACH v_appel IN ARRAY ARRAY[
    'SELECT public.lire_autres_competences()',
    'SELECT public.enregistrer_autres_competences(''{"comptabilite": "metier"}'', NULL, ''mi_temps'', true, 0, ''cle-type-21-a'')',
    'SELECT public.retirer_autres_competences(0, ''cle-type-21-b'')'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('21'), 'teacher', v_appel, '42501',
      'candidature d''un autre type que enseignant : refus (42501) : ' || left(v_appel, 40));
  END LOOP;
END $type$;

-- L'ordre des refus : le titulaire d'abord (42501), les arguments ensuite (22023). Un
-- compte qui n'est pas le titulaire n'apprend rien de la validation des arguments.
DO $ordre$
DECLARE
  v_appel text;
BEGIN
  FOREACH v_appel IN ARRAY ARRAY[
    'SELECT public.enregistrer_autres_competences(NULL, NULL, NULL, NULL, NULL, NULL)',
    'SELECT public.enregistrer_autres_competences(''[]'', NULL, ''toujours'', NULL, -5, ''x'')',
    'SELECT public.retirer_autres_competences(NULL, NULL)',
    'SELECT public.retirer_autres_competences(-5, ''x'')'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('e1'), 'guardian', v_appel, '42501',
      'arguments invalides par un compte qui n''est pas le titulaire : 42501 avant 22023 : ' || left(v_appel, 50));
  END LOOP;
END $ordre$;

-- Aucun acces direct a la table, quel que soit le role.
DO $direct$
DECLARE
  v_sql text;
BEGIN
  FOREACH v_sql IN ARRAY ARRAY[
    'SELECT count(*) FROM public.candidature_autres_competences',
    'INSERT INTO public.candidature_autres_competences (candidature_id, domaines, disponibilite, accord_contact) VALUES (''ca7acccc-0000-4000-8000-000000000020'', ''{"comptabilite": "metier"}'', ''plus'', false)',
    'UPDATE public.candidature_autres_competences SET accord_contact = false',
    'DELETE FROM public.candidature_autres_competences'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('02'), 'teacher', v_sql, '42501', 'candidat : acces direct refuse : ' || left(v_sql, 30));
    PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', v_sql, '42501', 'direction : acces direct refuse : ' || left(v_sql, 30));
  END LOOP;
END $direct$;

-- ------------------------------------------------------------
-- (c) Avant l'envoi de la Salle d'examen
-- ------------------------------------------------------------
SELECT pg_temp.garde('l01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w01', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-01-avant')$$));
SELECT pg_temp.garde('r01', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.retirer_autres_competences(0, 'cle-ac-01-retrait')$$));
SELECT pg_temp.vrai(pg_temp.lu('l01') @> '{"ouvert": false, "raison": "questionnaire_non_envoye", "version": 0, "reponses": null}'::jsonb
  AND (SELECT array_agg(c ->> 'code') FROM jsonb_array_elements(pg_temp.lu('l01') #> '{referentiel,competences}') c)
        = pg_temp.catalogue_initial()
  AND pg_temp.lu('l01') #> '{referentiel,familles}'
        = '["communication", "administration", "finances_droit", "pedagogie", "technique", "autre"]'::jsonb
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l01') #> '{referentiel,competences}') c
                   WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(c) k)
                         IS DISTINCT FROM ARRAY['actif', 'code', 'exemple', 'famille', 'libelle', 'ordre'])
  AND pg_temp.lu('l01') #> '{referentiel,niveaux}' = '["debutant", "experience", "metier"]'::jsonb
  AND pg_temp.lu('l01') #> '{referentiel,disponibilites}' = '["quelques_heures", "mi_temps", "plus", "pas_maintenant"]'::jsonb
  AND pg_temp.lu('l01') #>> '{referentiel,autreTexteMax}' = '200',
  'avant l''envoi : la lecture dit « pas ouvert », pourquoi, et rend les familles, le catalogue actif (25 competences, six cles chacune, sans version) et les listes fermees dans leur ordre d''affichage');
SELECT pg_temp.vrai(pg_temp.lu('w01') = '{"erreur": "questionnaire_non_envoye", "issue": "en_cours"}'::jsonb
  AND pg_temp.lu('r01') ->> 'retire' = 'false'
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('01')) = 0,
  'avant l''envoi : enregistrer refuse (questionnaire_non_envoye), retirer ne trouve rien, aucune ligne');

-- Un brouillon n'est pas un envoi.
SELECT pg_temp.garde('b01', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.enregistrer_reponses_salle_examen('salle-examen-1', current_setting('test.complet_sa')::jsonb, 0, 'cle-brouillon-ca7-01')$$));
SELECT pg_temp.garde('w01b', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-01-brouillon')$$));
SELECT pg_temp.vrai(pg_temp.lu('b01') ->> 'complet' = 'true'
  AND pg_temp.lu('w01b') = '{"erreur": "questionnaire_non_envoye", "issue": "en_cours"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_reponses WHERE candidature_id = pg_temp.c('01') AND brouillon) = 1
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('01')) = 0
  AND (SELECT count(*) FROM public.candidature_gestes WHERE cle IN ('cle-ac-01-avant', 'cle-ac-01-brouillon')) = 0,
  'un brouillon complet n''ouvre pas : enregistrer refuse toujours, aucune ligne, aucune cle gardee (un refus se rejoue avec la meme cle)');

-- Un document sans date d'envoi n'est pas un envoi (17), meme s'il n'est pas un brouillon.
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
VALUES (pg_temp.c('17'), 'salle-examen-1', '{}'::jsonb, 'candidat', false, NULL);
SELECT pg_temp.garde('w17', pg_temp.en(pg_temp.p('17'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-17-001')$$));
DELETE FROM public.candidature_reponses WHERE candidature_id = pg_temp.c('17');
SELECT pg_temp.vrai(pg_temp.lu('w17') = '{"erreur": "questionnaire_non_envoye", "issue": "en_cours"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('17')) = 0,
  'un document de reponses sans date d''envoi n''ouvre pas (questionnaire_non_envoye), aucune ligne');

-- Un refus avant tout envoi : « candidature close », pas « envoi requis ».
SELECT pg_temp.garde('l09', pg_temp.en(pg_temp.p('09'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w09', pg_temp.en(pg_temp.p('09'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-09-avant')$$));
SELECT pg_temp.vrai(pg_temp.lu('l09') @> '{"ouvert": false, "raison": "candidature_close", "version": 0}'::jsonb
  AND pg_temp.lu('w09') = '{"erreur": "candidature_close", "issue": "refusee"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('09')) = 0,
  'refusee avant l''envoi : candidature_close avec l''issue, aucune ligne');

-- L'envoi REEL ouvre : cadre religieux de TEST publie et accepte, puis
-- envoyer_reponses_salle_examen.
INSERT INTO public.contract_required_versions (contract_kind, version)
VALUES ('teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.qui(pg_temp.p('01'), 'teacher');
SET LOCAL ROLE authenticated;
INSERT INTO public.contract_acceptances (profile_id, contract_kind, version)
VALUES ('ca7a0000-0000-4000-8000-000000000001', 'teacher_religious_framework', 'test-cadre-1');
SELECT pg_temp.garde('e01', public.envoyer_reponses_salle_examen('salle-examen-1',
  current_setting('test.complet_sa')::jsonb, true, 'v2.0.0', 1, 'cle-envoi-ca7-01'));
RESET ROLE;
SELECT pg_temp.garde('l01b', pg_temp.en(pg_temp.p('01'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w01c', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"reseaux_sociaux": "experience"}', NULL, 'quelques_heures', true, 0, 'cle-ac-01-apres')$$));
SELECT pg_temp.vrai(pg_temp.lu('e01') -> 'candidature' @> '{"etape": "prequalification", "etat": "en_examen"}'::jsonb
  AND pg_temp.lu('l01b') @> '{"ouvert": true, "raison": null, "version": 0, "reponses": null}'::jsonb
  AND pg_temp.lu('w01c') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT domaines = '{"reseaux_sociaux": "experience"}' FROM public.candidature_autres_competences
        WHERE candidature_id = pg_temp.c('01')),
  'apres l''envoi reel (transition 6) : la lecture dit « ouvert » et la premiere ecriture passe, de bout en bout');

-- ------------------------------------------------------------
-- (d) Enregistrer : creation, idempotence, version, forme
-- ------------------------------------------------------------
-- 02 : l'etat vu par ailleurs avant toute reponse (pour (i)).
SELECT pg_temp.garde('avant_etat', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.garde('avant_ctrl', (SELECT jsonb_build_object(
    'paiement', private.paiement_etat(c.id),
    'entree', private.candidature_controles_entree(c, 'admission'),
    'questionnaire', private.candidature_questionnaire_envoye(c),
    'direction', private.candidature_etat_direction(c.id))
  FROM public.candidatures c WHERE c.id = pg_temp.c('02')));
SELECT pg_temp.garde('avant_dossier', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000002') - 'autresCompetences'$$));
SELECT pg_temp.garde('t02', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('l02', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w02', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "autre": "experience"}',
      '  Calligraphie arabe  ', 'mi_temps', true, 0, 'cle-ac-02-001')$$));
SELECT pg_temp.garde('l02b', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.vrai(pg_temp.lu('l02') @> '{"ouvert": true, "raison": null, "version": 0, "reponses": null}'::jsonb
  AND pg_temp.lu('w02') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('l02b') @> '{"ouvert": true, "version": 1}'::jsonb
  AND pg_temp.lu('l02b') #> '{reponses,domaines}' = '{"comptabilite": "metier", "autre": "experience"}'::jsonb
  AND pg_temp.lu('l02b') #>> '{reponses,autreTexte}' = 'Calligraphie arabe'
  AND pg_temp.lu('l02b') #>> '{reponses,disponibilite}' = 'mi_temps'
  AND pg_temp.lu('l02b') #> '{reponses,accord}' = 'true'::jsonb
  AND pg_temp.lu('l02b') #>> '{reponses,accordLe}' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$'
  AND pg_temp.lu('l02b') #>> '{reponses,majLe}' ~ 'Z$',
  'creation : version 1, texte « autre » sans blancs de tete ni de queue, accord et sa date, instants en UTC (Z)');
SELECT pg_temp.vrai(pg_temp.trace(pg_temp.c('02')) ->> 'ligne' = pg_temp.lu('t02') ->> 'ligne'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'reponses' = pg_temp.lu('t02') ->> 'reponses'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'evenements' = pg_temp.lu('t02') ->> 'evenements'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'gestes' = (pg_temp.lu('t02') ->> 'gestes')::int + 1 || ''
  AND pg_temp.trace(pg_temp.c('02')) ->> 'audit' = '1',
  'C5 : la ligne de la candidature (version, derniere activite), ses reponses et son journal d''evenements ne bougent pas ; une cle gardee, une ligne d''audit');
SELECT pg_temp.vrai((SELECT resultat FROM public.candidature_gestes WHERE cle = 'cle-ac-02-001')
      = '{"version": 1, "inchange": false}'::jsonb
  AND (SELECT geste = 'enregistrer_autres_competences' AND auteur_id = pg_temp.p('02')
         FROM public.candidature_gestes WHERE cle = 'cle-ac-02-001')
  AND (SELECT payload ->> 'version' = '1' AND payload ->> 'domaines' = '2' AND payload ->> 'accord' = 'true'
              AND payload::text NOT LIKE '%comptabilite%' AND payload::text NOT LIKE '%Calligraphie%'
         FROM public.audit_logs WHERE row_id = pg_temp.c('02')::text
          AND action = 'candidature_autres_competences_enregistrees'),
  'aucune reponse sous la cle gardee ni dans l''audit : la version, le nombre de domaines et l''accord seulement');

-- Rejeu de la meme cle : le premier resultat, sans ecriture, meme avec un autre contenu.
SELECT pg_temp.garde('t02b', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('w02r', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "autre": "experience"}',
      '  Calligraphie arabe  ', 'mi_temps', true, 0, 'cle-ac-02-001')$$));
SELECT pg_temp.garde('w02r2', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"assistanat": "debutant"}', NULL, 'plus', false, 7, 'cle-ac-02-001')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02r') = '{"version": 1, "inchange": false, "rejoue": true}'::jsonb
  AND pg_temp.lu('w02r2') = '{"version": 1, "inchange": false, "rejoue": true}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02b'),
  'idempotence : la meme cle rend le premier resultat (rejoue = true), meme avec une version et un contenu differents, 0 ecriture');
-- Une cle reutilisee : par une autre candidature, par un autre geste.
SELECT pg_temp.garde('w03k', pg_temp.en(pg_temp.p('03'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-02-001')$$));
SELECT pg_temp.garde('r02k', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.retirer_autres_competences(1, 'cle-ac-02-001')$$));
SELECT pg_temp.garde('w02k', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 1,
      'cle-envoi-ca7-01')$$));
SELECT pg_temp.vrai(pg_temp.lu('w03k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('r02k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('w02k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02b')
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('03')) = 0,
  'une cle reutilisee par une autre candidature, un autre geste ou le geste d''envoi est refusee, 0 ecriture');

-- La cle du brouillon de la Salle d'examen (01) ne se rejoue pas comme une ecriture.
SELECT pg_temp.garde('w01k', pg_temp.en(pg_temp.p('01'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 1,
      'cle-brouillon-ca7-01')$$));
SELECT pg_temp.vrai(pg_temp.lu('w01k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND (SELECT version = 1 AND domaines = '{"reseaux_sociaux": "experience"}'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('01')),
  'la cle du brouillon de la Salle d''examen est refusee (cle_idempotence_reutilisee) : elle ne rejoue pas une ecriture des autres competences, 0 ecriture');

-- Version attendue.
SELECT pg_temp.garde('w02v', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, 0, 'cle-ac-02-002')$$));
SELECT pg_temp.garde('w02v2', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, 2, 'cle-ac-02-003')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02v') = '{"erreur": "conflit_autres_competences", "versionCourante": 1}'::jsonb
  AND pg_temp.lu('w02v2') = '{"erreur": "conflit_autres_competences", "versionCourante": 1}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02b')
  AND (SELECT count(*) FROM public.candidature_gestes WHERE cle IN ('cle-ac-02-002', 'cle-ac-02-003')) = 0,
  'version attendue perimee (trop basse ou trop haute) : conflit_autres_competences avec la version courante, 0 ecriture, cle non gardee');

-- Ecriture identique : rien ne change (ni version, ni date d'accord, ni audit).
SELECT pg_temp.garde('d02', (SELECT jsonb_build_object('accord_le', accord_le, 'maj_le', maj_le, 'version', version)
                               FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')));
SELECT pg_temp.garde('w02i', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"autre": "experience", "comptabilite": "metier"}',
      'Calligraphie arabe', 'mi_temps', true, 1, 'cle-ac-02-004')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02i') = '{"version": 1, "inchange": true, "rejoue": false}'::jsonb
  AND (SELECT jsonb_build_object('accord_le', accord_le, 'maj_le', maj_le, 'version', version)
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')) = pg_temp.lu('d02')
  AND pg_temp.trace(pg_temp.c('02')) ->> 'audit' = '1'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'talents' = pg_temp.lu('t02b') ->> 'talents'
  AND (SELECT resultat FROM public.candidature_gestes WHERE cle = 'cle-ac-02-004') = '{"version": 1, "inchange": true}'::jsonb,
  'une ecriture identique (ordre des domaines et blancs du texte sans effet) : inchange = true, version, date d''accord et audit intacts, la cle est gardee');

-- Un vrai changement : version 2, nouvelle date d'accord.
SELECT pg_temp.garde('h02', to_jsonb(pg_temp.hors(pg_temp.c('02'))));
SELECT pg_temp.garde('w02c', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "reseaux_sociaux": "debutant"}',
      NULL, 'plus', true, 1, 'cle-ac-02-005')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02c') = '{"version": 2, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT version = 2 AND autre_texte IS NULL AND disponibilite = 'plus' AND accord_le > (pg_temp.lu('d02') ->> 'accord_le')::timestamptz
              AND maj_le > (pg_temp.lu('d02') ->> 'maj_le')::timestamptz AND domaines ? 'reseaux_sociaux' AND NOT domaines ? 'autre'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02'))
  AND pg_temp.trace(pg_temp.c('02')) ->> 'audit' = '2'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'ligne' = pg_temp.lu('t02') ->> 'ligne',
  'un changement : version 2, « autre » et son texte retires, nouvelle date d''accord, un second audit, la candidature intacte');
SELECT pg_temp.vrai(pg_temp.hors(pg_temp.c('02')) = (pg_temp.lu('h02') #>> '{}'),
  'une ecriture ne touche que la ligne de son titulaire : les autres lignes d''autres competences, les autres candidatures et les cles des autres sont intactes');
-- L'accord retire (les reponses restent) : plus de date d'accord.
SELECT pg_temp.garde('w02a', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "reseaux_sociaux": "debutant"}',
      NULL, 'plus', false, 2, 'cle-ac-02-006')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02a') = '{"version": 3, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT NOT accord_contact AND accord_le IS NULL AND domaines = '{"comptabilite": "metier", "reseaux_sociaux": "debutant"}'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02'))
  AND pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_autres_competences()$$) #> '{reponses,accord}' = 'false'::jsonb
  AND pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_autres_competences()$$) #> '{reponses,accordLe}' = 'null'::jsonb,
  'retirer son accord sans retirer ses reponses : accord = false, aucune date, les domaines restent');
-- Remettre l'accord pour la suite.
SELECT pg_temp.garde('w02b', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "reseaux_sociaux": "debutant"}',
      NULL, 'plus', true, 3, 'cle-ac-02-007')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02b') ->> 'version' = '4', 'accord redonne : version 4');

-- Arguments absents ou mal formes : 22023.
SELECT pg_temp.garde('t02a', pg_temp.trace(pg_temp.c('02')));
DO $args$
DECLARE
  v_sql text;
BEGIN
  FOREACH v_sql IN ARRAY ARRAY[
    $q$SELECT public.enregistrer_autres_competences(NULL, NULL, 'plus', true, 4, 'cle-ac-02-a01')$q$,
    $q$SELECT public.enregistrer_autres_competences('["comptabilite"]', NULL, 'plus', true, 4, 'cle-ac-02-a02')$q$,
    $q$SELECT public.enregistrer_autres_competences('"comptabilite"', NULL, 'plus', true, 4, 'cle-ac-02-a03')$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, NULL, true, 4, 'cle-ac-02-a04')$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', NULL, 4, 'cle-ac-02-a05')$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, NULL, 'cle-ac-02-a06')$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, -1, 'cle-ac-02-a07')$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, 4, NULL)$q$,
    $q$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'plus', true, 4, 'court')$q$,
    $q$SELECT public.retirer_autres_competences(NULL, 'cle-ac-02-a08')$q$,
    $q$SELECT public.retirer_autres_competences(-1, 'cle-ac-02-a09')$q$,
    $q$SELECT public.retirer_autres_competences(4, NULL)$q$,
    $q$SELECT public.retirer_autres_competences(4, 'court')$q$] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('02'), 'teacher', v_sql, '22023', 'argument invalide : 22023 : ' || left(v_sql, 80));
  END LOOP;
END $args$;
SELECT pg_temp.vrai(pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02a')
  AND (SELECT version FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')) = 4,
  'les 13 arguments refuses n''ont rien ecrit : la ligne est a la version 4');

-- Forme des reponses : huit motifs, aucune ecriture ni cle gardee.
SELECT pg_temp.garde('t02f', pg_temp.trace(pg_temp.c('02')));
CREATE FUNCTION pg_temp.essai(p_domaines text, p_texte text, p_dispo text, p_cle text) RETURNS jsonb
LANGUAGE plpgsql AS $$
BEGIN
  RETURN pg_temp.en('ca7a0000-0000-4000-8000-000000000002'::uuid, 'teacher',
    pg_catalog.format($q$SELECT public.enregistrer_autres_competences(%L::jsonb, %L, %L, true, 4, %L)$q$,
                      p_domaines, p_texte, p_dispo, p_cle));
END $$;
SELECT pg_temp.vrai(
      pg_temp.essai('{}', NULL, 'plus', 'cle-ac-02-f01')
        = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaines_requis"}}'::jsonb
  AND pg_temp.essai('{"cuisine": "metier"}', NULL, 'plus', 'cle-ac-02-f02')
        = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaine_inconnu"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": "expert"}', NULL, 'plus', 'cle-ac-02-f03')
        = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "niveau_invalide"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": 3}', NULL, 'plus', 'cle-ac-02-f04')
        = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "niveau_invalide"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": null}', NULL, 'plus', 'cle-ac-02-f05')
        = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "niveau_invalide"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": "metier"}', NULL, 'toujours', 'cle-ac-02-f06')
        = '{"erreur": "reponses_invalides", "champs": ["disponibilite"], "motifs": {"disponibilite": "disponibilite_inconnue"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": "metier"}', NULL, '', 'cle-ac-02-f07')
        = '{"erreur": "reponses_invalides", "champs": ["disponibilite"], "motifs": {"disponibilite": "disponibilite_inconnue"}}'::jsonb,
  'domaines et disponibilite : vide, inconnu, niveau inconnu, non texte, nul, disponibilite inconnue ou vide : reponses_invalides avec le champ et son motif');
SELECT pg_temp.vrai(
      pg_temp.essai('{"autre": "metier"}', NULL, 'plus', 'cle-ac-02-g01')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_requis"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', E'  \t \n ', 'plus', 'cle-ac-02-g02')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_requis"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": "metier"}', 'Un texte sans « autre »', 'plus', 'cle-ac-02-g03')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_non_attendu"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', repeat('a', 201), 'plus', 'cle-ac-02-g04')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_trop_long"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', E'deux\nlignes', 'plus', 'cle-ac-02-g05')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_invalide"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', E'tab\tulation', 'plus', 'cle-ac-02-g06')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_invalide"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', E'nul' || chr(133) || 'nel', 'plus', 'cle-ac-02-g07')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_invalide"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', 'sep' || chr(8232) || 'ligne', 'plus', 'cle-ac-02-g08')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_invalide"}}'::jsonb
  AND pg_temp.essai('{"autre": "metier"}', 'sep' || chr(8233) || 'paragraphe', 'plus', 'cle-ac-02-g09')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_invalide"}}'::jsonb,
  'texte « autre » : exige, refuse sans « autre », trop long (201), sur plusieurs lignes, avec un caractere de controle (tabulation, NEL) ou un separateur de ligne ou de paragraphe Unicode : refus nommes');
SELECT pg_temp.vrai(
      pg_temp.essai('{"cuisine": "x"}', 'texte', 'toujours', 'cle-ac-02-h01')
        = '{"erreur": "reponses_invalides", "champs": ["domaines", "autreTexte", "disponibilite"],
            "motifs": {"domaines": "domaine_inconnu", "autreTexte": "texte_non_attendu", "disponibilite": "disponibilite_inconnue"}}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02f')
  AND (SELECT count(*) FROM public.candidature_gestes WHERE cle LIKE 'cle-ac-02-f0_' OR cle LIKE 'cle-ac-02-g0_'
         OR cle LIKE 'cle-ac-02-h0_') = 0,
  'trois champs fautifs a la fois : tous nommes dans l''ordre domaines, autreTexte, disponibilite ; les 17 refus de forme n''ont ecrit ni ligne, ni audit, ni cle');
-- Un texte enorme est refuse avant toute normalisation (plus de 1000 signes), que ce soient des
-- blancs ou des lettres.
SELECT pg_temp.vrai(
      pg_temp.essai('{"autre": "metier"}', repeat(' ', 200000) || 'x', 'plus', 'cle-ac-02-i01')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_trop_long"}}'::jsonb
  AND pg_temp.essai('{"comptabilite": "metier"}', repeat('a', 1001), 'plus', 'cle-ac-02-i02')
        = '{"erreur": "reponses_invalides", "champs": ["autreTexte"], "motifs": {"autreTexte": "texte_trop_long"}}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02f'),
  'un texte de plus de 1000 signes est refuse (texte_trop_long) avant toute normalisation, 0 ecriture');
-- Les bornes qui passent : 200 caracteres, un texte sans « autre » fait de blancs, les neuf domaines.
SELECT pg_temp.garde('w02n', pg_temp.en(pg_temp.p('02'), 'teacher', pg_catalog.format(
  $q$SELECT public.enregistrer_autres_competences('{"assistanat": "debutant", "coordination_groupe": "debutant", "comptabilite": "experience",
     "reseaux_sociaux": "experience", "developpement": "metier", "traduction": "metier", "formation_enseignants": "debutant",
     "accueil_familles": "experience", "autre": "metier"}', %L, 'quelques_heures', true, 4, 'cle-ac-02-009')$q$, repeat('é', 200))));
SELECT pg_temp.vrai(pg_temp.lu('w02n') = '{"version": 5, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT length(autre_texte) = 200 AND (SELECT count(*) FROM jsonb_object_keys(domaines)) = 9
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')),
  'les bornes qui passent : les neuf domaines, un texte de 200 caracteres (« é » compte pour un)');
SELECT pg_temp.garde('w02w', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', E' \t ', 'mi_temps', true, 5, 'cle-ac-02-010')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02w') = '{"version": 6, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT autre_texte IS NULL AND domaines = '{"comptabilite": "metier"}'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')),
  'un texte fait de blancs sans « autre » vaut aucun texte : accepte, rien de garde');

-- ------------------------------------------------------------
-- (e) A toute etape en cours ; refusee ou retiree ; compte desactive
-- ------------------------------------------------------------
SELECT pg_temp.garde('t06', pg_temp.trace(pg_temp.c('06')));
SELECT pg_temp.garde('w06', pg_temp.en(pg_temp.p('06'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"developpement": "experience"}', NULL, 'quelques_heures', true, 0, 'cle-ac-06-001')$$));
SELECT pg_temp.garde('w07', pg_temp.en(pg_temp.p('07'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"traduction": "metier"}', NULL, 'mi_temps', false, 0, 'cle-ac-07-001')$$));
SELECT pg_temp.garde('w03', pg_temp.en(pg_temp.p('03'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"accueil_familles": "experience"}', NULL, 'plus', true, 0, 'cle-ac-03-001')$$));
SELECT pg_temp.vrai(pg_temp.lu('w06') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('w07') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('w03') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT en_pause AND etape = 'verifications' FROM public.candidatures WHERE id = pg_temp.c('06'))
  AND (SELECT etape = 'confirmee' FROM public.candidatures WHERE id = pg_temp.c('07'))
  AND pg_temp.trace(pg_temp.c('06')) ->> 'ligne' = pg_temp.lu('t06') ->> 'ligne',
  'a toute etape tant que la candidature est en cours : en pause en salle de verification, confirmee (salle des prets a enseigner), une femme en salle d''examen');

-- 20, confirmee (Salle des prets a enseigner) : ecrit puis retire. L'audit de l'un et de l'autre
-- se lit du cote de la candidature, meme quand son auteur n'est plus porteur d'une candidature
-- avant la salle 3 (la table et la ligne visees portent le cote, pas l'auteur).
UPDATE public.candidatures SET etape = 'confirmee', etat = NULL WHERE id = pg_temp.c('20');
SELECT pg_temp.garde('w20', pg_temp.en(pg_temp.p('20'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"reseaux_sociaux": "metier"}', NULL, 'plus', true, 0, 'cle-ac-20-001')$$));
SELECT pg_temp.garde('x20', pg_temp.en(pg_temp.p('20'), 'teacher', $$SELECT public.retirer_autres_competences(1, 'cle-ac-20-002')$$));
SELECT pg_temp.vrai(pg_temp.lu('w20') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('x20') = '{"retire": true, "version": 0, "rejoue": false}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('20')) = 0
  AND (SELECT count(*) FROM public.audit_logs WHERE row_id = pg_temp.c('20')::text
        AND action LIKE 'candidature\_autres\_competences%') = 2,
  'une candidature confirmee ecrit puis retire : deux lignes d''audit, la ligne retiree');

-- Refusee (04, avec des reponses) : enregistrer refuse, lire et retirer permis.
SELECT pg_temp.garde('t04', pg_temp.trace(pg_temp.c('04')));
SELECT pg_temp.garde('l04', pg_temp.en(pg_temp.p('04'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w04', pg_temp.en(pg_temp.p('04'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"traduction": "metier"}', NULL, 'plus', true, 0, 'cle-ac-04-001')$$));
SELECT pg_temp.garde('w04v', pg_temp.en(pg_temp.p('04'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"traduction": "metier"}', NULL, 'plus', true, 1, 'cle-ac-04-002')$$));
SELECT pg_temp.vrai(pg_temp.lu('l04') @> '{"ouvert": false, "raison": "candidature_close", "version": 1}'::jsonb
  AND pg_temp.lu('l04') #> '{reponses,domaines}' = '{"traduction": "debutant"}'::jsonb
  AND pg_temp.lu('w04') = '{"erreur": "candidature_close", "issue": "refusee"}'::jsonb
  AND pg_temp.lu('w04v') = '{"erreur": "candidature_close", "issue": "refusee"}'::jsonb
  AND pg_temp.trace(pg_temp.c('04')) = pg_temp.lu('t04'),
  'refusee : la personne voit ce qu''elle avait donne (ouvert = false, candidature_close), enregistrer refuse, 0 ecriture');
SELECT pg_temp.garde('x04', pg_temp.en(pg_temp.p('04'), 'teacher', $$SELECT public.retirer_autres_competences(1, 'cle-ac-04-retrait')$$));
SELECT pg_temp.vrai(pg_temp.lu('x04') = '{"retire": true, "version": 0, "rejoue": false}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('04')) = 0
  AND pg_temp.trace(pg_temp.c('04')) ->> 'ligne' = pg_temp.lu('t04') ->> 'ligne'
  AND (SELECT issue FROM public.candidatures WHERE id = pg_temp.c('04')) = 'refusee',
  'refusee : retirer ses reponses et son accord reste permis (a tout moment), la candidature refusee ne bouge pas');
-- Retiree (05) : rien a retirer, enregistrer refuse.
SELECT pg_temp.garde('w05', pg_temp.en(pg_temp.p('05'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"traduction": "metier"}', NULL, 'plus', true, 0, 'cle-ac-05-001')$$));
SELECT pg_temp.garde('x05', pg_temp.en(pg_temp.p('05'), 'teacher', $$SELECT public.retirer_autres_competences(0, 'cle-ac-05-retrait')$$));
SELECT pg_temp.vrai(pg_temp.lu('w05') = '{"erreur": "candidature_close", "issue": "retiree"}'::jsonb
  AND pg_temp.lu('x05') = '{"retire": false, "version": 0, "rejoue": false}'::jsonb,
  'retiree : enregistrer refuse (issue retiree rendue), retirer sans rien d''enregistre rend retire = false');
-- Le rejeu passe avant la cloture (19) : la cle d'une ecriture reussie rend son premier
-- resultat meme si la candidature est refusee depuis ; une cle neuve est refusee.
SELECT pg_temp.garde('w19', pg_temp.en(pg_temp.p('19'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"developpement": "debutant"}', NULL, 'plus', true, 0, 'cle-ac-19-001')$$));
UPDATE public.candidatures SET issue = 'refusee', issue_modele = 'refus_general' WHERE id = pg_temp.c('19');
SELECT pg_temp.garde('w19r', pg_temp.en(pg_temp.p('19'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"developpement": "debutant"}', NULL, 'plus', true, 0, 'cle-ac-19-001')$$));
SELECT pg_temp.garde('w19n', pg_temp.en(pg_temp.p('19'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"developpement": "metier"}', NULL, 'plus', true, 1, 'cle-ac-19-002')$$));
SELECT pg_temp.vrai(pg_temp.lu('w19') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('w19r') = '{"version": 1, "inchange": false, "rejoue": true}'::jsonb
  AND pg_temp.lu('w19n') = '{"erreur": "candidature_close", "issue": "refusee"}'::jsonb
  AND (SELECT version = 1 AND domaines = '{"developpement": "debutant"}'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('19')),
  'le rejeu passe avant la cloture : la cle d''une ecriture reussie rend son premier resultat apres un refus, une cle neuve est refusee (candidature_close), 0 ecriture');
DELETE FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('19');

-- Compte desactive (08) : plus la main sur rien, meme avec une ligne.
SELECT pg_temp.talents('08', '{"assistanat": "debutant"}', NULL, 'plus', true);
SELECT pg_temp.refus_en(pg_temp.p('08'), 'teacher', $$SELECT public.retirer_autres_competences(1, 'cle-ac-08-retrait')$$, '42501',
  'compte desactive : retirer refuse (42501), la ligne reste');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('08')) = 1,
  'compte desactive : la ligne est toujours la');
DELETE FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('08');
-- Un compte dont l'acces est expire.
UPDATE public.profiles SET access_until = now() - interval '1 day' WHERE id = pg_temp.p('20');
SELECT pg_temp.refus_en(pg_temp.p('20'), 'teacher', $$SELECT public.lire_autres_competences()$$, '42501',
  'acces expire : lire refuse (42501)');
UPDATE public.profiles SET access_until = NULL WHERE id = pg_temp.p('20');

-- ------------------------------------------------------------
-- (f) Retirer
-- ------------------------------------------------------------
SELECT pg_temp.garde('t02r', pg_temp.trace(pg_temp.c('02')));
SELECT pg_temp.garde('x02v', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.retirer_autres_competences(5, 'cle-ac-02-retrait-1')$$));
SELECT pg_temp.vrai(pg_temp.lu('x02v') = '{"erreur": "conflit_autres_competences", "versionCourante": 6}'::jsonb
  AND pg_temp.trace(pg_temp.c('02')) = pg_temp.lu('t02r'),
  'retirer avec une version perimee : conflit_autres_competences, 0 ecriture');
SELECT pg_temp.garde('h02r', to_jsonb(pg_temp.hors(pg_temp.c('02'))));
SELECT pg_temp.garde('x02', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.retirer_autres_competences(6, 'cle-ac-02-retrait-2')$$));
SELECT pg_temp.garde('x02r', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.retirer_autres_competences(6, 'cle-ac-02-retrait-2')$$));
SELECT pg_temp.garde('l02c', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.vrai(pg_temp.lu('x02') = '{"retire": true, "version": 0, "rejoue": false}'::jsonb
  AND pg_temp.lu('x02r') = '{"retire": true, "version": 0, "rejoue": true}'::jsonb
  AND pg_temp.lu('l02c') @> '{"ouvert": true, "version": 0, "reponses": null}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')) = 0
  AND pg_temp.trace(pg_temp.c('02')) ->> 'ligne' = pg_temp.lu('t02r') ->> 'ligne'
  AND pg_temp.trace(pg_temp.c('02')) ->> 'audit' = (SELECT (pg_temp.lu('t02r') ->> 'audit')::int + 1 || '')
  AND (SELECT payload::text NOT LIKE '%comptabilite%' AND payload ->> 'version' = '6'
         FROM public.audit_logs WHERE row_id = pg_temp.c('02')::text AND action = 'candidature_autres_competences_retirees')
  AND (SELECT resultat FROM public.candidature_gestes WHERE cle = 'cle-ac-02-retrait-2') = '{"retire": true, "version": 0}'::jsonb,
  'retirer : la ligne disparait (reponses et accord), un audit sans reponse, rejeu de la cle sans ecriture, la lecture redit « ouvert, version 0 »');
SELECT pg_temp.vrai(pg_temp.hors(pg_temp.c('02')) = (pg_temp.lu('h02r') #>> '{}'),
  'un retrait ne touche que la ligne de son titulaire : les autres lignes, les autres candidatures et les cles des autres sont intactes');
SELECT pg_temp.garde('w02re', pg_temp.en(pg_temp.p('02'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"assistanat": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-02-011')$$));
SELECT pg_temp.vrai(pg_temp.lu('w02re') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb,
  'apres un retrait, on recommence a la version 0 et la ligne repart a 1');

-- ------------------------------------------------------------
-- (g) Lecture par la direction : autresCompetences dans lire_candidature
-- ------------------------------------------------------------
SELECT pg_temp.garde('d10', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$));
SELECT pg_temp.garde('d16', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000016')$$));
SELECT pg_temp.garde('d15', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000015')$$));
SELECT pg_temp.garde('k02', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000002')$$));
SELECT pg_temp.vrai(pg_temp.lu('d10') -> 'autresCompetences' @> '{"domaines": {"comptabilite": "metier"}, "autreTexte": null,
      "disponibilite": "mi_temps", "accord": true}'::jsonb
  AND pg_temp.lu('d10') #>> '{autresCompetences,accordLe}' ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$'
  AND pg_temp.lu('d10') #>> '{autresCompetences,majLe}' ~ 'Z$'
  AND (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(pg_temp.lu('d10') -> 'autresCompetences') k)
        = ARRAY['accord', 'accordLe', 'autreTexte', 'disponibilite', 'domaines', 'majLe']
  AND pg_temp.lu('d10') ? 'autresCompetences' AND pg_temp.lu('d16') ? 'autresCompetences'
  AND pg_temp.lu('d16') -> 'autresCompetences' = 'null'::jsonb
  AND pg_temp.lu('d15') -> 'autresCompetences' @> '{"domaines": {"autre": "experience"}, "autreTexte": "Calligraphie arabe",
      "disponibilite": "pas_maintenant", "accord": false, "accordLe": null}'::jsonb
  AND pg_temp.lu('k02') #> '{autresCompetences,domaines}' = '{"assistanat": "metier"}'::jsonb,
  'la direction lit autresCompetences dans le dossier (six cles, instants en UTC) ; nul sans reponse ; sans accord, les reponses restent lues avec accord = false ; le sujet des RPC y retrouve ce que le candidat a ecrit');
SELECT pg_temp.vrai(pg_temp.lu('d10') #- '{autresCompetences}' ? 'reference' AND pg_temp.lu('d10') ->> 'reference' LIKE 'CAND-%'
  AND NOT (pg_temp.lu('d10') #- '{autresCompetences}' ? 'courriel'),
  'le reste du dossier est celui de CAND-L2A2 (reference, aucun contact)');

-- Portee : l'autre cote est hors portee, sans donnee, et trace.
SELECT pg_temp.garde('h13', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000013')$$));
SELECT pg_temp.garde('h10', pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$));
SELECT pg_temp.garde('f13', pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000013')$$));
SELECT pg_temp.vrai(pg_temp.lu('h13') = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.lu('h10') = '{"erreur": "hors_portee"}'::jsonb
  AND pg_temp.lu('h13')::text NOT LIKE '%assistanat%' AND pg_temp.lu('h10')::text NOT LIKE '%comptabilite%'
  AND pg_temp.lu('f13') #> '{autresCompetences,domaines}' = '{"assistanat": "metier", "coordination_groupe": "experience"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('13') AND type = 'lecture_hors_portee') = 1
  AND (SELECT count(*) FROM public.candidature_evenements
        WHERE candidature_id = pg_temp.c('10') AND type = 'lecture_hors_portee') = 1,
  'separation femmes et hommes : le directeur ne lit rien des reponses d''une candidate, la directrice rien de celles d''un candidat (hors_portee, aucune donnee, lecture tracee) ; chacun lit les siennes');
SELECT pg_temp.garde('s13', pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000013')$$));
SELECT pg_temp.garde('s10', pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$));
SELECT pg_temp.vrai(pg_temp.lu('s13') #> '{autresCompetences,domaines}' = '{"assistanat": "metier", "coordination_groupe": "experience"}'::jsonb
  AND pg_temp.lu('s10') #>> '{autresCompetences,disponibilite}' = 'mi_temps'
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
         AND row_id = pg_temp.c('13')::text AND actor = pg_temp.p('a4') AND payload ->> 'motif' = 'exception_super_admin_kyc') = 1
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
         AND row_id = pg_temp.c('10')::text AND actor = pg_temp.p('a4')) = 0,
  'le super-admin lit les deux cotes ; la lecture de l''autre cote (13) est journalisee (exception_super_admin_kyc), celle de son cote (10) ne l''est pas');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$, '42501',
  'direction au genre inconnu : le dossier, donc les autres competences, refuse (42501)');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "comptabilite"}', 'nom', 1)$$, '42501',
  'direction au genre inconnu : la liste filtree par competence refusee aussi (42501)');
SELECT pg_temp.refus_en(pg_temp.p('a3'), 'admin', $$SELECT public.lister_candidatures('{}', 'nom', 1)$$, '42501',
  'direction au genre inconnu : la liste refusee (42501)');
SELECT pg_temp.refus_en(pg_temp.p('02'), 'teacher', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$, '42501',
  'un candidat ne lit pas le dossier d''un autre (42501)');
SELECT pg_temp.refus_en(pg_temp.p('c1'), 'accountant', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000010')$$, '42501',
  'la comptabilite ne lit pas les autres competences (42501)');

-- Chaque candidature, lue par chaque direction : les reponses ne sortent que du bon cote.
DO $portee$
DECLARE
  v_c record;
  v_qui text;
  v_cote public.gender;
  v_lu jsonb;
  n integer := 0;
BEGIN
  FOR v_c IN SELECT id, genre FROM public.candidatures WHERE id::text LIKE 'ca7acccc%' ORDER BY id LOOP
    FOREACH v_qui IN ARRAY ARRAY['a1', 'a2'] LOOP
      v_cote := CASE v_qui WHEN 'a1' THEN 'male' ELSE 'female' END;
      v_lu := pg_temp.en(pg_temp.p(v_qui), 'admin',
                pg_catalog.format($q$SELECT public.lire_candidature(%L)$q$, v_c.id));
      IF v_c.genre = v_cote AND NOT (v_lu ? 'autresCompetences') THEN
        RAISE EXCEPTION 'CAND-AUTRES ROUGE : la direction % ne lit pas les reponses de la candidature % de son cote', v_qui, v_c.id;
      END IF;
      IF v_c.genre IS DISTINCT FROM v_cote AND v_lu IS DISTINCT FROM '{"erreur": "hors_portee"}'::jsonb THEN
        RAISE EXCEPTION 'CAND-AUTRES ROUGE : la direction % lit autre chose que hors_portee de l''autre cote (%) : %',
          v_qui, v_c.id, left(v_lu::text, 80);
      END IF;
      n := n + 1;
    END LOOP;
  END LOOP;
  PERFORM pg_temp.vrai(n = 2 * (SELECT count(*) FROM public.candidatures WHERE id::text LIKE 'ca7acccc%') AND n >= 40,
    'chaque candidature lue par chaque direction : les reponses ne sortent que du cote du lecteur, l''autre cote rend hors_portee et rien d''autre');
END $portee$;

-- Le journal d'audit suit le cote de la candidature : une ligne d'audit des autres competences
-- ne se lit que du cote de la candidature (C5), l'auteur y est une reference CAND- tant qu'il n'est
-- pas en salle des prets a enseigner, aucune reponse n'y figure.
CREATE FUNCTION pg_temp.journal(p_qui text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p(p_qui), 'admin',
    $q$SELECT coalesce(jsonb_agg(jsonb_build_object('type', j.type_evenement, 'ligne', j.ligne_visee,
                                                   'nom', j.nom_acteur, 'details', j.details) ORDER BY j.entree_id), '[]'::jsonb)
         FROM (SELECT * FROM public.journal_audit(NULL, 'candidature_autres_competences_enregistrees', NULL, 200)
               UNION ALL
               SELECT * FROM public.journal_audit(NULL, 'candidature_autres_competences_retirees', NULL, 200)) j$q$);
$$;
CREATE FUNCTION pg_temp.lignes_audit(p_journal jsonb) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(DISTINCT right(t ->> 'ligne', 2) ORDER BY right(t ->> 'ligne', 2)), ARRAY[]::text[])
    FROM jsonb_array_elements(p_journal) t;
$$;
CREATE FUNCTION pg_temp.lignes_attendues(p_genre public.gender) RETURNS text[]
LANGUAGE sql AS $$
  SELECT coalesce(array_agg(DISTINCT right(a.row_id, 2) ORDER BY right(a.row_id, 2)), ARRAY[]::text[])
    FROM public.audit_logs a JOIN public.candidatures c ON c.id::text = a.row_id
   WHERE a.action LIKE 'candidature\_autres\_competences%' AND c.genre = p_genre;
$$;
SELECT pg_temp.garde('ja1', pg_temp.journal('a1'));
SELECT pg_temp.garde('ja2', pg_temp.journal('a2'));
SELECT pg_temp.garde('ja3', pg_temp.journal('a3'));
SELECT pg_temp.garde('ja4', pg_temp.journal('a4'));
SELECT pg_temp.garde('da1', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT coalesce(jsonb_agg(jsonb_build_object('ligne', row_id) ORDER BY id), '[]'::jsonb) FROM public.audit_logs
     WHERE action LIKE 'candidature\_autres\_competences%'$$));
SELECT pg_temp.garde('da2', pg_temp.en(pg_temp.p('a2'), 'admin',
  $$SELECT coalesce(jsonb_agg(jsonb_build_object('ligne', row_id) ORDER BY id), '[]'::jsonb) FROM public.audit_logs
     WHERE action LIKE 'candidature\_autres\_competences%'$$));
SELECT pg_temp.vrai(cardinality(pg_temp.lignes_attendues('male')) >= 5 AND cardinality(pg_temp.lignes_attendues('female')) >= 1
  AND pg_temp.lignes_audit(pg_temp.lu('ja1')) = pg_temp.lignes_attendues('male')
  AND pg_temp.lignes_audit(pg_temp.lu('ja2')) = pg_temp.lignes_attendues('female')
  AND pg_temp.lignes_audit(pg_temp.lu('da1')) = pg_temp.lignes_attendues('male')
  AND pg_temp.lignes_audit(pg_temp.lu('da2')) = pg_temp.lignes_attendues('female')
  AND pg_temp.lu('ja3') = '[]'::jsonb
  AND pg_temp.lignes_audit(pg_temp.lu('ja4')) = (SELECT array_agg(x ORDER BY x)
        FROM unnest(pg_temp.lignes_attendues('male') || pg_temp.lignes_attendues('female')) x),
  'separation femmes et hommes : le journal d''audit (journal_audit et lecture directe) ne rend que les ecritures des candidatures de son cote ; la direction au genre inconnu n''en lit aucune ; le super-admin lit les deux');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
                        AND actor = pg_temp.p('a4') AND payload ->> 'lecture' = 'journal_audit'
                        AND (payload ->> 'lignesAutreCote')::int >= 1) >= 1,
  'le super-admin qui lit l''audit des autres competences de l''autre cote est journalise (exception_super_admin_kyc)');
SELECT pg_temp.vrai(NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('ja1') || pg_temp.lu('ja2')) t
                                 JOIN public.candidatures c ON c.id::text = t ->> 'ligne'
                                 WHERE (t ->> 'nom' LIKE 'CAND-%') <> (c.etape <> 'confirmee'))
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('ja1')) t WHERE t ->> 'ligne' LIKE '%07' AND t ->> 'nom' NOT LIKE 'CAND-%')
  AND EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('ja1')) t WHERE t ->> 'ligne' LIKE '%02' AND t ->> 'nom' LIKE 'CAND-%')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('ja1') || pg_temp.lu('ja2')) t
                   WHERE (t -> 'details')::text ~ '(comptabilite|reseaux_sociaux|developpement|assistanat|traduction|accueil_familles|Calligraphie|metier|experience)'
                      OR (t -> 'details') ?| ARRAY['domaines_codes', 'autre_texte', 'texte', 'reponses']),
  'dans le journal, l''auteur d''un candidat avant la salle des prets a enseigner est sa reference CAND- (jamais son nom ; 07 et 20, confirmees, sont nommees) et aucune reponse n''y figure');
SELECT pg_temp.vrai((pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.journal_audit_filtres() -> 'actions'$$)) @>
        '[{"action": "candidature_autres_competences_enregistrees", "n": 1}]'::jsonb
  AND NOT ((pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.journal_audit_filtres() -> 'actions'$$))::text
            LIKE '%candidature_autres_competences_retirees%'),
  'les totaux du journal (journal_audit_filtres) ne comptent que le cote du lecteur : une ecriture de candidate, aucun retrait');

-- La liste garde ses vingt et une cles (CAND-NOM-LATIN : nomLatin, nomLatinAConfirmer) et ne porte aucune reponse.
SELECT pg_temp.garde('lst', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{}', 'nom', 1)$$));
SELECT pg_temp.vrai(NOT EXISTS (
      SELECT 1 FROM jsonb_array_elements(pg_temp.lu('lst') -> 'lignes') l
      WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(l) k) IS DISTINCT FROM
            (SELECT array_agg(x ORDER BY x) FROM unnest(ARRAY['id', 'reference', 'nomComplet', 'type',
              'etape', 'etat', 'issue', 'enPause', 'repriseLe', 'restreinte', 'indisponible',
              'indisponibleJusquAu', 'paiement', 'paysResidence', 'responsableId', 'courrielAObtenir',
              'indicatifAConfirmer', 'derniereActivite', 'recueLe', 'nomLatin', 'nomLatinAConfirmer']) x))
  AND jsonb_array_length(pg_temp.lu('lst') -> 'lignes') = 18
  AND pg_temp.lu('lst')::text NOT LIKE '%comptabilite%' AND pg_temp.lu('lst')::text NOT LIKE '%Calligraphie%'
  AND pg_temp.lu('lst')::text NOT LIKE '%autresCompetences%',
  'la liste de la direction garde ses vingt et une cles (CAND-NOM-LATIN : nomLatin, nomLatinAConfirmer) et ne porte aucune reponse (spec 8.3) : 18 candidatures d''hommes');

-- ------------------------------------------------------------
-- (h) Le filtre de lister_candidatures
-- ------------------------------------------------------------
CREATE FUNCTION pg_temp.filtre(p_qui text, p_filtre text) RETURNS text[]
LANGUAGE sql AS $$
  SELECT pg_temp.nos(pg_temp.en(pg_temp.p(p_qui), 'admin',
    pg_catalog.format($q$SELECT public.lister_candidatures(%L::jsonb, 'nom', 1)$q$, p_filtre)));
$$;

-- Etat des donnees de ces filtres, hommes : 01 (reseaux_sociaux experience,
-- quelques heures, accord ; ecrite par la RPC apres l'envoi reel), 02
-- (assistanat metier, mi-temps, accord), 06 (developpement experience, quelques
-- heures, accord), 07 (traduction metier, mi-temps, SANS accord), puis 10 a 12
-- et 15 des fixtures ; femmes : 03 (relation familles experience, plus,
-- accord), 13 et 14 des fixtures.
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite"}') = ARRAY['10', '11']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite", "competenceNiveauMin": "metier"}') = ARRAY['10']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite", "competenceNiveauMin": "experience"}') = ARRAY['10', '11']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite", "competenceNiveauMin": "debutant"}') = ARRAY['10', '11']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "developpement"}') = ARRAY['06', '12'],
  'domaine seul, puis avec un niveau minimum (metier, experience, debutant) : le niveau est un minimum, jamais une egalite');
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceNiveauMin": "metier"}') = ARRAY['02', '07', '10', '12']
  AND pg_temp.filtre('a1', '{"competenceNiveauMin": "experience"}') = ARRAY['01', '02', '06', '07', '10', '11', '12', '15']
  AND pg_temp.filtre('a1', '{"competenceNiveauMin": "debutant"}') = ARRAY['01', '02', '06', '07', '10', '11', '12', '15'],
  'niveau minimum sans domaine : au moins un domaine a ce niveau ou plus (12 : developpement metier, reseaux_sociaux debutant) ; jamais une ligne sans reponse');
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDisponibilite": "mi_temps"}') = ARRAY['02', '07', '10']
  AND pg_temp.filtre('a1', '{"competenceDisponibilite": "plus"}') = ARRAY['11']
  AND pg_temp.filtre('a1', '{"competenceDisponibilite": "quelques_heures"}') = ARRAY['01', '06', '12']
  AND pg_temp.filtre('a1', '{"competenceDisponibilite": "pas_maintenant"}') = ARRAY['15'],
  'disponibilite : une valeur exacte, sans classement entre les valeurs');
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceAccord": true}') = ARRAY['01', '02', '06', '10', '11']
  AND pg_temp.filtre('a1', '{"competenceAccord": false}') = ARRAY['07', '12', '15']
  AND pg_temp.filtre('a1', '{"competenceAccord": true, "competenceDomaine": "comptabilite", "competenceNiveauMin": "metier",
        "competenceDisponibilite": "mi_temps"}') = ARRAY['10']
  AND pg_temp.filtre('a1', '{"competenceAccord": true, "competenceDomaine": "comptabilite", "competenceDisponibilite": "quelques_heures"}')
        = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "assistanat"}') = ARRAY['02']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "autre"}') = ARRAY['15'],
  'accord donne ou non ; les quatre filtres ensemble (ET) ; une combinaison sans resultat rend une page vide ; sans accord, la personne est tout de meme listee quand on le demande (accord = false)');
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDomaine": null, "competenceNiveauMin": null, "competenceDisponibilite": null,
        "competenceAccord": null}') = pg_temp.nos(pg_temp.lu('lst'))
  AND pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite", "etape": "verifications"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "developpement", "etape": "verifications"}') = ARRAY['06', '12']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "traduction", "issue": "refusee"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "traduction", "issue": "en_cours"}') = ARRAY['07'],
  'des cles a null valent des cles absentes (la liste entiere) ; les filtres de competence se combinent avec ceux de la liste (etape, issue)');

-- La portee : un filtre ne rend jamais une candidature de l'autre cote.
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDomaine": "accueil_familles"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a2', '{"competenceDomaine": "accueil_familles"}') = ARRAY['03']
  AND pg_temp.filtre('a2', '{"competenceDomaine": "comptabilite"}') = ARRAY['14']
  AND pg_temp.filtre('a2', '{"competenceDomaine": "assistanat", "competenceNiveauMin": "metier", "competenceAccord": true}') = ARRAY['13']
  AND pg_temp.filtre('a2', '{"competenceDomaine": "coordination_groupe"}') = ARRAY['13']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "coordination_groupe"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a2', '{"competenceNiveauMin": "metier", "competenceAccord": true}') = ARRAY['13', '14']
  AND pg_temp.filtre('a2', '{"competenceAccord": true}') = ARRAY['03', '13', '14'],
  'separation femmes et hommes : l''assistante pour le groupe des sœurs se cherche cote femmes (13) ; le directeur n''obtient aucune des candidates, la directrice aucun des candidats');
-- Le total et les lignes de l'autre cote : un filtre ne rend ni ligne, ni compte, ni trace d'une
-- candidature de l'autre cote.
SELECT pg_temp.vrai(
      (pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "accueil_familles"}', 'nom', 1)$$) ->> 'total') = '0'
  AND (pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "accueil_familles"}', 'nom', 1)$$) ->> 'total') = '1'
  AND (pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceAccord": true}', 'nom', 1)$$) ->> 'total') = '5'
  AND (pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lister_candidatures('{"competenceAccord": true}', 'nom', 1)$$) ->> 'total') = '3'
  AND (pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceNiveauMin": "debutant"}', 'nom', 1)$$) ->> 'total') = '8'
  AND (pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lister_candidatures('{"competenceNiveauMin": "debutant"}', 'nom', 1)$$) ->> 'total') = '3'
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs
                   WHERE action = 'candidatures_liste' AND actor IN (pg_temp.p('a1'), pg_temp.p('a2'))
                     AND payload ->> 'competences' = 'true'
                     AND (payload ->> 'lignes_hors_genre' <> '0' OR payload ->> 'exception_active' <> 'false'))
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_liste' AND actor IN (pg_temp.p('a1'), pg_temp.p('a2'))
        AND payload ->> 'competences' = 'true') >= 20,
  'separation femmes et hommes : le total d''une liste filtree ne compte que le cote du lecteur, et aucune liste filtree n''a rendu une seule ligne de l''autre cote (lignes_hors_genre = 0 dans chaque audit)');
SELECT pg_temp.garde('lsa', pg_temp.en(pg_temp.p('a4'), 'admin',
  $$SELECT public.lister_candidatures('{"competenceDomaine": "comptabilite"}', 'nom', 1)$$));
SELECT pg_temp.vrai(pg_temp.nos(pg_temp.lu('lsa')) = ARRAY['10', '11', '14']
  AND (pg_temp.lu('lsa') ->> 'total') = '3'
  AND (SELECT payload ->> 'lignes_hors_genre' = '1' AND payload ->> 'competences' = 'true'
              AND payload ->> 'exception_active' = 'true'
         FROM public.audit_logs WHERE action = 'candidatures_liste' AND actor = pg_temp.p('a4')
          AND payload ->> 'competences' = 'true' ORDER BY id DESC LIMIT 1),
  'le super-admin obtient les deux cotes (10, 11, 14) ; la liste note la ligne de l''autre cote et qu''un filtre de competence a servi');
SELECT pg_temp.vrai(
      (SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_liste' AND actor = pg_temp.p('a1')
        AND payload ->> 'competences' = 'true') >= 20
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'candidatures_liste' AND actor = pg_temp.p('a1')
        AND payload ->> 'competences' = 'false') >= 1
  AND NOT EXISTS (SELECT 1 FROM public.audit_logs WHERE action = 'candidatures_liste'
                   AND (payload::text LIKE '%comptabilite%' OR payload::text LIKE '%mi_temps%')),
  'chaque liste est auditee avec competences = vrai ou faux, jamais avec le domaine ni la disponibilite cherches');
-- Les compteurs ne dependent pas des filtres (toute la portee).
SELECT pg_temp.vrai(
      pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "comptabilite"}', 'nom', 1) -> 'compteursEtapes'$$)
    = pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{}', 'nom', 1) -> 'compteursEtapes'$$)
  AND pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "comptabilite"}', 'nom', 1) -> 'compteursAlertes'$$)
    = pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{}', 'nom', 1) -> 'compteursAlertes'$$),
  'les compteurs d''etape et d''alerte couvrent toute la portee, sans le filtre de competence');
-- Valeurs et types invalides : 22023.
DO $invalides$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY[
    '{"competenceDomaine": "cuisine"}',
    '{"competenceDomaine": ""}',
    '{"competenceDomaine": 3}',
    '{"competenceDomaine": ["comptabilite"]}',
    '{"competenceNiveauMin": "expert"}',
    '{"competenceNiveauMin": 2}',
    '{"competenceDisponibilite": "toujours"}',
    '{"competenceDisponibilite": true}',
    '{"competenceAccord": "oui"}',
    '{"competenceAccord": 1}',
    '{"competenceDomaines": "comptabilite"}'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin',
      pg_catalog.format($q$SELECT public.lister_candidatures(%L::jsonb, 'nom', 1)$q$, v_f), '22023',
      'filtre invalide : 22023 : ' || v_f);
  END LOOP;
END $invalides$;

-- ------------------------------------------------------------
-- (i) Jamais lues par un controle, le paiement ni etat_dossier()
-- ------------------------------------------------------------
-- 02 a maintenant une ligne (assistanat metier, mi-temps, accord). Meme etat
-- de dossier, memes controles, meme paiement, que sans elle.
SELECT pg_temp.garde('apres_etat', pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$));
SELECT pg_temp.garde('apres_ctrl', (SELECT jsonb_build_object(
    'paiement', private.paiement_etat(c.id),
    'entree', private.candidature_controles_entree(c, 'admission'),
    'questionnaire', private.candidature_questionnaire_envoye(c),
    'direction', private.candidature_etat_direction(c.id))
  FROM public.candidatures c WHERE c.id = pg_temp.c('02')));
SELECT pg_temp.garde('apres_dossier', pg_temp.en(pg_temp.p('a1'), 'admin',
  $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000002') - 'autresCompetences'$$));
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('02')) = 1
  AND pg_temp.lu('apres_etat') = pg_temp.lu('avant_etat')
  AND pg_temp.lu('apres_ctrl') = pg_temp.lu('avant_ctrl')
  AND pg_temp.lu('apres_dossier') = pg_temp.lu('avant_dossier'),
  'avec ou sans reponses : etat_dossier(), paiement, controles d''admission, questionnaire envoye et dossier (hors autresCompetences) sont identiques');
-- Avec ou sans accord, la meme chose.
UPDATE public.candidature_autres_competences SET accord_contact = false, accord_le = NULL
 WHERE candidature_id = pg_temp.c('02');
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$) = pg_temp.lu('apres_etat'),
  'accord donne ou non : etat_dossier() ne change pas');
-- Contre-epreuve : le meme calcul bouge quand ce qu'il lit bouge vraiment (la
-- declaration de paiement du questionnaire), puis la declaration est remise.
SELECT pg_temp.garde('decl', (SELECT to_jsonb(r.reponses) FROM public.candidature_reponses r
                               WHERE r.candidature_id = pg_temp.c('02') AND r.envoye_le IS NOT NULL));
UPDATE public.candidature_reponses SET reponses = reponses || '{"compteBancaire": false, "paysVersement": "NG"}'::jsonb
 WHERE candidature_id = pg_temp.c('02') AND envoye_le IS NOT NULL;
SELECT pg_temp.vrai((SELECT private.paiement_etat(c.id) FROM public.candidatures c WHERE c.id = pg_temp.c('02'))
      IS DISTINCT FROM pg_temp.lu('avant_ctrl') ->> 'paiement'
  AND pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$) IS DISTINCT FROM pg_temp.lu('apres_etat'),
  'contre-epreuve : la declaration de paiement, elle, change le calcul du paiement et l''etat du dossier');
UPDATE public.candidature_reponses SET reponses = (pg_temp.lu('decl'))
 WHERE candidature_id = pg_temp.c('02') AND envoye_le IS NOT NULL;
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$) = pg_temp.lu('apres_etat'),
  'la declaration remise, l''etat du dossier redevient celui d''avant : rien d''autre ne le faisait bouger');
-- La trace complete d'une ecriture du candidat ne touche aucune table de la
-- candidature en dehors des cles d'idempotence et de l'audit.
SELECT pg_temp.garde('t07', pg_temp.trace(pg_temp.c('07')));
SELECT pg_temp.garde('w07b', pg_temp.en(pg_temp.p('07'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"traduction": "metier", "reseaux_sociaux": "metier"}', NULL, 'mi_temps', true, 1, 'cle-ac-07-002')$$));
SELECT pg_temp.vrai(pg_temp.lu('w07b') ->> 'version' = '2'
  AND pg_temp.trace(pg_temp.c('07')) ->> 'ligne' = pg_temp.lu('t07') ->> 'ligne'
  AND pg_temp.trace(pg_temp.c('07')) ->> 'reponses' = pg_temp.lu('t07') ->> 'reponses'
  AND pg_temp.trace(pg_temp.c('07')) ->> 'evenements' = pg_temp.lu('t07') ->> 'evenements',
  'une candidature confirmee : l''ecriture ne touche ni sa ligne, ni ses reponses du questionnaire, ni son journal d''evenements');

-- ------------------------------------------------------------
-- (j) Contraintes de la table (le proprietaire, pas les RPC)
-- ------------------------------------------------------------
DO $contraintes$
DECLARE
  v_sql text;
  v_base text := $b$INSERT INTO public.candidature_autres_competences (candidature_id, domaines, autre_texte, disponibilite, accord_contact, accord_le, version) VALUES ('ca7acccc-0000-4000-8000-000000000016', %s)$b$;
BEGIN
  -- Un domaine hors du catalogue est refuse par le declencheur (23503), avant les contraintes ;
  -- un code mal forme aussi tant que le declencheur joue.
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"cuisine": "metier"}', NULL, 'plus', false, NULL, 1$v$), '23503', 'domaine hors du catalogue refuse (23503)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier", "cuisine": "metier"}', NULL, 'plus', false, NULL, 1$v$), '23503', 'un seul domaine hors du catalogue parmi des connus : refuse (23503)');
  PERFORM pg_temp.refus($u$UPDATE public.candidature_autres_competences SET domaines = '{"cuisine": "metier"}' WHERE candidature_id = 'ca7acccc-0000-4000-8000-000000000010'$u$, '23503', 'une mise a jour vers un domaine hors du catalogue : refusee (23503)');
  -- La forme du code et le nombre de domaines sont des contraintes de table, aussi sans le declencheur.
  ALTER TABLE public.candidature_autres_competences DISABLE TRIGGER candidature_autres_competences_domaines_connus;
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"Cuisine!": "metier"}', NULL, 'plus', false, NULL, 1$v$), '23514', 'code mal forme refuse par la contrainte (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$(SELECT jsonb_object_agg('k' || n, 'metier') FROM generate_series(1, 101) n), NULL, 'plus', false, NULL, 1$v$), '23514', 'plus de cent domaines refuse par la contrainte (23514)');
  EXECUTE pg_catalog.format(v_base, $v$(SELECT jsonb_object_agg('k' || n, 'metier') FROM generate_series(1, 100) n), NULL, 'plus', false, NULL, 1$v$);
  PERFORM pg_temp.vrai((SELECT (SELECT count(*) FROM jsonb_object_keys(domaines)) = 100 FROM public.candidature_autres_competences
                         WHERE candidature_id = pg_temp.c('16')), 'cent domaines (la borne) passent la contrainte, le declencheur coupe');
  DELETE FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('16');
  ALTER TABLE public.candidature_autres_competences ENABLE TRIGGER candidature_autres_competences_domaines_connus;
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$(SELECT jsonb_object_agg('k' || n, 'metier') FROM generate_series(1, 100) n), NULL, 'plus', false, NULL, 1$v$), '23503', 'le declencheur remis : cent domaines hors du catalogue refuses (23503)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "expert"}', NULL, 'plus', false, NULL, 1$v$), '23514', 'niveau hors liste refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{}', NULL, 'plus', false, NULL, 1$v$), '23514', 'aucun domaine refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'["comptabilite"]', NULL, 'plus', false, NULL, 1$v$), '23514', 'domaines en tableau refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": 1}', NULL, 'plus', false, NULL, 1$v$), '23514', 'niveau non texte refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"autre": "metier"}', NULL, 'plus', false, NULL, 1$v$), '23514', '« autre » sans texte refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', 'texte', 'plus', false, NULL, 1$v$), '23514', 'texte sans « autre » refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"autre": "metier"}', ' texte', 'plus', false, NULL, 1$v$), '23514', 'texte avec un blanc de tete refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"autre": "metier"}', E'deux\nlignes', 'plus', false, NULL, 1$v$), '23514', 'texte sur deux lignes refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"autre": "metier"}', repeat('a', 201), 'plus', false, NULL, 1$v$), '23514', 'texte de 201 caracteres refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"autre": "metier"}', '', 'plus', false, NULL, 1$v$), '23514', 'texte vide refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', NULL, 'toujours', false, NULL, 1$v$), '23514', 'disponibilite hors liste refusee (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', NULL, 'plus', true, NULL, 1$v$), '23514', 'accord sans date refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', NULL, 'plus', false, now(), 1$v$), '23514', 'date d''accord sans accord refusee (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', NULL, 'plus', false, NULL, 0$v$), '23514', 'version 0 refusee (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'{"comptabilite": "metier"}', NULL, NULL, false, NULL, 1$v$), '23502', 'disponibilite absente refusee (23502)');
  PERFORM pg_temp.refus($u$INSERT INTO public.candidature_autres_competences (candidature_id, domaines, disponibilite, accord_contact) VALUES ('ca7acccc-0000-4000-8000-000000000010', '{"comptabilite": "metier"}', 'plus', false)$u$,
    '23505', 'une seule ligne par candidature (23505)');
  PERFORM pg_temp.refus($u$INSERT INTO public.candidature_autres_competences (candidature_id, domaines, disponibilite, accord_contact) VALUES ('ca7acccc-0000-4000-8000-0000000000ff', '{"comptabilite": "metier"}', 'plus', false)$u$,
    '23503', 'une candidature connue exigee (23503)');
  PERFORM pg_temp.vrai((SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('16')) = 0,
    'aucune des insertions refusees n''a laisse de ligne');
  -- Les bornes qui passent, au niveau de la table.
  EXECUTE pg_catalog.format(v_base, $v$'{"autre": "metier"}', repeat('é', 200), 'pas_maintenant', true, now(), 1$v$);
  PERFORM pg_temp.vrai((SELECT length(autre_texte) = 200 FROM public.candidature_autres_competences
                         WHERE candidature_id = pg_temp.c('16')), 'un texte de 200 caracteres est accepte par la table');
  DELETE FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('16');
END $contraintes$;

-- ------------------------------------------------------------
-- (k) Conservation : la ligne suit la candidature ; ecart connu epingle
-- ------------------------------------------------------------
-- Une candidature sans historique s'efface, et la ligne avec elle (CASCADE).
INSERT INTO auth.users (id, email) VALUES (pg_temp.p('30'), 'cand-autres-30@test.invalid');
INSERT INTO public.profiles (id, immutable_id, role, first_name, last_name, account_status, gender)
VALUES (pg_temp.p('30'), 'CA7A-ENS-0030', 'teacher', 'Essai30', 'Fictif', 'pending_kyc', 'male');
INSERT INTO public.candidatures (id, type_code, profile_id, genre, nom_complet, etape, etat, issue, source)
VALUES (pg_temp.c('30'), 'enseignant', pg_temp.p('30'), 'male', 'Fixture CA7 30', 'prequalification', 'a_completer',
        'en_cours', 'lien_public');
SELECT pg_temp.talents('30', '{"comptabilite": "metier"}', NULL, 'plus', true);
DELETE FROM public.candidatures WHERE id = pg_temp.c('30');
SELECT pg_temp.vrai((SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('30')) = 0,
  'la ligne suit la candidature : supprimee avec elle (ON DELETE CASCADE)');

-- ECART CONNU (C9, CAND-Q21, CAND-BR-14), epingle : l'anonymisation existante
-- ne touche pas cette table, et l'export des donnees ne la cite pas. Ce
-- controle doit basculer quand le lot de conservation etendra cpt_anonymiser
-- et mes_donnees_export.
SELECT pg_temp.talents('18', '{"comptabilite": "experience"}', NULL, 'plus', true);
DO $anonymise$
BEGIN
  PERFORM private.cpt_anonymiser(pg_temp.p('18'));
  PERFORM pg_temp.vrai(
    (SELECT domaines = '{"comptabilite": "experience"}'::jsonb AND accord_contact
       FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('18'))
    AND (SELECT gender FROM public.profiles WHERE id = pg_temp.p('18')) IS NULL
    AND pg_get_functiondef('public.mes_donnees_export()'::regprocedure) NOT LIKE '%autres_competences%',
    'ECART CONNU CAND-Q21 : les reponses survivent a l''anonymisation du compte et sont absentes de l''export (prealable a la production)');
END $anonymise$;

-- ------------------------------------------------------------
-- (l) Le catalogue des competences (decision du directeur du 22/10)
-- ------------------------------------------------------------
-- Appels de la RPC d'ecriture au nom d'un compte, avec les arguments en jsonb
-- (cle absente = NULL).
CREATE FUNCTION pg_temp.sql_cat(p jsonb) RETURNS text
LANGUAGE sql AS $$
  SELECT pg_catalog.format(
    $q$SELECT public.enregistrer_competence_catalogue(%L, %L, %L::integer, %L, %L, %L::boolean, %L::integer, %L)$q$,
    p ->> 'code', p ->> 'famille', p ->> 'ordre', p ->> 'libelle', p ->> 'exemple', p ->> 'actif',
    p ->> 'version', p ->> 'cle');
$$;
CREATE FUNCTION pg_temp.cat(p_qui text, p jsonb) RETURNS jsonb
LANGUAGE sql AS $$ SELECT pg_temp.en(pg_temp.p(p_qui), 'admin', pg_temp.sql_cat(p)) $$;
-- L'entree d'un code, lue par le proprietaire (avec sa version).
CREATE FUNCTION pg_temp.entree(p_code text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT private.competences_entree(k, true) FROM public.competences_catalogue k WHERE k.code = p_code
$$;
-- Tout ce qu'une ecriture du catalogue peut toucher : les lignes du catalogue, le
-- journal, l'audit du catalogue et les reponses des candidats.
CREATE FUNCTION pg_temp.trace_cat() RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_catalog.jsonb_build_object(
    'catalogue', (SELECT md5(coalesce(string_agg(to_jsonb(k)::text, '|' ORDER BY k.code), '')) FROM public.competences_catalogue k),
    'journal', (SELECT count(*) FROM public.competences_catalogue_journal),
    'audit', (SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture'),
    'reponses', (SELECT md5(coalesce(string_agg(to_jsonb(t)::text, '|' ORDER BY t.candidature_id), ''))
                   FROM public.candidature_autres_competences t));
$$;
GRANT EXECUTE ON FUNCTION pg_temp.sql_cat(jsonb), pg_temp.cat(text, jsonb), pg_temp.entree(text), pg_temp.trace_cat()
  TO authenticated, anon;

-- Deux candidatures d'hommes de plus : 23 (une reponse ancienne), 24 (aucune reponse).
SELECT pg_temp.cand('23', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));
SELECT pg_temp.cand('24', 'male', 'prequalification', 'en_examen', 'en_cours', false, pg_temp.lu('complet_sa'));

-- (l.1) L'etat initial : la liste precise du directeur, par famille.
SELECT pg_temp.vrai((SELECT count(*) FROM public.competences_catalogue) = 25
  AND (SELECT array_agg(k.code ORDER BY array_position(private.competences_codes('familles'), k.famille), k.ordre, k.code)
         FROM public.competences_catalogue k) = pg_temp.catalogue_initial()
  AND (SELECT jsonb_object_agg(famille, n) FROM (SELECT famille, count(*) n FROM public.competences_catalogue GROUP BY famille) f)
        = '{"communication": 8, "administration": 5, "finances_droit": 3, "pedagogie": 5, "technique": 3, "autre": 1}'::jsonb
  AND (SELECT bool_and(actif AND version = 1) FROM public.competences_catalogue)
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue k WHERE k.libelle = '' OR k.exemple = '')
  AND NOT EXISTS (SELECT 1 FROM (SELECT famille, array_agg(ordre ORDER BY ordre) o, count(*)::integer n
                                   FROM public.competences_catalogue GROUP BY famille) f
                   WHERE f.o IS DISTINCT FROM (SELECT array_agg(g) FROM generate_series(1, f.n) g)),
  'etat initial : 25 competences en six familles (8, 5, 3, 5, 3, 1), toutes actives a la version 1, ordre 1 a n dans chaque famille, libelle et exemple renseignes');
SELECT pg_temp.vrai(
      (SELECT libelle FROM public.competences_catalogue WHERE code = 'reseaux_sociaux') = 'Gestion des réseaux sociaux'
  AND (SELECT libelle FROM public.competences_catalogue WHERE code = 'montage_video') = 'Montage vidéo et animation'
  AND (SELECT libelle FROM public.competences_catalogue WHERE code = 'relations_publiques') = 'Relations publiques et partenariats'
  AND (SELECT famille FROM public.competences_catalogue WHERE code = 'tests_niveau') = 'pedagogie'
  AND (SELECT famille FROM public.competences_catalogue WHERE code = 'juridique_donnees') = 'finances_droit'
  AND (SELECT famille FROM public.competences_catalogue WHERE code = 'assistance_technique') = 'technique',
  'etat initial : les competences nommees par le directeur (reseaux sociaux, relations publiques, design graphique, montage video, administration, pedagogie) y sont, dans la bonne famille');
SELECT pg_temp.vrai(
      (SELECT count(*) FROM public.competences_catalogue_journal WHERE geste = 'etat_initial'
          AND auteur_id IS NULL AND cle_idempotence IS NULL AND empreinte IS NULL AND avant IS NULL) = 25
  AND (SELECT count(*) FROM public.competences_catalogue_journal) = 25
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture') = 0
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue k
                   WHERE k.code = ANY (private.competences_codes('familles')) AND k.code <> 'autre'),
  'etat initial : une ligne de journal par competence (etat_initial, sans auteur ni cle), aucune entree d''audit, aucun code qui porte le nom d''une famille');

-- (l.2) Lire le catalogue : la direction (tout, versions, peutModifier), le candidat (actif, sans version).
SELECT pg_temp.garde('cat_a1', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.garde('cat_a3', pg_temp.en(pg_temp.p('a3'), 'admin', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.garde('cat_a4', pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.garde('cat_24', pg_temp.en(pg_temp.p('24'), 'teacher', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.vrai(
      (SELECT array_agg(c ->> 'code') FROM jsonb_array_elements(pg_temp.lu('cat_a1') -> 'competences') c) = pg_temp.catalogue_initial()
  AND pg_temp.lu('cat_a1') ->> 'peutModifier' = 'true'
  AND pg_temp.lu('cat_a1') = pg_temp.lu('cat_a3') AND pg_temp.lu('cat_a1') = pg_temp.lu('cat_a4')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('cat_a1') -> 'competences') c
                   WHERE (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(c) k)
                         IS DISTINCT FROM ARRAY['actif', 'code', 'exemple', 'famille', 'libelle', 'ordre', 'version'])
  AND pg_temp.lu('cat_a1') #> '{familles}' = '["communication", "administration", "finances_droit", "pedagogie", "technique", "autre"]'::jsonb,
  'la direction lit tout le catalogue dans l''ordre d''affichage, avec la version de chaque ligne et peutModifier ; sans condition de genre (le genre inconnu et le super-admin lisent la meme chose)');
SELECT pg_temp.vrai(
      (SELECT array_agg(c ->> 'code') FROM jsonb_array_elements(pg_temp.lu('cat_24') -> 'competences') c) = pg_temp.catalogue_initial()
  AND pg_temp.lu('cat_24') ->> 'peutModifier' = 'false'
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('cat_24') -> 'competences') c WHERE c ? 'version')
  AND pg_temp.lu('cat_24') #> '{competences,0}' = pg_temp.lu('l01') #> '{referentiel,competences,0}',
  'le candidat lit les competences actives dans le meme ordre, sans version, peutModifier = faux ; la meme entree que dans lire_autres_competences');
DO $lecteurs$
DECLARE
  v_qui record;
BEGIN
  FOR v_qui IN SELECT * FROM (VALUES
      (pg_temp.p('e1'), 'guardian', 'tuteur'),
      (pg_temp.p('c1'), 'accountant', 'comptabilite'),
      (pg_temp.p('b1'), 'teacher', 'enseignant sans candidature'),
      (pg_temp.p('08'), 'teacher', 'candidat au compte desactive'),
      (pg_temp.p('21'), 'teacher', 'candidat d''un autre type que enseignant'),
      (NULL::uuid, NULL::text, 'session sans compte')) AS q(id, role, nom) LOOP
    PERFORM pg_temp.refus_en(v_qui.id, v_qui.role, 'SELECT public.lire_catalogue_competences()', '42501',
      'lire le catalogue : ' || v_qui.nom || ' refuse (42501)');
  END LOOP;
  PERFORM pg_temp.refus_en(NULL, NULL, 'SELECT public.lire_catalogue_competences()', '42501',
    'lire le catalogue : anon refuse (42501)', 'anon');
END $lecteurs$;

-- (l.3) Ecrire le catalogue : la direction active seule, le titulaire d'abord (42501 avant 22023).
DO $ecrivains$
DECLARE
  v_qui record;
  v_ok text := pg_temp.sql_cat('{"code": "essai_refus", "famille": "technique", "libelle": "Essai", "actif": true, "cle": "cle-cat-refus-01"}');
  v_nul text := pg_temp.sql_cat('{}');
BEGIN
  FOR v_qui IN SELECT * FROM (VALUES
      (pg_temp.p('e1'), 'guardian', 'tuteur'),
      (pg_temp.p('c1'), 'accountant', 'comptabilite'),
      (pg_temp.p('b1'), 'teacher', 'enseignant sans candidature'),
      (pg_temp.p('24'), 'teacher', 'candidat (titulaire d''une candidature enseignant)'),
      (pg_temp.p('08'), 'teacher', 'candidat au compte desactive'),
      (NULL::uuid, NULL::text, 'session sans compte')) AS q(id, role, nom) LOOP
    PERFORM pg_temp.refus_en(v_qui.id, v_qui.role, v_ok, '42501', 'ecrire le catalogue : ' || v_qui.nom || ' refuse (42501)');
    PERFORM pg_temp.refus_en(v_qui.id, v_qui.role, v_nul, '42501',
      'ecrire le catalogue : ' || v_qui.nom || ', arguments absents : 42501 avant 22023');
  END LOOP;
  PERFORM pg_temp.refus_en(NULL, NULL, v_ok, '42501', 'ecrire le catalogue : anon refuse (42501)', 'anon');
END $ecrivains$;
SELECT pg_temp.vrai((SELECT count(*) FROM public.competences_catalogue) = 25
  AND (SELECT count(*) FROM public.competences_catalogue_journal) = 25
  AND (SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture') = 0,
  'aucun de ces refus n''a ecrit : 25 competences, 25 lignes de journal, aucune entree d''audit');

-- Arguments absents ou mal formes : 22023, rien d'ecrit.
SELECT pg_temp.garde('tc0', pg_temp.trace_cat());
DO $args_cat$
DECLARE
  v_a text;
  v_base jsonb := '{"code": "essai_forme", "famille": "technique", "libelle": "Essai de forme", "actif": true, "cle": "cle-cat-forme-01"}';
  v_n integer := 0;
BEGIN
  FOREACH v_a IN ARRAY ARRAY[
      '{"code": null}',
      '{"code": "Essai"}', '{"code": "e"}', '{"code": "1essai"}', '{"code": "essai-forme"}', '{"code": "essai forme"}',
      '{"code": "essai_forme_tres_long_tres_long_tres_long_tres"}',
      '{"code": "pedagogie"}', '{"code": "technique"}', '{"code": "finances_droit"}',
      '{"code": "autre"}', '{"famille": "autre"}',
      '{"famille": null}', '{"famille": "cuisine"}', '{"famille": "Technique"}', '{"famille": ""}',
      '{"ordre": 0}', '{"ordre": 1000}', '{"ordre": -1}',
      '{"libelle": null}', '{"libelle": ""}', '{"libelle": "   "}',
      '{"actif": null}',
      '{"version": 0}', '{"version": -3}',
      '{"cle": null}', '{"cle": "court"}'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || v_a::jsonb), '22023',
      'catalogue : argument invalide : 22023 : ' || v_a);
    v_n := v_n + 1;
  END LOOP;
  -- Les textes : trop longs, sur plusieurs lignes, avec un caractere de controle.
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('libelle', repeat('a', 81))), '22023', 'catalogue : libelle de 81 caracteres : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('libelle', repeat(' ', 5000) || 'x')), '22023', 'catalogue : libelle de plus de 1000 signes (blancs) : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('libelle', E'deux\nlignes')), '22023', 'catalogue : libelle sur deux lignes : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('libelle', E'tab\tulation')), '22023', 'catalogue : libelle avec une tabulation : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('libelle', 'sep' || chr(8232) || 'ligne')), '22023', 'catalogue : libelle avec un separateur de ligne Unicode : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('exemple', repeat('b', 201))), '22023', 'catalogue : exemple de 201 caracteres : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('exemple', E'deux\nlignes')), '22023', 'catalogue : exemple sur deux lignes : 22023');
  PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat(v_base || jsonb_build_object('exemple', repeat('b', 2000))), '22023', 'catalogue : exemple de plus de 1000 signes : 22023');
  PERFORM pg_temp.vrai(v_n = 27, 'vingt-sept jeux d''arguments invalides sur le code, la famille, l''ordre, le libelle, l''actif, la version et la cle, tous refuses (22023)');
END $args_cat$;
SELECT pg_temp.vrai(pg_temp.trace_cat() = pg_temp.lu('tc0'),
  'ces refus d''arguments n''ont rien ecrit : ni ligne, ni journal, ni audit, ni reponse');

-- (l.4) Ajouter : un code neuf, a la fin de sa famille, journalise et audite sans libelle.
SELECT pg_temp.garde('tc1', pg_temp.trace_cat());
SELECT pg_temp.garde('ajout1', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "  Modération des commentaires  ",
   "actif": true, "cle": "cle-cat-0001"}'));
SELECT pg_temp.vrai(pg_temp.lu('ajout1') = jsonb_build_object('inchange', false, 'rejoue', false, 'competence',
        jsonb_build_object('code', 'moderation', 'famille', 'communication', 'ordre', 9,
                           'libelle', 'Modération des commentaires', 'exemple', NULL, 'actif', true, 'version', 1))
  AND pg_temp.entree('moderation') = pg_temp.lu('ajout1') -> 'competence'
  AND (SELECT count(*) FROM public.competences_catalogue) = 26
  AND (SELECT count(*) FROM public.competences_catalogue_journal) = 26
  AND (SELECT geste = 'ajout' AND auteur_id = pg_temp.p('a1') AND cle_idempotence = 'cle-cat-0001'
              AND empreinte ~ '^[0-9a-f]{32}$' AND avant IS NULL AND apres ->> 'code' = 'moderation'
         FROM public.competences_catalogue_journal WHERE code = 'moderation'),
  'ajout : le code neuf est a la fin de sa famille (ordre 9), libelle sans blancs de tete ni de queue, version 1 ; une ligne de journal avec l''auteur, la cle et l''empreinte');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture') = 1
  AND (SELECT actor = pg_temp.p('a1') AND row_id = 'moderation' AND table_name = 'competences_catalogue'
              AND payload = '{"geste": "ajout", "famille": "communication", "actifAvant": null, "actifApres": true, "version": 1, "voie": "rpc"}'::jsonb
         FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture'),
  'ajout : une entree d''audit (qui, quel code, geste, famille, actif avant et apres, version, voie rpc), sans libelle ni exemple');

-- Rejeu, cle reutilisee, ajout d'un code deja la.
SELECT pg_temp.garde('tc2', pg_temp.trace_cat());
SELECT pg_temp.garde('ajout1r', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "  Modération des commentaires  ",
   "actif": true, "cle": "cle-cat-0001"}'));
SELECT pg_temp.garde('ajout1k', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Un autre libelle",
   "actif": true, "cle": "cle-cat-0001"}'));
SELECT pg_temp.garde('ajout1a', pg_temp.cat('a2', '{"code": "moderation", "famille": "communication", "libelle": "  Modération des commentaires  ",
   "actif": true, "cle": "cle-cat-0001"}'));
SELECT pg_temp.garde('ajout1v', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "  Modération des commentaires  ",
   "actif": true, "version": 1, "cle": "cle-cat-0001"}'));
SELECT pg_temp.garde('ajout1c', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération", "actif": true,
   "cle": "cle-cat-0002"}'));
SELECT pg_temp.vrai(pg_temp.lu('ajout1r') = jsonb_build_object('inchange', false, 'rejoue', true, 'competence', pg_temp.entree('moderation'))
  AND pg_temp.lu('ajout1k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('ajout1a') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('ajout1v') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.lu('ajout1c') = jsonb_build_object('erreur', 'conflit_catalogue', 'competence', pg_temp.entree('moderation'))
  AND pg_temp.trace_cat() = pg_temp.lu('tc2')
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue_journal WHERE cle_idempotence = 'cle-cat-0002'),
  'la meme cle rejouee rend la ligne relue (rejoue = true) sans ecrire ; la meme cle pour une autre demande (autre libelle, ou autre version attendue) ou par un autre compte est refusee ; ajouter un code deja la rend conflit_catalogue avec la ligne, sans garder la cle');

-- Ordre : a la fin de la famille, explicite, plafonne a 999 ; sans condition de genre (a2, a3, a4 ecrivent).
SELECT pg_temp.garde('ajout2', pg_temp.cat('a2', '{"code": "essai_ordre", "famille": "technique", "ordre": 999, "libelle": "Essai d''ordre",
   "exemple": "  Un exemple  ", "actif": true, "cle": "cle-cat-0003"}'));
SELECT pg_temp.garde('ajout3', pg_temp.cat('a3', '{"code": "essai_ordre_fin", "famille": "technique", "libelle": "Essai d''ordre en fin de famille",
   "actif": true, "cle": "cle-cat-0004"}'));
SELECT pg_temp.garde('ajout4', pg_temp.cat('a4', '{"code": "essai_inactif", "famille": "pedagogie", "ordre": 2, "libelle": "Ajoutee desactivee",
   "actif": false, "cle": "cle-cat-0005"}'));
SELECT pg_temp.vrai(pg_temp.lu('ajout2') #>> '{competence,ordre}' = '999' AND pg_temp.lu('ajout2') #>> '{competence,exemple}' = 'Un exemple'
  AND pg_temp.lu('ajout3') #>> '{competence,ordre}' = '999'
  AND pg_temp.lu('ajout4') #>> '{competence,ordre}' = '2' AND pg_temp.lu('ajout4') #>> '{competence,actif}' = 'false'
  AND (SELECT count(*) FROM public.competences_catalogue_journal WHERE auteur_id IN (pg_temp.p('a2'), pg_temp.p('a3'), pg_temp.p('a4'))) = 3,
  'la direction ecrit quel que soit son genre (femme, genre inconnu, super-admin) : ordre explicite, ordre de fin plafonne a 999, exemple sans blancs, ajout directement desactive');

-- (l.5) Modifier : par version attendue ; identique = sans effet ; code et famille ne changent pas ; desactiver et reactiver.
SELECT pg_temp.garde('tc3', pg_temp.trace_cat());
SELECT pg_temp.garde('mod_v', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération", "actif": true,
   "version": 7, "cle": "cle-cat-0010"}'));
SELECT pg_temp.garde('mod_v0', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération", "actif": true,
   "version": 2, "cle": "cle-cat-0011"}'));
SELECT pg_temp.garde('mod_abs', pg_temp.cat('a1', '{"code": "inconnue_du_catalogue", "famille": "communication", "libelle": "Absente", "actif": true,
   "version": 1, "cle": "cle-cat-0012"}'));
SELECT pg_temp.vrai(pg_temp.lu('mod_v') = jsonb_build_object('erreur', 'conflit_catalogue', 'competence', pg_temp.entree('moderation'))
  AND pg_temp.lu('mod_v0') = pg_temp.lu('mod_v')
  AND pg_temp.lu('mod_abs') = '{"erreur": "absente"}'::jsonb
  AND pg_temp.trace_cat() = pg_temp.lu('tc3')
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue_journal WHERE cle_idempotence IN ('cle-cat-0010', 'cle-cat-0011', 'cle-cat-0012')),
  'modifier avec une version perimee (trop haute) : conflit_catalogue avec la ligne relue ; un code absent : absente ; rien d''ecrit, aucune cle gardee');
SELECT pg_temp.refus_en(pg_temp.p('a1'), 'admin', pg_temp.sql_cat('{"code": "moderation", "famille": "technique", "libelle": "Modération",
   "actif": true, "version": 1, "cle": "cle-cat-0013"}'), '22023', 'modifier : la famille d''une competence ne change pas (22023)');

-- Une modification : libelle, exemple, ordre ; version 2 ; journal avec l'avant et l'apres.
SELECT pg_temp.garde('mod1', pg_temp.cat('a2', '{"code": "moderation", "famille": "communication", "libelle": "Modération des commentaires et messages",
   "exemple": "Réseaux sociaux, messagerie", "ordre": 3, "actif": true, "version": 1, "cle": "cle-cat-0014"}'));
SELECT pg_temp.vrai(pg_temp.lu('mod1') = jsonb_build_object('inchange', false, 'rejoue', false, 'competence', jsonb_build_object(
        'code', 'moderation', 'famille', 'communication', 'ordre', 3, 'libelle', 'Modération des commentaires et messages',
        'exemple', 'Réseaux sociaux, messagerie', 'actif', true, 'version', 2))
  AND (SELECT geste = 'modification' AND auteur_id = pg_temp.p('a2') AND avant ->> 'libelle' = 'Modération des commentaires'
              AND avant ->> 'version' = '1' AND apres ->> 'version' = '2' AND apres ->> 'ordre' = '3'
         FROM public.competences_catalogue_journal WHERE cle_idempotence = 'cle-cat-0014')
  AND (SELECT payload = '{"geste": "modification", "famille": "communication", "actifAvant": true, "actifApres": true, "version": 2, "voie": "rpc"}'::jsonb
              AND actor = pg_temp.p('a2')
         FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture' AND row_id = 'moderation' AND payload ->> 'version' = '2'),
  'modifier a la bonne version : version 2, libelle, exemple et ordre changes ; le journal garde l''avant et l''apres avec l''auteur ; l''audit note la version sans libelle');
-- Identique : rien ne change, rien n'est garde.
SELECT pg_temp.garde('tc4', pg_temp.trace_cat());
SELECT pg_temp.garde('mod_id', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "  Modération des commentaires et messages ",
   "exemple": "Réseaux sociaux, messagerie", "actif": true, "version": 2, "cle": "cle-cat-0015"}'));
SELECT pg_temp.vrai(pg_temp.lu('mod_id') = jsonb_build_object('inchange', true, 'rejoue', false, 'competence', pg_temp.entree('moderation'))
  AND (pg_temp.lu('mod_id') #>> '{competence,version}') = '2'
  AND (pg_temp.lu('mod_id') #>> '{competence,ordre}') = '3'
  AND pg_temp.trace_cat() = pg_temp.lu('tc4')
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue_journal WHERE cle_idempotence = 'cle-cat-0015'),
  'une modification identique (blancs sans effet, ordre nul = inchange) : inchange = true, version, journal et audit intacts, la cle n''est pas gardee');
-- Rejeu de la modification : la ligne relue, sans effet ; la cle d'une modification ne vaut pas pour une autre.
SELECT pg_temp.garde('mod1r', pg_temp.cat('a2', '{"code": "moderation", "famille": "communication", "libelle": "Modération des commentaires et messages",
   "exemple": "Réseaux sociaux, messagerie", "ordre": 3, "actif": true, "version": 1, "cle": "cle-cat-0014"}'));
SELECT pg_temp.garde('mod1k', pg_temp.cat('a2', '{"code": "moderation", "famille": "communication", "libelle": "Autre",
   "exemple": "Réseaux sociaux, messagerie", "ordre": 3, "actif": true, "version": 1, "cle": "cle-cat-0014"}'));
SELECT pg_temp.vrai(pg_temp.lu('mod1r') = jsonb_build_object('inchange', false, 'rejoue', true, 'competence', pg_temp.entree('moderation'))
  AND pg_temp.lu('mod1k') = '{"erreur": "cle_idempotence_reutilisee"}'::jsonb
  AND pg_temp.trace_cat() = pg_temp.lu('tc4'),
  'rejeu d''une modification reussie (meme cle, meme demande, version d''origine) : la ligne relue, rejoue = true, sans ecriture ; la meme cle pour une autre demande est refusee');

-- Desactiver puis reactiver : la version monte a chaque fois, l'audit note actif avant et apres.
SELECT pg_temp.garde('des1', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération des commentaires et messages",
   "exemple": "Réseaux sociaux, messagerie", "actif": false, "version": 2, "cle": "cle-cat-0016"}'));
SELECT pg_temp.garde('des1v', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération des commentaires et messages",
   "exemple": "Réseaux sociaux, messagerie", "actif": true, "version": 2, "cle": "cle-cat-0017"}'));
SELECT pg_temp.vrai(pg_temp.lu('des1') #>> '{competence,actif}' = 'false' AND pg_temp.lu('des1') #>> '{competence,version}' = '3'
  AND pg_temp.lu('des1v') ->> 'erreur' = 'conflit_catalogue'
  AND (SELECT payload = '{"geste": "modification", "famille": "communication", "actifAvant": true, "actifApres": false, "version": 3, "voie": "rpc"}'::jsonb
         FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture' AND row_id = 'moderation' AND payload ->> 'version' = '3'),
  'desactiver : actif = faux, version 3, une version perimee est refusee ; l''audit note actif avant (vrai) et apres (faux)');
SELECT pg_temp.garde('rea1', pg_temp.cat('a1', '{"code": "moderation", "famille": "communication", "libelle": "Modération des commentaires et messages",
   "exemple": "Réseaux sociaux, messagerie", "actif": true, "version": 3, "cle": "cle-cat-0018"}'));
SELECT pg_temp.vrai(pg_temp.lu('rea1') #>> '{competence,actif}' = 'true' AND pg_temp.lu('rea1') #>> '{competence,version}' = '4',
  'reactiver : actif = vrai, version 4 (une competence desactivee peut revenir)');

-- (l.6) Toute voie d'ecriture : ni suppression, ni vidage, ni changement de code ou de famille ; la version et le journal viennent du serveur.
SELECT pg_temp.garde('tc5', pg_temp.trace_cat());
SELECT pg_temp.refus($s$DELETE FROM public.competences_catalogue WHERE code = 'essai_inactif'$s$, '55000',
  'DELETE d''une competence jamais choisie : refuse (55000), une competence se desactive');
SELECT pg_temp.refus($s$DELETE FROM public.competences_catalogue$s$, '55000', 'DELETE de tout le catalogue : refuse (55000)');
SELECT pg_temp.refus($s$TRUNCATE public.competences_catalogue CASCADE$s$, '55000', 'TRUNCATE du catalogue : refuse (55000)');
SELECT pg_temp.refus($s$UPDATE public.competences_catalogue SET code = 'autre_code' WHERE code = 'moderation'$s$, '55000', 'le code d''une competence ne change pas (55000)');
SELECT pg_temp.refus($s$UPDATE public.competences_catalogue SET famille = 'technique' WHERE code = 'moderation'$s$, '55000', 'la famille d''une competence ne change pas (55000)');
SELECT pg_temp.refus($s$UPDATE public.competences_catalogue SET cree_le = now() WHERE code = 'moderation'$s$, '55000', 'la date de creation ne change pas (55000)');
SELECT pg_temp.refus($s$UPDATE public.competences_catalogue_journal SET apres = '{}'::jsonb$s$, '55000', 'le journal est en ajout seul : UPDATE refuse (55000)');
SELECT pg_temp.refus($s$DELETE FROM public.competences_catalogue_journal$s$, '55000', 'le journal est en ajout seul : DELETE refuse (55000)');
SELECT pg_temp.refus($s$TRUNCATE public.competences_catalogue_journal$s$, '55000', 'le journal est en ajout seul : TRUNCATE refuse (55000)');
SELECT pg_temp.vrai(pg_temp.trace_cat() = pg_temp.lu('tc5'), 'ces refus n''ont rien change : lignes, journal, audit et reponses intacts');
-- Un UPDATE qui ne change rien est ignore ; un vrai changement fait monter la version quoi qu'on ait ecrit.
UPDATE public.competences_catalogue SET libelle = libelle, actif = actif WHERE code = 'moderation';
UPDATE public.competences_catalogue SET version = 99, maj_le = '2001-01-01' WHERE code = 'moderation';
SELECT pg_temp.vrai(pg_temp.trace_cat() = pg_temp.lu('tc5')
  AND (SELECT version = 4 FROM public.competences_catalogue WHERE code = 'moderation'),
  'un UPDATE qui ne change ni libelle, ni exemple, ni ordre, ni actif est ignore (version et journal intacts), meme si on ecrit la version');
UPDATE public.competences_catalogue SET libelle = 'Modération (directe)', version = 99, maj_le = '2001-01-01' WHERE code = 'moderation';
SELECT pg_temp.vrai((SELECT version = 5 AND maj_le > '2020-01-01' FROM public.competences_catalogue WHERE code = 'moderation')
  AND (SELECT geste = 'modification' AND auteur_id IS NULL AND cle_idempotence IS NULL AND empreinte IS NULL
              AND apres ->> 'version' = '5' AND avant ->> 'version' = '4'
         FROM public.competences_catalogue_journal WHERE code = 'moderation' ORDER BY id DESC LIMIT 1)
  AND (SELECT payload ->> 'voie' = 'directe' AND payload ->> 'version' = '5'
         FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture' AND row_id = 'moderation' ORDER BY id DESC LIMIT 1),
  'un changement par le proprietaire (editeur SQL, migration) : la version monte a 5 quoi qu''on ait ecrit, le journal et l''audit le notent (voie directe, sans auteur ni cle)');
INSERT INTO public.competences_catalogue (code, famille, ordre, libelle, version, cree_le) VALUES ('essai_direct', 'technique', 5, 'Essai direct', 42, '2001-01-01');
SELECT pg_temp.vrai((SELECT version = 1 AND cree_le > '2020-01-01' FROM public.competences_catalogue WHERE code = 'essai_direct')
  AND (SELECT geste = 'ajout' AND auteur_id IS NULL FROM public.competences_catalogue_journal WHERE code = 'essai_direct'),
  'un ajout par le proprietaire : version 1 et date de creation du serveur, journalise (ajout, sans auteur)');
-- Les contraintes de la table.
DO $contraintes_cat$
DECLARE
  v_base text := $b$INSERT INTO public.competences_catalogue (code, famille, ordre, libelle, exemple) VALUES (%s)$b$;
BEGIN
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'Majuscule', 'technique', 1, 'x', NULL$v$), '23514', 'code a majuscule refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'x', 'technique', 1, 'x', NULL$v$), '23514', 'code d''un caractere refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'cuisine', 'cuisine', 1, 'x', NULL$v$), '23514', 'famille hors liste refusee (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'pedagogie', 'pedagogie', 1, 'x', NULL$v$), '23514', 'un code qui porte le nom d''une famille refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'communication', 'technique', 1, 'x', NULL$v$), '23514', 'un code qui porte le nom d''une famille (ancien domaine communication) refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'autre_chose', 'autre', 1, 'x', NULL$v$), '23514', 'la famille autre ne porte que le code autre (23514)');
  PERFORM pg_temp.refus($u$UPDATE public.competences_catalogue SET famille = 'technique' WHERE code = 'autre'$u$, '55000', 'le code autre ne quitte pas sa famille (55000)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_ordre_0', 'technique', 0, 'x', NULL$v$), '23514', 'ordre 0 refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_ordre_k', 'technique', 1000, 'x', NULL$v$), '23514', 'ordre 1000 refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_lib_a', 'technique', 1, '', NULL$v$), '23514', 'libelle vide refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_lib_b', 'technique', 1, ' x', NULL$v$), '23514', 'libelle avec un blanc de tete refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_lib_c', 'technique', 1, E'deux\nlignes', NULL$v$), '23514', 'libelle sur deux lignes refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_lib_d', 'technique', 1, repeat('a', 81), NULL$v$), '23514', 'libelle de 81 caracteres refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_exe_a', 'technique', 1, 'x', ''$v$), '23514', 'exemple vide refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'essai_exe_b', 'technique', 1, 'x', repeat('b', 201)$v$), '23514', 'exemple de 201 caracteres refuse (23514)');
  PERFORM pg_temp.refus(pg_catalog.format(v_base, $v$'moderation', 'communication', 1, 'x', NULL$v$), '23505', 'un code deja la refuse (23505)');
  PERFORM pg_temp.vrai(NOT EXISTS (SELECT 1 FROM public.competences_catalogue WHERE code LIKE 'essai\_%' AND code NOT IN
                                     ('essai_ordre', 'essai_ordre_fin', 'essai_inactif', 'essai_direct')),
    'aucun des ajouts refuses n''a laisse de ligne');
END $contraintes_cat$;

-- (l.7) Le candidat et un code desactive : lisible dans une reponse ancienne, plus choisissable.
-- 23 donne une reponse (juridique_donnees metier, comptabilite experience) tant que tout est actif.
SELECT pg_temp.garde('c23w', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"juridique_donnees": "metier", "comptabilite": "experience"}', NULL, 'mi_temps', true, 0, 'cle-ac-23-001')$$));
SELECT pg_temp.garde('des_jd', pg_temp.cat('a1', '{"code": "juridique_donnees", "famille": "finances_droit", "libelle": "Juridique et protection des données",
   "exemple": "Contrats, conditions d''utilisation, vie privée", "actif": false, "version": 1, "cle": "cle-cat-0020"}'));
SELECT pg_temp.vrai(pg_temp.lu('c23w') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('des_jd') #>> '{competence,actif}' = 'false' AND pg_temp.lu('des_jd') #>> '{competence,version}' = '2',
  'mise en place : 23 a choisi juridique_donnees quand il etait actif, puis la direction le desactive (version 2)');
SELECT pg_temp.garde('l23', pg_temp.en(pg_temp.p('23'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('l24', pg_temp.en(pg_temp.p('24'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('k23', pg_temp.en(pg_temp.p('23'), 'teacher', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.garde('k24', pg_temp.en(pg_temp.p('24'), 'teacher', $$SELECT public.lire_catalogue_competences()$$));
SELECT pg_temp.vrai(
      (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('l23') #> '{referentiel,competences}')) = 29
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('l24') #> '{referentiel,competences}')) = 28
  AND (SELECT c ->> 'actif' FROM jsonb_array_elements(pg_temp.lu('l23') #> '{referentiel,competences}') c WHERE c ->> 'code' = 'juridique_donnees') = 'false'
  AND (SELECT c ->> 'libelle' FROM jsonb_array_elements(pg_temp.lu('l23') #> '{referentiel,competences}') c WHERE c ->> 'code' = 'juridique_donnees')
        = 'Juridique et protection des données'
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l24') #> '{referentiel,competences}') c
                   WHERE c ->> 'code' IN ('juridique_donnees', 'essai_inactif'))
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('l23') #> '{referentiel,competences}') c WHERE c ->> 'code' = 'essai_inactif')
  AND (SELECT bool_and((c ->> 'actif')::boolean) FROM jsonb_array_elements(pg_temp.lu('l24') #> '{referentiel,competences}') c)
  AND pg_temp.lu('k23') -> 'competences' = pg_temp.lu('l23') #> '{referentiel,competences}'
  AND pg_temp.lu('k24') -> 'competences' = pg_temp.lu('l24') #> '{referentiel,competences}',
  'un code desactive : lisible (avec son libelle, actif = faux) dans la reponse ancienne de 23 ; absent de la liste offerte a 24 ; un code desactive que personne n''a choisi (essai_inactif) n''est offert a aucun candidat ; la lecture du catalogue dit la meme chose que celle des reponses');
SELECT pg_temp.vrai(
      (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('cat_a1') -> 'competences')) = 25
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_catalogue_competences()$$) -> 'competences')) = 30
  AND (SELECT c ->> 'actif' FROM jsonb_array_elements(pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_catalogue_competences()$$) -> 'competences') c
        WHERE c ->> 'code' = 'essai_inactif') = 'false',
  'la direction lit tout, desactives compris (30 competences, dont essai_inactif a actif = faux)');

-- 24 ne peut pas choisir un code desactive : refus rendu, aucune ecriture.
SELECT pg_temp.garde('t24', pg_temp.trace(pg_temp.c('24')));
SELECT pg_temp.garde('tc6', pg_temp.trace_cat());
SELECT pg_temp.garde('d24a', pg_temp.en(pg_temp.p('24'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"juridique_donnees": "debutant"}', NULL, 'plus', true, 0, 'cle-ac-24-001')$$));
SELECT pg_temp.garde('d24b', pg_temp.en(pg_temp.p('24'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier", "essai_inactif": "metier"}', NULL, 'plus', true, 0, 'cle-ac-24-002')$$));
SELECT pg_temp.garde('d24c', pg_temp.en(pg_temp.p('24'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"cuisine": "metier", "juridique_donnees": "metier"}', NULL, 'plus', true, 0, 'cle-ac-24-003')$$));
SELECT pg_temp.vrai(
      pg_temp.lu('d24a') = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaine_desactive"}}'::jsonb
  AND pg_temp.lu('d24b') = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaine_desactive"}}'::jsonb
  AND pg_temp.lu('d24c') = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaine_inconnu"}}'::jsonb
  AND (SELECT count(*) FROM public.candidature_gestes WHERE cle IN ('cle-ac-24-001', 'cle-ac-24-002', 'cle-ac-24-003')) = 0
  AND pg_temp.trace(pg_temp.c('24')) = pg_temp.lu('t24')
  AND pg_temp.trace_cat() = pg_temp.lu('tc6'),
  'un code desactive ne peut plus etre choisi par qui ne l''avait pas deja (domaine_desactive, meme parmi des codes actifs) ; un code absent du catalogue reste domaine_inconnu (et prime) ; le refus n''ecrit rien et ne garde pas la cle');

-- 23 garde son code desactive : enregistrer a l'identique, changer la disponibilite, changer le niveau.
SELECT pg_temp.garde('c23i', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience", "juridique_donnees": "metier"}', NULL, 'mi_temps', true, 1, 'cle-ac-23-002')$$));
SELECT pg_temp.garde('c23d', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience", "juridique_donnees": "metier"}', NULL, 'plus', true, 1, 'cle-ac-23-003')$$));
SELECT pg_temp.garde('c23n', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience", "juridique_donnees": "experience"}', NULL, 'plus', true, 2, 'cle-ac-23-004')$$));
SELECT pg_temp.vrai(pg_temp.lu('c23i') = '{"version": 1, "inchange": true, "rejoue": false}'::jsonb
  AND pg_temp.lu('c23d') = '{"version": 2, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('c23n') = '{"version": 3, "inchange": false, "rejoue": false}'::jsonb
  AND (SELECT domaines = '{"comptabilite": "experience", "juridique_donnees": "experience"}' AND disponibilite = 'plus'
         FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('23')),
  'qui avait choisi un code avant sa desactivation le garde : enregistrer a l''identique (inchange), changer la disponibilite, changer son niveau passent ; rien ne l''oblige a perdre sa reponse');

-- La direction le lit dans le dossier.
SELECT pg_temp.garde('d23', pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lire_candidature('ca7acccc-0000-4000-8000-000000000023')$$));
SELECT pg_temp.vrai(pg_temp.lu('d23') #> '{autresCompetences,domaines}' = '{"comptabilite": "experience", "juridique_donnees": "experience"}'::jsonb,
  'la direction lit dans le dossier le code desactive de la reponse ancienne');

-- Le filtre : un code OU une famille, desactives compris.
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDomaine": "finances_droit"}') = ARRAY['10', '11', '18', '23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "juridique_donnees"}') = ARRAY['23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "comptabilite"}') = ARRAY['10', '11', '18', '23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "finances_droit", "competenceNiveauMin": "metier"}') = ARRAY['10']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "juridique_donnees", "competenceNiveauMin": "experience"}') = ARRAY['23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "juridique_donnees", "competenceNiveauMin": "metier"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "finances_droit", "competenceDisponibilite": "plus", "competenceAccord": true}') = ARRAY['11', '18', '23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "communication"}') = ARRAY['01', '07', '12']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "administration"}') = ARRAY['02']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "technique"}') = ARRAY['06', '12']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "pedagogie"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "autre"}') = ARRAY['15'],
  'le filtre accepte une famille (tous ses codes, desactives compris : finances_droit rend 23 par juridique_donnees desactive et par comptabilite) ou un code (le desactive reste cherchable), seul ou avec niveau, disponibilite et accord ; la famille autre vaut le code autre');
SELECT pg_temp.vrai(
      pg_temp.filtre('a1', '{"competenceDomaine": "autre"}') = pg_temp.filtre('a1', '{"competenceDomaine": "autre", "competenceNiveauMin": "debutant"}')
  AND pg_temp.filtre('a2', '{"competenceDomaine": "finances_droit"}') = ARRAY['14']
  AND pg_temp.filtre('a2', '{"competenceDomaine": "administration"}') = ARRAY['03', '13']
  AND pg_temp.filtre('a2', '{"competenceDomaine": "juridique_donnees"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "coordination_groupe"}') = ARRAY[]::text[]
  AND (pg_temp.en(pg_temp.p('a1'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "administration"}', 'nom', 1)$$) ->> 'total') = '1'
  AND (pg_temp.en(pg_temp.p('a2'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "administration"}', 'nom', 1)$$) ->> 'total') = '2'
  AND (pg_temp.en(pg_temp.p('a4'), 'admin', $$SELECT public.lister_candidatures('{"competenceDomaine": "administration"}', 'nom', 1)$$) ->> 'total') = '3',
  'separation femmes et hommes : une famille ne rend que les candidatures du cote du lecteur (administration : 02 pour lui, 03 et 13 pour elle, les trois pour le super-admin)');
DO $famille_invalide$
DECLARE
  v_f text;
BEGIN
  FOREACH v_f IN ARRAY ARRAY['{"competenceDomaine": "cuisine"}', '{"competenceDomaine": "Pedagogie"}',
                             '{"competenceDomaine": "finances"}', '{"competenceDomaine": "finances_droit,pedagogie"}',
                             '{"competenceDomaine": ["finances_droit"]}'] LOOP
    PERFORM pg_temp.refus_en(pg_temp.p('a1'), 'admin',
      pg_catalog.format($q$SELECT public.lister_candidatures(%L::jsonb, 'nom', 1)$q$, v_f), '22023',
      'filtre de famille ou de code invalide : 22023 : ' || v_f);
  END LOOP;
END $famille_invalide$;

-- 23 retire le code desactive : il ne peut plus le reprendre, tant qu'il n'est pas reactive.
SELECT pg_temp.garde('c23r', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience"}', NULL, 'plus', true, 3, 'cle-ac-23-005')$$));
SELECT pg_temp.garde('c23b', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience", "juridique_donnees": "metier"}', NULL, 'plus', true, 4, 'cle-ac-23-006')$$));
SELECT pg_temp.garde('l23b', pg_temp.en(pg_temp.p('23'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.vrai(pg_temp.lu('c23r') = '{"version": 4, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('c23b') = '{"erreur": "reponses_invalides", "champs": ["domaines"], "motifs": {"domaines": "domaine_desactive"}}'::jsonb
  AND (SELECT count(*) FROM jsonb_array_elements(pg_temp.lu('l23b') #> '{referentiel,competences}')) = 28
  AND pg_temp.filtre('a1', '{"competenceDomaine": "juridique_donnees"}') = ARRAY[]::text[]
  AND pg_temp.filtre('a1', '{"competenceDomaine": "finances_droit"}') = ARRAY['10', '11', '18', '23'],
  'le code desactive ote de sa reponse, 23 ne peut plus le reprendre et ne le voit plus dans sa liste ; la recherche par ce code ne trouve plus personne, la famille trouve toujours 23 par comptabilite');
-- Reactiver : tout le monde peut de nouveau le choisir. Un code neuf est offert aussitot.
SELECT pg_temp.garde('rea_jd', pg_temp.cat('a1', '{"code": "juridique_donnees", "famille": "finances_droit", "libelle": "Juridique et protection des données",
   "exemple": "Contrats, conditions d''utilisation, vie privée", "actif": true, "version": 2, "cle": "cle-cat-0021"}'));
SELECT pg_temp.garde('c23c', pg_temp.en(pg_temp.p('23'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "experience", "juridique_donnees": "metier"}', NULL, 'plus', true, 4, 'cle-ac-23-007')$$));
SELECT pg_temp.garde('c24m', pg_temp.en(pg_temp.p('24'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"moderation": "experience", "essai_ordre": "debutant"}', NULL, 'quelques_heures', true, 0, 'cle-ac-24-005')$$));
SELECT pg_temp.vrai(pg_temp.lu('rea_jd') #>> '{competence,version}' = '3'
  AND pg_temp.lu('c23c') = '{"version": 5, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.lu('c24m') = '{"version": 1, "inchange": false, "rejoue": false}'::jsonb
  AND pg_temp.filtre('a1', '{"competenceDomaine": "juridique_donnees", "competenceNiveauMin": "metier"}') = ARRAY['23']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "communication"}') = ARRAY['01', '07', '12', '24']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "moderation"}') = ARRAY['24']
  AND pg_temp.filtre('a1', '{"competenceDomaine": "technique"}') = ARRAY['06', '12', '24'],
  'reactive, le code redevient choisissable ; un code ajoute par la direction est offert et choisissable aussitot, et la recherche par famille (communication, technique) le trouve');
-- Le declencheur de la table ne lit pas l'etat actif : une reponse ancienne se reenregistre, et le proprietaire peut ecrire un code desactive.
SELECT pg_temp.garde('des_in', pg_temp.cat('a1', '{"code": "essai_inactif", "famille": "pedagogie", "libelle": "Ajoutee desactivee", "actif": false,
   "version": 1, "ordre": 4, "cle": "cle-cat-0022"}'));
UPDATE public.candidature_autres_competences SET domaines = domaines || '{"essai_inactif": "debutant"}'::jsonb
 WHERE candidature_id = pg_temp.c('24');
SELECT pg_temp.vrai(pg_temp.lu('des_in') #>> '{competence,ordre}' = '4'
  AND (SELECT domaines ? 'essai_inactif' FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('24')),
  'le declencheur de la table verifie la presence au catalogue, pas l''etat actif : une ecriture directe d''un code desactive passe');
-- Retirer reste permis pour tous, desactive ou non.
SELECT pg_temp.garde('x24', pg_temp.en(pg_temp.p('24'), 'teacher', $$SELECT public.retirer_autres_competences(1, 'cle-ac-24-006')$$));
SELECT pg_temp.vrai(pg_temp.lu('x24') = '{"retire": true, "version": 0, "rejoue": false}'::jsonb,
  'retirer ses reponses reste permis, quel que soit l''etat des codes qu''elles citent');

-- (l.8) L'audit du catalogue se lit par toute direction active (aucune candidature visee, donc aucun cote) ;
-- aucun libelle ni exemple n'y figure.
CREATE FUNCTION pg_temp.audit_cat(p_qui text) RETURNS jsonb
LANGUAGE sql AS $$
  SELECT pg_temp.en(pg_temp.p(p_qui), 'admin',
    $q$SELECT coalesce(jsonb_agg(jsonb_build_object('ligne', j.ligne_visee, 'table', j.table_visee, 'details', j.details) ORDER BY j.entree_id), '[]'::jsonb)
         FROM public.journal_audit(NULL, 'competences_catalogue_ecriture', NULL, 200) j$q$);
$$;
SELECT pg_temp.garde('aud_a1', pg_temp.audit_cat('a1'));
SELECT pg_temp.garde('aud_a2', pg_temp.audit_cat('a2'));
SELECT pg_temp.garde('aud_a3', pg_temp.audit_cat('a3'));
SELECT pg_temp.garde('aud_a4', pg_temp.audit_cat('a4'));
SELECT pg_temp.vrai(jsonb_array_length(pg_temp.lu('aud_a1')) = (SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture')
  AND jsonb_array_length(pg_temp.lu('aud_a1')) >= 12
  AND pg_temp.lu('aud_a1') = pg_temp.lu('aud_a2') AND pg_temp.lu('aud_a1') = pg_temp.lu('aud_a3') AND pg_temp.lu('aud_a1') = pg_temp.lu('aud_a4')
  AND NOT EXISTS (SELECT 1 FROM jsonb_array_elements(pg_temp.lu('aud_a1')) t
                   WHERE t ->> 'table' <> 'competences_catalogue'
                      OR (t -> 'details')::text ~* '(libelle|exemple|Mod.ration|Juridique|Contrats)'
                      OR (SELECT array_agg(k ORDER BY k) FROM jsonb_object_keys(t -> 'details') k)
                         IS DISTINCT FROM ARRAY['actifApres', 'actifAvant', 'famille', 'geste', 'version', 'voie']),
  'l''audit du catalogue est lu par toute direction active (homme, femme, genre inconnu, super-admin), sans libelle ni exemple : geste, famille, actif avant et apres, version, voie');
SELECT pg_temp.vrai((SELECT count(*) FROM public.audit_logs WHERE action = 'candidature_exception_super_admin'
                      AND actor = pg_temp.p('a4') AND payload ->> 'lecture' = 'journal_audit'
                      AND (payload ->> 'lignesAutreCote')::int = (SELECT count(*) FROM public.audit_logs WHERE action = 'competences_catalogue_ecriture')) = 0,
  'le super-admin qui lit l''audit du catalogue n''est pas journalise comme exception : ces lignes n''ont pas de cote');

-- (l.9) Ni controle, ni paiement, ni etat_dossier() : le catalogue n'y change rien (etat de 02 comme avant tout changement).
SELECT pg_temp.vrai(pg_temp.en(pg_temp.p('02'), 'teacher', $$SELECT public.etat_dossier()$$) = pg_temp.lu('apres_etat')
  AND (SELECT private.paiement_etat(c.id) FROM public.candidatures c WHERE c.id = pg_temp.c('02')) IS NOT DISTINCT FROM (pg_temp.lu('apres_ctrl') ->> 'paiement'),
  'apres tous ces changements du catalogue (ajouts, modifications, desactivations), etat_dossier() et le paiement de 02 sont ceux d''avant');

-- (l.9 bis) L'ouverture ne compte que le document de reponses du CANDIDAT : un document importe (source import),
-- meme envoye et hors brouillon, n'ouvre rien.
SELECT pg_temp.cand('26', 'male', 'prequalification', 'a_completer', 'en_cours', false, NULL);
INSERT INTO public.candidature_reponses (candidature_id, questionnaire_version, reponses, source, brouillon, envoye_le)
VALUES (pg_temp.c('26'), 'import-drive', '{}'::jsonb, 'import', false, pg_catalog.clock_timestamp());
SELECT pg_temp.garde('l26', pg_temp.en(pg_temp.p('26'), 'teacher', $$SELECT public.lire_autres_competences()$$));
SELECT pg_temp.garde('w26', pg_temp.en(pg_temp.p('26'), 'teacher',
  $$SELECT public.enregistrer_autres_competences('{"comptabilite": "metier"}', NULL, 'mi_temps', true, 0, 'cle-ac-26-001')$$));
SELECT pg_temp.vrai(pg_temp.lu('l26') @> '{"ouvert": false, "raison": "questionnaire_non_envoye"}'::jsonb
  AND pg_temp.lu('w26') = '{"erreur": "questionnaire_non_envoye", "issue": "en_cours"}'::jsonb
  AND (SELECT count(*) FROM public.candidature_autres_competences WHERE candidature_id = pg_temp.c('26')) = 0,
  'un document de reponses importe, meme envoye et hors brouillon, n''ouvre rien : seul l''envoi de la Salle d''examen par le candidat compte');

-- (l.10) Le plafond de 100 codes : on remplit jusqu'a 99 (le proprietaire), la direction ajoute le 100e, puis plus.
INSERT INTO public.competences_catalogue (code, famille, ordre, libelle)
SELECT 'remplissage_' || n, 'technique', 100 + n, 'Remplissage ' || n
  FROM generate_series(1, 100 - (SELECT count(*) FROM public.competences_catalogue)::integer - 1) n;
SELECT pg_temp.vrai((SELECT count(*) FROM public.competences_catalogue) = 99, 'plafond : le catalogue compte 99 codes');
SELECT pg_temp.garde('cap100', pg_temp.cat('a1', '{"code": "centieme", "famille": "technique", "libelle": "Le centieme", "actif": true, "cle": "cle-cat-0030"}'));
SELECT pg_temp.garde('cap101', pg_temp.cat('a1', '{"code": "cent_unieme", "famille": "technique", "libelle": "Le cent unieme", "actif": true, "cle": "cle-cat-0031"}'));
SELECT pg_temp.garde('capmod', pg_temp.cat('a1', '{"code": "centieme", "famille": "technique", "libelle": "Le centieme, modifie", "actif": false,
   "version": 1, "cle": "cle-cat-0032"}'));
SELECT pg_temp.garde('capdup', pg_temp.cat('a1', '{"code": "centieme", "famille": "technique", "libelle": "Doublon", "actif": true, "cle": "cle-cat-0033"}'));
SELECT pg_temp.vrai(pg_temp.lu('cap100') #>> '{competence,code}' = 'centieme'
  AND pg_temp.lu('cap101') = '{"erreur": "catalogue_plein"}'::jsonb
  AND pg_temp.lu('capmod') #>> '{competence,version}' = '2'
  AND pg_temp.lu('capdup') ->> 'erreur' = 'conflit_catalogue'
  AND (SELECT count(*) FROM public.competences_catalogue) = 100
  AND NOT EXISTS (SELECT 1 FROM public.competences_catalogue_journal WHERE cle_idempotence IN ('cle-cat-0031', 'cle-cat-0033')),
  'plafond : le 100e code passe, le 101e est refuse (catalogue_plein, rien d''ecrit, cle non gardee) ; modifier ou desactiver reste permis au plafond ; ajouter un code deja la dit conflit_catalogue');

DO $fin$
BEGIN
  IF current_setting('test.n')::int <> 0 THEN
    RAISE NOTICE 'CAND-AUTRES : % controles verts', current_setting('test.n');
  END IF;
  IF current_setting('test.n')::int <> 302 THEN
    RAISE EXCEPTION 'CAND-AUTRES ROUGE : % controles executes, 302 attendus', current_setting('test.n');
  END IF;
END $fin$;

ROLLBACK;
