# VERIF-EA-2 : Élèves adultes, fin de vague (EA-7 à EA-RC) et EA-PL

Session 90248232, 03/10/2026, lecture seule (aucun commit de code). Branche `ui/eleves-adultes-v1` @ `5629693`, worktree détaché `D:\RA_TUTEUR\v-ea2`. Aucune session exclue (A-2026-10-02-file) n'a pris part à cette vérification.

## Verdict : VÉRIFIÉ (un mineur, nouvelle étape proposée EA-HL-DOUBLE-1)

Les dix étapes couvertes sont tenues au commit vérifié. Les quatre majeurs restants de la revue EA-R (M2, M4, M5, M6) sont corrigés et le restent à `5629693`. M1 et M3 sont bien annulés, et le code est conforme à E3 = b (K-53.8) et à K-53.6. Les deux lignes « À faire plus tard » sont livrées. Il reste un seul écart : la seconde moitié de la note de PT-A-20261002-4a9ebcbe, le double signal hors ligne (bandeau et carte), n'est pas traitée. C'est un point cosmétique, à arbitrer en HU-1.

## Verrou (dernier passage, chaque commande par `flutter-verrou.ps1`)

| Commande | Résultat |
|---|---|
| `flutter pub get` | OK, code 0 (il réécrit les fins de ligne de 3 fichiers `windows/flutter/generated_*`, que j'ai rétablis par `git checkout --` ; `git status` est vide à la fin) |
| `flutter analyze` | No issues found! (225 s), `analyze.log` |
| `flutter test test/features/foyer test/foyer test/features/adulte_recette test/features/accueil_adulte test/features/mon_espace_adulte test/features/ma_classe_adulte test/widgets test/features/demo/demo_adulte_page_test.dart test/features/demo/repere_demonstration_test.dart` (sans CAPTURE_DIR) | +801, ~672 ignorés, All tests passed! (`tests_ea2.log`). Les tests ignorés sont les captures (`sautSansCapture`) et 8 comparaisons à des maquettes absentes, antérieures à la vague (`foyer_capture_test.dart:314,328,342`, `fiche_eleve_capture_test.dart:285,301,315`, `formulaire_profil_eleve_capture_test.dart:235,248`). Aucun autre `skip:` dans ces dossiers. |
| `flutter test --reporter failures-only` (suite complète, sans CAPTURE_DIR) | +3875, ~2026 ignorés, 0 échec, « All other tests passed! » (1 589 s, `suite_complete_ea2.log`). Je l'ai lancée en plus, parce qu'EA-PL a modifié `EtatSysteme`, qui sert dans toute l'application. |
| `CAPTURE_DIR=D:\RA_TUTEUR\captures_VERIF-EA-2\png` puis `flutter test test/features/adulte_recette/captures_earc_test.dart test/features/adulte_recette/captures_ea10_test.dart` | +86, All tests passed! (`captures_ea2.log`), 86 PNG. |

## Points de REVUE_EA-R.md (contrôlés contre 4a9b318, puis tenus à 5629693)

| Point | Commit | Constat |
|---|---|---|
| M1 « Paiements du foyer » du second adulte | annulé (E3 = b, K-53.8) | La revue est rectifiée (`REVUE_EA-R.md:9, 17`). La ligne reste, ce qui est conforme : capture `earc_a_mon_espace_second_adulte_390_light` (« Forfait famille », « Paiements du foyer »). |
| M2 rubrique « Paiements » visible pendant le chargement ou en erreur | 8f65a69 | `mon_espace_adulte_page.dart:281` : `if (vue != null && vue.ligneFamille != forfaitFamille)`. La rubrique n'existe donc pas tant que la ligne n'est pas lue. Tests M2 verts (`mon_espace_adulte_page_test.dart:606, 629, 657, 685`). Capture `earc_b_…_chargement_390_light` : aucune ligne « Paiements », un squelette à la place de la ligne famille. |
| M3 « Validation refusée par la direction » | annulé (K-53.6) | `REVUE_EA-R.md:37`. Texte conforme : `fr.i18n.json:3956`, capture `earc_g_ma_famille_nouvelle_demande_390_light`. |
| M4 composants recopiés | bfea239, puis a9198bd et 5629693 | `_Carte` repose sur `AppCard` (`invitation_conjoint.dart:843-857`). `_Resultat` passe par `EcranResultat` (`:743-768`), tout comme `_PageEtatInvitation` (`acceptation_invitation.dart:570`). `_Actions` n'est plus une rangée recopiée : il délègue à `RangeeActions` (`invitation_conjoint.dart:863-873`), la même que dans `EtatSysteme` (`etat_systeme.dart:391`). `actionsContratB` est supprimé (diff 4a9b318..5629693 de `etat_systeme.dart`). |
| M5 aucun état hors ligne sur Accueil et Ma classe | 0737b87 | `accueil_adulte_page.dart:152-174` et `ma_classe_adulte_page.dart:145-152` : `EtatSysteme(nature: NatureEtat.horsLigne)`. Une capacité absente reste « indisponible ». `&reseau=coupe` atteint cet état depuis la vraie route (`accueil_adulte_page_test.dart:245`, `ma_classe_adulte_page_test.dart:299`, verts). Captures `earc_c_*`, `earc_d_*`. |
| M6 « Se déconnecter » appelle le vrai service | 8f65a69 (barrières prouvées en 81b881f) | `demo_adulte_page.dart:495` : `fermerDemo()` rend vrai. `_ServiceAuthDemo` (`:505`) surcharge `serviceAuthProvider` dans les deux coquilles (`:832`, `:1407`). Test `demo_adulte_page_test.dart:210` : un espion à la racine, `espion.appels == 0` pour chaque vue, puis retour à la liste. Vert. |
| Mineurs m1-m4, m6-m8, m13, m15-m17 | ce140b2, 81b881f | Contrôlés par sondage : soldes et prix marqués « (démonstration) » sans unité (captures `earc_a2_…_390_light` et `ea10_etape2_1440_light`) ; « Faire une nouvelle demande » au bord de fin (`earc_g`) ; tests RTL, refus tapé et `routeurProvider` dans des dossiers verts. Non traités et assumés par EA-RC : m5, m10, m11, m12. |

## Les deux lignes « À faire plus tard »

| Étape | Demandé (JSON) | Constat à 5629693 |
|---|---|---|
| PT-A-20261002-4a9ebcbe | Sur ordinateur, « Réessayer » prend toute la largeur ; double signal entre le bandeau « Pas de réseau » et la carte « Vous êtes hors ligne » | Largeur : **livrée**. `etat_systeme.dart:316` borne la carte à `largeurLecture` (800), au bord de début ; `RangeeActions` laisse « Réessayer » à sa taille, au bord de fin. Tests `composants_etats_test.dart:139` (bloc borné, Réessayer au bord de fin, LTR et RTL) et `rangee_actions_test.dart:59, 72, 89`, verts. Double signal : **non traité**. Le bandeau et la carte s'affichent encore ensemble (voir les captures ci-dessous) ; aucun commit EA-PL ne le cite. |
| PT-A-20261002-a0eb1cc5 | « Ajouter ma famille » mène à une page « arrivera dans une prochaine étape » | **Livré**. La clé `provisoire.ajouterMaFamille` est supprimée (diff i18n). `AjouterMaFamillePage` (`ajouter_ma_famille.dart`) reprend mot pour mot l'explication du doc §4 (`fr.i18n.json` `famille.ajouterPhrase`, comparée à `projet/ressources:specs/07_eleves_adultes/REWAYAH_DECISIONS_FOYER_FAMILLE_V1.md` §4). Elle propose « Inscrire un enfant », vers le formulaire commun, et « Inviter ma conjointe / mon conjoint » selon le genre (`demo_adulte_page.dart:1083-1110`). Le second adulte non rattaché voit un état indisponible avec son retour (`:1100`). Les tests `ajouter_ma_famille_test.dart:65, 145, 161, 212, 239, 273, 287, 328` (parcours jusqu'au résultat, genre, RTL) sont verts. |

