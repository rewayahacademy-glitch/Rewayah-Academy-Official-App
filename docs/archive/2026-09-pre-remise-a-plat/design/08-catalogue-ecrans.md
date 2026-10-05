# 08 — Catalogue des écrans

> **Aucun écran ne s'implémente s'il n'est pas dans ce tableau.**
> Si un écran manque, on l'ajoute ici d'abord, avec sa fiche, et on discute de
> la fiche avant d'ouvrir un fichier `.dart`. Sans cette règle, l'agent
> improvise, et c'est exactement ce qui produit les applications incohérentes.

## 1. Le registre

Colonnes : **Niv.** est le niveau de charge de `03-architecture-information.md`
§3. **Prof.** est la profondeur de navigation. **État** dit ce qu'il y a
réellement dans `lib/`, au 7 septembre 2026.

### Zone Accès

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-00` | Connexion | Tous | A | 0 | `/connexion` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `ELV-01` | Connexion élève | Élève | B | 0 | `/connexion/eleve` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c` | Création de profil | Tuteur, enseignant | C | 1 | `/inscription` | Parcours | Parcours centré | construit, fiche §6 |
| `TUT-00b` | Portail d'attente | Tuteur, enseignant | C | 0 | `/attente` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/a` | Accusé enregistrement et contrôle | Tuteur, enseignant | C | 1 | `/attente/accuse` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/b` | Contrat | Tuteur, enseignant | C | 1 | `/attente/contrat` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `TUT-00c/c` | Dépôt de la pièce | Tuteur, enseignant | C | 1 | `/attente/piece` | Page | Page centrée | **repris (R0)**, fiche §6 |
| `AGT-00` | Entrée d'un agent | Agent IA | A | 0 | `/agent` | Page | Page centrée | **construit (18/09)**, fiche §6 |
| `ENS-01` | Onboarding et bienvenue | Enseignant | C | 1 | `/enseignant/bienvenue` (+ les cinq surfaces partagées ci-dessus) | Parcours court, une carte par pas | Parcours centré | **partiel** : le tunnel `/attente/*` existe, la bienvenue est **à construire** (lot Enseignant), fiche §7 |

### Zone Foyer

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-01` | Accueil famille | Tuteur | C | 0 | `/tuteur` | Liste de `ChildCard` | 2 à 3 colonnes + colonne « à confirmer » | **repris (R2)**, fiche §6 |
| `TUT-02` | Foyer et appareils | Tuteur | C | 1 | `/tuteur/foyer` | Deux listes denses | Deux colonnes | **repris (R4)**, fiche §6 |
| `TUT-02/a` | Ajouter un enfant | Tuteur | C | 2 | `/tuteur/foyer/ajouter-enfant` | Parcours | Feuille latérale | **repris (R4)**, fiche §6 |
| `TUT-02/b` | Appairer un appareil | Tuteur | C | 2 | `/tuteur/foyer/appairer/:id` | Page, QR grand format | Page centrée | **repris (R4)**, fiche §6 |
| `TUT-05` | Réglages par enfant | Tuteur | C | 1 | `/tuteur/reglages` | Une carte par enfant | 2 colonnes | **repris (R4)**, fiche §6 |

### Zone Disponibilités et affectation

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `TUT-04` | Disponibilités du foyer | Tuteur | C | 1 | `/tuteur/disponibilites` | Grille défilante | Grille entière | **repris (R4)**, fiche §6 |
| `ENS-06` | Disponibilités et matching | Enseignant | D | 1 | `/enseignant/creneaux` | Deux onglets | Grille + feed côte à côte | **repris (R4)**, fiche §6 ; **en reprise, lot Enseignant** (Agent D) |
| `ADM-05` | Attribution manuelle | Admin | E | 1 | `/admin/attribution` | Deux listes empilées | Deux listes côte à côte | **construit (12/09)**, fiche §6 |

### Zone Journée et salle

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-02` | Accueil élève | Élève | B / C | 0 | `/eleve` | Deux blocs | Deux blocs centrés, **rien de plus** | **repris (R1)**, fiche §6 |
| `ENS-02` | Journée | Enseignant | D | 0 | `/enseignant/journee` | Une colonne | Colonne + panneau de détail | **repris (R3)**, fiche §6 ; **en reprise, lot Enseignant** (Agent A) |
| `ENS-07` | Fiche groupe | Enseignant | D | 1 | `/enseignant/groupe/:groupeId` | Page contextuelle | Page contextuelle, deux colonnes | **à construire**, lot Enseignant (Agent A), fiche §7 |
| `CTR-01` | Planning global | Contrôleur | D | 0 | `/controleur` | Liste | Tableau dense | **construit (13/09)**, fiche §6 |
| `ELV-03` | Salle, élève | Élève | B / C | hors arbre | `/salle` | Plein écran | Vidéo + contenu | **construit (12/09)**, fiche §6 |
| `ENS-03` | Salle, enseignant | Enseignant | D | hors arbre | `/salle` | Plein écran | Vidéo + contenu + participants | **construit (12/09)**, fiche §6 ; **en reprise, lot Enseignant** (Agent B) |
| `CTR-02` | Observation invisible | Contrôleur | D | hors arbre | `/salle` | Plein écran | Idem, bandeau de contrôle permanent | **construit (12/09)**, fiche §6 |

### Zone Contenu et transmission

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ELV-04` | Coran | Élève, enseignant | B / C | 1 | `/eleve/coran` | Lecteur plein écran | Colonne de lecture bornée | **construit (13/09)**, lot N5 |
| `ENS-04` | Cahier de transmission | Enseignant | D | 2 | `/enseignant/seance/:seanceId/cahier`, depuis la sortie de salle | Page, une main, 45 s | Panneau | **à construire**, lot Enseignant (Agent C), fiche §7 |
| `ENS-08` | Revue de groupe | Enseignant | D | 2 | `/enseignant/groupe/:groupeId/revue` | Page contextuelle, liste d'anomalies | Page contextuelle, liste + détail | **à construire**, lot Enseignant (Agent C), fiche §7 |
| `TUT-06` | Suivi du foyer | Tuteur | C | 1 | `/tuteur/suivi` | Une carte par cours | Tableau dense | **construit (13/09)**, fiche §6 |
| — | Suivi élève | Élève standard | C | 1 | `/eleve/suivi` | Liste | Liste + détail | **à construire** — ⚠ état périmé, voir §2 : `SuiviElevePage` est branchée depuis, sans fiche |

### Zone Administration

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `ADM-01` | Centre de commande | Admin | E | 0 | `/admin` | Signaux puis chiffres | 4 chiffres + liste pleine largeur | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-02` | Validation des dossiers | Admin | E | 1 | `/admin/personnes/dossiers` | Un dossier à la fois | File à gauche, dossier à droite | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-06` | Demandes et règles | Admin | E | 1 | `/admin/operations/demandes` | Liste de demandes | Liste + feuille de règles | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-04` | Journal d'audit | Admin | E | 1 | `/admin/securite-audit/journal` | Cartes | Tableau dense | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-05` | Attribution manuelle | Admin | E | 1 | `/admin/operations/attributions` | Deux listes empilées | Deux listes côte à côte | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-07` | Accès des agents IA | Admin | E | 1 | `/admin/securite-audit/acces-agents` | Formulaire puis cartes | Formulaire + tableau dense | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-08` | Comptes | Admin | E | 1 | `/admin/personnes/comptes` | Cartes | Tableau dense | **repris (19/09, gel d'architecture)**, fiche §6 |
| `ADM-09` | Groupes | Admin | E | 1 | `/admin/operations/groupes` | Cartes | Tableau dense | **construit (19/09, pivot 1-à-1 → groupe)**, fonction primaire d'Opérations |
| `ADM-10` | Diagnostics | Admin | E | 1 | `/admin/pedagogie/diagnostics` | File puis décision | File à gauche, décision à droite | **construit (19/09)**, fonction primaire de Pédagogie, fiche §6 |
| `ADM-11` | Progression | Admin | E | 1 | `/admin/pedagogie/progression` | Cartes groupées | Tableau dense groupé | **construit (19/09)**, fiche §6 |
| `ADM-12` | Évaluations | Admin | E | 1 | `/admin/pedagogie/evaluations` | Cartes | Tableau dense | **construit (19/09)**, fiche §6 |
| `ADM-13` | Programmes | Admin | E | 1 | `/admin/pedagogie/programmes` | Liste de versions | Liste + détail de niveaux | **construit (19/09)**, fiche §6 |
| `ADM-14` | Qualité | Admin | E | 1 | `/admin/pedagogie/qualite` | Cartes groupées par type | Tableau dense groupé | **construit (19/09)**, fiche §6 |
| `ADM-15` | Règles | Admin | E | 1 | `/admin/configuration/regles` | Liste de réglages | Liste de réglages, pleine largeur | **construit (19/09, contrat Finance/Configuration)**, fonction primaire de Configuration, fiche §6 |
| `ADM-16` | Fonctionnalités | Admin | E | 1 | `/admin/configuration/fonctionnalites` | Liste de réglages | Liste de réglages, pleine largeur | **construit (19/09, contrat Finance/Configuration)**, fiche §6 |
| `ADM-17` | Conservation des données | Admin | E | 1 | `/admin/configuration/conservation-donnees` | Liste de réglages | Liste de réglages, pleine largeur | **construit (19/09, contrat Finance/Configuration)**, fiche §6 |
| `ENS-05` | Profil enseignant | Enseignant | D | 0 | `/enseignant/profil` | Page, liste de sections | Page + colonnes | **à construire** (talon branché), lot Enseignant (Agent E), fiche §7. **Report ADR-003 levé** par ADR-027 |
| `CPT-01` | Espace comptable | Comptable | E | 0 | `/comptable` | Cartes | Tableaux | **construit (Comptable V1, 05/10)** : voir « Zone Comptable » ci-dessous, qui détaille `CPT-01` à `CPT-13` |

`ENS-05` figure dans la zone Administration par héritage du registre d'origine,
qui y a rangé les écrans sans zone propre. Sa zone réelle est la **surface
personnelle de l'enseignant**, et sa fiche §7 l'écrit ainsi. La ligne n'est pas
déplacée : un code d'écran change de place dans un tableau et six documents
continuent de citer l'ancienne.

**Codes nouveaux introduits par ce catalogue** : `ENS-05` et `CPT-01`, qui
existaient comme routes sans code, et les trois sous-écrans `TUT-00c/a`, `/b`,
`/c`, qui étaient décrits sans être nommés. Aucun code existant n'est renommé.

**Codes nouveaux introduits par le lot Enseignant, le 20 septembre 2026** :
`ENS-07` **Fiche groupe** et `ENS-08` **Revue de groupe**. Ils étaient libres :
le registre tenait déjà `ENS-02` à `ENS-06`, et `ENS-01` était nommé sans fiche
dans `docs/historique/couverture-specs.md` ligne 64 (« Portail KYC et
onboarding »). Les deux codes sont la conséquence directe du **pivot du
19 septembre 2026** — les cours se donnent par groupe de cinq enfants ou six
adultes, avec une seule visio commune (migration `0017`) — et l'enseignant
n'avait jusqu'ici aucune surface pour lire un groupe autrement qu'élève par
élève. Aucun code existant n'est renommé, et aucun des cinq écrans du lot ne
devient une destination de premier niveau
(`docs/architecture/TEACHER_PARALLEL_BASELINE.md` §3.2).

**Gel d'architecture du 19 septembre 2026** (`docs/architecture/ADMIN_IA_AUDIT.md`) :
la sidebar admin passe à huit domaines (Accueil, Opérations, Personnes,
Pédagogie, Finance, Configuration, Sécurité et audit, Direction), avec des
routes NESTED par domaine. Les sept écrans admin existants sont **déplacés**,
pas dupliqués : leurs anciennes routes plates (`/admin/tableau-de-bord`,
`/admin/dossiers`, `/admin/comptes`, `/admin/attribution`, `/admin/demandes`,
`/admin/journal`, `/admin/acces-agents`) restent en redirection permanente
vers leur route canonique ci-dessus. Aucun code `ADM-xx` n'est ajouté : quatre
des huit domaines (Pédagogie, Finance, Configuration, Direction) n'ont aucune
fonction livrée et **ne reçoivent ni route ni écran** -- l'audit interdit
explicitement une page construite pour remplir un domaine vide.

### Zone Comptable

Inscrite le 5 octobre 2026 (étape CPT-DIR-2, décision Q-11 = b du directeur,
prise par délégation le 05/10). La fiche de chaque écran est la revue UX
existante, `20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md` sur la branche
`pilotage/tuteur-v1` (citée « UX_REVIEW §n » dans la dernière colonne) : on n'en
écrit pas une seconde ici. Routes et ports : `CARTE_FONCTIONS` de CPT-FUS.
**État** : présent dans le code et testé localement, frontend seulement ; en
production chaque port renvoie `CapaciteIndisponible('CPT-BR-nn')` et la page
affiche son état « en préparation » ; la démonstration
`/demo/comptable?ecran=…` (hors production) porte les données. Montants
masqués par défaut, pourcentages dérivés d'un montant masqués avec eux (Q-9) ;
textes traduits en arabe (Q-10).

| Code | Écran | Rôle | Niv. | Prof. | Route | Mobile | Desktop | État |
| :--- | :--- | :--- | :-: | :-: | :--- | :--- | :--- | :--- |
| `CPT-01` | Aujourd'hui (et file « À traiter et alertes ») | Comptable | E | 0 | `/comptable`, `/comptable?vue=attention` | Zones empilées, file complète par lien | Grille de zones, accès rapides | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.1 |
| `CPT-02` | Paiements à effectuer, confirmation de payout | Comptable | E | 1 | `/comptable/paiements` | Cartes, barre de sélection basse | Tableau dense, sélection en lot | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.2 |
| `CPT-03` | Détail d'un paiement, « Signaler un écart » | Comptable | E | 2 | `/comptable/paiements/obligation/<id>` | Page, sections empilées | Détail et lignes du calcul côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.3 |
| `CPT-04` | Trésorerie et coffres, alimenter la Réserve | Comptable | E | 0 | `/comptable/tresorerie`, `?action=alimenter` | Synthèse puis coffres en cartes | Coffres à gauche, Réserve à droite | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.4 |
| `CPT-05` | Encaissements | Comptable | E | 1 | `/comptable/tresorerie/encaissements` | Cartes filtrées | Tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-06` | Détail d'un encaissement | Comptable | E | 2 | `/comptable/tresorerie/encaissements/<id>` | Page | Panneau à droite de la liste | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-07` | Rapprochement, remboursements | Comptable | E | 1 | `/comptable/tresorerie/rapprochement` | Liste puis détail | Liste à gauche, détail à droite | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.5 |
| `CPT-08` | Contractuels et obligations | Comptable | E | 1 | `/comptable/paiements/contractuels` | Onglets et cartes | Onglets et tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-09` | Obligation d'un contractuel | Comptable | E | 2 | `/comptable/paiements/contractuels/obligation/<id>` | Page, barre d'action collante | Détail et historique côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-10` | Nouvelle obligation | Comptable | E | 2 | `/comptable/paiements/contractuels/nouvelle` | Tâche focalisée, barre basse masquée | Formulaire borné | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.6 |
| `CPT-11` | Bénéficiaires | Comptable | E | 1 | `/comptable/paiements/beneficiaires` | Cartes filtrées | Tableau dense | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.7 |
| `CPT-12` | Profil de paiement d'un bénéficiaire | Comptable | E | 2 | `/comptable/paiements/beneficiaires/<id>` | Page, actions en bas | Profil et journal côte à côte | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.7 |
| `CPT-13` | Recevoir mes paiements | Comptable, Enseignant | D | 1 | `/compte/paiements-recus` | Page, méthodes en liste | Page bornée | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.10 |
| `ADM-18` | Finance > Réserve et délégation | Admin | E | 1 | `/admin/finance/reserve-delegation` | Deux panneaux empilés | Deux panneaux, formulaire borné | **construit (Comptable V1, 05/10)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 |
| `ADM-19` | Finance > À valider (demandes du Comptable) | Admin | E | 1 | `/admin/finance/a-valider` | File puis décision en feuille | File, décision en feuille | **construit (CPT-VAL-1, 05/10, Q-8 = a)**, fiche [UX_REVIEW](https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/blob/pilotage/tuteur-v1/20_comptable/UX_REVIEW_FINANCE_COMPTABLE_L0.md) §5.9 et `docs/current/CPT-VAL-1.md` |

**Codes nouveaux introduits le 5 octobre 2026** : `CPT-02` à `CPT-13`,
`ADM-18`, `ADM-19`. `CPT-01` garde son code et sa route ; seul son contenu
change. Aucun code existant n'est renommé. La Vue globale et les Politiques
commerciales de la Finance (vague 17_finance) restent hors de ce registre,
comme avant.

## 2. Ce que le registre révèle

> **Mise à jour du 13 septembre 2026, lot N5.** Le compte ci-dessous datait de
> la refonte. Depuis, `ADM-05` (hors série), `ADM-04`, **la salle**
> (`ELV-03`/`ENS-03`/`CTR-02`, un seul écran pour trois codes) puis **le
> lecteur de Coran** (`ELV-04`) ont été construits. Il reste **quatre** écrans à
> construire : le suivi élève, `TUT-06`, `ENS-05`, et `CPT-01` qui
> est hors MVP-0. L'espace admin n'a plus un seul écran manquant. Le compte se
> lit dans `lib/core/router/app_router.dart`, jamais en parcourant les écrans :
> un `EcranAConstruire` de ce fichier n'est pas un écran manquant mais l'état
> de chargement de la racine.
>
> ✅ **`CTR-01` est construit**, le même jour et par une autre session : sa
> route ne rend plus `EcranAConstruire`, et le compte est donc bien tombé à
> quatre. Fiche §6. **Aucun des quatre restants n'appartient à l'étape 5** : le
> suivi élève et `TUT-06` relèvent de la transmission, étape 6 avec `ENS-04` ;
> `ENS-05` est reporté avec l'ensemble du module finance (ADR-003) ; `CPT-01`
> est hors MVP-0. L'étape 5 n'a donc plus d'écran manquant.
>
> ✅ **`TUT-06` est construit le 13 septembre 2026**, et il en reste **trois** :
> le suivi élève, `ENS-05`, `CPT-01` — donc **deux dans le MVP-0**. Ce lot
> tranche une contradiction entre deux sources, et la fiche §6 l'écrit plutôt
> que de la masquer : `parcours-utilisateurs.md` décrit `TUT-06` comme
> l'historique des **cahiers de transmission**, qui n'existent ni comme table ni
> comme écran avant l'étape 6, quand la migration `0011` a ouvert
> `presence_seance_v` au tuteur **en nommant `TUT-06`** dans son propre corps.
> L'écran construit est donc celui que la base sait nourrir aujourd'hui — la
> date, l'enseignant, l'assiduité — et le contenu pédagogique le rejoindra avec
> `ENS-04`. **Aucune colonne vide n'est posée en attendant** : une colonne
> « ce qui a été travaillé » remplie de tirets serait une promesse non tenue à
> chaque ligne.
>
> 🔴 **Mise à jour du 20 septembre 2026, lot Enseignant, et elle corrige aussi
> la méthode de comptage.** Le compte ci-dessus ne se lit **plus** dans
> `lib/core/router/app_router.dart` : il n'y reste **qu'un seul**
> `EcranAConstruire` (ligne 91), et c'est celui que la ligne précédente nomme
> déjà comme l'état de chargement de la racine, pas un écran manquant. Toutes
> les autres routes rendent désormais une page. **Mesuré le 20 septembre 2026**
> par `Select-String -Path lib/core/router/app_router.dart -Pattern
> EcranAConstruire`, qui rend une occurrence. La méthode de comptage est donc
> désormais la colonne **État** de ce registre, et rien d'autre.
>
> **Le compte juste après ce lot de fiches.** Le catalogue inscrit cinq fiches
> neuves (`ENS-01`, `ENS-04`, `ENS-05`, `ENS-07`, `ENS-08`) : deux étaient déjà
> des lignes du registre sans fiche (`ENS-04`, `ENS-05`), trois sont des codes
> nouveaux dont un partiellement construit (`ENS-01`, dont le tunnel `/attente/*`
> existe). Écrans encore à construire, au sens de la constitution — une route
> qui rend un écran fini, avec sa fiche : **six dans le MVP-0** (`ENS-01`
> bienvenue, `ENS-04`, `ENS-05`, `ENS-07`, `ENS-08`, et le suivi élève),
> plus `CPT-01` hors MVP-0. Le compte est passé de deux à six **parce que le
> catalogue a rattrapé le produit**, pas parce que le produit a reculé : cinq de
> ces six écrans étaient déjà dus, quatre sans aucune fiche pour les décrire.
>
> ⚠ **Un état de ligne périmé, mesuré et non corrigé faute de fiche.** La ligne
> « Suivi élève » de la zone Contenu et transmission porte encore
> « à construire », alors que `lib/features/suivi_eleve/` existe et que
> `app_router.dart` ligne 198-200 branche `SuiviElevePage` sur
> `Routes.eleveSuivi`. Cet écran **n'a pas de fiche dans ce fichier** : au sens
> de la constitution il n'est donc pas fini, et sa ligne n'est pas passée à
> « construit » sur la seule preuve qu'une route rend quelque chose. C'est le
> seul écran du produit dans cet état, et la fiche est à écrire hors du lot
> Enseignant.

Un seul `EcranAConstruire` subsiste au routeur (l'état de chargement de la
racine), et quatre des écrans qui existent
étaient à reprendre par le lot R. Le lot R les a repris tous les quatre :
`ELV-02` (fait, R1), `TUT-01` (fait, R2), `ENS-02` et `ADM-01` (fait, R3).

Le lot **R0**, le 11 septembre 2026, a repris les six écrans de la zone Accès
qui montaient un `Scaffold` nu (cause n1 mesurée du rejet du 11 septembre,
`docs/HANDOFF.md` section 0 ter) : `TUT-00`, `ELV-01`, `TUT-00b`, `TUT-00c/a`,
`TUT-00c/b`, `TUT-00c/c`. `TUT-00c` n'a pas changé de code : il passait déjà
par `PageParcours`, seule sa fiche manquait.

Le lot **R4**, le même jour, a repris les six derniers écrans construits de la
refonte et leurs deux sous-écrans : `TUT-02`, `TUT-02/a`, `TUT-02/b`, `TUT-04`,
`TUT-05`, `ENS-06`, `ADM-02`, `ADM-06`. Le lot **R** est désormais complet.

