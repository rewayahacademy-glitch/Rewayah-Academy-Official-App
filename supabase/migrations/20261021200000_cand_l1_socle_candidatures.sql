-- CAND-L1 (21/10/2026) : socle du module des candidatures, lectures seulement.
--
-- Decisions du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md
-- (CAND-Q02 lot serveur borne autorise sur la base de test ; CAND-Q07
-- separation femmes/hommes en base, le super-admin voit les deux cotes).
-- Revue : docs/current/CANDIDATURES/REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md,
-- sections 5.4 (capacites), 6.2 (etape, etat, dimensions separees) et 8
-- (transitions). Contrat : docs/current/CANDIDATURES/CONTRAT_PORTS_CANDIDATURES.md,
-- regles transverses, section 1 (PortCandidaturesDirection) et section 3 (le
-- candidat lit son etat par etat_dossier(), pas par une lecture neuve).
-- Specification consolidee : SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- sections 3.4 (genre), 4.1 (dimensions) et 8 (droits).
--
-- Ce lot pose :
-- * les tables (types, candidatures, contacts, reponses versionnees, journal
--   des evenements en ajout seul) et la liste des lecteurs du contact ;
-- * cinq RPC de LECTURE pour la direction : capacites_candidatures,
--   lister_candidatures, lire_candidature, lire_contact_candidature,
--   historique_candidature ; et la brique privee private.cand_ma_candidature()
--   que etat_dossier() etendu (lot L2) appellera pour le candidat. Aucun geste
--   (transition, import, invitation, entretien, referentiel de paiement)
--   n'existe encore : les lots suivants les ajoutent.
--
-- Principes :
-- * aucune ecriture directe : RLS active, aucun privilege de table pour PUBLIC,
--   anon, authenticated, service_role ni agent_ro, aucune policy ; tout passe
--   par des RPC SECURITY DEFINER a search_path vide (F86), comme les tables de
--   la messagerie metier (20261016090000_com_back_1_messages_metier.sql) ;
-- * cloisonnement par genre EN BASE, meme regle que read_kyc_documents()
--   (0090_a81_f69_review_fixes.sql) : le genre du lecteur vient de
--   profiles.gender de auth.uid() ; un lecteur au genre inconnu est refuse
--   (42501), sauf l'exception super-admin de 0088
--   (kyc_super_admin_exception_active), qui lit les deux cotes ; la portee
--   s'applique dans le WHERE, jamais apres coup ;
-- * le genre d'une candidature rattachee a un compte est celui du compte
--   (profiles.gender, colonne privilegiee), jamais une valeur libre (C8) ;
-- * une lecture hors portee rend {erreur: 'hors_portee'} sans aucune donnee et
--   laisse une trace (evenement lecture_hors_portee et audit_logs) : le refus
--   metier est RENDU, jamais leve, pour que la trace survive (motif de
--   inviter_enseignant, 20261016100300) ; une lecture de l'autre cote par
--   l'exception super-admin est journalisee aussi (C13) ;
-- * aucune liste ne porte de courriel, de telephone ni de genre ; le contact se
--   lit par une RPC a part, journalisee, reservee a la direction nommee (C12) ;
-- * le journal des evenements ne porte ni nom ni identifiant d'auteur vers
--   l'ecran : l'auteur est rendu par categorie (direction, candidat, systeme) ;
-- * tout instant rendu voyage en UTC (C11).
--
-- Choix faits dans ce lot, a relire :
-- * C1 le journal des evenements est en AJOUT SEUL (declencheur sur le modele
--   de classe_mouvements_ajout_seul, 20261016100100). Sa cle etrangere vers la
--   candidature est ON DELETE RESTRICT, pas CASCADE : une cascade buterait de
--   toute facon sur le declencheur ; RESTRICT rend le blocage explicite (23503)
--   au lieu d'une erreur 55000 venue de la cascade. Une candidature qui a un
--   historique ne s'efface donc pas. Les contacts et les reponses gardent
--   ON DELETE CASCADE.
--   ECART CONNU, prealable a toute application en production (CAND-Q21,
--   CAND-BR-14) : la suppression de compte existante (CPT-SUPPR-EXPORT,
--   20261018150000 : mes_donnees_export, private.cpt_anonymiser,
--   traiter_demande_suppression) ne couvre pas encore ces tables. Apres
--   anonymisation d'un compte, sa candidature garde nom, contacts et
--   reponses, et l'export ne les rend pas ; le journal en ajout seul refuse
--   aussi d'effacer un motif_interne. Le lot de conservation etend
--   cpt_anonymiser et mes_donnees_export (motifs internes exclus) et ouvre une
--   voie d'anonymisation sanctionnee du journal, apres l'avis du juriste ; le
--   scenario epingle l'ecart pour qu'il ne s'oublie pas ;
-- * C2 la reference CAND-nnnnn est formee par to_char(..., 'FM99999999900000') :
--   cinq chiffres au moins, sans troncature au-dela de 99999 (lpad tronquerait
--   et ferait collision a la cent millieme candidature) ;
-- * C3 la recherche par nom normalise comme normaliserPourRecherche
--   (lib/core/recherche/normalisation_recherche.dart) : minuscules, lettres
--   latines sans accent, arabe sans voyelles breves ni signes (U+064B a
--   U+0655, U+0670) ni allongement (U+0640), alif hamza ou madda lu alif, alif
--   maqsura lu ya, espaces replies. L'extension unaccent n'est pas installee
--   dans ce depot. strpos plutot que LIKE, pour qu'un % ou un _ saisi ne soit
--   pas un joker ; une recherche vide apres normalisation ne rapproche aucun
--   nom. La recherche par telephone n'est pas dans ce lot ;
-- * C4 dans un filtre, une cle a null vaut cle absente (un client qui
--   serialise ses champs vides ne se fait pas refuser) ; une recherche vide
--   apres retrait des espaces vaut aucune recherche ;
-- * C5 les compteurs d'alerte ne comptent que les candidatures en cours (issue
--   en_cours), ni en pause ; entretiensEnRetard et bloquees restent null : ils
--   ne se calculent qu'avec le lot des entretiens et des controles, et null ne
--   doit jamais devenir 0 ;
-- * C6 historique : pagination par cle (cree_le, id) a partir de l'evenement
--   curseur, pour que l'ordre rendu (cree_le DESC, id DESC) et la coupe
--   restent coherents ; un curseur qui n'est pas un evenement de cette
--   candidature est refuse (22023) ;
-- * C7 aucune RPC publique ne rend l'etat au candidat : le contrat (section 3)
--   et la revue (section 5.1) veulent une seule source pour /attente,
--   etat_dossier() etendu au lot L2. Ce lot pose seulement la brique privee
--   private.cand_ma_candidature() (la candidature la plus recente du compte
--   auth.uid(), profil supprime ignore, sans garde de role pour qu'un compte
--   pending_kyc la lise), executable par aucun compte ;
-- * C8 le genre d'une candidature rattachee est recopie de profiles.gender a
--   chaque ecriture (declencheur, sur le modele de completer_kyc_document,
--   0004) ; un compte au genre inconnu ne se rattache pas (23514) ; un genre
--   efface depuis (compte anonymise) laisse le dernier genre connu. Le genre
--   declare ne vaut que pour une ligne sans compte (import, invitation) ;
-- * C9 contacts, selon MAPPAGE_IMPORT_FORMULAIRES.md section 4 : un courriel
--   VALIDE (forme de inviter_enseignant) est la seule cle de recherche et la
--   seule adresse d'invitation ; un courriel mal forme se garde a part
--   (courriel_brut) et la ligne est marquee courrielAObtenir ; un telephone
--   E.164 se garde normalise, tout autre se garde tel quel (telephone_brut),
--   jamais complete, et la ligne est marquee indicatifAConfirmer. Les listes
--   ne portent que ces deux marques, jamais les valeurs ;
-- * C10 indisponibilite (apres la salle 3 seulement) : un drapeau et un
--   jusqu'au facultatif, comme la pause ; sans date, elle est ouverte. Le
--   serveur rend indisponible deja calcule ; aucune date infinie ;
-- * C11 tout instant rendu est en UTC, suffixe Z, quel que soit le TimeZone de
--   la session ; aujourd'hui est le jour calendaire UTC (jusqu'au compris) ;
-- * C12 le contact est reserve a la direction NOMMEE (spec consolidee 8.1,
--   revue 5.4), de son cote : private.candidature_lecteurs_contact, accordee
--   par le proprietaire comme private.super_admin_kyc, vide par defaut. Sans
--   elle, peutVoirContact est faux et lire_contact_candidature refuse (42501) ;
-- * C13 l'exception super-admin est journalisee comme pour les pieces
--   (autoriser_lecture_piece_identite, 0088) : chaque dossier, historique ou
--   contact lu de l'autre cote laisse une entree audit_logs au motif
--   exception_super_admin_kyc ; la liste garde une entree par appel (F69,
--   0090) avec le nombre de lignes de l'autre cote rendues ;
-- * C14 doubleVerificationRequise reste faux : aucun geste de ce lot n'exige
--   l'aal2, et monter en aal2 n'ouvrirait rien. Le lot de l'import l'ouvre avec
--   peutImporter, comme capacites_import_inscriptions.
--
-- Hors de ce lot, a trancher avant la production :
-- * ECART HORS MODULE : une direction active peut encore changer son propre
--   profiles.gender (la garde de L1-07, 20261017100700, exempte toute la
--   direction active), donc changer de cote, lire, puis revenir. La meme
--   faiblesse touche read_kyc_documents. Le correctif (refuser a une direction
--   le changement de son propre genre, hors service_role et exception
--   super-admin, et journaliser tout changement de genre) est un lot hors
--   module (CAND-Q15), soumis au feu vert du directeur ;
-- * le lot L3 relie les invitations existantes aux candidatures (reprise) et
--   y fait declarer le genre par la direction : genre reste NOT NULL.
BEGIN;

