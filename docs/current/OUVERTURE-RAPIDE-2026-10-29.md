# Ouverture rapide de l'application, rapport du 29/10/2026

Branche `claude/admiring-brown-r6ai72-ouverture`, créée depuis `origin/main`. Aucune pull request (le garde-fou l'interdit).

## Ce qui est faux, bloqué ou non prouvé (à lire d'abord)

1. **L'écran de connexion reste lent sur un réseau lent : 31 s au lieu de 35,6 s.** Le logo, lui, apparaît tout de suite (0,35 s au lieu de 35,6 s). Le reste du temps, c'est le téléchargement : 4,95 Mo à 1,6 Mbit/s. Pour descendre encore, il faut les deux changements du directeur ci-dessous (polices dans `pubspec.yaml`) et un second lot qui charge à la demande les autres écrans.
2. **Rien n'est prouvé en production.** Toutes les mesures « après » viennent d'un build local servi avec les mêmes en-têtes que Vercel. La preuve, c'est le directeur qui ouvre https://app.rewayahacademy.com sur son téléphone après la fusion.
3. **Le cas « connecté » n'a pas été mesuré.** Je n'ai aucun compte de staging. Je n'ai donc pas vu, dans un navigateur, une page de la direction, de la comptabilité, la salle ou le Coran se charger à la demande. Les tests le couvrent (17 431 verts), pas un navigateur.
4. **Le point 3 de la demande n'est pas fait tel quel, et c'est voulu.** Le moteur Flutter attend **toutes** les polices de `assets/FontManifest.json` avant sa première image (`engine/initialization.dart`, ligne 154 : `_downloadAssetFonts`). Retirer les préchargements des polices arabes et du Coran aurait **ralenti** l'ouverture, puisqu'elles seraient parties après `main.dart.js` au lieu d'en même temps. Elles ne sortiront du chemin critique que par le changement de `pubspec.yaml` décrit plus bas. En attendant, elles passent en priorité basse.
5. **`tool/verifier_revue.dart` échoue : 1 074 écarts.** C'est le même nombre sur `origin/main` (vérifié dans une copie propre de `main`) : ce lot n'en ajoute aucun et n'en retire aucun.
6. Le moteur charge encore une police de repli Roboto (64 Ko) depuis `fonts.gstatic.com`. Je ne l'ai pas touché.

## Mesures

Protocole : Playwright, Chromium, écran de 390 x 844, processeur ralenti 4 fois, « 4G lent » (aller-retour de 150 ms, 1,6 Mbit/s en réception), cache vide, aucune session. Médiane de 3 ouvertures. Temps comptés depuis la navigation.

| | Production (`main`, 28/10) | Local, avant (`main`) | Local, après (ce lot) |
| :-- | --: | --: | --: |
| Premier pixel (fond seul) | 0,28 s | 0,22 s | 0,28 s |
| **Logo visible** | 39,5 s | 35,6 s | **0,35 s** |
| Première image de Flutter | 39,5 s | 35,6 s | 31,0 s |
| **Écran de connexion** | 39,5 s | 35,6 s | **31,0 s** |
| Octets reçus | 6,38 Mo | 5,73 Mo | 4,95 Mo |
| `main.dart.js` (non compressé) | 15,1 Mo | 15,1 Mo | 8,7 Mo |

Sans bridage du réseau (processeur ralenti 4 fois seulement) : écran de connexion à 7,6 s avant, 6,1 s après.

Avant ce lot, sans HTML d'ouverture, on ne voyait rien d'autre que le fond pendant toute l'attente : c'est le « l'application ne s'ouvre jamais » du directeur.

Ce qui reste téléchargé avant l'écran de connexion (après, compression brotli) : `main.dart.js` 2,13 Mo, moteur de rendu `canvaskit.wasm` 1,85 Mo, polices arabes et du Coran 0,64 Mo, autres polices 0,30 Mo.

## Ce qui a changé

1. **Ouverture dès le premier octet** (`web/index.html`). Le logo vertical blanc, tiré tel quel de `assets/brand/logo/blanc/logo-vertical.svg`, sur le violet de marque (#6538E4, `surfaceMarque`), avec un léger mouvement de respiration et une barre de chargement (tout s'arrête si l'appareil demande moins d'animations). L'ouverture disparaît à la première image de Flutter. Après 20 s : « La connexion prend plus de temps que prévu », « Vous pouvez patienter encore un peu ou recharger la page. » et le bouton « Recharger » (en arabe si la première langue du navigateur l'est). En 4G lent, ce message arrive avant la fin (31 s) ; « Recharger » relance avec ce qui est déjà en cache.
2. **Plus de carré au lancement de l'application installée** : `background_color` de `web/manifest.json` passe au violet de marque. Le carré venait de l'icône violette posée sur le fond clair.
3. **Plus de service worker** (`web/flutter_bootstrap.js`). Celui de Flutter est obsolète et le fichier servi se désinscrivait puis **rechargeait la page** à la première visite. Le fichier reste construit : un ancien service worker encore installé le reçoit et se retire.
4. **Le moteur de rendu est servi par l'application**, plus par `www.gstatic.com` (une connexion de moins, plus d'ouverture bloquée si ce domaine l'est), et préchargé dès la page.
5. **Polices arabes et du Coran en priorité basse** (voir le point 4 en tête).
6. **Écrans chargés à la demande** (`import ... deferred as`, composant `lib/core/router/page_differee.dart`) : la salle, le Coran, tous les écrans de la direction (dont la bibliothèque et le tableau de bord), la comptabilité, les candidatures, la recherche et les communications. 62 morceaux. Pendant le chargement, la navigation reste à sa place ; après 8 s, la phrase du chargement prolongé ; en cas d'échec, « Réessayer ».
7. **`/demo` n'est plus compilé en production** : constante `Env.demoCompilee` (fausse quand `ENVIRONNEMENT=production`) pour les routes `/demo/*`, les entrées `?demo=` et le lanceur.
8. **10 s au plus pour le démarrage** (`AppDelais.demarrageMax`) : `Supabase.initialize` (au retour d'un lien de connexion, il attendait l'échange du code avec le serveur, sans limite), la lecture du profil (20 s avant) et la relance de session. Passé ce délai, la page « hors ligne » ou la relance propose « Réessayer ».
9. **Plus de porte animée entre la connexion et l'accueil** : l'écran de démarrage (`EcranDemarrage`) montre la même image que l'ouverture HTML, logo vertical immobile, et passe la main. La page de connexion garde sa porte.
10. **Chargement des polices arabes et du Coran après la première image**, prêt mais inactif (`lib/core/theme/polices_differees.dart`) : il ne charge que les familles absentes du manifeste, donc rien tant que `pubspec.yaml` n'a pas changé.
11. Le mot « Recharger » est ajouté à la compétence `mots-rewayah`.

## Vérifications faites

| Commande | Résultat |
| :-- | :-- |
| `dart run slang` | OK |
| `dart run build_runner build --delete-conflicting-outputs` | OK, aucun fichier modifié |
| `dart analyze --fatal-infos` | aucun problème |
| `flutter test` | 17 431 réussis, 0 échec |
| `dart run tool/verifier_jetons.dart` | OK |
| `dart run tool/verifier_revue.dart` | échec, 1 074 écarts, identique à `origin/main` |
| `flutter build web --release` (mêmes options que la CI) | OK |

## Ce que le directeur doit changer lui-même (zones interdites aux agents)

### 1. `pubspec.yaml` : sortir les trois polices arabes et du Coran du manifeste (gain attendu : 0,64 Mo, environ 3 s en 4G lent)

Dans `flutter:`, retirer ces trois familles de la section `fonts:` :

```yaml
    - family: UthmanTahaNaskh
      fonts:
        - asset: assets/fonts/UthmanTahaNaskh-Regular.otf
    - family: UthmanicHafs
      fonts:
        - asset: assets/fonts/UthmanicHafs-v-3.0.ttf
    - family: NotoSansArabic
      fonts:
        - asset: assets/fonts/NotoSansArabic-Variable.ttf
```

et les ajouter à la section `assets:` :

```yaml
  assets:
    - assets/audio/fr/
    - assets/flags/
    # Polices chargees apres la premiere image (lib/core/theme/polices_differees.dart).
    - assets/fonts/UthmanTahaNaskh-Regular.otf
    - assets/fonts/UthmanicHafs-v-3.0.ttf
    - assets/fonts/NotoSansArabic-Variable.ttf
```

À pousser sur cette branche. Claude fait ensuite, dans le même lot : retirer de `web/index.html` les trois préchargements en priorité basse, et adapter les tests qui lisent la section `fonts` (`test/theme/typographie_test.dart`, chargement des polices de `test/capture/outil_capture.dart`). Effet visible : une interface en arabe ou une page du Coran ouverte dans la première seconde peut s'afficher un instant dans la police de repli, puis se redessiner.

### 2. `web/vercel.json` (c'est lui qui part chez Vercel, pas celui de la racine) : garder le moteur en cache

Les fichiers de Flutter n'ont pas de nom versionné : `main.dart.js`, `assets/FontManifest.json` ou `canvaskit/canvaskit.wasm` gardent le même nom d'une version à l'autre. Un cache « immuable » d'un an servirait donc une ancienne version après une mise en production : **ne pas le mettre**. Aujourd'hui, tout est en `max-age=0, must-revalidate` : le navigateur redemande, Vercel répond « inchangé » (304) sans renvoyer le fichier. C'est correct.

Seul ajout proposé, dans `headers`, pour éviter ces allers-retours sur le moteur et les polices, qui ne changent qu'avec une mise à jour de Flutter ou une nouvelle police :

```json
    {
      "source": "/canvaskit/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=86400, stale-while-revalidate=604800" }
      ]
    },
    {
      "source": "/assets/assets/fonts/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=86400, stale-while-revalidate=604800" }
      ]
    }
```

Risque accepté si on l'ajoute : le jour d'une montée de version de Flutter, un téléphone peut garder l'ancien moteur un jour au plus. Le gain est faible (des allers-retours, pas des octets) : ce changement est facultatif.

## Ce qu'il resterait pour aller plus loin (non fait, hors de la demande)

- Charger à la demande **tous** les écrans sauf la connexion et le démarrage (Accueil, Journée, Foyer, Compte...) : `main.dart.js` pourrait encore fondre de plusieurs mégaoctets. Le plus gros morceau restant est `lib/core/i18n/strings_fr.g.dart` (1 Mo).
- Servir la police de repli Roboto depuis l'application.

## Ce que le directeur fait pour prouver le lot, après fusion

1. Sur le téléphone, en 4G, ouvrir https://app.rewayahacademy.com dans une fenêtre privée.
2. Le logo Rewayah apparaît tout de suite sur le violet, sans carré : vrai. Écran blanc ou vide plus d'une seconde : faux, capture.
3. L'écran de connexion arrive, sans recharger la page en cours de route.
4. Se connecter par le lien reçu : après le lien, le logo immobile puis l'accueil, sans porte animée entre les deux.
5. En direction, ouvrir Dossiers puis Classes : chaque écran s'ouvre (une courte attente la première fois). Un écran qui reste vide ou dit « Réessayer » : faux, capture.
