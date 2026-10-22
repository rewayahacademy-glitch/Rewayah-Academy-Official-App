-- CAND-AUTRES (22/10/2026) : les autres competences des candidats, serveur.
--
-- Decision du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md,
-- section 1 quater (profiter du grand nombre de candidats pour d'autres
-- recrutements : leur demander, discretement, sans les ennuyer, et leur dire
-- pourquoi). Conception : docs/current/CANDIDATURES/PROPOSITION_AUTRES_COMPETENCES.md
-- (parcours facultatif de trois ecrans dans la salle d'attente, apres l'envoi
-- de la Salle d'examen ; filtre cote direction, separation femmes et hommes
-- respectee). Contrat : CONTRAT_PORTS_CANDIDATURES.md, section 3 bis.
-- Specification consolidee : SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- sections 2.1 (moment de la demande), 8.1 (capacites), 8.4 (conservation) et
-- 11 (lots). Besoin : DEPENDANCES_BACKEND.md, CAND-BR-19.
--
-- Ce lot pose :
-- * le CATALOGUE des competences (public.competences_catalogue : code, famille,
--   ordre, libelle, exemple, actif, version), garni de la liste precise du
--   directeur (22/10 : « il faut etre specifique dans ce que tu vas demander
--   comme competence : social media management, relations publiques, design
--   graphique, montage video, administration, specialistes en pedagogie, etc. »),
--   et son journal en ajout seul (public.competences_catalogue_journal). Un code
--   s'ajoute ou se desactive, ne se supprime jamais ; seule la direction l'ecrit
--   (enregistrer_competence_catalogue), journalise ;
-- * une table, une ligne par candidature (public.candidature_autres_competences) :
--   les domaines (codes du catalogue) et, pour chacun, un niveau (debutant,
--   experience, metier), un texte court pour « autre », la disponibilite pour
--   une mission (quelques_heures, mi_temps, plus, pas_maintenant), l'accord
--   d'etre contacte (booleen, date) et la date de mise a jour. RLS active,
--   aucun privilege, aucune policy : toute ecriture passe par les RPC ;
-- * cinq RPC : trois du candidat (lire_autres_competences,
--   enregistrer_autres_competences, idempotent et a version attendue,
--   retirer_autres_competences), la lecture du catalogue pour le candidat et la
--   direction (lire_catalogue_competences) et son ecriture pour la direction
--   seule (enregistrer_competence_catalogue) ;
-- * la lecture par la direction : lire_candidature rend la cle
--   autresCompetences ; lister_candidatures gagne quatre filtres
--   (competenceDomaine : un code OU une famille, competenceNiveauMin,
--   competenceDisponibilite, competenceAccord) ; les deux dans la portee par
--   genre de CAND-L1.
--
-- Choix faits dans ce lot, a relire :
-- * C1 qui, quand : le titulaire d'une candidature de type enseignant, au
--   compte valide (private.candidature_du_titulaire : en attente, provisoire
--   ou actif, non supprime, non expire, L1-08), et seulement APRES l'envoi de
--   la Salle d'examen : un document de reponses du candidat, envoye et qui
--   n'est pas un brouillon (envoye_le non nul), existe. La salle d'examen
--   reste courte (proposition, section 1) ; apres l'envoi la personne attend.
--   Ensuite, a toute etape (salle d'examen, de verification, des prets a
--   enseigner), pause comprise, TANT QUE la candidature est en cours : refusee
--   ou retiree, elle ne peut plus enregistrer (refus rendu candidature_close).
--   Lire et RETIRER restent permis a ces deux issues : la personne peut
--   modifier ou retirer ses reponses « a tout moment » (proposition, section
--   5), et retirer son accord d'etre contactee ne se ferme pas avec la
--   candidature d'enseignant. Un compte desactive ou dont l'acces est expire
--   n'a plus la main sur aucune des trois (42501) ;
-- * C2 refus et erreurs, comme le moteur de CAND-L2A1 : un argument absent ou
--   mal forme leve 22023 ; un appelant qui n'est pas le titulaire, 42501 (en
--   premier : un compte qui n'est pas le titulaire n'apprend rien de la
--   validation des arguments, ce que le moteur, lui, fait dans l'autre sens) ;
--   tout refus metier est RENDU, sans ecriture : cle_idempotence_reutilisee,
--   candidature_close, questionnaire_non_envoye, conflit_autres_competences
--   (versionCourante rendue), reponses_invalides (champs nommes, motif par
--   champ : domaines_requis, domaine_inconnu, domaine_desactive, niveau_invalide, texte_requis,
--   texte_non_attendu, texte_trop_long, texte_invalide,
--   disponibilite_inconnue). Ordre : titulaire, arguments, rejeu de la cle,
--   issue et envoi, version, forme des reponses ;
-- * C3 forme : de un domaine a autant que le catalogue en porte (au plus 100),
--   chacun avec un niveau, jamais un domaine hors du catalogue ; le texte
--   « autre » est exige quand « autre » est choisi et refuse sinon : un a deux
--   cents caracteres, blancs de tete et de queue retires, sans caractere de
--   controle (U+0001 a U+001F, U+007F a U+009F, separateurs de ligne et de
--   paragraphe), donc sur une seule ligne, « quelques mots », la meme regle
--   quelle que soit la langue du serveur ; un texte de plus de 1000 signes est
--   refuse avant toute normalisation ; la disponibilite est exigee ; l'accord
--   est un booleen exige. Rien sur le salaire d'une mission (proposition,
--   section 3). Les motifs du champ domaines : domaines_requis,
--   domaine_inconnu (absent du catalogue), domaine_desactive (au catalogue mais
--   desactive et pas deja dans la reponse enregistree), niveau_invalide ;
-- * C4 version et idempotence : la table porte sa propre version (1 a la
--   creation, un de plus a chaque ecriture qui change quelque chose) ;
--   versionAttendue vaut 0 quand rien n'est enregistre. Les cles
--   d'idempotence vont dans public.candidature_gestes (ajout seul, premier
--   resultat garde, une cle vaut pour une candidature, un geste et un
--   auteur), sous le verrou consultatif de la cle que prennent aussi les
--   gestes du moteur, puis le verrou de la ligne de la candidature (meme ordre
--   que le moteur : aucun croisement possible avec un geste de la direction).
--   Le resultat garde ne porte JAMAIS une reponse : la
--   version et inchange seulement. Une ecriture identique a l'etat courant
--   n'ecrit rien (inchange = true, version, date d'accord et audit
--   intacts) ;
-- * C5 ce n'est pas une transition : ni version de la candidature, ni
--   derniere activite (la liste de la direction ne remonte pas une personne
--   qui complete une reponse facultative), ni evenement du journal des
--   candidatures. Une ecriture effective et un retrait effectif laissent une
--   ligne d'audit_logs (candidature_autres_competences_enregistrees ou
--   _retirees, table candidatures, ligne = la candidature) sans aucune
--   reponse : le nombre de domaines, la version et l'accord. La ligne a donc
--   le cote de la candidature (journal_portee, C15 de CAND-L2A1) et son
--   auteur y est rendu par la reference CAND-, jamais par son nom ;
-- * C6 accord : accord_le est l'instant de l'ecriture qui a pose l'accord
--   (l'accord est confirme avec les reponses affichees, sur le meme ecran) ;
--   nul quand l'accord n'est pas donne (contrainte). Ne pas cocher la case
--   n'efface pas les reponses : la direction les voit, avec accord = false, et
--   ne propose aucune mission a cette personne (regle d'ecran, contrat 3 bis).
--   La recherche d'une personne pour une mission envoie competenceAccord =
--   true ;
-- * C7 lecture par la direction : dans lire_candidature (cle
--   autresCompetences, nulle sans reponse), donc dans la portee de CAND-L1 :
--   hors_portee rendu et trace, exception super-admin journalisee, comme le
--   dossier. Le filtre de lister_candidatures est un EXISTS dans le WHERE,
--   apres la portee ; une cle de filtre a null vaut cle absente ; tout filtre
--   de competence exige qu'une ligne existe ; competenceDomaine est un code du
--   catalogue (actif ou non : une reponse ancienne reste cherchable) OU une
--   famille, qui vaut tous les codes de cette famille, actifs ou non ;
--   competenceNiveauMin sans domaine vaut « au moins un domaine a ce niveau ou
--   plus » ; competenceDisponibilite est une valeur exacte ; l'audit de la
--   liste note seulement qu'un filtre de competence a servi. Les lignes de la liste gardent leurs dix-neuf cles
--   (contrat du scenario de CAND-L1) : aucune reponse dans une liste (spec
--   8.3) ;
-- * C8 jamais lues par un controle ni par le paiement : aucune fonction de
--   controle, de paiement, de transition ni etat_dossier() ne cite la table
--   (le scenario le prouve par le texte des fonctions et par le resultat :
--   controles, paiement et etat identiques avec et sans reponses) ;
-- * C9 conservation : la ligne suit la candidature (ON DELETE CASCADE, comme
--   les reponses). ECART CONNU, le meme que celui de CAND-L1 (CAND-Q21,
--   CAND-BR-14) : cpt_anonymiser et mes_donnees_export ne couvrent pas encore
--   cette table, a etendre avec le lot de conservation ; le scenario l'epingle ;
-- * C10 noms : aucune RPC publique de ce lot ne contient « candidature »
--   (scenarios de CAND-L1, L2A1 et L2A2 : la seule lecture de l'etat reste
--   etat_dossier()) ; les aides privees commencent par competences_
--   (le scenario de CAND-L1 compte neuf aides cand_) ;
-- * C11 le catalogue (decision du directeur du 22/10 : des competences
--   precises, regroupees par famille, que la direction complete sans nouvelle
--   version de l'app). Une ligne par competence : code (minuscules, chiffres
--   et _ ; jamais le nom d'une famille, sauf « autre »), famille (liste
--   fermee de six : communication, administration, finances_droit, pedagogie,
--   technique, autre ; un nom de famille se traduit dans l'app), ordre dans la
--   famille (1 a 999 ; a egalite, le code), libelle (1 a 80 caracteres) et
--   exemple (facultatif, 1 a 200) en francais sur une seule ligne, actif,
--   version. Le libelle et l'exemple sont ceux de la direction : l'app garde
--   ses propres textes (fr, ar) pour les codes qu'elle connait et affiche
--   ceux du catalogue pour les autres. « autre » est la famille « autre » et
--   rien d'autre (contrainte) ; le texte libre ne s'attache qu'a lui. Les
--   textes semes ci-dessous reprennent les mots de la proposition (section 3)
--   et passent par mots-rewayah avant d'etre montres ;
-- * C12 ajout seul ou desactivation, jamais de suppression : aucun DELETE ni
--   TRUNCATE sur le catalogue (declencheur, quelle que soit la voie ; l'erreur
--   dit de desactiver), le code et la famille d'une ligne ne changent pas, un
--   UPDATE qui ne change rien est ignore, la version monte a chaque changement
--   reel. Un code desactive : (a) n'est plus offert au choix (lire_catalogue_
--   competences et la lecture du candidat le rendent avec actif = false, que la
--   direction voit tous, que le candidat voit seulement dans sa reponse) ;
--   (b) ne peut plus etre choisi (reponses_invalides, domaine_desactive) SAUF
--   s'il figure deja dans la reponse enregistree de cette personne : elle peut
--   le garder ou l'oter en enregistrant autre chose, sans perdre une reponse
--   ancienne qu'elle n'a pas touchee (niveau modifiable, jamais ajoute de
--   nouveau) ; (c) reste lu, avec son libelle, dans une reponse ancienne ; (d)
--   reste cherchable par la direction (competenceDomaine : un code ou une
--   famille, desactive compris). Un code peut etre reactive. Le catalogue est
--   plafonne a 100 codes (catalogue_plein, refus rendu) ;
-- * C13 droits du catalogue : lire (lire_catalogue_competences) = la direction
--   active (tout le catalogue, avec les versions et peutModifier) OU le
--   titulaire d'une candidature enseignant (les competences actives et, rendues
--   avec actif = false, celles de sa propre reponse) ; ecrire
--   (enregistrer_competence_catalogue) = la direction active, sans condition de
--   genre (le catalogue ne porte aucune donnee de personne), jamais le
--   candidat, la comptabilite ni un tuteur. Ecriture par versionAttendue
--   (absente = ajout d'un code neuf) et cle d'idempotence, comme le referentiel
--   de paiement (L6) : version perimee ou code deja la, refus rendu
--   conflit_catalogue avec la ligne relue ; code absent, absente ; meme cle
--   rejouee avec la meme demande, la ligne relue (rejoue = true), sans effet ;
--   meme cle pour une autre demande ou un autre auteur, cle_idempotence_
--   reutilisee ; une modification identique ne change rien (inchange = true) ;
-- * C14 journal : chaque changement du catalogue, par toute voie (la RPC, une
--   migration, l'editeur SQL), laisse une ligne en ajout seul dans
--   competences_catalogue_journal (avant, apres, auteur et cle quand c'est un
--   compte) et une entree d'audit_logs (competences_catalogue_ecriture : code,
--   famille, actif avant et apres, version ; jamais un libelle) ; l'etat
--   initial seme ici y est consigne (etat_initial, sans auteur). Aucun compte ne
--   lit la table du journal ; la direction lit l'audit. Ces lignes n'ont pas de
--   cote (elles ne visent aucune candidature) : toute direction active les lit ;
-- * C15 la validation lit le catalogue ACTIF (C12) et un declencheur de la
--   table des reponses refuse, pour toute voie, un domaine absent du catalogue
--   (23503) ; il ne lit pas l'etat actif, pour qu'une reponse ancienne se
--   reenregistre. Aucun controle, paiement ni etat_dossier() ne lit le
--   catalogue (C8).
--
-- Hors de ce lot : l'ecran et le port Dart (la proposition, sections 2 et 3),
-- dont l'ecran du catalogue de la direction ; les textes (mots-rewayah,
-- passage par le directeur) ; la conservation (CAND-Q21) ; la liste de pays
-- ou de langues pour la traduction (« langues a preciser » : le texte « autre »
-- ne le remplace pas, a trancher avec l'ecran) ; une famille nouvelle (liste
-- fermee de six : elle demande un libelle dans l'app, donc une migration) ; le
-- contact lui-meme (la messagerie metier, L5).
BEGIN;

-- ============================================================
-- 1. Listes fermees (aides privees, jamais appelables par un compte)
-- ============================================================

-- La source unique des listes qui ne changent pas sans l'app : les familles du
-- catalogue, les niveaux (le niveau croit avec sa position) et les
-- disponibilites (comparees par egalite), dans l'ordre d'affichage. Les
-- competences elles-memes vivent dans le catalogue (section 2).
CREATE FUNCTION private.competences_codes(p_liste text)
RETURNS text[]
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE p_liste
    WHEN 'familles' THEN ARRAY['communication', 'administration', 'finances_droit', 'pedagogie', 'technique',
                               'autre']::text[]
    WHEN 'niveaux' THEN ARRAY['debutant', 'experience', 'metier']::text[]
    WHEN 'disponibilites' THEN ARRAY['quelques_heures', 'mi_temps', 'plus', 'pas_maintenant']::text[]
  END;
$function$;

-- Le rang d'un niveau (1 debutant, 2 experience, 3 metier) ; nul si inconnu.
CREATE FUNCTION private.competences_rang_niveau(p_niveau text)
RETURNS smallint
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.array_position(private.competences_codes('niveaux'), p_niveau)::smallint;
$function$;

-- La forme des domaines (lue par la contrainte de la table des reponses) : un
-- objet de un a cent domaines, chacun un code bien forme (la presence au
-- catalogue est verifiee par le declencheur de la table, section 3) avec un
-- niveau connu (texte).
CREATE FUNCTION private.competences_domaines_valides(p jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(CASE WHEN pg_catalog.jsonb_typeof(p) = 'object' THEN
    (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_each(p)) BETWEEN 1 AND 100
    AND NOT EXISTS (
      SELECT 1 FROM pg_catalog.jsonb_each(p) e
       WHERE e.key !~ '^[a-z][a-z0-9_]{1,39}$'
          OR pg_catalog.jsonb_typeof(e.value) <> 'string'
          OR (e.value #>> '{}') <> ALL (private.competences_codes('niveaux')))
  ELSE false END, false);
$function$;

-- ============================================================
-- 2. Le catalogue des competences et son journal
-- ============================================================

CREATE TABLE public.competences_catalogue (
  -- Un code ne se supprime jamais et ne change jamais (C12) ; ce n'est pas le
  -- nom d'une famille, sauf « autre » (C11), pour que le filtre d'une liste
  -- (un code OU une famille) reste sans ambiguite.
  code text PRIMARY KEY CHECK (code ~ '^[a-z][a-z0-9_]{1,39}$'),
  famille text NOT NULL CHECK (famille = ANY (private.competences_codes('familles'))),
  -- Le rang dans la famille ; a egalite, le code.
  ordre integer NOT NULL CHECK (ordre BETWEEN 1 AND 999),
  libelle text NOT NULL
    CHECK (pg_catalog.length(libelle) BETWEEN 1 AND 80
           AND libelle = pg_catalog.btrim(libelle)
           AND libelle !~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]'),
  exemple text NULL
    CHECK (exemple IS NULL
           OR (pg_catalog.length(exemple) BETWEEN 1 AND 200
               AND exemple = pg_catalog.btrim(exemple)
               AND exemple !~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]')),
  actif boolean NOT NULL DEFAULT true,
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  -- « autre » est la famille « autre » et rien d'autre (C11).
  CONSTRAINT competences_catalogue_autre CHECK ((code = 'autre') = (famille = 'autre')),
  CONSTRAINT competences_catalogue_code_famille
    CHECK (code = 'autre' OR code <> ALL (private.competences_codes('familles')))
);

-- Le journal des changements du catalogue (C14), en ajout seul. Une ligne de
-- l'etat initial ou d'une migration n'a ni auteur ni cle ; une ecriture par un
-- compte a les deux et l'empreinte de sa demande.
CREATE TABLE public.competences_catalogue_journal (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  code text NOT NULL REFERENCES public.competences_catalogue(code) ON DELETE RESTRICT,
  geste text NOT NULL CHECK (geste IN ('etat_initial', 'ajout', 'modification')),
  avant jsonb NULL CHECK (avant IS NULL OR pg_catalog.jsonb_typeof(avant) = 'object'),
  apres jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(apres) = 'object'),
  auteur_id uuid NULL REFERENCES public.profiles(id),
  cle_idempotence text NULL UNIQUE CHECK (pg_catalog.length(cle_idempotence) BETWEEN 8 AND 200),
  empreinte text NULL CHECK (empreinte ~ '^[0-9a-f]{32}$'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  CONSTRAINT competences_catalogue_journal_auteur_cle CHECK (
    (auteur_id IS NULL AND cle_idempotence IS NULL AND empreinte IS NULL)
    OR (auteur_id IS NOT NULL AND cle_idempotence IS NOT NULL AND empreinte IS NOT NULL)),
  CONSTRAINT competences_catalogue_journal_avant CHECK ((geste = 'modification') = (avant IS NOT NULL))
);
CREATE INDEX competences_catalogue_journal_code_idx
  ON public.competences_catalogue_journal (code, cree_le DESC);

ALTER TABLE public.competences_catalogue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.competences_catalogue_journal ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.competences_catalogue, public.competences_catalogue_journal
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
REVOKE ALL ON SEQUENCE public.competences_catalogue_journal_id_seq
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.competences_catalogue IS
  'CAND-AUTRES : catalogue des competences que l academie demande aux candidats (code, famille, ordre, '
  'libelle, exemple, actif) ; la direction l ajoute ou le desactive (enregistrer_competence_catalogue), '
  'jamais de suppression ; lu par le candidat et la direction (lire_catalogue_competences). Aucune policy.';
COMMENT ON COLUMN public.competences_catalogue.code IS
  'Stable pour toujours : une reponse ancienne le cite. Jamais le nom d une famille, sauf autre.';
COMMENT ON COLUMN public.competences_catalogue.actif IS
  'Faux : n est plus offert au choix et ne peut plus etre choisi, mais reste lu dans une reponse ancienne et cherchable.';
COMMENT ON TABLE public.competences_catalogue_journal IS
  'CAND-AUTRES : journal en ajout seul des changements du catalogue des competences (etat initial, '
  'ajouts, modifications), avec auteur, cle d idempotence et empreinte quand c est un compte ; aucune policy.';

-- Ajout seul : pour le journal, et (C12) pour le catalogue, qui ne se supprime
-- ni ne se vide.
CREATE FUNCTION private.competences_refuser_mutation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_TABLE_NAME = 'competences_catalogue' THEN
    RAISE EXCEPTION 'CAND-AUTRES : le catalogue des competences ne se supprime pas, une competence se desactive'
      USING ERRCODE = '55000';
  END IF;
  RAISE EXCEPTION 'CAND-AUTRES : % en ajout seul', TG_TABLE_NAME USING ERRCODE = '55000';
END;
$function$;
CREATE TRIGGER competences_catalogue_journal_ajout_seul
  BEFORE UPDATE OR DELETE ON public.competences_catalogue_journal
  FOR EACH ROW EXECUTE FUNCTION private.competences_refuser_mutation();
CREATE TRIGGER competences_catalogue_journal_sans_vidage
  BEFORE TRUNCATE ON public.competences_catalogue_journal
  FOR EACH STATEMENT EXECUTE FUNCTION private.competences_refuser_mutation();
CREATE TRIGGER competences_catalogue_sans_suppression
  BEFORE DELETE ON public.competences_catalogue
  FOR EACH ROW EXECUTE FUNCTION private.competences_refuser_mutation();
CREATE TRIGGER competences_catalogue_sans_vidage
  BEFORE TRUNCATE ON public.competences_catalogue
  FOR EACH STATEMENT EXECUTE FUNCTION private.competences_refuser_mutation();

-- Garde de ligne (C12), quelle que soit la voie : le code et la famille ne
-- changent pas ; un UPDATE qui ne change rien (libelle, exemple, ordre, actif)
-- est ignore ; sinon la version monte et la date de mise a jour est celle de
-- l'ecriture, quoi qu'on ait ecrit dans ces deux colonnes.
CREATE FUNCTION private.competences_catalogue_garde()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.version := 1;
    NEW.cree_le := pg_catalog.clock_timestamp();
    NEW.maj_le := NEW.cree_le;
    RETURN NEW;
  END IF;
  IF NEW.code IS DISTINCT FROM OLD.code OR NEW.famille IS DISTINCT FROM OLD.famille
     OR NEW.cree_le IS DISTINCT FROM OLD.cree_le THEN
    RAISE EXCEPTION 'CAND-AUTRES : le code et la famille d''une competence ne changent pas'
      USING ERRCODE = '55000';
  END IF;
  IF NEW.libelle IS NOT DISTINCT FROM OLD.libelle AND NEW.exemple IS NOT DISTINCT FROM OLD.exemple
     AND NEW.ordre IS NOT DISTINCT FROM OLD.ordre AND NEW.actif IS NOT DISTINCT FROM OLD.actif THEN
    RETURN NULL;
  END IF;
  NEW.version := OLD.version + 1;
  NEW.maj_le := pg_catalog.clock_timestamp();
  RETURN NEW;
END;
$function$;
CREATE TRIGGER competences_catalogue_garde
  BEFORE INSERT OR UPDATE ON public.competences_catalogue
  FOR EACH ROW EXECUTE FUNCTION private.competences_catalogue_garde();

-- Le journal (C14), pour toute voie d'ecriture : la RPC pose l'auteur, la cle
-- et l'empreinte dans un reglage local a la transaction, que ce declencheur
-- consomme (et remet a vide) ; une migration ou l'editeur SQL n'en pose pas
-- (auteur et cle nuls). La RPC n'ecrit jamais sans changement reel, donc le
-- declencheur de ligne tire toujours.
CREATE FUNCTION private.competences_catalogue_journaliser()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_ecriture jsonb := nullif(pg_catalog.current_setting('cand_autres.catalogue', true), '')::jsonb;
  v_auteur uuid := (v_ecriture ->> 'auteur')::uuid;
  v_avant jsonb := CASE WHEN TG_OP = 'UPDATE' THEN pg_catalog.to_jsonb(OLD) END;
BEGIN
  INSERT INTO public.competences_catalogue_journal
    (code, geste, avant, apres, auteur_id, cle_idempotence, empreinte)
  VALUES (NEW.code, CASE WHEN TG_OP = 'UPDATE' THEN 'modification' ELSE 'ajout' END, v_avant,
          pg_catalog.to_jsonb(NEW), v_auteur, v_ecriture ->> 'cle', v_ecriture ->> 'empreinte');
  IF v_ecriture IS NOT NULL THEN
    PERFORM pg_catalog.set_config('cand_autres.catalogue', '', true);
  END IF;
  -- audit_logs est lisible par toute direction active : ni libelle ni exemple,
  -- seulement de quoi retrouver le changement dans le journal.
  PERFORM public.log_sensitive_access('competences_catalogue_ecriture', 'competences_catalogue',
    NEW.code, pg_catalog.jsonb_build_object(
      'geste', CASE WHEN TG_OP = 'UPDATE' THEN 'modification' ELSE 'ajout' END,
      'famille', NEW.famille,
      'actifAvant', (v_avant ->> 'actif')::boolean,
      'actifApres', NEW.actif,
      'version', NEW.version,
      'voie', CASE WHEN v_auteur IS NULL THEN 'directe' ELSE 'rpc' END));
  RETURN NULL;
END;
$function$;

-- L'etat initial : la liste precise du directeur du 22/10, par famille. Les
-- libelles et les exemples reprennent les mots de la proposition (section 3) ;
-- ils passent par mots-rewayah avant d'etre montres, et l'app garde les siens
-- pour ces codes (C11). Semes AVANT le declencheur de journal : l'etat initial
-- se consigne en une fois (etat_initial), sans entree d'audit.
INSERT INTO public.competences_catalogue (code, famille, ordre, libelle, exemple) VALUES
  ('reseaux_sociaux', 'communication', 1, 'Gestion des réseaux sociaux',
   'Publier, animer les comptes de l''académie, répondre aux messages'),
  ('relations_publiques', 'communication', 2, 'Relations publiques et partenariats',
   'Mosquées, associations, médias'),
  ('design_graphique', 'communication', 3, 'Design graphique', 'Visuels, affiches, cartes'),
  ('montage_video', 'communication', 4, 'Montage vidéo et animation',
   'Courtes vidéos, sous-titres, animations'),
  ('photographie', 'communication', 5, 'Photographie et prise de vue', 'Photos, vidéos, prise de son'),
  ('redaction_contenus', 'communication', 6, 'Rédaction et création de contenus',
   'Articles, textes pour les réseaux, lettres d''information'),
  ('publicite_en_ligne', 'communication', 7, 'Publicité en ligne',
   'Campagnes, ciblage, suivi des résultats'),
  ('traduction', 'communication', 8, 'Traduction', 'Textes, sous-titres, messages aux familles'),
  ('assistanat', 'administration', 1, 'Assistanat administratif ou de direction',
   'Agenda, courriers, organisation du quotidien'),
  ('coordination_groupe', 'administration', 2, 'Coordination d''un groupe',
   'Par exemple le groupe des sœurs, ou celui des parents'),
  ('accueil_familles', 'administration', 3, 'Accueil et suivi des familles',
   'Répondre aux questions, accompagner une inscription'),
  ('gestion_projet', 'administration', 4, 'Planification et gestion de projet',
   'Calendrier, suivi des tâches, coordination d''une équipe'),
  ('ressources_humaines', 'administration', 5, 'Ressources humaines et recrutement',
   'Entretiens, sélection, accueil des nouveaux enseignants'),
  ('comptabilite', 'finances_droit', 1, 'Comptabilité', 'Tenue des comptes, factures, bilans'),
  ('gestion_financiere', 'finances_droit', 2, 'Gestion financière',
   'Budget, trésorerie, suivi des paiements'),
  ('juridique_donnees', 'finances_droit', 3, 'Juridique et protection des données',
   'Contrats, conditions d''utilisation, vie privée'),
  ('conception_programmes', 'pedagogie', 1, 'Conception de programmes et de supports',
   'Plans de cours, fiches, exercices'),
  ('formation_enseignants', 'pedagogie', 2, 'Formation et accompagnement des enseignants',
   'Former les nouveaux enseignants, les conseiller'),
  ('qualite_cours', 'pedagogie', 3, 'Observation et qualité des cours',
   'Observer une séance, donner un retour'),
  ('tests_niveau', 'pedagogie', 4, 'Tests de niveau',
   'Évaluer un nouvel élève avant son entrée en classe'),
  ('accompagnement_enfants', 'pedagogie', 5, 'Accompagnement des enfants',
   'Psychologie, besoins particuliers'),
  ('developpement', 'technique', 1, 'Développement web ou mobile', 'Sites, applications, outils internes'),
  ('assistance_technique', 'technique', 2, 'Assistance technique aux familles et aux enseignants',
   'Aider à se connecter, régler le son et la caméra'),
  ('donnees_tableurs', 'technique', 3, 'Données et tableurs', 'Tableaux de suivi, statistiques, rapports'),
  ('autre', 'autre', 1, 'Autre compétence', 'Quelques mots pour la décrire');

INSERT INTO public.competences_catalogue_journal (code, geste, apres)
SELECT k.code, 'etat_initial', pg_catalog.to_jsonb(k)
  FROM public.competences_catalogue k
 ORDER BY pg_catalog.array_position(private.competences_codes('familles'), k.famille), k.ordre, k.code;

CREATE TRIGGER competences_catalogue_journal
  AFTER INSERT OR UPDATE ON public.competences_catalogue
  FOR EACH ROW EXECUTE FUNCTION private.competences_catalogue_journaliser();

-- ============================================================
-- 3. Table des reponses
-- ============================================================

CREATE TABLE public.candidature_autres_competences (
  candidature_id uuid PRIMARY KEY REFERENCES public.candidatures(id) ON DELETE CASCADE,
  -- {"comptabilite": "metier", "autre": "experience"} : code du catalogue -> niveau.
  domaines jsonb NOT NULL CHECK (private.competences_domaines_valides(domaines)),
  autre_texte text NULL
    CHECK (autre_texte IS NULL
           OR (pg_catalog.length(autre_texte) BETWEEN 1 AND 200
               AND autre_texte = pg_catalog.btrim(autre_texte)
               AND autre_texte !~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]')),
  disponibilite text NOT NULL CHECK (disponibilite = ANY (private.competences_codes('disponibilites'))),
  accord_contact boolean NOT NULL,
  accord_le timestamptz NULL,
  version integer NOT NULL DEFAULT 1 CHECK (version >= 1),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  maj_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp(),
  -- Le texte n'existe que pour le domaine « autre », et le domaine « autre »
  -- l'exige (C3).
  CONSTRAINT candidature_autres_competences_texte_autre
    CHECK ((domaines ? 'autre') = (autre_texte IS NOT NULL)),
  -- La date d'accord n'existe que si l'accord est donne (C6).
  CONSTRAINT candidature_autres_competences_accord
    CHECK (accord_contact = (accord_le IS NOT NULL))
);

ALTER TABLE public.candidature_autres_competences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.candidature_autres_competences
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

COMMENT ON TABLE public.candidature_autres_competences IS
  'CAND-AUTRES : domaines (codes du catalogue des competences), niveaux, disponibilite et accord d etre '
  'contacte d un candidat pour une mission autre que l enseignement ; une ligne par candidature ; '
  'facultatif ; aucune policy : lecture et ecriture par les RPC seulement (le candidat : '
  'lire_autres_competences, enregistrer_autres_competences, retirer_autres_competences ; la direction : '
  'lire_candidature et lister_candidatures, dans la portee par genre). Jamais lue par un controle, le '
  'paiement ni etat_dossier(). Suit la conservation de la candidature (CAND-Q21).';
COMMENT ON COLUMN public.candidature_autres_competences.domaines IS
  'Code du catalogue -> niveau (debutant, experience, metier) ; un code desactive depuis reste ici, lisible.';
COMMENT ON COLUMN public.candidature_autres_competences.accord_le IS
  'Instant de l ecriture qui a pose l accord d etre contacte ; nul si l accord n est pas donne.';

-- Un domaine absent du catalogue est refuse par toute voie (C15) : le catalogue
-- ne perd jamais un code (C12), donc une reponse reste valide. Il ne lit pas
-- l'etat actif : une reponse ancienne se reenregistre.
CREATE FUNCTION private.competences_garde_domaines()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF pg_catalog.jsonb_typeof(NEW.domaines) = 'object'
     AND EXISTS (SELECT 1 FROM pg_catalog.jsonb_object_keys(NEW.domaines) AS d(code)
                  WHERE NOT EXISTS (SELECT 1 FROM public.competences_catalogue k WHERE k.code = d.code)) THEN
    RAISE EXCEPTION 'CAND-AUTRES : domaine absent du catalogue des competences' USING ERRCODE = '23503';
  END IF;
  RETURN NEW;
END;
$function$;
CREATE TRIGGER candidature_autres_competences_domaines_connus
  BEFORE INSERT OR UPDATE OF domaines ON public.candidature_autres_competences
  FOR EACH ROW EXECUTE FUNCTION private.competences_garde_domaines();

-- ============================================================
-- 4. Aides internes
-- ============================================================

-- La candidature du titulaire qui peut s'en servir : celle de son compte
-- (L1-08), de type enseignant. Nulle sinon.
CREATE FUNCTION private.competences_titulaire()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT c.id
    FROM public.candidatures c
   WHERE c.id = private.candidature_du_titulaire(false)
     AND c.type_code = 'enseignant';
$function$;

-- Pourquoi on ne peut pas enregistrer (C1) : nulle si c'est ouvert ;
-- candidature_close (refusee ou retiree) ; questionnaire_non_envoye (aucun
-- document de reponses envoye de la Salle d'examen).
CREATE FUNCTION private.competences_ouverture(c public.candidatures)
RETURNS text
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE WHEN c.issue = 'en_cours' THEN
    CASE WHEN EXISTS (SELECT 1 FROM public.candidature_reponses r
                       WHERE r.candidature_id = c.id AND r.source = 'candidat'
                         AND NOT r.brouillon AND r.envoye_le IS NOT NULL)
         THEN NULL ELSE 'questionnaire_non_envoye' END
  ELSE 'candidature_close' END;
$function$;

-- La forme rendue, au candidat comme a la direction : jamais la version (propre
-- au candidat, ajoutee par sa RPC). Les instants en UTC, suffixe Z.
CREATE FUNCTION private.competences_json(a public.candidature_autres_competences)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'domaines', a.domaines,
    'autreTexte', a.autre_texte,
    'disponibilite', a.disponibilite,
    'accord', a.accord_contact,
    'accordLe', private.cand_instant(a.accord_le),
    'majLe', private.cand_instant(a.maj_le));
$function$;

-- La forme des reponses (C3). Rend {champs, motifs, texte} : les champs fautifs
-- dans l'ordre domaines, autreTexte, disponibilite, le motif de chacun, et le
-- texte normalise (blancs de tete et de queue retires ; nul s'il est vide).
-- p_enregistres : les domaines deja enregistres pour cette personne ('{}' sans
-- reponse) ; un code desactive du catalogue n'est accepte que s'il y figure
-- deja (C12).
-- Un texte de plus de 1000 signes est refuse AVANT toute normalisation : il
-- vient d'un compte sans privilege, et le serveur ne travaille pas sur des
-- megaoctets pour un champ de « quelques mots ». Le motif de refus est celui
-- d'un texte trop long, que les blancs de tete et de queue y changent
-- quelque chose ou non.
CREATE FUNCTION private.competences_examiner(p_domaines jsonb, p_texte text, p_disponibilite text,
                                             p_enregistres jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_champs jsonb := '[]'::jsonb;
  v_motifs jsonb := '{}'::jsonb;
  v_trop_long boolean := coalesce(pg_catalog.length(p_texte), 0) > 1000;
  v_texte text := CASE WHEN v_trop_long THEN NULL ELSE private.candidature_motif(p_texte) END;
  v_autre boolean := false;
  v_motif text;
BEGIN
  IF pg_catalog.jsonb_typeof(p_domaines) = 'object' THEN
    v_autre := p_domaines ? 'autre';
    v_motif := CASE
      WHEN NOT EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_domaines)) THEN 'domaines_requis'
      WHEN EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_domaines) e
                    WHERE NOT EXISTS (SELECT 1 FROM public.competences_catalogue k
                                       WHERE k.code = e.key)) THEN 'domaine_inconnu'
      WHEN EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_domaines) e
                    JOIN public.competences_catalogue k ON k.code = e.key
                   WHERE NOT k.actif
                     AND NOT coalesce(pg_catalog.jsonb_typeof(p_enregistres) = 'object' AND p_enregistres ? e.key,
                                      false)) THEN 'domaine_desactive'
      WHEN EXISTS (SELECT 1 FROM pg_catalog.jsonb_each(p_domaines) e
                    WHERE pg_catalog.jsonb_typeof(e.value) <> 'string'
                       OR (e.value #>> '{}') <> ALL (private.competences_codes('niveaux'))) THEN 'niveau_invalide'
    END;
  ELSE
    v_motif := 'domaines_requis';
  END IF;
  IF v_motif IS NOT NULL THEN
    v_champs := v_champs || pg_catalog.jsonb_build_array('domaines');
    v_motifs := v_motifs || pg_catalog.jsonb_build_object('domaines', v_motif);
  END IF;

  v_motif := NULL;
  IF v_trop_long THEN
    v_motif := 'texte_trop_long';
  ELSIF v_autre THEN
    IF v_texte IS NULL THEN
      v_motif := 'texte_requis';
    END IF;
  ELSIF v_texte IS NOT NULL THEN
    v_motif := 'texte_non_attendu';
  END IF;
  IF v_motif IS NULL AND v_texte IS NOT NULL THEN
    IF pg_catalog.length(v_texte) > 200 THEN
      v_motif := 'texte_trop_long';
    ELSIF v_texte ~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]' THEN
      v_motif := 'texte_invalide';
    END IF;
  END IF;
  IF v_motif IS NOT NULL THEN
    v_champs := v_champs || pg_catalog.jsonb_build_array('autreTexte');
    v_motifs := v_motifs || pg_catalog.jsonb_build_object('autreTexte', v_motif);
  END IF;

  IF p_disponibilite IS NULL OR p_disponibilite <> ALL (private.competences_codes('disponibilites')) THEN
    v_champs := v_champs || pg_catalog.jsonb_build_array('disponibilite');
    v_motifs := v_motifs || pg_catalog.jsonb_build_object('disponibilite', 'disponibilite_inconnue');
  END IF;
  RETURN pg_catalog.jsonb_build_object('champs', v_champs, 'motifs', v_motifs, 'texte', v_texte);
END;
$function$;

-- Une entree du catalogue telle que l'ecran la lit : code, famille, ordre,
-- libelle, exemple, actif ; et la version, pour la direction qui ecrit par
-- version attendue.
CREATE FUNCTION private.competences_entree(k public.competences_catalogue, p_avec_version boolean)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
           'code', k.code, 'famille', k.famille, 'ordre', k.ordre, 'libelle', k.libelle,
           'exemple', k.exemple, 'actif', k.actif)
         || CASE WHEN p_avec_version THEN pg_catalog.jsonb_build_object('version', k.version)
                 ELSE '{}'::jsonb END;
$function$;

-- Les entrees du catalogue rendues a un ecran, dans l'ordre d'affichage
-- (famille, ordre, code). p_tout : toutes, avec leur version (la direction) ;
-- sinon les actives et, rendues avec actif = false, celles de p_enregistres, la
-- reponse de la personne (C12 : lisible).
CREATE FUNCTION private.competences_catalogue_json(p_tout boolean, p_enregistres jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(private.competences_entree(k, p_tout)
           ORDER BY pg_catalog.array_position(private.competences_codes('familles'), k.famille),
                    k.ordre, k.code), '[]'::jsonb)
    FROM public.competences_catalogue k
   WHERE p_tout OR k.actif
      OR coalesce(pg_catalog.jsonb_typeof(p_enregistres) = 'object' AND p_enregistres ? k.code, false);
$function$;

-- Ce que l'ecran lit avec ses reponses : les familles, les competences du
-- catalogue (voir ci-dessus), les niveaux, les disponibilites, la borne du
-- texte.
CREATE FUNCTION private.competences_referentiel(p_tout boolean, p_enregistres jsonb)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'familles', pg_catalog.to_jsonb(private.competences_codes('familles')),
    'competences', private.competences_catalogue_json(p_tout, p_enregistres),
    'niveaux', pg_catalog.to_jsonb(private.competences_codes('niveaux')),
    'disponibilites', pg_catalog.to_jsonb(private.competences_codes('disponibilites')),
    'autreTexteMax', 200);
$function$;

REVOKE ALL ON FUNCTION private.competences_codes(text), private.competences_catalogue_json(boolean, jsonb),
  private.competences_entree(public.competences_catalogue, boolean),
  private.competences_referentiel(boolean, jsonb),
  private.competences_rang_niveau(text), private.competences_domaines_valides(jsonb),
  private.competences_titulaire(), private.competences_ouverture(public.candidatures),
  private.competences_json(public.candidature_autres_competences),
  private.competences_examiner(jsonb, text, text, jsonb),
  private.competences_refuser_mutation(), private.competences_catalogue_garde(),
  private.competences_catalogue_journaliser(), private.competences_garde_domaines()
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

-- ============================================================
-- 5. RPC du candidat
-- ============================================================

-- Ce que l'ecran de la salle d'attente lit : si c'est ouvert (et sinon
-- pourquoi), la version, ses reponses, les listes (le catalogue actif et les
-- codes desactives de sa propre reponse, avec actif = false ; les familles,
-- les niveaux, les disponibilites). Lecture seule, du seul titulaire (42501
-- sinon). Ouverte aussi quand la candidature est close :
-- la personne voit ce qu'elle a donne et peut le retirer.
CREATE FUNCTION public.lire_autres_competences()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.competences_titulaire();
  v_c public.candidatures;
  v_a public.candidature_autres_competences;
  v_raison text;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'autres competences reservees au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id;
  SELECT a.* INTO v_a FROM public.candidature_autres_competences a WHERE a.candidature_id = v_id;
  v_raison := private.competences_ouverture(v_c);
  RETURN pg_catalog.jsonb_build_object(
    'ouvert', v_raison IS NULL,
    'raison', v_raison,
    'version', coalesce(v_a.version, 0),
    'reponses', CASE WHEN v_a.candidature_id IS NULL THEN NULL
                     ELSE private.competences_json(v_a) END,
    'referentiel', private.competences_referentiel(false, v_a.domaines));
END;
$function$;

-- Enregistre les reponses (C1 a C6). Rend {version, inchange, rejoue} ; la
-- RPC ne rend jamais une reponse : l'ecran relit par lire_autres_competences().
CREATE FUNCTION public.enregistrer_autres_competences(
  p_domaines jsonb,
  p_autre_texte text,
  p_disponibilite text,
  p_accord boolean,
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
  v_id uuid := private.competences_titulaire();
  v_c public.candidatures;
  v_a public.candidature_autres_competences;
  v_idem jsonb;
  v_raison text;
  v_ex jsonb;
  v_texte text;
  v_inchange boolean;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'autres competences reservees au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;
  IF p_domaines IS NULL OR pg_catalog.jsonb_typeof(p_domaines) <> 'object'
     OR p_disponibilite IS NULL OR p_accord IS NULL OR p_version_attendue IS NULL
     OR p_version_attendue < 0 OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'domaines (objet), disponibilite, accord, version attendue (0 ou plus) et cle attendus'
      USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'cle d''idempotence invalide : 8 a 200 signes' USING ERRCODE = '22023';
  END IF;

  -- La cle, puis la ligne : deux appels concurrents se suivent.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('candidature_geste:' || p_cle_idempotence, 0));
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE EXCEPTION 'autres competences reservees au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;

  v_idem := private.candidature_idempotence_lue(p_cle_idempotence, v_c.id,
                                                'enregistrer_autres_competences', v_uid);
  IF v_idem ? 'rejoue' THEN
    RETURN v_idem -> 'rejoue';
  ELSIF v_idem ? 'erreur' THEN
    RETURN v_idem;
  END IF;

  v_raison := private.competences_ouverture(v_c);
  IF v_raison IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', v_raison, 'issue', v_c.issue);
  END IF;
  SELECT a.* INTO v_a FROM public.candidature_autres_competences a WHERE a.candidature_id = v_c.id;
  IF p_version_attendue <> coalesce(v_a.version, 0) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_autres_competences',
                                         'versionCourante', coalesce(v_a.version, 0));
  END IF;
  v_ex := private.competences_examiner(p_domaines, p_autre_texte, p_disponibilite, v_a.domaines);
  IF pg_catalog.jsonb_array_length(v_ex -> 'champs') > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'reponses_invalides',
                                         'champs', v_ex -> 'champs', 'motifs', v_ex -> 'motifs');
  END IF;
  v_texte := v_ex ->> 'texte';

  IF v_a.candidature_id IS NULL THEN
    INSERT INTO public.candidature_autres_competences
      (candidature_id, domaines, autre_texte, disponibilite, accord_contact, accord_le)
    VALUES (v_c.id, p_domaines, v_texte, p_disponibilite, p_accord,
            CASE WHEN p_accord THEN pg_catalog.clock_timestamp() END)
    RETURNING * INTO v_a;
    v_inchange := false;
  ELSIF v_a.domaines = p_domaines
        AND v_a.autre_texte IS NOT DISTINCT FROM v_texte
        AND v_a.disponibilite = p_disponibilite
        AND v_a.accord_contact = p_accord THEN
    v_inchange := true;
  ELSE
    UPDATE public.candidature_autres_competences a
       SET domaines = p_domaines,
           autre_texte = v_texte,
           disponibilite = p_disponibilite,
           accord_contact = p_accord,
           accord_le = CASE WHEN p_accord THEN pg_catalog.clock_timestamp() END,
           version = a.version + 1,
           maj_le = pg_catalog.clock_timestamp()
     WHERE a.candidature_id = v_c.id
    RETURNING * INTO v_a;
    v_inchange := false;
  END IF;

  IF NOT v_inchange THEN
    PERFORM public.log_sensitive_access('candidature_autres_competences_enregistrees', 'candidatures',
      v_c.id::text, pg_catalog.jsonb_build_object(
        'version', v_a.version,
        'domaines', (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_object_keys(v_a.domaines)),
        'accord', v_a.accord_contact));
  END IF;
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_c.id, 'enregistrer_autres_competences',
    v_uid, pg_catalog.jsonb_build_object('version', v_a.version, 'inchange', v_inchange));