-- ============================================================
-- 1. Tables
-- ============================================================

CREATE TABLE public.candidature_types (
  code text PRIMARY KEY CHECK (code ~ '^[a-z_]{2,40}$'),
  actif boolean NOT NULL DEFAULT true,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
INSERT INTO public.candidature_types (code) VALUES ('enseignant');

-- La reference n'est jamais reattribuee (une sequence ne recule pas).
CREATE SEQUENCE public.candidatures_reference_seq AS bigint
  MINVALUE 1 MAXVALUE 99999999999999 NO CYCLE;

CREATE TABLE public.candidatures (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference text NOT NULL UNIQUE
    DEFAULT ('CAND-' || pg_catalog.to_char(
      pg_catalog.nextval('public.candidatures_reference_seq'::regclass), 'FM99999999900000'))
    CHECK (reference ~ '^CAND-[0-9]{5,}$'),
  type_code text NOT NULL REFERENCES public.candidature_types(code),
  profile_id uuid NULL REFERENCES public.profiles(id),
  -- Recopie de profiles.gender quand profile_id est pose (C8).
  genre public.gender NOT NULL,
  nom_complet text NOT NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(nom_complet)) BETWEEN 1 AND 200),
  etape text NOT NULL DEFAULT 'recue'
    CHECK (etape IN ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee')),
  etat text NULL
    CHECK (etat IN ('a_completer', 'en_examen', 'entretien_a_planifier',
                    'entretien_planifie', 'decision_en_attente')),
  issue text NOT NULL DEFAULT 'en_cours'
    CHECK (issue IN ('en_cours', 'refusee', 'retiree')),
  en_pause boolean NOT NULL DEFAULT false,
  reprise_le date NULL,
  restreinte boolean NOT NULL DEFAULT false,
  indisponible boolean NOT NULL DEFAULT false,
  indisponible_jusqu_au date NULL,
  paiement text NOT NULL DEFAULT 'inconnu'
    CHECK (paiement IN ('inconnu', 'compatible', 'incompatible', 'a_verifier')),
  responsable_id uuid NULL REFERENCES public.profiles(id),
  source text NOT NULL CHECK (source IN ('import', 'lien_public', 'invitation')),
  source_ref text NULL,
  pays_residence text NULL CHECK (pays_residence ~ '^[A-Z]{2}$'),
  fuseau_iana text NULL,
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  recue_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  derniere_activite timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT candidatures_type_profil_unique UNIQUE (type_code, profile_id),
  -- L'etat n'existe que dans les deux etapes qui en ont (revue, section 6.2).
  CONSTRAINT candidatures_etat_coherent CHECK (
    (etape IN ('recue', 'invitee', 'confirmee') AND etat IS NULL)
    OR (etape = 'prequalification' AND etat IS NOT NULL
        AND etat IN ('a_completer', 'en_examen'))
    OR (etape = 'verifications' AND etat IS NOT NULL
        AND etat IN ('en_examen', 'entretien_a_planifier', 'entretien_planifie',
                     'decision_en_attente'))),
  -- Une ligne importee porte toujours sa reference source (classeur, onglet,
  -- horodatage), jamais un nom.
  CONSTRAINT candidatures_import_reference CHECK (source <> 'import' OR source_ref IS NOT NULL),
  -- Sans compte, une candidature ne depasse pas l'invitation (revue, section 8).
  CONSTRAINT candidatures_compte_requis CHECK (profile_id IS NOT NULL OR etape IN ('recue', 'invitee')),
  -- Une date de reprise n'a de sens que pendant une pause.
  CONSTRAINT candidatures_reprise_en_pause CHECK (en_pause OR reprise_le IS NULL),
  -- L'indisponibilite (C10) : apres la salle 3, jusqu'au facultatif.
  CONSTRAINT candidatures_indisponible_jusqu_au CHECK (indisponible OR indisponible_jusqu_au IS NULL),
  CONSTRAINT candidatures_indisponible_confirmee CHECK (NOT indisponible OR etape = 'confirmee'),
  -- Aucune date infinie : elle sortirait vers l'ecran en texte illisible.
  CONSTRAINT candidatures_dates_finies CHECK (
    (reprise_le IS NULL OR pg_catalog.isfinite(reprise_le))
    AND (indisponible_jusqu_au IS NULL OR pg_catalog.isfinite(indisponible_jusqu_au)))
);
ALTER SEQUENCE public.candidatures_reference_seq OWNED BY public.candidatures.reference;
CREATE UNIQUE INDEX candidatures_source_ref_uidx
  ON public.candidatures (source, source_ref) WHERE source_ref IS NOT NULL;
