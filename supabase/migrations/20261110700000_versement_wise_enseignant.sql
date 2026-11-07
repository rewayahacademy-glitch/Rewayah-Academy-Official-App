-- FINANCE-ENSEIGNANT (lot 9, 06/11/2026) : la paie des enseignants par
-- paiement groupe Wise (fichier CSV importe dans Wise).
--
-- Decision du directeur, 06/11/2026 vers 22:12 UTC, relayee par le garde-cap :
-- « on passera par wise, qui permet d'importer un fichier excel pour le bulk
-- paiement. tu dois preparer un systeme qui peut importer les donnees des
-- enseignants pour qu'ils recoivent leurs paiements via wise (juste un CSV)...
-- apres le lancement on va connecter pawa pay et eventuellement verto ».
--
-- Le modele Wise : « Envoyer vers des comptes bancaires », USD vers USD,
-- telecharge par le directeur le 06/11/2026 (transmis par le garde-cap a 22:40
-- UTC). Ses 17 en-tetes sont poses ici, dans l'ordre, comme modele par defaut
-- (`versement_wise_colonnes`, version 1) ; un changement futur pose une
-- version nouvelle (`poser_modele_wise`), sans rien effacer.
--
-- Decisions du directeur, 06/11/2026 vers 22:30 UTC : les frais Wise sont
-- payes par l'academie (amountCurrency = target) ; une seule devise, l'USD,
-- source et cible, pour tous les enseignants.
--
-- Compte au nom d'un tiers (directeur, 06/11/2026 vers 22:55 UTC : « il faudra
-- permettre a un enseignant d'utiliser le compte qui n'est pas a son nom pour
-- recevoir son paiement, car beaucoup n'ont pas de compte en leurs noms ») :
-- `name` du fichier reste le nom du TITULAIRE ; si le compte n'est pas au nom
-- de l'enseignant, il dit son lien avec le titulaire et donne son accord
-- date. Protection contre le detournement : TOUT enregistrement (premier ou
-- changement) n'entre dans le fichier qu'apres validation par la direction
-- (`valider_coordonnees_versement`, journalise) ; chaque changement et chaque
-- validation envoient un courriel a l'enseignant (`courriel_enfiler`).
--
-- Pays ou Wise ne verse pas (garde-cap, 06/11/2026 ; Yemen interdit par Wise,
-- wise.com/help/articles/2978049) : le refus lit le referentiel existant
-- `public.referentiel_paiement` (CAND-L6), seule source de verite : un pays
-- dont le virement bancaire est `indisponible` est refuse. C'est le pays du
-- COMPTE et de l'adresse du titulaire (`adresse_pays`), jamais le pays ou vit
-- l'enseignant : un enseignant au Yemen peut donner le compte d'un proche en
-- Arabie saoudite. Le Yemen y passe a `indisponible` par la migration du lot
-- CAND-BANQUE ; ce fichier n'ecrit rien dans le referentiel.
--
-- Non prouve : qu'un paiement groupe passe par la voie SWIFT en USD vers la
-- Guinee, le Mali, la Mauritanie ou le Senegal (Wise l'accepte pour un virement
-- simple, wise.com/help/articles/2974947 ; aucune page ne relie les deux) ; des
-- banques intermediaires peuvent retenir des frais sur un virement SWIFT.
--
-- Regles (garde-cap, 06/11/2026) :
--   * coordonnees stockees en clair (Wise en a besoin), MAIS : RLS, aucun acces
--     direct ; l'enseignant ecrit et relit SEULEMENT les siennes, les numeros
--     masques sauf les 4 derniers caracteres ; lecture complete seulement par
--     l'export, reserve a admin et accountant, chaque export journalise (qui,
--     quand, quel mois, combien de lignes) ;
--   * aucun effacement : un changement ou un retrait rend l'ancienne ligne
--     inactive ;
--   * prestataire 'wise' ; 'pawapay' et 'verto' admis par la contrainte, rien
--     n'est code pour eux ;
--   * montant d'une ligne = le du de `releve_paie_mensuel` (enseignants[].montant,
--     total payable, jamais recalcule ici), moins les versements deja notes
--     du mois (`versements_paie`, non annules). Devise source USD ;
--   * un enseignant sans coordonnees completes n'entre pas dans le fichier : il
--     est rendu a part, « coordonnees manquantes ».
-- SECURITY DEFINER, search_path vide ; aucune instruction d'effacement.
--
-- `versements_paie` (20261110710000) est lu par l'export a l'execution
-- seulement : l'ordre d'installation des deux fichiers ne casse rien, mais
-- l'export exige les deux.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Reglages : champs requis par devise cible, colonnes du modele Wise
-- ---------------------------------------------------------------------------
-- Les champs que l'enseignant saisit pour une devise cible. `obligatoire` :
-- requis ; `si_pays` : le champ n'est demande que pour ces pays d'adresse
-- (nul : toujours demande).
CREATE TABLE public.versement_champs_requis (
  prestataire text NOT NULL CHECK (prestataire IN ('wise', 'pawapay', 'verto')),
  devise_cible text NOT NULL CHECK (devise_cible ~ '^[A-Z]{3}$'),
  champ text NOT NULL CHECK (champ IN ('titulaire', 'numero_compte', 'iban', 'swift',
    'adresse_pays', 'adresse_ville', 'adresse_ligne', 'adresse_etat', 'code_postal')),
  obligatoire boolean NOT NULL DEFAULT true,
  si_pays text[],
  ordre integer NOT NULL,
  PRIMARY KEY (prestataire, devise_cible, champ)
);
ALTER TABLE public.versement_champs_requis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versement_champs_requis FROM PUBLIC, anon, authenticated, service_role;

