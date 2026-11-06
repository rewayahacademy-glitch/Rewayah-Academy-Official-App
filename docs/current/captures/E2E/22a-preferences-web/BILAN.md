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

## Police arabe à la demande (préparé en local, 06/11 vers 23:30 UTC, branche `claude/police-arabe-local`)

Code : `lib/core/theme/polices_differees.dart` (déjà là depuis le 29/10, réutilisé) charge maintenant les
polices du Coran après la première image, et la police arabe d'interface **seulement quand l'arabe est
appliqué** (`chargerPoliceArabe`, appelée par `appliquerPreferenceLangue`, une seule fois). Il retire aussi
la ligne `<link rel="preload" … NotoSansArabic-Variable.ttf>` de `web/index.html` : cette ligne la
téléchargeait pour tout le monde, même avec la police déclarée à la demande.

Il reste un geste du directeur dans `pubspec.yaml`, interdit aux agents : déplacer `NotoSansArabic` de
`fonts:` vers `assets:`. Mesure faite en simulant ce geste dans le build (famille retirée de
`FontManifest.json`) :

| Ouverture | Avant (2fcae15d) | Après |
|---|---|---|
| Français, écran de connexion | NotoSansArabic 844 676 o | **aucune police arabe** |
| Français, page Apparence (affiche « العربية ») | NotoSansArabic 844 676 o | sous-ensemble Noto Sans Arabic de Google Fonts, 66 412 o (repli automatique du moteur pour les sept lettres du mot) |
| Arabe | NotoSansArabic 844 676 o | NotoSansArabic 844 676 o, chargée à la demande |

Les deux polices du Coran restent déclarées et se chargent dans tous les cas (décision du pilote).
Capture : `05-police-a-la-demande-ar-390.png`.

## Filet des liens (garde-cap, 06/11/2026, ordre du directeur)

`web/index.html`, avant le démarrage de Flutter : une adresse `/chemin?requête` sans fragment est réécrite
en `/?requête#/chemin?requête` (`history.replaceState`). Le routeur trouve la page dans le fragment. La
requête reste aussi à sa place, parce que l'invitation (`retenirInvitationDepuisAdresse`), les liens de
connexion et Supabase la lisent dans `Uri.base`. Ne sont pas touchés : la racine, une adresse qui a déjà un
fragment, un fichier (dernier segment avec un point).

Preuve : `node tool/e2e/filet_liens.mjs build/web` (serveur local qui sert `index.html` pour tout chemin,
comme `vercel.json`).

- Avant (build 2fcae15d) : `/connexion?mode=creer&invitation=1` restait sur `/connexion` et le routeur
  envoyait vers `#/commencer?etape=pourQui` (le questionnaire), **pas** sur « Créer votre compte ».
- Après : adresse `/?mode=creer&invitation=1#/connexion?mode=creer&invitation=1`, écran « Créer votre
  compte », à 390 et à 1440 (`06-filet-liens-connexion-*`). La racine et `/flutter.js` ne sont pas réécrits.
