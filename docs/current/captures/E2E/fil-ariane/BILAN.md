# FIL-ARIANE (PLAN-LOTS rang 22 n) : bilan

Demande du directeur, 06/11/2026 vers 13:20 UTC : « impossible de sortir de cette page, et c'est
partout pareil sur ordinateur […] pour la file d'ariane c'est maintenant, pas après ».

## Ce qui est faux, bloqué ou non prouvé (en premier)

- **Non prouvé en production.** Tout est prouvé sur la pile LOCALE (`tool/e2e/pile.sh`), pas par le
  directeur en production. « Fait » attend sa preuve après fusion.
- **L'enseignant n'a pas de ligne « Bibliothèque » dans son Compte.** La ligne n'existe que pour
  l'élève et la famille (`SessionState.peutOuvrirBibliotheque`, `compte_page.dart:108`). La capture
  « enseignant » ouvre donc la Bibliothèque par son adresse ; le fil y dit « Profil › Bibliothèque ».
  Ajouter la ligne est un changement de capacité, hors de ce lot : à décider.
- **Deux pages restent sans sortie** (le robot les consigne, il ne les corrige pas ; hors zone) :
  - `/tc/mushaf` (élève, 1440 et 390) : le lecteur du Coran ouvert par son adresse. Il n'a ni
    `PageShell`, ni entrée de navigation (l'élève lit le Coran par `/eleve/coran`, qui a sa barre).
  - `/avis/:jeton` (visiteur) : le formulaire d'avis sans compte, page publique hors application.
- **La barre latérale de la famille (et la barre basse) n'est pas dans l'arbre d'accessibilité du
  web** : un lecteur d'écran ne la voit pas. Déjà noté « ECART : onglet absent » par les robots
  précédents. Le robot la touche là où elle est dessinée et l'écrit (`colonne-dessinee`,
  `barre-dessinee`). Cause non trouvée dans ce lot (la sémantique de `_ItemColonne` est présente).
- **Le contrôleur passe la double vérification** grâce à un facteur TOTP amorcé en base locale
  (comme `mfa_direction.mjs`) ; sans lui, toutes ses routes ramènent à `/controleur/mfa`.
- **En arabe, la fiche Finances reste en français** (« Foyer », « Mariam · Finances », textes des
  finances) : les clés `ficheEleve` sont au socle des clés non traduites
  (`tool/ar_socle_non_traduites.txt`). Le fil, lui, se lit bien de droite à gauche. Hors lot.
- **Une page poussée (`push`) ne change pas l'adresse du navigateur** (réglage par défaut de
  go_router) : la Bibliothèque ouverte depuis le Compte garde `#/tuteur/compte` dans la barre
  d'adresse. Le fil reste juste (il lit la pile du routeur), mais un rechargement de la page revient
  au Compte. Constat, non corrigé ici.
- **`test/features/notifications/non_lues_test.dart`** a échoué une fois dans la suite complète
  (machine chargée par le robot), puis passe seul (7/7) : instable sous charge, pas lié au lot.

## Ce qui a été fait

1. **Un seul fil générique dans `PageShell`** (`lib/core/widgets/fil_ariane.dart`,
   `lib/core/router/fil_ariane.dart`). Sur tablette et ordinateur, au-dessus du titre de toute page
   de niveau 2 ou plus. Chaque segment est un lien (`LienFleche` sans flèche, cible 48) ; la page
   courante est en encre atténuée. Le fil est **calculé**, jamais écrit page par page :
   - l'arbre du rôle (`planFilPour`) vient des listes qui font déjà les coquilles :
     `destinationsPour` (famille, élève, enseignant, contrôle, comptabilité), `domainesAdmin` et les
     onglets de chaque domaine (direction) ;
   - les ancêtres se lisent dans l'adresse ; sinon sur la **pile du routeur** (l'écran d'où la page
     a été poussée : la Bibliothèque ouverte depuis le Compte dit « Compte › Bibliothèque ») ; sinon
     le Compte pour les pages du compte et la Bibliothèque, l'accueil pour le reste.
   - **`FilArianeFiche` devient un cas du générique** (`extends FilAriane`) : même rendu, même
     place (sous le titre), mêmes mots. `PageShell` ne pose pas de second fil quand la page passe un
     `FilAriane` en `ligneSousTitre`.
   - Le fil prend la marge déjà réservée au-dessus du titre : la tête ne grandit que de 8 à 32 px
     (`DECISION-DEFILEMENT` règle 3).
   - En arabe, le fil se lit de droite à gauche (`Wrap` sous `Directionality`, chevron miroir,
     paramètre isolé U+2068/U+2069).
