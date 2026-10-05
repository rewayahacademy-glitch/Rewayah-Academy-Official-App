<!-- verdict : ACCEPTEE_AVEC_RESERVES -->
# Revue adverse de EA-HL-DOUBLE-1d (branche `corrections/c2-hl-double-d`, commit 38b2e54a)

**Verdict : je l'accepte avec trois réserves mineures.** Les trois réserves de 1c sont levées et je l'ai vérifié par des preuves. Aucun défaut majeur ni moyen ne subsiste.

J'ai travaillé en lecture seule, dans deux worktrees jetables détachés sur 38b2e54a. Les deux sont retirés et je n'ai rien poussé. La branche part bien de `origin/corrections/revue-directeur-2026-10` (vérifié avec `merge-base --is-ancestor`). Elle compte 5 commits et chacun se termine exactement par les deux lignes demandées. Aucun fichier interdit n'est touché : supabase/, .github/, vercel.json, pubspec, thème, Coran.

## 1. La réserve moyenne (icône de l'Accueil élève) est levée

- Code : `accueil_eleve_page.dart:248` contient maintenant `icone: horsLigne ? AppIcons.attente : null`.
- Mutation : j'ai retiré cette ligne. Le test `accueil_eleve_test.dart` échoue alors avec « Found 2 widgets with icone « hors ligne » ». Avec le code de la branche, il passe.
- Capture `accueil_eleve_echec_390_clair` et `320x2_rtl_clair` ouvertes : le bandeau porte le wifi barré, le bloc le sablier, et aucun mot n'est coupé.
- Le même défaut, trouvé par le rédacteur dans la visionneuse de pièce, est lui aussi corrigé. Mutation sur `visionneuse_piece.dart:409` : le nouveau test échoue (« Found 1 widget with icone hors ligne »). Les autres blocs hors ligne de l'application (file des dossiers, `EtatSansDonnees`, page de démarrage) portaient déjà le sablier. La salle est une exception documentée.

## 2. Réserve mineure 3 (garde du catalogue et texte de l'entrée en observation) : levée

- Le motif partagé couvre maintenant « vérifiez/vérifie (votre|ta|la) connexion », « connexion/réseau impossible », « à cause de la connexion / d'une coupure », « la connexion ou le serveur », « besoin d'Internet » et « reconnectez cet appareil ».
- La phrase par défaut « Vérifiez votre connexion » est désormais attrapée aussi par `signauxHorsLigne()`.
- L'entrée en observation dit maintenant « Entrée impossible » / « L'entrée dans la séance n'a pas abouti. Réessayez… ».
- Mutation : j'ai remis le fr.i18n.json de la base et relancé slang. Trois tests échouent alors : la garde du catalogue, « hors ligne pendant l'entrée » (entree_explication_test) et l'Accueil élève. Avec la branche, ils passent.
- Capture `observation_echec_entree_390_sombre` ouverte : sablier, aucune redite du réseau, une seule icône wifi barré (celle du bandeau).

## 3. Réserve mineure 2 (couverture des captures) : levée

Le dossier `EA-HL-DOUBLE-1d/` contient 46 PNG et 2 scripts archivés. Les variantes qui manquaient sont là :

- Accueil élève, carte de session et échec de l'entrée en observation : 390 clair, 390 sombre, 390 guidée, 320x2 LTR, 320x2 RTL et 1440.
- File des dossiers admin : 390 clair, 390 sombre, 320x2 LTR, 320x2 RTL et 1440.
- Bienvenue et démarrage : sombre, guidée, 320x2 LTR et RTL.
- Appairage : guidée, 320x2 LTR et RTL.
- Foyer et fiche élève : 320x2 LTR et RTL.

J'ai ouvert les captures suivantes : visionneuse 1440, Accueil élève 390 et 320x2 RTL, observation 390 sombre, Bienvenue 320x2 RTL, dossiers 320x2, carte de session guidée, démarrage 320x2 RTL, appairage guidée, fiche élève 320x2 RTL. Je n'y vois aucun mot coupé ni aucun double signal. Les points déplacés en RTL (« .instant ») sont l'effet attendu du texte français affiché dans le sens RTL.

Le rédacteur a aussi trouvé et corrigé une coupure de « Bienvenue, » à 320x2 (`TexteSansCoupure`). En remettant `Text`, les deux tests LTR et RTL échouent.

## Contrôles

| Contrôle | Résultat |
| :--- | :--- |
| `dart run slang` | aucun écart avec le fichier généré committé |
| `dart analyze --fatal-infos` | aucune remarque |
| `verifier_revue` | 1551 sur la branche, 1568 sur la base |
| `verifier_jetons` | 39 sur la branche, 39 sur la base |
| Dossiers touchés (core/reseau, accueil élève, admin_dossiers, appareils, bienvenue, foyer, router, teaching_core/g, journée, accessibilité) | 1910 passent, 0 échec |
| test/features, test/teaching_core, test/core et test/widgets (régressions sur les autres appelants) | 5145 passent, 0 échec, 2251 sautés (captures, sans CAPTURE_DIR) |

Tous les tests ont tourné avec `--concurrency=2`. Ce qui précède est **testé localement** seulement : rien n'est testé sur staging ni déployé.

## Réserves restantes (mineures)

1. **Journée enseignant, texte `enseignant.journee.erreurPartielle`.** Il dit encore « (connexion instable ou service momentanément indisponible) » et le motif l'écarte exprès. Son jumeau du contrôleur, lui, a été réécrit. L'affichage dépend seulement d'une lecture en échec, sans condition sur le hors ligne, donc ce texte peut apparaître sous le bandeau. Je le tire de la lecture du code : ma sonde de rendu est restée sur le squelette, et aucun test ne monte cet état.
2. **03 ne dit plus la même chose que le code sur la visionneuse.** Le paragraphe « Exceptions » de 03 compte toujours la visionneuse parmi les écrans qui gardent leur propre signal. Le code et la capture montrent au contraire le bandeau au-dessus de la feuille et le sablier dans le bloc. Il faut aligner la phrase de 03.
3. **« Rewayah n'a pas répondu ».** Sept textes d'échec le disent alors que la cause réelle peut être l'appareil hors ligne. Les 21 réécritures sont des textes de l'agent, à faire valider par le directeur (ils sont bien consignés dans `tool/libelles_sources.json`).

Aucune de ces réserves n'empêche la fusion de ce lot. Elles relèvent d'un petit lot de suivi (EA-HL-DOUBLE-1e) ou d'un arbitrage des textes par le directeur.
