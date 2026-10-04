# AD-RC : corrections des majeurs de la revue AD-R

Poste A, 27/09/2026. Branche `ui/admin-v1`, de `2fac423` à `a8dfcb3`. Aucun push, aucune PR.

## Ce qui est fait

| Constat | Commit | Ce qui change |
|---|---|---|
| M5 (partie CL-4) | `739f478` | Fusion de `d44710a` (CL-4 et CL-4.RC). 5 conflits résolus en gardant les deux API, avec des valeurs neutres par défaut. slang régénéré. L'icône `reduire` était définie deux fois : la version admin s'appelle maintenant `AppIcons.moins` (`visionneuse_piece.dart`). |
| M1 (+ n2) | `c1d33d8` | Comptes : un tuteur `pending_kyc` n'est plus compté dans « attendent une décision ». Sa colonne Pièce affiche « Sans objet ». L'intro parle des enseignants. Fixture GUARDIAN-SR-000002 passée à `aucune`. Deux tests ajoutés. |
| M3 (partie sans arbitrage, = m2) | `f242c06` | `decider()` refuse lui-même la validation en production (`CapaciteIndisponible('AD-BR-02')`) avant tout appel RPC. Un test prouve qu'aucun appel ne part. Le refus et l'aperçu des pièces restent inchangés, en attente du directeur. |
| M4 | `a8dfcb3` | `PageShell` garde l'état du corps d'une structure à l'autre (rotation, redimensionnement, texte à 200 %). Le nouveau test `page_shell_etat_test.dart` échoue sur le code d'avant (0 sur 3) et passe après. |
| M2 | `d5fdd94` | `planche.json` à jour : commit `2fac423`, écrans 15 et 16 (tuteur), captures `ad10_1_famille_dispensee_*` marquées périmées K-47. Chaque chemin est vérifié avec Test-Path. |
| Intégration | `a8dfcb3` | Cherry-pick de M1, M3 et M4 sur la fusion. |

Chaque correctif a été relu par un agent qui ne l'avait pas écrit. Les trois relectures l'ont accepté, sans défaut bloquant.

## Mesure

- `flutter analyze` : aucun problème.
- Suite complète (`flutter test --reporter failures-only`, 1 101 s) : **3537 réussis, 1298 ignorés, 0 échec**. La suite compte plus de tests ignorés qu'en AD-R parce que les tests de capture de CL-4 sont entrés avec la fusion. Journal : `suite_complete_adrc.log`.

## Ce qui reste

- **M5, partie enseignant** : `ui/enseignant-v1` (`0b01297`, puis `1108a4a`) n'est pas sur GitHub. Le poste B doit la pousser, puis suivre `13_fusion/PLAN_FUSION_ADMIN_ENSEIGNANT.md` sur la base `a8dfcb3`. Attention : l'icône `reduire` est déjà réglée ici (`AppIcons.moins`).
- **M3, points (1) et (2)** : le directeur doit décider (Q-AD6-1, Q-AD8-1).
- **Rendu** : `ActionPrincipale` prend la version CL-4 pour tous les appelants, admin compris (filet du secondaire à 1, graisse du libellé). Les captures admin ne sont pas rejouées.
- **Mineurs relevés par les relectures** (lot de nettoyage AD) :
  - Comptes, ordre des lignes : la base met les tuteurs `pending_kyc` en tête. Il faut un tri stable côté client : d'abord ceux qui attendent une décision.
  - Comptes : la pastille « En attente » compte encore les tuteurs. Leur pastille d'état reste en avertissement.
  - Comptes : « Sans objet » est affiché pour le tuteur seulement. L'élève et les autres rôles sans pièce affichent encore « Aucune pièce déposée ».
  - Comptes : un compte `pending_kyc` dont le rôle est illisible n'est plus compté nulle part. Il faut le signaler.
  - Revue de dossier : depuis la garde, les branches `approuve ? …` de `decider()` ne peuvent plus s'exécuter. Il faut ajouter un commentaire.
  - PageShell : une page défilante repart encore du haut quand la structure change. La saisie et le focus sont conservés. Le test doit aussi être fait sur une vraie page d'un autre rôle.
  - m15 (`AppBottomSheet`, même problème que M4) : non traité.
  - Planche : `attente_refuse` et `retour_apres_validation` montrent encore les captures AD-10. Des captures HL-A-5 plus récentes existent.
- Mineurs m1, m3 à m17 et notes de la revue AD-R : non repris dans ce lot.
- Worktrees de travail conservés, en attente d'accord pour les retirer : `D:\RA_TUTEUR\adrc-m1`, `adrc-m3`, `adrc-m4` (branches `adrc/m1`, `adrc/m3`, `adrc/m4`).
