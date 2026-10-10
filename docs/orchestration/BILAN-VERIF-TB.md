# Bilan de la session de vérification TB (cloud 01KZyXbi), 10/10/2026

Branche : `claude/wizardly-babbage-lmhkog` (départ 35fd3490). Aucune PR ouverte.
Arrêt demandé par l'orchestrateur (session 01B8we8b) pour économiser l'usage.
Dernier SHA : celui du commit qui ajoute ce fichier (voir `git log -1`).

## Fait et vérifié (suite complète verte sur la branche)

- **Vérification des étapes « fait » de la session 01G4yRHY** : TB-F, TB-5, TB-6, TB-7a,
  TB-7b, TB-8, TB-9, TB-10, TB-11a, TB-11b, AR-SALLE-1, AR-TC-1, TB-STYLET-1, TB-1a passées
  « verifie » au tableau. Corrections de la vérification : 4917671d, 00548b28, b28136ec,
  980b51e6, 3f110455, 2d38362e. Suite sur 2d38362e : +6895 ~3474, 0 échec.
- **TB-12 (recette)** « fait » au tableau, preuve 7cea9cf1 : `05_recette/TB/TB_RAPPORT.md`,
  `05_recette/TB/TB-BR.md` (TB-BR-29 à 61), 212 captures `docs/current/captures/TB-12/`,
  4 fichiers de tests `test/features/tb_recette/recette_*_test.dart`.
  Suite sur a5393f82 : +6941 ~3884, 0 échec ; analyze 0 ; jetons 39 ; revue 1609.
- **TB-R (revue croisée)** « fait » au tableau, preuve a72fd566 : `05_recette/TB/REVUE_TB-R.md`
  (7 majeurs M1-M7, 36 mineurs, 16 notes).

## Fait mais non vérifié par la suite complète : TB-RC (en_cours au tableau)

Commits 138d9dac, 3c920384, 47405bba, c810890e, d77c8b10 et les trois commits de L6, puis
6cc37f84 (réunion des lots, 8 cas « attend L2 » réactivés : le signe de suite est le
chevron posé sur le fondu, décidé par délégation), puis le commit des captures régénérées.

- Corrigés, chacun avec test et contre-épreuve dans son lot : M1 (états élève §12),
  M2 (téléphone couché), M3 (bureau ×2), M4 (ordre de tabulation), M5, M6 (écriture),
  M7 (K-58 conséquence des affichages), et la plupart des mineurs (détail par lot dans
  `test/features/tb_recette/rc_*_test.dart` et dans les messages de commit).
- Contrôles faits après réunion : analyze 0, jetons 39, revue 1604, slang et build_runner
  sans diff, tests ciblés de chaque lot verts, groupe de la feuille Commandes 9/9.
- **Pas fait** : suite complète après réunion (arrêtée sur ordre), captures de contrôle du
  téléphone couché et du bureau ×2 sur l'état réuni, planche web du directeur.

Captures ouvertes après réunion (3ef49562) : 390 ×1 clair, 320 ×2 élève, 768 sombre,
1440 ×2 Commandes. Page entière et plus grande à 320 ×2 ; à 1440 ×2, la dernière rangée
(Support / Avec notes / Tableau) est coupée sous le fondu et le chevron de suite recouvre
le mot « Avec » : défaut restant, relevé aussi par la relecture de L2.

## Reste

- TB-RC : lancer la suite complète sur la tête de branche ; si verte, passer TB-RC « fait »
  avec ce SHA. Puis planche web (format CL-4) après ouverture des captures (K-61.9).
- Non corrigés (à porter dans `reste` de TB-RC) : m22 point rouge de PermanentNotice
  (ADR-011, gelé) ; n.7 phrase du tableau libre qui déborde à ×2 (surface_page_fixe) ;
  volet ouvert trop bas au téléphone couché ; n.17 menu de rangement visible pendant sa
  fermeture (MenuActions, core) ; m21 mémoire des outils par salle (BR-1) ; m20 coupure
  de room ; m3, m13, m25, m26, m29, n.10 partiels (voir lots L2) ; Quitter lu deux fois
  (CommandeSalle, core).
- Choix par délégation à valider par le directeur : bouton Focus garde le mot « Focus »
  dans les deux états (le nom lu dit « Quitter le focus ») ; salle_200_test mesure avec
  les polices du dépôt.
- K-60.4 : les corrections faites par cette session le 10/10 doivent être relues par une
  autre session.
- Tableau : etat/maintenant (v125) non mis à jour ; fiche
  sessions/C-2026-10-10-cloud-01KZyXbi encore active ; TB-STYLET-1, TB-1a et TB-BR 29-61 à
  reporter sur pilotage ; ligne de branche à rattacher à JONCTION-LIGNES-1.
