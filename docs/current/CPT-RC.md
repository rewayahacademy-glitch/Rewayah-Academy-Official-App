# CPT-RC : corrections de la revue Comptable (CPT-R)

Branche `ui/comptable-v1`, partie de `8fb00a71` (code revu par CPT-R). Rapport de revue : `REVUE_CPT-R.md` (pilotage). Spec : `20_comptable/V/REWAYAH_FINANCE_OPERATIONNELLE_COMPTABLE_V1.md`.

Style (K-63) : aucune couleur, police, rayon ou ombre venus des maquettes. Seuls des jetons existants sont utilisés (`AppRadius.arrondiLg`, `AppPage.largeurFormulaire`, `AppGabarit.seuilTexteColonne`). Aucun fichier `supabase/`, `.github/`, `pubspec.yaml`, `vercel.json`, `lib/core/theme`, ni aucun fichier du Coran n'a été touché (`git diff 8fb00a71 --stat` sur ces chemins : vide).

## 1. Correction par correction

| # | Revue | État | Ce qui a été fait | Preuve |
|:--|:--|:--|:--|:--|
| 1 | M1 démo réelle | **Fait** | `dependencies: <ProviderOrFamily>[port…]` ajouté sur les 23 lectures dérivées de `tresorerie_donnees.dart` (7), `etat_beneficiaires.dart` (3), `contractuels_commun.dart` (4), `etat_mes_moyens.dart` (2), `donnees_encaissements.dart` (3) et `donnees_rapprochement.dart` (4). `cpt_capt_recette_test.dart` passe désormais `racine: false` par défaut, et le test d'écart `ecart_route_demo_*` est retiré (il n'a plus d'objet). | Nouveau test `test/features/comptable/socle/route_demo_reelle_test.dart` : 16 écrans × 2 largeurs, `routesDemoComptable('staging')` dans un `ProviderScope` **nu**. Sur `8fb00a71` : **16 échecs** (8 écrans : beneficiaires, profilPaiement, tresorerie, alimenter, contractuels, obligationContractuel, nouvelleObligation, recevoirPaiements). Après correction : **32/32**. |
| 2 | M2 catalogue et galerie | **Fait** | `ligne_destination.dart` renommé en `ligne_destination_masquee.dart`, avec 5 imports mis à jour. Ajout de `BasculeMontants` (3 états), `MontantSensible` (3), `LigneDestinationMasquee` (3) et de la famille `PastillesComptable` (9 états, un par pastille) dans `composantsDuCatalogue`, avec leurs commentaires de lot, et dans la galerie (`lib/features/_dev/galerie/entrees_etats_comptable.dart`). | `flutter test test/widgets` : **+234, 0 échec** (CPT-R mesurait −1). |
| 3 | M3 en-tête 320 ×2 | **Fait** | `EntetePage` empile le retour et les actions au-dessus du titre dans trois cas : le mot le plus long ne tient pas à côté (comportement déjà présent) ; la largeur laissée au titre est inférieure à `partMinTitre` (la moitié de la colonne) ; ou, sur téléphone, le texte atteint `AppGabarit.seuilTexteColonne` (1,5). | `test/features/comptable/socle/entete_320_test.dart` (vraies polices), sur Attention, Détail du paiement et Obligation de contractuel. Sur `8fb00a71` : **3 échecs** (« titre composé dans 176 px sur 288 »). Après correction : 3/3. Le test vérifie que le titre a toute la largeur de l'en-tête, qu'aucun mot n'est coupé et qu'un texte du contenu apparaît dans le premier écran, au-dessus de la barre basse. Captures ouvertes : §4. |
| 4 | m3 compteur | **Fait** | Sur le bureau, la zone d'Aujourd'hui qui exclut les paiements s'intitule désormais « À traiter, hors paiements » (nouvelle clé `comptable.aujourdhui.aTraiterHorsPaiements`, déclarée dans `tool/libelles_sources.json`). **Libellé à valider par le directeur.** | `aujourdhui_page_test.dart`, groupe « compteurs » : chaque titre de section porte un seul nombre sur le bureau, le téléphone et la file complète (1440 et 390). La donnée de démonstration distingue bien les deux nombres (6 ≠ 8). |
| 5 | m6 R-FIN-12 | **Fait** | Ajout de `test/features/comptable/beneficiaires/r_fin_12_admin_test.dart`. Il couvre deux cas : l'admin consulte un enseignant dans les comptes (ADM-08) et ne voit aucun « Modifier les coordonnées » ; l'admin envoyé vers le profil de paiement est renvoyé vers `/admin`, sans `ProfilPaiementPage`. | 2/2. |
| 6 | m1 sous-dossier | **Fait** | `CarteReserveStrategique`, `LigneActivite` et `ResumeTresorerie` sont inscrits au catalogue et dans la galerie (2 états chacun). Le contrôle « chaque fichier de lib/core/widgets a son entrée » lit maintenant les sous-dossiers (`listSync(recursive: true)`). | `test/widgets` vert, voir la ligne 2. |
| 7 | m4, m5 bureau 1440 | **Fait, sauf la densité de la liste** | Nouvelle obligation : le formulaire et son pied sont bornés à `AppPage.largeurFormulaire` et calés au début de la ligne. Trésorerie : la synthèse occupe toute la largeur. Aujourd'hui : les deux cartes de tête ont la même hauteur (`IntrinsicHeight`), et « Voir tout » sur Alertes aligne les trois titres de colonne. La bascule des montants porte le mot d'état sur toutes les pages (`avecEtat: true`) ; elle s'efface seule sur téléphone et quand le texte est agrandi. **Reporté** : une liste de choix des bénéficiaires plus dense. Il faudrait une variante compacte de `ChoiceCardGroup` (composant partagé, ADR-013), ce qui est une décision de design. | Captures 1440 (§4). Test d'encaissements ajusté : il appuie sur le bouton de la bascule (`BasculeMontants.cleBouton`) et non plus sur le composant entier. |
| 8 | m7, m8 | **Fait pour E3, E4 et E5. Reporté pour E6, E8 et E9** | E3 : au-delà de `seuilTexteColonne`, la barre collante de W06 ne garde que l'erreur et le bouton ; la phrase d'aide passe en tête du corps, qui défile. E4 et E5 : `StatusPill` passe de `arrondiFull` à `arrondiLg`. Le rendu est identique sur une ligne (le rayon est ramené à la demi-hauteur) ; sur plusieurs lignes, la forme devient un rectangle arrondi et le bord ne touche plus le texte. **Reportés** : E6 (gabarit de l'interrupteur de délégation, Direction) ; E8 (vide de la coquille `admin_shell` partagée, qui touche tous les écrans admin et doit être coordonné avec leurs propriétaires) ; E9 (alignement d'une pastille dans `DataCollection`). | `entete_320_test.dart` : W06 à 320 ×1 (l'aide reste dans la barre) et à ×2 (l'aide est dans un `Scrollable`). Captures (§4). |
| 9 | m9 CPT-BR-02 | **Phrase rendue, non poussée** (fichier de pilotage) | Voir §3. | |
| 10 | m2 registre | **Non fait : attend Q-D4** | | |

