# CANDIDATURES · Contrat attendu des ports (proposition)

**Statut :** `spécifié` seulement, **proposition non décidée**. Aucun fichier Dart,
aucune migration, aucune RPC n'existe pour ce qui suit. Ce document prépare le
contrat que la spécification autorise pendant la phase « frontend seul »
(spec §1.2 : « le frontend peut préparer les écrans, composants, états, modèles de
présentation et contrats attendus » ; §9 : « documenter le contrat attendu »). Il
suit le modèle de `docs/current/PED-APRES/CONTRAT_PORTS_PED_APRES.md`.

Chaque méthode porte la question du directeur dont elle dépend
(`REVUE_CRITIQUE_CANDIDATURES_2026-10-21.md`, section 9). **Une réponse
différente du directeur change la méthode, pas l'inverse.** Les codes `CAND-BR-nn`
nomment les besoins serveur de `DEPENDANCES_BACKEND.md` ; en production, tant
qu'ils manquent, chaque port rend `CapaciteIndisponible('CAND-BR-nn')` et l'écran
le dit (« Disponible au branchement serveur »), jamais une donnée fictive.

## Règles transverses (toutes méthodes)

- **Autorisation serveur.** RLS et contrôle de capacité en base ; l'écran ne
  déduit aucun droit et lit des capacités, jamais un rôle. Refus :
  `PermissionInsuffisante`, sans aucune donnée. Source absente :
  `CapaciteIndisponible`. Jamais de faux succès.
- **Cloisonnement femmes/hommes** (selon `CAND-Q07`) : appliqué par le serveur à
  toutes les lectures et à tous les gestes, comme `read_kyc_documents()`. Une
  candidature hors portée se lit comme absente, et l'écran dit « hors portée »
  quand le serveur le précise, jamais « absente ».
- **Écritures.** `versionAttendue` (concurrence optimiste) et `cleIdempotence`
  (une par geste). Version périmée : `ConflitCandidature`, aucune écriture.
  Rejouer la même clé ne duplique pas l'effet.
- **Données personnelles.** Aucune liste ne porte de courriel, de téléphone ni de
  pièce. Le contact se lit par une méthode à part, journalisée. Le journal porte
  la référence, jamais le nom.
- **Étapes et contrôles calculés en base.** L'écran affiche l'étape, l'état et
  les contrôles que le serveur rend ; il ne recalcule rien (même règle que
  `etat_dossier()`).
- **Heures.** Toute heure voyage en UTC et s'affiche dans le fuseau de la
  personne qui lit ; un fuseau inconnu bloque la planification, il ne se devine
  pas.

## 1. `PortCandidaturesDirection` (Personnes, `ADM-20` à `ADM-22`)

| Méthode | Entrée | Sortie | Erreurs | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `capacites` | aucune | `CapacitesCandidatures` : `peutLire`, `peutVoirContact`, `peutDecider`, `peutImporter`, `peutMenerEntretien` | `CapaciteIndisponible` | `CAND-Q07`, `CAND-Q19` |
| `lister` | `FiltreCandidatures` (type, étape, état, issue, pause, responsable, pays, langue, niveau déclaré, paiement, entretien, période, `recherche?`), `TriCandidatures`, `page` (≥ 1) | `PageCandidatures` : `lignes`, `total` réel du filtre, `page`, `compteursEtapes`, `compteursAlertes` (bloquées, entretiens en retard, informations manquantes, confirmées indisponibles) | `PermissionInsuffisante`, `CapaciteIndisponible` | `CAND-Q04`, `CAND-Q20` |
| `lire` | `candidatureId` | `Candidature` : référence, type, étape, état, issue, pause, responsable, réponses (avec la version du questionnaire), `controles` (nom, vrai ou faux, cause), état de la pièce (lu, jamais la pièce), entretiens, prochaine action, `version` | `PermissionInsuffisante`, `CapaciteIndisponible` | - |
| `lireContact` | `candidatureId` | `ContactCandidat` : courriel, téléphone ; chaque lecture journalisée | `PermissionInsuffisante` | `CAND-Q07` |
| `historique` | `candidatureId`, `curseur?` | `PageHistorique` : transitions, décisions d'entretien, engagement (version, date), bascules de contrôles et leur cause, import d'origine et corrections, lectures hors portée et lectures du contact | `PermissionInsuffisante` | - |
| `geste` | `candidatureId`, `Geste`, `motif?`, `modeleMessage?`, `versionAttendue`, `cleIdempotence` | `Candidature` confirmée | `ControlesNonSatisfaits` (liste nommée), `MotifRequis`, `ConflitCandidature`, `PermissionInsuffisante`, `CapaciteIndisponible` | `CAND-Q01`, `CAND-Q03` |
| `preparerLot` | `ids`, `Geste` | `ApercuLot` : éligibles (référence, nom, étape), exclus avec leur raison, effet exact, `jeton` | `PermissionInsuffisante`, `CapaciteIndisponible` | - |
| `executerLot` | `jeton`, `motif?`, `modeleMessage?`, `nombreConfirme`, `cleIdempotence` | `RapportLot` : une ligne par candidature, issue `reussie`, `exclue`, `refusee` ou `inconnue`, avec sa raison | `JetonPerime` (le lot a changé depuis l'aperçu, rien n'est écrit), `PermissionInsuffisante` | - |
| `definirResponsable` | `candidatureId`, `profilId?`, `versionAttendue`, `cleIdempotence` | `Candidature` | `ConflitCandidature`, `PermissionInsuffisante` | - |
| `planifierEntretien` | `candidatureId`, `debutUtc`, `dureeMinutes`, `intervieweurId`, `versionAttendue`, `cleIdempotence` | `Entretien` | `FuseauInconnu`, `IntervieweurNonAutorise` (genre ou capacité), `ConflitCandidature` | `CAND-Q06`, `CAND-Q07`, `CAND-Q19` |
| `consignerEntretien` | `entretienId`, `IssueEntretien` (`tenu`, `annule`, `manqueCandidat`, `manqueIntervieweur`), `compteRendu?`, `constat?` (niveau observé, riwaya, ijaza présentée), `versionAttendue`, `cleIdempotence` | `Entretien` | `ConflitCandidature`, `PermissionInsuffisante` | `CAND-Q08`, `CAND-Q22` |

