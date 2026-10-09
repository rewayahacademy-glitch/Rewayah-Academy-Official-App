<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
## FILTRES-1 : relecture adverse de corrections/c2-filtres (af2f88ad)

**Verdict : ACCEPTÉE AVEC RÉSERVES.** La demande est remplie. Je n'ai trouvé aucun défaut majeur causé par le lot. Les réserves ci-dessous sont mineures, sauf une moyenne. Un défaut majeur antérieur au lot est à relayer.

Statut : présent dans le code et testé localement. Ni staging, ni déploiement. Je n'ai rien poussé. Le worktree `rv-FILTRES-1-29` et le worktree de base que j'avais ouvert sont retirés.

### Ce qui a été vérifié

**Périmètre**
- Le diff 6e2c91c4..af2f88ad ne touche à aucun fichier interdit : rien dans `supabase/`, `.github/`, `vercel.json`, `pubspec.yaml`, le thème, `page_shell`, le champ de saisie partagé, le rendu du Coran, `communications`, finance, comptable, revenus, salle ou `tc_classe_live`.
- `suivi_foyer`, modifié par le lot, est l'historique de la famille, pas un écran de finance. Le dossier finance `lib/features/foyer` n'est pas touché.
- Les 4 commits sont en français et se terminent exactement par les deux lignes demandées.

**Audit des écrans**
- J'ai cherché FilterPill, FilterChip, ChoiceChip, MenuFiltre et « filtre » dans `lib/features`. Les 11 écrans qui ont une vraie rangée de filtres passent tous à `RangeeFiltres`.
- `acces_agents` (choix de formulaire) et la feuille de planification des évaluations restent en `Wrap`. Cette décision est consignée et justifiée.
- Les autres occurrences de « filtre » ne correspondent à aucune rangée de puces.
- Il n'y a ni `docs/design/08-catalogue-ecrans.md` actif (seulement archivé) ni catalogue d'écrans dans `docs/current`. La fiche est donc en annexe A bis de `DASH_STRATEGIE.md`, avec fichier:ligne, état avant/après, composant retenu et liste des exclus.
- Le composant est nouveau et aucun équivalent n'existait. Les puces sont choisies dans des listes ou des menus remplis à partir des données. Aucun nouveau champ de saisie, aucun libellé nouveau.

**Outils**
- `dart analyze --fatal-infos` : 0 problème.
- `verifier_jetons` : 39, identique à la base mesurée.
- `verifier_revue` : 1550, identique à la base.

**Tests (toujours avec --concurrency=2)**

| Dossier | Résultat |
| :--- | :--- |
| `test/features` | 2888 succès, 0 échec |
| `test/widgets` | 298 succès |
| `test/core` | 687 succès |
| `test/accessibilite` | 362 succès |
| `test/teaching_core` | 1376 succès |
| `test/suivi` | 16 succès |
| `test/i18n` | 7 succès |

Les tests du lot (6 + 22) passent.

**Mutations (j'ai annulé la correction, les tests doivent échouer)**
1. Qualité et Historique du foyer remis en `Wrap` : 4 échecs.
2. `crossAxisAlignment.stretch` remplacé par `start` (les puces n'ont plus la même hauteur) : 11 échecs, dont 10 cas d'écran et le cas du composant.
3. Largeur des puces non bornée à la rangée : 3 échecs (mot long, Classes en LTR et en RTL).

Les tests mordent sur les trois garanties.

**Régressions au-delà de 320 px**
J'ai écrit un test ad hoc (non versionné) de 616 cas : les 11 écrans × largeurs 320, 390, 600, 700, 1024 et 1440 × texte x1 et x2 × LTR/RTL × clair/sombre, plus l'Interface guidée à 320 et 390. Résultat :
- 0 exception ;
- toujours une seule hauteur de puce et une seule ligne de puces ;
- à 1024 et 1440 en texte x1, tout tient sans défilement ;
- à 1440 en texte x2, Journal et Progression défilent.

**Captures**
- J'ai ouvert les 44 captures du dépôt, regroupées en planches avant/après, en LTR et en RTL.
- J'ai produit 176 captures supplémentaires (390 et 1440, clair et sombre, Interface guidée) et ouvert les planches correspondantes.
- Avant : 2 à 6 lignes de puces. Après : une seule rangée qui défile, avec fondu et barre de défilement. Aucun mot coupé dans les puces.

### Réserves (le détail est dans `defauts`)

1. **Moyen.** Le curseur de la barre de défilement est violet et posé juste sous les puces. Il ressemble à un soulignement d'onglet actif et rend la sélection ambiguë. À styliser avec des jetons, ou à rendre plus discret.
2. **Mineur.** Il manque le fichier `UX_REVIEW_FILTRES-1.md` que demande DESIGN-GOV §4.2 (source consultée, règle, conclusion).
3. **Mineur.** Les captures livrées ne couvrent que 320 px texte x2 en thème clair.
4. **Mineur.** Observations (admin) à partir de 600 px : quand un tuteur ou un élève est retenu, ses puces forment une seconde rangée sous les menus.
5. **Mineur.** Comme la rangée se centre sur le filtre retenu, la première puce est en partie cachée à l'ouverture (Qualité, Journal).
6. **Mineur.** La règle « jamais un Wrap de puces » est écrite dans `lib/CLAUDE.md` mais rien ne la contrôle automatiquement.
7. **Mineur.** Le diff contient du reformatage sans rapport avec FILTRES-1 dans `groupes_page.dart`, `evaluations_page.dart` et `programmes_page.dart`.

### À relayer (hors lot, antérieur)

- **Qualité, défaut majeur.** Dès qu'une anomalie est ouverte, la liste plante, à 320 x2 comme à 1440 x2. Je l'ai reproduit à l'identique sur la base 6e2c91c4.
- **Observations (admin).** Dans les lignes de la liste à 320 x2, la date et le nom « Fatoumata » se coupent au milieu des mots.
- **Groupes.** La page s'intitule encore « Groupes » (lot 3 : « groupe » devient « classe »).
- **Exclus de cette étape**, conformément à la consigne : `lib/features/communications/**`, Finance/Comptable (finance, foyer, comptable, revenus), salle et `tc_classe_live`. Leurs voies devront utiliser `RangeeFiltres` si elles ajoutent des filtres.
