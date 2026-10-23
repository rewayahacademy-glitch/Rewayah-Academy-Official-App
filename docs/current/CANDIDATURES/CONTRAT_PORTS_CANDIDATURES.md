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

**Écrit le 22/10/2026 pour `ADM-20` : `capacites` et `lister` seulement**
(`lib/core/candidature/port_candidatures_direction.dart`, adaptateur
`candidatures_direction_supabase.dart` sur les RPC `capacites_candidatures` et
`lister_candidatures`, double `test/fixtures/candidature/faux_candidatures_direction.dart`). Les
autres méthodes (`lire`, `lireContact`, `historique`, `geste`, lots, entretiens) s'ajoutent avec
l'écran qui les emploie.

- `FiltreCandidatures` n'a que les axes que le serveur filtre : recherche, étape, état, issue,
  pause, versement, pays de résidence (une clé inconnue est refusée, `22023`). `TriCandidatures` :
  activité, réception, nom. Pages de 50, fixées par le serveur.
- `CapacitesCandidatures` porte aussi `genreLecteurConnu` et les gestes rendus par CAND-L2A2
  (`gestes`, une clé absente vaut faux). `PageCandidatures.compteursAlertes` : un compteur que le
  serveur ne sert pas encore reste `null` (« Disponible au branchement serveur »).
- La recherche part normalisée (`FiltreCandidatures.rechercheEnvoyee`) : les traits d'union
  insécables et les tirets reviennent au trait d'union de la donnée, 200 caractères au plus (le
  serveur refuse davantage, `22023`).
- Refus : `42501` « genre du lecteur inconnu » devient `GenreLecteurInconnu`, tout autre `42501`
  `PermissionInsuffisante` ; fonction absente (`PGRST202`, `42883`) :
  `CapaciteIndisponible('CAND-BR-02')`. Un port absent rend la même capacité indisponible.

**Écrit le 23/10/2026 pour `ADM-21` : `lire`, `lireContact`, `historique`, `geste`,
`responsablesPossibles`, `moyensConfirmes`**
(mêmes fichiers ; modèles `lib/core/candidature/modeles_candidature_detail.dart`, gestes et refus
`lib/core/candidature/gestes_candidature.dart`). `lire` rend un `DetailCandidature` (la ligne, sa
`version`, la provenance, les messages choisis, la cause d'une restriction, les réponses ;
`controles` et `piece` restent `null` tant que le serveur ne les sert pas) ; `lireContact` est
journalisé côté serveur ; `historique` pagine par curseur et rend l'auteur par sa catégorie.

