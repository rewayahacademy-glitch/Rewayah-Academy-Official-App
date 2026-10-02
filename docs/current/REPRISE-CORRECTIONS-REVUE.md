# Reprise : corrections de la revue du directeur 01-02/10

Fiche de passage pour tout agent qui prend la suite. Elle se suffit à elle-même.

## Où je m'arrête

- Dépôt `rewayah-academy-official-app`, dossier `C:\RA\corrections`, branche `corrections/revue-directeur-2026-10` (issue de `integration/essai-fusion`), poussée sur `origin`.
- Dernier commit : `81931091` (fusion de `l1-ctafin`). Arbre propre.
- Lot 0 (règles et garde-fous) : fait. Lot 1 (composants partagés) : fait, fusionné, `dart analyze --fatal-infos` propre.
- Lots 2, 3, 4, 5 : non commencés.

## Ce qui n'est PAS vérifié (à faire en premier)

1. `flutter test` complet sur l'arbre fusionné : le système l'a arrêté (mémoire). Ne pas le lancer d'un bloc : passer par dossiers (`test/core`, `test/widgets`, `test/teaching_core`, puis le reste), un seul Flutter lourd à la fois (`C:\RA\outils-corrections\verrou.ps1`). Libérer la mémoire avant (supprimer les worktrees `C:\RA\corr-l1-*` devenus inutiles : `git worktree remove`).
2. `dart run tool/verifier_jetons.dart` (36 écarts déjà connus avant) et `dart run tool/verifier_revue.dart --detail`.
3. Régénérer `tool/revue_socle.txt` pour les règles fusionnées (`--regle=<nom> --ecrire-socle`), puis noter les chiffres avant/après dans `docs/current/REVUE-DIRECTEUR-2026-10.md` (tableau « Chiffres »).
4. Captures avant/après à 320 px et bureau : seules celles de MA-NAV-1 existent.

## Écarts connus à corriger

- CTRL-SALLE-1 : la mention « visite de contrôle » est revenue pour le contrôleur ; le directeur veut qu'elle disparaisse.
- l1-boutons : `_IconeEnTete` (chrome_seance.dart) et `_IconeBarre` (barre_support.dart) pourraient utiliser `BoutonIcone`.
- Page Configuration : 4 sections en menu, pas en segments.
- Test du panneau d'élèves assoupli (3e inscrit à 857 px).
- ON-AIR-1 : notification « Votre classe est ouverte » et temps réel dépendent du serveur (BR-1).

## Questions pour le directeur (une à la fois, avec recommandation)

- Au-delà de 130 % de texte, le mot d'état des bascules de salle disparaît : accepter ?
- Galerie vidéo de la salle : écart de 8 entre cartes, à garder ?
- Configuration : menu ou 4 segments ?
- Le Coran est retiré de la barre élève en Mode Accessibilité : confirmer ?
- Plus tard, selon les lots : écran exact de FILTRES-1 / SUPERPOS-1 / bouton K-56 ; choix K-58 ; CARTES-PERSO-1 = espace de classe ? ; nom « Cahier de transmission » ; textes KYC-PHOTO-1 ; REMPL-1 offre visible aux seuls enseignants du bon genre (recommandé).

## Suite : lot 2 (balayage de tous les écrans)

1. Harnais automatique de balayage (tous rôles, 320/390/1440, texte ×1 et ×2, clavier) : débordement, chevauchement, centrage, écart des cartes, plusieurs boutons pleins. S'appuyer sur `test/support/garde_interface.dart` et `test/capture/`.
2. SUPERPOS-1, BUG-PROG-1 (test qui reproduit le double clic sur « Créer une version » AVANT la correction), FILTRES-1, CTRL-SALLE-1 (interface).
3. BENTO-1 / DASH-1 : note de stratégie avec sources, puis fiches catalogue, puis code.
4. Appliquer partout les composants du lot 1 (liste dans `lib/CLAUDE.md`, section « Interdits d'interface »).

Lot 3 (libellés : LIB-ABS-1, LIB-CAHIER-1, LIB-OBJ-1, LIB-ERR-1, FOYER-ADMIN-1, KYC-PHOTO-1, K-58, « groupe » → « classe » ; chaque libellé déclaré dans `tool/libelles_sources.json` avec le commentaire du directeur comme source). Lot 4 (formulaires : FORM-AUTO-1, DISPO-1, partie interface de CLASSE-FORM-1). Lot 5 (serveur : seulement après validation des fiches par le directeur ; migrations avec RLS et `search_path = ''`, tests dans `supabase/tests`).

## Livraison restante

- PR brouillon : `gh` absent sur ce poste ; l'ouvrir à la main sur GitHub (base `integration/essai-fusion`, jamais `main`) ou installer `gh`.
- Démo PWA : `flutter build web --release`, republier `app/` dans l'artefact `NuzzbtBSUQ7BNwcpBWGo4p`, ou `flutter-deploy.yml` en `workflow_dispatch` depuis la branche.
- Tableau : passer les étapes à `fait` avec leur mesure ; répondre aux fils de commentaires de l'artefact quand corrigé.

## Pièges appris (à ne pas refaire)

- Fusion de branches parallèles : une union par regex casse les accolades de `garde_interface.dart` et `verifier_revue.dart` ; prendre `--ours` puis réappliquer les lignes `+` de chaque branche.
- Ajouter une règle dans `verifier_revue.dart` : ne pas insérer son nom aussi dans l'appel `Violation(...)`.
- Les chaînes slang générées (`lib/core/i18n/strings*.g.dart`) : relancer `dart run slang` après tout changement de JSON.
- Un seul agent de code par worktree ; chaque agent pousse sa branche avant de rendre la main.
- Sur Windows PowerShell 5.1 : pas de `&&`, chemins complets, `-Encoding utf8`.
- `git commit -F -` n'a pas fonctionné : utiliser `-m` ou un fichier de message.

## Interdits (inchangés)

`main`, PR vers `main`, `supabase/` (lot 5 seulement après accord), `pubspec.yaml`, thème et couleurs (K-37), Coran, secrets, aucun branchement serveur avant BR-1. Réponses au directeur en français.
