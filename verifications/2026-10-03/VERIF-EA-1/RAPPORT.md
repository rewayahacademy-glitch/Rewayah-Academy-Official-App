# VERIF-EA-1 : Élèves adultes, début de vague (EA-0 à EA-6)

Session 90248232, 03/10/2026, lecture seule (aucun commit de code). Branche `ui/eleves-adultes-v1` @ `5629693`, worktree détaché `D:\RA_TUTEUR\v-ea1`. Règle K-03 : cette session n'a écrit aucun code de la vague.

## Verdict : VÉRIFIÉ (un mineur, nouvelle étape EA-HORS-LIGNE-1)

Les huit étapes couvertes tiennent leur promesse au commit vérifié. Les cinq corrections citées sont ancêtres de `5629693` et toujours présentes ; aucune n'a été écrasée. Un défaut mineur, non suivi ailleurs : le bandeau hors ligne partagé dit « l'envoi attendra » sur la page d'invitation, qui dit le contraire.

## Verrou

| Commande | Résultat |
|---|---|
| `flutter pub get` | code 0 (`pubget.log`) |
| `dart analyze --fatal-infos lib test` | No issues found! (`analyze.log`) |
| `flutter test test/features/accueil_adulte test/features/ma_classe_adulte test/features/mon_espace_adulte test/features/foyer test/features/demo/demo_adulte_page_test.dart test/features/adulte_recette` (sans CAPTURE_DIR) | +613, ~672 ignorés, All tests passed! (`tests_ea1.log`) |
| `flutter test captures_ea_test.dart captures_ea3_test.dart captures_ea6_test.dart captures_ea6c_test.dart` avec CAPTURE_DIR | +256, All tests passed!, 256 PNG (`captures.log`) |

Tests ignorés : seulement les captures (`skip: sautSansCapture`) et 8 comparaisons de maquettes antérieures à la vague (`foyer_capture_test.dart:314`, `fiche_eleve_capture_test.dart:285`…, `skip: _maquette… == null`). Aucun « overflowed » ni « EXCEPTION CAUGHT » dans les deux journaux.

Le `pub get` a réécrit les fins de ligne de trois fichiers suivis (`windows/flutter/generated_plugin*`) ; ils ont été remis à l'état du commit (`git checkout --`), le worktree est propre.

## Les cinq corrections

Toutes ancêtres de `5629693` (`git merge-base --is-ancestor`, code 0).

| Commit | Étape | Ce qu'il corrige | Toujours présent à 5629693 |
|---|---|---|---|
| 9c5be75 | EA-2 | Dernières séances : date puis une ligne, sans répéter Classe ni enseignant ; salutation sur une ligne à 390, sans photo ; bureau : séance et « Avant » à la même hauteur ; bouton de l'emplacement vers la préparation ; cloche gardée au chargement ; « Voir tout » vers Ma classe ; `BlocBibliotheque` empile titre et lien au-delà du seuil de texte | Oui. `accueil_adulte_page.dart:287` (clé `accueil-adulte-prochaine-seance`), `:332` (`accueil-adulte-dernieres`), `:353` (`onVoirRessources`) ; `demo_adulte_page.dart:994` ; `tc_espace_groupe/` inchangé depuis 9c5be75 (`git diff --stat` vide). Évolution depuis : état hors ligne ajouté (EA-RC M5), rien de retiré. Tests `accueil_adulte_page_test.dart:136, 150, 165, 297` verts. |
| a1a0d13 | EA-3 | Le second adulte n'est jamais placé dans la Classe du titulaire (`maClasse` rend `null`, fournisseur réel indisponible) ; diamètre des photos repris de la fiche du groupe (40) ; « Voir tout » vers la Bibliothèque de la Classe | Oui. `adulte_demo.dart:727-730`, `demo_adulte_page.dart:864`, `ma_classe_adulte_page.dart:134, 256, 273`. Tests `ma_classe_adulte_page_test.dart:176, 226` verts. |
| e7c8ba7 | EA-4 | Identité lue par `identiteTitulaireProvider` ; aucune pastille pour l'état normal (`pastilleEtatNormal: false`, E12) ; « Informations légales » au lieu d'« À propos » (E7) ; retour des sous-pages du Compte vers Mon espace (`onRetour`) ; pages « Mes accords » et « Cours et accès » indisponibles et dites comme telles (EA-BR-08, 09) | Oui. `mon_espace_adulte_page.dart:219, 248, 389, 454-489` ; `compte_tuteur_page.dart:268, 299` ; `onRetour` dans `aide_page.dart:26`, `apparence_page.dart:30`, `informations_legales_page.dart:33`, `informations_page.dart:29`, `preferences_page.dart:29`, `securite_page.dart:26` ; `fr.i18n.json:3874-3878`. Test `mon_espace_adulte_page_test.dart:891` vert. |
| 9de21e2 | EA-5 | Le Foyer du tuteur n'est rendu que pour « pas titulaire » (`CapaciteIndisponible`) ; chargement et erreur dits (squelette, Réessayer) ; fiche d'enfant et appareils gardés dans la coquille (`onAller`, `onRetour`) ; plus de date d'accès sentinelle | Oui. `foyer_page.dart:169-174`, `place_adulte.dart:137`, `appareils_page.dart:42`, `fiche_eleve_page.dart:246-247`, `adulte_demo.dart:153`. `procheAdulte` absent de `lib/` (`git grep`, aucun résultat). Tests `ma_famille_adulte_test.dart:336, 849, 899` verts. |
| 6c6633a | EA-6 | Réponse tardive après annulation simulée (`acceptationRecue`) ; D5 « L'envoi n'a pas été confirmé. » + « Vérifiez avant de réessayer. » ; titre « Inviter ma conjointe / mon conjoint » ; E4 « Continuer » puis « Envoyer l'invitation » ; aide de l'adresse accordée au genre ; hors ligne sans promesse d'envoi automatique ; refus avec « Revenir à Ma famille » et Envoyer inactif ; focus ; latence sur `Mouvement.maximum` ; libellés provisoires D4 | Oui. `adulte_demo.dart:299, 314` ; `demo_adulte_page.dart:1669` ; `invitation_conjoint.dart:418-419, 469`, marques D4 l.15, 434, 448, 501, 519, 552, 676, 714, 756 ; `fr.i18n.json:3965-4002`. Aucune phrase « pas été envoyé », « n'est pas partie », « toujours envoyée » dans le fichier. Depuis : `_Resultat` passé sur `EcranResultat`, `_Carte` sur `AppCard`, `_Actions` sur `RangeeActions` (EA-RC M4, EA-PL) et garde hors ligne avant l'appel (m13) ; rien de retiré. Tests `inviter_conjoint_test.dart:454, 504, 527, 652, 691, 727` verts. |