2. **Au téléphone, un disque retour garanti hors coquille** : l'écran d'avant (`pop`), sinon
   l'accueil du rôle. Une coquille qui montre sa navigation le dit (`NavigationDeCoquille`, posé par
   `NavShell` et `AdminShell`) ; une tâche focalisée (`actionsCoquille: false`) et une liste de la
   coquille (`listeBureau`) gardent leur règle.
3. **Le robot `tool/e2e/fil_ariane.mjs`** lit l'arbre des routes dans le code du routeur
   (`app_router.dart` et les listes dépliées : 231 `GoRoute`, 229 chemins de production), ouvre
   chaque route de chaque rôle à 1440 et à 390, et touche un geste visible (segment du fil, disque
   retour, barre) en vérifiant que l'adresse change. `rapport.json` liste chaque route jouée.

## Réutilisé, écarté

- Réutilisé : `FilArianeFiche` (généralisé, pas doublé), `LienFleche`, `DisqueRetour`,
  `destinationsPour`, `domainesAdmin` et `onglets*` (libellés des segments, aucun libellé écrit deux
  fois), `ActionsEnteteCoquille` (retour déjà posé par une coquille), la clé
  `ficheEleve.filAriane.foyer`, `commun.mjs` (connexion, captures), le TOTP de `mfa_direction.mjs`.
- Écarté : une table écrite à la main des titres de toutes les routes (elle dériverait du code) ;
  un second composant de fil ; un fil au téléphone (le disque retour y suffit, place comptée) ;
  `ficheEleve.filAriane.suite` (remplacée par `nav.filAriane.suite`, générique).

## Verdict du robot (pile locale, 06/11/2026)

- `fil-ariane/` (passe des routes, 1440 puis 390, sept rôles) : **595 routes jouées** (229 chemins
  distincts). Geste prouvé : segment du fil 207, disque retour 197, barre basse 80, colonne
  sémantique 16, colonne dessinée 45 ; racine du rôle 44 ; exemptées 2 (`/salle`, `/agent` :
  billet ou jeton). **Sans sortie : 4** (`/tc/mushaf` et `/avis/:jeton`, à 1440 et à 390).
  Verdict **rouge** (5 : ces 4 pages, et le contrôle à 390 bloqué à la double vérification par une
  frappe perdue du robot).
- `fil-ariane/controle-390/` (rejeu du contrôle à 390, code rempli d'un coup) : 23 routes, 0 sans
  sortie, **vert**.
- `fil-ariane/r3/` (captures R3) : Bibliothèque depuis le Compte (famille), par son adresse
  (enseignant : pas de ligne), fiche de l'élève (Finances et fiche), page de la direction
  (Pédagogie › Bibliothèque) ; 390 et 1440 ; français et arabe ; sortie prouvée à chaque fois
  (disque retour au téléphone, segment du fil au bureau) : **vert**.

La passe des routes a tourné sur la construction d'avant les deux dernières retouches (isolation
U+2068/U+2069 du paramètre arabe, entrée de galerie, invisible en production) ; les captures R3
et le rejeu du contrôle, sur la construction finale.
Une seule barre de défilement, celle de la page : le fil est dans la tête de `PageShell`, aucun cadre
nouveau.