END;
$function$;

-- Retire les reponses et l'accord (C1 : permis a toute issue). Rend
-- {retire, version, rejoue} ; retire = false quand rien n'etait enregistre.
CREATE FUNCTION public.retirer_autres_competences(p_version_attendue integer, p_cle_idempotence text)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_id uuid := private.competences_titulaire();
  v_c public.candidatures;
  v_a public.candidature_autres_competences;
  v_idem jsonb;
  v_retire boolean;
BEGIN
  IF NOT coalesce(v_uid IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'autres competences reservees au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;
  IF p_version_attendue IS NULL OR p_version_attendue < 0 OR p_cle_idempotence IS NULL THEN
    RAISE EXCEPTION 'version attendue (0 ou plus) et cle attendues' USING ERRCODE = '22023';
  END IF;
  IF pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'cle d''idempotence invalide : 8 a 200 signes' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('candidature_geste:' || p_cle_idempotence, 0));
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_id FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE EXCEPTION 'autres competences reservees au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;

  v_idem := private.candidature_idempotence_lue(p_cle_idempotence, v_c.id,
                                                'retirer_autres_competences', v_uid);
  IF v_idem ? 'rejoue' THEN
    RETURN v_idem -> 'rejoue';
  ELSIF v_idem ? 'erreur' THEN
    RETURN v_idem;
  END IF;

  SELECT a.* INTO v_a FROM public.candidature_autres_competences a WHERE a.candidature_id = v_c.id;
  IF p_version_attendue <> coalesce(v_a.version, 0) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_autres_competences',
                                         'versionCourante', coalesce(v_a.version, 0));
  END IF;
  v_retire := v_a.candidature_id IS NOT NULL;
  IF v_retire THEN
    DELETE FROM public.candidature_autres_competences a WHERE a.candidature_id = v_c.id;
    PERFORM public.log_sensitive_access('candidature_autres_competences_retirees', 'candidatures',
      v_c.id::text, pg_catalog.jsonb_build_object('version', v_a.version, 'accord', v_a.accord_contact));
  END IF;
  RETURN private.candidature_geste_conclure(p_cle_idempotence, v_c.id, 'retirer_autres_competences',
    v_uid, pg_catalog.jsonb_build_object('retire', v_retire, 'version', 0));
