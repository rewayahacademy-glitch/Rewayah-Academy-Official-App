# FI-12 : rapport de recette de la vague Finance

Écrit le 04/10/2026. Base de code : worktree `rc-2`, branche `rc-2`, commit du test de captures `e680f97e` (au-dessus de `db74dddd`, FI-3c). Toute la voie Finance y est intégrée : FI-1b à FI-11c, FI-5b, FI-3c.

Ce rapport dit, écran par écran, ce qui est livré, les tests qui le tiennent (chiffres mesurés ce jour), les captures, les écarts à la maquette et les questions au directeur. Il ne tranche rien : les questions restent ouvertes tant que le directeur n'a pas répondu.

## 1. Les chiffres mesurés

Mesures du 04/10/2026 dans `rc-2`, commande `flutter test test/features/<dossier>` puis `flutter test -r json` pour le détail par fichier.

| Dossier | Réussis | Échecs | Sautés (captures sans `CAPTURE_DIR`) |
|---|---|---|---|
| `test/features/foyer` | 469 | 0 | 37 |
| `test/features/admin_finance` | 79 | 0 | 0 |
| `test/features/mon_espace_adulte` | 111 | 0 | 0 |
| `test/features/revenus_enseignant` | 23 | 0 | 0 |
| `test/features/acces_finance` | 41 | 0 | 0 |
| `test/features/finance` | 37 | 0 | 0 |
| `test/features/finance_recette` | 0 | 0 | 390 (captures seules) |
| **Total** | **760** | **0** | **427** |

Avec `CAPTURE_DIR`, le nouveau fichier `captures_fi12_test.dart` passe : 305 réussis, 0 échec (305 captures écrites).

Autres contrôles du worktree après le commit : `dart analyze --fatal-infos` : aucun problème ; `dart run tool/verifier_jetons.dart` : 39 relevés (inchangé).

Les 37 sautés de `foyer` sont trois fichiers de captures : `fiche_eleve_capture_test.dart` (12), `formulaire_profil_eleve_capture_test.dart` (7), `foyer_capture_test.dart` (18). Les 390 de `finance_recette` : `captures_fi12_test.dart` (305), `captures_fi4_test.dart` (54), `captures_fi_test.dart` (16), `captures_fi2_test.dart` (15).

## 2. Les captures

Dossier : `05_recette/FI/captures/`, 305 fichiers PNG. Nom : `fi12_<écran>_<état>_<largeur>_<thème>.png`, plus `fi12_<écran>_<état>_390_light_200pc.png` pour le texte à 200 %.

Grille par cas : 390 x 1400 et 1440 x 1400, clair et sombre ; 390 x 2400 à texte 200 % en clair. Soit 5 captures par cas, 61 cas.

Comment elles sont faites (`test/features/finance_recette/captures_fi12_test.dart`) :
- tuteur : le vrai routeur avec `surchargesDemoTuteur(finances: JeuFoyerFinance.x)` ;
- direction : le vrai routeur avec `surchargesDemoAdmin` ;
- enseignant : la démonstration `/demo/enseignant?ecran=revenus` pour contenu, vide et hors ligne ; le vrai routeur pour erreur et production ;
- adulte autonome : la démonstration `/demo/adulte` (`etat=adulteSeul`, `reseau=coupe` pour le hors ligne) ; la page `MesFinancesPage` seule pour erreur, vide et production ;
- enfant : `AccueilElevePage` seule, avec le port de l'accès de démonstration ;
- erreur : un double du port en échec ; hors ligne : le même double et `horsLigneProvider` à vrai ; production : aucun port de démonstration (ports neutres, `CapaciteIndisponible`).

Captures ouvertes et relues une à une (19) : `foyer_a_regulariser_390_light`, `foyer_a_regulariser_390_dark`, `foyer_hors_ligne_390_light`, `foyer_essai_390_light`, `foyer_production_390_light`, `foyer_cinq_profils_1440_light`, `finances_a_regulariser_390_light_200pc`, `finances_vide_390_dark`, `mouvements_a_regulariser_390_dark`, `recharge_etape1_390_light`, `recharge_etape2_390_light`, `recharge_production_390_light`, `resultat_termine_390_light`, `resultat_echec_1440_light`, `acces_enfant_ferme_390_light`, `acces_compte_a_regulariser_390_light`, `acces_fiche_essai_390_light`, `adulte_paiements_390_light`, `adulte_recharge_390_light` et `_200pc`, `revenus_contenu_390_light`, `revenus_erreur_390_light`, `admin_vue_globale_1440_dark`, `admin_politiques_1440_light`, `admin_politiques_hors_ligne_1440_dark`. Aucune n'est vide ni en carrés. Un défaut de la capture elle-même a été corrigé : à 1440 x 1000, le résultat du paiement coupait ses boutons en bas ; la hauteur bureau est passée à 1400 et les 122 captures à 1440 ont été refaites.

