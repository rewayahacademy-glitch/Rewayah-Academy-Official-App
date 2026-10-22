-- CAND-L2A2 (22/10/2026) : gestes de la direction du module des candidatures
-- qui ne demandent ni entretien ni controles nommes, et l'action groupee
-- (ADM-22).
--
-- Decisions du directeur : docs/current/DECISION-CANDIDATURES-2026-10-21.md
-- (CAND-Q02 lot serveur borne sur la base de test ; CAND-Q05 paiement, ligne
-- 28 ; CAND-Q07 separation femmes/hommes en base, ligne 30 ; CAND-Q10 le
-- candidat est prevenu dans l'app et par courriel, ligne 33 ; CAND-Q18 deux
-- issues de piece, ligne 41).
-- Specification consolidee : SPEC_CONSOLIDEE_CANDIDATURES_2026-10-21.md,
-- sections 2.2 (gestes par salle), 4.1, 4.2 (transitions 7, 10, 16, 17, 18,
-- 19, 23, 24, 25, 28 ; gestes groupables), 4.3 (pendant une pause), 5 et 5.1
-- (paiement_compatible, decisions de la direction), 8.1 (capacites), 8.2
-- (portee par genre), 10 (ADM-20, ADM-21, ADM-22), 11 (ligne L2) et 12.1
-- (L2-4, L2-7, L2-9, L2-10, L2-11, L2-17, L2-18). Contrat :
-- CONTRAT_PORTS_CANDIDATURES.md, regles transverses et section 1 (geste,
-- preparerLot, executerLot, definirResponsable). Besoins :
-- DEPENDANCES_BACKEND.md, CAND-BR-04, CAND-BR-06, CAND-BR-13 (gestes 24 et
-- 25). Courriels : CONTRAT_FILE_COURRIELS.md section 3 (codes des modeles,
-- marqueur aNotifier pour L5).
--
-- Ce lot pose, chaque geste par le moteur de CAND-L2A1
-- (private.candidature_geste_ouvrir, _appliquer, _conclure), cote de la
-- direction seulement :
-- * demander_complement_candidat : transition 7 (en_examen vers a_completer)
--   et 23 (Salle de verification et d'entretien, meme etat), elements
--   manquants nommes au candidat, motif ;
-- * admettre_salle_verification : transition 10, paiement_compatible (L6),
--   cadre religieux a la version requise, questionnaire complet a la version
--   courante, sinon controles_non_satisfaits nommes ;
-- * refuser_candidat : transition 16, motif interne et modele de message ;
-- * consigner_retrait_candidat : transition 17 par la direction, demande
--   recue par la conversation ou par courriel, canal et date traces, motif ;
-- * mettre_en_pause_candidat et lever_pause_candidat : transition 18, motif
--   et modele a la pose, reprise facultative ;
-- * rouvrir_candidat : transition 19, controles de l'etape reverifies,
--   questionnaire a la version courante, sinon controles_non_satisfaits ;
-- * definir_responsable_candidat : transition 28, membre actif de la
--   direction du meme cote, ou aucun ;
-- * confirmer_moyen_paiement_candidat et infirmer_moyen_paiement_candidat :
--   transitions 24 et 25, ecrites dans public.candidature_paiement_decisions
--   comme L6 l'a prevu, puis private.paiement_recalculer ;
-- * apercu_lot_candidats et executer_lot_candidats : l'action groupee
--   (ADM-22) pour mettre en pause, lever la pause et refuser ;
-- * capacites_candidatures redefinie : peutDecider, une capacite par geste,
--   peutEcrireReferentiel lu dans private.paiement_gestionnaire(), listes
--   fermees du lot ;
-- * lister_candidatures redefinie : le filtre etat accepte
--   paiement_non_disponible (question ouverte de L6), et le compteur
--   informationsManquantes compte le complement demande en salle 2 (L2-18,
--   D15).
--
-- Choix faits dans ce lot, a relire :
-- * D1 une RPC par geste (spec 4.2) ; aucun nom ne contient "candidature"
--   (scenario de CAND-L1, controle (a), et C14 de CAND-L2A1 : etat_dossier()
--   reste la seule lecture de l'etat du candidat) ; aucune aide privee ne
--   commence par cand_ (le scenario de CAND-L1 en compte neuf) ;
-- * D2 ordre des refus : garde positive de la direction active (42501) ;
--   arguments (22023) ; puis le moteur (auteur, genre connu, absente,
--   hors_portee trace, rejeu de la cle, conflit_candidature,
--   transition_interdite, motif_requis, modele_requis) ; puis les refus
--   propres au geste, RENDUS sans ecriture. Une cle rejouee rend donc le
--   premier resultat meme si une liste fermee a change depuis ;
-- * D3 resultat d'un geste : l'etat relu au serveur apres l'ecriture
--   (private.candidature_etat_direction : etape, etat, issue, pause et son
--   modele, refus et son modele, restriction et sa cause, indisponibilite,
--   paiement, responsable, version), garde sous la cle ; jamais une reponse,
--   un motif ni un nom (conservation, CAND-Q21). Le dossier complet se relit
--   par lire_candidature ;
-- * D4 modeles de message (refus, pause) : liste fermee privee
--   private.candidature_modeles_message, ecrite par migration ; codes
--   proposes, textes en fr et ar avec les ecrans (mots-rewayah), a soumettre
--   au directeur (spec 0.2 bis). Un modele hors liste est refuse
--   (modele_inconnu) ;
-- * D5 elements d'un complement (transitions 7 et 23) : liste fermee par
--   salle, private.candidature_complement_codes. En Salle d'examen : les
--   cartes du questionnaire courant (langues, recitation, disponibilites,
--   publics, versement) et cadre_religieux ; en Salle de verification et
--   d'entretien : piece_identite, cadre_religieux, contrat, avis, ce que le
--   candidat peut y faire (aucune transition ne lui rouvre ses reponses en
--   salle 2). Codes ecrits dans details.aCompleter de l'evenement, lus par
--   etat_dossier() (complementDemande, CAND-L2A1). A soumettre au directeur
--   (spec 0.2 bis) ;
-- * D6 admission (10) : trois controles, chacun nomme avec sa cause
--   (paiement_compatible : la dimension de L6 ; cadre_religieux : non_publie
--   ou non_accepte ; questionnaire_complet : absent, perime, incomplet ou
--   questionnaire_absent). Le questionnaire se lit sur le dernier document
--   envoye (jamais un brouillon), sans la cle accordRemuneration ni les
--   operateurs, que le controle de paiement couvre ;
-- * D7 reouverture (19), lecture stricte : compte_conforme (la regle de
--   CAND-L1B, nommee au lieu d'etre levee : role du type, pending_kyc, non
--   supprime, non expire, aucun engagement d'enseignant) ; questionnaire a
--   jour pour les etats qui suivent un envoi (en_examen,
--   paiement_non_disponible, salle 2) ; en salle 2, paiement_compatible et
--   cadre religieux (spec 5, colonne Exige pour) : rouvrir une candidature de
--   salle 2 est une rentree en salle 2, que 4.3 refuse sans paiement
--   compatible ni cadre a la version requise. Une candidature dont le
--   questionnaire ou, en salle 2, le cadre a change de version pendant
--   qu'elle etait refusee ou retiree ne se rouvre donc pas, et le blocage ne
--   se leve pas de lui-meme : le candidat n'accepte un texte que candidature
--   en cours (policy C9 de CAND-L2A1). A l'inverse, une candidature en examen
--   se rouvre sans le cadre ni les conditions de remuneration que la
--   transition 6 exige : seul son questionnaire est controle. A soumettre au
--   directeur (spec 0.2 bis). Apres la reouverture, le paiement est recalcule
--   (private.paiement_recalculer, cause reouverture, D19) : la transition 9
--   ou la transition 8 suit si besoin ;
-- * D8 retrait par la direction (17) : canal conversation ou courriel, date
--   de la demande ni future ni anterieure a la reception de la candidature,
--   motif ; l'entretien planifie est seulement note (L4 l'annulera) ;
-- * D9 pause (18) : reprise facultative, posterieure au jour UTC courant ;
--   lever la pause n'exige ni motif ni modele (motif facultatif, garde dans
--   l'evenement) ;
-- * D10 responsable (28) : le predicat du moteur (direction active, du meme
--   cote, non supprimee), verifie avant l'ecriture et rendu
--   responsable_invalide plutot que leve ;
-- * D11 paiement (24, 25) : le geste s'applique AVANT la decision (la regle
--   lit la dimension paiement en direct), puis la decision s'ecrit dans
--   public.candidature_paiement_decisions et private.paiement_recalculer
--   (moyen_confirme ou moyen_infirme, auteur, motif) en tire les effets : la
--   transition 8 suit une infirmation qui rend le paiement incompatible. Le
--   moyen est nomme (methode, operateur pour le mobile money) et doit etre
--   declare ; une confirmation exige une ligne confirme du pays de
--   versement : une ligne en_verification ne se confirme jamais
--   (moyen_non_confirmable, cause et etat de la ligne). En salle 3 sous
--   restriction de cause paiement (24, variante 2), la confirmation rend le
--   paiement compatible sans lever la restriction : la levee est la
--   transition 21 (L2B) ;
-- * D12 action groupee (ADM-22, PORTS preparerLot et executerLot) : gestes
--   groupables dans ce lot : mettre_en_pause, lever_pause, refuser ;
--   inviter et consigner_prevenu (L3) et tout autre geste rendent
--   geste_non_groupable. L'apercu rend les eligibles (reference, nom, etape,
--   etat, version), les exclus avec leur raison (absente, hors_portee sans
--   aucune donnee, transition_interdite avec pause ou etat), l'effet, le
--   nombre et un jeton (empreinte HMAC, D17, de l'auteur, du geste, des
--   eligibles et de leurs versions, des exclus). L'execution prend les memes identifiants,
--   le jeton et le nombre saisi : jeton different (le lot a change),
--   jeton_perime ; nombre different, nombre_discordant ; aucun eligible,
--   aucun_eligible ; motif et modele exiges une fois pour le lot ; rien
--   n'est ecrit avant ces controles. Chaque ligne passe ensuite seule par le
--   moteur, sous une cle derivee de celle du lot, dans un sous-bloc : un
--   refus ou une erreur n'annule jamais une reussite voisine ; chaque ligne
--   est reussie, exclue (inchangee) ou refusee, avec sa raison. Une tentative
--   hors portee laisse sa trace a l'apercu et a l'execution. Le rapport est
--   garde sous la cle du lot (public.candidature_lots, en ajout seul, sans
--   nom, sans reponse ni motif) : la meme cle rejouee le rend sans ecriture ;
--   reprise pour un autre geste, d'autres identifiants ou un autre auteur,
--   refusee. Au plus 200 candidatures par lot ;
-- * D13 capacites (spec 8.1) : peutDecider pour la direction active de genre
--   connu (un geste ne vaut que de son cote, l'exception super-admin reste de
--   lecture) ; une capacite par geste, vraie seulement pour ceux que le
--   serveur sait faire ; peutEcrireReferentiel lu dans
--   private.paiement_gestionnaire() (direction ou comptabilite, L6) ; listes
--   fermees rendues pour l'ecran (modeles, elements, canaux). Le defaut de
--   CORRECTIFS_HORS_MODULE_PROPOSES.md 0 ter (un membre de la direction change
--   son propre genre, sans trace) ouvre aussi ces gestes de l'autre cote tant
--   qu'il n'est pas corrige : a corriger avant tout passage sur staging ;
-- * D14 notifications et courriels : marqueur aNotifier dans l'evenement
--   seulement (complement_demande, admis_salle_verification, refus,
--   retrait_enregistre, pause_posee, pause_levee), le code du modele de la
--   liste fermee de CONTRAT_FILE_COURRIELS.md section 3 ; ce lot n'ecrit ni
--   notification ni courriel (L5). Aucun marqueur pour 19 et 25 (ecart 6 du
--   contrat de la file), ni pour 24 et 28, absents de la liste de la spec 7.2 ;
-- * D15 lister_candidatures (spec 4.2, ligne 23 ; L2-18) : le filtre etat
--   accepte paiement_non_disponible ; informationsManquantes compte une
--   candidature de la Salle de verification et d'entretien dont un
--   complement est en cours, selon la regle de complementDemande
--   d'etat_dossier() (private.candidature_complement_en_cours), comme
--   a_completer en salle 1 ; une pause n'y entre jamais (C5 de CAND-L1) ;
-- * D16 (relecture du 22/10) action groupee, traces : chaque identifiant de
--   l'autre cote laisse sa trace des l'entree dans l'apercu ou l'execution,
--   avant tout refus rendu (geste non groupable, motif, modele, date, cle
--   reprise, jeton, nombre) : private.candidature_lot_tracer. Un refus LEVE
--   (22023) ne porte que sur la forme des arguments et precede la trace, qu'il
--   effacerait. Un rejeu de la cle retrace ces identifiants (chaque appel est
--   une tentative, comme pour un geste seul) et rend hors_portee quand un
--   identifiant du rapport garde est desormais de l'autre cote (le moteur
--   verifie la portee avant le rejeu). L'apercu ecrit une ligne audit_logs
--   (candidatures_apercu_lot : cote du lecteur, geste, nombres, jamais un nom)
--   comme une lecture de liste ;
-- * D17 jeton : une empreinte HMAC-SHA256 (extensions.hmac), cle secrete du
--   serveur engendree a l'application de la migration
--   (private.candidature_lot_secret, gen_random_uuid ; jamais dans le depot),
--   tronquee a 32 signes. Aucun client ne peut le calculer : il ne l'obtient
--   que de l'apercu, qui trace ses tentatives. Changer la cle perime les
--   apercus ouverts ;
-- * D18 vocabulaire : l'apercu et l'execution acceptent les codes du moteur
--   (mettre_en_pause, lever_pause, refuser) et ceux de
--   capacites_candidatures().gestesGroupables (mettreEnPause, leverPause,
--   refuser) ; le rapport rend le code du moteur ;
-- * D19 reouverture et paiement : private.paiement_recalculer (corps de
--   20261021220100 recopie) gagne la cause reouverture : une candidature
--   rouverte en paiement_non_disponible dont le paiement n'est plus
--   incompatible (une ligne est passee confirme pendant le refus ou le
--   retrait, que le declencheur de L6 ne voit pas) passe en a_completer
--   (transition 9) ; la transition 8 suit toujours si besoin. Le code
--   d'element que la transition 9 nomme est la carte versement, celle de la
--   liste fermee de D5 (L6 ecrivait moyen_paiement) ;
-- * D20 fin d'un complement de salle 2 : en salle 2 aucun envoi ne remplace la
--   demande (la transition 6 ne vaut qu'en salle 1) et la plupart des elements
--   (piece, contrat, avis) n'ont pas encore de fin calculable : le complement
--   se cloture par un geste de la direction, la transition 23 avec le seul code
--   complement_clos (meme etat, evenement a liste vide, aucun marqueur
--   aNotifier) ; sans complement en cours : aucun_complement. A soumettre au
--   directeur (spec 0.2 bis) avec l'autre voie (fin calculee par element) ;
-- * D21 lire_candidature (corps de CAND-L1 recopie) rend pauseModele,
--   refusModele et restrictionCause, que le geste rend deja : l'ecran
--   relit le meme etat que celui que le geste vient de rendre ;
-- * D22 entretien planifie : le refus (16) et le retrait (17) notent
--   entretienPlanifie ; la reouverture (19) rend l'etat d'origine, y compris
--   entretien_planifie. Que l'etat d'origine apres un entretien annule soit
--   entretien_planifie ou entretien_a_planifier (cible de la ligne 12) est
--   laisse ouvert par la spec : a soumettre au directeur (0.2 bis), a regler
--   avec L4, qui annule la seance.
--
-- Conservation (CAND-Q21, CAND-BR-14, spec 8.4) : public.candidature_lots
-- (en ajout seul, sans nom, reponse ni motif) entre dans le lot de
-- conservation avec candidature_gestes.
--
-- Hors de ce lot : entretiens (L4, transitions 11 a 13) ; les huit controles
-- nommes, la validation de piece et la salle 3, le refus definitif de piece
-- (L2B, transitions 14, 15, 20 a 22) ; inviter, consigner_prevenu, rattacher,
-- garder pour suivi (L3, transitions 2, 3, 26, 27) ; notifications et
-- courriels (L5).
BEGIN;

-- ============================================================
-- 1. Listes fermees et lots
-- ============================================================

-- Les modeles de message que la direction choisit pour un refus ou une pause
-- (D4). Le candidat lit le texte du modele, jamais le motif interne. Codes
-- proposes, a soumettre au directeur ; ecrite par migration seulement.
CREATE TABLE private.candidature_modeles_message (
  code text PRIMARY KEY CHECK (code ~ '^[a-z][a-z0-9_]{1,59}$'),
  usage text NOT NULL CHECK (usage IN ('refus', 'pause')),
  rang smallint NOT NULL CHECK (rang >= 1),
  actif boolean NOT NULL DEFAULT true,
  CONSTRAINT candidature_modeles_message_rang UNIQUE (usage, rang)
);
INSERT INTO private.candidature_modeles_message (code, usage, rang) VALUES
  ('refus_general', 'refus', 1),
  ('refus_niveau', 'refus', 2),
  ('refus_besoins', 'refus', 3),
  ('refus_sans_reponse', 'refus', 4),
  ('pause_attente_besoin', 'pause', 1),
  ('pause_attente_informations', 'pause', 2),
  ('pause_demande_candidat', 'pause', 3),
  ('pause_general', 'pause', 4);
COMMENT ON TABLE private.candidature_modeles_message IS
  'CAND-L2A2 : liste fermee des modeles de message du refus et de la pause (D4) ; codes proposes, a '
  'soumettre au directeur ; textes fr et ar avec les ecrans. Ecrite par migration seulement.';

-- Les rapports de l'action groupee (D12), en ajout seul : un par cle de lot.
CREATE TABLE public.candidature_lots (
  cle text PRIMARY KEY CHECK (pg_catalog.length(cle) BETWEEN 8 AND 200),
  auteur_id uuid NOT NULL REFERENCES public.profiles(id),
  geste text NOT NULL CHECK (geste IN ('mettre_en_pause', 'lever_pause', 'refuser')),
  empreinte text NOT NULL CHECK (empreinte ~ '^[0-9a-f]{32}$'),
  jeton text NOT NULL CHECK (jeton ~ '^[0-9a-f]{32}$'),
  resultat jsonb NOT NULL CHECK (pg_catalog.jsonb_typeof(resultat) = 'object'),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
CREATE INDEX candidature_lots_auteur_idx ON public.candidature_lots (auteur_id, cree_le DESC);
CREATE TRIGGER candidature_lots_ajout_seul
  BEFORE UPDATE OR DELETE ON public.candidature_lots
  FOR EACH ROW EXECUTE FUNCTION private.cand_evenements_refuser_mutation();
COMMENT ON TABLE public.candidature_lots IS
  'CAND-L2A2 : rapport de chaque action groupee sous sa cle d idempotence (D12), en ajout seul ; '
  'jamais un nom, une reponse ni un motif ; aucune policy. Conservation : CAND-Q21.';

-- La cle des jetons de l'action groupee (D17) : un secret du serveur, une
-- seule ligne, engendre ici par la base (gen_random_uuid, 244 bits) et jamais
-- ecrit dans le depot. Aucun compte ne la lit. Pour la changer, le proprietaire
-- de la base met la ligne a jour : les apercus ouverts deviennent perimes.
CREATE TABLE private.candidature_lot_secret (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  secret text NOT NULL CHECK (pg_catalog.length(secret) >= 64),
  cree_le timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);
INSERT INTO private.candidature_lot_secret (secret)
VALUES (pg_catalog.gen_random_uuid()::text || pg_catalog.gen_random_uuid()::text);
COMMENT ON TABLE private.candidature_lot_secret IS
  'CAND-L2A2 : cle secrete des jetons de l action groupee (D17), engendree a l application de la migration ; '
  'une ligne ; aucune policy, aucun privilege client.';

REVOKE ALL ON private.candidature_modeles_message, private.candidature_lot_secret, public.candidature_lots
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;
ALTER TABLE private.candidature_modeles_message ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.candidature_lot_secret ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidature_lots ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 2. Aides internes (schema private, jamais appelables par un compte)
-- ============================================================

-- L'etat relu d'une candidature apres un geste (D3) : ses dimensions, sa
-- version ; jamais une reponse, un motif, un nom ni un contact.
CREATE FUNCTION private.candidature_etat_direction(p_id uuid)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT pg_catalog.jsonb_build_object(
    'id', c.id,
    'reference', c.reference,
    'type', c.type_code,
    'etape', c.etape,
    'etat', c.etat,
    'issue', c.issue,
    'enPause', c.en_pause,
    'repriseLe', c.reprise_le,
    'pauseModele', c.pause_modele,
    'refusModele', c.issue_modele,
    'restreinte', c.restreinte,
    'restrictionCause', c.restriction_cause,
    'indisponible', private.cand_indisponible(c),
    'paiement', c.paiement,
    'responsableId', c.responsable_id,
    'version', c.version,
    'derniereActivite', private.cand_instant(c.derniere_activite))
  FROM public.candidatures c
  WHERE c.id = p_id;
$function$;

-- Les elements qu'un complement peut nommer (D5), par salle : en Salle
-- d'examen, les cartes du questionnaire courant du type (dans leur ordre)
-- puis cadre_religieux ; en Salle de verification et d'entretien, ce que le
-- candidat peut y faire.
CREATE FUNCTION private.candidature_complement_codes(p_etape text, p_type text)
RETURNS text[]
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT CASE
    WHEN p_etape = 'prequalification' THEN
      coalesce((
        SELECT pg_catalog.array_agg(x.carte ORDER BY x.rang)
        FROM (
          SELECT c.e ->> 'carte' AS carte, pg_catalog.min(c.o) AS rang
          FROM public.candidature_questionnaires q
          CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(q.definition -> 'champs') WITH ORDINALITY AS c(e, o)
          WHERE q.type_code = p_type AND q.courant
            AND pg_catalog.jsonb_typeof(c.e -> 'carte') = 'string'
            AND (c.e ->> 'carte') ~ '^[a-z][a-z0-9_]{1,59}$'
          GROUP BY c.e ->> 'carte'
        ) x), ARRAY[]::text[]) || ARRAY['cadre_religieux']::text[]
    WHEN p_etape = 'verifications' THEN
      ARRAY['piece_identite', 'cadre_religieux', 'contrat', 'avis']::text[]
    ELSE ARRAY[]::text[]
  END;
$function$;

-- Le complement en cours d'une candidature : la meme regle que
-- complementDemande d'etat_dossier() (CAND-L2A1, C12) : les codes du dernier
-- evenement de transition qui en porte, tant que l'etape n'a pas change, que
-- l'issue est en cours et qu'aucun envoi (transition 6) ne l'a suivi. Lu par
-- le compteur informationsManquantes (D15, L2-18).
CREATE FUNCTION private.candidature_complement_en_cours(c public.candidatures)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_demande public.candidature_evenements;
  v_codes jsonb := '[]'::jsonb;
BEGIN
  SELECT e.* INTO v_demande
    FROM public.candidature_evenements e
   WHERE e.candidature_id = c.id AND e.type = 'transition'
     AND pg_catalog.jsonb_typeof(e.details -> 'aCompleter') = 'array'
   ORDER BY e.cree_le DESC, e.id DESC
   LIMIT 1;
  IF v_demande.id IS NOT NULL AND c.issue = 'en_cours'
     AND c.etape IS NOT DISTINCT FROM v_demande.etape_apres
     AND NOT EXISTS (SELECT 1 FROM public.candidature_evenements e
                      WHERE e.candidature_id = c.id AND e.type = 'transition'
                        AND e.details ->> 'transition' = '6'
                        AND (e.cree_le, e.id) > (v_demande.cree_le, v_demande.id)) THEN
    SELECT coalesce(pg_catalog.jsonb_agg(a.x ORDER BY a.o), '[]'::jsonb) INTO v_codes
      FROM pg_catalog.jsonb_array_elements(v_demande.details -> 'aCompleter') WITH ORDINALITY AS a(x, o)
     WHERE pg_catalog.jsonb_typeof(a.x) = 'string' AND (a.x #>> '{}') ~ '^[a-z][a-z0-9_]{1,59}$';
  END IF;
  RETURN v_codes;
END;
$function$;

-- Le dernier questionnaire envoye (jamais un brouillon) au regard de la
-- version courante (D6) : complet, absent, perime, incomplet, ou
-- questionnaire_absent (aucune version courante pour le type).
CREATE FUNCTION private.candidature_questionnaire_envoye(c public.candidatures)
RETURNS text
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_q public.candidature_questionnaires;
  v_doc public.candidature_reponses;
  v_ex jsonb;
BEGIN
  v_q := private.questionnaire_courant(c.type_code);
  IF v_q.version IS NULL THEN
    RETURN 'questionnaire_absent';
  END IF;
  SELECT r.* INTO v_doc
    FROM public.candidature_reponses r
   WHERE r.candidature_id = c.id AND r.source = 'candidat' AND NOT r.brouillon
   ORDER BY r.soumis_le DESC, r.id DESC
   LIMIT 1;
  IF v_doc.id IS NULL THEN
    RETURN 'absent';
  END IF;
  IF v_doc.questionnaire_version IS DISTINCT FROM v_q.version THEN
    RETURN 'perime';
  END IF;
  v_ex := private.questionnaire_examiner(v_q.definition, v_doc.reponses - 'accordRemuneration' - 'operateurs');
  IF pg_catalog.jsonb_array_length(v_ex -> 'manquants') > 0
     OR pg_catalog.jsonb_array_length(v_ex -> 'invalides') > 0 THEN
    RETURN 'incomplet';
  END IF;
  RETURN 'complet';
END;
$function$;

-- Les controles d'entree d'une candidature (D6, D7) : p_pour vaut admission
-- (transition 10) ou reouverture (transition 19). Rend un tableau
-- {nom, valeur, cause} ; cause nulle quand le controle est vrai.
CREATE FUNCTION private.candidature_controles_entree(c public.candidatures, p_pour text)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_resultat jsonb := '[]'::jsonb;
  v_paiement text;
  v_cadre text;
  v_cadre_cause text;
  v_quest text;
  v_p public.profiles;
  v_role public.app_role;
  v_compte_cause text;
  v_apres_envoi boolean;
  v_salle_2 boolean;
BEGIN
  IF p_pour IS NULL OR p_pour NOT IN ('admission', 'reouverture') THEN
    RAISE EXCEPTION 'controles d''entree : admission ou reouverture' USING ERRCODE = '22023';
  END IF;
  v_salle_2 := p_pour = 'admission' OR c.etape = 'verifications';
  v_apres_envoi := p_pour = 'admission'
    OR c.etape = 'verifications'
    OR (c.etape = 'prequalification' AND c.etat IN ('en_examen', 'paiement_non_disponible'));

  IF p_pour = 'reouverture' AND c.profile_id IS NOT NULL THEN
    SELECT p.* INTO v_p FROM public.profiles p WHERE p.id = c.profile_id;
    SELECT t.role_compte INTO v_role FROM public.candidature_types t WHERE t.code = c.type_code;
    v_compte_cause := CASE
      WHEN v_p.id IS NULL OR v_p.deleted_at IS NOT NULL THEN 'supprime'
      WHEN v_p.role IS DISTINCT FROM v_role THEN 'role'
      WHEN v_p.account_status IS DISTINCT FROM 'pending_kyc'::public.account_status THEN 'statut'
      WHEN v_p.access_until IS NOT NULL AND v_p.access_until <= pg_catalog.now() THEN 'expire'
      WHEN private.candidat_engagement_en_cours(c.profile_id) THEN 'engagement'
    END;
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'compte_conforme', 'valeur', v_compte_cause IS NULL, 'cause', v_compte_cause));
  END IF;

  IF v_salle_2 THEN
    v_paiement := private.paiement_etat(c.id);
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'paiement_compatible', 'valeur', v_paiement = 'compatible',
      'cause', CASE WHEN v_paiement <> 'compatible' THEN v_paiement END));
    v_cadre := public.cadre_religieux_version_requise();
    v_cadre_cause := CASE
      WHEN v_cadre IS NULL THEN 'non_publie'
      WHEN c.profile_id IS NULL OR NOT EXISTS (
             SELECT 1 FROM public.contract_acceptances a
              WHERE a.profile_id = c.profile_id AND a.contract_kind = 'teacher_religious_framework'
                AND a.version = v_cadre) THEN 'non_accepte'
    END;
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'cadre_religieux', 'valeur', v_cadre_cause IS NULL, 'cause', v_cadre_cause));
  END IF;

  IF v_apres_envoi THEN
    v_quest := private.candidature_questionnaire_envoye(c);
    v_resultat := v_resultat || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'nom', 'questionnaire_complet', 'valeur', v_quest = 'complet',
      'cause', CASE WHEN v_quest <> 'complet' THEN v_quest END));
  END IF;
  RETURN v_resultat;
