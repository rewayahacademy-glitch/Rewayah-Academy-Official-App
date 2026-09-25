# Lot E - Compte et suivi : rapport

Poste A. Worktree `D:\RA_TUTEUR\lot-e`, branche `ui/tuteur-v1-e`, créée depuis `ui/tuteur-v1` @ `cefab7f`. Commits locaux, **aucun push**.

| Sous-paquet | Statut | Commits |
|---|---|---|
| 1. Mon compte et sous-pages | **livré** (24/09, 19 h 55) | `65cbcee`, `05f62a8`, `bbaf63f` |
| 2. Historique et détails | **livré** (25/09, 03 h 30) | `5f44043`, `856e809`, `9479d04`, `6024bf1` |
| 3. Notifications et consultation admin des observations | non commencé | - |

---

## Sous-paquet 1 : Mon compte et sous-pages

### 1. Commits

| Hash | Message | Contenu |
|---|---|---|
| `65cbcee` | feat(compte-tuteur): adaptateurs identite du titulaire et acces du foyer | `lib/core/capacites/identite_titulaire_supabase.dart`, `acces_foyer_depuis_eleves.dart` |
| `05f62a8` | feat(compte-tuteur): Mon compte et ses sous-pages selon les maquettes V3 et V4 | 9 écrans (les 9 STUB du sous-paquet remplacés), `carte_rubriques.dart`, `donnees_compte.dart`, i18n `compte.tuteur.*` + `compte.profils`, slang régénéré, `test/features/compte/**` |
| `bbaf63f` | test(capture): Compte du tuteur a 390 et 1440, clair et sombre, planches V3 et V4 | `test/capture/compte_tuteur_capture_test.dart` |

Frontière `git diff --stat cefab7f -- supabase .github vercel.json web/vercel.json .firebaserc pubspec.yaml lib/core/theme lib/core/router lib/core/widgets lib/core/icons lib/core/coran lib/core/tc_coran lib/features/tc_mushaf` : **vide**. `windows/flutter/*` (fins de ligne de `pub get`) non commités. `compte_page.dart` (écrans des autres rôles) non modifié.

### 2. Écrans livrés et statut de preuve

Légende : UI = UI réalisée ; BR = branchée au service existant ; SIM = testée en simulation (tests de widget, vrai routeur) ; DB = dépendance backend ; COORD = attend un geste du coordinateur.

| Écran | Route | Statut | Détail |
|---|---|---|---|
| Mon compte | `/tuteur/compte` | UI, SIM ; BR partiel ; COORD (E-1) | Foyer (`profils_du_foyer_v`), fuseau (`mon_fuseau()`), déconnexion (`signOut`, `fermerDemo`) branchés. Identité et accès : adaptateurs écrits et testés, **provider de port à brancher par COORD** ; d'ici là la carte d'identité dit « Pas encore disponible » |
| Informations personnelles | `.../informations` | UI, SIM ; COORD (E-1) ; DB-CPT-01 | Lecture seule (prénom, nom, adresse de connexion, langue, fuseau des séances) ; aucune modification (aucune écriture tuteur) ; aucun téléphone, aucune ville (aucune colonne) |
| Connexion et sécurité | `.../securite` | UI, SIM ; COORD (E-1) ; DB-CPT-02 | Méthode réelle (lien par courriel ou Google, jamais « mot de passe » en production) ; appareils connectés : phrase « pas encore listés » ; la déconnexion reste au pied de Mon compte (une seule place) |
| Accès des profils élèves | `.../acces` | UI, SIM ; COORD (E-1) ; DB-FOY-05 | Une ligne par profil : « Sans date de fin », « Ouvert jusqu'au … », « Terminé le … » + pastille ; jamais « abonnement » ; phrase « le titulaire n'a pas d'échéance propre » ; place du futur solde par enfant (rien construit) |
| Paiements et reçus | `.../paiements` | UI, SIM ; DB-CPT-03 | Indisponible honnête, aucun bouton, « Aucun paiement ne vous est demandé ici » |
| Préférences | `.../preferences` | UI, SIM | Un seul groupe à filets (V4) : Apparence (lien), Langue et région (lecture), Notifications (« pas encore disponibles », DB-CPT-04). Tâche focalisée, disque retour |
| Apparence | `.../preferences/apparence` | UI, BR, SIM | Système / Clair / Sombre écrit `preferencesLocalesProvider`, lu par `RewayahApp`, persisté (sauf web, mémoire : 0e D10) ; même préférence que la bascule de l'en-tête. Confort visuel sans interrupteur (aucun consommateur, E-5) |
| Aide et support | `.../aide` | UI, SIM ; DB-CPT-07 | Indisponible honnête ; aucun faux contact |
| Informations légales | `.../informations-legales` | UI, BR, SIM ; DB-CPT-08 | Documents acceptés lus (`contract_acceptances`, `acceptationsProvider`) avec version et date ; CGU, confidentialité, mentions : indisponibles |