CREATE INDEX candidatures_genre_etape_idx ON public.candidatures (genre, etape);
CREATE INDEX candidatures_activite_idx ON public.candidatures (derniere_activite DESC);
CREATE INDEX candidatures_profil_idx ON public.candidatures (profile_id);

-- Le contact ne figure dans aucune liste : il se lit par
-- lire_contact_candidature(), journalisee. Valeur validee ou valeur brute,
-- jamais les deux (C9).
CREATE TABLE public.candidature_contacts (
  candidature_id uuid PRIMARY KEY REFERENCES public.candidatures(id) ON DELETE CASCADE,
  -- Seule cle de recherche et seule adresse d'invitation.
  courriel text NULL
    CHECK (courriel = pg_catalog.lower(pg_catalog.btrim(courriel))
           AND pg_catalog.length(courriel) <= 254
           AND courriel ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  -- Courriel mal forme, garde tel quel : courriel a obtenir.
  courriel_brut text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(courriel_brut)) BETWEEN 1 AND 254),
  telephone text NULL CHECK (telephone ~ '^\+[1-9][0-9]{6,14}$'),
  -- Telephone hors E.164, garde tel quel, jamais complete : indicatif a confirmer.
  telephone_brut text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(telephone_brut)) BETWEEN 1 AND 40),
  CONSTRAINT candidature_contacts_un_courriel CHECK (courriel IS NULL OR courriel_brut IS NULL),
  CONSTRAINT candidature_contacts_un_telephone CHECK (telephone IS NULL OR telephone_brut IS NULL)
);
CREATE INDEX candidature_contacts_courriel_idx
  ON public.candidature_contacts (courriel) WHERE courriel IS NOT NULL;

-- Reponses versionnees par questionnaire (revue, R7) ; jamais recopiees dans
-- teacher_profiles.
CREATE TABLE public.candidature_reponses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id) ON DELETE CASCADE,
  questionnaire_version text NOT NULL
    CHECK (pg_catalog.length(questionnaire_version) BETWEEN 1 AND 40),
  reponses jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(reponses) = 'object'),
  source text NOT NULL CHECK (source IN ('import', 'candidat')),
  soumis_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_reponses_candidature_idx
  ON public.candidature_reponses (candidature_id, soumis_le DESC);

