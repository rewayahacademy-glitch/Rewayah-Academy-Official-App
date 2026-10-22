# CANDIDATURES · Contrat attendu des ports (proposition)

**Statut :** `spécifié` seulement, **proposition non décidée**. Aucun fichier Dart,
aucune migration, aucune RPC n'existe pour ce qui suit. Ce document prépare le
contrat que la spécification autorise pendant la phase « frontend seul »
(`docs/current/CANDIDATURES/REWAYAH_CANDIDATURES_SPEC_V1_2026-10-21.md`, §1.2 :
« Le frontend peut préparer les écrans, composants, états, modèles de présentation
et contrats attendus » ; §9 : « documenter le contrat attendu »). Il suit le
modèle de `docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md`.

**Dépendances.** Chaque méthode dépend de `CAND-Q02` (feu vert du lot backend) ;
la colonne « Dépend de » nomme en plus les questions du directeur qui changent sa
forme (`REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 9), et « - » veut dire :
aucune autre. **Une réponse différente du directeur change la méthode, pas
l'inverse.**

**Codes.** Les codes `CAND-BR-nn` nomment les besoins serveur de
`DEPENDANCES_BACKEND.md`. C'est une famille d'identifiants neuve pour
`CapaciteIndisponible` : le lot qui écrira les ports l'ajoutera à la liste de
`lib/core/capacites/capacite_indisponible.dart`. Les codes d'écran `ADM-20` à
`ADM-24` et `CAND-01` à `CAND-03` sont proposés (revue §10) ; aucun n'est inscrit au
catalogue, et aucun ne s'implémente avant sa fiche.

## Règles transverses (toutes méthodes)

- **Erreurs communes.** Toute méthode peut rendre `CapaciteIndisponible('CAND-BR-nn')`
  (en production, tant que la source manque, et l'écran dit « Disponible au
  branchement serveur », jamais une donnée fictive) et `PermissionInsuffisante`
  (sans aucune donnée). Les colonnes « Erreurs » ne nomment que les erreurs
  propres.
- **Autorisation serveur.** RLS et contrôle de capacité en base ; l'écran ne
  déduit aucun droit et lit des capacités, jamais un rôle. Jamais de faux succès.
- **Cloisonnement femmes/hommes** (selon `CAND-Q07`) : appliqué par le serveur à
  toutes les lectures et à tous les gestes, sur le modèle de `read_kyc_documents()` :
  filtre par genre du lecteur, refus si ce genre est inconnu, journal de chaque
  lecture de liste. Que l'exception super-admin de `0088` s'applique aussi aux
  candidatures se tranche dans `CAND-Q07`.
- **Hors portée et absence.** Une candidature hors portée rend `HorsPortee` (refus
  en base, aucune donnée, tentative journalisée) ; une référence inconnue rend
  `CandidatureAbsente`. L'écran dit « hors portée » ou « absente » selon l'erreur,
  jamais l'une pour l'autre.
- **Écritures.** `versionAttendue` (concurrence optimiste) et `cleIdempotence`
  (une par geste). Version périmée : `ConflitCandidature`, aucune écriture.
  Rejouer la même clé ne duplique pas l'effet. Un geste interdit depuis l'étape,
  l'état ou l'issue courants rend `TransitionInterdite` (état courant nommé), sans
  écriture. Toute sortie d'écriture est la donnée **relue au serveur** après
  l'écriture.
- **Données personnelles.** Aucune liste ne porte de courriel, de téléphone, de
  genre ni de pièce. Le contact se lit par une méthode à part, journalisée. Le
  journal porte la référence, jamais le nom.
- **Étapes et contrôles calculés en base.** L'écran affiche l'étape, l'état et
  les contrôles que le serveur rend ; il ne recalcule rien (même règle que
  `etat_dossier()`).
- **Heures.** Tout instant (entretien, décision, envoi) voyage en UTC et s'affiche
  dans le fuseau de la personne qui lit. Un créneau récurrent garde son heure
  locale et son fuseau IANA (« Fuseaux IANA en stockage, UTC pour les instants »,
  `docs/current/02_ARCHITECTURE_ET_SECURITE.md:23`). Un fuseau inconnu bloque la
  planification ; il ne se devine pas.

## 1. `PortCandidaturesDirection` (Personnes, `ADM-20` à `ADM-22`)

| Méthode | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `capacites` | aucune | `CapacitesCandidatures` : `peutLire` (`candidatures.lire`), `peutVoirContact` (`candidatures.contact`), `peutDecider` (`candidatures.decider`), `peutImporter` (`candidatures.importer`), `peutMenerEntretien` (`entretiens.mener`), `peutEcrireReferentiel` (`paiement.referentiel.ecrire`), `peutLireHorsGenre` (exception journalisée) | - | `CAND-Q07`, `CAND-Q19` |
| `lister` | `FiltreCandidatures`, `TriCandidatures`, `page` (≥ 1) | `PageCandidatures` : `lignes` (`LigneCandidature`), `total` réel du filtre, `page`, `compteursEtapes`, `compteursAlertes` (bloquées, entretiens en retard, informations manquantes, confirmées indisponibles) | - | `CAND-Q04`, `CAND-Q07`, `CAND-Q20` |
| `lire` | `candidatureId` | `Candidature` | `HorsPortee`, `CandidatureAbsente` | `CAND-Q01`, `CAND-Q07`, `CAND-Q08` |
| `lireContact` | `candidatureId` | `ContactCandidat` : courriel, téléphone ; chaque lecture journalisée | `HorsPortee`, `CandidatureAbsente` | `CAND-Q07` |
| `historique` | `candidatureId`, `curseur?` | `PageHistorique` : transitions (ancien et nouvel état, auteur, horodatage, motif), décisions d'entretien et compte rendu, engagement (version, date), bascules de contrôles et leur cause, import d'origine avec ses avertissements et chaque correction, lectures hors portée et lectures du contact | `HorsPortee`, `CandidatureAbsente` | `CAND-Q07` |
| `geste` | `candidatureId`, `Geste`, `motif?`, `modeleMessage?`, `versionAttendue`, `cleIdempotence` | `Candidature` relue ; pour `inviter`, aussi `InvitationEmise` | `ControlesNonSatisfaits` (liste nommée), `MotifRequis`, `ModeleRequis`, `InvitationImpossible`, `TransitionInterdite`, `ConflitCandidature`, `HorsPortee`, `CandidatureAbsente` | `CAND-Q01`, `CAND-Q03`, `CAND-Q05`, `CAND-Q10`, `CAND-Q11`, `CAND-Q18` |
| `preparerLot` | `ids`, `Geste` groupable | `ApercuLot` : éligibles (référence, nom, étape ; aucun contact), exclus avec leur raison, effet exact, nombre d'éligibles, `jeton` | `GesteNonGroupable` | `CAND-Q01`, `CAND-Q03`, `CAND-Q10` |
| `executerLot` | `jeton`, `motif?`, `modeleMessage?`, `nombreConfirme`, `cleIdempotence` | `RapportLot` : une ligne par candidature, issue `reussie`, `exclue`, `refusee` ou `inconnue`, avec sa raison ; une ligne `reussie` d'un lot `inviter` porte son code | `JetonPerime` (le lot a changé depuis l'aperçu, rien n'est écrit), `NombreDiscordant` (le nombre saisi diffère des éligibles, rien n'est écrit), `MotifRequis`, `ModeleRequis` | `CAND-Q01`, `CAND-Q03`, `CAND-Q10` |
| `definirResponsable` | `candidatureId`, `profilId?`, `versionAttendue`, `cleIdempotence` | `Candidature` relue | `ConflitCandidature`, `HorsPortee`, `CandidatureAbsente` | - |
| `planifierEntretien` | `candidatureId`, `debutUtc`, `dureeMinutes`, `intervieweurId`, `versionAttendue`, `cleIdempotence` | `Entretien` | `FuseauInconnu`, `IntervieweurNonAutorise` (genre ou capacité), `ConflitCandidature`, `HorsPortee`, `CandidatureAbsente` | `CAND-Q06`, `CAND-Q07`, `CAND-Q19` |
| `consignerEntretien` | `entretienId`, `IssueEntretien` (`tenu`, `annule`, `manqueCandidat`, `manqueIntervieweur`), `compteRendu?`, `constat?` (niveau observé, riwaya, ijaza présentée), `motif?`, `versionAttendue`, `cleIdempotence` | `Entretien` | `CompteRenduRequis`, `MotifRequis`, `ConflitCandidature` | `CAND-Q08`, `CAND-Q19`, `CAND-Q22` |
| `mesEntretiens` | `page` (≥ 1) | les seuls entretiens où l'appelant est désigné | - | `CAND-Q07`, `CAND-Q19` |
| `lireEntretien` | `entretienId` | réponses utiles à l'entretien, date, fuseaux ; jamais le téléphone, la pièce ni son état, ni une autre candidature | `HorsPortee` | `CAND-Q07`, `CAND-Q19` |

**`Geste`** : `inviter`, `demanderComplement`, `admettreVerifications`,
`confirmerMoyenPaiement`, `infirmerMoyenPaiement`, `consignerPrevenu`,
`mettreEnPause` (`repriseLe?`), `leverPause`, `noterIndisponibilite` (`jusquAu?`),
`leverIndisponibilite`, `refuser`, `consignerRetrait`, `rouvrir`, `confirmer`,
`restreindre`, `leverRestriction`.

- **Motif exigé** pour `demanderComplement` (liste nommée des éléments manquants,
  rendue au candidat), `infirmerMoyenPaiement`, `mettreEnPause`, `refuser`,
  `consignerRetrait`, `rouvrir`, `restreindre` et `leverRestriction`.
- **Modèle de message exigé** (`ModeleRequis`), en plus du motif interne, pour
  `refuser` et `mettreEnPause`, en geste seul comme en lot : le texte vu par le
  candidat est ce modèle, jamais le motif.
- **`inviter`** ne crée pas de second mécanisme : il émet l'invitation par le port
  existant `PortInvitationsEnseignant.inviter` (RPC `inviter_enseignant`,
  `lib/core/recrutement/port_invitations_enseignant.dart`), puis le serveur inscrit
  le geste dans la candidature. Il rend `InvitationEmise` (code, expiration),
  affichée à la direction qui la transmet elle-même : aucun envoi.
  `InvitationImpossible` : `courrielAbsent`, `emailInvalide`, `compteExistant`,
  `dejaInvite`.
- **`confirmerMoyenPaiement`** (méthode et opérateur déclarés, ligne du référentiel
  croisée) et **`infirmerMoyenPaiement`** sont seuls à faire passer l'état de
  paiement de `aVerifier` à `compatible` ou `incompatible` ; une ligne
  `enVerification` ne se confirme jamais (`CAND-Q05`).
- **`consignerPrevenu`** constate un envoi fait ailleurs : canal et modèle, jamais
  un texte libre (`CAND-Q10`).
- **`consignerRetrait`** : demande du candidat reçue hors de l'application, avec son
  canal et sa date ; un entretien planifié est annulé, son issue reste. Une sortie
  décidée sans demande du candidat est un `refuser`.
- **`noterIndisponibilite`** et **`leverIndisponibilite`** ne changent pas
  l'étape ; une confirmée indisponible sort de l'affectation sans rétrograder.
- **`confirmer`** n'aboutit que si les huit contrôles sont vrais en base.
  **`leverRestriction`** et **`rouvrir`** revérifient les contrôles
  (`ControlesNonSatisfaits`).
- **Lot** : `preparerLot` n'accepte que `inviter`, `mettreEnPause`, `leverPause`,
  `refuser`, `consignerPrevenu` et `confirmer` ; tout autre geste rend
  `GesteNonGroupable` et se fait dossier par dossier. Une candidature sans
  courriel valide est `exclue` d'un lot `inviter` dès l'aperçu.

**`LigneCandidature`** (liste) : référence `CAND-…` (jamais réattribuée,
distincte du matricule RA), nom affiché, étape, état, issue, pause, restriction,
indisponibilité, `EtatEntretien`, état de paiement, pays de résidence déclaré,
responsable, `prevenu` (`aPrevenir`, ou date, canal et modèle), marques
`courrielAObtenir` et `indicatifAConfirmer`, dernière activité. **Aucun**
courriel, téléphone, genre ni pièce.

**`Candidature`** (détail) : la ligne, plus les réponses (avec la version du
questionnaire), les `controles` (nom, vrai ou faux, cause), l'état de la pièce
(lu, jamais la pièce), les entretiens, la prochaine action, après confirmation
`coordonneesFinancieres` (`absentes` ou `enregistrees`, lues dans CPT-13), et
`version`.

**`FiltreCandidatures`** : type, étape, état, issue, pause, responsable, pays de
résidence, langues d'explication, niveau de mémorisation déclaré, heures par
semaine, date de début, pièce (état lu dans `kyc_documents`), paiement (`inconnu`,
`compatible`, `incompatible`, `aVerifier`), entretien (état, date), alerte (l'une
des quatre), date de réception, dernière activité, `recherche?` (nom partiel
normalisé arabe et latin, référence `CAND-` exacte, courriel exact ; téléphone
exact réservé à `peutVoirContact` et journalisé). Une candidature en pause
n'entre dans aucun des quatre compteurs d'alerte.

**`EtatEntretien`** : `aPlanifier`, `planifie`, `sessionDisponible` (voie 2),
`enCours`, `termine`, `annule`, `manque`, `lienIndisponible`.

**`Entretien`** (direction) : état, issue, date, fuseaux, intervieweur, durée si
connue, résultat, compte rendu, annulé ou manqué le et par qui, action suivante.
Avec l'issue `tenu`, le compte rendu est obligatoire (`CompteRenduRequis`) et seul
l'intervieweur désigné l'enregistre. Avec `annule`, `manqueCandidat` ou
`manqueIntervieweur`, un motif est obligatoire, le geste relève de
`candidatures.decider`, et la candidature revient à `entretien_a_planifier` en
gardant l'issue.

## 2. `PortImportCandidatures` (`ADM-23`)

| Méthode | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `analyser` | `csv` (texte), `typeCandidature` | `AnalyseImport` : en-têtes normalisés, premières lignes **contacts masqués**, mappage suggéré, libellés à faire correspondre | `FichierIllisible` (ligne et cause) | `CAND-Q03` |
| `essaiABlanc` | `csv`, `mappage` (colonne vers champ), `correspondances` (libellé vers valeur) | `RapportImport` : compteurs `nouvelles`, `dejaConnues`, `ignorees`, `aCorriger` ; lignes avec issue, motifs, avertissements ; doublons probables (lignes et clé : courriel ou téléphone) ; `ecritureEffectuee: false` ; `jeton` | `MappageIncomplet` (champs obligatoires nommés) | `CAND-Q16` |
| `confirmer` | `jeton`, `rapprochements` (pour chaque groupe de doublons proposé : la ligne retenue, ou « personnes distinctes »), `cleIdempotence` | `RapportImport` final, ligne par ligne, référence source sans nom | `DoubleVerificationRequise` (aal2 exigée **en base**), `JetonPerime` | `CAND-Q03`, `CAND-Q16`, `CAND-Q17` |

**Relation avec l'existant.** L'import des inscriptions
(`previsualiser_import_inscriptions`, `confirmer_import_inscriptions`, migrations
`20261012184501_imm_accueil_dry_run.sql` et
`20261012185025_imm_accueil_confirmation_idempotente.sql`) lit déjà l'onglet
« Enseignants (Réponses) » et range ses lignes dans `private.preinscription_persons`
(`person_kind = 'teacher'`). Une ligne déjà présente là est rendue `dejaConnue` et
n'écrit rien. `capacites_import_inscriptions()` (migration
`20261018200000_imm_import_ecran.sql`) sert de modèle à `peutImporter` ; à la
différence de `confirmer_import_inscriptions`, qui ne l'exige pas, le nouvel
import exige l'aal2 en base.

**Garanties.** L'import n'écrit **que** des candidatures à l'étape `recue` ; il ne
crée ni compte, ni invitation, ni pièce, ni accord. Aucun rapprochement ne
s'applique sans choix explicite, et un groupe sans choix reste `aCorriger`.
Rejouer le même fichier n'ajoute rien (clé : classeur, onglet, horodatage de la
réponse). Une ligne réimportée après correction dans le classeur garde sa
référence source ; la correction s'inscrit dans l'historique de la candidature,
jamais comme une candidature nouvelle. Les créneaux de la colonne J (heure de La
Mecque, sans aucun jour) ne pré-remplissent aucun champ ; leur libellé est gardé tel
quel, jamais converti en heure absolue ni recopié dans `weekly_availability`
(`MAP §3.5`).

## 3. Le candidat, dans `/attente` (`CAND-01` à `CAND-03`)

**L'état n'est pas une lecture neuve.** C'est `etat_dossier()` étendu, lu par le
service existant (`lib/core/dossier/service_dossier.dart`). `EtapeDossier` gagne
les valeurs de la revue §10.1 (à compléter avec la liste, en examen, entretien
avec `EntretienCandidat`, en pause avec le texte du modèle et la reprise si
connue, refusée avec le texte du modèle, retirée), et le routeur continue de
confiner `/attente` sur cette seule source. Le candidat ne voit jamais un motif
interne, un résultat d'entretien, un compte rendu ni un constat.

**`EntretienCandidat`** : état (`EtatEntretien`), date, heure, fuseau du candidat
et de l'intervieweur, mode (`whatsapp` ou `salle`, selon `CAND-Q06`), ouverture
autorisée (voie 2).

`PortMaCandidature` ne porte que ce qui n'est pas un état :

| Méthode | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `conditionsRemuneration` | aucune | part de l'enseignant en pour mille par public, **lue en base** ; **jamais un montant ni la devise** (taux par élève présent et par heure compris : décision du directeur du 22/10) ; règle de l'élève absent, période de versement et frais, affichés seulement une fois posés en base (`CAND-BR-12`) ; jamais écrits en dur | - | - |
| `questionnaire` | aucune | `Questionnaire` : `version`, questions et options (pays, langues du référentiel, opérateurs **confirmés** pour le pays de versement, lus au serveur ; depuis le 22/10, les langues sont propres à chaque champ : `languesExplication` sans l'arabe et sans plafond, `langueMaternelle` facultative avec lui, une option `autre` ; et `moyensAccessibles`, champ facultatif et informatif dont les options sont tous les moyens connus du catalogue de paiement, `{code, methode, nom}`, que le serveur ne lit jamais pour le paiement ; depuis le 22/10 aussi, `disponibilitesDeclarees` est une **liste de plages** `{jour, debut, fin}` : jour ISO 1 à 7, heures entières `HH:00` (fin `24:00` admise), sans chevauchement, dans le seul fuseau de `fuseauIana`, spec consolidée 2.1 bis) | - | `CAND-Q05`, `CAND-Q13`, `CAND-Q15` |
| `enregistrerBrouillon` (ajouté par L2A1 le 22/10, à confirmer avec `CAND-F15`) | `version`, `reponses` partielles, `versionAttendue` (version du brouillon ouvert, 0 sans brouillon), `cleIdempotence` | version du brouillon, champs requis encore manquants, `complet` ; jamais les réponses, relues par `questionnaire` ; la version de la candidature ne change pas | `QuestionnairePerime`, `ReponsesInvalides` (champs nommés ; une cause nommée sous `motifs` quand elle existe, aujourd'hui `plages_qui_se_chevauchent` pour `disponibilitesDeclarees`), `ConflitBrouillon` (version courante rendue), `TransitionInterdite` | `CAND-Q05` |
| `envoyerReponses` | `version`, `reponses`, `accordRemuneration`, `versionConditions` (version des conditions affichées, ajoutée par L2A1), `versionAttendue`, `cleIdempotence` | état relu (`etat_dossier()`) | `QuestionnairePerime` (version courante rendue), `ReponsesInvalides` (comme ci-dessus), `ReponsesIncompletes` (champs nommés), `AccordRemunerationRequis`, `ConditionsIndisponibles`, `ConditionsPerimees` (version courante rendue : l'accord ne vaut que pour les conditions lues), `EngagementNonAccepte` (version requise rendue), `ConflitCandidature` ; aucune transition sans les trois | `CAND-Q05`, `CAND-Q11` |
| `retirer` | `versionAttendue`, `cleIdempotence` | état relu (`retiree`) | `ConflitCandidature`, `TransitionInterdite` | - |

L'engagement religieux ne prend **pas** de port neuf : il passe par la page
d'accords existante, une sorte d'accord de plus et sa version requise
(`CAND-Q11`, `CAND-BR-11`). Le questionnaire ne demande jamais de numéro de compte,
d'IBAN, de numéro de portefeuille, d'identifiant ni de code ; le numéro WhatsApp
de contact n'est jamais présenté ni réutilisé comme numéro de portefeuille.

## 4. `PortReferentielPaiement` (`ADM-24`, et une des sources de `CPT-BR-10` : la compatibilité par corridor, ni l'activation des prestataires ni leur solde)

| Méthode | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `lister` | `paysIso?` | lignes : pays, méthode (`virementBancaire`, `mobileMoney`), opérateur, prestataire, devise, type de décaissement, état (`confirme`, `enVerification`, `indisponible`), vérifié le, vérifié par, notes, `version` ; refus sans `paiement.referentiel.ecrire` | - | `CAND-Q05` |
| `enregistrer` | ligne, `versionAttendue`, `cleIdempotence` | la ligne telle qu'enregistrée au serveur, et `impact` : nombre de candidatures confirmées que le changement met en restriction | `ConfirmationSansVerification` (`confirme` exige date et responsable), `ConflitReferentiel` | `CAND-Q05` |
| `optionsConfirmees` | `paysVersementIso` | les seules lignes `confirme` du pays, sans notes internes | - | `CAND-Q05` |

Le prestataire est une **colonne de données**, jamais un nom dans le code métier
(« Aucun prestataire n'est code comme obligatoire ; un prestataire non active
n'apparait jamais operationnel », `lib/core/capacites/port_capacite_payout.dart:6-8`).
Ce référentiel alimente le port existant `PortCapacitePayout.capacite(corridor)`
sans le remplacer. Correspondance avec `CapacitePayout`
(`lib/core/comptable/statuts_comptable.dart`) : `confirme` donne au plus
`prisEnCharge` ; `enVerification` donne `verificationRequise` ; `indisponible`
donne `nonPrisEnCharge`. `temporairementIndisponible` et
`soldePrestataireInsuffisant` viennent du prestataire activé, jamais du
référentiel.

## 5. Garanties demandées au serveur

1. **Admission** : `confirmer` vérifie les huit contrôles en base, et la garde
   d'activation `guard_teacher_activation_signatures()` (déclencheur
   `profiles_guard_teacher_activation_signatures`,
   `supabase/migrations/0089_teacher_contract_activation_guard.sql`), étendue aux
   huit contrôles, les revérifie pour toute voie qui activerait un enseignant,
   `decider_dossier()` compris (`CAND-Q01`).
2. **Contrôle qui tombe** après confirmation (pièce, paiement, restriction) :
   restriction automatique motivée, sortie de l'affectabilité, étape et historique
   conservés ; jamais une rétrogradation silencieuse.
3. **Lot** : chaque ligne s'exécute seule ; un refus n'annule jamais une réussite
   voisine ; le rapport dit `inconnue` quand le serveur ne sait pas, jamais
   « réussie » par défaut.
4. **Message au candidat** : tiré d'un modèle validé ; aucun motif interne ne sort
   vers `etat_dossier()` ni vers `PortMaCandidature`.
5. **Pas de canal implicite** : aucune méthode n'envoie de message ;
   `consignerPrevenu` constate un envoi fait ailleurs (`CAND-Q10`, `CAND-BR-16`).
6. **Conservation** : durées, anonymisation, entrée des réponses dans
   `mes_donnees_export()` (motifs internes exclus) et voie d'effacement pour une
   personne sans compte, selon `CAND-Q21`, question ouverte qui attend l'avis du
   juriste ; rien n'est présumé avant la décision datée.
7. **Journal** : chaque geste, chaque lecture du contact et chaque lecture hors
   portée laissent une entrée `audit_logs` ; la chaîne reste vérifiable.

## 6. Tests de contrat

**Côté serveur** : ceux de la section 12 de la revue
(`supabase/tests/scenarios_candidatures.sql`).

**Côté application**, par port, deux doubles distincts :

- un simulateur de test, oracle des tests de widget, sur le modèle de
  `test/fixtures/ped_apres/faux_partage_pedagogique.dart`, importé par aucune
  ligne de production ;
- une démonstration fictive en mémoire, sur le modèle de
  `lib/core/capacites/partage_pedagogique_demonstration.dart`, branchée seulement
  sous `PLAYGROUND=true` par un sélecteur du type
  `portPartagePedagogiqueSelon(demo: ...)`.

## 7. Hors serveur : `PortPartageOffre` (`CAND-06`, carte à partager « Un proche veut apprendre le Coran ? »)

Décision du directeur du 22/10/2026 (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 bis).
**Aucune dépendance serveur** : ni RPC, ni migration, ni adaptateur `*_supabase.dart`, ni
`CapaciteIndisponible('CAND-BR-nn')`. Le partage est facultatif et sans effet sur la
candidature : aucun compteur, aucun évènement, aucune écriture.

Le seul point qui varie est l'appareil. `lib/core/partage_offre/port_partage_offre.dart` :

| Élément | Rôle |
| :--- | :--- |
| `NiveauPartage` (`image`, `lien`, `aucun`) | ce que le menu de partage de l'appareil accepte ; `aucun` : le bouton « Partager » n'est pas rendu |
| `partager(png, nomFichier, titre, texte, lien)` | ouvre le menu ; rend `IssuePartage.partage` ou `.annule` (la personne ferme le menu : aucun message) ; lève `PartageImpossible` si l'appareil refuse. `titre` et `texte` sont ceux que lit la personne qui reçoit : le titre de la carte (« Apprendre le Coran en ligne, en petite classe ») et sa première ligne, jamais le nom de l'académie (consigne du 22/10) |
| web (`partage_appareil_web.dart`) | `navigator.share` et `navigator.canShare` par `dart:js_interop` ; aucun paquet |
| autres plateformes (`partage_appareil_memoire.dart`) | `aucun` |
| double de test (`test/fixtures/partage_offre/faux_partage_offre.dart`) | oracle des tests de widget ; importé par aucune ligne de production |

« Enregistrer l'image » passe par `PortEnregistrementFichier` (`tc_telechargement`) et « Copier
le lien » par le presse-papiers de Flutter : ils existent déjà. Le lien vient de
`lienOffre` (`Env.siteUrl`, sinon l'origine de la page ouverte sur le web, sinon rien).
