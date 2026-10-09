<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## FILTRES-1b (reprise) : relecture adverse de `corrections/c2-filtres-b` (0de88e47)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** Les huit points de la demande sont présents dans le code et testés localement. Je n'ai trouvé aucun défaut majeur. Il reste une réserve moyenne, trois mineures, et des défauts antérieurs à relayer.

Statut : présent dans le code, testé localement. Ni staging, ni déploiement. Je n'ai rien poussé. Le worktree `rv-FILTRES-1b-68` est retiré.

### Périmètre
- Le diff 5a52ff30..0de88e47 compte 103 fichiers. Il ne touche ni `page_shell.dart`, ni `admin_shell.dart`, ni le thème, `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json` ou le rendu du Coran.
- Les 5 commits sont en français et se terminent exactement par les deux lignes demandées. Aucun autre identifiant de modèle n'y figure.

### Outils
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1532, autant que la base mesurée avec le même outil. Le total n'augmente pas.
- `verifier_revue --regle=wrap-filtres` : aucune violation.
- `verifier_jetons` : 37, autant que la base.

### Tests (toujours avec --concurrency=2)

| Dossier | Résultat |
| :--- | :--- |
| `test/features` | 3131 succès, 2166 sautés, 0 échec |
| `test/core` | 749 succès |
| `test/widgets` | 299 succès |
| `test/accessibilite` et `test/tc_observation` | 381 succès |
| Tests du lot (5 fichiers) | 135 succès |

### Mutations (j'annule une correction, les tests doivent échouer)

| N° | Mutation | Résultat |
| :--- | :--- | :--- |
| M1 | `qualite_page.dart` remis à la base | 8 échecs sur 8 (320 et 1440, x1 et x2, LTR et RTL) |
| M2 | La vue ne s'arrête plus au début d'une puce | 6 échecs |
| M2b | Retour au centrage sur le filtre retenu | 6 échecs |
| M3 | Seconde rangée de puces rétablie à partir de 600 px | 16 échecs |
| M4 | Ligne d'Observations toujours sur deux colonnes, sans empilement | 2 échecs (320 x2, LTR et RTL) |
| M5 | Curseur de défilement à la couleur d'accent | Le test « barre neutre » échoue |
| M6 | Marqueur « Choix de formulaire » retiré, puis un vrai `Wrap` de `FilterPill` | `wrap-filtres` signale 1 violation dans chaque cas |

Les tests mordent sur chacun des huit points.

### Les points de la demande
1. **Qualité.** La page ne plante plus. Chaque groupe d'anomalies est une section, sans défileur propre (`defileSeule: false`), à l'intérieur d'un `Expanded(ListView)` posé dans `ColonneCorps`. Les autres appelants de `DataCollection` gardent le comportement par défaut. Ce point est rempli.
2. **Curseur de défilement.** Il est pâle : un mélange à parts égales des jetons borderHairline et borderStrong, avec une piste visible. Ce n'est jamais l'accent. Le test passe en clair et en sombre. La barre est gardée pour la souris, décidé par délégation le 09/10. Ce point est rempli.
3. **Ouverture de la rangée.** À l'ouverture, la rangée s'arrête au début d'une puce et la puce retenue se voit entière. Sur Qualité à 320 x2, LTR et RTL, aucune lettre n'est coupée. Il reste une limite quand la rangée est en butée (réserve moyenne ci-dessous).
4. **Observations à partir de 600 px.** Il n'y a plus qu'une rangée, et la personne qu'on vient de retenir est amenée dans la vue grâce à `PuceFiltre`. C'est testé à 600, 700, 1024 et 1440, en x1 et x2, LTR et RTL. Ce point est rempli.
5. **Observations à 320 x2.** La date et « Fatoumata » sont entiers, en LTR, en RTL et en Interface guidée. Si un mot ne tient pas, la ligne empile ses colonnes, et les traits d'union sont insécables. Ce point est rempli.
6. **Revue UX.** `docs/current/UX_REVIEW_FILTRES-1.md` donne pour chaque point la source, la règle et la conclusion. Il dit que les sources web étaient inaccessibles. Le total de `verifier_revue` qu'il cite est inexact (voir les réserves).
7. **Règle « jamais un Wrap de puces ».** Le contrôle `wrap-filtres` est ajouté, il mord, et le total n'augmente pas. Ce point est rempli.
8. **Captures.** Elles couvrent 320x568 x2 en LTR, en RTL et en Interface guidée, puis 390, 390 sombre, 390 en Interface guidée et 1440, ainsi qu'Observations avec des personnes retenues. J'ai ouvert un échantillon de captures : Qualité, Observations, Comptes et Journal, dont Observations avec personnes retenues à 700 x1, 1024 x2 et 1440 x2 RTL. Ce point est rempli.

### Réserves
- **Moyenne.** Quand la puce retenue est la dernière de la rangée et que celle-ci est au bout, la puce d'avant reste visible avec son libellé coupé. On lit « Fatoumata Diallo » sans « Tuteur : » à 1024 x2 et à 1440 x2 RTL, ce qui ressemble à une puce complète. Deux pistes : un fondu plus large, ou un espace en fin de rangée qui permette de s'arrêter au début de la puce retenue.
- **Mineure.** La revue UX annonce un total `verifier_revue` de 1533 ; le total mesuré est 1532.
- **Mineure.** `wrap-filtres` ne voit pas un `Wrap(children: liste)` dont la liste est construite ailleurs.
- **Mineure.** À 700 x1, les menus sortent entièrement de la vue après le choix d'une personne. Seule la barre de défilement signale qu'ils sont là.

### À relayer (hors lot, antérieur)
- À 1440 texte x2, la vue tableau de `DataCollection` coupe des mots : « 23/09/20 / 26 », « enregistré / e », « 18:12: / 00 », en-tête « …Entr », ainsi que dans Comptes et Progression.
- En Interface guidée, les textes d'aide de recherche sont tronqués et « Programme / s » est coupé.
- En RTL forcé, les heures et les durées s'affichent dans l'ordre inversé.
- La page Groupes s'intitule toujours « Groupes ».
- Les sources web de la revue UX restent à relire.