Le point qui n'était pas à rater, corrigé au lot R4 : **`ENS-06` employait des
onglets sur desktop alors qu'il a la place d'afficher les deux panneaux**. Un
onglet sur un écran de 1440 pixels cachait la moitié de l'information sans
raison ; à partir de la tablette, la grille et le feed se voient désormais
tous les deux, sans onglet (fiche §6).

## 3. La fiche d'écran

Chaque écran a la sienne, dans ce fichier, en dessous du registre. Elle se
remplit **avant** l'implémentation. Un champ vide est une question à poser, pas
une case à deviner.

```
CODE              ENS-06
Nom               Disponibilités et matching
Rôle              Enseignant
Zone              Disponibilités et affectation
Niveau de charge  D
Écran parent      ENS-02
Profondeur        1
Question          Quand suis-je libre, et qui attend un enseignant ?

Priorités         P0  la grille de mes disponibilités
                  P0  le feed des élèves en attente, trié par ancienneté
                  P1  le nombre de places restantes sur mon plafond
                  P2  l'accès à la demande d'augmentation de plafond

Action principale     Prendre un élève
Actions secondaires   Poser ou retirer un créneau
Action tertiaire      Demander une augmentation de plafond
Destructif            aucun

Mobile            deux onglets
Tablette          grille au dessus, feed en dessous
Desktop           grille à gauche, feed à droite, pas d'onglet

États             loading   squelette de grille + trois lignes de feed
                  content   nominal
                  empty     « Aucune famille en attente sur vos créneaux »,
                            sans bouton : l'enseignant ne peut rien y faire
                  error     message sur le feed seul, la grille reste utilisable
                  offline   grille consultable, prise impossible et dite

Mouvement         prise d'un élève : la carte sort par le motif « suppression »,
                  retour local « Aicha vous est affectée »
                  créneau posé : la case change d'état, 160 ms

Invariants        le tri est par ancienneté d'attente, jamais alphabétique
                  la base tranche la concurrence, jamais l'écran
                  le feed rend une ligne par créneau, pas par élève :
                  compter les lignes annoncerait quatre familles pour une

Accessibilité     cases de grille à 44 minimum, label parlé « Lundi 17 heures,
                  disponible », grille lisible de droite à gauche en arabe
```

Les fiches des écrans à construire se remplissent au moment de leur lot. Les
fiches des écrans déjà construits se remplissent au lot R, **à partir du code
existant**, ce qui sert aussi de relecture.

Deux sections portent donc les fiches, et la distinction n'est pas cosmétique :
la **section 6** rassemble celles qui ont été remplies à partir du code, la
**section 7** celles du lot Enseignant, écrites **avant** le code et qui le
commandent. Une fiche de la section 7 ne décrit pas ce qui existe.

## 4. Invariants déjà acquis, à ne pas casser en reprenant un écran

Ces règles ont chacune coûté un défaut. Elles sont détaillées dans les journaux
d'étape ; elles sont rappelées ici parce que le lot R touchera les écrans qui
les portent.

| Écran | Invariant |
| :--- | :--- |
| `ELV-03`, `ENS-03`, `CTR-02` | Le bandeau permanent ne change **jamais**, y compris pendant une visite de contrôle. Son composant n'accepte aucun paramètre de visibilité |
| `ELV-03` | Micro et caméra fermés à l'entrée, un tap les ouvre. Vrai pour tous les rôles |
| `ELV-03` | Quand la politique du profil interdit la caméra, le bouton **n'existe pas**, il n'est pas grisé |
| `ENS-03` | La sortie mène obligatoirement à `ENS-04`. Aucun autre chemin |
| `ENS-06` | Tri par ancienneté d'attente. `order()` de postgrest trie en descendant par défaut : le sens s'écrit toujours |
| `ENS-02` | Pauses et prières sont des entrées de la même colonne, pas un bloc séparé |
| `ADM-01` | Le zéro s'affiche comme les autres valeurs |
| `ADM-02` | Constat et jugement séparés : document en haut, vérification au milieu, verdicts en bas |
| `TUT-02` | À la limite de deux appareils, le bouton d'ajout est **remplacé par une phrase** |
| `TUT-01` | « Assister » entre en observateur muet, et l'enseignant le voit arriver |
| Tous | Rien ne se ferme sur minuterie |

## 5. Ordre de reprise

| Lot | Écrans | Pourquoi cet ordre |
| :--- | :--- | :--- |
| **T** | aucun | Jetons, thème, typographie, mouvement. Reprendre un écran avant obligerait à le reprendre deux fois |
| **C** | aucun | Les douze composants P0 de `07-catalogue-composants.md`, et leur galerie |
| **R1** | `ELV-02` | **fait le 7 septembre 2026.** C'est l'écran montré à l'opérateur, et le plus simple : deux blocs. Il sert de preuve du système |
| **R2** | `TUT-01` | **fait le 8 septembre 2026.** Il porte `ChildCard`, composant du domaine famille |
| **R3** | `ENS-02`, `ADM-01` | **fait le 8 septembre 2026.** `TimelineRow` porté par les trois sorties (cours, pause, prière), `StatTile` aux compteurs, `SignalRow` à la liste à traiter. `NavShell` câblé au routeur dans le même lot, voir `etape-2-journal.md` |
| **R4** | `TUT-02`, `TUT-04`, `TUT-05`, `ENS-06`, `ADM-02`, `ADM-06` | Le reste de l'existant. **fait le 11 septembre 2026** |
| **N** | les onze écrans manquants | Chacun avec sa fiche remplie d'abord |

## 6. Fiches des écrans repris

Une fiche par écran, remplie au lot R **à partir du code**, ce qui sert aussi de
relecture. Un champ vide serait une question à poser, pas une case à deviner.

### `ELV-02` Accueil élève

```
CODE              ELV-02
Nom               Accueil eleve
Role              Eleve, en mode enfant et en mode standard
Zone              Journee
Niveau de charge  B en mode enfant, C en mode standard
Ecran parent      aucun : racine du role
Profondeur        0
Question          Quand est mon prochain cours, et comment j'y entre ?

Priorites         P0  l'etat du prochain cours, dans ses six formes
                  P0  l'entree en seance, pendant un cours en direct
                  P1  les interruptions de priere du cours, annoncees avant lui
                  P1  l'acces au Coran, permanent

Action principale     Rejoindre : rendue seulement pendant un cours en direct,
                      inerte hors ligne, jamais absente
Actions secondaires   aucune
Action tertiaire      Ouvrir le Coran : le second bloc, toujours present
Destructif            aucun

Mobile            Deux blocs empiles
Tablette          Deux blocs, gouttiere elargie a 32
Desktop           Identique, colonne centree et bornee a 1200. On n'ajoute
                  rien : le niveau B ne gagne pas de densite avec la largeur

Etats (bloc principal)
  cours plus tard   carte surfaceRaised : haut-parleur, compte a rebours en
                    displayMedium, prenom de l'enseignant
  cours imminent    carte surfacePrimary pleine, pulsation 1200 ms. Seule zone
                    pleine de l'ecran, seule pulsation du produit. Sous
                    mouvement reduit : bordure borderStrong fixe, sans pulsation
                    (04-systeme-mouvement.md section 5)
  cours en direct   carte surfaceRaised, pastille StatusPill verte, haut-parleur,
                    prenom, bouton Rejoindre en surfacePrimary
  aucun cours du jour   EmptyState registre subi, prochain cours exprime en
                        jours et jamais en date
  seance annulee    EmptyState registre subi, aucune explication technique,
                    aucun statut, aucun motif
  offline           identique au cours en direct : le bouton Rejoindre devient
                    inerte et gagne un pictogramme de reseau. Le bandeau
                    OfflineBanner de PageShell coiffe la page
  loading / error   pas d'etat dedie : la lecture des seances qui echoue ou qui
                    tarde retombe sur l'etat "aucun cours". Dette assumee,
                    reportee : concevoir un squelette et un message d'erreur a
                    hauteur d'enfant depasse la reprise

Mouvement         pulsation du bloc imminent : 1200 ms, hors budget de
                  transition ; remplacee par une bordure fixe sous mouvement
                  reduit

Invariants        deux blocs, rien d'autre, quel que soit l'etat
                  une seule zone pleine : le bloc imminent
                  les interruptions de priere sont annoncees avant le cours,
                  jamais decouvertes pendant (ADR-017), et sans condition d'etat
                  en mode enfant, chaque decision porte un libelle parle
                  (AudioLabel) ; l'heure et le nom de la priere ne s'y lisent pas
                  le prochain cours se dit en jours pour l'enfant, jamais en date
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44 en standard, 72 en mode enfant
                  libelles parles sur le prochain cours, le cours en direct et
                  la pause priere
                  les deux blocs se lisent de droite a gauche en arabe
                  a 200 % de taille de texte, les blocs grandissent, aucun texte
                  rogne
```

Reprise faite le 7 septembre 2026, sous-lot R1. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold` avec sa gouttière et son `OfflineBanner`.
  Il passe par `PageShell`, qui borne aussi la colonne à 1200 et la centre sur
  desktop, ce que le catalogue demandait pour le desktop du niveau B ;
- le cours en direct et le hors ligne étaient des aplats `surfacePrimary`
  pleins : trois zones pleines possibles sur un même écran. Seul l'imminent le
  reste ; les deux autres redeviennent des cartes, avec pastille verte et bouton
  d'entrée en `surfacePrimary` ;
- la pastille « en direct » était un `Container` décoré posé dans l'écran. Elle
  passe par `StatusPill`, comme sur `TUT-01` ;
- les états vides prenaient le registre « actionnable » par défaut, avec son
  icône d'accent. Ils passent au registre « subi » : l'enfant ne peut rien y
  faire, son enseignant prépare le prochain cours ;
- sous mouvement réduit, la pulsation était simplement arrêtée. Elle est
  désormais **remplacée** par une bordure `borderStrong` fixe, portée par une
  nouvelle prise `contourFort` de `BentoTile`, jumelle de celle d'`AppCard`.

### `TUT-01` Accueil famille

```
CODE              TUT-01
Nom               Accueil famille
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      aucun : racine du role
Profondeur        0
Question          Comment va chacun de mes enfants aujourd'hui, et qu'ai-je a
                  confirmer ?

Priorites         P0  l'etat en direct de chaque enfant, une carte par enfant
                  P0  l'entree en observateur muet pendant une seance en cours
                  P1  la date de fin d'acces de chaque enfant, qui tient lieu de
                      portefeuille en MVP-0
                  P1  l'acces aux appareils et aux reglages par enfant

Action principale     Assister : rendue seulement pendant une seance en cours de
                      l'enfant. Entre en observateur muet, et l'enseignant le
                      voit arriver
Actions secondaires   Proposer des heures : sur la seule carte "aucune heure
                      proposee"
Action tertiaire      aucune
Destructif            aucun

Mobile            Liste de ChildCard, puis section "Gerer le foyer"
Tablette          Identique, gouttiere du gabarit
Desktop           Identique, colonne centree et bornee a 1200. La mise en deux ou
                  trois colonnes et la colonne "a confirmer" du paragraphe 1 ne
                  sont pas implementees : reporte, comme le desktop multi-colonnes
                  d'ELV-02. Le lot R porte le langage des lots T et C, pas les
                  presentations de 05-regles-responsive.md

