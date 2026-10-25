# Démarrage de l'application web (audit du lancement, 25/10/2026)

**Rien n'est prouvé en production.** Ce lot est testé localement, avec un build web local et
Chromium sans écran ; la preuve reste celle du directeur.

## Mesures de l'audit

- Poids au premier chargement : 6,35 Mo.
- Premier écran : 37 s en 4G lente, 130 s en 3G, 4,5 s sur un bon réseau.

## Causes

- Les polices (1,8 Mo dans le build local, dont 845 Ko pour Noto Sans Arabic) partaient **après**
  `main.dart.js` : le moteur ne les demande qu'après avoir lu `assets/FontManifest.json`, une fois
  son code chargé et lancé. Mesure locale : environ 1 s plus tard, et jusqu'à +5 s en 4G lente.
- Le moteur de rendu (canvaskit) vient de `www.gstatic.com` : une connexion de plus à ouvrir.
- Une nouvelle version restait inconnue d'un onglet déjà ouvert, sans le dire.

## Ce que ce lot fait

1. `web/index.html` : préchargement de `main.dart.js` et des neuf polices du `FontManifest.json`
   construit (`as="fetch"`, `crossorigin`), connexion anticipée à `www.gstatic.com`. Contrôle
   Chromium : les polices partent avec `main.dart.js` ; aucun avertissement « preloaded but not
   used », aucun téléchargement en double. Contrôle négatif : sans `crossorigin`, deux
   avertissements et un doublon.
2. « Une nouvelle version de l'application est prête. » avec « Recharger » : `version.json` lu au
   démarrage, puis toutes les 15 minutes et à chaque retour au premier plan ; aucune requête hors
   ligne. Le bandeau reprend le registre du bandeau hors ligne. Essai Chromium : bandeau affiché
   après 15 minutes simulées. Le retour au premier plan n'est prouvé que par un test d'écran.

## Ce qui reste au directeur

- Polices arabes hors du paquet (chargées à la demande), à décider.
- Version de Flutter fixée dans le workflow (le canvaskit de `www.gstatic.com` suit la version).
- `--build-number` dans le workflow, différent à chaque déploiement : sans lui, le bandeau ne
  s'affiche jamais (le build local donne `"build_number":"1"`).
- Règle d'hébergement pour un ancien service worker resté chez des visiteurs.
- Numéro de version (`version` de `pubspec.yaml`, aujourd'hui `0.2.0`).
- Liste des préchargements à tenir à jour si une police est ajoutée ou retirée.