-- Ce que l'enseignant saisit pour le modele Wise USD, et rien d'autre (garde-
-- cap, 06/11) : name, accountNumber (numero ou IBAN), BIC, addressCountryCode,
-- addressCity, addressFirstLine ; addressState seulement aux Etats-Unis et au
-- Canada ; addressPostCode facultatif (la Guinee n'en a pas).
INSERT INTO public.versement_champs_requis (prestataire, devise_cible, champ, obligatoire, si_pays, ordre)
VALUES ('wise', 'USD', 'titulaire', true, NULL, 1),
       ('wise', 'USD', 'numero_compte', true, NULL, 2),
       ('wise', 'USD', 'swift', true, NULL, 3),
       ('wise', 'USD', 'adresse_pays', true, NULL, 4),
       ('wise', 'USD', 'adresse_ville', true, NULL, 5),
       ('wise', 'USD', 'adresse_ligne', true, NULL, 6),
       ('wise', 'USD', 'adresse_etat', true, ARRAY['US', 'CA'], 7),
       ('wise', 'USD', 'code_postal', false, NULL, 8);

-- Les colonnes du fichier, dans l'ordre du modele Wise. `source` dit d'ou
-- vient la valeur ; `champ` nomme la coordonnee (source = 'champ') ;
-- `valeur_fixe` la valeur ecrite telle quelle (source = 'fixe'). La version
-- la plus haute fait foi ; les anciennes restent.
CREATE TABLE public.versement_wise_colonnes (
  version integer NOT NULL CHECK (version >= 1),
  ordre integer NOT NULL CHECK (ordre BETWEEN 1 AND 60),
  en_tete text NOT NULL CHECK (pg_catalog.char_length(en_tete) BETWEEN 1 AND 80
                               AND en_tete !~ '[,"\r\n]'),
  source text NOT NULL CHECK (source IN ('champ', 'montant', 'devise_source', 'devise_cible',
    'type_montant', 'reference', 'matricule', 'courriel', 'fixe', 'vide')),
  champ text CHECK ((source = 'champ') = (champ IS NOT NULL) AND (champ IS NULL OR champ IN (
    'titulaire', 'numero_compte', 'iban', 'swift', 'adresse_pays', 'adresse_ville',
    'adresse_ligne', 'adresse_etat', 'code_postal'))),
  valeur_fixe text CHECK ((source = 'fixe') = (valeur_fixe IS NOT NULL)
                          AND (valeur_fixe IS NULL OR valeur_fixe !~ '[,"\r\n]')),
  pose_par uuid REFERENCES public.profiles(id),
  pose_le timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (version, ordre),
  UNIQUE (version, en_tete)
);
ALTER TABLE public.versement_wise_colonnes ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versement_wise_colonnes FROM PUBLIC, anon, authenticated, service_role;

-- Le modele telecharge par le directeur le 06/11/2026 (version 1). Valeurs
-- fixes decidees : receiverType PERSON, type SwiftCode ; amountCurrency vient
-- du reglage (target : frais payes par l'academie).
INSERT INTO public.versement_wise_colonnes (version, ordre, en_tete, source, champ, valeur_fixe)
VALUES (1, 1, 'name', 'champ', 'titulaire', NULL),
       (1, 2, 'recipientEmail', 'courriel', NULL, NULL),
       (1, 3, 'paymentReference', 'reference', NULL, NULL),
       (1, 4, 'referenceNumber', 'matricule', NULL, NULL),
       (1, 5, 'receiverType', 'fixe', NULL, 'PERSON'),
       (1, 6, 'amountCurrency', 'type_montant', NULL, NULL),
       (1, 7, 'amount', 'montant', NULL, NULL),
       (1, 8, 'sourceCurrency', 'devise_source', NULL, NULL),
       (1, 9, 'targetCurrency', 'devise_cible', NULL, NULL),
       (1, 10, 'type', 'fixe', NULL, 'SwiftCode'),
       (1, 11, 'accountNumber', 'champ', 'numero_compte', NULL),
       (1, 12, 'BIC', 'champ', 'swift', NULL),
       (1, 13, 'addressCountryCode', 'champ', 'adresse_pays', NULL),
       (1, 14, 'addressCity', 'champ', 'adresse_ville', NULL),
       (1, 15, 'addressFirstLine', 'champ', 'adresse_ligne', NULL),
       (1, 16, 'addressState', 'champ', 'adresse_etat', NULL),
       (1, 17, 'addressPostCode', 'champ', 'code_postal', NULL);

-- Reglages (A5) : devise source (USD, decision du directeur du 06/11) ; type
-- de montant : target, le montant exact recu, frais payes par l'academie
-- (decision du directeur du 06/11 ; wise.com/help/articles/5iWcIUdYHyTQMnezSzx4n3).
INSERT INTO public.app_config (key, value)
VALUES ('versement.wise_devise_source', '"USD"'::jsonb),
       ('versement.wise_type_montant', '"target"'::jsonb)
ON CONFLICT (key) DO NOTHING;

CREATE FUNCTION private.versement_reglage(p_cle text)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT CASE WHEN pg_catalog.jsonb_typeof(c.value) = 'string' THEN c.value #>> '{}' END
    FROM public.app_config c WHERE c.key = p_cle;
$function$;
REVOKE ALL ON FUNCTION private.versement_reglage(text) FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2. Les coordonnees de versement et le journal
-- ---------------------------------------------------------------------------
CREATE TABLE public.versement_coordonnees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL REFERENCES public.profiles(id),
  prestataire text NOT NULL DEFAULT 'wise' CHECK (prestataire IN ('wise', 'pawapay', 'verto')),
  devise_cible text NOT NULL CHECK (devise_cible ~ '^[A-Z]{3}$'),
  titulaire text CHECK (titulaire IS NULL OR pg_catalog.char_length(titulaire) BETWEEN 2 AND 140),
  numero_compte text CHECK (numero_compte IS NULL OR numero_compte ~ '^[A-Za-z0-9]{4,34}$'),
  iban text CHECK (iban IS NULL OR iban ~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{10,30}$'),
  swift text CHECK (swift IS NULL OR swift ~ '^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$'),
  adresse_pays text CHECK (adresse_pays IS NULL OR adresse_pays ~ '^[A-Z]{2}$'),
  adresse_ville text CHECK (adresse_ville IS NULL OR pg_catalog.char_length(adresse_ville) BETWEEN 1 AND 80),
  adresse_ligne text CHECK (adresse_ligne IS NULL OR pg_catalog.char_length(adresse_ligne) BETWEEN 1 AND 140),
  code_postal text CHECK (code_postal IS NULL OR code_postal ~ '^[A-Za-z0-9 -]{1,12}$'),
  adresse_etat text CHECK (adresse_etat IS NULL OR adresse_etat ~ '^[A-Z0-9]{1,3}$'),
  compte_a_mon_nom boolean NOT NULL DEFAULT true,
  lien_titulaire text CHECK (lien_titulaire IS NULL
                             OR lien_titulaire IN ('parent', 'conjoint', 'frere_soeur', 'autre')),
  autorise_le timestamptz,
  valide_le timestamptz,
  valide_par uuid REFERENCES public.profiles(id),
  active boolean NOT NULL DEFAULT true,
  cree_le timestamptz NOT NULL DEFAULT now(),
  retire_le timestamptz,
  CHECK (active = (retire_le IS NULL)),
  -- Un compte qui n'est pas au nom de l'enseignant : lien et accord exiges.
  CHECK (compte_a_mon_nom OR (lien_titulaire IS NOT NULL AND autorise_le IS NOT NULL)),
  CHECK ((valide_le IS NULL) = (valide_par IS NULL)),
  -- Aucune virgule, guillemet, point-virgule ni saut de ligne dans un texte
  -- libre : le fichier CSV reste sain sans echappement fragile.
  CONSTRAINT versement_coordonnees_csv_sain CHECK (
    coalesce(titulaire, '') || coalesce(adresse_ville, '') || coalesce(adresse_ligne, '') !~ '[,";\r\n]')
);
CREATE UNIQUE INDEX versement_coordonnees_une_active
  ON public.versement_coordonnees (profile_id) WHERE active;
ALTER TABLE public.versement_coordonnees ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versement_coordonnees FROM PUBLIC, anon, authenticated, service_role;

-- Le journal des changements et des exports, en ajout seul. Aucun role client
-- ni service n'y a de droit direct.
CREATE TABLE public.versement_journal (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  objet text NOT NULL CHECK (objet IN ('coordonnees_enregistrees', 'coordonnees_retirees',
    'coordonnees_validees', 'export_wise', 'modele_wise_pose')),
  profile_id uuid REFERENCES public.profiles(id),
  auteur uuid REFERENCES public.profiles(id),
  mois date,
  lignes integer,
  manquants integer,
  total_minor bigint,
  devise text,
  le timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX versement_journal_profil ON public.versement_journal (profile_id, le DESC);
ALTER TABLE public.versement_journal ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.versement_journal FROM PUBLIC, anon, authenticated, service_role;

CREATE FUNCTION private.versement_journal_immuable()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  RAISE EXCEPTION 'versement_journal est en ajout seul' USING ERRCODE = '42501';
END;
$function$;
REVOKE ALL ON FUNCTION private.versement_journal_immuable() FROM PUBLIC, anon, authenticated, service_role;
CREATE TRIGGER versement_journal_immuable
  BEFORE UPDATE ON public.versement_journal
  FOR EACH ROW EXECUTE FUNCTION private.versement_journal_immuable();

-- ---------------------------------------------------------------------------
-- 3. Aides
-- ---------------------------------------------------------------------------
-- Les 4 derniers caracteres, le reste masque.
CREATE FUNCTION private.versement_masque(p text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT CASE WHEN p IS NULL THEN NULL
              WHEN pg_catalog.char_length(p) <= 4 THEN p
              ELSE '••••' || pg_catalog.right(p, 4) END;
$function$;
REVOKE ALL ON FUNCTION private.versement_masque(text) FROM PUBLIC, anon, authenticated, service_role;

-- La valeur d'un champ d'une ligne de coordonnees.
CREATE FUNCTION private.versement_champ(c public.versement_coordonnees, p_champ text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT CASE p_champ
    WHEN 'titulaire' THEN c.titulaire WHEN 'numero_compte' THEN c.numero_compte
    WHEN 'iban' THEN c.iban WHEN 'swift' THEN c.swift
    WHEN 'adresse_pays' THEN c.adresse_pays WHEN 'adresse_ville' THEN c.adresse_ville
    WHEN 'adresse_ligne' THEN c.adresse_ligne WHEN 'code_postal' THEN c.code_postal
    WHEN 'adresse_etat' THEN c.adresse_etat END;
$function$;
REVOKE ALL ON FUNCTION private.versement_champ(public.versement_coordonnees, text)
  FROM PUBLIC, anon, authenticated, service_role;

-- Les champs requis qui manquent a une ligne (vide si complete).
CREATE FUNCTION private.versement_champs_manquants(c public.versement_coordonnees)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.array_agg(r.champ ORDER BY r.ordre), ARRAY[]::text[])
    FROM public.versement_champs_requis r
   WHERE r.prestataire = c.prestataire AND r.devise_cible = c.devise_cible
     AND r.obligatoire AND (r.si_pays IS NULL OR c.adresse_pays = ANY (r.si_pays))
     AND nullif(pg_catalog.btrim(private.versement_champ(c, r.champ)), '') IS NULL;
$function$;
REVOKE ALL ON FUNCTION private.versement_champs_manquants(public.versement_coordonnees)
  FROM PUBLIC, anon, authenticated, service_role;

-- Enfile le courriel « vos coordonnees de versement ont change » (categorie
-- compte, essentielle). Sans adresse, rien ne part et le geste n'est pas
-- empeche. La cle est celle de la ligne du journal : un seul courriel par
-- changement.
CREATE FUNCTION private.versement_courriel(p_profil uuid, p_objet text, p_journal uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_adresse text := public.courriel_adresse_profil(p_profil);
BEGIN
  IF v_adresse IS NULL THEN
    RETURN;
  END IF;
  PERFORM public.courriel_enfiler(
    'compte',
    CASE p_objet WHEN 'coordonnees_validees' THEN 'coordonnees_versement_validees'
                 ELSE 'coordonnees_versement_changees' END,
    v_adresse, p_profil, pg_catalog.jsonb_build_object('objet', p_objet),
    'versement:' || p_journal::text, 'auto', auth.uid());
END;
$function$;
REVOKE ALL ON FUNCTION private.versement_courriel(uuid, text, uuid) FROM PUBLIC, anon, authenticated, service_role;

-- Vrai pour un enseignant au compte valide.
CREATE FUNCTION private.versement_enseignant()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'teacher'
                  AND public.app_account_valid(), false);
$function$;
REVOKE ALL ON FUNCTION private.versement_enseignant() FROM PUBLIC, anon, authenticated, service_role;

-- Vrai pour la direction ou la comptabilite, compte valide.
CREATE FUNCTION private.versement_direction()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT coalesce(auth.uid() IS NOT NULL AND public.app_role() IN ('admin', 'accountant')
                  AND public.app_account_valid(), false);
$function$;
REVOKE ALL ON FUNCTION private.versement_direction() FROM PUBLIC, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. L'enseignant : lire (masque), enregistrer, retirer
-- ---------------------------------------------------------------------------
CREATE FUNCTION public.mes_coordonnees_versement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  c public.versement_coordonnees%ROWTYPE;
  v_devise text;
BEGIN
  IF NOT private.versement_enseignant() THEN
    RAISE EXCEPTION 'reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO c FROM public.versement_coordonnees x
   WHERE x.profile_id = auth.uid() AND x.active;
  v_devise := coalesce(c.devise_cible, 'USD');
  RETURN pg_catalog.jsonb_build_object(
    'prestataire', 'wise',
    'deviseCible', v_devise,
    'devisesProposees', coalesce((SELECT pg_catalog.jsonb_agg(DISTINCT r.devise_cible)
                                    FROM public.versement_champs_requis r
                                   WHERE r.prestataire = 'wise'), '[]'::jsonb),
    'champs', coalesce((SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                                 'champ', r.champ, 'obligatoire', r.obligatoire,
                                 'siPays', pg_catalog.to_jsonb(r.si_pays)) ORDER BY r.ordre)
                          FROM public.versement_champs_requis r
                         WHERE r.prestataire = 'wise' AND r.devise_cible = v_devise), '[]'::jsonb),
    'paysProfil', (SELECT t.country FROM public.teacher_profiles t WHERE t.profile_id = auth.uid()),
    'enregistre', c.id IS NOT NULL,
    'complet', c.id IS NOT NULL AND pg_catalog.cardinality(private.versement_champs_manquants(c)) = 0,
    'valide', c.valide_le IS NOT NULL,
    'compteAMonNom', coalesce(c.compte_a_mon_nom, true),
    'lienTitulaire', c.lien_titulaire,
    'modifieLe', c.cree_le,
    'coordonnees', CASE WHEN c.id IS NULL THEN NULL ELSE pg_catalog.jsonb_build_object(
      'titulaire', c.titulaire,
      'numeroCompte', private.versement_masque(c.numero_compte),
      'iban', private.versement_masque(c.iban),
      'swift', private.versement_masque(c.swift),
      'adressePays', c.adresse_pays, 'adresseVille', c.adresse_ville,
      'adresseLigne', c.adresse_ligne, 'adresseEtat', c.adresse_etat,
      'codePostal', c.code_postal) END);
END;
$function$;
REVOKE ALL ON FUNCTION public.mes_coordonnees_versement() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.mes_coordonnees_versement() TO authenticated;

-- Enregistre (ou remplace) mes coordonnees : l'ancienne ligne devient inactive.
-- Un champ requis vide est refuse (22023, avec la liste des champs) ; un champ
-- hors de ceux de la devise (ou demande pour un autre pays) est ignore : ni
-- plus ni moins que le modele.
CREATE FUNCTION public.enregistrer_mes_coordonnees_versement(
  p_devise_cible text, p_titulaire text, p_numero_compte text, p_iban text, p_swift text,
  p_adresse_pays text, p_adresse_ville text, p_adresse_ligne text, p_code_postal text,
  p_adresse_etat text, p_compte_a_mon_nom boolean, p_lien_titulaire text, p_autorisation boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_moi uuid := auth.uid();
  v_devise text := pg_catalog.upper(pg_catalog.btrim(coalesce(p_devise_cible, '')));
  v_requis text[];
  c public.versement_coordonnees%ROWTYPE;
  v_manque text[];
  v_journal uuid;
  -- Identifiants sans espaces ni tirets ; SWIFT et IBAN en majuscules.
  v_num text := nullif(pg_catalog.regexp_replace(coalesce(p_numero_compte, ''), '[\s-]', '', 'g'), '');
  v_iban text := nullif(pg_catalog.upper(pg_catalog.regexp_replace(coalesce(p_iban, ''), '\s', '', 'g')), '');
  v_swift text := nullif(pg_catalog.upper(pg_catalog.regexp_replace(coalesce(p_swift, ''), '\s', '', 'g')), '');
BEGIN
  IF NOT private.versement_enseignant() THEN
    RAISE EXCEPTION 'reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  SELECT pg_catalog.array_agg(r.champ) INTO v_requis FROM public.versement_champs_requis r
   WHERE r.prestataire = 'wise' AND r.devise_cible = v_devise;
  IF v_requis IS NULL THEN
    RAISE EXCEPTION 'devise non proposee' USING ERRCODE = '22023';
  END IF;
  c.profile_id := v_moi;
  c.prestataire := 'wise';
  c.devise_cible := v_devise;
  c.titulaire := CASE WHEN 'titulaire' = ANY (v_requis) THEN nullif(pg_catalog.btrim(p_titulaire), '') END;
  c.numero_compte := CASE WHEN 'numero_compte' = ANY (v_requis) THEN v_num END;
  c.iban := CASE WHEN 'iban' = ANY (v_requis) THEN v_iban END;
  c.swift := CASE WHEN 'swift' = ANY (v_requis) THEN v_swift END;
  c.adresse_pays := CASE WHEN 'adresse_pays' = ANY (v_requis)
                         THEN nullif(pg_catalog.upper(pg_catalog.btrim(p_adresse_pays)), '') END;
  c.adresse_ville := CASE WHEN 'adresse_ville' = ANY (v_requis) THEN nullif(pg_catalog.btrim(p_adresse_ville), '') END;
  c.adresse_ligne := CASE WHEN 'adresse_ligne' = ANY (v_requis) THEN nullif(pg_catalog.btrim(p_adresse_ligne), '') END;
  c.code_postal := CASE WHEN 'code_postal' = ANY (v_requis) THEN nullif(pg_catalog.btrim(p_code_postal), '') END;
  c.adresse_etat := CASE WHEN 'adresse_etat' = ANY (v_requis)
                          AND EXISTS (SELECT 1 FROM public.versement_champs_requis r
                                       WHERE r.prestataire = 'wise' AND r.devise_cible = v_devise
                                         AND r.champ = 'adresse_etat'
                                         AND (r.si_pays IS NULL OR c.adresse_pays = ANY (r.si_pays)))
                         THEN nullif(pg_catalog.upper(pg_catalog.btrim(p_adresse_etat)), '') END;
  IF p_compte_a_mon_nom IS NULL THEN
    RAISE EXCEPTION 'compte_a_mon_nom absent' USING ERRCODE = '22023';
  END IF;
  IF NOT p_compte_a_mon_nom THEN
    IF p_lien_titulaire IS NULL OR p_lien_titulaire NOT IN ('parent', 'conjoint', 'frere_soeur', 'autre') THEN
      RAISE EXCEPTION 'lien avec le titulaire absent' USING ERRCODE = '22023';
    END IF;
    IF p_autorisation IS NOT TRUE THEN
      RAISE EXCEPTION 'accord de versement sur le compte d''un tiers absent' USING ERRCODE = '22023';
    END IF;
  END IF;
  IF EXISTS (SELECT 1 FROM public.referentiel_paiement r
              WHERE r.pays = c.adresse_pays AND r.methode = 'virement_bancaire'
                AND r.etat = 'indisponible') THEN
    RAISE EXCEPTION 'pays_indisponible' USING ERRCODE = 'P0001';
  END IF;
  v_manque := private.versement_champs_manquants(c);
  IF pg_catalog.cardinality(v_manque) > 0 THEN
    RAISE EXCEPTION 'champs manquants: %', pg_catalog.array_to_string(v_manque, ',')
      USING ERRCODE = '22023';
  END IF;
  UPDATE public.versement_coordonnees SET active = false, retire_le = now()
   WHERE profile_id = v_moi AND active;
  INSERT INTO public.versement_coordonnees
    (profile_id, prestataire, devise_cible, titulaire, numero_compte, iban, swift,
     adresse_pays, adresse_ville, adresse_ligne, code_postal, adresse_etat,
     compte_a_mon_nom, lien_titulaire, autorise_le)
  VALUES (v_moi, 'wise', v_devise, c.titulaire, c.numero_compte, c.iban, c.swift,
          c.adresse_pays, c.adresse_ville, c.adresse_ligne, c.code_postal, c.adresse_etat,
          p_compte_a_mon_nom,
          CASE WHEN p_compte_a_mon_nom THEN NULL ELSE p_lien_titulaire END,
          CASE WHEN p_compte_a_mon_nom THEN NULL ELSE pg_catalog.now() END);
  INSERT INTO public.versement_journal (objet, profile_id, auteur)
  VALUES ('coordonnees_enregistrees', v_moi, v_moi)
  RETURNING id INTO v_journal;
  PERFORM private.versement_courriel(v_moi, 'coordonnees_enregistrees', v_journal);
  RETURN public.mes_coordonnees_versement();
END;
$function$;
REVOKE ALL ON FUNCTION public.enregistrer_mes_coordonnees_versement(text, text, text, text, text, text, text, text, text, text, boolean, text, boolean)
  FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.enregistrer_mes_coordonnees_versement(text, text, text, text, text, text, text, text, text, text, boolean, text, boolean)
  TO authenticated;

CREATE FUNCTION public.retirer_mes_coordonnees_versement()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_journal uuid;
BEGIN
  IF NOT private.versement_enseignant() THEN
    RAISE EXCEPTION 'reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  UPDATE public.versement_coordonnees SET active = false, retire_le = now()
   WHERE profile_id = auth.uid() AND active;
  IF FOUND THEN
    INSERT INTO public.versement_journal (objet, profile_id, auteur)
    VALUES ('coordonnees_retirees', auth.uid(), auth.uid())
    RETURNING id INTO v_journal;
    PERFORM private.versement_courriel(auth.uid(), 'coordonnees_retirees', v_journal);
  END IF;
  RETURN public.mes_coordonnees_versement();
END;
$function$;
REVOKE ALL ON FUNCTION public.retirer_mes_coordonnees_versement() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.retirer_mes_coordonnees_versement() TO authenticated;

-- Mon journal (enregistrements, retraits), sans les exports.
CREATE FUNCTION public.mon_journal_coordonnees_versement()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.versement_enseignant() THEN
    RAISE EXCEPTION 'reserve a l''enseignant' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('id', j.id, 'objet', j.objet, 'le', j.le)
           ORDER BY j.le DESC)
      FROM (SELECT * FROM public.versement_journal x
             WHERE x.profile_id = auth.uid()
               AND x.objet IN ('coordonnees_enregistrees', 'coordonnees_retirees', 'coordonnees_validees')
             ORDER BY x.le DESC LIMIT 50) j), '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.mon_journal_coordonnees_versement() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.mon_journal_coordonnees_versement() TO authenticated;

-- ---------------------------------------------------------------------------
-- 5. La direction : poser le modele Wise, voir qui est complet, exporter
-- ---------------------------------------------------------------------------
-- Pose une version nouvelle du modele Wise (direction seule), quand Wise change
-- son modele : la version la plus haute fait foi, les anciennes restent.
-- p_colonnes : [{enTete, source, champ?, valeurFixe?}, ...] dans l'ordre.
CREATE FUNCTION public.poser_modele_wise(p_colonnes jsonb)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_n integer;
  v_version integer;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  IF pg_catalog.jsonb_typeof(p_colonnes) IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_array_length(p_colonnes) = 0 THEN
    RAISE EXCEPTION 'modele vide' USING ERRCODE = '22023';
  END IF;
  SELECT coalesce(max(w.version), 0) + 1 INTO v_version FROM public.versement_wise_colonnes w;
  INSERT INTO public.versement_wise_colonnes (version, ordre, en_tete, source, champ, valeur_fixe, pose_par)
  SELECT v_version, e.ord::integer, e.v ->> 'enTete', e.v ->> 'source', e.v ->> 'champ',
         e.v ->> 'valeurFixe', auth.uid()
    FROM pg_catalog.jsonb_array_elements(p_colonnes) WITH ORDINALITY AS e(v, ord);
  GET DIAGNOSTICS v_n = ROW_COUNT;
  INSERT INTO public.versement_journal (objet, auteur, lignes) VALUES ('modele_wise_pose', auth.uid(), v_n);
  RETURN v_n;
END;
$function$;
REVOKE ALL ON FUNCTION public.poser_modele_wise(jsonb) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.poser_modele_wise(jsonb) TO authenticated;

-- Qui a des coordonnees completes (sans aucune valeur).
CREATE FUNCTION public.versement_coordonnees_direction()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.versement_direction() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  RETURN pg_catalog.jsonb_build_object(
    'modelePose', EXISTS (SELECT 1 FROM public.versement_wise_colonnes),
    'versionModele', (SELECT max(w.version) FROM public.versement_wise_colonnes w),
    'enseignants', coalesce((
      SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
               'enseignantId', p.id, 'prenom', p.first_name, 'nom', p.last_name,
               'matricule', p.immutable_id, 'coordonneesId', c.id,
               'enregistre', c.id IS NOT NULL,
               'complet', c.id IS NOT NULL AND pg_catalog.cardinality(private.versement_champs_manquants(c)) = 0,
               'valide', c.valide_le IS NOT NULL,
               'deviseCible', c.devise_cible,
               -- Ce que la direction lit pour valider : le titulaire, le lien,
               -- la date de l'accord, le pays, le numero masque.
               'titulaire', c.titulaire,
               'compteAMonNom', c.compte_a_mon_nom,
               'lienTitulaire', c.lien_titulaire,
               'autoriseLe', c.autorise_le,
               'pays', c.adresse_pays,
               'numeroMasque', private.versement_masque(c.numero_compte),
               'enregistreLe', c.cree_le)
             ORDER BY p.last_name, p.first_name)
        FROM public.profiles p
        LEFT JOIN public.versement_coordonnees c ON c.profile_id = p.id AND c.active
       WHERE p.role = 'teacher' AND p.deleted_at IS NULL), '[]'::jsonb));
