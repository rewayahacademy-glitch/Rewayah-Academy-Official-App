# FI-12 : rapport de recette de la vague Finance (format FQ)

Écrit le 04/10/2026, passe 2, mis à jour après la critique finale. Base de code : worktree `rc-2` au commit **`fdd97b40`**. Ce commit réunit les deux livraisons : `ef6887f7` (rc-1 : `recette_fi_test.dart`, 29 tests ; `recette_fi_roles_test.dart`, 9 tests ; trois corrections dans `lib`) et `8da29e9b` (rc-2 : les captures). Les numéros de ligne cités `:N` renvoient à `test/features/finance_recette/recette_fi_test.dart` ; `roles:N` renvoie à `recette_fi_roles_test.dart`, au même commit.

**Pourquoi un lot de recette a touché `lib`.** La recette a trouvé un défaut : sur Compte > Paiements, le second adulte faisait lire les finances du foyer, même sans les afficher (leçon 15). La correction tient en trois lignes (`lib/features/compte/paiements_page.dart`). Les deux autres changements (`demo_adulte_page.dart`, `finance_demo.dart`) ne touchent que la démonstration : le profil unique coché d'office (FI12-E18) et la variante `finance=a-regulariser` dont le refus 10 ter a besoin. Le directeur peut aussi décider de les ranger dans FI-RC.

Format imposé par la fiche FI-12 (`17_finance/02_DECOUPAGE.md:47`) et le guide §8 LOT FQ : chaque écart a un ID, une sévérité, un écran, une capture, l'attendu, l'observé, la correction et le statut.

Sévérités : **Bloquant** (refus du guide §13 ou de la revue non tenu, donnée interdite rendue), **Majeur** (écart visible à la maquette ou au guide sur un écran livré), **Mineur** (rendu, libellé, cas limite), **Info** (constat sans correction attendue). Statuts : **Tenu** (preuve citée), **Ouvert** (correction à faire, étape proposée), **Question** (le directeur tranche), **Corrigé** (corrigé dans cette passe, capture « après » ouverte).

Ce rapport ne tranche rien : les questions restent ouvertes (§9). Seule exception : FI12-E18, déjà corrigé dans le code et soumis à la confirmation du directeur.

## 1. Chiffres mesurés (04/10/2026, `rc-2`, commit `fdd97b40`)

`flutter test <dossier> -r json`, comptés par `testDone` non cachés. Les « sautés » sont les fichiers de captures, qui ne tournent qu'avec `CAPTURE_DIR`.


Suite complète, un dossier de `test/` à la fois, sur `fdd97b40` : **5815 réussis, 0 échec** (5777 au dernier push `db74dddd`).

| Dossier | Résultat |
| :--- | :--- |
| `test/accessibilite` | 00:40 +314: All tests passed! |
| `test/agent` | 00:00 +18: All tests passed! |
| `test/appairage` | 00:00 +12: All tests passed! |
| `test/cache` | 00:00 +11: All tests passed! |
| `test/capacites` | 00:00 +37: All tests passed! |
| `test/capture` | 00:16 +0 ~591: All tests skipped. |
| `test/config` | 00:01 +11: All tests passed! |
| `test/coran` | 00:00 +25: All tests passed! |
| `test/core` | 00:49 +716: All tests passed! |
| `test/features` | 07:43 +2879 ~2630: All tests passed! |
| `test/foyer` | 00:00 +18: All tests passed! |
| `test/i18n` | 00:00 +7: All tests passed! |
| `test/icons` | 00:00 +4: All tests passed! |
| `test/mouvement` | 00:01 +13: All tests passed! |
| `test/observabilite` | 00:00 +10: All tests passed! |
| `test/parcours` | 00:03 +44: All tests passed! |
| `test/planning` | 00:01 +23: All tests passed! |
| `test/presence` | 00:00 +20: All tests passed! |
| `test/priere` | 00:00 +15: All tests passed! |
| `test/router` | 00:16 +279: All tests passed! |
| `test/seance_famille` | 00:00 +25: All tests passed! |
| `test/suivi` | 00:00 +16: All tests passed! |
| `test/tc_observation` | 00:00 +19: All tests passed! |
| `test/teaching_core` | 01:12 +912 ~55: All tests passed! |
| `test/theme` | 00:05 +82: All tests passed! |
| `test/tool` | 00:01 +32: All tests passed! |
| `test/video` | 00:00 +43: All tests passed! |
| `test/widgets` | 00:35 +230: All tests passed! |

Contrôles : `dart run slang` et `build_runner` OK, `dart analyze --fatal-infos` **0 problème**, `verifier_jetons` **39 relevés** (le chiffre de la base). Captures FI-12 rejouées avec `CAPTURE_DIR` : **457 réussis, 0 échec**, 10 planches sautées sans `MAQUETTES_DIR`.