**`Geste`** : `inviter`, `demanderComplement`, `admettreVerifications`,
`consignerPrevenu` (canal et modèle, jamais un texte libre), `mettreEnPause`
(`repriseLe?`), `leverPause`, `refuser`, `consignerRetrait` (demande du candidat
reçue hors de l'application), `rouvrir`, `confirmer`, `restreindre`,
`leverRestriction`. `refuser`, `mettreEnPause`, `rouvrir`, `restreindre` et
`consignerRetrait` exigent un motif. `confirmer` n'aboutit que si les huit
contrôles sont vrais en base.

**`LigneCandidature`** (liste) : référence `CAND-…` (jamais réattribuée, distincte
du matricule RA), nom affiché, étape, état, issue, pause, pays de résidence
déclaré, état d'entretien, état de paiement, responsable, dernière activité.
**Aucun** courriel, téléphone, genre ni pièce.

## 2. `PortImportCandidatures` (`ADM-23`)

| Méthode | Entrée | Sortie | Erreurs | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `analyser` | `csv` (texte), `typeCandidature` | `AnalyseImport` : en-têtes normalisés, premières lignes **contacts masqués**, mappage suggéré, libellés à faire correspondre | `FichierIllisible` (ligne et cause), `PermissionInsuffisante` | `CAND-Q03` |
| `essaiABlanc` | `csv`, `mappage` (colonne vers champ), `correspondances` (libellé vers valeur) | `RapportImport` : compteurs `nouvelles`, `dejaConnues`, `ignorees`, `aCorriger` ; lignes avec issue, motifs, avertissements ; doublons probables (lignes et clé : courriel ou téléphone) ; `ecritureEffectuee: false` ; `jeton` | `MappageIncomplet` (champs obligatoires nommés), `PermissionInsuffisante` | `CAND-Q16` |
| `confirmer` | `jeton`, `cleIdempotence` | `RapportImport` final, ligne par ligne, référence source sans nom | `DoubleVerificationRequise` (aal2 exigée **en base**), `JetonPerime`, `PermissionInsuffisante` | `CAND-Q03`, `CAND-Q17` |

Garanties : l'import n'écrit **que** des candidatures à l'étape `recue` ; il ne
crée ni compte, ni invitation, ni pièce, ni accord ; une ligne déjà dans l'import
du 12/10 (formulaire B) est rendue `dejaConnue` et n'écrit rien ; rejouer le même
fichier n'ajoute rien (clé : classeur, onglet, horodatage de la réponse) ; les
créneaux exprimés en heure de La Mecque sont convertis en UTC, jamais recopiés
dans `weekly_availability`.

## 3. `PortMaCandidature` (le candidat, dans `/attente` : `CAND-01` à `CAND-03`)

| Méthode | Entrée | Sortie | Erreurs | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `etat` | aucune | `EtatMaCandidature` : étape, état, éléments à compléter (liste nommée), entretien (`EntretienCandidat` : date, heure, fuseaux, mode, issue), pause (motif public, reprise si connue), issue (`enCours`, `refusee` avec un message tiré d'un modèle validé, jamais le motif interne, `retiree`) | `CapaciteIndisponible`, réseau | `CAND-Q01`, `CAND-Q18` |
| `conditionsRemuneration` | aucune | part de l'enseignant, montants par élève présent et par heure, règle de l'élève absent, période de versement, frais : **lus dans la politique de paie en base**, jamais écrits en dur | `CapaciteIndisponible` | - |
| `questionnaire` | aucune | `Questionnaire` : `version`, questions et options (pays, langues, opérateurs **confirmés** pour le pays de versement, lus au serveur) | `CapaciteIndisponible` | `CAND-Q05`, `CAND-Q12` |
| `envoyerReponses` | `version`, `reponses`, `accordRemuneration`, `cleIdempotence` | `EtatMaCandidature` | `QuestionnairePerime` (version courante rendue), `ReponsesIncompletes` (champs nommés) | `CAND-Q03` |
| `retirer` | `cleIdempotence` | `EtatMaCandidature` (`retiree`) | `CapaciteIndisponible` | - |

L'engagement religieux ne prend **pas** de port neuf : il passe par la page
d'accords existante, une sorte d'accord de plus et sa version requise
(`CAND-Q11`). Le questionnaire ne demande jamais de numéro de compte, d'IBAN, de
numéro de portefeuille, d'identifiant ni de code.

## 4. `PortReferentielPaiement` (`ADM-24`, et source de `CPT-BR-10`)

| Méthode | Entrée | Sortie | Erreurs | Dépend de |
| :--- | :--- | :--- | :--- | :--- |
| `lister` | `paysIso?` | lignes : pays, méthode (`virementBancaire`, `mobileMoney`), opérateur, devise, type de décaissement, état (`confirme`, `enVerification`, `indisponible`), vérifié le, vérifié par, notes, `version` | `PermissionInsuffisante` (ni direction ni comptabilité) | `CAND-Q05` |
| `enregistrer` | ligne, `versionAttendue`, `cleIdempotence` | ligne confirmée et `impact` : nombre de confirmées que le changement met en restriction | `ConfirmationSansVerification` (`confirme` exige date et responsable), `ConflitReferentiel` | `CAND-Q05` |
| `optionsConfirmees` | `paysVersementIso` | les seules lignes `confirme` du pays, sans notes internes | `CapaciteIndisponible` | `CAND-Q05` |

Le prestataire est une **colonne de données**, jamais un nom dans le code métier
(« aucun prestataire n'est codé comme obligatoire »,
`lib/core/capacites/port_capacite_payout.dart:5-8`). Ce référentiel alimente le
port existant `PortCapacitePayout.capacite(corridor)` ; il ne le remplace pas.

## 5. Garanties demandées au serveur

1. **Admission** : `confirmer` vérifie les huit contrôles en base, et la garde
   d'activation (sur le modèle de `0089`) les revérifie pour toute voie qui
   activerait un enseignant (`CAND-Q01`).
2. **Contrôle qui tombe** après confirmation : restriction automatique motivée,
   sortie de l'affectabilité, étape et historique conservés ; jamais une
   rétrogradation silencieuse.
3. **Lot** : chaque ligne s'exécute seule ; un refus n'annule jamais une réussite
   voisine ; le rapport dit `inconnue` quand le serveur ne sait pas, jamais
   « réussie » par défaut.
4. **Message au candidat** : tiré d'un modèle validé ; aucun motif interne ne
   sort vers `PortMaCandidature`.
5. **Pas de canal implicite** : aucune méthode n'envoie de message ; `consignerPrevenu`
   constate un envoi fait ailleurs (`CAND-Q10`).
6. **Conservation** : durées et anonymisation selon `CAND-Q21` ; les réponses
   entrent dans la copie des données de la personne, motifs internes exclus.
7. **Journal** : chaque geste, chaque lecture du contact et chaque lecture hors
   portée laissent une entrée `audit_logs` ; la chaîne reste vérifiable.

## 6. Tests de contrat à écrire côté serveur

Ceux de la section 12 de la revue (`T/scenarios_candidatures.sql`), plus, par
port, un double de démonstration qui sert d'oracle aux tests de widget, sur le
modèle de `test/fixtures/ped_apres/faux_partage_pedagogique.dart`. Le double
rend des données marquées comme fictives, et seulement en mode démonstration.
