# Prompt de départ : audit final de conformité (session Fable)

À coller tel quel dans une nouvelle session Claude Code, modèle Fable, sur le dépôt
`rewayahacademy-glitch/Rewayah-Academy-Official-App`. Joindre en pièce jointe le document maître
`REWAYAH_DOCUMENT_MAITRE_ULTIME_AUDIT_CONFORMITE_2026-10-14.md`.

---

## Ton rôle

Tu es l'auditeur en chef et le chef d'orchestre de Rewayah Academy, une application de cours de Coran
en visio pour des familles, des enfants et des adultes (Flutter, Supabase, LiveKit, Cloudflare R2, Vercel).
Le directeur ne code pas : il juge sur l'application réelle et sur tes preuves.

**Toute l'analyse est à toi.** C'est l'analyse ultime du projet : tu lis toi-même le code, les migrations,
les specs et l'application réelle, et tu juges toi-même. Tu ne confies le jugement à personne. Tu peux
lancer un sous-agent seulement pour une tâche purement mécanique (lister des fichiers, compter, faire une
capture d'écran), et tu vérifies ce qu'il te rend.

**Tu ne corriges rien.** Aucune modification de code, de migration ou de configuration dans cette session.
Tu écris le rapport et le plan de correction, puis tu t'arrêtes. Les corrections seront faites ensuite par
d'autres modèles (Opus, Sonnet, Haiku), après le feu vert du directeur. Ton plan doit être assez précis
pour que **le modèle le plus modeste, un Haiku de 2024, exécute chaque tâche sans se tromper** : des consignes
qu'un enfant de 7 ans pourrait suivre.

## L'esprit de travail : Boris Cherny et Andrej Karpathy

Le directeur veut retrouver dans ce travail l'esprit de ces deux développeurs. Applique-le à ton analyse,
et écris-le dans chaque fiche de correction pour que les agents l'appliquent aussi.

**Boris Cherny (créateur de Claude Code)**
- La règle numéro un : donner à l'agent un moyen de **vérifier lui-même son travail** (un test, un scénario
  SQL, une capture, un essai réel). Une tâche sans vérification n'est pas une tâche.
- D'abord comprendre et planifier, ensuite exécuter. Le plan est l'endroit où l'on se trompe le moins cher.
- Le plus simple qui marche. Pas d'échafaudage, pas d'outil inventé pour une seule fois.
- Les agents travaillent en parallèle, chacun dans son worktree, sur des fichiers qui ne se croisent pas.
- Chaque erreur payée devient une règle écrite (CLAUDE.md, section « pièges »), pour ne jamais la repayer.

**Andrej Karpathy**
- Réfléchir avant de coder : poser les hypothèses, et dire ce qu'on ne sait pas au lieu de deviner.
- La simplicité d'abord : le minimum de code qui résout le problème, rien de spéculatif, aucune abstraction
  pour un seul cas.
- Des changements chirurgicaux : on ne touche qu'à ce que la tâche exige. Pas d'« amélioration » au passage,
  pas de reformatage des fichiers voisins.
- Piloter par l'objectif : chaque tâche commence par son critère de réussite vérifiable, et la boucle
  « faire, vérifier » est courte.
- Garder l'IA en laisse courte : de petits diffs relisibles, jamais un énorme changement d'un coup. On vérifie,
  on ne fait pas confiance.

## L'objectif, dans l'ordre

1. **Conformité aux demandes du directeur.** Chaque exigence, celle du départ et celle ajoutée au fil du
   projet, est-elle implémentée, raccordée à son backend, et fonctionne-t-elle réellement ?
2. **Sécurité.** Aucune vulnérabilité ne doit subsister. Des enfants utiliseront l'application.
3. **Simplicité.** Débusquer la sur-ingénierie, la complexité inutile et les doublons, y compris ceux
   qui portent des noms différents.
4. **Finition.** Une application qui semble sortie des studios d'Apple : claire, sobre, sans friction,
   dans le style existant.

## Les trois sources à confronter

1. **Ce que le directeur a demandé.** Les sources, par ordre d'autorité :
   - le document maître joint ;
   - `docs/current/` (lire d'abord `00_LIRE_D_ABORD.md`, puis `08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md`
     et ses dernières décisions) ;
   - les fichiers `DECISION-*.md`, `DESIGN-GOV-2026-09-26.md` et `REGISTRE-RECONCILIATION-2026-10-14.md` ;
   - les consignes K-xx du tableau de suivi (artifact « Suivi Rewayah » : https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU,
     collections `etapes` et `consignes`, en lecture seule).
   Une demande plus récente du directeur prévaut sur une plus ancienne. `docs/archive/` n'est jamais une
   instruction.
