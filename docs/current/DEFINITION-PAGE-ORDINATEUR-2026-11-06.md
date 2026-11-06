# Définition de la page d'ordinateur (WEB-BUREAU, 06/11/2026)

Statut : **proposée**, à valider par le garde-cap avant tout changement de code au-delà de
l'étape 1 (PLAN-LOTS §7 rang 22 n, méthode (a)). Une fois validée, c'est la règle que teste le
garde-fou permanent (méthode (c)) sur chaque route à 1440 × 900.

Pourquoi (directeur, 06/11/2026 vers 13:55 UTC) : « la racine du problème est seule et unique
(c'est une app mobile étirée sur web) […] sans oublier les en-têtes et pieds de page qui prennent la
moitié de l'écran ». Références exigées par le directeur à 17:30 UTC : « des RÉFÉRENCES, et plus
aucune devinette ».

## 1. Les références, dans l'ordre où elles font foi

1. **Les décisions datées de `docs/current/`**, quand elles sont plus récentes que la Bible
   (consigne du pilote, 06/11) : en particulier `DECISION-DEFILEMENT-2026-11-01.md` et
   `DECISION-LISTES-2026-10-23.md`. Les contradictions sont écrites au §5, pas tranchées ici.
2. **La Bible Frontend V2 du directeur, réintégrée le 06/11** (r1) :
   `docs/archive/2026-09-pre-remise-a-plat/design/05-regles-responsive.md` (« Ne pas agrandir
   l'application mobile. Réorganiser. »), `03-architecture-information.md`,
   `07-catalogue-composants.md`, `08-catalogue-ecrans.md` (registre écran par écran, colonne
   « Desktop »), `04-systeme-mouvement.md`.
3. **Material Design 3, pages officielles lues le 06/11 par Context7** (r2), citées règle par
   règle au §3.
4. **Google Classroom sur ordinateur** (r3), produit de comparaison : **bloqué**, voir §6.

## 2. La règle de la Bible, reprise telle quelle

> **Ne pas agrandir l'application mobile. Réorganiser.** (05 §2)

Trois remèdes, dans cet ordre (05 §2) : (1) ouvrir le détail à côté au lieu de naviguer (liste à
gauche, détail à droite) ; (2) passer d'une à plusieurs colonnes, jamais plus de trois ; (3) centrer
et borner : 1200 au plus, un texte suivi sur 68 caractères.

Le **registre écran par écran** (08 §1, colonne « Desktop ») est la cible de chaque écran : par
exemple `TUT-01` Accueil famille « 2 à 3 colonnes + colonne à confirmer », `TUT-02` Foyer « Deux
colonnes », `ENS-02` Journée « Colonne + panneau de détail », `ADM-02` Validation « File à gauche,
dossier à droite », `ADM-04` Journal « Tableau dense », suivi élève « Liste + détail ». Les fiches
de la section 6 du même fichier disent, pour plusieurs écrans, « desktop multi-colonnes : non
implémenté, reporté » (`TUT-01`, `ENS-02`, `ADM-01`, `TUT-05`) : **la cause écrite du problème du
directeur est ce report, jamais repris**.

## 3. La règle mesurable : à partir de 1200 px de large

| N° | Règle | Source | Mesure du garde-fou (1440 × 900, texte × 1) |
|---|---|---|---|
| **B1** | Barre latérale permanente du rôle ; jamais la barre du bas. | Bible 03 « La forme change avec la largeur » (≥ 1200 : barre latérale permanente 256) ; M3 [navigation drawer, guidelines](https://m3.material.io/components/navigation-drawer/guidelines) (standard drawer pour expanded, large, extra-large ; « Avoid using a navigation drawer with other primary navigation components, such as a navigation bar ») ; M3 [navigation bar, guidelines](https://m3.material.io/components/navigation-bar/guidelines) (« Only use navigation bars for compact and medium ») | La barre latérale de `NavShell` ou d'`AdminShell` est rendue ; la barre basse ne l'est pas. |
| **B2** | Une sortie visible, toujours. | Bible 03 « Profondeur » (la salle a une seule sortie) ; Nielsen, heuristique 3 | Barre latérale, segment du fil, ou disque retour. |
| **B3** | Le chemin cliquable en tête du contenu, sur toute page de niveau 2 ou plus. | Bible 03 « Profondeur » (trois niveaux au plus) ; brique `FilAriane` (généralise `FilArianeFiche`, maquette 06) | `FilAriane` au-dessus du titre ; chaque segment sauf le dernier mène quelque part. |
| **B4** | Largeur de lecture bornée. | Bible 05 §2 (1200 ; 68 caractères) ; M3 [lists, guidelines, line length](https://m3.material.io/components/lists/guidelines) (« ideal line length … 40 to 60 characters, but large-screen devices can accommodate up to 120 ») | Un texte suivi ne dépasse pas 800 px (`AppPage.largeurLecture`) ; la colonne ne dépasse pas 1200 (1440 pour `listeBureau`). |
| **B5** | Aucun bouton ni aucune carte étirés sur toute la largeur. | Bible 05 §2 (remèdes 2 et 3) ; M3 [buttons, guidelines](https://m3.material.io/components/buttons/guidelines) (« A button container's width is dynamically set to fit its label text ») ; `DESIGN-GOV` contrats A à E (pas de bouton pleine largeur sur bureau sans justification) | Un bouton plein ne dépasse pas 640 px (`largeurFormulaire`), hors d'une carte ou feuille déjà bornée. Une carte seule sur sa rangée ne dépasse pas 800 px ; plus large, elle partage sa rangée ou c'est une table. |
| **B6** | En-tête compact. | Bible 05 §9 (zone en-tête : navigation, contexte, titre, une action ; interdit « information secondaire massive ») ; `DECISION-DEFILEMENT` règle 3 | La tête fixe de `PageShell` mesure au plus 160 px. |
| **B7** | Pied compact. | Bible 05 §9 (zone d'action basse : une action primaire, jamais toutes les actions) | La zone d'action collée mesure au plus 96 px ; son bouton suit B5. |
| **B8** | Liste et détail côte à côte quand l'écran s'y prête. | Bible 05 §2 remède 1 et §3 ; M3 [list-detail](https://m3.material.io/foundations/layout/canonical-examples/list-detail) (Expanded 840+ et Large : 2 panes) ; M3 [breakpoints](https://m3.material.io/foundations/layout/breakpoints/overview) (Large : « 1 or 2 (recommended) » panes) | Revue, liste tenue à l'inventaire : les écrans dont le registre de la Bible dit « liste + détail », « file à gauche », « deux colonnes » passent par `EspaceTravailAdaptatif`. |
| **B9** | Aucune feuille du bas au-delà de 840 px. | M3 [bottom sheets, overview](https://m3.material.io/components/bottom-sheets/overview) (« Use bottom sheets in compact and medium ») et [guidelines](https://m3.material.io/components/bottom-sheets/guidelines) (« On larger expanded breakpoints … a bottom sheet can be swapped for a side sheet ») ; M3 [side sheets](https://m3.material.io/components/side-sheets/overview) | À partir de 840, `AppBottomSheet` se rend en feuille latérale ou en dialogue borné à 560 (`largeurDialogue`). Un contenu tiers (paiement) prend la colonne de la page, sortie en haut et Échap. |
| **B10** | Le téléphone ne change pas. | Bible 05 §1 (trois présentations, pas quatre applications) | Sous 600 px, captures 390 avant et après identiques, hors fil. |

## 4. Les placements demandés par le directeur (17:30 UTC), à confirmer par le garde-cap

| N° | Placement | Source | Où se corrige |
|---|---|---|---|
| **P1** | La déconnexion au même endroit pour tous les rôles : menu du compte en haut à droite sur ordinateur, bas du Compte au téléphone. | Demande du directeur ; M3 [breakpoints](https://m3.material.io/foundations/layout/breakpoints/overview) (Action : « Menu » à partir de medium) | Coquilles (`NavShell`, `AdminShell`) : une seule action « compte » d'en-tête. Aujourd'hui `AdminShell` a « Mon compte » en en-tête, les autres rôles l'ont dans leur page Compte. |
| **P2** | Aucune feuille du bas au-delà de 840 px. | B9 | `AppBottomSheet`, une fois. |
| **P3** | Menus aux couleurs du thème, corrigés une fois dans `MenuActions` et `MenuFiltre`. | M3 [color roles](https://m3.material.io/styles/color/roles) (menus sur les rôles « surface container ») ; M3 [menus, guidelines](https://m3.material.io/components/menus/guidelines) (« standard colors … more utilitarian ») | `MenuActions`, `MenuFiltre` : surface et encre de `AppPalette`, jamais les couleurs par défaut de Material. |
| **P4** | Barre latérale en sections, 7 destinations principales au plus. | Demande du directeur ; M3 [navigation drawer, guidelines](https://m3.material.io/components/navigation-drawer/guidelines) (« Use a navigation drawer for 5 or more primary destinations » ; « Use full-width dividers to separate groups of destinations » ; « group related destinations together ») | `NavShell` (barre latérale seulement ; la barre du bas garde 4 au plus) et `AdminShell`. |

## 5. Contradictions écrites, non tranchées (la décision datée la plus récente prévaut)

1. **Nombre de destinations.** Bible 03 : « Aucun rôle n'a plus de quatre destinations de premier
   niveau » (exception direction : huit, `AdminShell.maxDomaines`), et `NavShell.maxDestinations`
   l'impose par une assertion. Demande du directeur du 06/11 (P4) : barre latérale en sections, 7
   destinations principales au plus. Proposition : la barre du bas garde 4 au plus (téléphone) ;
   la barre latérale de l'ordinateur peut en montrer jusqu'à 7, en sections. **À trancher par le
   garde-cap ou le directeur.**
2. **Défilement d'une table.** Bible 07 (`DataCollection`) : « Il porte sa propre zone
   défilante … la page qui l'emploie passe donc `defilante: false` ». `DECISION-DEFILEMENT` du
   01/11 : une seule barre de défilement, celle de la page. La décision du 01/11 prévaut.
3. **Onglets.** Bible 07 (`SousNavigationDomaine`) : « rendue en `TabBar` scrollable ».
   ONGLETS-1 (`lib/CLAUDE.md`) : jamais de rangée qui défile, `SelecteurSection`. ONGLETS-1
   prévaut. Bible 07 (`SegmentedTabs`) : « Sur desktop, remplacés par deux colonnes quand c'est
   possible » : compatible avec B8.
4. **Accueil famille.** Bible 08 (`TUT-01`) : « 2 à 3 colonnes + colonne « à confirmer » ». Le
   Foyer et l'Accueil ont été redessinés depuis (Tuteur V1, maquettes de septembre et octobre) :
   la cible exacte de chaque écran est à relire contre la dernière maquette datée avant le lot de
   l'écran.
5. **Rail entre 600 et 1199.** Bible 03 : rail de 80 entre 600 et 1199. M3 (drawer guidelines) :
   drawer standard possible dès « expanded » (840). `AppGabarit` suit la Bible (barre latérale à
   1200). Aucun changement proposé.

## 6. Ce qui est bloqué ou non prouvé

- **r3, Google Classroom** : aucune capture faite. Il faut un compte Classroom (école de test) ;
  la session n'en a pas, et une capture de page publicitaire ne montre pas le produit. Deux
  issues : le directeur fournit les captures, ou un compte de test est créé. La comparaison
  « capture contre capture, par modèle » attend.
- **B4, B6, B7** ne sont mesurés par aucun robot aujourd'hui ; ils le seront par le garde-fou
  Flutter.
- Les captures « avant » de la pile locale ont peu de données (un foyer, un élève, une classe) :
  elles montrent moins l'étirement que la capture du directeur.

## 7. Exceptions admises par écrit (la liste ne peut que rétrécir)

| Route | Nature | Raison | Fin |
|---|---|---|---|
| pages d'entrée (questionnaire, connexion, inscription, attente, juridique) | permanente | sans rôle : pas de barre (B1) ; elles gardent B2, B4, B5, B9 | — |
| `/avis/:jeton` | permanente | page publique sans application (verdict du garde-cap, 06/11) | — |
| `/salle`, salle d'observation | permanente | composition validée par le directeur le 26/10, plein écran, avec Quitter | — |
| `/controleur/mfa` | permanente | porte de double vérification ; sortie par « Se déconnecter » | — |
| `/tc/mushaf` | **temporaire** | page sans sortie ; à fermer par une redirection de `/tc/mushaf` vers `/eleve/coran` pour l'élève (verdict du garde-cap, 06/11) | premier lot de code WEB-BUREAU |

Le fichier d'exceptions du garde-fou reprend ce tableau ; comme `tool/branchement_tolere.txt`, il
ne peut que rétrécir.

## 8. Ce que la définition ne fait pas

Elle ne change aucun droit, aucun état serveur, aucun texte métier (`DESIGN-GOV` §4.3) ; elle ne
crée aucun écran. Elle se corrige dans les composants partagés (`PageShell`, coquilles,
`EspaceTravailAdaptatif`, `AppBottomSheet`, `ActionPrincipale`, `AppCard`, `MenuActions`,
`MenuFiltre`), jamais écran par écran (D9).