## 2. Critères §61 (spec), un par un

| Critère | État | Preuve |
|:--|:--|:--|
| Aujourd'hui existe | Oui | `aujourdhui_page_test.dart` ; route réelle `aujourdhui` dans `route_demo_reelle_test` |
| Paiements à effectuer existe | Oui | `paiements_page_test.dart` ; route réelle `paiements` |
| Paiement individuel existe | Oui | `confirmation_payout_test.dart` (R-FIN-04, R-FIN-18) |
| Paiement en lot existe | Oui | `confirmation_payout_test.dart`, groupe « le lot (§41) », R-FIN-22 et 23 |
| Détail explicable existe | Oui | `detail_paiement_test.dart` (R-FIN-16, 17) ; route réelle `detailPaiement` |
| Contractuels existent | Oui | `contractuels_page_test.dart`, `obligation_contractuel_page_test.dart`, `nouvelle_obligation_page_test.dart` ; routes réelles (vides sur `8fb00a71`, remplies depuis M1) |
| Encaissements existent | Oui | `encaissements_test.dart` ; routes réelles `encaissements`, `detailEncaissement` |
| Rapprochement existe | Oui | `rapprochement_test.dart` ; route réelle `rapprochement` |
| Trésorerie existe | Oui | `tresorerie_page_test.dart` ; route réelle `tresorerie` (vide sur `8fb00a71`, remplie depuis M1) |
| Coffres existent | Oui | `tresorerie_page_test.dart`, `transfert_interne_test.dart` |
| Réserve stratégique existe | Oui | R-FIN-05 à 07 (`tresorerie_page_test.dart:138-183`) ; `CarteReserveStrategique` en galerie |
| Objectif dynamique existe | Oui | R-FIN-06 (`objectifMois`, 1, 6 et 12 mois) ; mode montant fixe R-FIN-07 |
| Alimentation auto configurable représentée | Oui | `strategic_reserve_policy_panel_test.dart`, `saisie_politique_test.dart` (R-FIN-08, 09) ; route réelle `alimenter` |
| Montants masqués existent | Oui | R-FIN-01 à 03 (`visibilite_montants_test.dart`, `montant_sensible_test.dart`) ; galerie `MontantSensible` et `BasculeMontants` |
| Self-payout bloqué | Oui | R-FIN-15 (`detail_paiement_test.dart`, `paiements_page_test.dart`) ; contre-épreuve de CPT-R |
| Staff ne modifie pas les coordonnées | Oui | R-FIN-11 (`beneficiaires_test.dart`) ; **R-FIN-12 a désormais son test dédié** (`r_fin_12_admin_test.dart`) |
| Bénéficiaire self-service existe | Oui | R-FIN-13 et 19 (`recevoir_paiements_test.dart`) ; route réelle `recevoirPaiements` (vide sur `8fb00a71`, remplie depuis M1) |
| Communications réutilisé | **Partiel** | R-FIN-21 tenu (aucune messagerie Finance) ; R-FIN-20 est différé à CPT-COM, comme prévu par le plan (`00_REPRISE.md` §5) |
| États d'erreur existent | Oui | groupes « etats » de chaque page (chargement, vide, erreur, indisponible, hors ligne) |
| Responsive existe | Oui | `mise_en_page_320_test.dart`, `entete_320_test.dart` (nouveau), `demo_320_x2_test.dart` ; captures 320 ×2, 390 et 1440 (§4) |
| Accessibilité existe | Oui | `test/accessibilite` (voir §5) ; lecteur d'écran de `LigneDestinationMasquee` ; aucun mot coupé (`verifierEcranSansMotCoupe`) |
| Design harmonisé | Oui | jetons 39 → 39 ; galerie à 0 échec ; captures ouvertes (§4) |
| Devoir de regard livré | Oui | `DEVOIR_DE_REGARD_FINANCE.md` (DR-01 à DR-25), revue CPT-R §1 |
| Zéro backend modifié | Oui | `git diff 8fb00a71 --stat -- supabase .github pubspec.yaml vercel.json` : vide |