- `geste` prend une `DemandeGeste` (un constructeur nommé par geste, avec `versionAttendue` et
  `cleIdempotence`) et rend un `ResultatGeste` (l'état relu, `rejoue`). Une RPC par geste
  (`parametresDuGeste`). **Les refus métier sont rendus dans le JSON** (`{"erreur": …}`), jamais
  levés : le port les lève en `RefusGeste` typés (`ConflitGeste`, `GesteInterdit`,
  `ControlesNonSatisfaits`, `MotifRequis`, `ModeleRequis`, `ModeleInconnu`, `ElementsRequis`,
  `ElementsInvalides`, `AucunComplement`, `RepriseInvalide`, `DateDemandeInvalide`,
  `MoyenNonConfirmable`, `MoyenNonDeclare`, `ResponsableInvalide`, `CleReutilisee`) ; sans réponse :
  `GesteNonConfirme`, qui garde la clé pour être rejouée. `CandidatureIntrouvable` et
  `CandidatureHorsPortee` restent deux refus distincts, en lecture comme en geste.
- `demanderComplement` : le serveur exige un `motif` non vide (`motif_requis`, transitions 7 et 23) ;
  l'écran ne le fait pas saisir (« aucun texte libre ») et l'envoie déduit de la liste choisie (les
  noms des éléments). La clé reste celle du geste ; `cloreComplement` garde un motif saisi.
- Les jours d'un geste (`repriseLe`, `demandeRecueLe`) sont des jours UTC : le serveur les compare au
  jour UTC courant (`date_reprise_invalide`, `date_demande_invalide`).
- Fonction absente : `CapaciteIndisponible('CAND-BR-03')` en lecture, `'CAND-BR-04'` pour les gestes
  et `'CAND-BR-07'` pour l'historique.
- `responsablesPossibles` répond toujours `CapaciteIndisponible('CAND-BR-04')` : le serveur n'a pas
  de RPC pour la liste. `moyensConfirmes(pays)` lit `options_paiement_confirmees`.
- La référence `CAND-…` d'une adresse est résolue en identifiant par la recherche exacte de la file
  (`identifiantDeReference`) ; la file passe l'identifiant à l'ouverture pour s'en dispenser.
- Le serveur ne sert ni le côté (femmes, hommes) d'une candidature, ni le texte des modèles de message
  (L5) : l'écran ne les devine pas.

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
`version`. Depuis le 22/10, aussi `autresCompetences` (nul sans réponse) :
`domaines` (objet domaine → niveau), `autreTexte` (nul sans le domaine `autre`),
`disponibilite`, `accord`, `accordLe` (UTC, nul sans accord) et `majLe` (UTC), dans la
même portée que le dossier (`HorsPortee` sans aucune donnée, exception du super-admin
journalisée).

**`FiltreCandidatures`** : type, étape, état, issue, pause, responsable, pays de
résidence, langues d'explication, niveau de mémorisation déclaré, heures par
semaine, date de début, pièce (état lu dans `kyc_documents`), paiement (`inconnu`,
`compatible`, `incompatible`, `aVerifier`), entretien (état, date), alerte (l'une
des quatre), date de réception, dernière activité, `recherche?` (nom partiel
normalisé arabe et latin, référence `CAND-` exacte, courriel exact ; téléphone
exact réservé à `peutVoirContact` et journalisé). Une candidature en pause
n'entre dans aucun des quatre compteurs d'alerte. **Autres compétences** (lot
`CAND-AUTRES` du 22/10, `CAND-BR-19`, sections 3 bis et 3 ter) : `competenceDomaine` (un
**code du catalogue** des compétences, désactivé ou non, **ou une famille** : tous les codes de
cette famille, désactivés compris), `competenceNiveauMin` (`debutant`, `experience` ou `metier` : ce niveau ou plus ;
sans domaine, « au moins un domaine à ce niveau »), `competenceDisponibilite` (valeur
exacte : `quelques_heures`, `mi_temps`, `plus` ou `pas_maintenant`) et `competenceAccord`
(booléen : `true` seulement les personnes qui acceptent d'être contactées, `false` celles qui
ont répondu sans accord). Une clé à `null` vaut une clé absente ; chaque clé de compétence
exige qu'une réponse existe ; une valeur hors catalogue, hors familles ou hors liste fermée est
refusée (`22023`). La recherche
d'une personne pour une mission envoie toujours `competenceAccord: true` et lit l'`issue` de
chaque ligne (une candidature retirée garde ses réponses et son accord : point à trancher,
`PROPOSITION_AUTRES_COMPETENCES.md` section 7). Les lignes de la
liste ne changent pas : aucune réponse de compétence n'y figure.

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

## 3 bis. Les autres compétences du candidat (`PortAutresCompetences`, `CAND-BR-19`, « Vos autres talents »)

Décision du directeur du 22/10 (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 quater) ;
conception : `PROPOSITION_AUTRES_COMPETENCES.md` (section 7 pour le serveur). Parcours **facultatif**
de la salle d'attente, **après l'envoi** de la Salle d'examen. **Ce n'est pas un état** : ni
`etat_dossier()` ni la candidature n'en portent rien ; le port lit et écrit ses propres
réponses. Lot serveur `présent dans le code`, `testé localement` le 22/10, ni staging ni
production ; aucun adaptateur `*_supabase.dart` n'existe encore. **Les compétences proposées sont
celles du catalogue** (section 3 ter) : précises, regroupées par famille, que la direction complète
sans nouvelle version de l'app (décision du directeur du 22/10 : « il faut être spécifique dans ce
que tu vas demander comme compétence »).

