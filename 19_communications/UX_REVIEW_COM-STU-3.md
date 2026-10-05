# UX_REVIEW_COM-STU-3 : revue UX des dispositions proposées pour Le Studio, Mode focus (COM-W03F, COM-M05)

Écrite le 05/10/2026, après coup, sur décision prise par délégation du directeur le 05/10 (D-FUS-9 = a ; artefact « Décisions du directeur, 4 octobre », https://claude.ai/artifact/V6mniNAePTUXfpxKbnkEhW). Cadre : `docs/current/DESIGN-GOV-2026-09-26.md` §4.1 à §4.3 et §4 bis (contrats B, C, E). Document seulement : chaque « Modification » est une demande pour le tour de correction.

**Code relu (lecture seule)** : `origin/ui/communications-v1` @ `27689f94` : `lib/features/com_studio/focus/` (`bascule_focus.dart`, `sortie_focus.dart`, `composer_minimal.dart`, `restauration_focus.dart`), `studio_page.dart` (l.34-48, l.335-346, l.840-866), `canal_page.dart` (l.40-48).

**Maquette COM-W03F absente** (QUESTIONS Q3) : la composition suit la spec §10, §20 « FocusStateRestorer », §22 « Focus », §23 « Focus ». Les dispositions sont des PROPOSITIONS d'agent.

**Décisions du 05/10 qui touchent ce lot (par délégation du directeur)** : R-12 = a (corriger le composant commun qui centre « Mode focus » et « Quitter le focus ») ; COM-R-3 constat 5 = a (en Focus, zone d'écriture réduite à une ligne, qui s'agrandit quand on écrit).

**Limite §4.3.** Le Focus ne change aucun droit, n'est transmis à personne et ne modifie pas le canal (spec §10.2) : rien ici n'y touche.

**Statut** : présent dans le code, testé localement (`test/features/com_studio/focus_*_test.dart` ; N-4 corrigé, COM-R-3) ; ni staging, ni déployé.

## Sources

Mêmes codes que `UX_REVIEW_COM-STU-1.md` (AND-WSC, AND-LD lues le 05/10/2026 ; WCAG 2.2 et NN/g relevés le 26/09/2026, non relus le 05/10 : w3.org et nngroup.com bloqués par le proxy de la session ; DESIGN-GOV et `lib/CLAUDE.md` relus le 05/10/2026), plus :

| Code | Source | URL | Date et vérification |
|---|---|---|---|
| W-212 | WCAG 2.2, 2.1.2 No Keyboard Trap (A) | https://www.w3.org/TR/WCAG22/ | relevé le 26/09/2026 (`11_admin/UX_REVIEW_03_ADMIN_DOSSIERS.md`) ; non relu le 05/10 |
| W-2411 | WCAG 2.2, 2.4.11 Focus Not Obscured (Minimum), AA | https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html | lue le 26/09/2026 (`10_classe/UX_REVIEW_CL-4.md`) ; non relue le 05/10 |
| W-233 | WCAG 2.2, 2.3.3 Animation from Interactions, AAA : le mouvement déclenché par une interaction peut être désactivé | https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html | lue le 02/10/2026 (`18_supports_tableau/UX_REVIEW_TB.md`) ; non relue le 05/10 |
| F-DA | Flutter API, `MediaQueryData.disableAnimations` | https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html | lue le 27/09/2026 (`15_accessibilite/UX_REVIEW_06_ACCESSIBILITE.md`) ; non relue le 05/10 (docs.flutter.dev bloqué) |
| F-LR | Flutter API, `SemanticsProperties.liveRegion` : annonce polie, même sans focus | https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html | lue le 26/09/2026 (`10_classe/UX_REVIEW_CL-4.md`) ; non relue le 05/10 |
| DG-E | DESIGN-GOV §4 bis.5 (contrat E) : en réduction de mouvement, durée 0 et translation 0 | `docs/current/DESIGN-GOV-2026-09-26.md` | relu le 05/10/2026 |
| K-54 | `lib/CLAUDE.md` : contenu d'un bouton centré ; `ActionPrincipale` (`pleineLargeur: false` = largeur du contenu) | `lib/CLAUDE.md` | relu le 05/10/2026 |

## Dispositions contrôlées

| # | Disposition proposée (où) | Source | Date | Règle utile | Conclusion | Modification |
|---|---|---|---|---|---|---|
| 1 | Le Focus est un état local du canal ouvert, jamais une route ni le plein écran du navigateur (`bascule_focus.dart:5-12`, `studio_page.dart:34-37`) | SPEC §10.1, §10.2 ; AND-LD (le retour suit la structure) | 05/10 | L'adresse ne change pas ; le retour du navigateur garde son sens | Conforme | Aucune. |
| 2 | Entrée : « Mode focus » dans l'en-tête du canal, `ActionPrincipale` tertiaire, compacte, `pleineLargeur: false`, infobulle avec l'aide §22 (`bascule_focus.dart:176-195`) | DG-B ; K-56 ; NN-10 n°6 | 05/10 ; 26/09 | Action rare = niveau tertiaire, jamais un second bouton plein ; libellé exact du lexique §22 | Ajustée | **R-12 (décision a du 05/10)** : le libellé se centre dans sa ligne (`Center` sans `widthFactor` dans `ActionPrincipale`, `action_principale.dart:164`). Corriger dans le composant commun (`Center(widthFactor: 1)` ou équivalent), puis revoir les captures de tous les écrans qui l'utilisent (K-54 : contenu centré DANS le bouton, bouton à la largeur de son contenu). |
| 3 | Ce qui disparaît en Focus : navigation du Studio (colonne, rail, barre basse), titre, disque retour, actions de coquille ; liste des canaux, recherche, panneau de contexte ; dans l'en-tête du canal, section et nombre de membres (`studio_page.dart:37-42`, `canal_page.dart:40-45`) | SPEC §10.3 ; NN-10 n°8 | 05/10 ; 26/09 | Retirer ce qui n'aide pas la tâche en cours | Conforme | Aucune. |
| 4 | Ce qui reste : fil centré à la largeur de lecture (`AppPage.largeurLecture` = 800), le même champ et « Envoyer », le vocal du fil, les pièces déjà jointes ; « Joindre un fichier » revient à la sortie ; bandeau hors ligne et erreurs du fil gardés (`studio_page.dart:42-43`, `:852` ; `composer_minimal.dart:1-24`) | SPEC §10.4, §10.6, §23 ; DG-D | 05/10 | « Contenu centré + composer + sortie » ; largeur de lecture bornée par le composant, pas ad hoc | Conforme | Aucune. Un seul champ (pas de copie de texte à l'entrée ni à la sortie) : aucune perte d'envoi en attente. |
| 5 | Bandeau de sortie (`FocusExitDock`) : identité « Le Studio », état « Focus activé » (avec « Échap pour quitter » hors téléphone) en `liveRegion`, et « Quitter le focus », `ActionPrincipale` secondaire compacte ; posé dans la même colonne centrée que le fil (R-12, partie corrigée) (`sortie_focus.dart:1-12`, `:50-100` ; `bascule_focus.dart:166-175`) | W-141 ; W-413 ; F-LR ; DG-B | 26/09 ; 05/10 | État dit en mots et annoncé une fois ; sortie visible sur tous les gabarits | Ajustée | Même correction que le point 2 pour « Quitter le focus » (R-12, composant commun). Le rappel d'Échap n'est pas montré sur téléphone : juste, le téléphone sort par le bouton ou le retour. |
| 6 | Le bandeau est le premier élément d'un corps non défilant, jamais l'en-tête de `PageShell` : il reste entier à l'écran à texte × 2 et sur une vue basse ; seul le fil défile (`studio_page.dart:340-346`) | W-2411 ; W-144 | 26/09 (relevé) | La sortie et le focus ne sont jamais masqués | Conforme | Aucune. |
| 7 | 320 de large, texte × 2 : la zone d'écriture et la sortie prennent tout l'écran, aucun message visible (COM-R-3, constat 5) | W-1410 ; W-144 ; NN-10 n°1 | 26/09 (relevé) | À 320 et à 200 %, le contenu principal reste lisible sans perte | Ajustée | **Décision a du 05/10** : en Focus, la zone d'écriture se réduit à une ligne et s'agrandit quand on écrit ; à vérifier par capture `com_studio_focus_320x2_clair.png` et par test (au moins un message visible et « Quitter le focus » entier). |
| 8 | Sorties : « Quitter le focus », Échap seulement si aucun dialogue, feuille ou menu ne l'a déjà consommé, et le retour explicite du téléphone (geste ou touche) quitte le Focus au lieu de quitter la page (`sortie_focus.dart:13-21`, `:151`) | W-212 ; AND-LD ; NN-10 n°3 | 26/09 ; 05/10 | Toujours une sortie claire ; la couche la plus haute reçoit Échap d'abord | Conforme | Aucune. |
| 9 | Focus clavier : à l'entrée il passe sur « Quitter le focus » ; à la sortie il reste sur l'élément qui l'avait (le champ) sinon revient sur « Mode focus » ; aucune portée de focus créée (`bascule_focus.dart:14-18`) | W-212 ; W-243 ; W-247 | 26/09 (relevé) | Pas de piège clavier ; ordre de focus logique ; focus visible | Conforme | Aucune. |
| 10 | Restauration (`FocusStateRestorer`) : capture à l'entrée (position du fil, champ, recherche, panneau), seconde capture à la sortie ; positions et panneaux d'après l'entrée, texte d'après la sortie ; rien ne quitte l'appareil (`restauration_focus.dart:1-27`) | SPEC §10.5, §20 ; NN-10 n°3 | 05/10 ; 26/09 | Aucune perte de texte saisi ; l'utilisateur retrouve son contexte | Conforme | Aucune. Testé (R-COM-10). |
| 11 | Réduction de mouvement : le bandeau apparaît tel quel (`ApparitionDouce` neutralisée), la disposition change d'un coup ; restauration sans animation (`sortie_focus.dart:22-23`, `restauration_focus.dart:25`) | DG-E ; W-233 ; F-DA | 05/10 ; 02/10 ; 27/09 | Durée 0 et translation 0 quand le système le demande | Conforme | Aucune. |

## Dérogations

Aucune. Deux ajustements découlent des décisions du 05/10 (R-12 et constat 5) et ne sont pas encore « présents dans le code » à la date de cette fiche.