END;
$function$;

-- Les controles faux d'un tableau de controles : {nom, cause}, dans l'ordre.
CREATE FUNCTION private.candidature_controles_faux(p_controles jsonb)
RETURNS jsonb
LANGUAGE sql
IMMUTABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
  SELECT coalesce(pg_catalog.jsonb_agg(
           pg_catalog.jsonb_build_object('nom', x.e ->> 'nom', 'cause', x.e -> 'cause') ORDER BY x.o),
         '[]'::jsonb)
  FROM pg_catalog.jsonb_array_elements(coalesce(p_controles, '[]'::jsonb)) WITH ORDINALITY AS x(e, o)
  WHERE NOT coalesce((x.e ->> 'valeur')::boolean, false);
$function$;

-- Un geste groupable (D9, D12) par le moteur : refuser, mettre en pause ou
-- lever la pause. Appele par les trois RPC et par l'action groupee. Rend le
-- resultat garde sous la cle, le premier resultat rejoue, ou un refus rendu.
CREATE FUNCTION private.candidature_geste_groupe(
  p_id uuid,
  p_geste text,
  p_auteur uuid,
  p_version integer,
  p_cle text,
  p_motif text,
  p_modele text,
  p_reprise_le date,
  p_details jsonb DEFAULT '{}'::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_o jsonb;
  v_c public.candidatures;
  v_ch jsonb := '{}'::jsonb;
  v_details jsonb;
BEGIN
  IF p_geste IS NULL OR p_geste NOT IN ('refuser', 'mettre_en_pause', 'lever_pause') THEN
    RAISE EXCEPTION 'geste groupable attendu : refuser, mettre_en_pause ou lever_pause' USING ERRCODE = '22023';
  END IF;
  IF p_geste <> 'mettre_en_pause' AND p_reprise_le IS NOT NULL THEN
    RAISE EXCEPTION 'date de reprise : pour une pause seulement' USING ERRCODE = '22023';
  END IF;
  IF p_geste = 'lever_pause' AND p_modele IS NOT NULL THEN
    RAISE EXCEPTION 'lever la pause : aucun modele de message' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, p_geste, 'direction', p_auteur, p_version, p_cle,
                                          p_motif, p_modele);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  IF p_geste IN ('refuser', 'mettre_en_pause') AND NOT EXISTS (
       SELECT 1 FROM private.candidature_modeles_message m
        WHERE m.code = p_modele AND m.actif
          AND m.usage = CASE p_geste WHEN 'refuser' THEN 'refus' ELSE 'pause' END) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modele_inconnu', 'geste', p_geste);
  END IF;
  IF p_geste = 'mettre_en_pause' AND p_reprise_le IS NOT NULL
     AND (NOT pg_catalog.isfinite(p_reprise_le)
          OR p_reprise_le <= (pg_catalog.now() AT TIME ZONE 'UTC')::date) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'date_reprise_invalide');
  END IF;

  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  v_details := coalesce(p_details, '{}'::jsonb) || CASE p_geste
    WHEN 'refuser' THEN pg_catalog.jsonb_build_object(
      'entretienPlanifie', v_c.etat IS NOT DISTINCT FROM 'entretien_planifie',
      'pauseLevee', v_c.en_pause,
      'aNotifier', 'refus')
    WHEN 'mettre_en_pause' THEN pg_catalog.jsonb_build_object('aNotifier', 'pause_posee')
    ELSE pg_catalog.jsonb_build_object('aNotifier', 'pause_levee')
  END;
  IF p_geste = 'mettre_en_pause' AND p_reprise_le IS NOT NULL THEN
    v_ch := pg_catalog.jsonb_build_object('reprise_le', p_reprise_le);
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, p_geste, (v_o ->> 'variante')::smallint, 'direction',
    p_auteur, p_motif, p_modele, v_ch, v_details);
  RETURN private.candidature_geste_conclure(p_cle, p_id, p_geste, p_auteur,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- Les identifiants d'un lot qui sont de l'autre cote que le lecteur : chacun
-- laisse sa trace (evenement lecture_hors_portee et ligne d'audit, comme une
-- lecture hors portee de CAND-L1), une fois par identifiant et par appel
-- (D16). Rend ces identifiants, dans l'ordre donne, sans doublon. A appeler
-- avant tout refus RENDU : un refus leve effacerait la trace.
CREATE FUNCTION private.candidature_lot_tracer(p_ids uuid[], p_lecteur uuid, p_genre public.gender,
                                               p_geste text)
RETURNS uuid[]
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_lecture text := 'lot:' || CASE WHEN p_geste ~ '^[A-Za-z][A-Za-z_]{2,59}$' THEN p_geste ELSE 'inconnu' END;
  v_ids uuid[] := ARRAY[]::uuid[];
  v_id uuid;
BEGIN
  FOR v_id IN
    SELECT d.id
    FROM (SELECT x.id, pg_catalog.min(x.o) AS o
            FROM pg_catalog.unnest(p_ids) WITH ORDINALITY AS x(id, o)
           GROUP BY x.id) d
    JOIN public.candidatures c ON c.id = d.id
    WHERE c.genre IS DISTINCT FROM p_genre
    ORDER BY d.o
  LOOP
    PERFORM private.cand_hors_portee(v_id, p_lecteur, v_lecture);
    v_ids := v_ids || v_id;
  END LOOP;
  RETURN v_ids;
END;
$function$;

-- Examine un lot (D12), sans rien ecrire : eligibles (dans l'ordre des
-- identifiants donnes, sans doublon), exclus avec leur raison, nombre et
-- jeton. Les eligibles et les exclus du cote du lecteur portent reference,
-- nom, etape, etat, issue, pause ; un exclu hors portee ou absent ne porte
-- que son identifiant. Le jeton est une empreinte HMAC-SHA256 sous la cle du
-- serveur (D17), tronquee a 32 signes : un client ne peut pas le calculer.
CREATE FUNCTION private.candidature_lot_examiner(p_geste text, p_ids uuid[], p_auteur uuid,
                                                 p_genre public.gender)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_i record;
  v_c public.candidatures;
  v_r private.candidature_gestes_regles;
  v_lignes jsonb := '[]'::jsonb;
  v_ligne jsonb;
  v_part_e text[] := ARRAY[]::text[];
  v_part_x text[] := ARRAY[]::text[];
  v_n integer := 0;
  v_secret text;
  v_message text;
BEGIN
  SELECT s.secret INTO v_secret FROM private.candidature_lot_secret s;
  IF v_secret IS NULL OR pg_catalog.length(v_secret) < 64 THEN
    RAISE EXCEPTION 'CAND-L2A2 : cle des jetons de lot absente' USING ERRCODE = 'P0001';
  END IF;
  FOR v_i IN
    SELECT x.id, pg_catalog.min(x.o) AS o
    FROM pg_catalog.unnest(p_ids) WITH ORDINALITY AS x(id, o)
    GROUP BY x.id
    ORDER BY 2
  LOOP
    SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = v_i.id;
    IF v_c.id IS NULL THEN
      v_ligne := pg_catalog.jsonb_build_object('id', v_i.id, 'eligible', false, 'raison', 'absente');
      v_part_x := v_part_x || (v_i.id::text || ':absente');
    ELSIF v_c.genre IS DISTINCT FROM p_genre THEN
      v_ligne := pg_catalog.jsonb_build_object('id', v_i.id, 'eligible', false, 'raison', 'hors_portee');
      v_part_x := v_part_x || (v_i.id::text || ':hors_portee');
    ELSE
      v_r := private.candidature_regle(v_c, p_geste, 'direction', NULL::smallint, false);
      v_ligne := pg_catalog.jsonb_build_object(
        'id', v_c.id, 'reference', v_c.reference, 'nomComplet', v_c.nom_complet,
        'etape', v_c.etape, 'etat', v_c.etat, 'issue', v_c.issue, 'enPause', v_c.en_pause,
        'version', v_c.version);
      IF v_r.geste IS NULL THEN
        v_ligne := v_ligne || pg_catalog.jsonb_build_object(
          'eligible', false, 'raison', 'transition_interdite',
          'detail', CASE WHEN (private.candidature_regle(v_c, p_geste, 'direction', NULL::smallint, true)).geste
                              IS NOT NULL THEN 'pause' ELSE 'etat' END);
        v_part_x := v_part_x || (v_c.id::text || ':transition_interdite:' || (v_ligne ->> 'detail'));
      ELSE
        v_ligne := v_ligne || pg_catalog.jsonb_build_object('eligible', true);
        v_part_e := v_part_e || (v_c.id::text || ':' || v_c.version::text);
        v_n := v_n + 1;
      END IF;
    END IF;
    v_lignes := v_lignes || pg_catalog.jsonb_build_array(v_ligne);
  END LOOP;
  v_message := coalesce(p_auteur::text, '') || '|' || p_geste || '|'
    || pg_catalog.array_to_string(ARRAY(SELECT e FROM pg_catalog.unnest(v_part_e) AS e ORDER BY e), ',')
    || '|'
    || pg_catalog.array_to_string(ARRAY(SELECT e FROM pg_catalog.unnest(v_part_x) AS e ORDER BY e), ',');
  RETURN pg_catalog.jsonb_build_object(
    'lignes', v_lignes,
    'nombre', v_n,
    'jeton', pg_catalog.substr(pg_catalog.encode(
      extensions.hmac(pg_catalog.convert_to(v_message, 'UTF8'), pg_catalog.convert_to(v_secret, 'UTF8'), 'sha256'),
      'hex'), 1, 32));
END;
$function$;

-- private.paiement_recalculer : corps de 20261021220100_cand_l6_referentiel_paiement.sql
-- recopie (causes, calcul en direct, transitions 8, 9 et 20, evenements,
-- audit des effets) ; ajouts de D19 : la cause reouverture (appelee par
-- rouvrir_candidat) applique la transition 9 a une candidature rouverte en
-- paiement_non_disponible dont le paiement n'est plus incompatible, et la
-- transition 9 nomme l'element versement (la carte de la liste fermee de D5),
-- non plus moyen_paiement. Rien d'autre ne change.
CREATE OR REPLACE FUNCTION private.paiement_recalculer(
  p_candidature uuid,
  p_cause text,
  p_auteur uuid DEFAULT NULL,
  p_motif text DEFAULT NULL,
  p_ligne uuid DEFAULT NULL,
  p_ligne_confirmee boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_c public.candidatures;
  v_avant text;
  v_apres text;
  v_effet text := 'aucun';
  v_cause jsonb;
  v_motif text := nullif(pg_catalog.btrim(p_motif), '');
BEGIN
  IF p_cause IS NULL OR p_cause NOT IN ('referentiel', 'reponses', 'moyen_confirme', 'moyen_infirme', 'reouverture') THEN
    RAISE EXCEPTION 'CAND-L6 : cause de recalcul inconnue' USING ERRCODE = '22023';
  END IF;
  IF p_cause = 'moyen_infirme' AND (v_motif IS NULL OR p_auteur IS NULL) THEN
    RAISE EXCEPTION 'CAND-L6 : un moyen infirme exige un auteur et un motif' USING ERRCODE = '22023';
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_candidature FOR UPDATE;
  IF v_c.id IS NULL THEN
    RAISE EXCEPTION 'CAND-L6 : candidature inconnue' USING ERRCODE = '22023';
  END IF;
  IF v_c.issue <> 'en_cours' OR v_c.profile_id IS NULL
     OR v_c.etape NOT IN ('prequalification', 'verifications', 'confirmee') THEN
    RETURN pg_catalog.jsonb_build_object('candidature', v_c.id, 'effet', 'aucun',
      'paiementAvant', v_c.paiement, 'paiementApres', v_c.paiement);
  END IF;

  v_avant := v_c.paiement;
  v_apres := private.paiement_etat(v_c.id);
  v_cause := pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
    'cause', p_cause, 'ligne', p_ligne, 'paiementAvant', v_avant, 'paiementApres', v_apres));

  IF v_apres IS DISTINCT FROM v_avant THEN
    INSERT INTO public.candidature_evenements (candidature_id, type, auteur_id, details)
    VALUES (v_c.id, 'controle', p_auteur, v_cause || pg_catalog.jsonb_build_object(
      'controle', 'paiement_compatible',
      'valeurAvant', v_avant = 'compatible',
      'valeurApres', v_apres = 'compatible'));
  END IF;

  IF v_c.etape = 'prequalification' AND v_c.etat = 'paiement_non_disponible'
     AND ((p_cause = 'referentiel' AND p_ligne_confirmee)
          OR (p_cause = 'reouverture' AND v_apres <> 'incompatible')) THEN
    -- Transition 9 : une ligne du pays passe confirme (a l'instant, ou
    -- pendant que la candidature etait refusee ou retiree : reouverture).
    UPDATE public.candidatures
       SET etat = 'a_completer', paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, auteur_id, details)
    VALUES (v_c.id, 'transition', 'prequalification', 'prequalification',
            'paiement_non_disponible', 'a_completer', NULL,
            v_cause || pg_catalog.jsonb_build_object('transition', 9,
              'aCompleter', pg_catalog.jsonb_build_array('versement'),
              'aNotifier', 'paiement_possible'));
    v_effet := 'a_completer';
  ELSIF v_c.etape = 'prequalification' AND v_c.etat = 'en_examen' AND v_apres = 'incompatible' THEN
    -- Transition 8 : aucun moyen ne croise une ligne confirme, moyen infirme ou
    -- ligne qui quitte confirme ; la cause et le motif eventuel sont traces.
    UPDATE public.candidatures
       SET etat = 'paiement_non_disponible', paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, etat_avant, etat_apres, auteur_id,
       motif_interne, details)
    VALUES (v_c.id, 'transition', 'prequalification', 'prequalification',
            'en_examen', 'paiement_non_disponible', p_auteur, v_motif,
            v_cause || pg_catalog.jsonb_build_object('transition', 8));
    v_effet := 'paiement_non_disponible';
  ELSIF v_c.etape = 'confirmee' AND v_apres <> 'compatible' AND NOT v_c.restreinte THEN
    -- Transition 20, automatique : restriction cause paiement, etape gardee.
    -- Le calcul en direct seul decide, jamais la colonne paiement : une
    -- personne en salle 3 est toujours compatible ou restreinte (R5, R13).
    UPDATE public.candidatures
       SET restreinte = true, restriction_cause = 'paiement', paiement = v_apres,
           version = version + 1
     WHERE id = v_c.id;
    INSERT INTO public.candidature_evenements
      (candidature_id, type, etape_avant, etape_apres, auteur_id, motif_interne, details)
    VALUES (v_c.id, 'restriction', 'confirmee', 'confirmee', p_auteur,
            'Paiement à revérifier : aucun moyen confirmé ne croise plus une ligne confirmée du pays de versement.',
            v_cause || pg_catalog.jsonb_build_object('transition', 20, 'restrictionCause', 'paiement'));
    v_effet := 'restriction';
  ELSIF v_apres IS DISTINCT FROM v_avant THEN
    UPDATE public.candidatures
       SET paiement = v_apres, version = version + 1
     WHERE id = v_c.id;
    -- Salle 2 : le controle tombe, sauf si la colonne le disait deja faux.
    v_effet := CASE
      WHEN v_c.etape = 'verifications' AND v_apres <> 'compatible'
           AND v_avant IN ('compatible', 'inconnu') THEN 'bloquee'
      WHEN v_c.etape = 'confirmee' AND v_apres <> 'compatible' THEN 'deja_restreinte'
      ELSE 'paiement' END;
  END IF;

  IF v_effet IN ('a_completer', 'paiement_non_disponible', 'restriction') THEN
    PERFORM public.log_sensitive_access('candidature_effet_paiement', 'candidatures', v_c.id::text,
      v_cause || pg_catalog.jsonb_build_object('effet', v_effet));
  END IF;

  RETURN pg_catalog.jsonb_build_object('candidature', v_c.id, 'effet', v_effet,
    'paiementAvant', v_avant, 'paiementApres', v_apres);