| Méthode (RPC) | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `lire` (`lire_autres_competences()`) | aucune | `AutresCompetences` : `ouvert` (booléen), `raison` (nulle si ouvert, sinon `questionnaire_non_envoye` ou `candidature_close`), `version` (0 sans réponse), `reponses?` (`domaines` objet domaine → niveau, `autreTexte`, `disponibilite`, `accord`, `accordLe`, `majLe`, instants en UTC), `referentiel` (`familles` : les six familles dans l'ordre d'affichage ; `competences` : les entrées du catalogue dans l'ordre famille, `ordre`, code, soit **les actives et, avec `actif = false`, celles de sa propre réponse** ; `niveaux`, `disponibilites` ; `autreTexteMax` = 200) | `PermissionInsuffisante` (`42501` : pas le titulaire d'une candidature d'enseignant, ou compte non valide) | `CAND-BR-19` |
| `enregistrer` (`enregistrer_autres_competences(p_domaines jsonb, p_autre_texte text, p_disponibilite text, p_accord boolean, p_version_attendue integer, p_cle_idempotence text)`) | `domaines` (au moins 1 code du catalogue, chacun avec son niveau), `autreTexte?` (exigé avec `autre`, refusé sinon), `disponibilite`, `accord`, `versionAttendue` (0 sans réponse), `cleIdempotence` (8 à 200 signes) | `{version, inchange, rejoue}` ; **jamais une réponse** : l'écran relit par `lire` | `QuestionnaireNonEnvoye`, `CandidatureClose` (l'issue est rendue : `refusee` ou `retiree`), `ConflitAutresCompetences` (`versionCourante` rendue), `ReponsesInvalides` (champs parmi `domaines`, `autreTexte`, `disponibilite`, chacun avec son motif sous `motifs` : `domaines_requis`, `domaine_inconnu` (absent du catalogue), `domaine_desactive` (au catalogue, désactivé, et pas déjà dans sa réponse enregistrée), `niveau_invalide`, `texte_requis`, `texte_non_attendu`, `texte_trop_long`, `texte_invalide`, `disponibilite_inconnue`), `CleReutilisee` (`cle_idempotence_reutilisee` : une clé qui a servi à une autre candidature ou à un autre geste) | `CAND-BR-19` |
| `retirer` (`retirer_autres_competences(p_version_attendue integer, p_cle_idempotence text)`) | `versionAttendue`, `cleIdempotence` | `{retire, version, rejoue}` ; `retire = false` quand rien n'était enregistré | `ConflitAutresCompetences`, `CleReutilisee` | `CAND-BR-19` |

- **Les refus métier sont rendus, non levés** : un objet `{erreur: ...}`, sans aucune écriture
  (comme `PortMaCandidature`). Seuls un appelant qui n'est pas le titulaire (`42501`) et un
  argument absent ou mal formé (`22023`, par exemple une version négative ou une clé trop courte)
  lèvent.
- **Ordre des refus** de `enregistrer` : titulaire (`42501`, avant toute validation : un compte qui n'est pas
  le titulaire n'apprend rien des arguments), arguments (`22023`), rejeu de la clé (le premier résultat,
  `rejoue = true`, même si la version ou le contenu ont changé), candidature close ou envoi
  manquant, version, forme des réponses. Seuls les succès gardent leur clé : un refus se rejoue
  avec la même clé.
- **`retirer` reste permis** à une candidature refusée ou retirée (la personne retire son accord
  « à tout moment »), jamais à un compte non valide. **`enregistrer` exige** une candidature en
  cours, après l'envoi, pause comprise.
- **Une écriture identique à l'état courant** (même contenu, même accord) ne change rien :
  `inchange = true`, version et date d'accord intactes.
- **L'accord** est un booléen avec sa date : la date est celle de l'écriture qui l'a posé et
  disparaît avec lui. Décocher n'efface pas les réponses (`retirer` le fait).
- **Aucune dépendance de décision** : ces réponses ne sont lues par aucun contrôle de passage,
  par aucun calcul du paiement ni par `etat_dossier()`.
- **Aucun montant, aucune rémunération de mission** : « chaque mission aura ses conditions »
  (proposition, section 3).

## 3 ter. Le catalogue des compétences (`PortCatalogueCompetences`, `CAND-BR-19`)

Décision du directeur du 22/10 : demander des compétences **précises** (réseaux sociaux, relations
publiques, design graphique, montage vidéo, administration, pédagogie…), regroupées par famille
pour se lire d'un coup d'oeil, et que la direction complète **sans nouvelle version de l'app**.
La liste vit donc en base : `competences_catalogue`, fermée à tout compte, lue par le candidat et
la direction par `lire_catalogue_competences()`, écrite par la direction seule par
`enregistrer_competence_catalogue(...)`. État initial (migration) : **25 compétences en six
familles** : `communication` (`reseaux_sociaux`, `relations_publiques`, `design_graphique`,
`montage_video`, `photographie`, `redaction_contenus`, `publicite_en_ligne`, `traduction`),
`administration` (`assistanat`, `coordination_groupe`, `accueil_familles`, `gestion_projet`,
`ressources_humaines`), `finances_droit` (`comptabilite`, `gestion_financiere`,
`juridique_donnees`), `pedagogie` (`conception_programmes`, `formation_enseignants`,
`qualite_cours`, `tests_niveau`, `accompagnement_enfants`), `technique` (`developpement`,
`assistance_technique`, `donnees_tableurs`) et `autre` (`autre`). Lot serveur `présent dans le
code`, `testé localement` le 22/10, ni staging ni production.