-- Le journal de la candidature (revue, section 5.3 point 8) : transitions,
-- gestes, lectures du contact et lectures hors portee. Ajout seul (C1).
CREATE TABLE public.candidature_evenements (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id) ON DELETE RESTRICT,
  type text NOT NULL CHECK (type IN (
    'creee', 'transition', 'pause', 'reprise', 'restriction', 'levee_restriction',
    'responsable', 'controle', 'import', 'correction_import', 'lecture_contact',
    'lecture_hors_portee', 'entretien', 'engagement', 'prevenu')),
  etape_avant text NULL CHECK (etape_avant IN
    ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee')),
  etape_apres text NULL CHECK (etape_apres IN
    ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee')),
  etat_avant text NULL CHECK (etat_avant IN ('a_completer', 'en_examen',
    'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente')),
  etat_apres text NULL CHECK (etat_apres IN ('a_completer', 'en_examen',
    'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente')),
  issue_avant text NULL CHECK (issue_avant IN ('en_cours', 'refusee', 'retiree')),
  issue_apres text NULL CHECK (issue_apres IN ('en_cours', 'refusee', 'retiree')),
  auteur_id uuid NULL REFERENCES public.profiles(id),
  motif_interne text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(motif_interne)) BETWEEN 1 AND 2000),
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(details) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_evenements_candidature_idx
  ON public.candidature_evenements (candidature_id, cree_le DESC, id DESC);

-- La direction nommee pour lire le contact (C12), sur le modele de
-- private.super_admin_kyc (0088) : accordee par le proprietaire, aucune
-- ecriture par un compte.
CREATE TABLE private.candidature_lecteurs_contact (
  profile_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  accorde_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  accorde_par uuid NULL REFERENCES public.profiles(id)
);

ALTER TABLE public.candidature_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_reponses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_evenements ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.candidature_lecteurs_contact ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.candidature_types, public.candidatures, public.candidature_contacts,
  public.candidature_reponses, public.candidature_evenements,
  private.candidature_lecteurs_contact
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
-- Les privileges par defaut de Supabase ouvrent aussi les sequences.
REVOKE ALL ON SEQUENCE public.candidatures_reference_seq,
  public.candidature_evenements_id_seq
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.candidatures IS
  'CAND-L1 : une candidature par type et par compte. Aucune policy : lecture par les RPC '
  'candidatures seulement, cloisonnees par genre (CAND-Q07) ; genre recopie du compte (C8).';
COMMENT ON TABLE public.candidature_contacts IS
  'CAND-L1 : courriel et telephone, valides ou bruts (C9), jamais dans une liste ; lecture '
  'journalisee par lire_contact_candidature(), direction nommee.';
COMMENT ON TABLE public.candidature_evenements IS
  'CAND-L1 : journal de la candidature en ajout seul (C1). ON DELETE RESTRICT : une '
  'candidature qui a un historique ne s efface pas (CAND-Q21 a venir).';
COMMENT ON TABLE private.candidature_lecteurs_contact IS
  'CAND-L1 : direction nommee pour lire le contact des candidatures (C12) ; accordee par le '
  'proprietaire, comme private.super_admin_kyc.';

-- ============================================================
-- 2. Aides internes (schema private, jamais appelables par un compte)
-- ============================================================

-- Ajout seul : ni modification ni suppression, pour personne.
CREATE FUNCTION private.cand_evenements_refuser_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'CAND-L1 : historique des candidatures en ajout seul'
    USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER candidature_evenements_ajout_seul
  BEFORE UPDATE OR DELETE ON public.candidature_evenements
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();

-- Le genre d'une candidature rattachee est celui du compte (C8), a chaque
-- ecriture : une valeur fournie est ecrasee, comme dans completer_kyc_document.
CREATE FUNCTION private.cand_genre_du_compte()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_genre public.gender;
BEGIN
  IF NEW.profile_id IS NULL THEN
    RETURN NEW;
  END IF;
  SELECT p.gender INTO v_genre FROM public.profiles p WHERE p.id = NEW.profile_id;
  IF v_genre IS NOT NULL THEN
    NEW.genre := v_genre;
  ELSIF TG_OP = 'UPDATE' AND NEW.profile_id IS NOT DISTINCT FROM OLD.profile_id THEN
    -- Genre efface depuis le rattachement (compte anonymise) : dernier connu.
    NEW.genre := OLD.genre;
  ELSE
    RAISE EXCEPTION 'CAND-L1 : genre du compte inconnu, candidature impossible a rattacher'
      USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER candidatures_genre_du_compte
  BEFORE INSERT OR UPDATE ON public.candidatures
  FOR EACH ROW EXECUTE FUNCTION private.cand_genre_du_compte();

-- Le lecteur : la direction active seulement (garde positive canonique), son
-- genre lu en base, l'exception super-admin de 0088 et la nomination pour le
-- contact (C12). Aucune ligne pour tout autre appelant. Appelee depuis les RPC
-- DEFINER (proprietaire postgres), d'ou kyc_super_admin_exception_active()
-- reste appelable.
CREATE FUNCTION private.cand_lecteur()
RETURNS TABLE (profile_id uuid, genre public.gender, super_admin boolean, contact boolean)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT p.id, p.gender, coalesce(public.kyc_super_admin_exception_active(), false),
         EXISTS (SELECT 1 FROM private.candidature_lecteurs_contact n WHERE n.profile_id = p.id)
  FROM public.profiles p
  WHERE p.id = auth.uid()
    AND p.deleted_at IS NULL
    AND coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
$function$;