END;
$function$;

-- ============================================================
-- 3. RPC des gestes de la direction
-- ============================================================

-- demanderComplement : transition 7 (Salle d'examen, en_examen vers
-- a_completer) ou 23 (Salle de verification et d'entretien, meme etat) ;
-- elements nommes dans la liste fermee de la salle (D5), motif exige. En
-- salle 2 seulement, le code complement_clos, seul, cloture le complement en
-- cours (D20) : meme transition 23, evenement a liste vide, aucun marqueur
-- aNotifier.
CREATE FUNCTION public.demander_complement_candidat(
  p_id uuid,
  p_elements text[],
  p_motif text,
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
  v_codes text[];
  v_elements text[];
  v_invalides text[];
  v_cloture boolean;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_elements IS NULL OR pg_catalog.cardinality(p_elements) > 20
     OR pg_catalog.array_position(p_elements, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'elements attendus : un tableau de 20 codes au plus, sans valeur nulle' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'demander_complement', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  SELECT coalesce(pg_catalog.array_agg(x.e ORDER BY x.o), ARRAY[]::text[]) INTO v_elements
    FROM (SELECT e.e, pg_catalog.min(e.o) AS o
            FROM pg_catalog.unnest(p_elements) WITH ORDINALITY AS e(e, o) GROUP BY e.e) x;
  IF pg_catalog.cardinality(v_elements) = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'elements_requis');
  END IF;
  -- La cloture (D20) : le seul code complement_clos, en salle 2 (variante 2 de
  -- la regle, transition 23), quand un complement court.
  v_cloture := v_elements = ARRAY['complement_clos']::text[] AND (v_o ->> 'variante')::smallint = 2;
  IF v_cloture THEN
    IF pg_catalog.jsonb_array_length(private.candidature_complement_en_cours(v_c)) = 0 THEN
      RETURN pg_catalog.jsonb_build_object('erreur', 'aucun_complement');
    END IF;
    PERFORM private.candidature_geste_appliquer(p_id, 'demander_complement', (v_o ->> 'variante')::smallint,
      'direction', v_uid, p_motif, NULL, '{}'::jsonb,
      pg_catalog.jsonb_build_object('aCompleter', '[]'::jsonb, 'cloture', true));
    RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'demander_complement', v_uid,
      pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                    'aCompleter', '[]'::jsonb));
  END IF;
  v_codes := private.candidature_complement_codes(v_c.etape, v_c.type_code);
  SELECT pg_catalog.array_agg(CASE WHEN e ~ '^[a-z][a-z0-9_]{1,59}$' THEN e ELSE '?' END ORDER BY e)
    INTO v_invalides
    FROM pg_catalog.unnest(v_elements) AS e
   WHERE NOT (e = ANY (v_codes));
  IF v_invalides IS NOT NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'elements_invalides', 'elements', pg_catalog.to_jsonb(v_invalides),
                                         'permis', pg_catalog.to_jsonb(v_codes));
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'demander_complement', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('aCompleter', pg_catalog.to_jsonb(v_elements), 'aNotifier', 'complement_demande'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'demander_complement', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'aCompleter', pg_catalog.to_jsonb(v_elements)));
END;
$function$;

