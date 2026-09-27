# AGENT_HANDOFF — point d'entrée pour OpenCode, Hermes, et tout agent hors Claude Code

Ce fichier existe parce que trois outils travaillent sur ce dépôt (`~/.claude/CLAUDE.md`
de l'opérateur les nomme : Claude Code, Hermes Agent, OpenCode), et que la
mémoire d'agent de l'un n'est pas lue par les deux autres. Les règles du projet
vivent dans le dépôt, pas dans une mémoire propriétaire : c'est ce fichier qui
les rassemble pour un agent qui n'a jamais ouvert ce dépôt.

**Si tu es Claude Code** : `CLAUDE.md` à la racine est ton point d'entrée
habituel, tu peux le lire directement. Ce fichier n'ajoute rien pour toi que
`CLAUDE.md` ne dise déjà, il existe pour que la même information atteigne les
deux autres outils.

## 1. Lire dans cet ordre, avant toute tâche

> **Statut au 14 septembre 2026 : OpenCode est abandonné.** Ce document est
> conservé pour l'historique et pour éviter de perdre les règles qu'il
> rassemblait, mais aucune tâche ne doit plus être déléguée à OpenCode et aucun
> de ses changements concurrents ne doit être promu ou déployé. Le handoff
> actif et les prompts de clôture sont dans `docs/HANDOFF.md`, section 10 ;
> l'exécution restante relève de Claude Code et des opérations explicitement
> autorisées par l'opérateur.

1. **`docs/HANDOFF.md`** — où la session précédente s'est arrêtée, le lot à
   reprendre, les commandes vérifiées sur ce poste, les mesures à ne pas faire
   régresser.
2. **`docs/PROGRESS.md`**, section DÉMARRER ICI — l'état du projet dans son
   ensemble.
3. **`docs/design/00-bible-frontend-v2.md`** avant tout écran, tout composant,
   toute couleur — le contrat frontend (ADR-019), 61 chapitres. Puis
   `docs/design/README.md` §4 BIS, qui dit ce qui en est déjà tenu et ce qui
   reste un écart ouvert.
4. **`docs/architecture/decisions.md`** — le registre ADR, questions déjà
   tranchées. Ne jamais retrancher une question qui y est déjà résolue.
5. **`lib/CLAUDE.md`** — les règles non négociables du code Flutter, celles que
   `tool/verifier_jetons.dart` fait échouer en CI si elles sont ignorées.
6. **`supabase/CLAUDE.md`** — si la tâche touche le backend.

Ne pas ouvrir l'historique des étapes passées (`docs/architecture/etape-*-journal.md`)
sauf doute précis sur un point : `docs/HANDOFF.md` dit lesquels lire selon la
tâche.

## 2. Ce qui est non négociable, quel que soit l'outil qui écrit le code

- **Aucun écran ne s'implémente s'il n'est pas inscrit dans
  `docs/design/08-catalogue-ecrans.md`.** S'il manque, on l'ajoute au catalogue
  d'abord, avec sa fiche complète, avant d'ouvrir un fichier `.dart`.
- **Aucune couleur, police, rayon, ombre, durée, courbe ou espacement inventé.**
  Tout vient de `docs/produit/design-tokens.md`, et `tool/verifier_jetons.dart`
  le vérifie mécaniquement. Lance-le avant de déclarer un travail fini :
  `dart run tool/verifier_jetons.dart`.
- **Un seul routeur**, `lib/core/router/app_router.dart`. Aucune branche par
  plateforme ni par mode d'interface.
- **La RLS est la barrière, le routeur est une commodité.** Ne jamais faire
  reposer une règle de sécurité sur une redirection côté client.
- **Un widget ne lit jamais un rôle, il lit une capacité.**
- **Un écran n'est fini qu'avec ses états** `loading`, `content`, `empty`,
  `error`, `offline`.
- **Branche `refactor-ui-lavender-3628477128789856989` : l'ignorer.** Travail de
  Google Jules, basé sur une autre branche (`specs`), divergent. Ne jamais
  déployer un commit qui n'est pas vert sur `main`.
- **`main` est déployé en production** sur `rewayah-academy.vercel.app` à
  chaque push. Ne pousser que du travail vérifié par les cinq contrôles de
  `docs/HANDOFF.md` §5 (ou §6 de ce fichier).

## 3. Le plan d'application de la Bible Frontend V2 (ADR-019)

Huit lots, un par session, chacun se terminant par un commit et un push :
**B0** (ancrage, ce lot) → **T2** (durcir le langage) → **R0** (tunnel
d'entrée) → **T3** (mode sombre) → **R4** (reste de l'existant) → **A1**
(accessibilité, RTL et clavier prouvés) → **N0** (specs de l'étape 5) → **L10**
(clôture de l'étape 4, dette indépendante). Détail complet dans
`docs/design/README.md` §9 et `docs/architecture/decisions.md`, ADR-019.

**Un lot par session.** Ne pas déborder sur le lot suivant même si le temps ou
le budget le permettrait : c'est ce qui garde chaque commit relisible et
chaque échec isolé à un seul lot.

## 4. Fin de session : le prompt de reprise est obligatoire

Toute session, quel que soit l'outil, se termine par trois choses, dans cet
ordre :

1. Les contrôles de vérification (section suivante), avec les chiffres réels
   lus dans leur sortie — jamais une appréciation.
2. La mise à jour de `docs/HANDOFF.md` avec un état honnête du lot fait, de ce
   qui reste, et des écarts consignés.
3. Un commit, un push, puis **ce gabarit rempli**, prêt à copier dans la
   prochaine session :

```
Rewayah Academy -- depot D:\RA _APP\RA -OFFICIAL-APP, branche main @ <SHA>.
Chemins en absolu.

Lis docs/HANDOFF.md, puis docs/design/00-bible-frontend-v2.md (chapitres
pertinents pour le lot suivant), puis docs/AGENT_HANDOFF.md si tu n'es pas
Claude Code.

DERNIER LOT FAIT : <nom> -- <une ligne>
  Mesures : analyze <...>, tests <N>, jetons <N> fichiers, SQL <34+39>
  Restes ou ecarts consignes : <... ou aucun>

LOT SUIVANT : <nom> -- <objectif en une phrase>
  Fichiers : <liste courte>
  Decisions a faire trancher par l'operateur AVANT de coder : <... ou aucune>

Un lot par session. Fin de lot : controles + capture 390x844 si visuel +
HANDOFF.md + commit + push, jamais l'inverse. Ignore refactor-ui-lavender.
```

Ce gabarit existe pour qu'aucune session, sur aucun des trois outils, n'ait
besoin qu'on lui redonne les mêmes instructions.

## 5. Budget

Le plan de l'opérateur est serré (limites hebdomadaires). Sur Claude Code, un
budget épuisé se contourne en déléguant à OpenCode via ce fichier plutôt que ce
fichier n'existerait pas : c'est exactement pour ce genre de relais qu'il est
écrit. Un lot dont l'implémentation est terminée mais dont la vérification n'a
pas pu tourner **n'est pas un lot fini** : ne pas le déclarer tel dans
`docs/HANDOFF.md`.

## 6. Commandes vérifiées sur ce poste

```
cd "D:\RA _APP\RA -OFFICIAL-APP"
flutter pub get
dart run slang                                          # AVANT build_runner
dart run build_runner build --delete-conflicting-outputs
dart analyze --fatal-infos
flutter test
dart run tool/verifier_jetons.dart
```

Harnais SQL : les commandes Docker exactes, avec la boucle `pg_isready`, sont
dans `docs/HANDOFF.md` section 6. Ne pas les redeviner : les noms de migration
sont ceux du dépôt.

PowerShell 5.1 : ne jamais rediriger `2>&1` sur un exécutable natif (ça
fabrique un `NativeCommandError` même quand la commande a réussi) ; lire la
sortie plutôt que le code de retour.