- Ce tableau remplace la mesure faite sur `8da29e9b` avant la fusion (13 dossiers, 1 399 réussis, 0 échec). Cette ancienne mesure ne comptait que 24 tests dans `recette_fi_test.dart` et ne voyait ni `recette_fi_roles_test.dart` ni les trois corrections de `lib`.
- Attendus dans `test/features/finance_recette` : `recette_fi_test.dart` **29 tests**, `recette_fi_roles_test.dart` **9 tests**.
- Accessibilité (clavier, focus visible, lecteur d'écran, cible tactile) : aucun test ne la mesure. C'est un écart ouvert (FI12-E19), pas un point tenu.

## 2. Les captures

Dossier `05_recette/FI/captures/` : **477 fichiers PNG**.

Toutes les captures ont été régénérées sur `fdd97b40`, après la fusion :
- `fi12_adulte_recharge_*` (5 fichiers) ont changé : le seul profil de l'adulte est maintenant coché ;
- Compte > Paiements du second adulte n'a pas changé à l'image : la correction retire une lecture, rien d'affiché ;
- 10 nouvelles : `fi12_adulte_a_regulariser_paiements_*` et `fi12_adulte_a_regulariser_recharge_*` (52 $ sur 60, il manque 8 $, montant suggéré 8 $). Ouvertes : `paiements_390_light`, `recharge_1440_dark`.

| Lot | Fichiers | Grille |
|---|---|---|
| Passe 1 (`_cas`, 61 cas) | 305 | 390 x 1400 et 1440 x 1400, clair et sombre ; 390 x 2400 à texte 200 % |
| Passe 2 (`_complements`, 41 cas) | 142 | États ajoutés : 390 clair, 390 sombre, **1440 x 900** (guide §10) ; certains aussi à 200 % et RTL. Formats des écrans principaux : **768 x 1024** clair et sombre, 1440 x 900 clair et sombre, 390 RTL |
| Planches maquette \| capture (guide §11.2) | 20 (10 planches + 10 captures seules) | À la taille exacte de chaque maquette 01 à 10 : 390 x 693 (téléphone) et 1440 x 810 (bureau) |

Ce que la passe 2 ajoute, par demande de la critique :

| Demande | Fichiers `fi12_…` |
|---|---|
| Chargement (squelette) | `foyer_chargement_*`, `finances_chargement_*`, `mouvements_chargement_*`, `recharge_chargement_*`, `resultat_chargement_*`, `admin_vue_globale_chargement_*`, `admin_politiques_chargement_*` |
| Résultat, 8 états sur 8 | passe 1 : `resultat_termine`, `_attente`, `_echec`, `_perime` ; passe 2 : `resultat_preparation_*`, `resultat_confirme_*`, `resultat_allocation_*`, `resultat_annule_*` (avec 200 %) |
| Compte > Paiements | `compte_paiements_tuteur_*`, `compte_paiements_production_*`, `compte_paiements_titulaire_adulte_*`, `compte_paiements_second_adulte_*` |
| Reçu depuis Mouvements | `mouvements_recu_*` (tape « Voir le reçu » puis capture) |
| Politiques | `admin_politiques_coherence_*` (plafond 3 et remise 51 saisis), `admin_politiques_comparaison_*` (tarif adulte 65), `admin_politiques_historique_*`, `admin_politiques_publier_*` |
| Fiche > Accès | `acces_fiche_erreur_*`, `acces_fiche_hors_ligne_*`, `acces_fiche_finance_en_echec_*` |
| Enfant dans Mes groupes (vrai routeur, session élève en mode enfant, `/tc/groupes`) | `acces_enfant_groupes_ferme_*` (avec 200 % et RTL), `acces_enfant_groupes_ouvert_*` |
| `/demo/finance` | `demo_finance_vueGlobale_*`, `demo_finance_politiques_*` (avec 768 et RTL) |
| Tablette 768 | `foyer_a_regulariser_768_*`, `finances_a_regulariser_768_*`, `recharge_etape1_768_*`, `admin_vue_globale_768_*` (clair et sombre) ; `mouvements_a_regulariser_768_light`, `recharge_etape2_768_light`, `resultat_termine_768_light`, `adulte_paiements_768_light`, `revenus_contenu_768_light`, `admin_politiques_768_light` |
| 1440 x 900 | les mêmes écrans, suffixe `1440x900_light` (et `_dark` pour Foyer, Finances, Recharge, Vue globale) |
| RTL | les mêmes écrans, suffixe `390_light_rtl` |
| §10 « interdit » | `interdit_tuteur_admin_finance_*`, `interdit_recharge_second_adulte_*` |
| §10 « incomplet » | `incomplet_recharge_rien_coche_*`, `admin_politiques_coherence_*` |
| §10 « concurrent / en attente » | `resultat_attente_*`, `resultat_allocation_*`, `resultat_confirme_*`, `resultat_preparation_*` |
| §10 « périmé » | `resultat_perime_*` |
| Comparaison high-fi | `planche_01_resultat` … `planche_10_politiques` (et `_capture`) |

**Vérifications faites au moment de la capture** (le test échoue sinon ; 457 réussis) : aucune exception de rendu sur chaque capture de la passe 2 ; `_refusFoyer`, `_refusRecharge`, `_refusBandeau`, `_refusPolitiques`, `_refusVariation`, `_enfantSansArgent` et les contrôles du second adulte, détaillés en §4 et §6.

**Captures ouvertes et relues une à une en passe 2 (22)** : `foyer_chargement_390_light`, `foyer_a_regulariser_768_light`, `finances_a_regulariser_1440x900_light`, `recharge_etape1_1440x900_light`, `recharge_etape1_390_light_rtl`, `recharge_etape2_768_light`, `incomplet_recharge_rien_coche_390_light`, `resultat_allocation_390_light`, `resultat_annule_390_light`, `mouvements_recu_390_light`, `compte_paiements_second_adulte_390_light`, `interdit_recharge_second_adulte_390_light`, `interdit_tuteur_admin_finance_390_light`, `acces_fiche_erreur_390_light`, `acces_fiche_finance_en_echec_390_light`, `acces_enfant_groupes_ferme_390_light`, `admin_politiques_coherence_1440x900_light`, `admin_politiques_historique_390_light`, `admin_vue_globale_768_dark`, `planche_01_resultat`, `planche_03_foyer`, `planche_05_foyer` ; plus les maquettes 04 et 07. Passe 1 : 25 relues (liste de la passe 1). Total relu : 47 sur 467. Aucune affirmation de ce rapport ne s'appuie sur une capture non relue sans le dire.

## 3. Écarts (format FQ)

| ID | Sév. | Écran | Capture | Attendu | Observé | Correction | Statut |
|---|---|---|---|---|---|---|---|
| FI12-E01 | Majeur | Foyer, cartes d'enfant | `fi12_foyer_a_regulariser_768_light`, `fi12_foyer_chargement_390_light` | Pas de chevron sur les cartes (revue:315, Q-FI-9) | **Un chevron par carte** : 3 mesurés (`CHEVRON 3` imprimé par `_refusFoyer` sur 5 captures). Code : `lib/features/foyer/ligne_membre.dart:243-246` (`fin: … AppIcons.chevron`). La passe 1 (§3.1) le présentait comme un choix ; la revue le refuse : c'est un écart, la contradiction est levée en sa faveur | Retirer `fin` de `CarteMembre` (la carte entière reste cliquable) | Ouvert (FI-RC) |
| FI12-E02 | Majeur | Foyer | `fi12_planche_03_foyer`, `fi12_planche_05_foyer` | « Recharger plusieurs profils » seul bouton plein, « Ajouter un profil élève » secondaire (Q-FI-2, guide §5.1) | Inverse : « Ajouter un profil élève » plein ; le test `foyer_finances_test.dart` « un seul bouton plein : « Recharger plusieurs profils » est secondaire » fixe cet inverse | Selon la réponse, inverser les niveaux et le test | Question (Q1) |
| FI12-E03 | Majeur | Foyer mobile | `fi12_planche_03_foyer` | Rangée des trois compteurs gardée (Q-FI-7) ; composition de la maquette 03 | Pas de compteurs ; synthèse en liste. La high-fi Tuteur mobile **n'est pas reproduite** (§14) | Composer la synthèse mobile comme la maquette 03 | Ouvert (FI-RC) |
| FI12-E04 | Majeur | Fiche > Finances bureau | `fi12_finances_a_regulariser_1440x900_light` | Colonne d'identité = groupe « Paramètres de l'élève » réutilisé (revue FI-6a, maquette 06) ; période dite une fois | Colonne gauche : identité seule, vide en dessous ; « Aucune période financée » sous l'identité et « Période à financer octobre 2026 » dans la vue : période dite deux fois (revue:315) | Reprendre le groupe « Paramètres de l'élève » ; période à un seul endroit | Ouvert (FI-RC) |
| FI12-E05 | Mineur | Foyer, carte d'Ibrahim | `fi12_foyer_a_regulariser_768_light` | Même phrase que la fiche (« Période à financer octobre 2026 ») | « Prochain débit 1 octobre 2026 · 50 $ » le 4 octobre | Lire la même donnée que la fiche | Question (Q2) |
| FI12-E06 | Mineur | Foyer, carte | `fi12_foyer_a_regulariser_768_light` | Même classe partout | « Pas encore de classe » au Foyer, « Classe Al-Huda » sur la fiche (`fi12_finances_a_regulariser_1440x900_light`) | Une seule source dans la démonstration | Question (Q3) |
| FI12-E07 | Majeur | Résultat, reçu : « Répartition par profil » | `fi12_resultat_allocation_390_light`, `fi12_mouvements_recu_390_light`, `fi12_resultat_echec_1440_light` | Ligne de la maquette 01 : avatar à côté du nom, montant aligné | Bandeau de couleur au-dessus, avatar sous le nom, débordant de la ligne ; à 1440 colonne d'environ 560 px | Reprendre la ligne d'identité du récapitulatif (`fi12_recharge_etape2_768_light` la rend correctement) | Ouvert (FI-RC) |
| FI12-E08 | Mineur | Résultat | `fi12_resultat_annule_390_light`, `fi12_planche_01_resultat` | « Retour aux soldes » (E-15, `02_DECOUPAGE` FI-8) | « Revenir aux paiements du foyer » | Libellé du guide | Ouvert (FI-RC) |
| FI12-E09 | Mineur | Résultat | `fi12_resultat_allocation_390_light` | Le moyen de paiement lu (maquette 01 : une ligne des détails) | Une carte de choix cochée, comme sur la recharge, sur une page où rien ne se choisit | Ligne de détail en lecture | Ouvert (FI-RC) |
| FI12-E10 | Mineur | Recharge, Résultat | `fi12_resultat_annule_390_light` | « Paiement sécurisé et chiffré » retiré (Q-FI-4) | La phrase exacte est absente (0 dans `fr.i18n.json`) ; le moyen dit « Paiement web sécurisé. Aucun débit avant votre confirmation. » (`argent.moyen.webStripeDetail`, `ligne_moyen_paiement.dart:77`) | Le directeur dit si cette phrase tombe sous Q-FI-4 | Question (Q4) |
| FI12-E11 | Mineur | Recharge | `fi12_recharge_etape1_1440x900_light`, `fi12_incomplet_recharge_rien_coche_390_light` | « Tout sélectionner » retiré (E-14, `02_DECOUPAGE` FI-7) | Présent en tête de la liste | Retirer, ou confirmer qu'il reste | Question (Q5) |
| FI12-E12 | Mineur | Fiche > Accès, finance en échec | `fi12_acces_fiche_finance_en_echec_390_light` | Une lecture en échec se dit (§10 « error ») | La page retombe sur l'échéance seule : « Expiré depuis le 30 septembre 2026 … ne peut plus entrer dans Rewayah », sans dire que la finance n'a pas pu être lue ; « À régulariser » disparaît. Comportement voulu et testé (`acces_finance_test.dart`, « tuteur : fiche eleve > Acces » > « finance indisponible : la carte de l echeance seule ») | Une ligne neutre quand la finance échoue (pas quand elle est indisponible) | Question (Q6) |
| FI12-E13 | Majeur (serveur) | Enfant : Accueil, Mes groupes | `fi12_acces_enfant_groupes_ferme_390_light` | Le port de l'enfant ne porte que son état d'accès (revue:104, leçon 15) | L'écran ne montre ni montant ni cause (vérifié : aucun « $ » ni « régulariser » sur 7 captures). Mais l'enfant lit `PortAccesFoyer.acces()`, **la liste du foyer**, filtrée à l'écran par `accesAppelantProvider` ; `AccesBeneficiaire` porte aussi `motif` et `statutServeur` (réservés, toujours nuls) | FI-BR-08 : pour une session enfant, ne rendre que la ligne de l'appelant, sans `motif` | Ouvert (BR-1) |
| FI12-E14 | Info | Enfant, Mes groupes | `fi12_acces_enfant_groupes_ferme_390_light` | La coquille de l'enfant autour de l'écran | `/tc/groupes` s'ouvre sans barre de navigation (route hors coquille, `routes_tc_a.dart`) | Hors Finance : voie TC | Info |
| FI12-E15 | Mineur | Politiques à 390 | `fi12_admin_politiques_historique_390_light` | Aucun mot coupé (§10) | « Version lancemen / t-2026-10 », « brouillon- / 2027-01 » coupés au milieu | Nom de version sur sa propre ligne, ou colonne plus large | Ouvert (FI-RC) |
| FI12-E16 | Mineur | Tous, RTL | `fi12_recharge_etape1_390_light_rtl` | Droite-à-gauche lisible | Le sens est forcé sur le texte français : ponctuation et « $ » migrent (« .Choisissez… », « $ Solde actuel : 12 », « sur 2 1 »). `assets/i18n/ar.i18n.json` existe : la vraie preuve serait la langue arabe | Capturer en `AppLocale.ar` | Ouvert (FI-R) |
| FI12-E17 | Info | Compte > Paiements, second adulte | `fi12_compte_paiements_second_adulte_390_light` | Historique du foyer en lecture (date, justificatif) | « Paiements pas encore consultables » : l'historique attend DB-CPT-03. Ni solde ni recharge (vérifié à la capture) | Aucune côté front | Info |
| FI12-E18 | Mineur | Recharge de l'adulte ouverte directement | `fi12_adulte_recharge_390_light` (passe 1, périmée : à régénérer, §2) | Son seul profil coché | Avant : non coché ; coché seulement depuis « Recharger » de Paiements | `demo_adulte_page.dart` : `preselection: {mesFinances.profilId}`. Test : roles:290 (avec et sans `eleve=`, la case cochée, « Vérifier » actif) | **Corrigé dans FI-12 (profil unique coché d'office), à confirmer par le directeur** (Q7) |
| FI12-E19 | Majeur | Toute la voie | aucune | §10 Accessibilité : clavier, focus visible, lecteur d'écran, cible tactile | Aucun test Finance ne les mesure (`sendKeyEvent`, `LogicalKeyboardKey` : 0 dans les dossiers Finance) ; seul le texte à 200 % est capturé et testé | Tests de recette dédiés | Ouvert (FI-R) |
| FI12-E20 | Mineur | Vue globale | `fi12_planche_09_vue_globale` | Blocs C7 « État des paiements » et C8 « Top classes » gardés (`ECARTS_MAQUETTES_08_10`) | Absents | Selon la réponse | Question (Q8) |
| FI12-E21 | Mineur | Revenus à 390 | `fi12_revenus_contenu_390_light` (passe 1) | Légende lisible | « Sièges éligibles » sur six lignes en colonne étroite | Légende sous le chiffre | Ouvert (FI-RC) |
| FI12-E22 | Mineur | Fiche > Accès, enfant en essai | `fi12_acces_fiche_essai_390_light` (passe 1) | Phrase sur l'essai | « Aucune date de fin n'est enregistrée » à côté de « Essai : 1/2 » | Phrase d'essai | Question (Q9) |
| FI12-E23 | Mineur | Captures bureau | passe 1 : `*_1440_*` | 1440 x 900 (§10) | Passe 1 en 1440 x 1400 (page entière) | Passe 2 : 1440 x 900 pour Foyer, Finances, Mouvements, Recharge, Résultat, Paiements adulte, Revenus, Vue globale, Politiques et chaque état ajouté | Corrigé (`fi12_*_1440x900_*`, 3 ouvertes) |
| FI12-E24 | Mineur | Tablette | passe 1 : aucune | 768 (§10, « tablette / rail ») | Absente de FI-12 | Passe 2 : 768 sur 10 écrans (rail visible sur `fi12_foyer_a_regulariser_768_light`) | Corrigé |
| FI12-E25 | Majeur | Fiche > Accès | passe 1 : aucune | États erreur et hors ligne capturés | Absents | `fi12_acces_fiche_erreur_*` (« Impossible de charger ces informations », « Réessayer »), `fi12_acces_fiche_hors_ligne_*` | Corrigé |
| FI12-E26 | Mineur | Résultat à 1440 | `fi12_resultat_echec_1440_light` | Guide §6 : sur bureau, pas une seule colonne de téléphone | Une colonne bornée d'environ 560 px. Le refus 8 (`:1298`) l'accepte comme « tâche focalisée » (largeur au plus `AppPage.largeurDialogue`) ; le guide §6 ne prévoit pas cette exception | Selon la réponse | Question (Q10) |
| FI12-E27 | Mineur | Enfant, Mes groupes | `fi12_acces_enfant_groupes_ouvert_*` | Rejoindre actif quand le mois est financé | Rejoindre est présent mais toujours inactif : l'entrée en salle (`BilletSalle`) n'est pas branchée sur cette route (`:1670`). L'activation n'est prouvée que sur l'Accueil de l'élève (`:1625`) | Brancher l'entrée en salle (hors Finance), puis rejouer `:1625` sur Mes groupes | Ouvert (FI-RC) |
| FI12-E28 | Mineur | Fiche > Accès, Compte > Paiements, Enfant, Mes finances, Revenus | aucune | État « chargement » capturé (§10) | Non capturé sur ces cinq écrans (§7) | Captures de chargement | Ouvert (FI-RC) |
| FI12-E29 | Majeur | Compte > Paiements | aucune | États erreur et hors ligne (§10) | Ni capturés ni cités par un test de recette (§7) | Captures et test d'erreur et de hors ligne | Ouvert (FI-RC) |
| FI12-E30 | Majeur | Toute la voie | aucune | §14 (c) : clair, sombre, RTL et texte 200 % prouvés | Le test renvoie à « les balayages de chaque fichier d'écran » (`:1818-1820`), sans nom de test ni chiffre. Les captures existent, mais aucune mesure nommée | Un test de recette qui balaie les dix écrans dans les quatre modes et donne le nombre | Ouvert (FI-R) |
| FI12-E31 | Mineur | Toute la voie | aucune | §14 (c) : « aucune fonction dupliquée » prouvé | Repose sur le seul refus 1 (`:794`), qui ne prouve qu'un seul moteur de recharge | Relevé des fonctions en double dans `lib/features` Finance | Ouvert (FI-R) |
| FI12-E32 | Majeur | Tuteur, mobile et bureau | `fi12_planche_01` à `07` | §14 : high-fi Tuteur reproduite | Non atteinte : écarts FI12-E01 à E04 et E07 | Reprise par FI-RC | Ouvert (FI-RC) |
| FI12-E33 | Mineur | Recharge de l'adulte, 1440 | `fi12_adulte_a_regulariser_recharge_1440_dark` | Montant suggéré lisible d'un coup d'œil | « Montant suggéré : 8 $ » coupé sur trois lignes dans une colonne étroite, alors que la carte a de la place | Donner la place au texte avant les boutons − / + | Ouvert (FI-RC) |
| FI12-E34 | Cosmétique | Recharge de l'adulte autonome | `fi12_adulte_recharge_390_light` | Une action utile | « Tout désélectionner » proposé avec un seul profil | Masquer l'action sous deux profils | Ouvert (FI-RC) |