END;
$function$;

-- ============================================================
-- 6. Le catalogue : lecture (candidat et direction) et ecriture (direction)
-- ============================================================

-- Le catalogue tel que l'ecran le lit (C13). La direction active : tout, avec
-- les versions et peutModifier = vrai. Le titulaire d'une candidature
-- enseignant : les competences actives et, avec actif = false, celles de sa
-- propre reponse ; peutModifier = faux. Aucun autre compte (42501). Le
-- catalogue ne porte aucune donnee de personne : pas de condition de genre.
CREATE FUNCTION public.lire_catalogue_competences()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_direction boolean := coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false);
  v_id uuid;
  v_enregistres jsonb;
BEGIN
  IF v_direction THEN
    RETURN pg_catalog.jsonb_build_object(
      'familles', pg_catalog.to_jsonb(private.competences_codes('familles')),
      'competences', private.competences_catalogue_json(true, NULL),
      'peutModifier', true);
  END IF;
  v_id := private.competences_titulaire();
  IF NOT coalesce(auth.uid() IS NOT NULL AND v_id IS NOT NULL, false) THEN
    RAISE EXCEPTION 'catalogue des competences reserve a la direction et au titulaire d''une candidature enseignant'
      USING ERRCODE = '42501';
  END IF;
  SELECT a.domaines INTO v_enregistres
    FROM public.candidature_autres_competences a WHERE a.candidature_id = v_id;
  RETURN pg_catalog.jsonb_build_object(
    'familles', pg_catalog.to_jsonb(private.competences_codes('familles')),
    'competences', private.competences_catalogue_json(false, v_enregistres),
    'peutModifier', false);