## 3. Écran par écran

### 3.1 Foyer, soldes et paiements (`/tuteur/foyer`) : FI-4, FI-5, FI-5b

**Livré.** `lib/features/foyer/foyer_page.dart`, `lib/features/foyer/finances_foyer.dart`. Synthèse « Soldes et paiements » (total des soldes en lecture, à financer ce mois, profils financés, paiements du mois), carte de chaque enfant avec pastille d'état, période financée, solde, prochain débit, lien « Recharger {prénom} » sous la carte d'un profil à régulariser, « Recharger plusieurs profils ». À 1440 : synthèse en rangée, cartes en grille de trois, « Dernières transactions » à côté des appareils. Sans source (production) : aucun bloc d'argent ni bouton de recharge.

**Tests.** `foyer/foyer_finances_test.dart` 27, `foyer/foyer_bureau_test.dart` 8, `foyer/foyer_page_test.dart` 20, `foyer/accessibilite_foyer_test.dart` 34, `foyer/carte_membre_test.dart` 9, `foyer/ligne_membre_test.dart` 9. Captures existantes : `captures_fi4_test.dart` (six jeux, 54) et `captures_fi2_test.dart` (15).

**Captures FI-12.** `fi12_foyer_a_regulariser_*`, `fi12_foyer_essai_*`, `fi12_foyer_aucun_paiement_*`, `fi12_foyer_cinq_profils_*`, `fi12_foyer_erreur_*`, `fi12_foyer_hors_ligne_*`, `fi12_foyer_production_*`.

**Écarts à la maquette 03 et 05, vus sur les captures.**
- « Ajouter un profil élève » est le bouton plein, en haut ; « Recharger plusieurs profils » est en contour. La maquette met la recharge en avant, et le choix de nuit Q-FI-2 (`QUESTIONS_NUIT_2026-10-03.md`) disait « Recharger plusieurs profils » seul bouton principal. À confirmer.
- Ordre des cartes : Aïcha, Ibrahim, Mariam (maquette : Mariam, Ibrahim, Aïcha). L'ordre vient de la source de démonstration.
- La carte dit « Pas encore de classe » alors que la fiche Finances du même enfant dit « Classe Al-Huda » (le foyer de démonstration ne porte pas de classe, la finance en porte une).
- Ibrahim à régulariser : la carte du Foyer garde « Prochain débit 1 octobre 2026 · 50 $ », date déjà passée le 4 octobre. La fiche Finances a été corrigée en FI-6a-REVUE2 (« Période à financer octobre 2026 ») ; la carte du Foyer ne l'est pas.
- Pas de rangée de trois compteurs à icônes ni de lien « Gérer tous les enfants » (choix Q-FI-7 et revue FI-1a).
- Pas de bouton « Voir le détail » par carte : la carte entière ouvre la fiche (chevron).

### 3.2 Fiche élève > Finances (`/tuteur/foyer/:id/finances`) : FI-6a

**Livré.** `lib/features/foyer/fiche/finances_page.dart`. Identité, pastille d'état et période, bandeau « Accès à régulariser » avec le manque exact et la fin de conservation de la place, vue financière (solde, période à financer ou prochain débit, mensualité), détail de la mensualité, lien Mouvements, « Recharger {prénom} ». Cinq états : chargement, contenu, vide (« Aucune finance enregistrée »), erreur, hors ligne, plus production (« pas encore disponible »).

**Tests.** `foyer/fiche_eleve_finances_test.dart` 39, `foyer/fiche_eleve_test.dart` 43.

**Captures.** `fi12_finances_a_regulariser_*`, `fi12_finances_essai_*`, `fi12_finances_vide_*`, `fi12_finances_erreur_*`, `fi12_finances_hors_ligne_*`, `fi12_finances_production_*`.

**Écarts à la maquette 02 et 06.** Pas d'onglets Général / Apprentissage / Finances : Finances est une sous-page de la fiche (choix Q-FI-1). À 200 %, « Tarif enfant » et « 50 $ » passent sur deux lignes, lisibles.