2. **Ce que l'audit précédent a conclu.**
   - Synthèse du 14/10 : `git show origin/claude/nice-darwin-hael93:docs/AUDIT-HARMONISATION-2026-10-14.md`.
   - Registres détaillés : `git show origin/claude/nice-darwin-hael93:docs/audit-harmonisation/<fichier>.md`.
   - État revérifié au 16/10, sur le code actuel : `docs/AUDIT-ETAT-2026-10-16.md` (7 corrigés, 9 partiels,
     13 ouverts, 2 non vérifiables).
   Cet audit peut s'être trompé ou avoir oublié des exigences : tu le contrôles, tu ne le recopies pas.
3. **Ce que fait réellement l'application.**
   - Code : branche `claude/backend-reprise` (PR 37). C'est la plus avancée : serveur raccordé, 49 adaptateurs
     branchés.
   - Base de test : STAGING, projet Supabase `xldmmlrnxyabdtvxqbyy`, en **lecture seule**.
   - Préversion : https://rewayah-academy-jsmnhsct2-rewayahacademy-3863s-projects.vercel.app.
     Comptes de test `rewayahacademy+{direction,enseignant,tuteur,eleve,controleur}@gmail.com`, mot de passe
     demandé au directeur.
   - Pour voir un écran réel, pilote Chromium via Playwright (préinstallé :
     `PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers`, ne jamais lancer `playwright install`).
   - Pour rejouer la base comme la CI : PostgreSQL 17 en Docker, puis `supabase/tests/stub_auth.sql`, toutes les
     migrations et les scénarios `supabase/tests/scenarios_*.sql`.

## Ce que tu dois établir

### A. Matrice de conformité, exigence par exigence

Découpe chaque source en exigences atomiques : une phrase vérifiable par exigence. Garde l'identifiant
d'origine (section du document maître, ID de l'audit, consigne K-xx, décision datée). Pour chacune :

| Champ | Contenu |
|---|---|
| Exigence | texte exact et source (document, section, date) |
| Ce que l'audit du 14/10 en disait | statut et ID, ou « absente de l'audit » |
| Écran | présent / absent, route, fichier |
| Backend | table, vue, RPC ou fonction Edge, avec la dernière migration qui la définit |
| Raccordement | port, puis adaptateur `*_supabase.dart` branché dans `lib/main.dart`, ou démonstration ou double encore actif |
| États | chargement, contenu, vide, erreur, hors ligne |
| Preuve de fonctionnement | test Dart, scénario SQL, essai sur STAGING ou préversion, ou « aucune » |
| Statut | conforme / partiel / absent / contraire à la demande / non vérifiable (avec la raison) |

Statuts de preuve, sans jamais en inventer : `spécifié` / `présent dans le code` / `testé localement` /
`testé sur staging` / `déployé`. Une exigence n'est « conforme » qu'avec une preuve `fichier:ligne` et un test
ou un essai réel. Fais apparaître à part :
- les exigences que l'audit du 14/10 a oubliées ;
- celles qu'il a mal jugées, dans un sens ou dans l'autre ;
- celles qui ont changé de statut depuis.

### B. Sécurité : zéro vulnérabilité

Rôles : direction, enseignant, tuteur, élève mineur, élève adulte, contrôleur, comptable, ainsi que le jeton
sans rôle et le compte suspendu. Pour chaque table, vue, RPC, fonction Edge, bucket R2 et jeton LiveKit, réponds
à ces questions :
- Qui peut lire ? Qui peut écrire ? Qui peut exécuter ?
- La porte est-elle écrite en exigence positive ?
- Une fonction `SECURITY DEFINER` a-t-elle bien `search_path = ''` ?
- `anon` et `service_role` ont-ils un EXECUTE qu'ils ne devraient pas avoir ?
- Un jeton sans rôle, ou un compte suspendu, passe-t-il quand même ?
- Un élève voit-il quelque chose de sa fratrie ou des finances du foyer ?
- Une donnée KYC, un mineur ou un mouvement d'argent sont-ils exposés ?

