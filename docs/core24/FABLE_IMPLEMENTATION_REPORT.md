# FABLE_IMPLEMENTATION_REPORT

Sprint noyau 24 h, périmètre frontend Flutter (Fable). Écrit le 21 septembre 2026
sur la branche `core24/fable-frontend`, baseline `ae61eb6` (voir
`FABLE_FILE_OWNERSHIP.md` §0 pour le choix de baseline : `CORE24_BASELINE_SHA`
n'a été fourni nulle part).

**À lire avant** : `CONTRACT_REQUEST_FABLE.md`. Tout ce que ce rapport décrit
comme « prêt » l'est contre des adaptateurs **réels** sur la base existante ; ce
qui attend une RPC dit « capacité absente » à l'écran, en une phrase, et le
contrat nomme la RPC.

---

## 1. Ce qui est livré, écran par écran

### Admin — Opérations > Classes (`groupes_page.dart`, réécrit)

- Le mot visible est **Classe**. Deux entrées : « Créer une classe » (principale),
  « Générer plusieurs classes » (secondaire). Côte à côte dès la tablette, l'une
  sous l'autre sur téléphone.
- Liste `DataCollection` : tableau dense à partir de 1200, cartes en dessous.
  Colonnes humaines : classe, enseignant **ou « Enseignant à affecter »**, public,
  créneau en mots (« lundi à 17:00 »), inscrits `n / seuil` (donnée serveur),
  état en pastille. Menu d'actions par ligne (inscrire, capacité, observation,
  clôturer), conservé de l'existant.
- Feuille de détail : la `CarteClasse` détail ouvert + les inscrits.
- **Inscription d'un élève sans identifiant** : un filtre texte, des pilules
  d'élèves (`comptes_admin`, rôle élève), un motif. Le champ « Identifiant de
  l'élève » a disparu.
- Toute erreur passe par `messageHumain()` : aucun message Postgres.

### Admin — Création de Classe (`creation_classe_page.dart`, nouveau)

Trois pas, une page, sur toutes les largeurs :

1. **Programme et public** : deux pilules de public, les niveaux du programme
   publié via `SelecteurNiveauProgramme` (nom humain seul), le nom prérempli
   « {niveau} · {public} », modifiable.
2. **Créneaux** : la `GrilleSemaine` de `TUT-04`/`ENS-06` (une case, un jour et
   une heure, jamais « jour = 1 »). Une case pour une Classe, N cases pour un
   lot (« 3 créneaux choisis »). Enseignant **facultatif**, choisi dans une liste
   filtrée par le serveur, « À affecter plus tard » par défaut. Durée, capacité,
   seuil : préremplis depuis les règles de l'académie (« Défaut de l'académie »
   quand la base applique son propre défaut), modifiables seulement par
   « Modifier ».
3. **Aperçu** : une `CarteClasse` par brouillon, détail ouvert, puis « Publier la
   classe » ou « Publier 3 classes ».

Dès la tablette, l'aperçu vivant se pose à droite du pas courant. La zone
d'action est bornée à `AppPage.largeurFormulaire` : aucun bouton primaire de
1440 points. La page est poussée sur le navigateur (bouton précédent du
navigateur = fermer) et rend le nombre de Classes publiées.

### Admin — Personnes > Comptes (`comptes_page.dart`)

Deux colonnes KYC V2 séparées : **Exigence KYC** (requis / facultatif /
dispensé) et **KYC** (non commencé / soumis / vérifié / correction / refusé /
dispensé). Sur un enseignant seulement, un menu « Dispenser du KYC » ou
« Rétablir l'exigence KYC » → feuille : conséquence en clair, **motif
obligatoire**, bouton inerte sans motif, retour local « Enregistré.
L'éligibilité est recalculée. », erreur humaine dans la feuille.

### Enseignant — Bienvenue (`bienvenue_page.dart`) et Mes classes (nouveau)