« Vérifié réellement » : **rien** (aucun navigateur, aucun appareil, aucun Supabase).

### 3. Carte des fonctions (une fonction = un seul endroit)

| Fonction | Écran unique | Route | Place dans la maquette (V3 / V4) | Écart |
|---|---|---|---|---|
| Ouvrir les préférences | Mon compte, en-tête | `/tuteur/compte/preferences` | engrenage en haut à droite | libellé accessible « Préférences » ajouté |
| Identité du titulaire (nom, rôle, statut, adresse, méthode) | Mon compte, carte d'identité | - | carte pleine largeur en tête | pas de téléphone (aucune donnée) ; « Compte vérifié » devient « Compte validé » (statut `active` lu), « Profil à compléter » pour `provisional_active` |
| Modifier l'identité | **non rendue** | - | bouton « Modifier » (carte d'identité) et « Modifier mes informations » | aucune écriture (DB-CPT-01) ; un bouton qui ne peut pas aboutir n'est pas rendu |
| Accès des profils élèves | Mon compte > Accès et paiements | `.../acces` | carte gauche 1 (« Abonnement et accès », en-tête + pastille) | titre « Accès et paiements » (un accès daté n'est pas un abonnement) ; pastille « Accès actif / terminé » calculée des échéances réelles |
| Paiements, reçus, moyen de paiement | Mon compte > Accès et paiements | `.../paiements` | « Gérer les paiements » (CTA), « Historique et reçus », « Moyen de paiement » | trois entrées fondues en UNE ligne « Paiements et reçus · Non disponible » ; pas de CTA dominant sans service |
| Connexion et sécurité | Mon compte > Connexion et sécurité | `.../securite` | carte gauche 2 | « Appareils connectés » et « Sécurité et confidentialité » non rendus (pas de sessions, doublon) ; titre du mandat « Connexion et sécurité » |
| Informations personnelles | Mon compte > Informations personnelles | `.../informations` | carte droite 1 | résumé sans répéter nom ni adresse (déjà sur l'identité) ; ligne « Consulter mes informations » |
| Aller au Foyer | Mon compte > Mon foyer | `/tuteur/foyer` (go, destination Foyer active) | carte droite 2, « Gérer mon foyer » | légende sans « disponibilités » ; le titulaire n'est pas compté comme élève |
| Créer mon profil élève | Mon compte > Mon foyer (raccourci prévu par le mandat, même flux que le Foyer) | `/tuteur/foyer/ajouter?pour=moi` (écran lot B) | absent de la maquette (V3 §7) | masquée seulement quand le profil existe |
| Aide et contact | Mon compte > Aide et support | `.../aide` | carte droite 3, « Questions fréquentes » + « Contacter Rewayah » | deux entrées vers la même page fondues en une, « Non disponible » |
| Informations légales | Mon compte > Aide et support | `.../informations-legales` | absent de la maquette (V3 §7) | ligne sobre dans la carte Aide |
| Se déconnecter | Mon compte, pied de page | action (`signOut` local ; `fermerDemo` en démonstration) | bande pleine largeur rouge, séparée | confirmation `ConfirmDestructive` ajoutée ; message si échec |
| Apparence | Préférences | `.../preferences/apparence` | V4 01, ligne « Apparence » | - |
| Langue et région | Préférences (lecture) | - | V4 01 | pas de chevron : rien à régler (français seul, fuseau tenu par l'académie) |
| Notifications (réglages) | Préférences (lecture) | - | V4 01 | « Pas encore disponibles » (DB-CPT-04) |
| Sécurité (V4 01) | **Mon compte** seulement | `.../securite` | 4e carte de V4 01 | retirée des Préférences : doublon de « Connexion et sécurité » |
| Thème Système / Clair / Sombre | Apparence (et bascule de la coquille, même préférence) | - | V4 02 groupe 1 | cartes `ChoiceCardGroup` sans miniature ni sous-ligne (E-3) |
| Réduire animations / effets, taille du texte | Apparence (lecture) | - | V4 02 « Confort visuel » | aucun interrupteur (aucun consommateur, E-5) |

Aucune fonction du sous-paquet n'est rendue deux fois (test « aucune fonction sans service n'est rendue ni doublée »).

### 4. Captures (`05_recette/e/captures/`, lues)

- 36 captures : 9 écrans × {390x844@3, 1440x900@1} × {clair, sombre} (`e_<écran>_<taille>_<thème>.png`) ; + `e_compte_390x1900@2_pleine_hauteur_{light,dark}.png` (page entière).
- 5 planches maquette | rendu (+ `_capture.png`) : `e_planche_compte_mobile_clair`, `e_planche_compte_mobile_sombre`, `e_planche_compte_bureau_clair`, `e_planche_preferences_mobile_sombre`, `e_planche_apparence_mobile_sombre` (maquettes V4 recadrées dans `05_recette/e/maquettes/`).
- Constats et corrections faites après la première planche : filet latéral des cartes masqué par le fond des lignes (corrigé : filet au premier plan) ; valeur de ligne collée au libellé (corrigé : valeur calée à droite) ; titre « Accès et paiements » coupé par la pastille sur téléphone (corrigé : pastille sous le résumé sous 560 de large) ; légendes de lignes absentes de la maquette (retirées) ; nom répété dans deux cartes (retiré du résumé).
- Conforme au layout : ordre des cartes, en-tête dans la carte (médaillon, titre, résumé, pastille), lignes à filets en retrait, deux colonnes 11:10 sur bureau, déconnexion séparée pleine largeur, barre basse Compte actif, engrenage en haut à droite ; Préférences en un groupe (V4 le recommande).
- Écarts restants, non corrigibles par le lot : maquette ~1,4 fois plus dense qu'un vrai 390 (les planches comparent la structure) ; cloche (et bascule dès la tablette) ajoutées par la coquille ; icônes de remplacement (E-4) ; options de thème sans miniature, sous-ligne ni radio (E-3) ; carte locale `CarteRubriques` en attendant l'extension de `GroupeReglages` (E-2).

### 5. Tests lancés (tous sous `flutter-verrou.ps1`, dossier `D:\RA_TUTEUR\lot-e`)

| # | Commande | Résultat exact |
|---|---|---|
| 1 | `flutter pub get` | `Got dependencies!`, code 0 |
| 2 | `dart run slang && dart analyze --fatal-infos` (compte + adaptateurs) | 1 info `prefer_initializing_formals`, corrigée |
| 3 | `dart analyze --fatal-infos test/features/compte lib/features/compte` puis `flutter test test/features/compte` | analyse : 1 erreur de test (`ProviderListenable`), corrigée ; `+43 -2` (nom répété dans deux cartes), corrigé |
| 4 | idem + `flutter test test/capture/compte_tuteur_capture_test.dart` (CAPTURE_DIR) | `No issues found!` ; `+45: All tests passed!` ; captures `+44: All tests passed!` |
| 5 | après corrections des planches : `dart run slang && dart format && dart analyze --fatal-infos` (lib/features/compte, 2 adaptateurs, test/features/compte, capture) `&& flutter test test/features/compte && flutter test test/capture/compte_tuteur_capture_test.dart` | `No issues found!` ; `01:02 +45: All tests passed!` (`e1_tests_compte.log`) ; `00:59 +44: All tests passed!` (`e1_captures.log`) |
| 6 | `dart run tool/verifier_jetons.dart && flutter test test/features/compte_test.dart test/router/navigation_test.dart test/config/fixtures_isolees_test.dart test/i18n` | `Jetons verifies : 422 fichiers, aucune violation.` ; `00:46 +85: All tests passed!` (`e1_nonreg.log`) |

Couverture des 45 tests du lot : destination Compte touchée depuis la barre ; ordre des cartes (390) ; deux colonnes (1440) ; aucun libellé sans service ni doublon ; **chaque rubrique touchée à 390 et 1440** puis retour par le disque (Compte actif, barre visible) ; « Gérer mon foyer » allume le Foyer ; « Créer mon profil élève » ouvre `?pour=moi` et disparaît si le profil existe ; engrenage > Apparence > Sombre (préférence appliquée, retours en chaîne, barre masquée puis revenue) ; préférences sur bureau (colonne gardée) ; déconnexion : annuler, confirmer (390 et 1440), échec dit ; états : identité indisponible (port de production), échec + Réessayer, chargement (squelette), foyer vide, hors ligne (bandeau) ; sous-pages : trois états d'accès, foyer sans profil, paiements et aide indisponibles, documents acceptés, informations en lecture seule, sécurité sans mot de passe ; adaptateurs et fonctions pures (méthode de connexion, identité, accès triés, ville du fuseau, date longue, statut).

**Non exécutés** : analyse complète et suite complète (réservées au coordinateur) ; `build_runner` (aucune source concernée) ; build web ; appareil, navigateur ; Supabase. Test `(c)` de la définition de « fait » (texte présent dans le `main.dart.js` servi) : à faire après publication de l'aperçu.

### 6. Demandes au coordinateur

Détail et signatures : `pilotage-tuteur-v1/demandes/E.md`.
- **E-1** brancher `IdentiteTitulaireSupabase` et `AccesFoyerDepuisEleves` dans les providers de port (sans cela, identité et accès restent « indisponibles » en production).
- **E-2** étendre `GroupeReglages` (en-tête dans la carte, corps) et corriger ses deux défauts (valeur non calée, filet latéral recouvert) ; puis `CarteRubriques` disparaît.
- **E-3** `ChoiceCardGroup` : description, aperçu, radio (Apparence ; sert aussi B).
- **E-4** icônes Phosphor manquantes (couronne, question, enveloppe, palette, globe...).
- **E-5** consommer `animationsReduites` / `effetsReduits` pour rendre les interrupteurs de V4.
- **E-6** informations : `compte.profils` = « Gérer mon foyer » (test du routeur toujours vert) ; aucune entrée vers `/tuteur/compte/consentements` (lot A) ; adaptateurs de démonstration à prévoir ; bascule de thème présente sur le Compte bureau.

### 7. Défauts hors périmètre

Aucun consigné dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md` pour ce sous-paquet. Les deux défauts du composant partagé `GroupeReglages` sont dans E-2.

---

## Sous-paquet 2 : Historique, détail de séance, détail des observations

Reprise d'un agent coupé : `lib/core/suivi/groupes_seances.dart` (non suivi) et les clés `historique.*` (non commitées) ont été relus, gardés et complétés.

### 1. Commits

| Hash | Message | Contenu |
|---|---|---|
| `5f44043` | feat(historique-tuteur): adaptateurs de lecture, classe des seances et visites d'observation sous RLS | `lib/core/suivi/groupes_seances.dart` (`sessions.groupe_id`, tri `started_at` descendant écrit), `lib/core/tc_observation/historique_observations_supabase.dart` (port K4, `guardian_session_visit`, tri `entered_at` descendant et `visit_number` croissant écrits) |
| `856e809` | feat(historique-tuteur): Historique Seances et Observations, detail de seance et detail des observations (maquette V8 D2, D4) | 3 STUB remplacés (`observations_page`, `detail_seance_page`, `detail_observations_page`), `suivi_foyer_page` refait, `composants_historique`, `donnees_historique`, `filtres_historique` ; i18n `historique.*` (+ retrait de `tuteur.suivi.*`, espace du lot) ; slang ; `test/features/historique/**` ; ancien `test/features/suivi_foyer_test.dart` supprimé (écran remplacé) |
| `9479d04` | fix(historique-tuteur): colonnes alignees, sous-titres sur une ligne, visites calees a droite (planches V8) | corrections après planches |
| `6024bf1` | test(capture): Historique du tuteur ... | `test/capture/historique_tuteur_capture_test.dart` |

Frontière `git diff --stat cefab7f -- supabase .github vercel.json web/vercel.json .firebaserc pubspec.yaml lib/core/theme lib/core/router lib/core/widgets lib/core/icons lib/core/coran lib/core/tc_coran lib/features/tc_mushaf` : **vide**. `vue_suivi_foyer.dart` (lu par l'élève) non modifié. `windows/flutter/*` non commités. STUB restants du lot E : `notifications_page.dart`, `observations_admin_page.dart` (sous-paquet 3).

### 2. Écrans livrés et statut de preuve

| Écran | Route | Statut | Détail |
|---|---|---|---|
| Historique, Séances | `/tuteur/suivi` (alias `/tuteur/historique`, `?eleve=&classe=` lus) | UI, BR, SIM ; DB-CRS-13, DB-HIS-03 | `mes_seances_v` + `presence_seance_v` (services existants) ; classe par `sessions.groupe_id` + classes courantes (`mes_groupes_famille_v`), sinon « Classe non disponible » ; sélecteur K1 partagé avec l'Accueil ; filtres Classe / Période / Statut (dérivés de la lecture, mémoire de session) ; séances passées seulement ; statut après la séance : coupure, départ, calcul non confirmé, inconnu = « En cours de vérification », jamais une absence ; « Retard N min » ; le sort du cours prime ; fuseau dit ; aucun réseau |
| Historique, Observations | `/tuteur/suivi/observations` | UI, SIM ; COORD (E-7) ; DB-OBS-03/04/11 | Port K4 : **production = « Historique des observations indisponible »** jusqu'à E-7 ; en simulation : une ligne par séance et élève, « n visites · durée serveur » ou « Durée non confirmée », « Terminée » / « Sortie non enregistrée », jamais de motif de fin |
| Détail de séance | `/tuteur/seances/:seanceId?eleve=` | UI, BR, SIM ; DB-CRS-12 | Titre = classe, sous-titre élève et date ; carte « La séance » (horaire, durée prévue, classe, enseignant avec Sayyid/Sayyida si la classe courante le nomme) ; carte « Présence de X » (statut, arrivée, interruption, phrase) ; fuseau UTC±hh:mm ; « introuvable » pour un id hors foyer ; aucun résumé famille (`lesson_reports` exclu) |
| Détail des observations | `/tuteur/seances/:seanceId/observations?eleve=` | UI, SIM ; COORD (E-7) | Résumé (Vous, élève, enseignant, durée totale serveur), visites (rang, plage, durée, statut), fuseau ; introuvable ; indisponible en production |

« Vérifié réellement » : **rien** (aucun navigateur, appareil ni Supabase).

### 3. Carte des fonctions

| Fonction | Écran unique | Route | Place dans la maquette (V8 D2 / D4, ancienne Historique) | Écart |
|---|---|---|---|---|
| Choisir l'élève | Historique (sélecteur K1, même sélection que l'Accueil) | - | rangée d'avatars sous le titre | point de statut non rendu (aucun état mesuré ici) ; sous-libellé = nombre de séances passées |
| Ajouter un profil élève | **Foyer seulement** | `/tuteur/foyer/ajouter` | item « Ajouter enfant » du sélecteur | non rendu ici (doublon) |
| Basculer Séances / Observations | Historique, contrôle segmenté | `/tuteur/suivi` / `/tuteur/suivi/observations` (`go`) | sous le sélecteur, pleine largeur | - |
| Filtrer (Classe, Période, Statut) | chaque segment | - | trois menus sous le segment | sans icône (E-8.1) ; menu Classe absent sans classe nommable ; statuts présents seulement |
| Ouvrir une séance | ligne de la carte Séances | `/tuteur/seances/:id?eleve=` (`go`) | ligne entière + chevron | sur téléphone la pastille passe sous la classe (maquette plus dense) ; à 1440 à droite |
| Ouvrir les visites d'une séance | ligne de la carte Observations | `/tuteur/seances/:id/observations?eleve=` | ligne + chevron | idem |
| Revenir à la liste | disque retour des détails | `go` vers la liste (filtres conservés) | « ‹ Observations » / « Retour à l'historique » (D4) | bouton « Retour à l'historique » non rendu : doublon du retour |
| Réseau élève / enseignant | **non rendu** | - | ancienne capture | non mesuré (DB-HIS-03) |
| Motif de fin de visite | **non rendu** | - | « Limite atteinte », « Départ volontaire » | le serveur écrit toujours « sortie volontaire » (DB-OBS-04) |
| Notifications (cloche) | coquille | `/tuteur/notifications` | en haut à droite | sous-paquet 3 |

### 4. Captures (`05_recette/e/captures/`, lues)

- 16 : 4 écrans × {390x844@3, 1440x900@1} × {clair, sombre} (`e_historique_seances_*`, `e_historique_observations_*`, `e_detail_seance_*`, `e_detail_observations_*`) ; + `e_historique_seances_390x1400@2_pleine_hauteur_{light,dark}` ; + états `e_historique_observations_indisponible_390x844@3_light`, `e_historique_vide_390x844@3_light`.
- 3 planches (+ `_capture.png`) : `e_planche_historique_observations_mobile_sombre` (V8 D2), `e_planche_detail_observations_mobile_clair` (V8 D4), `e_planche_historique_seances_ancienne_sombre` (ancienne capture). Maquettes recadrées : `05_recette/e/maquettes/v8_d2_*.png`, `v8_d4_*.png`.
- Corrections après planches : débordement de ligne à 390 (pastille passée sous la classe) ; filets verticaux désalignés à 1440 (colonne de date à largeur fixe) ; date en double dans le détail de séance (ligne « Date » retirée, sous-titre court) ; durée et pastille des visites calées à droite comme D4.
- Conforme au layout : titre + cloche, sélecteur, segment, trois filtres, UNE carte à filets, colonne date | filet | classe, pastille, chevron ; barre basse Historique active ; bureau : colonne de lecture 800 alignée au début, barre latérale.
- Écarts restants : maquette ~1,4 fois plus dense (planches = structure) ; pastille sous la classe sur téléphone ; filtres sans icône (E-8.1) ; point de statut et « Ajouter » du sélecteur absents ; sous-titre du détail sur deux lignes à 390 (disque retour + cloche) ; bascule de thème de la coquille à 1440.

### 5. Tests (tous sous `flutter-verrou.ps1`, dossier `D:\RA_TUTEUR\lot-e`)

| # | Commande | Résultat exact |
|---|---|---|
| 1 | `dart run slang && dart format ... && dart analyze --fatal-infos lib/features/suivi_foyer lib/core/suivi lib/core/tc_observation/historique_observations_supabase.dart` | `No issues found!` |
| 2 | `flutter test test/features/historique` (1re passe) | `+20 -5` : débordement de ligne à 390, `push` sans adresse (remplacé par `go`), retour imbriqué, test de filtre faux, largeur mesurée sur le mauvais widget ; corrigés |
| 3 | `dart run tool/verifier_jetons.dart` (1re passe) | `1 violation [espacement-hors-echelle]` (`SizedBox(width: 1)`), corrigée |
| 4 | final : `dart analyze --fatal-infos lib/features/suivi_foyer test/features/historique test/capture/historique_tuteur_capture_test.dart` ; `verifier_jetons` ; `flutter test test/features/historique test/router/navigation_test.dart test/accessibilite/rtl_echelle_texte_ecrans_test.dart test/features/suivi_eleve_test.dart test/suivi test/config/fixtures_isolees_test.dart test/i18n` | `No issues found!` ; `Jetons verifies : 427 fichiers, aucune violation.` ; `01:27 +183: All tests passed!` (`e2_tests_historique.log`) |
| 5 | `flutter test test/capture/historique_tuteur_capture_test.dart` (CAPTURE_DIR + 3 maquettes) | `00:26 +24: All tests passed!` (`e2_captures.log`) |

Couverture (33 tests du lot) : destination Historique **touchée** depuis la barre (390 et 1440), Historique actif ; ordre sélecteur > segment > filtres ; « Ajouter » absent ; statuts après séance (présence, retard 8 min, vérification pour une coupure, annulé, non tenu ; jamais « Absence » ni « Lien coupé ») ; classe et Sayyid ; ni séance future ni autre élève ; tri décroissant ; fuseau ; aucun réseau ; profil A2 **touché** ; ligne **touchée** > détail (horaire, arrivée, phrase, UTC) > disque retour **touché** > liste encore filtrée ; filtres Statut, Période, filtre vide + « Réinitialiser les filtres » ; Classe ; sans classe lisible ; `?eleve=` ; segment Observations **touché** (indisponible en production, sans « Réessayer ») puis Séances ; observations simulées : ligne, détail **touché**, visites, retour, profil A2, aucun motif de fin ; filtre Statut qui survit au changement de profil ; vide ; introuvables (séance, visites) avec retour **touché** ; chargement (squelette) ; échec + Réessayer (relecture comptée) ; vide ; foyer sans profil ; hors ligne (bandeau) ; présence illisible ; fonctions pures (statuts, périodes civiles, durées, dates, décalage, classes des séances, groupement des visites, lignes incomplètes écartées).

**Non exécutés** : analyse et suite complètes (coordinateur) ; build web ; navigateur, appareil, Supabase ; test `(c)` de la définition de « fait » après publication de l'aperçu ; `graphe_imports.ps1` (écrans atteints par `app_router.dart`, fichier inchangé).

### 6. Demandes au coordinateur

`demandes/E.md` : **E-7** brancher `HistoriqueObservationsSupabase` dans `portHistoriqueObservationsProvider` (après confirmation du GRANT SELECT en production) ; **E-8** informations (icône de `MenuFiltre`, « Réessayer » pendant le réessai automatique de Riverpod, « Ajouter » non rendu, entrée `?eleve=&classe=` pour le lot C, clés `tuteur.suivi.*` retirées).

### 7. Défauts hors périmètre

Aucun consigné dans `08_BACKLOG_VAGUE_CLASSE_VISIO.md`.