**Trous restants, tous ouverts.** Aucun n'est compté comme tenu : accessibilité (FI12-E19, FI-R), RTL en arabe (FI12-E16, FI-R), chargement de cinq écrans (FI12-E28, FI-RC), erreur et hors ligne de Compte > Paiements (FI12-E29, FI-RC), §14 (c) clair, sombre, RTL et 200 % (FI12-E30, FI-R), « aucune fonction dupliquée » (FI12-E31, FI-R), high-fi Tuteur (FI12-E32, FI-RC).

## 4. Refus de la revue (`UX_REVIEW_08_FINANCE.md:315`), un par un

« Vérif. capture » = contrôle exécuté pendant la capture, sur l'écran rendu (`captures_fi12_test.dart`, groupe « passe 2 ») ; le test échoue si l'élément apparaît. « i18n » = `grep -c` dans `assets/i18n/fr.i18n.json` (aucun texte d'écran n'existe hors de ce fichier).

| ID | Élément refusé (maquette) | Preuve | Résultat | Statut |
|---|---|---|---|---|
| FI12-R01 | « + Recharger » en tête (03) | i18n « + Recharger » : 0 ; vérif. capture `_refusFoyer` (`textContaining('+ Recharger')` absent, `SyntheseSoldesFoyer.rechargerKey` une seule fois) sur `fi12_foyer_a_regulariser_{768_light,768_dark,1440x900_light,1440x900_dark,390_light_rtl}` ; `foyer_finances_test.dart` « un seul bouton plein » | Absent | Tenu |
| FI12-R02 | Chevron des cartes (03, 05) | `_refusFoyer` mesure `CHEVRON 3` ; `ligne_membre.dart:245` | **Présent** | Ouvert (FI12-E01) |
| FI12-R03 | « Gérer tous les enfants » (03, 05) | i18n « Gérer tous » : 0 ; `_refusFoyer` (5 captures) | Absent | Tenu |
| FI12-R04 | Panneau « Actions rapides » (05) | i18n : 0 ; `_refusFoyer` ; `fi12_planche_05_foyer` (« Dernières transactions » à sa place) | Absent | Tenu |
| FI12-R05 | « Recharger plusieurs profils » sur la page de recharge (07) | `_refusRecharge` (`t.foyer.finances.rechargerPlusieurs` absent) sur `fi12_recharge_etape1_*` (5), `fi12_recharge_etape2_*` (3), `fi12_incomplet_recharge_rien_coche_*` (4) ; `recette_fi_test.dart` refus 1 (`:794`) | Absent | Tenu |
| FI12-R06 | Pastille de période répétée sous l'identité (06) | `fi12_finances_a_regulariser_1440x900_light` | **Période dite deux fois** | Ouvert (FI12-E04) |
| FI12-R07 | Phrase de recharge sur la fiche (06) | `fi12_finances_a_regulariser_1440x900_light` : le bandeau dit le manque et la conservation, sans phrase de recharge ; un seul « Recharger Ibrahim » | Absente | Tenu |
| FI12-R08 | Chevrons des moyens de paiement (04, 07) | `fi12_resultat_annule_390_light` : carte de choix avec coche, sans chevron ; `chevron` dans `ligne_moyen_paiement.dart` : 0 | Absents | Tenu |
| FI12-R09 | « Paiement sécurisé et chiffré » (04) | i18n « sécurisé et chiffré » : 0 ; `_refusRecharge` (`textContaining('chiffré')` absent, 12 captures) | Absent ; voisin « Paiement web sécurisé » | Tenu, avec FI12-E10 |
| FI12-R10 | Croix du bandeau (07) | `BandeauAttention` n'a aucun paramètre de fermeture (`titre`, `message`, `ton`, `action`) ; `_refusBandeau` (bandeau présent, `AppIcons.fermer` absent) sur `fi12_finances_a_regulariser_*` (5) ; `_refusRecharge` (12) | Absente | Tenu |
| FI12-R11 | Éclat de réussite et « ! » (01) | `fi12_planche_01_resultat` : « Paiement confirmé » sans « ! », pastille sans éclat ; `recette_fi_test.dart` refus 12 (`:1693`) | Absents | Tenu |
| FI12-R12 | « Apprentissage » (02) | i18n : 0 | Absent | Tenu |
| FI12-R13 | Coque de la direction et entrées inventées (08 à 10) | `fi12_revenus_contenu_1440x900_light` (coque Enseignant) ; `fi12_interdit_tuteur_admin_finance_390_light` (le tuteur reçoit « Vous n'avez pas accès à cette page ») | Tenu | Tenu |
| FI12-R14 | Flèches « vs mois précédent » sans donnée (08, 09) | i18n « mois précédent » : 0 ; aucune icône de tendance dans `app_icons.dart` (seul fichier autorisé à créer une icône) ; `_refusVariation` (`précédent` et `vs ` absents) sur `fi12_admin_vue_globale_*` (5) et `fi12_revenus_contenu_*` (3) | Absentes | Tenu |
| FI12-R15 | « À propos des anciennes primes » (08) | i18n « anciennes primes » : 0 | Absent | Tenu |
| FI12-R16 | Catégories inventées, histogramme mêlé (09) | i18n « Répartition des revenus », « Dernières opérations » : 0 ; aucun graphique dans `lib/features/admin_finance` (grep `BarChart` : 0) | Absents | Tenu |
| FI12-R17 | « Enregistrer les modifications » plein (10) | i18n : 0 | Absent | Tenu |
| FI12-R18 | Menu « … » et sélecteur de mois (10) | `_refusPolitiques` (`PopupMenuButton`, `DropdownButton`, `CalendarDatePicker` absents) sur `fi12_admin_politiques_historique_*` (3) et `fi12_admin_politiques_{768_light,1440x900_light,390_light_rtl}` (3) ; grep `PopupMenuButton|showMenu|DropdownButton|showDatePicker` dans `admin_finance`, `foyer`, `revenus_enseignant` : 0 | Absents | Tenu |
| FI12-R19 | Valeurs de maquette (30 $, −5 $, 2024, « par cours ») | i18n « 2024 », « par cours » : 0 ; `recette_fi_test.dart` refus 13 (`:1721`) | Absentes | Tenu |

## 5. Refus du guide §13, un test chacun

Tests de `recette_fi_test.dart`, groupe « (b) refus §13 » (`:793`), numérotés de 1 à 14 comme dans le fichier. Les « bis » et « ter » complètent un refus sur un autre rôle.

| N° | Refus §13 | Test (fichier:ligne) | Ce que le test prouve, et sa limite | Statut |
|---|---|---|---|---|
| 1 | Action à deux endroits | `:794` | Toute recharge ouvre le même moteur, sur la même route. Voir aussi FI12-R05 | Tenu |
| 2 | Enfant qui consomme le solde d'un autre | `:868` | Ibrahim reste à régulariser malgré le solde d'Aïcha ; chaque mouvement ne cite que son profil ; la recharge d'Ibrahim, de bout en bout sur le vrai routeur, ne crédite que lui (une seule allocation, sa part). **Limite** : le port espion fabrique lui-même l'allocation. Le test prouve que l'écran rend l'allocation du port. L'invariant « aucun débit ne puise dans le solde d'un autre » relève du serveur (FI-BR-06) | Tenu à l'écran ; serveur : FI-BR-06 |
| 3 | Total utilisable comme portefeuille | `:1030` | Le total du foyer est une lecture ; aucun moyen « solde du foyer » à la recharge | Tenu |
| 4 | Avatar qui change de couleur | `:1060` | Même couleur sur Fiche > Finances, reçu, recharge et résultat. Fiche > Accès et Compte > Paiements ne posent aucun avatar (relevé vide, vérifié) | Tenu |
| 4 bis | Même refus, élève adulte | `:1136` | Même couleur de Ma famille aux Paiements du foyer et à la recharge ; pour l'adulte autonome, de Mes finances à sa recharge | Tenu |
| 5 | Couleur selon l'index | `:1180` | Liste à l'envers ou partielle : chaque profil garde sa couleur | Tenu |
| 6 | Statut par couleur seule | `:1225` | Chaque pastille porte son mot ; deux états d'un même ton ont deux mots | Tenu |
| 7 | Tarif dans un widget | `:1267` | Garde de source sur `lib/features`, avec contre-épreuve | Tenu |
| 8 | Mobile étiré sur bureau | `:1298` | À 1440 x 900, dix écrans mesurés (`:328`) : colonnes et barre latérale ; tableau de Mouvements ; boutons non étirés. **Exception** : le Résultat reste une colonne bornée d'environ 560 px (FI12-E26, Q10) | Tenu, sauf Q10 |
| 9 | Maquette bureau compressée en mobile | `:1366` | À 390, les dix écrans ont une colonne et la barre basse, et une composition différente de 1440 ; Mouvements en liste, montant sous la ligne du profil | Tenu |
| 10 | Compte bloqué pour impayé (tuteur) | `:1436` | Chaque espace du tuteur reste ouvert ; l'accès à régulariser se dit | Tenu |
| 10 bis | Même refus, enfant | `:1464` | Sur la vraie coquille de l'élève : Accueil, Ma classe, Coran et Mes groupes ouverts ; seule la copie neutre ; aucune finance lue | Tenu |
| 10 ter | Même refus, adulte autonome | `:1521` | Variante `finance=a-regulariser` : chaque destination reste ouverte ; Mon espace et Paiements disent le manque et proposent la recharge | Tenu |
| 11 | Rejoindre selon le solde | `:1571` | Garde de source durcie : aucune lecture de solde dans `acces_finance.dart`, et une expression qui doit attraper 12 cas et en laisser passer 5 | Tenu |
| 11 bis | Même refus, vraie coquille | `:1625` | Ibrahim à 0 et mois financé : Rejoindre actif ; à 42 et mois non financé : Rejoindre fermé ; le solde n'est jamais lu. **Réserve** : sur Mes groupes, Rejoindre est toujours inactif (entrée en salle non branchée, `:1670`) ; l'activation n'est prouvée que sur l'Accueil (FI12-E27) | Tenu sur l'Accueil ; Mes groupes ouvert |
| 12 | Confirmation simulée | `:1693` | Garde de source ; le parcours : `resultat_recharge_test.dart` (« le succès vient du port ») ; Résultat 8 états sur 8 capturés | Tenu |
| 13 | Ancien montant 20/26, 10/20, 5/10 | `:1721` | Garde de source ; voir FI12-R19 | Tenu |
| 14 | Backend touché | `:1754` | `fail()` explicite, aucun saut ; repli sur la merge-base ; index, arbre de travail et fichiers non suivis vérifiés. Mesuré : `git diff --name-only aebd21a5 HEAD -- supabase/` : 0 fichier ; `.github`, `pubspec.yaml`, `vercel.json` : 0 | Tenu |

Le groupe « (c) definition of done §14 » (`:1827`) teste deux points : chaque écran Finance du tuteur a sa route (`:1828`) et les paramètres commerciaux sont injectables (`:1848`). Ses autres affirmations restent sans preuve nommée : FI12-E30 et FI12-E31.

## 6. Données par rôle (`UX_REVIEW_08_FINANCE.md:96-106`)

| Rôle | Attendu | Preuve à l'écran | Preuve dans les données | Statut |
|---|---|---|---|---|
| Tuteur titulaire | Solde, mensualité, manque, mouvements, recharge, par enfant | `fi12_foyer_*`, `fi12_finances_*`, `fi12_mouvements_*`, `fi12_recharge_*` | `PortPaiementsFoyer.finances()` (FI-BR-03) ; `recette_fi_test.dart` refus 2 (`:868`) et 3 (`:1030`) | Tenu |
| Titulaire adulte (Ma famille) | Les mêmes, dont lui | `fi12_compte_paiements_titulaire_adulte_*` | `paiements_foyer_adulte_test.dart` « Mon espace > Ma famille > Paiements du foyer, tapes : un solde… » ; refus 4 bis (`:1136`) | Tenu |
| Second adulte rattaché | Aucun solde, mensualité, manque ni recharge ; historique en lecture | `fi12_compte_paiements_second_adulte_*` (périmée : prise avant la correction de `paiements_page.dart`, à régénérer, §2) ; `fi12_interdit_recharge_second_adulte_*` (vérif. `RechargeFoyerPage` absente) | **`recette_fi_test.dart` n'y suffit pas ; `recette_fi_roles_test.dart`, roles:340** : sur Compte > Paiements puis sur sept écrans de sa coquille, ni solde, ni recharge, ni montant, ni mot « solde », « mensualité », « manque », « recharge » ; à la fin, **0 lecture des finances du foyer, 0 lecture des bénéficiaires de recharge, 0 lecture de « mes finances »** (seul l'historique est lu). Ce test a trouvé le défaut corrigé dans `paiements_page.dart` (en-tête). Aussi : `paiements_foyer_adulte_test.dart` « le second adulte rattache : l'historique seul, ni soldes, ni « Recharger », ni les enfants (E3, F7) » ; `acces_finance_test.dart` « adulte autonome : Mon espace » > « second adulte rattache : aucune finance lue, aucun bandeau ». « Jamais chargé » côté serveur : FI-BR-03 et FI-BR-18, non branchés | Tenu à l'écran ; serveur ouvert |
| Élève adulte autonome | Son seul profil | `fi12_adulte_*` (passe 1), `fi12_adulte_paiements_{768_light,1440x900_light,390_light_rtl}` | `mes_finances_test.dart` (32), port `PortMesFinances` (FI-BR-17) | Tenu |
| Élève enfant | Ni montant, ni cause, ni mouvements, ni recharge | `fi12_acces_enfant_*` (passe 1) et `fi12_acces_enfant_groupes_*` (vérif. `_enfantSansArgent` : aucun « $ », aucun « régulariser », 7 captures) | **roles:423** : les champs de `AccesBeneficiaire` sont figés (9 champs, aucun type ni nom d'argent) ; `motif` et `statutServeur` restent nuls dans chaque jeu de démonstration. **roles:474** : sur la vraie coquille, quatre écrans et trois jeux, 0 lecture des finances du foyer, de la recharge et de « mes finances ». Aussi : refus 10 bis (`:1464`), `acces_finance_test.dart` | Écran tenu ; donnée ouverte : le port rend encore la liste du foyer (FI12-E13) |

## 7. États du guide §10, écran par écran

« P1 » : capture de la passe 1 ; « P2 » : passe 2. « — » : l'état n'existe pas sur cet écran, avec la raison.

| Écran | loading | empty | success | error | forbidden | incomplete | stale | concurrent / pending |
|---|---|---|---|---|---|---|---|---|
| Foyer | P2 | P1 `foyer_aucun_paiement` | P1 | P1 | — (route du tuteur ; un autre rôle est redirigé, `test/router` 279 verts) | — (rien ne se saisit) | — | — |
| Fiche > Finances | P2 | P1 `finances_vide` | P1 | P1 | — | — | — | — |
| Mouvements, reçu | P2 | P1 `mouvements_vide` | P1, P2 `mouvements_recu` | P1 | — | — | — | Paiement en confirmation sans reçu (`fiche_eleve_mouvements_test.dart`) |
| Recharge | P2 | P1 `recharge_production` | P1 | P1 | P2 `interdit_recharge_second_adulte` | P2 `incomplet_recharge_rien_coche` | — | — |
| Résultat | P2 | P1 `resultat_vide` | P1 `resultat_termine` | P1 `resultat_echec`, `resultat_erreur` | — | — | P1 `resultat_perime` | P1 `resultat_attente` ; P2 `resultat_preparation`, `resultat_confirme`, `resultat_allocation`, `resultat_annule` |
| Fiche > Accès | non capturé (FI12-E28) | — | P1 | P2 `acces_fiche_erreur`, `acces_fiche_finance_en_echec` | — | — | — | — |
| Compte > Paiements | non capturé (FI12-E28) | P2 `compte_paiements_production` | P2 | non capturé (FI12-E29) | P2 second adulte (lecture seule) | — | — | — |
| Enfant (Accueil, Mes groupes) | non capturé (FI12-E28) | — | P1, P2 | — | Accès fermé : P1, P2 `acces_enfant_groupes_ferme` | — | — | — |
| Mes finances (adulte) | non capturé (FI12-E28) | P1 `adulte_vide` | P1 | P1 | — | — | — | — |
| Revenus | non capturé (FI12-E28) | P1 `revenus_vide` | P1 | P1 | — | — | — | — |
| Vue globale | P2 | P1 `admin_vue_globale_vide` | P1 | P1 | P2 `interdit_tuteur_admin_finance` | — | — | — |
| Politiques | P2 | — (une version active existe toujours) | P1 | P1 | — | P2 `admin_politiques_coherence` | — | P2 `admin_politiques_publier` |

Hors ligne : P1 pour chaque écran sauf Compte > Paiements (FI12-E29) ; P2 `acces_fiche_hors_ligne`.

Captures régénérées après la fusion (voir §2) : recharge de l'adulte, et la variante `finance=a-regulariser` de l'adulte (Paiements et Recharge).

## 8. Besoins serveur

La table des FI-BR rendus par les ports, ce qui manque côté serveur pour chacun, et les corrections de références proposées (LOT-E vers FI-BR-08 ; EA-BR-24/25 vers FI-BR-06 ; EA-BR-23 vers FI-BR-03) sont reportées dans `17_finance/FI-BR.md`, section « Relu par FI-12 (04/10) ». Ports concernés (`rc-2`) : `port_politiques_commerciales.dart` (FI-BR-01, 02), `port_paiements_foyer.dart` (FI-BR-03, 05 ; DB-CPT-03 ; EA-BR-23), `port_recharge_foyer.dart` (FI-BR-06 ; EA-BR-24, 25), `port_revenus_enseignant.dart` (FI-BR-11), `port_finance_direction.dart` (FI-BR-12), `port_mes_finances.dart` (FI-BR-17), `port_accents_profils.dart` (FI-BR-19), `port_acces_foyer.dart` (LOT-E). FI12-E13 ajoute une exigence à FI-BR-08.

## 9. Questions au directeur

1. **Q1 (FI12-E02)** : bouton principal du Foyer, « Ajouter un profil élève » (aujourd'hui) ou « Recharger plusieurs profils » (Q-FI-2) ?
2. **Q2 (FI12-E05)** : la carte du Foyer doit-elle dire « Période à financer octobre 2026 », comme la fiche ?
3. **Q3 (FI12-E06)** : une seule source pour la classe de l'enfant dans la démonstration ?
4. **Q4 (FI12-E10)** : « Paiement web sécurisé. Aucun débit avant votre confirmation. » reste-t-il, ou tombe-t-il avec « Paiement sécurisé et chiffré » ?
5. **Q5 (FI12-E11)** : « Tout sélectionner » sur la recharge : retiré (E-14) ou gardé ?
6. **Q6 (FI12-E12)** : quand la finance ne se lit pas, Fiche > Accès doit-elle le dire ?
7. **Q7 (FI12-E18)** : déjà corrigé dans FI-12, le profil unique est coché d'office. Le directeur confirme, ou demande de revenir en arrière.
8. **Q8 (FI12-E20)** : « État des paiements » et « Top classes » de la Vue globale dans cette vague ?
9. **Q9 (FI12-E22)** : phrase de l'accès d'un enfant en essai.
10. **Q-FI-10** (déjà posée) : Revenus depuis le Profil (fait) ou le Compte ?
11. **Q2 de `17_finance/QUESTIONS.md`** (« business plan ») reste ouverte.
12. **Q10 (FI12-E26)** : Résultat, une colonne de 560 à 1440 (guide §6). Le guide refuse le mobile posé tel quel sur bureau. Garde-t-on cette colonne comme « tâche focalisée », ou faut-il une composition de bureau ?
13. **Réserve (FI12-E27)** : dans Mes groupes de l'enfant, Rejoindre est toujours inactif, car l'entrée en salle n'est pas branchée. L'activation de Rejoindre selon le mois financé n'est donc prouvée que sur l'Accueil. À reprendre quand l'entrée en salle sera branchée.

## 10. Ce qui reste hors de ce rapport

- La suite complète sur `fdd97b40` (§1) et les trois captures à régénérer (§2, §7).
- §14 « high-fi Tuteur mobile et desktop reproduites » : **non atteint** (FI12-E32). Les planches `fi12_planche_01` à `07` montrent les écarts FI12-E01 à E04 et E07 à E09. FI-RC les reprend. La vague Finance ne peut pas être dite terminée tant qu'ils restent ouverts.
- Les écarts ouverts pour FI-R : FI12-E16, E19, E30, E31. Pour FI-RC : FI12-E01, E03, E04, E07 à E09, E15, E21, E27, E28, E29, E32.
- La revue croisée FI-R et la planche du directeur FI-RC.
