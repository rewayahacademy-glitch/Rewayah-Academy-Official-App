# FI-ACCENT-1 : l'accent de profil n'a pas d'étape qui le porte

Écrit le 04/10/2026 par la session cloud b061fd81 (relevé VERIF-PREP, gravité moyen, session 90248232). Pilotage seulement : aucune ligne de code, aucune couleur, aucun jeton (K-37).

## 1. Ce qui était faux

Trois lignes du pilotage disaient de prendre le bandeau d'accent du profil dans les teintes d'identité des **classes** :

| Où | Ce qui était écrit | Statut |
|---|---|---|
| `00_REPRISE.md` §4, ligne « Accent d'identité stable » (l. 57) | `teintesIdentite` / `teinteGroupe(index)`, « le guide §3.8 point 2 demande justement de réutiliser l'existant » | Barré le 04/10 |
| `00_REPRISE.md` §5 RISQUE (l. 185-186) | « on prend les 32 teintes d'identité existantes » | Barré le 04/10 |
| `02_DECOUPAGE.md`, ligne FI-2 (l. 32) | « bandeau d'accent depuis `teintesIdentite` par clé stable » | Barré le 04/10 |
| Tableau, note de FI-2 | « Bandeau pris dans teintesIdentite par clé stable » | Corrigée le 04/10 |

## 2. Pourquoi c'est faux (sources)

- **Guide Finance V4 §3.2** : le bandeau « n'est PAS … une couleur de classe. C'est uniquement un identifiant visuel de personne ».
- **Guide §3.8 points 2 et 3** : réutiliser les accents **de profils** s'ils existent, **sinon** ajouter seulement les jetons sémantiques nécessaires, figés par test. « Cette extension est la seule exception couleur nouvellement approuvée dans ce chantier. »
- **Code** (`ui/finance-v1` @ 4cc9c472) : aucun accent de profil n'existe. `app_palette.dart:296-306` décrit `teintesIdentite` comme des teintes sans sens, à ne pas indexer directement ; `palette_groupe.dart:10-21` les emploie pour les **classes**, `couverture_ressource.dart:43-76` et `vignette_ressource.dart:123` pour les **couvertures** de la bibliothèque. Prendre ces teintes pour un profil ferait qu'un enfant et sa classe partagent une même couleur à l'écran.
- **FI-0 lui-même**, règle FI15 (`00_REPRISE.md` §7) : l'accent « n'est ni un statut, ni une classe, ni une alerte ».
- **Revue FI-1a** (`UX_REVIEW_08_FINANCE.md:19`, `:152`, X-1) : « jusque-là, FI-2 ne pose aucune teinte de profil ».

## 3. Les quatre textes qui se contredisent

| Texte | Dit |
|---|---|
| Guide Finance V4 §3.2, §3.8 (directeur, 02/10) | Bandeau coloré **derrière** l'avatar ; nouveaux jetons d'accent de profil autorisés. |
| K-37 (directeur, 26/09) | Thème figé, aucune couleur nouvelle jusqu'à la fin des rôles ; toute idée de couleur = une ligne TH-2. |
| AVATAR-1 (`lib/CLAUDE.md`, règles d'interface) | « Jamais de carré ni de fond carré derrière l'avatar » ; le bandeau du foyer « se pose sur la carte, pas sur l'avatar ». |
| FOY-COUL-1 (tableau, voie CORR-2) | Couleur **choisie par le tuteur** dans les paramètres du profil, bandeau contenu dans la carte. |

Le guide §0 dit qu'il prime pour le périmètre Finance ; K-37 et AVATAR-1 sont plus anciens mais généraux. Ce n'est pas à une session de choisir : question au directeur ci-dessous.

## 4. Question au directeur (ligne TH-2, à trancher avant FI-2)

**Comment distinguer les profils d'un même foyer par la couleur ?**

1. **Jetons d'accent de profil nouveaux**, figés par test, distincts des teintes de classe (guide §3.8). Exception à K-37 limitée à ces jetons.
2. **Aucune couleur de profil pour l'instant** : FI-2 livre l'avatar et le prénom sans bandeau ; la couleur viendra avec TH-2 à la fin des rôles. Rien n'est bloqué.
3. **Couleur choisie par le tuteur** (FOY-COUL-1), parmi une courte liste de jetons de profil ; demande un champ serveur (BR-1).

Et pour la place du bandeau : **derrière l'avatar** (guide §3.2) ou **sur la carte** (AVATAR-1, FOY-COUL-1) ?

**Recommandation de la session** : choix 2 maintenant (FI-2 avance sans rien bloquer, conforme à la revue FI-1a et à K-37), puis 1 ou 3 en TH-2. La clé d'accent stable existe déjà dans les données (`FinancesProfil.cleAccent`, FI-1c) : le jour où la couleur est décidée, elle se branche sans toucher aux écrans.

## 5. Conséquence pour FI-2 tant que le directeur n'a pas répondu

FI-2 construit `ProfileIdentityAvatar` et `ProfileIdentityRow` **sans aucune teinte de profil** : photo ou initiale, prénom, âge s'il est rendu, classe, dans cet ordre constant. Jamais `teintesIdentite`, jamais `teinteGroupe`. Le composant reçoit la `cleAccent` mais ne la transforme en aucune couleur.
