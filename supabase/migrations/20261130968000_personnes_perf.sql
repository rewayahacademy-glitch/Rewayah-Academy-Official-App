-- PERSONNES-PERF (plan du parcours, PE-C9 « lenteur du bureau » ; directeur, 20/11/2026, 23 h 30 : « il est temps de penser
-- a la performance de ces pages, il faut que tu revoies ce qui se passe avec la BD pour ces pages »). Premiere des deux
-- migrations du lot (la seconde, 20261130968500, est installable seule) : les index manquants et les plans gardes de la
-- messagerie, plus une lecture legere des non-lus.
--
-- MESURE (production, lecture seule, 20/11/2026 ; pg_stat_statements depuis le 15/11 12 h) :
--   * com_lister_fils = 74 % du temps de toute la base (32 895 s sur 19 351 appels, 1,7 s en moyenne, 10 555 blocs par
--     appel) ; sur 24 h, 431 reponses 500 a 8 s (delai depasse), toutes pour un compte de la direction. La page
--     Candidatures, la coquille du bureau (icone des messages) et l'accueil de la direction l'appellent pour compter des
--     non-lus. Sur une base fictive a l'echelle (733 profils, 650 candidatures, 360 fils, 860 messages), 1,05 s par appel,
--     dont 1,1 s dans des aides SQL privees appelees par fil et par message (com_paires 360 fois, com_participant 1 580
--     fois, com_objet 360 fois...) : une fonction LANGUAGE sql munie de SET search_path n'est jamais integree a la requete
--     appelante, et son corps est re-analyse et re-planifie A CHAQUE APPEL.
--   * kyc_documents n'a aucun index sur profile_id : 476 543 lectures sequentielles depuis le 15/11 (comptes_admin_par_role
--     en fait trois par compte, les controles de salle 3 de lister_candidatures et dossiers_en_attente aussi). profiles n'a
--     aucun index sur household_id : 105 899 lectures sequentielles (eleves d'un foyer, par compte et par fil de famille).
--
-- CE QUI CHANGE :
--   1. Deux index, crees par CREATE INDEX ordinaire (sans CONCURRENTLY) : kyc_documents fait 176 kB et profiles 240 kB en
--      production le 20/11 ; la creation prend quelques millisecondes et la migration reste une transaction ordinaire.
--   2. DOUZE aides passent de LANGUAGE sql a LANGUAGE plpgsql, CORPS IDENTIQUE (la meme requete, rendue par RETURN (...)
--      ou RETURN QUERY), pour que leur plan soit garde d'un appel a l'autre : dix aides privees de la messagerie
--      (com_participant, com_objet, com_paires, com_candidature_lisible, com_est_partie, entretien_cote_permis,
--      praxis_est_officiel, com_profil_valide, com_est_mineur, com_foyer_valide) et deux portes de la direction lues par
--      compte (app_private.compte_candidat_hors_portee, 733 appels par lecture de comptes_admin_par_role ou de
--      dossiers_en_attente ; public.kyc_super_admin_exception_active). Meme signature, meme volatilite (STABLE), meme
--      SECURITY (DEFINER pour entretien_cote_permis, compte_candidat_hors_portee et kyc_super_admin_exception_active), meme
--      search_path vide, meme proprietaire, memes droits (CREATE OR REPLACE les conserve ; le controle final compare
--      chaque liste de droits a celle de la production du 20/11, agent_ro et service_role compris). Chaque corps remplace
--      est celui installe en production le 20/11, controle par son empreinte md5(prosrc) ci-dessous. Mesure locale :
--      com_lister_fils 1 050 ms -> 235 ms, reponse identique octet pour octet.
--      POLITIQUES RLS qui en emploient une : profiles_compte_candidat_portee et
--      contract_acceptances_compte_candidat_portee (app_private.compte_candidat_hors_portee) ; meme reponse, donc meme
--      filtrage. Aucune vue.
--      APPELANTS de ces aides (releve du 20/11 sur une base rejouee jusqu'a 20261130966000) : com_lister_fils, com_lire_fil, com_lire_fil_page, com_conversations_pour_objet, com_fil_pour_objet,
--      com_mes_capacites, com_ouvrir_conversation, praxis_ecrire, private.com_fil_json, com_annonce_json,
--      com_annonce_generale_json, com_destinataires_signal, push1_depuis_message_candidat, praxis_est_partie_a,
--      praxis_est_equipe, praxis_auteur_direction, praxis_auteur_json, et pour entretien_cote_permis :
--      ouvrir_creneau_entretien, ecrire_compte_rendu_entretien, personnel_entretiens, personnel_pour_entretien,
--      ajouter_participant_entretien, entretien_creneau_tenable, entretien_conclusion, entretien_controles_planification ;
--      pour compte_candidat_hors_portee : comptes_admin, comptes_admin_par_role, dossiers_en_attente, indicateurs_admin ;
--      pour kyc_super_admin_exception_active : compte_candidat_hors_portee, read_kyc_documents,
--      autoriser_lecture_piece_identite, indicateurs_admin, references_dossiers_admin, journal_audit,
--      journal_audit_filtres, private.cand_lecteur, candidature_geste_ouvrir, candidature_lot_examiner,
--      candidature_lot_tracer, pelc_lot_examiner, entretien_peut_agir, com_annonce_cotes.
--      Leurs reponses ne changent pas : meme requete, meme instantane (STABLE), seul le moment de la planification change.
--   3. Une lecture legere, public.com_non_lus_par_objet() : pour chaque fil que l'appelant voit et qui a des messages non
--      lus, {fil, type, objet, non_lus}. MEMES DROITS que com_lister_fils : meme appelant (private.com_appelant_msg),
--      memes fils (com_est_partie sur les deux parties), meme visibilite et meme compte, recopies de private.com_fil_json
--      dans private.com_fil_non_lus (un fil que com_fil_json ne rend pas n'a ici aucune ligne). Quelques centaines
--      d'octets au lieu de toute la messagerie (540 Ko pour la direction sur la base fictive). AUCUN ecran ne la lit
--      encore : la PR #673 (veille des messages) la fera lire, avec repli sur com_lister_fils tant qu'elle manque.
-- MOTS D'EFFACEMENT : zero. Aucune donnee n'est ecrite. Rien n'est allume.

DO $preflight$
DECLARE
  v record;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('private.com_participant(text,uuid,text,uuid)', '63bf0ee76576ee8302eb1ef85ebbe44a'),
      ('private.com_objet(text,uuid)', '03b1846bde02f40b9c3dc554ad3922b5'),
      ('private.com_paires(text,uuid)', '99c56abad2ba63b29818bbee82d03d76'),
      ('private.com_candidature_lisible(uuid,uuid)', '9a6161c7305d40adb79461ba5d0efcd9'),
      ('private.com_est_partie(uuid,text,uuid,text,text,uuid)', '1c3cb14974bc909fa4f870d20707a62f'),
      ('private.entretien_cote_permis(uuid,public.gender)', 'b8a8dd6c32ed9c41080c4ad33bf38c4b'),
      ('private.praxis_est_officiel(uuid)', '6e17426dcd6e8cb6584917f6e665e384'),
      ('private.com_profil_valide(uuid,text)', '50b93d06d9034e69cd3f3fa422c02072'),
      ('private.com_est_mineur(uuid)', '23e730d3569e906da03f9847a4792d9e'),
      ('private.com_foyer_valide(uuid)', 'abe8be22d3573e9ae2398affc40c756d'),
      ('app_private.compte_candidat_hors_portee(uuid)', '843dc3d6bef47238d68805d246a90cdf'),
      ('public.kyc_super_admin_exception_active()', '133bc9bb5c3fe4d280868baba28e6f53'),
      ('private.com_fil_json(uuid,uuid,text,uuid)', '3002018f5fa3b207660bf515d959e92f'),
      ('private.com_appelant_msg()', '09f560034780d28459ce49896a924622')) AS t(f, md5) LOOP
    IF pg_catalog.to_regprocedure(v.f) IS NULL THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % absente ; rien n''est modifie', v.f;
    END IF;
    IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
         WHERE p.oid = pg_catalog.to_regprocedure(v.f)) IS DISTINCT FROM v.md5 THEN
      IF (SELECT l.lanname FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_language l ON l.oid = p.prolang
           WHERE p.oid = pg_catalog.to_regprocedure(v.f)) = 'plpgsql'
         AND pg_catalog.to_regprocedure('public.com_non_lus_par_objet()') IS NOT NULL THEN
        RAISE EXCEPTION 'PERSONNES-PERF : deja installe ; rien n''est modifie';
      END IF;
      RAISE EXCEPTION 'PERSONNES-PERF : la definition de % n''est pas celle attendue ; rien n''est modifie', v.f;
    END IF;
  END LOOP;
  IF pg_catalog.to_regprocedure('public.com_non_lus_par_objet()') IS NOT NULL
     OR pg_catalog.to_regprocedure('private.com_fil_non_lus(uuid,uuid,text,uuid)') IS NOT NULL THEN
    RAISE EXCEPTION 'PERSONNES-PERF : com_non_lus_par_objet existe deja ; rien n''est modifie';
  END IF;
END
$preflight$;

-- 1. Les index manquants.
CREATE INDEX IF NOT EXISTS kyc_documents_profil_recent_idx
  ON public.kyc_documents (profile_id, created_at DESC, id DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS profiles_foyer_idx
  ON public.profiles (household_id)
  WHERE household_id IS NOT NULL;

-- 2. Les aides de la messagerie, corps identiques, en plpgsql (plans gardes).
CREATE OR REPLACE FUNCTION private.com_participant(p_nature text, p_id uuid, p_type text, p_objet_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT CASE p_nature
    WHEN 'equipe' THEN pg_catalog.jsonb_build_object(
      'id', 'administration', 'nature', 'equipe', 'fonction', 'administration')
    WHEN 'foyer' THEN pg_catalog.jsonb_build_object(
      'id', p_id::text, 'nature', 'foyer', 'fonction', 'famille',
      'eleves', coalesce((
        SELECT pg_catalog.jsonb_agg(s.first_name ORDER BY s.first_name, s.id)
        FROM public.profiles s
        WHERE s.household_id = p_id AND s.deleted_at IS NULL
          AND s.role = 'student' AND private.com_est_mineur(s.id)
          AND CASE p_type
                WHEN 'eleve' THEN s.id = p_objet_id
                WHEN 'classe' THEN EXISTS (
                  SELECT 1 FROM public.groupe_membres m
                  WHERE m.student_id = s.id AND m.groupe_id = p_objet_id AND m.left_at IS NULL)
                ELSE true END), '[]'::jsonb))
    ELSE (
      SELECT pg_catalog.jsonb_build_object(
        'id', p.id::text, 'nature', 'profil',
        'fonction', CASE p.role WHEN 'teacher' THEN 'enseignant'
                                WHEN 'guardian' THEN 'famille'
                                WHEN 'student' THEN 'eleve'
                                ELSE 'personne' END,
        'officiel', private.praxis_est_officiel(p.id),
        'compte_officiel', (SELECT o.code FROM private.comptes_officiels o WHERE o.profile_id = p.id),
        'prenom', p.first_name,
        'nom', CASE WHEN p.role = 'teacher' THEN p.last_name END,
        'titre', CASE WHEN p.role = 'teacher' THEN
                   CASE p.gender WHEN 'female' THEN 'sayyida' WHEN 'male' THEN 'sayid' END END)
      FROM public.profiles p WHERE p.id = p_id)
    END
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_objet(p_type text, p_objet_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
    'type', p_type, 'id', p_objet_id::text,
    'classe', CASE p_type
      WHEN 'classe' THEN (SELECT g.libelle FROM public.groupes g WHERE g.id = p_objet_id)
      WHEN 'eleve' THEN (SELECT g.libelle FROM public.groupe_membres m
                           JOIN public.groupes g ON g.id = m.groupe_id
                          WHERE m.student_id = p_objet_id AND m.left_at IS NULL
                          ORDER BY m.joined_at DESC LIMIT 1)
      WHEN 'remplacement' THEN (SELECT g.libelle FROM public.remplacements_seance r
                                  JOIN public.sessions s ON s.id = r.session_id
                                  JOIN public.groupes g ON g.id = s.groupe_id
                                 WHERE r.id = p_objet_id)
      END,
    'prenom', CASE p_type WHEN 'eleve' THEN
      (SELECT p.first_name FROM public.profiles p WHERE p.id = p_objet_id) END))
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_paires(p_type text, p_objet_id uuid)
 RETURNS TABLE(a_nature text, a_id uuid, b_nature text, b_id uuid)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
#variable_conflict use_column
BEGIN
  RETURN QUERY
  WITH membres AS (
    -- Eleves actifs d'une Classe active, avec leur enseignant valide.
    SELECT g.id AS groupe_id, g.teacher_id, s.id AS eleve_id, s.household_id,
           private.com_est_mineur(s.id) AS mineur
    FROM public.groupes g
    JOIN public.groupe_membres m ON m.groupe_id = g.id AND m.left_at IS NULL
    JOIN public.profiles s ON s.id = m.student_id AND s.deleted_at IS NULL
    WHERE g.ended_at IS NULL
      -- Economie (15/11/2026) : les branches ci-dessous ne lisent que les
      -- membres de la Classe demandee (type classe) ou l'eleve demande (type
      -- eleve) ; les autres types n'en lisent aucun. Calculer com_est_mineur
      -- pour chaque membre de chaque Classe, a chaque appel, coutait environ
      -- 15 ms par fil. Meme resultat.
      AND ((p_type = 'classe' AND g.id = p_objet_id)
           OR (p_type = 'eleve' AND s.id = p_objet_id))
  ), cibles AS (
    -- Classe : chaque foyer d'un eleve mineur, chaque eleve adulte, avec
    -- l'enseignant ; foyer et Administration ; enseignant et Administration.
    SELECT 'foyer' AS a_nature, mb.household_id AS a_id, 'profil' AS b_nature, mb.teacher_id AS b_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'classe' AND mb.groupe_id = p_objet_id AND NOT mb.mineur
    UNION
    SELECT 'profil', g.teacher_id, 'equipe', NULL
      FROM public.groupes g WHERE p_type = 'classe' AND g.id = p_objet_id AND g.ended_at IS NULL
    -- Eleve : mineur, son foyer avec son enseignant et avec l'Administration ;
    -- adulte, lui-meme avec son enseignant.
    UNION
    SELECT 'foyer', mb.household_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'foyer', mb.household_id, 'equipe', NULL
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND mb.mineur
    UNION
    SELECT 'profil', mb.eleve_id, 'profil', mb.teacher_id
      FROM membres mb WHERE p_type = 'eleve' AND mb.eleve_id = p_objet_id AND NOT mb.mineur
    -- Dossier (identifiant = profil du titulaire du dossier) : enseignant
    -- ou foyer du tuteur, avec l'Administration.
    UNION
    SELECT CASE p.role WHEN 'teacher' THEN 'profil' ELSE 'foyer' END,
           CASE p.role WHEN 'teacher' THEN p.id ELSE p.household_id END,
           'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'dossier' AND p.id = p_objet_id AND p.deleted_at IS NULL
        AND p.role IN ('teacher', 'guardian')
    -- Remplacement : titulaire et remplacant, chacun avec l'Administration.
    UNION
    SELECT 'profil', x.enseignant_id, 'equipe', NULL
      FROM public.remplacements_seance r
      CROSS JOIN LATERAL (VALUES (r.enseignant_titulaire_id), (r.enseignant_remplacant_id))
        AS x(enseignant_id)
      WHERE p_type = 'remplacement' AND r.id = p_objet_id AND x.enseignant_id IS NOT NULL
    -- Profil de paiement (CPT-BR-11) : le beneficiaire enseignant et l'equipe.
    UNION
    SELECT 'profil', p.id, 'equipe', NULL
      FROM public.profiles p
      WHERE p_type = 'profilPaiement' AND p.id = p_objet_id AND p.role = 'teacher'
    -- Candidature (MESSAGES-CANDIDAT) : le candidat enseignant et l'equipe,
    -- tant que la candidature est en cours, hors pause, avant la salle des
    -- prets ; lisible par le candidat ou par la direction de son cote.
    UNION
    SELECT 'profil', cd.profile_id, 'equipe', NULL
      FROM public.candidatures cd
      WHERE p_type = 'candidature' AND cd.id = p_objet_id
        AND cd.type_code = 'enseignant' AND cd.profile_id IS NOT NULL
        AND cd.issue = 'en_cours' AND NOT cd.en_pause AND cd.etape <> 'confirmee'
        AND private.com_candidature_lisible(cd.id, auth.uid())
  )
  SELECT c.a_nature, c.a_id, c.b_nature, c.b_id
  FROM cibles c
  WHERE c.a_id IS NOT NULL
    AND (p_type = 'candidature' OR (CASE c.a_nature
          WHEN 'foyer' THEN private.com_foyer_valide(c.a_id)
          ELSE private.com_profil_valide(c.a_id, NULL) AND NOT private.com_est_mineur(c.a_id)
        END
    AND (c.b_nature = 'equipe'
         OR (private.com_profil_valide(c.b_id, 'teacher') AND c.b_id <> c.a_id))
    -- Lot (B), 02/11/2026 : avec l'enseignant, seulement si un eleve concerne
    -- (l'adulte lui-meme, ou un eleve du foyer dans cette Classe ou cet eleve)
    -- a un acces paye.
    AND (c.b_nature = 'equipe'
         OR (c.a_nature = 'profil' AND private.acces_paye(c.a_id))
         OR (c.a_nature = 'foyer' AND EXISTS (
               SELECT 1 FROM membres mb
                WHERE mb.household_id = c.a_id
                  AND ((p_type = 'classe' AND mb.groupe_id = p_objet_id)
                       OR (p_type = 'eleve' AND mb.eleve_id = p_objet_id))
                  AND private.acces_paye(mb.eleve_id))))));
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_candidature_lisible(p_candidature uuid, p_moi uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(EXISTS (
    SELECT 1 FROM public.candidatures c
     WHERE c.id = p_candidature
       AND c.type_code = 'enseignant'
       AND (c.profile_id = p_moi
            OR (EXISTS (SELECT 1 FROM public.profiles a
                         WHERE a.id = p_moi AND a.role = 'admin'
                           AND a.account_status = 'active' AND a.deleted_at IS NULL)
                AND private.entretien_cote_permis(p_moi, c.genre)))), false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_est_partie(p_moi uuid, p_role text, p_foyer uuid, p_type text, p_nature text, p_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(CASE p_nature
    WHEN 'profil' THEN p_id = p_moi
    WHEN 'foyer' THEN p_role = 'guardian' AND p_foyer IS NOT NULL AND p_id = p_foyer
    WHEN 'equipe' THEN p_role = 'admin'
                    OR (p_role = 'accountant' AND p_type = 'profilPaiement')
    ELSE false END, false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.entretien_cote_permis(p_profil uuid, p_genre public.gender)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(
    EXISTS (SELECT 1 FROM public.profiles p
             WHERE p.id = p_profil AND p.gender = p_genre)
    OR (EXISTS (SELECT 1 FROM private.super_admin_kyc s WHERE s.profile_id = p_profil)
        AND EXISTS (SELECT 1 FROM public.app_config c
                     WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb)),
    false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.praxis_est_officiel(p_profil uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(EXISTS (SELECT 1 FROM private.comptes_officiels o WHERE o.profile_id = p_profil), false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_profil_valide(p_profile_id uuid, p_role text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = p_profile_id
      AND (p_role IS NULL OR p.role::text = p_role)
      AND p.deleted_at IS NULL
      AND p.account_status IN ('active', 'provisional_active')
      AND (p.access_until IS NULL OR p.access_until > pg_catalog.clock_timestamp()))
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_est_mineur(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(
    (SELECT sp.student_type = 'minor' FROM public.student_profiles sp
      WHERE sp.profile_id = p_profile_id AND sp.deleted_at IS NULL),
    (SELECT p.role = 'student' FROM public.profiles p WHERE p.id = p_profile_id),
    true)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION private.com_foyer_valide(p_foyer_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT EXISTS (
    SELECT 1 FROM public.households h
    JOIN public.profiles g ON g.household_id = h.id AND g.role = 'guardian'
    WHERE h.id = p_foyer_id AND h.status = 'active' AND h.deleted_at IS NULL
      AND private.com_profil_valide(g.id, 'guardian'))
  );
END;
$function$;

CREATE OR REPLACE FUNCTION app_private.compte_candidat_hors_portee(p_profile_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(
    p_profile_id IS NOT NULL
    AND public.app_role() = 'admin'
    -- La plupart des comptes ne portent aucune candidature : ce test d'abord.
    AND EXISTS (
      SELECT 1
      FROM public.candidatures c
      WHERE c.profile_id = p_profile_id
        AND c.etape <> 'confirmee'
        AND c.genre IS DISTINCT FROM (
          SELECT p.gender FROM public.profiles p
          WHERE p.id = auth.uid() AND p.deleted_at IS NULL))
    AND NOT public.kyc_super_admin_exception_active(),
    false)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.kyc_super_admin_exception_active()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN (
  SELECT coalesce(
    public.app_role() = 'admin'
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.deleted_at IS NULL
    )
    AND EXISTS (
      SELECT 1 FROM private.super_admin_kyc s
      WHERE s.profile_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.app_config c
      WHERE c.key = 'kyc_exception_super_admin' AND c.value = 'true'::jsonb
    ), false
  )
  );
END;
$function$;


-- 3. Les non-lus seuls, aux droits de com_lister_fils.
-- La visibilite et le compte sont ceux de private.com_fil_json (corps 3002018f...), recopies a l'identique : NULL pour
-- un fil que com_fil_json ne rendrait pas.
CREATE FUNCTION private.com_fil_non_lus(p_fil_id uuid, p_moi uuid, p_role text, p_foyer uuid)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
DECLARE
  f public.com_fils%ROWTYPE;
  v_soi_a boolean;
  v_soi_b boolean;
  v_autorisee boolean;
  v_lu timestamptz;
BEGIN
  SELECT * INTO f FROM public.com_fils x WHERE x.id = p_fil_id;
  IF NOT FOUND THEN RETURN NULL; END IF;
  v_soi_a := private.com_est_partie(p_moi, p_role, p_foyer, f.type_objet, f.partie_a_nature, f.partie_a_id);
  v_soi_b := private.com_est_partie(p_moi, p_role, p_foyer, f.type_objet, f.partie_b_nature, f.partie_b_id);
  IF NOT (v_soi_a OR v_soi_b) THEN RETURN NULL; END IF;
  IF f.type_objet <> 'candidature' AND NOT private.com_profil_valide(p_moi, NULL) THEN
    RETURN NULL;
  END IF;
  IF f.type_objet = 'candidature' AND NOT private.com_candidature_lisible(f.objet_id, p_moi) THEN
    RETURN NULL;
  END IF;
  v_autorisee := EXISTS (
    SELECT 1 FROM private.com_paires(f.type_objet, f.objet_id) q
    WHERE q.a_nature = f.partie_a_nature AND q.a_id = f.partie_a_id
      AND q.b_nature = f.partie_b_nature AND q.b_id IS NOT DISTINCT FROM f.partie_b_id);
  IF NOT (v_autorisee OR v_soi_a OR f.partie_b_nature = 'equipe') THEN RETURN NULL; END IF;
  SELECT l.lu_jusqu_au INTO v_lu FROM public.com_lectures l
    WHERE l.fil_id = f.id AND l.profile_id = p_moi;
  RETURN (SELECT pg_catalog.count(*) FROM public.com_messages m
                 WHERE m.fil_id = f.id AND m.auteur_id <> p_moi AND NOT EXISTS (SELECT 1 FROM public.com_message_images ix WHERE ix.message_id = m.id AND ((ix.etat = 'en_attente' AND ix.auteur <> p_moi) OR (ix.etat = 'supprimee' AND ix.confirmee_le IS NULL))) AND NOT (pg_catalog.btrim(m.texte) = '[image]' AND NOT EXISTS (SELECT 1 FROM public.com_message_images iy WHERE iy.message_id = m.id))
                   AND m.envoye_le > coalesce(v_lu, '-infinity'::timestamptz))::integer;
END;
$function$;

REVOKE ALL ON FUNCTION private.com_fil_non_lus(uuid, uuid, text, uuid) FROM PUBLIC, anon, authenticated;

-- Les fils de l'appelant qui ont des non-lus, du plus recent au plus ancien (l'ordre de com_lister_fils) :
-- [{"fil": id, "type": type_objet, "objet": objet_id, "non_lus": n}, ...]. Un fil sans non-lus n'a pas de ligne.
CREATE FUNCTION public.com_non_lus_par_objet()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  moi record;
  v_resultat jsonb;
BEGIN
  SELECT * INTO moi FROM private.com_appelant_msg();
  IF moi.id IS NULL THEN
    RAISE EXCEPTION 'COM-BACK-1 non autorise' USING ERRCODE = '42501';
  END IF;
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'fil', x.id, 'type', x.type_objet, 'objet', x.objet_id, 'non_lus', x.n)
           ORDER BY x.activite DESC, x.id DESC), '[]'::jsonb)
    INTO v_resultat
  FROM (
    SELECT f.id, f.type_objet, f.objet_id, coalesce(f.dernier_message_le, f.cree_le) AS activite,
           private.com_fil_non_lus(f.id, moi.id, moi.role, moi.foyer) AS n
    FROM public.com_fils f
    WHERE private.com_est_partie(moi.id, moi.role, moi.foyer, f.type_objet, f.partie_a_nature, f.partie_a_id)
       OR private.com_est_partie(moi.id, moi.role, moi.foyer, f.type_objet, f.partie_b_nature, f.partie_b_id)
    OFFSET 0
  ) x
  WHERE x.n > 0;
  RETURN v_resultat;
END;
$function$;

REVOKE ALL ON FUNCTION public.com_non_lus_par_objet() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.com_non_lus_par_objet() TO authenticated;

-- Controle final : tout est en place, rien d'autre n'a bouge.
DO $controle$
DECLARE
  v record;
  v_role text;
BEGIN
  FOR v IN SELECT * FROM (VALUES
      ('private.com_participant(text,uuid,text,uuid)', false, '{postgres=X/postgres}'),
      ('private.com_objet(text,uuid)', false, '{postgres=X/postgres}'),
      ('private.com_paires(text,uuid)', false, '{postgres=X/postgres}'),
      ('private.com_candidature_lisible(uuid,uuid)', false, '{postgres=X/postgres}'),
      ('private.com_est_partie(uuid,text,uuid,text,text,uuid)', false, '{postgres=X/postgres}'),
      ('private.entretien_cote_permis(uuid,public.gender)', true, '{postgres=X/postgres}'),
      ('private.praxis_est_officiel(uuid)', false, '{postgres=X/postgres}'),
      ('private.com_profil_valide(uuid,text)', false, '{postgres=X/postgres}'),
      ('private.com_est_mineur(uuid)', false, '{postgres=X/postgres}'),
      ('private.com_foyer_valide(uuid)', false, '{postgres=X/postgres}'),
      ('app_private.compte_candidat_hors_portee(uuid)', true, '{postgres=X/postgres,authenticated=X/postgres,agent_ro=X/postgres}'),
      ('public.kyc_super_admin_exception_active()', true, '{postgres=X/postgres,service_role=X/postgres}'),
      ('private.com_fil_non_lus(uuid,uuid,text,uuid)', false, '{postgres=X/postgres}')) AS t(f, definer, acl) LOOP
    IF NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_proc p JOIN pg_catalog.pg_language l ON l.oid = p.prolang
          WHERE p.oid = pg_catalog.to_regprocedure(v.f)
            AND l.lanname = 'plpgsql' AND p.provolatile = 's' AND p.prosecdef = v.definer
            AND p.proowner = 'postgres'::regrole
            AND p.proconfig = ARRAY['search_path=""']
            AND p.proacl::text = v.acl) THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % : plpgsql, STABLE, securite, proprietaire, search_path vide ou droits inattendus', v.f;
    END IF;
  END LOOP;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated'] LOOP
    IF has_function_privilege(v_role, 'private.com_fil_non_lus(uuid,uuid,text,uuid)', 'EXECUTE') THEN
      RAISE EXCEPTION 'PERSONNES-PERF : % peut executer private.com_fil_non_lus', v_role;
    END IF;
  END LOOP;
  IF has_function_privilege('anon', 'public.com_non_lus_par_objet()', 'EXECUTE')
     OR NOT has_function_privilege('authenticated', 'public.com_non_lus_par_objet()', 'EXECUTE') THEN
    RAISE EXCEPTION 'PERSONNES-PERF : droits de com_non_lus_par_objet inattendus';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_proc p
                  WHERE p.oid = pg_catalog.to_regprocedure('public.com_non_lus_par_objet()')
                    AND p.prosecdef AND p.provolatile = 's' AND p.proowner = 'postgres'::regrole
                    AND p.proconfig = ARRAY['search_path=""']) THEN
    RAISE EXCEPTION 'PERSONNES-PERF : com_non_lus_par_objet : DEFINER, STABLE, postgres, search_path vide attendus';
  END IF;
  IF pg_catalog.to_regclass('public.kyc_documents_profil_recent_idx') IS NULL
     OR pg_catalog.to_regclass('public.profiles_foyer_idx') IS NULL THEN
    RAISE EXCEPTION 'PERSONNES-PERF : index absent';
  END IF;
  IF (SELECT pg_catalog.md5(p.prosrc) FROM pg_catalog.pg_proc p
       WHERE p.oid = pg_catalog.to_regprocedure('private.com_fil_json(uuid,uuid,text,uuid)'))
     IS DISTINCT FROM '3002018f5fa3b207660bf515d959e92f' THEN
    RAISE EXCEPTION 'PERSONNES-PERF : com_fil_json ne doit pas changer';
  END IF;
END
$controle$;
