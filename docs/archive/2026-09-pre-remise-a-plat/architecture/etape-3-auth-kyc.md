# Plan d'exécution - Étape 3
## Auth, KYC, appairage, portails d'attente

Ce document décrit **ce qui doit exister** et **comment on vérifie que c'est
correct**. Il tient pour l'étape 3 le rôle que `etape-2-core-flutter.md` tient
pour l'étape 2. Il n'existait pas : les étapes 0, 1 et 2 avaient chacune leur
plan, l'étape 3 n'était nommée que par une ligne de feuille de route.

Sources : `docs/produit/parcours-utilisateurs.md` pour les écrans,
`docs/architecture/decisions.md` pour les ADR, `etape-0-1-fondations.md` pour le
schéma, `etape-2-journal.md` pour ce qui existe déjà côté Flutter.

---

## 1. Ce que l'étape 3 doit rendre possible

Le produit n'a **aucune porte d'entrée** avant cette étape. L'étape 1 a posé le
modèle de données, l'étape 2 le socle d'interface, mais personne ne peut encore
créer de compte, déposer une pièce d'identité, appairer un appareil ni ouvrir
une session d'enfant.

À la fin de l'étape 3, ces cinq parcours fonctionnent de bout en bout :

| # | Parcours | Écrans |
| :-- | :--- | :--- |
| 1 | Un tuteur s'inscrit, dépose son dossier, attend, est validé | `TUT-00`, `TUT-00c`, `TUT-00b` |
| 2 | Un enseignant fait la même chose, avec son contrat de non-concurrence | `TUT-00`, `TUT-00c`, `TUT-00b` |
| 3 | Un tuteur crée le profil de son enfant et appaire un appareil | `TUT-02` |
| 4 | Un enfant ouvre l'application sur l'appareil appairé et entre son code | `ELV-01` |
| 5 | L'administration valide ou refuse un dossier | `ADM-02` |

Les tableaux de bord qui suivent la validation (`TUT-01`, `ELV-02`, `ENS-02`,
`ADM-01`) sont l'étape 4. L'étape 3 s'arrête à la porte, elle ne la franchit
pas.

---

## 2. Cinq défauts trouvés dans l'existant, à corriger ici

Ils ont été trouvés en construisant les parcours, pas en relisant le schéma.
Chacun rend un parcours de l'étape 3 impossible, et aucun n'était visible tant
qu'aucun écran n'existait.

### 2.1 Aucune inscription ne crée de profil

`profiles` référence `auth.users`, mais **rien ne crée la ligne `profiles` quand
un utilisateur s'inscrit**. Le hook de jeton n'injecte alors ni rôle ni foyer,
`SessionState.role` vaut `null`, et `PorteAcces` renvoie `deconnecte`. Un
nouveau compte est donc renvoyé sur l'écran de connexion en boucle, à jamais.

Correction : une fonction `creer_profil_inscription()` appelée par la première
page de l'onboarding, et une porte `inscription` dans le routeur pour la période
où la session existe sans profil.

### 2.2 Un enseignant ne peut pas déposer sa pièce d'identité

La seule policy d'insertion sur `kyc_documents` est `kyc_guardian_insert`, qui
exige `app_role() = 'guardian'`. La matrice d'accès de l'étape 1 accorde
pourtant à l'enseignant un « E sien ». Le parcours 2 est bloqué à sa première
action.

### 2.3 Le genre du lecteur KYC est déduit de son propre dossier

`read_kyc_documents()` lit le genre du lecteur dans **ses propres documents
KYC**, et se replie silencieusement sur la branche masculine quand il n'en a
aucun. Conséquences : une administratrice qui n'a jamais déposé de pièce ne voit
aucun dossier féminin, donc ne peut pas faire son travail ; et un administrateur
masculin voit les dossiers masculins par accident plutôt que par règle.