- La bienvenue gagne un bloc « Accès ouvert / Accès en attente » : contrat,
  identité, et **une dispense se lit comme une décision de l'académie** (« KYC
  dispensé », « L'académie vous a dispensé de cette étape »). Troisième sortie
  « Voir les classes ».
- `ClassesEnseignantPage` (`/enseignant/classes`) : tant que
  `contrat && (KYC vérifié || dispensé)` n'est pas vrai, **onboarding seul**,
  Classes disponibles masquées, chaque étape avec l'action qui débloque. Après :
  « Mes classes » (→ fiche `ENS-07`) et « Classes disponibles » avec l'unique
  bouton **Candidater** ; la carte dit « Candidature envoyée » et perd son
  bouton ; le refus se dit en langage humain.

### Tuteur / élève adulte — Classes du foyer (nouveau) et accueil

- `ClassesFoyerPage` (`/tuteur/classes`) : **« Pour qui ? »** en pilules de
  membres du foyer (absent avec un seul membre), « Classes du foyer »,
  « Classes disponibles pour {prénom} » avec le seul bouton
  **« Inscrire {prénom} »** (pastille « Inscrit » ensuite, aucun bouton sur une
  Classe complète), « Proposer un créneau » (feuille + grille, une case) quand
  rien ne convient, et le **planning** avec l'état de présence **rendu par le
  serveur** (« État calculé par le serveur, jamais par cet appareil »).
- `AccueilFamillePage` : ligne « Classes disponibles » dans « Gérer le foyer ».
  Le produit dit « membres du foyer » partout dans l'ownership (i18n).

### KYC famille non bloquant

- `DepotPiecePage` : « Faire plus tard » (tertiaire) pour tuteur et élève,
  jamais pour l'enseignant. `AttentePage` : « Continuer sans la pièce pour
  l'instant » quand seule la pièce manque. Ces deux sorties mènent à la racine
  du rôle et **rebondiront sur `/attente` tant que la porte de session n'a pas
  changé** (auth core, contrat §4.4).

### Précondition Salle — photo d'un membre mineur

`PorteSalle` remplace le bouton Rejoindre dans `MesGroupesPage` (`/tc/groupes`)
et dans le bloc « cours en direct » d'`ELV-02` (structure à 2 blocs intacte).
Photo requise et absente : titre calme, raison, « Ajouter la photo » (tuteur →
réglages) ou « la photo s'ajoute depuis le compte du tuteur » (élève). Photo
présente, non requise, ou précondition inconnue : le bouton, et le serveur
tranche. Aucun blocage inventé pour un adulte.

### Présence

`SurfacePresence` et le planning du foyer lisent `presence_seance_v` par les
services existants. Aucun timer Flutter ne décide d'un état ; `maintenant` ne
sert qu'à dater (« en salle depuis 12 min »). L'indisponible se lit « État
inconnu », jamais « Absence ».

---

## 2. Fichiers

Voir `FABLE_FILE_OWNERSHIP.md` §1 : 18 fichiers Dart nouveaux sous `lib/`,
11 modifiés, `fr.i18n.json` + 2 fichiers générés par slang, 13 fichiers de test,
3 documents. Aucun fichier de `lib/core/`, `supabase/`, routeur, DI, design
system ; aucune dépendance.

---

## 3. Tests

| Commande | Résultat |
| :--- | :--- |
| `dart run tool/verifier_jetons.dart` | 355 fichiers, **aucune violation** |
| `dart analyze lib test/features/classes` | **0 issue** |
| `flutter test test/features/classes` | **80 / 80** (11 suites) |
| Suites existantes des écrans touchés (`accueil_eleve`, `accueil_famille`, `bienvenue_enseignant`, `dossier`, `attente`, `comptes`, `observation_groupe_admin`, `fiche_groupe`, `profil_enseignant`, `reglages_enfant`, `suivi_foyer`, `appareils`, `compte`, `disponibilites`, `teaching_core/a`, `router`, `widgets`, `i18n`) | **518 / 518** |
| `flutter test` (suite complète, `--concurrency 2`) | voir §3.2 |

