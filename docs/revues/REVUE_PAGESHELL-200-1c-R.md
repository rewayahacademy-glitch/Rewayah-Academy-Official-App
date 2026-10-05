<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse de PAGESHELL-200-1c (branche corrections/c2-pageshell-c, 397ef11d)

**Verdict : ACCEPTÉE AVEC RÉSERVES (mineures).** Les trois réserves de 1b sont traitées et prouvées. Le débordement préexistant de 667x375 a disparu. Aucune régression n'est détectée. Le travail a été fait dans un worktree jetable détaché, retiré à la fin. Rien n'a été poussé.

## Ce qui a été vérifié

### Contrôles statiques
- `dart analyze --fatal-infos` : aucun problème.
- `verifier_revue` : 1568 violations, le même total que la base selon le rédacteur (la base n'a pas été remesurée dans cette revue).
- `verifier_jetons` : aucune violation dans les deux fichiers touchés.
- Commentaire de `_corpsLarge` : il fait 124 colonnes sur la base et repasse sous 80 colonnes. Les autres lignes de plus de 80 colonnes de ces deux fichiers existaient déjà sur la base.

### Tests, tous avec `--concurrency=2`
- `test/teaching_core`, `test/accessibilite`, `test/core`, `test/router` : +2680 ~142, 0 échec.
- `test/features` et `test/widgets` : +3122 ~2126, 0 échec.
- Ces dossiers couvrent les 108 écrans sous `PageShell`. `ColonneCorps` et `DefileurCorps` n'ont qu'un appelant : le panneau d'observation.

### Mutations
Fichiers rejoués : `salle_observation_test` et `page_shell_hauteur_corps_test`. La branche intacte donne +112.

| Mutation | Résultat |
| :--- | :--- |
| M1 : `_forcerDefilement` neutralisé | échec (4 tests) |
| M2 : `valeur(souples: false)` | échec (16) |
| M3 : `valeur(souples: true)`, pour le cas « salle qui tient » | échec (4) |
| M4 : panneau remis à la base | échec (14) |
| M5 : `minimumEtire` remis à 48 | échec (cas 932x430 RTL) |
| M6 : sans `repere` | **vert**, voir la réserve 2 |

### Captures ouvertes

**Celles du rédacteur.**
- 320x568 à 200 %, positions support et bout, LTR et RTL : la pastille « En direct » et le support sont entiers, la barre est atteignable.
- 800x360 sombre, bout : le support est visible.
- 667x375 à 200 % en Interface guidée : la page défile, la barre est entière, il n'y a plus de bande de débordement.
- 667x375 à 100 % : la tête reste fixe, la barre est au premier affichage, comme demandé en non-régression.
- 800x360 RTL, haut : l'en-tête en Wrap est correctement aligné.

**Les miennes : 80 captures adverses.** Elles couvrent 390x844 et 320x568 à 200 %, 1440x900 à 100 et 200 %, et 667x375 à 200 % sans zone sûre. Chaque taille est prise en clair et en sombre, standard et Interface guidée, LTR et RTL, en haut et en bout. Aucune ne lève d'exception ni ne déborde. 1440x900 est inchangé, la barre y est visible au premier affichage. 390x844 à 200 % en standard montre le support entier et la barre.

**Remarque sans conséquence.** En RTL, le point final apparaît en tête (« .s'affiche ici »). C'est un effet bidi du harnais, qui force le RTL avec des libellés français. Ce n'est pas un défaut de l'application.

## Réserves (mineures)
1. **390x844 à 200 % en Interface guidée.** La salle « tient », donc le minimum utile n'est pas imposé, et le support n'est visible qu'en partie (environ 110 px). Le rendu est identique à la base : ce n'est pas une régression, mais le support n'est pas « réellement visible » dans ce cas.
2. **Le repère n'est verrouillé par aucun test** : la mutation M6 passe au vert.
3. **Le basculement en défilement global est mémorisé par vue**, pas par contenu. C'est théorique et sans effet visible.

## Champ serveur
Aucun besoin serveur.