-- Normalisation de recherche (C3), la meme que normaliserPourRecherche :
-- minuscules, latin sans accent, arabe sans voyelles breves, signes ni
-- allongement, formes de l'alif et du ya reunies, espaces replies.
CREATE FUNCTION private.cand_normaliser(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(pg_catalog.regexp_replace(
    pg_catalog.translate(pg_catalog.lower(coalesce(p_texte, '')),
      'àâäáãåçéèêëíìîïñóòôöõúùûüýÿÀÂÄÁÃÅÇÉÈÊËÍÌÎÏÑÓÒÔÖÕÚÙÛÜÝ'
        || U&'\0623\0625\0622\0649'
        || U&'\064B\064C\064D\064E\064F\0650\0651\0652\0653\0654\0655\0670\0640',
      'aaaaaaceeeeiiiinooooouuuuyyaaaaaaceeeeiiiinooooouuuuy'
        || U&'\0627\0627\0627\064A'),
    '[[:space:]]+', ' ', 'g'));
$function$;

-- Un instant rendu a l'ecran : UTC, suffixe Z, quel que soit le TimeZone de la
-- session (C11).
CREATE FUNCTION private.cand_instant(p_instant timestamptz)
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.to_char(p_instant AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
$function$;

-- Indisponible aujourd'hui (C10, C11) : drapeau pose, sans date ou jusqu'au
-- jour UTC courant compris.
CREATE FUNCTION private.cand_indisponible(c public.candidatures)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT c.indisponible
         AND (c.indisponible_jusqu_au IS NULL
              OR c.indisponible_jusqu_au >= (pg_catalog.now() AT TIME ZONE 'UTC')::date);
$function$;

-- La forme d'une ligne de liste (LigneCandidature) : jamais de courriel, de
-- telephone ni de genre ; du contact, seulement les deux marques (C9).
CREATE FUNCTION private.cand_ligne_json(c public.candidatures)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', c.id,
    'reference', c.reference,
    'nomComplet', c.nom_complet,
    'type', c.type_code,
    'etape', c.etape,
    'etat', c.etat,
    'issue', c.issue,
    'enPause', c.en_pause,
    'repriseLe', c.reprise_le,
    'restreinte', c.restreinte,
    'indisponible', private.cand_indisponible(c),
    'indisponibleJusquAu', c.indisponible_jusqu_au,
    'paiement', c.paiement,
    'paysResidence', c.pays_residence,
    'responsableId', c.responsable_id,
    'courrielAObtenir', NOT EXISTS (
      SELECT 1 FROM public.candidature_contacts k
      WHERE k.candidature_id = c.id AND k.courriel IS NOT NULL),
    'indicatifAConfirmer', EXISTS (
      SELECT 1 FROM public.candidature_contacts k
      WHERE k.candidature_id = c.id AND k.telephone_brut IS NOT NULL),
    'derniereActivite', private.cand_instant(c.derniere_activite),
    'recueLe', private.cand_instant(c.recue_le));
$function$;

-- Une lecture hors portee : trace dans le journal de la candidature (sans
-- motif, details vides) et dans audit_logs (quelle lecture), puis refus rendu
-- sans aucune donnee.
CREATE FUNCTION private.cand_hors_portee(p_id uuid, p_lecteur uuid, p_lecture text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id)
  VALUES (p_id, 'lecture_hors_portee', p_lecteur);
  PERFORM public.log_sensitive_access('candidature_hors_portee', 'candidatures', p_id::text,
    pg_catalog.jsonb_build_object('lecture', p_lecture));
  RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
END;
$function$;

-- La candidature du compte appelant (C7), pour etat_dossier() etendu au lot
-- L2 : aucune garde de role (un compte pending_kyc n'est pas
-- app_account_valid()), la seule identite est auth.uid(). Ni motif, ni
-- responsable, ni paiement, ni restriction, ni evenement.
CREATE FUNCTION private.cand_ma_candidature()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce((
    SELECT pg_catalog.jsonb_build_object(
             'candidature', true,
             'reference', c.reference,
             'type', c.type_code,
             'etape', c.etape,
             'etat', c.etat,
             'issue', c.issue,
             'enPause', c.en_pause,
             'repriseLe', c.reprise_le)
    FROM public.candidatures c
    JOIN public.profiles p ON p.id = c.profile_id AND p.deleted_at IS NULL
    WHERE c.profile_id = auth.uid()
    ORDER BY c.recue_le DESC, c.id DESC
    LIMIT 1), pg_catalog.jsonb_build_object('candidature', false));
$function$;

REVOKE ALL ON FUNCTION private.cand_evenements_refuser_mutation(), private.cand_genre_du_compte(),
  private.cand_lecteur(), private.cand_normaliser(text), private.cand_instant(timestamptz),
  private.cand_indisponible(public.candidatures), private.cand_ligne_json(public.candidatures),
  private.cand_hors_portee(uuid, uuid, text), private.cand_ma_candidature()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 3. RPC de lecture
-- ============================================================

-- Ce que l'ecran peut offrir, lu au serveur (revue, section 5.4). Les quatre
-- capacites de geste (peutDecider, peutImporter, peutMenerEntretien,
-- peutEcrireReferentiel) sont FAUSSES A DESSEIN : aucun de ces gestes n'existe
-- encore cote serveur, et une capacite ne promet jamais une action que le
-- serveur ne sait pas faire. Les lots des transitions, de l'import, des
-- entretiens (CAND-Q19 : la direction) et du referentiel de paiement les
-- ouvriront avec leurs RPC. doubleVerificationRequise est faux pour la meme
-- raison (C14). peutVoirContact exige la nomination (C12).
CREATE FUNCTION public.capacites_candidatures()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_admin boolean;
  v_genre public.gender;
  v_super boolean;
  v_contact boolean;
  v_lire boolean;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL, false) THEN
    RAISE EXCEPTION 'Acces refuse' USING ERRCODE = '42501';
  END IF;
  v_admin := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  IF v_admin THEN
    SELECT l.genre, l.super_admin, l.contact INTO v_genre, v_super, v_contact
    FROM private.cand_lecteur() l;
  END IF;
  v_super := v_admin AND coalesce(v_super, false);
  v_lire := v_admin AND (v_genre IS NOT NULL OR v_super);
  RETURN pg_catalog.jsonb_build_object(
    'peutLire', v_lire,
    'peutVoirContact', v_lire AND coalesce(v_contact, false),
    'peutLireHorsGenre', v_super,
    'genreLecteurConnu', v_admin AND v_genre IS NOT NULL,
    'peutDecider', false,
    'peutImporter', false,
    'doubleVerificationRequise', false,
    'peutMenerEntretien', false,
    'peutEcrireReferentiel', false);
