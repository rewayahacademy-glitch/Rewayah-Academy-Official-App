-- CAND-L3 (23/10/2026) : inscription publique sans invitation, import controle
-- des reponses des formulaires, rapprochement, liste des personnes a prevenir.
--
-- Decisions du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md
-- (CAND-Q03 un lien public ; CAND-Q04 une seule liste ; CAND-Q06 pas de WhatsApp
-- hors l'envoi du lien aux personnes sans courriel ; CAND-Q07 separation
-- femmes/hommes en base ; CAND-Q10 le module n'envoie aucun courriel ; CAND-Q16
-- la ligne la plus recente l'emporte ; CAND-Q17 l'import reste ponctuel ; CAND-Q21
-- conservation, avis du juriste). Specification consolidee :
-- SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md, section 3 (3.1 lignes 2 a 6, 3.2,
-- 3.4), 4.2 (transitions 1, 2, 5, 26, 27), 7.4, 11 (ligne L3), 12.1 (L3-1 a L3-19).
-- Besoins : DEPENDANCES_BACKEND.md, CAND-BR-09, CAND-BR-16, CAND-BR-17, part de
-- CAND-BR-04. Mappage : MAPPAGE_IMPORT_FORMULAIRES.md (colonnes, contacts,
-- doublons). Fiches : CAND-04 et ADM-23 du catalogue.
--
-- Ce lot pose :
-- * l'inscription d'un candidat par le lien public ou par un code d'invitation
--   (inscrire_candidat) : le compte est celui de l'invitation (fabrique
--   private.creer_profil_inscription_interne, role teacher, pending_kyc, sans
--   foyer : CAND-L1B), la candidature n'existe qu'une fois le courriel confirme
--   (auth.users.email_confirmed_at), l'accord de confidentialite est enregistre
--   a la version attendue, un plafond d'inscriptions par heure (app_config)
--   rend la meme reponse que le succes, une cle de mise en ligne (fausse par
--   defaut) ferme l'inscription sans code en base ;
-- * l'import controle des reponses des formulaires : analyse serveur d'un CSV
--   (apercu_import_formulaires : essai a blanc, aucun nom ni contact rendu,
--   jeton HMAC), confirmation idempotente (confirmer_import_formulaires :
--   super-admin en aal2, cle d'idempotence, jeton, choix de doublons), des
--   REPONSES IMPORTEES (jamais un compte, une invitation, une piece, un accord
--   ni une candidature a la place de la personne), un journal, des lots ;
-- * la lecture de ces reponses dans la portee femmes/hommes
--   (lister_formulaires_importes) et le geste « garder pour suivi »
--   (transition 2) ;
-- * le rapprochement (spec 3.4) : le meme courriel confirme relie la reponse a
--   la candidature et pre-remplit le brouillon de la Salle d'examen ; le meme
--   telephone, seul, propose a la direction (lister_rapprochements_candidats,
--   rattacher_formulaire_candidat : transition 27) ;
-- * la liste des personnes a prevenir (lister_a_prevenir_candidats) et le geste
--   « consigner prevenu » (transition 26) : le lien d'inscription envoye par
--   WhatsApp a une personne sans courriel. Aucun courriel n'est ecrit dans une
--   file : la file des courriels (CONTRAT_FILE_COURRIELS.md, public.
--   candidature_courriels) n'existe pas encore, elle est du lot L5.
--
-- Choix faits dans ce lot, a relire :
-- * C1 l'import (apercu et confirmation) est reserve au super-admin de 0088 en
--   double verification (aal2 lue dans le jeton, exigee en base) : le fichier
--   mele les deux cotes (spec 3.2). Lire les reponses importees, les garder
--   pour suivi, prevenir et rattacher sont des gestes de la direction, dans sa
--   portee : son cote ; le super-admin lit les deux cotes (lecture journalisee)
--   mais ne decide que du sien (CAND-L2A1, C4) ;
-- * C2 doublons (MAPPAGE 5, CAND-Q16) : deux lignes du MEME genre declare qui
--   partagent un courriel valide OU un telephone normalise (jamais un nom) ; la
--   plus recente l'emporte, les autres restent en historique (jamais effacees).
--   Le groupe se forme de proche en proche sur tout ce que la base garde (la
--   composante entiere, historique compris), pour que rejouer un fichier ne le
--   defasse pas. Un choix de la direction par groupe (« personnes distinctes » ou la ligne
--   retenue) l'emporte et est GARDE sous l'identifiant du groupe : un fichier
--   corrige qui se rejoue ne le defait pas. Une ligne gardee pour suivi ou
--   rattachee a une candidature n'est jamais mise en historique. ECART a la
--   spec 3.2 et a L3-11 (« un groupe sans choix reste a corriger ») : la
--   decision du directeur CAND-Q16 (la plus recente l'emporte) est posterieure
--   a cette proposition et le defaut la suit. Deux lignes de genres
--   differents ne forment jamais un groupe (un couple qui partage un
--   telephone ce sont deux personnes, de deux cotes) ;
-- * C3 rapprochement (spec 3.4 et 0.2 bis) : le courriel CONFIRME (celui de la
--   session) relie seul, a condition qu'une seule ligne active du meme genre
--   le porte ; le telephone ne relie jamais seul (aucun canal ne le verifie) :
--   il propose, et la direction applique (transition 27). Un genre different ne
--   rapproche jamais. Une personne de B (l'import du 12/10) est reconnue par un
--   evenement, sans rien pre-remplir : sa ligne n'est pas ecrite. Une
--   proposition ne se lit et ne s'applique que tant qu'elle tient : la ligne est du
--   meme cote que la candidature (un fichier corrige peut changer son genre), elle
--   porte encore son telephone, la candidature n'est pas reliee a une ligne. La
--   ligne `recue` que l'inscription reprend est relue sous verrou, et une ligne
--   retiree ou refusee n'est pas reprise (candidature neuve). Une inscription et
--   un import ne se croisent pas (verrou de l'import, partage par l'une,
--   exclusif pour l'autre) : sans lui, chacun rapprochait ce qu'il ecrivait de ce
--   que l'autre n'avait pas encore valide, et la personne n'etait jamais reliee ;
-- * C4 deux portes, un compte : inscrire_candidat sert le lien public (p_code
--   nul) et l'invitation (p_code). inscrire_enseignant_invite (RACCORDEMENT-1016,
--   AF L1-11) est LAISSEE telle quelle : le client deploye l'appelle et les
--   scenarios de ces lots l'epinglent. Elle ne cree pas de candidature, ne
--   demande ni telephone ni accord ; le client de CAND-04 passe a inscrire_candidat,
--   puis un lot ferme l'ancienne voie et reprend les comptes pending_kyc nes
--   d'une invitation (reprise, spec 3.3) : PAS ECRIT ICI ;
-- * C5 plafond : le nombre d'inscriptions publiques reussies de la derniere
--   heure (private.inscriptions_publiques) contre candidatures.inscriptions_par_heure
--   (60 par defaut). Au-dela : {resultat: acceptee} sans rien ecrire, exactement
--   la reponse du succes. L'invitation n'est pas plafonnee. Le plafond se joue
--   dans la RPC (CAND-F03 tranchee) : inscription_candidat_ouverte() ne rend que
--   la cle de mise en ligne et la version de confidentialite attendue, jamais l'etat du plafond ;
-- * C6 la cle candidatures.inscription_publique_ouverte est FAUSSE a
--   l'application de la migration (le controle final de la migration le verifie).
--   Le lien ne va sur le site, et la cle ne passe a vrai, qu'avec L1 a L3, le
--   SMTP d'authentification en production, enable_confirmations = true, le texte
--   de confidentialite relu par le juriste et le feu vert du directeur ;
-- * C7 l'accord de confidentialite : table a part (contract_acceptances est lue
--   par la garde d'activation d'un enseignant, un accord de plus y serait un
--   contrat de plus a exiger), version attendue dans app_config
--   (candidatures.confidentialite_version, 2026-10-v1 comme VersionsJuridiques) ;
-- * C8 candidatures.langue (fr ou ar, prerequis L3 du contrat de la file des
--   courriels, section 9) : remplie par l'inscription, jamais deduite ;
-- * C9 noms : aucune RPC du lot ne contient « candidature » (scenario de CAND-L1,
--   controle (a)) ; les aides privees s'appellent formulaires_* (les neuf cand_
--   de CAND-L1 restent neuf) ;
-- * C10 contacts (MAPPAGE 4), table des indicatifs (private.indicatifs_telephoniques,
--   UIT, sans les sous-zones nord-americaines) : un telephone n'est normalise
--   que si un indicatif reconnu est en tete (« + » ou « 00 » : 8 a 15 chiffres ;
--   sinon 11 a 15, le plan nord-americain 11 exactement) ; un numero national
--   (0...), trop court ou trop long, une notation scientifique, un « 0 » national
--   en trop (sauf Italie, Cote d'Ivoire, Gabon, Benin) restent tels quels,
--   « indicatif a confirmer ». Les chiffres arabo-indiens sont lus. Un courriel
--   mal forme n'est ni une cle ni une adresse ;
-- * C11 en-tetes reconnus par leur TEXTE normalise (pas leur position), debut de
--   phrase ; une association manuelle position -> champ (p_mappage) comble un
--   en-tete inconnu. Horodatage : ISO 8601 ou JJ/MM/AAAA, dans le fuseau donne
--   (UTC par defaut) ; la reference source est classeur|onglet|horodatage ECRIT
--   dans le fichier (jamais l'instant converti), donc stable d'un import a
--   l'autre. Le classeur et l'onglet ne portent pas de barre verticale ;
-- * C12 pre-remplissage : les sept reponses de MAPPAGE 2 (colonnes E a I, K, L)
--   deja converties en codes, gardees si le questionnaire courant les accepte ;
--   ce que la personne a deja ecrit dans son brouillon l'emporte ; le brouillon
--   n'est jamais envoye (private.paiement_declaration l'ignore) ; la version de
--   la candidature ne change pas ;
-- * C13 une ligne `recue` gardee pour suivi, du meme courriel et du meme cote,
--   DEVIENT la candidature de la personne qui s'inscrit (meme identifiant,
--   provenance import, transition 5 tracee) ; rattachee par la direction
--   (telephone), elle est retiree : la personne est inscrite ;
-- * C14 audit : les listes laissent une ligne bornee a leur cote (convention
--   candidatures_liste de CAND-L1), la tentative hors portee d'un geste est
--   tracee du cote vise (CAND-L2A1, C15) ; les lignes d'audit de l'import ne
--   portent que des compteurs ;
-- * C15 capacites : capacites_candidatures() est redefinie (corps de CAND-L2A2) :
--   peutImporter, doubleVerificationRequise, trois gestes, deux listes fermees ;
-- * C16 accord WhatsApp : la reponse de la personne (formulaire, colonne M) est
--   gardee avec sa reponse importee et MONTREE par la liste des personnes a
--   prevenir (accordWhatsapp) ; elle ne la filtre pas, le directeur n'ayant pas
--   tranche (spec 0.2 bis).
--
-- Hors de ce lot :
-- * inviter (transition 3), l'expiration d'une invitation (4), la reprise des
--   invitations deja emises et des comptes pending_kyc sans candidature, le retrait
--   du code des invitations rendues a la direction, l'action groupee de
--   consigner_prevenu (le lot de CAND-L2A2 la refuse) : avec la file des courriels
--   (L5) et le client ;
-- * la conservation, l'anonymisation et l'export des reponses importees (y compris
--   de qui ne s'inscrit jamais), des accords, des lots, du journal et des choix
--   (CAND-BR-14, CAND-Q21, spec 8.4) ;
-- * un captcha (supabase/config.toml) et enable_confirmations : configuration
--   d'authentification, non touchee.
BEGIN;

-- ============================================================
-- 1. Reglages de l'inscription publique (app_config) et langue
-- ============================================================

-- Trois reglages de l'administration (journalises comme tout app_config). La
-- cle de mise en ligne est FAUSSE par defaut (spec 3.1, condition 6) : tant
-- qu'elle l'est, l'inscription sans code est refusee en base.
INSERT INTO public.app_config (key, value) VALUES
  ('candidatures.inscription_publique_ouverte', 'false'::jsonb),
  ('candidatures.inscriptions_par_heure', '60'::jsonb),
  ('candidatures.confidentialite_version', '"2026-10-v1"'::jsonb)
ON CONFLICT (key) DO NOTHING;

-- Un reglage mal forme ne s'enregistre pas : un booleen, un entier de 1 a
-- 10000, une version de la forme 2026-10-v1. Les autres cles ne sont pas
-- touchees (meme motif que private.pe_valider_responsable).
CREATE FUNCTION private.inscription_reglages_valider()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF NEW.key = 'candidatures.inscription_publique_ouverte' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'boolean' THEN
      RAISE EXCEPTION 'reglage des candidatures : un booleen est attendu' USING ERRCODE = '22023';
    END IF;
  ELSIF NEW.key = 'candidatures.inscriptions_par_heure' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'number'
       OR (NEW.value #>> '{}') !~ '^[1-9][0-9]{0,4}$'
       OR (NEW.value #>> '{}')::integer > 10000 THEN
      RAISE EXCEPTION 'reglage des candidatures : un entier de 1 a 10000 est attendu' USING ERRCODE = '22023';
    END IF;
  ELSIF NEW.key = 'candidatures.confidentialite_version' THEN
    IF pg_catalog.jsonb_typeof(NEW.value) IS DISTINCT FROM 'string'
       OR (NEW.value #>> '{}') !~ '^[0-9]{4}-[0-9]{2}-v[0-9]{1,3}$' THEN
      RAISE EXCEPTION 'reglage des candidatures : une version de la forme 2026-10-v1 est attendue'
        USING ERRCODE = '22023';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER app_config_inscription_candidats
  BEFORE INSERT OR UPDATE ON public.app_config
  FOR EACH ROW EXECUTE FUNCTION private.inscription_reglages_valider();

-- La langue de l'interface au moment de l'inscription (prerequis L3 du contrat
-- de la file des courriels, section 9). Nulle pour les lignes sans compte et
-- pour les candidatures nees avant ce lot ; non nulle pour toute candidature
-- creee par inscrire_candidat.
ALTER TABLE public.candidatures
  ADD COLUMN langue text NULL CHECK (langue IN ('fr', 'ar'));
COMMENT ON COLUMN public.candidatures.langue IS
  'CAND-L3 : langue de l interface choisie a l inscription (fr ou ar), pour les courriels de la file (L5) ; '
  'jamais deduite.';

-- ============================================================
-- 2. Tables
-- ============================================================

-- L'accord de confidentialite, a la version acceptee et a sa date (spec 3.1,
-- condition 5). Ajout seul. Une table a part : contract_acceptances est lue
-- par la garde d'activation d'un enseignant, et un accord de plus y serait
-- un contrat de plus a exiger. La cle vers le profil est RESTRICT, comme celle
-- du journal des candidatures (CAND-L1, C1) : une cascade buterait de toute facon
-- sur le declencheur d'ajout seul ; le blocage est explicite (23503) et c'est
-- l'anonymisation du compte (CAND-BR-14) qui devra traiter cette table.
CREATE TABLE public.candidat_accords_confidentialite (
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  version text NOT NULL CHECK (version ~ '^[0-9]{4}-[0-9]{2}-v[0-9]{1,3}$'),
  porte text NOT NULL CHECK (porte IN ('lien_public', 'invitation')),
  accepte_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  PRIMARY KEY (profile_id, version)
);
CREATE TRIGGER candidat_accords_confidentialite_ajout_seul
  BEFORE UPDATE OR DELETE ON public.candidat_accords_confidentialite
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();

-- Le compteur du plafond horaire : une ligne par inscription publique reussie.
-- Sans nom ni profil : seul l'instant compte.
CREATE TABLE private.inscriptions_publiques (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX inscriptions_publiques_cree_le_idx ON private.inscriptions_publiques (cree_le);

-- Les indicatifs telephoniques reconnus (UIT, sans les sous-zones du plan
-- nord-americain) : un indicatif absent d'ici n'est jamais devine, le numero
-- reste « indicatif a confirmer » (MAPPAGE 4). Sans prefixe l'un de l'autre.
CREATE TABLE private.indicatifs_telephoniques (
  indicatif text PRIMARY KEY CHECK (indicatif ~ '^[1-9][0-9]{0,2}$')
);
INSERT INTO private.indicatifs_telephoniques (indicatif)
SELECT i FROM pg_catalog.unnest(ARRAY[
  '1', '7',
  '20', '27', '30', '31', '32', '33', '34', '36', '39', '40', '41', '43', '44', '45', '46', '47', '48', '49',
  '51', '52', '53', '54', '55', '56', '57', '58', '60', '61', '62', '63', '64', '65', '66',
  '81', '82', '84', '86', '90', '91', '92', '93', '94', '95', '98',
  '211', '212', '213', '216', '218',
  '220', '221', '222', '223', '224', '225', '226', '227', '228', '229', '230', '231', '232', '233', '234',
  '235', '236', '237', '238', '239', '240', '241', '242', '243', '244', '245', '246', '247', '248', '249',
  '250', '251', '252', '253', '254', '255', '256', '257', '258',
  '260', '261', '262', '263', '264', '265', '266', '267', '268', '269',
  '290', '291', '297', '298', '299',
  '350', '351', '352', '353', '354', '355', '356', '357', '358', '359',
  '370', '371', '372', '373', '374', '375', '376', '377', '378', '380', '381', '382', '383', '385', '386',
  '387', '389', '420', '421', '423',
  '500', '501', '502', '503', '504', '505', '506', '507', '508', '509',
  '590', '591', '592', '593', '594', '595', '596', '597', '598', '599',
  '670', '672', '673', '674', '675', '676', '677', '678', '679', '680', '681', '682', '683', '685', '686',
  '687', '688', '689', '690', '691', '692',
  '850', '852', '853', '855', '856', '880', '886',
  '960', '961', '962', '963', '964', '965', '966', '967', '968', '970', '971', '972', '973', '974', '975',
  '976', '977', '992', '993', '994', '995', '996', '998'
]) AS i;

-- Les en-tetes des formulaires (MAPPAGE 2), reconnus par leur texte normalise
-- et jamais par leur position. Un en-tete est reconnu s'il COMMENCE par la
-- phrase (un point d'interrogation ou un emoji en fin n'y change rien).
CREATE TABLE private.formulaires_entetes (
  champ text NOT NULL CHECK (champ IN ('horodatage', 'genre', 'nom', 'telephone', 'langueMaternelle',
    'languesExplication', 'memorisation', 'ijaza', 'experience', 'creneaux', 'heures', 'debut', 'whatsapp',
    'courriel')),
  phrase text NOT NULL CHECK (pg_catalog.length(phrase) >= 4),
  PRIMARY KEY (champ, phrase)
);

-- Les libelles d'options des formulaires (MAPPAGE 3), normalises comme les
-- en-tetes. valeur nulle : le libelle est connu mais n'a pas d'equivalent
-- (jamais devine) ; avertissement : le code rendu a la direction.
CREATE TABLE private.formulaires_libelles (
  champ text NOT NULL CHECK (champ IN ('genre', 'langue', 'memorisation', 'ijaza', 'experience', 'debut')),
  libelle text NOT NULL CHECK (pg_catalog.length(libelle) >= 1),
  valeur text NULL,
  avertissement text NULL CHECK (avertissement ~ '^[a-z][a-z0-9_]{2,59}$'),
  PRIMARY KEY (champ, libelle)
);

-- Un lot d'import : un par confirmation (cle d'idempotence), en ajout seul.
-- Ni nom, ni contact, ni reponse : des compteurs et le rapport ligne par
-- ligne (reference source, issue), comme candidature_lots.
CREATE TABLE public.formulaires_lots (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  cle text NOT NULL UNIQUE CHECK (pg_catalog.length(cle) BETWEEN 8 AND 200),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  classeur text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(classeur)) BETWEEN 1 AND 200),
  onglet text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(onglet)) BETWEEN 1 AND 200),
  empreinte text NOT NULL CHECK (empreinte ~ '^[0-9a-f]{32}$'),
  compteurs jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(compteurs) = 'object'),
  rapport jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(rapport) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE TRIGGER formulaires_lots_ajout_seul
  BEFORE UPDATE OR DELETE ON public.formulaires_lots
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();

