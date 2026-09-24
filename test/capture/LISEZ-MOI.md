# Captures d'écran de recette

Outil de capture fidèle pour comparer un écran aux maquettes du directeur
(recette C11 du chantier Tuteur V1, intégrée en phase 0c1).

- `outil_capture.dart` : les fonctions (polices réelles, vue fixée, capture PNG,
  planche maquette | capture).
- `exemple_capture_test.dart` : un exemple complet, à copier pour un écran.
- `coquille_capture_test.dart` : la coquille du tuteur sur le vrai routeur
  (390x844 et 1440x900, clair et sombre, rail replié en 1024x768), et deux
  planches si `CAPTURE_MAQUETTE_BUREAU` (Accueil bureau clair) et
  `CAPTURE_MAQUETTE_MOBILE` (Mon compte mobile clair) désignent les maquettes.

## Sauté par défaut

Sans la variable d'environnement `CAPTURE_DIR`, chaque groupe de capture est
**sauté** (`skip: sautSansCapture`) : `flutter test` et la CI le comptent comme
« skipped », rien ne s'exécute et rien n'est écrit sur le disque.

## Lancer une capture

PowerShell, depuis la racine du dépôt, sous le verrou de la machine :

```powershell
$env:CAPTURE_DIR = "D:\RA _APP\pilotage-tuteur-v1\05_recette\captures"
& "D:\RA _APP\pilotage-tuteur-v1\outils\flutter-verrou.ps1" -Dossier (Get-Location).Path -Commande "flutter test --no-pub test/capture/exemple_capture_test.dart --reporter expanded"
Remove-Item Env:\CAPTURE_DIR
```

Variables lues :

| Variable | Rôle | Défaut |
|---|---|---|
| `CAPTURE_DIR` | Dossier de sortie des PNG. **Absente = captures sautées.** | aucun |
| `CAPTURE_MAQUETTE` | Chemin d'une maquette PNG : écrit la planche `maquette \| capture` côte à côte. Absente = ce test est sauté. | aucun |
| `CAPTURE_LARGEUR_LOGIQUE` | Largeur logique de la maquette : 390 pour un téléphone, 1440 pour un bureau. | 390 |

Sorties : `<nom>.png` (capture, ou planche maquette | capture) et, pour une
comparaison, `<nom>_capture.png` (la capture seule).

## Ce que l'outil garantit

1. **Polices réelles** : toutes les familles de `FontManifest.json` sont
   chargées (Plus Jakarta Sans, DM Sans, polices arabes, Phosphor). Le test
   « garde-fou » mesure la largeur de « iiiiiiiiii » et échoue si le texte
   tombe sur la police de test (carrés).
2. **Vue fixée** : taille logique et densité (`fixerVueCapture`), ou calage sur
   les pixels d'une maquette (`fixerVueMaquette`) ; zone sûre simulable
   (barre d'état 47, indicateur 34).
3. **Vrai thème** clair et sombre (`AppTheme.pour`), locale et délégués de
   l'application ; le cadre est posé au-dessus de `MaterialApp` (fond, feuilles
   et superpositions compris).

## Pièges connus (C11 §5.4)

- Toute opération d'image se fait dans `tester.runAsync` (sinon le test pend).
- `pumpAndSettle` échoue sur un squelette ou une pulsation : utiliser
  `stabiliser`.
- Une capture n'est que la fenêtre : pour une page longue, plusieurs captures
  ou une vue plus haute (à dire dans la preuve).
- Les images réseau ne se chargent pas sous `flutter test` : l'avatar retombe
  sur les initiales. Jamais de photo réelle dans une capture de recette.
- Données : fixtures de test isolées uniquement, jamais un repli de production.

Une capture prouve le rendu d'un état simulé ; elle ne prouve ni un service
branché, ni un parcours. La fidélité se juge sur la planche.