Etats (carte d'un enfant, cinq phases decidees par phaseEnfant, fonction pure)
  en cours              ChildCard posee surfaceRaised, pastille StatusPill verte
                        "En direct", prenom de l'enseignant, minuteur ecoule,
                        bouton "Assister" en surfacePrimary. Jamais un aplat
                        plein : deux enfants en cours ne font pas deux zones
                        pleines (01-systeme-visuel.md section 3)
  cours a venir         ChildCard posee, "Aujourd'hui a {heure}, avec {prenom}",
  aujourd'hui           aucune action
  rien aujourd'hui      ChildCard posee, le prochain rendez-vous date ("{jour} a
                        {heure}, avec {prenom}"), ou, quand la semaine n'est pas
                        encore posee, "Aucun cours programme pour l'instant". Le
                        preambule "Rien aujourd'hui" de l'ecran d'avant est
                        retire : la carte dit directement le prochain rendez-vous,
                        ce que le catalogue nomme "Rien aujourd'hui : prochain
                        cours date"
  en recherche          ChildCard posee, encre inkMuted, pastille neutre "En
                        recherche d'un enseignant", "Demande deposee le {date}"
                        ou, sans date datable, "Un enseignant prendra {prenom} en
                        charge parmi les heures proposees"
  aucune heure          ChildCard washWarning + contour borderStrong, "Aucune
  proposee              heure proposee pour {prenom}", bouton "Proposer des
                        heures". La phrase de consequence de l'ecran d'avant
                        ("Sans creneau, aucun enseignant ne peut...") n'est plus
                        rendue : l'etat scelle EnfantSansPlanning ne porte que
                        ce que 07-catalogue-composants.md section 3 lui fixe
  seance annulee        ChildCard washAlert, pastille alerte "Annule", motif en
                        une phrase ("Le cours de {heure} n'aura pas lieu", ou
                        "Seance annulee peu avant l'heure" pour une annulation
                        tardive), et ce qui est propose. Le libelle de statut
                        "Seance annulee" de l'ecran d'avant est porte par la
                        pastille, plus par une ligne
  loading / error       pas d'etat dedie : une lecture en echec des enfants, des
                        seances ou des affectations affiche une phrase d'alerte
                        sous les cartes ; une lecture qui tarde retombe sur
                        l'etat nominal, y compris le transitoire "en recherche ->
                        aucune heure" pendant que les creneaux se chargent. Meme
                        dette assumee qu'ELV-02
  hors ligne            le bandeau OfflineBanner de PageShell coiffe la page.
                        L'etat hors ligne par carte de ChildCard n'est pas cable :
                        distinguer donnee volatile et donnee stable par enfant
                        depasse la reprise

Mouvement         aucun propre a l'ecran. La carte imminente de ChildCard ne
                  pulse pas : une seule zone pulse par produit, c'est ELV-02

Invariants        une carte par enfant, aucune statistique decorative : le tuteur
                  n'a pas le tableau de bord d'un gestionnaire (03 section 6)
                  "Assister" entre en observateur muet, et l'enseignant le voit
                  arriver
                  "Assister" n'est rendu que pendant une seance en cours
                  une seule zone pleine par ecran : aucune carte n'est un aplat
                  surfacePrimary, seul le bouton "Assister" l'est
                  le motif d'une annulation est une phrase humaine, jamais la
                  valeur SQL du statut
                  rien ne se ferme sur minuterie
                  la carte n'est pas cliquable : TUT-01 n'a pas d'ecran de detail
                  par enfant, et 07 section 4 interdit une affordance qui ne mene
                  nulle part. Le chevron de la ligne "Normal" du catalogue 07
                  section 3 est une prise du composant, honoree le jour ou un
                  ecran de suivi par enfant existera

Accessibilite     cibles a 44 en mode standard
                  chaque ChildCard porte un libelle parle : prenom, etat, detail
                  les cartes se lisent de droite a gauche en arabe
                  a 200 % de taille de texte, les cartes grandissent, aucun texte
                  rogne
```

Reprise faite le 8 septembre 2026, sous-lot R2. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold` avec `OfflineBanner`, `RefreshIndicator`
  et `ListView`. Il passe par `PageShell` : fond crème, gouttière du gabarit,
  colonne centrée et bornée à 1200, titre d'écran, bandeau hors ligne ;
- ses lignes d'enfant étaient un `BentoTile` portant un `switch` d'états dans
  l'écran. Elles passent par `ChildCard` : l'écran ne décide plus que **quelle**
  phase, par la fonction pure `phaseEnfant` (renommage de l'ancien `etatEnfant`,
  pour éviter la collision avec le `EtatEnfant` scellé de `ChildCard`), et un
  mapper traduit la phase en état visuel avec les phrases mises en forme ;
- la pastille « en direct » était un `Container` décoré posé dans l'écran. Elle
  passe par `StatusPill`, portée par la carte. Conséquence de fond, la même qu'à
  `ELV-02` : le cours en direct n'est plus un aplat `surfacePrimary` plein mais
  une carte posée, seul son bouton porte l'aplat ;
- une `SectionHeader` « Gérer le foyer » sépare les cartes des blocs secondaires
  (appareils, réglages, accès), qui restent des `BentoTile` comme le bloc Coran
  d'`ELV-02`. Nouvelle clé `t.tuteur.accueil.gererLeFoyer` ;
- deux règles ajoutées à `verifier_jetons.dart` avec la reprise, comme le lot C
  l'avait prévu : aucun `Container` décoré dans `lib/features/`, aucun
  `showDialog` hors de `ConfirmDestructive`. Zéro occurrence de l'un et de
  l'autre après la reprise.

Dettes assumées et écarts reportés, sur le modèle de la dette loading/error
d'`ELV-02` :

- **le tirage-pour-rafraîchir disparaît.** L'ancien écran portait un
  `RefreshIndicator` qui invalidait les trois providers ; `PageShell` ne porte
  volontairement pas d'état de données, et l'envelopper dans un `RefreshIndicator`
  réintroduirait la tuyauterie par écran que le lot R retire. `seancesProvider`
  et `affectationsProvider` ne sont alors relus qu'au démarrage de l'application,
  ou après édition des disponibilités, chemin hors du parcours tuteur. Un
  rétablissement propre est une **prise `onRafraichir` optionnelle de
  `PageShell`** : évolution de composant à trancher explicitement, puisqu'elle
  touche la frontière « ni les états de données » de son en-tête, et utile aussi
  à `ELV-02` et aux écrans R3/R4 ;
- desktop multi-colonnes et colonne « à confirmer » du §1 : non implémentés,
  reportés, comme pour `ELV-02` ;
- **`NavShell` n'est toujours pas câblé au routeur**, comme R1 l'avait laissé.
  Après R2, la racine du rôle tuteur est refondue mais n'offre toujours aucune
  navigation de premier niveau vers Disponibilités, Réglages ou Suivi. Le câblage
  demande un `StatefulShellRoute` couvrant tous les rôles à barre : c'est son
  propre sous-lot, à traiter avec `ENS-02` / `ADM-01` (R3) ou après.

### `ENS-02` Journée

```
CODE              ENS-02
Nom               Journee
Role              Enseignant
Zone              Journee
Niveau de charge  D
Ecran parent      aucun : racine du role
Profondeur        0
Question          Quel est mon prochain cours, et qui attend un enseignant ?

Priorites         P0  l'etat du cours : en cours ou prochain, en une carte
                      dominante
                  P0  les alertes du cours dominant (un eleve qui n'est pas
                      entre, un cours annule aujourd'hui), JUSTE SOUS la carte
                      et non dans les exceptions : a 390 de large, une absence
                      annoncee sous la colonne serait lue apres le cours
                  P0  la colonne de la journee, cours, pauses et prieres
                      comme entrees de meme nature
                  P1  les rapports en attente, en SignalRow, qui menent au
                      cahier de la seance concernee (ENS-04)
                  P1  le feed des eleves en attente, porte vers la grille
                      des creneaux (ENS-06)
                  P2  l'acces contextuel a la fiche du groupe (ENS-07)

Action principale     « Lancer le cours », et seulement dans la fenetre ou elle
                      peut aboutir : de dix minutes avant le debut jusqu'a la
                      fin. Hors fenetre, une phrase dit quand elle s'ouvrira,
                      jamais un bouton grise. Le materiel est verifie AVANT par
                      preVolProvider : sans micro, il n'y a pas de bouton, il y
                      a la raison. Hors ligne, le bouton disparait et le dit
Actions secondaires   Ouvrir le cahier d'un rapport en retard ; ouvrir la fiche
                      du groupe ; ouvrir la grille des creneaux
Action tertiaire      aucune
Destructif            aucun

Mobile            carte dominante, colonne, puis bloc matching
Tablette          identique, gouttiere du gabarit
Desktop           la colonne et un panneau de detail cote a cote (registre) ne
                  sont pas implementes : reporte, comme les multi-colonnes
                  d'ELV-02. Le lot R porte le langage, pas les presentations
                  de 05-regles-responsive.md

Etats
  en cours          carte posee surfaceRaised, pastille StatusPill verte
                    "En direct", prenom, identifiant immuable, "jusqu'a
                    {heure}". Jamais un aplat sature : une seule zone pleine
                    par ecran, et l'etat se dit par la pastille, pas par la
                    couleur de fond
  a venir           carte posee, "Prochain cours", minuteur en heures et
                    minutes, sans date
  autre jour        carte posee, "{jour} a {heure}" : le jour long nomme
                    l'instant, une date seule n'y ajoute rien
  aucun cours       EmptyState registre subi : l'enseignant ne quitte pas
                    l'ecran pour agir, le bloc matching en dessous le fait
  journee finie     une phrase sous la colonne, singulier ou pluriel
  loading           Skeleton.tuileBento puis Skeleton.ligneTimeline, par UN
                    SEUL chemin : le second squelette, inatteignable, a ete
                    supprime et non repare (lot Enseignant, agent A)
  error             EmptyState et « Reessayer » qui relit vraiment
  error partielle   quand prieres, pause, rapports ou feed echouent seuls :
                    une phrase en inkAlert, et l'ecran reste utilisable. Une
                    pause illisible ferait disparaitre toutes les pauses en
                    silence
  preflight echoue  pas de bouton, et la raison distincte : micro absent, ou
                    permission refusee. « Reessayer » remesure le materiel
  presence inconnue aucune alerte : invariant J3, inconnu n'est pas absent
  seance sans groupe ni nom invente ni tiret, et aucun acces groupe
  hors ligne        le bandeau OfflineBanner de PageShell coiffe la page, et
                    dans la fenetre de lancement le CTA disparait avec sa
                    raison

Mouvement         aucun propre a l'ecran

Invariants        pauses et prieres sont des entrees de la meme colonne,
                  jamais un bloc separe : l'interruption se lit a sa place
                  dans le deroule
                  une seule colonne, une entree par evenement, aucune
                  statistique decorative
                  UNE ENTREE PAR SEANCE, jamais une par eleve : depuis le pivot
                  du 19 septembre 2026 l'ecran lit seancesEnseignantProvider,
                  et non seancesProvider qui afficherait cinq fois le cours
                  d'un groupe de cinq enfants
                  le bloc dominant porte le NOM DU GROUPE et son effectif, pas
                  un prenom : cinq prenoms avant un cours seraient cinq choses
                  a lire, et ils se lisent sur ENS-07
                  les alertes individuelles restent RARES : deux au plus, puis
                  une phrase qui dit combien d'autres attendent
                  l'objectif commun de la seance n'est PAS affiche : aucune
                  couche ne le porte, et se taire coute moins cher qu'un tiret
                  a chaque ligne (CONTRACT_REQUEST_A.md §4)
                  la colonne est portee par TimelineRow, qui decide lui-meme
                  du libelle et de l'icone de chaque sorte
                  les heures affichees sont celles de l'appareil, sans
                  mention de fuseau : les seances sont des instants absolus,
                  et mon_fuseau dit ou l'enseignant pose ses creneaux
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44
                  chaque ligne de la colonne porte son libelle parle
                  la colonne se lit de droite a gauche en arabe
                  a 200 % de taille de texte, aucun texte rogne
```

Reprise faite le 8 septembre 2026, sous-lot R3. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner`, un tirage-pour-
  rafraîchir et un `ListView` avec sa gouttière. Il passe par `PageShell` :
  fond crème, titre d'écran, gouttière du gabarit, colonne bornée et centrée,
  bandeau hors ligne ;
- le bloc dominant était un aplat `surfacePrimary` plein quand un cours était
  en cours : une zone pleine de plus sur un écran qui n'a aucune action à
  promouvoir. Il devient une carte posée, et l'état « en cours » se dit par
  une pastille `StatusPill` verte, la même que sur `ELV-02` et `TUT-01` ;
- les lignes de la colonne étaient un `BentoTile` local `_LigneJournee`. Elles
  passent par `TimelineRow` (nouveau composant, `07` §2) : un seul gabarit pour
  les trois sorties, l'icône `AppIcon.cours` ou `AppIcon.pause`, le libellé et
  la durée décidés par le composant lui-même, pour que la colonne reste une
  seule liste homogène ;
- l'état vide « aucun cours » prenait le registre actionnable par défaut. Il
  passe au registre « subi », comme sur `ELV-02` : l'enseignant ne peut rien y
  faire ici, le bloc matching est en dessous.

Dettes assumées et écarts reportés :

- **le tirage-pour-rafraîchir disparaît**, comme sur `TUT-01` et `ADM-01`
  (même format de dette, voir la fiche `TUT-01`). `seancesProvider`,
  `reglagesPriereProvider` et `valeurRegleProvider` ne sont alors relus qu'au
  démarrage de l'application ; la sortie de la grille des créneaux (ENS-06)
  reste un chemin de relecture honnête. Rétablissement propre = prise
  **`onRafraichir` optionnelle de `PageShell`**, à trancher explicitement ;
- le panneau de détail desktop du registre : non implémenté, reporté.

### `ADM-01` Centre de commande

```
CODE              ADM-01
Nom               Centre de commande
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun : racine du role
Profondeur        0
Question          Qu'est-ce qui attend une decision ce matin ?

Priorites         P0  les six compteurs, zeros compris (invariant I9)
                  P0  ce qui se traite d'un tap : dossiers et demandes,
                      ordonnes par anciennete
                  P1  la portee de la liste, dite en une phrase

Action principale     aucune : chaque signal EST son propre bouton, il n'y a
                      pas d'action qui prime sur les autres
Actions secondaires   Ouvrir la validation des dossiers (ADM-02), ouvrir les
                      demandes et regles (ADM-06) : depuis le compteur comme
                      depuis la ligne ; ouvrir la qualite pedagogique (ADM-14)
                      depuis le compteur "rapports manquants"
Action tertiaire      aucune
Destructif            aucun

Mobile            six compteurs en deux colonnes, puis la liste a traiter
Tablette          identique, gouttiere du gabarit
Desktop           la liste pleine largeur (registre) : les compteurs restent
                  deux par deux, denses et recurrents. Reporte avec le desktop
                  multi-colonnes

Etats
  compteurs         toujours six, zeros compris (I9) : rendus des que la
                    lecture aboutit
  compteurs         une phrase d'alerte, jamais six zeros inventes : l'admin
  en echec          verrait une ruche vide et croirait tout traite
  liste a traiter   une SignalRow par cas, triee par anciennete de depose,
                    jamais par nature : un dossier depose hier passe devant
                    une demande de ce matin
  rien a traiter    EmptyState "tout est traite", sans bouton : il n'y a rien
                    a ouvrir
  liste en echec    une phrase sous la liste, et les compteurs restent :
                    dossiers et demandes passent par deux fonctions
                    differentes, l'echec de l'une n'emporte pas l'autre
  loading           "chargement" sous le titre, avant les compteurs

Mouvement         aucun propre a l'ecran

Invariants        le zero s'affiche comme les autres valeurs, jamais masque
                  le tri est par anciennete d'attente, jamais alphabetique
                  trois compteurs menent a leur ecran (dossiers, demandes,
                  rapports manquants -> ADM-14 depuis le 19 septembre 2026) ;
                  les deux restants (incidents, comptes echus) sont des
                  rapports sans onPress, jusqu'a ce qu'une fonction
                  Securite/Personnes reelle existe pour les filtrer
                  un signal mene directement a son ecran d'action, jamais a
                  un menu (02-regles-ux.md section 2)
                  l'anciennete se lit en jours, tous les jours lus sur le
                  meme instant, jamais recolores dans une meme liste
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44
                  chaque tuile et chaque ligne porte un libelle parle, chiffre
                  et libelle ensemble
                  chiffres tabulaires : passer de 17 a 18 ne fait pas bouger
                  la ligne
                  la page se lit de droite a gauche en arabe
```

Reprise faite le 8 septembre 2026, sous-lot R3. Ce que le code portait avant, et
que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner`, un tirage-pour-
  rafraîchir (`RefreshIndicator` invalidant trois providers) et son `ListView`.
  Il passe par `PageShell`, comme `ELV-02`, `TUT-01` et `ENS-02` ;
- les compteurs étaient un `BentoTile` local `_Compteur` qui teintait la tuile
  en discret quand la valeur passait au-dessus de zéro — une couleur portée
  par la seule valeur, que le catalogue de composants interdit (« le ton ne se
  lit pas sur la valeur », `stat_tile.dart`). Ils passent par `StatTile` :
  chiffres tabulaires, libellé parlé, et le ton neutre partout. Trois d'entre
  eux tiennent des compteurs actionnables (dossiers → `ADM-02`, demandes →
  `ADM-06`, rapports manquants → `ADM-14` depuis le 19 septembre 2026) ; les
  deux restants sont des rapports sans `onPress`, jusqu'à ce qu'une fonction
  Sécurité ou Personnes réelle existe pour les filtrer ;
- les lignes à traiter étaient un `BentoTile` local `_Ligne`. Elles passent
  par `SignalRow` : icône, phrase, ancienneté, chevron, et un libellé parlé
  qui lie la phrase à l'ancienneté.

Deux écarts du registre à trancher, révélés par la relecture de la fiche, et
retenus **sans rien déplacer** dans le code, qui suit `parcours-utilisateurs.md`
(cadre du haut dans `docs/design/README.md` §3) :

- **six compteurs**, là où `parcours-utilisateurs.md` §5 et le README §7 en
  écrivent cinq : `demandes`, `ADM-06`, figure dans le code mais pas dans la
  liste produit. Choisir si le sixième reste, ou si le coup de pouce vers les
  demandes est porté par la liste à traiter seule ;
- **l'ordre** : le registre dit « Signaux puis chiffres » et `02-regles-ux.md`
  §2 place « ce que je dois traiter » en premier ; `parcours-utilisateurs.md`
  dit « Cinq indicateurs en haut, sous les chiffres une liste ». Le code rend
  les compteurs d'abord. Si la règle « les signaux d'abord » l'emporte, les
  compteurs passent sous la liste, et c'est une fiche refaite.

Dettes assumées :

- **le tirage-pour-rafraîchir disparaît**, même format et même sort que sur
  `TUT-01` et `ENS-02` : les trois providers d'`ADM-01` ne sont relus qu'au
  démarrage. Rétablissement propre = prise `onRafraichir` optionnelle de
  `PageShell`, à trancher explicitement. C'est le troisième écran qui la
  demande, le lot R en fait une dette commune ;
- **desktop pleine largeur de la liste** : non implémenté, la liste garde la
  gouttière du gabarit. Reporté, comme les autres multi-colonnes du lot R.

### `TUT-00` Connexion

```
CODE              TUT-00
Nom               Connexion
Role              Tous
Zone              Acces
Niveau de charge  A
Ecran parent      aucun : racine, seul ecran atteignable sans session
Profondeur        0
Question          Comment entrer, sans mot de passe a creer ni a retenir ?

Priorites         P0  envoyer un lien de connexion par courriel
                  P0  se connecter avec Google
                  P1  rejoindre l'entree eleve (ELV-01), un parcours different,
                      jamais une variante de celui-ci

Action principale     Recevoir le lien : actif des le premier affichage. Il
                      verifie l'adresse au moment ou l'on appuie et dit sous le
                      champ ce qui ne va pas
Actions secondaires   Se connecter avec Google, avec le logo Google. La SEULE
                      action a filet de l'ecran
Action tertiaire      Connecter l'appareil d'un eleve : ouvre une feuille
                      d'explication avant ELV-01, jamais l'ecran directement
Destructif            aucun

Mobile            Page centree, une carte
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200
                  La carte se centre verticalement quand la hauteur le permet,
                  et redevient defilante des qu'elle ne le permet plus

Etats             saisie      carte avec le champ courriel, etiquette AU DESSUS
                              du champ et texte d'invite a l'interieur
                  envoi       bouton en cours
                  lien envoye la carte est remplacee par la confirmation et un
                              bouton "changer d'adresse". Ne se ferme jamais
                              tout seul et ne compte pas a rebours
                  erreur      message sous le champ, avant l'envoi si le format
                              est invalide, apres l'envoi si le service refuse

Mouvement         aucun propre a l'ecran

Invariants        aucun mot de passe nulle part dans ce parcours
                  l'etat "lien envoye" ne se ferme jamais sur minuterie
                  seul ecran du produit atteignable sans session

Accessibilite     champ courriel avec l'autofill hint email, action clavier
                  "go" pour envoyer sans quitter le clavier
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, sans carte, sans ombre, sans marque :
  la cause n1 mesurée du rejet du 11 septembre (`docs/HANDOFF.md` section
  0 ter), parce que c'est le seul écran visible sans compte. Il passe par
  `PageShell` ;
- le formulaire flottait à même le fond crème. Il est posé sur `AppCard`
  (`surfaceRaised`, filet et ombre) ;
- une zone de marque (`MarquePage`, nouveau composant partagé) précède la
  carte : le nom du produit seul, en `inkAccent`, faute d'un asset de logo
  dans le dépôt.

Reprise faite le 19 septembre 2026. Trois défauts rapportés par l'opérateur, et
ce que la fiche change en conséquence :

- **« il y a des bordures sur chaque bouton ».** Les trois moyens d'entrer se
  lisaient au même poids : deux secondaires à filet de 2 points, et surtout le
  bouton principal **désactivé**, dont le filet fait 3 points — le plus épais de
  l'écran, sur l'action la plus importante, au premier affichage. La hiérarchie
  de la section 4 de `02-regles-ux.md` existait dans le composant mais pas sur
  l'écran. Elle y est : un aplat plein, **un seul filet**, un texte seul.
  L'entrée élève descend donc de secondaire à tertiaire — elle dit ainsi ce que
  le code affirmait déjà en commentaire, que c'est un parcours différent.
- **le bouton principal n'est plus inerte au repos.** La fiche demandait « jamais
  grisée sans raison dite » ; il était grisé et la raison ne s'affichait nulle
  part. Pire, la vérification d'adresse écrite dans l'écran ne pouvait jamais
  s'exécuter, le bouton étant mort avant d'être touché : c'était du code mort.
  Elle parle maintenant sous le champ, au moment de l'appui.
- **« le placeholder pour l'email semble désactivé ».** Deux causes, toutes deux
  dans le thème et non dans l'écran : l'étiquette flottante de Material se pose
  à l'intérieur du champ vide, en gris, là où l'œil attend une invite ; et
  `enabledBorder` et `disabledBorder` étaient **le même appel**, donc rien ne
  distinguait un champ qui attend une frappe d'un champ qui n'en acceptera
  jamais. L'étiquette monte au-dessus, l'invite descend dedans, et le filet
  inerte passe au plus faible de la rampe. Le correctif est global : le défaut
  l'était.
- **« J'ai un code ne veut rien dire ».** Le libellé ne disait ni à qui il
  s'adressait ni où trouver ce code. Il devient « Connecter l'appareil d'un
  élève » — verbe et objet, et le vocabulaire de rôle du produit. Le clic ouvre
  une feuille adressée au **tuteur** (`AppBottomSheet`) : pour qui, où générer le
  code — Foyer et appareils, puis le profil de l'élève, puis « Ajouter un
  appareil » —, sa validité de dix minutes et le plafond de deux appareils. Elle
  ne promet **jamais** de scanner : aucun lecteur n'existe dans cette version.
  `ELV-01`, lui, tutoie l'enfant ; les deux voix ne pouvaient pas tenir sur le
  même écran.

Le bouton Google porte désormais le logo Google (`LogoGoogle`, tracés officiels,
fichier propriétaire de ses couleurs de marque). Il ne se miroite pas en RTL,
comme tout logo (`06-accessibilite.md` section 5).

### `ELV-01` Connexion élève

```
CODE              ELV-01
Nom               Connexion eleve
Role              Eleve
Zone              Acces
Niveau de charge  B
Ecran parent      aucun : racine, parcours distinct de TUT-00 (ADR-005)
Profondeur        0
Question          Qui est-ce, et avec quel code personnel ?

Priorites         P0  sur un appareil deja appaire, retrouver son profil sans
                      ressaisir le code d'appairage
                  P0  creer ou saisir son code personnel, qui ne quitte jamais
                      l'appareil (ADR-005)
                  P1  premier appairage : saisir le code recu du tuteur

Action principale     Valider (appairage), ou le pave numerique lui-meme
                      (creation et saisie du code personnel)
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, le contenu change selon le moment
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats (moments successifs, jamais deux a la fois)
  chargement        texte de chargement, le temps de lire les profils connus
                    de l'appareil
  saisie du code    aucun profil connu : champ code (6 caracteres, majuscules),
                    bouton Valider inerte avant 6 caracteres
  choix du profil   des profils existent : une tuile par profil, composition
                    volontairement asymetrique
  creation du code  premier usage du profil sur cet appareil : le pave
                    numerique demande le code deux fois, un ecart efface la
                    premiere saisie et le dit
  saisie du code    le profil a deja un code : le pave numerique le demande.
  personnel         Une erreur du pave le dit sans relancer de saisie ailleurs
  code expire       le jeton d'appareil a ete revoque par le tuteur : le
                    profil disparait de la liste et un message le dit

Mouvement         aucun propre a l'ecran

Invariants        le code personnel ne quitte jamais l'appareil : aucun
                  service ne declare de parametre pour le recevoir (ADR-005)
                  sur un appareil deja appaire, l'ecran de saisie du code
                  d'appairage ne reapparait jamais
                  la comparaison du code personnel est locale, aucun appel
                  reseau ne recoit la saisie

Accessibilite     cibles larges sur les tuiles de profil (AvatarTile)
                  le pave numerique dit l'erreur sans redemander une saisie
                  de plus
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, cause n1 avec `TUT-00`. Il passe par
  `PageShell` ;
- chaque moment (saisie du code, choix du profil, pave numerique) flottait
  directement sur le fond crème. Le contenu du moment courant est posé sur une
  seule `AppCard`, comme sur `TUT-00` ;
- la même `MarquePage` que `TUT-00` précède la carte : les deux écrans du
  tunnel d'entrée partagent la même identité visuelle.

### `TUT-00c` Création de profil

```
CODE              TUT-00c
Nom               Creation de profil
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00 (atteint apres une premiere connexion sans profil)
Profondeur        1
Question          Qui es-tu, et quel role joues-tu dans le foyer ou l'ecole ?

Priorites         P0  le role (tuteur, eleve adulte qui est son propre tuteur,
                      ou enseignant) : ADR-009
                  P0  l'identite (prenom, nom)
                  P1  le genre, qui decide en base qui pourra lire une piece
                      d'identite plus tard (audit 1.3)
                  P1  un recapitulatif avant l'envoi

Action principale     Continuer (pages 1 a 3), Creer mon profil (page 4)
Actions secondaires   Retour (pages 2 a 4)
Action tertiaire      aucune
Destructif            aucun

Mobile            Parcours en quatre pages courtes, une question par page
                  (ADR-013), coquille PageParcours (retour, progression,
                  temps restant estime)
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             page 1 (role)      trois cartes cliquables + "Autre", qui
                                     renvoie vers l'academie sans inventer de
                                     role (ChoiceCardGroup)
                  page 2 (identite)  deux champs, Continuer inerte tant que
                                     les deux ne sont pas remplis
                  page 3 (genre)     deux cartes + "Autre", meme registre que
                                     la page 1
                  page 4 (recap)     trois lignes libelle/valeur, erreur
                                     d'envoi dite sous le bouton
                  envoi              bouton en cours

Mouvement         la barre de progression segmentee de PageParcours, pas de
                  mouvement propre a l'ecran

Invariants        le role declare ici n'accorde rien : la base ecrit
                  pending_kyc en dur, quoi que le client envoie
                  l'eleve adulte n'est pas un role de plus, c'est son propre
                  tuteur, un foyer d'une personne (ADR-009)
                  la carte "Autre" ne devine jamais un role ou un genre, elle
                  dit que le parcours ne convient pas

Accessibilite     une question par page : jamais un formulaire qui empile les
                  champs (ADR-013)
                  temps restant estime a chaque page, pour que l'incertitude
                  ne coute pas plus cher que la longueur
```

Aucune reprise : cet écran passait déjà par `PageParcours` avant le lot R0.
Seule sa fiche manquait, écrite ici à partir du code existant, comme le
demande la section 3.

### `TUT-00b` Portail d'attente

```
CODE              TUT-00b
Nom               Portail d'attente
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00 (session valide, profil cree, dossier incomplet)
Profondeur        0
Question          Qu'est-ce qui manque encore avant d'entrer dans l'app ?

Priorites         P0  dire exactement ce que l'administration voit, jamais un
                      calcul divergent recalcule a l'ecran (etat_dossier() en
                      base)
                  P0  l'action pour chaque piece manquante, une a une
                  P1  se deconnecter

Action principale     Selon la piece manquante : lire la carte d'accuse
                      (TUT-00c/a), signer le contrat (TUT-00c/b), deposer la
                      piece (TUT-00c/c)
Actions secondaires   Se deconnecter
Action tertiaire      Reessayer, seulement quand la lecture du dossier echoue
Destructif            aucun

Mobile            Page centree, une carte
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats (etat.etape, calcule en base par etat_dossier())
  incomplet         une BentoTile par piece manquante (accuse, contrat, piece
                    d'identite), chacune avec son bouton
  en verification   icone, "en cours d'examen", date de depot si connue, delai
                    indicatif
  refuse            le motif de refus en clair (la base ne renvoie jamais un
                    refus sans motif), bouton pour corriger
  suspendu          icone d'alerte, detail, "contacter l'academie"
  loading           texte de chargement
  error (lecture)   phrase d'erreur, bouton Reessayer : un etat de dossier
                    illisible ne se devine pas

Mouvement         aucun propre a l'ecran

Invariants        ne montre jamais l'application derriere un voile : dit ce
                  qui manque et rien d'autre
                  le calcul de l'etape vient de la base, jamais recalcule ici
                  une lecture qui echoue dit une phrase et laisse reessayer,
                  elle ne ferme jamais la deconnexion

Accessibilite     le message d'erreur de lecture est en liveRegion
                  la carte se lit de droite a gauche en arabe
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son propre tirage-pour-rafraîchir
  (`RefreshIndicator` invalidant `etatDossierProvider`). Il passe par
  `PageShell` ;
- le contenu (les quatre états `_Contenu`, `_Indisponible`, `_Patience`)
  flottait sur le fond crème. Il est posé sur une seule `AppCard` ;
- la même `MarquePage` que `TUT-00` et `ELV-01` précède la carte.

Dette assumée : **le tirage-pour-rafraîchir disparaît**, même sort que sur
`TUT-01`, `ENS-02` et `ADM-01` (voir leurs fiches) — `RefreshIndicator` posé
autour d'un `ListView` a besoin d'être l'enfant direct d'un `Expanded` pour ne
pas planter (hauteur non bornée), et `PageShell` en mode `defilante: false` ne
donne pas cette garantie à son `child`. C'est le quatrième écran qui la
demande. Le bouton « réessayer » de l'état d'erreur reste le seul moyen de
relire le dossier avant le prochain démarrage de l'application.

### `TUT-00c/a` Accusé enregistrement et contrôle

```
CODE              TUT-00c/a
Nom               Accuse enregistrement et controle
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Que faut-il savoir du dispositif d'enregistrement et de
                  controle, avant de l'accepter ?

Priorites         P0  les deux points en clair : enregistrement audio, visite
                      de controle possible (ADR-011)
                  P1  revenir au portail sans accepter

Action principale     "Compris" : accepte l'accuse et retourne au portail
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal    titre, deux points illustres (BentoTile + icone),
                              bouton dans la zone d'action
                  envoi      bouton en cours
                  erreur     message sous le titre, dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        vient avant le contrat, jamais apres : un dispositif decouvert
                  apres coup est un litige (ADR-011)
                  courte pour etre lue : deux points, pas un texte long

Accessibilite     le message d'erreur est en liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé (partagé avec `TUT-00c/b`, meme coquille
`_PageASigner` dans `signature_page.dart`) :