### 3.3 Fiche élève > Mouvements (`/tuteur/foyer/:id/mouvements`) : FI-6b

**Livré.** `lib/features/foyer/fiche/mouvements_page.dart`. Liste en ajout seul, signe et texte, sélecteur de profil, « Voir le reçu » quand il existe, aucun reçu pour un paiement en confirmation.

**Tests.** `foyer/fiche_eleve_mouvements_test.dart` 27.

**Captures.** `fi12_mouvements_a_regulariser_*`, `fi12_mouvements_vide_*` (Aïcha en essai : « Aucun mouvement »), `fi12_mouvements_erreur_*`, `fi12_mouvements_hors_ligne_*`, `fi12_mouvements_production_*`.

**Écart.** Pas de maquette dédiée. Ibrahim à régulariser n'a qu'un mouvement (recharge de 42 $) : aucune mensualité d'octobre n'apparaît, ce qui est cohérent avec « Aucune période financée ».

### 3.4 Recharge (`/tuteur/foyer/recharge`) : FI-7

**Livré.** `lib/features/foyer/recharge_foyer.dart`, un seul moteur. Étape 1 : profils cochés, montant par profil (pas de 10, montant suggéré pour le manque), « Tout sélectionner », raison du bouton inactif. Étape 2 : récapitulatif par profil, total à payer, « un seul paiement, pas de solde commun », moyen de paiement, « Payer 50 $ ». Hors ligne : rien ne part. Production : « Recharge pas encore disponible », sans bouton.

**Tests.** `foyer/recharge_multi_profils_test.dart` 25, `foyer/recharge_foyer_adulte_test.dart` 17, `foyer/paiements_foyer_adulte_test.dart` 10.

**Captures.** `fi12_recharge_etape1_*` (Ibrahim coché), `fi12_recharge_etape2_*` (Mariam 10 $, Ibrahim 40 $), `fi12_recharge_erreur_*`, `fi12_recharge_hors_ligne_*`, `fi12_recharge_production_*`.

**Écarts à la maquette 04 et 07.** Le nom de page est « Recharge » (Q-FI-5). Pas de mention « Paiement sécurisé et chiffré » (Q-FI-4). À l'étape 1 les lignes non cochées montrent seulement « 0 $ », sans boutons moins et plus : c'est voulu (montant désactivé), mais la ligne paraît décalée.

### 3.5 Résultat de la recharge (`/tuteur/foyer/recharge/result?commande=`) : FI-8

**Livré.** `lib/features/foyer/resultat_recharge.dart`. Huit états lus par le port, jamais « confirmé » au retour d'un écran externe ; seul `termine` montre les nouveaux soldes. Échec : motif, sélection gardée, « Réessayer », « Changer de moyen de paiement ». Sans commande : vide et retour.

**Tests.** `foyer/resultat_recharge_test.dart` 52.

**Captures.** `fi12_resultat_termine_*`, `fi12_resultat_attente_*`, `fi12_resultat_echec_*`, `fi12_resultat_perime_*`, `fi12_resultat_vide_*`, `fi12_resultat_erreur_*`, `fi12_resultat_hors_ligne_*`, `fi12_resultat_production_*`.

**Écarts à la maquette 01.** À 1440 (`fi12_resultat_echec_1440_light`), dans « Répartition par profil », le bandeau de couleur et l'avatar débordent du haut de chaque ligne, et la colonne reste étroite (environ 560 px) au milieu de l'écran. Même chose à 390, plus discret. À montrer au directeur.

### 3.6 Accès, essai et impayé : FI-9a

**Livré.** `lib/features/acces_finance/acces_finance.dart`, branché dans l'accueil de l'enfant, Mes groupes, Compte > Accès du tuteur, Fiche > Accès, Mon espace de l'adulte. Enfant : « Accès à cette classe temporairement indisponible », jamais une cause ni un montant, Rejoindre absent. Tuteur et adulte : « Accès à régulariser », le manque exact, le mois ; « Essai : 1/2 ». Rejoindre dépend de la période financée, jamais du solde.

