-- CAND-L1B (21/10/2026) : forme en base du compte candidat, complement de
-- CAND-L1 avant L2 (spec consolidee, section 3.1 condition 1, section 0.3
-- derniere ligne, section 11 ligne L1 : "si L1 est livre sans la forme du
-- compte, un complement de L1 la fixe avant L2").
--
-- Decision (sans question au directeur, spec 0.3) : le compte candidat est un
-- profil de role 'teacher' au statut 'pending_kyc', avec une fiche
-- teacher_profiles vide, le MEME pour le lien public (L3) et pour
-- l'invitation. C'est exactement ce que fabrique aujourd'hui la seule porte,
-- private.creer_profil_inscription_interne('teacher', ...) appelee par
-- inscrire_enseignant_invite (20261017150200_af_l1_11, l. 61-64 et 80, appel
-- l. 169) ; L3 fera passer le lien public par la meme fabrique.
--
-- Pourquoi garder 'teacher' + 'pending_kyc' plutot qu'un role ou un statut
-- neuf :
-- * le confinement existe deja et repose sur le statut, pas sur le role :
--   app_account_valid() n'admet que active et provisional_active
--   (0001_fondations.sql, l. 412-422), et chaque porte de travail l'exige
--   (jeton de cours, affectation, prerequis, listes d'enseignants, messagerie,
--   bibliotheque) ;
-- * les trois portes que le candidat DOIT franchir sont deja ouvertes au role
--   teacher en attente : depot de piece (kyc_staff_self_insert, 0004 l. 169-174,
--   puis af_l1_08 l. 226 et 20261017120100 l. 168), contrat et avis
--   (contract_acceptances_self_insert, af_l1_08 l. 234), code de conduite
--   (20261021210400, l. 54-70) ; et la garde d'activation 0089
--   (NEW.role = 'teacher') joue a l'activation ;
-- * un role neuf ('candidate') obligerait a rouvrir chacune de ces policies, le
--   crochet du jeton, le routeur et la garde 0089, puis a changer le role (une
--   colonne privilegiee) a l'entree en salle 3 ; un statut neuf toucherait
--   app_account_valid() et les 176 fichiers de migration qui le lisaient au
--   21/10. Plus de surface, pour le meme confinement.
--
-- Ce que le releve des lecteurs de teacher_profiles et de role = 'teacher'
-- (toutes les fonctions, vues et policies de la base rejouee) a trouve, et ce
-- que ce lot corrige :
-- * F1 maj_profil_enseignant (0027) n'exige ni role ni compte valide : un
--   compte en attente ecrit pays, langues et fuseau de teacher_profiles, qui
--   sont des prerequis de travail (20261016100500, l. 49-74) poses apres la
--   salle 3 (spec 2.1, 2.2). Correction : garde positive teacher et compte
--   valide (section 6) ;
-- * F2 peut_deposer_piece_identite (0034, l. 274-303), porte du depot R2
--   (supabase/functions/piece-identite-depot), exige app_account_valid() alors
--   que kyc_staff_self_insert admet le compte en attente depuis af_l1_08 : un
--   enseignant invite avant le module ne pouvait pas deposer sa piece par le
--   coffre. Correction : la branche du depot pour soi suit la policy, et toute
--   voie respecte l'etape de la candidature (section 5) ;
-- * F3 un depot pour soi par la policy portait n'importe quel status : un
--   candidat inserait sa piece deja 'approved', avec verified_at, et
--   etat_dossier() la disait approuvee. Correction : un depot d'un compte
--   client n'est jamais une decision (section 5) ;
-- * F4 rien ne liait la candidature a la forme du compte : une candidature
--   enseignant se rattachait a un tuteur, et decider_dossier() activait un
--   candidat avant la salle 3. Correction : le type porte le role du compte
--   (role_compte), et avant la Salle des prets a enseigner le compte rattache
--   n'est ni active ni provisional_active (section 2). La regle est un
--   declencheur de contrainte des deux cotes, DEFERRABLE INITIALLY IMMEDIATE :
--   une CHECK ne lit pas profiles et ne se rejoue pas quand le profil change ;
--   une cle etrangere composee (profile_id, role) vers profiles(id, role)
--   demanderait une unicite neuve sur profiles et une colonne recopiee, sans
--   couvrir le statut. L2 peut differer la verification dans la transaction
--   d'entree en salle 3 (SET CONSTRAINTS ... DEFERRED) ;
-- * F5 defense en profondeur : une ecriture directe (direction par
--   sessions_admin_all, ou cle de service) posait un compte candidat en
--   enseignant d'une classe, d'une seance de cours, d'une affectation ou d'un
--   remplacement, sans passer par aucun predicat. Correction : refus en base
--   tant que la candidature n'est pas en Salle des prets a enseigner, des deux
--   cotes (section 3). Les seances 'entretien' de L4 ne sont pas touchees : le
--   declencheur ne joue que sur les types de cours existants.
--
-- Reprise apres relecture (21/10, soir) :
-- * R1 ecriture biaisee : les deux cotes lisaient l'autre sans verrou (le
--   rattachement ne prend que le FOR KEY SHARE de la cle etrangere, qui ne gene
--   pas l'activation) ; deux transactions validaient un compte actif avant la
--   salle 3. Le cote candidature verrouille la ligne du compte FOR NO KEY
--   UPDATE, le cote affectation FOR SHARE : la seconde transaction attend la
--   premiere, puis relit et refuse. Preuve a deux sessions :
--   supabase/tests/scenarios_cand_l1b_concurrence.sql ;
-- * R2 F5 cote candidature : rattacher une candidature a un compte qui
--   enseigne deja, ou ramener avant la salle 3 une candidature dont le compte
--   enseigne, est refuse (compte_candidat_non_affectable). "Enseigne" veut
--   dire un engagement EN COURS (classe non close, seance de cours a venir ou
--   en cours, affectation ouverte, remplacement d'une telle seance) : un
--   historique (classe close, seance passee, journal en ajout seul) ne
--   s'efface pas et n'interdit pas a une ancienne enseignante de candidater ;
-- * R3 la regle du role ne vaut que pour une candidature en cours avant la
--   salle 3 ; celle du statut, pour un compte du role du type. Une enseignante
--   confirmee, ou une personne dont la candidature est refusee ou retiree,
--   change de role comme tout compte (DECISION-IMMATRICULATION-2026-10-12,
--   l. 23) ; rouvrir la candidature rejoue la regle du role (issue surveillee) ;
-- * R4 cloisonnement par genre des comptes candidats (CAND-Q07, DEC:30, spec
--   8.2) : la direction de l'autre cote ne lit plus un compte qui porte une
--   candidature avant la salle 3, ni dans comptes_admin() (ADM-08), ni dans
--   dossiers_en_attente() (ADM-02), ni dans le compteur d'indicateurs_admin()
--   (ADM-01), ni dans profiles (policy restrictive) ; meme regle que CAND-L1
--   (genre du lecteur lu en base, inconnu = hors portee, exception
--   super-admin de 0088). Une ecriture de la direction de l'autre cote sur ce
--   profil touche 0 ligne : plus de message qui revele la candidature ;
-- * R5 la file d'ADM-02 ne montre un compte candidat qu'en Salle de
--   verification et d'entretien (en cours) ou apres : la salle d'examen se
--   suit dans ADM-20 et ADM-21 (spec 2.2) ;
-- * R6 la piece d'un compte candidat ne se depose qu'en Salle de verification
--   et d'entretien (en cours) ou apres (spec 2.1), par toute voie : porte R2,
--   policy, cle de service ;
-- * R7 comptes_admin() sert ADM-08 (registre des comptes), pas ADM-02 ;
-- * R8 peut_deposer_piece_identite, comptes_admin et indicateurs_admin
--   suivent l'idiome F86 : authenticated seul (aucun appelant service_role ni
--   agent_ro : la fonction Edge appelle la porte sous le jeton de
--   l'appelant, _shared/r2/client_appelant.ts l. 51-57) ;
-- * R9 le scenario couvre chaque branche declaree des declencheurs.
--
-- Deja tenu, prouve par le scenario sans rien changer : jeton de cours
-- (autoriser_jeton_video, 20261017110100 l. 44-52) ; affectation
-- (app_private.verifier_affectation_enseignant, 20261021210200 l. 105 ;
-- tc_verifier_affectation_enseignant ; creer_groupe l. 338 ;
-- affecter_enseignant_classe_c11bis ; attribuer_eleve, 20261012100800 l. 57 ;
-- prendre_eleve, 20261012121000 l. 18 ; remplacement_enseignant_compatible,
-- 20261011185954 l. 59) ; prerequis (prerequis_enseignant, 20261016100500
-- l. 59 ; weekly_availability_write, 0005 l. 463-465 ; photos_enseignants,
-- 20261017110900 l. 33-44) ; listes (enseignants_pour, 20261011225032 l. 102 ;
-- enseignants_pour_classe, 0083 l. 106 ; enseignants_pour_public,
-- 20261016100900 l. 96 ; candidats_cible_tirage ; pilotage_admin_page ;
-- personnes_observables ; offres_remplacement ; notification des
-- remplacements ; vues et recherche de la famille, qui passent par
-- groupes.teacher_id) ; colonnes privilegiees du profil
-- (guard_profile_privileged_columns, 20261017100700 l. 10).
--
-- Deux candidatures ouvertes du meme type pour un compte : deja refusees par
-- CAND-L1 (candidatures_type_profil_unique, UNIQUE (type_code, profile_id)),
-- plus strict encore (une seule candidature par type et par compte, rouverte
-- par geste en L2) ; le scenario le prouve, rien n'est ajoute.
--
-- Hors de ce lot (a trancher ailleurs, spec 0.3 et 11) : l'etape a laquelle
-- chaque accord est permis (L2, apres la reponse du directeur sur les accords
-- en trois moments) ; les autres surfaces de la direction qui nomment un
-- compte (journal_audit, demandes_suppression_lister, jetons_agent_actifs, et
-- le message d'une affectation directe refusee, qui suppose l'identifiant
-- connu) : L2 ; le depot R2 d'un tuteur en attente, que kyc_guardian_insert
-- admet et que peut_deposer_piece_identite refuse encore (hors module,
-- inchange) ; purge_at fourni par le client a l'insertion d'une piece
-- (CAND-Q21, conservation).
BEGIN;

-- ============================================================
-- 1. Le type porte le role du compte candidat
-- ============================================================

ALTER TABLE public.candidature_types ADD COLUMN role_compte public.app_role;
UPDATE public.candidature_types SET role_compte = 'teacher' WHERE code = 'enseignant';
ALTER TABLE public.candidature_types ALTER COLUMN role_compte SET NOT NULL;
COMMENT ON COLUMN public.candidature_types.role_compte IS
  'CAND-L1B : role du compte rattache a une candidature de ce type (enseignant : teacher). '
  'Un type neuf le declare ; verifie par private.candidature_compte_conforme().';

-- ============================================================
-- 2. Forme du compte rattache a une candidature
-- ============================================================

-- Un engagement EN COURS d'enseignant (R2) : classe non close, seance de cours
-- a venir ou en cours, affectation ouverte, remplacement sur une telle seance.
-- L'historique ne compte pas : il ne s'efface pas.
CREATE FUNCTION private.candidat_engagement_en_cours(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT EXISTS (
           SELECT 1 FROM public.groupes g
           WHERE g.teacher_id = p_profile_id AND g.ended_at IS NULL)
      OR EXISTS (
           SELECT 1 FROM public.sessions s
           WHERE s.teacher_id = p_profile_id
             AND s.session_type IN ('standard', 'child')
             AND s.deleted_at IS NULL
             AND s.status IN ('planned', 'preflight', 'in_progress'))
      OR EXISTS (
           SELECT 1 FROM public.teacher_student_assignments a
           WHERE a.teacher_id = p_profile_id AND a.ended_at IS NULL)
      OR EXISTS (
           SELECT 1 FROM public.remplacements_seance r
           JOIN public.sessions s ON s.id = r.session_id
           WHERE r.enseignant_remplacant_id = p_profile_id
             AND s.deleted_at IS NULL
             AND s.status IN ('planned', 'preflight', 'in_progress'));
$function$;

-- La regle, en un seul endroit, lue des deux cotes. Messages stables,
-- lisibles par L2.
-- * role : une candidature en cours (issue en_cours) avant la Salle des prets
--   a enseigner se rattache a un compte du role de son type (R3) ;
-- * statut : avant la salle 3, un compte du role du type n'est ni active ni
--   provisional_active, quelle que soit l'issue (une candidature refusee ou
--   retiree ne fait pas un enseignant) ;
-- * engagement : avant la salle 3, quelle que soit l'issue, le compte n'a
--   aucun engagement d'enseignant en cours (R2).
-- Tout est lu dans l'etat courant des tables, jamais dans la ligne qui a
-- declenche : le resultat est le meme quand la verification est differee.
CREATE FUNCTION private.candidature_compte_conforme(p_profile_id uuid)
RETURNS void
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_role public.app_role;
  v_statut public.account_status;
BEGIN
  IF p_profile_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM public.candidatures c WHERE c.profile_id = p_profile_id
  ) THEN
    RETURN;
  END IF;
  SELECT p.role, p.account_status INTO v_role, v_statut
  FROM public.profiles p
  WHERE p.id = p_profile_id;
  IF NOT FOUND THEN
    -- La cle etrangere de candidatures.profile_id refuse deja un compte absent.
    RETURN;
  END IF;
  IF EXISTS (
    SELECT 1
    FROM public.candidatures c
    JOIN public.candidature_types t ON t.code = c.type_code
    WHERE c.profile_id = p_profile_id
      AND c.issue = 'en_cours'
      AND c.etape <> 'confirmee'
      AND t.role_compte IS DISTINCT FROM v_role
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'compte_candidat_role_du_type',
      DETAIL = 'CAND-L1B : une candidature en cours avant la Salle des prets a enseigner se rattache a un compte du role de son type (enseignant : teacher).';
  END IF;
  IF v_statut IN ('active', 'provisional_active') AND EXISTS (
    SELECT 1
    FROM public.candidatures c
    JOIN public.candidature_types t ON t.code = c.type_code
    WHERE c.profile_id = p_profile_id
      AND c.etape <> 'confirmee'
      AND t.role_compte = v_role
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'compte_candidat_actif_avant_salle_3',
      DETAIL = 'CAND-L1B : avant la Salle des prets a enseigner, le compte candidat reste pending_kyc (ni active ni provisional_active).';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.candidatures c
    WHERE c.profile_id = p_profile_id AND c.etape <> 'confirmee'
  ) AND private.candidat_engagement_en_cours(p_profile_id) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'compte_candidat_non_affectable',
      DETAIL = 'CAND-L1B : un compte candidat n''est l''enseignant d''aucune classe, seance de cours, affectation ni remplacement en cours avant la Salle des prets a enseigner.';
  END IF;
END;
$function$;

-- Cote candidature (R1) : la ligne du compte est verrouillee FOR NO KEY
-- UPDATE avant la lecture. Une activation, un changement de role ou une
-- affectation concurrente (FOR SHARE, section 3) attend la validation de
-- cette transaction, ou cette transaction attend la leur, puis relit
-- (nouvel instantane a chaque instruction en READ COMMITTED).
CREATE FUNCTION private.candidature_forme_compte_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM 1 FROM public.profiles p WHERE p.id = NEW.profile_id FOR NO KEY UPDATE;
  PERFORM private.candidature_compte_conforme(NEW.profile_id);
  RETURN NULL;
END;
$function$;

-- Cote compte : l'UPDATE tient deja le verrou de sa ligne, qui entre en
-- conflit avec celui du cote candidature.
CREATE FUNCTION private.profil_forme_compte_candidat_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  PERFORM private.candidature_compte_conforme(NEW.id);
  RETURN NULL;
END;
$function$;

-- Cote candidature : a la creation, au rattachement, au changement d'etape,
-- de type ou d'issue (rouvrir rejoue la regle du role).
CREATE CONSTRAINT TRIGGER candidatures_forme_compte
  AFTER INSERT OR UPDATE OF profile_id, etape, type_code, issue ON public.candidatures
  DEFERRABLE INITIALLY IMMEDIATE
  FOR EACH ROW
  WHEN (NEW.profile_id IS NOT NULL)
  EXECUTE FUNCTION private.candidature_forme_compte_trg();

-- Cote compte : changement de role ou de statut, par toute voie
-- (decider_dossier, direction par profiles_admin_all, cle de service).
CREATE CONSTRAINT TRIGGER profiles_forme_compte_candidat
  AFTER UPDATE OF role, account_status ON public.profiles
  DEFERRABLE INITIALLY IMMEDIATE
  FOR EACH ROW
  WHEN (OLD.role IS DISTINCT FROM NEW.role OR OLD.account_status IS DISTINCT FROM NEW.account_status)
  EXECUTE FUNCTION private.profil_forme_compte_candidat_trg();

-- ============================================================
-- 3. Un compte candidat n'enseigne a personne (defense en profondeur)
-- ============================================================

-- La colonne qui designe l'enseignant est passee en argument du declencheur
-- (teacher_id, ou enseignant_remplacant_id pour un remplacement). La ligne du
-- compte est verrouillee FOR SHARE (R1) : deux affectations ne se genent pas,
-- un rattachement de candidature concurrent (FOR NO KEY UPDATE) attend.
CREATE FUNCTION private.candidat_non_affectable_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_enseignant uuid;
BEGIN
  v_enseignant := (pg_catalog.to_jsonb(NEW) ->> TG_ARGV[0])::uuid;
  IF v_enseignant IS NULL THEN
    RETURN NEW;
  END IF;
  PERFORM 1 FROM public.profiles p WHERE p.id = v_enseignant FOR SHARE;
  IF EXISTS (
    SELECT 1
    FROM public.candidatures c
    WHERE c.profile_id = v_enseignant
      AND c.etape <> 'confirmee'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23514',
      MESSAGE = 'compte_candidat_non_affectable',
      DETAIL = 'CAND-L1B : un compte candidat n''est l''enseignant d''aucune classe, seance de cours, affectation ni remplacement avant la Salle des prets a enseigner.';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER groupes_candidat_non_affectable
  BEFORE INSERT OR UPDATE OF teacher_id ON public.groupes
  FOR EACH ROW
  WHEN (NEW.teacher_id IS NOT NULL)
  EXECUTE FUNCTION private.candidat_non_affectable_trg('teacher_id');

-- Seances de cours seulement : la seance 'entretien' de L4 fixera sa propre
-- forme de teacher_id (spec 6.1, 0.3).
CREATE TRIGGER sessions_candidat_non_affectable
  BEFORE INSERT OR UPDATE OF teacher_id, session_type ON public.sessions
  FOR EACH ROW
  WHEN (NEW.teacher_id IS NOT NULL AND NEW.session_type IN ('standard', 'child'))
  EXECUTE FUNCTION private.candidat_non_affectable_trg('teacher_id');

CREATE TRIGGER teacher_student_assignments_candidat_non_affectable
  BEFORE INSERT OR UPDATE OF teacher_id ON public.teacher_student_assignments
  FOR EACH ROW
  WHEN (NEW.teacher_id IS NOT NULL)
  EXECUTE FUNCTION private.candidat_non_affectable_trg('teacher_id');

-- Le journal des remplacements est en ajout seul (remplacements_seance_no_update).
CREATE TRIGGER remplacements_seance_candidat_non_affectable
  BEFORE INSERT ON public.remplacements_seance
  FOR EACH ROW
  WHEN (NEW.enseignant_remplacant_id IS NOT NULL)
  EXECUTE FUNCTION private.candidat_non_affectable_trg('enseignant_remplacant_id');

-- ============================================================
-- 4. Cloisonnement par genre des comptes candidats (R4)
-- ============================================================

-- Vrai quand l'appelant est la direction, hors exception super-admin (0088),
-- et que le compte porte une candidature avant la salle 3 de l'autre cote que
-- le sien ; un lecteur au genre inconnu n'a aucun cote (comme
-- private.cand_lecteur de CAND-L1). Le genre de la candidature est celui du
-- compte (C8 de CAND-L1). Dans app_private, non expose par PostgREST, pour
-- qu'une policy l'appelle (motif de app_private.peut_lire_groupe, 0073).
CREATE FUNCTION app_private.compte_candidat_hors_portee(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
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
    false);
$function$;

ALTER FUNCTION app_private.compte_candidat_hors_portee(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION app_private.compte_candidat_hors_portee(uuid)
  FROM PUBLIC, anon, service_role;
-- Les deux roles que la policy ci-dessous vise ; agent_ro lit profiles par
-- profiles_agent_select sous le jeton de la personne observee (0014).
GRANT EXECUTE ON FUNCTION app_private.compte_candidat_hors_portee(uuid) TO authenticated, agent_ro;
COMMENT ON FUNCTION app_private.compte_candidat_hors_portee(uuid) IS
  'CAND-L1B : compte portant une candidature avant la salle 3, de l autre cote que la direction qui lit '
  '(genre inconnu = hors portee, exception super-admin de 0088). Lu par la policy restrictive de profiles, '
  'comptes_admin, dossiers_en_attente et indicateurs_admin.';

-- La direction de l'autre cote ne lit ni n'ecrit la ligne : une ecriture
-- touche 0 ligne, sans message qui revele la candidature. Restrictive : elle
-- borne profiles_admin_all et profiles_agent_select sans rien ouvrir. Les
-- autres comptes ne sont pas touches (app_role() lu une fois).
CREATE POLICY profiles_compte_candidat_portee
  ON public.profiles
  AS RESTRICTIVE
  FOR ALL
  TO authenticated, agent_ro
  USING ((SELECT public.app_role()) IS DISTINCT FROM 'admin'::public.app_role
         OR NOT app_private.compte_candidat_hors_portee(id));

-- ============================================================
-- 5. La piece : jamais une decision, jamais hors etape
-- ============================================================

-- La piece d'un compte candidat se depose en Salle de verification et
-- d'entretien (candidature en cours) ou apres (spec 2.1 ; R6) ; un compte
-- sans candidature n'est pas touche. Lu par la porte R2, par le declencheur
-- du depot (toute voie) et par la file d'ADM-02 (R5).
CREATE FUNCTION private.candidature_permet_depot_piece(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT NOT EXISTS (
    SELECT 1
    FROM public.candidatures c
    WHERE c.profile_id = p_profile_id
      AND NOT (c.etape = 'confirmee'
               OR (c.etape = 'verifications' AND c.issue = 'en_cours')));
$function$;

CREATE FUNCTION private.kyc_depot_etape_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.candidature_permet_depot_piece(NEW.profile_id) THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'depot_piece_hors_etape',
      DETAIL = 'CAND-L1B : la piece d''un compte candidat se depose en Salle de verification et d''entretien (candidature en cours) ou apres ; jamais en Salle d''examen, ni apres un refus ou un retrait.';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER kyc_documents_depot_etape
  BEFORE INSERT ON public.kyc_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.kyc_depot_etape_trg();

-- SECURITY INVOKER a dessein : current_user est le role de l'appelant. Une
-- insertion par une RPC DEFINER (preparer_depot_piece_identite, proprietaire
-- postgres) ou par la cle de service n'est pas touchee ; un compte client
-- (kyc_staff_self_insert, kyc_guardian_insert) ne pose ni status autre que
-- pending, ni verificateur, ni date de verification, ni motif de refus. Seule
-- decider_dossier() decide.
CREATE FUNCTION private.kyc_depot_sans_decision_trg()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NOT (
    current_user IN ('postgres', 'service_role', 'supabase_admin')
    OR (NEW.status = 'pending'
        AND NEW.verified_by IS NULL
        AND NEW.verified_at IS NULL
        AND NEW.rejection_reason IS NULL)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'depot_piece_sans_decision',
      DETAIL = 'CAND-L1B : un depot de piece nait pending, sans verificateur, date de verification ni motif ; seule decider_dossier() decide.';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER kyc_documents_depot_sans_decision
  BEFORE INSERT ON public.kyc_documents
  FOR EACH ROW
  EXECUTE FUNCTION private.kyc_depot_sans_decision_trg();

REVOKE ALL ON FUNCTION private.candidat_engagement_en_cours(uuid),
  private.candidature_compte_conforme(uuid),
  private.candidature_forme_compte_trg(), private.profil_forme_compte_candidat_trg(),
  private.candidat_non_affectable_trg(), private.candidature_permet_depot_piece(uuid),
  private.kyc_depot_etape_trg(), private.kyc_depot_sans_decision_trg()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
ALTER FUNCTION private.candidat_engagement_en_cours(uuid) OWNER TO postgres;
ALTER FUNCTION private.candidature_compte_conforme(uuid) OWNER TO postgres;
ALTER FUNCTION private.candidature_forme_compte_trg() OWNER TO postgres;
ALTER FUNCTION private.profil_forme_compte_candidat_trg() OWNER TO postgres;
ALTER FUNCTION private.candidat_non_affectable_trg() OWNER TO postgres;
ALTER FUNCTION private.candidature_permet_depot_piece(uuid) OWNER TO postgres;
ALTER FUNCTION private.kyc_depot_etape_trg() OWNER TO postgres;
ALTER FUNCTION private.kyc_depot_sans_decision_trg() OWNER TO postgres;

-- ============================================================
-- 6. Prerequis de travail : compte valide seulement (F1)
-- ============================================================

-- Corps de 0027 inchange, sauf la garde : role teacher ET compte valide, en
-- exigence positive. Un compte candidat ne pose ni pays, ni langues, ni fuseau
-- dans teacher_profiles : les langues et le fuseau y sont recopies des
-- reponses a l'entree en salle 3 (spec 2.2), le pays par l'enseignant actif.
CREATE OR REPLACE FUNCTION public.maj_profil_enseignant(
  p_country text DEFAULT NULL,
  p_languages text[] DEFAULT NULL,
  p_timezone text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND public.app_role() = 'teacher' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'profil enseignant reserve a un enseignant au compte valide'
      USING ERRCODE = '42501';
  END IF;

  -- Le fuseau fait loi sur la grille de disponibilites : un libelle absent de
  -- la base de fuseaux casserait mon_fuseau() sans erreur visible.
  IF p_timezone IS NOT NULL
     AND NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_timezone
     ) THEN
    RAISE EXCEPTION 'fuseau inconnu';
  END IF;

  UPDATE public.teacher_profiles t
     SET country = coalesce(p_country, t.country),
         languages = coalesce(p_languages, t.languages),
         timezone_iana = coalesce(p_timezone, t.timezone_iana)
   WHERE t.profile_id = v_uid
     AND t.deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'aucun profil enseignant';
  END IF;
END;
$function$;

-- ============================================================
-- 7. Depot R2 : la porte suit kyc_staff_self_insert et l'etape (F2, R6)
-- ============================================================

-- Branches admin et tuteur inchangees (compte valide). La branche du depot
-- pour soi (teacher, controller) reprend la garde etroite d'af_l1_08 : compte
-- pending_kyc, provisional_active ou active, acces non echu, non supprime.
-- Toutes les branches exigent l'etape de la candidature (R6).
CREATE OR REPLACE FUNCTION public.peut_deposer_piece_identite(p_profile_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(
    p_profile_id IS NOT NULL
    AND private.candidature_permet_depot_piece(p_profile_id)
    AND (
      (public.app_account_valid()
       AND (public.app_role() = 'admin'
            OR (public.app_role() = 'guardian'
                AND EXISTS (
                  SELECT 1 FROM public.profiles p
                  WHERE p.id = p_profile_id
                    AND p.deleted_at IS NULL
                    AND p.household_id IS NOT NULL
                    AND p.household_id = public.app_household_id()))))
      OR (public.app_role() IN ('teacher', 'controller')
          AND p_profile_id = auth.uid()
          AND EXISTS (
            SELECT 1 FROM public.profiles pv
            WHERE pv.id = auth.uid()
              AND pv.account_status IN ('pending_kyc', 'provisional_active', 'active')
              AND (pv.access_until IS NULL OR pv.access_until > pg_catalog.now())
              AND pv.deleted_at IS NULL))
    ),
    false);
$function$;

-- ============================================================
-- 8. Lectures de la direction bornees a son cote (R4, R5)
-- ============================================================

-- ADM-08, registre des comptes : corps de 0015/0044 inchange, plus la portee
-- des comptes candidats.
CREATE OR REPLACE FUNCTION public.comptes_admin()
RETURNS TABLE(profile_id uuid, immutable_id text, prenom text, nom text, role public.app_role,
              etat_compte public.account_status, inscrit_le timestamp with time zone,
              acces_jusqu_au timestamp with time zone, foyer_id uuid, etat_piece text,
              contrats integer, a_enseignant boolean, enfants_du_foyer integer)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  select
    p.id,
    p.immutable_id,
    case when public.agent_identite_masquee() then null else p.first_name end,
    case when public.agent_identite_masquee() then null else p.last_name end,
    p.role,
    p.account_status,
    p.created_at,
    p.access_until,
    p.household_id,
    case
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'pending' and k.deleted_at is null
      ) then 'a_verifier'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'approved' and k.deleted_at is null
      ) then 'validee'
      when exists (
        select 1 from public.kyc_documents k
        where k.profile_id = p.id and k.status = 'rejected' and k.deleted_at is null
      ) then 'refusee'
      else 'aucune'
    end::text,
    (select count(*)::int from public.contract_acceptances c where c.profile_id = p.id),
    exists (
      select 1 from public.teacher_student_assignments a
      where a.student_id = p.id and a.ended_at is null
    ),
    (select count(*)::int from public.profiles e
      where e.household_id = p.household_id
        and e.role = 'student' and e.deleted_at is null)
  from public.profiles p
  where p.deleted_at is null
    and public.app_role() = 'admin'
    and public.app_account_valid()
    and not app_private.compte_candidat_hors_portee(p.id)
  order by
    case p.account_status
      when 'pending_kyc' then 0
      when 'provisional_active' then 1
      else 2
    end,
    p.created_at asc;
$function$;

-- ADM-02, file des dossiers a valider : corps de 20261012114000 inchange,
-- plus la portee des comptes candidats, et un compte candidat n'y entre
-- qu'avec une candidature en Salle de verification et d'entretien (en cours)
-- ou apres (R5).
CREATE OR REPLACE FUNCTION public.dossiers_en_attente()
RETURNS TABLE(profile_id uuid, immutable_id text, first_name text, last_name text,
              role public.app_role, account_status public.account_status,
              inscrit_le timestamp with time zone, document_id uuid, doc_type text,
              document_gender public.gender, object_key text,
              depose_le timestamp with time zone, etat_piece text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_en_attente integer;
BEGIN
  IF NOT coalesce(
    public.app_role() = 'admin' AND public.app_account_valid(),
    false
  ) THEN
    RAISE EXCEPTION 'validation des dossiers reservee a l''administration';
  END IF;

  SELECT count(*) INTO v_en_attente
  FROM public.kyc_documents k
  WHERE k.status = 'pending' AND k.deleted_at IS NULL;

  IF v_en_attente = 0 THEN
    RETURN QUERY
      SELECT
        p.id, p.immutable_id, p.first_name, p.last_name, p.role,
        p.account_status, p.created_at,
        NULL::uuid, NULL::text, NULL::public.gender, NULL::text,
        NULL::timestamptz,
        'aucune'::text
      FROM public.profiles p
      WHERE p.deleted_at IS NULL
        AND p.account_status = 'pending_kyc'
        AND NOT app_private.compte_candidat_hors_portee(p.id)
        AND private.candidature_permet_depot_piece(p.id)
      ORDER BY p.created_at ASC;
    RETURN;
  END IF;

  RETURN QUERY
    WITH visibles AS (
      SELECT k.*
      FROM public.read_kyc_documents() k
      WHERE k.status = 'pending'
    )
    SELECT
      p.id, p.immutable_id, p.first_name, p.last_name, p.role,
      p.account_status, p.created_at,
      v.id, v.doc_type, v.gender, v.object_key, v.created_at,
      CASE
        WHEN v.id IS NOT NULL THEN 'a_verifier'
        WHEN EXISTS (
          SELECT 1 FROM public.kyc_documents k2
          WHERE k2.profile_id = p.id
            AND k2.status = 'pending'
            AND k2.deleted_at IS NULL
        ) THEN 'non_visible'
        ELSE 'aucune'
      END::text
    FROM public.profiles p
    LEFT JOIN visibles v ON v.profile_id = p.id
    WHERE p.deleted_at IS NULL
      AND (p.account_status = 'pending_kyc' OR v.id IS NOT NULL)
      AND NOT app_private.compte_candidat_hors_portee(p.id)
      AND private.candidature_permet_depot_piece(p.id)
    ORDER BY coalesce(v.created_at, p.created_at) ASC;
END;
$function$;

-- ADM-01 : le compteur des dossiers en attente compte ce que la file
-- d'ADM-02 montre a ce lecteur ; les autres compteurs sont inchanges.
CREATE OR REPLACE FUNCTION public.indicateurs_admin()
RETURNS TABLE(dossiers_en_attente integer, foyers_sans_enseignant integer,
              rapports_manquants integer, incidents_24h integer, comptes_echus integer,
              demandes_en_attente integer)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
begin
  if NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) then
    raise exception 'centre de commande reserve a l''administration';
  end if;

  return query
  select
    -- Des **personnes** en attente de validation, plus des documents deposes.
    -- L'ancien compte lisait `kyc_documents where status='pending'` et
    -- affichait donc zero pendant que trois enseignants attendaient.
    -- CAND-L1B : un compte candidat de l'autre cote, ou en salle d'examen,
    -- n'est pas compte.
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'pending_kyc'
        and not app_private.compte_candidat_hors_portee(p.id)
        and private.candidature_permet_depot_piece(p.id)),
    (select count(distinct p.household_id)::int
       from public.profiles p
      where p.role = 'student' and p.deleted_at is null
        and p.account_status in ('active', 'provisional_active')
        and not exists (
          select 1 from public.teacher_student_assignments a
          where a.student_id = p.id and a.ended_at is null)),
    (select count(*)::int from public.sessions s
      where s.status = 'ended' and s.deleted_at is null
        and not exists (
          select 1 from public.lesson_reports r
          where r.session_id = s.id and r.deleted_at is null)),
    (select count(*)::int from public.sessions s
      where s.deleted_at is null
        and s.status in ('tech_failure', 'teacher_absent', 'student_absent')
        and s.updated_at > now() - interval '24 hours'),
    (select count(*)::int from public.profiles p
      where p.deleted_at is null
        and p.account_status = 'provisional_active'
        and p.access_until is not null and p.access_until < now()),
    (select count(*)::int from public.matching_requests m
      where m.status = 'pending');
end;
$function$;

-- ============================================================
-- 9. Droits et empreintes F86 des RPC client, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.maj_profil_enseignant(text,text[],text)',
    'public.peut_deposer_piece_identite(uuid)',
    'public.comptes_admin()',
    'public.dossiers_en_attente()',
    'public.indicateurs_admin()'
  ] LOOP
    EXECUTE pg_catalog.format('ALTER FUNCTION %s OWNER TO postgres', f);
    EXECUTE pg_catalog.format('REVOKE ALL ON FUNCTION %s FROM PUBLIC, anon, service_role, agent_ro', f);
    EXECUTE pg_catalog.format('GRANT EXECUTE ON FUNCTION %s TO authenticated', f);
  END LOOP;
END;
$acl$;

DO $droits$
DECLARE
  v record;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.maj_profil_enseignant(text,text[],text)', 'ROLE_POSITIVE_TEACHER_VALID',
       'ENS-05 : ecriture bornee aux trois champs non sensibles du profil enseignant (pays, langues, fuseau), jamais weekly_hours_cap ni kyc_status. Garde positive teacher et compte valide (F1) : un compte candidat pending_kyc est refuse (42501).'),
      ('public.peut_deposer_piece_identite(uuid)', 'ROLE_POSITIVE_DEPOT_PIECE',
       'Porte du depot R2, sans effet de bord : admin ou tuteur de son foyer au compte valide ; enseignant ou controleur pour soi, compte pending_kyc, provisional_active ou active, comme kyc_staff_self_insert (F2) ; toujours a l etape de la candidature (salle 2 en cours ou salle 3, R6). authenticated seul : la fonction Edge appelle la porte sous le jeton de l appelant (R8).'),
      ('public.comptes_admin()', 'ROLE_POSITIVE_ADMIN_VALID',
       'ADM-08 : tous les comptes du produit, ce qui attend une decision d abord. Respecte le masquage d identite des agents. Un compte candidat avant la salle 3 de l autre cote que la direction qui lit n est pas rendu (R4, exception super-admin de 0088).'),
      ('public.dossiers_en_attente()', 'ROLE_POSITIVE_TEMPLATE',
       'ADM-02 : file des dossiers a valider, pieces cloisonnees par genre (read_kyc_documents). Un compte candidat n y entre que de son cote et en Salle de verification et d entretien en cours ou apres (R4, R5).'),
      ('public.indicateurs_admin()', 'ROLE_POSITIVE_TEMPLATE',
       'ADM-01 : compteurs de la direction ; dossiers en attente compte ce que la file d ADM-02 montre a ce lecteur (R4, R5).')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. CAND-L1B. %s Must-pass: supabase/tests/scenarios_cand_l1b_forme_compte.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note));
  END LOOP;