-- Les reponses importees des formulaires : une ligne par reference source
-- (classeur, onglet, horodatage tel qu'ecrit dans le fichier). Jamais une
-- candidature, un compte, une invitation, une piece ni un accord (spec 3.2).
-- Le genre est celui que la personne a declare : il borne la lecture de la
-- direction comme celui d'une candidature.
CREATE TABLE public.formulaires_reponses (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  reference_source text NOT NULL UNIQUE
    CHECK (pg_catalog.length(reference_source) BETWEEN 3 AND 500),
  lot_id uuid NOT NULL REFERENCES public.formulaires_lots(id),
  recue_le timestamptz NOT NULL,
  genre public.gender NOT NULL,
  nom_affiche text NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(nom_affiche)) BETWEEN 1 AND 200),
  courriel text NULL
    CHECK (courriel = pg_catalog.lower(pg_catalog.btrim(courriel))
           AND pg_catalog.length(courriel) <= 254
           AND courriel ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
  courriel_brut text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(courriel_brut)) BETWEEN 1 AND 254),
  telephone text NULL CHECK (telephone ~ '^\+[1-9][0-9]{6,14}$'),
  telephone_brut text NULL
    CHECK (pg_catalog.length(pg_catalog.btrim(telephone_brut)) BETWEEN 1 AND 40),
  -- Les reponses converties en codes du questionnaire (MAPPAGE 3) : les seules
  -- que l'on pre-remplit. Jamais les disponibilites, le pays, le paiement.
  reponses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(reponses) = 'object'),
  -- Le libelle des creneaux (colonne J), tel quel, jamais converti (MAPPAGE 3.5).
  creneaux_libelle text NULL CHECK (pg_catalog.length(creneaux_libelle) <= 1000),
  consentement_whatsapp boolean NOT NULL DEFAULT false,
  contenu_empreinte text NOT NULL CHECK (contenu_empreinte ~ '^[0-9a-f]{32}$'),
  etat text NOT NULL DEFAULT 'active' CHECK (etat IN ('active', 'historique')),
  remplacee_par uuid NULL REFERENCES public.formulaires_reponses(id),
  -- La candidature `recue` que la direction a gardee pour suivre cette ligne.
  suivi_id uuid NULL REFERENCES public.candidatures(id),
  -- La candidature de la personne, une fois rattachee.
  candidature_id uuid NULL REFERENCES public.candidatures(id),
  rattachement text NULL CHECK (rattachement IN ('courriel', 'telephone')),
  rattachee_le timestamptz NULL,
  prerempli_champs text[] NULL,
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  modifie_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT formulaires_reponses_un_courriel CHECK (courriel IS NULL OR courriel_brut IS NULL),
  CONSTRAINT formulaires_reponses_un_telephone CHECK (telephone IS NULL OR telephone_brut IS NULL),
  CONSTRAINT formulaires_reponses_rattachement_complet CHECK (
    (candidature_id IS NULL) = (rattachement IS NULL) AND (candidature_id IS NULL) = (rattachee_le IS NULL)),
  -- Une ligne en historique a ete remplacee par une plus recente et ne porte
  -- aucun usage : ni suivi, ni rattachement (spec 3.2, CAND-Q16).
  CONSTRAINT formulaires_reponses_historique CHECK (
    (etat = 'historique') = (remplacee_par IS NOT NULL)
    AND (etat = 'active' OR (suivi_id IS NULL AND candidature_id IS NULL)))
);
CREATE UNIQUE INDEX formulaires_reponses_candidature_uidx
  ON public.formulaires_reponses (candidature_id) WHERE candidature_id IS NOT NULL;
CREATE UNIQUE INDEX formulaires_reponses_suivi_uidx
  ON public.formulaires_reponses (suivi_id) WHERE suivi_id IS NOT NULL;
CREATE INDEX formulaires_reponses_courriel_idx
  ON public.formulaires_reponses (courriel) WHERE courriel IS NOT NULL AND etat = 'active';
CREATE INDEX formulaires_reponses_telephone_idx
  ON public.formulaires_reponses (telephone) WHERE telephone IS NOT NULL AND etat = 'active';
CREATE INDEX formulaires_reponses_genre_idx ON public.formulaires_reponses (genre, etat, recue_le DESC);