END;
$function$;

-- La liste de la direction, cloisonnee par genre dans le WHERE. Chaque appel
-- laisse une entree d'audit (comme read_kyc_documents), sans le terme cherche,
-- avec le nombre de lignes de l'autre cote rendues par l'exception (C13).
-- Filtres (cles facultatives de p_filtre) : type, etape, etat, issue, enPause,
-- paiement, paysResidence, recherche. Tri : activite, recente, nom. Pages de 50.
CREATE FUNCTION public.lister_candidatures(
  p_filtre jsonb DEFAULT '{}'::jsonb,
  p_tri text DEFAULT 'activite',
  p_page integer DEFAULT 1
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_filtre jsonb := coalesce(p_filtre, '{}'::jsonb);
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_fautives text;
  v_type text;
  v_etape text;
  v_etat text;
  v_issue text;
  v_pause boolean;
  v_paiement text;
  v_pays text;
  v_recherche text;
  v_recherche_nom text;
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
  v_etapes jsonb;
  v_alertes jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;

  -- Le filtre : un objet, des cles connues, des valeurs du bon type.
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre de candidatures invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
  FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
  WHERE k.cle <> ALL (ARRAY['type', 'etape', 'etat', 'issue', 'enPause', 'paiement',
                            'paysResidence', 'recherche']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key = 'enPause' THEN 'boolean' ELSE 'string' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;

  v_type := v_filtre ->> 'type';
  v_etape := v_filtre ->> 'etape';
  v_etat := v_filtre ->> 'etat';
  v_issue := v_filtre ->> 'issue';
  v_pause := (v_filtre ->> 'enPause')::boolean;
  v_paiement := v_filtre ->> 'paiement';
  v_pays := v_filtre ->> 'paysResidence';
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');

  IF (v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.candidature_types t WHERE t.code = v_type))
     OR (v_etape IS NOT NULL AND v_etape NOT IN
        ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_paiement IS NOT NULL AND v_paiement NOT IN
        ('inconnu', 'compatible', 'incompatible', 'a_verifier'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre de candidatures invalide' USING ERRCODE = '22023';
  END IF;
  IF p_tri IS NULL OR p_tri NOT IN ('activite', 'recente', 'nom') THEN
    RAISE EXCEPTION 'tri de candidatures invalide : activite, recente ou nom' USING ERRCODE = '22023';
  END IF;
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page de candidatures invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;
  -- Une recherche faite seulement de signes ne rapproche aucun nom (C3).
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');

  -- La portee (genre ou exception super-admin) et les filtres, dans le WHERE.
  -- Le courriel cherche est le courriel valide seulement, jamais le brut (C9).
  WITH filtrees AS MATERIALIZED (
    SELECT c AS ligne,
           pg_catalog.row_number() OVER (ORDER BY
             CASE WHEN p_tri = 'activite' THEN c.derniere_activite END DESC,
             CASE WHEN p_tri = 'recente' THEN c.recue_le END DESC,
             CASE WHEN p_tri = 'nom' THEN c.nom_complet END ASC,
             c.id ASC) AS rang
    FROM public.candidatures c
    WHERE (v_super OR c.genre = v_genre)
      AND (v_type IS NULL OR c.type_code = v_type)
      AND (v_etape IS NULL OR c.etape = v_etape)
      AND (v_etat IS NULL OR c.etat = v_etat)
      AND (v_issue IS NULL OR c.issue = v_issue)
      AND (v_pause IS NULL OR c.en_pause = v_pause)
      AND (v_paiement IS NULL OR c.paiement = v_paiement)
      AND (v_pays IS NULL OR c.pays_residence = v_pays)
      AND (v_recherche IS NULL
           OR c.reference = pg_catalog.upper(v_recherche)
           OR EXISTS (SELECT 1 FROM public.candidature_contacts k
                      WHERE k.candidature_id = c.id
                        AND k.courriel = pg_catalog.lower(v_recherche))
           OR (v_recherche_nom IS NOT NULL
               AND pg_catalog.strpos(private.cand_normaliser(c.nom_complet), v_recherche_nom) > 0))
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.ligne).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(private.cand_ligne_json(f.ligne) ORDER BY f.rang)
                    FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50),
                  '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
  FROM filtrees f;

  -- Les compteurs : toute la portee, sans les autres filtres.
  SELECT pg_catalog.jsonb_build_object(
           'recue', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'recue'),
           'invitee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'invitee'),
           'prequalification', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'prequalification'),
           'verifications', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'verifications'),
           'confirmee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'confirmee')),
         pg_catalog.jsonb_build_object(
           'informationsManquantes', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause AND c.etat = 'a_completer'),
           'confirmeesIndisponibles', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause AND c.etape = 'confirmee'
               AND private.cand_indisponible(c)),
           'entretiensEnRetard', NULL::integer,
           'bloquees', NULL::integer)
    INTO v_etapes, v_alertes
  FROM public.candidatures c
  WHERE (v_super OR c.genre = v_genre);

  PERFORM public.log_sensitive_access('candidatures_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page,
      'recherche', v_recherche IS NOT NULL));

  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'total', v_total,
    'page', p_page,
    'taillePage', 50,
    'compteursEtapes', v_etapes,
    'compteursAlertes', v_alertes);
