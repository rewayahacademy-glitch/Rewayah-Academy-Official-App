# FI-12 : rapport de recette de la vague Finance (format FQ)

Écrit le 04/10/2026, passe 2 (reprise de la critique de la passe 1, sections 2 et 4). Base de code : worktree `rc-2`, commit des captures `8da29e9b` (au-dessus de `930cf21f`, fusion de `rc-1` : `recette_fi_test.dart` y est, 24 tests). Format imposé par la fiche FI-12 (`17_finance/02_DECOUPAGE.md:47`) et le guide §8 LOT FQ : chaque écart a un ID, une sévérité, un écran, une capture, l'attendu, l'observé, la correction et le statut.

Sévérités : **Bloquant** (refus du guide §13 ou de la revue non tenu, donnée interdite rendue), **Majeur** (écart visible à la maquette ou au guide sur un écran livré), **Mineur** (rendu, libellé, cas limite), **Info** (constat sans correction attendue). Statuts : **Tenu** (preuve citée), **Ouvert** (correction à faire, étape proposée), **Question** (le directeur tranche), **Corrigé** (corrigé dans cette passe, capture « après » ouverte).

Ce rapport ne tranche rien : les questions restent ouvertes (§9).

## 1. Chiffres mesurés (04/10/2026, `rc-2`, commit `8da29e9b`)

`flutter test <dossier> -r json`, comptés par `testDone` non cachés. Les « sautés » sont les fichiers de captures, qui ne tournent qu'avec `CAPTURE_DIR`.