**`EntreeCatalogue`** : `code` (stable pour toujours : une réponse ancienne le cite), `famille`,
`ordre` (rang dans la famille), `libelle` (1 à 80 caractères, une ligne), `exemple?` (1 à 200),
`actif` ; pour la direction seulement, `version`. Les familles sont une **liste fermée de six**
(un nom de famille se traduit dans l'app) ; un nom de famille n'est jamais un code, sauf `autre`,
qui est à la fois la famille et le code du texte libre.

| Méthode (RPC) | Entrée | Sortie | Erreurs propres | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `lire` (`lire_catalogue_competences()`) | aucune | `CatalogueCompetences` : `familles`, `competences` (`EntreeCatalogue`, dans l'ordre famille, `ordre`, code), `peutModifier` (capacité : vrai pour la direction active seule). **Direction** : tout le catalogue, désactivés compris, avec les versions. **Titulaire d'une candidature d'enseignant** : les actives et, avec `actif = false`, celles de sa propre réponse ; sans version | `PermissionInsuffisante` (`42501` : ni la direction active ni le titulaire) | `CAND-BR-19` |
| `enregistrer` (`enregistrer_competence_catalogue(p_code text, p_famille text, p_ordre integer, p_libelle text, p_exemple text, p_actif boolean, p_version_attendue integer, p_cle_idempotence text)`) | `code`, `famille`, `ordre?` (nul : à la fin de la famille pour un ajout, inchangé pour une modification), `libelle`, `exemple?`, `actif`, `versionAttendue?` (**nulle = ajout d'un code neuf** ; sinon la version lue : modification), `cleIdempotence` (8 à 200 signes) | `{competence, inchange, rejoue}` (`competence` : l'entrée relue, avec sa version) | `ConflitCatalogue` (`conflit_catalogue` : code déjà là à l'ajout, ou version périmée ; l'entrée relue est rendue), `CompetenceAbsente` (`absente`), `CataloguePlein` (`catalogue_plein`, 100 codes), `CleReutilisee` ; levées : `PermissionInsuffisante` (`42501` : pas la direction active, **y compris le candidat**) et `22023` (code mal formé ou nom de famille, famille inconnue, `autre` hors de la famille `autre`, ordre hors de 1 à 999, libelle vide, trop long ou sur plusieurs lignes, exemple trop long ou sur plusieurs lignes, famille changée, version attendue inférieure à 1, clé trop courte) | `CAND-BR-19` |

- **Ajout seul ou désactivation, jamais de suppression.** Aucun `DELETE` ni `TRUNCATE`, par aucune
  voie (déclencheur) ; le code et la famille d'une ligne ne changent jamais ; une compétence
  ajoutée par erreur se **désactive**, et se réactive. Le catalogue est plafonné à 100 codes.
- **Une compétence désactivée** : n'est plus offerte (absente de la liste d'un candidat qui ne l'a
  pas déjà choisie), ne peut plus être choisie (`reponses_invalides`, motif `domaine_desactive`) **sauf
  par qui l'a déjà dans sa réponse enregistrée** : elle la garde (avec son libelle, `actif = false`),
  peut changer son niveau ou la retirer en enregistrant autre chose, et ne la reprend plus ensuite
  tant qu'elle n'est pas réactivée ; reste lue dans le dossier par la direction ; reste cherchable
  (`competenceDomaine`, par son code ou par sa famille) ; `retirer` ne dépend d'aucun état. Une
  compétence **neuve** est offerte et choisissable aussitôt.
- **Les textes.** `libelle` et `exemple` sont en français, ceux de la direction. Pour un code que
  l'app connaît, l'écran affiche **son propre texte** (`fr`, `ar`) ; pour tout autre code, ceux du
  catalogue. Les textes semés par la migration reprennent les mots de la proposition (section 3) et
  passent par `mots-rewayah` avant d'être montrés. Une famille nouvelle demande une migration et
  un libellé dans l'app.
- **Droits.** Lire : la direction active (sans condition de genre : le catalogue ne porte aucune donnée
  de personne) ou le titulaire. Écrire : la direction active seule. Ordre des refus : la direction (`42501`, avant toute
  validation : un autre compte n'apprend rien des arguments), la forme de la clé (`22023`), le rejeu de la clé
  (avant la validation des autres arguments, comme le référentiel de paiement de `ADM-24`), les arguments
  (`22023`), puis, à l'ajout, le code déjà là (`conflit_catalogue`) et le plafond, à la modification, le code
  absent, la famille changée (`22023`), la version, l'écriture identique.
- **Idempotence.** Une clé rejouée avec la même demande par le même compte rend l'entrée relue
  (`rejoue = true`) sans écriture ; la même clé pour une autre demande (version attendue comprise)
  ou un autre compte est refusée ; une modification identique ne change rien (`inchange = true`) et
  ne garde pas sa clé ; un refus rendu ne garde pas sa clé.
- **Journal.** Chaque changement, par toute voie (la RPC, une migration, l'éditeur SQL), laisse une ligne
  en ajout seul (`competences_catalogue_journal` : l'avant, l'après, l'auteur et la clé quand c'est un
  compte) et une entrée d'`audit_logs` (`competences_catalogue_ecriture` : code, geste, famille, actif
  avant et après, version, voie ; **jamais un libelle**). Ces entrées n'ont aucun côté : toute direction
  active les lit (`journal_audit`).
- **Aucune dépendance de décision** : ni un contrôle de passage, ni le paiement, ni `etat_dossier()` ne
  lit le catalogue.

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
   Depuis le 22/10, la table `candidature_autres_competences` (section 3 bis) suit la
   candidature et entre dans le même lot : anonymisation, export et effacement, avec le
   texte de « autre » et l'accord.
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

## 7. Quasi hors serveur : `PortPartageOffre` et `PortGenrePartageur` (`CAND-06`, carte à partager « Aidez une personne à apprendre la parole d'Allah. »)

Décision du directeur du 22/10/2026 (`DECISION-CANDIDATURES-2026-10-21.md`, section 1 bis).
**Aucune écriture, aucune RPC, aucune migration** et pas de
`CapaciteIndisponible('CAND-BR-nn')` : le partage est facultatif et sans effet sur la
candidature (aucun compteur, aucun évènement). **Une seule lecture ajoutée** (refonte du
22/10, soir) : le **genre** du titulaire, sur sa propre ligne `profiles.gender`
(politique `profiles_self_select`), pour choisir la variante de la carte ; il ne pilote
ni droit ni notification et rien n'en part. Inconnu (profil illisible, hors ligne, aucun port,
plus de 5 secondes), il donne la variante neutre, jamais une erreur.

| Élément | Rôle |
| :--- | :--- |
| `PortGenrePartageur.genreDuTitulaire()` (`core/partage_offre/port_genre_partageur.dart`) | `Genre?` du titulaire ; `null` s'il ne se lit pas ; **jamais deviné** d'un prénom ni d'une photo |
| `GenrePartageurSupabase` (`genre_partageur_supabase.dart`) | un `SELECT gender FROM profiles WHERE id = auth.uid()`, délai `AppDelais.requeteMax` ; `genreDepuisLigne` rend `null` hors `male`/`female` |
| `languesEnseignementCandidatProvider` (`personnalisation_carte.dart`) | la réponse `languesExplication` de la dernière candidature, par le port de la candidature déjà branché ; vide si elle ne se lit pas |
| `reglagesCarteProvider` | les deux lectures ensemble, chacune bornée à 5 secondes (`delaiReglagesCarte`) ; ne lève jamais |
| double de test (`FauxGenrePartageur`) | oracle des tests de widget ; importé par aucune ligne de production |

Le seul point qui varie est l'appareil. `lib/core/partage_offre/port_partage_offre.dart` :

| Élément | Rôle |
| :--- | :--- |
| `NiveauPartage` (`image`, `lien`, `aucun`) | ce que le menu de partage de l'appareil accepte ; `aucun` : le bouton « Je partage » n'est pas rendu |
| `partager(png, nomFichier, titre, texte, lien)` | ouvre le menu ; rend `IssuePartage.partage` ou `.annule` (la personne ferme le menu : aucun message) ; lève `PartageImpossible` si l'appareil refuse. `titre` et `texte` sont ceux que lit la personne qui reçoit : le titre de la carte et sa ligne, **dans la langue de la carte** (« Apprendre le Coran, en petite classe. », « Avec le même enseignant. »), jamais le nom de l'académie (consigne du 22/10) |
| web (`partage_appareil_web.dart`) | `navigator.share` et `navigator.canShare` par `dart:js_interop` ; aucun paquet |
| autres plateformes (`partage_appareil_memoire.dart`) | `aucun` |
| double de test (`test/fixtures/partage_offre/faux_partage_offre.dart`) | oracle des tests de widget ; importé par aucune ligne de production |

« Enregistrer l'image » passe par `PortEnregistrementFichier` (`tc_telechargement`) et « Copier
le lien » par le presse-papiers de Flutter : ils existent déjà. Le lien vient de
`lienOffre` (`Env.siteUrl`, sinon l'origine de la page ouverte sur le web, sinon rien).
