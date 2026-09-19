# 03 — Architecture de l'information

## 1. Rewayah n'est pas une application, c'est un écosystème multi-rôles

```
                        REWAYAH
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
     PUBLIC           PARTICIPANTS          STAFF
        │                  │                  │
   site vitrine       élève enfant          admin
   annonces           élève standard        contrôleur
   inscription        élève adulte          comptable
                      tuteur
                      enseignant
```

**Le site public et l'application sont deux produits.** `rewayahacademy.com`
présente, `app` fait travailler. On ne mélange pas leurs registres, leurs
navigations ni leurs gabarits. Ce dépôt ne contient que l'application ; si un
écran de présentation y apparaît un jour, il porte le registre éditorial de
`05-regles-responsive.md` §6, pas celui d'un tableau de bord.

## 2. Rôle, profil, mode, capacité : quatre choses différentes

C'est le point qui empêche le produit de devenir ingérable à mesure que les
rôles se multiplient.

```
IDENTITÉ      un compte, une personne
   ↓
RÔLE          guardian, student, teacher, controller, admin, accountant
   ↓
PROFIL        la ligne de `profiles` : un tuteur peut avoir un profil élève adulte
   ↓
MODE          enfant ou standard : porté par le profil, décidé par l'âge, modifiable
   ↓
CAPACITÉ      « peut poser un créneau », « peut voir un document d'identité »
   ↓
PORTÉE        sur quel foyer, quel élève, quelle séance
```

Règles :

- **Un widget ne lit jamais un rôle.** Il lit une capacité. `if (role == admin)`
  dispersé dans les écrans est une bombe à retardement : le jour où le
  contrôleur invité obtient une partie des droits admin, il faut relire tout le
  code au lieu d'une table.
- **Le mode d'interface n'est pas un rôle** et ne crée pas d'arborescence. Il
  change ce qu'un même écran affiche (ADR-009, déjà tenu).
- **Une même personne peut porter deux profils.** Un tuteur qui apprend est son
  propre foyer : mêmes écrans, portée différente.
- La capacité est **calculée côté serveur** et lue par le client. Le client ne
  la déduit pas d'un rôle. La barrière reste la RLS.

## 3. Cinq niveaux de charge cognitive

Même langage visuel, densité différente. Le niveau détermine la densité de
`01-systeme-visuel.md` §7, le nombre de destinations, et la profondeur permise.

| Niveau | Qui | Objectif | Décisions par écran | Densité |
| :--- | :--- | :--- | :-: | :--- |
| **A** Public | Visiteur | Découvrir | 1 | Aérée |
| **B** Élève enfant | 6 à 8 ans | Apprendre | 1 à 2 | Aérée |
| **C** Élève standard, tuteur, élève adulte | 9 ans et plus | Apprendre et gérer | 3 à 5 | Standard |
| **D** Enseignant, contrôleur | Professionnel | Enseigner, vérifier | 5 à 8 | Standard |
| **E** Admin, comptable | Opérateur | Contrôler, décider | 8 et plus | Compacte sur desktop, standard sur mobile |

**Dense n'est pas laid.** Le niveau E a le droit d'afficher un tableau de
douze colonnes sur desktop. Il n'a pas le droit de le rétrécir sur mobile.

## 4. Les zones du produit

Une zone est un ensemble d'écrans qui partagent un objet métier. Un écran
appartient à une seule zone.

| Zone | Objet central | Écrans |
| :--- | :--- | :--- |
| Accès | Compte, dossier, contrat | connexion, inscription, portail d'attente, accusé, contrat, pièce |
| Foyer | Household, profils, appareils | `TUT-01`, `TUT-02`, ajout d'enfant, appairage, `TUT-05` |
| Disponibilités et affectation | `weekly_availability`, affectation durable | `TUT-04`, `ENS-06`, `ADM-05` |
| Journée | Séance | `ENS-02`, `ELV-02`, `CTR-01` |
| Salle | Séance en cours | `ELV-03`, `ENS-03`, `CTR-02` |
| Contenu | Coran, bibliothèque | `ELV-04` |
| Transmission | Cahier | `ENS-04`, `TUT-06`, suivi élève |
| Administration | Dossier, demande, règle | `ADM-01`, `ADM-02`, `ADM-04`, `ADM-06` |
| Finance | Non ouverte en MVP-0 | — |

Un écran qui ne trouve pas sa zone est un écran mal conçu, pas une zone
manquante.

## 5. Navigation

### La règle, plus stricte que ce que proposait la note de refonte

> **Aucun rôle n'a plus de quatre destinations de premier niveau, et l'enfant
> n'en a aucune.**

La note proposait cinq entrées dont un menu « Plus ». Le produit tient en
quatre, et il faut que ça reste vrai : c'est la seule chose qui empêche la barre
basse de devenir un menu. Le « Plus » est autorisé **seulement** comme quatrième
entrée quand un rôle dépasse, jamais comme cinquième.

> ⚠ **Exception, lot IA-01, 19 septembre 2026.** Cette règle reste vraie pour
> tous les rôles ci-dessous, mais l'opérateur a tranché qu'elle ne suffit plus
> au panneau admin, appelé à grandir avec un RBAC à plusieurs rôles. L'admin
> ne passe plus par `NavShell` : il a sa propre coquille, `AdminShell`
> (`lib/core/widgets/admin_shell.dart`), plafonnée à **huit** domaines de
> premier niveau, jamais plus granulaire (`AdminShell.maxDomaines`, un
> `assert` vivant comme celui-ci). Le détail des huit domaines et leur
> cartographie sur les écrans existants vivent dans
> `docs/architecture/ADMIN_IA_AUDIT.md` et `lib/core/admin/admin_domaine.dart`,
> pas ici.