END;
$function$;
REVOKE ALL ON FUNCTION public.versement_coordonnees_direction() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versement_coordonnees_direction() TO authenticated;

-- La direction valide les coordonnees actives d'un enseignant, telles qu'elle
-- les a lues (`p_coordonnees` : l'identifiant de la ligne lue ; si
-- l'enseignant a change entre-temps, la validation est refusee). Journalise ;
-- courriel a l'enseignant.
CREATE FUNCTION public.valider_coordonnees_versement(p_enseignant uuid, p_coordonnees uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  c public.versement_coordonnees%ROWTYPE;
  v_journal uuid;
BEGIN
  IF NOT coalesce(auth.uid() IS NOT NULL AND public.app_role() = 'admin'
                  AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'reserve a la direction' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO c FROM public.versement_coordonnees x
   WHERE x.profile_id = p_enseignant AND x.active FOR UPDATE;
  IF NOT FOUND OR c.id IS DISTINCT FROM p_coordonnees THEN
    RAISE EXCEPTION 'coordonnees changees ou retirees' USING ERRCODE = 'P0002';
  END IF;
  IF c.valide_le IS NOT NULL THEN
    RETURN false;
  END IF;
  IF pg_catalog.cardinality(private.versement_champs_manquants(c)) > 0 THEN
    RAISE EXCEPTION 'coordonnees incompletes' USING ERRCODE = '22023';
  END IF;
  UPDATE public.versement_coordonnees SET valide_le = pg_catalog.now(), valide_par = auth.uid()
   WHERE id = c.id;
  INSERT INTO public.versement_journal (objet, profile_id, auteur)
  VALUES ('coordonnees_validees', p_enseignant, auth.uid())
  RETURNING id INTO v_journal;
  PERFORM private.versement_courriel(p_enseignant, 'coordonnees_validees', v_journal);
  RETURN true;
END;
$function$;
REVOKE ALL ON FUNCTION public.valider_coordonnees_versement(uuid, uuid) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.valider_coordonnees_versement(uuid, uuid) TO authenticated;

-- Un montant mineur en texte decimal, point comme separateur, sans millier
-- (Wise : « no special characters or commas in Amount »).
CREATE FUNCTION private.versement_montant_texte(p_mineur bigint, p_devise text)
RETURNS text
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $function$
  SELECT CASE WHEN p_devise IN ('JPY', 'XOF', 'XAF', 'KMF', 'GNF') THEN p_mineur::text
              ELSE pg_catalog.to_char(p_mineur / 100.0, 'FM9999999990.00') END;
$function$;
REVOKE ALL ON FUNCTION private.versement_montant_texte(bigint, text) FROM PUBLIC, anon, authenticated, service_role;

-- L'export du mois de paie p_mois. Rend {exportId, mois, devise, colonnes:
-- [en-tetes], lignes: [[valeurs]], manquants: [...], total}. Journalise.
CREATE FUNCTION public.versement_export_wise(p_mois date)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_releve jsonb;
  v_mois date;
  v_devise text;
  v_source text := coalesce(private.versement_reglage('versement.wise_devise_source'), 'USD');
  v_type_montant text := coalesce(private.versement_reglage('versement.wise_type_montant'), 'target');
  v_version integer;
  v_courriel text;
  v_colonnes jsonb;
  v_lignes jsonb := '[]'::jsonb;
  v_manquants jsonb := '[]'::jsonb;
  v_total bigint := 0;
  v_export uuid;
  e jsonb;
  c public.versement_coordonnees%ROWTYPE;
  v_id uuid;
  v_du bigint;
  v_verse bigint;
  v_reste bigint;
  v_nom text;
  v_matricule text;
  v_ligne jsonb;
BEGIN
  IF NOT private.versement_direction() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  IF p_mois IS NULL THEN
    RAISE EXCEPTION 'mois de paie absent' USING ERRCODE = '22023';
  END IF;
  SELECT max(w.version) INTO v_version FROM public.versement_wise_colonnes w;
  IF v_version IS NULL THEN
    RAISE EXCEPTION 'modele_wise_absent' USING ERRCODE = 'P0001';
  END IF;
  SELECT pg_catalog.jsonb_agg(w.en_tete ORDER BY w.ordre) INTO v_colonnes
    FROM public.versement_wise_colonnes w WHERE w.version = v_version;

  -- Le du : celui du releve, jamais recalcule ici.
  v_releve := public.releve_paie_mensuel(p_mois);
  v_mois := (v_releve ->> 'debut')::date;
  v_devise := v_releve ->> 'devise';
  IF v_devise IS DISTINCT FROM v_source THEN
    RAISE EXCEPTION 'devise du releve (%) differente de la devise source (%)', v_devise, v_source
      USING ERRCODE = '22023';
  END IF;

  FOR e IN SELECT x FROM pg_catalog.jsonb_array_elements(v_releve -> 'enseignants') AS x LOOP
    v_id := (e ->> 'enseignantId')::uuid;
    v_du := (e -> 'montant' ->> 'mineur')::bigint;
    SELECT coalesce(sum(v.montant_minor), 0) INTO v_verse FROM public.versements_paie v
     WHERE v.enseignant_id = v_id AND v.mois = v_mois AND v.annule_le IS NULL AND v.devise = v_devise;
    v_reste := v_du - v_verse;
    CONTINUE WHEN v_reste <= 0;
    SELECT p.immutable_id INTO v_matricule FROM public.profiles p WHERE p.id = v_id;
    SELECT u.email INTO v_courriel FROM auth.users u WHERE u.id = v_id;
    v_nom := pg_catalog.btrim(coalesce(e ->> 'prenom', '') || ' ' || coalesce(e ->> 'nom', ''));
    c := NULL;
    SELECT * INTO c FROM public.versement_coordonnees x WHERE x.profile_id = v_id AND x.active;
    IF c.id IS NULL OR pg_catalog.cardinality(private.versement_champs_manquants(c)) > 0
       OR c.valide_le IS NULL THEN
      v_manquants := v_manquants || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'enseignantId', v_id, 'nom', v_nom, 'matricule', v_matricule,
        'montant', pg_catalog.jsonb_build_object('mineur', v_reste, 'devise', v_devise),
        'raison', CASE WHEN c.id IS NULL THEN 'aucune'
                       WHEN pg_catalog.cardinality(private.versement_champs_manquants(c)) > 0 THEN 'incompletes'
                       ELSE 'a_valider' END));
      CONTINUE;
    END IF;
    SELECT pg_catalog.jsonb_agg(CASE w.source
             WHEN 'montant' THEN private.versement_montant_texte(v_reste, v_devise)
             WHEN 'devise_source' THEN v_source
             WHEN 'devise_cible' THEN c.devise_cible
             WHEN 'type_montant' THEN v_type_montant
             WHEN 'reference' THEN 'Rewayah paie ' || pg_catalog.to_char(v_mois, 'YYYY-MM')
             WHEN 'matricule' THEN coalesce(v_matricule, '')
             WHEN 'courriel' THEN coalesce(v_courriel, '')
             WHEN 'fixe' THEN w.valeur_fixe
             WHEN 'vide' THEN ''
             ELSE coalesce(private.versement_champ(c, w.champ), '') END ORDER BY w.ordre)
      INTO v_ligne FROM public.versement_wise_colonnes w WHERE w.version = v_version;
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(v_ligne);
    v_total := v_total + v_reste;
  END LOOP;

  IF pg_catalog.jsonb_array_length(v_lignes) > 1000 THEN
    RAISE EXCEPTION 'plus de 1 000 lignes : Wise refuse le fichier' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.versement_journal (objet, auteur, mois, lignes, manquants, total_minor, devise)
  VALUES ('export_wise', auth.uid(), v_mois, pg_catalog.jsonb_array_length(v_lignes),
          pg_catalog.jsonb_array_length(v_manquants), v_total, v_devise)
  RETURNING id INTO v_export;

  RETURN pg_catalog.jsonb_build_object(
    'exportId', v_export, 'mois', pg_catalog.to_char(v_mois, 'YYYY-MM-DD'), 'devise', v_devise,
    'colonnes', v_colonnes, 'lignes', v_lignes, 'manquants', v_manquants,
    'total', pg_catalog.jsonb_build_object('mineur', v_total, 'devise', v_devise));