Le genre du personnel est une donnée de son profil, pas un effet de bord de son
dossier. Correction : colonne `profiles.gender`, lecture depuis le profil, et
**refus explicite** quand il est inconnu plutôt qu'un repli silencieux.

### 2.4 Un appareil ne peut être appairé qu'à un seul enfant

`devices` porte `constraint devices_fingerprint_unique unique (device_fingerprint)`.
Une tablette partagée entre deux enfants du même foyer ne peut donc exister,
alors que `ELV-01` est construit autour du choix de profil sur appareil partagé.
L'unicité doit porter sur le couple, pas sur l'empreinte seule.

### 2.5 Le foyer est obligatoire pour tout le monde

`profiles.household_id` est `not null`. Un enseignant, un contrôleur, un
administrateur n'ont pas de foyer. Deux issues : leur fabriquer un foyer
fantôme, qui polluerait la table qui sert d'unité de facturation et les
compteurs de `ADM-01` ; ou dire la vérité. On dit la vérité, et on la rend
vérifiable par une contrainte : un élève et un tuteur ont un foyer, le personnel
n'en a pas.

---

## 3. Invariants de l'étape 3

Ils sont à l'étape 3 ce que les paires de couleurs sont à l'étape 2 : des règles
appliquées par du code, pas par de la relecture.

| # | Invariant | Où il est appliqué |
| :-- | :--- | :--- |
| I1 | Une inscription publique ne produit que `guardian` ou `teacher` | `creer_profil_inscription()`, exception en base |
| I2 | Une inscription publique naît toujours `pending_kyc`, jamais `provisional_active` | Même fonction, valeur écrite en dur. Scénario 20 de l'étape 1 |
| I3 | Un compte ne peut pas se créer deux profils | Clé primaire de `profiles` plus contrôle explicite |
| I4 | Le code d'appairage n'est jamais stocké en clair | Seule son empreinte est écrite. Il n'existe qu'à l'écran du tuteur et pendant sa durée de validité |
| I5 | Le code personnel de l'enfant ne quitte jamais l'appareil | Aucun chemin de code ne l'envoie. Vérifié par un test qui lit la source |
| I6 | Le rôle demandé par le client n'est jamais celui qui est écrit sans contrôle | La fonction refuse tout rôle hors des deux publics |
| I7 | Le plafond de deux appareils est tranché en base | Déclencheur `devices_cap` de l'étape 1, jamais par l'écran |
| I8 | Une lecture de dossier KYC est journalisée avant de rendre la moindre ligne | `read_kyc_documents()`, ordre des instructions |
| I9 | Le personnel masculin ne voit aucun dossier féminin, et l'inverse | Même fonction, avec refus si le genre du lecteur est inconnu |

---

## 4. Modèle de porte d'accès, complété

L'étape 2 a posé quatre portes. L'étape 3 en ajoute une, et c'est la correction
du défaut 2.1.

| Porte | Situation | Ce qui est atteignable |
| :--- | :--- | :--- |
| `chargement` | Session non résolue | Rien, aucune redirection |
| `deconnecte` | Aucune session | `/connexion` |
| **`inscription`** | **Session valide, aucune ligne `profiles`** | **`/inscription`** |
| `attente` | Profil en `pending_kyc`, ou statut illisible | `/attente` |
| `suspendu` | Profil `disabled` | `/attente`, motif différent |
| `actif` | `active` ou `provisional_active` | Les routes du rôle |

**Un échec de lecture n'est pas une absence de profil.** Les deux se
ressemblent depuis le client et ne veulent pas dire la même chose : l'absence
ouvre l'inscription, l'échec ferme sur le portail d'attente. Confondre les deux
enverrait un compte suspendu recréer un profil.

---

## 5. Écrans

### `TUT-00` Connexion

Un lien reçu par courriel, ou Google. Aucun mot de passe à retenir, donc aucun
mot de passe à perdre ni à voler.

