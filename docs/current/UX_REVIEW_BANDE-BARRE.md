# UX_REVIEW BANDE-BARRE (11/11/2026)

Demande : le garde-cap, le 11/11/2026, pour le directeur. Le directeur voit toujours un rectangle derrière la barre en production, malgré la PR 404.

## D'abord : ce qui n'est pas prouvé

- Rien n'est prouvé en production. Le directeur seul le prouvera, après la fusion.
- Les données de test sont pauvres. Sur les 12 écrans relevés, deux seulement dépassent l'écran : Compte du tuteur et Journée de l'enseignant. Pour les dix autres, le passage sous la barre n'est prouvé qu'avec un contenu de test (`test/widgets/nav_shell_sans_bande_test.dart`).
- L'écran Coran de l'élève n'est pas capturé : dans ce harnais, il appelle Supabase.
- Une page qui porte son propre défilement (liste paresseuse sous une tête fixe) garde l'encart réservé au bas de sa liste. Elle n'est pas couverte par ce lot : un `ListView` qui ignore `MediaQuery.padding` s'arrête encore au-dessus de la barre.

## Cause relevée

Le relevé est dans `docs/current/captures/E2E/bande-barre/bande_avant_*`, sur le vrai routeur, en clair et en sombre.

- Au repos, aucune différence de couleur : la couleur sous la barre est celle du fond de la page sur tous les écrans relevés. La PR 404 marchait sur ce point.
- **Le rectangle apparaît quand la page défile.** La barre avait sa place réservée dans une colonne, sous la page ; la PR 404 n'en avait changé que la couleur. Le contenu s'arrête donc net sur une ligne droite au-dessus de la pilule, et la pilule semble posée sur un rectangle de la couleur de la page. Voir `bande_avant_tuteur_compte_clair_defile.png` : la ligne « Créer mon profil élève » est coupée net.

## Correction, dans le core seul

- **`NavShell`** : la barre flotte sur la page, posée dans une pile au-dessus d'elle. Il n'y a plus de place réservée.
  - La hauteur mesurée de la barre, zone sûre comprise, devient l'encart bas de la page (`MediaQuery.padding.bottom`).
  - La page est ainsi prévenue : sa fin, ses menus et ses avis s'arrêtent au-dessus de la barre.
- **`PageShell`** : une page qui défile ne retire plus l'encart bas hors de son défilement. Elle l'ajoute à la fin de son contenu, qui passe ainsi sous la pilule et le cercle, puis s'arrête au-dessus d'eux.
- **Feuilles du bas** (`AppBottomSheet.ouvrir`) : la feuille monte depuis le bord de l'écran, là où est la barre. La barre s'efface en fondu le temps que la feuille reste ouverte (`ControleurBarreBasse.effacerPourUneFeuille`). C'est la solution qui manquait à la PR 404. Les boîtes de dialogue et les menus ne changent pas : ils évitent l'encart.

## Règles consultées

| Règle | Source | Date | Conclusion | Modification |
| :--- | :--- | :--- | :--- | :--- |
| Barre d'onglets flottante au-dessus du contenu, qui défile dessous | Apple HIG, Tab bars (« Liquid Glass ») | consulté le 11/11/2026 | La barre flotte, le contenu passe dessous et reste atteignable par défilement | Pile au lieu d'une colonne |
| Encart bas : la fin du contenu n'est jamais cachée | Flutter, `MediaQuery.padding` et `SafeArea` | 11/11/2026 | L'encart dit à la page où s'arrêter | Hauteur de la barre en encart bas |
| Une feuille du bas modale passe au-dessus de la barre de navigation | Material 3, Bottom sheets | 11/11/2026 | La feuille ne doit pas glisser sous la barre | La barre s'efface tant que la feuille est ouverte |
| DECISION-DEFILEMENT (01/11/2026) : la page défile jusqu'au bord, rien de gros collé au-dessus du contenu | `docs/current/DECISION-DEFILEMENT-2026-11-01.md` | 01/11/2026 | Un rectangle fixe en bas d'écran contredisait la règle | Supprimé |

## Preuves

- `docs/current/captures/E2E/bande-barre/planche_bande_avant_apres.png` montre, de gauche à droite :
  - avant, défilé ;
  - après, défilé ;
  - après, en fin de page.
  Les rangées sont Compte du tuteur et Journée de l'enseignant, en clair et en sombre.
- Les captures une à une (`bande_avant_*`, `bande_apres_*`) couvrent :
  - le tuteur : Accueil, Foyer, Historique, Compte ;
  - l'enseignant : Journée, Classes, Messages, Profil ;
  - l'élève : Accueil, Suivi ;
  - le contrôleur : Accueil, Historique.
- Tests : `test/widgets/nav_shell_sans_bande_test.dart`, qui vérifie :
  - le contenu sous la barre ;
  - la fin au-dessus de la barre ;
  - la feuille qui efface la barre, puis la barre qui revient.
