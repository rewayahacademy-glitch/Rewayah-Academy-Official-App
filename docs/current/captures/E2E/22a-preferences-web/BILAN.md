# Lot 22 a PREFERENCES-WEB, preuve locale (agent 4, 06/11/2026)

Statut : **testé localement** (build web de publication, sans serveur, page `/demo/adulte?ecran=apparence`,
Chromium par Playwright). Pas testé sur staging, pas en production : la preuve du directeur reste à faire.

## Ce qui existe déjà, réutilisé

- `PreferencesLocales`, `persistanceApparenceProvider`, `StockagePreferences` : le thème était déjà persisté
  hors web ; seul le web prenait une mémoire perdue au rechargement.
- `features/inscription/questionnaire/memoire_appareil.dart` : accès au `localStorage` déjà écrit en
  `dart:js_interop` ; il sert maintenant de stockage des préférences sur le web. Aucune dépendance nouvelle,
  `pubspec.yaml` intact.
- `SelecteurTheme` et `ControleSegmente` : le choix de la langue est fait avec le même composant.
- `appliquerLangueDeLAppareil` (langue_demarrage) : c'est le choix « Système ».
- Réglages du compte : les deux lignes inactives « Français, actif » et « Arabe, non disponible » sont
  remplacées par le vrai choix.

## Captures (390 et 1440)

1. `01-fr-avant-choix-*` : ouverture en français, « Système » choisi.
2. `02-ar-apres-choix-*` : on touche « العربية » ; l'application passe en arabe, de droite à gauche.
3. `03-ar-apres-rechargement-*` : après rechargement, l'arabe est gardé.
4. `04-ar-sombre-apres-rechargement-*` : on choisit le thème sombre, puis on recharge ; le thème sombre est gardé.

Journal du robot : `localStorage` = `arabe` après le choix, `sombre` après le choix du thème ; ouverture en
français : **aucun morceau différé chargé** ; ouverture en arabe : `main.dart.js_1.part.js` seul.

## Performance (règle du 05/11)

| Build | `main.dart.js` | morceau arabe `main.dart.js_1.part.js` |
|---|---|---|
| avant (main 7b3a3f05) | 14 926 896 o | 3 032 856 o |
| après | 14 932 396 o (+5 500) | 3 034 980 o (+2 124) |

La langue mémorisée est appliquée dans `main` avant `runApp` : pas de passage par une autre langue.
Police arabe chargée seulement en arabe : non vérifié dans ce lot.