Trois états : saisie, lien envoyé, erreur. L'état « lien envoyé » ne se ferme
pas tout seul et ne compte pas à rebours (règle commune des parcours).

### `/inscription` puis `TUT-00c` Identité et contrat

Parcours en pages courtes, une question par page, cartes cliquables avec carte
« Autre » systématique (ADR-013). Jamais un formulaire qui empile les champs.

Trois temps, chacun avec un seul bouton d'action : identité, contrat,
confirmation. Une estimation du temps restant en bas d'écran, parce que
l'incertitude coûte plus cher que la longueur.

Avant de demander une pièce d'identité, l'écran explique en deux lignes ce que
le contrat protège, **avec l'enregistrement audio et la visite de contrôle
nommés en clair** et non enfouis dans un texte long (ADR-002, ADR-011).

### `TUT-00b` Portail d'attente

| État | Ce qui s'affiche |
| :--- | :--- |
| Dossier incomplet | Deux ou trois éléments à fournir, chacun avec son bouton |
| En vérification | Statut, date de dépôt, délai annoncé, un seul bouton pour joindre l'académie |
| Refusé | Le motif en une phrase, et l'action pour corriger |
| Suspendu | Le motif, et l'action pour joindre l'académie |

L'écran ne montre jamais l'application derrière un voile.

### `TUT-02` Foyer et appareils, partie appairage

Liste dense, pas de grandes cartes : c'est un écran de gestion. Pour chaque
appareil, le type, la dernière utilisation, le profil qui l'a utilisé, un bouton
de révocation. À la limite de deux appareils, **le bouton d'ajout est remplacé
par un message**, jamais laissé actif pour échouer ensuite.

L'ajout affiche un QR grand format, le code à six caractères en dessous, et le
délai de validité qui s'écoule.

### `ELV-01` Connexion de l'enfant

Sur un appareil non appairé : entrer le code. Le bloc « scanner le QR »
n'apparaît **que si un lecteur de code est disponible sur la plateforme**, par
la même règle que le bouton d'ajout d'appareil de `TUT-02` : un bouton qui
échoue après le geste coûte plus cher qu'un bouton absent.

Sur un appareil appairé : le choix de profil, photo réelle ou initiales,
composition volontairement asymétrique. Puis le code personnel sur le pavé
géant.

Le code personnel est **créé sur l'appareil** juste après l'appairage, en
présence du tuteur qui vient de montrer le code. Il n'est jamais transmis, donc
jamais réinitialisable à distance : le tuteur révoque l'appareil et le réappaire.

### `ADM-02` Validation des dossiers

Un dossier à la fois, jamais une grille : la vérification d'identité mérite une
attention séquentielle. **Séparation stricte du constat et du jugement** :
aperçu du document en haut, checklist au milieu, les deux verdicts en bas, dans
cet ordre et jamais mélangés.

Le filtre de genre est appliqué par la base, pas par l'écran. La journalisation
de chaque consultation est rappelée en toutes lettres sous les boutons de
décision.

---

## 6. Ce que la base doit gagner (migration 0004)

| Objet | Rôle |
| :--- | :--- |
| `profiles.gender` | Genre du personnel, pour le filtre KYC. Défaut 2.3 |
| `profiles.household_id` rendu facultatif, plus contrainte de rôle | Défaut 2.5 |
| `devices` : unicité sur le couple, colonne `token_hash`, `derniere_utilisation` | Défaut 2.4, plus le jeton d'appareil de l'ADR-010 |
| `kyc_documents.rejection_reason` | Le motif en une phrase de `TUT-00b` |
| Policy d'insertion KYC pour l'enseignant | Défaut 2.2 |
| `device_pairing_codes` | Codes d'appairage éphémères, empreinte seule |
| `contract_acceptances` | Contrat signé, et accusé ADR-011 à usage unique |
| `creer_profil_inscription()` | Défaut 2.1, avec I1, I2, I3, I6 |
| `creer_code_appairage()` | Génération, plafond d'appareils, durée de validité |
| `etat_dossier()` | Ce qui manque au dossier, pour `TUT-00b` |
| `decider_dossier()` | Verdict de `ADM-02`, journalisé |
| Buckets `kyc` et `avatars` | Privés, URL signées de courte durée (ADR-012) |