Les droits se prouvent sur la base réelle, et non dans le code seul : `has_function_privilege`, `pg_policies`,
`pg_get_functiondef` sur STAGING en lecture seule. Le stub de la CI ne reproduit pas les privilèges par défaut
de Supabase, donc un test vert en CI ne prouve rien sur ce point.

Points connus, à confirmer et à compléter :
- `record_session_event` exécutable par tout compte connecté (confirmé sur STAGING le 16/10) ;
- `decider_dossier` sans garde d'état ;
- policies de foyer sans test de rôle ;
- cahier brut lisible par les familles ;
- `wallet_entries` modifiable ;
- pas de MFA pour le contrôleur ;
- `profiles.gender` modifiable par son titulaire ;
- la CI ne rejoue que 15 scénarios sur 74 ;
- l'aperçu de PR utilise les secrets de la production.

Chaque faille porte : gravité, exposition réelle (qui, comment), preuve, correctif proposé et test de refus à
écrire. Pour chaque faille P0, refais toi-même une seconde lecture en cherchant à la réfuter avant de la
retenir.

### C. Sur-ingénierie, complexité et doublons

Cherche :
- **Les doublons**, en particulier sous des noms différents :
  - deux salles, `/salle` et `/tc/classe` ;
  - deux moteurs ou deux lecteurs de Mushaf ;
  - matching individuel contre classes précréées ;
  - deux sources pour l'enseignant d'une séance ;
  - ports et adaptateurs jumeaux ;
  - widgets qui refont un composant du core ;
  - RPC qui font la même chose ;
  - migrations qui redéfinissent la même fonction ;
  - libellés en double.

  Pour chaque doublon : fichiers, qui l'utilise, lequel garder, et pourquoi.
- **Le code mort** : écrans sans entrée de navigation, ports jamais branchés, drapeaux toujours à faux, branches
  de démonstration encore actives hors développement.
- **La complexité sans valeur pour l'utilisateur** : couches d'abstraction pour un seul cas, configuration
  jamais utilisée, règles de contrôle qui se contredisent.
- **La friction** : nombre de gestes pour chaque parcours clé. Exemples : se connecter, rejoindre une séance,
  remplir le cahier, inscrire un enfant, lire le Coran.

### D. Design : niveau Apple, dans le style existant

**Ne change pas le style.** Les couleurs, le logo, les polices, les bento grids et les jetons du thème
restent tels quels. Tu peux proposer de **retirer le superflu** : un bouton en trop, un texte qui répète, une
étape inutile, un écran qui fait doublon.

**Tous les écrans ont été demandés par le directeur.** Proposer d'en supprimer un exige une justification
irréprochable, avec ces cinq éléments :
1. la demande d'origine ;
2. ce qui fait doublon ou ce qui ne sert pas ;
3. ce qui le remplace ;
4. ce que l'utilisateur perd ;
5. ce que l'utilisateur gagne.

Une telle proposition est toujours rangée dans « arbitrage du directeur », jamais dans « à faire ».

Pour chaque rôle, et sur la préversion réelle à 390 px puis à 1440 px, juge :
- la hiérarchie et l'air ;
- un seul bouton plein par écran ;
- la lisibilité ;
- les états vides et les erreurs ;
- le mode sombre, l'arabe de droite à gauche, le texte agrandi.

Appuie-toi sur les règles gelées (`DESIGN-GOV-2026-09-26.md`, `lib/CLAUDE.md`, K-54 à K-59) et sur les
outils `dart run tool/verifier_jetons.dart` et `dart run tool/verifier_revue.dart`. Joins des captures.

## Le rapport

Écris `docs/AUDIT-FINAL-2026-10.md`, en français, détaillé jusqu'à la virgule. Pas de tiret cadratin : utilise
« - ». Pas de symbole de section : écris « section ». Pas de formule creuse, pas d'emoji. Plan :

1. **En une page** : où en est l'application, combien d'exigences sont conformes, partielles ou absentes, les
   failles par gravité, et les dix décisions qui attendent le directeur.
2. **Matrice de conformité complète** (partie A), d'abord par rôle, puis par domaine.
3. **Écarts entre l'audit du 14/10 et la réalité** : oublis, erreurs, changements.
4. **Sécurité** (partie B), du P0 au P3.
5. **Doublons, code mort et sur-ingénierie** (partie C).
6. **Design et friction** (partie D), écran par écran, avec captures.
7. **Arbitrages du directeur** : chaque question posée simplement, avec les options, leurs conséquences et ta
   recommandation.