Questions toujours ouvertes pour le directeur (CPT-R) : Q-D1 (boucle de validation), Q-D2 (pourcentages sous le masque), Q-D3 (arabe), Q-D4 (registre).

## 3. Phrase pour CPT-BR-02 (m9)

À ajouter dans `20_comptable/CPT-BR.md`, section CPT-BR-02 :

> Le serveur refuse `dejaSoumis` pour toute seconde soumission d'une même obligation dans une même version (obligation, version), **quelle que soit la clé d'idempotence** : une feuille de confirmation fermée puis rouverte après « issue inconnue » tire une clé neuve, et seul ce refus empêche alors un double paiement.

## 4. Captures (`docs/current/captures/CPT-RC/`)

Les 119 captures de `test/capture/cpt_capt_recette_test.dart` ont été régénérées (`CAPTURE_DIR=docs/current/captures/CPT-RC`, +120, 0 échec), **depuis la vraie coquille de démonstration, sans aucune surcharge à la racine** (M1). Formats : 390 ×3 clair et sombre, 1440 clair et sombre, 320 ×2 texte ×2, variantes montants affichés, RTL.

Captures ouvertes et vérifiées à l'œil :
- `attention_320x640@2_texte2_light_masques` : le retour et la bascule sont au-dessus du titre ; le titre « À traiter et alertes » tient sur deux lignes (aucun mot isolé), suivi du sous-titre ; la section « À traiter aujourd'hui 8 » commence dans le premier écran.
- `detailPaiement_320x640@2_texte2_light_masques` : « Détail du paiement » sur deux lignes, la phrase sur quatre lignes à pleine largeur ; le nom du bénéficiaire commence dans le premier écran.
- `obligationContractuel_320x640@2_texte2_light_masques` (W06) : la barre collante se réduit au seul bouton « Payer » ; la phrase d'aide est dans le corps ; la carte « Facture #024 » est visible.
- `tresorerie_1440x900@1_light_masques` : écran auparavant vide sur la vraie route, il montre maintenant les données. La synthèse occupe toute la largeur, et « Montants masqués » est écrit à côté de la bascule.
- `recevoirPaiements_390x844@3_light_masques` : écran auparavant « Pas encore disponible » sur la vraie route, il montre maintenant l'avis, l'état et le bouton.
- `aujourdhui_1440x900@1_dark_masques` : les deux cartes de tête ont la même hauteur, et « Voir tout » apparaît sur Alertes. **Écart restant** : le nouveau titre « À traiter, hors paiements » passe sur deux lignes à 1440 et décale à nouveau sa colonne d'environ 16 px. Une formulation plus courte réglerait ce point ; elle relève du choix du directeur sur ce libellé.
- `nouvelleObligation_1440x900@1_light_masques` : le formulaire et le bouton sont bornés à 640 px. Les cartes de choix gardent leurs 112 px de haut (la densité est reportée, voir la ligne 7).