| Rôle | Destinations | Ce qu'elles sont |
| :--- | :-: | :--- |
| Élève, mode enfant | 0 | Aucune navigation. Deux blocs, retour automatique après le cours |
| Élève, mode standard | 3 | Accueil, Coran, Suivi |
| Tuteur | 4 | Foyer, Disponibilités, Réglages, Suivi |
| Enseignant | 3 | Journée, Créneaux, Profil |
| Contrôleur | 1 | Une liste. Pas de barre |
| Admin | 8 (exception) | Accueil, Opérations, Personnes, Pédagogie, Finance, Configuration, Sécurité et audit, Direction (`AdminShell`, voir note ci-dessus) |
| Comptable | — | Aucun écran en MVP-0 |

Ces destinations sont déjà celles de `lib/core/router/routes.dart`. La refonte ne
les change pas, hors l'exception admin ci-dessus.

### La forme change avec la largeur, pas la structure

| Largeur | Forme | Détail |
| :--- | :--- | :--- |
| < 600 | Barre basse | Les mêmes destinations, icône plus label |
| 600 à 1199 | Rail latéral 80 | Icônes plus labels courts, replié |
| ≥ 1200 | Barre latérale permanente 256 | Labels complets, section active mise en valeur |

Une seule liste de destinations alimente les trois formes. Trois listes
finiraient par diverger.

### Profondeur

Trois niveaux au maximum, la salle exceptée.

```
autorisé            Accueil → Élève → Évaluation
refusé              Accueil → Académie → Élèves → Groupe → Élève → Cours → Détail
```

Si une fonctionnalité demande un quatrième niveau, c'est l'architecture qu'il
faut revoir, pas la navigation qu'il faut allonger. Le remède habituel est un
panneau de détail sur desktop plutôt qu'une page de plus.

**La salle est hors arborescence** : elle se prend l'écran entier, son URL est
éphémère et non mémorisable (ADR-005), et elle a une seule sortie, qui mène à
`ENS-04` pour l'enseignant et à `ELV-02` pour l'élève.

## 6. Deux cas particuliers à ne pas rater

**Le contrôleur n'a pas le tableau de bord de l'admin.** Sa question n'est pas
« que se passe-t-il » mais « qu'est-ce qui nécessite une vérification ». Son
écran est un flux d'anomalies, pas une grille de statistiques.

**Le tuteur n'a pas le tableau de bord d'un gestionnaire.** `TUT-01` est un
foyer : une ligne par enfant, l'état en direct, et ce qu'il y a à confirmer.
Aucune statistique décorative.

## 7. Le rattachement d'un écran nouveau

Avant d'écrire un fichier, un écran doit pouvoir remplir ceci. S'il ne le peut
pas, il n'est pas prêt.

```
Rôle                  Enseignant
Zone                  Transmission
Niveau de charge      D
Écran parent          ENS-02
Profondeur            2
Question              Qu'est-ce que j'ai travaillé avec cet élève ?
Action principale     Valider le cahier
Actions secondaires   Reprendre un point de phonétique
Destructif            aucun
Présentation mobile   page
Présentation desktop  panneau de détail
États                 loading, content, empty, error, offline
```

Le catalogue d'écrans (`08-catalogue-ecrans.md`) tient ces fiches. Un écran sans
fiche ne s'implémente pas.

## 8. État métier, état UI, préférence personnelle

Ajouté au lot B0 (Bible Frontend V2 §40-41). Trois familles, et un `state`
Flutter qui ne dit jamais à laquelle il appartient : c'est à qui l'écrit de le
savoir avant de choisir où le ranger.

| Famille | Exemples dans ce produit | Vit dans |
| :--- | :--- | :--- |
| **État métier** | Présence, session, document partagé de la salle, droits, progression | La base (Supabase), lu par un provider Riverpod. Jamais une variable locale d'écran |
| **État UI** | Menu ouvert, feuille ouverte, focus visuel, position de défilement, mode compact d'un panneau | L'arbre de widgets ou un `StateProvider` local à l'écran. Ne survit pas à la navigation |
| **Préférence personnelle** | Thème clair/sombre (lot T3), zoom du lecteur, préférences de lecture | Le mécanisme de stockage local déjà existant (`lib/core/cache/secure/stockage_securise.dart`, `lib/core/cache/db/app_database.dart`). Jamais réinventé par écran |

**Ne jamais stocker un état métier dans une variable d'UI locale** : un
`setState` qui retient « l'élève est présent » se désynchronise de la base à la
première reconnexion, et l'écran ment sans qu'aucun test ne le voie, puisque le
test ne rejoue pas la reconnexion.

### Restauration

Quand l'application est interrompue puis reprise, restaurer lorsque pertinent :
route, session, document, position, sélection, mode d'affichage, formulaire non
soumis quand c'est sûr de le faire.

Ne jamais restaurer aveuglément :

- un état expiré ;
- une permission devenue invalide (elle a pu changer pendant l'absence) ;
- une session terminée ;
- une action déjà consommée (un dossier déjà validé ne se rouvre pas sur un
  formulaire qui propose de le revalider).

C'est la même distinction qui gouverne `24. QURAN READER — ÉTATS PERSONNELS VS
PARTAGÉS` de la Bible, spécifiée pour le lecteur au lot N0 : l'état partagé de
la salle est un état métier, l'état personnel de lecture de l'élève est une
préférence personnelle, et l'un ne doit jamais écraser silencieusement l'autre.
