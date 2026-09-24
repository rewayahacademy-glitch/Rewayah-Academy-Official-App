# Démarrer le poste B (second ordinateur)

## Étape 1 : installer Claude Code (toi, 2 minutes)

Ouvre **PowerShell** (touche Windows, tape « PowerShell », Entrée), colle cette ligne, Entrée :

```
irm https://claude.ai/install.ps1 | iex
```

Ferme PowerShell, rouvre-le, tape `claude`, Entrée, et connecte-toi avec **le même compte** que sur le premier ordinateur.

## Étape 2 : coller ce prompt dans Claude Code

```
ultracode Tu es le POSTE B du chantier frontend Tuteur V1 de Rewayah Academy (Flutter). Un autre ordinateur, le POSTE A, est le coordinateur : il travaille en même temps sur les lots C, E et O. Toi, tu fais les lots B (Foyer), puis D (Appareils), puis A (Admission). Les deux postes ne communiquent QUE par GitHub (dépôt https://github.com/rewayahacademy-glitch/Rewayah-Academy-Official-App.git) et par le tableau de suivi https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU (outil ArtifactData, collection "etapes").

1. INSTALLATION (coche PB-01 à PB-03 dans le tableau au fur et à mesure) :
   - Git : winget install --id Git.Git -e --source winget ; puis git config --global user.name "rewayahacademy-glitch" et git config --global user.email "rewayahacademy@gmail.com".
   - Flutter EXACTEMENT 3.47.2 stable (révision d3b14c876900e553bc736ca19295fc09e3853e8e) dans C:\flutter : télécharge https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.2-stable.zip, extrais dans C:\, ajoute C:\flutter\bin au PATH utilisateur, lance flutter --version (doit afficher 3.47.2 / Dart 3.13.2) et flutter doctor.
   - git clone du dépôt dans C:\RA\depot (si GitHub demande une connexion, dis-moi exactement quoi faire) ; git -C C:\RA\depot fetch origin ui/tuteur-v1 pilotage/tuteur-v1 ; git -C C:\RA\depot checkout ui/tuteur-v1 ; git -C C:\RA\depot worktree add C:\RA\pilotage pilotage/tuteur-v1 ; flutter pub get dans C:\RA\depot.
2. LECTURE (coche PB-04) : C:\RA\pilotage\COORDINATION.md EN ENTIER (canal, chemins du poste B, fichiers que tu as le droit d'écrire, interdits), puis ETAT_A.md, 05_LOTS_PHASE1.md (§0 et sections B, D, A), 03_DECISIONS_COORDINATEUR.md (les §1 bis, 1 ter, 1 ter bis PRIMENT), BRIEF.md. Tous les chemins D:\... des documents se traduisent avec le tableau « Chemins sur le poste B » de COORDINATION.md. Vérifie que tu peux écrire dans le tableau de suivi (update de PB-04).
3. EXÉCUTION : lance UN workflow qui traite les lots dans l'ordre B, D, A (deux lots en parallèle au plus : cette machine a 16 Go). Pour chaque lot : worktree C:\RA\lot-<x> sur une nouvelle branche ui/tuteur-v1-<x> issue de origin/ui/tuteur-v1 ; un agent par sous-paquet, EN SÉQUENCE, chacun marque sa ligne du tableau « en_cours » puis « fait » avec la preuve (hash de commit) ; puis un agent de revue indépendante adversariale (fidélité aux maquettes, carte des fonctions sans doublon, honnêteté, accessibilité, frontière) ; puis un agent de correction ; après chaque sous-paquet et en fin de lot : git push de la branche du lot, mise à jour de etat/B.md et push de pilotage/tuteur-v1 (git pull --rebase avant). Les agents appliquent strictement le §0 de 05_LOTS_PHASE1.md et la définition de « fait » (bouton touché par un test, captures maquette | rendu).
4. RÈGLES : plan fermé, aucune étape hors du tableau sans ligne HL-B-<n> et son motif ; jamais de push vers main, de merge dans main, de PR, de migration, de modification de supabase/, .github/, pubspec.yaml, lib/core/theme, lib/core/router, lib/core/widgets, ni des fichiers du Coran ; jamais de secret affiché ou commité. Commandes Flutter lourdes via C:\RA\pilotage\outils\flutter-verrou.ps1. Toutes les 30 minutes : git -C C:\RA\pilotage pull --rebase et lis ETAT_A.md (nouvelle base à fusionner, réponses aux demandes).
Commence maintenant par l'installation. Réponds-moi en français, brièvement, à chaque étape franchie.
```

## Ce que tu surveilles

Le tableau https://claude.ai/artifact/XMVyZJiLTcmMKTnhsbp3sU : les cases se cochent au fil des étapes, sur les deux postes.