**Tests.** `acces_finance/acces_finance_test.dart` 41 (dont l'enfant sans cause financière et sans lecture de la finance, 320 px à 200 %, LTR et RTL, clair et sombre).

**Captures.** `fi12_acces_fiche_a_regulariser_*`, `fi12_acces_fiche_essai_*`, `fi12_acces_compte_a_regulariser_*`, `fi12_acces_compte_production_*`, `fi12_acces_enfant_ferme_*`, `fi12_acces_enfant_ouvert_*`, `fi12_acces_enfant_hors_ligne_*`.

**Écart.** Pas de maquette. Sur Fiche > Accès d'Aïcha en essai : « Aucune date de fin n'est enregistrée » à côté de « Essai : 1/2 » ; la phrase est vraie mais peut inquiéter un parent.

### 3.7 Mes finances de l'élève adulte autonome : FI-9b

**Livré.** `lib/features/mon_espace_adulte/mes_finances_page.dart`. Mon espace > Paiements reprend la vue de la fiche du tuteur à la deuxième personne ; Mes mouvements ; la recharge est le même moteur avec son seul profil. Aucune donnée d'un autre membre (port `PortMesFinances`, périmètre de la session).

**Tests.** `mon_espace_adulte/mes_finances_test.dart` 32, `mon_espace_adulte/mon_espace_adulte_page_test.dart` 79.

**Captures.** `fi12_adulte_mon_espace_*`, `fi12_adulte_paiements_*`, `fi12_adulte_mouvements_*`, `fi12_adulte_recharge_*`, `fi12_adulte_hors_ligne_*`, `fi12_adulte_erreur_*`, `fi12_adulte_vide_*`, `fi12_adulte_production_*`, `fi12_adulte_contenu_page_*`.

**Écarts.** Ouverte directement (`ecran=maRecharge`), la recharge de l'adulte arrive avec son seul profil **non coché** : il doit le cocher pour continuer. Ouverte par « Recharger » depuis Paiements, le profil est passé coché (code : `onRecharger`). La coquille adulte n'existe encore qu'en démonstration (choix provisoire Q2, `/eleve/finances` à venir).

### 3.8 Revenus de l'enseignant (`/enseignant/revenus`) : FI-10

**Livré.** `lib/features/revenus_enseignant/revenus_enseignant_page.dart`. « Estimation » du mois, revenu estimé, heures assurées, classes ; détail par Classe (heures, capacité, sièges éligibles expliqués, taux horaire effectif, montant estimé) ; aide Internet à part. Ouvert depuis le Profil de l'enseignant.

**Tests.** `revenus_enseignant/revenus_enseignant_test.dart` 23.

**Captures.** `fi12_revenus_contenu_*`, `fi12_revenus_vide_*`, `fi12_revenus_hors_ligne_*`, `fi12_revenus_erreur_*`, `fi12_revenus_production_*`.

**Écarts à la maquette 08** (relevé B1 à B8 de `17_finance/ECARTS_MAQUETTES_08_10.md`) : écran dans l'espace Enseignant, pas dans la coque de la direction ; pas de carte « anciennes primes » ; pas d'« Historique des paiements » avec « Payé ». À 390, la légende de « Sièges éligibles » fait six lignes dans une colonne étroite.

### 3.9 Finance de la direction : Vue globale (`/admin/finance`) : FI-11a

**Livré.** `lib/features/admin_finance/vue_globale_finance.dart`. Sept indicateurs séparés (encaissé, revenu académique, paie enseignants, marge projetée sur la seule paie, impayés, essais en nombre, soldes créditeurs) et alertes. Mois sans activité : les zéros restent, la phrase le dit. Production : « Pas encore disponible », sans « Réessayer ».

**Tests.** `admin_finance/vue_globale_finance_test.dart` 21, `admin_finance/finance_domaine_test.dart` 8.

**Captures.** `fi12_admin_vue_globale_*`, `fi12_admin_vue_globale_vide_*`, `fi12_admin_vue_globale_erreur_*`, `fi12_admin_vue_globale_hors_ligne_*`, `fi12_admin_vue_globale_production_*`. Aussi `/demo/finance` par `captures_fi_test.dart`.

**Écarts à la maquette 09** (C1 à C8) : pas de « Répartition des revenus », pas de « Dernières opérations », pas de « Top classes », pas d'« État des paiements » en bloc séparé. C7 et C8 étaient « à garder » dans le relevé et ne sont pas faits.

### 3.10 Politiques commerciales (`/admin/finance/politiques`) : FI-11b, FI-11c

**Livré.** `lib/features/admin_finance/politiques_commerciales.dart`. Brouillon et version active datées, comparaison avec la version active, historique des versions en lecture seule, tarifs, essai, remises, rémunération avec aide Internet, paiement et relances ; aperçu foyer 1 à 5 enfants et taux enseignant arrêtés par le port ; erreurs de cohérence par champ ; « Publier » honnête (indisponible avant le branchement).

**Tests.** `admin_finance/politiques_commerciales_test.dart` 50.

**Captures.** `fi12_admin_politiques_*`, `fi12_admin_politiques_erreur_*`, `fi12_admin_politiques_hors_ligne_*`, `fi12_admin_politiques_production_*`.

**Écarts à la maquette 10** : D1 à D12 suivis selon `ECARTS_MAQUETTES_08_10.md`. Le brouillon ne s'enregistre pas : « Vos modifications restent sur cet écran tant que vous ne le quittez pas » (dit à l'écran).