-- admettreVerifications : transition 10 (en_examen vers Salle de
-- verification et d'entretien, entretien_a_planifier), sous les trois
-- controles de D6, sinon controles_non_satisfaits nommes.
CREATE FUNCTION public.admettre_salle_verification(
  p_id uuid,
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
  v_controles jsonb;
  v_faux jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'admettre_verifications', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  v_controles := private.candidature_controles_entree(v_c, 'admission');
  v_faux := private.candidature_controles_faux(v_controles);
  IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits', 'controles', v_faux);
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'admettre_verifications', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('controles', v_controles, 'aNotifier', 'admis_salle_verification'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'admettre_verifications', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- refuser : transition 16, motif interne et modele de message de la liste
-- fermee (D4) ; la pause est levee avec l'issue terminale (C5 de CAND-L2A1).
CREATE FUNCTION public.refuser_candidat(
  p_id uuid,
  p_motif text,
  p_modele text,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.candidature_geste_groupe(p_id, 'refuser', auth.uid(), p_version_attendue, p_cle_idempotence,
                                          p_motif, p_modele, NULL);
END;
$function$;

-- mettreEnPause : transition 18 a la pose, motif et modele (D4), reprise
-- facultative posterieure au jour courant (D9).
CREATE FUNCTION public.mettre_en_pause_candidat(
  p_id uuid,
  p_motif text,
  p_modele text,
  p_reprise_le date,
  p_version_attendue integer,
  p_cle_idempotence text
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.candidature_geste_groupe(p_id, 'mettre_en_pause', auth.uid(), p_version_attendue,
                                          p_cle_idempotence, p_motif, p_modele, p_reprise_le);
END;
$function$;

-- leverPause : transition 18 a la levee ; motif facultatif, aucun modele.
CREATE FUNCTION public.lever_pause_candidat(
  p_id uuid,
  p_version_attendue integer,
  p_cle_idempotence text,
  p_motif text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  RETURN private.candidature_geste_groupe(p_id, 'lever_pause', auth.uid(), p_version_attendue,
                                          p_cle_idempotence, p_motif, NULL, NULL);
END;
$function$;

-- consignerRetrait : transition 17 par la direction, pour une demande recue
-- par la conversation ou par courriel (D8) : canal, date de la demande,
-- motif ; la pause est levee avec l'issue terminale.
CREATE FUNCTION public.consigner_retrait_candidat(
  p_id uuid,
  p_canal text,
  p_demande_recue_le date,
  p_motif text,
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
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_canal IS NULL OR p_canal NOT IN ('conversation', 'courriel') OR p_demande_recue_le IS NULL THEN
    RAISE EXCEPTION 'retrait : canal (conversation ou courriel) et date de la demande attendus' USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'retirer', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF NOT pg_catalog.isfinite(p_demande_recue_le)
     OR p_demande_recue_le > (pg_catalog.now() AT TIME ZONE 'UTC')::date
     OR p_demande_recue_le < (v_c.recue_le AT TIME ZONE 'UTC')::date THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'date_demande_invalide');
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'retirer', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object(
      'canal', p_canal,
      'demandeRecueLe', pg_catalog.to_char(p_demande_recue_le, 'YYYY-MM-DD'),
      'entretienPlanifie', v_c.etat IS NOT DISTINCT FROM 'entretien_planifie',
      'pauseLevee', v_c.en_pause,
      'aNotifier', 'retrait_enregistre'));
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'retirer', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- rouvrir : transition 19 (refusee ou retiree vers l'etape et l'etat
-- d'origine, gardes), sous les controles de D7, sinon controles_non_satisfaits
-- nommes ; puis le paiement est recalcule (la transition 8 peut suivre).
CREATE FUNCTION public.rouvrir_candidat(
  p_id uuid,
  p_motif text,
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
  v_controles jsonb;
  v_faux jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'rouvrir', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  v_controles := private.candidature_controles_entree(v_c, 'reouverture');
  v_faux := private.candidature_controles_faux(v_controles);
  IF pg_catalog.jsonb_array_length(v_faux) > 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'controles_non_satisfaits', 'controles', v_faux);
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'rouvrir', (v_o ->> 'variante')::smallint,
    'direction', v_uid, p_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_build_object('issueAvant', v_c.issue, 'refusModeleAvant', v_c.issue_modele,
                                  'controles', v_controles));
  PERFORM private.paiement_recalculer(p_id, 'reouverture');
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'rouvrir', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- definirResponsable : transition 28, un membre actif de la direction du meme
-- cote que la candidature, ou aucun (D10).
CREATE FUNCTION public.definir_responsable_candidat(
  p_id uuid,
  p_responsable_id uuid,
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
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'definir_responsable', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  SELECT c.* INTO v_c FROM public.candidatures c WHERE c.id = p_id;
  IF p_responsable_id IS NOT NULL AND NOT EXISTS (
       SELECT 1 FROM public.profiles p
        WHERE p.id = p_responsable_id
          AND p.role = 'admin'::public.app_role
          AND p.deleted_at IS NULL
          AND p.account_status = 'active'::public.account_status
          AND p.gender IS NOT DISTINCT FROM v_c.genre) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'responsable_invalide');
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'definir_responsable', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, NULL, pg_catalog.jsonb_build_object('responsable_id', p_responsable_id), '{}'::jsonb);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'definir_responsable', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id)));
END;
$function$;

-- confirmerMoyenPaiement : transition 24 (D11), en Salle d'examen
-- (en_examen, paiement a_verifier) ou en salle 3 sous restriction de cause
-- paiement ; le moyen nomme est declare et croise une ligne confirme du pays
-- de versement, sinon moyen_non_confirmable avec sa cause.
CREATE FUNCTION public.confirmer_moyen_paiement_candidat(
  p_id uuid,
  p_methode text,
  p_operateur text,
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
  v_decl jsonb;
  v_pays text;
  v_ligne text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_methode IS NULL OR p_methode NOT IN ('virement_bancaire', 'mobile_money')
     OR (p_methode = 'virement_bancaire') <> (p_operateur IS NULL)
     OR (p_operateur IS NOT NULL AND p_operateur !~ '^[a-z][a-z0-9_]{1,39}$') THEN
    RAISE EXCEPTION 'moyen attendu : virement_bancaire sans operateur, ou mobile_money et son operateur'
      USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'confirmer_moyen_paiement', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  v_decl := private.paiement_declaration(p_id);
  v_pays := v_decl ->> 'paysVersement';
  IF v_decl IS NULL
     OR NOT ((p_methode = 'virement_bancaire' AND coalesce((v_decl ->> 'compteBancaire')::boolean, false))
             OR (p_methode = 'mobile_money' AND coalesce((v_decl -> 'operateurs') ? p_operateur, false))) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'moyen_non_confirmable', 'cause', 'non_declare');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.referentiel_paiement l
                  WHERE l.pays = v_pays AND l.etat = 'confirme' AND l.methode = p_methode
                    AND (p_methode = 'virement_bancaire' OR l.operateur = p_operateur)) THEN
    SELECT pg_catalog.string_agg(DISTINCT l.etat, ',' ORDER BY l.etat) INTO v_ligne
      FROM public.referentiel_paiement l
     WHERE l.pays = v_pays AND l.methode = p_methode
       AND (p_methode = 'virement_bancaire' OR l.operateur = p_operateur);
    RETURN pg_catalog.jsonb_build_object('erreur', 'moyen_non_confirmable', 'cause', 'ligne_non_confirmee',
                                         'etatLigne', v_ligne);
  END IF;
  -- Le geste d'abord : sa regle lit la dimension paiement en direct (D11).
  PERFORM private.candidature_geste_appliquer(p_id, 'confirmer_moyen_paiement', (v_o ->> 'variante')::smallint,
    'direction', v_uid, NULL, NULL, '{}'::jsonb,
    pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
      'decision', 'confirme', 'pays', v_pays, 'methode', p_methode, 'operateur', p_operateur)));
  INSERT INTO public.candidature_paiement_decisions (candidature_id, pays, methode, operateur, decision, auteur_id)
  VALUES (p_id, v_pays, p_methode, p_operateur, 'confirme', v_uid);
  PERFORM private.paiement_recalculer(p_id, 'moyen_confirme', v_uid);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'confirmer_moyen_paiement', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'paiement', private.paiement_etat(p_id)));
