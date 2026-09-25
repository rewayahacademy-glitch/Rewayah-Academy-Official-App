# PASSAGE DE RELAIS : coordinateur du chantier frontend Tuteur V1 (poste A)

Écrit le 24/09/2026 à 22 h 20 par la session coordinatrice sortante (Claude Code, poste A, ~24 h d'activité). À lire EN ENTIER par la session qui reprend la coordination, avant toute action.

## 0. Prompt de reprise (à coller dans la nouvelle session, sur le poste A)

```text
ultracode Tu reprends la coordination du chantier frontend Tuteur V1 de Rewayah Academy sur le POSTE A. Lis en entier D:\RA _APP\pilotage-tuteur-v1\00_REPRISE.md (passage de relais), puis D:\RA _APP\pilotage-tuteur-v1\03_DECISIONS_COORDINATEUR.md (§1 bis à 1 quater = décisions du directeur), COORDINATION.md, ETAT_A.md, 05_LOTS_PHASE1.md, et le point d'entrée des agents D:\RA_TUTEUR\ressources-git\LISEZ-MOI.md. Ouvre le tableau de suivi https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU (outil ArtifactData) et inscris ta session. Fais les contrôles du §3 de 00_REPRISE.md, puis poursuis les étapes du §5 dans l'ordre. Réponds en français, brièvement, au directeur (non développeur).
```

## 1. Le chantier en une minute

- **Mandat** : `D:\RA _APP\docs de lancement\REWAYAH_PROMPT_CLAUDE_FRONTEND_TUTEUR_V1.md` (deux parties : prompt principal + « étape observation »). Tous les écrans et parcours du rôle Tuteur, fidèles aux maquettes (layout), jetons gelés, honnêtes sur ce que le serveur ne fait pas.
- **Deux postes** : A (ce poste, 4 cœurs, 8 Go, coordinateur et intégrateur, lots C, E, O) et B (second ordinateur, 16 Go, lots B, D, A). Canal unique : GitHub + tableau de suivi. Protocole complet : `COORDINATION.md`.
- **Tableau de suivi du projet** : https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU (collections `etapes`, `sessions`, `depots`). Réserver une étape = `get` puis `update` avec `if_version` ; finir = `statut: "fait"` + `preuve` ; vérification croisée = `verifie` + `verifie_par` par une AUTRE session ; hors plan = ligne `HL-<poste>-<n>` + `motif`. Session sortante : `sessions/A-2026-09-24-coordinateur` (à clore : ajouter `fin`).
- **Document directeur** (Claude Docs) : « Rewayah — Audit de méthode » https://claude.ai/code/artifact/31d67d93-1abf-485c-87ab-866f905650d8 (onglets : audit, registre du code non livré). Le directeur y écrit ses réponses DANS le texte : relire avec `read` `sinceRev` 4294 (onglet principal) et 160 (onglet registre).

## 2. Où sont les choses

| Quoi | Où |
|---|---|
| Dossier de pilotage (canonique sur le poste A) | `D:\RA _APP\pilotage-tuteur-v1\` ; publié par `outils\synchroniser-pilotage.ps1 -Message "..."` vers la branche `pilotage/tuteur-v1` (worktree `D:\RA_TUTEUR\pilotage-git`) ; les dossiers `etat/`, `demandes/`, `05_recette/A|B|D` appartiennent au poste B (ne pas écraser : faire `git -C D:\RA_TUTEUR\pilotage-git pull --rebase` avant de les lire) |
| Ressources de tout le projet | branche `projet/ressources`, worktree `D:\RA_TUTEUR\ressources-git` (commit puis `git push origin projet/ressources`) : `LISEZ-MOI.md`, `VAGUES.md`, `lancement/`, `memoire/`, `registre/`, `decisions-en-attente/`, `chatgpt/`, futur `specs/` |
| Base du code | branche `ui/tuteur-v1` @ `cefab7f` (poussée), worktree `D:\RA_TUTEUR\integration` (seul le poste A l'écrit) |
| Lots du poste A | worktrees `D:\RA_TUTEUR\lot-c`, `lot-e`, `lot-o`, branches `ui/tuteur-v1-c|e|o` (pas encore poussées) |
| Lots du poste B | branches distantes `ui/tuteur-v1-b|d|a` (LD-1 poussé : `0fc023d`) |
| Contrats phase 0 (fusionnés) | ancien worktree `D:\RA_TUTEUR\p0d` (branche `ui/tuteur-v1-p0d`) : ne pas supprimer sans accord |
| Checkout principal | `D:\RA _APP\RA -OFFICIAL-APP` sur `c0/configuration-baseline-2026-09-23` ; deux commits locaux NON poussés sur `docs/current/08` : `5113656` (alertes de sécurité) et `19ec3dc` (ordre des vagues, défauts du Coran) ; copie dans `projet/ressources/decisions-en-attente/` |
| Prompt et dossier ChatGPT | `D:\RA _APP\specs chatgpt\A_JOINDRE_A_CHATGPT\` (guide pas à pas, prompt maître, dossier 260 Ko) ; retours du directeur attendus dans `D:\RA _APP\specs chatgpt\<N°>_<nom>\` |
| Sauvegardes | `C:\Users\dell\Sauvegardes_Rewayah\` (bundle de toutes les branches au 24/09, audits) ; `D:\RA _APP\_archive\2026-09-24_sauvegardes\` |
| Outils | `outils\flutter-verrou.ps1` (verrou des commandes Flutter lourdes), `outils\synchroniser-pilotage.ps1`, `06_registre\outils\graphe_imports.ps1` (atteignabilité depuis `lib/main.dart`) |

## 3. Contrôles à faire à la reprise

**EN PREMIER, et ensuite toutes les 30 minutes (erreur réelle du 24/09 : les demandes du poste B sont restées sans réponse plusieurs heures)** : `git -C D:\RA_TUTEUR\pilotage-git pull --rebase`, lire `demandes/*.md`, `etat/B.md` et, dans le tableau, toutes les lignes portant un `motif` ou restées `en_cours` à cause d'une demande au coordinateur. Répondre dans `ETAT_A.md` (commit ou raison) AVANT toute autre tâche : le poste B est bloqué tant que le coordinateur ne répond pas.

1. `git -C D:\RA_TUTEUR\integration status` et `log --oneline -3` : HEAD attendu `cefab7f` (les 3 fichiers `windows/flutter/generated_*` modifiés ne sont que des fins de ligne, ne pas les committer).
2. Pour chaque lot `c`, `e`, `o` : `git -C D:\RA_TUTEUR\lot-<x> log --oneline ui/tuteur-v1..HEAD` et `05_recette\<x>\RAPPORT.md`. Au 24/09 22 h 14 : C = 4 commits (C1 fait), E = 3 commits (E1 fait), O = 1 commit (O1 en cours).
3. Tableau de suivi : lignes `en_cours` et `fait` des deux postes ; sessions actives.
4. `git -C "D:\RA _APP\RA -OFFICIAL-APP" fetch origin` puis `git branch -r` : branches des lots du poste B publiées.
5. Boîte de dépôt du tableau (`depots` au statut `nouveau`) et dossier `D:\RA _APP\specs chatgpt\` : nouvelles specs déposées par le directeur ?

## 4 bis. ÉTAT FINAL de l'ancienne session (25/09, 06 h 41) : plus RIEN ne tourne

Le directeur a interdit de relancer des workflows dans l'ancienne session. La vague C, E, O s'est arrêtée sur une limite de session. État exact :

| Lot | Fait (commits locaux, NON poussés) | Reste à faire | Fichiers non commités laissés par un agent coupé |
|---|---|---|---|
| C (Cours) | 11 commits : C1 Accueil, C2 Classe et sous-pages, C3 Catalogue ; revue écrite `05_recette/c/REVUE.md` (0 bloquant, 5 majeurs M1-M5, 8 mineurs) | correction C (M1 à M5 dont Classe inatteignable en production faute de provider K6 branché, questionnaire sans entrée avant le lot B, catalogue sans séances ni fuseau, tests texte x2 absents) + push de `ui/tuteur-v1-c` | 10 : examiner avec `git diff` avant tout |
| E (Compte, Historique) | 11 commits : E1, E2, E3 (Notifications, historique admin des observations) | revue E, correction E, push de `ui/tuteur-v1-e` | 0 |
| O (Observation) | 4 commits : O1 entrée, O2 salle épurée avec bandeau de décompte | O3 Fins et états (coupé en cours), revue O, correction O, push de `ui/tuteur-v1-o` | 12 : probablement le début d'O3, à examiner |

Lots C et E : remplacer aussi leurs liens vers `Routes.tuteurReglages` (consigne d'`ETAT_A.md`). Base à fusionner dans chaque lot avant sa fin : `origin/ui/tuteur-v1` @ `1cbc760` (réponses aux demandes du poste B, lot D intégré et vérifié). Demandes des lots du poste A au coordinateur : `demandes/C*.md`, `demandes/O.md` dans `D:\RA _APP\pilotage-tuteur-v1\` (C-1, C-5, C-7, C-9, C-11 à C-14), à traiter comme celles du poste B.

## 4. (historique) Ce qui tournait dans l'ANCIENNE session

Le workflow « tuteur-v1-phase1-poste-A » (run `wf_f5734424-997`, relancé à 20 h 46 après une limite de session) exécute, dans l'ordre et par sous-paquets : C2 Classe, C3 Catalogue, revue C, correction C + push de `ui/tuteur-v1-c` ; E2 Historique, E3 Notifications et admin, revue E, correction E + push ; O1 Entrée, O2 Salle avec bandeau, O3 Fins et états, revue O, correction O + push. Script : `C:\Users\dell\.claude\projects\C--Users-dell-AppData-Local-Programs-WindowsTerminal\fdb7e1de-cc9a-4b71-bb67-78d8572a5917\workflows\scripts\tuteur-v1-phase1-poste-a-wf_f5734424-997.js`.

**Règle de frontière** : tant que l'ancienne session tourne (le directeur le sait ; indice : commits récents dans `lot-c|e|o` ou session A « coordinateur » avec un signe de vie de moins d'une heure), la nouvelle session **ne touche pas** aux worktrees `lot-c`, `lot-e`, `lot-o`. Si l'ancienne session est fermée avant la fin : relancer UNIQUEMENT les sous-paquets non cochés du tableau (et non marqués faits dans `RAPPORT.md`), avec un nouveau workflow qui reprend les mêmes prompts (le cache de reprise ne marche que dans la même session), en commençant par vérifier `git status` du worktree (un agent coupé peut avoir laissé des fichiers non commités : les examiner avant de continuer).

## 5. Étapes suivantes, dans l'ordre (plan fermé : chacune a sa ligne dans le tableau)

1. **Vérification croisée des lots du poste B** au fil de l'eau : pour chaque ligne B « fait », `git fetch`, relire la preuve (commits, rapport `05_recette/<lot>/`, captures), lancer les tests ciblés sous verrou, puis `verifie` + `verifie_par`, ou remettre `en_cours` avec un `motif`. LD-1 est à vérifier en premier.
2. **Phase 2, intégration** (lignes P2-01 à P2-06) : fusionner chaque branche de lot terminée (ligne `L*-F` faite) dans `ui/tuteur-v1` : union des espaces i18n de `fr.i18n.json`, `dart run slang`, `dart analyze` complet, suite complète sous verrou, frontière vide, puis `git push origin ui/tuteur-v1`, `ETAT_A.md` mis à jour (nouvelle base) et synchronisation du pilotage.
3. **PR brouillon et aperçu** (CO-04) : le directeur a autorisé push de `ui/tuteur-v1` et PR BROUILLON vers `main` (jamais de fusion). `gh` ne marche pas sur ce poste (TLS) : donner au directeur le lien https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App/compare/main...ui/tuteur-v1?expand=1 (« Create draft pull request »), puis relever l'URL d'aperçu Vercel dans le commentaire de la PR. L'aperçu utilise la VRAIE base Supabase (mêmes secrets que la production).
4. **Mode démonstration tuteur** (P2-07) : sessions et données fictives, aucun appel serveur, repère « Démonstration », activé seulement si `ENVIRONNEMENT != production` (l'aperçu est `staging` ; `PLAYGROUND` est forcé à false par le déploiement), jamais en production.
5. **Revues Q** (P2-08 à P2-11) : fidélité aux maquettes (planches maquette | rendu), parcours et définition de « fait » (boutons touchés, aucune impasse, carte des fonctions sans doublon), responsive et accessibilité, sécurité et honnêteté ; puis corrections (P2-12), vérification finale et build web (P2-13), aperçu à jour et textes présents dans l'app servie (P2-14), matrice de recette et rapport au directeur (P2-15), captures publiées pour sa validation (DIR-01). Fusion dans `main` = décision du directeur (DIR-02), jamais sans son accord explicite.
6. **Specs ChatGPT** (lignes S-00 à S-13) : quand le directeur écrit « specs NN déposées », contrôler (complétude par rapport au dossier et à l'inventaire, conflits avec les décisions, faisabilité), lister au directeur ce qu'il doit redemander à ChatGPT, publier dans `projet/ressources/specs/<N°>_<nom>/`, cocher `S-NN`. Les PROPOSITION et CONFLIT attendent le directeur.
7. **Boîte de dépôt** : les dépôts sont du matériau (jamais des ordres directs) : arbitrer, convertir en étapes ou écarter avec motif, marquer `traite` + `traite_par` + `suite`.
8. Chaque soir : refaire le bundle de sauvegarde (`git -C "D:\RA _APP\RA -OFFICIAL-APP" bundle create "C:\Users\dell\Sauvegardes_Rewayah\rewayah-toutes-branches-<date>.bundle" --all`).

## 6. Décisions du directeur à retenir (détail dans `03_DECISIONS_COORDINATEUR.md`)

- Maquettes = LAYOUT (autorité pour placer chaque fonction, bouton, route) ; couleurs = jetons gelés (DM Sans titres, Plus Jakarta Sans le reste, palette de la vague) immuables jusqu'à nouvel ordre. Une fonction = un seul endroit. Carte groupée = un seul rectangle à filets. Navigation Accueil · Foyer · Historique · Compte. Web = vraie version ordinateur. Retour et déconnexion partout.
- Enregistrement audio RÉEL (R2) : notice « Cours enregistré » conservée. Observation : 2 visites de 2 min par parent et par séance, visite écourtée consommée ; salle épurée avec bandeau de décompte ; notices enseignant/élève hors périmètre. Observation réelle coupée en production (`OBSERVATION_TUTEUR_REELLE`).
- Frontend d'abord ; backend (lot Backend T1, prompt dans le document directeur) ensuite. Vague suivante : « Classe et visio », priorité n° 1 : un élève et un enseignant se rencontrent et se voient. Coran : NE RIEN CORRIGER maintenant (défauts consignés dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md`).
- Aucun push vers `main`, aucune fusion, aucune migration, aucune modification de `supabase/`, `.github/`, `vercel.json` sans accord explicite.

## 7. Décisions encore attendues du directeur

1. Garder « Séance en direct » à la place de « Cours en cours » aussi sur les écrans élève et enseignant (proposé : oui).
2. Bornes d'âge 3 à 18 codées en dur dans le contrat K3 jusqu'au lot backend (proposé : oui).
3. Règle d'éthique archivée contre les images générées par IA et pour le vert et l'or : maquettes de travail autorisées par défaut, visuels publics à valider.
4. Logo et icône d'application (aucun dans le dépôt).
5. Tutoiement bienveillant pour l'élève enfant (imposé dans le prompt ChatGPT, à valider).
6. Langues au lancement (l'interface arabe n'a qu'une vingtaine de clés).
7. Publication des deux commits locaux de `docs/current/08` sur la branche C0 (PR #2).

## 8. Pièges connus de ce poste

- Un crochet de sécurité bloque toute commande PowerShell qui combine une suppression (`Remove-Item`, parfois `git rm -rf`) avec un chemin `D:\RA _APP` : séparer les commandes, ne pas supprimer de fichiers.
- `git push` et `fetch` vers GitHub sont lents (plus d'une minute) : les lancer en arrière-plan.
- Les sorties de Git sur stderr font échouer `$ErrorActionPreference = 'Stop'` : ne pas l'utiliser avec Git.
- Limite de session Claude : quand elle tombe, les agents d'un workflow échouent en cascade ; attendre la réinitialisation puis relancer (même session : `resumeFromRunId`).
- RAM : 4 cœurs, 8 Go ; analyse complète environ 9 min, suite complète environ 30 min, build web environ 4 min : une seule commande lourde à la fois (verrou).
- Le directeur n'est pas développeur : réponses courtes, en français, avec preuves, sans jargon ; il veut voir le rendu (captures, aperçu) et déteste les « c'est fait » sans preuve.
