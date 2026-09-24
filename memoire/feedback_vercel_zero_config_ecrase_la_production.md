---
name: feedback_vercel_zero_config_ecrase_la_production
description: "Sur un dépôt que Vercel ne sait pas construire, le déploiement Git zero-config sert le dépôt BRUT, se marque READY, et prend l'alias de production — 404 partout, sans aucun signal."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b30e2d16-b513-40af-a9aa-abfc569df7fe
  modified: 2026-09-21T06:39:07.660Z
---

Un projet Vercel sans framework détecté et sans `package.json` à la racine n'a **aucune
commande de build**. Le zero-config ne refuse pas : il publie le répertoire racine du dépôt
tel quel. Le déploiement est marqué **READY**, jamais ERROR. S'il vise la production, il prend
automatiquement l'alias — et remplace l'application par un site mort.

Mesuré le 21/09/2026 sur Rewayah (dépôt Flutter, projet `rewayah-academy`, framework `null`) :

| URL sur un déploiement Git « READY »   | Réponse |
|----------------------------------------|---------|
| `/`                                    | 404 `NOT_FOUND` |
| `/index.html`                          | 404 |
| `/main.dart.js`                        | 404 |
| `/pubspec.yaml`                        | **200** `text/yaml` |
| `/lib/main.dart`                       | **200** |

C'est exactement la panne du 18/09 (commit `fdf5168`) : « un build vide de 292 ms,
rewayah-academy.vercel.app rendait 404 sur toutes les routes ».

**Why:** un déploiement qui réussit à ne rien construire est indiscernable d'un déploiement
réussi, tant qu'on lit le statut au lieu du contenu servi. C'est le cas où la garde
« contrôler le bundle SERVI, pas le message de la CLI » ([[feedback_chiffrer_avant_de_proposer]])
n'est pas une précaution mais la seule mesure qui existe.

**How to apply:**
- Sur un dépôt que Vercel ne construit pas (Flutter, Dart, Rust, Go sans adaptateur), poser
  `{"git": {"deploymentEnabled": false}}` dans `vercel.json` — **le booléen, pas
  `{"main": false}`**. La forme étroite ne couvre que `main` et laisse chaque branche produire
  un déploiement public inutile.
- `deploymentEnabled` ne borne QUE l'intégration Git. `vercel deploy` en CLI reste la voie de
  production et n'est pas touché.
- Deuxième conséquence, moins visible : ces déploiements servent le **code source** au public.
  Sans protection de déploiement, `/supabase/config.toml`, `/.github/workflows/*.yml` et
  `/lib/**` répondent 200 sans authentification. Vérifier `passwordProtection`,
  `ssoProtection`, `trustedIps` — et supprimer les préviews déjà en ligne, car couper la
  création n'efface pas l'existant.
- Le `vercel.json` qui gouverne un bundle déployé à la CLI est celui qui est **dans le
  dossier déployé** (`web/vercel.json` copié par Flutter dans `build/web/`), pas celui de la
  racine. Deux fichiers, deux portées : le premier sert, le second ne sert qu'aux
  déploiements Git — donc à rien quand ils sont coupés.

Voir [[rewayah_chaine_deploiement_reparee_2026-09-21]].