END;
$function$;

-- Ajoute une competence au catalogue (p_version_attendue nulle) ou la modifie
-- (p_version_attendue = la version lue) : libelle, exemple, ordre, actif ;
-- le code et la famille ne changent pas, aucune ligne ne s'efface (une
-- competence se desactive, et se reactive). p_ordre nul : a la fin de sa
-- famille pour un ajout, inchange pour une modification. Direction active
-- seule. Rend {competence, inchange, rejoue} ou un refus rendu
-- (conflit_catalogue avec la ligne relue, absente, catalogue_plein,
-- cle_idempotence_reutilisee), jamais une erreur pour un refus de metier.
CREATE FUNCTION public.enregistrer_competence_catalogue(
  p_code text,
  p_famille text,
  p_ordre integer,
  p_libelle text,
  p_exemple text,
  p_actif boolean,
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
  v_libelle text;
  v_exemple text;
  v_empreinte text;
  v_j public.competences_catalogue_journal;
  v_k public.competences_catalogue;
  v_ordre integer;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'catalogue des competences reserve a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_cle_idempotence IS NULL OR pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200 THEN
    RAISE EXCEPTION 'cle d''idempotence invalide : 8 a 200 signes' USING ERRCODE = '22023';
  END IF;
  -- Un texte de plus de 1000 signes est refuse avant toute normalisation (comme
  -- le texte « autre »), puis les blancs de tete et de queue sont retires ; un
  -- texte vide vaut aucun texte.
  IF coalesce(pg_catalog.length(p_libelle), 0) > 1000 OR coalesce(pg_catalog.length(p_exemple), 0) > 1000 THEN
    RAISE EXCEPTION 'libelle ou exemple trop long' USING ERRCODE = '22023';
  END IF;
  v_libelle := private.candidature_motif(p_libelle);
  v_exemple := private.candidature_motif(p_exemple);
  v_empreinte := pg_catalog.md5(pg_catalog.jsonb_build_object(
    'code', p_code, 'famille', p_famille, 'ordre', p_ordre, 'libelle', v_libelle, 'exemple', v_exemple,
    'actif', p_actif, 'versionAttendue', p_version_attendue)::text);

  -- Reprise : la meme cle rend l'effet d'origine, relu au serveur, sans nouvel effet.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cand_autres_cle:' || p_cle_idempotence, 0));
  SELECT j.* INTO v_j FROM public.competences_catalogue_journal j WHERE j.cle_idempotence = p_cle_idempotence;
  IF v_j.id IS NOT NULL THEN
    IF v_j.auteur_id IS DISTINCT FROM v_uid OR v_j.empreinte IS DISTINCT FROM v_empreinte THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
    END IF;
    SELECT k.* INTO v_k FROM public.competences_catalogue k WHERE k.code = v_j.code;
    RETURN pg_catalog.jsonb_build_object('competence', private.competences_entree(v_k, true),
                                         'inchange', false, 'rejoue', true);
  END IF;

  -- Arguments : formes et listes fermees (22023).
  IF p_code IS NULL OR p_code !~ '^[a-z][a-z0-9_]{1,39}$'
     OR p_famille IS NULL OR p_famille <> ALL (private.competences_codes('familles'))
     OR (p_code = 'autre') <> (p_famille = 'autre')
     OR (p_code <> 'autre' AND p_code = ANY (private.competences_codes('familles')))
     OR (p_ordre IS NOT NULL AND p_ordre NOT BETWEEN 1 AND 999)
     OR v_libelle IS NULL OR pg_catalog.length(v_libelle) > 80
     OR v_libelle ~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]'
     OR (v_exemple IS NOT NULL AND (pg_catalog.length(v_exemple) > 200
                                    OR v_exemple ~ '[\u0001-\u001f\u007f-\u009f\u2028\u2029]'))
     OR p_actif IS NULL
     OR (p_version_attendue IS NOT NULL AND p_version_attendue < 1) THEN
    RAISE EXCEPTION 'competence du catalogue invalide : code, famille, ordre, libelle (1 a 80, une ligne), exemple (200 au plus, une ligne), actif et version attendue (1 ou plus) attendus'
      USING ERRCODE = '22023';
  END IF;

  -- Une ecriture a la fois : le plafond et la ligne se lisent sur un etat sur.
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('cand_autres_catalogue', 0));
  SELECT k.* INTO v_k FROM public.competences_catalogue k WHERE k.code = p_code FOR UPDATE;

  IF p_version_attendue IS NULL THEN
    IF v_k.code IS NOT NULL THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_catalogue',
                                           'competence', private.competences_entree(v_k, true));
    END IF;
    IF (SELECT pg_catalog.count(*) FROM public.competences_catalogue) >= 100 THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'catalogue_plein');
    END IF;
    v_ordre := coalesce(p_ordre, (SELECT LEAST(999, coalesce(pg_catalog.max(k.ordre), 0) + 1)
                                    FROM public.competences_catalogue k WHERE k.famille = p_famille));
    PERFORM pg_catalog.set_config('cand_autres.catalogue', pg_catalog.jsonb_build_object(
      'auteur', v_uid, 'cle', p_cle_idempotence, 'empreinte', v_empreinte)::text, true);
    INSERT INTO public.competences_catalogue (code, famille, ordre, libelle, exemple, actif)
    VALUES (p_code, p_famille, v_ordre, v_libelle, v_exemple, p_actif)
    RETURNING * INTO v_k;
    RETURN pg_catalog.jsonb_build_object('competence', private.competences_entree(v_k, true),
                                         'inchange', false, 'rejoue', false);
  END IF;

  IF v_k.code IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'absente');
  END IF;
  IF v_k.famille <> p_famille THEN
    RAISE EXCEPTION 'la famille d''une competence ne change pas' USING ERRCODE = '22023';
  END IF;
  IF p_version_attendue <> v_k.version THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'conflit_catalogue',
                                         'competence', private.competences_entree(v_k, true));
  END IF;
  v_ordre := coalesce(p_ordre, v_k.ordre);
  IF v_libelle = v_k.libelle AND v_exemple IS NOT DISTINCT FROM v_k.exemple
     AND v_ordre = v_k.ordre AND p_actif = v_k.actif THEN
    RETURN pg_catalog.jsonb_build_object('competence', private.competences_entree(v_k, true),
                                         'inchange', true, 'rejoue', false);
  END IF;
  PERFORM pg_catalog.set_config('cand_autres.catalogue', pg_catalog.jsonb_build_object(
    'auteur', v_uid, 'cle', p_cle_idempotence, 'empreinte', v_empreinte)::text, true);
  UPDATE public.competences_catalogue k
     SET libelle = v_libelle, exemple = v_exemple, ordre = v_ordre, actif = p_actif
   WHERE k.code = p_code
  RETURNING * INTO v_k;
  RETURN pg_catalog.jsonb_build_object('competence', private.competences_entree(v_k, true),
                                       'inchange', false, 'rejoue', false);