### 3.1 Les scénarios minimum du prompt, et le test qui les mesure

| Scénario | Test |
| :--- | :--- |
| création Classe mobile et desktop sans champ ID | `creation_classe_test.dart` (390 : aucun champ identifiant/jour/heure, grille, aperçu, publication ; 1440 : aperçu à côté, bouton borné) |
| carte Classe responsive | `carte_classe_test.dart` (360, 390, 768, 1024, 1440 ; 1/2/3 colonnes) |
| marketplace enseignant | `classes_enseignant_test.dart` (Candidater → port, carte sans bouton ensuite, fiche) |
| marketplace tuteur/élève | `classes_foyer_test.dart` (membre d'abord, Inscrire → port avec `membreId`, complet sans bouton, proposer un créneau) |
| KYC élève skippable | `kyc_plus_tard_test.dart` (tuteur : « Faire plus tard » et « Continuer sans la pièce » ; enseignant : jamais) |
| KYC enseignant bloquant tant que non cléaré | `classes_enseignant_test.dart` (KYC non commencé ou contrat manquant → onboarding, disponibles masquées) |
| dispense Admin visible correctement | `comptes_kyc_test.dart` (colonnes, motif requis, écriture `requise: false`, rétablir) ; `classes_enseignant_test.dart` (« L'académie vous a dispensé ») |
| photo mineur manquante bloque seulement l'entrée Live et propose l'action | `porte_salle_test.dart` ; `adaptateurs_test.dart` (mode enfant sans photo → bloqué, avec photo → non, standard → jamais) |
| foyer utilise « membres » | `classes_foyer_test.dart` (« Pour qui ? », « Classes du foyer ») |
| état de présence affiché sans calcul client | `surface_presence_test.dart`, `classes_foyer_test.dart` (planning : `planifiee` rendu, `null` → inconnu) |
| aucune erreur backend brute rendue à l'écran | `erreur_domaine_test.dart` + un cas par écran (`is not unique`, `P0001`, `PGRST` jamais affichés) |

### 3.2 Suite complète

`flutter test --concurrency 2` sur tout le dépôt, le 21/09/2026 à la fin du lot :
**1808 / 1808 verts, aucun rouge**, 11 min 16 s. Le rappel KYC de
`ClassesFoyerPage` a été ajouté après ce run ; sa suite (`classes_foyer_test.dart`,
13 tests dont les 2 nouveaux) a été rejouée verte, et `dart analyze` reste à 0.
Le total du dépôt est donc de 1810 tests, +80 par rapport à la baseline
(1730 mesurés sur `ae61eb6` par la session précédente, hors les 10 réécrits ici).

`catalogue_galerie_test` (défaut baseline #2, connu) est **vert** dans ce run :
aucun composant n'a été ajouté à `lib/core/widgets/`.

---

## 4. Rendu par largeur (descriptions, pas de captures)

Aucune capture : le lot n'a pas été exécuté sur appareil ni navigateur (voir §5).
Les mesures ci-dessous sont celles des tests de layout (`getRect`,
`takeException`), pas d'un regard.

| Largeur | Admin > Classes | Création de Classe | Mes classes (enseignant) | Classes du foyer |
| :--- | :--- | :--- | :--- | :--- |
| 360 | cartes en colonne, deux boutons empilés, menu d'actions par carte | pas courant plein écran, grille 7 colonnes de cases de 48, boutons Retour/Continuer en ligne bornée | onboarding ou 1 colonne de cartes | sélecteur en pilules, 1 colonne |
| 390 | idem | idem (testé) | 1 colonne (testé) | 1 colonne (testé) |
| 768 | rail admin + cartes | pas courant + aperçu vivant à droite (3/5 – 2/5) | 2 colonnes | 2 colonnes |
| 1024 | rail admin + cartes 2 colonnes | idem, cartes d'aperçu 2 colonnes | 2 colonnes (testé) | 2 colonnes |
| 1440 | barre latérale + tableau dense, actions en ligne | idem, zone d'action ≤ 640 alignée à la fin (testé : largeur < 700) | 3 colonnes, page bornée à 1200 | 3 colonnes |

Mode sombre : aucune couleur posée hors palette (`verifier_jetons`), toutes les
paires viennent d'`AppPalette` ; non regardé à l'œil.

---

## 5. Limites réelles, dites sans détour

1. **Aucune exécution sur Android, iOS ni Web.** Le lot est vérifié par
   `flutter analyze`, `verifier_jetons` et les tests de widgets. **iOS non
   compilé/testé** (aucun runner macOS). **Android non compilé.** Le build Web n'a
   pas été lancé pendant la suite complète pour ne pas déclencher le garde-fou
   mémoire de la machine ; à faire par Astra à l'intégration.
2. **Les quatre gestes de marketplace n'aboutissent pas encore en production** :
   `classesDisponibles`, `candidater`, `inscrire`, `proposerCreneau` lèvent
   `capaciteAbsente` (RPC absentes, contrat §3). Les écrans le disent en une
   phrase et ne font pas semblant.
3. **Publier sans enseignant** lève `capaciteAbsente` avant toute écriture :
   `creer_groupe` exige un enseignant (contrat §2.1). Avec enseignant, un lot se
   publie par une boucle de RPC, avec `EchecPublicationPartielle` si l'une échoue.
4. **La dispense KYC n'a aucune source serveur** : jamais inventée, donc jamais
   affichée en production tant que §4 du contrat n'est pas livré. L'UI de
   dispense est complète et testée contre le port.
5. **« Faire plus tard » rebondit sur `/attente`** tant que la porte de session
   (auth core) traite `pending_kyc` comme une attente (contrat §4.4).
6. **Précondition photo** : l'exigence est déduite du mode enfant, faute de
   drapeau serveur ; un mineur en mode standard n'est pas reconnu. Côté enfant,
   la lecture de `profils_du_foyer_v` peut être refusée par la RLS : la
   précondition est alors inconnue et le serveur tranche seul.
7. **`portGroupesProvider` (Teaching Core, hors ownership) garde son double de
   démonstration** en production : « Classes du foyer » l'affiche tel quel.
8. **Non construits, hors liste d'ownership** : l'écran Admin d'acceptation des
   candidatures, l'agrégat Admin des créneaux proposés et « Créer la classe »
   depuis un agrégat, la présence dans la feuille de détail Admin (pas de
   `prochaine_seance_id`).
9. **`CreationClassePage` est poussée par `Navigator.push`** (route sans URL) :
   le bouton précédent du navigateur la ferme, mais l'adresse ne change pas et un
   rechargement la perd. Une route `/admin/operations/classes/nouvelle` est le
   choix propre le jour où Astra touche le routeur ; la page est déjà une
   `GoRoute`-compatible (aucun paramètre requis).
10. Les cinq largeurs sont mesurées par des tests de layout, pas par des
    captures ; le 200 % de texte et le RTL ne sont pas mesurés sur les écrans
    neufs (les composants réutilisés le sont déjà par le catalogue).

---

## 6. Prompt de reprise

```
Dépôt D:\RA _APP\RA -OFFICIAL-APP, worktree D:\RA_CORE24\fable, branche core24/fable-frontend.
Lire docs/core24/FABLE_IMPLEMENTATION_REPORT.md puis CONTRACT_REQUEST_FABLE.md.
Intégration : ...routesCore24() dans app_router.dart, puis livrer les RPC du
récapitulatif §8 du contrat, dans l'ordre. Ne rien fusionner dans main sans le
vertical slice complet.
```
