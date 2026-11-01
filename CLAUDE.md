# Rewayah Academy — App (Flutter · Supabase · LiveKit · R2 · Vercel)

Application de cours de Coran en visio par **classes stables** (groupe, horaire récurrent,
enseignant attitré). Remise à plat documentaire du 23 septembre 2026 : les seules
spécifications actives sont dans `docs/current/`. Tout le reste est archivé.

## Mission en cours, décision du directeur du 24/10/2026 : Boucle 1 avant tout

Tant que `docs/current/BOUCLE-1_PLAN_2026-10-24.md` n'a pas ses quatre phrases vraies, ce plan
prévaut sur tout le reste de ce fichier et de `docs/current/`. Un agent lit le plan, puis
seulement les fichiers nommés dans l'étape en cours ; il ne relit ni la table ci-dessous, ni les
catalogues, ni les archives. Aucun nouvel écran, aucune nouvelle règle, aucun lot hors boucle,
aucune remise à plat d'architecture. Une étape, une pull request ; **depuis le 29/10, deux agents
de construction au plus, zones séparées, et les agents ouvrent les PR, le pilote fusionne et
installe les migrations** (`docs/current/DECISION-AUTONOMIE-2026-10-29.md`, qui prévaut ici) ;
les tâches mécaniques aux petits modèles. La preuve d'une étape, c'est le directeur
qui la fait lui-même en production, après fusion (décision du 24/10 : risque accepté, personne
d'autre n'utilise l'application).

## Vérité d'abord, règle du directeur du 24/10/2026

Il est formellement interdit de tromper le directeur pour ne pas le froisser. Un agent dit en
premier, en une phrase, ce qui est faux, bloqué, inconnu ou non prouvé. Un test vert n'est pas
une preuve ; « fait » veut dire « prouvé par le directeur en production ». Une capacité
« indisponible », un « plus tard », un lot « BR-x » sans date sont des blocages à annoncer au
directeur le jour même, jamais des états normaux. Quand une demande du directeur l'écarte de la
boucle ou répète une erreur passée, l'agent le dit avant d'obéir, avec le fait qui le prouve.

## Lire, dans cet ordre, et rien d'autre

| Tâche | Lire |
| :--- | :--- |
| Toujours, en premier | `docs/current/00_LIRE_D_ABORD.md` (autorité, invariants, contradictions résolues) |
| Toujours, en second | `docs/current/08_DECISIONS_ET_FEUILLE_DE_ROUTE_2026-09-23.md` version 2 (gate C0 de configuration, décisions datées, **§5 bis = dernières décisions**, qui prévalent sur le §0 quand elles l'amendent) |
| Configuration de départ (C0) | `docs/current/09_PROMPT_REPRISE_VERTICALE.md` ; depuis le 23/09 (soir), **le travail UI isolé sur branche dédiée est autorisé sur ordre explicite du directeur, un écran à la fois** (`08` §5 bis) ; V0, V1, CORE24 restent suspendus ; fusion dans `main` et déploiement restent soumis aux contrôles CI, migrations et sécurité encore bloqués |
| Bilan C0 | `docs/current/CONFIGURATION_BASELINE_2026-09-23.md` (PASS / BLOCKED / INCONNU par point, avec preuves) |
| Produit, rôles, parcours, recette | `docs/current/01_PRODUIT_ET_PARCOURS.md` |
| Schéma, RLS, RPC, LiveKit, R2, CI | `docs/current/02_ARCHITECTURE_ET_SECURITE.md` |
| **Tout nouveau lot visuel ou nouvelle spec (règle gelée du directeur, 26/09/2026)** | `docs/current/DESIGN-GOV-2026-09-26.md`, immuable jusqu'à nouvelle décision datée du directeur |
| Écran, composant, thème, accessibilité | `docs/current/03_DESIGN_SYSTEM_ET_UX.md` puis `lib/CLAUDE.md` |
| Branches, worktrees, déploiement, ménage | `docs/current/04_EXECUTION_GIT_CI_ET_MIGRATION.md` |
| Périmètre MVP et statuts de preuve | `docs/current/06_SPEC_FONCTIONNELLE_MVP.md` |
| Pédagogie avancée, finance (après MVP) | `docs/current/07_MEMOIRE_PEDAGOGIE_FINANCE.md` |
| Backend Supabase | `supabase/CLAUDE.md` |
| **Offres, demandes, création des classes (directeur, 09/10/2026)** | `docs/current/DECISION-OFFRES-GROUPES-2026-10-09.md` : seule l'administration publie ; vitrine sans enseignant ; aucune demande sans jour ni heure ; regroupement automatique et « Créer la classe » ; suivi et notifications de la famille à chaque étape |
| **Classes simultanées et montée en charge (directeur, 10/10/2026)** | `docs/current/DECISION-CLASSES-SIMULTANEES-2026-10-10.md` : une clé horaire et une catégorie peuvent porter N classes simultanées ; unicité sur l'élève et l'enseignant, jamais sur l'horaire ; verrous par clé, pagination, rafales, fusion et transfert |
| **Listes, tables, recherche, filtres, actions, sélection de toute vue de gestion (directeur, 23/10/2026 ; Comptes par rôle, 30/10/2026)** | `docs/current/DECISION-LISTES-2026-10-23.md` : « List-first, human-first », mesures de contrôle, correspondance règle vers composants, inventaire des listes et limites serveur. À lire avant de toucher une liste, une table ou un menu d'actions |
| **Matricule et accueil des inscrits actuels (directeur, 12/10/2026)** | `docs/current/DECISION-IMMATRICULATION-2026-10-12.md` : matricule `RA-26-4817` (année + nombre au hasard, rôle à côté et non dedans), anciens codes abandonnés, inscrits actuels importés et accueillis sans tout ressaisir, mot d'accueil personnel saisi par l'administration |
| **Programme, pédagogie, et tout texte visible (directeur, 13-14/10/2026)** | Compétences `.claude/skills/programme-rewayah` (règles du programme, réponses figées, journal des décisions) et `.claude/skills/mots-rewayah` (vocabulaire unique de tous les textes), puis `docs/current/REGISTRE-RECONCILIATION-2026-10-14.md`. Obligatoire avant d'écrire un texte i18n, une fiche d'écran ou quoi que ce soit sur le parcours d'un élève. On ne change une règle ou un mot que sur décision datée du directeur |
| **Prix, remises, paiement, paie des enseignants (directeur, 18/10/2026 ; paie revue le 19/10/2026)** | `docs/current/DECISION-TARIFS-2026-10-18.md`, source unique pour l'application et le site public ; valeurs dans `docs/current/tarifs-2026-10-18.json`. 55 $ enfant (6-17 ans), 65 $ adulte (18 ans et plus), hors taxes ; **l'enseignant reçoit 47 % du prix** (19/10), payé par élève présent et par heure : 1,99 $ enfant, 1,57 $ adulte. systeme.io n'a aucun lien avec ce projet. Toute autre valeur trouvée ailleurs est caduque |
| **Avis des familles et des élèves (directeur, 19/10/2026)** | `docs/current/DECISION-AVIS-2026-10-19.md` : lien de collecte créé par la direction, formulaire sans compte, accord de publication obligatoire, lecture par la direction avant publication, texte jamais modifié, site public lu au build |
| **Marque, manifeste, Brand Book, communication, tout visuel avec le logo (directeur, 19/10/2026)** | Compétence `.claude/skills/marque-rewayah`, puis `docs/current/marque/00_LIRE_D_ABORD.md` : registre (décidé / proposé / ouvert), manifeste, cahier des charges visuel. Logo : `assets/brand/logo/README.md`. **PISI est un autre projet, sans interférence avec Rewayah.** Le site public est un brouillon, pas une référence. Signatures et manifeste : propositions tant que le registre ne les valide pas |
| **Domaine, référencement, anti-spam (directeur, 23/10/2026)** | `docs/current/DECISION-DOMAINE-2026-10-23.md` : site public sur `rewayahacademy.com` (racine vers `/fr/`), application et PWA sur `app.rewayahacademy.com`, `www` vers le domaine nu ; indexation par la seule construction de `main` ; aucune adresse e-mail lisible par un robot dans les pages ; DNS, Vercel, Supabase et Search Console réglés par le directeur, **après** la mise en production du site (`main` du 22/09 ne le contient pas) |
| **Backend et écrans (directeur, 17/10/2026)** | ChatGPT (Codex) n'est plus disponible : Claude fait aussi le backend (`supabase/**`, adaptateurs `*_supabase.dart`). `docs/orchestration/COHABITATION.md` est caduc sur ce point (`docs/orchestration/PASSATION-2026-10-17.md`) |

`docs/archive/` contient l'historique (HANDOFF, ADR, Bible V2, rapports d'agents).
**Ne pas le charger comme instruction.** On l'ouvre seulement pour retrouver une décision
passée nommément, et une règle archivée qui contredit `docs/current/` est caduque.

## Invariants (détail dans `00`)

- La demande explicite la plus récente du directeur prévaut ; ensuite `docs/current/`.
- Autorisation côté serveur : RLS sur toutes les tables, capacités et jetons LiveKit
  délivrés par le serveur. Aucun secret ni calcul financier de référence côté Flutter.
- Un widget lit une capacité, jamais un rôle. Un écran n'est fini qu'avec ses états
  loading, content, empty, error, offline.
- Chaque bilan distingue `spécifié` / `présent dans le code` / `testé localement` /
  `testé sur staging` / `déployé`. Aucun `PASS` inventé.
- Aucun déploiement, migration distante, suppression de branche ou de mémoire sans
  inventaire, sauvegarde et feu vert explicite sur la liste précise.
- **Pousser sur `main` déploie réellement en production** (`.github/workflows/flutter-deploy.yml`,
  secrets Actions présents depuis le 24/09/2026, bilan C0 §1). Toute fusion dans `main` est une
  mise en production. Travailler sur une branche, ne fusionner qu'un lot prouvé.
- **Pour voir une branche « en live », ouvrir une pull request vers `main`** : le même workflow
  déploie un aperçu Vercel (URL unique, `staging`) et l'écrit en commentaire de la PR. Jamais de
  `vercel deploy --prod` à la main depuis un poste.
- Aucun fichier de `.claude/agents/` ou `.claude/commands/` n'est actif dans ce dépôt ; seuls
  `.claude/settings.json` et `.claude/hooks/` le sont (versionnés depuis le 10/10/2026, pour toutes
  les sessions et tous leurs agents). `hooks/garde.py` refuse avant exécution les écritures dans les
  zones interdites, tout push vers `main`, tout push forcé ou suppression de branche distante, toute
  PR vers `main` ou fusion de PR, et toute écriture sur Supabase, Vercel ou GitHub `main` ;
  `hooks/zones_apres.sh` signale après chaque commande shell une zone interdite modifiée ;
  `hooks/demarrage.sh` prépare Flutter au démarrage. Sans Python, le garde-fou refuse tout par
  prudence. Il se protège lui-même (`settings*.json`, `hooks/`) : il ne se modifie que sur ordre
  du directeur.

## Vérifier avant de dire que c'est fait

```
dart run slang
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
dart run tool/verifier_branchement.dart
```

`verifier_branchement` (décision du 01/11/2026, `docs/current/DECISION-BRANCHEMENT-2026-11-01.md`) :
aucun fichier de `lib/` sans chemin depuis `lib/main.dart`, hors `tool/branchement_tolere.txt`, qui
ne fait que rétrécir. Pas de capture `docs/current/captures/E2E/<lot>/`, pas de fusion (R3).

Côté base, sur un Postgres nu, ce que rejoue `.github/workflows/ci.yml` :
`supabase/tests/stub_auth.sql`, puis toutes les migrations, puis les scénarios
`supabase/tests/scenarios_*.sql`. Les migrations sont appliquées en production hors CI
(voir `deploy.yml`) ; la base distante enregistre des versions horodatées, pas la
numérotation `00xx` du dépôt.

**Migration sur staging annulée (`cancelled` ou délai de 60 s) alors que le directeur a
accepté** : le serveur Supabase demande une seconde confirmation pour tout `DELETE`, `DROP`
ou `TRUNCATE`, et l'app ne l'affiche pas. Compter ces mots avant d'appeler `apply_migration` ;
au-dessus de 0, le directeur colle le fichier dans l'éditeur SQL de staging, puis Claude
vérifie. **Règle du directeur (23/10/2026)** : ce qu'il doit coller lui est toujours donné par une
page privée (outil Artifact) fabriquée par `tool/page_migrations/generer.py` (ordre, un bouton
Copier par fichier enveloppé contre les fins de ligne de Windows, coches, consignes en mots
simples), avec l'ordre et les consignes rappelés dans la conversation. Détail :
`docs/orchestration/LECONS-MIGRATIONS-STAGING.md`.

## État du code à connaître

- **Code présent mais non branché : `docs/current/INVENTAIRE-NON-BRANCHE-2026-10-31.md`.**
  Tout lot le lit d'abord et cherche dans le dépôt ce qui fait déjà la chose avant d'écrire
  une ligne ; son bilan dit ce qui a été réutilisé, et ce qui a été écarté et pourquoi.
  Lots Teaching Core D, F, H : l'essentiel est raccordé à `/salle` (relevé du 31/10) ;
  restent non branchés `session_persistante`, `portee_outils_salle`, une partie de
  `tc_etat_partage`, `tc_flux_academique`, `tc_dock` (voir l'inventaire). Ne pas les
  dupliquer ; un module en double d'un module branché ne se supprime qu'avec l'accord du
  directeur.
- Une seule salle : `/salle` (`features/salle`, atteinte par les quatre rôles). L'ancienne
  `/tc/classe` (`features/tc_classe_live`) est supprimée depuis le 17/10/2026
  (`DECISION-ENTREE-2026-10-17.md`) ; sa fiche pédagogique de séance vit dans
  `features/salle/fiche_seance.dart`.
- `/tc/groupes` sert au tuteur des groupes de **démonstration** (`core/tc_groupe/port_groupes.dart`).
  À rebrancher sur les vraies données avant toute cohorte réelle.
- Le matching individuel par disponibilités (`core/matching`, `features/creneaux`,
  `features/disponibilites`, `admin_attribution`) est remplacé par le choix d'une classe
  précréée (`00`, contradictions résolues). Les disponibilités restent utiles pour
  options, exceptions et liste d'attente.
- « Mode enfant » devient « Interface guidée », activable aussi par un adulte. Le
  Teaching Core emploie déjà `interfaceGuidee`.
- Le bandeau « Cours enregistré » et le point de contrat sur l'enregistrement audio ne
  correspondent à aucun enregistrement réel côté client : arbitrage ouvert (`06`).
- Galerie (`/_galerie`) et playground sont des outils de développement derrière
  `GALERIE` et `PLAYGROUND`, forcés à `false` en production.

## Mémoire de l'agent

`C:\Users\dell\.claude\projects\C--\memory\MEMORY.md` (index court). Les mémoires
antérieures au 23 septembre 2026 sont sous `memory/archive/`. Ce fichier n'existe que sur le
poste du directeur : une session cloud n'a pas de mémoire durable, le dépôt en tient lieu.