### 3.11 Démonstration et doubles : FI-1c

`lib/features/demo/finance_demo.dart` (une seule source, six jeux du foyer). Tests : `finance/finance_demo_test.dart` 37.

## 4. Les règles du guide §13, vues dans la recette

| Règle à refuser (guide §13) | Ce que montrent tests et captures |
|---|---|
| Action à deux endroits | Un seul moteur de recharge (Foyer, fiche, Compte, adulte ouvrent la même `RechargeFoyerPage`) : `recharge_multi_profils_test.dart`, `recharge_foyer_adulte_test.dart`. |
| Enfant qui consomme le solde d'un autre | Montant par profil, récapitulatif par profil, « pas de solde commun » : `fi12_recharge_etape2_390_light`. |
| Total foyer utilisable comme portefeuille | « Une lecture : chaque solde reste celui de son profil » sous le total : `fi12_foyer_a_regulariser_390_light`. |
| Couleur de profil qui change ou dépend de l'index | Couleur choisie par profil (K-62) ; à vérifier par FI-R sur l'ordre (Aïcha est en lavande au Foyer, Mariam en rose, partout pareil dans les captures relues). |
| Statut par couleur seule | Pastilles avec texte (« Financé », « À régulariser », « Essai : 1/2 ») sur toutes les captures relues. |
| Tarif dans un widget | Garde-fou des montants en dur (FI-3c) ; tous les montants viennent de `finance_demo.dart`. |
| Compte bloqué pour impayé | L'enfant garde le Coran et sa navigation (`fi12_acces_enfant_ferme_390_light`). |
| Rejoindre selon le solde | `acces_finance_test.dart` (Rejoindre selon la période financée). |
| Confirmation simulée comme vérité | Résultat lu par le port, huit états : `resultat_recharge_test.dart`. |
| Ancien montant 20/26 ou 5/10 | Absent des captures relues. |
| Backend touché | Aucun fichier `supabase/` dans la vague. |

## 5. Besoins serveur : les FI-BR rendus par les ports

Relevé par `grep "CapaciteIndisponible('FI-BR-" lib/core/capacites` : ce que chaque port neutre de production renvoie aujourd'hui, et ce qui manque au serveur.

