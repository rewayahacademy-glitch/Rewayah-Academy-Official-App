# Reprise du chantier frontend Tuteur V1 (à lire en premier après un /clear ou une nouvelle session)

Mis à jour : 24/09/2026.

## Où en est le chantier
- Lot 0 inventaire : TERMINÉ. Manifeste visuel `01_visuel/00_MANIFESTE.md` ; cartographie `02_code/00_MAPPING_ROUTES.md`, `00_CONTRATS_PARTAGES.md`, `00_OWNERSHIP.md`, `00_DEPENDANCES_BACKEND.md`, `00_CONTRADICTIONS.md` (+ rapports détaillés `02_code/C01..C11`).
- Décisions du coordinateur et RÉPONSES DU DIRECTEUR : `03_DECISIONS_COORDINATEUR.md` (le §1 bis prime).
- Phase 0 (fondations) : workflow `tuteur-v1-phase0-fondations`, run `wf_ab30aa4b-e67`, lancé le 24/09. Rapports dans `04_phase0/` (0a_base, 0b_jetons, 0d_contrats, 0c1_composants, 0c2_coquille_routeur, revue_*, 0e_corrections, 0f_verification). Vérifier ce qui existe avant de relancer quoi que ce soit.
- Git : worktree d'intégration `D:\RA_TUTEUR\integration`, branche locale `ui/tuteur-v1` (base `3cf3544`, branche C0). Worktree de contrats `D:\RA_TUTEUR\p0d`, branche `ui/tuteur-v1-p0d` (fusionnée par l'étape 0c1). AUCUN push, aucune PR, aucun merge main.

## Contrôle à faire à la reprise
1. `git -C D:\RA_TUTEUR\integration log --oneline 3cf3544..HEAD` et `git status` : quelles étapes de phase 0 ont committé.
2. Lire les rapports présents dans `04_phase0/`.
3. Vérifier que `salle.bandeauPermanent` vaut « Cours enregistré, visite de contrôle possible. » dans `assets/i18n/fr.i18n.json` du worktree d'intégration (la reprise de `33503fe` l'avait changé à tort ; directeur : l'audio est réellement enregistré sur R2). Idem `contrat.pointEnregistrement`, `enseignant.profil.contratAccuse` = valeurs de `3cf3544`.
4. Frontière : `git diff --stat 3cf3544...HEAD -- supabase .github vercel.json web/vercel.json .firebaserc` vide.
5. Si la phase 0 est incomplète : terminer les étapes manquantes (le script est `C:\Users\dell\.claude\projects\C--Users-dell-AppData-Local-Programs-WindowsTerminal\fdb7e1de-cc9a-4b71-bb67-78d8572a5917\workflows\scripts\tuteur-v1-phase0-fondations-wf_ab30aa4b-e67.js`).

## Étapes suivantes prévues
- Phase 1 : six lots en worktrees `D:\RA_TUTEUR\lot-<a|b|c|cobs|d|e>` (branches `ui/tuteur-v1-<lot>` issues de `ui/tuteur-v1`), découpés en sous-parcours (A Admission 4 paquets, B Foyer 2, C Cours 3, C-obs Observation 3, D Appareils 3, E Compte/Historique 3), chacun suivi d'une revue indépendante (fidélité high-fi + honnêteté/sécurité) et d'une correction. Deux workflows en parallèle (cap 2 agents chacun, machine 4 cœurs / 7,9 Go).
- Phase 2 : intégration des branches de lot dans `ui/tuteur-v1` (union des espaces i18n, régénération), mode démonstration tuteur isolé pour l'aperçu, revues Q (fidélité, parcours/routes, responsive/a11y, frontière sécurité), corrections, vérification complète, captures comparatives, matrice de recette, rapport au directeur.

## Engagements pris auprès du directeur (audit « Rewayah — Audit de méthode », 24/09)
- Phase 1 : commencer par les lots qui ont des high-fi (C Cours, E Compte/Historique, C-obs Observation), puis A, B, D.
- Publier les captures maquette/rendu de chaque lot dans `05_recette/` dès qu'elles existent, sans attendre la fin, pour validation au fil de l'eau.
- Un lot « Backend T1 » (supabase/ et .github/ci.yml seulement, worktree `D:\RA_BACKEND_T1`, branche `backend/tuteur-t1`) peut tourner en parallèle dans une autre session : ne jamais toucher ces chemins depuis ce chantier.

## Registre du code non livré (24/09) et sauvegardes
- Registre : `06_registre/00_REGISTRE.md` (36 lignes, 27 revérifications) ; onglet « Registre du code non livré » du document directeur.
- Sauvegardes FAITES et vérifiées : `D:\RA _APP\_archive\2026-09-24_sauvegardes\audit-preproduction-20260915.bundle` ; audit CORE24 copié dans `_archive\2026-09-23_worktrees\classes-v2\` ; `C:\Users\dell\Sauvegardes_Rewayah\` (bundle audit, audit CORE24, correctif 0043 jeton vidéo, `claude-local`, `rewayah-toutes-branches-2026-09-24.bundle` 7,5 Mo / 99 refs). À refaire chaque soir tant que le chantier avance.
- NE PAS lancer `A_VALIDER_retirer_worktrees.ps1` tel quel.
- Coran à l'envers : `lib/core/coran/service_coran.dart:309, 329, 330, 459, 460` sans `ascending: true` (postgrest trie en décroissant par défaut). Mini-lot proposé au directeur (en attente de son accord).
- Commit `5113656` sur C0 = alertes de sécurité dans `08`, fait par le coordinateur à la demande du directeur.

## Règles permanentes
- Commandes Flutter lourdes via `outils/flutter-verrou.ps1` (verrou système).
- Aucun push, aucun merge main, aucune migration, aucune modification de `supabase/`, `.github/`, `vercel.json`.
- Statuts de preuve : UI réalisée / branchée / testée en simulation / vérifiée réellement / dépendance backend.

## Prompt de reprise conseillé
« Reprends le chantier frontend Tuteur V1 de Rewayah : lis `D:\RA _APP\pilotage-tuteur-v1\00_REPRISE.md`, fais les contrôles de reprise, puis poursuis là où la phase en cours s'est arrêtée. »