END;
$function$;

-- Le dossier d'une candidature. Refus metier rendus : {erreur: 'absente'} ou
-- {erreur: 'hors_portee'} (trace laissee). Une lecture de l'autre cote par
-- l'exception super-admin est journalisee (C13). controles et piece restent
-- null dans ce lot : le lot des transitions les calcule.
CREATE FUNCTION public.lire_candidature(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN private.cand_hors_portee(p_id, v_lecteur, 'dossier');
  END IF;
  IF v_super AND v_c.genre IS DISTINCT FROM v_genre THEN
    PERFORM public.log_sensitive_access('candidature_exception_super_admin', 'candidatures',
      p_id::text, pg_catalog.jsonb_build_object('lecture', 'dossier',
                                                'motif', 'exception_super_admin_kyc'));
  END IF;

  RETURN private.cand_ligne_json(v_c) || pg_catalog.jsonb_build_object(
    'version', v_c.version,
    'source', v_c.source,
    'reponses', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'questionnaireVersion', r.questionnaire_version,
               'reponses', r.reponses,
               'source', r.source,
               'soumisLe', private.cand_instant(r.soumis_le))
             ORDER BY r.soumis_le DESC, r.id DESC)
      FROM public.candidature_reponses r
      WHERE r.candidature_id = v_c.id), '[]'::jsonb),
    'controles', NULL::jsonb,
    'piece', NULL::jsonb);
END;
$function$;

-- Le contact d'une candidature dans la portee, pour la direction nommee (C12) :
-- chaque lecture laisse un evenement lecture_contact et une entree d'audit, au
-- motif exception_super_admin_kyc quand elle vient de l'autre cote (C13).
-- Valeurs validees et valeurs brutes rendues a part (C9).
CREATE FUNCTION public.lire_contact_candidature(p_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_nomme boolean;
  v_c public.candidatures;
  v_k public.candidature_contacts;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin, l.contact INTO v_lecteur, v_genre, v_super, v_nomme
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(v_nomme, false) THEN
    RAISE EXCEPTION 'contact des candidatures reserve a la direction nommee' USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL THEN
    RAISE EXCEPTION 'candidature attendue' USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN private.cand_hors_portee(p_id, v_lecteur, 'contact');
  END IF;

  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id)
  VALUES (p_id, 'lecture_contact', v_lecteur);
  PERFORM public.log_sensitive_access('candidature_lecture_contact', 'candidature_contacts',
    p_id::text, pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'motif', CASE WHEN v_super AND v_c.genre IS DISTINCT FROM v_genre
                    THEN 'exception_super_admin_kyc' ELSE 'meme_genre_admin' END));

  SELECT k.* INTO v_k FROM public.candidature_contacts k WHERE k.candidature_id = p_id;
  RETURN pg_catalog.jsonb_build_object(
    'courriel', v_k.courriel,
    'telephone', v_k.telephone,
    'courrielBrut', v_k.courriel_brut,
    'telephoneBrut', v_k.telephone_brut);
END;
$function$;

-- L'historique, le plus recent d'abord, par pages (C6). L'auteur est une
-- categorie : systeme (aucun auteur), candidat (le compte de la candidature),
-- direction (tout autre). Ni nom ni identifiant d'auteur. Une lecture de
-- l'autre cote par l'exception super-admin est journalisee (C13).
CREATE FUNCTION public.historique_candidature(
  p_id uuid,
  p_curseur bigint DEFAULT NULL,
  p_limite integer DEFAULT 50
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_super boolean;
  v_c public.candidatures;
  v_curseur_le timestamptz;
  v_evenements jsonb;
  v_suivant bigint;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'candidatures reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super
  FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune candidature lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_id IS NULL OR p_limite IS NULL OR p_limite < 1 OR p_limite > 200 THEN
    RAISE EXCEPTION 'historique invalide : candidature attendue, limite de 1 a 200'
      USING ERRCODE = '22023';
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF v_c.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF NOT (v_super OR v_c.genre = v_genre) THEN
    RETURN private.cand_hors_portee(p_id, v_lecteur, 'historique');
  END IF;

  IF p_curseur IS NOT NULL THEN
    SELECT e.cree_le INTO v_curseur_le
    FROM public.candidature_evenements e
    WHERE e.id = p_curseur AND e.candidature_id = p_id;
    IF v_curseur_le IS NULL THEN
      RAISE EXCEPTION 'curseur d''historique inconnu pour cette candidature' USING ERRCODE = '22023';
    END IF;
  END IF;
  IF v_super AND v_c.genre IS DISTINCT FROM v_genre THEN
    PERFORM public.log_sensitive_access('candidature_exception_super_admin', 'candidatures',
      p_id::text, pg_catalog.jsonb_build_object('lecture', 'historique',
                                                'motif', 'exception_super_admin_kyc'));
  END IF;

  WITH page AS (
    SELECT e.*,
           pg_catalog.row_number() OVER (ORDER BY e.cree_le DESC, e.id DESC) AS rang
    FROM public.candidature_evenements e
    WHERE e.candidature_id = p_id
      AND (p_curseur IS NULL OR (e.cree_le, e.id) < (v_curseur_le, p_curseur))
    ORDER BY e.cree_le DESC, e.id DESC
    LIMIT p_limite + 1
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', p.id,
             'type', p.type,
             'quand', private.cand_instant(p.cree_le),
             'etapeAvant', p.etape_avant,
             'etapeApres', p.etape_apres,
             'etatAvant', p.etat_avant,
             'etatApres', p.etat_apres,
             'issueAvant', p.issue_avant,
             'issueApres', p.issue_apres,
             'auteur', CASE WHEN p.auteur_id IS NULL THEN 'systeme'
                            WHEN p.auteur_id = v_c.profile_id THEN 'candidat'
                            ELSE 'direction' END,
             'motif', p.motif_interne)
           ORDER BY p.rang) FILTER (WHERE p.rang <= p_limite), '[]'::jsonb),
         CASE WHEN pg_catalog.count(*) > p_limite
              THEN pg_catalog.max(p.id) FILTER (WHERE p.rang = p_limite) END
    INTO v_evenements, v_suivant
  FROM page p;

  RETURN pg_catalog.jsonb_build_object('evenements', v_evenements, 'curseurSuivant', v_suivant);