## UX_REVIEW_07 et EA-0 (F1 à F24)

| Point | Constat |
|---|---|
| EA-0, préparation | Pilotage `395a18e` : `00_REPRISE.md`, `02_DECOUPAGE.md`, `V/00_MAQUETTES_ELEVES_ADULTES.md`, `PLANCHE-1..6.png`, tous présents. Ressources `8e62d1b` : `memoire/ELEVES-ADULTES-2026-09-27.md`, 24 règles F1 à F24 comptées, fichier inchangé depuis (`git diff --stat 8e62d1b projet/ressources` vide). |
| EA-1a, UX_REVIEW_07 | `16_eleves_adultes/UX_REVIEW_07_ELEVES_ADULTES.md` @ `48e5eb4`, inchangé depuis : 19 lignes toutes « Adapter », contrats A à E, K-42 points 1 à 7, textes T1 à T3, une dérogation (Q5, deux boutons de même poids), 14 questions toutes `NON_BLOQUANT`. Les sources en ligne sont datées du 27/09 par l'auteur ; non relues ici. |
| Ligne 1, coquille | 4 destinations (Accueil, Ma classe, Coran, Mon espace) `demo_adulte_page.dart:452-473` ; barre en bas à 390, rail à 768, barre latérale à 1440 ; destination active en icône pleine et libellé (captures). Famille par la ligne « Ma famille » de Mon espace, jamais une 5e destination. |
| Ligne 2 et 3, Accueil | Salutation sur une ligne, cloche, « Mon parcours » en une ligne, absence seule en pastille ; deux colonnes sur bureau ; aucune tuile « Ajouter ma famille ». |
| Ligne 4, Ma classe | Sections sans onglets, participants en initiales, effectif « 3 élèves sur 6 places » rendu, progression en une ligne, aucune mention du foyer. |
| Ligne 5, Mon espace | Une seule ligne famille selon la situation ; second adulte : « Forfait famille » et « Paiements du foyer » (E3 = b, K-53.8), aucune rubrique « Paiements » personnelle ; « Se déconnecter » à part, en bas. |
| Ligne 6 et 7, Ma famille | Carte du titulaire en tête (E6), place sur sa ligne (F21), initiales pour la conjointe (Q4), un seul bouton plein « Ajouter un profil élève » côté membres, « Recharger » côté paiements sur bureau. |
| Ligne 8, profil élève | `procheAdulte` absent de `lib/` ; test `ma_famille_adulte_test.dart:336` vert. |
| Ligne 9, invitation | Deux étapes, « Modifier » revient avec la saisie, double envoi neutralisé, erreurs neutres (F4), réponse tardive sans rattachement (F5). Tests `inviter_conjoint_test.dart:128, 271, 338, 454, 793` verts. |
| F6, F7 confidentialité (majeur de la revue cloud d'EA-4) | Pour les 25 états et les deux genres, le second adulte ne voit jamais les enfants ni le Foyer, même par l'adresse : `mon_espace_adulte_page_test.dart:268-366` (50 cas) verts. |
| F24, démonstration fermée en production | `routesDemoAdulte` vide en production : `demo_adulte_page.dart:350`, test `demo_adulte_page_test.dart:29-43` vert. |

## Captures (K-61), ouvertes par cette session

Toutes produites depuis `5629693`. Les quatre bords regardés : aucune bande jaune et noire, aucun texte coupé sauf ce qui est noté.

| Fichier | Ce qu'on voit |
|---|---|
| `ea1b_accueil_390_light.png` | Coquille à 4 destinations en bas, Accueil actif (icône pleine, libellé, trait). « Bonjour Mamadou » sur une ligne, cloche, Prochaine séance, Avant le prochain cours (3), Mon parcours en une ligne. |
| `ea1b_accueil_768_light.png` | Rail à gauche, mêmes blocs en une colonne. |
| `ea1b_accueil_1440_dark.png` | Barre latérale ; deux colonnes ; « Absence » seule pastille. Le titre « Ressources de la classe » passe sur deux lignes à côté de « Voir tout » (voir remarques). |
| `ea3_ma_classe_390_light_pleine.png` | Page entière : identité, séance, À propos en une ligne, Participants (M, M, Y, « Mamadou (vous) »), 3 ressources, progression « Chapitre 1 · Page 24 ». |
| `ea3_ma_classe_1440_dark.png` | Deux colonnes en rangées ; participants à gauche, ressources à droite. |
| `ea3_ma_classe_390_light_200pc_pleine.png` | Texte ×2 : tout tient, rien ne déborde. Dans la barre du bas, « Mon esp… » est tronqué (déjà suivi en HU-1). |
| `ea3_ma_classe_390_light_conjoint.png` | Vue du second adulte : « Pas encore disponible », jamais la Classe An-Nour. |
| `ea1b_monEspace_390_light.png`, `ea1b_monEspace_1440_light.png` | Carte d'identité sans pastille d'état normal, Mon compte groupé, une ligne « Ma famille », Aide et support, Se déconnecter à part. À 1440 : titres « Mon compte » et « Aide et support » à la même hauteur. |
| `ea1b_mon_espace_vue_conjointe_390_dark.png` | Mariama : « Forfait famille » et « Paiements du foyer · Non disponible », aucune rubrique « Paiements » personnelle, aucune « Ma famille ». |
| `ea1b_maFamille_390_light.png` | Carte du titulaire en tête, « Mariama, votre conjointe » (initiales), Aïcha et Oumar, un bouton plein, Paiements du foyer, « À propos du forfait famille ». |
| `ea1b_maFamille_1440_light.png`, `ea1b_maFamille_1440_dark.png` | Fond uniforme jusqu'en haut : la bande blanche relevée en EA-1b n'existe plus. Membres à gauche, Paiements du foyer à droite avec un seul « Recharger ». |
| `ea6_inviter_conjoint_390_light.png` | « Inviter ma conjointe », « Un compte personnel pour elle », texte du doc §19, aide de l'adresse accordée (« votre conjointe »), « Continuer » au bord de fin. |
| `ea6_verifier_envoyer_390_light.png` | « Vérifier et envoyer », récapitulatif, « Modifier » puis « Envoyer l'invitation ». |
| `ea6_inviter_conjoint_390_light_erreur_reseau.png` | « L'envoi n'a pas été confirmé. » / « Vérifiez avant de réessayer. Vos informations sont conservées. » (D5). |
| `ea6_inviter_conjoint_390_light_refus.png` | « Cette invitation ne peut pas être envoyée », « Revenir à Ma famille », Envoyer inactif. Page montée seule (le test le dit, `captures_ea6_test.dart:221-223`). |
| `ea6_inviter_conjoint_390_dark_hors_ligne.png` | Page : « Rien n'est envoyé. Vous pourrez envoyer l'invitation vous-même… ». Bandeau du haut : « Pas de réseau. Tout reste consultable, l'envoi attendra. » **Contradiction** (défaut ci-dessous). |
| `ea6_inviter_conjoint_390_light_200pc.png` | Texte ×2 : titre sur deux lignes, rien de coupé. |
| `ea6_invitation_envoyee_1440_light.png` | Détail aligné sur la tête de page, « Annuler l'invitation » en destructif tertiaire au bord de fin. |
| `ea6c_echec_annulation_390_light.png` | « L'annulation n'a pas été confirmée. » / « Vérifiez avant de réessayer. » L'adresse se coupe « …@exampl / e.com » (voir remarques). |
| `ea6c_ligne_annulee_390_dark.png` | Après annulation : « Ajouter une conjointe », « L'invitation a été annulée et ne peut plus être acceptée… », personne rattaché. |
| `ea6c_hors_ligne_annulation_390_light.png` | Page : « Rien n'est annulé » ; bandeau : « l'envoi attendra ». Même contradiction. |

## Défaut → étape proposée

- **EA-HORS-LIGNE-1** (mineur, voie probable CORR-2, dépend d'INTEG-RC-1) : le bandeau hors ligne partagé affiche `reseau.horsLigne` = « Pas de réseau. Tout reste consultable, l'envoi attendra. » (`assets/i18n/fr.i18n.json:126`, texte du 06/09). Sur l'invitation du conjoint, la page dit au même moment « Rien n'est envoyé. Vous pourrez envoyer l'invitation vous-même… » (`fr.i18n.json:3986`) et « Rien n'est annulé… » (`:3998`). Le bandeau promet un envoi automatique que l'écran dément ; c'est le mineur de la revue d'EA-6 (« horsLigne laisse croire à un envoi automatique »), corrigé dans la page mais pas dans le bandeau. Captures `ea6_inviter_conjoint_390_dark_hors_ligne.png`, `ea6c_hors_ligne_annulation_390_light.png`. Remède possible : un texte de bandeau qui ne promet rien (« Pas de réseau. Tout reste consultable. »), ou ne pas poser le bandeau sur les pages qui disent déjà l'état hors ligne. Composant partagé : à faire à un seul endroit, toutes les coquilles en héritent.

## Remarques (sans étape nouvelle)

- « Mon esp… » tronqué à 200 % dans la barre du bas (`ea3_ma_classe_390_light_200pc_pleine.png`) : déjà suivi en HU-1 (PT-A-20261002-a4a8025f).
- À 1440, texte normal, « Ressources de la classe » passe sur deux lignes à côté de « Voir tout » (`ea1b_accueil_1440_dark.png`, `ea3_ma_classe_1440_dark.png`) : rien de coupé ; même composant que le relevé d'EA-2 sur `BlocBibliotheque`.
- L'adresse e-mail se coupe au milieu dans `LigneCleValeur` à 390 (`ea6c_echec_annulation_390_light.png`) : une adresse n'a pas d'espace ; cosmétique, proche de COUPE-MOTS-1.
- La preuve d'EA-2 cite `7dc3bab`, qui n'est pas sur la branche ; le commit de la branche est `ba1ab86`, même contenu (`git patch-id --stable` identique : `eefd5c1d…`).
- La réponse tardive après annulation est simulée par une fonction pure sur un état fixe ; aucune réponse n'arrive pendant que l'écran est ouvert. Accepté comme suffisant pour la démonstration par REVUE_EA-R (m12) ; la ligne serveur EA-BR-15 reste.
- Le refus et le hors ligne de l'invitation ne s'atteignent pas depuis `/demo/adulte` ; leurs captures montent la vraie page seule, et le test le dit.

## Étapes couvertes

| Étape | Résultat | Pourquoi |
|---|---|---|
| EA-0 | verifie | Pilotage `395a18e` et ressources `8e62d1b` présents et intacts ; F1 à F24 complets (24). |
| EA-1a | verifie | UX_REVIEW_07 @ `48e5eb4` intact : 19 lignes, contrats A à E, T1 à T3, une dérogation, 14 questions non bloquantes. Sources en ligne non relues. |
| EA-1b | verifie | Coquille à 4 destinations, 25 états du doc §18 (`adulte_demo.dart:27`), `/demo/adulte` fermée en production (test vert), 198 captures ea1b produites et lues en partie ; bande blanche du bureau disparue. |
| EA-2 | verifie | 9c5be75 présent ; tests de l'Accueil verts ; captures 390, 768, 1440 lues. |
| EA-3 | verifie | a1a0d13 présent ; tests verts ; 15 captures ea3, dont 200 % et vue du second adulte, lues. |
| EA-4 | verifie | e7c8ba7 et EA-4c présents ; confidentialité F6, F7 sur 25 états × 2 genres verte ; captures de Mon espace lues. |
| EA-5 | verifie | 9de21e2 présent, E5 et E6 tenus (tests `ma_famille_adulte_test.dart:418, 522, 547`) ; captures de Ma famille lues. |
| EA-6 | verifie | 6c6633a présent ; D5, E4, F3, F4, F5 tenus ; 43 captures ea6 et ea6c, dont 11 lues. Un mineur, EA-HORS-LIGNE-1. |