-- Le journal des reponses importees, en ajout seul : import, correction sur la
-- meme reference, passage en historique, rattachement, proposition, suivi.
-- Jamais un nom, un contact ni une reponse : des identifiants et des codes.
CREATE TABLE public.formulaires_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  reponse_id uuid NOT NULL REFERENCES public.formulaires_reponses(id),
  type text NOT NULL CHECK (type IN ('import', 'correction', 'historique', 'reactivation', 'suivi',
    'proposition', 'rattachement')),
  lot_id uuid NULL REFERENCES public.formulaires_lots(id),
  auteur_id uuid NULL REFERENCES public.profiles(id),
  details jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (pg_catalog.jsonb_typeof(details) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX formulaires_journal_reponse_idx ON public.formulaires_journal (reponse_id, cree_le DESC, id DESC);
CREATE TRIGGER formulaires_journal_ajout_seul
  BEFORE UPDATE OR DELETE ON public.formulaires_journal
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();

-- Le choix de la direction pour un groupe de doublons (« distinctes », ou la
-- reference retenue), garde sous l'identifiant du groupe (l'empreinte de ses
-- references : qui change des qu'un membre s'ajoute). Il s'applique a tout
-- import ou le meme groupe reparait : un fichier corrige qui se rejoue ne
-- defait pas ce que la direction a decide. Aucune donnee personnelle.
CREATE TABLE public.formulaires_choix_doublons (
  groupe text PRIMARY KEY CHECK (groupe ~ '^[0-9a-f]{12}$'),
  retenue text NOT NULL CHECK (pg_catalog.length(retenue) BETWEEN 3 AND 500),
  lot_id uuid NOT NULL REFERENCES public.formulaires_lots(id),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

-- Les rapprochements proposes a la direction (spec 3.4) : un meme telephone
-- normalise, jamais un courriel (le courriel confirme rattache seul). La
-- personne ne voit rien de cela.
CREATE TABLE public.formulaires_rapprochements (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  reponse_id uuid NOT NULL REFERENCES public.formulaires_reponses(id),
  candidature_id uuid NOT NULL REFERENCES public.candidatures(id),
  cle text NOT NULL CHECK (cle = 'telephone'),
  statut text NOT NULL DEFAULT 'proposee' CHECK (statut IN ('proposee', 'appliquee')),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  applique_le timestamptz NULL,
  applique_par uuid NULL REFERENCES public.profiles(id),
  CONSTRAINT formulaires_rapprochements_unique UNIQUE (reponse_id, candidature_id),
  CONSTRAINT formulaires_rapprochements_application CHECK (
    (statut = 'appliquee') = (applique_le IS NOT NULL) AND (statut = 'appliquee' OR applique_par IS NULL))
);
CREATE INDEX formulaires_rapprochements_candidature_idx ON public.formulaires_rapprochements (candidature_id);

ALTER TABLE public.candidat_accords_confidentialite ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.inscriptions_publiques ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.indicatifs_telephoniques ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.formulaires_entetes ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.formulaires_libelles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formulaires_lots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formulaires_reponses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formulaires_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formulaires_choix_doublons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.formulaires_rapprochements ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.candidat_accords_confidentialite, private.inscriptions_publiques,
  private.indicatifs_telephoniques, private.formulaires_entetes, private.formulaires_libelles,
  public.formulaires_lots, public.formulaires_reponses, public.formulaires_journal,
  public.formulaires_rapprochements, public.formulaires_choix_doublons
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON SEQUENCE public.formulaires_journal_id_seq, private.inscriptions_publiques_id_seq
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.candidat_accords_confidentialite IS
  'CAND-L3 : accord de confidentialite de chaque candidat, a la version acceptee et a sa date (spec 3.1, '
  'condition 5), en ajout seul ; aucune policy. Conservation : CAND-Q21.';
COMMENT ON TABLE private.inscriptions_publiques IS
  'CAND-L3 : une ligne par inscription publique reussie, pour le plafond par heure ; aucun nom ni profil.';
COMMENT ON TABLE private.indicatifs_telephoniques IS
  'CAND-L3 : indicatifs telephoniques reconnus a l import ; un indicatif absent n est jamais devine.';
COMMENT ON TABLE private.formulaires_entetes IS
  'CAND-L3 : en-tetes des formulaires reconnus par leur texte normalise (MAPPAGE 2), jamais par la position.';
COMMENT ON TABLE private.formulaires_libelles IS
  'CAND-L3 : libelles d options des formulaires et leur code (MAPPAGE 3) ; valeur nulle = sans equivalent.';
COMMENT ON TABLE public.formulaires_lots IS
  'CAND-L3 : un lot par confirmation d import (cle d idempotence), en ajout seul ; compteurs et rapport sans '
  'nom, contact ni reponse ; aucune policy. Conservation : CAND-Q21.';
COMMENT ON TABLE public.formulaires_reponses IS
  'CAND-L3 : reponses importees des formulaires Google, une par reference source ; jamais une candidature a la '
  'place de la personne (spec 3.2). Genre declare = portee de lecture (CAND-Q07). Aucune policy : lecture par '
  'les RPC de la direction seulement. Conservation : CAND-Q21 (lignes jamais rattachees comprises).';
COMMENT ON TABLE public.formulaires_journal IS
  'CAND-L3 : journal des reponses importees en ajout seul ; ni nom, ni contact, ni reponse.';
COMMENT ON TABLE public.formulaires_choix_doublons IS
  'CAND-L3 : choix de la direction pour un groupe de doublons, sous l identifiant du groupe ; rejoue a chaque import ; '
  'aucune donnee personnelle ; aucune policy.';
COMMENT ON TABLE public.formulaires_rapprochements IS
  'CAND-L3 : rapprochements proposes a la direction (meme telephone normalise, spec 3.4) ; invisibles de la '
  'personne ; aucune policy.';

-- ============================================================
-- 3. Normalisation des contacts, des en-tetes et des libelles
-- ============================================================

-- Chiffres arabo-indiens (٠-٩) et persans (۰-۹) lus comme des chiffres ASCII.
CREATE FUNCTION private.formulaires_chiffres(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.translate(p_texte,
    U&'\0660\0661\0662\0663\0664\0665\0666\0667\0668\0669\06F0\06F1\06F2\06F3\06F4\06F5\06F6\06F7\06F8\06F9',
    '01234567890123456789');
$function$;

-- Le texte d'un en-tete ou d'un libelle, prepare pour la comparaison :
-- minuscules, accents et voyelles breves retires, alif et ya reunis (comme
-- private.cand_normaliser), tatwil, emojis, ponctuation et signes retires
-- (seuls restent les lettres latines et arabes, les chiffres ASCII et l'espace),
-- espaces replies. Le mappage se fait sur ce texte, jamais sur la position.
CREATE FUNCTION private.formulaires_texte(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.btrim(pg_catalog.regexp_replace(
    pg_catalog.regexp_replace(
      private.cand_normaliser(private.formulaires_chiffres(
        pg_catalog.regexp_replace(coalesce(p_texte, ''),
          '[   -     　]', ' ', 'g'))),
      '[^a-z0-9ء-يٮ-ۓ ]', '', 'g'),
    ' +', ' ', 'g'));
$function$;

CREATE FUNCTION private.formulaires_compact(p_texte text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.replace(private.formulaires_texte(p_texte), ' ', '');
$function$;

-- Un courriel (MAPPAGE 4) : espaces retires, minuscules ; une adresse bien
-- formee est la cle de rapprochement, une adresse mal formee se garde brute
-- (courriel a obtenir) et ne sert ni de cle ni d'adresse d'invitation.
CREATE FUNCTION private.formulaires_courriel(p_brut text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_s text := pg_catalog.lower(pg_catalog.regexp_replace(coalesce(p_brut, ''),
    '[[:space:] ​-‏‪-‮⁦-⁩﻿]', '', 'g'));
BEGIN
  IF v_s = '' THEN
    RETURN pg_catalog.jsonb_build_object('courriel', NULL, 'brut', NULL);
  END IF;
  IF pg_catalog.length(v_s) <= 254 AND v_s ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RETURN pg_catalog.jsonb_build_object('courriel', v_s, 'brut', NULL);
  END IF;
  RETURN pg_catalog.jsonb_build_object('courriel', NULL,
    'brut', pg_catalog.left(pg_catalog.btrim(p_brut), 254));
END;
$function$;

-- Un telephone (MAPPAGE 4) : jamais complete, jamais devine.
-- * « + » ou « 00 » puis un indicatif reconnu en tete et 8 a 15 chiffres :
--   normalise en « + » et chiffres ;
-- * sans « + » ni « 00 » : « + » ajoute SEULEMENT si un indicatif reconnu est
--   en tete et que le numero compte 11 a 15 chiffres (le plan nord-americain :
--   11 chiffres exactement, le second de 2 a 9) ; un numero national (il
--   commence par 0), trop court ou trop long reste tel quel ;
-- * un « 0 » national en trop apres l'indicatif est signale et le numero reste
--   tel quel (sauf l'Italie, la Cote d'Ivoire, le Gabon et le Benin, dont les
--   numeros gardent leur 0) ;
-- * une cellule stockee comme nombre (« 9665012345.0 ») est relue comme texte ;
--   une notation scientifique n'est pas relue : le numero reste tel quel.
-- Rend {telephone, brut, avertissements} : un telephone ou un brut, jamais les
-- deux, ou ni l'un ni l'autre pour une cellule vide.
CREATE FUNCTION private.formulaires_telephone(p_brut text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_t text := pg_catalog.btrim(pg_catalog.regexp_replace(coalesce(p_brut, ''),
    '[ ​-‏‪-‮⁦-⁩﻿]', '', 'g'));
  v_s text;
  v_plus boolean;
  v_code text;
  v_nat text;
  v_av text[] := ARRAY[]::text[];
  v_brut jsonb;
BEGIN
  IF v_t = '' THEN
    RETURN pg_catalog.jsonb_build_object('telephone', NULL, 'brut', NULL, 'avertissements', '[]'::jsonb);
  END IF;
  v_brut := pg_catalog.jsonb_build_object('telephone', NULL, 'brut', pg_catalog.left(v_t, 40));
  v_s := private.formulaires_chiffres(v_t);
  v_s := pg_catalog.regexp_replace(v_s, '^([0-9]+)[.][0]+$', '\1');
  v_s := pg_catalog.regexp_replace(v_s, '[ ().-]', '', 'g');
  v_plus := pg_catalog.left(v_s, 1) = '+';
  IF v_plus THEN
    v_s := pg_catalog.substr(v_s, 2);
  END IF;
  IF v_s !~ '^[0-9]+$' THEN
    RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["telephone_illisible"]'::jsonb);
  END IF;
  IF NOT v_plus AND pg_catalog.left(v_s, 2) = '00' THEN
    v_plus := true;
    v_s := pg_catalog.substr(v_s, 3);
  END IF;
  IF NOT v_plus AND pg_catalog.left(v_s, 1) = '0' THEN
    RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["format_national"]'::jsonb);
  END IF;
  SELECT i.indicatif INTO v_code FROM private.indicatifs_telephoniques i
   WHERE pg_catalog.left(v_s, pg_catalog.length(i.indicatif)) = i.indicatif
   ORDER BY pg_catalog.length(i.indicatif) DESC
   LIMIT 1;
  IF v_code IS NULL THEN
    RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["indicatif_inconnu"]'::jsonb);
  END IF;
  IF v_plus THEN
    IF pg_catalog.length(v_s) NOT BETWEEN 8 AND 15 THEN
      RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["longueur_implausible"]'::jsonb);
    END IF;
  ELSE
    IF pg_catalog.length(v_s) NOT BETWEEN 11 AND 15
       OR (v_code = '1' AND (pg_catalog.length(v_s) <> 11 OR pg_catalog.substr(v_s, 2, 1) NOT BETWEEN '2' AND '9')) THEN
      RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["indicatif_a_confirmer"]'::jsonb);
    END IF;
  END IF;
  v_nat := pg_catalog.substr(v_s, pg_catalog.length(v_code) + 1);
  IF pg_catalog.left(v_nat, 1) = '0' AND v_code NOT IN ('39', '225', '241', '229') THEN
    RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["zero_national_en_trop"]'::jsonb);
  END IF;
  IF v_s !~ '^[1-9][0-9]{6,14}$' THEN
    RETURN v_brut || pg_catalog.jsonb_build_object('avertissements', '["longueur_implausible"]'::jsonb);
  END IF;
  RETURN pg_catalog.jsonb_build_object('telephone', '+' || v_s, 'brut', NULL, 'avertissements', pg_catalog.to_jsonb(v_av));
END;
$function$;

-- Un horodatage de formulaire. ISO 8601 (« 2026-10-01 14:03:22 », avec ou sans
-- decalage) ou « JJ/MM/AAAA hh:mm:ss » (le jour d'abord, comme l'export d'un
-- classeur en francais ou en arabe). Sans decalage, l'heure est celle du
-- fuseau donne. Rend null quand le texte ne se lit pas : jamais devine.
CREATE FUNCTION private.formulaires_horodatage(p_texte text, p_fuseau text)
RETURNS timestamptz
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_t text := pg_catalog.btrim(private.formulaires_chiffres(coalesce(p_texte, '')));
  v_m text[];
  v_ts timestamp;
BEGIN
  IF v_t ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}([ T][0-9]{2}:[0-9]{2}(:[0-9]{2}([.][0-9]+)?)?)?(Z|[+-][0-9]{2}(:?[0-9]{2})?)?$' THEN
    IF v_t ~ '(Z|[+-][0-9]{2}(:?[0-9]{2})?)$' AND v_t ~ '[0-9]{2}:[0-9]{2}' THEN
      RETURN v_t::timestamptz;
    END IF;
    v_ts := v_t::timestamp;
    RETURN v_ts AT TIME ZONE p_fuseau;
  END IF;
  v_m := pg_catalog.regexp_match(v_t,
    '^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})(?: +([0-9]{1,2}):([0-9]{2})(?::([0-9]{2}))?)?$');
  IF v_m IS NOT NULL THEN
    v_ts := pg_catalog.make_timestamp(v_m[3]::integer, v_m[2]::integer, v_m[1]::integer,
      coalesce(v_m[4]::integer, 0), coalesce(v_m[5]::integer, 0), coalesce(v_m[6]::integer, 0)::double precision);
    RETURN v_ts AT TIME ZONE p_fuseau;
  END IF;
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  RETURN NULL;
END;
$function$;

-- ------------------------------------------------------------
-- Les en-tetes et les libelles (MAPPAGE 2 et 3), ranges normalises
-- ------------------------------------------------------------
INSERT INTO private.formulaires_entetes (champ, phrase)
SELECT v.champ, private.formulaires_texte(v.phrase)
FROM (VALUES
  ('horodatage', 'Horodateur'),
  ('horodatage', 'Timestamp'),
  ('horodatage', 'الطابع الزمني'),
  ('genre', 'هل أنت'),
  ('nom', 'الاسم الكامل'),
  ('telephone', 'رقم الواتساب مع رمز الدولة'),
  ('langueMaternelle', 'ما هي لغتك الأم'),
  ('languesExplication', 'بأي لغات تستطيع أن تشرح للطالب وتصحح له أخطاءه'),
  ('memorisation', 'ما مستواك في حفظ القرآن'),
  ('ijaza', 'هل تستطيع تقديم شهادة أو إجازة تثبت مستواك عند المقابلة'),
  ('experience', 'هل لديك خبرة في تعليم المبتدئين القراءة'),
  ('creneaux', 'هل تستطيع التدريس في ساعات متأخرة من الليل بتوقيت مكة المكرمة'),
  ('heures', 'كم ساعة في الأسبوع تستطيع التدريس بانتظام'),
  ('debut', 'متى تستطيع أن تبدأ'),
  ('whatsapp', 'أوافق على أن يتصل بي فريق المشروع عبر واتساب'),
  ('courriel', 'البريد الألكتروني')
) AS v(champ, phrase);

-- Genre (3.1) : deux graphies chacune, comparees sans espaces (« ذ كـــــر »).
INSERT INTO private.formulaires_libelles (champ, libelle, valeur)
SELECT 'genre', private.formulaires_compact(v.libelle), v.valeur
FROM (VALUES
  ('ذكر', 'male'), ('ذ كـــــر', 'male'), ('أنثى', 'female'), ('أنـــثــى', 'female')
) AS v(libelle, valeur)
ON CONFLICT DO NOTHING;

-- Langues (3.2, colonnes E et F). Poular, peul et fulfulde : une seule langue,
-- le code poular. « لغة أخرى اكتبها » : le code autre.
INSERT INTO private.formulaires_libelles (champ, libelle, valeur)
SELECT 'langue', private.formulaires_texte(v.libelle), v.valeur
FROM (VALUES
  ('العربية', 'ar'), ('الإنجليزية', 'english'), ('الفرنسية', 'francais'),
  ('الفولاني ـ فولفولدي', 'poular'), ('الفولاني', 'poular'), ('فولفولدي', 'poular'),
  ('peul', 'poular'), ('fulfulde', 'poular'), ('poular', 'poular'), ('ff', 'poular'),
  ('الهاوسا', 'ha'), ('الولوف', 'wo'), ('البشتو', 'ps'), ('الأردية', 'ur'),
  ('السونينكي', 'snk'), ('البامبارا', 'bm'), ('السواحيلية', 'sw'), ('الماندينكا', 'mnk'),
  ('الأورومو', 'om'), ('الأمهرية', 'am'), ('اليوروبا', 'yo'), ('البنغالية', 'bn'),
  ('الفارسية', 'fa'), ('الإندونيسية', 'id'), ('الصومالية', 'so'), ('الهندية', 'hi'),
  ('الأوزبكية', 'uz'), ('التركية', 'tr'), ('الألمانية', 'de'), ('البرتغالية', 'pt'),
  ('الروسية', 'ru'), ('لغة أخرى اكتبها', 'autre')
) AS v(libelle, valeur)
ON CONFLICT DO NOTHING;

-- Memorisation (3.3). L'ijaza n'est pas une quantite memorisee : aucune valeur,
-- la personne repond (jamais le Coran entier a sa place).
INSERT INTO private.formulaires_libelles (champ, libelle, valeur, avertissement)
SELECT 'memorisation', private.formulaires_texte(v.libelle), v.valeur, v.avertissement
FROM (VALUES
  ('حفظت القرآن كله', 'coran_entier', NULL),
  ('عندي إجازة قراءة وإقراء', NULL, 'ijaza_declaree_en_g'),
  ('حفظت أكثر من 10 أجزاء', 'de_10_a_29_juz', NULL),
  ('حفظت أقل من 10 أجزاء', 'moins_10_juz', NULL),
  ('لم أحفظ، لكنني أقرأ القرآن قراءة جيدة بالتجويد', 'aucune', NULL)
) AS v(libelle, valeur, avertissement)
ON CONFLICT DO NOTHING;

-- Ijaza presentable (3.4, colonne H) et experience avec les debutants
-- (colonne I) : l'option « pret a un test » de la colonne I n'a pas
-- d'equivalent (oui ou non seulement) et ne pre-remplit rien.
INSERT INTO private.formulaires_libelles (champ, libelle, valeur, avertissement)
SELECT v.champ, private.formulaires_texte(v.libelle), v.valeur, v.avertissement
FROM (VALUES
  ('ijaza', 'نعم', 'oui', NULL),
  ('ijaza', 'لا', 'non', NULL),
  ('ijaza', 'لا، لكني مستعد لإجراء اختبار لتحديد المستوى', 'pret_test', NULL),
  ('experience', 'نعم', 'oui', NULL),
  ('experience', 'لا', 'non', NULL),
  ('experience', 'لا، لكني مستعد لإجراء اختبار لتحديد المستوى', NULL, 'experience_pret_test_sans_equivalent')
) AS v(champ, libelle, valeur, avertissement)
ON CONFLICT DO NOTHING;

-- Debut possible (3.6, colonne L).
INSERT INTO private.formulaires_libelles (champ, libelle, valeur)
SELECT 'debut', private.formulaires_texte(v.libelle), v.valeur
FROM (VALUES
  ('يمكن لي البدء فورا', 'immediat'), ('في الشهر القادم', 'mois_prochain'),
  ('خلال 3 أشهر', 'sous_3_mois'), ('لا أعرف بعد', 'inconnu')
) AS v(libelle, valeur)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 4. Lecture d'un export (analyse serveur, MAPPAGE 2 a 5)
-- ============================================================

-- Les heures par semaine de la colonne K, converties en classes souhaitees
-- (MAPPAGE 3.6 : la borne basse). Rend {valeur, avertissement}.
CREATE FUNCTION private.formulaires_classes(p_cellule text)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_t text := private.formulaires_texte(p_cellule);
  v_n text[];
BEGIN
  IF v_t = '' THEN
    RETURN pg_catalog.jsonb_build_object('valeur', NULL, 'avertissement', NULL);
  END IF;
  SELECT pg_catalog.array_agg(m[1] ORDER BY o) INTO v_n
    FROM pg_catalog.regexp_matches(v_t, '([0-9]+)', 'g') WITH ORDINALITY AS x(m, o);
  IF v_t LIKE 'اقل من%' AND v_n = ARRAY['3'] THEN
    RETURN pg_catalog.jsonb_build_object('valeur', NULL, 'avertissement', 'moins_de_3_heures');
  ELSIF v_t LIKE 'اكثر من%' AND v_n = ARRAY['10'] THEN
    RETURN pg_catalog.jsonb_build_object('valeur', '3', 'avertissement', NULL);
  ELSIF v_n = ARRAY['3', '5'] THEN
    RETURN pg_catalog.jsonb_build_object('valeur', '1', 'avertissement', NULL);
  ELSIF v_n = ARRAY['6', '10'] THEN
    RETURN pg_catalog.jsonb_build_object('valeur', '2', 'avertissement', NULL);
  END IF;
  RETURN pg_catalog.jsonb_build_object('valeur', NULL, 'avertissement', 'libelle_inconnu_heures');
END;
$function$;

-- Une option de liste (libelles de MAPPAGE 3) : {valeur, avertissement}.
CREATE FUNCTION private.formulaires_option(p_champ text, p_cellule text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_cle text := CASE WHEN p_champ = 'genre' THEN private.formulaires_compact(p_cellule)
                     ELSE private.formulaires_texte(p_cellule) END;
  v_l private.formulaires_libelles;
BEGIN
  IF v_cle = '' THEN
    RETURN pg_catalog.jsonb_build_object('valeur', NULL, 'avertissement', NULL);
  END IF;
  SELECT l.* INTO v_l FROM private.formulaires_libelles l WHERE l.champ = p_champ AND l.libelle = v_cle;
  IF v_l.champ IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('valeur', NULL, 'avertissement', 'libelle_inconnu_' || p_champ);
  END IF;
  RETURN pg_catalog.jsonb_build_object('valeur', v_l.valeur, 'avertissement', v_l.avertissement);
END;
$function$;

-- Lit l'export : en-tetes reconnus par leur texte, une ligne normalisee par
-- ligne de donnees (la ligne 1 est l'en-tete). Aucune ecriture, aucune
-- lecture de la base hors des tables de libelles. Rend
-- {erreur} ou {entetes, lignes}. Une ligne porte ses donnees (nom, contacts,
-- reponses converties) : seules les fonctions de ce module la lisent, et
-- l'apercu en retire tout ce qui identifie.
CREATE FUNCTION private.formulaires_lire(p_csv text, p_classeur text, p_onglet text, p_mappage jsonb,
                                         p_fuseau text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_rows jsonb;
  v_head jsonb;
  v_pos jsonb := '{}'::jsonb;
  v_entetes jsonb := '[]'::jsonb;
  v_doubles text[] := ARRAY[]::text[];
  v_manquants text[] := ARRAY[]::text[];
  v_champs constant text[] := ARRAY['horodatage', 'genre', 'nom', 'telephone', 'langueMaternelle',
    'languesExplication', 'memorisation', 'ijaza', 'experience', 'creneaux', 'heures', 'debut', 'whatsapp',
    'courriel'];
  v_champ text;
  v_norm text;
  v_k text;
  v_v jsonb;
  v_p integer;
  i integer;
  j integer;
  v_ncol integer;
  v_row jsonb;
  v_lignes jsonb := '[]'::jsonb;
  v_vues jsonb := '{}'::jsonb;
  -- une ligne
  v_h text;
  v_ts timestamptz;
  v_genre text;
  v_nom text;
  v_tel jsonb;
  v_mail jsonb;
  v_rep jsonb;
  v_av text[];
  v_mo text[];
  v_o jsonb;
  v_cell text;
  v_piece text;
  v_langues text[];
  v_creneaux text;
  v_crenx text;
  v_wa boolean;
  v_ref text;
  v_empreinte text;
  v_issue text;
  v_obj jsonb;
BEGIN
  IF p_fuseau IS NULL OR NOT EXISTS (SELECT 1 FROM pg_catalog.pg_timezone_names z WHERE z.name = p_fuseau) THEN
    RAISE EXCEPTION 'fuseau des horodatages inconnu' USING ERRCODE = '22023';
  END IF;
  BEGIN
    v_rows := private.parse_import_csv(p_csv);
  EXCEPTION WHEN SQLSTATE '22023' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'fichier_illisible', 'cause', SQLERRM);
  END;
  IF pg_catalog.jsonb_array_length(v_rows) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'fichier_vide');
  END IF;
  v_head := v_rows -> 0;
  v_ncol := pg_catalog.jsonb_array_length(v_head);

  -- En-tetes : reconnus par leur texte ; un champ reconnu deux fois est une erreur.
  FOR i IN 0 .. v_ncol - 1 LOOP
    v_norm := private.formulaires_texte(v_head ->> i);
    v_champ := NULL;
    IF v_norm <> '' THEN
      SELECT e.champ INTO v_champ FROM private.formulaires_entetes e
       WHERE pg_catalog.left(v_norm, pg_catalog.length(e.phrase)) = e.phrase
       ORDER BY pg_catalog.length(e.phrase) DESC, e.champ
       LIMIT 1;
    END IF;
    IF v_champ IS NOT NULL THEN
      IF v_pos ? v_champ THEN
        v_doubles := v_doubles || v_champ;
      ELSE
        v_pos := v_pos || pg_catalog.jsonb_build_object(v_champ, i + 1);
      END IF;
    END IF;
  END LOOP;

  -- Association manuelle (position 1-based -> champ, ou null pour ignorer).
  IF p_mappage IS NOT NULL THEN
    IF pg_catalog.jsonb_typeof(p_mappage) <> 'object' THEN
      RAISE EXCEPTION 'mappage invalide : un objet position -> champ est attendu' USING ERRCODE = '22023';
    END IF;
    FOR v_k, v_v IN SELECT * FROM pg_catalog.jsonb_each(p_mappage) LOOP
      IF v_k !~ '^[0-9]{1,3}$' OR v_k::integer NOT BETWEEN 1 AND v_ncol
         OR (pg_catalog.jsonb_typeof(v_v) NOT IN ('string', 'null'))
         OR (pg_catalog.jsonb_typeof(v_v) = 'string' AND NOT ((v_v #>> '{}') = ANY (v_champs))) THEN
        RAISE EXCEPTION 'mappage invalide : position ou champ inconnu' USING ERRCODE = '22023';
      END IF;
      v_p := v_k::integer;
      -- La position est reaffectee : on retire ce que l'auto-detection y avait mis.
      FOR v_champ IN SELECT k FROM pg_catalog.jsonb_object_keys(v_pos) AS k LOOP
        IF (v_pos ->> v_champ)::integer = v_p THEN
          v_pos := v_pos - v_champ;
        END IF;
      END LOOP;
      IF pg_catalog.jsonb_typeof(v_v) = 'string' THEN
        v_pos := (v_pos - (v_v #>> '{}')) || pg_catalog.jsonb_build_object(v_v #>> '{}', v_p);
      END IF;
    END LOOP;
    v_doubles := ARRAY[]::text[];
  END IF;

  FOR i IN 0 .. v_ncol - 1 LOOP
    v_champ := NULL;
    FOR v_k IN SELECT k FROM pg_catalog.jsonb_object_keys(v_pos) AS k LOOP
      IF (v_pos ->> v_k)::integer = i + 1 THEN
        v_champ := v_k;
      END IF;
    END LOOP;
    v_entetes := v_entetes || pg_catalog.jsonb_build_array(
      pg_catalog.jsonb_build_object('position', i + 1, 'champ', v_champ));
  END LOOP;
  IF pg_catalog.cardinality(v_doubles) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'entetes_ambigus',
      'champs', (SELECT pg_catalog.jsonb_agg(DISTINCT d) FROM pg_catalog.unnest(v_doubles) AS d),
      'entetes', v_entetes);
  END IF;
  FOREACH v_champ IN ARRAY ARRAY['horodatage', 'genre', 'nom'] LOOP
    IF NOT v_pos ? v_champ THEN
      v_manquants := v_manquants || v_champ;
    END IF;
  END LOOP;
  IF NOT (v_pos ? 'telephone' OR v_pos ? 'courriel') THEN
    v_manquants := v_manquants || 'contact'::text;
  END IF;
  IF pg_catalog.cardinality(v_manquants) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'mappage_incomplet',
      'champs', pg_catalog.to_jsonb(v_manquants), 'entetes', v_entetes);
  END IF;

  -- Les lignes de donnees.
  FOR i IN 1 .. pg_catalog.jsonb_array_length(v_rows) - 1 LOOP
    v_row := v_rows -> i;
    v_av := ARRAY[]::text[];
    v_mo := ARRAY[]::text[];
    v_rep := '{}'::jsonb;

    -- Une cellule de la ligne, par champ (nulle si vide ou absente).
    v_h := nullif(pg_catalog.btrim(v_row ->> ((v_pos ->> 'horodatage')::integer - 1)), '');
    v_ts := private.formulaires_horodatage(v_h, p_fuseau);
    v_nom := nullif(pg_catalog.btrim(pg_catalog.regexp_replace(
      coalesce(v_row ->> ((v_pos ->> 'nom')::integer - 1), ''), '[[:space:] ]+', ' ', 'g')), '');
    v_o := private.formulaires_option('genre', v_row ->> ((v_pos ->> 'genre')::integer - 1));
    v_genre := v_o ->> 'valeur';
    v_tel := private.formulaires_telephone(
      CASE WHEN v_pos ? 'telephone' THEN v_row ->> ((v_pos ->> 'telephone')::integer - 1) END);
    v_mail := private.formulaires_courriel(
      CASE WHEN v_pos ? 'courriel' THEN v_row ->> ((v_pos ->> 'courriel')::integer - 1) END);

    IF v_nom IS NULL AND v_tel ->> 'telephone' IS NULL AND v_tel ->> 'brut' IS NULL
       AND v_mail ->> 'courriel' IS NULL AND v_mail ->> 'brut' IS NULL THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'n', i + 1, 'issue_lecture', 'ignoree', 'motifs', '["ligne_vide"]'::jsonb, 'avertissements', '[]'::jsonb));
      CONTINUE;
    END IF;

    IF v_h IS NULL OR v_ts IS NULL THEN v_mo := v_mo || 'horodatage_illisible'::text; END IF;
    IF v_genre IS NULL THEN v_mo := v_mo || 'genre_illisible'::text; END IF;
    IF v_nom IS NULL THEN v_mo := v_mo || 'nom_absent'::text;
    ELSIF pg_catalog.length(v_nom) > 200 THEN v_mo := v_mo || 'nom_trop_long'::text; END IF;

    -- Contacts : les avertissements du telephone, un courriel mal forme.
    IF v_tel -> 'avertissements' <> '[]'::jsonb THEN
      v_av := v_av || ARRAY(SELECT pg_catalog.jsonb_array_elements_text(v_tel -> 'avertissements'));
    END IF;
    IF v_mail ->> 'brut' IS NOT NULL THEN v_av := v_av || 'courriel_malforme'::text; END IF;

    -- Langue maternelle (E) : un libelle inconnu devient « autre langue ».
    IF v_pos ? 'langueMaternelle' THEN
      v_cell := nullif(pg_catalog.btrim(v_row ->> ((v_pos ->> 'langueMaternelle')::integer - 1)), '');
      IF v_cell IS NOT NULL THEN
        v_o := private.formulaires_option('langue', v_cell);
        IF v_o ->> 'valeur' IS NULL THEN
          v_rep := v_rep || pg_catalog.jsonb_build_object('langueMaternelle', 'autre');
          v_av := v_av || 'langue_maternelle_vers_autre'::text;
        ELSE
          v_rep := v_rep || pg_catalog.jsonb_build_object('langueMaternelle', v_o ->> 'valeur');
        END IF;
      END IF;
    END IF;

    -- Langues d'explication (F) : decoupees selon la liste d'options, l'arabe
    -- retire (pas une langue de cours), poular unique, aucun plafond.
    IF v_pos ? 'languesExplication' THEN
      v_cell := nullif(pg_catalog.btrim(v_row ->> ((v_pos ->> 'languesExplication')::integer - 1)), '');
      v_langues := ARRAY[]::text[];
      IF v_cell IS NOT NULL THEN
        FOR v_piece IN SELECT pg_catalog.btrim(x) FROM pg_catalog.regexp_split_to_table(v_cell, '[,،;]') AS x LOOP
          CONTINUE WHEN pg_catalog.btrim(v_piece) = '';
          v_o := private.formulaires_option('langue', v_piece);
          IF v_o ->> 'valeur' IS NULL THEN
            v_o := pg_catalog.jsonb_build_object('valeur', 'autre');
            v_av := v_av || 'langue_inconnue_vers_autre'::text;
          END IF;
          IF v_o ->> 'valeur' = 'ar' THEN
            v_av := v_av || 'arabe_retire'::text;
          ELSIF NOT ((v_o ->> 'valeur') = ANY (v_langues)) THEN
            v_langues := v_langues || (v_o ->> 'valeur');
          END IF;
        END LOOP;
        IF pg_catalog.cardinality(v_langues) > 0 THEN
          v_rep := v_rep || pg_catalog.jsonb_build_object('languesExplication', pg_catalog.to_jsonb(v_langues));
        END IF;
      END IF;
    END IF;

    -- Memorisation (G), ijaza presentable (H), experience (I), debut (L).
    FOREACH v_champ IN ARRAY ARRAY['memorisation', 'ijaza', 'experience', 'debut'] LOOP
      CONTINUE WHEN NOT v_pos ? v_champ;
      v_cell := nullif(pg_catalog.btrim(v_row ->> ((v_pos ->> v_champ)::integer - 1)), '');
      CONTINUE WHEN v_cell IS NULL;
      v_o := private.formulaires_option(v_champ, v_cell);
      IF v_o ->> 'avertissement' IS NOT NULL THEN v_av := v_av || (v_o ->> 'avertissement'); END IF;
      IF v_o ->> 'valeur' IS NOT NULL THEN
        v_rep := v_rep || pg_catalog.jsonb_build_object(
          CASE v_champ WHEN 'memorisation' THEN 'niveauMemorisationDeclare' WHEN 'ijaza' THEN 'ijazaPresentable'
                       WHEN 'experience' THEN 'experienceDebutants' ELSE 'debutPossible' END,
          v_o ->> 'valeur');
      END IF;
    END LOOP;

    -- Heures par semaine (K) : classes souhaitees (borne basse).
    IF v_pos ? 'heures' THEN
      v_o := private.formulaires_classes(v_row ->> ((v_pos ->> 'heures')::integer - 1));
      IF v_o ->> 'avertissement' IS NOT NULL THEN v_av := v_av || (v_o ->> 'avertissement'); END IF;
      IF v_o ->> 'valeur' IS NOT NULL THEN
        v_rep := v_rep || pg_catalog.jsonb_build_object('classesSouhaitees', v_o ->> 'valeur');
      END IF;
    END IF;

    -- Creneaux (J) : le libelle tel quel, jamais converti ni lu comme une
    -- disponibilite (MAPPAGE 3.5). Les reponses contradictoires sont signalees.
    v_creneaux := NULL;
    IF v_pos ? 'creneaux' THEN
      v_creneaux := pg_catalog.left(nullif(pg_catalog.btrim(pg_catalog.regexp_replace(
        coalesce(v_row ->> ((v_pos ->> 'creneaux')::integer - 1), ''), '[[:space:]]+', ' ', 'g')), ''), 1000);
      IF v_creneaux IS NOT NULL THEN
        v_crenx := private.formulaires_texte(v_creneaux);
        IF (v_crenx LIKE '%جاهز في اي وقت%' OR v_crenx LIKE '%لا استطيع التدريس بعد%')
           AND (v_crenx ~ '(8|10) مساء' OR v_crenx LIKE '%منتصف الليل%' OR v_crenx ~ '2 صباح') THEN
          v_av := v_av || 'creneaux_contradictoires'::text;
        END IF;
      END IF;
    END IF;

    -- Accord de contact WhatsApp (M) : valable pour ce contact seulement.
    v_wa := v_pos ? 'whatsapp'
            AND private.formulaires_texte(v_row ->> ((v_pos ->> 'whatsapp')::integer - 1)) = 'اوافق';

    v_ref := p_classeur || '|' || p_onglet || '|' || coalesce(v_h, '');
    v_obj := pg_catalog.jsonb_build_object(
      'genre', v_genre, 'nom', v_nom,
      'courriel', v_mail ->> 'courriel', 'courriel_brut', v_mail ->> 'brut',
      'telephone', v_tel ->> 'telephone', 'telephone_brut', v_tel ->> 'brut',
      'reponses', v_rep, 'creneaux', v_creneaux, 'whatsapp', v_wa);
    v_empreinte := pg_catalog.md5(v_obj::text);
    v_issue := CASE WHEN pg_catalog.cardinality(v_mo) > 0 THEN 'a_corriger' ELSE 'ok' END;

    -- Une meme reference deux fois dans le fichier : identique, ignoree ;
    -- differente, a corriger (jamais fusionnee en silence).
    IF v_issue = 'ok' THEN
      IF v_vues ? v_ref THEN
        IF v_vues ->> v_ref = v_empreinte THEN
          v_issue := 'ignoree';
          v_mo := v_mo || 'meme_reference_meme_contenu'::text;
        ELSE
          v_issue := 'a_corriger';
          v_mo := v_mo || 'meme_reference_contenu_different'::text;
        END IF;
      ELSE
        v_vues := v_vues || pg_catalog.jsonb_build_object(v_ref, v_empreinte);
      END IF;
    END IF;

    v_lignes := v_lignes || pg_catalog.jsonb_build_array(v_obj || pg_catalog.jsonb_build_object(
      'n', i + 1, 'issue_lecture', v_issue, 'reference', v_ref,
      'recue_le', CASE WHEN v_ts IS NULL THEN NULL ELSE v_ts::text END,
      'empreinte', v_empreinte,
      'motifs', pg_catalog.to_jsonb(v_mo),
      'avertissements', pg_catalog.to_jsonb(ARRAY(SELECT DISTINCT a FROM pg_catalog.unnest(v_av) AS a ORDER BY a))));
  END LOOP;

  RETURN pg_catalog.jsonb_build_object('entetes', v_entetes, 'lignes', v_lignes);
END;
$function$;

-- ============================================================
-- 5. Plan d'un import : lignes connues, corrigees, doublons
-- ============================================================

-- Compare les lignes lues a ce que la base garde et rend le plan, sans rien
-- ecrire. Pour chaque ligne lue :
-- * ignoree / a_corriger : telles que lues, rien n'est ecrit ;
-- * deja_connue : la personne est deja dans l'import des inscriptions du
--   12/10 (courriel d'un enseignant de private.preinscription_*, MAPPAGE 1,
--   ligne B) ou la reference source existe avec le meme contenu (le fichier
--   rejoue) ; rien n'est ecrit ;
-- * corrigee : la reference source existe avec un autre contenu, la ligne est
--   corrigee sur place (0 reponse nouvelle, une correction tracee) ;
-- * nouvelle : une reference neuve.
-- Doublons (MAPPAGE 5, CAND-Q16) : deux lignes du MEME genre declare qui partagent
-- un courriel valide OU un telephone normalise, jamais un nom, forment un groupe ; la plus
-- recente l'emporte, les autres restent en historique. Une ligne gardee pour
-- suivi ou rattachee a une candidature n'est jamais mise en historique. La
-- direction peut corriger un groupe avant de confirmer : choix = [{groupe,
-- retenue}] ou retenue est une reference source ou « distinctes » (deux
-- personnes qui partagent un contact). Les lignes deja en base participent aux
-- groupes, qu'elles soient ou non dans le fichier.
-- Rend {decisions, mutations, groupes, compteurs} ou {erreur: choix_invalide}.
CREATE FUNCTION private.formulaires_planifier(p_lignes jsonb, p_choix jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_choix jsonb := coalesce(p_choix, '[]'::jsonb);
  v_dec jsonb[] := ARRAY[]::jsonb[];
  v_l jsonb;
  v_s public.formulaires_reponses;
  v_issue text;
  v_mo jsonb;
  i integer;
  j integer;
  -- les participants aux groupes
  v_n integer := 0;
  v_p_ref text[] := ARRAY[]::text[];
  v_p_gen text[] := ARRAY[]::text[];
  v_p_mail text[] := ARRAY[]::text[];
  v_p_tel text[] := ARRAY[]::text[];
  v_p_ts timestamptz[] := ARRAY[]::timestamptz[];
  v_p_pin boolean[] := ARRAY[]::boolean[];
  v_p_dec integer[] := ARRAY[]::integer[];
  v_p_id uuid[] := ARRAY[]::uuid[];
  v_p_etat text[] := ARRAY[]::text[];
  v_p_gagnant text[] := ARRAY[]::text[];
  v_parent integer[] := ARRAY[]::integer[];
  v_cle_mail jsonb := '{}'::jsonb;
  v_cle_tel jsonb := '{}'::jsonb;
  v_membres jsonb;
  v_cx_mail text[] := ARRAY[]::text[];
  v_cx_tel text[] := ARRAY[]::text[];
  v_nouveaux integer;
  v_a integer;
  v_b integer;
  v_k integer;
  v_invalides text[];
  v_finaux jsonb;
  v_groupes jsonb;
  v_mutations jsonb := '[]'::jsonb;
  v_m record;
  v_compteurs jsonb;
BEGIN
  IF p_lignes IS NULL OR pg_catalog.jsonb_typeof(p_lignes) <> 'array'
     OR pg_catalog.jsonb_typeof(v_choix) <> 'array' THEN
    RAISE EXCEPTION 'plan d import : lignes et choix (listes) attendus' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_choix) c
              WHERE pg_catalog.jsonb_typeof(c) <> 'object'
                 OR pg_catalog.jsonb_typeof(c -> 'groupe') IS DISTINCT FROM 'string'
                 OR pg_catalog.jsonb_typeof(c -> 'retenue') IS DISTINCT FROM 'string'
                 OR (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(c)) <> 2) THEN
    RAISE EXCEPTION 'choix de doublons invalide : [{groupe, retenue}] attendu' USING ERRCODE = '22023';
  END IF;

  -- Chaque ligne lue : sa decision, et sa place dans les groupes.
  FOR i IN 0 .. pg_catalog.jsonb_array_length(p_lignes) - 1 LOOP
    v_l := p_lignes -> i;
    v_issue := v_l ->> 'issue_lecture';
    v_mo := v_l -> 'motifs';
    IF v_issue <> 'ok' THEN
      v_dec := v_dec || pg_catalog.jsonb_build_object(
        'n', v_l -> 'n', 'issue', v_issue, 'motifs', v_mo, 'avertissements', v_l -> 'avertissements');
      CONTINUE;
    END IF;
    v_s := NULL;
    -- Deja dans l'import des inscriptions du 12/10 (un enseignant de B).
    IF v_l ->> 'courriel' IS NOT NULL AND EXISTS (
         SELECT 1 FROM private.preinscription_households h
           JOIN private.preinscription_persons pp ON pp.household_id = h.id AND pp.person_kind = 'teacher'
          WHERE h.email_normalise = v_l ->> 'courriel') THEN
      v_dec := v_dec || (v_l || pg_catalog.jsonb_build_object(
        'issue', 'deja_connue', 'motifs', '["inscription_12_10"]'::jsonb));
      CONTINUE;
    END IF;
    SELECT r.* INTO v_s FROM public.formulaires_reponses r WHERE r.reference_source = v_l ->> 'reference';
    IF v_s.id IS NOT NULL THEN
      IF v_s.genre::text IS DISTINCT FROM v_l ->> 'genre'
         AND (v_s.suivi_id IS NOT NULL OR v_s.candidature_id IS NOT NULL) THEN
        v_dec := v_dec || (v_l || pg_catalog.jsonb_build_object(
          'issue', 'a_corriger', 'motifs', '["genre_change_sur_ligne_suivie"]'::jsonb));
        CONTINUE;
      END IF;
      v_issue := CASE WHEN v_s.contenu_empreinte = v_l ->> 'empreinte' THEN 'deja_connue' ELSE 'corrigee' END;
    ELSE
      v_issue := 'nouvelle';
    END IF;
    v_dec := v_dec || (v_l || pg_catalog.jsonb_build_object('issue', v_issue, 'existant_id', v_s.id));
    -- Les contacts et le genre que la base garde AUJOURD'HUI pour cette ligne
    -- amorcent la fermeture ci-dessous, en plus de ceux du fichier : une ligne
    -- corrigee (un courriel, un telephone ou un genre change dans le classeur)
    -- quitte son groupe, et ses voisins, qui ne la touchent plus, doivent etre
    -- relus pour sortir de l'historique ou changer de remplacante.
    IF v_s.id IS NOT NULL THEN
      IF v_s.courriel IS NOT NULL THEN
        v_cx_mail := v_cx_mail || (v_s.genre::text || '|' || v_s.courriel);
      END IF;
      IF v_s.telephone IS NOT NULL THEN
        v_cx_tel := v_cx_tel || (v_s.genre::text || '|' || v_s.telephone);
      END IF;
    END IF;
    -- Participant : les valeurs de la base pour une ligne qui existe (l'instant
    -- et l'usage), celles du fichier pour son contenu.
    v_n := v_n + 1;
    v_p_ref := v_p_ref || (v_l ->> 'reference');
    v_p_gen := v_p_gen || (v_l ->> 'genre');
    v_p_mail := v_p_mail || (v_l ->> 'courriel');
    v_p_tel := v_p_tel || (v_l ->> 'telephone');
    v_p_ts := v_p_ts || CASE WHEN v_s.id IS NOT NULL THEN v_s.recue_le ELSE (v_l ->> 'recue_le')::timestamptz END;
    v_p_pin := v_p_pin || (v_s.id IS NOT NULL AND (v_s.suivi_id IS NOT NULL OR v_s.candidature_id IS NOT NULL));
    v_p_dec := v_p_dec || pg_catalog.cardinality(v_dec);
    v_p_id := v_p_id || v_s.id;
    v_p_etat := v_p_etat || v_s.etat;
    v_p_gagnant := v_p_gagnant || (SELECT rp.reference_source FROM public.formulaires_reponses rp
                                    WHERE rp.id = v_s.remplacee_par);
  END LOOP;

  -- Les lignes deja en base, hors fichier, que des contacts communs (du meme
  -- genre) relient aux lignes du fichier (tels que le fichier les dit, et tels
  -- que la base les gardait avant sa correction), de proche en proche : la
  -- composante entiere, en historique comme en actif. Un groupe incomplet se lirait comme un
  -- groupe plus petit : une ligne mise en historique dont le voisin n'est pas
  -- charge redeviendrait active, et rejouer le meme fichier defairait ce que le
  -- premier import a decide (idempotence).
  v_cx_mail := v_cx_mail || ARRAY(SELECT DISTINCT x.g || '|' || x.m
                                    FROM ROWS FROM (pg_catalog.unnest(v_p_gen), pg_catalog.unnest(v_p_mail)) AS x(g, m)
                                   WHERE x.m IS NOT NULL);
  v_cx_tel := v_cx_tel || ARRAY(SELECT DISTINCT x.g || '|' || x.t
                                  FROM ROWS FROM (pg_catalog.unnest(v_p_gen), pg_catalog.unnest(v_p_tel)) AS x(g, t)
                                 WHERE x.t IS NOT NULL);
  LOOP
    v_nouveaux := 0;
    FOR v_s IN
      SELECT r.* FROM public.formulaires_reponses r
       WHERE NOT (r.reference_source = ANY (v_p_ref))
         AND ((r.courriel IS NOT NULL AND (r.genre::text || '|' || r.courriel) = ANY (v_cx_mail))
              OR (r.telephone IS NOT NULL AND (r.genre::text || '|' || r.telephone) = ANY (v_cx_tel)))
       ORDER BY r.recue_le, r.reference_source
    LOOP
      v_n := v_n + 1;
      v_nouveaux := v_nouveaux + 1;
      v_p_ref := v_p_ref || v_s.reference_source;
      v_p_gen := v_p_gen || v_s.genre::text;
      v_p_mail := v_p_mail || v_s.courriel;
      v_p_tel := v_p_tel || v_s.telephone;
      v_p_ts := v_p_ts || v_s.recue_le;
      v_p_pin := v_p_pin || (v_s.suivi_id IS NOT NULL OR v_s.candidature_id IS NOT NULL);
      v_p_dec := v_p_dec || 0;
      v_p_id := v_p_id || v_s.id;
      v_p_etat := v_p_etat || v_s.etat;
      v_p_gagnant := v_p_gagnant || (SELECT rp.reference_source FROM public.formulaires_reponses rp
                                      WHERE rp.id = v_s.remplacee_par);
      IF v_s.courriel IS NOT NULL THEN
        v_cx_mail := v_cx_mail || (v_s.genre::text || '|' || v_s.courriel);
      END IF;
      IF v_s.telephone IS NOT NULL THEN
        v_cx_tel := v_cx_tel || (v_s.genre::text || '|' || v_s.telephone);
      END IF;
    END LOOP;
    EXIT WHEN v_nouveaux = 0;
  END LOOP;

  -- Les groupes : un contact commun (courriel valide ou telephone normalise).
  v_parent := ARRAY(SELECT g FROM pg_catalog.generate_series(1, v_n) AS g);
  FOR i IN 1 .. v_n LOOP
    FOR j IN 1 .. 2 LOOP
      CONTINUE WHEN (j = 1 AND v_p_mail[i] IS NULL) OR (j = 2 AND v_p_tel[i] IS NULL);
      -- Un contact commun ne relie que les lignes du meme genre declare : un
      -- couple qui partage un telephone, ce sont deux personnes, de deux
      -- cotes (CAND-Q07) ; rien ne traverse.
      IF j = 1 THEN
        v_k := (v_cle_mail ->> (v_p_gen[i] || '|' || v_p_mail[i]))::integer;
        IF v_k IS NULL THEN
          v_cle_mail := v_cle_mail || pg_catalog.jsonb_build_object(v_p_gen[i] || '|' || v_p_mail[i], i);
          CONTINUE;
        END IF;
      ELSE
        v_k := (v_cle_tel ->> (v_p_gen[i] || '|' || v_p_tel[i]))::integer;
        IF v_k IS NULL THEN
          v_cle_tel := v_cle_tel || pg_catalog.jsonb_build_object(v_p_gen[i] || '|' || v_p_tel[i], i);
          CONTINUE;
        END IF;
      END IF;
      v_a := i;
      WHILE v_parent[v_a] <> v_a LOOP v_a := v_parent[v_a]; END LOOP;
      v_b := v_k;
      WHILE v_parent[v_b] <> v_b LOOP v_b := v_parent[v_b]; END LOOP;
      IF v_a <> v_b THEN
        v_parent[GREATEST(v_a, v_b)] := LEAST(v_a, v_b);
      END IF;
    END LOOP;
  END LOOP;
  v_membres := '[]'::jsonb;
  FOR i IN 1 .. v_n LOOP
    v_a := i;
    WHILE v_parent[v_a] <> v_a LOOP v_a := v_parent[v_a]; END LOOP;
    v_membres := v_membres || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'i', i, 'ref', v_p_ref[i], 'mail', v_p_mail[i], 'tel', v_p_tel[i], 'ts', v_p_ts[i], 'pin', v_p_pin[i],
      'd', v_p_dec[i], 'id', v_p_id[i], 'etat', v_p_etat[i], 'gagnant_base', v_p_gagnant[i], 'racine', v_a));
  END LOOP;

  -- Les choix de la direction doivent viser un groupe de deux lignes ou plus
  -- et l'une de ses references (ou « distinctes »), une fois chacun.
  WITH m AS (
    SELECT * FROM pg_catalog.jsonb_to_recordset(v_membres) AS x(i integer, ref text, racine integer)
  ), g AS (
    SELECT m.racine, pg_catalog.count(*) AS taille,
           pg_catalog.left(pg_catalog.md5(pg_catalog.string_agg(m.ref, ',' ORDER BY m.ref)), 12) AS gid
      FROM m GROUP BY m.racine
  ), c AS (
    SELECT x.groupe, x.retenue FROM pg_catalog.jsonb_to_recordset(v_choix) AS x(groupe text, retenue text)
  )
  SELECT coalesce(pg_catalog.array_agg(DISTINCT c.groupe), ARRAY[]::text[]) INTO v_invalides
    FROM c
   WHERE NOT EXISTS (SELECT 1 FROM g WHERE g.gid = c.groupe AND g.taille >= 2)
      OR (c.retenue <> 'distinctes' AND NOT EXISTS (
            SELECT 1 FROM g JOIN m ON m.racine = g.racine WHERE g.gid = c.groupe AND m.ref = c.retenue))
      OR (SELECT pg_catalog.count(*) FROM c c2 WHERE c2.groupe = c.groupe) > 1;
  IF pg_catalog.cardinality(v_invalides) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'choix_invalide', 'groupes', pg_catalog.to_jsonb(v_invalides));
  END IF;

  -- Le resultat de chaque participant : actif ou en historique, et pour qui.
  WITH m AS (
    SELECT * FROM pg_catalog.jsonb_to_recordset(v_membres)
      AS x(i integer, ref text, mail text, tel text, ts timestamptz, pin boolean, d integer, id uuid, etat text,
           gagnant_base text, racine integer)
  ), g AS (
    SELECT m.racine, pg_catalog.count(*) AS taille,
           pg_catalog.left(pg_catalog.md5(pg_catalog.string_agg(m.ref, ',' ORDER BY m.ref)), 12) AS gid,
           (pg_catalog.count(m.mail) - pg_catalog.count(DISTINCT m.mail)) > 0 AS via_mail,
           (pg_catalog.count(m.tel) - pg_catalog.count(DISTINCT m.tel)) > 0 AS via_tel
      FROM m GROUP BY m.racine
  ), r AS (
    SELECT m.*, pg_catalog.row_number() OVER (PARTITION BY m.racine ORDER BY m.pin DESC, m.ts DESC, m.ref DESC) AS rang
      FROM m
  ), c AS (
    -- Les choix de cet appel, puis ceux d'un import precedent pour les groupes
    -- (meme membres, donc meme identifiant) que cet appel ne tranche pas.
    SELECT x.groupe, x.retenue FROM pg_catalog.jsonb_to_recordset(v_choix) AS x(groupe text, retenue text)
    UNION ALL
    SELECT s.groupe, s.retenue FROM public.formulaires_choix_doublons s
     WHERE NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_to_recordset(v_choix) AS y(groupe text, retenue text)
                        WHERE y.groupe = s.groupe)
  ), f AS (
    SELECT r.*, g.gid, g.taille, g.via_mail, g.via_tel, c.retenue AS choix,
           CASE WHEN c.retenue IS NOT NULL AND c.retenue <> 'distinctes' THEN c.retenue
                ELSE pg_catalog.first_value(r.ref) OVER (PARTITION BY r.racine ORDER BY r.rang) END AS gagnant
      FROM r JOIN g ON g.racine = r.racine
      LEFT JOIN c ON c.groupe = g.gid
  )
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'i', f.i, 'ref', f.ref, 'd', f.d, 'id', f.id, 'etat', f.etat, 'gagnant_base', f.gagnant_base,
           'groupe', CASE WHEN f.taille >= 2 THEN f.gid END,
           'taille', f.taille, 'choix', f.choix, 'distinctes', coalesce(f.choix = 'distinctes', false),
           'actif', f.taille = 1 OR f.pin OR coalesce(f.choix = 'distinctes', false) OR f.ref = f.gagnant,
           'gagnant', f.gagnant, 'via_mail', f.via_mail, 'via_tel', f.via_tel, 'rang', f.rang)
         ORDER BY f.i), '[]'::jsonb)
    INTO v_finaux
    FROM f;

  -- Les decisions des lignes du fichier, completees ; les mutations des lignes
  -- deja en base dont l'etat ou le remplacant change.
  FOR v_m IN SELECT * FROM pg_catalog.jsonb_to_recordset(v_finaux)
      AS x(i integer, ref text, d integer, id uuid, etat text, gagnant_base text, groupe text, taille integer,
           distinctes boolean, actif boolean, gagnant text, via_mail boolean, via_tel boolean, rang bigint)
  LOOP
    IF v_m.d > 0 THEN
      v_dec[v_m.d] := v_dec[v_m.d] || pg_catalog.jsonb_build_object(
        'etat_final', CASE WHEN v_m.actif THEN 'active' ELSE 'historique' END,
        'gagnant', CASE WHEN v_m.actif THEN NULL ELSE v_m.gagnant END,
        'groupe', v_m.groupe,
        'groupe_taille', v_m.taille);
    END IF;
    IF v_m.id IS NOT NULL AND (
         (v_m.actif AND v_m.etat = 'historique')
         OR (NOT v_m.actif AND (v_m.etat = 'active' OR v_m.gagnant_base IS DISTINCT FROM v_m.gagnant))) THEN
      v_mutations := v_mutations || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'id', v_m.id, 'reference', v_m.ref,
        'etat_final', CASE WHEN v_m.actif THEN 'active' ELSE 'historique' END,
        'gagnant', CASE WHEN v_m.actif THEN NULL ELSE v_m.gagnant END,
        'dans_le_fichier', v_m.d > 0));
    END IF;
  END LOOP;

  -- Les groupes de deux lignes ou plus, avec leur nature, sans aucune valeur
  -- de contact (la nature seulement).
  SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', x.groupe,
           'nature', CASE WHEN x.via_mail AND x.via_tel THEN 'courriel_et_telephone'
                          WHEN x.via_mail THEN 'courriel' ELSE 'telephone' END,
           'taille', x.taille,
           'lignes', x.lignes,
           'retenueProposee', x.retenue_n,
           'retenueDansLaBase', x.choix IS DISTINCT FROM 'distinctes' AND x.retenue_n IS NULL,
           'choisi', x.choix IS NOT NULL,
           'choix', x.choix) ORDER BY x.groupe), '[]'::jsonb)
    INTO v_groupes
    FROM (
      SELECT f.groupe, f.taille, pg_catalog.bool_or(f.via_mail) AS via_mail, pg_catalog.bool_or(f.via_tel) AS via_tel,
             coalesce(pg_catalog.jsonb_agg(v_dec[f.d] -> 'n' ORDER BY f.d) FILTER (WHERE f.d > 0), '[]'::jsonb) AS lignes,
             CASE WHEN pg_catalog.max(f.choix) = 'distinctes' THEN NULL
                  ELSE (SELECT v_dec[f2.d] -> 'n' FROM pg_catalog.jsonb_to_recordset(v_finaux)
                          AS f2(ref text, d integer, groupe text, gagnant text)
                         WHERE f2.groupe = f.groupe AND f2.ref = f2.gagnant AND f2.d > 0) END AS retenue_n,
             pg_catalog.max(f.choix) AS choix
        FROM pg_catalog.jsonb_to_recordset(v_finaux)
          AS f(i integer, d integer, groupe text, taille integer, choix text, via_mail boolean, via_tel boolean)
       WHERE f.groupe IS NOT NULL
       GROUP BY f.groupe, f.taille
    ) x;

  -- Les compteurs : une ligne lue compte une fois ; les personnes sont les
  -- groupes qui touchent le fichier (un groupe « distinctes » compte ses lignes).
  SELECT pg_catalog.jsonb_build_object(
    'lignesLues', pg_catalog.jsonb_array_length(p_lignes),
    'nouvelles', pg_catalog.count(*) FILTER (WHERE d ->> 'issue' = 'nouvelle'),
    'corrigees', pg_catalog.count(*) FILTER (WHERE d ->> 'issue' = 'corrigee'),
    'dejaConnues', pg_catalog.count(*) FILTER (WHERE d ->> 'issue' = 'deja_connue'),
    'ignorees', pg_catalog.count(*) FILTER (WHERE d ->> 'issue' = 'ignoree'),
    'aCorriger', pg_catalog.count(*) FILTER (WHERE d ->> 'issue' = 'a_corriger'),
    'historique', pg_catalog.count(*) FILTER (WHERE d ->> 'etat_final' = 'historique'
                                                AND d ->> 'issue' IN ('nouvelle', 'corrigee')),
    'personnes', (SELECT coalesce(pg_catalog.sum(CASE WHEN g.distinctes THEN g.nb ELSE 1 END), 0)
                    FROM (SELECT f.racine_cle, pg_catalog.bool_or(f.distinctes) AS distinctes,
                                 pg_catalog.count(*) FILTER (WHERE f.d > 0) AS nb
                            FROM (SELECT x.d, x.distinctes, coalesce(x.groupe, x.ref) AS racine_cle
                                    FROM pg_catalog.jsonb_to_recordset(v_finaux)
                                      AS x(d integer, ref text, groupe text, distinctes boolean)) f
                           GROUP BY f.racine_cle
                          HAVING pg_catalog.count(*) FILTER (WHERE f.d > 0) > 0) g))
    INTO v_compteurs
    FROM pg_catalog.unnest(v_dec) AS d;

  RETURN pg_catalog.jsonb_build_object(
    'decisions', pg_catalog.to_jsonb(v_dec),
    'mutations', v_mutations,
    'groupes', v_groupes,
    'compteurs', v_compteurs);