---

## 7. Fonctions Edge

L'enfant n'a ni courriel ni mot de passe. Sa ligne `profiles` référence pourtant
`auth.users`, et une session Supabase ne se fabrique pas côté client. Deux
fonctions, seules détentrices de la clé de service, sont donc nécessaires.

| Fonction | Rôle | Contrôle métier revérifié |
| :--- | :--- | :--- |
| `creer-profil-enfant` | Crée l'utilisateur, le profil et la fiche élève d'un enfant | L'appelant est le tuteur du foyer visé et son compte est valide |
| `session-enfant` | Échange un code d'appairage ou un jeton d'appareil contre une session | Code non expiré et non consommé, ou jeton d'appareil non révoqué |

Règle de l'étape 1 rappelée : **toute fonction qui emploie la clé de service
revérifie l'autorisation métier explicitement.** La clé de service contourne la
RLS, elle ne remplace pas le contrôle.

---

## 8. Scénarios d'acceptation

Ils sont la définition de fin d'étape. Comme à l'étape 2, un scénario non mesuré
n'est pas un scénario vert.

| # | Scénario | Comment il se vérifie |
| :-- | :--- | :--- |
| 1 | Un compte authentifié sans profil atteint l'inscription, et rien d'autre | Test de redirection, toutes les routes croisées |
| 2 | Un échec de lecture du profil ferme sur le portail d'attente, il n'ouvre pas l'inscription | Test sur la source de session |
| 3 | Une inscription publique ne peut produire ni `admin`, ni `provisional_active` | Test SQL sur Postgres 17 |
| 4 | Un enseignant dépose sa pièce d'identité | Test SQL de policy |
| 5 | Un administrateur sans genre renseigné reçoit un refus explicite, pas la moitié des dossiers | Test SQL |
| 6 | Une tablette se partage entre deux enfants du même foyer | Test SQL |
| 7 | Un troisième appareil est refusé par la base | Test SQL, déclencheur de l'étape 1 |
| 8 | Un code d'appairage expiré ou déjà consommé est refusé | Test SQL |
| 9 | Le code personnel de l'enfant n'apparaît dans aucun appel réseau | Test qui lit la source, comme celui de `PermanentNotice` |
| 10 | Le portail d'attente affiche le bon état pour chacun des quatre cas | Test de widget |
| 11 | Le bouton d'ajout d'appareil disparaît à la limite, il n'échoue pas | Test de widget |
| 12 | Le parcours en cartes propose toujours une issue « Autre » | Déjà tenu par `ChoiceCardGroup`, vérifié à l'usage |

---

## 9. Ce que l'étape 3 ne fait pas

À dire ici pour qu'une session suivante ne le cherche pas :

- **Aucun tableau de bord.** `TUT-01`, `ELV-02`, `ENS-02`, `ADM-01` sont
  l'étape 4.
- **Aucune disponibilité ni matching.** `TUT-04` et `ENS-06` sont l'étape 4.
- **Aucune salle de cours.** L'étape 5.
- **Aucune lecture de QR par la caméra.** Le paquet nécessaire réclame une
  configuration de permissions par plateforme et un build Android que ce poste
  ne peut pas produire. Le chemin par le code fonctionne partout, y compris sur
  le Web et sur Windows, et l'interface est déjà posée pour recevoir le lecteur.
- **Aucun import de comptes migrés.** Le `provisional_active` de l'ADR-014
  n'existe que par un import déclenché par l'administration, à partir d'un
  fichier que l'opérateur n'a pas encore fourni.