END;
$function$;

-- infirmerMoyenPaiement : transition 25 (D11), en Salle d'examen, paiement
-- a_verifier ou compatible ; moyen declare et nomme, motif exige ; la
-- transition 8 suit si plus aucun moyen ne tient.
CREATE FUNCTION public.infirmer_moyen_paiement_candidat(
  p_id uuid,
  p_methode text,
  p_operateur text,
  p_motif text,
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
  v_decl jsonb;
  v_pays text;
  v_motif text := private.candidature_motif(p_motif);
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  IF p_methode IS NULL OR p_methode NOT IN ('virement_bancaire', 'mobile_money')
     OR (p_methode = 'virement_bancaire') <> (p_operateur IS NULL)
     OR (p_operateur IS NOT NULL AND p_operateur !~ '^[a-z][a-z0-9_]{1,39}$') THEN
    RAISE EXCEPTION 'moyen attendu : virement_bancaire sans operateur, ou mobile_money et son operateur'
      USING ERRCODE = '22023';
  END IF;
  v_o := private.candidature_geste_ouvrir(p_id, 'infirmer_moyen_paiement', 'direction', v_uid,
                                          p_version_attendue, p_cle_idempotence, p_motif);
  IF v_o ? 'rejoue' THEN
    RETURN v_o -> 'rejoue';
  ELSIF v_o ? 'erreur' THEN
    RETURN v_o;
  END IF;
  v_decl := private.paiement_declaration(p_id);
  v_pays := v_decl ->> 'paysVersement';
  IF v_decl IS NULL
     OR NOT ((p_methode = 'virement_bancaire' AND coalesce((v_decl ->> 'compteBancaire')::boolean, false))
             OR (p_methode = 'mobile_money' AND coalesce((v_decl -> 'operateurs') ? p_operateur, false))) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'moyen_non_declare');
  END IF;
  PERFORM private.candidature_geste_appliquer(p_id, 'infirmer_moyen_paiement', (v_o ->> 'variante')::smallint,
    'direction', v_uid, v_motif, NULL, '{}'::jsonb,
    pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
      'decision', 'infirme', 'pays', v_pays, 'methode', p_methode, 'operateur', p_operateur)));
  INSERT INTO public.candidature_paiement_decisions
    (candidature_id, pays, methode, operateur, decision, motif_interne, auteur_id)
  VALUES (p_id, v_pays, p_methode, p_operateur, 'infirme', v_motif, v_uid);
  PERFORM private.paiement_recalculer(p_id, 'moyen_infirme', v_uid, v_motif);
  RETURN private.candidature_geste_conclure(p_cle_idempotence, p_id, 'infirmer_moyen_paiement', v_uid,
    pg_catalog.jsonb_build_object('candidature', private.candidature_etat_direction(p_id),
                                  'paiement', private.paiement_etat(p_id)));
