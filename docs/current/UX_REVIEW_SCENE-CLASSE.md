# UX_REVIEW SCENE-CLASSE (11/11/2026)

Lot : la grille des visages, un seul cadre, un seul état de la scène. Première moitié du modèle
`docs/current/salle/MODES-AFFICHAGE.md` (§2 règles 1 à 4 et 7, §3, trois lignes du §5). Journal : D-028.

Demande du directeur (11/11/2026) : « Les vidéos sont grandes, non ? Il faut juste des carrés comme
sur Zoom, et pense à les rendre esthétiques (leur layout) pour que ce soit plaisant de voir la grille,
ajoute aussi des animations. [...] il faut que tout soit bien coordonné et ne pas agir comme des
entités différentes. »

## La règle appliquée

| Règle | Source | Date de lecture | Conclusion | Modification |
| :--- | :--- | :--- | :--- | :--- |
| Grille de galerie : pour N personnes, le nombre de colonnes qui donne les plus grands cadres à forme fixe ; dernière rangée centrée ; tuiles qui ne s'étirent pas | Zoom, vue galerie (support.zoom.com, « Gallery view ») ; Google Meet, disposition « Mosaïque » (support.google.com/meet, « Change your layout ») ; Microsoft Teams, galerie 16:9 (learn.microsoft.com, « Video layouts in Teams ») ; FaceTime de groupe (support.apple.com, tuiles en grille, celle qui parle mise en avant) | 11/11/2026 | Les quatre gardent une forme fixe par tuile et centrent la grille ; aucune n'étire une tuile pour remplir l'écran. C'était le défaut vu au banc (171 x 330 au téléphone, 616 x 344 sur ordinateur) | `calculerGrille` essaie 1 à N colonnes et garde le plus grand cadre ; `rectsGrille` centre la grille et chaque rangée |
| Forme du cadre : carré en portrait étroit, 4/3 ailleurs | Meet (tuiles proches du carré sur téléphone en portrait), Zoom et Teams (16:9 ou 4:3 sur ordinateur) ; MODES-AFFICHAGE §3 | 11/11/2026 | Le carré utilise la largeur d'un téléphone sans faire des bandes ; 4/3 garde un visage entier sur un écran large (16:9 couperait le menton d'une webcam tenue de près) | `rapportCadre(Gabarit, Orientation)` : `Gabarit.mobile` en portrait, 1 ; sinon 4/3. Aucune largeur comparée à un nombre hors d'`AppGabarit` |
| Borne : un cadre ne dépasse pas **480 points** de large | Meet et Zoom plafonnent la taille d'une tuile quand il y a peu de monde (deux personnes dans une grande fenêtre ne remplissent pas l'écran) ; Fitts et la loi de proximité (Gestalt) : des visages trop écartés obligent l'œil à balayer | 11/11/2026 | 480 x 360 (4/3), c'est un visage à taille naturelle à un bras de l'écran ; une webcam de 720 lignes s'y voit nette ; à deux ou trois dans 1440, les cadres restent des cadres (et non 600 de large), groupés au centre | `largeurMaxCadre = 7,5 respirations` (480), dans `grille_visages.dart` |
| Plancher : jamais de cadre sous **96 points** ; au-delà, des pages entières | WCAG 2.5.8 (cible de 24 au moins, le menu de gestes en garde 48) ; lisibilité du nom et du signe du micro | 11/11/2026 | Sous 96, le nom et le micro ne se lisent plus et le menu de gestes couvre le visage | `coteMinCadre = 96` ; au-delà, pages entières et `BarrePrecedentSuivant` (règle NAV-FLECHES-1 du dépôt) |
| Rien ne passe sur un visage | `lib/CLAUDE.md` « aucun élément ne recouvre un contenu à lire » ; MODES-AFFICHAGE §2 règle 4 | 11/11/2026 | Sa propre image flottait par-dessus la grille et la barre ; « Ouvrir le Coran » était posé sur un visage | Sa propre image est le dernier cadre ; la barre et la capsule ont leur place réservée ; « Ouvrir le Coran » sous la grille, centré |
| Redimensionnement, zoom à 400 % | WCAG 1.4.10 (Reflow) | 11/11/2026 | La grille se recalcule pour toute place, de 64 à 480 de côté ; au plus petit, pages entières ; aucun défilement horizontal de page | Testé de 320 x 568 à 1920 x 1080, 1 à 12 personnes |
| Contraste des éléments non textuels | WCAG 1.4.11 | 11/11/2026 | L'étiquette du nom est une pastille sombre à 72 % (encre claire sur fond sombre, environ 6,5:1 même sur une image blanche) ; le micro fermé est une icône barrée et un mot lu ; l'anneau de parole (4 points, encre d'accent) n'est jamais le seul signal | La parole est aussi dite au lecteur d'écran (« en train de parler ») ; « Récite » garde son mot et un contour franc |
| Mouvement | WCAG 2.3.3 (Animation from Interactions) ; jetons TRANSITIONS-SALLE (D-025) | 11/11/2026 | Arrivée : grandit de 85 à 100 % en fondu (200 ms) ; départ : rétrécit en fondu (130 ms), puis les autres glissent sur le ressort sans rebond (280 ms) ; « Réduire les animations » : fondu seul, les cadres sautent à leur place ; aucune boucle | `AppMouvement.fonduEntree`, `fonduSortie`, `deplacementEntree`, `ressortDeplacement` ; un seul jeton nouveau (`graceDepartVisage`, ce n'est pas un mouvement) |
| Reconnexion | Meet garde la tuile d'une personne dont le réseau saute quelques secondes | 11/11/2026 | Une personne qui disparaît garde sa place, atténuée, **3 secondes** ; revenue à temps, rien ne bouge ; sinon elle part. Sa propre image (caméra coupée) part aussitôt | `EntreeGrille.attendreAuDepart`, `AppMouvement.graceDepartVisage` |
| Taille de fenêtre qui change | Habitude des quatre outils | 11/11/2026 | La grille suit la fenêtre sans animer (sinon elle « nage » pendant qu'on tire le bord) | `GrilleVisages` compare la place à la précédente |

## Ce qui a été écarté

- **Étirer les cadres pour remplir la scène** (l'ancienne `_Galerie` par `GridView.count`) : c'est le
  défaut que le directeur a vu.
- **Le 16:9 de Teams** : coupe le menton et le front d'une webcam tenue près du visage ; la bouche est ce
  que l'enseignant regarde pour corriger une récitation.
- **Mettre en avant celui qui parle en changeant l'ordre** (« locuteur actif » de Zoom) : MODES-AFFICHAGE
  §3, l'ordre ne bouge pas, l'anneau suffit ; une grille qui se réordonne à chaque bruit est illisible.
- **Des points de page seuls** : remplacés par la barre précédent / suivant du dépôt (NAV-FLECHES-1),
  qui se lit au clavier et au lecteur d'écran ; le glissement du doigt marche aussi.
- **Garder sa propre image quand on est seul dans la salle** : la règle dit « seul : la scène d'attente,
  inchangée » ; l'image flottante disparaît donc aussi de l'attente (à confirmer par le directeur,
  voir D-028).

## Limites connues

- Au plus petit téléphone (320 x 568), sept personnes (une classe pleine avec l'enseignant) ne tiennent
  pas à 96 points : trois colonnes de 96 et leurs écarts font 320, plus que la place. La grille passe
  alors en deux pages (6 puis 1). Dès 360 de large, tout tient sur une page.
- La borne de 480 et le plancher de 96 sont des propositions : au directeur de les confirmer en
  production.