END;
$function$;

-- ============================================================
-- 6. Rapprochement : pre-remplissage du brouillon, lien, propositions
-- ============================================================

-- Pre-remplit le brouillon de la Salle d'examen avec les reponses utiles d'une
-- ligne importee (MAPPAGE 2 : colonnes E a I, K et L ; jamais les
-- disponibilites, le pays, le fuseau, les publics, le paiement, le cadre
-- religieux, la riwaya ni le niveau de tajwid). Seules les valeurs que le
-- questionnaire courant accepte sont gardees ; ce que la personne a deja
-- ecrit dans son brouillon l'emporte. N'envoie rien : le brouillon n'est
-- jamais une reponse envoyee (private.paiement_declaration l'ignore) et la
-- personne l'ouvre, le relit et l'envoie elle-meme. Rend les codes poses.
CREATE FUNCTION private.formulaires_prerempli(p_candidature uuid, p_reponse uuid)
RETURNS text[]
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_r public.formulaires_reponses;
  v_q public.candidature_questionnaires;
  v_b public.candidature_reponses;
  v_valides jsonb;
  v_ecrit jsonb;
  v_codes text[];
BEGIN
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature;
  SELECT r.* INTO v_r FROM public.formulaires_reponses r WHERE r.id = p_reponse;
  IF v_c.id IS NULL OR v_r.id IS NULL
     OR v_c.etape <> 'prequalification' OR v_c.etat IS DISTINCT FROM 'a_completer' OR v_c.issue <> 'en_cours' THEN
    RETURN ARRAY[]::text[];
  END IF;
  v_q := private.questionnaire_courant(v_c.type_code);
  IF v_q.version IS NULL THEN
    RETURN ARRAY[]::text[];
  END IF;
  v_valides := (private.questionnaire_examiner(v_q.definition, v_r.reponses)) -> 'reponses';
  v_b := private.questionnaire_brouillon(p_candidature, v_q.version);
  IF v_b.id IS NOT NULL THEN
    v_valides := v_valides - ARRAY(SELECT pg_catalog.jsonb_object_keys(v_b.reponses));
  END IF;
  IF v_valides = '{}'::jsonb THEN
    RETURN ARRAY[]::text[];
  END IF;
  v_ecrit := CASE WHEN v_b.id IS NULL THEN v_valides ELSE v_b.reponses || v_valides END;
  PERFORM private.questionnaire_ecrire(p_candidature, v_q.version, v_ecrit, false);
  SELECT pg_catalog.array_agg(k ORDER BY k) INTO v_codes FROM pg_catalog.jsonb_object_keys(v_valides) AS k;
  UPDATE public.formulaires_reponses
     SET prerempli_champs = v_codes, modifie_le = pg_catalog.clock_timestamp()
   WHERE id = p_reponse;
  RETURN v_codes;
END;
$function$;

-- Relie une ligne importee a une candidature : la ligne porte la candidature,
-- le lien est journalise des deux cotes (journal des lignes, journal de la
-- candidature) et le brouillon est pre-rempli. Une ligne deja reliee, en
-- historique, ou une candidature deja reliee a une autre ligne : rien. Rend
-- {lie, prerempli}.
CREATE FUNCTION private.formulaires_relier(p_reponse uuid, p_candidature uuid, p_cle text, p_auteur uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
  v_codes text[];
BEGIN
  IF p_cle NOT IN ('courriel', 'telephone') THEN
    RAISE EXCEPTION 'cle de rattachement inconnue' USING ERRCODE = '22023';
  END IF;
  BEGIN
    UPDATE public.formulaires_reponses
       SET candidature_id = p_candidature, rattachement = p_cle,
           rattachee_le = pg_catalog.clock_timestamp(), modifie_le = pg_catalog.clock_timestamp()
     WHERE id = p_reponse AND candidature_id IS NULL AND etat = 'active';
    GET DIAGNOSTICS v_n = ROW_COUNT;
  EXCEPTION WHEN unique_violation THEN
    v_n := 0;
  END;
  IF v_n = 0 THEN
    RETURN pg_catalog.jsonb_build_object('lie', false, 'prerempli', '[]'::jsonb);
  END IF;
  INSERT INTO public.formulaires_journal (reponse_id, type, auteur_id, details)
  VALUES (p_reponse, 'rattachement', p_auteur,
          pg_catalog.jsonb_build_object('candidature', p_candidature, 'cle', p_cle));
  INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
  VALUES (p_candidature, 'import', p_auteur,
          pg_catalog.jsonb_build_object('geste', 'rattachement', 'cle', p_cle, 'reponse', p_reponse));
  v_codes := private.formulaires_prerempli(p_candidature, p_reponse);
  RETURN pg_catalog.jsonb_build_object('lie', true, 'prerempli', pg_catalog.to_jsonb(v_codes));
END;
$function$;

-- Propose a la direction un rattachement par telephone : une ligne active, du
-- meme cote, pas encore reliee. Une candidature deja reliee a une ligne (par son
-- courriel) n'en recoit aucune : elle ne pourrait pas s'appliquer. Rend le
-- nombre de propositions ecrites.
CREATE FUNCTION private.formulaires_proposer(p_candidature uuid, p_telephone text, p_genre public.gender,
                                             p_hors_reponse uuid, p_auteur uuid)
RETURNS integer
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_r record;
  v_n integer := 0;
  v_id uuid;
BEGIN
  IF p_telephone IS NULL
     OR EXISTS (SELECT 1 FROM public.formulaires_reponses x WHERE x.candidature_id = p_candidature) THEN
    RETURN 0;
  END IF;
  FOR v_r IN
    SELECT r.id FROM public.formulaires_reponses r
     WHERE r.etat = 'active' AND r.candidature_id IS NULL AND r.genre = p_genre
       AND r.telephone = p_telephone AND r.id IS DISTINCT FROM p_hors_reponse
     ORDER BY r.recue_le, r.id
  LOOP
    INSERT INTO public.formulaires_rapprochements (reponse_id, candidature_id, cle)
    VALUES (v_r.id, p_candidature, 'telephone')
    ON CONFLICT (reponse_id, candidature_id) DO NOTHING
    RETURNING id INTO v_id;
    IF v_id IS NOT NULL THEN
      INSERT INTO public.formulaires_journal (reponse_id, type, auteur_id, details)
      VALUES (v_r.id, 'proposition', p_auteur,
              pg_catalog.jsonb_build_object('candidature', p_candidature, 'cle', 'telephone'));
      v_n := v_n + 1;
    END IF;
    v_id := NULL;
  END LOOP;
  RETURN v_n;
END;
$function$;

-- Une inscription (lien public ou invitation) rapproche la candidature des
-- lignes importees (spec 3.4) :
-- * le MEME COURRIEL confirme, d'une ligne du meme cote : rattachement
--   automatique et pre-remplissage ; exactement une ligne, sinon rien (jamais
--   un choix entre deux personnes) ;
-- * le meme telephone normalise, seulement : une PROPOSITION a la direction,
--   rien n'est montre a la personne (aucun canal ne verifie un telephone) ;
-- * le nom seul : jamais.
-- Un genre different ne rapproche jamais (rien ne traverse les deux cotes).
-- Rend {courriel: lie ou non, propositions, prerempli}.
CREATE FUNCTION private.formulaires_rapprocher_inscription(p_candidature uuid, p_courriel text,
                                                           p_telephone text, p_genre public.gender,
                                                           p_auteur uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_ids uuid[];
  v_lien jsonb := pg_catalog.jsonb_build_object('lie', false, 'prerempli', '[]'::jsonb);
  v_props integer;
BEGIN
  IF p_courriel IS NOT NULL THEN
    SELECT pg_catalog.array_agg(r.id) INTO v_ids
      FROM public.formulaires_reponses r
     WHERE r.etat = 'active' AND r.candidature_id IS NULL AND r.genre = p_genre AND r.courriel = p_courriel;
    IF pg_catalog.cardinality(v_ids) = 1 THEN
      v_lien := private.formulaires_relier(v_ids[1], p_candidature, 'courriel', p_auteur);
    END IF;
  END IF;
  v_props := private.formulaires_proposer(p_candidature, p_telephone, p_genre,
    (SELECT r.id FROM public.formulaires_reponses r WHERE r.candidature_id = p_candidature), p_auteur);
  RETURN pg_catalog.jsonb_build_object('courriel', v_lien -> 'lie', 'propositions', v_props,
                                       'prerempli', v_lien -> 'prerempli');
END;
$function$;

-- Un import rapproche, dans l'autre sens, une ligne active des candidatures
-- deja inscrites (la personne s'est inscrite avant l'import) : memes regles,
-- une candidature en cours en Salle d'examen, du meme cote, pas encore reliee.
CREATE FUNCTION private.formulaires_rapprocher_reponse(p_reponse uuid, p_auteur uuid)
RETURNS void
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_r public.formulaires_reponses;
  v_ids uuid[];
  v_c record;
BEGIN
  SELECT r.* INTO v_r FROM public.formulaires_reponses r WHERE r.id = p_reponse;
  IF v_r.id IS NULL OR v_r.etat <> 'active' OR v_r.candidature_id IS NOT NULL THEN
    RETURN;
  END IF;
  -- Comme a l'inscription : exactement une ligne active, libre et du meme cote
  -- porte ce courriel (deux personnes « distinctes » au meme courriel : aucune
  -- ligne n'est choisie a la place de la personne, quelle que soit celle que
  -- l'import traite la premiere).
  IF v_r.courriel IS NOT NULL
     AND (SELECT pg_catalog.count(*) FROM public.formulaires_reponses x
           WHERE x.etat = 'active' AND x.candidature_id IS NULL AND x.genre = v_r.genre
             AND x.courriel = v_r.courriel) = 1 THEN
    SELECT pg_catalog.array_agg(c.id) INTO v_ids
      FROM public.candidatures c
      JOIN public.candidature_contacts k ON k.candidature_id = c.id
     WHERE c.profile_id IS NOT NULL AND c.type_code = 'enseignant' AND c.genre = v_r.genre
       AND c.etape = 'prequalification' AND c.issue = 'en_cours' AND k.courriel = v_r.courriel
       AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses x WHERE x.candidature_id = c.id);
    IF pg_catalog.cardinality(v_ids) = 1 THEN
      PERFORM private.formulaires_relier(v_r.id, v_ids[1], 'courriel', p_auteur);
      RETURN;
    END IF;
  END IF;
  IF v_r.telephone IS NOT NULL THEN
    FOR v_c IN
      SELECT c.id FROM public.candidatures c
        JOIN public.candidature_contacts k ON k.candidature_id = c.id
       WHERE c.profile_id IS NOT NULL AND c.type_code = 'enseignant' AND c.genre = v_r.genre
         AND c.etape = 'prequalification' AND c.issue = 'en_cours' AND k.telephone = v_r.telephone
         AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses x WHERE x.candidature_id = c.id)
       ORDER BY c.recue_le, c.id
    LOOP
      INSERT INTO public.formulaires_rapprochements (reponse_id, candidature_id, cle)
      VALUES (v_r.id, v_c.id, 'telephone')
      ON CONFLICT (reponse_id, candidature_id) DO NOTHING;
      IF FOUND THEN
        INSERT INTO public.formulaires_journal (reponse_id, type, auteur_id, details)
        VALUES (v_r.id, 'proposition', p_auteur,
                pg_catalog.jsonb_build_object('candidature', v_c.id, 'cle', 'telephone'));
      END IF;
    END LOOP;
  END IF;
END;
$function$;

-- ============================================================
-- 7. Inscription d'un candidat (lien public ou invitation)
-- ============================================================

-- L'inscription sans code est-elle ouverte ? Lu au serveur par une session
-- sans profil : la cle de mise en ligne seule, jamais le plafond (CAND-F03 :
-- le plafond se joue dans inscrire_candidat, ou la reponse est la meme que le
-- succes). Rend aussi la version de la confidentialite que le serveur attend.
CREATE FUNCTION public.inscription_candidat_ouverte()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL, false) THEN
    RAISE EXCEPTION 'session requise' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'ouverte', coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                          WHERE c.key = 'candidatures.inscription_publique_ouverte'), false),
    'versionConfidentialite', (SELECT c.value #>> '{}' FROM public.app_config c
                                WHERE c.key = 'candidatures.confidentialite_version'));
