# Intégration de nuit — 05/10/2026

But : vérifier que toutes les corrections vérifiées de la nuit tiennent ensemble sur la branche commune à jour.
Branche : `ccr-1b1bfa0b-m1kvkk`, construite depuis 5af09eb3 (3 commits de doc `docs/orchestration/`). Chaque fusion est un `git merge --no-ff`, suivi d'une analyse complète (`dart analyze --fatal-infos`, 0 problème attendu) avant la fusion suivante.
Fichiers i18n générés (`lib/core/i18n/strings*.g.dart`) : jamais résolus à la main. On a pris un côté puis relancé `dart run slang` à chaque fois. `build_runner` relancé à la fin : aucun écart.
Aucun fichier modifié dans `supabase/`, `pubspec.yaml`, `.github/`, `vercel.json`. Aucun fichier du Coran modifié par l'intégration (voir la note en bas).

## Fusions

| # | Branche | Hash | Étapes | Conflits et résolution | Analyse |
|---|---|---|---|---|---|
| 1 | corrections/revue-directeur-2026-10 | 29a4fc83 | branche commune à jour (c2-* fusionnées) | aucun | 0 |
| 2 | corrections/jur-app-1 | 2f725aa6 | JUR-APP-1 | `fr.i18n.json` : blocs a3/e1/clauseControle de JUR ajoutés ; `signature.horsLigne` garde le texte de la branche commune (EA-HL-DOUBLE-1, sans « Vous êtes hors ligne. »), que JUR ne modifiait pas | 0 |
| 3 | corrections/salle-err-320-1 | d5742304 | SALLE-ENCRE-1, SALLE-CORR-4 m10, SALLE-ERR-320-1, réparation journee_page (contient c1-salle et l'ancien JUR 8c6b50dd) | i18n générée seulement. Vérifié : `lib/features/salle_seance/` est identique octet pour octet à JUR 2f725aa6 (chrome_seance, cible_debordante, information_controle, mention_seance, salle_seance) ; l'encre m10 vit dans `salle_page.dart` et elle est présente | 0 |
| 4a | corrections/coupe-mots-1b | b6efe6a1 | COUPE-MOTS-1b | aucun (chrome_seance et salle_seance = JUR + COUPE-MOTS) | 0 |
| 4b | corrections/enseignant-mineurs-1 | fe33eaf0 | LIB-ERR-2, EN-7c-MINEURS | `journee_page.dart` : les deux côtés gardés (`coursAnnule: _retrouverParId(...)` de la réparation INTEG-SALLE + `phrasePartielle` de LIB-ERR-2) | 0 |
| 4c | corrections/capt-l1-2 | 473aea68 | CAPT-L1-2 | aucun (captures et tests de capture seulement, ancêtre de 4d) | 0 (mesuré après 4d) |
| 4d | corrections/onglets-coupe-1 | 342558bc | ONGLETS-COUPE-1 | aucun | 0 |
| 5a | corrections/ctrl-msg-2 | bc0e8963 | CTRL-MSG-2, COUPE-MOTS-CTRL-1 (base c1-ctrl : CTRL-MSG-1, CTRL-SEANCE-1, CTRL-DELAI-1, CTRL-RETOUR-1) | `libelles_sources.json` en union. **1 erreur d'analyse** : `roster_prenom_initiale_test` (CTRL-ROSTER-C7-1, branche commune) surchargeait `rosterControleProvider` sans paramètre, alors que CTRL-SEANCE-1 l'a passé en `.family(seanceId)`. Corrigé dans **8f4f8869** (surcharge `(Ref, String)`) | 1 → 0 |
| 5b | corrections/ma-apres-1b | 172a1944 | MA-APRES-1b, MA-APRES-1, MA-DEC-1, MA-TUTOIEMENT-1, MA-CORAN-TETE-1 (base c1-ma) | `accueil_accessibilite.dart` : imports de DASH-MA-PROD gardés ; salutation = `TexteSansCoupure(_insecable(...))` de la branche commune + commentaire MA-DEC-1 (c1-ma ne faisait qu'envelopper la salutation dans TexteSansCoupure). `libelles_sources.json` en union | 0 |
| 6a | corrections/classe-live-encre-1 | 1d4a3987 | CLASSE-LIVE-ENCRE-1, ENS-PAYS-1, FORM-L8 e0c881ce (base c1-integ2 : c1-lib, c1-form-a/b, AD-NETTOYAGE…) | `journee_page.dart` : LIB-ERR-2 et LIB-LOT3-2 font le même travail sous deux clés, arbitrage A1 ; `accueil_eleve_page.dart` : imports des deux côtés (pays_enseignant + raccourci_tactile, setting_row) ; `comptes_test.dart` : `monter(echusSeulement)` de la branche commune + surface haute 800×2400 d'AD-NETTOYAGE ; JSON en union (arbitrages L1 à L4). **1 erreur d'analyse** : `journee_test` (LIB-LOT3-2) lisait `erreurPartielleCahiers`. Corrigé dans **bf2548bd** | 1 → 0 |
| 6b | corrections/form-l8-9 | 73734b66 | FORM-L9-VERSET, FORM-L9 | i18n générée seulement | 0 |
| 6c | corrections/ad-nettoyage-2 | d52314cb | AD-NETTOYAGE-2, AD-M2-CAPT | `attente.illisible` / `attente.horsLigne` : arbitrage L5 | 0 |
| 6d | corrections/form-corr-1 | b7984358 | FORM-CORR-1, FORM-MINEURS | `data_collection.dart` et `programmes_page.dart` : arbitrage A2 ; `catalogue_galerie_test` : `PaysEnseignant` et `ChampEtiquete` gardés tous les deux ; le passage à ChampEtiquete de FORM-CORR-1 est gardé | 0 |
| R | réparation | d8e4417d | après la suite de tests | deux textes réparés, voir L1 et L6 | 0 |

## Arbitrages

**Code**
- **A1 — message d'échec partiel de Ma journée.** Deux implémentations du même comportement :
  - LIB-ERR-2 (enseignant-mineurs-1) : `phrasePartielle`, clé `erreurPartielleRetards` ;
  - LIB-LOT3-2 (c1-lib) : `messagePartiel`, clé `erreurPartielleCahiers`.

  On garde le code et les clés de LIB-ERR-2, déjà en place sur la branche commune avec la réparation INTEG-SALLE. La clé `erreurPartielleCahiers` disparaît, et son test suit la clé gardée. Aucun comportement perdu : les deux disent ce qui manque (horaires, cahiers, ou les deux).
- **A2 — liste qui défile avec la page.** Deux implémentations :
  - ONGLETS-COUPE-1 : `DataCollection.defileAvecLaPage` + `PlaceCollection`, actif dès que la vue est en cartes (hors desktop) ;
  - FORM-MINEURS : `DataCollection.integree` + `_SelonDefilement`, actif hors desktop quand le texte dépasse 130 %.

  Le cas de FORM-MINEURS est compris dans celui d'ONGLETS-COUPE-1. On garde donc ONGLETS-COUPE-1, et le paramètre `integree` est retiré (il ne servait qu'à `programmes_page`). Tests admin_pedagogie_programmes, mise en page Pédagogie, FORM-L2/L4 et champ_date_320 : 86/86 verts.

**Textes (`fr.i18n.json` et `tool/libelles_sources.json`)**
- **L1** `enseignant.journee.erreurPartielleRetards` / `erreurPartielleTout` (texte).
  - D'abord : texte de LIB-ERR-2, la correction la plus récente (« les cahiers à terminer »).
  - Ensuite : `libelles_lot3_test` (LIB-CAHIER-1) exige « cahiers de transmission ». On a donc pris les textes vérifiés de LIB-LOT3-2 (« Vos cahiers de transmission à terminer… », « …vos pauses et vos cahiers de transmission à terminer… »). Les clés et le code de LIB-ERR-2 restent.
- **L2** `libelles_sources` `enseignant.cahier.echecEnvoi` : source corrigée par INTEG-MINEURS-1 (« EN-7c (058c5251)… »), plus récente que la note LIB-CAHIER-1.
- **L3** `libelles_sources` `eleve.accueil.erreurCours` : version de la branche commune (DASH-ELV-ERR-b, plus complète).
- **L4** `libelles_sources` `controleur.compteRendu.visiteInconnueAide` : version CTRL-MSG-2 (plus récente que CTRL-MSG-1).
- **L5** `attente.illisible` / `attente.horsLigne` : les deux intentions combinées.
  - AD-NETTOYAGE-2 remplace « dossier » par « compte » ;
  - EA-HL-DOUBLE-1 retire « Vous êtes hors ligne. ».
  - Résultat : « L'état de votre compte ne s'affiche pas pour le moment. » / « L'état de votre compte s'affichera dès le retour du réseau. »
- **L6** `accessibilite.apres.horsLigne` / `horsLigneVous` (MA-APRES-1) : « Tu es / Vous êtes hors ligne : » retiré, selon la règle EA-HL-DOUBLE-1 (l'écran est dans PageShell, dont le bandeau le dit déjà). C'était une régression de jonction mesurée par `etat_sans_donnees_test`. Les captures MA-APRES-1 de l'état hors ligne montrent encore l'ancien texte : elles n'ont pas été refaites.

**Non tranché (à décider par le directeur)**
- **N1** `enseignant.journee.aTerminerVide` (« Tous vos cahiers sont terminés. »), `aTerminerSansDonnees`, `aTerminerErreur` (« Les cahiers à terminer… ») : ces textes viennent de la branche commune (DASH-ENS-b, EA-HL-DOUBLE-1). DASH-ENS-b a retiré « transmission » exprès, parce que le mot était coupé à 320 px avec le texte à 200 %. LIB-CAHIER-1 (test `libelles_lot3_test`, c1-lib) exige « cahier de transmission » partout. Les deux règles se contredisent sur ces trois clés, donc le test reste rouge.

## Chiffres (tête d8e4417d puis ce document)

- `dart analyze --fatal-infos` complet : **0 problème**.
- `dart run tool/verifier_jetons.dart` : **31 violations**. Pour comparaison :

  | Branche | Violations |
  |---|---|
  | branche commune 29a4fc83 | 39 |
  | JUR 2f725aa6 | 39 |
  | chaîne salle d5742304 | 39 |
  | coupe-mots, enseignant-mineurs, onglets-coupe, ctrl-msg-2, ma-apres-1b | 39 chacune |
  | c1-integ2 (classe-live-encre-1, form-l8-9, ad-nettoyage-2) | 32 |
  | form-corr-1 | 31 |

  Explication : c1-integ2 retire 8 violations (6 `duree-litterale` des démonstrations du contrôleur, 2 `direction-non-geree` `EdgeInsets.fromLTRB` de salle_seance) et en ajoute 1 (`ontap-nu` de champ_date, FORM-L2/L4). FORM-CORR-1 retire celle-ci (ChampDate en Pressable). L'intégration est l'union des retraits, **aucune violation nouvelle** : la comparaison ligne à ligne avec la branche commune donne 8 retraits et 0 ajout.
- `dart run tool/verifier_revue.dart` : **1610**. Détail :

  | Règle | Nombre |
  |---|---|
  | libelle-sans-source | 1546 |
  | bouton-grise | 34 |
  | plein-multiple | 17 |
  | affirmation-reseau | 5 |
  | avatar-taille | 4 |
  | avatar-recompose | 3 |
  | bouton-recompose | 1 |

  Les branches sources sont entre 1573 (branche commune) et 1636 (salle). L'écart vient surtout des nouveaux libellés ajoutés par l'union des branches.

### Tests par dossier (sous `flock /tmp/flutter.lock`, un dossier à la fois)

| Dossier | Résultat |
|---|---|
| accessibilite | +349 **-2** |
| agent | +18 |
| appairage | +12 |
| cache | +11 |
| capacites | +37 |
| capture | +0 ~1199 (sautés sans CAPTURE_DIR) |
| config | +11 |
| coran | +25 |
| core | +685 (après d8e4417d ; avant : +684 -1) |
| foyer | +18 |
| i18n | +7 |
| icons | +4 |
| mouvement | +13 |
| observabilite | +11 |
| parcours | +44 |
| planning | +23 |
| presence | +20 |
| priere | +15 |
| router | +300 |
| seance_famille | +25 |
| suivi | +16 |
| tc_observation | +19 |
| teaching_core | +1338 ~76 |
| theme | +70 |
| tool | +32 |
| video | +43 |
| widgets | +298 |
| test/tool_source_echec_envoi_test.dart | +1 |
| features/accessibilite_recette | ~93 |
| features/accueil_adulte | +80 |
| features/admin_configuration | +12 |
| features/admin_dossiers | +79 |
| features/admin_observations | +19 |
| features/admin_pedagogie_programmes | +13 |
| features/admission | +3 |
| features/adulte_recette | +224 ~641 |
| features/appareils | +101 ~211 |
| features/cahier | +28 ~44 |
| features/classe_eleve | +34 ~25 |
| features/classe_enseignant | +37 ~24 |
| features/classe_live_encre1 | +6 |
| features/classe_recette | +28 ~30 |
| features/classe_tuteur | +106 ~54 |
| features/compte | +47 |
| features/controleur | +222 |
| features/controleur_recette | +6 ~186 |
| features/creneaux | ~19 |
| features/demo | +109 ~10 |
| features/ens_pays1 | +49 |
| features/enseignant_classes | +24 |
| features/enseignant_recette | +6 ~233 |
| features/fiche_eleve | +5 ~13 |
| features/foyer | +277 ~37 |
| features/historique | +33 |
| features/journee | +48 ~30 |
| features/ma_classe_adulte | +15 |
| features/mon_espace_adulte | +79 |
| features/notifications | +8 |
| features/profil_enseignant | +21 ~30 |
| features/revue_groupe | ~12 |
| features/salle_seance | +515 ~361 |
| features/tc_espace_groupe | +8 |
| features/*_test.dart (racine, paquet 1/4) | +325 ~14 |
| features/*_test.dart (racine, paquet 2/4) | +142 |
| features/*_test.dart (racine, paquet 3/4) | +203 ~6 **-1** (relancé après d8e4417d : même résultat, N1) |
| features/*_test.dart (racine, paquet 4/4) | +209 ~84 |
| **Total** | **6566 réussis, 3432 sautés, 3 échecs** |

Après la fin de la suite, seuls les dossiers touchés par d8e4417d ont été relancés : core, journee, journee_test, libelles_lot3, ma_apres1/1b, accessibilite, paquet racine 3.

## Échecs restants et leur origine

1. `test/accessibilite/ma11_technique_test.dart` : « salle, mariam » et « salle, idriss » (2 échecs).
   - Constat : une cible clavier fait 16 px de haut (`Rect.fromLTRB(32, 84, 201.7, 100)`). C'est le lien « En savoir plus » du bandeau de la salle, posé par JUR-APP-1 en lien « sans hauteur » avec une cible débordante (`CibleDebordante`). MA-11 mesure le rectangle de focus, qui fait 16 px.
   - Origine : **déjà rouge sur `corrections/jur-app-1` @ 2f725aa6 seule** (mesuré : même échec, mêmes coordonnées). Ce n'est pas une régression de fusion.
   - À décider : agrandir le rectangle de focus du lien, ou faire mesurer à MA-11 la cible débordante.
2. `test/features/libelles_lot3_test.dart` (LIB-CAHIER-1) : 1 échec.
   - Origine : vraie contradiction entre DASH-ENS-b (branche commune) et LIB-CAHIER-1 (c1-lib) sur trois libellés (N1). Rouge seulement depuis la jonction des deux lignées. Non tranché.

## Note sur le Coran

La fusion de `ma-apres-1b` apporte MA-TUTOIEMENT-1 (c1-ma, vérifiée). Cette correction touche `lib/features/tc_mushaf/` : `textes_lecteur_coran.dart`, `vue_page_mushaf.dart`, `vue_verset_agrandi.dart`. Ce sont les phrases des états sans texte ; le rendu du Coran n'est pas modifié, selon sa fiche. L'intégration n'y a rien modifié elle-même. On le signale parce que la règle K-19 met ce dossier hors périmètre.