| FI-BR | Port et méthode (fichier:ligne) | Écrans qui l'attendent | Ce qui manque côté serveur |
|---|---|---|---|
| FI-BR-01 | `port_politiques_commerciales.dart:54` `active()`, `:71` `apercuFamille()`, `:78` `apercuEnseignant()` | Foyer, recharge, Politiques | La politique effective versionnée et sa lecture par tous ; le calcul serveur des aperçus. |
| FI-BR-02 | `port_politiques_commerciales.dart:60` `versions()`, `:65` `publier()` | Politiques | Brouillon, publication datée non rétroactive, historique, écriture réservée et auditée. |
| FI-BR-03 | `port_paiements_foyer.dart:158` `finances()` | Foyer, Fiche > Finances, Accès | La finance de chaque profil (solde, période, prochain débit, mensualité détaillée, état) et la synthèse du foyer (FI-BR-04 n'a pas de méthode à lui : il passe par `finances()`). |
| FI-BR-05 | `port_paiements_foyer.dart:163` `mouvements()`, `:169` `derniersMouvements()` | Mouvements, Foyer à 1440 | Mouvements en ajout seul par profil, reçus. |
| FI-BR-06 | `port_recharge_foyer.dart:245` `verifierMontants()`, `:250` `suivre()` | Recharge, Résultat | Commande multi-profils, total et taxe arrêtés, idempotence, huit états, webhook avant crédit. Les méthodes `beneficiaires()`, `verifier()` et `payer()` renvoient encore les anciennes références EA-BR-24 et EA-BR-25 (`:227`, `:233`, `:240`), que FI-BR-06 remplace. |
| FI-BR-11 | `port_revenus_enseignant.dart:106` `moisEnCours()` | Revenus | Revenus estimés par séance assurée, sièges éligibles, taux plafonné, aide Internet à part. |
| FI-BR-12 | `port_finance_direction.dart:121` `vueGlobale()` | Vue globale | Les sept indicateurs et les alertes. |
| FI-BR-17 | `port_mes_finances.dart:39` `finances()`, `:44` `mouvements()` | Mes finances de l'adulte | Les données de FI-BR-03, 05 et 06 limitées au profil de la session. |
| FI-BR-19 | `port_accents_profils.dart:32` et `:37` | Foyer, fiche, toutes les cartes de profil | La clé d'accent par profil, écrite par le titulaire seul. |

Autres références de ces ports qui ne sont pas des FI-BR : `port_paiements_foyer.dart` `historique()` et `detail()` (DB-CPT-03), `soldes()` (EA-BR-23, remplacé par FI-BR-03), `port_acces_foyer.dart:104` `acces()` (LOT-E ; le besoin est FI-BR-08).

**FI-BR sans port aujourd'hui** (rien ne les appelle dans `lib/core/capacites`) : FI-BR-04 (passe par FI-BR-03), FI-BR-07 (moyens de paiement enregistrés : la démonstration n'en a qu'un), FI-BR-08 (accès par période financée : port `LOT-E`), FI-BR-09 (débit mensuel), FI-BR-10 (taxes), FI-BR-13 (rôle comptable, hors lot), FI-BR-14 (tables `wallets`), FI-BR-15 (rails natifs), FI-BR-16 (relances), FI-BR-18 (second adulte : règle de lecture, sans port propre). Proposition : remplacer `LOT-E` par `FI-BR-08` et `EA-BR-24/25` par `FI-BR-06` dans les ports, pour que la table dise la vérité (petite étape de code, non faite ici).

## 6. Questions au directeur

Tirées du code, des tests et des captures. Aucune n'est tranchée ici.

1. **Bouton principal du Foyer.** Aujourd'hui « Ajouter un profil élève » est plein et « Recharger plusieurs profils » en contour. Le choix de nuit Q-FI-2 disait l'inverse. Lequel garder ?
2. **Prochain débit passé sur la carte du Foyer.** Ibrahim affiche « Prochain débit 1 octobre 2026 » le 4 octobre. La fiche dit « Période à financer octobre 2026 ». La carte doit-elle dire la même chose que la fiche ?
3. **Classe sur la carte du Foyer.** « Pas encore de classe » au Foyer, « Classe Al-Huda » sur la fiche du même enfant (démonstration). À aligner sur une seule source ?
4. **Répartition par profil du résultat** à 1440 : bandeau et avatar qui débordent de la ligne, colonne étroite au centre. Acceptez-vous ce rendu ou voulez-vous la ligne de la maquette 01 ?
5. **Vue globale** : les blocs « État des paiements » et « Top classes », marqués « à garder » dans le relevé de la maquette 09 (C7, C8), ne sont pas faits. Les voulez-vous dans cette vague ?
6. **Recharge de l'adulte** ouverte directement : son seul profil arrive non coché. Doit-il être coché d'office ?
7. **Accès d'un enfant en essai** : « Aucune date de fin n'est enregistrée ». Préférez-vous une phrase sur l'essai (« En essai, 1 séance sur 2 ») ?
8. **Q-FI-10** (déjà posée) : Revenus de l'enseignant depuis le Profil (fait ainsi) ou depuis le Compte ?
9. **Q1 et Q2 de `17_finance/QUESTIONS.md`** : Q1 est close dans les faits (maquettes 08 à 10 reçues le 02/10) ; Q2 (« business plan ») reste ouverte.

## 7. Ce qui reste hors de ce rapport

- La revue croisée FI-R (session qui n'a pas écrit le code) et la planche du directeur FI-RC.
- Les captures 768 et RTL de cette vague restent celles de `captures_fi4_test.dart` (768 et 1200 du Foyer) et `captures_fi_test.dart` (RTL de `/demo/finance`) ; `captures_fi12_test.dart` ne fait que 390 et 1440.
- Les états « interdit », « incomplet », « périmé », « concurrent » du guide §10 ne sont pas capturés ici, sauf le « périmé » du paiement (`fi12_resultat_perime_*`) et l'attente de confirmation (`fi12_resultat_attente_*`).