END;
$function$;

-- ============================================================
-- 4. Action groupee (ADM-22, D12)
-- ============================================================

-- preparerLot : les eligibles, les exclus et leur raison, l'effet, le nombre
-- et le jeton. Rien n'est ecrit, sauf la trace de chaque candidature hors
-- portee (comme une lecture hors portee de CAND-L1, D16, y compris pour un
-- geste non groupable) et la ligne d'audit de la lecture (le nom des
-- eligibles sort, comme d'une liste). Le geste s'ecrit avec le code du moteur
-- ou celui de gestesGroupables (D18).
CREATE FUNCTION public.apercu_lot_candidats(p_geste text, p_ids uuid[])
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_lecteur uuid;
  v_genre public.gender;
  v_geste text;
  v_hors uuid[];
  v_ex jsonb;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre INTO v_lecteur, v_genre FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun geste tant qu''il n''est pas renseigne' USING ERRCODE = '42501';
  END IF;
  IF p_geste IS NULL OR p_ids IS NULL OR pg_catalog.cardinality(p_ids) NOT BETWEEN 1 AND 200
     OR pg_catalog.array_position(p_ids, NULL) IS NOT NULL THEN
    RAISE EXCEPTION 'lot attendu : un geste et de 1 a 200 candidatures, sans valeur nulle' USING ERRCODE = '22023';
  END IF;
  v_geste := CASE p_geste WHEN 'mettreEnPause' THEN 'mettre_en_pause' WHEN 'leverPause' THEN 'lever_pause'
                          ELSE p_geste END;
  -- La trace d'abord : aucun refus rendu ne la precede (D16).
  v_hors := private.candidature_lot_tracer(p_ids, v_lecteur, v_genre, p_geste);
  IF v_geste NOT IN ('mettre_en_pause', 'lever_pause', 'refuser') THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'geste_non_groupable',
      'geste', CASE WHEN p_geste ~ '^[A-Za-z][A-Za-z_]{2,59}$' THEN p_geste END);
  END IF;
  v_ex := private.candidature_lot_examiner(v_geste, p_ids, v_lecteur, v_genre);
  PERFORM public.log_sensitive_access('candidatures_apercu_lot', 'candidatures', NULL,
    pg_catalog.jsonb_build_object(
      'reader_gender', v_genre,
      'geste', v_geste,
      'nombre', (v_ex ->> 'nombre')::integer,
      'exclus', (SELECT pg_catalog.count(*) FROM pg_catalog.jsonb_array_elements(v_ex -> 'lignes') e
                  WHERE NOT (e ->> 'eligible')::boolean),
      'hors_portee', pg_catalog.cardinality(v_hors)));
  RETURN pg_catalog.jsonb_build_object(
    'geste', v_geste,
    'effet', (SELECT r.cible FROM private.candidature_gestes_regles r WHERE r.geste = v_geste AND r.variante = 1),
    'motifRequis', v_geste IN ('mettre_en_pause', 'refuser'),
    'modeleRequis', v_geste IN ('mettre_en_pause', 'refuser'),
    'eligibles', (SELECT coalesce(pg_catalog.jsonb_agg(e - 'eligible'), '[]'::jsonb)
                    FROM pg_catalog.jsonb_array_elements(v_ex -> 'lignes') AS e
                   WHERE (e ->> 'eligible')::boolean),
    'exclus', (SELECT coalesce(pg_catalog.jsonb_agg(e - 'eligible' - 'version'), '[]'::jsonb)
                 FROM pg_catalog.jsonb_array_elements(v_ex -> 'lignes') AS e
                WHERE NOT (e ->> 'eligible')::boolean),
    'nombre', v_ex -> 'nombre',
    'jeton', v_ex ->> 'jeton');
END;
$function$;