END;
$function$;
REVOKE ALL ON FUNCTION public.versement_export_wise(date) FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versement_export_wise(date) TO authenticated;

-- Les exports passes (qui, quand, quel mois, combien).
CREATE FUNCTION public.versement_exports_direction()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT private.versement_direction() THEN
    RAISE EXCEPTION 'reserve a la direction et a la comptabilite' USING ERRCODE = '42501';
  END IF;
  RETURN coalesce((
    SELECT pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
             'id', j.id, 'le', j.le, 'mois', j.mois, 'lignes', j.lignes, 'manquants', j.manquants,
             'total', pg_catalog.jsonb_build_object('mineur', j.total_minor, 'devise', j.devise),
             'par', pg_catalog.btrim(coalesce(p.first_name, '') || ' ' || coalesce(p.last_name, '')))
           ORDER BY j.le DESC)
      FROM (SELECT * FROM public.versement_journal x WHERE x.objet = 'export_wise'
             ORDER BY x.le DESC LIMIT 50) j
      LEFT JOIN public.profiles p ON p.id = j.auteur), '[]'::jsonb);
END;
$function$;
REVOKE ALL ON FUNCTION public.versement_exports_direction() FROM PUBLIC, anon, service_role;
GRANT EXECUTE ON FUNCTION public.versement_exports_direction() TO authenticated;

COMMIT;