END;
$droits$;

COMMENT ON FUNCTION private.candidat_engagement_en_cours(uuid) IS
  'CAND-L1B : engagement d enseignant en cours (classe non close, seance de cours a venir ou en cours, affectation ouverte, remplacement d une telle seance). Aucun droit client.';
COMMENT ON FUNCTION private.candidature_compte_conforme(uuid) IS
  'CAND-L1B : forme du compte rattache a une candidature (role du type tant qu elle est en cours avant la salle 3 ; ni active ni provisional_active pour le role du type avant confirmee ; aucun engagement en cours avant confirmee). Lue par les deux declencheurs de contrainte. Aucun droit client.';
COMMENT ON FUNCTION private.candidat_non_affectable_trg() IS
  'CAND-L1B : aucun compte candidat (candidature hors confirmee) en enseignant d''une classe, seance de cours, affectation ou remplacement ; verrou FOR SHARE sur le compte. Aucun droit client.';
COMMENT ON FUNCTION private.candidature_permet_depot_piece(uuid) IS
  'CAND-L1B : la piece d un compte candidat se depose en salle 2 en cours ou en salle 3 ; un compte sans candidature n est pas touche. Aucun droit client.';
COMMENT ON FUNCTION private.kyc_depot_etape_trg() IS
  'CAND-L1B : refuse le depot d une piece hors etape, par toute voie. Aucun droit client.';
