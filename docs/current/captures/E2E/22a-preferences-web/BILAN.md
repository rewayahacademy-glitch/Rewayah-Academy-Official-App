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

## Police arabe : **FAUX**, elle se charge aussi en français (relevé du 06/11, 23:00 UTC)

Mesure prise sur le réseau dans Playwright, au même build, ouverture en français (« Système », appareil `fr-FR`)
puis en arabe : **les mêmes 10 polices dans les deux cas**, parmi lesquelles `NotoSansArabic-Variable.ttf`
(844 676 o), `UthmanicHafs-v-3.0.ttf` (301 396 o) et `UthmanTahaNaskh-Regular.otf` (164 684 o), soit environ
1,3 Mo de polices arabes téléchargées par une personne qui ouvre l'application en français.

La cause : le moteur web de Flutter charge au démarrage toutes les familles déclarées dans
`pubspec.yaml` (section `fonts:`, ensuite dans `FontManifest.json`). Ce lot ne l'a ni créé ni corrigé.
Pour corriger, il faudrait retirer `NotoSansArabic` de la section `fonts:` et la charger à la demande
(`FontLoader`) quand l'arabe est choisi. Cela touche `pubspec.yaml`, un geste du directeur, et il faut le
décider. Les deux polices du Coran restent nécessaires en français, sur les pages du Coran.