## 5. Contrôles et dernier passage de la suite

Tout a tourné sous `flock /tmp/flutter.lock`, au commit `d6092049` (code final ; seuls ce rapport et les captures sont venus ensuite).

| Contrôle | Résultat |
|:--|:--|
| `dart analyze --fatal-infos` (dépôt entier) | **No issues found**, sortie 0 |
| `dart run tool/verifier_jetons.dart` | **39 violations** (39 → 39), aucune dans les fichiers touchés |
| `dart run tool/verifier_revue.dart --detail` | **0** violation sur `comptable.*` |
| `dart run slang` | régénéré pour la nouvelle clé `aTraiterHorsPaiements` |

**Dernier passage de la suite complète**, dossier par dossier (05/10, 04:10:54Z à 04:28:29Z) :

| Dossier | Passés | Sautés | Échecs |
|:--|--:|--:|--:|
| accessibilite | 314 | 0 | 0 |
| agent | 18 | 0 | 0 |
| appairage | 12 | 0 | 0 |
| cache | 11 | 0 | 0 |
| capacites | 41 | 0 | 0 |
| capture | 0 | 790 | 0 (sautés sans `CAPTURE_DIR`) |
| config | 11 | 0 | 0 |
| coran | 25 | 0 | 0 |
| core | 731 | 0 | 0 |
| features | 3 408 | 2 708 | 0 |
| foyer | 18 | 0 | 0 |
| i18n | 7 | 0 | 0 |
| icons | 4 | 0 | 0 |
| mouvement | 13 | 0 | 0 |
| observabilite | 10 | 0 | 0 |
| parcours | 44 | 0 | 0 |
| planning | 23 | 0 | 0 |
| presence | 20 | 0 | 0 |
| priere | 15 | 0 | 0 |
| router | 279 | 0 | 0 |
| seance_famille | 25 | 0 | 0 |
| suivi | 16 | 0 | 0 |
| tc_observation | 19 | 0 | 0 |
| teaching_core | 912 | 55 | 0 |
| theme | 82 | 0 | 0 |
| tool | 32 | 0 | 0 |
| video | 43 | 0 | 0 |
| widgets | 234 | 0 | 0 |
| **Total** | **6 367** | **3 553** | **0** |

Plus la recette de captures avec `CAPTURE_DIR` : +120, 0 échec.