## Captures (ouvertes une par une, 4 bords regardés)

Copiées dans `captures/`. Aucune bande jaune et noire, aucun débordement, aucun texte coupé dans le contenu.

- `earc_c_accueil_hors_ligne_1440_light.png` / `_dark.png` : la carte « Vous êtes hors ligne » fait 800 px (de x 288 à x 1088) et part du bord de début ; « Réessayer » garde sa taille, au bord de fin de la carte. En haut, sur toute la largeur, le bandeau « Pas de réseau. Tout reste consultable, l'envoi attendra. » s'arrête avant le ruban « Démonstration ». **Les deux signaux sont présents ensemble.** La cloche est en haut à droite et la navigation latérale est complète.
- `earc_c_accueil_hors_ligne_390_light.png` : sur deux lignes, le bandeau s'arrête avant le ruban. Carte pleine largeur avec « Réessayer » à sa taille, au bord de fin. Barre du bas à 4 destinations, Accueil actif.
- `earc_d_ma_classe_hors_ligne_390_dark.png` : titre « Ma classe », même bandeau et même carte hors ligne. Contraste correct en sombre.
- `earc_i_ajouter_ma_famille_390_light.png` : titre « Ajouter ma famille » avec flèche de retour. Une carte porte la phrase du doc §4. « Inviter ma conjointe » (contour) puis « Inscrire un enfant → » (plein) sont empilés à la même largeur, au bord de fin. Mon espace est actif.
- `earc_i_ajouter_ma_famille_1440_dark.png` : la carte est bornée (environ 560 px). Les deux actions sont sur une ligne, au bord de fin, la secondaire avant la principale.
- `ea10_etape2_1440_light.png` (recharge, étape 2) : récapitulatif par bénéficiaire (Mamadou 10,00 € (démonstration), Aïcha 5,00 € (démonstration)), « Modifier » au bord de fin, « Total à payer 15,00 € (démonstration) », « Payer 15,00 € (démonstration) » à sa taille, au bord de fin. Progression « 2 sur 2 ».
- `ea10_d5_390_light.png` (recharge, échec du paiement) : « Le paiement n'a pas été confirmé. Vérifiez avant de réessayer. » (D5), le bouton Payer reste au bord de fin. Rien n'est affiché comme un succès.
- `earc_a_mon_espace_second_adulte_390_light.png` (M2, M1 annulé) : pas de « Paiements » personnelle entre « Cours et accès » et « Mes accords ». Sont présents « Forfait famille » et « Paiements du foyer Non disponible ».
- `earc_b_mon_espace_second_adulte_chargement_390_light.png` (M2) : pendant le chargement, aucune rubrique « Paiements », un squelette à la place de la ligne famille.
- `earc_a2_foyer_titulaire_soldes_390_light.png` (EA-9, m3, m17) : « Solde de démonstration 1 à 4 » sans unité, « Bientôt épuisé » sur Aïcha, « Recharger » au bord de fin, historique honnête « Paiements pas encore consultables ».
- `earc_e_invitation_envoyee_1440_light.png` (M4) : `EcranResultat` centré, icône avion en papier, « Invitation envoyée », phrase avec l'adresse, « Revenir à Ma famille → ».
- `earc_f_invitation_recue_acceptee_390_dark.png` (M4, EA-7) : icône de coche sur l'utilisateur, « Invitation acceptée », « Vous avez rejoint le forfait famille de Mamadou. », pas de flèche de retour, « Aller à Mon espace → ».
- `earc_g_ma_famille_nouvelle_demande_390_light.png` (M3, m1) : « Validation refusée par la direction » avec l'icône interdit, « Faire une nouvelle demande » à sa taille, au bord de fin.
- `earc_h_deconnexion_confirmation_390_light.png` (M6) : feuille « Se déconnecter de Rewayah ? » avec « Me déconnecter » et « Annuler ». C'est le test `demo_adulte_page_test.dart:210` qui prouve qu'aucun appel réel n'est fait.