END;
$function$;

-- Inscription d'un candidat enseignant, par le lien public (p_code nul) ou par
-- un code d'invitation. Le compte est celui de l'invitation, fabrique par
-- private.creer_profil_inscription_interne (role teacher, pending_kyc, sans
-- foyer, fiche vide : CAND-L1B), et la candidature naît avec lui, en Salle
-- d'examen a completer. Les conditions de la transition 5 :
-- * courriel CONFIRME (auth.users.email_confirmed_at), sinon rien n'est cree ;
-- * genre, telephone avec indicatif, langue (fr ou ar) : obligatoires ;
-- * accord de confidentialite a la version que le serveur attend ;
-- * sans code : la cle de mise en ligne vraie, et un plafond d'inscriptions
--   par heure (app_config) : au-dela, la reponse est la MEME que le succes
--   et rien n'est ecrit ;
-- * avec code : le code lie a l'adresse de la session, non revoque, non
--   consomme, non expire (memes resultats que inscrire_enseignant_invite).
-- Puis le rapprochement (spec 3.4) avec les reponses importees : memes regles
-- pour les deux portes. Les refus sont RENDUS ({resultat}) ; une session
-- absente ou deja inscrite leve 42501. Rend {resultat}.
CREATE FUNCTION public.inscrire_candidat(
  p_code text,
  p_first_name text,
  p_last_name text,
  p_gender public.gender,
  p_telephone text,
  p_langue text,
  p_version_confidentialite text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_email text;
  v_confirme timestamptz;
  v_code text := nullif(pg_catalog.btrim(p_code), '');
  v_ligne public.invitations_enseignant;
  v_porte text;
  v_prenom text := pg_catalog.btrim(coalesce(p_first_name, ''));
  v_nom text := pg_catalog.btrim(coalesce(p_last_name, ''));
  v_tel jsonb;
  v_invalides text[] := ARRAY[]::text[];
  v_conf text;
  v_plafond integer;
  v_recentes integer;
  v_lignes uuid[];
  v_cid uuid;
  v_nom_complet text;
  v_reconnue text;
BEGIN
  SELECT pg_catalog.lower(pg_catalog.btrim(u.email)), u.email_confirmed_at INTO v_email, v_confirme
    FROM auth.users u WHERE u.id = v_uid;
  IF NOT coalesce(v_uid IS NOT NULL AND v_email IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid), false) THEN
    RAISE EXCEPTION 'inscription de candidat reservee a une session sans profil' USING ERRCODE = '42501';
  END IF;
  -- La candidature n'existe qu'une fois le courriel confirme (spec 3.1, 2).
  IF v_confirme IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'courriel_non_confirme');
  END IF;
  -- Un seul appel a la fois par session ; le profil est relu sous le verrou.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('inscription_candidat:' || v_uid::text, 0));
  IF EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = v_uid) THEN
    RAISE EXCEPTION 'inscription de candidat reservee a une session sans profil' USING ERRCODE = '42501';
  END IF;

  -- La porte.
  IF v_code IS NULL THEN
    v_porte := 'lien_public';
    IF NOT coalesce((SELECT c.value = 'true'::jsonb FROM public.app_config c
                      WHERE c.key = 'candidatures.inscription_publique_ouverte'), false) THEN
      RETURN pg_catalog.jsonb_build_object('resultat', 'fermee');
    END IF;
  ELSE
    v_porte := 'invitation';
    SELECT i.* INTO v_ligne FROM public.invitations_enseignant i
     WHERE i.code = pg_catalog.upper(v_code) AND i.email = v_email AND i.revoquee_le IS NULL
     FOR UPDATE;
    IF v_ligne.id IS NULL THEN
      RETURN pg_catalog.jsonb_build_object('resultat', 'inconnue');
    ELSIF v_ligne.utilisee_le IS NOT NULL THEN
      RETURN pg_catalog.jsonb_build_object('resultat', 'deja_utilisee');
    ELSIF v_ligne.expire_le <= pg_catalog.now() THEN
      RETURN pg_catalog.jsonb_build_object('resultat', 'expiree');
    END IF;
  END IF;

  -- Ce que la personne doit donner : nommé, jamais devine.
  IF v_prenom = '' OR pg_catalog.length(v_prenom) > 90 THEN v_invalides := v_invalides || 'prenom'::text; END IF;
  IF v_nom = '' OR pg_catalog.length(v_nom) > 90 THEN v_invalides := v_invalides || 'nom'::text; END IF;
  IF p_gender IS NULL THEN v_invalides := v_invalides || 'genre'::text; END IF;
  IF p_langue IS NULL OR p_langue NOT IN ('fr', 'ar') THEN v_invalides := v_invalides || 'langue'::text; END IF;
  v_tel := private.formulaires_telephone(p_telephone);
  IF v_tel ->> 'telephone' IS NULL THEN v_invalides := v_invalides || 'telephone'::text; END IF;
  IF pg_catalog.cardinality(v_invalides) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'invalide', 'champs', pg_catalog.to_jsonb(v_invalides));
  END IF;
  SELECT c.value #>> '{}' INTO v_conf FROM public.app_config c WHERE c.key = 'candidatures.confidentialite_version';
  IF v_conf IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'confidentialite_indisponible');
  ELSIF p_version_confidentialite IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'confidentialite_requise', 'versionCourante', v_conf);
  ELSIF p_version_confidentialite <> v_conf THEN
    RETURN pg_catalog.jsonb_build_object('resultat', 'confidentialite_perimee', 'versionCourante', v_conf);
  END IF;

  -- Un import et une inscription ne se croisent pas : chacun rapproche ce qu'il
  -- ecrit de ce que l'autre a ecrit, et tant que l'autre n'est pas valide il ne le
  -- voit pas ; la personne ne serait jamais reliee a sa reponse. (Le journal
  -- d'audit ne suffit pas a les ordonner : l'import n'y ecrit qu'apres son
  -- rapprochement.) Verrou de l'import : partage ici, exclusif a la confirmation.
  PERFORM pg_catalog.pg_advisory_xact_lock_shared(pg_catalog.hashtextextended('import_formulaires', 0));

  -- Le plafond par heure (sans code) : au-dela, la meme reponse que le succes,
  -- rien d'ecrit. Un verrou serialise les inscriptions publiques.
  IF v_porte = 'lien_public' THEN
    PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('inscription_candidat_plafond', 0));
    v_plafond := coalesce(public.app_config_int('candidatures.inscriptions_par_heure', 60), 60);
    SELECT pg_catalog.count(*) INTO v_recentes FROM private.inscriptions_publiques s
     WHERE s.cree_le > pg_catalog.clock_timestamp() - interval '1 hour';
    IF v_recentes >= v_plafond THEN
      RETURN pg_catalog.jsonb_build_object('resultat', 'acceptee');
    END IF;
  END IF;

  -- Le compte : la fabrique de l'invitation, une seule pour les deux portes.
  PERFORM private.creer_profil_inscription_interne('teacher', v_prenom, v_nom, p_gender);
  IF v_porte = 'invitation' THEN
    UPDATE public.invitations_enseignant i
       SET utilisee_le = pg_catalog.clock_timestamp(), utilisee_par = v_uid
     WHERE i.id = v_ligne.id;
    PERFORM public.log_sensitive_access('invitation_enseignant_consommee', 'invitations_enseignant',
      v_ligne.id::text, pg_catalog.jsonb_build_object('profile_id', v_uid));
  ELSE
    INSERT INTO private.inscriptions_publiques DEFAULT VALUES;
  END IF;
  INSERT INTO public.candidat_accords_confidentialite (profile_id, version, porte)
  VALUES (v_uid, v_conf, v_porte);

  -- La candidature : celle qu'une ligne « pour suivi » du meme courriel et du
  -- meme cote attendait (elle devient cette candidature, spec 3.4), sinon une
  -- neuve. Une personne reconnue dans l'import du 12/10 (B) est notee, sans
  -- aucun pre-remplissage.
  v_nom_complet := pg_catalog.btrim(v_prenom || ' ' || v_nom);
  v_reconnue := CASE WHEN EXISTS (
      SELECT 1 FROM private.preinscription_households h
        JOIN private.preinscription_persons pp ON pp.household_id = h.id AND pp.person_kind = 'teacher'
       WHERE h.email_normalise = v_email) THEN 'inscription_12_10' END;
  SELECT pg_catalog.array_agg(c.id) INTO v_lignes
    FROM public.candidatures c
    JOIN public.candidature_contacts k ON k.candidature_id = c.id
   WHERE c.type_code = 'enseignant' AND c.profile_id IS NULL AND c.etape = 'recue' AND c.issue = 'en_cours'
     AND c.genre = p_gender AND k.courriel = v_email;
  -- La ligne est relue sous verrou, dans l'etat qu'on lui suppose : une
  -- direction qui la retire, la refuse ou la rattache au meme instant (gestes du
  -- moteur, qui verrouillent la candidature) ne la laisse pas devenir la
  -- candidature de la personne en gardant son issue ; sinon une candidature neuve.
  v_cid := NULL;
  IF pg_catalog.cardinality(v_lignes) = 1 THEN
    SELECT c.id INTO v_cid FROM public.candidatures c
     WHERE c.id = v_lignes[1] AND c.type_code = 'enseignant' AND c.profile_id IS NULL AND c.etape = 'recue'
       AND c.issue = 'en_cours' AND c.genre = p_gender
       AND EXISTS (SELECT 1 FROM public.candidature_contacts k
                    WHERE k.candidature_id = c.id AND k.courriel = v_email)
     FOR UPDATE OF c;
  END IF;
  IF v_cid IS NOT NULL THEN
    UPDATE public.candidatures c
       SET profile_id = v_uid, etape = 'prequalification', etat = 'a_completer', nom_complet = v_nom_complet,
           langue = p_langue, version = c.version + 1, derniere_activite = pg_catalog.clock_timestamp()
     WHERE c.id = v_cid;
    UPDATE public.candidature_contacts k
       SET courriel = v_email, courriel_brut = NULL, telephone = v_tel ->> 'telephone', telephone_brut = NULL
     WHERE k.candidature_id = v_cid;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_apres, issue_avant, issue_apres, auteur_id, details)
    VALUES (v_cid, 'transition', 'recue', 'prequalification', 'a_completer', 'en_cours', 'en_cours', v_uid,
            pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
              'geste', 'inscription', 'transition', 5, 'auteur', 'candidat', 'porte', v_porte,
              'ligneSuivie', true, 'reconnue', v_reconnue)));
  ELSE
    INSERT INTO public.candidatures
      (type_code, profile_id, genre, nom_complet, etape, etat, issue, source, langue)
    VALUES ('enseignant', v_uid, p_gender, v_nom_complet, 'prequalification', 'a_completer', 'en_cours',
            v_porte, p_langue)
    RETURNING id INTO v_cid;
    INSERT INTO public.candidature_contacts (candidature_id, courriel, telephone)
    VALUES (v_cid, v_email, v_tel ->> 'telephone');
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_apres, etat_apres, issue_apres, auteur_id, details)
    VALUES (v_cid, 'creee', 'prequalification', 'a_completer', 'en_cours', v_uid,
            pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
              'geste', 'inscription', 'transition', 5, 'auteur', 'candidat', 'porte', v_porte,
              'reconnue', v_reconnue)));
  END IF;
  PERFORM public.log_sensitive_access('candidature_inscription', 'candidatures', v_cid::text,
    pg_catalog.jsonb_build_object('porte', v_porte, 'transition', 5, 'confidentialite', v_conf));

  -- Le rapprochement avec les reponses importees (courriel confirme : lien et
  -- pre-remplissage ; telephone seul : proposition a la direction).
  PERFORM private.formulaires_rapprocher_inscription(v_cid, v_email, v_tel ->> 'telephone', p_gender, v_uid);
  RETURN pg_catalog.jsonb_build_object('resultat', 'acceptee');