-- executerLot : les memes identifiants, le jeton de l'apercu, le nombre saisi,
-- le motif et le modele communs, la cle du lot. Rapport ligne par ligne,
-- garde sous la cle (D12). Ordre : gardes et forme des arguments (leves),
-- trace des identifiants de l'autre cote (D16), puis seulement les refus
-- rendus (geste non groupable, rejeu, motif, modele, date, jeton, nombre).
CREATE FUNCTION public.executer_lot_candidats(
  p_geste text,
  p_ids uuid[],
  p_jeton text,
  p_nombre_confirme integer,
  p_cle_idempotence text,
  p_motif text DEFAULT NULL,
  p_modele text DEFAULT NULL,
  p_reprise_le date DEFAULT NULL
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
  v_genre public.gender;
  v_geste text;
  v_groupable boolean;
  v_hors uuid[];
  v_empreinte text;
  v_lot public.candidature_lots;
  v_motif text := private.candidature_motif(p_motif);
  v_ex jsonb;
  v_l jsonb;
  v_r jsonb;
  v_lignes jsonb := '[]'::jsonb;
  v_reussies integer := 0;
  v_exclues integer := 0;
  v_refusees integer := 0;
  v_resultat jsonb;
  v_base_cle text;
BEGIN
  IF NOT coalesce(public.app_role() = 'admin' AND public.app_account_valid(), false) THEN
    RAISE EXCEPTION 'gestes des candidatures reserves a la direction active' USING ERRCODE = '42501';
  END IF;
  SELECT l.profile_id, l.genre INTO v_lecteur, v_genre FROM private.cand_lecteur() l;
  IF v_lecteur IS NULL OR v_genre IS NULL THEN
    RAISE EXCEPTION 'genre du lecteur inconnu : aucun geste tant qu''il n''est pas renseigne' USING ERRCODE = '42501';
  END IF;
  IF p_geste IS NULL OR p_ids IS NULL OR pg_catalog.cardinality(p_ids) NOT BETWEEN 1 AND 200
     OR pg_catalog.array_position(p_ids, NULL) IS NOT NULL
     OR p_jeton IS NULL OR p_jeton !~ '^[0-9a-f]{32}$'
     OR p_nombre_confirme IS NULL OR p_nombre_confirme < 0
     OR p_cle_idempotence IS NULL OR pg_catalog.length(p_cle_idempotence) NOT BETWEEN 8 AND 200
     OR (p_modele IS NOT NULL AND p_modele !~ '^[a-z][a-z0-9_]{1,59}$')
     OR pg_catalog.length(v_motif) > 2000 THEN
    RAISE EXCEPTION 'lot attendu : geste, 1 a 200 candidatures, jeton, nombre confirme, cle (8 a 200 signes), modele et motif valides'
      USING ERRCODE = '22023';
  END IF;
  v_geste := CASE p_geste WHEN 'mettreEnPause' THEN 'mettre_en_pause' WHEN 'leverPause' THEN 'lever_pause'
                          ELSE p_geste END;
  v_groupable := v_geste IN ('mettre_en_pause', 'lever_pause', 'refuser');
  IF v_groupable AND ((v_geste <> 'mettre_en_pause' AND p_reprise_le IS NOT NULL)
                      OR (v_geste = 'lever_pause' AND p_modele IS NOT NULL)) THEN
    RAISE EXCEPTION 'lot : modele ou date de reprise invalide pour ce geste' USING ERRCODE = '22023';
  END IF;

  -- La trace d'abord : aucun refus rendu ne la precede (D16).
  v_hors := private.candidature_lot_tracer(p_ids, v_lecteur, v_genre, p_geste);
  IF NOT v_groupable THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'geste_non_groupable',
      'geste', CASE WHEN p_geste ~ '^[A-Za-z][A-Za-z_]{2,59}$' THEN p_geste END);
  END IF;

  -- La cle du lot : une demande, un auteur ; rejouee, le premier rapport, sauf
  -- si un identifiant du rapport est desormais de l'autre cote (le moteur
  -- verifie la portee avant le rejeu, D16).
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('candidature_lot:' || p_cle_idempotence, 0));
  v_empreinte := pg_catalog.md5(v_geste || '|' || pg_catalog.array_to_string(
    ARRAY(SELECT DISTINCT x::text FROM pg_catalog.unnest(p_ids) AS x ORDER BY 1), ','));
  SELECT l.* INTO v_lot FROM public.candidature_lots l WHERE l.cle = p_cle_idempotence;
  IF v_lot.cle IS NOT NULL THEN
    IF v_lot.auteur_id = v_uid AND v_lot.geste = v_geste AND v_lot.empreinte = v_empreinte THEN
      IF EXISTS (SELECT 1 FROM pg_catalog.jsonb_array_elements(v_lot.resultat -> 'lignes') l
                  WHERE (l ->> 'id')::uuid = ANY (v_hors)
                    AND NOT coalesce(l ->> 'issue' = 'exclue' AND l ->> 'raison' = 'hors_portee', false)) THEN
        RETURN pg_catalog.jsonb_build_object('erreur', 'hors_portee');
      END IF;
      RETURN v_lot.resultat || '{"rejoue": true}'::jsonb;
    END IF;
    RETURN pg_catalog.jsonb_build_object('erreur', 'cle_idempotence_reutilisee');
  END IF;

  -- Ce que le lot exige une fois pour toutes ses lignes.
  IF v_geste IN ('mettre_en_pause', 'refuser') AND v_motif IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'motif_requis', 'geste', v_geste);
  END IF;
  IF v_geste IN ('mettre_en_pause', 'refuser') AND p_modele IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modele_requis', 'geste', v_geste);
  END IF;
  IF v_geste IN ('mettre_en_pause', 'refuser') AND NOT EXISTS (
       SELECT 1 FROM private.candidature_modeles_message m
        WHERE m.code = p_modele AND m.actif
          AND m.usage = CASE v_geste WHEN 'refuser' THEN 'refus' ELSE 'pause' END) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'modele_inconnu', 'geste', v_geste);
  END IF;
  IF v_geste = 'mettre_en_pause' AND p_reprise_le IS NOT NULL
     AND (NOT pg_catalog.isfinite(p_reprise_le)
          OR p_reprise_le <= (pg_catalog.now() AT TIME ZONE 'UTC')::date) THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'date_reprise_invalide');
  END IF;

  -- Le lot n'a pas change depuis l'apercu, et la direction a saisi son
  -- nombre ; sinon rien n'est ecrit.
  v_ex := private.candidature_lot_examiner(v_geste, p_ids, v_lecteur, v_genre);
  IF v_ex ->> 'jeton' IS DISTINCT FROM p_jeton THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'jeton_perime');
  END IF;
  IF (v_ex ->> 'nombre')::integer = 0 THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'aucun_eligible');
  END IF;
  IF (v_ex ->> 'nombre')::integer <> p_nombre_confirme THEN
    RETURN pg_catalog.jsonb_build_object('erreur', 'nombre_discordant', 'nombre', (v_ex ->> 'nombre')::integer);
  END IF;

  -- Chaque ligne seule, sous une cle derivee de celle du lot. Les lignes de
  -- l'autre cote ont deja laisse leur trace.
  v_base_cle := 'lot-' || pg_catalog.md5(p_cle_idempotence) || '-';
  FOR v_l IN SELECT e FROM pg_catalog.jsonb_array_elements(v_ex -> 'lignes') WITH ORDINALITY AS x(e, o) ORDER BY x.o LOOP
    IF NOT (v_l ->> 'eligible')::boolean THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_strip_nulls(pg_catalog.jsonb_build_object(
        'id', v_l -> 'id', 'reference', v_l -> 'reference', 'issue', 'exclue',
        'raison', v_l ->> 'raison', 'detail', v_l ->> 'detail')));
      v_exclues := v_exclues + 1;
      CONTINUE;
    END IF;
    BEGIN
      v_r := private.candidature_geste_groupe((v_l ->> 'id')::uuid, v_geste, v_uid, (v_l ->> 'version')::integer,
        v_base_cle || (v_l ->> 'id'), v_motif, p_modele, p_reprise_le,
        pg_catalog.jsonb_build_object('lot', pg_catalog.md5(p_cle_idempotence)));
      IF v_r ? 'erreur' THEN
        v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'id', v_l -> 'id', 'reference', v_l -> 'reference', 'issue', 'refusee', 'raison', v_r ->> 'erreur'));
        v_refusees := v_refusees + 1;
      ELSE
        v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
          'id', v_l -> 'id', 'reference', v_l -> 'reference', 'issue', 'reussie',
          'candidature', v_r -> 'candidature'));
        v_reussies := v_reussies + 1;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      v_lignes := v_lignes || pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
        'id', v_l -> 'id', 'reference', v_l -> 'reference', 'issue', 'refusee', 'raison', 'erreur_serveur',
        'code', SQLSTATE));
      v_refusees := v_refusees + 1;
    END;
  END LOOP;

  v_resultat := pg_catalog.jsonb_build_object(
    'geste', v_geste,
    'nombre', (v_ex ->> 'nombre')::integer,
    'reussies', v_reussies,
    'exclues', v_exclues,
    'refusees', v_refusees,
    'lignes', v_lignes);
  INSERT INTO public.candidature_lots (cle, auteur_id, geste, empreinte, jeton, resultat)
  VALUES (p_cle_idempotence, v_uid, v_geste, v_empreinte, p_jeton, v_resultat);
  RETURN v_resultat || '{"rejoue": false}'::jsonb;
END;
$function$;

-- ============================================================
-- 5. Lectures de CAND-L1 redefinies
-- ============================================================

-- capacites_candidatures : corps de 20261021200000_cand_l1_socle_candidatures.sql
-- recopie (garde, lecteur, contact, exception) ; ajouts de D13 : peutDecider,
-- une capacite par geste (vraie pour ceux que le serveur sait faire),
-- peutEcrireReferentiel lu dans private.paiement_gestionnaire(), listes
-- fermees du lot. peutImporter, peutMenerEntretien et
-- doubleVerificationRequise restent faux (L3, L4).
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
  RETURN pg_catalog.jsonb_build_object(
    'peutLire', v_lire,
    'peutVoirContact', v_lire AND coalesce(v_contact, false),
    'peutLireHorsGenre', v_super,
    'genreLecteurConnu', v_admin AND v_genre IS NOT NULL,
    'peutDecider', v_decider,
    'peutImporter', false,
    'doubleVerificationRequise', false,
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
      'consignerPrevenu', false,
      'garderPourSuivi', false,
      'rattacher', false,
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
      'codesClotureComplement', CASE WHEN v_decider THEN '["complement_clos"]'::jsonb ELSE '[]'::jsonb END));
END;
$function$;

-- lire_candidature : corps de 20261021200000_cand_l1_socle_candidatures.sql
-- recopie (garde, lecteur, absente ou hors_portee rendus, trace, exception
-- super-admin journalisee, dossier) ; ajout de D21 : pauseModele, refusModele
-- et restrictionCause, que le resultat d'un geste rend deja. Rien d'autre ne
-- change.
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

-- lister_candidatures : corps de 20261021200000_cand_l1_socle_candidatures.sql
-- recopie (garde, portee dans le WHERE, filtres, tri, pages, compteurs,
-- audit) ; ajouts de D15 : le filtre etat accepte paiement_non_disponible
-- (etat pose par L6) ; informationsManquantes compte aussi une candidature
-- de la Salle de verification et d'entretien dont un complement est en cours
-- (transition 23, L2-18).
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

-- ============================================================
-- 6. Droits, empreintes F86, controle final
-- ============================================================

REVOKE ALL ON FUNCTION
  private.candidature_etat_direction(uuid),
  private.candidature_complement_codes(text, text),
  private.candidature_complement_en_cours(public.candidatures),
  private.candidature_questionnaire_envoye(public.candidatures),
  private.candidature_controles_entree(public.candidatures, text),
  private.candidature_controles_faux(jsonb),
  private.candidature_geste_groupe(uuid, text, uuid, integer, text, text, text, date, jsonb),
  private.candidature_lot_tracer(uuid[], uuid, public.gender, text),
  private.candidature_lot_examiner(text, uuid[], uuid, public.gender),
  private.paiement_recalculer(uuid, text, uuid, text, uuid, boolean)
  FROM PUBLIC, anon, authenticated, service_role, agent_ro;

DO $acl$
DECLARE
  f text;
