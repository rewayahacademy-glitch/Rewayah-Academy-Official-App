# Quatre agents de construction, et les règles pour bien livrer : décision du directeur du 02/11/2026

Décision écrite par le pilote. Elle amende le §3 de `DECISION-AUTONOMIE-2026-10-29.md`, qui
fixait deux agents au plus ; le reste de cette décision tient.

## 1. Ce que le directeur a dit

- Par le garde-cap, le 02/11 :
  - « Un agent super puissant cherche tout ce qui a été bien codé mais pas branché, et le
    branche, même hors des boucles ; puis on finit les boucles ; ce qui reste, on code tout, on
    branche tout. »
  - Il veut qu'on finisse d'ici demain.
  - « Le garde-cap corrige le plan du pilote. »
  - La recette en production est son affaire. Ce n'est pas un préalable qu'on lui renvoie ;
    notre affaire, c'est que tout marche quand il testera.
- Au pilote, le 02/11 vers 15:30 UTC : « Va pour 4 agents, mais tu écris des règles strictes
  qui permettent à tout le monde de bien faire et bien livrer, sans refaire les erreurs du
  passé. »

Les règles ci-dessous sont celles-là. Chacune cite l'erreur passée qu'elle empêche. Le pilote
les copie dans chaque consigne d'agent, et un agent qui en enfreint une voit sa PR refusée.

## 2. Qui fait quoi

| Rôle | Nombre | Fait | Ne fait jamais |
|---|---|---|---|
| Pilote | 1 | attribue lots, zones et numéros ; relit ; voit les captures ; installe les migrations ; fusionne, une PR à la fois | construire un lot |
| Garde-cap | 1 | relève ce qui reste ; corrige le plan du pilote avant lancement ; relit sur demande | construire, fusionner, migrer |
| Agents de construction | **4 au plus** | un lot, une branche, une PR brouillon, ses captures | fusionner, migrer, toucher la zone d'un autre |

## 3. Les règles

### Zones

- **Z1. Une zone écrite par agent.** Elle tient dans sa consigne et comprend :
  - une branche ;
  - des dossiers ;
  - une plage de numéros de migration donnée par le pilote.

  Un fichier hors de la zone ne se modifie pas. Si le lot l'exige, l'agent s'arrête et le
  demande au pilote.
  - *Erreur évitée :* deux lots ont pris le même numéro `20261104500000`, puis
    `20261104700000`, et il a fallu renuméroter deux fois.
- **Z2. Les fichiers partagés se modifient seulement par ajout.**
  - Fichiers concernés : `assets/i18n/*.json`, `tool/libelles_sources.json`, `lib/main.dart`,
    `tool/branchement_tolere.txt`, `docs/current/UX-CONSTATS.md`, `ETAT-OUVERTURE.md`.
  - Pour les textes, chaque agent ajoute ses clés sous un préfixe propre à son lot, puis
    régénère avec `dart run slang`. Les fichiers générés (`strings*.g.dart`, `*.g.dart`) ne se
    corrigent jamais à la main. En cas de conflit : fusionner `main`, puis régénérer.
- **Z3. Avant d'écrire une ligne, chercher ce qui existe déjà.**
  - Lire `INVENTAIRE-NON-BRANCHE-2026-10-31.md`, `tool/branchement_tolere.txt` et le code.
  - Le bilan dit ce qui a été réutilisé, et ce qui a été écarté et pourquoi.
  - Un doublon d'un module branché ne s'écrit pas. Un module en double ne se supprime qu'avec
    l'accord du directeur.

### Base de données

- **B1. Rendre une colonne facultative, ou changer son sens, oblige à recenser tous ses
  lecteurs.**
  - Recenser en SQL, en Edge et en Dart, avec la liste dans l'en-tête de la migration.
  - Chaque lecteur cassé est corrigé dans le même lot, avec une contre-preuve rouge puis verte.
  - *Erreur évitée :* au lot (A), `pour_mille` NULL donnait une facture à 0 et levait une
    suspension ; les deux pièges ont été trouvés à temps.
- **B2. Les fonctions de déclencheur sont en `SECURITY DEFINER` dès qu'elles appellent une
  fonction de `private`.**
  - Elles portent `SET search_path = ''`, puis `REVOKE` à tous.
  - Le scénario insère en tant qu'`authenticated` et `service_role`, jamais seulement en
    `postgres`.
  - *Erreur évitée :* le déclencheur de NOTIFS-L6 était en `INVOKER`, et toute insertion venue
    d'une fonction Edge aurait échoué.
- **B3. Une politique RLS qui appelle une fonction de `private` donne l'`EXECUTE` à chaque rôle
  qui lit la table**, `agent_ro` compris.
  - *Erreur évitée :* au lot (B), `agent_ro` ne pouvait plus lire `session_recordings`.
- **B4. Une fonction existante se retouche par ancre.**
  - On applique `pg_temp.remplacer`, qui échoue si l'ancre n'est pas trouvée exactement une
    fois.
  - On rafraîchit l'empreinte F86.
  - Un bloc `postflight` vérifie le résultat.
  - On ne recopie jamais une fonction entière quand une ancre suffit, car la production peut
    différer du dépôt.
- **B5. Les mots d'effacement sont isolés.**
  - Si un lot contient `DROP`, `DELETE` ou `TRUNCATE`, même `DROP NOT NULL`, ce passage va
    seul dans un petit fichier, que le directeur colle depuis la page du pilote.
  - Le reste va dans un fichier sans aucun de ces mots, que le pilote installe.
  - L'en-tête de chaque fichier dit lequel des deux il est.
