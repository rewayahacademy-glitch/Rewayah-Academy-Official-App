# Consolidation des vagues 2, 3 et 4 - 17/10/2026, 02:40 UTC

Écrite par l'orchestrateur de nuit (session 014MHQ7F). Les preuves de fond sont celles des deux vérificateurs finaux, agents neufs qui n'ont écrit aucun lot : `L3-V-2026-10.md` (avec la contre-vérification « L2-V bis ») et `L4-V-2026-10.md`.

| Contrôle | Résultat | Preuve |
|---|---|---|
| Lots fusionnés | Vague 2 : L2-01, L2-02, L2-03, L2-04, L2-05, L2-07, L2-08, L2-09, L2-10 et leurs reprises L2-01R, L2-02R, L2-03R, L2-05R, L2-07R, L2-08R. Vague 3 : L3-03, L3-04, L3-05, L3-06, L3-07. Vague 4 : L4-01 à L4-07, réconciliation tirage et RangeeFiltres. | `lots/V34-candidate` @ eb3e283d (vérifié @ 7ce2e9bf), fusionné en 00d0bc2c ; `lots/L4-V-verification` @ e89892fc, fusionné en fdd6d2b1 |
| Lots non faits | L2-06 (A-09 sans réponse), L3-01 et L3-02 (débloqués à 01:56 et 01:57, en cours), L1-10 et L1-11 (débloqués, en cours) | tableau Suivi |
| Zones interdites | aucune (`.github`, `site-public`, `lib/core/theme`, `parcours_offres`, `pubspec`, `vercel`, `.claude`) | diff contre `origin/claude/backend-reprise` |
| Migrations existantes modifiées | aucune ; 15 migrations nouvelles, `20261017100100` à `20261017130800`, dans l'ordre des dépendances | `ls supabase/migrations/202610171*` |
| Rejeu SQL | 214 migrations, 15/15 CI dans l'ordre, 88/88 scénarios sur base neuve ; b09 et af_l2_01 verts à l'heure défavorable ; preuves inverses des migrations de la nuit | L3-V, section 1 |
| Flutter | slang et build_runner sans écart, analyse propre ; suite complète en une commande (49 min) : +14975 ~6963, aucun rouge ; les cinq rouges de L2-V verts | L3-V, section 2 |
| Garde-fous | verifier_jetons 2 (A-13) contre 18 ; verifier_revue 1152 au-dessus du socle contre 1206, aucune règle en hausse | L3-V, section 3 ; L4-V |
| Visuel | critères chiffrés de L4-01 à L4-07 mesurés avant et après ; un seul bouton plein par écran mesuré ; D5 tenue | L4-V |
| Grille des six problèmes | lecture à l'échelle améliorée (InitPlan, L1-08R) ; aucune autre dégradation | L3-V, section 5 |
| Conflits résolus | fichiers générés `strings*.g.dart` par `dart run slang` ; `tool/libelles_sources.json` par l'union des deux côtés (JSON validé) ; un import dans `mode_demonstration.dart` (L4-02 et L2-07R) ; comportement de `RangeeFiltres` (L4-04 et L4-07) par un paramètre explicite | journal de la nuit |

Défauts ouverts, non bloquants : L4-05 D-1 (P2, sémantique du bouton de l'alerte, reprise en cours) ; L3-07 E-1 et E-2 (P3, fiche `L3-07-reprise.md`).

Verdict : arbre complet consolidé sur `claude/corrections-audit-2026-10-17`. Statut « testé localement » seulement : rien n'est appliqué sur STAGING ni en production.