BEGIN
  FOREACH f IN ARRAY ARRAY[
    'public.demander_complement_candidat(uuid,text[],text,integer,text)',
    'public.admettre_salle_verification(uuid,integer,text)',
    'public.refuser_candidat(uuid,text,text,integer,text)',
    'public.mettre_en_pause_candidat(uuid,text,text,date,integer,text)',
    'public.lever_pause_candidat(uuid,integer,text,text)',
    'public.consigner_retrait_candidat(uuid,text,date,text,integer,text)',
    'public.rouvrir_candidat(uuid,text,integer,text)',
    'public.definir_responsable_candidat(uuid,uuid,integer,text)',
    'public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)',
    'public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)',
    'public.apercu_lot_candidats(text,uuid[])',
    'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)',
    'public.capacites_candidatures()',
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
      ('public.demander_complement_candidat(uuid,text[],text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active (garde positive) ; moteur de CAND-L2A1 : genre connu, son cote seulement (hors_portee rendu et trace), cle, version, regle (transitions 7 et 23, hors pause), motif ; elements de la liste fermee de la salle, sinon elements_requis ou elements_invalides rendus sans ecriture ; en salle 2, le seul code complement_clos cloture le complement en cours (aucun_complement sinon).'),
      ('public.admettre_salle_verification(uuid,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 10, en_examen, hors pause) ; paiement_compatible, cadre religieux a la version requise et questionnaire complet a la version courante, sinon controles_non_satisfaits nommes, sans ecriture.'),
      ('public.refuser_candidat(uuid,text,text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 16, pause permise et levee) ; motif interne et modele de la liste fermee, sinon refus rendus sans ecriture.'),
      ('public.mettre_en_pause_candidat(uuid,text,text,date,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 18, pose) ; motif, modele de la liste fermee, reprise facultative future, sinon refus rendus sans ecriture.'),
      ('public.lever_pause_candidat(uuid,integer,text,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 18, levee, pause requise) ; motif facultatif, aucun modele.'),
      ('public.consigner_retrait_candidat(uuid,text,date,text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 17 par la direction, pause permise et levee) ; canal conversation ou courriel, date de la demande, motif, sinon refus sans ecriture.'),
      ('public.rouvrir_candidat(uuid,text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 19, refusee ou retiree) ; compte conforme, questionnaire a jour, paiement et cadre en salle 2, sinon controles_non_satisfaits nommes sans ecriture ; paiement recalcule.'),
      ('public.definir_responsable_candidat(uuid,uuid,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 28, hors pause) ; responsable de la direction active du meme cote ou aucun, sinon responsable_invalide sans ecriture.'),
      ('public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 24, en_examen a verifier ou salle 3 restreinte paiement) ; moyen declare croisant une ligne confirme, sinon moyen_non_confirmable ; decision ecrite puis paiement recalcule (L6).'),
      ('public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active ; moteur (transition 25, motif) ; moyen declare, sinon moyen_non_declare ; decision ecrite puis paiement recalcule, transition 8 si incompatible (L6).'),
      ('public.apercu_lot_candidats(text,uuid[])', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Direction active de genre connu (42501 sinon) ; gestes groupables pause, levee, refus (codes du moteur ou de gestesGroupables), sinon geste_non_groupable ; chaque identifiant de l autre cote trace avant tout refus rendu ; eligibles et exclus avec raison, hors portee sans donnee ; jeton HMAC sous la cle du serveur ; une ligne audit_logs par apercu, sans nom.'),
      ('public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE_ENGINE',
       'Direction active de genre connu ; arguments (22023) puis trace de chaque identifiant de l autre cote avant tout refus rendu ; cle du lot (rejeu apres controle de la portee, reutilisation refusee) ; motif, modele, jeton et nombre controles avant toute ecriture ; chaque ligne seule par le moteur, sous une cle derivee ; exclus inchanges ; rapport garde sans nom.'),
      ('public.capacites_candidatures()', 'SESSION_REQUIRED_CAPABILITY_READ',
       'Lecture seule : corps de CAND-L1 garde ; CAND-L2A2 : peutDecider (direction active de genre connu), une capacite par geste (vraie pour les gestes que le serveur sait faire), peutEcrireReferentiel lu dans private.paiement_gestionnaire(), listes fermees. Sans session : 42501.'),
      ('public.lire_candidature(uuid)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Corps de CAND-L1 garde (direction active ; absente ou hors_portee rendus, jamais leves ; hors portee trace sans aucune donnee ; exception super-admin journalisee) ; CAND-L2A2 : pauseModele, refusModele et restrictionCause rendus.'),
      ('public.lister_candidatures(jsonb,text,integer)', 'ROLE_POSITIVE_ADMIN_GENDER_SCOPE',
       'Corps de CAND-L1 garde (portee par genre dans le WHERE, genre inconnu 42501, filtres 22023, aucune cle courriel, telephone ni genre, audit de chaque liste) ; CAND-L2A2 : filtre etat paiement_non_disponible ; complement en cours de salle 2 compte dans informationsManquantes.')
    ) AS t(signature, garde, note)
  LOOP
    EXECUTE pg_catalog.format('COMMENT ON FUNCTION %s IS %L', v.signature, pg_catalog.format(
      'F86 candidate allowlist: signature=%s; md5_functiondef=%s; guard_type=%s; owner=postgres; search_path=""; reviewer=Claude a relire; date=2026-10-22. CAND-L2A2. %s Must-pass: supabase/tests/scenarios_cand_l2a2_gestes_direction.sql%s.',
      v.signature,
      pg_catalog.md5(pg_catalog.pg_get_functiondef(v.signature::regprocedure)),
      v.garde, v.note,
      CASE WHEN v.signature IN ('public.capacites_candidatures()', 'public.lister_candidatures(jsonb,text,integer)',
                                'public.lire_candidature(uuid)')
           THEN ', supabase/tests/scenarios_cand_l1_socle.sql' ELSE '' END));
  END LOOP;
END;
$droits$;

DO $postflight$
DECLARE
  v record;
  v_role text;
BEGIN
  -- Les RPC client : DEFINER, proprietaire postgres, search_path vide,
  -- volatilite attendue, empreinte F86 a jour, authenticated seul, garde
  -- positive sur le role ET app_account_valid() (liste blanche des
  -- volatiles), aucune garde negative.
  FOR v IN
    SELECT e.signature, e.volatilite, p.*
    FROM (VALUES
      ('public.demander_complement_candidat(uuid,text[],text,integer,text)', 'v'),
      ('public.admettre_salle_verification(uuid,integer,text)', 'v'),
      ('public.refuser_candidat(uuid,text,text,integer,text)', 'v'),
      ('public.mettre_en_pause_candidat(uuid,text,text,date,integer,text)', 'v'),
      ('public.lever_pause_candidat(uuid,integer,text,text)', 'v'),
      ('public.consigner_retrait_candidat(uuid,text,date,text,integer,text)', 'v'),
      ('public.rouvrir_candidat(uuid,text,integer,text)', 'v'),
      ('public.definir_responsable_candidat(uuid,uuid,integer,text)', 'v'),
      ('public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)', 'v'),
      ('public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)', 'v'),
      ('public.apercu_lot_candidats(text,uuid[])', 'v'),
      ('public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)', 'v'),
      ('public.capacites_candidatures()', 's'),
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
       OR NOT pg_catalog.has_function_privilege('authenticated', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('anon', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('service_role', v.oid, 'EXECUTE')
       OR pg_catalog.has_function_privilege('agent_ro', v.oid, 'EXECUTE')
       OR app_private.has_unsafe_role_guard(v.prosrc)
       OR (v.prosrc LIKE '%app_role()%' AND v.prosrc NOT LIKE '%app_account_valid%')
       OR (v.proname LIKE '%candidature%'
           AND v.proname NOT IN ('capacites_candidatures', 'lister_candidatures', 'lire_candidature')) THEN
      RAISE EXCEPTION 'CAND-L2A2 : DEFINER, proprietaire, search_path, volatilite, empreinte, ACL, garde ou nom invalide : %',
        v.signature;
    END IF;
  END LOOP;

  -- Les gestes passent par le moteur de CAND-L2A1.
  FOR v IN
    SELECT p.oid, p.prosrc FROM pg_catalog.pg_proc p
    WHERE p.oid IN ('public.demander_complement_candidat(uuid,text[],text,integer,text)'::regprocedure,
                    'public.admettre_salle_verification(uuid,integer,text)'::regprocedure,
                    'public.consigner_retrait_candidat(uuid,text,date,text,integer,text)'::regprocedure,
                    'public.rouvrir_candidat(uuid,text,integer,text)'::regprocedure,
                    'public.definir_responsable_candidat(uuid,uuid,integer,text)'::regprocedure,
                    'public.confirmer_moyen_paiement_candidat(uuid,text,text,integer,text)'::regprocedure,
                    'public.infirmer_moyen_paiement_candidat(uuid,text,text,text,integer,text)'::regprocedure,
                    'private.candidature_geste_groupe(uuid,text,uuid,integer,text,text,text,date,jsonb)'::regprocedure)
  LOOP
    IF pg_catalog.strpos(v.prosrc, 'private.candidature_geste_ouvrir') = 0
       OR pg_catalog.strpos(v.prosrc, 'private.candidature_geste_appliquer') = 0
       OR pg_catalog.strpos(v.prosrc, 'private.candidature_geste_conclure') = 0 THEN
      RAISE EXCEPTION 'CAND-L2A2 : geste hors du moteur : %', v.oid::regprocedure;
    END IF;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
       WHERE p.oid IN ('public.refuser_candidat(uuid,text,text,integer,text)'::regprocedure,
                       'public.mettre_en_pause_candidat(uuid,text,text,date,integer,text)'::regprocedure,
                       'public.lever_pause_candidat(uuid,integer,text,text)'::regprocedure,
                       'public.executer_lot_candidats(text,uuid[],text,integer,text,text,text,date)'::regprocedure)
         AND pg_catalog.strpos(p.prosrc, 'private.candidature_geste_groupe') > 0) <> 4 THEN
    RAISE EXCEPTION 'CAND-L2A2 : refus, pause et lot hors du geste groupable commun';
  END IF;

  -- Les aides internes : appelables par aucun compte ; aucune aide cand_ de
  -- plus (CAND-L1 en compte neuf).
  FOR v IN
    SELECT p.oid FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'candidature\_%'
  LOOP
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_function_privilege(v_role, v.oid, 'EXECUTE') THEN
        RAISE EXCEPTION 'CAND-L2A2 : aide interne % executable par %', v.oid::regprocedure, v_role;
      END IF;
    END LOOP;
  END LOOP;
  IF (SELECT pg_catalog.count(*) FROM pg_catalog.pg_proc p
      WHERE p.pronamespace = 'private'::regnamespace AND p.proname LIKE 'cand\_%') <> 9 THEN
    RAISE EXCEPTION 'CAND-L2A2 : les aides cand_ de CAND-L1 doivent rester neuf';
  END IF;

  -- Les tables du lot : RLS active, aucun privilege client, aucune policy.
  FOR v IN
    SELECT c.oid, c.relrowsecurity FROM pg_catalog.pg_class c
    WHERE c.oid IN ('private.candidature_modeles_message'::regclass, 'public.candidature_lots'::regclass,
                    'private.candidature_lot_secret'::regclass)
  LOOP
    IF NOT v.relrowsecurity THEN
      RAISE EXCEPTION 'CAND-L2A2 : RLS inactive sur %', v.oid::regclass;
    END IF;
    FOREACH v_role IN ARRAY ARRAY['anon', 'authenticated', 'service_role', 'agent_ro'] LOOP
      IF pg_catalog.has_table_privilege(v_role, v.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER') THEN
        RAISE EXCEPTION 'CAND-L2A2 : % garde un privilege sur %', v_role, v.oid::regclass;
      END IF;
    END LOOP;
  END LOOP;
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies
              WHERE (schemaname = 'public' AND tablename = 'candidature_lots')
                 OR (schemaname = 'private' AND tablename IN ('candidature_modeles_message', 'candidature_lot_secret'))) THEN
    RAISE EXCEPTION 'CAND-L2A2 : une policy ouvre une table du lot';
  END IF;
  IF pg_catalog.obj_description('public.candidature_lots'::regclass, 'pg_class') IS NULL
     OR pg_catalog.obj_description('private.candidature_modeles_message'::regclass, 'pg_class') IS NULL
     OR pg_catalog.obj_description('private.candidature_lot_secret'::regclass, 'pg_class') IS NULL THEN
    RAISE EXCEPTION 'CAND-L2A2 : tables du lot sans commentaire';
  END IF;
  -- La cle des jetons : une seule ligne, assez longue, engendree par la base.
  IF (SELECT pg_catalog.count(*) FROM private.candidature_lot_secret) <> 1
     OR EXISTS (SELECT 1 FROM private.candidature_lot_secret WHERE pg_catalog.length(secret) < 64) THEN
    RAISE EXCEPTION 'CAND-L2A2 : la cle des jetons de lot est absente ou trop courte';
  END IF;

  -- Les listes fermees et les regles du moteur que ce lot suppose.
  IF (SELECT pg_catalog.count(*) FROM private.candidature_modeles_message WHERE usage = 'refus' AND actif) = 0
     OR (SELECT pg_catalog.count(*) FROM private.candidature_modeles_message WHERE usage = 'pause' AND actif) = 0
     OR private.candidature_complement_codes('prequalification', 'enseignant')
        IS DISTINCT FROM ARRAY['langues', 'recitation', 'disponibilites', 'publics', 'versement', 'cadre_religieux']::text[]
     OR NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                     WHERE r.geste = 'refuser' AND r.groupable AND r.pause = 'permise')
     OR NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                     WHERE r.geste = 'mettre_en_pause' AND r.groupable AND r.admis = ARRAY['reprise_le']::text[])
     OR NOT EXISTS (SELECT 1 FROM private.candidature_gestes_regles r
                     WHERE r.geste = 'lever_pause' AND r.groupable AND r.pause = 'requise')
     OR (SELECT pg_catalog.count(*) FROM private.candidature_gestes_regles r
          WHERE r.geste IN ('demander_complement', 'admettre_verifications', 'retirer', 'rouvrir',
                            'definir_responsable', 'confirmer_moyen_paiement', 'infirmer_moyen_paiement')) <> 9 THEN
    RAISE EXCEPTION 'CAND-L2A2 : listes fermees ou regles du moteur differentes de ce que le lot suppose';
  END IF;
END;
$postflight$;

COMMIT;