- **B6. Une migration est additive.** L'ancien code de production doit continuer de marcher
  avec elle, parce que le pilote l'installe avant la fusion. On ne supprime ni ne renomme rien
  que l'ancien code lit.
- **B7. Aucune écriture en production depuis un agent**, ni par `execute_sql`, ni par les
  robots E2E, ni par une fonction Edge. Les robots tournent sur la pile locale seulement.

### Tests et textes

- **T1. Aucun test instable.**
  - On ne cherche jamais une sous-chaîne dans un identifiant tiré au hasard.
  - Toute expression régulière construite à partir d'une donnée est échappée.
  - Un test qui échoue « une fois sur dix » est un bug du test.
  - *Erreur évitée :* `scenarios_cpt_suppression_export` (motifs `f02` et `-7.6`).
- **T2. Avant la PR, lancer la suite complète.**
  - Commandes : `dart run slang`, `build_runner`, `dart analyze --fatal-infos`, `flutter test`,
    `verifier_jetons`, `verifier_branchement`, plus les scénarios SQL du lot et ceux des tables
    touchées.
  - Les échecs déjà connus sont cités par leur nom, avec leur cause ; aucun autre n'est
    toléré.
- **T3. Tout texte visible passe par la compétence `mots-rewayah`.**
  - On n'écrit jamais deux libellés contradictoires sur un même écran.
    - *Erreur évitée :* capture 04 du lot (B), avec « Financé jusqu'au » à côté de
      « À financer ».
  - Ni « cours en cours », ni aucun code (`FN-`, `BO003`, nom de table) dans un texte lu par
    une personne.
- **T4. Un écran n'est fini qu'avec ses cinq états** : chargement, contenu, vide, erreur, hors
  ligne.
  - Un bouton actif ne ressemble pas à un bouton éteint.
    - *Erreur évitée :* UX-046.

### Livraison

- **L1. Une PR brouillon par lot.** Si le diff hors fichiers générés et captures dépasse environ
  1 500 lignes, ou s'il touche deux domaines, le lot se coupe en deux PR.
- **L2. Pas de capture, pas de fusion (R3).**
  - Le dossier `docs/current/captures/E2E/<lot>/` contient :
    - les captures à 1440 et à 390 ;
    - un `verdict.json` ;
    - un `journal.txt`.
  - Le robot vérifie le texte attendu, pas seulement l'absence d'erreur.
  - Chaque capture montre ce qu'elle prétend montrer : pas le haut de la page quand la ligne
    est plus bas.
- **L3. La description de PR commence par ce qui est faux, bloqué ou non prouvé.**
  - On ne dit jamais « fait ». On dit « PR prête » ; « fait » veut dire prouvé par le
    directeur.
- **L4. Ne pas fusionner `main` dans sa branche sans raison**, puisque chaque fusion relance une
  heure de CI. Il n'y a que deux raisons :
  - un conflit réel ;
  - une demande du pilote.
  - *Erreur évitée :* la PR 135 a été relancée pour rien.
- **L5. Après « relu » du pilote, on ne pousse plus rien.** Seule exception : une CI rouge,
  avec sa cause dite au pilote avant la poussée.
- **L6. Interdits à tout agent de construction** :
  - `merge_pull_request`, `apply_migration`, `execute_sql` en écriture ;
  - `.github/`, `pubspec.yaml`, `vercel.json`, `.claude/settings*.json` et `.claude/hooks/` ;
  - toute clé ou tout secret, toute adresse e-mail dans le dépôt, tout nom de modèle dans un
    commit ou une PR ;
  - tout contournement du garde-fou.
- **L7. Rendre compte au pilote par `send_message`, en quelques lignes**, dans cet ordre :
  1. ce qui est faux ou bloqué ;
  2. la PR et son dernier commit ;
  3. les migrations et leurs mots d'effacement ;
  4. le dossier de captures ;
  5. les échecs de test connus.

### Pilote

- **P1. Avant chaque fusion**, le pilote :
  - relit les vérifications du dernier commit (toutes vertes, aucune en cours) ;
  - voit les captures ;
  - vérifie en lecture, sur la production, chaque ancre de chaque migration ;
  - compte les mots d'effacement.
- **P2. Ordre d'une livraison avec migration :**
  1. le directeur colle le fichier à effacement, s'il y en a un ;
  2. le pilote installe le fichier sans effacement et vérifie ;
  3. la CI est verte, puis le pilote fusionne.

  Une seule fusion à la fois : la suivante attend le déploiement de la précédente.
- **P3. Le directeur reçoit une seule action à la fois**, par une page privée pour tout
  collage, en mots simples.
- **P4. Le garde-cap relit le plan de lots** avant tout lancement. Sans sa relecture, aucun
  agent ne part.

## 4. Risque accepté, dit tel quel

- À quatre agents, le pilote devient le passage obligé : relecture, captures, migrations,
  fusions une par une, environ une heure de CI par PR. « D'ici demain » n'est pas garanti ;
  le pilote dit chaque soir au directeur ce qui est fusionné, ce qui attend, et pourquoi.
- Les conflits sur les fichiers partagés restent possibles malgré Z2. Ils se règlent par une
  fusion de `main`, puis une régénération, jamais par un passage en force.