END;
$function$;

-- ============================================================
-- 7. Lectures de la direction redefinies (C7)
-- ============================================================

-- lire_candidature : corps de 20261022000100_cand_l2a2_gestes_direction.sql
-- recopie (garde, lecteur, absente ou hors_portee rendus, trace, exception
-- super-admin journalisee, dossier) ; seul ajout, la cle autresCompetences
-- (nulle sans reponse). Rien d'autre ne change.
CREATE OR REPLACE FUNCTION public.lire_candidature(p_id uuid)
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
    'pauseModele', v_c.pause_modele,
    'refusModele', v_c.issue_modele,
    'restrictionCause', v_c.restriction_cause,
    'autresCompetences', (SELECT private.competences_json(a)
                           FROM public.candidature_autres_competences a
                          WHERE a.candidature_id = v_c.id),
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

-- lister_candidatures : corps de 20261022000100_cand_l2a2_gestes_direction.sql
-- recopie (garde, portee dans le WHERE, filtres, tri, pages, compteurs,
-- audit) ; ajouts : quatre filtres de competence (competenceDomaine : un code
-- du catalogue ou une famille, competenceNiveauMin, competenceDisponibilite,
-- competenceAccord), un EXISTS dans le WHERE apres la portee, et la note
-- « competences » dans l'audit de la liste. Les lignes, les compteurs et le
-- tri ne changent pas.
CREATE OR REPLACE FUNCTION public.lister_candidatures(
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
  v_comp_domaine text;
  v_comp_codes text[];
  v_comp_niveau text;
  v_comp_dispo text;
  v_comp_accord boolean;
  v_comp boolean;
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
                            'paysResidence', 'recherche', 'competenceDomaine',
                            'competenceNiveauMin', 'competenceDisponibilite', 'competenceAccord']);
  IF v_fautives IS NOT NULL THEN
    RAISE EXCEPTION 'filtre de candidatures inconnu : %', v_fautives USING ERRCODE = '22023';
  END IF;
  SELECT pg_catalog.string_agg(e.key, ', ' ORDER BY e.key) INTO v_fautives
  FROM pg_catalog.jsonb_each(v_filtre) e
  WHERE pg_catalog.jsonb_typeof(e.value) <> 'null'
    AND pg_catalog.jsonb_typeof(e.value)
        <> CASE WHEN e.key IN ('enPause', 'competenceAccord') THEN 'boolean' ELSE 'string' END;
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
  v_comp_domaine := v_filtre ->> 'competenceDomaine';
  v_comp_niveau := v_filtre ->> 'competenceNiveauMin';
  v_comp_dispo := v_filtre ->> 'competenceDisponibilite';
  v_comp_accord := (v_filtre ->> 'competenceAccord')::boolean;
  v_comp := coalesce(v_comp_domaine, v_comp_niveau, v_comp_dispo) IS NOT NULL OR v_comp_accord IS NOT NULL;
  v_recherche := nullif(pg_catalog.btrim(v_filtre ->> 'recherche'), '');

  -- CAND-L2A2 (D15) : l'etat paiement_non_disponible de L6 se filtre.
  IF (v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM public.candidature_types t WHERE t.code = v_type))
     OR (v_etape IS NOT NULL AND v_etape NOT IN
        ('recue', 'invitee', 'prequalification', 'verifications', 'confirmee'))
     OR (v_etat IS NOT NULL AND v_etat NOT IN ('a_completer', 'en_examen', 'paiement_non_disponible',
        'entretien_a_planifier', 'entretien_planifie', 'decision_en_attente'))
     OR (v_issue IS NOT NULL AND v_issue NOT IN ('en_cours', 'refusee', 'retiree'))
     OR (v_paiement IS NOT NULL AND v_paiement NOT IN
        ('inconnu', 'compatible', 'incompatible', 'a_verifier'))
     OR (v_pays IS NOT NULL AND v_pays !~ '^[A-Z]{2}$')
     OR (v_comp_domaine IS NOT NULL AND NOT (
           v_comp_domaine = ANY (private.competences_codes('familles'))
           OR EXISTS (SELECT 1 FROM public.competences_catalogue k WHERE k.code = v_comp_domaine)))
     OR (v_comp_niveau IS NOT NULL AND v_comp_niveau <> ALL (private.competences_codes('niveaux')))
     OR (v_comp_dispo IS NOT NULL AND v_comp_dispo <> ALL (private.competences_codes('disponibilites')))
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
  -- Un code du catalogue ou une famille : les codes cherches, actifs ou non
  -- (une reponse ancienne reste cherchable, C12).
  IF v_comp_domaine IS NOT NULL THEN
    SELECT coalesce(pg_catalog.array_agg(k.code), ARRAY[]::text[]) INTO v_comp_codes
      FROM public.competences_catalogue k
     WHERE k.code = v_comp_domaine OR k.famille = v_comp_domaine;
  END IF;

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
      AND (NOT v_comp OR EXISTS (
             SELECT 1 FROM public.candidature_autres_competences a
              WHERE a.candidature_id = c.id
                AND (v_comp_accord IS NULL OR a.accord_contact = v_comp_accord)
                AND (v_comp_dispo IS NULL OR a.disponibilite = v_comp_dispo)
                AND ((v_comp_domaine IS NULL AND v_comp_niveau IS NULL) OR EXISTS (
                       SELECT 1 FROM pg_catalog.jsonb_each_text(a.domaines) d
                        WHERE (v_comp_domaine IS NULL OR d.key = ANY (v_comp_codes))
                          AND (v_comp_niveau IS NULL
                               OR private.competences_rang_niveau(d.value)
                                  >= private.competences_rang_niveau(v_comp_niveau))))))
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

  -- Les compteurs : toute la portee, sans les autres filtres. CAND-L2A2
  -- (D15) : un complement en cours en salle 2 compte dans les informations
  -- manquantes, comme a_completer en salle 1.
  SELECT pg_catalog.jsonb_build_object(
           'recue', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'recue'),
           'invitee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'invitee'),
           'prequalification', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'prequalification'),
           'verifications', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'verifications'),
           'confirmee', pg_catalog.count(*) FILTER (WHERE c.issue = 'en_cours' AND c.etape = 'confirmee')),
         pg_catalog.jsonb_build_object(
           'informationsManquantes', pg_catalog.count(*) FILTER (
             WHERE c.issue = 'en_cours' AND NOT c.en_pause
               AND (c.etat = 'a_completer'
                    OR CASE WHEN c.etape = 'verifications'
                            THEN pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(c)) > 0
                            ELSE false END)),
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
      'recherche', v_recherche IS NOT NULL,
      'competences', v_comp));

  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'total', v_total,
    'page', p_page,
    'taillePage', 50,
    'compteursEtapes', v_etapes,
    'compteursAlertes', v_alertes);
