# Parcours de bout en bout (ligne d'arrivée), en LOCAL

Tout tourne sur une pile locale : rien n'écrit en production.

```
tool/e2e/pile.sh            # Supabase local (CLI 2.122), Mailpit, fonctions Edge, LiveKit --dev, build web, serveur 8090
tool/e2e/amorcer.sh         # direction + enseignant validé, en SQL local (seuls comptes hors interface)
tool/e2e/enchainer.sh       # 2, 3, 4, 5, 1, 8 (étapes 1-2) dans l'ordre des données ; puis 6 et « parcours_8.mjs --apres » après la clôture des séances
node tool/e2e/etat.mjs <n>    # reporte le verdict dans docs/current/ETAT-OUVERTURE.md
```

- Captures, journal et verdict : `docs/current/captures/E2E/parcours-<n>/`.
- Réparations de pile (le dépôt `supabase/` n'est pas modifié, une copie est adaptée dans `/tmp/e2e-pile`) :
  numéros de migration en double renumérotés pour le CLI ; SMTP Gmail coupé (Mailpit) et confirmation
  d'e-mail activée ; relais HTTPS (`relais_https.mjs`) car l'application refuse une URL `http` ; clé
  publiable locale (la clé anon locale porte `iss=supabase-demo`, refusée) ; certificat du proxy injecté
  dans le conteneur des fonctions Edge (téléchargement de `jsr.io`).
- Le parcours 2 règle le fuseau de l'enseignant de test pour que la séance commence dans l'heure, quelle
  que soit l'heure UTC ; le parcours 5 attend l'ouverture de la salle (20 minutes avant).
- Prérequis : Docker, Node 22, Flutter stable dans `/opt/flutter`, Playwright dans `/opt/node-tools`.

## Ce qu'il faut savoir pour rejouer (relevés du 31/10/2026)

- **Registre d'images** : `public.ecr.aws` peut répondre « Data limit exceeded ». Le CLI 2.122 se
  rabat alors tout seul sur `ghcr.io/supabase/*` (vu le 31/10) ; sinon, retaguer les images
  `supabase/*` de Docker Hub en `public.ecr.aws/supabase/*`.
- **Flutter** peut manquer dans le conteneur : installer la version stable dans `/opt/flutter`
  (`releases_linux.json` de `storage.googleapis.com`), puis `git config --global --add safe.directory /opt/flutter`.
- **Branchement (règle R1, 01/11)** : `pile.sh construire` lance `dart run tool/verifier_branchement.dart`
  avant le build web et s'arrête s'il échoue (code non branché hors de `tool/branchement_tolere.txt`).
- **Après un redémarrage de la machine** : relancer `pile.sh demarrer` puis `pile.sh servir` ; les volumes
  Docker gardent la base (vu le 01/11 à 03:10).
- **Fonctions Edge** : le conteneur doit faire confiance au certificat du proxy (téléchargement de
  `jsr.io`) et à l'autorité locale du relais SMTPS ; `pile.sh` l'ajoute juste après le démarrage.
  Lancer `functions serve` détaché (`setsid nohup`), sinon il meurt avec la commande qui l'a lancé.
- **E-mails de l'application** : la file `courriels_sortants` part par `courriels-envoi` (tâche
  pg_cron) vers Mailpit, par le relais `relais_smtps.mjs` (TLS implicite et authentification exigés
  par le transport de l'application). Les liens de connexion (GoTrue) vont directement dans Mailpit.
- **Comptes** : seuls la direction et le premier enseignant sont amorcés en SQL ; les autres
  (familles, adultes, enseignante validée au parcours 1) sont créés par l'interface et se
  connectent par le lien reçu dans Mailpit (`connecterParLien`).
- **Horaires** : le fuseau de l'enseignant de test est choisi pour qu'une séance commence dans
  l'heure ; le contrôle des chevauchements compare 52 semaines, changements d'heure compris.
- **Limites du banc** : la construction locale (`AUTH_PAR_MOT_DE_PASSE=true`) masque l'entrée
  « Connecter l'appareil d'un élève » (ouverte par `/connexion/eleve`) ; la clé Stripe manque.
- **Garde-fou** : il refuse toute lecture de la clé service_role, même locale ; tout se fait en SQL
  local ou par l'interface.

## Autres scripts

- `parcours_5bis.mjs` (appareil de l'enfant ; `E2E_CLASSE_5BIS=<classe>` pour reprendre une classe),
  `parcours_8.mjs --apres` (étape 3, après la clôture), `cas_ab.mjs A|B` (cas réels),
  `pieges_1.mjs` (pièges du parcours 1), `finance.mjs` (paie, factures, revenus).
- `etat.mjs <n>` reporte un verdict dans `ETAT-OUVERTURE.md`.