COMMENT ON FUNCTION private.kyc_depot_sans_decision_trg() IS
  'CAND-L1B : un depot de piece par un compte client nait pending, sans decision. INVOKER a dessein (current_user). Aucun droit client.';
COMMENT ON POLICY profiles_compte_candidat_portee ON public.profiles IS
  'CAND-L1B : la direction de l autre cote ne lit ni n ecrit un compte qui porte une candidature avant la salle 3 (CAND-Q07).';

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Le type enseignant porte le role teacher ; la colonne est obligatoire.
  IF NOT EXISTS (SELECT 1 FROM public.candidature_types WHERE code = 'enseignant' AND role_compte = 'teacher')
     OR EXISTS (SELECT 1 FROM pg_catalog.pg_attribute a
                WHERE a.attrelid = 'public.candidature_types'::regclass
                  AND a.attname = 'role_compte' AND NOT a.attnotnull) THEN
    RAISE EXCEPTION 'CAND-L1B : role_compte absent ou facultatif';
  END IF;

  -- Les RPC client : DEFINER, proprietaire postgres, search_path vide,
  -- volatilite attendue, empreinte F86 a jour, garde positive, authenticated
  -- seul.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.maj_profil_enseignant(text,text[],text)', 'v'),
      ('public.peut_deposer_piece_identite(uuid)', 's'),
      ('public.comptes_admin()', 's'),
      ('public.dossiers_en_attente()', 'v'),
      ('public.indicateurs_admin()', 'v')
    ) AS e(signature, volatilite)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR NOT v.prosecdef
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
       OR v.provolatile::text <> v.volatilite
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '')
          NOT LIKE '%md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef(v.oid)) || '%'
       OR app_private.has_unsafe_role_guard(v.prosrc)
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L1B : DEFINER, proprietaire, search_path, volatilite, empreinte, garde ou ACL invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Les aides internes : proprietaire postgres, search_path vide, DEFINER
  -- sauf le declencheur du depot sans decision (INVOKER), appelables par aucun
  -- compte.
  FOR v IN
    SELECT e.signature, e.definer, p.*
    FROM (VALUES
      ('private.candidat_engagement_en_cours(uuid)', true),
      ('private.candidature_compte_conforme(uuid)', true),
      ('private.candidature_forme_compte_trg()', true),
      ('private.profil_forme_compte_candidat_trg()', true),
      ('private.candidat_non_affectable_trg()', true),
      ('private.candidature_permet_depot_piece(uuid)', true),
      ('private.kyc_depot_etape_trg()', true),
      ('private.kyc_depot_sans_decision_trg()', false)
    ) AS e(signature, definer)
    LEFT JOIN pg_catalog.pg_proc p ON p.oid = pg_catalog.to_regprocedure(e.signature)
  LOOP
    IF v.oid IS NULL
       OR v.prosecdef IS DISTINCT FROM v.definer
       OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
       OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false) THEN
      RAISE EXCEPTION 'CAND-L1B : aide interne invalide : %', v.signature;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L1B : aide interne % executable par %', v.signature, v_role;
      END IF;
    END LOOP;
  END LOOP;

  -- L'aide de la policy : DEFINER STABLE, proprietaire postgres, search_path
  -- vide ; authenticated et agent_ro seuls.
  SELECT p.* INTO v FROM pg_catalog.pg_proc p
  WHERE p.oid = pg_catalog.to_regprocedure('app_private.compte_candidat_hors_portee(uuid)');
  IF v.oid IS NULL OR NOT v.prosecdef OR v.provolatile <> 's'
     OR pg_catalog.pg_get_userbyid(v.proowner) <> 'postgres'
     OR NOT coalesce(v.proconfig @> ARRAY['search_path=""'], false)
     OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
     OR NOT pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
     OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE') THEN
    RAISE EXCEPTION 'CAND-L1B : app_private.compte_candidat_hors_portee invalide';
  END IF;

  -- La policy : restrictive, toutes commandes, authenticated et agent_ro ; la
  -- RLS de profiles reste active.
  IF NOT EXISTS (
       SELECT 1 FROM pg_catalog.pg_policies
       WHERE schemaname = 'public' AND tablename = 'profiles'
         AND policyname = 'profiles_compte_candidat_portee'
         AND permissive = 'RESTRICTIVE' AND cmd = 'ALL'
         AND roles @> ARRAY['authenticated', 'agent_ro']::name[]
         AND roles <@ ARRAY['authenticated', 'agent_ro']::name[])
     OR NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = 'public.profiles'::regclass) THEN
    RAISE EXCEPTION 'CAND-L1B : policy restrictive de profiles absente ou mal formee';
  END IF;

  -- Les declencheurs : presents, actifs ; les deux de contrainte differables,
  -- immediats par defaut.
  FOR v IN
    SELECT e.tbl, e.nom, e.contrainte, t.oid AS tid, t.tgenabled, t.tgconstraint,
           t.tgdeferrable, t.tginitdeferred
    FROM (VALUES
      ('public.candidatures', 'candidatures_forme_compte', true),
      ('public.profiles', 'profiles_forme_compte_candidat', true),
      ('public.groupes', 'groupes_candidat_non_affectable', false),
      ('public.sessions', 'sessions_candidat_non_affectable', false),
      ('public.teacher_student_assignments', 'teacher_student_assignments_candidat_non_affectable', false),
      ('public.remplacements_seance', 'remplacements_seance_candidat_non_affectable', false),
      ('public.kyc_documents', 'kyc_documents_depot_etape', false),
      ('public.kyc_documents', 'kyc_documents_depot_sans_decision', false)
    ) AS e(tbl, nom, contrainte)
    LEFT JOIN pg_catalog.pg_trigger t
      ON t.tgrelid = e.tbl::regclass AND t.tgname = e.nom AND NOT t.tgisinternal
  LOOP
    IF v.tid IS NULL OR v.tgenabled <> 'O'
       OR (v.contrainte AND (v.tgconstraint = 0 OR NOT v.tgdeferrable OR v.tginitdeferred))
       OR (NOT v.contrainte AND v.tgconstraint <> 0) THEN
      RAISE EXCEPTION 'CAND-L1B : declencheur absent ou mal forme : %.%', v.tbl, v.nom;
    END IF;
  END LOOP;

  -- Les donnees deja en base respectent la forme, engagements compris (base
  -- de test : rien ne doit faire echouer ce controle ; ailleurs, l'echec se
  -- voit).
  FOR v IN SELECT DISTINCT c.profile_id FROM public.candidatures c WHERE c.profile_id IS NOT NULL LOOP
    PERFORM private.candidature_compte_conforme(v.profile_id);
  END LOOP;
END;
$postflight$;

COMMIT;