END;
$function$;

-- ============================================================
-- 8. Droits, empreintes F86, controle final
-- ============================================================

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.lire_autres_competences()',
    'public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)',
    'public.retirer_autres_competences(integer,text)',
    'public.lire_catalogue_competences()',
    'public.enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)',
    'public.lire_candidature(uuid)',
    'public.lister_candidatures(jsonb,text,integer)'
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
      ('public.lire_autres_competences()', 'POSITIVE_CANDIDATE_SELF',
       'Titulaire d une candidature enseignant au compte valide (L1-08), sinon 42501 ; rend si c est ouvert et pourquoi sinon (candidature_close, questionnaire_non_envoye), la version, ses reponses, les listes fermees ; lecture seule, ouverte aussi a une candidature close pour qu elle puisse retirer.'),
      ('public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)', 'POSITIVE_CANDIDATE_SELF_ENGINE',
       'Titulaire d une candidature enseignant au compte valide, sinon 42501 ; arguments 22023 ; cle d idempotence (public.candidature_gestes, rejeu sans ecriture) ; ouvert apres l envoi de la Salle d examen et tant que la candidature est en cours, sinon refus rendu ; version attendue (0 sans reponse) ; reponses de la liste fermee, sinon reponses_invalides nommees ; une ecriture identique ne change rien ; ni version de candidature, ni activite, ni evenement ; audit sans reponse ; aucune reponse gardee sous la cle.'),
      ('public.retirer_autres_competences(integer,text)', 'POSITIVE_CANDIDATE_SELF_ENGINE',
       'Titulaire d une candidature enseignant au compte valide, sinon 42501 ; cle d idempotence et version attendue ; efface les reponses et l accord a toute issue de la candidature ; rien a retirer rendu retire = false ; audit sans reponse.'),
      ('public.lire_catalogue_competences()', 'ROLE_POSITIVE_ADMIN_OR_CANDIDATE_SELF',
       'Direction active (tout le catalogue, avec les versions et peutModifier) ou titulaire d une candidature enseignant au compte valide (les competences actives et, avec actif = faux, celles de sa propre reponse), sinon 42501 ; lecture seule ; aucune condition de genre, le catalogue ne porte aucune donnee de personne.'),
      ('public.enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)', 'ROLE_POSITIVE_ADMIN',
       'Direction active seule, sinon 42501 ; cle d idempotence (journal du catalogue, rejeu sans ecriture) ; arguments 22023 ; ajout (version attendue nulle) ou modification par version attendue ; code et famille immuables ; aucune suppression, une competence se desactive ; plafond de 100 codes ; refus rendus conflit_catalogue, absente, catalogue_plein, cle_idempotence_reutilisee ; journal et audit sans libelle.'),
      ('public.lire_candidature(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Corps de CAND-L2A2 garde (direction active ; absente ou hors_portee rendus, jamais leves ; hors portee trace sans aucune donnee ; exception super-admin journalisee ; pauseModele, refusModele, restrictionCause) ; CAND-AUTRES : autresCompetences rendu dans la portee, nul sans reponse.'),
      ('public.lister_candidatures(jsonb,text,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Corps de CAND-L2A2 garde (portee par genre dans le WHERE, genre inconnu 42501, filtres 22023, aucune cle courriel, telephone ni genre, audit de chaque liste, etat paiement_non_disponible) ; CAND-AUTRES : filtres competenceDomaine, competenceNiveauMin, competenceDisponibilite, competenceAccord apres la portee, valeurs hors liste fermee 22023, audit qui note le filtre.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-22. CAND-AUTRES.%s %s Must-pass: supabase/tests/scenarios_cand_autres_competences.sql%s.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde,
      CASE WHEN v.signature IN ('public.lire_candidature(uuid)', 'public.lister_candidatures(jsonb,text,integer)')
           THEN ' Repris de CAND-L2A2 (CAND-L1 avant lui).' ELSE '' END,
      v.note,
      CASE WHEN v.signature IN ('public.lire_candidature(uuid)', 'public.lister_candidatures(jsonb,text,integer)')
           THEN ', supabase/tests/scenarios_cand_l2a2_gestes_direction.sql, supabase/tests/scenarios_cand_l1_socle.sql'
           ELSE '' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Les RPC : DEFINER, proprietaire postgres, search_path vide, volatilite
  -- attendue, empreinte F86 a jour (CAND-AUTRES), authenticated seul, aucune
  -- garde negative.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.lire_autres_competences()', 's'),
      ('public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)', 'v'),
      ('public.retirer_autres_competences(integer,text)', 'v'),
      ('public.lire_catalogue_competences()', 's'),
      ('public.enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)', 'v'),
      ('public.lire_candidature(uuid)', 'v'),
      ('public.lister_candidatures(jsonb,text,integer)', 'v')
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
       OR coalesce(pg_catalog.obj_description(v.oid, 'pg_proc'), '') NOT LIKE '%CAND-AUTRES%'
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc) THEN
      RAISE EXCEPTION 'CAND-AUTRES : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL ou garde invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Les deux lectures de la direction gardent leur corps et leur ajout.
  IF pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                         WHERE p.oid = 'public.lire_candidature(uuid)'::regprocedure), 'autresCompetences') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lire_candidature(uuid)'::regprocedure), 'cand_hors_portee') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lire_candidature(uuid)'::regprocedure), 'restrictionCause') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'competenceNiveauMin') = 0
     OR pg_catalog.strpos((SELECT p.prosrc FROM pg_catalog.pg_proc p
                            WHERE p.oid = 'public.lister_candidatures(jsonb,text,integer)'::regprocedure),
                          'paiement_non_disponible') = 0 THEN
    RAISE EXCEPTION 'CAND-AUTRES : lire_candidature ou lister_candidatures a perdu son corps ou son ajout';
  END IF;

  -- Les aides internes : appelables par aucun compte ; quatorze, et les neuf
  -- aides cand_ de CAND-L1 restent neuf.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
       WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'competences\_%') <> 14 THEN
    RAISE EXCEPTION 'CAND-AUTRES : quatorze aides competences_ attendues';
  END IF;
  FOR v IN
    SELECT p.oid
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'competences\_%'
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-AUTRES : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
      WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-AUTRES : les aides cand_ de CAND-L1 doivent rester neuf';
  END IF;

  -- Les trois tables : RLS active, aucun privilege client, aucune policy.
  FOR v IN
    SELECT t.nom FROM (VALUES ('public.candidature_autres_competences'), ('public.competences_catalogue'),
                              ('public.competences_catalogue_journal')) AS t(nom)
  LOOP
    IF NOT (SELECT c.relrowsecurity FROM pg_catalog.pg_class c WHERE c.oid = v.nom::regclass) THEN
      RAISE EXCEPTION 'CAND-AUTRES : RLS inactive sur %', v.nom;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_table_privilege(v_role, v.nom, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-AUTRES : % garde un privilege sur %', v_role, v.nom;
      END IF;
    END LOOP;
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies
                WHERE schemaname = 'public' AND tablename = pg_catalog.split_part(v.nom, '.', 2)) THEN
      RAISE EXCEPTION 'CAND-AUTRES : une policy ouvre %', v.nom;
    END IF;
  END LOOP;
  FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
    IF pg_catalog.has_sequence_privilege(v_role, 'public.competences_catalogue_journal_id_seq', 'USAGE,SELECT,UPDATE') THEN
      RAISE EXCEPTION 'CAND-AUTRES : % garde un privilege sur la sequence du journal du catalogue', v_role;
    END IF;
  END LOOP;

  -- Le catalogue ne se supprime ni ne se vide, son journal est en ajout seul,
  -- le journal de l'etat initial est complet (C12, C14) : une ligne par code.
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_trigger t
       WHERE t.tgrelid IN ('public.competences_catalogue'::regclass, 'public.competences_catalogue_journal'::regclass,
                           'public.candidature_autres_competences'::regclass)
         AND NOT t.tgisinternal
         AND t.tgname IN ('competences_catalogue_journal_ajout_seul', 'competences_catalogue_journal_sans_vidage',
                          'competences_catalogue_sans_suppression', 'competences_catalogue_sans_vidage',
                          'competences_catalogue_garde', 'competences_catalogue_journal',
                          'candidature_autres_competences_domaines_connus')) <> 7
     OR (SELECT pg_catalog.count(*) FROM public.competences_catalogue) <> 25
     OR (SELECT pg_catalog.count(*) FROM public.competences_catalogue_journal WHERE geste = 'etat_initial') <> 25
     OR EXISTS (SELECT 1 FROM public.competences_catalogue k
                 WHERE NOT EXISTS (SELECT 1 FROM public.competences_catalogue_journal j WHERE j.code = k.code)) THEN
    RAISE EXCEPTION 'CAND-AUTRES : declencheurs du catalogue, 25 competences ou journal de l''etat initial invalides';
  END IF;

  -- Aucune autre fonction publique ni privee ne lit la table des reponses (C8) :
  -- les deux lectures de la direction, les RPC du candidat, la lecture du
  -- catalogue (reponse propre du candidat) et les aides de ce lot.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname IN ('public', 'private', 'app_private')
       AND p.prosrc LIKE '%candidature_autres_competences%'
       AND p.oid NOT IN (
         'public.lire_autres_competences()'::regprocedure,
         'public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)'::regprocedure,
         'public.retirer_autres_competences(integer,text)'::regprocedure,
         'public.lire_catalogue_competences()'::regprocedure,
         'public.lire_candidature(uuid)'::regprocedure,
         'public.lister_candidatures(jsonb,text,integer)'::regprocedure)
  ) THEN
    RAISE EXCEPTION 'CAND-AUTRES : une fonction hors du lot lit candidature_autres_competences';
  END IF;
  -- Ni le catalogue : le controle, le paiement, les transitions et
  -- etat_dossier() ne le citent pas.
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_proc p
      JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
     WHERE n.nspname IN ('public', 'private', 'app_private')
       AND p.prosrc LIKE '%competences_catalogue%'
       AND NOT (n.nspname = 'private' AND p.proname LIKE 'competences\_%')
       AND p.oid NOT IN (
         'public.lire_autres_competences()'::regprocedure,
         'public.enregistrer_autres_competences(jsonb,text,text,boolean,integer,text)'::regprocedure,
         'public.lire_catalogue_competences()'::regprocedure,
         'public.enregistrer_competence_catalogue(text,text,integer,text,text,boolean,integer,text)'::regprocedure,
         'public.lister_candidatures(jsonb,text,integer)'::regprocedure)
  ) THEN
    RAISE EXCEPTION 'CAND-AUTRES : une fonction hors du lot lit competences_catalogue';
  END IF;
END;
$postflight$;

COMMIT;