- l'écran montait son propre `Scaffold`, avec une zone d'action reimplementee
  a la main (`Padding` + `Column` + message d'erreur). Il passe par
  `PageShell`, dont c'est exactement le role (`actions:`) ;
- les points en clair flottaient dans un `ListView` a meme le fond crème. Ils
  sont poses sur une `AppCard` ;
- une `MarquePage` précède la carte.

### `TUT-00c/b` Contrat

```
CODE              TUT-00c/b
Nom               Contrat
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Quelles sont mes conditions, et les accepter ?

Priorites         P0  les points du contrat propre au role : enregistrement et
                      controle pour tous, occultation des coordonnees en plus
                      pour l'enseignant (ADR-008)
                  P1  revenir au portail sans accepter

Action principale     "Accepter" : accepte le contrat et retourne au portail
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal    titre, introduction, une BentoTile par point,
                              bouton dans la zone d'action
                  envoi      bouton en cours
                  erreur     message sous le titre, dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        le contenu depend du role (SorteContrat.pour(role)) : le
                  point sur l'occultation des coordonnees n'existe que pour
                  l'enseignant, c'est le controle anti-pillage de l'ADR-008
                  meme coquille que TUT-00c/a : deux ecrans du meme type de
                  page, pas deux implementations

Accessibilite     le message d'erreur est en liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0, même changement que
`TUT-00c/a` : `Scaffold` et zone d'action manuelle remplacés par `PageShell` et
sa prise `actions:`, contenu posé sur `AppCard`, `MarquePage` en tête.

### `TUT-00c/c` Dépôt de la pièce

```
CODE              TUT-00c/c
Nom               Depot de la piece d'identite
Role              Tuteur, enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      TUT-00b (une des pieces manquantes du dossier)
Profondeur        1
Question          Quelle piece, et laquelle envoyer ?

Priorites         P0  le type de piece (carte d'identite, passeport, titre de
                      sejour)
                  P0  choisir un fichier, borne a la taille maximale acceptee
                  P1  revenir au portail sans envoyer

Action principale     Envoyer : inerte tant qu'aucun fichier n'est choisi
Actions secondaires   Choisir un fichier : inerte tant qu'aucun type n'est
                      choisi
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, action collee en bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             nominal          titre, intro, ChoiceCardGroup des trois
                                    types, bouton secondaire "choisir un
                                    fichier"
                  fichier trop lourd  message sous le titre, avant meme la
                                    tentative d'envoi
                  fichier choisi   le bouton secondaire dit "Fichier choisi",
                                    le bouton Envoyer devient actif
                  envoi            bouton en cours, dans la zone d'action
                  erreur d'envoi   message dans la zone d'action

Mouvement         aucun propre a l'ecran

Invariants        le genre transmis avec la piece vient du profil, jamais
                  d'une saisie de plus : il decide quel membre du personnel
                  pourra la regarder (audit 1.3)
                  la borne de taille est verifiee avant l'envoi, jamais apres
                  plusieurs minutes de televersement

Accessibilite     les deux messages d'erreur (taille, envoi) sont en
                  liveRegion
```

Reprise faite le 11 septembre 2026, sous-lot R0. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, avec une zone d'action reimplementee
  a la main. Il passe par `PageShell` et sa prise `actions:`, comme
  `TUT-00c/a` et `TUT-00c/b` ;
- le contenu (question du type, `ChoiceCardGroup`, bouton "choisir un
  fichier") flottait dans un `ListView` a meme le fond crème. Il est pose sur
  une `AppCard` ;
- une `MarquePage` précède la carte.

### `TUT-02` Foyer et appareils

```
CODE              TUT-02
Nom               Foyer et appareils
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-01 (lien direct depuis l'accueil famille)
Profondeur        1
Question          Qui vit dans ce foyer, et quels appareils leur sont appaires ?

Priorites         P0  un bloc par enfant : ses appareils actifs
                  P0  revoquer un appareil
                  P1  ajouter un enfant
                  P1  ajouter un appareil, tant que la limite (ADR-010, deux
                      par enfant) n'est pas atteinte

Action principale     Ajouter un enfant (bas de liste) ; par enfant, Ajouter
                      un appareil
Actions secondaires   Revoquer un appareil (par ligne)
Action tertiaire      aucune
Destructif            aucun -- revoquer coupe l'acces de l'appareil, ca ne
                      supprime rien ; niveau secondaire, pas destructif

Mobile            Liste dense, un bloc par enfant
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "deux colonnes" au bureau ; non
                  implemente, ecart anterieur a ce lot, hors scope d'une
                  reprise de coquille

Etats             content         nominal
                  empty           aucun enfant dans le foyer (EmptyState,
                                  bouton "Ajouter un enfant")
                  limite atteinte le bouton "Ajouter un appareil" est
                                  remplace par une phrase, jamais desactive
                                  (invariant deja acquis, section 4)
                  aucun appareil  phrase seule, pas de liste vide dessinee

Mouvement         aucun propre a l'ecran

Invariants        a la limite de deux appareils, le bouton d'ajout est
                  remplace par une phrase (deja acquis, section 4)
                  la photo reelle ou le repli sur initiales, jamais une icone
                  d'erreur (ADR-012)

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`, un `OfflineBanner` posé à la main et
  un tirage-pour-rafraîchir (`RefreshIndicator` invalidant les deux providers
  du foyer) autour de son `ListView`. Il passe par `PageShell` ;
- **Dette assumée** : le tirage-pour-rafraîchir disparaît, même sort et même
  raison que sur `TUT-00b`, `TUT-01`, `ENS-02` et `ADM-01` (voir leurs
  fiches) — un `RefreshIndicator` autour d'un `ListView` a besoin d'être
  l'enfant direct d'un `Expanded` pour ne pas planter en hauteur non bornée,
  et `PageShell` ne donne pas cette garantie à son `child`. C'est le
  cinquième écran qui la demande.

### `TUT-02/a` Ajout d'un enfant

```
CODE              TUT-02/a
Nom               Ajout d'un enfant
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-02 (bouton "Ajouter un enfant"), aussi atteint depuis
                  TUT-05 quand le foyer est vide
Profondeur        2
Question          Qui est cet enfant, et quel age a-t-il ?

Priorites         P0  le prenom et le nom
                  P0  l'age, qui fixe en base le mode d'interface et la
                      politique camera initiale (ADR-009) -- jamais calcule
                      ici
                  P1  dire l'erreur si la creation echoue

Action principale     Creer (PageParcours), inerte tant que les trois champs
                      ne sont pas valides
Actions secondaires   Retour
Action tertiaire      aucune
Destructif            aucun

Mobile            Page unique de PageParcours (question, action, retour) ;
                  numero 1 sur 1, pas de barre de progression segmentee
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             saisie          nominal
                  age invalide    message d'erreur sous le champ age (hors
                                  3-18 ans), bouton Creer reste inerte
                  envoi           bouton en cours
                  erreur d'envoi  message en liveRegion sous l'action

Mouvement         coquille de PageParcours, aucun mouvement propre

Invariants        l'age ne decide de rien ici : le mode d'interface et la
                  politique camera sont derives en base depuis app_config,
                  jamais dans ce code
                  le seuil d'age est un reglage d'academie, pas une constante
                  d'application

Accessibilite     le message d'erreur d'envoi est en liveRegion
```

Aucune reprise : cet écran passait déjà par `PageParcours` avant le lot R4.
Seule sa fiche manquait, écrite ici à partir du code existant, même cas que
`TUT-00c` au lot R0.

### `TUT-02/b` Appairer un appareil

```
CODE              TUT-02/b
Nom               Appairer un appareil
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      TUT-02 (bouton "Ajouter" d'un enfant)
Profondeur        2
Question          Comment cet appareil rejoint-il le foyer ?

Priorites         P0  le QR grand format et le code en clair, lisibles a
                      distance
                  P0  le delai de validite qui s'ecoule, annonce en clair
                  P1  pouvoir regenerer un code expire

Action principale     aucune sur le QR lui-meme -- Regenerer (code expire) ou
                      Reessayer (erreur), seuls boutons du corps
Actions secondaires   Retour, dans la zone d'action collee en bas
                      (PageShell.actions)
Action tertiaire      aucune
Destructif            aucun

Mobile            Page centree, une carte, QR grand format, retour colle en
                  bas
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200

Etats             chargement   texte de chargement, le temps de creer le code
                  code actif   QR + code en clair + compte a rebours
                               (Semantics liveRegion)
                  code expire  message + bouton Regenerer
                  erreur       message + bouton Reessayer

Mouvement         aucun propre a l'ecran

Invariants        le code n'existe qu'a l'ecran, la base n'en garde que
                  l'empreinte -- quitter l'ecran le perd, comportement attendu
                  le QR ne porte que le code, ni identifiant de foyer ni
                  adresse

Accessibilite     le compte a rebours est en liveRegion ; le code en clair a
                  un libelle parle, espace lettre par lettre
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold`. Il passe par `PageShell` ;
- le bouton de retour, collé en bas à la main dans un `Padding` hors
  `Scaffold`, passe par la prise `actions:` de `PageShell` — même correction
  que les feuilles d'accueil du lot R0 (`TUT-00c/a`, `TUT-00c/b`,
  `TUT-00c/c`).

### `TUT-04` Disponibilités du foyer

```
CODE              TUT-04
Nom               Disponibilites du foyer
Role              Tuteur
Zone              Disponibilites et affectation
Niveau de charge  C
Ecran parent      aucun : onglet de la navigation tuteur, atteint depuis la
                  barre
Profondeur        1
Question          Quand chaque enfant du foyer est-il disponible pour un
                  cours ?

Priorites         P0  une grille de semaine par enfant, case par case
                  P0  dire ce que la grille produit (elle alimente le
                      matching inverse)
                  P1  le repli quand le foyer n'a aucun enfant

Action principale     aucune globale -- chaque case de GrilleSemaine est
                      l'action elementaire (tap = pose ou retire un creneau)
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            Une carte par enfant, une grille par carte, la page defile
                  verticalement
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "grille entiere" au bureau ; GrilleSemaine
                  ne defile jamais horizontalement (pas de Viewport), la
                  distinction n'a jamais eu de code a elle

Etats             content    nominal
                  empty      aucun enfant dans le foyer (EmptyState)
                  error      erreur d'enregistrement d'une case (message sous
                             la grille, la grille reste utilisable)
                  en cours   une case en ecriture n'accepte plus de tap

Mouvement         retour haptique de la case (Pressable), aucun mouvement
                  propre a l'ecran

Invariants        GrilleSemaine est le meme composant, au sens litteral, que
                  celui d'ENS-06 -- deux grilles jumelles finiraient par ne
                  plus afficher la meme chose (ADR-017)
                  l'etat d'ecriture ne se filtre jamais par type d'execution
                  de l'AsyncValue

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son `ListView`. Il passe par
  `PageShell` ; pas de tirage-pour-rafraîchir à perdre ici, il n'y en avait
  pas.

### `TUT-05` Réglages par enfant

```
CODE              TUT-05
Nom               Reglages par enfant
Role              Tuteur
Zone              Foyer
Niveau de charge  C
Ecran parent      aucun : onglet de la navigation tuteur, atteint depuis la
                  barre
Profondeur        1
Question          Que faut-il changer pour cet enfant avant la prochaine
                  seance ?

Priorites         P0  une carte par enfant : photo, camera, mode d'interface
                  P0  le texte dit la consequence en clair, avec le prenom
                      (jamais un libelle abstrait)
                  P1  les trois demandes que le tuteur peut deposer
                      (reaffectation, duree, minimum payable)

Action principale     par carte : Ajouter/Changer la photo ; Autoriser/
                      Retirer la camera ; Passer standard/enfant
Actions secondaires   Demander une reaffectation (si un enseignant suit
                      l'enfant), la duree de seance, le minimum payable --
                      chacune ouvre une feuille
Action tertiaire      aucune
Destructif            aucun

Mobile            Une carte par enfant, verticale
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "2 colonnes" au bureau ; non implemente,
                  ecart anterieur a ce lot, hors scope d'une reprise de
                  coquille

Etats             content   nominal
                  empty     aucun enfant dans le foyer (EmptyState, bouton
                            "Ajouter un enfant")
                  error     par geste (photo, reglage, demande), message sous
                            le bouton concerne, jamais un etat de page

Mouvement         aucun propre a l'ecran

Invariants        ces reglages s'appliquent a la seance suivante, jamais
                  pendant un cours en direct (dit une fois en tete, pas
                  repete par carte)
                  aucune copie locale optimiste : ce que la base a accepte
                  est ce qui s'affiche
                  la carte "reaffectation" n'apparait que si un enseignant
                  suit deja l'enfant

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` et son `ListView`. Il passe par
  `PageShell` ;
- la feuille `FeuilleDemandeTuteur` (bottom sheet) garde son `Padding` manuel
  dupliqué — dette déjà connue depuis le lot B0 (`docs/HANDOFF.md` section
  0 ter, point 3), pas traitée ici, hors scope.

### `ENS-06` Disponibilités et matching

```
CODE              ENS-06
Nom               Disponibilites et matching
Role              Enseignant
Zone              Disponibilites et affectation
Niveau de charge  D
Ecran parent      aucun : onglet de la navigation enseignant, atteint depuis
                  la barre (aussi depuis ENS-02, bloc matching)
Profondeur        1
Question          Quand suis-je libre, et qui attend un enseignant ?

Priorites         P0  la grille de mes disponibilites
                  P0  le feed des eleves en attente, trie par anciennete
                  P1  le nombre de places restantes sur mon plafond
                  P1  l'acces a la demande d'augmentation de plafond

Action principale     Prendre un eleve
Actions secondaires   Poser ou retirer un creneau (case de GrilleSemaine)
Action tertiaire      Demander une augmentation de plafond
Destructif            aucun

Mobile            deux onglets (Heures, Eleves), un seul panneau visible,
                  PageShell.entete porte le TabBar -- pas de balayage au
                  doigt entre onglets : le contenu bascule sur l'index du
                  TabController au tap (voir Invariants)
Tablette          pas d'onglet : la grille puis le feed, empiles dans une
                  seule colonne defilante
Desktop           pas d'onglet : la grille a gauche, le feed a droite, cote a
                  cote dans une Row

Etats             loading         texte de chargement, le temps que la
                                  session livre l'identifiant
                  content         nominal
                  empty           aucune famille en attente sur vos creneaux,
                                  sans bouton (l'enseignant ne peut rien y
                                  faire)
                  error           message sur le feed ou sous la grille,
                                  chaque panneau reste utilisable
                                  independamment de l'autre
                  offline         grille consultable, prise impossible et
                                  dite (OfflineBanner, deja porte par
                                  PageShell)
                  plafond atteint le bouton Prendre n'est pas rendu, une
                                  phrase l'explique, avec l'acces a la
                                  demande d'augmentation

Mouvement         retour haptique de la case (Pressable) ; aucun mouvement
                  propre a la bascule d'onglet (pas de PageView, donc pas de
                  transition animee entre panneaux)

Invariants        le tri est par anciennete d'attente, jamais alphabetique
                  le feed rend une ligne par creneau compatible, pas par
                  eleve : compter les lignes annoncerait quatre familles la
                  ou une seule attend
                  pas de TabBarView : il s'appuie sur un PageView, qui exige
                  une hauteur bornee, et PageShell ne borne jamais la hauteur
                  de son child -- c'est la page entiere qui defile, meme
                  mecanique que le reste du produit
                  a partir de la tablette, la grille et le feed se voient a
                  la fois : un onglet sur un ecran large cacherait la moitie
                  de l'information sans raison

Accessibilite     cases de grille a 44 minimum, label parle "Lundi 17 heures,
                  disponible"
                  grille lisible de droite a gauche en arabe (a revoir au lot
                  A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé — **l'écart du registre (section 2), corrigé** :

- l'écran montait un `DefaultTabController` et un `Scaffold` propres, avec un
  `TabBar` et un `TabBarView` fixes, quel que soit le gabarit. À partir de la
  tablette, la grille et le feed se voient désormais tous les deux, sans
  onglet ;
- sur mobile, les deux onglets restent, mais sans `TabBarView` : `PageShell`
  ne borne jamais la hauteur de son `child`, condition que `TabBarView` (un
  `PageView`) exige. Le panneau bascule directement sur l'index du
  `TabController`, ce qui coûte le balayage au doigt entre onglets, gardé au
  tap seul ;
- `CreneauxPage` passe de `ConsumerWidget` à `StatelessWidget` : elle ne lit
  plus aucun provider elle-même, elle choisit seulement la présentation selon
  `AppGabarit.de(context)` ;
- les deux onglets internes (`_OngletHeures`, `_OngletEleves`) passaient
  chacun par leur propre `ListView`. Ils passent par `Column`, comme les
  autres écrans de ce lot : c'est désormais la page entière (ou la colonne du
  panneau, sur tablette et desktop) qui défile, jamais un `Viewport` imbriqué.

### `ADM-02` Validation des dossiers

```
CODE              ADM-02
Nom               Validation des dossiers
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun : onglet de la navigation admin, atteint depuis la
                  barre (aussi depuis le compteur "dossiers" de ADM-01)
Profondeur        1
Question          Ce dossier est-il complet et lisible, et faut-il
                  l'approuver ?

Priorites         P0  un dossier a la fois, jamais une grille (attention
                      sequentielle)
                  P0  la checklist des trois constats avant tout jugement
                      (lisible, nom, validite)
                  P0  le motif obligatoire d'un refus
                  P1  combien de dossiers restent apres celui-ci

Action principale     Approuver (inerte tant que les trois constats ne sont
                      pas coches)
Actions secondaires   Refuser (ouvre le champ de motif)
Action tertiaire      Reessayer (lecture de la file en erreur, ou genre du
                      lecteur inconnu)
Destructif            Refuser un dossier (niveau destructif, motif
                      obligatoire)

Mobile            Colonne unique : apercu du document, checklist, verdict,
                  dans cet ordre
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "file a gauche, dossier a droite" ; non
                  implemente, ecart anterieur a ce lot, hors scope d'une
                  reprise de coquille

Etats             content   nominal (piece deposee, en attente de verdict)
                  sans piece  la personne est inscrite mais n'a rien depose :
                            son etat est dit, l'anciennete de l'inscription
                            avec, et NI checklist NI verdict ne sont rendus
                            (ajoute le 18/09, migration 0015)
                  hors portee  une piece existe mais la regle de genre
                            interdit de la lire : dit comme tel, et jamais
                            confondu avec une absence de piece
                  empty     aucun dossier en attente (EmptyState)
                  error     genre du lecteur inconnu (message specifique,
                            pas de bouton Reessayer : ce n'est pas
                            transitoire) ou erreur de lecture generique
                            (bouton Reessayer)
                  loading   texte de chargement

Mouvement         aucun propre a l'ecran

Invariants        constat -> checklist -> verdict, jamais melanges : le
                  verdict reste dans le corps defilant de PageShell et
                  jamais dans sa zone actions: -- une zone actions collee en
                  bas detacherait le jugement du constat qu'il suit
                  (section 4 de ce document)
                  une ligne de cette file est une PERSONNE, pas un document
                  (migration 0015). Avant elle, une personne inscrite sans
                  piece n'existait pour aucun ecran, et trois enseignants ont
                  attendu sept jours pendant que le compteur affichait zero
                  rien a constater => rien a trancher : sans piece lisible,
                  aucun verdict n'est propose. La base refuserait le geste, et
                  un bouton qui echoue apres coup coute plus cher qu'un bouton
                  absent (meme choix que la carte "aucune heure proposee"
                  d'ADM-05)
                  le cloisonnement de genre n'est pas applique ici : il vit
                  dans read_kyc_documents(), en base
                  Riverpod 3 : lire hasError/hasValue par getter, jamais le
                  type d'execution de l'AsyncValue

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` autour du même `switch` sur
  `AsyncValue`. Il passe par `PageShell` ;
- la zone de verdict (checklist puis approuver/refuser) reste délibérément
  dans le corps défilant, **pas** dans `PageShell.actions` : contrairement
  aux écrans à action unique du lot R0, la séquence constat→checklist→verdict
  doit rester lisible de haut en bas en une seule colonne (invariant déjà
  noté section 4, "Constat et jugement séparés").

### `ADM-06` Demandes et règles

```
CODE              ADM-06
Nom               Demandes et regles
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      ADM-01 (compteur "demandes")
Profondeur        1
Question          Cette demande doit-elle etre accordee, et que dit la regle
                  du profil concerne ?

Priorites         P0  une demande a la fois, la plus ancienne en premier
                  P0  la feuille de regles du sujet, plateforme et effective
                      cote a cote
                  P0  le motif obligatoire d'un refus
                  P1  changer ou clore une regle a la volee, sans qu'une
                      demande existe

Action principale     Accorder
Actions secondaires   Refuser (ouvre le motif) ; Changer / Clore une regle
                      depuis la feuille
Action tertiaire      Reessayer (lecture de la file en erreur)
Destructif            Refuser une demande (motif obligatoire)

Mobile            Colonne unique : constat de la demande, feuille de regles,
                  verdict
Tablette          Identique
Desktop           Identique, colonne centree et bornee a 1200 -- le registre
                  section 1 annonce "liste + feuille de regles" ; non
                  implemente, meme ecart et meme raison qu'ADM-02

Etats             content   nominal
                  empty     aucune demande en attente
                  error     lecture hors ligne (bouton Reessayer)
                  loading   texte de chargement

Mouvement         aucun propre a l'ecran

Invariants        meme sequence constat -> jugement qu'ADM-02, meme raison de
                  garder le verdict dans le corps defilant plutot que dans
                  PageShell.actions
                  chaque regle vient de la meme ligne de regles_profil_v,
                  jamais deux lectures separees qui finiraient par diverger
                  une surcharge close ne se supprime jamais (historique)

Accessibilite     non revue par ce lot (report au lot A1)
```

Reprise faite le 11 septembre 2026, sous-lot R4. Ce que le code portait avant,
et que la reprise a corrigé :

- l'écran montait son propre `Scaffold` autour du même `switch` sur
  `AsyncValue`. Il passe par `PageShell` ;
- la zone de verdict reste, pour la même raison qu'`ADM-02`, dans le corps
  défilant et pas dans `PageShell.actions` ;
- `FeuilleRegle` (bottom sheet) garde aussi son `Padding` manuel dupliqué,
  même dette que `TUT-05`.

### `ADM-05` Attribution manuelle

```
CODE              ADM-05
Nom               Attribution manuelle
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      ADM-01 (compteur "foyers sans enseignant")
Profondeur        1
Question          A quel enseignant confier cet enfant que personne n'a pris ?

Priorites         P0  deux listes, jamais un formulaire : eleves a gauche,
                      enseignants a droite, confirmation dessous
                  P0  l'anciennete d'attente ordonne la colonne de gauche
                  P0  l'eleve sans creneau reste visible ET non selectionnable,
                      avec la raison ecrite
                  P0  l'enseignant qui ne partage aucune heure reste dans la
                      liste, apres les autres : sans lui l'ecran serait vide le
                      jour ou l'on en a besoin
                  P0  le motif obligatoire hors disponibilite (ADR-021)
                  P1  l'heure evidente est preselectionnee : deux taps

Action principale     Attribuer X a Y
Actions secondaires   Choisir un autre eleve (repli mobile) ; choisir l'heure
                      quand plusieurs sont possibles
Action tertiaire      Reessayer (lecture en erreur)
Destructif            aucun -- une affectation se defait par ADM-06, jamais ici

Mobile            Deux listes empilees. La file cede la place des qu'un eleve
                  est choisi : empiler deux listes longues obligerait a
                  chercher sous le pli ce que le premier tap vient de faire
                  apparaitre
Tablette          Deux colonnes cote a cote
Desktop           Identique

Etats             content   nominal
                  empty     aucun eleve sans enseignant ; aucun eleve choisi
                            (colonne de droite)
                  error     lecture hors ligne des deux cotes, separement
                  loading   Skeleton.liste -- premier ecran du produit a
                            employer le composant (bible section 18)

Mouvement         aucun propre a l'ecran

Invariants        l'heure vient TOUJOURS des creneaux de la famille, jamais de
                  l'enseignant ni de l'administration
                  un enseignant au plafond n'est pas selectionnable, il n'est
                  pas grise apres le geste
                  changer d'eleve remet a zero enseignant, heure et motif
                  aucune ecriture directe dans teacher_student_assignments :
                  ADM-05 appelle attribuer_eleve(), comme ENS-06 appelle
                  prendre_eleve()

Accessibilite     cartes selectionnables via AppCard (Pressable : focus,
                  survol, cible tactile), libelle semantique porte le nom
```

Construit le 12 septembre 2026, hors série, pendant que le lot N2 de l'étape 5
attendait la décision du fournisseur vidéo. Sept tests de widget et neuf
contrôles SQL (`supabase/tests/scenarios_adm05.sql`) le tiennent.

Deux conséquences hors de l'écran lui-même :

- le compteur « Foyers sans enseignant » d'`ADM-01` mène désormais ici. Il ne
  menait nulle part depuis le lot L3, faute d'écran d'action ;
- `parcours-utilisateurs.md` §5 annonçait « attribution en deux taps ». Elle
  l'est quand une seule heure est possible, et **seulement** dans ce cas : avec
  deux heures communes, choisir à la place de l'administration reviendrait à
  poser une heure de cours par défaut.

### `ADM-04` Journal d'audit

```
CODE              ADM-04
Nom               Journal d'audit
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      aucun. Quatrieme destination du menu admin
Profondeur        1
Question          Qui a fait quoi, quand -- et personne n'y a-t-il touche depuis ?

Priorites         P0  la liste, la plus recente d'abord, paginee
                  P0  trois filtres : acteur, type d'evenement, periode
                  P0  AUCUN bouton qui ecrive, nulle part
                  P0  l'etat de la chaine de hachage, en tete
                  P1  le detail de l'entree, borne a trois couples
                  P2  charger les entrees plus anciennes

Action principale     AUCUNE. Seul ecran du produit dans ce cas, et c'est le
                      sujet : la seule chose qu'on puisse faire d'un journal
                      immuable, c'est le lire
Actions secondaires   filtrer ; charger la suite
Action tertiaire      effacer les filtres (depuis l'etat vide seulement)
Destructif            aucun, et par construction : audit_logs refuse update et
                      delete par declencheur depuis 0001

Mobile            Cartes : le type d'evenement en titre, quand/qui/role/cible
                  sur la ligne secondaire, le detail sur sa propre ligne
Tablette          Cartes, identique
Desktop           Tableau dense, en-tete collee en haut. C'est sa forme
                  naturelle (05-regles-responsive.md section 3)

Etats             loading   Skeleton.liste -- deuxieme ecran du produit a
                            employer le composant, apres ADM-05
                  content   nominal
                  empty     aucun evenement : registre BONNE NOUVELLE, sans
                            bouton. Sous filtre : registre actionnable, avec
                            « effacer les filtres »
                  error     message + reessayer. Une page SUIVANTE en echec
                            n'efface pas ce qui est deja lu
                  offline   bandeau de PageShell

Mouvement         aucun propre a l'ecran

Invariants        l'ordre est chronologique inverse, jamais autre chose
                  un changement de filtre relit depuis le debut : garder les
                  entrees deja lues melangerait deux filtres dans une liste
                  la pagination est un keyset (created_at, id), jamais un
                  offset : le journal recoit des lignes pendant qu'on le lit
                  un type d'evenement inconnu s'affiche TEL QUEL, jamais
                  masque : le vocabulaire vit en base et grandira
                  une entree sans acteur humain est nommee « Le systeme », un
                  compte clos « Compte supprime ». Jamais une case vide
                  la verification de chaine ne voyage pas avec la liste, elle
                  a sa propre lecture (voir ADR-022)

Accessibilite     chaque cellule du tableau porte le titre de sa colonne dans
                  son libelle parle : Flutter n'associe pas un en-tete a ses
                  cellules comme le ferait un <th>
                  chaque carte se lit comme un seul element (MergeSemantics)
                  les pilules de filtre portent l'etat « selectionne »
```

Construit le 12 septembre 2026. Treize tests de widget, trois tests unitaires
et neuf contrôles SQL (`supabase/tests/scenarios_adm04.sql`) le tiennent.

Trois conséquences hors de l'écran lui-même :

- **`DataCollection` existe enfin.** Il était au catalogue des composants en P1
  depuis la refonte, « nécessaire avant l'étape 5 », et n'avait jamais été
  construit faute d'écran dont la forme naturelle soit un tableau. `ADM-04`
  était cet écran ;
- **`FilterPill` est né ici**, hors de la liste d'origine, et a été inscrit au
  catalogue comme `MarquePage` avant lui ;
- **la chaîne de hachage de `audit_logs` est relue pour la première fois.**
  Elle existait depuis l'étape 1, et chaque écriture payait un `lock table`
  pour la tenir : le prix était payé, la garantie jamais constatée. Détail et
  arbitrage : **ADR-022**.

### `ELV-03` / `ENS-03` / `CTR-02` La salle

**Les trois codes sont un seul écran, et c'est la première décision de la
fiche.** Ce qui les distingue ne vient pas du rôle de session, que le client
porte, mais du **jeton** émis par `create-room-token` : son champ `role` et ses
capacités signées (`can_publish`, `can_publish_video`, `hidden`). Un écran qui
choisirait sa vue d'après `sessionProvider.role` déciderait d'après une valeur
que le client peut avoir mal lue ; le jeton, lui, est ce que le serveur LiveKit
fera respecter de toute façon. Trois écrans séparés auraient par ailleurs
divergé sur le bandeau permanent, qui est exactement ce que l'ADR-011 interdit.

Le jeton porte **quatre** rôles, pas trois : `participant_role` vaut `teacher`,
`student`, `guardian_observer` ou `masked_controller`. Le quatrième code manquait
au registre : le tuteur qui presse « Assister » depuis `TUT-01` entre en
observateur muet et **visible**, là où le contrôleur entre invisible. Il n'a pas
de code d'écran propre parce qu'il n'a pas d'écran propre : c'est `ELV-03` sans
aucune commande de publication.

```
CODE              ELV-03, ENS-03, CTR-02
Nom               La salle
Role              Eleve, enseignant, tuteur observateur, controleur
Zone              Journee et salle
Niveau de charge  B / C (eleve), D (enseignant, controleur)
Ecran parent      aucun. HORS ARBRE : ni barre basse, ni rail, ni retour
Profondeur        hors arbre
Question          Mon cours a lieu maintenant : est-ce que j'y suis, est-ce que
                  l'autre y est, et qu'est-ce que j'entends ?

Priorites         P0  le flux de l'autre, en grand
                  P0  micro, camera, quitter -- selon ce que le jeton permet
                  P0  le bandeau permanent, jamais masque (ADR-011)
                  P0  dire l'etat de la connexion en mots, jamais en couleur
                  P1  la liste des participants (enseignant, controleur)
                  P2  le document partage et les controles de page (lot N5)

Action principale     AUCUNE au sens du bouton plein : la salle est un lieu, pas
                      un formulaire. Les commandes sont des controles egaux
Actions secondaires   ouvrir ou fermer le micro ; ouvrir ou fermer la camera
Action tertiaire      aucune
Destructif            quitter, et c'est le seul geste confirme de l'ecran

Mobile            Une seule scene : le flux dominant plein cadre, la vignette
                  locale posee dessus, en bas de la zone. Bandeau puis
                  commandes sous la scene
Tablette          Idem, plus la colonne des participants pour l'enseignant et
                  le controleur
Desktop           Idem tablette, vignette locale plus grande

Etats             loading   demande de jeton en cours, puis pre-vol : un mot par
                            etape, jamais un squelette -- il n'y a aucune forme
                            de contenu a preparer
                  content   connecte. Sous-etat : seul en salle, qui se dit
                  empty     seul en salle : « n'est pas encore arrive »
                  error     quatre refus distincts, un message par cause
                  offline   AUCUN bandeau hors ligne : c'est LiveKit qui sait,
                            et deux signaux concurrents se contrediraient

Mouvement         aucun propre a l'ecran. Le mouvement d'encouragement de la
                  sortie (fiche produit) attend le lot de la presence : il
                  annoncerait un cours fini, ce que N3 ne sait pas encore

Invariants        le bandeau permanent est le MEME pour les quatre roles, sans
                  parametre : PermanentNotice n'en accepte aucun
                  micro et camera FERMES a l'entree, pour TOUS les roles. Un
                  tap les ouvre
                  un controle que le jeton refuse N'EST PAS RENDU, jamais grise
                  le controleur ne figure PAS dans sa propre liste de
                  participants : il voit deux personnes, comme l'enseignant.
                  C'est le test visuel de l'invisibilite
                  la qualite du lien se dit en mots. Une pastille seule ne
                  represente jamais un etat critique
                  aucune URL LiveKit, aucun import du SDK hors de
                  livekit_session_provider.dart

Accessibilite     chaque commande porte le libelle de son ACTE (« Ouvrir le
                  micro »), jamais celui de son etat
                  chaque vignette se lit comme un element unique : nom, role,
                  micro, image
                  cible tactile du mode courant, 72 en mode enfant
```

**Le bandeau permanent est en bas, sous la scène.** Les deux sources se
contredisaient : la fiche produit dit « bandeau permanent en bas de salle »,
`etape-5-salle-coran-presence.md` §7 dit « en haut ». La fiche produit tranche,
pour une raison matérielle : en haut, le bandeau entre en concurrence avec la
zone média dominante et, sur téléphone, avec l'encoche et le geste de retour.
En bas, il touche les commandes, c'est-à-dire l'endroit que l'on regarde quand
on décide d'ouvrir son micro.

**Ce que N3 ne construit pas, et pourquoi ce n'est pas un oubli :**

- **le document partagé et les contrôles de page de niveau 1.** Ils n'ont ni
  contenu à paginer (le Coran est le lot N5, et son jeu de données n'est pas
  importé) ni canal de diffusion tranché (question `e` du §10 de la spécification
  d'étape : LiveKit data, Supabase Realtime, autre). Les livrer maintenant
  donnerait à l'enseignant des boutons qui tournent des pages que l'élève ne
  verrait pas : un produit qui ment. La zone n'est donc pas rendue du tout, et
  le bouton « Ouvrir le Coran » **n'existe pas** plutôt que d'être grisé, par la
  règle déjà appliquée au bouton caméra ;
- **les quatorze états de présence.** C'est le lot N4. La salle dit l'état de sa
  **connexion** temps réel, ce que LiveKit sait, et rien de ce que la base
  dérive. L'invariant J3 (« un état de présence indisponible s'affiche comme
  inconnu ») n'a donc encore rien à borner ici ;
- **`ENS-03` vers `ENS-04`.** L'invariant du §4 exige que la sortie de
  l'enseignant mène au cahier de transmission, et rien d'autre. `ENS-04` est
  l'étape 6 : aucune route n'existe. La sortie mène donc à `ENS-02`, et **cet
  écart est ouvert**, nommé ici plutôt que masqué par une route vide qui
  prétendrait tenir l'invariant.

Construit le 12 septembre 2026, lot N3. Il remplace le plus gros
`EcranAConstruire` du routeur : il reste **six** écrans à construire.

#### Ce que le lot `N4` y ajoute, le 13 septembre 2026

La fiche ci-dessus ne change pas : **N4 étend la salle, il ne la réécrit pas.**
Trois ajouts, et une correction.

```
Priorites   P0  l'etat de presence personnel de l'eleve, permanent (section 6.6)
            P1  le tableau de presence des inscrits (enseignant, controleur)

Mobile      L'eleve : sa presence sous la pastille de connexion, en mots.
            L'enseignant : un bouton « Presence » dans l'entete, qui ouvre
            la liste en feuille -- consultable, jamais imposee
Tablette    La colonne laterale porte la presence, et non plus la seule liste
            des participants connectes
```

**La liste change de nature, et c'est la décision du lot.** Elle était bâtie sur
les participants que le moteur temps réel publie ; elle est désormais bâtie sur
les **inscrits**, avec l'état de chacun. La raison est celle qui justifiait N4 :
celui qui n'est jamais arrivé n'a aucune piste LiveKit, donc aucune ligne côté
moteur — et c'est précisément de lui que l'enseignant a besoin de savoir quelque
chose. L'état du micro reste affiché, mais seulement pour qui est réellement
dans la salle : un micro barré à côté de « Pas encore là » dirait deux fois la
même chose, et la deuxième serait fausse.

**Deux faits distincts, deux lignes.** La pastille du haut dit l'état de la
**connexion** temps réel, ce que le moteur sait ; celle de la présence dit ce
que la base dérive. On peut être parfaitement connecté et noté « en retard », et
avoir perdu le lien depuis dix secondes sans être encore noté « déconnecté ».
Les confondre en une seule pastille aurait été faux.

**Le tuteur observateur ne lit ni l'un ni l'autre.** Il assiste : il n'a pas
d'état pédagogique à consulter, et la liste ne lui est pas due. Le suivi d'un
enfant est `TUT-06`, à l'étape 6.

**Invariants ajoutés à la fiche :**

```
Invariants  un etat de presence indisponible s'affiche INCONNU, jamais
            « absent » -- les deux ne disent pas la meme chose, et l'un
            compte pour le suivi quand l'autre ne compte pour rien (J3)
            une couleur seule ne represente jamais un etat de presence : la
            pastille porte toujours son mot, et sa duree quand il y en a
            une (J7)
            l'eleve ne lit QUE son propre etat -- la borne est en base, pas
            dans l'ecran
            une visite de controle ne laisse AUCUNE ligne de presence
            lisible, pas meme a l'interesse (ADR-011)
```

**La correction.** `presence_seance_v`, posée au lot N1, n'avait **aucun filtre
d'appelant** — alors que les trois vues d'exposition de `0001` en portent toutes
un. Une vue appartenant à `postgres` sans `security_invoker` ne voit pas la RLS
des tables qu'elle lit : tout compte authentifié y aurait lu la présence de
toutes les séances de la plateforme. Mesuré sur les fixtures de
`scenarios_n4.sql` : un élève inscrit à aucune des deux séances y lisait **6
lignes sur 6** ; il en lit **0** depuis la migration `0011`. Rien n'a fuité — il
n'existe aucune séance en base — et le défaut n'avait jamais été exercé parce
qu'aucun écran ne lisait la vue. **Une vue sans écran est une vue non testée**,
c'est la leçon de N3 une seconde fois.

**Ce que N4 ne construit pas :** le **geste** de correction manuelle
(`corrigee_manuel`) et le marquage `excusee`. La table et ses policies existent
depuis `0007`, mais l'écran qui les déclenche demande une confirmation, un motif
obligatoire et une entrée de journal — c'est un lot, pas une ligne, et la
spécification d'étape §6.5 laisse d'ailleurs ce mécanisme explicitement ouvert.
N4 **affiche** la consolidation ; il ne la prononce pas.

### Surface propriétaire de correction de présence

Cette surface est réservée aux capacités serveur `peutCorriger` et
`peutExcuser`, sans lire un rôle dans le widget. Elle reçoit une ligne de
présence déjà bornée, un adaptateur typé et les libellés de l'intégration. Elle
propose `corrigee_manuel` et `excusee` lorsque la capacité correspondante est
présente ; aucune action n'est rendue pour une capacité absente ou hors ligne.

Chaque décision ouvre une confirmation explicite avec le participant, l'état
demandé et un motif obligatoire. Le panneau montre la mutation en cours, ne
déclare le succès qu'après le retour de l'adaptateur, conserve la ligne lue
pendant l'attente, puis expose un état succès ou erreur récupérable. Le motif
n'est pas affiché dans la ligne de présence : il appartient au contrat serveur
et au journal d'audit.

L'implémentation UI isolée vit dans `lib/features/presence_correction/` et
n'ajoute aucune route. Elle reste raccordable à la salle enseignant ou à
l'espace administration après livraison du contrat serveur.

Deux conséquences hors de l'écran :

- **`PageImmersive` existe**, dans `lib/core/widgets/`, et rejoint le catalogue
  des composants. C'est la coquille des écrans qui n'ont ni titre, ni gouttière,
  ni page : la salle aujourd'hui, `ELV-04` au lot N5. Sans elle, la salle aurait
  monté un `Scaffold` nu, c'est-à-dire exactement le défaut mesuré sur le tunnel
  d'entrée le 11 septembre ;
- **un défaut de `N2` est corrigé.** `LiveKitSessionProvider.rejoindre()` ouvrait
  le micro dès l'entrée « la voix d'abord ». C'était contraire à l'invariant du
  §4, présent au catalogue depuis la refonte et écrit deux fois dans la fiche
  produit : à l'entrée, rien ne publie tant que personne n'a tapé. Le défaut
  était invisible sans écran pour l'exercer.

---

### `ELV-04` Le Coran

**Le premier écran du produit dont le contenu n'est pas de l'interface.** Tous
les autres présentent des données de l'application ; celui-ci présente un texte
qui existait avant elle, et cela renverse trois habitudes du dépôt.

La première est visuelle : le motif « carte sur fond crème », pris à tous les
écrans des lots R, **s'inverse ici délibérément**. La Bible §22 l'impose,
`CONTENT > CHROME`, et §5.3 de la spécification d'étape l'écrit sans détour : le
Coran ne se traite jamais comme une `AppCard` entourée de contrôles. L'écran
passe donc par `PageImmersive`, registre `lecture`, le parchemin plus chaud que
`parcours-utilisateurs.md` réclamait pour cet écran.

La deuxième est le sens de lecture. Le `PageView` des 604 pages vit dans un
`Directionality.rtl`, **quelle que soit la langue de l'interface autour** : on
tourne les pages d'un mushaf de la droite vers la gauche, et ce n'est pas une
préférence d'affichage, c'est le document.

La troisième est l'écriture. **L'écran n'enregistre la position de lecture
qu'après un geste de navigation de l'élève.** Ouvrir le Coran ne doit jamais
écraser le marque-page par la page d'ouverture : ce serait le défaut que
l'invariant J2 interdit à l'enseignant, commis par l'écran lui-même.

```
CODE              ELV-04
Nom               Le Coran
Role              Eleve (enseignant au lot N6, en document partage)
Zone              Contenu et transmission
Niveau de charge  B / C
Ecran parent      ELV-02, et la barre basse de l'eleve
Profondeur        1
Question          Ou en etais-je, et qu'est-ce que je lis maintenant ?

Priorites         P0  le texte, en grand, sans rien par-dessus
                  P0  savoir ou l'on est : sourate, page sur 604, juz
                  P0  reprendre la ou l'on s'etait arrete
                  P1  tourner la page, au doigt comme au bouton
                  P2  la taille du texte, et la provenance du corpus

Action principale     AUCUNE au sens du bouton plein : lire n'est pas valider.
                      « Reprendre » est la seule action mise en avant, et elle
                      disparait des qu'elle ne menerait nulle part
Actions secondaires   page precedente, page suivante
Action tertiaire      reduire ou agrandir le texte
Destructif            aucun

Mobile            Le texte plein cadre, balayage lateral pour tourner la page.
                  Entete de reperage en haut, commandes de page en bas
Tablette          Idem, texte plus grand
Desktop           Idem, colonne de lecture bornee par la coquille

Etats             loading   le texte arrive
                  content   la page, decoupee par sourate
                  empty     AUCUN etat vide legitime : une page du mushaf porte
                            toujours du texte. Une page vide signifie que le
                            corpus n'est pas importe, et se dit comme tel
                  error     lecture impossible, avec « Reessayer »
                  offline   celui de la coquille

Mouvement         le glissement d'une page a l'autre, et rien d'autre : un
                  texte sacre ne s'anime pas

Invariants        J6 : aucun identifiant de fichier nulle part. L'ecran lit des
                  versets et compose lui-meme
                  J2 : la position de lecture ne s'ecrit qu'apres un geste de
                  l'eleve, et aucun enseignant ne peut l'ecrire (borne en base)
                  le texte ne se modifie jamais : aucune ecriture hors admin
                  la provenance du corpus est visible AU PIED DE CHAQUE PAGE,
                  jamais reléguee dans un ecran « a propos »
                  une sourate ne porte son titre que la ou elle COMMENCE

Accessibilite     le texte reste selectionnable et lisible par un lecteur
                  d'ecran : c'est ce que le rendu Unicode achete, et c'est la
                  raison de ne pas etre passe aux glyphes d'une edition
                  les numeros de verset sont MUETS : ce sont des reperes de mise
                  en page, pas du texte a epeler au milieu d'une phrase
                  les commandes de page portent un verbe, pas une fleche
```

**Ce que la navigation de page n'est pas.** §5.3 demande que les contrôles
secondaires soient masqués et révélés par un tap. Tourner la page **n'est pas
un contrôle secondaire** : c'est le geste du lecteur. Le masquer laisserait le
clavier et les technologies d'assistance sans aucun moyen d'avancer, le
balayage étant le seul recours. Sont donc masqués, derrière le bouton de
réglages de l'en-tête : la taille du texte, et rien d'autre pour l'instant.

**Ce que `N5` ne construit pas, et qui est écrit plutôt que masqué :**

- **le mode suivi enseignant** (§4.4) et le document partagé. C'est le lot N6,
  et il attend toujours la question `e` du §10 : le canal de diffusion de l'état
  partagé de séance n'est pas tranché. Le bouton « Ouvrir le Coran » de la salle
  n'existe donc toujours pas ;
- **le découpage en quinze lignes par page.** La colonne `verset.ligne` reste
  nulle : les deux sources disponibles ne segmentent pas les mots de la même
  façon (83 668 contre 77 881, mesuré), et une correspondance devinée sur un
  texte sacré n'est pas acceptable. Rien à l'écran n'en dépend (ADR-024) ;
- **le lien cliquable vers tanzil.net.** L'URL est affichée en clair ;
  `url_launcher` n'est pas au `pubspec.yaml`, qu'une autre session modifiait au
  moment du lot.

Construit le 13 septembre 2026, lot N5. Le composant `RosaceVerset` rejoint le
catalogue des composants a cette occasion.

### `CTR-01` Planning global

**La seule destination du rôle**, et c'est la première contrainte de la fiche :
un contrôleur n'a qu'un travail (modèle de navigation, `parcours-utilisateurs.md`),
donc pas de barre basse, pas de rail, pas de menu. L'écran répond à une seule
question, celle que `02-regles-ux.md` lui assigne : **qu'est-ce qui nécessite une
vérification ?** L'ordre des lignes est la réponse, et il ne se règle pas.

```
CODE              CTR-01
Nom               Planning global
Role              Controleur
Zone              Journee et salle
Niveau de charge  D
Ecran parent      aucun : c'est la racine du role
Profondeur        0
Question          Qu'est-ce qui a lieu maintenant, qu'est-ce qui a mal tourne,
                  et ou dois-je entrer ?

Priorites         P0  les seances en cours, en tete, avec leur bouton d'entree
                  P0  l'heure locale ET l'heure UTC de chaque seance
                  P0  le rappel permanent que la visite est journalisee
                  P1  les seances a venir, du plus proche au plus lointain
                  P1  les filtres par etat et par enseignant
                  P2  ce que la lecture n'a pas montre, en pied de liste

Action principale     AUCUNE au sens du bouton plein : l'ecran est une liste, et
                      « Observer » se pose sur une LIGNE, pas sur l'ecran. Vingt
                      cours en direct feraient vingt zones pleines, ce que la
                      regle de la zone pleine unique interdit. Niveau secondaire
Actions secondaires   retenir un etat, retenir un enseignant, tout afficher
Action tertiaire      reessayer une lecture qui a echoue
Destructif            aucun

Mobile            Une carte par seance : enseignant en titre, eleve, heure et
                  etat sur la ligne secondaire, heure UTC en dessous, bouton
                  d'entree en dernier
Tablette          Idem mobile : un tableau dense retreci est precisement ce que
                  `05-regles-responsive.md` section 3 interdit
Desktop           Tableau dense, en-tete de colonnes collee en haut, la liste
                  defile dessous

Etats             loading   squelette de liste, jamais le mot « Chargement »
                  content   la liste, triee : en cours, incidents, a venir
                  empty     aucune seance : un constat, pas une panne, et aucun
                            bouton -- il n'y a rien a relacher
                  empty+    aucune seance SOUS FILTRE : une impasse dont on sort,
                            avec « Tout afficher »
                  error     la lecture a echoue, avec « Reessayer ». Une
                            relecture qui echoue n'efface jamais la liste deja
                            affichee
                  offline   le bandeau hors ligne de PageShell, rien de plus

Mouvement         aucun propre a l'ecran. Le seul mouvement est le retour local
                  d'un refus d'entree

Invariants        « en cours » se mesure sur les HEURES, jamais sur
                  `sessions.status` : rien dans le produit ne fait passer une
                  seance a `in_progress`, et un bouton conditionne a ce statut
                  ne s'afficherait jamais
                  le bouton d'entree n'existe QUE sur une seance en cours. Hors
                  de la, pas de bouton grise : pas de bouton
                  l'inscription precede la navigation. On n'ouvre la salle
                  qu'apres que la base a accepte la visite
                  l'heure locale et l'heure UTC sont TOUTES LES DEUX affichees
                  le rappel de journalisation est permanent, comme le bandeau
                  de la salle : ni conditionnel, ni au premier passage
                  prenom ET identifiant immuable des deux cotes, jamais le nom
                  de famille ni la photo (ADR-008, ADR-012)

Accessibilite     chaque cellule porte le titre de sa colonne dans son libelle
                  parle : Flutter n'associe pas un en-tete a ses cellules
                  la carte se lit comme un seul element (MergeSemantics)
                  l'etat porte toujours son mot, jamais la seule pastille
```

**Ce que le lot a trouvé, et qui ne se voyait pas.** `CTR-02`, l'observation
invisible, était **inatteignable** depuis sa construction : rien n'inscrivait
jamais de ligne `masked_controller` dans `session_participants`, et
`autoriser_jeton_video()` refuse tout appelant qui n'y figure pas. Pire, le
plafond de participants du MVP-0 — deux — comptait les témoins comme des élèves :
un cours 1-to-1 était **plein**, donc fermé à toute visite, et le bouton
« Assister » de `TUT-01`, en production depuis l'étape 4, échouait de la même
façon sans rien dire. La migration `0012` ouvre les deux portes et rend au
plafond son sens : il borne le **groupe pédagogique**, pas l'assistance. La
spécification d'étape 5 §9 l'écrivait déjà — « le 1-to-1, **le contrôleur en
plus** ».

**Et l'invisibilité ne tenait que sur deux surfaces.** `N4` l'avait fermée sur la
présence ; restaient `session_peers_v`, la table `session_participants`
elle-même (policies enseignant et foyer) et `session_events`, toutes trois
lisibles depuis un navigateur authentifié. Aucune n'avait jamais été exercée,
faute de ligne à y lire. **Une invisibilité se vérifie sur chaque surface où la
personne peut apparaître** — la leçon de N4, une seconde fois, et il a fallu la
mesurer pour la croire : le premier correctif écrivait la borne directement dans
la policy de `session_events`, où elle ne voyait rien, parce qu'une policy qui
interroge une table protégée par RLS ne voit que ce que l'appelant voit.

**Ce que la fiche ne construit pas, et pourquoi ce n'est pas un oubli :**

- **les trois signalements automatiques de l'ADR-011** (visites répétées sur un
  même enseignant, volume anormal sur une journée, concentration sur un élève).
  Ils surveillent le surveillant, et leur place est l'espace admin, pas l'écran
  du contrôleur : les lui montrer lui dirait exactement quel seuil ne pas
  franchir. Le journal porte déjà la matière (`controller_observation_started`) ;
- **`CTR-03`, la grille d'audit.** Reportée par la fiche produit elle-même : en
  MVP-0 le contrôleur observe et signale, il ne note pas ;
- **le signalement d'incident à l'administrateur.** Il figure dans le tableau
  « peut / ne peut pas » de l'ADR-011, mais aucun écran, aucune table et aucun
  canal ne le portent aujourd'hui. Le construire ici en aurait fait un formulaire
  sans destinataire.

Construit le 13 septembre 2026, lot `CTR-01`, en parallèle du lot N5.

### `TUT-06` Suivi du foyer

**La fiche commence par une contradiction entre deux sources, parce qu'elle a dû
la trancher.** `docs/produit/parcours-utilisateurs.md` décrit `TUT-06` sous le
titre « Après le cours » : *historique par enfant des cahiers de transmission —
date, enseignant, ce qui a été travaillé, les points de phonétique relevés*. Le
cahier de transmission est `ENS-04`, il appartient à l'**étape 6** (ADR-003), et
il n'a aujourd'hui ni table, ni écran, ni format. Mais la migration `0011`, en
bornant `presence_seance_v` à son appelant, a écrit dans son propre corps :
*« Le tuteur : les participants de son foyer. C'est ce qui permettra à `TUT-06`
d'exister sans rouvrir cette vue. »*

Les deux sources parlent donc du même écran à deux moments de sa vie. La
décision de ce lot : **construire les deux tiers que la base sait nourrir — la
date, l'enseignant, l'assiduité — et ne rien poser pour le tiers manquant.**
Pas de colonne « travaillé » remplie de tirets, pas de panneau de détail vide :
un espace réservé à un contenu absent se lit comme une panne, et il se lira
ainsi à chaque ligne, tous les jours, jusqu'à l'étape 6.

**Ce que l'écran ajoute à `TUT-01`, et pourquoi il ne fait pas double emploi.**
`TUT-01` répond à « que se passe-t-il **maintenant** » — une carte par enfant,
cinq phases, le bouton « Assister ». `TUT-06` répond à « comment ça **se
passe** » : la même donnée lue dans l'autre sens, du plus récent vers le passé,
avec l'état de présence que `TUT-01` n'affiche jamais. Un parent qui paie a
deux questions, pas une.

```
CODE              TUT-06
Nom               Suivi du foyer
Role              Tuteur
Zone              Contenu et transmission
Niveau de charge  C
Ecran parent      TUT-01
Profondeur        1
Question          Comment se passent les cours de mes enfants ?

Priorites         P0  un cours par ligne, du plus recent au plus ancien
                  P0  l'etat de presence de MON enfant sur ce cours, avec son
                      mot -- jamais la seule pastille (invariant J7)
                  P0  la date et l'enseignant de chaque cours
                  P1  le filtre par enfant, des que le foyer en compte deux
                  P1  le prochain cours, en tete, quand il y en a un
                  P2  ce que la lecture n'a pas montre, en pied de liste

Action principale     AUCUNE. L'ecran est une lecture : rien ne s'y decide, rien
                      ne s'y corrige. Le geste de correction d'un etat de
                      presence appartient a l'enseignant et a l'administration
                      (section 6.5 de la spec d'etape), jamais au tuteur
Actions secondaires   retenir un enfant, tout afficher
Action tertiaire      reessayer une lecture qui a echoue
Destructif            aucun

Mobile            Une carte par cours : la date en titre, l'enfant et
                  l'enseignant sur la ligne secondaire, l'etat en pastille
Tablette          Idem mobile, comme `CTR-01` : un tableau dense retreci est ce
                  que `05-regles-responsive.md` section 3 interdit
Desktop           Tableau dense, en-tete de colonnes collee en haut

Etats             loading   squelette de liste, jamais le mot « Chargement »
                  content   la liste, du plus recent au plus ancien
                  empty     aucun cours encore tenu : un CONSTAT, pas une panne,
                            et sans bouton -- le foyer n'a rien a y faire, il
                            attend son premier cours
                  empty+    aucun cours pour l'enfant retenu : une impasse de
                            filtre, dont on sort par « Tout afficher »
                  error     la lecture a echoue, avec « Reessayer ». Une
                            relecture qui echoue n'efface jamais la liste deja
                            affichee
                  offline   le bandeau hors ligne de PageShell, rien de plus

Mouvement         aucun propre a l'ecran

Invariants        `inconnu` n'est JAMAIS rendu « Absence » (invariant J3). Un
                  cours sans ligne de presence lisible dit « Etat inconnu » :
                  une absence compte pour le suivi et pour la paie, ne pas
                  savoir ne compte pour rien
                  l'ordre ne depend JAMAIS de l'etat. Le plus recent d'abord, et
                  rien d'autre : une ligne qui remonterait parce qu'elle est
                  devenue critique se ferait toucher a la place d'une autre
                  le tuteur lit l'etat, il ne le PRONONCE pas. Aucun geste de
                  correction, aucune demande d'excuse : ce sont deux surfaces
                  d'ecriture qui n'existent pas encore, et qui ne lui
                  reviendront pas
                  la vue dit QU'UNE decision humaine a fige un etat, jamais
                  POURQUOI. Le motif reste en base et au journal (section 6.6)
                  prenom ET identifiant immuable de l'enseignant, jamais le nom
                  de famille ni la photo (ADR-008, ADR-012)
                  le client ne filtre RIEN par foyer : `presence_seance_v` et
                  `mes_seances_v` sont deja bornees en base. Un filtre client
                  serait une decoration par-dessus une donnee deja livree

Accessibilite     chaque cellule porte le titre de sa colonne dans son libelle
                  parle : Flutter n'associe pas un en-tete a ses cellules
                  la carte se lit comme un seul element (MergeSemantics)
                  l'etat porte toujours son mot
```

**Aucune migration.** C'est le premier lot d'écran de l'étape 5 à n'en demander
aucune, et ce n'est pas un hasard : `0011` et `0005` avaient déjà ouvert au
tuteur exactement ce que cet écran lit, `presence_seance_v` pour les membres de
son foyer et `mes_seances_v` pour leurs séances. La lecture se fait donc **sans
filtre client** — un `select()` nu rend au tuteur son foyer et rien d'autre.

**Ce que la fiche ne construit pas, et pourquoi ce n'est pas un oubli :**

- **le contenu pédagogique** — ce qui a été travaillé, les points de phonétique.
  C'est `ENS-04`, étape 6. Tant qu'aucun enseignant ne peut l'écrire, aucun
  parent ne peut le lire, et une colonne vide ne comble pas un cahier absent ;
- **la notification de fin de séance**, que la fiche produit décrit comme ce qui
  « justifie l'abonnement aux yeux du parent qui paie ». Elle demande un canal :
  `device_tokens` est vide et l'étape D de l'onboarding reste ouverte
  (`etape-4-dashboards.md` section 8). La construire ici en aurait fait un
  message sans destinataire ;
- **le détail d'une séance.** Il n'a rien à porter de plus que sa ligne tant que
  le cahier n'existe pas. Le registre annonçait « liste + détail » sur desktop ;
  la fiche le remplace par le tableau dense, et le dit plutôt que de livrer un
  panneau vide ;
- **le geste de correction ou d'excuse d'une absence.** Il appartient à
  l'enseignant et à l'administration, il demande motif, confirmation et entrée
  de journal, et la section 6.5 de la spécification d'étape le laisse
  explicitement ouvert. Le poser chez le tuteur aurait donné au foyer le droit
  de corriger ce qui compte pour la paie de l'enseignant.

Construit le 13 septembre 2026, lot `TUT-06`.

### `ADM-07` Accès des agents IA

```
CODE              ADM-07
Nom               Accès des agents IA
Rôle              Admin
Zone              Administration
Niveau de charge  E
Écran parent      ADM-01
Profondeur        1
Question          Qui observe l'application en ce moment, et sous quels yeux ?

Priorités         P0  émettre un jeton : à quoi il sert, qui il observe,
                      pendant combien de temps, avec ou sans les prénoms
                  P0  le lien à remettre, montré UNE seule fois
                  P0  la liste des jetons, l'actif d'abord, et sa révocation
                  P1  « Pourra » et « Ne pourra pas », de rang égal
                  P2  le compteur d'ouvertures, et la mention « jamais utilisé »

Action principale     Émettre un jeton
Actions secondaires   Copier le lien
Action tertiaire      aucune
Destructif            Révoquer un jeton (confirmation, irréversible)

Mobile            formulaire en pile, puis une carte par jeton
Tablette          idem, colonne plus large
Desktop           formulaire pleine largeur, puis tableau dense

États             loading   squelette de liste sous le formulaire
                  content   nominal
                  empty     « Aucun jeton d'observation », registre bonne
                            nouvelle : personne n'a accès, ce n'est pas un manque
                  error     message sur la liste seule, le formulaire reste
                            utilisable
                  offline   l'émission échoue et le dit ; rien n'est mis en file :
                            un jeton émis hors ligne serait un secret perdu

Mouvement         aucun. Un écran d'accès ne s'anime pas : la carte du secret
                  apparaît à la place du formulaire, sans transition qui
                  détournerait l'œil du seul moment où le lien est lisible

Invariants        le secret n'apparaît qu'une fois, et l'écran le dit AVANT
                  l'état d'un jeton vient de la base, jamais d'une comparaison
                  entre son expiration et l'horloge du poste
                  la durée proposée est une commodité : le plafond de 24 h est
                  tenu par la base, qui refuse l'appel direct
                  la portée ne se modifie pas : il n'existe aucun geste
                  d'édition, parce qu'il n'existe aucune écriture en base
                  le libellé est obligatoire : un jeton anonyme ne se révoque pas

Accessibilité     le lien est sélectionnable au clavier, jamais seulement
                  copiable par un bouton ; l'état de chaque jeton est porté par
                  un mot, jamais par la seule couleur de sa pastille
```

**Un seul écran, pas un parcours en quatre étapes.** La console de l'autre
produit de l'opérateur guidait l'émission en quatre écrans successifs ; ici les
quatre champs se voient ensemble, et la liste est juste en dessous. Un assistant
se justifie quand une étape dépend de la précédente : aucune ne dépend ici d'une
autre.

Ce que cet écran garde de la console précédente, parce que c'en était la bonne
idée : **« Pourra » et « Ne pourra pas » de rang égal**. Quand on accorde un
droit d'accès, la question utile n'est pas ce qu'il ouvre, c'est ce qu'il
n'ouvre pas.

Construit le 18 septembre 2026, lot `AGT-01` (ADR-025).

### `AGT-00` Entrée d'un agent

```
CODE              AGT-00
Nom               Entrée d'un agent
Rôle              Agent IA
Zone              Accès
Niveau de charge  A
Écran parent      aucun
Profondeur        0
Question          Ce lien m'ouvre-t-il l'application, et sinon pourquoi ?

Priorités         P0  dire pourquoi une entrée a échoué
                  P0  fabriquer l'adresse à ouvrir quand on arrive sans jeton
                  P1  rappeler que l'observation est en lecture seule

Action principale     aucune
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            page
Tablette          page centrée
Desktop           page centrée

États             loading   aucun : l'ouverture a déjà eu lieu, ou échoué,
                            avant que cet écran existe
                  content   le formulaire, et l'adresse fabriquée
                  empty     confondu avec content : sans jeton, l'écran EST son
                            formulaire
                  error     la carte de refus, en tête
                  offline   non traité : sans réseau, l'amorçage a déjà échoué
                            et l'écran affiche « service indisponible »

Mouvement         aucun.

Invariants        cet écran n'ouvre AUCUNE session : l'ouverture se décide dans
                  `main()`, avant que le premier écran existe
                  le jeton n'est rangé nulle part, ni disque ni stockage du
                  navigateur : fermer l'onglet met fin à l'observation
                  le refus ne distingue jamais « inconnu », « révoqué » et
                  « expiré » : la base rend déjà le même message pour les trois
                  on ne navigue pas vers l'adresse fabriquée, on la montre : une
                  navigation interne ne relancerait pas l'amorçage, et l'agent
                  croirait être entré sans l'être

Accessibilité     l'adresse fabriquée est sélectionnable ; la carte de refus
                  porte son titre et sa cause en texte, jamais en icône seule
```

**Publique par construction, et ce n'est pas une porte dérobée.** Un porteur de
jeton n'a, par définition, aucune session : le renvoyer sur `/connexion` lui
présenterait un écran de connexion humaine et lui ferait perdre le jeton passé
dans l'URL. Sans jeton vivant, cette route ne rend qu'un formulaire ; avec un
jeton, elle n'ouvre que ce que la base accorde déjà au rôle `agent_ro`,
c'est-à-dire de la lecture, et seulement celle de la personne observée.

Construit le 18 septembre 2026, lot `AGT-01` (ADR-025).

### `ADM-08` Comptes

```
CODE              ADM-08
Nom               Comptes
Role              Admin
Zone              Administration
Niveau de charge  E
Ecran parent      ADM-01
Profondeur        1
Question          Qui s'est inscrit, et qui attend une decision ?

Priorites         P0  les personnes qui attendent une decision, en premier
                  P0  l'etat de la piece d'identite, y compris « aucune »
                  P1  l'anciennete de l'inscription, en jours
                  P1  le filtre par etat de compte et par role

Action principale     aucune : cet ecran constate, il ne tranche pas. Les
                      verdicts vivent sur ADM-02, l'attribution sur ADM-05
Actions secondaires   filtrer par etat, filtrer par role
Action tertiaire      aucune
Destructif            aucun

Mobile            une carte par personne (DataCollection replie le tableau)
Tablette          identique
Desktop           tableau dense, sa forme naturelle au niveau E

Etats             loading   squelette de liste, cinq lignes
                  content   bandeau d'attente, filtres, puis le tableau
                  empty     « Aucun compte avec ce filtre », registre subi :
                            c'est le filtre qu'il faut retirer
                  error     phrase + « Reessayer », registre ACTIONNABLE.
                            EmptyState ne rend son bouton que dans ce
                            registre : declare en subi, le bouton n'existe pas
                  offline   le bandeau OfflineBanner de PageShell coiffe la page

Mouvement         aucun propre a l'ecran

Invariants        une personne sans piece deposee est VISIBLE et dit ce qui
                  manque. C'est la raison d'etre de l'ecran
                  le tri vient de la base : ce qui attend une decision d'abord,
                  puis l'anciennete. Jamais l'ordre alphabetique
                  l'anciennete se rend en jours, jamais en date seule : une
                  date demande un calcul, « depuis 7 jours » appelle un geste
                  le masquage d'identite est respecte : sous un jeton d'agent
                  masque, la base ne rend aucun prenom et l'ecran n'affiche que
                  l'identifiant immuable
                  aucune ecriture : cet ecran est en lecture seule

Accessibilite     cibles a 44 ; chaque ligne porte son libelle parle, nom et
                  etat ensemble ; chiffres tabulaires sur l'anciennete et les
                  contrats ; la page se lit de droite a gauche en arabe
```

**Pourquoi cet écran existe, et pourquoi son absence a coûté cher.** Mesuré sur
la base de production le 18 septembre 2026 : trois enseignants inscrits les 11
et 15 septembre attendaient depuis sept jours, **contrats signés**, sans avoir
déposé leur pièce d'identité. Aucun écran de l'administration ne les montrait.
`dossiers_en_attente()` lisait `kyc_documents where status = 'pending'` — elle
comptait des **documents**, et une personne sans document n'existait pour
personne. Le centre de commande affichait « 0 dossiers à valider » et l'écran de
validation « Aucun dossier en attente », sur une académie bloquée : un foyer
attendait un enseignant, trois enseignants attendaient d'être validés, et
l'interface annonçait qu'il n'y avait rien à faire.

La fiche `ADM-01` avait pourtant écrit la phrase du danger — « l'admin verrait
une ruche vide et croirait tout traité » — mais seulement pour le cas d'une
lecture en échec. Le cas où la donnée existe et qu'aucun compteur ne la compte
n'avait jamais été prévu.

Construit le 18 septembre 2026, avec la migration `0015`, qui corrige aussi
`dossiers_en_attente()` pour qu'elle rende une ligne par **personne**.

### `ADM-13` Programmes

```
CODE              ADM-13
Nom               Programmes
Role              Admin
Zone              Administration > Pedagogie
Niveau de charge  E
Ecran parent      aucun (racine de sa sous-navigation)
Profondeur        1
Question          Que contient le curriculum publie, et qu'est-ce qui est en
                  brouillon ?

Priorites         P0  la version publiee courante et ses niveaux
                  P0  le statut brouillon/publiee/archivee, sans ambiguite
                  P1  creer un niveau dans une version brouillon
                  P1  publier une version (confirmation, motif)

Action principale     publier la version en brouillon (confirmation + motif)
Actions secondaires   creer un niveau, modifier un niveau (brouillon
                      seulement), creer une nouvelle version a partir de la
                      publiee courante
Action tertiaire      aucune
Destructif            supprimer un niveau d'une version brouillon (motif
                      requis, jamais sur une version publiee)

Mobile            une carte par niveau, groupee par cycle
Tablette          identique
Desktop           liste de versions a gauche, niveaux de la version
                  selectionnee a droite, groupes par cycle

Etats             loading   squelette de liste, cinq lignes
                  content   liste des versions puis niveaux de la version
                             selectionnee
                  empty     "Aucune version de programme" -- creer la
                             premiere version brouillon
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         aucun propre a l'ecran

Invariants        le code technique (ex. F1-PHO-01) n'est jamais un titre : le
                  nom humain seul est affiche en premier plan, le code reste
                  en sous-texte technique discret
                  une version au statut publiee ne peut plus etre modifiee ni
                  en RPC ni en UI -- toute modification academique cree une
                  nouvelle version brouillon
                  publier exige un motif, journalise via
                  log_sensitive_access
                  la version active pour Diagnostics/Progression/Evaluations
                  est la publiee la plus recente, jamais un brouillon

Accessibilite     cibles a 44 ; chaque niveau porte son libelle parle nom +
                  cycle ; la page se lit de droite a gauche en arabe
```

Fondation du domaine Pédagogie : les quatre autres écrans (`ADM-10`
Diagnostics, `ADM-11` Progression, `ADM-12` Évaluations, `ADM-14` Qualité)
référencent `programme_niveaux` d'une version publiée. Construit en premier
dans l'ordre technique du lot, bien qu'affiché en dernier dans la
sous-navigation (Diagnostics, Progression, Évaluations, Programmes, Qualité),
qui reste l'ordre demandé par la mission.

### `ADM-10` Diagnostics

```
CODE              ADM-10
Nom               Diagnostics
Role              Admin
Zone              Administration > Pedagogie
Niveau de charge  E
Ecran parent      aucun (fonction primaire du domaine)
Profondeur        1
Question          Quel niveau reel donner au prochain eleve non place ?

Priorites         P0  l'eleve qui attend depuis le plus longtemps, en premier
                  P0  le programme doit avoir une version publiee, sinon rien
                       n'est decidable
                  P1  le motif de la decision

Action principale     decider le placement (niveau + motif obligatoire)
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            un eleve a la fois, meme discipline qu'ADM-02
Tablette          identique
Desktop           identique -- une decision a la fois, jamais une file
                  parcourue en grille

Etats             loading   squelette de liste, quatre lignes
                  content   un eleve, un selecteur de niveau groupe par
                             cycle, un motif, une action
                  empty     "Aucun eleve a diagnostiquer", registre BONNE
                             NOUVELLE : personne n'attend
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page
                  (etat supplementaire) aucun programme publie : registre
                  subi, oriente vers Pedagogie > Programmes plutot que
                  d'inventer un choix

Mouvement         aucun propre a l'ecran

Invariants        la file est calculee (eleves actifs absents de
                  progression_historique), jamais une colonne d'etat
                  separee a garder synchronisee
                  le niveau propose vient uniquement de la version publiee
                  la plus recente, jamais d'un brouillon
                  un eleve deja diagnostique ne peut pas etre re-diagnostique
                  ici -- une correction passe par Progression (ADM-11)
                  motif obligatoire, journalise via log_sensitive_access

Accessibilite     cibles a 44 ; chaque niveau proposé porte son libelle
                  parle ; la page se lit de droite a gauche en arabe
```

Deuxième lot du domaine Pédagogie. Nécessite `ADM-13` (une version du
programme publiée) pour proposer un niveau réel.

### `ADM-11` Progression

```
CODE              ADM-11
Nom               Progression
Role              Admin
Zone              Administration > Pedagogie
Niveau de charge  E
Ecran parent      aucun (atteint depuis la sous-navigation Pedagogie)
Profondeur        1
Question          Ou en est chaque eleve, et qui est bloque ?

Priorites         P0  le niveau courant et le groupe de chaque eleve
                  P0  les exceptions actives (blocage/derogation), visibles
                       sans ouvrir chaque fiche
                  P1  le filtre par cycle

Action principale     aucune : cet ecran constate d'abord. Poser/clore une
                      exception et changer de niveau restent des actions de
                      ligne, via le menu contextuel
Actions secondaires   filtrer par cycle
Action tertiaire      aucune
Destructif            aucun

Mobile            une carte par eleve (DataCollection replie le tableau)
Tablette          identique
Desktop           tableau dense, sa forme naturelle au niveau E

Etats             loading   squelette de liste, cinq lignes
                  content   filtres par cycle, puis le tableau
                  empty     "Aucun eleve actif", registre subi
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         aucun propre a l'ecran

Invariants        un eleve sans groupe actif ou sans niveau decide reste
                  VISIBLE et dit ce qui manque -- meme discipline qu'ADM-08
                  au plus une exception active par type et par eleve
                  (contrainte posee par poser_exception_progression)
                  progression_exceptions est un catalogue distinct de
                  rule_overrides/matching_requests (ADM-06) : jamais
                  fusionne avec les regles operationnelles
                  changer de niveau hors evaluation est une decision
                  manuelle, journalisee au meme titre qu'un diagnostic

Accessibilite     cibles a 44 ; chaque ligne porte son libelle parle nom,
                  groupe, niveau et exception ensemble ; chiffres tabulaires
                  sur l'anciennete ; la page se lit de droite a gauche en
                  arabe
```

Troisième lot du domaine Pédagogie. Le niveau courant vient de la dernière
ligne de `progression_historique` (`ADM-10`), jamais d'une colonne d'état
séparée.

### `ADM-12` Évaluations

```
CODE              ADM-12
Nom               Évaluations
Role              Admin
Zone              Administration > Pedagogie
Niveau de charge  E
Ecran parent      aucun (atteint depuis la sous-navigation Pedagogie)
Profondeur        1
Question          Qu'est-ce qui est prevu, passe, et certifie ?

Priorites         P0  les evaluations planifiees, visibles en premier
                  P0  le resultat d'une evaluation realisee
                  P1  le filtre par statut, et un filtre dedie
                       « Certifications »

Action principale     planifier une evaluation
Actions secondaires   filtrer par statut/type, enregistrer un resultat,
                      annuler une evaluation planifiee (actions de ligne)
Action tertiaire      aucune
Destructif            annuler une evaluation planifiee (motif requis)

Mobile            une carte par evaluation (DataCollection replie le
                  tableau)
Tablette          identique
Desktop           tableau dense, sa forme naturelle au niveau E

Etats             loading   squelette de liste, cinq lignes
                  content   filtres, puis le tableau
                  empty     "Aucune evaluation" / "Aucune evaluation avec ce
                             filtre", registre subi
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         aucun propre a l'ecran

Invariants        une certification est une evaluation de type
                  `certification` reussie -- jamais un objet separe, le
                  filtre "Certifications" lit les memes lignes
                  une reevaluation est une nouvelle evaluation planifiee sur
                  le meme niveau apres un echec, jamais un objet a part
                  une reussite en reevaluation ou certification ajoute une
                  ligne a progression_historique, jamais une nouvelle
                  source de verite sur le niveau courant
                  seule une evaluation planifiee peut recevoir un resultat
                  ou etre annulee

Accessibilite     cibles a 44 ; chaque ligne porte son libelle parle eleve,
                  niveau, type et statut ensemble ; chiffres tabulaires sur
                  la date ; la page se lit de droite a gauche en arabe
```

Quatrième lot du domaine Pédagogie.

### `ADM-14` Qualité

```
CODE              ADM-14
Nom               Qualite
Role              Admin
Zone              Administration > Pedagogie
Niveau de charge  E
Ecran parent      ADM-01 (compteur "rapports manquants", branche le 19
                  septembre 2026), aussi atteint depuis la sous-navigation
                  Pedagogie
Profondeur        1
Question          Quelles anomalies pedagogiques attendent une action ?

Priorites         P0  les anomalies ouvertes, groupees par type
                  P0  le rapport manquant raccorde enfin le compteur mort
                       d'ADM-01
                  P1  le filtre ouvertes/traitees

Action principale     aucune : cet ecran constate d'abord. Marquer traite
                      reste une action de ligne
Actions secondaires   filtrer ouvertes/traitees/toutes
Action tertiaire      aucune
Destructif            aucun

Mobile            cartes groupees par type d'anomalie
Tablette          identique
Desktop           tableau dense par groupe, meme composant que les autres
                  ecrans du domaine

Etats             loading   squelette de liste, cinq lignes
                  content   filtres, puis un tableau par type d'anomalie
                             present
                  empty     "Aucune anomalie detectee", registre BONNE
                             NOUVELLE quand aucun filtre n'exclut rien ;
                             registre subi si le filtre choisi exclut tout
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         aucun propre a l'ecran

Invariants        chaque anomalie est calculee a la lecture
                  (anomalies_qualite()), jamais stockee -- seul le controle
                  (traite ou non) est retenu en base
                  marquer traite est idempotent : re-traiter met a jour la
                  note, ne duplique jamais la ligne de controle
                  le suivi enseignant se lit sur la colonne « Concerne » du
                  groupe Rapports manquants, pas un agregat separe

Accessibilite     cibles a 44 ; chaque ligne porte son libelle parle
                  personne, anciennete et statut ensemble ; chiffres
                  tabulaires sur l'anciennete ; la page se lit de droite a
                  gauche en arabe
```

Cinquième et dernier lot du domaine Pédagogie. Raccorde enfin le compteur
« rapports manquants » d'`ADM-01`, présent depuis la migration `0001` mais
jamais consommé par aucun écran (audit, ligne 134). Câble aussi la
sous-navigation des cinq écrans et active `AdminDomaine.pedagogie`.

### `ADM-15` Règles

```
CODE              ADM-15
Nom               Regles
Role              Admin
Zone              Administration > Configuration
Niveau de charge  E
Ecran parent      aucun (fonction primaire de Configuration)
Profondeur        1
Question          Quelles valeurs par defaut regissent toute la plateforme ?

Priorites         P0  les dix reglages de app_config lisibles et modifiables
                  P1  le rappel que la surcharge par profil (ADM-06) est un
                       ecran distinct, jamais le meme reglage ici

Action principale     aucune : chaque ligne s'edite individuellement, une
                      feuille a la fois
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            liste de SettingRow, pleine largeur
Tablette          identique
Desktop           identique -- pas de tableau, dix lignes ne le justifient
                  pas

Etats             loading   squelette de liste, cinq lignes
                  content   dix SettingRow, valeur courante affichee
                  empty     jamais -- les dix cles sont toujours seedees
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         AppBottomSheet a l'ouverture de chaque edition (280/200 ms)

Invariants        edite le defaut de plateforme (app_config), jamais une
                  surcharge de profil (rule_overrides, ADM-06) -- deux
                  routes canoniques distinctes
                  app_config_history journalise chaque ecriture par le
                  trigger existant, rien a faire cote ecran
                  une saisie non entiere ou negative est refusee avant tout
                  appel reseau

Accessibilite     cibles a 44 ; chaque ligne porte titre et description au
                  lecteur d'ecran ; le champ de la feuille recoit le focus a
                  l'ouverture ; la page se lit de droite a gauche en arabe
```

Première fonction du domaine Configuration, contrat métier reçu le 19
septembre 2026 au soir (`docs/architecture/ADMIN_FINANCE_CONFIGURATION.md`).
Active `AdminDomaine.configuration` et câble la sous-navigation des trois
écrans construits (`ongletsConfiguration()`). Académie, Classe en ligne,
Notifications et Localisation restent à construire.

### `ADM-16` Fonctionnalités

```
CODE              ADM-16
Nom               Fonctionnalites
Role              Admin
Zone              Administration > Configuration
Niveau de charge  E
Ecran parent      aucun (atteint depuis la sous-navigation Configuration)
Profondeur        1
Question          Quelles fonctionnalites changent le comportement de toute
                  la plateforme ?

Priorites         P0  l'interrupteur des seances multi-participants
                  P0  le plafond de participants qui l'accompagne

Action principale     aucune : l'interrupteur ecrit immediatement, le
                      plafond s'edite par feuille
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun

Mobile            liste de SettingRow, pleine largeur
Tablette          identique
Desktop           identique

Etats             loading   squelette de liste, deux lignes
                  content   un interrupteur puis un reglage entier
                  empty     jamais -- les deux cles sont toujours seedees
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         AppBottomSheet a l'ouverture de l'edition du plafond

Invariants        l'interrupteur ecrit sans confirmation, l'echec s'affiche
                  sous la ligne plutot que de rester silencieux
                  meme regle de separation Finance/Configuration que
                  ADM-15

Accessibilite     cibles a 44 ; l'interrupteur porte titre et description au
                  lecteur d'ecran ; la page se lit de droite a gauche en
                  arabe
```

Deuxième fonction du domaine Configuration. Reprend l'exemple donné par le
contrat métier lui-même : « Activer les cours multi-participants ->
Configuration > Fonctionnalités ».

### `ADM-17` Conservation des données

```
CODE              ADM-17
Nom               ConservationDonnees
Role              Admin
Zone              Administration > Configuration
Niveau de charge  E
Ecran parent      aucun (atteint depuis la sous-navigation Configuration)
Profondeur        1
Question          Combien de temps ces donnees restent-elles accessibles
                  avant suppression automatique ?

Priorites         P0  le delai des enregistrements de seance
                  P0  le delai des documents d'identite deposes

Action principale     aucune : chaque ligne s'edite individuellement
Actions secondaires   aucune
Action tertiaire      aucune
Destructif            aucun -- ces reglages allongent ou raccourcissent un
                      delai, ils ne suppriment rien eux-memes

Mobile            liste de SettingRow, pleine largeur
Tablette          identique
Desktop           identique

Etats             loading   squelette de liste, deux lignes
                  content   deux reglages entiers, en jours
                  empty     jamais -- les deux cles sont toujours seedees
                  error     phrase + "Reessayer", registre actionnable
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                             page

Mouvement         AppBottomSheet a l'ouverture de chaque edition

Invariants        `recording_retention_days` et `kyc_retention_days` sont
                  les deux seuls delais de conservation qui existent en
                  base -- aucun autre a modeliser sans nouvelle migration

Accessibilite     cibles a 44 ; chaque ligne porte titre et description au
                  lecteur d'ecran ; la page se lit de droite a gauche en
                  arabe
```

Troisième et dernière fonction construite du domaine Configuration pour ce
lot. `kyc_documents.purge_at` (migration `0004`) se déduit de
`kyc_retention_days` à chaque dépôt ; cet écran édite le réglage, jamais la
colonne calculée.

---

## 7. Fiches du lot Enseignant (20 septembre 2026)

Cinq fiches écrites **avant** l'implémentation, en exécution du gel
`docs/architecture/TEACHER_PARALLEL_BASELINE.md` et de la règle de `CLAUDE.md`
ligne 74 : aucun écran ne s'implémente s'il n'est pas inscrit ici. Elles ne
décrivent donc pas du code existant, contrairement aux fiches de la section 6 —
elles le commandent. Un champ resté ouvert est écrit comme ouvert, et un agent
qui le comble sans décision opérateur invente une UX.

### `ENS-01` Onboarding et bienvenue

```
CODE              ENS-01
Nom               Onboarding et bienvenue
Role              Enseignant
Zone              Acces
Niveau de charge  C
Ecran parent      aucun : c'est la porte d'entree du role
Profondeur        0 pour les surfaces partagees, 1 pour la bienvenue
Question          Ou en est mon dossier, et que dois-je faire maintenant ?

Priorites         P0  l'etat du dossier, dit en une phrase et sans jargon
                  P0  le seul pas qui reste a faire, en une action
                  P0  les deux accuses obligatoires : enregistrement audio et
                      visite de controle (ADR-011), puis le contrat
                      `teacher_nda`
                  P1  la bienvenue une fois le dossier valide, et le chemin
                      vers la premiere declaration de disponibilites
                  P2  rien d'autre : un enseignant en attente n'a aucune
                      decision utile a prendre ici

Action principale     le pas suivant du dossier, un seul a la fois : accuser,
                      signer, deposer la piece. Une fois le dossier valide,
                      "Declarer mes disponibilites", qui mene a ENS-06
Actions secondaires   aucune sur les surfaces d'attente : une deuxieme action
                      ferait croire a un choix qui n'existe pas
Action tertiaire      la deconnexion, deja portee par le portail d'attente
Destructif            aucun

Mobile            un parcours, une carte par pas, jamais un formulaire long
                  (ADR-013). La bienvenue est une page courte, une colonne
Tablette          identique, gouttiere du gabarit
Desktop           parcours centre et borne, comme le reste de la zone Acces

Surfaces traversees, et elles se REUTILISENT toutes
  /connexion            TUT-00, partagee avec le tuteur
  /attente              TUT-00b, le portail : il porte l'etat du dossier
  /attente/accuse       TUT-00c/a, l'accuse enregistrement audio + visite de
                        controle (ADR-011). Il PRECEDE le contrat, decision
                        ADR-016
  /attente/contrat      TUT-00c/b, le contrat `teacher_nda` pour l'enseignant,
                        `guardian_terms` pour le tuteur : c'est
                        `0004_inscription_kyc_appairage.sql` ligne 463 qui
                        choisit, jamais l'ecran
  /attente/piece        TUT-00c/c, le depot KYC
  /enseignant/bienvenue ECRAN NEUF, traverse UNE SEULE FOIS apres validation

Etats du compte a couvrir, et le nom exact que la base leur donne
  incomplet          EtapeDossier.incomplet : il manque des pieces, une liste
                     courte, chacune avec son bouton
  en attente         EtapeDossier.enVerification : tout est depose, l'academie
                     verifie. Aucun bouton : l'enseignant ne peut rien faire
                     de plus, et un bouton inerte serait un mensonge
  valide             AccountStatus.active : le portail ne s'affiche plus, la
                     bienvenue s'affiche une fois, puis la Journee
  correction         EtapeDossier.refuse porte AUSSI ce cas : la base ne
  demandee           distingue pas "refuse definitivement" de "a corriger".
                     L'ecran rend le motif et de quoi corriger. QUESTION
                     OUVERTE : un refus definitif et une demande de correction
                     ne se disent pas de la meme facon, et rien en base ne
                     permet aujourd'hui de les separer
  refuse             meme etat que ci-dessus, meme limite
  suspendu           EtapeDossier.suspendu / AccountStatus.disabled : aucun
                     acces, et aucune action
  expire             N'EXISTE PAS comme etat. Le cas voisin est
                     AccountStatus.provisionalActive, avec
                     `profiles.kyc_completion_deadline` : acces complet, profil
                     a completer sous 30 jours, AUCUNE coupure automatique
                     (ADR-014). L'echeance s'affiche, elle ne bloque rien

Etats d'ecran     loading   squelette du portail, le temps que l'etat du
                            dossier arrive
                  content   nominal, un seul pas visible
                  empty     n'existe pas : un dossier a toujours un etat
                  error     la lecture de l'etat echoue : une phrase et
                            "Reessayer". Ne JAMAIS retomber sur "en attente"
                            par defaut, ce serait inventer un verdict
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                            page ; le depot de piece n'est pas propose

Mouvement         aucun propre a l'ecran. Rien ne se ferme sur minuterie, et la
                  bienvenue ne defile pas toute seule

Invariants        les deux accuses de l'ADR-011 sont OBLIGATOIRES et se
                  signent une seule fois : un enseignant qui decouvre
                  l'enregistrement audio ou la visite de controle apres coup
                  est un litige
                  l'accuse precede le contrat, jamais l'inverse (ADR-016)
                  la bienvenue ne porte AUCUNE grille de semaine : la
                  declaration des disponibilites vit dans ENS-06, et deux
                  grilles jumelles finiraient par diverger
                  la bienvenue se traverse une seule fois : elle ne devient
                  jamais une destination, et ne se retrouve pas depuis la barre
                  un bouton qui ne peut pas aboutir n'est pas rendu, et une
                  phrase prend sa place
                  le role declare a l'inscription est borne par la base, pas
                  par l'ecran (ADR-016)

Accessibilite     cibles a 44
                  chaque pas du parcours porte son intitule au lecteur d'ecran
                  le parcours se lit de droite a gauche en arabe
                  a 200 % de taille de texte, aucun texte rogne, et les cartes
                  de choix grandissent au lieu de couper
```

Ce que cette fiche **n'autorise pas** : construire un second tunnel d'entree. Les
cinq surfaces partagées existent, sont testées (`test/features/dossier_test.dart`,
`test/features/inscription_test.dart`, `test/features/attente_test.dart`) et
servent le tuteur autant que l'enseignant. Le seul fichier neuf de cette fiche
est la bienvenue.

Trois des sept échecs de test antérieurs au lot tombent sur
`dossier_test.dart` et deux sur `inscription_test.dart`, tous pour la même
cause mesurée : un `tap()` hors du viewport (`TEACHER_PARALLEL_BASELINE.md` §7).
Ce sont des défauts de **mise en page mobile** de ces surfaces partagées, pas
des défauts du parcours : les corriger est dans le périmètre de cette fiche,
changer le parcours du tuteur ne l'est pas.

Reste ouvert, et ne s'invente pas : la distinction entre un refus définitif et
une demande de correction n'existe **ni en base ni dans l'énumération
`EtapeDossier`**. Les deux se disent aujourd'hui par le même état, avec le motif
pour seule différence. C'est une décision opérateur, pas une décision d'agent.

### `ENS-04` Cahier de transmission

```
CODE              ENS-04
Nom               Cahier de transmission
Role              Enseignant
Zone              Contenu et transmission
Niveau de charge  D
Ecran parent      ENS-03, la salle : c'est son ECRAN DE SORTIE
Profondeur        2
Question          Ce cours s'est-il passe comme prevu, et sinon, en quoi ?

Le principe qui commande tout le reste
  L'ecran est PREREMPLI. Tout vaut "Continuer" par defaut. L'enseignant ne
  modifie que les exceptions. Cible : moins de 45 secondes pour la seance
  entiere, sur un telephone d'entree de gamme, a une main, hors ligne.
  Corollaire : aucune saisie manuelle de ce que le systeme sait deduire. Un
  champ vide a remplir est un echec de conception, pas un choix de l'operateur.

Priorites         P0  le constat prerempli, lisible d'un coup d'oeil
                  P0  le bouton unique qui l'accepte tel quel
                  P1  signaler une exception, par exception et non en bloc
                  P1  le point phonetique, en puces geantes a cocher
                  P2  l'objectif personnel et le travail maison
                  P2  la note libre, facultative

Ce que le SYSTEME deduit, et que l'enseignant n'a jamais a saisir
  presence          par `etat_presence()`, quatorze etats. Un etat
                    indisponible se dit `inconnu`, JAMAIS `absente`
                    (invariant J3)
  duree             de la seance, mesuree
  contenu presente  ce qui a ete pousse en salle
  unite du          quand elle existe : rien n'est affiche si le curriculum
  curriculum        ne rend pas d'unite pour cette seance
  evenements        de seance, tels que la salle les a produits
  ces cinq elements arrivent par `brouillon_cahier(uuid)`, RPC stable de la
  migration 0025

Ce que l'enseignant PEUT faire
  confirmer le constat tel quel, en une action
  signaler une exception sur un element precis du constat
  noter un point phonetique
  definir ou ajuster un objectif personnel d'eleve
  ajuster le travail maison
  suspendre le nouveau contenu dans la marge autorisee

Ce que l'enseignant NE PEUT PAS faire, et ou l'ecran ne pose meme pas le geste
  modifier le curriculum institutionnel (invariant 8 du gel)
  changer un cycle fixe pour un eleve seul
  valider un gate hors des regles
  inventer un programme parallele a celui de l'academie

Action principale     un bouton UNIQUE de validation. Il accepte le constat
                      prerempli, exceptions comprises si l'enseignant en a
                      pose
Actions secondaires   poser une exception, cocher une paire phonetique
Action tertiaire      la note libre, facultative
Destructif            aucun. Un cahier depose ne se supprime pas depuis ici

Mobile            Page, une main, 45 s. Trois zones empilees : le constat
                  prerempli, la matrice de phonetique en puces geantes (quatre
                  paires par defaut), la note libre. Le bouton de validation en
                  bas, atteignable au pouce
Tablette          identique, gouttiere elargie
Desktop           Panneau : le registre l'ecrit ainsi, et la raison est que la
                  sortie de salle ne doit pas faire perdre le contexte du cours

Etats             loading     squelette des trois zones, le temps que
                              `brouillon_cahier` rende le constat
                  content     nominal, prerempli
                  empty       le brouillon revient sans presence ni contenu :
                              le cahier reste depossable, et l'ecran DIT que le
                              constat n'a pas pu etre deduit. Il ne presente
                              pas un formulaire vide comme si c'etait normal
                  error       la lecture du brouillon echoue : phrase +
                              "Reessayer". La validation reste possible sans
                              prerempli, parce qu'un cahier tardif vaut mieux
                              qu'un cahier perdu
                  offline     le cahier part en FILE LOCALE avec sa cle
                              d'idempotence, et l'ecran dit "sera envoye des le
                              retour du reseau". Il ne bloque pas l'enseignant
                              sur son cours suivant
                  deja depose un cahier existe pour cette seance : l'ecran le
                              rend en lecture et ne propose pas un second
                              depot. La cle d'idempotence rend le double envoi
                              inoffensif, mais l'ecran ne doit pas le
                              provoquer

Mouvement         aucun propre a l'ecran : chaque milliseconde d'animation est
                  prise sur les 45 secondes. Le retour haptique des puces
                  phonetiques vient de Pressable

Invariants        la sortie de salle mene ICI, et nulle part ailleurs
                  (invariant 6 du gel) : le cahier n'est pas facultatif, il est
                  l'ecran de sortie
                  ce n'est JAMAIS une destination de la barre basse
                  la cle d'idempotence est generee A LA REDACTION, jamais a
                  l'envoi (invariant 7 du gel) : une file qui genere sa cle au
                  moment d'emettre depose deux fois le meme cahier apres une
                  coupure
                  la file hors ligne est celle qui EXISTE (`FileRapports`,
                  `DepotRapports`, `RapportEnAttente`, table drift
                  `RapportsEnAttente`). Il lui manque une implementation et un
                  branchement, PAS une refonte, et `AppDatabase` garde quatre
                  tables (invariant 12)
                  `inconnu` n'est jamais rendu "Absence" (invariant J3)
                  le curriculum institutionnel n'est pas modifiable d'ici
                  (invariant 8)
                  aucune coordonnee privee de famille : prenom et identifiant
                  immuable, jamais de nom de famille (ADR-008, invariant 4)
                  rien ne se ferme sur minuterie, et surtout pas cet ecran :
                  un cahier qui se valide tout seul est un faux temoignage

Accessibilite     cibles a 44 au minimum, et les puces phonetiques sont
                  DELIBEREMENT plus grandes : elles se cochent a une main, en
                  marchant, sur un telephone tenu par le pouce
                  chaque element du constat porte son libelle parle, y compris
                  l'etat de presence deduit
                  la page se lit de droite a gauche en arabe
                  a 200 % de taille de texte, les trois zones grandissent et
                  le bouton de validation reste atteignable sans defilement
                  horizontal
```

Pourquoi le préremplissage n'est pas un confort mais la condition de
l'existence de l'écran : un cahier à remplir de zéro après cinq cours d'affilée
ne se remplit pas. Le produit le sait depuis l'audit initial
(`docs/architecture/audit-initial.md` ligne 537), et les 45 secondes sont
écrites à quatre endroits du dépôt. Ce qui n'était écrit nulle part, et que
cette fiche pose : **la règle « aucune saisie manuelle de ce qui est
déductible », avec la liste exacte des cinq champs déductibles**. Sans cette
liste, « prérempli » est une intention ; avec elle, c'est vérifiable.

Reste ouvert, et il faut le dire avant que l'écran ne soit construit : les
décisions **D05 et D06** de `docs/parallel-reports/01-decisions.md` — qui peut
corriger ou excuser une présence, avec quel motif obligatoire et dans quel
délai — sont encore `BLOCKED`, sans décision opérateur écrite. Tout
préremplissage de présence s'appuie donc sur une règle métier non tranchée. Le
piège connu, déjà payé une fois : `etat_presence()` déduit « absente » d'un
cours que l'académie n'a pas donné. Un cahier qui affirme une absence que
l'académie a causée est pire qu'un cahier vide.

Reste ouvert également : `0025_role_enseignant.sql` crée bien
`brouillon_cahier(uuid)`, mais **pas** `deposer_cahier(uuid, text, jsonb)`,
qui est la seule RPC d'écriture promise par le gel (§5.1). Sans elle, l'écran
n'a aucun moyen d'écrire `lesson_reports`, et la validation ne peut pas
aboutir. C'est un préalable de l'Agent Z, pas une dette de l'écran.

### `ENS-05` Profil enseignant

```
CODE              ENS-05
Nom               Profil enseignant
Role              Enseignant
Zone              Surface personnelle de l'enseignant (rangee sous
                  Administration dans le registre, par heritage)
Niveau de charge  D
Ecran parent      aucun : DESTINATION DE PREMIER NIVEAU, troisieme et derniere
                  de la barre de l'enseignant
Profondeur        0
Question          Qui suis-je pour l'academie, et ou reglo-je ce qui
                  m'appartient ?

Priorites         P0  l'identite professionnelle autorisee
                  P0  le statut du compte, dit en une phrase
                  P0  l'acces aux parametres reellement personnels,
                      DECONNEXION COMPRISE
                  P1  le contrat : sa nature, sa version, sa date
                      d'acceptation, en LECTURE SEULE
                  P1  les langues et les pays declares
                  P2  les preferences personnelles autorisees

Contenu, et rien de plus
  identite professionnelle autorisee : ce que l'academie affiche de
  l'enseignant, tel que le produit le montre deja aux familles -- prenom et
  identifiant immuable (ADR-008)
  statut du compte : `AccountStatus`, dit en une phrase et sans code
  contrat : `contract_acceptances` rend la sorte (`teacher_nda`), la version
  et la date. LECTURE SEULE, sans exception : un contrat qui s'edite depuis
  l'ecran de la personne qu'il engage n'est plus un contrat
  langues et pays declares
  preferences personnelles autorisees
  acces aux surfaces personnelles, DECONNEXION COMPRISE

Ce qui n'y va PAS, et ou ca vit
  disponibilites operationnelles  ENS-06, et nulle part ailleurs
  planning                        ENS-02
  rapports                        ENS-04, et le bloc "rapports en attente" de
                                  ENS-02
  reglages LiveKit globaux        exploitation, jamais un ecran d'enseignant
  politiques Academie            administration
  paie detaillee                  HORS PERIMETRE, voir ci-dessous

Action principale     aucune au sens du bouton plein : un profil se consulte,
                      il ne se valide pas. Chaque ligne s'edite
                      individuellement, sur le motif de SettingRow
Actions secondaires   editer une preference personnelle
Action tertiaire      aucune
Destructif            la deconnexion. Elle se confirme, et elle est la SEULE
                      action de cet ecran qui perd quelque chose

Mobile            une page, une liste de sections, chaque reglage sur sa ligne
Tablette          identique, gouttiere elargie
Desktop           page + colonnes : l'identite et le statut d'un cote, les
                  reglages de l'autre

Etats             loading   squelette de liste, le temps que la session et le
                            contrat arrivent
                  content   nominal
                  empty     n'existe pas : un enseignant connecte a toujours
                            un profil et un statut
                  error     phrase + "Reessayer" sur la section qui a echoue,
                            les autres restent lisibles. La DECONNEXION reste
                            accessible meme si tout le reste echoue : c'est la
                            seule chose que l'enseignant doit toujours pouvoir
                            faire
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                            page ; l'edition d'une preference est impossible et
                            dite, la deconnexion reste possible

Mouvement         AppBottomSheet a l'ouverture de chaque edition, comme les
                  ecrans de reglages deja construits. Rien d'autre

Invariants        TROIS destinations au niveau 1 pour l'enseignant, pas
                  quatre : "Compte" DISPARAIT (invariant 1 du gel) et c'est
                  ENS-05 qui reprend l'acces aux surfaces personnelles
                  la deconnexion est atteignable depuis CET ecran, sur
                  telephone : la barre basse Material 3 n'accepte aucune entree
                  hors destination, donc sans ENS-05 un enseignant sur
                  telephone n'a plus AUCUN chemin vers la deconnexion
                  les informations contractuelles sensibles sont en lecture
                  seule
                  aucune donnee de paie, aucun solde, aucun montant : ni
                  affiche, ni promis, ni grise
                  un widget ne lit jamais un role, il lit une capacite
                  rien ne se ferme sur minuterie

Accessibilite     cibles a 44
                  chaque ligne porte son titre et sa description au lecteur
                  d'ecran
                  la page se lit de droite a gauche en arabe
                  a 200 % de taille de texte, les lignes de reglage grandissent
                  et aucun libelle n'est rogne
```

**Le report est levé, et c'est écrit ici parce que le registre disait le
contraire.** Le registre marquait `ENS-05` « reporté avec l'ensemble du module
finance (ADR-003) », et la raison de ce report était que le profil devait
porter la paie détaillée. Le contrat du lot Enseignant **retire la paie
détaillée du périmètre** : le profil se construit sans elle, et il n'y a plus
rien à attendre de la finance pour le construire. Décision consignée en
**ADR-027**.

**Le point de cette fiche qu'il ne faut pas rater**, parce qu'il est la seule
raison pour laquelle cet écran est urgent et non simplement dû : la barre de
l'enseignant passe de **quatre destinations à trois**. `destinationsPour(role:
AppRole.teacher)` en rend quatre aujourd'hui (`nav_shell.dart`), dont
« Compte » — et c'est `lib/features/compte/compte_page.dart` qui porte
aujourd'hui la déconnexion (ligne 104-108). « Compte » et « Profil » sont deux
destinations pour la même question, *moi* ; « Compte » sort donc, et `ENS-05`
reprend l'accès aux surfaces personnelles. **Si `ENS-05` ne porte pas la
déconnexion, un enseignant sur téléphone n'a plus aucun chemin pour se
déconnecter** : la barre basse Material 3 n'accepte aucune entrée hors
destination, et `secondairesPour(role: AppRole.teacher)` reste vide. Ce n'est
pas un détail de confort, c'est une porte murée.

État réel au moment où cette fiche est écrite : la route
`/enseignant/profil` rend déjà `ProfilEnseignantPage`, un talon qui affiche le
statut du compte, la charge pédagogique (élèves actifs, heures disponibles) et
un renvoi vers les réglages d'heures. Il n'a **qu'un test de dix-huit lignes**,
qui vérifie un titre. Cette fiche ne décrit donc pas un écran neuf mais un
talon à finir.

⚠ **Une seconde implémentation de `ENS-05` existe ailleurs, et il faut la
trancher avant d'écrire une ligne.** Le worktree
`C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-r2`, branche
`codex/r2-adaptive-shell`, porte une version divergente de
`profil_enseignant_page.dart` et un `lib/core/profil/service_profil_enseignant.dart`.
Détail mesuré et conséquences dans `docs/parallel-reports/SOCLE_CATALOGUE_REPORT.md`.

### `ENS-07` Fiche groupe

```
CODE              ENS-07
Nom               Fiche groupe
Role              Enseignant
Zone              Journee et salle
Niveau de charge  D
Ecran parent      ENS-02, la Journee
Profondeur        1
Question          Qui est dans ce groupe, quand se reunit-il, et y reste-t-il
                  de la place ?

Priorites         P0  les membres du groupe
                  P0  le creneau hebdomadaire du groupe
                  P1  les places libres sur le seuil
                  P2  l'acces a la revue courte (ENS-08)

Contenu
  le groupe          son nom tel que l'administration l'a pose, son type
  son creneau        hebdomadaire : le jour et l'heure de la seule visio
                     commune du groupe
  ses membres        prenom + identifiant immuable + niveau. JAMAIS de nom de
                     famille, de courriel, de telephone ni d'adresse
                     (ADR-008). C'est `mon_groupe_detail(uuid)` qui borne, pas
                     l'ecran : `groupe_detail` est admin seul et rend
                     `student_nom`
  places libres      sur le seuil du groupe : cinq enfants ou six adultes
  revue courte       le chemin vers ENS-08, en action tertiaire

Action principale     aucune : une fiche se lit. Un enseignant ne compose pas
                      son groupe, l'administration le fait (ADM-09)
Actions secondaires   aucune
Action tertiaire      Ouvrir la revue du groupe (ENS-08)
Destructif            aucun

Mobile            page contextuelle : l'en-tete du groupe et son creneau, puis
                  la liste des membres, puis les places libres
Tablette          identique, gouttiere elargie
Desktop           deux colonnes : le groupe et son creneau a gauche, les
                  membres a droite

Etats             loading   squelette : en-tete + trois lignes de membres
                  content   nominal
                  empty     un groupe sans aucun membre : l'ecran le DIT,
                            sans bouton, parce que l'enseignant ne peut pas y
                            remedier. C'est un etat subi, pas une invitation
                  error     phrase + "Reessayer"
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                            page ; la fiche reste consultable si elle a ete
                            lue

Mouvement         aucun propre a l'ecran

Invariants        ce n'est JAMAIS une destination : elle s'ouvre depuis la
                  Journee, contextuellement
                  aucun nom de famille, aucun courriel, aucun telephone, aucune
                  adresse (ADR-008, invariant 4 du gel)
                  l'enseignant ne modifie pas la composition du groupe
                  le seuil affiche est celui du groupe, jamais un chiffre
                  calcule a l'ecran
                  les heures affichees sont celles de l'appareil, sans mention
                  de fuseau (invariant 11 du gel)
                  le zero s'affiche comme les autres valeurs : "0 place libre"
                  se lit, il ne se masque pas

Accessibilite     cibles a 44
                  chaque membre porte son libelle parle : prenom, identifiant,
                  niveau
                  la liste se lit de droite a gauche en arabe
                  a 200 % de taille de texte, les lignes de membre grandissent
                  et l'identifiant immuable ne se coupe pas -- c'est le seul
                  moyen de nommer un eleve sans nom de famille
```

Cet écran est la conséquence directe du **pivot du 19 septembre 2026** : les
cours se donnent par groupe de cinq enfants ou six adultes, avec **une seule
visio commune**, et non plus en 1-à-1. Avant le pivot, « le groupe » n'était pas
une chose qu'un enseignant pouvait regarder — il voyait une liste d'élèves. La
fiche groupe est l'endroit où le groupe devient un objet.

Ses sources sont `mes_groupes_v` et `mon_groupe_detail(uuid)`, créées par la
migration `0025`, et `sessions.groupe_id`, qui est la colonne sans laquelle la
fiche ne s'ouvre pas depuis une séance. Elle est nullable : les séances 1-à-1
antérieures au pivot restent valides.

Deux choses que cette fiche ne fait pas, et pour de bonnes raisons. Elle
n'ouvre pas de destination « Groupes » : l'enseignant a trois destinations, et
il atteint un groupe par le cours qu'il donne, pas par un annuaire. Et elle ne
réconcilie pas les plafonds : `ADR-004` dit encore « groupes jusqu'à 6, plafond
à 2 imposé par trigger tant que `allow_multi_participant_sessions` est faux »,
ce qui ne s'accorde pas avec cinq enfants et six adultes. **Cette contradiction
est réelle et n'appartient pas à cette fiche** : elle demande un ADR du pivot
groupes, signalé dans le rapport de socle.

### `ENS-08` Revue de groupe

```
CODE              ENS-08
Nom               Revue de groupe
Role              Enseignant
Zone              Contenu et transmission
Niveau de charge  D
Ecran parent      ENS-07, la fiche groupe
Profondeur        2
Question          Quelque chose demande-t-il mon attention sur ce groupe ?

Rythme            mensuel ou fin de cycle. JAMAIS un rapport narratif
                  obligatoire, et jamais une echeance qui rappelle : un
                  enseignant a qui l'on demande un texte chaque mois cesse
                  d'ecrire des textes utiles au troisieme mois

Priorites         P0  les anomalies, et rien qu'elles
                  P1  l'etat vide, qui est l'etat NORMAL et frequent
                  P2  aucune priorite de plus : cet ecran ne resume pas le
                      groupe, ENS-07 le fait

N'affiche QUE les anomalies produites par le systeme
  gate a venir              un palier de programme approche pour un eleve
  eleve hors corridor       un eleve sort de la marge de progression attendue
  proposition de transfert  le systeme propose de deplacer un eleve de groupe
  proposition de            le systeme propose de revoir le niveau ou le
  reorientation             parcours d'un eleve

Action principale     aucune : la revue se lit. Une anomalie porte sa propre
                      suite, et l'enseignant n'est pas celui qui tranche un
                      transfert ou une reorientation
Actions secondaires   ouvrir l'anomalie pour en lire le detail
Action tertiaire      aucune
Destructif            aucun

Mobile            page contextuelle, une liste d'anomalies, une carte chacune
Tablette          identique, gouttiere elargie
Desktop           liste a gauche, detail de l'anomalie selectionnee a droite

Etats             loading   squelette de liste, trois lignes
                  content   une carte par anomalie
                  empty     "Rien ne demande votre attention." C'est l'etat
                            NORMAL et FREQUENT de cet ecran, en registre subi,
                            SANS bouton : il n'y a rien a faire, et une
                            invitation a agir serait une invitation a inventer
                            un probleme
                  error     phrase + "Reessayer"
                  offline   le bandeau OfflineBanner de PageShell coiffe la
                            page

Mouvement         aucun propre a l'ecran

Invariants        ce n'est JAMAIS une destination : elle s'ouvre depuis la
                  fiche groupe ou depuis une anomalie de la Journee
                  aucun rapport narratif obligatoire, aucune echeance qui
                  rappelle
                  l'enseignant ne modifie pas le curriculum institutionnel, ne
                  change pas un cycle fixe individuellement, ne valide pas un
                  gate hors regles (invariant 8 du gel)
                  aucun nom de famille (ADR-008)
                  AUCUNE COLONNE DE TIRETS : tant qu'une source de donnees est
                  absente, son bloc est absent, jamais rempli de tirets ni de
                  zeros. C'est la regle que TUT-06 a posee le 13 septembre
                  2026, pour la meme raison
                  le zero s'affiche comme les autres valeurs quand il est un
                  vrai zero -- ce qui n'est pas le cas d'une donnee absente

Accessibilite     cibles a 44
                  chaque anomalie porte son libelle parle, et son type se dit
                  par un mot, jamais par une couleur seule
                  la liste se lit de droite a gauche en arabe
                  a 200 % de taille de texte, les cartes d'anomalie
                  grandissent et aucun libelle de type n'est rogne
```

**Ce que cette fiche doit dire honnêtement, et qui conditionne tout son
contenu.** Les sources de données de cet écran — le programme, la progression,
les évaluations — sont posées par les migrations **`0020` à `0024`**
(`0020_programme_pedagogique`, `0021_diagnostics_placement`,
`0022_progression_suivi`, `0023_evaluations`, `0024_qualite_pedagogique`). Ces
cinq migrations sont **committées sur `main`** et **ne sont PAS appliquées à la
base**. Mesuré le 20 septembre 2026 : la base s'arrête à
`0019_groupes_durcissement`. L'écran est donc **complet** — sa mise en page, ses
états, ses invariants sont décidés ici — mais **ses blocs restent vides jusqu'à
ce que ces migrations soient poussées**, et il ne pose **aucune colonne de
tirets en attendant**. Un écran qui affiche des tirets promet une donnée à
chaque ligne ; un bloc absent ne promet rien.

**Un écart de vocabulaire, qui est une question ouverte et non un oubli.** Les
quatre anomalies que le contrat du lot nomme — gate à venir, élève hors
corridor, proposition de transfert, proposition de réorientation — **n'existent
sous aucun de ces noms dans la base**. Ce que `0020`-`0024` savent produire
aujourd'hui : `anomalies_qualite()` avec trois types
(`rapport_manquant`, `blocage_sans_suivi`, `evaluation_en_retard`, table
`controles_qualite` de `0024`) et `progression_exceptions.type` à deux valeurs
(`blocage`, `derogation`, table de `0022`). De plus, `anomalies_qualite()` est
**réservée à l'administration** (`app_role() = 'admin'`), et **aucune RPC
d'anomalies bornée à l'enseignant n'existe**. La correspondance entre les quatre
anomalies de la fiche et ce que la base sait calculer est donc **ouverte**, et
elle ne s'invente pas : soit une RPC enseignant est écrite, soit les quatre noms
sont remplacés par ceux que la base porte déjà. C'est une décision de socle.