END;
$function$;

-- ============================================================
-- 8. Import controle des reponses des formulaires (super-admin, aal2)
-- ============================================================

-- Le jeton de l'apercu : une empreinte HMAC-SHA256 sous la cle du serveur
-- (celle des lots de CAND-L2A2), de l'auteur, du classeur, de l'onglet, du
-- fuseau, du mappage et du contenu du fichier. Un client ne peut pas le
-- calculer ; un fichier different le perime.
CREATE FUNCTION private.formulaires_jeton(p_auteur uuid, p_csv text, p_classeur text, p_onglet text,
                                          p_mappage jsonb, p_fuseau text)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_secret text;
BEGIN
  SELECT s.secret INTO v_secret FROM private.candidature_lot_secret s;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 64 THEN
    RAISE EXCEPTION 'CAND-L3 : cle des jetons absente' USING ERRCODE = 'P0001';
  END IF;
  RETURN pg_catalog.substr(pg_catalog.encode(extensions.hmac(
    pg_catalog.convert_to('import-formulaires|' || coalesce(p_auteur::text, '') || '|' || p_classeur || '|'
      || p_onglet || '|' || p_fuseau || '|' || coalesce(p_mappage::text, '') || '|' || pg_catalog.md5(p_csv),
      'UTF8'),
    pg_catalog.convert_to(v_secret, 'UTF8'), 'sha256'), 'hex'), 1, 32);
END;
$function$;

-- L'apercu d'un import (essai a blanc) : aucune ecriture, hors la ligne
-- d'audit. Il rend les en-tetes reconnus, les compteurs, une ligne par ligne
-- lue (issue, motifs, avertissements, marques « courriel a obtenir » et
-- « indicatif a confirmer », groupe et etat final), les groupes de doublons
-- (leur nature, jamais la valeur du contact) et le jeton de la confirmation.
-- Ni nom, ni courriel, ni telephone, ni reponse. Reserve au super-admin en
-- double verification (spec 3.2 : le fichier mele les deux cotes).
CREATE FUNCTION public.apercu_import_formulaires(
  p_csv text,
  p_classeur text,
  p_onglet text,
  p_mappage jsonb DEFAULT NULL,
  p_fuseau text DEFAULT 'UTC'
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_super boolean;
  v_classeur text := pg_catalog.btrim(coalesce(p_classeur, ''));
  v_onglet text := pg_catalog.btrim(coalesce(p_onglet, ''));
  v_lu jsonb;
  v_plan jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'import des formulaires reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.super_admin INTO v_lecteur, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT coalesce(v_super, false) THEN
    RAISE EXCEPTION 'import des formulaires reserve au super-admin' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.app_aal() = 'aal2', false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'double_verification_requise', 'ecritureEffectuee', false);
  END IF;
  IF p_csv IS NULL OR pg_catalog.length(p_csv) > 5000000 OR v_classeur = '' OR v_onglet = ''
     OR pg_catalog.length(v_classeur) > 200 OR pg_catalog.length(v_onglet) > 200
     OR pg_catalog.strpos(v_classeur, '|') > 0 OR pg_catalog.strpos(v_onglet, '|') > 0 THEN
    RAISE EXCEPTION 'fichier, classeur et onglet attendus (5 Mo, noms de 200 signes sans barre verticale)'
      USING ERRCODE = '22023';
  END IF;

  v_lu := private.formulaires_lire(p_csv, v_classeur, v_onglet, p_mappage, p_fuseau);
  IF v_lu ? 'erreur' THEN
    RETURN v_lu || pg_catalog.jsonb_build_object('ecritureEffectuee', false);
  END IF;
  v_plan := private.formulaires_planifier(v_lu -> 'lignes', '[]'::jsonb);

  PERFORM public.log_sensitive_access('formulaires_apercu', 'formulaires_lots', NULL,
    (v_plan -> 'compteurs') || pg_catalog.jsonb_build_object('groupes', pg_catalog.jsonb_array_length(v_plan -> 'groupes')));
  RETURN pg_catalog.jsonb_build_object(
    'ecritureEffectuee', false,
    'jeton', private.formulaires_jeton(v_uid, p_csv, v_classeur, v_onglet, p_mappage, p_fuseau),
    'entetes', v_lu -> 'entetes',
    'compteurs', v_plan -> 'compteurs',
    'groupes', v_plan -> 'groupes',
    'lignes', (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'ligne', d -> 'n',
        'issue', d -> 'issue',
        'motifs', coalesce(d -> 'motifs', '[]'::jsonb),
        'avertissements', coalesce(d -> 'avertissements', '[]'::jsonb),
        'courrielAObtenir', CASE WHEN d ? 'etat_final' OR d ->> 'issue' = 'deja_connue'
                                 THEN (d ->> 'courriel') IS NULL END,
        'indicatifAConfirmer', CASE WHEN d ? 'etat_final' OR d ->> 'issue' = 'deja_connue'
                                    THEN (d ->> 'telephone_brut') IS NOT NULL END,
        'groupe', d -> 'groupe',
        'etatFinal', d -> 'etat_final') ORDER BY (d ->> 'n')::integer), '[]'::jsonb)
      FROM pg_catalog.jsonb_array_elements(v_plan -> 'decisions') d));
END;
$function$;

-- La confirmation d'un import. Memes gardes que l'apercu, plus : une cle
-- d'idempotence (le meme fichier rejoue sous la meme cle rend le meme rapport
-- sans rien ecrire ; la cle d'un autre fichier ou d'un autre auteur est
-- refusee), le jeton de l'apercu (un autre fichier le perime), les choix de
-- doublons de la direction. Elle ecrit des REPONSES IMPORTEES, rien d'autre :
-- ni compte, ni invitation, ni piece, ni accord, ni candidature (spec 3.2).
-- Un fichier rejoue n'ajoute rien ; une ligne corrigee dans le classeur se
-- corrige sur sa reference source (une correction tracee, 0 reponse nouvelle).
-- Rend le rapport ligne par ligne : la reference source, jamais un nom.
CREATE FUNCTION public.confirmer_import_formulaires(
  p_csv text,
  p_classeur text,
  p_onglet text,
  p_jeton text,
  p_choix jsonb,
  p_cle_idempotence text,
  p_mappage jsonb DEFAULT NULL,
  p_fuseau text DEFAULT 'UTC'
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_super boolean;
  v_classeur text := pg_catalog.btrim(coalesce(p_classeur, ''));
  v_onglet text := pg_catalog.btrim(coalesce(p_onglet, ''));
  v_empreinte text;
  v_lot public.formulaires_lots;
  v_lu jsonb;
  v_plan jsonb;
  v_d jsonb;
  v_m jsonb;
  v_rapport jsonb;
  v_lot_id uuid := pg_catalog.gen_random_uuid();
  v_id uuid;
  v_old public.formulaires_reponses;
  v_champs text[];
  v_gagnant uuid;
  v_ids uuid[] := ARRAY[]::uuid[];
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'import des formulaires reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.super_admin INTO v_lecteur, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT coalesce(v_super, false) THEN
    RAISE EXCEPTION 'import des formulaires reserve au super-admin' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.app_aal() = 'aal2', false) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'double_verification_requise', 'ecritureEffectuee', false);
  END IF;
  IF p_csv IS NULL OR pg_catalog.length(p_csv) > 5000000 OR v_classeur = '' OR v_onglet = ''
     OR pg_catalog.length(v_classeur) > 200 OR pg_catalog.length(v_onglet) > 200
     OR pg_catalog.strpos(v_classeur, '|') > 0 OR pg_catalog.strpos(v_onglet, '|') > 0
     OR p_jeton IS NULL OR p_cle_idempotence IS NULL OR pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200
     OR (p_choix IS NOT NULL AND pg_catalog.jsonb_typeof(p_choix) <> 'array') THEN
    RAISE EXCEPTION 'fichier, classeur, onglet, jeton, choix (liste) et cle (8 a 200 signes) attendus'
      USING ERRCODE = '22023';
  END IF;
  v_empreinte := pg_catalog.md5(p_csv);

  -- Un seul import a la fois ; la cle d'abord (le rejeu ne depend de rien d'autre).
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('import_formulaires', 0));
  SELECT l.* INTO v_lot FROM public.formulaires_lots l WHERE l.cle = p_cle_idempotence;
  IF v_lot.id IS NOT NULL THEN
    IF v_lot.auteur_id = v_uid AND v_lot.empreinte = v_empreinte AND v_lot.classeur = v_classeur
       AND v_lot.onglet = v_onglet THEN
      RETURN v_lot.rapport || pg_catalog.jsonb_build_object('rejoue', true);
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
  END IF;
  IF p_jeton IS DISTINCT FROM private.formulaires_jeton(v_uid, p_csv, v_classeur, v_onglet, p_mappage, p_fuseau) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'jeton_perime', 'ecritureEffectuee', false);
  END IF;

  v_lu := private.formulaires_lire(p_csv, v_classeur, v_onglet, p_mappage, p_fuseau);
  IF v_lu ? 'erreur' THEN
    RETURN v_lu || pg_catalog.jsonb_build_object('ecritureEffectuee', false);
  END IF;
  v_plan := private.formulaires_planifier(v_lu -> 'lignes', coalesce(p_choix, '[]'::jsonb));
  IF v_plan ? 'erreur' THEN
    RETURN v_plan || pg_catalog.jsonb_build_object('ecritureEffectuee', false);
  END IF;

  -- Le rapport : une entree par ligne lue, la reference source et l'issue,
  -- jamais un nom ni un contact.
  v_rapport := pg_catalog.jsonb_build_object(
    'ecritureEffectuee', true,
    'lot', v_lot_id,
    'compteurs', v_plan -> 'compteurs',
    'choix', coalesce(p_choix, '[]'::jsonb),
    'lignes', (SELECT coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'ligne', d -> 'n',
        'reference', d -> 'reference',
        'issue', d -> 'issue',
        'etatFinal', d -> 'etat_final',
        'motifs', coalesce(d -> 'motifs', '[]'::jsonb),
        'avertissements', coalesce(d -> 'avertissements', '[]'::jsonb))) ORDER BY (d ->> 'n')::integer), '[]'::jsonb)
      FROM pg_catalog.jsonb_array_elements(v_plan -> 'decisions') d));
  INSERT INTO public.formulaires_lots (id, cle, auteur_id, classeur, onglet, empreinte, compteurs, rapport)
  VALUES (v_lot_id, p_cle_idempotence, v_uid, v_classeur, v_onglet, v_empreinte, v_plan -> 'compteurs', v_rapport);

  -- Les choix de la direction pour les groupes de doublons, gardes pour les
  -- imports suivants (un fichier corrige qui se rejoue ne les defait pas).
  FOR v_m IN SELECT c FROM pg_catalog.jsonb_array_elements(coalesce(p_choix, '[]'::jsonb)) c LOOP
    INSERT INTO public.formulaires_choix_doublons (groupe, retenue, lot_id, auteur_id)
    VALUES (v_m ->> 'groupe', v_m ->> 'retenue', v_lot_id, v_uid)
    ON CONFLICT (groupe) DO UPDATE
      SET retenue = excluded.retenue, lot_id = excluded.lot_id, auteur_id = excluded.auteur_id,
          cree_le = pg_catalog.clock_timestamp();
  END LOOP;

  -- Passe 1 : les lignes nouvelles qui restent actives.
  FOR v_d IN SELECT d FROM pg_catalog.jsonb_array_elements(v_plan -> 'decisions') d
              WHERE d ->> 'issue' = 'nouvelle' AND d ->> 'etat_final' = 'active'
              ORDER BY (d ->> 'n')::integer LOOP
    INSERT INTO public.formulaires_reponses
      (reference_source, lot_id, recue_le, genre, nom_affiche, courriel, courriel_brut, telephone, telephone_brut,
       reponses, creneaux_libelle, consentement_whatsapp, contenu_empreinte, etat)
    VALUES (v_d ->> 'reference', v_lot_id, (v_d ->> 'recue_le')::timestamptz, (v_d ->> 'genre')::public.gender,
            v_d ->> 'nom', v_d ->> 'courriel', v_d ->> 'courriel_brut', v_d ->> 'telephone',
            v_d ->> 'telephone_brut', v_d -> 'reponses', v_d ->> 'creneaux', (v_d ->> 'whatsapp')::boolean,
            v_d ->> 'empreinte', 'active')
    RETURNING id INTO v_id;
    INSERT INTO public.formulaires_journal (reponse_id, type, lot_id, auteur_id, details)
    VALUES (v_id, 'import', v_lot_id, v_uid, '{}'::jsonb);
    v_ids := v_ids || v_id;
  END LOOP;

  -- Passe 2 : les lignes nouvelles que la plus recente remplace (historique).
  FOR v_d IN SELECT d FROM pg_catalog.jsonb_array_elements(v_plan -> 'decisions') d
              WHERE d ->> 'issue' = 'nouvelle' AND d ->> 'etat_final' = 'historique'
              ORDER BY (d ->> 'n')::integer LOOP
    SELECT r.id INTO v_gagnant FROM public.formulaires_reponses r WHERE r.reference_source = v_d ->> 'gagnant';
    INSERT INTO public.formulaires_reponses
      (reference_source, lot_id, recue_le, genre, nom_affiche, courriel, courriel_brut, telephone, telephone_brut,
       reponses, creneaux_libelle, consentement_whatsapp, contenu_empreinte, etat, remplacee_par)
    VALUES (v_d ->> 'reference', v_lot_id, (v_d ->> 'recue_le')::timestamptz, (v_d ->> 'genre')::public.gender,
            v_d ->> 'nom', v_d ->> 'courriel', v_d ->> 'courriel_brut', v_d ->> 'telephone',
            v_d ->> 'telephone_brut', v_d -> 'reponses', v_d ->> 'creneaux', (v_d ->> 'whatsapp')::boolean,
            v_d ->> 'empreinte', 'historique', v_gagnant)
    RETURNING id INTO v_id;
    INSERT INTO public.formulaires_journal (reponse_id, type, lot_id, auteur_id, details)
    VALUES (v_id, 'import', v_lot_id, v_uid, pg_catalog.jsonb_build_object('etat', 'historique'));
  END LOOP;

  -- Passe 3 : les lignes corrigees dans le classeur, sur leur reference source.
  FOR v_d IN SELECT d FROM pg_catalog.jsonb_array_elements(v_plan -> 'decisions') d
              WHERE d ->> 'issue' = 'corrigee' ORDER BY (d ->> 'n')::integer LOOP
    SELECT r.* INTO v_old FROM public.formulaires_reponses r WHERE r.id = (v_d ->> 'existant_id')::uuid FOR UPDATE;
    v_champs := ARRAY[]::text[];
    IF v_old.genre::text IS DISTINCT FROM v_d ->> 'genre' THEN v_champs := v_champs || 'genre'::text; END IF;
    IF v_old.nom_affiche IS DISTINCT FROM v_d ->> 'nom' THEN v_champs := v_champs || 'nom'::text; END IF;
    IF v_old.courriel IS DISTINCT FROM v_d ->> 'courriel'
       OR v_old.courriel_brut IS DISTINCT FROM v_d ->> 'courriel_brut' THEN
      v_champs := v_champs || 'courriel'::text;
    END IF;
    IF v_old.telephone IS DISTINCT FROM v_d ->> 'telephone'
       OR v_old.telephone_brut IS DISTINCT FROM v_d ->> 'telephone_brut' THEN
      v_champs := v_champs || 'telephone'::text;
    END IF;
    IF v_old.reponses IS DISTINCT FROM v_d -> 'reponses' THEN v_champs := v_champs || 'reponses'::text; END IF;
    IF v_old.creneaux_libelle IS DISTINCT FROM v_d ->> 'creneaux' THEN v_champs := v_champs || 'creneaux'::text; END IF;
    IF v_old.consentement_whatsapp IS DISTINCT FROM (v_d ->> 'whatsapp')::boolean THEN
      v_champs := v_champs || 'consentement'::text;
    END IF;
    UPDATE public.formulaires_reponses r
       SET genre = (v_d ->> 'genre')::public.gender, nom_affiche = v_d ->> 'nom', courriel = v_d ->> 'courriel',
           courriel_brut = v_d ->> 'courriel_brut', telephone = v_d ->> 'telephone',
           telephone_brut = v_d ->> 'telephone_brut', reponses = v_d -> 'reponses',
           creneaux_libelle = v_d ->> 'creneaux', consentement_whatsapp = (v_d ->> 'whatsapp')::boolean,
           contenu_empreinte = v_d ->> 'empreinte', modifie_le = pg_catalog.clock_timestamp()
     WHERE r.id = v_old.id;
    INSERT INTO public.formulaires_journal (reponse_id, type, lot_id, auteur_id, details)
    VALUES (v_old.id, 'correction', v_lot_id, v_uid, pg_catalog.jsonb_build_object('champs', pg_catalog.to_jsonb(v_champs)));
    -- La ligne gardee pour suivi, pas encore inscrite, suit la correction.
    IF v_old.suivi_id IS NOT NULL AND v_old.candidature_id IS NULL THEN
      UPDATE public.candidatures c
         SET nom_complet = v_d ->> 'nom', derniere_activite = pg_catalog.clock_timestamp()
       WHERE c.id = v_old.suivi_id AND c.profile_id IS NULL AND c.etape = 'recue';
      UPDATE public.candidature_contacts k
         SET courriel = v_d ->> 'courriel', courriel_brut = v_d ->> 'courriel_brut',
             telephone = v_d ->> 'telephone', telephone_brut = v_d ->> 'telephone_brut'
       WHERE k.candidature_id = v_old.suivi_id
         AND EXISTS (SELECT 1 FROM public.candidatures c WHERE c.id = v_old.suivi_id AND c.profile_id IS NULL);
    END IF;
    IF (v_d ->> 'etat_final') = 'active' AND v_old.etat = 'active' THEN
      v_ids := v_ids || v_old.id;
    END IF;
  END LOOP;

  -- Passe 4 : les lignes deja en base dont l'etat change parce qu'une ligne plus
  -- recente les remplace (ou ne les remplace plus).
  FOR v_m IN SELECT m FROM pg_catalog.jsonb_array_elements(v_plan -> 'mutations') m LOOP
    IF v_m ->> 'etat_final' = 'historique' THEN
      SELECT r.id INTO v_gagnant FROM public.formulaires_reponses r WHERE r.reference_source = v_m ->> 'gagnant';
      UPDATE public.formulaires_reponses r
         SET etat = 'historique', remplacee_par = v_gagnant, modifie_le = pg_catalog.clock_timestamp()
       WHERE r.id = (v_m ->> 'id')::uuid;
      INSERT INTO public.formulaires_journal (reponse_id, type, lot_id, auteur_id, details)
      VALUES ((v_m ->> 'id')::uuid, 'historique', v_lot_id, v_uid,
              pg_catalog.jsonb_build_object('remplaceePar', v_gagnant));
    ELSE
      UPDATE public.formulaires_reponses r
         SET etat = 'active', remplacee_par = NULL, modifie_le = pg_catalog.clock_timestamp()
       WHERE r.id = (v_m ->> 'id')::uuid;
      INSERT INTO public.formulaires_journal (reponse_id, type, lot_id, auteur_id, details)
      VALUES ((v_m ->> 'id')::uuid, 'reactivation', v_lot_id, v_uid, '{}'::jsonb);
      -- Une ligne qui redevient active (choix de la direction) est rapprochee
      -- comme une ligne neuve : sa personne a pu s'inscrire entre-temps.
      v_ids := v_ids || (v_m ->> 'id')::uuid;
    END IF;
  END LOOP;

  -- Les personnes deja inscrites avant l'import : memes regles de
  -- rapprochement que l'inscription (lien par courriel, proposition par
  -- telephone), pour les lignes actives que cet import vient d'ecrire.
  FOREACH v_id IN ARRAY v_ids LOOP
    PERFORM private.formulaires_rapprocher_reponse(v_id, v_uid);
  END LOOP;

  PERFORM public.log_sensitive_access('formulaires_import', 'formulaires_lots', v_lot_id::text,
    (v_plan -> 'compteurs') || pg_catalog.jsonb_build_object('groupes', pg_catalog.jsonb_array_length(v_plan -> 'groupes')));
  RETURN v_rapport || '{"rejoue": false}'::jsonb;