END;
$function$;

-- ============================================================
-- 4. Droits, empreintes F86, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.capacites_candidatures()',
    'public.lister_candidatures(jsonb,text,integer)',
    'public.lire_candidature(uuid)',
    'public.lire_contact_candidature(uuid)',
    'public.historique_candidature(uuid,bigint,integer)'
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
      ('public.capacites_candidatures()', 'SESSION_REQUIRED_CAPABILITY_READ',
       'Lecture seule : capacites lues au serveur ; direction active, genre connu ou super-admin pour lire ; contact pour la direction nommee ; gestes et double verification a false a dessein. Sans session : 42501.'),
      ('public.lister_candidatures(jsonb,text,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active ; portee par genre du lecteur dans le WHERE, super-admin les deux cotes ; genre inconnu 42501 ; filtre, tri ou page invalide 22023 ; aucune cle courriel, telephone ni genre ; audit de chaque lecture de liste, lignes de l autre cote comptees.'),
      ('public.lire_candidature(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active ; absente ou hors_portee rendus, jamais leves ; hors portee trace (evenement et audit) sans aucune donnee ; exception super-admin journalisee.'),
      ('public.lire_contact_candidature(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_NAMED',
       'Direction active et nommee (private.candidature_lecteurs_contact), sinon 42501 ; chaque lecture du contact tracee (evenement lecture_contact et audit, motif de l exception) ; hors portee rendu et trace.'),
      ('public.historique_candidature(uuid,bigint,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active ; auteur en categorie, ni nom ni identifiant ; limite 1 a 200 ; hors portee rendu et trace ; exception super-admin journalisee.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-21. CAND-L1. %s Must-pass: supabase/tests/scenarios_cand_l1_socle.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Les RPC : DEFINER, proprietaire postgres, search_path vide, volatilite
  -- attendue, empreinte F86 a jour, authenticated seul.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.capacites_candidatures()', 's'),
      ('public.lister_candidatures(jsonb,text,integer)', 'v'),
      ('public.lire_candidature(uuid)', 'v'),
      ('public.lire_contact_candidature(uuid)', 'v'),
      ('public.historique_candidature(uuid,bigint,integer)', 'v')
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
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'CAND-L1 : DEFINER, proprietaire, search_path, volatilite, empreinte ou ACL invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Aucune lecture publique de l'etat du candidat (C7).
  IF pg_catalog.to_regprocedure('public.ma_candidature()') IS NOT NULL THEN
    RAISE EXCEPTION 'CAND-L1 : l''etat du candidat se lit par etat_dossier(), pas par ma_candidature()';
  END IF;

  -- Les aides internes : appelables par aucun compte.
  FOR v IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private' AND p.proname LIKE 'cand\_%'
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L1 : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;

  -- Les tables : RLS active, aucun privilege client ; les sequences aussi.
  FOR v IN
    SELECT c.oid, c.relkind, c.relrowsecurity
    FROM pg_catalog.pg_class c
    WHERE c.oid IN ('public.candidature_types'::regclass, 'public.candidatures'::regclass,
                    'public.candidature_contacts'::regclass, 'public.candidature_reponses'::regclass,
                    'public.candidature_evenements'::regclass,
                    'private.candidature_lecteurs_contact'::regclass,
                    'public.candidatures_reference_seq'::regclass,
                    'public.candidature_evenements_id_seq'::regclass)
  LOOP
    IF v.relkind = 'r' AND NOT v.relrowsecurity THEN
      RAISE EXCEPTION 'CAND-L1 : RLS inactive sur %', v.oid::regclass;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF (v.relkind = 'r' AND pg_catalog.has_table_privilege(v_role, v.oid,
            'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER'))
         OR (v.relkind = 'S' AND pg_catalog.has_sequence_privilege(v_role, v.oid,
            'USAGE,SELECT,UPDATE')) THEN
        RAISE EXCEPTION 'CAND-L1 : % garde un privilege sur %', v_role, v.oid::regclass;
      END IF;
    END LOOP;
  END LOOP;
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_policies
    WHERE (schemaname = 'public'
           AND tablename IN ('candidature_types', 'candidatures', 'candidature_contacts',
                             'candidature_reponses', 'candidature_evenements'))
       OR (schemaname = 'private' AND tablename = 'candidature_lecteurs_contact')
  ) THEN
    RAISE EXCEPTION 'CAND-L1 : une policy ouvre une table des candidatures';
  END IF;
END;
$postflight$;

COMMIT;
