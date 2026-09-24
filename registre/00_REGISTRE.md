# 00 - Registre du code produit mais invisible dans l'application

Date : 24/09/2026, synthèse rédigée entre 16:30 et 17:30 (+03:00). Lecteur visé : le directeur, non développeur.
Sources : les quatre relevés `R1_fichiers_non_atteignables.md`, `R2_branches.md`, `R3_worktrees_stashes.md`, `R4_annonce_vs_atteignable.md` (même dossier), plus **27 revérifications faites par moi-même en lecture seule** (liste au §6).
Rien n'a été modifié : aucun checkout, commit, stash, fetch, push, worktree créé ou retiré. Seules écritures : ce fichier, et des copies de travail dans le dossier temporaire de ma session (hors dépôt).

---

## 1. Conclusion

**Sur `main`, la version censée partir en ligne, 45 fichiers de code (7 551 lignes : les outils de classe de l'enseignant, la synchronisation en direct, l'après-cours, le micro-avis, le signalement) ne sont reliés à aucun écran, le dernier lot fusionné (le parcours de choix d'horaire du tuteur, 5 864 lignes, 22/09) n'a jamais été mis en ligne, et tout le travail resté sur des branches (observation, V0, CORE24, les 40 commits du chantier Tuteur) n'est par construction pas dans l'application : dans presque tous les cas le code existe et n'est pas perdu, il manque le dernier geste (un bouton, une fusion, un déploiement), et « c'est fait » a été affirmé sur la foi de tests qui ouvrent les écrans en appelant le routeur directement, jamais en touchant un bouton.**

En bref :

- **Sur 38 fonctions annoncées comme livrées hors administration, 24 ne sont pas atteignables** par l'utilisateur : 8 ont une adresse mais aucun bouton, 10 sont du code qu'aucun écran n'affiche, 6 n'existent pas sur `main` (R4 §4). Les 17 écrans d'administration annoncés sont, eux, tous atteignables.
- **L'application en ligne est plus ancienne que `main`** : le fichier servi date du 21/09 à 06:17 GMT, le seul commit de `main` postérieur (`4a7aa2b`, 22/09) n'y figure pas (revérifié, §6 n° 22-24).
- **Deux travaux peuvent être perdus pour de bon** : un audit de préproduction et deux tests de sécurité qui n'existent que dans une copie isolée, visée par un script de suppression en attente ; un audit CORE24 jamais enregistré dans Git (§3).
- **Le Coran s'affiche à l'envers sur chaque page, en ligne, depuis le 13/09.** La cause est une seule requête, prouvée jusque dans le fichier réellement servi (§4). Elle est toujours présente dans le chantier Tuteur.

Vocabulaire employé : **atteignable** = un bouton ou un onglet de l'application y mène ; **branché** = le fichier est compilé dans l'application ; **main** = la branche de référence (la pousser déclenche un déploiement depuis le 24/09) ; **branche** = une version parallèle du code, invisible tant qu'elle n'est pas fusionnée ; **non committé** = fichier présent sur le disque mais jamais enregistré dans Git.

---

## 2. Tableau principal

Colonnes « Valeur » : utile / doublon / obsolète / non conforme / manque. « Risque de perte » : oui si le travail n'a qu'un exemplaire hors Git ou sur ce seul poste.

### A. Sur `main`, écrit et testé, jamais relié à l'application (45 fichiers, 7 551 lignes)

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 1 | **Teaching Dock** : outils de l'enseignant (annoter, marquer un verset, masquer pour la récitation, pointer, stylet) | Enseignant, en classe | `main` non branché : `lib/features/tc_dock/` (6 fichiers) + `lib/core/tc_outils/` (9) | Aucun écran ne l'importe ; l'emplacement prévu dans la classe en direct reste vide ; l'enregistrement des annotations renvoie volontairement une erreur « aucune implementation serveur » | R1 §3-§4 ; revérifié : `teaching_dock.dart` a 0 importeur sur `4a7aa2b` ; `port_annotations.dart:211-217` | utile, incomplet (pas de serveur) | intégrer au chantier **Enseignant / Salle** (pas Tuteur : les observateurs n'ont aucun outil, `port_dock_hote.dart:177-180` selon R1) | non |
| 2 | **Synchronisation en direct de la classe** (gestes et état envoyés aux élèves) | Salle, tous | `main` non branché : `lib/core/tc_realtime/` (9) | Le transport est « indisponible » par défaut ; aucun fichier ne le relie à la vidéo | R1 §3 ; revérifié `providers_tc_realtime.dart:25-26` (`TransportIndisponible()`) | utile, prérequis des n° 1, 3, 20 | chantier **Salle** (salle unique) | non |
| 3 | **Reprise après coupure / arrivée en retard** (état partagé de la séance) | Salle, tous | `main` non branché : `lib/core/tc_etat_partage/` (6 sur 8) | Mémoire locale seulement, aucun écran | R1 §3 (`providers_tc_etat_partage.dart:22-23`) ; revérifié : les 2 fichiers atteignables du dossier sont `port_etat_partage` et `shared_content_state`, importés par le lecteur du Coran | utile | chantier **Salle** | non |
| 4 | **Après-cours prérempli** de l'enseignant | Enseignant | `main` non branché : `post_cours_vm.dart`, `port_post_cours.dart`, `panneau_post_cours.dart` | Aucun écran ; le fournisseur de données renvoie une erreur volontaire | R1 §3 (`port_post_cours.dart:299-305`) ; revérifié : `panneau_post_cours.dart` 0 importeur | utile | chantier **Enseignant** | non |
| 5 | **Micro-avis de l'élève** en fin de séance | Élève (l'enseignant voit la tendance) | `main` non branché : `session_feedback`, `rotation_feedback`, `port_feedback`, `feedback_memoire`, `carte_feedback_seance` | Aucun écran ; erreur volontaire côté données | R1 §3 (`port_feedback.dart:99-104`) ; R4 n° 14 | utile | chantier **Élève** | non |
| 6 | **Signalement d'un élève** vers l'administration | Enseignant, Admin | `main` non branché : `port_signalement`, `feuille_signalement` | Aucun écran ; erreur volontaire côté données | R1 §3 (`port_signalement.dart:141-147`) | utile | chantier **Enseignant** (+ réception côté Admin) | non |
| 7 | **Bloc « Avant le prochain cours »** | Élève, famille | `main` non branché : `bloc_avant_prochain_cours.dart` | L'emplacement existe mais affiche « Bientôt disponible » ; le vrai bloc n'y est pas posé | R1 §3 (`emplacements_groupe.dart:38-50`) ; R4 n° 13 ; revérifié : 0 importeur | utile | chantier **Élève** ; à examiner pour le Foyer du tuteur | non |
| 8 | **Bibliothèque ouverte pendant le cours** | Enseignant, Salle | `main` non branché : `class_library_picker.dart` | Aucun importeur | R1 n° 34 ; revérifié : 0 importeur | utile | chantier **Salle** | non |
| 9 | **Barre « Cours en cours »** | Tous | `main` non branché : `barre_cours_en_cours.dart` | Posée nulle part ; aucun test | R1 n° 35 ; revérifié : 0 importeur | utile | chantier **Salle** | non |
| 10 | Deux outils de contrôle (`duree_academique.dart`, `capacites_observateur.dart`) | Vérification de règles | `main` non branché | Pas destinés à l'écran (le second le dit dans son en-tête) | R1 §3 (`capacites_observateur.dart:7-11`) | utile comme test | **conserver tel quel** | non |

### B. Sur `main`, une adresse existe mais aucun bouton n'y mène

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 11 | **Écran de bienvenue de l'enseignant** (ENS-01) | Enseignant | `main`, `/enseignant/bienvenue` | Aucun bouton ; annoncé « écran neuf, routé » ; le test « de bout en bout » l'ouvre en appelant le routeur | R4 n° 22 ; revérifié `git grep enseignantBienvenue 4a7aa2b -- lib` : seulement `routes.dart:133` et `app_router.dart:348` | utile | chantier **Enseignant** (décider où l'ouvrir) | non |
| 12 | **Mes groupes / Espace Groupe** côté élève | Élève | `main`, `/tc/groupes` | Seul le tuteur a un bouton ; les groupes affichés sont **inventés** (démonstration) | R4 n° 6 ; revérifié : seule entrée `accueil_famille_page.dart:467`, `port_groupes.dart:38` = `GroupesDemonstrationLocale()` | utile | élève : chantier **Élève** ; tuteur : déjà corrigé dans le chantier Tuteur (n° 25) | non |
| 13 | **Bibliothèque** (`/tc/bibliotheque`) | Élève, tuteur | `main` | Accessible seulement depuis l'Espace Groupe ; toujours vide (catalogue local) | R4 n° 7 | utile | chantier **Élève** | non |
| 14 | **Liste des élèves (roster)** dans l'Espace Groupe | Enseignant | `main` | La porte d'accès refuse `/tc/groupes` à l'enseignant, le seul rôle visé | R4 n° 25 ; revérifié `redirection.dart:134-137` (élève et tuteur seulement) | utile | chantier **Enseignant** | non |
| 15 | **Seconde salle « Classe Live »** (`/tc/classe`) et l'annonce « un tuteur observe » qu'elle porte | Enseignant, élève | `main` | Seule entrée dans l'Espace Groupe, inaccessible aux rôles admis ; deux salles coexistent | R4 n° 8 et 24 ; `CLAUDE.md:69-71` | **doublon** de `/salle` | arbitrage du directeur dans un chantier **Salle** (une seule salle) ; ne pas développer les deux | non |
| 16 | **Porte d'observation** (`/tc/observation/:id`) | Tuteur, admin, contrôleur | `main` | Aucun appelant ; « Assister » envoie encore vers `/salle` | R4 n° 48 ; revérifié : `routes_tc_g.dart:21` sans appelant, aveu en commentaire `entete_classe.dart:199` | utile | tuteur : chantier **Tuteur** (déjà repris, n° 27) ; admin et contrôleur : leurs chantiers | non |
| 17 | **Lecteur du Coran en double** (`/tc/mushaf`) | Élève | `main` | Aucune entrée ; même écran que `/eleve/coran` | R4 n° 9 | **doublon** | **abandonner** cette adresse (garder `/eleve/coran`), après accord | non |
| 18 | **Suivi élève en interface guidée** | Élève | `main` | En interface guidée, la barre de navigation n'a aucune destination | R4 n° 3 (`nav_shell.dart:55-56`) | utile | chantier **Élève** | non |

### C. Sur `main`, code présent mais jamais affiché, ou fonction absente

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 19 | **Indicateur « on t'observe » côté enfant** | Élève | `main` (défini, jamais utilisé) ; utilisé dans `ui/tuteur-v1` | Jamais posé dans un écran sur `main` | revérifié : sur `4a7aa2b`, définition seule (`indicateur_observation.dart:131-133`) ; sur `436c290` posé dans `salle_page.dart:510` et `entete_classe.dart:220` | utile | chantier **Tuteur** (déjà repris, fermé hors développement, n° 27) | non |
| 20 | **La page du Coran présentée par l'enseignant, vue par l'élève** | Élève | côté élève : **n'existe nulle part** hors CORE24 | Aucun écran élève ne reçoit la page ; l'enseignant tourne des pages que personne ne voit | revérifié `git grep contenusPresentes 4a7aa2b -- lib` : seul lecteur `salle_enseignant/presentation_coran.dart:55` | utile, essentiel | chantier **Salle** (avec le n° 2) | - |
| 21 | **Suivi de la classe dans le lecteur du Coran** | Élève | `main` | Le paramètre de séance n'est jamais transmis | R4 n° 10 | utile | chantier **Salle** | non |
| 22 | **Page de correction de présence** (propriétaire) | Admin, enseignant | `main` (`PresenceCorrectionPage`) | Jamais affichée ; un panneau équivalent est dans le cahier de l'enseignant | R4 n° 30 | doublon partiel | **conserver en archive** ; décider dans le chantier **Administration** | non |
| 23 | **Le Coran hors salle pour l'enseignant** | Enseignant | n'existe pas | Aucune destination ; la porte d'accès lui refuse `/eleve` et `/tc/mushaf` | R4 n° 23 | **manque** | chantier **Enseignant** | - |

### D. Sur `main`, branché, mais absent de l'application en ligne

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 24 | **Parcours de personnalisation et de choix d'horaire** (commit `4a7aa2b`, 5 864 lignes, dont la migration `0043_offres_horaires_et_intentions.sql` de 1 357 lignes) | Tuteur | `main`, branché (bloc posé sur l'accueil famille) | **Jamais déployé** : le fichier servi en ligne date du 21/09 06:17 GMT, avant ce commit du 22/09 ; le déploiement automatique n'avait pas ses secrets avant le 24/09 (`CLAUDE.md:38-40`, checkout C0) | revérifié : `main.dart.js` de `rewayah-academy.vercel.app` (SHA-256 `CA9B877A…68571`, identique à R1) ne contient aucun de ses textes (« Personnaliser le parcours » : 0), alors que 8 textes plus anciens y sont (1 à 3 fois chacun) ; `git log main --first-parent --since=2026-09-21T06:17:02Z` = `4a7aa2b` seul ; `main:.github/workflows/flutter-deploy.yml:10-14` décrit la production tenue « à la main » du 18 au 21/09 | utile | chantier **Tuteur** (déjà dans la base de `ui/tuteur-v1`, fichiers atteignables sur `436c290`) ; vérifier en production la migration `0043_offres…` | non |

### E. Sur des branches jamais fusionnées dans `main`

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 25 | **Vraies classes et horloge serveur** au lieu des groupes de démonstration (V0) | Tuteur, élève | branche `v0/verite-produit` (`33503fe`) ; repris dans `ui/tuteur-v1` (`b6df316`) | Jamais fusionné ; `main` sert toujours des groupes inventés | R2 §4.1 ; revérifié `main:lib/core/tc_groupe/port_groupes.dart:37-39` | utile, **bloquant** pour de vrais élèves (`08:5`) | chantier **Tuteur** (fait dans le code, à fusionner avec le lot) | non (branche sur GitHub) |
| 26 | **Trois libellés « le cours n'est pas enregistré »** (V0) | Tous | `33503fe` seulement | Volontairement non repris par `b6df316` : le chantier Tuteur affiche toujours « Cours enregistré, visite de contrôle possible. » | revérifié `git grep` sur `436c290` : `fr.i18n.json:136` et `:1694` ; `08:5` : anomalie « cours enregistré » bloquante | utile, **bloquant** | **décision du directeur**, puis chantier **Tuteur** | non |
| 27 | **Observation par le tuteur**, partie écran (20 fichiers) | Tuteur, enseignant, enfant | branche `observation/lot-2026-09-21` ; repris dans `ui/tuteur-v1` (`0401086`) | Jamais fusionné ; dans le chantier Tuteur, **volontairement fermé hors développement** (`db52be5`) tant que le serveur n'est pas prêt | R2 §4.2 ; revérifié `436c290:lib/core/config/env.dart:46-54, 76-79` | utile | chantier **Tuteur** ; le dire « présent, désactivé », jamais « fait » | non |
| 28 | **Observation, partie serveur** (migrations `0039` à `0042`) | Serveur | branche `observation/lot-2026-09-21` (et `astra/*`) | Absentes de `main`, de C0 et du chantier Tuteur ; dites appliquées en production (non vérifié) | revérifié `git ls-tree` : 4 fichiers sur `0bfc9e4`, 0 sur `4a7aa2b`, `3cf3544`, `436c290` | utile | **lot serveur dédié** (hors chantier Tuteur), après lecture de la base | non (branche sur GitHub) |
| 29 | **CORE24** : classes V2, KYC V2, salle unique, remplacement d'enseignant, dispatch (6 branches) | Tous | `core24/fable-frontend`, `integration/core24-classes-v2(-remediation)`, `astra/core24-*` | Déclaré **non conforme** par le directeur ; jamais fusionné | R2 §4.4 ; `08:27` | **non conforme** | **conserver en archive**, ne pas intégrer ni copier | **oui**, en cas de perte du disque D: : 5 des 6 branches n'ont jamais été poussées (R2 §3, R3 §7) |
| 30 | Anciens lots Codex du 13-15/09 (thème adaptatif, coquille, connexion de démonstration, correction de présence) | - | `codex/*` (5 branches) | Remplacés dans `main` par recopie | R2 §4.3 (mesure ligne à ligne) | **obsolète** | **abandonner**, après accord | non |
| 31 | Documents : décision « badges à cinq niveaux », docs normatives du Teaching Core, arbitrage CORE24 | Direction | `lot/onboarding-offres`, `teaching-core/0-coordinateur`, `docs/core24-classes-arbitration` | Documents seulement, jamais repris dans `docs/current` | R2 §4.5 | utile (badges), historique (le reste) | badges : intégrer aux docs de C0 ; le reste : archive | non (sauf `docs/core24-classes-arbitration`, jamais poussée) |

### F. Hors du dépôt principal, ou jamais enregistré dans Git

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 32 | **Audit de préproduction du 15/09** (1 553 lignes) + **2 tests de sécurité de la clé Supabase** absents de `main` | Sécurité | 2 commits `ca43141` et `79c0fad`, **seulement** dans la copie isolée `C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-release-20260915` (et son worktree `rewayah-audit-20260915`) | Jamais rapatriés dans le dépôt principal ni sur GitHub | revérifié : `git -C <clone> log` et `show --stat` ; `git -C "D:\RA _APP\RA -OFFICIAL-APP" cat-file -e` échoue pour les deux ; `A_VALIDER_retirer_worktrees.ps1:19-23` supprime ces deux dossiers ; `JOURNAL_ARCHIVAGE.txt` : « clone-audit-20260915 : 0 fichier(s) archive(s) » | utile (preuve d'audit + 2 tests) | **sauvegarder d'abord** (§3), puis archive ; tests : chantier sécurité | **OUI, élevé** |
| 33 | **Audit de conformité CORE24** (le document qui fonde le verdict « non conforme ») | Direction | fichier non committé `...\WindowsTerminal\rewayah-classes-v2\CORE24_CLASSES_COMPLIANCE_AUDIT.md` | Jamais enregistré dans Git, absent de l'archive | revérifié : `git status` = `??` ; 337 lignes, 35 147 octets, 22/09 21:35 ; son contenu (blob `639cdc8`) n'existe dans aucune branche ; aucune copie sous `D:\RA _APP\_archive` ; cité par `integration/core24-classes-v2-remediation:CORE24_CLASSES_REMEDIATION_REPORT.md` | utile | **sauvegarder** (§3), conserver en archive | **OUI, moyen** |
| 34 | **Correctif d'urgence du jeton vidéo** (`0043_autoriser_jeton_video_verifie_le_bon_compte.sql`) | Serveur, salle | fichier non committé dans `D:\RA_OBS` + copie identique dans `_archive` | Jamais committé ; son numéro `0043` est **déjà pris** sur `main` par `0043_offres_horaires_et_intentions.sql` | revérifié : SHA-256 `864D7594…` identiques ; lignes 1-11 : `0042` « refusait donc TOUT jeton video » (affirmation du fichier, non vérifiée en base) | utile, urgent si la cause est vraie | **lot serveur** : lire la base, puis renuméroter | faible (2 copies, même disque D:, hors Git) |

### G. Chantier Tuteur en cours (`ui/tuteur-v1`)

| # | Module | Rôle | Où il se trouve | Pourquoi il n'est pas visible | Preuve | Valeur | Recommandation | Risque de perte |
|---|---|---|---|---|---|---|---|---|
| 35 | **Le chantier Tuteur lui-même** (40 commits au-dessus de `main` à `436c290`) | Tuteur | branche **locale** `ui/tuteur-v1` (worktree `D:\RA_TUTEUR\integration`, non lu) | Pas publiée, pas fusionnée : rien n'est en ligne, **c'est normal à ce stade** | revérifié : aucune référence `origin/ui*` ; `git rev-list --count 4a7aa2b..436c290` = 40 ; frontière serveur respectée (`git diff --stat 3cf3544...436c290 -- supabase .github vercel.json .firebaserc dart_define.example.json` vide) | utile | poursuivre ; sauvegarde hors disque D: (§3) | **OUI** (un seul exemplaire, disque D:) |
| 36 | **Contrats du chantier Tuteur pas encore branchés** (21 fichiers : ports des capacités du foyer, création de profil élève, séances du foyer, disponibilité et historique de l'observation) | Tuteur | `ui/tuteur-v1` @ `436c290` | Écrits et testés, pas encore reliés à l'application. Aucun des 45 fichiers du bloc A n'y est branché non plus | revérifié : `graphe_imports.ps1 -Ref 436c290` = 66 fichiers non atteignables = les 45 de `main` + 21 nouveaux (dont `disponibilites_page.dart` et `ecran_a_construire.dart`, débranchés volontairement : `app_router.dart:365-370`) | utile (en cours) | chantier **Tuteur actuel** : ne dire « fait » qu'avec la preuve du §5 bis | oui (idem n° 35) |

**36 lignes.**

---

## 3. Travaux à risque de perte, et sauvegarde recommandée (NON exécutée)

Chaque commande ci-dessous **écrit** un fichier : elle attend l'accord explicite du directeur. Aucune ne modifie les dépôts sources (un `git bundle create` lit le dépôt et produit un fichier ailleurs). Elles n'envoient rien sur GitHub et ne déploient rien.

| Priorité | Ce qui peut être perdu | Pourquoi | Sauvegarde recommandée |
|---|---|---|---|
| **1** | Audit de préproduction + 2 tests (n° 32) | Un seul exemplaire, dans une copie que le script `A_VALIDER_retirer_worktrees.ps1` efface (lignes 19-23, `Remove-Item -Recurse -Force`) alors que `BRANCHES_A_VALIDER.md:57` le dit sûr (R3) | a) **Ne pas lancer ce script** ; retirer `rewayah-release-20260915` et `rewayah-audit-20260915` de sa ligne 19. b) `git -C "C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-release-20260915" bundle create "D:\RA _APP\_archive\2026-09-24_sauvegardes\audit-preproduction-20260915.bundle" codex/audit-preproduction-20260915` (après `New-Item -ItemType Directory -Force` du dossier). c) Contrôle : `git bundle verify <fichier>` doit citer `79c0fad`. |
| **2** | Audit de conformité CORE24 (n° 33) | Fichier jamais committé, aucune copie | `New-Item -ItemType Directory -Force "D:\RA _APP\_archive\2026-09-23_worktrees\classes-v2"` puis `Copy-Item "C:\Users\dell\AppData\Local\Programs\WindowsTerminal\rewayah-classes-v2\CORE24_CLASSES_COMPLIANCE_AUDIT.md" "D:\RA _APP\_archive\2026-09-23_worktrees\classes-v2\"` ; contrôle par `Get-FileHash` (les deux empreintes doivent être égales). |
| **3** | Chantier Tuteur (40 commits), 5 branches CORE24, `docs/core24-classes-arbitration`, lots `codex/*` locaux, et le commit `5113656` de C0 (1 ligne dans `08`) | N'existent que dans `D:\RA _APP\RA -OFFICIAL-APP\.git` (R2 §3, R3 §7) | Un fichier unique, **sur un autre disque que D:** : `git -C "D:\RA _APP\RA -OFFICIAL-APP" bundle create "C:\Users\dell\Sauvegardes_Rewayah\rewayah-toutes-branches-2026-09-24.bundle" --all` ; à refaire chaque soir tant que le chantier Tuteur avance. Pousser `ui/tuteur-v1` sur GitHub serait une seconde copie ; selon `main:.github/workflows/flutter-deploy.yml:19-22`, un push d'une autre branche que `main` ne déclenche pas le déploiement, mais le BRIEF l'interdit sans accord. |
| 4 | Correctif `0043` du jeton vidéo (n° 34) | Deux copies, même disque, hors Git | `Copy-Item "D:\RA_OBS\supabase\migrations\0043_autoriser_jeton_video_verifie_le_bon_compte.sql" "C:\Users\dell\Sauvegardes_Rewayah\"` |
| 5 | Outils de protection locaux `.claude\hooks\secret-scanner.py` et `.claude\settings.local.json` (pas du code de l'application) | Non suivis par Git, non archivés (R3 §3.1) | `Copy-Item -Recurse "D:\RA _APP\RA -OFFICIAL-APP\.claude" "C:\Users\dell\Sauvegardes_Rewayah\claude-local"` |

**Rien à sauver dans les 3 stashes** (revérifié §6 n° 18-19) : `stash@{0}` est vide, `stash@{1}` a 10 fichiers sur 11 déjà dans l'historique de `main` (le 11e ajoute `livekit_client: ^2.12.0`, déjà présent sur `main`), `stash@{2}` a 9 fichiers sur 9 dans l'historique de `main`.

**Rien à sauver non plus dans les 15 autres worktrees sales** : leur contenu est déjà dans un commit ou dans l'archive du 23/09, vérifié fichier par fichier par R3 (§3, §6). Je n'ai revérifié moi-même que `0043` (n° 34).

---

## 4. « Coran lu à l'envers »

### Diagnostic (prouvé)

Sur chaque page, les versets arrivent **du dernier au premier**. L'écran les pose dans l'ordre reçu : le dernier verset en haut, le premier en bas. Pour lire dans l'ordre, il faut partir du bas et remonter. **Constat simple** : à la page 1 (Al-Fatiha), la basmala apparaît en bas et le verset 7 en haut.

Cause : la requête qui lit les versets d'une page demande un tri **sans préciser le sens**. La bibliothèque utilisée (`postgrest` 2.9.1) trie alors en **décroissant**, à l'inverse du SQL habituel.

| Maillon | Fichier:ligne | Constat |
|---|---|---|
| Requête des versets d'une page | `lib/core/coran/service_coran.dart:324-330` (`main` @ `4a7aa2b`) | `.order('sourate_numero').order('numero')`, **sans `ascending: true`** (revérifié) |
| Comportement de la bibliothèque | `%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\postgrest-2.9.1\lib\src\postgrest_transform_builder.dart:102-115`, doc lignes 71-73 | `bool ascending = false` ; construit `colonne.desc` ; la doc écrit « results come back in descending order unless ascending: true is passed » (revérifié) |
| Version verrouillée | `main:pubspec.lock` | `postgrest` `2.9.1`, sha256 `b7f95727…9a21` (revérifié) |
| **Dans l'application en ligne** | `main.dart.js` servi par `rewayah-academy.vercel.app` (SHA-256 `CA9B877A…68571`) | la requête compilée est `.o2(0,"sourate_numero").o2(0,"numero")`, et `o2(a,b){return this.BH(0,b,!1)}` avec `p=c?"asc":"desc"` : **« desc » est bien envoyé en production**. Témoin : la liste d'attente, écrite avec `ascending: true`, est compilée `.BH(0,"depuis",!0)` (revérifié, preuve nouvelle par rapport à R4) |
| Aucun retri côté écran | `lib/core/coran`, `lib/core/tc_coran`, `lib/features/tc_mushaf` | `git grep` de `.sort(`, `reversed`, `compareTo` : 0 résultat ; le découpage `vue_lecteur.dart:194-201` garde l'ordre reçu ; la mise en page « fidèle » qui pourrait imposer un autre ordre est désactivée (`layout_lignes_indisponible.dart:51-52`) (revérifié) |
| Depuis quand | `git blame -L 324,331 4a7aa2b -- lib/core/coran/service_coran.dart` | commit `090ae6f`, **13/09**, jamais modifié depuis (revérifié) |
| Toujours dans le chantier Tuteur | `ui/tuteur-v1` @ `436c290`, même fichier, mêmes lignes | inchangé (revérifié) |

### Fichiers en cause et effets associés

- `lib/core/coran/service_coran.dart:324-330` : ordre des versets d'une page (défaut principal). Utilisé par le lecteur de l'élève (`/eleve/coran`) et, via `pageCoranProvider` (`:486-489`), par le panneau que l'enseignant présente en salle (R4 §5.3).
- `lib/core/coran/service_coran.dart:306-309` : liste des sourates en ordre décroissant (la recherche par nom propose d'abord les numéros élevés, R4).
- `lib/core/coran/service_coran.dart:454-461` : la **recherche** d'un mot trie aussi en décroissant puis garde 50 résultats (`.limit(limite)`, `limite = 50`) : elle renvoie donc les **50 dernières** occurrences du Coran, pas les 50 premières (déduit du code, constat nouveau, non observé à l'écran).
- `lib/core/coran/vue_lecteur.dart:189` : le titre d'une sourate qui commence sur la page n'est pas posé, car le test `courants.first.numero == 1` lit le **dernier** verset (revérifié à la lecture).
- Effets relevés par R4 et non revérifiés par moi : titre d'écran faux sur une page à plusieurs sourates (`mushaf_page.dart:208-210`), marque-page décalé (`vue_verset_agrandi.dart:288-298`), mode « verset agrandi » à l'envers.
- Le piège était connu : `lib/core/matching/service_matching.dart:199-205` (« `order()` de postgrest trie en DESCENDANT quand on ne dit rien ») (revérifié). Aucun test ne lit la vraie requête (R4 §5.4).
- Seconde cause, plus faible, possible pour la « marche arrière » d'une page à l'autre : le geste de glissement et les boutons « Page précédente / suivante » vont en sens contraires (R4 §5.5, non revérifié).

### Correction (information seulement, rien n'a été modifié)

Ajouter `ascending: true` aux lignes `service_coran.dart:309, 329, 330, 459, 460`, et un test qui lit l'adresse réellement envoyée (script de R4 §8). Même défaut possible ailleurs : 11 autres appels `.order(...)` sans sens écrit (appareils, séances, créneaux, offres), effet à l'écran non mesuré (R4 §6). Ce doit être un **lot explicite**, décidé par le directeur.

---

## 5. Ce que ce registre ne couvre pas

- **Aucune application lancée, aucun test exécuté, aucune capture d'écran.** « Atteignable » veut dire qu'un bouton existe dans le code, pas que l'écran fonctionne. Les chiffres de tests (« 1 762 tests verts », `08:27`) restent des affirmations.
- **Aucune lecture de la base de production.** Restent INCONNUS : les migrations réellement appliquées (`0039`-`0042`, `0043_offres…`), l'existence des tables du Teaching Core, et la réalité de la panne du jeton vidéo décrite par le correctif `0043`.
- **Production** : seul le domaine `rewayah-academy.vercel.app` a été vérifié. Le commit exact de la version en ligne est INCONNU (fichier daté du 21/09 06:17 GMT, sans identifiant de commit). Un autre domaine de production éventuel n'a pas été contrôlé.
- **Chantier Tuteur** : `D:\RA_TUTEUR\*` n'a pas été lu. La branche `ui/tuteur-v1` n'est vue qu'à travers Git, à `436c290` ; elle avance pendant ce relevé. Le rôle Tuteur n'est pas refait par R4 (voir `02_code\00_MAPPING_ROUTES.md`).
- **Annonces** : R4 a lu une sélection de documents (`HANDOFF.md` et le catalogue d'écrans par sections, certains rapports d'agents par recherche ciblée). Une fonction annoncée ailleurs (conversation, message, autre document) peut manquer.
- **Copies du projet** : recherchées sur `D:\` et `...\WindowsTerminal`, sur 3 niveaux de dossiers. `C:\Users\dell\.gemini\`, OneDrive et le reste de `C:` n'ont pas été parcourus (R3 §9).
- **Méthodes approchées** : la comparaison ligne à ligne de R2 dit « repris » ou « absent », pas « se comporte pareil » ; la recherche de textes dans le fichier en ligne confirme le graphe d'imports, elle ne le remplace pas.
- **Revérification partielle** : j'ai rejoué 27 contrôles (§6). Les autres affirmations des quatre relevés sont reprises avec leur source, sans contrôle de ma part.
- **Commentaires du directeur** : les commentaires ajoutés sur le document artefact n'ont pas été lus par cet agent (hors de sa tâche). Ce registre ne les intègre pas.

---

## 5 bis. Règle de preuve proposée pour éviter un nouveau « c'est fait »

Une fonction n'est « faite » que si les trois preuves sont jointes : (1) son fichier est atteignable depuis `lib/main.dart` (`graphe_imports.ps1 -Ref <commit>`) ; (2) un bouton ou un onglet y mène, trouvé par `git grep` hors routeur et hors tests ; (3) après déploiement, un de ses textes est présent dans le `main.dart.js` servi en ligne. Un test qui appelle `routeur.go(...)` ne compte pas comme preuve d'accès.

---

## 6. Revérifications faites pour ce registre (lecture seule)

| n° | Affirmation contrôlée | Commande / fichier | Résultat |
|---|---|---|---|
| 1 | Références | `git rev-parse main origin/main c0/… origin/c0/… ui/tuteur-v1` | `4a7aa2b` = `4a7aa2b` ; C0 local `5113656`, distant `3cf3544` ; `ui/tuteur-v1` = `436c290` (a bougé depuis R2) |
| 2 | 45 fichiers non branchés (R1) | `graphe_imports.ps1 -Ref 4a7aa2b -OutDir <scratchpad>` | 346 / 301 / **45**, 7 551 lignes ; liste des atteignables identique à celle de R1 (0 écart) |
| 3 | Racines sans importeur (R1) | `git grep` des directives `import/export/part` visant `teaching_dock`, `panneau_post_cours`, `barre_cours_en_cours`, `bloc_avant_prochain_cours`, `class_library_picker` | 0 importeur chacun |
| 4 | Transport indisponible (R1) | `git show 4a7aa2b:lib/core/tc_realtime/providers_tc_realtime.dart` | lignes 25-26 confirmées |
| 5 | Annotations en erreur volontaire (R1) | `git show 4a7aa2b:lib/core/tc_outils/port_annotations.dart` | lignes 211-217 confirmées |
| 6 | Le chantier Tuteur ne branche aucun des 45 | `graphe_imports.ps1 -Ref 436c290` | 66 non atteignables : les 45 + 21 nouveaux (constat nouveau) |
| 7 | Bienvenue enseignant sans bouton (R4) | `git grep enseignantBienvenue 4a7aa2b -- lib` | 2 lignes, déclaration seulement |
| 8 | Porte d'observation sans appelant (R4) | `git grep -E "versObservation\|tcObservation" 4a7aa2b -- lib` | définitions et un commentaire, aucun appel |
| 9 | Indicateur enfant jamais posé (R4) | `git grep IndicateurObservationEnfant` sur `4a7aa2b` et `436c290` | `main` : définition seule ; `ui` : posé 2 fois |
| 10 | Page présentée non reçue par l'élève (R4) | `git grep contenusPresentes 4a7aa2b -- lib` | seul consommateur côté enseignant |
| 11 | Porte `/tc/*` par rôle (R4) | `git show 4a7aa2b:lib/core/router/redirection.dart` | lignes 133-150 confirmées |
| 12 | Groupes de démonstration sur `main` (R2, R4) | `git show 4a7aa2b:lib/core/tc_groupe/port_groupes.dart` | ligne 38 `GroupesDemonstrationLocale()` |
| 13 | Observation fermée hors développement (R2) | `git show 436c290:lib/core/config/env.dart` | lignes 76-79 `demandee && environnement == 'developpement'` |
| 14 | Libellé « Cours enregistré » dans le chantier Tuteur (R2) | `git grep` sur `436c290 -- assets/i18n/fr.i18n.json` | lignes 136 et 1694 |
| 15 | Migrations `0039`-`0042` absentes (R2) | `git ls-tree` sur 4 références | 4 sur la branche d'observation, 0 ailleurs ; `0043_offres…` déjà sur `main` (collision de numéro, constat nouveau) |
| 16 | Deux commits seulement dans le clone (R3) | `git -C <clone> log/show --stat` ; `git cat-file -e` dans le dépôt principal | confirmés, absents du dépôt principal ; le clone n'a aucun stash |
| 17 | Script de suppression dangereux (R3) | lecture de `A_VALIDER_retirer_worktrees.ps1` et `JOURNAL_ARCHIVAGE.txt` | lignes 19-23 confirmées ; « clone-audit-20260915 : 0 fichier(s) archive(s) » |
| 18 | Audit CORE24 non committé (R3) | `git status` du worktree, `hash-object` sans écriture, `cat-file -e`, recherche dans `_archive` | non suivi, blob absent, aucune copie |
| 19 | Stashes sans contenu unique (R3) | `git diff-tree`, `stash show --stat`, blobs contre `git rev-list --objects main` | `{0}` vide ; `{1}` 10/11 ; `{2}` 9/9 |
| 20 | Correctif `0043` archivé à l'identique (R3) | `Get-FileHash` des deux copies | identiques (`864D7594…`) |
| 21 | Commit `5113656` non poussé (R2, R3) | `git log origin/c0/…..c0/…` ; `git show -s` | 1 commit, 24/09 15:25:37, 1 ligne dans `08`, compte `rewayahacademy-glitch` |
| 22 | Fichier en ligne (R1) | `Invoke-WebRequest …/main.dart.js` (copie dans le scratchpad) | HTTP 200, 5 313 881 octets, SHA-256 identique à R1, `Last-Modified` 21/09 06:17:02 GMT |
| 23 | Textes du bloc A absents en ligne (R1) | recherche dans ce fichier | `tc.outils.pointeur`, `tc.etat_partage.revision`, texte d'erreur des annotations : 0 |
| 24 | Parcours d'horaire absent en ligne (nouveau) | recherche de 6 textes de `4a7aa2b` ; contrôle sur 8 textes antérieurs | 0 pour les 6 ; 1 à 3 pour chacun des 8 témoins |
| 25 | Requête du Coran et sens par défaut (R4) | `git show`/`blame` de `service_coran.dart` ; lecture de `postgrest_transform_builder.dart` ; `pubspec.lock` | confirmés (§4) |
| 26 | Requête du Coran compilée en « desc » en ligne (nouveau) | recherche de `sourate_numero`, `o2(`, `BH(` dans le fichier en ligne | `.o2(0,"sourate_numero").o2(0,"numero")` → `!1` → `desc` |
| 27 | Aucun retri côté écran (R4) | `git grep -E "\.sort\(\|sorted\|reversed\|compareTo"` sur les dossiers du Coran ; `layout_lignes_indisponible.dart:51-52` | 0 ; mise en page fidèle désactivée |

Écarts relevés entre les relevés et mes contrôles : l'audit CORE24 compte 337 lignes (R3 : 336) ; le chantier Tuteur compte 40 commits à `436c290` (R2 : 39 à `f075a7e`) ; R2 présente `main` comme « = production selon `CLAUDE.md` », ce que le fichier en ligne dément pour le commit `4a7aa2b`. Aucun écart sur le fond.
