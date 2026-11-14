# CAMERA-JUMELAGE : preuve dans un vrai navigateur (12/11/2026)

Ce qui n'est PAS prouvé : le téléphone Android réel du directeur n'a pas été essayé. Que le flux
resté ouvert soit LA cause du « NotReadableError » de la séance du 12/11 reste une hypothèse forte ;
que `mobile_scanner` 7.4.2 ne ferme pas le flux sur le web est prouvé ci-dessous.

Aucun changement visible : la page du scanner est identique, d'où aucune capture.

## Comment la mesure est faite

`tool/e2e/camera_jumelage_flux.mjs` (Chromium de Playwright, caméra simulée
`--use-fake-device-for-media-stream`, aucun serveur Supabase) :

1. `getUserMedia` est enveloppé avant le chargement pour garder chaque flux rendu (`window.__flux`).
   Au premier appel, un flux **témoin** (comme la visio de la salle réduite) est attaché à un
   `<video>` ordinaire pendant le démarrage du lecteur : il ne doit jamais être fermé.
2. Ouverture de `/connexion/eleve/scanner`, attente d'une piste `live`.
3. Onglet caché puis revenu (`visibilitychange`) : pause puis reprise de l'écran.
4. Sortie comme une personne : bouton « Saisir le code » ; on lit `readyState` de chaque piste.

Construction (deux fois, mêmes options, `-O1 --no-wasm-dry-run` à cause de la mémoire du conteneur) :
`--dart-define=SUPABASE_URL=https://127.0.0.1:9`, clé publiable plausible, `ENVIRONNEMENT=developpement`.
Pour la construction d'avant, la clé compilée (« factice ») ouvrait l'écran « Configuration absente » ;
la chaîne a été remplacée dans `main.dart.js` par la même clé plausible que celle d'après, sans
autre modification.

## Avant la correction (main 25f3ed78) : défaut reproduit

```
{"mesure":"camera ouverte","url":"http://127.0.0.1:8097/#/connexion/eleve/scanner","pistes":[["live"]],"temoin":["live"]}
{"mesure":"onglet cache","pistes":[["live"]]}
{"mesure":"onglet revenu","pistes":[["live"],["live"]]}
{"mesure":"apres sortie","url":"http://127.0.0.1:8097/#/connexion/eleve/code","pistes":[["live"],["live"]],"temoin":["live"]}
code=1
```

La caméra reste ouverte après la sortie ; une pause puis une reprise en ouvre même une deuxième.

## Après la correction

```
{"mesure":"camera ouverte","url":"http://127.0.0.1:8097/#/connexion/eleve/scanner","pistes":[["live"]],"temoin":["live"]}
{"mesure":"onglet cache","pistes":[["ended"]]}
{"mesure":"onglet revenu","pistes":[["ended"],["live"]]}
{"mesure":"apres sortie","url":"http://127.0.0.1:8097/#/connexion/eleve/code","pistes":[["ended"],["ended"]],"temoin":["live"]}
code=0
```

Chaque flux du lecteur est fermé (pause et sortie), la reprise rouvre un flux neuf, et le flux
témoin hors lecteur reste `live`.

## Rejouer

```
flutter build web --release -O1 --no-wasm-dry-run \
  --dart-define=SUPABASE_URL=https://127.0.0.1:9 \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_essaiLocalSansServeur000000
node tool/e2e/camera_jumelage_flux.mjs build/web
```