END;
$function$;

-- ============================================================
-- 9. La direction : lire les reponses importees, les garder, prevenir, rattacher
-- ============================================================

-- La liste des reponses importees, dans la portee de la direction (son cote ;
-- le super-admin lit les deux, la lecture est journalisee comme celle des
-- candidatures). Nom, date, marques « courriel a obtenir » et « indicatif a
-- confirmer » ; jamais un courriel, un telephone, un genre ni une reponse
-- (CAND-F13). Filtre : etat, suivi, rattachee, aPrevenir, recherche (nom
-- partiel normalise, reference source exacte ou courriel exact).
CREATE FUNCTION public.lister_formulaires_importes(p_filtre jsonb DEFAULT '{}'::jsonb, p_page integer DEFAULT 1)
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
  v_etat text;
  v_suivi boolean;
  v_rattachee boolean;
  v_a_prevenir boolean;
  v_recherche text;
  v_recherche_nom text;
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
  v_compteurs jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reponses importees reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune reponse importee lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.jsonb_typeof(v_filtre) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'filtre invalide : objet attendu' USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(k.cle, ', ' ORDER BY k.cle) INTO v_fautives
    FROM pg_catalog.jsonb_object_keys(v_filtre) AS k(cle)
   WHERE k.cle <> ALL (ARRAY['etat', 'suivi', 'rattachee', 'aPrevenir', 'recherche']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
    FROM pg_catalog.jsonb_each(v_filtre) e
   WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
     AND pg_catalog.jsonb_typeof(e.value) <> CASE WHEN e.key IN ('etat', 'recherche') THEN 'string' ELSE 'boolean' END;
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre mal type : %', v_fautives USING ERRCODE = '22023';
  END IF;
  v_etat := v_filtre ->> 'etat';
  v_suivi := (v_filtre ->> 'suivi')::boolean;
  v_rattachee := (v_filtre ->> 'rattachee')::boolean;
  v_a_prevenir := (v_filtre ->> 'aPrevenir')::boolean;
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');
  IF (v_etat IS NOT NULL AND v_etat NOT IN ('active', 'historique')) OR pg_catalog.length(v_recherche) > 200 THEN
    RAISE EXCEPTION 'valeur de filtre invalide' USING ERRCODE = '22023';
  END IF;
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;
  v_recherche_nom := nullif(private.cand_normaliser(v_recherche), '');

  WITH base AS (
    SELECT r.*,
           EXISTS (SELECT 1 FROM public.candidature_evenements e
                    WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu') AS prevenu
      FROM public.formulaires_reponses r
     WHERE v_super OR r.genre = v_genre
  ), filtrees AS MATERIALIZED (
    SELECT b AS ligne,
           pg_catalog.row_number() OVER (ORDER BY b.recue_le DESC, b.id ASC) AS rang
      FROM base b
     WHERE (v_etat IS NULL OR b.etat = v_etat)
       AND (v_suivi IS NULL OR (b.suivi_id IS NOT NULL) = v_suivi)
       AND (v_rattachee IS NULL OR (b.candidature_id IS NOT NULL) = v_rattachee)
       AND (v_a_prevenir IS NULL OR (b.etat = 'active' AND b.candidature_id IS NULL AND b.courriel IS NULL
                                     AND NOT b.prevenu) = v_a_prevenir)
       AND (v_recherche IS NULL
            OR b.reference_source = v_recherche
            OR b.courriel = pg_catalog.lower(v_recherche)
            OR (v_recherche_nom IS NOT NULL
                AND pg_catalog.strpos(private.cand_normaliser(b.nom_affiche), v_recherche_nom) > 0))
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.ligne).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', (f.ligne).id,
           'reference', (f.ligne).reference_source,
           'nomComplet', (f.ligne).nom_affiche,
           'recueLe', private.cand_instant((f.ligne).recue_le),
           'etat', (f.ligne).etat,
           'courrielAObtenir', (f.ligne).courriel IS NULL,
           'indicatifAConfirmer', (f.ligne).telephone_brut IS NOT NULL,
           'suivi', (f.ligne).suivi_id IS NOT NULL,
           'candidatureSuivieId', (f.ligne).suivi_id,
           'rattachee', (f.ligne).candidature_id IS NOT NULL,
           'prevenu', (f.ligne).prevenu,
           'aPrevenir', (f.ligne).etat = 'active' AND (f.ligne).candidature_id IS NULL
                        AND (f.ligne).courriel IS NULL AND NOT (f.ligne).prevenu) ORDER BY f.rang)
           FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50), '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
    FROM filtrees f;

  SELECT pg_catalog.jsonb_build_object(
           'actives', pg_catalog.count(*) FILTER (WHERE r.etat = 'active'),
           'historique', pg_catalog.count(*) FILTER (WHERE r.etat = 'historique'),
           'suivies', pg_catalog.count(*) FILTER (WHERE r.suivi_id IS NOT NULL),
           'rattachees', pg_catalog.count(*) FILTER (WHERE r.candidature_id IS NOT NULL),
           'aPrevenir', pg_catalog.count(*) FILTER (WHERE r.etat = 'active' AND r.candidature_id IS NULL
             AND r.courriel IS NULL
             AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                              WHERE e.candidature_id = r.suivi_id AND e.type = 'prevenu')))
    INTO v_compteurs
    FROM public.formulaires_reponses r
   WHERE v_super OR r.genre = v_genre;

  -- Une lecture de liste : la convention de la liste des candidatures
  -- (table candidatures, ligne nulle, genre du lecteur), pour que la ligne
  -- d'audit ne se lise que de son cote (CAND-L2A1, C15).
  PERFORM public.log_sensitive_access('formulaires_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page,
      'recherche', v_recherche IS NOT NULL));
  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes, 'total', v_total, 'page', p_page, 'taillePage', 50, 'compteurs', v_compteurs);
END;
$function$;

-- Garder une ligne importee « pour suivi » (transition 2, spec 3.2 : choix de
-- mise en oeuvre a confirmer, 0.3) : une candidature `recue`, SANS compte,
-- porte l'invitation ou la trace du lien envoye par WhatsApp. Ce n'est pas
-- une candidature deposee : elle n'entre en Salle d'examen que quand la
-- personne s'inscrit (meme courriel confirme). Geste de la direction, de son
-- cote seulement (le super-admin lit les deux cotes mais ne decide que du
-- sien). Une seule ligne de suivi par reponse importee : le rejeu rend la
-- meme (rejoue = true). Aucun contact n'est rendu.
CREATE FUNCTION public.garder_formulaire_pour_suivi(p_reponse uuid)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_lecteur uuid;
  v_genre public.gender;
  v_r public.formulaires_reponses;
  v_cid uuid;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre INTO v_lecteur, v_genre FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun geste tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_reponse IS NULL THEN
    RAISE EXCEPTION 'reponse importee attendue' USING ERRCODE = '22023';
  END IF;
  SELECT r.* INTO v_r FROM public.formulaires_reponses r WHERE r.id = p_reponse FOR UPDATE;
  IF v_r.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF v_r.genre IS DISTINCT FROM v_genre THEN
    -- La trace d'une tentative hors portee ne se lit que du cote vise (C15).
    PERFORM public.log_sensitive_access('formulaire_hors_portee', 'candidatures', NULL,
      pg_catalog.jsonb_build_object('reader_gender', v_r.genre, 'exception_active', false,
                                    'lecture', 'garder_pour_suivi'));
    RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
  END IF;
  IF v_r.suivi_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(v_r.suivi_id),
                                         'rejoue', true);
  END IF;
  IF v_r.etat <> 'active' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'ligne_historique');
  END IF;
  IF v_r.candidature_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'deja_rattachee');
  END IF;

  INSERT INTO public.candidatures (type_code, genre, nom_complet, etape, issue, source, source_ref)
  VALUES ('enseignant', v_r.genre, v_r.nom_affiche, 'recue', 'en_cours', 'import', v_r.reference_source)
  RETURNING id INTO v_cid;
  INSERT INTO public.candidature_contacts (candidature_id, courriel, courriel_brut, telephone, telephone_brut)
  VALUES (v_cid, v_r.courriel, v_r.courriel_brut, v_r.telephone, v_r.telephone_brut);
  INSERT INTO public.candidature_evenements (candidature_id, type, etape_apres, issue_apres, auteur_id, details)
  VALUES (v_cid, 'creee', 'recue', 'en_cours', v_uid,
          pg_catalog.jsonb_build_object('geste', 'garder_pour_suivi', 'transition', 2, 'auteur', 'direction',
                                        'reponse', v_r.id));
  UPDATE public.formulaires_reponses r
     SET suivi_id = v_cid, modifie_le = pg_catalog.clock_timestamp()
   WHERE r.id = v_r.id;
  INSERT INTO public.formulaires_journal (reponse_id, type, auteur_id, details)
  VALUES (v_r.id, 'suivi', v_uid, pg_catalog.jsonb_build_object('candidature', v_cid));
  PERFORM public.log_sensitive_access('candidature_geste', 'candidatures', v_cid::text,
    pg_catalog.jsonb_build_object('geste', 'garder_pour_suivi', 'transition', 2, 'auteur', 'direction',
                                  'etapeApres', 'recue', 'issueApres', 'en_cours', 'version', 1));
  RETURN pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(v_cid), 'rejoue', false);
END;
$function$;

-- La liste des personnes a prevenir (CAND-BR-16) : les lignes `recue` gardees
-- pour suivi, en cours, sans courriel valide ; le lien d'inscription leur
-- parvient par un message WhatsApp hors de l'app, le seul que le directeur
-- admette (CAND-Q06 ; spec 7.4). Le module n'envoie rien. Par defaut celles
-- dont l'envoi n'est pas encore consigne ; p_inclure_prevenus les rend toutes,
-- avec le canal et la date du dernier envoi consigne. Dans la portee de la
-- direction. Pas de contact : le numero se lit par lire_contact_candidature.
-- accordWhatsapp est la reponse de la personne a la question du formulaire
-- (« j'accepte que l'equipe me contacte par WhatsApp », MAPPAGE colonne M),
-- gardee avec sa reponse importee : vrai, faux, ou nul quand la ligne ne vient
-- d'aucune reponse importee. La liste ne la filtre pas (le directeur n'a pas
-- tranche, spec 0.2 bis) ; elle la montre, pour que personne ne contacte
-- sans le savoir quelqu'un qui n'a pas accepte.
CREATE FUNCTION public.lister_a_prevenir_candidats(p_inclure_prevenus boolean DEFAULT false,
                                                    p_page integer DEFAULT 1)
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
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'personnes a prevenir reservees a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucune personne a prevenir lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_inclure_prevenus IS NULL OR p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'arguments invalides : booleen et page (1 ou plus) attendus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;

  WITH base AS (
    SELECT c,
           (SELECT e.cree_le FROM public.candidature_evenements e
             WHERE e.candidature_id = c.id AND e.type = 'prevenu'
             ORDER BY e.cree_le DESC, e.id DESC LIMIT 1) AS prevenu_le,
           (SELECT e.details FROM public.candidature_evenements e
             WHERE e.candidature_id = c.id AND e.type = 'prevenu'
             ORDER BY e.cree_le DESC, e.id DESC LIMIT 1) AS prevenu_details,
           (SELECT r.consentement_whatsapp FROM public.formulaires_reponses r
             WHERE r.suivi_id = c.id) AS accord_whatsapp
      FROM public.candidatures c
     WHERE (v_super OR c.genre = v_genre)
       AND c.type_code = 'enseignant' AND c.etape = 'recue' AND c.issue = 'en_cours' AND c.profile_id IS NULL
       AND NOT EXISTS (SELECT 1 FROM public.candidature_contacts k
                        WHERE k.candidature_id = c.id AND k.courriel IS NOT NULL)
  ), filtrees AS MATERIALIZED (
    SELECT b.*, pg_catalog.row_number() OVER (ORDER BY (b.c).recue_le ASC, (b.c).id ASC) AS rang
      FROM base b
     WHERE p_inclure_prevenus OR b.prevenu_le IS NULL
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.c).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', (f.c).id,
           'reference', (f.c).reference,
           'nomComplet', (f.c).nom_complet,
           'version', (f.c).version,
           'recueLe', private.cand_instant((f.c).recue_le),
           'indicatifAConfirmer', EXISTS (SELECT 1 FROM public.candidature_contacts k
                                           WHERE k.candidature_id = (f.c).id AND k.telephone_brut IS NOT NULL),
           'prevenu', f.prevenu_le IS NOT NULL,
           'prevenuLe', private.cand_instant(f.prevenu_le),
           'canal', f.prevenu_details ->> 'canal',
           'dateEnvoi', f.prevenu_details ->> 'date',
           'accordWhatsapp', f.accord_whatsapp) ORDER BY f.rang)
           FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50), '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
    FROM filtrees f;

  PERFORM public.log_sensitive_access('a_prevenir_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page));
  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes, 'total', v_total, 'page', p_page, 'taillePage', 50);
END;
$function$;

-- Consigner qu'une personne a ete prevenue (transition 26, CAND-BR-16) : le
-- lien d'inscription lui a ete envoye par WhatsApp, hors de l'app, pour une
-- ligne `recue` sans courriel valide. La direction constate un envoi fait
-- ailleurs, de son cote ; le module n'envoie jamais. Liste fermee : canal
-- whatsapp, modele lien_inscription, jamais un texte libre ; la date est celle
-- de l'envoi, non future. Par le moteur : version attendue, cle d'idempotence.
CREATE FUNCTION public.consigner_prevenu_candidat(
  p_id uuid,
  p_canal text,
  p_modele text,
  p_date date,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_o jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_canal IS NULL OR p_modele IS NULL OR p_date IS NULL THEN
    RAISE EXCEPTION 'canal, modele et date de l''envoi attendus' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'consigner_prevenu', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  IF p_canal <> 'whatsapp' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'canal_inconnu');
  END IF;
  IF p_modele <> 'lien_inscription' THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modele_inconnu');
  END IF;
  IF p_date > (pg_catalog.now() AT TIME ZONE 'UTC')::date THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'date_future');
  END IF;
  -- Une personne qui a un courriel valide s'invite par courriel (transition 3),
  -- elle ne se prévient pas par WhatsApp.
  IF EXISTS (SELECT 1 FROM public.candidature_contacts k WHERE k.candidature_id = p_id AND k.courriel IS NOT NULL) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'courriel_disponible');
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'consigner_prevenu', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, p_modele, '{}'::jsonb,
    pg_catalog.jsonb_build_object('canal', p_canal, 'date', p_date));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'consigner_prevenu', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Les rapprochements par telephone proposes a la direction (spec 3.4) : une
-- reponse importee et une candidature en Salle d'examen a completer, du meme
-- cote, qui partagent un telephone normalise. La direction voit les deux noms
-- pour decider si c'est la meme personne ; la personne ne voit rien.
CREATE FUNCTION public.lister_rapprochements_candidats(p_page integer DEFAULT 1)
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
  v_offset bigint;
  v_total integer;
  v_hors_genre integer;
  v_lignes jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'rapprochements reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre, l.super_admin INTO v_lecteur, v_genre, v_super FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR NOT (v_super OR v_genre IS NOT NULL) THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun rapprochement lisible tant qu''il n''est pas renseigne'
      USING ERRCODE = '42501';
  END IF;
  IF p_page IS NULL OR p_page < 1 THEN
    RAISE EXCEPTION 'page invalide : 1 ou plus' USING ERRCODE = '22023';
  END IF;
  v_offset := (p_page::bigint - 1) * 50;

  WITH filtrees AS MATERIALIZED (
    SELECT p, r, c, pg_catalog.row_number() OVER (ORDER BY p.cree_le ASC, p.id ASC) AS rang
      FROM public.formulaires_rapprochements p
      JOIN public.formulaires_reponses r ON r.id = p.reponse_id
      JOIN public.candidatures c ON c.id = p.candidature_id
     WHERE (v_super OR c.genre = v_genre)
       AND p.statut = 'proposee' AND r.etat = 'active' AND r.candidature_id IS NULL
       AND c.issue = 'en_cours' AND c.etape = 'prequalification' AND c.etat = 'a_completer'
       -- Une proposition ne se liste que tant qu'elle tient et qu'elle peut
       -- s'appliquer : le meme cote (un fichier corrige peut changer le genre
       -- d'une ligne apres la proposition : la ligne de l'autre cote ne se lirait
       -- plus ici que par son nom), le meme telephone (une correction peut le
       -- changer), une candidature pas encore reliee a une ligne.
       AND r.genre = c.genre
       AND r.telephone IS NOT NULL
       AND EXISTS (SELECT 1 FROM public.candidature_contacts k
                    WHERE k.candidature_id = c.id AND k.telephone = r.telephone)
       AND NOT EXISTS (SELECT 1 FROM public.formulaires_reponses x WHERE x.candidature_id = c.id)
  )
  SELECT pg_catalog.count(*)::integer,
         pg_catalog.count(*) FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50
                                       AND (f.c).genre IS DISTINCT FROM v_genre)::integer,
         coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
           'id', (f.p).id,
           'cle', (f.p).cle,
           'proposeLe', private.cand_instant((f.p).cree_le),
           'reponse', pg_catalog.jsonb_build_object(
             'id', (f.r).id, 'reference', (f.r).reference_source, 'nomComplet', (f.r).nom_affiche,
             'recueLe', private.cand_instant((f.r).recue_le)),
           'candidature', pg_catalog.jsonb_build_object(
             'id', (f.c).id, 'reference', (f.c).reference, 'nomComplet', (f.c).nom_complet,
             'version', (f.c).version)) ORDER BY f.rang)
           FILTER (WHERE f.rang > v_offset AND f.rang <= v_offset + 50), '[]'::jsonb)
    INTO v_total, v_hors_genre, v_lignes
    FROM filtrees f;

  PERFORM public.log_sensitive_access('rapprochements_liste', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'exception_active', v_super,
      'lignes_hors_genre', v_hors_genre,
      'total', v_total,
      'page', p_page));
  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes, 'total', v_total, 'page', p_page, 'taillePage', 50);