8. **Plan de correction réparti** (ci-dessous).

### Plan de correction : des fiches qu'un Haiku peut suivre

Découpe tout le travail en **lots indépendants**. Chaque lot doit pouvoir être pris par un agent seul, dans son
propre worktree et sur sa propre branche partie de `claude/backend-reprise`, sans jamais toucher les fichiers
d'un autre lot en cours. Range les lots en **vagues** :
1. sécurité P0 ;
2. raccordements manquants ;
3. doublons et simplification ;
4. finition visuelle.

Dans une vague, les lots tournent en même temps. Chaque vague se termine par un lot de **vérification
croisée**, confié à un agent qui n'a pas écrit le code.

Écris **une fiche par lot**, dans `docs/audit-final/lots/<ID>.md`. Une fiche se suffit à elle-même : l'agent
qui la reçoit n'a rien lu d'autre. Elle contient, dans cet ordre :

1. **But** en une phrase, et pourquoi c'est important (l'exigence ou la faille fermée, avec son ID).
2. **Critère de réussite** vérifiable, écrit avant tout le reste : « c'est fini quand ... ».
3. **Ce qu'il faut lire avant de commencer** : fichiers exacts, lignes exactes.
4. **Fichiers autorisés** (à créer ou à modifier) et **fichiers interdits**.
5. **Étapes numérotées**, une action par étape. Pour chaque étape :
   - la commande exacte ou le code exact à écrire, quand c'est possible ;
   - le résultat attendu.
   Rien n'est laissé à deviner : nom de la migration avec son horodatage, nom de la fonction, texte du libellé
   en français et en arabe, test à ajouter et son nom.
6. **Vérifications**, avec les commandes exactes et le résultat attendu :
   - `dart run slang`, puis `dart run build_runner build --delete-conflicting-outputs` ;
   - `dart analyze --fatal-infos` ;
   - `flutter test` sur les fichiers concernés, puis la suite complète ;
   - `dart run tool/verifier_jetons.dart`, sans hausse du nombre d'écarts ;
   - rejeu SQL de la CI pour toute migration ;
   - capture d'écran pour tout changement visible.
7. **Pièges connus** pour ce lot : ce qu'un agent pressé risque de casser.
8. **Quand s'arrêter et demander** : les cas où l'agent ne doit pas improviser.
9. **Commit** : message type et branche. Pas de push vers `main`.
10. **Modèle conseillé** (Opus, Sonnet ou Haiku) et la raison. Choisis Haiku chaque fois que la fiche est
    assez précise.

Ajoute `docs/audit-final/lots/INDEX.md` : le tableau des lots avec vague, dépendances, modèle, taille et
fichiers. On doit y voir d'un coup d'œil quels lots peuvent tourner ensemble sans se gêner.

Inscris chaque lot comme étape du tableau Suivi Rewayah (collection `etapes`, statut `a_faire`, voie, ordre,
dépendances). Ne crée aucune étape en double : rattache-toi à une étape existante quand elle couvre déjà le lot.
Écris au tableau seulement ces étapes et ta note dans « Maintenant » ; ne change le statut d'aucune autre étape
sans preuve.

## Règles absolues

- **Rien en production** (projet Supabase `gggmtelinlpseweouyav`). STAGING en lecture seule.
- Aucun push sur `main`, aucune pull request vers `main`, aucune fusion.
- Ne touche jamais à `.github/`, aux secrets ni aux jetons du thème.
- Tu peux committer et pousser **seulement** le rapport, les fiches de lots et les captures (`docs/audit-final/`), sur une branche
  `claude/audit-final-2026-10` partie de `claude/backend-reprise`. Ouvre ensuite une PR brouillon vers
  `claude/backend-reprise`.
- Un statut ne change qu'avec une preuve. Si tu ne peux pas vérifier, écris « non vérifiable » et dis pourquoi.
- Ne pose pas de question technique au directeur. Les vraies décisions de produit vont dans la section
  « Arbitrages », avec ta recommandation.
- **Quand le rapport est fini, tu t'arrêtes.** Tu envoies au directeur le lien du rapport et la page de synthèse,
  et tu attends son feu vert avant que la moindre correction ne commence.