## Défaut → étape proposée (aucune réouverture, K-38)

- **EA-HL-DOUBLE-1** (mineur, voie probable CORR-2, dépend d'INTEG-RC-1 si le correctif part de la branche des corrections) : « Hors ligne dit une seule fois : bandeau ou carte, pas les deux ». Sur l'Accueil et Ma classe adultes, en hors ligne, `PageShell` affiche toujours `OfflineBanner` (`page_shell.dart:182`), et la page affiche en plus `EtatSysteme(nature: horsLigne)` (`accueil_adulte_page.dart:174`, `ma_classe_adulte_page.dart:152`). Captures : `earc_c_accueil_hors_ligne_1440_light.png`, `earc_d_ma_classe_hors_ligne_390_dark.png`. C'est la seconde moitié de la note de PT-A-20261002-4a9ebcbe (« double signal ; à traiter en HU-1, K-42 »), non livrée. Il faut d'abord arbitrer, car le code a une convention contraire : `mon_espace_adulte_page.dart:49` estime que « bandeau et un seul état » revient à dire une seule fois. Il faut trancher en HU-1, puis appliquer la règle à tous les écrans.

## Remarques (sans étape)

- `RangeeActions` (`action_principale.dart:371`) est un nouveau composant partagé. Il est extrait d'`EtatSysteme` pour HU-1, sur demande de PT-A-20261002-4a9ebcbe : ce n'est pas une copie, mais il faut le savoir pour le contrat C (« aucun nouveau composant partagé »).
- `ajouter_ma_famille.dart:70` : si `onInscrireEnfant` vaut `null`, « Inviter » disparaît aussi. La démonstration ne prend jamais ce chemin, puisqu'elle passe toujours les deux actions.
- Le ruban « Démonstration » est coupé par le coin (« Démonstratio ») sur toutes les captures de la coquille. Ce défaut est antérieur à la vague et ne concerne que l'aperçu.

## Étapes couvertes

| Étape | Statut | Pourquoi |
|---|---|---|
| EA-7 | vérifiée | Commits 3f5b01f, 6a0a2fe, d48ee03 et 39a16ce, tous ancêtres de 5629693. `acceptation_invitation_test.dart` est vert (Accepter et Refuser tapés). Capture `earc_f_…_acceptee_390_dark`. |
| EA-8 | vérifiée | d497e77 et fc4234d sont des ancêtres. `sortie_forfait_test.dart` est vert (retrait, départ, notifications des deux côtés, garde hors ligne). |
| EA-9 | vérifiée | 00b0c81 et 0ddf503 sont des ancêtres. `paiements_foyer_adulte_test.dart` est vert. Capture `earc_a2_…_390_light`. |
| EA-10 | vérifiée | f18068e, 3a09a3b et 5816d36 sont des ancêtres. `recharge_foyer_adulte_test.dart` est vert. Texte D5 dans `fr.i18n.json:3910-3911`. Captures `ea10_etape2_1440_light` et `ea10_d5_390_light`. |
| EA-11 | vérifiée | 9096fb5 et 43e0682 sont des ancêtres. `reprise_foyer_test.dart` est vert (dépôt, refus, attente de l'administration, jamais « validée » d'office). |
| EA-12 | vérifiée | 298ba34 et 510acbb sont des ancêtres. `recette_ea12_test.dart` est vert, dans `test/features/adulte_recette`. |
| EA-R | vérifiée | `05_recette/EA/REVUE_EA-R.md` existe, avec 6 majeurs et 17 mineurs. La rectification M1/M3 figure en `:9, 17, 37`, et le bilan corrigé en `:208`. |
| EA-RC | vérifiée | 8f65a69, 0737b87, bfea239, ce140b2, 81b881f et 4a9b318 sont des ancêtres. M2, M4, M5 et M6 sont corrigés (tableau ci-dessus). La suite complète passe à 5629693 (+3875, 0 échec) et l'analyse est propre. |
| PT-A-20261002-4a9ebcbe | vérifiée (titre), avec un mineur | « Réessayer » n'est plus en pleine largeur sur ordinateur : code, tests et captures `earc_c_*_1440`. Le double signal n'est pas traité : étape EA-HL-DOUBLE-1. |
| PT-A-20261002-a0eb1cc5 | vérifiée | Le parcours « Ajouter ma famille » est construit en démonstration (d8c37bf, 5629693). Tests jusqu'au résultat, captures `earc_i_*`. |

## Journaux

`analyze.log`, `tests_ea2.log`, `suite_complete_ea2.log`, `captures_ea2.log`. Les 86 captures brutes sont dans `D:\RA_TUTEUR\captures_VERIF-EA-2\png` ; seules les 15 citées sont copiées ici.