END;
$function$;

-- Rattacher les reponses importees a une candidature (transition 27) : la
-- direction applique une proposition par telephone (spec 3.4). Par le moteur
-- (version attendue, cle d'idempotence, son cote). La reponse est reliee, le
-- brouillon pre-rempli (ce que la personne a deja ecrit l'emporte), et la
-- ligne `recue` gardee pour suivi, si elle existe, est retiree : la personne
-- est inscrite. Rend l'etat de la candidature et les codes pre-remplis.
CREATE FUNCTION public.rattacher_formulaire_candidat(
  p_id uuid,
  p_reponse uuid,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_o jsonb;
  v_c public.candidatures;
  v_r public.formulaires_reponses;
  v_p public.formulaires_rapprochements;
  v_lien jsonb;
  v_suivi public.candidatures;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_reponse IS NULL THEN
    RAISE EXCEPTION 'reponse importee attendue' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'rattacher', 'direction', v_uid, p_version_attendue,
                                          p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  SELECT r.* INTO v_r FROM public.formulaires_reponses r WHERE r.id = p_reponse FOR UPDATE;
  SELECT p.* INTO v_p FROM public.formulaires_rapprochements p
   WHERE p.reponse_id = p_reponse AND p.candidature_id = p_id;
  IF v_r.id IS NULL OR v_p.id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_inconnue');
  END IF;
  -- La proposition tient tant que la ligne est du meme cote et porte encore le
  -- telephone de la candidature (un fichier corrige peut changer l'un et l'autre).
  IF v_r.genre IS DISTINCT FROM v_c.genre OR v_r.telephone IS NULL
     OR NOT EXISTS (SELECT 1 FROM public.candidature_contacts k
                     WHERE k.candidature_id = p_id AND k.telephone = v_r.telephone) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'proposition_inconnue');
  END IF;
  IF v_r.etat <> 'active' OR v_r.candidature_id IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reponse_deja_rattachee');
  END IF;
  IF EXISTS (SELECT 1 FROM public.formulaires_reponses x WHERE x.candidature_id = p_id) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'candidature_deja_rattachee');
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'rattacher', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('reponse', p_reponse, 'cle', 'telephone'));
  v_lien := private.formulaires_relier(p_reponse, p_id, 'telephone', v_uid);
  UPDATE public.formulaires_rapprochements p
     SET statut = 'appliquee', applique_le = pg_catalog.clock_timestamp(), applique_par = v_uid
   WHERE p.id = v_p.id;
  -- La ligne gardee pour suivi n'a plus d'objet : la personne est inscrite.
  IF v_r.suivi_id IS NOT NULL THEN
    SELECT c.* INTO v_suivi FROM public.candidatures c
     WHERE c.id = v_r.suivi_id AND c.profile_id IS NULL AND c.etape = 'recue' AND c.issue = 'en_cours'
     FOR UPDATE;
    IF v_suivi.id IS NOT NULL THEN
      UPDATE public.candidatures c
         SET issue = 'retiree', version = c.version + 1, derniere_activite = pg_catalog.clock_timestamp()
       WHERE c.id = v_suivi.id;
      INSERT INTO public.candidature_evenements
        (candidature_id, type, etape_avant, etape_apres, issue_avant, issue_apres, auteur_id, details)
      VALUES (v_suivi.id, 'transition', 'recue', 'recue', 'en_cours', 'retiree', v_uid,
              pg_catalog.jsonb_build_object('geste', 'rattacher', 'transition', 27, 'auteur', 'direction',
                                            'cause', 'inscrite', 'candidatureInscrite', p_id));
    END IF;
  END IF;
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'rattacher', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'prerempli', v_lien -> 'prerempli'));
END;
$function$;

-- ============================================================
-- 10. Capacites : l'import, le suivi, le rattachement
-- ============================================================

-- capacites_candidatures : corps de 20261022000100_cand_l2a2_gestes_direction.sql
-- recopie (garde, lecteur, contact, exception, une capacite par geste, listes
-- fermees) ; ajouts de CAND-L3 : peutImporter (super-admin en double
-- verification) et doubleVerificationRequise (super-admin en aal1),
-- consignerPrevenu, garderPourSuivi et rattacher (la direction, de son cote),
-- et les listes du geste « prevenu ». inviter reste faux (avec la file des
-- courriels, L5).
CREATE OR REPLACE FUNCTION public.capacites_candidatures()
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
  v_decider boolean;
  v_aal2 boolean;
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
  -- CAND-L2A2 (D13) : un geste ne vaut que de son cote ; l'exception
  -- super-admin reste une exception de lecture.
  v_decider := v_admin AND v_genre IS NOT NULL;
  -- CAND-L3 : l'import des formulaires est celui du super-admin en double verification (aal2, exigee en base).
  v_aal2 := coalesce(public.app_aal() = 'aal2', false);
  RETURN pg_catalog.jsonb_build_object(
    'peutLire', v_lire,
    'peutVoirContact', v_lire AND coalesce(v_contact, false),
    'peutLireHorsGenre', v_super,
    'genreLecteurConnu', v_admin AND v_genre IS NOT NULL,
    'peutDecider', v_decider,
    'peutImporter', v_super AND v_aal2,
    'doubleVerificationRequise', v_super AND NOT v_aal2,
    'peutMenerEntretien', false,
    'peutEcrireReferentiel', coalesce(private.paiement_gestionnaire(), false),
    'gestes', pg_catalog.jsonb_build_object(
      'demanderComplement', v_decider,
      'cloreComplement', v_decider,
      'admettreVerifications', v_decider,
      'confirmerMoyenPaiement', v_decider,
      'infirmerMoyenPaiement', v_decider,
      'mettreEnPause', v_decider,
      'leverPause', v_decider,
      'refuser', v_decider,
      'consignerRetrait', v_decider,
      'rouvrir', v_decider,
      'definirResponsable', v_decider,
      'agirEnLot', v_decider,
      'inviter', false,
      'consignerPrevenu', v_decider,
      'garderPourSuivi', v_decider,
      'rattacher', v_decider,
      'planifierEntretien', false,
      'consignerEntretien', false,
      'pieceACorriger', false,
      'validerPiece', false,
      'restreindre', false,
      'leverRestriction', false,
      'noterIndisponibilite', false,
      'leverIndisponibilite', false),
    'gestesGroupables', CASE WHEN v_decider THEN '["mettreEnPause", "leverPause", "refuser"]'::jsonb
                             ELSE '[]'::jsonb END,
    'listes', pg_catalog.jsonb_build_object(
      'modelesRefus', CASE WHEN v_decider THEN coalesce((
        SELECT pg_catalog.jsonb_agg(m.code ORDER BY m.rang) FROM private.candidature_modeles_message m
         WHERE m.usage = 'refus' AND m.actif), '[]'::jsonb) ELSE '[]'::jsonb END,
      'modelesPause', CASE WHEN v_decider THEN coalesce((
        SELECT pg_catalog.jsonb_agg(m.code ORDER BY m.rang) FROM private.candidature_modeles_message m
         WHERE m.usage = 'pause' AND m.actif), '[]'::jsonb) ELSE '[]'::jsonb END,
      'complementSalleExamen', CASE WHEN v_decider
        THEN pg_catalog.to_jsonb(private.candidature_complement_codes('prequalification', 'enseignant'))
        ELSE '[]'::jsonb END,
      'complementSalleVerification', CASE WHEN v_decider
        THEN pg_catalog.to_jsonb(private.candidature_complement_codes('verifications', 'enseignant'))
        ELSE '[]'::jsonb END,
      'canauxRetrait', CASE WHEN v_decider THEN '["conversation", "courriel"]'::jsonb ELSE '[]'::jsonb END,
      'codesClotureComplement', CASE WHEN v_decider THEN '["complement_clos"]'::jsonb ELSE '[]'::jsonb END,
      'canauxPrevenu', CASE WHEN v_decider THEN '["whatsapp"]'::jsonb ELSE '[]'::jsonb END,
      'modelesPrevenu', CASE WHEN v_decider THEN '["lien_inscription"]'::jsonb ELSE '[]'::jsonb END));
END;
$function$;

-- ============================================================
-- 11. Droits, empreintes F86, controle final
-- ============================================================

REVOKE ALL ON FUNCTION
  private.inscription_reglages_valider(),
  private.formulaires_chiffres(text),
  private.formulaires_texte(text),
  private.formulaires_compact(text),
  private.formulaires_courriel(text),
  private.formulaires_telephone(text),
  private.formulaires_horodatage(text, text),
  private.formulaires_classes(text),
  private.formulaires_option(text, text),
  private.formulaires_lire(text, text, text, jsonb, text),
  private.formulaires_planifier(jsonb, jsonb),
  private.formulaires_prerempli(uuid, uuid),
  private.formulaires_relier(uuid, uuid, text, uuid),
  private.formulaires_proposer(uuid, text, public.gender, uuid, uuid),
  private.formulaires_rapprocher_inscription(uuid, text, text, public.gender, uuid),
  private.formulaires_rapprocher_reponse(uuid, uuid),
  private.formulaires_jeton(uuid, text, text, text, jsonb, text)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.inscription_candidat_ouverte()',
    'public.inscrire_candidat(text,text,text,public.gender,text,text,text)',
    'public.apercu_import_formulaires(text,text,text,jsonb,text)',
    'public.confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)',
    'public.lister_formulaires_importes(jsonb,integer)',
    'public.garder_formulaire_pour_suivi(uuid)',
    'public.lister_a_prevenir_candidats(boolean,integer)',
    'public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)',
    'public.lister_rapprochements_candidats(integer)',
    'public.rattacher_formulaire_candidat(uuid,uuid,integer,text)',
    'public.capacites_candidatures()'
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
  v_ancien text;
BEGIN
  FOR v IN
    SELECT * FROM (VALUES
      ('public.inscription_candidat_ouverte()', 'SESSION_REQUIRED_CAPABILITY_READ',
       'Lecture seule : la cle de mise en ligne de l inscription sans code (fausse par defaut) et la version de confidentialite attendue. Sans session : 42501.'),
      ('public.inscrire_candidat(text,text,text,public.gender,text,text,text)', 'SESSION_POSITIVE',
       'Session avec adresse, sans profil (42501 sinon) ; courriel confirme (auth.users.email_confirmed_at) sinon rien n est cree ; sans code : cle de mise en ligne vraie, sinon fermee ; plafond par heure (app_config) au-dela duquel la reponse est celle du succes, sans ecriture ; avec code : code lie a l adresse, non revoque, non consomme, non expire ; genre, telephone avec indicatif, langue fr ou ar et accord de confidentialite a la version attendue, sinon refus rendus sans ecriture. Fabrique private.creer_profil_inscription_interne (role teacher, pending_kyc) ; candidature en Salle d examen a completer ; rapprochement avec les reponses importees (courriel confirme : lien et pre-remplissage ; telephone : proposition a la direction). DEFINER : auth.users, invitations_enseignant, app_config.'),
      ('public.apercu_import_formulaires(text,text,text,jsonb,text)', 'ROLE_POSITIVE_SUPER_ADMIN_AAL2',
       'Direction active (garde positive) ET super-admin de 0088 (42501 sinon) ET aal2 lue dans le jeton (double_verification_requise rendu sinon) ; essai a blanc : aucune ecriture de donnees, une ligne audit_logs sans nom ni contact ; rend compteurs, groupes (nature seulement) et jeton HMAC sous la cle du serveur.'),
      ('public.confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)', 'ROLE_POSITIVE_SUPER_ADMIN_AAL2',
       'Memes gardes que l apercu ; cle d idempotence (rejeu = meme rapport, cle d un autre fichier ou auteur refusee) ; jeton de l apercu ; choix de doublons valides ; ecrit des reponses importees, un journal et un lot, jamais un compte, une invitation, une piece, un accord ni une candidature ; un import a la fois (verrou) ; rapport sans nom.'),
      ('public.lister_formulaires_importes(jsonb,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active de genre connu (42501 sinon) ; portee par genre dans le WHERE, le super-admin lit les deux cotes ; filtres 22023 ; aucune cle courriel, telephone, genre ni reponse ; audit de chaque liste borne a son cote.'),
      ('public.garder_formulaire_pour_suivi(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active de genre connu ; son cote seulement (hors_portee rendu et trace du cote vise, super-admin compris) ; une ligne recue sans compte par reponse importee (rejeu = la meme) ; refus rendus : absente, ligne_historique, deja_rattachee.'),
      ('public.lister_a_prevenir_candidats(boolean,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active de genre connu ; lignes recue sans courriel valide, dans la portee du lecteur ; aucun contact rendu ; audit de chaque liste borne a son cote.'),
      ('public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur de CAND-L2A1 (transition 26, ligne recue, hors pause) ; canal whatsapp et modele lien_inscription seuls, date non future, ligne sans courriel valide, sinon refus rendus sans ecriture ; le module n envoie rien.'),
      ('public.lister_rapprochements_candidats(integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active de genre connu ; propositions par telephone d une candidature en Salle d examen a completer, dans la portee du lecteur ; audit de chaque liste borne a son cote.'),
      ('public.rattacher_formulaire_candidat(uuid,uuid,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 27, a_completer, hors pause) ; proposition existante du meme cote, reponse libre, candidature non deja rattachee, sinon refus rendus sans ecriture ; lien journalise, brouillon pre-rempli, ligne de suivi retiree.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-23. CAND-L3. %s Must-pass: supabase/tests/scenarios_cand_l3_inscription_import.sql.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note));
  END LOOP;

  -- capacites_candidatures garde son commentaire (CAND-L1, CAND-L2A2) : seule
  -- l'empreinte change, et la ligne de CAND-L3 s'y ajoute.
  v_ancien := pg_catalog.obj_description('public.capacites_candidatures()'::regprocedure, 'pg_proc');
  EXECUTE pg_catalog.format('COMMENT ON FUNCTION public.capacites_candidatures() IS %L',
    pg_catalog.regexp_replace(v_ancien, 'md5_functiondef=[0-9a-f]{32}',
      'md5_functiondef=' || pg_catalog.md5(pg_catalog.pg_get_functiondef('public.capacites_candidatures()'::regprocedure)))
    || ' CAND-L3 : peutImporter (super-admin en aal2) et doubleVerificationRequise (super-admin en aal1), geste consignerPrevenu, garderPourSuivi et rattacher, listes canauxPrevenu et modelesPrevenu. Must-pass: supabase/tests/scenarios_cand_l3_inscription_import.sql.');
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Les RPC client : DEFINER, proprietaire postgres, search_path vide,
  -- volatilite attendue, empreinte F86 a jour, authenticated seul, garde
  -- positive sur le role ET app_account_valid(), aucun nom qui contienne
  -- candidature.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.inscription_candidat_ouverte()', 's'),
      ('public.inscrire_candidat(text,text,text,public.gender,text,text,text)', 'v'),
      ('public.apercu_import_formulaires(text,text,text,jsonb,text)', 'v'),
      ('public.confirmer_import_formulaires(text,text,text,text,jsonb,text,jsonb,text)', 'v'),
      ('public.lister_formulaires_importes(jsonb,integer)', 'v'),
      ('public.garder_formulaire_pour_suivi(uuid)', 'v'),
      ('public.lister_a_prevenir_candidats(boolean,integer)', 'v'),
      ('public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)', 'v'),
      ('public.lister_rapprochements_candidats(integer)', 'v'),
      ('public.rattacher_formulaire_candidat(uuid,uuid,integer,text)', 'v'),
      ('public.capacites_candidatures()', 's')
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
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc)
       OR (v.prosrc LIKE '%app_role()%' AND v.prosrc NOT LIKE '%app_account_valid%')
       OR (v.proname LIKE '%candidature%'
           AND v.proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature')) THEN
      RAISE EXCEPTION 'CAND-L3 : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL, garde ou nom invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Les gestes passent par le moteur de CAND-L2A1.
  FOR v IN
    SELECT p.oid, p.prosrc FROM pg_catalog.pg_proc p
    WHERE p.oid IN ('public.consigner_prevenu_candidat(uuid,text,text,date,integer,text)'::regprocedure,
                    'public.rattacher_formulaire_candidat(uuid,uuid,integer,text)'::regprocedure)
  LOOP
    IF pg_catalog.strpos(v.prosrc, 'private.candidature_geste_ouvrir') = 0
       OR pg_catalog.strpos(v.prosrc, 'private.candidature_geste_appliquer') = 0
       OR pg_catalog.strpos(v.prosrc, 'private.candidature_geste_conclure') = 0 THEN
      RAISE EXCEPTION 'CAND-L3 : geste hors du moteur : %', v.oid::regprocedure;
    END IF;
  END LOOP;

  -- Les aides internes : appelables par aucun compte ; aucune aide cand_ de
  -- plus (neuf, CAND-L1) ni candidature_ de plus (les neuf de CAND-L2A2 et
  -- les autres de CAND-L2A1/L6).
  FOR v IN
    SELECT p.oid FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'private'::regnamespace
      AND (p.proname LIKE 'formulaires\_%' OR p.proname = 'inscription_reglages_valider')
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L3 : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
      WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'formulaires\_%') <> 16
     OR (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
         WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-L3 : seize aides formulaires_ attendues et les neuf aides cand_ de CAND-L1 inchangees';
  END IF;

  -- Les tables du lot : RLS active, aucun privilege client, aucune policy.
  FOR v IN
    SELECT c.oid, c.relrowsecurity FROM pg_catalog.pg_class c
    WHERE c.oid IN ('public.candidat_accords_confidentialite'::regclass, 'private.inscriptions_publiques'::regclass,
                    'private.indicatifs_telephoniques'::regclass, 'private.formulaires_entetes'::regclass,
                    'private.formulaires_libelles'::regclass, 'public.formulaires_lots'::regclass,
                    'public.formulaires_reponses'::regclass, 'public.formulaires_journal'::regclass,
                    'public.formulaires_rapprochements'::regclass, 'public.formulaires_choix_doublons'::regclass)
  LOOP
    IF NOT v.relrowsecurity THEN
      RAISE EXCEPTION 'CAND-L3 : RLS inactive sur %', v.oid::regclass;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_table_privilege(v_role, v.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L3 : % garde un privilege sur %', v_role, v.oid::regclass;
      END IF;
    END LOOP;
    IF pg_catalog.obj_description(v.oid, 'pg_class') IS NULL THEN
      RAISE EXCEPTION 'CAND-L3 : table sans commentaire : %', v.oid::regclass;
    END IF;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies
              WHERE (schemaname = 'public' AND tablename IN ('candidat_accords_confidentialite', 'formulaires_lots',
                                                             'formulaires_reponses', 'formulaires_journal',
                                                             'formulaires_rapprochements', 'formulaires_choix_doublons'))
                 OR (schemaname = 'private' AND tablename IN ('inscriptions_publiques', 'indicatifs_telephoniques',
                                                              'formulaires_entetes', 'formulaires_libelles'))) THEN
    RAISE EXCEPTION 'CAND-L3 : une policy ouvre une table du lot';
  END IF;

  -- Les reglages : la mise en ligne est fausse a l'application de la migration
  -- (spec 3.1, condition 6) ; le plafond et la version existent.
  IF (SELECT c.value FROM public.app_config c WHERE c.key = 'candidatures.inscription_publique_ouverte')
       IS DISTINCT FROM 'false'::jsonb
     OR (SELECT c.value FROM public.app_config c WHERE c.key = 'candidatures.inscriptions_par_heure') IS NULL
     OR (SELECT c.value FROM public.app_config c WHERE c.key = 'candidatures.confidentialite_version') IS NULL THEN
    RAISE EXCEPTION 'CAND-L3 : reglages de l inscription publique absents ou la mise en ligne n est pas fausse';
  END IF;

  -- La table des regles du moteur est celle de CAND-L2A1 (inviter, consigner_prevenu, rattacher y sont deja).
  IF (SELECT pg_catalog.count(*) FROM private.candidature_gestes_regles) <> 26
     OR NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = 'consigner_prevenu')
     OR NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r WHERE r.geste = 'rattacher') THEN
    RAISE EXCEPTION 'CAND-L3 : table des regles du moteur differente de ce que le lot suppose';
  END IF;
END;
$postflight$;

COMMIT;