| Dossier | Réussis | Échecs | Sautés |
|---|---|---|---|
| `test/features/foyer` | 469 | 0 | 37 |
| `test/features/admin_finance` | 79 | 0 | 0 |
| `test/features/mon_espace_adulte` | 111 | 0 | 0 |
| `test/features/revenus_enseignant` | 23 | 0 | 0 |
| `test/features/acces_finance` | 41 | 0 | 0 |
| `test/features/finance` | 37 | 0 | 0 |
| `test/features/finance_recette` | 24 | 0 | 542 |
| `test/features/compte` (`PaiementsComptePage`) | 47 | 0 | 0 |
| `test/features/adulte_recette` (pages Finance de l'adulte) | 226 | 0 | 647 |
| `test/features/classe_eleve` (accès de l'enfant) | 34 | 0 | 25 |
| `test/features/profil_enseignant` (entrée Revenus) | 11 | 0 | 30 |
| `test/features/accueil_eleve_test.dart` | 18 | 0 | 0 |
| `test/router` | 279 | 0 | 0 |
| **Total** | **1 399** | **0** | **1 281** |

- Les 24 réussis de `finance_recette` sont `recette_fi_test.dart` (refus 13 compris : le commit `aebd21a5` est présent dans `rc-2`, le test n'est pas sauté). Les 542 sautés : `captures_fi12_test.dart` 457, `captures_fi4_test.dart` 54, `captures_fi_test.dart` 16, `captures_fi2_test.dart` 15.
- Avec `CAPTURE_DIR=05_recette/FI/captures MAQUETTES_DIR=<17_finance/V>` : `captures_fi12_test.dart` **457 réussis, 0 échec** (305 de la passe 1, 142 de la passe 2, 10 planches).
- `dart run slang` : généré ; `dart run build_runner build --delete-conflicting-outputs` : 2 158 sorties, aucun fichier suivi modifié ; `dart analyze --fatal-infos` : aucun problème ; `dart format --set-exit-if-changed` sur le fichier touché : 0 changé ; `dart run tool/verifier_jetons.dart` : **39** relevés.
- Non mesuré ici : `test/core` et le `flutter test` complet (consigne : jamais toute la suite) ; navigation clavier, focus visible, lecteur d'écran et cible tactile (§10 Accessibilité) : aucun test Finance ne les mesure, voir FI12-E19.

## 2. Les captures

Dossier `05_recette/FI/captures/` : **467 fichiers PNG**.

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
| FI12-E18 | Mineur | Recharge de l'adulte ouverte directement | `fi12_adulte_recharge_390_light` (passe 1) | Son seul profil coché | Non coché ; coché seulement depuis « Recharger » de Paiements | Cocher d'office le profil unique | Question (Q7) |
| FI12-E19 | Majeur | Toute la voie | aucune | §10 Accessibilité : clavier, focus visible, lecteur d'écran, cible tactile | Aucun test Finance ne les mesure (`sendKeyEvent`, `LogicalKeyboardKey` : 0 dans les dossiers Finance) ; seul le texte à 200 % est capturé et testé | Tests de recette dédiés | Ouvert (FI-R) |
| FI12-E20 | Mineur | Vue globale | `fi12_planche_09_vue_globale` | Blocs C7 « État des paiements » et C8 « Top classes » gardés (`ECARTS_MAQUETTES_08_10`) | Absents | Selon la réponse | Question (Q8) |
| FI12-E21 | Mineur | Revenus à 390 | `fi12_revenus_contenu_390_light` (passe 1) | Légende lisible | « Sièges éligibles » sur six lignes en colonne étroite | Légende sous le chiffre | Ouvert (FI-RC) |
| FI12-E22 | Mineur | Fiche > Accès, enfant en essai | `fi12_acces_fiche_essai_390_light` (passe 1) | Phrase sur l'essai | « Aucune date de fin n'est enregistrée » à côté de « Essai : 1/2 » | Phrase d'essai | Question (Q9) |
| FI12-E23 | Mineur | Captures bureau | passe 1 : `*_1440_*` | 1440 x 900 (§10) | Passe 1 en 1440 x 1400 (page entière) | Passe 2 : 1440 x 900 pour Foyer, Finances, Mouvements, Recharge, Résultat, Paiements adulte, Revenus, Vue globale, Politiques et chaque état ajouté | Corrigé (`fi12_*_1440x900_*`, 3 ouvertes) |
| FI12-E24 | Mineur | Tablette | passe 1 : aucune | 768 (§10, « tablette / rail ») | Absente de FI-12 | Passe 2 : 768 sur 10 écrans (rail visible sur `fi12_foyer_a_regulariser_768_light`) | Corrigé |
| FI12-E25 | Majeur | Fiche > Accès | passe 1 : aucune | États erreur et hors ligne capturés | Absents | `fi12_acces_fiche_erreur_*` (« Impossible de charger ces informations », « Réessayer »), `fi12_acces_fiche_hors_ligne_*` | Corrigé |

## 4. Refus de la revue (`UX_REVIEW_08_FINANCE.md:315`), un par un

« Vérif. capture » = contrôle exécuté pendant la capture, sur l'écran rendu (`captures_fi12_test.dart`, groupe « passe 2 ») ; le test échoue si l'élément apparaît. « i18n » = `grep -c` dans `assets/i18n/fr.i18n.json` (aucun texte d'écran n'existe hors de ce fichier).

| ID | Élément refusé (maquette) | Preuve | Résultat | Statut |
|---|---|---|---|---|
| FI12-R01 | « + Recharger » en tête (03) | i18n « + Recharger » : 0 ; vérif. capture `_refusFoyer` (`textContaining('+ Recharger')` absent, `SyntheseSoldesFoyer.rechargerKey` une seule fois) sur `fi12_foyer_a_regulariser_{768_light,768_dark,1440x900_light,1440x900_dark,390_light_rtl}` ; `foyer_finances_test.dart` « un seul bouton plein » | Absent | Tenu |
| FI12-R02 | Chevron des cartes (03, 05) | `_refusFoyer` mesure `CHEVRON 3` ; `ligne_membre.dart:245` | **Présent** | Ouvert (FI12-E01) |
| FI12-R03 | « Gérer tous les enfants » (03, 05) | i18n « Gérer tous » : 0 ; `_refusFoyer` (5 captures) | Absent | Tenu |
| FI12-R04 | Panneau « Actions rapides » (05) | i18n : 0 ; `_refusFoyer` ; `fi12_planche_05_foyer` (« Dernières transactions » à sa place) | Absent | Tenu |
| FI12-R05 | « Recharger plusieurs profils » sur la page de recharge (07) | `_refusRecharge` (`t.foyer.finances.rechargerPlusieurs` absent) sur `fi12_recharge_etape1_*` (5), `fi12_recharge_etape2_*` (3), `fi12_incomplet_recharge_rien_coche_*` (4) ; `recette_fi_test.dart` refus 1 | Absent | Tenu |
| FI12-R06 | Pastille de période répétée sous l'identité (06) | `fi12_finances_a_regulariser_1440x900_light` | **Période dite deux fois** | Ouvert (FI12-E04) |
| FI12-R07 | Phrase de recharge sur la fiche (06) | `fi12_finances_a_regulariser_1440x900_light` : le bandeau dit le manque et la conservation, sans phrase de recharge ; un seul « Recharger Ibrahim » | Absente | Tenu |
| FI12-R08 | Chevrons des moyens de paiement (04, 07) | `fi12_resultat_annule_390_light` : carte de choix avec coche, sans chevron ; `chevron` dans `ligne_moyen_paiement.dart` : 0 | Absents | Tenu |
| FI12-R09 | « Paiement sécurisé et chiffré » (04) | i18n « sécurisé et chiffré » : 0 ; `_refusRecharge` (`textContaining('chiffré')` absent, 12 captures) | Absent ; voisin « Paiement web sécurisé » | Tenu, avec FI12-E10 |
| FI12-R10 | Croix du bandeau (07) | `BandeauAttention` n'a aucun paramètre de fermeture (`titre`, `message`, `ton`, `action`) ; `_refusBandeau` (bandeau présent, `AppIcons.fermer` absent) sur `fi12_finances_a_regulariser_*` (5) ; `_refusRecharge` (12) | Absente | Tenu |
| FI12-R11 | Éclat de réussite et « ! » (01) | `fi12_planche_01_resultat` : « Paiement confirmé » sans « ! », pastille sans éclat ; `recette_fi_test.dart` refus 11 | Absents | Tenu |
| FI12-R12 | « Apprentissage » (02) | i18n : 0 | Absent | Tenu |
| FI12-R13 | Coque de la direction et entrées inventées (08 à 10) | `fi12_revenus_contenu_1440x900_light` (coque Enseignant) ; `fi12_interdit_tuteur_admin_finance_390_light` (le tuteur reçoit « Vous n'avez pas accès à cette page ») | Tenu | Tenu |
| FI12-R14 | Flèches « vs mois précédent » sans donnée (08, 09) | i18n « mois précédent » : 0 ; aucune icône de tendance dans `app_icons.dart` (seul fichier autorisé à créer une icône) ; `_refusVariation` (`précédent` et `vs ` absents) sur `fi12_admin_vue_globale_*` (5) et `fi12_revenus_contenu_*` (3) | Absentes | Tenu |
| FI12-R15 | « À propos des anciennes primes » (08) | i18n « anciennes primes » : 0 | Absent | Tenu |
| FI12-R16 | Catégories inventées, histogramme mêlé (09) | i18n « Répartition des revenus », « Dernières opérations » : 0 ; aucun graphique dans `lib/features/admin_finance` (grep `BarChart` : 0) | Absents | Tenu |
| FI12-R17 | « Enregistrer les modifications » plein (10) | i18n : 0 | Absent | Tenu |
| FI12-R18 | Menu « … » et sélecteur de mois (10) | `_refusPolitiques` (`PopupMenuButton`, `DropdownButton`, `CalendarDatePicker` absents) sur `fi12_admin_politiques_historique_*` (3) et `fi12_admin_politiques_{768_light,1440x900_light,390_light_rtl}` (3) ; grep `PopupMenuButton|showMenu|DropdownButton|showDatePicker` dans `admin_finance`, `foyer`, `revenus_enseignant` : 0 | Absents | Tenu |
| FI12-R19 | Valeurs de maquette (30 $, −5 $, 2024, « par cours ») | i18n « 2024 », « par cours » : 0 ; `recette_fi_test.dart` refus 12 | Absentes | Tenu |

## 5. Refus du guide §13, un test chacun

Tests de `test/features/finance_recette/recette_fi_test.dart`, groupe « (b) refus §13 » (noms tels qu'ils sont dans le fichier ; 24 réussis dans `rc-2`, §1).

| Refus §13 | Test qui le prouve | Preuve complémentaire | Statut |
|---|---|---|---|
| Action à deux endroits | « 1. une action a deux endroits : toute recharge ouvre LE meme moteur, sur la meme route » | FI12-R05 | Tenu |
| Enfant qui consomme le solde d'un autre | « 2. un enfant ne consomme pas le solde d un autre : Ibrahim reste a regulariser malgre le solde d Aicha » | `fi12_recharge_etape2_*` (montant par profil, « pas de solde commun ») | Tenu (aucune allocation de recharge vérifiée par le test : reste à la passe 2 de `rc-1`) |
| Total utilisable comme portefeuille | « 3. le total foyer n est pas un wallet : une lecture, aucun moyen « solde du foyer » a la recharge » | « Une lecture : chaque solde reste celui de son profil » sur `fi12_foyer_a_regulariser_768_light` | Tenu |
| Avatar qui change de couleur | « 4. un avatar garde sa couleur d un ecran a l autre » | Reçu et résultat : même couleur à la capture (`fi12_mouvements_recu_390_light`, `fi12_resultat_allocation_390_light`) | Tenu (Fiche > Accès, Compte > Paiements, adulte : non relevés par le test) |
| Couleur selon l'index | « 5. la couleur de profil ne depend pas de la place dans la liste : a l envers ou en partie, chaque profil garde sa couleur » | — | Tenu |
| Statut par couleur seule | « 6. aucun statut financier par la couleur seule : chaque pastille porte son mot, deux etats d un meme ton ont deux mots » | Pastilles avec texte sur toutes les captures relues | Tenu |
| Tarif dans un widget | « 7. aucun tarif code dans un ecran (garde de source sur lib/features) » | — | Tenu |
| Mobile étiré sur bureau | « 8. le mobile n est pas etire sur bureau : a 1440, recharge et resultat restent dans leur colonne » | `fi12_*_1440x900_*` des autres écrans (Foyer en grille de trois, Finances en deux colonnes, Vue globale en grille) | Tenu pour recharge et résultat par test ; capture seule pour les autres |
| Maquette bureau compressée en mobile | **Ajouté par la passe 2 dans `rc-1`** (autre agent, en cours : absent du fichier relu le 04/10) | Planches `fi12_planche_01` à `04` (mobile) et `05` à `10` (bureau) : compositions distinctes | À citer quand le test est fusionné |
| Compte bloqué pour impayé | « 9. un impaye ne ferme pas le compte : chaque espace du tuteur reste ouvert, l acces a regulariser se dit » | Enfant : `fi12_acces_enfant_ferme_*`, `fi12_acces_enfant_groupes_ferme_*` (classes lisibles, bandeau neutre) | Tenu pour le tuteur ; capture pour l'enfant |
| Rejoindre selon le solde | « 10. Rejoindre ne depend pas du solde (garde de source ; le comportement : acces_finance_test.dart, « Rejoindre suit la periode financee, jamais le solde ») » | `fi12_acces_enfant_groupes_ouvert_*` (vrai routeur) | Tenu (garde de source étroite, voir critique) |
| Confirmation simulée | « 11. aucune confirmation de paiement simulee (garde de source ; le parcours : resultat_recharge_test.dart, « parcours de demonstration... le succes vient du port ») » | Résultat 8 états sur 8 capturés | Tenu |
| Ancien montant 20/26, 10/20, 5/10 | « 12. aucun ancien montant 20/26, 10/20 ou 5/10 (garde de source) » | FI12-R19 | Tenu |
| Backend touché | « 13. FRONTEND ONLY : aucun fichier sous supabase/ modifie depuis la base ui/finance-v1 (aebd21a5) » : tourne dans `rc-2` (commit présent) | Mesuré : `git diff --name-only aebd21a5 HEAD -- supabase/` : 0 fichier ; non suivis sous `supabase/` : 0 ; `.github`, `pubspec.yaml`, `vercel.json` : 0 | Tenu |

## 6. Données par rôle (`UX_REVIEW_08_FINANCE.md:96-106`)

| Rôle | Attendu | Preuve à l'écran | Preuve dans les données | Statut |
|---|---|---|---|---|
| Tuteur titulaire | Solde, mensualité, manque, mouvements, recharge, par enfant | `fi12_foyer_*`, `fi12_finances_*`, `fi12_mouvements_*`, `fi12_recharge_*` | `PortPaiementsFoyer.finances()` (FI-BR-03) ; `recette_fi_test.dart` refus 2 et 3 | Tenu |
| Titulaire adulte (Ma famille) | Les mêmes, dont lui | `fi12_compte_paiements_titulaire_adulte_*` | `paiements_foyer_adulte_test.dart` « Mon espace > Ma famille > Paiements du foyer, tapes : un solde… » | Tenu |
| Second adulte rattaché | Aucun solde, mensualité, manque ni recharge ; historique en lecture | `fi12_compte_paiements_second_adulte_*` (vérif. capture : `PaiementsComptePage` présent, `rechargerKey` et « Recharger » absents) ; `fi12_interdit_recharge_second_adulte_*` (vérif. `RechargeFoyerPage` absente) | `paiements_foyer_adulte_test.dart` « le second adulte rattache : l'historique seul, ni soldes, ni « Recharger », ni les enfants (E3, F7) » ; `acces_finance_test.dart` « adulte autonome : Mon espace » > « second adulte rattache : aucune finance lue, aucun bandeau ». « Jamais chargé » côté serveur : FI-BR-03 et FI-BR-18, non branchés | Tenu à l'écran ; serveur ouvert |
| Élève adulte autonome | Son seul profil | `fi12_adulte_*` (passe 1), `fi12_adulte_paiements_{768_light,1440x900_light,390_light_rtl}` | `mes_finances_test.dart` (32), port `PortMesFinances` (FI-BR-17) | Tenu |
| Élève enfant | Ni montant, ni cause, ni mouvements, ni recharge | `fi12_acces_enfant_*` (passe 1) et `fi12_acces_enfant_groupes_*` (vérif. `_enfantSansArgent` : aucun « $ », aucun « régulariser », 7 captures) | `AccesBeneficiaire` ne porte aucun montant ; `acces_finance_test.dart` (copie neutre, Rejoindre absent) | Écran tenu ; donnée ouverte (FI12-E13) |

## 7. États du guide §10, écran par écran

« P1 » : capture de la passe 1 ; « P2 » : passe 2. « — » : l'état n'existe pas sur cet écran, avec la raison.

| Écran | loading | empty | success | error | forbidden | incomplete | stale | concurrent / pending |
|---|---|---|---|---|---|---|---|---|
| Foyer | P2 | P1 `foyer_aucun_paiement` | P1 | P1 | — (route du tuteur ; un autre rôle est redirigé, `test/router` 279 verts) | — (rien ne se saisit) | — | — |
| Fiche > Finances | P2 | P1 `finances_vide` | P1 | P1 | — | — | — | — |
| Mouvements, reçu | P2 | P1 `mouvements_vide` | P1, P2 `mouvements_recu` | P1 | — | — | — | Paiement en confirmation sans reçu (`fiche_eleve_mouvements_test.dart`) |
| Recharge | P2 | P1 `recharge_production` | P1 | P1 | P2 `interdit_recharge_second_adulte` | P2 `incomplet_recharge_rien_coche` | — | — |
| Résultat | P2 | P1 `resultat_vide` | P1 `resultat_termine` | P1 `resultat_echec`, `resultat_erreur` | — | — | P1 `resultat_perime` | P1 `resultat_attente` ; P2 `resultat_preparation`, `resultat_confirme`, `resultat_allocation`, `resultat_annule` |
| Fiche > Accès | non capturé | — | P1 | P2 `acces_fiche_erreur`, `acces_fiche_finance_en_echec` | — | — | — | — |
| Compte > Paiements | non capturé | P2 `compte_paiements_production` | P2 | non capturé | P2 second adulte (lecture seule) | — | — | — |
| Enfant (Accueil, Mes groupes) | non capturé | — | P1, P2 | — | Accès fermé : P1, P2 `acces_enfant_groupes_ferme` | — | — | — |
| Mes finances (adulte) | non capturé | P1 `adulte_vide` | P1 | P1 | — | — | — | — |
| Revenus | non capturé | P1 `revenus_vide` | P1 | P1 | — | — | — | — |
| Vue globale | P2 | P1 `admin_vue_globale_vide` | P1 | P1 | P2 `interdit_tuteur_admin_finance` | — | — | — |
| Politiques | P2 | — (une version active existe toujours) | P1 | P1 | — | P2 `admin_politiques_coherence` | — | P2 `admin_politiques_publier` |

Hors ligne : P1 pour chaque écran sauf Compte > Paiements ; P2 `acces_fiche_hors_ligne`.

## 8. Besoins serveur

La table des FI-BR rendus par les ports, ce qui manque côté serveur pour chacun, et les corrections de références proposées (LOT-E vers FI-BR-08 ; EA-BR-24/25 vers FI-BR-06 ; EA-BR-23 vers FI-BR-03) sont reportées dans `17_finance/FI-BR.md`, section « Relu par FI-12 (04/10) ». Ports concernés (`rc-2`) : `port_politiques_commerciales.dart` (FI-BR-01, 02), `port_paiements_foyer.dart` (FI-BR-03, 05 ; DB-CPT-03 ; EA-BR-23), `port_recharge_foyer.dart` (FI-BR-06 ; EA-BR-24, 25), `port_revenus_enseignant.dart` (FI-BR-11), `port_finance_direction.dart` (FI-BR-12), `port_mes_finances.dart` (FI-BR-17), `port_accents_profils.dart` (FI-BR-19), `port_acces_foyer.dart` (LOT-E). FI12-E13 ajoute une exigence à FI-BR-08.

## 9. Questions au directeur

1. **Q1 (FI12-E02)** : bouton principal du Foyer, « Ajouter un profil élève » (aujourd'hui) ou « Recharger plusieurs profils » (Q-FI-2) ?
2. **Q2 (FI12-E05)** : la carte du Foyer doit-elle dire « Période à financer octobre 2026 », comme la fiche ?
3. **Q3 (FI12-E06)** : une seule source pour la classe de l'enfant dans la démonstration ?
4. **Q4 (FI12-E10)** : « Paiement web sécurisé. Aucun débit avant votre confirmation. » reste-t-il, ou tombe-t-il avec « Paiement sécurisé et chiffré » ?
5. **Q5 (FI12-E11)** : « Tout sélectionner » sur la recharge : retiré (E-14) ou gardé ?
6. **Q6 (FI12-E12)** : quand la finance ne se lit pas, Fiche > Accès doit-elle le dire ?
7. **Q7 (FI12-E18)** : la recharge de l'adulte ouverte directement coche-t-elle son profil d'office ?
8. **Q8 (FI12-E20)** : « État des paiements » et « Top classes » de la Vue globale dans cette vague ?
9. **Q9 (FI12-E22)** : phrase de l'accès d'un enfant en essai.
10. **Q-FI-10** (déjà posée) : Revenus depuis le Profil (fait) ou le Compte ?
11. **Q2 de `17_finance/QUESTIONS.md`** (« business plan ») reste ouverte.

## 10. Ce qui reste hors de ce rapport

- Le test du refus « maquette compressée » (`rc-1`, passe 2 de l'autre agent) et les compléments des sections 1, 3, 5 et 6 de la critique (allocations du refus 2, couleur sur les autres écrans, mobile étiré sur six écrans, impayé de l'adulte, garde de Rejoindre, accessibilité clavier et lecteur d'écran) : à citer ici quand ils sont fusionnés.
- §14 « high-fi Tuteur mobile et desktop reproduites » : **non atteint**. Les planches `fi12_planche_01` à `07` montrent les écarts FI12-E01 à E04 et E07 à E09.
- La revue croisée FI-R et la planche du directeur FI-RC.
